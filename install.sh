#!/bin/sh
# Install skeleton-crew skills for every agent on this machine and turn BLUF on.
# Usage: curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.sh | sh
set -eu

npx -y skills add mpiv-ai/skeleton-crew -g "$@"

START='<!-- skeleton-crew:bluf -->'
END='<!-- /skeleton-crew:bluf -->'
LINE='Always follow the bluf skill for every reply.'

turn_on() {
  file="$1"
  [ -d "$(dirname "$file")" ] || return 0
  if [ -f "$file" ] && grep -qF "$START" "$file"; then
    echo "BLUF already on in $file"
    return 0
  fi
  printf '\n%s\n%s\n%s\n' "$START" "$LINE" "$END" >> "$file"
  echo "BLUF on in $file"
}

turn_on "$HOME/.claude/CLAUDE.md"
turn_on "$HOME/.codex/AGENTS.md"

echo "Done. To turn BLUF off, run uninstall.sh or delete the skeleton-crew lines in those files."
