<#
  Issue #40: i punti in virgola mobile del renderer software che il corpus delle demo non esercita (pendenze,
  pavimenti 3D, voxel, correzione di prospettiva, interpolazione) provati su una mappa fatta apposta
  (Tests\Data\Fp40\fp40.wad, da Make-Mappa-Virgola.ps1) e su un giro scritto (walk.script, con -autoscript).

  Per ogni scenario di Scenari-Virgola.psd1 e per ogni modo (8, 32) si esegue lo stesso gioco con l'eseguibile di
  riferimento (Win32) e con quello nuovo (Win64), nella stessa cartella e con la stessa riga di comando, e si
  confrontano: impronta dello stato per tic, impronta del fotogramma di ogni tic e i fotogrammi scritti dai passi
  "shot" del copione (byte per byte). Se c'e' una differenza si esegue il riferimento una seconda volta: se due
  esecuzioni dello stesso eseguibile non sono uguali il confronto non vale niente (dice "RUMORE").

  Esiti per scenario e modo: UGUALE, DIVERSO (con il primo fotogramma o il primo tic che cambia), RUMORE,
  ESECUZIONE FALLITA. Esce con 1 se c'e' un DIVERSO, un RUMORE o un'esecuzione fallita.

  Uso:
    powershell -NoProfile -File Tools\Verifica\40\Confronta-Scenari-Virgola.ps1 -Exe <Win64\Doom32.exe> `
      -RefExe <Win32\Doom32.exe> [-Scenario 'slopes*'] [-Modes 8,32] [-WorkRoot C:\ddparity_40] [-DataRoot <bin>]
  Il file freedoom2.wad si prende da -DataRoot (la cartella bin con Doom\FREEDOOM2.WAD).
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$RefExe,
  [string]$Scenario = '*',
  [int[]]$Modes = @(8, 32),
  [string]$WorkRoot = 'C:\ddparity_40',
  [string]$DataRoot = '',
  [int]$TimeoutSeconds = 300
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
$root = Get-ParityRoot
$tool = Get-ParityTool
$data = Join-Path $root 'Tests\Data\Fp40'
$pk3 = Join-Path $root 'Tests\Data\Pk3\zpktest.pk3'
$scenarios = (Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Scenari-Virgola.psd1')).Scenarios |
  Where-Object { $_.Name -like $Scenario }
$exeName = 'parity_Doom32.exe'
$newSource = (Resolve-Path $Exe).Path
$refSource = (Resolve-Path $RefExe).Path
$bad = 0

function Invoke-Scenario($dir, $tag, $source, $mode, $files) {
  # la riga di comando e' sempre la stessa: la sua lunghezza sposta i blocchi di memoria (vedi Invoke-ParityEntry)
  Copy-Item $source (Join-Path $dir $exeName) -Force
  foreach ($name in 'ps.txt', 'pf.txt') { Remove-Item (Join-Path $dir $name) -ErrorAction SilentlyContinue }
  # (il filtro 'walk.script.*' di Windows vale anche per 'walk.script' stesso)
  Get-ChildItem $dir -Filter '*.bmp' | Where-Object { $_.Name -like 'walk.script.*.bmp' } | Remove-Item -ErrorAction SilentlyContinue
  $arguments = "-iwad FREEDOOM2.WAD -file $files -config p$mode.ini -dontsavedefaults -nomusic -nosound -noblit " +
    "-warp 1 -skill 3 -autoscript walk.script -statehash ps.txt -framehash pf.txt"
  $run = Invoke-ParityGame -Exe (Join-Path $dir $exeName) -Arguments $arguments -WorkDir $dir -TimeoutSeconds $TimeoutSeconds
  $out = [ordered]@{ Run = $run; State = (Join-Path $dir "$tag.state.txt"); Frame = (Join-Path $dir "$tag.frame.txt"); Shots = @() }
  foreach ($pair in @(@('ps.txt', $out.State), @('pf.txt', $out.Frame))) {
    Remove-Item $pair[1] -ErrorAction SilentlyContinue
    if (Test-Path (Join-Path $dir $pair[0])) { Move-Item (Join-Path $dir $pair[0]) $pair[1] -Force }
  }
  foreach ($bmp in @(Get-ChildItem $dir -Filter '*.bmp' | Where-Object { $_.Name -like 'walk.script.*.bmp' })) {
    $target = Join-Path $dir ("{0}.{1}" -f $tag, $bmp.Name)
    Move-Item $bmp.FullName $target -Force
    $out.Shots += $target
  }
  $out
}

function Test-Same($a, $b) {
  $problems = @()
  $s = (& $tool compare $a.State $b.State) | Out-String
  if ($s -notmatch 'EQUAL') { $problems += "STATO $($s.Trim())" }
  $f = (& $tool compare $a.Frame $b.Frame) | Out-String
  if ($f -notmatch 'EQUAL') { $problems += "FOTOGRAMMI $($f.Trim())" }
  if ($a.Shots.Count -ne $b.Shots.Count) { $problems += "SHOT $($a.Shots.Count) e $($b.Shots.Count)" }
  else {
    for ($i = 0; $i -lt $a.Shots.Count; $i++) {
      $r = [ParityBitmapCompare]::Compare($a.Shots[$i], $b.Shots[$i])
      if ($r -ne 'uguali') { $problems += ("{0}: {1}" -f (Split-Path $a.Shots[$i] -Leaf), $r) }
    }
  }
  $problems
}

foreach ($sc in $scenarios) {
  $files = 'fp40.wad'
  if ($sc.Pk3) { $files += ' zpktest.pk3' }
  $dir = Initialize-ParityRunDir -Game 'Doom' -WorkRoot $WorkRoot -DataRoot $DataRoot -ExtraIni $sc.Ini
  Copy-Item (Join-Path $data 'fp40.wad') $dir -Force
  Copy-Item (Join-Path $data 'walk.script') $dir -Force
  Copy-Item $pk3 $dir -Force
  foreach ($mode in $Modes) {
    $label = "{0,-14} modo {1,2}" -f $sc.Name, $mode
    $ref = Invoke-Scenario $dir 'ref' $refSource $mode $files
    $new = Invoke-Scenario $dir 'new' $newSource $mode $files
    $failed = @($ref, $new) | Where-Object { $_.Run.Alive -or $_.Run.Crash -or -not (Test-Path $_.State) }
    if ($failed) {
      Write-Output "$label : ESECUZIONE FALLITA ($($failed[0].Run.Text))"; $bad++; continue
    }
    $diff = Test-Same $ref $new
    if (-not $diff) { Write-Output ("$label : UGUALE ({0} fotogrammi 'shot', stato e impronte)" -f $new.Shots.Count); continue }
    # una differenza: il riferimento e' uguale a se stesso? (la seconda esecuzione si fa solo qui, per risparmiare tempo)
    $ref2 = Invoke-Scenario $dir 'ref2' $refSource $mode $files
    $noise = Test-Same $ref $ref2
    if ($noise) { Write-Output "$label : RUMORE (il riferimento non e' uguale a se stesso): $($noise -join '; ')" }
    else { Write-Output "$label : DIVERSO: $($diff -join '; ')" }
    $bad++
  }
}
if ($bad -gt 0) { exit 1 }
