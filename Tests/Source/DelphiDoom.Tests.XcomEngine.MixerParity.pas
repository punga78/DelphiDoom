{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom audio library - the mixer on              }
{  Libs\AudioMix against a copy of the mixer as it was before (issue #228):     }
{  the same calls, the same samples and statistics, byte by byte                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.MixerParity;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>Raw 16 bit stereo samples: the bytes are the samples (the real decoders are not what is tested here)</summary>
  TParitySampleDecoder = class(TInterfacedObject, IXcomSampleDecoder)
  public
    function Accepts(const AData: TBytes): Boolean;
    function TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
  end;

  /// <summary>A track that makes loud samples from a seed</summary>
  TParityTrack = class(TInterfacedObject, IXcomMusicTrack)
  strict private
    FState: Cardinal;
    FPlaying: Boolean;
  public
    constructor Create(ASeed: Cardinal);
    function Format: string;
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

  [TestFixture]
  [Category('xcom')]
  TTestXcomMixerParity = class
  public
    [Test]
    procedure DovrebbeDareGliStessiCampioniEStatisticheDelVecchioMixerSuScenariACasoConSeme;
    [Test]
    procedure DovrebbeNonSuonareSenzaUscita;
  end;

implementation

uses
  DelphiDoom.XcomAudio.Mixer, DelphiDoom.XcomAudio.ManualOutput, DelphiDoom.Tests.XcomEngine.LegacyMixer,
  DelphiDoom.Tests.AudioMix.Support;

{ TParitySampleDecoder }

function TParitySampleDecoder.Accepts(const AData: TBytes): Boolean;
begin
  Result := Length(AData) >= 4;
end;

function TParitySampleDecoder.TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
var
  LCount: Integer;
begin
  Result := Length(AData) >= 4;
  if not Result then
    Exit;
  LCount := (Length(AData) div 4) * 2;
  SetLength(ASamples, LCount);
  Move(AData[0], ASamples[0], LCount * SizeOf(SmallInt));
end;

{ TParityTrack }

constructor TParityTrack.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

function TParityTrack.Format: string;
begin
  Result := 'Parity';
end;

procedure TParityTrack.Start(ALoop: Integer);
begin
  FPlaying := True;
end;

procedure TParityTrack.Stop;
begin
  FPlaying := False;
end;

function TParityTrack.IsPlaying: Boolean;
begin
  Result := FPlaying;
end;

procedure TParityTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ABytes div 2 - 1 do
  begin
    FState := FState * 1664525 + 1013904223;
    ABuffer^ := SmallInt(Trunc(SmallInt((FState shr 8) and $FFFF) * AVolume));
    Inc(ABuffer);
  end;
end;

{ TTestXcomMixerParity }

procedure TTestXcomMixerParity.DovrebbeDareGliStessiCampioniEStatisticheDelVecchioMixerSuScenariACasoConSeme;
var
  LSeed, LStep, LIndex, LChannel, LLoops, LBytes: Integer;
  LRandom: TAudioMixLcg;
  LOldOutput, LNewOutput: TXcomManualPcmOutput;
  LOldOutputIntf, LNewOutputIntf: IXcomPcmOutput;
  LOldMixer, LNewMixer: IXcomAudioDevice;
  LOldChannels, LNewChannels: IXcomChannelMixer;
  LOldSink, LNewSink: IXcomMusicSink;
  LOldMeter, LNewMeter: IXcomMixerMeter;
  LWave: TBytes;
  LOldBytes, LNewBytes: TBytes;
  LOldStats, LNewStats: TXcomMixerStatistics;
  LTrackSeed: Cardinal;
  LAmbient: Double;
  LPaused: Boolean;
begin
  for LSeed := 1 to 40 do
  begin
    LRandom := TAudioMixLcg.Create(LSeed);
    try
      LOldOutput := TXcomManualPcmOutput.Create;
      LOldOutputIntf := LOldOutput;
      LNewOutput := TXcomManualPcmOutput.Create;
      LNewOutputIntf := LNewOutput;
      LOldMixer := TLegacyXcomMixer.Create(LOldOutputIntf, 22050, TParitySampleDecoder.Create);
      LNewMixer := TXcomMixer.Create(LNewOutputIntf, 22050, TParitySampleDecoder.Create);
      LOldChannels := LOldMixer as IXcomChannelMixer;
      LNewChannels := LNewMixer as IXcomChannelMixer;
      LOldSink := LOldMixer as IXcomMusicSink;
      LNewSink := LNewMixer as IXcomMusicSink;
      LOldMeter := LOldMixer as IXcomMixerMeter;
      LNewMeter := LNewMixer as IXcomMixerMeter;
      Assert.IsTrue(LOldMeter.Open);
      Assert.IsTrue(LNewMeter.Open);
      for LStep := 1 to 70 do
      begin
        case LRandom.Next(13) of
          0, 1:
            begin
              SetLength(LWave, LRandom.Between(2, 1500) * 4);
              for LIndex := 0 to High(LWave) do
                LWave[LIndex] := Byte(LRandom.Next(256));
              LOldMixer.PlayWave(LWave);
              LNewMixer.PlayWave(LWave);
            end;
          2, 3:
            begin
              SetLength(LWave, LRandom.Between(2, 1500) * 4);
              for LIndex := 0 to High(LWave) do
                LWave[LIndex] := Byte(LRandom.Next(256));
              LChannel := LRandom.Between(-2, 16);
              LLoops := LRandom.Between(-1, 2);
              Assert.AreEqual(LOldChannels.PlayChannel(LWave, LChannel, LLoops),
                LNewChannels.PlayChannel(LWave, LChannel, LLoops));
            end;
          4:
            begin
              LChannel := LRandom.Between(-1, 16);
              LLoops := LRandom.Between(-400, 400);
              LBytes := LRandom.Between(-20, 300);
              LOldChannels.SetPosition(LChannel, LLoops, LBytes);
              LNewChannels.SetPosition(LChannel, LLoops, LBytes);
            end;
          5:
            begin
              LChannel := LRandom.Between(-1, 15);
              LOldChannels.HaltChannel(LChannel);
              LNewChannels.HaltChannel(LChannel);
            end;
          6:
            begin
              LChannel := LRandom.Between(-1, 15);
              LLoops := LRandom.Between(-10, 140);
              LOldChannels.SetChannelVolume(LChannel, LLoops);
              LNewChannels.SetChannelVolume(LChannel, LLoops);
            end;
          7:
            begin
              LChannel := LRandom.Between(-1, 128);
              LLoops := LRandom.Between(-1, 128);
              LBytes := LRandom.Between(-1, 128);
              LOldMixer.SetVolume(LChannel, LLoops, LBytes);
              LNewMixer.SetVolume(LChannel, LLoops, LBytes);
            end;
          8:
            begin
              LAmbient := LRandom.Between(0, 150) / 100;
              LOldChannels.SetAmbientVolume(LAmbient);
              LNewChannels.SetAmbientVolume(LAmbient);
            end;
          9:
            begin
              LTrackSeed := LRandom.Next(100000);
              LLoops := LRandom.Between(-1, 2);
              LOldSink.PlayTrack(TParityTrack.Create(LTrackSeed), LLoops);
              LNewSink.PlayTrack(TParityTrack.Create(LTrackSeed), LLoops);
            end;
          10:
            begin
              LOldSink.StopTrack;
              LNewSink.StopTrack;
            end;
          11:
            begin
              LPaused := LRandom.Chance(50);
              LOldSink.PauseTrack(LPaused);
              LNewSink.PauseTrack(LPaused);
            end;
        end;
        LBytes := LRandom.Between(1, 400) * 4;
        LOldBytes := LOldOutput.Pump(LBytes);
        LNewBytes := LNewOutput.Pump(LBytes);
        Assert.AreEqual<Integer>(Length(LOldBytes), Length(LNewBytes));
        Assert.IsTrue(CompareMem(@LOldBytes[0], @LNewBytes[0], Length(LOldBytes)),
          Format('campioni, seme %d passo %d', [LSeed, LStep]));
        LOldStats := LOldMeter.Statistics;
        LNewStats := LNewMeter.Statistics;
        Assert.AreEqual<Int64>(LOldStats.RenderedBytes, LNewStats.RenderedBytes);
        Assert.AreEqual<Integer>(LOldStats.Peak, LNewStats.Peak);
        Assert.AreEqual<Integer>(LOldStats.SoundsStarted, LNewStats.SoundsStarted);
        Assert.IsTrue(LOldStats.Rms = LNewStats.Rms, 'RMS');
        Assert.AreEqual<Integer>(LOldMeter.ActiveChannels, LNewMeter.ActiveChannels);
        for LChannel := 0 to 15 do
          Assert.AreEqual(LOldChannels.IsChannelPlaying(LChannel), LNewChannels.IsChannelPlaying(LChannel));
        Assert.AreEqual(LOldChannels.FreeInterfaceChannel, LNewChannels.FreeInterfaceChannel);
      end;
      LOldMixer.Close;
      LNewMixer.Close;
    finally
      LRandom.Free;
    end;
  end;
end;

procedure TTestXcomMixerParity.DovrebbeNonSuonareSenzaUscita;
var
  LOld: IXcomAudioDevice;
  LNew: IXcomAudioDevice;
begin
  LOld := TLegacyXcomMixer.Create(nil, 22050, TParitySampleDecoder.Create);
  LNew := TXcomMixer.Create(nil, 22050, TParitySampleDecoder.Create);
  Assert.AreEqual((LOld as IXcomMixerMeter).Open, (LNew as IXcomMixerMeter).Open);
  Assert.AreEqual(LOld.IsAvailable, LNew.IsAvailable);
end;

end.
