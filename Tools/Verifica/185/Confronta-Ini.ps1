<#
  Fetta 1c della issue #185 (la famiglia m_*): il file .ini scritto dal vecchio e dal nuovo eseguibile deve essere
  uguale byte per byte. Per ogni gioco e per ogni configurazione di prova:
    1. prepara due copie identiche del file (intestazione del .ini vero del gioco in bin\<Gioco> + il corpo di
       Tests\Data\Configuration\Fetta1c\<Gioco>.body.ini: valori fuori intervallo, chiavi sconosciute, nomi ripetuti,
       maiuscole, esadecimali, caratteri tra apici, righe senza "=");
    2. lancia il vecchio sulla prima e il nuovo sulla seconda con la prima demo del corpus (-timedemo, che finisce con
       I_Quit e quindi salva la configurazione: niente -dontsavedefaults);
    3. confronta i due file scritti, e il numero di gametic della riga "timed".
  Con -DefaultValues il file indicato da -config non esiste: il motore parte dai valori di partenza di ogni voce e li scrive
  all'uscita (e' la prova "valore di partenza di ogni voce"). Non si usa l'opzione -defaultvalues del motore: con lei
  TEngineDefaults.Load esce prima di ricordare il nome del file e all'uscita non scrive niente (vecchio e nuovo uguali).

  Uso (riferimento: master 63a151cc):
    powershell -NoProfile -File Tools\Verifica\185\Confronta-Ini.ps1 `
      -Exe    "Doom=<nuovo>\Doom32.exe;Heretic=<nuovo>\Heretic32.exe;Hexen=<nuovo>\Hexen32.exe;Strife=<nuovo>\Strife32.exe" `
      -RefExe "Doom=<rif>\Doom32.exe;Heretic=<rif>\Heretic32.exe;Hexen=<rif>\Hexen32.exe;Strife=<rif>\Strife32.exe" `
      [-DefaultValues] [-WorkRoot C:\ddparity_1c] [-DataRoot C:\Progetti\DelphiDoom\bin]

  Scritto senza poterlo eseguire (cambio di processo della fetta 1c: le esecuzioni dei giochi le fa l'agente di
  verifica): se una riga non funziona va corretta qui.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$RefExe,
  [switch]$DefaultValues,
  [string]$WorkRoot = 'C:\ddparity_1c',
  [string]$DataRoot = ''
)
. (Join-Path $PSScriptRoot 'Parity-Common.ps1')
$games = Get-ParityGames
$root = Get-ParityRoot
$newMap = ConvertTo-ParityMap $Exe
$refMap = ConvertTo-ParityMap $RefExe
$data = Get-ParityDataRoot $DataRoot
$failures = 0

foreach ($gameName in $games.Keys) {
  if (-not $newMap[$gameName] -or -not $refMap[$gameName]) { continue }
  $info = $games[$gameName]
  $exeName = 'ini_new_' + $info.Exe
  $refName = 'ini_ref_' + $info.Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot `
    -Executables @{ $exeName = $newMap[$gameName]; $refName = $refMap[$gameName] }
  $entry = @(Get-ParityCorpus -Game $gameName)[0]
  $demo = $entry.Demo
  if ($entry.ContainsKey('Auto')) {
    $demo = $entry.Short
    Copy-Item (Join-Path $root ("Tests\Data\Parity\{0}\{1}.lmp" -f $gameName, $entry.Name)) (Join-Path $dir ($demo + '.lmp')) -Force
  }
  $header = Get-Content (Join-Path (Join-Path $data $info.Folder) $info.Ini) -TotalCount 1
  $body = [IO.File]::ReadAllText((Join-Path $root "Tests\Data\Configuration\Fetta1c\$gameName.body.ini"))
  $text = $header + "`r`n" + $body
  $results = @{}
  foreach ($side in 'ref', 'new') {
    $ini = "c1c_$side.ini"
    Remove-Item (Join-Path $dir $ini) -ErrorAction SilentlyContinue
    if (-not $DefaultValues) { [IO.File]::WriteAllText((Join-Path $dir $ini), $text) }
    $extra = ''
    if ($gameName -eq 'Hexen') { $extra = ($extra + ' -devparm').Trim() }
    $name = if ($side -eq 'ref') { $refName } else { $exeName }
    $arguments = "-iwad $($entry.Iwad) -config $ini -nomusic -nosound -noblit -timedemo $demo $extra"
    $run = Invoke-ParityGame -Exe (Join-Path $dir $name) -Arguments $arguments -WorkDir $dir -TimeoutSeconds 600
    $results[$side] = [pscustomobject]@{ Run = $run; File = (Join-Path $dir $ini) }
  }
  $refBytes = @(); $newBytes = @()
  if (Test-Path $results['ref'].File) { $refBytes = [IO.File]::ReadAllBytes($results['ref'].File) }
  if (Test-Path $results['new'].File) { $newBytes = [IO.File]::ReadAllBytes($results['new'].File) }
  $same = ($refBytes.Length -eq $newBytes.Length)
  if ($same) { for ($i = 0; $i -lt $refBytes.Length; $i++) { if ($refBytes[$i] -ne $newBytes[$i]) { $same = $false; break } } }
  $written = (Test-Path $results['ref'].File) -and (Test-Path $results['new'].File)
  if ($written -and -not $DefaultValues) { $written = -not ([IO.File]::ReadAllText($results['ref'].File) -eq $text) }
  $label = "{0,-8} {1}" -f $gameName, $(if ($DefaultValues) { 'valori di partenza' } else { 'file di prova' })
  if ($results['ref'].Run.Crash -or $results['new'].Run.Crash -or $results['ref'].Run.Alive -or $results['new'].Run.Alive) {
    Write-Output "$label : ESECUZIONE NON RIUSCITA | vecchio: $($results['ref'].Run.Text) | nuovo: $($results['new'].Run.Text)"
    $failures++
  } elseif (-not $written) {
    Write-Output "$label : il vecchio non ha riscritto il file (I_Quit non e' stato raggiunto?)"
    $failures++
  } elseif ($same) {
    Write-Output "$label : UGUALE ($($refBytes.Length) byte)"
  } else {
    $refLines = Get-Content $results['ref'].File
    $newLines = Get-Content $results['new'].File
    $first = 0
    while ($first -lt [Math]::Min($refLines.Count, $newLines.Count) -and $refLines[$first] -eq $newLines[$first]) { $first++ }
    Write-Output "$label : DIVERSO alla riga $($first + 1): vecchio '$($refLines[$first])' nuovo '$($newLines[$first])'"
    $failures++
  }
}
exit $failures
