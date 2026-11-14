{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - routes between areas (be_aas_route.c)             }
{                                                                              }
{  Port of AAS_AreaRouteToGoalArea, AAS_AreaTravelTimeToGoalArea,              }
{  AAS_AreaReachabilityToGoalArea, AAS_PredictRoute, AAS_EnableRoutingArea,    }
{  AAS_ReachabilityFromNum, AAS_NextAreaReachability,                          }
{  AAS_NextModelReachability and AAS_NearestHideArea. Based on the Quake III   }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.Router;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Route.Data,
  DelphiDoom.Aas.Route.CacheStore, DelphiDoom.Aas.Route.Alternative;

type
  /// <summary>
  ///   The routing of one AAS file (aasworld.initialized is true once it is made). It owns the route data, the caches
  ///   and the alternative routes; the file, the import, the tracer and the memory are not owned. Hold it as an
  ///   interface
  /// </summary>
  TAasRouter = class(TInterfacedObject, IAasRouter)
  strict private
    FImport: IBotImport;
    FMemory: IAasRoutingMemory;
    FDeveloper: Boolean;
    FAreaSettings: TArray<TAasAreaSettings>;
    FReachability: TArray<TAasReachability>;
    FData: TAasRouteData;
    FStore: TAasRouteCacheStore;
    FAlternative: TAasAlternativeRoutes;
    FHideTravelTimes: TArray<Word>;
    FClusters: TArray<TAasCluster>;
    FPortals: TArray<TAasPortal>;
    FPortalIndex: TArray<Integer>;
    procedure ReportRange(const AFunction: string; const AName: string; const ANumber: Integer);
    procedure Project(const APoint, AStart, AEnd: TVec3; var AProjection: TVec3);
  public
    /// <summary>
    ///   Makes the routing data (AAS_InitRouting). <c>AMemory</c> may be nil (the caches are never dropped for lack of
    ///   memory); <c>ADeveloper</c> is bot_developer: the errors about areas that are out of range are printed
    ///   only then
    /// </summary>
    constructor Create(const AFile: IAasFile; const AImport: IBotImport; const ATracer: IAasTracer;
      const AMemory: IAasRoutingMemory; const ADeveloper: Boolean);
    destructor Destroy; override;
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
    /// <summary>The data of the routing: the reversed links, the travel times of the areas, the portal times (for tests)</summary>
    property RouteData: TAasRouteData read FData;
    /// <summary>The caches (for tests)</summary>
    property CacheStore: TAasRouteCacheStore read FStore;
    procedure UpdateCounts(out AAreaUpdates, APortalUpdates: Integer);
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Route.Cache;

resourcestring
  SRangeArea = '%s: areanum %d out of range'#10;
  SRangeGoal = '%s: goalareanum %d out of range'#10;
  SEnableRange = 'AAS_EnableRoutingArea: areanum %d out of range'#10;
  SNextRange = 'AAS_NextAreaReachability: areanum %d out of range'#10;
  SNextFatal = 'AAS_NextAreaReachability: reachnum < settings->firstreachableara';

const
  // 1 * 1024 * 1024: the routing drops caches while less memory than this is available
  CMinimumMemory = 1024 * 1024;
  CTen: Single = 10.0;

{ TAasRouter }

constructor TAasRouter.Create(const AFile: IAasFile; const AImport: IBotImport; const ATracer: IAasTracer;
  const AMemory: IAasRoutingMemory; const ADeveloper: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FMemory := AMemory;
  FDeveloper := ADeveloper;
  FData := TAasRouteData.Create(AFile, AImport, ATracer);
  try
    FStore := TAasRouteCacheStore.Create(AFile, FData);
    FAlternative := TAasAlternativeRoutes.Create(AFile);
  except
    FStore.Free;
    FData.Free;
    raise;
  end;
  FAreaSettings := FData.AreaSettings;
  FClusters := AFile.Clusters;
  FPortals := AFile.Portals;
  FPortalIndex := AFile.PortalIndex;
  FReachability := FData.Reachability;
  SetLength(FHideTravelTimes, FData.AreaCount);
end;

destructor TAasRouter.Destroy;
begin
  FAlternative.Free;
  FStore.Free;
  FData.Free;
  inherited Destroy;
end;

procedure TAasRouter.ReportRange(const AFunction: string; const AName: string; const ANumber: Integer);
begin
  if not FDeveloper then
    Exit;
  if AName = 'area' then
    FImport.Print(PRT_ERROR, AnsiString(Format(SRangeArea, [AFunction, ANumber])))
  else
    FImport.Print(PRT_ERROR, AnsiString(Format(SRangeGoal, [AFunction, ANumber])));
end;

function TAasRouter.AreaRouteToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
  ATravelFlags: Integer; var ATravelTime, AReachNum: Integer): Boolean;
var
  LClusterNum, LGoalClusterNum, LPortalNum, LIndex, LClusterAreaNum, LBestReachNum, LTravelFlags: Integer;
  LTime, LBestTime: Word;
  LPortal: TAasPortal;
  LCluster: TAasCluster;
  LAreaCache, LPortalCache: TAasRouteCache;
begin
  LTravelFlags := ATravelFlags;
  if AAreaNum = AGoalAreaNum then
  begin
    ATravelTime := 1;
    AReachNum := 0;
    Exit(True);
  end;
  if (AAreaNum <= 0) or (AAreaNum >= FData.AreaCount) then
  begin
    ReportRange('AAS_AreaTravelTimeToGoalArea', 'area', AAreaNum);
    Exit(False);
  end;
  if (AGoalAreaNum <= 0) or (AGoalAreaNum >= FData.AreaCount) then
  begin
    ReportRange('AAS_AreaTravelTimeToGoalArea', 'goal', AGoalAreaNum);
    Exit(False);
  end;
  // make sure the routing cache doesn't grow to large
  if Assigned(FMemory) then
    while FMemory.AvailableMemory < CMinimumMemory do
      if not FStore.FreeOldestCache then
        Break;
  if ((FAreaSettings[AAreaNum].Contents and AREACONTENTS_DONOTENTER) <> 0) or
    ((FAreaSettings[AGoalAreaNum].Contents and AREACONTENTS_DONOTENTER) <> 0) then
    LTravelFlags := LTravelFlags or TFL_DONOTENTER;
  try
    LClusterNum := FAreaSettings[AAreaNum].Cluster;
    LGoalClusterNum := FAreaSettings[AGoalAreaNum].Cluster;
    // check if the area is a portal of the goal area cluster
    if (LClusterNum < 0) and (LGoalClusterNum > 0) then
    begin
      LPortal := FPortals[-LClusterNum];
      if (LPortal.FrontCluster = LGoalClusterNum) or (LPortal.BackCluster = LGoalClusterNum) then
        LClusterNum := LGoalClusterNum;
    end
    // check if the goalarea is a portal of the area cluster
    else if (LClusterNum > 0) and (LGoalClusterNum < 0) then
    begin
      LPortal := FPortals[-LGoalClusterNum];
      if (LPortal.FrontCluster = LClusterNum) or (LPortal.BackCluster = LClusterNum) then
        LGoalClusterNum := LClusterNum;
    end;
    // if both areas are in the same cluster
    // NOTE: there might be a shorter route via another cluster!!! but we don't care
    if (LClusterNum > 0) and (LGoalClusterNum > 0) and (LClusterNum = LGoalClusterNum) then
    begin
      LAreaCache := FStore.GetAreaRoutingCache(LClusterNum, AGoalAreaNum, LTravelFlags);
      // the number of the area in the cluster
      LClusterAreaNum := FStore.ClusterAreaNum(LClusterNum, AAreaNum);
      LCluster := FClusters[LClusterNum];
      // if the area is NOT a reachability area
      if LClusterAreaNum >= LCluster.NumReachabilityAreas then
        Exit(False);
      // if it is possible to travel to the goal area through this cluster
      if LAreaCache.TravelTimes[LClusterAreaNum] <> 0 then
      begin
        AReachNum := FAreaSettings[AAreaNum].FirstReachableArea + LAreaCache.Reachabilities[LClusterAreaNum];
        if not Assigned(AOrigin) then
        begin
          ATravelTime := LAreaCache.TravelTimes[LClusterAreaNum];
          Exit(True);
        end;
        ATravelTime := LAreaCache.TravelTimes[LClusterAreaNum] +
          FData.AreaTravelTime(AAreaNum, AOrigin^, FReachability[AReachNum].StartPoint);
        Exit(True);
      end;
    end;

    LClusterNum := FAreaSettings[AAreaNum].Cluster;
    LGoalClusterNum := FAreaSettings[AGoalAreaNum].Cluster;
    // if the goal area is a portal
    if LGoalClusterNum < 0 then
    begin
      // just assume the goal area is part of the front cluster
      LPortal := FPortals[-LGoalClusterNum];
      LGoalClusterNum := LPortal.FrontCluster;
    end;
    // get the portal routing cache
    LPortalCache := FStore.GetPortalRoutingCache(LGoalClusterNum, AGoalAreaNum, LTravelFlags);
    // if the area is a cluster portal, read directly from the portal cache
    if LClusterNum < 0 then
    begin
      ATravelTime := LPortalCache.TravelTimes[-LClusterNum];
      AReachNum := FAreaSettings[AAreaNum].FirstReachableArea + LPortalCache.Reachabilities[-LClusterNum];
      Exit(True);
    end;

    LBestTime := 0;
    LBestReachNum := -1;
    // the cluster the area is in
    LCluster := FClusters[LClusterNum];
    // find the portal of the area cluster leading towards the goal area
    for LIndex := 0 to LCluster.NumPortals - 1 do
    begin
      LPortalNum := FPortalIndex[LCluster.FirstPortal + LIndex];
      // if the goal area isn't reachable from the portal
      if LPortalCache.TravelTimes[LPortalNum] = 0 then
        Continue;
      LPortal := FPortals[LPortalNum];
      // get the cache of the portal area
      LAreaCache := FStore.GetAreaRoutingCache(LClusterNum, LPortal.AreaNum, LTravelFlags);
      // current area inside the current cluster
      LClusterAreaNum := FStore.ClusterAreaNum(LClusterNum, AAreaNum);
      // if the area is NOT a reachability area
      if LClusterAreaNum >= LCluster.NumReachabilityAreas then
        Continue;
      // if the portal is NOT reachable from this area
      if LAreaCache.TravelTimes[LClusterAreaNum] = 0 then
        Continue;
      // total travel time is the travel time the portal area is from the goal area plus the travel time towards
      // the portal area; for now the largest travel time through the portal area is added
      LTime := Word(LPortalCache.TravelTimes[LPortalNum] + LAreaCache.TravelTimes[LClusterAreaNum]);
      LTime := Word(LTime + FData.PortalMaxTravelTimes[LPortalNum]);
      if Assigned(AOrigin) then
      begin
        AReachNum := FAreaSettings[AAreaNum].FirstReachableArea + LAreaCache.Reachabilities[LClusterAreaNum];
        LTime := Word(LTime + FData.AreaTravelTime(AAreaNum, AOrigin^, FReachability[AReachNum].StartPoint));
      end;
      // if the time is better than the one already found
      if (LBestTime = 0) or (LTime < LBestTime) then
      begin
        LBestReachNum := AReachNum;
        LBestTime := LTime;
      end;
    end;
    if LBestReachNum < 0 then
      Exit(False);
    AReachNum := LBestReachNum;
    ATravelTime := LBestTime;
    Result := True;
  except
    on EAasRouteException do
    begin
      // a cache that was half made must not stay in the store
      FStore.Clear;
      raise;
    end;
  end;
end;

function TAasRouter.AreaTravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
  ATravelFlags: Integer): Integer;
var
  LReachNum: Integer;
begin
  LReachNum := 0;
  if not AreaRouteToGoalArea(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags, Result, LReachNum) then
    Result := 0;
end;

function TAasRouter.AreaReachabilityToGoalArea(const AAreaNum: Integer; const AOrigin: PVec3; const AGoalAreaNum,
  ATravelFlags: Integer): Integer;
var
  LTravelTime: Integer;
begin
  Result := 0;
  if not AreaRouteToGoalArea(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags, LTravelTime, Result) then
    Result := 0;
end;

function TAasRouter.PredictRoute(var ARoute: TAasPredictRoute; const AAreaNum: Integer; const AOrigin: TVec3;
  const AGoalAreaNum, ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags,
  AStopAreaNum: Integer): Boolean;
var
  LCurArea, LReachNum, LIndex, LJ, LTestArea: Integer;
  LCurOrigin: TVec3;
  LReach: TAasReachability;
begin
  // init output
  ARoute.StopEvent := RSE_NONE;
  ARoute.EndArea := AGoalAreaNum;
  ARoute.EndContents := 0;
  ARoute.EndTravelFlags := 0;
  ARoute.EndPos := AOrigin;
  ARoute.Time := 0;

  LCurArea := AAreaNum;
  LCurOrigin := AOrigin;

  LIndex := 0;
  while (LCurArea <> AGoalAreaNum) and ((AMaxAreas = 0) or (LIndex < AMaxAreas)) and (LIndex < FData.AreaCount) do
  begin
    LReachNum := AreaReachabilityToGoalArea(LCurArea, @LCurOrigin, AGoalAreaNum, ATravelFlags);
    if LReachNum = 0 then
    begin
      ARoute.StopEvent := RSE_NOROUTE;
      Exit(False);
    end;
    LReach := FReachability[LReachNum];

    if (AStopEvent and RSE_USETRAVELTYPE) <> 0 then
    begin
      if (FData.TravelFlagForType(LReach.TravelType) and AStopTravelFlags) <> 0 then
      begin
        ARoute.StopEvent := RSE_USETRAVELTYPE;
        ARoute.EndArea := LCurArea;
        ARoute.EndContents := FAreaSettings[LCurArea].Contents;
        ARoute.EndTravelFlags := FData.TravelFlagForType(LReach.TravelType);
        ARoute.EndPos := LReach.StartPoint;
        Exit(True);
      end;
      if (FData.AreaContentsTravelFlags(LReach.AreaNum) and AStopTravelFlags) <> 0 then
      begin
        ARoute.StopEvent := RSE_USETRAVELTYPE;
        ARoute.EndArea := LReach.AreaNum;
        ARoute.EndContents := FAreaSettings[LReach.AreaNum].Contents;
        ARoute.EndTravelFlags := FData.AreaContentsTravelFlags(LReach.AreaNum);
        ARoute.EndPos := LReach.EndPoint;
        Inc(ARoute.Time, FData.AreaTravelTime(AAreaNum, AOrigin, LReach.StartPoint));
        Inc(ARoute.Time, LReach.TravelTime);
        Exit(True);
      end;
    end;
    for LJ := 0 to FData.ReachabilityAreaCount[LReachNum] do
    begin
      if LJ >= FData.ReachabilityAreaCount[LReachNum] then
        LTestArea := LReach.AreaNum
      else
        LTestArea := FData.ReachabilityAreaIndex[FData.ReachabilityAreaFirst[LReachNum] + LJ];
      if (AStopEvent and RSE_ENTERCONTENTS) <> 0 then
        if (FAreaSettings[LTestArea].Contents and AStopContents) <> 0 then
        begin
          ARoute.StopEvent := RSE_ENTERCONTENTS;
          ARoute.EndArea := LTestArea;
          ARoute.EndContents := FAreaSettings[LTestArea].Contents;
          ARoute.EndPos := LReach.EndPoint;
          Inc(ARoute.Time, FData.AreaTravelTime(AAreaNum, AOrigin, LReach.StartPoint));
          Inc(ARoute.Time, LReach.TravelTime);
          Exit(True);
        end;
      if (AStopEvent and RSE_ENTERAREA) <> 0 then
        if LTestArea = AStopAreaNum then
        begin
          ARoute.StopEvent := RSE_ENTERAREA;
          ARoute.EndArea := LTestArea;
          ARoute.EndContents := FAreaSettings[LTestArea].Contents;
          ARoute.EndPos := LReach.StartPoint;
          Exit(True);
        end;
    end;

    Inc(ARoute.Time, FData.AreaTravelTime(AAreaNum, AOrigin, LReach.StartPoint));
    Inc(ARoute.Time, LReach.TravelTime);
    ARoute.EndArea := LReach.AreaNum;
    ARoute.EndContents := FAreaSettings[LReach.AreaNum].Contents;
    ARoute.EndTravelFlags := FData.TravelFlagForType(LReach.TravelType);
    ARoute.EndPos := LReach.EndPoint;
    LCurArea := LReach.AreaNum;
    LCurOrigin := LReach.EndPoint;
    if (AMaxTime <> 0) and (ARoute.Time > AMaxTime) then
      Break;
    Inc(LIndex);
  end;
  Result := LCurArea = AGoalAreaNum;
end;

function TAasRouter.EnableRoutingArea(const AAreaNum, AEnable: Integer): Integer;
var
  LFlags: Integer;
begin
  if (AAreaNum <= 0) or (AAreaNum >= FData.AreaCount) then
  begin
    if FDeveloper then
      FImport.Print(PRT_ERROR, AnsiString(Format(SEnableRange, [AAreaNum])));
    Exit(0);
  end;
  LFlags := FAreaSettings[AAreaNum].AreaFlags and AREA_DISABLED;
  if AEnable < 0 then
    Exit(Ord(LFlags = 0));
  if AEnable <> 0 then
    FAreaSettings[AAreaNum].AreaFlags := FAreaSettings[AAreaNum].AreaFlags and not AREA_DISABLED
  else
    FAreaSettings[AAreaNum].AreaFlags := FAreaSettings[AAreaNum].AreaFlags or AREA_DISABLED;
  // if the status of the area changed
  if LFlags <> (FAreaSettings[AAreaNum].AreaFlags and AREA_DISABLED) then
    // remove all routing cache involving this area
    FStore.RemoveRoutingCacheUsingArea(AAreaNum);
  Result := Ord(LFlags = 0);
end;

function TAasRouter.AreaContentsTravelFlags(const AAreaNum: Integer): Integer;
begin
  Result := FData.AreaContentsTravelFlags(AAreaNum);
end;

function TAasRouter.TravelFlagForType(const ATravelType: Integer): Integer;
begin
  Result := FData.TravelFlagForType(ATravelType);
end;

procedure TAasRouter.ReachabilityFromNum(const ANum: Integer; var AReach: TAasReachability);
begin
  if (ANum < 0) or (ANum >= Length(FReachability)) then
    FillChar(AReach, SizeOf(AReach), 0)
  else
    AReach := FReachability[ANum];
end;

function TAasRouter.NextAreaReachability(const AAreaNum, AReachNum: Integer): Integer;
var
  LSettings: TAasAreaSettings;
  LReachNum: Integer;
begin
  if (AAreaNum <= 0) or (AAreaNum >= FData.AreaCount) then
  begin
    FImport.Print(PRT_ERROR, AnsiString(Format(SNextRange, [AAreaNum])));
    Exit(0);
  end;
  LSettings := FAreaSettings[AAreaNum];
  if AReachNum = 0 then
    Exit(LSettings.FirstReachableArea);
  if AReachNum < LSettings.FirstReachableArea then
  begin
    FImport.Print(PRT_FATAL, AnsiString(SNextFatal));
    Exit(0);
  end;
  LReachNum := AReachNum + 1;
  if LReachNum >= LSettings.FirstReachableArea + LSettings.NumReachableAreas then
    Exit(0);
  Result := LReachNum;
end;

function TAasRouter.NextModelReachability(const ANum, AModelNum: Integer): Integer;
var
  LIndex, LStart: Integer;
  LType: Integer;
begin
  if ANum <= 0 then
    LStart := 1
  else if ANum >= Length(FReachability) then
    Exit(0)
  else
    LStart := ANum + 1;
  for LIndex := LStart to High(FReachability) do
  begin
    LType := FReachability[LIndex].TravelType and TRAVELTYPE_MASK;
    if LType = TRAVEL_ELEVATOR then
    begin
      if FReachability[LIndex].FaceNum = AModelNum then
        Exit(LIndex);
    end
    else if LType = TRAVEL_FUNCBOB then
      if (FReachability[LIndex].FaceNum and $0000FFFF) = AModelNum then
        Exit(LIndex);
  end;
  Result := 0;
end;

procedure TAasRouter.Project(const APoint, AStart, AEnd: TVec3; var AProjection: TVec3);
var
  LPVec, LVec: TVec3;
  LScale, LProduct: Single;
  LIndex: Integer;
begin
  TAasVectorMath.Subtract(APoint, AStart, LPVec);
  TAasVectorMath.Subtract(AEnd, AStart, LVec);
  TAasVectorMath.Normalize(LVec);
  // project onto the directional vector for this segment: VectorMA( vStart, DotProduct( pVec, vec ), vec, vProj )
  LScale := TAasVectorMath.Dot(LPVec, LVec);
  for LIndex := 0 to 2 do
  begin
    LProduct := LVec[LIndex] * LScale;
    AProjection[LIndex] := AStart[LIndex] + LProduct;
  end;
end;

function TAasRouter.NearestHideArea(const ASrcNum: Integer; const AOrigin: TVec3; const AAreaNum, AEnemyNum: Integer;
  const AEnemyOrigin: TVec3; const AEnemyAreaNum, ATravelFlags: Integer): Integer;
type
  TUpdate = record
    AreaNum: Integer;
    TmpTravelTime: Word;
    Start: TVec3;
    Next, Prev: Integer;
    InList: Boolean;
  end;
var
  LUpdates: TArray<TUpdate>;
  LIndex, LJ, LNextAreaNum, LBadTravelFlags, LNumReach, LBestArea, LCurrent, LNext, LListStart, LListEnd: Integer;
  LTime, LBestTravelTime: Word;
  LReach: TAasReachability;
  LDist1, LDist2, LDifference, LScaled: Single;
  LV1, LV2, LP: TVec3;
  LStart: TVec3;
begin
  FillChar(FHideTravelTimes[0], Length(FHideTravelTimes) * SizeOf(Word), 0);
  SetLength(LUpdates, FData.AreaCount);
  LBestTravelTime := 0;
  LBestArea := 0;
  LBadTravelFlags := not ATravelFlags;

  LCurrent := AAreaNum;
  LUpdates[LCurrent].AreaNum := AAreaNum;
  LUpdates[LCurrent].Start := AOrigin;
  LUpdates[LCurrent].TmpTravelTime := 0;
  LUpdates[LCurrent].Next := -1;
  LUpdates[LCurrent].Prev := -1;
  LListStart := LCurrent;
  LListEnd := LCurrent;
  while LListStart >= 0 do
  begin
    LCurrent := LListStart;
    if LUpdates[LCurrent].Next >= 0 then
      LUpdates[LUpdates[LCurrent].Next].Prev := -1
    else
      LListEnd := -1;
    LListStart := LUpdates[LCurrent].Next;
    LUpdates[LCurrent].InList := False;
    LNumReach := FAreaSettings[LUpdates[LCurrent].AreaNum].NumReachableAreas;
    LStart := LUpdates[LCurrent].Start;
    for LIndex := 0 to LNumReach - 1 do
    begin
      LReach := FReachability[FAreaSettings[LUpdates[LCurrent].AreaNum].FirstReachableArea + LIndex];
      // if an undesired travel type is used
      if (FData.TravelFlagForType(LReach.TravelType) and LBadTravelFlags) <> 0 then
        Continue;
      if (FData.AreaContentsTravelFlags(LReach.AreaNum) and LBadTravelFlags) <> 0 then
        Continue;
      // number of the area the reachability leads to
      LNextAreaNum := LReach.AreaNum;
      // if this moves us into the enemies area, skip it
      if LNextAreaNum = AEnemyAreaNum then
        Continue;
      // time already travelled plus the traveltime through the current area plus the travel time from the reachability
      LTime := Word(LUpdates[LCurrent].TmpTravelTime +
        FData.AreaTravelTime(LUpdates[LCurrent].AreaNum, LStart, LReach.StartPoint));
      LTime := Word(LTime + LReach.TravelTime);

      // avoid going near the enemy
      Project(AEnemyOrigin, LStart, LReach.EndPoint, LP);
      LJ := 0;
      while LJ < 3 do
      begin
        if ((LP[LJ] > LStart[LJ]) and (LP[LJ] > LReach.EndPoint[LJ])) or
          ((LP[LJ] < LStart[LJ]) and (LP[LJ] < LReach.EndPoint[LJ])) then
          Break;
        Inc(LJ);
      end;
      if LJ < 3 then
        TAasVectorMath.Subtract(AEnemyOrigin, LReach.EndPoint, LV2)
      else
        TAasVectorMath.Subtract(AEnemyOrigin, LP, LV2);
      LDist2 := TAasVectorMath.Length(LV2);
      // never go through the enemy
      if LDist2 < 40 then
        Continue;
      TAasVectorMath.Subtract(AEnemyOrigin, LStart, LV1);
      LDist1 := TAasVectorMath.Length(LV1);
      if LDist2 < LDist1 then
      begin
        LDifference := LDist1 - LDist2;
        LScaled := LDifference * CTen;
        // the sum is a float; the conversion to unsigned short truncates it
        LDifference := LTime;
        LDifference := LDifference + LScaled;
        LTime := Word(Trunc(LDifference) and $FFFF);
      end;
      // AAS_AreaVisible is a stub that says no
      if (LBestTravelTime <> 0) and (LTime >= LBestTravelTime) then
        Continue;
      if (FHideTravelTimes[LNextAreaNum] = 0) or (FHideTravelTimes[LNextAreaNum] > LTime) then
      begin
        // if the nextarea is not visible from the enemy area (it never is visible: the stub returns false)
        LBestTravelTime := LTime;
        LBestArea := LNextAreaNum;
        FHideTravelTimes[LNextAreaNum] := LTime;
        LNext := LNextAreaNum;
        LUpdates[LNext].AreaNum := LNextAreaNum;
        LUpdates[LNext].TmpTravelTime := LTime;
        // remember where we entered this area
        LUpdates[LNext].Start := LReach.EndPoint;
        // if this update is not in the list yet
        if not LUpdates[LNext].InList then
        begin
          LUpdates[LNext].Next := -1;
          LUpdates[LNext].Prev := LListEnd;
          if LListEnd >= 0 then
            LUpdates[LListEnd].Next := LNext
          else
            LListStart := LNext;
          LListEnd := LNext;
          LUpdates[LNext].InList := True;
        end;
      end;
    end;
  end;
  Result := LBestArea;
end;

function TAasRouter.AlternativeRouteGoals(const AStart: TVec3; const AStartAreaNum: Integer; const AGoal: TVec3;
  const AGoalAreaNum, ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; const AMaxGoals,
  AType: Integer): Integer;
begin
  Result := FAlternative.Find(Self as IAasRouter, FAreaSettings, AStart, AStartAreaNum, AGoal, AGoalAreaNum,
    ATravelFlags, AGoals, AMaxGoals, AType);
end;

procedure TAasRouter.CacheStatistics(out AAreaCaches, APortalCaches, AMemory: Integer);
begin
  FStore.Statistics(AAreaCaches, APortalCaches);
  AMemory := FStore.CacheSize;
end;

procedure TAasRouter.UpdateCounts(out AAreaUpdates, APortalUpdates: Integer);
begin
  AAreaUpdates := FStore.AreaCacheUpdates;
  APortalUpdates := FStore.PortalCacheUpdates;
end;

end.
