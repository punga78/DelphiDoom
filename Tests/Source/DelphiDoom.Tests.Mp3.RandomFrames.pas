{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mp3 library - valid frames with random contents    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.RandomFrames;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mp3.Intf;

type
  /// <summary>
  ///   Streams of layer III frames that follow the standard but whose values are random: the
  ///   side info is written field by field with values that the standard allows (every kind of
  ///   block, long, short and mixed, the Huffman tables that exist, regions inside the bands,
  ///   at most 288 big values, the parts inside the bits of the frame, a bit reservoir that only
  ///   points to bytes already given) and the main data are random bits, which every Huffman
  ///   tree reads. The scale factors of MPEG-1 and of MPEG-2 and the stereo modes (middle/side
  ///   and intensity) all come out. The sound is noise; what matters is that the decoder never
  ///   fails inside and that it gives always the same samples
  /// </summary>
  [TestFixture]
  [Category('mp3')]
  TTestMp3RandomFrames = class(TObject)
  private
    FMp3: IMp3;
    FSeed: UInt32;
    function NextRandom: UInt32;
    function RandomBelow(ALimit: Integer): Integer;
    /// <summary>A stream of AFrameCount valid frames with this header and random contents</summary>
    function BuildStream(AMpeg1, AProtected: Boolean; ABitrateIndex, AFrequencyIndex, AMode,
      AModeExtension, AFrameCount: Integer): TBytes;
    /// <summary>Decodes the whole stream; the digest covers the samples and the result codes</summary>
    function DecodeDigest(const AData: TBytes; AChannels: Integer; out AInternalErrors,
      ASampleBytes: Integer): UInt64;
    function DecodeAll(const AData: TBytes; AFeedChunk, APcmChunk: Integer): TBytes;
    function RunSeries(AMpeg1: Boolean; AFirstSeed, ACount: Integer; out AInternalErrors,
      ASampleBytes: Integer): UInt64;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDecodificareFrameCasualiMpeg1SenzaErroriInterni;
    [Test]
    procedure DovrebbeDecodificareFrameCasualiMpeg2SenzaErroriInterni;
    [Test]
    procedure DovrebbeDareSempreGliStessiCampioni;
    [Test]
    procedure DovrebbeDareGliStessiCampioniInPezziPiccoli;
    /// <summary>
    ///   Regression: a mixed block of MPEG-2 has 6 long bands (36 lines), not 8 as in MPEG-1.
    ///   The decoder took 8 and divided by a band of width 0 (EDivByZero, MP3_ERROR_INTERNAL)
    /// </summary>
    [Test]
    procedure DovrebbeDecodificareUnBloccoMistoMpeg2;
  end;

implementation

uses
  System.Math, DelphiDoom.Mp3.Engine;

const
  FNV_OFFSET = UInt64($CBF29CE484222325);
  FNV_PRIME = UInt64($00000100000001B3);
  SERIES_LENGTH = 48;
  FRAMES_PER_STREAM = 8;

{$Q-}
{$R-}

type
  /// <summary>Writes bits, the most significant first, from a position of a byte array</summary>
  TBitWriter = record
    Data: TBytes;
    Position: Integer;
    procedure Write(AValue: Cardinal; ABits: Integer);
  end;

procedure TBitWriter.Write(AValue: Cardinal; ABits: Integer);
var
  LBit: Integer;
  LByte: Integer;
begin
  for LBit := ABits - 1 downto 0 do
  begin
    LByte := Position shr 3;
    if (AValue shr LBit) and 1 <> 0 then
      Data[LByte] := Data[LByte] or ($80 shr (Position and 7))
    else
      Data[LByte] := Data[LByte] and not ($80 shr (Position and 7));
    Inc(Position);
  end;
end;

procedure HashBytes(var AHash: UInt64; AData: PByte; ASize: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ASize - 1 do
  begin
    AHash := AHash xor AData[LIndex];
    AHash := AHash * FNV_PRIME;
  end;
end;

procedure HashInteger(var AHash: UInt64; AValue: Integer);
begin
  HashBytes(AHash, @AValue, SizeOf(AValue));
end;

{ TTestMp3RandomFrames }

procedure TTestMp3RandomFrames.Setup;
begin
  FMp3 := TMp3Engine.Create;
end;

procedure TTestMp3RandomFrames.TearDown;
begin
  FMp3 := nil;
end;

function TTestMp3RandomFrames.NextRandom: UInt32;
begin
  // xorshift32: the same numbers on every machine
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TTestMp3RandomFrames.RandomBelow(ALimit: Integer): Integer;
begin
  if ALimit <= 0 then
    Exit(0);
  Result := Integer(NextRandom mod Cardinal(ALimit));
end;

function TTestMp3RandomFrames.BuildStream(AMpeg1, AProtected: Boolean; ABitrateIndex,
  AFrequencyIndex, AMode, AModeExtension, AFrameCount: Integer): TBytes;
const
  BITRATES_MPEG1: array[1..14] of Integer = (32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320);
  BITRATES_MPEG2: array[1..14] of Integer = (8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160);
  FREQUENCIES_MPEG1: array[0..2] of Integer = (44100, 48000, 32000);
  FREQUENCIES_MPEG2: array[0..2] of Integer = (22050, 24000, 16000);
  // the tables 4 and 14 are not in the standard
  TABLES: array[0..29] of Integer = (0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18,
    19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
var
  LFrameSize: Integer;
  LChannels: Integer;
  LGranules: Integer;
  LSideInfoSize: Integer;
  LMainDataBytes: Integer;
  LReservoir: Integer;
  LBackPointer: Integer;
  LPartBits: Integer;
  LFrame: Integer;
  LGranule: Integer;
  LChannel: Integer;
  LIndex: Integer;
  LOffset: Integer;
  LRegion0: Integer;
  LWriter: TBitWriter;
begin
  if AMpeg1 then
  begin
    LFrameSize := 144 * BITRATES_MPEG1[ABitrateIndex] * 1000 div FREQUENCIES_MPEG1[AFrequencyIndex];
    LGranules := 2;
  end
  else
  begin
    LFrameSize := 72 * BITRATES_MPEG2[ABitrateIndex] * 1000 div FREQUENCIES_MPEG2[AFrequencyIndex];
    LGranules := 1;
  end;
  if AMode = 3 then
    LChannels := 1
  else
    LChannels := 2;
  if AMpeg1 then
    LSideInfoSize := IfThen(LChannels = 1, 17, 32)
  else
    LSideInfoSize := IfThen(LChannels = 1, 9, 17);
  LMainDataBytes := LFrameSize - 4 - 2 * Ord(AProtected) - LSideInfoSize;

  SetLength(Result, LFrameSize * AFrameCount);
  LWriter.Data := Result;
  LReservoir := 0;
  for LFrame := 0 to AFrameCount - 1 do
  begin
    LOffset := LFrame * LFrameSize;
    Result[LOffset] := $FF;
    // sync, version, layer III (01), protection bit (0 = a checksum follows)
    Result[LOffset + 1] := $F2 or (Ord(AMpeg1) shl 3) or Ord(not AProtected);
    Result[LOffset + 2] := Byte((ABitrateIndex shl 4) or (AFrequencyIndex shl 2));
    Result[LOffset + 3] := Byte((AMode shl 6) or (AModeExtension shl 4));
    // the checksum (not checked) and the main data are random
    for LIndex := 4 to LFrameSize - 1 do
      Result[LOffset + LIndex] := Byte(NextRandom shr 24);

    // the reservoir: the main data may start in the bytes of the frames before
    LBackPointer := RandomBelow(Min(LReservoir, IfThen(AMpeg1, 511, 255)) + 1);
    LPartBits := ((LBackPointer + LMainDataBytes) * 8) div (LGranules * LChannels);

    LWriter.Position := (LOffset + 4 + 2 * Ord(AProtected)) * 8;
    if AMpeg1 then
    begin
      LWriter.Write(LBackPointer, 9);
      LWriter.Write(NextRandom, IfThen(LChannels = 1, 5, 3));
      for LChannel := 0 to LChannels - 1 do
        LWriter.Write(NextRandom, 4); // scfsi
    end
    else
    begin
      LWriter.Write(LBackPointer, 8);
      LWriter.Write(NextRandom, LChannels);
    end;

    for LGranule := 0 to LGranules - 1 do
      for LChannel := 0 to LChannels - 1 do
      begin
        LWriter.Write(Min(LPartBits, 4095) - RandomBelow(Min(LPartBits, 4095) div 4), 12);
        LWriter.Write(RandomBelow(289), 9); // big_values
        LWriter.Write(NextRandom, 8); // global_gain
        LWriter.Write(NextRandom, IfThen(AMpeg1, 4, 9)); // scalefac_compress
        if RandomBelow(2) = 1 then
        begin
          LWriter.Write(1, 1); // window switching
          LWriter.Write(1 + RandomBelow(3), 2); // block_type 1..3
          LWriter.Write(RandomBelow(2), 1); // mixed
          for LIndex := 0 to 1 do
            LWriter.Write(TABLES[RandomBelow(Length(TABLES))], 5);
          for LIndex := 0 to 2 do
            LWriter.Write(NextRandom, 3); // subblock_gain
        end
        else
        begin
          LWriter.Write(0, 1);
          for LIndex := 0 to 2 do
            LWriter.Write(TABLES[RandomBelow(Length(TABLES))], 5);
          // the regions stay inside the 22 bands
          LRegion0 := RandomBelow(16);
          LWriter.Write(LRegion0, 4);
          LWriter.Write(RandomBelow(Min(7, 20 - LRegion0) + 1), 3);
        end;
        if AMpeg1 then
          LWriter.Write(NextRandom, 1); // preflag
        LWriter.Write(NextRandom, 1); // scalefac_scale
        LWriter.Write(NextRandom, 1); // count1table_select
      end;
    Inc(LReservoir, LMainDataBytes);
  end;
end;

function TTestMp3RandomFrames.DecodeDigest(const AData: TBytes; AChannels: Integer;
  out AInternalErrors, ASampleBytes: Integer): UInt64;
var
  LDecoder: IMp3Decoder;
  LPcm: TBytes;
  LWritten: Cardinal;
  LCode: Integer;
  LGuard: Integer;
begin
  Result := FNV_OFFSET;
  AInternalErrors := 0;
  ASampleBytes := 0;
  Assert.AreEqual(MP3_OK, FMp3.CreateDecoder(AChannels, MP3_DEFAULT_VOLUME, LDecoder));
  Assert.AreEqual(MP3_OK, LDecoder.Feed(@AData[0], Length(AData)));
  SetLength(LPcm, 8192);
  LGuard := 0;
  repeat
    LCode := LDecoder.Decode(@LPcm[0], Length(LPcm), LWritten);
    HashInteger(Result, LCode);
    HashBytes(Result, @LPcm[0], LWritten);
    Inc(ASampleBytes, LWritten);
    if LCode = MP3_ERROR_INTERNAL then
      Inc(AInternalErrors);
    Inc(LGuard);
  until (LCode = MP3_NEED_DATA) or (LGuard > 1000);
  HashInteger(Result, LDecoder.GetFrequency);
  HashInteger(Result, LDecoder.GetChannels);
end;

function TTestMp3RandomFrames.DecodeAll(const AData: TBytes; AFeedChunk,
  APcmChunk: Integer): TBytes;
var
  LDecoder: IMp3Decoder;
  LPcm: TBytes;
  LWritten: Cardinal;
  LOffset: Integer;
  LCode: Integer;
begin
  Result := nil;
  Assert.AreEqual(MP3_OK, FMp3.CreateDecoder(MP3_CHANNELS_BOTH, MP3_DEFAULT_VOLUME, LDecoder));
  SetLength(LPcm, APcmChunk);
  LOffset := 0;
  while LOffset < Length(AData) do
  begin
    LDecoder.Feed(@AData[LOffset], Min(AFeedChunk, Length(AData) - LOffset));
    Inc(LOffset, AFeedChunk);
    repeat
      LCode := LDecoder.Decode(@LPcm[0], APcmChunk, LWritten);
      Assert.IsTrue(LCode >= 0, Format('code %d', [LCode]));
      SetLength(Result, Length(Result) + Integer(LWritten));
      if LWritten > 0 then
        Move(LPcm[0], Result[Length(Result) - Integer(LWritten)], LWritten);
    until LCode = MP3_NEED_DATA;
  end;
end;

function TTestMp3RandomFrames.RunSeries(AMpeg1: Boolean; AFirstSeed, ACount: Integer;
  out AInternalErrors, ASampleBytes: Integer): UInt64;
var
  LIndex: Integer;
  LStream: TBytes;
  LErrors: Integer;
  LBytes: Integer;
  LDigest: UInt64;
begin
  Result := FNV_OFFSET;
  AInternalErrors := 0;
  ASampleBytes := 0;
  for LIndex := AFirstSeed to AFirstSeed + ACount - 1 do
  begin
    FSeed := UInt32(LIndex) * 2654435761 + 1;
    LStream := BuildStream(AMpeg1, (LIndex div 4) mod 2 = 1, 9 + (LIndex div 8) mod 6,
      (LIndex div 3) mod 3, LIndex mod 4, (LIndex div 2) mod 4, FRAMES_PER_STREAM);
    LDigest := DecodeDigest(LStream, (LIndex div 5) mod 4, LErrors, LBytes);
    HashBytes(Result, @LDigest, SizeOf(LDigest));
    Inc(AInternalErrors, LErrors);
    Inc(ASampleBytes, LBytes);
  end;
end;

procedure TTestMp3RandomFrames.DovrebbeDecodificareFrameCasualiMpeg1SenzaErroriInterni;
var
  LErrors: Integer;
  LBytes: Integer;
begin
  RunSeries(True, 1, SERIES_LENGTH, LErrors, LBytes);
  Assert.AreEqual(0, LErrors);
  Assert.IsTrue(LBytes > 0);
end;

procedure TTestMp3RandomFrames.DovrebbeDecodificareFrameCasualiMpeg2SenzaErroriInterni;
var
  LErrors: Integer;
  LBytes: Integer;
begin
  RunSeries(False, 1, SERIES_LENGTH, LErrors, LBytes);
  Assert.AreEqual(0, LErrors);
  Assert.IsTrue(LBytes > 0);
end;

procedure DirtyHeap(AFill: Byte);
var
  LBlocks: array[0..199] of Pointer;
  LIndex: Integer;
  LSize: Integer;
begin
  // blocks of many sizes filled and given back: the next allocations get this memory
  for LIndex := 0 to High(LBlocks) do
  begin
    LSize := 16 + (LIndex * 7919) mod 65536;
    GetMem(LBlocks[LIndex], LSize);
    FillChar(LBlocks[LIndex]^, LSize, AFill);
  end;
  for LIndex := High(LBlocks) downto 0 do
    FreeMem(LBlocks[LIndex]);
end;

procedure TTestMp3RandomFrames.DovrebbeDareSempreGliStessiCampioni;
var
  LErrors: Integer;
  LBytes: Integer;
  LFirst: UInt64;
  LSecond: UInt64;
begin
  // The samples come from Single arithmetic: an optimized build keeps more bits in the FPU and
  // gives other samples, so there is no digest to compare with. What must not change them is
  // what the memory had before. Regression: the buffer of the bit reservoir was not zeroed and
  // the Huffman reader, which may go a few bits past a granule, read what the heap had
  DirtyHeap($00);
  LFirst := RunSeries(True, 100, 8, LErrors, LBytes) xor RunSeries(False, 100, 8, LErrors, LBytes);
  DirtyHeap($A5);
  LSecond := RunSeries(True, 100, 8, LErrors, LBytes) xor RunSeries(False, 100, 8, LErrors, LBytes);
  Assert.AreEqual(LFirst, LSecond);
  DirtyHeap($FF);
  LSecond := RunSeries(True, 100, 8, LErrors, LBytes) xor RunSeries(False, 100, 8, LErrors, LBytes);
  Assert.AreEqual(LFirst, LSecond);
end;

procedure TTestMp3RandomFrames.DovrebbeDareGliStessiCampioniInPezziPiccoli;
var
  LStream: TBytes;
  LWhole: TBytes;
  LPieces: TBytes;
begin
  FSeed := 12345;
  LStream := BuildStream(True, False, 9, 0, 1, 3, FRAMES_PER_STREAM);
  LWhole := DecodeAll(LStream, Length(LStream), 1000);
  LPieces := DecodeAll(LStream, 37, 98);
  Assert.IsTrue(Length(LWhole) > 0);
  Assert.AreEqual(Length(LWhole), Length(LPieces));
  Assert.IsTrue(CompareMem(@LWhole[0], @LPieces[0], Length(LWhole)));
end;

procedure TTestMp3RandomFrames.DovrebbeDecodificareUnBloccoMistoMpeg2;
var
  LStream: TBytes;
  LWriter: TBitWriter;
  LErrors: Integer;
  LBytes: Integer;
begin
  // one MPEG-2 frame, 22050 Hz, 64 kbit/s, mono, no checksum; then a second one to close it
  FSeed := 777;
  LStream := BuildStream(False, False, 8, 0, 3, 0, 2);
  // the side info of the first frame (9 bytes after the header), written again by hand
  LWriter.Data := LStream;
  LWriter.Position := 4 * 8;
  LWriter.Write(0, 8); // main_data_begin
  LWriter.Write(0, 1); // private
  LWriter.Write(1500, 12); // part2_3_length
  LWriter.Write(200, 9); // big_values
  LWriter.Write(180, 8); // global_gain
  LWriter.Write(100, 9); // scalefac_compress
  LWriter.Write(1, 1); // window switching
  LWriter.Write(2, 2); // short blocks
  LWriter.Write(1, 1); // mixed
  LWriter.Write(1, 5); // table 1
  LWriter.Write(2, 5); // table 2
  LWriter.Write(0, 9); // subblock gains
  LWriter.Write(0, 1); // scalefac_scale
  LWriter.Write(0, 1); // count1table_select
  DecodeDigest(LStream, MP3_CHANNELS_BOTH, LErrors, LBytes);
  Assert.AreEqual(0, LErrors);
  Assert.IsTrue(LBytes > 0);
end;

end.
