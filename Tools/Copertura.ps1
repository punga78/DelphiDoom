<#
  Misura la copertura dei test di una libreria con DelphiCodeCoverage (CodeCoverage.exe).

  Uso:
    powershell -NoProfile -File Tools\Copertura.ps1 -Test Zone
    powershell -NoProfile -File Tools\Copertura.ps1 -Test IdLib.Hashing -Cartella Libs\IdLib\Hashing
    powershell -NoProfile -File Tools\Copertura.ps1 -Test Zone -SenzaCompilare
    powershell -NoProfile -File Tools\Copertura.ps1 -Tutti
    powershell -NoProfile -File Tools\Copertura.ps1 -Test Zone -SoloComando

  -Test           nome del progetto di test senza il prefisso: "Zone" = Tests\DelphiDoom.Tests.Zone,
                  "" o "Zlib" = Tests\DelphiDoom.Tests (il progetto di zlib).
  -Cartella       cartella dei sorgenti da misurare: tutte le *.pas della cartella. Senza, si misurano le unit
                  che il .dpr di test compila dalla cartella della sua libreria (Libs\<Nome>, Libs\<A>\<B> per
                  "A.B"; Sndfile anche Libs\Sound): le librerie da cui dipende contano nel loro progetto.
  -Tutti          esegue tutti i progetti di test elencati in build.bat (variabile TESTS) uno dopo l'altro
                  e scrive un riepilogo in logs\copertura\riepilogo.txt.
  -SenzaCompilare usa l'eseguibile gia' in bin\Tests, che deve essere compilato in Debug (senza questa
                  opzione lo script lo ricompila con build.bat in Debug: la mappa di Release non ha i numeri di riga).
  -SoloComando    stampa il comando di CodeCoverage senza eseguirlo.
  -CodeCoverage   percorso di CodeCoverage.exe. Se omesso: variabile d'ambiente DELPHI_CODECOVERAGE,
                  poi Tools\CodeCoverage\CodeCoverage.exe, poi il PATH.

  Prerequisiti:
    - CodeCoverage.exe (https://github.com/DelphiCodeCoverage/DelphiCodeCoverage/releases), solo Win32:
      va copiato in Tools\CodeCoverage\ (cartella ignorata da git) o indicato con -CodeCoverage.
    - i progetti di test devono produrre il file .map in modalita' Detailed: i .dproj di Tests\ lo
      fanno gia' (DCC_MapFile = 3).

  Uscita: logs\copertura\<Test>\ (CodeCoverage_Summary.html, un file html per unit, xml) e una riga di
  riepilogo a video. Nessun file del repository viene modificato.
#>
param(
  [string]$Test = '',
  [string]$Cartella = '',
  [switch]$Tutti,
  [switch]$SenzaCompilare,
  [switch]$SoloComando,
  [string]$CodeCoverage = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Find-CodeCoverage([string]$Explicit) {
  $candidates = @()
  if ($Explicit -ne '') { $candidates += $Explicit }
  if ($env:DELPHI_CODECOVERAGE) { $candidates += $env:DELPHI_CODECOVERAGE }
  $candidates += (Join-Path $root 'Tools\CodeCoverage\CodeCoverage.exe')
  $candidates += 'C:\Strumenti\DelphiCodeCoverage\Win32\CodeCoverage.exe'
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path } }
  $cmd = Get-Command 'CodeCoverage.exe' -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

# The folders a test project is the owner of: its library and nothing else. A project also compiles the
# libraries it depends on (Screenshot compiles Jpeg, Png and Zlib), but their lines belong to their own
# project and would only dilute the number. Projects whose library has another name are listed here.
$ownedFolders = @{
  'Zlib'    = @('Libs\Zlib')
  'Sndfile' = @('Libs\Sndfile', 'Libs\Sound')   # the engine that the game uses is Libs\Sound
  'Common'  = @('Common')
}

# The source files to measure: with -Cartella every .pas of that folder; otherwise the units that the test
# project compiles from the folders it owns (Libs\<Name>, Libs\<A>\<B> for "A.B", or the table above).
function Get-SourceFiles([string]$TestName, [string]$Project, [string]$Explicit) {
  if ($Explicit -ne '') {
    return @(Get-ChildItem -LiteralPath (Join-Path $root $Explicit) -Filter *.pas -File -Recurse |
      ForEach-Object { $_.FullName })
  }
  $dpr = Join-Path $root "Tests\$Project.dpr"
  if (-not (Test-Path -LiteralPath $dpr)) { throw "Progetto non trovato: $dpr" }
  $paths = [regex]::Matches((Get-Content -LiteralPath $dpr -Raw), "in\s+'([^']+\.pas)'") |
    ForEach-Object { [IO.Path]::GetFullPath((Join-Path (Join-Path $root 'Tests') $_.Groups[1].Value)) }
  $key = if ($TestName -eq '') { 'Zlib' } else { $TestName }
  $owned = if ($ownedFolders.ContainsKey($key)) { $ownedFolders[$key] } else { @('Libs\' + ($key -replace '\.', '\')) }
  $prefixes = @($owned | ForEach-Object { (Join-Path $root $_) + '\' })
  return @($paths | Where-Object {
    $path = $_
    @($prefixes | Where-Object { $path.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
  })
}

function Invoke-Coverage([string]$TestName, [string]$Explicit) {
  $project = if ($TestName -eq '' -or $TestName -eq 'Zlib') { 'DelphiDoom.Tests' } else { 'DelphiDoom.Tests.' + $TestName }
  $exe = Join-Path $root "bin\Tests\$project.exe"
  $map = Join-Path $root "bin\Tests\$project.map"
  $files = @(Get-SourceFiles $TestName $project $Explicit)
  if ($files.Count -eq 0) { throw "Nessuna unit da misurare per $project" }
  $label = if ($TestName -eq '') { 'Zlib' } else { $TestName }
  $out = Join-Path $root "logs\copertura\$label"

  if (-not $SenzaCompilare) {
    Write-Host "Compilazione di Tests\$project ..."
    # Debug: the map of Release has no line numbers; full path because cmd.exe does not see Set-Location
    & cmd.exe /c "`"$root\build.bat`" Tests\$project Debug" | Select-Object -Last 3 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "Compilazione fallita: vedi logs\$project.log" }
  }
  if (-not (Test-Path -LiteralPath $exe)) { throw "Eseguibile non trovato: $exe (compila senza -SenzaCompilare)" }
  if (-not (Test-Path -LiteralPath $map)) { throw "File .map non trovato: $map (serve DCC_MapFile = 3, Detailed)" }

  $units = @($files | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object -Unique)
  $folders = @($files | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique)
  New-Item -ItemType Directory -Force $out | Out-Null
  $unitsFile = Join-Path $out 'unit.txt'
  Set-Content -LiteralPath $unitsFile -Value $units -Encoding ascii

  # -sp wants every folder that holds a source (it does not recurse). The tool cuts a unit name at its last dot
  # (it treats it as a file name), so the list has the .pas extension and the default -efe takes it away again
  $args = @('-e', $exe, '-m', $map, '-uf', $unitsFile, '-sp') + $folders + @(
    '-od', $out,
    '-html', '-xml', '-xmllines',
    '-tec',
    '-a', '^-^-exitbehavior:Continue'
  )

  if ($SoloComando) {
    Write-Host ("CodeCoverage.exe " + (($args | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '))
    return $null
  }

  $tool = Find-CodeCoverage $CodeCoverage
  if (-not $tool) {
    throw "CodeCoverage.exe non trovato. Scaricalo da https://github.com/DelphiCodeCoverage/DelphiCodeCoverage/releases e copialo in Tools\CodeCoverage\ (oppure imposta DELPHI_CODECOVERAGE o usa -CodeCoverage)."
  }

  Write-Host "Misura di ${label}: $($units.Count) unit in $($folders.Count) cartelle"
  $log = Join-Path $out 'codecoverage.log'
  $output = & $tool @args 2>&1 | ForEach-Object { "$_" }
  Set-Content -LiteralPath $log -Value $output -Encoding utf8
  # the tool ends with a table: | lines | covered | covered % |
  $totals = $output | Where-Object { $_ -match '^\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*%' } | Select-Object -Last 1
  $tests = $output | Where-Object { $_ -match '^Tests (Passed|Failed|Errored)' } | ForEach-Object { $_.Trim() }
  if ($totals -match '^\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*%') {
    $line = "{0}: {1}% ({2} righe coperte su {3}); {4}" -f $label, $Matches[3], $Matches[2], $Matches[1], ($tests -join ', ')
  } else {
    $line = "{0}: nessun riepilogo, vedi {1}" -f $label, $log
  }
  Write-Host $line
  Write-Host "Report: $out\CodeCoverage_Summary.html"
  return $line
}

if ($Tutti) {
  $bat = Get-Content -LiteralPath (Join-Path $root 'build.bat') -Raw
  $m = [regex]::Match($bat, 'set "TESTS=([^"]+)"')
  if (-not $m.Success) { throw 'Variabile TESTS non trovata in build.bat' }
  $names = $m.Groups[1].Value.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) |
    ForEach-Object { $_ -replace '^Tests\\DelphiDoom\.Tests\.?', '' }
  $rows = @()
  foreach ($n in $names) {
    try { $rows += (Invoke-Coverage $n '') } catch { $rows += ("{0}: ERRORE {1}" -f $n, $_.Exception.Message) }
  }
  if (-not $SoloComando) {
    New-Item -ItemType Directory -Force (Join-Path $root 'logs\copertura') | Out-Null
    Set-Content -LiteralPath (Join-Path $root 'logs\copertura\riepilogo.txt') -Value $rows -Encoding utf8
    Write-Output "Riepilogo: logs\copertura\riepilogo.txt"
  }
} else {
  $null = Invoke-Coverage $Test $Cartella
}
