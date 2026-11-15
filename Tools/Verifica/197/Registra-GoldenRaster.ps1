<#
  Issue #197: riscrive Tests\Data\War\raster.golden.txt dal rasterizzatore software della SDL3 VERA (sdl_raster_ref.c).
  Ogni sezione "M modo conteggio" e' seguita da "R seme impronta" per i semi da 1 a conteggio. Modi (bit): 1 = alfa parziali nelle
  texture, 2 = tutto dentro lo schermo, 4 = misure intere, 8 = niente specchi, 16 = niente scale, 32 = niente riempimenti,
  64 = niente texture. Il modo 0 e' quello del gioco (alfa 0 o 255, ritaglio, frazioni, specchi, scale, riempimenti e contorni).
  Uso:  powershell -NoProfile -File Registra-GoldenRaster.ps1 -Out <cartella nuova fuori dal repository>
#>
param([Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Compila-RasterRef.ps1') -Out $Out | Out-Null
$exe = Join-Path $Out 'sdl_raster_ref.exe'
$golden = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot))) 'Tests\Data\War\raster.golden.txt'
$lines = New-Object System.Collections.Generic.List[string]
foreach ($case in @(@(0, 400), @(2, 200), @(28, 200), @(46, 200))) {
  $lines.Add("M $($case[0]) $($case[1])")
  foreach ($l in (& $exe $case[1] $case[0])) { $lines.Add($l) }
}
[IO.File]::WriteAllLines($golden, $lines)
"Scritto $golden ($($lines.Count) righe)"
