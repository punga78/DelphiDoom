{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math library - the accumulators of the walls of    }
{  the 3D floors (TX87Double)                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.X87DoubleSteps;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   MultiplyAdd, ProductPlusCount and TruncSumDivide of TX87Double (issue #40, the _DBL functions of
  ///   r_3dfloors.pas). At 32 bit each result is compared with the expression computed by the FPU; the
  ///   fingerprint is a constant and at 64 bit the same fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestX87DoubleSteps = class(TObject)
  public
    [Test]
    procedure DovrebbeSommareUnPassoMoltiplicato;
    [Test]
    procedure DovrebbeSommareUnProdottoEUnPassoMoltiplicato;
    [Test]
    procedure DovrebbeTroncareUnaSommaDivisa;
  end;

implementation

uses
  DelphiDoom.MathCore.X87Double, DelphiDoom.Tests.MathCore.Fingerprint;

const
  CASES = 200000;

type
  TRandomSource = record
    State: Cardinal;
    function Next: Cardinal;
    function NextDouble(AScale: Integer): Double;
  end;

function TRandomSource.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State xor (State shr 13);
end;

function TRandomSource.NextDouble(AScale: Integer): Double;
var
  LBits: Int64;
begin
  LBits := (Int64(Next and $1FFFFF) shl 32) or Int64(Next);
  Result := LBits / 9007199254740992.0 * AScale;
  if Next and 1 = 1 then
    Result := -Result;
end;

function SameBits(const A, B: Double): Boolean;
begin
  Result := PUInt64(@A)^ = PUInt64(@B)^;
end;

{ TTestX87DoubleSteps }

procedure TTestX87DoubleSteps.DovrebbeSommareUnPassoMoltiplicato;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex, LCount: Integer;
  LBase, LStep, LResult: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := 5001;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LBase := LRandom.NextDouble(1 shl 22);
      LStep := LRandom.NextDouble(1 shl 12);
      LCount := Integer(LRandom.Next mod 640);
      LResult := TX87Double.MultiplyAdd(LBase, LCount, LStep);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := LBase + LCount * LStep;
      Assert.IsTrue(SameBits(LNative, LResult), Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LResult);
    end;
    Assert.AreEqual('75FCAF0ED3187911/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestX87DoubleSteps.DovrebbeSommareUnProdottoEUnPassoMoltiplicato;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex, LCount: Integer;
  LA, LB, LStep, LResult: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := 5002;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LA := LRandom.NextDouble(1 shl 10);
      LB := LRandom.NextDouble(1 shl 20);
      LStep := LRandom.NextDouble(1 shl 20);
      LCount := Integer(LRandom.Next mod 640);
      LResult := TX87Double.ProductPlusCount(LA, LB, LCount, LStep);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := LA * LB + LCount * LStep;
      Assert.IsTrue(SameBits(LNative, LResult), Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LResult);
    end;
    Assert.AreEqual('D591EA3139E7AD0A/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestX87DoubleSteps.DovrebbeTroncareUnaSommaDivisa;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex, LResult: Integer;
  LA, LB: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Integer;
  {$IFEND}
begin
  LRandom.State := 5003;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LA := LRandom.NextDouble(1 shl 22);
      LB := LRandom.NextDouble(1 shl 22);
      if LIndex mod 3 = 0 then
        LB := -LA + LRandom.NextDouble(1 shl 8);
      LResult := TX87Double.TruncSumDivide(LA, LB, 65536);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Trunc((LA + LB) / 65536);
      Assert.AreEqual(LNative, LResult, Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LResult);
    end;
    Assert.AreEqual('372D48A5C765A7C1/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
