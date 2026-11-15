<#
  Issue #197: riscrive Tests\Data\War\raster.golden.txt dal rasterizzatore software della SDL3 VERA (sdl_raster_ref.c).
  Ogni sezione "M modo conteggio" e' seguita da "R seme impronta" per i semi da 1 a conteggio. Modi (bit): 1 = alfa parziali nelle
  texture, 2 = tutto dentro lo schermo, 4 = misure intere, 8 = niente specchi, 16 = niente scale, 32 = niente riempimenti,
  64 = niente texture. Il modo 0 e' quello del gioco (alfa 0 o 255, ritaglio, frazioni, specchi, scale, riempimenti e contorni).
  Le sezioni "L modo conteggio" sono le linee: bit 2 = dentro lo schermo, 4 = estremi interi, 8 = linee corte.
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
# le linee (SDL_RenderLine), sempre opache: sezioni "L modo conteggio" (vedi lineScenario in sdl_raster_ref.c)
foreach ($case in @(@(0, 400), @(2, 200), @(4, 200), @(8, 200), @(10, 200), @(14, 200))) {
  $lines.Add("L $($case[0]) $($case[1])")
  foreach ($l in (& $exe lines $case[1] $case[0])) { $lines.Add($l) }
}
[IO.File]::WriteAllLines($golden, $lines)
"Scritto $golden ($($lines.Count) righe)"
