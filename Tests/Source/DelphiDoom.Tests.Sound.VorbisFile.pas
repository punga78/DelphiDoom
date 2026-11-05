{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds Ogg Vorbis files in memory  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.VorbisFile;

interface

uses
  System.SysUtils;

type
  /// <summary>How the file is made; every field has a default that makes a plain file</summary>
  TSoundTestVorbisOptions = record
    Channels: Integer;
    SampleRate: Integer;
    /// <summary>How many audio packets the stream has</summary>
    Packets: Integer;
    /// <summary>The type of the residue: 0, 1 or 2</summary>
    ResidueType: Integer;
    /// <summary>Serial number of the logical stream</summary>
    Serial: Integer;
    /// <summary>Samples taken off the end by the granule position of the last page</summary>
    TrimEnd: Integer;
    /// <summary>Seed of the random numbers that make the packets</summary>
    Seed: Cardinal;
    class function Plain: TSoundTestVorbisOptions; static;
  end;

  /// <summary>
  ///   Ogg Vorbis files for the tests. The headers are made on purpose (full
  ///   codebooks, a floor of type 1, coupling for two channels, blocks of 256
  ///   and 2048 samples); the audio packets are random bits after the bits of
  ///   the mode, which any decoder turns into the same noise
  /// </summary>
  TSoundTestVorbisFile = class
  public
    class function Build(const AOptions: TSoundTestVorbisOptions): TBytes; static;
    /// <summary>One file after the other, as a file of two sounds</summary>
    class function Chain(const AFirst, ASecond: TBytes): TBytes; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Ogg.Types, DelphiDoom.Ogg.Stream;

const
  SHORT_BLOCK = 256;
  LONG_BLOCK = 2048;

type
  /// <summary>Writes bits the way the packer of Ogg does: the least significant first</summary>
  TBitWriter = record
    Bytes: TBytes;
    BitCount: Integer;
    procedure Write(AValue: Cardinal; ABits: Integer);
    procedure WriteText(const AText: AnsiString);
  end;

procedure TBitWriter.Write(AValue: Cardinal; ABits: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ABits - 1 do
  begin
    if (BitCount shr 3) >= Length(Bytes) then
      SetLength(Bytes, Length(Bytes) + 256);
    if ((AValue shr LIndex) and 1) <> 0 then
      Bytes[BitCount shr 3] := Bytes[BitCount shr 3] or (1 shl (BitCount and 7));
    Inc(BitCount);
  end;
end;

procedure TBitWriter.WriteText(const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    Write(Ord(AText[LIndex]), 8);
end;

function Log2Floor(AValue: Cardinal): Integer;
begin
  Result := -1;
  while AValue <> 0 do
  begin
    Inc(Result);
    AValue := AValue shr 1;
  end;
end;

/// <summary>The packed float of codebooks (_float32_pack)</summary>
function PackFloat(AValue: Double): Cardinal;
var
  LSign: Cardinal;
  LExponent, LMantissa: Integer;
begin
  LSign := 0;
  if AValue < 0 then
  begin
    LSign := $80000000;
    AValue := -AValue;
  end;
  LExponent := Floor(Ln(AValue) / Ln(2) + 0.001);
  LMantissa := Round(AValue * Power(2, 20 - LExponent));
  Result := LSign or (Cardinal(LExponent + 768) shl 21) or Cardinal(LMantissa);
end;

procedure WriteHeaderTag(var AWriter: TBitWriter; AType: Integer);
begin
  AWriter.Write(AType, 8);
  AWriter.WriteText('vorbis');
end;

/// <summary>A codebook of ACount entries that all have the same code length</summary>
procedure WriteBook(var AWriter: TBitWriter; ADim, ACount, ALength: Integer);
var
  LIndex: Integer;
begin
  AWriter.Write($564342, 24);
  AWriter.Write(ADim, 16);
  AWriter.Write(ACount, 24);
  // not ordered, every entry used
  AWriter.Write(0, 1);
  AWriter.Write(0, 1);
  for LIndex := 1 to ACount do
    AWriter.Write(ALength - 1, 5);
end;

function BuildIdHeader(const AOptions: TSoundTestVorbisOptions): TBytes;
var
  LWriter: TBitWriter;
begin
  LWriter := Default(TBitWriter);
  WriteHeaderTag(LWriter, 1);
  LWriter.Write(0, 32);
  LWriter.Write(AOptions.Channels, 8);
  LWriter.Write(AOptions.SampleRate, 32);
  LWriter.Write(0, 32);
  LWriter.Write(128000, 32);
  LWriter.Write(0, 32);
  LWriter.Write(Log2Floor(SHORT_BLOCK), 4);
  LWriter.Write(Log2Floor(LONG_BLOCK), 4);
  LWriter.Write(1, 1);
  SetLength(LWriter.Bytes, (LWriter.BitCount + 7) shr 3);
  Result := LWriter.Bytes;
end;

function BuildCommentHeader: TBytes;
var
  LWriter: TBitWriter;
begin
  LWriter := Default(TBitWriter);
  WriteHeaderTag(LWriter, 3);
  LWriter.Write(16, 32);
  LWriter.WriteText('DelphiDoom tests');
  LWriter.Write(1, 32);
  LWriter.Write(10, 32);
  LWriter.WriteText('TITLE=test');
  LWriter.Write(1, 1);
  SetLength(LWriter.Bytes, (LWriter.BitCount + 7) shr 3);
  Result := LWriter.Bytes;
end;

function BuildSetupHeader(const AOptions: TSoundTestVorbisOptions): TBytes;
var
  LWriter: TBitWriter;
  LIndex: Integer;
begin
  LWriter := Default(TBitWriter);
  WriteHeaderTag(LWriter, 5);

  // four codebooks: the classes of the floor, its amplitudes, the partition
  // words of the residue (a single entry) and the vectors of the residue
  LWriter.Write(4 - 1, 8);
  WriteBook(LWriter, 1, 16, 4);
  LWriter.Write(0, 4);
  WriteBook(LWriter, 1, 256, 8);
  LWriter.Write(0, 4);
  // one entry of one bit: the codebook that is not a full tree
  LWriter.Write($564342, 24);
  LWriter.Write(1, 16);
  LWriter.Write(1, 24);
  LWriter.Write(0, 1);
  LWriter.Write(0, 1);
  LWriter.Write(0, 5);
  LWriter.Write(0, 4);
  // a lattice of 8 values for each of the 2 dimensions
  WriteBook(LWriter, 2, 64, 6);
  LWriter.Write(1, 4);
  LWriter.Write(PackFloat(-0.4), 32);
  LWriter.Write(PackFloat(0.1), 32);
  LWriter.Write(4 - 1, 4);
  LWriter.Write(0, 1);
  for LIndex := 0 to 7 do
    LWriter.Write(LIndex, 4);

  // the hooks of the time domain
  LWriter.Write(0, 6);
  LWriter.Write(0, 16);

  // a floor of type 1: one partition class of two posts
  LWriter.Write(0, 6);
  LWriter.Write(1, 16);
  LWriter.Write(1, 5);
  LWriter.Write(0, 4);
  LWriter.Write(2 - 1, 3);
  LWriter.Write(1, 2);
  LWriter.Write(0, 8);
  LWriter.Write(2, 8);
  LWriter.Write(0, 8);
  LWriter.Write(0, 2);
  LWriter.Write(8, 4);
  LWriter.Write(64, 8);
  LWriter.Write(192, 8);

  // a residue
  LWriter.Write(0, 6);
  LWriter.Write(AOptions.ResidueType, 16);
  LWriter.Write(0, 24);
  LWriter.Write(1024, 24);
  LWriter.Write(16 - 1, 24);
  LWriter.Write(0, 6);
  LWriter.Write(2, 8);
  LWriter.Write(1, 3);
  LWriter.Write(0, 1);
  LWriter.Write(3, 8);

  // a mapping, with coupling for two channels
  LWriter.Write(0, 6);
  LWriter.Write(0, 16);
  LWriter.Write(0, 1);
  if AOptions.Channels = 2 then
  begin
    LWriter.Write(1, 1);
    LWriter.Write(0, 8);
    LWriter.Write(0, 1);
    LWriter.Write(1, 1);
  end
  else
    LWriter.Write(0, 1);
  LWriter.Write(0, 2);
  LWriter.Write(0, 8);
  LWriter.Write(0, 8);
  LWriter.Write(0, 8);

  // the short and the long mode
  LWriter.Write(2 - 1, 6);
  LWriter.Write(0, 1);
  LWriter.Write(0, 16);
  LWriter.Write(0, 16);
  LWriter.Write(0, 8);
  LWriter.Write(1, 1);
  LWriter.Write(0, 16);
  LWriter.Write(0, 16);
  LWriter.Write(0, 8);
  LWriter.Write(1, 1);

  SetLength(LWriter.Bytes, (LWriter.BitCount + 7) shr 3);
  Result := LWriter.Bytes;
end;

{ TSoundTestVorbisOptions }

class function TSoundTestVorbisOptions.Plain: TSoundTestVorbisOptions;
begin
  Result.Channels := 2;
  Result.SampleRate := 44100;
  Result.Packets := 30;
  Result.ResidueType := 1;
  Result.Serial := 4711;
  Result.TrimEnd := 0;
  Result.Seed := 12345;
end;

{ TSoundTestVorbisFile }

class function TSoundTestVorbisFile.Build(const AOptions: TSoundTestVorbisOptions): TBytes;
var
  LStream: TOggStreamState;
  LPage: TOggPage;
  LPacket: TOggPacket;
  LOut: TBytes;
  LFill, LIndex, LLength, LByte, LMask, LModeBits: Integer;
  LSeed: Cardinal;
  LPayload: TBytes;
  LLong, LPreviousLong, LLast: Boolean;
  LGranule: Int64;
  LHeaders: array[0..2] of TBytes;

  procedure WritePage;
  begin
    if Length(LOut) < LFill + LPage.HeaderLength + LPage.BodyLength then
      SetLength(LOut, (LFill + LPage.HeaderLength + LPage.BodyLength) * 2);
    Move(LPage.Header^, LOut[LFill], LPage.HeaderLength);
    Inc(LFill, LPage.HeaderLength);
    Move(LPage.Body^, LOut[LFill], LPage.BodyLength);
    Inc(LFill, LPage.BodyLength);
  end;

  function Next: Cardinal;
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    Result := LSeed shr 8;
  end;

  procedure PutPacket(const AData: TBytes; ABeginning, AEnd: Boolean; AGranule, ANumber: Int64);
  begin
    FillChar(LPacket, SizeOf(LPacket), 0);
    LPacket.Packet := @AData[0];
    LPacket.Bytes := Length(AData);
    LPacket.BeginningOfStream := Ord(ABeginning);
    LPacket.EndOfStream := Ord(AEnd);
    LPacket.GranulePosition := AGranule;
    LPacket.PacketNumber := ANumber;
    TOggStream.PacketIn(@LStream, @LPacket);
  end;

begin
  FillChar(LStream, SizeOf(LStream), 0);
  LFill := 0;
  LSeed := AOptions.Seed;
  LHeaders[0] := BuildIdHeader(AOptions);
  LHeaders[1] := BuildCommentHeader;
  LHeaders[2] := BuildSetupHeader(AOptions);

  TOggStream.Init(@LStream, AOptions.Serial);
  try
    PutPacket(LHeaders[0], True, False, 0, 0);
    while TOggStream.Flush(@LStream, @LPage) <> 0 do
      WritePage;
    PutPacket(LHeaders[1], False, False, 0, 1);
    PutPacket(LHeaders[2], False, False, 0, 2);
    // the audio starts on a page of its own
    while TOggStream.Flush(@LStream, @LPage) <> 0 do
      WritePage;

    LGranule := 0;
    LPreviousLong := False;
    for LIndex := 0 to AOptions.Packets - 1 do
    begin
      LLast := LIndex = AOptions.Packets - 1;
      LLong := (Next and 3) = 0;
      if LLong then
        LLength := 200 + Integer(Next mod 400)
      else
        LLength := 40 + Integer(Next mod 120);
      SetLength(LPayload, LLength);
      for LByte := 0 to LLength - 1 do
        LPayload[LByte] := Byte(Next);

      // the first bits: an audio packet (0), the mode (1 bit) and, for a long
      // block, the windows before and after it; the rest is noise
      LModeBits := Ord(LLong) shl 1;
      LMask := 3;
      if LLong then
      begin
        LModeBits := LModeBits or (Ord(LPreviousLong) shl 2) or (1 shl 3);
        LMask := $F;
      end;
      LPayload[0] := (LPayload[0] and not LMask) or Byte(LModeBits);

      if LIndex > 0 then
      begin
        if LLong then
          Inc(LGranule, LONG_BLOCK div 4)
        else
          Inc(LGranule, SHORT_BLOCK div 4);
        if LPreviousLong then
          Inc(LGranule, LONG_BLOCK div 4)
        else
          Inc(LGranule, SHORT_BLOCK div 4);
      end;
      if LLast then
        PutPacket(LPayload, False, True, LGranule - AOptions.TrimEnd, 3 + LIndex)
      else
        PutPacket(LPayload, False, False, LGranule, 3 + LIndex);
      LPreviousLong := LLong;
      while TOggStream.PageOut(@LStream, @LPage) <> 0 do
        WritePage;
    end;
    while TOggStream.Flush(@LStream, @LPage) <> 0 do
      WritePage;
  finally
    TOggStream.Clear(@LStream);
  end;

  SetLength(LOut, LFill);
  Result := LOut;
end;

class function TSoundTestVorbisFile.Chain(const AFirst, ASecond: TBytes): TBytes;
begin
  SetLength(Result, Length(AFirst) + Length(ASecond));
  Move(AFirst[0], Result[0], Length(AFirst));
  Move(ASecond[0], Result[Length(AFirst)], Length(ASecond));
end;

end.
