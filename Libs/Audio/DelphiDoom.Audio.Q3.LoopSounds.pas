{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, looping sounds                 }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.LoopSounds;

interface

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Intf,
  DelphiDoom.Audio.Q3.State, DelphiDoom.Audio.Q3.Listener;

type
  /// <summary>
  ///   The continuous sounds of the entities (loopSounds[]): S_AddLoopingSound,
  ///   S_AddRealLoopingSound, S_StopLoopingSound, S_ClearLoopingSounds,
  ///   S_UpdateEntityPosition and S_AddLoopSounds, which merges the sounds of the same
  ///   effect and spatializes them into the loop channels of the state
  /// </summary>
  /// <remarks>
  ///   Differences from the original: an entity number out of 0..1023 raises
  ///   EQ3SoundException (the C accepts 1024 and writes past the array). The doppler
  ///   state of S_AddLoopingSound is kept as the C computes it, including that the old
  ///   scale is always 1 (the C resets dopplerScale just before reading it)
  /// </remarks>
  TQ3LoopSounds = class
  strict private
    FState: TQ3SoundState;
    FListener: TQ3Listener;
    FClock: IQ3SoundClock;
    FLoops: array[0..Q3_MAX_GENTITIES - 1] of TQ3LoopSound;
    FLoopFrame: Integer;
    procedure CheckEntity(AEntityNumber: Integer);
    function DistanceSquared(const AFrom, ATo: TQ3Vec3): Single;
    function PrepareLoop(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3;
      ASfx: TQ3Sfx): Integer;
  public
    constructor Create(AState: TQ3SoundState; AListener: TQ3Listener;
      const AClock: IQ3SoundClock);
    /// <summary>The part of S_ClearSoundBuffer that stops the loops: all sounds and channels</summary>
    procedure Reset;
    /// <summary>S_StopLoopingSound</summary>
    procedure Stop(AEntityNumber: Integer);
    /// <summary>S_ClearLoopingSounds</summary>
    procedure Clear(AKillAll: Boolean);
    /// <summary>S_AddLoopingSound (a sound heard in 3D while the entity adds it each frame)</summary>
    procedure Add(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3; ASfx: TQ3Sfx);
    /// <summary>S_AddRealLoopingSound (the sound stays until it is stopped)</summary>
    procedure AddReal(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3;
      ASfx: TQ3Sfx);
    /// <summary>S_UpdateEntityPosition</summary>
    procedure UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3Vec3);
    /// <summary>The position an entity last had (loopSounds[n].origin)</summary>
    function OriginOf(AEntityNumber: Integer): TQ3Vec3;
    /// <summary>The loop of an entity, for inspection</summary>
    function LoopOf(AEntityNumber: Integer): TQ3LoopSound;
    /// <summary>S_AddLoopSounds: fills LoopChannels and NumLoopChannels of the state</summary>
    procedure BuildLoopChannels;
  end;

implementation

uses
  System.Math;

{ TQ3LoopSounds }

constructor TQ3LoopSounds.Create(AState: TQ3SoundState; AListener: TQ3Listener;
  const AClock: IQ3SoundClock);
begin
  inherited Create;
  FState := AState;
  FListener := AListener;
  FClock := AClock;
  Reset;
end;

procedure TQ3LoopSounds.CheckEntity(AEntityNumber: Integer);
begin
  if (AEntityNumber < 0) or (AEntityNumber >= Q3_MAX_GENTITIES) then
    raise EQ3SoundException.CreateFmt(SQ3BadEntityNumber, [AEntityNumber]);
end;

procedure TQ3LoopSounds.Reset;
begin
  FillChar(FLoops, SizeOf(FLoops), 0);
  FillChar(FState.LoopChannels, SizeOf(FState.LoopChannels), 0);
  FState.NumLoopChannels := 0;
end;

procedure TQ3LoopSounds.Stop(AEntityNumber: Integer);
begin
  CheckEntity(AEntityNumber);
  FLoops[AEntityNumber].Active := False;
  FLoops[AEntityNumber].Kill := False;
end;

procedure TQ3LoopSounds.Clear(AKillAll: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to Q3_MAX_GENTITIES - 1 do
    if AKillAll or FLoops[LIndex].Kill or
      (Assigned(FLoops[LIndex].Sfx) and (FLoops[LIndex].Sfx.SoundLength = 0)) then
    begin
      FLoops[LIndex].Kill := False;
      Stop(LIndex);
    end;
  FState.NumLoopChannels := 0;
end;

function TQ3LoopSounds.DistanceSquared(const AFrom, ATo: TQ3Vec3): Single;
var
  LDelta: TQ3Vec3;
  LTerm: Single;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    LDelta[LIndex] := ATo[LIndex] - AFrom[LIndex];
  Result := LDelta[0] * LDelta[0];
  LTerm := LDelta[1] * LDelta[1];
  Result := Result + LTerm;
  LTerm := LDelta[2] * LDelta[2];
  Result := Result + LTerm;
end;

function TQ3LoopSounds.PrepareLoop(AEntityNumber: Integer; const AOrigin,
  AVelocity: TQ3Vec3; ASfx: TQ3Sfx): Integer;
begin
  CheckEntity(AEntityNumber);
  if ASfx.SoundLength = 0 then
    raise EQ3SoundException.CreateFmt(SQ3SoundHasLengthZero, [ASfx.Name]);
  FLoops[AEntityNumber].Origin := AOrigin;
  FLoops[AEntityNumber].Velocity := AVelocity;
  Result := AEntityNumber;
end;

procedure TQ3LoopSounds.Add(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3;
  ASfx: TQ3Sfx);
var
  LOut: TQ3Vec3;
  LLengthA, LLengthB: Single;
  LDivisor: Single;
  LIndex: Integer;
  LVelocitySquared, LTerm: Single;
begin
  PrepareLoop(AEntityNumber, AOrigin, AVelocity, ASfx);
  FLoops[AEntityNumber].Active := True;
  FLoops[AEntityNumber].Kill := True;
  FLoops[AEntityNumber].Doppler := False;
  FLoops[AEntityNumber].OldDopplerScale := 1.0;
  FLoops[AEntityNumber].DopplerScale := 1.0;
  FLoops[AEntityNumber].Sfx := ASfx;

  LVelocitySquared := AVelocity[0] * AVelocity[0];
  LTerm := AVelocity[1] * AVelocity[1];
  LVelocitySquared := LVelocitySquared + LTerm;
  LTerm := AVelocity[2] * AVelocity[2];
  LVelocitySquared := LVelocitySquared + LTerm;
  if (FState.Doppler <> 0) and (LVelocitySquared > 0.0) then
  begin
    FLoops[AEntityNumber].Doppler := True;
    LLengthA := DistanceSquared(FLoops[FListener.Number].Origin,
      FLoops[AEntityNumber].Origin);
    for LIndex := 0 to 2 do
      LOut[LIndex] := FLoops[AEntityNumber].Origin[LIndex] +
        FLoops[AEntityNumber].Velocity[LIndex];
    LLengthB := DistanceSquared(FLoops[FListener.Number].Origin, LOut);
    if FLoops[AEntityNumber].FrameNumber + 1 <> FClock.FrameCount then
      FLoops[AEntityNumber].OldDopplerScale := 1.0
    else
      FLoops[AEntityNumber].OldDopplerScale := FLoops[AEntityNumber].DopplerScale;
    LDivisor := LLengthA * 100;
    // the C divides by zero when the sound is at the listener: the scale is infinity
    // (the sound moves, so the new position is not at the listener), which is kept, and
    // the sound stays a doppler one
    if LDivisor = 0 then
      FLoops[AEntityNumber].DopplerScale := Single(Infinity)
    else
      FLoops[AEntityNumber].DopplerScale := LLengthB / LDivisor;
    if FLoops[AEntityNumber].DopplerScale <= 1.0 then
      FLoops[AEntityNumber].Doppler := False;
  end;
  FLoops[AEntityNumber].FrameNumber := FClock.FrameCount;
end;

procedure TQ3LoopSounds.AddReal(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3;
  ASfx: TQ3Sfx);
begin
  PrepareLoop(AEntityNumber, AOrigin, AVelocity, ASfx);
  FLoops[AEntityNumber].Sfx := ASfx;
  FLoops[AEntityNumber].Active := True;
  FLoops[AEntityNumber].Kill := False;
  FLoops[AEntityNumber].Doppler := False;
end;

procedure TQ3LoopSounds.UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3Vec3);
begin
  CheckEntity(AEntityNumber);
  FLoops[AEntityNumber].Origin := AOrigin;
end;

function TQ3LoopSounds.OriginOf(AEntityNumber: Integer): TQ3Vec3;
begin
  CheckEntity(AEntityNumber);
  Result := FLoops[AEntityNumber].Origin;
end;

function TQ3LoopSounds.LoopOf(AEntityNumber: Integer): TQ3LoopSound;
begin
  CheckEntity(AEntityNumber);
  Result := FLoops[AEntityNumber];
end;

procedure TQ3LoopSounds.BuildLoopChannels;
var
  LIndex, LOther, LTime: Integer;
  LLeftTotal, LRightTotal, LLeft, LRight: Integer;
begin
  FState.NumLoopChannels := 0;
  LTime := FClock.Milliseconds;
  Inc(FLoopFrame);
  for LIndex := 0 to Q3_MAX_GENTITIES - 1 do
  begin
    // already merged into an earlier sound
    if (not FLoops[LIndex].Active) or (FLoops[LIndex].MergeFrame = FLoopFrame) then
      Continue;

    if FLoops[LIndex].Kill then
      FListener.SpatializeOrigin(FLoops[LIndex].Origin, 127, FState.Dma.Channels,
        LLeftTotal, LRightTotal)
    else
      FListener.SpatializeOrigin(FLoops[LIndex].Origin, 90, FState.Dma.Channels,
        LLeftTotal, LRightTotal);

    FLoops[LIndex].Sfx.LastTimeUsed := LTime;

    for LOther := LIndex + 1 to Q3_MAX_GENTITIES - 1 do
    begin
      if (not FLoops[LOther].Active) or FLoops[LOther].Doppler or
        (FLoops[LOther].Sfx <> FLoops[LIndex].Sfx) then
        Continue;
      FLoops[LOther].MergeFrame := FLoopFrame;
      if FLoops[LOther].Kill then
        FListener.SpatializeOrigin(FLoops[LOther].Origin, 127, FState.Dma.Channels,
          LLeft, LRight)
      else
        FListener.SpatializeOrigin(FLoops[LOther].Origin, 90, FState.Dma.Channels,
          LLeft, LRight);
      FLoops[LOther].Sfx.LastTimeUsed := LTime;
      Inc(LLeftTotal, LLeft);
      Inc(LRightTotal, LRight);
    end;
    // not audible
    if (LLeftTotal = 0) and (LRightTotal = 0) then
      Continue;

    if LLeftTotal > 255 then
      LLeftTotal := 255;
    if LRightTotal > 255 then
      LRightTotal := 255;

    with FState.LoopChannels[FState.NumLoopChannels] do
    begin
      MasterVolume := 127;
      LeftVolume := LLeftTotal;
      RightVolume := LRightTotal;
      Sfx := FLoops[LIndex].Sfx;
      Doppler := FLoops[LIndex].Doppler;
      DopplerScale := FLoops[LIndex].DopplerScale;
      OldDopplerScale := FLoops[LIndex].OldDopplerScale;
    end;
    Inc(FState.NumLoopChannels);
    if FState.NumLoopChannels = Q3_MAX_CHANNELS then
      Exit;
  end;
end;

end.
