{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - routes between areas                    }
{                                                                              }
{  Port of idAASLocal::RouteToGoalArea, TravelTimeToGoalArea and               }
{  FindNearestGoal (AAS_routing.cpp), Doom 3 GPL Source Code. Based on the     }
{  Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011 id Software   }
{  LLC, a ZeniMax Media company. This unit is derived from the Doom 3 GPL      }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Router;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.Reachability,
  DelphiDoom.Aas.D3.Types, DelphiDoom.Aas.D3.Intf, DelphiDoom.Aas.D3.Topology, DelphiDoom.Aas.D3.CacheStore,
  DelphiDoom.Aas.D3.RoutingCache;

type
  /// <summary>
  ///   The travel time and the first reachability to use between two areas, from the caches of the
  ///   clusters and of the portals; and the search of the nearest area that a callback accepts. The
  ///   topology, the store and the log are not owned
  /// </summary>
  TAasRouter = class
  strict private
    FTopology: TAasTopology;
    FStore: TAasCacheStore;
    FLog: IIdLibLog;
    FGoalAreaTravelTimes: TArray<Word>;
    FAreaUpdate: TArray<TAasRoutingUpdate>;
    function AreaReachability(const AAreaNum, AReachNumber: Integer): TAasReachability;
    function RouteInCaches(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum, ATravelFlags: Integer;
      out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
    function GoalCanBeCached(const AClusterNum, AGoalAreaNum: Integer): Boolean;
  public
    /// <summary>The log gets the messages of the original (nil is silent)</summary>
    constructor Create(const ATopology: TAasTopology; const AStore: TAasCacheStore; const ALog: IIdLibLog);
    /// <summary>
    ///   True if there is a route (and the travel time is 0 if the areas are the same); False if the
    ///   areas are not in the file, the origin area is not reachable or the goal cannot be reached.
    ///   Where the original would read past the end of its cache arrays (a goal that is not a
    ///   reachable area of its cluster) the answer is False
    /// </summary>
    function RouteToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum, ATravelFlags: Integer;
      out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
    function TravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    function FindNearestGoal(out AGoal: TAasGoal; const AAreaNum: Integer; const AOrigin, ATarget: TGeoVec3;
      const ATravelFlags: Integer; var AObstacles: array of TAasObstacle; const ANavigator: IAasNavigator;
      const ACallback: IAasAreaCallback): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.Aas.D3.TravelTime;

resourcestring
  SAreaOutOfRange = 'RouteToGoalArea: areaNum %d out of range';
  SGoalAreaOutOfRange = 'RouteToGoalArea: goalAreaNum %d out of range';

const
  // 0.1f
  CPathEpsilon: Single = 0.100000001490116119384765625;

{ TAasRouter }

constructor TAasRouter.Create(const ATopology: TAasTopology; const AStore: TAasCacheStore; const ALog: IIdLibLog);
begin
  inherited Create;
  FTopology := ATopology;
  FStore := AStore;
  FLog := ALog;
  SetLength(FGoalAreaTravelTimes, FTopology.NumAreas);
  SetLength(FAreaUpdate, FTopology.NumAreas);
end;

function TAasRouter.AreaReachability(const AAreaNum, AReachNumber: Integer): TAasReachability;
begin
  if AReachNumber < Length(FTopology.Reach[AAreaNum]) then
    Result := FTopology.Reach[AAreaNum][AReachNumber]
  else
    Result := nil;
end;

function TAasRouter.GoalCanBeCached(const AClusterNum, AGoalAreaNum: Integer): Boolean;
var
  LClusterAreaNum: Integer;
begin
  LClusterAreaNum := FStore.ClusterAreaNum(AClusterNum, AGoalAreaNum);
  Result := (LClusterAreaNum >= 0) and
    (LClusterAreaNum < FTopology.AasFile.Clusters[AClusterNum].NumReachableAreas);
end;

function TAasRouter.RouteToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
  ATravelFlags: Integer; out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
begin
  ATravelTime := 0;
  AReach := nil;

  if AAreaNum = AGoalAreaNum then
    Exit(True);

  if (AAreaNum <= 0) or (AAreaNum >= FTopology.NumAreas) then
  begin
    if Assigned(FLog) then
      FLog.Printf(Format(SAreaOutOfRange, [AAreaNum]));
    Exit(False);
  end;
  if (AGoalAreaNum <= 0) or (AGoalAreaNum >= FTopology.NumAreas) then
  begin
    if Assigned(FLog) then
      FLog.Printf(Format(SGoalAreaOutOfRange, [AGoalAreaNum]));
    Exit(False);
  end;

  FStore.TrimToMemory;
  try
    Result := RouteInCaches(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags, ATravelTime, AReach);
  except
    on EAasRoutingException do
    begin
      // a cache that was half made must not stay in the store
      FStore.Clear;
      raise;
    end;
  end;
end;

function TAasRouter.RouteInCaches(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
  ATravelFlags: Integer; out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
var
  LClusterNum, LGoalClusterNum, LPortalNum, LIndex, LClusterAreaNum: Integer;
  LTime, LBestTime: Word;
  LPortal: TAasPortal;
  LCluster: TAasCluster;
  LAreaCache, LPortalCache, LClusterCache: TAasRoutingCache;
  LBestReach, LReach, LNextReach: TAasReachability;
begin
  LClusterNum := FTopology.Areas[AAreaNum].Cluster;
  LGoalClusterNum := FTopology.Areas[AGoalAreaNum].Cluster;

  // if the source area is a cluster portal, read directly from the portal cache
  if LClusterNum < 0 then
  begin
    // if the goal area is a portal
    if LGoalClusterNum < 0 then
    begin
      // just assume the goal area is part of the front cluster
      LPortal := FTopology.AasFile.Portals[-LGoalClusterNum];
      LGoalClusterNum := LPortal.Clusters[0];
    end;
    if not GoalCanBeCached(LGoalClusterNum, AGoalAreaNum) then
      Exit(False);
    // get the portal routing cache
    LPortalCache := FStore.GetPortalRoutingCache(LGoalClusterNum, AGoalAreaNum, ATravelFlags);
    AReach := AreaReachability(AAreaNum, LPortalCache.Reachabilities[-LClusterNum]);
    if not Assigned(AReach) then
      Exit(False);
    ATravelTime := LPortalCache.TravelTimes[-LClusterNum] +
      TAasTravelTime.Calculate(FTopology.Areas[AAreaNum].TravelFlags, AOrigin, AReach.StartPoint);
    Exit(True);
  end;

  LBestTime := 0;
  LBestReach := nil;

  // check if the goal area is a portal of the source area cluster
  if LGoalClusterNum < 0 then
  begin
    LPortal := FTopology.AasFile.Portals[-LGoalClusterNum];
    if (LPortal.Clusters[0] = LClusterNum) or (LPortal.Clusters[1] = LClusterNum) then
      LGoalClusterNum := LClusterNum;
  end;

  // if both areas are in the same cluster
  LClusterCache := nil;
  if (LClusterNum > 0) and (LGoalClusterNum > 0) and (LClusterNum = LGoalClusterNum) then
  begin
    if not GoalCanBeCached(LClusterNum, AGoalAreaNum) then
      Exit(False);
    LClusterCache := FStore.GetAreaRoutingCache(LClusterNum, AGoalAreaNum, ATravelFlags);
    LClusterAreaNum := FStore.ClusterAreaNum(LClusterNum, AAreaNum);
    if (LClusterAreaNum < Length(LClusterCache.TravelTimes)) and (LClusterCache.TravelTimes[LClusterAreaNum] <> 0) then
    begin
      LBestReach := AreaReachability(AAreaNum, LClusterCache.Reachabilities[LClusterAreaNum]);
      if not Assigned(LBestReach) then
        Exit(False);
      LBestTime := Word(LClusterCache.TravelTimes[LClusterAreaNum] +
        TAasTravelTime.Calculate(FTopology.Areas[AAreaNum].TravelFlags, AOrigin, LBestReach.StartPoint));
    end
    else
      LClusterCache := nil;
  end;

  LClusterNum := FTopology.Areas[AAreaNum].Cluster;
  LGoalClusterNum := FTopology.Areas[AGoalAreaNum].Cluster;

  // if the goal area is a portal
  if LGoalClusterNum < 0 then
  begin
    // just assume the goal area is part of the front cluster
    LPortal := FTopology.AasFile.Portals[-LGoalClusterNum];
    LGoalClusterNum := LPortal.Clusters[0];
  end;
  if not GoalCanBeCached(LGoalClusterNum, AGoalAreaNum) then
    Exit(False);
  // get the portal routing cache
  LPortalCache := FStore.GetPortalRoutingCache(LGoalClusterNum, AGoalAreaNum, ATravelFlags);

  // the cluster the area is in
  LCluster := FTopology.AasFile.Clusters[LClusterNum];
  // current area inside the current cluster
  LClusterAreaNum := FStore.ClusterAreaNum(LClusterNum, AAreaNum);
  // if the area is not a reachable area
  if LClusterAreaNum >= LCluster.NumReachableAreas then
    Exit(False);

  // find the portal of the source area cluster leading towards the goal area
  for LIndex := 0 to LCluster.NumPortals - 1 do
  begin
    LPortalNum := FTopology.AasFile.PortalIndex[LCluster.FirstPortal + LIndex];

    // if the goal area isn't reachable from the portal
    if LPortalCache.TravelTimes[LPortalNum] = 0 then
      Continue;

    LPortal := FTopology.AasFile.Portals[LPortalNum];
    // get the cache of the portal area
    LAreaCache := FStore.GetAreaRoutingCache(LClusterNum, LPortal.AreaNum, ATravelFlags);
    // if the portal is not reachable from this area
    if LAreaCache.TravelTimes[LClusterAreaNum] = 0 then
      Continue;

    LReach := AreaReachability(AAreaNum, LAreaCache.Reachabilities[LClusterAreaNum]);

    if Assigned(LClusterCache) then
    begin
      // if the next reachability from the portal leads back into the cluster
      LNextReach := AreaReachability(LPortal.AreaNum, LPortalCache.Reachabilities[LPortalNum]);
      if not Assigned(LNextReach) then
        Continue;
      if (FTopology.Areas[LNextReach.ToAreaNum].Cluster < 0) or
        (FTopology.Areas[LNextReach.ToAreaNum].Cluster = LClusterNum) then
        Continue;
    end;

    // the total travel time is the travel time from the portal area to the goal area
    // plus the travel time from the source area towards the portal area
    LTime := Word(LPortalCache.TravelTimes[LPortalNum] + LAreaCache.TravelTimes[LClusterAreaNum]);
    // NOTE: Should add the exact travel time through the portal area. However we add the
    // largest travel time through the portal area, because the reachability used to travel
    // into the portal area is not known.
    LTime := Word(LTime + LPortal.MaxAreaTravelTime);

    // if the time is better than the one already found
    if (LBestTime = 0) or (LTime < LBestTime) then
    begin
      LBestReach := LReach;
      LBestTime := LTime;
    end;
  end;

  if not Assigned(LBestReach) then
    Exit(False);

  AReach := LBestReach;
  ATravelTime := LBestTime;
  Result := True;
end;

function TAasRouter.TravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
  ATravelFlags: Integer): Integer;
var
  LReach: TAasReachability;
begin
  if not RouteToGoalArea(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags, Result, LReach) then
    Result := 0;
end;

function TAasRouter.FindNearestGoal(out AGoal: TAasGoal; const AAreaNum: Integer; const AOrigin, ATarget: TGeoVec3;
  const ATravelFlags: Integer; var AObstacles: array of TAasObstacle; const ANavigator: IAasNavigator;
  const ACallback: IAasAreaCallback): Boolean;
var
  LIndex, LObstacle, LAxis, LBadTravelFlags, LNextAreaNum, LBestAreaNum: Integer;
  LTime, LBestTravelTime: Word;
  LCurrent, LNext, LListStart, LListEnd: Integer;
  LReach: TAasReachability;
  LNextArea: TAasArea;
  LV1, LV2, LP, LStart, LEnd, LDelta: TGeoVec3;
  LTargetDist, LDist, LScaled, LSum, LLow, LHigh, LProjection: Single;
  LBoxMins, LBoxMaxs: TGeoVec3;
  LReaches: TArray<TAasReachability>;
  LAreaNum: Integer;
begin
  if (not Assigned(FTopology)) or (AAreaNum <= 0) or (AAreaNum >= FTopology.NumAreas) then
  begin
    AGoal.AreaNum := AAreaNum;
    AGoal.Origin := AOrigin;
    Exit(False);
  end;

  // if the first area is valid goal, just return the origin
  if ACallback.TestArea(ANavigator, AAreaNum) then
  begin
    AGoal.AreaNum := AAreaNum;
    AGoal.Origin := AOrigin;
    Exit(True);
  end;

  // setup obstacles
  LBoxMins := FTopology.AasFile.Settings.BoundingBoxes[0].Mins;
  LBoxMaxs := FTopology.AasFile.Settings.BoundingBoxes[0].Maxs;
  for LObstacle := 0 to High(AObstacles) do
  begin
    AObstacles[LObstacle].ExpAbsBounds.Mins := AObstacles[LObstacle].AbsBounds.Mins - LBoxMaxs;
    AObstacles[LObstacle].ExpAbsBounds.Maxs := AObstacles[LObstacle].AbsBounds.Maxs - LBoxMins;
  end;

  LBadTravelFlags := not ATravelFlags;
  FillChar(FGoalAreaTravelTimes[0], Length(FGoalAreaTravelTimes) * SizeOf(Word), 0);

  LDelta := ATarget - AOrigin;
  LTargetDist := LDelta.Length;

  // initialize first update
  LCurrent := AAreaNum;
  FAreaUpdate[LCurrent].AreaNum := AAreaNum;
  FAreaUpdate[LCurrent].TmpTravelTime := 0;
  FAreaUpdate[LCurrent].Start := AOrigin;
  FAreaUpdate[LCurrent].Next := -1;
  FAreaUpdate[LCurrent].Prev := -1;
  LListStart := LCurrent;
  LListEnd := LCurrent;

  LBestTravelTime := 0;
  LBestAreaNum := 0;

  // while there are updates in the list
  while LListStart >= 0 do
  begin
    LCurrent := LListStart;
    if FAreaUpdate[LCurrent].Next >= 0 then
      FAreaUpdate[FAreaUpdate[LCurrent].Next].Prev := -1
    else
      LListEnd := -1;
    LListStart := FAreaUpdate[LCurrent].Next;

    FAreaUpdate[LCurrent].IsInList := False;

    // if we already found a closer location
    if (LBestTravelTime <> 0) and (FAreaUpdate[LCurrent].TmpTravelTime >= LBestTravelTime) then
      Continue;

    LAreaNum := FAreaUpdate[LCurrent].AreaNum;
    LStart := FAreaUpdate[LCurrent].Start;
    LReaches := FTopology.Reach[LAreaNum];
    for LIndex := 0 to Length(LReaches) - 1 do
    begin
      LReach := LReaches[LIndex];

      // if the reachability uses an undesired travel type
      if (LReach.TravelType and LBadTravelFlags) <> 0 then
        Continue;

      // next area the reachability leads to
      LNextAreaNum := LReach.ToAreaNum;
      LNextArea := FTopology.Areas[LNextAreaNum];

      // if traveling through the next area requires an undesired travel flag
      if (LNextArea.TravelFlags and LBadTravelFlags) <> 0 then
        Continue;

      LEnd := LReach.EndPoint;
      LTime := Word(FAreaUpdate[LCurrent].TmpTravelTime +
        TAasTravelTime.Calculate(FTopology.Areas[LAreaNum].TravelFlags, LStart, LReach.StartPoint));
      LTime := Word(LTime + LReach.TravelTime);

      // project target origin onto movement vector through the area
      LV1 := LEnd - LStart;
      LV1.NormalizeSelf;
      LV2 := ATarget - LStart;
      LProjection := LV2.Dot(LV1);
      LP := LV1 * LProjection;
      LP := LStart + LP;

      // get the point on the path closest to the target
      LAxis := 0;
      while LAxis < 3 do
      begin
        LSum := LStart[LAxis] + CPathEpsilon;
        LLow := LEnd[LAxis] + CPathEpsilon;
        if (LP[LAxis] > LSum) and (LP[LAxis] > LLow) then
          Break;
        LSum := LStart[LAxis] - CPathEpsilon;
        LLow := LEnd[LAxis] - CPathEpsilon;
        if (LP[LAxis] < LSum) and (LP[LAxis] < LLow) then
          Break;
        Inc(LAxis);
      end;
      if LAxis >= 3 then
      begin
        LDelta := ATarget - LP;
        LDist := LDelta.Length;
      end
      else
      begin
        LDelta := ATarget - LEnd;
        LDist := LDelta.Length;
      end;

      // avoid moving closer to the target
      if LDist < LTargetDist then
      begin
        LScaled := LTargetDist - LDist;
        LScaled := LScaled * 10;
        LHigh := LTime;
        LSum := LHigh + LScaled;
        LTime := Word(Trunc(LSum) and $FFFF);
      end;

      // if we already found a closer location
      if (LBestTravelTime <> 0) and (LTime >= LBestTravelTime) then
        Continue;

      // if this is not the best path towards the next area
      if (FGoalAreaTravelTimes[LNextAreaNum] <> 0) and (LTime >= FGoalAreaTravelTimes[LNextAreaNum]) then
        Continue;

      // path may not go through any obstacles
      LObstacle := 0;
      while LObstacle <= High(AObstacles) do
      begin
        // if the movement vector intersects the expanded obstacle bounds
        if AObstacles[LObstacle].ExpAbsBounds.LineIntersection(LStart, LEnd) then
          Break;
        Inc(LObstacle);
      end;
      if LObstacle <= High(AObstacles) then
        Continue;

      FGoalAreaTravelTimes[LNextAreaNum] := LTime;
      LNext := LNextAreaNum;
      FAreaUpdate[LNext].AreaNum := LNextAreaNum;
      FAreaUpdate[LNext].TmpTravelTime := LTime;
      FAreaUpdate[LNext].Start := LEnd;

      // if we are not allowed to fly
      if (LBadTravelFlags and TFL_FLY) <> 0 then
        // avoid areas near ledges
        if (FTopology.Areas[LNextAreaNum].Flags and AREA_LEDGE) <> 0 then
          FAreaUpdate[LNext].TmpTravelTime := Word(FAreaUpdate[LNext].TmpTravelTime + AAS_LEDGE_TRAVELTIME_PENALTY);

      if not FAreaUpdate[LNext].IsInList then
      begin
        FAreaUpdate[LNext].Next := -1;
        FAreaUpdate[LNext].Prev := LListEnd;
        if LListEnd >= 0 then
          FAreaUpdate[LListEnd].Next := LNext
        else
          LListStart := LNext;
        LListEnd := LNext;
        FAreaUpdate[LNext].IsInList := True;
      end;

      // don't put goal near a ledge
      if (LNextArea.Flags and AREA_LEDGE) = 0 then
      begin
        // add travel time through the area
        LTime := Word(LTime + TAasTravelTime.Calculate(FTopology.Areas[LReach.ToAreaNum].TravelFlags, LEnd,
          FTopology.Centers[LNextAreaNum]));

        if (LBestTravelTime = 0) or (LTime < LBestTravelTime) then
          // if the area is not visible to the target
          if ACallback.TestArea(ANavigator, LReach.ToAreaNum) then
          begin
            LBestTravelTime := LTime;
            LBestAreaNum := LReach.ToAreaNum;
          end;
      end;
    end;
  end;

  if LBestAreaNum <> 0 then
  begin
    AGoal.AreaNum := LBestAreaNum;
    AGoal.Origin := FTopology.Centers[LBestAreaNum];
    Exit(True);
  end;

  Result := False;
end;

end.
