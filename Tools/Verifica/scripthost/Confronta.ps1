# TEMPORARY HARNESS (issue #173), level L2 of the plan docs\SCRIPTHOST_PIANO.md: runs <Game>_L2_OLD.exe and
# <Game>_L2_NEW.exe (Compila-ScriptHost.ps1 -Variant L2) on a level and compares what they wrote:
#   verify_scripthost_L2.txt          one line per host function: the result of the script that calls it and the FNV-1a
#                                     of the state of the level (sectors, lines, sides, mobjs, player) after the call
#   verify_scripthost_L2_scripts.txt  the generated scripts (the generator is the same unit, so they must be equal)
#   verify_scripthost_L2_context.txt  the implicit actor (fetta 2f-5): events and RunScript, see LEGGIMI.md
#   verify_scripthost_L2_progress.txt the function being run when the game ended (only if it crashed)
#
#   .\Tools\Verifica\scripthost\Confronta.ps1 -Game Doom|Heretic|Hexen|Strife|GLDoom [-BinDir <cartella>] [-Seconds 600]
#                                            [-Extra '-vshskip Name1,Name2'] [-Twice]
#
# Copies the executables into bin\<Gioco>, runs them one at a time with Tools\Esegui-gioco.ps1 -StopWhenExited (the
# hook ends the game with Halt(0) once the battery is done), prints UGUALE or DIVERSO for every file with the
# differing lines, and removes the copied executables and the files it made. With -Twice every executable also runs
# a second time and the two runs of the same executable are compared (a line that differs there is noise, not a
# difference between old and new: it is listed apart).
# If a run ends without the result file, the progress file says which function ended the game: skip it with
# -Extra '-vshskip <Name>' for both executables and run again.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Hexen', 'Strife', 'GLDoom')][string]$Game,
  [string]$BinDir = '',
  [int]$Seconds = 600,
  [string]$Extra = '',
  [switch]$Twice,
  [int]$ShowLines = 15,
  [int]$MaxRepetitions = 80
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
  'Doom'    { $runs = @('-iwad FREEDOOM2.WAD -warp 1', '-iwad DOOM1.WAD -warp 1 1') }
  'GLDoom'  { $runs = @('-iwad FREEDOOM2.WAD -warp 1') }
  'Heretic' { $runs = @('-iwad HERETIC1.WAD -warp 1 1') }
  'Hexen'   { $runs = @('-iwad HEXEN.WAD -warp 1') }
  'Strife'  { $runs = @('-iwad STRIFE0.WAD -warp 2') }
}
$flags = "-nomonsters -nomusic -nosound -vsh l2 $Extra"

function Clear-Files {
  Get-ChildItem $BinDir -Filter 'verify_scripthost_*.txt' -ErrorAction SilentlyContinue | Remove-Item -Force
}

$script:skips = New-Object System.Collections.Generic.List[string]
$script:added = 0

# one run of one executable with the current list of skipped functions; true if it wrote the result file
function Invoke-One([string]$Label, [string]$Arguments, [string]$Dest) {
  $exe = Join-Path $here "harness_out\${Game}_L2_$($Label.ToUpper()).exe"
  if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe (Compila-ScriptHost.ps1 -Variant L2)" }
  $copy = Join-Path $BinDir "${exeName}_VSH$($Label.ToUpper()).exe"
  Copy-Item $exe $copy -Force
  Clear-Files
  $skipArgument = ''
  if ($script:skips.Count -gt 0) { $skipArgument = '-vshskip ' + ($script:skips -join ',') }
  try {
    Write-Host "--- $Label : $Arguments (saltate dal ciclo: $($script:skips.Count))"
    & powershell -NoProfile -File $runner -Exe $copy -Arguments "$Arguments $flags $skipArgument" -WorkDir $BinDir -Seconds $Seconds -StopWhenExited
  }
  finally {
    Remove-Item $copy -Force -ErrorAction SilentlyContinue
  }
  Remove-Item $Dest -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force $Dest | Out-Null
  Get-ChildItem $BinDir -Filter 'verify_scripthost_*.txt' -ErrorAction SilentlyContinue | Move-Item -Destination $Dest -Force
  return (Test-Path (Join-Path $Dest 'verify_scripthost_L2.txt'))
}

# runs until the result file exists: an executable that dies puts the function in progress in the list of the skipped
# ones and runs again (the list is shared by old, new and all the repetitions); the same function twice in a row, or
# too many repetitions, stop everything
function Invoke-UntilDone([string]$Label, [string]$Arguments, [string]$Dest) {
  $last = ''
  while ($true) {
    if (Invoke-One $Label $Arguments $Dest) { return }
    $progress = Join-Path $Dest 'verify_scripthost_L2_progress.txt'
    if (-not (Test-Path $progress)) { throw "[$Label] nessun risultato e nessun file di avanzamento (il gioco non e arrivato al livello?)" }
    $line = (Get-Content $progress | Select-Object -First 1)
    if ($line -notmatch '^\d+ (\S+)\.(\S+)$') { throw "[$Label] file di avanzamento non riconosciuto: $line" }
    $name = $Matches[2]
    if ($name -eq $last -or $script:skips -contains $name) { throw "[$Label] l'eseguibile e morto due volte sulla stessa funzione: $line" }
    $last = $name
    $script:added++
    if ($script:added -gt $MaxRepetitions) { throw "troppe ripetizioni ($MaxRepetitions): saltate finora $($script:skips -join ',')" }
    Write-Host "    [$Label] morto su $line : salto $name e rilancio"
    $script:skips.Add($name)
  }
}
function Compare-Files([string]$Title, [string]$A, [string]$B, [string]$NameA, [string]$NameB) {
  if (-not (Test-Path $A) -or -not (Test-Path $B)) {
    Write-Host "$Title : DIVERSO (file presente solo in uno dei due)"
    return 1
  }
  $linesA = @(Get-Content $A)
  $linesB = @(Get-Content $B)
  $diff = @(Compare-Object $linesA $linesB -SyncWindow 0)
  if ($linesA.Count -eq $linesB.Count -and $diff.Count -eq 0) {
    Write-Host "$Title : UGUALE ($($linesA.Count) righe)"
    return 0
  }
  Write-Host "$Title : DIVERSO ($NameA $($linesA.Count) righe, $NameB $($linesB.Count))"
  $diff | Select-Object -First $ShowLines | ForEach-Object {
    if ($_.SideIndicator -eq '<=') { $side = $NameA } else { $side = $NameB }
    Write-Host "    $side $($_.InputObject)"
  }
  return 1
}

$work = Join-Path $here "harness_out\verifyvsh\$Game"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
$different = 0
$index = 0
try {
  foreach ($arguments in $runs) {
    $index++
    # until old and new both finish with the same, unchanged list of skipped functions
    do {
      $before = $script:skips.Count
      Invoke-UntilDone 'Old' $arguments (Join-Path $work "run${index}_old")
      Invoke-UntilDone 'New' $arguments (Join-Path $work "run${index}_new")
    } while ($script:skips.Count -ne $before)
    if ($Twice) {
      Invoke-UntilDone 'Old' $arguments (Join-Path $work "run${index}_old2")
      Invoke-UntilDone 'New' $arguments (Join-Path $work "run${index}_new2")
      if ($script:skips.Count -ne $before) { throw 'la lista dei salti e cambiata nelle ripetizioni: rifare senza -Twice poi con -Twice' }
    }
    $skipFile = Join-Path $work "run${index}_skipped.txt"
    $script:skips | Set-Content $skipFile
    Write-Host "[$Game] $arguments : funzioni saltate dal ciclo automatico, oltre a Polyobj_* e alla lista di default ($($script:skips.Count)): $($script:skips -join ', ')  -> $skipFile"
    foreach ($name in 'verify_scripthost_L2.txt', 'verify_scripthost_L2_scripts.txt', 'verify_scripthost_L2_context.txt', 'verify_scripthost_L2_props.txt', 'verify_scripthost_L2_props_scripts.txt') {
      $different += Compare-Files "[$Game] $arguments $name" (Join-Path $work "run${index}_old\$name") (Join-Path $work "run${index}_new\$name") 'vecchio' 'nuovo'
      if ($Twice) {
        $noiseOld = Compare-Files "[$Game] $arguments $name (vecchio contro vecchio, rumore)" (Join-Path $work "run${index}_old\$name") (Join-Path $work "run${index}_old2\$name") 'vecchio' 'vecchio2'
        $noiseNew = Compare-Files "[$Game] $arguments $name (nuovo contro nuovo, rumore)" (Join-Path $work "run${index}_new\$name") (Join-Path $work "run${index}_new2\$name") 'nuovo' 'nuovo2'
      }
    }
  }
}
finally {
  Clear-Files
  Get-ChildItem $BinDir -Filter "${exeName}_VSH*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force
}
if ($different -eq 0) { Write-Host "== $Game : UGUALE in tutte le prove" } else { Write-Host "== $Game : DIVERSO in $different confronti" }
Write-Host "File in $work"
