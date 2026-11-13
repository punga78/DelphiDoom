{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, composition root               }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Factory;

interface

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Audio.Q3.Intf, DelphiDoom.Audio.Q3.SoundSystem;

type
  /// <summary>The only place that knows the classes of the Quake III sound system</summary>
  TQ3SoundSystemFactory = class
  public
    /// <summary>
    ///   Builds a sound system on a device and a clock. ASndfile and AFiles are what
    ///   RegisterSound needs to read WAV files; with nil, sounds are only added to the
    ///   registry (Registry.AddSound). The result owns every class it is made of; call
    ///   Init after it
    /// </summary>
    class function CreateSoundSystem(const ADevice: IQ3SoundDevice; const AClock: IQ3SoundClock;
      const ASndfile: ISndfile; const AFiles: IQ3SoundFileSource): TQ3SoundSystem; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Audio.Q3.State, DelphiDoom.Audio.Q3.Loader,
  DelphiDoom.Audio.Q3.SfxRegistry, DelphiDoom.Audio.Q3.Listener,
  DelphiDoom.Audio.Q3.ChannelPool, DelphiDoom.Audio.Q3.LoopSounds,
  DelphiDoom.Audio.Q3.RawStream, DelphiDoom.Audio.Q3.Mixer, DelphiDoom.Audio.Q3.Scheduler;

{ TQ3SoundSystemFactory }

class function TQ3SoundSystemFactory.CreateSoundSystem(const ADevice: IQ3SoundDevice;
  const AClock: IQ3SoundClock; const ASndfile: ISndfile;
  const AFiles: IQ3SoundFileSource): TQ3SoundSystem;
var
  LState: TQ3SoundState;
  LLoader: TQ3SoundLoader;
  LRegistry: TQ3SfxRegistry;
  LListener: TQ3Listener;
  LPool: TQ3ChannelPool;
  LLoops: TQ3LoopSounds;
  LRaw: TQ3RawStream;
  LMixer: TQ3Mixer;
  LScheduler: TQ3Scheduler;
  LSystem: TQ3SoundSystem;
begin
  LState := TQ3SoundState.Create;
  LLoader := nil;
  if Assigned(ASndfile) then
    LLoader := TQ3SoundLoader.Create(ASndfile);
  LRegistry := TQ3SfxRegistry.Create(LState, LLoader, AFiles);
  LListener := TQ3Listener.Create;
  LPool := TQ3ChannelPool.Create(LState, AClock, LListener);
  LLoops := TQ3LoopSounds.Create(LState, LListener, AClock);
  LRaw := TQ3RawStream.Create(LState);
  LMixer := TQ3Mixer.Create(LState, ADevice);
  LSystem := nil;
  LScheduler := TQ3Scheduler.Create(LState, ADevice, AClock, LPool, LMixer,
    procedure
    begin
      LSystem.StopAllSounds;
    end);
  LSystem := TQ3SoundSystem.Create(LState, ADevice, LRegistry, LListener, LPool, LLoops,
    LRaw, LMixer, LScheduler);
  LSystem.Own(LState);
  if Assigned(LLoader) then
    LSystem.Own(LLoader);
  LSystem.Own(LRegistry);
  LSystem.Own(LListener);
  LSystem.Own(LPool);
  LSystem.Own(LLoops);
  LSystem.Own(LRaw);
  LSystem.Own(LMixer);
  LSystem.Own(LScheduler);
  Result := LSystem;
end;

end.
