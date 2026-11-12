<#
  Issue #185, fase 0: prova del rumore zero. Esegue DUE volte lo stesso eseguibile sulla stessa demo, in ogni modo
  (8 e 32 bit), e confronta le impronte dello stato e dei fotogrammi: devono essere uguali al bit. Se non lo sono,
  gli strumenti non si possono usare (una differenza sarebbe rumore e non un cambiamento del codice).

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Rumore-Zero.ps1 [-Game Doom] [-Name 'd1_demo1'] [-Modes 8,32]
      [-Exe @{ Doom = 'percorso\Doom32.exe' }] [-WorkRoot <cartella>] [-DataRoot <bin con i WAD>]
#>
param(
  [string[]]$Game = @(),
  [string]$Name = '*',
  [int[]]$Modes = @(8, 32),
  [string]$WorkRoot = (Join-Path $env:TEMP 'ddparity'),
  [string]$DataRoot = '',
  [object]$Exe = @{}
)
. (Join-Path $PSScriptRoot 'Parity-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
$games = Get-ParityGames
$tool = Get-ParityTool
$bad = 0
$good = 0

foreach ($gameName in $games.Keys) {
  $mine = @(Get-ParityCorpus -Game $Game -Name $Name | Where-Object { $_.Game -eq $gameName })
  if ($mine.Count -eq 0) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path $root ("bin\{0}\{1}" -f $games[$gameName].Folder, $games[$gameName].Exe) }
  $exeName = 'parity_' + $games[$gameName].Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{ $exeName = $source }
  foreach ($entry in $mine) {
    foreach ($mode in $Modes) {
      $files = @()
      foreach ($n in 1, 2) {
        $state = Join-Path $dir ("{0}.noise{1}.state.txt" -f $entry.Short, $n)
        $frame = Join-Path $dir ("{0}.noise{1}.f.txt" -f $entry.Short, $n)
        $null = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $exeName -StateFile $state -FrameFile $frame
        $files += , @($state, $frame)
      }
      $s = (& $tool compare $files[0][0] $files[1][0]) | Out-String
      $f = (& $tool compare $files[0][1] $files[1][1]) | Out-String
      $tics = (& $tool count $files[0][0]); $frames = (& $tool count $files[0][1])
      if (($s -match 'EQUAL') -and ($f -match 'EQUAL') -and [int]$tics -gt 0) {
        $good++
        Write-Output ("{0,-8} {1,-14} modo {2,2}: IDENTICHE ({3} tic, {4} fotogrammi)" -f $gameName, $entry.Name, $mode, $tics, $frames)
      } else {
        $bad++
        Write-Output ("{0,-8} {1,-14} modo {2,2}: DIVERSE stato: {3} fotogrammi: {4}" -f $gameName, $entry.Name, $mode, $s.Trim(), $f.Trim())
      }
    }
  }
}
Write-Output ("--- identiche: {0}  diverse: {1}" -f $good, $bad)
if ($bad -gt 0) { exit 1 }
