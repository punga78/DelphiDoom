{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the routing of an AAS that is not      }
{  initialized yet                                                             }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): be_aas_route.c. }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.NullRouter;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types,
  DelphiDoom.Aas.Route.Intf;

type
  /// <summary>
  ///   What the routing functions of the C answer while aasworld.initialized is false: no route, no travel time, no
  ///   reachability (the router of the map exists only when the initialization has finished). The bots ask the
  ///   world for a router at any time, so they get this one until then
  /// </summary>
  TQ3BotNullRouter = class(TInterfacedObject, IAasRouter)
  public
    function AreaRouteToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
      ATravelFlags: Integer; var ATravelTime, AReachNum: Integer): Boolean;
    function AreaTravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    function AreaReachabilityToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    function PredictRoute(var ARoute: TAasPredictRoute; const AAreaNum: Integer; const AOrigin: TVec3;
      const AGoalAreaNum, ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags,
      AStopAreaNum: Integer): Boolean;
    function EnableRoutingArea(const AAreaNum, AEnable: Integer): Integer;
    function AreaContentsTravelFlags(const AAreaNum: Integer): Integer;
    function AreaTravelTime(const AAreaNum: Integer; const AStart, AEnd: TVec3): Integer;
    function TravelFlagForType(const ATravelType: Integer): Integer;
    procedure ReachabilityFromNum(const ANum: Integer; var AReach: TAasReachability);
    function NextAreaReachability(const AAreaNum, AReachNum: Integer): Integer;
    function NextModelReachability(const ANum, AModelNum: Integer): Integer;
    function NearestHideArea(const ASrcNum: Integer; const AOrigin: TVec3; const AAreaNum, AEnemyNum: Integer;
      const AEnemyOrigin: TVec3; const AEnemyAreaNum, ATravelFlags: Integer): Integer;
    function AlternativeRouteGoals(const AStart: TVec3; const AStartAreaNum: Integer; const AGoal: TVec3;
      const AGoalAreaNum, ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; const AMaxGoals,
      AType: Integer): Integer;
    procedure CacheStatistics(out AAreaCaches, APortalCaches, AMemory: Integer);
    procedure UpdateCounts(out AAreaUpdates, APortalUpdates: Integer);
  end;

implementation

function TQ3BotNullRouter.AreaRouteToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
  ATravelFlags: Integer; var ATravelTime, AReachNum: Integer): Boolean;
begin
  Result := False;
end;

function TQ3BotNullRouter.AreaTravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3;
  const AGoalAreaNum, ATravelFlags: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.AreaReachabilityToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3;
  const AGoalAreaNum, ATravelFlags: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.PredictRoute(var ARoute: TAasPredictRoute; const AAreaNum: Integer; const AOrigin: TVec3;
  const AGoalAreaNum, ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags,
  AStopAreaNum: Integer): Boolean;
begin
  ARoute.StopEvent := 0;
  ARoute.EndArea := AGoalAreaNum;
  ARoute.EndContents := 0;
  ARoute.EndTravelFlags := 0;
  ARoute.EndPos := AOrigin;
  ARoute.Time := 0;
  Result := AAreaNum = AGoalAreaNum;
end;

function TQ3BotNullRouter.EnableRoutingArea(const AAreaNum, AEnable: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.AreaContentsTravelFlags(const AAreaNum: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.AreaTravelTime(const AAreaNum: Integer; const AStart, AEnd: TVec3): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.TravelFlagForType(const ATravelType: Integer): Integer;
begin
  Result := 0;
end;

procedure TQ3BotNullRouter.ReachabilityFromNum(const ANum: Integer; var AReach: TAasReachability);
begin
  AReach := Default(TAasReachability);
end;

function TQ3BotNullRouter.NextAreaReachability(const AAreaNum, AReachNum: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.NextModelReachability(const ANum, AModelNum: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.NearestHideArea(const ASrcNum: Integer; const AOrigin: TVec3; const AAreaNum,
  AEnemyNum: Integer; const AEnemyOrigin: TVec3; const AEnemyAreaNum, ATravelFlags: Integer): Integer;
begin
  Result := 0;
end;

function TQ3BotNullRouter.AlternativeRouteGoals(const AStart: TVec3; const AStartAreaNum: Integer;
  const AGoal: TVec3; const AGoalAreaNum, ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; const AMaxGoals,
  AType: Integer): Integer;
begin
  Result := 0;
end;

procedure TQ3BotNullRouter.CacheStatistics(out AAreaCaches, APortalCaches, AMemory: Integer);
begin
  AAreaCaches := 0;
  APortalCaches := 0;
  AMemory := 0;
end;

procedure TQ3BotNullRouter.UpdateCounts(out AAreaUpdates, APortalUpdates: Integer);
begin
  AAreaUpdates := 0;
  APortalUpdates := 0;
end;

end.
