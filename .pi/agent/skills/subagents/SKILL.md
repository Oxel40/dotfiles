---
name: subagents
description: >
  Spawn and coordinate pi subagents via bash (`pi -p`) or tmux sessions. Use
  when a task benefits from parallel work, isolated context (scouting,
  reviewing), or long-running workers the user may want to watch or steer.
  Triggers: "subagent", "spawn agents", "fan out", "in parallel", "fleet",
  "worker", "delegate".
---

# Subagents

A subagent is just another `pi` process. You (the orchestrator) spawn it with bash.

**If env `PI_SUBAGENT=1` is set, you ARE a subagent: do not spawn others. Do your task.**

## Workspace

One dir per run. Every worker gets a task file in, writes a report file out.

```bash
RUN=${TMPDIR:-/tmp}/pi-fleet/$(date +%Y%m%d-%H%M%S); mkdir -p $RUN   # /tmp is not writable here
```

Each bash call is a fresh shell: echo `$RUN` once and use the literal path afterwards.

Write each brief to `$RUN/<name>.task.md` with the `write` tool (avoids shell quoting hell). A brief must be self-contained: the worker sees none of your context. Include: goal, cwd, relevant files, constraints, and the exact report format you want back. Keep reports short; you read them, not the transcript.

## Model choice

Pick from this table. Do not invent others. Omit `--model` to inherit the default.

| Role | Model | Tools |
|------|-------|-------|
| scout (find/map/summarize code) | `github-copilot/gpt-6-luna:medium` | `read,grep,find,ls,bash` |
| planner / hard reasoning | default (omit) | `read,grep,find,ls` |
| implementer | default (omit) | default (omit) |
| reviewer | `github-copilot/gpt-6-sol` (different family than implementer catches more) | `read,grep,find,ls,bash` |

Read-only roles: also say "do not modify files" in the brief; `bash` is not truly read-only.

## Level 1: one-shot, `pi -p` (default)

Worker runs, prints its final answer, exits. Use for scouts, planners, reviewers, bounded implementations.

```bash
PI_SUBAGENT=1 pi -p --no-session --model github-copilot/gpt-6-luna:medium \
  --tools read,grep,find,ls,bash @$RUN/scout-auth.task.md > $RUN/scout-auth.md 2> $RUN/scout-auth.err &
PI_SUBAGENT=1 pi -p --no-session --model github-copilot/gpt-6-luna:medium \
  --tools read,grep,find,ls,bash @$RUN/scout-db.task.md > $RUN/scout-db.md 2> $RUN/scout-db.err &
wait
```

Then `read` the `.md` reports. Empty report → check `.err`.
Run in the background with `&` + `wait` in ONE bash call, and set a generous bash timeout (e.g. 1800s).

## Level 2: tmux, interactive and steerable

Use when the job is long, the user wants to watch, or you may need to steer mid-way. The worker stays alive after finishing, so tell it in the brief: *"When done, write your report to `$RUN/<name>.md`, then write `DONE` to `$RUN/<name>.done`."*

```bash
tmux new-session -d -s pi-impl-auth -c "$WORKDIR" \
  "PI_SUBAGENT=1 pi --name impl-auth @$RUN/impl-auth.task.md"
```

- Check progress: `tmux capture-pane -p -t pi-impl-auth -S -60`
- Wait for done: `until [ -f $RUN/impl-auth.done ]; do sleep 15; done`
- Steer: `tmux send-keys -t pi-impl-auth "also cover the logout path" Enter`
- List: `tmux ls | grep '^pi-'`
- Clean up when done: `tmux kill-session -t pi-impl-auth`

Tell the user the session name so they can `tmux attach -t <name>`.
Session is saved (no `--no-session`) so the user can resume with `pi -r`.

## Parallel writers need worktrees

Two workers editing the same checkout will clobber each other. Read-only workers can share.

```bash
git worktree add ../$(basename $PWD)-impl-auth -b impl-auth
# ... worker runs with -c / cd into that dir ...
# merge back, then: git worktree remove ../<dir>
```

## Rules

- Max ~4 concurrent workers (rate limits).
- One orchestrator only; workers never spawn workers.
- Pass reports between workers as files (`@$RUN/scout-auth.md` in the next brief), never re-type them.
- Don't delegate what you can do in a couple of tool calls yourself. Delegate for parallelism or to keep big exploration out of your context.
- Verify worker claims (run the tests yourself) before reporting success to the user.
