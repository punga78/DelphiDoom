{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contract of the routing of Quake III              }
{                                                                              }
{  The functions of be_aas_route.c and be_aas_routealt.c that the bot AI        }
{  (be_ai_goal.c, be_ai_move.c) calls. Based on the Quake III Arena GPL        }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.Intf;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types;

type
  /// <summary>
  ///   The memory that the game has left (AvailableMemory of l_memory.c): the routing drops the oldest caches
  ///   while less than 1 MB is available
  /// </summary>
  IAasRoutingMemory = interface
    ['{5B3E2A10-7C94-4E61-A8D5-1F0B6C93D207}']
    function AvailableMemory: Integer;
  end;

  /// <summary>
  ///   The routing of the bots on an AAS file: travel times, the reachability to take, route prediction and
  ///   alternative routes. Reachabilities are numbers into the reachability lump of the file; 0 is "none"
  /// </summary>
  IAasRouter = interface
    ['{5B3E2A10-7C94-4E61-A8D5-1F0B6C93D208}']
    /// <summary>
    ///   The travel time (hundreth of a second) and the number of the reachability to take from an area to a goal area.
    ///   <c>AOrigin</c> may be nil: then the time within the first area is not counted and, with a route through
    ///   a portal, the reachability is not set (AAS_AreaRouteToGoalArea)
    /// </summary>
    function AreaRouteToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
      ATravelFlags: Integer; var ATravelTime, AReachNum: Integer): Boolean;
    /// <summary>0 if there is no route</summary>
    function AreaTravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    /// <summary>0 if there is no route</summary>
    function AreaReachabilityToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    /// <summary>Follows the route and stops on an event (AAS_PredictRoute)</summary>
    function PredictRoute(var ARoute: TAasPredictRoute; const AAreaNum: Integer; const AOrigin: TVec3;
      const AGoalAreaNum, ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags,
      AStopAreaNum: Integer): Boolean;
    /// <summary>
    ///   Enables (1), disables (0) or reads (-1) a routing area: a disabled area is not entered and the caches that use it
    ///   are dropped. Returns whether it was enabled
    /// </summary>
    function EnableRoutingArea(const AAreaNum, AEnable: Integer): Integer;
    function AreaContentsTravelFlags(const AAreaNum: Integer): Integer;
    /// <summary>AAS_AreaTravelTime: the time to cross the area from the start to the end (at least 1, hundredths of a second)</summary>
    function AreaTravelTime(const AAreaNum: Integer; const AStart, AEnd: TVec3): Integer;
    function TravelFlagForType(const ATravelType: Integer): Integer;
    /// <summary>A copy of the reachability; zeros if the number is not in the file</summary>
    procedure ReachabilityFromNum(const ANum: Integer; var AReach: TAasReachability);
    /// <summary>The next reachability of the area after <c>AReachNum</c> (0 starts), 0 at the end</summary>
    function NextAreaReachability(const AAreaNum, AReachNum: Integer): Integer;
    /// <summary>The next elevator or bobbing reachability of a model after <c>ANum</c></summary>
    function NextModelReachability(const ANum, AModelNum: Integer): Integer;
    /// <summary>The nearest area to the source that the enemy cannot see (always visible: AAS_AreaVisible is a stub)</summary>
    function NearestHideArea(const ASrcNum: Integer; const AOrigin: TVec3; const AAreaNum, AEnemyNum: Integer;
      const AEnemyOrigin: TVec3; const AEnemyAreaNum, ATravelFlags: Integer): Integer;
    /// <summary>
    ///   Goals of alternative routes between the start and the goal (AAS_AlternativeRouteGoals); the number found,
    ///   at most the length of <c>AGoals</c>
    /// </summary>
    function AlternativeRouteGoals(const AStart: TVec3; const AStartAreaNum: Integer; const AGoal: TVec3;
      const AGoalAreaNum, ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; const AMaxGoals,
      AType: Integer): Integer;
    /// <summary>How many caches of each kind there are and the memory counted for them</summary>
    procedure CacheStatistics(out AAreaCaches, APortalCaches, AMemory: Integer);
    /// <summary>The number of routing updates of the cluster and portal caches since the last reset (numareacacheupdates, numportalcacheupdates)</summary>
    procedure UpdateCounts(out AAreaUpdates, APortalUpdates: Integer);
  end;

implementation

end.
