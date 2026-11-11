# TEMPORARY HARNESS (issue #172, fetta 2f-5): the -timedemo demo1/2/3 of Doom with the old executable and the new one
# (the executables of Compila-ScriptHost.ps1 -Variant L2, run with -vsh demo): the last state of the first player
# (gametic, level time, position, angle, momentum, health, kills, items, secrets) written by the hook PS_EventTick must be
# the same. The expected gametics of the shareware demos are 5026, 3836 and 2134 (the last tick that the hook sees can be
# the one before).
#
#   .\Tools\Verifica\scripthost\Confronta-Demo.ps1 [-Game Doom] [-BinDir <cartella>] [-Seconds 600]
#       [-Demos demo1,demo2,demo3] [-OldLabel OLD|BASE_b7155edf] [-Pad 300]
#
# -OldLabel   the executable of the old side: harness_out\Doom_L2_<label>.exe (OLD is 919a19ef, BASE_b7155edf is the
#             commit before the slice, built with Compila-ScriptHost.ps1 -OldCommit b7155edf and copied by hand)
# -Pad        KB of memory that both executables take at the start (-vshpad): demo1 reads past the end of a block of the
#             renderer (R_ReadDC32InternalCache, see docs\PENDING_ISSUES.md) and for some layouts of the memory it ends in an
#             access violation at gametic 4287; the padding moves the layout. The same -Pad on both sides.
param(
  [ValidateSet('Doom')][string]$Game = 'Doom',
  [string]$BinDir = '',
  [int]$Seconds = 600,
  [string[]]$Demos = @('demo1', 'demo2', 'demo3'),
  [string]$OldLabel = 'OLD',
  [int]$Pad = 0
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
if ($BinDir -eq '') { $BinDir = Join-Path $common "bin\$Game" }
if (-not (Test-Path $BinDir)) { throw "Cartella non trovata: $BinDir" }
$all = $true
foreach ($demo in $Demos) {
  $lines = @{}
  foreach ($label in $OldLabel, 'NEW') {
    $exe = Join-Path $here "harness_out\${Game}_L2_$label.exe"
    if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe (Compila-ScriptHost.ps1 -Variant L2)" }
    $copy = Join-Path $BinDir "${Game}32_VSHDEMO$label.exe"
    Copy-Item $exe $copy -Force
    $file = Join-Path $BinDir 'verify_scripthost_demo.txt'
    Remove-Item $file -ErrorAction SilentlyContinue
    try {
      & powershell -NoProfile -File $runner -Exe $copy -Arguments "-iwad DOOM1.WAD -timedemo $demo -nosound -nomusic -vsh demo -vshpad $Pad" -WorkDir $BinDir -Seconds $Seconds -StopWhenExited | Out-Null
    }
    finally {
      Remove-Item $copy -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $file) { $lines[$label] = (Get-Content $file -Raw).Trim() } else { $lines[$label] = 'NESSUN RISULTATO' }
    Remove-Item $file -ErrorAction SilentlyContinue
  }
  # the hook sees the last tick before the end of the demo: it can be the tick before in one run and not in the other
  $oldLine = $lines[$OldLabel] -replace '^gametic=\d+ leveltime=\d+ ', ''
  $newLine = $lines['NEW'] -replace '^gametic=\d+ leveltime=\d+ ', ''
  $same = $oldLine -eq $newLine
  if (-not $same) { $all = $false }
  Write-Host ("{0}: {1}" -f $demo, $(if ($same) { 'UGUALE' } else { 'DIVERSO' }))
  Write-Host "  old: $($lines[$OldLabel])"
  Write-Host "  new: $($lines['NEW'])"
}
if ($all) { Write-Host 'TUTTE UGUALI' } else { Write-Host 'CI SONO DIFFERENZE'; exit 1 }
