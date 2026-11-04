{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - reads the system and meta events of a track           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Reader.SystemEvent;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Midi.ByteReader;

type
  /// <summary>
  ///   Reads what follows the status byte of the events $F0..$FF, which XMIDI
  ///   and standard MIDI tracks write in the same way
  /// </summary>
  /// <remarks>
  ///   Damaged data is repaired where it can be: a parameter over 127 is
  ///   cut to 127, a length that does not fit in 64 bits is taken as zero,
  ///   the fixed size meta events (SMPTE offset, time and key signature) are
  ///   padded with zeros or cut. A track that ends in the middle of an event
  ///   makes Read answer False and the event is to be dropped
  /// </remarks>
  TXmiSystemEventReader = class
  public
    /// <param name="AReader">Positioned after the status byte</param>
    /// <param name="AEvent">Has its Status set; receives the rest</param>
    /// <param name="AEndOfExclusiveHasData">
    ///   Standard MIDI gives the end of exclusive ($F7) a length and bytes
    ///   like the start ($F0); XMIDI does not
    /// </param>
    /// <returns>False if the data ends in the middle of the event</returns>
    class function Read(AReader: TXmiByteReader; var AEvent: TXmiEvent;
      AEndOfExclusiveHasData: Boolean): Boolean; static;

    /// <summary>
    ///   A parameter of an event: a byte of at most 127
    /// </summary>
    class function ReadParameter(AReader: TXmiByteReader): Byte; static;
  end;

implementation

const
  MAX_PARAMETER = 127;
  MAX_CHANNEL = 15;
  SMPTE_OFFSET_SIZE = 5;
  TIME_SIGNATURE_SIZE = 4;
  KEY_SIGNATURE_SIZE = 2;

function ReadByteOrZero(AReader: TXmiByteReader): Byte;
begin
  if AReader.AtEnd then
    Result := 0
  else
    Result := AReader.ReadByte;
end;

// The length that follows a system exclusive or a meta event. Overflow gives
// length zero and tells the caller not to read the data
function ReadLength(AReader: TXmiByteReader; out ALength: UInt64;
  out AOverflow: Boolean): Boolean;
begin
  Result := True;
  AOverflow := False;
  case AReader.ReadMidiNumber(ALength) of
    TXmiVarLengthStatus.EndOfData:
      Result := False;
    TXmiVarLengthStatus.Overflow:
      begin
        AOverflow := True;
        ALength := 0;
      end;
  end;
end;

// The bytes of a system exclusive or of an unknown meta event. The last
// byte of the track is not taken: the files that end an event there are
// damaged, and it has always been dropped
procedure ReadData(AReader: TXmiByteReader; ALength: UInt64;
  var AEvent: TXmiEvent);
var
  LIndex: UInt64;
  LByte: Byte;
  LCount: Integer;
begin
  LCount := 0;
  LIndex := 0;
  while LIndex < ALength do
  begin
    if AReader.AtEnd then
      Break;
    LByte := AReader.ReadByte;
    if AReader.AtEnd then
      Break;
    SetLength(AEvent.Data, LCount + 1);
    AEvent.Data[LCount] := LByte;
    Inc(LCount);
    Inc(LIndex);
  end;
end;

// The bytes of a meta event with a number inside, most significant first
procedure ReadValue(AReader: TXmiByteReader; ALength: UInt64;
  var AEvent: TXmiEvent);
var
  LIndex: UInt64;
begin
  LIndex := 0;
  while LIndex < ALength do
  begin
    if LIndex > 0 then
      AEvent.Value := AEvent.Value shl 8;
    AEvent.Value := AEvent.Value or ReadByteOrZero(AReader);
    Inc(LIndex);
  end;
end;

// A meta event of a fixed size: the bytes are kept, padded with zeros or cut
procedure ReadFixedData(AReader: TXmiByteReader; ALength: UInt64; ASize: Integer;
  var AEvent: TXmiEvent);
var
  LIndex: UInt64;
  LBytes: TBytes;
begin
  SetLength(LBytes, 0);
  LIndex := 0;
  while LIndex < ALength do
  begin
    SetLength(LBytes, Length(LBytes) + 1);
    LBytes[High(LBytes)] := ReadByteOrZero(AReader);
    Inc(LIndex);
  end;
  SetLength(LBytes, ASize);
  AEvent.Data := LBytes;
end;

procedure ReadText(AReader: TXmiByteReader; ALength: UInt64;
  var AEvent: TXmiEvent);
var
  LBytes: TBytes;
  LCount: Integer;
  LIndex: Integer;
  LTextLength: Integer;
begin
  if ALength > UInt64(AReader.Remaining) then
    LCount := AReader.Remaining
  else
    LCount := Integer(ALength);
  SetLength(LBytes, LCount);
  for LIndex := 0 to LCount - 1 do
    LBytes[LIndex] := AReader.ReadByte;

  // The text ends at the first zero
  LTextLength := 0;
  while (LTextLength < LCount) and (LBytes[LTextLength] <> 0) do
    Inc(LTextLength);
  if LTextLength > 0 then
    SetString(AEvent.Text, PAnsiChar(@LBytes[0]), LTextLength);
end;

// A meta event; False when the data ends in the middle of it
function ReadMeta(AReader: TXmiByteReader; var AEvent: TXmiEvent): Boolean;
var
  LLength: UInt64;
  LOverflow: Boolean;
begin
  Result := False;
  AEvent.Param1 := TXmiSystemEventReader.ReadParameter(AReader);
  if not ReadLength(AReader, LLength, LOverflow) then
    Exit;
  Result := True;
  if LOverflow then
    Exit;

  case AEvent.Param1 of
    XMI_META_SEQUENCE_NUMBER, XMI_META_PORT_PREFIX, XMI_META_TEMPO:
      ReadValue(AReader, LLength, AEvent);
    1..7:
      ReadText(AReader, LLength, AEvent);
    XMI_META_CHANNEL_PREFIX:
      begin
        ReadValue(AReader, LLength, AEvent);
        // A channel prefix is a channel
        if (AEvent.Value < 0) or (AEvent.Value > MAX_CHANNEL) then
          AEvent.Value := 0;
      end;
    XMI_META_SMPTE_OFFSET:
      ReadFixedData(AReader, LLength, SMPTE_OFFSET_SIZE, AEvent);
    XMI_META_TIME_SIGNATURE:
      ReadFixedData(AReader, LLength, TIME_SIGNATURE_SIZE, AEvent);
    XMI_META_KEY_SIGNATURE:
      ReadFixedData(AReader, LLength, KEY_SIGNATURE_SIZE, AEvent);
  else
    ReadData(AReader, LLength, AEvent);
  end;
end;

{ TXmiSystemEventReader }

class function TXmiSystemEventReader.ReadParameter(AReader: TXmiByteReader): Byte;
begin
  Result := AReader.ReadByte;
  if Result > MAX_PARAMETER then
    Result := MAX_PARAMETER;
end;

class function TXmiSystemEventReader.Read(AReader: TXmiByteReader;
  var AEvent: TXmiEvent; AEndOfExclusiveHasData: Boolean): Boolean;
var
  LLength: UInt64;
  LOverflow: Boolean;
  LKind: Integer;
begin
  Result := True;
  LKind := AEvent.Status and 15;
  case LKind of
    0, 7:
      if (LKind = 0) or AEndOfExclusiveHasData then
      begin
        if not ReadLength(AReader, LLength, LOverflow) then
          Exit(False);
        if not LOverflow then
          ReadData(AReader, LLength, AEvent);
      end;
    1, 3:
      AEvent.Param1 := ReadParameter(AReader);
    2:
      begin
        AEvent.Param1 := ReadParameter(AReader);
        AEvent.Param2 := ReadParameter(AReader);
        AEvent.Value := AEvent.Param1 * 128 + AEvent.Param2;
      end;
    15:
      Result := ReadMeta(AReader, AEvent);
  end;
end;

end.
