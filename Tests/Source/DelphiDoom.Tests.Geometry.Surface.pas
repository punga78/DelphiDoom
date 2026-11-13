{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGeoSurface (idSurface)                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Surface;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The triangle surface: hand worked values and parity with the real idSurface of Doom 3
  ///   (Tests\Data\Geometry\surface.golden.txt, lines mesh and sf_*)
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometrySurface = class(TObject)
  public
    [Test]
    procedure UnQuadratoDovrebbeAvereCinqueSpigoliPiuIlFinto;
    [Test]
    procedure UnaTriangoloDovrebbeAvereLeFacceDegliSpigoli;
    [Test]
    procedure UnaMeshAperteNonDovrebbeEssereChiusa;
    [Test]
    procedure UnTetraedroDovrebbeEssereChiusoEConvesso;
    [Test]
    procedure DueTriangoliSeparatiNonDovrebberoEssereConnessi;
    [Test]
    procedure IlCostruttoreDovrebbeRifiutareDatiNonValidi;
    [Test]
    procedure CopyDovrebbeDareUnaSuperficieIndipendente;
    [Test]
    procedure AppendDovrebbeSommareIndiciEVertici;
    [Test]
    procedure TranslateERotateDovrebberoMuovereIVertici;
    [Test]
    procedure ClearESwapTrianglesDovrebberoSpostareITriangoli;
    [Test]
    procedure PlaneDistanceEPlaneSideDovrebberoMisurareIlPiano;
    [Test]
    procedure SplitDovrebbeDividereUnQuadratoLungoUnaDiagonale;
    [Test]
    procedure SplitDiUnaSuperficieSuUnLatoDovrebbeDareUnaCopia;
    [Test]
    procedure SplitDiUnaSuperficieSulPianoDovrebbeSceglierePerLaNormale;
    [Test]
    procedure SplitDiUnTetraedroConTriangoliATantiVerticiNonDovrebbeSforareIBuffer;
    [Test]
    procedure ClipInPlaceDovrebbeTenereLaParteDavanti;
    [Test]
    procedure ClipInPlaceDietroIlPianoDovrebbeSvuotareLaSuperficie;
    [Test]
    procedure IlRaggioDovrebbeColpireUnTriangolo;
    [Test]
    procedure IlSegmentoDovrebbeColpireSoloSeCorto;
    [Test]
    procedure LaMeshDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IlPianoDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure SplitDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure ClipInPlaceDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure RaggioESegmentoDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TraslazioneRotazioneEUnioneDovrebberoDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Types,
  DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.Surface, DelphiDoom.Tests.Geometry.Golden;

type
  TMesh = record
    Verts: TArray<TGeoDrawVert>;
    Indexes: TArray<Integer>;
  end;

function MakeVert(AX, AY, AZ: Single): TGeoDrawVert;
begin
  Result.Clear;
  Result.Xyz := TGeoVec3.Make(AX, AY, AZ);
end;

/// <summary>Two triangles (0 1 2) and (0 2 3) forming the square from (0, 0) to (2, 2) in the plane z = 0</summary>
function MakeQuad: TGeoSurface;
begin
  Result := TGeoSurface.Create([MakeVert(0, 0, 0), MakeVert(2, 0, 0), MakeVert(2, 2, 0), MakeVert(0, 2, 0)],
    [0, 1, 2, 0, 2, 3]);
end;

function MakeTetrahedron: TGeoSurface;
begin
  Result := TGeoSurface.Create([MakeVert(0, 0, 0), MakeVert(2, 0, 0), MakeVert(0, 2, 0), MakeVert(0, 0, 2)],
    [0, 1, 2, 0, 3, 1, 0, 2, 3, 1, 3, 2]);
end;

function ReadMesh(var AReader: TGeoGoldenReader): TMesh;
var
  LIndex: Integer;
begin
  SetLength(Result.Verts, AReader.Int);
  for LIndex := 0 to High(Result.Verts) do
    Result.Verts[LIndex] := AReader.DrawVert;
  SetLength(Result.Indexes, AReader.Int);
  for LIndex := 0 to High(Result.Indexes) do
    Result.Indexes[LIndex] := AReader.Int;
end;

function SurfaceFromMesh(const AMesh: TMesh): TGeoSurface;
begin
  Result := TGeoSurface.Create(AMesh.Verts, AMesh.Indexes);
end;

procedure PutSurface(AWriter: TGeoGoldenWriter; ASurface: TGeoSurface);
var
  LIndex, LEdgeCount: Integer;
  LEdge: TGeoSurfaceEdge;
begin
  // the original gives no edge count: the highest edge number in the indexes plus one
  LEdgeCount := 0;
  for LIndex := 0 to ASurface.NumIndexes - 1 do
    if Abs(ASurface.EdgeIndexes[LIndex]) + 1 > LEdgeCount then
      LEdgeCount := Abs(ASurface.EdgeIndexes[LIndex]) + 1;
  AWriter.Int(ASurface.NumVertices);
  AWriter.Int(ASurface.NumIndexes);
  AWriter.Int(LEdgeCount);
  for LIndex := 0 to ASurface.NumVertices - 1 do
    AWriter.DrawVert(ASurface[LIndex]);
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

/// <summary>Reads the lines of the given names, keeping the meshes by number</summary>
procedure RunLines(const ANames: array of string; const AAction: TProc<string, TDictionary<Integer, TMesh>>);
var
  LLines: TStringList;
  LMeshes: TDictionary<Integer, TMesh>;
  LLine: string;
  LReader: TGeoGoldenReader;
  LNumber: Integer;
  LAll: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LAll, Length(ANames) + 1);
  LAll[0] := 'mesh';
  for LIndex := 0 to High(ANames) do
    LAll[LIndex + 1] := ANames[LIndex];
  LLines := TGeoGolden.Load('surface.golden.txt', LAll);
  LMeshes := TDictionary<Integer, TMesh>.Create;
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      if LLine.StartsWith('mesh ') then
      begin
        LReader := TGeoGoldenReader.Open(LLine);
        LNumber := LReader.Int;
        LMeshes.Add(LNumber, ReadMesh(LReader));
      end
      else
        AAction(LLine, LMeshes);
    end;
  finally
    LMeshes.Free;
    LLines.Free;
  end;
end;

procedure TTestGeometrySurface.UnQuadratoDovrebbeAvereCinqueSpigoliPiuIlFinto;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    Assert.AreEqual(4, LSurface.NumVertices);
    Assert.AreEqual(6, LSurface.NumIndexes);
    // the dummy edge 0 plus the four sides and the shared diagonal
    Assert.AreEqual(6, LSurface.NumEdges);
    Assert.AreEqual(0, LSurface.Edges[1].Verts[0]);
    Assert.AreEqual(1, LSurface.Edges[1].Verts[1]);
    Assert.IsTrue(LSurface.IsConnected);
    Assert.IsFalse(LSurface.IsClosed);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.UnaTriangoloDovrebbeAvereLeFacceDegliSpigoli;
var
  LSurface: TGeoSurface;
begin
  LSurface := TGeoSurface.Create([MakeVert(0, 0, 0), MakeVert(1, 0, 0), MakeVert(0, 1, 0)], [0, 1, 2]);
  try
    Assert.AreEqual(4, LSurface.NumEdges);
    // edge 0-1 is used forward (positive), 1-2 forward, 2-0 reversed (stored as 0-2)
    Assert.AreEqual(1, LSurface.EdgeIndexes[0]);
    Assert.AreEqual(2, LSurface.EdgeIndexes[1]);
    Assert.AreEqual(-3, LSurface.EdgeIndexes[2]);
    Assert.AreEqual(0, LSurface.Edges[1].Tris[0]);
    Assert.AreEqual(-1, LSurface.Edges[1].Tris[1]);
    Assert.AreEqual(-1, LSurface.Edges[3].Tris[0]);
    Assert.AreEqual(0, LSurface.Edges[3].Tris[1]);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.UnaMeshAperteNonDovrebbeEssereChiusa;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    Assert.IsFalse(LSurface.IsPolytope);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.UnTetraedroDovrebbeEssereChiusoEConvesso;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeTetrahedron;
  try
    Assert.AreEqual(7, LSurface.NumEdges);
    Assert.IsTrue(LSurface.IsClosed);
    Assert.IsTrue(LSurface.IsConnected);
    Assert.IsTrue(LSurface.IsPolytope);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.DueTriangoliSeparatiNonDovrebberoEssereConnessi;
var
  LSurface: TGeoSurface;
begin
  LSurface := TGeoSurface.Create([MakeVert(0, 0, 0), MakeVert(1, 0, 0), MakeVert(0, 1, 0), MakeVert(5, 5, 5),
    MakeVert(6, 5, 5), MakeVert(5, 6, 5)], [0, 1, 2, 3, 4, 5]);
  try
    Assert.IsFalse(LSurface.IsConnected);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.IlCostruttoreDovrebbeRifiutareDatiNonValidi;
begin
  Assert.WillRaise(
    procedure
    begin
      TGeoSurface.Create([], [0, 1, 2]);
    end, EGeometryException);
  Assert.WillRaise(
    procedure
    begin
      TGeoSurface.Create([MakeVert(0, 0, 0)], [0, 0]);
    end, EGeometryException);
  Assert.WillRaise(
    procedure
    begin
      TGeoSurface.Create([MakeVert(0, 0, 0), MakeVert(1, 0, 0), MakeVert(0, 1, 0)], [0, 1, 7]);
    end, EGeometryException);
end;

procedure TTestGeometrySurface.CopyDovrebbeDareUnaSuperficieIndipendente;
var
  LSurface, LCopy: TGeoSurface;
begin
  LSurface := MakeQuad;
  LCopy := LSurface.Copy;
  try
    LCopy.TranslateSelf(TGeoVec3.Make(1, 1, 1));
    Assert.AreEqual<Single>(0, LSurface[0].Xyz.X);
    Assert.AreEqual<Single>(1, LCopy[0].Xyz.X);
    Assert.AreEqual(LSurface.NumEdges, LCopy.NumEdges);
  finally
    LCopy.Free;
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.AppendDovrebbeSommareIndiciEVertici;
var
  LSurface, LOther: TGeoSurface;
begin
  LSurface := MakeQuad;
  LOther := MakeQuad;
  try
    LSurface.Append(LOther);
    Assert.AreEqual(8, LSurface.NumVertices);
    Assert.AreEqual(12, LSurface.NumIndexes);
    Assert.AreEqual(4, LSurface.Indexes[6]);
    Assert.IsFalse(LSurface.IsConnected);
  finally
    LOther.Free;
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.TranslateERotateDovrebberoMuovereIVertici;
var
  LSurface: TGeoSurface;
  LRotation: TGeoMat3;
begin
  LSurface := MakeQuad;
  try
    LSurface.TranslateSelf(TGeoVec3.Make(1, 2, 3));
    Assert.AreEqual<Single>(3, LSurface[1].Xyz.X);
    Assert.AreEqual<Single>(4, LSurface[2].Xyz.Y);
    Assert.AreEqual<Single>(3, LSurface[0].Xyz.Z);
    LRotation := TGeoMat3.Identity;
    LRotation.Rows[0] := TGeoVec3.Make(0, 1, 0);
    LRotation.Rows[1] := TGeoVec3.Make(-1, 0, 0);
    LSurface.RotateSelf(LRotation);
    // idlib: vector * matrix = row0 * x + row1 * y + row2 * z
    Assert.AreEqual<Single>(-2, LSurface[0].Xyz.X);
    Assert.AreEqual<Single>(1, LSurface[0].Xyz.Y);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.ClearESwapTrianglesDovrebberoSpostareITriangoli;
var
  LFirst, LSecond: TGeoSurface;
begin
  LFirst := MakeQuad;
  LSecond := MakeTetrahedron;
  try
    LFirst.SwapTriangles(LSecond);
    Assert.AreEqual(4, LFirst.NumVertices);
    Assert.AreEqual(12, LFirst.NumIndexes);
    Assert.AreEqual(6, LSecond.NumIndexes);
    LSecond.Clear;
    Assert.AreEqual(0, LSecond.NumVertices);
    Assert.AreEqual(0, LSecond.NumEdges);
    Assert.AreEqual(0, LSecond.NumIndexes);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGeometrySurface.PlaneDistanceEPlaneSideDovrebberoMisurareIlPiano;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    // the plane x = 5: everything is behind, the nearest vertex is 3 away
    Assert.AreEqual<Single>(-3, LSurface.PlaneDistance(TGeoPlane.Make(1, 0, 0, -5)));
    Assert.AreEqual(PLANESIDE_BACK, LSurface.PlaneSide(TGeoPlane.Make(1, 0, 0, -5)));
    Assert.AreEqual<Single>(0, LSurface.PlaneDistance(TGeoPlane.Make(1, 0, 0, -1)));
    Assert.AreEqual(PLANESIDE_CROSS, LSurface.PlaneSide(TGeoPlane.Make(1, 0, 0, -1)));
    Assert.AreEqual(PLANESIDE_ON, LSurface.PlaneSide(TGeoPlane.Make(0, 0, 1, 0)));
    Assert.AreEqual(PLANESIDE_FRONT, LSurface.PlaneSide(TGeoPlane.Make(0, 0, 1, 1)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.SplitDovrebbeDividereUnQuadratoLungoUnaDiagonale;
var
  LSurface, LFront, LBack: TGeoSurface;
  LFrontEdges, LBackEdges: array[0..63] of Integer;
  LCount: Integer;
begin
  LSurface := MakeQuad;
  try
    // the plane x = 1 cuts the two triangles
    Assert.AreEqual(PLANESIDE_CROSS, LSurface.Split(TGeoPlane.Make(1, 0, 0, -1), 0.1, LFront, LBack,
      @LFrontEdges[0], @LBackEdges[0]));
    try
      Assert.IsTrue(LFront.NumIndexes > 0);
      Assert.IsTrue(LBack.NumIndexes > 0);
      Assert.AreEqual<Single>(0, LFront.PlaneDistance(TGeoPlane.Make(1, 0, 0, -1)));
      LCount := 0;
      while LFrontEdges[LCount] >= 0 do
        Inc(LCount);
      Assert.IsTrue(LCount > 0);
      LCount := 0;
      while LBackEdges[LCount] >= 0 do
        Inc(LCount);
      Assert.IsTrue(LCount > 0);
    finally
      LFront.Free;
      LBack.Free;
    end;
    Assert.AreEqual(4, LSurface.NumVertices);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.SplitDiUnaSuperficieSuUnLatoDovrebbeDareUnaCopia;
var
  LSurface, LFront, LBack: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    Assert.AreEqual(PLANESIDE_FRONT, LSurface.Split(TGeoPlane.Make(1, 0, 0, 5), 0.1, LFront, LBack));
    Assert.IsNull(LBack);
    Assert.AreEqual(6, LFront.NumIndexes);
    LFront.Free;
    Assert.AreEqual(PLANESIDE_BACK, LSurface.Split(TGeoPlane.Make(1, 0, 0, -5), 0.1, LFront, LBack));
    Assert.IsNull(LFront);
    LBack.Free;
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.SplitDiUnaSuperficieSulPianoDovrebbeSceglierePerLaNormale;
var
  LSurface, LFront, LBack: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    // the triangles are counter clockwise seen from +z: with the cross product used by idlib
    // the normal matches the plane z = 0 pointing down
    Assert.AreEqual(PLANESIDE_BACK, LSurface.Split(TGeoPlane.Make(0, 0, 1, 0), 0.1, LFront, LBack));
    Assert.IsNull(LFront);
    LBack.Free;
    Assert.AreEqual(PLANESIDE_FRONT, LSurface.Split(TGeoPlane.Make(0, 0, -1, 0), 0.1, LFront, LBack));
    Assert.IsNull(LBack);
    LFront.Free;
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.SplitDiUnTetraedroConTriangoliATantiVerticiNonDovrebbeSforareIBuffer;
var
  LSurface, LFront, LBack: TGeoSurface;
begin
  // the plane z = 1 leaves the base (3 vertices, 7 triangles once cut) on one side: the original sizes
  // the index buffer of ClipInPlace for 18 indexes and writes 21 (heap overflow); here the buffers grow
  LSurface := MakeTetrahedron;
  try
    Assert.IsTrue(LSurface.ClipInPlace(TGeoPlane.Make(0, 0, -1, 1), 0));
    Assert.AreEqual(21, LSurface.NumIndexes);
  finally
    LSurface.Free;
  end;
  LSurface := MakeTetrahedron;
  try
    Assert.AreEqual(PLANESIDE_CROSS, LSurface.Split(TGeoPlane.Make(0, 0, 1, -1), 0, LFront, LBack));
    Assert.AreEqual(9, LFront.NumIndexes);
    Assert.AreEqual(21, LBack.NumIndexes);
    LFront.Free;
    LBack.Free;
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.ClipInPlaceDovrebbeTenereLaParteDavanti;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    Assert.IsTrue(LSurface.ClipInPlace(TGeoPlane.Make(1, 0, 0, -1), 0.1));
    Assert.AreEqual<Single>(0, LSurface.PlaneDistance(TGeoPlane.Make(1, 0, 0, -1)));
    Assert.IsTrue(LSurface.NumIndexes > 0);
    Assert.IsTrue(LSurface.NumVertices >= 4);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.ClipInPlaceDietroIlPianoDovrebbeSvuotareLaSuperficie;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    Assert.IsFalse(LSurface.ClipInPlace(TGeoPlane.Make(1, 0, 0, -5), 0.1));
    Assert.AreEqual(0, LSurface.NumIndexes);
  finally
    LSurface.Free;
  end;
  LSurface := MakeQuad;
  try
    // everything in front: unchanged
    Assert.IsTrue(LSurface.ClipInPlace(TGeoPlane.Make(1, 0, 0, 5), 0.1));
    Assert.AreEqual(6, LSurface.NumIndexes);
    // coplanar, normals opposite: gone; same side: kept
    Assert.IsTrue(LSurface.ClipInPlace(TGeoPlane.Make(0, 0, -1, 0), 0.1));
    Assert.IsFalse(LSurface.ClipInPlace(TGeoPlane.Make(0, 0, 1, 0), 0.1));
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.IlRaggioDovrebbeColpireUnTriangolo;
var
  LSurface: TGeoSurface;
  LScale: Single;
begin
  LSurface := MakeQuad;
  try
    Assert.IsTrue(LSurface.RayIntersection(TGeoVec3.Make(1.5, 0.5, 4), TGeoVec3.Make(0, 0, -1), LScale));
    AssertNear(4, LScale, 1E-5);
    Assert.IsTrue(LSurface.RayIntersection(TGeoVec3.Make(1.5, 0.5, -4), TGeoVec3.Make(0, 0, 1), LScale));
    AssertNear(4, LScale, 1E-5);
    Assert.IsFalse(LSurface.RayIntersection(TGeoVec3.Make(9, 9, 4), TGeoVec3.Make(0, 0, -1), LScale));
    Assert.AreEqual<Single>(GEO_INFINITY, LScale);
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.IlSegmentoDovrebbeColpireSoloSeCorto;
var
  LSurface: TGeoSurface;
begin
  LSurface := MakeQuad;
  try
    Assert.IsTrue(LSurface.LineIntersection(TGeoVec3.Make(1.5, 0.5, 1), TGeoVec3.Make(1.5, 0.5, -1)));
    Assert.IsFalse(LSurface.LineIntersection(TGeoVec3.Make(1.5, 0.5, 4), TGeoVec3.Make(1.5, 0.5, 1)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestGeometrySurface.LaMeshDovrebbeDareLeStesseRispostePerIlCpp;
begin
  RunLines(['sf_build'],
    procedure(ALine: string; AMeshes: TDictionary<Integer, TMesh>)
    var
      LReader: TGeoGoldenReader;
      LSurface: TGeoSurface;
      LWriter: TGeoGoldenWriter;
    begin
      LReader := TGeoGoldenReader.Open(ALine);
      LSurface := SurfaceFromMesh(AMeshes[LReader.Int]);
      LWriter := TGeoGoldenWriter.Create;
      try
        PutSurface(LWriter, LSurface);
        LWriter.Flag(LSurface.IsConnected);
        LWriter.Flag(LSurface.IsClosed);
        LWriter.Flag(LSurface.IsPolytope(0.1));
        LWriter.Flag(LSurface.IsPolytope(0.5));
        TGeoGolden.CompareOutput(ALine, LWriter.Text);
      finally
        LWriter.Free;
        LSurface.Free;
      end;
    end);
end;

procedure TTestGeometrySurface.IlPianoDovrebbeDareLeStesseRispostePerIlCpp;
begin
  RunLines(['sf_plane'],
    procedure(ALine: string; AMeshes: TDictionary<Integer, TMesh>)
    var
      LReader: TGeoGoldenReader;
      LSurface: TGeoSurface;
      LWriter: TGeoGoldenWriter;
      LPlane: TGeoPlane;
      LEpsilon: Single;
    begin
      LReader := TGeoGoldenReader.Open(ALine);
      LSurface := SurfaceFromMesh(AMeshes[LReader.Int]);
      LPlane := LReader.Plane;
      LEpsilon := LReader.Float;
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.Float(LSurface.PlaneDistance(LPlane));
        LWriter.Int(LSurface.PlaneSide(LPlane, LEpsilon));
        TGeoGolden.CompareOutput(ALine, LWriter.Text);
      finally
        LWriter.Free;
        LSurface.Free;
      end;
    end);
end;

procedure TTestGeometrySurface.SplitDovrebbeDareLeStesseRispostePerIlCpp;
begin
  RunLines(['sf_split'],
    procedure(ALine: string; AMeshes: TDictionary<Integer, TMesh>)
    var
      LReader: TGeoGoldenReader;
      LSurface, LFront, LBack: TGeoSurface;
      LWriter: TGeoGoldenWriter;
      LPlane: TGeoPlane;
      LEpsilon: Single;
      LSide, LIndex, LCount: Integer;
      LFrontEdges, LBackEdges: array[0..511] of Integer;
    begin
      LReader := TGeoGoldenReader.Open(ALine);
      LSurface := SurfaceFromMesh(AMeshes[LReader.Int]);
      LPlane := LReader.Plane;
      LEpsilon := LReader.Float;
      LWriter := TGeoGoldenWriter.Create;
      try
        LSide := LSurface.Split(LPlane, LEpsilon, LFront, LBack, @LFrontEdges[0], @LBackEdges[0]);
        LWriter.Int(LSide);
        LWriter.Flag(Assigned(LFront));
        LWriter.Flag(Assigned(LBack));
        if Assigned(LFront) then
          PutSurface(LWriter, LFront);
        if Assigned(LBack) then
          PutSurface(LWriter, LBack);
        if LSide = PLANESIDE_CROSS then
        begin
          LCount := 0;
          while LFrontEdges[LCount] >= 0 do
            Inc(LCount);
          LWriter.Int(LCount);
          for LIndex := 0 to LCount - 1 do
            LWriter.Int(LFrontEdges[LIndex]);
          LCount := 0;
          while LBackEdges[LCount] >= 0 do
            Inc(LCount);
          LWriter.Int(LCount);
          for LIndex := 0 to LCount - 1 do
            LWriter.Int(LBackEdges[LIndex]);
        end;
        TGeoGolden.CompareOutput(ALine, LWriter.Text);
      finally
        LFront.Free;
        LBack.Free;
        LWriter.Free;
        LSurface.Free;
      end;
    end);
end;

procedure TTestGeometrySurface.ClipInPlaceDovrebbeDareLeStesseRispostePerIlCpp;
begin
  RunLines(['sf_clip'],
    procedure(ALine: string; AMeshes: TDictionary<Integer, TMesh>)
    var
      LReader: TGeoGoldenReader;
      LSurface: TGeoSurface;
      LWriter: TGeoGoldenWriter;
      LPlane: TGeoPlane;
      LEpsilon: Single;
      LKeep: Boolean;
    begin
      LReader := TGeoGoldenReader.Open(ALine);
      LSurface := SurfaceFromMesh(AMeshes[LReader.Int]);
      LPlane := LReader.Plane;
      LEpsilon := LReader.Float;
      LKeep := LReader.Flag;
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.Flag(LSurface.ClipInPlace(LPlane, LEpsilon, LKeep));
        PutSurface(LWriter, LSurface);
        TGeoGolden.CompareOutput(ALine, LWriter.Text);
      finally
        LWriter.Free;
        LSurface.Free;
      end;
    end);
end;

procedure TTestGeometrySurface.RaggioESegmentoDovrebberoDareLeStesseRispostePerIlCpp;
begin
  RunLines(['sf_ray', 'sf_line'],
    procedure(ALine: string; AMeshes: TDictionary<Integer, TMesh>)
    var
      LReader: TGeoGoldenReader;
      LSurface: TGeoSurface;
      LWriter: TGeoGoldenWriter;
      LStart, LOther: TGeoVec3;
      LScale: Single;
      LHit: Boolean;
    begin
      LReader := TGeoGoldenReader.Open(ALine);
      LSurface := SurfaceFromMesh(AMeshes[LReader.Int]);
      LStart := LReader.Vec3;
      LOther := LReader.Vec3;
      LWriter := TGeoGoldenWriter.Create;
      try
        if ALine.StartsWith('sf_ray') then
        begin
          LHit := LSurface.RayIntersection(LStart, LOther, LScale, LReader.Flag);
          LWriter.Flag(LHit);
          LWriter.Float(LScale);
        end
        else
          LWriter.Flag(LSurface.LineIntersection(LStart, LOther));
        TGeoGolden.CompareOutput(ALine, LWriter.Text);
      finally
        LWriter.Free;
        LSurface.Free;
      end;
    end);
end;

procedure TTestGeometrySurface.TraslazioneRotazioneEUnioneDovrebberoDareLeStesseRispostePerIlCpp;
begin
  RunLines(['sf_translate', 'sf_rotate', 'sf_append'],
    procedure(ALine: string; AMeshes: TDictionary<Integer, TMesh>)
    var
      LReader: TGeoGoldenReader;
      LSurface, LOther: TGeoSurface;
      LWriter: TGeoGoldenWriter;
    begin
      LReader := TGeoGoldenReader.Open(ALine);
      LSurface := SurfaceFromMesh(AMeshes[LReader.Int]);
      LWriter := TGeoGoldenWriter.Create;
      try
        if ALine.StartsWith('sf_translate') then
          LSurface.TranslateSelf(LReader.Vec3)
        else if ALine.StartsWith('sf_rotate') then
          LSurface.RotateSelf(LReader.Mat3)
        else
        begin
          LOther := SurfaceFromMesh(AMeshes[LReader.Int]);
          try
            LSurface.Append(LOther);
          finally
            LOther.Free;
          end;
        end;
        PutSurface(LWriter, LSurface);
        TGeoGolden.CompareOutput(ALine, LWriter.Text);
      finally
        LWriter.Free;
        LSurface.Free;
      end;
    end);
end;

end.
