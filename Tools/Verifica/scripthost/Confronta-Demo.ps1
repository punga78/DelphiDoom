# TEMPORARY HARNESS (issue #172, fetta 2f-5): the -timedemo demo1/2/3 of Doom with the old executable and the new one
# (the two executables of Compila-ScriptHost.ps1 -Variant L2, run with -vsh demo): the last state of the first player
# (gametic, level time, position, angle, momentum, health, kills, items, secrets) written by the hook PS_EventTick must be
# the same. The expected gametics of the shareware demos are 5026, 3836 and 2134.
#
#   .\Tools\Verifica\scripthost\Confronta-Demo.ps1 [-Game Doom] [-BinDir <cartella>] [-Seconds 600]
#
param(
  [ValidateSet('Doom')][string]$Game = 'Doom',
  [string]$BinDir = '',
  [int]$Seconds = 600
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
if ($BinDir -eq '') { $BinDir = Join-Path $common "bin\$Game" }
if (-not (Test-Path $BinDir)) { throw "Cartella non trovata: $BinDir" }
$all = $true
foreach ($demo in 'demo1', 'demo2', 'demo3') {
  $lines = @{}
  foreach ($label in 'OLD', 'NEW') {
    $exe = Join-Path $here "harness_out\${Game}_L2_$label.exe"
    if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe (Compila-ScriptHost.ps1 -Variant L2)" }
    $copy = Join-Path $BinDir "${Game}32_VSHDEMO$label.exe"
    Copy-Item $exe $copy -Force
    $file = Join-Path $BinDir 'verify_scripthost_demo.txt'
    Remove-Item $file -ErrorAction SilentlyContinue
    try {
      & powershell -NoProfile -File $runner -Exe $copy -Arguments "-iwad DOOM1.WAD -timedemo $demo -nosound -nomusic -vsh demo" -WorkDir $BinDir -Seconds $Seconds -StopWhenExited | Out-Null
    }
    finally {
      Remove-Item $copy -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $file) { $lines[$label] = (Get-Content $file -Raw).Trim() } else { $lines[$label] = 'NESSUN RISULTATO' }
    Remove-Item $file -ErrorAction SilentlyContinue
  }
  $same = $lines['OLD'] -eq $lines['NEW']
  if (-not $same) { $all = $false }
  Write-Host ("{0}: {1}" -f $demo, $(if ($same) { 'UGUALE' } else { 'DIVERSO' }))
  Write-Host "  old: $($lines['OLD'])"
  Write-Host "  new: $($lines['NEW'])"
}
if ($all) { Write-Host 'TUTTE UGUALI' } else { Write-Host 'CI SONO DIFFERENZE'; exit 1 }
