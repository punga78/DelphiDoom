{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the numbers and booleans of the console                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Numbers;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleNumbers = class(TObject)
  public
    [TestCase('decimale', '12,12')]
    [TestCase('negativo', '-5,-5')]
    [TestCase('esadecimale 0x', '0x10,16')]
    [TestCase('esadecimale negativo', '-0x10,-16')]
    [TestCase('dollaro', '$ff,255')]
    [TestCase('cancelletto', '#12,12')]
    [TestCase('cancelletto negativo', '#-12,-12')]
    [TestCase('non numero', 'abc,0')]
    [TestCase('0x senza cifre', '0x,0')]
    [TestCase('cifre sbagliate', '0xZZ,0')]
    [TestCase('decimale con virgola', '1.5,0')]
    [TestCase('troppo grande', '99999999999,0')]
    [TestCase('massimo', '2147483647,2147483647')]
    procedure TestParseInteger(const AText: string; AExpected: Integer);
    [Test]
    procedure TestParseIntegerOfEmptyTextIsZero;
    [TestCase('true', 'TRUE,True')]
    [TestCase('on', 'on,True')]
    [TestCase('yes', 'Yes,True')]
    [TestCase('uno', '1,True')]
    [TestCase('false', 'false,False')]
    [TestCase('off', 'OFF,False')]
    [TestCase('no', 'no,False')]
    [TestCase('zero', '0,False')]
    procedure TestEvaluateBoolean(const AText: string; AExpected: Boolean);
    [Test]
    procedure TestEvaluateBooleanKeepsTheDefaultForOtherTexts;
  end;

implementation

uses
  DelphiDoom.Console.Numbers;

{ TTestConsoleNumbers }

procedure TTestConsoleNumbers.TestParseInteger(const AText: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TConsoleNumbers.ParseInteger(AText),
    'dovrebbe leggere ' + AText + ' come il vecchio atoi');
end;

procedure TTestConsoleNumbers.TestParseIntegerOfEmptyTextIsZero;
begin
  Assert.AreEqual(0, TConsoleNumbers.ParseInteger(''), 'dovrebbe dare 0');
end;

procedure TTestConsoleNumbers.TestEvaluateBoolean(const AText: string; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TConsoleNumbers.EvaluateBoolean(AText, not AExpected),
    'dovrebbe riconoscere ' + AText);
end;

procedure TTestConsoleNumbers.TestEvaluateBooleanKeepsTheDefaultForOtherTexts;
begin
  Assert.IsTrue(TConsoleNumbers.EvaluateBoolean('maybe', True), 'dovrebbe dare il valore di partenza');
  Assert.IsFalse(TConsoleNumbers.EvaluateBoolean('2', False), 'dovrebbe dare il valore di partenza');
  Assert.IsTrue(TConsoleNumbers.EvaluateBoolean('', True), 'dovrebbe dare il valore di partenza');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleNumbers);

end.
