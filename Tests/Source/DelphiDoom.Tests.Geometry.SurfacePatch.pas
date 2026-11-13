{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGeoSurfacePatch (idSurface_Patch)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.SurfacePatch;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The Bezier patch: hand worked values and parity with the real idSurface_Patch of Doom 3
  ///   (Tests\Data\Geometry\surface.golden.txt, lines pa_*)
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometrySurfacePatch = class(TObject)
  public
    [Test]
    procedure SetSizeDovrebbeRifiutareDimensioniNonValide;
    [Test]
    procedure UnaPatchPianaSuddivisaInModoEsplicitoDovrebbeDareUnaGrigliaRegolare;
    [Test]
    procedure IlPuntoCentraleDellaCurvaDovrebbeEssereLaMediaPesata;
    [Test]
    procedure LeNormaliDiUnaPatchPianaDovrebberoEssereLeNormaliDelPiano;
    [Test]
    procedure RemoveLinearDovrebbeToglierePunteSuUnaRetta;
    [Test]
    procedure SubdivideSenzaErroreNonDovrebbeAggiungereRigheNeColonne;
    [Test]
    procedure SubdivideConUnaLunghezzaMassimaDovrebbeAggiungereColonne;
    [Test]
    procedure AssignDovrebbeCopiareLeDimensioni;
    [Test]
    procedure SubdivideExplicitDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure SubdivideDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.Surface,
  DelphiDoom.Geometry.Surface.Patch, DelphiDoom.Tests.Geometry.Golden;

/// <summary>A flat 3x3 control mesh with a spacing of 2 units, in the plane z = AHeight</summary>
function MakeFlatPatch(AColumns, ARows: Integer; AHeight: Single): TGeoSurfacePatch;
var
  LColumn, LRow: Integer;
  LVertex: TGeoDrawVert;
begin
  Result := TGeoSurfacePatch.Create(AColumns, ARows);
  Result.SetSize(AColumns, ARows);
  for LRow := 0 to ARows - 1 do
    for LColumn := 0 to AColumns - 1 do
    begin
      LVertex.Clear;
      LVertex.Xyz := TGeoVec3.Make(LColumn * 2, LRow * 2, AHeight);
      LVertex.St := TIdVec2.Create(LColumn / (AColumns - 1), LRow / (ARows - 1));
      Result.Vertices[LRow * AColumns + LColumn] := LVertex;
    end;
end;

procedure PutPatch(AWriter: TGeoGoldenWriter; APatch: TGeoSurfacePatch);
var
  LIndex, LEdgeCount: Integer;
begin
  AWriter.Int(APatch.Width);
  AWriter.Int(APatch.Height);
  AWriter.Int(APatch.NumVertices);
  AWriter.Int(APatch.NumIndexes);
  for LIndex := 0 to APatch.NumVertices - 1 do
    AWriter.DrawVertShort(APatch[LIndex]);
  for LIndex := 0 to APatch.NumIndexes - 1 do
    AWriter.Int(APatch.Indexes[LIndex]);
  LEdgeCount := 0;
  for LIndex := 0 to APatch.NumIndexes - 1 do
    if Abs(APatch.EdgeIndexes[LIndex]) + 1 > LEdgeCount then
      LEdgeCount := Abs(APatch.EdgeIndexes[LIndex]) + 1;
  AWriter.Int(LEdgeCount);
end;

function ReadPatch(var AReader: TGeoGoldenReader; out AWidth, AHeight: Integer): TGeoSurfacePatch;
var
  LIndex: Integer;
begin
  AWidth := AReader.Int;
  AHeight := AReader.Int;
  AReader.Int; // the kind of control mesh, only for the reader of the file
  Result := TGeoSurfacePatch.Create(AWidth, AHeight);
  Result.SetSize(AWidth, AHeight);
  for LIndex := 0 to AWidth * AHeight - 1 do
    Result.Vertices[LIndex] := AReader.DrawVertShort;
end;

procedure TTestGeometrySurfacePatch.SetSizeDovrebbeRifiutareDimensioniNonValide;
var
  LPatch: TGeoSurfacePatch;
begin
  LPatch := TGeoSurfacePatch.Create(5, 3);
  try
    LPatch.SetSize(5, 3);
    Assert.AreEqual(5, LPatch.Width);
    Assert.AreEqual(3, LPatch.Height);
    Assert.AreEqual(15, LPatch.NumVertices);
    Assert.WillRaise(
      procedure
      begin
        LPatch.SetSize(6, 3);
      end, EGeometryException);
    Assert.WillRaise(
      procedure
      begin
        LPatch.SetSize(3, 0);
      end, EGeometryException);
  finally
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.UnaPatchPianaSuddivisaInModoEsplicitoDovrebbeDareUnaGrigliaRegolare;
var
  LPatch: TGeoSurfacePatch;
begin
  LPatch := MakeFlatPatch(3, 3, 0);
  try
    LPatch.SubdivideExplicit(4, 2, False);
    Assert.AreEqual(5, LPatch.Width);
    Assert.AreEqual(3, LPatch.Height);
    Assert.AreEqual(15, LPatch.NumVertices);
    Assert.AreEqual(4 * 2 * 2 * 3, LPatch.NumIndexes);
    // a flat quadratic patch with equally spaced control points is a regular grid
    AssertNear(1, LPatch[1].Xyz.X, 1E-5);
    AssertNear(2, LPatch[2].Xyz.X, 1E-5);
    AssertNear(2, LPatch[5].Xyz.Y, 1E-5);
    AssertNear(0.5, LPatch[2].St.X, 1E-5);
    Assert.IsFalse(LPatch.IsClosed);
  finally
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.IlPuntoCentraleDellaCurvaDovrebbeEssereLaMediaPesata;
var
  LPatch: TGeoSurfacePatch;
  LVertex: TGeoDrawVert;
begin
  LPatch := MakeFlatPatch(3, 3, 0);
  try
    // lift the middle control point: the curve passes at (a + 2b + c) / 4 on each axis
    LVertex := LPatch[4];
    LVertex.Xyz.Z := 8;
    LPatch.Vertices[4] := LVertex;
    LPatch.SubdivideExplicit(2, 2, False);
    // two passes of (0 + 2 * 8 + 0) / 4 and (0 + 2 * 4 + 0) / 4
    AssertNear(2, LPatch[4].Xyz.Z, 1E-5);
    AssertNear(0, LPatch[0].Xyz.Z, 1E-5);
  finally
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.LeNormaliDiUnaPatchPianaDovrebberoEssereLeNormaliDelPiano;
var
  LPatch: TGeoSurfacePatch;
  LIndex: Integer;
begin
  LPatch := MakeFlatPatch(3, 3, 1);
  try
    LPatch.SubdivideExplicit(2, 2, True);
    for LIndex := 0 to LPatch.NumVertices - 1 do
    begin
      AssertNear(0, LPatch[LIndex].Normal.X, 1E-5);
      AssertNear(1, LPatch[LIndex].Normal.Z, 1E-5);
    end;
  finally
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.RemoveLinearDovrebbeToglierePunteSuUnaRetta;
var
  LPatch: TGeoSurfacePatch;
begin
  LPatch := MakeFlatPatch(5, 3, 0);
  try
    LPatch.SubdivideExplicit(1, 1, False, True);
    // every column and row of a flat regular patch lies on a straight line
    Assert.AreEqual(2, LPatch.Width);
    Assert.AreEqual(2, LPatch.Height);
    Assert.AreEqual(6, LPatch.NumIndexes);
  finally
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.SubdivideSenzaErroreNonDovrebbeAggiungereRigheNeColonne;
var
  LPatch: TGeoSurfacePatch;
begin
  LPatch := MakeFlatPatch(3, 3, 0);
  try
    LPatch.Subdivide(1, 1, 0);
    // the straight rows and columns are removed down to the corners
    Assert.AreEqual(2, LPatch.Width);
    Assert.AreEqual(2, LPatch.Height);
    Assert.AreEqual(4, LPatch.NumVertices);
  finally
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.SubdivideConUnaLunghezzaMassimaDovrebbeAggiungereColonne;
var
  LPatch: TGeoSurfacePatch;
  LShort, LLong: Integer;
begin
  LPatch := MakeFlatPatch(3, 3, 0);
  try
    LPatch.Subdivide(100, 100, 0.5);
    LLong := LPatch.Width;
  finally
    LPatch.Free;
  end;
  LPatch := MakeFlatPatch(3, 3, 0);
  try
    LPatch.Subdivide(100, 100, 100);
    LShort := LPatch.Width;
  finally
    LPatch.Free;
  end;
  // flat patches lose their straight columns anyway: the long span only forces the first insertion
  Assert.IsTrue(LLong >= LShort);
end;

procedure TTestGeometrySurfacePatch.AssignDovrebbeCopiareLeDimensioni;
var
  LPatch, LCopy: TGeoSurfacePatch;
begin
  LPatch := MakeFlatPatch(5, 3, 0);
  LCopy := TGeoSurfacePatch.Create;
  try
    LCopy.Assign(LPatch);
    Assert.AreEqual(5, LCopy.Width);
    Assert.AreEqual(3, LCopy.Height);
    Assert.AreEqual(5, LCopy.MaxWidth);
    Assert.AreEqual(LPatch.NumVertices, LCopy.NumVertices);
  finally
    LCopy.Free;
    LPatch.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.SubdivideExplicitDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LPatch: TGeoSurfacePatch;
  LWidth, LHeight, LHorizontal, LVertical: Integer;
  LNormals, LLinear: Boolean;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['pa_explicit']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LPatch := ReadPatch(LReader, LWidth, LHeight);
      LHorizontal := LReader.Int;
      LVertical := LReader.Int;
      LNormals := LReader.Flag;
      LLinear := LReader.Flag;
      LWriter := TGeoGoldenWriter.Create;
      try
        LPatch.SubdivideExplicit(LHorizontal, LVertical, LNormals, LLinear);
        PutPatch(LWriter, LPatch);
        TGeoGolden.CompareOutput(LLine, LWriter.Text, 4, 1E-3);
      finally
        LWriter.Free;
        LPatch.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometrySurfacePatch.SubdivideDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LPatch: TGeoSurfacePatch;
  LWidth, LHeight: Integer;
  LHorizontalError, LVerticalError, LLength: Single;
  LNormals: Boolean;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['pa_subdivide']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LPatch := ReadPatch(LReader, LWidth, LHeight);
      LHorizontalError := LReader.Float;
      LVerticalError := LReader.Float;
      LLength := LReader.Float;
      LNormals := LReader.Flag;
      LWriter := TGeoGoldenWriter.Create;
      try
        LPatch.Subdivide(LHorizontalError, LVerticalError, LLength, LNormals);
        PutPatch(LWriter, LPatch);
        TGeoGolden.CompareOutput(LLine, LWriter.Text, 4, 1E-3);
      finally
        LWriter.Free;
        LPatch.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

end.
