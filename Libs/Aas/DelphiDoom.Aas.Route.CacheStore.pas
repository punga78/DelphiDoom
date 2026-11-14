{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the routing caches of areas and portals           }
{                                                                              }
{  Port of AAS_InitClusterAreaCache, AAS_InitPortalCache, AAS_LinkCache,       }
{  AAS_UnlinkCache, AAS_FreeOldestCache, AAS_RemoveRoutingCacheInCluster,      }
{  AAS_RemoveRoutingCacheUsingArea, AAS_UpdateAreaRoutingCache,                }
{  AAS_GetAreaRoutingCache, AAS_UpdatePortalRoutingCache and                   }
{  AAS_GetPortalRoutingCache of be_aas_route.c. Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.CacheStore;

interface

uses
  System.SysUtils, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Data, DelphiDoom.Aas.Route.Cache;

type
  /// <summary>
  ///   The caches of the routing: for every area of every cluster the travel times towards it from the other areas
  ///   of the cluster, and for every area of the world the travel times towards it from the portals. They are made
  ///   when a route is asked for and linked from the oldest to the newest use. The store owns them; the loops of the
  ///   flood use arrays and no call through an interface. The data is not owned
  /// </summary>
  TAasRouteCacheStore = class
  strict private
    FData: TAasRouteData;
    FClusters: TArray<TAasCluster>;
    FPortals: TArray<TAasPortal>;
    FPortalIndex: TArray<Integer>;
    FClusterAreaCache: TArray<TArray<TAasRouteCache>>;
    FPortalCache: TArray<TAasRouteCache>;
    FAreaUpdate: TArray<TAasRouteUpdate>;
    FPortalUpdate: TArray<TAasRouteUpdate>;
    FOldest: TAasRouteCache;
    FNewest: TAasRouteCache;
    FCacheSize: Integer;
    FAreaCacheUpdates: Integer;
    FPortalCacheUpdates: Integer;
    FFrameRoutingUpdates: Integer;
    procedure LinkCache(const ACache: TAasRouteCache);
    procedure UnlinkCache(const ACache: TAasRouteCache);
    procedure FreeRoutingCache(const ACache: TAasRouteCache);
    procedure UpdateAreaRoutingCache(const AAreaCache: TAasRouteCache);
    procedure UpdatePortalRoutingCache(const APortalCache: TAasRouteCache);
  public
    constructor Create(const AFile: IAasFile; const AData: TAasRouteData);
    destructor Destroy; override;
    /// <summary>AAS_ClusterAreaNum: the number of the area inside the cluster, or as a portal of it</summary>
    function ClusterAreaNum(const ACluster, AAreaNum: Integer): Integer;
    function GetAreaRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRouteCache;
    function GetPortalRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRouteCache;
    /// <summary>Drops the oldest cache that is not an area cache towards a portal; False if there is none</summary>
    function FreeOldestCache: Boolean;
    procedure RemoveRoutingCacheInCluster(const AClusterNum: Integer);
    procedure RemoveRoutingCacheUsingArea(const AAreaNum: Integer);
    procedure Clear;
    /// <summary>numareacacheupdates and numportalcacheupdates</summary>
    property AreaCacheUpdates: Integer read FAreaCacheUpdates write FAreaCacheUpdates;
    property PortalCacheUpdates: Integer read FPortalCacheUpdates write FPortalCacheUpdates;
    /// <summary>aasworld.frameroutingupdates: counted, never limited (the limit is commented out in the original)</summary>
    property FrameRoutingUpdates: Integer read FFrameRoutingUpdates write FFrameRoutingUpdates;
    /// <summary>routingcachesize</summary>
    property CacheSize: Integer read FCacheSize;
    procedure Statistics(out AAreaCaches, APortalCaches: Integer);
  end;

implementation

uses
  DelphiDoom.Aas.Route.Types;

resourcestring
  SClusterAreaOutOfRange = 'AAS routing: area %d is not an area of cluster %d';

{ TAasRouteCacheStore }

constructor TAasRouteCacheStore.Create(const AFile: IAasFile; const AData: TAasRouteData);
var
  LIndex, LMax: Integer;
begin
  inherited Create;
  FData := AData;
  FClusters := AFile.Clusters;
  FPortals := AFile.Portals;
  FPortalIndex := AFile.PortalIndex;
  SetLength(FClusterAreaCache, Length(FClusters));
  LMax := 0;
  for LIndex := 0 to High(FClusters) do
  begin
    SetLength(FClusterAreaCache[LIndex], FClusters[LIndex].NumAreas);
    if FClusters[LIndex].NumReachabilityAreas > LMax then
      LMax := FClusters[LIndex].NumReachabilityAreas;
  end;
  SetLength(FPortalCache, AData.AreaCount);
  // the original allocates maxreachabilityareas updates and indexes them by the number of the area in the cluster,
  // which can be larger when a cluster has areas without reachabilities: the update array has room for all of them
  for LIndex := 0 to High(FClusters) do
    if FClusters[LIndex].NumAreas > LMax then
      LMax := FClusters[LIndex].NumAreas;
  SetLength(FAreaUpdate, LMax);
  SetLength(FPortalUpdate, Length(FPortals) + 1);
end;

destructor TAasRouteCacheStore.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAasRouteCacheStore.Clear;
var
  LIndex: Integer;
  LCache: TAasRouteCache;
begin
  for LIndex := 0 to High(FClusters) do
    RemoveRoutingCacheInCluster(LIndex);
  for LIndex := 0 to High(FPortalCache) do
    while Assigned(FPortalCache[LIndex]) do
    begin
      LCache := FPortalCache[LIndex];
      FPortalCache[LIndex] := LCache.Next;
      FreeRoutingCache(LCache);
    end;
  FOldest := nil;
  FNewest := nil;
  FCacheSize := 0;
end;

procedure TAasRouteCacheStore.UnlinkCache(const ACache: TAasRouteCache);
begin
  if Assigned(ACache.TimeNext) then
    ACache.TimeNext.TimePrev := ACache.TimePrev
  else
    FNewest := ACache.TimePrev;
  if Assigned(ACache.TimePrev) then
    ACache.TimePrev.TimeNext := ACache.TimeNext
  else
    FOldest := ACache.TimeNext;
  ACache.TimeNext := nil;
  ACache.TimePrev := nil;
end;

procedure TAasRouteCacheStore.LinkCache(const ACache: TAasRouteCache);
begin
  if Assigned(FNewest) then
  begin
    FNewest.TimeNext := ACache;
    ACache.TimePrev := FNewest;
  end
  else
  begin
    FOldest := ACache;
    ACache.TimePrev := nil;
  end;
  ACache.TimeNext := nil;
  FNewest := ACache;
end;

procedure TAasRouteCacheStore.FreeRoutingCache(const ACache: TAasRouteCache);
begin
  UnlinkCache(ACache);
  Dec(FCacheSize, ACache.Size);
  ACache.Free;
end;

function TAasRouteCacheStore.ClusterAreaNum(const ACluster, AAreaNum: Integer): Integer;
var
  LSide, LAreaCluster: Integer;
begin
  LAreaCluster := FData.AreaSettings[AAreaNum].Cluster;
  if LAreaCluster > 0 then
    Result := FData.AreaSettings[AAreaNum].ClusterAreaNum
  else
  begin
    LSide := Ord(FPortals[-LAreaCluster].FrontCluster <> ACluster);
    Result := FPortals[-LAreaCluster].ClusterAreaNum[LSide];
  end;
end;

procedure TAasRouteCacheStore.RemoveRoutingCacheInCluster(const AClusterNum: Integer);
var
  LIndex: Integer;
  LCache, LNext: TAasRouteCache;
begin
  for LIndex := 0 to FClusters[AClusterNum].NumAreas - 1 do
  begin
    LCache := FClusterAreaCache[AClusterNum][LIndex];
    while Assigned(LCache) do
    begin
      LNext := LCache.Next;
      FreeRoutingCache(LCache);
      LCache := LNext;
    end;
    FClusterAreaCache[AClusterNum][LIndex] := nil;
  end;
end;

procedure TAasRouteCacheStore.RemoveRoutingCacheUsingArea(const AAreaNum: Integer);
var
  LIndex, LCluster: Integer;
  LCache, LNext: TAasRouteCache;
begin
  LCluster := FData.AreaSettings[AAreaNum].Cluster;
  if LCluster > 0 then
    // remove all the cache in the cluster the area is in
    RemoveRoutingCacheInCluster(LCluster)
  else
  begin
    // if this is a portal remove all cache in both the front and back cluster
    RemoveRoutingCacheInCluster(FPortals[-LCluster].FrontCluster);
    RemoveRoutingCacheInCluster(FPortals[-LCluster].BackCluster);
  end;
  // remove all portal cache
  for LIndex := 0 to FData.AreaCount - 1 do
  begin
    LCache := FPortalCache[LIndex];
    while Assigned(LCache) do
    begin
      LNext := LCache.Next;
      FreeRoutingCache(LCache);
      LCache := LNext;
    end;
    FPortalCache[LIndex] := nil;
  end;
end;

function TAasRouteCacheStore.FreeOldestCache: Boolean;
var
  LCache: TAasRouteCache;
  LClusterAreaNum: Integer;
begin
  LCache := FOldest;
  while Assigned(LCache) do
  begin
    // never free area cache leading towards a portal
    if (LCache.Kind = ROUTE_CACHETYPE_AREA) and (FData.AreaSettings[LCache.AreaNum].Cluster < 0) then
    begin
      LCache := LCache.TimeNext;
      Continue;
    end;
    Break;
  end;
  if not Assigned(LCache) then
    Exit(False);
  if LCache.Kind = ROUTE_CACHETYPE_AREA then
  begin
    // number of the area in the cluster
    LClusterAreaNum := ClusterAreaNum(LCache.Cluster, LCache.AreaNum);
    // unlink from cluster area cache
    if Assigned(LCache.Prev) then
      LCache.Prev.Next := LCache.Next
    else
      FClusterAreaCache[LCache.Cluster][LClusterAreaNum] := LCache.Next;
    if Assigned(LCache.Next) then
      LCache.Next.Prev := LCache.Prev;
  end
  else
  begin
    // unlink from portal cache
    if Assigned(LCache.Prev) then
      LCache.Prev.Next := LCache.Next
    else
      FPortalCache[LCache.AreaNum] := LCache.Next;
    if Assigned(LCache.Next) then
      LCache.Next.Prev := LCache.Prev;
  end;
  FreeRoutingCache(LCache);
  Result := True;
end;

procedure TAasRouteCacheStore.UpdateAreaRoutingCache(const AAreaCache: TAasRouteCache);
var
  LIndex, LNextAreaNum, LCluster, LBadTravelFlags, LClusterAreaNum, LNumReachabilityAreas, LLinkNum: Integer;
  LCurrent, LNext, LListStart, LListEnd, LRow: Integer;
  LTime: Word;
  LLinks: TArray<TAasReversedLink>;
  LTimes: TArray<Word>;
  LSettings: TArray<TAasAreaSettings>;
begin
  Inc(FAreaCacheUpdates);
  // number of reachability areas within this cluster
  LNumReachabilityAreas := FClusters[AAreaCache.Cluster].NumReachabilityAreas;
  Inc(FFrameRoutingUpdates);
  LBadTravelFlags := not AAreaCache.TravelFlags;
  LClusterAreaNum := ClusterAreaNum(AAreaCache.Cluster, AAreaCache.AreaNum);
  if LClusterAreaNum >= LNumReachabilityAreas then
    Exit;
  LSettings := FData.AreaSettings;
  LTimes := FData.AreaTravelTimes;

  LCurrent := LClusterAreaNum;
  FAreaUpdate[LCurrent].AreaNum := AAreaCache.AreaNum;
  FAreaUpdate[LCurrent].TravelTimesRow := -1;
  FAreaUpdate[LCurrent].TmpTravelTime := AAreaCache.StartTravelTime;
  AAreaCache.TravelTimes[LClusterAreaNum] := AAreaCache.StartTravelTime;
  // put the area to start with in the current read list
  FAreaUpdate[LCurrent].Next := -1;
  FAreaUpdate[LCurrent].Prev := -1;
  LListStart := LCurrent;
  LListEnd := LCurrent;
  // while there are updates in the current list
  while LListStart >= 0 do
  begin
    LCurrent := LListStart;
    if FAreaUpdate[LCurrent].Next >= 0 then
      FAreaUpdate[FAreaUpdate[LCurrent].Next].Prev := -1
    else
      LListEnd := -1;
    LListStart := FAreaUpdate[LCurrent].Next;
    FAreaUpdate[LCurrent].InList := False;
    // check all reversed reachability links
    LLinks := FData.Reversed[FAreaUpdate[LCurrent].AreaNum];
    LRow := FAreaUpdate[LCurrent].TravelTimesRow;
    for LIndex := 0 to Length(LLinks) - 1 do
    begin
      LLinkNum := LLinks[LIndex].LinkNum;
      // if there is used an undesired travel type
      if (FData.TravelFlagForType(FData.Reachability[LLinkNum].TravelType) and LBadTravelFlags) <> 0 then
        Continue;
      // if not allowed to enter the next area
      if (LSettings[FData.Reachability[LLinkNum].AreaNum].AreaFlags and AREA_DISABLED) <> 0 then
        Continue;
      // if the next area has a not allowed travel flag
      if (FData.AreaContentsTravelFlags(FData.Reachability[LLinkNum].AreaNum) and LBadTravelFlags) <> 0 then
        Continue;
      // number of the area the reversed reachability leads to
      LNextAreaNum := LLinks[LIndex].AreaNum;
      // get the cluster number of the area
      LCluster := LSettings[LNextAreaNum].Cluster;
      // don't leave the cluster
      if (LCluster > 0) and (LCluster <> AAreaCache.Cluster) then
        Continue;
      // get the number of the area in the cluster
      LClusterAreaNum := ClusterAreaNum(AAreaCache.Cluster, LNextAreaNum);
      if LClusterAreaNum >= LNumReachabilityAreas then
        Continue;
      // time already travelled plus the traveltime through the current area plus the travel time from the reachability
      LTime := Word(FAreaUpdate[LCurrent].TmpTravelTime + FData.Reachability[LLinkNum].TravelTime);
      if LRow >= 0 then
        LTime := Word(LTime + LTimes[LRow + LIndex]);

      if (AAreaCache.TravelTimes[LClusterAreaNum] = 0) or (AAreaCache.TravelTimes[LClusterAreaNum] > LTime) then
      begin
        AAreaCache.TravelTimes[LClusterAreaNum] := LTime;
        AAreaCache.Reachabilities[LClusterAreaNum] := Byte(LLinkNum - LSettings[LNextAreaNum].FirstReachableArea);
        LNext := LClusterAreaNum;
        FAreaUpdate[LNext].AreaNum := LNextAreaNum;
        FAreaUpdate[LNext].TmpTravelTime := LTime;
        FAreaUpdate[LNext].TravelTimesRow := FData.AreaTravelTimeStart[LNextAreaNum] +
          (LLinkNum - LSettings[LNextAreaNum].FirstReachableArea) * Length(FData.Reversed[LNextAreaNum]);
        if not FAreaUpdate[LNext].InList then
        begin
          // we add the update to the end of the list
          FAreaUpdate[LNext].Next := -1;
          FAreaUpdate[LNext].Prev := LListEnd;
          if LListEnd >= 0 then
            FAreaUpdate[LListEnd].Next := LNext
          else
            LListStart := LNext;
          LListEnd := LNext;
          FAreaUpdate[LNext].InList := True;
        end;
      end;
    end;
  end;
end;

function TAasRouteCacheStore.GetAreaRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRouteCache;
var
  LClusterAreaNum: Integer;
  LClusterCache: TAasRouteCache;
begin
  // number of the area in the cluster
  LClusterAreaNum := ClusterAreaNum(AClusterNum, AAreaNum);
  if (LClusterAreaNum < 0) or (LClusterAreaNum >= Length(FClusterAreaCache[AClusterNum])) then
    raise EAasRouteException.Create(Format(SClusterAreaOutOfRange, [AAreaNum, AClusterNum]));
  // pointer to the cache for the area in the cluster
  LClusterCache := FClusterAreaCache[AClusterNum][LClusterAreaNum];
  // find the cache without undesired travel flags
  Result := LClusterCache;
  while Assigned(Result) do
  begin
    if Result.TravelFlags = ATravelFlags then
      Break;
    Result := Result.Next;
  end;
  // if there was no cache
  if not Assigned(Result) then
  begin
    Result := TAasRouteCache.Create(FClusters[AClusterNum].NumReachabilityAreas);
    Inc(FCacheSize, Result.Size);
    Result.Cluster := AClusterNum;
    Result.AreaNum := AAreaNum;
    Result.StartTravelTime := 1;
    Result.TravelFlags := ATravelFlags;
    Result.Prev := nil;
    Result.Next := LClusterCache;
    if Assigned(LClusterCache) then
      LClusterCache.Prev := Result;
    FClusterAreaCache[AClusterNum][LClusterAreaNum] := Result;
    UpdateAreaRoutingCache(Result);
  end
  else
    UnlinkCache(Result);
  // the cache has been accessed
  Result.Kind := ROUTE_CACHETYPE_AREA;
  LinkCache(Result);
end;

procedure TAasRouteCacheStore.UpdatePortalRoutingCache(const APortalCache: TAasRouteCache);
var
  LIndex, LPortalNum, LClusterAreaNum, LClusterNum, LCurrent, LNext, LListStart, LListEnd: Integer;
  LTime: Word;
  LPortal: TAasPortal;
  LCluster: TAasCluster;
  LCache: TAasRouteCache;
begin
  Inc(FPortalCacheUpdates);
  LCurrent := Length(FPortals);
  FPortalUpdate[LCurrent].Cluster := APortalCache.Cluster;
  FPortalUpdate[LCurrent].AreaNum := APortalCache.AreaNum;
  FPortalUpdate[LCurrent].TmpTravelTime := APortalCache.StartTravelTime;
  // if the start area is a cluster portal, store the travel time for that portal
  LClusterNum := FData.AreaSettings[APortalCache.AreaNum].Cluster;
  if LClusterNum < 0 then
    APortalCache.TravelTimes[-LClusterNum] := APortalCache.StartTravelTime;
  // put the area to start with in the current read list
  FPortalUpdate[LCurrent].Next := -1;
  FPortalUpdate[LCurrent].Prev := -1;
  LListStart := LCurrent;
  LListEnd := LCurrent;
  // while there are updates in the current list
  while LListStart >= 0 do
  begin
    LCurrent := LListStart;
    // remove the current update from the list
    if FPortalUpdate[LCurrent].Next >= 0 then
      FPortalUpdate[FPortalUpdate[LCurrent].Next].Prev := -1
    else
      LListEnd := -1;
    LListStart := FPortalUpdate[LCurrent].Next;
    // current update is removed from the list
    FPortalUpdate[LCurrent].InList := False;
    LCluster := FClusters[FPortalUpdate[LCurrent].Cluster];
    LCache := GetAreaRoutingCache(FPortalUpdate[LCurrent].Cluster, FPortalUpdate[LCurrent].AreaNum,
      APortalCache.TravelFlags);
    // take all portals of the cluster
    for LIndex := 0 to LCluster.NumPortals - 1 do
    begin
      LPortalNum := FPortalIndex[LCluster.FirstPortal + LIndex];
      LPortal := FPortals[LPortalNum];
      // if this is the portal of the current update continue
      if LPortal.AreaNum = FPortalUpdate[LCurrent].AreaNum then
        Continue;
      LClusterAreaNum := ClusterAreaNum(FPortalUpdate[LCurrent].Cluster, LPortal.AreaNum);
      if LClusterAreaNum >= LCluster.NumReachabilityAreas then
        Continue;
      LTime := LCache.TravelTimes[LClusterAreaNum];
      if LTime = 0 then
        Continue;
      LTime := Word(LTime + FPortalUpdate[LCurrent].TmpTravelTime);
      if (APortalCache.TravelTimes[LPortalNum] = 0) or (APortalCache.TravelTimes[LPortalNum] > LTime) then
      begin
        APortalCache.TravelTimes[LPortalNum] := LTime;
        LNext := LPortalNum;
        if LPortal.FrontCluster = FPortalUpdate[LCurrent].Cluster then
          FPortalUpdate[LNext].Cluster := LPortal.BackCluster
        else
          FPortalUpdate[LNext].Cluster := LPortal.FrontCluster;
        FPortalUpdate[LNext].AreaNum := LPortal.AreaNum;
        // add travel time through the actual portal area for the next update
        FPortalUpdate[LNext].TmpTravelTime := Word(LTime + FData.PortalMaxTravelTimes[LPortalNum]);
        if not FPortalUpdate[LNext].InList then
        begin
          FPortalUpdate[LNext].Next := -1;
          FPortalUpdate[LNext].Prev := LListEnd;
          if LListEnd >= 0 then
            FPortalUpdate[LListEnd].Next := LNext
          else
            LListStart := LNext;
          LListEnd := LNext;
          FPortalUpdate[LNext].InList := True;
        end;
      end;
    end;
  end;
end;

function TAasRouteCacheStore.GetPortalRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRouteCache;
begin
  // find the cached portal routing if existing
  Result := FPortalCache[AAreaNum];
  while Assigned(Result) do
  begin
    if Result.TravelFlags = ATravelFlags then
      Break;
    Result := Result.Next;
  end;
  // if the portal routing isn't cached
  if not Assigned(Result) then
  begin
    Result := TAasRouteCache.Create(Length(FPortals));
    Inc(FCacheSize, Result.Size);
    Result.Cluster := AClusterNum;
    Result.AreaNum := AAreaNum;
    Result.StartTravelTime := 1;
    Result.TravelFlags := ATravelFlags;
    // add the cache to the cache list
    Result.Prev := nil;
    Result.Next := FPortalCache[AAreaNum];
    if Assigned(FPortalCache[AAreaNum]) then
      FPortalCache[AAreaNum].Prev := Result;
    FPortalCache[AAreaNum] := Result;
    // update the cache
    UpdatePortalRoutingCache(Result);
  end
  else
    UnlinkCache(Result);
  // the cache has been accessed
  Result.Kind := ROUTE_CACHETYPE_PORTAL;
  LinkCache(Result);
end;

procedure TAasRouteCacheStore.Statistics(out AAreaCaches, APortalCaches: Integer);
var
  LCache: TAasRouteCache;
begin
  AAreaCaches := 0;
  APortalCaches := 0;
  LCache := FOldest;
  while Assigned(LCache) do
  begin
    if LCache.Kind = ROUTE_CACHETYPE_AREA then
      Inc(AAreaCaches)
    else
      Inc(APortalCaches);
    LCache := LCache.TimeNext;
  end;
end;

end.
