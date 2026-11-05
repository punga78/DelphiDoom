{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Apple Core Audio Format (CAF)                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Caf;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   CAF files with linear PCM (8 to 32 bit, either byte order), float,
  ///   double, mu-law and A-law samples. The ALAC encoding is not read yet
  /// </summary>
  TCafFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader, DelphiDoom.Sound.Convert;

const
  SIZEOF_DESC_CHUNK = 32;
  MAX_CHANNELS = 1024;

var
  MARKER_CAFF, MARKER_DESC, MARKER_PEAK, MARKER_CHAN, MARKER_FREE, MARKER_DATA,
  MARKER_KUKI, MARKER_PAKT, MARKER_INFO, MARKER_LPCM, MARKER_ALAW, MARKER_ULAW,
  MARKER_ALAC: Cardinal;

function ReadInt64BigEndian(var AReader: TSoundByteReader): Int64;
var
  LHigh, LLow: Cardinal;
begin
  LHigh := AReader.ReadUInt32;
  LLow := AReader.ReadUInt32;
  Result := (Int64(LHigh) shl 32) or Int64(LLow);
end;

function ReadDoubleBigEndian(var AReader: TSoundByteReader): Double;
var
  LBits: Int64;
begin
  LBits := ReadInt64BigEndian(AReader);
  Move(LBits, Result, SizeOf(Result));
end;

{ TCafFormat }

function TCafFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LMarker: Cardinal;
  LChunkSize, LDataLength, LDataOffset, LDataEnd: Int64;
  LSampleRate: Double;
  LFormatId, LFormatFlags, LPacketBytes, LChannels, LBitsPerChannel: Cardinal;
  LHaveData: Boolean;
  LLayout: TSoundPcmLayout;
  LBigEndian: Boolean;
  LEndianFlag, LCodec, LByteWidth: Integer;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := True;

  // The 'caff' marker and 'desc' right after the version and the flags
  if LFileLength < 12 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  if LReader.ReadMarker <> MARKER_CAFF then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.Position := 8;
  if LReader.ReadMarker <> MARKER_DESC then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LReader.Position := 8;
  LMarker := LReader.ReadMarker;
  LChunkSize := ReadInt64BigEndian(LReader);
  LSampleRate := ReadDoubleBigEndian(LReader);
  if LChunkSize < SIZEOF_DESC_CHUNK then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LFormatId := LReader.ReadMarker;
  LFormatFlags := LReader.ReadUInt32;
  LPacketBytes := LReader.ReadUInt32;
  LReader.ReadUInt32;                    // frames per packet
  LChannels := LReader.ReadUInt32;
  LBitsPerChannel := LReader.ReadUInt32;
  if LChannels > MAX_CHANNELS then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LChunkSize > SIZEOF_DESC_CHUNK then
    LReader.Skip(Integer(LChunkSize - SIZEOF_DESC_CHUNK));

  LHaveData := False;
  LDataOffset := 0;
  LDataLength := 0;
  LDataEnd := 0;

  while True do
  begin
    LMarker := LReader.ReadMarker;
    LChunkSize := ReadInt64BigEndian(LReader);
    if LReader.Overrun then
      LMarker := 0;
    if LMarker = 0 then
      Break;
    if LChunkSize < 0 then
      Break;
    if LChunkSize > LFileLength then
      Break;

    if LMarker = MARKER_PEAK then
    begin
      if LChunkSize <> 4 + Int64(LChannels) * 12 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_DATA then
    begin
      LReader.ReadUInt32;                // edit count
      if LChunkSize > LFileLength - LReader.Position + 10 then
        LDataLength := LFileLength - LReader.Position - 8
      else
        // Without the 4 bytes of the edit count
        LDataLength := LChunkSize - 4;
      LDataOffset := LReader.Position;
      if LDataLength + LDataOffset < LFileLength then
        LDataEnd := LDataLength + LDataOffset;
      LReader.Skip(LDataLength);
      LHaveData := True;
    end
    else if LMarker = MARKER_PAKT then
    begin
      if (LChunkSize < 24) or (LChunkSize > LFileLength - LReader.Position) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_INFO then
    begin
      if (LChunkSize < 4) or (LChunkSize > LFileLength - LReader.Position) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LReader.Skip(LChunkSize);
    end
    else
      // 'chan', 'free', 'kuki' and the chunks nobody knows: skipped
      LReader.Skip(LChunkSize);

    if (LMarker <> MARKER_DATA) and (LChunkSize >= $FFFFFF00) then
      Break;
    if LReader.Position >= LFileLength - 8 then
      Break;
  end;

  if not LHaveData then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // The samples are big endian unless the flags say otherwise
  LBigEndian := (LFormatFlags and 2) = 0;
  if LBigEndian then
    LEndianFlag := 0
  else
    LEndianFlag := SNDFILE_FORMAT_ENDIAN_LITTLE;

  LCodec := 0;
  LByteWidth := 0;
  if LFormatId = MARKER_ALAC then
    // Apple Lossless: not read yet
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  if (LFormatId = MARKER_LPCM) and ((LFormatFlags and 1) <> 0) then
  begin
    if (LBitsPerChannel = 32) and (LPacketBytes = 4 * LChannels) then
    begin
      LByteWidth := 4;
      LCodec := SNDFILE_FORMAT_FLOAT;
    end
    else if (LBitsPerChannel = 64) and (LPacketBytes = 8 * LChannels) then
    begin
      LByteWidth := 8;
      LCodec := SNDFILE_FORMAT_DOUBLE;
    end;
  end
  else if LFormatId = MARKER_LPCM then
  begin
    if (LBitsPerChannel = 32) and (LPacketBytes = 4 * LChannels) then
    begin
      LByteWidth := 4;
      LCodec := SNDFILE_FORMAT_PCM_32;
    end
    else if (LBitsPerChannel = 24) and (LPacketBytes = 3 * LChannels) then
    begin
      LByteWidth := 3;
      LCodec := SNDFILE_FORMAT_PCM_24;
    end
    else if (LBitsPerChannel = 16) and (LPacketBytes = 2 * LChannels) then
    begin
      LByteWidth := 2;
      LCodec := SNDFILE_FORMAT_PCM_16;
    end
    else if (LBitsPerChannel = 8) and (LPacketBytes = LChannels) then
    begin
      LByteWidth := 1;
      LCodec := SNDFILE_FORMAT_PCM_S8;
    end;
  end;
  if (LCodec = 0) and (LFormatId = MARKER_ALAW) and (LBitsPerChannel = 8) then
  begin
    LByteWidth := 1;
    LCodec := SNDFILE_FORMAT_ALAW;
  end;
  if (LCodec = 0) and (LFormatId = MARKER_ULAW) and (LBitsPerChannel = 8) then
  begin
    LByteWidth := 1;
    LCodec := SNDFILE_FORMAT_ULAW;
  end;
  if LCodec = 0 then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := LCodec;
  LLayout.BytesPerSample := LByteWidth;
  LLayout.Channels := Integer(LChannels);
  LLayout.SampleRate := TSoundConvert.RoundToLong(LSampleRate);
  LLayout.Format := SNDFILE_FORMAT_CAF or LEndianFlag or LCodec;

  // The decoders measure the data again
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
  MARKER_CAFF := TSoundByteReader.MarkerOf('caff');
  MARKER_DESC := TSoundByteReader.MarkerOf('desc');
  MARKER_PEAK := TSoundByteReader.MarkerOf('peak');
  MARKER_CHAN := TSoundByteReader.MarkerOf('chan');
  MARKER_FREE := TSoundByteReader.MarkerOf('free');
  MARKER_DATA := TSoundByteReader.MarkerOf('data');
  MARKER_KUKI := TSoundByteReader.MarkerOf('kuki');
  MARKER_PAKT := TSoundByteReader.MarkerOf('pakt');
  MARKER_INFO := TSoundByteReader.MarkerOf('info');
  MARKER_LPCM := TSoundByteReader.MarkerOf('lpcm');
  MARKER_ALAW := TSoundByteReader.MarkerOf('alaw');
  MARKER_ULAW := TSoundByteReader.MarkerOf('ulaw');
  MARKER_ALAC := TSoundByteReader.MarkerOf('alac');

end.
