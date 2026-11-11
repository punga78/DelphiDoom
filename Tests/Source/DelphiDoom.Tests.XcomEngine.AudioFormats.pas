{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the formats of the music of the xcom game: MP3, FLAC,   }
{  OGG, MOD and MIDI (GM.CAT and .mid), the order in which the formats are      }
{  tried and the channels of the mixer (files built in memory: no device, no    }
{  file of the original game)                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.AudioFormats;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomAudio.Intf,
  DelphiDoom.XcomAudio.Types, DelphiDoom.XcomAudio.Mixer, DelphiDoom.XcomAudio.ManualOutput,
  DelphiDoom.XcomAudio.Factory, DelphiDoom.XcomAudio.Mp3Decoder, DelphiDoom.XcomAudio.TrackerTrack,
  DelphiDoom.XcomAudio.GmConverter, DelphiDoom.XcomAudio.MidiSynth, DelphiDoom.XcomAudio.MidiTrack,
  DelphiDoom.XcomAudio.DigitalTrack, DelphiDoom.XcomEngine.Types, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.OptionsScreens, DelphiDoom.Tests.XcomEngine.AudioFakes,
  DelphiDoom.Tests.XcomEngine.AudioFiles, DelphiDoom.Tests.Mp3.Samples, DelphiDoom.Tests.Sound.FlacFile,
  DelphiDoom.Tests.Sound.VorbisFile;

type
  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMp3Decoder = class
  strict private
    FDecoder: IXcomSampleDecoder;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure IlRiconoscimentoVedeUnTagId3EUnaSincronizzazione;
    [Test]
    procedure UnFlussoDiFrameSilenziosiDaLaDurataGiusta;
    [Test]
    procedure UnFlussoStereoDiventaStereoAlRateDelMixer;
    [Test]
    procedure UnTagId3PrimaDeiFrameSiSalta;
    [Test]
    procedure DatiCheNonSonoMp3DannoFalso;
    [Test]
    procedure UnFrameDelLayerDueNonSiAccetta;
    [Test]
    procedure SenzaMp3DaEccezione;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomTrackerTrack = class
  strict private
    function Render(const ATrack: IXcomMusicTrack; AFrames: Integer): TArray<SmallInt>;
  public
    [Test]
    procedure UnModuloSiRiconosceEDaRmsNonNullo;
    [Test]
    procedure UnFileQualsiasiNonESuonato;
    [Test]
    procedure UnModuloSenzaLoopFinisce;
    [Test]
    procedure UnModuloInLoopInfinitoNonFinisce;
    [Test]
    procedure UnModuloConLoopDueVolteFinisceDopoDue;
    [Test]
    procedure IlVolumeScalaIlModulo;
    [Test]
    procedure FermareLiberaIlModuloEPuoRipartire;
    [Test]
    procedure UnModuloTroncatoENonSuona;
    [Test]
    procedure UnaRichiestaNonMultiplaDiQuattroDaEccezione;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomGmConverter = class
  public
    [Test]
    procedure UnaVoceDiGmCatDiventaUnFileMidiDiTipoUno;
    [Test]
    procedure IlTempoDelFlussoDiventaUnEventoDiTempo;
    [Test]
    procedure IlVolumeDelleNoteSegueLaPatch;
    [Test]
    procedure IlCanaleDieciHaIlVolumeDellaBatteria;
    [Test]
    procedure LaPatchSettantaSetteDiventaSessantadue;
    [Test]
    procedure UnControllerZeroCambiaIlTempo;
    [Test]
    procedure UnaSottosequenzaSiInserisce;
    [Test]
    procedure UnaSottosequenzaInesistenteDaNil;
    [Test]
    procedure UnFlussoTroncatoDaNil;
    [Test]
    procedure UnFlussoVuotoDaNil;
    [Test]
    procedure UnTempoZeroDaNil;
    [Test]
    procedure UnFlussoConDatiInPiuDaNil;
    [Test]
    procedure IlRiverberoVaATrenta;
    [Test]
    procedure IlFileConvertitoSiLeggeEDaLaStessaDurata;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMidiSynth = class
  strict private
    FSynth: TXcomMidiSynth;
    FRef: IXcomMidiSynth;
    function Render(AFrames: Integer): TArray<SmallInt>;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure SenzaNoteSuonaSilenzio;
    [Test]
    procedure UnaNotaSuonaEPoiSiSpegneAlRilascio;
    [Test]
    procedure UnaNotaConVelocitaZeroEUnNoteOff;
    [Test]
    procedure UnaNotaPiuAltaOscillaPiuVelocemente;
    [Test]
    procedure IlVolumeDelCanaleScalaIlSuono;
    [Test]
    procedure IlPanoramaSpostaIlSuonoAlLatoGiusto;
    [Test]
    procedure IlPitchBendCambiaLaFrequenza;
    [Test]
    procedure TutteLeNoteSpenteTaceSubito;
    [Test]
    procedure TutteLeNoteRilasciateSiSpengonoDaSole;
    [Test]
    procedure LaBatteriaSuonaSulCanaleDieciESiSpegneDaSola;
    [Test]
    procedure OltreLeVociDisponibiliSiRubaLaPiuVecchia;
    [Test]
    procedure IlResetFaTacere;
    [Test]
    procedure IlRenderSommaAlBufferEdECompreso;
    [Test]
    procedure UnaRichiestaNonMultiplaDiQuattroDaEccezione;
    [Test]
    procedure UnRateNonValidoDaEccezione;
    [Test]
    procedure OgniFamigliaDiPatchProduceSuono;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMidiTrack = class
  strict private
    function Render(const ATrack: IXcomMusicTrack; AFrames: Integer): TArray<SmallInt>;
    function NewTrack(const AMidi: TBytes): IXcomMusicTrack;
  public
    [Test]
    procedure UnFileMidiSiRiconoscePerLaIntestazione;
    [Test]
    procedure UnFileMidiSuonaConRmsNonNullo;
    [Test]
    procedure LaDurataIlSecondoPiuLaCodaDiUnSecondo;
    [Test]
    procedure UnTrackInLoopInfinitoRicomincia;
    [Test]
    procedure UnLoopDiDueVolteFinisceDopoDue;
    [Test]
    procedure UnFileIllegibileNonSuona;
    [Test]
    procedure UnFileVuotoNonSuona;
    [Test]
    procedure IlVolumeScalaLaMusica;
    [Test]
    procedure FermareFaTacereIlSintetizzatore;
    [Test]
    procedure IlTempoDelFileDecideLaDurata;
    [Test]
    procedure UnaRichiestaNonMultiplaDiQuattroDaEccezione;
    [Test]
    procedure UnSintetizzatoreNilDaEccezione;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMusicFormats = class
  strict private
    FOptions: TXcomOptions;
    FOutput: TXcomManualPcmOutput;
    FOutputRef: IXcomPcmOutput;
    FResources: TFakeResources;
    FResourcesRef: IXcomResources;
    FDevice: IXcomAudioDevice;
    FMusic: IXcomMusicPlayer;
    function Rule(const AName: string; ACatPos: Integer = MaxInt): TXcomMusicRule;
    procedure Load(const ARules: TArray<TXcomMusicRule>);
    function PlayedRms(const AName: string; ASeconds: Double = 1): Double;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnFileFlacSuonaEHaIlNomeFlac;
    [Test]
    procedure UnFileOggSuonaEHaIlNomeOgg;
    [Test]
    procedure UnFileMp3SiCaricaEHaIlNomeMp3;
    [Test]
    procedure UnFileModSuonaEHaIlNomeMod;
    [Test]
    procedure UnFileMidSuonaEHaIlNomeMidi;
    [Test]
    procedure UnaVoceDiGmCatSuonaConIlFormatoPreferito;
    [Test]
    procedure SenzaAdlibCatIlGmESenzaPreferenzaQuelloCheSuona;
    [Test]
    procedure FlacVinceSuOggESuWav;
    [Test]
    procedure UnFlacRottoRipieganaSulWav;
    [Test]
    procedure UnOggRottoRipieganaSulFormatoDopo;
    [Test]
    procedure IlFormatoPreferitoVaPrimaDelleAltre;
    [Test]
    procedure UnGmCatDanneggiatoNonCarica;
    [Test]
    procedure UnaVoceDiGmCatNonValidaNonSuonaEFermaLaRicerca;
    [Test]
    procedure UnaVoceOltreGmCatNonCarica;
    [Test]
    procedure IlNomeDelFileVaInMinuscolo;
    [Test]
    procedure UnaTracciaDigitaleSiDecodificaSoloAllAvvio;
    [Test]
    procedure ConMuteNonSiCaricaNulla;
    [Test]
    procedure CambiareBranoFermaIlPrecedenteELiberaLeRisorse;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMixerChannels = class
  strict private
    FOutput: TXcomManualPcmOutput;
    FOutputRef: IXcomPcmOutput;
    FDevice: IXcomAudioDevice;
    FChannels: IXcomChannelMixer;
    FMeter: IXcomMixerMeter;
    function SampleAt(const ASamples: TBytes; AIndex: Integer): Integer;
    function Tone: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure PlayChannelMenoUnoUsaIlPrimoCanaleLiberoDaQuattro;
    [Test]
    procedure UnCanaleScelto3SuonaSuQuelCanale;
    [Test]
    procedure UnCanaleOltreIlSedicesimoDaMenoUno;
    [Test]
    procedure SuUnCanaleOccupatoIlNuovoSuonoSostituisceIlVecchio;
    [Test]
    procedure ConLoopMenoUnoSuonaPerSempre;
    [Test]
    procedure ConLoopUnoSuonaDueVolte;
    [Test]
    procedure UnLoopPiuCortoDelBufferSiRipeteNelBuffer;
    [Test]
    procedure HaltChannelFermaIlCanale;
    [Test]
    procedure HaltChannelMenoUnoFermaTutto;
    [Test]
    procedure IlVolumeDelCanaleScalaIlSuono;
    [Test]
    procedure IlVolumeDelCanaleMenoUnoVaATutti;
    [Test]
    procedure SetVolumeImpostaIVolumiDeiCanaliCome;
    [Test]
    procedure IlCanaleDellAmbienteSegueIlVolumeDellAmbiente;
    [Test]
    procedure UnAngoloAdestraTaceLaSinistra;
    [Test]
    procedure UnAngoloASinistraTaceLaDestra;
    [Test]
    procedure DavantiIDueCanaliSonoPari;
    [Test]
    procedure LaDistanzaAbbassaIlSuono;
    [Test]
    procedure UnAngoloNegativoESopraTrecentosessanta;
    [Test]
    procedure LaPosizioneVaSoloAlCanaleIndicato;
    [Test]
    procedure IlCanaleDellInterfacciaLiberoEUnoODue;
    [Test]
    procedure ConDueSuoniDiInterfacciaNonCiSonoCanaliLiberi;
    [Test]
    procedure UnSuonoNonLeggibileDaMenoUno;
    [Test]
    procedure IlSuonoDiPlayWaveNonSegueIlVolumeDelCanale;
    [Test]
    procedure ConIlSilenzioDelloSfondoPlayWaveTace;
    [Test]
    procedure IlSilenzioSiTogliePiuTardi;
    [Test]
    procedure IlRateDelMixerCambiaLaLunghezzaDelSuono;
    [Test]
    procedure UnSuonoVuotoNonOccupaIlCanale;
    [Test]
    procedure ILoopCompletiFinisconoEIlCanaleSiLibera;
    [Test]
    procedure UnMixerSenzaDecodificatoreDaEccezione;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomAudioFocus = class
  strict private
    FWorld: TTestWorld;
    FAudio: TFakeAudio;
    FAudioRef: IXcomAudioDevice;
    procedure Post(AFocus: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ConBackgroundMuteSenzaIlFuocoIVolumiVannoAZero;
    [Test]
    procedure ConBackgroundMuteConIlFuocoTornanoQuelliDelleOpzioni;
    [Test]
    procedure SenzaBackgroundMuteIlFuocoNonCambiaIVolumi;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomAudioRate = class
  public
    [Test]
    procedure ConRateZeroLaFabbricaUsaAudioSampleRateDelleOpzioni;
    [Test]
    procedure ConUnRateEsplicitoLaFabbricaUsaQuello;
    [Test]
    procedure UnRateNonValidoDelleOpzioniDiventa22050;
    [Test]
    procedure IlRateDelleOpzioniArrivaAlBranoDigitale;
  end;

implementation

const
  RATE = 22050;

function RenderTo(const ATrack: IXcomMusicTrack; AFrames: Integer; AVolume: Single): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
  if AFrames > 0 then
  begin
    // the tracks add to the buffer: it starts from silence
    FillChar(Result[0], AFrames * 4, 0);
    ATrack.Render(@Result[0], AFrames * 4, AVolume);
  end;
end;

{ TTestXcomMp3Decoder }

procedure TTestXcomMp3Decoder.Setup;
begin
  FDecoder := TTestDecoders.Mp3;
end;

procedure TTestXcomMp3Decoder.IlRiconoscimentoVedeUnTagId3EUnaSincronizzazione;
begin
  Assert.IsTrue(FDecoder.Accepts(TMp3Samples.SilentFrame(True)));
  Assert.IsTrue(FDecoder.Accepts(TMp3Samples.Id3Tag(20)));
  Assert.IsFalse(FDecoder.Accepts(TEncoding.ASCII.GetBytes('RIFF0000WAVE')));
  Assert.IsFalse(FDecoder.Accepts(TBytes.Create($FF, $E0, 0, 0)));
  Assert.IsFalse(FDecoder.Accepts(TBytes.Create($FF, $FF)));
  Assert.IsFalse(FDecoder.Accepts(nil));
end;

procedure TTestXcomMp3Decoder.UnFlussoDiFrameSilenziosiDaLaDurataGiusta;
var
  LSamples: TArray<SmallInt>;
begin
  // 44100 Hz mono at 22050 Hz: half of 1152 frames for each MPEG frame (the first one gives nothing, as layer III
  // needs the data of the frame before)
  Assert.IsTrue(FDecoder.TryDecode(TMp3Samples.SilentStream(20, True), 22050, LSamples));
  Assert.IsTrue(Length(LSamples) div 2 >= 19 * 576, IntToStr(Length(LSamples) div 2));
  Assert.IsTrue(Length(LSamples) div 2 <= 20 * 576);
  Assert.AreEqual(0.0, TAudioFiles.Rms(LSamples), 1e-9);
end;

procedure TTestXcomMp3Decoder.UnFlussoStereoDiventaStereoAlRateDelMixer;
var
  LSamples: TArray<SmallInt>;
  LStereo: TArray<SmallInt>;
begin
  Assert.IsTrue(FDecoder.TryDecode(TMp3Samples.SilentStream(10, False), 22050, LStereo));
  Assert.IsTrue(FDecoder.TryDecode(TMp3Samples.SilentStream(10, True), 22050, LSamples));
  Assert.AreEqual(Length(LSamples), Length(LStereo));
  // at the rate of the file the frames are 1152 each
  Assert.IsTrue(FDecoder.TryDecode(TMp3Samples.SilentStream(10, True), 44100, LSamples));
  Assert.IsTrue(Length(LSamples) div 2 >= 9 * 1152);
end;

procedure TTestXcomMp3Decoder.UnTagId3PrimaDeiFrameSiSalta;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsTrue(FDecoder.TryDecode(TMp3Samples.Join(TMp3Samples.Id3Tag(40), TMp3Samples.SilentStream(10, True)),
    22050, LSamples));
  Assert.IsTrue(Length(LSamples) > 0);
end;

procedure TTestXcomMp3Decoder.DatiCheNonSonoMp3DannoFalso;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsFalse(FDecoder.TryDecode(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8), 22050, LSamples));
  Assert.AreEqual(0, Length(LSamples));
  Assert.IsFalse(FDecoder.TryDecode(nil, 22050, LSamples));
  Assert.IsFalse(FDecoder.TryDecode(TMp3Samples.SilentStream(2), 0, LSamples));
end;

procedure TTestXcomMp3Decoder.UnFrameDelLayerDueNonSiAccetta;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsFalse(FDecoder.TryDecode(TMp3Samples.Layer2Frame, 22050, LSamples));
end;

procedure TTestXcomMp3Decoder.SenzaMp3DaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomMp3Decoder.Create(nil);
    end, EArgumentNilException);
end;

{ TTestXcomTrackerTrack }

function TTestXcomTrackerTrack.Render(const ATrack: IXcomMusicTrack; AFrames: Integer): TArray<SmallInt>;
begin
  Result := RenderTo(ATrack, AFrames, 1);
end;

procedure TTestXcomTrackerTrack.UnModuloSiRiconosceEDaRmsNonNullo;
var
  LTrack: IXcomMusicTrack;
  LSamples: TArray<SmallInt>;
begin
  Assert.IsTrue(TXcomTrackerTrack.Accepts(TAudioFiles.Mod_));
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  Assert.AreEqual('MOD', LTrack.Format);
  Assert.IsFalse(LTrack.IsPlaying);
  LTrack.Start(-1);
  Assert.IsTrue(LTrack.IsPlaying);
  LSamples := Render(LTrack, RATE div 2);
  Assert.IsTrue(TAudioFiles.Rms(LSamples) > 100, FloatToStr(TAudioFiles.Rms(LSamples)));
end;

procedure TTestXcomTrackerTrack.UnFileQualsiasiNonESuonato;
var
  LTrack: IXcomMusicTrack;
begin
  Assert.IsFalse(TXcomTrackerTrack.Accepts(TBytes.Create(1, 2, 3)));
  Assert.IsFalse(TXcomTrackerTrack.Accepts(TEncoding.ASCII.GetBytes('RIFF0000WAVEfmt ')));
  LTrack := TXcomTrackerTrack.Create(TBytes.Create(1, 2, 3), RATE);
  LTrack.Start(-1);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomTrackerTrack.UnModuloSenzaLoopFinisce;
var
  LTrack: IXcomMusicTrack;
  LSamples: TArray<SmallInt>;
begin
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  LTrack.Start(0);
  // 64 rows of 6 ticks of 20 ms: 7.68 seconds
  LSamples := Render(LTrack, RATE * 6);
  Assert.IsTrue(LTrack.IsPlaying);
  LSamples := Render(LTrack, RATE * 3);
  Assert.IsFalse(LTrack.IsPlaying);
  Assert.AreEqual(0, Integer(LSamples[Length(LSamples) - 1]));
end;

procedure TTestXcomTrackerTrack.UnModuloInLoopInfinitoNonFinisce;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  LTrack.Start(-1);
  Render(LTrack, RATE * 9);
  Assert.IsTrue(LTrack.IsPlaying);
  Render(LTrack, RATE * 9);
  Assert.IsTrue(LTrack.IsPlaying);
end;

procedure TTestXcomTrackerTrack.UnModuloConLoopDueVolteFinisceDopoDue;
var
  LTrack: IXcomMusicTrack;
  LFrames: Integer;
begin
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  LTrack.Start(2);
  // with the buffers of the output (1024 frames): two turns of 7.68 seconds
  LFrames := 0;
  while LTrack.IsPlaying and (LFrames < RATE * 20) do
  begin
    Render(LTrack, 1024);
    Inc(LFrames, 1024);
  end;
  Assert.IsTrue(LFrames > RATE * 15, IntToStr(LFrames));
  Assert.IsTrue(LFrames < RATE * 16, IntToStr(LFrames));
end;

procedure TTestXcomTrackerTrack.IlVolumeScalaIlModulo;
var
  LFull: TArray<SmallInt>;
  LHalf: TArray<SmallInt>;
  LTrack: IXcomMusicTrack;
begin
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  LTrack.Start(-1);
  LFull := RenderTo(LTrack, RATE div 2, 1);
  LTrack.Start(-1);
  LHalf := RenderTo(LTrack, RATE div 2, 0.5);
  Assert.AreEqual(TAudioFiles.Rms(LFull) / 2, TAudioFiles.Rms(LHalf), TAudioFiles.Rms(LFull) * 0.02);
end;

procedure TTestXcomTrackerTrack.FermareLiberaIlModuloEPuoRipartire;
var
  LTrack: IXcomMusicTrack;
  LPreparation: IXcomMusicPreparation;
  LSamples: TArray<SmallInt>;
begin
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  Assert.IsTrue(Supports(LTrack, IXcomMusicPreparation, LPreparation));
  LPreparation.Prepare;
  LTrack.Start(-1);
  LTrack.Stop;
  Assert.IsFalse(LTrack.IsPlaying);
  // a stopped track makes no samples
  LSamples := Render(LTrack, 100);
  Assert.AreEqual(0.0, TAudioFiles.Rms(LSamples), 1e-9);
  LTrack.Start(-1);
  Assert.IsTrue(LTrack.IsPlaying);
  Assert.IsTrue(TAudioFiles.Rms(Render(LTrack, RATE div 2)) > 100);
end;

procedure TTestXcomTrackerTrack.UnModuloTroncatoENonSuona;
var
  LTrack: IXcomMusicTrack;
  LMod: TBytes;
begin
  // the signature is there but the patterns are not
  LMod := Copy(TAudioFiles.Mod_, 0, 1100);
  LTrack := TXcomTrackerTrack.Create(LMod, RATE);
  LTrack.Start(-1);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomTrackerTrack.UnaRichiestaNonMultiplaDiQuattroDaEccezione;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LTrack := TXcomTrackerTrack.Create(TAudioFiles.Mod_, RATE);
  LTrack.Start(-1);
  SetLength(LBuffer, 8);
  Assert.WillRaise(
    procedure
    begin
      LTrack.Render(@LBuffer[0], 6, 1);
    end, EXcomAudioException);
end;

{ TTestXcomGmConverter }

procedure TTestXcomGmConverter.UnaVoceDiGmCatDiventaUnFileMidiDiTipoUno;
var
  LMidi: TBytes;
begin
  LMidi := TXcomGmConverter.Convert(TAudioFiles.GmEntry);
  Assert.IsTrue(Length(LMidi) > 40);
  Assert.AreEqual('MThd', string(TEncoding.ASCII.GetString(Copy(LMidi, 0, 4))));
  // format 1, two tracks (the tempo and the one of the channel), 24 ticks per quarter note
  Assert.AreEqual(1, Integer(LMidi[9]));
  Assert.AreEqual(2, Integer(LMidi[11]));
  Assert.AreEqual(24, Integer(LMidi[13]));
  Assert.AreEqual('MTrk', string(TEncoding.ASCII.GetString(Copy(LMidi, 14, 4))));
end;

procedure TTestXcomGmConverter.IlTempoDelFlussoDiventaUnEventoDiTempo;
var
  LMidi: TBytes;
begin
  LMidi := TXcomGmConverter.Convert(TAudioFiles.GmEntry);
  // the tempo track: delta 0, FF 51 03 and 60000000 / 120 = 500000 = 07 A1 20, delta 0, end of track
  Assert.AreEqual(11, Integer(LMidi[21]));
  Assert.AreEqual($FF, Integer(LMidi[23]));
  Assert.AreEqual($51, Integer(LMidi[24]));
  Assert.AreEqual($07, Integer(LMidi[26]));
  Assert.AreEqual($A1, Integer(LMidi[27]));
  Assert.AreEqual($20, Integer(LMidi[28]));
end;

procedure TTestXcomGmConverter.IlVolumeDelleNoteSegueLaPatch;
var
  LMidi: TBytes;
  LIndex: Integer;
  LFound: Boolean;
begin
  // the patch 18 has volume 85 of 128: the velocity 100 becomes 100 * 85 / 128 = 66
  LMidi := TXcomGmConverter.Convert(TAudioFiles.GmEntry(18));
  LFound := False;
  for LIndex := 0 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $90) and (LMidi[LIndex + 1] = 60) then
    begin
      LFound := True;
      Assert.AreEqual(66, Integer(LMidi[LIndex + 2]));
    end;
  Assert.IsTrue(LFound);
  // the patch 0 has 100: 100 * 100 / 128 = 78
  LMidi := TXcomGmConverter.Convert(TAudioFiles.GmEntry(0));
  for LIndex := 0 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $90) and (LMidi[LIndex + 1] = 60) then
      Assert.AreEqual(78, Integer(LMidi[LIndex + 2]));
end;

procedure TTestXcomGmConverter.IlCanaleDieciHaIlVolumeDellaBatteria;
var
  LEntry: TBytes;
  LMidi: TBytes;
  LIndex: Integer;
  LFound: Boolean;
begin
  // the same song on the channel 9: the velocity 100 becomes 100 * 80 / 128 = 62
  LEntry := TAudioFiles.GmEntry;
  LEntry[3] := 9;
  LMidi := TXcomGmConverter.Convert(LEntry);
  LFound := False;
  for LIndex := 0 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $99) and (LMidi[LIndex + 1] = 60) then
    begin
      LFound := True;
      Assert.AreEqual(62, Integer(LMidi[LIndex + 2]));
    end;
  Assert.IsTrue(LFound);
end;

procedure TTestXcomGmConverter.LaPatchSettantaSetteDiventaSessantadue;
var
  LMidi: TBytes;
  LIndex: Integer;
  LFound: Boolean;
begin
  // the patches 63 ($3F) and 87 ($57) go to 62 ($3E)
  LFound := False;
  LMidi := TXcomGmConverter.Convert(TAudioFiles.GmEntry($57));
  for LIndex := 0 to Length(LMidi) - 2 do
    if LMidi[LIndex] = $C0 then
    begin
      LFound := True;
      Assert.AreEqual($3E, Integer(LMidi[LIndex + 1]));
    end;
  Assert.IsTrue(LFound);
end;

procedure TTestXcomGmConverter.UnControllerZeroCambiaIlTempo;
var
  LEntry: TBytes;
  LMidi: TBytes;
  LIndex: Integer;
  LCount: Integer;
begin
  // a controller 0 with the value 60: the tempo becomes 120 and the controller is not written
  LEntry := TBytes.Create(100, 0, 1, 0, 10, 0, 0, 0, $00, $B0, 0, 60, $00, $FF);
  LMidi := TXcomGmConverter.Convert(LEntry);
  Assert.IsTrue(Length(LMidi) > 0);
  LCount := 0;
  for LIndex := 0 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $FF) and (LMidi[LIndex + 1] = $51) then
      Inc(LCount);
  // the global tempo and the new one
  Assert.AreEqual(2, LCount);
end;

procedure TTestXcomGmConverter.UnaSottosequenzaSiInserisce;
var
  LEntry: TBytes;
  LMidi: TBytes;
  LIndex: Integer;
  LNotes: Integer;
begin
  // one subsequence (a note on and an end of subsequence: 4 + 6 bytes), a track that calls it twice (4 + 8 bytes)
  LEntry := TBytes.Create(120, 1,
    10, 0, 0, 0, $00, $90, 60, 100, $00, $FD,
    1,
    0, 12, 0, 0, 0, $00, $FE, 0, $00, $FE, 0, $00, $FF);
  LMidi := TXcomGmConverter.Convert(LEntry);
  Assert.IsTrue(Length(LMidi) > 0);
  LNotes := 0;
  for LIndex := 0 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $90) and (LMidi[LIndex + 1] = 60) then
      Inc(LNotes);
  Assert.AreEqual(2, LNotes);
end;

procedure TTestXcomGmConverter.UnaSottosequenzaInesistenteDaNil;
var
  LEntry: TBytes;
begin
  LEntry := TBytes.Create(120, 0, 1, 0, 9, 0, 0, 0, $00, $FE, 3, $00, $FF);
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(LEntry)));
end;

procedure TTestXcomGmConverter.UnFlussoTroncatoDaNil;
var
  LEntry: TBytes;
begin
  LEntry := TAudioFiles.GmEntry;
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(Copy(LEntry, 0, Length(LEntry) - 3))));
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(Copy(LEntry, 0, 5))));
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(Copy(LEntry, 0, 2))));
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(Copy(LEntry, 0, 1))));
end;

procedure TTestXcomGmConverter.UnFlussoVuotoDaNil;
begin
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(nil)));
end;

procedure TTestXcomGmConverter.UnTempoZeroDaNil;
var
  LEntry: TBytes;
begin
  LEntry := TAudioFiles.GmEntry;
  LEntry[0] := 0;
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(LEntry)));
end;

procedure TTestXcomGmConverter.UnFlussoConDatiInPiuDaNil;
begin
  Assert.AreEqual(0, Length(TXcomGmConverter.Convert(TAudioFiles.GmEntry + TBytes.Create(1, 2))));
end;

procedure TTestXcomGmConverter.IlRiverberoVaATrenta;
var
  LEntry: TBytes;
  LMidi: TBytes;
  LIndex: Integer;
  LFound: Boolean;
begin
  // controller $5B (reverb) with the value 100 is written with 30
  LEntry := TBytes.Create(120, 0, 1, 0, 10, 0, 0, 0, $00, $B0, $5B, 100, $00, $FF);
  LMidi := TXcomGmConverter.Convert(LEntry);
  LFound := False;
  for LIndex := 0 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $B0) and (LMidi[LIndex + 1] = $5B) then
    begin
      LFound := True;
      Assert.AreEqual(30, Integer(LMidi[LIndex + 2]));
    end;
  Assert.IsTrue(LFound);
end;

procedure TTestXcomGmConverter.IlFileConvertitoSiLeggeEDaLaStessaDurata;
var
  LTrack: IXcomMusicTrack;
  LSamples: TArray<SmallInt>;
begin
  // 96 ticks of 24 per quarter note at 120 per minute are two seconds: two notes of two seconds, then the tail of one
  LTrack := TXcomMidiTrack.Create(TXcomGmConverter.Convert(TAudioFiles.GmEntry), RATE, TXcomMidiSynth.Create(RATE));
  LTrack.Start(0);
  LSamples := RenderTo(LTrack, RATE div 2, 1);
  Assert.IsTrue(TAudioFiles.Rms(LSamples) > 50);
  RenderTo(LTrack, RATE * 4, 1);
  Assert.IsTrue(LTrack.IsPlaying);
  RenderTo(LTrack, RATE, 1);
  Assert.IsFalse(LTrack.IsPlaying);
end;

{ TTestXcomMidiSynth }

procedure TTestXcomMidiSynth.Setup;
begin
  FSynth := TXcomMidiSynth.Create(RATE);
  FRef := FSynth;
end;

function TTestXcomMidiSynth.Render(AFrames: Integer): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
  // the synthesizer adds to the buffer: it starts from silence
  FillChar(Result[0], AFrames * 4, 0);
  FRef.Render(@Result[0], AFrames * 4);
end;

procedure TTestXcomMidiSynth.SenzaNoteSuonaSilenzio;
begin
  Assert.AreEqual(0.0, TAudioFiles.Rms(Render(1000)), 1e-9);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestXcomMidiSynth.UnaNotaSuonaEPoiSiSpegneAlRilascio;
begin
  FRef.Send($90, 60, 100);
  Assert.AreEqual(1, FSynth.ActiveVoices);
  Assert.IsTrue(TAudioFiles.Rms(Render(2000)) > 50);
  FRef.Send($80, 60, 0);
  // the release lasts 0.05 s or more: after half a second the voice is gone
  Render(RATE div 2);
  Assert.AreEqual(0, FSynth.ActiveVoices);
  Assert.AreEqual(0.0, TAudioFiles.Rms(Render(1000)), 1e-9);
end;

procedure TTestXcomMidiSynth.UnaNotaConVelocitaZeroEUnNoteOff;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($90, 60, 0);
  Render(RATE div 2);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestXcomMidiSynth.UnaNotaPiuAltaOscillaPiuVelocemente;
var
  LLow: TArray<SmallInt>;
  LHigh: TArray<SmallInt>;

  function Crossings(const ASamples: TArray<SmallInt>): Integer;
  var
    LIndex: Integer;
  begin
    Result := 0;
    for LIndex := 1 to Length(ASamples) div 2 - 1 do
      if (ASamples[(LIndex - 1) * 2] < 0) <> (ASamples[LIndex * 2] < 0) then
        Inc(Result);
  end;

begin
  // a triangle wave of the piano family: the crossings of zero follow the frequency (110 and 440 Hz)
  FRef.Send($90, 45, 100);
  LLow := Render(RATE);
  FRef.Send($B0, 120, 0);
  FRef.Send($90, 69, 100);
  LHigh := Render(RATE);
  Assert.IsTrue(Crossings(LHigh) > Crossings(LLow) * 3, Format('%d %d', [Crossings(LLow), Crossings(LHigh)]));
end;

procedure TTestXcomMidiSynth.IlVolumeDelCanaleScalaIlSuono;
var
  LFull: Double;
  LHalf: Double;
begin
  FRef.Send($90, 60, 100);
  LFull := TAudioFiles.Rms(Render(2000));
  FRef.Send($B0, 120, 0);
  FRef.Send($B0, 7, 50);
  FRef.Send($90, 60, 100);
  LHalf := TAudioFiles.Rms(Render(2000));
  Assert.IsTrue(LHalf < LFull * 0.7, Format('%f %f', [LFull, LHalf]));
  Assert.IsTrue(LHalf > 0);
  // the expression of the channel counts as well
  FRef.Send($B0, 120, 0);
  FRef.Send($B0, 7, 100);
  FRef.Send($B0, 11, 0);
  FRef.Send($90, 60, 100);
  Assert.AreEqual(0.0, TAudioFiles.Rms(Render(2000)), 1e-9);
end;

procedure TTestXcomMidiSynth.IlPanoramaSpostaIlSuonoAlLatoGiusto;
var
  LSamples: TArray<SmallInt>;
  LLeft: Double;
  LRight: Double;
  LIndex: Integer;
begin
  FRef.Send($B0, 10, 0);
  FRef.Send($90, 60, 100);
  LSamples := Render(2000);
  LLeft := 0;
  LRight := 0;
  for LIndex := 0 to 1999 do
  begin
    LLeft := LLeft + Abs(LSamples[LIndex * 2]);
    LRight := LRight + Abs(LSamples[LIndex * 2 + 1]);
  end;
  Assert.IsTrue(LLeft > 10 * LRight + 1, Format('pan 0: %f %f', [LLeft, LRight]));
  FRef.Send($B0, 120, 0);
  FRef.Send($B0, 10, 127);
  FRef.Send($90, 60, 100);
  LSamples := Render(2000);
  LLeft := 0;
  LRight := 0;
  for LIndex := 0 to 1999 do
  begin
    LLeft := LLeft + Abs(LSamples[LIndex * 2]);
    LRight := LRight + Abs(LSamples[LIndex * 2 + 1]);
  end;
  Assert.IsTrue(LRight > 10 * LLeft + 1, Format('pan 127: %f %f', [LLeft, LRight]));
end;

procedure TTestXcomMidiSynth.IlPitchBendCambiaLaFrequenza;
var
  LPlain: TArray<SmallInt>;
  LBent: TArray<SmallInt>;

  function Crossings(const ASamples: TArray<SmallInt>): Integer;
  var
    LIndex: Integer;
  begin
    Result := 0;
    for LIndex := 1 to Length(ASamples) div 2 - 1 do
      if (ASamples[(LIndex - 1) * 2] < 0) <> (ASamples[LIndex * 2] < 0) then
        Inc(Result);
  end;

begin
  FRef.Send($90, 60, 100);
  LPlain := Render(RATE);
  FRef.Send($B0, 120, 0);
  // the highest bend: two semitones up
  FRef.Send($E0, $7F, $7F);
  FRef.Send($90, 60, 100);
  LBent := Render(RATE);
  Assert.IsTrue(Crossings(LBent) > Crossings(LPlain));
end;

procedure TTestXcomMidiSynth.TutteLeNoteSpenteTaceSubito;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($90, 64, 100);
  FRef.Send($B0, 120, 0);
  Assert.AreEqual(0, FSynth.ActiveVoices);
  Assert.AreEqual(0.0, TAudioFiles.Rms(Render(500)), 1e-9);
end;

procedure TTestXcomMidiSynth.TutteLeNoteRilasciateSiSpengonoDaSole;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($90, 64, 100);
  FRef.Send($B0, 123, 0);
  Assert.AreEqual(2, FSynth.ActiveVoices);
  Render(RATE);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestXcomMidiSynth.LaBatteriaSuonaSulCanaleDieciESiSpegneDaSola;
var
  LSamples: TArray<SmallInt>;
begin
  // a kick (a falling sine), a snare and a hat: noise that dies by itself, a note off does not matter
  FRef.Send($99, 36, 110);
  FRef.Send($99, 38, 110);
  FRef.Send($99, 42, 110);
  LSamples := Render(500);
  Assert.IsTrue(TAudioFiles.Rms(LSamples) > 100);
  FRef.Send($89, 36, 0);
  Render(RATE);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestXcomMidiSynth.OltreLeVociDisponibiliSiRubaLaPiuVecchia;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 39 do
    FRef.Send($90, 40 + LIndex, 100);
  Assert.AreEqual(32, FSynth.ActiveVoices);
  // with released voices the steal takes one of them: the voices that sound stay 32
  FRef.Send($80, 40 + 39, 0);
  FRef.Send($90, 100, 100);
  Assert.AreEqual(32, FSynth.ActiveVoices);
  Assert.IsTrue(TAudioFiles.Rms(Render(500)) > 10);
end;

procedure TTestXcomMidiSynth.IlResetFaTacere;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($B0, 7, 10);
  FRef.Reset;
  Assert.AreEqual(0, FSynth.ActiveVoices);
  // the controllers are back to the start: a new note has the full volume
  FRef.Send($90, 60, 100);
  Assert.IsTrue(TAudioFiles.Rms(Render(2000)) > 50);
end;

procedure TTestXcomMidiSynth.IlRenderSommaAlBufferEdECompreso;
var
  LBuffer: TArray<SmallInt>;
  LIndex: Integer;
begin
  SetLength(LBuffer, 400);
  for LIndex := 0 to 399 do
    LBuffer[LIndex] := 32000;
  FRef.Send($90, 60, 127);
  FRef.Send($90, 64, 127);
  FRef.Send($90, 67, 127);
  FRef.Render(@LBuffer[0], 1600);
  // it adds to what is there and never goes beyond the 16 bits
  for LIndex := 0 to 399 do
    Assert.IsTrue((LBuffer[LIndex] >= -32768) and (LBuffer[LIndex] <= 32767));
  Assert.IsTrue(TAudioFiles.Rms(LBuffer) > 25000);
end;

procedure TTestXcomMidiSynth.UnaRichiestaNonMultiplaDiQuattroDaEccezione;
var
  LBuffer: TArray<SmallInt>;
begin
  SetLength(LBuffer, 8);
  Assert.WillRaise(
    procedure
    begin
      FRef.Render(@LBuffer[0], 6);
    end, EXcomAudioException);
end;

procedure TTestXcomMidiSynth.UnRateNonValidoDaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomMidiSynth.Create(0);
    end, EArgumentOutOfRangeException);
end;

procedure TTestXcomMidiSynth.OgniFamigliaDiPatchProduceSuono;
var
  LFamily: Integer;
begin
  for LFamily := 0 to 15 do
  begin
    FRef.Send($B0, 120, 0);
    FRef.Send($C0, LFamily * 8, 0);
    FRef.Send($90, 60, 100);
    Assert.IsTrue(TAudioFiles.Rms(Render(1000)) > 20, 'family ' + IntToStr(LFamily));
  end;
end;

{ TTestXcomMidiTrack }

function TTestXcomMidiTrack.Render(const ATrack: IXcomMusicTrack; AFrames: Integer): TArray<SmallInt>;
begin
  Result := RenderTo(ATrack, AFrames, 1);
end;

function TTestXcomMidiTrack.NewTrack(const AMidi: TBytes): IXcomMusicTrack;
begin
  Result := TXcomMidiTrack.Create(AMidi, RATE, TXcomMidiSynth.Create(RATE));
end;

procedure TTestXcomMidiTrack.UnFileMidiSiRiconoscePerLaIntestazione;
begin
  Assert.IsTrue(TXcomMidiTrack.Accepts(TAudioFiles.Midi));
  Assert.IsFalse(TXcomMidiTrack.Accepts(TEncoding.ASCII.GetBytes('RIFF0000WAVE0000')));
  Assert.IsFalse(TXcomMidiTrack.Accepts(TEncoding.ASCII.GetBytes('MThd')));
  Assert.AreEqual('MIDI', NewTrack(TAudioFiles.Midi).Format);
end;

procedure TTestXcomMidiTrack.UnFileMidiSuonaConRmsNonNullo;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(0);
  Assert.IsTrue(LTrack.IsPlaying);
  Assert.IsTrue(TAudioFiles.Rms(Render(LTrack, RATE div 4)) > 50);
  // and the second note, a beat later
  Assert.IsTrue(TAudioFiles.Rms(Render(LTrack, RATE div 4 * 3)) > 0);
end;

procedure TTestXcomMidiTrack.LaDurataIlSecondoPiuLaCodaDiUnSecondo;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(0);
  // 120 beats per minute, two beats of notes: one second, then the second of tail
  Render(LTrack, RATE + RATE div 2);
  Assert.IsTrue(LTrack.IsPlaying);
  Render(LTrack, RATE div 2 - 100);
  Assert.IsTrue(LTrack.IsPlaying);
  Render(LTrack, 400);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomMidiTrack.UnTrackInLoopInfinitoRicomincia;
var
  LTrack: IXcomMusicTrack;
  LSamples: TArray<SmallInt>;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(-1);
  Render(LTrack, RATE * 2 + 100);
  Assert.IsTrue(LTrack.IsPlaying);
  // the second turn plays the first note again
  LSamples := Render(LTrack, RATE div 4);
  Assert.IsTrue(TAudioFiles.Rms(LSamples) > 50);
end;

procedure TTestXcomMidiTrack.UnLoopDiDueVolteFinisceDopoDue;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(2);
  Render(LTrack, RATE * 3);
  Assert.IsTrue(LTrack.IsPlaying);
  Render(LTrack, RATE * 2);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomMidiTrack.UnFileIllegibileNonSuona;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := NewTrack(TBytes.Create($4D, $54, $68, $64, 0, 0, 0, 6, 9, 9, 9, 9, 9, 9, 1, 2, 3));
  LTrack.Start(-1);
  Assert.IsFalse(LTrack.IsPlaying);
  Assert.AreEqual(0.0, TAudioFiles.Rms(Render(LTrack, 100)), 1e-9);
end;

procedure TTestXcomMidiTrack.UnFileVuotoNonSuona;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := NewTrack(nil);
  LTrack.Start(-1);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomMidiTrack.IlVolumeScalaLaMusica;
var
  LTrack: IXcomMusicTrack;
  LFull: TArray<SmallInt>;
  LHalf: TArray<SmallInt>;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(0);
  LFull := RenderTo(LTrack, 3000, 1);
  LTrack.Start(0);
  LHalf := RenderTo(LTrack, 3000, 0.5);
  Assert.AreEqual(TAudioFiles.Rms(LFull) / 2, TAudioFiles.Rms(LHalf), TAudioFiles.Rms(LFull) * 0.02);
end;

procedure TTestXcomMidiTrack.FermareFaTacereIlSintetizzatore;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(0);
  Render(LTrack, 1000);
  LTrack.Stop;
  Assert.IsFalse(LTrack.IsPlaying);
  Assert.AreEqual(0.0, TAudioFiles.Rms(Render(LTrack, 1000)), 1e-9);
end;

procedure TTestXcomMidiTrack.IlTempoDelFileDecideLaDurata;
var
  LMidi: TBytes;
  LTrack: IXcomMusicTrack;
begin
  // the same song with a tempo event of 1000000 microseconds per beat (60 per minute): twice as long
  LMidi := TAudioFiles.Midi;
  LMidi := Copy(LMidi, 0, 22) + TBytes.Create($00, $FF, $51, $03, $0F, $42, $40) + Copy(LMidi, 22, Length(LMidi) - 22);
  // the length of the track grows by 7
  LMidi[21] := LMidi[21] + 7;
  LTrack := NewTrack(LMidi);
  LTrack.Start(0);
  // two beats of one second, then the tail: still playing after 2.5 seconds, over after 3.1
  Render(LTrack, RATE * 5 div 2);
  Assert.IsTrue(LTrack.IsPlaying);
  Render(LTrack, RATE * 6 div 10);
  Assert.IsFalse(LTrack.IsPlaying);
end;

procedure TTestXcomMidiTrack.UnaRichiestaNonMultiplaDiQuattroDaEccezione;
var
  LTrack: IXcomMusicTrack;
  LBuffer: TArray<SmallInt>;
begin
  LTrack := NewTrack(TAudioFiles.Midi);
  LTrack.Start(0);
  SetLength(LBuffer, 8);
  Assert.WillRaise(
    procedure
    begin
      LTrack.Render(@LBuffer[0], 6, 1);
    end, EXcomAudioException);
end;

procedure TTestXcomMidiTrack.UnSintetizzatoreNilDaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomMidiTrack.Create(TAudioFiles.Midi, RATE, nil);
    end, EArgumentNilException);
end;

{ TTestXcomMusicFormats }

procedure TTestXcomMusicFormats.Setup;
begin
  FOptions := TXcomOptions.Create;
  FOutput := TXcomManualPcmOutput.Create;
  FOutputRef := FOutput;
  FResources := TFakeResources.Create;
  FResourcesRef := FResources;
  TXcomAudioFactory.CreateAudio(FOptions, FOutputRef, RATE, FDevice, FMusic);
  FDevice.SetVolume(128, 128, 128);
end;

procedure TTestXcomMusicFormats.TearDown;
begin
  if FMusic <> nil then
    FMusic.Stop;
  FMusic := nil;
  if FDevice <> nil then
    FDevice.Close;
  FDevice := nil;
  FOutputRef := nil;
  FOutput := nil;
  FResourcesRef := nil;
  FOptions.Free;
end;

function TTestXcomMusicFormats.Rule(const AName: string; ACatPos: Integer): TXcomMusicRule;
begin
  Result.MusicType := AName;
  Result.Name := AName;
  Result.CatPos := ACatPos;
  Result.Normalization := 0.76;
end;

procedure TTestXcomMusicFormats.Load(const ARules: TArray<TXcomMusicRule>);
begin
  FResources.Rules := ARules;
  FMusic.Reload(FResourcesRef);
end;

function TTestXcomMusicFormats.PlayedRms(const AName: string; ASeconds: Double): Double;
var
  LBytes: TBytes;
  LSamples: TArray<SmallInt>;
begin
  FMusic.PlayMusic(AName, 0);
  Assert.IsTrue(FMusic.IsPlaying, 'plays ' + AName);
  LBytes := FOutput.Pump(Round(RATE * ASeconds) * 4);
  SetLength(LSamples, Length(LBytes) div 2);
  Move(LBytes[0], LSamples[0], Length(LBytes));
  Result := TAudioFiles.Rms(LSamples);
end;

procedure TTestXcomMusicFormats.UnFileFlacSuonaEHaIlNomeFlac;
var
  LOptions: TSoundTestFlacOptions;
begin
  LOptions := TSoundTestFlacOptions.Plain;
  FResources.SoundFiles.Add('song.flac', TSoundTestFlacFile.Build(LOptions,
    [TSoundTestFlacFile.Signal(44100, 16, 1)]));
  Load([Rule('SONG')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  Assert.IsTrue(PlayedRms('SONG') > 1000);
  Assert.AreEqual('FLAC', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnFileOggSuonaEHaIlNomeOgg;
begin
  FResources.SoundFiles.Add('song.ogg', TSoundTestVorbisFile.Build(TSoundTestVorbisOptions.Plain));
  Load([Rule('SONG')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  Assert.IsTrue(PlayedRms('SONG', 0.2) > 0);
  Assert.AreEqual('OGG', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnFileMp3SiCaricaEHaIlNomeMp3;
begin
  FResources.SoundFiles.Add('song.mp3', TMp3Samples.SilentStream(40, False));
  Load([Rule('SONG')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  FMusic.PlayMusic('SONG', 0);
  Assert.IsTrue(FMusic.IsPlaying);
  Assert.AreEqual('MP3', FMusic.CurrentFormat);
  // the music of the game loops: after more than its length (a second) it plays still
  FOutput.Pump(RATE * 3 * 4);
  Assert.IsTrue(FMusic.IsPlaying);
end;

procedure TTestXcomMusicFormats.UnFileModSuonaEHaIlNomeMod;
begin
  FResources.SoundFiles.Add('song.mod', TAudioFiles.Mod_);
  Load([Rule('SONG')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  Assert.IsTrue(PlayedRms('SONG', 0.5) > 100);
  Assert.AreEqual('MOD', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnFileMidSuonaEHaIlNomeMidi;
begin
  FResources.SoundFiles.Add('song.mid', TAudioFiles.Midi);
  Load([Rule('SONG')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  Assert.IsTrue(PlayedRms('SONG', 0.5) > 50);
  Assert.AreEqual('MIDI', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnaVoceDiGmCatSuonaConIlFormatoPreferito;
begin
  // preferredMusic 7: GM
  FOptions.PreferredMusic := 7;
  FResources.SoundFiles.Add('gm.cat', TAudioFiles.Cat([TAudioFiles.GmEntry(0), TAudioFiles.GmEntry(40)]));
  Load([Rule('GMA', 0), Rule('GMB', 1)]);
  Assert.AreEqual(2, FMusic.LoadedCount);
  Assert.IsTrue(PlayedRms('GMB', 0.5) > 50);
  Assert.AreEqual('MIDI', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.SenzaAdlibCatIlGmESenzaPreferenzaQuelloCheSuona;
begin
  // the Adlib comes before GM in the order, but without an ADLIB.CAT the GM is the one that plays
  FResources.SoundFiles.Add('gm.cat', TAudioFiles.Cat([TAudioFiles.GmEntry(0)]));
  Load([Rule('GMA', 0)]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  FMusic.PlayMusic('GMA', 0);
  Assert.AreEqual('MIDI', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.FlacVinceSuOggESuWav;
begin
  FResources.SoundFiles.Add('song.wav', TWaveMaker.Constant(255, 5000));
  FResources.SoundFiles.Add('song.ogg', TSoundTestVorbisFile.Build(TSoundTestVorbisOptions.Plain));
  FResources.SoundFiles.Add('song.flac', TSoundTestFlacFile.Build(TSoundTestFlacOptions.Plain,
    [TSoundTestFlacFile.Signal(4410, 16, 1)]));
  Load([Rule('SONG')]);
  FMusic.PlayMusic('SONG', 0);
  Assert.AreEqual('FLAC', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnFlacRottoRipieganaSulWav;
begin
  FResources.SoundFiles.Add('song.wav', TWaveMaker.Constant(255, 5000));
  FResources.SoundFiles.Add('song.flac', TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8));
  Load([Rule('SONG')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  FMusic.PlayMusic('SONG', 0);
  Assert.AreEqual('WAV', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnOggRottoRipieganaSulFormatoDopo;
begin
  // the .ogg that is a MOD in disguise is not read as OGG (the content is not Ogg): the .mod after it plays
  FResources.SoundFiles.Add('song.ogg', TAudioFiles.Mod_);
  FResources.SoundFiles.Add('song.mod', TAudioFiles.Mod_);
  Load([Rule('SONG')]);
  FMusic.PlayMusic('SONG', 0);
  Assert.AreEqual('MOD', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.IlFormatoPreferitoVaPrimaDelleAltre;
begin
  // 5: WAV before FLAC
  FOptions.PreferredMusic := 5;
  FResources.SoundFiles.Add('song.wav', TWaveMaker.Constant(255, 5000));
  FResources.SoundFiles.Add('song.flac', TSoundTestFlacFile.Build(TSoundTestFlacOptions.Plain,
    [TSoundTestFlacFile.Signal(4410, 16, 1)]));
  Load([Rule('SONG')]);
  FMusic.PlayMusic('SONG', 0);
  Assert.AreEqual('WAV', FMusic.CurrentFormat);
  FOptions.PreferredMusic := 0;
  Load([Rule('SONG')]);
  FMusic.Stop;
  FMusic.PlayMusic('SONG', 0);
  Assert.AreEqual('FLAC', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicFormats.UnGmCatDanneggiatoNonCarica;
begin
  FOptions.PreferredMusic := 7;
  // an index that says there are 100 entries in a file of 12 bytes
  FResources.SoundFiles.Add('gm.cat', TBytes.Create(0, 3, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0));
  Load([Rule('GMA', 0)]);
  Assert.AreEqual(0, FMusic.LoadedCount);
end;

procedure TTestXcomMusicFormats.UnaVoceDiGmCatNonValidaNonSuonaEFermaLaRicerca;
begin
  FResources.SoundFiles.Add('gm.cat', TAudioFiles.Cat([TBytes.Create(1, 2, 3)]));
  // a .mid with the name of the rule comes after GM in the order
  FResources.SoundFiles.Add('gma.mid', TAudioFiles.Midi);
  Load([Rule('GMA', 0)]);
  // GMCatFile::loadMIDI gives a Music even for a stream that is not valid: it is there, it does not play, and the
  // search of formats stops
  Assert.AreEqual(1, FMusic.LoadedCount);
  FMusic.PlayMusic('GMA', 0);
  Assert.IsFalse(FMusic.IsPlaying);
end;

procedure TTestXcomMusicFormats.UnaVoceOltreGmCatNonCarica;
begin
  FResources.SoundFiles.Add('gm.cat', TAudioFiles.Cat([TAudioFiles.GmEntry]));
  Load([Rule('GMA', 1), Rule('GMB', MaxInt), Rule('GMC', -1)]);
  Assert.AreEqual(0, FMusic.LoadedCount);
end;

procedure TTestXcomMusicFormats.IlNomeDelFileVaInMinuscolo;
begin
  FResources.SoundFiles.Add('gmabc.mid', TAudioFiles.Midi);
  Load([Rule('GMABC')]);
  Assert.AreEqual(1, FMusic.LoadedCount);
end;

procedure TTestXcomMusicFormats.UnaTracciaDigitaleSiDecodificaSoloAllAvvio;
var
  LDecoder: TCountingDecoder;
  LDecoderRef: IXcomSampleDecoder;
  LTrack: IXcomMusicTrack;
begin
  LDecoder := TCountingDecoder.Create(TTestDecoders.Sound);
  LDecoderRef := LDecoder;
  LTrack := TXcomDigitalTrack.Create(LDecoderRef, TWaveMaker.Constant(255, 5000), RATE, 'OGG');
  // a track that is made is not decoded until it is going to play
  Assert.AreEqual(0, LDecoder.Decodes);
  (FDevice as IXcomMusicSink).PlayTrack(LTrack, 0);
  Assert.AreEqual(1, LDecoder.Decodes);
  (FDevice as IXcomMusicSink).StopTrack;
end;

procedure TTestXcomMusicFormats.ConMuteNonSiCaricaNulla;
begin
  FOptions.Mute := True;
  FResources.SoundFiles.Add('song.mid', TAudioFiles.Midi);
  Load([Rule('SONG')]);
  Assert.AreEqual(0, FMusic.LoadedCount);
end;

procedure TTestXcomMusicFormats.CambiareBranoFermaIlPrecedenteELiberaLeRisorse;
begin
  FResources.SoundFiles.Add('a.mod', TAudioFiles.Mod_);
  FResources.SoundFiles.Add('b.mid', TAudioFiles.Midi);
  Load([Rule('A'), Rule('B')]);
  FMusic.PlayMusic('A', 0);
  Assert.AreEqual('MOD', FMusic.CurrentFormat);
  FMusic.PlayMusic('B', 0);
  Assert.AreEqual('MIDI', FMusic.CurrentFormat);
  Assert.IsTrue(PlayedRms('B', 0.5) > 50);
  FMusic.Stop;
  Assert.IsFalse(FMusic.IsPlaying);
end;

{ TTestXcomMixerChannels }

procedure TTestXcomMixerChannels.Setup;
begin
  FOutput := TXcomManualPcmOutput.Create;
  FOutputRef := FOutput;
  FDevice := TXcomMixer.Create(FOutputRef, RATE, TTestDecoders.Sound);
  FChannels := FDevice as IXcomChannelMixer;
  FMeter := FDevice as IXcomMixerMeter;
  Assert.IsTrue(FMeter.Open);
end;

procedure TTestXcomMixerChannels.TearDown;
begin
  FChannels := nil;
  FMeter := nil;
  FDevice.Close;
  FDevice := nil;
  FOutputRef := nil;
  FOutput := nil;
end;

function TTestXcomMixerChannels.SampleAt(const ASamples: TBytes; AIndex: Integer): Integer;
begin
  Result := SmallInt(ASamples[AIndex * 2] or (ASamples[AIndex * 2 + 1] shl 8));
end;

function TTestXcomMixerChannels.Tone: TBytes;
begin
  // 100 frames of 127 * 256 (8 bit 255) on both channels
  Result := TWaveMaker.Constant(255, 100);
end;

procedure TTestXcomMixerChannels.PlayChannelMenoUnoUsaIlPrimoCanaleLiberoDaQuattro;
begin
  Assert.AreEqual(4, FChannels.PlayChannel(Tone, -1, 0));
  Assert.AreEqual(5, FChannels.PlayChannel(Tone, -1, 0));
  Assert.IsTrue(FChannels.IsChannelPlaying(4));
  Assert.IsFalse(FChannels.IsChannelPlaying(3));
  Assert.AreEqual(2, FMeter.ActiveChannels);
end;

procedure TTestXcomMixerChannels.UnCanaleScelto3SuonaSuQuelCanale;
begin
  Assert.AreEqual(3, FChannels.PlayChannel(Tone, 3, 0));
  Assert.IsTrue(FChannels.IsChannelPlaying(3));
  Assert.AreEqual(1, FMeter.ActiveChannels);
end;

procedure TTestXcomMixerChannels.UnCanaleOltreIlSedicesimoDaMenoUno;
begin
  Assert.AreEqual(-1, FChannels.PlayChannel(Tone, 16, 0));
  Assert.AreEqual(-1, FChannels.PlayChannel(Tone, -2, 0));
  Assert.AreEqual(0, FMeter.ActiveChannels);
  Assert.IsFalse(FChannels.IsChannelPlaying(16));
  Assert.IsFalse(FChannels.IsChannelPlaying(-1));
end;

procedure TTestXcomMixerChannels.SuUnCanaleOccupatoIlNuovoSuonoSostituisceIlVecchio;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(TWaveMaker.Constant(255, 100), 5, 0);
  FOutput.Pump(40);
  FChannels.PlayChannel(TWaveMaker.Constant(192, 100), 5, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(1, FMeter.ActiveChannels);
  Assert.AreEqual(64 * 256, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.ConLoopMenoUnoSuonaPerSempre;
begin
  FChannels.PlayChannel(Tone, 3, -1);
  FOutput.Pump(100 * 4 * 50);
  Assert.IsTrue(FChannels.IsChannelPlaying(3));
  FChannels.HaltChannel(3);
  Assert.IsFalse(FChannels.IsChannelPlaying(3));
end;

procedure TTestXcomMixerChannels.ConLoopUnoSuonaDueVolte;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(Tone, 3, 1);
  LSamples := FOutput.Pump(400 * 3);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 199));
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 399));
  Assert.AreEqual(0, SampleAt(LSamples, 400));
  Assert.IsFalse(FChannels.IsChannelPlaying(3));
end;

procedure TTestXcomMixerChannels.UnLoopPiuCortoDelBufferSiRipeteNelBuffer;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(TWaveMaker.Constant(255, 3), 3, -1);
  LSamples := FOutput.Pump(4 * 100);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 199));
end;

procedure TTestXcomMixerChannels.HaltChannelFermaIlCanale;
begin
  FChannels.PlayChannel(Tone, 4, 0);
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.HaltChannel(4);
  Assert.IsFalse(FChannels.IsChannelPlaying(4));
  Assert.IsTrue(FChannels.IsChannelPlaying(5));
end;

procedure TTestXcomMixerChannels.HaltChannelMenoUnoFermaTutto;
begin
  FChannels.PlayChannel(Tone, 4, 0);
  FChannels.PlayChannel(Tone, 3, -1);
  FChannels.HaltChannel(-1);
  Assert.AreEqual(0, FMeter.ActiveChannels);
end;

procedure TTestXcomMixerChannels.IlVolumeDelCanaleScalaIlSuono;
var
  LSamples: TBytes;
begin
  FChannels.SetChannelVolume(5, 64);
  FChannels.PlayChannel(Tone, 5, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256 div 2, SampleAt(LSamples, 0));
  FChannels.SetChannelVolume(5, 0);
  FChannels.PlayChannel(Tone, 5, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(0, SampleAt(LSamples, 0));
  // beyond the range it is held to it
  FChannels.SetChannelVolume(5, 1000);
  FChannels.PlayChannel(Tone, 5, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.IlVolumeDelCanaleMenoUnoVaATutti;
var
  LSamples: TBytes;
begin
  FChannels.SetChannelVolume(-1, 32);
  FChannels.PlayChannel(Tone, 4, 0);
  FChannels.PlayChannel(Tone, 9, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256 div 4 * 2, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.SetVolumeImpostaIVolumiDeiCanaliCome;
var
  LSamples: TBytes;
begin
  // Game::setVolume: the sounds 48 of 128 (the curve of 84), the interface 128, the ambience half of the sounds
  FDevice.SetVolume(128, 128, 128);
  FChannels.PlayChannel(Tone, 6, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  FDevice.SetVolume(84, 128, 128);
  FChannels.PlayChannel(Tone, 6, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(Trunc(127 * 256 * 48 / 128), SampleAt(LSamples, 0));
  // the interface channels (1 and 2) take their own volume
  FChannels.HaltChannel(-1);
  FDevice.SetVolume(84, 128, 128);
  FChannels.PlayChannel(Tone, 1, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.IlCanaleDellAmbienteSegueIlVolumeDellAmbiente;
var
  LSamples: TBytes;
begin
  // without a battle the ambience is half of the sounds
  FDevice.SetVolume(128, 128, 128);
  FChannels.PlayChannel(Tone, 3, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256 div 2, SampleAt(LSamples, 0));
  // a battle with the ambience at 0.25
  FChannels.SetAmbientVolume(0.25);
  FDevice.SetVolume(128, 128, 128);
  FChannels.PlayChannel(Tone, 3, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256 div 4, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.UnAngoloAdestraTaceLaSinistra;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 90, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(0, SampleAt(LSamples, 0));
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 1));
end;

procedure TTestXcomMixerChannels.UnAngoloASinistraTaceLaDestra;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 270, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  Assert.AreEqual(0, SampleAt(LSamples, 1));
end;

procedure TTestXcomMixerChannels.DavantiIDueCanaliSonoPari;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 0, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 1));
end;

procedure TTestXcomMixerChannels.LaDistanzaAbbassaIlSuono;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 0, 255);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(0, SampleAt(LSamples, 0));
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 0, 128);
  LSamples := FOutput.Pump(40);
  // (255 - 128) / 255 of the sample
  Assert.AreEqual(Trunc(127 * 256 * (127 / 255)), SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.UnAngoloNegativoESopraTrecentosessanta;
var
  LSamples: TBytes;
begin
  // Map::getSoundAngle gives 360 + x: 440 is 80 degrees to the right
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 440, 0);
  LSamples := FOutput.Pump(40);
  Assert.IsTrue(SampleAt(LSamples, 0) < 127 * 256 div 10);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 1));
  // 280: 80 degrees to the left
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 280, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  Assert.IsTrue(SampleAt(LSamples, 1) < 127 * 256 div 10);
end;

procedure TTestXcomMixerChannels.LaPosizioneVaSoloAlCanaleIndicato;
var
  LSamples: TBytes;
begin
  FChannels.PlayChannel(Tone, 5, 0);
  FChannels.SetPosition(5, 90, 0);
  FChannels.SetPosition(6, 90, 0);
  FChannels.SetPosition(-1, 90, 0);
  FChannels.SetPosition(99, 90, 0);
  FChannels.PlayChannel(Tone, 7, 0);
  LSamples := FOutput.Pump(40);
  // the channel 5 is at the right (0 and 127 * 256), the channel 7 is at the center: the left is 127 * 256 and the
  // right 2 * 127 * 256, that saturates
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
  Assert.AreEqual(32767, SampleAt(LSamples, 1));
end;

procedure TTestXcomMixerChannels.IlCanaleDellInterfacciaLiberoEUnoODue;
begin
  Assert.AreEqual(1, FChannels.FreeInterfaceChannel);
  FChannels.PlayChannel(Tone, 1, 0);
  Assert.AreEqual(2, FChannels.FreeInterfaceChannel);
end;

procedure TTestXcomMixerChannels.ConDueSuoniDiInterfacciaNonCiSonoCanaliLiberi;
begin
  FChannels.PlayChannel(Tone, 1, 0);
  FChannels.PlayChannel(Tone, 2, 0);
  Assert.AreEqual(-1, FChannels.FreeInterfaceChannel);
  // Mix_PlayChannel(-1) then takes any free channel from 4
  Assert.AreEqual(4, FChannels.PlayChannel(Tone, FChannels.FreeInterfaceChannel, 0));
end;

procedure TTestXcomMixerChannels.UnSuonoNonLeggibileDaMenoUno;
begin
  Assert.AreEqual(-1, FChannels.PlayChannel(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13), -1, 0));
  Assert.AreEqual(0, FMeter.ActiveChannels);
end;

procedure TTestXcomMixerChannels.IlSuonoDiPlayWaveNonSegueIlVolumeDelCanale;
var
  LSamples: TBytes;
begin
  // the volume of PlayWave is in the samples (TXcomGame.PlaySound): the channels do not scale it again
  FDevice.SetVolume(10, 128, 10);
  FDevice.PlayWave(Tone);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.ConIlSilenzioDelloSfondoPlayWaveTace;
var
  LSamples: TBytes;
begin
  FDevice.SetVolume(0, 0, 0);
  FDevice.PlayWave(Tone);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(0, SampleAt(LSamples, 0));
  // a sound that plays through the channels is silent as well: its volume is 0
  FChannels.PlayChannel(Tone, 5, 0);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(0, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.IlSilenzioSiTogliePiuTardi;
var
  LSamples: TBytes;
begin
  FDevice.SetVolume(0, 0, 0);
  FDevice.SetVolume(84, 84, 84);
  FDevice.PlayWave(Tone);
  LSamples := FOutput.Pump(40);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 0));
end;

procedure TTestXcomMixerChannels.IlRateDelMixerCambiaLaLunghezzaDelSuono;
var
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LSamples: TBytes;
begin
  // a sound of 22050 Hz of 100 frames on a mixer of 44100 Hz lasts 200 frames: the sample is repeated
  LOutput := TXcomManualPcmOutput.Create;
  LOutputRef := LOutput;
  LDevice := TXcomMixer.Create(LOutputRef, 44100, TTestDecoders.Sound);
  Assert.IsTrue((LDevice as IXcomMixerMeter).Open);
  Assert.AreEqual(44100, LOutput.Rate);
  LDevice.PlayWave(TWaveMaker.Constant(255, 100));
  LSamples := LOutput.Pump(4 * 300);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 399));
  Assert.AreEqual(0, SampleAt(LSamples, 400));
  LDevice.Close;
  // and a mixer of 11025 Hz takes every other sample: 50 frames
  LOutput := TXcomManualPcmOutput.Create;
  LOutputRef := LOutput;
  LDevice := TXcomMixer.Create(LOutputRef, 11025, TTestDecoders.Sound);
  Assert.IsTrue((LDevice as IXcomMixerMeter).Open);
  LDevice.PlayWave(TWaveMaker.Constant(255, 100));
  LSamples := LOutput.Pump(4 * 100);
  Assert.AreEqual(127 * 256, SampleAt(LSamples, 99));
  Assert.AreEqual(0, SampleAt(LSamples, 100));
  LDevice.Close;
end;

procedure TTestXcomMixerChannels.UnSuonoVuotoNonOccupaIlCanale;
begin
  FChannels.PlayChannel(TWaveMaker.Make(22050, 1, 8, nil), 5, -1);
  FOutput.Pump(40);
  Assert.IsFalse(FChannels.IsChannelPlaying(5));
end;

procedure TTestXcomMixerChannels.ILoopCompletiFinisconoEIlCanaleSiLibera;
begin
  FChannels.PlayChannel(TWaveMaker.Constant(255, 10), 5, 2);
  FOutput.Pump(4 * 29);
  Assert.IsTrue(FChannels.IsChannelPlaying(5));
  FOutput.Pump(4 * 5);
  Assert.IsFalse(FChannels.IsChannelPlaying(5));
end;

procedure TTestXcomMixerChannels.UnMixerSenzaDecodificatoreDaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomMixer.Create(nil, RATE, nil);
    end, EArgumentNilException);
end;

{ TTestXcomAudioFocus }

procedure TTestXcomAudioFocus.Setup;
begin
  FWorld := TTestWorld.Create;
  FAudio := TFakeAudio.Create;
  FAudioRef := FAudio;
  FAudio.Sound := -5;
  FWorld.Game.SetAudioDevice(FAudioRef);
  // the frame handles no event without a state
  FWorld.Game.SetState(TMusicState.Create(FWorld.Game));
  FWorld.Game.Options.SoundVolume := 84;
  FWorld.Game.Options.MusicVolume := 60;
  FWorld.Game.Options.UiVolume := 40;
end;

procedure TTestXcomAudioFocus.TearDown;
begin
  FWorld.Free;
  FAudioRef := nil;
end;

procedure TTestXcomAudioFocus.Post(AFocus: Boolean);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekActive);
  LEvent.Key := Ord(AFocus);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(2);
end;

procedure TTestXcomAudioFocus.ConBackgroundMuteSenzaIlFuocoIVolumiVannoAZero;
begin
  FWorld.Game.Options.BackgroundMute := True;
  Post(False);
  Assert.AreEqual(0, FAudio.Sound);
  Assert.AreEqual(0, FAudio.Music);
  Assert.AreEqual(0, FAudio.Ui);
end;

procedure TTestXcomAudioFocus.ConBackgroundMuteConIlFuocoTornanoQuelliDelleOpzioni;
begin
  FWorld.Game.Options.BackgroundMute := True;
  Post(False);
  Post(True);
  Assert.AreEqual(84, FAudio.Sound);
  Assert.AreEqual(60, FAudio.Music);
  Assert.AreEqual(40, FAudio.Ui);
end;

procedure TTestXcomAudioFocus.SenzaBackgroundMuteIlFuocoNonCambiaIVolumi;
begin
  FWorld.Game.Options.BackgroundMute := False;
  Post(False);
  Post(True);
  Assert.AreEqual(-5, FAudio.Sound);
end;

{ TTestXcomAudioRate }

procedure TTestXcomAudioRate.ConRateZeroLaFabbricaUsaAudioSampleRateDelleOpzioni;
var
  LOptions: TXcomOptions;
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.SetValue('audioSampleRate', 44100);
    LOutput := TXcomManualPcmOutput.Create;
    LOutputRef := LOutput;
    TXcomAudioFactory.CreateAudio(LOptions, LOutputRef, 0, LDevice, LMusic);
    Assert.AreEqual(44100, LOutput.Rate);
    LDevice.Close;
  finally
    LMusic := nil;
    LDevice := nil;
    LOptions.Free;
  end;
end;

procedure TTestXcomAudioRate.ConUnRateEsplicitoLaFabbricaUsaQuello;
var
  LOptions: TXcomOptions;
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.SetValue('audioSampleRate', 44100);
    LOutput := TXcomManualPcmOutput.Create;
    LOutputRef := LOutput;
    TXcomAudioFactory.CreateAudio(LOptions, LOutputRef, 11025, LDevice, LMusic);
    Assert.AreEqual(11025, LOutput.Rate);
    LDevice.Close;
  finally
    LMusic := nil;
    LDevice := nil;
    LOptions.Free;
  end;
end;

procedure TTestXcomAudioRate.UnRateNonValidoDelleOpzioniDiventa22050;
var
  LOptions: TXcomOptions;
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.SetValue('audioSampleRate', 0);
    LOutput := TXcomManualPcmOutput.Create;
    LOutputRef := LOutput;
    TXcomAudioFactory.CreateAudio(LOptions, LOutputRef, 0, LDevice, LMusic);
    Assert.AreEqual(XCOM_AUDIO_RATE, LOutput.Rate);
    LDevice.Close;
  finally
    LMusic := nil;
    LDevice := nil;
    LOptions.Free;
  end;
end;

procedure TTestXcomAudioRate.IlRateDelleOpzioniArrivaAlBranoDigitale;
var
  LOptions: TXcomOptions;
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
  LResources: TFakeResources;
  LResourcesRef: IXcomResources;
  LRule: TXcomMusicRule;
  LSamples: TBytes;
begin
  LOptions := TXcomOptions.Create;
  LResources := TFakeResources.Create;
  LResourcesRef := LResources;
  try
    LOptions.SetValue('audioSampleRate', 44100);
    LOutput := TXcomManualPcmOutput.Create;
    LOutputRef := LOutput;
    TXcomAudioFactory.CreateAudio(LOptions, LOutputRef, 0, LDevice, LMusic);
    LRule.MusicType := 'W';
    LRule.Name := 'W';
    LRule.CatPos := MaxInt;
    LRule.Normalization := 0.76;
    LResources.Rules := [LRule];
    // 10 frames of a file of 22050 Hz are 20 frames of the mixer, and the track loops: 80 bytes make one turn
    LResources.SoundFiles.Add('w.wav', TWaveMaker.Constant(255, 10));
    LDevice.SetVolume(128, 128, 128);
    LMusic.Reload(LResourcesRef);
    LMusic.PlayMusic('W', 0);
    LSamples := LOutput.Pump(80);
    Assert.AreEqual(127 * 256, Integer(SmallInt(LSamples[78] or (LSamples[79] shl 8))));
    LMusic.Stop;
    LDevice.Close;
  finally
    LMusic := nil;
    LDevice := nil;
    LResourcesRef := nil;
    LOptions.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomAudioFocus);
  TDUnitX.RegisterTestFixture(TTestXcomAudioRate);
  TDUnitX.RegisterTestFixture(TTestXcomMp3Decoder);
  TDUnitX.RegisterTestFixture(TTestXcomTrackerTrack);
  TDUnitX.RegisterTestFixture(TTestXcomGmConverter);
  TDUnitX.RegisterTestFixture(TTestXcomMidiSynth);
  TDUnitX.RegisterTestFixture(TTestXcomMidiTrack);
  TDUnitX.RegisterTestFixture(TTestXcomMusicFormats);
  TDUnitX.RegisterTestFixture(TTestXcomMixerChannels);

end.
