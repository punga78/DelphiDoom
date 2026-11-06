{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the player of the sound effects                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SfxPlayer;

interface

uses
  DelphiDoom.Audio.Types, DelphiDoom.Audio.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   A fixed number of channels, every one with a voice of the device. A sound that was played
  ///   and is over is played again from its voice; a new sound takes a channel that was never
  ///   used and, when there is none, the one that is playing for the longest time. The handle of a
  ///   sound is a number that only goes up
  /// </summary>
  TSfxPlayer = class(TInterfacedObject, ISfxPlayer)
  public
    const
      CHANNEL_COUNT = 32;
  private
    FDevice: ISoundDevice;
    FSource: ISfxSampleSource;
    FLog: ILog;
    FVoices: array[0..CHANNEL_COUNT - 1] of IAudioVoice;
    FActive: array[0..CHANNEL_COUNT - 1] of Boolean;
    FSoundIds: array[0..CHANNEL_COUNT - 1] of Integer;
    FHandles: array[0..CHANNEL_COUNT - 1] of Integer;
    FHandleCount: Integer;
    function IsChannelPlaying(AChannel: Integer): Boolean;
    procedure KillChannel(AChannel: Integer);
    function RestartChannel(AChannel, AVolume, ASeparation: Integer): Integer;
    function FindChannelToReplace: Integer;
    function CreateVoiceFor(ASoundId: Integer; var ASample: TSfxSample): IAudioVoice;
    function TryCreateVoice(ASoundId: Integer; const ASample: TSfxSample;
      out AVoice: IAudioVoice): Integer;
    procedure FailStart(const AStep: string; ACode, ASoundId: Integer);
  public
    /// <param name="ADevice">May be nil: there is no sound, only handles</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const ADevice: ISoundDevice; const ASource: ISfxSampleSource;
      const ALog: ILog);
    procedure Shutdown;
    function Start(ASoundId, AVolume, ASeparation: Integer): Integer;
    procedure Stop(AHandle: Integer);
    function IsPlaying(AHandle: Integer): Boolean;
    procedure UpdateParams(AHandle, AVolume, ASeparation: Integer);
    procedure ForgetSounds;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Audio.Levels;

const
  SCreateSoundBuffer = 'CreateSoundBuffer()';
  SLoadSoundBuffer = 'SoundBuffer.Lock()';
  SStartFailed = 'I_StartSound(): %s failed, result = %d. Sound id = %d (%s).'#13#10;
  SRestartDead = 'I_RestartChannel(): Restarting dead sound at channel %d';
  SZeroLength = 'I_StartSound(): Sound %d(%s) has zero length.'#13#10;
  SExternalDiscarded =
    'I_StartSound(): External sound %d caused a problem and will be discarded'#13#10;

{ TSfxPlayer }

constructor TSfxPlayer.Create(const ADevice: ISoundDevice; const ASource: ISfxSampleSource;
  const ALog: ILog);
begin
  inherited Create;
  FDevice := ADevice;
  FSource := ASource;
  FLog := ALog;
  FHandleCount := 1;
  ForgetSounds;
end;

procedure TSfxPlayer.ForgetSounds;
var
  LChannel: Integer;
begin
  for LChannel := 0 to CHANNEL_COUNT - 1 do
    FSoundIds[LChannel] := -1;
end;

function TSfxPlayer.IsChannelPlaying(AChannel: Integer): Boolean;
begin
  Result := False;
  if not Assigned(FDevice) then
    Exit;
  if not Assigned(FVoices[AChannel]) then
    Exit;
  if not FActive[AChannel] then
    Exit;

  if FVoices[AChannel].IsPlaying then
    Result := True
  else
    FActive[AChannel] := False;
end;

procedure TSfxPlayer.KillChannel(AChannel: Integer);
begin
  if Assigned(FDevice) and Assigned(FVoices[AChannel]) then
  begin
    FVoices[AChannel].Stop;
    FVoices[AChannel] := nil;
  end;
end;

function TSfxPlayer.RestartChannel(AChannel, AVolume, ASeparation: Integer): Integer;
var
  LVoice: IAudioVoice;
begin
  FActive[AChannel] := True;
  LVoice := FVoices[AChannel];
  if not Assigned(LVoice) then
    raise ESfxFatalException.CreateFmt(SRestartDead, [AChannel]);

  LVoice.Stop;
  LVoice.Rewind;
  LVoice.SetPan(TSfxLevels.SeparationToPan(ASeparation));
  LVoice.SetVolume(TSfxLevels.VolumeToAttenuation(AVolume));
  LVoice.Play;
  FHandles[AChannel] := FHandleCount;
  Result := FHandleCount;
  Inc(FHandleCount);
end;

function TSfxPlayer.FindChannelToReplace: Integer;
var
  LChannel: Integer;
  LOldestAge: Integer;
  LAge: Integer;
  LFree: Integer;
begin
  Result := 0;
  LOldestAge := 0;
  LFree := -1;
  for LChannel := 0 to CHANNEL_COUNT - 1 do
  begin
    if Assigned(FVoices[LChannel]) then
    begin
      LAge := FHandleCount - FHandles[LChannel];
      if LAge > LOldestAge then
      begin
        LOldestAge := LAge;
        Result := LChannel;
      end;
    end
    else
      LFree := LChannel;
  end;
  if LFree >= 0 then
    Result := LFree;
end;

procedure TSfxPlayer.FailStart(const AStep: string; ACode, ASoundId: Integer);
begin
  raise ESfxStartException.CreateFmt(SStartFailed, [AStep, ACode, ASoundId, FSource.NameOf(ASoundId)]);
end;

function TSfxPlayer.TryCreateVoice(ASoundId: Integer; const ASample: TSfxSample;
  out AVoice: IAudioVoice): Integer;
begin
  Result := FDevice.CreateVoice(ASample, AVoice);
end;

/// The device may refuse a format whose average bytes per second do not match; so it is tried
/// again with the average that the format says
function TSfxPlayer.CreateVoiceFor(ASoundId: Integer; var ASample: TSfxSample): IAudioVoice;
var
  LCode: Integer;
begin
  Result := nil;
  LCode := TryCreateVoice(ASoundId, ASample, Result);
  if LCode = 0 then
    Exit;

  if ASample.IsExternal then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SExternalDiscarded, [ASoundId]));
    FSource.DiscardExternal(ASoundId);
    ASample := FSource.Load(ASoundId);
    LCode := TryCreateVoice(ASoundId, ASample, Result);
    if LCode = 0 then
      Exit;
  end;

  ASample.Format.AverageBytesPerSecond := ASample.Format.SamplesPerSecond *
    ASample.Format.Channels * ASample.Format.BitsPerSample div 8;
  LCode := TryCreateVoice(ASoundId, ASample, Result);
  if LCode <> 0 then
    FailStart(SCreateSoundBuffer, LCode, ASoundId);
  FSource.StoreAverageBytes(ASoundId, ASample.Format.AverageBytesPerSecond);
end;

function TSfxPlayer.Start(ASoundId, AVolume, ASeparation: Integer): Integer;
var
  LChannel: Integer;
  LSample: TSfxSample;
  LVoice: IAudioVoice;
  LCode: Integer;
begin
  if not Assigned(FDevice) then
  begin
    Result := FHandleCount;
    Inc(FHandleCount);
    Exit;
  end;

  // the same sound, over: it is played again from its voice
  for LChannel := 0 to CHANNEL_COUNT - 1 do
    if Assigned(FVoices[LChannel]) and (FSoundIds[LChannel] = ASoundId) and
       not IsChannelPlaying(LChannel) then
    begin
      Result := RestartChannel(LChannel, AVolume, ASeparation);
      Exit;
    end;

  LChannel := FindChannelToReplace;
  LSample := FSource.Load(ASoundId);
  if LSample.Length = 0 then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SZeroLength, [ASoundId, FSource.NameOf(ASoundId)]));
    Result := FHandleCount;
    Exit;
  end;

  LVoice := CreateVoiceFor(ASoundId, LSample);
  LCode := LVoice.Load(LSample);
  if LCode <> 0 then
    FailStart(SLoadSoundBuffer, LCode, ASoundId);

  FVoices[LChannel] := LVoice;
  FSoundIds[LChannel] := ASoundId;
  Result := RestartChannel(LChannel, AVolume, ASeparation);
end;

procedure TSfxPlayer.Stop(AHandle: Integer);
var
  LChannel: Integer;
begin
  if not Assigned(FDevice) then
    Exit;

  for LChannel := 0 to CHANNEL_COUNT - 1 do
    if IsChannelPlaying(LChannel) and (FHandles[LChannel] = AHandle) then
    begin
      FVoices[LChannel].Stop;
      FActive[LChannel] := False;
    end;
end;

function TSfxPlayer.IsPlaying(AHandle: Integer): Boolean;
var
  LChannel: Integer;
begin
  Result := False;
  if not Assigned(FDevice) then
    Exit;

  for LChannel := 0 to CHANNEL_COUNT - 1 do
    if (FHandles[LChannel] = AHandle) and IsChannelPlaying(LChannel) then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TSfxPlayer.UpdateParams(AHandle, AVolume, ASeparation: Integer);
var
  LChannel: Integer;
begin
  if not Assigned(FDevice) then
    Exit;

  for LChannel := 0 to CHANNEL_COUNT - 1 do
    if IsChannelPlaying(LChannel) and (FHandles[LChannel] = AHandle) then
    begin
      FVoices[LChannel].SetPan(TSfxLevels.SeparationToPan(ASeparation));
      FVoices[LChannel].SetVolume(TSfxLevels.VolumeToAttenuation(AVolume));
      Exit;
    end;
end;

procedure TSfxPlayer.Shutdown;
var
  LChannel: Integer;
begin
  if Assigned(FDevice) then
  begin
    for LChannel := 0 to CHANNEL_COUNT - 1 do
      KillChannel(LChannel);
    FDevice.Shutdown;
  end;
end;

end.
