{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - 3D sound of Doom 3, shared types                }
{                                                                              }
{  Port of the data of sound\sound.h, snd_local.h, snd_system.cpp (the cvars   }
{  and their defaults) and renderer\RenderWorld.h (exitPortal_t).              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.D3.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>DOOM_TO_METERS: sound.h</summary>
  D3_DOOM_TO_METERS: Single = 0.0254;
  /// <summary>METERS_TO_DOOM: 1.0f / DOOM_TO_METERS</summary>
  D3_METERS_TO_DOOM: Single = 1.0 / 0.0254;
  /// <summary>SND_EPSILON: below this a volume always multiplies to zero</summary>
  D3_SND_EPSILON: Single = 1.0 / 32768.0;
  /// <summary>MIXBUFFER_SAMPLES: the samples of a mixing block</summary>
  D3_MIXBUFFER_SAMPLES = 4096;
  /// <summary>MAX_PORTAL_TRACE_DEPTH: how many portals a sound goes through</summary>
  D3_MAX_PORTAL_TRACE_DEPTH = 10;

  /// <summary>PS_BLOCK_VIEW and PS_BLOCK_AIR of RenderWorld.h: a portal that blocks them occludes sound</summary>
  D3_PS_BLOCK_VIEW = 1;
  D3_PS_BLOCK_AIR = 4;

  /// <summary>The soundShaderFlags of sound.h (the values of <c>DelphiDoom.Decl.Sound.Types</c>)</summary>
  D3_SSF_PRIVATE_SOUND = 1 shl 0;
  D3_SSF_ANTI_PRIVATE_SOUND = 1 shl 1;
  D3_SSF_NO_OCCLUSION = 1 shl 2;
  D3_SSF_GLOBAL = 1 shl 3;
  D3_SSF_OMNIDIRECTIONAL = 1 shl 4;
  D3_SSF_LOOPING = 1 shl 5;
  D3_SSF_PLAY_ONCE = 1 shl 6;
  D3_SSF_UNCLAMPED = 1 shl 7;
  D3_SSF_NO_FLICKER = 1 shl 8;
  D3_SSF_NO_DUPS = 1 shl 9;

type
  /// <summary>The cvars of the sound system that the 3D mixing reads (snd_system.cpp, with the defaults)</summary>
  TD3SoundCvars = record
    /// <summary>s_volume_dB</summary>
    VolumeDb: Single;
    /// <summary>s_quadraticFalloff</summary>
    QuadraticFalloff: Boolean;
    /// <summary>s_useOcclusion</summary>
    UseOcclusion: Boolean;
    /// <summary>s_doorDistanceAdd: the distance added when a sound goes through a portal that blocks view or air</summary>
    DoorDistanceAdd: Single;
    /// <summary>s_dotbias6</summary>
    DotBias6: Single;
    /// <summary>s_minVolume6</summary>
    MinVolume6: Single;
    /// <summary>s_dotbias2</summary>
    DotBias2: Single;
    /// <summary>s_minVolume2</summary>
    MinVolume2: Single;
    /// <summary>s_spatializationDecay</summary>
    SpatializationDecay: Single;
    /// <summary>s_subFraction: the volume of the subwoofer in 5.1</summary>
    SubFraction: Single;
    /// <summary>s_globalFraction: the volume to all speakers when not spatialized</summary>
    GlobalFraction: Single;
    /// <summary>s_clipVolumes</summary>
    ClipVolumes: Boolean;
    /// <summary>s_playDefaultSound: a beep for missing sounds</summary>
    PlayDefaultSound: Boolean;
    /// <summary>s_slowAttenuate</summary>
    SlowAttenuate: Boolean;
    class function Defaults: TD3SoundCvars; static;
  end;

  /// <summary>
  ///   exitPortal_t: a portal of the render world between two areas, with the polygon of its opening (the points of
  ///   <c>idWinding</c>, at least three) and what it blocks
  /// </summary>
  TD3ExitPortal = record
    Areas: array[0..1] of Integer;
    BlockingBits: Integer;
    Points: TArray<TIdVec3>;
  end;

  /// <summary>
  ///   The part of <c>idSoundEmitterLocal</c> that spatialization reads and writes: where the emitter is (in Doom
  ///   units), the loudest range of its channels, and what <c>Spatialize</c> works out
  /// </summary>
  TD3EmitterSpace = record
    /// <summary>origin, in Doom units</summary>
    Origin: TIdVec3;
    /// <summary>maxDistance: the largest maxDistance of the playing channels, in meters</summary>
    MaxDistance: Single;
    /// <summary>realDistance: the straight distance to the listener, in meters</summary>
    RealDistance: Single;
    /// <summary>distance: the distance through the portals, in meters (Doom units while it is searched)</summary>
    Distance: Single;
    /// <summary>spatializedOrigin: where the sound seems to come from, in Doom units</summary>
    SpatializedOrigin: TIdVec3;
    /// <summary>lastValidPortalArea</summary>
    LastValidPortalArea: Integer;
    class function Init(const AOrigin: TIdVec3; AMaxDistance: Single): TD3EmitterSpace; static;
  end;

implementation

{ TD3SoundCvars }

class function TD3SoundCvars.Defaults: TD3SoundCvars;
begin
  Result.VolumeDb := 0;
  Result.QuadraticFalloff := True;
  Result.UseOcclusion := True;
  Result.DoorDistanceAdd := 150;
  Result.DotBias6 := 0.8;
  Result.MinVolume6 := 0;
  Result.DotBias2 := 1.1;
  Result.MinVolume2 := 0.25;
  Result.SpatializationDecay := 2;
  Result.SubFraction := 0.75;
  Result.GlobalFraction := 0.8;
  Result.ClipVolumes := True;
  Result.PlayDefaultSound := True;
  Result.SlowAttenuate := True;
end;

{ TD3EmitterSpace }

class function TD3EmitterSpace.Init(const AOrigin: TIdVec3; AMaxDistance: Single): TD3EmitterSpace;
begin
  Result := Default(TD3EmitterSpace);
  Result.Origin := AOrigin;
  Result.MaxDistance := AMaxDistance;
  Result.LastValidPortalArea := -1;
end;

end.
