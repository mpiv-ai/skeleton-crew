# Show, for each agent on this machine, whether each skeleton-crew skill's rules are on.
# Usage (PowerShell): irm https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/check.ps1 | iex
$ErrorActionPreference = 'Stop'

$Source = 'https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main'
if ($env:SKELETON_CREW_SOURCE) { $Source = $env:SKELETON_CREW_SOURCE }
$ProgressPreference = 'SilentlyContinue'

function Get-SourceText([string]$Path) {
  try {
    if ($Source -match '^https?://') {
      $c = (Invoke-WebRequest -UseBasicParsing -Uri "$Source/$Path").Content
      if ($c -is [byte[]]) { $c = [System.Text.Encoding]::UTF8.GetString($c) }
      return [string]$c
    }
    return [System.IO.File]::ReadAllText([System.IO.Path]::Combine($Source, $Path))
  } catch { throw "Could not fetch $Path from $Source." }
}

function Split-Lines([string]$Text) {
  if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
  if ($Text.Length -eq 0) { return ,@() }
  $parts = $Text -split "`n"
  if ($Text.EndsWith("`n")) { $parts = $parts[0..($parts.Count - 2)] }
  return ,@($parts | ForEach-Object { $_.TrimEnd("`r") })
}

$Blocks = [ordered]@{}
foreach ($n in (Split-Lines (Get-SourceText 'blocks.txt'))) {
  $n = $n.Trim()
  if ($n -cnotmatch '^[a-z0-9-]+$') { continue }
  $Blocks[$n] = Split-Lines (Get-SourceText "skills/$n/block.md")
}

# 'current' if $Lines hold $Block exactly, 'older' if they hold its first marker only, 'none' otherwise.
function Get-Rules([string[]]$Lines, [string[]]$Block) {
  $rules = 'none'
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -cne $Block[0]) { continue }
    $rules = 'older'
    if ($i + $Block.Count -gt $Lines.Count) { continue }
    $k = 0; while ($k -lt $Block.Count -and $Lines[$i + $k] -ceq $Block[$k]) { $k++ }
    if ($k -eq $Block.Count) { return 'current' }
  }
  return $rules
}

function Show-Blocks([string]$Agent, [string]$AgentHome, [string]$File, [string]$Skills) {
  if (-not (Test-Path -LiteralPath $AgentHome)) { Write-Host ('{0,-12} {1,-9} not installed' -f $Agent, ''); return }
  $lines = @()
  if ($File -and (Test-Path -LiteralPath $File)) { $lines = Split-Lines ([System.IO.File]::ReadAllText($File)) }
  foreach ($n in $Blocks.Keys) {
    $hasSkill = Test-Path -LiteralPath ([System.IO.Path]::Combine($Skills, $n, 'SKILL.md'))
    $rules = Get-Rules $lines $Blocks[$n]
    if (-not $hasSkill) { $state = 'OFF  - skill missing; rerun the installer' }
    elseif ($rules -eq 'current') { $state = 'ON' }
    elseif ($rules -eq 'older') { $state = 'ON   - older rules; rerun the installer to update' }
    elseif (-not $File) { $state = 'ON   - skill only (this agent applies skills on its own)' }
    else { $state = 'PART - skill installed, rules missing; rerun the installer' }
    Write-Host ('{0,-12} {1,-9} {2}' -f $Agent, $n, $state)
  }
}

$H = $HOME
Show-Blocks 'Claude Code' ([System.IO.Path]::Combine($H, '.claude')) ([System.IO.Path]::Combine($H, '.claude', 'CLAUDE.md')) ([System.IO.Path]::Combine($H, '.claude', 'skills'))
Show-Blocks 'Codex' ([System.IO.Path]::Combine($H, '.codex')) ([System.IO.Path]::Combine($H, '.codex', 'AGENTS.md')) ([System.IO.Path]::Combine($H, '.agents', 'skills'))
Show-Blocks 'Pi' ([System.IO.Path]::Combine($H, '.pi')) '' ([System.IO.Path]::Combine($H, '.agents', 'skills'))
