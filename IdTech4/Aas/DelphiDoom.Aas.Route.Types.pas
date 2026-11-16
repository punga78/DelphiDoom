{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - routing types and travel flags of Quake III       }
{                                                                              }
{  Constants and records of game/be_aas.h and botlib/be_aas_def.h that the     }
{  routing (be_aas_route.c, be_aas_routealt.c) uses. Based on the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.Types;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

const
  /// <summary>The travel flags of game/be_aas.h (TFL_*): what a bot may do while it travels</summary>
  TFL_INVALID = $00000001;
  TFL_WALK = $00000002;
  TFL_CROUCH = $00000004;
  TFL_BARRIERJUMP = $00000008;
  TFL_JUMP = $00000010;
  TFL_LADDER = $00000020;
  TFL_WALKOFFLEDGE = $00000080;
  TFL_SWIM = $00000100;
  TFL_WATERJUMP = $00000200;
  TFL_TELEPORT = $00000400;
  TFL_ELEVATOR = $00000800;
  TFL_ROCKETJUMP = $00001000;
  TFL_BFGJUMP = $00002000;
  TFL_GRAPPLEHOOK = $00004000;
  TFL_DOUBLEJUMP = $00008000;
  TFL_RAMPJUMP = $00010000;
  TFL_STRAFEJUMP = $00020000;
  TFL_JUMPPAD = $00040000;
  TFL_AIR = $00080000;
  TFL_WATER = $00100000;
  TFL_SLIME = $00200000;
  TFL_LAVA = $00400000;
  TFL_DONOTENTER = $00800000;
  TFL_FUNCBOB = $01000000;
  TFL_FLIGHT = $02000000;
  TFL_BRIDGE = $04000000;
  TFL_NOTTEAM1 = $08000000;
  TFL_NOTTEAM2 = $10000000;
  /// <summary>TFL_DEFAULT: what a bot does when nothing else is said</summary>
  TFL_DEFAULT = TFL_WALK or TFL_CROUCH or TFL_BARRIERJUMP or TFL_JUMP or TFL_LADDER or TFL_WALKOFFLEDGE or
    TFL_SWIM or TFL_WATERJUMP or TFL_TELEPORT or TFL_ELEVATOR or TFL_AIR or TFL_WATER or TFL_JUMPPAD or TFL_FUNCBOB;

  /// <summary>The route prediction stop events (RSE_*)</summary>
  RSE_NONE = 0;
  RSE_NOROUTE = 1;
  RSE_USETRAVELTYPE = 2;
  RSE_ENTERCONTENTS = 4;
  RSE_ENTERAREA = 8;

  /// <summary>The types of alternative route goals (ALTROUTEGOAL_*)</summary>
  ALTROUTEGOAL_ALL = 1;
  ALTROUTEGOAL_CLUSTERPORTALS = 2;
  ALTROUTEGOAL_VIEWPORTALS = 4;

  /// <summary>CACHETYPE_PORTAL and CACHETYPE_AREA of be_aas_def.h</summary>
  ROUTE_CACHETYPE_PORTAL = 0;
  ROUTE_CACHETYPE_AREA = 1;

  /// <summary>MAX_REACHABILITYPASSAREAS: the areas that a reachability goes through are at most so many</summary>
  MAX_REACHABILITYPASSAREAS = 32;
  /// <summary>The reachabilities of an area that the routing looks at (the reversed links and the update arrays hold 128)</summary>
  MAX_ROUTE_REACHABILITIES = 128;
  /// <summary>
  ///   sizeof(aas_routingcache_t) of the 32 bit build of the original without the table (type, time, size, cluster,
  ///   areanum, origin, starttraveltime, travelflags, four links, reachabilities, one travel time): the memory
  ///   of a cache is counted with it
  /// </summary>
  ROUTE_CACHE_HEADER_SIZE = 64;

type
  /// <summary>A pointer to a vector: the routing functions take NULL for "no origin"</summary>
  PVec3 = ^TVec3;

  /// <summary>aas_predictroute_t</summary>
  TAasPredictRoute = record
    /// <summary>Position at the end of the movement prediction</summary>
    EndPos: TVec3;
    EndArea: Integer;
    StopEvent: Integer;
    EndContents: Integer;
    EndTravelFlags: Integer;
    NumAreas: Integer;
    /// <summary>Time predicted ahead, in hundreth of a second</summary>
    Time: Integer;
  end;

  /// <summary>aas_altroutegoal_t</summary>
  TAasAltRouteGoal = record
    Origin: TVec3;
    AreaNum: Integer;
    StartTravelTime: Word;
    GoalTravelTime: Word;
    ExtraTravelTime: Word;
  end;

  /// <summary>
  ///   The AAS file cannot be routed on: a number that the routing uses to index an array is outside the arrays of
  ///   the file (the original reads or writes outside the memory)
  /// </summary>
  EAasRouteException = class(Exception);

implementation

end.
