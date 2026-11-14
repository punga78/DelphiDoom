{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types and constants of the path finding           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_pathfinder.h and war_pathfinder.c,         }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.Types;

interface

uses
  System.Types, DelphiDoom.War.Level.Types;

const
  /// <summary>wpath_dirC: the eight neighbors of a tile, from the north clockwise</summary>
  WAR_PATH_DIRECTION_COUNT = 8;
  /// <summary>wpath_dirX</summary>
  WAR_PATH_DIR_X: array[0..WAR_PATH_DIRECTION_COUNT - 1] of Integer = (0, 1, 1, 1, 0, -1, -1, -1);
  /// <summary>wpath_dirY</summary>
  WAR_PATH_DIR_Y: array[0..WAR_PATH_DIRECTION_COUNT - 1] of Integer = (-1, -1, 0, 1, 1, 1, 0, -1);
  /// <summary>
  ///   WAR_DIRECTION_COUNT: the direction of a tile of the flow field that has none (the goal, a tile that cannot be
  ///   reached); sampling it gives the zero vector
  /// </summary>
  WAR_FLOW_NO_DIRECTION = 8;
  /// <summary>INT32_MAX: the cost of a tile of the flow field that was not reached</summary>
  WAR_FLOW_UNREACHED = $7FFFFFFF;
  /// <summary>The cost of a step along an axis and along a diagonal in the flow field (the A star counts 1 for both)</summary>
  WAR_FLOW_COST_STRAIGHT = 100;
  WAR_FLOW_COST_DIAGONAL = 141;

type
  /// <summary>
  ///   WarMapNode. Id is the number of the tile (y * 64 + x); Parent is the Id of the node it was reached from, -1 for
  ///   the first node; Level is never used by the original
  /// </summary>
  TWarPathNode = record
    Id: Integer;
    X: Integer;
    Y: Integer;
    Level: Integer;
    Parent: Integer;
    GScore: Integer;
    FScore: Integer;
  end;

  /// <summary>WarMapPath: the tiles of a path from the start to the end (or to the closest tile that was reached)</summary>
  TWarMapPath = record
    Count: Integer;
    Nodes: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of TPoint;
  end;

implementation

end.
