{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the measures of a level          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.LevelPrecalc;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererLevelPrecalc = class(TObject)
  private
    FPrecalc: IRendererLevelPrecalc;
    procedure MeasureOne(AStartX, AStartY, AEndX, AEndY: Integer; out AMapLength: Integer;
      out AInverseLength: Double);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlPavimentoPiuBassoEIlSoffittoPiuAlto;
    [Test]
    procedure DovrebbeDareIValoriDiPartenzaSenzaSettori;
    [Test]
    procedure DovrebbeRichiedereLeMureAlteSoloOltreLaSoglia;
    [Test]
    procedure DovrebbeCalcolareLaDistanzaSenzaTroncareA32Bit;
    [Test]
    procedure DovrebbeFallireSeLeTabelleDeiSettoriDifferiscono;
    [Test]
    procedure DovrebbeMisurareUnSegmentoOrizzontale;
    [Test]
    procedure DovrebbeMisurareUnSegmentoDiTreQuattroCinque;
    [Test]
    procedure DovrebbeArrotondareAMetaAlPari;
    [Test]
    procedure DovrebbeFallireSeLeTabelleDeiSegDifferiscono;
    [Test]
    procedure DovrebbeFallireSeIRisultatiSonoTroppoCorti;
    /// <summary>
    ///   Parity: R_CalcSectors of the old r_segs2.pas, copied here as it was, and the library give
    ///   the same range and the same flag on random sectors
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_CalcSectors;
    /// <summary>
    ///   Parity: R_PrecalcSegs of the old r_segs2.pas, copied here as it was, and the library give
    ///   the same lengths, bit by bit, on random segs
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_PrecalcSegs;
  end;

implementation

// as in the engine: the differences of the coordinates wrap around before they become Double
{$Q-}
{$R-}

uses
  DelphiDoom.Renderer.Factory;

const
  FRACUNIT = 65536;

{ TTestRendererLevelPrecalc }

procedure TTestRendererLevelPrecalc.Setup;
begin
  FPrecalc := TRendererFactory.CreateLevelPrecalc;
end;

procedure TTestRendererLevelPrecalc.TearDown;
begin
  FPrecalc := nil;
end;

procedure TTestRendererLevelPrecalc.MeasureOne(AStartX, AStartY, AEndX, AEndY: Integer;
  out AMapLength: Integer; out AInverseLength: Double);
var
  LMapLength: TArray<Integer>;
  LInverseLength: TArray<Double>;
begin
  SetLength(LMapLength, 1);
  SetLength(LInverseLength, 1);
  FPrecalc.MeasureSegments(TArray<Integer>.Create(AStartX), TArray<Integer>.Create(AStartY),
    TArray<Integer>.Create(AEndX), TArray<Integer>.Create(AEndY), LMapLength, LInverseLength);
  AMapLength := LMapLength[0];
  AInverseLength := LInverseLength[0];
end;

procedure TTestRendererLevelPrecalc.DovrebbeDareIlPavimentoPiuBassoEIlSoffittoPiuAlto;
var
  LRange: TRendererHeightRange;
begin
  LRange := FPrecalc.MeasureHeights(
    TArray<Integer>.Create(0, -128 * FRACUNIT, 64 * FRACUNIT),
    TArray<Integer>.Create(128 * FRACUNIT, 256 * FRACUNIT, 200 * FRACUNIT));

  Assert.AreEqual(-128 * FRACUNIT, LRange.LowestFloor);
  Assert.AreEqual(256 * FRACUNIT, LRange.HighestCeiling);
  Assert.IsFalse(LRange.NeedsTallWalls);
end;

procedure TTestRendererLevelPrecalc.DovrebbeDareIValoriDiPartenzaSenzaSettori;
var
  LRange: TRendererHeightRange;
begin
  LRange := FPrecalc.MeasureHeights(nil, nil);

  Assert.AreEqual(MaxInt, LRange.LowestFloor);
  Assert.AreEqual(Low(Integer), LRange.HighestCeiling);
  Assert.IsFalse(LRange.NeedsTallWalls);
end;

procedure TTestRendererLevelPrecalc.DovrebbeRichiedereLeMureAlteSoloOltreLaSoglia;
begin
  Assert.IsFalse(FPrecalc.MeasureHeights(TArray<Integer>.Create(0),
    TArray<Integer>.Create(RENDERER_TALL_WALL_OFFSET)).NeedsTallWalls, 'esattamente la soglia');
  Assert.IsTrue(FPrecalc.MeasureHeights(TArray<Integer>.Create(0),
    TArray<Integer>.Create(RENDERER_TALL_WALL_OFFSET + 1)).NeedsTallWalls, 'un po'' oltre');
end;

procedure TTestRendererLevelPrecalc.DovrebbeCalcolareLaDistanzaSenzaTroncareA32Bit;
begin
  // from the lowest to the highest integer: more than a 32 bit number can say
  Assert.IsTrue(FPrecalc.MeasureHeights(TArray<Integer>.Create(Low(Integer)),
    TArray<Integer>.Create(MaxInt)).NeedsTallWalls);
end;

procedure TTestRendererLevelPrecalc.DovrebbeFallireSeLeTabelleDeiSettoriDifferiscono;
begin
  Assert.WillRaise(
    procedure
    begin
      FPrecalc.MeasureHeights(TArray<Integer>.Create(0, 1), TArray<Integer>.Create(0));
    end,
    ERendererException);
end;

procedure TTestRendererLevelPrecalc.DovrebbeMisurareUnSegmentoOrizzontale;
var
  LMapLength: Integer;
  LInverseLength: Double;
begin
  MeasureOne(0, 0, 128 * FRACUNIT, 0, LMapLength, LInverseLength);

  Assert.AreEqual(128, LMapLength);
  Assert.IsTrue(Abs(1 / (128 * FRACUNIT) - LInverseLength) < 1E-18);
end;

procedure TTestRendererLevelPrecalc.DovrebbeMisurareUnSegmentoDiTreQuattroCinque;
var
  LMapLength: Integer;
  LInverseLength: Double;
begin
  MeasureOne(10 * FRACUNIT, 20 * FRACUNIT, 13 * FRACUNIT, 24 * FRACUNIT, LMapLength,
    LInverseLength);

  Assert.AreEqual(5, LMapLength);
  Assert.IsTrue(Abs(1 / (5 * FRACUNIT) - LInverseLength) < 1E-18);
end;

procedure TTestRendererLevelPrecalc.DovrebbeArrotondareAMetaAlPari;
var
  LMapLength: Integer;
  LInverseLength: Double;
begin
  // 2.5 map units and 3.5 map units: Round goes to the even number, as it always did
  MeasureOne(0, 0, FRACUNIT * 5 div 2, 0, LMapLength, LInverseLength);
  Assert.AreEqual(2, LMapLength);
  MeasureOne(0, 0, FRACUNIT * 7 div 2, 0, LMapLength, LInverseLength);
  Assert.AreEqual(4, LMapLength);
end;

procedure TTestRendererLevelPrecalc.DovrebbeFallireSeLeTabelleDeiSegDifferiscono;
var
  LMapLength: TArray<Integer>;
  LInverseLength: TArray<Double>;
begin
  SetLength(LMapLength, 1);
  SetLength(LInverseLength, 1);

  Assert.WillRaise(
    procedure
    begin
      FPrecalc.MeasureSegments(TArray<Integer>.Create(0), TArray<Integer>.Create(0, 1),
        TArray<Integer>.Create(5), TArray<Integer>.Create(5), LMapLength, LInverseLength);
    end,
    ERendererException);
end;

procedure TTestRendererLevelPrecalc.DovrebbeFallireSeIRisultatiSonoTroppoCorti;
var
  LMapLength: TArray<Integer>;
  LInverseLength: TArray<Double>;
begin
  SetLength(LMapLength, 1);
  SetLength(LInverseLength, 0);

  Assert.WillRaise(
    procedure
    begin
      FPrecalc.MeasureSegments(TArray<Integer>.Create(0), TArray<Integer>.Create(0),
        TArray<Integer>.Create(5), TArray<Integer>.Create(5), LMapLength, LInverseLength);
    end,
    ERendererException);
end;

procedure TTestRendererLevelPrecalc.DovrebbeFareComeIlVecchioR_CalcSectors;
var
  LCase: Integer;
  LCount: Integer;
  LIndex: Integer;
  LFloors: TArray<Integer>;
  LCeilings: TArray<Integer>;
  LRange: TRendererHeightRange;
  lowestfloor: Integer;
  highestceiling: Integer;
  level_needs_tall_walls: Boolean;
  h: Int64;
begin
  RandSeed := 20260712;
  for LCase := 1 to 300 do
  begin
    LCount := Random(40);
    SetLength(LFloors, LCount);
    SetLength(LCeilings, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      LFloors[LIndex] := (Random(4096) - 2048) * FRACUNIT;
      LCeilings[LIndex] := (Random(4096) - 2048) * FRACUNIT;
      if Random(20) = 0 then
        LCeilings[LIndex] := LFloors[LIndex] + Random(MaxInt div 2);
    end;

    // the old R_CalcSectors
    lowestfloor := MaxInt;
    highestceiling := Low(Integer);
    for LIndex := 0 to LCount - 1 do
    begin
      if LFloors[LIndex] < lowestfloor then
        lowestfloor := LFloors[LIndex];
      if LCeilings[LIndex] > highestceiling then
        highestceiling := LCeilings[LIndex];
    end;
    h := Int64(highestceiling) - Int64(lowestfloor);
    level_needs_tall_walls := h > 2048 * FRACUNIT;

    LRange := FPrecalc.MeasureHeights(LFloors, LCeilings);

    Assert.AreEqual(lowestfloor, LRange.LowestFloor, Format('pavimento (caso %d)', [LCase]));
    Assert.AreEqual(highestceiling, LRange.HighestCeiling, Format('soffitto (caso %d)', [LCase]));
    Assert.IsTrue(level_needs_tall_walls = LRange.NeedsTallWalls, Format('mura alte (caso %d)', [LCase]));
  end;
end;

procedure TTestRendererLevelPrecalc.DovrebbeFareComeIlVecchioR_PrecalcSegs;
const
  COUNT = 2000;
var
  LIndex: Integer;
  LStartX: TArray<Integer>;
  LStartY: TArray<Integer>;
  LEndX: TArray<Integer>;
  LEndY: TArray<Integer>;
  LMapLength: TArray<Integer>;
  LInverseLength: TArray<Double>;
  LOldMapLength: Integer;
  LOldInverse: Double;
  dx, dy: Double;
  len: Double;
begin
  RandSeed := 20260713;
  SetLength(LStartX, COUNT);
  SetLength(LStartY, COUNT);
  SetLength(LEndX, COUNT);
  SetLength(LEndY, COUNT);
  SetLength(LMapLength, COUNT);
  SetLength(LInverseLength, COUNT);
  for LIndex := 0 to COUNT - 1 do
  begin
    LStartX[LIndex] := Random($60000000) - $30000000;
    LStartY[LIndex] := Random($60000000) - $30000000;
    LEndX[LIndex] := Random($60000000) - $30000000;
    LEndY[LIndex] := Random($60000000) - $30000000;
    // a seg of length zero divides by zero: the map has none
    if (LEndX[LIndex] = LStartX[LIndex]) and (LEndY[LIndex] = LStartY[LIndex]) then
      Inc(LEndX[LIndex]);
  end;

  FPrecalc.MeasureSegments(LStartX, LStartY, LEndX, LEndY, LMapLength, LInverseLength);

  for LIndex := 0 to COUNT - 1 do
  begin
    // the old R_PrecalcSegs
    dx := LEndX[LIndex] - LStartX[LIndex];
    dy := LEndY[LIndex] - LStartY[LIndex];
    len := sqrt(dx * dx + dy * dy);
    LOldMapLength := round(len / FRACUNIT);
    LOldInverse := 1 / len;

    Assert.AreEqual(LOldMapLength, LMapLength[LIndex], Format('lunghezza (seg %d)', [LIndex]));
    Assert.IsTrue(CompareMem(@LOldInverse, @LInverseLength[LIndex], SizeOf(Double)),
      Format('inverso (seg %d)', [LIndex]));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRendererLevelPrecalc);

end.
