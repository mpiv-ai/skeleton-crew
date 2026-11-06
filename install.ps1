# Install skeleton-crew skills for every agent on this machine and turn BLUF on.
# Usage (PowerShell): irm https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

npx -y skills add mpiv-ai/skeleton-crew -g @args
if ($LASTEXITCODE -ne 0) { throw "skills install failed" }

$Start = '<!-- skeleton-crew:bluf -->'
$End = '<!-- /skeleton-crew:bluf -->'
$Line = 'Always follow the bluf skill for every reply.'

function Enable-Bluf([string]$File) {
  if (-not (Test-Path (Split-Path $File -Parent))) { return }
  if ((Test-Path $File) -and (Select-String -Path $File -SimpleMatch $Start -Quiet)) {
    Write-Host "BLUF already on in $File"; return
  }
  Add-Content -Path $File -Value "`n$Start`n$Line`n$End" -Encoding utf8
  Write-Host "BLUF on in $File"
}

Enable-Bluf (Join-Path $HOME '.claude\CLAUDE.md')
Enable-Bluf (Join-Path $HOME '.codex\AGENTS.md')

Write-Host 'Done. To turn BLUF off, run uninstall.ps1 or delete the skeleton-crew lines in those files.'
