{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the text helpers of the console                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Text;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleText = class(TObject)
  public
    [Test]
    procedure TestUpperCaseChangesOnlyAsciiLetters;
    [Test]
    procedure TestLowerCaseChangesOnlyAsciiLetters;
    [Test]
    procedure TestTrimRemovesControlCharactersAndSpaces;
    [Test]
    procedure TestTrimOfBlanksIsEmpty;
    [Test]
    procedure TestSplitTrimsBothParts;
    [Test]
    procedure TestSplitCutsAtTheFirstSeparatorOnly;
    [Test]
    procedure TestSplitWithoutSeparatorKeepsTheTextAsItIs;
    [Test]
    procedure TestSplitWithLeadingSeparatorGivesEmptyFirstPart;
    [Test]
    procedure TestStartsWith;
  end;

implementation

uses
  DelphiDoom.Console.Text;

{ TTestConsoleText }

procedure TTestConsoleText.TestUpperCaseChangesOnlyAsciiLetters;
begin
  Assert.AreEqual('ABC-1' + Char($E8), TConsoleText.UpperCase('aBc-1' + Char($E8)),
    'dovrebbe lasciare invariati i caratteri che non sono lettere ASCII');
end;

procedure TTestConsoleText.TestLowerCaseChangesOnlyAsciiLetters;
begin
  Assert.AreEqual('abc-1' + Char($C8), TConsoleText.LowerCase('aBC-1' + Char($C8)),
    'dovrebbe lasciare invariati i caratteri che non sono lettere ASCII');
end;

procedure TTestConsoleText.TestTrimRemovesControlCharactersAndSpaces;
begin
  Assert.AreEqual('a b', TConsoleText.Trim(#9' a b '#13#10),
    'dovrebbe togliere tutto cio'' che non e'' sopra lo spazio');
end;

procedure TTestConsoleText.TestTrimOfBlanksIsEmpty;
begin
  Assert.AreEqual('', TConsoleText.Trim('  '#9' '), 'dovrebbe dare una stringa vuota');
  Assert.AreEqual('', TConsoleText.Trim(''), 'dovrebbe dare una stringa vuota');
end;

procedure TTestConsoleText.TestSplitTrimsBothParts;
var
  LFirst: string;
  LSecond: string;
begin
  TConsoleText.Split('  one   two  ', ' ', LFirst, LSecond);
  Assert.AreEqual('', LFirst, 'dovrebbe dare la parte prima del primo separatore');
  TConsoleText.Split('one   two  three ', ' ', LFirst, LSecond);
  Assert.AreEqual('one', LFirst);
  Assert.AreEqual('two  three', LSecond, 'dovrebbe togliere gli spazi ai due lati del resto');
end;

procedure TTestConsoleText.TestSplitCutsAtTheFirstSeparatorOnly;
var
  LFirst: string;
  LSecond: string;
begin
  TConsoleText.Split('a,b,c', ',', LFirst, LSecond);
  Assert.AreEqual('a', LFirst);
  Assert.AreEqual('b,c', LSecond, 'dovrebbe tagliare solo al primo separatore');
end;

procedure TTestConsoleText.TestSplitWithoutSeparatorKeepsTheTextAsItIs;
var
  LFirst: string;
  LSecond: string;
begin
  TConsoleText.Split(#9'echo'#9, ' ', LFirst, LSecond);
  Assert.AreEqual(#9'echo'#9, LFirst, 'dovrebbe lasciare il testo com''e'' (come faceva il vecchio codice)');
  Assert.AreEqual('', LSecond);
end;

procedure TTestConsoleText.TestSplitWithLeadingSeparatorGivesEmptyFirstPart;
var
  LFirst: string;
  LSecond: string;
begin
  TConsoleText.Split(',b', ',', LFirst, LSecond);
  Assert.AreEqual('', LFirst, 'dovrebbe dare una prima parte vuota');
  Assert.AreEqual('b', LSecond);
end;

procedure TTestConsoleText.TestStartsWith;
begin
  Assert.IsTrue(TConsoleText.StartsWith('//', '// c'), 'dovrebbe riconoscere il prefisso');
  Assert.IsFalse(TConsoleText.StartsWith('//', '/'), 'dovrebbe rifiutare un testo piu'' corto');
  Assert.IsFalse(TConsoleText.StartsWith('ab', 'AB'), 'dovrebbe distinguere maiuscole e minuscole');
  Assert.IsTrue(TConsoleText.StartsWith('', 'x'), 'dovrebbe accettare un prefisso vuoto');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleText);

end.
