---
name: subagents
description: >
  Spawn and coordinate pi subagents in tmux so the user can watch and steer
  them. Subagents may spawn their own subagents (depth-limited). Use when a
  task benefits from parallel work, isolated context (scouting, reviewing),
  or long-running workers. Triggers: "subagent", "spawn agents", "fan out",
  "in parallel", "fleet", "worker", "delegate".
---

# Subagents

A subagent is an interactive `pi` running in a window of a tmux session (one session per run, called the "fleet"). The user can attach and watch every agent, at every level, live.

Scripts (in this skill's dir, `S=/Users/p901vln/.pi/agent/skills/subagents`):
- `$S/spawn.sh <name> <task-file> [workdir] [-- pi args]`: start an agent. Reads the brief from the task file. The agent must write `<run>/<name>.md` (its report), then `<run>/<name>.done`. The script adds this rule to the agent's system prompt for you.
- `$S/wait.sh <run> [--timeout SEC] <name>...`: block until those agents are done. Exit 0 = done, 1 = an agent died without finishing, 124 = timeout. On 1 or 124 it prints the tail of each unfinished pane.

## Are you a subagent?

If `PI_SUBAGENT=1`, yes. `PI_RUN` is the shared run dir, `PI_AGENT_NAME` is your name, and `PI_SUBAGENT_DEPTH` / `PI_SUBAGENT_MAX_DEPTH` show how deep you are. You may spawn children the same way (put their task files in `$PI_RUN`). Their names get your prefix automatically (`impl.tests`), so pass that full name to `wait.sh`. spawn.sh refuses once max depth (default 3) is reached. Then do the work yourself. Whatever happens, finish with your `.md` report and the `.done` file.

## Workflow

Top-level orchestrator: create the run dir once.

```bash
RUN=${TMPDIR:-/tmp}/pi-fleet/$(date +%Y%m%d-%H%M%S); mkdir -p $RUN; echo $RUN   # /tmp is not writable here
```

Each bash call starts a fresh shell, so use the literal echoed path afterwards.

1. Write each brief to `$RUN/<name>.task.md` with the `write` tool. The worker sees none of your context. Include the goal, cwd, relevant files, constraints and the exact report format. Keep reports short; you read the report, not the transcript.
2. Spawn (returns immediately):
   ```bash
   $S/spawn.sh scout-auth $RUN/scout-auth.task.md /path/to/repo -- --model github-copilot/gpt-6-luna:medium --tools read,grep,find,ls,bash,write
   $S/spawn.sh scout-db   $RUN/scout-db.task.md   /path/to/repo -- --model github-copilot/gpt-6-luna:medium --tools read,grep,find,ls,bash,write
   ```
3. **Print the watch command for the user, copied exactly** from spawn.sh's output, in a code block, once per run:
   `TMUX_TMPDIR=/var/folders/.../T/ tmux attach -t pi-fleet-<project>-<run>`
   The prefix is required: the sandbox blocks `/tmp`, so tmux keeps its socket in `$TMPDIR`. `<project>` is the git repo name of the first agent's workdir. Also tell the user how to move around: `Ctrl-b w` opens a tree of all agents, including nested ones, and `Ctrl-b d` detaches.
4. Wait (use a bash timeout larger than `--timeout`, e.g. 1800 vs 1500):
   ```bash
   $S/wait.sh $RUN --timeout 1500 scout-auth scout-db
   ```
5. `read` `$RUN/<name>.md`. Pass a report to the next worker as a file (`@$RUN/scout-auth.md` in its brief). Never re-type it.

## Inspect / steer / clean up

All commands need `export TMUX_TMPDIR=$TMPDIR` first. The window id is in `$RUN/<name>.win`. Do not target windows by name: dots in names break tmux targets.

- Peek: `tmux capture-pane -p -t $(cat $RUN/<name>.win) -S -60`
- Steer: `tmux send-keys -t $(cat $RUN/<name>.win) "also cover logout" Enter`
- List: `tmux list-windows -t $(cat $RUN/.fleet) -F '#{window_name} dead=#{pane_dead}'`
- Done with the run: `tmux kill-session -t $(cat $RUN/.fleet)`. Agents stay alive after `.done` so the user can inspect them, so ask the user before killing if they may still be watching.
- Transcripts are saved in `$RUN/sessions/`.

Stuck agent (no `.done`, idle pane)? Peek at it. It may be sitting at a prompt such as project trust, or have finished without writing the files. Steer it with send-keys.

## Model choice

Pick from this table. Do not invent others. Omit `--model` to inherit the default.

| Role | Model | Tools |
|------|-------|-------|
| scout (find/map/summarize code) | `github-copilot/gpt-6-luna:medium` | `read,grep,find,ls,bash,write` |
| planner / hard reasoning | default (omit) | `read,grep,find,ls,bash,write` |
| implementer | default (omit) | default (omit) |
| reviewer | `github-copilot/gpt-6-sol` (a different model family from the implementer catches more) | `read,grep,find,ls,bash,write` |

Every agent needs `write` (for its report) and `bash` (to spawn children). For read-only roles, say in the brief: "do not modify files except your report". Neither `bash` nor `write` is truly read-only.

## Parallel writers need worktrees

Two workers editing the same checkout will overwrite each other's changes. Read-only workers can share one.

```bash
git worktree add ../$(basename $PWD)-impl-auth -b impl-auth   # pass that dir as spawn.sh's workdir
# merge back, then: git worktree remove ../<dir>
```

## Rules

- Concurrency is capped across the whole tree (`PI_FLEET_MAX`, default 6 unfinished agents). spawn.sh blocks until a slot frees up. A parent waiting on children still counts, so keep trees shallow and narrow.
- Spawn children only when the subtask is big or parallel. Don't delegate what you can do in a couple of tool calls.
- Verify worker claims (run the tests yourself) before reporting success upward or to the user.
