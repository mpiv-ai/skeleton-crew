#!/bin/sh
# Ask each agent the same questions with BLUF off and on, then score the answers.
# Usage: evals/run.sh [claude] [codex] [pi]     (default: every agent found on this machine)
# "On" puts the BLUF block and skill in the project folder; "off" uses an empty folder.
# Your own global instructions still apply in both runs, so compare on and off, not agents.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"; repo="$(dirname "$here")"
out="$here/results/$(date -u +%Y%m%dT%H%MZ)"; mkdir -p "$out"
agents="$*"; [ -n "$agents" ] || for a in claude codex pi; do command -v "$a" >/dev/null && agents="$agents $a"; done
block="$(sed -n "/^cat > \"\$work\/new\" <<'BLOCK'$/,/^BLOCK$/p" "$repo/install.sh" | sed '1d;$d')"

ask() { # agent dir prompt outfile
  case "$1" in
    claude) (cd "$2" && timeout 180 claude -p "$3" < /dev/null > "$4" 2>/dev/null) ;;
    codex)  (cd "$2" && timeout 180 codex exec --skip-git-repo-check -o "$4" "$3" < /dev/null >/dev/null 2>&1) ;;
    pi)     (cd "$2" && timeout 180 pi -p --no-session "$3" < /dev/null > "$4" 2>/dev/null) ;;
  esac || true
}

for agent in $agents; do (
  tail -n +2 "$here/prompts.tsv" | while IFS="$(printf '\t')" read -r id kind prompt; do
    for cond in off on; do
      dir="$(mktemp -d)"
      if [ "$cond" = on ]; then
        printf '%s\n' "$block" > "$dir/CLAUDE.md"; cp "$dir/CLAUDE.md" "$dir/AGENTS.md"
        mkdir -p "$dir/.claude/skills" "$dir/.agents/skills"
        cp -r "$repo/skills/bluf" "$dir/.claude/skills/"; cp -r "$repo/skills/bluf" "$dir/.agents/skills/"
      fi
      ask "$agent" "$dir" "$prompt" "$out/$agent.$cond.$id.txt"
      rm -rf "$dir"
    done
  done ) &
done
wait
python3 "$here/score.py" "$out" "$here/prompts.tsv" | tee "$out/results.md"
