{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - tables of the units (GENERATED)                    }
{                                                                              }
{  Port of war1 (acoto87/war1), unitsData, unitStats and buildingStats of      }
{  war_units.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see            }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Written by Tools\Verifica\193\Make-WarMapTables.ps1 from the output of the  }
{  original C code (Tests\Data\War\map.tables.golden.txt): do not edit by hand }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.UnitData;

interface

uses
  DelphiDoom.War.Map.Types;

const
  /// <summary>unitsData: the sprite record and the size of 50 unit types</summary>
  WAR_UNIT_DATA: array[0..49] of TWarUnitData = (
    (UnitType: 0; ResourceIndex: 279; SizeX: 1; SizeY: 1),
    (UnitType: 1; ResourceIndex: 280; SizeX: 1; SizeY: 1),
    (UnitType: 2; ResourceIndex: 281; SizeX: 1; SizeY: 1),
    (UnitType: 3; ResourceIndex: 282; SizeX: 1; SizeY: 1),
    (UnitType: 4; ResourceIndex: 283; SizeX: 1; SizeY: 1),
    (UnitType: 5; ResourceIndex: 284; SizeX: 1; SizeY: 1),
    (UnitType: 6; ResourceIndex: 285; SizeX: 1; SizeY: 1),
    (UnitType: 7; ResourceIndex: 286; SizeX: 1; SizeY: 1),
    (UnitType: 8; ResourceIndex: 287; SizeX: 1; SizeY: 1),
    (UnitType: 9; ResourceIndex: 288; SizeX: 1; SizeY: 1),
    (UnitType: 10; ResourceIndex: 289; SizeX: 1; SizeY: 1),
    (UnitType: 11; ResourceIndex: 290; SizeX: 1; SizeY: 1),
    (UnitType: 12; ResourceIndex: 291; SizeX: 1; SizeY: 1),
    (UnitType: 13; ResourceIndex: 292; SizeX: 1; SizeY: 1),
    (UnitType: 14; ResourceIndex: 293; SizeX: 1; SizeY: 1),
    (UnitType: 15; ResourceIndex: 294; SizeX: 1; SizeY: 1),
    (UnitType: 16; ResourceIndex: 295; SizeX: 1; SizeY: 1),
    (UnitType: 17; ResourceIndex: 296; SizeX: 1; SizeY: 1),
    (UnitType: 18; ResourceIndex: 296; SizeX: 1; SizeY: 1),
    (UnitType: 19; ResourceIndex: 297; SizeX: 1; SizeY: 1),
    (UnitType: 20; ResourceIndex: 298; SizeX: 1; SizeY: 1),
    (UnitType: 21; ResourceIndex: 299; SizeX: 1; SizeY: 1),
    (UnitType: 22; ResourceIndex: 300; SizeX: 1; SizeY: 1),
    (UnitType: 23; ResourceIndex: 301; SizeX: 1; SizeY: 1),
    (UnitType: 24; ResourceIndex: 302; SizeX: 1; SizeY: 1),
    (UnitType: 25; ResourceIndex: 303; SizeX: 1; SizeY: 1),
    (UnitType: 26; ResourceIndex: 304; SizeX: 1; SizeY: 1),
    (UnitType: 27; ResourceIndex: 305; SizeX: 1; SizeY: 1),
    (UnitType: 28; ResourceIndex: 306; SizeX: 1; SizeY: 1),
    (UnitType: 32; ResourceIndex: 307; SizeX: 2; SizeY: 2),
    (UnitType: 33; ResourceIndex: 308; SizeX: 2; SizeY: 2),
    (UnitType: 34; ResourceIndex: 309; SizeX: 3; SizeY: 3),
    (UnitType: 35; ResourceIndex: 310; SizeX: 3; SizeY: 3),
    (UnitType: 36; ResourceIndex: 311; SizeX: 3; SizeY: 3),
    (UnitType: 37; ResourceIndex: 312; SizeX: 3; SizeY: 3),
    (UnitType: 38; ResourceIndex: 313; SizeX: 2; SizeY: 2),
    (UnitType: 39; ResourceIndex: 314; SizeX: 2; SizeY: 2),
    (UnitType: 40; ResourceIndex: 315; SizeX: 3; SizeY: 3),
    (UnitType: 41; ResourceIndex: 316; SizeX: 3; SizeY: 3),
    (UnitType: 42; ResourceIndex: 317; SizeX: 3; SizeY: 3),
    (UnitType: 43; ResourceIndex: 318; SizeX: 3; SizeY: 3),
    (UnitType: 44; ResourceIndex: 319; SizeX: 3; SizeY: 3),
    (UnitType: 45; ResourceIndex: 320; SizeX: 3; SizeY: 3),
    (UnitType: 46; ResourceIndex: 321; SizeX: 2; SizeY: 2),
    (UnitType: 47; ResourceIndex: 322; SizeX: 2; SizeY: 2),
    (UnitType: 48; ResourceIndex: 323; SizeX: 4; SizeY: 4),
    (UnitType: 49; ResourceIndex: 324; SizeX: 4; SizeY: 4),
    (UnitType: 50; ResourceIndex: 325; SizeX: 3; SizeY: 3),
    (UnitType: 52; ResourceIndex: 326; SizeX: 1; SizeY: 1),
    (UnitType: 53; ResourceIndex: 326; SizeX: 1; SizeY: 1)
  );

  /// <summary>unitStats: the 28 unit types that move</summary>
  WAR_UNIT_STATS: array[0..27] of TWarUnitStats = (
    (UnitType: 0; Range: 1; Sight: 2; Armor: 2; Hp: 60; Mana: -1; MinDamage: 1; RndDamage: 9; Decay: -1),
    (UnitType: 1; Range: 1; Sight: 2; Armor: 2; Hp: 60; Mana: -1; MinDamage: 1; RndDamage: 9; Decay: -1),
    (UnitType: 2; Range: 1; Sight: 2; Armor: 0; Hp: 40; Mana: -1; MinDamage: 0; RndDamage: 0; Decay: -1),
    (UnitType: 3; Range: 1; Sight: 2; Armor: 0; Hp: 40; Mana: -1; MinDamage: 0; RndDamage: 0; Decay: -1),
    (UnitType: 4; Range: 8; Sight: 5; Armor: 0; Hp: 120; Mana: -1; MinDamage: 0; RndDamage: 255; Decay: -1),
    (UnitType: 5; Range: 8; Sight: 5; Armor: 0; Hp: 120; Mana: -1; MinDamage: 0; RndDamage: 255; Decay: -1),
    (UnitType: 6; Range: 1; Sight: 4; Armor: 5; Hp: 90; Mana: -1; MinDamage: 1; RndDamage: 13; Decay: -1),
    (UnitType: 7; Range: 1; Sight: 4; Armor: 5; Hp: 90; Mana: -1; MinDamage: 1; RndDamage: 13; Decay: -1),
    (UnitType: 8; Range: 5; Sight: 5; Armor: 1; Hp: 60; Mana: -1; MinDamage: 4; RndDamage: 0; Decay: -1),
    (UnitType: 9; Range: 4; Sight: 4; Armor: 1; Hp: 60; Mana: -1; MinDamage: 5; RndDamage: 0; Decay: -1),
    (UnitType: 10; Range: 3; Sight: 4; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; Decay: -1),
    (UnitType: 11; Range: 2; Sight: 3; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; Decay: -1),
    (UnitType: 12; Range: 1; Sight: 3; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; Decay: -1),
    (UnitType: 13; Range: 2; Sight: 3; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; Decay: -1),
    (UnitType: 14; Range: 5; Sight: 5; Armor: 0; Hp: 110; Mana: -1; MinDamage: 10; RndDamage: 0; Decay: -1),
    (UnitType: 15; Range: 1; Sight: 2; Armor: 5; Hp: 50; Mana: -1; MinDamage: 1; RndDamage: 15; Decay: -1),
    (UnitType: 17; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: -1; MinDamage: -1; RndDamage: -1; Decay: -1),
    (UnitType: 18; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: -1; MinDamage: -1; RndDamage: -1; Decay: -1),
    (UnitType: 19; Range: 1; Sight: 2; Armor: 3; Hp: 60; Mana: -1; MinDamage: 1; RndDamage: 12; Decay: -1),
    (UnitType: 20; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: 255; MinDamage: 1; RndDamage: 3; Decay: 45),
    (UnitType: 21; Range: 1; Sight: 2; Armor: 10; Hp: 150; Mana: -1; MinDamage: 1; RndDamage: 0; Decay: -1),
    (UnitType: 22; Range: 1; Sight: 2; Armor: 0; Hp: 200; Mana: -1; MinDamage: 0; RndDamage: 40; Decay: -1),
    (UnitType: 23; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: 255; MinDamage: 3; RndDamage: 0; Decay: 45),
    (UnitType: 24; Range: 1; Sight: 2; Armor: 1; Hp: 40; Mana: -1; MinDamage: 1; RndDamage: 9; Decay: -1),
    (UnitType: 25; Range: 1; Sight: 2; Armor: 2; Hp: 30; Mana: 255; MinDamage: 1; RndDamage: 9; Decay: -1),
    (UnitType: 26; Range: 1; Sight: 2; Armor: 1; Hp: 40; Mana: -1; MinDamage: 1; RndDamage: 4; Decay: 45),
    (UnitType: 27; Range: 1; Sight: 2; Armor: 0; Hp: 300; Mana: 255; MinDamage: 0; RndDamage: 65; Decay: 45),
    (UnitType: 28; Range: 3; Sight: 4; Armor: 0; Hp: 250; Mana: 255; MinDamage: 40; RndDamage: 0; Decay: 45)
  );

  /// <summary>buildingStats: the 19 building types (the gold mine included)</summary>
  WAR_BUILDING_STATS: array[0..18] of TWarBuildingStats = (
    (UnitType: 32; Armor: 0; Sight: 2; Hp: 400),
    (UnitType: 33; Armor: 0; Sight: 2; Hp: 400),
    (UnitType: 34; Armor: 0; Sight: 3; Hp: 800),
    (UnitType: 35; Armor: 0; Sight: 3; Hp: 800),
    (UnitType: 36; Armor: 0; Sight: 3; Hp: 700),
    (UnitType: 37; Armor: 0; Sight: 3; Hp: 700),
    (UnitType: 38; Armor: 0; Sight: 2; Hp: 900),
    (UnitType: 39; Armor: 0; Sight: 2; Hp: 900),
    (UnitType: 40; Armor: 0; Sight: 3; Hp: 2500),
    (UnitType: 41; Armor: 0; Sight: 3; Hp: 2500),
    (UnitType: 42; Armor: 0; Sight: 3; Hp: 600),
    (UnitType: 43; Armor: 0; Sight: 3; Hp: 600),
    (UnitType: 44; Armor: 0; Sight: 3; Hp: 500),
    (UnitType: 45; Armor: 0; Sight: 3; Hp: 500),
    (UnitType: 46; Armor: 0; Sight: 2; Hp: 800),
    (UnitType: 47; Armor: 0; Sight: 2; Hp: 800),
    (UnitType: 48; Armor: 0; Sight: 4; Hp: 5000),
    (UnitType: 49; Armor: 0; Sight: 4; Hp: 5000),
    (UnitType: 50; Armor: 0; Sight: 3; Hp: 25500)
  );

implementation

end.
