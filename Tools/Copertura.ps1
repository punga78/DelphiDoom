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
  -Cartella       cartella dei sorgenti da misurare (default: Libs\<Test>; per "IdLib.Hashing" prova
                  Libs\IdLib\Hashing). Le unit misurate sono tutte quelle *.pas della cartella.
  -Tutti          esegue tutti i progetti di test elencati in build.bat (variabile TESTS) uno dopo l'altro
                  e scrive un riepilogo in logs\copertura\riepilogo.txt.
  -SenzaCompilare usa l'eseguibile gia' in bin\Tests (altrimenti lo ricompila con build.bat).
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
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path } }
  $cmd = Get-Command 'CodeCoverage.exe' -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Get-SourceFolder([string]$TestName, [string]$Explicit) {
  if ($Explicit -ne '') { return $Explicit }
  if ($TestName -eq '' -or $TestName -eq 'Zlib') { return 'Libs\Zlib' }
  $parts = $TestName.Split('.')
  $flat = 'Libs\' + $TestName
  if (Test-Path -LiteralPath $flat) { return $flat }
  $nested = 'Libs\' + ($parts -join '\')
  if (Test-Path -LiteralPath $nested) { return $nested }
  throw "Cartella dei sorgenti non trovata per '$TestName': indicala con -Cartella"
}

function Invoke-Coverage([string]$TestName, [string]$Explicit) {
  $project = if ($TestName -eq '' -or $TestName -eq 'Zlib') { 'DelphiDoom.Tests' } else { 'DelphiDoom.Tests.' + $TestName }
  $exe = Join-Path $root "bin\Tests\$project.exe"
  $map = Join-Path $root "bin\Tests\$project.map"
  $folder = Get-SourceFolder $TestName $Explicit
  $label = if ($TestName -eq '') { 'Zlib' } else { $TestName }
  $out = Join-Path $root "logs\copertura\$label"

  if (-not $SenzaCompilare) {
    Write-Host "Compilazione di Tests\$project ..."
    & cmd.exe /c "build.bat Tests\$project Release" | Select-Object -Last 3 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "Compilazione fallita: vedi logs\$project.log" }
  }
  if (-not (Test-Path -LiteralPath $exe)) { throw "Eseguibile non trovato: $exe (compila senza -SenzaCompilare)" }
  if (-not (Test-Path -LiteralPath $map)) { throw "File .map non trovato: $map (serve DCC_MapFile = 3, Detailed)" }

  $units = Get-ChildItem -LiteralPath (Join-Path $root $folder) -Filter *.pas -File -Recurse |
    ForEach-Object { $_.BaseName } | Sort-Object -Unique
  if ($units.Count -eq 0) { throw "Nessuna unit .pas in $folder" }
  New-Item -ItemType Directory -Force $out | Out-Null
  $unitsFile = Join-Path $out 'unit.txt'
  Set-Content -LiteralPath $unitsFile -Value $units -Encoding ascii

  $args = @(
    '-e', $exe, '-m', $map,
    '-uf', $unitsFile,
    '-spd', (Join-Path $root $folder),
    '-od', $out,
    '-html', '-xml',
    '-a', '--exitbehavior:Continue'
  )

  if ($SoloComando) {
    Write-Host ("CodeCoverage.exe " + (($args | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '))
    return $null
  }

  $tool = Find-CodeCoverage $CodeCoverage
  if (-not $tool) {
    throw "CodeCoverage.exe non trovato. Scaricalo da https://github.com/DelphiCodeCoverage/DelphiCodeCoverage/releases e copialo in Tools\CodeCoverage\ (oppure imposta DELPHI_CODECOVERAGE o usa -CodeCoverage)."
  }

  Write-Host "Misura di ${label}: $($units.Count) unit in $folder"
  $log = Join-Path $out 'codecoverage.log'
  & $tool @args 2>&1 | Tee-Object -FilePath $log | Out-Null
  $summary = Select-String -LiteralPath $log -Pattern 'covered|coverage' -SimpleMatch:$false |
    Select-Object -Last 3 | ForEach-Object { $_.Line.Trim() }
  $line = "{0}: {1}" -f $label, ($summary -join ' | ')
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
