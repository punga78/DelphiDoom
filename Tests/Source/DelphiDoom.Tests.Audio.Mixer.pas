{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the software mixer and its voices   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Mixer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.Types, DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.Mixer.Intf, DelphiDoom.Audio.Mixer;

type
  [TestFixture]
  [Category('audio')]
  TTestAudioMixer = class(TObject)
  strict private
    const
      RATE = 1000;
    var
      FMixer: TSfxMixer;
      FMixerIntf: ISfxMixer;
      FBytes: TBytes;
    function MakeSample(const ASamples: array of SmallInt; AChannels, ARate: Integer): TSfxSample;
    function MakeSample8(const ASamples: array of Byte): TSfxSample;
    function MakeVoice(const ASample: TSfxSample): IAudioVoice;
    function Render(AFrames: Integer): TArray<SmallInt>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnFormatoNonPcm;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiCanaliNonSupportato;
    [Test]
    procedure DovrebbeDareSilenzioSenzaVoci;
    [Test]
    procedure DovrebbeSuonareUnaVoceMonoSuEntrambiICanali;
    [Test]
    procedure DovrebbeLeggereGliOttoBitComeSenzaSegno;
    [Test]
    procedure DovrebbeLeggereUnaVoceStereo;
    [Test]
    procedure DovrebbeSilenziareIlLatoLontanoDalPan;
    [Test]
    procedure DovrebbeSilenziareConIlVolumeMinimo;
    [Test]
    procedure DovrebbeInterpolareQuandoIlRateDelSuonoENellaMeta;
    [Test]
    procedure DovrebbeSommareDueVociTagliandoUnaVoltaSola;
    [Test]
    procedure DovrebbeEssereInRiproduzioneFinoAllaFineDelSuono;
    [Test]
    procedure DovrebbeFermareUnaVoce;
    [Test]
    procedure DovrebbeRipartireDalPrimoCampione;
    [Test]
    procedure DovrebbeRiprodurreUnaVoceGiaFinita;
    [Test]
    procedure DovrebbeNonSuonareDueVolteLaStessaVoceSePremutaSubito;
    [Test]
    procedure DovrebbeTenereIlConteggioDelleVociAttive;
    [Test]
    procedure DovrebbeFermareTutteLeVociConClear;
    [Test]
    procedure DovrebbeIgnorareUnaVoceDopoLaFineDelMixer;
    [Test]
    procedure DovrebbeRifiutareUnRateDelMixerNonValido;
  end;

implementation

{ TTestAudioMixer }

procedure TTestAudioMixer.Setup;
begin
  FMixer := TSfxMixer.Create(RATE);
  FMixerIntf := FMixer;
end;

procedure TTestAudioMixer.TearDown;
begin
  FMixerIntf := nil;
  FMixer := nil;
end;

function TTestAudioMixer.MakeSample(const ASamples: array of SmallInt; AChannels, ARate: Integer): TSfxSample;
var
  LIndex: Integer;
begin
  SetLength(FBytes, Length(ASamples) * 2);
  for LIndex := 0 to High(ASamples) do
  begin
    FBytes[LIndex * 2] := Byte(ASamples[LIndex] and $FF);
    FBytes[LIndex * 2 + 1] := Byte((ASamples[LIndex] shr 8) and $FF);
  end;
  Result.Format.Tag := 1;
  Result.Format.Channels := AChannels;
  Result.Format.SamplesPerSecond := ARate;
  Result.Format.AverageBytesPerSecond := ARate * AChannels * 2;
  Result.Format.BitsPerSample := 16;
  Result.Data := @FBytes[0];
  Result.Offset := 0;
  Result.Length := Length(FBytes);
  Result.IsExternal := False;
end;

function TTestAudioMixer.MakeSample8(const ASamples: array of Byte): TSfxSample;
var
  LIndex: Integer;
begin
  SetLength(FBytes, Length(ASamples));
  for LIndex := 0 to High(ASamples) do
    FBytes[LIndex] := ASamples[LIndex];
  Result.Format.Tag := 1;
  Result.Format.Channels := 1;
  Result.Format.SamplesPerSecond := RATE;
  Result.Format.AverageBytesPerSecond := RATE;
  Result.Format.BitsPerSample := 8;
  Result.Data := @FBytes[0];
  Result.Offset := 0;
  Result.Length := Length(FBytes);
  Result.IsExternal := False;
end;

function TTestAudioMixer.MakeVoice(const ASample: TSfxSample): IAudioVoice;
begin
  Assert.AreEqual<Integer>(0, FMixerIntf.CreateVoice(ASample, Result));
  Assert.AreEqual<Integer>(0, Result.Load(ASample));
end;

function TTestAudioMixer.Render(AFrames: Integer): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
  FillChar(Result[0], Length(Result) * 2, $55);
  FMixerIntf.Render(PByte(@Result[0]), AFrames * 4);
end;

procedure TTestAudioMixer.DovrebbeRifiutareUnFormatoNonPcm;
var
  LSample: TSfxSample;
  LVoice: IAudioVoice;
begin
  LSample := MakeSample([1, 2], 1, RATE);
  LSample.Format.Tag := 3;
  Assert.AreEqual<Integer>(SFX_MIXER_BAD_FORMAT, FMixerIntf.CreateVoice(LSample, LVoice));
  Assert.IsNull(LVoice);
end;

procedure TTestAudioMixer.DovrebbeRifiutareUnNumeroDiCanaliNonSupportato;
var
  LSample: TSfxSample;
  LVoice: IAudioVoice;
begin
  LSample := MakeSample([1, 2, 3], 3, RATE);
  Assert.AreEqual<Integer>(SFX_MIXER_BAD_FORMAT, FMixerIntf.CreateVoice(LSample, LVoice));
end;

procedure TTestAudioMixer.DovrebbeDareSilenzioSenzaVoci;
var
  LOutput: TArray<SmallInt>;
  LIndex: Integer;
begin
  LOutput := Render(8);
  for LIndex := 0 to High(LOutput) do
    Assert.AreEqual<Integer>(0, LOutput[LIndex]);
end;

procedure TTestAudioMixer.DovrebbeSuonareUnaVoceMonoSuEntrambiICanali;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([1000, -2000, 3000], 1, RATE));
  LVoice.Play;
  LOutput := Render(4);
  Assert.AreEqual<Integer>(1000, LOutput[0]);
  Assert.AreEqual<Integer>(1000, LOutput[1]);
  Assert.AreEqual<Integer>(-2000, LOutput[2]);
  Assert.AreEqual<Integer>(-2000, LOutput[3]);
  Assert.AreEqual<Integer>(3000, LOutput[4]);
  Assert.AreEqual<Integer>(3000, LOutput[5]);
  Assert.AreEqual<Integer>(0, LOutput[6]);
  Assert.AreEqual<Integer>(0, LOutput[7]);
end;

procedure TTestAudioMixer.DovrebbeLeggereGliOttoBitComeSenzaSegno;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample8([128, 255, 0]));
  LVoice.Play;
  LOutput := Render(3);
  Assert.AreEqual<Integer>(0, LOutput[0]);
  Assert.AreEqual<Integer>(127 * 256, LOutput[2]);
  Assert.AreEqual<Integer>(-32768, LOutput[4]);
end;

procedure TTestAudioMixer.DovrebbeLeggereUnaVoceStereo;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([100, 200, 300, 400], 2, RATE));
  LVoice.Play;
  LOutput := Render(2);
  Assert.AreEqual<Integer>(100, LOutput[0]);
  Assert.AreEqual<Integer>(200, LOutput[1]);
  Assert.AreEqual<Integer>(300, LOutput[2]);
  Assert.AreEqual<Integer>(400, LOutput[3]);
end;

procedure TTestAudioMixer.DovrebbeSilenziareIlLatoLontanoDalPan;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([1000, 1000], 1, RATE));
  LVoice.SetPan(AUDIO_PAN_RIGHT);
  LVoice.Play;
  LOutput := Render(2);
  Assert.AreEqual<Integer>(0, LOutput[0]);
  Assert.AreEqual<Integer>(1000, LOutput[1]);
end;

procedure TTestAudioMixer.DovrebbeSilenziareConIlVolumeMinimo;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([1000, 1000], 1, RATE));
  LVoice.SetVolume(AUDIO_VOLUME_MIN);
  LVoice.Play;
  LOutput := Render(2);
  Assert.AreEqual<Integer>(0, LOutput[0]);
  Assert.AreEqual<Integer>(0, LOutput[1]);
end;

procedure TTestAudioMixer.DovrebbeInterpolareQuandoIlRateDelSuonoENellaMeta;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([0, 1000], 1, RATE div 2));
  LVoice.Play;
  LOutput := Render(5);
  Assert.AreEqual<Integer>(0, LOutput[0]);
  Assert.AreEqual<Integer>(500, LOutput[2]);
  Assert.AreEqual<Integer>(1000, LOutput[4]);
  Assert.AreEqual<Integer>(1000, LOutput[6]);
  Assert.AreEqual<Integer>(0, LOutput[8]);
end;

procedure TTestAudioMixer.DovrebbeSommareDueVociTagliandoUnaVoltaSola;
var
  LFirst: IAudioVoice;
  LSecond: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LFirst := MakeVoice(MakeSample([30000, -30000], 1, RATE));
  LSecond := MakeVoice(MakeSample([30000, -30000], 1, RATE));
  LFirst.Play;
  LSecond.Play;
  LOutput := Render(2);
  Assert.AreEqual<Integer>(32767, LOutput[0]);
  Assert.AreEqual<Integer>(-32768, LOutput[2]);
end;

procedure TTestAudioMixer.DovrebbeEssereInRiproduzioneFinoAllaFineDelSuono;
var
  LVoice: IAudioVoice;
begin
  LVoice := MakeVoice(MakeSample([1, 2, 3, 4], 1, RATE));
  Assert.IsFalse(LVoice.IsPlaying);
  LVoice.Play;
  Assert.IsTrue(LVoice.IsPlaying);
  Render(2);
  Assert.IsTrue(LVoice.IsPlaying);
  Render(4);
  Assert.IsFalse(LVoice.IsPlaying);
end;

procedure TTestAudioMixer.DovrebbeFermareUnaVoce;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([1000, 1000], 1, RATE));
  LVoice.Play;
  LVoice.Stop;
  Assert.IsFalse(LVoice.IsPlaying);
  LOutput := Render(2);
  Assert.AreEqual<Integer>(0, LOutput[0]);
end;

procedure TTestAudioMixer.DovrebbeRipartireDalPrimoCampione;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([10, 20, 30], 1, RATE));
  LVoice.Play;
  Render(2);
  LVoice.Stop;
  LVoice.Rewind;
  LVoice.Play;
  LOutput := Render(1);
  Assert.AreEqual<Integer>(10, LOutput[0]);
end;

procedure TTestAudioMixer.DovrebbeRiprodurreUnaVoceGiaFinita;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([10, 20], 1, RATE));
  LVoice.Play;
  Render(4);
  LVoice.Play;
  LOutput := Render(2);
  Assert.AreEqual<Integer>(10, LOutput[0]);
  Assert.AreEqual<Integer>(20, LOutput[2]);
end;

procedure TTestAudioMixer.DovrebbeNonSuonareDueVolteLaStessaVoceSePremutaSubito;
var
  LVoice: IAudioVoice;
  LOutput: TArray<SmallInt>;
begin
  LVoice := MakeVoice(MakeSample([100, 100], 1, RATE));
  LVoice.Play;
  LVoice.Play;
  Assert.AreEqual<Integer>(1, FMixer.ActiveVoiceCount);
  LOutput := Render(1);
  Assert.AreEqual<Integer>(100, LOutput[0]);
end;

procedure TTestAudioMixer.DovrebbeTenereIlConteggioDelleVociAttive;
var
  LFirst: IAudioVoice;
  LSecond: IAudioVoice;
begin
  LFirst := MakeVoice(MakeSample([1, 2, 3], 1, RATE));
  LSecond := MakeVoice(MakeSample([1, 2], 1, RATE));
  LFirst.Play;
  LSecond.Play;
  Assert.AreEqual<Integer>(2, FMixer.ActiveVoiceCount);
  Render(2);
  Assert.AreEqual<Integer>(2, FMixer.ActiveVoiceCount);
  Render(1);
  Assert.AreEqual<Integer>(1, FMixer.ActiveVoiceCount);
end;

procedure TTestAudioMixer.DovrebbeFermareTutteLeVociConClear;
var
  LVoice: IAudioVoice;
begin
  LVoice := MakeVoice(MakeSample([1, 2, 3], 1, RATE));
  LVoice.Play;
  FMixerIntf.Clear;
  Assert.AreEqual<Integer>(0, FMixer.ActiveVoiceCount);
end;

procedure TTestAudioMixer.DovrebbeIgnorareUnaVoceDopoLaFineDelMixer;
var
  LVoice: IAudioVoice;
begin
  LVoice := MakeVoice(MakeSample([1, 2, 3], 1, RATE));
  FMixerIntf := nil;
  FMixer := nil;
  LVoice.Play;
  Assert.IsFalse(LVoice.IsPlaying);
  LVoice.Stop;
end;

procedure TTestAudioMixer.DovrebbeRifiutareUnRateDelMixerNonValido;
begin
  Assert.WillRaise(
    procedure
    begin
      TSfxMixer.Create(0);
    end, EArgumentOutOfRangeException);
end;

end.
