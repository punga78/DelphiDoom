{******************************************************************************}
{                                                                              }
{  DelphiDoom: CMF - reads the events of a standard MIDI track                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Reader.MidiTrack;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Track, DelphiDoom.Xmi.Midi.ByteReader;

type
  /// <summary>
  ///   Reads the events of a track written the way standard MIDI files do:
  ///   a delay, then a status byte that can be left out when it is the one of
  ///   the event before (running status)
  /// </summary>
  TXmiMidiTrackReader = class
  public
    /// <summary>
    ///   Reads until the data ends. A track that ends in the middle of an
    ///   event drops the event; bytes that start with no status to follow
    ///   are skipped
    /// </summary>
    class procedure Read(AReader: TXmiByteReader; ATrack: TXmiTrack); static;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Reader.SystemEvent;

{ TXmiMidiTrackReader }

class procedure TXmiMidiTrackReader.Read(AReader: TXmiByteReader;
  ATrack: TXmiTrack);
var
  LEvent: TXmiEvent;
  LTicks: UInt64;
  LByte: Byte;
  LStatus: Byte;
  LHasStatus: Boolean;
  LReadTicks: Boolean;
  LRunning: Boolean;

  // Reads what follows the status byte; False when the data ends in the
  // middle of the event
  function ReadBody: Boolean;
  begin
    Result := True;
    case LStatus shr 4 of
      8..11:
        begin
          LEvent.Param1 := TXmiSystemEventReader.ReadParameter(AReader);
          LEvent.Param2 := TXmiSystemEventReader.ReadParameter(AReader);
        end;
      12, 13:
        LEvent.Param1 := TXmiSystemEventReader.ReadParameter(AReader);
      14:
        begin
          LEvent.Param1 := TXmiSystemEventReader.ReadParameter(AReader);
          LEvent.Param2 := TXmiSystemEventReader.ReadParameter(AReader);
          LEvent.Value := LEvent.Param1 + LEvent.Param2 * 128;
        end;
      15:
        Result := TXmiSystemEventReader.Read(AReader, LEvent, True);
    end;
  end;

begin
  LHasStatus := False;
  LReadTicks := True;
  LTicks := 0;
  while not AReader.AtEnd do
  begin
    if LReadTicks then
    begin
      case AReader.ReadMidiNumber(LTicks) of
        TXmiVarLengthStatus.EndOfData:
          Break;
        TXmiVarLengthStatus.Overflow:
          Continue;
      end;
      if AReader.AtEnd then
        Break;
    end;

    LByte := AReader.ReadByte;
    if (LByte < 128) and not LHasStatus then
    begin
      // A data byte with no status to apply it to: skipped, and the
      // next byte is not preceded by a delay
      LReadTicks := False;
      Continue;
    end;
    LReadTicks := True;

    LEvent := Default(TXmiEvent);
    LEvent.Ticks := LTicks;
    LRunning := False;
    if LByte >= 128 then
    begin
      LStatus := LByte;
      LHasStatus := True;
    end
    else
    begin
      // The status of the event before applies; the byte just read is the
      // first of its data
      LStatus := ATrack[ATrack.Count - 1].Status;
      LRunning := True;
      AReader.StepBack;
    end;
    LEvent.Status := LStatus;
    LEvent.RunningStatus := LRunning;

    try
      if not ReadBody then
        Break;
    except
      // The data ends inside a parameter: the event is incomplete
      on EXmiDataException do
        Break;
    end;

    ATrack.AddRead(LEvent);
  end;
end;

end.
