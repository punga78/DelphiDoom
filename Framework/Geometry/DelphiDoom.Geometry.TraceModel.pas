{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the trace model (idTraceModel)               }
{                                                                              }
{  Port of the used part of idTraceModel (TraceModel.h, TraceModel.cpp) of     }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. Doom 3 Source Code: GNU General Public License version 3     }
{  with additional terms. This unit is a derived work (GPL v3).                }
{  Not ported: Rotate, Shrink, Compare, silhouette edges and mass properties   }
{  (nothing in the collision code uses them). Octahedron, dodecahedron and     }
{  cone: issue #236, checked against the real TraceModel.cpp.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.TraceModel;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding;

const
  /// <summary>Bit cache limits of the collision code</summary>
  MAX_TRACEMODEL_VERTS = 32;
  MAX_TRACEMODEL_EDGES = 32;
  MAX_TRACEMODEL_POLYS = 16;
  MAX_TRACEMODEL_POLYEDGES = 16;

type
  TTraceModelKind = (tmkInvalid, tmkBox, tmkOctahedron, tmkDodecahedron, tmkCylinder, tmkCone,
    tmkBone, tmkPolygon, tmkPolygonVolume, tmkCustom);

  /// <summary>An edge of a trace model: two vertex numbers and the normal</summary>
  TTraceModelEdge = record
    V: array[0..1] of Integer;
    Normal: TGeoVec3;
  end;

  /// <summary>
  ///   A polygon: the edges are signed numbers (negative: the edge is walked backwards)
  ///   into the edge array, which starts at 1
  /// </summary>
  TTraceModelPoly = record
    Normal: TGeoVec3;
    Dist: Single;
    Bounds: TGeoBounds;
    NumEdges: Integer;
    Edges: array[0..MAX_TRACEMODEL_POLYEDGES - 1] of Integer;
  end;

  /// <summary>
  ///   A small polygonal model used as the moving volume of a trace. Edge 0 is not used.
  ///   The number of vertices, edges and polygons is limited by the collision code
  /// </summary>
  TTraceModel = class
  public
    Kind: TTraceModelKind;
    NumVerts: Integer;
    Verts: array[0..MAX_TRACEMODEL_VERTS - 1] of TGeoVec3;
    NumEdges: Integer;
    Edges: array[0..MAX_TRACEMODEL_EDGES] of TTraceModelEdge;
    NumPolys: Integer;
    Polys: array[0..MAX_TRACEMODEL_POLYS - 1] of TTraceModelPoly;
    /// <summary>Offset to the center of the model</summary>
    Offset: TGeoVec3;
    Bounds: TGeoBounds;
    IsConvex: Boolean;

    constructor Create; overload;
    constructor CreateBox(const ABounds: TGeoBounds);
    constructor CreateCylinder(const ABounds: TGeoBounds; ANumSides: Integer);

    procedure Assign(ASource: TTraceModel);
    /// <summary>Axial box (idTraceModel::SetupBox)</summary>
    procedure SetupBox(const ABounds: TGeoBounds);
    /// <summary>Cylinder approximation with an axis along Z (idTraceModel::SetupCylinder)</summary>
    procedure SetupCylinder(const ABounds: TGeoBounds; ANumSides: Integer);
    /// <summary>Octahedron in the bounds (idTraceModel::SetupOctahedron and InitOctahedron)</summary>
    procedure SetupOctahedron(const ABounds: TGeoBounds); overload;
    /// <summary>The origin is placed at the center of the octahedron (idTraceModel::SetupOctahedron(size))</summary>
    procedure SetupOctahedron(ASize: Single); overload;
    /// <summary>Dodecahedron in the bounds (idTraceModel::SetupDodecahedron and InitDodecahedron)</summary>
    procedure SetupDodecahedron(const ABounds: TGeoBounds); overload;
    /// <summary>The origin is placed at the center of the dodecahedron</summary>
    procedure SetupDodecahedron(ASize: Single); overload;
    /// <summary>Cone with its axis along Z (idTraceModel::SetupCone; fewer than 2 sides become 3, as in the C++)</summary>
    procedure SetupCone(const ABounds: TGeoBounds; ANumSides: Integer); overload;
    /// <summary>The origin is placed at the apex of the cone (idTraceModel::SetupCone(height, width, sides))</summary>
    procedure SetupCone(AHeight, AWidth: Single; ANumSides: Integer); overload;
    /// <summary>Bone: a small double pyramid with its axis along Z (idTraceModel::SetupBone and InitBone)</summary>
    procedure SetupBone(ALength, AWidth: Single);
    /// <summary>Arbitrary convex polygon, without volume (idTraceModel::SetupPolygon)</summary>
    procedure SetupPolygon(const AVertices: array of TGeoVec3); overload;
    procedure SetupPolygon(AWinding: TGeoWinding); overload;
    /// <summary>Turns the polygon into a volume of the given thickness (idTraceModel::VolumeFromPolygon)</summary>
    procedure VolumeFromPolygon(ADestination: TTraceModel; AThickness: Single);
    /// <summary>Computes the edge normals; returns the number of sharp edges</summary>
    function GenerateEdgeNormals: Integer;
    procedure Translate(const ATranslation: TGeoVec3);
  end;

implementation

uses
  System.Math, DelphiDoom.Geometry.FloatMath;

const
  SHARP_EDGE_DOT: Single = -0.7;
  /// <summary>idMath::TWO_PI as a float</summary>
  TWO_PI_SINGLE: Single = 6.283185307179586;

{ TTraceModel }

constructor TTraceModel.Create;
begin
  inherited Create;
  Kind := tmkInvalid;
  Bounds.Clear;
end;

constructor TTraceModel.CreateBox(const ABounds: TGeoBounds);
begin
  Create;
  SetupBox(ABounds);
end;

constructor TTraceModel.CreateCylinder(const ABounds: TGeoBounds; ANumSides: Integer);
begin
  Create;
  SetupCylinder(ABounds, ANumSides);
end;

procedure TTraceModel.Assign(ASource: TTraceModel);
begin
  Kind := ASource.Kind;
  NumVerts := ASource.NumVerts;
  Verts := ASource.Verts;
  NumEdges := ASource.NumEdges;
  Edges := ASource.Edges;
  NumPolys := ASource.NumPolys;
  Polys := ASource.Polys;
  Offset := ASource.Offset;
  Bounds := ASource.Bounds;
  IsConvex := ASource.IsConvex;
end;

procedure TTraceModel.SetupBox(const ABounds: TGeoBounds);
var
  LIndex: Integer;
  LCorner: array[0..1] of TGeoVec3;

  procedure SetPolyEdges(APoly: Integer; AEdge0, AEdge1, AEdge2, AEdge3: Integer; ANX, ANY, ANZ: Single);
  begin
    Polys[APoly].NumEdges := 4;
    Polys[APoly].Edges[0] := AEdge0;
    Polys[APoly].Edges[1] := AEdge1;
    Polys[APoly].Edges[2] := AEdge2;
    Polys[APoly].Edges[3] := AEdge3;
    Polys[APoly].Normal.SetValues(ANX, ANY, ANZ);
  end;

begin
  if Kind <> tmkBox then
  begin
    // InitBox: the size independent box
    Kind := tmkBox;
    NumVerts := 8;
    NumEdges := 12;
    NumPolys := 6;
    for LIndex := 0 to 3 do
    begin
      Edges[LIndex + 1].V[0] := LIndex;
      Edges[LIndex + 1].V[1] := (LIndex + 1) and 3;
      Edges[LIndex + 5].V[0] := 4 + LIndex;
      Edges[LIndex + 5].V[1] := 4 + ((LIndex + 1) and 3);
      Edges[LIndex + 9].V[0] := LIndex;
      Edges[LIndex + 9].V[1] := 4 + LIndex;
    end;
    // all edges of a polygon go counter clockwise
    SetPolyEdges(0, -4, -3, -2, -1, 0, 0, -1);
    SetPolyEdges(1, 5, 6, 7, 8, 0, 0, 1);
    SetPolyEdges(2, 1, 10, -5, -9, 0, -1, 0);
    SetPolyEdges(3, 2, 11, -6, -10, 1, 0, 0);
    SetPolyEdges(4, 3, 12, -7, -11, 0, 1, 0);
    SetPolyEdges(5, 4, 9, -8, -12, -1, 0, 0);
    IsConvex := True;
    GenerateEdgeNormals;
  end;

  // offset to center
  Offset := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LCorner[0] := ABounds.Mins;
  LCorner[1] := ABounds.Maxs;
  // set box vertices
  for LIndex := 0 to 7 do
  begin
    Verts[LIndex].X := LCorner[(LIndex xor (LIndex shr 1)) and 1].X;
    Verts[LIndex].Y := LCorner[(LIndex shr 1) and 1].Y;
    Verts[LIndex].Z := LCorner[(LIndex shr 2) and 1].Z;
  end;
  // set polygon plane distances
  Polys[0].Dist := -ABounds.Mins.Z;
  Polys[1].Dist := ABounds.Maxs.Z;
  Polys[2].Dist := -ABounds.Mins.Y;
  Polys[3].Dist := ABounds.Maxs.X;
  Polys[4].Dist := ABounds.Maxs.Y;
  Polys[5].Dist := -ABounds.Mins.X;
  // set polygon bounds
  for LIndex := 0 to 5 do
    Polys[LIndex].Bounds := ABounds;
  Polys[0].Bounds.Maxs.Z := ABounds.Mins.Z;
  Polys[1].Bounds.Mins.Z := ABounds.Maxs.Z;
  Polys[2].Bounds.Maxs.Y := ABounds.Mins.Y;
  Polys[3].Bounds.Mins.X := ABounds.Maxs.X;
  Polys[4].Bounds.Mins.Y := ABounds.Maxs.Y;
  Polys[5].Bounds.Maxs.X := ABounds.Mins.X;

  Bounds := ABounds;
end;

procedure TTraceModel.SetupCylinder(const ABounds: TGeoBounds; ANumSides: Integer);
var
  LIndex: Integer;
  LN: Integer;
  LII: Integer;
  LN2: Integer;
  LAngle: Single;
  LHalfSize: TGeoVec3;
begin
  LN := ANumSides;
  if LN < 3 then
    LN := 3;
  if LN * 2 > MAX_TRACEMODEL_VERTS then
    LN := MAX_TRACEMODEL_VERTS div 2;
  if LN * 3 > MAX_TRACEMODEL_EDGES then
    LN := MAX_TRACEMODEL_EDGES div 3;
  if LN + 2 > MAX_TRACEMODEL_POLYS then
    LN := MAX_TRACEMODEL_POLYS - 2;

  Kind := tmkCylinder;
  NumVerts := LN * 2;
  NumEdges := LN * 3;
  NumPolys := LN + 2;
  Offset := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LHalfSize := ABounds.Maxs - Offset;
  for LIndex := 0 to LN - 1 do
  begin
    // verts
    LAngle := 2 * Pi * LIndex / LN;
    Verts[LIndex].X := Cos(Double(LAngle)) * LHalfSize.X + Offset.X;
    Verts[LIndex].Y := Sin(Double(LAngle)) * LHalfSize.Y + Offset.Y;
    Verts[LIndex].Z := -LHalfSize.Z + Offset.Z;
    Verts[LN + LIndex].X := Verts[LIndex].X;
    Verts[LN + LIndex].Y := Verts[LIndex].Y;
    Verts[LN + LIndex].Z := LHalfSize.Z + Offset.Z;
    // edges
    LII := LIndex + 1;
    LN2 := LN shl 1;
    Edges[LII].V[0] := LIndex;
    Edges[LII].V[1] := LII mod LN;
    Edges[LN + LII].V[0] := Edges[LII].V[0] + LN;
    Edges[LN + LII].V[1] := Edges[LII].V[1] + LN;
    Edges[LN2 + LII].V[0] := LIndex;
    Edges[LN2 + LII].V[1] := LN + LIndex;
    // vertical polygon edges
    Polys[LIndex].NumEdges := 4;
    Polys[LIndex].Edges[0] := LII;
    Polys[LIndex].Edges[1] := LN2 + (LII mod LN) + 1;
    Polys[LIndex].Edges[2] := -(LN + LII);
    Polys[LIndex].Edges[3] := -(LN2 + LII);
    // bottom and top polygon edges
    Polys[LN].Edges[LIndex] := -(LN - LIndex);
    Polys[LN + 1].Edges[LIndex] := LN + LII;
  end;
  // bottom and top polygon numEdges
  Polys[LN].NumEdges := LN;
  Polys[LN + 1].NumEdges := LN;
  // polygons
  for LIndex := 0 to LN - 1 do
  begin
    // vertical polygon plane
    Polys[LIndex].Normal := (Verts[(LIndex + 1) mod LN] - Verts[LIndex]).Cross(Verts[LN + LIndex] - Verts[LIndex]);
    Polys[LIndex].Normal.NormalizeSelf;
    Polys[LIndex].Dist := Polys[LIndex].Normal.Dot(Verts[LIndex]);
    // vertical polygon bounds
    Polys[LIndex].Bounds.Clear;
    Polys[LIndex].Bounds.AddPoint(Verts[LIndex]);
    Polys[LIndex].Bounds.AddPoint(Verts[(LIndex + 1) mod LN]);
    Polys[LIndex].Bounds.Mins.Z := -LHalfSize.Z + Offset.Z;
    Polys[LIndex].Bounds.Maxs.Z := LHalfSize.Z + Offset.Z;
  end;
  // bottom and top polygon plane
  Polys[LN].Normal.SetValues(0, 0, -1);
  Polys[LN].Dist := -ABounds.Mins.Z;
  Polys[LN + 1].Normal.SetValues(0, 0, 1);
  Polys[LN + 1].Dist := ABounds.Maxs.Z;
  // trm bounds
  Bounds := ABounds;
  // bottom and top polygon bounds
  Polys[LN].Bounds := Bounds;
  Polys[LN].Bounds.Maxs.Z := Bounds.Mins.Z;
  Polys[LN + 1].Bounds := Bounds;
  Polys[LN + 1].Bounds.Mins.Z := Bounds.Maxs.Z;
  // convex model
  IsConvex := True;

  GenerateEdgeNormals;
end;

procedure TTraceModel.SetupOctahedron(const ABounds: TGeoBounds);
const
  EdgeVerts: array[1..12, 0..1] of Integer = ((4, 0), (0, 2), (2, 4), (2, 1), (1, 4), (1, 3), (3, 4), (3, 0),
    (5, 2), (0, 5), (5, 1), (5, 3));
  PolyEdges: array[0..7, 0..2] of Integer = ((1, 2, 3), (-3, 4, 5), (-5, 6, 7), (-7, 8, -1), (9, -2, 10),
    (11, -4, -9), (12, -6, -11), (-10, -8, -12));
var
  LIndex: Integer;
  LEdge: Integer;
  LE0: Integer;
  LE1: Integer;
  LV0: Integer;
  LV1: Integer;
  LV2: Integer;
  LHalf: TGeoVec3;
begin
  if Kind <> tmkOctahedron then
  begin
    // InitOctahedron
    Kind := tmkOctahedron;
    NumVerts := 6;
    NumEdges := 12;
    NumPolys := 8;
    for LEdge := 1 to 12 do
    begin
      Edges[LEdge].V[0] := EdgeVerts[LEdge, 0];
      Edges[LEdge].V[1] := EdgeVerts[LEdge, 1];
    end;
    // all edges of a polygon go counter clockwise
    for LIndex := 0 to 7 do
    begin
      Polys[LIndex].NumEdges := 3;
      for LEdge := 0 to 2 do
        Polys[LIndex].Edges[LEdge] := PolyEdges[LIndex, LEdge];
    end;
    IsConvex := True;
  end;

  Offset := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LHalf.X := ABounds.Maxs.X - Offset.X;
  LHalf.Y := ABounds.Maxs.Y - Offset.Y;
  LHalf.Z := ABounds.Maxs.Z - Offset.Z;
  // set vertices
  Verts[0].SetValues(Offset.X + LHalf.X, Offset.Y, Offset.Z);
  Verts[1].SetValues(Offset.X - LHalf.X, Offset.Y, Offset.Z);
  Verts[2].SetValues(Offset.X, Offset.Y + LHalf.Y, Offset.Z);
  Verts[3].SetValues(Offset.X, Offset.Y - LHalf.Y, Offset.Z);
  Verts[4].SetValues(Offset.X, Offset.Y, Offset.Z + LHalf.Z);
  Verts[5].SetValues(Offset.X, Offset.Y, Offset.Z - LHalf.Z);
  // set polygons
  for LIndex := 0 to NumPolys - 1 do
  begin
    LE0 := Polys[LIndex].Edges[0];
    LE1 := Polys[LIndex].Edges[1];
    LV0 := Edges[Abs(LE0)].V[Ord(LE0 < 0)];
    LV1 := Edges[Abs(LE0)].V[Ord(LE0 >= 0)];
    LV2 := Edges[Abs(LE1)].V[Ord(LE1 >= 0)];
    // polygon plane
    Polys[LIndex].Normal := (Verts[LV1] - Verts[LV0]).Cross(Verts[LV2] - Verts[LV0]);
    Polys[LIndex].Normal.NormalizeSelf;
    Polys[LIndex].Dist := Polys[LIndex].Normal.Dot(Verts[LV0]);
    // polygon bounds
    Polys[LIndex].Bounds.Mins := Verts[LV0];
    Polys[LIndex].Bounds.Maxs := Verts[LV0];
    Polys[LIndex].Bounds.AddPoint(Verts[LV1]);
    Polys[LIndex].Bounds.AddPoint(Verts[LV2]);
  end;
  // trm bounds
  Bounds := ABounds;

  GenerateEdgeNormals;
end;

procedure TTraceModel.SetupOctahedron(ASize: Single);
var
  LHalfSize: Single;
  LBounds: TGeoBounds;
begin
  LHalfSize := ASize * 0.5;
  LBounds.Mins.SetValues(-LHalfSize, -LHalfSize, -LHalfSize);
  LBounds.Maxs.SetValues(LHalfSize, LHalfSize, LHalfSize);
  SetupOctahedron(LBounds);
end;

procedure TTraceModel.SetupDodecahedron(const ABounds: TGeoBounds);
const
  EdgeVerts: array[1..30, 0..1] of Integer = ((0, 8), (8, 9), (9, 4), (4, 16), (16, 0), (16, 17), (17, 2),
    (2, 12), (12, 0), (2, 10), (10, 3), (3, 13), (13, 12), (9, 5), (5, 15), (15, 14), (14, 4), (3, 19), (19, 18),
    (18, 1), (1, 13), (7, 11), (11, 6), (6, 14), (15, 7), (1, 8), (18, 5), (6, 17), (11, 10), (19, 7));
  PolyEdges: array[0..11, 0..4] of Integer = ((1, 2, 3, 4, 5), (-5, 6, 7, 8, 9), (-8, 10, 11, 12, 13),
    (14, 15, 16, 17, -3), (18, 19, 20, 21, -12), (22, 23, 24, -16, 25), (-9, -13, -21, 26, -1),
    (-26, -20, 27, -14, -2), (-4, -17, -24, 28, -6), (-23, 29, -10, -7, -28), (-25, -15, -27, -19, 30),
    (-30, -18, -11, -29, -22));
var
  LIndex: Integer;
  LEdge: Integer;
  LE: array[0..3] of Integer;
  LV0: Integer;
  LV1: Integer;
  LV2: Integer;
  LV3: Integer;
  LV4: Integer;
  LS: Single;
  LD: Single;
  LA: TGeoVec3;
  LB: TGeoVec3;
  LC: TGeoVec3;
begin
  if Kind <> tmkDodecahedron then
  begin
    // InitDodecahedron
    Kind := tmkDodecahedron;
    NumVerts := 20;
    NumEdges := 30;
    NumPolys := 12;
    for LEdge := 1 to 30 do
    begin
      Edges[LEdge].V[0] := EdgeVerts[LEdge, 0];
      Edges[LEdge].V[1] := EdgeVerts[LEdge, 1];
    end;
    // all edges of a polygon go counter clockwise
    for LIndex := 0 to 11 do
    begin
      Polys[LIndex].NumEdges := 5;
      for LEdge := 0 to 4 do
        Polys[LIndex].Edges[LEdge] := PolyEdges[LIndex, LEdge];
    end;
    IsConvex := True;
  end;

  // 1.0f / ( 3.0f ) ^ 0.5f, ( ( 3.0f - ( 5.0f ) ^ 0.5f ) / 6.0f ) ^ 0.5f, ( ( 3.0f + ( 5.0f ) ^ 0.5f ) / 6.0f ) ^ 0.5f
  LA.SetValues(0.5773502691896257, 0.5773502691896257, 0.5773502691896257);
  LB.SetValues(0.3568220897730899, 0.3568220897730899, 0.3568220897730899);
  LC.SetValues(0.9341723589627156, 0.9341723589627156, 0.9341723589627156);
  LD := 0.5 / LC.X;
  LS := (ABounds.Maxs.X - ABounds.Mins.X) * LD;
  LA.X := LA.X * LS;
  LB.X := LB.X * LS;
  LC.X := LC.X * LS;
  LS := (ABounds.Maxs.Y - ABounds.Mins.Y) * LD;
  LA.Y := LA.Y * LS;
  LB.Y := LB.Y * LS;
  LC.Y := LC.Y * LS;
  LS := (ABounds.Maxs.Z - ABounds.Mins.Z) * LD;
  LA.Z := LA.Z * LS;
  LB.Z := LB.Z * LS;
  LC.Z := LC.Z * LS;

  Offset := (ABounds.Mins + ABounds.Maxs) * 0.5;
  // set vertices
  Verts[0].SetValues(Offset.X + LA.X, Offset.Y + LA.Y, Offset.Z + LA.Z);
  Verts[1].SetValues(Offset.X + LA.X, Offset.Y + LA.Y, Offset.Z - LA.Z);
  Verts[2].SetValues(Offset.X + LA.X, Offset.Y - LA.Y, Offset.Z + LA.Z);
  Verts[3].SetValues(Offset.X + LA.X, Offset.Y - LA.Y, Offset.Z - LA.Z);
  Verts[4].SetValues(Offset.X - LA.X, Offset.Y + LA.Y, Offset.Z + LA.Z);
  Verts[5].SetValues(Offset.X - LA.X, Offset.Y + LA.Y, Offset.Z - LA.Z);
  Verts[6].SetValues(Offset.X - LA.X, Offset.Y - LA.Y, Offset.Z + LA.Z);
  Verts[7].SetValues(Offset.X - LA.X, Offset.Y - LA.Y, Offset.Z - LA.Z);
  Verts[8].SetValues(Offset.X + LB.X, Offset.Y + LC.Y, Offset.Z);
  Verts[9].SetValues(Offset.X - LB.X, Offset.Y + LC.Y, Offset.Z);
  Verts[10].SetValues(Offset.X + LB.X, Offset.Y - LC.Y, Offset.Z);
  Verts[11].SetValues(Offset.X - LB.X, Offset.Y - LC.Y, Offset.Z);
  Verts[12].SetValues(Offset.X + LC.X, Offset.Y, Offset.Z + LB.Z);
  Verts[13].SetValues(Offset.X + LC.X, Offset.Y, Offset.Z - LB.Z);
  Verts[14].SetValues(Offset.X - LC.X, Offset.Y, Offset.Z + LB.Z);
  Verts[15].SetValues(Offset.X - LC.X, Offset.Y, Offset.Z - LB.Z);
  Verts[16].SetValues(Offset.X, Offset.Y + LB.Y, Offset.Z + LC.Z);
  Verts[17].SetValues(Offset.X, Offset.Y - LB.Y, Offset.Z + LC.Z);
  Verts[18].SetValues(Offset.X, Offset.Y + LB.Y, Offset.Z - LC.Z);
  Verts[19].SetValues(Offset.X, Offset.Y - LB.Y, Offset.Z - LC.Z);

  // set polygons
  for LIndex := 0 to NumPolys - 1 do
  begin
    for LEdge := 0 to 3 do
      LE[LEdge] := Polys[LIndex].Edges[LEdge];
    LV0 := Edges[Abs(LE[0])].V[Ord(LE[0] < 0)];
    LV1 := Edges[Abs(LE[0])].V[Ord(LE[0] >= 0)];
    LV2 := Edges[Abs(LE[1])].V[Ord(LE[1] >= 0)];
    LV3 := Edges[Abs(LE[2])].V[Ord(LE[2] >= 0)];
    LV4 := Edges[Abs(LE[3])].V[Ord(LE[3] >= 0)];
    // polygon plane
    Polys[LIndex].Normal := (Verts[LV1] - Verts[LV0]).Cross(Verts[LV2] - Verts[LV0]);
    Polys[LIndex].Normal.NormalizeSelf;
    Polys[LIndex].Dist := Polys[LIndex].Normal.Dot(Verts[LV0]);
    // polygon bounds
    Polys[LIndex].Bounds.Mins := Verts[LV0];
    Polys[LIndex].Bounds.Maxs := Verts[LV0];
    Polys[LIndex].Bounds.AddPoint(Verts[LV1]);
    Polys[LIndex].Bounds.AddPoint(Verts[LV2]);
    Polys[LIndex].Bounds.AddPoint(Verts[LV3]);
    Polys[LIndex].Bounds.AddPoint(Verts[LV4]);
  end;
  // trm bounds
  Bounds := ABounds;

  GenerateEdgeNormals;
end;

procedure TTraceModel.SetupDodecahedron(ASize: Single);
var
  LHalfSize: Single;
  LBounds: TGeoBounds;
begin
  LHalfSize := ASize * 0.5;
  LBounds.Mins.SetValues(-LHalfSize, -LHalfSize, -LHalfSize);
  LBounds.Maxs.SetValues(LHalfSize, LHalfSize, LHalfSize);
  SetupDodecahedron(LBounds);
end;

procedure TTraceModel.SetupCone(const ABounds: TGeoBounds; ANumSides: Integer);
var
  LIndex: Integer;
  LN: Integer;
  LII: Integer;
  LAngle: Single;
  LHalfSize: TGeoVec3;
begin
  LN := ANumSides;
  if LN < 2 then
    LN := 3;
  if LN + 1 > MAX_TRACEMODEL_VERTS then
    LN := MAX_TRACEMODEL_VERTS - 1;
  if LN * 2 > MAX_TRACEMODEL_EDGES then
    LN := MAX_TRACEMODEL_EDGES div 2;
  if LN + 1 > MAX_TRACEMODEL_POLYS then
    LN := MAX_TRACEMODEL_POLYS - 1;

  Kind := tmkCone;
  NumVerts := LN + 1;
  NumEdges := LN * 2;
  NumPolys := LN + 1;
  Offset := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LHalfSize := ABounds.Maxs - Offset;
  Verts[LN].SetValues(0, 0, LHalfSize.Z + Offset.Z);
  for LIndex := 0 to LN - 1 do
  begin
    // verts
    // idMath::TWO_PI * i / n: a float for each operation
    LAngle := TWO_PI_SINGLE;
    LAngle := LAngle * LIndex;
    LAngle := LAngle / LN;
    Verts[LIndex].X := Cos(Double(LAngle)) * LHalfSize.X + Offset.X;
    Verts[LIndex].Y := Sin(Double(LAngle)) * LHalfSize.Y + Offset.Y;
    Verts[LIndex].Z := -LHalfSize.Z + Offset.Z;
    // edges
    LII := LIndex + 1;
    Edges[LII].V[0] := LIndex;
    Edges[LII].V[1] := LII mod LN;
    Edges[LN + LII].V[0] := LIndex;
    Edges[LN + LII].V[1] := LN;
    // vertical polygon edges
    Polys[LIndex].NumEdges := 3;
    Polys[LIndex].Edges[0] := LII;
    Polys[LIndex].Edges[1] := LN + (LII mod LN) + 1;
    Polys[LIndex].Edges[2] := -(LN + LII);
    // bottom polygon edges
    Polys[LN].Edges[LIndex] := -(LN - LIndex);
  end;
  // bottom polygon numEdges
  Polys[LN].NumEdges := LN;

  // polygons
  for LIndex := 0 to LN - 1 do
  begin
    // polygon plane
    Polys[LIndex].Normal := (Verts[(LIndex + 1) mod LN] - Verts[LIndex]).Cross(Verts[LN] - Verts[LIndex]);
    Polys[LIndex].Normal.NormalizeSelf;
    Polys[LIndex].Dist := Polys[LIndex].Normal.Dot(Verts[LIndex]);
    // polygon bounds
    Polys[LIndex].Bounds.Clear;
    Polys[LIndex].Bounds.AddPoint(Verts[LIndex]);
    Polys[LIndex].Bounds.AddPoint(Verts[(LIndex + 1) mod LN]);
    Polys[LIndex].Bounds.AddPoint(Verts[LN]);
  end;
  // bottom polygon plane
  Polys[LN].Normal.SetValues(0, 0, -1);
  Polys[LN].Dist := -ABounds.Mins.Z;
  // trm bounds
  Bounds := ABounds;
  // bottom polygon bounds
  Polys[LN].Bounds := Bounds;
  Polys[LN].Bounds.Maxs.Z := Bounds.Mins.Z;
  // convex model
  IsConvex := True;

  GenerateEdgeNormals;
end;

procedure TTraceModel.SetupCone(AHeight, AWidth: Single; ANumSides: Integer);
var
  LHalfWidth: Single;
  LBounds: TGeoBounds;
begin
  LHalfWidth := AWidth * 0.5;
  LBounds.Mins.SetValues(-LHalfWidth, -LHalfWidth, -AHeight);
  LBounds.Maxs.SetValues(LHalfWidth, LHalfWidth, 0);
  SetupCone(LBounds, ANumSides);
end;

procedure TTraceModel.SetupBone(ALength, AWidth: Single);
var
  LIndex: Integer;
  LJ: Integer;
  LEdgeNum: Integer;
  LHalfLength: Single;
  LBack: Integer;
  procedure SetPoly(APoly, AEdge0, AEdge1, AEdge2: Integer);
  begin
    Polys[APoly].NumEdges := 3;
    Polys[APoly].Edges[0] := AEdge0;
    Polys[APoly].Edges[1] := AEdge1;
    Polys[APoly].Edges[2] := AEdge2;
  end;
begin
  LHalfLength := ALength * 0.5;
  if Kind <> tmkBone then
  begin
    // InitBone: the size independent part
    Kind := tmkBone;
    NumVerts := 5;
    NumEdges := 9;
    NumPolys := 6;
    for LIndex := 0 to 2 do
    begin
      Edges[LIndex + 1].V[0] := 0;
      Edges[LIndex + 1].V[1] := LIndex + 1;
      Edges[LIndex + 4].V[0] := 1 + LIndex;
      Edges[LIndex + 4].V[1] := 1 + ((LIndex + 1) mod 3);
      Edges[LIndex + 7].V[0] := LIndex + 1;
      Edges[LIndex + 7].V[1] := 4;
    end;
    // all edges of a polygon go counter clockwise
    SetPoly(0, 2, -4, -1);
    SetPoly(1, 3, -5, -2);
    SetPoly(2, 1, -6, -3);
    SetPoly(3, 4, 8, -7);
    SetPoly(4, 5, 9, -8);
    SetPoly(5, 6, 7, -9);
    // convex model
    IsConvex := True;
  end;
  // offset to center
  Offset.SetValues(0, 0, 0);
  // set vertices
  Verts[0].SetValues(0, 0, -LHalfLength);
  Verts[1].SetValues(0, AWidth * -0.5, 0);
  Verts[2].SetValues(AWidth * 0.5, AWidth * 0.25, 0);
  Verts[3].SetValues(AWidth * -0.5, AWidth * 0.25, 0);
  Verts[4].SetValues(0, 0, LHalfLength);
  // set bounds
  Bounds.Mins.SetValues(AWidth * -0.5, AWidth * -0.5, -LHalfLength);
  Bounds.Maxs.SetValues(AWidth * 0.5, AWidth * 0.25, LHalfLength);
  // poly plane normals
  Polys[0].Normal := (Verts[2] - Verts[0]).Cross(Verts[1] - Verts[0]);
  Polys[0].Normal.NormalizeSelf;
  Polys[2].Normal.SetValues(-Polys[0].Normal.X, Polys[0].Normal.Y, Polys[0].Normal.Z);
  Polys[3].Normal.SetValues(Polys[0].Normal.X, Polys[0].Normal.Y, -Polys[0].Normal.Z);
  Polys[5].Normal.SetValues(-Polys[0].Normal.X, Polys[0].Normal.Y, -Polys[0].Normal.Z);
  Polys[1].Normal := (Verts[3] - Verts[0]).Cross(Verts[2] - Verts[0]);
  Polys[1].Normal.NormalizeSelf;
  Polys[4].Normal.SetValues(Polys[1].Normal.X, Polys[1].Normal.Y, -Polys[1].Normal.Z);
  // poly plane distances
  for LIndex := 0 to 5 do
  begin
    Polys[LIndex].Dist := Polys[LIndex].Normal.Dot(Verts[Edges[Abs(Polys[LIndex].Edges[0])].V[0]]);
    Polys[LIndex].Bounds.Clear;
    for LJ := 0 to 2 do
    begin
      LEdgeNum := Polys[LIndex].Edges[LJ];
      if LEdgeNum < 0 then
        LBack := 1
      else
        LBack := 0;
      Polys[LIndex].Bounds.AddPoint(Verts[Edges[Abs(LEdgeNum)].V[LBack]]);
    end;
  end;

  GenerateEdgeNormals;
end;

procedure TTraceModel.SetupPolygon(const AVertices: array of TGeoVec3);
var
  LIndex: Integer;
  LNext: Integer;
  LMid: TGeoVec3;
  LCount: Integer;
begin
  LCount := Length(AVertices);
  Kind := tmkPolygon;
  NumVerts := LCount;
  // times three because we need to be able to turn the polygon into a volume
  if NumVerts * 3 > MAX_TRACEMODEL_EDGES then
    NumVerts := MAX_TRACEMODEL_EDGES div 3;

  NumEdges := NumVerts;
  NumPolys := 2;
  // set polygon planes
  Polys[0].NumEdges := NumEdges;
  Polys[0].Normal := (AVertices[1] - AVertices[0]).Cross(AVertices[2] - AVertices[0]);
  Polys[0].Normal.NormalizeSelf;
  Polys[0].Dist := Polys[0].Normal.Dot(AVertices[0]);
  Polys[1].NumEdges := NumEdges;
  Polys[1].Normal := -Polys[0].Normal;
  Polys[1].Dist := -Polys[0].Dist;
  // setup verts, edges and polygons
  Polys[0].Bounds.Clear;
  LMid := TGeoVec3.Origin;
  LNext := 1;
  for LIndex := 0 to NumVerts - 1 do
  begin
    if LNext >= NumVerts then
      LNext := 0;
    Verts[LIndex] := AVertices[LIndex];
    Edges[LIndex + 1].V[0] := LIndex;
    Edges[LIndex + 1].V[1] := LNext;
    Edges[LIndex + 1].Normal := Polys[0].Normal.Cross(AVertices[LIndex] - AVertices[LNext]);
    Edges[LIndex + 1].Normal.NormalizeSelf;
    Polys[0].Edges[LIndex] := LIndex + 1;
    Polys[1].Edges[LIndex] := -(NumVerts - LIndex);
    Polys[0].Bounds.AddPoint(Verts[LIndex]);
    LMid := LMid + AVertices[LIndex];
    Inc(LNext);
  end;
  Polys[1].Bounds := Polys[0].Bounds;
  // offset to center
  Offset := LMid * (1.0 / NumVerts);
  // total bounds
  Bounds := Polys[0].Bounds;
  // considered non convex because the model has no volume
  IsConvex := False;
end;

procedure TTraceModel.SetupPolygon(AWinding: TGeoWinding);
var
  LVertices: TArray<TGeoVec3>;
  LIndex: Integer;
begin
  SetLength(LVertices, AWinding.NumPoints);
  for LIndex := 0 to AWinding.NumPoints - 1 do
    LVertices[LIndex] := AWinding[LIndex];
  SetupPolygon(LVertices);
end;

procedure TTraceModel.VolumeFromPolygon(ADestination: TTraceModel; AThickness: Single);
var
  LIndex: Integer;
begin
  ADestination.Assign(Self);
  ADestination.Kind := tmkPolygonVolume;
  ADestination.NumVerts := NumVerts * 2;
  ADestination.NumEdges := NumEdges * 3;
  ADestination.NumPolys := NumEdges + 2;
  for LIndex := 0 to NumEdges - 1 do
  begin
    ADestination.Verts[NumVerts + LIndex] := Verts[LIndex] - Polys[0].Normal * AThickness;
    ADestination.Edges[NumEdges + LIndex + 1].V[0] := NumVerts + LIndex;
    ADestination.Edges[NumEdges + LIndex + 1].V[1] := NumVerts + (LIndex + 1) mod NumVerts;
    ADestination.Edges[NumEdges * 2 + LIndex + 1].V[0] := LIndex;
    ADestination.Edges[NumEdges * 2 + LIndex + 1].V[1] := NumVerts + LIndex;
    ADestination.Polys[1].Edges[LIndex] := -(NumEdges + LIndex + 1);
    ADestination.Polys[2 + LIndex].NumEdges := 4;
    ADestination.Polys[2 + LIndex].Edges[0] := -(LIndex + 1);
    ADestination.Polys[2 + LIndex].Edges[1] := NumEdges * 2 + LIndex + 1;
    ADestination.Polys[2 + LIndex].Edges[2] := NumEdges + LIndex + 1;
    ADestination.Polys[2 + LIndex].Edges[3] := -(NumEdges * 2 + (LIndex + 1) mod NumEdges + 1);
    ADestination.Polys[2 + LIndex].Normal := (Verts[(LIndex + 1) mod NumVerts] - Verts[LIndex]).Cross(Polys[0].Normal);
    ADestination.Polys[2 + LIndex].Normal.NormalizeSelf;
    ADestination.Polys[2 + LIndex].Dist := ADestination.Polys[2 + LIndex].Normal.Dot(Verts[LIndex]);
  end;
  ADestination.Polys[1].Dist := ADestination.Polys[1].Normal.Dot(ADestination.Verts[NumEdges]);
  ADestination.GenerateEdgeNormals;
end;

function TTraceModel.GenerateEdgeNormals: Integer;
var
  LPolyIndex: Integer;
  LEdgeIndex: Integer;
  LEdgeNum: Integer;
  LEdge: ^TTraceModelEdge;
  LPoly: ^TTraceModelPoly;
  LDot: Single;
  LDir: TGeoVec3;
  LStart: Integer;
  LEnd: Integer;
begin
  for LEdgeIndex := 0 to NumEdges do
    Edges[LEdgeIndex].Normal.Zero;

  Result := 0;
  for LPolyIndex := 0 to NumPolys - 1 do
  begin
    LPoly := @Polys[LPolyIndex];
    for LEdgeIndex := 0 to LPoly.NumEdges - 1 do
    begin
      LEdgeNum := LPoly.Edges[LEdgeIndex];
      LEdge := @Edges[Abs(LEdgeNum)];
      if (LEdge.Normal.X = 0) and (LEdge.Normal.Y = 0) and (LEdge.Normal.Z = 0) then
        LEdge.Normal := LPoly.Normal
      else
      begin
        LDot := LEdge.Normal.Dot(LPoly.Normal);
        // if the two planes make a very sharp edge
        if LDot < SHARP_EDGE_DOT then
        begin
          // max length normal pointing outside both polygons
          if LEdgeNum > 0 then
            LStart := 1
          else
            LStart := 0;
          if LEdgeNum < 0 then
            LEnd := 1
          else
            LEnd := 0;
          LDir := Verts[LEdge.V[LStart]] - Verts[LEdge.V[LEnd]];
          LEdge.Normal := LEdge.Normal.Cross(LDir) + LPoly.Normal.Cross(-LDir);
          LEdge.Normal := LEdge.Normal * ((0.5 / (0.5 + 0.5 * SHARP_EDGE_DOT)) / LEdge.Normal.Length);
          Inc(Result);
        end
        else
          LEdge.Normal := (LEdge.Normal + LPoly.Normal) * (0.5 / (0.5 + 0.5 * LDot));
      end;
    end;
  end;
end;

procedure TTraceModel.Translate(const ATranslation: TGeoVec3);
var
  LIndex: Integer;
begin
  for LIndex := 0 to NumVerts - 1 do
    Verts[LIndex] := Verts[LIndex] + ATranslation;
  for LIndex := 0 to NumPolys - 1 do
  begin
    Polys[LIndex].Dist := Polys[LIndex].Dist + Polys[LIndex].Normal.Dot(ATranslation);
    Polys[LIndex].Bounds.TranslateSelf(ATranslation);
  end;
  Offset := Offset + ATranslation;
  Bounds.TranslateSelf(ATranslation);
end;

end.
