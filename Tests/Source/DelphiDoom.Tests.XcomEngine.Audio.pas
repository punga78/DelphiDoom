{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio of the xcom game: the volume curve, the WAV   }
{  decoder, the mixer and the Adlib and WAV tracks (fakes: no device, no file   }
{  of the original game)                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Audio;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Volume,
  DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.Types,
  DelphiDoom.XcomAudio.WaveDecoder, DelphiDoom.XcomAudio.Mixer, DelphiDoom.XcomAudio.ManualOutput,
  DelphiDoom.XcomAudio.AdlibTrack, DelphiDoom.XcomAudio.WavTrack, DelphiDoom.Tests.XcomEngine.AudioFakes;

type
  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomVolume = class
  public
    [Test]
    procedure LaCurvaVaDaZeroAlMassimo;
    [Test]
    procedure IlVolumeDelMixerSiTroncaComeSdl;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomWaveDecoder = class
  public
    [Test]
    procedure UnMonoA8BitDa11025A22050RaddoppiaICampioni;
    [Test]
    procedure UnoStereoA16BitPassaCosiComE;
    [Test]
    procedure UnMonoA16BitDiventaStereo;
    [Test]
    procedure UnFileCheNonEPcmDaEccezione;
    [Test]
    procedure UnaIntestazioneTroncataDaEccezione;
    [Test]
    procedure UnChunkDatiPiuLungoDelFileSiLimitaAlFile;
    [Test]
    procedure UnChunkSconosciutoPrimaDeiDatiSiSalta;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMixer = class
  strict private
    FOutput: TXcomManualPcmOutput;
    FOutputRef: IXcomPcmOutput;
    FDevice: IXcomAudioDevice;
    FMeter: IXcomMixerMeter;
    FSink: IXcomMusicSink;
    function SampleAt(const ASamples: TBytes; AIndex: Integer): Integer;
    procedure Open;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaUscitaNonSuonaNulla;
    [Test]
    procedure UnSuonoArrivaAllUscitaEPoiFinisce;
    [Test]
    procedure IlTredicesimoSuonoContemporaneoSiPerde;
    [Test]
    procedure DueSuoniFortiSiSommanoSaturando;
    [Test]
    procedure UnaRichiestaNonMultiplaDiQuattroDaEccezione;
    [Test]
    procedure IlSilenzioHaRmsZeroEUnSuonoNo;
    [Test]
    procedure UnaTracciaDiMusicaSiAggiungeAlMix;
    [Test]
    procedure LaMusicaInPausaTace;
    [Test]
    procedure IlVolumeDellaMusicaSiApplicaAllaTraccia;
    [Test]
    procedure UnaTracciaNuovaFermaLaPrecedente;
    [Test]
    procedure FermareLaMusicaFermaLaTraccia;
    [Test]
    procedure UnFileNonWavNonDaSuono;
    [Test]
    procedure ChiudereFermaLUscita;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomTracks = class
  strict private
    function Buffer(AFrames: Integer): TArray<SmallInt>;
  public
    [Test]
    procedure LaTracciaAdlibCaricaESuonaConLaNormalizzazione;
    [Test]
    procedure LaTracciaAdlibNonRenderizzaSeNonAttiva;
    [Test]
    procedure LaTracciaAdlibConVolumeZeroTace;
    [Test]
    procedure LaTracciaAdlibSommaICampioniDelPlayer;
    [Test]
    procedure LaTracciaAdlibRipartePerMusicAlwaysLoop;
    [Test]
    procedure LaTracciaAdlibNonRipartePerSenzaMusicAlwaysLoop;
    [Test]
    procedure FermareUnaTracciaAdlibNonAttivaNonFermaIlPlayer;
    [Test]
    procedure UnaTracciaWavSuonaUnaVoltaEPoiFinisce;
    [Test]
    procedure UnaTracciaWavInLoopInfinitoNonFinisce;
    [Test]
    procedure UnaTracciaWavConLoopTreVolteFinisceDopoTre;
    [Test]
    procedure UnaTracciaWavApplicaIlVolume;
    [Test]
    procedure UnaTracciaWavRifiutaUnFileNonPcm;
    [Test]
    procedure UnaTracciaWavVuotaNonPartePerNulla;
  end;

implementation

const
  RATE = 22050;

{ TTestXcomVolume }

procedure TTestXcomVolume.LaCurvaVaDaZeroAlMassimo;
begin
  Assert.AreEqual(0.0, TXcomVolume.Exponent(0), 1e-12);
  Assert.AreEqual(1.0, TXcomVolume.Exponent(128), 1e-12);
  Assert.IsTrue(TXcomVolume.Exponent(64) < 0.5);
  Assert.IsTrue(TXcomVolume.Exponent(64) > TXcomVolume.Exponent(32));
end;

procedure TTestXcomVolume.IlVolumeDelMixerSiTroncaComeSdl;
begin
  Assert.AreEqual(0, TXcomVolume.Mixer(0));
  Assert.AreEqual(128, TXcomVolume.Mixer(128));
  // (exp(ln(11) * 84 / 128) - 1) / 10 * 128 = 48.9
  Assert.AreEqual(48, TXcomVolume.Mixer(84));
end;

{ TTestXcomWaveDecoder }

procedure TTestXcomWaveDecoder.UnMonoA8BitDa11025A22050RaddoppiaICampioni;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TXcomWaveDecoder.ToStereo16(TWaveMaker.Make(11025, 1, 8, TBytes.Create(128, 255)), 22050);
  // two samples at the half rate: four frames, each sample twice, each frame in both channels
  Assert.AreEqual(8, Length(LSamples));
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(0, Integer(LSamples[3]));
  Assert.AreEqual(127 * 256, Integer(LSamples[4]));
  Assert.AreEqual(127 * 256, Integer(LSamples[7]));
end;

procedure TTestXcomWaveDecoder.UnoStereoA16BitPassaCosiComE;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TXcomWaveDecoder.ToStereo16(TWaveMaker.Make(22050, 2, 16,
    TBytes.Create($01, $00, $FF, $FF, $00, $80, $FF, $7F)), 22050);
  Assert.AreEqual(4, Length(LSamples));
  Assert.AreEqual(1, Integer(LSamples[0]));
  Assert.AreEqual(-1, Integer(LSamples[1]));
  Assert.AreEqual(-32768, Integer(LSamples[2]));
  Assert.AreEqual(32767, Integer(LSamples[3]));
end;

procedure TTestXcomWaveDecoder.UnMonoA16BitDiventaStereo;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TXcomWaveDecoder.ToStereo16(TWaveMaker.Make(22050, 1, 16, TBytes.Create($10, $00, $F0, $FF)), 22050);
  Assert.AreEqual(4, Length(LSamples));
  Assert.AreEqual(16, Integer(LSamples[0]));
  Assert.AreEqual(16, Integer(LSamples[1]));
  Assert.AreEqual(-16, Integer(LSamples[2]));
  Assert.AreEqual(-16, Integer(LSamples[3]));
end;

procedure TTestXcomWaveDecoder.UnFileCheNonEPcmDaEccezione;
var
  LWave: TBytes;
begin
  LWave := TWaveMaker.Make(22050, 1, 8, TBytes.Create(1, 2));
  // the format tag 2 is ADPCM
  LWave[20] := 2;
  Assert.WillRaise(
    procedure
    begin
      TXcomWaveDecoder.ToStereo16(LWave, 22050);
    end, EXcomAudioException);
  Assert.WillRaise(
    procedure
    begin
      TXcomWaveDecoder.ToStereo16(TWaveMaker.Make(22050, 3, 8, TBytes.Create(1, 2, 3)), 22050);
    end, EXcomAudioException);
  Assert.WillRaise(
    procedure
    begin
      TXcomWaveDecoder.ToStereo16(TWaveMaker.Make(22050, 1, 12, TBytes.Create(1, 2)), 22050);
    end, EXcomAudioException);
end;

procedure TTestXcomWaveDecoder.UnaIntestazioneTroncataDaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomWaveDecoder.ToStereo16(TBytes.Create(1, 2, 3), 22050);
    end, EXcomAudioException);
  Assert.WillRaise(
    procedure
    begin
      TXcomWaveDecoder.ToStereo16(TEncoding.ASCII.GetBytes('RIFF....WAVE'), 22050);
    end, EXcomAudioException);
  Assert.WillRaise(
    procedure
    begin
      TXcomWaveDecoder.ToStereo16(TWaveMaker.Make(22050, 1, 8, TBytes.Create(1, 2)), 0);
    end, EXcomAudioException);
end;

procedure TTestXcomWaveDecoder.UnChunkDatiPiuLungoDelFileSiLimitaAlFile;
var
  LWave: TBytes;
  LSamples: TArray<SmallInt>;
begin
  LWave := TWaveMaker.Make(22050, 1, 8, TBytes.Create(128, 128, 128, 128));
  // the size of the data chunk says 1000
  LWave[40] := $E8;
  LWave[41] := $03;
  LSamples := TXcomWaveDecoder.ToStereo16(LWave, 22050);
  Assert.AreEqual(8, Length(LSamples));
end;

procedure TTestXcomWaveDecoder.UnChunkSconosciutoPrimaDeiDatiSiSalta;
var
  LWave: TBytes;
  LExtra: TBytes;
  LSamples: TArray<SmallInt>;
begin
  LWave := TWaveMaker.Make(22050, 1, 8, TBytes.Create(255, 255));
  // a "LIST" chunk of 3 bytes (plus the byte that makes it even) between the format and the data
  LExtra := TEncoding.ASCII.GetBytes('LIST') + TBytes.Create(3, 0, 0, 0, 1, 2, 3, 0);
  LWave := Copy(LWave, 0, 36) + LExtra + Copy(LWave, 36, Length(LWave) - 36);
  LSamples := TXcomWaveDecoder.ToStereo16(LWave, 22050);
  Assert.AreEqual(4, Length(LSamples));
  Assert.AreEqual(127 * 256, Integer(LSamples[0]));
end;

{ TTestXcomMixer }

procedure TTestXcomMixer.Setup;
begin
  FOutput := TXcomManualPcmOutput.Create;
  FOutputRef := FOutput;
  FDevice := TXcomMixer.Create(FOutputRef, RATE);
  FMeter := FDevice as IXcomMixerMeter;
  FSink := FDevice as IXcomMusicSink;
end;

procedure TTestXcomMixer.TearDown;
begin
  FSink := nil;
  FMeter := nil;
  FDevice.Close;
  FDevice := nil;
  FOutputRef := nil;
end;

procedure TTestXcomMixer.Open;
begin
  Assert.IsTrue(FMeter.Open);
end;

function TTestXcomMixer.SampleAt(const ASamples: TBytes; AIndex: Integer): Integer;
begin
  Result := SmallInt(ASamples[AIndex * 2] or (ASamples[AIndex * 2 + 1] shl 8));
end;

procedure TTestXcomMixer.SenzaUscitaNonSuonaNulla;
var
  LDevice: IXcomAudioDevice;
begin
  LDevice := TXcomMixer.Create(nil, RATE);
  Assert.IsFalse((LDevice as IXcomMixerMeter).Open);
  Assert.IsFalse(LDevice.IsAvailable);
  LDevice.PlayWave(TWaveMaker.Constant(255, 100));
  Assert.AreEqual(0, (LDevice as IXcomMixerMeter).ActiveChannels);
  LDevice.Close;
  // an output that cannot open (no loudspeaker) gives the same
  LDevice := TXcomMixer.Create(TXcomManualPcmOutput.Create(False), RATE);
  Assert.IsFalse((LDevice as IXcomMixerMeter).Open);
  Assert.IsFalse(LDevice.IsAvailable);
end;

procedure TTestXcomMixer.UnSuonoArrivaAllUscitaEPoiFinisce;
var
  LSamples: TBytes;
begin
  Open;
  Assert.IsTrue(FDevice.IsAvailable);
  Assert.AreEqual(RATE, FOutput.Rate);
  FDevice.PlayWave(TWaveMaker.Constant(255, 100));
  Assert.AreEqual(1, FMeter.ActiveChannels);
  // 100 frames of 127 * 256 on both channels, then silence
  LSamples := FOutput.Pump(400 * 2);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 199));
  Assert.AreEqual(0, SampleAt(LSamples, 200));
  Assert.AreEqual(0, FMeter.ActiveChannels);
end;

procedure TTestXcomMixer.IlTredicesimoSuonoContemporaneoSiPerde;
var
  LIndex: Integer;
begin
  Open;
  // the channels 0 to 3 are reserved: twelve sounds play, the next ones are dropped
  for LIndex := 1 to 13 do
    FDevice.PlayWave(TWaveMaker.Constant(200, 1000));
  Assert.AreEqual(12, FMeter.ActiveChannels);
  Assert.AreEqual(12, FMeter.Statistics.SoundsStarted);
end;

procedure TTestXcomMixer.DueSuoniFortiSiSommanoSaturando;
var
  LSamples: TBytes;
  LIndex: Integer;
begin
  Open;
  for LIndex := 1 to 4 do
    FDevice.PlayWave(TWaveMaker.Constant(255, 50));
  LSamples := FOutput.Pump(400);
  // 4 * 32512 does not fit: the sum stops at 32767
  Assert.AreEqual(32767, SampleAt(LSamples, 0));
  Assert.AreEqual(32767, FMeter.Statistics.Peak);
  for LIndex := 1 to 4 do
    FDevice.PlayWave(TWaveMaker.Constant(0, 50));
  LSamples := FOutput.Pump(400);
  Assert.AreEqual(-32768, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixer.UnaRichiestaNonMultiplaDiQuattroDaEccezione;
begin
  Open;
  Assert.WillRaise(
    procedure
    begin
      FOutput.Pump(6);
    end, EXcomAudioException);
  Assert.WillRaise(
    procedure
    begin
      FOutput.Pump(0);
    end, EXcomAudioException);
end;

procedure TTestXcomMixer.IlSilenzioHaRmsZeroEUnSuonoNo;
begin
  Open;
  FOutput.Pump(4000);
  Assert.AreEqual(4000, Integer(FMeter.Statistics.RenderedBytes));
  Assert.AreEqual(0.0, FMeter.Statistics.Rms, 1e-9);
  FDevice.PlayWave(TWaveMaker.Constant(255, 500));
  FOutput.Pump(4000);
  Assert.IsTrue(FMeter.Statistics.Rms > 1000);
end;

procedure TTestXcomMixer.UnaTracciaDiMusicaSiAggiungeAlMix;
var
  LTrack: TFakeTrack;
  LRef: IXcomMusicTrack;
  LSamples: TBytes;
begin
  Open;
  LTrack := TFakeTrack.Create;
  LRef := LTrack;
  LTrack.Value := 1000;
  FSink.PlayTrack(LRef, 3);
  Assert.AreEqual(3, LTrack.LastLoop);
  Assert.IsTrue(FSink.CurrentTrack = LRef);
  FDevice.PlayWave(TWaveMaker.Constant(192, 20));
  LSamples := FOutput.Pump(200);
  // the sound and the music add up (the music at the default volume of the mixer: full)
  Assert.AreEqual(64 * 256 + 1000, SampleAt(LSamples, 0));
  Assert.AreEqual(1000, SampleAt(LSamples, 49));
  FSink.StopTrack;
end;

procedure TTestXcomMixer.LaMusicaInPausaTace;
var
  LTrack: TFakeTrack;
  LRef: IXcomMusicTrack;
  LSamples: TBytes;
begin
  Open;
  LTrack := TFakeTrack.Create;
  LRef := LTrack;
  LTrack.Value := 500;
  FSink.PlayTrack(LRef, -1);
  FSink.PauseTrack(True);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(0, SampleAt(LSamples, 0));
  FSink.PauseTrack(False);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(500, SampleAt(LSamples, 0));
  FSink.StopTrack;
end;

procedure TTestXcomMixer.IlVolumeDellaMusicaSiApplicaAllaTraccia;
var
  LTrack: TFakeTrack;
  LRef: IXcomMusicTrack;
begin
  Open;
  LTrack := TFakeTrack.Create;
  LRef := LTrack;
  FSink.PlayTrack(LRef, -1);
  FDevice.SetVolume(10, 128, 10);
  FOutput.Pump(40);
  Assert.AreEqual(1.0, Double(LTrack.LastVolume), 1e-6);
  FDevice.SetVolume(10, 0, 10);
  FOutput.Pump(40);
  Assert.AreEqual(0.0, Double(LTrack.LastVolume), 1e-6);
  // a negative volume leaves the old one (Game::setVolume(-1, ...))
  FDevice.SetVolume(-1, 64, -1);
  FOutput.Pump(40);
  Assert.AreEqual(TXcomVolume.Exponent(64), Double(LTrack.LastVolume), 1e-6);
  FDevice.SetVolume(-1, -1, -1);
  FOutput.Pump(40);
  Assert.AreEqual(TXcomVolume.Exponent(64), Double(LTrack.LastVolume), 1e-6);
  FSink.StopTrack;
end;

procedure TTestXcomMixer.UnaTracciaNuovaFermaLaPrecedente;
var
  LFirst: TFakeTrack;
  LFirstRef: IXcomMusicTrack;
  LSecond: TFakeTrack;
  LSecondRef: IXcomMusicTrack;
begin
  Open;
  LFirst := TFakeTrack.Create;
  LFirstRef := LFirst;
  LSecond := TFakeTrack.Create;
  LSecondRef := LSecond;
  FSink.PlayTrack(LFirstRef, -1);
  FSink.PlayTrack(LSecondRef, -1);
  Assert.AreEqual(1, LFirst.Stopped);
  Assert.AreEqual(1, LSecond.Started);
  // the same track again does not stop itself
  FSink.PlayTrack(LSecondRef, -1);
  Assert.AreEqual(0, LSecond.Stopped);
  Assert.AreEqual(2, LSecond.Started);
  FSink.StopTrack;
end;

procedure TTestXcomMixer.FermareLaMusicaFermaLaTraccia;
var
  LTrack: TFakeTrack;
  LRef: IXcomMusicTrack;
begin
  Open;
  LTrack := TFakeTrack.Create;
  LRef := LTrack;
  FSink.PlayTrack(LRef, -1);
  FSink.StopTrack;
  Assert.AreEqual(1, LTrack.Stopped);
  Assert.IsTrue(FSink.CurrentTrack = nil);
  // stopping with no track is harmless
  FSink.StopTrack;
  Assert.AreEqual(1, LTrack.Stopped);
end;

procedure TTestXcomMixer.UnFileNonWavNonDaSuono;
begin
  Open;
  FDevice.PlayWave(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13));
  Assert.AreEqual(0, FMeter.ActiveChannels);
end;

procedure TTestXcomMixer.ChiudereFermaLUscita;
begin
  Open;
  FDevice.Close;
  Assert.IsFalse(FDevice.IsAvailable);
  Assert.IsFalse(FOutput.IsOpen);
  // a closed mixer takes no sound
  FDevice.PlayWave(TWaveMaker.Constant(255, 20));
  Assert.AreEqual(0, FMeter.ActiveChannels);
  // closing twice is harmless
  FDevice.Close;
end;

{ TTestXcomTracks }

function TTestXcomTracks.Buffer(AFrames: Integer): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
end;

procedure TTestXcomTracks.LaTracciaAdlibCaricaESuonaConLaNormalizzazione;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LTrack: IXcomMusicTrack;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LTrack := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(3, 65, 66, 67, 9), 0.76);
  Assert.AreEqual('Adlib', LTrack.Format);
  Assert.IsFalse(LTrack.IsPlaying);
  LTrack.Start(-1);
  Assert.AreEqual(5, Length(LPlayer.Loaded));
  Assert.AreEqual(0.76, Double(LPlayer.PlayVolume), 1e-6);
  Assert.IsTrue(LTrack.IsPlaying);
  LTrack.Stop;
  Assert.AreEqual(1, LPlayer.Stops);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomTracks.LaTracciaAdlibNonRenderizzaSeNonAttiva;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LTrack := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(1), 1);
  LBuffer := Buffer(10);
  LTrack.Render(@LBuffer[0], 40, 1);
  Assert.AreEqual(0, LPlayer.Renders);
end;

procedure TTestXcomTracks.LaTracciaAdlibConVolumeZeroTace;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LTrack := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(1), 1);
  LTrack.Start(-1);
  LBuffer := Buffer(10);
  LTrack.Render(@LBuffer[0], 40, 0);
  Assert.AreEqual(0, LPlayer.Renders);
end;

procedure TTestXcomTracks.LaTracciaAdlibSommaICampioniDelPlayer;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LPlayer.RenderValue := 30000;
  LTrack := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(1), 1);
  LTrack.Start(-1);
  LBuffer := Buffer(4);
  LBuffer[0] := 1000;
  LBuffer[1] := -20000;
  LBuffer[3] := 30000;
  LTrack.Render(@LBuffer[0], 16, 0.5);
  Assert.AreEqual(1, LPlayer.Renders);
  Assert.AreEqual(0.5, Double(LPlayer.LastVolume), 1e-6);
  Assert.AreEqual(31000, Integer(LBuffer[0]));
  Assert.AreEqual(10000, Integer(LBuffer[1]));
  // the sum saturates
  Assert.AreEqual(32767, Integer(LBuffer[3]));
  // a size that is not a whole number of stereo samples
  Assert.WillRaise(
    procedure
    begin
      LTrack.Render(@LBuffer[0], 6, 0.5);
    end, EXcomAudioException);
end;

procedure TTestXcomTracks.LaTracciaAdlibRipartePerMusicAlwaysLoop;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LSettings: TFakeSettings;
  LSettingsRef: IXcomMusicSettings;
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LSettings := TFakeSettings.Create;
  LSettingsRef := LSettings;
  LSettings.LoopOn := True;
  LTrack := TXcomAdlibTrack.Create(LPlayerRef, LSettingsRef, TBytes.Create(1), 1);
  LTrack.Start(-1);
  LPlayer.Playing := False;
  LBuffer := Buffer(4);
  LTrack.Render(@LBuffer[0], 16, 1);
  // AdlibMusic::player plays the song again and returns without sound
  Assert.AreEqual(2, LPlayer.Plays);
  Assert.AreEqual(0, LPlayer.Renders);
end;

procedure TTestXcomTracks.LaTracciaAdlibNonRipartePerSenzaMusicAlwaysLoop;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LTrack := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(1), 1);
  LTrack.Start(-1);
  LPlayer.Playing := False;
  LBuffer := Buffer(4);
  LTrack.Render(@LBuffer[0], 16, 1);
  Assert.AreEqual(1, LPlayer.Plays);
  Assert.AreEqual(1, LPlayer.Renders);
end;

procedure TTestXcomTracks.FermareUnaTracciaAdlibNonAttivaNonFermaIlPlayer;
var
  LPlayer: TFakeAdlibPlayer;
  LPlayerRef: IXcomAdlibPlayer;
  LFirst: IXcomMusicTrack;
  LSecond: IXcomMusicTrack;
begin
  LPlayer := TFakeAdlibPlayer.Create;
  LPlayerRef := LPlayer;
  LFirst := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(1), 1);
  LSecond := TXcomAdlibTrack.Create(LPlayerRef, TFakeSettings.Create, TBytes.Create(2), 1);
  LFirst.Start(-1);
  LFirst.Stop;
  LSecond.Start(-1);
  // the first track went away already: stopping it again must not silence the second
  LFirst.Stop;
  Assert.AreEqual(1, LPlayer.Stops);
  Assert.IsTrue(LSecond.IsPlaying);
end;

procedure TTestXcomTracks.UnaTracciaWavSuonaUnaVoltaEPoiFinisce;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  // 10 frames of 127 * 256
  LTrack := TXcomWavTrack.Create(TWaveMaker.Constant(255, 10), RATE);
  Assert.AreEqual('Wav', LTrack.Format);
  Assert.IsFalse(LTrack.IsPlaying);
  LTrack.Start(0);
  Assert.IsTrue(LTrack.IsPlaying);
  LBuffer := Buffer(30);
  LTrack.Render(@LBuffer[0], 120, 1);
  Assert.AreEqual(127 * 256, Integer(LBuffer[0]));
  Assert.AreEqual(127 * 256, Integer(LBuffer[19]));
  Assert.AreEqual(0, Integer(LBuffer[20]));
  Assert.IsFalse(LTrack.IsPlaying);
  LTrack.Stop;
end;

procedure TTestXcomTracks.UnaTracciaWavInLoopInfinitoNonFinisce;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LTrack := TXcomWavTrack.Create(TWaveMaker.Constant(255, 10), RATE);
  LTrack.Start(-1);
  LBuffer := Buffer(100);
  LTrack.Render(@LBuffer[0], 400, 1);
  Assert.AreEqual(127 * 256, Integer(LBuffer[199]));
  Assert.IsTrue(LTrack.IsPlaying);
  LTrack.Stop;
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomTracks.UnaTracciaWavConLoopTreVolteFinisceDopoTre;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LTrack := TXcomWavTrack.Create(TWaveMaker.Constant(255, 10), RATE);
  LTrack.Start(3);
  LBuffer := Buffer(100);
  LTrack.Render(@LBuffer[0], 400, 1);
  // 3 times 10 frames, then silence
  Assert.AreEqual(127 * 256, Integer(LBuffer[59]));
  Assert.AreEqual(0, Integer(LBuffer[60]));
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomTracks.UnaTracciaWavApplicaIlVolume;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LTrack := TXcomWavTrack.Create(TWaveMaker.Constant(255, 10), RATE);
  LTrack.Start(0);
  LBuffer := Buffer(10);
  LBuffer[0] := 100;
  LTrack.Render(@LBuffer[0], 40, 0.5);
  Assert.AreEqual(100 + 127 * 256 div 2, Integer(LBuffer[0]));
  Assert.AreEqual(127 * 256 div 2, Integer(LBuffer[1]));
end;

procedure TTestXcomTracks.UnaTracciaWavRifiutaUnFileNonPcm;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomWavTrack.Create(TBytes.Create(1, 2, 3), RATE);
    end, EXcomAudioException);
end;

procedure TTestXcomTracks.UnaTracciaWavVuotaNonPartePerNulla;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LTrack := TXcomWavTrack.Create(TWaveMaker.Make(22050, 1, 8, nil), RATE);
  LTrack.Start(-1);
  Assert.IsFalse(LTrack.IsPlaying);
  LBuffer := Buffer(4);
  LTrack.Render(@LBuffer[0], 16, 1);
  Assert.AreEqual(0, Integer(LBuffer[0]));
  Assert.WillRaise(
    procedure
    begin
      LTrack.Render(@LBuffer[0], 6, 1);
    end, EXcomAudioException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomVolume);
  TDUnitX.RegisterTestFixture(TTestXcomWaveDecoder);
  TDUnitX.RegisterTestFixture(TTestXcomMixer);
  TDUnitX.RegisterTestFixture(TTestXcomTracks);

end.
