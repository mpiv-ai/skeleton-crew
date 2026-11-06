#!/bin/sh
# Install skeleton-crew skills for every agent on this machine and turn BLUF on.
# Usage: curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.sh | sh
set -eu

npx -y skills add mpiv-ai/skeleton-crew -g "$@"

START='<!-- skeleton-crew:bluf -->'
END='<!-- /skeleton-crew:bluf -->'
LINE='Always follow the bluf skill for every reply.'

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
  if [ -f "$file" ] && grep -qF "$START" "$file"; then
    echo "BLUF already on in $file"
    return 0
  fi
  printf '\n%s\n%s\n%s\n' "$START" "$LINE" "$END" >> "$file"
  echo "BLUF on in $file"
}

turn_on claude-code "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills/bluf"
turn_on codex "$HOME/.codex/AGENTS.md" "$HOME/.agents/skills/bluf"

echo "Done. To turn BLUF off, run uninstall.sh or delete the skeleton-crew lines in those files."
