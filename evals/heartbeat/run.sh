#!/bin/bash
# Heartbeat real-work test. Each agent is asked to run ./job.sh and say when it finishes,
# with the heartbeat block off and on, in throwaway folders.
# "slow": the job prints a step every 20 seconds and finishes after 3 minutes.
# "stall": the same script, but another process holds its lock, so it prints one step and hangs.
# The agent sees the same script and the same request either way.
# The shell is limited to ./job.sh and sleep: Claude Code by --allowedTools, Pi by gate.ts.
# Our own global instructions, hooks, extensions and skills are switched off.
# Each agent runs in its own process namespace with its own /tmp (bubblewrap), so it cannot
# see the other runs, their files, or this script in the process list. The lock holder stays outside, as an unknown process would.
# Needs bwrap (bubblewrap). Usage: evals/heartbeat/run.sh [claude] [pi]    (OUT=dir to resume, LIMIT=seconds per run, REPS=n)
set -u
here=$(cd "$(dirname "$0")" && pwd); repo=$(cd "$here/../.." && pwd)
block=$repo/skills/heartbeat/block.md
out=${OUT:-$repo/evals/results/$(date -u +%Y%m%dT%H%MZ)-heartbeat}; mkdir -p "$out"
agents=${*:-claude pi}; limit=${LIMIT:-420}
ask="Run ./job.sh and tell me when it finishes."

run() { # agent cond task rep
  f=$out/$1.$2.$3.$4; [ -s "$f.jsonl" ] && return
  d=$(mktemp -d); cp "$here"/fixture/job.sh "$d"/
  [ "$3" = stall ] && (cd "$d" && flock .job.lock sleep 100000 > /dev/null 2>&1 &) && sleep 1
  if [ "$2" = on ]; then
    cp "$block" "$d/CLAUDE.md"; cp "$block" "$d/AGENTS.md"
    mkdir -p "$d/.claude/skills"; cp -r "$repo/skills/heartbeat" "$d/.claude/skills/"
  fi
  box=(bwrap --dev-bind / / --tmpfs /tmp --bind "$d" "$d" --unshare-pid --proc /proc --die-with-parent)
  t0=$(date +%s)
  if [ "$1" = claude ]; then
    (set -o pipefail; cd "$d" && env -u BB_THREAD_ID -u BB_THREAD_STORAGE -u BB_FOLD_UNATTENDED \
      timeout "$limit" "${box[@]}" claude -p "$ask" --setting-sources project \
      --settings "{\"claudeMdExcludes\":[\"$HOME/.claude/CLAUDE.md\"]}" \
      --output-format stream-json --verbose \
      --allowedTools "Read,TaskStop,Bash(./job.sh:*),Bash(sleep:*)" \
      < /dev/null 2>&1 | python3 "$here/stamp.py" > "$f.jsonl")
  else
    on=(); [ "$2" = on ] && on=(--append-system-prompt "$d/AGENTS.md" --skill "$d/.claude/skills/heartbeat")
    (set -o pipefail; cd "$d" && timeout "$limit" "${box[@]}" pi -p --mode json --no-session -nc -ns -ne --no-mcp \
      -e "$here/gate.ts" -t read,bash "${on[@]}" "$ask" < /dev/null 2>&1 | python3 "$here/stamp.py" > "$f.jsonl")
  fi
  rc=$?
  # What really happened: how long the run took and whether the time limit cut it off.
  # The sandbox ends the job with the agent; this also stops the lock holder.
  for p in /proc/[0-9]*; do
    [ "$(readlink "$p/cwd" 2>/dev/null)" = "$d" ] && kill "${p#/proc/}" 2>/dev/null
  done
  printf '{"seconds": %s, "exit": %s}\n' "$(( $(date +%s) - t0 ))" "$rc" > "$f.truth.json"
  rm -rf "$d"
}

for rep in $(seq 1 "${REPS:-1}"); do
  for agent in $agents; do for cond in off on; do for t in slow stall; do
    run "$agent" "$cond" "$t" "$rep" &
  done; done; done
done
wait
python3 "$here/score.py" "$out" | tee "$out/results.md"
if grep -l -i -F -e "$(hostname)" -e "$(id -un)" "$out"/*.jsonl 2>/dev/null; then
  echo "Warning: the files above name this machine or user. Redact them before publishing."
fi
