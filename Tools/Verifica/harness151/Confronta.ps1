# TEMPORARY HARNESS (issues #151 and #156): runs <Game>_V_OLD.exe and <Game>_V_NEW.exe (Compila-151.ps1) on a list of
# maps and compares what they wrote:
#   verify151_lumps.txt   the lumps W_ReadLump read, in order (up to the end of the level load)
#   verify151_<MAP>.txt   count and FNV-1a of the level structures (issue 151) and DUMP156 (issue 156)
#
#   .\Tools\Verifica\harness151\Confronta.ps1 -Game Doom|Heretic|Hexen|Strife|GLDoom [-BinDir <cartella>] [-Seconds 120]
#
# Copies the executables into bin\<Gioco>, runs them one at a time with Tools\Esegui-gioco.ps1 -StopWhenExited
# (the hook ends the game with Halt(0) once the level is loaded), prints UGUALE or DIVERSO for every run with
# the differing lines, and removes the copied executables and the files it made.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Hexen', 'Strife', 'GLDoom')][string]$Game,
  [string]$BinDir = '',
  [int]$Seconds = 120,
  [int]$ShowLines = 12
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
if ($Game -eq 'GLDoom') { $folder = 'Doom' } else { $folder = $Game }
if ($BinDir -eq '') { $BinDir = Join-Path $common "bin\$folder" }
if (-not (Test-Path $BinDir)) { throw "Cartella non trovata: $BinDir" }
$exeName = "${Game}32"

switch ($Game) {
  'Doom'    { $runs = @('-iwad FREEDOOM2.WAD -warp 1', '-iwad FREEDOOM2.WAD -warp 7', '-iwad DOOM1.WAD -warp 1 1') }
  'GLDoom'  { $runs = @('-iwad FREEDOOM2.WAD -warp 1') }
  'Heretic' { $runs = @('-iwad HERETIC1.WAD -warp 1 1', '-iwad HERETIC1.WAD -warp 1 2') }
  'Hexen'   { $runs = @('-iwad HEXEN.WAD -warp 1') }
  'Strife'  { $runs = @('-iwad STRIFE0.WAD -warp 2') }
}
$extra = '-nomonsters -nomusic -nosound -verify151 1'

function Clear-Files {
  Get-ChildItem $BinDir -Filter 'verify151_*.txt' -ErrorAction SilentlyContinue | Remove-Item -Force
}

function Invoke-One([string]$Label, [string]$Arguments, [string]$Dest) {
  $exe = Join-Path $here "harness_out\${Game}_V_$($Label.ToUpper()).exe"
  if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe (Compila-151.ps1)" }
  $copy = Join-Path $BinDir "${exeName}_V$($Label.ToUpper()).exe"
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
  Get-ChildItem $BinDir -Filter 'verify151_*.txt' -ErrorAction SilentlyContinue | Move-Item -Destination $Dest -Force
}

$work = Join-Path $here "harness_out\verify151\$Game"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
$different = 0
$index = 0
try {
  foreach ($arguments in $runs) {
    $index++
    $old = Join-Path $work "run${index}_old"
    $new = Join-Path $work "run${index}_new"
    Invoke-One 'Old' $arguments $old
    Invoke-One 'New' $arguments $new

    $names = @(Get-ChildItem $old, $new -Filter 'verify151_*.txt' -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } | Sort-Object -Unique)
    if ($names.Count -eq 0) { Write-Host "[$Game] $arguments : NESSUN FILE (il gioco non e arrivato a caricare il livello?)"; $different++; continue }
    foreach ($name in $names) {
      $a = Join-Path $old $name
      $b = Join-Path $new $name
      if (-not (Test-Path $a) -or -not (Test-Path $b)) {
        Write-Host "[$Game] $arguments $name : DIVERSO (file presente solo in uno dei due)"
        $different++
        continue
      }
      $linesA = @(Get-Content $a)
      $linesB = @(Get-Content $b)
      $diff = @(Compare-Object $linesA $linesB -SyncWindow 0)
      if ($linesA.Count -eq $linesB.Count -and $diff.Count -eq 0) {
        Write-Host "[$Game] $arguments $name : UGUALE ($($linesA.Count) righe)"
      } else {
        $different++
        Write-Host "[$Game] $arguments $name : DIVERSO (vecchio $($linesA.Count) righe, nuovo $($linesB.Count))"
        if ($name -eq 'verify151_lumps.txt') {
          # first position where the two orders differ
          $limit = [Math]::Min($linesA.Count, $linesB.Count)
          for ($i = 0; $i -lt $limit; $i++) {
            if ($linesA[$i] -ne $linesB[$i]) { Write-Host "    prima differenza alla riga $($i + 1): vecchio '$($linesA[$i])' nuovo '$($linesB[$i])'"; break }
          }
        } else {
          $diff | Select-Object -First $ShowLines | ForEach-Object {
            if ($_.SideIndicator -eq '<=') { $side = 'vecchio' } else { $side = 'nuovo  ' }
            Write-Host "    $side $($_.InputObject)"
          }
        }
      }
    }
  }
}
finally {
  Clear-Files
  Get-ChildItem $BinDir -Filter "${exeName}_V*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force
}
if ($different -eq 0) { Write-Host "== $Game : UGUALE in tutte le prove" } else { Write-Host "== $Game : DIVERSO in $different confronti" }
