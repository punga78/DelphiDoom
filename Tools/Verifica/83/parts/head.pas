{ The code of TMidi (Base\i_midi_new.pas of the commit before the MIDI library, kept in
  old_i_midi_new.txt) with what plays on the device taken out: the conversion of the events into
  the buffers of the midi stream is the text of the old unit, line by line.
  Made by MakeOldMidi.bat from parts\ and old_i_midi_new.txt: do not edit by hand. }
unit OldMidiNew;

{$Q-}
{$R-}
{$H+}
{$J+}
{$ALIGN 8}
{$WARN SYMBOL_DEPRECATED OFF}

interface

uses
  System.SysUtils,
  OldMidiShims;

type
  /// <summary>
  ///   How the song is played. omTempo is Play(True) with the pointer of the inserted tempo
  ///   event corrected, omTempoLegacy is the same with the pointer as it was
  /// </summary>
  TOldMode = (omLooped, omTempo, omTempoLegacy, omOnce);

  TOldRun = record
    Failed: Boolean;
    Blocks: TArray<TOldBlock>;
  end;

function OldMidiRun(const AData: TBytes; AMode: TOldMode; ARounds: Integer): TOldRun;

implementation

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.MMSystem;

