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
