<#
  Issue #185, fase 0: registra i golden di parita' con l'eseguibile dato. Per ogni voce del corpus (Corpus.psd1) e per
  ogni modo (8 e 32 bit) riproduce la demo con -timedemo -noblit -statehash -framehash (configurazione fissa
  p8.ini / p32.ini, orologio virtuale, input chiuso) e salva compressi (gzip) in Tests\Data\Parity\<Gioco>\:
    <Nome>.state.gz   un'impronta dello stato per tic (uguale nei due modi: si controlla)
    <Nome>.f8.gz      un'impronta del fotogramma per fotogramma, modo a 8 bit
    <Nome>.f32.gz     idem a 32 bit
  e un riepilogo golden.csv per gioco (tic, fotogrammi, byte, secondi). Le demo registrate col pilota automatico
  stanno in Tests\Data\Parity\<Gioco>\<Nome>.lmp (Registra-Demo.ps1).

  IMPORTANTE: i golden sono il comportamento del codice di partenza: si registrano con un eseguibile fatto dal
  commit di partenza della fase che si sta per fare (piu' gli strumenti di parita'), MAI con quello che si vuole provare.

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Registra-Golden.ps1 [-Game Doom,Heretic] [-Name 'd1_*'] [-Modes 8,32]
      [-WorkRoot <cartella>] [-DataRoot <bin con i WAD>] [-Exe @{ Doom = 'percorso\Doom32.exe' }] [-OutDir <cartella>]
#>
param(
  [string[]]$Game = @(),
  [string]$Name = '*',
  [int[]]$Modes = @(8, 32),
  [string]$WorkRoot = 'C:\ddparity',
  [string]$DataRoot = '',
  [object]$Exe = @{},
  [string]$OutDir = ''
)
. (Join-Path $PSScriptRoot 'Parity-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
if ($OutDir -eq '') { $OutDir = Join-Path $root 'Tests\Data\Parity' }
$games = Get-ParityGames
$tool = Get-ParityTool
$problems = 0

foreach ($gameName in $games.Keys) {
  $mine = @(Get-ParityCorpus -Game $Game -Name $Name | Where-Object { $_.Game -eq $gameName })
  if ($mine.Count -eq 0) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path $root ("bin\{0}\{1}" -f $games[$gameName].Folder, $games[$gameName].Exe) }
  $exeName = 'parity_' + $games[$gameName].Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{ $exeName = $source }
  $target = Join-Path $OutDir $gameName
  New-Item -ItemType Directory -Force $target | Out-Null
  $csv = New-Object System.Collections.Generic.List[string]
  $csv.Add('name;tics;frames8;frames32;bytes;seconds')

  foreach ($entry in $mine) {
    $state = Join-Path $dir ($entry.Short + '.state.txt')
    $stateFirst = ''
    $tics = 0; $frames = @{ 8 = 0; 32 = 0 }; $bytes = 0; $seconds = 0
    foreach ($mode in $Modes) {
      $frameFile = Join-Path $dir ("{0}.f{1}.txt" -f $entry.Short, $mode)
      $stateFile = Join-Path $dir ("{0}.state{1}.txt" -f $entry.Short, $mode)
      $run = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $exeName -StateFile $stateFile -FrameFile $frameFile
      $seconds += $run.Seconds
      if ($run.Alive -or $run.Crash -or -not (Test-Path $stateFile)) {
        Write-Output ("{0,-8} {1,-14} modo {2}: ESECUZIONE FALLITA ({3})" -f $gameName, $entry.Name, $mode, $run.Text)
        $problems++
        continue
      }
      if ($stateFirst -eq '') {
        $stateFirst = $stateFile
        $tics = [int](& $tool count $stateFile)
        $packed = Join-Path $target ($entry.Name + '.state.gz')
        & $tool pack $stateFile $packed
        $bytes += (Get-Item $packed).Length
      } else {
        $same = (& $tool compare $stateFirst $stateFile) | Out-String
        if ($same -notmatch 'EQUAL') {
          Write-Output ("{0,-8} {1,-14} lo stato del modo {2} e' DIVERSO da quello del primo modo: {3}" -f $gameName, $entry.Name, $mode, $same.Trim())
          $problems++
        }
      }
      $frames[$mode] = [int](& $tool count $frameFile)
      $packed = Join-Path $target ("{0}.f{1}.gz" -f $entry.Name, $mode)
      & $tool pack $frameFile $packed
      $bytes += (Get-Item $packed).Length
    }
    $csv.Add(('{0};{1};{2};{3};{4};{5}' -f $entry.Name, $tics, $frames[8], $frames[32], $bytes, $seconds))
    Write-Output ("{0,-8} {1,-14} tic={2,5} fotogrammi8={3,5} fotogrammi32={4,5} golden={5,7} byte  {6,4} s" -f
      $gameName, $entry.Name, $tics, $frames[8], $frames[32], $bytes, $seconds)
  }
  # il riepilogo unisce le righe vecchie (voci non rifatte) e le nuove
  $csvFile = Join-Path $target 'golden.csv'
  $old = @{}
  if (Test-Path $csvFile) { foreach ($row in (Get-Content $csvFile | Select-Object -Skip 1)) { $old[($row -split ';')[0]] = $row } }
  foreach ($row in ($csv | Select-Object -Skip 1)) { $old[($row -split ';')[0]] = $row }
  $out = @($csv[0]) + @($old.Keys | Sort-Object | ForEach-Object { $old[$_] })
  [IO.File]::WriteAllLines($csvFile, $out)
}
if ($problems -gt 0) { Write-Output "$problems problemi"; exit 1 }
