{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - a sound effect of the software mixer             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Mixer.Voice;
{$Q-}
{$R-}
// the position is a 32.32 fixed point number that is only ever added to

interface

uses
  DelphiDoom.AudioMix.Intf,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.Mixer.Intf;

type
  /// <summary>
  ///   A sound effect (PCM, 8 bit unsigned or 16 bit signed, one or two channels, any rate) that plays at the rate
  ///   of the mixer with linear interpolation, a volume and a pan. It is an IAudioVoice for the player and an
  ///   IPcmVoice for the list of the mixer: Mix adds its next frames to a wide sum (two 32 bit integers for each
  ///   frame). Play always starts from the first sample (the player never resumes a stopped sound); the voice is in
  ///   the list of the mixer only while it plays. Volume and pan are read once for each block
  /// </summary>
  TSfxMixerVoice = class(TInterfacedObject, IAudioVoice, IPcmVoice)
  strict private
    [weak] FScheduler: ISfxVoiceScheduler;
    FChannels: Integer;
    FStep: UInt64;
    // decoded when it is loaded: 16 bit samples, interleaved by channel
    FSamples: TArray<SmallInt>;
    FFrameCount: Integer;
    // the position in the frames, 32.32 fixed point
    FPosition: UInt64;
    FHandle: Integer;
    FVolume: Integer;
    FPan: Integer;
    FLeftGain: Integer;
    FRightGain: Integer;
    procedure UpdateGains;
  public
    /// <param name="AScheduler">The mixer that owns the list of the voices; it is not kept alive by the voice</param>
    constructor Create(const AScheduler: ISfxVoiceScheduler; AChannels, ASampleRate, AOutputRate: Integer);
    function Load(const ASample: TSfxSample): Integer;
    procedure Play;
    procedure Stop;
    procedure Rewind;
    procedure SetPan(APan: Integer);
    procedure SetVolume(AVolume: Integer);
    function IsPlaying: Boolean;
    /// <summary>Adds ACount frames to ADestination (PInteger, two integers per frame); true when it has ended</summary>
    function Mix(ADestination: Pointer; ACount: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  DelphiDoom.Audio.Mixer.Gains;

const
  POSITION_SHIFT = 32;
  // 15 bits of fraction: the product with a difference of two samples fits 32 bits
  FRACTION_SHIFT = POSITION_SHIFT - 15;
  FRACTION_MASK = $7FFF;
  FRACTION_ONE = 32768;

{ TSfxMixerVoice }

constructor TSfxMixerVoice.Create(const AScheduler: ISfxVoiceScheduler; AChannels, ASampleRate,
  AOutputRate: Integer);
begin
  inherited Create;
  if not Assigned(AScheduler) then
    raise EArgumentNilException.Create('AScheduler');
  FScheduler := AScheduler;
  FChannels := AChannels;
  FStep := (UInt64(ASampleRate) shl POSITION_SHIFT) div UInt64(AOutputRate);
  FVolume := AUDIO_VOLUME_MAX;
  FPan := AUDIO_PAN_CENTER;
  UpdateGains;
end;

procedure TSfxMixerVoice.UpdateGains;
var
  LLeft: Integer;
  LRight: Integer;
begin
  TSfxMixerGains.ChannelGains(FVolume, FPan, LLeft, LRight);
  FLeftGain := LLeft;
  FRightGain := LRight;
end;

function TSfxMixerVoice.Load(const ASample: TSfxSample): Integer;
var
  LBytes: Integer;
  LBytesPerSample: Integer;
  LCount: Integer;
  LIndex: Integer;
  LSource: PByte;
  LDecoded: TArray<SmallInt>;
  LLock: TCriticalSection;
  LScheduler: ISfxVoiceScheduler;
begin
  LBytes := ASample.Length - ASample.Offset;
  if (LBytes < 0) or (not Assigned(ASample.Data)) then
    Exit(SFX_MIXER_BAD_FORMAT);
  LBytesPerSample := ASample.Format.BitsPerSample div 8;
  LCount := LBytes div LBytesPerSample;
  // whole frames only
  LCount := LCount - (LCount mod FChannels);
  SetLength(LDecoded, LCount);
  LSource := ASample.Data + ASample.Offset;
  if LBytesPerSample = 1 then
  begin
    // 8 bit samples have no sign
    for LIndex := 0 to LCount - 1 do
      LDecoded[LIndex] := (Integer(LSource[LIndex]) - 128) shl 8;
  end
  else
  begin
    for LIndex := 0 to LCount - 1 do
      LDecoded[LIndex] := SmallInt(Word(LSource[LIndex * 2]) or (Word(LSource[LIndex * 2 + 1]) shl 8));
  end;

  LScheduler := FScheduler;
  if Assigned(LScheduler) then
  begin
    LLock := LScheduler.Lock;
    LLock.Enter;
  end
  else
    LLock := nil;
  try
    FSamples := LDecoded;
    FFrameCount := LCount div FChannels;
    FPosition := 0;
  finally
    if Assigned(LLock) then
      LLock.Leave;
  end;
  Result := 0;
end;

procedure TSfxMixerVoice.Play;
var
  LScheduler: ISfxVoiceScheduler;
begin
  LScheduler := FScheduler;
  if not Assigned(LScheduler) then
    Exit;
  LScheduler.Lock.Enter;
  try
    FPosition := 0;
    if FHandle = 0 then
      FHandle := LScheduler.Start(Self);
  finally
    LScheduler.Lock.Leave;
  end;
end;

procedure TSfxMixerVoice.Stop;
var
  LScheduler: ISfxVoiceScheduler;
begin
  LScheduler := FScheduler;
  if not Assigned(LScheduler) then
    Exit;
  LScheduler.Lock.Enter;
  try
    if FHandle <> 0 then
    begin
      LScheduler.Remove(FHandle);
      FHandle := 0;
    end;
  finally
    LScheduler.Lock.Leave;
  end;
end;

procedure TSfxMixerVoice.Rewind;
begin
  // Play starts from the first sample: nothing to keep
end;

procedure TSfxMixerVoice.SetPan(APan: Integer);
begin
  FPan := APan;
  UpdateGains;
end;

procedure TSfxMixerVoice.SetVolume(AVolume: Integer);
begin
  FVolume := AVolume;
  UpdateGains;
end;

function TSfxMixerVoice.IsPlaying: Boolean;
begin
  Result := FHandle <> 0;
end;

function TSfxMixerVoice.Mix(ADestination: Pointer; ACount: Integer): Boolean;
var
  LIndex: Integer;
  LFrame: Integer;
  LNext: Integer;
  LFraction: Integer;
  LLeft: Integer;
  LRight: Integer;
  LLeftGain: Integer;
  LRightGain: Integer;
  LSums: PInteger;
  LPosition: UInt64;
begin
  // called with the lock of the list: Play and Stop cannot change the position or the handle meanwhile
  LLeftGain := FLeftGain;
  LRightGain := FRightGain;
  LPosition := FPosition;
  LSums := PInteger(ADestination);
  Result := False;
  for LIndex := 0 to ACount - 1 do
  begin
    LFrame := Integer(LPosition shr POSITION_SHIFT);
    if LFrame >= FFrameCount then
    begin
      Result := True;
      Break;
    end;
    LNext := LFrame + 1;
    if LNext >= FFrameCount then
      LNext := LFrame;
    LFraction := Integer((LPosition shr FRACTION_SHIFT) and FRACTION_MASK);
    if FChannels = 1 then
    begin
      LLeft := FSamples[LFrame] + ((FSamples[LNext] - FSamples[LFrame]) * LFraction) div FRACTION_ONE;
      LRight := LLeft;
    end
    else
    begin
      LLeft := FSamples[LFrame * 2] + ((FSamples[LNext * 2] - FSamples[LFrame * 2]) * LFraction) div FRACTION_ONE;
      LRight := FSamples[LFrame * 2 + 1] +
        ((FSamples[LNext * 2 + 1] - FSamples[LFrame * 2 + 1]) * LFraction) div FRACTION_ONE;
    end;
    Inc(LSums^, (LLeft * LLeftGain) div SFX_GAIN_ONE);
    Inc(LSums);
    Inc(LSums^, (LRight * LRightGain) div SFX_GAIN_ONE);
    Inc(LSums);
    Inc(LPosition, FStep);
  end;
  FPosition := LPosition;
  if Result then
    FHandle := 0;
end;

end.
