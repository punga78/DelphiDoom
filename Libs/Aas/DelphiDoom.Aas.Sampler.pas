{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the area of a point (be_aas_sample.c)             }
{                                                                              }
{  Port of AAS_PointAreaNum, AAS_PointPresenceType and                         }
{  AAS_PointReachabilityAreaIndex. Based on the Quake III Arena GPL Source     }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Sampler;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   Walks the tree of nodes with a point. The original trusts the file: a node or a plane
  ///   out of range, or a loop in the tree, reads outside the arrays or never ends; here they
  ///   are the errors of the debug build of the original (printed, and the answer is 0).
  /// </summary>
  TAasSampler = class(TInterfacedObject, IAasSampler)
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    FInitialized: Boolean;
  public
    /// <summary>
    ///   AInitialized is aasworld.initialized, set by the code that prepares the routing
    ///   (not part of this library): without it the reachability index is always 0
    /// </summary>
    constructor Create(const AFile: IAasFile; const AImport: IBotImport; const AInitialized: Boolean = False);
    function PointAreaNum(const APoint: TVec3): Integer;
    function PointPresenceType(const APoint: TVec3): Integer;
    function PointReachabilityAreaIndex(const APoint: TVec3): Integer;
    function ReachabilityAreaCount: Integer;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath,
  System.SysUtils;

resourcestring
  SNodeOutOfRange = 'nodenum = %d >= aasworld.numnodes = %d'#10;
  SPlaneOutOfRange = 'node->planenum = %d >= aasworld.numplanes = %d'#10;
  SLoopInTree = 'AAS_PointAreaNum: the tree of nodes has a loop'#10;

{ TAasSampler }

constructor TAasSampler.Create(const AFile: IAasFile; const AImport: IBotImport; const AInitialized: Boolean);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
  FInitialized := AInitialized;
end;

function TAasSampler.PointAreaNum(const APoint: TVec3): Integer;
var
  LNodes: TArray<TAasNode>;
  LPlanes: TArray<TAasPlane>;
  LNodeNum, LSteps: Integer;
  LNode: TAasNode;
  LDist: Single;
begin
  LNodes := FFile.Nodes;
  LPlanes := FFile.Planes;
  // start with node 1 because node zero is a dummy used for solid leafs
  LNodeNum := 1;
  LSteps := 0;
  while LNodeNum > 0 do
  begin
    if LNodeNum >= Length(LNodes) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, Format(SNodeOutOfRange, [LNodeNum, Length(LNodes)]));
      Exit(0);
    end;
    LNode := LNodes[LNodeNum];
    if (LNode.PlaneNum < 0) or (LNode.PlaneNum >= Length(LPlanes)) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, Format(SPlaneOutOfRange, [LNode.PlaneNum, Length(LPlanes)]));
      Exit(0);
    end;
    LDist := TAasVectorMath.Dot(APoint, LPlanes[LNode.PlaneNum].Normal);
    LDist := LDist - LPlanes[LNode.PlaneNum].Dist;
    if LDist > 0 then
      LNodeNum := LNode.Children[0]
    else
      LNodeNum := LNode.Children[1];
    Inc(LSteps);
    if LSteps > Length(LNodes) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, SLoopInTree);
      Exit(0);
    end;
  end;
  if LNodeNum = 0 then
    Exit(0);
  Result := -LNodeNum;
end;

function TAasSampler.PointPresenceType(const APoint: TVec3): Integer;
var
  LAreaNum: Integer;
  LSettings: TArray<TAasAreaSettings>;
begin
  LAreaNum := PointAreaNum(APoint);
  if LAreaNum = 0 then
    Exit(PRESENCE_NONE);
  LSettings := FFile.AreaSettings;
  if LAreaNum >= Length(LSettings) then
    Exit(0);
  Result := LSettings[LAreaNum].PresenceType;
end;

function TAasSampler.ReachabilityAreaCount: Integer;
var
  LClusters: TArray<TAasCluster>;
  LIndex: Integer;
begin
  Result := 0;
  if not FInitialized then
    Exit;
  LClusters := FFile.Clusters;
  for LIndex := 0 to High(LClusters) do
    Inc(Result, LClusters[LIndex].NumReachabilityAreas);
end;

function TAasSampler.PointReachabilityAreaIndex(const APoint: TVec3): Integer;
var
  LAreaNum, LCluster, LClusterAreaNum, LIndex: Integer;
  LSettings: TArray<TAasAreaSettings>;
  LClusters: TArray<TAasCluster>;
  LPortals: TArray<TAasPortal>;
begin
  Result := 0;
  if not FInitialized then
    Exit;
  LSettings := FFile.AreaSettings;
  LClusters := FFile.Clusters;
  LPortals := FFile.Portals;
  LAreaNum := PointAreaNum(APoint);
  if (LAreaNum = 0) or (LAreaNum >= Length(LSettings)) or (LSettings[LAreaNum].NumReachableAreas = 0) then
    Exit;
  LCluster := LSettings[LAreaNum].Cluster;
  LClusterAreaNum := LSettings[LAreaNum].ClusterAreaNum;
  if LCluster < 0 then
  begin
    // the original assigns the cluster first and then indexes the portals with the new,
    // positive cluster (-cluster = a negative index): the portal is the one of the area
    if -LCluster >= Length(LPortals) then
      Exit;
    LClusterAreaNum := LPortals[-LCluster].ClusterAreaNum[0];
    LCluster := LPortals[-LCluster].FrontCluster;
  end;
  if (LCluster < 0) or (LCluster > Length(LClusters)) then
    Exit;
  for LIndex := 0 to LCluster - 1 do
    Inc(Result, LClusters[LIndex].NumReachabilityAreas);
  Inc(Result, LClusterAreaNum);
end;

end.
