{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the arc tangent in software    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.SoftArcTan;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TSoftArcTan against fpatan of the 32 bit FPU: the result is within a few units of the last of the 64
  ///   bits (it is not bit exact); at 64 bit, where there is no Extended, the fingerprint of the results (the
  ///   class uses integers only) must be the one of 32 bit
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreSoftArcTan = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLArcoTangenteVicinoAQuelloDellaFpu;
    [Test]
    procedure DovrebbeDareLArcoTangenteDiDueArgomentiInTuttiIQuadranti;
    [Test]
    procedure DovrebbeDareIValoriNotiDellArcoTangente;
  end;

implementation

uses
  System.Math, DelphiDoom.MathCore.SoftExtended, DelphiDoom.MathCore.SoftArcTan,
  DelphiDoom.Tests.MathCore.Fingerprint;

type
  TRandomSource = record
    State: Cardinal;
    function Next: Cardinal;
  end;

function TRandomSource.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State xor (State shr 13);
end;

{$IF SizeOf(Extended) > SizeOf(Double)}
// the Extended of the FPU as an exact sum of two Doubles
function FromNative(const AValue: Extended): TSoftExtended;
var
  LHigh, LLow: Double;
begin
  LHigh := AValue;
  LLow := AValue - LHigh;
  Result := TSoftExtended.FromDouble(LHigh) + TSoftExtended.FromDouble(LLow);
end;

// |A - B| / |B| in units of 2^-64
function Distance(const A, B: TSoftExtended): Double;
var
  LDifference: TSoftExtended;
begin
  LDifference := A - B;
  if LDifference.IsZero then
    Exit(0);
  if LDifference.IsNegative then
    LDifference := -LDifference;
  Result := (LDifference / TSoftExtended.FromDouble(Abs(B.ToDouble)) * TSoftExtended.FromMantissa(1, 64)).ToDouble;
end;
{$IFEND}

{ TTestMathCoreSoftArcTan }

procedure TTestMathCoreSoftArcTan.DovrebbeDareLArcoTangenteVicinoAQuelloDellaFpu;
const
  COUNT = 40000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LArgument: Double;
  LResult: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LWorst: Double;
  {$IFEND}
begin
  LRandom.State := 12;
  LFingerprint := TFingerprint.Create;
  try
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LWorst := 0;
    {$IFEND}
    for LIndex := 0 to COUNT - 1 do
    begin
      case LIndex mod 4 of
        0: LArgument := LRandom.Next / 4294967296.0;
        1: LArgument := 1.0 + (LRandom.Next / 4294967296.0) * 2.0;
        2: LArgument := -(LRandom.Next / 4294967296.0) * 1000.0;
      else
        LArgument := (Integer(LRandom.Next) div 65536) / 1024.0;
      end;
      LResult := TSoftArcTan.ArcTan(TSoftExtended.FromDouble(LArgument));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      if LArgument <> 0 then
        LWorst := Max(LWorst, Distance(LResult, FromNative(ArcTan(Extended(LArgument)))));
      {$IFEND}
      LFingerprint.AddDouble(LResult.ToDouble);
    end;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    Assert.IsTrue(LWorst < 16, Format('the worst result is %g units of the last bit from the FPU', [LWorst]));
    {$IFEND}
    Assert.AreEqual('A01CD9ADA04EA39C/40000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreSoftArcTan.DovrebbeDareLArcoTangenteDiDueArgomentiInTuttiIQuadranti;
const
  COUNT = 40000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LY, LX: Integer;
  LResult: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LWorst: Double;
  LNative: Extended;
  {$IFEND}
begin
  LRandom.State := 3;
  LFingerprint := TFingerprint.Create;
  try
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LWorst := 0;
    {$IFEND}
    for LIndex := 0 to COUNT - 1 do
    begin
      LY := Integer(LRandom.Next and 8191) - 4096;
      LX := Integer(LRandom.Next and 8191) - 4096;
      if LIndex mod 16 = 0 then
        LY := 0;
      if LIndex mod 17 = 0 then
        LX := 0;
      LResult := TSoftArcTan.ArcTan2(TSoftExtended.FromInt64(LY), TSoftExtended.FromInt64(LX));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := ArcTan2(Extended(LY), Extended(LX));
      if (LY <> 0) and (LX <> 0) then
        LWorst := Max(LWorst, Distance(LResult, FromNative(LNative)))
      else
        Assert.AreEqual(Double(LNative), LResult.ToDouble, 1E-18, Format('%d %d', [LY, LX]));
      {$IFEND}
      LFingerprint.AddDouble(LResult.ToDouble);
    end;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    Assert.IsTrue(LWorst < 32, Format('the worst result is %g units of the last bit from the FPU', [LWorst]));
    {$IFEND}
    Assert.AreEqual('9C740A4E25084C82/40000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreSoftArcTan.DovrebbeDareIValoriNotiDellArcoTangente;
var
  LPiOverFour: Double;
begin
  LPiOverFour := Pi / 4;
  // Pi is an Extended at 32 bit: the tolerance is a few units of the last bit of a Double
  Assert.AreEqual(LPiOverFour, TSoftArcTan.ArcTan(TSoftExtended.FromInt64(1)).ToDouble, 1E-15);
  Assert.AreEqual(-LPiOverFour, TSoftArcTan.ArcTan(TSoftExtended.FromInt64(-1)).ToDouble, 1E-15);
  Assert.AreEqual(Pi / 2, TSoftArcTan.ArcTan2(TSoftExtended.FromInt64(5), TSoftExtended.FromInt64(0)).ToDouble, 1E-15);
  Assert.AreEqual(Pi, TSoftArcTan.ArcTan2(TSoftExtended.FromInt64(0), TSoftExtended.FromInt64(-5)).ToDouble, 1E-15);
  Assert.AreEqual(-3 * Pi / 4, TSoftArcTan.ArcTan2(TSoftExtended.FromInt64(-2), TSoftExtended.FromInt64(-2)).ToDouble, 1E-15);
  Assert.IsTrue(TSoftArcTan.ArcTan(TSoftExtended.FromInt64(0)).IsZero);
end;

end.
