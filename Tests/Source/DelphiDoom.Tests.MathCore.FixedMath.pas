{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the fixed point arithmetic     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.FixedMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.MathCore.Golden,
  DelphiDoom.Tests.MathCore.PairRunner;

type
  /// <summary>
  ///   Parity with the old m_fixed (golden file fixed.golden.txt, made by the old code on the
  ///   pairs of TMathCoreSamples) and a few values written by hand
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreFixedMath = class(TObject)
  private
    FGolden: TGoldenFile;
    FRunner: TPairRunner;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMoltiplicareCometFixedMul;
    [Test]
    procedure DovrebbeMoltiplicareEScorrereCometFixedMulShl;
    [Test]
    procedure DovrebbeMoltiplicareEDividereCometFixedMulDiv;
    [Test]
    procedure DovrebbeArrotondareCometFixedMulEx;
    [Test]
    procedure DovrebbeMoltiplicareConLeVarianti88E8;
    [Test]
    procedure DovrebbeMoltiplicareConLaParteIntera;
    [Test]
    procedure DovrebbeDividereCometFixedDiv;
    [Test]
    procedure DovrebbeDividereCometFixedDivPositive;
    [Test]
    procedure DovrebbeDividereCometFixedDivFast;
    [Test]
    procedure DovrebbeDividereCometFixedDivEx;
    [Test]
    procedure DovrebbeDividereCometFixedDiv2;
    [Test]
    procedure DovrebbeDividereCometFixedDivLW;
    [Test]
    procedure DovrebbeCalcolareIlModuloCometFixedMod;
    [Test]
    procedure DovrebbeConvertireDaEVersoVirgolaMobile;
    [Test]
    procedure DovrebbeCalcolareLaRadiceCometFixedSqrt;
    [Test]
    procedure DovrebbeCalcolareConInteriA64Bit;

    [Test]
    procedure DovrebbeMoltiplicareUnoPerUno;
    [Test]
    procedure DovrebbeMoltiplicareNumeriNegativi;
    [Test]
    procedure DovrebbeSaturareLaDivisioneTroppoGrande;
    [Test]
    procedure DovrebbeSaturareLaDivisionePerZeroSecondoIlSegno;
    [Test]
    procedure DovrebbeSollevareUnErroreNellaDivisioneGrezzaPerZero;
    [Test]
    procedure DovrebbeSollevareUnErroreNellaDivisioneGrezzaCheNonEntra;
    [Test]
    procedure DovrebbeScorrereConSegno;
    [Test]
    procedure DovrebbeArrotondareLeMetaAlNumeroPari;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath;

{ TTestMathCoreFixedMath }

procedure TTestMathCoreFixedMath.Setup;
begin
  FGolden := TGoldenFile.Create('fixed.golden.txt');
  FRunner := TPairRunner.Create(FGolden);
end;

procedure TTestMathCoreFixedMath.TearDown;
begin
  FRunner.Free;
  FGolden.Free;
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareCometFixedMul;
begin
  FRunner.Bin('fixed.Mul', function(A, B: Integer): Integer begin Result := TFixedMath.Mul(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareEScorrereCometFixedMulShl;
begin
  FRunner.Bin('fixed.MulShl3', function(A, B: Integer): Integer begin Result := TFixedMath.MulShl3(A, B); end);
  FRunner.Bin('fixed.MulShl4', function(A, B: Integer): Integer begin Result := TFixedMath.MulShl4(A, B); end);
  FRunner.Bin('fixed.MulShl5', function(A, B: Integer): Integer begin Result := TFixedMath.MulShl5(A, B); end);
  FRunner.Bin('fixed.MulShl8', function(A, B: Integer): Integer begin Result := TFixedMath.MulShl8(A, B); end);
  FRunner.Bin('fixed.MulShl10', function(A, B: Integer): Integer begin Result := TFixedMath.MulShl10(A, B); end);
  FRunner.Bin('fixed.MulShl14', function(A, B: Integer): Integer begin Result := TFixedMath.MulShl14(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareEDividereCometFixedMulDiv;
begin
  FRunner.Bin('fixed.MulDiv8', function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv8(A, B); end);
  FRunner.Bin('fixed.MulDiv16', function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv16(A, B); end);
  FRunner.Bin('fixed.MulDiv256', function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv256(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeArrotondareCometFixedMulEx;
begin
  FRunner.Bin('fixed.MulRounded', function(A, B: Integer): Integer begin Result := TFixedMath.MulRounded(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareConLeVarianti88E8;
begin
  FRunner.Bin('fixed.Mul88', function(A, B: Integer): Integer begin Result := TFixedMath.Mul88(A, B); end);
  FRunner.Bin('fixed.Mul8', function(A, B: Integer): Integer begin Result := TFixedMath.Mul8(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareConLaParteIntera;
begin
  FRunner.Bin('fixed.MulByInteger', function(A, B: Integer): Integer begin Result := TFixedMath.MulByInteger(A, B); end);
  FRunner.Bin('fixed.IntegerMul', function(A, B: Integer): Integer begin Result := TFixedMath.IntegerMul(A, B); end);
  FRunner.Bin('fixed.IntegerOfMul', function(A, B: Integer): Integer begin Result := TFixedMath.IntegerOfMul(A, B); end);
  FRunner.Unary('fixed.ToInteger', function(A: Integer): Integer begin Result := TFixedMath.ToInteger(A); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeDividereCometFixedDiv;
begin
  FRunner.Bin('fixed.Divide', function(A, B: Integer): Integer begin Result := TFixedMath.Divide(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeDividereCometFixedDivPositive;
begin
  FRunner.Bin('fixed.DividePositive', function(A, B: Integer): Integer begin Result := TFixedMath.DividePositive(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeDividereCometFixedDivFast;
begin
  FRunner.Bin('fixed.DivideFast', function(A, B: Integer): Integer begin Result := TFixedMath.DivideFast(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeDividereCometFixedDivEx;
begin
  FRunner.Bin('fixed.DivideEx', function(A, B: Integer): Integer begin Result := TFixedMath.DivideEx(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeDividereCometFixedDiv2;
begin
  FRunner.Bin('fixed.DivideRaw', function(A, B: Integer): Integer begin Result := TFixedMath.DivideRaw(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeDividereCometFixedDivLW;
begin
  FRunner.BinUnsigned('fixed.DivideUnsigned',
    function(A, B: Cardinal): Cardinal begin Result := TFixedMath.DivideUnsigned(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeCalcolareIlModuloCometFixedMod;
begin
  FRunner.Bin('fixed.Modulo', function(A, B: Integer): Integer begin Result := TFixedMath.Modulo(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeConvertireDaEVersoVirgolaMobile;
begin
  FRunner.Unary('fixed.FromSingle', function(A: Integer): Integer begin Result := TFixedMath.FromSingle(Single(A / 4096.0)); end);
  FRunner.Unary('fixed.FromDouble', function(A: Integer): Integer begin Result := TFixedMath.FromDouble(A / 4096.0); end);
  FRunner.Unary('fixed.FromExtended', function(A: Integer): Integer begin Result := TFixedMath.FromExtended(Extended(A / 4096.0)); end);
  FRunner.UnaryDouble('fixed.ToSingle', function(A: Integer): Double begin Result := TFixedMath.ToSingle(A); end);
  FRunner.UnaryDouble('fixed.ToDouble', function(A: Integer): Double begin Result := TFixedMath.ToDouble(A); end);
  FRunner.UnaryDouble('fixed.ToExtended', function(A: Integer): Double begin Result := TFixedMath.ToExtended(A); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeCalcolareLaRadiceCometFixedSqrt;
begin
  FRunner.Unary('fixed.Sqrt', function(A: Integer): Integer begin Result := TFixedMath.Sqrt(A and $7FFFFFFF); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeCalcolareConInteriA64Bit;
begin
  FRunner.Bin64('fixed.Int64ToInteger', function(A, B: Integer): Int64 begin Result := TFixedMath.Int64ToInteger(Int64(A) * B); end);
  FRunner.Bin64('fixed.Mul64', function(A, B: Integer): Int64 begin Result := TFixedMath.Mul64(Int64(A), Int64(B)); end);
  FRunner.BinDouble('fixed.FloatDivide', function(A, B: Integer): Double begin Result := TFixedMath.FloatDivide(A, B); end);
  FRunner.BinDouble('fixed.FloatMul', function(A, B: Integer): Double begin Result := TFixedMath.FloatMul(A, B); end);
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareUnoPerUno;
begin
  Assert.AreEqual(FIXED_ONE, TFixedMath.Mul(FIXED_ONE, FIXED_ONE));
  Assert.AreEqual(6 * FIXED_ONE, TFixedMath.Mul(2 * FIXED_ONE, 3 * FIXED_ONE));
  Assert.AreEqual(FIXED_ONE div 4, TFixedMath.Mul(FIXED_ONE div 2, FIXED_ONE div 2));
end;

procedure TTestMathCoreFixedMath.DovrebbeMoltiplicareNumeriNegativi;
begin
  Assert.AreEqual(-6 * FIXED_ONE, TFixedMath.Mul(-2 * FIXED_ONE, 3 * FIXED_ONE));
  Assert.AreEqual(6 * FIXED_ONE, TFixedMath.Mul(-2 * FIXED_ONE, -3 * FIXED_ONE));
end;

procedure TTestMathCoreFixedMath.DovrebbeSaturareLaDivisioneTroppoGrande;
begin
  Assert.AreEqual(FIXED_MAX, TFixedMath.Divide(FIXED_MAX, 1));
  Assert.AreEqual(FIXED_MIN, TFixedMath.Divide(-FIXED_MAX, 1));
  Assert.AreEqual(2 * FIXED_ONE, TFixedMath.Divide(6 * FIXED_ONE, 3 * FIXED_ONE));
end;

procedure TTestMathCoreFixedMath.DovrebbeSaturareLaDivisionePerZeroSecondoIlSegno;
begin
  Assert.AreEqual(FIXED_MAX, TFixedMath.Divide(FIXED_ONE, 0));
  Assert.AreEqual(FIXED_MIN, TFixedMath.Divide(-FIXED_ONE, 0));
  Assert.AreEqual(FIXED_MAX, TFixedMath.DivideFast(-FIXED_ONE, 0));
  Assert.AreEqual(FIXED_MIN, TFixedMath.DivideEx(-FIXED_ONE, 0));
end;

procedure TTestMathCoreFixedMath.DovrebbeSollevareUnErroreNellaDivisioneGrezzaPerZero;
begin
  Assert.WillRaise(
    procedure
    begin
      TFixedMath.DivideRaw(FIXED_ONE, 0);
    end, EMathCoreException);
end;

procedure TTestMathCoreFixedMath.DovrebbeSollevareUnErroreNellaDivisioneGrezzaCheNonEntra;
begin
  // the old code raised the exception of the processor
  Assert.WillRaise(
    procedure
    begin
      TFixedMath.DivideRaw(FIXED_MAX, 1);
    end, EMathCoreException);
end;

procedure TTestMathCoreFixedMath.DovrebbeScorrereConSegno;
begin
  Assert.AreEqual(-1, TFixedMath.ShiftRight(-1, 8));
  Assert.AreEqual(-2, TFixedMath.ShiftRight(-257, 8));
  Assert.AreEqual(1, TFixedMath.ShiftRight(257, 8));
  Assert.AreEqual(-3, TFixedMath.ToInteger(-3 * FIXED_ONE));
end;

procedure TTestMathCoreFixedMath.DovrebbeArrotondareLeMetaAlNumeroPari;
begin
  // 0.5 goes to 0, 1.5 to 2, 2.5 to 2, -0.5 to 0, -1.5 to -2
  Assert.AreEqual<Int64>(0, TFixedMath.RoundDivide(1, 2));
  Assert.AreEqual<Int64>(2, TFixedMath.RoundDivide(3, 2));
  Assert.AreEqual<Int64>(2, TFixedMath.RoundDivide(5, 2));
  Assert.AreEqual<Int64>(0, TFixedMath.RoundDivide(-1, 2));
  Assert.AreEqual<Int64>(-2, TFixedMath.RoundDivide(-3, 2));
  Assert.AreEqual<Int64>(-4, TFixedMath.RoundDivide(-7, 2));
  Assert.AreEqual<Int64>(2, TFixedMath.RoundDivide(7, 3));
end;

end.
