# Install skeleton-crew skills for every agent on this machine and turn BLUF on.
# Usage (PowerShell): irm https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

npx -y skills add mpiv-ai/skeleton-crew -g @args
if ($LASTEXITCODE -ne 0) { throw "skills install failed" }

$Start = '<!-- skeleton-crew:bluf -->'
$End = '<!-- /skeleton-crew:bluf -->'
$Line = 'Always follow the bluf skill for every reply.'

# Turn BLUF on only for an agent that is installed and has the skill where it reads skills.
# If the picker skipped an installed agent, add the skill for it first.
function Enable-Bluf([string]$Agent, [string]$File, [string]$Skill) {
  if (-not (Test-Path -LiteralPath (Split-Path $File -Parent))) { return }
  $skillFile = Join-Path $Skill 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillFile)) {
    npx -y skills add mpiv-ai/skeleton-crew -g -a $Agent --skill bluf -y | Out-Null
  }
  if (-not (Test-Path -LiteralPath $skillFile)) {
    Write-Host "Skipped ${Agent}: the bluf skill is not where it reads skills ($Skill)."; return
  }
  if ((Test-Path -LiteralPath $File) -and (Select-String -LiteralPath $File -SimpleMatch $Start -Quiet)) {
    Write-Host "BLUF already on in $File"; return
  }
  Add-Content -Path $File -Value "`n$Start`n$Line`n$End" -Encoding utf8
  Write-Host "BLUF on in $File"
}

Enable-Bluf 'claude-code' (Join-Path $HOME '.claude\CLAUDE.md') (Join-Path $HOME '.claude\skills\bluf')
Enable-Bluf 'codex' (Join-Path $HOME '.codex\AGENTS.md') (Join-Path $HOME '.agents\skills\bluf')

Write-Host 'Done. To turn BLUF off, run uninstall.ps1 or delete the skeleton-crew lines in those files.'
