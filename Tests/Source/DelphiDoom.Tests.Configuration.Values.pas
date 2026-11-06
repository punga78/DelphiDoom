{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the configuration library - the values                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Configuration.Values;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('configuration')]
  TTestConfigurationValues = class(TObject)
  public
    [TestCase('decimal', '640,640')]
    [TestCase('negative', '-12,-12')]
    [TestCase('zero', '0,0')]
    [TestCase('dollar hex', '$1F,31')]
    [TestCase('0x hex', '0x10,16')]
    [TestCase('negative 0x hex', '-0x10,-16')]
    [TestCase('hash', '#25,25')]
    [TestCase('nothing', ',0')]
    [TestCase('garbage', '12abc,0')]
    procedure TestNumbers(const AText: string; AExpected: Integer);
    [Test]
    procedure TestACharacterInQuotesIsItsCode;
    [Test]
    procedure TestADigitInQuotesIsTheDigit;
    [Test]
    procedure TestQuotesMustBeTheSame;
    [Test]
    procedure TestALoneCharacterIsItsCode;
    [Test]
    procedure TestALoneDigitIsTheDigit;
    [Test]
    procedure TestBooleans;
    [Test]
    procedure TestFormatting;
  end;

implementation

uses
  DelphiDoom.Configuration.Values;

{ TTestConfigurationValues }

procedure TTestConfigurationValues.TestNumbers(const AText: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TConfigurationValues.ParseInteger(AText));
end;

procedure TTestConfigurationValues.TestACharacterInQuotesIsItsCode;
begin
  Assert.AreEqual(Ord('q'), TConfigurationValues.ParseInteger('''q'''));
  Assert.AreEqual(Ord('Z'), TConfigurationValues.ParseInteger('"Z"'));
  Assert.AreEqual(Ord(' '), TConfigurationValues.ParseInteger(''' '''));
end;

procedure TTestConfigurationValues.TestADigitInQuotesIsTheDigit;
begin
  Assert.AreEqual(7, TConfigurationValues.ParseInteger('''7'''));
  Assert.AreEqual(0, TConfigurationValues.ParseInteger('"0"'));
end;

procedure TTestConfigurationValues.TestQuotesMustBeTheSame;
begin
  // a mix of quotes is not a character: it is not a number either
  Assert.AreEqual(0, TConfigurationValues.ParseInteger('''q"'));
end;

procedure TTestConfigurationValues.TestALoneCharacterIsItsCode;
begin
  Assert.AreEqual(Ord('a'), TConfigurationValues.ParseInteger('a'));
  Assert.AreEqual(Ord('-'), TConfigurationValues.ParseInteger('-'));
end;

procedure TTestConfigurationValues.TestALoneDigitIsTheDigit;
begin
  Assert.AreEqual(5, TConfigurationValues.ParseInteger('5'));
end;

procedure TTestConfigurationValues.TestBooleans;
begin
  Assert.IsTrue(TConfigurationValues.ParseBoolean('1'));
  Assert.IsTrue(TConfigurationValues.ParseBoolean('7'));
  Assert.IsTrue(TConfigurationValues.ParseBoolean('-1'));
  Assert.IsFalse(TConfigurationValues.ParseBoolean('0'));
  Assert.IsFalse(TConfigurationValues.ParseBoolean(''));
  Assert.IsFalse(TConfigurationValues.ParseBoolean('yes'));
end;

procedure TTestConfigurationValues.TestFormatting;
begin
  Assert.AreEqual('640', TConfigurationValues.FormatInteger(640));
  Assert.AreEqual('-3', TConfigurationValues.FormatInteger(-3));
  Assert.AreEqual('1', TConfigurationValues.FormatBoolean(True));
  Assert.AreEqual('0', TConfigurationValues.FormatBoolean(False));
end;

end.
