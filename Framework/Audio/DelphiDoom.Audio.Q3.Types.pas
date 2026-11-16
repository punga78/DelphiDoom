{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, shared types                   }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Types;

interface

uses
  System.SysUtils, DelphiDoom.Audio.Q3.Sfx;

const
  /// <summary>MAX_CHANNELS</summary>
  Q3_MAX_CHANNELS = 96;
  /// <summary>PAINTBUFFER_SIZE: samples (pairs) of the paint buffer</summary>
  Q3_PAINTBUFFER_SIZE = 4096;
  /// <summary>MAX_RAW_SAMPLES: pairs of the stream for music and video</summary>
  Q3_MAX_RAW_SAMPLES = 16384;
  /// <summary>MAX_GENTITIES</summary>
  Q3_MAX_GENTITIES = 1024;
  /// <summary>START_SAMPLE_IMMEDIATE</summary>
  Q3_START_SAMPLE_IMMEDIATE = $7FFFFFFF;
  /// <summary>SOUND_FULLVOLUME: distance up to which a sound is at full volume</summary>
  Q3_SOUND_FULLVOLUME = 80;
  /// <summary>SOUND_ATTENUATE</summary>
  Q3_SOUND_ATTENUATE: Single = 0.0008;

  // entity channels of q_shared.h
  Q3_CHAN_AUTO = 0;
  Q3_CHAN_LOCAL = 1;
  Q3_CHAN_WEAPON = 2;
  Q3_CHAN_VOICE = 3;
  Q3_CHAN_ITEM = 4;
  Q3_CHAN_BODY = 5;
  Q3_CHAN_LOCAL_SOUND = 6;
  Q3_CHAN_ANNOUNCER = 7;

resourcestring
  SQ3BadEntityNumber = 'S_StartSound: bad entitynum %d';
  SQ3SoundHasLengthZero = '%s has length 0';
  SQ3BadSampleRate = 'S_RawSamples: bad sample rate %d';
  SQ3BadSoundRate = 'Sound with a bad rate: %d';

type
  /// <summary>vec3_t</summary>
  TQ3Vec3 = array[0..2] of Single;
  PQ3Vec3 = ^TQ3Vec3;
  /// <summary>The three axes of the listener (vec3_t axis[3])</summary>
  TQ3Axis = array[0..2] of TQ3Vec3;

  /// <summary>portable_samplepair_t (the values are clamped to +/- $00FFFF00 and shifted down)</summary>
  TQ3SamplePair = record
    Left: Integer;
    Right: Integer;
  end;

  /// <summary>channel_t</summary>
  TQ3Channel = record
    AllocTime: Integer;
    /// <summary>Q3_START_SAMPLE_IMMEDIATE = set on the next mix</summary>
    StartSample: Integer;
    EntityNumber: Integer;
    EntityChannel: Integer;
    /// <summary>0..255 after the spatialization</summary>
    LeftVolume: Integer;
    RightVolume: Integer;
    /// <summary>0..255 before the spatialization</summary>
    MasterVolume: Integer;
    DopplerScale: Single;
    OldDopplerScale: Single;
    Origin: TQ3Vec3;
    FixedOrigin: Boolean;
    /// <summary>thesfx: not owned; nil if the channel is free</summary>
    Sfx: TQ3Sfx;
    Doppler: Boolean;
  end;

  /// <summary>loopSound_t</summary>
  TQ3LoopSound = record
    Origin: TQ3Vec3;
    Velocity: TQ3Vec3;
    Sfx: TQ3Sfx;
    MergeFrame: Integer;
    Active: Boolean;
    Kill: Boolean;
    Doppler: Boolean;
    DopplerScale: Single;
    OldDopplerScale: Single;
    FrameNumber: Integer;
  end;

  /// <summary>dma_t without the buffer (the buffer comes from the device)</summary>
  TQ3DmaInfo = record
    /// <summary>1 mono, 2 stereo</summary>
    Channels: Integer;
    /// <summary>Mono samples in the buffer (a power of two)</summary>
    Samples: Integer;
    /// <summary>8 or 16</summary>
    SampleBits: Integer;
    /// <summary>Samples per second per channel</summary>
    Speed: Integer;
    /// <summary>Do not mix less than this (a power of two)</summary>
    SubmissionChunk: Integer;
  end;

  /// <summary>Raised where Quake III calls Com_Error (ERR_DROP)</summary>
  EQ3SoundException = class(Exception);

  /// <summary>Arithmetic of the C that Delphi does not have</summary>
  TQ3Math = class
  public
    /// <summary>Arithmetic shift to the right (what >> does on a signed int in C)</summary>
    class function Sar(AValue, AShift: Integer): Integer; static;
    /// <summary>
    ///   Conversion of a float to int as the C does it: truncation, and $80000000 when the
    ///   value does not fit (the result of cvttss2si)
    /// </summary>
    class function TruncToInt(AValue: Double): Integer; static;
  end;

implementation

uses
  System.Math;

{ TQ3Math }

class function TQ3Math.Sar(AValue, AShift: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr AShift
  else
    Result := not ((not AValue) shr AShift);
end;

class function TQ3Math.TruncToInt(AValue: Double): Integer;
begin
  // IsNan and IsInfinite look at the bits: no comparison with a NaN, which can trap
  if IsNan(AValue) or IsInfinite(AValue) or (AValue >= 2147483648.0) or
    (AValue <= -2147483649.0) then
    Result := Integer($80000000)
  else
    Result := Trunc(AValue);
end;

end.
