# Turn BLUF off and remove skeleton-crew skills.
$ErrorActionPreference = 'Stop'

function Disable-Bluf([string]$File) {
  if (-not (Test-Path $File)) { return }
  $text = Get-Content -Path $File -Raw
  if ($text -notmatch [regex]::Escape('<!-- skeleton-crew:bluf -->')) { return }
  $pattern = '\r?\n*<!-- skeleton-crew:bluf -->[\s\S]*?<!-- /skeleton-crew:bluf -->\r?\n?'
  $text = [regex]::Replace($text, $pattern, "`n")
  $text = $text.TrimEnd("`r", "`n")
  if ($text.Length -eq 0) { Remove-Item $File } else { Set-Content -Path $File -Value $text -Encoding utf8 }
  Write-Host "BLUF off in $File"
}

Disable-Bluf (Join-Path $HOME '.claude\CLAUDE.md')
Disable-Bluf (Join-Path $HOME '.codex\AGENTS.md')

npx -y skills remove bluf -g -y
