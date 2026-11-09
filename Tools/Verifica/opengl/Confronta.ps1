# TEMPORARY HARNESS (issue #177): runs <Game>_GL_OLD.exe twice and <Game>_GL_NEW.exe once (Compila.ps1) on a
# list of maps and compares the GL calls they recorded (glrecord_<MAP>.txt):
#   old against old  = the noise: it has to be identical, otherwise the comparison with the new one means nothing
#   old against new  = the result
#
#   .\Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom|GLHeretic|GLHexen|GLStrife [-BinDir <cartella>]
#                                          [-Tics 70] [-StartTic 35] [-Seconds 120] [-SkipNoise]
#
# Copies the executables into bin\<Gioco>, runs them one at a time with Tools\Esegui-gioco.ps1 -StopWhenExited
# (the game ends with Halt(0) after the last recorded tic), prints UGUALE or DIVERSO for each comparison with
# the first lines that differ, and removes the copied executables and the files it made.
# Files of the runs stay in <this tree>\harness_out\glrecord\<Game>\ for a closer look.
param(
  [Parameter(Mandatory = $true)][ValidateSet('GLDoom', 'GLHeretic', 'GLHexen', 'GLStrife')][string]$Game,
  [string]$BinDir = '',
  [int]$Tics = 70,
  [int]$StartTic = 35,
  [int]$Seconds = 120,
  [int]$ShowLines = 8,
  [switch]$SkipNoise
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
  'GLDoom'    { $runs = @('-iwad FREEDOOM2.WAD -warp 1', '-iwad DOOM1.WAD -warp 1 1') }
  'GLHeretic' { $runs = @('-iwad HERETIC1.WAD -warp 1 1') }
  'GLHexen'   { $runs = @('-iwad HEXEN.WAD -warp 1') }
  'GLStrife'  { $runs = @('-iwad STRIFE0.WAD -warp 2') }
}
# fixed state: no monsters, no sound, no interpolation (its fraction depends on the clock), a window
$extra = "-nomonsters -nomusic -nosound -nointerpolate -windowed -glrecord $Tics -glrecordstart $StartTic"

function Clear-Files {
  Get-ChildItem $BinDir -Filter 'glrecord_*.txt' -ErrorAction SilentlyContinue | Remove-Item -Force
}

function Invoke-One([string]$Label, [string]$Version, [string]$Arguments, [string]$Dest) {
  $exe = Join-Path $here "harness_out\${Game}_GL_$($Version.ToUpper()).exe"
  if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe (Compila.ps1)" }
  $copy = Join-Path $BinDir "${exeName}_G$($Version.ToUpper()).exe"
  Copy-Item $exe $copy -Force
  Clear-Files
  try {
    Write-Host "--- $Label : $Arguments"
    & powershell -NoProfile -File $runner -Exe $copy -Arguments "$Arguments $extra" -WorkDir $BinDir -Seconds $Seconds -StopWhenExited
  }
  finally {
    Remove-Item $copy -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Force $Dest | Out-Null
  Get-ChildItem $BinDir -Filter 'glrecord_*.txt' -ErrorAction SilentlyContinue | Move-Item -Destination $Dest -Force
}

# Compares two files; writes UGUALE/DIVERSO and the first differences. Returns $true if they are the same.
function Compare-Records([string]$Title, [string]$A, [string]$B, [string]$NameA, [string]$NameB) {
  $linesA = [System.IO.File]::ReadAllLines($A)
  $linesB = [System.IO.File]::ReadAllLines($B)
  if ([System.Linq.Enumerable]::SequenceEqual([string[]]$linesA, [string[]]$linesB)) {
    Write-Host "$Title : UGUALE ($($linesA.Count) righe)"
    return $true
  }
  Write-Host "$Title : DIVERSO ($NameA $($linesA.Count) righe, $NameB $($linesB.Count))"
  $limit = [Math]::Min($linesA.Count, $linesB.Count)
  $first = -1
  for ($i = 0; $i -lt $limit; $i++) { if ($linesA[$i] -cne $linesB[$i]) { $first = $i; break } }
  if ($first -lt 0) { $first = $limit }
  # the frame the first difference is in (its label is in the FRAME line that closes it)
  $label = '?'
  for ($i = $first; $i -lt $linesA.Count; $i++) { if ($linesA[$i].StartsWith('FRAME ')) { $label = $linesA[$i]; break } }
  Write-Host "    prima differenza alla riga $($first + 1), nel fotogramma chiuso da: $label"
  for ($k = 0; $k -lt $ShowLines; $k++) {
    $ia = $first + $k
    $va = if ($ia -lt $linesA.Count) { $linesA[$ia] } else { '<fine>' }
    $vb = if ($ia -lt $linesB.Count) { $linesB[$ia] } else { '<fine>' }
    if ($va -cne $vb) { Write-Host "    $NameA : $va"; Write-Host "    $NameB : $vb" }
  }
  # which frames differ (compare the FRAME lines in order)
  $framesA = @($linesA | Where-Object { $_.StartsWith('FRAME ') })
  $framesB = @($linesB | Where-Object { $_.StartsWith('FRAME ') })
  $differing = 0
  $count = [Math]::Min($framesA.Count, $framesB.Count)
  for ($i = 0; $i -lt $count; $i++) { if ($framesA[$i] -cne $framesB[$i]) { $differing++ } }
  Write-Host "    fotogrammi: $NameA $($framesA.Count), $NameB $($framesB.Count), con somma diversa: $differing"
  return $false
}

$work = Join-Path $here "harness_out\glrecord\$Game"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
$different = 0
$noisy = 0
$index = 0
try {
  foreach ($arguments in $runs) {
    $index++
    $old1 = Join-Path $work "run${index}_old1"
    $old2 = Join-Path $work "run${index}_old2"
    $new = Join-Path $work "run${index}_new"
    Invoke-One 'vecchio (1)' 'Old' $arguments $old1
    if (-not $SkipNoise) { Invoke-One 'vecchio (2, rumore)' 'Old' $arguments $old2 }
    Invoke-One 'nuovo' 'New' $arguments $new

    $names = @(Get-ChildItem $old1, $new -Filter 'glrecord_*.txt' -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } | Sort-Object -Unique)
    if ($names.Count -eq 0) { Write-Host "[$Game] $arguments : NESSUN FILE (il gioco non e arrivato a registrare? vedi bin\<Gioco>\DATA\LOGS)"; $different++; continue }
    foreach ($name in $names) {
      $a = Join-Path $old1 $name
      $b = Join-Path $new $name
      if (-not (Test-Path $a) -or -not (Test-Path $b)) {
        Write-Host "[$Game] $arguments $name : DIVERSO (file presente solo in uno dei due)"
        $different++
        continue
      }
      if (-not $SkipNoise) {
        $c = Join-Path $old2 $name
        if (Test-Path $c) {
          if (-not (Compare-Records "[$Game] $arguments $name RUMORE (vecchio contro vecchio)" $a $c 'vecchio1' 'vecchio2')) {
            $noisy++
            Write-Host "    ATTENZIONE: due esecuzioni dello stesso eseguibile non danno lo stesso flusso: il confronto col nuovo non e' conclusivo"
          }
        }
      }
      if (-not (Compare-Records "[$Game] $arguments $name RISULTATO (vecchio contro nuovo)" $a $b 'vecchio' 'nuovo')) { $different++ }
    }
  }
}
finally {
  Clear-Files
  Get-ChildItem $BinDir -Filter "${exeName}_G*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force
}
if ($noisy -gt 0) { Write-Host "== $Game : RUMORE in $noisy confronti vecchio-vecchio" }
if ($different -eq 0) { Write-Host "== $Game : UGUALE in tutte le prove" } else { Write-Host "== $Game : DIVERSO in $different confronti" }
