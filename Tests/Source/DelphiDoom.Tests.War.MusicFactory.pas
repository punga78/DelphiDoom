{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the factory of the music and of the silent synth of    }
{  Libs\War                                                                    }
{                                                                              }
{  The whole chain with no sound: a MIDI file built in memory, the real        }
{  sequencer of Libs\Midi, the player and the synth that adds nothing.         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicFactory;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('war')]
  TTestWarMusicFactory = class
  strict private
    function Song: TBytes;
  public
    [Test]
    procedure DovrebbeFarSuonareUnaCanzoneConIlSintetizzatoreMuto;
    [Test]
    procedure DovrebbeLasciareIlBufferComeEConIlSintetizzatoreMuto;
    [Test]
    procedure DovrebbeFinireLaCanzoneAncheSenzaSuono;
    [Test]
    procedure DovrebbeFarCreareLaDissolvenzaDallaFabbrica;
    [Test]
    procedure DovrebbeRifiutareUnaCanzoneCheNonSiLegge;
    [Test]
    procedure DovrebbeAccettareUnLogNulloPerLaCanzone;
    [Test]
    procedure DovrebbeNonFareNullaDalSintetizzatoreMuto;
    [Test]
    procedure DovrebbeDareLeScelteDiUnSuonoNessunoFissoOCasuale;
  end;

implementation

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Midi.Intf, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Intf,
  DelphiDoom.War.Music.Factory, DelphiDoom.War.Music.SilentSynth, DelphiDoom.War.Sound.Types,
  DelphiDoom.Tests.M2m.MidiBuilder;

{ TTestWarMusicFactory }

function TTestWarMusicFactory.Song: TBytes;
begin
  Result := TTestMidiBuilder.Join([TTestMidiBuilder.Header(0, 1, 100),
    TTestMidiBuilder.Track(TTestMidiBuilder.Join([TTestMidiBuilder.ProgramChange(0, 0, 5),
      TTestMidiBuilder.NoteOn(10, 0, 60, 100), TTestMidiBuilder.NoteOff(50, 0, 60, 0),
      TTestMidiBuilder.EndOfTrack(0)]))]);
end;

procedure TTestWarMusicFactory.DovrebbeFarSuonareUnaCanzoneConIlSintetizzatoreMuto;
var
  LLog: ILog;
  LPlayer: IWarMusicPlayer;
begin
  LLog := nil;
  LPlayer := TWarMusicFactory.CreatePlayer(TWarMusicFactory.CreateSilentSynth, TWarMusicFactory.CreateTimeline(LLog));
  Assert.IsTrue(LPlayer.Play(Song, False, 0));
  Assert.AreEqual<Integer>(Ord(wmsPlaying), Ord(LPlayer.State));
end;

procedure TTestWarMusicFactory.DovrebbeLasciareIlBufferComeEConIlSintetizzatoreMuto;
var
  LLog: ILog;
  LPlayer: IWarMusicPlayer;
  LBuffer: array[0..99] of SmallInt;
  LIndex: Integer;
begin
  LLog := nil;
  LPlayer := TWarMusicFactory.CreatePlayer(TWarMusicFactory.CreateSilentSynth, TWarMusicFactory.CreateTimeline(LLog));
  LPlayer.Play(Song, False, 0);
  for LIndex := 0 to High(LBuffer) do
    LBuffer[LIndex] := SmallInt(LIndex * 7 - 300);
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  for LIndex := 0 to High(LBuffer) do
    Assert.AreEqual<Integer>(LIndex * 7 - 300, LBuffer[LIndex]);
end;

procedure TTestWarMusicFactory.DovrebbeFinireLaCanzoneAncheSenzaSuono;
var
  LLog: ILog;
  LPlayer: IWarMusicPlayer;
  LBuffer: array[0..4409] of SmallInt;
begin
  LLog := nil;
  LPlayer := TWarMusicFactory.CreatePlayer(TWarMusicFactory.CreateSilentSynth, TWarMusicFactory.CreateTimeline(LLog));
  LPlayer.Play(Song, False, 0);
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  // the last event is at 60 ticks of 5 ms, 300 ms: 13230 samples
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  Assert.AreEqual<Integer>(Ord(wmsPlaying), Ord(LPlayer.State), '100 ms');
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  Assert.AreEqual<Integer>(Ord(wmsEnded), Ord(LPlayer.State), '400 ms');
end;

procedure TTestWarMusicFactory.DovrebbeFarCreareLaDissolvenzaDallaFabbrica;
var
  LLog: ILog;
  LPlayer: IWarMusicPlayer;
  LBuffer: array[0..4409] of SmallInt;
begin
  LLog := nil;
  LPlayer := TWarMusicFactory.CreatePlayer(TWarMusicFactory.CreateSilentSynth, TWarMusicFactory.CreateTimeline(LLog));
  LPlayer.Play(Song, True, 50);
  LPlayer.Stop(50);
  Assert.AreEqual<Integer>(Ord(wmsFadingOut), Ord(LPlayer.State));
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LPlayer.Mix(@LBuffer[0], Length(LBuffer));
  Assert.AreEqual<Integer>(Ord(wmsStopped), Ord(LPlayer.State), 'The fade of 50 ms is over after 100 ms');
end;

procedure TTestWarMusicFactory.DovrebbeRifiutareUnaCanzoneCheNonSiLegge;
var
  LLog: ILog;
  LPlayer: IWarMusicPlayer;
begin
  LLog := nil;
  LPlayer := TWarMusicFactory.CreatePlayer(TWarMusicFactory.CreateSilentSynth, TWarMusicFactory.CreateTimeline(LLog));
  Assert.IsFalse(LPlayer.Play(TTestMidiBuilder.Bytes([1, 2, 3, 4, 5]), False, 0));
  Assert.AreEqual<Integer>(Ord(wmsStopped), Ord(LPlayer.State));
end;

procedure TTestWarMusicFactory.DovrebbeAccettareUnLogNulloPerLaCanzone;
var
  LLog: ILog;
begin
  LLog := nil;
  Assert.IsNotNull(TWarMusicFactory.CreateTimeline(LLog));
end;

procedure TTestWarMusicFactory.DovrebbeNonFareNullaDalSintetizzatoreMuto;
var
  LSynth: IWarMusicSynth;
  LBuffer: array[0..3] of SmallInt;
begin
  LSynth := TWarSilentMusicSynth.Create;
  LSynth.ProgramChange(0, 1, False);
  LSynth.NoteOn(0, 60, 1.0);
  LSynth.NoteOff(0, 60);
  LSynth.PitchBend(0, 8192);
  LSynth.ControlChange(0, 7, 100);
  LSynth.AllNotesOff;
  LBuffer[0] := 5;
  LBuffer[3] := -5;
  LSynth.Render(@LBuffer[0], 4);
  Assert.AreEqual<Integer>(5, LBuffer[0]);
  Assert.AreEqual<Integer>(-5, LBuffer[3]);
end;

procedure TTestWarMusicFactory.DovrebbeDareLeScelteDiUnSuonoNessunoFissoOCasuale;
begin
  Assert.IsTrue(TWarSoundChoice.None.IsNone);
  Assert.IsFalse(TWarSoundChoice.None.IsRandom);
  Assert.IsFalse(TWarSoundChoice.Fixed(5).IsNone);
  Assert.IsFalse(TWarSoundChoice.Fixed(5).IsRandom);
  Assert.IsTrue(TWarSoundChoice.Range(5, 7).IsRandom);
  Assert.IsFalse(TWarSoundChoice.Range(5, 5).IsRandom);
end;

end.
