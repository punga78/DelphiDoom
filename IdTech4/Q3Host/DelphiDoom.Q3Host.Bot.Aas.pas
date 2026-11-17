{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the AAS half of the bot library        }
{  export table (aas_export_t) with the guards of the C                        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): be_interface.c, }
{  be_aas_*.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived  }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Aas;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Entity.Types, DelphiDoom.Aas.Main.System, DelphiDoom.Q3Host.Bot.Intf;

type
  /// <summary>
  ///   IQ3BotAas on the AAS system and the parts of the map that is loaded. What the C does when no map is loaded
  ///   (aasworld.loaded) or the AAS is not initialized (aasworld.initialized, set when the routing exists) is done
  ///   here: the answer 0 or the message, before any part is asked. The parts belong to the library, which gives
  ///   them with SetMap and the router with SetRouter
  /// </summary>
  TQ3BotAas = class(TInterfacedObject, IQ3BotAas)
  strict private
    FImport: IBotImport;
    FSystem: TAasSystem;
    FBsp: IAasBspWorld;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FBoxAreas: IAasBoxAreas;
    FAreas: IAasAreaQuery;
    FMovement: IAasMovement;
    FRouter: IAasRouter;
    function RangeError(const AWhat: string; AAreaNum: Integer): Integer;
  public
    /// <summary>The system and the BSP are not owned</summary>
    constructor Create(const AImport: IBotImport; const ASystem: TAasSystem; const ABsp: IAasBspWorld);
    procedure SetMap(const ASampler: IAasSampler; const ATracer: IAasTracer; const ABoxAreas: IAasBoxAreas;
      const AAreas: IAasAreaQuery; const AMovement: IAasMovement);
    procedure SetRouter(const ARouter: IAasRouter);
    procedure ClearMap;
    function EntityInfo(AEntity: Integer): TAasEntityInfo;
    function Initialized: Boolean;
    procedure PresenceTypeBoundingBox(APresenceType: Integer; out AMins, AMaxs: TVec3);
    function Time: Single;
    function PointAreaNum(const APoint: TVec3): Integer;
    function PointReachabilityAreaIndex(const APoint: PVec3): Integer;
    function TraceAreas(const AStart, AEnd: TVec3; AMaxAreas: Integer; out AAreas: TArray<Integer>;
      out APoints: TArray<TVec3>): Integer;
    function BBoxAreas(const AAbsMins, AAbsMaxs: TVec3; AMaxAreas: Integer): TArray<Integer>;
    function AreaInfo(AAreaNum: Integer; out AInfo: TAasAreaInfo): Integer;
    function PointContents(const APoint: TVec3): Integer;
    function NextBspEntity(AEntity: Integer): Integer;
    function ValueForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: AnsiString;
      ASize: Integer): Boolean;
    function VectorForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: TVec3): Boolean;
    function FloatForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: Single): Boolean;
    function IntForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: Integer): Boolean;
    function AreaReachability(AAreaNum: Integer): Integer;
    function AreaTravelTimeToGoalArea(AAreaNum: Integer; const AOrigin: PVec3; AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    function EnableRoutingArea(AAreaNum, AEnable: Integer): Integer;
    function PredictRoute(var ARoute: TAasPredictRoute; AAreaNum: Integer; const AOrigin: TVec3; AGoalAreaNum,
      ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags, AStopAreaNum: Integer): Boolean;
    function AlternativeRouteGoals(const AStart: TVec3; AStartAreaNum: Integer; const AGoal: TVec3; AGoalAreaNum,
      ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; AMaxGoals, AType: Integer): Integer;
    function Swimming(const AOrigin: TVec3): Boolean;
    function PredictClientMovement(out AMove: TAasClientMove; AEntityNum: Integer; const AOrigin: TVec3;
      APresenceType: Integer; AOnGround: Boolean; const AVelocity, ACmdMove: TVec3; ACmdFrames, AMaxFrames: Integer;
      AFrameTime: Single; AStopEvent, AStopAreaNum: Integer; AVisualize: Boolean): Boolean;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.BoxMath, DelphiDoom.Aas.Bsp.Intf;

const
  CONTENTS_LAVA = 8;
  CONTENTS_SLIME = 16;
  CONTENTS_WATER = 32;
  RSE_NONE = 0;
  RSE_NOROUTE = 1;

resourcestring
  SAreaOutOfRange = '%s: areanum %d out of range'#10;
  SNotLoaded = 'AAS_LinkEntity: aas not loaded'#10;
  SBspEntityOutOfRange = 'bsp entity out of range'#10;

constructor TQ3BotAas.Create(const AImport: IBotImport; const ASystem: TAasSystem; const ABsp: IAasBspWorld);
begin
  inherited Create;
  FImport := AImport;
  FSystem := ASystem;
  FBsp := ABsp;
end;

procedure TQ3BotAas.SetMap(const ASampler: IAasSampler; const ATracer: IAasTracer; const ABoxAreas: IAasBoxAreas;
  const AAreas: IAasAreaQuery; const AMovement: IAasMovement);
begin
  FSampler := ASampler;
  FTracer := ATracer;
  FBoxAreas := ABoxAreas;
  FAreas := AAreas;
  FMovement := AMovement;
end;

procedure TQ3BotAas.SetRouter(const ARouter: IAasRouter);
begin
  FRouter := ARouter;
end;

procedure TQ3BotAas.ClearMap;
begin
  FSampler := nil;
  FTracer := nil;
  FBoxAreas := nil;
  FAreas := nil;
  FMovement := nil;
  FRouter := nil;
end;

// AAS_Error: botimport.Print( PRT_FATAL ... ); the map has no area, so every number is out of range
function TQ3BotAas.RangeError(const AWhat: string; AAreaNum: Integer): Integer;
begin
  FImport.Print(PRT_FATAL, AnsiString(Format(SAreaOutOfRange, [AWhat, AAreaNum])));
  Result := 0;
end;

function TQ3BotAas.EntityInfo(AEntity: Integer): TAasEntityInfo;
begin
  Result := FSystem.Entities.EntityInfo(AEntity);
end;

function TQ3BotAas.Initialized: Boolean;
begin
  Result := FSystem.Initialized;
end;

procedure TQ3BotAas.PresenceTypeBoundingBox(APresenceType: Integer; out AMins, AMaxs: TVec3);
begin
  TAasBoxMath.PresenceTypeBoundingBox(FImport, APresenceType, AMins, AMaxs);
end;

function TQ3BotAas.Time: Single;
begin
  Result := FSystem.Time;
end;

function TQ3BotAas.PointAreaNum(const APoint: TVec3): Integer;
begin
  if not FSystem.Loaded or not Assigned(FSampler) then
    Exit(0);
  Result := FSampler.PointAreaNum(APoint);
end;

function TQ3BotAas.PointReachabilityAreaIndex(const APoint: PVec3): Integer;
begin
  if not FSystem.Initialized or not Assigned(FSampler) then
    Exit(0);
  // a NULL point is the number of reachability areas of the whole map
  if not Assigned(APoint) then
    Exit(FSampler.ReachabilityAreaCount);
  Result := FSampler.PointReachabilityAreaIndex(APoint^);
end;

function TQ3BotAas.TraceAreas(const AStart, AEnd: TVec3; AMaxAreas: Integer; out AAreas: TArray<Integer>;
  out APoints: TArray<TVec3>): Integer;
begin
  AAreas := nil;
  APoints := nil;
  if not FSystem.Loaded or not Assigned(FTracer) then
    Exit(0);
  Result := FTracer.TraceAreas(AStart, AEnd, AMaxAreas, AAreas, APoints);
end;

function TQ3BotAas.BBoxAreas(const AAbsMins, AAbsMaxs: TVec3; AMaxAreas: Integer): TArray<Integer>;
begin
  if not FSystem.Loaded or not Assigned(FBoxAreas) then
  begin
    FImport.Print(PRT_ERROR, AnsiString(SNotLoaded));
    Exit(nil);
  end;
  Result := FBoxAreas.BBoxAreas(AAbsMins, AAbsMaxs, AMaxAreas);
end;

function TQ3BotAas.AreaInfo(AAreaNum: Integer; out AInfo: TAasAreaInfo): Integer;
begin
  AInfo := Default(TAasAreaInfo);
  if not Assigned(FAreas) then
  begin
    FImport.Print(PRT_ERROR, AnsiString(Format(SAreaOutOfRange, ['AAS_AreaInfo', AAreaNum])));
    Exit(0);
  end;
  Result := FAreas.AreaInfo(AAreaNum, AInfo);
end;

function TQ3BotAas.PointContents(const APoint: TVec3): Integer;
begin
  Result := FBsp.PointContents(APoint);
end;

function TQ3BotAas.NextBspEntity(AEntity: Integer): Integer;
begin
  if not Assigned(FSystem.BspEntities) then
    Exit(0);
  Result := FSystem.BspEntities.NextEntity(AEntity);
end;

function TQ3BotAas.ValueForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: AnsiString;
  ASize: Integer): Boolean;
begin
  AValue := '';
  if not Assigned(FSystem.BspEntities) then
  begin
    FImport.Print(PRT_MESSAGE, AnsiString(SBspEntityOutOfRange));
    Exit(False);
  end;
  Result := FSystem.BspEntities.ValueForKey(AEntity, AKey, AValue, ASize);
end;

function TQ3BotAas.VectorForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: TVec3): Boolean;
begin
  AValue := Default(TVec3);
  if not Assigned(FSystem.BspEntities) then
  begin
    FImport.Print(PRT_MESSAGE, AnsiString(SBspEntityOutOfRange));
    Exit(False);
  end;
  Result := FSystem.BspEntities.VectorForKey(AEntity, AKey, AValue);
end;

function TQ3BotAas.FloatForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: Single): Boolean;
begin
  AValue := 0;
  if not Assigned(FSystem.BspEntities) then
  begin
    FImport.Print(PRT_MESSAGE, AnsiString(SBspEntityOutOfRange));
    Exit(False);
  end;
  Result := FSystem.BspEntities.FloatForKey(AEntity, AKey, AValue);
end;

function TQ3BotAas.IntForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: Integer): Boolean;
begin
  AValue := 0;
  if not Assigned(FSystem.BspEntities) then
  begin
    FImport.Print(PRT_MESSAGE, AnsiString(SBspEntityOutOfRange));
    Exit(False);
  end;
  Result := FSystem.BspEntities.IntForKey(AEntity, AKey, AValue);
end;

function TQ3BotAas.AreaReachability(AAreaNum: Integer): Integer;
begin
  if not Assigned(FAreas) then
    Exit(RangeError('AAS_AreaReachability', AAreaNum));
  Result := FAreas.AreaReachability(AAreaNum);
end;

function TQ3BotAas.AreaTravelTimeToGoalArea(AAreaNum: Integer; const AOrigin: PVec3; AGoalAreaNum,
  ATravelFlags: Integer): Integer;
begin
  // not initialized: no routing, no time
  if not Assigned(FRouter) then
    Exit(0);
  Result := FRouter.AreaTravelTimeToGoalArea(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags);
end;

function TQ3BotAas.EnableRoutingArea(AAreaNum, AEnable: Integer): Integer;
begin
  if not Assigned(FRouter) then
    Exit(0);
  Result := FRouter.EnableRoutingArea(AAreaNum, AEnable);
end;

function TQ3BotAas.PredictRoute(var ARoute: TAasPredictRoute; AAreaNum: Integer; const AOrigin: TVec3; AGoalAreaNum,
  ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags, AStopAreaNum: Integer): Boolean;
begin
  if Assigned(FRouter) then
    Exit(FRouter.PredictRoute(ARoute, AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags, AMaxAreas, AMaxTime,
      AStopEvent, AStopContents, AStopTravelFlags, AStopAreaNum));
  // no routing: the output is initialized; a map with areas has no reachability to the goal, no map has no loop
  ARoute.StopEvent := RSE_NONE;
  ARoute.EndArea := AGoalAreaNum;
  ARoute.EndContents := 0;
  ARoute.EndTravelFlags := 0;
  ARoute.EndPos := AOrigin;
  ARoute.Time := 0;
  Result := AAreaNum = AGoalAreaNum;
  if not Result and FSystem.Loaded then
    ARoute.StopEvent := RSE_NOROUTE;
end;

function TQ3BotAas.AlternativeRouteGoals(const AStart: TVec3; AStartAreaNum: Integer; const AGoal: TVec3;
  AGoalAreaNum, ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; AMaxGoals, AType: Integer): Integer;
begin
  if not Assigned(FRouter) then
    Exit(0);
  Result := FRouter.AlternativeRouteGoals(AStart, AStartAreaNum, AGoal, AGoalAreaNum, ATravelFlags, AGoals, AMaxGoals,
    AType);
end;

function TQ3BotAas.Swimming(const AOrigin: TVec3): Boolean;
var
  LTest: TVec3;
begin
  if Assigned(FMovement) then
    Exit(FMovement.Swimming(AOrigin));
  // AAS_Swimming needs the BSP only
  LTest := AOrigin;
  LTest[2] := LTest[2] - 2;
  Result := (FBsp.PointContents(LTest) and (CONTENTS_LAVA or CONTENTS_SLIME or CONTENTS_WATER)) <> 0;
end;

function TQ3BotAas.PredictClientMovement(out AMove: TAasClientMove; AEntityNum: Integer; const AOrigin: TVec3;
  APresenceType: Integer; AOnGround: Boolean; const AVelocity, ACmdMove: TVec3; ACmdFrames, AMaxFrames: Integer;
  AFrameTime: Single; AStopEvent, AStopAreaNum: Integer; AVisualize: Boolean): Boolean;
begin
  AMove := Default(TAasClientMove);
  if not Assigned(FMovement) then
    Exit(False);
  Result := FMovement.PredictClientMovement(AMove, AEntityNum, AOrigin, APresenceType, AOnGround, AVelocity,
    ACmdMove, ACmdFrames, AMaxFrames, AFrameTime, AStopEvent, AStopAreaNum, AVisualize);
end;

end.
