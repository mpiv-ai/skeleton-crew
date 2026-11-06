# Show whether BLUF is on for each agent on this machine.
# Usage (PowerShell): irm https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/check.ps1 | iex
$ErrorActionPreference = 'Stop'

$Current = '"BLUF:" marks the answer only; progress notes while you work are one plain line without it.'

function Show-Bluf([string]$Name, [string]$AgentHome, [string]$File, [string]$Skill) {
  if (-not (Test-Path -LiteralPath $AgentHome)) { Write-Host ('{0,-12} not installed' -f $Name); return }
  $hasSkill = Test-Path -LiteralPath ([System.IO.Path]::Combine($Skill, 'SKILL.md'))
  $rules = 'none'
  if ($File -and (Test-Path -LiteralPath $File)) {
    $lines = [System.IO.File]::ReadAllLines($File)
    if ($lines -ccontains '<!-- skeleton-crew:bluf -->') { if ($lines -ccontains $Current) { $rules = 'current' } else { $rules = 'older' } }
  }
  if (-not $hasSkill) { $state = 'OFF  - skill missing; rerun the installer' }
  elseif ($rules -eq 'current') { $state = 'ON' }
  elseif ($rules -eq 'older') { $state = 'ON   - older rules; rerun the installer to update' }
  elseif (-not $File) { $state = 'ON   - skill only (this agent applies skills on its own)' }
  else { $state = 'PART - skill installed, rules missing; rerun the installer' }
  Write-Host ('{0,-12} {1}' -f $Name, $state)
}

$H = $HOME
Show-Bluf 'Claude Code' ([System.IO.Path]::Combine($H, '.claude')) ([System.IO.Path]::Combine($H, '.claude', 'CLAUDE.md')) ([System.IO.Path]::Combine($H, '.claude', 'skills', 'bluf'))
Show-Bluf 'Codex' ([System.IO.Path]::Combine($H, '.codex')) ([System.IO.Path]::Combine($H, '.codex', 'AGENTS.md')) ([System.IO.Path]::Combine($H, '.agents', 'skills', 'bluf'))
Show-Bluf 'Pi' ([System.IO.Path]::Combine($H, '.pi')) '' ([System.IO.Path]::Combine($H, '.agents', 'skills', 'bluf'))
