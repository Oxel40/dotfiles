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

## State to Track

Maintain these values throughout the session:

```
FEATURE_REQUEST: <the original user prompt>
ITERATION: 0
MAX_ITERATIONS: 5
CODEBASE_REPORT: null
WEB_REPORT: null
DRAFT_PLAN: null
ORACLE_PLAN_REVIEW: null
TASK_PLAN: null
IMPL_REPORT: null
ADVERSARY_VERDICT: null
VERIFIER_VERDICT: null
```

---

## Phase 1 — Scout (runs once at start, may re-run on revision)

Both briefs go to opencode's **built-in `explore` subagent** — there is no
separate scout agent. `explore` already holds `websearch`, `webfetch`, `bash`
and `read` permissions, so the external brief is fully within its powers; do
not add a `scout` agent back. `explore` has no report format of its own, so
each brief below must specify it in full.

**Issue both as `task` calls in a single response** so they run in parallel.
Two calls, same `subagent_type: "explore"`, different briefs. Do not wait for
one before starting the other.

### `explore` brief (codebase):
```
Feature request: <FEATURE_REQUEST>
Working directory: <current project root>

Map this codebase for the feature above. Do not modify anything.
Return exactly these sections:

## Tech Stack
Languages, frameworks, package manager, notable libraries — with the file
that proves each (package.json, go.mod, pyproject.toml, ...).

## Commands
Build, test, lint, typecheck, run. Exact commands, taken from package.json
scripts / Makefile / CI config. Say "none found" rather than guessing.

## Relevant Files
Every file the feature will need to read or change, with a one-line reason.
file:line for the specific functions that matter.

## Existing Patterns
How this codebase already does the thing being asked for — error handling,
config, testing, module layout. The implementer must match these, not
invent new ones.

## Constraints & Gotchas
Anything that will break a naive implementation.
```

### `explore` brief (external):
```
Feature request: <FEATURE_REQUEST>
Tech stack (if known): <from the explore run, or "unknown">

Research what is needed to implement the above correctly. You may clone and
read dependency source. Do not modify the workspace.
Return exactly these sections:

## Relevant APIs
The specific functions/types to use, with real signatures read from the
installed version's source — not remembered ones. Note the version.

## Correct Usage
Minimal correct example for each, in the project's language.

## Pitfalls
Deprecations, breaking changes, and common misuse for THIS version.

## Sources
File paths in cloned source, or URLs. Mark anything you could not verify.
```

Wait for both to complete. Store results as CODEBASE_REPORT and WEB_REPORT.

**Skip the external `explore` call entirely** if the feature uses no external library the
codebase does not already use. Say so in one line and set WEB_REPORT to
"skipped — no new external dependencies".

**Re-scout on revision rounds:**
- If the adversary report says "Needs codebase re-scout: YES" → re-run `explore` with the codebase brief plus the adversary's stated reason as additional context
- If the adversary report says "Needs web re-scout: YES" → re-run `explore` with the external brief plus the adversary's stated reason as additional context
- Update the stored reports before passing to implementer

---

## Phase 2 — Plan

### Phase 2a — Draft

**Invoke planner** as a subagent.

### planner brief:
```
You are the planner agent.

Feature request: <FEATURE_REQUEST>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

--- WEB RESEARCH REPORT ---
<WEB_REPORT>

Produce a complete Task Plan as specified in your instructions.
```

Wait for completion. Store result as DRAFT_PLAN.

### Phase 2b — Oracle review

**Invoke oracle** as a subagent.

### oracle brief:
```
You are the oracle agent.

Feature request: <FEATURE_REQUEST>
Working directory: <current project root>

--- DRAFT TASK PLAN ---
<DRAFT_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

--- WEB RESEARCH REPORT ---
<WEB_REPORT>

Review the draft plan before implementation. Verify its file paths and line
references against the actual code. Identify incorrect assumptions, missing
steps, unnecessary work, and simpler approaches. Return your standard oracle
analysis with concrete recommendations for the planner. If the plan is sound,
say so briefly — do not manufacture objections.
```

Wait for completion. Store result as ORACLE_PLAN_REVIEW.

### Phase 2c — Revise

**Invoke planner** as a subagent for the single revision round.

### planner revision brief:
```
You are the planner agent.

Feature request: <FEATURE_REQUEST>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

--- WEB RESEARCH REPORT ---
<WEB_REPORT>

--- DRAFT TASK PLAN ---
<DRAFT_PLAN>

--- ORACLE PLAN REVIEW ---
<ORACLE_PLAN_REVIEW>

Revise the draft using the oracle's review. Return a complete replacement Task
Plan in your standard format. Do not return a diff, changelog, or list of
edits. Where the oracle's direct file reads contradict the codebase report,
prefer the oracle; if the disagreement is material, record it under Risks &
Open Questions.
```

Wait for completion. Store result as TASK_PLAN. The plan review runs exactly
once; implementation revision rounds resume at Phase 3 and never re-invoke the
planner or oracle.

---

## Phase 3 — Implement

Set `ITERATION = ITERATION + 1`.

**Invoke implementer** as a subagent.

### implementer brief (initial round):
```
You are the implementer agent.

Iteration: Initial (1 of 5 max)
Feature request: <FEATURE_REQUEST>

--- TASK PLAN ---
<TASK_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

Implement the Task Plan completely. Produce an Implementation Report.
```

### implementer brief (revision rounds):
```
You are the implementer agent.

Iteration: Revision <ITERATION> of <MAX_ITERATIONS>
Feature request: <FEATURE_REQUEST>

--- TASK PLAN ---
<TASK_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT (updated if re-scouted)>

--- ADVERSARY REPORT ---
<ADVERSARY_REPORT>

--- VERIFIER REPORT ---
<VERIFIER_REPORT>

Address all BLOCKER and MAJOR findings from the adversary report.
Fix all test and build failures from the verifier report.
Produce an updated Implementation Report.
```

Wait for completion. Store result as IMPL_REPORT.

---

## Phase 4 — Review & Verify (parallel)

**Invoke adversary and verifier simultaneously** using the `task` tool.

### adversary brief:
```
You are the adversary agent.

Feature request: <FEATURE_REQUEST>

--- IMPLEMENTATION REPORT ---
<IMPL_REPORT>

--- TASK PLAN ---
<TASK_PLAN>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

Adversarially review the implementation. Produce an Adversary Report with a PASS or FAIL verdict.
```

### verifier brief:
```
You are the verifier agent.

--- IMPLEMENTATION REPORT ---
<IMPL_REPORT>

--- CODEBASE REPORT ---
<CODEBASE_REPORT>

Working directory: <current project root>

Run the project's build, lint, and tests. Produce a Verification Report with a PASS or FAIL verdict.
```

Wait for both. Store results as ADVERSARY_REPORT and VERIFIER_REPORT.

---

## Phase 5 — Evaluate

```
IF ADVERSARY_VERDICT == PASS AND VERIFIER_VERDICT == PASS:
    → Go to Phase 6 (Done)

ELSE IF a BLOCKER or MAJOR with the same root cause as last round survived:
    → Go to Phase 7 (Escalate) — do not spend remaining iterations

ELSE IF ITERATION >= MAX_ITERATIONS:
    → Go to Phase 7 (Escalate)

ELSE:
    → Check adversary re-scout recommendations
    → Re-run scouts if needed (Phase 1 partial)
    → Go to Phase 3 (Revision round)
```

### Early escalation

A finding that survives a full revision round means the **plan** is wrong, not
the code. More implementer rounds will not fix it, they will just burn tokens
producing variations of the same mistake.

Track REPEATED_FINDINGS across rounds. Compare by root cause, not by wording —
the adversary may describe the same defect differently each round. The moment a
BLOCKER or MAJOR appears in two consecutive adversary reports, or the same test
fails in two consecutive verifier reports after the implementer claimed to fix
it, stop and escalate. Name the stuck finding explicitly in the escalation
report and say which phase you believe is at fault (usually the plan, sometimes
a scout report that missed context).

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
- Build: <pass/fail>
- Lint: <pass/fail or skipped>
- Tests: <pass/fail, N tests run>

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

### Result: <MAX ITERATIONS REACHED (<MAX_ITERATIONS>) | STUCK — finding survived a revision round>

### Current Status
- Adversary verdict: <PASS | FAIL>
- Verifier verdict: <PASS | FAIL>
- Iterations used: <ITERATION> of <MAX_ITERATIONS>

### Stuck Finding (if escalated early)
<the finding that survived, and which phase is at fault — plan, or a scout
report that missed context>

### Unresolved Issues

#### From Adversary (if FAIL)
<list remaining BLOCKERs and MAJORs>

#### From Verifier (if FAIL)
<list failing tests/build errors>

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
2. **Never skip the codebase `explore` call**, even on simple requests — the verifier needs the detected test command. The external brief may be skipped when no new external dependency is involved.
3. **Always run adversary and verifier in parallel.** Use the `task` tool with two simultaneous invocations.
4. **Do not editorialize verdicts.** If adversary says FAIL, it's FAIL. Do not override based on your own reading of the code.
5. **Inform the user of progress** at the start of each phase with a brief one-line status: e.g. `Phase 1/5 — Scouting codebase and web...`
6. **On re-scout**, tell the user why: `Re-scouting codebase — adversary flagged missing context around authentication module.`
7. **Keep the user informed on each iteration**: `Revision 2/5 — adversary found 2 BLOCKERs, verifier: 3 test failures. Sending back to implementer.`
8. **Run plan review exactly once.** Phase 2 always runs draft → oracle review → planner revision. Implementation revision rounds return to Phase 3, not Phase 2.
