{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, shared state                   }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.State;

interface

uses
  DelphiDoom.Audio.Q3.Types;

type
  /// <summary>
  ///   What snd_dma.c keeps in globals and the other files read: the channels, the loop
  ///   channels, the times, the stream of raw samples and the cvars. One instance is
  ///   shared by the classes of one sound system; two systems do not share anything
  /// </summary>
  TQ3SoundState = class
  public
    Channels: array[0..Q3_MAX_CHANNELS - 1] of TQ3Channel;
    LoopChannels: array[0..Q3_MAX_CHANNELS - 1] of TQ3Channel;
    NumLoopChannels: Integer;
    /// <summary>s_soundtime: sample pairs</summary>
    SoundTime: Integer;
    /// <summary>s_paintedtime: sample pairs</summary>
    PaintedTime: Integer;
    /// <summary>s_rawend</summary>
    RawEnd: Integer;
    RawSamples: array[0..Q3_MAX_RAW_SAMPLES - 1] of TQ3SamplePair;
    Dma: TQ3DmaInfo;
    SoundStarted: Boolean;
    SoundMuted: Boolean;
    /// <summary>s_volume (0.8)</summary>
    Volume: Single;
    /// <summary>s_mixahead (0.2)</summary>
    MixAhead: Single;
    /// <summary>s_mixPreStep (0.05)</summary>
    MixPreStep: Single;
    /// <summary>s_doppler (1)</summary>
    Doppler: Integer;
    /// <summary>s_testsound (0)</summary>
    TestSound: Integer;
    constructor Create;
  end;

implementation

{ TQ3SoundState }

constructor TQ3SoundState.Create;
begin
  inherited Create;
  Volume := 0.8;
  MixAhead := 0.2;
  MixPreStep := 0.05;
  Doppler := 1;
end;

end.
