# TEMPORARY HARNESS (issue #172, fetta 2i): runs <Game>_OLD.exe and <Game>_NEW.exe (harness_out\ovr, built with
# Compila-ScriptHost.ps1 -Variant L2: the harness has the mode "-vsh overlay") on a level and compares
# verify_scripthost_overlay.txt: the FNV-1a of the 320x200 buffer of the overlay after every step (text, patches,
# stretched patches, pixels, rectangles, lines, drawers that expire), of the record that a savegame stores (the fields
# that each kind uses) and of the frame (8 and 32 bits, with and without threads) after the flash.
#
#   .\Tools\Verifica\scripthost\Confronta-Overlay.ps1 -Game Doom|Heretic|Hexen|Strife|GLDoom [-Save <file.golden>]
#
# With -Save the file of the OLD executable is also copied to that path (the golden of Tests\Data\ScriptHost).
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Hexen', 'Strife', 'GLDoom')][string]$Game,
  [string]$Save = '',
  [int]$Seconds = 300
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
if ($Game -eq 'GLDoom') { $folder = 'Doom' } else { $folder = $Game }
$binDir = Join-Path $common "bin\$folder"
switch ($Game) {
  'Doom'    { $runs = @('-iwad FREEDOOM2.WAD -warp 1', '-iwad DOOM1.WAD -warp 1 1') }
  'GLDoom'  { $runs = @('-iwad FREEDOOM2.WAD -warp 1') }
  'Heretic' { $runs = @('-iwad HERETIC1.WAD -warp 1 1') }
  'Hexen'   { $runs = @('-iwad HEXEN.WAD -warp 1') }
  'Strife'  { $runs = @('-iwad STRIFE0.WAD -warp 2') }
}
$work = Join-Path $here "harness_out\ovr\run_$Game"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $work | Out-Null
$different = 0
$index = 0
foreach ($arguments in $runs) {
  $index++
  foreach ($label in 'OLD', 'NEW') {
    $exe = Join-Path $here "harness_out\ovr\${Game}_$label.exe"
    if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe" }
    $copy = Join-Path $binDir "${Game}32_OVR$label.exe"
    Copy-Item $exe $copy -Force
    Remove-Item (Join-Path $binDir 'verify_scripthost_overlay.txt') -Force -ErrorAction SilentlyContinue
    try {
      Write-Host "--- $label : $arguments"
      & powershell -NoProfile -File $runner -Exe $copy -Arguments "$arguments -nomonsters -nomusic -nosound -vsh overlay" -WorkDir $binDir -Seconds $Seconds -StopWhenExited
    }
    finally {
      Remove-Item $copy -Force -ErrorAction SilentlyContinue
    }
    $result = Join-Path $binDir 'verify_scripthost_overlay.txt'
    if (-not (Test-Path $result)) { throw "[$label] nessun risultato (il gioco non e arrivato al livello?)" }
    Move-Item $result (Join-Path $work "run${index}_$label.txt") -Force
  }
  $a = @(Get-Content (Join-Path $work "run${index}_OLD.txt"))
  $b = @(Get-Content (Join-Path $work "run${index}_NEW.txt"))
  $diff = @(Compare-Object $a $b -SyncWindow 0)
  if ($a.Count -eq $b.Count -and $diff.Count -eq 0) {
    Write-Host "[$Game] $arguments : UGUALE ($($a.Count) righe)"
  } else {
    $different++
    Write-Host "[$Game] $arguments : DIVERSO (vecchio $($a.Count) righe, nuovo $($b.Count))"
    $diff | Select-Object -First 20 | ForEach-Object { Write-Host "    $($_.SideIndicator) $($_.InputObject)" }
  }
  if ($Save -ne '' -and $index -eq 1) { Copy-Item (Join-Path $work "run${index}_OLD.txt") $Save -Force }
}
if ($different -eq 0) { Write-Host "== $Game : UGUALE in tutte le prove" } else { Write-Host "== $Game : DIVERSO in $different prove" }
