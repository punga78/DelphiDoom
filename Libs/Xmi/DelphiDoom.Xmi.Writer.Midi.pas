{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - writes a song as a standard MIDI file             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Writer.Midi;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Xmi.Midi.Song,
  DelphiDoom.Xmi.Midi.Track;

type
  /// <summary>
  ///   Writes the events of a song, already in standard MIDI form, as the
  ///   bytes of a standard MIDI file
  /// </summary>
  TXmiMidiWriter = class
  private
    class procedure WriteNumber(AStream: TStream; AValue: UInt64); static;
    class procedure WriteBigEndian16(AStream: TStream; AValue: Word); static;
    class procedure WriteBigEndian32(AStream: TStream; AValue: Cardinal); static;
    class procedure WriteByte(AStream: TStream; AValue: Byte); static;
    class procedure WriteBytes(AStream: TStream; const ABytes: TBytes); static;
    class procedure WriteMeta(AStream: TStream; AEvent: PXmiEvent); static;
    class procedure WriteTrack(AStream: TStream; ATrack: TXmiTrack); static;
  public
    /// <summary>
    ///   A song of type 0 writes its first track only
    /// </summary>
    class function Write(ASong: TXmiSong): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types;

const
  HEADER_TAG: array[0..3] of AnsiChar = 'MThd';
  TRACK_TAG: array[0..3] of AnsiChar = 'MTrk';
  HEADER_LENGTH = 6;

{ TXmiMidiWriter }

class procedure TXmiMidiWriter.WriteByte(AStream: TStream; AValue: Byte);
begin
  AStream.WriteBuffer(AValue, 1);
end;

class procedure TXmiMidiWriter.WriteBytes(AStream: TStream; const ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

class procedure TXmiMidiWriter.WriteBigEndian16(AStream: TStream; AValue: Word);
begin
  WriteByte(AStream, Byte(AValue shr 8));
  WriteByte(AStream, Byte(AValue and $FF));
end;

class procedure TXmiMidiWriter.WriteBigEndian32(AStream: TStream; AValue: Cardinal);
begin
  WriteByte(AStream, Byte(AValue shr 24));
  WriteByte(AStream, Byte((AValue shr 16) and $FF));
  WriteByte(AStream, Byte((AValue shr 8) and $FF));
  WriteByte(AStream, Byte(AValue and $FF));
end;

class procedure TXmiMidiWriter.WriteNumber(AStream: TStream; AValue: UInt64);
var
  LGroups: array[0..9] of Byte;
  LCount: Integer;
  LIndex: Integer;
begin
  // Seven bits at a time, the least significant first...
  LCount := 0;
  repeat
    LGroups[LCount] := Byte(AValue and 127);
    Inc(LCount);
    AValue := AValue shr 7;
  until AValue = 0;

  // ...written the other way round, all but the last with the high bit
  for LIndex := LCount - 1 downto 0 do
  begin
    if LIndex > 0 then
      WriteByte(AStream, LGroups[LIndex] or 128)
    else
      WriteByte(AStream, LGroups[LIndex]);
  end;
end;

class procedure TXmiMidiWriter.WriteMeta(AStream: TStream; AEvent: PXmiEvent);
var
  LBytes: TBytes;
begin
  WriteByte(AStream, AEvent.Param1);
  case AEvent.Param1 of
    XMI_META_SEQUENCE_NUMBER:
      begin
        SetLength(LBytes, 2);
        LBytes[0] := Byte((AEvent.Value shr 8) and $FF);
        LBytes[1] := Byte(AEvent.Value and $FF);
        WriteNumber(AStream, Length(LBytes));
        WriteBytes(AStream, LBytes);
      end;
    1..7:
      begin
        WriteNumber(AStream, Length(AEvent.Text));
        if Length(AEvent.Text) > 0 then
          AStream.WriteBuffer(PAnsiChar(AEvent.Text)^, Length(AEvent.Text));
      end;
    XMI_META_CHANNEL_PREFIX, XMI_META_PORT_PREFIX:
      begin
        WriteNumber(AStream, 1);
        WriteByte(AStream, Byte(AEvent.Value and $FF));
      end;
    XMI_META_TEMPO:
      begin
        SetLength(LBytes, 3);
        LBytes[0] := Byte((AEvent.Value shr 16) and $FF);
        LBytes[1] := Byte((AEvent.Value shr 8) and $FF);
        LBytes[2] := Byte(AEvent.Value and $FF);
        WriteNumber(AStream, Length(LBytes));
        WriteBytes(AStream, LBytes);
      end;
  else
    WriteNumber(AStream, Length(AEvent.Data));
    WriteBytes(AStream, AEvent.Data);
  end;
end;

class procedure TXmiMidiWriter.WriteTrack(AStream: TStream; ATrack: TXmiTrack);
var
  LIndex: Integer;
  LEvent: PXmiEvent;
begin
  for LIndex := 0 to ATrack.Count - 1 do
  begin
    LEvent := ATrack.EventAt(LIndex);
    WriteNumber(AStream, LEvent.Ticks);

    // The status byte is left out when it is the one of the event before
    if LIndex = 0 then
      LEvent.RunningStatus := False
    else if LEvent.Status <> ATrack.EventAt(LIndex - 1).Status then
      LEvent.RunningStatus := False;
    if LEvent.Status >= $F0 then
      LEvent.RunningStatus := False;
    if not LEvent.RunningStatus then
      WriteByte(AStream, LEvent.Status);

    case LEvent.Status shr 4 of
      8..11:
        begin
          WriteByte(AStream, LEvent.Param1);
          WriteByte(AStream, LEvent.Param2);
        end;
      12, 13:
        WriteByte(AStream, LEvent.Param1);
      14:
        begin
          LEvent.Param1 := Byte(LEvent.Value and 127);
          LEvent.Param2 := Byte((LEvent.Value shr 7) and 127);
          WriteByte(AStream, LEvent.Param1);
          WriteByte(AStream, LEvent.Param2);
        end;
      15:
        case LEvent.Status and 15 of
          0, 7:
            begin
              WriteNumber(AStream, Length(LEvent.Data));
              WriteBytes(AStream, LEvent.Data);
            end;
          1, 3:
            WriteByte(AStream, LEvent.Param1);
          2:
            begin
              LEvent.Param1 := Byte((LEvent.Value shr 7) and 127);
              LEvent.Param2 := Byte(LEvent.Value and 127);
              WriteByte(AStream, LEvent.Param1);
              WriteByte(AStream, LEvent.Param2);
            end;
          15:
            WriteMeta(AStream, LEvent);
        end;
    end;
  end;
end;

class function TXmiMidiWriter.Write(ASong: TXmiSong): TBytes;
var
  LStream: TMemoryStream;
  LTrackStream: TMemoryStream;
  LTrackCount: Integer;
  LIndex: Integer;
begin
  LStream := TMemoryStream.Create;
  try
    if ASong.MidiType = XMI_MIDI_TYPE_SINGLE_TRACK then
      LTrackCount := Ord(ASong.Tracks.Count > 0)
    else
      LTrackCount := ASong.Tracks.Count;

    LStream.WriteBuffer(HEADER_TAG, SizeOf(HEADER_TAG));
    WriteBigEndian32(LStream, HEADER_LENGTH);
    WriteBigEndian16(LStream, ASong.MidiType);
    WriteBigEndian16(LStream, LTrackCount);
    if ASong.Smpte >= 0 then
      WriteBigEndian16(LStream, ASong.Division)
    else
    begin
      WriteByte(LStream, Byte(ASong.Smpte));
      WriteByte(LStream, Byte(ASong.Division and $FF));
    end;

    for LIndex := 0 to LTrackCount - 1 do
    begin
      LTrackStream := TMemoryStream.Create;
      try
        WriteTrack(LTrackStream, ASong.Tracks[LIndex]);
        LStream.WriteBuffer(TRACK_TAG, SizeOf(TRACK_TAG));
        WriteBigEndian32(LStream, Cardinal(LTrackStream.Size));
        if LTrackStream.Size > 0 then
          LStream.WriteBuffer(LTrackStream.Memory^, LTrackStream.Size);
      finally
        LTrackStream.Free;
      end;
    end;

    SetLength(Result, LStream.Size);
    if LStream.Size > 0 then
      Move(LStream.Memory^, Result[0], LStream.Size);
  finally
    LStream.Free;
  end;
end;

end.
