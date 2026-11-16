<#
  Issue #247, fetta 5: prova che R_SetRenderingFunctions (ora una tabella) da' le stesse funzioni del vecchio testo.

  L'eseguibile, con DDPARITY_RENDERFUNCTIONS=<file> e le opzioni di parita', dopo il primo tic chiama la procedura
  per ogni livello di dettaglio (6) e per ogni combinazione dei flag che il vecchio testo leggeva (usemultithread,
  diher8bittransparency, fuzz, nebbia di Hexen), e scrive per ogni combinazione il NOME della funzione che ogni variabile ha
  ricevuto (DelphiDoom.Engine.Renderer.FunctionDump, generata dal testo storico). Il file e' confrontato con il golden
  Tests\Data\Renderer\RenderFunctions\<Gioco>.rf.gz, prodotto dal VECCHIO testo prima di cancellarlo.

  Uso:
    powershell -NoProfile -File Tools\Verifica\247\Confronta-Funzioni.ps1 [-Game Doom,Hexen] [-Exe 'Doom=C:\x\Doom32.exe']
      [-WorkRoot C:\ddparity_247] [-DataRoot <bin con i WAD>] [-Registra]
  -Registra: scrive i golden (solo con un eseguibile del vecchio testo). Esce con 0 se tutto e' uguale.
#>
param(
  [string[]]$Game = @('Doom', 'Heretic', 'Hexen', 'Strife'),
  [object]$Exe = @{},
  [string]$WorkRoot = 'C:\ddparity_247',
  [string]$DataRoot = '',
  [string]$GoldenDir = '',
  [switch]$Registra
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
$Exe = ConvertTo-ParityMap $Exe
$Game = @($Game | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Get-ParityRoot
if ($GoldenDir -eq '') { $GoldenDir = Join-Path $root 'Tests\Data\Renderer\RenderFunctions' }
$games = Get-ParityGames
$demos = @{ Doom = 'd1_demo1'; Heretic = 'a_h_e1m1'; Hexen = 'a_x_map01_f'; Strife = 'a_s_map32' }
if (-not $env:DD_GAME_PRIORITY) { $env:DD_GAME_PRIORITY = 'Normal' }
$failed = 0

function Read-Gz([string]$Path) {
  $in = [IO.File]::OpenRead($Path)
  try {
    $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
    $ms = New-Object IO.MemoryStream
    $gz.CopyTo($ms)
    [Text.Encoding]::ASCII.GetString($ms.ToArray())
  } finally { $in.Dispose() }
}
function Write-Gz([string]$Path, [string]$Text) {
  New-Item -ItemType Directory -Force (Split-Path -Parent $Path) | Out-Null
  $out = [IO.File]::Create($Path)
  try {
    $gz = New-Object IO.Compression.GZipStream($out, [IO.Compression.CompressionMode]::Compress)
    $bytes = [Text.Encoding]::ASCII.GetBytes($Text)
    $gz.Write($bytes, 0, $bytes.Length)
    $gz.Dispose()
  } finally { $out.Dispose() }
}

foreach ($gameName in $games.Keys) {
  if ($Game -notcontains $gameName) { continue }
  $source = $Exe[$gameName]
  if (-not $source) { $source = Join-Path (Get-ParityBin $games[$gameName].Folder) $games[$gameName].Exe }
  $exeName = 'parity_rf_' + $games[$gameName].Exe
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{ $exeName = $source }
  $entry = @(Get-ParityCorpus -Game $gameName -Name $demos[$gameName])[0]
  $dumpFile = Join-Path $dir 'rf.txt'
  Remove-Item $dumpFile -ErrorAction SilentlyContinue
  $env:DDPARITY_RENDERFUNCTIONS = 'rf.txt'
  try {
    $run = Invoke-ParityEntry -Entry $entry -Mode 8 -RunDir $dir -ExeName $exeName -StateFile (Join-Path $dir 'rf.state.txt') -FrameFile (Join-Path $dir 'rf.frame.txt')
  } finally { Remove-Item Env:\DDPARITY_RENDERFUNCTIONS -ErrorAction SilentlyContinue }
  if ($run.Alive -or $run.Crash -or -not (Test-Path $dumpFile)) {
    Write-Output ("{0,-8} : ESECUZIONE FALLITA ({1})" -f $gameName, $run.Text)
    $failed++
    continue
  }
  $text = [IO.File]::ReadAllText($dumpFile)
  $golden = Join-Path $GoldenDir ("{0}.rf.gz" -f $gameName)
  if ($Registra) {
    Write-Gz $golden $text
    Write-Output ("{0,-8} : registrato ({1} righe) in {2}" -f $gameName, ($text -split "`n").Count, $golden)
    continue
  }
  $expected = Read-Gz $golden
  if ($expected -ceq $text) {
    Write-Output ("{0,-8} : UGUALE ({1} righe)" -f $gameName, ($text -split "`n").Count)
  } else {
    $a = $expected -split "`n"; $b = $text -split "`n"
    $n = [Math]::Min($a.Count, $b.Count)
    $first = 0
    for ($i = 0; $i -lt $n; $i++) { if ($a[$i] -cne $b[$i]) { $first = $i + 1; break } }
    Write-Output ("{0,-8} : DIVERSO alla riga {1} (golden {2} righe, nuovo {3})" -f $gameName, $first, $a.Count, $b.Count)
    if ($first -gt 0) {
      $x = $a[$first - 1].Split(' '); $y = $b[$first - 1].Split(' ')
      $onlyOld = @($x | Where-Object { $y -notcontains $_ }); $onlyNew = @($y | Where-Object { $x -notcontains $_ })
      Write-Output ("      solo nel golden: {0}" -f ($onlyOld -join ' '))
      Write-Output ("      solo nel nuovo : {0}" -f ($onlyNew -join ' '))
    }
    $failed++
  }
}
if ($failed -eq 0) { Write-Output 'FUNZIONI DI DISEGNO: tutto UGUALE' } else { Write-Output "FUNZIONI DI DISEGNO: $failed non uguali o fallite" }
exit $failed
