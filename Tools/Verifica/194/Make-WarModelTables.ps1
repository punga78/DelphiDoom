<#
  Issue #194 (prima fetta): scrive DelphiDoom.War.Model.StatData.pas e DelphiDoom.War.Model.ActionData.pas dall'uscita del C
  (Tests\Data\War\model.tables.golden.txt, prodotta da `war_model_ref tables`). Le tabelle non si scrivono a mano: si rifanno.

  Uso: powershell -NoProfile -File Make-WarModelTables.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\model.tables.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Libs\War')
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }

function SingleOf([string]$hex) {
  $bytes = [BitConverter]::GetBytes([Convert]::ToUInt32($hex, 16))
  $v = [BitConverter]::ToSingle($bytes, 0)
  if ($v -eq 0) { return '0.0' }
  return $v.ToString('0.#########', $inv)
}

function Header([string]$What) {
  @(
    '{******************************************************************************}',
    '{                                                                              }',
    "{  DelphiDoom: war library - $What (GENERATED)",
    '{                                                                              }',
    '{  Port of war1 (acoto87/war1), war_units.c and war_actions.c, (c) 2019        }',
    '{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }',
    '{  This is an altered version, not the original.                               }',
    '{                                                                              }',
    '{  Written by Tools\Verifica\194\Make-WarModelTables.ps1 from the output of    }',
    '{  the original C code (Tests\Data\War\model.tables.golden.txt): do not edit   }',
    '{  by hand                                                                     }',
    '{                                                                              }',
    '{  Licensed under the GNU General Public License, version 2 or later           }',
    '{                                                                              }',
    '{******************************************************************************}'
  )
}

function Rows([string]$Tag) { $lines | Where-Object { $_.StartsWith("$Tag ") } | ForEach-Object { ,($_.Split(' ')) } }

# ---- StatData
$o = New-Object System.Collections.Generic.List[string]
$h0 = Header 'x'
$h0[2] = '{  DelphiDoom: war library - statistics of units, upgrades and spells (GENERATED)}'
$o.AddRange([string[]]$h0)
$o.Add('unit DelphiDoom.War.Model.StatData;')
$o.Add('')
$o.Add('interface')
$o.Add('')
$o.Add('uses')
$o.Add('  DelphiDoom.War.Model.Stats.Types;')
$o.Add('')
$o.Add('const')
$u = @(Rows 'U')
$o.Add("  /// <summary>unitStats of war_units.c: the $($u.Count) unit types that move</summary>")
$o.Add("  WAR_UNIT_STAT_DATA: array[0..$($u.Count - 1)] of TWarUnitStatsFull = (")
for ($i = 0; $i -lt $u.Count; $i++) {
  $r = $u[$i]
  $sep = if ($i -lt $u.Count - 1) { ',' } else { '' }
  $o.Add("    (UnitType: $($r[1]); Range: $($r[2]); Sight: $($r[3]); Armor: $($r[4]); Hp: $($r[5]); Mana: $($r[6]); MinDamage: $($r[7]); RndDamage: $($r[8]); BuildTime: $($r[9]); GoldCost: $($r[10]); WoodCost: $($r[11]); Decay: $($r[12]); Speeds: ($(SingleOf $r[13]), $(SingleOf $r[14]), $(SingleOf $r[15])))$sep")
}
$o.Add('  );')
$o.Add('')
$b = @(Rows 'B')
$o.Add("  /// <summary>buildingStats of war_units.c: the $($b.Count) buildings (the gold mine included)</summary>")
$o.Add("  WAR_BUILDING_STAT_DATA: array[0..$($b.Count - 1)] of TWarBuildingStatsFull = (")
for ($i = 0; $i -lt $b.Count; $i++) {
  $r = $b[$i]
  $sep = if ($i -lt $b.Count - 1) { ',' } else { '' }
  $o.Add("    (UnitType: $($r[1]); Armor: $($r[2]); Sight: $($r[3]); Hp: $($r[4]); BuildTime: $($r[5]); GoldCost: $($r[6]); WoodCost: $($r[7]))$sep")
}
$o.Add('  );')
$o.Add('')
$g = @(Rows 'G')
$o.Add("  /// <summary>upgradeStats and upgradesData of war_units.c: the $($g.Count) upgrades</summary>")
$o.Add("  WAR_UPGRADE_STAT_DATA: array[0..$($g.Count - 1)] of TWarUpgradeStats = (")
for ($i = 0; $i -lt $g.Count; $i++) {
  $r = $g[$i]
  $sep = if ($i -lt $g.Count - 1) { ',' } else { '' }
  $o.Add("    (UpgradeType: $($r[1]); BuildTime: $($r[2]); GoldCost1: $($r[3]); GoldCost2: $($r[4]); MaxLevel: $($r[5]))$sep")
}
$o.Add('  );')
$o.Add('')
$p = @(Rows 'P')
$o.Add("  /// <summary>spellStats and spellMappings of war_units.c: the $($p.Count) spells and summons (MappedUnit -1 if it does not summon)</summary>")
$o.Add("  WAR_SPELL_STAT_DATA: array[0..$($p.Count - 1)] of TWarSpellStats = (")
for ($i = 0; $i -lt $p.Count; $i++) {
  $r = $p[$i]
  $sep = if ($i -lt $p.Count - 1) { ',' } else { '' }
  $o.Add("    (SpellType: $($r[1]); ManaCost: $($r[2]); Time: $(SingleOf $r[3]); Range: $($r[4]); MappedUnit: $($r[5]))$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
[IO.File]::WriteAllLines((Join-Path $OutDir 'DelphiDoom.War.Model.StatData.pas'), $o, (New-Object System.Text.UTF8Encoding($false)))

# ---- ActionData
$a = New-Object System.Collections.Generic.List[string]
$h = Header 'actions of the unit types'
$h[2] = '{  DelphiDoom: war library - what each unit type can do (GENERATED)             }'
$a.AddRange([string[]]$h)
$a.Add('unit DelphiDoom.War.Model.ActionData;')
$a.Add('')
$a.Add('interface')
$a.Add('')
$a.Add('const')
$a.Add('  /// <summary>')
$a.Add('  ///   gUnitActionDefs of war_actions.c: for each unit type (rows) and each action (idle, walk, attack, death, harvest,')
$a.Add('  ///   repair, build) the duration in frames (the sum of the wait steps) or -1 if the unit type has no such action')
$a.Add('  /// </summary>')
$rows = @(Rows 'A')
$a.Add("  WAR_ACTION_DURATIONS: array[0..$($rows.Count - 1), 0..6] of Integer = (")
for ($i = 0; $i -lt $rows.Count; $i++) {
  $r = $rows[$i]
  $vals = for ($k = 2; $k -lt 9; $k++) { $pair = $r[$k].Split(','); if ($pair[0] -eq '1') { $pair[1] } else { '-1' } }
  $sep = if ($i -lt $rows.Count - 1) { ',' } else { '' }
  $a.Add("    ($($vals -join ', '))$sep")
}
$a.Add('  );')
$a.Add('')
$a.Add('implementation')
$a.Add('')
$a.Add('end.')
[IO.File]::WriteAllLines((Join-Path $OutDir 'DelphiDoom.War.Model.ActionData.pas'), $a, (New-Object System.Text.UTF8Encoding($false)))
"Scritti StatData ($($u.Count) unita', $($b.Count) edifici, $($g.Count) miglioramenti, $($p.Count) incantesimi) e ActionData ($($rows.Count) tipi)"
