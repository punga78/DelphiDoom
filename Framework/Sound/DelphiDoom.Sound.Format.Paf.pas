{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Ensoniq PARIS files                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Paf;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   Ensoniq PARIS files: 2048 bytes of header, then 8 or 16 bit samples, or
  ///   24 bit ones packed in blocks of 32 bytes that hold 10 samples of one
  ///   channel. The blocks of the channels follow one another
  /// </summary>
  TPafFormat = class(TInterfacedObject, ISoundFormat)
  private
    function Decode24(const ASource: TBytes; AChannels, ASampleRate: Integer;
      ALittleEndian: Boolean; out ASamples: TSoundSamples): Integer;
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.PcmReader;

const
  HEADER_LENGTH = 2048;
  SAMPLES_PER_BLOCK = 10;
  BLOCK_SIZE = 32;
  MAX_CHANNELS = 1024;
  PAF_PCM_16 = 0;
  PAF_PCM_24 = 1;
  PAF_PCM_S8 = 2;

{ TPafFormat }

function TPafFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LBigMarker, LLittleMarker: Boolean;
  LFields: array[0..5] of Cardinal;
  LIndex: Integer;
  LLittle: Boolean;
  LLayout: TSoundPcmLayout;
  LEndian: Integer;
begin
  ASamples := nil;
  if Length(ASource) < 4 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  // " paf" marks a file with big endian numbers in the header, "fap " little endian ones
  LBigMarker := (ASource[0] = Ord(' ')) and (ASource[1] = Ord('p')) and
    (ASource[2] = Ord('a')) and (ASource[3] = Ord('f'));
  LLittleMarker := (ASource[0] = Ord('f')) and (ASource[1] = Ord('a')) and
    (ASource[2] = Ord('p')) and (ASource[3] = Ord(' '));
  if not (LBigMarker or LLittleMarker) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  if Length(ASource) < HEADER_LENGTH then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  for LIndex := 0 to 5 do
    if LBigMarker then
      LFields[LIndex] := (Cardinal(ASource[4 + LIndex * 4]) shl 24) or
        (Cardinal(ASource[5 + LIndex * 4]) shl 16) or
        (Cardinal(ASource[6 + LIndex * 4]) shl 8) or ASource[7 + LIndex * 4]
    else
      LFields[LIndex] := (Cardinal(ASource[7 + LIndex * 4]) shl 24) or
        (Cardinal(ASource[6 + LIndex * 4]) shl 16) or
        (Cardinal(ASource[5 + LIndex * 4]) shl 8) or ASource[4 + LIndex * 4];

  // version, endianness of the samples, rate, format, channels, source
  if LFields[0] <> 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if (Integer(LFields[4]) < 1) or (Integer(LFields[4]) > MAX_CHANNELS) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LLittle := LFields[1] <> 0;

  if LFields[3] = PAF_PCM_24 then
    Exit(Decode24(ASource, Integer(LFields[4]), Integer(LFields[2]), LLittle, ASamples));

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Channels := Integer(LFields[4]);
  LLayout.SampleRate := Integer(LFields[2]);
  if LLittle then
    LEndian := SNDFILE_FORMAT_ENDIAN_LITTLE
  else
    LEndian := SNDFILE_FORMAT_ENDIAN_BIG;
  case LFields[3] of
    PAF_PCM_S8:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_S8;
        LLayout.BytesPerSample := 1;
      end;
    PAF_PCM_16:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_16;
        LLayout.BytesPerSample := 2;
      end;
  else
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;
  LLayout.Format := SNDFILE_FORMAT_PAF or LEndian or LLayout.Encoding;

  Result := TSoundPcmReader.Read(ASource, LLayout, HEADER_LENGTH,
    Length(ASource) - HEADER_LENGTH, Length(ASource), not LLittle, ASamples);
end;

function TPafFormat.Decode24(const ASource: TBytes; AChannels,
  ASampleRate: Integer; ALittleEndian: Boolean;
  out ASamples: TSoundSamples): Integer;
var
  LInfo: TSoundFileInfo;
  LDataLength, LBlockSize, LMaxBlocks, LBlock, LK, LIndex, LAvailable, LOffset, LChannel: Integer;
  LStale: TBytes;
  LValues: TArray<Integer>;
  LBytes: TBytes;
  LTemp: Byte;
  LPointer: Integer;
begin
  LDataLength := Length(ASource) - HEADER_LENGTH;
  LBlockSize := BLOCK_SIZE * AChannels;
  if (LDataLength mod BLOCK_SIZE) <> 0 then
    LMaxBlocks := LDataLength div LBlockSize + 1
  else
    LMaxBlocks := LDataLength div LBlockSize;

  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.Channels := AChannels;
  LInfo.SampleRate := ASampleRate;
  LInfo.Frames := Int64(SAMPLES_PER_BLOCK) * LMaxBlocks;
  LInfo.Sections := 1;
  LInfo.Seekable := 1;
  LInfo.Format := SNDFILE_FORMAT_PAF or SNDFILE_FORMAT_PCM_24;
  if ALittleEndian then
    LInfo.Format := LInfo.Format or SNDFILE_FORMAT_ENDIAN_LITTLE
  else
    LInfo.Format := LInfo.Format or SNDFILE_FORMAT_ENDIAN_BIG;

  SetLength(LValues, LInfo.Frames * AChannels);
  // The buffer of the block stays as it is when the file has less than a whole
  // block: what is missing is what the previous block left (already swapped)
  SetLength(LStale, LBlockSize);
  for LBlock := 0 to LMaxBlocks - 1 do
  begin
    LOffset := HEADER_LENGTH + LBlock * LBlockSize;
    LAvailable := Length(ASource) - LOffset;
    if LAvailable > LBlockSize then
      LAvailable := LBlockSize;
    if LAvailable > 0 then
      Move(ASource[LOffset], LStale[0], LAvailable);

    // the ints of the block are written in the endianness of the file
    if not ALittleEndian then
      for LIndex := 0 to 8 * AChannels - 1 do
      begin
        LTemp := LStale[LIndex * 4];
        LStale[LIndex * 4] := LStale[LIndex * 4 + 3];
        LStale[LIndex * 4 + 3] := LTemp;
        LTemp := LStale[LIndex * 4 + 1];
        LStale[LIndex * 4 + 1] := LStale[LIndex * 4 + 2];
        LStale[LIndex * 4 + 2] := LTemp;
      end;

    for LK := 0 to SAMPLES_PER_BLOCK * AChannels - 1 do
    begin
      LChannel := LK mod AChannels;
      LPointer := BLOCK_SIZE * LChannel + 3 * (LK div AChannels);
      LValues[LBlock * SAMPLES_PER_BLOCK * AChannels + LK] := Integer(
        (Cardinal(LStale[LPointer]) shl 8) or (Cardinal(LStale[LPointer + 1]) shl 16) or
        (Cardinal(LStale[LPointer + 2]) shl 24));
    end;
  end;

  SetLength(LBytes, Length(LValues) * SizeOf(Integer));
  if Length(LValues) > 0 then
    Move(LValues[0], LBytes[0], Length(LBytes));
  ASamples := TSoundSamples.Create(LInfo, TSoundSampleKind.Int32, LBytes, -1);
  Result := SNDFILE_OK;
end;

end.
