{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - sampling an .aas file, with the }
{  parity of the real AASFile_sample.cpp of Doom 3 (aas_query.golden.txt)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.AasSampler;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3,
  DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestAasSampler = class
  strict private
    FFile: TAasFile;
    FSampler: IAasSampler;
    function DataFolder: string;
    function LoadFile(const AName: string): TAasFile;
    procedure Use(const AName: string);
    procedure RunQueries(const AOutput: TStrings);
    function GoldenBlock(const ALines: TStringList; const ACase: string): TStringList;
    function Bits(const AValue: Single): string;
    function VectorBits(const ATag: string; const AValue: TGeoVec3): string;
    function BuildChainFile(const ALength: Integer): TAasFile;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdlib;
    [Test]
    procedure DovrebbeTrovareLAreaDiUnPunto;
    [Test]
    procedure DovrebbeDareZeroPerUnPuntoNelSolido;
    [Test]
    procedure DovrebbeDareIlCentroSeLAreaNonERaggiungibile;
    [Test]
    procedure DovrebbeDareIlCentroDelPavimentoSullaTraccia;
    [Test]
    procedure DovrebbeFermareLaTracciaSuUnAreaVietata;
    [Test]
    procedure DovrebbeUscireDalSolidoSeRichiesto;
    [Test]
    procedure DovrebbeRegistrareLeAreeAttraversateFinoAlMassimo;
    [Test]
    procedure DovrebbeSpingereUnPuntoDentroLArea;
    [Test]
    procedure DovrebbeCercareUnAreaPerIBounds;
    [Test]
    procedure DovrebbeCercareUnAreaRaggiungibileAttornoAlPunto;
    [Test]
    procedure DovrebbeRifiutareUnNodoCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnAreaCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnaPilaDiTracciaTroppoAlta;
    [Test]
    procedure DovrebbeRifiutareUnAlberoPiuProfondoDeiNodi;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.Trace,
  DelphiDoom.MapFile.Aas.Factory, DelphiDoom.MapFile.Aas.Sampler;

var
  GPoints: array[0..7] of TGeoVec3;

{ TTestAasSampler }

function TTestAasSampler.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\MapFile\');
end;

function TTestAasSampler.LoadFile(const AName: string): TAasFile;
var
  LBytes: TBytes;
  LText: AnsiString;
begin
  Assert.IsTrue(TFile.Exists(DataFolder + AName), AName + ' not found in ' + DataFolder);
  LBytes := TFile.ReadAllBytes(DataFolder + AName);
  SetLength(LText, Length(LBytes));
  Move(LBytes[0], LText[1], Length(LBytes));
  Result := TAasFileFactory.CreateReader(nil).ParseText(LText, AnsiString(AName));
end;

procedure TTestAasSampler.Use(const AName: string);
begin
  FSampler := nil;
  FFile.Free;
  FFile := LoadFile(AName);
  FSampler := TAasFileFactory.CreateSampler(FFile);
end;

procedure TTestAasSampler.TearDown;
begin
  FSampler := nil;
  FFile.Free;
  FFile := nil;
end;

function TTestAasSampler.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := '#' + LowerCase(IntToHex(PCardinal(@LValue)^, 8));
end;

function TTestAasSampler.VectorBits(const ATag: string; const AValue: TGeoVec3): string;
begin
  Result := Format('%s %s %s %s', [ATag, Bits(AValue.X), Bits(AValue.Y), Bits(AValue.Z)]);
end;

procedure TTestAasSampler.RunQueries(const AOutput: TStrings);
const
  FLAGS: array[0..3] of Integer = (0, 0, AREA_LIQUID, 0);
  TRAVEL: array[0..3] of Integer = (0, 0, 0, TFL_WATER);
  OUT_OF_SOLID: array[0..3] of Boolean = (False, True, False, True);
  MAX_AREAS: array[0..3] of Integer = (0, 8, 8, 2);
var
  LAreaCount, LIndex, LPoint, LFrom, LTo, LVariant, LArea: Integer;
  LSearch, LBounds: TGeoBounds;
  LPush: TGeoVec3;
  LTrace: TAasTrace;
  LHit: Boolean;
begin
  LAreaCount := FFile.NumAreas;
  LSearch := TGeoBounds.Make(TGeoVec3.Make(-64, -64, -64), TGeoVec3.Make(64, 64, 64));
  for LIndex := 0 to LAreaCount - 1 do
    AOutput.Add(VectorBits(Format('G %d', [LIndex]), FSampler.AreaReachableGoal(LIndex)));
  for LPoint := 0 to 7 do
  begin
    AOutput.Add(Format('PA %d %d', [LPoint, FSampler.PointAreaNum(GPoints[LPoint])]));
    AOutput.Add(Format('PR %d %d %d %d', [LPoint,
      FSampler.PointReachableAreaNum(GPoints[LPoint], LSearch, AREA_REACHABLE_WALK, 0),
      FSampler.PointReachableAreaNum(GPoints[LPoint], LSearch, AREA_FLOOR, TFL_WATER),
      FSampler.PointReachableAreaNum(GPoints[LPoint], LSearch, $FF, 0)]));
    LBounds := TGeoBounds.Make(GPoints[LPoint] - TGeoVec3.Make(16, 16, 16),
      GPoints[LPoint] + TGeoVec3.Make(16, 16, 16));
    AOutput.Add(Format('BR %d %d %d', [LPoint, FSampler.BoundsReachableAreaNum(LBounds, AREA_FLOOR, 0),
      FSampler.BoundsReachableAreaNum(LBounds, AREA_FLOOR, TFL_WATER)]));
  end;
  for LIndex := 0 to LAreaCount - 1 do
    for LPoint := 0 to 7 do
    begin
      LPush := GPoints[LPoint];
      FSampler.PushPointIntoAreaNum(LIndex, LPush);
      AOutput.Add(VectorBits(Format('PU %d %d', [LIndex, LPoint]), LPush));
    end;
  for LFrom := 0 to 7 do
    for LTo := 0 to 7 do
    begin
      if LFrom = LTo then
        Continue;
      for LVariant := 0 to 3 do
      begin
        LTrace := TAasTrace.Init;
        LTrace.Flags := FLAGS[LVariant];
        LTrace.TravelFlags := TRAVEL[LVariant];
        LTrace.GetOutOfSolid := OUT_OF_SOLID[LVariant];
        LTrace.MaxAreas := MAX_AREAS[LVariant];
        if MAX_AREAS[LVariant] > 0 then
        begin
          SetLength(LTrace.Areas, 8);
          SetLength(LTrace.Points, 8);
        end;
        LHit := FSampler.Trace(LTrace, GPoints[LFrom], GPoints[LTo]);
        AOutput.Add(Format('TR %d %d %d %d %s %s %s %s %d %d %d %d', [LFrom, LTo, LVariant, Ord(LHit),
          Bits(LTrace.Fraction), Bits(LTrace.EndPos.X), Bits(LTrace.EndPos.Y), Bits(LTrace.EndPos.Z),
          LTrace.PlaneNum, LTrace.LastAreaNum, LTrace.BlockingAreaNum, LTrace.NumAreas]));
        for LArea := 0 to LTrace.NumAreas - 1 do
          AOutput.Add(VectorBits(Format('TA %d %d', [LTrace.Areas[LArea], LArea]), LTrace.Points[LArea]));
      end;
    end;
end;

function TTestAasSampler.GoldenBlock(const ALines: TStringList; const ACase: string): TStringList;
var
  LIndex: Integer;
  LInCase: Boolean;
begin
  Result := TStringList.Create;
  LInCase := False;
  for LIndex := 0 to ALines.Count - 1 do
    if ALines[LIndex].StartsWith('CASE ') then
      LInCase := ALines[LIndex] = 'CASE ' + ACase
    else if LInCase then
      Result.Add(ALines[LIndex]);
end;

procedure TTestAasSampler.DovrebbeDareLeStesseRisposteDelVeroIdlib;
var
  LGolden, LExpected, LActual: TStringList;
  LCase: string;
  LIndex: Integer;
begin
  LGolden := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + 'aas_query.golden.txt'), 'aas_query.golden.txt not found');
    LGolden.LoadFromFile(DataFolder + 'aas_query.golden.txt');
    // aas_minimal.aas has no tree and is not sampled
    for LCase in ['aas_rooms.aas', 'aas_walk.aas'] do
    begin
      Use(LCase);
      LExpected := GoldenBlock(LGolden, LCase);
      LActual := TStringList.Create;
      try
        RunQueries(LActual);
        Assert.IsTrue(LExpected.Count > 400, 'no golden lines for ' + LCase);
        if LExpected.Text <> LActual.Text then
          LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.' + LCase + '.actual.txt'));
        Assert.AreEqual<Integer>(LExpected.Count, LActual.Count, LCase + ': number of lines');
        for LIndex := 0 to LExpected.Count - 1 do
          Assert.AreEqual(LExpected[LIndex], LActual[LIndex], Format('%s line %d', [LCase, LIndex + 1]));
      finally
        LActual.Free;
        LExpected.Free;
      end;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestAasSampler.DovrebbeTrovareLAreaDiUnPunto;
begin
  Use('aas_walk.aas');
  Assert.AreEqual<Integer>(1, FSampler.PointAreaNum(TGeoVec3.Make(32, 32, 32)));
  Assert.AreEqual<Integer>(2, FSampler.PointAreaNum(TGeoVec3.Make(96, 32, 32)));
  Assert.AreEqual<Integer>(3, FSampler.PointAreaNum(TGeoVec3.Make(160, 32, 32)));
end;

procedure TTestAasSampler.DovrebbeDareZeroPerUnPuntoNelSolido;
begin
  Use('aas_walk.aas');
  Assert.AreEqual<Integer>(0, FSampler.PointAreaNum(TGeoVec3.Make(-30, 32, 10)));
  Assert.AreEqual<Integer>(0, FSampler.PointAreaNum(TGeoVec3.Make(250, 32, 10)));
end;

procedure TTestAasSampler.DovrebbeDareIlCentroSeLAreaNonERaggiungibile;
var
  LGoal: TGeoVec3;
begin
  Use('aas_walk.aas');
  // the area 3 is liquid, the area 0 has no faces
  LGoal := FSampler.AreaReachableGoal(3);
  Assert.AreEqual<Single>(160, LGoal.X);
  Assert.AreEqual<Single>(32, LGoal.Y);
  Assert.AreEqual<Single>(32, LGoal.Z);
  LGoal := FSampler.AreaReachableGoal(0);
  Assert.AreEqual<Single>(0, LGoal.X);
end;

procedure TTestAasSampler.DovrebbeDareIlCentroDelPavimentoSullaTraccia;
var
  LGoal: TGeoVec3;
begin
  Use('aas_walk.aas');
  // the centre of the floor is (32, 32, 0); the trace from one unit above goes down through
  // area 1 to the end of the tree and stops at the last point of the line (z = -1023)
  LGoal := FSampler.AreaReachableGoal(1);
  Assert.AreEqual<Single>(32, LGoal.X);
  Assert.AreEqual<Single>(32, LGoal.Y);
  Assert.AreEqual<Single>(-1023, LGoal.Z);
end;

procedure TTestAasSampler.DovrebbeFermareLaTracciaSuUnAreaVietata;
var
  LTrace: TAasTrace;
begin
  Use('aas_walk.aas');
  LTrace := TAasTrace.Init;
  LTrace.Flags := AREA_LIQUID;
  Assert.IsTrue(FSampler.Trace(LTrace, TGeoVec3.Make(32, 32, 32), TGeoVec3.Make(160, 32, 32)));
  Assert.AreEqual<Integer>(3, LTrace.BlockingAreaNum);
  Assert.AreEqual<Integer>(2, LTrace.LastAreaNum);
  Assert.IsTrue((LTrace.Fraction > 0.5) and (LTrace.Fraction < 1));
  Assert.AreEqual<Integer>(0, LTrace.NumAreas);
  // the same trace by travel flags: the area 3 has TFL_WATER
  LTrace := TAasTrace.Init;
  LTrace.TravelFlags := TFL_WATER;
  Assert.IsTrue(FSampler.Trace(LTrace, TGeoVec3.Make(32, 32, 32), TGeoVec3.Make(160, 32, 32)));
  Assert.AreEqual<Integer>(3, LTrace.BlockingAreaNum);
  // a trace that is not blocked reaches its end
  LTrace := TAasTrace.Init;
  Assert.IsFalse(FSampler.Trace(LTrace, TGeoVec3.Make(32, 32, 32), TGeoVec3.Make(160, 32, 32)));
  Assert.AreEqual<Single>(1, LTrace.Fraction);
  Assert.AreEqual<Integer>(3, LTrace.LastAreaNum);
  Assert.AreEqual<Single>(160, LTrace.EndPos.X);
end;

procedure TTestAasSampler.DovrebbeUscireDalSolidoSeRichiesto;
var
  LTrace: TAasTrace;
begin
  Use('aas_walk.aas');
  LTrace := TAasTrace.Init;
  Assert.IsTrue(FSampler.Trace(LTrace, TGeoVec3.Make(-30, 32, 10), TGeoVec3.Make(96, 32, 10)));
  Assert.AreEqual<Single>(0, LTrace.Fraction);
  Assert.AreEqual<Integer>(0, LTrace.BlockingAreaNum);
  Assert.AreEqual<Integer>(0, LTrace.LastAreaNum);
  LTrace := TAasTrace.Init;
  LTrace.GetOutOfSolid := True;
  Assert.IsFalse(FSampler.Trace(LTrace, TGeoVec3.Make(-30, 32, 10), TGeoVec3.Make(96, 32, 10)));
  Assert.AreEqual<Integer>(2, LTrace.LastAreaNum);
  Assert.AreEqual<Single>(1, LTrace.Fraction);
  // a trace that never leaves the solid does not complete
  LTrace := TAasTrace.Init;
  LTrace.GetOutOfSolid := True;
  Assert.IsFalse(FSampler.Trace(LTrace, TGeoVec3.Make(-30, 32, 10), TGeoVec3.Make(-60, 32, 10)));
  Assert.AreEqual<Single>(0, LTrace.Fraction);
  Assert.AreEqual<Single>(-30, LTrace.EndPos.X);
end;

procedure TTestAasSampler.DovrebbeRegistrareLeAreeAttraversateFinoAlMassimo;
var
  LTrace: TAasTrace;
begin
  Use('aas_walk.aas');
  LTrace := TAasTrace.Init;
  LTrace.MaxAreas := 2;
  SetLength(LTrace.Areas, 2);
  SetLength(LTrace.Points, 2);
  FSampler.Trace(LTrace, TGeoVec3.Make(32, 32, 32), TGeoVec3.Make(160, 32, 32));
  Assert.AreEqual<Integer>(2, LTrace.NumAreas);
  Assert.AreEqual<Integer>(1, LTrace.Areas[0]);
  Assert.AreEqual<Integer>(2, LTrace.Areas[1]);
  Assert.AreEqual<Single>(32, LTrace.Points[0].X);
  // the arrays may be shorter than MaxAreas: the count goes on, nothing is stored past the end
  LTrace := TAasTrace.Init;
  LTrace.MaxAreas := 8;
  SetLength(LTrace.Areas, 1);
  FSampler.Trace(LTrace, TGeoVec3.Make(32, 32, 32), TGeoVec3.Make(160, 32, 32));
  Assert.AreEqual<Integer>(3, LTrace.NumAreas);
  Assert.AreEqual<Integer>(1, LTrace.Areas[0]);
end;

procedure TTestAasSampler.DovrebbeSpingereUnPuntoDentroLArea;
var
  LPoint: TGeoVec3;
begin
  Use('aas_walk.aas');
  // a point in front of every plane of the faces of the area 1 does not move
  LPoint := TGeoVec3.Make(200, 100, 100);
  FSampler.PushPointIntoAreaNum(1, LPoint);
  Assert.AreEqual<Single>(200, LPoint.X);
  Assert.AreEqual<Single>(100, LPoint.Y);
  Assert.AreEqual<Single>(100, LPoint.Z);
  // the planes of the file face outwards from x = 0 and the faces are taken in turn: each plane
  // that has the point behind it moves it onto itself (x = 64, then 192, y = 64, z = 64)
  LPoint := TGeoVec3.Make(-30, 32, 32);
  FSampler.PushPointIntoAreaNum(1, LPoint);
  Assert.AreEqual<Single>(192, LPoint.X);
  Assert.AreEqual<Single>(64, LPoint.Y);
  Assert.AreEqual<Single>(64, LPoint.Z);
end;

procedure TTestAasSampler.DovrebbeCercareUnAreaPerIBounds;
begin
  Use('aas_walk.aas');
  Assert.AreEqual<Integer>(2, FSampler.BoundsReachableAreaNum(
    TGeoBounds.Make(TGeoVec3.Make(80, 20, 20), TGeoVec3.Make(110, 40, 40)), AREA_FLOOR, 0));
  // a box that crosses the plane of x = 64 gives the first suitable area at the back
  Assert.AreEqual<Integer>(1, FSampler.BoundsReachableAreaNum(
    TGeoBounds.Make(TGeoVec3.Make(50, 20, 20), TGeoVec3.Make(80, 40, 40)), AREA_FLOOR, 0));
  // the water area is excluded by its travel flags, no area has the flag 0x8000
  Assert.AreEqual<Integer>(0, FSampler.BoundsReachableAreaNum(
    TGeoBounds.Make(TGeoVec3.Make(150, 20, 20), TGeoVec3.Make(170, 40, 40)), AREA_FLOOR, TFL_WATER));
  Assert.AreEqual<Integer>(0, FSampler.BoundsReachableAreaNum(
    TGeoBounds.Make(TGeoVec3.Make(80, 20, 20), TGeoVec3.Make(110, 40, 40)), $8000, 0));
end;

procedure TTestAasSampler.DovrebbeCercareUnAreaRaggiungibileAttornoAlPunto;
var
  LSearch: TGeoBounds;
begin
  Use('aas_walk.aas');
  LSearch := TGeoBounds.Make(TGeoVec3.Make(-64, -64, -64), TGeoVec3.Make(64, 64, 64));
  // a point in an area that has the flags
  Assert.AreEqual<Integer>(2, FSampler.PointReachableAreaNum(TGeoVec3.Make(96, 32, 32), LSearch,
    AREA_REACHABLE_WALK, 0));
  // in solid, close to the first area: the search box grows until it finds it
  Assert.AreEqual<Integer>(1, FSampler.PointReachableAreaNum(TGeoVec3.Make(-30, 32, 10), LSearch,
    AREA_REACHABLE_WALK, 0));
  // nothing has the flag: no area
  Assert.AreEqual<Integer>(0, FSampler.PointReachableAreaNum(TGeoVec3.Make(96, 32, 32), LSearch, $8000, 0));
end;

procedure TTestAasSampler.DovrebbeRifiutareUnNodoCheNonEsiste;
var
  LFile: TAasFile;
  LSampler: IAasSampler;
  LRaised: Boolean;
begin
  LFile := TAasFile.Create;
  try
    LSampler := TAasFileFactory.CreateSampler(LFile);
    LRaised := False;
    try
      LSampler.PointAreaNum(TGeoVec3.Origin);
    except
      on E: EAasFileException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'no node 1');
    // a node with a plane that is not in the list
    LFile.Nodes := [Default(TAasNode), Default(TAasNode)];
    LFile.Nodes[1].PlaneNum := 4;
    LRaised := False;
    try
      LSampler.PointAreaNum(TGeoVec3.Origin);
    except
      on E: EAasFileException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'no plane 4');
  finally
    LSampler := nil;
    LFile.Free;
  end;
end;

procedure TTestAasSampler.DovrebbeRifiutareUnAreaCheNonEsiste;
var
  LRaised: Boolean;
begin
  Use('aas_walk.aas');
  LRaised := False;
  try
    FSampler.AreaReachableGoal(9);
  except
    on E: EAasFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  LRaised := False;
  try
    FSampler.PushPointIntoAreaNum(-1, GPoints[0]);
  except
    on E: EAasFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

function TTestAasSampler.BuildChainFile(const ALength: Integer): TAasFile;
var
  LNodes: TArray<TAasNode>;
  LIndex: Integer;
  LPlanes: TArray<TGeoPlane>;
begin
  Result := TAasFile.Create;
  SetLength(LPlanes, ALength + 2);
  LPlanes[0] := TGeoPlane.Make(0, 0, 0, 0);
  // plane k is x = 127 - k / 2: a line from 0 to 128 is cut by each one in turn and its
  // start part (that ends 1/8 before the plane) still crosses the next plane
  for LIndex := 1 to ALength + 1 do
    LPlanes[LIndex] := TGeoPlane.Make(1, 0, 0, -(127 - (LIndex - 1) * 0.5));
  Result.Planes := LPlanes;
  Result.Areas.Add(TAasArea.Create);
  Result.Areas.Add(TAasArea.Create);
  SetLength(LNodes, ALength + 2);
  // node i has the same child at both sides
  for LIndex := 1 to ALength + 1 do
  begin
    LNodes[LIndex].PlaneNum := LIndex;
    LNodes[LIndex].Children[0] := LIndex + 1;
    LNodes[LIndex].Children[1] := LIndex + 1;
  end;
  LNodes[ALength + 1].Children[0] := -1;
  LNodes[ALength + 1].Children[1] := -1;
  Result.Nodes := LNodes;
end;

procedure TTestAasSampler.DovrebbeRifiutareUnaPilaDiTracciaTroppoAlta;
var
  LFile: TAasFile;
  LSampler: IAasSampler;
  LTrace: TAasTrace;
  LRaised: Boolean;
begin
  LFile := BuildChainFile(MAX_AAS_TREE_DEPTH + 2);
  try
    LSampler := TAasFileFactory.CreateSampler(LFile);
    LTrace := TAasTrace.Init;
    LRaised := False;
    try
      LSampler.Trace(LTrace, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(128, 0, 0));
    except
      on E: EAasFileException do
        LRaised := E.Message.Contains('stack overflow');
    end;
    Assert.IsTrue(LRaised);
  finally
    LSampler := nil;
    LFile.Free;
  end;
end;

procedure TTestAasSampler.DovrebbeRifiutareUnAlberoPiuProfondoDeiNodi;
var
  LFile: TAasFile;
  LSampler: IAasSampler;
  LRaised: Boolean;
begin
  LFile := TAasFile.Create;
  try
    // a node that is its own child: with a box that crosses its plane the recursion would not end
    LFile.Planes := [TGeoPlane.Make(0, 0, 0, 0), TGeoPlane.Make(1, 0, 0, -64)];
    LFile.Areas.Add(TAasArea.Create);
    LFile.Nodes := [Default(TAasNode), Default(TAasNode)];
    LFile.Nodes[1].PlaneNum := 1;
    LFile.Nodes[1].Children[0] := 1;
    LFile.Nodes[1].Children[1] := 1;
    LSampler := TAasFileFactory.CreateSampler(LFile);
    LRaised := False;
    try
      LSampler.BoundsReachableAreaNum(TGeoBounds.Make(TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(128, 1, 1)), 1, 0);
    except
      on E: EAasFileException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LSampler := nil;
    LFile.Free;
  end;
end;

initialization
  GPoints[0] := TGeoVec3.Make(32, 32, 32);
  GPoints[1] := TGeoVec3.Make(96, 32, 32);
  GPoints[2] := TGeoVec3.Make(160, 32, 32);
  GPoints[3] := TGeoVec3.Make(-30, 32, 10);
  GPoints[4] := TGeoVec3.Make(250, 32, 10);
  GPoints[5] := TGeoVec3.Make(96, 32, -100);
  GPoints[6] := TGeoVec3.Make(64.05, 32, 32);
  GPoints[7] := TGeoVec3.Make(190, 10, 20);

end.
