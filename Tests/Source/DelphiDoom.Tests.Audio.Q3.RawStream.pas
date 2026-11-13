{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of S_RawSamples and of the RoQ sink of the Quake III      }
{  sound                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.RawStream;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Audio.Q3.Rig;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3RawStream = class
  strict private
    FRig: TQ3TestRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCopiareUnoStereoASedociBitScalatoPerIlVolume;
    [Test]
    procedure DovrebbeDuplicareIlMonoASedici;
    [Test]
    procedure DovrebbeLeggereLOttoBitStereoComeCaratteriConSegno;
    [Test]
    procedure DovrebbeLeggereLOttoBitMonoSenzaSegno;
    [Test]
    procedure DovrebbeRipetereICampioniQuandoIlRateEMeta;
    [Test]
    procedure DovrebbeSaltareICampioniQuandoIlRateERaddoppiato;
    [Test]
    procedure DovrebbeScalareIlVolume;
    [Test]
    procedure DovrebbeIgnorareLeChiamateSeIlSuonoNonEAttivo;
    [Test]
    procedure DovrebbeRiportareLaFineAlTempoDelDispositivo;
    [Test]
    procedure DovrebbeGirareNelBufferCircolare;
    [Test]
    procedure DovrebbeIgnorareUnFormatoNonPrevisto;
    [Test]
    procedure DovrebbeRifiutareUnRateNonPositivo;
    [Test]
    procedure DovrebbeLeggereUnArrayDiSedociBit;
    [Test]
    procedure DovrebbeIgnorareUnArrayVuotoOCanaliNonPrevisti;
    [Test]
    procedure DovrebbeDareALMixerIlFlussoSottoGliEffetti;
  end;

  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3RoqSink = class
  strict private
    FRig: TQ3TestRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMandareLAudioDiUnFilmatoAlFlussoGrezzo;
    [Test]
    procedure DovrebbeMandareUnAudioMonoComeFotogrammiSingoli;
    [Test]
    procedure DovrebbeUsareIlVolumeDelSink;
    [Test]
    procedure DovrebbeFunzionareComeSinkDelDecoderDiCinematic;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.RawStream, DelphiDoom.Audio.Q3.RoqSink,
  DelphiDoom.Cinematic.Intf;

{ TTestQ3RawStream }

procedure TTestQ3RawStream.Setup;
begin
  FRig := TQ3TestRig.Create;
end;

procedure TTestQ3RawStream.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3RawStream.DovrebbeCopiareUnoStereoASedociBitScalatoPerIlVolume;
var
  LData: array[0..3] of SmallInt;
begin
  LData[0] := 100;
  LData[1] := -200;
  LData[2] := 300;
  LData[3] := 400;
  FRig.Sound.RawSamples(2, 22050, 2, 2, @LData[0], 1.0);
  Assert.AreEqual(2, FRig.Sound.State.RawEnd);
  Assert.AreEqual(25600, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(-51200, FRig.Sound.State.RawSamples[0].Right);
  Assert.AreEqual(76800, FRig.Sound.State.RawSamples[1].Left);
  Assert.AreEqual(102400, FRig.Sound.State.RawSamples[1].Right);
end;

procedure TTestQ3RawStream.DovrebbeDuplicareIlMonoASedici;
var
  LData: array[0..1] of SmallInt;
begin
  LData[0] := 10;
  LData[1] := -20;
  FRig.Sound.RawSamples(2, 22050, 2, 1, @LData[0], 1.0);
  Assert.AreEqual(2, FRig.Sound.State.RawEnd);
  Assert.AreEqual(2560, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(2560, FRig.Sound.State.RawSamples[0].Right);
  Assert.AreEqual(-5120, FRig.Sound.State.RawSamples[1].Left);
end;

procedure TTestQ3RawStream.DovrebbeLeggereLOttoBitStereoComeCaratteriConSegno;
var
  LData: TBytes;
begin
  // the C reads these bytes as char: $FB is -5, not 251
  LData := TBytes.Create($FB, $07);
  FRig.Sound.RawSamples(1, 22050, 1, 2, PByte(LData), 1.0);
  Assert.AreEqual(-5 * 65536, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(7 * 65536, FRig.Sound.State.RawSamples[0].Right);
end;

procedure TTestQ3RawStream.DovrebbeLeggereLOttoBitMonoSenzaSegno;
var
  LData: TBytes;
begin
  LData := TBytes.Create(128, 200);
  FRig.Sound.RawSamples(2, 22050, 1, 1, PByte(LData), 1.0);
  Assert.AreEqual(0, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(72 * 65536, FRig.Sound.State.RawSamples[1].Right);
end;

procedure TTestQ3RawStream.DovrebbeRipetereICampioniQuandoIlRateEMeta;
var
  LData: array[0..1] of SmallInt;
begin
  LData[0] := 1;
  LData[1] := 2;
  FRig.Sound.RawSamples(2, 11025, 2, 1, @LData[0], 1.0);
  // i * 0.5 < 2: four samples
  Assert.AreEqual(4, FRig.Sound.State.RawEnd);
  Assert.AreEqual(256, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(256, FRig.Sound.State.RawSamples[1].Left);
  Assert.AreEqual(512, FRig.Sound.State.RawSamples[2].Left);
  Assert.AreEqual(512, FRig.Sound.State.RawSamples[3].Left);
end;

procedure TTestQ3RawStream.DovrebbeSaltareICampioniQuandoIlRateERaddoppiato;
var
  LData: array[0..7] of SmallInt;
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    LData[LIndex] := LIndex + 1;
  // stereo at 44100: frames 0 and 2 of the four
  FRig.Sound.RawSamples(4, 44100, 2, 2, @LData[0], 1.0);
  Assert.AreEqual(2, FRig.Sound.State.RawEnd);
  Assert.AreEqual(256, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(5 * 256, FRig.Sound.State.RawSamples[1].Left);
  Assert.AreEqual(6 * 256, FRig.Sound.State.RawSamples[1].Right);
end;

procedure TTestQ3RawStream.DovrebbeScalareIlVolume;
var
  LData: array[0..0] of SmallInt;
begin
  LData[0] := 100;
  FRig.Sound.RawSamples(1, 22050, 2, 1, @LData[0], 0.5);
  Assert.AreEqual(100 * 128, FRig.Sound.State.RawSamples[0].Left);
end;

procedure TTestQ3RawStream.DovrebbeIgnorareLeChiamateSeIlSuonoNonEAttivo;
var
  LData: array[0..0] of SmallInt;
begin
  LData[0] := 100;
  FRig.Sound.DisableSounds;
  FRig.Sound.RawSamples(1, 22050, 2, 1, @LData[0], 1.0);
  Assert.AreEqual(0, FRig.Sound.State.RawEnd);
  FRig.Sound.BeginRegistration;
  FRig.Sound.Shutdown;
  FRig.Sound.RawSamples(1, 22050, 2, 1, @LData[0], 1.0);
  Assert.AreEqual(0, FRig.Sound.State.RawEnd);
end;

procedure TTestQ3RawStream.DovrebbeRiportareLaFineAlTempoDelDispositivo;
var
  LData: array[0..0] of SmallInt;
begin
  LData[0] := 100;
  FRig.Sound.State.SoundTime := 500;
  FRig.Sound.RawSamples(1, 22050, 2, 1, @LData[0], 1.0);
  Assert.AreEqual(501, FRig.Sound.State.RawEnd);
end;

procedure TTestQ3RawStream.DovrebbeGirareNelBufferCircolare;
var
  LData: array[0..3] of SmallInt;
begin
  LData[0] := 1;
  LData[1] := 2;
  LData[2] := 3;
  LData[3] := 4;
  FRig.Sound.State.SoundTime := 16383;
  FRig.Sound.RawSamples(2, 22050, 2, 2, @LData[0], 1.0);
  Assert.AreEqual(16385, FRig.Sound.State.RawEnd);
  Assert.AreEqual(256, FRig.Sound.State.RawSamples[16383].Left);
  Assert.AreEqual(3 * 256, FRig.Sound.State.RawSamples[0].Left);
end;

procedure TTestQ3RawStream.DovrebbeIgnorareUnFormatoNonPrevisto;
var
  LData: TBytes;
begin
  LData := TBytes.Create(1, 2, 3, 4, 5, 6);
  FRig.Sound.RawSamples(2, 22050, 3, 1, PByte(LData), 1.0);
  FRig.Sound.RawSamples(2, 22050, 2, 3, PByte(LData), 1.0);
  Assert.AreEqual(0, FRig.Sound.State.RawEnd);
end;

procedure TTestQ3RawStream.DovrebbeRifiutareUnRateNonPositivo;
var
  LData: array[0..0] of SmallInt;
begin
  LData[0] := 1;
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.RawSamples(1, 0, 2, 1, @LData[0], 1.0);
    end, EQ3SoundException);
end;

procedure TTestQ3RawStream.DovrebbeLeggereUnArrayDiSedociBit;
begin
  FRig.Sound.Raw.RawSamples(TArray<SmallInt>.Create(1, 2, 3, 4), 22050, 2, 1.0);
  Assert.AreEqual(2, FRig.Sound.State.RawEnd);
  Assert.AreEqual(512, FRig.Sound.State.RawSamples[0].Right);
  FRig.Sound.Raw.RawSamples(TArray<SmallInt>.Create(5, 6, 7), 22050, 1, 1.0);
  Assert.AreEqual(5, FRig.Sound.State.RawEnd);
end;

procedure TTestQ3RawStream.DovrebbeIgnorareUnArrayVuotoOCanaliNonPrevisti;
begin
  FRig.Sound.Raw.RawSamples(nil, 22050, 2, 1.0);
  FRig.Sound.Raw.RawSamples(TArray<SmallInt>.Create(1, 2, 3), 22050, 3, 1.0);
  FRig.Sound.Raw.RawSamples(TArray<SmallInt>.Create(1, 2, 3), 22050, 0, 1.0);
  Assert.AreEqual(0, FRig.Sound.State.RawEnd);
end;

procedure TTestQ3RawStream.DovrebbeDareALMixerIlFlussoSottoGliEffetti;
begin
  FRig.Sound.Raw.RawSamples(TArray<SmallInt>.Create(1000, 2000, 3000, 4000), 22050, 2, 1.0);
  FRig.Sound.State.Volume := 1.0;
  FRig.Sound.Mixer.PaintChannels(4);
  Assert.AreEqual(1000, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(2000, Integer(FRig.DeviceSample(1)));
  Assert.AreEqual(3000, Integer(FRig.DeviceSample(2)));
  Assert.AreEqual(4000, Integer(FRig.DeviceSample(3)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(4)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(7)));
end;

{ TTestQ3RoqSink }

procedure TTestQ3RoqSink.Setup;
begin
  FRig := TQ3TestRig.Create;
end;

procedure TTestQ3RoqSink.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3RoqSink.DovrebbeMandareLAudioDiUnFilmatoAlFlussoGrezzo;
var
  LSink: IRoqAudioSink;
begin
  LSink := TQ3RoqAudioSink.Create(FRig.Sound.Raw);
  LSink.AudioReceived(TArray<SmallInt>.Create(100, 200, 300, 400), 2, 22050);
  Assert.AreEqual(2, FRig.Sound.State.RawEnd);
  Assert.AreEqual(25600, FRig.Sound.State.RawSamples[0].Left);
  Assert.AreEqual(51200, FRig.Sound.State.RawSamples[0].Right);
  Assert.AreEqual(102400, FRig.Sound.State.RawSamples[1].Right);
end;

procedure TTestQ3RoqSink.DovrebbeMandareUnAudioMonoComeFotogrammiSingoli;
var
  LSink: IRoqAudioSink;
begin
  LSink := TQ3RoqAudioSink.Create(FRig.Sound.Raw);
  LSink.AudioReceived(TArray<SmallInt>.Create(10, 20), 1, 22050);
  Assert.AreEqual(2, FRig.Sound.State.RawEnd);
  Assert.AreEqual(5120, FRig.Sound.State.RawSamples[1].Left);
end;

procedure TTestQ3RoqSink.DovrebbeUsareIlVolumeDelSink;
var
  LSink: IRoqAudioSink;
begin
  LSink := TQ3RoqAudioSink.Create(FRig.Sound.Raw, 0.5);
  LSink.AudioReceived(TArray<SmallInt>.Create(100), 1, 22050);
  Assert.AreEqual(12800, FRig.Sound.State.RawSamples[0].Left);
end;

procedure TTestQ3RoqSink.DovrebbeFunzionareComeSinkDelDecoderDiCinematic;
var
  LSink: IRoqAudioSink;
begin
  // the decoder gives a mono chunk as two equal channels, at the rate of the file
  LSink := TQ3RoqAudioSink.Create(FRig.Sound.Raw);
  LSink.AudioReceived(TArray<SmallInt>.Create(7, 7, 9, 9), 2, 11025);
  // 11025 on 22050: every frame twice
  Assert.AreEqual(4, FRig.Sound.State.RawEnd);
  Assert.AreEqual(7 * 256, FRig.Sound.State.RawSamples[1].Right);
  Assert.AreEqual(9 * 256, FRig.Sound.State.RawSamples[3].Left);
end;

end.
