{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - statistics of units, upgrades and spells (GENERATED)}
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c and war_actions.c, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Written by Tools\Verifica\194\Make-WarModelTables.ps1 from the output of    }
{  the original C code (Tests\Data\War\model.tables.golden.txt): do not edit   }
{  by hand                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.StatData;

interface

uses
  DelphiDoom.War.Model.Stats.Types;

const
  /// <summary>unitStats of war_units.c: the 28 unit types that move</summary>
  WAR_UNIT_STAT_DATA: array[0..27] of TWarUnitStatsFull = (
    (UnitType: 0; Range: 1; Sight: 2; Armor: 2; Hp: 60; Mana: -1; MinDamage: 1; RndDamage: 9; BuildTime: 48; GoldCost: 400; WoodCost: 0; Decay: -1; Speeds: (16.736, 16.736, 16.736)),
    (UnitType: 1; Range: 1; Sight: 2; Armor: 2; Hp: 60; Mana: -1; MinDamage: 1; RndDamage: 9; BuildTime: 48; GoldCost: 400; WoodCost: 0; Decay: -1; Speeds: (16.736, 16.736, 16.736)),
    (UnitType: 2; Range: 1; Sight: 2; Armor: 0; Hp: 40; Mana: -1; MinDamage: 0; RndDamage: 0; BuildTime: 60; GoldCost: 400; WoodCost: 0; Decay: -1; Speeds: (19.584, 19.584, 19.584)),
    (UnitType: 3; Range: 1; Sight: 2; Armor: 0; Hp: 40; Mana: -1; MinDamage: 0; RndDamage: 0; BuildTime: 60; GoldCost: 400; WoodCost: 0; Decay: -1; Speeds: (19.584, 19.584, 19.584)),
    (UnitType: 4; Range: 8; Sight: 5; Armor: 0; Hp: 120; Mana: -1; MinDamage: 0; RndDamage: 255; BuildTime: 80; GoldCost: 900; WoodCost: 200; Decay: -1; Speeds: (8.992, 8.992, 8.992)),
    (UnitType: 5; Range: 8; Sight: 5; Armor: 0; Hp: 120; Mana: -1; MinDamage: 0; RndDamage: 255; BuildTime: 80; GoldCost: 900; WoodCost: 200; Decay: -1; Speeds: (8.992, 8.992, 8.992)),
    (UnitType: 6; Range: 1; Sight: 4; Armor: 5; Hp: 90; Mana: -1; MinDamage: 1; RndDamage: 13; BuildTime: 64; GoldCost: 850; WoodCost: 0; Decay: -1; Speeds: (19.584, 22.064, 26.064)),
    (UnitType: 7; Range: 1; Sight: 4; Armor: 5; Hp: 90; Mana: -1; MinDamage: 1; RndDamage: 13; BuildTime: 64; GoldCost: 850; WoodCost: 0; Decay: -1; Speeds: (19.584, 22.064, 26.064)),
    (UnitType: 8; Range: 5; Sight: 5; Armor: 1; Hp: 60; Mana: -1; MinDamage: 4; RndDamage: 0; BuildTime: 56; GoldCost: 450; WoodCost: 50; Decay: -1; Speeds: (19.584, 19.584, 19.584)),
    (UnitType: 9; Range: 4; Sight: 4; Armor: 1; Hp: 60; Mana: -1; MinDamage: 5; RndDamage: 0; BuildTime: 56; GoldCost: 450; WoodCost: 50; Decay: -1; Speeds: (19.584, 19.584, 19.584)),
    (UnitType: 10; Range: 3; Sight: 4; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; BuildTime: 72; GoldCost: 900; WoodCost: 0; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 11; Range: 2; Sight: 3; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; BuildTime: 72; GoldCost: 900; WoodCost: 0; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 12; Range: 1; Sight: 3; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; BuildTime: 64; GoldCost: 700; WoodCost: 0; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 13; Range: 2; Sight: 3; Armor: 0; Hp: 40; Mana: 255; MinDamage: 6; RndDamage: 0; BuildTime: 64; GoldCost: 700; WoodCost: 0; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 14; Range: 5; Sight: 5; Armor: 0; Hp: 110; Mana: -1; MinDamage: 10; RndDamage: 0; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (19.584, 19.584, 19.584)),
    (UnitType: 15; Range: 1; Sight: 2; Armor: 5; Hp: 50; Mana: -1; MinDamage: 1; RndDamage: 15; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (19.584, 19.584, 19.584)),
    (UnitType: 17; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: -1; MinDamage: -1; RndDamage: -1; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 18; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: -1; MinDamage: -1; RndDamage: -1; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 19; Range: 1; Sight: 2; Armor: 3; Hp: 60; Mana: -1; MinDamage: 1; RndDamage: 12; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (17.936, 17.936, 17.936)),
    (UnitType: 20; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: 255; MinDamage: 1; RndDamage: 3; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: 45; Speeds: (26.064, 26.064, 26.064)),
    (UnitType: 21; Range: 1; Sight: 2; Armor: 10; Hp: 150; Mana: -1; MinDamage: 1; RndDamage: 0; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (26.064, 26.064, 26.064)),
    (UnitType: 22; Range: 1; Sight: 2; Armor: 0; Hp: 200; Mana: -1; MinDamage: 0; RndDamage: 40; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (17.936, 17.936, 17.936)),
    (UnitType: 23; Range: 1; Sight: 2; Armor: 0; Hp: 30; Mana: 255; MinDamage: 3; RndDamage: 0; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: 45; Speeds: (26.064, 26.064, 26.064)),
    (UnitType: 24; Range: 1; Sight: 2; Armor: 1; Hp: 40; Mana: -1; MinDamage: 1; RndDamage: 9; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (16.736, 16.736, 16.736)),
    (UnitType: 25; Range: 1; Sight: 2; Armor: 2; Hp: 30; Mana: 255; MinDamage: 1; RndDamage: 9; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: -1; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 26; Range: 1; Sight: 2; Armor: 1; Hp: 40; Mana: -1; MinDamage: 1; RndDamage: 4; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: 45; Speeds: (13.984, 13.984, 13.984)),
    (UnitType: 27; Range: 1; Sight: 2; Armor: 0; Hp: 300; Mana: 255; MinDamage: 0; RndDamage: 65; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: 45; Speeds: (17.936, 17.936, 17.936)),
    (UnitType: 28; Range: 3; Sight: 4; Armor: 0; Hp: 250; Mana: 255; MinDamage: 40; RndDamage: 0; BuildTime: -1; GoldCost: -1; WoodCost: -1; Decay: 45; Speeds: (17.936, 17.936, 17.936))
  );

  /// <summary>buildingStats of war_units.c: the 19 buildings (the gold mine included)</summary>
  WAR_BUILDING_STAT_DATA: array[0..18] of TWarBuildingStatsFull = (
    (UnitType: 32; Armor: 0; Sight: 2; Hp: 400; BuildTime: 80; GoldCost: 500; WoodCost: 300),
    (UnitType: 33; Armor: 0; Sight: 2; Hp: 400; BuildTime: 80; GoldCost: 500; WoodCost: 300),
    (UnitType: 34; Armor: 0; Sight: 3; Hp: 800; BuildTime: 120; GoldCost: 600; WoodCost: 500),
    (UnitType: 35; Armor: 0; Sight: 3; Hp: 800; BuildTime: 120; GoldCost: 600; WoodCost: 500),
    (UnitType: 36; Armor: 0; Sight: 3; Hp: 700; BuildTime: 160; GoldCost: 800; WoodCost: 500),
    (UnitType: 37; Armor: 0; Sight: 3; Hp: 700; BuildTime: 160; GoldCost: 800; WoodCost: 500),
    (UnitType: 38; Armor: 0; Sight: 2; Hp: 900; BuildTime: 160; GoldCost: 1400; WoodCost: 300),
    (UnitType: 39; Armor: 0; Sight: 2; Hp: 900; BuildTime: 160; GoldCost: 1400; WoodCost: 300),
    (UnitType: 40; Armor: 0; Sight: 3; Hp: 2500; BuildTime: 80; GoldCost: 400; WoodCost: 400),
    (UnitType: 41; Armor: 0; Sight: 3; Hp: 2500; BuildTime: 80; GoldCost: 400; WoodCost: 400),
    (UnitType: 42; Armor: 0; Sight: 3; Hp: 600; BuildTime: 120; GoldCost: 600; WoodCost: 500),
    (UnitType: 43; Armor: 0; Sight: 3; Hp: 600; BuildTime: 120; GoldCost: 600; WoodCost: 500),
    (UnitType: 44; Armor: 0; Sight: 3; Hp: 500; BuildTime: 120; GoldCost: 1000; WoodCost: 400),
    (UnitType: 45; Armor: 0; Sight: 3; Hp: 500; BuildTime: 120; GoldCost: 1000; WoodCost: 400),
    (UnitType: 46; Armor: 0; Sight: 2; Hp: 800; BuildTime: 120; GoldCost: 900; WoodCost: 400),
    (UnitType: 47; Armor: 0; Sight: 2; Hp: 800; BuildTime: 120; GoldCost: 900; WoodCost: 400),
    (UnitType: 48; Armor: 0; Sight: 4; Hp: 5000; BuildTime: -1; GoldCost: -1; WoodCost: -1),
    (UnitType: 49; Armor: 0; Sight: 4; Hp: 5000; BuildTime: -1; GoldCost: -1; WoodCost: -1),
    (UnitType: 50; Armor: 0; Sight: 3; Hp: 25500; BuildTime: -1; GoldCost: -1; WoodCost: -1)
  );

  /// <summary>upgradeStats and upgradesData of war_units.c: the 19 upgrades</summary>
  WAR_UPGRADE_STAT_DATA: array[0..18] of TWarUpgradeStats = (
    (UpgradeType: 0; BuildTime: 128; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2),
    (UpgradeType: 1; BuildTime: 128; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2),
    (UpgradeType: 2; BuildTime: 140; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2),
    (UpgradeType: 3; BuildTime: 140; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2),
    (UpgradeType: 4; BuildTime: 140; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2),
    (UpgradeType: 5; BuildTime: 140; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2),
    (UpgradeType: 6; BuildTime: 140; GoldCost1: 750; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 7; BuildTime: 140; GoldCost1: 750; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 8; BuildTime: 140; GoldCost1: 1500; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 9; BuildTime: 140; GoldCost1: 1500; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 10; BuildTime: 140; GoldCost1: 3000; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 11; BuildTime: 140; GoldCost1: 3000; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 12; BuildTime: 128; GoldCost1: 750; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 13; BuildTime: 128; GoldCost1: 750; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 14; BuildTime: 128; GoldCost1: 1500; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 15; BuildTime: 128; GoldCost1: 1500; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 16; BuildTime: 128; GoldCost1: 3000; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 17; BuildTime: 128; GoldCost1: 3000; GoldCost2: 0; MaxLevel: 1),
    (UpgradeType: 18; BuildTime: 128; GoldCost1: 750; GoldCost2: 1500; MaxLevel: 2)
  );

  /// <summary>spellStats and spellMappings of war_units.c: the 12 spells and summons (MappedUnit -1 if it does not summon)</summary>
  WAR_SPELL_STAT_DATA: array[0..11] of TWarSpellStats = (
    (SpellType: 8; ManaCost: 51; Time: 0.0; Range: 0; MappedUnit: 20),
    (SpellType: 9; ManaCost: 51; Time: 0.0; Range: 0; MappedUnit: 23),
    (SpellType: 10; ManaCost: 255; Time: 0.0; Range: 0; MappedUnit: 27),
    (SpellType: 11; ManaCost: 250; Time: 0.0; Range: 0; MappedUnit: 28),
    (SpellType: 0; ManaCost: 6; Time: 0.0; Range: 6; MappedUnit: -1),
    (SpellType: 1; ManaCost: 70; Time: 10; Range: 0; MappedUnit: -1),
    (SpellType: 2; ManaCost: 200; Time: 50; Range: 6; MappedUnit: -1),
    (SpellType: 3; ManaCost: 25; Time: 0.0; Range: 12; MappedUnit: -1),
    (SpellType: 5; ManaCost: 50; Time: 0.0; Range: 6; MappedUnit: -1),
    (SpellType: 6; ManaCost: 50; Time: 10; Range: 0; MappedUnit: -1),
    (SpellType: 7; ManaCost: 100; Time: 13; Range: 6; MappedUnit: -1),
    (SpellType: 4; ManaCost: 100; Time: 10; Range: 12; MappedUnit: -1)
  );

implementation

end.
