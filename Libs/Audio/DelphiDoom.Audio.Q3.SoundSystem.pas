{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound system (snd_dma.c)              }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.SoundSystem;

interface

uses
  System.Generics.Collections, DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx,
  DelphiDoom.Audio.Q3.Intf, DelphiDoom.Audio.Q3.State,
  DelphiDoom.Audio.Q3.SfxRegistry, DelphiDoom.Audio.Q3.Listener,
  DelphiDoom.Audio.Q3.ChannelPool, DelphiDoom.Audio.Q3.LoopSounds,
  DelphiDoom.Audio.Q3.RawStream, DelphiDoom.Audio.Q3.Mixer,
  DelphiDoom.Audio.Q3.Scheduler;

type
  /// <summary>
  ///   The entry points of the sound system of Quake III with the names of snd_public.h:
  ///   S_Init, S_RegisterSound, S_StartSound, S_StartLocalSound, S_AddLoopingSound,
  ///   S_Respatialize, S_RawSamples, S_Update... Each does what the C does and hands the
  ///   work to the class that owns it. The background track (S_StartBackgroundTrack,
  ///   S_UpdateBackgroundTrack, files of music read from the disk) is not part of it: a
  ///   stream is fed through RawSamples
  /// </summary>
  TQ3SoundSystem = class
  strict private
    FState: TQ3SoundState;
    FDevice: IQ3SoundDevice;
    FRegistry: TQ3SfxRegistry;
    FListener: TQ3Listener;
    FPool: TQ3ChannelPool;
    FLoops: TQ3LoopSounds;
    FRaw: TQ3RawStream;
    FMixer: TQ3Mixer;
    FScheduler: TQ3Scheduler;
    FOwned: TObjectList<TObject>;
  public
    /// <summary>The collaborators are not owned unless they are given to Own</summary>
    constructor Create(AState: TQ3SoundState; const ADevice: IQ3SoundDevice;
      ARegistry: TQ3SfxRegistry; AListener: TQ3Listener; APool: TQ3ChannelPool;
      ALoops: TQ3LoopSounds; ARaw: TQ3RawStream; AMixer: TQ3Mixer; AScheduler: TQ3Scheduler);
    destructor Destroy; override;
    /// <summary>Gives an object to the system, which frees it with itself</summary>
    procedure Own(AObject: TObject);
    /// <summary>S_Init after SNDDMA_Init succeeded: takes the format of the device, muted</summary>
    procedure Init;
    /// <summary>S_Shutdown</summary>
    procedure Shutdown;
    /// <summary>S_BeginRegistration: sounds can play again</summary>
    procedure BeginRegistration;
    /// <summary>S_DisableSounds: stops everything and mutes until BeginRegistration</summary>
    procedure DisableSounds;
    /// <summary>S_RegisterSound (the sound is never compressed)</summary>
    function RegisterSound(const AName: string): Integer;
    /// <summary>
    ///   S_StartSound. AOrigin nil = follow the entity (then the entity number must be
    ///   0..1023). A handle out of range is ignored, as in the C
    /// </summary>
    procedure StartSound(AOrigin: PQ3Vec3; AEntityNumber, AEntityChannel, ASfxHandle: Integer);
    /// <summary>S_StartLocalSound: a sound of the listener, at full volume</summary>
    procedure StartLocalSound(ASfxHandle, AChannelNumber: Integer);
    /// <summary>S_ClearSoundBuffer: no loops, free channels, empty stream, silent buffer</summary>
    procedure ClearSoundBuffer;
    /// <summary>S_StopAllSounds (without the background track)</summary>
    procedure StopAllSounds;
    procedure ClearLoopingSounds(AKillAll: Boolean);
    procedure AddLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3;
      ASfxHandle: Integer);
    procedure AddRealLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3Vec3;
      ASfxHandle: Integer);
    procedure StopLoopingSound(AEntityNumber: Integer);
    /// <summary>S_UpdateEntityPosition</summary>
    procedure UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3Vec3);
    /// <summary>
    ///   S_Respatialize: moves the listener, recomputes the volumes of the running sounds
    ///   and rebuilds the loop channels (AInWater is unused, as in the C)
    /// </summary>
    procedure Respatialize(AEntityNumber: Integer; const AHead: TQ3Vec3;
      const AAxis: TQ3Axis; AInWater: Integer);
    /// <summary>S_RawSamples on a buffer in memory</summary>
    procedure RawSamples(ASamples, ARate, AWidth, AChannels: Integer; AData: PByte;
      AVolume: Single);
    /// <summary>S_Update (the background track is not read)</summary>
    procedure Update;
    property State: TQ3SoundState read FState;
    property Registry: TQ3SfxRegistry read FRegistry;
    property Listener: TQ3Listener read FListener;
    property Pool: TQ3ChannelPool read FPool;
    property Loops: TQ3LoopSounds read FLoops;
    property Raw: TQ3RawStream read FRaw;
    property Mixer: TQ3Mixer read FMixer;
    property Scheduler: TQ3Scheduler read FScheduler;
  end;

implementation

{ TQ3SoundSystem }

constructor TQ3SoundSystem.Create(AState: TQ3SoundState; const ADevice: IQ3SoundDevice;
  ARegistry: TQ3SfxRegistry; AListener: TQ3Listener; APool: TQ3ChannelPool;
  ALoops: TQ3LoopSounds; ARaw: TQ3RawStream; AMixer: TQ3Mixer; AScheduler: TQ3Scheduler);
begin
  inherited Create;
  FState := AState;
  FDevice := ADevice;
  FRegistry := ARegistry;
  FListener := AListener;
  FPool := APool;
  FLoops := ALoops;
  FRaw := ARaw;
  FMixer := AMixer;
  FScheduler := AScheduler;
  FOwned := TObjectList<TObject>.Create(True);
end;

destructor TQ3SoundSystem.Destroy;
begin
  FOwned.Free;
  inherited Destroy;
end;

procedure TQ3SoundSystem.Own(AObject: TObject);
begin
  FOwned.Add(AObject);
end;

procedure TQ3SoundSystem.Init;
begin
  FState.Dma := FDevice.Dma;
  FState.SoundStarted := True;
  FState.SoundMuted := True;
  FState.SoundTime := 0;
  FState.PaintedTime := 0;
  StopAllSounds;
end;

procedure TQ3SoundSystem.Shutdown;
begin
  FState.SoundStarted := False;
end;

procedure TQ3SoundSystem.BeginRegistration;
begin
  FState.SoundMuted := False;
end;

procedure TQ3SoundSystem.DisableSounds;
begin
  StopAllSounds;
  FState.SoundMuted := True;
end;

function TQ3SoundSystem.RegisterSound(const AName: string): Integer;
begin
  Result := FRegistry.RegisterSound(AName);
end;

procedure TQ3SoundSystem.StartSound(AOrigin: PQ3Vec3; AEntityNumber, AEntityChannel,
  ASfxHandle: Integer);
var
  LSfx: TQ3Sfx;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;
  if (not Assigned(AOrigin)) and ((AEntityNumber < 0) or (AEntityNumber >= Q3_MAX_GENTITIES)) then
    raise EQ3SoundException.CreateFmt(SQ3BadEntityNumber, [AEntityNumber]);
  LSfx := FRegistry.SfxOf(ASfxHandle);
  if LSfx = nil then
    Exit;
  if not LSfx.InMemory then
    FRegistry.EnsureLoaded(LSfx);
  FPool.StartSound(AOrigin, AEntityNumber, AEntityChannel, LSfx);
end;

procedure TQ3SoundSystem.StartLocalSound(ASfxHandle, AChannelNumber: Integer);
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;
  if FRegistry.SfxOf(ASfxHandle) = nil then
    Exit;
  StartSound(nil, FListener.Number, AChannelNumber, ASfxHandle);
end;

procedure TQ3SoundSystem.ClearSoundBuffer;
var
  LClear: Byte;
  LBuffer: PByte;
begin
  if not FState.SoundStarted then
    Exit;

  // stop looping sounds
  FLoops.Reset;
  FPool.Reset;
  FState.RawEnd := 0;

  if FState.Dma.SampleBits = 8 then
    LClear := $80
  else
    LClear := 0;

  FDevice.BeginPainting;
  LBuffer := FDevice.GetBuffer;
  if Assigned(LBuffer) then
    FillChar(LBuffer^, FState.Dma.Samples * FState.Dma.SampleBits div 8, LClear);
  FDevice.Submit;
end;

procedure TQ3SoundSystem.StopAllSounds;
begin
  if not FState.SoundStarted then
    Exit;
  ClearSoundBuffer;
end;

procedure TQ3SoundSystem.ClearLoopingSounds(AKillAll: Boolean);
begin
  FLoops.Clear(AKillAll);
end;

procedure TQ3SoundSystem.AddLoopingSound(AEntityNumber: Integer; const AOrigin,
  AVelocity: TQ3Vec3; ASfxHandle: Integer);
var
  LSfx: TQ3Sfx;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;
  LSfx := FRegistry.SfxOf(ASfxHandle);
  if LSfx = nil then
    Exit;
  if not LSfx.InMemory then
    FRegistry.EnsureLoaded(LSfx);
  FLoops.Add(AEntityNumber, AOrigin, AVelocity, LSfx);
end;

procedure TQ3SoundSystem.AddRealLoopingSound(AEntityNumber: Integer; const AOrigin,
  AVelocity: TQ3Vec3; ASfxHandle: Integer);
var
  LSfx: TQ3Sfx;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;
  LSfx := FRegistry.SfxOf(ASfxHandle);
  if LSfx = nil then
    Exit;
  if not LSfx.InMemory then
    FRegistry.EnsureLoaded(LSfx);
  FLoops.AddReal(AEntityNumber, AOrigin, AVelocity, LSfx);
end;

procedure TQ3SoundSystem.StopLoopingSound(AEntityNumber: Integer);
begin
  FLoops.Stop(AEntityNumber);
end;

procedure TQ3SoundSystem.UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3Vec3);
begin
  FLoops.UpdateEntityPosition(AEntityNumber, AOrigin);
end;

procedure TQ3SoundSystem.Respatialize(AEntityNumber: Integer; const AHead: TQ3Vec3;
  const AAxis: TQ3Axis; AInWater: Integer);
var
  LIndex: Integer;
  LOrigin: TQ3Vec3;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;

  FListener.Place(AEntityNumber, AHead, AAxis);

  // update spatialization for dynamic sounds
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
  begin
    if FState.Channels[LIndex].Sfx = nil then
      Continue;
    // anything coming from the view entity will always be full volume
    if FState.Channels[LIndex].EntityNumber = FListener.Number then
    begin
      FState.Channels[LIndex].LeftVolume := FState.Channels[LIndex].MasterVolume;
      FState.Channels[LIndex].RightVolume := FState.Channels[LIndex].MasterVolume;
    end
    else
    begin
      if FState.Channels[LIndex].FixedOrigin then
        LOrigin := FState.Channels[LIndex].Origin
      else
        LOrigin := FLoops.OriginOf(FState.Channels[LIndex].EntityNumber);
      FListener.SpatializeOrigin(LOrigin, FState.Channels[LIndex].MasterVolume,
        FState.Dma.Channels, FState.Channels[LIndex].LeftVolume,
        FState.Channels[LIndex].RightVolume);
    end;
  end;

  // add loopsounds
  FLoops.BuildLoopChannels;
end;

procedure TQ3SoundSystem.RawSamples(ASamples, ARate, AWidth, AChannels: Integer;
  AData: PByte; AVolume: Single);
begin
  FRaw.RawSamples(ASamples, ARate, AWidth, AChannels, AData, AVolume);
end;

procedure TQ3SoundSystem.Update;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;
  FScheduler.Update;
end;

end.
