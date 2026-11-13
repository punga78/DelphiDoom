{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the game map                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.h, war_units.h and war.h, (c) 2019     }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Types;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types;

const
  /// <summary>MEGA_TILE_WIDTH and HEIGHT of war.h: pixels of a tile of the map</summary>
  WAR_MEGA_TILE_SIZE = 16;
  /// <summary>MINIMAP_WIDTH and HEIGHT of war.h: one pixel per tile</summary>
  WAR_MINIMAP_SIZE = 64;
  /// <summary>Bytes of the image of the minimap: 64 x 64 pixels of R, G, B, A</summary>
  WAR_MINIMAP_BYTES = WAR_MINIMAP_SIZE * WAR_MINIMAP_SIZE * 4;
  /// <summary>MAP_VIEWPORT_WIDTH of war.h</summary>
  WAR_MAP_VIEWPORT_WIDTH = 240;
  /// <summary>MAP_VIEWPORT_HEIGHT of war.h</summary>
  WAR_MAP_VIEWPORT_HEIGHT = 176;
  /// <summary>TREE_MAX_WOOD of war.h: the wood of a new tree</summary>
  WAR_TREE_MAX_WOOD = 100;
  /// <summary>WAR_WALL_MAX_HP of war_units.h</summary>
  WAR_WALL_MAX_HP = 60;
  /// <summary>Tiles of the map: 64 x 64</summary>
  WAR_MAP_TILE_COUNT = WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT;
  /// <summary>WarMapTilesetType: the forest (0) and the swamp (1) tilesets; the dungeon (2) uses the swamp tiles for the felled trees</summary>
  WAR_TILESET_FOREST = 0;
  WAR_TILESET_SWAMP = 1;
  WAR_TILESET_DUNGEON = 2;

type
  /// <summary>WarMapTileState of war_enums.h (the values are the ones of the original)</summary>
  TWarMapTileState = (wtsUnknown = 1, wtsFog = 2, wtsVisible = 4);

  /// <summary>WarFogBoundaryType of war_enums.h</summary>
  TWarFogBoundary = (wfbNone, wfbUnknown, wfbFog);

  /// <summary>WarMapTile: what the player knows of a tile (the piece of fog to draw and where fog meets unknown)</summary>
  TWarMapTile = record
    State: TWarMapTileState;
    /// <summary>WarFogPieceType, 0..15: the piece of the fog tile map (0 = none)</summary>
    PieceType: Byte;
    Boundary: TWarFogBoundary;
  end;

  PWarMapTile = ^TWarMapTile;

  /// <summary>WarUpgrade: whether the player may research an upgrade and the level it has</summary>
  TWarUpgradeState = record
    Allowed: Byte;
    Level: Byte;
  end;

  /// <summary>WarPlayerInfo (without the AI): the race, the resources and what the level allows</summary>
  TWarPlayerInfo = record
    Index: Byte;
    Race: TWarRace;
    Gold: Integer;
    Wood: Integer;
    GodMode: Boolean;
    /// <summary>1 where the level allows the feature (build, train, research)</summary>
    Features: array[0..WAR_MAX_FEATURES_COUNT - 1] of Byte;
    Upgrades: array[0..WAR_MAX_UPGRADES_COUNT - 1] of TWarUpgradeState;
  end;

  /// <summary>unitsData of war_units.c: the sprite record and the size in tiles of a unit type</summary>
  TWarUnitData = record
    UnitType: Integer;
    ResourceIndex: Integer;
    SizeX: Integer;
    SizeY: Integer;
  end;

  /// <summary>unitStats of war_units.c (the fields a map needs): the statistics of a unit that moves</summary>
  TWarUnitStats = record
    UnitType: Integer;
    Range: Integer;
    Sight: Integer;
    Armor: Integer;
    Hp: Integer;
    Mana: Integer;
    MinDamage: Integer;
    RndDamage: Integer;
    Decay: Integer;
  end;

  /// <summary>buildingStats of war_units.c (the fields a map needs): the statistics of a building</summary>
  TWarBuildingStats = record
    UnitType: Integer;
    Armor: Integer;
    Sight: Integer;
    Hp: Integer;
  end;

  /// <summary>
  ///   A unit, building or gold mine of the map (WarUnitComponent with the position of the transform). The
  ///   position is the tile times 16; the direction starts at 0 (the original draws it at random: it is not a
  ///   datum of the level)
  /// </summary>
  TWarMapUnit = record
    /// <summary>The id of the entity (the original keeps 16 bits)</summary>
    Id: Word;
    UnitType: Integer;
    Direction: Integer;
    TileX: Integer;
    TileY: Integer;
    SizeX: Integer;
    SizeY: Integer;
    Player: Byte;
    ResourceKind: TWarResourceKind;
    Amount: Integer;
    MaxHp: Integer;
    Hp: Integer;
    MaxMana: Integer;
    Mana: Integer;
    Armor: Integer;
    Range: Integer;
    MinDamage: Integer;
    RndDamage: Integer;
    Decay: Integer;
    /// <summary>manaTime: 1 for the units that move</summary>
    ManaTime: Integer;
    HasBeenSeen: Boolean;
    /// <summary>The unit is dying or collapsing (wst_isDead, wst_isCollapsing): the minimap does not show it. Set by the game, never by the level</summary>
    IsGone: Boolean;
  end;

  /// <summary>The window on the map, in pixels of the map (map->camera.viewport)</summary>
  TWarViewport = record
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
  end;

resourcestring
  SWarMapUnitUnknown = 'The unit type %d has no data in the tables of the game';
  SWarMapTileOutside = 'The tile %d, %d is not in the map';
  SWarMapPixelOutside = 'The minimap pixel %d is not in the image of the minimap';
  SWarMapTilesetTile = 'The tile %d of the map is not in the tileset image';
  SWarMapTilesetShort = 'The tileset image has %d bytes, %d are needed';
  SWarMapVisualShort = 'The visual map has %d tiles, %d are needed';
  SWarMapPassableShort = 'The passable map has %d tiles, %d are needed';
  SWarMapNoBuilder = 'The map builder needs the tables of the units';

implementation

end.
