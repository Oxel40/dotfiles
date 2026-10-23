---
name: checks
description: >-
  Run every check in .agents/checks/ against the diff, one subagent each, in
  parallel. Codified conventions — complements the built-in /review, which
  covers general correctness. Usage: /checks [scope]
severity-default: medium
---

Run the project's review checks in parallel. You are the aggregator only — you
do NOT review any code yourself. Use the subagent protocol (task files + `pi -p`
with `PI_SUBAGENT=1`) for parallel dispatch, not opencode task calls.

1. **DETERMINE SCOPE.** If the following is non-empty, use it as the scope (a
   git ref range, `--staged`, a commit hash, or a path): user's argument.
   Otherwise use `git diff`. If that is empty use `git diff --staged`. If that
   is also empty use `git show HEAD`. Also run `git status --short` to catch
   untracked files — they are part of the change and no diff will show them.
   State the resolved scope in one line.

2. **COLLECT CHECKS.** Glob `.agents/checks/*.md` under the project root and
   `~/.agents/checks/*.md`. Read each one. A project check overrides a global
   check with the same `name` in its frontmatter.

3. **DISPATCH.** Create a temp workdir:
   `RUN=${TMPDIR:-/tmp}/pi-fleet/$(date +%Y%m%d-%H%M%S); mkdir -p $RUN`.
   Issue ONE task file per check, ALL IN THE SAME BASH CALL so they run in
   parallel. Each brief is written to `$RUN/<name>.task.md` via the `write` tool:

   ```markdown
   You are a reviewer running a specific check against a code diff.

   CHECK NAME: <name>
   SEVERITY DEFAULT: <severity-default from frontmatter>

   THE RULE TO APPLY:
   (paste the FULL body of the .md file verbatim — do not summarize)

   SCOPE (run these commands to gather context):
   git diff <scope>    # or whatever scope you determined
   git status --short

   REPORT FORMAT:
   - If the check passed, reply exactly: `CLEAN`
   - If it found issues, for each one state: SEVERITY, file:line, what it is,
     suggested fix. Be terse — just the finding and why it matters.
   ```

   Then spawn them as background subagents:
   ```bash
   PI_SUBAGENT=1 pi -p --no-session @$RUN/security.task.md > $RUN/security.md 2> $RUN/security.err &
   PI_SUBAGENT=1 pi -p --no-session @$RUN/error-handling.task.md > $RUN/error-handling.md 2> $RUN/error-handling.err &
   # ... one per check ...
   wait
   ```

   If no check files exist anywhere, say so and stop — do not invent a review.

4. **READ REPORTS.** `read` each `$RUN/<name>.md`. Empty report means the worker
   hit an error — check `.err`. A report containing only `CLEAN` means the check
   passed with no findings.

5. **AGGREGATE.** Group findings by severity: critical, high, medium, low.
   Drop exact duplicates at the same file:line. Name any check that returned
   clean or was empty (if empty, note "subagent error — did not produce output").
   Do not add findings of your own, do not soften or reword a finding, and do
   not fix anything — this is a report.

6. End with a one-line verdict: total findings by severity, and whether anything
   blocks a commit (critical or high does; medium and low do not).
