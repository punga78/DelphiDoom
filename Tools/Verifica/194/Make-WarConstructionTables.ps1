<#
  Issue #194 (seconda fetta): scrive DelphiDoom.War.Model.ActionStepData.pas dall'uscita del C
  (Tests\Data\War\model.construction.tables.golden.txt, prodotta da `war_model_ref construction-tables`): i passi di ogni
  azione di ogni tipo di unita' (gUnitActionDefs di war_actions.c) e le risorse delle immagini di costruzione
  (buildingsData). Le tabelle non si scrivono a mano: si rifanno.

  Le definizioni uguali (tipo di unita' diversi con gli stessi passi) si scrivono una volta sola.

  Uso: powershell -NoProfile -File Make-WarConstructionTables.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\model.construction.tables.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Libs\War')
)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }

$defs = New-Object System.Collections.Generic.List[object]
$keys = @{}
$index = @{}        # "t,a" -> indice della definizione
foreach ($l in ($lines | Where-Object { $_.StartsWith('S ') })) {
  $f = $l.Split(' ')
  $type = [int]$f[1]; $action = [int]$f[2]
  $count = [int]$f[5]
  $steps = @()
  for ($i = 0; $i -lt $count; $i++) { $steps += $f[6 + $i] }
  $key = "$($f[3]) $($f[4]) $($steps -join ' ')"
  if (-not $keys.ContainsKey($key)) {
    $keys[$key] = $defs.Count
    $defs.Add(@{ Loop = ($f[3] -eq '1'); Directional = ($f[4] -eq '1'); Steps = $steps })
  }
  $index["$type,$action"] = $keys[$key]
}

$pool = New-Object System.Collections.Generic.List[string]
$first = @()
foreach ($d in $defs) {
  $first += $pool.Count
  foreach ($s in $d.Steps) { $p = $s.Split(':'); $pool.Add("(StepType: $($p[0]); Param: $($p[1]))") }
}

$o = New-Object System.Collections.Generic.List[string]
$o.AddRange([string[]]@(
  '{******************************************************************************}',
  '{                                                                              }',
  '{  DelphiDoom: war library - the steps of the unit actions (GENERATED)          }',
  '{                                                                              }',
  '{  Port of war1 (acoto87/war1), war_actions.c and war_units.c, (c) 2019        }',
  '{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }',
  '{  This is an altered version, not the original.                               }',
  '{                                                                              }',
  '{  Written by Tools\Verifica\194\Make-WarConstructionTables.ps1 from the       }',
  '{  output of the original C code (Tests\Data\War\                              }',
  '{  model.construction.tables.golden.txt): do not edit by hand                  }',
  '{                                                                              }',
  '{  Licensed under the GNU General Public License, version 2 or later           }',
  '{                                                                              }',
  '{******************************************************************************}',
  'unit DelphiDoom.War.Model.ActionStepData;',
  '',
  'interface',
  '',
  'type',
  '  /// <summary>WarUnitActionStep: what the step is (1 frame, 2 wait, 3 attack, 4 to 10 sounds) and its parameter</summary>',
  '  TWarActionStep = record',
  '    StepType: Byte;',
  '    Param: Integer;',
  '  end;',
  '',
  '  /// <summary>WarUnitActionDef without the type: the steps are WAR_ACTION_STEPS[First .. First + Count - 1]</summary>',
  '  TWarActionDef = record',
  '    Loop: Boolean;',
  '    Directional: Boolean;',
  '    First: Integer;',
  '    Count: Integer;',
  '  end;',
  '',
  'const'
))
$o.Add("  /// <summary>The steps of all the definitions, one after the other ($($pool.Count) steps)</summary>")
$o.Add("  WAR_ACTION_STEPS: array[0..$($pool.Count - 1)] of TWarActionStep = (")
for ($i = 0; $i -lt $pool.Count; $i++) {
  $sep = if ($i -lt $pool.Count - 1) { ',' } else { '' }
  $o.Add("    $($pool[$i])$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add("  /// <summary>The $($defs.Count) different definitions of gUnitActionDefs</summary>")
$o.Add("  WAR_ACTION_DEFS: array[0..$($defs.Count - 1)] of TWarActionDef = (")
for ($i = 0; $i -lt $defs.Count; $i++) {
  $d = $defs[$i]
  $sep = if ($i -lt $defs.Count - 1) { ',' } else { '' }
  $loop = if ($d.Loop) { 'True' } else { 'False' }
  $dir = if ($d.Directional) { 'True' } else { 'False' }
  $o.Add("    (Loop: $loop; Directional: $dir; First: $($first[$i]); Count: $($d.Steps.Count))$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add('  /// <summary>For each unit type (rows) and action (idle, walk, attack, death, harvest, repair, build) the index in WAR_ACTION_DEFS, or -1</summary>')
$o.Add('  WAR_ACTION_DEF_INDEX: array[0..53, 0..6] of SmallInt = (')
for ($t = 0; $t -le 53; $t++) {
  $cells = @()
  for ($a = 0; $a -le 6; $a++) { if ($index.ContainsKey("$t,$a")) { $cells += $index["$t,$a"] } else { $cells += -1 } }
  $sep = if ($t -lt 53) { ',' } else { '' }
  $o.Add("    ($($cells -join ', '))$sep")
}
$o.Add('  );')
$o.Add('')
$rs = @($lines | Where-Object { $_.StartsWith('R ') } | ForEach-Object { , $_.Split(' ') })
$o.Add("  /// <summary>buildingsData of war_units.c: the resource of the image of a building under construction, by unit type, counting from the type that WAR_BUILDING_FIRST_TYPE says</summary>")
$o.Add("  WAR_BUILDING_FIRST_TYPE = $($rs[0][1]);")
$o.Add("  WAR_BUILDING_CONSTRUCTION_RESOURCES: array[0..$($rs.Count - 1)] of Integer = (" + (($rs | ForEach-Object { $_[2] }) -join ', ') + ');')
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
$out = Join-Path $OutDir 'DelphiDoom.War.Model.ActionStepData.pas'
[IO.File]::WriteAllText($out, (($o -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($true)))
"Scritto $out ($($pool.Count) passi, $($defs.Count) definizioni)"
