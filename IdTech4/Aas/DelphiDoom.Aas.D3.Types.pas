{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - shared types and constants              }
{                                                                              }
{  Port of the types of AAS.h and AAS_local.h, Doom 3 GPL Source Code. Based   }
{  on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011 id     }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom   }
{  3 GPL source code and is therefore available under the GNU General Public   }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Types;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.MapFile.Aas.Reachability;

const
  /// <summary>Types of path (the anonymous enum of AAS.h)</summary>
  PATHTYPE_WALK = 0;
  PATHTYPE_WALKOFFLEDGE = 1;
  PATHTYPE_BARRIERJUMP = 2;
  PATHTYPE_JUMP = 3;

  /// <summary>CACHETYPE_AREA and CACHETYPE_PORTAL of AAS_routing.cpp</summary>
  AAS_CACHETYPE_AREA = 1;
  AAS_CACHETYPE_PORTAL = 2;

  /// <summary>MAX_ROUTING_CACHE_MEMORY: 2 MB of cache before the oldest entries are dropped</summary>
  AAS_MAX_ROUTING_CACHE_MEMORY = 2 * 1024 * 1024;
  /// <summary>LEDGE_TRAVELTIME_PANALTY: added to the time of an area near a ledge when flying is not allowed</summary>
  AAS_LEDGE_TRAVELTIME_PENALTY = 250;
  /// <summary>
  ///   sizeof(idRoutingCache) of the 32 bit build (five ints, four pointers, a short padded to 4, two
  ///   pointers). The cache memory is counted with this number, not with the size of the Delphi
  ///   object, so that the same entries are dropped at the same time as in the original
  /// </summary>
  AAS_ROUTING_CACHE_HEADER_SIZE = 48;

  /// <summary>maxWalkPathIterations, maxFlyPathIterations</summary>
  AAS_MAX_PATH_ITERATIONS = 10;

type
  /// <summary>aasPath_t: the answer of WalkPathToGoal and FlyPathToGoal</summary>
  TAasPath = record
    /// <summary>One of the PATHTYPE_ constants (type)</summary>
    Kind: Integer;
    /// <summary>Point the AI should move towards</summary>
    MoveGoal: TGeoVec3;
    /// <summary>Number of the area the AI should move towards</summary>
    MoveAreaNum: Integer;
    /// <summary>Secondary move goal for complex navigation</summary>
    SecondaryGoal: TGeoVec3;
    /// <summary>The reachability used for navigation; nil if none. Not owned: it belongs to the file</summary>
    Reachability: TAasReachability;
  end;

  /// <summary>aasGoal_t</summary>
  TAasGoal = record
    AreaNum: Integer;
    Origin: TGeoVec3;
  end;

  /// <summary>
  ///   aasObstacle_t. <c>ExpAbsBounds</c> is filled by FindNearestGoal from <c>AbsBounds</c>, as the
  ///   original does in its parameter
  /// </summary>
  TAasObstacle = record
    AbsBounds: TGeoBounds;
    ExpAbsBounds: TGeoBounds;
  end;

  /// <summary>
  ///   The routing data of a file is not valid for a query: a reachability that leads to an area
  ///   that does not exist, a cluster or portal that the file does not hold, more than
  ///   MAX_REACH_PER_AREA reachabilities in an area (gameLocal.Error in the original). Where the
  ///   original reads past the end of an array this exception takes its place
  /// </summary>
  EAasRoutingException = class(EAasFileException);

implementation

end.
