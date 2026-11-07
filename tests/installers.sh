#!/usr/bin/env bash
# Run install, uninstall and check against throwaway home folders, for sh and PowerShell.
# Usage: tests/installers.sh [sh] [mawk] [busybox] [pwsh]   (default: every runner found)
# Set PWSH to a PowerShell 7 binary if pwsh is not on PATH. Nothing outside a temp folder is touched.
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
root="$(mktemp -d)"; trap 'rm -rf "$root"' EXIT
PWSH="${PWSH:-$(command -v pwsh || true)}"

runners="$*"
if [ -z "$runners" ]; then
  runners="sh"
  command -v mawk >/dev/null && runners="$runners mawk"
  command -v busybox >/dev/null && runners="$runners busybox"
  [ -n "$PWSH" ] && runners="$runners pwsh"
fi

# npx does nothing, so the skill folders are whatever each case sets up.
mkdir -p "$root/bin" "$root/mawk" "$root/busybox"
printf '#!/bin/sh\nexit 0\n' > "$root/bin/npx"; chmod +x "$root/bin/npx"
command -v mawk >/dev/null && ln -s "$(command -v mawk)" "$root/mawk/awk"
command -v busybox >/dev/null && printf '#!/bin/sh\nexec busybox awk "$@"\n' > "$root/busybox/awk" && chmod +x "$root/busybox/awk"

bluf="$(cat "$repo/skills/bluf/block.md")"
receipts="$(cat "$repo/skills/receipts/block.md")"
full="$bluf"$'\n\n'"$receipts"$'\n'
user=$'My own rule.\n'
bom=$'\xef\xbb\xbf'

pass=0; fail=0; failed=""
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); failed="$failed\n  $R: $1"; printf '  FAIL  %s\n' "$1"; }
same() { if cmp -s "$1" "$2"; then ok "$3"; else bad "$3"; diff <(od -c "$1") <(od -c "$2") | head -8; fi; }
has()  { if grep -qF -- "$2" "$1"; then ok "$3"; else bad "$3"; sed 's/^/        /' "$1"; fi; }
put()  { printf '%s' "$2" > "$1"; }

home() { # fresh home with both agents and both skills
  H="$(mktemp -d "$root/home.XXXX")"
  mkdir -p "$H/.claude/skills/bluf" "$H/.claude/skills/receipts" "$H/.codex" "$H/.agents/skills/bluf" "$H/.agents/skills/receipts"
  touch "$H/.claude/skills/bluf/SKILL.md" "$H/.claude/skills/receipts/SKILL.md" "$H/.agents/skills/bluf/SKILL.md" "$H/.agents/skills/receipts/SKILL.md"
  C="$H/.claude/CLAUDE.md"; A="$H/.codex/AGENTS.md"; E="$root/expect"; L="$root/log"
}

run() { # <runner> <install|uninstall|check>
  local p="$root/bin:$PATH"
  case "$1" in
    mawk) p="$root/mawk:$p" ;;
    busybox) p="$root/busybox:$p" ;;
  esac
  case "$1" in
    pwsh) HOME="$H" PATH="$p" SKELETON_CREW_SOURCE="$repo" "$PWSH" -NoProfile -NonInteractive -File "$repo/$2.ps1" ;;
    *) HOME="$H" PATH="$p" SKELETON_CREW_SOURCE="$repo" sh "$repo/$2.sh" ;;
  esac > "$L" 2>&1
}

first_windows_file() { # the file the first Windows installer (Add-Content in PowerShell 5.1) left: BOM, LF inside, CRLF at the end
  printf '\357\273\277\n<!-- skeleton-crew:bluf -->\nAlways follow the bluf skill for every reply.\n<!-- /skeleton-crew:bluf -->\r\n' > "$1"
}

# The three earlier BLUF blocks, one file each.
mkdir -p "$root/prev"
awk -v d="$root/prev" '/^<!-- skeleton-crew:bluf -->$/ { n++ } n { print > (d "/" n) }' "$repo/skills/bluf/block.previous.md"

for R in $runners; do
  echo "== $R"

  home; run "$R" install
  put "$E" "$full"; same "$C" "$E" "fresh install: CLAUDE.md has both blocks"; same "$A" "$E" "fresh install: AGENTS.md has both blocks"
  cp "$C" "$root/first"; run "$R" install; same "$C" "$root/first" "rerun changes nothing"
  run "$R" uninstall; put "$E" ""; same "$C" "$E" "uninstall after fresh install leaves an empty file"

  home; put "$C" "$user"; cp "$C" "$root/orig"; run "$R" install
  put "$E" "$user"$'\n'"$full"; same "$C" "$E" "existing file: blocks added after a blank line"
  run "$R" install; same "$C" "$E" "existing file: rerun changes nothing"
  run "$R" uninstall; same "$C" "$root/orig" "existing file: uninstall is byte-identical"

  home; printf '\357\273\277My own rule.\r\nSecond line.\r\n' > "$C"; cp "$C" "$root/orig"; run "$R" install
  { printf '\357\273\277My own rule.\r\nSecond line.\r\n\r\n'; printf '%s' "$full" | sed 's/$/\r/'; } > "$E"
  same "$C" "$E" "BOM+CRLF file: blocks added with CRLF, BOM kept"
  run "$R" uninstall; same "$C" "$root/orig" "BOM+CRLF file: uninstall is byte-identical"

  for f in current "$root"/prev/*; do
    case "$f" in current) label="today's bluf-only block"; blk="$bluf"$'\n' ;; *) label="earlier bluf block $(basename "$f")"; blk="$(cat "$f")"$'\n' ;; esac
    home; put "$C" "$user"$'\n'"$blk"; run "$R" install
    put "$E" "$user"$'\n'"$full"; same "$C" "$E" "upgrade from $label"
    run "$R" uninstall; put "$E" "$user"; same "$C" "$E" "uninstall after upgrade from $label is byte-identical to the original"
  done

  home; first_windows_file "$C"; run "$R" install
  { printf '\357\273\277'; printf '%s' "$full"; } > "$E"; same "$C" "$E" "upgrade from the first Windows installer's BOM+CRLF file"
  run "$R" uninstall; put "$E" "$bom"; same "$C" "$E" "uninstall after that upgrade leaves only the BOM"

  home; put "$C" "$user"$'\n'"${bluf/Bad news goes in the first line./Bad news last.}"$'\n\n'"$receipts"$'\n'; cp "$C" "$root/orig"
  run "$R" install; same "$C" "$root/orig" "edited bluf block: install leaves the file untouched"
  has "$L" "skeleton-crew bluf lines were edited" "edited bluf block: install says which block"
  run "$R" uninstall; same "$C" "$root/orig" "edited bluf block: uninstall leaves the file untouched"

  home; put "$C" "$user"$'\n'"$bluf"$'\n\nmy notes\n<!-- /skeleton-crew:receipts -->\n'; cp "$C" "$root/orig"
  run "$R" install; same "$C" "$root/orig" "edited receipts block: install leaves the file untouched"
  has "$L" "skeleton-crew receipts lines were edited" "edited receipts block: install says which block"

  home; rm -rf "$H/.agents/skills/receipts"; run "$R" install
  put "$E" "$bluf"$'\n'; same "$A" "$E" "receipts skill missing for Codex: AGENTS.md gets bluf only"
  same "$C" <(printf '%s' "$full") "receipts skill missing for Codex: CLAUDE.md still gets both"
  has "$L" "Skipped receipts for codex" "receipts skill missing: install says so"

  home; printf 'no newline at end' > "$C"; cp "$C" "$root/orig"; run "$R" uninstall
  same "$C" "$root/orig" "uninstall leaves a file with no blocks untouched"

  home; mkdir -p "$H/dotfiles"; put "$H/dotfiles/CLAUDE.md" "$user"; ln -s ../dotfiles/CLAUDE.md "$C"; run "$R" install
  if [ -L "$C" ]; then ok "symlinked CLAUDE.md stays a symlink"; else bad "symlinked CLAUDE.md stays a symlink"; fi
  put "$E" "$user"$'\n'"$full"; same "$H/dotfiles/CLAUDE.md" "$E" "symlinked CLAUDE.md: blocks written to its target"
  run "$R" uninstall; put "$E" "$user"; same "$H/dotfiles/CLAUDE.md" "$E" "symlinked CLAUDE.md: uninstall restores the target"

  home; run "$R" check
  [ "$(grep -c 'PART' "$L")" = 4 ] && ok "check before install: 4 PART lines" || { bad "check before install: 4 PART lines"; cat "$L"; }
  run "$R" install; run "$R" check
  [ "$(grep -cE '^(Claude Code|Codex) +(bluf|receipts) +ON$' "$L")" = 4 ] && ok "check after install: ON per agent per skill" || { bad "check after install: ON per agent per skill"; cat "$L"; }
  has "$L" "not installed" "check: Pi not installed gets one line"
  put "$C" "$user"$'\n'"$(cat "$root/prev/1")"$'\n'; rm -rf "$H/.agents/skills/receipts"; run "$R" check
  has "$L" "older rules" "check: an earlier bluf block reads older"
  grep -E '^Codex +receipts +OFF' "$L" >/dev/null && ok "check: missing skill reads OFF" || { bad "check: missing skill reads OFF"; cat "$L"; }
  [ "$R" = sh ] && { echo "   check output after install:"; home; run sh install; run sh check; sed 's/^/     /' "$L"; }
done

# Install with one shell and uninstall with the other.
if [ -n "$PWSH" ]; then
  echo "== cross"
  for pair in "sh pwsh" "pwsh sh"; do
    set -- $pair; R="$1>$2"
    home; put "$C" "$user"; run "$1" install; run "$2" uninstall; put "$E" "$user"; same "$C" "$E" "install with $1, uninstall with $2: byte-identical"
  done
fi

echo "== repo"; R=repo
for pair in "install.sh uninstall.sh" "install.ps1 uninstall.ps1"; do
  set -- $pair
  if diff <(sed -n '/^# --- shared with/,/^# --- end shared ---$/p' "$repo/$1" | tail -n +2) \
          <(sed -n '/^# --- shared with/,/^# --- end shared ---$/p' "$repo/$2" | tail -n +2) >/dev/null; then
    ok "$1 and $2 share identical block code"; else bad "$1 and $2 share identical block code"; fi
done
listed="$(grep -v '^#' "$repo/blocks.txt" | sort | tr '\n' ' ')"
found="$(cd "$repo/skills" && ls -d */block.md | cut -d/ -f1 | sort | tr '\n' ' ')"
[ "$listed" = "$found" ] && ok "blocks.txt lists every skills/<name>/block.md ($listed)" || bad "blocks.txt ($listed) differs from skills/*/block.md ($found)"

echo; echo "$pass passed, $fail failed"
[ "$fail" = 0 ] || { printf "Failed:$failed\n"; exit 1; }
