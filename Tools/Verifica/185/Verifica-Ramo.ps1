<#
  Issue #185: la verifica standard di un ramo (un worktree o la radice) dopo uno sviluppo che tocca il motore.
  Fa girare, nell'ordine, e scrive una riga OK / FALLITO per controllo:
    1. build dei dieci eseguibili dei giochi (errori e avvisi contro la base: gli avvisi non devono aumentare);
    2. build dei quattro compilatori ddc_* e di Launcher, DD_IDE, DD_Tools, ddc;
    3. build ed esecuzione delle suite di test indicate (numeri letti dal runner: trovati, passati, falliti, errori);
    4. le tre demo di Doom32 (5026 / 3836 / 2134 gametic);
    5. l'avvio di Heretic32, Hexen32, Strife32 e dei quattro GL (vivi dopo 20 s, nessun crash.txt);
    6. i golden della fase 0 (Confronta-Golden.ps1: 44 voci a 8 bit e 44 a 32 bit: tutte UGUALI).
  NON fa i confronti con -ExtraIni, le misure a coppie e le prove specifiche di una fetta: quelle stanno nel file
  Tools\Verifica\185\Fetta-<nome>.txt scritto da chi ha sviluppato (comandi esatti) e si lanciano a parte.

  Uso (da qualunque cartella):
    powershell -NoProfile -File <radice>\Tools\Verifica\185\Verifica-Ramo.ps1 -Root <radice del ramo o del worktree>
      [-Suites Hud,Parity,...] [-DataRoot C:\Progetti\DelphiDoom\bin] [-WorkRoot C:\ddparity_verifica]
      [-NoBuild] [-NoGolden] [-NoDemo] [-Report <file>]

  Esce con 0 se tutto e' OK, 1 se qualcosa e' FALLITO. Scrive anche un riepilogo in <Report> (predefinito:
  <WorkRoot>\Verifica-Ramo.txt). Ci vogliono circa 45 minuti (i golden da soli 30): lanciarlo in primo piano o
  in background e leggere il riepilogo finale.

  Base degli avvisi (Tools\build.bat giochi, righe "warning [HW]dddd" divise per due) di master 57fce618 con la
  fetta 1a: 387 / 337 / 309 / 259 / 204 / 154 / 418 / 345 / 386 / 387. Quando una fetta la riduce, aggiornare qui.
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [string[]]$Suites = @('Hud', 'Parity', 'Common', 'Renderer', 'Iwad', 'Palette', 'OpenGl', 'Radix', 'Speed'),
  [string]$DataRoot = 'C:\Progetti\DelphiDoom\bin',
  [string]$WorkRoot = 'C:\ddparity_verifica',
  [switch]$NoBuild,
  [switch]$NoGolden,
  [switch]$NoDemo,
  [string]$Report = ''
)
$ErrorActionPreference = 'Continue'
$Root = (Resolve-Path $Root).Path
if ($Report -eq '') { $Report = Join-Path $WorkRoot 'Verifica-Ramo.txt' }
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
$Suites = @($Suites | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$started = Get-Date
$lines = New-Object System.Collections.ArrayList
$failed = 0

function Say([string]$text) { Write-Output $text; [void]$lines.Add($text) }
function Check([bool]$ok, [string]$text) {
  if ($ok) { Say "OK       $text" } else { Say "FALLITO  $text"; $script:failed++ }
}
function Build([string]$name) { & cmd /c "`"$Root\Tools\build.bat`" $name" | Out-Null }
function LogOf([string]$name) { Join-Path $Root "logs\$name.log" }
function ErrorCount([string]$name) {
  $log = LogOf $name
  if (-not (Test-Path $log)) { return -1 }
  @(Get-Content $log | Select-String ' error | Fatal').Count
}
function WarningCount([string]$name) {
  $log = LogOf $name
  if (-not (Test-Path $log)) { return -1 }
  [int](@(Get-Content $log | Select-String 'warning [HW]\d{4}').Count / 2)
}
function Numbers([string]$text) {
  $r = @{}
  foreach ($k in 'Found', 'Passed', 'Failed', 'Errored', 'Ignored') {
    $m = [regex]::Match($text, "Tests $k\s*:\s*(\d+)")
    $r[$k] = if ($m.Success) { [int]$m.Groups[1].Value } else { -1 }
  }
  $r
}

Say "Verifica del ramo: $Root ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
Say "Commit: $((& git -C $Root log -1 --format='%h %s').Substring(0, 70))"

# --- 1 e 2. build -------------------------------------------------------------------------------------------
$games = @('Doom32', 'GLDoom32', 'Heretic32', 'GLHeretic32', 'Hexen32', 'GLHexen32', 'Strife32', 'GLStrife32', 'Radix32', 'SpeedHaste32')
$baseline = @(387, 337, 309, 259, 204, 154, 418, 345, 386, 387)
if (-not $NoBuild) { Build 'giochi' }
for ($i = 0; $i -lt $games.Count; $i++) {
  $e = ErrorCount $games[$i]
  $w = WarningCount $games[$i]
  Check (($e -eq 0) -and ($w -le $baseline[$i])) ("build {0}: errori {1}, avvisi {2} (base {3})" -f $games[$i], $e, $w, $baseline[$i])
}
$tools = @('ddc_doom', 'ddc_heretic', 'ddc_hexen', 'ddc_strife', 'Launcher', 'DD_IDE', 'DD_Tools', 'ddc')
$toolPaths = @{ 'Launcher' = 'Launcher\Launcher'; 'DD_IDE' = 'DD_IDE\DD_IDE'; 'DD_Tools' = 'DD_Tools\DD_Tools'; 'ddc' = 'Libs\Ddc\ddc' }
foreach ($t in $tools) {
  $target = if ($toolPaths.ContainsKey($t)) { $toolPaths[$t] } else { $t }
  if (-not $NoBuild) { Build $target }
  $e = ErrorCount $t
  Check ($e -eq 0) ("build {0}: errori {1}" -f $t, $e)
}

# --- 3. suite ------------------------------------------------------------------------------------------------
foreach ($s in $Suites) {
  $project = "Tests\DelphiDoom.Tests.$s"
  if (-not $NoBuild) { Build $project }
  $e = ErrorCount "DelphiDoom.Tests.$s"
  $exe = Join-Path $Root "bin\Tests\DelphiDoom.Tests.$s.exe"
  if (-not (Test-Path $exe)) { Check $false "suite ${s}: eseguibile non trovato"; continue }
  $output = (& $exe 2>&1 | Out-String)
  $n = Numbers $output
  Check (($e -eq 0) -and ($n.Found -gt 0) -and ($n.Failed -eq 0) -and ($n.Errored -eq 0)) `
    ("suite {0}: errori di build {1}, trovati {2}, passati {3}, ignorati {4}, falliti {5}, errori {6}" -f $s, $e, $n.Found, $n.Passed, $n.Ignored, $n.Failed, $n.Errored)
}

# --- 4 e 5. demo e avvii -------------------------------------------------------------------------------------
. (Join-Path $Root 'Tools\Verifica\185\Parity-Common.ps1')
$runner = Join-Path $Root 'Tools\Esegui-gioco.ps1'
function RunDir([string]$game, [hashtable]$executables) {
  Initialize-ParityRunDir -Game $game -WorkRoot (Join-Path $WorkRoot 'run') -DataRoot $DataRoot -Executables $executables
}
if (-not $NoDemo) {
  $doomDir = RunDir 'Doom' @{ 'Doom32.exe' = (Join-Path $Root 'bin\Doom\Doom32.exe'); 'GLDoom32.exe' = (Join-Path $Root 'bin\Doom\GLDoom32.exe') }
  $expected = @{ 'demo1' = 5026; 'demo2' = 3836; 'demo3' = 2134 }
  foreach ($d in 'demo1', 'demo2', 'demo3') {
    $text = (& powershell -NoProfile -File $runner -Exe (Join-Path $doomDir 'Doom32.exe') -Arguments "-iwad DOOM1.WAD -timedemo $d -nosound -nomusic" -WorkDir $doomDir -Seconds 900 -StopWhenExited | Out-String)
    $log = Get-ChildItem $doomDir -Recurse -Filter '*stdout*.txt' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
    $line = if ($log) { (Get-Content $log.FullName | Select-String 'timed (\d+) gametics' | Select-Object -Last 1) } else { $null }
    $got = if ($line -and ($line.Line -match 'timed (\d+) gametics')) { [int]$Matches[1] } else { -1 }
    Check (($got -eq $expected[$d]) -and ($text -notmatch 'crash=True')) ("Doom32 {0}: {1} gametic (attesi {2})" -f $d, $got, $expected[$d])
  }
  $launches = @(
    @('Doom', 'GLDoom32.exe', '-iwad DOOM1.WAD -warp 1 1'),
    @('Heretic', 'Heretic32.exe', '-iwad HERETIC1.WAD -warp 1 1'), @('Heretic', 'GLHeretic32.exe', '-iwad HERETIC1.WAD -warp 1 1'),
    @('Hexen', 'Hexen32.exe', '-iwad HEXEN.WAD -warp 1'), @('Hexen', 'GLHexen32.exe', '-iwad HEXEN.WAD -warp 1'),
    @('Strife', 'Strife32.exe', '-iwad STRIFE0.WAD -warp 32'), @('Strife', 'GLStrife32.exe', '-iwad STRIFE0.WAD -warp 32')
  )
  foreach ($l in $launches) {
    $dir = if ($l[0] -eq 'Doom') { $doomDir } else {
      $folder = (Get-ParityGames)[$l[0]].Folder
      RunDir $l[0] @{ ($l[1]) = (Join-Path $Root ("bin\$folder\" + $l[1])) } }
    if ($l[0] -ne 'Doom') {
      # i GL stanno accanto al gioco software: la cartella di lavoro li prende dalla stessa tabella
      $exeSource = Join-Path $Root ("bin\{0}\{1}" -f (Get-ParityGames)[$l[0]].Folder, $l[1])
      Copy-Item $exeSource (Join-Path $dir $l[1]) -Force
    }
    $text = (& powershell -NoProfile -File $runner -Exe (Join-Path $dir $l[1]) -Arguments ($l[2] + ' -nosound -nomusic') -WorkDir $dir -Seconds 20 | Out-String)
    Check (($text -match 'alive=True') -and ($text -notmatch 'crash=True')) ("avvio {0}: {1}" -f $l[1], ($text.Trim() -replace '\s+', ' '))
  }
}

# --- 6. golden -----------------------------------------------------------------------------------------------
if (-not $NoGolden) {
  $exeMap = "Doom=$Root\bin\Doom\Doom32.exe;Heretic=$Root\bin\Heretic\Heretic32.exe;Hexen=$Root\bin\Hexen\Hexen32.exe;Strife=$Root\bin\Strife\Strife32.exe"
  foreach ($mode in '8', '32') {
    $out = & powershell -NoProfile -File (Join-Path $Root 'Tools\Verifica\185\Confronta-Golden.ps1') -Modes $mode `
      -Exe $exeMap -DataRoot $DataRoot -WorkRoot (Join-Path $WorkRoot 'golden') 2>&1 | Out-String
    $summary = [regex]::Match($out, 'uguali:\s*(\d+)\s+diverse:\s*(\d+)')
    $equal = if ($summary.Success) { [int]$summary.Groups[1].Value } else { -1 }
    $different = if ($summary.Success) { [int]$summary.Groups[2].Value } else { -1 }
    Check (($equal -eq 44) -and ($different -eq 0)) ("golden modo {0}: uguali {1}, diverse {2}" -f $mode, $equal, $different)
    if ($different -ne 0) {
      foreach ($l in ($out -split "`r?`n" | Where-Object { $_ -and ($_ -notmatch 'UGUALE$') -and ($_ -notmatch '^---') } | Select-Object -First 6)) {
        Say ("         " + $l.Substring(0, [Math]::Min(230, $l.Length)))
      }
    }
  }
}

$minutes = [int]((Get-Date) - $started).TotalMinutes
Say ("--- controlli falliti: {0}  (durata {1} min)" -f $failed, $minutes)
Set-Content -Path $Report -Value ($lines -join "`r`n") -Encoding UTF8
Say "Riepilogo scritto in $Report"
if ($failed -gt 0) { exit 1 }
