<#
  Issue #246: golden dell'automap del renderer software. L'automap non e' nelle demo del corpus (Corpus.psd1): qui un
  copione (-autoscript, Tests\Data\Parity\Automap\<Gioco>.script) fa camminare il giocatore, apre l'automap e passa per
  i suoi tasti (cheat di linee e cose, griglia, segni, segui, ruota, grande, i tre stati di TAB, cancella i segni).
  Ogni fotogramma e' hashato da -framehash e lo stato da -statehash; il copione fotografa anche tredici fotogrammi
  (<copione>.<n>.bmp, per guardarli). Nessuna opzione nuova nel motore: solo quelle di IdTech1\Parity.

  Tre usi:
    -Record      registra i golden da -Exe (un eseguibile del codice di partenza): Tests\Data\Parity\Automap\<Gioco>.s<modo>.gz
                 e .f<modo>.gz
    (predefinito) rilancia -Exe e confronta con i golden
    -RefExe      rilancia anche l'eseguibile di riferimento e confronta nuovo e vecchio tra loro (stessa cartella di lavoro)
    -Noise       rilancia due volte -Exe e li confronta (rumore zero)

  I golden dei fotogrammi valgono nella cartella di lavoro con cui sono stati registrati (-WorkRoot, predefinita
  C:\ddparity_246b): la lunghezza del percorso cambia la disposizione della memoria (vedi CLAUDE.md, trappola 5).

  Uso:
    powershell -NoProfile -File Tools\Verifica\246\Confronta-Automap.ps1 [-Game Doom] [-Modes 8] [-Exe 'Doom=percorso']
      [-RefExe 'Doom=percorso'] [-Record] [-Noise] [-WorkRoot C:\ddparity_246b] [-DataRoot <bin con i WAD>]
  Esce con 0 se tutto e' uguale.
#>
param(
  [string[]]$Game = @(),
  [int[]]$Modes = @(8, 32),
  [string]$WorkRoot = 'C:\ddparity_246b',
  [string]$DataRoot = '',
  [object]$Exe = @{},
  [object]$RefExe = @{},
  [switch]$Record,
  [switch]$Noise
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$RefExe = ConvertTo-ParityMap $RefExe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
$games = Get-ParityGames
$tool = Get-ParityTool
$goldenDir = Join-Path $root 'Tests\Data\Parity\Automap'
# gioco -> WAD e argomenti di partenza del livello (come le voci a_* del corpus)
$setup = @{
  Doom    = @{ Iwad = 'DOOM1.WAD'; Args = '-warp 1 1 -skill 3' }
  Heretic = @{ Iwad = 'HERETIC1.WAD'; Args = '-warp 1 1 -skill 3' }
  Hexen   = @{ Iwad = 'HEXEN.WAD'; Args = '-warp 1 -skill 3 -class 0' }
  Strife  = @{ Iwad = 'STRIFE0.WAD'; Args = '-warp 32 -skill 3' }
}
if ($env:DD_GAME_PRIORITY -eq $null) { $env:DD_GAME_PRIORITY = 'Normal' }
if (-not $env:DD_PARITY_TIMEOUT) { $env:DD_PARITY_TIMEOUT = '1800' }
$different = 0
$equal = 0

# Una esecuzione del copione: stessa riga di comando per ogni eseguibile (la lunghezza degli argomenti conta)
function Invoke-AutomapRun {
  param([string]$Dir, [string]$ExeName, [string]$GameName, [int]$Mode, [string]$StateFile, [string]$FrameFile)
  Remove-Item $StateFile, $FrameFile, (Join-Path $Dir 'ps.txt'), (Join-Path $Dir 'pf.txt') -ErrorAction SilentlyContinue
  $arguments = "-iwad $($setup[$GameName].Iwad) -config p$Mode.ini -dontsavedefaults -nomusic -nosound -noblit " +
    "$($setup[$GameName].Args) -autoscript am.script -statehash ps.txt -framehash pf.txt"
  $run = Invoke-ParityGame -Exe (Join-Path $Dir $ExeName) -Arguments $arguments -WorkDir $Dir -TimeoutSeconds ([int]$env:DD_PARITY_TIMEOUT)
  if (Test-Path (Join-Path $Dir 'ps.txt')) { Move-Item (Join-Path $Dir 'ps.txt') $StateFile -Force }
  if (Test-Path (Join-Path $Dir 'pf.txt')) { Move-Item (Join-Path $Dir 'pf.txt') $FrameFile -Force }
  $run
}

function Test-AutomapRun {
  param($Run, [string]$StateFile, [string]$FrameFile, [string]$Label)
  # a fine copione il gioco esce da solo (I_Quit): Alive = ancora vivo allo scadere del tempo
  if ($Run.Alive -or $Run.Crash -or -not (Test-Path $StateFile) -or -not (Test-Path $FrameFile)) {
    Write-Host "$Label : ESECUZIONE FALLITA ($($Run.Text))"
    return $false
  }
  $true
}

foreach ($gameName in $games.Keys) {
  if ($Game.Count -gt 0 -and $Game -notcontains $gameName) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path (Get-ParityBin $games[$gameName].Folder) $games[$gameName].Exe }
  $exeName = 'parity_' + $games[$gameName].Exe
  $refName = 'parity_ref_' + $games[$gameName].Exe
  $executables = @{ $exeName = $source }
  if ($RefExe[$gameName]) { $executables[$refName] = $RefExe[$gameName] }
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables $executables
  Copy-Item (Join-Path $goldenDir "$gameName.script") (Join-Path $dir 'am.script') -Force
  foreach ($mode in $Modes) {
    # Strife e Doom in 8 e 32 bit, Heretic e Hexen solo a 8 bit come il corpus
    if ($mode -eq 32 -and $gameName -notin 'Doom', 'Strife') { continue }
    $label = "{0,-8} automap      modo {1,2}" -f $gameName, $mode
    $newState = Join-Path $dir "new$mode.state.txt"
    $newFrame = Join-Path $dir "new$mode.f.txt"
    $run = Invoke-AutomapRun -Dir $dir -ExeName $exeName -GameName $gameName -Mode $mode -StateFile $newState -FrameFile $newFrame
    if (-not (Test-AutomapRun $run $newState $newFrame $label)) { $different++; continue }
    $stats = Get-ParityStateStats -Tool $tool -File $newState
    $goldenState = Join-Path $goldenDir "$gameName.s$mode.gz"
    $goldenFrame = Join-Path $goldenDir "$gameName.f$mode.gz"
    if ($Record) {
      & $tool pack $newState $goldenState | Out-Null
      & $tool pack $newFrame $goldenFrame | Out-Null
      Write-Output "$label : REGISTRATO ($($stats.Tics) tic)"
      continue
    }
    $problem = $false
    if ($Noise) {
      $secondState = Join-Path $dir "second$mode.state.txt"
      $secondFrame = Join-Path $dir "second$mode.f.txt"
      $run2 = Invoke-AutomapRun -Dir $dir -ExeName $exeName -GameName $gameName -Mode $mode -StateFile $secondState -FrameFile $secondFrame
      if (-not (Test-AutomapRun $run2 $secondState $secondFrame $label)) { $different++; continue }
      $refState = $secondState; $refFrame = $secondFrame
    }
    elseif ($RefExe[$gameName]) {
      $refState = Join-Path $dir "ref$mode.state.txt"
      $refFrame = Join-Path $dir "ref$mode.f.txt"
      $run2 = Invoke-AutomapRun -Dir $dir -ExeName $refName -GameName $gameName -Mode $mode -StateFile $refState -FrameFile $refFrame
      if (-not (Test-AutomapRun $run2 $refState $refFrame $label)) { $different++; continue }
    }
    else {
      $refState = $goldenState; $refFrame = $goldenFrame
    }
    $result = (& $tool compare $refState $newState) | Out-String
    if ($result -notmatch 'EQUAL') { $problem = $true; Write-Output "$label : STATO $($result.Trim())" }
    $result = (& $tool compare $refFrame $newFrame) | Out-String
    if ($result -notmatch 'EQUAL') { $problem = $true; Write-Output "$label : FOTOGRAMMA $($result.Trim())" }
    if ($problem) { $different++ } else { $equal++; Write-Output "$label : UGUALE ($($stats.Tics) tic)" }
  }
}
Write-Output "Confronti uguali: $equal, diversi o falliti: $different"
if ($different -gt 0) { exit 1 }
exit 0
