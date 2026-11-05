{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Sonic Foundry Wave64 (W64)                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.W64;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   Wave64 files: like WAV, with 16 byte GUIDs for chunk names and 64 bit
  ///   sizes, chunks aligned to 8 bytes. PCM, float, mu-law and A-law. The
  ///   header is walked the way libsndfile does, including its mistakes (it
  ///   skips the wrong number of bytes after the chunks it does not use)
  /// </summary>
  TW64Format = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader,
  DelphiDoom.Sound.WavLike.Fmt, DelphiDoom.Sound.Codec.MsAdpcm,
  DelphiDoom.Sound.Codec.ImaAdpcm, DelphiDoom.Sound.CodecSamples;

const
  HAVE_RIFF = $01;
  HAVE_WAVE = $02;
  HAVE_FMT = $04;
  HAVE_DATA = $20;

  MAX_CHANNELS = 1024;
  CHUNK_HEADER_SIZE = 24;

type
  TGuid16 = array[0..15] of Byte;

const
  GUID_RIFF: TGuid16 = (Ord('r'), Ord('i'), Ord('f'), Ord('f'), $2E, $91, $CF, $11,
    $A5, $D6, $28, $DB, $04, $C1, $00, $00);
  GUID_WAVE: TGuid16 = (Ord('w'), Ord('a'), Ord('v'), Ord('e'), $F3, $AC, $D3, $11,
    $8C, $D1, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_FMT: TGuid16 = (Ord('f'), Ord('m'), Ord('t'), Ord(' '), $F3, $AC, $D3, $11,
    $8C, $D1, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_FACT: TGuid16 = (Ord('f'), Ord('a'), Ord('c'), Ord('t'), $F3, $AC, $D3, $11,
    $8C, $D1, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_DATA: TGuid16 = (Ord('d'), Ord('a'), Ord('t'), Ord('a'), $F3, $AC, $D3, $11,
    $8C, $D1, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_ACID: TGuid16 = ($6D, $07, $1C, $EA, $A3, $EF, $78, $4C,
    $90, $57, $7F, $79, $EE, $25, $2A, $AE);
  GUID_LEVL: TGuid16 = ($6C, $65, $76, $6C, $F3, $AC, $D3, $11,
    $D1, $8C, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_LIST: TGuid16 = ($6C, $69, $73, $74, $2F, $91, $CF, $11,
    $A5, $D6, $28, $DB, $04, $C1, $00, $00);
  GUID_JUNK: TGuid16 = ($6A, $75, $6E, $6B, $F3, $AC, $D3, $11,
    $8C, $D1, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_BEXT: TGuid16 = ($62, $65, $78, $74, $F3, $AC, $D3, $AA,
    $D1, $8C, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_MARKER: TGuid16 = ($56, $62, $F7, $AB, $2D, $39, $D2, $11,
    $86, $C7, $00, $C0, $4F, $8E, $DB, $8A);
  GUID_SUMLIST: TGuid16 = ($BC, $94, $5F, $92, $5A, $52, $D2, $11,
    $86, $DC, $00, $C0, $4F, $8E, $DB, $8A);

/// <summary>
///   The "hash" libsndfile compares the GUIDs by. Not injective, and the
///   comparison is only as good as it is: kept so the same files are accepted
/// </summary>
function HashOf(const AGuid: TGuid16): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 15 do
    Result := Result xor (Integer(AGuid[LIndex]) shl LIndex);
end;

function ReadHash(var AReader: TSoundByteReader): Integer;
var
  LGuid: TGuid16;
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    LGuid[LIndex] := AReader.ReadByte;
  Result := HashOf(LGuid);
end;

function ReadInt64LittleEndian(var AReader: TSoundByteReader): Int64;
var
  LLow, LHigh: Cardinal;
begin
  LLow := AReader.ReadUInt32;
  LHigh := AReader.ReadUInt32;
  Result := Int64(LLow) or (Int64(LHigh) shl 32);
end;

{ TW64Format }

function TW64Format.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LHashRiff, LHashWave, LHashFmt, LHashFact, LHashData, LHashAcid, LHashLevl,
  LHashList, LHashJunk, LHashBext, LHashMarker, LHashSumList: Integer;
  LMarker: Integer;
  LChunkSize: Int64;
  LStage: Integer;
  LDone: Boolean;
  LLayout: TWavLikeLayout;
  LDataOffset: Int64;
  LPcm: TSoundPcmLayout;
  LCodec: Integer;
  LStart, LHeaderLength: Int64;
  LData: TBytes;
  LFrames: Int64;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  if (LFileLength < 12) or (ASource[0] <> Ord('r')) or (ASource[1] <> Ord('i')) or
     (ASource[2] <> Ord('f')) or (ASource[3] <> Ord('f')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LHashRiff := HashOf(GUID_RIFF);
  LHashWave := HashOf(GUID_WAVE);
  LHashFmt := HashOf(GUID_FMT);
  LHashFact := HashOf(GUID_FACT);
  LHashData := HashOf(GUID_DATA);
  LHashAcid := HashOf(GUID_ACID);
  LHashLevl := HashOf(GUID_LEVL);
  LHashList := HashOf(GUID_LIST);
  LHashJunk := HashOf(GUID_JUNK);
  LHashBext := HashOf(GUID_BEXT);
  LHashMarker := HashOf(GUID_MARKER);
  LHashSumList := HashOf(GUID_SUMLIST);

  LReader := TSoundByteReader.Create(ASource);
  FillChar(LLayout, SizeOf(LLayout), 0);
  LStage := 0;
  LDone := False;
  LDataOffset := -1;
  LHeaderLength := 0;

  while not LDone do
  begin
    // Every chunk starts on an 8 byte boundary
    if (LReader.Position and 7) <> 0 then
      LReader.Skip(8 - (LReader.Position and 7));

    if LReader.Position >= LFileLength then
      Break;
    LMarker := ReadHash(LReader);
    LChunkSize := ReadInt64LittleEndian(LReader);

    if LMarker = LHashRiff then
    begin
      if LStage <> 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LStage := LStage or HAVE_RIFF;
      if ReadHash(LReader) = LHashWave then
        LStage := LStage or HAVE_WAVE;
      LChunkSize := 0;
    end
    else if LMarker = LHashAcid then
      Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING)
    else if LMarker = LHashFmt then
    begin
      if (LStage and (HAVE_RIFF or HAVE_WAVE)) <> (HAVE_RIFF or HAVE_WAVE) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      // Size of the GUID and of the size field
      Dec(LChunkSize, CHUNK_HEADER_SIZE);
      if (LChunkSize < 16) or (LChunkSize > High(Integer)) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      Result := TWavLikeFmtChunk.Read(LReader, Cardinal(LChunkSize), LLayout);
      if Result <> SNDFILE_OK then
        Exit;
      if (LChunkSize mod 8) <> 0 then
        LReader.Skip(8 - (LChunkSize mod 8));
      LStage := LStage or HAVE_FMT;
      LChunkSize := 0;
    end
    else if LMarker = LHashFact then
    begin
      ReadInt64LittleEndian(LReader);
      LChunkSize := 0;
    end
    else if LMarker = LHashData then
    begin
      if (LStage and (HAVE_RIFF or HAVE_WAVE or HAVE_FMT)) <> (HAVE_RIFF or HAVE_WAVE or HAVE_FMT) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LDataOffset := LReader.Position;
      LHeaderLength := LChunkSize - CHUNK_HEADER_SIZE;
      if LHeaderLength > LFileLength - LDataOffset then
        LHeaderLength := LFileLength - LDataOffset;
      if (LChunkSize mod 8) <> 0 then
        Inc(LChunkSize, 8 - (LChunkSize mod 8));
      LStage := LStage or HAVE_DATA;
      // libsndfile skips the whole size from here, although the header is read already
      LReader.Skip(LChunkSize);
      LChunkSize := 0;
    end
    else if (LMarker = LHashLevl) or (LMarker = LHashList) or (LMarker = LHashJunk) or
            (LMarker = LHashBext) or (LMarker = LHashMarker) or (LMarker = LHashSumList) then
      Dec(LChunkSize, CHUNK_HEADER_SIZE)
    else
      LDone := True;

    if LDone then
      Break;
    if LChunkSize >= LFileLength then
      Break;
    if LReader.Position >= LFileLength - 8 then
      Break;
    if (LChunkSize > 0) and (LChunkSize < $FFFF0000) then
      // It already took the header off above: this skips 24 bytes too few
      LReader.Skip(Integer(LChunkSize) - CHUNK_HEADER_SIZE);
  end;

  if LDataOffset <= 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LLayout.Channels < 1 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LLayout.Channels >= MAX_CHANNELS then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  FillChar(LPcm, SizeOf(LPcm), 0);
  if LFileLength > LDataOffset then
    LStart := LFileLength - LDataOffset
  else
    LStart := 0;
  case LLayout.Tag of
    TWavLikeFmtChunk.WAVE_FORMAT_MS_ADPCM:
      begin
        Result := TMsAdpcmDecoder.Decode(ASource, LDataOffset, LHeaderLength,
          LLayout.Channels, LLayout.BlockAlign, LLayout.SamplesPerBlock, LData, LFrames);
        if Result = SNDFILE_OK then
          ASamples := TSoundCodecSamples.Wrap(SNDFILE_FORMAT_W64 or SNDFILE_FORMAT_MS_ADPCM,
            LLayout.Channels, LLayout.SampleRate, LFrames, LData,
            LHeaderLength mod LLayout.BlockAlign <> 0);
        Exit;
      end;
    TWavLikeFmtChunk.WAVE_FORMAT_IMA_ADPCM:
      begin
        Result := TImaAdpcmDecoder.DecodeWavLike(ASource, LDataOffset, LStart,
          LLayout.Channels, LLayout.BlockAlign, LLayout.SamplesPerBlock, LData, LFrames);
        if Result = SNDFILE_OK then
          ASamples := TSoundCodecSamples.Wrap(SNDFILE_FORMAT_W64 or SNDFILE_FORMAT_IMA_ADPCM,
            LLayout.Channels, LLayout.SampleRate, LFrames, LData);
        Exit;
      end;
    TWavLikeFmtChunk.WAVE_FORMAT_PCM, TWavLikeFmtChunk.WAVE_FORMAT_EXTENSIBLE:
      begin
        // Even an extensible file: whatever its GUID says, the width decides
        case LLayout.BytesPerSample of
          1: LCodec := SNDFILE_FORMAT_PCM_U8;
          2: LCodec := SNDFILE_FORMAT_PCM_16;
          3: LCodec := SNDFILE_FORMAT_PCM_24;
          4: LCodec := SNDFILE_FORMAT_PCM_32;
        else
          Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
        end;
        LPcm.BytesPerSample := LLayout.BytesPerSample;
      end;
    TWavLikeFmtChunk.WAVE_FORMAT_MULAW:
      begin
        LCodec := SNDFILE_FORMAT_ULAW;
        LPcm.BytesPerSample := 1;
      end;
    TWavLikeFmtChunk.WAVE_FORMAT_ALAW:
      begin
        LCodec := SNDFILE_FORMAT_ALAW;
        LPcm.BytesPerSample := 1;
      end;
    TWavLikeFmtChunk.WAVE_FORMAT_IEEE_FLOAT:
      if LLayout.BytesPerSample = 8 then
      begin
        LCodec := SNDFILE_FORMAT_DOUBLE;
        LPcm.BytesPerSample := 8;
      end
      else
      begin
        LCodec := SNDFILE_FORMAT_FLOAT;
        LPcm.BytesPerSample := 4;
      end;
  else
    // MS ADPCM, IMA ADPCM and GSM 6.10 are not read yet
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;

  LPcm.Encoding := LCodec;
  LPcm.Channels := LLayout.Channels;
  LPcm.SampleRate := LLayout.SampleRate;
  LPcm.Format := SNDFILE_FORMAT_W64 or LCodec;

  Result := TSoundPcmReader.Read(ASource, LPcm, LDataOffset, LStart, LFileLength,
    False, ASamples);
end;

end.
