<#
  Issue #193 (seconda fetta): genera Libs\War\DelphiDoom.War.Map.UnitData.pas dalle tabelle delle unita' (unitsData,
  unitStats, buildingStats di war_units.c) che il C ORIGINALE ha scritto in Tests\Data\War\map.tables.golden.txt
  (Registra-GoldenMap.ps1). Non si modifica a mano il risultato.

  Uso: powershell -NoProfile -File Make-WarMapTables.ps1
#>
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$lines = [IO.File]::ReadAllLines((Join-Path $root 'Tests\Data\War\map.tables.golden.txt'))
$d = @(); $s = @(); $b = @()
foreach ($l in $lines) {
  $f = $l.Split(' ')
  switch ($f[0]) {
    'D' { $d += ,$f }
    'S' { $s += ,$f }
    'B' { $b += ,$f }
  }
}
function Rows($rows, [string[]]$names) {
  $out = @()
  for ($i = 0; $i -lt $rows.Count; $i++) {
    $parts = @()
    for ($k = 0; $k -lt $names.Count; $k++) { $parts += ('{0}: {1}' -f $names[$k], $rows[$i][$k + 1]) }
    $sep = if ($i -lt $rows.Count - 1) { ',' } else { '' }
    $out += ('    (' + ($parts -join '; ') + ')' + $sep)
  }
  $out
}
$text = @()
$text += '{******************************************************************************}'
$text += '{                                                                              }'
$text += '{  DelphiDoom: war library - tables of the units (GENERATED)                    }'
$text += '{                                                                              }'
$text += '{  Port of war1 (acoto87/war1), unitsData, unitStats and buildingStats of      }'
$text += '{  war_units.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see            }'
$text += '{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }'
$text += '{                                                                              }'
$text += '{  Written by Tools\Verifica\193\Make-WarMapTables.ps1 from the output of the  }'
$text += '{  original C code (Tests\Data\War\map.tables.golden.txt): do not edit by hand }'
$text += '{                                                                              }'
$text += '{  Licensed under the GNU General Public License, version 2 or later           }'
$text += '{                                                                              }'
$text += '{******************************************************************************}'
$text += 'unit DelphiDoom.War.Map.UnitData;'
$text += ''
$text += 'interface'
$text += ''
$text += 'uses'
$text += '  DelphiDoom.War.Map.Types;'
$text += ''
$text += 'const'
$text += ('  /// <summary>unitsData: the sprite record and the size of {0} unit types</summary>' -f $d.Count)
$text += ('  WAR_UNIT_DATA: array[0..{0}] of TWarUnitData = (' -f ($d.Count - 1))
$text += Rows $d @('UnitType', 'ResourceIndex', 'SizeX', 'SizeY')
$text += '  );'
$text += ''
$text += ('  /// <summary>unitStats: the {0} unit types that move</summary>' -f $s.Count)
$text += ('  WAR_UNIT_STATS: array[0..{0}] of TWarUnitStats = (' -f ($s.Count - 1))
$text += Rows $s @('UnitType', 'Range', 'Sight', 'Armor', 'Hp', 'Mana', 'MinDamage', 'RndDamage', 'Decay')
$text += '  );'
$text += ''
$text += ('  /// <summary>buildingStats: the {0} building types (the gold mine included)</summary>' -f $b.Count)
$text += ('  WAR_BUILDING_STATS: array[0..{0}] of TWarBuildingStats = (' -f ($b.Count - 1))
$text += Rows $b @('UnitType', 'Armor', 'Sight', 'Hp')
$text += '  );'
$text += ''
$text += 'implementation'
$text += ''
$text += 'end.'
[IO.File]::WriteAllText((Join-Path $root 'Libs\War\DelphiDoom.War.Map.UnitData.pas'), (($text -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)
"UnitData: $($d.Count) unita', $($s.Count) statistiche, $($b.Count) edifici"
