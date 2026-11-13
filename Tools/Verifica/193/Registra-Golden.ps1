<#
  Issue #193: compila il riferimento in C (Compila-LevelRef.ps1) e riscrive i golden di Tests\Data\War:
  levels.golden.txt, campaigns.golden.txt, objectives.golden.txt, autotile.tables.golden.txt, autotile.golden.txt,
  grid.golden.txt. Servono la cartella -Out NUOVA (fuori dal repository) e il DATA.WAR vero.

  Uso: powershell -NoProfile -File Registra-Golden.ps1 -Out <cartella nuova> [-DataWar <...\DATA.WAR>]
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR'
)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Compila-LevelRef.ps1') -Out $Out | Out-Host
$exe = Join-Path $Out 'war_lvl_ref.exe'
$data = Join-Path (Split-Path (Split-Path $PSScriptRoot)) '..\Tests\Data\War'
$data = [IO.Path]::GetFullPath($data)
$jobs = @(
  @('levels', $DataWar, 'levels.golden.txt'),
  @('campaigns', '-', 'campaigns.golden.txt'),
  @('objectives', '-', 'objectives.golden.txt'),
  @('tables', '-', 'autotile.tables.golden.txt'),
  @('autotile', '-', 'autotile.golden.txt'),
  @('grid', '-', 'grid.golden.txt')
)
foreach ($j in $jobs) {
  $lines = & $exe $j[1] $j[0]
  if ($LASTEXITCODE -ne 0) { throw "$($j[0]) e' uscito con $LASTEXITCODE" }
  # LF, ASCII: lo stesso byte per byte su ogni macchina
  [IO.File]::WriteAllText((Join-Path $data $j[2]), (($lines -join "`n") + "`n"), [Text.Encoding]::ASCII)
  "$($j[2]): $($lines.Count) righe"
}
