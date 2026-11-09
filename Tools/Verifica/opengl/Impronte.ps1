# TEMPORARY HARNESS (issue #177): compares the level geometry of the OpenGL games, old executable against new one.
#
#   .\Tools\Verifica\opengl\Impronte.ps1 -Game GLDoom|GLHeretic|GLHexen|GLStrife [-BinDir <cartella>] [-Seconds 300]
#
# Runs <Game>_GL_OLD.exe and <Game>_GL_NEW.exe (Compila.ps1) with  -glfingerprint <file>: after the first level the
# harness loads every map of the IWAD one after the other and writes, for each map, FNV-1a 64 sums of the GL vertexes
# and texture coordinates, the loops of the sectors, the flags of sectors and lines, the vertexes, segs, subsectors
# and nodes (by value: no pointers). Prints UGUALE or DIVERSO for each IWAD, with the lines that differ.
# The files stay in <this tree>\harness_out\impronte\<Game>\ . Needs the lock of Tools\Esegui-gioco.ps1.
param(
  [Parameter(Mandatory = $true)][ValidateSet('GLDoom', 'GLHeretic', 'GLHexen', 'GLStrife')][string]$Game,
  [string]$BinDir = '',
  [int]$Seconds = 300
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
$folder = $Game.Substring(2)
if ($BinDir -eq '') { $BinDir = Join-Path $common "bin\$folder" }
if (-not (Test-Path $BinDir)) { throw "Cartella non trovata: $BinDir" }
$exeName = "${Game}32"

switch ($Game) {
  'GLDoom'    { $runs = @(@('FREEDOOM2.WAD', '-iwad FREEDOOM2.WAD -warp 1'), @('DOOM1.WAD', '-iwad DOOM1.WAD -warp 1 1')) }
  'GLHeretic' { $runs = @(, @('HERETIC1.WAD', '-iwad HERETIC1.WAD -warp 1 1')) }
  'GLHexen'   { $runs = @(, @('HEXEN.WAD', '-iwad HEXEN.WAD -warp 1')) }
  'GLStrife'  { $runs = @(, @('STRIFE0.WAD', '-iwad STRIFE0.WAD -warp 2')) }
}
$work = Join-Path $here "harness_out\impronte\$Game"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $work | Out-Null
$different = 0

foreach ($run in $runs) {
  $iwad = $run[0]
  $arguments = $run[1]
  $files = @{}
  foreach ($version in @('Old', 'New')) {
    $exe = Join-Path $here "harness_out\${Game}_GL_$($version.ToUpper()).exe"
    if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe (Compila.ps1)" }
    $copy = Join-Path $BinDir "${exeName}_G$($version.ToUpper()).exe"
    $output = Join-Path $work "$($iwad)_$version.txt"
    Copy-Item $exe $copy -Force
    try {
      Write-Host "--- $version : $arguments"
      & powershell -NoProfile -File $runner -Exe $copy -Arguments "$arguments -nomonsters -nomusic -nosound -nomouse -nojoystick -windowed -glfingerprint `"$output`"" -WorkDir $BinDir -Seconds $Seconds -StopWhenExited
    }
    finally {
      Remove-Item $copy -Force -ErrorAction SilentlyContinue
    }
    $files[$version] = $output
  }
  if (-not (Test-Path $files['Old']) -or -not (Test-Path $files['New'])) {
    Write-Host "[$Game] $iwad : NESSUN FILE (il gioco non e arrivato alla fine; vedi bin\<Gioco>\DATA\LOGS)"
    $different++
    continue
  }
  $a = [System.IO.File]::ReadAllLines($files['Old'])
  $b = [System.IO.File]::ReadAllLines($files['New'])
  if ([System.Linq.Enumerable]::SequenceEqual([string[]]$a, [string[]]$b)) {
    Write-Host "[$Game] $iwad : UGUALE ($($a.Count) mappe)"
  }
  else {
    Write-Host "[$Game] $iwad : DIVERSO (vecchio $($a.Count) mappe, nuovo $($b.Count))"
    $different++
    $limit = [Math]::Max($a.Count, $b.Count)
    $shown = 0
    for ($i = 0; $i -lt $limit -and $shown -lt 6; $i++) {
      $va = if ($i -lt $a.Count) { $a[$i] } else { '<fine>' }
      $vb = if ($i -lt $b.Count) { $b[$i] } else { '<fine>' }
      if ($va -cne $vb) { Write-Host "    vecchio: $va"; Write-Host "    nuovo  : $vb"; $shown++ }
    }
  }
}
if ($different -eq 0) { Write-Host "== $Game : UGUALE in tutte le prove" } else { Write-Host "== $Game : DIVERSO in $different prove" }
