{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the text form of an .aas file   }
{  that the driver of the C++ harness prints (Tests\Data\MapFile\harness)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.AasDump;

{$Q-}
{$R-}

interface

uses
  System.Classes, DelphiDoom.MapFile.Aas.AasFile;

type
  /// <summary>
  ///   The lines of aas.golden.txt for a file that was read: floats are "#" and the 32 bits in
  ///   hexadecimal. The centre of an area is the mean of its faces (the C++ gives the reachable
  ///   goal for the areas that have a reachable flag, which needs a trace and is not ported: the
  ///   data of the tests have none)
  /// </summary>
  TAasDump = class
  public
    class function Hex(const AValue: Single): string; static;
    /// <summary>The CRC line shows the CRC that the caller expected (the C++ keeps that one, not the file's)</summary>
    class procedure Dump(const AFile: TAasFile; const AOutput: TStrings; const AExpectedCrc: Cardinal); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds,
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.Reachability,
  DelphiDoom.MapFile.Aas.Geometry, DelphiDoom.MapFile.Aas.Settings, DelphiDoom.Scanner.IdDict;

procedure Line(const AOutput: TStrings; const AFormat: string; const AArgs: array of const);
begin
  AOutput.Add(Format(AFormat, AArgs));
end;

procedure DumpReachabilities(const AFile: TAasFile; const AOutput: TStrings; const AIndex: Integer);
var
  LArea: TAasArea;
  LReach: TAasReachability;
  LIndex, LKey: Integer;
  LStart, LEnd: TGeoVec3;
  LPair: TIdKeyValue;
begin
  LArea := AFile.Areas[AIndex];
  for LIndex := 0 to LArea.Reach.Count - 1 do
  begin
    LReach := LArea.Reach[LIndex];
    LStart := LReach.StartPoint;
    LEnd := LReach.EndPoint;
    Line(AOutput, 'R %d %d %d %d %d %s %s %s %s %s %s %d %d', [AIndex, LIndex, LReach.TravelType,
      Integer(LReach.ToAreaNum), Integer(LReach.FromAreaNum), TAasDump.Hex(LStart.X), TAasDump.Hex(LStart.Y),
      TAasDump.Hex(LStart.Z), TAasDump.Hex(LEnd.X), TAasDump.Hex(LEnd.Y), TAasDump.Hex(LEnd.Z), LReach.EdgeNum,
      Integer(LReach.TravelTime)]);
    if LReach.TravelType = TFL_SPECIAL then
      for LKey := 0 to LReach.Special.GetNumKeyVals - 1 do
        if LReach.Special.TryGetKeyVal(LKey, LPair) then
          Line(AOutput, 'RS %d %d |%s|=|%s|', [AIndex, LIndex, string(LPair.Key), string(LPair.Value)]);
  end;
  for LIndex := 0 to LArea.ReverseReach.Count - 1 do
  begin
    LReach := LArea.ReverseReach[LIndex];
    Line(AOutput, 'RR %d %d from %d edge %d time %d', [AIndex, LIndex, Integer(LReach.FromAreaNum),
      LReach.EdgeNum, Integer(LReach.TravelTime)]);
  end;
end;

procedure DumpSettings(const ASettings: TAasSettings; const AOutput: TStrings);
var
  LIndex: Integer;
  LBounds: TGeoBounds;
begin
  Line(AOutput, 'SBOXES %d', [ASettings.NumBoundingBoxes]);
  for LIndex := 0 to ASettings.NumBoundingBoxes - 1 do
  begin
    LBounds := ASettings.BoundingBoxes[LIndex];
    Line(AOutput, 'SB %d %s %s %s %s %s %s', [LIndex, TAasDump.Hex(LBounds.Mins.X), TAasDump.Hex(LBounds.Mins.Y),
      TAasDump.Hex(LBounds.Mins.Z), TAasDump.Hex(LBounds.Maxs.X), TAasDump.Hex(LBounds.Maxs.Y),
      TAasDump.Hex(LBounds.Maxs.Z)]);
  end;
  Line(AOutput, 'SFLAGS %d %d %d %d %d %d', [Ord(ASettings.UsePatches), Ord(ASettings.WriteBrushMap),
    Ord(ASettings.PlayerFlood), Ord(ASettings.NoOptimize), Ord(ASettings.AllowSwimReachabilities),
    Ord(ASettings.AllowFlyReachabilities)]);
  Line(AOutput, 'SEXT |%s|', [string(ASettings.FileExtension)]);
  Line(AOutput, 'SGRAV %s %s %s', [TAasDump.Hex(ASettings.Gravity.X), TAasDump.Hex(ASettings.Gravity.Y),
    TAasDump.Hex(ASettings.Gravity.Z)]);
  Line(AOutput, 'SGDIR %s %s %s %s', [TAasDump.Hex(ASettings.GravityDir.X), TAasDump.Hex(ASettings.GravityDir.Y),
    TAasDump.Hex(ASettings.GravityDir.Z), TAasDump.Hex(ASettings.GravityValue)]);
  Line(AOutput, 'SIGDIR %s %s %s', [TAasDump.Hex(ASettings.InvGravityDir.X), TAasDump.Hex(ASettings.InvGravityDir.Y),
    TAasDump.Hex(ASettings.InvGravityDir.Z)]);
  Line(AOutput, 'SHEIGHTS %s %s %s %s %s', [TAasDump.Hex(ASettings.MaxStepHeight),
    TAasDump.Hex(ASettings.MaxBarrierHeight), TAasDump.Hex(ASettings.MaxWaterJumpHeight),
    TAasDump.Hex(ASettings.MaxFallHeight), TAasDump.Hex(ASettings.MinFloorCos)]);
  Line(AOutput, 'STT %d %d %d %d', [ASettings.BarrierJumpTime, ASettings.StartCrouchingTime,
    ASettings.WaterJumpTime, ASettings.StartWalkOffLedgeTime]);
end;

{ TAasDump }

class function TAasDump.Hex(const AValue: Single): string;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, SizeOf(LBits));
  Result := '#' + LowerCase(IntToHex(LBits, 8));
end;

class procedure TAasDump.Dump(const AFile: TAasFile; const AOutput: TStrings; const AExpectedCrc: Cardinal);
var
  LIndex: Integer;
  LPlane: TGeoPlane;
  LVertex, LCenter: TGeoVec3;
  LFace: TAasFace;
  LArea: TAasArea;
  LBounds: TGeoBounds;
  LNode: TAasNode;
  LPortal: TAasPortal;
  LCluster: TAasCluster;
begin
  Line(AOutput, 'CRC %u', [AExpectedCrc]);
  Line(AOutput, 'PLANES %d', [AFile.NumPlanes]);
  for LIndex := 0 to AFile.NumPlanes - 1 do
  begin
    LPlane := AFile.Planes[LIndex];
    Line(AOutput, 'PL %d %s %s %s %s', [LIndex, Hex(LPlane.A), Hex(LPlane.B), Hex(LPlane.C), Hex(LPlane.D)]);
  end;
  Line(AOutput, 'VERTICES %d', [AFile.NumVertices]);
  for LIndex := 0 to AFile.NumVertices - 1 do
  begin
    LVertex := AFile.Vertices[LIndex];
    Line(AOutput, 'V %d %s %s %s', [LIndex, Hex(LVertex.X), Hex(LVertex.Y), Hex(LVertex.Z)]);
  end;
  Line(AOutput, 'EDGES %d', [AFile.NumEdges]);
  for LIndex := 0 to AFile.NumEdges - 1 do
    Line(AOutput, 'E %d %d %d', [LIndex, AFile.Edges[LIndex].VertexNum[0], AFile.Edges[LIndex].VertexNum[1]]);
  Line(AOutput, 'EDGEINDEX %d', [Length(AFile.EdgeIndex)]);
  for LIndex := 0 to High(AFile.EdgeIndex) do
    Line(AOutput, 'EI %d %d', [LIndex, AFile.EdgeIndex[LIndex]]);
  Line(AOutput, 'FACES %d', [AFile.NumFaces]);
  for LIndex := 0 to AFile.NumFaces - 1 do
  begin
    LFace := AFile.Faces[LIndex];
    Line(AOutput, 'F %d %d %d %d %d %d %d', [LIndex, Integer(LFace.PlaneNum), Integer(LFace.Flags),
      Integer(LFace.Areas[0]), Integer(LFace.Areas[1]), LFace.FirstEdge, LFace.NumEdges]);
  end;
  Line(AOutput, 'FACEINDEX %d', [Length(AFile.FaceIndex)]);
  for LIndex := 0 to High(AFile.FaceIndex) do
    Line(AOutput, 'FI %d %d', [LIndex, AFile.FaceIndex[LIndex]]);
  Line(AOutput, 'AREAS %d', [AFile.NumAreas]);
  for LIndex := 0 to AFile.NumAreas - 1 do
  begin
    LArea := AFile.Areas[LIndex];
    Line(AOutput, 'A %d %d %d %d %d %d %d %d', [LIndex, Integer(LArea.Flags), Integer(LArea.Contents),
      LArea.FirstFace, LArea.NumFaces, Integer(LArea.Cluster), Integer(LArea.ClusterAreaNum), LArea.TravelFlags]);
    LBounds := LArea.Bounds;
    Line(AOutput, 'AB %d %s %s %s %s %s %s', [LIndex, Hex(LBounds.Mins.X), Hex(LBounds.Mins.Y),
      Hex(LBounds.Mins.Z), Hex(LBounds.Maxs.X), Hex(LBounds.Maxs.Y), Hex(LBounds.Maxs.Z)]);
    LCenter := TAasGeometry.AreaCenter(AFile, LIndex);
    Line(AOutput, 'AC %d %s %s %s', [LIndex, Hex(LCenter.X), Hex(LCenter.Y), Hex(LCenter.Z)]);
    DumpReachabilities(AFile, AOutput, LIndex);
  end;
  Line(AOutput, 'NODES %d', [AFile.NumNodes]);
  for LIndex := 0 to AFile.NumNodes - 1 do
  begin
    LNode := AFile.Nodes[LIndex];
    Line(AOutput, 'N %d %d %d %d', [LIndex, Integer(LNode.PlaneNum), LNode.Children[0], LNode.Children[1]]);
  end;
  Line(AOutput, 'PORTALS %d', [AFile.NumPortals]);
  for LIndex := 0 to AFile.NumPortals - 1 do
  begin
    LPortal := AFile.Portals[LIndex];
    // MaxAreaTravelTime is not printed: the C++ leaves it uninitialised after a load (243 on the stack of the harness)
    Line(AOutput, 'P %d %d %d %d %d %d', [LIndex, Integer(LPortal.AreaNum), Integer(LPortal.Clusters[0]),
      Integer(LPortal.Clusters[1]), Integer(LPortal.ClusterAreaNum[0]), Integer(LPortal.ClusterAreaNum[1])]);
  end;
  Line(AOutput, 'PORTALINDEX %d', [Length(AFile.PortalIndex)]);
  for LIndex := 0 to High(AFile.PortalIndex) do
    Line(AOutput, 'PI %d %d', [LIndex, AFile.PortalIndex[LIndex]]);
  Line(AOutput, 'CLUSTERS %d', [AFile.NumClusters]);
  for LIndex := 0 to AFile.NumClusters - 1 do
  begin
    LCluster := AFile.Clusters[LIndex];
    Line(AOutput, 'C %d %d %d %d %d', [LIndex, LCluster.NumAreas, LCluster.NumReachableAreas, LCluster.FirstPortal,
      LCluster.NumPortals]);
  end;
  DumpSettings(AFile.Settings, AOutput);
  Line(AOutput, 'DEPTH %d', [TAasGeometry.MaxTreeDepth(AFile)]);
  Line(AOutput, 'NUMREACH %d', [AFile.NumReachabilities]);
end;

end.
