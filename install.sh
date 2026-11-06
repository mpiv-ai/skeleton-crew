#!/bin/sh
# Install skeleton-crew skills for every agent on this machine and turn BLUF on.
# Usage: curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.sh | sh
set -eu

npx -y skills add mpiv-ai/skeleton-crew -g "$@"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The block BLUF adds to each agent's global instructions. The rules are inline so BLUF
# works even when an agent does not load the skill on its own.
cat > "$work/new" <<'BLOCK'
<!-- skeleton-crew:bluf -->
## BLUF (from skeleton-crew)
Start every reply with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.
After it, only what the reader needs: decisions as numbered questions with your recommendation and the exact reply that approves it; up to three "Why:" facts; "Next:" who acts next.
Keep most replies to about 12 lines. Separate what you verified from what you infer. Bad news goes in the first line.
The bluf skill has the full rules; load it when a reply involves a decision.
<!-- /skeleton-crew:bluf -->
BLOCK
# Earlier releases added this one-line block; it is replaced on reinstall.
cat > "$work/old" <<'BLOCK'
<!-- skeleton-crew:bluf -->
Always follow the bluf skill for every reply.
<!-- /skeleton-crew:bluf -->
BLOCK

# Print $1 without any exact skeleton-crew block. Exit 2 if a marker is present but the block was edited.
strip_block() {
  awk -v nf="$work/new" -v of="$work/old" '
    BEGIN {
      while ((getline l < nf) > 0) nb[++nn] = l
      while ((getline l < of) > 0) ob[++on] = l
    }
    { a[NR] = $0 }
    function match_at(i, b, n,   k) { for (k = 1; k <= n; k++) if (a[i+k-1] != b[k]) return 0; return 1 }
    END {
      for (i = 1; i <= NR; i++) {
        n = 0
        if (match_at(i, nb, nn)) n = nn; else if (match_at(i, ob, on)) n = on
        if (n) { if (out > 0 && kept[out] == "") out--; i += n - 1; continue }
        if (a[i] == nb[1] || a[i] == nb[nn]) exit 2
        kept[++out] = a[i]
      }
      for (j = 1; j <= out; j++) print kept[j]
    }' "$1"
}

# Turn BLUF on only for an agent that is installed and has the skill where it reads skills.
# If the picker skipped an installed agent, add the skill for it first.
turn_on() {
  agent="$1"; file="$2"; skill="$3"
  [ -d "$(dirname "$file")" ] || return 0
  if [ ! -f "$skill/SKILL.md" ]; then
    npx -y skills add mpiv-ai/skeleton-crew -g -a "$agent" --skill bluf -y >/dev/null
  fi
  if [ ! -f "$skill/SKILL.md" ]; then
    echo "Skipped $agent: the bluf skill is not where it reads skills ($skill)."
    return 0
  fi
  if [ -f "$file" ]; then
    tmp="$(mktemp "$(dirname "$file")/.skeleton-crew.XXXXXX")"
    if ! strip_block "$file" > "$tmp"; then
      rm -f "$tmp"
      echo "Left $file unchanged: its skeleton-crew lines were edited. Remove them by hand, then rerun."
      return 0
    fi
  else
    tmp="$(mktemp "$(dirname "$file")/.skeleton-crew.XXXXXX")"
  fi
  { [ -s "$tmp" ] && echo; cat "$work/new"; } >> "$tmp"
  mv "$tmp" "$file"
  echo "BLUF on in $file"
}

turn_on claude-code "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills/bluf"
turn_on codex "$HOME/.codex/AGENTS.md" "$HOME/.agents/skills/bluf"

echo "Done. To turn BLUF off, run uninstall.sh or delete the skeleton-crew lines in those files."
