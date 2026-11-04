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
  DelphiDoom.Xmi.Iff, DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Midi.ByteReader;

const
  XMI_DIVISION = 60;
  MAX_PARAMETER = 127;

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
  LLength: UInt64;

  function ReadParameter: Byte;
  begin
    Result := LReader.ReadByte;
    if Result > MAX_PARAMETER then
      Result := MAX_PARAMETER;
  end;

  function ReadByteOrZero: Byte;
  begin
    if LReader.AtEnd then
      Result := 0
    else
      Result := LReader.ReadByte;
  end;

  // Reads the length that follows a note, a system exclusive or a meta
  // event. False when the data ends in the middle of the event
  function ReadLength(out AOverflow: Boolean): Boolean;
  begin
    Result := True;
    AOverflow := False;
    case LReader.ReadMidiNumber(LLength) of
      TXmiVarLengthStatus.EndOfData:
        Result := False;
      TXmiVarLengthStatus.Overflow:
        begin
          AOverflow := True;
          LLength := 0;
        end;
    end;
  end;

  // The bytes of a system exclusive or of an unknown meta event. The last
  // byte of the track is not taken: the files that end an event there are
  // damaged, and it has always been dropped
  procedure ReadData;
  var
    LIndex: UInt64;
    LByte: Byte;
    LCount: Integer;
  begin
    LCount := 0;
    LIndex := 0;
    while LIndex < LLength do
    begin
      if LReader.AtEnd then
        Break;
      LByte := LReader.ReadByte;
      if LReader.AtEnd then
        Break;
      SetLength(LEvent.Data, LCount + 1);
      LEvent.Data[LCount] := LByte;
      Inc(LCount);
      Inc(LIndex);
    end;
  end;

  // The bytes of a meta event with a number inside, most significant first
  procedure ReadValue;
  var
    LIndex: UInt64;
  begin
    LIndex := 0;
    while LIndex < LLength do
    begin
      if LIndex > 0 then
        LEvent.Value := LEvent.Value shl 8;
      LEvent.Value := LEvent.Value or ReadByteOrZero;
      Inc(LIndex);
    end;
  end;

  // A meta event of a fixed size: the bytes are kept, padded with zeros or cut
  procedure ReadFixedData(ASize: Integer);
  var
    LIndex: UInt64;
    LBytes: TBytes;
  begin
    SetLength(LBytes, 0);
    LIndex := 0;
    while LIndex < LLength do
    begin
      SetLength(LBytes, Length(LBytes) + 1);
      LBytes[High(LBytes)] := ReadByteOrZero;
      Inc(LIndex);
    end;
    SetLength(LBytes, ASize);
    LEvent.Data := LBytes;
  end;

  procedure ReadText;
  var
    LBytes: TBytes;
    LCount: Integer;
    LTextLength: Integer;
  begin
    if LLength > UInt64(LReader.Remaining) then
      LCount := LReader.Remaining
    else
      LCount := Integer(LLength);
    SetLength(LBytes, LCount);
    for LTextLength := 0 to LCount - 1 do
      LBytes[LTextLength] := LReader.ReadByte;

    // The text ends at the first zero
    LTextLength := 0;
    while (LTextLength < LCount) and (LBytes[LTextLength] <> 0) do
      Inc(LTextLength);
    if LTextLength > 0 then
      SetString(LEvent.Text, PAnsiChar(@LBytes[0]), LTextLength);
  end;

  // Reads a meta event; False when the data ends in the middle of it
  function ReadMeta: Boolean;
  var
    LOverflow: Boolean;
  begin
    Result := False;
    LEvent.Param1 := ReadParameter;
    if not ReadLength(LOverflow) then
      Exit;
    Result := True;
    if LOverflow then
      Exit;

    case LEvent.Param1 of
      XMI_META_SEQUENCE_NUMBER, XMI_META_PORT_PREFIX, XMI_META_TEMPO:
        ReadValue;
      1..7:
        ReadText;
      XMI_META_CHANNEL_PREFIX:
        begin
          ReadValue;
          // A channel prefix is a channel
          if (LEvent.Value < 0) or (LEvent.Value > 15) then
          begin
            LEvent.Value := 0;
          end;
        end;
      XMI_META_SMPTE_OFFSET:
        ReadFixedData(5);
      XMI_META_TIME_SIGNATURE:
        ReadFixedData(4);
      XMI_META_KEY_SIGNATURE:
        ReadFixedData(2);
    else
      ReadData;
    end;
  end;

  // Reads what follows the status byte of a system event; False when the
  // data ends in the middle of it
  function ReadSystemEvent: Boolean;
  var
    LOverflow: Boolean;
  begin
    Result := True;
    case LStatus and 15 of
      0:
        begin
          if not ReadLength(LOverflow) then
            Exit(False);
          if not LOverflow then
            ReadData;
        end;
      1, 3:
        LEvent.Param1 := ReadParameter;
      2:
        begin
          LEvent.Param1 := ReadParameter;
          LEvent.Param2 := ReadParameter;
          LEvent.Value := LEvent.Param1 * 128 + LEvent.Param2;
        end;
      15:
        Result := ReadMeta;
    end;
  end;

  // Reads what follows the status byte; False when the data ends in the
  // middle of the event
  function ReadBody: Boolean;
  var
    LOverflow: Boolean;
  begin
    Result := True;
    case LStatus shr 4 of
      9:
        begin
          LEvent.Param1 := ReadParameter;
          LEvent.Param2 := ReadParameter;
          if not ReadLength(LOverflow) then
            Exit(False);
          LEvent.Duration := LLength;
        end;
      10, 11:
        begin
          LEvent.Param1 := ReadParameter;
          LEvent.Param2 := ReadParameter;
        end;
      12, 13:
        LEvent.Param1 := ReadParameter;
      14:
        begin
          LEvent.Param1 := ReadParameter;
          LEvent.Param2 := ReadParameter;
          LEvent.Value := LEvent.Param1 + LEvent.Param2 * 128;
        end;
      15:
        Result := ReadSystemEvent;
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

      // The first track name is the name of the song
      if (LStatus = XMI_STATUS_META) and (LEvent.Param1 = XMI_META_TRACK_NAME) and
         (ATrack.Title = '') and (LEvent.Text <> '') then
        ATrack.Title := LEvent.Text;

      ATrack.Add(LEvent);
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
