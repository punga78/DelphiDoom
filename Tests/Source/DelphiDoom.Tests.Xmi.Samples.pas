{******************************************************************************}
{                                                                              }
{  DelphiDoom: songs built in memory for the tests of the XMI/CMF library      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Samples;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Minimal valid songs, byte by byte, so that the tests need no files
  /// </summary>
  TXmiSamples = class
  private
    class procedure WriteTag(AStream: TStream; const ATag: AnsiString); static;
    class procedure WriteBigEndian32(AStream: TStream; AValue: Cardinal); static;
    class procedure WriteLittleEndian16(AStream: TStream; AValue: Word); static;
    class procedure WriteBytes(AStream: TStream; const ABytes: array of Byte); static;
  public
    /// <summary>
    ///   XMI with one song: FORM XDIR (INFO: 1 track) + CAT XMID with one
    ///   FORM XMID whose EVNT has a program change and the end of track
    /// </summary>
    class function BuildXmi: TBytes; static;

    /// <summary>
    ///   CMF version 1.0 without instruments, with the same two events
    /// </summary>
    class function BuildCmf: TBytes; static;

    /// <summary>
    ///   Header of a standard MIDI file (14 bytes) and a minimal track
    /// </summary>
    class function BuildMidi: TBytes; static;

    /// <summary>
    ///   Signature of a Sopepos file: enough to be recognized, not to be
    ///   converted
    /// </summary>
    class function BuildSopHeader: TBytes; static;

    /// <summary>
    ///   Bytes that belong to no format
    /// </summary>
    class function BuildGarbage(ASize: Integer): TBytes; static;

    /// <summary>
    ///   The four characters at AOffset, or '' if the data is shorter
    /// </summary>
    class function TagAt(const AData: TBytes; AOffset: Integer): string; static;
  end;

implementation

const
  // Delta 0 + program change (channel 0, program 5), delta 0 + end of track
  SONG_EVENTS: array[0..6] of Byte = ($00, $C0, $05, $00, $FF, $2F, $00);

{ TXmiSamples }

class procedure TXmiSamples.WriteTag(AStream: TStream; const ATag: AnsiString);
begin
  AStream.WriteBuffer(PAnsiChar(ATag)^, Length(ATag));
end;

class procedure TXmiSamples.WriteBigEndian32(AStream: TStream; AValue: Cardinal);
begin
  WriteBytes(AStream, [Byte(AValue shr 24), Byte(AValue shr 16),
    Byte(AValue shr 8), Byte(AValue)]);
end;

class procedure TXmiSamples.WriteLittleEndian16(AStream: TStream; AValue: Word);
begin
  WriteBytes(AStream, [Byte(AValue), Byte(AValue shr 8)]);
end;

class procedure TXmiSamples.WriteBytes(AStream: TStream;
  const ABytes: array of Byte);
begin
  AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

class function TXmiSamples.BuildXmi: TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    // FORM XDIR: 'XDIR' + INFO chunk (8 bytes of header + 2 of data) = 14
    WriteTag(LStream, 'FORM');
    WriteBigEndian32(LStream, 14);
    WriteTag(LStream, 'XDIR');
    WriteTag(LStream, 'INFO');
    WriteBigEndian32(LStream, 2);
    WriteLittleEndian16(LStream, 1);

    // CAT XMID: 'XMID' + FORM chunk (8 + 20) = 32
    WriteTag(LStream, 'CAT ');
    WriteBigEndian32(LStream, 32);
    WriteTag(LStream, 'XMID');

    // FORM XMID: 'XMID' + EVNT chunk (8 + 7 + 1 byte of padding) = 20
    WriteTag(LStream, 'FORM');
    WriteBigEndian32(LStream, 20);
    WriteTag(LStream, 'XMID');
    WriteTag(LStream, 'EVNT');
    WriteBigEndian32(LStream, Length(SONG_EVENTS));
    WriteBytes(LStream, SONG_EVENTS);
    WriteBytes(LStream, [$00]);

    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TXmiSamples.BuildCmf: TBytes;
const
  HEADER_SIZE = 36;
  // Header, then the byte with the number of instruments, then the music
  MUSIC_OFFSET = HEADER_SIZE + 1;
var
  LStream: TBytesStream;
  LChannel: Integer;
begin
  LStream := TBytesStream.Create;
  try
    WriteTag(LStream, 'CTMF');
    WriteLittleEndian16(LStream, $0100);       // version 1.0
    WriteLittleEndian16(LStream, 0);           // offset of the instruments
    WriteLittleEndian16(LStream, MUSIC_OFFSET);
    WriteLittleEndian16(LStream, 48);          // ticks per quarter note
    WriteLittleEndian16(LStream, 96);          // ticks per second
    WriteLittleEndian16(LStream, 0);           // offset of the title
    WriteLittleEndian16(LStream, 0);           // offset of the composer
    WriteLittleEndian16(LStream, 0);           // offset of the remarks
    for LChannel := 0 to 15 do
      WriteBytes(LStream, [$00]);              // channels in use
    WriteBytes(LStream, [$00]);                // number of instruments
    WriteBytes(LStream, SONG_EVENTS);

    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TXmiSamples.BuildMidi: TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    WriteTag(LStream, 'MThd');
    WriteBigEndian32(LStream, 6);
    WriteBytes(LStream, [$00, $00, $00, $01, $00, $60]);
    WriteTag(LStream, 'MTrk');
    WriteBigEndian32(LStream, Length(SONG_EVENTS));
    WriteBytes(LStream, SONG_EVENTS);

    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TXmiSamples.BuildSopHeader: TBytes;
const
  SOP_MIN_SIZE = $4C;
begin
  SetLength(Result, SOP_MIN_SIZE);
  FillChar(Pointer(Result)^, SOP_MIN_SIZE, 0);
  Move(PAnsiChar('sopepos')^, Pointer(Result)^, 7);
  Result[8] := 1;
end;

class function TXmiSamples.BuildGarbage(ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  // Bytes above $7F: no chunk name, no signature of any format
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := Byte($80 or ((LIndex * 13 + 1) and $7F));
end;

class function TXmiSamples.TagAt(const AData: TBytes; AOffset: Integer): string;
var
  LTag: AnsiString;
begin
  if (AOffset < 0) or (AOffset + 4 > Length(AData)) then
    Exit('');

  SetString(LTag, PAnsiChar(@AData[AOffset]), 4);
  Result := string(LTag);
end;

end.
