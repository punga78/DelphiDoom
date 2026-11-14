{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the Doubles of the 32 bit FPU  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.X87Double;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.MathCore.Golden;

type
  /// <summary>
  ///   TX87Double and the sine of TSoftExtended against the 32 bit FPU (issue #40). At 32 bit the exact way of
  ///   every expression is compared bit by bit with the expression computed by the processor, and the
  ///   fingerprint of the results is the golden file (x87double.golden.txt); at 64 bit the same fingerprint
  ///   must come out, and the fast way (native result when it is proved equal) must give what the exact way gives
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreX87Double = class(TObject)
  private
    FGolden: TGoldenFile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareSenoECosenoDelProcessore;
    [Test]
    procedure DovrebbeArrotondareASingleComeLaFpu;
    [Test]
    procedure DovrebbeSommareComeLaFpu;
    [Test]
    procedure DovrebbeSommareComeLaFpuVicinoAllaMetaDiDueDouble;
    [Test]
    procedure DovrebbeTroncareBasePiuPassiComeLaFpu;
    [Test]
    procedure DovrebbeTroncareConScostamentoEDivisoreComeLaFpu;
    [Test]
    procedure DovrebbeArrotondareProdottiEQuozientiComeLaFpu;
    [Test]
    procedure DovrebbeDareIlReciprocoInVirgolaFissaConIDivisoriInteri;
    [Test]
    procedure DovrebbeDareLeProfonditaDeiPianiEDegliSprite;
    [Test]
    procedure DovrebbeTroncareIQuozientiDelleLuci;
    [Test]
    procedure DovrebbeArrotondareLaSommaDiDueProdotti;
    [Test]
    procedure DovrebbeDareLaRadiceQuadrataDellaFpu;
    [Test]
    procedure DovrebbeDareLaDistanzaDaUnSeg;
    [Test]
    procedure DovrebbeDareLaProiezioneDellaVista;
    [Test]
    procedure DovrebbeDareZeroConUnDivisoreNullo;
    [Test]
    procedure DovrebbeDareIDoubleDelleEspressioniFredde;
    [Test]
    procedure DovrebbeRifiutareIlRisultatoNativoVicinoAlConfine;
  end;

implementation

uses
  System.Math, DelphiDoom.MathCore.SoftExtended, DelphiDoom.MathCore.X87Double,
  DelphiDoom.Tests.MathCore.Fingerprint;

type
  TRandomSource = record
    State: UInt64;
    function Next: UInt64;
    function NextDouble(AMinExponent, AMaxExponent: Integer): Double;
    function NextInteger(ARange: Integer): Integer;
  end;

function TRandomSource.Next: UInt64;
begin
  State := State xor (State shl 13);
  State := State xor (State shr 7);
  State := State xor (State shl 17);
  Result := State;
end;

function TRandomSource.NextDouble(AMinExponent, AMaxExponent: Integer): Double;
var
  LBits: UInt64;
  LExponent: Integer;
begin
  LBits := Next;
  LExponent := AMinExponent + Integer(Next mod UInt64(AMaxExponent - AMinExponent + 1));
  LBits := (LBits and $800FFFFFFFFFFFFF) or (UInt64(1023 + LExponent) shl 52);
  Result := PDouble(@LBits)^;
end;

// -ARange..ARange
function TRandomSource.NextInteger(ARange: Integer): Integer;
begin
  Result := Integer(Next mod UInt64(2 * ARange + 1)) - ARange;
end;

function SameBits(const A, B: Double): Boolean;
begin
  Result := PUInt64(@A)^ = PUInt64(@B)^;
end;

// The inputs of the tests must be the same bits at 32 and at 64 bit: they are made with integers and with
// TSoftExtended, never with an expression of the compiler (which is what differs between the two)

// AValue moved by ASteps representable numbers (away from zero when positive)
function Nudge(const AValue: Double; ASteps: Integer): Double;
var
  LBits: UInt64;
begin
  LBits := PUInt64(@AValue)^ + UInt64(Int64(ASteps));
  Result := PDouble(@LBits)^;
end;

function ExponentOf(const AValue: Double): Integer;
begin
  Result := Integer((PUInt64(@AValue)^ shr 52) and $7FF) - 1023;
end;

function Ratio(const A, B, C: Double): Double;
begin
  Result := (TSoftExtended.FromDouble(A) * TSoftExtended.FromDouble(B) / TSoftExtended.FromDouble(C)).ToDouble;
end;

{ TTestMathCoreX87Double }

procedure TTestMathCoreX87Double.Setup;
begin
  FGolden := TGoldenFile.Create('x87double.golden.txt');
end;

procedure TTestMathCoreX87Double.TearDown;
begin
  FGolden.Free;
end;

procedure TTestMathCoreX87Double.DovrebbeDareSenoECosenoDelProcessore;
const
  COUNT = 200000;
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LSeed: Cardinal;
  LAngle: Cardinal;
  LFactor: TSoftExtended;
  LArgument, LSine, LCosine: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNativeArgument, LNativeSine, LNativeCosine: Extended;
  LNativeDouble: Double;
  LLastBit: Integer;
  LDoubles: Integer;
  LMantissa: UInt64;
  LExponent: Word;
  {$IFEND}
begin
  // 2 * 3.141592657 / 2^32: the factor from an angle of 32 bits to radians of the renderer
  LFactor := TSoftExtended.FromMantissa(UInt64($C90FDAA5CACCB9CF), -93);
  LFingerprint := TFingerprint.Create;
  try
    LSeed := 12345;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LLastBit := 0;
    LDoubles := 0;
    {$IFEND}
    for LIndex := 0 to COUNT - 1 do
    begin
      LSeed := LSeed * 1664525 + 1013904223;
      LAngle := LSeed xor (LSeed shr 13);
      // the angles near to a multiple of a quarter of turn too, where the Pi of the processor counts
      if LIndex mod 16 = 0 then
        LAngle := (LAngle and $C0000000) + (LAngle and $3FF) - 512;
      LArgument := TSoftExtended.FromInt64(LAngle) * LFactor;
      LSine := TSoftExtended.Sin(LArgument);
      LCosine := TSoftExtended.Cos(LArgument);
      LFingerprint.AddInt64(Int64(LSine.Mantissa));
      LFingerprint.AddInteger(LSine.BinaryExponent);
      LFingerprint.AddBoolean(LSine.IsNegative);
      LFingerprint.AddInt64(Int64(LCosine.Mantissa));
      LFingerprint.AddInteger(LCosine.BinaryExponent);
      LFingerprint.AddBoolean(LCosine.IsNegative);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNativeArgument := LAngle * Extended(2 * 3.141592657 / $100000000);
      LNativeSine := Sin(LNativeArgument);
      LNativeCosine := Cos(LNativeArgument);
      // the processor is not correctly rounded: the last of the 64 bits may differ, nothing more
      LMantissa := PUInt64(@LNativeSine)^;
      LExponent := PWord(PByte(@LNativeSine) + 8)^;
      if LMantissa <> 0 then
      begin
        Assert.AreEqual(Integer(LExponent and $7FFF), LSine.BinaryExponent + 63 + 16383,
          Format('exponent of the sine of angle %u', [LAngle]));
        Assert.AreEqual((LExponent and $8000) <> 0, LSine.IsNegative, Format('sign of the sine of angle %u', [LAngle]));
        Assert.IsTrue((LMantissa - LSine.Mantissa + 1) <= 2, Format('sine of angle %u', [LAngle]));
        if LMantissa <> LSine.Mantissa then
          Inc(LLastBit);
      end;
      LMantissa := PUInt64(@LNativeCosine)^;
      if LMantissa <> 0 then
      begin
        Assert.IsTrue((LMantissa - LCosine.Mantissa + 1) <= 2, Format('cosine of angle %u', [LAngle]));
        if LMantissa <> LCosine.Mantissa then
          Inc(LLastBit);
      end;
      LNativeDouble := LNativeSine;
      if not SameBits(LNativeDouble, LSine.ToDouble) then
        Inc(LDoubles);
      LNativeDouble := LNativeCosine;
      if not SameBits(LNativeDouble, LCosine.ToDouble) then
        Inc(LDoubles);
      {$IFEND}
    end;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    // measured on the processor of the golden files: 2.8% of the results with the last bit different, one
    // Double in a hundred thousand
    Assert.IsTrue(LLastBit < 2 * COUNT div 20, Format('%d results with a different last bit', [LLastBit]));
    Assert.IsTrue(LDoubles < 2 * COUNT div 5000, Format('%d different Doubles', [LDoubles]));
    {$IFEND}
    FGolden.Check('x87.sincos', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeArrotondareASingleComeLaFpu;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB: Double;
  LSoft: TSoftExtended;
  LSingle: Single;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Single;
  {$IFEND}
begin
  LRandom.State := $A5A5A5A55A5A5A5A;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 49999 do
    begin
      LA := LRandom.NextDouble(-20, 20);
      LB := LRandom.NextDouble(-20, 20);
      if LIndex mod 5 = 0 then
        // exactly the middle between two Singles, and a little beside it
        LA := Nudge((LRandom.NextInteger(8000000) * 2 + 1) / 16777216 / 2, LIndex mod 3 - 1);
      LSoft := TSoftExtended.FromDouble(LA) * TSoftExtended.FromDouble(LB);
      if LIndex mod 5 = 0 then
        LSoft := TSoftExtended.FromDouble(LA);
      LSingle := LSoft.ToSingle;
      {$IF SizeOf(Extended) > SizeOf(Double)}
      if LIndex mod 5 = 0 then
        LNative := LA
      else
        LNative := Extended(LA) * Extended(LB);
      Assert.AreEqual(PCardinal(@LNative)^, PCardinal(@LSingle)^, Format('case %d: %.17g %.17g', [LIndex, LA, LB]));
      {$IFEND}
      LFingerprint.AddSingle(LSingle);
    end;
    FGolden.Check('x87.single', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeSommareComeLaFpu;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB, LFast, LExact: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := $0123456789ABCDEF;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 999999 do
    begin
      LA := LRandom.NextDouble(-10, 40);
      case LIndex mod 4 of
        0:
          LB := LRandom.NextDouble(-10, 40);
        1:
          // a step much smaller than the sum, as in the loops of the walls
          LB := LRandom.NextDouble(ExponentOf(LA) - 30, ExponentOf(LA) - 5);
        2:
          LB := LRandom.NextInteger(100000);
      else
        // nearly the opposite: the sum loses most of its bits
        LB := -Nudge(LA, LRandom.NextInteger(1000000));
      end;
      LFast := TX87Double.Add(LA, LB);
      LExact := TX87Double.AddExact(LA, LB);
      Assert.IsTrue(SameBits(LFast, LExact), Format('sum %d: %.17g + %.17g', [LIndex, LA, LB]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Extended(LA) + Extended(LB);
      Assert.IsTrue(SameBits(LNative, LExact), Format('sum %d against the FPU: %.17g + %.17g', [LIndex, LA, LB]));
      {$IFEND}
      LFingerprint.AddDouble(LExact);
    end;
    FGolden.Check('x87.add', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeSommareComeLaFpuVicinoAllaMetaDiDueDouble;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB, LUnit, LFast, LExact: Double;
  LDifferent: Integer;
  LPlain: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  // the second addend is half a unit of the last place of the first one, less or plus a few 4096ths: the
  // sum rounded once (53 bits) and rounded twice (64 and then 53) are different numbers in many of these
  LRandom.State := $FEDCBA9876543210;
  LFingerprint := TFingerprint.Create;
  LDifferent := 0;
  try
    for LIndex := 0 to 199999 do
    begin
      LA := LRandom.NextDouble(0, 30);
      LUnit := Ldexp(1.0, Floor(Log2(Abs(LA))) - 52);
      LB := LUnit / 2 + LUnit / 4096 * (LRandom.NextInteger(4) / 2);
      if Odd(LIndex) then
        LB := -LB;
      if LA < 0 then
        LB := -LB;
      if LIndex mod 50 = 0 then
        // a power of two as the first addend: the unit below it is half
        LA := Ldexp(1.0, LIndex mod 30);
      LFast := TX87Double.Add(LA, LB);
      LExact := TX87Double.AddExact(LA, LB);
      Assert.IsTrue(SameBits(LFast, LExact), Format('sum %d: %.17g + %.17g', [LIndex, LA, LB]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Extended(LA) + Extended(LB);
      Assert.IsTrue(SameBits(LNative, LExact), Format('sum %d against the FPU: %.17g + %.17g', [LIndex, LA, LB]));
      {$ELSE}
      LPlain := LA + LB;
      if not SameBits(LPlain, LExact) then
        Inc(LDifferent);
      {$IFEND}
      LFingerprint.AddDouble(LExact);
    end;
    {$IF SizeOf(Extended) = SizeOf(Double)}
    // the test is not empty: here the plain sum of the 64 bit code is often not the one of the FPU
    Assert.IsTrue(LDifferent > 1000, Format('only %d sums differ from the plain one', [LDifferent]));
    {$IFEND}
    FGolden.Check('x87.add.middle', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeTroncareBasePiuPassiComeLaFpu;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LBase, LStep: Double;
  LCount: Integer;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  LRandom.State := $1111222233334444;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 499999 do
    begin
      LBase := LRandom.NextDouble(0, 29);
      LStep := LRandom.NextDouble(-8, 18);
      LCount := LRandom.NextInteger(2000);
      if LIndex mod 3 = 0 then
      begin
        // the sum falls on an integer, or a hair beside it
        LStep := LRandom.NextInteger(4096) / 8;
        LBase := Nudge(LRandom.NextInteger(1000000) - LCount * LStep, LIndex mod 5 - 2);
      end;
      LFast := TX87Double.TruncMulAdd(LBase, LCount, LStep);
      LExact := TX87Double.TruncMulAddExact(LBase, LCount, LStep);
      Assert.AreEqual(LExact, LFast, Format('case %d: %.17g + %d * %.17g', [LIndex, LBase, LCount, LStep]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Trunc(LBase + LCount * LStep);
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %.17g + %d * %.17g',
        [LIndex, LBase, LCount, LStep]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.truncmuladd', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeTroncareConScostamentoEDivisoreComeLaFpu;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LValue: Double;
  LUnit: Integer;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  LRandom.State := $5555666677778888;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 499999 do
    begin
      LUnit := 1 shl (LIndex mod 13);
      LValue := LRandom.NextDouble(0, 30);
      if LIndex mod 3 = 0 then
        // the numerator falls on a multiple of the unit, or a hair beside it
        LValue := Nudge(LRandom.NextInteger(100000) * LUnit - (LUnit - 1), LIndex mod 5 - 2);
      if Odd(LIndex) then
      begin
        // yl of the loop of the walls: Trunc((value + (unit - 1)) / unit)
        LFast := TX87Double.TruncOffsetDivide(LValue, LUnit - 1, 0, LUnit);
        LExact := TX87Double.TruncOffsetDivideExact(LValue, LUnit - 1, 0, LUnit);
      end
      else
      begin
        // the bottom wall: Trunc((value + unit - 1) / unit)
        LFast := TX87Double.TruncOffsetDivide(LValue, LUnit, -1, LUnit);
        LExact := TX87Double.TruncOffsetDivideExact(LValue, LUnit, -1, LUnit);
      end;
      Assert.AreEqual(LExact, LFast, Format('case %d: %.17g, unit %d', [LIndex, LValue, LUnit]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      if Odd(LIndex) then
        LNative := Trunc((LValue + (LUnit - 1)) / LUnit)
      else
        LNative := Trunc((LValue + LUnit - 1) / LUnit);
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %.17g, unit %d', [LIndex, LValue, LUnit]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.truncoffsetdivide', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeArrotondareProdottiEQuozientiComeLaFpu;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB: Double;
  LWidth: Integer;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  LRandom.State := $9999AAAABBBBCCCC;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 499999 do
    begin
      LWidth := 320 + 16 * Integer(LRandom.Next mod 200);
      LA := LRandom.NextDouble(8, 22);
      LB := LRandom.NextDouble(-12, 8);
      case LIndex mod 4 of
        0:
          begin
            if LIndex mod 3 = 0 then
              // on a half, or a hair beside it
              LA := Nudge(Ratio(LRandom.NextInteger(100000) + 0.5, LWidth, 320), LIndex mod 5 - 2);
            LFast := TX87Double.RoundMulDivide(LA, 320, LWidth);
            LExact := TX87Double.RoundMulDivideExact(LA, 320, LWidth, 1);
            {$IF SizeOf(Extended) > SizeOf(Double)}
            LNative := Round(LA * 320 / LWidth);
            {$IFEND}
          end;
        1:
          begin
            LFast := TX87Double.RoundMulDivide(LA, 320, 32, LWidth);
            LExact := TX87Double.RoundMulDivideExact(LA, 320, 32, LWidth);
            {$IF SizeOf(Extended) > SizeOf(Double)}
            LNative := Round(LA * 320 / 32 / LWidth);
            {$IFEND}
          end;
        2:
          begin
            if LIndex mod 3 = 0 then
              // 2^32 / a on a half: a = 2^33 / (2n + 1)
              LA := Nudge(Ratio(8589934592.0, 1, 2 * (1000 + Integer(LRandom.Next mod 1000000)) + 1), LIndex mod 5 - 2);
            LFast := TX87Double.RoundQuotient(4294967296.0, LA);
            LExact := TX87Double.RoundQuotientExact(4294967296.0, LA);
            {$IF SizeOf(Extended) > SizeOf(Double)}
            LNative := Round($100000000 / LA);
            {$IFEND}
          end;
      else
        begin
          if LIndex mod 3 = 0 then
          begin
            LB := 1 shl (LIndex mod 9);
            LA := Nudge((LRandom.NextInteger(1000000) + 0.5) / LB, LIndex mod 5 - 2);
          end;
          LFast := TX87Double.RoundProduct(LA, LB);
          LExact := TX87Double.RoundProductExact(LA, LB);
          {$IF SizeOf(Extended) > SizeOf(Double)}
          LNative := Round(LA * LB);
          {$IFEND}
        end;
      end;
      Assert.AreEqual(LExact, LFast, Format('case %d: %.17g %.17g %d', [LIndex, LA, LB, LWidth]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %.17g %.17g %d', [LIndex, LA, LB, LWidth]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.round', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeDareIlReciprocoInVirgolaFissaConIDivisoriInteri;
const
  FRACUNIT = 65536;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LValue: Integer;
  LResult: Integer;
  LSoft: Integer;
begin
  // Trunc((FRACUNIT / dc_iscale) * FRACUNIT) of the depth buffers: an integer division gives the same
  LRandom.State := $0F0F0F0F12345678;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 1999999 do
    begin
      case LIndex mod 5 of
        0:
          LValue := 1 + LIndex div 5;
        1:
          LValue := (1 shl (1 + LIndex mod 30)) + LRandom.NextInteger(3);
        2:
          LValue := MaxInt - Integer(LRandom.Next mod 100000);
        3:
          LValue := -1 - Integer(LRandom.Next mod $7FFFFFFF);
      else
        LValue := 1 + Integer(LRandom.Next mod $7FFFFFFF);
      end;
      if LValue = 0 then
        LValue := 1;
      LResult := TX87Double.TruncFixedReciprocal(LValue);
      LSoft := Integer(((TSoftExtended.FromInt64(FRACUNIT) / TSoftExtended.FromInt64(LValue)) *
        TSoftExtended.FromInt64(FRACUNIT)).Truncate);
      Assert.AreEqual(LSoft, LResult, Format('reciprocal of %d', [LValue]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Integer(Trunc((FRACUNIT / LValue) * FRACUNIT)), LResult,
        Format('reciprocal of %d against the FPU', [LValue]));
      {$IFEND}
      LFingerprint.AddInteger(LResult);
    end;
    FGolden.Check('x87.fixedreciprocal', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeDareLeProfonditaDeiPianiEDegliSprite;
const
  FRACUNIT = 65536;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB: Integer;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  LRandom.State := $7777000011112222;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 499999 do
    begin
      if Odd(LIndex) then
      begin
        // Round(FRACUNIT / (planeheight / rows) * FRACUNIT)
        LA := 1 + Integer(LRandom.Next mod (2048 * FRACUNIT));
        LB := 1 + Integer(LRandom.Next mod 1080);
        if LIndex mod 7 = 0 then
          // 2^32 * rows / height on a half: height = 2^33 * rows / (2n + 1) is not an integer, but near to one
          LA := Integer(Int64(8589934592) * LB div (2 * (4 * LB + Integer(LRandom.Next mod 100000)) + 1));
        LFast := TX87Double.RoundScaledInverse(FRACUNIT, LA, LB);
        LExact := TX87Double.RoundScaledInverseExact(FRACUNIT, LA, LB);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Round(FRACUNIT / (LA / LB) * FRACUNIT));
        {$IFEND}
      end
      else
      begin
        // Trunc((FRACUNIT / dc_iscale) * (FRACUNIT / infoscale) * FRACUNIT)
        LA := 64 + Integer(LRandom.Next mod (64 * FRACUNIT));
        LB := 4096 + Integer(LRandom.Next mod (8 * FRACUNIT));
        if LIndex mod 6 = 0 then
        begin
          // powers of two: the result is an integer
          LA := 1 shl (6 + LIndex mod 16);
          LB := 1 shl (12 + LIndex mod 7);
        end;
        LFast := TX87Double.TruncReciprocalProduct(FRACUNIT, LA, LB);
        LExact := TX87Double.TruncReciprocalProductExact(FRACUNIT, LA, LB);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Trunc((FRACUNIT / LA) * (FRACUNIT / LB) * FRACUNIT));
        {$IFEND}
      end;
      Assert.AreEqual(LExact, LFast, Format('case %d: %d %d', [LIndex, LA, LB]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %d %d', [LIndex, LA, LB]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.depth', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeTroncareIQuozientiDelleLuci;
const
  LIGHTTEXTURESIZE = 128;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LScale: Integer;
  LWidth: Single;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  // R_DrawVisLight: Trunc(xiscale * LIGHTTEXTURESIZE / w) and Trunc(scale * w / LIGHTTEXTURESIZE), w a Single
  LRandom.State := $3333444455556666;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 499999 do
    begin
      LScale := 1 + Integer(LRandom.Next mod (16 * 65536));
      // a width as the definitions of the lights give it: a few units, often a round number
      LWidth := (16 + Integer(LRandom.Next mod 4096)) / 16;
      if LIndex mod 3 = 0 then
        LWidth := Single(LRandom.NextDouble(2, 9));
      if LIndex mod 4 = 0 then
        LScale := LScale and not $FFF;
      if Odd(LIndex) then
      begin
        LFast := TX87Double.TruncQuotient(LScale * LIGHTTEXTURESIZE, LWidth);
        LExact := TX87Double.TruncQuotientExact(LScale * LIGHTTEXTURESIZE, LWidth);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Trunc(LScale * LIGHTTEXTURESIZE / LWidth));
        {$IFEND}
      end
      else
      begin
        LFast := TX87Double.TruncMulDivide(LWidth, LScale, LIGHTTEXTURESIZE);
        LExact := TX87Double.TruncMulDivideExact(LWidth, LScale, LIGHTTEXTURESIZE);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Trunc(LScale * LWidth / LIGHTTEXTURESIZE));
        {$IFEND}
      end;
      Assert.AreEqual(LExact, LFast, Format('case %d: %d %.9g', [LIndex, LScale, LWidth]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %d %.9g', [LIndex, LScale, LWidth]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.lights', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeArrotondareLaSommaDiDueProdotti;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB: Integer;
  LSine, LCosine: Single;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  // the view point turned by the angle of a flat: Round(dx * cosine - dy * sine), sine and cosine Singles
  LRandom.State := $ABCDEF0102030405;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 299999 do
    begin
      LA := LRandom.NextInteger(MaxInt div 2);
      LB := LRandom.NextInteger(MaxInt div 2);
      LSine := Single(LRandom.NextDouble(-12, -1));
      LCosine := Single(LRandom.NextDouble(-12, -1));
      if LIndex mod 4 = 0 then
      begin
        // quarters and halves: the sum falls often on a half
        LSine := 0.5;
        LCosine := -0.25;
        LA := LA or 1;
      end;
      LFast := TX87Double.RoundCrossProducts(LA, LCosine, LB, -LSine);
      LExact := TX87Double.RoundCrossProductsExact(LA, LCosine, LB, -LSine);
      Assert.AreEqual(LExact, LFast, Format('case %d: %d %d', [LIndex, LA, LB]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Integer(Round(LA * LCosine - LB * LSine));
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %d %d', [LIndex, LA, LB]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.cross', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeDareLaRadiceQuadrataDellaFpu;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LValue: Double;
  LRoot: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Extended;
  {$IFEND}
begin
  LRandom.State := $1357924680ACE135;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 199999 do
    begin
      LValue := Abs(LRandom.NextDouble(-40, 62));
      case LIndex mod 4 of
        0:
          // perfect squares and their neighbours
          LValue := Nudge(Sqr(1.0 + LRandom.Next mod 60000000), LIndex mod 3 - 1);
        1:
          LValue := 1 + LRandom.Next mod 1000000;
      end;
      LRoot := TSoftExtended.Sqrt(TSoftExtended.FromDouble(LValue));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Sqrt(Extended(LValue));
      Assert.IsTrue((PUInt64(@LNative)^ = LRoot.Mantissa) and
        (Integer(PWord(PByte(@LNative) + 8)^ and $7FFF) = LRoot.BinaryExponent + 63 + 16383),
        Format('root of %.17g', [LValue]));
      {$IFEND}
      LFingerprint.AddInt64(Int64(LRoot.Mantissa));
      LFingerprint.AddInteger(LRoot.BinaryExponent);
    end;
    Assert.IsTrue(TSoftExtended.Sqrt(TSoftExtended.FromInt64(0)).IsZero);
    Assert.AreEqual(Int64(12), TSoftExtended.Sqrt(TSoftExtended.FromInt64(144)).Round);
    Assert.WillRaise(
      procedure
      begin
        TSoftExtended.Sqrt(TSoftExtended.FromInt64(-4));
      end, EInvalidOp);
    FGolden.Check('x87.sqrt', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeDareLaDistanzaDaUnSeg;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LDeltaX, LDeltaY, LViewX, LViewY, LInverse: Double;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  // R_DistToSeg and R_CalcSegOffset: Round((dy * dx1 - dx * dy1) * inv_length), 16.16 coordinates in Doubles
  LRandom.State := $2468ACE013579BDF;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 499999 do
    begin
      LDeltaX := LRandom.NextInteger($30000000);
      LDeltaY := LRandom.NextInteger($30000000);
      LViewX := LRandom.NextInteger($60000000);
      LViewY := LRandom.NextInteger($60000000);
      if LIndex mod 5 = 0 then
      begin
        // the view point nearly on the line of the seg: the two products nearly cancel
        LViewX := LDeltaX * 2;
        LViewY := LDeltaY * 2 + LRandom.NextInteger(1000);
      end;
      if (LDeltaX = 0) and (LDeltaY = 0) then
        LDeltaX := 65536;
      // the inverse of the length as the level loader stores it
      LInverse := (TSoftExtended.FromInt64(1) / TSoftExtended.FromDouble(TSoftExtended.Sqrt(
        TSoftExtended.FromDouble(LDeltaX) * TSoftExtended.FromDouble(LDeltaX) +
        TSoftExtended.FromDouble(LDeltaY) * TSoftExtended.FromDouble(LDeltaY)).ToDouble)).ToDouble;
      if Odd(LIndex) then
      begin
        LFast := TX87Double.RoundScaledCross(LDeltaY, LViewX, -LDeltaX, LViewY, LInverse);
        LExact := TX87Double.RoundScaledCrossExact(LDeltaY, LViewX, -LDeltaX, LViewY, LInverse);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Round((LDeltaY * LViewX - LDeltaX * LViewY) * LInverse));
        {$IFEND}
      end
      else
      begin
        LFast := TX87Double.RoundScaledCross(LDeltaX, LViewX, LDeltaY, LViewY, LInverse);
        LExact := TX87Double.RoundScaledCrossExact(LDeltaX, LViewX, LDeltaY, LViewY, LInverse);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Round((LDeltaX * LViewX + LDeltaY * LViewY) * LInverse));
        {$IFEND}
      end;
      Assert.AreEqual(LExact, LFast, Format('case %d', [LIndex]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    FGolden.Check('x87.segdistance', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeDareLaProiezioneDellaVista;
const
  FRACUNIT = 65536;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LCenter: Integer;
  LWidth, LHeight: Integer;
  LAspect, LQuotient: Double;
  LFast, LExact: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  LNativeQuotient: Double;
  {$IFEND}
begin
  // projection := Round(centerx / aspect * FRACUNIT) and pspritescale := Round((centerx / aspect * FRACUNIT) / 160)
  LRandom.State := $0102030405060708;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 299999 do
    begin
      LCenter := 160 + Integer(LRandom.Next mod 2000);
      // an aspect between 1 and 2, as the widest mode of the monitor over 4 / 3 gives
      // one draw per statement: with two draws in one expression the two compilers take them in a different
      // order (the denominator first is the order of the 32 bit compiler, which made the golden)
      LHeight := 1000 + Integer(LRandom.Next mod 1000);
      LWidth := 1000 + Integer(LRandom.Next mod 3000);
      LAspect := (TSoftExtended.FromInt64(LWidth) / TSoftExtended.FromInt64(LHeight) /
        TSoftExtended.FromRatio(4, 3)).ToDouble;
      if LAspect < 1 then
        LAspect := 1;
      if Odd(LIndex) then
      begin
        LFast := TX87Double.RoundScaledQuotient(LCenter, LAspect, FRACUNIT);
        LExact := TX87Double.RoundScaledQuotientExact(LCenter, LAspect, FRACUNIT, 1);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Round(LCenter / LAspect * FRACUNIT));
        {$IFEND}
      end
      else
      begin
        LFast := TX87Double.RoundScaledQuotient(LCenter, LAspect, FRACUNIT, 160);
        LExact := TX87Double.RoundScaledQuotientExact(LCenter, LAspect, FRACUNIT, 160);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := Integer(Round((LCenter / LAspect * FRACUNIT) / 160));
        {$IFEND}
      end;
      LQuotient := TX87Double.Divide(LCenter, LAspect);
      Assert.AreEqual(LExact, LFast, Format('case %d: %d %.17g', [LIndex, LCenter, LAspect]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(LNative, LExact, Format('case %d against the FPU: %d %.17g', [LIndex, LCenter, LAspect]));
      LNativeQuotient := LCenter / LAspect;
      Assert.IsTrue(SameBits(LNativeQuotient, LQuotient), Format('quotient of case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
      LFingerprint.AddDouble(LQuotient);
    end;
    FGolden.Check('x87.projection', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeDareZeroConUnDivisoreNullo;
begin
  // the FPU gives an infinity and then the "integer indefinite" ($8000000000000000): its low 32 bits are 0
  Assert.AreEqual(0, TX87Double.TruncFixedReciprocal(0));
  Assert.AreEqual(0, TX87Double.RoundScaledInverseExact(65536, 0, 100));
  Assert.AreEqual(0, TX87Double.TruncReciprocalProductExact(65536, 0, 65536));
  Assert.AreEqual(0, TX87Double.TruncReciprocalProductExact(65536, 65536, 0));
  Assert.AreEqual(0, TX87Double.TruncQuotientExact(1000, 0));
  Assert.AreEqual(0, TX87Double.TruncMulDivideExact(2.5, 1000, 0));
  {$IF SizeOf(Extended) = SizeOf(Double)}
  Assert.AreEqual(0, TX87Double.RoundScaledInverse(65536, 0, 100));
  Assert.AreEqual(0, TX87Double.TruncReciprocalProduct(65536, 0, 65536));
  Assert.AreEqual(0, TX87Double.TruncQuotient(1000, 0));
  {$IFEND}
  // one is the only divisor that gives 2^32: the low 32 bits are 0 here too
  Assert.AreEqual(0, TX87Double.TruncFixedReciprocal(1));
  Assert.AreEqual(Integer($80000000), TX87Double.TruncFixedReciprocal(2));
  Assert.AreEqual(65536, TX87Double.TruncFixedReciprocal(65536));
end;

procedure TTestMathCoreX87Double.DovrebbeDareIDoubleDelleEspressioniFredde;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB, LC, LResult: Double;
  LCount: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := $DDDDEEEEFFFF0001;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 299999 do
    begin
      LA := LRandom.NextDouble(-6, 24);
      LB := LRandom.NextDouble(-6, 24);
      LC := LRandom.NextDouble(0, 30);
      LCount := 1 + Integer(LRandom.Next mod 3000);
      case LIndex mod 3 of
        0:
          begin
            LResult := TX87Double.Multiply(LA, LB);
            {$IF SizeOf(Extended) > SizeOf(Double)}
            LNative := Extended(LA) * Extended(LB);
            {$IFEND}
          end;
        1:
          begin
            LResult := TX87Double.SubtractProduct(LC, LA, LB);
            {$IF SizeOf(Extended) > SizeOf(Double)}
            LNative := Extended(LC) - Extended(LA) * Extended(LB);
            {$IFEND}
          end;
      else
        begin
          LResult := TX87Double.DifferenceQuotient(LA, LB, LCount);
          {$IF SizeOf(Extended) > SizeOf(Double)}
          LNative := (Extended(LA) - Extended(LB)) / LCount;
          {$IFEND}
        end;
      end;
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.IsTrue(SameBits(LNative, LResult), Format('case %d: %.17g %.17g %.17g %d', [LIndex, LA, LB, LC, LCount]));
      {$IFEND}
      LFingerprint.AddDouble(LResult);
    end;
    FGolden.Check('x87.cold', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreX87Double.DovrebbeRifiutareIlRisultatoNativoVicinoAlConfine;
begin
  Assert.IsTrue(TX87Double.CanTruncate(1234.5, 1234.5));
  Assert.IsFalse(TX87Double.CanTruncate(1234.0, 1234.0), 'an integer is on the border of Trunc');
  Assert.IsFalse(TX87Double.CanTruncate(1234.00000000000023, 1234.0));
  Assert.IsTrue(TX87Double.CanTruncate(1234.000001, 1234.0));
  Assert.IsFalse(TX87Double.CanTruncate(1234.000001, 1E12), 'the bigger the intermediate values, the wider the doubt');
  Assert.IsFalse(TX87Double.CanTruncate(3E9, 3E9), 'out of the range of an Integer');
  Assert.IsTrue(TX87Double.CanRound(1234.0, 1234.0));
  Assert.IsFalse(TX87Double.CanRound(1234.5, 1234.5), 'a half is on the border of Round');
  Assert.IsFalse(TX87Double.CanRound(-1234.49999999999977, 1234.5));
  Assert.IsTrue(TX87Double.CanRound(-1234.499999, 1234.5));
  Assert.IsFalse(TX87Double.CanRound(-3E9, 3E9));
end;

end.
