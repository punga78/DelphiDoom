<#
  Issue #40 (sotto-issue #43): i golden di STATO della parita' (Tests\Data\Parity\<Gioco>\*.state.gz) rifatti con
  l'eseguibile dato, senza il lock globale dei giochi.

  E' il confronto di stato di Tools\Verifica\185\Confronta-Golden.ps1 (stessa riga di comando delle voci del corpus,
  stesso ParityTool compare) per le macchine cariche, dove il lock di Tools\Esegui-gioco.ps1 e la priorita' bassa
  fanno scadere le esecuzioni: qui i giochi partono uno per volta a priorita' normale. Solo lo stato (i fotogrammi
  non c'entrano coi salvataggi): con -Small la finestra e' 320x200, che non cambia lo stato e dimezza i tempi; una
  voce che risultasse diversa va rifatta senza -Small e poi con Confronta-Golden.ps1.

  Uso (dalla radice del repository):
    powershell -NoProfile -File Tools\Verifica\40\Confronta-Stato.ps1 [-Game Doom,Hexen] [-Name 'd1_*'] [-Small]
       [-Exe "Doom=...;..."] [-DataRoot <bin coi WAD>] [-WorkRoot C:\ddsave40\golden]
  Codice di uscita: 0 se tutte le voci sono uguali ai golden, 1 altrimenti.
#>
param(
  [string[]]$Game = @(),
  [string]$Name = '*',
  $Exe = @{},
  [string]$DataRoot = '',
  [string]$WorkRoot = 'C:\ddsave40\golden',
  [switch]$Small
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
. (Join-Path $PSScriptRoot 'Salvataggi-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
$goldenDir = Join-Path $root 'Tests\Data\Parity'
$games = Get-ParityGames
$tool = Get-ParityTool
$extraIni = @()
if ($Small) { $extraIni = @('soft_screenwidth=320', 'soft_screenheight=200') }
$equal = 0; $different = 0
foreach ($gameName in $games.Keys) {
  $mine = @(Get-ParityCorpus -Game $Game -Name $Name | Where-Object { $_.Game -eq $gameName })
  if ($mine.Count -eq 0) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path (Get-ParityBin $games[$gameName].Folder) $games[$gameName].Exe }
  $exeName = 'parity_' + $games[$gameName].Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{ $exeName = $source } -ExtraIni $extraIni
  foreach ($entry in $mine) {
    $demo = $entry.Demo
    $extra = ''
    if ($entry.ContainsKey('Auto')) {
      $demo = $entry.Short
      if ($entry.Game -eq 'Hexen') { $extra = ' -devparm' }
      Copy-Item (Join-Path $root ("Tests\Data\Parity\{0}\{1}.lmp" -f $entry.Game, $entry.Name)) (Join-Path $dir ($demo + '.lmp')) -Force
    }
    $state = Join-Path $dir 'ps.txt'
    Remove-Item $state, (Join-Path $dir 'pf.txt') -ErrorAction SilentlyContinue
    # la stessa riga di comando di Invoke-ParityEntry
    $arguments = "-iwad $($entry.Iwad) -config p8.ini -dontsavedefaults -nomusic -nosound -noblit -timedemo $demo -statehash ps.txt -framehash pf.txt$extra"
    $run = Invoke-SaveRun -Exe (Join-Path $dir $exeName) -Arguments $arguments -WorkDir $dir -TimeoutSeconds 900 -NoLock
    $label = "{0,-8} {1,-14}" -f $gameName, $entry.Name
    if ($run.Alive -or $run.Crash -or -not (Test-Path $state)) { Write-Output "$label : ESECUZIONE FALLITA"; $different++; continue }
    $golden = Join-Path $goldenDir ("{0}\{1}.state.gz" -f $gameName, $entry.Name)
    $result = (& $tool compare $golden $state) | Out-String
    if ($result -match 'EQUAL') { $equal++; Write-Output "$label : UGUALE" }
    else { $different++; Write-Output "$label : STATO $($result.Trim())" }
  }
}
Write-Output "$equal voci uguali ai golden, $different diverse o fallite"
if ($different -gt 0) { exit 1 }
exit 0
