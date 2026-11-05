{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds AU and VOC files in memory  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.ContainerFiles;

interface

uses
  System.SysUtils;

type
  TSoundTestAuOptions = record
    BigEndian: Boolean;
    /// <summary>Code of the encoding in the header (1 mu-law, 2..5 PCM, 6 float, 7 double, 27 A-law)</summary>
    Encoding: Cardinal;
    Channels: Cardinal;
    SampleRate: Cardinal;
    /// <summary>Zero bytes between the 24 byte header and the data</summary>
    Padding: Integer;
    /// <summary>Size written in the header; -2 for the real one</summary>
    DataSize: Int64;
    class function Plain(AEncoding, AChannels: Cardinal): TSoundTestAuOptions; static;
  end;

  TSoundTestVocOptions = record
    /// <summary>Block 8 before the sound (stereo or not, a rate of its own)</summary>
    Extended: Boolean;
    Stereo: Boolean;
    /// <summary>Block 9 instead of block 1: with this encoding, bits and channels</summary>
    ExtendedII: Boolean;
    Encoding: Word;
    BitsPerSample: Byte;
    Channels: Byte;
    TextBlockFirst: Boolean;
    OmitTerminator: Boolean;
    Version: Word;
    class function Plain: TSoundTestVocOptions; static;
  end;

  TSoundTestAiffOptions = record
    /// <summary>FORM type AIFC, with the encoding in the COMM chunk</summary>
    Aifc: Boolean;
    /// <summary>Four characters, only for AIFC</summary>
    Encoding: AnsiString;
    Channels: Word;
    SampleSize: Word;
    /// <summary>Chunks between the COMM and the SSND chunk: NAME (odd length) and an unknown one</summary>
    ChunksBeforeData: Boolean;
    /// <summary>An ANNO chunk of odd length after the data</summary>
    ChunkAfterData: Boolean;
    /// <summary>Bytes of the SSND chunk between its header and the sound</summary>
    SsndOffset: Cardinal;
    /// <summary>Size written in the SSND chunk; -2 for the real one</summary>
    SsndSize: Int64;
    OmitComm: Boolean;
    OmitSsnd: Boolean;
    class function Plain(AChannels, ASampleSize: Word): TSoundTestAiffOptions; static;
    class function Compressed(const AEncoding: AnsiString; AChannels,
      ASampleSize: Word): TSoundTestAiffOptions; static;
  end;

  TSoundTestContainerFile = class
  public
    class function BuildAiff(const AOptions: TSoundTestAiffOptions;
      const APayload: TBytes): TBytes; static;
    /// <summary>
    ///   W64 with a 'fmt ' chunk of ATag; AFact adds a 'fact' chunk before the
    ///   data and AJunk a 'junk' chunk after it
    /// </summary>
    class function BuildW64(ATag, AChannels, ABits: Word; ARate: Cardinal;
      AFact, AJunk: Boolean; const APayload: TBytes): TBytes; static;
    /// <summary>
    ///   RF64: ADs64 puts the sizes in a 'ds64' chunk (with ADataLength in it,
    ///   -2 for the real one) and writes $FFFFFFFF as the size of the data
    /// </summary>
    class function BuildRf64(ATag, AChannels, ABits: Word; ARate: Cardinal;
      ADs64: Boolean; ADataLength: Int64; const APayload: TBytes): TBytes; static;
    /// <summary>AVR: ARate hertz, AMono as in the header (0 mono, 65535 stereo)</summary>
    /// <summary>
    ///   CAF with a 'desc' chunk of the given kind; AFree adds a 'free' chunk
    ///   before the data and AInfoAfter an 'info' chunk after it
    /// </summary>
    class function BuildCaf(const AFormatId: AnsiString; AFlags, APacketBytes,
      AChannels, ABits: Cardinal; ARate: Double; AFree, AInfoAfter: Boolean;
      const APayload: TBytes): TBytes; static;    /// <summary>SVX: 8SVX or 16SV, with optional NAME, ANNO and CHAN chunks before the BODY</summary>
    class function BuildSvx(A16Bit: Boolean; ARate: Word; ACompression: Byte;
      AChannelChunk, AExtraChunks: Boolean; const APayload: TBytes): TBytes; static;
    /// <summary>
    ///   IRCAM: the fields are written big endian when ABigFields; AMarker are
    ///   the first four bytes
    /// </summary>
    class function BuildIrcam(const AMarker: array of Byte; ABigFields: Boolean;
      ARate: Single; AChannels, AEncoding: Cardinal; const APayload: TBytes): TBytes; static;    class function BuildAvr(AMono, AResolution, ASign: Word; ARate: Cardinal;
      const APayload: TBytes): TBytes; static;
    /// <summary>HTK: ACount is the sample count written; -1 for the real one</summary>
    class function BuildHtk(ACount: Int64; APeriod, AKind: Cardinal;
      const APayload: TBytes): TBytes; static;
    class function BuildAu(const AOptions: TSoundTestAuOptions;
      const APayload: TBytes): TBytes; static;
    class function BuildVoc(const AOptions: TSoundTestVocOptions;
      const APayload: TBytes): TBytes; static;
  end;

implementation

type
  TSink = record
    Bytes: TBytes;
    procedure Add(AValue: Byte);
    procedure AddText(const AText: AnsiString);
    procedure AddNumber(AValue: Cardinal; AByteCount: Integer; ABigEndian: Boolean);
    procedure AddBytes(const AValues: TBytes);
  end;

{ TSink }

procedure TSink.Add(AValue: Byte);
begin
  SetLength(Bytes, Length(Bytes) + 1);
  Bytes[High(Bytes)] := AValue;
end;

procedure TSink.AddText(const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    Add(Byte(AText[LIndex]));
end;

procedure TSink.AddNumber(AValue: Cardinal; AByteCount: Integer;
  ABigEndian: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AByteCount - 1 do
    if ABigEndian then
      Add(Byte(AValue shr (8 * (AByteCount - 1 - LIndex))))
    else
      Add(Byte(AValue shr (8 * LIndex)));
end;

procedure TSink.AddBytes(const AValues: TBytes);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AValues) do
    Add(AValues[LIndex]);
end;

{ TSoundTestAuOptions }

class function TSoundTestAuOptions.Plain(AEncoding,
  AChannels: Cardinal): TSoundTestAuOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Encoding := AEncoding;
  Result.Channels := AChannels;
  Result.SampleRate := 8000;
  Result.DataSize := -2;
end;

{ TSoundTestVocOptions }

class function TSoundTestVocOptions.Plain: TSoundTestVocOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Version := $010A;
  Result.Channels := 1;
  Result.BitsPerSample := 8;
end;

{ TSoundTestAiffOptions }

class function TSoundTestAiffOptions.Plain(AChannels,
  ASampleSize: Word): TSoundTestAiffOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Encoding := '';
  Result.Channels := AChannels;
  Result.SampleSize := ASampleSize;
  Result.SsndSize := -2;
end;

class function TSoundTestAiffOptions.Compressed(const AEncoding: AnsiString;
  AChannels, ASampleSize: Word): TSoundTestAiffOptions;
begin
  Result := Plain(AChannels, ASampleSize);
  Result.Aifc := True;
  Result.Encoding := AEncoding;
end;

{ TSoundTestContainerFile }

class function TSoundTestContainerFile.BuildW64(ATag, AChannels, ABits: Word;
  ARate: Cardinal; AFact, AJunk: Boolean; const APayload: TBytes): TBytes;
const
  GUID_TAIL: array[0..11] of Byte = ($F3, $AC, $D3, $11, $8C, $D1, $00, $C0, $4F, $8E, $DB, $8A);
  RIFF_TAIL: array[0..11] of Byte = ($2E, $91, $CF, $11, $A5, $D6, $28, $DB, $04, $C1, $00, $00);
var
  LSink: TSink;
  LIndex: Integer;

  procedure AddGuid(const AName: AnsiString; const ATail: array of Byte);
  var
    LTailIndex: Integer;
  begin
    LSink.AddText(AName);
    for LTailIndex := 0 to High(ATail) do
      LSink.Add(ATail[LTailIndex]);
  end;

  procedure AddInt64(AValue: Int64);
  begin
    LSink.AddNumber(Cardinal(AValue and $FFFFFFFF), 4, False);
    LSink.AddNumber(Cardinal(AValue shr 32), 4, False);
  end;

  procedure Align;
  begin
    while (Length(LSink.Bytes) and 7) <> 0 do
      LSink.Add(0);
  end;

begin
  AddGuid('riff', RIFF_TAIL);
  AddInt64(0);
  AddGuid('wave', GUID_TAIL);

  AddGuid('fmt ', GUID_TAIL);
  AddInt64(24 + 16);
  LSink.AddNumber(ATag, 2, False);
  LSink.AddNumber(AChannels, 2, False);
  LSink.AddNumber(ARate, 4, False);
  LSink.AddNumber(ARate * AChannels * ((ABits + 7) div 8), 4, False);
  LSink.AddNumber(AChannels * ((ABits + 7) div 8), 2, False);
  LSink.AddNumber(ABits, 2, False);
  Align;

  if AFact then
  begin
    AddGuid('fact', GUID_TAIL);
    AddInt64(24 + 8);
    AddInt64(Length(APayload) div (AChannels * ((ABits + 7) div 8)));
  end;

  AddGuid('data', GUID_TAIL);
  AddInt64(24 + Length(APayload));
  LSink.AddBytes(APayload);
  Align;

  if AJunk then
  begin
    AddGuid('junk', GUID_TAIL);
    AddInt64(24 + 16);
    for LIndex := 1 to 16 do
      LSink.Add($55);
  end;
  Result := LSink.Bytes;
end;

class function TSoundTestContainerFile.BuildRf64(ATag, AChannels, ABits: Word;
  ARate: Cardinal; ADs64: Boolean; ADataLength: Int64;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
  LLength: Int64;
begin
  if ADataLength = -2 then
    LLength := Length(APayload)
  else
    LLength := ADataLength;
  LSink.AddText('RF64');
  LSink.AddNumber($FFFFFFFF, 4, False);
  LSink.AddText('WAVE');
  if ADs64 then
  begin
    LSink.AddText('ds64');
    LSink.AddNumber(28, 4, False);
    LSink.AddNumber(0, 4, False);
    LSink.AddNumber(0, 4, False);
    LSink.AddNumber(Cardinal(LLength and $FFFFFFFF), 4, False);
    LSink.AddNumber(Cardinal(LLength shr 32), 4, False);
    LSink.AddNumber(0, 4, False);
    LSink.AddNumber(0, 4, False);
    LSink.AddNumber(0, 4, False);
  end;
  LSink.AddText('fmt ');
  LSink.AddNumber(16, 4, False);
  LSink.AddNumber(ATag, 2, False);
  LSink.AddNumber(AChannels, 2, False);
  LSink.AddNumber(ARate, 4, False);
  LSink.AddNumber(ARate * AChannels * ((ABits + 7) div 8), 4, False);
  LSink.AddNumber(AChannels * ((ABits + 7) div 8), 2, False);
  LSink.AddNumber(ABits, 2, False);
  LSink.AddText('data');
  if ADs64 then
    LSink.AddNumber($FFFFFFFF, 4, False)
  else
    LSink.AddNumber(Cardinal(LLength), 4, False);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;
class function TSoundTestContainerFile.BuildCaf(const AFormatId: AnsiString;
  AFlags, APacketBytes, AChannels, ABits: Cardinal; ARate: Double; AFree,
  AInfoAfter: Boolean; const APayload: TBytes): TBytes;
var
  LSink: TSink;
  LBits: Int64;
  LIndex: Integer;
begin
  LSink.AddText('caff');
  LSink.AddNumber(1, 2, True);
  LSink.AddNumber(0, 2, True);
  LSink.AddText('desc');
  LSink.AddNumber(0, 4, True);
  LSink.AddNumber(32, 4, True);
  Move(ARate, LBits, 8);
  LSink.AddNumber(Cardinal(LBits shr 32), 4, True);
  LSink.AddNumber(Cardinal(LBits and $FFFFFFFF), 4, True);
  LSink.AddText(AFormatId);
  LSink.AddNumber(AFlags, 4, True);
  LSink.AddNumber(APacketBytes, 4, True);
  LSink.AddNumber(1, 4, True);
  LSink.AddNumber(AChannels, 4, True);
  LSink.AddNumber(ABits, 4, True);

  if AFree then
  begin
    LSink.AddText('free');
    LSink.AddNumber(0, 4, True);
    LSink.AddNumber(10, 4, True);
    for LIndex := 1 to 10 do
      LSink.Add(0);
  end;

  LSink.AddText('data');
  LSink.AddNumber(0, 4, True);
  LSink.AddNumber(Cardinal(Length(APayload) + 4), 4, True);
  LSink.AddNumber(0, 4, True);
  LSink.AddBytes(APayload);

  if AInfoAfter then
  begin
    LSink.AddText('info');
    LSink.AddNumber(0, 4, True);
    LSink.AddNumber(12, 4, True);
    LSink.AddNumber(0, 4, True);
    LSink.AddText('abcdefgh');
  end;
  Result := LSink.Bytes;
end;
class function TSoundTestContainerFile.BuildSvx(A16Bit: Boolean; ARate: Word;
  ACompression: Byte; AChannelChunk, AExtraChunks: Boolean;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
begin
  LSink.AddText('FORM');
  LSink.AddNumber(0, 4, True);
  if A16Bit then
    LSink.AddText('16SV')
  else
    LSink.AddText('8SVX');
  LSink.AddText('VHDR');
  LSink.AddNumber(20, 4, True);
  LSink.AddNumber(Cardinal(Length(APayload)), 4, True);
  LSink.AddNumber(0, 4, True);
  LSink.AddNumber(32, 4, True);
  LSink.AddNumber(ARate, 2, True);
  LSink.Add(1);
  LSink.Add(ACompression);
  LSink.AddNumber($10000, 4, True);
  if AExtraChunks then
  begin
    LSink.AddText('NAME');
    LSink.AddNumber(4, 4, True);
    LSink.AddText('abcd');
    LSink.AddText('ANNO');
    LSink.AddNumber(8, 4, True);
    LSink.AddText('libsndfi');
  end;
  if AChannelChunk then
  begin
    LSink.AddText('CHAN');
    LSink.AddNumber(4, 4, True);
    LSink.AddNumber(6, 4, True);
  end;
  LSink.AddText('BODY');
  LSink.AddNumber(Cardinal(Length(APayload)), 4, True);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;

class function TSoundTestContainerFile.BuildIrcam(const AMarker: array of Byte;
  ABigFields: Boolean; ARate: Single; AChannels, AEncoding: Cardinal;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
  LIndex: Integer;
  LBits: Cardinal;
begin
  for LIndex := 0 to 3 do
    LSink.Add(AMarker[LIndex]);
  Move(ARate, LBits, 4);
  LSink.AddNumber(LBits, 4, ABigFields);
  LSink.AddNumber(AChannels, 4, ABigFields);
  LSink.AddNumber(AEncoding, 4, ABigFields);
  while Length(LSink.Bytes) < 1024 do
    LSink.Add(0);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;
class function TSoundTestContainerFile.BuildAvr(AMono, AResolution, ASign: Word;
  ARate: Cardinal; const APayload: TBytes): TBytes;
var
  LSink: TSink;
  LIndex: Integer;
begin
  LSink.AddText('2BIT');
  LSink.AddText('sample'#0#0);
  LSink.AddNumber(AMono, 2, True);
  LSink.AddNumber(AResolution, 2, True);
  LSink.AddNumber(ASign, 2, True);
  LSink.AddNumber(0, 2, True);
  LSink.AddNumber($FFFF, 2, True);
  LSink.AddNumber(ARate, 4, True);
  LSink.AddNumber(Cardinal(Length(APayload) div 2), 4, True);
  LSink.AddNumber(0, 4, True);
  LSink.AddNumber(0, 4, True);
  // Reserved words, extended name and the user text: up to 128 bytes
  for LIndex := Length(LSink.Bytes) + 1 to 128 do
    LSink.Add(0);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;

class function TSoundTestContainerFile.BuildHtk(ACount: Int64; APeriod,
  AKind: Cardinal; const APayload: TBytes): TBytes;
var
  LSink: TSink;
begin
  if ACount < 0 then
    ACount := Length(APayload) div 2;
  LSink.AddNumber(Cardinal(ACount), 4, True);
  LSink.AddNumber(APeriod, 4, True);
  LSink.AddNumber(AKind, 4, True);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;

class function TSoundTestContainerFile.BuildAiff(
  const AOptions: TSoundTestAiffOptions; const APayload: TBytes): TBytes;
const
  // 44100 as an 80 bit float
  RATE: array[0..9] of Byte = ($40, $0E, $AC, $44, 0, 0, 0, 0, 0, 0);
var
  LBody, LComm, LSsnd: TSink;
  LIndex: Integer;
  LSsndSize: Cardinal;
begin
  LBody.AddText('FORM');
  LBody.AddNumber(0, 4, True);
  if AOptions.Aifc then
    LBody.AddText('AIFC')
  else
    LBody.AddText('AIFF');

  if not AOptions.OmitComm then
  begin
    LComm.AddNumber(AOptions.Channels, 2, True);
    LComm.AddNumber(1000, 4, True);
    LComm.AddNumber(AOptions.SampleSize, 2, True);
    for LIndex := 0 to 9 do
      LComm.Add(RATE[LIndex]);
    if AOptions.Aifc then
    begin
      LComm.AddText(AOptions.Encoding);
      // An empty name: a Pascal string padded to an even length
      LComm.Add(0);
      LComm.Add(0);
    end;
    LBody.AddText('COMM');
    LBody.AddNumber(Cardinal(Length(LComm.Bytes)), 4, True);
    LBody.AddBytes(LComm.Bytes);
  end;

  if AOptions.ChunksBeforeData then
  begin
    LBody.AddText('NAME');
    LBody.AddNumber(3, 4, True);
    LBody.AddText('abc');
    LBody.Add(0);
    LBody.AddText('ZZZZ');
    LBody.AddNumber(4, 4, True);
    LBody.AddNumber($01020304, 4, True);
  end;

  if not AOptions.OmitSsnd then
  begin
    LSsnd.AddNumber(AOptions.SsndOffset, 4, True);
    LSsnd.AddNumber(0, 4, True);
    for LIndex := 1 to Integer(AOptions.SsndOffset) do
      LSsnd.Add(0);
    LSsnd.AddBytes(APayload);
    if AOptions.SsndSize = -2 then
      LSsndSize := Cardinal(Length(LSsnd.Bytes))
    else
      LSsndSize := Cardinal(AOptions.SsndSize);
    LBody.AddText('SSND');
    LBody.AddNumber(LSsndSize, 4, True);
    LBody.AddBytes(LSsnd.Bytes);
    // A chunk of odd length is followed by a pad byte
    if (Length(LSsnd.Bytes) and 1) <> 0 then
      LBody.Add(0);
  end;

  if AOptions.ChunkAfterData then
  begin
    LBody.AddText('ANNO');
    LBody.AddNumber(5, 4, True);
    LBody.AddText('hello');
    LBody.Add(0);
  end;
  Result := LBody.Bytes;
end;

class function TSoundTestContainerFile.BuildAu(const AOptions: TSoundTestAuOptions;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
  LSize: Cardinal;
  LIndex: Integer;
begin
  if AOptions.BigEndian then
    LSink.AddText('.snd')
  else
    LSink.AddText('dns.');
  LSink.AddNumber(Cardinal(24 + AOptions.Padding), 4, AOptions.BigEndian);
  if AOptions.DataSize = -2 then
    LSize := Cardinal(Length(APayload))
  else
    LSize := Cardinal(AOptions.DataSize);
  LSink.AddNumber(LSize, 4, AOptions.BigEndian);
  LSink.AddNumber(AOptions.Encoding, 4, AOptions.BigEndian);
  LSink.AddNumber(AOptions.SampleRate, 4, AOptions.BigEndian);
  LSink.AddNumber(AOptions.Channels, 4, AOptions.BigEndian);
  for LIndex := 1 to AOptions.Padding do
    LSink.Add(0);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;

class function TSoundTestContainerFile.BuildVoc(const AOptions: TSoundTestVocOptions;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
begin
  LSink.AddText('Creative Voice File');
  LSink.Add($1A);
  LSink.AddNumber(26, 2, False);
  LSink.AddNumber(AOptions.Version, 2, False);
  LSink.AddNumber($1234 + (not AOptions.Version and $FFFF), 2, False);

  if AOptions.TextBlockFirst then
  begin
    LSink.Add(5);
    LSink.AddNumber(6, 3, False);
    LSink.AddText('hello!');
  end;

  if AOptions.ExtendedII then
  begin
    LSink.Add(9);
    LSink.AddNumber(Cardinal(Length(APayload) + 12), 3, False);
    LSink.AddNumber(22050, 4, False);
    LSink.Add(AOptions.BitsPerSample);
    LSink.Add(AOptions.Channels);
    LSink.AddNumber(AOptions.Encoding, 2, False);
    LSink.AddNumber(0, 4, False);
  end
  else
  begin
    if AOptions.Extended then
    begin
      LSink.Add(8);
      LSink.AddNumber(4, 3, False);
      LSink.AddNumber(65536 - 1000000 div 11025 * 2 div 2, 2, False);
      LSink.Add(0);
      if AOptions.Stereo then
        LSink.Add(1)
      else
        LSink.Add(0);
    end;
    LSink.Add(1);
    LSink.AddNumber(Cardinal(Length(APayload) + 2), 3, False);
    LSink.Add(206);                                          // 1000000 / (256 - 206)
    LSink.Add(0);
  end;

  LSink.AddBytes(APayload);
  if not AOptions.OmitTerminator then
    LSink.Add(0);
  Result := LSink.Bytes;
end;

end.
