{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the geometry library - winding and trace model         }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Winding;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('geometry')]
  TTestGeometryWinding = class(TObject)
  public
    [Test]
    procedure TestBaseForPlaneLiesOnThePlane;
    [Test]
    procedure TestBaseForPlaneIsHuge;
    [Test]
    procedure TestClipKeepsTheFrontPart;
    [Test]
    procedure TestClipOfAWindingBehindTheEmptiesIt;
    [Test]
    procedure TestClipOfAWindingInFrontKeepsIt;
    [Test]
    procedure TestClipKeepOn;
    [Test]
    procedure TestClipAxialPlaneIsExact;
    [Test]
    procedure TestReverseSelf;
    [Test]
    procedure TestBounds;
    [Test]
    procedure TestBoxTraceModel;
    [Test]
    procedure TestBoxTraceModelEdgesAreWalkedConsistently;
    [Test]
    procedure TestBoxTraceModelNormalsAndDistances;
    [Test]
    procedure TestBoxTraceModelOffsetAndBounds;
    [Test]
    procedure TestCylinderTraceModel;
    [Test]
    procedure TestPolygonTraceModelAndVolume;
    [Test]
    procedure TestTraceModelTranslate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.Tests.Collision.Support;

const
  EPS = 1e-4;

{ TTestGeometryWinding }

procedure TTestGeometryWinding.TestBaseForPlaneLiesOnThePlane;
var
  LWinding: TGeoWinding;
  LPlane: TGeoPlane;
  LIndex: Integer;
begin
  LPlane := TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 12);
  LWinding := TGeoWinding.CreateForPlane(LPlane);
  try
    Assert.AreEqual(4, LWinding.NumPoints);
    for LIndex := 0 to 3 do
      Assert.AreEqual(0.0, LPlane.Distance(LWinding[LIndex]), 1e-3);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestBaseForPlaneIsHuge;
var
  LWinding: TGeoWinding;
begin
  LWinding := TGeoWinding.CreateForPlane(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 0));
  try
    // the base is as large as the world: IsHuge is the test that rejects it
    Assert.IsTrue(LWinding.IsHuge);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestClipKeepsTheFrontPart;
var
  LWinding: TGeoWinding;
  LBounds: TGeoBounds;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 0, 0),
    TGeoVec3.Make(10, 10, 0), TGeoVec3.Make(0, 10, 0)]);
  try
    // keep x > 4
    Assert.IsTrue(LWinding.ClipInPlace(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 4), 0));
    Assert.AreEqual(4, LWinding.NumPoints);
    LBounds := LWinding.GetBounds;
    Assert.AreEqual(4.0, LBounds.Mins.X, EPS);
    Assert.AreEqual(10.0, LBounds.Maxs.X, EPS);
    Assert.AreEqual(0.0, LBounds.Mins.Y, EPS);
    Assert.AreEqual(10.0, LBounds.Maxs.Y, EPS);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestClipOfAWindingBehindTheEmptiesIt;
var
  LWinding: TGeoWinding;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 0, 0), TGeoVec3.Make(10, 10, 0)]);
  try
    Assert.IsFalse(LWinding.ClipInPlace(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 20), 0));
    Assert.AreEqual(0, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestClipOfAWindingInFrontKeepsIt;
var
  LWinding: TGeoWinding;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 0, 0), TGeoVec3.Make(10, 10, 0)]);
  try
    Assert.IsTrue(LWinding.ClipInPlace(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), -5), 0));
    Assert.AreEqual(3, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestClipKeepOn;
var
  LWinding: TGeoWinding;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 3), TGeoVec3.Make(10, 0, 3), TGeoVec3.Make(10, 10, 3)]);
  try
    // the winding lies on the plane z = 3: kept only when asked
    Assert.IsTrue(LWinding.ClipInPlace(TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 3), 0.1, True));
    Assert.AreEqual(3, LWinding.NumPoints);
    Assert.IsFalse(LWinding.ClipInPlace(TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 3), 0.1, False));
    Assert.AreEqual(0, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestClipAxialPlaneIsExact;
var
  LWinding: TGeoWinding;
  LIndex: Integer;
  LOnPlane: Integer;
  LPlaneDist: Single;
begin
  // the split points on an axial plane are not computed by interpolation: they are exact
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 3, 0),
    TGeoVec3.Make(10, 9, 0), TGeoVec3.Make(0, 7, 0)]);
  try
    LPlaneDist := 3.3;
    LWinding.ClipInPlace(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), LPlaneDist), 0);
    LOnPlane := 0;
    for LIndex := 0 to LWinding.NumPoints - 1 do
      if LWinding[LIndex].X = LPlaneDist then
        Inc(LOnPlane);
    Assert.AreEqual(2, LOnPlane);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestReverseSelf;
var
  LWinding: TGeoWinding;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(1, 0, 0), TGeoVec3.Make(2, 0, 0), TGeoVec3.Make(3, 0, 0),
    TGeoVec3.Make(4, 0, 0)]);
  try
    LWinding.ReverseSelf;
    Assert.AreEqual(4.0, LWinding[0].X, 0.0);
    Assert.AreEqual(3.0, LWinding[1].X, 0.0);
    Assert.AreEqual(1.0, LWinding[3].X, 0.0);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestBounds;
var
  LWinding: TGeoWinding;
  LBounds: TGeoBounds;
begin
  LWinding := TGeoWinding.Create;
  try
    LBounds := LWinding.GetBounds;
    Assert.IsTrue(LBounds.IsCleared);
    LWinding.AddPoint(TGeoVec3.Make(1, 5, -2));
    LWinding.AddPoint(TGeoVec3.Make(-3, 2, 4));
    LBounds := LWinding.GetBounds;
    Assert.AreEqual(-3.0, LBounds.Mins.X, 0.0);
    Assert.AreEqual(5.0, LBounds.Maxs.Y, 0.0);
    Assert.AreEqual(-2.0, LBounds.Mins.Z, 0.0);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding.TestBoxTraceModel;
var
  LTrm: TTraceModel;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    Assert.AreEqual(8, LTrm.NumVerts);
    Assert.AreEqual(12, LTrm.NumEdges);
    Assert.AreEqual(6, LTrm.NumPolys);
    Assert.IsTrue(LTrm.IsConvex);
    Assert.IsTrue(LTrm.Kind = tmkBox);
  finally
    LTrm.Free;
  end;
end;

procedure TTestGeometryWinding.TestBoxTraceModelEdgesAreWalkedConsistently;
var
  LTrm: TTraceModel;
  LUsers: array[0..MAX_TRACEMODEL_EDGES] of Integer;
  LForward: array[0..MAX_TRACEMODEL_EDGES] of Integer;
  LPoly: Integer;
  LEdge: Integer;
  LNum: Integer;
  LStart: Integer;
  LEnd: Integer;
  LPrevEnd: Integer;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    FillChar(LUsers, SizeOf(LUsers), 0);
    FillChar(LForward, SizeOf(LForward), 0);
    for LPoly := 0 to LTrm.NumPolys - 1 do
    begin
      LPrevEnd := -1;
      for LEdge := 0 to LTrm.Polys[LPoly].NumEdges - 1 do
      begin
        LNum := LTrm.Polys[LPoly].Edges[LEdge];
        Inc(LUsers[Abs(LNum)]);
        if LNum > 0 then
        begin
          Inc(LForward[LNum]);
          LStart := LTrm.Edges[LNum].V[0];
          LEnd := LTrm.Edges[LNum].V[1];
        end
        else
        begin
          LStart := LTrm.Edges[-LNum].V[1];
          LEnd := LTrm.Edges[-LNum].V[0];
        end;
        // the polygon is a closed loop: each edge starts where the previous one ended
        if LPrevEnd <> -1 then
          Assert.AreEqual(LPrevEnd, LStart);
        LPrevEnd := LEnd;
      end;
    end;
    // every edge of a closed box is used by exactly two polygons, once in each direction
    for LEdge := 1 to LTrm.NumEdges do
    begin
      Assert.AreEqual(2, LUsers[LEdge], 'edge ' + IntToStr(LEdge));
      Assert.AreEqual(1, LForward[LEdge], 'edge ' + IntToStr(LEdge));
    end;
  finally
    LTrm.Free;
  end;
end;

procedure TTestGeometryWinding.TestBoxTraceModelNormalsAndDistances;
var
  LTrm: TTraceModel;
  LPoly: Integer;
  LEdge: Integer;
  LNum: Integer;
  LVertexIndex: Integer;
  LPlane: TGeoPlane;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-4, -6, -8, 10, 12, 14));
  try
    for LPoly := 0 to LTrm.NumPolys - 1 do
    begin
      LPlane := TGeoPlane.Make(LTrm.Polys[LPoly].Normal, LTrm.Polys[LPoly].Dist);
      Assert.AreEqual(1.0, LTrm.Polys[LPoly].Normal.Length, 1e-5);
      // each vertex of the polygon is on its plane and the other vertices are behind it
      for LEdge := 0 to LTrm.Polys[LPoly].NumEdges - 1 do
      begin
        LNum := LTrm.Polys[LPoly].Edges[LEdge];
        if LNum > 0 then
          LVertexIndex := LTrm.Edges[LNum].V[0]
        else
          LVertexIndex := LTrm.Edges[-LNum].V[1];
        Assert.AreEqual(0.0, LPlane.Distance(LTrm.Verts[LVertexIndex]), 1e-4);
      end;
      for LVertexIndex := 0 to LTrm.NumVerts - 1 do
        Assert.IsTrue(LPlane.Distance(LTrm.Verts[LVertexIndex]) <= 1e-4);
    end;
    // the normal of a box edge is the sum of the two polygon normals (perpendicular: length sqrt(2))
    Assert.AreEqual(1.41421356, LTrm.Edges[1].Normal.Length, 1e-4);
  finally
    LTrm.Free;
  end;
end;

procedure TTestGeometryWinding.TestBoxTraceModelOffsetAndBounds;
var
  LTrm: TTraceModel;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-4, -6, -8, 10, 12, 14));
  try
    Assert.AreEqual(3.0, LTrm.Offset.X, 1e-6);
    Assert.AreEqual(3.0, LTrm.Offset.Y, 1e-6);
    Assert.AreEqual(3.0, LTrm.Offset.Z, 1e-6);
    Assert.AreEqual(-4.0, LTrm.Bounds.Mins.X, 0.0);
    Assert.AreEqual(14.0, LTrm.Bounds.Maxs.Z, 0.0);
    // the polygon bounds of the top face are flat at the maximum
    Assert.AreEqual(14.0, LTrm.Polys[1].Bounds.Mins.Z, 0.0);
    Assert.AreEqual(14.0, LTrm.Polys[1].Bounds.Maxs.Z, 0.0);
  finally
    LTrm.Free;
  end;
end;

procedure TTestGeometryWinding.TestCylinderTraceModel;
var
  LTrm: TTraceModel;
  LUsers: array[0..MAX_TRACEMODEL_EDGES] of Integer;
  LPoly: Integer;
  LEdge: Integer;
begin
  LTrm := TTraceModel.CreateCylinder(Bounds3(-16, -16, 0, 16, 16, 64), 8);
  try
    Assert.AreEqual(16, LTrm.NumVerts);
    Assert.AreEqual(24, LTrm.NumEdges);
    Assert.AreEqual(10, LTrm.NumPolys);
    FillChar(LUsers, SizeOf(LUsers), 0);
    for LPoly := 0 to LTrm.NumPolys - 1 do
      for LEdge := 0 to LTrm.Polys[LPoly].NumEdges - 1 do
        Inc(LUsers[Abs(LTrm.Polys[LPoly].Edges[LEdge])]);
    for LEdge := 1 to LTrm.NumEdges do
      Assert.AreEqual(2, LUsers[LEdge], 'edge ' + IntToStr(LEdge));
    Assert.AreEqual(0.0, LTrm.Offset.X, 1e-6);
    Assert.AreEqual(32.0, LTrm.Offset.Z, 1e-6);
  finally
    LTrm.Free;
  end;
end;

procedure TTestGeometryWinding.TestPolygonTraceModelAndVolume;
var
  LTrm: TTraceModel;
  LVolume: TTraceModel;
begin
  LTrm := TTraceModel.Create;
  LVolume := TTraceModel.Create;
  try
    LTrm.SetupPolygon([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 0, 0), TGeoVec3.Make(10, 10, 0),
      TGeoVec3.Make(0, 10, 0)]);
    Assert.AreEqual(4, LTrm.NumVerts);
    Assert.AreEqual(2, LTrm.NumPolys);
    Assert.IsFalse(LTrm.IsConvex);
    Assert.AreEqual(1.0, LTrm.Polys[0].Normal.Z, 1e-5);
    Assert.AreEqual(-1.0, LTrm.Polys[1].Normal.Z, 1e-5);
    Assert.AreEqual(5.0, LTrm.Offset.X, 1e-5);
    LTrm.VolumeFromPolygon(LVolume, 2);
    Assert.AreEqual(8, LVolume.NumVerts);
    Assert.AreEqual(12, LVolume.NumEdges);
    Assert.AreEqual(6, LVolume.NumPolys);
    // the volume extends behind the polygon along -normal
    Assert.AreEqual(-2.0, LVolume.Verts[4].Z, 1e-5);
  finally
    LVolume.Free;
    LTrm.Free;
  end;
end;

procedure TTestGeometryWinding.TestTraceModelTranslate;
var
  LTrm: TTraceModel;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-1, -1, -1, 1, 1, 1));
  try
    LTrm.Translate(TGeoVec3.Make(10, 0, 0));
    Assert.AreEqual(9.0, LTrm.Bounds.Mins.X, 1e-6);
    Assert.AreEqual(10.0, LTrm.Offset.X, 1e-6);
    // the polygon at x = max has the distance moved by the translation
    Assert.AreEqual(11.0, LTrm.Polys[3].Dist, 1e-6);
  finally
    LTrm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGeometryWinding);

end.
