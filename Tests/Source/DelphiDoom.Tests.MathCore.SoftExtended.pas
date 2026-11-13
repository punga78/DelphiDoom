{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the Extended in software       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.SoftExtended;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.MathCore.Golden;

type
  /// <summary>
  ///   TSoftExtended against the Extended of the 32 bit FPU: at 32 bit every result is compared bit by bit with the
  ///   processor, and its fingerprint is the golden file (softextended.golden.txt); at 64 bit, where there is no
  ///   Extended, the same fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreSoftExtended = class(TObject)
  private
    FGolden: TGoldenFile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelleQuattroOperazioni;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiNelleCatene;
    [Test]
    procedure DovrebbeDareLeStesseSommeConNumeriVicini;
    [Test]
    procedure DovrebbeConvertireInDoubleEInInteroComeLaFpu;
    [Test]
    procedure DovrebbeDareLeCostantiDecimaliDelCompilatore;
    [Test]
    procedure DovrebbeConfrontareCorrettamente;
    [Test]
    procedure DovrebbeSollevareLaDivisionePerZero;
  end;

implementation

uses
  System.Math, DelphiDoom.MathCore.SoftExtended, DelphiDoom.Tests.MathCore.Fingerprint;

type
  TRandomSource = record
    State: UInt64;
    function Next: UInt64;
    function NextDouble: Double;
    function NextSmall: Double;
  end;

function TRandomSource.Next: UInt64;
begin
  State := State xor (State shl 13);
  State := State xor (State shr 7);
  State := State xor (State shl 17);
  Result := State;
end;

// a Double with a random sign, a random fraction and an exponent in -60..60
function TRandomSource.NextDouble: Double;
var
  LBits: UInt64;
begin
  LBits := Next;
  LBits := (LBits and $800FFFFFFFFFFFFF) or (UInt64(1023 - 60 + Integer(Next mod 121)) shl 52);
  Result := PDouble(@LBits)^;
end;

// now and then an integer or a number that a program writes: 0.299, 10, 65536
function TRandomSource.NextSmall: Double;
const
  NICE: array[0..11] of Double = (0.1, 0.299, 0.587, 0.114, 10, 65536, 1.5, 255, 0.5, 3.14159265, 1000, 0.9);
var
  LCase: Integer;
begin
  LCase := Integer(Next mod 4);
  case LCase of
    0:
      Result := Integer(Next mod 2001) - 1000;
    1:
      Result := NICE[Integer(Next mod 12)];
  else
    Result := NextDouble;
  end;
  if Result = 0 then
    Result := 1;
end;

{$IF SizeOf(Extended) > SizeOf(Double)}
function SameAsNative(const ASoft: TSoftExtended; const ANative: Extended): Boolean;
var
  LMantissa: UInt64;
  LExponent: Word;
begin
  LMantissa := PUInt64(@ANative)^;
  LExponent := PWord(PByte(@ANative) + 8)^;
  if LMantissa = 0 then
    Exit(ASoft.IsZero);
  Result := (ASoft.Mantissa = LMantissa) and (ASoft.BinaryExponent + 63 + 16383 = Integer(LExponent and $7FFF)) and
    (ASoft.IsNegative = ((LExponent and $8000) <> 0));
end;
{$IFEND}

procedure AddSoft(const AFingerprint: TFingerprint; const AValue: TSoftExtended);
begin
  AFingerprint.AddInt64(Int64(AValue.Mantissa));
  AFingerprint.AddInteger(AValue.BinaryExponent);
  AFingerprint.AddBoolean(AValue.IsNegative);
  AFingerprint.AddDouble(AValue.ToDouble);
  if Abs(AValue.ToDouble) < 4E18 then
  begin
    AFingerprint.AddInt64(AValue.Truncate);
    AFingerprint.AddInt64(AValue.Round);
  end;
end;

{ TTestMathCoreSoftExtended }

procedure TTestMathCoreSoftExtended.Setup;
begin
  FGolden := TGoldenFile.Create('softextended.golden.txt');
end;

procedure TTestMathCoreSoftExtended.TearDown;
begin
  FGolden.Free;
end;

procedure TTestMathCoreSoftExtended.DovrebbeDareGliStessiRisultatiDelleQuattroOperazioni;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB: Double;
  LSoft: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Extended;
  {$IFEND}
begin
  LRandom.State := $9E3779B97F4A7C15;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 79999 do
    begin
      if Odd(LIndex shr 2) then
        LA := LRandom.NextSmall
      else
        LA := LRandom.NextDouble;
      LB := LRandom.NextSmall;
      case LIndex mod 4 of
        0:
          LSoft := TSoftExtended.FromDouble(LA) + TSoftExtended.FromDouble(LB);
        1:
          LSoft := TSoftExtended.FromDouble(LA) - TSoftExtended.FromDouble(LB);
        2:
          LSoft := TSoftExtended.FromDouble(LA) * TSoftExtended.FromDouble(LB);
      else
        LSoft := TSoftExtended.FromDouble(LA) / TSoftExtended.FromDouble(LB);
      end;
      {$IF SizeOf(Extended) > SizeOf(Double)}
      case LIndex mod 4 of
        0:
          LNative := Extended(LA) + Extended(LB);
        1:
          LNative := Extended(LA) - Extended(LB);
        2:
          LNative := Extended(LA) * Extended(LB);
      else
        LNative := Extended(LA) / Extended(LB);
      end;
      Assert.IsTrue(SameAsNative(LSoft, LNative), Format('operation %d: %.17g and %.17g', [LIndex, LA, LB]));
      {$IFEND}
      AddSoft(LFingerprint, LSoft);
    end;
    FGolden.Check('softextended.operations', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreSoftExtended.DovrebbeDareGliStessiRisultatiNelleCatene;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB, LC: Double;
  LSoft: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Extended;
  {$IFEND}
begin
  LRandom.State := $D1B54A32D192ED03;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 59999 do
    begin
      LA := LRandom.NextDouble;
      LB := LRandom.NextSmall;
      LC := LRandom.NextSmall;
      // a * b + c, a / b * c, (a + b) * c, a - b * c and (a * b) / c: the intermediates stay in 64 bits
      case LIndex mod 5 of
        0:
          LSoft := TSoftExtended.FromDouble(LA) * TSoftExtended.FromDouble(LB) + TSoftExtended.FromDouble(LC);
        1:
          LSoft := TSoftExtended.FromDouble(LA) / TSoftExtended.FromDouble(LB) * TSoftExtended.FromDouble(LC);
        2:
          LSoft := (TSoftExtended.FromDouble(LA) + TSoftExtended.FromDouble(LB)) * TSoftExtended.FromDouble(LC);
        3:
          LSoft := TSoftExtended.FromDouble(LA) - TSoftExtended.FromDouble(LB) * TSoftExtended.FromDouble(LC);
      else
        LSoft := (TSoftExtended.FromDouble(LA) * TSoftExtended.FromDouble(LB)) / TSoftExtended.FromDouble(LC);
      end;
      {$IF SizeOf(Extended) > SizeOf(Double)}
      case LIndex mod 5 of
        0:
          LNative := Extended(LA) * Extended(LB) + Extended(LC);
        1:
          LNative := Extended(LA) / Extended(LB) * Extended(LC);
        2:
          LNative := (Extended(LA) + Extended(LB)) * Extended(LC);
        3:
          LNative := Extended(LA) - Extended(LB) * Extended(LC);
      else
        LNative := (Extended(LA) * Extended(LB)) / Extended(LC);
      end;
      Assert.IsTrue(SameAsNative(LSoft, LNative), Format('chain %d: %.17g, %.17g and %.17g', [LIndex, LA, LB, LC]));
      {$IFEND}
      AddSoft(LFingerprint, LSoft);
    end;
    FGolden.Check('softextended.chains', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreSoftExtended.DovrebbeDareLeStesseSommeConNumeriVicini;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB: Double;
  LBits: UInt64;
  LSoft: TSoftExtended;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Extended;
  {$IFEND}
begin
  // cancellations and numbers of the same size: the second one is the first with a few bits changed or a
  // little exponent away
  LRandom.State := $2545F4914F6CDD1D;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 39999 do
    begin
      LA := LRandom.NextDouble;
      LBits := PUInt64(@LA)^;
      case LIndex mod 4 of
        0:
          LBits := LBits xor (LRandom.Next and $FFF);
        1:
          LBits := LBits xor (LRandom.Next and $FFFFFFFFF);
        2:
          LBits := (LBits and $800FFFFFFFFFFFFF) or (((LBits shr 52) and $7FF) - Cardinal(LRandom.Next mod 3)) shl 52;
      else
        LBits := (LBits and $800FFFFFFFFFFFFF) or (((LBits shr 52) and $7FF) - Cardinal(60 + LRandom.Next mod 5)) shl 52;
      end;
      LB := PDouble(@LBits)^;
      if Odd(LIndex shr 2) then
        LB := -LB;
      LSoft := TSoftExtended.FromDouble(LA) + TSoftExtended.FromDouble(LB);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Extended(LA) + Extended(LB);
      Assert.IsTrue(SameAsNative(LSoft, LNative), Format('sum %d: %.17g and %.17g', [LIndex, LA, LB]));
      {$IFEND}
      AddSoft(LFingerprint, LSoft);
    end;
    FGolden.Check('softextended.sums', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreSoftExtended.DovrebbeConvertireInDoubleEInInteroComeLaFpu;
var
  LHalf, LOne, LTwoAndHalf: TSoftExtended;
begin
  LHalf := TSoftExtended.FromRatio(1, 2);
  LTwoAndHalf := TSoftExtended.FromRatio(5, 2);
  LOne := 1;
  Assert.AreEqual<Int64>(0, LHalf.Truncate, 'Truncate(0.5)');
  Assert.AreEqual<Int64>(0, LHalf.Round, 'Round(0.5), to the even');
  Assert.AreEqual<Int64>(2, LTwoAndHalf.Round, 'Round(2.5), to the even');
  Assert.AreEqual<Int64>(3, (LTwoAndHalf + LHalf).Round, 'Round(3.0)');
  Assert.AreEqual<Int64>(-2, (-LTwoAndHalf).Round, 'Round(-2.5)');
  Assert.AreEqual<Int64>(-2, (-LTwoAndHalf).Truncate, 'Truncate(-2.5)');
  Assert.AreEqual<Int64>(2, (LOne + LHalf).Round, 'Round(1.5), to the even');
  Assert.AreEqual(0.5, LHalf.ToDouble, 0.0);
  Assert.AreEqual(0.0, TSoftExtended.FromInt64(0).ToDouble, 0.0);
  Assert.AreEqual<Int64>(High(Int64), TSoftExtended.FromInt64(High(Int64)).Truncate);
  Assert.AreEqual<Int64>(Low(Int64) + 1, TSoftExtended.FromInt64(Low(Int64) + 1).Truncate);
  Assert.AreEqual<Int64>(-123456789012, TSoftExtended.FromInt64(-123456789012).Round);
end;

procedure TTestMathCoreSoftExtended.DovrebbeDareLeCostantiDecimaliDelCompilatore;
var
  LValue: TSoftExtended;
begin
  // 0.299 as a Double is not the Extended that the 32 bit compiler makes of the literal: the ratio is
  LValue := TSoftExtended.FromRatio(299, 1000);
  Assert.AreEqual(0.299, LValue.ToDouble, 0.0, 'the double of the ratio is the nearest double');
  LValue := TSoftExtended.FromRatio(1, 10);
  Assert.AreEqual(0.1, LValue.ToDouble, 0.0);
  Assert.AreEqual<UInt64>($CCCCCCCCCCCCCCCD, LValue.Mantissa, 'the 64 bits of 0.1');
end;

procedure TTestMathCoreSoftExtended.DovrebbeConfrontareCorrettamente;
var
  LOne, LTwo, LMinusOne, LZero: TSoftExtended;
begin
  LOne := 1;
  LTwo := 2;
  LMinusOne := -1;
  LZero := 0;
  Assert.IsTrue(LOne < LTwo);
  Assert.IsTrue(LTwo > LOne);
  Assert.IsTrue(LMinusOne < LZero);
  Assert.IsTrue(LMinusOne < LOne);
  Assert.IsTrue(LZero < LOne);
  Assert.IsTrue(LOne = TSoftExtended.FromDouble(1.0));
  Assert.IsTrue(LOne <> LTwo);
  Assert.IsTrue(LOne <= LOne);
  Assert.IsTrue(LOne >= LOne);
  Assert.IsTrue(LZero = -LZero);
  Assert.IsTrue(LOne - LOne = LZero);
end;

procedure TTestMathCoreSoftExtended.DovrebbeSollevareLaDivisionePerZero;
begin
  Assert.WillRaise(
    procedure
    var
      LValue: TSoftExtended;
    begin
      LValue := TSoftExtended.FromInt64(1) / TSoftExtended.FromInt64(0);
      if LValue.IsZero then
        Exit;
    end, EZeroDivide);
end;

end.
