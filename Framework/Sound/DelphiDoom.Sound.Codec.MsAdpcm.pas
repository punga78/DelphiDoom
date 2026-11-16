{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Microsoft ADPCM                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.MsAdpcm;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Decodes the blocks of Microsoft ADPCM, mono or stereo, the way
  ///   libsndfile does: the predictors are the seven fixed ones whatever the
  ///   'fmt ' chunk says, and the arithmetic is done on 16 bit values
  /// </summary>
  TMsAdpcmDecoder = class
  public
    /// <summary>
    ///   Decodes the whole blocks that fit in ADataLength bytes from
    ///   ADataOffset. AData receives 16 bit samples (little endian, as they
    ///   are in memory), AFrames how many frames there are
    /// </summary>
    class function Decode(const ASource: TBytes; ADataOffset, ADataLength: Int64;
      AChannels, ABlockSize, ASamplesPerBlock: Integer; out AData: TBytes;
      out AFrames: Int64): Integer; static;
  end;

implementation

const
  COEFF_COUNT = 7;
  ADAPTATION: array[0..15] of Integer = (230, 230, 230, 230, 307, 409, 512, 614,
    768, 614, 512, 409, 307, 230, 230, 230);
  COEFF_1: array[0..COEFF_COUNT - 1] of Integer = (256, 512, 0, 192, 240, 460, 392);
  COEFF_2: array[0..COEFF_COUNT - 1] of Integer = (0, -256, 0, 64, 0, -208, -232);

/// <summary>Shift right keeping the sign, whatever the compiler does with shr</summary>
function ShiftRight8(AValue: Integer): Integer;
begin
  Result := (AValue - (AValue and $FF)) div 256;
end;

function PredictorOf(AValue: Byte): Integer;
begin
  // A value out of range counts as the first predictor
  if AValue >= COEFF_COUNT then
    Result := 0
  else
    Result := AValue;
end;

function Word16(const ABlock: TBytes; AIndex: Integer): SmallInt;
begin
  Result := SmallInt(ABlock[AIndex] or (ABlock[AIndex + 1] shl 8));
end;

procedure DecodeBlock(const ABlock: TBytes; AChannels, ABlockSize,
  ASamplesPerBlock: Integer; var ASamples: TArray<SmallInt>);
var
  LPredictor: array[0..1] of Integer;
  LDelta: array[0..1] of SmallInt;
  LBlockIndex, LSampleIndex, LIndex, LChannel, LByteCode, LDeltaNow, LPredict,
  LCurrent: Integer;
begin
  if AChannels = 1 then
  begin
    LPredictor[0] := PredictorOf(ABlock[0]);
    LDelta[0] := Word16(ABlock, 1);
    LDelta[1] := 0;
    ASamples[1] := Word16(ABlock, 3);
    ASamples[0] := Word16(ABlock, 5);
    LBlockIndex := 7;
  end
  else
  begin
    LPredictor[0] := PredictorOf(ABlock[0]);
    LPredictor[1] := PredictorOf(ABlock[1]);
    LDelta[0] := Word16(ABlock, 2);
    LDelta[1] := Word16(ABlock, 4);
    ASamples[2] := Word16(ABlock, 6);
    ASamples[3] := Word16(ABlock, 8);
    ASamples[0] := Word16(ABlock, 10);
    ASamples[1] := Word16(ABlock, 12);
    LBlockIndex := 14;
  end;

  // The packed 4 bit samples, high nibble first
  LSampleIndex := 2 * AChannels;
  while LBlockIndex < ABlockSize do
  begin
    ASamples[LSampleIndex] := (ABlock[LBlockIndex] shr 4) and $0F;
    ASamples[LSampleIndex + 1] := ABlock[LBlockIndex] and $0F;
    Inc(LSampleIndex, 2);
    Inc(LBlockIndex);
  end;

  for LIndex := 2 * AChannels to ASamplesPerBlock * AChannels - 1 do
  begin
    if AChannels > 1 then
      LChannel := LIndex mod 2
    else
      LChannel := 0;
    LByteCode := ASamples[LIndex] and $F;

    LDeltaNow := LDelta[LChannel];
    LDelta[LChannel] := SmallInt(ShiftRight8(ADAPTATION[LByteCode] * LDeltaNow));
    if LDelta[LChannel] < 16 then
      LDelta[LChannel] := 16;
    if (LByteCode and 8) <> 0 then
      Dec(LByteCode, $10);

    LPredict := ShiftRight8(ASamples[LIndex - AChannels] * COEFF_1[LPredictor[LChannel]] +
      ASamples[LIndex - 2 * AChannels] * COEFF_2[LPredictor[LChannel]]);
    LCurrent := LByteCode * LDeltaNow + LPredict;
    if LCurrent > 32767 then
      LCurrent := 32767
    else if LCurrent < -32768 then
      LCurrent := -32768;
    ASamples[LIndex] := SmallInt(LCurrent);
  end;
end;

{ TMsAdpcmDecoder }

class function TMsAdpcmDecoder.Decode(const ASource: TBytes; ADataOffset,
  ADataLength: Int64; AChannels, ABlockSize, ASamplesPerBlock: Integer;
  out AData: TBytes; out AFrames: Int64): Integer;
var
  LBlocks, LBlock: Int64;
  LBytes: TBytes;
  LSamples: TArray<SmallInt>;
  LCount, LAvailable, LPosition: Int64;
  LBlockSamples: Integer;
begin
  AData := nil;
  AFrames := 0;
  if (AChannels < 1) or (AChannels > 2) or (ABlockSize < 7 * AChannels) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if ASamplesPerBlock <> 2 * (ABlockSize - 6 * AChannels) div AChannels then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if ADataLength < 0 then
    ADataLength := 0;

  // A last block that is not whole is not part of the sound
  LBlocks := ADataLength div ABlockSize;
  AFrames := LBlocks * ASamplesPerBlock;
  LBlockSamples := ASamplesPerBlock * AChannels;
  SetLength(AData, AFrames * AChannels * SizeOf(SmallInt));
  SetLength(LBytes, ABlockSize);
  SetLength(LSamples, LBlockSamples);

  for LBlock := 0 to LBlocks - 1 do
  begin
    // The data may well go on after the end of the sound: libsndfile reads it
    LPosition := ADataOffset + LBlock * ABlockSize;
    LAvailable := Length(ASource) - LPosition;
    if LAvailable > ABlockSize then
      LAvailable := ABlockSize;
    LCount := LAvailable;
    if LCount > 0 then
      Move(ASource[Integer(LPosition)], LBytes[0], Integer(LCount));
    DecodeBlock(LBytes, AChannels, ABlockSize, ASamplesPerBlock, LSamples);
    Move(LSamples[0], AData[Integer(LBlock * LBlockSamples * SizeOf(SmallInt))],
      LBlockSamples * SizeOf(SmallInt));
  end;
  Result := SNDFILE_OK;
end;

end.
