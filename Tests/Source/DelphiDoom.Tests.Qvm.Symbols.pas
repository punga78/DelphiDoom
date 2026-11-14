{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the symbols of a .map file, the      }
{  profile, and the float instructions on the bits                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Symbols;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Symbols;

type
  [TestFixture]
  [Category('Qvm')]
  TTestQvmSymbols = class
  strict private
    FSymbols: TQvmSymbols;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('cifre', '1f,31')]
    [TestCase('maiuscole', 'FF,255')]
    [TestCase('vuoto', ',0')]
    [TestCase('prefisso ignorato', '0x10,16')]
    [TestCase('caratteri saltati', 'g1-2z,18')]
    [TestCase('otto cifre', 'ffffffff,-1')]
    [TestCase('nove cifre avvolgono', '123456789,591751049')]
    procedure ParseHexDovrebbeFareComeLOriginale(const AText: string; AExpected: Integer);
    [Test]
    procedure SenzaSimboliDovrebbeDirlo;
    [Test]
    procedure DovrebbeTenereSoloISimboliDelSegmentoDelCodice;
    [Test]
    procedure IlValoreDovrebbeDiventareLOffsetDellIstruzione;
    [Test]
    procedure UnValoreCheNonEUnIstruzioneDovrebbeRestareComE;
    [Test]
    procedure DovrebbeDareNomePiuScartoPerUnIndirizzoDentroUnaFunzione;
    [Test]
    procedure PrimaDelPrimoSimboloLoScartoDovrebbeEssereNegativo;
    [Test]
    procedure DovrebbeCercareUnSimboloPerNomeDistinguendoLeMaiuscole;
    [Test]
    procedure DovrebbeSaltareCommentiEAccettareNomiTraVirgolette;
    [Test]
    procedure UnaRigaIncompletaDovrebbeFermareLaLetturaEdEssereSegnalata;
    [Test]
    procedure CaricareDiNuovoDovrebbeDimenticareISimboliDiPrima;
    [Test]
    procedure IlProfiloDovrebbeOrdinareDalMenoAlPiuEseguitoEAzzerare;
    [Test]
    procedure IlProfiloSenzaIstruzioniDovrebbeAvereTutteLePercentualiAZero;
    [Test]
    procedure IContiSuUnIndiceCheNonEsisteDovrebberoEssereIgnorati;
  end;

  [TestFixture]
  [Category('Qvm')]
  TTestQvmFloatMath = class
  public
    [Test]
    procedure DovrebbeRiconoscereInfinitiENaN;
    [Test]
    procedure UnNaNNonDovrebbeEssereUgualeNeMinoreDiNulla;
    [Test]
    procedure LoZeroNegativoDovrebbeEssereUgualeAlloZero;
    [Test]
    procedure IlConfrontoDovrebbeSeguireLOrdineDeiNumeri;
    [Test]
    [TestCase('zero', '0,0')]
    [TestCase('meno zero', '-2147483648,0')]
    [TestCase('mezzo', '1056964608,0')]
    [TestCase('uno', '1065353216,1')]
    [TestCase('meno uno e mezzo', '-1077936128,-1')]
    [TestCase('due virgola nove', '1077516698,2')]
    [TestCase('sedici milioni', '1266679808,16777216')]
    [TestCase('il piu grande che sta', '1325400063,2147483520')]
    [TestCase('due alla trentuno', '1325400064,-2147483648')]
    [TestCase('meno due alla trentuno', '-822083584,-2147483648')]
    [TestCase('infinito', '2139095040,-2147483648')]
    [TestCase('NaN', '2143289344,-2147483648')]
    [TestCase('denormale', '1,0')]
    procedure LaConversioneAInteroDovrebbeTroncareComeCvttss2si(ABits, AExpected: Integer);
    [Test]
    procedure UnOperandoNaNDovrebbeEssereIlRisultatoResoQuieto;
    [Test]
    procedure GliInfinitiDovrebberoSeguireLeRegoleIeee;
  end;

implementation

uses
  System.Math, DelphiDoom.Qvm.Opcodes, DelphiDoom.Qvm.FloatMath;

const
  // six instructions at these offsets
  POINTERS: array[0..5] of Integer = (0, 5, 6, 11, 20, 21);
  SAMPLE_MAP: AnsiString =
    '0 0 vmMain' + #10 +
    '0 2 helper' + #10 +
    '1 0 g_data' + #10 +
    '0 4 last' + #10 +
    '2 10 lit' + #10;

{ TTestQvmSymbols }

procedure TTestQvmSymbols.Setup;
var
  LPointers: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(LPointers, Length(POINTERS));
  for LIndex := 0 to High(POINTERS) do
    LPointers[LIndex] := POINTERS[LIndex];
  FSymbols := TQvmSymbols.Create(LPointers);
end;

procedure TTestQvmSymbols.TearDown;
begin
  FSymbols.Free;
end;

procedure TTestQvmSymbols.ParseHexDovrebbeFareComeLOriginale(const AText: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TQvmSymbols.ParseHex(AnsiString(AText)));
end;

procedure TTestQvmSymbols.SenzaSimboliDovrebbeDirlo;
begin
  Assert.AreEqual(0, FSymbols.Count);
  Assert.AreEqual<AnsiString>('NO SYMBOLS', FSymbols.ValueToSymbol(0));
  Assert.AreEqual(-1, FSymbols.FunctionIndex(0));
  Assert.AreEqual(0, FSymbols.SymbolToValue('vmMain'));
  Assert.AreEqual<Integer>(0, Length(FSymbols.TakeProfile.Entries));
end;

procedure TTestQvmSymbols.DovrebbeTenereSoloISimboliDelSegmentoDelCodice;
begin
  Assert.AreEqual(3, FSymbols.Load(SAMPLE_MAP));
  Assert.AreEqual(3, FSymbols.Count);
  Assert.IsFalse(FSymbols.IncompleteLine);
  Assert.AreEqual(0, FSymbols.SymbolToValue('g_data'));
  Assert.AreEqual(0, FSymbols.SymbolToValue('lit'));
end;

procedure TTestQvmSymbols.IlValoreDovrebbeDiventareLOffsetDellIstruzione;
begin
  FSymbols.Load(SAMPLE_MAP);
  Assert.AreEqual(0, FSymbols.SymbolToValue('vmMain'));
  Assert.AreEqual(6, FSymbols.SymbolToValue('helper'));
  Assert.AreEqual(20, FSymbols.SymbolToValue('last'));
end;

procedure TTestQvmSymbols.UnValoreCheNonEUnIstruzioneDovrebbeRestareComE;
begin
  // 6 instructions: 5 is the last one, 6 and above are left as they are
  FSymbols.Load('0 5 inside' + #10 + '0 6 outside' + #10 + '0 ff far');
  Assert.AreEqual(21, FSymbols.SymbolToValue('inside'));
  Assert.AreEqual(6, FSymbols.SymbolToValue('outside'));
  Assert.AreEqual(255, FSymbols.SymbolToValue('far'));
end;

procedure TTestQvmSymbols.DovrebbeDareNomePiuScartoPerUnIndirizzoDentroUnaFunzione;
begin
  FSymbols.Load(SAMPLE_MAP);
  Assert.AreEqual<AnsiString>('vmMain', FSymbols.ValueToSymbol(0));
  Assert.AreEqual<AnsiString>('vmMain+5', FSymbols.ValueToSymbol(5));
  Assert.AreEqual<AnsiString>('helper', FSymbols.ValueToSymbol(6));
  Assert.AreEqual<AnsiString>('helper+13', FSymbols.ValueToSymbol(19));
  Assert.AreEqual<AnsiString>('last', FSymbols.ValueToSymbol(20));
  Assert.AreEqual<AnsiString>('last+1000', FSymbols.ValueToSymbol(1020));
  Assert.AreEqual(0, FSymbols.FunctionIndex(5));
  Assert.AreEqual(1, FSymbols.FunctionIndex(6));
  Assert.AreEqual(2, FSymbols.FunctionIndex(High(Integer)));
end;

procedure TTestQvmSymbols.PrimaDelPrimoSimboloLoScartoDovrebbeEssereNegativo;
begin
  FSymbols.Load('0 2 helper' + #10 + '0 4 last');
  // the return address -1 of the entry frame, as the profile of the original asks
  Assert.AreEqual<AnsiString>('helper+-7', FSymbols.ValueToSymbol(-1));
  Assert.AreEqual(0, FSymbols.FunctionIndex(-1));
end;

procedure TTestQvmSymbols.DovrebbeCercareUnSimboloPerNomeDistinguendoLeMaiuscole;
begin
  FSymbols.Load(SAMPLE_MAP);
  Assert.AreEqual(6, FSymbols.SymbolToValue('helper'));
  Assert.AreEqual(0, FSymbols.SymbolToValue('Helper'));
  Assert.AreEqual(0, FSymbols.SymbolToValue(''));
end;

procedure TTestQvmSymbols.DovrebbeSaltareCommentiEAccettareNomiTraVirgolette;
begin
  Assert.AreEqual(2, FSymbols.Load('// a comment' + #13#10 + '0 0 vmMain /* another' + #10 + ' one */' + #9 +
    '0' + #10 + '2' + #10 + '"two words"' + #13#10));
  Assert.AreEqual(6, FSymbols.SymbolToValue('two words'));
  Assert.AreEqual<AnsiString>('two words+1', FSymbols.ValueToSymbol(7));
end;

procedure TTestQvmSymbols.UnaRigaIncompletaDovrebbeFermareLaLetturaEdEssereSegnalata;
begin
  Assert.AreEqual(1, FSymbols.Load('0 0 vmMain' + #10 + '0 2'));
  Assert.IsTrue(FSymbols.IncompleteLine);
  Assert.AreEqual(1, FSymbols.Load('0 0 vmMain' + #10 + '0'));
  Assert.IsTrue(FSymbols.IncompleteLine);
  // a line of another segment that is cut is not noticed, as in the original
  Assert.AreEqual(1, FSymbols.Load('0 0 vmMain' + #10 + '1 2'));
  Assert.IsFalse(FSymbols.IncompleteLine);
  Assert.AreEqual(0, FSymbols.Load(''));
  Assert.IsFalse(FSymbols.IncompleteLine);
end;

procedure TTestQvmSymbols.CaricareDiNuovoDovrebbeDimenticareISimboliDiPrima;
begin
  FSymbols.Load(SAMPLE_MAP);
  FSymbols.AddCount(1, 10);
  Assert.AreEqual(1, FSymbols.Load('0 3 other'));
  Assert.AreEqual(0, FSymbols.SymbolToValue('helper'));
  Assert.AreEqual(11, FSymbols.SymbolToValue('other'));
  Assert.AreEqual<Int64>(0, FSymbols.TakeProfile.Total);
end;

procedure TTestQvmSymbols.IlProfiloDovrebbeOrdinareDalMenoAlPiuEseguitoEAzzerare;
var
  LProfile: TQvmProfile;
begin
  FSymbols.Load(SAMPLE_MAP);
  FSymbols.AddCount(0, 250);
  FSymbols.AddCount(1, 50);
  FSymbols.AddCount(2, 700);
  FSymbols.AddCount(1, 0);
  LProfile := FSymbols.TakeProfile;
  Assert.AreEqual<Int64>(1000, LProfile.Total);
  Assert.AreEqual<Integer>(3, Length(LProfile.Entries));
  Assert.AreEqual<AnsiString>('helper', LProfile.Entries[0].Name);
  Assert.AreEqual<Int64>(50, LProfile.Entries[0].Count);
  Assert.AreEqual(5, LProfile.Entries[0].Percent);
  Assert.AreEqual<AnsiString>('vmMain', LProfile.Entries[1].Name);
  Assert.AreEqual(25, LProfile.Entries[1].Percent);
  Assert.AreEqual<AnsiString>('last', LProfile.Entries[2].Name);
  Assert.AreEqual<Int64>(700, LProfile.Entries[2].Count);
  Assert.AreEqual(70, LProfile.Entries[2].Percent);
  // the counts are taken: the next profile starts from nothing
  LProfile := FSymbols.TakeProfile;
  Assert.AreEqual<Int64>(0, LProfile.Total);
  Assert.AreEqual<Int64>(0, LProfile.Entries[2].Count);
  // a percentage is cut, not rounded: 2 of 3 is 66
  FSymbols.AddCount(0, 2);
  FSymbols.AddCount(2, 1);
  LProfile := FSymbols.TakeProfile;
  Assert.AreEqual(0, LProfile.Entries[0].Percent);
  Assert.AreEqual(33, LProfile.Entries[1].Percent);
  Assert.AreEqual(66, LProfile.Entries[2].Percent);
end;

procedure TTestQvmSymbols.IlProfiloSenzaIstruzioniDovrebbeAvereTutteLePercentualiAZero;
var
  LProfile: TQvmProfile;
begin
  FSymbols.Load(SAMPLE_MAP);
  LProfile := FSymbols.TakeProfile;
  Assert.AreEqual<Integer>(3, Length(LProfile.Entries));
  // equal counts keep the order of the file
  Assert.AreEqual<AnsiString>('vmMain', LProfile.Entries[0].Name);
  Assert.AreEqual<AnsiString>('helper', LProfile.Entries[1].Name);
  Assert.AreEqual<AnsiString>('last', LProfile.Entries[2].Name);
  Assert.AreEqual(0, LProfile.Entries[0].Percent);
  Assert.AreEqual(0, LProfile.Entries[2].Percent);
end;

procedure TTestQvmSymbols.IContiSuUnIndiceCheNonEsisteDovrebberoEssereIgnorati;
begin
  FSymbols.Load(SAMPLE_MAP);
  FSymbols.AddCount(-1, 100);
  FSymbols.AddCount(3, 100);
  Assert.AreEqual<Int64>(0, FSymbols.TakeProfile.Total);
end;

{ TTestQvmFloatMath }

function Bits(AValue: Single): Integer;
begin
  Result := PInteger(@AValue)^;
end;

procedure TTestQvmFloatMath.DovrebbeRiconoscereInfinitiENaN;
begin
  Assert.IsTrue(TQvmFloatMath.IsSpecial($7F800000));
  Assert.IsTrue(TQvmFloatMath.IsSpecial(Integer($FF800000)));
  Assert.IsTrue(TQvmFloatMath.IsSpecial($7FC00000));
  Assert.IsTrue(TQvmFloatMath.IsSpecial($7F800001));
  Assert.IsFalse(TQvmFloatMath.IsSpecial($7F7FFFFF));
  Assert.IsFalse(TQvmFloatMath.IsSpecial(0));
  Assert.IsFalse(TQvmFloatMath.IsNaN($7F800000));
  Assert.IsFalse(TQvmFloatMath.IsNaN(Integer($FF800000)));
  Assert.IsTrue(TQvmFloatMath.IsNaN($7F800001));
  Assert.IsTrue(TQvmFloatMath.IsNaN(Integer($FFC00000)));
  Assert.IsFalse(TQvmFloatMath.IsNaN(Bits(1)));
end;

procedure TTestQvmFloatMath.UnNaNNonDovrebbeEssereUgualeNeMinoreDiNulla;
const
  NAN_BITS: array[0..3] of Integer = ($7FC00000, Integer($FFC00000), $7F800001, Integer($FFA12345));
var
  LNaN, LOther: Integer;
begin
  for LNaN in NAN_BITS do
    for LOther in [0, 1] do
    begin
      Assert.IsFalse(TQvmFloatMath.Equal(LNaN, Bits(LOther)));
      Assert.IsFalse(TQvmFloatMath.Equal(Bits(LOther), LNaN));
      Assert.IsFalse(TQvmFloatMath.Less(LNaN, Bits(LOther)));
      Assert.IsFalse(TQvmFloatMath.Less(Bits(LOther), LNaN));
      Assert.IsFalse(TQvmFloatMath.LessOrEqual(LNaN, Bits(LOther)));
      Assert.IsFalse(TQvmFloatMath.LessOrEqual(Bits(LOther), LNaN));
      Assert.IsFalse(TQvmFloatMath.Equal(LNaN, LNaN));
      Assert.IsFalse(TQvmFloatMath.LessOrEqual(LNaN, LNaN));
    end;
end;

procedure TTestQvmFloatMath.LoZeroNegativoDovrebbeEssereUgualeAlloZero;
begin
  Assert.IsTrue(TQvmFloatMath.Equal(0, Integer($80000000)));
  Assert.IsTrue(TQvmFloatMath.Equal(Integer($80000000), 0));
  Assert.IsFalse(TQvmFloatMath.Less(Integer($80000000), 0));
  Assert.IsFalse(TQvmFloatMath.Less(0, Integer($80000000)));
  Assert.IsTrue(TQvmFloatMath.LessOrEqual(0, Integer($80000000)));
  Assert.IsTrue(TQvmFloatMath.LessOrEqual(Integer($80000000), 0));
end;

procedure TTestQvmFloatMath.IlConfrontoDovrebbeSeguireLOrdineDeiNumeri;
const
  // in increasing order
  ORDERED: array[0..10] of Cardinal = ($FF800000, $FF7FFFFF, $BF800000, $80800000, $80000001, $00000000,
    $00000001, $00800000, $3F800000, $7F7FFFFF, $7F800000);
var
  LFirst, LSecond: Integer;
begin
  for LFirst := 0 to High(ORDERED) do
    for LSecond := 0 to High(ORDERED) do
    begin
      Assert.AreEqual(LFirst = LSecond, TQvmFloatMath.Equal(Integer(ORDERED[LFirst]), Integer(ORDERED[LSecond])));
      Assert.AreEqual(LFirst < LSecond, TQvmFloatMath.Less(Integer(ORDERED[LFirst]), Integer(ORDERED[LSecond])));
      Assert.AreEqual(LFirst <= LSecond,
        TQvmFloatMath.LessOrEqual(Integer(ORDERED[LFirst]), Integer(ORDERED[LSecond])));
    end;
end;

procedure TTestQvmFloatMath.LaConversioneAInteroDovrebbeTroncareComeCvttss2si(ABits, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TQvmFloatMath.ToInteger(ABits));
  // the other sign gives the other sign, but the "indefinite" is the same for both
  if AExpected <> Low(Integer) then
    Assert.AreEqual(-AExpected, TQvmFloatMath.ToInteger(ABits xor Integer($80000000)))
  else
    Assert.AreEqual(Low(Integer), TQvmFloatMath.ToInteger(ABits xor Integer($80000000)));
end;

procedure TTestQvmFloatMath.UnOperandoNaNDovrebbeEssereIlRisultatoResoQuieto;
const
  OPS: array[0..3] of Integer = (OP_ADDF, OP_SUBF, OP_MULF, OP_DIVF);
var
  LOpcode: Integer;
begin
  for LOpcode in OPS do
  begin
    // the first operand wins
    Assert.AreEqual(Integer($7FC00001), TQvmFloatMath.Special(LOpcode, $7F800001, Integer($FFC12345)));
    Assert.AreEqual(Integer($FFC12345), TQvmFloatMath.Special(LOpcode, Integer($FFC12345), $7F800001));
    Assert.AreEqual(Integer($7FE00000), TQvmFloatMath.Special(LOpcode, $7FA00000, Bits(1)));
    Assert.AreEqual(Integer($7FE00000), TQvmFloatMath.Special(LOpcode, Bits(1), $7FA00000));
    Assert.AreEqual(Integer($FFC00000), TQvmFloatMath.Special(LOpcode, $7F800000, Integer($FFC00000)));
  end;
end;

procedure TTestQvmFloatMath.GliInfinitiDovrebberoSeguireLeRegoleIeee;
const
  PLUS = Integer($7F800000);
  MINUS = Integer($FF800000);
  // the NaN x86 makes out of an invalid operation
  INDEFINITE = Integer($FFC00000);
var
  LMask: TArithmeticExceptionMask;
begin
  // the interpreter runs with the exceptions masked
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    Assert.AreEqual(PLUS, TQvmFloatMath.Special(OP_ADDF, PLUS, Bits(1)));
    Assert.AreEqual(PLUS, TQvmFloatMath.Special(OP_ADDF, Bits(-5), PLUS));
    Assert.AreEqual(INDEFINITE, TQvmFloatMath.Special(OP_ADDF, PLUS, MINUS));
    Assert.AreEqual(MINUS, TQvmFloatMath.Special(OP_SUBF, Bits(1), PLUS));
    Assert.AreEqual(INDEFINITE, TQvmFloatMath.Special(OP_SUBF, PLUS, PLUS));
    Assert.AreEqual(MINUS, TQvmFloatMath.Special(OP_MULF, PLUS, Bits(-2)));
    Assert.AreEqual(INDEFINITE, TQvmFloatMath.Special(OP_MULF, PLUS, 0));
    Assert.AreEqual(0, TQvmFloatMath.Special(OP_DIVF, Bits(3), PLUS));
    Assert.AreEqual(Integer($80000000), TQvmFloatMath.Special(OP_DIVF, Bits(3), MINUS));
    Assert.AreEqual(INDEFINITE, TQvmFloatMath.Special(OP_DIVF, PLUS, MINUS));
    Assert.AreEqual(PLUS, TQvmFloatMath.Special(OP_DIVF, PLUS, Bits(2)));
  finally
    SetExceptionMask(LMask);
  end;
end;

end.
