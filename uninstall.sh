#!/bin/sh
# Turn BLUF off and remove skeleton-crew skills.
# Removes only the exact three-line block install.sh added; everything else in the file is left as it was.
set -eu

START='<!-- skeleton-crew:bluf -->'
LINE='Always follow the bluf skill for every reply.'
END='<!-- /skeleton-crew:bluf -->'

turn_off() {
  file="$1"
  [ -f "$file" ] || return 0
  grep -qxF "$START" "$file" || return 0
  tmp="$(mktemp "$(dirname "$file")/.skeleton-crew.XXXXXX")"
  if ! awk -v s="$START" -v l="$LINE" -v e="$END" '
    { a[NR] = $0 }
    END {
      removed = 0
      for (i = 1; i <= NR; i++) {
        if (a[i] == s && a[i+1] == l && a[i+2] == e) {
          if (out > 0 && kept[out] == "") out--   # drop the blank line install.sh added before the block
          i += 2; removed++; continue
        }
        if (a[i] == s || a[i] == e) { exit 2 }     # a marker without the exact block: leave the file alone
        kept[++out] = a[i]
      }
      if (removed == 0) exit 2
      for (j = 1; j <= out; j++) print kept[j]
    }' "$file" > "$tmp"; then
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
