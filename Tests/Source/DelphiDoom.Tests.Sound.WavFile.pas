{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds WAV files in memory         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.WavFile;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What a test file looks like. Every field has the value of a plain,
  ///   well formed file: a test changes only what it wants to break
  /// </summary>
  TSoundTestWavOptions = record
    /// <summary>Format tag of the 'fmt ' chunk (1 PCM, 3 float, 6 A-law, 7 mu-law)</summary>
    Tag: Word;
    Channels: Word;
    SampleRate: Cardinal;
    BitsPerSample: Word;
    BigEndian: Boolean;
    /// <summary>WAVE_FORMAT_EXTENSIBLE with Tag as the sub format</summary>
    Extensible: Boolean;
    /// <summary>A JUNK chunk before 'fmt '</summary>
    JunkBeforeFormat: Boolean;
    /// <summary>A LIST chunk after the data</summary>
    ChunkAfterData: Boolean;
    /// <summary>Size written in the 'data' chunk; -1 for the real one</summary>
    DataSize: Int64;
    /// <summary>Size written in the 'fmt ' chunk; -1 for the real one</summary>
    FormatSize: Integer;
    OmitData: Boolean;
    OmitFormat: Boolean;
    class function Plain(ATag: Word; AChannels: Word; ABits: Word): TSoundTestWavOptions; static;
  end;

  TSoundTestWavFile = class
  public
    class function Build(const AOptions: TSoundTestWavOptions;
      const APayload: TBytes): TBytes; static;
    /// <summary>Deterministic bytes: the same seed gives the same bytes</summary>
    class function RandomBytes(ACount: Integer; ASeed: Cardinal): TBytes; static;
    /// <summary>
    ///   Floats of 4 bytes (or doubles of 8) spread between -2 and 2, with
    ///   some values beyond the range of the integers, in the order of the file
    /// </summary>
    class function FloatPayload(ACount: Integer; ASeed: Cardinal; ADouble,
      ABigEndian: Boolean): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Tests.Support.ExtendedQuotient;

{$Q-}
{$R-}

type
  TByteSink = record
    Bytes: TBytes;
    Count: Integer;
    BigEndian: Boolean;
    procedure Add(AValue: Byte);
    procedure AddText(const AText: AnsiString);
    procedure AddNumber(AValue: Cardinal; AByteCount: Integer);
    procedure AddBytes(const AValues: TBytes);
  end;

{ TByteSink }

procedure TByteSink.Add(AValue: Byte);
begin
  if Count >= Length(Bytes) then
    SetLength(Bytes, Length(Bytes) * 2 + 64);
  Bytes[Count] := AValue;
  Inc(Count);
end;

procedure TByteSink.AddText(const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    Add(Byte(AText[LIndex]));
end;

procedure TByteSink.AddNumber(AValue: Cardinal; AByteCount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AByteCount - 1 do
    if BigEndian then
      Add(Byte(AValue shr (8 * (AByteCount - 1 - LIndex))))
    else
      Add(Byte(AValue shr (8 * LIndex)));
end;

procedure TByteSink.AddBytes(const AValues: TBytes);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AValues) do
    Add(AValues[LIndex]);
end;

{ TSoundTestWavOptions }

class function TSoundTestWavOptions.Plain(ATag, AChannels,
  ABits: Word): TSoundTestWavOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Tag := ATag;
  Result.Channels := AChannels;
  Result.SampleRate := 22050;
  Result.BitsPerSample := ABits;
  Result.DataSize := -1;
  Result.FormatSize := -1;
end;

{ TSoundTestWavFile }

class function TSoundTestWavFile.Build(const AOptions: TSoundTestWavOptions;
  const APayload: TBytes): TBytes;
var
  LSink: TByteSink;
  LFormatBody: TByteSink;
  LBytesPerFrame: Integer;
  LRiffSizeAt: Integer;
  LWrittenDataSize: Cardinal;
begin
  LSink.Count := 0;
  LSink.BigEndian := AOptions.BigEndian;
  LFormatBody.Count := 0;
  LFormatBody.BigEndian := AOptions.BigEndian;

  LBytesPerFrame := AOptions.Channels * ((AOptions.BitsPerSample + 7) div 8);

  if AOptions.BigEndian then
    LSink.AddText('RIFX')
  else
    LSink.AddText('RIFF');
  LRiffSizeAt := LSink.Count;
  LSink.AddNumber(0, 4);
  LSink.AddText('WAVE');

  if AOptions.JunkBeforeFormat then
  begin
    LSink.AddText('JUNK');
    LSink.AddNumber(6, 4);
    LSink.AddBytes(TBytes.Create(1, 2, 3, 4, 5, 6));
  end;

  if not AOptions.OmitFormat then
  begin
    if AOptions.Extensible then
      LFormatBody.AddNumber($FFFE, 2)
    else
      LFormatBody.AddNumber(AOptions.Tag, 2);
    LFormatBody.AddNumber(AOptions.Channels, 2);
    LFormatBody.AddNumber(AOptions.SampleRate, 4);
    LFormatBody.AddNumber(AOptions.SampleRate * Cardinal(LBytesPerFrame), 4);
    LFormatBody.AddNumber(Cardinal(LBytesPerFrame), 2);
    LFormatBody.AddNumber(AOptions.BitsPerSample, 2);
    if AOptions.Extensible then
    begin
      LFormatBody.AddNumber(22, 2);                         // extra bytes
      LFormatBody.AddNumber(AOptions.BitsPerSample, 2);     // valid bits
      LFormatBody.AddNumber(3, 4);                          // channel mask
      LFormatBody.AddNumber(AOptions.Tag, 4);               // GUID: data1 = format
      LFormatBody.AddNumber(0, 2);
      LFormatBody.AddNumber($10, 2);
      LFormatBody.Add($80);
      LFormatBody.Add($00);
      LFormatBody.Add($00);
      LFormatBody.Add($AA);
      LFormatBody.Add($00);
      LFormatBody.Add($38);
      LFormatBody.Add($9B);
      LFormatBody.Add($71);
    end
    else if (AOptions.Tag = 6) or (AOptions.Tag = 7) then
      LFormatBody.AddNumber(0, 2);                          // extra bytes of the codecs

    LSink.AddText('fmt ');
    if AOptions.FormatSize >= 0 then
      LSink.AddNumber(Cardinal(AOptions.FormatSize), 4)
    else
      LSink.AddNumber(Cardinal(LFormatBody.Count), 4);
    LSink.AddBytes(Copy(LFormatBody.Bytes, 0, LFormatBody.Count));
  end;

  if not AOptions.OmitData then
  begin
    if AOptions.DataSize >= 0 then
      LWrittenDataSize := Cardinal(AOptions.DataSize)
    else
      LWrittenDataSize := Cardinal(Length(APayload));
    LSink.AddText('data');
    LSink.AddNumber(LWrittenDataSize, 4);
    LSink.AddBytes(APayload);
    if Odd(Length(APayload)) then
      LSink.Add(0);                                         // chunks are word aligned
  end;

  if AOptions.ChunkAfterData then
  begin
    LSink.AddText('LIST');
    LSink.AddNumber(8, 4);
    LSink.AddText('INFOabcd');
  end;

  // Size of the RIFF chunk: patched in place
  Result := Copy(LSink.Bytes, 0, LSink.Count);
  LSink.Count := LRiffSizeAt;
  LSink.Bytes := Result;
  LSink.AddNumber(Cardinal(Length(Result) - 8), 4);
  Result := Copy(LSink.Bytes, 0, Length(Result));
end;

class function TSoundTestWavFile.RandomBytes(ACount: Integer;
  ASeed: Cardinal): TBytes;
var
  LIndex: Integer;
  LState: Cardinal;
begin
  SetLength(Result, ACount);
  LState := ASeed * 2654435761 + 12345;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := LState * 1664525 + 1013904223;
    Result[LIndex] := Byte(LState shr 24);
  end;
end;

class function TSoundTestWavFile.FloatPayload(ACount: Integer; ASeed: Cardinal;
  ADouble, ABigEndian: Boolean): TBytes;
var
  LIndex, LByte, LSize: Integer;
  LState: Cardinal;
  LSingle: Single;
  LDouble: Double;
  LRaw: array[0..7] of Byte;
begin
  if ADouble then
    LSize := 8
  else
    LSize := 4;
  SetLength(Result, ACount * LSize);
  LState := ASeed * 2654435761 + 777;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := LState * 1664525 + 1013904223;
    case LIndex mod 11 of
      0: LDouble := 0.0;
      1: LDouble := 1.0;
      2: LDouble := -1.0;
      3: LDouble := 1.5;
      4: LDouble := -2.5;
    else
      // the quotient of the 32 bit FPU, the one of the golden files
      LDouble := TExtendedQuotient.Divide(Integer(LState shr 8) mod 4000001 - 2000000, 1000000.0);
    end;
    if ADouble then
      Move(LDouble, LRaw, 8)
    else
    begin
      LSingle := LDouble;
      Move(LSingle, LRaw, 4);
    end;
    for LByte := 0 to LSize - 1 do
      if ABigEndian then
        Result[LIndex * LSize + LByte] := LRaw[LSize - 1 - LByte]
      else
        Result[LIndex * LSize + LByte] := LRaw[LByte];
  end;
end;

end.
