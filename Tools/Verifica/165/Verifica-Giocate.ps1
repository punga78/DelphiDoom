<#
  Plays Keen32 on the real data (no window, a script, no random seed: the same run every time) from the world map
  to its endings and compares the pictures with the ones that were looked at one by one (issue #165):
    livello   Prove\fine-livello.script, -Level 6      a small level to its end, back to the world map
    gameover  Prove\game-over.script, -Control 0 -DefaultKeys, -Level 1
                                                       the lives end: Game Over, the high score entry, the table, the title
    finale    Prove\finale.script, -Level 15           King Boobus Tuber is gone: the finale (THE END) and the high scores
    mouse     Prove\mouse.script, -Control 4           the mouse moves Keen
    joystick  Prove\joystick.script, -Control 2        the first joystick moves Keen
  The golden file is Tests\Data\Keen\giocate.golden.txt (one SHA-256 for each picture); -Record writes it. The data
  of Keen Dreams are not in the repository: the folders are given.

    powershell -NoProfile -File Tools\Verifica\165\Verifica-Giocate.ps1 -Exe bin\Win32\Release\Keen\Keen32.exe `
      -DataFolders <folder>,<folder>,<folder> [-Record]
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string[]]$DataFolders,
  [switch]$Record
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$golden = Join-Path $root 'Tests\Data\Keen\giocate.golden.txt'
$runs = @(
  @{ Name = 'livello';  Script = 'fine-livello.script'; Control = -1; Level = 6;  Keys = $false },
  @{ Name = 'gameover'; Script = 'game-over.script';    Control = 0;  Level = 1;  Keys = $true },
  @{ Name = 'finale';   Script = 'finale.script';       Control = -1; Level = 15; Keys = $false },
  @{ Name = 'mouse';    Script = 'mouse.script';        Control = 4;  Level = 1;  Keys = $false },
  @{ Name = 'joystick'; Script = 'joystick.script';     Control = 2;  Level = 1;  Keys = $false }
)
$lines = @()
foreach ($run in $runs) {
  $out = Join-Path $env:TEMP ("keen_giocata_" + $run.Name)
  $arguments = @('-NoProfile', '-File', (Join-Path $PSScriptRoot 'Prova-Dispositivi.ps1'), '-Exe', $Exe,
    '-DataFolders', ($DataFolders -join ','), '-Script', (Join-Path $PSScriptRoot ('Prove\' + $run.Name.Replace('gameover', 'game-over').Replace('livello', 'fine-livello') + '.script')),
    '-Control', $run.Control, '-Level', $run.Level, '-Out', $out)
  if ($run.Keys) { $arguments += '-DefaultKeys' }
  $text = & powershell @arguments 2>&1 | Out-String
  foreach ($file in Get-ChildItem (Join-Path $out 'shots') -Filter *.png | Sort-Object Name) {
    $lines += ('{0} {1} {2}' -f $run.Name, $file.Name, (Get-FileHash $file.FullName -Algorithm SHA256).Hash)
  }
}
if ($Record) {
  [IO.File]::WriteAllText($golden, (($lines -join "`n") + "`n"))
  "recorded: $($lines.Count) pictures"
  exit 0
}
$expected = [IO.File]::ReadAllText($golden).Replace("`r`n", "`n").TrimEnd().Split("`n")
$failed = 0
for ($i = 0; $i -lt [Math]::Max($lines.Count, $expected.Count); $i++) {
  $a = if ($i -lt $lines.Count) { $lines[$i] } else { '(none)' }
  $b = if ($i -lt $expected.Count) { $expected[$i] } else { '(none)' }
  if ($a -ne $b) { "DIFFERENT: got $a, expected $b"; $failed++ }
}
if ($failed -gt 0) { exit 1 }
"OK: $($lines.Count) pictures are the same"
