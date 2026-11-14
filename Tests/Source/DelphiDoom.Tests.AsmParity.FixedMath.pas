{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - fixed point and shifts    }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AsmParity.FixedMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of the old assembler of m_fixed, r_softlights, p_local and of the shifts of d_delphi
  ///   (copied in DelphiDoom.Tests.AsmParity.Oracles) with the Pascal ones of TFixedMath, on the limit
  ///   values and on millions of pseudo random inputs. In the 32 bit build the assembler runs and
  ///   is compared result by result; in the 64 bit build, where it cannot run, the Pascal results
  ///   on the same inputs must have the fingerprint that the assembler gave at 32 bit
  ///   (Tests\Data\MathCore\asm.golden.txt).
  /// </summary>
  [TestFixture]
  [Category('asm')]
  TTestAsmFixedMath = class(TObject)
  public
    [Test]
    procedure DovrebbeMoltiplicareCometFixedMul;
    [Test]
    procedure DovrebbeMoltiplicareEScorrereCometFixedMulShl;
    [Test]
    procedure DovrebbeMoltiplicareEDividereCometFixedMulDiv;
    [Test]
    procedure DovrebbeMoltiplicareConLeVarianti88E8;
    [Test]
    procedure DovrebbeMoltiplicareConLaParteIntera;
    [Test]
    procedure DovrebbeDareLaParteInteraCometFixedInt;
    [Test]
    procedure DovrebbeDividereCometFixedDiv2ESollevareNegliStessiCasi;
    [Test]
    procedure DovrebbeDividereCometFixedDivFastESollevareNegliStessiCasi;
    [Test]
    procedure DovrebbeDividereCometFixedDivLWESollevareNegliStessiCasi;
    [Test]
    procedure DovrebbeCalcolareIlFattoreDellaLuceCometAsmCalcFactor;
    [Test]
    procedure DovrebbeScorrereConSegnoCometSar;
    [Test]
    procedure DovrebbeScorrereAVariabileConLaStessaMaschera;
    [Test]
    procedure DovrebbeScorrereASinistraConLaStessaMaschera;
    [Test]
    procedure DovrebbeCalcolareIlBloccoDellaMappaCometMapBlockInt;
    [Test]
    procedure DovrebbeCalcolareLaFrazioneDellaMappaCometMapToFrac;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.Tests.AsmParity.Oracles, DelphiDoom.Tests.AsmParity.Parity;

const
  // the inputs of the functions that never raise; the ones that can raise are slower
  RANDOM_PAIRS = 1000000;
  RANDOM_PAIRS_RAISING = 100000;

{ TTestAsmFixedMath }

procedure TTestAsmFixedMath.DovrebbeMoltiplicareCometFixedMul;
begin
  TParityRunner.CompareBinary('FixedMul', TAsmOracles.Binary('FixedMul'),
    function(A, B: Integer): Integer begin Result := TFixedMath.Mul(A, B); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareEScorrereCometFixedMulShl;
begin
  TParityRunner.CompareBinary('FixedMulShl3', TAsmOracles.Binary('FixedMulShl3'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl3(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl4', TAsmOracles.Binary('FixedMulShl4'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl4(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl5', TAsmOracles.Binary('FixedMulShl5'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl5(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl8', TAsmOracles.Binary('FixedMulShl8'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl8(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl10', TAsmOracles.Binary('FixedMulShl10'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl10(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl14', TAsmOracles.Binary('FixedMulShl14'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl14(A, B); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareEDividereCometFixedMulDiv;
begin
  TParityRunner.CompareBinary('FixedMulDiv8', TAsmOracles.Binary('FixedMulDiv8'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv8(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulDiv16', TAsmOracles.Binary('FixedMulDiv16'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv16(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulDiv256', TAsmOracles.Binary('FixedMulDiv256'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv256(A, B); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareConLeVarianti88E8;
begin
  TParityRunner.CompareBinary('FixedMul88', TAsmOracles.Binary('FixedMul88'),
    function(A, B: Integer): Integer begin Result := TFixedMath.Mul88(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMul8', TAsmOracles.Binary('FixedMul8'),
    function(A, B: Integer): Integer begin Result := TFixedMath.Mul8(A, B); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareConLaParteIntera;
begin
  TParityRunner.CompareBinary('FixedIntMul', TAsmOracles.Binary('FixedIntMul'),
    function(A, B: Integer): Integer begin Result := TFixedMath.MulByInteger(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('IntFixedMul', TAsmOracles.Binary('IntFixedMul'),
    function(A, B: Integer): Integer begin Result := TFixedMath.IntegerMul(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedInt_FixedMul', TAsmOracles.Binary('FixedInt_FixedMul'),
    function(A, B: Integer): Integer begin Result := TFixedMath.IntegerOfMul(A, B); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeDareLaParteInteraCometFixedInt;
begin
  TParityRunner.CompareUnary('FixedInt', TAsmOracles.Unary('FixedInt'),
    function(A: Integer): Integer begin Result := TFixedMath.ToInteger(A); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeDividereCometFixedDiv2ESollevareNegliStessiCasi;
begin
  TParityRunner.CompareBinary('FixedDiv2', TAsmOracles.Binary('FixedDiv2'),
    function(A, B: Integer): Integer begin Result := TFixedMath.DivideRaw(A, B); end,
    RANDOM_PAIRS_RAISING);
end;

procedure TTestAsmFixedMath.DovrebbeDividereCometFixedDivFastESollevareNegliStessiCasi;
begin
  TParityRunner.CompareBinary('FixedDiv_fast', TAsmOracles.Binary('FixedDiv_fast'),
    function(A, B: Integer): Integer begin Result := TFixedMath.DivideFast(A, B); end,
    RANDOM_PAIRS_RAISING);
end;

procedure TTestAsmFixedMath.DovrebbeDividereCometFixedDivLWESollevareNegliStessiCasi;
begin
  TParityRunner.CompareBinaryUnsigned('FixedDivLW', TAsmOracles.BinaryUnsigned('FixedDivLW'),
    function(A, B: Cardinal): Cardinal begin Result := TFixedMath.DivideUnsigned(A, B); end,
    RANDOM_PAIRS_RAISING);
end;

procedure TTestAsmFixedMath.DovrebbeCalcolareIlFattoreDellaLuceCometAsmCalcFactor;
begin
  TParityRunner.CompareBinaryUnsigned('ASM_CalcFactor', TAsmOracles.BinaryUnsigned('ASM_CalcFactor'),
    function(A, B: Cardinal): Cardinal begin Result := TFixedMath.OneMinusDivideUnsigned(A, B); end,
    RANDOM_PAIRS_RAISING);
end;

procedure TTestAsmFixedMath.DovrebbeScorrereConSegnoCometSar;
begin
  TParityRunner.CompareUnary('_SHR1', TAsmOracles.Unary('_SHR1'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 1); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR2', TAsmOracles.Unary('_SHR2'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 2); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR3', TAsmOracles.Unary('_SHR3'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 3); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR4', TAsmOracles.Unary('_SHR4'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 4); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR7', TAsmOracles.Unary('_SHR7'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 7); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR8', TAsmOracles.Unary('_SHR8'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 8); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR14', TAsmOracles.Unary('_SHR14'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 14); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeScorrereAVariabileConLaStessaMaschera;
begin
  // the Pascal _SHR of d_delphi is TFixedMath.ShiftRight(x, bits and 31): the processor uses the
  // low five bits of the count
  TParityRunner.CompareBinary('_SHR', TAsmOracles.Binary('_SHR'),
    function(A, B: Integer): Integer begin Result := TFixedMath.ShiftRight(A, B and 31); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeScorrereASinistraConLaStessaMaschera;
begin
  // the Pascal _SHL of d_delphi is x shl (bits and 31)
  TParityRunner.CompareBinary('_SHL', TAsmOracles.Binary('_SHL'),
    function(A, B: Integer): Integer begin Result := A shl (B and 31); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeCalcolareIlBloccoDellaMappaCometMapBlockInt;
begin
  // MAPBLOCKSHIFT = FRACBITS + 7
  TParityRunner.CompareUnary('MapBlockInt', TAsmOracles.Unary('MapBlockInt'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 23); end,
    RANDOM_PAIRS);
end;

procedure TTestAsmFixedMath.DovrebbeCalcolareLaFrazioneDellaMappaCometMapToFrac;
begin
  // MAPBTOFRAC = MAPBLOCKSHIFT - FRACBITS
  TParityRunner.CompareUnary('MapToFrac', TAsmOracles.Unary('MapToFrac'),
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 7); end,
    RANDOM_PAIRS);
end;

end.
