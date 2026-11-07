# Turn skeleton-crew's rules off and remove its skills.
# Removes only the exact blocks the installer added; everything else in the file is left as it was.
$ErrorActionPreference = 'Stop'

# --- shared with uninstall.ps1: keep identical ---
# Each skill in blocks.txt keeps the block it adds to an agent's global instructions in
# skills/<name>/block.md, and every block an earlier release added in skills/<name>/block.previous.md.
# The rules are inline so they work even when an agent does not load the skill on its own.
$Source = 'https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main'
if ($env:SKELETON_CREW_SOURCE) { $Source = $env:SKELETON_CREW_SOURCE }
$ProgressPreference = 'SilentlyContinue'
$Utf8 = New-Object System.Text.UTF8Encoding $false

function Get-SourceText([string]$Path, [switch]$Optional) {
  try {
    if ($Source -match '^https?://') {
      $c = (Invoke-WebRequest -UseBasicParsing -Uri "$Source/$Path").Content
      if ($c -is [byte[]]) { $c = $Utf8.GetString($c) }
      return [string]$c
    }
    return [System.IO.File]::ReadAllText([System.IO.Path]::Combine($Source, $Path))
  } catch {
    if ($Optional) { return '' }
    throw "Could not fetch $Path from $Source. Nothing changed."
  }
}

# Lines without line endings or a byte order mark.
function Split-Lines([string]$Text) {
  if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
  if ($Text.Length -eq 0) { return ,@() }
  $parts = $Text -split "`n"
  if ($Text.EndsWith("`n")) { $parts = $parts[0..($parts.Count - 2)] }
  return ,@($parts | ForEach-Object { $_.TrimEnd("`r") })
}

# Each skeleton-crew block in $Lines, as an array of lines.
function Get-Blocks([string[]]$Lines) {
  $blocks = New-Object System.Collections.Generic.List[object]
  $cur = $null; $end = $null
  foreach ($l in $Lines) {
    if ($null -eq $cur -and $l -cmatch '^<!-- skeleton-crew:([a-z0-9-]+) -->$') {
      $cur = New-Object System.Collections.Generic.List[string]; $end = "<!-- /skeleton-crew:$($Matches[1]) -->"
    }
    if ($null -ne $cur) {
      $cur.Add($l)
      if ($l -ceq $end) { $blocks.Add([string[]]$cur.ToArray()); $cur = $null }
    }
  }
  return ,$blocks
}

$Names = New-Object System.Collections.Generic.List[string]
$Current = New-Object 'System.Collections.Generic.Dictionary[string,object]'
$Known = New-Object System.Collections.Generic.List[object]
$Markers = New-Object 'System.Collections.Generic.Dictionary[string,string]'
foreach ($n in (Split-Lines (Get-SourceText 'blocks.txt'))) {
  $n = $n.Trim()
  if ($n -cnotmatch '^[a-z0-9-]+$') { continue }
  $cur = Get-Blocks (Split-Lines (Get-SourceText "skills/$n/block.md"))
  if ($cur.Count -ne 1 -or $cur[0][0] -cne "<!-- skeleton-crew:$n -->") { throw "Could not fetch the $n block from $Source. Nothing changed." }
  $Names.Add($n); $Current[$n] = $cur[0]; $Known.Add($cur[0])
  foreach ($b in (Get-Blocks (Split-Lines (Get-SourceText "skills/$n/block.previous.md" -Optional)))) { $Known.Add($b) }
  $Markers["<!-- skeleton-crew:$n -->"] = $n; $Markers["<!-- /skeleton-crew:$n -->"] = $n
}

function Test-BlockAt([string[]]$Lines, [int]$At, [string[]]$Block) {
  if ($At + $Block.Count -gt $Lines.Count) { return $false }
  for ($k = 0; $k -lt $Block.Count; $k++) { if ($Lines[$At + $k] -cne $Block[$k]) { return $false } }
  return $true
}

# Rewrite $File with every exact known block removed and $Add (lines, may be empty) added at the end,
# keeping its byte order mark and line endings. Writes through a temp file. Returns
# 'written', 'unchanged', 'noblock' (nothing to remove, file untouched) or 'edited:<skill>'.
function Update-Blocks([string]$File, [string[]]$Add) {
  $bytes = New-Object byte[] 0
  if (Test-Path -LiteralPath $File) { $bytes = [System.IO.File]::ReadAllBytes($File) }
  $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
  $skip = 0; if ($bom) { $skip = 3 }
  $text = $Utf8.GetString($bytes, $skip, $bytes.Length - $skip)
  $nl = "`n"; $i = $text.IndexOf("`n"); if ($i -gt 0 -and $text[$i - 1] -eq "`r") { $nl = "`r`n" }
  $lines = Split-Lines $text
  $kept = New-Object System.Collections.Generic.List[string]
  $removed = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $n = 0
    foreach ($kb in $Known) { if ($n -eq 0 -and (Test-BlockAt $lines $i $kb)) { $n = $kb.Count } }
    if ($n -gt 0) {
      if ($kept.Count -gt 0 -and $kept[$kept.Count - 1] -eq '') { $kept.RemoveAt($kept.Count - 1) }
      $i += $n - 1; $removed = $true; continue
    }
    if ($Markers.ContainsKey($lines[$i])) { return "edited:$($Markers[$lines[$i]])" }
    $kept.Add($lines[$i])
  }
  if ($Add.Count -eq 0 -and -not $removed) { return 'noblock' }
  if ($Add.Count -gt 0 -and $kept.Count -gt 0) { $kept.Add('') }
  foreach ($l in $Add) { $kept.Add($l) }
  $out = ''; if ($kept.Count -gt 0) { $out = ($kept -join $nl) + $nl }
  $new = $Utf8.GetBytes($out)
  if ($bom) { $new = [byte[]]((0xEF, 0xBB, 0xBF) + $new) }
  if ((Test-Path -LiteralPath $File) -and [Convert]::ToBase64String($new) -ceq [Convert]::ToBase64String($bytes)) { return 'unchanged' }
  $item = $null; if (Test-Path -LiteralPath $File) { $item = Get-Item -LiteralPath $File -Force }
  if ($item -and $item.LinkType) { [System.IO.File]::WriteAllBytes($File, $new); return 'written' }
  $tmp = [System.IO.Path]::Combine(([System.IO.Path]::GetDirectoryName($File)), '.skeleton-crew.' + [guid]::NewGuid().ToString('N'))
  [System.IO.File]::WriteAllBytes($tmp, $new)
  Move-Item -LiteralPath $tmp -Destination $File -Force
  return 'written'
}
# --- end shared ---

function Disable-Blocks([string]$File) {
  if (-not (Test-Path -LiteralPath $File)) { return }
  $result = Update-Blocks $File @()
  if ($result -like 'edited:*') {
    Write-Host "Left $File unchanged: its skeleton-crew $($result.Substring(7)) lines were edited. Remove them by hand."; return
  }
  if ($result -eq 'written') { Write-Host "Off in $File" }
}

Disable-Blocks ([System.IO.Path]::Combine($HOME, '.claude', 'CLAUDE.md'))
Disable-Blocks ([System.IO.Path]::Combine($HOME, '.codex', 'AGENTS.md'))

$skillNames = $Names.ToArray()
npx -y skills remove @skillNames -g -y
