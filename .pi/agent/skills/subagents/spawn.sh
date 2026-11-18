#!/usr/bin/env bash
# Spawn an interactive pi subagent in a tmux window of the run's fleet session.
# Usage: spawn.sh <name> <task-file> [workdir] [-- extra pi args, e.g. --model X --tools a,b]
# The run dir is the task file's directory. Report -> <run>/<name>.md, done marker -> <run>/<name>.done.
# Nested spawns share the fleet session and run dir; names get the parent prefix (parent.child).
set -euo pipefail
export TMUX_TMPDIR=${TMUX_TMPDIR:-${TMPDIR:-/tmp}}  # sandbox blocks /tmp, so the user attaches with this TMUX_TMPDIR prefix

name=$1 task=$2; shift 2
workdir=$PWD
if [ $# -gt 0 ] && [ "$1" != "--" ]; then workdir=$1; shift; fi
[ "${1:-}" = "--" ] && shift

[ -f "$task" ] || { echo "task file not found: $task" >&2; exit 1; }
run=$(cd "$(dirname "$task")" && pwd)
task=$run/$(basename "$task")
[ -n "${PI_AGENT_NAME:-}" ] && name="$PI_AGENT_NAME.$name"

depth=$(( ${PI_SUBAGENT_DEPTH:-0} + 1 ))
max_depth=${PI_SUBAGENT_MAX_DEPTH:-3}
if [ "$depth" -gt "$max_depth" ]; then
  echo "refusing: depth $depth > PI_SUBAGENT_MAX_DEPTH=$max_depth; do the work yourself" >&2; exit 2
fi

# Fleet session name: pi-fleet-<project>-<run>, fixed by the first spawn of the run (worktrees must not rename it).
if [ ! -f "$run/.fleet" ]; then
  # common dir's parent = main checkout, so a worktree in $RUN/wt/<x> still yields the repo name
  project=$(basename "$(dirname "$(git -C "$workdir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo "$workdir/.git")")")
  echo "pi-fleet-$project-$(basename "$run")" | tr '.:' '__' > "$run/.fleet"  # tmux forbids . and : in session names
fi
fleet=${PI_FLEET:-$(cat "$run/.fleet")}
max_live=${PI_FLEET_MAX:-6}

# Global concurrency cap across the whole tree: wait while too many agents are unfinished.
live() {
  tmux list-windows -t "$fleet" -F '#{window_name}' 2>/dev/null | while read -r w; do
    [ -f "$run/$w.done" ] || echo "$w"
  done | wc -l | tr -d ' '
}
while [ "$(live)" -ge "$max_live" ]; do sleep 10; done

protocol="You are subagent '$name' (depth $depth of max $max_depth), started by another agent; nobody reads your chat.
When finished: write your final report to $run/$name.md with the write tool, then create the file $run/$name.done containing DONE. Then stop.
If you cannot finish, still write the report explaining why, then the .done file.
You may spawn your own subagents only via the subagents skill (spawn.sh); they will be prefixed '$name.'."

env_args=(-e PI_SUBAGENT=1 -e "PI_SUBAGENT_DEPTH=$depth" -e "PI_SUBAGENT_MAX_DEPTH=$max_depth"
  -e "PI_FLEET=$fleet" -e "PI_FLEET_MAX=$max_live" -e "PI_AGENT_NAME=$name" -e "PI_RUN=$run")
cmd=(pi --name "$name" --session-dir "$run/sessions" --append-system-prompt "$protocol" "$@" "@$task")

rm -f "$run/$name.done"
if tmux has-session -t "$fleet" 2>/dev/null; then
  win=$(tmux new-window -d -P -F '#{window_id}' -t "$fleet:" -n "$name" -c "$workdir" "${env_args[@]}" "${cmd[@]}")
else
  win=$(tmux new-session -d -P -F '#{window_id}' -s "$fleet" -n "$name" -c "$workdir" -x 200 -y 50 "${env_args[@]}" "${cmd[@]}")
fi
echo "$win" > "$run/$name.win"  # window id: names may contain dots, which tmux targets treat as pane separators
tmux set-option -w -t "$win" remain-on-exit on  # keep crashed panes visible
echo "spawned $name; watch: TMUX_TMPDIR=$TMUX_TMPDIR tmux attach -t $fleet"
