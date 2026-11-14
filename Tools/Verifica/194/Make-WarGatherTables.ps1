<#
  Issue #194 (seconda fetta, raccolta): scrive DelphiDoom.War.Model.GatherData.pas dall'uscita del C
  (Tests\Data\War\gather.tables.golden.txt, prodotta da `war_model_ref gather-tables`): i passi dell'azione di raccolta
  e le immagini dei trasportatori. Le tabelle non si scrivono a mano: si rifanno.

  Uso: powershell -NoProfile -File Make-WarGatherTables.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\gather.tables.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Libs\War')
)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }
$harvest = @($lines | Where-Object { $_.StartsWith('H ') } | ForEach-Object { ,($_.Split(' ')) })
$workers = @($lines | Where-Object { $_.StartsWith('W ') } | ForEach-Object { ,($_.Split(' ')) })
$max = ($harvest | ForEach-Object { [int]$_[4] } | Measure-Object -Maximum).Maximum

$o = New-Object System.Collections.Generic.List[string]
$o.AddRange([string[]]@(
  '{******************************************************************************}',
  '{                                                                              }',
  '{  DelphiDoom: war library - steps of the harvest action, carrying images     }',
  '{  (GENERATED)                                                                 }',
  '{                                                                              }',
  '{  Port of war1 (acoto87/war1), war_actions.c and war_units.c, (c) 2019        }',
  '{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }',
  '{  This is an altered version, not the original.                               }',
  '{                                                                              }',
  '{  Written by Tools\Verifica\194\Make-WarGatherTables.ps1 from the output of   }',
  '{  the original C code (Tests\Data\War\gather.tables.golden.txt): do not edit  }',
  '{  by hand                                                                     }',
  '{                                                                              }',
  '{  Licensed under the GNU General Public License, version 2 or later           }',
  '{                                                                              }',
  '{******************************************************************************}',
  'unit DelphiDoom.War.Model.GatherData;',
  '',
  'interface',
  '',
  'const',
  "  /// <summary>The most steps that a definition of the table has</summary>",
  "  WAR_ACTION_STEPS_MAX = $max;",
  '',
  'type',
  '  /// <summary>WarUnitActionStep: the type (WAR_ACTION_STEP_*) and its parameter (a frame, a number of frames)</summary>',
  '  TWarActionStepData = record',
  '    StepType: Integer;',
  '    Param: Integer;',
  '  end;',
  '',
  '  /// <summary>The part of a WarUnitActionDef that the update of the action reads</summary>',
  '  TWarActionDefinition = record',
  '    UnitType: Integer;',
  '    Directional: Boolean;',
  '    Loop: Boolean;',
  '    Count: Integer;',
  '    Steps: array[0..WAR_ACTION_STEPS_MAX - 1] of TWarActionStepData;',
  '  end;',
  '',
  '  /// <summary>WarWorkerData: the images of a worker that carries wood or gold</summary>',
  '  TWarWorkerSprites = record',
  '    UnitType: Integer;',
  '    CarryingWood: Integer;',
  '    CarryingGold: Integer;',
  '  end;',
  '',
  'const'
))
$o.Add("  /// <summary>gUnitActionDefs[type][WAR_ACTION_TYPE_HARVEST] of war_actions.c: the unit types that have it</summary>")
$o.Add("  WAR_HARVEST_ACTIONS: array[0..$($harvest.Count - 1)] of TWarActionDefinition = (")
for ($i = 0; $i -lt $harvest.Count; $i++) {
  $r = $harvest[$i]
  $n = [int]$r[4]
  $steps = for ($k = 0; $k -lt $max; $k++) {
    if ($k -lt $n) { $p = $r[5 + $k].Split(':'); "(StepType: $($p[0]); Param: $($p[1]))" } else { '(StepType: 0; Param: 0)' }
  }
  $sep = if ($i -lt $harvest.Count - 1) { ',' } else { '' }
  $o.Add("    (UnitType: $($r[1]); Directional: $(if ($r[2] -eq '1') {'True'} else {'False'}); Loop: $(if ($r[3] -eq '1') {'True'} else {'False'}); Count: $n;")
  $o.Add("      Steps: ($($steps -join ', ')))$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add("  /// <summary>workersData of war_units.c</summary>")
$o.Add("  WAR_WORKER_SPRITES: array[0..$($workers.Count - 1)] of TWarWorkerSprites = (")
for ($i = 0; $i -lt $workers.Count; $i++) {
  $r = $workers[$i]
  $sep = if ($i -lt $workers.Count - 1) { ',' } else { '' }
  $o.Add("    (UnitType: $($r[1]); CarryingWood: $($r[2]); CarryingGold: $($r[3]))$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
[IO.File]::WriteAllLines((Join-Path $OutDir 'DelphiDoom.War.Model.GatherData.pas'), $o, (New-Object System.Text.UTF8Encoding($false)))
"Scritta GatherData ($($harvest.Count) azioni di raccolta, $($workers.Count) trasportatori)"
