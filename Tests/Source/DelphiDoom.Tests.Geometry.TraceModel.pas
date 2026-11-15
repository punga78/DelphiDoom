{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTraceModel (idTraceModel): octahedron, dodecahedron,  }
{  cone and cylinder, with the golden file of the real Doom 3 TraceModel.cpp   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.TraceModel;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Geometry')]
  TTestGeometryTraceModel = class(TObject)
  public
    [Test]
    procedure IlTraceModelDovrebbeDareLeStesseRisposteDelCpp;
    [Test]
    procedure L_ottaedroDovrebbeAvereSeiVerticiEOttoPoligoni;
    [Test]
    procedure IlDodecaedroDovrebbeAvereVentiVerticiEDodiciPentagoni;
    [Test]
    procedure IlConoDovrebbeAvereUnApiceEUnaBase;
    [Test]
    procedure IlConoConMenoDiDueLatiDovrebbeAvereTreLati;
    [Test]
    procedure IlConoDovrebbeLimitareILatiAlMassimoDelModello;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Tests.Geometry.Golden;

procedure PutModel(AWriter: TGeoGoldenWriter; AModel: TTraceModel);
var
  LIndex: Integer;
  LEdge: Integer;
begin
  AWriter.Int(Ord(AModel.Kind));
  AWriter.Int(AModel.NumVerts);
  AWriter.Int(AModel.NumEdges);
  AWriter.Int(AModel.NumPolys);
  AWriter.Flag(AModel.IsConvex);
  AWriter.Vec3(AModel.Offset);
  AWriter.Vec3(AModel.Bounds.Mins);
  AWriter.Vec3(AModel.Bounds.Maxs);
  for LIndex := 0 to AModel.NumVerts - 1 do
    AWriter.Vec3(AModel.Verts[LIndex]);
  for LIndex := 1 to AModel.NumEdges do
  begin
    AWriter.Int(AModel.Edges[LIndex].V[0]);
    AWriter.Int(AModel.Edges[LIndex].V[1]);
    AWriter.Vec3(AModel.Edges[LIndex].Normal);
  end;
  for LIndex := 0 to AModel.NumPolys - 1 do
  begin
    AWriter.Int(AModel.Polys[LIndex].NumEdges);
    for LEdge := 0 to AModel.Polys[LIndex].NumEdges - 1 do
      AWriter.Int(AModel.Polys[LIndex].Edges[LEdge]);
    AWriter.Vec3(AModel.Polys[LIndex].Normal);
    AWriter.Float(AModel.Polys[LIndex].Dist);
    AWriter.Vec3(AModel.Polys[LIndex].Bounds.Mins);
    AWriter.Vec3(AModel.Polys[LIndex].Bounds.Maxs);
  end;
end;

procedure TTestGeometryTraceModel.IlTraceModelDovrebbeDareLeStesseRisposteDelCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LModel: TTraceModel;
  LBounds: TGeoBounds;
  LKind: Integer;
  LSides: Integer;
  LF: array[0..5] of Single;
  LIndex: Integer;
begin
  LLines := TGeoGolden.Load('trm.golden.txt', ['trm']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LKind := LReader.Int;
      LSides := LReader.Int;
      for LIndex := 0 to 5 do
        LF[LIndex] := LReader.Float;
      LBounds.Mins.SetValues(LF[0], LF[1], LF[2]);
      LBounds.Maxs.SetValues(LF[3], LF[4], LF[5]);
      LModel := TTraceModel.Create;
      LWriter := TGeoGoldenWriter.Create;
      try
        case LKind of
          0: LModel.SetupOctahedron(LBounds);
          1: LModel.SetupDodecahedron(LBounds);
          2: LModel.SetupCone(LBounds, LSides);
          3: LModel.SetupCylinder(LBounds, LSides);
          4: LModel.SetupOctahedron(LF[0]);
          5: LModel.SetupDodecahedron(LF[0]);
          6: LModel.SetupCone(LF[0], LF[1], LSides);
        end;
        PutModel(LWriter, LModel);
        TGeoGolden.CompareOutput(LLine, LWriter.Text, 4, 1E-3);
      finally
        LWriter.Free;
        LModel.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryTraceModel.L_ottaedroDovrebbeAvereSeiVerticiEOttoPoligoni;
var
  LModel: TTraceModel;
begin
  LModel := TTraceModel.Create;
  try
    LModel.SetupOctahedron(2);
    Assert.AreEqual(Ord(tmkOctahedron), Ord(LModel.Kind));
    Assert.AreEqual(6, LModel.NumVerts);
    Assert.AreEqual(12, LModel.NumEdges);
    Assert.AreEqual(8, LModel.NumPolys);
    Assert.IsTrue(LModel.IsConvex);
    Assert.AreEqual<Single>(1, LModel.Verts[0].X);
    Assert.AreEqual<Single>(-1, LModel.Verts[5].Z);
  finally
    LModel.Free;
  end;
end;

procedure TTestGeometryTraceModel.IlDodecaedroDovrebbeAvereVentiVerticiEDodiciPentagoni;
var
  LModel: TTraceModel;
  LIndex: Integer;
begin
  LModel := TTraceModel.Create;
  try
    LModel.SetupDodecahedron(2);
    Assert.AreEqual(20, LModel.NumVerts);
    Assert.AreEqual(30, LModel.NumEdges);
    Assert.AreEqual(12, LModel.NumPolys);
    for LIndex := 0 to 11 do
      Assert.AreEqual(5, LModel.Polys[LIndex].NumEdges);
  finally
    LModel.Free;
  end;
end;

procedure TTestGeometryTraceModel.IlConoDovrebbeAvereUnApiceEUnaBase;
var
  LModel: TTraceModel;
begin
  LModel := TTraceModel.Create;
  try
    // the origin is at the apex
    LModel.SetupCone(10, 4, 6);
    Assert.AreEqual(7, LModel.NumVerts);
    Assert.AreEqual(12, LModel.NumEdges);
    Assert.AreEqual(7, LModel.NumPolys);
    Assert.AreEqual<Single>(0, LModel.Verts[6].Z);
    Assert.AreEqual<Single>(-10, LModel.Verts[0].Z);
    Assert.AreEqual(6, LModel.Polys[6].NumEdges, 'the base');
  finally
    LModel.Free;
  end;
end;

procedure TTestGeometryTraceModel.IlConoConMenoDiDueLatiDovrebbeAvereTreLati;
var
  LModel: TTraceModel;
  LBounds: TGeoBounds;
begin
  LBounds.Mins.SetValues(-1, -1, -1);
  LBounds.Maxs.SetValues(1, 1, 1);
  LModel := TTraceModel.Create;
  try
    // idTraceModel::SetupCone: n < 2 becomes 3 (SetupCylinder uses n < 3)
    LModel.SetupCone(LBounds, 1);
    Assert.AreEqual(4, LModel.NumVerts);
    LModel.SetupCone(LBounds, 2);
    Assert.AreEqual(3, LModel.NumVerts, 'two sides are kept');
  finally
    LModel.Free;
  end;
end;

procedure TTestGeometryTraceModel.IlConoDovrebbeLimitareILatiAlMassimoDelModello;
var
  LModel: TTraceModel;
  LBounds: TGeoBounds;
begin
  LBounds.Mins.SetValues(-1, -1, -1);
  LBounds.Maxs.SetValues(1, 1, 1);
  LModel := TTraceModel.Create;
  try
    LModel.SetupCone(LBounds, 100);
    // 16 edges at most: n * 2 <= 32, 16 polygons: n + 1 <= 16
    Assert.AreEqual(16, LModel.NumPolys);
    Assert.AreEqual(30, LModel.NumEdges);
  finally
    LModel.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGeometryTraceModel);

end.
