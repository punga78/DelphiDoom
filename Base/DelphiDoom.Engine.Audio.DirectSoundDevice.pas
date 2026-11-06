{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the sound card through DirectSound                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Audio.DirectSoundDevice;

interface

uses
  System.SysUtils,
  Windows,
  DirectX,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf,
  DelphiDoom.Logging.Intf;

type
  TDirectSoundDevice = class(TInterfacedObject, ISoundDevice)
  private
    FWindow: TFunc<THandle>;
    FLog: ILog;
    FDirectSound: IDirectSound;
    FPrimary: IDirectSoundBuffer;
  public
    /// <param name="AWindow">The window of the game, asked when the device starts</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AWindow: TFunc<THandle>; const ALog: ILog);
    function Initialize: Boolean;
    procedure Shutdown;
    function CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
  end;

implementation

uses
  MMSystem,
  DelphiDoom.Engine.Audio.DirectSoundVoice;

const
  SCreateFailed = 'I_InitSound(): DirectSoundCreate Failed, result = %d';
  SCooperativeLevelFailed = 'I_InitSound(): DirectSound.SetCooperativeLevel Failed, result = %d';
  SPrimaryUnavailable = 'I_InitSound(): Unable to access primary sound buffer, result = %d';
  SPrimaryFormatFailed = 'I_InitSound(): Unable to set primary sound buffer format, result = %d';

{ TDirectSoundDevice }

constructor TDirectSoundDevice.Create(const AWindow: TFunc<THandle>; const ALog: ILog);
begin
  inherited Create;
  FWindow := AWindow;
  FLog := ALog;
end;

function TDirectSoundDevice.Initialize: Boolean;
var
  LResult: HRESULT;
  LDescription: DSBUFFERDESC;
  LFormat: TWAVEFORMATEX;
begin
  Result := False;
  LResult := DirectSoundCreate(nil, FDirectSound, nil);
  if LResult <> DS_OK then
  begin
    FDirectSound := nil;
    if Assigned(FLog) then
      FLog.Info(Format(SCreateFailed, [LResult]));
    Exit;
  end;

  LResult := FDirectSound.SetCooperativeLevel(FWindow(), DSSCL_PRIORITY);
  if LResult <> DS_OK then
    raise EAudioDeviceException.CreateFmt(SCooperativeLevelFailed, [LResult]);

  LFormat.wFormatTag := WAVE_FORMAT_PCM;
  LFormat.nChannels := 1;
  LFormat.cbSize := 0;
  LFormat.nBlockAlign := 1;
  LFormat.nSamplesPerSec := 11025;
  LFormat.nAvgBytesPerSec := 11025;
  LFormat.wBitsPerSample := 8;

  ZeroMemory(@LDescription, SizeOf(LDescription));
  LDescription.dwSize := SizeOf(LDescription);
  LDescription.dwFlags := DSBCAPS_PRIMARYBUFFER;
  LDescription.dwBufferBytes := 0;
  LDescription.lpwfxFormat := nil;

  LResult := FDirectSound.CreateSoundBuffer(LDescription, FPrimary, nil);
  if LResult <> DS_OK then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SPrimaryUnavailable, [LResult]));
    FPrimary := nil;
  end
  else
  begin
    LResult := FPrimary.SetFormat(LFormat);
    if (LResult <> DS_OK) and Assigned(FLog) then
      FLog.Warning(Format(SPrimaryFormatFailed, [LResult]));
    FPrimary.Play(0, 0, DSBPLAY_LOOPING);
  end;

  Result := True;
end;

procedure TDirectSoundDevice.Shutdown;
begin
  FPrimary := nil;
  FDirectSound := nil;
end;

function TDirectSoundDevice.CreateVoice(const ASample: TSfxSample;
  out AVoice: IAudioVoice): Integer;
var
  LFormat: TWAVEFORMATEX;
  LDescription: DSBUFFERDESC;
  LBuffer: IDirectSoundBuffer;
begin
  AVoice := nil;
  LFormat.wFormatTag := ASample.Format.Tag;
  LFormat.nChannels := ASample.Format.Channels;
  LFormat.nSamplesPerSec := ASample.Format.SamplesPerSecond;
  LFormat.nAvgBytesPerSec := ASample.Format.AverageBytesPerSecond;
  LFormat.wBitsPerSample := ASample.Format.BitsPerSample;
  LFormat.nBlockAlign := LFormat.nChannels * LFormat.wBitsPerSample div 8;
  LFormat.cbSize := 0;

  ZeroMemory(@LDescription, SizeOf(LDescription));
  LDescription.dwSize := SizeOf(LDescription);
  LDescription.dwFlags := DSBCAPS_CTRLVOLUME or DSBCAPS_CTRLFREQUENCY or DSBCAPS_CTRLPAN or
    DSBCAPS_GETCURRENTPOSITION2 or DSBCAPS_STATIC;
  LDescription.dwBufferBytes := ASample.Length;
  LDescription.lpwfxFormat := @LFormat;

  Result := FDirectSound.CreateSoundBuffer(LDescription, LBuffer, nil);
  if Result = DS_OK then
    AVoice := TDirectSoundVoice.Create(LBuffer);
end;

end.
