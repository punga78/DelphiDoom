<#
  Issue #185, fase 0: registra con il motore stesso le demo del corpus che si fanno con il pilota automatico
  (-autodemo seme tic). La demo contiene solo ticcmd: si salva in Tests\Data\Parity\<Gioco>\<Nome>.lmp
  (nessun dato del gioco; per riprodurla servono il WAD e la mappa indicati in Corpus.psd1).

  Dopo la registrazione la demo si riproduce (-timedemo) e l'impronta dello stato della riproduzione deve
  essere uguale a quella della registrazione: e' la prova che la demo registra cio' che e' successo.

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Registra-Demo.ps1 [-Game Doom,Heretic] [-Name 'a_d1_*']
      [-WorkRoot <cartella>] [-DataRoot <bin con i WAD>] [-Exe @{ Doom = 'percorso\Doom32.exe' }] [-NoVerify]
#>
param(
  [string[]]$Game = @(),
  [string]$Name = 'a_*',
  [string]$WorkRoot = (Join-Path $env:TEMP 'ddparity'),
  [string]$DataRoot = '',
  [hashtable]$Exe = @{},
  [switch]$NoVerify
)
. (Join-Path $PSScriptRoot 'Parity-Common.ps1')
# con powershell -File una lista separata da virgole arriva come una sola stringa
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
$games = Get-ParityGames
$tool = Get-ParityTool
$entries = @(Get-ParityCorpus -Game $Game -Name $Name | Where-Object { $_.ContainsKey('Auto') })
$failed = 0

foreach ($gameName in $games.Keys) {
  $mine = @($entries | Where-Object { $_.Game -eq $gameName })
  if ($mine.Count -eq 0) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path $root ("bin\{0}\{1}" -f $games[$gameName].Folder, $games[$gameName].Exe) }
  $exeName = 'parity_' + $games[$gameName].Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{ $exeName = $source }
  $target = Join-Path $root "Tests\Data\Parity\$gameName"
  New-Item -ItemType Directory -Force $target | Out-Null

  foreach ($entry in $mine) {
    $auto = $entry.Auto
    $lmp = Join-Path $dir ($entry.Short + '.lmp')
    Remove-Item $lmp -ErrorAction SilentlyContinue
    $stateFile = Join-Path $dir ($entry.Short + '.rec.state.txt')
    $arguments = "-iwad $($entry.Iwad) -config p8.ini -dontsavedefaults -nomusic -nosound -noblit -singletics " +
      "-warp $($auto.Warp) -skill $($auto.Skill) -record $($entry.Short) -autodemo $($auto.Seed) $($auto.Tics) " +
      "-statehash $(Split-Path -Leaf $stateFile) $($auto.Extra)"
    $run = Invoke-ParityGame -Exe (Join-Path $dir $exeName) -Arguments $arguments -WorkDir $dir -TimeoutSeconds 600
    if (-not (Test-Path $lmp)) {
      Write-Output ("{0,-14} {1,-14} NON REGISTRATA ({2})" -f $gameName, $entry.Name, $run.Text)
      $failed++
      continue
    }
    Copy-Item $lmp (Join-Path $target ($entry.Name + '.lmp')) -Force
    $note = ''
    $tics = $auto.Tics
    if (-not $NoVerify) {
      $replay = Join-Path $dir ($entry.Short + '.play.state.txt')
      $frame = Join-Path $dir ($entry.Short + '.play.frame.txt')
      $null = Invoke-ParityEntry -Entry $entry -Mode 8 -RunDir $dir -ExeName $exeName -StateFile $replay -FrameFile $frame
      $result = (& $tool compare $stateFile $replay) | Out-String
      # la riproduzione ha un tic in piu' (la fine della demo): l'unica differenza ammessa e' la lunghezza
      # (e la registrazione puo' finire prima dei tic chiesti: in Hexen la morte del giocatore chiude la demo)
      $recorded = [int](& $tool count $stateFile)
      $replayed = [int](& $tool count $replay)
      if ($result -match 'EQUAL') { $note = 'riproduzione uguale' }
      elseif ($result -match 'length of the log' -and ($replayed - $recorded) -eq 1) { $note = 'riproduzione uguale (un tic in piu)' }
      else { $note = 'RIPRODUZIONE DIVERSA: ' + $result.Trim(); $failed++ }
      $tics = $recorded
    }
    $size = (Get-Item (Join-Path $target ($entry.Name + '.lmp'))).Length
    Write-Output ("{0,-8} {1,-14} {2,6} byte  tic={3}  {4}" -f $gameName, $entry.Name, $size, $tics, $note)
  }
}
if ($failed -gt 0) { Write-Output "$failed demo non registrate o non riproducibili"; exit 1 }
