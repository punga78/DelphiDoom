{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cheat scrambler                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CheatScrambler;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('console')]
  TTestCheatScrambler = class(TObject)
  public
    [TestCase('i', '105,178')]
    [TestCase('d', '100,38')]
    [TestCase('q', '113,170')]
    [TestCase('zero', '0,0')]
    [TestCase('tutti i bit', '255,255')]
    procedure TestKnownLetters(AInput, AExpected: Integer);
    [Test]
    procedure TestScrambleTwiceGivesTheOriginalByte;
    [Test]
    procedure TestScrambleIsABijection;
  end;

implementation

uses
  DelphiDoom.Console.CheatScrambler;

{ TTestCheatScrambler }

procedure TTestCheatScrambler.TestKnownLetters(AInput, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(TCheatScrambler.Scramble(Byte(AInput))),
    'dovrebbe mescolare i bit come il vecchio SCRAMBLE');
end;

procedure TTestCheatScrambler.TestScrambleTwiceGivesTheOriginalByte;
var
  LValue: Integer;
begin
  for LValue := 0 to 255 do
    Assert.AreEqual(LValue, Integer(TCheatScrambler.Scramble(TCheatScrambler.Scramble(Byte(LValue)))),
      'dovrebbe essere la sua inversa');
end;

procedure TTestCheatScrambler.TestScrambleIsABijection;
var
  LSeen: array[0..255] of Boolean;
  LValue: Integer;
begin
  FillChar(LSeen, SizeOf(LSeen), 0);
  for LValue := 0 to 255 do
    LSeen[TCheatScrambler.Scramble(Byte(LValue))] := True;
  for LValue := 0 to 255 do
    Assert.IsTrue(LSeen[LValue], 'dovrebbe dare ogni byte una volta');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCheatScrambler);

end.
