{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, when and how far to mix        }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Scheduler;

interface

uses
  System.SysUtils, DelphiDoom.Audio.Q3.Intf, DelphiDoom.Audio.Q3.State,
  DelphiDoom.Audio.Q3.ChannelPool, DelphiDoom.Audio.Q3.Mixer;

type
  /// <summary>
  ///   S_GetSoundtime and S_Update_: reads the position of the device, decides up to
  ///   which sample to mix ahead (s_mixahead, s_mixPreStep, the submission chunk) and
  ///   runs the mixer between BeginPainting and Submit. The statics of the C (buffers,
  ///   oldsamplepos, lastTime, ot) are fields
  /// </summary>
  TQ3Scheduler = class
  strict private
    FState: TQ3SoundState;
    FDevice: IQ3SoundDevice;
    FClock: IQ3SoundClock;
    FPool: TQ3ChannelPool;
    FMixer: TQ3Mixer;
    FOnStopAllSounds: TProc;
    FBuffers: Integer;
    FOldSamplePosition: Integer;
    FLastTime: Single;
    FOldSoundTime: Integer;
  public
    /// <summary>AOnStopAllSounds is what S_GetSoundtime calls when the time gets too large</summary>
    constructor Create(AState: TQ3SoundState; const ADevice: IQ3SoundDevice;
      const AClock: IQ3SoundClock; APool: TQ3ChannelPool; AMixer: TQ3Mixer;
      const AOnStopAllSounds: TProc);
    /// <summary>S_GetSoundtime: sets SoundTime and PaintedTime of the state</summary>
    procedure UpdateSoundTime;
    /// <summary>S_Update_: one step of mixing</summary>
    procedure Update;
  end;

implementation

{$Q-}
{$R-}

uses
  DelphiDoom.Audio.Q3.Types;

{ TQ3Scheduler }

constructor TQ3Scheduler.Create(AState: TQ3SoundState; const ADevice: IQ3SoundDevice;
  const AClock: IQ3SoundClock; APool: TQ3ChannelPool; AMixer: TQ3Mixer;
  const AOnStopAllSounds: TProc);
begin
  inherited Create;
  FState := AState;
  FDevice := ADevice;
  FClock := AClock;
  FPool := APool;
  FMixer := AMixer;
  FOnStopAllSounds := AOnStopAllSounds;
  FOldSoundTime := -1;
end;

procedure TQ3Scheduler.UpdateSoundTime;
var
  LFullSamples, LPosition: Integer;
  LLead: Single;
begin
  LFullSamples := FState.Dma.Samples div FState.Dma.Channels;

  // it is possible to miscount buffers if it has wrapped twice between calls
  LPosition := FDevice.GetPosition;
  if LPosition < FOldSamplePosition then
  begin
    Inc(FBuffers); // buffer wrapped
    if FState.PaintedTime > $40000000 then
    begin
      // time to chop things off to avoid 32 bit limits
      FBuffers := 0;
      FState.PaintedTime := LFullSamples;
      if Assigned(FOnStopAllSounds) then
        FOnStopAllSounds();
    end;
  end;
  FOldSamplePosition := LPosition;

  FState.SoundTime := FBuffers * LFullSamples + LPosition div FState.Dma.Channels;

  if FState.Dma.SubmissionChunk < 256 then
  begin
    LLead := FState.MixPreStep * FState.Dma.Speed;
    LLead := Single(FState.SoundTime) + LLead;
    FState.PaintedTime := TQ3Math.TruncToInt(LLead);
  end
  else
    FState.PaintedTime := FState.SoundTime + FState.Dma.SubmissionChunk;
end;

procedure TQ3Scheduler.Update;
var
  LEndTime: Cardinal;
  LSamples: Integer;
  LThisTime, LSane, LMixAhead, LOp, LTerm: Single;
  LProduct: Double;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;

  LThisTime := FClock.Milliseconds;

  // updates SoundTime
  UpdateSoundTime;

  if FState.SoundTime = FOldSoundTime then
    Exit;
  FOldSoundTime := FState.SoundTime;

  // clear any sound effects that end before the current time, and start any new sounds
  FPool.ScanChannelStarts;

  LSane := LThisTime - FLastTime;
  if LSane < 11 then
    LSane := 11; // 85hz

  LMixAhead := FState.MixAhead * FState.Dma.Speed;
  LTerm := LSane * FState.Dma.Speed;
  LProduct := Double(LTerm) * 0.01;
  LProduct := Double(FState.MixPreStep) + LProduct;
  LOp := Single(LProduct);
  if LOp < LMixAhead then
    LMixAhead := LOp;

  // mix ahead of the current position
  LTerm := Single(FState.SoundTime) + LMixAhead;
  LEndTime := Cardinal(TQ3Math.TruncToInt(LTerm));

  // mix to an even submission block size
  LEndTime := (LEndTime + Cardinal(FState.Dma.SubmissionChunk) - 1) and
    not Cardinal(FState.Dma.SubmissionChunk - 1);

  // never mix more than the complete buffer
  LSamples := FState.Dma.Samples shr (FState.Dma.Channels - 1);
  if LEndTime - Cardinal(FState.SoundTime) > Cardinal(LSamples) then
    LEndTime := Cardinal(FState.SoundTime + LSamples);

  FDevice.BeginPainting;
  FMixer.PaintChannels(Integer(LEndTime));
  FDevice.Submit;

  FLastTime := LThisTime;
end;

end.
