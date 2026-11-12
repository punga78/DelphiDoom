{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the greed library - the mixer to PCM, its          }
{  adapter on the sound output of the host and the decoder of the songs         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PcmMixer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.GameHost.Audio.Intf,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.PcmMixer;

type
  /// <summary>A song of one constant sample on each side</summary>
  TFakeSongRenderer = class(TInterfacedObject, IGreedSongRenderer)
  public
    Left, Right: SmallInt;
    Frames: Integer;
    procedure Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
  end;

  TFakeSongDecoder = class(TInterfacedObject, IGreedSongDecoder)
  public
    Renderer: TFakeSongRenderer;
    Accept: Boolean;
    Rate: Integer;
    function Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
  end;

  TFakeMixerLog = class(TInterfacedObject, ILog)
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

  /// <summary>An output that asks its source only when the test says so</summary>
  TFakePcmOutput = class(TInterfacedObject, IGameHostPcmOutput)
  public
    HasDevice: Boolean;
    Opened: Boolean;
    Rate: Integer;
    [weak] Source: IGameHostPcmSource;
    Closes: Integer;
    function Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
    procedure Close;
    function IsOpen: Boolean;
    function CompletedBuffers: Integer;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedPcmMixer = class
  strict private
    FDecoder: TFakeSongDecoder;
    FDecoderIntf: IGreedSongDecoder;
    FMixer: TGreedPcmMixer;
    FMixerIntf: IGreedSoundDevice;
    function Render(AFrames: Integer): TArray<SmallInt>;
  public
    /// <summary>A PCM WAV with the samples given (8 bit: 0..255, 16 bit: -32768..32767), interleaved</summary>
    class function Wave(AChannels, ABits, ARate: Integer; const ASamples: array of Integer): TBytes; static;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareSilenzioSeNienteSuona;
    [Test]
    procedure DovrebbeSuonareUnaWavMonoSuiDueLati;
    [Test]
    procedure DovrebbeConvertireGliOttoBitSenzaSegno;
    [Test]
    procedure DovrebbeTenereSeparatiIDueCanaliDiUnaWavStereo;
    [Test]
    procedure DovrebbeRipetereICampioniSeLaWavEPiuLenta;
    [Test]
    procedure DovrebbeFinireLEffettoAllaFineDellaWav;
    [Test]
    procedure DovrebbeAbbassareIlLatoLontanoConIlPan;
    [Test]
    procedure DovrebbeApplicareIlVolume;
    [Test]
    procedure DovrebbeFermareUnEffetto;
    [Test]
    procedure DovrebbeSommareDueEffettiETagliareOltreISediciBit;
    [Test]
    procedure DovrebbeRifiutareByteCheNonSonoUnaWav;
    [Test]
    procedure DovrebbeRifiutareUnaWavCheNonEPcm;
    [Test]
    procedure DovrebbeRifiutareUnaWavConIDatiOltreLaFine;
    [Test]
    procedure DovrebbeNonSuonareSenzaInizializzazione;
    [Test]
    procedure DovrebbeSuonareLaCanzoneConIlSuoVolume;
    [Test]
    procedure DovrebbeFermareLaCanzone;
    [Test]
    procedure DovrebbeSostituireLaCanzoneConLaNuova;
    [Test]
    procedure DovrebbeDareNilSeIlModuloNonERiconosciuto;
    [Test]
    procedure DovrebbeNonAvereMusicaSenzaDecoder;
    [Test]
    procedure DovrebbeContareNelleStatistiche;
    [Test]
    procedure DovrebbeSvuotareTuttoAlloShutdown;
    [Test]
    procedure DovrebbeRifiutareUnaFrequenzaNonValidaEUnLogNil;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedHostAudio = class
  public
    [Test]
    procedure DovrebbeAprireLUscitaAllaFrequenzaDelMixerEDareISuoiCampioni;
    [Test]
    procedure DovrebbeDireFalsoSenzaDispositivo;
    [Test]
    procedure DovrebbeChiudereLUscitaQuandoVieneDistrutto;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedTrackerSongDecoder = class
  public
    /// <summary>A ProTracker module of 4 channels with one pattern, one sample that loops and one note</summary>
    class function Module: TBytes; static;
    [Test]
    procedure DovrebbeSuonareUnModuloProTracker;
    [Test]
    procedure DovrebbeDareNilPerByteCheNonSonoUnModulo;
    [Test]
    procedure DovrebbeSuonareNelMixer;
  end;

implementation

uses
  DelphiDoom.Greed.HostAudio, DelphiDoom.Greed.TrackerSongDecoder;

{ TFakeSongRenderer }

procedure TFakeSongRenderer.Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AFrames - 1 do
  begin
    ASamples[LIndex * 2] := Left;
    ASamples[LIndex * 2 + 1] := Right;
  end;
  Inc(Frames, AFrames);
end;

{ TFakeSongDecoder }

function TFakeSongDecoder.Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
begin
  Rate := ARate;
  if not Accept then
    Exit(nil);
  Renderer := TFakeSongRenderer.Create;
  Renderer.Left := AModule[0] * 100;
  Renderer.Right := -AModule[0] * 100;
  Result := Renderer;
end;

{ TFakeMixerLog }

procedure TFakeMixerLog.Info(const AText: string);
begin
end;

procedure TFakeMixerLog.Warning(const AText: string);
begin
end;

procedure TFakeMixerLog.DevWarning(const AText: string);
begin
end;

procedure TFakeMixerLog.Error(const AText: string);
begin
end;

{ TFakePcmOutput }

function TFakePcmOutput.Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
begin
  if not HasDevice then
    Exit(False);
  Rate := ARate;
  Source := ASource;
  Opened := True;
  Result := True;
end;

procedure TFakePcmOutput.Close;
begin
  Opened := False;
  Source := nil;
  Inc(Closes);
end;

function TFakePcmOutput.IsOpen: Boolean;
begin
  Result := Opened;
end;

function TFakePcmOutput.CompletedBuffers: Integer;
begin
  Result := 7;
end;

{ TTestGreedPcmMixer }

class function TTestGreedPcmMixer.Wave(AChannels, ABits, ARate: Integer; const ASamples: array of Integer): TBytes;
var
  LDataBytes, LIndex, LOffset: Integer;

  procedure Put32(AAt: Integer; AValue: Cardinal);
  begin
    Result[AAt] := Byte(AValue);
    Result[AAt + 1] := Byte(AValue shr 8);
    Result[AAt + 2] := Byte(AValue shr 16);
    Result[AAt + 3] := Byte(AValue shr 24);
  end;

  procedure Put16(AAt: Integer; AValue: Word);
  begin
    Result[AAt] := Byte(AValue);
    Result[AAt + 1] := Byte(AValue shr 8);
  end;

  procedure PutTag(AAt: Integer; const ATag: AnsiString);
  var
    LChar: Integer;
  begin
    for LChar := 1 to 4 do
      Result[AAt + LChar - 1] := Byte(ATag[LChar]);
  end;

begin
  LDataBytes := Length(ASamples) * (ABits div 8);
  // the parser of the engine reads long words and stops two before the end: a chunk of padding follows the data,
  // as the files of the game have other chunks or enough samples
  SetLength(Result, 44 + LDataBytes + 12);
  PutTag(44 + LDataBytes, 'pad ');
  Put32(48 + LDataBytes, 4);
  PutTag(0, 'RIFF');
  Put32(4, 48 + LDataBytes);
  PutTag(8, 'WAVE');
  PutTag(12, 'fmt ');
  Put32(16, 16);
  Put16(20, 1);
  Put16(22, AChannels);
  Put32(24, ARate);
  Put32(28, ARate * AChannels * (ABits div 8));
  Put16(32, AChannels * (ABits div 8));
  Put16(34, ABits);
  PutTag(36, 'data');
  Put32(40, LDataBytes);
  LOffset := 44;
  for LIndex := 0 to High(ASamples) do
    if ABits = 8 then
    begin
      Result[LOffset] := Byte(ASamples[LIndex]);
      Inc(LOffset);
    end
    else
    begin
      Put16(LOffset, Word(SmallInt(ASamples[LIndex])));
      Inc(LOffset, 2);
    end;
end;

procedure TTestGreedPcmMixer.Setup;
begin
  FDecoder := TFakeSongDecoder.Create;
  FDecoderIntf := FDecoder;
  FDecoder.Accept := True;
  FMixer := TGreedPcmMixer.Create(1000, FDecoderIntf, TFakeMixerLog.Create);
  FMixerIntf := FMixer;
  FMixerIntf.Initialize;
end;

procedure TTestGreedPcmMixer.TearDown;
begin
  FMixerIntf := nil;
  FDecoderIntf := nil;
end;

function TTestGreedPcmMixer.Render(AFrames: Integer): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
  FMixer.Render(PByte(@Result[0]), AFrames * 4);
end;

procedure TTestGreedPcmMixer.DovrebbeDareSilenzioSeNienteSuona;
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  SetLength(LSamples, 8);
  for LIndex := 0 to 7 do
    LSamples[LIndex] := 99;
  FMixer.Render(PByte(@LSamples[0]), 16);
  for LIndex := 0 to 7 do
    Assert.AreEqual(0, Integer(LSamples[LIndex]));
  Assert.AreEqual(Int64(4), FMixer.Statistics.FramesRendered);
  Assert.AreEqual(Int64(0), FMixer.Statistics.FramesWithSound);
end;

procedure TTestGreedPcmMixer.DovrebbeSuonareUnaWavMonoSuiDueLati;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsNotNull(FMixerIntf.StartEffect(Wave(1, 16, 1000, [1000, -2000, 3000])));
  LSamples := Render(3);
  Assert.AreEqual(1000, Integer(LSamples[0]));
  Assert.AreEqual(1000, Integer(LSamples[1]));
  Assert.AreEqual(-2000, Integer(LSamples[2]));
  Assert.AreEqual(-2000, Integer(LSamples[3]));
  Assert.AreEqual(3000, Integer(LSamples[4]));
end;

procedure TTestGreedPcmMixer.DovrebbeConvertireGliOttoBitSenzaSegno;
var
  LSamples: TArray<SmallInt>;
begin
  FMixerIntf.StartEffect(Wave(1, 8, 1000, [128, 255, 0, 128]));
  LSamples := Render(3);
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(127 * 256, Integer(LSamples[2]));
  Assert.AreEqual(-128 * 256, Integer(LSamples[4]));
end;

procedure TTestGreedPcmMixer.DovrebbeTenereSeparatiIDueCanaliDiUnaWavStereo;
var
  LSamples: TArray<SmallInt>;
begin
  FMixerIntf.StartEffect(Wave(2, 16, 1000, [100, -100, 200, -200]));
  LSamples := Render(2);
  Assert.AreEqual(100, Integer(LSamples[0]));
  Assert.AreEqual(-100, Integer(LSamples[1]));
  Assert.AreEqual(200, Integer(LSamples[2]));
  Assert.AreEqual(-200, Integer(LSamples[3]));
end;

procedure TTestGreedPcmMixer.DovrebbeRipetereICampioniSeLaWavEPiuLenta;
var
  LSamples: TArray<SmallInt>;
begin
  // a wave at half the rate of the mixer: each of its samples is heard twice
  FMixerIntf.StartEffect(Wave(1, 16, 500, [10, 20]));
  LSamples := Render(5);
  Assert.AreEqual(10, Integer(LSamples[0]));
  Assert.AreEqual(10, Integer(LSamples[2]));
  Assert.AreEqual(20, Integer(LSamples[4]));
  Assert.AreEqual(20, Integer(LSamples[6]));
  Assert.AreEqual(0, Integer(LSamples[8]));
end;

procedure TTestGreedPcmMixer.DovrebbeFinireLEffettoAllaFineDellaWav;
var
  LChannel: IGreedEffectChannel;
begin
  LChannel := FMixerIntf.StartEffect(Wave(1, 16, 1000, [1, 2]));
  Assert.IsTrue(LChannel.IsActive);
  Render(2);
  Assert.IsTrue(LChannel.IsActive, 'the end is seen when the next sample is asked for');
  Render(1);
  Assert.IsFalse(LChannel.IsActive);
  Assert.AreEqual(0, FMixer.Statistics.ActiveEffects);
  Assert.AreEqual(1, FMixer.Statistics.EffectsEnded);
end;

procedure TTestGreedPcmMixer.DovrebbeAbbassareIlLatoLontanoConIlPan;
var
  LChannel: IGreedEffectChannel;
  LSamples: TArray<SmallInt>;
begin
  LChannel := FMixerIntf.StartEffect(Wave(1, 16, 1000, [1000, 1000, 1000]));
  LChannel.SetPan(1);
  LSamples := Render(1);
  Assert.AreEqual(0, Integer(LSamples[0]), 'all to the right: nothing on the left');
  Assert.AreEqual(1000, Integer(LSamples[1]));
  LChannel.SetPan(-0.5);
  LSamples := Render(1);
  Assert.AreEqual(1000, Integer(LSamples[0]));
  Assert.AreEqual(500, Integer(LSamples[1]));
  LChannel.SetPan(-7);
  LSamples := Render(1);
  Assert.AreEqual(1000, Integer(LSamples[0]));
  Assert.AreEqual(0, Integer(LSamples[1]), 'a pan outside -1..1 is the nearest end');
end;

procedure TTestGreedPcmMixer.DovrebbeApplicareIlVolume;
var
  LChannel: IGreedEffectChannel;
  LSamples: TArray<SmallInt>;
begin
  LChannel := FMixerIntf.StartEffect(Wave(1, 16, 1000, [1000, 1000, 1000]));
  LChannel.SetVolume(0.25);
  LSamples := Render(1);
  Assert.AreEqual(250, Integer(LSamples[0]));
  LChannel.SetVolume(0);
  LSamples := Render(1);
  Assert.AreEqual(0, Integer(LSamples[0]));
  LChannel.SetVolume(5);
  LSamples := Render(1);
  Assert.AreEqual(1000, Integer(LSamples[0]));
end;

procedure TTestGreedPcmMixer.DovrebbeFermareUnEffetto;
var
  LChannel: IGreedEffectChannel;
  LSamples: TArray<SmallInt>;
begin
  LChannel := FMixerIntf.StartEffect(Wave(1, 16, 1000, [1000, 1000, 1000]));
  LChannel.Stop;
  Assert.IsFalse(LChannel.IsActive);
  LSamples := Render(1);
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(0, FMixer.Statistics.ActiveEffects);
end;

procedure TTestGreedPcmMixer.DovrebbeSommareDueEffettiETagliareOltreISediciBit;
var
  LSamples: TArray<SmallInt>;
begin
  FMixerIntf.StartEffect(Wave(1, 16, 1000, [100, 30000, -30000]));
  FMixerIntf.StartEffect(Wave(1, 16, 1000, [23, 30000, -30000]));
  LSamples := Render(3);
  Assert.AreEqual(123, Integer(LSamples[0]));
  Assert.AreEqual(32767, Integer(LSamples[2]));
  Assert.AreEqual(-32768, Integer(LSamples[4]));
  Assert.AreEqual(Int64(4), FMixer.Statistics.ClippedSamples);
  Assert.AreEqual(32767, FMixer.Statistics.Peak);
end;

procedure TTestGreedPcmMixer.DovrebbeRifiutareByteCheNonSonoUnaWav;
begin
  Assert.IsNull(FMixerIntf.StartEffect(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)));
  Assert.IsNull(FMixerIntf.StartEffect(nil));
  Assert.AreEqual(1, FMixer.Statistics.EffectsRejected, 'an empty lump is not an effect that was refused');
  Assert.AreEqual(0, FMixer.Statistics.EffectsStarted);
end;

procedure TTestGreedPcmMixer.DovrebbeRifiutareUnaWavCheNonEPcm;
var
  LWave: TBytes;
begin
  LWave := Wave(1, 16, 1000, [1, 2]);
  // the tag of the format: 2 is ADPCM
  LWave[20] := 2;
  Assert.IsNull(FMixerIntf.StartEffect(LWave));
  LWave := Wave(1, 16, 1000, [1, 2]);
  // three channels
  LWave[22] := 3;
  Assert.IsNull(FMixerIntf.StartEffect(LWave));
  LWave := Wave(1, 16, 1000, [1, 2]);
  // 24 bit samples
  LWave[34] := 24;
  Assert.IsNull(FMixerIntf.StartEffect(LWave));
  Assert.AreEqual(3, FMixer.Statistics.EffectsRejected);
end;

procedure TTestGreedPcmMixer.DovrebbeRifiutareUnaWavConIDatiOltreLaFine;
var
  LWave: TBytes;
  LChannel: IGreedEffectChannel;
begin
  LWave := Wave(1, 16, 1000, [1, 2, 3, 4]);
  // the data chunk says more bytes than the file has: the parser cuts it or the mixer refuses, never a read outside
  LWave[40] := 200;
  LChannel := FMixerIntf.StartEffect(LWave);
  Render(300);
  Assert.Pass;
end;

procedure TTestGreedPcmMixer.DovrebbeNonSuonareSenzaInizializzazione;
var
  LMixer: IGreedSoundDevice;
begin
  LMixer := TGreedPcmMixer.Create(1000, FDecoderIntf, TFakeMixerLog.Create);
  Assert.IsNull(LMixer.StartEffect(Wave(1, 16, 1000, [1, 2])));
  Assert.IsNull(LMixer.StartMusic(TBytes.Create(1), 1));
end;

procedure TTestGreedPcmMixer.DovrebbeSuonareLaCanzoneConIlSuoVolume;
var
  LSong: IGreedMusicChannel;
  LSamples: TArray<SmallInt>;
begin
  LSong := FMixerIntf.StartMusic(TBytes.Create(10), 0.5);
  Assert.IsNotNull(LSong);
  Assert.AreEqual(1000, FDecoder.Rate, 'the song is decoded at the rate of the mixer');
  LSamples := Render(2);
  Assert.AreEqual(500, Integer(LSamples[0]));
  Assert.AreEqual(-500, Integer(LSamples[1]));
  LSong.SetVolume(1);
  FMixerIntf.StartEffect(Wave(1, 16, 1000, [7]));
  LSamples := Render(1);
  Assert.AreEqual(1007, Integer(LSamples[0]), 'the effects are added to the song');
  Assert.AreEqual(3, FDecoder.Renderer.Frames);
  Assert.AreEqual(Int64(3), FMixer.Statistics.FramesWithMusic);
end;

procedure TTestGreedPcmMixer.DovrebbeFermareLaCanzone;
var
  LSong: IGreedMusicChannel;
  LSamples: TArray<SmallInt>;
begin
  LSong := FMixerIntf.StartMusic(TBytes.Create(10), 1);
  Assert.IsTrue(FMixer.Statistics.SongPlaying);
  LSong.Stop;
  LSamples := Render(1);
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.IsFalse(FMixer.Statistics.SongPlaying);
end;

procedure TTestGreedPcmMixer.DovrebbeSostituireLaCanzoneConLaNuova;
var
  LSamples: TArray<SmallInt>;
begin
  FMixerIntf.StartMusic(TBytes.Create(10), 1);
  FMixerIntf.StartMusic(TBytes.Create(20), 1);
  LSamples := Render(1);
  Assert.AreEqual(2000, Integer(LSamples[0]));
  Assert.AreEqual(2, FMixer.Statistics.SongsStarted);
end;

procedure TTestGreedPcmMixer.DovrebbeDareNilSeIlModuloNonERiconosciuto;
begin
  FDecoder.Accept := False;
  Assert.IsNull(FMixerIntf.StartMusic(TBytes.Create(10), 1));
  Assert.IsNull(FMixerIntf.StartMusic(nil, 1));
  Assert.AreEqual(1, FMixer.Statistics.SongsRejected);
end;

procedure TTestGreedPcmMixer.DovrebbeNonAvereMusicaSenzaDecoder;
var
  LMixer: IGreedSoundDevice;
begin
  LMixer := TGreedPcmMixer.Create(1000, nil, TFakeMixerLog.Create);
  LMixer.Initialize;
  Assert.IsNull(LMixer.StartMusic(TBytes.Create(10), 1));
  Assert.IsNotNull(LMixer.StartEffect(Wave(1, 16, 1000, [1, 2])));
end;

procedure TTestGreedPcmMixer.DovrebbeContareNelleStatistiche;
var
  LStatistics: TGreedMixerStatistics;
begin
  FMixerIntf.StartEffect(Wave(1, 16, 1000, [500, 0, -700]));
  Render(10);
  LStatistics := FMixer.Statistics;
  Assert.AreEqual(Int64(10), LStatistics.FramesRendered);
  Assert.AreEqual(Int64(2), LStatistics.FramesWithSound);
  Assert.AreEqual(700, LStatistics.Peak);
  Assert.AreEqual(1, LStatistics.EffectsStarted);
  Assert.AreEqual(1, LStatistics.EffectsEnded);
  Assert.AreEqual(Int64(0), LStatistics.ClippedSamples);
  Assert.AreEqual(1000, FMixer.GetRate);
end;

procedure TTestGreedPcmMixer.DovrebbeSvuotareTuttoAlloShutdown;
var
  LSamples: TArray<SmallInt>;
begin
  FMixerIntf.StartEffect(Wave(1, 16, 1000, [500, 500, 500]));
  FMixerIntf.StartMusic(TBytes.Create(10), 1);
  FMixerIntf.Shutdown;
  LSamples := Render(1);
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.IsNull(FMixerIntf.StartEffect(Wave(1, 16, 1000, [500])));
end;

procedure TTestGreedPcmMixer.DovrebbeRifiutareUnaFrequenzaNonValidaEUnLogNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedPcmMixer.Create(0, nil, TFakeMixerLog.Create).Free;
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPcmMixer.Create(1000, nil, nil).Free;
    end, EArgumentNilException);
end;

{ TTestGreedHostAudio }

procedure TTestGreedHostAudio.DovrebbeAprireLUscitaAllaFrequenzaDelMixerEDareISuoiCampioni;
var
  LOutput: TFakePcmOutput;
  LOutputIntf: IGameHostPcmOutput;
  LMixer: TGreedPcmMixer;
  LDevice: IGreedSoundDevice;
  LAudio: TGreedHostAudio;
  LAudioIntf: IGameHostPcmSource;
  LSamples: TArray<SmallInt>;
begin
  LOutput := TFakePcmOutput.Create;
  LOutputIntf := LOutput;
  LOutput.HasDevice := True;
  LMixer := TGreedPcmMixer.Create(22050, nil, TFakeMixerLog.Create);
  LDevice := LMixer;
  LDevice.Initialize;
  LAudio := TGreedHostAudio.Create(LOutputIntf, LMixer);
  LAudioIntf := LAudio;
  Assert.IsTrue(LAudio.Open);
  Assert.IsTrue(LAudio.Open, 'open twice is open');
  Assert.AreEqual(22050, LOutput.Rate);
  Assert.AreEqual(7, LAudio.CompletedBuffers);
  LDevice.StartEffect(TTestGreedPcmMixer.Wave(1, 16, 22050, [321]));
  SetLength(LSamples, 2);
  LOutput.Source.Render(PByte(@LSamples[0]), 4);
  Assert.AreEqual(321, Integer(LSamples[0]));
  LAudio.Close;
  Assert.IsFalse(LOutput.Opened);
end;

procedure TTestGreedHostAudio.DovrebbeDireFalsoSenzaDispositivo;
var
  LOutputIntf: IGameHostPcmOutput;
  LDevice: IGreedPcmRenderer;
  LAudioIntf: IGameHostPcmSource;
  LAudio: TGreedHostAudio;
begin
  LOutputIntf := TFakePcmOutput.Create;
  LDevice := TGreedPcmMixer.Create(22050, nil, TFakeMixerLog.Create);
  LAudio := TGreedHostAudio.Create(LOutputIntf, LDevice);
  LAudioIntf := LAudio;
  Assert.IsFalse(LAudio.Open);
end;

procedure TTestGreedHostAudio.DovrebbeChiudereLUscitaQuandoVieneDistrutto;
var
  LOutput: TFakePcmOutput;
  LOutputIntf: IGameHostPcmOutput;
  LDevice: IGreedPcmRenderer;
  LAudioIntf: IGameHostPcmSource;
begin
  LOutput := TFakePcmOutput.Create;
  LOutputIntf := LOutput;
  LOutput.HasDevice := True;
  LDevice := TGreedPcmMixer.Create(22050, nil, TFakeMixerLog.Create);
  LAudioIntf := TGreedHostAudio.Create(LOutputIntf, LDevice);
  LAudioIntf := nil;
  Assert.AreEqual(1, LOutput.Closes);
end;

procedure TTestGreedHostAudio.DovrebbeVolereLeSueParti;
var
  LOutputIntf: IGameHostPcmOutput;
  LDevice: IGreedPcmRenderer;
begin
  LOutputIntf := TFakePcmOutput.Create;
  LDevice := TGreedPcmMixer.Create(22050, nil, TFakeMixerLog.Create);
  Assert.WillRaise(
    procedure
    begin
      TGreedHostAudio.Create(nil, LDevice).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHostAudio.Create(LOutputIntf, nil).Free;
    end, EArgumentNilException);
end;

{ TTestGreedTrackerSongDecoder }

class function TTestGreedTrackerSongDecoder.Module: TBytes;
const
  HEADER_SIZE = 1084;
  PATTERN_SIZE = 64 * 4 * 4;
  SAMPLE_BYTES = 64;
var
  LIndex: Integer;
begin
  SetLength(Result, HEADER_SIZE + PATTERN_SIZE + SAMPLE_BYTES);
  // the first sample: its length and its loop in words, volume 64
  Result[20 + 22] := 0;
  Result[20 + 23] := SAMPLE_BYTES div 2;
  Result[20 + 25] := 64;
  Result[20 + 26] := 0;
  Result[20 + 27] := 0;
  Result[20 + 28] := 0;
  Result[20 + 29] := SAMPLE_BYTES div 2;
  // one position that plays the pattern 0
  Result[950] := 1;
  Result[951] := 127;
  Result[1080] := Ord('M');
  Result[1081] := Ord('.');
  Result[1082] := Ord('K');
  Result[1083] := Ord('.');
  // the first cell: sample 1, period 428 (C-2)
  Result[HEADER_SIZE] := $01;
  Result[HEADER_SIZE + 1] := $AC;
  Result[HEADER_SIZE + 2] := $10;
  Result[HEADER_SIZE + 3] := $00;
  // a square wave
  for LIndex := 0 to SAMPLE_BYTES - 1 do
    if (LIndex div 8) mod 2 = 0 then
      Result[HEADER_SIZE + PATTERN_SIZE + LIndex] := 100
    else
      Result[HEADER_SIZE + PATTERN_SIZE + LIndex] := Byte(-100);
end;

procedure TTestGreedTrackerSongDecoder.DovrebbeSuonareUnModuloProTracker;
var
  LDecoder: IGreedSongDecoder;
  LSong: IGreedSongRenderer;
  LSamples: TArray<SmallInt>;
  LIndex, LSounding: Integer;
begin
  LDecoder := TGreedTrackerSongDecoder.Create;
  LSong := LDecoder.Open(Module, 22050);
  Assert.IsNotNull(LSong);
  SetLength(LSamples, 2 * 2048);
  LSong.Render(LSamples, 2048);
  LSounding := 0;
  for LIndex := 0 to High(LSamples) do
    if LSamples[LIndex] <> 0 then
      Inc(LSounding);
  Assert.IsTrue(LSounding > 1000, Format('%d samples of 4096 have sound', [LSounding]));
end;

procedure TTestGreedTrackerSongDecoder.DovrebbeDareNilPerByteCheNonSonoUnModulo;
var
  LDecoder: IGreedSongDecoder;
begin
  LDecoder := TGreedTrackerSongDecoder.Create;
  Assert.IsNull(LDecoder.Open(TBytes.Create(1, 2, 3, 4), 22050));
  Assert.IsNull(LDecoder.Open(nil, 22050));
end;

procedure TTestGreedTrackerSongDecoder.DovrebbeSuonareNelMixer;
var
  LMixer: TGreedPcmMixer;
  LDevice: IGreedSoundDevice;
  LSamples: TArray<SmallInt>;
begin
  LMixer := TGreedPcmMixer.Create(22050, TGreedTrackerSongDecoder.Create, TFakeMixerLog.Create);
  LDevice := LMixer;
  LDevice.Initialize;
  Assert.IsNotNull(LDevice.StartMusic(Module, 1));
  SetLength(LSamples, 2 * 2048);
  LMixer.Render(PByte(@LSamples[0]), 2048 * 4);
  Assert.IsTrue(LMixer.Statistics.FramesWithMusic > 500);
  Assert.IsTrue(LMixer.Statistics.Peak > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedPcmMixer);
  TDUnitX.RegisterTestFixture(TTestGreedHostAudio);
  TDUnitX.RegisterTestFixture(TTestGreedTrackerSongDecoder);

end.
