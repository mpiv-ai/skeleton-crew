#!/bin/sh
# Turn BLUF off and remove skeleton-crew skills.
set -eu

turn_off() {
  file="$1"
  [ -f "$file" ] || return 0
  grep -qF '<!-- skeleton-crew:bluf -->' "$file" || return 0
  tmp="$(mktemp)"
  awk '
    /<!-- skeleton-crew:bluf -->/ { skip = 1; held = ""; next }
    /<!-- \/skeleton-crew:bluf -->/ { skip = 0; next }
    skip { next }
    /^$/ { held = held "\n"; next }
    { printf "%s", held; held = ""; print }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
  [ -s "$file" ] || rm -f "$file"
  echo "BLUF off in $file"
}

turn_off "$HOME/.claude/CLAUDE.md"
turn_off "$HOME/.codex/AGENTS.md"

npx -y skills remove bluf -g -y
