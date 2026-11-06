# Turn BLUF off and remove skeleton-crew skills.
# Removes only the exact block the installer added; everything else in the file is left as it was.
$ErrorActionPreference = 'Stop'

# The block BLUF adds to each agent's global instructions. The rules are inline so BLUF
# works even when an agent does not load the skill on its own.
$NewBlock = @(
  '<!-- skeleton-crew:bluf -->'
  '## BLUF (from skeleton-crew)'
  'Start every answer with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.'
  'Bring decisions, not essays. Anything you need from the user (a decision, an approval, or information) goes under "Needs you:" as numbered questions; each gives your recommendation and what happens if they agree, and ends with Reply: `<exact words>`. Routine choices get one line; spending, sending, deleting, or anything irreversible gets the full brief.'
  'After that, at most three "Why:" facts and a "Next:" line. Keep most replies to about 12 lines.'
  'Separate what you verified from what you infer. Bad news goes in the first line.'
  '"BLUF:" marks the answer only; progress notes while you work are one plain line without it.'
  'The bluf skill has the full rules; load it when a reply involves a decision.'
  '<!-- /skeleton-crew:bluf -->'
)
$Block3 = @(
  '<!-- skeleton-crew:bluf -->'
  '## BLUF (from skeleton-crew)'
  'Start every answer with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.'
  'Bring decisions, not essays: each one is a numbered question with your recommendation, what happens if they agree, and the exact reply that approves it. Routine choices get one line; spending, sending, deleting, or anything irreversible gets the full brief.'
  'After that, at most three "Why:" facts and a "Next:" line. Keep most replies to about 12 lines.'
  'Separate what you verified from what you infer. Bad news goes in the first line.'
  '"BLUF:" marks the answer only; progress notes while you work are one plain line without it.'
  'The bluf skill has the full rules; load it when a reply involves a decision.'
  '<!-- /skeleton-crew:bluf -->'
)
# Blocks earlier releases added; reinstall replaces them and uninstall removes them.
$Block2 = @(
  '<!-- skeleton-crew:bluf -->'
  '## BLUF (from skeleton-crew)'
  'Start every reply with a line that begins "BLUF:" and gives the answer, outcome, or verdict in one sentence. No greeting, no preamble.'
  'After it, only what the reader needs: decisions as numbered questions with your recommendation and the exact reply that approves it; up to three "Why:" facts; "Next:" who acts next.'
  'Keep most replies to about 12 lines. Separate what you verified from what you infer. Bad news goes in the first line.'
  'The bluf skill has the full rules; load it when a reply involves a decision.'
  '<!-- /skeleton-crew:bluf -->'
)

$Block1 = @(
  '<!-- skeleton-crew:bluf -->'
  'Always follow the bluf skill for every reply.'
  '<!-- /skeleton-crew:bluf -->'
)
$Utf8 = New-Object System.Text.UTF8Encoding $false

function Test-BlockAt([string[]]$Lines, [int]$At, [string[]]$Block) {
  if ($At + $Block.Count -gt $Lines.Count) { return $false }
  for ($k = 0; $k -lt $Block.Count; $k++) { if ($Lines[$At + $k] -cne $Block[$k]) { return $false } }
  return $true
}

# Returns the file's lines without any exact skeleton-crew block, or $null if a marker is present but the block was edited.
function Remove-Block([string]$File) {
  $lines = @()
  if (Test-Path -LiteralPath $File) { $lines = @([System.IO.File]::ReadAllLines($File)) }
  $kept = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $n = 0
    foreach ($kb in @($NewBlock, $Block3, $Block2, $Block1)) { if ($n -eq 0 -and (Test-BlockAt $lines $i $kb)) { $n = $kb.Count } }
    if ($n -gt 0) {
      if ($kept.Count -gt 0 -and $kept[$kept.Count - 1] -eq '') { $kept.RemoveAt($kept.Count - 1) }
      $i += $n - 1; continue
    }
    if ($lines[$i] -ceq $NewBlock[0] -or $lines[$i] -ceq $NewBlock[$NewBlock.Count - 1]) { return $null }
    $kept.Add($lines[$i])
  }
  return ,$kept
}

function Write-Lines([string]$File, $Lines) {
  $text = ''
  if ($Lines.Count -gt 0) { $text = ($Lines -join "`n") + "`n" }
  $tmp = [System.IO.Path]::Combine(([System.IO.Path]::GetDirectoryName($File)), '.skeleton-crew.' + [guid]::NewGuid().ToString('N'))
  [System.IO.File]::WriteAllText($tmp, $text, $Utf8)
  Move-Item -LiteralPath $tmp -Destination $File -Force
}

function Disable-Bluf([string]$File) {
  if (-not (Test-Path -LiteralPath $File)) { return }
  if (-not ([System.IO.File]::ReadAllLines($File) -ccontains $NewBlock[0])) { return }
  $kept = Remove-Block $File
  if ($null -eq $kept) {
    Write-Host "Left $File unchanged: its skeleton-crew lines were edited. Remove them by hand."; return
  }
  Write-Lines $File $kept
  Write-Host "BLUF off in $File"
}

Disable-Bluf ([System.IO.Path]::Combine($HOME, '.claude', 'CLAUDE.md'))
Disable-Bluf ([System.IO.Path]::Combine($HOME, '.codex', 'AGENTS.md'))

npx -y skills remove bluf -g -y
