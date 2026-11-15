<#
  Issue #197: riscrive Tests\Data\War\ui.<script>.golden.txt dal remake in C ORIGINALE e INTERO con la SDL3 vera
  (war_frame_ref.c): per ogni script di Tools\Verifica\197\scripts una riga "H n impronta" per fotogramma (FNV-1a dei
  320 x 200 x 4 byte RGBA). E' il gruppo "197 render" di Tools\Verifica\201\Golden-Common.ps1: qui lo si lancia da solo.
  Serve il DATA.WAR vero e i PNG dei font (Reference\war1\assets); senza il DATA.WAR non riscrive nulla.

  Uso:
    powershell -NoProfile -File Tools\Verifica\197\Registra-GoldenUi.ps1 [-DataWar <...\DATA.WAR>] [-Out <cartella NUOVA fuori dal repository>]
#>
param(
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR',
  [string]$Out = ''
)
$ErrorActionPreference = 'Stop'
$register = Join-Path (Split-Path $PSScriptRoot) '201\Registra-Golden.ps1'
if ($Out -eq '') { & $register -DataWar $DataWar -Solo '197' } else { & $register -DataWar $DataWar -Solo '197' -Out $Out }
