{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGeoSurfacePolytope (idSurface_Polytope)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.SurfacePolytope;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The polytope surface: hand worked values and parity with the real idSurface_Polytope of Doom 3
  ///   (Tests\Data\Geometry\surface.golden.txt, lines pt_*)
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometrySurfacePolytope = class(TObject)
  public
    [Test]
    procedure IlTetraedroDovrebbeAvereQuattroTriangoli;
    [Test]
    procedure LEsaedroDovrebbeAvereOttoVerticiEDodiciTriangoli;
    [Test]
    procedure LOttaedroDovrebbeAvereSeiVerticiEOttoTriangoli;
    [Test]
    procedure LeFormeDovrebberoEssereChiuseEConnesse;
    [Test]
    procedure FromPlanesDovrebbeDareUnaScatolaDa8VerticiEDa12Triangoli;
    [Test]
    procedure FromPlanesDiUnPianoSoloDovrebbeDareIlQuadrilateroBase;
    [Test]
    procedure SplitPolytopeDovrebbeAggiungereITriangoliDiChiusura;
    [Test]
    procedure SplitPolytopeFuoriDalPoliedroDovrebbeDareUnaMetaVuota;
    [Test]
    procedure LeFormeDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure SplitPolytopeDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.Surface,
  DelphiDoom.Geometry.Surface.Polytope, DelphiDoom.Tests.Geometry.Golden;

function UnitBounds: TGeoBounds;
begin
  Result := TGeoBounds.Make(TGeoVec3.Make(-1, -1, -1), TGeoVec3.Make(1, 1, 1));
end;

procedure PutSurface(AWriter: TGeoGoldenWriter; ASurface: TGeoSurface);
var
  LIndex, LEdgeCount: Integer;
  LEdge: TGeoSurfaceEdge;
begin
  LEdgeCount := 0;
  for LIndex := 0 to ASurface.NumIndexes - 1 do
    if Abs(ASurface.EdgeIndexes[LIndex]) + 1 > LEdgeCount then
      LEdgeCount := Abs(ASurface.EdgeIndexes[LIndex]) + 1;
  AWriter.Int(ASurface.NumVertices);
  AWriter.Int(ASurface.NumIndexes);
  AWriter.Int(LEdgeCount);
  for LIndex := 0 to ASurface.NumVertices - 1 do
    AWriter.Vec3(ASurface[LIndex].Xyz);
  for LIndex := 0 to ASurface.NumIndexes - 1 do
    AWriter.Int(ASurface.Indexes[LIndex]);
  for LIndex := 0 to LEdgeCount - 1 do
  begin
    LEdge := ASurface.Edges[LIndex];
    AWriter.Int(LEdge.Verts[0]);
    AWriter.Int(LEdge.Verts[1]);
    AWriter.Int(LEdge.Tris[0]);
    AWriter.Int(LEdge.Tris[1]);
  end;
  for LIndex := 0 to ASurface.NumIndexes - 1 do
    AWriter.Int(ASurface.EdgeIndexes[LIndex]);
end;

procedure Setup(APolytope: TGeoSurfacePolytope; AKind: Integer; const ABounds: TGeoBounds);
begin
  case AKind of
    0: APolytope.SetupTetrahedron(ABounds);
    1: APolytope.SetupHexahedron(ABounds);
  else
    APolytope.SetupOctahedron(ABounds);
  end;
end;

procedure TTestGeometrySurfacePolytope.IlTetraedroDovrebbeAvereQuattroTriangoli;
var
  LPolytope: TGeoSurfacePolytope;
begin
  LPolytope := TGeoSurfacePolytope.Create;
  try
    LPolytope.SetupTetrahedron(UnitBounds);
    Assert.AreEqual(4, LPolytope.NumVertices);
    Assert.AreEqual(12, LPolytope.NumIndexes);
    Assert.AreEqual<Single>(1, LPolytope[0].Xyz.Z);
    AssertNear(-1 / 3, LPolytope[1].Xyz.Z, 1E-6);
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.LEsaedroDovrebbeAvereOttoVerticiEDodiciTriangoli;
var
  LPolytope: TGeoSurfacePolytope;
begin
  LPolytope := TGeoSurfacePolytope.Create;
  try
    LPolytope.SetupHexahedron(UnitBounds);
    Assert.AreEqual(8, LPolytope.NumVertices);
    Assert.AreEqual(36, LPolytope.NumIndexes);
    Assert.AreEqual<Single>(-1, LPolytope[0].Xyz.X);
    Assert.AreEqual<Single>(1, LPolytope[6].Xyz.Z);
    // a cube: twelve edges (and the dummy one) plus the six diagonals of the faces
    Assert.AreEqual(1 + 18, LPolytope.NumEdges);
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.LOttaedroDovrebbeAvereSeiVerticiEOttoTriangoli;
var
  LPolytope: TGeoSurfacePolytope;
begin
  LPolytope := TGeoSurfacePolytope.Create;
  try
    LPolytope.SetupOctahedron(UnitBounds);
    Assert.AreEqual(6, LPolytope.NumVertices);
    Assert.AreEqual(24, LPolytope.NumIndexes);
    Assert.AreEqual(1 + 12, LPolytope.NumEdges);
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.LeFormeDovrebberoEssereChiuseEConnesse;
var
  LPolytope: TGeoSurfacePolytope;
  LKind: Integer;
begin
  for LKind := 0 to 2 do
  begin
    LPolytope := TGeoSurfacePolytope.Create;
    try
      Setup(LPolytope, LKind, UnitBounds);
      Assert.IsTrue(LPolytope.IsClosed, 'chiusa ' + IntToStr(LKind));
      Assert.IsTrue(LPolytope.IsConnected, 'connessa ' + IntToStr(LKind));
      // with the winding of the original every other vertex is in front of a triangle plane (idPlane::FromPoints),
      // so IsPolytope is false for the stock shapes; the golden file has the same answer
      Assert.IsFalse(LPolytope.IsPolytope, 'orientamento ' + IntToStr(LKind));
    finally
      LPolytope.Free;
    end;
  end;
end;

procedure TTestGeometrySurfacePolytope.FromPlanesDovrebbeDareUnaScatolaDa8VerticiEDa12Triangoli;
var
  LPolytope: TGeoSurfacePolytope;
begin
  // the original loops on a variable that never changes once a vertex exists (j++ instead of k++)
  LPolytope := TGeoSurfacePolytope.Create;
  try
    LPolytope.FromPlanes([TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 1), TGeoPlane.Make(TGeoVec3.Make(-1, 0, 0), 1),
      TGeoPlane.Make(TGeoVec3.Make(0, 1, 0), 1), TGeoPlane.Make(TGeoVec3.Make(0, -1, 0), 1),
      TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 1), TGeoPlane.Make(TGeoVec3.Make(0, 0, -1), 1)]);
    Assert.AreEqual(8, LPolytope.NumVertices);
    Assert.AreEqual(36, LPolytope.NumIndexes);
    Assert.IsTrue(LPolytope.IsClosed);
    Assert.IsTrue(LPolytope.IsPolytope(0.5));
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.FromPlanesDiUnPianoSoloDovrebbeDareIlQuadrilateroBase;
var
  LPolytope: TGeoSurfacePolytope;
begin
  LPolytope := TGeoSurfacePolytope.Create;
  try
    // one plane alone is a huge quadrilateral (clipped by nothing): not empty, but with no other
    // plane to close it the winding is the base winding
    LPolytope.FromPlanes([TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0)]);
    Assert.AreEqual(4, LPolytope.NumVertices);
    Assert.AreEqual(6, LPolytope.NumIndexes);
    LPolytope.Clear;
    LPolytope.FromPlanes([]);
    Assert.AreEqual(0, LPolytope.NumVertices);
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.SplitPolytopeDovrebbeAggiungereITriangoliDiChiusura;
var
  LPolytope, LFront, LBack: TGeoSurfacePolytope;
begin
  LPolytope := TGeoSurfacePolytope.Create;
  try
    LPolytope.SetupHexahedron(UnitBounds);
    Assert.AreEqual(PLANESIDE_CROSS, LPolytope.SplitPolytope(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 0.25), 0.1,
      LFront, LBack));
    try
      // each half got the triangles that close the cut
      Assert.IsTrue(LFront.NumIndexes > 0);
      Assert.IsTrue(LBack.NumIndexes > 0);
      Assert.IsTrue(LFront.NumIndexes + LBack.NumIndexes > 36);
    finally
      LFront.Free;
      LBack.Free;
    end;
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.SplitPolytopeFuoriDalPoliedroDovrebbeDareUnaMetaVuota;
var
  LPolytope, LFront, LBack: TGeoSurfacePolytope;
begin
  LPolytope := TGeoSurfacePolytope.Create;
  try
    LPolytope.SetupOctahedron(UnitBounds);
    Assert.AreEqual(PLANESIDE_BACK, LPolytope.SplitPolytope(TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 5), 0.1, LFront,
      LBack));
    try
      Assert.AreEqual(0, LFront.NumIndexes);
      Assert.AreEqual(24, LBack.NumIndexes);
    finally
      LFront.Free;
      LBack.Free;
    end;
  finally
    LPolytope.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.LeFormeDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LPolytope: TGeoSurfacePolytope;
  LBounds: TGeoBounds;
  LKind: Integer;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['pt_setup']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LKind := LReader.Int;
      LBounds.Mins := LReader.Vec3;
      LBounds.Maxs := LReader.Vec3;
      LPolytope := TGeoSurfacePolytope.Create;
      LWriter := TGeoGoldenWriter.Create;
      try
        Setup(LPolytope, LKind, LBounds);
        PutSurface(LWriter, LPolytope);
        LWriter.Flag(LPolytope.IsConnected);
        LWriter.Flag(LPolytope.IsClosed);
        LWriter.Flag(LPolytope.IsPolytope(0.1));
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
        LPolytope.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometrySurfacePolytope.SplitPolytopeDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LPolytope, LFront, LBack: TGeoSurfacePolytope;
  LBounds: TGeoBounds;
  LPlane: TGeoPlane;
  LEpsilon: Single;
  LKind: Integer;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['pt_split']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LKind := LReader.Int;
      LBounds.Mins := LReader.Vec3;
      LBounds.Maxs := LReader.Vec3;
      LPlane := LReader.Plane;
      LEpsilon := LReader.Float;
      LPolytope := TGeoSurfacePolytope.Create;
      LWriter := TGeoGoldenWriter.Create;
      try
        Setup(LPolytope, LKind, LBounds);
        LWriter.Int(LPolytope.SplitPolytope(LPlane, LEpsilon, LFront, LBack));
        PutSurface(LWriter, LFront);
        PutSurface(LWriter, LBack);
        LWriter.Flag(LFront.IsClosed);
        LWriter.Flag(LBack.IsClosed);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
        LFront.Free;
        LBack.Free;
      finally
        LWriter.Free;
        LPolytope.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

end.
