{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the sound device on top of Libs\Audio            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the BASS calls of modplay   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.AudioDevice;

interface

uses
  System.SysUtils, DelphiDoom.Audio.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Greed.Sound.Intf;

type
  /// <summary>
  ///   IGreedSoundDevice (what BASS did) with the pieces of the audio library: an effect is a WAV that
  ///   TSfxWaveParser reads and a voice of an ISoundDevice plays (pan and volume from the linear values of the
  ///   game to the hundredths of a decibel of the device); a song is a module that an IMusicPlayer (the tracker
  ///   backend) registers and plays in a loop. The devices come from the caller: DirectSound and the module
  ///   backend are classes of the engine, a test gives fakes
  /// </summary>
  TGreedAudioDevice = class(TInterfacedObject, IGreedSoundDevice)
  strict private
    FDevice: ISoundDevice;
    FMusic: IMusicPlayer;
    FLog: ILog;
    FReady: Boolean;
  public
    constructor Create(const ADevice: ISoundDevice; const AMusic: IMusicPlayer; const ALog: ILog);
    function Initialize: Boolean;
    procedure Shutdown;
    function StartEffect(const AWave: TBytes): IGreedEffectChannel;
    function StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
    /// <summary>-1.0 .. 1.0 to -10000 .. 10000 (AUDIO_PAN_LEFT .. AUDIO_PAN_RIGHT)</summary>
    class function ToDevicePan(APan: Single): Integer; static;
    /// <summary>0.0 .. 1.0 to hundredths of a decibel, -10000 (silence) .. 0</summary>
    class function ToDeviceVolume(AVolume: Single): Integer; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Audio.Types, DelphiDoom.Audio.WaveParser;

type
  TEffectChannel = class(TInterfacedObject, IGreedEffectChannel)
  strict private
    FVoice: IAudioVoice;
    // the voice copies the samples at Load: the bytes are only kept while it is started
  public
    constructor Create(const AVoice: IAudioVoice);
    procedure SetPan(APan: Single);
    procedure SetVolume(AVolume: Single);
    function IsActive: Boolean;
    procedure Stop;
  end;

  TMusicChannel = class(TInterfacedObject, IGreedMusicChannel)
  strict private
    FPlayer: IMusicPlayer;
    FHandle: Integer;
    // the song is read from these bytes while it plays
    FModule: TBytes;
  public
    constructor Create(const APlayer: IMusicPlayer; AHandle: Integer; const AModule: TBytes);
    procedure SetVolume(AVolume: Single);
    procedure Stop;
  end;

const
  // the volumes of the music backends are the 0..15 of Doom
  MUSIC_VOLUME_STEPS = 15;

{ TEffectChannel }

constructor TEffectChannel.Create(const AVoice: IAudioVoice);
begin
  inherited Create;
  FVoice := AVoice;
end;

procedure TEffectChannel.SetPan(APan: Single);
begin
  FVoice.SetPan(TGreedAudioDevice.ToDevicePan(APan));
end;

procedure TEffectChannel.SetVolume(AVolume: Single);
begin
  FVoice.SetVolume(TGreedAudioDevice.ToDeviceVolume(AVolume));
end;

function TEffectChannel.IsActive: Boolean;
begin
  Result := FVoice.IsPlaying;
end;

procedure TEffectChannel.Stop;
begin
  FVoice.Stop;
end;

{ TMusicChannel }

constructor TMusicChannel.Create(const APlayer: IMusicPlayer; AHandle: Integer; const AModule: TBytes);
begin
  inherited Create;
  FPlayer := APlayer;
  FHandle := AHandle;
  FModule := AModule;
end;

procedure TMusicChannel.SetVolume(AVolume: Single);
begin
  FPlayer.SetVolume(Round(Min(Max(AVolume, 0), 1) * MUSIC_VOLUME_STEPS));
end;

procedure TMusicChannel.Stop;
begin
  if FHandle <> 0 then
    FPlayer.Unregister(FHandle);
  FHandle := 0;
end;

{ TGreedAudioDevice }

constructor TGreedAudioDevice.Create(const ADevice: ISoundDevice; const AMusic: IMusicPlayer; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  if not Assigned(AMusic) then
    raise EArgumentNilException.Create('AMusic');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FDevice := ADevice;
  FMusic := AMusic;
  FLog := ALog;
end;

function TGreedAudioDevice.Initialize: Boolean;
begin
  FMusic.Initialize;
  FReady := FDevice.Initialize;
  Result := FReady;
end;

procedure TGreedAudioDevice.Shutdown;
begin
  FMusic.Shutdown;
  FDevice.Shutdown;
  FReady := False;
end;

function TGreedAudioDevice.StartEffect(const AWave: TBytes): IGreedEffectChannel;
var
  LChunks: TSfxWaveChunks;
  LSample: TSfxSample;
  LVoice: IAudioVoice;
begin
  Result := nil;
  if not FReady or (Length(AWave) = 0) then
    Exit;
  // the lumps of the game are WAV files (BASS reads them); the parser would take any other bytes for a DMX sound
  if not TSfxWaveParser.IsRiff(@AWave[0], Length(AWave)) then
    Exit;
  LChunks := Default(TSfxWaveChunks);
  TSfxWaveParser.ParseLump(@AWave[0], Length(AWave), 'greed', FLog, LChunks);
  if not (LChunks.FormatFound and LChunks.DataFound) then
    Exit;
  LSample := Default(TSfxSample);
  LSample.Format := LChunks.Format;
  LSample.Data := @AWave[LChunks.DataOffset];
  LSample.Length := LChunks.DataLength;
  if (FDevice.CreateVoice(LSample, LVoice) <> 0) or not Assigned(LVoice) then
    Exit;
  if LVoice.Load(LSample) <> 0 then
    Exit;
  LVoice.Play;
  Result := TEffectChannel.Create(LVoice);
end;

function TGreedAudioDevice.StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
var
  LHandle: Integer;
begin
  Result := nil;
  if Length(AModule) = 0 then
    Exit;
  LHandle := FMusic.Register(@AModule[0], Length(AModule));
  if LHandle = 0 then
    Exit;
  Result := TMusicChannel.Create(FMusic, LHandle, AModule);
  Result.SetVolume(AVolume);
  FMusic.Play(LHandle, True);
end;

class function TGreedAudioDevice.ToDevicePan(APan: Single): Integer;
begin
  Result := Round(Min(Max(APan, -1), 1) * AUDIO_PAN_RIGHT);
end;

class function TGreedAudioDevice.ToDeviceVolume(AVolume: Single): Integer;
begin
  if AVolume <= 0.0001 then
    Exit(AUDIO_VOLUME_MIN);
  // 20 log10 of the amplitude, in hundredths of a decibel
  Result := Round(2000 * Log10(Min(AVolume, 1)));
  if Result < AUDIO_VOLUME_MIN then
    Result := AUDIO_VOLUME_MIN;
end;

end.
