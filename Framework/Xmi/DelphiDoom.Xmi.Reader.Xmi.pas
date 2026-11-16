{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI - reads an Extended MIDI (XMIDI) file                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Reader.Xmi;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Song, DelphiDoom.Xmi.Midi.Track;

type
  /// <summary>
  ///   Reads the songs of an XMIDI file: an IFF file with a FORM XDIR (the
  ///   header, with the number of songs) followed by a CAT XMID that holds a
  ///   FORM XMID per song, or just FORM XMID groups one after the other
  /// </summary>
  /// <remarks>
  ///   The events keep the form of the file: the notes carry their duration
  ///   and there are no Note Off events (see TXmiXmiToMidiConverter). A song
  ///   becomes a track of the TXmiSong; the division is 60 ticks per quarter
  ///   note and the tempo the standard one, which makes 120 ticks a second
  /// </remarks>
  TXmiXmiReader = class
  private
    class procedure ReadEvents(const AData: TBytes; AOffset, ASize: Cardinal;
      ATrack: TXmiTrack); static;
  public
    /// <summary>
    ///   Raises EXmiDataException if the data has no XMIDI headers
    /// </summary>
    class function Read(const AData: TBytes): TXmiSong; static;
  end;

implementation

uses
  DelphiDoom.Xmi.Iff, DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Midi.ByteReader,
  DelphiDoom.Xmi.Reader.SystemEvent;

const
  XMI_DIVISION = 60;

type
  TTrackLocation = record
    Offset: Cardinal;
    Size: Cardinal;
  end;

{ TXmiXmiReader }

class procedure TXmiXmiReader.ReadEvents(const AData: TBytes; AOffset,
  ASize: Cardinal; ATrack: TXmiTrack);
var
  LReader: TXmiByteReader;
  LEvent: TXmiEvent;
  LTicks: UInt64;
  LStatus: Byte;

  // Reads what follows the status byte; False when the data ends in the
  // middle of the event
  function ReadBody: Boolean;
  var
    LDuration: UInt64;
  begin
    Result := True;
    case LStatus shr 4 of
      9:
        begin
          LEvent.Param1 := TXmiSystemEventReader.ReadParameter(LReader);
          LEvent.Param2 := TXmiSystemEventReader.ReadParameter(LReader);
          // The duration of the note; a number too long is taken as zero
          case LReader.ReadMidiNumber(LDuration) of
            TXmiVarLengthStatus.EndOfData:
              Exit(False);
            TXmiVarLengthStatus.Overflow:
              LDuration := 0;
          end;
          LEvent.Duration := LDuration;
        end;
      10, 11:
        begin
          LEvent.Param1 := TXmiSystemEventReader.ReadParameter(LReader);
          LEvent.Param2 := TXmiSystemEventReader.ReadParameter(LReader);
        end;
      12, 13:
        LEvent.Param1 := TXmiSystemEventReader.ReadParameter(LReader);
      14:
        begin
          LEvent.Param1 := TXmiSystemEventReader.ReadParameter(LReader);
          LEvent.Param2 := TXmiSystemEventReader.ReadParameter(LReader);
          LEvent.Value := LEvent.Param1 + LEvent.Param2 * 128;
        end;
      15:
        Result := TXmiSystemEventReader.Read(LReader, LEvent, False);
    end;
  end;

begin
  LReader := TXmiByteReader.Create(AData, AOffset, ASize);
  try
    while not LReader.AtEnd do
    begin
      case LReader.ReadXmiDelay(LTicks) of
        TXmiVarLengthStatus.EndOfData:
          Break;
        TXmiVarLengthStatus.Overflow:
          Continue;
      end;
      if LReader.AtEnd then
        Break;

      LStatus := LReader.ReadByte;
      LEvent := Default(TXmiEvent);
      LEvent.Ticks := LTicks;
      LEvent.Status := LStatus;

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
  finally
    LReader.Free;
  end;
end;

class function TXmiXmiReader.Read(const AData: TBytes): TXmiSong;
var
  LNodes: TXmiIffNodes;
  LGroup: TXmiIffNodes;
  LSongs: TXmiIffNodes;
  LInfo: TXmiIffNodes;
  LEvents: TXmiIffNodes;
  LLocations: TArray<TTrackLocation>;
  LTrackCount: Word;
  LIndex: Integer;
  LSize: Int64;
  LTrack: TXmiTrack;

  procedure AddLocation(const ASong: TXmiIffNode);
  var
    LContent: TXmiIffNodes;
  begin
    LContent := TXmiIff.GetNodes(AData, ASong.DataOffset, ASong.Size);
    LEvents := TXmiIff.Search(LContent, 'EVNT');
    SetLength(LLocations, Length(LLocations) + 1);
    if Length(LEvents) > 0 then
    begin
      LLocations[High(LLocations)].Offset := LEvents[0].DataOffset;
      LLocations[High(LLocations)].Size := LEvents[0].Size;
    end
    else
    begin
      LLocations[High(LLocations)].Offset := ASong.DataOffset;
      LLocations[High(LLocations)].Size := 0;
    end;
  end;

begin
  LLocations := nil;
  LNodes := TXmiIff.GetNodes(AData, 0, Length(AData));

  if TXmiIff.Count(LNodes, 'CAT ', 'XMID') > 0 then
  begin
    // The usual file: a header with the number of songs, then the songs
    if (Length(LNodes) > 0) and (LNodes[0].Name = 'FORM') and
       (LNodes[0].Sub = 'XDIR') then
    begin
      LTrackCount := 0;
      LGroup := TXmiIff.GetNodes(AData, LNodes[0].DataOffset, LNodes[0].Size);
      LInfo := TXmiIff.Search(LGroup, 'INFO');
      if (Length(LInfo) > 0) and (LInfo[0].Size >= 2) and
         (Int64(LInfo[0].DataOffset) + LInfo[0].Size <= Length(AData)) then
        LTrackCount := Word(AData[LInfo[0].DataOffset] or
          (AData[LInfo[0].DataOffset + 1] shl 8));

      LGroup := TXmiIff.Search(LNodes, 'CAT ', 'XMID');
      LNodes := TXmiIff.GetNodes(AData, LGroup[0].DataOffset, LGroup[0].Size);
      LSongs := TXmiIff.Search(LNodes, 'FORM', 'XMID');
      if LTrackCount > 0 then
      begin
        if Length(LSongs) < LTrackCount then
          LTrackCount := Length(LSongs);
      end
      else
        LTrackCount := Length(LSongs);

      for LIndex := 0 to LTrackCount - 1 do
        AddLocation(LSongs[LIndex]);
    end;
  end
  else if TXmiIff.Count(LNodes, 'FORM', 'XMID') > 0 then
  begin
    // The songs one after the other, without header
    LSongs := TXmiIff.Search(LNodes, 'FORM', 'XMID');
    for LIndex := 0 to High(LSongs) do
      AddLocation(LSongs[LIndex]);
  end
  else
    raise EXmiDataException.Create('XMIDI headers not found');

  Result := TXmiSong.Create;
  try
    Result.InitialTempo := XMI_MIDI_STANDARD_TEMPO;
    Result.Smpte := 0;
    Result.Division := XMI_DIVISION;
    Result.MidiType := XMI_MIDI_TYPE_MULTI_SONG;

    for LIndex := 0 to High(LLocations) do
    begin
      // The size of a song that runs beyond the file is cut to the file
      if Int64(LLocations[LIndex].Offset) + LLocations[LIndex].Size > Length(AData) then
      begin
        LSize := Int64(Length(AData)) - LLocations[LIndex].Offset;
        if LSize < 0 then
          Continue;
        LLocations[LIndex].Size := Cardinal(LSize);
      end;

      LTrack := Result.AddTrack;
      ReadEvents(AData, LLocations[LIndex].Offset, LLocations[LIndex].Size, LTrack);
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
