#!/bin/sh
# Show, for each agent on this machine, whether each skeleton-crew skill's rules are on.
# Usage: curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/check.sh | sh
set -eu

src="${SKELETON_CREW_SOURCE:-https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fetch() { # <path in repo> <output file>
  case "$src" in
    http://*|https://*) curl -fsSL "$src/$1" -o "$2" 2>/dev/null ;;
    *) cp "$src/$1" "$2" 2>/dev/null ;;
  esac
}

fetch blocks.txt "$work/list" || { echo "Could not fetch blocks.txt from $src."; exit 1; }
names=""
for name in $(grep -v '^#' "$work/list" | tr -d '\r'); do
  case "$name" in *[!a-z0-9-]*) continue ;; esac
  fetch "skills/$name/block.md" "$work/$name.new" || { echo "Could not fetch the $name block from $src."; exit 1; }
  names="$names $name"
done

# Exit 0 if file $1 holds block $2 exactly, 1 if it holds that skill's marker only, 3 if neither.
has_block() {
  LC_ALL=C awk -v bf="$2" '
    BEGIN { while ((getline l < bf) > 0) { sub(/\r$/, "", l); b[++n] = l } }
    { sub(/\r$/, ""); if (NR == 1 && substr($0, 1, 3) == "\357\273\277") $0 = substr($0, 4); a[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (a[i] != b[1]) continue
        seen = 1
        for (k = 1; k <= n && a[i+k-1] == b[k]; k++) ;
        if (k > n) exit 0
      }
      exit seen ? 1 : 3
    }' "$1"
}

report() {
  agent="$1"; home="$2"; file="$3"; skills="$4"
  if [ ! -d "$home" ]; then printf '%-12s %-9s not installed\n' "$agent" ""; return; fi
  for name in $names; do
    rules=none
    if [ -n "$file" ] && [ -f "$file" ]; then
      rc=0; has_block "$file" "$work/$name.new" || rc=$?
      case "$rc" in 0) rules=current ;; 1) rules=older ;; esac
    fi
    if [ ! -f "$skills/$name/SKILL.md" ]; then state="OFF  - skill missing; rerun the installer"
    elif [ "$rules" = current ]; then state="ON"
    elif [ "$rules" = older ]; then state="ON   - older rules; rerun the installer to update"
    elif [ -z "$file" ]; then state="ON   - skill only (this agent applies skills on its own)"
    else state="PART - skill installed, rules missing; rerun the installer"
    fi
    printf '%-12s %-9s %s\n' "$agent" "$name" "$state"
  done
}

report "Claude Code" "$HOME/.claude" "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills"
report "Codex" "$HOME/.codex" "$HOME/.codex/AGENTS.md" "$HOME/.agents/skills"
report "Pi" "$HOME/.pi" "" "$HOME/.agents/skills"
