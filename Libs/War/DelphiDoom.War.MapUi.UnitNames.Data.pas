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
    (UnitType: WAR_UNIT_FOOTMAN; Portrait: 0; Name: 'FOOTMAN'),
    (UnitType: WAR_UNIT_GRUNT; Portrait: 1; Name: 'GRUNT'),
    (UnitType: WAR_UNIT_PEASANT; Portrait: 4; Name: 'PEASANT'),
    (UnitType: WAR_UNIT_PEON; Portrait: 5; Name: 'PEON'),
    (UnitType: WAR_UNIT_CATAPULT_HUMANS; Portrait: 6; Name: 'CATAPULT'),
    (UnitType: WAR_UNIT_CATAPULT_ORCS; Portrait: 7; Name: 'CATAPULT'),
    (UnitType: WAR_UNIT_KNIGHT; Portrait: 8; Name: 'KNIGHT'),
    (UnitType: WAR_UNIT_RAIDER; Portrait: 9; Name: 'RAIDER'),
    (UnitType: WAR_UNIT_ARCHER; Portrait: 10; Name: 'ARCHER'),
    (UnitType: WAR_UNIT_SPEARMAN; Portrait: 11; Name: 'SPEARMAN'),
    (UnitType: WAR_UNIT_CONJURER; Portrait: 2; Name: 'CONJURER'),
    (UnitType: WAR_UNIT_WARLOCK; Portrait: 3; Name: 'WARLOCK'),
    (UnitType: WAR_UNIT_CLERIC; Portrait: 12; Name: 'CLERIC'),
    (UnitType: WAR_UNIT_NECROLYTE; Portrait: 13; Name: 'NECROLYTE'),
    (UnitType: WAR_UNIT_MEDIVH; Portrait: 54; Name: 'MEDIVH'),
    (UnitType: WAR_UNIT_LOTHAR; Portrait: 53; Name: 'LOTHAR'),
    (UnitType: WAR_UNIT_WOUNDED; Portrait: 57; Name: 'WOUNDED'),
    (UnitType: WAR_UNIT_GRIZELDA; Portrait: 55; Name: 'GRIZELDA'),
    (UnitType: WAR_UNIT_GARONA; Portrait: 56; Name: 'GARONA'),
    (UnitType: WAR_UNIT_OGRE; Portrait: 44; Name: 'OGRE'),
    (UnitType: WAR_UNIT_SPIDER; Portrait: 45; Name: 'SPIDER'),
    (UnitType: WAR_UNIT_SLIME; Portrait: 46; Name: 'SLIME'),
    (UnitType: WAR_UNIT_FIRE_ELEMENTAL; Portrait: 47; Name: 'FIRE ELEM'),
    (UnitType: WAR_UNIT_SCORPION; Portrait: 48; Name: 'SCORPION'),
    (UnitType: WAR_UNIT_BRIGAND; Portrait: 58; Name: 'BRIGAND'),
    (UnitType: WAR_UNIT_THE_DEAD; Portrait: 50; Name: 'THE DEAD'),
    (UnitType: WAR_UNIT_SKELETON; Portrait: 49; Name: 'SKELETON'),
    (UnitType: WAR_UNIT_DAEMON; Portrait: 51; Name: 'DAEMON'),
    (UnitType: WAR_UNIT_WATER_ELEMENTAL; Portrait: 52; Name: 'WATER ELEM'),
    (UnitType: WAR_UNIT_FARM_HUMANS; Portrait: 14; Name: 'FARM'),
    (UnitType: WAR_UNIT_FARM_ORCS; Portrait: 15; Name: 'FARM'),
    (UnitType: WAR_UNIT_BARRACKS_HUMANS; Portrait: 16; Name: 'BARRACKS'),
    (UnitType: WAR_UNIT_BARRACKS_ORCS; Portrait: 17; Name: 'BARRACKS'),
    (UnitType: WAR_UNIT_CHURCH; Portrait: 28; Name: 'CHURCH'),
    (UnitType: WAR_UNIT_TEMPLE; Portrait: 29; Name: 'TEMPLE'),
    (UnitType: WAR_UNIT_TOWER_HUMANS; Portrait: 18; Name: 'TOWER'),
    (UnitType: WAR_UNIT_TOWER_ORCS; Portrait: 19; Name: 'TOWER'),
    (UnitType: WAR_UNIT_TOWNHALL_HUMANS; Portrait: 20; Name: 'TOWN HALL'),
    (UnitType: WAR_UNIT_TOWNHALL_ORCS; Portrait: 21; Name: 'TOWN HALL'),
    (UnitType: WAR_UNIT_LUMBERMILL_HUMANS; Portrait: 22; Name: 'MILL'),
    (UnitType: WAR_UNIT_LUMBERMILL_ORCS; Portrait: 23; Name: 'MILL'),
    (UnitType: WAR_UNIT_STABLE; Portrait: 24; Name: 'STABLES'),
    (UnitType: WAR_UNIT_KENNEL; Portrait: 25; Name: 'KENNEL'),
    (UnitType: WAR_UNIT_BLACKSMITH_HUMANS; Portrait: 26; Name: 'BLACKSMITH'),
    (UnitType: WAR_UNIT_BLACKSMITH_ORCS; Portrait: 27; Name: 'BLACKSMITH'),
    (UnitType: WAR_UNIT_STORMWIND; Portrait: 31; Name: 'STORMWIND'),
    (UnitType: WAR_UNIT_BLACKROCK; Portrait: 32; Name: 'BLACKROCK'),
    (UnitType: WAR_UNIT_GOLDMINE; Portrait: 30; Name: 'GOLD MINE'),
    (UnitType: WAR_UNIT_HUMAN_CORPSE; Portrait: 0; Name: 'CORPSE'),
    (UnitType: WAR_UNIT_ORC_CORPSE; Portrait: 0; Name: 'CORPSE')
  );

  // _WarUnitPortraits of war_enums.h: the frame of the record 361
  WAR_PORTRAIT_FOOTMAN = 0;
  WAR_PORTRAIT_GRUNT = 1;
  WAR_PORTRAIT_CONJURER = 2;
  WAR_PORTRAIT_WARLOCK = 3;
  WAR_PORTRAIT_PEASANT = 4;
  WAR_PORTRAIT_PEON = 5;
  WAR_PORTRAIT_CATAPULT_HUMANS = 6;
  WAR_PORTRAIT_CATAPULT_ORCS = 7;
  WAR_PORTRAIT_KNIGHT = 8;
  WAR_PORTRAIT_RAIDER = 9;
  WAR_PORTRAIT_ARCHER = 10;
  WAR_PORTRAIT_SPEARMAN = 11;
  WAR_PORTRAIT_CLERIC = 12;
  WAR_PORTRAIT_NECROLYTE = 13;
  WAR_PORTRAIT_FARM_HUMANS = 14;
  WAR_PORTRAIT_FARM_ORCS = 15;
  WAR_PORTRAIT_BARRACKS_HUMANS = 16;
  WAR_PORTRAIT_BARRACKS_ORCS = 17;
  WAR_PORTRAIT_TOWER_HUMANS = 18;
  WAR_PORTRAIT_TOWER_ORCS = 19;
  WAR_PORTRAIT_TOWNHALL_HUMANS = 20;
  WAR_PORTRAIT_TOWNHALL_ORCS = 21;
  WAR_PORTRAIT_LUMBERMILL_HUMANS = 22;
  WAR_PORTRAIT_LUMBERMILL_ORCS = 23;
  WAR_PORTRAIT_STABLE = 24;
  WAR_PORTRAIT_KENNEL = 25;
  WAR_PORTRAIT_BLACKSMITH_HUMANS = 26;
  WAR_PORTRAIT_BLACKSMITH_ORCS = 27;
  WAR_PORTRAIT_CHURCH = 28;
  WAR_PORTRAIT_TEMPLE = 29;
  WAR_PORTRAIT_GOLDMINE = 30;
  WAR_PORTRAIT_STORMWIND = 31;
  WAR_PORTRAIT_BLACKROCK = 32;
  WAR_PORTRAIT_MOVE_HUMANS = 33;
  WAR_PORTRAIT_MOVE_ORCS = 34;
  WAR_PORTRAIT_REPAIR = 35;
  WAR_PORTRAIT_HARVEST = 36;
  WAR_PORTRAIT_BUILD_BASIC = 37;
  WAR_PORTRAIT_BUILD_ADVANCED = 38;
  WAR_PORTRAIT_DELIVER = 39;
  WAR_PORTRAIT_CANCEL = 40;
  WAR_PORTRAIT_WALL = 41;
  WAR_PORTRAIT_ROAD = 42;
  WAR_PORTRAIT_UNKOWN = 43;
  WAR_PORTRAIT_OGRE = 44;
  WAR_PORTRAIT_SPIDER = 45;
  WAR_PORTRAIT_SLIME = 46;
  WAR_PORTRAIT_FIRE_ELEMENTAL = 47;
  WAR_PORTRAIT_SCORPION = 48;
  WAR_PORTRAIT_SKELETON = 49;
  WAR_PORTRAIT_DEAD = 50;
  WAR_PORTRAIT_DAEMON = 51;
  WAR_PORTRAIT_WATER_ELEMENTAL = 52;
  WAR_PORTRAIT_LOTHAR = 53;
  WAR_PORTRAIT_MEDIVH = 54;
  WAR_PORTRAIT_GRIZELDA = 55;
  WAR_PORTRAIT_GARONA = 56;
  WAR_PORTRAIT_WOUNDED = 57;
  WAR_PORTRAIT_BRIGAND = 58;
  WAR_PORTRAIT_HOLY_LANCE = 59;
  WAR_PORTRAIT_ELEMENTAL_BLAST = 60;
  WAR_PORTRAIT_SHADOW_SPEAR = 61;
  WAR_PORTRAIT_FIREBALL = 62;
  WAR_PORTRAIT_SWORD_1 = 63;
  WAR_PORTRAIT_SWORD_2 = 64;
  WAR_PORTRAIT_SWORD_3 = 65;
  WAR_PORTRAIT_AXE_1 = 66;
  WAR_PORTRAIT_AXE_2 = 67;
  WAR_PORTRAIT_AXE_3 = 68;
  WAR_PORTRAIT_WOLVES_1 = 69;
  WAR_PORTRAIT_WOLVES_2 = 70;
  WAR_PORTRAIT_ARROW_1 = 71;
  WAR_PORTRAIT_ARROW_2 = 72;
  WAR_PORTRAIT_ARROW_3 = 73;
  WAR_PORTRAIT_SPEAR_1 = 74;
  WAR_PORTRAIT_SPEAR_2 = 75;
  WAR_PORTRAIT_SPEAR_3 = 76;
  WAR_PORTRAIT_HORSE_1 = 77;
  WAR_PORTRAIT_HORSE_2 = 78;
  WAR_PORTRAIT_SHIELD_1_HUMANS = 79;
  WAR_PORTRAIT_SHIELD_2_HUMANS = 80;
  WAR_PORTRAIT_SHIELD_3_HUMANS = 81;
  WAR_PORTRAIT_SHIELD_1_ORCS = 82;
  WAR_PORTRAIT_SHIELD_2_ORCS = 83;
  WAR_PORTRAIT_SHIELD_3_ORCS = 84;
  WAR_PORTRAIT_HEALING = 85;
  WAR_PORTRAIT_FAR_SIGHT = 86;
  WAR_PORTRAIT_INVISIBILITY = 87;
  WAR_PORTRAIT_RAIN_OF_FIRE = 88;
  WAR_PORTRAIT_RAISE_DEAD = 89;
  WAR_PORTRAIT_DARK_VISION = 90;
  WAR_PORTRAIT_UNHOLY_ARMOR = 91;
  WAR_PORTRAIT_POISON_CLOUD = 92;

implementation

end.
