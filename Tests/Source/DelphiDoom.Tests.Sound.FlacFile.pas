{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds FLAC files in memory        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.FlacFile;

interface

uses
  System.SysUtils;

type
  TSoundTestFlacSubframe = (Constant, Verbatim, Fixed, Lpc);

  /// <summary>How the file is made; every field has a default that makes a plain file</summary>
  TSoundTestFlacOptions = record
    Channels: Integer;
    BitsPerSample: Integer;
    SampleRate: Integer;
    BlockSize: Integer;
    Subframe: TSoundTestFlacSubframe;
    /// <summary>Order of the fixed predictor (0 to 4) or of the LPC one</summary>
    Order: Integer;
    PartitionOrder: Integer;
    /// <summary>Rice parameters of 5 bits and an escape that does not fit</summary>
    Rice2: Boolean;
    /// <summary>Write the partitions with the escape code and raw samples</summary>
    UseEscape: Boolean;
    /// <summary>0 independent, 1 left-side, 2 right-side, 3 mid-side</summary>
    Assignment: Integer;
    /// <summary>Total samples written in STREAMINFO: -2 for the real number</summary>
    TotalSamples: Int64;
    /// <summary>The sample rate and the bits of each frame say "see STREAMINFO"</summary>
    HeaderFromStreamInfo: Boolean;
    /// <summary>Metadata blocks (padding and a comment) before the last one</summary>
    ExtraMetadata: Boolean;
    /// <summary>Spoil the CRC-16 of this frame (-1 for none)</summary>
    BadCrcFrame: Integer;
    /// <summary>Spoil the CRC-8 of the header of this frame (-1 for none)</summary>
    BadHeaderFrame: Integer;
    /// <summary>Bytes of garbage between the frames</summary>
    Garbage: Integer;
    /// <summary>The samples have this many zero low bits (wasted bits)</summary>
    WastedBits: Integer;
    class function Plain: TSoundTestFlacOptions; static;
  end;

  TSoundTestFlacFile = class
  public
    /// <summary>
    ///   ASamples[channel][index]: values that fit BitsPerSample (and have
    ///   WastedBits zero low bits)
    /// </summary>
    class function Build(const AOptions: TSoundTestFlacOptions;
      const ASamples: TArray<TArray<Integer>>): TBytes; static;
    /// <summary>A deterministic signal: a few sines and some noise</summary>
    class function Signal(ACount, ABits, ASeed: Integer): TArray<Integer>; static;
  end;

implementation

uses
  System.Math;

type
  TBitWriter = record
    Bytes: TBytes;
    Count: Integer;
    Bits: Integer;
    procedure Write(AValue: Cardinal; ACount: Integer);
    procedure WriteSigned(AValue: Integer; ACount: Integer);
    procedure WriteUnary(AValue: Cardinal);
    procedure Align;
  end;

var
  Crc8Table: array[0..255] of Byte;
  Crc16Table: array[0..255] of Word;

procedure InitTables;
var
  LIndex, LBit: Integer;
  LCrc8: Byte;
  LCrc16: Word;
begin
  for LIndex := 0 to 255 do
  begin
    LCrc8 := LIndex;
    LCrc16 := LIndex shl 8;
    for LBit := 0 to 7 do
    begin
      if (LCrc8 and $80) <> 0 then
        LCrc8 := Byte((LCrc8 shl 1) xor $07)
      else
        LCrc8 := Byte(LCrc8 shl 1);
      if (LCrc16 and $8000) <> 0 then
        LCrc16 := Word((LCrc16 shl 1) xor $8005)
      else
        LCrc16 := Word(LCrc16 shl 1);
    end;
    Crc8Table[LIndex] := LCrc8;
    Crc16Table[LIndex] := LCrc16;
  end;
end;

{ TBitWriter }

procedure TBitWriter.Write(AValue: Cardinal; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := ACount - 1 downto 0 do
  begin
    Bits := (Bits shl 1) or Integer((AValue shr LIndex) and 1);
    Inc(Count);
    if Count = 8 then
    begin
      SetLength(Bytes, Length(Bytes) + 1);
      Bytes[High(Bytes)] := Byte(Bits);
      Count := 0;
      Bits := 0;
    end;
  end;
end;

procedure TBitWriter.WriteSigned(AValue: Integer; ACount: Integer);
begin
  if ACount > 0 then
    Write(Cardinal(AValue) and (Cardinal($FFFFFFFF) shr (32 - ACount)), ACount);
end;

procedure TBitWriter.WriteUnary(AValue: Cardinal);
begin
  while AValue > 0 do
  begin
    Write(0, 1);
    Dec(AValue);
  end;
  Write(1, 1);
end;

procedure TBitWriter.Align;
begin
  if Count > 0 then
    Write(0, 8 - Count);
end;

{ TSoundTestFlacOptions }

class function TSoundTestFlacOptions.Plain: TSoundTestFlacOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Channels := 1;
  Result.BitsPerSample := 16;
  Result.SampleRate := 44100;
  Result.BlockSize := 1152;
  Result.Subframe := TSoundTestFlacSubframe.Fixed;
  Result.Order := 2;
  Result.PartitionOrder := 2;
  Result.TotalSamples := -2;
  Result.BadCrcFrame := -1;
  Result.BadHeaderFrame := -1;
end;

{ TSoundTestFlacFile }

class function TSoundTestFlacFile.Signal(ACount, ABits, ASeed: Integer): TArray<Integer>;
var
  LIndex: Integer;
  LAmplitude: Double;
  LState: Cardinal;
  LNoise: Integer;
begin
  SetLength(Result, ACount);
  LState := Cardinal(ASeed) * 2654435761 + 12345;
  LAmplitude := (Int64(1) shl (ABits - 1)) * 0.45;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := LState * 1664525 + 1013904223;
    LNoise := Integer((LState shr 24) and $3F) - 32;
    Result[LIndex] := Round(LAmplitude * Sin(LIndex * 0.031 + ASeed) +
      LAmplitude * 0.3 * Sin(LIndex * 0.37)) + LNoise;
  end;
end;

class function TSoundTestFlacFile.Build(const AOptions: TSoundTestFlacOptions;
  const ASamples: TArray<TArray<Integer>>): TBytes;
var
  LOut: TBitWriter;
  LSamples: Integer;
  LFrame, LFrames, LStart, LBlock, LChannel, LIndex, LSubframeBits, LTotal: Integer;
  LCoded: TArray<TArray<Integer>>;
  LHeaderStart, LHeaderEnd, LCrcIndex: Integer;
  LCrc8: Byte;
  LCrc16: Word;
  LBytes: TBytes;

  procedure WriteStreamInfo(AIsLast: Boolean);
  var
    LMax, LMd5Byte: Integer;
    LTotalSamples: Int64;
  begin
    LOut.Write(Ord(AIsLast), 1);
    LOut.Write(0, 7);
    LOut.Write(34, 24);
    LMax := AOptions.BlockSize;
    LOut.Write(Cardinal(LMax), 16);
    LOut.Write(Cardinal(LMax), 16);
    LOut.Write(0, 24);
    LOut.Write(0, 24);
    LOut.Write(Cardinal(AOptions.SampleRate), 20);
    LOut.Write(Cardinal(AOptions.Channels - 1), 3);
    LOut.Write(Cardinal(AOptions.BitsPerSample - 1), 5);
    if AOptions.TotalSamples = -2 then
      LTotalSamples := LSamples
    else
      LTotalSamples := AOptions.TotalSamples;
    LOut.Write(Cardinal(LTotalSamples shr 32), 4);
    LOut.Write(Cardinal(LTotalSamples and $FFFFFFFF), 32);
    for LMd5Byte := 1 to 16 do
      LOut.Write(0, 8);
  end;

  procedure WriteResidual(const AResidual: TArray<Integer>; AOrder, ABlockSize: Integer);
  var
    LPartitions, LPartitionSamples, LPartition, LFrom, LCount, LParam, LMaxBits,
    LIndexRes, LParamBits, LEscape: Integer;
    LSum: Int64;
    LUnsigned: Cardinal;
  begin
    LPartitions := 1 shl AOptions.PartitionOrder;
    LPartitionSamples := ABlockSize shr AOptions.PartitionOrder;
    if AOptions.Rice2 then
    begin
      LParamBits := 5;
      LEscape := 31;
      LOut.Write(1, 2);
    end
    else
    begin
      LParamBits := 4;
      LEscape := 15;
      LOut.Write(0, 2);
    end;
    LOut.Write(Cardinal(AOptions.PartitionOrder), 4);
    LFrom := 0;
    for LPartition := 0 to LPartitions - 1 do
    begin
      if LPartition = 0 then
        LCount := LPartitionSamples - AOrder
      else
        LCount := LPartitionSamples;
      if AOptions.UseEscape then
      begin
        LMaxBits := 1;
        for LIndexRes := LFrom to LFrom + LCount - 1 do
          while (AResidual[LIndexRes] >= (1 shl (LMaxBits - 1))) or
                (AResidual[LIndexRes] < -(1 shl (LMaxBits - 1))) do
            Inc(LMaxBits);
        LOut.Write(Cardinal(LEscape), LParamBits);
        LOut.Write(Cardinal(LMaxBits), 5);
        for LIndexRes := LFrom to LFrom + LCount - 1 do
          LOut.WriteSigned(AResidual[LIndexRes], LMaxBits);
      end
      else
      begin
        LSum := 0;
        for LIndexRes := LFrom to LFrom + LCount - 1 do
        begin
          if AResidual[LIndexRes] < 0 then
            LUnsigned := ((Cardinal(not AResidual[LIndexRes])) shl 1) or 1
          else
            LUnsigned := Cardinal(AResidual[LIndexRes]) shl 1;
          Inc(LSum, LUnsigned);
        end;
        LParam := 0;
        if LCount > 0 then
          while ((Int64(LCount) shl (LParam + 1)) <= LSum) and (LParam < LEscape - 1) do
            Inc(LParam);
        LOut.Write(Cardinal(LParam), LParamBits);
        for LIndexRes := LFrom to LFrom + LCount - 1 do
        begin
          if AResidual[LIndexRes] < 0 then
            LUnsigned := ((Cardinal(not AResidual[LIndexRes])) shl 1) or 1
          else
            LUnsigned := Cardinal(AResidual[LIndexRes]) shl 1;
          LOut.WriteUnary(LUnsigned shr LParam);
          if LParam > 0 then
            LOut.Write(LUnsigned and ((Cardinal(1) shl LParam) - 1), LParam);
        end;
      end;
      Inc(LFrom, LCount);
    end;
  end;

  procedure WriteSubframe(const AData: TArray<Integer>; AOffset, ABlockSize, ABits: Integer);
  var
    LValues: TArray<Integer>;
    LWasted, LOrder, LI, LJ, LShift, LPrecision: Integer;
    LResidual: TArray<Integer>;
    LPredicted: Int64;
    LCoefficients: array[0..31] of Integer;
    LTypeByte: Integer;
  begin
    // A block shorter than the order still writes all the warm-up samples:
    // those past the block are zeros (they used to be read past the array)
    SetLength(LValues, Max(ABlockSize, 32));
    LWasted := AOptions.WastedBits;
    for LI := 0 to ABlockSize - 1 do
      LValues[LI] := AData[AOffset + LI] div (1 shl LWasted);
    ABits := ABits - LWasted;

    case AOptions.Subframe of
      TSoundTestFlacSubframe.Constant:
        LTypeByte := 0;
      TSoundTestFlacSubframe.Verbatim:
        LTypeByte := 1;
      TSoundTestFlacSubframe.Fixed:
        LTypeByte := 8 + AOptions.Order;
    else
      LTypeByte := 32 + AOptions.Order - 1;
    end;
    LOut.Write(0, 1);
    LOut.Write(Cardinal(LTypeByte), 6);
    if LWasted > 0 then
    begin
      LOut.Write(1, 1);
      LOut.WriteUnary(Cardinal(LWasted - 1));
    end
    else
      LOut.Write(0, 1);

    case AOptions.Subframe of
      TSoundTestFlacSubframe.Constant:
        LOut.WriteSigned(LValues[0], ABits);
      TSoundTestFlacSubframe.Verbatim:
        for LI := 0 to ABlockSize - 1 do
          LOut.WriteSigned(LValues[LI], ABits);
      TSoundTestFlacSubframe.Fixed:
        begin
          LOrder := AOptions.Order;
          for LI := 0 to LOrder - 1 do
            LOut.WriteSigned(LValues[LI], ABits);
          SetLength(LResidual, ABlockSize);
          for LI := LOrder to ABlockSize - 1 do
          begin
            case LOrder of
              0: LPredicted := 0;
              1: LPredicted := LValues[LI - 1];
              2: LPredicted := 2 * Int64(LValues[LI - 1]) - LValues[LI - 2];
              3: LPredicted := 3 * Int64(LValues[LI - 1]) - 3 * Int64(LValues[LI - 2]) + LValues[LI - 3];
            else
              LPredicted := 4 * Int64(LValues[LI - 1]) - 6 * Int64(LValues[LI - 2]) +
                4 * Int64(LValues[LI - 3]) - LValues[LI - 4];
            end;
            LResidual[LI - LOrder] := Integer(Int64(LValues[LI]) - LPredicted);
          end;
          WriteResidual(LResidual, LOrder, ABlockSize);
        end;
    else
      begin
        LOrder := AOptions.Order;
        for LI := 0 to LOrder - 1 do
          LOut.WriteSigned(LValues[LI], ABits);
        // Any coefficients will do: the residual makes up for them
        LPrecision := 12;
        LShift := 9;
        LOut.Write(Cardinal(LPrecision - 1), 4);
        LOut.Write(Cardinal(LShift), 5);
        for LI := 0 to LOrder - 1 do
        begin
          LCoefficients[LI] := (LOrder - LI) * (1500 div LOrder) - 700;
          if (LI and 1) <> 0 then
            LCoefficients[LI] := -LCoefficients[LI] div 3;
          LOut.WriteSigned(LCoefficients[LI], LPrecision);
        end;
        SetLength(LResidual, ABlockSize);
        for LI := LOrder to ABlockSize - 1 do
        begin
          LPredicted := 0;
          for LJ := 0 to LOrder - 1 do
            LPredicted := LPredicted + Int64(LCoefficients[LJ]) * LValues[LI - LJ - 1];
          LPredicted := LPredicted div (Int64(1) shl LShift) - Ord((LPredicted < 0) and
            ((LPredicted mod (Int64(1) shl LShift)) <> 0));
          LResidual[LI - LOrder] := Integer(Int64(LValues[LI]) - LPredicted);
        end;
        WriteResidual(LResidual, LOrder, ABlockSize);
      end;
    end;
  end;

  procedure WriteUtf8(AValue: Cardinal);
  var
    LByteIndex: Integer;
  begin
    if AValue < $80 then
      LOut.Write(AValue, 8)
    else if AValue < $800 then
    begin
      LOut.Write($C0 or (AValue shr 6), 8);
      LOut.Write($80 or (AValue and $3F), 8);
    end
    else if AValue < $10000 then
    begin
      LOut.Write($E0 or (AValue shr 12), 8);
      for LByteIndex := 1 downto 0 do
        LOut.Write($80 or ((AValue shr (6 * LByteIndex)) and $3F), 8);
    end
    else
    begin
      LOut.Write($F0 or (AValue shr 18), 8);
      for LByteIndex := 2 downto 0 do
        LOut.Write($80 or ((AValue shr (6 * LByteIndex)) and $3F), 8);
    end;
  end;

  procedure WriteFrameHeader(AFrameNumber, ABlockSize: Integer);
  var
    LBlockCode, LRateCode, LSizeCode, LChannelCode: Integer;
  begin
    LOut.Write($FFF8, 16);
    case ABlockSize of
      192: LBlockCode := 1;
      576: LBlockCode := 2;
      1152: LBlockCode := 3;
      2304: LBlockCode := 4;
      4608: LBlockCode := 5;
      256: LBlockCode := 8;
      512: LBlockCode := 9;
      1024: LBlockCode := 10;
      2048: LBlockCode := 11;
      4096: LBlockCode := 12;
      8192: LBlockCode := 13;
      16384: LBlockCode := 14;
      32768: LBlockCode := 15;
    else
      if ABlockSize <= 256 then
        LBlockCode := 6
      else
        LBlockCode := 7;
    end;
    if AOptions.HeaderFromStreamInfo then
      LRateCode := 0
    else
      case AOptions.SampleRate of
        88200: LRateCode := 1;
        44100: LRateCode := 9;
        48000: LRateCode := 10;
        22050: LRateCode := 6;
        8000: LRateCode := 4;
      else
        if (AOptions.SampleRate mod 1000 = 0) and (AOptions.SampleRate div 1000 < 256) then
          LRateCode := 12
        else
          LRateCode := 13;
      end;
    LOut.Write(Cardinal(LBlockCode), 4);
    LOut.Write(Cardinal(LRateCode), 4);
    if AOptions.Assignment > 0 then
      LChannelCode := 8 + AOptions.Assignment - 1
    else
      LChannelCode := AOptions.Channels - 1;
    LOut.Write(Cardinal(LChannelCode), 4);
    if AOptions.HeaderFromStreamInfo then
      LSizeCode := 0
    else
      case AOptions.BitsPerSample of
        8: LSizeCode := 1;
        12: LSizeCode := 2;
        16: LSizeCode := 4;
        20: LSizeCode := 5;
      else
        LSizeCode := 6;
      end;
    LOut.Write(Cardinal(LSizeCode), 3);
    LOut.Write(0, 1);
    WriteUtf8(Cardinal(AFrameNumber));
    if LBlockCode = 6 then
      LOut.Write(Cardinal(ABlockSize - 1), 8)
    else if LBlockCode = 7 then
      LOut.Write(Cardinal(ABlockSize - 1), 16);
    if LRateCode = 12 then
      LOut.Write(Cardinal(AOptions.SampleRate div 1000), 8)
    else if LRateCode = 13 then
      LOut.Write(Cardinal(AOptions.SampleRate), 16);
  end;

begin
  InitTables;
  // A local record only has its managed fields cleared
  LOut.Bytes := nil;
  LOut.Count := 0;
  LOut.Bits := 0;
  LSamples := Length(ASamples[0]);
  LOut.Write(Ord('f'), 8);
  LOut.Write(Ord('L'), 8);
  LOut.Write(Ord('a'), 8);
  LOut.Write(Ord('C'), 8);
  WriteStreamInfo(not AOptions.ExtraMetadata);
  if AOptions.ExtraMetadata then
  begin
    // A block of padding and a Vorbis comment (the last one)
    LOut.Write(0, 1);
    LOut.Write(1, 7);
    LOut.Write(20, 24);
    for LIndex := 1 to 20 do
      LOut.Write(0, 8);
    LOut.Write(1, 1);
    LOut.Write(4, 7);
    LOut.Write(8, 24);
    // vendor length (little endian), vendor, comment count
    LOut.Write(0, 8); LOut.Write(0, 8); LOut.Write(0, 8); LOut.Write(0, 8);
    LOut.Write(0, 8); LOut.Write(0, 8); LOut.Write(0, 8); LOut.Write(0, 8);
  end;

  // Side channels
  SetLength(LCoded, AOptions.Channels);
  for LChannel := 0 to AOptions.Channels - 1 do
    LCoded[LChannel] := ASamples[LChannel];
  if (AOptions.Assignment > 0) and (AOptions.Channels = 2) then
  begin
    SetLength(LCoded[0], LSamples);
    SetLength(LCoded[1], LSamples);
    for LIndex := 0 to LSamples - 1 do
      case AOptions.Assignment of
        1:
          begin
            LCoded[0][LIndex] := ASamples[0][LIndex];
            LCoded[1][LIndex] := ASamples[0][LIndex] - ASamples[1][LIndex];
          end;
        2:
          begin
            LCoded[0][LIndex] := ASamples[0][LIndex] - ASamples[1][LIndex];
            LCoded[1][LIndex] := ASamples[1][LIndex];
          end;
      else
        begin
          LCoded[0][LIndex] := (ASamples[0][LIndex] + ASamples[1][LIndex]) div 2 -
            Ord(((ASamples[0][LIndex] + ASamples[1][LIndex]) < 0) and
            (((ASamples[0][LIndex] + ASamples[1][LIndex]) and 1) <> 0));
          LCoded[1][LIndex] := ASamples[0][LIndex] - ASamples[1][LIndex];
        end;
      end;
  end;

  LFrames := (LSamples + AOptions.BlockSize - 1) div AOptions.BlockSize;
  for LFrame := 0 to LFrames - 1 do
  begin
    LStart := LFrame * AOptions.BlockSize;
    LBlock := AOptions.BlockSize;
    if LStart + LBlock > LSamples then
      LBlock := LSamples - LStart;

    // Not before the last frame: libFLAC drops it there for reasons not emulated
    if (AOptions.Garbage > 0) and (LFrame < LFrames - 1) then
      for LIndex := 1 to AOptions.Garbage do
        LOut.Write(Cardinal((LIndex * 37) and $7F), 8);

    LHeaderStart := Length(LOut.Bytes);
    WriteFrameHeader(LFrame, LBlock);
    LHeaderEnd := Length(LOut.Bytes);
    LCrc8 := 0;
    for LCrcIndex := LHeaderStart to LHeaderEnd - 1 do
      LCrc8 := Crc8Table[LCrc8 xor LOut.Bytes[LCrcIndex]];
    if LFrame = AOptions.BadHeaderFrame then
      LCrc8 := LCrc8 xor $5A;
    LOut.Write(LCrc8, 8);

    for LChannel := 0 to AOptions.Channels - 1 do
    begin
      LSubframeBits := AOptions.BitsPerSample;
      case AOptions.Assignment of
        1: if LChannel = 1 then Inc(LSubframeBits);
        2: if LChannel = 0 then Inc(LSubframeBits);
        3: if LChannel = 1 then Inc(LSubframeBits);
      end;
      WriteSubframe(LCoded[LChannel], LStart, LBlock, LSubframeBits);
    end;
    LOut.Align;

    LCrc16 := 0;
    for LCrcIndex := LHeaderStart to High(LOut.Bytes) do
      LCrc16 := Word((LCrc16 shl 8) xor Crc16Table[(LCrc16 shr 8) xor LOut.Bytes[LCrcIndex]]);
    if LFrame = AOptions.BadCrcFrame then
      LCrc16 := LCrc16 xor $A5A5;
    LOut.Write(LCrc16, 16);
  end;
  LTotal := Length(LOut.Bytes);
  SetLength(LBytes, LTotal);
  Move(LOut.Bytes[0], LBytes[0], LTotal);
  Result := LBytes;
end;

end.
