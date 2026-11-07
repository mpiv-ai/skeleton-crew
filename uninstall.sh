#!/bin/sh
# Turn skeleton-crew's rules off and remove its skills.
# Removes only the exact blocks the installer added; everything else in the file is left as it was.
set -eu

# --- shared with uninstall.sh: keep identical ---
# Each skill in blocks.txt keeps the block it adds to an agent's global instructions in
# skills/<name>/block.md, and every block an earlier release added in skills/<name>/block.previous.md.
# The rules are inline so they work even when an agent does not load the skill on its own.
src="${SKELETON_CREW_SOURCE:-https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fetch() { # <path in repo> <output file>
  case "$src" in
    http://*|https://*) curl -fsSL "$src/$1" -o "$2" 2>/dev/null ;;
    *) cp "$src/$1" "$2" 2>/dev/null ;;
  esac
}

# Sets $names and writes $work/<name>.new (current block) and $work/known (every block ever added).
load_blocks() {
  fetch blocks.txt "$work/list" || { echo "Could not fetch blocks.txt from $src. Nothing changed."; exit 1; }
  names=""; : > "$work/known"
  for name in $(grep -v '^#' "$work/list" | tr -d '\r'); do
    case "$name" in *[!a-z0-9-]*) continue ;; esac
    fetch "skills/$name/block.md" "$work/$name.new" &&
      [ "$(head -n 1 "$work/$name.new" | tr -d '\r')" = "<!-- skeleton-crew:$name -->" ] &&
      [ "$(tail -n 1 "$work/$name.new" | tr -d '\r')" = "<!-- /skeleton-crew:$name -->" ] ||
      { echo "Could not fetch the $name block from $src. Nothing changed."; exit 1; }
    fetch "skills/$name/block.previous.md" "$work/$name.old" || : > "$work/$name.old"
    { cat "$work/$name.new"; echo; cat "$work/$name.old"; echo; } >> "$work/known"
    names="$names $name"
  done
}

# Print the file with every exact known block removed and the blocks in file `af` added at the end,
# keeping its byte order mark and line endings. Exit 2 (skill name on stderr) if a block was edited,
# 3 if the file had no known block.
rewrite_awk='
  BEGIN {
    while ((getline l < kf) > 0) {
      sub(/\r$/, "", l)
      if (!inb && l ~ /^<!-- skeleton-crew:[a-z0-9-]+ -->$/) {
        inb = 1; nk++; name = substr(l, 20, length(l) - 23)
        mark[l] = name; mark["<!-- /skeleton-crew:" name " -->"] = name
      }
      if (inb) { kb[nk, ++kn[nk]] = l; if (l == "<!-- /skeleton-crew:" name " -->") inb = 0 }
    }
    while (af != "" && (getline l < af) > 0) { sub(/\r$/, "", l); add[++na] = l }
  }
  {
    line = $0
    if (NR == 1) {
      if (substr(line, 1, 3) == "\357\273\277") { bom = "\357\273\277"; line = substr(line, 4) }
      if (line ~ /\r$/) nl = "\r\n"
    }
    sub(/\r$/, "", line); a[NR] = line
  }
  function match_at(i, b,   k) { for (k = 1; k <= kn[b]; k++) if (a[i+k-1] != kb[b, k]) return 0; return 1 }
  END {
    if (nl == "") nl = "\n"
    for (i = 1; i <= NR; i++) {
      n = 0
      for (b = 1; b <= nk && !n; b++) if (match_at(i, b)) n = kn[b]
      if (n) { if (out > 0 && kept[out] == "") out--; i += n - 1; removed = 1; continue }
      if (a[i] in mark) { printf "%s", mark[a[i]] > "/dev/stderr"; exit 2 }
      kept[++out] = a[i]
    }
    if (na && out) kept[++out] = ""
    for (j = 1; j <= na; j++) kept[++out] = add[j]
    printf "%s", bom
    for (j = 1; j <= out; j++) printf "%s%s", kept[j], nl
    exit removed ? 0 : 3
  }'

# rewrite <file> <blocks to add, or empty>. Writes through a temp file and sets $result to
# written, unchanged, noblock (nothing to remove, file untouched) or edited:<skill>.
rewrite() {
  file="$1"; input="$file"; [ -f "$file" ] || input=/dev/null
  tmp="$(mktemp "$(dirname "$file")/.skeleton-crew.XXXXXX")"
  if [ -f "$file" ]; then cp -p "$file" "$tmp"; else chmod "$(printf '%o' $((0666 & ~$(umask))))" "$tmp"; fi
  rc=0; LC_ALL=C awk -v kf="$work/known" -v af="$2" "$rewrite_awk" "$input" > "$tmp" 2> "$work/err" || rc=$?
  if [ "$rc" = 2 ]; then result="edited:$(cat "$work/err")"; rm -f "$tmp"; return 0; fi
  if [ "$rc" != 0 ] && [ "$rc" != 3 ]; then rm -f "$tmp"; echo "Could not read $file. Nothing changed."; exit 1; fi
  if [ -z "$2" ] && [ "$rc" = 3 ]; then result=noblock; rm -f "$tmp"; return 0; fi
  if [ -f "$file" ] && cmp -s "$tmp" "$file"; then result=unchanged; rm -f "$tmp"; return 0; fi
  if [ -L "$file" ]; then cat "$tmp" > "$file"; rm -f "$tmp"; else mv "$tmp" "$file"; fi
  result=written
}
# --- end shared ---

load_blocks

turn_off() {
  rewrite "$1" ""
  case "$result" in
    edited:*) echo "Left $1 unchanged: its skeleton-crew ${result#edited:} lines were edited. Remove them by hand." ;;
    written) echo "Off in $1" ;;
  esac
}

for f in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
  if [ -f "$f" ]; then turn_off "$f"; fi
done

# shellcheck disable=SC2086
npx -y skills remove $names -g -y
