{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine - the sound device on the PCM output         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveOutDevice;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.Types, DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.Mixer.Intf, DelphiDoom.Audio.Mixer, DelphiDoom.GameHost.Audio.Intf,
  DelphiDoom.Engine.Audio.WaveOutDevice;

type
  /// <summary>An output that does not play: it keeps the source, as a thread of waveOut would ask it for samples</summary>
  TFakePcmOutput = class(TInterfacedObject, IGameHostPcmOutput)
  public
    OpenResult: Boolean;
    OpenCount: Integer;
    CloseCount: Integer;
    Rate: Integer;
    Source: IGameHostPcmSource;
    constructor Create;
    function Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
    procedure Close;
    function IsOpen: Boolean;
    function CompletedBuffers: Integer;
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioWaveOutDevice = class(TObject)
  strict private
    FOutput: TFakePcmOutput;
    FOutputIntf: IGameHostPcmOutput;
    FDevice: ISoundDevice;
    FBytes: TBytes;
    function MakeSample: TSfxSample;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAprireLUscitaAlRateDato;
    [Test]
    procedure DovrebbeDareFalsoSeLUscitaNonSiApre;
    [Test]
    procedure DovrebbeDareLaVoceMixataAllUscita;
    [Test]
    procedure DovrebbeChiudereLUscitaEFermareLeVoci;
    [Test]
    procedure DovrebbeRifiutareUnFormatoNonSuonabile;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNulle;
  end;

implementation

{ TFakePcmOutput }

constructor TFakePcmOutput.Create;
begin
  inherited Create;
  OpenResult := True;
end;

function TFakePcmOutput.Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
begin
  Inc(OpenCount);
  Rate := ARate;
  Result := OpenResult;
  if Result then
    Source := ASource;
end;

procedure TFakePcmOutput.Close;
begin
  Inc(CloseCount);
  Source := nil;
end;

function TFakePcmOutput.IsOpen: Boolean;
begin
  Result := Assigned(Source);
end;

function TFakePcmOutput.CompletedBuffers: Integer;
begin
  Result := 0;
end;

{ TTestAudioWaveOutDevice }

procedure TTestAudioWaveOutDevice.Setup;
begin
  FOutput := TFakePcmOutput.Create;
  FOutputIntf := FOutput;
  FDevice := TEngineWaveOutSoundDevice.Create(FOutputIntf, TSfxMixer.Create(1000), 1000, nil);
end;

procedure TTestAudioWaveOutDevice.TearDown;
begin
  FDevice := nil;
  FOutputIntf := nil;
  FOutput := nil;
end;

function TTestAudioWaveOutDevice.MakeSample: TSfxSample;
begin
  SetLength(FBytes, 4);
  FBytes[0] := 100;
  FBytes[1] := 0;
  FBytes[2] := 200;
  FBytes[3] := 0;
  Result.Format.Tag := 1;
  Result.Format.Channels := 1;
  Result.Format.SamplesPerSecond := 1000;
  Result.Format.AverageBytesPerSecond := 2000;
  Result.Format.BitsPerSample := 16;
  Result.Data := @FBytes[0];
  Result.Offset := 0;
  Result.Length := 4;
  Result.IsExternal := False;
end;

procedure TTestAudioWaveOutDevice.DovrebbeAprireLUscitaAlRateDato;
begin
  Assert.IsTrue(FDevice.Initialize);
  Assert.AreEqual<Integer>(1, FOutput.OpenCount);
  Assert.AreEqual<Integer>(1000, FOutput.Rate);
  Assert.IsTrue(Assigned(FOutput.Source));
end;

procedure TTestAudioWaveOutDevice.DovrebbeDareFalsoSeLUscitaNonSiApre;
begin
  FOutput.OpenResult := False;
  Assert.IsFalse(FDevice.Initialize);
end;

procedure TTestAudioWaveOutDevice.DovrebbeDareLaVoceMixataAllUscita;
var
  LVoice: IAudioVoice;
  LSample: TSfxSample;
  LBuffer: array[0..3] of SmallInt;
begin
  FDevice.Initialize;
  LSample := MakeSample;
  Assert.AreEqual<Integer>(0, FDevice.CreateVoice(LSample, LVoice));
  Assert.AreEqual<Integer>(0, LVoice.Load(LSample));
  LVoice.Play;
  // the thread of the output asks the source
  FOutput.Source.Render(PByte(@LBuffer[0]), SizeOf(LBuffer));
  Assert.AreEqual<Integer>(100, LBuffer[0]);
  Assert.AreEqual<Integer>(100, LBuffer[1]);
  Assert.AreEqual<Integer>(200, LBuffer[2]);
  Assert.AreEqual<Integer>(200, LBuffer[3]);
end;

procedure TTestAudioWaveOutDevice.DovrebbeChiudereLUscitaEFermareLeVoci;
var
  LVoice: IAudioVoice;
  LSample: TSfxSample;
begin
  FDevice.Initialize;
  LSample := MakeSample;
  FDevice.CreateVoice(LSample, LVoice);
  LVoice.Load(LSample);
  LVoice.Play;
  FDevice.Shutdown;
  Assert.AreEqual<Integer>(1, FOutput.CloseCount);
  Assert.IsFalse(FOutput.IsOpen);
end;

procedure TTestAudioWaveOutDevice.DovrebbeRifiutareUnFormatoNonSuonabile;
var
  LVoice: IAudioVoice;
  LSample: TSfxSample;
begin
  LSample := MakeSample;
  LSample.Format.BitsPerSample := 24;
  Assert.AreEqual<Integer>(SFX_MIXER_BAD_FORMAT, FDevice.CreateVoice(LSample, LVoice));
  Assert.IsNull(LVoice);
end;

procedure TTestAudioWaveOutDevice.DovrebbeRifiutareLeDipendenzeNulle;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineWaveOutSoundDevice.Create(nil, TSfxMixer.Create(1000), 1000, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TEngineWaveOutSoundDevice.Create(FOutputIntf, nil, 1000, nil);
    end, EArgumentNilException);
end;

end.
