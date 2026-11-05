{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - IMA ADPCM                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.ImaAdpcm;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Decodes the blocks of IMA ADPCM as libsndfile does, for the two layouts
  ///   it knows: the one of WAV and W64 (a header of four bytes per channel,
  ///   samples interleaved by groups of eight) and the one of AIFF-C 'ima4'
  ///   (34 bytes per channel and block, 64 samples each)
  /// </summary>
  TImaAdpcmDecoder = class
  public
    /// <summary>
    ///   WAV and W64. The last block, if it is cut short, is decoded too,
    ///   with whatever the buffer of the previous block still held
    /// </summary>
    class function DecodeWavLike(const ASource: TBytes; ADataOffset, ADataLength: Int64;
      AChannels, ABlockSize, ASamplesPerBlock: Integer; out AData: TBytes;
      out AFrames: Int64): Integer; static;
    class function DecodeAiff(const ASource: TBytes; ADataOffset, ADataLength: Int64;
      AChannels: Integer; out AData: TBytes; out AFrames: Int64): Integer; static;
  end;

implementation

const
  INDEX_ADJUST: array[0..15] of Integer = (-1, -1, -1, -1, 2, 4, 6, 8,
    -1, -1, -1, -1, 2, 4, 6, 8);
  STEP_SIZE: array[0..88] of Integer = (7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19,
    21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
    130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494,
    544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878,
    2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484,
    7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500,
    20350, 22385, 24623, 27086, 29794, 32767);

  // IMA ADPCM in AIFF-C: always these
  AIFF_BLOCK_SIZE = 34;
  AIFF_SAMPLES_PER_BLOCK = 64;

function ClampStep(AIndex: Integer): Integer;
begin
  if AIndex < 0 then
    Result := 0
  else if AIndex >= Length(STEP_SIZE) then
    Result := Length(STEP_SIZE) - 1
  else
    Result := AIndex;
end;

function Diff(AStep, AByteCode: Integer): Integer;
begin
  Result := AStep div 8;
  if (AByteCode and 1) <> 0 then
    Inc(Result, AStep div 4);
  if (AByteCode and 2) <> 0 then
    Inc(Result, AStep div 2);
  if (AByteCode and 4) <> 0 then
    Inc(Result, AStep);
  if (AByteCode and 8) <> 0 then
    Result := -Result;
end;

{ TImaAdpcmDecoder }

class function TImaAdpcmDecoder.DecodeWavLike(const ASource: TBytes; ADataOffset,
  ADataLength: Int64; AChannels, ABlockSize, ASamplesPerBlock: Integer;
  out AData: TBytes; out AFrames: Int64): Integer;
var
  LBlocks, LBlock, LPosition: Int64;
  LBlockBytes: TBytes;
  LSamples: TArray<SmallInt>;
  LStepIndex: array[0..1] of Integer;
  LPredictor, LBlockIndex, LIndexStart, LChannel, LIndex, LByteCode, LStep, LCount,
  LRead, LBlockSamples: Integer;
begin
  AData := nil;
  AFrames := 0;
  if (AChannels < 1) or (AChannels > 2) or (ABlockSize <= 0) or (ASamplesPerBlock <= 0) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LCount := 2 * (ABlockSize - 4 * AChannels) div AChannels + 1;
  if ASamplesPerBlock <> LCount then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  // The nibbles come in groups of four bytes per channel
  if ((ABlockSize - 4 * AChannels) mod (4 * AChannels)) <> 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if ADataLength < 0 then
    ADataLength := 0;

  LBlocks := ADataLength div ABlockSize;
  if (ADataLength mod ABlockSize) <> 0 then
    Inc(LBlocks);
  AFrames := LBlocks * ASamplesPerBlock;
  LBlockSamples := ASamplesPerBlock * AChannels;
  SetLength(AData, AFrames * AChannels * SizeOf(SmallInt));
  SetLength(LBlockBytes, ABlockSize * AChannels);
  SetLength(LSamples, LBlockSamples);

  for LBlock := 0 to LBlocks - 1 do
  begin
    LPosition := ADataOffset + LBlock * ABlockSize;
    LRead := Length(ASource) - LPosition;
    if LRead > ABlockSize then
      LRead := ABlockSize;
    if LRead > 0 then
      Move(ASource[Integer(LPosition)], LBlockBytes[0], LRead);

    for LChannel := 0 to AChannels - 1 do
    begin
      LPredictor := LBlockBytes[LChannel * 4] or (LBlockBytes[LChannel * 4 + 1] shl 8);
      if (LPredictor and $8000) <> 0 then
        Dec(LPredictor, $10000);
      LStepIndex[LChannel] := ClampStep(LBlockBytes[LChannel * 4 + 2]);
      LSamples[LChannel] := SmallInt(LPredictor);
    end;

    LBlockIndex := 4 * AChannels;
    LIndexStart := AChannels;
    while LBlockIndex < ABlockSize do
    begin
      for LChannel := 0 to AChannels - 1 do
      begin
        LIndex := LIndexStart + LChannel;
        for LCount := 0 to 3 do
        begin
          LByteCode := LBlockBytes[LBlockIndex];
          Inc(LBlockIndex);
          LSamples[LIndex] := LByteCode and $0F;
          Inc(LIndex, AChannels);
          LSamples[LIndex] := (LByteCode shr 4) and $0F;
          Inc(LIndex, AChannels);
        end;
      end;
      Inc(LIndexStart, 8 * AChannels);
    end;

    for LIndex := AChannels to LBlockSamples - 1 do
    begin
      if AChannels > 1 then
        LChannel := LIndex mod 2
      else
        LChannel := 0;
      LByteCode := LSamples[LIndex] and $F;
      LStep := STEP_SIZE[LStepIndex[LChannel]];
      LPredictor := LSamples[LIndex - AChannels];
      Inc(LPredictor, Diff(LStep, LByteCode));
      if LPredictor > 32767 then
        LPredictor := 32767
      else if LPredictor < -32768 then
        LPredictor := -32768;
      LStepIndex[LChannel] := ClampStep(LStepIndex[LChannel] + INDEX_ADJUST[LByteCode]);
      LSamples[LIndex] := SmallInt(LPredictor);
    end;

    Move(LSamples[0], AData[Integer(LBlock * LBlockSamples * SizeOf(SmallInt))],
      LBlockSamples * SizeOf(SmallInt));
  end;
  Result := SNDFILE_OK;
end;

class function TImaAdpcmDecoder.DecodeAiff(const ASource: TBytes; ADataOffset,
  ADataLength: Int64; AChannels: Integer; out AData: TBytes;
  out AFrames: Int64): Integer;
var
  LBlocks, LGroup, LGroupCount, LPosition: Int64;
  LBlockBytes: TBytes;
  LSamples: TArray<SmallInt>;
  LChannel, LK, LByteCode, LPredictor, LStepIndex, LStep, LRead, LOffset,
  LGroupSamples: Integer;
begin
  AData := nil;
  AFrames := 0;
  if (AChannels < 1) or (AChannels > 2) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if ADataLength < 0 then
    ADataLength := 0;

  LBlocks := ADataLength div AIFF_BLOCK_SIZE;
  if (ADataLength mod AIFF_BLOCK_SIZE) <> 0 then
    Inc(LBlocks);
  AFrames := AIFF_SAMPLES_PER_BLOCK * LBlocks div AChannels;
  LGroupSamples := AIFF_SAMPLES_PER_BLOCK * AChannels;
  SetLength(AData, AFrames * AChannels * SizeOf(SmallInt));
  SetLength(LBlockBytes, AIFF_BLOCK_SIZE * AChannels);
  SetLength(LSamples, LGroupSamples);

  // One group is a block of every channel
  LGroupCount := (AFrames * AChannels + LGroupSamples - 1) div LGroupSamples;
  for LGroup := 0 to LGroupCount - 1 do
  begin
    if (LGroup + 1) * AChannels > LBlocks then
      // Past the last block libsndfile gives silence
      FillChar(LSamples[0], LGroupSamples * SizeOf(SmallInt), 0)
    else
    begin
      LPosition := ADataOffset + LGroup * AIFF_BLOCK_SIZE * AChannels;
      LRead := Length(ASource) - LPosition;
      if LRead > AIFF_BLOCK_SIZE * AChannels then
        LRead := AIFF_BLOCK_SIZE * AChannels;
      if LRead > 0 then
        Move(ASource[Integer(LPosition)], LBlockBytes[0], LRead);

      for LChannel := 0 to AChannels - 1 do
      begin
        LOffset := LChannel * AIFF_BLOCK_SIZE;
        LPredictor := SmallInt((LBlockBytes[LOffset] shl 8) or (LBlockBytes[LOffset + 1] and $80));
        LStepIndex := ClampStep(LBlockBytes[LOffset + 1] and $7F);

        for LK := 0 to AIFF_BLOCK_SIZE - 3 do
        begin
          LByteCode := LBlockBytes[LOffset + LK + 2];
          LSamples[AChannels * (2 * LK) + LChannel] := LByteCode and $F;
          LSamples[AChannels * (2 * LK + 1) + LChannel] := (LByteCode shr 4) and $F;
        end;

        for LK := 0 to AIFF_SAMPLES_PER_BLOCK - 1 do
        begin
          LStep := STEP_SIZE[LStepIndex];
          LByteCode := LSamples[AChannels * LK + LChannel];
          LStepIndex := ClampStep(LStepIndex + INDEX_ADJUST[LByteCode]);
          Inc(LPredictor, Diff(LStep, LByteCode));
          if LPredictor < -32768 then
            LPredictor := -32768
          else if LPredictor > 32767 then
            LPredictor := 32767;
          LSamples[AChannels * LK + LChannel] := SmallInt(LPredictor);
        end;
      end;
    end;

    LK := Integer(LGroup * LGroupSamples);
    LOffset := LGroupSamples;
    if (LGroup + 1) * LGroupSamples > AFrames * AChannels then
      LOffset := Integer(AFrames * AChannels) - LK;
    Move(LSamples[0], AData[LK * SizeOf(SmallInt)], LOffset * SizeOf(SmallInt));
  end;
  Result := SNDFILE_OK;
end;

end.
