{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - RF64 (EBU 64 bit WAV)                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Rf64;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   RF64 files: a WAV whose sizes live in a 'ds64' chunk. PCM, float,
  ///   mu-law and A-law. The chunks about metadata (bext, cart, LIST, INFO,
  ///   PEAK) are skipped by their size
  /// </summary>
  TRf64Format = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader,
  DelphiDoom.Sound.WavLike.Fmt;

const
  HAVE_DS64 = $01;
  HAVE_FMT = $02;

  MAX_CHANNELS = 1024;

var
  MARKER_RF64, MARKER_WAVE, MARKER_DS64, MARKER_FMT, MARKER_BEXT, MARKER_CART,
  MARKER_INFO, MARKER_LIST, MARKER_PEAK, MARKER_DATA, MARKER_WVPK,
  MARKER_OGGS: Cardinal;

function ReadInt64LittleEndian(var AReader: TSoundByteReader): Int64;
var
  LLow, LHigh: Cardinal;
begin
  LLow := AReader.ReadUInt32;
  LHigh := AReader.ReadUInt32;
  Result := Int64(LLow) or (Int64(LHigh) shl 32);
end;

{ TRf64Format }

function TRf64Format.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LMarker, LChunkSize, LNext, LBytesRead, LTableLength: Cardinal;
  LStage: Cardinal;
  LDone: Boolean;
  LLayout: TWavLikeLayout;
  LRiffSize, LDataLengthDs64, LDataLength, LDataOffset, LDataEnd, LUsable: Int64;
  LPcm: TSoundPcmLayout;
  LCodec: Integer;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  LReader := TSoundByteReader.Create(ASource);
  if LFileLength < 12 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  if LReader.ReadMarker <> MARKER_RF64 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.ReadMarker;
  if LReader.ReadMarker <> MARKER_WAVE then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  FillChar(LLayout, SizeOf(LLayout), 0);
  LStage := 0;
  LDone := False;
  LRiffSize := 0;
  LDataLengthDs64 := 0;
  LDataLength := -1;
  LDataOffset := -1;
  LDataEnd := 0;

  while not LDone do
  begin
    // The chunk markers are read as they are in the file, in either order
    LMarker := LReader.ReadMarker;
    LReader.BigEndian := False;
    LChunkSize := LReader.ReadUInt32;
    if LReader.Overrun then
      LMarker := 0;
    if LMarker = 0 then
      Break;

    if LMarker = MARKER_DS64 then
    begin
      if (LStage and HAVE_DS64) = 0 then
      begin
        LRiffSize := ReadInt64LittleEndian(LReader);
        LDataLengthDs64 := ReadInt64LittleEndian(LReader);
        ReadInt64LittleEndian(LReader);
        LTableLength := LReader.ReadUInt32;
        LReader.Skip(LTableLength);
        // 32 bit arithmetic, as in libsndfile (the jump counts as bytes read)
        LBytesRead := 28 + LTableLength;
        if LChunkSize = LBytesRead then
          // as it should be
        else if LChunkSize >= LBytesRead + 4 then
        begin
          LNext := LReader.ReadMarker;
          if LNext = MARKER_FMT then
            LReader.Skip(-4)
          else
            LReader.Skip(Integer(LChunkSize - LBytesRead - 4));
        end;
        LStage := LStage or HAVE_DS64;
      end;
    end
    else if LMarker = MARKER_FMT then
    begin
      Result := TWavLikeFmtChunk.Read(LReader, LChunkSize, LLayout);
      if Result <> SNDFILE_OK then
        Exit;
      LStage := LStage or HAVE_FMT;
    end
    else if (LMarker = MARKER_BEXT) or (LMarker = MARKER_CART) or
            (LMarker = MARKER_INFO) or (LMarker = MARKER_LIST) then
      LReader.Skip(LChunkSize)
    else if LMarker = MARKER_PEAK then
    begin
      if (LStage and (HAVE_DS64 or HAVE_FMT)) <> (HAVE_DS64 or HAVE_FMT) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      if LChunkSize <> Cardinal(8 + LLayout.Channels * 8) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_DATA then
    begin
      if (LStage and HAVE_DS64) <> 0 then
        LDataLength := LDataLengthDs64
      else if LChunkSize <> $FFFFFFFF then
        LDataLength := LChunkSize;
      LDataOffset := LReader.Position;
      if LDataOffset > 0 then
      begin
        // A file that was not closed properly has no sizes: the data is the rest
        if (LChunkSize = 0) and (LRiffSize = 8) and (LFileLength > 44) then
          LDataLength := LFileLength - LDataOffset;
        if LDataLength + LDataOffset < LFileLength then
          LDataEnd := LDataLength + LDataOffset;
        LReader.Skip(LDataLength);
      end;
    end
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
    // A 'data' size of $FFFFFFFF means the size of the ds64 chunk applies
    if (LMarker <> MARKER_DATA) and (LChunkSize >= LFileLength) then
      Break;
    if LReader.Position >= LFileLength - 4 then
      Break;
  end;

  if LDataOffset <= 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LLayout.Channels < 1 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LLayout.Channels >= MAX_CHANNELS then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // The data of a WAV is not another container
  LReader.Position := LDataOffset;
  LMarker := LReader.ReadMarker;
  if (LMarker = MARKER_WVPK) or (LMarker = MARKER_OGGS) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  FillChar(LPcm, SizeOf(LPcm), 0);
  case LLayout.Tag of
    TWavLikeFmtChunk.WAVE_FORMAT_PCM, TWavLikeFmtChunk.WAVE_FORMAT_EXTENSIBLE,
    TWavLikeFmtChunk.WAVE_FORMAT_IEEE_FLOAT, TWavLikeFmtChunk.WAVE_FORMAT_ALAW,
    TWavLikeFmtChunk.WAVE_FORMAT_MULAW:
      if not TWavLikeFmtChunk.ResolveEncoding(LLayout, LCodec) then
        Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  else
    // ADPCM, GSM and G.721 are not read yet
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;

  if (LCodec = SNDFILE_FORMAT_ULAW) or (LCodec = SNDFILE_FORMAT_ALAW) then
    LPcm.BytesPerSample := 1
  else
    LPcm.BytesPerSample := LLayout.BytesPerSample;
  LPcm.Encoding := LCodec;
  LPcm.Channels := LLayout.Channels;
  LPcm.SampleRate := LLayout.SampleRate;
  LPcm.Format := SNDFILE_FORMAT_RF64 or LCodec;

  LUsable := LFileLength - LDataOffset;
  if LDataEnd > 0 then
    LDataLength := LDataEnd - LDataOffset
  else
    LDataLength := LUsable;
  if LDataLength < 0 then
  begin
    // A length of -1 (no size anywhere) is a negative number of frames for
    // one byte per frame, and no frame at all for the others
    if LDataLength div (LPcm.Channels * LPcm.BytesPerSample) < 0 then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    LDataLength := 0;
  end;

  Result := TSoundPcmReader.Read(ASource, LPcm, LDataOffset, LDataLength,
    LFileLength, False, ASamples);
end;

initialization
  MARKER_RF64 := TSoundByteReader.MarkerOf('RF64');
  MARKER_WAVE := TSoundByteReader.MarkerOf('WAVE');
  MARKER_DS64 := TSoundByteReader.MarkerOf('ds64');
  MARKER_FMT := TSoundByteReader.MarkerOf('fmt ');
  MARKER_BEXT := TSoundByteReader.MarkerOf('bext');
  MARKER_CART := TSoundByteReader.MarkerOf('cart');
  MARKER_INFO := TSoundByteReader.MarkerOf('INFO');
  MARKER_LIST := TSoundByteReader.MarkerOf('LIST');
  MARKER_PEAK := TSoundByteReader.MarkerOf('PEAK');
  MARKER_DATA := TSoundByteReader.MarkerOf('data');
  MARKER_WVPK := TSoundByteReader.MarkerOf('wvpk');
  MARKER_OGGS := TSoundByteReader.MarkerOf('OggS');

end.
