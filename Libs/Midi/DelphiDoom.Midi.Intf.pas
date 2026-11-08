{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - contracts                                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Midi.Types;

type
  /// <summary>
  ///   Turns a Standard MIDI file into the blocks of events that the midi stream of Windows
  ///   plays: the bytes of MIDIEVENT records, 12 bytes each. It calls nothing of the system:
  ///   the device (the stream, its callback, its buffers) is the caller's
  /// </summary>
  /// <remarks>
  ///   One sequencer plays one song: Load once, then ask for one block after the other. A block
  ///   ends when it is full (a buffer of the caller) or when it has covered about 60
  ///   milliseconds of the song
  /// </remarks>
  IMidiStreamSequencer = interface
    ['{7D2A4E19-3B86-4C05-A1F7-5E90C8B6D342}']
    function GetTimeDivision: Word;
    function GetLooped: Boolean;
    procedure SetLooped(AValue: Boolean);
    function GetTempoPercent: Cardinal;
    procedure SetTempoPercent(AValue: Cardinal);

    /// <summary>
    ///   Reads the file and puts the song at its start. False, with a warning to the log, if
    ///   the bytes are not a Standard MIDI file that can be read: the sequencer is then empty
    /// </summary>
    function Load(AData: Pointer; ASize: Integer): Boolean;
    /// <summary>
    ///   The next block of events, as many as fit in AMaxLength bytes. AReset forgets what a
    ///   block left half done (an event that did not fit) but not the position in the song:
    ///   the first block of a stream asks for it. mcrDone, with no bytes, once the song is over
    ///   and it does not loop; a song that loops starts again from its beginning
    /// </summary>
    function ConvertBlock(AReset: Boolean; AMaxLength: Integer;
      out ABytes: TBytes): TMidiConvertResult;
    /// <summary>The song goes back to its first event</summary>
    procedure Rewind;
    /// <summary>The next event written is preceded by an event with the current tempo</summary>
    procedure RequestTempoEvent;

    /// <summary>The division word of the file as it is: ticks per quarter note or SMPTE</summary>
    property TimeDivision: Word read GetTimeDivision;
    /// <summary>At the end the song starts again (false when it is created)</summary>
    property Looped: Boolean read GetLooped write SetLooped;
    /// <summary>The speed of the song, 100 is the one of the file (zero is read as one)</summary>
    property TempoPercent: Cardinal read GetTempoPercent write SetTempoPercent;
  end;

  /// <summary>Makes a sequencer for every song: the player of the engine owns one at a time</summary>
  IMidiStreamSequencerFactory = interface
    ['{E1B58C73-0A94-4D2F-8B6E-3F7A19D50C84}']
    function CreateSequencer: IMidiStreamSequencer;
  end;

implementation

end.
