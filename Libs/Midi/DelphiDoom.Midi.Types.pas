{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - types and constants shared by the classes         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.Types;

interface

type
  /// <summary>
  ///   An event of the midi stream of Windows (MIDIEVENT without the parameters of a long
  ///   event): 12 bytes, little endian. The layout is the one of the buffers that the stream
  ///   plays, so a block of events is its bytes
  /// </summary>
  TMidiStreamEvent = packed record
    /// <summary>Ticks since the last event</summary>
    Time: Cardinal;
    /// <summary>Always zero</summary>
    StreamId: Cardinal;
    case Integer of
      0: (Data: packed array[0..2] of Byte; EventType: Byte);
      1: (Event: Cardinal);
  end;

  PMidiStreamEvent = ^TMidiStreamEvent;

  /// <summary>What a conversion pass of the sequencer says</summary>
  TMidiConvertResult = (
    /// <summary>The block holds the events of this pass (it may be empty)</summary>
    mcrNoError,
    /// <summary>The song is over and it does not loop: there is nothing more</summary>
    mcrDone
  );

  /// <summary>The kind of an event of the song once the tracks are merged</summary>
  TMidiSequenceEventKind = (
    /// <summary>A channel message: status, and two data bytes (the second is zero if it has none)</summary>
    mskChannel,
    /// <summary>A system exclusive event: it is not played</summary>
    mskSystemExclusive,
    /// <summary>A change of tempo: Tempo is the microseconds of a quarter note</summary>
    mskTempo,
    /// <summary>A meta event that the stream does not use</summary>
    mskOtherMeta
  );

  /// <summary>An event of the merged song, at an absolute time in ticks</summary>
  TMidiSequenceEvent = record
    Time: Cardinal;
    Kind: TMidiSequenceEventKind;
    Status: Byte;
    Data1: Byte;
    Data2: Byte;
    Tempo: Cardinal;
  end;

const
  /// <summary>The first word of a Standard MIDI file: MThd</summary>
  MIDI_FILE_ID = $6468544D;

  MIDI_CONTROL_CHANGE = $B0;
  MIDI_CONTROLLER_VOLUME = $07;

  /// <summary>The flag of an event of the stream that asks for a callback when it is reached</summary>
  MIDI_STREAM_CALLBACK = $40000000;
  /// <summary>The type of the events of the stream that change the tempo (MEVT_TEMPO)</summary>
  MIDI_STREAM_TEMPO = $01;

  /// <summary>The bytes of an event of the stream</summary>
  MIDI_STREAM_EVENT_SIZE = 12;

  /// <summary>The volume of a song is 100 percent when it starts</summary>
  MIDI_VOLUME_FULL = 100;
  /// <summary>The value of the volume controller that is 100 percent</summary>
  MIDI_CONTROLLER_MAXIMUM = 127;

implementation

end.
