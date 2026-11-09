{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedAudioDevice                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.AudioDevice;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Audio.Intf,
  DelphiDoom.Logging.Intf, DelphiDoom.Tests.Audio.Fakes, DelphiDoom.Greed.Sound.Intf,
  DelphiDoom.Greed.AudioDevice;

type
  TFakeMusicPlayer = class(TInterfacedObject, IMusicPlayer)
  public
    Registered: TList<Integer>;
    Played: TList<Integer>;
    Unregistered: TList<Integer>;
    Volumes: TList<Integer>;
    RefuseSongs: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize;
    procedure Shutdown;
    function Register(AData: Pointer; ASize: Integer): Integer;
    procedure Play(AHandle: Integer; ALooping: Boolean);
    procedure Pause(AHandle: Integer);
    procedure Resume(AHandle: Integer);
    procedure Unregister(AHandle: Integer);
    procedure SetVolume(AVolume: Integer);
    procedure Process;
  end;

  TFakeLog = class(TInterfacedObject, ILog)
  public
    Warnings: Integer;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedAudioDevice = class(TObject)
  private
    FDevice: TFakeDevice;
    FDeviceIntf: ISoundDevice;
    FMusic: TFakeMusicPlayer;
    FMusicIntf: IMusicPlayer;
    FSut: IGreedSoundDevice;
    function Wave: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSuonareUnaWavSuUnaVoceDelDispositivo;
    [Test]
    procedure DovrebbePassarePanEVolumeAlDispositivo;
    [Test]
    procedure DovrebbeDirePanESilenzioAgliEstremi;
    [Test]
    procedure DovrebbeRifiutareUnaWavNonValida;
    [Test]
    procedure DovrebbeRifiutareSeLaVoceNonSiCrea;
    [Test]
    procedure DovrebbeSuonareUnModuloInRipetizione;
    [Test]
    procedure DovrebbeFermareIlModuloConUnregister;
    [Test]
    procedure DovrebbeDareNilSeNessunBackendRiconosceIlModulo;
    [Test]
    procedure DovrebbeNonSuonareSenzaInizializzazione;
    [Test]
    procedure DovrebbeSollevareConDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.Audio.Types;

{ TFakeMusicPlayer }

constructor TFakeMusicPlayer.Create;
begin
  inherited Create;
  Registered := TList<Integer>.Create;
  Played := TList<Integer>.Create;
  Unregistered := TList<Integer>.Create;
  Volumes := TList<Integer>.Create;
end;

destructor TFakeMusicPlayer.Destroy;
begin
  Registered.Free;
  Played.Free;
  Unregistered.Free;
  Volumes.Free;
  inherited;
end;

procedure TFakeMusicPlayer.Initialize;
begin
end;

procedure TFakeMusicPlayer.Shutdown;
begin
end;

function TFakeMusicPlayer.Register(AData: Pointer; ASize: Integer): Integer;
begin
  if RefuseSongs then
    Exit(0);
  Registered.Add(ASize);
  Result := Registered.Count;
end;

procedure TFakeMusicPlayer.Play(AHandle: Integer; ALooping: Boolean);
begin
  if ALooping then
    Played.Add(AHandle);
end;

procedure TFakeMusicPlayer.Pause(AHandle: Integer);
begin
end;

procedure TFakeMusicPlayer.Resume(AHandle: Integer);
begin
end;

procedure TFakeMusicPlayer.Unregister(AHandle: Integer);
begin
  Unregistered.Add(AHandle);
end;

procedure TFakeMusicPlayer.SetVolume(AVolume: Integer);
begin
  Volumes.Add(AVolume);
end;

procedure TFakeMusicPlayer.Process;
begin
end;

{ TFakeLog }

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  Inc(Warnings);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

{ TTestGreedAudioDevice }

function TTestGreedAudioDevice.Wave: TBytes;
const
  // RIFF, WAVE, fmt (PCM, mono, 11025 Hz, 8 bit) and 4 bytes of data
  WAV: array[0..47] of Byte = (
    $52, $49, $46, $46, $28, 0, 0, 0, $57, $41, $56, $45, $66, $6D, $74, $20, 16, 0, 0, 0, 1, 0, 1, 0,
    $11, $2B, 0, 0, $11, $2B, 0, 0, 1, 0, 8, 0, $64, $61, $74, $61, 4, 0, 0, 0, 10, 20, 30, 40);
var
  LIndex: Integer;
begin
  SetLength(Result, Length(WAV));
  for LIndex := 0 to High(WAV) do
    Result[LIndex] := WAV[LIndex];
end;

procedure TTestGreedAudioDevice.Setup;
begin
  FDevice := TFakeDevice.Create;
  FDeviceIntf := FDevice;
  FMusic := TFakeMusicPlayer.Create;
  FMusicIntf := FMusic;
  FSut := TGreedAudioDevice.Create(FDeviceIntf, FMusicIntf, TFakeLog.Create);
  FSut.Initialize;
end;

procedure TTestGreedAudioDevice.TearDown;
begin
  FSut := nil;
  FMusicIntf := nil;
  FDeviceIntf := nil;
end;

procedure TTestGreedAudioDevice.DovrebbeSuonareUnaWavSuUnaVoceDelDispositivo;
var
  LChannel: IGreedEffectChannel;
begin
  LChannel := FSut.StartEffect(Wave);
  Assert.IsNotNull(LChannel);
  Assert.AreEqual(1, FDevice.Voices.Count);
  Assert.IsTrue(FDevice.Voices[0].Loaded);
  Assert.AreEqual(1, FDevice.Voices[0].PlayCount);
  Assert.IsTrue(LChannel.IsActive);
  FDevice.Voices[0].Playing := False;
  Assert.IsFalse(LChannel.IsActive);
  LChannel.Stop;
  Assert.AreEqual(1, FDevice.Voices[0].StopCount);
end;

procedure TTestGreedAudioDevice.DovrebbePassarePanEVolumeAlDispositivo;
var
  LChannel: IGreedEffectChannel;
begin
  LChannel := FSut.StartEffect(Wave);
  LChannel.SetPan(0.5);
  LChannel.SetVolume(0.1);
  Assert.AreEqual(5000, FDevice.Voices[0].Pan);
  // 20 log10(0.1) = -20 dB
  Assert.AreEqual(-2000, FDevice.Voices[0].Volume);
end;

procedure TTestGreedAudioDevice.DovrebbeDirePanESilenzioAgliEstremi;
begin
  Assert.AreEqual(AUDIO_PAN_LEFT, TGreedAudioDevice.ToDevicePan(-3));
  Assert.AreEqual(AUDIO_PAN_RIGHT, TGreedAudioDevice.ToDevicePan(3));
  Assert.AreEqual(AUDIO_PAN_CENTER, TGreedAudioDevice.ToDevicePan(0));
  Assert.AreEqual(AUDIO_VOLUME_MIN, TGreedAudioDevice.ToDeviceVolume(0));
  Assert.AreEqual(AUDIO_VOLUME_MAX, TGreedAudioDevice.ToDeviceVolume(1));
  Assert.AreEqual(AUDIO_VOLUME_MAX, TGreedAudioDevice.ToDeviceVolume(5));
  Assert.AreEqual(AUDIO_VOLUME_MIN, TGreedAudioDevice.ToDeviceVolume(0.00005));
end;

procedure TTestGreedAudioDevice.DovrebbeRifiutareUnaWavNonValida;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 100);
  Assert.IsNull(FSut.StartEffect(LBytes));
  Assert.IsNull(FSut.StartEffect(nil));
  Assert.AreEqual(0, FDevice.Voices.Count);
end;

procedure TTestGreedAudioDevice.DovrebbeRifiutareSeLaVoceNonSiCrea;
begin
  FDevice.FailuresLeft := 1;
  Assert.IsNull(FSut.StartEffect(Wave));
end;

procedure TTestGreedAudioDevice.DovrebbeSuonareUnModuloInRipetizione;
var
  LChannel: IGreedMusicChannel;
begin
  LChannel := FSut.StartMusic(Wave, 1.0);
  Assert.IsNotNull(LChannel);
  Assert.AreEqual(1, FMusic.Played.Count);
  Assert.AreEqual(15, FMusic.Volumes[0]);
  LChannel.SetVolume(0.5);
  Assert.AreEqual(8, FMusic.Volumes[1]);
end;

procedure TTestGreedAudioDevice.DovrebbeFermareIlModuloConUnregister;
var
  LChannel: IGreedMusicChannel;
begin
  LChannel := FSut.StartMusic(Wave, 1.0);
  LChannel.Stop;
  LChannel.Stop;
  Assert.AreEqual(1, FMusic.Unregistered.Count);
  Assert.AreEqual(1, FMusic.Unregistered[0]);
end;

procedure TTestGreedAudioDevice.DovrebbeDareNilSeNessunBackendRiconosceIlModulo;
begin
  FMusic.RefuseSongs := True;
  Assert.IsNull(FSut.StartMusic(Wave, 1.0));
  Assert.IsNull(FSut.StartMusic(nil, 1.0));
end;

procedure TTestGreedAudioDevice.DovrebbeNonSuonareSenzaInizializzazione;
var
  LSut: IGreedSoundDevice;
begin
  LSut := TGreedAudioDevice.Create(FDeviceIntf, FMusicIntf, TFakeLog.Create);
  Assert.IsNull(LSut.StartEffect(Wave));
end;

procedure TTestGreedAudioDevice.DovrebbeSollevareConDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedAudioDevice.Create(nil, FMusicIntf, TFakeLog.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedAudioDevice.Create(FDeviceIntf, nil, TFakeLog.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedAudioDevice.Create(FDeviceIntf, FMusicIntf, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedAudioDevice);

end.
