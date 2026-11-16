{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, channels and S_StartSound      }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.ChannelPool;

interface

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Intf,
  DelphiDoom.Audio.Q3.State, DelphiDoom.Audio.Q3.Listener;

type
  /// <summary>
  ///   The 96 channels of Quake III: the free list (S_ChannelSetup, S_ChannelMalloc,
  ///   S_ChannelFree), the choice of a channel for a new sound (S_StartSound) and the
  ///   start and end of sounds at each mix (S_ScanChannelStarts)
  /// </summary>
  /// <remarks>
  ///   The free list is a stack of indexes, popped from the last channel down as in the C
  ///   (which links the free channels through their own memory). Differences from the
  ///   original: the duplicate check reads channel i and not the channel 2i (the C
  ///   advances the pointer and the index together and reads past the array), and when no
  ///   channel passes the two tests the oldest of all is taken (the C reads one element
  ///   past the end of the array to decide)
  /// </remarks>
  TQ3ChannelPool = class
  strict private
    FState: TQ3SoundState;
    FClock: IQ3SoundClock;
    FListener: TQ3Listener;
    FFree: array[0..Q3_MAX_CHANNELS - 1] of Integer;
    FFreeCount: Integer;
    function Allocate: Integer;
    function StealChannel(ASfx: TQ3Sfx; AEntityNumber: Integer): Integer;
  public
    constructor Create(AState: TQ3SoundState; const AClock: IQ3SoundClock;
      AListener: TQ3Listener);
    /// <summary>S_ChannelSetup: every channel free, the last one is the first given</summary>
    procedure Reset;
    /// <summary>S_ChannelFree</summary>
    procedure Release(AIndex: Integer);
    /// <summary>
    ///   S_StartSound on a sound already validated. AOrigin nil = follow the entity. The
    ///   result is the index of the channel, -1 if the sound was not started (double start
    ///   within 50 ms, too many of the same, no channel to take)
    /// </summary>
    function StartSound(AOrigin: PQ3Vec3; AEntityNumber, AEntityChannel: Integer;
      ASfx: TQ3Sfx): Integer;
    /// <summary>S_ScanChannelStarts: True if a sound began since the last mix</summary>
    function ScanChannelStarts: Boolean;
  end;

implementation

{ TQ3ChannelPool }

constructor TQ3ChannelPool.Create(AState: TQ3SoundState; const AClock: IQ3SoundClock;
  AListener: TQ3Listener);
begin
  inherited Create;
  FState := AState;
  FClock := AClock;
  FListener := AListener;
  Reset;
end;

procedure TQ3ChannelPool.Reset;
var
  LIndex: Integer;
begin
  FillChar(FState.Channels, SizeOf(FState.Channels), 0);
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    FFree[LIndex] := LIndex;
  FFreeCount := Q3_MAX_CHANNELS;
end;

procedure TQ3ChannelPool.Release(AIndex: Integer);
begin
  FState.Channels[AIndex].Sfx := nil;
  FFree[FFreeCount] := AIndex;
  Inc(FFreeCount);
end;

function TQ3ChannelPool.Allocate: Integer;
begin
  if FFreeCount = 0 then
    Exit(-1);
  Dec(FFreeCount);
  Result := FFree[FFreeCount];
  FState.Channels[Result].AllocTime := FClock.Milliseconds;
end;

function TQ3ChannelPool.StealChannel(ASfx: TQ3Sfx; AEntityNumber: Integer): Integer;
var
  LIndex, LOldest: Integer;
begin
  Result := -1;
  LOldest := ASfx.LastTimeUsed;
  // the oldest sound of the same entity
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    if (FState.Channels[LIndex].EntityNumber <> FListener.Number) and
      (FState.Channels[LIndex].EntityNumber = AEntityNumber) and
      (FState.Channels[LIndex].AllocTime < LOldest) and
      (FState.Channels[LIndex].EntityChannel <> Q3_CHAN_ANNOUNCER) then
    begin
      LOldest := FState.Channels[LIndex].AllocTime;
      Result := LIndex;
    end;
  if Result <> -1 then
    Exit;
  // else the oldest of everyone but the listener and the announcer
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    if (FState.Channels[LIndex].EntityNumber <> FListener.Number) and
      (FState.Channels[LIndex].AllocTime < LOldest) and
      (FState.Channels[LIndex].EntityChannel <> Q3_CHAN_ANNOUNCER) then
    begin
      LOldest := FState.Channels[LIndex].AllocTime;
      Result := LIndex;
    end;
  if Result <> -1 then
    Exit;
  // else the oldest of all
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    if FState.Channels[LIndex].AllocTime < LOldest then
    begin
      LOldest := FState.Channels[LIndex].AllocTime;
      Result := LIndex;
    end;
end;

function TQ3ChannelPool.StartSound(AOrigin: PQ3Vec3; AEntityNumber, AEntityChannel: Integer;
  ASfx: TQ3Sfx): Integer;
var
  LIndex, LTime, LInPlay, LAllowed: Integer;
begin
  Result := -1;
  LTime := FClock.Milliseconds;

  LAllowed := 4;
  if AEntityNumber = FListener.Number then
    LAllowed := 8;

  LInPlay := 0;
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    if (FState.Channels[LIndex].EntityNumber = AEntityNumber) and
      (FState.Channels[LIndex].Sfx = ASfx) then
    begin
      // double sound start
      if LTime - FState.Channels[LIndex].AllocTime < 50 then
        Exit;
      Inc(LInPlay);
    end;
  if LInPlay > LAllowed then
    Exit;

  ASfx.LastTimeUsed := LTime;

  Result := Allocate;
  if Result = -1 then
  begin
    Result := StealChannel(ASfx, AEntityNumber);
    if Result = -1 then
      Exit; // "dropping sound"
    FState.Channels[Result].AllocTime := ASfx.LastTimeUsed;
  end;

  if Assigned(AOrigin) then
  begin
    FState.Channels[Result].Origin := AOrigin^;
    FState.Channels[Result].FixedOrigin := True;
  end
  else
    FState.Channels[Result].FixedOrigin := False;
  FState.Channels[Result].MasterVolume := 127;
  FState.Channels[Result].EntityNumber := AEntityNumber;
  FState.Channels[Result].Sfx := ASfx;
  FState.Channels[Result].StartSample := Q3_START_SAMPLE_IMMEDIATE;
  FState.Channels[Result].EntityChannel := AEntityChannel;
  FState.Channels[Result].LeftVolume := 127;
  FState.Channels[Result].RightVolume := 127;
  FState.Channels[Result].Doppler := False;
end;

function TQ3ChannelPool.ScanChannelStarts: Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
  begin
    if FState.Channels[LIndex].Sfx = nil then
      Continue;
    // started this frame: it begins mixing at the very first sample
    if FState.Channels[LIndex].StartSample = Q3_START_SAMPLE_IMMEDIATE then
    begin
      FState.Channels[LIndex].StartSample := FState.PaintedTime;
      Result := True;
      Continue;
    end;
    // completely finished by now
    if FState.Channels[LIndex].StartSample + FState.Channels[LIndex].Sfx.SoundLength <=
      FState.PaintedTime then
      Release(LIndex);
  end;
end;

end.
