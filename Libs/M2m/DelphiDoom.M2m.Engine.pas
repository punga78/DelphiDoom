{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - the converter, behind the IM2m contract           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.Engine;

interface

uses
  DelphiDoom.M2m.Intf;

type
  /// <summary>
  ///   Implements IM2m on top of the reader, the merger of tracks and the
  ///   converter. It has no state: any number of calls can be made, from any thread
  /// </summary>
  TM2mEngine = class(TInterfacedObject, IM2m)
  public
    function ConvertMidiToMus(AMidi: Pointer; AMidiSize: Cardinal; AMus: Pointer;
      AMusCapacity: Cardinal; out AMusSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.M2m.Converter,
  DelphiDoom.M2m.MidiFile,
  DelphiDoom.M2m.MidiReader,
  DelphiDoom.M2m.TrackMerger;

const
  // A Standard MIDI file of a game is a few tens of kilobytes
  MAX_MIDI_SIZE = 64 * 1024 * 1024;

{ TM2mEngine }

function TM2mEngine.ConvertMidiToMus(AMidi: Pointer; AMidiSize: Cardinal; AMus: Pointer;
  AMusCapacity: Cardinal; out AMusSize: Cardinal): Integer;
var
  LMidi, LMerged: TMidiFile;
  LMus: TBytes;
begin
  AMusSize := 0;
  if not Assigned(AMidi) or (AMidiSize = 0) or (AMidiSize > MAX_MIDI_SIZE) then
    Exit(M2M_ERROR_ARGUMENT);

  try
    LMidi := TMidiReader.Parse(AMidi, Integer(AMidiSize));
    try
      // The tracks of a type 1 file play alongside: they become one
      if LMidi.Mode = 1 then
      begin
        LMerged := TMidiTrackMerger.Merge(LMidi);
        LMidi.Free;
        LMidi := LMerged;
      end;
      LMus := TMidiToMusConverter.Convert(LMidi);
    finally
      LMidi.Free;
    end;

    AMusSize := Length(LMus);
    if AMusSize > AMusCapacity then
      Exit(M2M_ERROR_BUFFER);
    if not Assigned(AMus) then
      Exit(M2M_ERROR_ARGUMENT);
    Move(LMus[0], AMus^, AMusSize);
    Result := M2M_OK;
  except
    on E: EM2mException do
      Result := E.Code;
    on Exception do
      Result := M2M_ERROR_INTERNAL;
  end;
end;

end.
