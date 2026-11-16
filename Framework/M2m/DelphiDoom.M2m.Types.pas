{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - the events and tracks of a MIDI file              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.Types;

interface

type
  /// <summary>
  ///   The kind of a MIDI event; the value of an event read with a running
  ///   status that has no previous event is metNone
  /// </summary>
  TMidiEventType = (
    metNoteOff,
    metNoteOn,
    metNoteAftertouch,
    metController,
    metProgramChange,
    metChannelAftertouch,
    metPitchBend,
    metMeta,
    metSysEx,
    metSysExContinuation,
    metNone);

  /// <summary>One event of a track, with the time that has gone since the one before it</summary>
  TMidiEvent = record
    Delta: Cardinal;
    EventType: TMidiEventType;
    Channel: Integer;
    /// <summary>The key, the controller or the program; for a meta event its type</summary>
    Param1: Integer;
    Param2: Integer;
    /// <summary>The bytes of a meta or system exclusive event</summary>
    Data: TArray<Byte>;
  end;

  TMidiTrack = record
    Events: TArray<TMidiEvent>;
  end;

const
  // Types of meta events
  META_ENDTRACK = $2F;
  META_TEMPO = $51;
  META_SEQUENCER_EVENT = $7F;

  // Controllers that MUS can express
  CONTROLLER_BANKSELECT = 0;
  CONTROLLER_MODWHEEL = 1;
  CONTROLLER_CHANNELVOLUME = 7;
  CONTROLLER_PAN = 10;
  CONTROLLER_EXPRESSION = 11;
  CONTROLLER_LSB_OFFSET = 32;
  CONTROLLER_SUSTAIN = 64;
  CONTROLLER_SOFTPEDAL = 67;
  CONTROLLER_REVERB = 91;
  CONTROLLER_CHORUS = 93;
  CONTROLLER_ALL_SOUND_OFF = 120;
  CONTROLLER_RESET_ALL = 121;
  CONTROLLER_ALL_NOTES_OFF = 123;
  CONTROLLER_MONO_ON = 126;
  CONTROLLER_POLY_ON = 127;

implementation

end.
