{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the music on a MIDI output           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicMidiSynth;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Midi.Output.Intf, DelphiDoom.War.Music.Types,
  DelphiDoom.War.Music.Intf, DelphiDoom.War.Music.MidiSynth;

type
  /// <summary>A MIDI output that writes the messages down as hex text, like "90 3C 64"; no device is ever opened</summary>
  TFakeMidiOutput = class(TInterfacedObject, IMidiShortOutput)
  strict private
    FMessages: TStringList;
    FOpen: Boolean;
  public
    OpenResult: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Open: Boolean;
    procedure Close;
    function IsOpen: Boolean;
    procedure Send(AStatus, AData1, AData2: Byte);
    property Messages: TStringList read FMessages;
  end;

  /// <summary>The events of a song become MIDI messages; the fade is done on the volume controller</summary>
  [TestFixture]
  [Category('war')]
  TTestWarMusicMidiSynth = class(TObject)
  strict private
    FOutputObject: TFakeMidiOutput;
    FOutput: IMidiShortOutput;
    FSynthObject: TWarMidiMusicSynth;
    FSynth: IWarMusicSynth;
    function Last: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaUscitaNil;
    [Test]
    procedure DovrebbeMandareIlCambioDiProgramma;
    [Test]
    procedure DovrebbeMandareUnaNotaConLaVelocitaDa0A127;
    [Test]
    procedure DovrebbeSaltareUnaNotaConVelocitaZero;
    [Test]
    procedure DovrebbeLimitareLaVelocitaA127;
    [Test]
    procedure DovrebbeMandareIlRilascioDiUnaNota;
    [Test]
    procedure DovrebbeMandareIlPitchBendInDueByteDa7Bit;
    [Test]
    procedure DovrebbeMandareUnControllerCheNonELVolume;
    [Test]
    procedure DovrebbeMascherareICanaliEIByteDiDati;
    [Test]
    procedure DovrebbeSpegnereTuttiICanaliSuAllNotesOff;
    [Test]
    procedure DovrebbeNonAggiungereNullaAiCampioni;
    [Test]
    procedure DovrebbeScalareIlVolumeDelBranoConIlGuadagno;
    [Test]
    procedure DovrebbeRimandareIlVolumeDiOgniCanaleQuandoCambiaIlGuadagno;
    [Test]
    procedure DovrebbeNonRimandareIlVolumeSeIlGuadagnoNonCambia;
    [Test]
    procedure DovrebbeRimettereICanaliAlloStandardPerUnNuovoBrano;
    [Test]
    procedure DovrebbeSuonareSottoIlPlayerConLaDissolvenzaSulVolume;
  end;

implementation

uses
  DelphiDoom.War.Music.Player, DelphiDoom.Tests.War.MusicFakes;

{ TFakeMidiOutput }

constructor TFakeMidiOutput.Create;
begin
  inherited Create;
  FMessages := TStringList.Create;
  OpenResult := True;
end;

destructor TFakeMidiOutput.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

function TFakeMidiOutput.Open: Boolean;
begin
  FOpen := OpenResult;
  Result := FOpen;
end;

procedure TFakeMidiOutput.Close;
begin
  FOpen := False;
end;

function TFakeMidiOutput.IsOpen: Boolean;
begin
  Result := FOpen;
end;

procedure TFakeMidiOutput.Send(AStatus, AData1, AData2: Byte);
begin
  FMessages.Add(Format('%.2X %.2X %.2X', [AStatus, AData1, AData2]));
end;

{ TTestWarMusicMidiSynth }

procedure TTestWarMusicMidiSynth.Setup;
begin
  FOutputObject := TFakeMidiOutput.Create;
  FOutput := FOutputObject;
  FSynthObject := TWarMidiMusicSynth.Create(FOutput);
  FSynth := FSynthObject;
end;

procedure TTestWarMusicMidiSynth.TearDown;
begin
  FSynth := nil;
  FSynthObject := nil;
  FOutput := nil;
  FOutputObject := nil;
end;

function TTestWarMusicMidiSynth.Last: string;
begin
  Result := FOutputObject.Messages[FOutputObject.Messages.Count - 1];
end;

procedure TTestWarMusicMidiSynth.DovrebbeRifiutareUnaUscitaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarMidiMusicSynth.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestWarMusicMidiSynth.DovrebbeMandareIlCambioDiProgramma;
begin
  FSynth.ProgramChange(2, 73, False);
  Assert.AreEqual('C2 49 00', Last);
  FSynth.ProgramChange(9, 0, True);
  Assert.AreEqual('C9 00 00', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeMandareUnaNotaConLaVelocitaDa0A127;
begin
  FSynth.NoteOn(1, 60, 1.0);
  Assert.AreEqual('91 3C 7F', Last);
  FSynth.NoteOn(1, 60, 100 / 127);
  Assert.AreEqual('91 3C 64', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeSaltareUnaNotaConVelocitaZero;
begin
  // velocity 0 is a note off for a device: a note that is silent is not sent
  FSynth.NoteOn(1, 60, 0);
  Assert.AreEqual(0, FOutputObject.Messages.Count);
end;

procedure TTestWarMusicMidiSynth.DovrebbeLimitareLaVelocitaA127;
begin
  FSynth.NoteOn(0, 60, 3.5);
  Assert.AreEqual('90 3C 7F', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeMandareIlRilascioDiUnaNota;
begin
  FSynth.NoteOff(4, 72);
  Assert.AreEqual('84 48 40', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeMandareIlPitchBendInDueByteDa7Bit;
begin
  FSynth.PitchBend(3, 8192);
  Assert.AreEqual('E3 00 40', Last);
  FSynth.PitchBend(3, $3FFF);
  Assert.AreEqual('E3 7F 7F', Last);
  FSynth.PitchBend(3, 1);
  Assert.AreEqual('E3 01 00', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeMandareUnControllerCheNonELVolume;
begin
  FSynth.ControlChange(5, 10, 33);
  Assert.AreEqual('B5 0A 21', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeMascherareICanaliEIByteDiDati;
begin
  FSynth.NoteOff(17, 200);
  Assert.AreEqual('81 48 40', Last);
  FSynth.ControlChange(0, 64, 500);
  Assert.AreEqual('B0 40 7F', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeSpegnereTuttiICanaliSuAllNotesOff;
begin
  FSynth.AllNotesOff;
  Assert.AreEqual(32, FOutputObject.Messages.Count);
  Assert.AreEqual('B0 7B 00', FOutputObject.Messages[0]);
  Assert.AreEqual('B0 78 00', FOutputObject.Messages[1]);
  Assert.AreEqual('BF 7B 00', FOutputObject.Messages[30]);
  Assert.AreEqual('BF 78 00', FOutputObject.Messages[31]);
end;

procedure TTestWarMusicMidiSynth.DovrebbeNonAggiungereNullaAiCampioni;
var
  LSamples: array[0..3] of SmallInt;
begin
  LSamples[0] := 5;
  LSamples[1] := -5;
  LSamples[2] := 100;
  LSamples[3] := 0;
  FSynth.Render(@LSamples[0], 4);
  Assert.AreEqual<Integer>(5, LSamples[0]);
  Assert.AreEqual<Integer>(-5, LSamples[1]);
  Assert.AreEqual<Integer>(100, LSamples[2]);
  Assert.AreEqual(0, FOutputObject.Messages.Count);
end;

procedure TTestWarMusicMidiSynth.DovrebbeScalareIlVolumeDelBranoConIlGuadagno;
begin
  FSynthObject.SetGain(WAR_MUSIC_GAIN_FULL div 2);
  FOutputObject.Messages.Clear;
  FSynth.ControlChange(2, 7, 80);
  Assert.AreEqual('B2 07 28', Last, 'The volume that the song gives (80) at half gain is 40');
end;

procedure TTestWarMusicMidiSynth.DovrebbeRimandareIlVolumeDiOgniCanaleQuandoCambiaIlGuadagno;
begin
  FSynth.ControlChange(1, 7, 80);
  FOutputObject.Messages.Clear;
  FSynthObject.SetGain(WAR_MUSIC_GAIN_FULL div 2);
  Assert.AreEqual(16, FOutputObject.Messages.Count);
  Assert.AreEqual('B0 07 32', FOutputObject.Messages[0], 'The default of 100 at half gain');
  Assert.AreEqual('B1 07 28', FOutputObject.Messages[1], 'The 80 of the song');
  FSynthObject.SetGain(0);
  Assert.AreEqual('BF 07 00', Last);
end;

procedure TTestWarMusicMidiSynth.DovrebbeNonRimandareIlVolumeSeIlGuadagnoNonCambia;
begin
  FSynthObject.SetGain(WAR_MUSIC_GAIN_FULL);
  Assert.AreEqual(0, FOutputObject.Messages.Count);
  FSynthObject.SetGain(WAR_MUSIC_GAIN_FULL * 2);
  Assert.AreEqual(0, FOutputObject.Messages.Count, 'A gain over the full one is the full one');
end;

procedure TTestWarMusicMidiSynth.DovrebbeRimettereICanaliAlloStandardPerUnNuovoBrano;
begin
  FSynth.ControlChange(0, 7, 20);
  FOutputObject.Messages.Clear;
  FSynthObject.ResetChannels;
  Assert.AreEqual(48, FOutputObject.Messages.Count);
  Assert.AreEqual('B0 79 00', FOutputObject.Messages[0]);
  Assert.AreEqual('E0 00 40', FOutputObject.Messages[1]);
  Assert.AreEqual('B0 07 64', FOutputObject.Messages[2], 'The volume of a channel is the General MIDI default');
end;

procedure TTestWarMusicMidiSynth.DovrebbeSuonareSottoIlPlayerConLaDissolvenzaSulVolume;
var
  LTimeline: IWarMusicTimeline;
  LPlayer: IWarMusicPlayer;
  LEvent, LRelease: TWarMusicEvent;
  LBuffer: array[0..1023] of SmallInt;
begin
  LEvent := Default(TWarMusicEvent);
  LEvent.Kind := wmkNoteOn;
  LEvent.Channel := 0;
  LEvent.Key := 60;
  LEvent.Value := 127;
  LRelease := LEvent;
  LRelease.Kind := wmkNoteOff;
  // far away: the song is not over, so the player does not put the notes off at the end of the block
  LRelease.TimeMs := 100000;
  LTimeline := TFakeMusicTimeline.Create([LEvent, LRelease]);
  LPlayer := TWarMusicPlayer.Create(FSynth, LTimeline, 44100);
  Assert.IsTrue(LPlayer.Play([1], False, 100));
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  // the channels are reset, then the gain is told (0: a fade in starts from silence), then the note starts
  Assert.AreEqual('90 3C 7F', Last, 'The note is the last message of the first block');
  Assert.IsTrue((FOutputObject.Messages.IndexOf('B0 07 00') >= 0), 'The volume of channel 0 is 0 at the start of the fade');
  Assert.AreEqual<Integer>(0, LBuffer[100], 'The device makes no samples');
end;

end.
