<#
  Issue #40: gli eseguibili a 64 bit devono dare lo stesso stato e gli stessi fotogrammi di quelli a 32 bit.
  Per ogni voce del corpus della parita' (Tools\Verifica\185\Corpus.psd1) e per ogni modo (8, 32):
    1. si esegue il nuovo (di solito Win64) e si confrontano le impronte con i golden (fatti a Win32);
    2. se differiscono, si esegue il riferimento (Win32) NELLO STESSO AMBIENTE (stessa cartella, stesso nome
       dell'eseguibile, stessa riga di comando) e si confrontano le due esecuzioni tra loro.
  Il passo 2 serve perche' alcune voci non riproducono il golden nemmeno a Win32 fuori dall'ambiente in cui il
  golden e' stato registrato (il renderer legge a volte un byte fuori da un buffer e cio' che trova dipende da
  dove stanno i blocchi di memoria: docs\PARITA_MOTORE.md, "Limiti noti").

  Esiti per voce: UGUALE AL GOLDEN, UGUALE A WIN32 (il golden non si riproduce nemmeno con il riferimento),
  DIVERSO (con la prima differenza). Esce con 1 se c'e' almeno un DIVERSO o un'esecuzione fallita.

  Uso:
    powershell -NoProfile -File Tools\Verifica\40\Confronta-Bitness.ps1 [-Game Doom] [-Name 'd1_*'] [-Modes 8] `
      -Exe "Doom=<Win64>\Doom32.exe;Heretic=..." -RefExe "Doom=<Win32>\Doom32.exe;Heretic=..." [-WorkRoot C:\ddparity]
  (con "powershell -File" un solo modo per invocazione)
#>
param(
  [string[]]$Game = @(),
  [string]$Name = '*',
  [int[]]$Modes = @(8, 32),
  [string]$WorkRoot = 'C:\ddparity',
  [string]$DataRoot = '',
  [Parameter(Mandatory = $true)][object]$Exe,
  [Parameter(Mandatory = $true)][object]$RefExe,
  [string]$GoldenDir = ''
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$RefExe = ConvertTo-ParityMap $RefExe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
if ($GoldenDir -eq '') { $GoldenDir = Join-Path $root 'Tests\Data\Parity' }
$games = Get-ParityGames
$tool = Get-ParityTool
$golden = 0; $sameAsRef = 0; $different = 0

foreach ($gameName in $games.Keys) {
  $mine = @(Get-ParityCorpus -Game $Game -Name $Name | Where-Object { $_.Game -eq $gameName })
  if ($mine.Count -eq 0) { continue }
  if (-not $Exe[$gameName] -or -not $RefExe[$gameName]) { throw "Mancano -Exe o -RefExe per $gameName" }
  $newSource = (Resolve-Path $Exe[$gameName]).Path
  $refSource = (Resolve-Path $RefExe[$gameName]).Path
  # un solo nome per i due eseguibili: il nome fa parte della riga di comando
  $exeName = 'parity_' + $games[$gameName].Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{}
  $target = Join-Path $dir $exeName
  foreach ($entry in $mine) {
    foreach ($mode in $Modes) {
      $label = "{0,-8} {1,-14} modo {2,2}" -f $gameName, $entry.Name, $mode
      $newState = Join-Path $dir ("{0}.b{1}.new.state.txt" -f $entry.Short, $mode)
      $newFrame = Join-Path $dir ("{0}.b{1}.new.f.txt" -f $entry.Short, $mode)
      Copy-Item $newSource $target -Force
      $run = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $exeName -StateFile $newState -FrameFile $newFrame
      if ($run.Alive -or $run.Crash -or -not (Test-Path $newState) -or -not (Test-Path $newFrame)) {
        Write-Output "$label : ESECUZIONE FALLITA ($($run.Text))"
        $different++
        continue
      }
      $stateResult = (& $tool compare (Join-Path $GoldenDir ("{0}\{1}.state.gz" -f $gameName, $entry.Name)) $newState) | Out-String
      $frameResult = (& $tool compare (Join-Path $GoldenDir ("{0}\{1}.f{2}.gz" -f $gameName, $entry.Name, $mode)) $newFrame) | Out-String
      if (($stateResult -match 'EQUAL') -and ($frameResult -match 'EQUAL')) {
        $golden++
        Write-Output "$label : UGUALE AL GOLDEN"
        Remove-Item $newState, $newFrame -ErrorAction SilentlyContinue
        continue
      }
      $refState = Join-Path $dir ("{0}.b{1}.ref.state.txt" -f $entry.Short, $mode)
      $refFrame = Join-Path $dir ("{0}.b{1}.ref.f.txt" -f $entry.Short, $mode)
      Copy-Item $refSource $target -Force
      $run = Invoke-ParityEntry -Entry $entry -Mode $mode -RunDir $dir -ExeName $exeName -StateFile $refState -FrameFile $refFrame
      if ($run.Alive -or $run.Crash -or -not (Test-Path $refState) -or -not (Test-Path $refFrame)) {
        Write-Output "$label : ESECUZIONE DEL RIFERIMENTO FALLITA ($($run.Text))"
        $different++
        continue
      }
      $stateResult = (& $tool compare $refState $newState) | Out-String
      $frameResult = (& $tool compare $refFrame $newFrame) | Out-String
      if (($stateResult -match 'EQUAL') -and ($frameResult -match 'EQUAL')) {
        $sameAsRef++
        Write-Output "$label : UGUALE A WIN32 (il golden non si riproduce nemmeno con il riferimento in questo ambiente)"
        Remove-Item $newState, $newFrame, $refState, $refFrame -ErrorAction SilentlyContinue
      } else {
        $different++
        if ($stateResult -notmatch 'EQUAL') { Write-Output "$label : DIVERSO, STATO $($stateResult.Trim())" }
        if ($frameResult -notmatch 'EQUAL') { Write-Output "$label : DIVERSO, FOTOGRAMMA $($frameResult.Trim())" }
      }
    }
  }
}
Write-Output ("--- uguali al golden: {0}  uguali a Win32: {1}  diversi: {2}" -f $golden, $sameAsRef, $different)
if ($different -gt 0) { exit 1 }
