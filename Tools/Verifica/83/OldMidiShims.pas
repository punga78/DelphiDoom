{ What the old i_midi_new needed from the engine (i_system, d_main, i_midi, d_delphi), written
  again so that the old code compiles alone in the program that records its blocks.
  The program is not part of the build: see RUN.md in the root of the repository. }
unit OldMidiShims;

interface

uses
  Winapi.Windows,
  System.SysUtils;

const
  MThd = $6468544D; // Start of file
  MTrk = $6B72544D; // Start of track
  MIDI_CTRLCHANGE: Byte = $B0; // + ctrlr + value
  MIDICTRL_VOLUME: Byte = $07;

type
  EOldMidiError = class(Exception);

  /// <summary>One block that the old ConvertToBuffer wrote: its code (0 no error, 1 done)</summary>
  TOldBlock = record
    Code: Integer;
    Bytes: TBytes;
  end;

var
  devparm: Boolean = False;
  debugfile: Pointer = nil;
  /// <summary>
  ///   True: the tempo event inserted by Play is followed by the next event 12 bytes later (the
  ///   old code moved a pointer to a record of 16 bytes by 12 steps: 192 bytes)
  /// </summary>
  GFixTempoPointer: Boolean = True;
  /// <summary>The blocks of the setup, written by the replaced StreamBufferSetup</summary>
  GSetupBlocks: TArray<TOldBlock>;

procedure I_Error(const error: string; const Args: array of const); overload;
procedure I_Error(const error: string); overload;
procedure fprintf(f: Pointer; const fmt: string; const A: array of const);
function I_SelectDefaultMidiDevice: LongWord;
function GetIntegerInRange(const x: integer; const a, b: integer): integer;

implementation

procedure I_Error(const error: string; const Args: array of const);
begin
  raise EOldMidiError.Create(Format(error, Args));
end;

procedure I_Error(const error: string);
begin
  raise EOldMidiError.Create(error);
end;

procedure fprintf(f: Pointer; const fmt: string; const A: array of const);
begin
end;

function I_SelectDefaultMidiDevice: LongWord;
begin
  Result := $FFFFFFFF;
end;

function GetIntegerInRange(const x: integer; const a, b: integer): integer;
begin
  if x < a then
    Result := a
  else if x > b then
    Result := b
  else
    Result := x;
end;

end.
