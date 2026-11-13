<#
  Issue #185, fase 0: rilancia l'eseguibile dato su ogni voce del corpus e confronta le impronte con i golden di
  Tests\Data\Parity\<Gioco>\ (Registra-Golden.ps1). Per ogni voce e modo dice UGUALE oppure la PRIMA differenza:
  gioco, demo, modo, tic e quali impronte (mobj, sector, side, line, player, scalari; o full, view, hud per i fotogrammi).

  Con -RefExe (un eseguibile fatto dal commit dei golden, con gli strumenti) la differenza si localizza:
    - stato: si rilanciano i due eseguibili con -statehash-detail sul tic della differenza e si dice il campo
      (categoria, indice dell'oggetto, nome del campo: per esempio "mobj 12 momz");
    - fotogramma: si scaricano i due fotogrammi del tic (-framedump) e si dice quanti pixel sono diversi, dove, e
      dove stanno i due file BMP.

  Con -ExtraIni 'chiave=valore;chiave=valore' (per esempio 'drawfps=1;drawcrosshair=1;screenblocks=8') la configurazione
  delle esecuzioni cambia (le chiavi si aggiungono o sostituiscono quelle di partenza): i golden non valgono piu', quindi
  si rilanciano **vecchio (-RefExe) e nuovo (-Exe)** con la stessa configurazione e si confrontano tra loro (stato e
  fotogrammi). -RefExe e' obbligatorio. Serve a coprire i rami che la configurazione dei golden non esercita.

  Esce con 0 se tutto e' uguale, 1 se c'e' almeno una differenza o un'esecuzione fallita.

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Confronta-Golden.ps1 [-Game Doom] [-Name 'd1_*'] [-Modes 8,32] [-NoFrames]
      [-Exe @{ Doom = 'percorso\Doom32.exe' }] [-RefExe @{ Doom = 'percorso\Doom32_rif.exe' }]
      [-ExtraIni 'drawfps=1;screenblocks=8']
      [-WorkRoot <cartella>] [-DataRoot <bin con i WAD>] [-GoldenDir <cartella>]
  Con piu' modi passare un solo -Modes per volta o una lista nello stesso processo (-Modes 8,32 da dentro PowerShell;
  da "powershell -File" la virgola non separa: usare una modalita' per invocazione).
#>
param(
  [string[]]$Game = @(),
  [string]$Name = '*',
  [int[]]$Modes = @(8, 32),
  [switch]$NoFrames,
  [string]$WorkRoot = 'C:\ddparity',
  [string]$DataRoot = '',
  [object]$Exe = @{},
  [object]$RefExe = @{},
  [string]$GoldenDir = '',
  [string]$ExtraIni = '',
  [string]$ExtraArgs = ''
)
. (Join-Path $PSScriptRoot 'Parity-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$RefExe = ConvertTo-ParityMap $RefExe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
if ($GoldenDir -eq '') { $GoldenDir = Join-Path $root 'Tests\Data\Parity' }
$games = Get-ParityGames
$tool = Get-ParityTool
$different = 0
$equal = 0

# una riproduzione con opzioni in piu' (dettaglio dello stato o scarico di un fotogramma)
function Invoke-ParityExtra {
  param($Entry, [int]$Mode, [string]$Dir, [string]$ExeName, [string]$Extra, [string]$Tag)
  $null = Invoke-ParityEntry -Entry $Entry -Mode $Mode -RunDir $Dir -ExeName $ExeName `
    -StateFile (Join-Path $Dir "$Tag.state.txt") -FrameFile (Join-Path $Dir "$Tag.frame.txt") -Extra $Extra
}

foreach ($gameName in $games.Keys) {
  $mine = @(Get-ParityCorpus -Game $Game -Name $Name | Where-Object { $_.Game -eq $gameName })
  if ($mine.Count -eq 0) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path $root ("bin\{0}\{1}" -f $games[$gameName].Folder, $games[$gameName].Exe) }
  $exeName = 'parity_' + $games[$gameName].Exe
  $executables = @{ $exeName = $source }
  $refName = 'parity_ref_' + $games[$gameName].Exe
  if ($RefExe[$gameName]) { $executables[$refName] = $RefExe[$gameName] }
  $extraLines = @($ExtraIni -split ';' | Where-Object { $_ -ne '' })
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables $executables -ExtraIni $extraLines

  if ($extraLines.Count -gt 0 -or $ExtraArgs -ne '') {
    # vecchio contro nuovo con la stessa configurazione: niente golden
    if (-not $RefExe[$gameName]) { throw "-ExtraIni richiede -RefExe per $gameName (il vecchio eseguibile da confrontare)" }
    foreach ($entry in $mine) {
      foreach ($mode in $Modes) {
        $label = "{0,-8} {1,-14} modo {2,2} [extra]" -f $gameName, $entry.Name, $mode
        $refState = Join-Path $dir ("{0}.x{1}.ref.state.txt" -f $entry.Short, $mode)
        $refFrame = Join-Path $dir ("{0}.x{1}.ref.f.txt" -f $entry.Short, $mode)
        $newState = Join-Path $dir ("{0}.x{1}.new.state.txt" -f $entry.Short, $mode)
        $newFrame = Join-Path $dir ("{0}.x{1}.new.f.txt" -f $entry.Short, $mode)
        $runRef = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $refName -StateFile $refState -FrameFile $refFrame -Extra $ExtraArgs
        $runNew = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $exeName -StateFile $newState -FrameFile $newFrame -Extra $ExtraArgs
        $failed = $null
        foreach ($pair in @(@($runRef, $refState, 'vecchio'), @($runNew, $newState, 'nuovo'))) {
          if ($pair[0].Alive -or $pair[0].Crash -or -not (Test-Path $pair[1])) { $failed = "$($pair[2]): $($pair[0].Text)" }
        }
        if ($failed) { Write-Output "$label : ESECUZIONE FALLITA ($failed)"; $different++; continue }
        $problem = $false
        $result = (& $tool compare $refState $newState) | Out-String
        if ($result -notmatch 'EQUAL') { $problem = $true; Write-Output "$label : STATO $($result.Trim())" }
        if (-not $NoFrames) {
          $result = (& $tool compare $refFrame $newFrame) | Out-String
          if ($result -notmatch 'EQUAL') { $problem = $true; Write-Output "$label : FOTOGRAMMA $($result.Trim())" }
        }
        if ($problem) { $different++ } else { $equal++; Write-Output "$label : UGUALE" }
      }
    }
    continue
  }

  foreach ($entry in $mine) {
    $goldenState = Join-Path $GoldenDir ("{0}\{1}.state.gz" -f $gameName, $entry.Name)
    foreach ($mode in $Modes) {
      $label = "{0,-8} {1,-14} modo {2,2}" -f $gameName, $entry.Name, $mode
      $stateFile = Join-Path $dir ("{0}.cmp{1}.state.txt" -f $entry.Short, $mode)
      $frameFile = Join-Path $dir ("{0}.cmp{1}.f.txt" -f $entry.Short, $mode)
      $run = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $exeName -StateFile $stateFile -FrameFile $frameFile
      if ($run.Alive -or $run.Crash -or -not (Test-Path $stateFile)) {
        Write-Output "$label : ESECUZIONE FALLITA ($($run.Text))"
        $different++
        continue
      }
      $problem = $false
      $result = (& $tool compare $goldenState $stateFile) | Out-String
      if ($result -notmatch 'EQUAL') {
        $problem = $true
        Write-Output "$label : STATO $($result.Trim())"
        if (($result -match '\(tic (\d+)\)') -and $RefExe[$gameName]) {
          $tic = [int]$Matches[1]
          $first = [Math]::Max(0, $tic - 1)
          foreach ($which in @(@($refName, 'ref'), @($exeName, 'new'))) {
            Invoke-ParityExtra -Entry $entry -Mode $mode -Dir $dir -ExeName $which[0] -Tag ("det_" + $which[1]) -Extra "-statehash-detail $first $tic"
          }
          $detail = (& $tool compare (Join-Path $dir 'det_ref.state.txt') (Join-Path $dir 'det_new.state.txt')) | Out-String
          Write-Output "      localizzazione: $($detail.Trim())"
        }
      }
      if (-not $NoFrames) {
        $goldenFrame = Join-Path $GoldenDir ("{0}\{1}.f{2}.gz" -f $gameName, $entry.Name, $mode)
        $result = (& $tool compare $goldenFrame $frameFile) | Out-String
        if ($result -notmatch 'EQUAL') {
          $problem = $true
          Write-Output "$label : FOTOGRAMMA $($result.Trim())"
          if (($result -match '\(tic (\d+)\)') -and $RefExe[$gameName]) {
            $tic = [int]$Matches[1]
            foreach ($which in @(@($refName, 'ref'), @($exeName, 'new'))) {
              Invoke-ParityExtra -Entry $entry -Mode $mode -Dir $dir -ExeName $which[0] -Tag ("dump_" + $which[1]) -Extra "-framedump $tic $(Join-Path $dir ('dump_' + $which[1] + '.bmp'))"
            }
            $bmp = [ParityBitmapCompare]::Compare((Join-Path $dir 'dump_ref.bmp'), (Join-Path $dir 'dump_new.bmp'))
            Write-Output "      localizzazione: fotogramma del tic ${tic}: $bmp (file: $dir\dump_ref.bmp e dump_new.bmp)"
          }
        }
      }
      if ($problem) { $different++ } else { $equal++; Write-Output "$label : UGUALE" }
    }
  }
}
Write-Output ("--- uguali: {0}  diverse: {1}" -f $equal, $different)
if ($different -gt 0) { exit 1 }
