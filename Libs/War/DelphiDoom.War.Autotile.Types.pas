{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the tile joins                           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_entities.h and war_units.h, (c) 2019       }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Autotile.Types;

interface

const
  /// <summary>WAR_RUIN_PIECE_NONE and WAR_TREE_NONE: no piece fits the neighbors, the original removes it</summary>
  WAR_PIECE_NONE = 0;
  /// <summary>WAR_TREE_CHOPPED: a tree already cut down, its type is not recomputed</summary>
  WAR_TREE_CHOPPED = 19;

type
  /// <summary>One cell of a road or of a wall (WarRoadPiece, WarWallPiece without the hit points of the game)</summary>
  TWarLinePiece = record
    /// <summary>The piece type, 0..14 (the same names for roads and walls, WAR_ROAD_PIECE_LEFT ...)</summary>
    PieceType: Byte;
    TileX: Integer;
    TileY: Integer;
    Player: Byte;
  end;

  /// <summary>One cell of a ruin (WarRuinPiece)</summary>
  TWarRuinPiece = record
    PieceType: Byte;
    TileX: Integer;
    TileY: Integer;
  end;

  /// <summary>One tree (WarTree)</summary>
  TWarTree = record
    /// <summary>WarTreeTileType, 0..19</summary>
    TileType: Byte;
    TileX: Integer;
    TileY: Integer;
    /// <summary>Wood left; a tree with none does not join the others</summary>
    Amount: Integer;
  end;

  /// <summary>The tile of the tileset of a piece in the forest and in the swamp</summary>
  TWarPieceTiles = record
    Forest: Integer;
    Swamp: Integer;
  end;

  /// <summary>The tiles of a wall piece whole, damaged and destroyed, in the forest and in the swamp</summary>
  TWarWallTiles = record
    Forest: Integer;
    DamagedForest: Integer;
    DestroyedForest: Integer;
    Swamp: Integer;
    DamagedSwamp: Integer;
    DestroyedSwamp: Integer;
  end;

  /// <summary>The 16 neighbor combinations of a road or wall piece and the piece each one gives</summary>
  TWarLineTypeMap = array[0..15] of Byte;

/// <summary>wpath_isInside: the cell is in the 64 x 64 map</summary>
function WarTileInside(AX, AY: Integer): Boolean;
/// <summary>A number for the cell, for a set; cells within 1024 of the map are told apart</summary>
function WarTileKey(AX, AY: Integer): Integer;

implementation

uses
  DelphiDoom.War.Level.Types;

function WarTileInside(AX, AY: Integer): Boolean;
begin
  Result := (AX >= 0) and (AX < WAR_MAP_TILES_WIDTH) and (AY >= 0) and (AY < WAR_MAP_TILES_HEIGHT);
end;

function WarTileKey(AX, AY: Integer): Integer;
begin
  Result := (AY + 1024) * 4096 + (AX + 1024);
end;

end.
