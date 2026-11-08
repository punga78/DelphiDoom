{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - TMidiVolume and TMidiEventFeeder             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.Volume;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.Volume;

type
  [TestFixture]
  [Category('midi')]
  TTestMidiVolume = class
  public
    [Test]
    procedure DovrebbeDareLaPercentualeDiOgniLivelloDelMenu;
    [Test]
    procedure DovrebbeUsareIlLivelloPiuVicinoSeEFuoriDalMenu;
    [Test]
    procedure DovrebbeDareIlValoreDelControlloDiUnaPercentuale;
    [Test]
    procedure DovrebbeComporreIlMessaggioDelControlloDelVolume;
    [Test]
    procedure DovrebbeRiscrivereSoloIlVolumeDeiCambiDiControllo;
    [Test]
    procedure DovrebbePartireSempreDagliEventiOriginali;
  end;

implementation

function Make(AEvent: Cardinal): TMidiStreamEvent;
begin
  Result.Time := 0;
  Result.StreamId := 0;
  Result.Event := AEvent;
end;

procedure TTestMidiVolume.DovrebbeDareLaPercentualeDiOgniLivelloDelMenu;
const
  EXPECTED: array[0..15] of Integer = (0, 7, 13, 20, 27, 33, 40, 47, 53, 60, 67, 73, 80, 87, 93, 100);
var
  LLevel: Integer;
begin
  for LLevel := 0 to 15 do
    Assert.AreEqual(EXPECTED[LLevel], TMidiVolume.PercentOfLevel(LLevel));
end;

procedure TTestMidiVolume.DovrebbeUsareIlLivelloPiuVicinoSeEFuoriDalMenu;
begin
  Assert.AreEqual(0, TMidiVolume.PercentOfLevel(-5));
  Assert.AreEqual(100, TMidiVolume.PercentOfLevel(99));
end;

procedure TTestMidiVolume.DovrebbeDareIlValoreDelControlloDiUnaPercentuale;
begin
  Assert.AreEqual(0, TMidiVolume.ControllerValueOfPercent(0));
  Assert.AreEqual(63, TMidiVolume.ControllerValueOfPercent(50));
  Assert.AreEqual(127, TMidiVolume.ControllerValueOfPercent(100));
end;

procedure TTestMidiVolume.DovrebbeComporreIlMessaggioDelControlloDelVolume;
begin
  Assert.AreEqual(Integer($007F07B3), Integer(TMidiVolume.ControlChangeMessage(3, 127)));
  Assert.AreEqual(Integer($000007B0), Integer(TMidiVolume.ControlChangeMessage(0, 0)));
end;

procedure TTestMidiVolume.DovrebbeRiscrivereSoloIlVolumeDeiCambiDiControllo;
var
  LEvents: array[0..2] of TMidiStreamEvent;
  LOriginals: array[0..2] of TMidiStreamEvent;
begin
  // a note, the volume of channel 2 and the pan of channel 2
  LEvents[0] := Make($00643C90);
  LEvents[1] := Make($406407B2);
  LEvents[2] := Make($00400AB2);
  LOriginals[0] := LEvents[0];
  LOriginals[1] := LEvents[1];
  LOriginals[2] := LEvents[2];
  TMidiVolume.ApplyToEvents(@LEvents[0], @LOriginals[0], 3, 40);
  Assert.AreEqual(Integer($00643C90), Integer(LEvents[0].Event));
  // the flag of the callback stays: only the low seven bits of the third byte are replaced
  Assert.AreEqual(Integer($402807B2), Integer(LEvents[1].Event));
  Assert.AreEqual(Integer($00400AB2), Integer(LEvents[2].Event));
end;

procedure TTestMidiVolume.DovrebbePartireSempreDagliEventiOriginali;
var
  LEvents: array[0..0] of TMidiStreamEvent;
  LOriginals: array[0..0] of TMidiStreamEvent;
begin
  LOriginals[0] := Make($006407B0);
  LEvents[0] := LOriginals[0];
  TMidiVolume.ApplyToEvents(@LEvents[0], @LOriginals[0], 1, 7);
  TMidiVolume.ApplyToEvents(@LEvents[0], @LOriginals[0], 1, 100);
  Assert.AreEqual(Integer($006407B0), Integer(LEvents[0].Event));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiVolume);

end.
