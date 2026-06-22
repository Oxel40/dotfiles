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
TASK_PLAN: null
IMPL_REPORT: null
ADVERSARY_VERDICT: null
VERIFIER_VERDICT: null
```

---

## Phase 1 — Scout (runs once at start, may re-run on revision)

**Invoke both scouts in parallel** using the `task` tool. Do not wait for one before starting the other.

### codebase-scout brief:
```
You are the codebase-scout agent.

Feature request: <FEATURE_REQUEST>
Working directory: <current project root>

Produce a complete Codebase Report as specified in your instructions.
```

### web-scout brief:
```
You are the web-scout agent.

Feature request: <FEATURE_REQUEST>
Tech stack (if known): <from prior codebase-scout run, or "unknown">

Produce a complete Web Research Report as specified in your instructions.
```

Wait for both to complete. Store results as CODEBASE_REPORT and WEB_REPORT.

**Re-scout on revision rounds:**
- If the adversary report says "Needs codebase re-scout: YES" → re-run codebase-scout with the adversary's stated reason as additional context
- If the adversary report says "Needs web re-scout: YES" → re-run web-scout with the adversary's stated reason as additional context
- Update the stored reports before passing to implementer

---

## Phase 2 — Plan

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

Wait for completion. Store result as TASK_PLAN.

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

ELSE IF ITERATION >= MAX_ITERATIONS:
    → Go to Phase 7 (Escalate)

ELSE:
    → Check adversary re-scout recommendations
    → Re-run scouts if needed (Phase 1 partial)
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

### Result: MAX ITERATIONS REACHED (<MAX_ITERATIONS>)

### Current Status
- Adversary verdict: <PASS | FAIL>
- Verifier verdict: <PASS | FAIL>

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
2. **Never skip the scouts**, even on simple requests — the verifier needs the detected test command.
3. **Always run adversary and verifier in parallel.** Use the `task` tool with two simultaneous invocations.
4. **Do not editorialize verdicts.** If adversary says FAIL, it's FAIL. Do not override based on your own reading of the code.
5. **Inform the user of progress** at the start of each phase with a brief one-line status: e.g. `Phase 1/5 — Scouting codebase and web...`
6. **On re-scout**, tell the user why: `Re-scouting codebase — adversary flagged missing context around authentication module.`
7. **Keep the user informed on each iteration**: `Revision 2/5 — adversary found 2 BLOCKERs, verifier: 3 test failures. Sending back to implementer.`
