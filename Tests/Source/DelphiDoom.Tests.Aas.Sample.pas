{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the small worlds of the tests        }
{                                                                              }
{  Builds the same .aas files as Tools\Verifica\122\aasgen.c (same recipe:     }
{  a row of boxes of 64 units, a tree of nodes, faces, reachabilities). No     }
{  file of the game is used or stored.                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Sample;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types;

const
  /// <summary>The checksum of the BSP the samples are made for</summary>
  SAMPLE_CHECKSUM = $12345678;

type
  /// <summary>
  ///   Variants: 0 four areas, version 5; 1 six areas with a skew plane at the root of the
  ///   areas tree and other contents; 2 as 0 in version 4 (header not scrambled); 3 as 0
  ///   with 16 bytes between the lumps of the edges and of the faces
  /// </summary>
  TAasSample = class
  strict private
    class function FindEdge(var AEdges: TList<TAasEdge>; const AFirst, ASecond: Integer): Integer; static;
  public
    class function AreaCount(const AVariant: Integer): Integer; static;
    class function Content(const AVariant: Integer): TAasFileData; static;
    /// <summary>The file: header, lumps, scrambled header for version 5</summary>
    class function Bytes(const AVariant: Integer): TBytes; static;
    /// <summary>The lumps as bytes in the order of the header, for a file that is already laid out</summary>
    class function Layout(const AContent: TAasFileData; const AVersion, AGap: Integer): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Aas.AasFile, DelphiDoom.Aas.Intf, DelphiDoom.Aas.HeaderCipher;

function Vec(const X, Y, Z: Single): TVec3;
begin
  Result[0] := X;
  Result[1] := Y;
  Result[2] := Z;
end;

function Vertex(const X, Y, Z: Integer): Integer;
begin
  Result := 1 + X * 4 + Y * 2 + Z;
end;

{ TAasSample }

class function TAasSample.AreaCount(const AVariant: Integer): Integer;
begin
  if AVariant = 1 then
    Result := 6
  else
    Result := 4;
end;

class function TAasSample.FindEdge(var AEdges: TList<TAasEdge>; const AFirst, ASecond: Integer): Integer;
var
  LIndex: Integer;
  LEdge: TAasEdge;
begin
  for LIndex := 1 to AEdges.Count - 1 do
  begin
    if (AEdges[LIndex].Vertexes[0] = AFirst) and (AEdges[LIndex].Vertexes[1] = ASecond) then
      Exit(LIndex);
    if (AEdges[LIndex].Vertexes[0] = ASecond) and (AEdges[LIndex].Vertexes[1] = AFirst) then
      Exit(-LIndex);
  end;
  LEdge.Vertexes[0] := AFirst;
  LEdge.Vertexes[1] := ASecond;
  AEdges.Add(LEdge);
  Result := AEdges.Count - 1;
end;

class function TAasSample.Content(const AVariant: Integer): TAasFileData;
var
  LAreas: Integer;
  LPlanes: TList<TAasPlane>;
  LEdges: TList<TAasEdge>;
  LEdgeIndex, LFaceIndex: TList<Integer>;
  LFaces: TList<TAasFace>;
  LNodes: TList<TAasNode>;
  LRootX: Integer;
  LSkew: Boolean;

  procedure AddPair(const ANormal: TVec3; const ADist: Single; const AType: Integer);
  var
    LPlane: TAasPlane;
  begin
    LPlane.Normal := ANormal;
    LPlane.Dist := ADist;
    LPlane.PlaneType := AType;
    LPlanes.Add(LPlane);
    LPlane.Normal[0] := -ANormal[0];
    LPlane.Normal[1] := -ANormal[1];
    LPlane.Normal[2] := -ANormal[2];
    LPlane.Dist := -ADist;
    LPlanes.Add(LPlane);
  end;

  function AddNode(const APlane, AFront, ABack: Integer): Integer;
  var
    LNode: TAasNode;
  begin
    LNode.PlaneNum := APlane;
    LNode.Children[0] := AFront;
    LNode.Children[1] := ABack;
    LNodes.Add(LNode);
    Result := LNodes.Count - 1;
  end;

  procedure SetChildren(const ANode, AFront, ABack: Integer);
  var
    LNode: TAasNode;
  begin
    LNode := LNodes[ANode];
    LNode.Children[0] := AFront;
    LNode.Children[1] := ABack;
    LNodes[ANode] := LNode;
  end;

  // the areas LowArea..HighArea - 1 (zero based) as a subtree; returns the child value
  function BuildX(const ALow, AHigh: Integer): Integer;
  var
    LMiddle, LNodeNum, LFront, LBack, LPlane: Integer;
  begin
    if AHigh - ALow = 1 then
      Exit(-(ALow + 1));
    LMiddle := (ALow + AHigh) div 2;
    if LSkew and (ALow = 0) and (AHigh = LAreas) then
      LPlane := 2 * LRootX
    else
      LPlane := 2 * (4 + LMiddle);
    LNodeNum := AddNode(LPlane, 0, 0);
    LFront := BuildX(LMiddle, AHigh);
    LBack := BuildX(ALow, LMiddle);
    SetChildren(LNodeNum, LFront, LBack);
    Result := LNodeNum;
  end;

  // a face of the box grid: axis W (normal +W) at the grid coordinate C, U and V are the
  // next axes (U x V = W); the edges go clockwise as seen along the normal
  procedure AddFace(const AAxis, ACoord, AU0, AU1, AV0, AV1, APlane, AFlags, AFront, ABack: Integer);
  var
    LU, LV, LCorner: Integer;
    LPoints: array[0..3] of Integer;
    LGrid: array[0..3] of array[0..2] of Integer;
    LFace: TAasFace;
    LIndex: Integer;
    LCoordinates: array[0..3] of array[0..1] of Integer;
  begin
    LU := (AAxis + 1) mod 3;
    LV := (AAxis + 2) mod 3;
    LCoordinates[0][0] := AU0; LCoordinates[0][1] := AV0;
    LCoordinates[1][0] := AU0; LCoordinates[1][1] := AV1;
    LCoordinates[2][0] := AU1; LCoordinates[2][1] := AV1;
    LCoordinates[3][0] := AU1; LCoordinates[3][1] := AV0;
    for LCorner := 0 to 3 do
    begin
      LGrid[LCorner][AAxis] := ACoord;
      LGrid[LCorner][LU] := LCoordinates[LCorner][0];
      LGrid[LCorner][LV] := LCoordinates[LCorner][1];
      LPoints[LCorner] := Vertex(LGrid[LCorner][0], LGrid[LCorner][1], LGrid[LCorner][2]);
    end;
    LFace.PlaneNum := APlane;
    LFace.FaceFlags := AFlags;
    LFace.NumEdges := 4;
    LFace.FirstEdge := LEdgeIndex.Count;
    LFace.FrontArea := AFront;
    LFace.BackArea := ABack;
    for LIndex := 0 to 3 do
      LEdgeIndex.Add(FindEdge(LEdges, LPoints[LIndex], LPoints[(LIndex + 1) mod 4]));
    LFaces.Add(LFace);
  end;

var
  LArea, LNodeNum, LNeighbor, LFaceNum, LClusterOne, LClusterTwo: Integer;
  LVertexes: TList<TVec3>;
  LAreaList: TList<TAasArea>;
  LSettings: TList<TAasAreaSettings>;
  LReach: TList<TAasReachability>;
  LPortals: TList<TAasPortal>;
  LClusters: TList<TAasCluster>;
  LBox: TAasBBox;
  LAreaRecord: TAasArea;
  LSetting: TAasAreaSettings;
  LReachRecord: TAasReachability;
  LPortal: TAasPortal;
  LCluster: TAasCluster;
  LX, LY, LZ, LContents, LFlags, LCount: Integer;
  LNodeY1, LNodeZ0, LNodeZ1, LRoot: Integer;
  LNormal: TVec3;
begin
  LAreas := AreaCount(AVariant);
  LSkew := AVariant = 1;
  FillChar(Result, SizeOf(Result), 0);
  LPlanes := TList<TAasPlane>.Create;
  LEdges := TList<TAasEdge>.Create;
  LEdgeIndex := TList<Integer>.Create;
  LFaceIndex := TList<Integer>.Create;
  LFaces := TList<TAasFace>.Create;
  LNodes := TList<TAasNode>.Create;
  LVertexes := TList<TVec3>.Create;
  LAreaList := TList<TAasArea>.Create;
  LSettings := TList<TAasAreaSettings>.Create;
  LReach := TList<TAasReachability>.Create;
  LPortals := TList<TAasPortal>.Create;
  LClusters := TList<TAasCluster>.Create;
  try
    // bounding boxes: normal and crouching client
    SetLength(Result.BBoxes, 2);
    LBox.PresenceType := PRESENCE_NORMAL;
    LBox.Flags := 0;
    LBox.Mins := Vec(-15, -15, -24);
    LBox.Maxs := Vec(15, 15, 32);
    Result.BBoxes[0] := LBox;
    LBox.PresenceType := PRESENCE_CROUCH;
    LBox.Maxs := Vec(15, 15, 8);
    Result.BBoxes[1] := LBox;

    // vertexes: a dummy, then the grid (i, j, k) at (64 i, 64 j, 64 k)
    LVertexes.Add(Vec(0, 0, 0));
    for LX := 0 to LAreas do
      for LY := 0 to 1 do
        for LZ := 0 to 1 do
          LVertexes.Add(Vec(LX * 64, LY * 64, LZ * 64));

    // planes, in pairs: y = 0, y = 64, z = 0, z = 64, x = 64 i (i = 0 .. areas), the skew plane
    AddPair(Vec(0, 1, 0), 0, 1);
    AddPair(Vec(0, 1, 0), 64, 1);
    AddPair(Vec(0, 0, 1), 0, 2);
    AddPair(Vec(0, 0, 1), 64, 2);
    for LX := 0 to LAreas do
      AddPair(Vec(1, 0, 0), LX * 64, 0);
    LRootX := 4 + LAreas + 1;
    // the numbers are exact in every precision
    LNormal := Vec(0.75, 0.5, 0);
    AddPair(LNormal, (LAreas div 2) * 48 + 16, 3);

    // nodes: a dummy, then the walls y and z (outside is a solid leaf), then the areas
    AddNode(0, 0, 0);
    LNodeNum := AddNode(0, 0, 0);
    LNodeY1 := AddNode(2 * 1, 0, 0);
    LNodeZ0 := AddNode(2 * 2, 0, 0);
    LNodeZ1 := AddNode(2 * 3, 0, 0);
    SetChildren(LNodeNum, LNodeY1, 0);
    SetChildren(LNodeY1, 0, LNodeZ0);
    SetChildren(LNodeZ0, LNodeZ1, 0);
    LRoot := BuildX(0, LAreas);
    SetChildren(LNodeZ1, 0, LRoot);

    // faces: a dummy, the faces between the boxes (x), then four per area
    LFaces.Add(Default(TAasFace));
    LEdges.Add(Default(TAasEdge));
    LEdgeIndex.Add(0);
    for LX := 0 to LAreas do
    begin
      LFlags := 0;
      if (LX = 0) or (LX = LAreas) then
        LFlags := FACE_SOLID;
      LFaceNum := 0;
      if LX < LAreas then
        LFaceNum := LX + 1;
      LNeighbor := 0;
      if LX > 0 then
        LNeighbor := LX;
      AddFace(0, LX, 0, 1, 0, 1, 2 * (4 + LX), LFlags, LFaceNum, LNeighbor);
    end;
    for LArea := 1 to LAreas do
    begin
      AddFace(1, 0, 0, 1, LArea - 1, LArea, 0, FACE_SOLID, LArea, 0);
      AddFace(1, 1, 0, 1, LArea - 1, LArea, 2, FACE_SOLID, 0, LArea);
      AddFace(2, 0, LArea - 1, LArea, 0, 1, 4, FACE_SOLID or FACE_GROUND, LArea, 0);
      AddFace(2, 1, LArea - 1, LArea, 0, 1, 6, FACE_SOLID, 0, LArea);
    end;

    // areas: a dummy, then the boxes; the face index has a dummy too
    LFaceIndex.Add(0);
    LAreaList.Add(Default(TAasArea));
    for LArea := 1 to LAreas do
    begin
      LAreaRecord.AreaNum := LArea;
      LAreaRecord.NumFaces := 6;
      LAreaRecord.FirstFace := LFaceIndex.Count;
      LAreaRecord.Mins := Vec((LArea - 1) * 64, 0, 0);
      LAreaRecord.Maxs := Vec(LArea * 64, 64, 64);
      LAreaRecord.Center := Vec(LArea * 64 - 32, 32, 32);
      LAreaList.Add(LAreaRecord);
      // the normal of a face points into the area when its index is positive
      LFaceIndex.Add(LArea - 1 + 1);
      LFaceIndex.Add(-(LArea + 1));
      LFaceIndex.Add(LAreas + 1 + (LArea - 1) * 4 + 1);
      LFaceIndex.Add(-(LAreas + 1 + (LArea - 1) * 4 + 2));
      LFaceIndex.Add(LAreas + 1 + (LArea - 1) * 4 + 3);
      LFaceIndex.Add(-(LAreas + 1 + (LArea - 1) * 4 + 4));
    end;

    // settings, reachabilities (a dummy at index 0), portals and clusters
    LSettings.Add(Default(TAasAreaSettings));
    LReach.Add(Default(TAasReachability));
    LClusterOne := 0;
    LClusterTwo := 0;
    for LArea := 1 to LAreas do
    begin
      case LArea of
        1: begin LContents := 0; LFlags := AREA_GROUNDED; end;
        2: begin LContents := AREACONTENTS_WATER; LFlags := AREA_GROUNDED or AREA_LIQUID; end;
        3: begin LContents := AREACONTENTS_JUMPPAD; LFlags := AREA_GROUNDED or AREA_LADDER; end;
        4: begin LContents := AREACONTENTS_CLUSTERPORTAL; LFlags := AREA_GROUNDED; end;
        5: begin LContents := AREACONTENTS_DONOTENTER; LFlags := AREA_GROUNDED; end;
      else
        begin LContents := AREACONTENTS_TELEPORTER or AREACONTENTS_LAVA; LFlags := AREA_GROUNDED or AREA_BRIDGE; end;
      end;
      LSetting.Contents := LContents;
      LSetting.AreaFlags := LFlags;
      LSetting.PresenceType := PRESENCE_NORMAL or PRESENCE_CROUCH;
      if LArea = 2 then
        LSetting.PresenceType := PRESENCE_CROUCH;
      if (AVariant = 1) and (LArea = 5) then
        LSetting.PresenceType := PRESENCE_NONE;
      if LArea = 4 then
      begin
        LSetting.Cluster := -1;
        LSetting.ClusterAreaNum := 3;
      end
      else if LArea <= 2 then
      begin
        Inc(LClusterOne);
        LSetting.Cluster := 1;
        LSetting.ClusterAreaNum := LClusterOne;
      end
      else
      begin
        Inc(LClusterTwo);
        LSetting.Cluster := 2;
        LSetting.ClusterAreaNum := LClusterTwo;
      end;
      LSetting.FirstReachableArea := LReach.Count;
      LCount := 0;
      for LNeighbor := LArea - 1 to LArea + 1 do
      begin
        if (LNeighbor = LArea) or (LNeighbor < 1) or (LNeighbor > LAreas) then
          Continue;
        // the face between the two boxes: x face number max(area, neighbor) - 1 + 1
        if LNeighbor > LArea then
          LFaceNum := LArea + 1
        else
          LFaceNum := LArea;
        LReachRecord.AreaNum := LNeighbor;
        LReachRecord.FaceNum := LFaceNum;
        LReachRecord.EdgeNum := LEdgeIndex[LFaces[LFaceNum].FirstEdge];
        LReachRecord.StartPoint := Vec(LArea * 64 - 32, 32, 32);
        LReachRecord.EndPoint := Vec(LNeighbor * 64 - 32, 32, 32);
        LReachRecord.TravelType := TRAVEL_WALK;
        LReachRecord.TravelTime := 100 + LArea * 10 + LNeighbor;
        LReachRecord.Padding := 0;
        LReach.Add(LReachRecord);
        Inc(LCount);
      end;
      LSetting.NumReachableAreas := LCount;
      LSettings.Add(LSetting);
    end;
    LPortals.Add(Default(TAasPortal));
    LPortal.AreaNum := 4;
    LPortal.FrontCluster := 1;
    LPortal.BackCluster := 2;
    LPortal.ClusterAreaNum[0] := 3;
    LPortal.ClusterAreaNum[1] := 1;
    LPortals.Add(LPortal);
    LClusters.Add(Default(TAasCluster));
    LCluster.NumAreas := LClusterOne + 1;
    LCluster.NumReachabilityAreas := LClusterOne + 1;
    LCluster.NumPortals := 1;
    LCluster.FirstPortal := 0;
    LClusters.Add(LCluster);
    LCluster.NumAreas := LClusterTwo + 1;
    LCluster.NumReachabilityAreas := LClusterTwo + 1;
    LCluster.FirstPortal := 1;
    LClusters.Add(LCluster);

    Result.Vertexes := LVertexes.ToArray;
    Result.Planes := LPlanes.ToArray;
    Result.Edges := LEdges.ToArray;
    Result.EdgeIndex := LEdgeIndex.ToArray;
    Result.Faces := LFaces.ToArray;
    Result.FaceIndex := LFaceIndex.ToArray;
    Result.Areas := LAreaList.ToArray;
    Result.AreaSettings := LSettings.ToArray;
    Result.Reachability := LReach.ToArray;
    Result.Nodes := LNodes.ToArray;
    Result.Portals := LPortals.ToArray;
    SetLength(Result.PortalIndex, 2);
    Result.PortalIndex[0] := 1;
    Result.PortalIndex[1] := 1;
    Result.Clusters := LClusters.ToArray;
  finally
    LClusters.Free;
    LPortals.Free;
    LReach.Free;
    LSettings.Free;
    LAreaList.Free;
    LVertexes.Free;
    LNodes.Free;
    LFaces.Free;
    LFaceIndex.Free;
    LEdgeIndex.Free;
    LEdges.Free;
    LPlanes.Free;
  end;
end;

class function TAasSample.Layout(const AContent: TAasFileData; const AVersion, AGap: Integer): TBytes;
var
  LFile: IAasFile;
  LHeader: TAasFileHeader;
  LLump: TBytes;
  LIndex, LOffset: Integer;
begin
  LFile := TAasFile.Create(AContent);
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Ident := AAS_ID;
  LHeader.Version := AVersion;
  LHeader.BspChecksum := Integer(SAMPLE_CHECKSUM);
  LOffset := SizeOf(TAasFileHeader);
  SetLength(Result, LOffset);
  for LIndex := 0 to AAS_LUMPS - 1 do
  begin
    LLump := LFile.LumpBytes(LIndex);
    if (AGap > 0) and (LIndex = AASLUMP_FACES) then
    begin
      SetLength(Result, Length(Result) + AGap);
      Inc(LOffset, AGap);
    end;
    LHeader.Lumps[LIndex].FileOffset := LOffset;
    LHeader.Lumps[LIndex].FileLength := Length(LLump);
    SetLength(Result, Length(Result) + Length(LLump));
    if Length(LLump) > 0 then
      Move(LLump[0], Result[LOffset], Length(LLump));
    Inc(LOffset, Length(LLump));
  end;
  if AVersion = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  Move(LHeader, Result[0], SizeOf(TAasFileHeader));
end;

class function TAasSample.Bytes(const AVariant: Integer): TBytes;
var
  LVersion, LGap: Integer;
begin
  LVersion := AAS_VERSION;
  LGap := 0;
  if AVariant = 2 then
    LVersion := AAS_VERSION_OLD;
  if AVariant = 3 then
    LGap := 16;
  if AVariant = 2 then
    Result := Layout(Content(0), LVersion, LGap)
  else if AVariant = 3 then
    Result := Layout(Content(0), LVersion, LGap)
  else
    Result := Layout(Content(AVariant), LVersion, LGap);
end;

end.
