---
name: orchestration-loop
description: >-
  Full multi-agent orchestration protocol for feature builds. Defines the
  scout → plan → implement → adversarial review → verify → iterate loop.
  Use when running /orchestrate or when the orchestrator agent needs the
  coordination protocol. Covers phase sequencing, agent invocation, report
  passing, iteration tracking, re-scout logic, and final reporting.
---

# Orchestration Loop Protocol

This skill defines the exact protocol the **orchestrator** agent follows when executing a `/orchestrate` run. Load this skill at the start of every orchestration session and follow it precisely.

---

## Subagent Invocation Mechanism

All subagents are dispatched using the `task` tool:

```
task(
  subagent_type: "<agent-name>",
  description: "<short description for the UI>",
  prompt: "<full brief text>"
)
```

**To run two agents in parallel**, issue both `task` calls in the **same response step** — do not wait for one to complete before issuing the other. The protocol marks parallel phases explicitly with `[PARALLEL]`.

---

## State to Track

Maintain these values throughout the session:

```
FEATURE_REQUEST: <the original user prompt>
ITERATION: 0
MAX_ITERATIONS: 5
CODEBASE_REPORT: null
WEB_REPORT: null
TASK_PLAN: null
IMPL_REPORT: null
ADVERSARY_REPORT: null
ADVERSARY_VERDICT: null
VERIFIER_REPORT: null
VERIFIER_VERDICT: null
```

After each phase completes, update the **Context Tracker** (see below) before proceeding.

---

## Context Tracker

After every phase, print and maintain this compact block. This is the single source of truth for current state and survives context pressure. Do not rely on scrollback — always reprint this at the start of each phase announcement.

```
─────────────────────────────────────────
ORCHESTRATION TRACKER
Goal: <FEATURE_REQUEST — one line max>
Iteration: <ITERATION> / <MAX_ITERATIONS>

Phase 1 — Scout:       [ pending | done | re-run ]
Phase 2 — Plan:        [ pending | done ]
Phase 3 — Implement:   [ pending | done (N) ]
Phase 4 — Review:      [ pending | done (N) ]
  Adversary:           [ pending | PASS | FAIL — N blockers, M majors ]
  Verifier:            [ pending | PASS | FAIL — N failures ]

Commands detected:
  test:  <command or NOT DETECTED>
  build: <command or NOT DETECTED>
  lint:  <command or NOT DETECTED>
─────────────────────────────────────────
```

Fill in only what is known. Leave `pending` for phases not yet reached. Update the "Commands detected" fields as soon as the codebase-scout report is received.

---

## Phase 1 — Scout [PARALLEL]

Print: `Phase 1/5 — Scouting codebase and web...`

Print the Context Tracker (iteration 0, all pending).

**Invoke both scouts in the same response step** using two simultaneous `task` calls:

### codebase-scout invocation:
```
task(
  subagent_type: "codebase-scout",
  description: "Scout codebase for feature context",
  prompt: """
Feature request: <FEATURE_REQUEST>
Working directory: <current project root>

Produce a complete Codebase Report as specified in your instructions.
"""
)
```

### web-scout invocation (same step):
```
task(
  subagent_type: "web-scout",
  description: "Research external docs and APIs",
  prompt: """
Feature request: <FEATURE_REQUEST>
Tech stack (if known): unknown — codebase-scout is running in parallel

Produce a complete Web Research Report as specified in your instructions.
"""
)
```

Wait for both to complete. Store results as `CODEBASE_REPORT` and `WEB_REPORT`.

**After receiving reports:**
- Extract test/build/lint commands from the codebase-scout report
- Update the Context Tracker "Commands detected" fields immediately
- If all three commands are `NOT DETECTED`, warn the user before proceeding

**Validate before proceeding:** If the codebase-scout report's `### Test & Build Commands` section lists `NOT DETECTED` for the primary test command, note this in the tracker and flag it to the user — the verifier will be limited to build/lint only.

Print updated Context Tracker.

**Re-scout on revision rounds:**
- If the adversary report says "Needs codebase re-scout: YES" → re-run codebase-scout with the adversary's stated reason appended to the prompt
- If the adversary report says "Needs web re-scout: YES" → re-run web-scout with the adversary's stated reason appended to the prompt
- Update `CODEBASE_REPORT` / `WEB_REPORT` before passing to the implementer
- Print: `Re-scouting codebase — adversary flagged: <reason>`

---

## Phase 2 — Plan

Print: `Phase 2/5 — Planning implementation...`

**Invoke planner:**
```
task(
  subagent_type: "planner",
  description: "Synthesize scout reports into task plan",
  prompt: """
Feature request: <FEATURE_REQUEST>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

--- WEB RESEARCH REPORT ---
<WEB_REPORT>

Produce a complete Task Plan as specified in your instructions.
"""
)
```

Wait for completion. Store result as `TASK_PLAN`.

Print updated Context Tracker.

---

## Phase 3 — Implement

Set `ITERATION = ITERATION + 1`.

**Print the Iteration Status block** at the start of every Phase 3 entry (initial and all revisions):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ITERATION <ITERATION> / <MAX_ITERATIONS>
Goal: <FEATURE_REQUEST — one line max>
<If initial:>
  Starting initial implementation.
<If revision:>
  Adversary: <ADVERSARY_VERDICT> — <count> BLOCKERs, <count> MAJORs, <count> MINORs
  Verifier:  <VERIFIER_VERDICT> — <summary: e.g. "3 test failures", "build error", "passed">
  Sending back to implementer to address findings.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Initial round:
```
task(
  subagent_type: "implementer",
  description: "Implement feature — iteration 1",
  prompt: """
Iteration: Initial (1 of <MAX_ITERATIONS> max)
Feature request: <FEATURE_REQUEST>

--- TASK PLAN ---
<TASK_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

Implement the Task Plan completely. Produce an Implementation Report.
"""
)
```

### Revision rounds:
```
task(
  subagent_type: "implementer",
  description: "Revise implementation — iteration <ITERATION>",
  prompt: """
Iteration: Revision <ITERATION> of <MAX_ITERATIONS>
Feature request: <FEATURE_REQUEST>

--- TASK PLAN ---
<TASK_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

--- ADVERSARY REPORT ---
<ADVERSARY_REPORT>

--- VERIFIER REPORT ---
<VERIFIER_REPORT>

Address all BLOCKER and MAJOR findings from the adversary report.
Fix all test and build failures from the verifier report.
Produce an updated Implementation Report.
"""
)
```

Wait for completion. Store result as `IMPL_REPORT`.

Print updated Context Tracker.

---

## Phase 4 — Review & Verify [PARALLEL]

Print: `Phase 4/5 — Adversarial review and verification (parallel)...`

**Invoke adversary and verifier in the same response step** using two simultaneous `task` calls:

### adversary invocation:
```
task(
  subagent_type: "adversary",
  description: "Adversarial code review — iteration <ITERATION>",
  prompt: """
Feature request: <FEATURE_REQUEST>

--- IMPLEMENTATION REPORT ---
<IMPL_REPORT>

--- TASK PLAN ---
<TASK_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

Adversarially review the implementation. Produce an Adversary Report with a PASS or FAIL verdict.
"""
)
```

### verifier invocation (same step):
```
task(
  subagent_type: "verifier",
  description: "Run tests, build, lint — iteration <ITERATION>",
  prompt: """
--- IMPLEMENTATION REPORT ---
<IMPL_REPORT>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

Working directory: <current project root>

Use the test/build/lint commands from the Codebase Report — do not re-detect.
If a command is listed as NOT DETECTED, skip that step and note it.
Run the project's build, lint, and tests. Produce a Verification Report with a PASS or FAIL verdict.
"""
)
```

Wait for both. Store results as `ADVERSARY_REPORT`, `ADVERSARY_VERDICT`, `VERIFIER_REPORT`, `VERIFIER_VERDICT`.

Print updated Context Tracker.

---

## Phase 5 — Evaluate

```
IF ADVERSARY_VERDICT == PASS AND VERIFIER_VERDICT == PASS:
    → Go to Phase 6 (Done)

ELSE IF ITERATION >= MAX_ITERATIONS:
    → Go to Phase 7 (Escalate)

ELSE:
    → Check adversary re-scout recommendations
    → Re-run scouts if flagged (Phase 1 partial)
    → Go to Phase 3 (Revision round)
```

---

## Phase 6 — Done

Print the following **Final Success Report** to the user:

```
## Orchestration Complete

### Feature
<FEATURE_REQUEST>

### Result: SUCCESS

### Iterations Used
<ITERATION> of <MAX_ITERATIONS>

### What Was Built
<summary of changes from final IMPL_REPORT>

### Verification
- Adversary: PASS
- Build: <pass / fail / skipped>
- Lint: <pass / fail / warnings only / skipped>
- Tests: <pass / fail, N tests run>

### Files Changed
<list from final IMPL_REPORT>

### Notes
<any MINORs from adversary that were not fixed, with reasoning>
```

---

## Phase 7 — Escalate

Print the following **Escalation Report** to the user:

```
## Orchestration Escalated

### Feature
<FEATURE_REQUEST>

### Result: MAX ITERATIONS REACHED (<MAX_ITERATIONS>)

### Current Status
- Adversary verdict: <PASS | FAIL>
- Verifier verdict: <PASS | FAIL>

### Unresolved Issues

#### From Adversary (if FAIL)
<list remaining BLOCKERs and MAJORs>

#### From Verifier (if FAIL)
<list failing tests / build errors>

### What Was Completed
<summary of what was successfully implemented and works>

### Recommended Next Steps
<concrete suggestions for the user to resolve remaining issues manually>

### Files Changed So Far
<list from latest IMPL_REPORT>
```

---

## Orchestrator Conduct Rules

1. **Never summarize reports when passing them between agents.** Pass the full structured report text.
2. **Never skip the scouts**, even on simple requests — the verifier needs the detected test commands.
3. **Always run adversary and verifier in parallel.** Issue both `task` calls in the same response step.
4. **Always run codebase-scout and web-scout in parallel.** Issue both `task` calls in the same response step.
5. **Do not editorialize verdicts.** If adversary says FAIL, it is FAIL. Do not override based on your own reading of the code.
6. **Inform the user of progress** at the start of each phase with the status line and updated Context Tracker.
7. **On re-scout**, tell the user why: e.g. `Re-scouting codebase — adversary flagged missing context around authentication module.`
8. **Keep the user informed on each iteration** using the Iteration Status block at Phase 3 entry.
