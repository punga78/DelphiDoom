{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of Pos1 of d_delphi (the prefix test)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Common.Pos1;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('common')]
  TTestCommonPos1 = class(TObject)
  public
    [Test]
    procedure TestEqualStringsAreAPrefixOfEachOther;
    [Test]
    procedure TestRealPrefix;
    [Test]
    procedure TestEmptyPrefixIsAlwaysTrue;
    [Test]
    procedure TestPrefixLongerThanTheStringIsFalse;
    [Test]
    procedure TestRegressionSoftWindowYposIsNotSoftWindowXpos;
    [Test]
    [TestCase('car1', 'Xbcdefgh,abcdefgh')]
    [TestCase('car2', 'aXcdefgh,abcdefgh')]
    [TestCase('car3', 'abXdefgh,abcdefgh')]
    [TestCase('car4', 'abcXefgh,abcdefgh')]
    [TestCase('car5', 'abcdXfgh,abcdefgh')]
    [TestCase('car6', 'abcdeXgh,abcdefgh')]
    [TestCase('car7', 'abcdefXh,abcdefgh')]
    [TestCase('car8', 'abcdefgX,abcdefgh')]
    procedure TestADifferenceInAnyCharacterIsSeen(const ASubs, AText: string);
    [Test]
    [TestCase('len1', 'a')]
    [TestCase('len2', 'ab')]
    [TestCase('len3', 'abc')]
    [TestCase('len4', 'abcd')]
    [TestCase('len5', 'abcde')]
    [TestCase('len6', 'abcdef')]
    [TestCase('len7', 'abcdefg')]
    [TestCase('len9', 'abcdefghi')]
    procedure TestEveryLengthOfPrefixMatches(const ASubs: string);
  end;

implementation

uses
  d_delphi;

{ TTestCommonPos1 }

procedure TTestCommonPos1.TestEqualStringsAreAPrefixOfEachOther;
begin
  Assert.IsTrue(Pos1('doomdef', 'doomdef'));
end;

procedure TTestCommonPos1.TestRealPrefix;
begin
  Assert.IsTrue(Pos1('soft_', 'soft_windowxpos=100'));
  Assert.IsFalse(Pos1('hard_', 'soft_windowxpos=100'));
end;

procedure TTestCommonPos1.TestEmptyPrefixIsAlwaysTrue;
begin
  Assert.IsTrue(Pos1('', 'anything'));
  Assert.IsTrue(Pos1('', ''));
end;

procedure TTestCommonPos1.TestPrefixLongerThanTheStringIsFalse;
begin
  Assert.IsFalse(Pos1('abcdef', 'abc'));
end;

procedure TTestCommonPos1.TestRegressionSoftWindowYposIsNotSoftWindowXpos;
begin
  Assert.IsFalse(Pos1('soft_windowypos=', 'soft_windowxpos=100'));
  Assert.IsTrue(Pos1('soft_windowxpos=', 'soft_windowxpos=100'));
end;

procedure TTestCommonPos1.TestADifferenceInAnyCharacterIsSeen(const ASubs, AText: string);
begin
  Assert.IsFalse(Pos1(ASubs, AText));
end;

procedure TTestCommonPos1.TestEveryLengthOfPrefixMatches(const ASubs: string);
begin
  Assert.IsTrue(Pos1(ASubs, 'abcdefghij'));
end;

end.
