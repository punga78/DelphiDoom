{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - types shared by the readers and the converters    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Midi.Types;

interface

uses
  System.SysUtils;

const
  // Tempo of a song that does not say otherwise: 500000 microseconds per
  // quarter note
  XMI_MIDI_STANDARD_TEMPO = 500000;

  // Status of the events that are not tied to a channel
  XMI_STATUS_SYSEX = $F0;
  XMI_STATUS_META = $FF;

  // Meta events
  XMI_META_SEQUENCE_NUMBER = 0;
  XMI_META_TRACK_NAME = 3;
  XMI_META_CHANNEL_PREFIX = 32;
  XMI_META_PORT_PREFIX = 33;
  XMI_META_END_OF_TRACK = 47;
  XMI_META_TEMPO = 81;
  XMI_META_SMPTE_OFFSET = 84;
  XMI_META_TIME_SIGNATURE = 88;
  XMI_META_KEY_SIGNATURE = 89;

  // The types of MIDI file
  XMI_MIDI_TYPE_SINGLE_TRACK = 0;
  XMI_MIDI_TYPE_MULTI_SONG = 2;

type
  /// <summary>
  ///   What the conversion of a song can end with
  /// </summary>
  TXmiConversionStatus = (Ok, UnknownFormat, BadData, TrackOutOfRange,
    OutOfMemory);

  /// <summary>
  ///   Raised by the readers when the data of a song is damaged beyond what
  ///   can be repaired. Never leaves the converter
  /// </summary>
  EXmiDataException = class(Exception);

  /// <summary>
  ///   One event of a track, in the form every format is read into and every
  ///   converter works on
  /// </summary>
  /// <remarks>
  ///   Ticks is the delay from the previous event. For the channel events
  ///   Status is the MIDI status byte; for the system ones $F0..$FF, and for
  ///   a meta event ($FF) Param1 is its type. Value holds the numbers of the
  ///   events that have one (pitch bend, tempo, channel prefix...), Data the
  ///   bytes of the system exclusive and unknown meta events, Text the text
  ///   of the meta events 1..7
  /// </remarks>
  TXmiEvent = record
    Ticks: UInt64;
    Status: Byte;
    Param1: Byte;
    Param2: Byte;
    Value: Int64;
    /// <summary>Duration of an XMI note, in ticks</summary>
    Duration: UInt64;
    Data: TBytes;
    Text: AnsiString;
    /// <summary>
    ///   The event may omit its status byte when the one before has the same
    ///   (MIDI running status)
    /// </summary>
    RunningStatus: Boolean;
  end;

  PXmiEvent = ^TXmiEvent;

implementation

end.
