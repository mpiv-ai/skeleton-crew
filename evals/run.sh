#!/bin/sh
# Ask each agent the same questions with a skill off and on, then score the answers.
# Usage: [SKILL=receipts] evals/run.sh [claude] [codex] [pi]     (default: bluf, every agent found on this machine)
# "On" puts the skill's block and the skill in the project folder; "off" uses an empty folder.
# bluf uses evals/prompts.tsv and score.py; any other skill uses evals/<skill>/prompts.tsv and score.py.
# Claude Code and Pi skip your own global instructions and hooks (set ISOLATE=0 to keep them).
# Codex has no switch for that, so its global AGENTS.md applies in both runs: compare its on and off only.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"; repo="$(dirname "$here")"
agents="$*"; [ -n "$agents" ] || for a in claude codex pi; do command -v "$a" >/dev/null && agents="$agents $a"; done
skill="${SKILL:-bluf}"; set_dir="$here"; [ "$skill" = bluf ] || set_dir="$here/$skill"
[ -f "$set_dir/prompts.tsv" ] || { echo "No prompts for $skill in $set_dir"; exit 1; }
block="$(cat "$repo/skills/$skill/block.md")"
out="${OUT:-$here/results/$(date -u +%Y%m%dT%H%MZ)${SKILL:+-$SKILL}}"; mkdir -p "$out"   # set OUT to resume a run

ask() { # agent dir prompt outfile
  case "$1" in
    claude) if [ "${ISOLATE:-1}" = 1 ]; then
              (cd "$2" && timeout 180 claude -p --setting-sources project,local \
                --settings "{\"claudeMdExcludes\":[\"$HOME/.claude/CLAUDE.md\"]}" "$3" < /dev/null > "$4" 2>/dev/null)
            else (cd "$2" && timeout 180 claude -p "$3" < /dev/null > "$4" 2>/dev/null); fi ;;
    codex)  (cd "$2" && timeout 180 codex exec --skip-git-repo-check -o "$4" "$3" < /dev/null >/dev/null 2>&1) ;;
    pi)     if [ "${ISOLATE:-1}" = 1 ]; then
              pdir="$2"; pprompt="$3"; pout="$4"; set -- --no-context-files
              [ -f "$pdir/AGENTS.md" ] && set -- "$@" --append-system-prompt "$pdir/AGENTS.md"
              (cd "$pdir" && timeout 180 pi -p --no-session "$@" "$pprompt" < /dev/null > "$pout" 2>/dev/null)
            else (cd "$2" && timeout 180 pi -p --no-session "$3" < /dev/null > "$4" 2>/dev/null); fi ;;
  esac || true
}

for agent in $agents; do (
  tail -n +2 "$set_dir/prompts.tsv" | while IFS="$(printf '\t')" read -r id kind prompt; do
    case " ${ONLY:-$id} " in *" $id "*) ;; *) continue ;; esac   # ONLY="id1 id2" limits prompts
    for cond in ${CONDS:-off on}; do
      [ -s "$out/$agent.$cond.$id.txt" ] && continue   # already answered
      dir="$(mktemp -d)"
      if [ "$cond" = on ]; then
        printf '%s\n' "$block" > "$dir/CLAUDE.md"; cp "$dir/CLAUDE.md" "$dir/AGENTS.md"
        mkdir -p "$dir/.claude/skills" "$dir/.agents/skills"
        cp -r "$repo/skills/$skill" "$dir/.claude/skills/"; cp -r "$repo/skills/$skill" "$dir/.agents/skills/"
      fi
      ask "$agent" "$dir" "$prompt" "$out/$agent.$cond.$id.txt"
      rm -rf "$dir"
    done
  done ) &
done
wait
python3 "$set_dir/score.py" "$out" "$set_dir/prompts.tsv" | tee "$out/results.md"

# Answers can mention the test machine. Flag them before you publish the results.
if grep -l -i -F -e "$(hostname)" -e "$(id -un)" "$out"/*.txt 2>/dev/null; then
  echo "Warning: the files above name this machine or user. Redact them before publishing."
fi
