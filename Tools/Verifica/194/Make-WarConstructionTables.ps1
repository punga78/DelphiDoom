<#
  Issue #194 (seconda fetta): scrive DelphiDoom.War.Model.BuildingResources.Data.pas dall'uscita del C
  (Tests\Data\War\model.construction.tables.golden.txt, prodotta da `war_model_ref construction-tables`): le risorse delle
  immagini di costruzione (buildingsData di war_units.c). I passi delle azioni non sono piu' qui: sono nella tabella unica di
  tutte le azioni (Make-WarActionSteps.ps1, DelphiDoom.War.Model.ActionSteps.Data). Le tabelle non si scrivono a mano: si
  rifanno.

  Uso: powershell -NoProfile -File Make-WarConstructionTables.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\model.construction.tables.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Libs\War')
)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }
$rs = @($lines | Where-Object { $_.StartsWith('R ') } | ForEach-Object { , $_.Split(' ') })

$o = New-Object System.Collections.Generic.List[string]
$o.AddRange([string[]]@(
  '{******************************************************************************}',
  '{                                                                              }',
  '{  DelphiDoom: war library - images of the buildings under construction       }',
  '{  (GENERATED)                                                                 }',
  '{                                                                              }',
  '{  Port of war1 (acoto87/war1), war_units.c, (c) 2019 Alejandro Coto          }',
  '{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }',
  '{  version, not the original.                                                  }',
  '{                                                                              }',
  '{  Written by Tools\Verifica\194\Make-WarConstructionTables.ps1 from the       }',
  '{  output of the original C code (Tests\Data\War\                              }',
  '{  model.construction.tables.golden.txt): do not edit by hand                  }',
  '{                                                                              }',
  '{  Licensed under the GNU General Public License, version 2 or later           }',
  '{                                                                              }',
  '{******************************************************************************}',
  'unit DelphiDoom.War.Model.BuildingResources.Data;',
  '',
  'interface',
  '',
  'const'
))
$o.Add("  /// <summary>buildingsData of war_units.c: the resource of the image of a building under construction, by unit type, counting from the type that WAR_BUILDING_FIRST_TYPE names</summary>")
$o.Add("  WAR_BUILDING_FIRST_TYPE = $($rs[0][1]);")
$o.Add("  WAR_BUILDING_CONSTRUCTION_RESOURCES: array[0..$($rs.Count - 1)] of Integer = (" + (($rs | ForEach-Object { $_[2] }) -join ', ') + ');')
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
$out = Join-Path $OutDir 'DelphiDoom.War.Model.BuildingResources.Data.pas'
[IO.File]::WriteAllText($out, (($o -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($true)))
"Scritto $out ($($rs.Count) risorse)"
