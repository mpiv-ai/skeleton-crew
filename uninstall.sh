#!/bin/sh
# Turn BLUF off and remove skeleton-crew skills.
# Removes only the exact block the installer added; everything else in the file is left as it was.
set -eu

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

turn_off() {
  file="$1"
  [ -f "$file" ] || return 0
  grep -qxF '<!-- skeleton-crew:bluf -->' "$file" || return 0
  tmp="$(mktemp "$(dirname "$file")/.skeleton-crew.XXXXXX")"
  if ! strip_block "$file" > "$tmp"; then
    rm -f "$tmp"
    echo "Left $file unchanged: its skeleton-crew lines were edited. Remove them by hand."
    return 0
  fi
  mv "$tmp" "$file"
  echo "BLUF off in $file"
}

turn_off "$HOME/.claude/CLAUDE.md"
turn_off "$HOME/.codex/AGENTS.md"

npx -y skills remove bluf -g -y
