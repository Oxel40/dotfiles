#!/usr/bin/env bash
# Wait until the named subagents have written <run>/<name>.done.
# Usage: wait.sh <run-dir> [--timeout SECONDS] <name>...   (names as printed by spawn.sh)
# Exit 0: all done. Exit 1: some agent's pane died without .done. Exit 124: timeout.
# On failure/timeout prints the last lines of each unfinished pane.
set -uo pipefail
export TMUX_TMPDIR=${TMUX_TMPDIR:-${TMPDIR:-/tmp}}  # sandbox blocks /tmp; your terminal must use the same dir to attach

run=$1; shift
timeout=1500
if [ "${1:-}" = "--timeout" ]; then timeout=$2; shift 2; fi
start=$SECONDS

report() {
  for n in "$@"; do
    [ -f "$run/$n.done" ] && continue
    echo "--- $n (not done) ---"
    tmux capture-pane -p -t "$(cat "$run/$n.win" 2>/dev/null)" -S -200 2>/dev/null | grep -v "^ *$" | tail -25
  done
}

while :; do
  pending=() dead=()
  for n in "$@"; do
    [ -f "$run/$n.done" ] && continue
    pending+=("$n")
    w=$(cat "$run/$n.win" 2>/dev/null) || continue  # not spawned yet (spawn.sh may be waiting for a slot)
    d=$(tmux display-message -p -t "$w" '#{pane_dead}' 2>/dev/null || echo 1)
    [ "$d" = 1 ] && dead+=("$n")
  done
  [ ${#pending[@]} -eq 0 ] && { echo "all done: $*"; exit 0; }
  if [ ${#dead[@]} -gt 0 ]; then echo "exited without .done: ${dead[*]}"; report "${dead[@]}"; exit 1; fi
  if [ $((SECONDS - start)) -ge "$timeout" ]; then
    echo "timeout after ${timeout}s; still running: ${pending[*]}"; report "${pending[@]}"; exit 124
  fi
  sleep 10
done
