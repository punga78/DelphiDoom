{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the levels                               }
{                                                                              }
{  Port of war1 (acoto87/war1), the level part of war_resources.h and          }
{  war.h, (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\       }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAP_TILES_WIDTH of war.h: tiles of a level in a row</summary>
  WAR_MAP_TILES_WIDTH = 64;
  /// <summary>MAP_TILES_HEIGHT of war.h</summary>
  WAR_MAP_TILES_HEIGHT = 64;
  /// <summary>MAX_FEATURES_COUNT of war.h: bits of the "allow" mask of a level (what can be built, trained, researched)</summary>
  WAR_MAX_FEATURES_COUNT = 22;
  /// <summary>MAX_UPGRADES_COUNT of war.h: the kinds of upgrade and spell of the level info</summary>
  WAR_MAX_UPGRADES_COUNT = 10;
  /// <summary>MAX_PLAYERS_COUNT of war.h: the players of a level (4 + the neutral one)</summary>
  WAR_MAX_PLAYERS_COUNT = 5;
  /// <summary>MAX_OBJECTIVES_LENGTH of war.h: bytes of the objectives text, the terminator included</summary>
  WAR_MAX_OBJECTIVES_LENGTH = 512;
  /// <summary>MAX_ENTITIES_COUNT of war.h: the most starting units of a level</summary>
  WAR_MAX_ENTITIES_COUNT = 1024;
  /// <summary>MAX_CONSTRUCTS_COUNT of war.h: the most starting roads (or walls) of a level</summary>
  WAR_MAX_CONSTRUCTS_COUNT = 100;
  /// <summary>MAX_CUSTOM_MAP_GOLDMINES_COUNT of war.h</summary>
  WAR_MAX_CUSTOM_GOLDMINES_COUNT = 10;
  /// <summary>MAX_CUSTOM_MAP_CONFIGURATIONS_COUNT of war.h: starting positions of a custom map</summary>
  WAR_MAX_CUSTOM_CONFIGURATIONS_COUNT = 10;
  /// <summary>MAX_CUSTOM_MAP_ENTITIES_COUNT of war.h</summary>
  WAR_MAX_CUSTOM_ENTITIES_COUNT = 1024;
  /// <summary>Bytes of the visual and of the passable record: one 16 bit number per tile of the map</summary>
  WAR_LEVEL_MAP_BYTES = WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT * 2;

  // WarUnitType of war_enums.h: the type of a starting unit (a byte in the level; the original keeps it in an int)
  WAR_UNIT_FOOTMAN = 0;
  WAR_UNIT_GRUNT = 1;
  WAR_UNIT_PEASANT = 2;
  WAR_UNIT_PEON = 3;
  WAR_UNIT_CATAPULT_HUMANS = 4;
  WAR_UNIT_CATAPULT_ORCS = 5;
  WAR_UNIT_KNIGHT = 6;
  WAR_UNIT_RAIDER = 7;
  WAR_UNIT_ARCHER = 8;
  WAR_UNIT_SPEARMAN = 9;
  WAR_UNIT_CONJURER = 10;
  WAR_UNIT_WARLOCK = 11;
  WAR_UNIT_CLERIC = 12;
  WAR_UNIT_NECROLYTE = 13;
  WAR_UNIT_MEDIVH = 14;
  WAR_UNIT_LOTHAR = 15;
  WAR_UNIT_WOUNDED = 16;
  WAR_UNIT_GRIZELDA = 17;
  WAR_UNIT_GARONA = 18;
  WAR_UNIT_OGRE = 19;
  WAR_UNIT_SPIDER = 20;
  WAR_UNIT_SLIME = 21;
  WAR_UNIT_FIRE_ELEMENTAL = 22;
  WAR_UNIT_SCORPION = 23;
  WAR_UNIT_BRIGAND = 24;
  WAR_UNIT_THE_DEAD = 25;
  WAR_UNIT_SKELETON = 26;
  WAR_UNIT_DAEMON = 27;
  WAR_UNIT_WATER_ELEMENTAL = 28;
  WAR_UNIT_DRAGON_CYCLOPS_GIANT = 29;
  WAR_UNIT_26 = 30;
  WAR_UNIT_30 = 31;
  WAR_UNIT_FARM_HUMANS = 32;
  WAR_UNIT_FARM_ORCS = 33;
  WAR_UNIT_BARRACKS_HUMANS = 34;
  WAR_UNIT_BARRACKS_ORCS = 35;
  WAR_UNIT_CHURCH = 36;
  WAR_UNIT_TEMPLE = 37;
  WAR_UNIT_TOWER_HUMANS = 38;
  WAR_UNIT_TOWER_ORCS = 39;
  WAR_UNIT_TOWNHALL_HUMANS = 40;
  WAR_UNIT_TOWNHALL_ORCS = 41;
  WAR_UNIT_LUMBERMILL_HUMANS = 42;
  WAR_UNIT_LUMBERMILL_ORCS = 43;
  WAR_UNIT_STABLE = 44;
  WAR_UNIT_KENNEL = 45;
  WAR_UNIT_BLACKSMITH_HUMANS = 46;
  WAR_UNIT_BLACKSMITH_ORCS = 47;
  WAR_UNIT_STORMWIND = 48;
  WAR_UNIT_BLACKROCK = 49;
  WAR_UNIT_GOLDMINE = 50;
  WAR_UNIT_51 = 51;
  WAR_UNIT_HUMAN_CORPSE = 52;
  WAR_UNIT_ORC_CORPSE = 53;
  /// <summary>WAR_UNIT_COUNT: how many unit types the original knows</summary>
  WAR_UNIT_COUNT = 54;

type
  /// <summary>WarRace of war_enums.h</summary>
  TWarRace = (wraNeutral, wraHumans, wraOrcs);

  /// <summary>WarResourceKind of war_enums.h: what a starting unit holds (only the gold mines hold something)</summary>
  TWarResourceKind = (wrkNone, wrkGold, wrkWood);

  /// <summary>WarConstructType of war_enums.h</summary>
  TWarConstructType = (wctUnknown, wctRoad, wctWall);

  /// <summary>
  ///   WarLevelUnit: a unit (or a building, or a gold mine) the level starts with. The tile is the level byte
  ///   divided by two. The original struct is 20 bytes because its enums are as big as an int; this one is not a
  ///   disk format, it is packed to 7 bytes
  /// </summary>
  TWarLevelUnit = packed record
    X: Byte;
    Y: Byte;
    UnitType: Byte;
    Player: Byte;
    ResourceKind: TWarResourceKind;
    Amount: Word;
  end;

  /// <summary>WarLevelConstruct: a stretch of road or wall (the original struct is 12 bytes; this is 6)</summary>
  TWarLevelConstruct = packed record
    ConstructType: TWarConstructType;
    X1: Byte;
    Y1: Byte;
    X2: Byte;
    Y2: Byte;
    Player: Byte;
  end;

  /// <summary>WarCustomMapConfiguration: the starting units of the two players of a custom map in one position</summary>
  TWarCustomMapConfiguration = record
    StartEntities: TArray<TWarLevelUnit>;
  end;

  /// <summary>
  ///   levelInfo of WarResource: what a level info record says about the level. The indices of the records it
  ///   points to are the ones of the archive (the original stores the number of the file minus two)
  /// </summary>
  TWarLevelInfo = record
    /// <summary>The index of the record in the archive (it is also the campaign map type of the original)</summary>
    Index: Integer;
    /// <summary>Param1 of the catalog: 0 forest, 1 swamp, 2 dungeon (WarMapTilesetType)</summary>
    TilesetType: Word;
    /// <summary>Param2 of the catalog: a map of the skirmish menu</summary>
    CustomMap: Boolean;
    /// <summary>The first 32 bit number of the record: the mask of what the level allows</summary>
    AllowId: Cardinal;
    AllowedHumanUnits: Boolean;
    AllowedOrcsUnits: Boolean;
    /// <summary>1 where bit F of AllowId is set</summary>
    AllowedFeatures: array[0..WAR_MAX_FEATURES_COUNT - 1] of Byte;
    /// <summary>[upgrade, player]; the spells the level does not allow stay 0</summary>
    AllowedUpgrades: array[0..WAR_MAX_UPGRADES_COUNT - 1, 0..WAR_MAX_PLAYERS_COUNT - 1] of Byte;
    StartX: Word;
    StartY: Word;
    NextLevelIndex: Word;
    VisualIndex: Word;
    PassableIndex: Word;
    PaletteIndex: Word;
    TilesIndex: Word;
    TilesetIndex: Word;
    Lumber: array[0..WAR_MAX_PLAYERS_COUNT - 1] of Cardinal;
    Gold: array[0..WAR_MAX_PLAYERS_COUNT - 1] of Cardinal;
    /// <summary>The race of the players 0..3; the player 4 is never set (wraNeutral)</summary>
    Races: array[0..WAR_MAX_PLAYERS_COUNT - 1] of TWarRace;
    Objectives: AnsiString;
    StartEntities: TArray<TWarLevelUnit>;
    StartRoads: TArray<TWarLevelConstruct>;
    StartWalls: TArray<TWarLevelConstruct>;
    StartGoldmines: TArray<TWarLevelUnit>;
    StartConfigurations: TArray<TWarCustomMapConfiguration>;
  end;

resourcestring
  SWarLevelIsNotLevelInfo = 'The record %d is not a level info record of the catalog';
  SWarLevelRecordMissing = 'The level %d needs the record %d (%s), which cannot be read';
  SWarLevelMapSize = 'The map record has %d bytes, a level map has %d';
  SWarLevelTooMany = 'The level has more than %d %s';
  SWarLevelObjectivesTooLong = 'The objectives text of the level goes past the record or is longer than %d bytes';
  SWarLevelIndexOutOfRange = 'The tile %d, %d is not in the map';

implementation

end.
