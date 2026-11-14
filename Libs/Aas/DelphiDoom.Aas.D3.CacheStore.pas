{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - the routing caches of areas and portals }
{                                                                              }
{  Port of the cache part of idAASLocal (AAS_routing.cpp): SetupRoutingCache,  }
{  GetAreaRoutingCache, UpdateAreaRoutingCache, GetPortalRoutingCache,         }
{  UpdatePortalRoutingCache, LinkCache, UnlinkCache, DeleteOldestCache,        }
{  DeleteClusterCache, DeletePortalCache, RemoveRoutingCacheUsingArea.         }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.CacheStore;

interface

uses
  DelphiDoom.Aas.D3.Topology, DelphiDoom.Aas.D3.RoutingCache;

type
  /// <summary>
  ///   The caches of the routing: for each reachable area of every cluster the travel times towards
  ///   it from the other areas of the cluster (area caches), and for each area of the world the
  ///   travel times towards it from the portals (portal caches). They are made when a route is asked
  ///   for and kept in a list sorted by use, so that the oldest are dropped when they take more than
  ///   <c>MaxMemory</c>. The store owns them. The loops of the flood use arrays and no call through
  ///   an interface. The topology is not owned
  /// </summary>
  TAasCacheStore = class
  strict private
    FTopology: TAasTopology;
    FMaxMemory: Integer;
    FAreaCacheIndex: TArray<TArray<TAasRoutingCache>>;
    FPortalCacheIndex: TArray<TAasRoutingCache>;
    FAreaUpdate: TArray<TAasRoutingUpdate>;
    FPortalUpdate: TArray<TAasRoutingUpdate>;
    FCacheListStart: TAasRoutingCache;
    FCacheListEnd: TAasRoutingCache;
    FTotalCacheMemory: Integer;
    procedure LinkCache(const ACache: TAasRoutingCache);
    procedure UnlinkCache(const ACache: TAasRoutingCache);
    procedure UpdateAreaRoutingCache(const AAreaCache: TAasRoutingCache);
    procedure UpdatePortalRoutingCache(const APortalCache: TAasRoutingCache);
  public
    constructor Create(const ATopology: TAasTopology; const AMaxMemory: Integer);
    destructor Destroy; override;
    /// <summary>
    ///   The number of the area inside the cluster (ClusterAreaNum): its own number if it is in the
    ///   cluster, the one it has as a portal of the cluster otherwise
    /// </summary>
    function ClusterAreaNum(const AClusterNum, AAreaNum: Integer): Integer;
    /// <summary>The cache towards the area inside the cluster; made and filled if it does not exist</summary>
    function GetAreaRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRoutingCache;
    /// <summary>The cache towards the area from every portal; made and filled if it does not exist</summary>
    function GetPortalRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRoutingCache;
    procedure DeleteClusterCache(const AClusterNum: Integer);
    procedure DeletePortalCache;
    /// <summary>Drops the oldest cache; there must be one</summary>
    procedure DeleteOldestCache;
    /// <summary>
    ///   Drops what depends on the area: the caches of its cluster, of both clusters of a portal, and
    ///   all the portal caches
    /// </summary>
    procedure RemoveRoutingCacheUsingArea(const AAreaNum: Integer);
    /// <summary>Drops the oldest caches while they take more than the memory allowed</summary>
    procedure TrimToMemory;
    procedure Clear;
    /// <summary>The memory counted for the caches (totalCacheMemory)</summary>
    property TotalCacheMemory: Integer read FTotalCacheMemory;
    property MaxMemory: Integer read FMaxMemory;
    /// <summary>How many caches there are of each kind and the memory of each (RoutingStats)</summary>
    procedure Statistics(out ANumAreaCache, ANumPortalCache, AAreaMemory, APortalMemory: Integer);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.Aas.D3.Types;

resourcestring
  SClusterAreaOutOfRange = 'AAS routing: area %d is not a reachable area of cluster %d';

{ TAasCacheStore }

constructor TAasCacheStore.Create(const ATopology: TAasTopology; const AMaxMemory: Integer);
var
  LIndex, LSize: Integer;
begin
  inherited Create;
  FTopology := ATopology;
  FMaxMemory := AMaxMemory;
  SetLength(FAreaCacheIndex, FTopology.AasFile.NumClusters);
  LSize := FTopology.NumAreas;
  for LIndex := 0 to FTopology.AasFile.NumClusters - 1 do
  begin
    SetLength(FAreaCacheIndex[LIndex], FTopology.AasFile.Clusters[LIndex].NumReachableAreas);
    if FTopology.AasFile.Clusters[LIndex].NumReachableAreas > LSize then
      LSize := FTopology.AasFile.Clusters[LIndex].NumReachableAreas;
  end;
  SetLength(FPortalCacheIndex, FTopology.NumAreas);
  SetLength(FAreaUpdate, LSize);
  SetLength(FPortalUpdate, FTopology.AasFile.NumPortals + 1);
end;

destructor TAasCacheStore.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAasCacheStore.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Length(FAreaCacheIndex) - 1 do
    DeleteClusterCache(LIndex);
  DeletePortalCache;
  FCacheListStart := nil;
  FCacheListEnd := nil;
  FTotalCacheMemory := 0;
end;

procedure TAasCacheStore.LinkCache(const ACache: TAasRoutingCache);
begin
  // if the cache is already linked
  if Assigned(ACache.TimeNext) or Assigned(ACache.TimePrev) or (FCacheListStart = ACache) then
    UnlinkCache(ACache);

  Inc(FTotalCacheMemory, ACache.Footprint);

  // add cache to the end of the list
  ACache.TimeNext := nil;
  ACache.TimePrev := FCacheListEnd;
  if Assigned(FCacheListEnd) then
    FCacheListEnd.TimeNext := ACache;
  FCacheListEnd := ACache;
  if not Assigned(FCacheListStart) then
    FCacheListStart := ACache;
end;

procedure TAasCacheStore.UnlinkCache(const ACache: TAasRoutingCache);
begin
  Dec(FTotalCacheMemory, ACache.Footprint);

  if Assigned(ACache.TimeNext) then
    ACache.TimeNext.TimePrev := ACache.TimePrev
  else
    FCacheListEnd := ACache.TimePrev;
  if Assigned(ACache.TimePrev) then
    ACache.TimePrev.TimeNext := ACache.TimeNext
  else
    FCacheListStart := ACache.TimeNext;
  ACache.TimeNext := nil;
  ACache.TimePrev := nil;
end;

function TAasCacheStore.ClusterAreaNum(const AClusterNum, AAreaNum: Integer): Integer;
var
  LSide, LAreaCluster: Integer;
begin
  LAreaCluster := FTopology.Areas[AAreaNum].Cluster;
  if LAreaCluster > 0 then
    Result := FTopology.Areas[AAreaNum].ClusterAreaNum
  else
  begin
    LSide := Ord(FTopology.AasFile.Portals[-LAreaCluster].Clusters[0] <> AClusterNum);
    Result := FTopology.AasFile.Portals[-LAreaCluster].ClusterAreaNum[LSide];
  end;
end;

procedure TAasCacheStore.DeleteClusterCache(const AClusterNum: Integer);
var
  LIndex: Integer;
  LCache: TAasRoutingCache;
begin
  for LIndex := 0 to Length(FAreaCacheIndex[AClusterNum]) - 1 do
  begin
    LCache := FAreaCacheIndex[AClusterNum][LIndex];
    while Assigned(LCache) do
    begin
      FAreaCacheIndex[AClusterNum][LIndex] := LCache.Next;
      UnlinkCache(LCache);
      LCache.Free;
      LCache := FAreaCacheIndex[AClusterNum][LIndex];
    end;
  end;
end;

procedure TAasCacheStore.DeletePortalCache;
var
  LIndex: Integer;
  LCache: TAasRoutingCache;
begin
  for LIndex := 0 to Length(FPortalCacheIndex) - 1 do
  begin
    LCache := FPortalCacheIndex[LIndex];
    while Assigned(LCache) do
    begin
      FPortalCacheIndex[LIndex] := LCache.Next;
      UnlinkCache(LCache);
      LCache.Free;
      LCache := FPortalCacheIndex[LIndex];
    end;
  end;
end;

procedure TAasCacheStore.DeleteOldestCache;
var
  LCache: TAasRoutingCache;
begin
  LCache := FCacheListStart;
  // unlink the oldest cache
  UnlinkCache(LCache);

  // unlink the oldest cache from the area or portal cache index
  if Assigned(LCache.Next) then
    LCache.Next.Prev := LCache.Prev;
  if Assigned(LCache.Prev) then
    LCache.Prev.Next := LCache.Next
  else if LCache.Kind = AAS_CACHETYPE_AREA then
    FAreaCacheIndex[LCache.Cluster][ClusterAreaNum(LCache.Cluster, LCache.AreaNum)] := LCache.Next
  else if LCache.Kind = AAS_CACHETYPE_PORTAL then
    FPortalCacheIndex[LCache.AreaNum] := LCache.Next;

  LCache.Free;
end;

procedure TAasCacheStore.TrimToMemory;
begin
  while (FTotalCacheMemory > FMaxMemory) and Assigned(FCacheListStart) do
    DeleteOldestCache;
end;

procedure TAasCacheStore.RemoveRoutingCacheUsingArea(const AAreaNum: Integer);
var
  LClusterNum: Integer;
begin
  LClusterNum := FTopology.Areas[AAreaNum].Cluster;
  if LClusterNum > 0 then
    // remove all the cache in the cluster the area is in
    DeleteClusterCache(LClusterNum)
  else
  begin
    // if this is a portal remove all cache in both the front and back cluster
    DeleteClusterCache(FTopology.AasFile.Portals[-LClusterNum].Clusters[0]);
    DeleteClusterCache(FTopology.AasFile.Portals[-LClusterNum].Clusters[1]);
  end;
  DeletePortalCache;
end;

procedure TAasCacheStore.UpdateAreaRoutingCache(const AAreaCache: TAasRoutingCache);
var
  LIndex, LNextAreaNum, LCluster, LBadTravelFlags, LClusterAreaNum, LNumReachableAreas: Integer;
  LCurrent, LNext, LListStart, LListEnd, LRow: Integer;
  LTime: Word;
  LRevReach: TArray<TAasReachability>;
  LReach: TAasReachability;
  LNextArea: TAasArea;
  LTravelTimes: TArray<Word>;
begin
  LTravelTimes := FTopology.TravelTimes;
  // number of reachability areas within this cluster
  LNumReachableAreas := FTopology.AasFile.Clusters[AAreaCache.Cluster].NumReachableAreas;

  // number of the start area within the cluster
  LClusterAreaNum := ClusterAreaNum(AAreaCache.Cluster, AAreaCache.AreaNum);
  if LClusterAreaNum >= LNumReachableAreas then
    Exit;

  AAreaCache.TravelTimes[LClusterAreaNum] := AAreaCache.StartTravelTime;
  LBadTravelFlags := not AAreaCache.TravelFlags;

  // initialize first update (its travel times are a row of zeros)
  LCurrent := LClusterAreaNum;
  FAreaUpdate[LCurrent].AreaNum := AAreaCache.AreaNum;
  FAreaUpdate[LCurrent].TravelTimesRow := -1;
  FAreaUpdate[LCurrent].TmpTravelTime := AAreaCache.StartTravelTime;
  FAreaUpdate[LCurrent].Next := -1;
  FAreaUpdate[LCurrent].Prev := -1;
  LListStart := LCurrent;
  LListEnd := LCurrent;

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

    LRevReach := FTopology.RevReach[FAreaUpdate[LCurrent].AreaNum];
    LRow := FAreaUpdate[LCurrent].TravelTimesRow;
    for LIndex := 0 to Length(LRevReach) - 1 do
    begin
      LReach := LRevReach[LIndex];

      // if the reachability uses an undesired travel type
      if (LReach.TravelType and LBadTravelFlags) <> 0 then
        Continue;

      // next area the reversed reachability leads to
      LNextAreaNum := LReach.FromAreaNum;
      LNextArea := FTopology.Areas[LNextAreaNum];

      // if traveling through the next area requires an undesired travel flag
      if (LNextArea.TravelFlags and LBadTravelFlags) <> 0 then
        Continue;

      // get the cluster number of the area
      LCluster := LNextArea.Cluster;
      // don't leave the cluster, however do flood into cluster portals
      if (LCluster > 0) and (LCluster <> AAreaCache.Cluster) then
        Continue;

      // get the number of the area in the cluster
      LClusterAreaNum := ClusterAreaNum(AAreaCache.Cluster, LNextAreaNum);
      if LClusterAreaNum >= LNumReachableAreas then
        Continue; // should never happen

      // time already travelled plus the traveltime through the current area
      // plus the travel time of the reachability towards the next area
      LTime := Word(FAreaUpdate[LCurrent].TmpTravelTime + LReach.TravelTime);
      if LRow >= 0 then
        LTime := Word(LTime + LTravelTimes[LRow + LIndex]);

      if (AAreaCache.TravelTimes[LClusterAreaNum] = 0) or (LTime < AAreaCache.TravelTimes[LClusterAreaNum]) then
      begin
        AAreaCache.TravelTimes[LClusterAreaNum] := LTime;
        // reversed reachability used to get into this area
        AAreaCache.Reachabilities[LClusterAreaNum] := LReach.Number;
        LNext := LClusterAreaNum;
        FAreaUpdate[LNext].AreaNum := LNextAreaNum;
        FAreaUpdate[LNext].TmpTravelTime := LTime;
        FAreaUpdate[LNext].TravelTimesRow := FTopology.ReachRow[LNextAreaNum][LReach.Number];

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
      end;
    end;
  end;
end;

function TAasCacheStore.GetAreaRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRoutingCache;
var
  LClusterAreaNum: Integer;
  LClusterCache: TAasRoutingCache;
begin
  // number of the area in the cluster
  LClusterAreaNum := ClusterAreaNum(AClusterNum, AAreaNum);
  if (LClusterAreaNum < 0) or (LClusterAreaNum >= Length(FAreaCacheIndex[AClusterNum])) then
    raise EAasRoutingException.Create(Format(SClusterAreaOutOfRange, [AAreaNum, AClusterNum]));
  // pointer to the cache for the area in the cluster
  LClusterCache := FAreaCacheIndex[AClusterNum][LClusterAreaNum];
  // check if cache without undesired travel flags already exists
  Result := LClusterCache;
  while Assigned(Result) do
  begin
    if Result.TravelFlags = ATravelFlags then
      Break;
    Result := Result.Next;
  end;
  // if no cache found
  if not Assigned(Result) then
  begin
    Result := TAasRoutingCache.Create(FTopology.AasFile.Clusters[AClusterNum].NumReachableAreas);
    Result.Kind := AAS_CACHETYPE_AREA;
    Result.Cluster := AClusterNum;
    Result.AreaNum := AAreaNum;
    Result.StartTravelTime := 1;
    Result.TravelFlags := ATravelFlags;
    Result.Prev := nil;
    Result.Next := LClusterCache;
    if Assigned(LClusterCache) then
      LClusterCache.Prev := Result;
    FAreaCacheIndex[AClusterNum][LClusterAreaNum] := Result;
    UpdateAreaRoutingCache(Result);
  end;
  LinkCache(Result);
end;

procedure TAasCacheStore.UpdatePortalRoutingCache(const APortalCache: TAasRoutingCache);
var
  LIndex, LPortalNum, LClusterAreaNum, LCurrent, LNext, LListStart, LListEnd: Integer;
  LTime: Word;
  LPortal: TAasPortal;
  LCluster: TAasCluster;
  LCache: TAasRoutingCache;
begin
  LCurrent := FTopology.AasFile.NumPortals;
  FPortalUpdate[LCurrent].Cluster := APortalCache.Cluster;
  FPortalUpdate[LCurrent].AreaNum := APortalCache.AreaNum;
  FPortalUpdate[LCurrent].TmpTravelTime := APortalCache.StartTravelTime;

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
    FPortalUpdate[LCurrent].IsInList := False;

    LCluster := FTopology.AasFile.Clusters[FPortalUpdate[LCurrent].Cluster];
    LCache := GetAreaRoutingCache(FPortalUpdate[LCurrent].Cluster, FPortalUpdate[LCurrent].AreaNum,
      APortalCache.TravelFlags);

    // take all portals of the cluster
    for LIndex := 0 to LCluster.NumPortals - 1 do
    begin
      LPortalNum := FTopology.AasFile.PortalIndex[LCluster.FirstPortal + LIndex];
      LPortal := FTopology.AasFile.Portals[LPortalNum];

      LClusterAreaNum := ClusterAreaNum(FPortalUpdate[LCurrent].Cluster, LPortal.AreaNum);
      if LClusterAreaNum >= LCluster.NumReachableAreas then
        Continue;

      LTime := LCache.TravelTimes[LClusterAreaNum];
      if LTime = 0 then
        Continue;
      LTime := Word(LTime + FPortalUpdate[LCurrent].TmpTravelTime);

      if (APortalCache.TravelTimes[LPortalNum] = 0) or (LTime < APortalCache.TravelTimes[LPortalNum]) then
      begin
        APortalCache.TravelTimes[LPortalNum] := LTime;
        APortalCache.Reachabilities[LPortalNum] := LCache.Reachabilities[LClusterAreaNum];
        LNext := LPortalNum;
        if LPortal.Clusters[0] = FPortalUpdate[LCurrent].Cluster then
          FPortalUpdate[LNext].Cluster := LPortal.Clusters[1]
        else
          FPortalUpdate[LNext].Cluster := LPortal.Clusters[0];
        FPortalUpdate[LNext].AreaNum := LPortal.AreaNum;
        // add travel time through the actual portal area for the next update
        FPortalUpdate[LNext].TmpTravelTime := Word(LTime + LPortal.MaxAreaTravelTime);

        if not FPortalUpdate[LNext].IsInList then
        begin
          FPortalUpdate[LNext].Next := -1;
          FPortalUpdate[LNext].Prev := LListEnd;
          if LListEnd >= 0 then
            FPortalUpdate[LListEnd].Next := LNext
          else
            LListStart := LNext;
          LListEnd := LNext;
          FPortalUpdate[LNext].IsInList := True;
        end;
      end;
    end;
  end;
end;

function TAasCacheStore.GetPortalRoutingCache(const AClusterNum, AAreaNum, ATravelFlags: Integer): TAasRoutingCache;
begin
  // check if cache without undesired travel flags already exists
  Result := FPortalCacheIndex[AAreaNum];
  while Assigned(Result) do
  begin
    if Result.TravelFlags = ATravelFlags then
      Break;
    Result := Result.Next;
  end;
  // if no cache found
  if not Assigned(Result) then
  begin
    Result := TAasRoutingCache.Create(FTopology.AasFile.NumPortals);
    Result.Kind := AAS_CACHETYPE_PORTAL;
    Result.Cluster := AClusterNum;
    Result.AreaNum := AAreaNum;
    Result.StartTravelTime := 1;
    Result.TravelFlags := ATravelFlags;
    Result.Prev := nil;
    Result.Next := FPortalCacheIndex[AAreaNum];
    if Assigned(FPortalCacheIndex[AAreaNum]) then
      FPortalCacheIndex[AAreaNum].Prev := Result;
    FPortalCacheIndex[AAreaNum] := Result;
    UpdatePortalRoutingCache(Result);
  end;
  LinkCache(Result);
end;

procedure TAasCacheStore.Statistics(out ANumAreaCache, ANumPortalCache, AAreaMemory, APortalMemory: Integer);
var
  LCache: TAasRoutingCache;
begin
  ANumAreaCache := 0;
  ANumPortalCache := 0;
  AAreaMemory := 0;
  APortalMemory := 0;
  LCache := FCacheListStart;
  while Assigned(LCache) do
  begin
    if LCache.Kind = AAS_CACHETYPE_AREA then
    begin
      Inc(ANumAreaCache);
      Inc(AAreaMemory, LCache.Footprint);
    end
    else
    begin
      Inc(ANumPortalCache);
      Inc(APortalMemory, LCache.Footprint);
    end;
    LCache := LCache.TimeNext;
  end;
end;

end.
