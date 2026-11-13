{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the player of the music of Libs\War                    }
{                                                                              }
{  A fake synth writes down its calls, a fake timeline gives the events: no    }
{  MIDI file, no SoundFont. A block of 64 samples at 44100 Hz is 1.4512 ms:    }
{  an event at 100 ms fires in the 69th block, that starts at sample 4352.     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicPlayer;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Intf,
  DelphiDoom.Tests.War.MusicFakes;

type
  [TestFixture]
  [Category('war')]
  TTestWarMusicPlayer = class
  strict private
    FSynthObject: TFakeMusicSynth;
    FSynth: IWarMusicSynth;
    FTimelineObject: TFakeMusicTimeline;
    FPlayer: IWarMusicPlayer;
    procedure Start(const AEvents: TArray<TWarMusicEvent>; ALevel: SmallInt = 0);
    class function Note(ATimeMs: Cardinal; AKind: TWarMusicEventKind; AChannel, AKey: Integer;
      AValue: Integer = 0): TWarMusicEvent; static;
    function MixSamples(ACount: Integer; ABase: SmallInt = 0): TArray<SmallInt>;
    function CountCalls(const AKind: string): Integer;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareSintetizzatoreEOrdineNulli;
    [Test]
    procedure DovrebbeDareFalsoESuonoFermoSeLaCanzoneNonSiLegge;
    [Test]
    procedure DovrebbeSommareIlSuonoDelSintetizzatoreAlBuffer;
    [Test]
    procedure DovrebbeFarScattareUnEventoNelBloccoDa64DoveCadeIlSuoTempo;
    [Test]
    procedure DovrebbeNonFarScattareUnEventoPrimaDelSuoTempo;
    [Test]
    procedure DovrebbeFarScattareGliEventiDelloStessoTempoNellOrdineDellaCanzone;
    [Test]
    procedure DovrebbeInoltrareOgniTipoDiEventoAlSintetizzatore;
    [Test]
    procedure DovrebbeMettereLaBatteriaSulCanale9;
    [Test]
    procedure DovrebbeScalareLaVelocitaDelleNoteConIlVolume;
    [Test]
    procedure DovrebbeTenereLaVelocitaDellaNotaGiaIniziataQuandoCambiaIlVolume;
    [Test]
    procedure DovrebbeLimitareIlVolumeTraZeroEUno;
    [Test]
    procedure DovrebbeFermareLaCanzoneConIlVolumeAZero;
    [Test]
    procedure DovrebbeFermareLaCanzoneSeLaMusicaEDisabilitata;
    [Test]
    procedure DovrebbeSpegnereLeNoteUnaSolaVoltaMentreESilenziata;
    [Test]
    procedure DovrebbeRiprendereDoveEraDopoIlSilenzio;
    [Test]
    procedure DovrebbeFinireAllUltimoEventoSenzaCiclo;
    [Test]
    procedure DovrebbeFinireNellaChiamataInCuiScattaLUltimoEvento;
    [Test]
    procedure DovrebbeNonFareNullaDopoLaFine;
    [Test]
    procedure DovrebbeRicominciareSubitoDopoLUltimoEventoNelCiclo;
    [Test]
    procedure DovrebbeTenereIlTempoCheERestatoOltreLUltimoEventoNelCiclo;
    [Test]
    procedure DovrebbeFermareUnCicloChePartirebbeSenzaFine;
    [Test]
    procedure DovrebbeFinireUnaCanzoneVuotaAncheNelCiclo;
    [Test]
    procedure DovrebbeContareUnEventoIgnoratoNelTempoDelCiclo;
    [Test]
    procedure DovrebbeFermareSubitoConDissolvenzaZero;
    [Test]
    procedure DovrebbeFermareDopoLaDissolvenzaInUscita;
    [Test]
    procedure DovrebbeAbbassareIlSuonoDuranteLaDissolvenzaInUscita;
    [Test]
    procedure DovrebbeAlzareIlSuonoDuranteLaDissolvenzaInEntrata;
    [Test]
    procedure DovrebbeSostituireLaCanzoneChePartecipa;
    [Test]
    procedure DovrebbeNonFareNullaSeStopArrivaASuonoFermo;
    [Test]
    procedure DovrebbeServireUnaRichiestaPiuLungaDelBufferInterno;
    [Test]
    procedure DovrebbeSommareConSaturazioneAlBuffer;
    [Test]
    procedure DovrebbeIgnorareUnaRichiestaSenzaCampioni;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Music.Player;

{ TTestWarMusicPlayer }

class function TTestWarMusicPlayer.Note(ATimeMs: Cardinal; AKind: TWarMusicEventKind; AChannel, AKey: Integer;
  AValue: Integer): TWarMusicEvent;
begin
  Result := Default(TWarMusicEvent);
  Result.TimeMs := ATimeMs;
  Result.Kind := AKind;
  Result.Channel := AChannel;
  Result.Key := AKey;
  Result.Value := AValue;
end;

procedure TTestWarMusicPlayer.Start(const AEvents: TArray<TWarMusicEvent>; ALevel: SmallInt);
begin
  FSynthObject := TFakeMusicSynth.Create(ALevel);
  FSynth := FSynthObject;
  FTimelineObject := TFakeMusicTimeline.Create(AEvents);
  FPlayer := TWarMusicPlayer.Create(FSynth, FTimelineObject, 44100);
end;

procedure TTestWarMusicPlayer.TearDown;
begin
  FPlayer := nil;
  FSynth := nil;
  FSynthObject := nil;
  FTimelineObject := nil;
end;

function TTestWarMusicPlayer.MixSamples(ACount: Integer; ABase: SmallInt): TArray<SmallInt>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := ABase;
  FPlayer.Mix(@Result[0], ACount);
end;

function TTestWarMusicPlayer.CountCalls(const AKind: string): Integer;
var
  LCall: string;
begin
  Result := 0;
  for LCall in FSynthObject.Calls do
    if LCall.Split([' '])[1] = AKind then
      Inc(Result);
end;

procedure TTestWarMusicPlayer.DovrebbeRifiutareSintetizzatoreEOrdineNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarMusicPlayer.Create(nil, TFakeMusicTimeline.Create([]), 44100);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarMusicPlayer.Create(TFakeMusicSynth.Create, nil, 44100);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarMusicPlayer.Create(TFakeMusicSynth.Create, TFakeMusicTimeline.Create([]), 0);
    end, EWarException);
end;

procedure TTestWarMusicPlayer.DovrebbeDareFalsoESuonoFermoSeLaCanzoneNonSiLegge;
begin
  FSynthObject := TFakeMusicSynth.Create;
  FSynth := FSynthObject;
  FTimelineObject := TFakeMusicTimeline.Create([], False);
  FPlayer := TWarMusicPlayer.Create(FSynth, FTimelineObject, 44100);
  Assert.IsFalse(FPlayer.Play(nil, False, 0));
  Assert.AreEqual<Integer>(Ord(wmsStopped), Ord(FPlayer.State));
  MixSamples(100);
  Assert.AreEqual<Integer>(0, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeSommareIlSuonoDelSintetizzatoreAlBuffer;
var
  LSamples: TArray<SmallInt>;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)], 25);
  Assert.IsTrue(FPlayer.Play([1], False, 0));
  LSamples := MixSamples(100, 1000);
  Assert.AreEqual<Integer>(1025, LSamples[0]);
  Assert.AreEqual<Integer>(1025, LSamples[99]);
  Assert.AreEqual<Integer>(100, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeFarScattareUnEventoNelBloccoDa64DoveCadeIlSuoTempo;
begin
  Start([Note(100, wmkNoteOn, 1, 60, 127)]);
  FPlayer.Play([1], False, 0);
  MixSamples(10000);
  Assert.AreEqual<Integer>(1, CountCalls('ON'));
  Assert.AreEqual('4352 ON 1 60 3f800000', FSynthObject.Calls[0]);
end;

procedure TTestWarMusicPlayer.DovrebbeNonFarScattareUnEventoPrimaDelSuoTempo;
begin
  Start([Note(100, wmkNoteOn, 1, 60, 127)]);
  FPlayer.Play([1], False, 0);
  // 68 blocks are 98.69 ms: the event at 100 ms is not due yet
  MixSamples(68 * 64);
  Assert.AreEqual<Integer>(0, FSynthObject.Calls.Count);
  MixSamples(64);
  Assert.AreEqual<Integer>(1, CountCalls('ON'));
end;

procedure TTestWarMusicPlayer.DovrebbeFarScattareGliEventiDelloStessoTempoNellOrdineDellaCanzone;
begin
  Start([Note(0, wmkProgramChange, 2, 5), Note(0, wmkNoteOn, 2, 64, 100), Note(0, wmkNoteOff, 2, 64)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  Assert.AreEqual('0 PC 2 5 0', FSynthObject.Calls[0]);
  Assert.IsTrue(FSynthObject.Calls[1].StartsWith('0 ON 2 64 '));
  Assert.AreEqual('0 OF 2 64', FSynthObject.Calls[2]);
end;

procedure TTestWarMusicPlayer.DovrebbeInoltrareOgniTipoDiEventoAlSintetizzatore;
begin
  Start([Note(0, wmkPitchBend, 3, 0, 8192), Note(0, wmkControlChange, 3, 7, 99), Note(0, wmkNoteOn, 3, 40, 127),
    Note(0, wmkNoteOff, 3, 40)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  Assert.AreEqual('0 PB 3 8192', FSynthObject.Calls[0]);
  Assert.AreEqual('0 CC 3 7 99', FSynthObject.Calls[1]);
  Assert.AreEqual(1, CountCalls('ON'));
  Assert.AreEqual(1, CountCalls('OF'));
end;

procedure TTestWarMusicPlayer.DovrebbeMettereLaBatteriaSulCanale9;
begin
  Start([Note(0, wmkProgramChange, 9, 0), Note(0, wmkProgramChange, 8, 0)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  Assert.AreEqual('0 PC 9 0 1', FSynthObject.Calls[0]);
  Assert.AreEqual('0 PC 8 0 0', FSynthObject.Calls[1]);
end;

procedure TTestWarMusicPlayer.DovrebbeScalareLaVelocitaDelleNoteConIlVolume;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127)]);
  FPlayer.SetVolume(0.5, True);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  Assert.AreEqual('0 ON 0 60 3f000000', FSynthObject.Calls[0]);
end;

procedure TTestWarMusicPlayer.DovrebbeTenereLaVelocitaDellaNotaGiaIniziataQuandoCambiaIlVolume;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127), Note(30, wmkNoteOn, 0, 61, 127)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  FPlayer.SetVolume(0.25, True);
  MixSamples(2000);
  // only the note that starts after the change has the new volume: the first call is not asked again
  Assert.AreEqual('0 ON 0 60 3f800000', FSynthObject.Calls[0]);
  Assert.IsTrue(FSynthObject.Calls[1].EndsWith(' 3e800000'), FSynthObject.Calls[1]);
end;

procedure TTestWarMusicPlayer.DovrebbeLimitareIlVolumeTraZeroEUno;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127)]);
  FPlayer.SetVolume(7, True);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  Assert.AreEqual('0 ON 0 60 3f800000', FSynthObject.Calls[0]);
end;

procedure TTestWarMusicPlayer.DovrebbeFermareLaCanzoneConIlVolumeAZero;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127)]);
  FPlayer.SetVolume(-1, True);
  FPlayer.Play([1], False, 0);
  MixSamples(1000);
  Assert.AreEqual<Integer>(0, FSynthObject.Rendered, 'The song does not advance');
  FPlayer.SetVolume(1, True);
  MixSamples(64);
  Assert.AreEqual<Integer>(1, CountCalls('ON'));
end;

procedure TTestWarMusicPlayer.DovrebbeFermareLaCanzoneSeLaMusicaEDisabilitata;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127)]);
  FPlayer.SetVolume(1, False);
  FPlayer.Play([1], False, 0);
  MixSamples(1000);
  Assert.AreEqual<Integer>(0, FSynthObject.Calls.Count);
  Assert.AreEqual<Integer>(Ord(wmsPlaying), Ord(FPlayer.State));
end;

procedure TTestWarMusicPlayer.DovrebbeSpegnereLeNoteUnaSolaVoltaMentreESilenziata;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127)]);
  FPlayer.Play([1], False, 0);
  FPlayer.SetSilenced(True);
  MixSamples(500);
  MixSamples(500);
  Assert.AreEqual(1, CountCalls('AO'));
  Assert.AreEqual(0, CountCalls('ON'));
  Assert.AreEqual<Integer>(0, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeRiprendereDoveEraDopoIlSilenzio;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 127)]);
  FPlayer.Play([1], False, 0);
  FPlayer.SetSilenced(True);
  MixSamples(500);
  FPlayer.SetSilenced(False);
  MixSamples(64);
  Assert.AreEqual(1, CountCalls('ON'));
end;

procedure TTestWarMusicPlayer.DovrebbeFinireAllUltimoEventoSenzaCiclo;
begin
  Start([Note(10, wmkNoteOn, 0, 60, 100)]);
  FPlayer.Play([1], False, 0);
  MixSamples(1000);
  Assert.AreEqual<Integer>(Ord(wmsEnded), Ord(FPlayer.State));
  Assert.AreEqual(1, CountCalls('AO'), 'The notes that were left sounding stop');
end;

procedure TTestWarMusicPlayer.DovrebbeFinireNellaChiamataInCuiScattaLUltimoEvento;
begin
  Start([Note(10, wmkNoteOn, 0, 60, 100)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64 * 6);
  Assert.AreEqual<Integer>(Ord(wmsPlaying), Ord(FPlayer.State), 'The event at 10 ms is in the 7th block');
  MixSamples(64 * 3);
  Assert.AreEqual<Integer>(Ord(wmsEnded), Ord(FPlayer.State));
  // the rest of the call is rendered as the original does
  Assert.AreEqual<Integer>(64 * 9, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeNonFareNullaDopoLaFine;
var
  LSamples: TArray<SmallInt>;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 100)], 7);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  LSamples := MixSamples(64, 3);
  Assert.AreEqual<Integer>(3, LSamples[0]);
  Assert.AreEqual<Integer>(64, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeRicominciareSubitoDopoLUltimoEventoNelCiclo;
var
  LIndex, LOns: Integer;
  LParts: TArray<string>;
  LPositions: TArray<Integer>;
begin
  // the last event is at 20 ms: the song starts again as soon as it has fired
  Start([Note(10, wmkNoteOn, 0, 60, 100), Note(20, wmkNoteOff, 0, 60)]);
  FPlayer.Play([1], True, 0);
  MixSamples(44100);
  Assert.AreEqual<Integer>(Ord(wmsPlaying), Ord(FPlayer.State));
  Assert.IsTrue(FTimelineObject.RewindCount > 20, 'It loops many times in one second');
  LOns := 0;
  for LIndex := 0 to FSynthObject.Calls.Count - 1 do
  begin
    LParts := FSynthObject.Calls[LIndex].Split([' ']);
    if LParts[1] = 'ON' then
    begin
      SetLength(LPositions, Length(LPositions) + 1);
      LPositions[High(LPositions)] := StrToInt(LParts[0]);
      Inc(LOns);
    end;
  end;
  Assert.IsTrue(LOns > 20);
  // one turn is the 20 ms of the song: 882 samples (a block of 64 of slack)
  Assert.IsTrue(Abs(LPositions[2] - LPositions[1] - 882) <= 64, IntToStr(LPositions[2] - LPositions[1]));
end;

procedure TTestWarMusicPlayer.DovrebbeTenereIlTempoCheERestatoOltreLUltimoEventoNelCiclo;
var
  LFirst, LSecond: Integer;
begin
  // a single call of 10000 samples goes round more than once: the time past the end is not lost
  Start([Note(30, wmkNoteOn, 0, 60, 100)]);
  FPlayer.Play([1], True, 0);
  MixSamples(10000);
  LFirst := CountCalls('ON');
  // 226 ms with a turn of 30 ms: seven turns, give or take the block
  Assert.IsTrue((LFirst >= 6) and (LFirst <= 8), IntToStr(LFirst));
  LSecond := FTimelineObject.RewindCount;
  Assert.IsTrue(LSecond >= LFirst - 1);
end;

procedure TTestWarMusicPlayer.DovrebbeFermareUnCicloChePartirebbeSenzaFine;
begin
  // the only event is at time 0: the turn has no length (the original would never leave the block)
  Start([Note(0, wmkNoteOn, 0, 60, 100)]);
  FPlayer.Play([1], True, 0);
  MixSamples(64);
  Assert.AreEqual<Integer>(Ord(wmsEnded), Ord(FPlayer.State));
  Assert.IsTrue(CountCalls('ON') <= 65);
end;

procedure TTestWarMusicPlayer.DovrebbeFinireUnaCanzoneVuotaAncheNelCiclo;
begin
  Start([]);
  FPlayer.Play([1], True, 0);
  MixSamples(64);
  Assert.AreEqual<Integer>(Ord(wmsEnded), Ord(FPlayer.State));
end;

procedure TTestWarMusicPlayer.DovrebbeContareUnEventoIgnoratoNelTempoDelCiclo;
begin
  // the last message of the list is not played (a tempo or a pressure) but the turn lasts until it: 40 ms
  Start([Note(10, wmkNoteOn, 0, 60, 100), Note(40, wmkIgnored, 0, 0)]);
  FPlayer.Play([1], True, 0);
  MixSamples(44100);
  // 1000 ms / 40 ms = 25 turns
  Assert.IsTrue(Abs(CountCalls('ON') - 25) <= 2, IntToStr(CountCalls('ON')));
  Assert.AreEqual(0, CountCalls('PB') + CountCalls('CC'));
end;

procedure TTestWarMusicPlayer.DovrebbeFermareSubitoConDissolvenzaZero;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  FPlayer.Stop(0);
  Assert.AreEqual<Integer>(Ord(wmsStopped), Ord(FPlayer.State));
  Assert.AreEqual(1, CountCalls('AO'));
  MixSamples(64);
  Assert.AreEqual<Integer>(64, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeFermareDopoLaDissolvenzaInUscita;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)], 1000);
  FPlayer.Play([1], False, 0);
  FPlayer.Stop(100);
  Assert.AreEqual<Integer>(Ord(wmsFadingOut), Ord(FPlayer.State));
  // 100 ms are 4410 samples
  MixSamples(4000);
  Assert.AreEqual<Integer>(Ord(wmsFadingOut), Ord(FPlayer.State));
  MixSamples(500);
  Assert.AreEqual<Integer>(Ord(wmsStopped), Ord(FPlayer.State));
  Assert.AreEqual(1, CountCalls('AO'));
end;

procedure TTestWarMusicPlayer.DovrebbeAbbassareIlSuonoDuranteLaDissolvenzaInUscita;
var
  LSamples: TArray<SmallInt>;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)], 1000);
  FPlayer.Play([1], False, 0);
  FPlayer.Stop(1000);
  LSamples := MixSamples(44100);
  Assert.AreEqual<Integer>(1000, LSamples[0]);
  Assert.IsTrue(Abs(LSamples[22050] - 500) <= 2, IntToStr(LSamples[22050]));
  Assert.IsTrue(LSamples[44099] < 5);
end;

procedure TTestWarMusicPlayer.DovrebbeAlzareIlSuonoDuranteLaDissolvenzaInEntrata;
var
  LSamples: TArray<SmallInt>;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)], 1000);
  FPlayer.Play([1], False, 1000);
  LSamples := MixSamples(44100 + 1000);
  Assert.AreEqual<Integer>(0, LSamples[0]);
  Assert.IsTrue(Abs(LSamples[22050] - 500) <= 2, IntToStr(LSamples[22050]));
  Assert.AreEqual<Integer>(1000, LSamples[44100 + 500]);
end;

procedure TTestWarMusicPlayer.DovrebbeSostituireLaCanzoneChePartecipa;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)]);
  FPlayer.Play([1], False, 0);
  MixSamples(64);
  FPlayer.Play([2], False, 0);
  Assert.AreEqual<Integer>(2, FTimelineObject.LoadCount);
  Assert.AreEqual(1, CountCalls('AO'), 'The notes of the first song stop');
  Assert.AreEqual<Integer>(Ord(wmsPlaying), Ord(FPlayer.State));
end;

procedure TTestWarMusicPlayer.DovrebbeNonFareNullaSeStopArrivaASuonoFermo;
begin
  Start([]);
  FPlayer.Stop(500);
  Assert.AreEqual<Integer>(Ord(wmsStopped), Ord(FPlayer.State));
  Assert.AreEqual<Integer>(0, FSynthObject.Calls.Count);
end;

procedure TTestWarMusicPlayer.DovrebbeServireUnaRichiestaPiuLungaDelBufferInterno;
var
  LSamples: TArray<SmallInt>;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)], 5);
  FPlayer.Play([1], False, 0);
  LSamples := MixSamples(WAR_MUSIC_SCRATCH_SAMPLES * 2 + 100);
  Assert.AreEqual<Integer>(5, LSamples[0]);
  Assert.AreEqual<Integer>(5, LSamples[WAR_MUSIC_SCRATCH_SAMPLES]);
  Assert.AreEqual<Integer>(5, LSamples[High(LSamples)]);
  Assert.AreEqual<Integer>(WAR_MUSIC_SCRATCH_SAMPLES * 2 + 100, FSynthObject.Rendered);
end;

procedure TTestWarMusicPlayer.DovrebbeSommareConSaturazioneAlBuffer;
var
  LSamples: TArray<SmallInt>;
begin
  Start([Note(100000, wmkNoteOff, 0, 60)], 1000);
  FPlayer.Play([1], False, 0);
  LSamples := MixSamples(10, 32500);
  Assert.AreEqual<Integer>(32767, LSamples[0]);
  LSamples := MixSamples(10, -32500);
  Assert.AreEqual<Integer>(-31500, LSamples[0]);
end;

procedure TTestWarMusicPlayer.DovrebbeIgnorareUnaRichiestaSenzaCampioni;
begin
  Start([Note(0, wmkNoteOn, 0, 60, 100)]);
  FPlayer.Play([1], False, 0);
  FPlayer.Mix(nil, 0);
  FPlayer.Mix(nil, -5);
  Assert.AreEqual<Integer>(0, FSynthObject.Calls.Count);
end;

end.
