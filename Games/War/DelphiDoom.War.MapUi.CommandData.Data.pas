{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - data of the commands of the units (GENERATED)      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c (commandsBaseData, commandMappings, }
{  upgradesData, spellData) and war_enums.h, (c) 2019 Alejandro Coto Gutierrez, }
{  zlib License (see Games\War\LICENSE-war1.txt). This is an altered version,   }
{  not the original.                                                            }
{                                                                              }
{  Written by Tools\Verifica\197\Make-WarCommandData.ps1 from the original C    }
{  code: do not edit by hand                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandData.Data;

interface

uses
  DelphiDoom.War.Ui.Types;

type
  /// <summary>WarUnitCommandBaseData without the click handler (the type of the command says what the click does)</summary>
  TWarCommandBase = record
    CommandType: Integer;
    HotKey: TWarKey;
    HighlightIndex: Integer;
    HighlightCount: Integer;
    Tooltip: AnsiString;
    /// <summary>What the status line says while a building trains or researches it</summary>
    Tooltip2: AnsiString;
  end;

  /// <summary>WarUnitCommandMapping: the unit, upgrade or spell that a command is for</summary>
  TWarCommandMapping = record
    CommandType: Integer;
    MappedType: Integer;
  end;

  /// <summary>WarUpgradeData: the frames of the portraits of the levels of an upgrade</summary>
  TWarUpgradeFrames = record
    Levels: Integer;
    Frame1: Integer;
    Frame2: Integer;
  end;

const
  /// <summary>commandsBaseData: by the number of the command (the table of the original is in another order, searched by type)</summary>
  WAR_COMMAND_BASE: array[0..73] of TWarCommandBase = (    (CommandType: 0; HotKey: wkNone; HighlightIndex: -1; HighlightCount: 1; Tooltip: ''; Tooltip2: ''),
    (CommandType: 1; HotKey: wkM; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'MOVE'; Tooltip2: ''),
    (CommandType: 2; HotKey: wkS; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'STOP'; Tooltip2: ''),
    (CommandType: 3; HotKey: wkH; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'HARVEST LUMBER/MINE GOLD'; Tooltip2: ''),
    (CommandType: 4; HotKey: wkT; HighlightIndex: 16; HighlightCount: 1; Tooltip: 'RETURN GOODS TO TOWN HALL'; Tooltip2: ''),
    (CommandType: 5; HotKey: wkR; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'REPAIR'; Tooltip2: ''),
    (CommandType: 6; HotKey: wkA; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'ATTACK'; Tooltip2: ''),
    (CommandType: 7; HotKey: wkF; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN FOOTMAN'; Tooltip2: 'TRAINING A FOOTMAN'),
    (CommandType: 8; HotKey: wkU; HighlightIndex: 8; HighlightCount: 1; Tooltip: 'TRAIN GRUNT'; Tooltip2: 'TRAINING A GRUNT'),
    (CommandType: 9; HotKey: wkP; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN PEASANT'; Tooltip2: 'TRAINING A PEASANT'),
    (CommandType: 10; HotKey: wkP; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN PEON'; Tooltip2: 'TRAINING A PEON'),
    (CommandType: 11; HotKey: wkT; HighlightIndex: 8; HighlightCount: 1; Tooltip: 'BUILD CATAPULT'; Tooltip2: 'TRAINING A CATAPULT CREW'),
    (CommandType: 12; HotKey: wkT; HighlightIndex: 8; HighlightCount: 1; Tooltip: 'BUILD CATAPULT'; Tooltip2: 'TRAINING A CATAPULT CREW'),
    (CommandType: 13; HotKey: wkK; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN KNIGHT'; Tooltip2: 'TRAINING A KNIGHT'),
    (CommandType: 14; HotKey: wkR; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN RAIDER'; Tooltip2: 'TRAINING A RAIDER'),
    (CommandType: 15; HotKey: wkA; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN ARCHER'; Tooltip2: 'TRAINING AN ARCHER'),
    (CommandType: 16; HotKey: wkS; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'TRAIN SPEARMAN'; Tooltip2: 'TRAINING A SPEARMAN'),
    (CommandType: 17; HotKey: wkT; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'TRAIN CONJURER'; Tooltip2: 'TRAINING A CONJURER'),
    (CommandType: 18; HotKey: wkT; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'TRAIN WARLOCK'; Tooltip2: 'TRAINING A WARLOCK'),
    (CommandType: 19; HotKey: wkT; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'TRAIN CLERIC'; Tooltip2: 'TRAINING A CLERIC'),
    (CommandType: 20; HotKey: wkT; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'TRAIN NECROLYTE'; Tooltip2: 'TRAINING A NECROLYTE'),
    (CommandType: 21; HotKey: wkH; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'HEALING'; Tooltip2: ''),
    (CommandType: 22; HotKey: wkF; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'FAR SEEING'; Tooltip2: ''),
    (CommandType: 23; HotKey: wkI; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'INVISIBILITY'; Tooltip2: ''),
    (CommandType: 24; HotKey: wkR; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'RAIN OF FIRE'; Tooltip2: ''),
    (CommandType: 25; HotKey: wkP; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'CLOUD OF POISON'; Tooltip2: ''),
    (CommandType: 26; HotKey: wkR; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'RAISE DEAD'; Tooltip2: ''),
    (CommandType: 27; HotKey: wkD; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'DARK VISION'; Tooltip2: ''),
    (CommandType: 28; HotKey: wkU; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'UNHOLY ARMOR'; Tooltip2: ''),
    (CommandType: 29; HotKey: wkR; HighlightIndex: 12; HighlightCount: 1; Tooltip: 'SUMMON SPIDERS'; Tooltip2: ''),
    (CommandType: 30; HotKey: wkO; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'SUMMON SCORPIONS'; Tooltip2: ''),
    (CommandType: 31; HotKey: wkD; HighlightIndex: 7; HighlightCount: 1; Tooltip: 'SUMMON DAEMON'; Tooltip2: ''),
    (CommandType: 32; HotKey: wkW; HighlightIndex: 7; HighlightCount: 1; Tooltip: 'SUMMON WATER ELEMENTAL'; Tooltip2: ''),
    (CommandType: 33; HotKey: wkB; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'BUILD BASIC STRUCTURE'; Tooltip2: ''),
    (CommandType: 34; HotKey: wkA; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD ADVANCED STRUCTURE'; Tooltip2: ''),
    (CommandType: 35; HotKey: wkF; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD FARM'; Tooltip2: ''),
    (CommandType: 36; HotKey: wkF; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD FARM'; Tooltip2: ''),
    (CommandType: 37; HotKey: wkB; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD BARRACKS'; Tooltip2: ''),
    (CommandType: 38; HotKey: wkB; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD BARRACKS'; Tooltip2: ''),
    (CommandType: 39; HotKey: wkU; HighlightIndex: 8; HighlightCount: 1; Tooltip: 'BUILD CHURCH'; Tooltip2: ''),
    (CommandType: 40; HotKey: wkE; HighlightIndex: 7; HighlightCount: 1; Tooltip: 'BUILD TEMPLE'; Tooltip2: ''),
    (CommandType: 41; HotKey: wkT; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD TOWER'; Tooltip2: ''),
    (CommandType: 42; HotKey: wkT; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD TOWER'; Tooltip2: ''),
    (CommandType: 43; HotKey: wkH; HighlightIndex: 11; HighlightCount: 1; Tooltip: 'BUILD TOWN HALL'; Tooltip2: ''),
    (CommandType: 44; HotKey: wkH; HighlightIndex: 11; HighlightCount: 1; Tooltip: 'BUILD TOWN HALL'; Tooltip2: ''),
    (CommandType: 45; HotKey: wkL; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD LUMBER MILL'; Tooltip2: ''),
    (CommandType: 46; HotKey: wkL; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD LUMBER MILL'; Tooltip2: ''),
    (CommandType: 47; HotKey: wkS; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD STABLES'; Tooltip2: ''),
    (CommandType: 48; HotKey: wkK; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD KENNEL'; Tooltip2: ''),
    (CommandType: 49; HotKey: wkB; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD BLACKSMITH'; Tooltip2: ''),
    (CommandType: 50; HotKey: wkB; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD BLACKSMITH'; Tooltip2: ''),
    (CommandType: 51; HotKey: wkR; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD ROAD'; Tooltip2: ''),
    (CommandType: 52; HotKey: wkW; HighlightIndex: 6; HighlightCount: 1; Tooltip: 'BUILD WALL'; Tooltip2: ''),
    (CommandType: 53; HotKey: wkW; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'UPGRADE SWORD STRENGTH'; Tooltip2: 'RESEARCHING WEAPONRY'),
    (CommandType: 54; HotKey: wkA; HighlightIndex: 8; HighlightCount: 1; Tooltip: 'UPGRADE AXE STRENGTH'; Tooltip2: 'RESEARCHING WEAPONRY'),
    (CommandType: 55; HotKey: wkH; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'UPGRADE SHIELD STRENGTH'; Tooltip2: 'RESEARCHING ARMOR'),
    (CommandType: 56; HotKey: wkH; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'UPGRADE SHIELD STRENGTH'; Tooltip2: 'RESEARCHING ARMOR'),
    (CommandType: 57; HotKey: wkU; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'UPGRADE ARROW STRENGTH'; Tooltip2: 'RESEARCHING WEAPONRY'),
    (CommandType: 58; HotKey: wkU; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'UPGRADE SPEAR STRENGTH'; Tooltip2: 'RESEARCHING WEAPONRY'),
    (CommandType: 59; HotKey: wkB; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'BREED FASTER HORSES'; Tooltip2: 'BREADING BETTER STOCK'),
    (CommandType: 60; HotKey: wkB; HighlightIndex: 0; HighlightCount: 1; Tooltip: 'BREED FASTER WOLVES'; Tooltip2: 'BREADING BETTER STOCK'),
    (CommandType: 61; HotKey: wkM; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH MINOR SUMMONING'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 62; HotKey: wkM; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH MINOR SUMMONING'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 63; HotKey: wkR; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH RAIN OF FIRE'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 64; HotKey: wkP; HighlightIndex: 18; HighlightCount: 1; Tooltip: 'RESEARCH CLOUD OF POISON'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 65; HotKey: wkA; HighlightIndex: 10; HighlightCount: 1; Tooltip: 'RESEARCH MAJOR SUMMONING'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 66; HotKey: wkA; HighlightIndex: 10; HighlightCount: 1; Tooltip: 'RESEARCH MAJOR SUMMONING'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 67; HotKey: wkH; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH HEALING'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 68; HotKey: wkR; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH RAISING DEAD'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 69; HotKey: wkF; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH FAR SEEING'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 70; HotKey: wkD; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH DARK VISION'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 71; HotKey: wkI; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH INVISIBILITY'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 72; HotKey: wkU; HighlightIndex: 9; HighlightCount: 1; Tooltip: 'RESEARCH UNHOLY ARMOR'; Tooltip2: 'RESEARCHING NEW SPELL'),
    (CommandType: 73; HotKey: wkEsc; HighlightIndex: 0; HighlightCount: 3; Tooltip: 'ESC - CANCEL'; Tooltip2: '')
  );

  /// <summary>commandMappings: 62 rows in the order of the table; the first 30 are units (train and build), then 20 upgrades, then the 4 summons and 8 spells</summary>
  WAR_COMMAND_MAPPINGS: array[0..61] of TWarCommandMapping = (
    (CommandType: 7; MappedType: 0),
    (CommandType: 8; MappedType: 1),
    (CommandType: 9; MappedType: 2),
    (CommandType: 10; MappedType: 3),
    (CommandType: 11; MappedType: 4),
    (CommandType: 12; MappedType: 5),
    (CommandType: 13; MappedType: 6),
    (CommandType: 14; MappedType: 7),
    (CommandType: 15; MappedType: 8),
    (CommandType: 16; MappedType: 9),
    (CommandType: 17; MappedType: 10),
    (CommandType: 18; MappedType: 11),
    (CommandType: 19; MappedType: 12),
    (CommandType: 20; MappedType: 13),
    (CommandType: 35; MappedType: 32),
    (CommandType: 36; MappedType: 33),
    (CommandType: 37; MappedType: 34),
    (CommandType: 38; MappedType: 35),
    (CommandType: 39; MappedType: 36),
    (CommandType: 40; MappedType: 37),
    (CommandType: 41; MappedType: 38),
    (CommandType: 42; MappedType: 39),
    (CommandType: 43; MappedType: 40),
    (CommandType: 44; MappedType: 41),
    (CommandType: 45; MappedType: 42),
    (CommandType: 46; MappedType: 43),
    (CommandType: 47; MappedType: 44),
    (CommandType: 48; MappedType: 45),
    (CommandType: 49; MappedType: 46),
    (CommandType: 50; MappedType: 47),
    (CommandType: 53; MappedType: 2),
    (CommandType: 54; MappedType: 3),
    (CommandType: 55; MappedType: 18),
    (CommandType: 56; MappedType: 18),
    (CommandType: 57; MappedType: 0),
    (CommandType: 58; MappedType: 1),
    (CommandType: 59; MappedType: 4),
    (CommandType: 60; MappedType: 5),
    (CommandType: 61; MappedType: 6),
    (CommandType: 62; MappedType: 7),
    (CommandType: 63; MappedType: 8),
    (CommandType: 64; MappedType: 9),
    (CommandType: 65; MappedType: 10),
    (CommandType: 66; MappedType: 11),
    (CommandType: 67; MappedType: 12),
    (CommandType: 68; MappedType: 13),
    (CommandType: 69; MappedType: 14),
    (CommandType: 70; MappedType: 15),
    (CommandType: 71; MappedType: 16),
    (CommandType: 72; MappedType: 17),
    (CommandType: 29; MappedType: 8),
    (CommandType: 30; MappedType: 9),
    (CommandType: 31; MappedType: 10),
    (CommandType: 32; MappedType: 11),
    (CommandType: 21; MappedType: 0),
    (CommandType: 22; MappedType: 1),
    (CommandType: 23; MappedType: 2),
    (CommandType: 24; MappedType: 3),
    (CommandType: 26; MappedType: 5),
    (CommandType: 27; MappedType: 6),
    (CommandType: 28; MappedType: 7),
    (CommandType: 25; MappedType: 4)
  );

  /// <summary>upgradesData: by the number of the upgrade</summary>
  WAR_UPGRADE_FRAMES: array[0..18] of TWarUpgradeFrames = (
    (Levels: 2; Frame1: 72; Frame2: 73),
    (Levels: 2; Frame1: 75; Frame2: 76),
    (Levels: 2; Frame1: 64; Frame2: 65),
    (Levels: 2; Frame1: 67; Frame2: 68),
    (Levels: 2; Frame1: 77; Frame2: 78),
    (Levels: 2; Frame1: 69; Frame2: 70),
    (Levels: 1; Frame1: 48; Frame2: 48),
    (Levels: 1; Frame1: 45; Frame2: 45),
    (Levels: 1; Frame1: 88; Frame2: 88),
    (Levels: 1; Frame1: 92; Frame2: 92),
    (Levels: 1; Frame1: 52; Frame2: 52),
    (Levels: 1; Frame1: 51; Frame2: 51),
    (Levels: 1; Frame1: 85; Frame2: 85),
    (Levels: 1; Frame1: 89; Frame2: 89),
    (Levels: 1; Frame1: 86; Frame2: 86),
    (Levels: 1; Frame1: 90; Frame2: 90),
    (Levels: 1; Frame1: 87; Frame2: 87),
    (Levels: 1; Frame1: 91; Frame2: 91),
    (Levels: 2; Frame1: 80; Frame2: 81)
  );

  /// <summary>spellData: the frame of the portrait of a spell or a summon, by its number</summary>
  WAR_SPELL_PORTRAITS: array[0..11] of Integer = (85, 86, 87, 88, 92, 89, 90, 91, 45, 48, 51, 52);

  // WarFeatureType of war_enums.h (player->features[feature / 2])
  WAR_FEATURE_UNIT_FOOTMAN = 0;
  WAR_FEATURE_UNIT_GRUNT = 1;
  WAR_FEATURE_UNIT_PEASANT = 2;
  WAR_FEATURE_UNIT_PEON = 3;
  WAR_FEATURE_UNIT_CATAPULT_HUMANS = 4;
  WAR_FEATURE_UNIT_CATAPULT_ORCS = 5;
  WAR_FEATURE_UNIT_KNIGHT = 6;
  WAR_FEATURE_UNIT_RAIDER = 7;
  WAR_FEATURE_UNIT_ARCHER = 8;
  WAR_FEATURE_UNIT_SPEARMAN = 9;
  WAR_FEATURE_UNIT_CONJURER = 10;
  WAR_FEATURE_UNIT_WARLOCK = 11;
  WAR_FEATURE_UNIT_CLERIC = 12;
  WAR_FEATURE_UNIT_NECROLYTE = 13;
  WAR_FEATURE_UNIT_FARM_HUMANS = 14;
  WAR_FEATURE_UNIT_FARM_ORCS = 15;
  WAR_FEATURE_UNIT_BARRACKS_HUMANS = 16;
  WAR_FEATURE_UNIT_BARRACKS_ORCS = 17;
  WAR_FEATURE_UNIT_CHURCH = 18;
  WAR_FEATURE_UNIT_TEMPLE = 19;
  WAR_FEATURE_UNIT_TOWER_HUMANS = 20;
  WAR_FEATURE_UNIT_TOWER_ORCS = 21;
  WAR_FEATURE_UNIT_TOWN_HALL_HUMANS = 22;
  WAR_FEATURE_UNIT_TOWN_HALL_ORCS = 23;
  WAR_FEATURE_UNIT_LUMBER_MILL_HUMANS = 24;
  WAR_FEATURE_UNIT_LUMBER_MILL_ORCS = 25;
  WAR_FEATURE_UNIT_STABLE = 26;
  WAR_FEATURE_UNIT_KENNEL = 27;
  WAR_FEATURE_UNIT_BLACKSMITH_HUMANS = 28;
  WAR_FEATURE_UNIT_BLACKSMITH_ORCS = 29;
  WAR_FEATURE_SPELL_HEALING = 30;
  WAR_FEATURE_SPELL_RAISE_DEAD = 31;
  WAR_FEATURE_SPELL_FAR_SIGHT = 32;
  WAR_FEATURE_SPELL_DARK_VISION = 33;
  WAR_FEATURE_SPELL_INVISIBILITY = 34;
  WAR_FEATURE_SPELL_UNHOLY_ARMOR = 35;
  WAR_FEATURE_SPELL_SCORPION = 36;
  WAR_FEATURE_SPELL_SPIDER = 37;
  WAR_FEATURE_SPELL_RAIN_OF_FIRE = 38;
  WAR_FEATURE_SPELL_POISON_CLOUD = 39;
  WAR_FEATURE_SPELL_WATER_ELEMENTAL = 40;
  WAR_FEATURE_SPELL_DAEMON = 41;
  WAR_FEATURE_UNIT_ROAD = 42;
  WAR_FEATURE_UNIT_WALL = 43;

  // WarUnitCommandType of war_enums.h, as WAR_CMD_*
  WAR_CMD_NONE = 0;
  WAR_CMD_MOVE = 1;
  WAR_CMD_STOP = 2;
  WAR_CMD_HARVEST = 3;
  WAR_CMD_DELIVER = 4;
  WAR_CMD_REPAIR = 5;
  WAR_CMD_ATTACK = 6;
  WAR_CMD_TRAIN_FOOTMAN = 7;
  WAR_CMD_TRAIN_GRUNT = 8;
  WAR_CMD_TRAIN_PEASANT = 9;
  WAR_CMD_TRAIN_PEON = 10;
  WAR_CMD_TRAIN_CATAPULT_HUMANS = 11;
  WAR_CMD_TRAIN_CATAPULT_ORCS = 12;
  WAR_CMD_TRAIN_KNIGHT = 13;
  WAR_CMD_TRAIN_RAIDER = 14;
  WAR_CMD_TRAIN_ARCHER = 15;
  WAR_CMD_TRAIN_SPEARMAN = 16;
  WAR_CMD_TRAIN_CONJURER = 17;
  WAR_CMD_TRAIN_WARLOCK = 18;
  WAR_CMD_TRAIN_CLERIC = 19;
  WAR_CMD_TRAIN_NECROLYTE = 20;
  WAR_CMD_SPELL_HEALING = 21;
  WAR_CMD_SPELL_FAR_SIGHT = 22;
  WAR_CMD_SPELL_INVISIBILITY = 23;
  WAR_CMD_SPELL_RAIN_OF_FIRE = 24;
  WAR_CMD_SPELL_POISON_CLOUD = 25;
  WAR_CMD_SPELL_RAISE_DEAD = 26;
  WAR_CMD_SPELL_DARK_VISION = 27;
  WAR_CMD_SPELL_UNHOLY_ARMOR = 28;
  WAR_CMD_SUMMON_SPIDER = 29;
  WAR_CMD_SUMMON_SCORPION = 30;
  WAR_CMD_SUMMON_DAEMON = 31;
  WAR_CMD_SUMMON_WATER_ELEMENTAL = 32;
  WAR_CMD_BUILD_BASIC = 33;
  WAR_CMD_BUILD_ADVANCED = 34;
  WAR_CMD_BUILD_FARM_HUMANS = 35;
  WAR_CMD_BUILD_FARM_ORCS = 36;
  WAR_CMD_BUILD_BARRACKS_HUMANS = 37;
  WAR_CMD_BUILD_BARRACKS_ORCS = 38;
  WAR_CMD_BUILD_CHURCH = 39;
  WAR_CMD_BUILD_TEMPLE = 40;
  WAR_CMD_BUILD_TOWER_HUMANS = 41;
  WAR_CMD_BUILD_TOWER_ORCS = 42;
  WAR_CMD_BUILD_TOWNHALL_HUMANS = 43;
  WAR_CMD_BUILD_TOWNHALL_ORCS = 44;
  WAR_CMD_BUILD_LUMBERMILL_HUMANS = 45;
  WAR_CMD_BUILD_LUMBERMILL_ORCS = 46;
  WAR_CMD_BUILD_STABLE = 47;
  WAR_CMD_BUILD_KENNEL = 48;
  WAR_CMD_BUILD_BLACKSMITH_HUMANS = 49;
  WAR_CMD_BUILD_BLACKSMITH_ORCS = 50;
  WAR_CMD_BUILD_ROAD = 51;
  WAR_CMD_BUILD_WALL = 52;
  WAR_CMD_UPGRADE_SWORDS = 53;
  WAR_CMD_UPGRADE_AXES = 54;
  WAR_CMD_UPGRADE_SHIELD_HUMANS = 55;
  WAR_CMD_UPGRADE_SHIELD_ORCS = 56;
  WAR_CMD_UPGRADE_ARROWS = 57;
  WAR_CMD_UPGRADE_SPEARS = 58;
  WAR_CMD_UPGRADE_HORSES = 59;
  WAR_CMD_UPGRADE_WOLVES = 60;
  WAR_CMD_UPGRADE_SCORPION = 61;
  WAR_CMD_UPGRADE_SPIDER = 62;
  WAR_CMD_UPGRADE_RAIN_OF_FIRE = 63;
  WAR_CMD_UPGRADE_POISON_CLOUD = 64;
  WAR_CMD_UPGRADE_WATER_ELEMENTAL = 65;
  WAR_CMD_UPGRADE_DAEMON = 66;
  WAR_CMD_UPGRADE_HEALING = 67;
  WAR_CMD_UPGRADE_RAISE_DEAD = 68;
  WAR_CMD_UPGRADE_FAR_SIGHT = 69;
  WAR_CMD_UPGRADE_DARK_VISION = 70;
  WAR_CMD_UPGRADE_INVISIBILITY = 71;
  WAR_CMD_UPGRADE_UNHOLY_ARMOR = 72;
  WAR_CMD_CANCEL = 73;

implementation

end.
