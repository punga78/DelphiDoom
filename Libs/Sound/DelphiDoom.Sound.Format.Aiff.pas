{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - AIFF and AIFF-C                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Aiff;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   AIFF and AIFF-C files with PCM (8 to 32 bit, either byte order), float,
  ///   double, mu-law and A-law samples, and the AIFF-C DWVW, GSM 6.10 and IMA
  ///   ADPCM encodings. Follows the chunk parser of libsndfile, quirks included.
  ///   A file without an SSND chunk is refused, and the CHAN chunk is always
  ///   skipped whole (libsndfile reads the rest of a chunk whose layout it does
  ///   not know as the next chunk)
  /// </summary>
  TAiffFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader,
  DelphiDoom.Sound.Codec.Gsm610, DelphiDoom.Sound.Codec.ImaAdpcm,
  DelphiDoom.Sound.Codec.Dwvw, DelphiDoom.Sound.CodecSamples;

const
  HAVE_FORM = $01;
  HAVE_AIFF = $02;
  HAVE_AIFC = $04;
  HAVE_COMM = $10;
  HAVE_SSND = $20;

  MAX_CHANNELS = 1024;
  // Size of the buffer libsndfile reads the text chunks into
  BUFFER_LENGTH = 8192;

  SIZEOF_AIFF_COMM = 18;
  SIZEOF_AIFC_COMM_MIN = 22;
  SIZEOF_AIFC_COMM = 24;
  SIZEOF_INST_CHUNK = 20;
  SIZEOF_SSND_HEADER = 8;
  SIZEOF_PEAK_HEADER = 8;
  SIZEOF_PEAK_CHANNEL = 8;

type
  TAiffComm = record
    Size: Cardinal;
    Channels: SmallInt;
    Frames: Cardinal;
    SampleSize: SmallInt;
    SampleRate: array[0..9] of Byte;
    Encoding: Cardinal;
  end;

var
  MARKER_FORM, MARKER_AIFF, MARKER_AIFC, MARKER_COMM, MARKER_SSND, MARKER_MARK,
  MARKER_INST, MARKER_APPL, MARKER_CHAN, MARKER_PEAK, MARKER_BASC,
  MARKER_COPYRIGHT, MARKER_NAME, MARKER_AUTH, MARKER_ANNO, MARKER_COMT,
  MARKER_FVER, MARKER_SFX, MARKER_NONE, MARKER_TWOS, MARKER_SOWT, MARKER_RAW,
  MARKER_IN24, MARKER_NI24, MARKER_IN32, MARKER_NI32, MARKER_FL32_LOWER,
  MARKER_FL32_UPPER, MARKER_FL64_LOWER, MARKER_FL64_UPPER, MARKER_ULAW_LOWER,
  MARKER_ULAW_UPPER, MARKER_ALAW_LOWER, MARKER_ALAW_UPPER, MARKER_DWVW,
  MARKER_GSM, MARKER_IMA4: Cardinal;

function SwapBytes(AValue: Cardinal): Cardinal;
begin
  Result := (AValue shr 24) or ((AValue shr 8) and $FF00) or
    ((AValue shl 8) and $FF0000) or (AValue shl 24);
end;

/// <summary>The 80 bit float of the COMM chunk, kept to what fits an integer</summary>
function TenByteFloatToInt(const ABytes: array of Byte): Integer;
begin
  if (ABytes[0] and $80) <> 0 then
    Exit(0);
  if ABytes[0] <= $3F then
    Exit(1);
  if ABytes[0] > $40 then
    Exit($4000000);
  if (ABytes[0] = $40) and (ABytes[1] > $1C) then
    Exit(800000000);
  Result := (Integer(ABytes[2]) shl 23) or (Integer(ABytes[3]) shl 15) or
    (Integer(ABytes[4]) shl 7) or (Integer(ABytes[5]) shr 1);
  Result := Result shr (29 - ABytes[1]);
end;

function CodecOfBitWidth(ABits: Integer): Integer;
begin
  Result := 0;
  if (ABits < 8) or (ABits > 32) then
    Exit;
  case (ABits + 7) div 8 of
    1: Result := SNDFILE_FORMAT_PCM_S8;
    2: Result := SNDFILE_FORMAT_PCM_16;
    3: Result := SNDFILE_FORMAT_PCM_24;
    4: Result := SNDFILE_FORMAT_PCM_32;
  end;
end;

function BytesOfBitWidth(ABits: Integer): Integer;
begin
  Result := (ABits + 7) div 8;
end;

procedure ReadComm(var AReader: TSoundByteReader; var AComm: TAiffComm);
var
  LIndex: Integer;
begin
  AComm.Channels := SmallInt(AReader.ReadUInt16);
  AComm.Frames := AReader.ReadUInt32;
  AComm.SampleSize := SmallInt(AReader.ReadUInt16);
  for LIndex := 0 to High(AComm.SampleRate) do
    AComm.SampleRate[LIndex] := AReader.ReadByte;

  // Some files have the size written in the wrong byte order
  if (AComm.Size > $10000) and ((AComm.Size and $FFFF) = 0) then
    AComm.Size := SwapBytes(AComm.Size);

  if AComm.Size = SIZEOF_AIFF_COMM then
    AComm.Encoding := MARKER_NONE
  else if AComm.Size = SIZEOF_AIFC_COMM_MIN then
    AComm.Encoding := AReader.ReadMarker
  else if AComm.Size >= SIZEOF_AIFC_COMM then
  begin
    AComm.Encoding := AReader.ReadMarker;
    AReader.ReadByte;
    if AComm.Size > BUFFER_LENGTH then
      AComm.Size := BUFFER_LENGTH;
    // The rest of the chunk: the name of the encoding
    AReader.Skip(Integer(AComm.Size) - SIZEOF_AIFC_COMM + 1);
  end;
end;

/// <summary>
///   What the COMM chunk makes of the samples: codec, byte order and width
/// </summary>
function ResolveComm(var AComm: TAiffComm; out ALayout: TSoundPcmLayout;
  out ABigEndian: Boolean): Integer;
var
  LCodec, LEndianFlag, LByteWidth: Integer;
begin
  FillChar(ALayout, SizeOf(ALayout), 0);
  ABigEndian := True;
  LEndianFlag := 0;

  if (AComm.Channels < 1) or (AComm.Channels >= MAX_CHANNELS) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // Some 'fl32' and 'fl64' files carry the wrong sample size
  if ((AComm.Encoding = MARKER_FL32_LOWER) or (AComm.Encoding = MARKER_FL32_UPPER)) and
     (AComm.SampleSize <> 32) then
    AComm.SampleSize := 32
  else if ((AComm.Encoding = MARKER_FL64_LOWER) or (AComm.Encoding = MARKER_FL64_UPPER)) and
          (AComm.SampleSize <> 64) then
    AComm.SampleSize := 64;

  LCodec := CodecOfBitWidth(AComm.SampleSize);
  LByteWidth := BytesOfBitWidth(AComm.SampleSize);

  if AComm.Encoding = MARKER_NONE then
    // Plain AIFF: the codec is what the sample size says
  else if (AComm.Encoding = MARKER_TWOS) or (AComm.Encoding = MARKER_IN24) or
          (AComm.Encoding = MARKER_IN32) then
    LEndianFlag := SNDFILE_FORMAT_ENDIAN_BIG
  else if (AComm.Encoding = MARKER_SOWT) or (AComm.Encoding = MARKER_NI24) or
          (AComm.Encoding = MARKER_NI32) then
  begin
    ABigEndian := False;
    LEndianFlag := SNDFILE_FORMAT_ENDIAN_LITTLE;
  end
  else if (AComm.Encoding = MARKER_FL32_LOWER) or (AComm.Encoding = MARKER_FL32_UPPER) then
  begin
    LCodec := SNDFILE_FORMAT_FLOAT;
    LByteWidth := 4;
  end
  else if (AComm.Encoding = MARKER_FL64_LOWER) or (AComm.Encoding = MARKER_FL64_UPPER) then
  begin
    LCodec := SNDFILE_FORMAT_DOUBLE;
    LByteWidth := 8;
  end
  else if (AComm.Encoding = MARKER_ULAW_LOWER) or (AComm.Encoding = MARKER_ULAW_UPPER) then
  begin
    LCodec := SNDFILE_FORMAT_ULAW;
    LByteWidth := 1;
  end
  else if (AComm.Encoding = MARKER_ALAW_LOWER) or (AComm.Encoding = MARKER_ALAW_UPPER) then
  begin
    LCodec := SNDFILE_FORMAT_ALAW;
    LByteWidth := 1;
  end
  else if AComm.Encoding = MARKER_RAW then
    LCodec := SNDFILE_FORMAT_PCM_U8
  else if AComm.Encoding = MARKER_GSM then
  begin
    // The samples are made by the codec, whatever the sample size says
    LCodec := SNDFILE_FORMAT_GSM610;
    LByteWidth := 0;
  end
  else if AComm.Encoding = MARKER_IMA4 then
  begin
    LCodec := SNDFILE_FORMAT_IMA_ADPCM;
    LByteWidth := 0;
  end
  else if AComm.Encoding = MARKER_DWVW then
  begin
    case AComm.SampleSize of
      12: LCodec := SNDFILE_FORMAT_DWVW_12;
      16: LCodec := SNDFILE_FORMAT_DWVW_16;
      24: LCodec := SNDFILE_FORMAT_DWVW_24;
    else
      LCodec := SNDFILE_FORMAT_DWVW_N;
    end;
    // The width of the words is what the decoder needs
    LByteWidth := AComm.SampleSize;
  end
  else
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  // Whatever the sample size, the decoders of libsndfile need these widths
  case LCodec of
    SNDFILE_FORMAT_PCM_S8, SNDFILE_FORMAT_PCM_U8:
      if LByteWidth <> 1 then
        Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
    SNDFILE_FORMAT_PCM_16, SNDFILE_FORMAT_PCM_24, SNDFILE_FORMAT_PCM_32,
    SNDFILE_FORMAT_FLOAT, SNDFILE_FORMAT_DOUBLE, SNDFILE_FORMAT_ULAW,
    SNDFILE_FORMAT_ALAW, SNDFILE_FORMAT_GSM610, SNDFILE_FORMAT_IMA_ADPCM,
    SNDFILE_FORMAT_DWVW_12, SNDFILE_FORMAT_DWVW_16, SNDFILE_FORMAT_DWVW_24,
    SNDFILE_FORMAT_DWVW_N:
      ;
  else
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;

  ALayout.Encoding := LCodec;
  ALayout.BytesPerSample := LByteWidth;
  ALayout.Channels := AComm.Channels;
  ALayout.SampleRate := TenByteFloatToInt(AComm.SampleRate);
  ALayout.Format := SNDFILE_FORMAT_AIFF or LCodec or LEndianFlag;
  Result := SNDFILE_OK;
end;

/// <summary>
///   DWVW. The 12 bit one opens, but libsndfile has no function to read it:
///   the sound is there and nothing can be read from it
/// </summary>
function DecodeDwvw(const ASource: TBytes; const ALayout: TSoundPcmLayout;
  ADataOffset, ADataLength: Int64; ACommFrames: Cardinal; out ASamples: TSoundSamples): Integer;
var
  LInfo: TSoundFileInfo;
  LData: TArray<Integer>;
  LBytes: TBytes;
  LFrames, LDecoded: Int64;
  LBits: Integer;
  LMoreThanThere, LHasTrailing: Boolean;
  LTrailing: Integer;
begin
  LMoreThanThere := False;
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.SampleRate := ALayout.SampleRate;
  LInfo.Channels := ALayout.Channels;
  LInfo.Format := ALayout.Format;
  LInfo.Sections := 1;
  LInfo.Seekable := 1;
  LDecoded := 0;
  LFrames := ACommFrames;
  case ALayout.Encoding of
    SNDFILE_FORMAT_DWVW_12: LBits := 0;
    SNDFILE_FORMAT_DWVW_16: LBits := 16;
    SNDFILE_FORMAT_DWVW_24: LBits := 24;
  else
    begin
      LBits := ALayout.BytesPerSample;
      if (LBits < 8) or (LBits >= 24) then
        Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
    end;
  end;
  if LBits > 0 then
  begin
    Result := TDwvwDecoder.Decode(ASource, ADataOffset, ADataLength, LBits,
      ALayout.Channels, LData, LFrames, LTrailing, LHasTrailing);
    if Result <> SNDFILE_OK then
      Exit;
    LDecoded := Length(LData) div ALayout.Channels;
    // libsndfile keeps the number of frames of the COMM chunk if it is smaller
    if LFrames > ACommFrames then
      LFrames := ACommFrames;
    if LDecoded > LFrames then
    begin
      LDecoded := LFrames;
      LMoreThanThere := True;
    end;
  end;
  LInfo.Frames := LFrames;
  SetLength(LBytes, LDecoded * ALayout.Channels * SizeOf(Integer));
  if LDecoded > 0 then
    Move(LData[0], LBytes[0], Length(LBytes));
  ASamples := TSoundSamples.Create(LInfo, TSoundSampleKind.Int32, LBytes, LDecoded);
  ASamples.RewindOnly := True;
  ASamples.ReadsUnimplemented := LBits = 0;
  // Decoded past the frames it keeps: libsndfile clears what follows them
  if LMoreThanThere then
    ASamples.ZeroFillChunk := -1
  else if LBits > 0 then
  begin
    ASamples.ZeroFillChunk := -4;
    ASamples.HasTrailingItem := LHasTrailing and (LDecoded > 0);
    ASamples.TrailingItem := LTrailing;
  end;
  Result := SNDFILE_OK;
end;

function TAiffFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LFound: Integer;
  LMarker, LChunkSize: Cardinal;
  LDone: Boolean;
  LComm: TAiffComm;
  LLayout: TSoundPcmLayout;
  LBigEndian: Boolean;
  LDataOffset, LDataLength, LDataEnd: Int64;
  LSsndSize, LSsndOffset: Cardinal;
  LBytes, LBytesRead, LCount, LIndex: Cardinal;
  LMarkCount: Word;
  LPascalLength: Byte;
  LStringLength: Word;
  LSkipped: Integer;
  LData: TBytes;
  LFrames: Int64;
  LPastTheEnd: Boolean;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := True;

  // What libsndfile looks for to pick this format
  if (LFileLength < 12) or (LReader.ReadMarker <> MARKER_FORM) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.Position := 8;
  LMarker := LReader.ReadMarker;
  if (LMarker <> MARKER_AIFF) and (LMarker <> MARKER_AIFC) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.Position := 0;

  FillChar(LComm, SizeOf(LComm), 0);
  FillChar(LLayout, SizeOf(LLayout), 0);
  LBigEndian := True;
  LFound := 0;
  LChunkSize := 0;
  LDataOffset := -1;
  LDataLength := -1;
  LDataEnd := 0;
  LDone := False;

  // The chunks can come in any order: read them all, then check the mandatory ones
  while not LDone do
  begin
    LReader.Skip(LChunkSize and 1);
    LMarker := LReader.ReadMarker;
    LChunkSize := LReader.ReadUInt32;
    if LReader.Overrun then
      LMarker := 0;
    if LMarker = 0 then
      Break;

    if LMarker = MARKER_FORM then
    begin
      if LFound <> 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LFound := LFound or HAVE_FORM;
      LMarker := LReader.ReadMarker;
      if LMarker = MARKER_AIFC then
        LFound := LFound or HAVE_AIFC or HAVE_AIFF
      else if LMarker = MARKER_AIFF then
        LFound := LFound or HAVE_AIFF;
      // No pad byte before the next marker
      LChunkSize := 0;
    end
    else if LMarker = MARKER_COMM then
    begin
      LChunkSize := LChunkSize + (LChunkSize and 1);
      LComm.Size := LChunkSize;
      ReadComm(LReader, LComm);
      Result := ResolveComm(LComm, LLayout, LBigEndian);
      if Result <> SNDFILE_OK then
        Exit;
      LFound := LFound or HAVE_COMM;
    end
    else if LMarker = MARKER_PEAK then
    begin
      // Must come after the COMM chunk
      if (LFound and (HAVE_FORM or HAVE_AIFF or HAVE_COMM)) <> (HAVE_FORM or HAVE_AIFF or HAVE_COMM) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      if LChunkSize <> Cardinal(SIZEOF_PEAK_HEADER + LLayout.Channels * SIZEOF_PEAK_CHANNEL) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_SSND then
    begin
      LSsndSize := LChunkSize;
      LSsndOffset := LReader.ReadUInt32;
      LReader.ReadUInt32;
      // 32 bit arithmetic, as in libsndfile: a size under 8 gives a huge length
      LDataLength := Int64(Cardinal(LSsndSize - SIZEOF_SSND_HEADER));
      LDataOffset := LReader.Position;
      if (LDataLength > LFileLength - LDataOffset) or (LDataLength < 0) then
        LDataLength := LFileLength - LDataOffset;
      Inc(LDataOffset, LSsndOffset);
      Dec(LDataLength, LSsndOffset);
      // Only when something follows the data
      if LDataLength + LDataOffset < LFileLength then
        LDataEnd := LDataLength + LDataOffset;
      LFound := LFound or HAVE_SSND;
      LReader.Position := LDataOffset + LDataLength;
    end
    else if (LMarker = MARKER_COPYRIGHT) or (LMarker = MARKER_AUTH) or
            (LMarker = MARKER_NAME) or (LMarker = MARKER_ANNO) then
    begin
      // Text chunks: skipped, but libsndfile refuses the ones that do not fit its buffer
      if LChunkSize <> 0 then
      begin
        if (LMarker = MARKER_COPYRIGHT) and (LChunkSize >= BUFFER_LENGTH) then
          Exit(SNDFILE_ERR_MALFORMED_FILE);
        if (LMarker = MARKER_AUTH) and (LChunkSize >= BUFFER_LENGTH - 1) then
          Exit(SNDFILE_ERR_MALFORMED_FILE);
        if ((LMarker = MARKER_NAME) or (LMarker = MARKER_ANNO)) and (LChunkSize >= BUFFER_LENGTH - 2) then
          Exit(SNDFILE_ERR_MALFORMED_FILE);
        LReader.Skip(LChunkSize + (LChunkSize and 1));
        Inc(LChunkSize, LChunkSize and 1);
      end;
    end
    else if LMarker = MARKER_COMT then
    begin
      if LChunkSize <> 0 then
      begin
        LBytes := LChunkSize;
        LCount := LReader.ReadUInt16;
        Dec(LBytes, 2);
        for LIndex := 1 to LCount do
        begin
          LReader.ReadUInt32;
          LReader.ReadUInt16;
          LStringLength := LReader.ReadUInt16;
          Dec(LBytes, 8);
          if LStringLength + 1 > BUFFER_LENGTH then
            Exit(SNDFILE_ERR_MALFORMED_FILE);
          LReader.Skip(LStringLength);
          Dec(LBytes, LStringLength);
        end;
        // Unsigned, as in libsndfile: a chunk that is too short skips far ahead
        if LBytes > 0 then
          LReader.Skip(Integer(LBytes));
      end;
    end
    else if LMarker = MARKER_APPL then
    begin
      if LChunkSize <> 0 then
      begin
        if LChunkSize >= BUFFER_LENGTH - 1 then
          // The pad byte is skipped here and again before the next chunk
          LReader.Skip(LChunkSize + (LChunkSize and 1))
        else if LChunkSize < 4 then
          LReader.Skip(LChunkSize + (LChunkSize and 1))
        else
        begin
          LReader.Skip(LChunkSize + (LChunkSize and 1));
          Inc(LChunkSize, LChunkSize and 1);
        end;
      end;
    end
    else if LMarker = MARKER_INST then
    begin
      // Same bytes whether the chunk is understood or not
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_BASC then
      LReader.Skip(Integer(LChunkSize))
    else if LMarker = MARKER_MARK then
    begin
      LMarkCount := LReader.ReadUInt16;
      LBytesRead := 2;
      if LMarkCount > 1000 then
        LReader.Skip(Integer(LChunkSize - LBytesRead))
      else
      begin
        LIndex := 0;
        while (LIndex < LMarkCount) and (LBytesRead < LChunkSize) do
        begin
          LReader.ReadUInt16;
          LReader.ReadUInt32;
          LPascalLength := LReader.ReadByte;
          Inc(LBytesRead, 7);
          if (LPascalLength and 1) <> 0 then
            LSkipped := LPascalLength
          else
            LSkipped := LPascalLength + 1;
          LReader.Skip(LSkipped);
          Inc(LBytesRead, Cardinal(LSkipped));
          Inc(LIndex);
        end;
        LReader.Skip(Integer(LChunkSize - LBytesRead));
      end;
    end
    else if (LMarker = MARKER_FVER) or (LMarker = MARKER_SFX) then
    begin
      if LMarker = MARKER_FVER then
        LFound := LFound or $08;
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_NONE then
    begin
      // Broken AIFC files whose COMM chunk has the wrong length
      LChunkSize := (LChunkSize shr 24) - 3;
      LReader.Skip(Integer(LChunkSize));
    end
    else if LMarker = MARKER_CHAN then
      LReader.Skip(LChunkSize)
    else
    begin
      if LChunkSize >= $FFFF0000 then
        LDone := True
      else if TSoundByteReader.IsPrintable(LMarker shr 24) and
              TSoundByteReader.IsPrintable((LMarker shr 16) and $FF) and
              TSoundByteReader.IsPrintable((LMarker shr 8) and $FF) and
              TSoundByteReader.IsPrintable(LMarker and $FF) then
        LReader.Skip(LChunkSize)
      else if (LReader.Position and 3) <> 0 then
        LReader.Skip(-3)
      else
        LDone := True;
    end;

    if LDone then
      Break;
    if LChunkSize >= LFileLength then
      Break;
    if LReader.Position >= LFileLength - 8 then
      Break;
  end;

  if LLayout.Channels < 1 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  // FORM and its type are the first chunk (they picked the format), and the
  // channels come only from a COMM chunk: of the chunks libsndfile wants, only
  // the SSND chunk can still be missing
  if (LFound and HAVE_SSND) = 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  if LLayout.Encoding = SNDFILE_FORMAT_GSM610 then
  begin
    if LDataLength < 0 then
      LDataLength := 0;
    Result := TGsm610Decoder.Decode(ASource, LDataOffset, LDataLength, False, LData, LFrames);
    // libsndfile keeps the number of frames of the COMM chunk if it is smaller
    if LFrames > LComm.Frames then
      LFrames := LComm.Frames;
    if Result = SNDFILE_OK then
      ASamples := TSoundCodecSamples.WrapGsm(LLayout.Format, LLayout.Channels,
        LLayout.SampleRate, LFrames, LData);
    Exit;
  end;

  case LLayout.Encoding of
    SNDFILE_FORMAT_DWVW_12, SNDFILE_FORMAT_DWVW_16, SNDFILE_FORMAT_DWVW_24, SNDFILE_FORMAT_DWVW_N:
      Exit(DecodeDwvw(ASource, LLayout, LDataOffset, LDataLength, LComm.Frames, ASamples));
  end;
  if LLayout.Encoding = SNDFILE_FORMAT_IMA_ADPCM then
  begin
    if LDataEnd > 0 then
      LDataLength := LDataEnd - LDataOffset
    else if LFileLength > LDataOffset then
      LDataLength := LFileLength - LDataOffset
    else
      LDataLength := 0;
    Result := TImaAdpcmDecoder.DecodeAiff(ASource, LDataOffset, LDataLength,
      LLayout.Channels, LData, LFrames, LPastTheEnd);
    if Result = SNDFILE_OK then
      ASamples := TSoundCodecSamples.Wrap(LLayout.Format, LLayout.Channels,
        LLayout.SampleRate, LFrames, LData, LPastTheEnd);
    Exit;
  end;

  // The decoders measure the data again: up to the end of the file or of the SSND chunk
  if LFileLength > LDataOffset then
  begin
    if LDataEnd > 0 then
      LDataLength := LDataEnd - LDataOffset
    else
      LDataLength := LFileLength - LDataOffset;
  end
  else
    LDataLength := 0;
  if LDataLength < 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  Result := TSoundPcmReader.Read(ASource, LLayout, LDataOffset, LDataLength,
    LFileLength, LBigEndian, ASamples);
end;

initialization
  MARKER_FORM := TSoundByteReader.MarkerOf('FORM');
  MARKER_AIFF := TSoundByteReader.MarkerOf('AIFF');
  MARKER_AIFC := TSoundByteReader.MarkerOf('AIFC');
  MARKER_COMM := TSoundByteReader.MarkerOf('COMM');
  MARKER_SSND := TSoundByteReader.MarkerOf('SSND');
  MARKER_MARK := TSoundByteReader.MarkerOf('MARK');
  MARKER_INST := TSoundByteReader.MarkerOf('INST');
  MARKER_APPL := TSoundByteReader.MarkerOf('APPL');
  MARKER_CHAN := TSoundByteReader.MarkerOf('CHAN');
  MARKER_PEAK := TSoundByteReader.MarkerOf('PEAK');
  MARKER_BASC := TSoundByteReader.MarkerOf('basc');
  MARKER_COPYRIGHT := TSoundByteReader.MarkerOf('(c) ');
  MARKER_NAME := TSoundByteReader.MarkerOf('NAME');
  MARKER_AUTH := TSoundByteReader.MarkerOf('AUTH');
  MARKER_ANNO := TSoundByteReader.MarkerOf('ANNO');
  MARKER_COMT := TSoundByteReader.MarkerOf('COMT');
  MARKER_FVER := TSoundByteReader.MarkerOf('FVER');
  MARKER_SFX := TSoundByteReader.MarkerOf('SFX!');
  MARKER_NONE := TSoundByteReader.MarkerOf('NONE');
  MARKER_TWOS := TSoundByteReader.MarkerOf('twos');
  MARKER_SOWT := TSoundByteReader.MarkerOf('sowt');
  MARKER_RAW := TSoundByteReader.MarkerOf('raw ');
  MARKER_IN24 := TSoundByteReader.MarkerOf('in24');
  MARKER_NI24 := TSoundByteReader.MarkerOf('42ni');
  MARKER_IN32 := TSoundByteReader.MarkerOf('in32');
  MARKER_NI32 := TSoundByteReader.MarkerOf('23ni');
  MARKER_FL32_LOWER := TSoundByteReader.MarkerOf('fl32');
  MARKER_FL32_UPPER := TSoundByteReader.MarkerOf('FL32');
  MARKER_FL64_LOWER := TSoundByteReader.MarkerOf('fl64');
  MARKER_FL64_UPPER := TSoundByteReader.MarkerOf('FL64');
  MARKER_ULAW_LOWER := TSoundByteReader.MarkerOf('ulaw');
  MARKER_ULAW_UPPER := TSoundByteReader.MarkerOf('ULAW');
  MARKER_ALAW_LOWER := TSoundByteReader.MarkerOf('alaw');
  MARKER_ALAW_UPPER := TSoundByteReader.MarkerOf('ALAW');
  MARKER_DWVW := TSoundByteReader.MarkerOf('DWVW');
  MARKER_GSM := TSoundByteReader.MarkerOf('GSM ');
  MARKER_IMA4 := TSoundByteReader.MarkerOf('ima4');

end.
