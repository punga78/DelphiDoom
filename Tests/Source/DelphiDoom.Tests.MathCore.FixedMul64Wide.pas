{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - FixedMul64 beyond 2^31         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.FixedMul64Wide;

// Issue #40: TFixedMath.Mul64 with a factor beyond 2^31 was Round(A / 65536 * B) in Double at 64 bit,
// which is not the Extended (64 bits of mantissa) of the old 32 bit code. It is now made of integers.
// At 32 bit every result is compared with the expression of the old code, calculated by the FPU; the
// fingerprint of the series is the golden file (fixedmul64wide.golden.txt) and the same one must come
// out at 64 bit.

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.MathCore.Golden;

type
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreFixedMul64Wide = class(TObject)
  private
    FGolden: TGoldenFile;
    FState: UInt64;
    function NextValue: UInt64;
    function NextFactor: Int64;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
    [Test]
    procedure DovrebbeArrotondareDueVolteOltreSessantaquattroBit;
    [Test]
    procedure DovrebbeDareIlRisultatoDelCalcoloInSoftware;
    [Test]
    procedure DovrebbeDareLInteroIndefinitoSeIlRisultatoNonEntra;
    [Test]
    procedure DovrebbeMoltiplicareIValoriLimiteSenzaSollevare;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.SoftExtended, DelphiDoom.Tests.MathCore.Fingerprint;

{$IF SizeOf(Extended) > SizeOf(Double)}
function OldFixedMul64(const A, B: Int64): Int64;
begin
  Result := Round(A / 65536 * B);
end;
{$IFEND}

{ TTestMathCoreFixedMul64Wide }

procedure TTestMathCoreFixedMul64Wide.Setup;
begin
  FGolden := TGoldenFile.Create('fixedmul64wide.golden.txt');
  FState := $2545F4914F6CDD1D;
end;

procedure TTestMathCoreFixedMul64Wide.TearDown;
begin
  FGolden.Free;
end;

function TTestMathCoreFixedMul64Wide.NextValue: UInt64;
begin
  FState := FState xor (FState shl 13);
  FState := FState xor (FState shr 7);
  FState := FState xor (FState shl 17);
  Result := FState;
end;

// A number of any size, from a few bits to 63, with a random sign
function TTestMathCoreFixedMul64Wide.NextFactor: Int64;
var
  LBits: UInt64;
  LValue: UInt64;
begin
  LBits := NextValue;
  LValue := NextValue shr (LBits mod 63 + 1);
  Result := Int64(LValue);
  if Odd(NextValue shr 11) then
    Result := -Result;
end;

procedure TTestMathCoreFixedMul64Wide.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
const
  EDGES: array[0..17] of Int64 = (0, 1, -1, 2, 32768, 65535, 65536, 65537, $7FFFFFFF, $80000000, $80000001,
    $FFFFFFFF, $100000001, Int64($7FFFFFFFFFFFFFFF), Int64($4000000000000000), Int64($3FFFFFFFFFFFFFFF),
    -Int64($7FFFFFFFFFFFFFFF), $7FFFFFFFFFFF);
  // a product of 2^78 or more is where an Extended overflows its way to the integer: no comparison
  LIMIT = 3.0E23;
var
  LIndex: Integer;
  LA, LB: Int64;
  LFingerprint: TFingerprint;
  LResult: Int64;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 400000 do
    begin
      if LIndex < Length(EDGES) * Length(EDGES) then
      begin
        LA := EDGES[LIndex div Length(EDGES)];
        LB := EDGES[LIndex mod Length(EDGES)];
      end
      else
      begin
        // the factors are made one after the other: the order of evaluation is not the same in 32 and 64 bit
        LA := NextFactor;
        LB := NextFactor;
      end;
      LResult := TFixedMath.Mul64(LA, LB);
{$IF SizeOf(Extended) > SizeOf(Double)}
      if Abs(LA / 1.0 * LB) < LIMIT then
        Assert.AreEqual(OldFixedMul64(LA, LB), LResult, Format('Mul64 %d %d', [LA, LB]));
{$IFEND}
      LFingerprint.AddInt64(LResult);
    end;
    FGolden.Check('fixedmul64wide.mul64', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreFixedMul64Wide.DovrebbeArrotondareDueVolteOltreSessantaquattroBit;
begin
  // Values worked out by hand. (2^40 - 1) * (2^40 + 1) = 2^80 - 1: the 64 bit mantissa rounds it to 2^80
  // (a carry), 2^80 / 2^16 = 2^64 does not fit and the result is the integer indefinite
  Assert.AreEqual(Low(Int64), TFixedMath.Mul64((Int64(1) shl 40) - 1, (Int64(1) shl 40) + 1));
  // (2^40 + 1) * (2^30 + 1) = 2^70 + 2^40 + 2^30 + 1: 71 bits, 7 are dropped from the 64 significant
  // ones; the 7 bits dropped are 0000001 (less than a half): rounded down, then the 16 bits of the
  // fraction (all the bits above 2^6 left are 2^40 + 2^30 shifted: 2^70 / 2^16 = 2^54 plus 2^24 and 2^14)
  Assert.AreEqual((Int64(1) shl 54) + (Int64(1) shl 24) + (Int64(1) shl 14),
    TFixedMath.Mul64((Int64(1) shl 40) + 1, (Int64(1) shl 30) + 1));
end;

procedure TTestMathCoreFixedMul64Wide.DovrebbeDareIlRisultatoDelCalcoloInSoftware;
var
  LExponentA, LExponentB, LDeltaA, LDeltaB: Integer;
  LA, LB: Int64;
begin
  // factors next to a power of two make products with every length of mantissa and the carries of the
  // first rounding; the oracle is the Extended in software, which is proved bit for bit against the FPU
  for LExponentA := 32 to 62 do
    for LExponentB := 32 to 62 do
      if LExponentA + LExponentB < 78 then
        for LDeltaA := -1 to 1 do
          for LDeltaB := -1 to 1 do
          begin
            LA := (Int64(1) shl LExponentA) + LDeltaA;
            LB := (Int64(1) shl LExponentB) + LDeltaB;
            Assert.AreEqual((TSoftExtended.FromInt64(LA) / TSoftExtended.FromInt64(65536) *
              TSoftExtended.FromInt64(LB)).Round, TFixedMath.Mul64(LA, LB), Format('%d * %d', [LA, LB]));
          end;
end;

procedure TTestMathCoreFixedMul64Wide.DovrebbeDareLInteroIndefinitoSeIlRisultatoNonEntra;
begin
  // 2^63 * 2^31 / 2^16 = 2^78: more than an Int64 holds
  Assert.AreEqual(Low(Int64), TFixedMath.Mul64(Low(Int64), Int64(1) shl 31));
  Assert.AreEqual(Low(Int64), TFixedMath.Mul64(Int64(1) shl 62, Int64(1) shl 32));
  Assert.AreEqual(Low(Int64), TFixedMath.Mul64(Int64(1) shl 62, -(Int64(1) shl 32)));
  Assert.AreEqual(Low(Int64), TFixedMath.Mul64(High(Int64), High(Int64)));
  // the last that fits
  Assert.AreEqual(Int64(1) shl 62, TFixedMath.Mul64(Int64(1) shl 62, 65536));
  Assert.AreEqual(-(Int64(1) shl 62), TFixedMath.Mul64(-(Int64(1) shl 62), 65536));
end;

procedure TTestMathCoreFixedMul64Wide.DovrebbeMoltiplicareIValoriLimiteSenzaSollevare;
begin
  Assert.AreEqual(Int64(0), TFixedMath.Mul64(Low(Int64), 0));
  Assert.AreEqual(Int64(0), TFixedMath.Mul64(0, Low(Int64)));
  Assert.AreEqual(Low(Int64), TFixedMath.Mul64(Low(Int64), 65536));
  Assert.AreEqual(Int64(1) shl 47, TFixedMath.Mul64(Int64(1) shl 47, 65536));
  Assert.AreEqual(High(Int64), TFixedMath.Mul64(High(Int64), 65536));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMathCoreFixedMul64Wide);

end.
