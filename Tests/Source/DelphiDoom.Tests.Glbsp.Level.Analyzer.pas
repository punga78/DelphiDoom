{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the level analysis of the glbsp port                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Level.Analyzer;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Geometry,
  DelphiDoom.Glbsp.Level.Analyzer,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Raw,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Options;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspLevelAnalyzer = class(TObject)
  private
    FData: TGlbspLevelData;
    FOptions: TGlbspOptions;
    FMessages: TStringList;
    FAnalyzer: TGlbspLevelAnalyzer;
    function AddVertex(const AX, AY: Double): TGlbspVertex;
    function AddSector: TGlbspSector;
    function AddSidedef(const ASector: TGlbspSector): TGlbspSidedef;
    function AddLine(const AStart, AEnd: TGlbspVertex; const ARight,
      ALeft: TGlbspSidedef): TGlbspLinedef;
    procedure CreateAnalyzer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSegmentoAttraversaLaScatola;
    [Test]
    procedure TestSegmentoFuoriDallaScatola;
    [Test]
    procedure TestSegmentoCheToccaIlBordo;

    [Test]
    procedure TestVerticiDuplicatiPuntanoAlPrimo;
    [Test]
    procedure TestSidedefDuplicatiPuntanoAlPrimo;
    [Test]
    procedure TestSidedefSuLineaSpecialeNonSiUnisce;
    [Test]
    procedure TestSidedefSpecialiNonImpedisconoDiUnireIDuplicati;
    [Test]
    procedure TestPotaturaDelleLineeSpostaIRiferimenti;
    [Test]
    procedure TestPotaturaDeiVerticiRinumera;
    [Test]
    procedure TestPotaturaDeiSidedefAbbassaIlConteggioDelSettore;
    [Test]
    procedure TestPotaturaDeiSettori;
    [Test]
    procedure TestPotaturaSenzaLineeSollevaEccezione;

    [Test]
    procedure TestLineeSovrapposte;
    [Test]
    procedure TestWallTipSonoInOrdineDiAngolo;
    [Test]
    procedure TestVertexCheckOpenTrovaIlSettore;
    [Test]
    procedure TestPolyobjSuUnaLineaMarcaEntrambiISettori;

    [Test]
    procedure TestNuovoVerticeDaSplitConDuplicatoNormale;
    [Test]
    procedure TestNuovoVerticeDegenere;
  end;

implementation

{ TTestGlbspLevelAnalyzer }

procedure TTestGlbspLevelAnalyzer.Setup;
begin
  FData := TGlbspLevelData.Create;
  FOptions := TGlbspOptions.Default;
  FMessages := TStringList.Create;
  FAnalyzer := nil;
end;

procedure TTestGlbspLevelAnalyzer.TearDown;
begin
  FAnalyzer.Free;
  FMessages.Free;
  FData.Free;
end;

procedure TTestGlbspLevelAnalyzer.CreateAnalyzer;
begin
  FAnalyzer.Free;
  FAnalyzer := TGlbspLevelAnalyzer.Create(FData, FOptions, FMessages);
end;

function TTestGlbspLevelAnalyzer.AddVertex(const AX, AY: Double): TGlbspVertex;
begin
  Result := FData.NewVertex;
  Result.X := AX;
  Result.Y := AY;
  Result.Index := FData.Vertices.Count - 1;
end;

function TTestGlbspLevelAnalyzer.AddSector: TGlbspSector;
begin
  Result := FData.NewSector;
  Result.Index := FData.Sectors.Count - 1;
end;

function TTestGlbspLevelAnalyzer.AddSidedef(const ASector: TGlbspSector): TGlbspSidedef;
begin
  Result := FData.NewSidedef;
  Result.Sector := ASector;
  Result.Index := FData.Sidedefs.Count - 1;
  if Assigned(ASector) then
    Inc(ASector.RefCount);
end;

function TTestGlbspLevelAnalyzer.AddLine(const AStart, AEnd: TGlbspVertex; const ARight,
  ALeft: TGlbspSidedef): TGlbspLinedef;
begin
  Result := FData.NewLinedef;
  Result.Start := AStart;
  Result.EndVertex := AEnd;
  Result.Right := ARight;
  Result.Left := ALeft;
  Result.TwoSided := Assigned(ALeft);
  Result.Index := FData.Linedefs.Count - 1;
  Inc(AStart.RefCount);
  Inc(AEnd.RefCount);
  if Assigned(ARight) then
    Inc(ARight.RefCount);
  if Assigned(ALeft) then
    Inc(ALeft.RefCount);
  Result.ZeroLength := (Abs(AStart.X - AEnd.X) < DIST_EPSILON) and
    (Abs(AStart.Y - AEnd.Y) < DIST_EPSILON);
end;

procedure TTestGlbspLevelAnalyzer.TestSegmentoAttraversaLaScatola;
begin
  Assert.IsTrue(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, -50, 5, 50, 5));
  Assert.IsTrue(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, 5, -50, 5, 50));
  Assert.IsTrue(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, 2, 2, 8, 8));
end;

procedure TTestGlbspLevelAnalyzer.TestSegmentoFuoriDallaScatola;
begin
  Assert.IsFalse(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, -50, 20, 50, 20));
  Assert.IsFalse(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, 20, -5, 20, 50));
  Assert.IsFalse(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, -20, -20, -5, -5));
end;

procedure TTestGlbspLevelAnalyzer.TestSegmentoCheToccaIlBordo;
begin
  Assert.IsTrue(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, 10, 10, 30, 30));
  Assert.IsTrue(TGlbspGeometry.CheckLinedefInsideBox(0, 0, 10, 10, -10, 0, 0, 0));
end;

procedure TTestGlbspLevelAnalyzer.TestVerticiDuplicatiPuntanoAlPrimo;
begin
  AddVertex(0, 0);
  AddVertex(10, 10);
  AddVertex(0, 0);
  AddVertex(0, 0);
  CreateAnalyzer;

  FAnalyzer.DetectDuplicateVertices;

  Assert.IsNull(FData.Vertices[0].Equiv);
  Assert.IsNull(FData.Vertices[1].Equiv);
  Assert.AreSame(FData.Vertices[0], FData.Vertices[2].Equiv);
  Assert.AreSame(FData.Vertices[0], FData.Vertices[3].Equiv);
end;

procedure TTestGlbspLevelAnalyzer.TestSidedefDuplicatiPuntanoAlPrimo;
var
  LSector: TGlbspSector;
begin
  LSector := AddSector;
  AddSidedef(LSector).XOffset := 4;
  AddSidedef(LSector).XOffset := 8;
  AddSidedef(LSector).XOffset := 4;
  CreateAnalyzer;

  FAnalyzer.DetectDuplicateSidedefs;

  Assert.IsNull(FData.Sidedefs[0].Equiv);
  Assert.IsNull(FData.Sidedefs[1].Equiv);
  Assert.AreSame(FData.Sidedefs[0], FData.Sidedefs[2].Equiv);
end;

procedure TTestGlbspLevelAnalyzer.TestSidedefSuLineaSpecialeNonSiUnisce;
var
  LSector: TGlbspSector;
begin
  LSector := AddSector;
  AddSidedef(LSector);
  AddSidedef(LSector).OnSpecial := 1;
  CreateAnalyzer;

  FAnalyzer.DetectDuplicateSidedefs;

  Assert.IsNull(FData.Sidedefs[1].Equiv);
end;

// Regression (#139): glbsp 2.24 compared a sidedef on a special line by index
// with every other sidedef, which is not an order, and the duplicates around
// it were merged or not depending on the sort algorithm. Every duplicate must
// point to the first sidedef of its kind, whatever the specials in between
procedure TTestGlbspLevelAnalyzer.TestSidedefSpecialiNonImpedisconoDiUnireIDuplicati;
const
  COUNT = 300;
var
  LSectors: array[0..2] of TGlbspSector;
  LIndex, LOther: Integer;
  LSide: TGlbspSidedef;
  LFirst: TGlbspSidedef;
  LSameKind: Boolean;

  function IndexOf(const ASide: TGlbspSidedef): Integer;
  begin
    if Assigned(ASide) then
      Result := ASide.Index
    else
      Result := -1;
  end;

begin
  LSectors[0] := AddSector;
  LSectors[1] := AddSector;
  LSectors[2] := nil;
  for LIndex := 0 to COUNT - 1 do
  begin
    LSide := AddSidedef(LSectors[(LIndex * 7) mod 3]);
    LSide.XOffset := (LIndex * 5) mod 4;
    LSide.YOffset := (LIndex * 3) mod 2;
    if (LIndex mod 3) = 1 then
      LSide.OnSpecial := 1;
  end;
  CreateAnalyzer;

  FAnalyzer.DetectDuplicateSidedefs;

  for LIndex := 0 to COUNT - 1 do
  begin
    LSide := FData.Sidedefs[LIndex];
    if LSide.OnSpecial <> 0 then
    begin
      Assert.IsNull(LSide.Equiv, Format('special sidedef %d', [LIndex]));
      Continue;
    end;
    LFirst := nil;
    for LOther := 0 to LIndex - 1 do
    begin
      LSameKind := (FData.Sidedefs[LOther].OnSpecial = 0) and
        (FData.Sidedefs[LOther].Sector = LSide.Sector) and
        (FData.Sidedefs[LOther].XOffset = LSide.XOffset) and
        (FData.Sidedefs[LOther].YOffset = LSide.YOffset);
      if LSameKind then
      begin
        LFirst := FData.Sidedefs[LOther];
        Break;
      end;
    end;
    // AreSame would read a nil object to describe a failure
    Assert.IsTrue(LFirst = LSide.Equiv, Format('sidedef %d: equivalent %d instead of %d',
      [LIndex, IndexOf(LSide.Equiv), IndexOf(LFirst)]));
  end;
end;

procedure TTestGlbspLevelAnalyzer.TestPotaturaDelleLineeSpostaIRiferimenti;
var
  LSector: TGlbspSector;
  LSide0, LSide1: TGlbspSidedef;
  LV0, LV1, LV2, LV3: TGlbspVertex;
  LLine: TGlbspLinedef;
begin
  LSector := AddSector;
  LSide0 := AddSidedef(LSector);
  LSide1 := AddSidedef(LSector);
  LV0 := AddVertex(0, 0);
  LV1 := AddVertex(100, 0);
  LV2 := AddVertex(0, 0);
  LV3 := AddVertex(100, 0);
  AddLine(LV0, LV1, LSide0, nil);
  // The second line uses the duplicates of the vertices and of the sidedef
  AddLine(LV2, LV3, LSide1, nil);
  // Zero length line: removed
  AddLine(LV1, LV1, LSide0, nil);
  CreateAnalyzer;
  LSide1.Equiv := LSide0;
  LV2.Equiv := LV0;
  LV3.Equiv := LV1;

  FAnalyzer.PruneLinedefs;

  Assert.AreEqual(2, FData.Linedefs.Count);
  LLine := FData.Linedefs[1];
  Assert.AreSame(LV0, LLine.Start);
  Assert.AreSame(LV1, LLine.EndVertex);
  Assert.AreSame(LSide0, LLine.Right);
  Assert.AreEqual(1, LLine.Index);
  Assert.AreEqual(2, LV0.RefCount);
  Assert.AreEqual(2, LV1.RefCount);
  Assert.AreEqual(0, LV2.RefCount);
  Assert.AreEqual(3, LSide0.RefCount);
  Assert.AreEqual(0, LSide1.RefCount);
end;

procedure TTestGlbspLevelAnalyzer.TestPotaturaDeiVerticiRinumera;
begin
  AddVertex(0, 0).RefCount := 1;
  AddVertex(1, 1).RefCount := 0;
  AddVertex(2, 2).RefCount := 3;
  AddVertex(3, 3).RefCount := 0;
  AddVertex(4, 4).RefCount := 1;
  CreateAnalyzer;

  FAnalyzer.PruneVertices;

  Assert.AreEqual(3, FData.Vertices.Count);
  Assert.AreEqual(3, FData.NumNormalVert);
  Assert.AreEqual(0, FData.Vertices[0].Index);
  Assert.AreEqual(1, FData.Vertices[1].Index);
  Assert.AreEqual(2, FData.Vertices[2].Index);
  Assert.AreEqual(Double(4), FData.Vertices[2].X);
end;

procedure TTestGlbspLevelAnalyzer.TestPotaturaDeiSidedefAbbassaIlConteggioDelSettore;
var
  LSector: TGlbspSector;
  LUnused: TGlbspSidedef;
begin
  LSector := AddSector;
  AddSidedef(LSector).RefCount := 1;
  LUnused := AddSidedef(LSector);
  LUnused.RefCount := 0;
  CreateAnalyzer;
  Assert.AreEqual(2, LSector.RefCount);

  FAnalyzer.PruneSidedefs;

  Assert.AreEqual(1, FData.Sidedefs.Count);
  Assert.AreEqual(1, LSector.RefCount);
end;

procedure TTestGlbspLevelAnalyzer.TestPotaturaDeiSettori;
begin
  AddSector.RefCount := 0;
  AddSector.RefCount := 2;
  AddSector.RefCount := 0;
  AddSector.RefCount := 1;
  CreateAnalyzer;

  FAnalyzer.PruneSectors;

  Assert.AreEqual(2, FData.Sectors.Count);
  Assert.AreEqual(0, FData.Sectors[0].Index);
  Assert.AreEqual(1, FData.Sectors[1].Index);
  Assert.AreEqual(1, FData.Sectors[1].RefCount);
end;

procedure TTestGlbspLevelAnalyzer.TestPotaturaSenzaLineeSollevaEccezione;
var
  LVertex: TGlbspVertex;
begin
  LVertex := AddVertex(0, 0);
  AddLine(LVertex, LVertex, nil, nil);
  CreateAnalyzer;

  Assert.WillRaise(
    procedure
    begin
      FAnalyzer.PruneLinedefs;
    end, EGlbspLevelException);
end;

procedure TTestGlbspLevelAnalyzer.TestLineeSovrapposte;
var
  LV0, LV1: TGlbspVertex;
  LFirst, LSecond, LThird, LOther: TGlbspLinedef;
begin
  LV0 := AddVertex(0, 0);
  LV1 := AddVertex(100, 0);
  LFirst := AddLine(LV0, LV1, nil, nil);
  LOther := AddLine(AddVertex(0, 50), AddVertex(100, 50), nil, nil);
  // The same line in the opposite direction, then once more
  LSecond := AddLine(LV1, LV0, nil, nil);
  LThird := AddLine(LV0, LV1, nil, nil);
  CreateAnalyzer;

  FAnalyzer.DetectOverlappingLines;

  Assert.IsNull(LFirst.Overlap);
  Assert.IsNull(LOther.Overlap);
  Assert.AreSame(LFirst, LSecond.Overlap);
  Assert.AreSame(LFirst, LThird.Overlap);
end;

procedure TTestGlbspLevelAnalyzer.TestWallTipSonoInOrdineDiAngolo;
var
  LCenter: TGlbspVertex;
  LSectorA, LSectorB: TGlbspSector;
  LTip: TGlbspWallTip;
  LAngles: string;
begin
  LSectorA := AddSector;
  LSectorB := AddSector;
  LCenter := AddVertex(0, 0);
  // Three lines that leave the center to the north, the east and the west
  AddLine(LCenter, AddVertex(0, 10), AddSidedef(LSectorA), nil);
  AddLine(LCenter, AddVertex(10, 0), AddSidedef(LSectorB), nil);
  AddLine(AddVertex(-10, 0), LCenter, AddSidedef(LSectorA), AddSidedef(LSectorB));
  CreateAnalyzer;

  FAnalyzer.CalculateWallTips;

  LAngles := '';
  LTip := LCenter.TipSet;
  while Assigned(LTip) do
  begin
    LAngles := LAngles + FormatFloat('0', LTip.Angle) + ' ';
    LTip := LTip.Next;
  end;
  Assert.AreEqual('0 90 180 ', LAngles);
  // Tip to the north: left is nil, right is the sector A of the line
  Assert.AreSame(LSectorA, LCenter.TipSet.Next.Right);
  Assert.IsNull(LCenter.TipSet.Next.Left);
  // The previous links are right
  Assert.AreSame(LCenter.TipSet, LCenter.TipSet.Next.Prev);
  Assert.IsNull(LCenter.TipSet.Prev);
end;

procedure TTestGlbspLevelAnalyzer.TestVertexCheckOpenTrovaIlSettore;
var
  LCenter: TGlbspVertex;
  LSectorA, LSectorB: TGlbspSector;
begin
  LSectorA := AddSector;
  LSectorB := AddSector;
  LCenter := AddVertex(0, 0);
  // A two sided line to the east (A on the right) and one to the north
  AddLine(LCenter, AddVertex(10, 0), AddSidedef(LSectorA), AddSidedef(LSectorB));
  AddLine(LCenter, AddVertex(0, 10), AddSidedef(LSectorA), AddSidedef(LSectorB));
  CreateAnalyzer;
  FAnalyzer.CalculateWallTips;

  // A direction along a wall is closed
  Assert.IsNull(FAnalyzer.VertexCheckOpen(LCenter, 1, 0));
  // Between the east and north lines (45 degrees): on the right of the north tip
  Assert.AreSame(LSectorA, FAnalyzer.VertexCheckOpen(LCenter, 1, 1));
  // Past the last tip (south-west): on the left of the last tip
  Assert.AreSame(LSectorB, FAnalyzer.VertexCheckOpen(LCenter, -1, -1));
end;

procedure TTestGlbspLevelAnalyzer.TestPolyobjSuUnaLineaMarcaEntrambiISettori;
var
  LSectorA, LSectorB, LSectorC: TGlbspSector;
  LLine, LFar: TGlbspLinedef;
  LThing: TGlbspThing;
begin
  LSectorA := AddSector;
  LSectorB := AddSector;
  LSectorC := AddSector;
  LLine := AddLine(AddVertex(0, 0), AddVertex(100, 0), AddSidedef(LSectorA),
    AddSidedef(LSectorB));
  LLine.LineType := HEXTYPE_POLY_START;
  LFar := AddLine(AddVertex(500, 500), AddVertex(600, 500), AddSidedef(LSectorC), nil);
  LThing := FData.NewThing;
  LThing.ThingType := PO_SPAWN_TYPE;
  LThing.X := 50;
  LThing.Y := 0;
  CreateAnalyzer;

  FAnalyzer.DetectPolyobjSectors;

  Assert.AreEqual(1, LSectorA.HasPolyobj);
  Assert.AreEqual(1, LSectorB.HasPolyobj);
  Assert.AreEqual(0, LSectorC.HasPolyobj);
  Assert.IsTrue(LLine.IsPrecious);
  Assert.IsFalse(LFar.IsPrecious);
end;

procedure TTestGlbspLevelAnalyzer.TestNuovoVerticeDaSplitConDuplicatoNormale;
var
  LSeg: TGlbspSeg;
  LSector: TGlbspSector;
  LVertex: TGlbspVertex;
begin
  LSector := AddSector;
  LSeg := FData.NewSeg;
  LSeg.Sector := LSector;
  LSeg.PdX := 10;
  LSeg.PdY := 0;
  FData.DoingNormal := True;
  FData.NumNormalVert := 5;
  FData.NumGlVert := 2;
  CreateAnalyzer;

  LVertex := FAnalyzer.NewVertexFromSplitSeg(LSeg, 12.5, 7);

  // Version 2: a GL vertex plus a duplicate vertex for the normal nodes
  Assert.AreEqual(2 or IS_GL_VERTEX, LVertex.Index);
  Assert.AreEqual(3, FData.NumGlVert);
  Assert.AreEqual(6, FData.NumNormalVert);
  Assert.IsNotNull(LVertex.NormalDup);
  Assert.AreEqual(5, LVertex.NormalDup.Index);
  Assert.AreEqual(2, LVertex.RefCount);
  Assert.AreEqual(Double(12.5), LVertex.NormalDup.X);
  // Two wall tips: toward the east (0 degrees) and toward the west (180)
  Assert.AreEqual(Double(0), LVertex.TipSet.Angle, 1E-9);
  Assert.AreEqual(Double(180), LVertex.TipSet.Next.Angle, 1E-9);
end;

procedure TTestGlbspLevelAnalyzer.TestNuovoVerticeDegenere;
var
  LStart, LEnd, LVertex: TGlbspVertex;
begin
  LStart := AddVertex(0, 0);
  LEnd := AddVertex(3, 0);
  FData.DoingNormal := True;
  FData.NumNormalVert := 2;
  LStart.RefCount := 2;
  CreateAnalyzer;

  LVertex := FAnalyzer.NewVertexDegenerate(LStart, LEnd);

  // It moves along the direction of the seg until it rounds to another point
  Assert.AreEqual(Double(1), LVertex.X);
  Assert.AreEqual(Double(0), LVertex.Y);
  Assert.AreEqual(2, LVertex.Index);
  Assert.AreEqual(3, FData.NumNormalVert);
  Assert.AreEqual(2, LVertex.RefCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspLevelAnalyzer);

end.
