{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - the loaded file as routing data         }
{                                                                              }
{  Port of idAASLocal::CalculateAreaTravelTimes (AAS_routing.cpp) and of the   }
{  area centre of idAASFileLocal::FinishAreas, Doom 3 GPL Source Code.         }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Topology;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>
  ///   The file seen as the routing needs it: arrays of the areas, of the reachabilities that start
  ///   and that end in each area (in the order of the chains of the original), the centre of every
  ///   area and the travel time through each area for every pair of (reachability that starts,
  ///   reachability that arrives). The areas and reachabilities are the objects of the file, not
  ///   copies: what the routing changes (travel flags, <c>Number</c>, <c>DisableCount</c>, the
  ///   maximum travel time of the portals) is changed in the file, as in the original. The file is
  ///   not owned
  /// </summary>
  TAasTopology = class
  strict private
    FFile: TAasFile;
    FAreas: TArray<TAasArea>;
    FReach: TArray<TArray<TAasReachability>>;
    FRevReach: TArray<TArray<TAasReachability>>;
    FCenters: TArray<TGeoVec3>;
    FTravelTimes: TArray<Word>;
    FReachRow: TArray<TArray<Integer>>;
    procedure Validate;
    procedure CalculateAreaTravelTimes;
  public
    /// <summary>
    ///   Takes the arrays from the file, checks that every number that the routing uses to index is
    ///   inside the file (EAasRoutingException) and computes the travel times of the areas. The
    ///   sampler gives the centre of the areas (area->center of the original)
    /// </summary>
    constructor Create(const AFile: TAasFile; const ASampler: IAasSampler);
    property AasFile: TAasFile read FFile;
    /// <summary>The areas of the file by number</summary>
    property Areas: TArray<TAasArea> read FAreas;
    /// <summary>The reachabilities that start in the area (area->reach, next, next, ...)</summary>
    property Reach: TArray<TArray<TAasReachability>> read FReach;
    /// <summary>The reachabilities that lead to the area (area->rev_reach, rev_next, ...)</summary>
    property RevReach: TArray<TArray<TAasReachability>> read FRevReach;
    property Centers: TArray<TGeoVec3> read FCenters;
    /// <summary>All the travel times through the areas, one row per reachability that starts in an area</summary>
    property TravelTimes: TArray<Word> read FTravelTimes;
    /// <summary>
    ///   The first entry in <c>TravelTimes</c> of the row of the reachability <c>[area][number]</c>;
    ///   entry <c>j</c> of the row is the time from the start of the reachability to the end of the
    ///   <c>j</c>th reachability that leads to the area
    /// </summary>
    property ReachRow: TArray<TArray<Integer>> read FReachRow;
    /// <summary>The number of areas</summary>
    function NumAreas: Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Aas.Types, DelphiDoom.Aas.D3.Types, DelphiDoom.Aas.D3.TravelTime;

resourcestring
  SGeometryOutOfRange = 'AAS routing: the faces, edges or vertices that area, face or edge %d refers to are not in the file';
  SNoAreas ='AAS routing: the file has no areas';
  SAreaClusterOutOfRange = 'AAS routing: area %d is in cluster %d, which the file does not hold';
  SAreaClusterAreaNum = 'AAS routing: area %d has the negative number %d inside its cluster';
  SReachAreaOutOfRange = 'AAS routing: a reachability of area %d leads to or from area %d, which the file does not hold';
  SPortalOutOfRange = 'AAS routing: portal %d refers to area %d, cluster %d or cluster area %d that the file does not hold';
  SClusterPortalsOutOfRange = 'AAS routing: cluster %d has portals outside the portal index';
  SReachWithoutFlags = 'AAS routing: area %d has reachabilities but is neither AREA_REACHABLE_WALK nor AREA_REACHABLE_FLY';
  STooManyReach = 'AAS routing: area %d has more than %d reachabilities';

{ TAasTopology }

constructor TAasTopology.Create(const AFile: TAasFile; const ASampler: IAasSampler);
var
  LIndex, LNumber: Integer;
  LArea: TAasArea;
begin
  inherited Create;
  FFile := AFile;
  if AFile.NumAreas < 1 then
    raise EAasRoutingException.Create(SNoAreas);
  SetLength(FAreas, AFile.NumAreas);
  SetLength(FReach, AFile.NumAreas);
  SetLength(FRevReach, AFile.NumAreas);
  SetLength(FCenters, AFile.NumAreas);
  for LIndex := 0 to AFile.NumAreas - 1 do
  begin
    LArea := AFile.Areas[LIndex];
    FAreas[LIndex] := LArea;
    SetLength(FReach[LIndex], LArea.Reach.Count);
    for LNumber := 0 to LArea.Reach.Count - 1 do
      FReach[LIndex][LNumber] := LArea.Reach[LNumber];
    SetLength(FRevReach[LIndex], LArea.ReverseReach.Count);
    for LNumber := 0 to LArea.ReverseReach.Count - 1 do
      FRevReach[LIndex][LNumber] := LArea.ReverseReach[LNumber];
  end;
  Validate;
  for LIndex := 0 to AFile.NumAreas - 1 do
    FCenters[LIndex] := ASampler.AreaReachableGoal(LIndex);
  CalculateAreaTravelTimes;
end;

function TAasTopology.NumAreas: Integer;
begin
  Result := Length(FAreas);
end;

procedure TAasTopology.Validate;
var
  LIndex, LPosition, LCluster: Integer;
  LArea: TAasArea;
  LReach: TAasReachability;
  LPortal: TAasPortal;
  LFileCluster: TAasCluster;

  procedure CheckReach(const AFromArea: Integer; const AReach: TAasReachability);
  begin
    if (AReach.ToAreaNum < 1) or (AReach.ToAreaNum >= NumAreas) or (AReach.FromAreaNum < 1) or
      (AReach.FromAreaNum >= NumAreas) then
      raise EAasRoutingException.Create(Format(SReachAreaOutOfRange, [AFromArea, AReach.ToAreaNum]));
  end;

begin
  for LIndex := 1 to NumAreas - 1 do
  begin
    LArea := FAreas[LIndex];
    LCluster := LArea.Cluster;
    if (LCluster = 0) or (LCluster >= FFile.NumClusters) or ((LCluster < 0) and (-LCluster >= FFile.NumPortals)) then
      raise EAasRoutingException.Create(Format(SAreaClusterOutOfRange, [LIndex, LCluster]));
    if LArea.ClusterAreaNum < 0 then
      raise EAasRoutingException.Create(Format(SAreaClusterAreaNum, [LIndex, LArea.ClusterAreaNum]));
    for LReach in FReach[LIndex] do
      CheckReach(LIndex, LReach);
    for LReach in FRevReach[LIndex] do
      CheckReach(LIndex, LReach);
  end;
  // the geometry that the paths and the wall edges walk through
  for LIndex := 0 to FFile.NumEdges - 1 do
    if (FFile.Edges[LIndex].VertexNum[0] < 0) or (FFile.Edges[LIndex].VertexNum[0] >= FFile.NumVertices) or
      (FFile.Edges[LIndex].VertexNum[1] < 0) or (FFile.Edges[LIndex].VertexNum[1] >= FFile.NumVertices) then
      raise EAasRoutingException.Create(Format(SGeometryOutOfRange, [LIndex]));
  for LIndex := 0 to FFile.NumFaces - 1 do
    if (FFile.Faces[LIndex].FirstEdge < 0) or (FFile.Faces[LIndex].NumEdges < 0) or
      (Int64(FFile.Faces[LIndex].FirstEdge) + FFile.Faces[LIndex].NumEdges > Length(FFile.EdgeIndex)) then
      raise EAasRoutingException.Create(Format(SGeometryOutOfRange, [LIndex]))
    else
      for LPosition := FFile.Faces[LIndex].FirstEdge to FFile.Faces[LIndex].FirstEdge + FFile.Faces[LIndex].NumEdges - 1 do
        if Abs(FFile.EdgeIndex[LPosition]) >= FFile.NumEdges then
          raise EAasRoutingException.Create(Format(SGeometryOutOfRange, [LIndex]));
  for LIndex := 0 to NumAreas - 1 do
  begin
    LArea := FAreas[LIndex];
    if (LArea.FirstFace < 0) or (LArea.NumFaces < 0) or
      (Int64(LArea.FirstFace) + LArea.NumFaces > Length(FFile.FaceIndex)) then
      raise EAasRoutingException.Create(Format(SGeometryOutOfRange, [LIndex]));
    for LPosition := LArea.FirstFace to LArea.FirstFace + LArea.NumFaces - 1 do
      if Abs(FFile.FaceIndex[LPosition]) >= FFile.NumFaces then
        raise EAasRoutingException.Create(Format(SGeometryOutOfRange, [LIndex]));
  end;
  for LIndex := 1 to FFile.NumPortals - 1 do
  begin
    LPortal := FFile.Portals[LIndex];
    if (LPortal.AreaNum < 1) or (LPortal.AreaNum >= NumAreas) or (LPortal.Clusters[0] < 0) or
      (LPortal.Clusters[0] >= FFile.NumClusters) or (LPortal.Clusters[1] < 0) or
      (LPortal.Clusters[1] >= FFile.NumClusters) or (LPortal.ClusterAreaNum[0] < 0) or
      (LPortal.ClusterAreaNum[1] < 0) then
      raise EAasRoutingException.Create(Format(SPortalOutOfRange,
        [LIndex, LPortal.AreaNum, LPortal.Clusters[0], LPortal.ClusterAreaNum[0]]));
  end;
  for LIndex := 0 to FFile.NumClusters - 1 do
  begin
    LFileCluster := FFile.Clusters[LIndex];
    if (LFileCluster.FirstPortal < 0) or (LFileCluster.NumPortals < 0) or (LFileCluster.NumReachableAreas < 0) or
      (Int64(LFileCluster.FirstPortal) + LFileCluster.NumPortals > Length(FFile.PortalIndex)) then
      raise EAasRoutingException.Create(Format(SClusterPortalsOutOfRange, [LIndex]));
    for LPosition := LFileCluster.FirstPortal to LFileCluster.FirstPortal + LFileCluster.NumPortals - 1 do
      if (FFile.PortalIndex[LPosition] < 0) or (FFile.PortalIndex[LPosition] >= FFile.NumPortals) then
        raise EAasRoutingException.Create(Format(SClusterPortalsOutOfRange, [LIndex]));
  end;
end;

procedure TAasTopology.CalculateAreaTravelTimes;
var
  LAreaNum, LNumber, LRevNumber, LTotal, LPosition, LMaxTime: Integer;
  LTime: Word;
  LArea: TAasArea;
  LReach: TAasReachability;
  LPortals: TArray<TAasPortal>;
begin
  LTotal := 0;
  for LAreaNum := 0 to NumAreas - 1 do
  begin
    LArea := FAreas[LAreaNum];
    if (LArea.Flags and (AREA_REACHABLE_WALK or AREA_REACHABLE_FLY)) = 0 then
    begin
      if Length(FReach[LAreaNum]) > 0 then
        raise EAasRoutingException.Create(Format(SReachWithoutFlags, [LAreaNum]));
      Continue;
    end;
    if Length(FReach[LAreaNum]) > MAX_REACH_PER_AREA then
      raise EAasRoutingException.Create(Format(STooManyReach, [LAreaNum, MAX_REACH_PER_AREA]));
    Inc(LTotal, Length(FReach[LAreaNum]) * Length(FRevReach[LAreaNum]));
  end;
  SetLength(FTravelTimes, LTotal);
  SetLength(FReachRow, NumAreas);
  LPortals := FFile.Portals;
  LPosition := 0;
  for LAreaNum := 0 to NumAreas - 1 do
  begin
    LArea := FAreas[LAreaNum];
    if (LArea.Flags and (AREA_REACHABLE_WALK or AREA_REACHABLE_FLY)) = 0 then
      Continue;
    SetLength(FReachRow[LAreaNum], Length(FReach[LAreaNum]));
    LMaxTime := 0;
    // for each reachability that starts in this area calculate the travel time
    // towards all the reachabilities that lead towards this area
    for LNumber := 0 to Length(FReach[LAreaNum]) - 1 do
    begin
      LReach := FReach[LAreaNum][LNumber];
      LReach.Number := LNumber;
      LReach.DisableCount := 0;
      FReachRow[LAreaNum][LNumber] := LPosition;
      for LRevNumber := 0 to Length(FRevReach[LAreaNum]) - 1 do
      begin
        LTime := TAasTravelTime.Calculate(LArea.TravelFlags, LReach.StartPoint,
          FRevReach[LAreaNum][LRevNumber].EndPoint);
        FTravelTimes[LPosition + LRevNumber] := LTime;
        if LTime > LMaxTime then
          LMaxTime := LTime;
      end;
      Inc(LPosition, Length(FRevReach[LAreaNum]));
    end;
    // if this area is a portal set the maximum travel time through it
    if LArea.Cluster < 0 then
      LPortals[-LArea.Cluster].MaxAreaTravelTime := Word(LMaxTime);
  end;
end;

end.
