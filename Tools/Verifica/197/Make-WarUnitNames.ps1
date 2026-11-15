<#
  Issue #197: scrive Libs\War\DelphiDoom.War.MapUi.UnitNames.Data.pas dal codice ORIGINALE (Reference\war1\src\war_units.c, la
  tabella unitsData, e war_enums.h, l'enum dei ritratti): il nome che il pannello mostra e il fotogramma del ritratto (record
  361) di ogni tipo di unita'. Nessuna modifica a mano: se il C cambia si rifa.

  Uso:  powershell -NoProfile -File Tools\Verifica\197\Make-WarUnitNames.ps1 [-War1 <...\Reference\war1>]
#>
param([string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1')
$ErrorActionPreference = 'Stop'
$units = [IO.File]::ReadAllText((Join-Path $War1 'src\war_units.c'))
$enums = [IO.File]::ReadAllText((Join-Path $War1 'src\war_enums.h'))

# i ritratti: l'enum _WarUnitPortraits, in ordine, da 0
$m = [regex]::Match($enums, 'typedef enum _WarUnitPortraits\s*\{(.*?)\}', 'Singleline')
$portrait = @{}
$index = 0
foreach ($line in $m.Groups[1].Value -split "`n") {
  $t = $line.Trim().TrimEnd(',')
  if ($t -match '^(WAR_PORTRAIT_\w+)$') { $portrait[$Matches[1]] = $index; $index++ }
}
if ($portrait.Count -lt 60) { throw "Ritratti letti: $($portrait.Count)" }

$rows = New-Object System.Collections.Generic.List[string]
$regex = '\{\s*(WAR_UNIT_\w+)\s*,\s*\d+\s*,\s*(WAR_PORTRAIT_\w+|0)\s*,\s*\d+\s*,\s*\d+\s*,\s*WSV_INIT\("([^"]*)"\)\s*\}'
foreach ($r in [regex]::Matches($units, $regex)) {
  $frame = if ($r.Groups[2].Value -eq '0') { 0 } else { $portrait[$r.Groups[2].Value] }
  $rows.Add("    (UnitType: $($r.Groups[1].Value); Portrait: $frame; Name: '$($r.Groups[3].Value)')")
}
if ($rows.Count -ne 50) { throw "Unita' lette: $($rows.Count), ne servono 50" }

$out = @'
{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - names and portraits of the units (GENERATED)       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c (unitsData) and war_enums.h, (c)    }
{  2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Written by Tools\Verifica\197\Make-WarUnitNames.ps1 from the original C     }
{  code: do not edit by hand                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.UnitNames.Data;

interface

uses
  DelphiDoom.War.Level.Types;

type
  /// <summary>The name that the panel shows for a unit type and the frame of its portrait (the record 361)</summary>
  TWarUnitName = record
    UnitType: Integer;
    Portrait: Integer;
    Name: AnsiString;
  end;

const
  /// <summary>unitsData of war_units.c: one row for each of the 50 unit types, in the order of the table</summary>
  WAR_UNIT_NAMES: array[0..49] of TWarUnitName = (
'@
$out += "`n" + ($rows -join ",`n") + "`n  );`n"
# and the whole enum of the portraits (the frames of the record 361 that the command buttons use too)
$constants = ($portrait.GetEnumerator() | Sort-Object Value | ForEach-Object { "  $($_.Key) = $($_.Value);" }) -join "`n"
$out += "`n  // _WarUnitPortraits of war_enums.h: the frame of the record 361`n$constants`n`nimplementation`n`nend.`n"
$root = Split-Path (Split-Path (Split-Path $PSScriptRoot))
[IO.File]::WriteAllText((Join-Path $root 'Libs\War\DelphiDoom.War.MapUi.UnitNames.Data.pas'), ($out -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
"scritte $($rows.Count) righe"
