#!/bin/sh
# Show whether BLUF is on for each agent on this machine.
# Usage: curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/check.sh | sh
set -eu

CURRENT='"BLUF:" marks the answer only; progress notes while you work are one plain line without it.'

report() {
  name="$1"; home="$2"; file="$3"; skill="$4"
  if [ ! -d "$home" ]; then printf '%-12s not installed\n' "$name"; return; fi
  has_skill=no; [ -f "$skill/SKILL.md" ] && has_skill=yes
  rules=none
  if [ -n "$file" ] && [ -f "$file" ] && grep -qxF '<!-- skeleton-crew:bluf -->' "$file"; then
    if grep -qxF "$CURRENT" "$file"; then rules=current; else rules=older; fi
  fi
  if [ "$has_skill" = no ]; then state="OFF  - skill missing; rerun the installer"
  elif [ "$rules" = current ]; then state="ON"
  elif [ "$rules" = older ]; then state="ON   - older rules; rerun the installer to update"
  elif [ -z "$file" ]; then state="ON   - skill only (this agent applies skills on its own)"
  else state="PART - skill installed, rules missing; rerun the installer"
  fi
  printf '%-12s %s\n' "$name" "$state"
}

report "Claude Code" "$HOME/.claude" "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills/bluf"
report "Codex" "$HOME/.codex" "$HOME/.codex/AGENTS.md" "$HOME/.agents/skills/bluf"
report "Pi" "$HOME/.pi" "" "$HOME/.agents/skills/bluf"
