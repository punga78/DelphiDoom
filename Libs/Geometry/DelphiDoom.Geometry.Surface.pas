{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the triangle surface (idSurface)             }
{                                                                              }
{  Port of idSurface (idlib\geometry\Surface.h and Surface.cpp) of the Doom 3  }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Surface;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.DrawVert;

type
  /// <summary>
  ///   An edge of a surface (surfaceEdge_t), 16 bytes: the two vertices with the smaller number
  ///   first and the two triangles that share it (the index of their first corner, -1 when absent)
  /// </summary>
  TGeoSurfaceEdge = record
    Verts: array[0..1] of Integer;
    Tris: array[0..1] of Integer;
  end;

  /// <summary>
  ///   A triangle mesh in which each edge is shared by at most two triangles (idSurface). Edge
  ///   number 0 is a dummy so that an edge index can be negative for a reversed edge. The lists of
  ///   the original (<c>idList</c>) are dynamic arrays whose length is the number of elements.
  /// </summary>
  TGeoSurface = class
  strict protected
    FVerts: TArray<TGeoDrawVert>;
    /// <summary>Three references to vertices for each triangle</summary>
    FIndexes: TArray<Integer>;
    FEdges: TArray<TGeoSurfaceEdge>;
    /// <summary>Three references to edges for each triangle, negative for a reversed edge</summary>
    FEdgeIndexes: TArray<Integer>;
    function GetVertex(AIndex: Integer): TGeoDrawVert;
    procedure SetVertex(AIndex: Integer; const AValue: TGeoDrawVert);
    function GetNumIndexes: Integer;
    function GetNumVertices: Integer;
    function GetIndex(AIndex: Integer): Integer;
    function GetEdgeIndex(AIndex: Integer): Integer;
    function GetNumEdges: Integer;
    function GetEdge(AIndex: Integer): TGeoSurfaceEdge;
    /// <summary>Rebuilds the edges and the edge indexes from the triangle indexes</summary>
    procedure GenerateEdgeIndexes;
    /// <summary>The edge between the two vertices, negative when reversed, 0 when none</summary>
    function FindEdge(AVertex1, AVertex2: Integer): Integer;
  public
    constructor Create; overload;
    /// <summary>A surface with a copy of the vertices and the indexes</summary>
    constructor Create(const AVerts: array of TGeoDrawVert; const AIndexes: array of Integer); overload;
    /// <summary>Copies the arrays of another surface (the copy constructor of the original)</summary>
    procedure Assign(const ASurface: TGeoSurface); virtual;
    function Copy: TGeoSurface;

    property NumVertices: Integer read GetNumVertices;
    property NumIndexes: Integer read GetNumIndexes;
    property NumEdges: Integer read GetNumEdges;
    property Vertices[AIndex: Integer]: TGeoDrawVert read GetVertex write SetVertex; default;
    property Indexes[AIndex: Integer]: Integer read GetIndex;
    property EdgeIndexes[AIndex: Integer]: Integer read GetEdgeIndex;
    property Edges[AIndex: Integer]: TGeoSurfaceEdge read GetEdge;

    /// <summary>Appends another surface (operator+=)</summary>
    procedure Append(const ASurface: TGeoSurface);
    procedure Clear;
    procedure SwapTriangles(const ASurface: TGeoSurface);
    procedure TranslateSelf(const ATranslation: TGeoVec3);
    procedure RotateSelf(const ARotation: TGeoMat3);
    /// <summary>
    ///   Splits into a front and a back surface (new objects owned by the caller; nil when empty);
    ///   this surface is unchanged. The optional arrays receive, ended by -1, the indexes of the
    ///   edges lying on the plane. Returns PLANESIDE_FRONT, _BACK or _CROSS
    /// </summary>
    function Split(const APlane: TGeoPlane; AEpsilon: Single; out AFront, ABack: TGeoSurface;
      AFrontOnPlaneEdges: PInteger = nil; ABackOnPlaneEdges: PInteger = nil): Integer;
    /// <summary>
    ///   Cuts off the part at the back of the plane; true when some part is in front. If nothing
    ///   is in front the surface is cleared
    /// </summary>
    function ClipInPlace(const APlane: TGeoPlane; AEpsilon: Single = 0.1; AKeepOn: Boolean = False): Boolean;
    /// <summary>True when each triangle can be reached from any other one</summary>
    function IsConnected: Boolean;
    function IsClosed: Boolean;
    /// <summary>True when the surface is closed and no vertex is in front of a triangle plane</summary>
    function IsPolytope(AEpsilon: Single = 0.1): Boolean;
    function PlaneDistance(const APlane: TGeoPlane): Single;
    function PlaneSide(const APlane: TGeoPlane; AEpsilon: Single = 0.1): Integer;
    /// <summary>True when the segment meets a triangle (the back face flag is ignored, as in the original)</summary>
    function LineIntersection(const AStart, AEnd: TGeoVec3; ABackFaceCull: Boolean = False): Boolean;
    /// <summary>The intersection point is start + dir * scale; scale is 1e30 when nothing is hit</summary>
    function RayIntersection(const AStart, ADir: TGeoVec3; out AScale: Single; ABackFaceCull: Boolean = False): Boolean;
  end;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath, DelphiDoom.Geometry.Pluecker;

type
  TIntegerPair = array[0..1] of Integer;

const
  SIDE_FRONT = PLANESIDE_FRONT;
  SIDE_BACK = PLANESIDE_BACK;
  SIDE_ON = PLANESIDE_ON;

function SignBit(AValue: Integer): Integer; inline;
begin
  Result := Integer(TGeoMath.IntSignBitSet(AValue));
end;

/// <summary>UpdateVertexIndex of Surface.cpp: the new number of a vertex, assigned on first use</summary>
function UpdateVertexIndex(var AIndexNum: TIntegerPair; const ARemap, ACopyIndex: TArray<Integer>;
  AVertexNumber: Integer): Integer;
var
  LSide: Integer;
begin
  LSide := SignBit(ARemap[AVertexNumber]);
  AIndexNum[0] := ARemap[AVertexNumber];
  ARemap[AVertexNumber] := AIndexNum[LSide];
  Inc(AIndexNum[1], LSide);
  ACopyIndex[ARemap[AVertexNumber]] := AVertexNumber;
  Result := ARemap[AVertexNumber];
end;

procedure PutInteger(var ABuffer: TArray<Integer>; var ACount: Integer; AValue: Integer);
begin
  if ACount >= Length(ABuffer) then
    SetLength(ABuffer, Length(ABuffer) * 2 + 16);
  ABuffer[ACount] := AValue;
  Inc(ACount);
end;

procedure FillMinusOne(var AValues: TArray<Integer>; ACount: Integer);
var
  LIndex: Integer;
begin
  SetLength(AValues, ACount);
  for LIndex := 0 to ACount - 1 do
    AValues[LIndex] := -1;
end;

{ TGeoSurface }

constructor TGeoSurface.Create;
begin
  inherited Create;
end;

constructor TGeoSurface.Create(const AVerts: array of TGeoDrawVert; const AIndexes: array of Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  if (Length(AVerts) = 0) or (Length(AIndexes) = 0) then
    raise EGeometryException.Create('TGeoSurface.Create: vertices and indexes are required');
  if Length(AIndexes) mod 3 <> 0 then
    raise EGeometryException.Create('TGeoSurface.Create: the number of indexes must be a multiple of 3');
  for LIndex := 0 to High(AIndexes) do
    if (AIndexes[LIndex] < 0) or (AIndexes[LIndex] >= Length(AVerts)) then
      raise EGeometryException.Create('TGeoSurface.Create: index out of range');
  SetLength(FVerts, Length(AVerts));
  for LIndex := 0 to High(AVerts) do
    FVerts[LIndex] := AVerts[LIndex];
  SetLength(FIndexes, Length(AIndexes));
  for LIndex := 0 to High(AIndexes) do
    FIndexes[LIndex] := AIndexes[LIndex];
  GenerateEdgeIndexes;
end;

procedure TGeoSurface.Assign(const ASurface: TGeoSurface);
begin
  FVerts := System.Copy(ASurface.FVerts);
  FIndexes := System.Copy(ASurface.FIndexes);
  FEdges := System.Copy(ASurface.FEdges);
  FEdgeIndexes := System.Copy(ASurface.FEdgeIndexes);
end;

function TGeoSurface.Copy: TGeoSurface;
begin
  Result := TGeoSurface.Create;
  Result.Assign(Self);
end;

function TGeoSurface.GetVertex(AIndex: Integer): TGeoDrawVert;
begin
  Result := FVerts[AIndex];
end;

procedure TGeoSurface.SetVertex(AIndex: Integer; const AValue: TGeoDrawVert);
begin
  FVerts[AIndex] := AValue;
end;

function TGeoSurface.GetNumIndexes: Integer;
begin
  Result := Length(FIndexes);
end;

function TGeoSurface.GetNumVertices: Integer;
begin
  Result := Length(FVerts);
end;

function TGeoSurface.GetIndex(AIndex: Integer): Integer;
begin
  Result := FIndexes[AIndex];
end;

function TGeoSurface.GetEdgeIndex(AIndex: Integer): Integer;
begin
  Result := FEdgeIndexes[AIndex];
end;

function TGeoSurface.GetNumEdges: Integer;
begin
  Result := Length(FEdges);
end;

function TGeoSurface.GetEdge(AIndex: Integer): TGeoSurfaceEdge;
begin
  Result := FEdges[AIndex];
end;

procedure TGeoSurface.Append(const ASurface: TGeoSurface);
var
  LIndex, LVertexBase, LIndexBase: Integer;
begin
  LVertexBase := Length(FVerts);
  LIndexBase := Length(FIndexes);
  SetLength(FVerts, LVertexBase + Length(ASurface.FVerts));
  for LIndex := 0 to High(ASurface.FVerts) do
    FVerts[LVertexBase + LIndex] := ASurface.FVerts[LIndex];
  SetLength(FIndexes, LIndexBase + Length(ASurface.FIndexes));
  for LIndex := 0 to High(ASurface.FIndexes) do
    FIndexes[LIndexBase + LIndex] := ASurface.FIndexes[LIndex] + LVertexBase;
  GenerateEdgeIndexes;
end;

procedure TGeoSurface.Clear;
begin
  FVerts := nil;
  FIndexes := nil;
  FEdges := nil;
  FEdgeIndexes := nil;
end;

procedure TGeoSurface.SwapTriangles(const ASurface: TGeoSurface);
var
  LVerts: TArray<TGeoDrawVert>;
  LIntegers: TArray<Integer>;
  LEdges: TArray<TGeoSurfaceEdge>;
begin
  LVerts := FVerts;
  FVerts := ASurface.FVerts;
  ASurface.FVerts := LVerts;
  LIntegers := FIndexes;
  FIndexes := ASurface.FIndexes;
  ASurface.FIndexes := LIntegers;
  LEdges := FEdges;
  FEdges := ASurface.FEdges;
  ASurface.FEdges := LEdges;
  LIntegers := FEdgeIndexes;
  FEdgeIndexes := ASurface.FEdgeIndexes;
  ASurface.FEdgeIndexes := LIntegers;
end;

procedure TGeoSurface.TranslateSelf(const ATranslation: TGeoVec3);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FVerts) do
    FVerts[LIndex].Xyz := FVerts[LIndex].Xyz + ATranslation;
end;

procedure TGeoSurface.RotateSelf(const ARotation: TGeoMat3);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FVerts) do
  begin
    FVerts[LIndex].Xyz := FVerts[LIndex].Xyz * ARotation;
    FVerts[LIndex].Normal := FVerts[LIndex].Normal * ARotation;
    FVerts[LIndex].Tangents[0] := FVerts[LIndex].Tangents[0] * ARotation;
    FVerts[LIndex].Tangents[1] := FVerts[LIndex].Tangents[1] * ARotation;
  end;
end;

procedure TGeoSurface.GenerateEdgeIndexes;
var
  LIndex, LCorner, LI0, LI1, LI2, LSide, LV0, LV1, LEdgeNumber, LEdgeCount: Integer;
  LVertexEdges, LEdgeChain: TArray<Integer>;
  LNewEdges: TArray<TGeoSurfaceEdge>;
  LTriangle: array[0..2] of Integer;
  LEdge: array[0..2] of TGeoSurfaceEdge;
begin
  FillMinusOne(LVertexEdges, Length(FVerts));
  // one more than the original: the last edge number can equal the number of indexes
  SetLength(LEdgeChain, Length(FIndexes) + 1);
  SetLength(FEdgeIndexes, Length(FIndexes));
  SetLength(LNewEdges, Length(FIndexes) + 1);
  // the first edge is a dummy
  LNewEdges[0].Verts[0] := 0;
  LNewEdges[0].Verts[1] := 0;
  LNewEdges[0].Tris[0] := 0;
  LNewEdges[0].Tris[1] := 0;
  LEdgeCount := 1;
  LIndex := 0;
  while LIndex < Length(FIndexes) do
  begin
    LTriangle[0] := FIndexes[LIndex];
    LTriangle[1] := FIndexes[LIndex + 1];
    LTriangle[2] := FIndexes[LIndex + 2];
    LI0 := LTriangle[0];
    LI1 := LTriangle[1];
    LI2 := LTriangle[2];
    // each edge with the smallest vertex number first
    LSide := SignBit(LI1 - LI0);
    LEdge[0].Verts[0] := LTriangle[LSide];
    LEdge[0].Verts[1] := LTriangle[LSide xor 1];
    LSide := SignBit(LI2 - LI1) + 1;
    LEdge[1].Verts[0] := LTriangle[LSide];
    LEdge[1].Verts[1] := LTriangle[LSide xor 3];
    LSide := SignBit(LI2 - LI0) shl 1;
    LEdge[2].Verts[0] := LTriangle[LSide];
    LEdge[2].Verts[1] := LTriangle[LSide xor 2];
    for LCorner := 0 to 2 do
    begin
      LV0 := LEdge[LCorner].Verts[0];
      LV1 := LEdge[LCorner].Verts[1];
      LEdgeNumber := LVertexEdges[LV0];
      while LEdgeNumber >= 0 do
      begin
        if LNewEdges[LEdgeNumber].Verts[1] = LV1 then
          Break;
        LEdgeNumber := LEdgeChain[LEdgeNumber];
      end;
      // the edge does not exist yet
      if LEdgeNumber < 0 then
      begin
        LEdge[LCorner].Tris[0] := -1;
        LEdge[LCorner].Tris[1] := -1;
        LEdgeNumber := LEdgeCount;
        LNewEdges[LEdgeCount] := LEdge[LCorner];
        Inc(LEdgeCount);
        LEdgeChain[LEdgeNumber] := LVertexEdges[LV0];
        LVertexEdges[LV0] := LEdgeNumber;
      end;
      // an edge may not be shared by more than two triangles
      if LTriangle[LCorner] = LV0 then
      begin
        LNewEdges[LEdgeNumber].Tris[0] := LIndex;
        FEdgeIndexes[LIndex + LCorner] := LEdgeNumber;
      end
      else
      begin
        LNewEdges[LEdgeNumber].Tris[1] := LIndex;
        FEdgeIndexes[LIndex + LCorner] := -LEdgeNumber;
      end;
    end;
    Inc(LIndex, 3);
  end;
  SetLength(LNewEdges, LEdgeCount);
  FEdges := LNewEdges;
end;

function TGeoSurface.FindEdge(AVertex1, AVertex2: Integer): Integer;
var
  LIndex, LFirst, LSecond: Integer;
begin
  if AVertex1 < AVertex2 then
  begin
    LFirst := AVertex1;
    LSecond := AVertex2;
  end
  else
  begin
    LFirst := AVertex2;
    LSecond := AVertex1;
  end;
  for LIndex := 1 to High(FEdges) do
  begin
    if (FEdges[LIndex].Verts[0] = LFirst) and (FEdges[LIndex].Verts[1] = LSecond) then
    begin
      if AVertex1 < AVertex2 then
        Exit(LIndex)
      else
        Exit(-LIndex);
    end;
  end;
  Result := 0;
end;

function TGeoSurface.Split(const APlane: TGeoPlane; AEpsilon: Single; out AFront, ABack: TGeoSurface;
  AFrontOnPlaneEdges: PInteger; ABackOnPlaneEdges: PInteger): Integer;
var
  LDists: TArray<Single>;
  LSides: TArray<Byte>;
  LCounts: array[0..2] of Integer;
  LEdgeSplitVertex: TArray<Integer>;
  LEdgeSplitCount: Integer;
  LVertexRemap: array[0..1] of TArray<Integer>;
  LVertexIndexNum: array[0..1] of TIntegerPair;
  LVertexCopyIndex: array[0..1] of TArray<Integer>;
  LIndexBuffer: array[0..1] of TArray<Integer>;
  LIndexNum: array[0..1] of Integer;
  LOnPlaneEdges: array[0..1] of TArray<Integer>;
  LOnPlaneCount: array[0..1] of Integer;
  LSurface: array[0..1] of TGeoSurface;
  LIndex, LV0, LV1, LV2, LE0, LE1, LE2, LS, LSidesOr: Integer;
  LF: Single;
  LVertex: TGeoDrawVert;
  LOnPlaneEdgeCapacity: Integer;

  procedure Emit(ASurface, AValue: Integer);
  begin
    PutInteger(LIndexBuffer[ASurface], LIndexNum[ASurface], AValue);
  end;

  function Update(ASurface, AVertexNumber: Integer): Integer;
  begin
    Result := UpdateVertexIndex(LVertexIndexNum[ASurface], LVertexRemap[ASurface],
      LVertexCopyIndex[ASurface], AVertexNumber);
  end;

  /// <summary>Marks the next index to be written as the start of a triangle on the plane</summary>
  procedure MarkOnPlane(ASurface: Integer);
  begin
    LOnPlaneEdges[ASurface][LOnPlaneCount[ASurface]] := LIndexNum[ASurface];
    Inc(LOnPlaneCount[ASurface]);
  end;

begin
  SetLength(LDists, Length(FVerts));
  SetLength(LSides, Length(FVerts));
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;
  for LIndex := 0 to High(FVerts) do
  begin
    LF := APlane.Distance(FVerts[LIndex].Xyz);
    LDists[LIndex] := LF;
    if LF > AEpsilon then
      LSides[LIndex] := SIDE_FRONT
    else if LF < -AEpsilon then
      LSides[LIndex] := SIDE_BACK
    else
      LSides[LIndex] := SIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  AFront := nil;
  ABack := nil;
  // coplanar: in front when the normals match
  if (LCounts[SIDE_FRONT] = 0) and (LCounts[SIDE_BACK] = 0) then
  begin
    LF := (FVerts[FIndexes[1]].Xyz - FVerts[FIndexes[0]].Xyz).Cross(
      FVerts[FIndexes[0]].Xyz - FVerts[FIndexes[2]].Xyz).Dot(APlane.Normal);
    if TGeoMath.FloatSignBitSet(LF) <> 0 then
    begin
      ABack := Copy;
      Exit(SIDE_BACK);
    end
    else
    begin
      AFront := Copy;
      Exit(SIDE_FRONT);
    end;
  end;
  if LCounts[SIDE_FRONT] = 0 then
  begin
    ABack := Copy;
    Exit(SIDE_BACK);
  end;
  if LCounts[SIDE_BACK] = 0 then
  begin
    AFront := Copy;
    Exit(SIDE_FRONT);
  end;
  LSurface[0] := TGeoSurface.Create;
  LSurface[1] := TGeoSurface.Create;
  AFront := LSurface[0];
  ABack := LSurface[1];
  SetLength(LEdgeSplitVertex, Length(FEdges));
  LEdgeSplitCount := 0;
  LOnPlaneEdgeCapacity := Length(FIndexes) + 8;
  LCounts[SIDE_FRONT] := 0;
  LCounts[SIDE_BACK] := 0;
  LCounts[SIDE_ON] := 0;
  // split edges
  for LIndex := 0 to High(FEdges) do
  begin
    LV0 := FEdges[LIndex].Verts[0];
    LV1 := FEdges[LIndex].Verts[1];
    LSidesOr := LSides[LV0] or LSides[LV1];
    // both vertices on the same side or one on the clipping plane
    if ((LSides[LV0] xor LSides[LV1]) = 0) or ((LSidesOr and SIDE_ON) <> 0) then
    begin
      LEdgeSplitVertex[LIndex] := -1;
      Inc(LCounts[LSidesOr and SIDE_BACK]);
      Inc(LCounts[SIDE_ON], (LSidesOr and SIDE_ON) shr 1);
    end
    else
    begin
      LF := LDists[LV0] / (LDists[LV0] - LDists[LV1]);
      LVertex.LerpAll(FVerts[LV0], FVerts[LV1], LF);
      LEdgeSplitVertex[LIndex] := LEdgeSplitCount;
      Inc(LEdgeSplitCount);
      SetLength(LSurface[0].FVerts, LEdgeSplitCount);
      LSurface[0].FVerts[LEdgeSplitCount - 1] := LVertex;
      SetLength(LSurface[1].FVerts, LEdgeSplitCount);
      LSurface[1].FVerts[LEdgeSplitCount - 1] := LVertex;
    end;
  end;
  for LS := 0 to 1 do
  begin
    SetLength(LVertexRemap[LS], Length(FVerts));
    FillMinusOne(LVertexRemap[LS], Length(FVerts));
    SetLength(LVertexCopyIndex[LS], LEdgeSplitCount + Length(FVerts));
    LVertexIndexNum[LS][0] := 0;
    LVertexIndexNum[LS][1] := LEdgeSplitCount;
    SetLength(LIndexBuffer[LS], (LCounts[LS] + LCounts[SIDE_ON]) * 2 + LEdgeSplitCount * 4 + 16);
    LIndexNum[LS] := 0;
    SetLength(LOnPlaneEdges[LS], LOnPlaneEdgeCapacity + 4 * LEdgeSplitCount + 4);
    LOnPlaneCount[LS] := 0;
  end;
  // split triangles
  LIndex := 0;
  while LIndex < Length(FEdgeIndexes) do
  begin
    LE0 := Abs(FEdgeIndexes[LIndex]);
    LE1 := Abs(FEdgeIndexes[LIndex + 1]);
    LE2 := Abs(FEdgeIndexes[LIndex + 2]);
    LV0 := FIndexes[LIndex];
    LV1 := FIndexes[LIndex + 1];
    LV2 := FIndexes[LIndex + 2];
    case (SignBit(LEdgeSplitVertex[LE0]) or (SignBit(LEdgeSplitVertex[LE1]) shl 1) or
      (SignBit(LEdgeSplitVertex[LE2]) shl 2)) xor 7 of
      0: // no edges split
        begin
          if ((LSides[LV0] and LSides[LV1] and LSides[LV2]) and SIDE_ON) <> 0 then
          begin
            LF := (FVerts[LV1].Xyz - FVerts[LV0].Xyz).Cross(FVerts[LV0].Xyz - FVerts[LV2].Xyz).Dot(APlane.Normal);
            LS := Integer(TGeoMath.FloatSignBitSet(LF));
          end
          else
            LS := (LSides[LV0] or LSides[LV1] or LSides[LV2]) and SIDE_BACK;
          // the three candidates are written, only the counted ones are kept
          LOnPlaneEdges[LS][LOnPlaneCount[LS]] := LIndexNum[LS];
          Inc(LOnPlaneCount[LS], (LSides[LV0] and LSides[LV1]) shr 1);
          LOnPlaneEdges[LS][LOnPlaneCount[LS]] := LIndexNum[LS] + 1;
          Inc(LOnPlaneCount[LS], (LSides[LV1] and LSides[LV2]) shr 1);
          LOnPlaneEdges[LS][LOnPlaneCount[LS]] := LIndexNum[LS] + 2;
          Inc(LOnPlaneCount[LS], (LSides[LV2] and LSides[LV0]) shr 1);
          Emit(LS, Update(LS, LV0));
          Emit(LS, Update(LS, LV1));
          Emit(LS, Update(LS, LV2));
        end;
      1: // first edge split
        begin
          LS := LSides[LV0] and SIDE_BACK;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE0]);
          Emit(LS, Update(LS, LV2));
          Emit(LS, Update(LS, LV0));
          LS := LS xor 1;
          MarkOnPlane(LS);
          Emit(LS, Update(LS, LV2));
          Emit(LS, LEdgeSplitVertex[LE0]);
          Emit(LS, Update(LS, LV1));
        end;
      2: // second edge split
        begin
          LS := LSides[LV1] and SIDE_BACK;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, Update(LS, LV0));
          Emit(LS, Update(LS, LV1));
          LS := LS xor 1;
          MarkOnPlane(LS);
          Emit(LS, Update(LS, LV0));
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, Update(LS, LV2));
        end;
      3: // first and second edge split
        begin
          LS := LSides[LV1] and SIDE_BACK;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, LEdgeSplitVertex[LE0]);
          Emit(LS, Update(LS, LV1));
          LS := LS xor 1;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE0]);
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, Update(LS, LV0));
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, Update(LS, LV2));
          Emit(LS, Update(LS, LV0));
        end;
      4: // third edge split
        begin
          LS := LSides[LV2] and SIDE_BACK;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE2]);
          Emit(LS, Update(LS, LV1));
          Emit(LS, Update(LS, LV2));
          LS := LS xor 1;
          MarkOnPlane(LS);
          Emit(LS, Update(LS, LV1));
          Emit(LS, LEdgeSplitVertex[LE2]);
          Emit(LS, Update(LS, LV0));
        end;
      5: // first and third edge split
        begin
          LS := LSides[LV0] and SIDE_BACK;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE0]);
          Emit(LS, LEdgeSplitVertex[LE2]);
          Emit(LS, Update(LS, LV0));
          LS := LS xor 1;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE2]);
          Emit(LS, LEdgeSplitVertex[LE0]);
          Emit(LS, Update(LS, LV1));
          Emit(LS, Update(LS, LV1));
          Emit(LS, Update(LS, LV2));
          Emit(LS, LEdgeSplitVertex[LE2]);
        end;
      6: // second and third edge split
        begin
          LS := LSides[LV2] and SIDE_BACK;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE2]);
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, Update(LS, LV2));
          LS := LS xor 1;
          MarkOnPlane(LS);
          Emit(LS, LEdgeSplitVertex[LE1]);
          Emit(LS, LEdgeSplitVertex[LE2]);
          Emit(LS, Update(LS, LV1));
          Emit(LS, Update(LS, LV0));
          Emit(LS, Update(LS, LV1));
          Emit(LS, LEdgeSplitVertex[LE2]);
        end;
    end;
    Inc(LIndex, 3);
  end;
  for LS := 0 to 1 do
  begin
    SetLength(LIndexBuffer[LS], LIndexNum[LS]);
    LSurface[LS].FIndexes := LIndexBuffer[LS];
    // the vertices of the cut edges are already in place, the others are copied
    SetLength(LSurface[LS].FVerts, LVertexIndexNum[LS][1]);
    for LIndex := LEdgeSplitCount to High(LSurface[LS].FVerts) do
      LSurface[LS].FVerts[LIndex] := FVerts[LVertexCopyIndex[LS][LIndex]];
    LSurface[LS].GenerateEdgeIndexes;
  end;
  if Assigned(AFrontOnPlaneEdges) then
  begin
    for LIndex := 0 to LOnPlaneCount[0] - 1 do
      PInteger(NativeInt(AFrontOnPlaneEdges) + LIndex * SizeOf(Integer))^ := LOnPlaneEdges[0][LIndex];
    PInteger(NativeInt(AFrontOnPlaneEdges) + LOnPlaneCount[0] * SizeOf(Integer))^ := -1;
  end;
  if Assigned(ABackOnPlaneEdges) then
  begin
    for LIndex := 0 to LOnPlaneCount[1] - 1 do
      PInteger(NativeInt(ABackOnPlaneEdges) + LIndex * SizeOf(Integer))^ := LOnPlaneEdges[1][LIndex];
    PInteger(NativeInt(ABackOnPlaneEdges) + LOnPlaneCount[1] * SizeOf(Integer))^ := -1;
  end;
  Result := PLANESIDE_CROSS;
end;

function TGeoSurface.ClipInPlace(const APlane: TGeoPlane; AEpsilon: Single; AKeepOn: Boolean): Boolean;
var
  LDists: TArray<Single>;
  LSides: TArray<Byte>;
  LCounts: array[0..2] of Integer;
  LEdgeSplitVertex, LVertexRemap, LVertexCopyIndex, LNewIndexes: TArray<Integer>;
  LVertexIndexNum: TIntegerPair;
  LNewVerts: TArray<TGeoDrawVert>;
  LIndexNum, LEdgeSplitCount, LIndex, LV0, LV1, LV2, LE0, LE1, LE2: Integer;
  LF: Single;
  LVertex: TGeoDrawVert;

  procedure Emit(AValue: Integer);
  begin
    PutInteger(LNewIndexes, LIndexNum, AValue);
  end;

  function Update(AVertexNumber: Integer): Integer;
  begin
    Result := UpdateVertexIndex(LVertexIndexNum, LVertexRemap, LVertexCopyIndex, AVertexNumber);
  end;

begin
  SetLength(LDists, Length(FVerts));
  SetLength(LSides, Length(FVerts));
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;
  for LIndex := 0 to High(FVerts) do
  begin
    LF := APlane.Distance(FVerts[LIndex].Xyz);
    LDists[LIndex] := LF;
    if LF > AEpsilon then
      LSides[LIndex] := SIDE_FRONT
    else if LF < -AEpsilon then
      LSides[LIndex] := SIDE_BACK
    else
      LSides[LIndex] := SIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  if (LCounts[SIDE_FRONT] = 0) and (LCounts[SIDE_BACK] = 0) then
  begin
    LF := (FVerts[FIndexes[1]].Xyz - FVerts[FIndexes[0]].Xyz).Cross(
      FVerts[FIndexes[0]].Xyz - FVerts[FIndexes[2]].Xyz).Dot(APlane.Normal);
    if TGeoMath.FloatSignBitSet(LF) <> 0 then
    begin
      Clear;
      Exit(False);
    end;
    Exit(True);
  end;
  if LCounts[SIDE_FRONT] = 0 then
  begin
    Clear;
    Exit(False);
  end;
  if LCounts[SIDE_BACK] = 0 then
    Exit(True);
  SetLength(LEdgeSplitVertex, Length(FEdges));
  LEdgeSplitCount := 0;
  LCounts[SIDE_FRONT] := 0;
  LCounts[SIDE_BACK] := 0;
  for LIndex := 0 to High(FEdges) do
  begin
    LV0 := FEdges[LIndex].Verts[0];
    LV1 := FEdges[LIndex].Verts[1];
    if ((LSides[LV0] xor LSides[LV1]) = 0) or (((LSides[LV0] or LSides[LV1]) and SIDE_ON) <> 0) then
    begin
      LEdgeSplitVertex[LIndex] := -1;
      Inc(LCounts[(LSides[LV0] or LSides[LV1]) and SIDE_BACK]);
    end
    else
    begin
      LF := LDists[LV0] / (LDists[LV0] - LDists[LV1]);
      LVertex.LerpAll(FVerts[LV0], FVerts[LV1], LF);
      LEdgeSplitVertex[LIndex] := LEdgeSplitCount;
      Inc(LEdgeSplitCount);
      SetLength(LNewVerts, LEdgeSplitCount);
      LNewVerts[LEdgeSplitCount - 1] := LVertex;
    end;
  end;
  SetLength(LNewIndexes, (LCounts[SIDE_FRONT] shl 1) + (LEdgeSplitCount shl 2) + 16);
  LIndexNum := 0;
  FillMinusOne(LVertexRemap, Length(FVerts));
  SetLength(LVertexCopyIndex, LEdgeSplitCount + Length(FVerts));
  LVertexIndexNum[0] := 0;
  LVertexIndexNum[1] := LEdgeSplitCount;
  LIndex := 0;
  while LIndex < Length(FEdgeIndexes) do
  begin
    LE0 := Abs(FEdgeIndexes[LIndex]);
    LE1 := Abs(FEdgeIndexes[LIndex + 1]);
    LE2 := Abs(FEdgeIndexes[LIndex + 2]);
    LV0 := FIndexes[LIndex];
    LV1 := FIndexes[LIndex + 1];
    LV2 := FIndexes[LIndex + 2];
    case (SignBit(LEdgeSplitVertex[LE0]) or (SignBit(LEdgeSplitVertex[LE1]) shl 1) or
      (SignBit(LEdgeSplitVertex[LE2]) shl 2)) xor 7 of
      0: // no edges split
        begin
          if ((LSides[LV0] or LSides[LV1] or LSides[LV2]) and SIDE_BACK) = 0 then
          begin
            if ((LSides[LV0] and LSides[LV1] and LSides[LV2]) and SIDE_ON) <> 0 then
            begin
              // coplanar
              if AKeepOn then
              begin
                LF := (FVerts[LV1].Xyz - FVerts[LV0].Xyz).Cross(
                  FVerts[LV0].Xyz - FVerts[LV2].Xyz).Dot(APlane.Normal);
                if TGeoMath.FloatSignBitSet(LF) = 0 then
                begin
                  Emit(Update(LV0));
                  Emit(Update(LV1));
                  Emit(Update(LV2));
                end;
              end;
            end
            else
            begin
              Emit(Update(LV0));
              Emit(Update(LV1));
              Emit(Update(LV2));
            end;
          end;
        end;
      1: // first edge split
        if (LSides[LV0] and SIDE_BACK) = 0 then
        begin
          Emit(Update(LV0));
          Emit(LEdgeSplitVertex[LE0]);
          Emit(Update(LV2));
        end
        else
        begin
          Emit(LEdgeSplitVertex[LE0]);
          Emit(Update(LV1));
          Emit(Update(LV2));
        end;
      2: // second edge split
        if (LSides[LV1] and SIDE_BACK) = 0 then
        begin
          Emit(Update(LV1));
          Emit(LEdgeSplitVertex[LE1]);
          Emit(Update(LV0));
        end
        else
        begin
          Emit(LEdgeSplitVertex[LE1]);
          Emit(Update(LV2));
          Emit(Update(LV0));
        end;
      3: // first and second edge split
        if (LSides[LV1] and SIDE_BACK) = 0 then
        begin
          Emit(Update(LV1));
          Emit(LEdgeSplitVertex[LE1]);
          Emit(LEdgeSplitVertex[LE0]);
        end
        else
        begin
          Emit(Update(LV0));
          Emit(LEdgeSplitVertex[LE0]);
          Emit(LEdgeSplitVertex[LE1]);
          Emit(LEdgeSplitVertex[LE1]);
          Emit(Update(LV2));
          Emit(Update(LV0));
        end;
      4: // third edge split
        if (LSides[LV2] and SIDE_BACK) = 0 then
        begin
          Emit(Update(LV2));
          Emit(LEdgeSplitVertex[LE2]);
          Emit(Update(LV1));
        end
        else
        begin
          Emit(LEdgeSplitVertex[LE2]);
          Emit(Update(LV0));
          Emit(Update(LV1));
        end;
      5: // first and third edge split
        if (LSides[LV0] and SIDE_BACK) = 0 then
        begin
          Emit(Update(LV0));
          Emit(LEdgeSplitVertex[LE0]);
          Emit(LEdgeSplitVertex[LE2]);
        end
        else
        begin
          Emit(LEdgeSplitVertex[LE0]);
          Emit(Update(LV1));
          Emit(LEdgeSplitVertex[LE2]);
          Emit(Update(LV1));
          Emit(Update(LV2));
          Emit(LEdgeSplitVertex[LE2]);
        end;
      6: // second and third edge split
        if (LSides[LV2] and SIDE_BACK) = 0 then
        begin
          Emit(Update(LV2));
          Emit(LEdgeSplitVertex[LE2]);
          Emit(LEdgeSplitVertex[LE1]);
        end
        else
        begin
          Emit(LEdgeSplitVertex[LE2]);
          Emit(Update(LV1));
          Emit(LEdgeSplitVertex[LE1]);
          Emit(Update(LV0));
          Emit(Update(LV1));
          Emit(LEdgeSplitVertex[LE2]);
        end;
    end;
    Inc(LIndex, 3);
  end;
  SetLength(LNewIndexes, LIndexNum);
  SetLength(LNewVerts, LVertexIndexNum[1]);
  for LIndex := LEdgeSplitCount to High(LNewVerts) do
    LNewVerts[LIndex] := FVerts[LVertexCopyIndex[LIndex]];
  FIndexes := LNewIndexes;
  FVerts := LNewVerts;
  GenerateEdgeIndexes;
  Result := True;
end;

function TGeoSurface.IsConnected: Boolean;
var
  LIndex, LCorner, LIslandCount, LTriangleCount, LQueueStart, LQueueEnd, LCurrent, LNext, LEdgeNumber: Integer;
  LQueue, LIslandNumber: TArray<Integer>;
begin
  LIslandCount := 0;
  LTriangleCount := Length(FIndexes) div 3;
  FillMinusOne(LIslandNumber, LTriangleCount);
  SetLength(LQueue, LTriangleCount + 1);
  for LIndex := 0 to LTriangleCount - 1 do
  begin
    if LIslandNumber[LIndex] <> -1 then
      Continue;
    LQueueStart := 0;
    LQueueEnd := 1;
    LQueue[0] := LIndex;
    LIslandNumber[LIndex] := LIslandCount;
    while LQueueStart < LQueueEnd do
    begin
      LCurrent := LQueue[LQueueStart];
      for LCorner := 0 to 2 do
      begin
        LEdgeNumber := FEdgeIndexes[LCurrent * 3 + LCorner];
        LNext := FEdges[Abs(LEdgeNumber)].Tris[Integer(TGeoMath.IntSignBitNotSet(LEdgeNumber))];
        if LNext = -1 then
          Continue;
        LNext := LNext div 3;
        if LIslandNumber[LNext] <> -1 then
          Continue;
        LQueue[LQueueEnd] := LNext;
        Inc(LQueueEnd);
        LIslandNumber[LNext] := LIslandCount;
      end;
      Inc(LQueueStart);
    end;
    Inc(LIslandCount);
  end;
  Result := LIslandCount = 1;
end;

function TGeoSurface.IsClosed: Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FEdges) do
    if (FEdges[LIndex].Tris[0] < 0) or (FEdges[LIndex].Tris[1] < 0) then
      Exit(False);
  Result := True;
end;

function TGeoSurface.IsPolytope(AEpsilon: Single): Boolean;
var
  LIndex, LVertex: Integer;
  LPlane: TGeoPlane;
begin
  if not IsClosed then
    Exit(False);
  LIndex := 0;
  while LIndex < Length(FIndexes) do
  begin
    LPlane.FromPoints(FVerts[FIndexes[LIndex]].Xyz, FVerts[FIndexes[LIndex + 1]].Xyz,
      FVerts[FIndexes[LIndex + 2]].Xyz);
    for LVertex := 0 to High(FVerts) do
      if LPlane.Side(FVerts[LVertex].Xyz, AEpsilon) = PLANESIDE_FRONT then
        Exit(False);
    Inc(LIndex, 3);
  end;
  Result := True;
end;

function TGeoSurface.PlaneDistance(const APlane: TGeoPlane): Single;
var
  LIndex: Integer;
  LDistance, LMin, LMax: Single;
begin
  LMin := GEO_INFINITY;
  LMax := -LMin;
  for LIndex := 0 to High(FVerts) do
  begin
    LDistance := APlane.Distance(FVerts[LIndex].Xyz);
    if LDistance < LMin then
    begin
      LMin := LDistance;
      if (TGeoMath.FloatSignBitSet(LMin) and TGeoMath.FloatSignBitNotSet(LMax)) <> 0 then
        Exit(0);
    end;
    if LDistance > LMax then
    begin
      LMax := LDistance;
      if (TGeoMath.FloatSignBitSet(LMin) and TGeoMath.FloatSignBitNotSet(LMax)) <> 0 then
        Exit(0);
    end;
  end;
  if TGeoMath.FloatSignBitNotSet(LMin) <> 0 then
    Exit(LMin);
  if TGeoMath.FloatSignBitSet(LMax) <> 0 then
    Exit(LMax);
  Result := 0;
end;

function TGeoSurface.PlaneSide(const APlane: TGeoPlane; AEpsilon: Single): Integer;
var
  LIndex: Integer;
  LDistance: Single;
  LFront, LBack: Boolean;
begin
  LFront := False;
  LBack := False;
  for LIndex := 0 to High(FVerts) do
  begin
    LDistance := APlane.Distance(FVerts[LIndex].Xyz);
    if LDistance < -AEpsilon then
    begin
      if LFront then
        Exit(PLANESIDE_CROSS);
      LBack := True;
    end
    else if LDistance > AEpsilon then
    begin
      if LBack then
        Exit(PLANESIDE_CROSS);
      LFront := True;
    end;
  end;
  if LBack then
    Exit(PLANESIDE_BACK);
  if LFront then
    Exit(PLANESIDE_FRONT);
  Result := PLANESIDE_ON;
end;

function TGeoSurface.LineIntersection(const AStart, AEnd: TGeoVec3; ABackFaceCull: Boolean): Boolean;
var
  LScale: Single;
begin
  RayIntersection(AStart, AEnd - AStart, LScale, False);
  Result := (LScale >= 0) and (LScale <= 1);
end;

function TGeoSurface.RayIntersection(const AStart, ADir: TGeoVec3; out AScale: Single;
  ABackFaceCull: Boolean): Boolean;
var
  LIndex, LI0, LI1, LI2, LS0, LS1, LS2: Integer;
  LDistance, LS, LTemp: Single;
  LSidedness: TArray<Byte>;
  LRay, LLine: TGeoPluecker;
  LPlane: TGeoPlane;
begin
  SetLength(LSidedness, Length(FEdges));
  AScale := GEO_INFINITY;
  LS := 0;
  LRay.FromRay(AStart, ADir);
  // sidedness of the ray for every edge
  for LIndex := 0 to High(FEdges) do
  begin
    LLine.FromLine(FVerts[FEdges[LIndex].Verts[1]].Xyz, FVerts[FEdges[LIndex].Verts[0]].Xyz);
    LDistance := LLine.PermutedInnerProduct(LRay);
    LSidedness[LIndex] := Byte(TGeoMath.FloatSignBitSet(LDistance));
  end;
  LIndex := 0;
  while LIndex < Length(FEdgeIndexes) do
  begin
    LI0 := FEdgeIndexes[LIndex];
    LI1 := FEdgeIndexes[LIndex + 1];
    LI2 := FEdgeIndexes[LIndex + 2];
    LS0 := LSidedness[Abs(LI0)] xor SignBit(LI0);
    LS1 := LSidedness[Abs(LI1)] xor SignBit(LI1);
    LS2 := LSidedness[Abs(LI2)] xor SignBit(LI2);
    if (LS0 and LS1 and LS2) <> 0 then
    begin
      LPlane.FromPoints(FVerts[FIndexes[LIndex]].Xyz, FVerts[FIndexes[LIndex + 1]].Xyz,
        FVerts[FIndexes[LIndex + 2]].Xyz);
      // a parallel plane leaves the previous value, as the uninitialised variable of the original
      if LPlane.RayIntersection(AStart, ADir, LTemp) then
        LS := LTemp;
      if TGeoMath.Fabs(LS) < TGeoMath.Fabs(AScale) then
        AScale := LS;
    end
    else if (not ABackFaceCull) and ((LS0 or LS1 or LS2) = 0) then
    begin
      LPlane.FromPoints(FVerts[FIndexes[LIndex]].Xyz, FVerts[FIndexes[LIndex + 1]].Xyz,
        FVerts[FIndexes[LIndex + 2]].Xyz);
      if LPlane.RayIntersection(AStart, ADir, LTemp) then
        LS := LTemp;
      if TGeoMath.Fabs(LS) < TGeoMath.Fabs(AScale) then
        AScale := LS;
    end;
    Inc(LIndex, 3);
  end;
  Result := TGeoMath.Fabs(AScale) < GEO_INFINITY;
end;

end.
