{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - clusters and portals (be_aas_cluster.c)           }
{                                                                              }
{  Port of AAS_RemoveClusterAreas, AAS_UpdatePortal, AAS_FloodClusterAreas_r,  }
{  AAS_FloodClusterAreasUsingReachabilities, AAS_NumberClusterAreas,           }
{  AAS_FindClusters, AAS_CreatePortals and AAS_TestPortals. Based on the       }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Cluster.Builder;

interface

uses
  System.SysUtils, DelphiDoom.Aas.Cluster.World;

type
  /// <summary>
  ///   Makes the portals from the areas that are cluster portals, floods the areas into clusters through their
  ///   reachabilities and numbers the areas inside each cluster. The world is not owned
  /// </summary>
  TAasClusterBuilder = class
  strict private
    FWorld: TAasClusterWorld;
    FNoFaceFlood: Boolean;
    function UpdatePortal(const AAreaNum, AClusterNum: Integer): Boolean;
    function FloodClusterAreas(const AAreaNum, AClusterNum: Integer): Boolean;
    function FloodClusterAreasUsingReachabilities(const AClusterNum: Integer): Boolean;
    procedure NumberClusterAreas(const AClusterNum: Integer);
  public
    constructor Create(const AWorld: TAasClusterWorld);
    /// <summary>aasworld.areasettings[i].cluster = 0 for every area</summary>
    procedure RemoveClusterAreas;
    /// <summary>One portal for every area that is a cluster portal (AAS_CreatePortals)</summary>
    procedure CreatePortals;
    /// <summary>The clusters; False if the flood meets a cluster from another one or a portal that cannot be (AAS_FindClusters)</summary>
    function FindClusters: Boolean;
    /// <summary>
    ///   True if every portal has a front and a back cluster; the first that has not loses its portal flag
    ///   (AAS_TestPortals)
    /// </summary>
    function TestPortals: Boolean;
    /// <summary>
    ///   nofaceflood of the original (True): the flood goes only through reachabilities and the areas without
    ///   reachabilities do not start a cluster
    /// </summary>
    property NoFaceFlood: Boolean read FNoFaceFlood write FNoFaceFlood;
  end;

implementation

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Cluster.Types;

{ TAasClusterBuilder }

constructor TAasClusterBuilder.Create(const AWorld: TAasClusterWorld);
begin
  inherited Create;
  FWorld := AWorld;
  FNoFaceFlood := True;
end;

procedure TAasClusterBuilder.RemoveClusterAreas;
var
  LIndex: Integer;
begin
  for LIndex := 1 to FWorld.NumAreas - 1 do
    FWorld.AreaSettings[LIndex].Cluster := 0;
end;

function TAasClusterBuilder.UpdatePortal(const AAreaNum, AClusterNum: Integer): Boolean;
var
  LPortalNum: Integer;
begin
  // find the portal of the area
  LPortalNum := 1;
  while LPortalNum < FWorld.NumPortals do
  begin
    if FWorld.Portals[LPortalNum].AreaNum = AAreaNum then
      Break;
    Inc(LPortalNum);
  end;
  if LPortalNum = FWorld.NumPortals then
  begin
    FWorld.Error(Format('no portal of area %d', [AAreaNum]));
    Exit(True);
  end;
  // if the portal is already fully updated
  if FWorld.Portals[LPortalNum].FrontCluster = AClusterNum then
    Exit(True);
  if FWorld.Portals[LPortalNum].BackCluster = AClusterNum then
    Exit(True);
  // if the portal has no front cluster yet
  if FWorld.Portals[LPortalNum].FrontCluster = 0 then
    FWorld.Portals[LPortalNum].FrontCluster := AClusterNum
  // if the portal has no back cluster yet
  else if FWorld.Portals[LPortalNum].BackCluster = 0 then
    FWorld.Portals[LPortalNum].BackCluster := AClusterNum
  else
  begin
    // remove the cluster portal flag contents
    FWorld.AreaSettings[AAreaNum].Contents := FWorld.AreaSettings[AAreaNum].Contents and not AREACONTENTS_CLUSTERPORTAL;
    FWorld.LogWrite(Format('portal area %d is seperating more than two clusters'#13#10, [AAreaNum]));
    Exit(False);
  end;
  if FWorld.PortalIndexSize >= AAS_MAX_PORTALINDEXSIZE then
  begin
    FWorld.Error('AAS_MAX_PORTALINDEXSIZE');
    Exit(True);
  end;
  // set the area cluster number to the negative portal number
  FWorld.AreaSettings[AAreaNum].Cluster := -LPortalNum;
  // add the portal to the cluster using the portal index
  FWorld.PortalIndex[FWorld.Clusters[AClusterNum].FirstPortal + FWorld.Clusters[AClusterNum].NumPortals] := LPortalNum;
  FWorld.PortalIndexSize := FWorld.PortalIndexSize + 1;
  Inc(FWorld.Clusters[AClusterNum].NumPortals);
  Result := True;
end;

function TAasClusterBuilder.FloodClusterAreas(const AAreaNum, AClusterNum: Integer): Boolean;
var
  LIndex, LFaceNum, LReachArea: Integer;
begin
  if (AAreaNum <= 0) or (AAreaNum >= FWorld.NumAreas) then
  begin
    FWorld.Error('AAS_FloodClusterAreas_r: areanum out of range');
    Exit(False);
  end;
  // if the area is already part of a cluster
  if FWorld.AreaSettings[AAreaNum].Cluster > 0 then
  begin
    if FWorld.AreaSettings[AAreaNum].Cluster = AClusterNum then
      Exit(True);
    // there's a reachability going from one cluster to another only in one direction
    FWorld.Error(Format('cluster %d touched cluster %d at area %d'#13#10,
      [AClusterNum, FWorld.AreaSettings[AAreaNum].Cluster, AAreaNum]));
    Exit(False);
  end;
  // don't add the cluster portal areas to the clusters
  if (FWorld.AreaSettings[AAreaNum].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
    Exit(UpdatePortal(AAreaNum, AClusterNum));
  // set the area cluster number
  FWorld.AreaSettings[AAreaNum].Cluster := AClusterNum;
  FWorld.AreaSettings[AAreaNum].ClusterAreaNum := FWorld.Clusters[AClusterNum].NumAreas;
  // the cluster has an extra area
  Inc(FWorld.Clusters[AClusterNum].NumAreas);
  // use area faces to flood into adjacent areas
  if not FNoFaceFlood then
    for LIndex := 0 to FWorld.Areas[AAreaNum].NumFaces - 1 do
    begin
      LFaceNum := Abs(FWorld.FaceIndex[FWorld.Areas[AAreaNum].FirstFace + LIndex]);
      if FWorld.Faces[LFaceNum].FrontArea = AAreaNum then
      begin
        if FWorld.Faces[LFaceNum].BackArea <> 0 then
          if not FloodClusterAreas(FWorld.Faces[LFaceNum].BackArea, AClusterNum) then
            Exit(False);
      end
      else if FWorld.Faces[LFaceNum].FrontArea <> 0 then
        if not FloodClusterAreas(FWorld.Faces[LFaceNum].FrontArea, AClusterNum) then
          Exit(False);
    end;
  // use the reachabilities to flood into other areas
  for LIndex := 0 to FWorld.AreaSettings[AAreaNum].NumReachableAreas - 1 do
  begin
    LReachArea := FWorld.Reachability[FWorld.AreaSettings[AAreaNum].FirstReachableArea + LIndex].AreaNum;
    if LReachArea = 0 then
      Continue;
    if not FloodClusterAreas(LReachArea, AClusterNum) then
      Exit(False);
  end;
  Result := True;
end;

function TAasClusterBuilder.FloodClusterAreasUsingReachabilities(const AClusterNum: Integer): Boolean;
var
  LIndex, LJ, LAreaNum: Integer;
begin
  LIndex := 1;
  while LIndex < FWorld.NumAreas do
  begin
    // if this area already has a cluster set, or is a cluster portal
    if (FWorld.AreaSettings[LIndex].Cluster = 0) and
      ((FWorld.AreaSettings[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) = 0) then
      // loop over the reachable areas from this area
      for LJ := 0 to FWorld.AreaSettings[LIndex].NumReachableAreas - 1 do
      begin
        LAreaNum := FWorld.Reachability[FWorld.AreaSettings[LIndex].FirstReachableArea + LJ].AreaNum;
        // if this area is a cluster portal
        if (FWorld.AreaSettings[LAreaNum].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
          Continue;
        // if this area has a cluster set
        if FWorld.AreaSettings[LAreaNum].Cluster <> 0 then
        begin
          if not FloodClusterAreas(LIndex, AClusterNum) then
            Exit(False);
          LIndex := 0;
          Break;
        end;
      end;
    Inc(LIndex);
  end;
  Result := True;
end;

procedure TAasClusterBuilder.NumberClusterAreas(const AClusterNum: Integer);
var
  LIndex, LPortalNum: Integer;
begin
  FWorld.Clusters[AClusterNum].NumAreas := 0;
  FWorld.Clusters[AClusterNum].NumReachabilityAreas := 0;
  // number all areas in this cluster WITH reachabilities
  for LIndex := 1 to FWorld.NumAreas - 1 do
  begin
    if FWorld.AreaSettings[LIndex].Cluster <> AClusterNum then
      Continue;
    if FWorld.AreaReachability(LIndex) = 0 then
      Continue;
    FWorld.AreaSettings[LIndex].ClusterAreaNum := FWorld.Clusters[AClusterNum].NumAreas;
    Inc(FWorld.Clusters[AClusterNum].NumAreas);
    Inc(FWorld.Clusters[AClusterNum].NumReachabilityAreas);
  end;
  // number all portals in this cluster WITH reachabilities
  for LIndex := 0 to FWorld.Clusters[AClusterNum].NumPortals - 1 do
  begin
    LPortalNum := FWorld.PortalIndex[FWorld.Clusters[AClusterNum].FirstPortal + LIndex];
    if FWorld.AreaReachability(FWorld.Portals[LPortalNum].AreaNum) = 0 then
      Continue;
    if FWorld.Portals[LPortalNum].FrontCluster = AClusterNum then
      FWorld.Portals[LPortalNum].ClusterAreaNum[0] := FWorld.Clusters[AClusterNum].NumAreas
    else
      FWorld.Portals[LPortalNum].ClusterAreaNum[1] := FWorld.Clusters[AClusterNum].NumAreas;
    Inc(FWorld.Clusters[AClusterNum].NumAreas);
    Inc(FWorld.Clusters[AClusterNum].NumReachabilityAreas);
  end;
  // number all areas in this cluster WITHOUT reachabilities
  for LIndex := 1 to FWorld.NumAreas - 1 do
  begin
    if FWorld.AreaSettings[LIndex].Cluster <> AClusterNum then
      Continue;
    if FWorld.AreaReachability(LIndex) <> 0 then
      Continue;
    FWorld.AreaSettings[LIndex].ClusterAreaNum := FWorld.Clusters[AClusterNum].NumAreas;
    Inc(FWorld.Clusters[AClusterNum].NumAreas);
  end;
  // number all portals in this cluster WITHOUT reachabilities
  for LIndex := 0 to FWorld.Clusters[AClusterNum].NumPortals - 1 do
  begin
    LPortalNum := FWorld.PortalIndex[FWorld.Clusters[AClusterNum].FirstPortal + LIndex];
    if FWorld.AreaReachability(FWorld.Portals[LPortalNum].AreaNum) <> 0 then
      Continue;
    if FWorld.Portals[LPortalNum].FrontCluster = AClusterNum then
      FWorld.Portals[LPortalNum].ClusterAreaNum[0] := FWorld.Clusters[AClusterNum].NumAreas
    else
      FWorld.Portals[LPortalNum].ClusterAreaNum[1] := FWorld.Clusters[AClusterNum].NumAreas;
    Inc(FWorld.Clusters[AClusterNum].NumAreas);
  end;
end;

function TAasClusterBuilder.FindClusters: Boolean;
var
  LIndex: Integer;
begin
  RemoveClusterAreas;
  for LIndex := 1 to FWorld.NumAreas - 1 do
  begin
    // if the area is already part of a cluster
    if FWorld.AreaSettings[LIndex].Cluster <> 0 then
      Continue;
    // if not flooding through faces only use areas that have reachabilities
    if FNoFaceFlood then
      if FWorld.AreaSettings[LIndex].NumReachableAreas = 0 then
        Continue;
    // if the area is a cluster portal
    if (FWorld.AreaSettings[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
      Continue;
    if FWorld.NumClusters >= AAS_MAX_CLUSTERS then
    begin
      FWorld.Error('AAS_MAX_CLUSTERS');
      Exit(False);
    end;
    FWorld.Clusters[FWorld.NumClusters].NumAreas := 0;
    FWorld.Clusters[FWorld.NumClusters].NumReachabilityAreas := 0;
    FWorld.Clusters[FWorld.NumClusters].FirstPortal := FWorld.PortalIndexSize;
    FWorld.Clusters[FWorld.NumClusters].NumPortals := 0;
    // flood the areas in this cluster
    if not FloodClusterAreas(LIndex, FWorld.NumClusters) then
      Exit(False);
    if not FloodClusterAreasUsingReachabilities(FWorld.NumClusters) then
      Exit(False);
    // number the cluster areas
    NumberClusterAreas(FWorld.NumClusters);
    FWorld.NumClusters := FWorld.NumClusters + 1;
  end;
  Result := True;
end;

procedure TAasClusterBuilder.CreatePortals;
var
  LIndex: Integer;
begin
  for LIndex := 1 to FWorld.NumAreas - 1 do
    // if the area is a cluster portal
    if (FWorld.AreaSettings[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
    begin
      if FWorld.NumPortals >= AAS_MAX_PORTALS then
      begin
        FWorld.Error('AAS_MAX_PORTALS');
        Exit;
      end;
      FWorld.Portals[FWorld.NumPortals].AreaNum := LIndex;
      FWorld.Portals[FWorld.NumPortals].FrontCluster := 0;
      FWorld.Portals[FWorld.NumPortals].BackCluster := 0;
      FWorld.NumPortals := FWorld.NumPortals + 1;
    end;
end;

function TAasClusterBuilder.TestPortals: Boolean;
var
  LIndex, LArea: Integer;
begin
  for LIndex := 1 to FWorld.NumPortals - 1 do
  begin
    LArea := FWorld.Portals[LIndex].AreaNum;
    if FWorld.Portals[LIndex].FrontCluster = 0 then
    begin
      FWorld.AreaSettings[LArea].Contents := FWorld.AreaSettings[LArea].Contents and not AREACONTENTS_CLUSTERPORTAL;
      FWorld.LogWrite(Format('portal area %d has no front cluster'#13#10, [LArea]));
      Exit(False);
    end;
    if FWorld.Portals[LIndex].BackCluster = 0 then
    begin
      FWorld.AreaSettings[LArea].Contents := FWorld.AreaSettings[LArea].Contents and not AREACONTENTS_CLUSTERPORTAL;
      FWorld.LogWrite(Format('portal area %d has no back cluster'#13#10, [LArea]));
      Exit(False);
    end;
  end;
  Result := True;
end;

end.
