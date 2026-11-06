{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - the string functions            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.Strings;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedStrings = class(TObject)
  public
    [Test]
    procedure TestTrimRimuoveCaratteriDiControllo;
    [Test]
    procedure TestSplitCharNonTagliaSeSeparatoreAssente;
    [Test]
    procedure TestSplitCharTagliaEdIspezionaLeDueParti;
    [Test]
    procedure TestFirstWordCharNonTagliaGliSpazi;
    [Test]
    procedure TestSecondWordRestituisceIlRestoSenzaSpazi;
    [Test]
    procedure TestSplitSetUsaIlPrimoSeparatoreDelSet;
    [Test]
    procedure TestParseFirstWordLeggeLeVirgolette;
    [Test]
    procedure TestRemoveQuotesToglieUnaVirgolettaPerLato;
    [Test]
    [TestCase('decimale', '123,-1,123')]
    [TestCase('negativo', '-7,-1,-7')]
    [TestCase('esadecimale0x', '0x10,-1,16')]
    [TestCase('esadecimaleMaiuscolo', '0X1F,-1,31')]
    [TestCase('esadecimaleDollaro', '$20,-1,32')]
    [TestCase('cancelletto', '#15,-1,15')]
    [TestCase('testo', 'abc,-1,-1')]
    [TestCase('misto', '12abc,-1,-1')]
    [TestCase('vuoto', ',-1,-1')]
    [TestCase('defaultZero', 'abc,0,0')]
    procedure TestToIntegerLeggeLeNotazioniDelVecchioAtoi(const AText: string; ADefault, AExpected: Integer);
    [Test]
    procedure TestToSingleAccettaLaVirgola;
    [Test]
    [TestCase('intero', '100,64,100')]
    [TestCase('metaVirgolaPunto', '0.5,64,32768')]
    [TestCase('oltreSoglia', '70000.0,64,70000')]
    [TestCase('sottoSoglia', '63.5,64,4161536')]
    [TestCase('allaSoglia', '64.0,64,4194304')]
    [TestCase('negativo', '-2.25,256,-147456')]
    procedure TestFixedOrFloat(const AText: string; ATolerance, AExpected: Integer);
  end;

implementation

uses
  DelphiDoom.Dehacked.Strings;

{ TTestDehackedStrings }

procedure TTestDehackedStrings.TestTrimRimuoveCaratteriDiControllo;
begin
  Assert.AreEqual('a b', TDehackedStrings.Trim(#9' a b '#13#10));
  Assert.AreEqual('', TDehackedStrings.Trim('   '));
  Assert.AreEqual('', TDehackedStrings.Trim(''));
end;

procedure TTestDehackedStrings.TestSplitCharNonTagliaSeSeparatoreAssente;
var
  LFirst, LSecond: string;
begin
  TDehackedStrings.SplitChar('  ABC  ', LFirst, LSecond, '=');
  Assert.AreEqual('  ABC  ', LFirst);
  Assert.AreEqual('', LSecond);
end;

procedure TTestDehackedStrings.TestSplitCharTagliaEdIspezionaLeDueParti;
var
  LFirst, LSecond: string;
begin
  TDehackedStrings.SplitChar('  HIT POINTS  =  100 = 5 ', LFirst, LSecond, '=');
  Assert.AreEqual('HIT POINTS', LFirst);
  Assert.AreEqual('100 = 5', LSecond);
end;

procedure TTestDehackedStrings.TestFirstWordCharNonTagliaGliSpazi;
begin
  Assert.AreEqual('AB ', TDehackedStrings.FirstWordChar('AB =C', '='));
  Assert.AreEqual('', TDehackedStrings.FirstWordChar(' AB')); // the splitter is the first character
  Assert.AreEqual('AB', TDehackedStrings.FirstWordChar('AB'));
end;

procedure TTestDehackedStrings.TestSecondWordRestituisceIlRestoSenzaSpazi;
begin
  Assert.AreEqual('FRAME 17)', TDehackedStrings.SecondWord('7 (FRAME 17)', '('));
  Assert.AreEqual('5', TDehackedStrings.SecondWord('NEWFRAME   5  '));
  Assert.AreEqual('', TDehackedStrings.SecondWord('NEWFRAME'));
end;

procedure TTestDehackedStrings.TestSplitSetUsaIlPrimoSeparatoreDelSet;
var
  LFirst, LSecond: string;
begin
  TDehackedStrings.SplitSet('A_EXPLODE(128, 4)', LFirst, LSecond, [' ', '(']);
  Assert.AreEqual('A_EXPLODE', LFirst);
  Assert.AreEqual('128, 4)', LSecond);
  TDehackedStrings.SplitSet('SOLID+SHOOTABLE', LFirst, LSecond, [' ', '|', ',', '+']);
  Assert.AreEqual('SOLID', LFirst);
  Assert.AreEqual('SHOOTABLE', LSecond);
end;

procedure TTestDehackedStrings.TestParseFirstWordLeggeLeVirgolette;
begin
  Assert.AreEqual('ZOMBIE MAN', TDehackedStrings.ParseFirstWord('"ZOMBIE MAN" (x)'));
  Assert.AreEqual('ZOMBIE', TDehackedStrings.ParseFirstWord('  ZOMBIE MAN'));
  Assert.AreEqual('', TDehackedStrings.ParseFirstWord('   '));
end;

procedure TTestDehackedStrings.TestRemoveQuotesToglieUnaVirgolettaPerLato;
begin
  Assert.AreEqual('ABC', TDehackedStrings.RemoveQuotes('"ABC"'));
  Assert.AreEqual('"ABC', TDehackedStrings.RemoveQuotes('""ABC"'));
  Assert.AreEqual('', TDehackedStrings.RemoveQuotes('"'));
end;

procedure TTestDehackedStrings.TestToIntegerLeggeLeNotazioniDelVecchioAtoi(const AText: string;
  ADefault, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TDehackedStrings.ToInteger(AText, ADefault));
end;

procedure TTestDehackedStrings.TestToSingleAccettaLaVirgola;
begin
  Assert.AreEqual(Single(1.5), TDehackedStrings.ToSingle('1,5', 0));
  Assert.AreEqual(Single(2.25), TDehackedStrings.ToSingle('2.25', 0));
  Assert.AreEqual(Single(7), TDehackedStrings.ToSingle('abc', 7));
end;

procedure TTestDehackedStrings.TestFixedOrFloat(const AText: string; ATolerance, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TDehackedStrings.FixedOrFloat(AText, ATolerance));
end;

end.
