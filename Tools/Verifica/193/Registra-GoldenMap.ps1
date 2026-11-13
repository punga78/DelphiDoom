<#
  Issue #193 (seconda fetta): compila il riferimento in C (Compila-MapRef.ps1) e riscrive i golden della mappa di gioco in
  Tests\Data\War: map.maps.golden.txt (ogni livello appena istanziato, dopo il primo aggiornamento del fog e con la
  minimappa), map.trees.golden.txt (60 scenari di alberi con seme fisso), map.tables.golden.txt (le tabelle delle unita').
  Servono la cartella -Out NUOVA (fuori dal repository) e il DATA.WAR vero.

  Uso: powershell -NoProfile -File Registra-GoldenMap.ps1 -Out <cartella nuova> [-DataWar <...\DATA.WAR>]
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR'
)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Compila-MapRef.ps1') -Out $Out | Out-Host
$exe = Join-Path $Out 'war_map_ref.exe'
$data = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\Tests\Data\War'))
$jobs = @(
  @('maps', 'map.maps.golden.txt'),
  @('trees', 'map.trees.golden.txt'),
  @('tables', 'map.tables.golden.txt')
)
foreach ($j in $jobs) {
  $lines = & $exe $DataWar $j[0]
  if ($LASTEXITCODE -ne 0) { throw "$($j[0]) e' uscito con $LASTEXITCODE" }
  # LF, ASCII: lo stesso byte per byte su ogni macchina
  [IO.File]::WriteAllText((Join-Path $data $j[1]), (($lines -join "`n") + "`n"), [Text.Encoding]::ASCII)
  "$($j[1]): $($lines.Count) righe"
}
