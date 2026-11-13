{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the sum that saturates     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.Saturation;

interface

uses
  DUnitX.TestFramework, DelphiDoom.AudioMix.Saturation;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixSaturation = class
  public
    [TestCase('dentro', '100,100')]
    [TestCase('zero', '0,0')]
    [TestCase('limite alto', '32767,32767')]
    [TestCase('limite basso', '-32768,-32768')]
    [TestCase('sopra', '32768,32767')]
    [TestCase('molto sopra', '1000000,32767')]
    [TestCase('sotto', '-32769,-32768')]
    [TestCase('molto sotto', '-1000000,-32768')]
    procedure ClampTaglia(AValue, AExpected: Integer);
    [Test]
    procedure AddSaturatedSommaESatura;
    [Test]
    procedure AddSaturatedNonToccaOltreIlConteggio;
  end;

implementation

procedure TTestAudioMixSaturation.ClampTaglia(AValue, AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, TPcmSaturation.Clamp(AValue));
end;

procedure TTestAudioMixSaturation.AddSaturatedSommaESatura;
var
  LDestination: array[0..4] of SmallInt;
  LSource: array[0..4] of SmallInt;
begin
  LDestination[0] := 10;
  LDestination[1] := 30000;
  LDestination[2] := -30000;
  LDestination[3] := -32768;
  LDestination[4] := 5;
  LSource[0] := -3;
  LSource[1] := 30000;
  LSource[2] := -30000;
  LSource[3] := -1;
  LSource[4] := 32767;
  TPcmSaturation.AddSaturated(@LDestination[0], @LSource[0], 5);
  Assert.AreEqual<Integer>(7, LDestination[0]);
  Assert.AreEqual<Integer>(32767, LDestination[1]);
  Assert.AreEqual<Integer>(-32768, LDestination[2]);
  Assert.AreEqual<Integer>(-32768, LDestination[3]);
  Assert.AreEqual<Integer>(32767, LDestination[4]);
end;

procedure TTestAudioMixSaturation.AddSaturatedNonToccaOltreIlConteggio;
var
  LDestination: array[0..2] of SmallInt;
  LSource: array[0..2] of SmallInt;
begin
  LDestination[0] := 1;
  LDestination[1] := 2;
  LDestination[2] := 3;
  LSource[0] := 10;
  LSource[1] := 10;
  LSource[2] := 10;
  TPcmSaturation.AddSaturated(@LDestination[0], @LSource[0], 2);
  Assert.AreEqual<Integer>(11, LDestination[0]);
  Assert.AreEqual<Integer>(12, LDestination[1]);
  Assert.AreEqual<Integer>(3, LDestination[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAudioMixSaturation);

end.
