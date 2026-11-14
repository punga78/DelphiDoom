<#
  Misura la copertura dei test di una libreria con DelphiCodeCoverage (CodeCoverage.exe).

  Uso:
    powershell -NoProfile -File Tools\Copertura.ps1 -Test Zone
    powershell -NoProfile -File Tools\Copertura.ps1 -Test IdLib.Hashing -Cartella Libs\IdLib\Hashing
    powershell -NoProfile -File Tools\Copertura.ps1 -Test XcomTour -Cartella "Libs\XcomGeoscape,Libs\XcomBasescape"
    powershell -NoProfile -File Tools\Copertura.ps1 -Test Zone -SenzaCompilare
    powershell -NoProfile -File Tools\Copertura.ps1 -Tutti
    powershell -NoProfile -File Tools\Copertura.ps1 -Test Zone -SoloComando

  -Test           nome del progetto di test senza il prefisso: "Zone" = Tests\DelphiDoom.Tests.Zone,
                  "" o "Zlib" = Tests\DelphiDoom.Tests (il progetto di zlib).
  -Cartella       cartella dei sorgenti da misurare: tutte le *.pas della cartella. Senza, si misurano le unit
                  che il .dpr di test compila dalla cartella della sua libreria (Libs\<Nome>, Libs\<A>\<B> per
                  "A.B"; Sndfile anche Libs\Sound): le librerie da cui dipende contano nel loro progetto.
  -Tutti          esegue tutti i progetti di test elencati in Tools\build.bat (variabile TESTS) uno dopo l'altro
                  e scrive un riepilogo in logs\copertura\riepilogo.txt.
  -SenzaCompilare usa l'eseguibile gia' in bin\Win32\Debug\Tests, che deve essere compilato in Debug (senza questa
                  opzione lo script lo ricompila con Tools\build.bat in Debug: la mappa di Release non ha i numeri di riga).
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
    # more than one folder, separated by commas: a single run of the tests measures them all
    return @($Explicit.Split(',') | ForEach-Object {
      Get-ChildItem -LiteralPath (Join-Path $root $_.Trim()) -Filter *.pas -File -Recurse } |
      ForEach-Object { $_.FullName })
  }
  $dpr = Join-Path $root "Tests\$Project.dpr"
  if (-not (Test-Path -LiteralPath $dpr)) { throw "Progetto non trovato: $dpr" }
  $paths = [regex]::Matches((Get-Content -LiteralPath $dpr -Raw), "in\s+'([^']+\.pas)'") |
    ForEach-Object { [IO.Path]::GetFullPath((Join-Path (Join-Path $root 'Tests') $_.Groups[1].Value)) }
  $key = if ($TestName -eq '') { 'Zlib' } else { $TestName }
  $owned = if ($ownedFolders.ContainsKey($key)) { $ownedFolders[$key] } else { @('Libs\' + ($key -replace '\.', '\')) }
  $prefixes = @($owned | ForEach-Object { (Join-Path $root $_) + '\' })
  $listed = @($paths | Where-Object {
    $path = $_
    @($prefixes | Where-Object { $path.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
  })
  if ($listed.Count -gt 0) { return $listed }
  # The .dpr names no unit of its library (it finds them through the search path, as XcomDebriefing does): the
  # units are the ones of the owned folders that the linker put in the map
  $map = Join-Path $root "bin\Win32\Debug\Tests\$Project.map"
  if (-not (Test-Path -LiteralPath $map)) { return @() }
  $linked = @{}
  foreach ($m in [regex]::Matches((Get-Content -LiteralPath $map -Raw), 'Line numbers for [^(\r\n]+\(([^)\r\n]+\.pas)\)')) {
    $linked[(Split-Path -Leaf $m.Groups[1].Value).ToLowerInvariant()] = $true
  }
  return @($owned | ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $root $_) -Filter *.pas -File } |
    Where-Object { $linked.ContainsKey($_.Name.ToLowerInvariant()) } | ForEach-Object { $_.FullName })
}

# A copy of the map without the line of the closing "end." of the units that have no initialization or
# finalization. The compiler gives that line the address that follows the last routine, and there it often
# writes the RTTI of the unit (the type info of a TArray<T> used in the unit): CodeCoverage would put its
# breakpoint, an INT3, on a byte of that data and never take it away, because data is not run. That is how
# the name length of TArray<PSingle> in DelphiDoom.Sound.Vorbis.Residue became $CC and SetLength allocated
# the wrong size under coverage only (issue #138).
function New-CodeOnlyMap([string]$Map, [string[]]$Sources, [string]$Target) {
  $byName = @{}
  foreach ($s in $Sources) { $byName[(Split-Path -Leaf $s).ToLowerInvariant()] = $s }
  $drop = 0
  $lines = Get-Content -LiteralPath $Map
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -notmatch '^Line numbers for [^(]+\(([^)]+)\)') { continue }
    $source = $byName[$Matches[1].ToLowerInvariant()]
    if (-not $source) { continue }
    $text = Get-Content -LiteralPath $source
    if (@($text | Where-Object { $_ -match '^\s*(initialization|finalization)\b' }).Count -gt 0) { continue }
    $endLine = 0
    for ($k = $text.Count - 1; $k -ge 0; $k--) { if ($text[$k].Trim() -ieq 'end.') { $endLine = $k + 1; break } }
    if ($endLine -eq 0) { continue }
    for ($j = $i + 1; $j -lt $lines.Count -and $lines[$j] -notmatch '^Line numbers for '; $j++) {
      $before = $lines[$j]
      $lines[$j] = [regex]::Replace($before, "\s+$endLine 0001:[0-9A-F]{8}", '')
      if ($lines[$j] -ne $before) {
        $drop++
        # a row left empty would end the section for the reader of the map
        if ($lines[$j].Trim() -eq '') { $lines[$j] = $null }
      }
    }
  }
  Set-Content -LiteralPath $Target -Value @($lines | Where-Object { $null -ne $_ }) -Encoding ascii
  return $drop
}

# One row for each measured folder (the tool only gives the total): the lines of its units in the xml summary.
function Write-FolderTotals([string]$Out, [string[]]$Files) {
  $summary = Join-Path $Out 'CodeCoverage_Summary.xml'
  if (-not (Test-Path -LiteralPath $summary)) { return }
  $folderOf = @{}
  foreach ($f in $Files) { $folderOf[(Split-Path -Leaf $f).ToLowerInvariant()] = Split-Path -Parent $f }
  $totals = @{}
  $xml = [xml](Get-Content -LiteralPath $summary -Raw)
  foreach ($src in $xml.SelectNodes('//srcfile')) {
    $folder = $folderOf[([string]$src.name).ToLowerInvariant()]
    if (-not $folder) { continue }
    $cov = $src.SelectSingleNode("coverage[starts-with(@type,'line')]")
    if (-not $cov -or ([string]$cov.value) -notmatch '\((\d+)/(\d+)\)') { continue }
    if (-not $totals.ContainsKey($folder)) { $totals[$folder] = @(0, 0) }
    $totals[$folder][0] += [int]$Matches[1]
    $totals[$folder][1] += [int]$Matches[2]
  }
  foreach ($folder in ($totals.Keys | Sort-Object)) {
    $t = $totals[$folder]
    Write-Host ("  {0}: {1}% ({2} righe coperte su {3})" -f $folder.Substring($root.Length + 1),
      [Math]::Floor(100 * $t[0] / [Math]::Max(1, $t[1])), $t[0], $t[1])
  }
}

function Invoke-Coverage([string]$TestName, [string]$Explicit) {
  $project = if ($TestName -eq '' -or $TestName -eq 'Zlib') { 'DelphiDoom.Tests' } else { 'DelphiDoom.Tests.' + $TestName }
  $exe = Join-Path $root "bin\Win32\Debug\Tests\$project.exe"
  $map = Join-Path $root "bin\Win32\Debug\Tests\$project.map"
  $label = if ($TestName -eq '') { 'Zlib' } else { $TestName }
  $out = Join-Path $root "logs\copertura\$label"

  if (-not $SenzaCompilare) {
    Write-Host "Compilazione di Tests\$project ..."
    # Debug: the map of Release has no line numbers; full path because cmd.exe does not see Set-Location
    & cmd.exe /c "`"$root\Tools\build.bat`" Tests\$project Debug" | Select-Object -Last 3 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "Compilazione fallita: vedi logs\$project.log" }
  }
  if (-not (Test-Path -LiteralPath $exe)) { throw "Eseguibile non trovato: $exe (compila senza -SenzaCompilare)" }
  if (-not (Test-Path -LiteralPath $map)) { throw "File .map non trovato: $map (serve DCC_MapFile = 3, Detailed)" }
  # after the build: a project that names no unit of its library is measured on the units of the map
  $files = @(Get-SourceFiles $TestName $project $Explicit)
  if ($files.Count -eq 0) { throw "Nessuna unit da misurare per $project" }

  $units = @($files | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object -Unique)
  $folders = @($files | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique)
  New-Item -ItemType Directory -Force $out | Out-Null
  $unitsFile = Join-Path $out 'unit.txt'
  Set-Content -LiteralPath $unitsFile -Value $units -Encoding ascii
  $codeMap = Join-Path $out 'codice.map'
  $null = New-CodeOnlyMap $map $files $codeMap
  $map = $codeMap

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
  if ($Explicit.Contains(',')) { Write-FolderTotals $out $files }
  Write-Host "Report: $out\CodeCoverage_Summary.html"
  return $line
}

if ($Tutti) {
  $bat = Get-Content -LiteralPath (Join-Path $root 'Tools\build.bat') -Raw
  $m = [regex]::Match($bat, 'set "TESTS=([^"]+)"')
  if (-not $m.Success) { throw 'Variabile TESTS non trovata in Tools\build.bat' }
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
