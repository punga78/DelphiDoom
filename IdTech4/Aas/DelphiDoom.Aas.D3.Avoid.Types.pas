{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, shared types        }
{                                                                              }
{  Port of the types and constants of the dynamic obstacle avoidance of        }
{  AI_pathing.cpp and of obstaclePath_t of AI.h, Doom 3 GPL Source Code.       }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3 or (at your option) any later version, with the   }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.Types;

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Mat3;

const
  /// <summary>MAX_OBSTACLE_RADIUS: the obstacles are searched this far around the path</summary>
  AVOID_MAX_OBSTACLE_RADIUS = 256.0;
  /// <summary>MAX_AAS_WALL_EDGES</summary>
  AVOID_MAX_AAS_WALL_EDGES = 256;
  /// <summary>MAX_OBSTACLES</summary>
  AVOID_MAX_OBSTACLES = 256;
  /// <summary>MAX_PATH_NODES: a path tree is not grown beyond this number of nodes</summary>
  AVOID_MAX_PATH_NODES = 256;
  /// <summary>MAX_OBSTACLE_PATH: the points of an optimized path</summary>
  AVOID_MAX_OBSTACLE_PATH = 64;
  /// <summary>
  ///   The entity of an obstacle that is a wall of the AAS (the NULL entity of the original). The entities of
  ///   the game are any other number
  /// </summary>
  AVOID_NO_ENTITY = 0;

type
  /// <summary>
  ///   An entity of the game that blocks the way, as the clip model of the entity: the box in the local
  ///   space of the model and its place. The game has already made the choices that depend on its entities and
  ///   their physics: only actors that are not the one that walks, nor its enemy, nor dead, nor moving the
  ///   same way as it does, and moveables, are listed (idAI::GetObstacles asks them of the entities)
  /// </summary>
  TAvoidClipModel = record
    /// <summary>The number of the entity; not <c>AVOID_NO_ENTITY</c></summary>
    EntityId: Integer;
    /// <summary>idClipModel::GetBounds: the box in the space of the model</summary>
    Bounds: TGeoBounds;
    /// <summary>idClipModel::GetAbsBounds</summary>
    AbsBounds: TGeoBounds;
    Origin: TGeoVec3;
    Axis: TGeoMat3;
  end;

  /// <summary>obstaclePath_t: the answer of the search of a path around the obstacles</summary>
  TAvoidPath = record
    /// <summary>Seek position avoiding obstacles</summary>
    SeekPos: TGeoVec3;
    /// <summary>If not <c>AVOID_NO_ENTITY</c> the first obstacle along the path</summary>
    FirstObstacle: Integer;
    StartPosOutsideObstacles: TGeoVec3;
    /// <summary>If not <c>AVOID_NO_ENTITY</c> the obstacle that contains the start position</summary>
    StartPosObstacle: Integer;
    SeekPosOutsideObstacles: TGeoVec3;
    SeekPosObstacle: Integer;
  end;

  /// <summary>
  ///   The obstacle avoidance cannot go on: a winding that has no edge to walk along, a path that has more
  ///   points than MAX_OBSTACLE_PATH, an obstacle that the tree names and the list does not hold. The
  ///   original loops forever or reads outside its arrays
  /// </summary>
  EAasAvoidException = class(Exception);

implementation

end.
