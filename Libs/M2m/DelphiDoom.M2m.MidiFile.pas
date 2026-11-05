{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - a Standard MIDI file in memory                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.MidiFile;

interface

uses
  DelphiDoom.M2m.Types;

type
  /// <summary>
  ///   The tracks of a Standard MIDI file and the header that says how to
  ///   read their times
  /// </summary>
  TMidiFile = class
  public
    /// <summary>0 single track, 1 tracks alongside, 2 tracks one after the other</summary>
    Mode: Integer;
    /// <summary>24, 25, 29, 30 or 0 when the times are not in SMPTE frames</summary>
    SmpteFps: Integer;
    /// <summary>Clocks per frame, or clocks per quarter note when SmpteFps is 0</summary>
    Timing: Integer;
    Tracks: TArray<TMidiTrack>;
  end;

implementation

end.
