# Turn BLUF off and remove skeleton-crew skills.
# Removes only the exact three-line block install.ps1 added; everything else in the file is left as it was.
$ErrorActionPreference = 'Stop'

$Start = '<!-- skeleton-crew:bluf -->'
$Line = 'Always follow the bluf skill for every reply.'
$End = '<!-- /skeleton-crew:bluf -->'

function Disable-Bluf([string]$File) {
  if (-not (Test-Path -LiteralPath $File)) { return }
  $lines = @(Get-Content -LiteralPath $File)
  if ($lines -notcontains $Start) { return }
  $kept = New-Object System.Collections.Generic.List[string]
  $removed = 0
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq $Start -and $i + 2 -lt $lines.Count -and $lines[$i + 1] -eq $Line -and $lines[$i + 2] -eq $End) {
      if ($kept.Count -gt 0 -and $kept[$kept.Count - 1] -eq '') { $kept.RemoveAt($kept.Count - 1) }
      $i += 2; $removed++; continue
    }
    if ($lines[$i] -eq $Start -or $lines[$i] -eq $End) {
      Write-Host "Left $File unchanged: its skeleton-crew lines were edited. Remove them by hand."; return
    }
    $kept.Add($lines[$i])
  }
  if ($removed -eq 0) { return }
  $tmp = Join-Path (Split-Path -LiteralPath $File -Parent) ('.skeleton-crew.' + [guid]::NewGuid().ToString('N'))
  Set-Content -LiteralPath $tmp -Value $kept -Encoding utf8
  Move-Item -LiteralPath $tmp -Destination $File -Force
  Write-Host "BLUF off in $File"
}

Disable-Bluf (Join-Path $HOME '.claude\CLAUDE.md')
Disable-Bluf (Join-Path $HOME '.codex\AGENTS.md')

npx -y skills remove bluf -g -y
