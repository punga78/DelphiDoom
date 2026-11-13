<#
  Issue #192 (seconda fetta): compila il riferimento in C (Compila-RenderRef.ps1) e riscrive i golden del testo e degli
  sprite in Tests\Data\War: render.text.golden.txt (240 scenari di testo con seme fisso: misure, disegno di una riga e di
  piu' righe, come lista di blit) e render.sprites.golden.txt (un WarSprite per ogni immagine, sprite e cursore del
  DATA.WAR vero, con e senza sottoinsieme di fotogrammi, e i blit di renderSprite). Servono la cartella -Out NUOVA
  (fuori dal repository) e il DATA.WAR vero.

  Uso: powershell -NoProfile -File Registra-GoldenRender.ps1 -Out <cartella nuova> [-DataWar <...\DATA.WAR>]
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR'
)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Compila-RenderRef.ps1') -Out $Out | Out-Host
$exe = Join-Path $Out 'war_render_ref.exe'
$data = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\Tests\Data\War'))
$jobs = @(
  @('-', 'text', 'render.text.golden.txt'),
  @($DataWar, 'sprites', 'render.sprites.golden.txt')
)
foreach ($j in $jobs) {
  $lines = & $exe $j[0] $j[1]
  if ($LASTEXITCODE -ne 0) { throw "$($j[1]) e' uscito con $LASTEXITCODE" }
  # LF, ASCII: lo stesso byte per byte su ogni macchina
  [IO.File]::WriteAllText((Join-Path $data $j[2]), (($lines -join "`n") + "`n"), [Text.Encoding]::ASCII)
  "$($j[2]): $($lines.Count) righe"
}
