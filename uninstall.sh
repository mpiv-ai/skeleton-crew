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
Start every answer with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.
Bring decisions, not essays: each one is a numbered question with your recommendation, what happens if they agree, and the exact reply that approves it. Routine choices get one line; spending, sending, deleting, or anything irreversible gets the full brief.
After that, at most three "Why:" facts and a "Next:" line. Keep most replies to about 12 lines.
Separate what you verified from what you infer. Bad news goes in the first line.
"BLUF:" marks the answer only; progress notes while you work are one plain line without it.
The bluf skill has the full rules; load it when a reply involves a decision.
<!-- /skeleton-crew:bluf -->
BLOCK
# Every block any release has added, so reinstall and uninstall recognise them. Blocks are separated by %%.
cat > "$work/known" <<'BLOCK'
<!-- skeleton-crew:bluf -->
## BLUF (from skeleton-crew)
Start every answer with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.
Bring decisions, not essays: each one is a numbered question with your recommendation, what happens if they agree, and the exact reply that approves it. Routine choices get one line; spending, sending, deleting, or anything irreversible gets the full brief.
After that, at most three "Why:" facts and a "Next:" line. Keep most replies to about 12 lines.
Separate what you verified from what you infer. Bad news goes in the first line.
"BLUF:" marks the answer only; progress notes while you work are one plain line without it.
The bluf skill has the full rules; load it when a reply involves a decision.
<!-- /skeleton-crew:bluf -->
%%
<!-- skeleton-crew:bluf -->
## BLUF (from skeleton-crew)
Start every reply with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.
After it, only what the reader needs: decisions as numbered questions with your recommendation and the exact reply that approves it; up to three "Why:" facts; "Next:" who acts next.
Keep most replies to about 12 lines. Separate what you verified from what you infer. Bad news goes in the first line.
The bluf skill has the full rules; load it when a reply involves a decision.
<!-- /skeleton-crew:bluf -->
%%
<!-- skeleton-crew:bluf -->
Always follow the bluf skill for every reply.
<!-- /skeleton-crew:bluf -->
BLOCK

# Print $1 without any exact skeleton-crew block. Exit 2 if a marker is present but the block was edited.
strip_block() {
  awk -v kf="$work/known" '
    BEGIN {
      nk = 1
      while ((getline l < kf) > 0) { if (l == "%%") { nk++; continue }; kb[nk, ++kn[nk]] = l }
      first = kb[1, 1]; last = kb[1, kn[1]]
    }
    { a[NR] = $0 }
    function match_at(i, b,   k) { for (k = 1; k <= kn[b]; k++) if (a[i+k-1] != kb[b, k]) return 0; return 1 }
    END {
      for (i = 1; i <= NR; i++) {
        n = 0
        for (b = 1; b <= nk && !n; b++) if (match_at(i, b)) n = kn[b]
        if (n) { if (out > 0 && kept[out] == "") out--; i += n - 1; continue }
        if (a[i] == first || a[i] == last) exit 2
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
