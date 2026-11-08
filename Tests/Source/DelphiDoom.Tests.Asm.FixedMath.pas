{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - fixed point and shifts    }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Asm.FixedMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of the old assembler of m_fixed, r_softlights, p_local and of the shifts of d_delphi
  ///   (copied in DelphiDoom.Tests.Asm.Oracles) with the Pascal ones of TFixedMath, on the limit
  ///   values and on millions of pseudo random inputs. Only for the 32 bit build, where the
  ///   assembler can run.
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

{$IFDEF CPUX86}

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.Tests.Asm.Oracles, DelphiDoom.Tests.Asm.Parity;

const
  // the inputs of the functions that never raise; the ones that can raise are slower
  RANDOM_PAIRS = 1000000;
  RANDOM_PAIRS_RAISING = 100000;

{$ENDIF}

{ TTestAsmFixedMath }

procedure TTestAsmFixedMath.DovrebbeMoltiplicareCometFixedMul;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedMul',
    function(A, B: Integer): Integer begin Result := OldFixedMul(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.Mul(A, B); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareEScorrereCometFixedMulShl;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedMulShl3',
    function(A, B: Integer): Integer begin Result := OldFixedMulShl3(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl3(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl4',
    function(A, B: Integer): Integer begin Result := OldFixedMulShl4(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl4(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl5',
    function(A, B: Integer): Integer begin Result := OldFixedMulShl5(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl5(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl8',
    function(A, B: Integer): Integer begin Result := OldFixedMulShl8(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl8(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl10',
    function(A, B: Integer): Integer begin Result := OldFixedMulShl10(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl10(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulShl14',
    function(A, B: Integer): Integer begin Result := OldFixedMulShl14(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulShl14(A, B); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareEDividereCometFixedMulDiv;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedMulDiv8',
    function(A, B: Integer): Integer begin Result := OldFixedMulDiv8(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv8(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulDiv16',
    function(A, B: Integer): Integer begin Result := OldFixedMulDiv16(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv16(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMulDiv256',
    function(A, B: Integer): Integer begin Result := OldFixedMulDiv256(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulDiv256(A, B); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareConLeVarianti88E8;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedMul88',
    function(A, B: Integer): Integer begin Result := OldFixedMul88(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.Mul88(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedMul8',
    function(A, B: Integer): Integer begin Result := OldFixedMul8(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.Mul8(A, B); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeMoltiplicareConLaParteIntera;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedIntMul',
    function(A, B: Integer): Integer begin Result := OldFixedIntMul(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.MulByInteger(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('IntFixedMul',
    function(A, B: Integer): Integer begin Result := OldIntFixedMul(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.IntegerMul(A, B); end,
    RANDOM_PAIRS);
  TParityRunner.CompareBinary('FixedInt_FixedMul',
    function(A, B: Integer): Integer begin Result := OldFixedInt_FixedMul(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.IntegerOfMul(A, B); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeDareLaParteInteraCometFixedInt;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareUnary('FixedInt',
    function(A: Integer): Integer begin Result := OldFixedInt(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ToInteger(A); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeDividereCometFixedDiv2ESollevareNegliStessiCasi;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedDiv2',
    function(A, B: Integer): Integer begin Result := OldFixedDiv2(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.DivideRaw(A, B); end,
    RANDOM_PAIRS_RAISING);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeDividereCometFixedDivFastESollevareNegliStessiCasi;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinary('FixedDiv_fast',
    function(A, B: Integer): Integer begin Result := OldFixedDiv_fast(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.DivideFast(A, B); end,
    RANDOM_PAIRS_RAISING);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeDividereCometFixedDivLWESollevareNegliStessiCasi;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinaryUnsigned('FixedDivLW',
    function(A, B: Cardinal): Cardinal begin Result := OldFixedDivLW(A, B); end,
    function(A, B: Cardinal): Cardinal begin Result := TFixedMath.DivideUnsigned(A, B); end,
    RANDOM_PAIRS_RAISING);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeCalcolareIlFattoreDellaLuceCometAsmCalcFactor;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareBinaryUnsigned('ASM_CalcFactor',
    function(A, B: Cardinal): Cardinal begin Result := OldCalcFactor(A, B); end,
    function(A, B: Cardinal): Cardinal begin Result := TFixedMath.OneMinusDivideUnsigned(A, B); end,
    RANDOM_PAIRS_RAISING);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeScorrereConSegnoCometSar;
begin
  {$IFDEF CPUX86}
  TParityRunner.CompareUnary('_SHR1',
    function(A: Integer): Integer begin Result := OldSHR1(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 1); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR2',
    function(A: Integer): Integer begin Result := OldSHR2(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 2); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR3',
    function(A: Integer): Integer begin Result := OldSHR3(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 3); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR4',
    function(A: Integer): Integer begin Result := OldSHR4(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 4); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR7',
    function(A: Integer): Integer begin Result := OldSHR7(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 7); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR8',
    function(A: Integer): Integer begin Result := OldSHR8(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 8); end,
    RANDOM_PAIRS);
  TParityRunner.CompareUnary('_SHR14',
    function(A: Integer): Integer begin Result := OldSHR14(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 14); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeScorrereAVariabileConLaStessaMaschera;
begin
  {$IFDEF CPUX86}
  // the Pascal _SHR of d_delphi is TFixedMath.ShiftRight(x, bits and 31): the processor uses the
  // low five bits of the count
  TParityRunner.CompareBinary('_SHR',
    function(A, B: Integer): Integer begin Result := OldSHR(A, B); end,
    function(A, B: Integer): Integer begin Result := TFixedMath.ShiftRight(A, B and 31); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeScorrereASinistraConLaStessaMaschera;
begin
  {$IFDEF CPUX86}
  // the Pascal _SHL of d_delphi is x shl (bits and 31)
  TParityRunner.CompareBinary('_SHL',
    function(A, B: Integer): Integer begin Result := OldSHL(A, B); end,
    function(A, B: Integer): Integer begin Result := A shl (B and 31); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeCalcolareIlBloccoDellaMappaCometMapBlockInt;
begin
  {$IFDEF CPUX86}
  // MAPBLOCKSHIFT = FRACBITS + 7
  TParityRunner.CompareUnary('MapBlockInt',
    function(A: Integer): Integer begin Result := OldMapBlockInt(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 23); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

procedure TTestAsmFixedMath.DovrebbeCalcolareLaFrazioneDellaMappaCometMapToFrac;
begin
  {$IFDEF CPUX86}
  // MAPBTOFRAC = MAPBLOCKSHIFT - FRACBITS
  TParityRunner.CompareUnary('MapToFrac',
    function(A: Integer): Integer begin Result := OldMapToFrac(A); end,
    function(A: Integer): Integer begin Result := TFixedMath.ShiftRight(A, 7); end,
    RANDOM_PAIRS);
  {$ELSE}
  Assert.Pass('Assembler comparison only in the 32 bit build');
  {$ENDIF}
end;

end.
