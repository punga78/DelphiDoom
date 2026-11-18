{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map utility rules of p_maputl                      }
{                                                                              }
{  The rules are the static methods of TMapUtilRoutines (the text of the old   }
{  free routines of commit 5adaf6fb9). The oracles are written here from the   }
{  meaning of the routine (a cross product in 64 bits, the box corners), not   }
{  copied from the unit.                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Rules.MapUtil;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Types,
  m_fixed,
  p_mobj_h,
  p_map,
  r_defs,
  p_setup,
  p_maputl;

type
  [TestFixture]
  [Category('rules')]
  TTestRulesMapUtil = class
  strict private
    FVertices: array[0..1] of vertex_t;
    FLine: line_t;
    FSectors: array[0..3] of sector_t;
    FThing: mobj_t;
    FSeed: Cardinal;
    function NextRandom(const ARange: Integer): Integer;
    procedure MakeLine(const AX1, AY1, AX2, AY2: fixed_t);
    function ReferenceSide(const AX, AY: fixed_t): Integer;
    procedure MakeSector(const AIndex: Integer; const AFloor, ACeiling: fixed_t; const AFloorPic: Integer);
    procedure MakeTwoSidedLine(const AFront, ABack: Integer);
    class function ShiftRight16(const AValue: Int64): Int64; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeStimareLaDistanzaConIlMinoreDimezzato;
    [Test]
    procedure DovrebbeDareLaDistanzaSimmetricaESenzaSegno;
    [Test]
    procedure DovrebbeSaturareLaDistanzaSuUnaMappaGrande;
    [Test]
    procedure DovrebbeDareLoStessoLatoDelProdottoVettorialeSuLineeObblique;
    [Test]
    procedure DovrebbeDareLatoZeroOUnoSuLineeVerticaliEOrizzontali;
    [Test]
    procedure DovrebbeDareIlLatoDellaScatolaDaUnaParteDiUnaLineaOrizzontale;
    [Test]
    procedure DovrebbeDareMenoUnoSeLaScatolaAttraversaLaLinea;
    [Test]
    procedure DovrebbeDareIlLatoDellaScatolaSuLineeObblique;
    [Test]
    procedure DovrebbeDareApertura0SuUnaLineaAUnSoloLato;
    [Test]
    procedure DovrebbeUsareIlSoffittoPiuBassoEIlPavimentoPiuAltoNellApertura;
    [Test]
    procedure DovrebbeSceglierePavimentoEFlatDelLatoPiuAlto;
    [Test]
    procedure DovrebbeAbbassareIlSoffittoConUnPianoIntermedioSopraLaCosa;
    [Test]
    procedure DovrebbeAlzareIlPavimentoConUnPianoIntermedioSottoLaCosa;
    [Test]
    procedure DovrebbeAlzareIlPavimentoBassoConUnPianoIntermedioQuandoQuelloAltoEPiuInAlto;
    [Test]
    procedure DovrebbeIgnorareIPianiIntermediSenzaIlControlloDei3dFloor;
  end;

implementation

const
  SeedStart = 20261118;

{ TTestRulesMapUtil }

procedure TTestRulesMapUtil.Setup;
begin
  FSeed := SeedStart;
  largemap := False;
end;

procedure TTestRulesMapUtil.TearDown;
begin
  largemap := False;
end;

function TTestRulesMapUtil.NextRandom(const ARange: Integer): Integer;
begin
  FSeed := FSeed * 1664525 + 1013904223;
  Result := Integer(FSeed shr 8) mod ARange;
end;

procedure TTestRulesMapUtil.MakeLine(const AX1, AY1, AX2, AY2: fixed_t);
begin
  FillChar(FLine, SizeOf(FLine), 0);
  FVertices[0].x := AX1;
  FVertices[0].y := AY1;
  FVertices[1].x := AX2;
  FVertices[1].y := AY2;
  FLine.v1 := @FVertices[0];
  FLine.v2 := @FVertices[1];
  FLine.dx := AX2 - AX1;
  FLine.dy := AY2 - AY1;
  if FLine.dx = 0 then
    FLine.slopetype := ST_VERTICAL
  else if FLine.dy = 0 then
    FLine.slopetype := ST_HORIZONTAL
  else if (FLine.dy > 0) = (FLine.dx > 0) then
    FLine.slopetype := ST_POSITIVE
  else
    FLine.slopetype := ST_NEGATIVE;
end;

// An arithmetic shift right by 16 (the engine's sar), written as a floor division to be independent of it
class function TTestRulesMapUtil.ShiftRight16(const AValue: Int64): Int64;
begin
  Result := AValue div 65536;
  if (AValue < 0) and (AValue mod 65536 <> 0) then
    Dec(Result);
end;

// The point is on the back side (1) when the cross product is not on the front side: the same comparison of the
// engine, in 64 bits, on the two terms that the engine computes with a fixed point multiplication
function TTestRulesMapUtil.ReferenceSide(const AX, AY: fixed_t): Integer;
var
  LLeft: Integer;
  LRight: Integer;
begin
  LLeft := Integer(ShiftRight16(ShiftRight16(FLine.dy) * (AX - FLine.v1.x)));
  LRight := Integer(ShiftRight16(Int64(AY - FLine.v1.y) * ShiftRight16(FLine.dx)));
  if LRight < LLeft then
    Result := 0
  else
    Result := 1;
end;

procedure TTestRulesMapUtil.MakeSector(const AIndex: Integer; const AFloor, ACeiling: fixed_t; const AFloorPic: Integer);
begin
  FSectors[AIndex].floorheight := AFloor;
  FSectors[AIndex].ceilingheight := ACeiling;
  FSectors[AIndex].floorpic := AFloorPic;
  FSectors[AIndex].midsec := -1;
end;

procedure TTestRulesMapUtil.MakeTwoSidedLine(const AFront, ABack: Integer);
begin
  MakeLine(0, 0, 64 * FRACUNIT, 0);
  FLine.sidenum[0] := 0;
  FLine.sidenum[1] := 1;
  FLine.frontsector := @FSectors[AFront];
  FLine.backsector := @FSectors[ABack];
end;

procedure TTestRulesMapUtil.DovrebbeStimareLaDistanzaConIlMinoreDimezzato;
begin
  // 3 + 4 - 3 / 2 = 6
  Assert.AreEqual(6, TMapUtilRoutines.P_AproxDistance(3, 4));
  Assert.AreEqual(6, TMapUtilRoutines.P_AproxDistance(4, 3));
  Assert.AreEqual(0, TMapUtilRoutines.P_AproxDistance(0, 0));
  Assert.AreEqual(100 * FRACUNIT, TMapUtilRoutines.P_AproxDistance(100 * FRACUNIT, 0));
  Assert.AreEqual(150 * FRACUNIT, TMapUtilRoutines.P_AproxDistance(100 * FRACUNIT, 100 * FRACUNIT));
end;

procedure TTestRulesMapUtil.DovrebbeDareLaDistanzaSimmetricaESenzaSegno;
var
  LIndex: Integer;
  LDx: Integer;
  LDy: Integer;
begin
  for LIndex := 1 to 500 do
  begin
    LDx := NextRandom(2000 * FRACUNIT) - 1000 * FRACUNIT;
    LDy := NextRandom(2000 * FRACUNIT) - 1000 * FRACUNIT;
    Assert.AreEqual(TMapUtilRoutines.P_AproxDistance(LDx, LDy), TMapUtilRoutines.P_AproxDistance(LDy, LDx));
    Assert.AreEqual(TMapUtilRoutines.P_AproxDistance(LDx, LDy), TMapUtilRoutines.P_AproxDistance(-LDx, -LDy));
    Assert.IsTrue(TMapUtilRoutines.P_AproxDistance(LDx, LDy) >= 0);
  end;
end;

procedure TTestRulesMapUtil.DovrebbeSaturareLaDistanzaSuUnaMappaGrande;
begin
  largemap := True;
  // the 64 bit sum is not cut: 3 + 4 / 2 for the larger and half the smaller
  Assert.AreEqual(5, TMapUtilRoutines.P_AproxDistance(3, 4));
  Assert.AreEqual(MaxInt, TMapUtilRoutines.P_AproxDistance(MaxInt, MaxInt));
  Assert.AreEqual(MaxInt, TMapUtilRoutines.P_AproxDistance(MaxInt, 1000));
end;

procedure TTestRulesMapUtil.DovrebbeDareLoStessoLatoDelProdottoVettorialeSuLineeObblique;
var
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
begin
  for LIndex := 1 to 2000 do
  begin
    MakeLine(
      (NextRandom(400) - 200) * FRACUNIT, (NextRandom(400) - 200) * FRACUNIT,
      (NextRandom(400) - 200) * FRACUNIT, (NextRandom(400) - 200) * FRACUNIT);
    if (FLine.dx = 0) or (FLine.dy = 0) then
      Continue;
    LX := (NextRandom(600) - 300) * FRACUNIT + NextRandom(FRACUNIT);
    LY := (NextRandom(600) - 300) * FRACUNIT + NextRandom(FRACUNIT);
    Assert.AreEqual(ReferenceSide(LX, LY), TMapUtilRoutines.P_PointOnLineSide(LX, LY, @FLine));
  end;
end;

procedure TTestRulesMapUtil.DovrebbeDareLatoZeroOUnoSuLineeVerticaliEOrizzontali;
begin
  // vertical, going up: the front is on the left... the engine says 1 for x <= v1.x when dy > 0
  MakeLine(0, 0, 0, 64 * FRACUNIT);
  Assert.AreEqual(1, TMapUtilRoutines.P_PointOnLineSide(-FRACUNIT, 10, @FLine));
  Assert.AreEqual(1, TMapUtilRoutines.P_PointOnLineSide(0, 10, @FLine));
  Assert.AreEqual(0, TMapUtilRoutines.P_PointOnLineSide(FRACUNIT, 10, @FLine));
  // the same line, reversed
  MakeLine(0, 64 * FRACUNIT, 0, 0);
  Assert.AreEqual(0, TMapUtilRoutines.P_PointOnLineSide(-FRACUNIT, 10, @FLine));
  Assert.AreEqual(1, TMapUtilRoutines.P_PointOnLineSide(FRACUNIT, 10, @FLine));
  // horizontal, going right: the points above are on the back side (1)
  MakeLine(0, 0, 64 * FRACUNIT, 0);
  Assert.AreEqual(1, TMapUtilRoutines.P_PointOnLineSide(10, FRACUNIT, @FLine));
  Assert.AreEqual(0, TMapUtilRoutines.P_PointOnLineSide(10, 0, @FLine));
  Assert.AreEqual(0, TMapUtilRoutines.P_PointOnLineSide(10, -FRACUNIT, @FLine));
  // horizontal, going left
  MakeLine(64 * FRACUNIT, 0, 0, 0);
  Assert.AreEqual(0, TMapUtilRoutines.P_PointOnLineSide(10, FRACUNIT, @FLine));
  Assert.AreEqual(1, TMapUtilRoutines.P_PointOnLineSide(10, -FRACUNIT, @FLine));
end;

procedure TTestRulesMapUtil.DovrebbeDareIlLatoDellaScatolaDaUnaParteDiUnaLineaOrizzontale;
var
  LBox: array[0..3] of fixed_t;
begin
  MakeLine(0, 0, 64 * FRACUNIT, 0);
  // BOX_TOP, BOX_BOTTOM, BOX_LEFT, BOX_RIGHT
  LBox[BOX_TOP] := 40 * FRACUNIT;
  LBox[BOX_BOTTOM] := 10 * FRACUNIT;
  LBox[BOX_LEFT] := 0;
  LBox[BOX_RIGHT] := 20 * FRACUNIT;
  Assert.AreEqual(1, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
  LBox[BOX_TOP] := -10 * FRACUNIT;
  LBox[BOX_BOTTOM] := -40 * FRACUNIT;
  Assert.AreEqual(0, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
  // a line going left turns the sides
  MakeLine(64 * FRACUNIT, 0, 0, 0);
  Assert.AreEqual(1, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
end;

procedure TTestRulesMapUtil.DovrebbeDareMenoUnoSeLaScatolaAttraversaLaLinea;
var
  LBox: array[0..3] of fixed_t;
begin
  LBox[BOX_TOP] := 10 * FRACUNIT;
  LBox[BOX_BOTTOM] := -10 * FRACUNIT;
  LBox[BOX_LEFT] := -10 * FRACUNIT;
  LBox[BOX_RIGHT] := 10 * FRACUNIT;
  MakeLine(-64 * FRACUNIT, 0, 64 * FRACUNIT, 0);
  Assert.AreEqual(-1, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
  MakeLine(0, -64 * FRACUNIT, 0, 64 * FRACUNIT);
  Assert.AreEqual(-1, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
  MakeLine(-64 * FRACUNIT, -64 * FRACUNIT, 64 * FRACUNIT, 64 * FRACUNIT);
  Assert.AreEqual(-1, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
  MakeLine(-64 * FRACUNIT, 64 * FRACUNIT, 64 * FRACUNIT, -64 * FRACUNIT);
  Assert.AreEqual(-1, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
end;

procedure TTestRulesMapUtil.DovrebbeDareIlLatoDellaScatolaSuLineeObblique;
var
  LBox: array[0..3] of fixed_t;
  LIndex: Integer;
  LSideA: Integer;
  LSideB: Integer;
  LExpected: Integer;
begin
  for LIndex := 1 to 1000 do
  begin
    MakeLine(
      (NextRandom(400) - 200) * FRACUNIT, (NextRandom(400) - 200) * FRACUNIT,
      (NextRandom(400) - 200) * FRACUNIT, (NextRandom(400) - 200) * FRACUNIT);
    if (FLine.dx = 0) or (FLine.dy = 0) then
      Continue;
    LBox[BOX_LEFT] := (NextRandom(500) - 250) * FRACUNIT;
    LBox[BOX_RIGHT] := LBox[BOX_LEFT] + (NextRandom(60) + 1) * FRACUNIT;
    LBox[BOX_BOTTOM] := (NextRandom(500) - 250) * FRACUNIT;
    LBox[BOX_TOP] := LBox[BOX_BOTTOM] + (NextRandom(60) + 1) * FRACUNIT;
    // the two corners that the engine looks at depend on the slope
    if FLine.slopetype = ST_POSITIVE then
    begin
      LSideA := ReferenceSide(LBox[BOX_LEFT], LBox[BOX_TOP]);
      LSideB := ReferenceSide(LBox[BOX_RIGHT], LBox[BOX_BOTTOM]);
    end
    else
    begin
      LSideA := ReferenceSide(LBox[BOX_RIGHT], LBox[BOX_TOP]);
      LSideB := ReferenceSide(LBox[BOX_LEFT], LBox[BOX_BOTTOM]);
    end;
    if LSideA = LSideB then
      LExpected := LSideA
    else
      LExpected := -1;
    Assert.AreEqual(LExpected, TMapUtilRoutines.P_BoxOnLineSide(Pfixed_tArray(@LBox), @FLine));
  end;
end;

procedure TTestRulesMapUtil.DovrebbeDareApertura0SuUnaLineaAUnSoloLato;
begin
  MakeLine(0, 0, 64 * FRACUNIT, 0);
  FLine.sidenum[0] := 0;
  FLine.sidenum[1] := -1;
  openrange := 77;
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(0, openrange);
end;

procedure TTestRulesMapUtil.DovrebbeUsareIlSoffittoPiuBassoEIlPavimentoPiuAltoNellApertura;
begin
  MakeSector(0, 0, 128 * FRACUNIT, 5);
  MakeSector(1, 16 * FRACUNIT, 96 * FRACUNIT, 6);
  MakeTwoSidedLine(0, 1);
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(96 * FRACUNIT, opentop);
  Assert.AreEqual(16 * FRACUNIT, openbottom);
  Assert.AreEqual(0, lowfloor);
  Assert.AreEqual(80 * FRACUNIT, openrange);
  // the same line seen from the other side gives the same opening
  MakeTwoSidedLine(1, 0);
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(96 * FRACUNIT, opentop);
  Assert.AreEqual(16 * FRACUNIT, openbottom);
  Assert.AreEqual(0, lowfloor);
  Assert.AreEqual(80 * FRACUNIT, openrange);
end;

procedure TTestRulesMapUtil.DovrebbeSceglierePavimentoEFlatDelLatoPiuAlto;
begin
  MakeSector(0, 24 * FRACUNIT, 128 * FRACUNIT, 5);
  MakeSector(1, 8 * FRACUNIT, 128 * FRACUNIT, 6);
  MakeTwoSidedLine(0, 1);
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(24 * FRACUNIT, openbottom);
  Assert.AreEqual(8 * FRACUNIT, lowfloor);
  Assert.AreEqual(5, TMapCheck.FloorPic);
  MakeTwoSidedLine(1, 0);
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(24 * FRACUNIT, openbottom);
  Assert.AreEqual(5, TMapCheck.FloorPic);
  // equal floors: the back sector wins (the engine takes the back floor when the front is not higher)
  MakeSector(1, 24 * FRACUNIT, 128 * FRACUNIT, 6);
  MakeTwoSidedLine(0, 1);
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(6, TMapCheck.FloorPic);
  Assert.AreEqual(24 * FRACUNIT, lowfloor);
end;

procedure TTestRulesMapUtil.DovrebbeAbbassareIlSoffittoConUnPianoIntermedioSopraLaCosa;
begin
  // a 3d floor (sector 2) from 40 to 56 in the front sector; the thing is from 0 to 56: its middle is below the
  // middle of the 3d floor, so the 3d floor is a ceiling for it
  MakeSector(0, 0, 128 * FRACUNIT, 5);
  MakeSector(1, 0, 128 * FRACUNIT, 5);
  MakeSector(2, 40 * FRACUNIT, 56 * FRACUNIT, 5);
  FSectors[0].midsec := 2;
  MakeTwoSidedLine(0, 1);
  sectors := @FSectors[0];
  FThing.z := 0;
  FThing.height := 56 * FRACUNIT;
  TMapCheck.Thing := @FThing;
  TMapUtilRoutines.P_LineOpening(@FLine, True);
  Assert.AreEqual(40 * FRACUNIT, opentop);
  Assert.AreEqual(0, openbottom);
  Assert.AreEqual(40 * FRACUNIT, openrange);
end;

procedure TTestRulesMapUtil.DovrebbeAlzareIlPavimentoConUnPianoIntermedioSottoLaCosa;
begin
  // the thing is from 48 to 56: it is on the 3d floor from 40 to 56, whose top becomes the floor
  MakeSector(0, 0, 128 * FRACUNIT, 5);
  MakeSector(1, 16 * FRACUNIT, 128 * FRACUNIT, 5);
  MakeSector(2, 40 * FRACUNIT, 56 * FRACUNIT, 5);
  FSectors[0].midsec := 2;
  MakeTwoSidedLine(0, 1);
  sectors := @FSectors[0];
  FThing.z := 48 * FRACUNIT;
  FThing.height := 8 * FRACUNIT;
  TMapCheck.Thing := @FThing;
  TMapUtilRoutines.P_LineOpening(@FLine, True);
  Assert.AreEqual(56 * FRACUNIT, openbottom);
  Assert.AreEqual(128 * FRACUNIT, opentop);
  Assert.AreEqual(72 * FRACUNIT, openrange);
  Assert.AreEqual(0, lowfloor);
end;

procedure TTestRulesMapUtil.DovrebbeAlzareIlPavimentoBassoConUnPianoIntermedioQuandoQuelloAltoEPiuInAlto;
begin
  // the back floor (64) is above the top of the 3d floor of the back sector (56): the 3d floor only raises the low floor
  MakeSector(0, 0, 128 * FRACUNIT, 5);
  MakeSector(1, 64 * FRACUNIT, 128 * FRACUNIT, 5);
  MakeSector(2, 40 * FRACUNIT, 56 * FRACUNIT, 5);
  FSectors[0].midsec := 2;
  MakeTwoSidedLine(0, 1);
  sectors := @FSectors[0];
  FThing.z := 48 * FRACUNIT;
  FThing.height := 8 * FRACUNIT;
  TMapCheck.Thing := @FThing;
  TMapUtilRoutines.P_LineOpening(@FLine, True);
  Assert.AreEqual(64 * FRACUNIT, openbottom);
  Assert.AreEqual(56 * FRACUNIT, lowfloor);
end;

procedure TTestRulesMapUtil.DovrebbeIgnorareIPianiIntermediSenzaIlControlloDei3dFloor;
begin
  MakeSector(0, 0, 128 * FRACUNIT, 5);
  MakeSector(1, 0, 128 * FRACUNIT, 5);
  MakeSector(2, 40 * FRACUNIT, 56 * FRACUNIT, 5);
  FSectors[0].midsec := 2;
  MakeTwoSidedLine(0, 1);
  sectors := @FSectors[0];
  TMapUtilRoutines.P_LineOpening(@FLine, False);
  Assert.AreEqual(128 * FRACUNIT, opentop);
  Assert.AreEqual(0, openbottom);
end;
end.
