{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - FLAC                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The behaviour follows libFLAC 1.3 as libsndfile drives it.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.Flac;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples;

type
  /// <summary>What the STREAMINFO block says</summary>
  TFlacStreamInfo = record
    MinBlockSize, MaxBlockSize: Integer;
    SampleRate: Integer;
    Channels: Integer;
    BitsPerSample: Integer;
    TotalSamples: Int64;
  end;

  /// <summary>
  ///   Decoder of FLAC streams: the metadata blocks, then the frames. Damaged
  ///   frames are dealt with like libFLAC does: the decoder looks for the next
  ///   frame, and a frame whose CRC does not match comes out as silence
  /// </summary>
  TFlacDecoder = class
  private
    type
      TFrameResult = (Frame, Resync, EndOfData);
      THeader = record
        BlockSize: Integer;
        SampleRate: Integer;
        Channels: Integer;
        Assignment: Integer;
        BitsPerSample: Integer;
        SampleNumber: Int64;
      end;
  private
    FData: TBytes;
    FPosition: Integer;
    FBit: Integer;
    FCached: Boolean;
    FLookahead: Byte;
    FWarmup: array[0..1] of Byte;
    FInfo: TFlacStreamInfo;
    FHasInfo: Boolean;
    FFixedBlockSize: Integer;
    FNextFixedBlockSize: Integer;
    FSamplesDecoded: Int64;
    FHeader: THeader;
    FPendingError: Integer;
    FEvents: TArray<TSoundErrorEvent>;
    FOutput: array of TArray<Integer>;
    FResidual: TArray<Integer>;
    function ReadBits(ACount: Integer): Cardinal;
    function ReadSigned(ACount: Integer): Integer;
    function ReadUnary: Cardinal;
    procedure AlignToByte;
    function Aligned: Boolean;
    function ReadMetadata: Boolean;
    function ReadFrameHeader(out AResult: TFrameResult): Boolean;
    function ReadFrame(out AResult: TFrameResult): Boolean;
    function ReadSubframe(AChannel, ABitsPerSample: Integer; out AResult: TFrameResult): Boolean;
    function ReadResidual(APredictorOrder, APartitionOrder: Integer; AExtended: Boolean): Boolean;
    function FindSync: Boolean;
  public
    constructor Create(const AData: TBytes);
    /// <summary>
    ///   Decodes the stream. AData receives the samples interleaved and
    ///   justified to the top of 32 bits, ADecodedFrames how many frames the
    ///   frames of the stream made
    /// </summary>
    function Decode(out AInfo: TFlacStreamInfo; out AData: TArray<Integer>;
      out ADecodedFrames: Int64; out AEvents: TArray<TSoundErrorEvent>): Integer;
  end;

implementation

type
  EFlacEndOfData = class(Exception);

var
  Crc8Table: array[0..255] of Byte;
  Crc16Table: array[0..255] of Word;

procedure InitCrcTables;
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

function Crc8Of(const ABytes: array of Byte; ACount: Integer): Byte;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to ACount - 1 do
    Result := Crc8Table[Result xor ABytes[LIndex]];
end;

/// <summary>Arithmetic shift right by one of a 32 bit number</summary>
function ShiftRightOne(AValue: Integer): Integer;
begin
  Result := (AValue - (AValue and 1)) div 2;
end;

/// <summary>Arithmetic shift right of a 64 bit number (shr does not keep the sign)</summary>
function ShiftRight64(AValue: Int64; ABy: Integer): Int64;
begin
  if ABy = 0 then
    Exit(AValue);
  Result := (AValue - (AValue and ((Int64(1) shl ABy) - 1))) div (Int64(1) shl ABy);
end;

{ TFlacDecoder }

constructor TFlacDecoder.Create(const AData: TBytes);
begin
  inherited Create;
  FData := AData;
end;

function TFlacDecoder.Aligned: Boolean;
begin
  Result := FBit = 0;
end;

procedure TFlacDecoder.AlignToByte;
begin
  if FBit <> 0 then
  begin
    FBit := 0;
    Inc(FPosition);
  end;
end;

function TFlacDecoder.ReadBits(ACount: Integer): Cardinal;
var
  LTake, LAvailable: Integer;
begin
  Result := 0;
  while ACount > 0 do
  begin
    if FPosition >= Length(FData) then
      raise EFlacEndOfData.Create('end of data');
    LAvailable := 8 - FBit;
    if ACount < LAvailable then
      LTake := ACount
    else
      LTake := LAvailable;
    Result := (Result shl LTake) or
      ((Cardinal(FData[FPosition]) shr (LAvailable - LTake)) and ((1 shl LTake) - 1));
    Dec(ACount, LTake);
    Inc(FBit, LTake);
    if FBit = 8 then
    begin
      FBit := 0;
      Inc(FPosition);
    end;
  end;
end;

function TFlacDecoder.ReadSigned(ACount: Integer): Integer;
var
  LValue: Cardinal;
begin
  if ACount = 0 then
    Exit(0);
  LValue := ReadBits(ACount);
  if ACount < 32 then
  begin
    // Sign extension of a number of ACount bits
    if (LValue and (Cardinal(1) shl (ACount - 1))) <> 0 then
      LValue := LValue or (Cardinal($FFFFFFFF) shl ACount);
  end;
  Result := Integer(LValue);
end;

function TFlacDecoder.ReadUnary: Cardinal;
var
  LByte, LMask: Integer;
begin
  Result := 0;
  while True do
  begin
    if FPosition >= Length(FData) then
      raise EFlacEndOfData.Create('end of data');
    LByte := FData[FPosition] and ($FF shr FBit);
    if LByte = 0 then
    begin
      // the rest of this byte is zeros
      Inc(Result, 8 - FBit);
      FBit := 0;
      Inc(FPosition);
      Continue;
    end;
    LMask := $80 shr FBit;
    while (LByte and LMask) = 0 do
    begin
      LMask := LMask shr 1;
      Inc(Result);
      Inc(FBit);
    end;
    // consume the 1 that ends it
    Inc(FBit);
    if FBit = 8 then
    begin
      FBit := 0;
      Inc(FPosition);
    end;
    Exit;
  end;
end;

function TFlacDecoder.ReadMetadata: Boolean;
var
  LIsLast: Boolean;
  LType, LLength, LStart: Cardinal;
  LValue: Cardinal;
  LHigh, LLow: Cardinal;
begin
  // Result is whether the walk can go on to the next block
  LIsLast := ReadBits(1) <> 0;
  LType := ReadBits(7);
  LLength := ReadBits(24);
  LStart := FPosition;
  if LType = 0 then
  begin
    FInfo.MinBlockSize := Integer(ReadBits(16));
    FInfo.MaxBlockSize := Integer(ReadBits(16));
    ReadBits(24);                       // min frame size
    ReadBits(24);                       // max frame size
    FInfo.SampleRate := Integer(ReadBits(20));
    FInfo.Channels := Integer(ReadBits(3)) + 1;
    FInfo.BitsPerSample := Integer(ReadBits(5)) + 1;
    LHigh := ReadBits(4);
    LLow := ReadBits(32);
    FInfo.TotalSamples := (Int64(LHigh) shl 32) or LLow;
    // The MD5 sum
    for LValue := 1 to 16 do
      ReadBits(8);
    FHasInfo := True;
    if LLength < 34 then
      Exit(False);
  end;
  // The rest of the block, and every block of another kind
  if Int64(LStart) + LLength > Length(FData) then
  begin
    FPosition := Length(FData);
    raise EFlacEndOfData.Create('end of data');
  end;
  FPosition := Integer(LStart + LLength);
  Result := not LIsLast;
end;

function TFlacDecoder.FindSync: Boolean;
var
  LByte: Cardinal;
  LFirst: Boolean;
begin
  Result := False;
  LFirst := True;
  // The total is known: do not look for more once it has all been decoded
  if (FInfo.TotalSamples > 0) and (FSamplesDecoded >= FInfo.TotalSamples) then
    Exit;
  AlignToByte;
  while True do
  begin
    if FCached then
    begin
      LByte := FLookahead;
      FCached := False;
    end
    else
      LByte := ReadBits(8);
    if LByte = $FF then
    begin
      FWarmup[0] := Byte(LByte);
      LByte := ReadBits(8);
      if LByte = $FF then
      begin
        // The second may be the start of the sync code
        FLookahead := Byte(LByte);
        FCached := True;
      end
      else if (LByte shr 1) = $7C then
      begin
        FWarmup[1] := Byte(LByte);
        Exit(True);
      end;
    end;
    // Not at a frame: libFLAC reports the first byte it has to skip
    if LFirst then
    begin
      FPendingError := 157;
      LFirst := False;
    end;
  end;
end;

function TFlacDecoder.ReadFrameHeader(out AResult: TFrameResult): Boolean;
var
  LRaw: array[0..15] of Byte;
  LRawLength: Integer;
  LUnparseable: Boolean;
  LBlockHint, LRateHint, LValue, LIndex, LByte, LExtra: Integer;
  LSampleNumber: UInt64;
  LUtf: Cardinal;
  LCrc: Byte;
  LVariable: Boolean;

  function ReadUtf8(out AValue: UInt64; AMaxExtra: Integer): Boolean;
  var
    LFirst, LNext: Integer;
    LCount, LStep: Integer;
    LResult: UInt64;
  begin
    // False when the sequence is not UTF-8; the bytes read go to the raw header
    LFirst := Integer(ReadBits(8));
    LRaw[LRawLength] := Byte(LFirst);
    Inc(LRawLength);
    if (LFirst and $80) = 0 then
    begin
      LResult := LFirst;
      LCount := 0;
    end
    else if ((LFirst and $C0) <> 0) and ((LFirst and $20) = 0) then
    begin
      LResult := LFirst and $1F;
      LCount := 1;
    end
    else if ((LFirst and $E0) <> 0) and ((LFirst and $10) = 0) then
    begin
      LResult := LFirst and $0F;
      LCount := 2;
    end
    else if ((LFirst and $F0) <> 0) and ((LFirst and $08) = 0) then
    begin
      LResult := LFirst and $07;
      LCount := 3;
    end
    else if ((LFirst and $F8) <> 0) and ((LFirst and $04) = 0) then
    begin
      LResult := LFirst and $03;
      LCount := 4;
    end
    else if ((LFirst and $FC) <> 0) and ((LFirst and $02) = 0) then
    begin
      LResult := LFirst and $01;
      LCount := 5;
    end
    else if (AMaxExtra = 6) and ((LFirst and $FE) <> 0) and ((LFirst and $01) = 0) then
    begin
      LResult := 0;
      LCount := 6;
    end
    else
      Exit(False);
    for LStep := 1 to LCount do
    begin
      LNext := Integer(ReadBits(8));
      LRaw[LRawLength] := Byte(LNext);
      Inc(LRawLength);
      if ((LNext and $80) = 0) or ((LNext and $40) <> 0) then
        Exit(False);
      LResult := (LResult shl 6) or UInt64(LNext and $3F);
    end;
    AValue := LResult;
    Result := True;
  end;

begin
  Result := True;
  AResult := TFrameResult.Frame;
  LRaw[0] := FWarmup[0];
  LRaw[1] := FWarmup[1];
  LRawLength := 2;
  LUnparseable := (LRaw[1] and $02) <> 0;
  LBlockHint := 0;
  LRateHint := 0;

  for LIndex := 0 to 1 do
  begin
    LByte := Integer(ReadBits(8));
    if LByte = $FF then
    begin
      // A sync code cannot be inside a header: the first sync was wrong
      FLookahead := Byte(LByte);
      FCached := True;
      FPendingError := 154;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    LRaw[LRawLength] := Byte(LByte);
    Inc(LRawLength);
  end;

  LValue := LRaw[2] shr 4;
  case LValue of
    0: LUnparseable := True;
    1: FHeader.BlockSize := 192;
    2..5: FHeader.BlockSize := 576 shl (LValue - 2);
    6, 7: LBlockHint := LValue;
  else
    FHeader.BlockSize := 256 shl (LValue - 8);
  end;

  LValue := LRaw[2] and $0F;
  case LValue of
    0:
      if FHasInfo then
        FHeader.SampleRate := FInfo.SampleRate
      else
        LUnparseable := True;
    1: FHeader.SampleRate := 88200;
    2: FHeader.SampleRate := 176400;
    3: FHeader.SampleRate := 192000;
    4: FHeader.SampleRate := 8000;
    5: FHeader.SampleRate := 16000;
    6: FHeader.SampleRate := 22050;
    7: FHeader.SampleRate := 24000;
    8: FHeader.SampleRate := 32000;
    9: FHeader.SampleRate := 44100;
    10: FHeader.SampleRate := 48000;
    11: FHeader.SampleRate := 96000;
    12, 13, 14: LRateHint := LValue;
  else
    begin
      FPendingError := 154;
      AResult := TFrameResult.Resync;
      Exit;
    end;
  end;

  LValue := LRaw[3] shr 4;
  if (LValue and 8) <> 0 then
  begin
    FHeader.Channels := 2;
    case LValue and 7 of
      0, 1, 2: FHeader.Assignment := (LValue and 7) + 1;
    else
      LUnparseable := True;
    end;
  end
  else
  begin
    FHeader.Channels := LValue + 1;
    FHeader.Assignment := 0;
  end;

  case (LRaw[3] and $0E) shr 1 of
    0:
      if FHasInfo then
        FHeader.BitsPerSample := FInfo.BitsPerSample
      else
        LUnparseable := True;
    1: FHeader.BitsPerSample := 8;
    2: FHeader.BitsPerSample := 12;
    4: FHeader.BitsPerSample := 16;
    5: FHeader.BitsPerSample := 20;
    6: FHeader.BitsPerSample := 24;
  else
    LUnparseable := True;
  end;

  if (LRaw[3] and $01) <> 0 then
    LUnparseable := True;

  LVariable := ((LRaw[1] and $01) <> 0) or
    (FHasInfo and (FInfo.MinBlockSize <> FInfo.MaxBlockSize));
  if LVariable then
  begin
    if not ReadUtf8(LSampleNumber, 6) then
    begin
      FLookahead := LRaw[LRawLength - 1];
      FCached := True;
      FPendingError := 154;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    FHeader.SampleNumber := Int64(LSampleNumber);
  end
  else
  begin
    if not ReadUtf8(LSampleNumber, 5) then
    begin
      FLookahead := LRaw[LRawLength - 1];
      FCached := True;
      FPendingError := 154;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    LUtf := Cardinal(LSampleNumber);
  end;

  if LBlockHint <> 0 then
  begin
    LValue := Integer(ReadBits(8));
    LRaw[LRawLength] := Byte(LValue);
    Inc(LRawLength);
    if LBlockHint = 7 then
    begin
      LExtra := Integer(ReadBits(8));
      LRaw[LRawLength] := Byte(LExtra);
      Inc(LRawLength);
      LValue := (LValue shl 8) or LExtra;
    end;
    FHeader.BlockSize := LValue + 1;
  end;

  if LRateHint <> 0 then
  begin
    LValue := Integer(ReadBits(8));
    LRaw[LRawLength] := Byte(LValue);
    Inc(LRawLength);
    if LRateHint <> 12 then
    begin
      LExtra := Integer(ReadBits(8));
      LRaw[LRawLength] := Byte(LExtra);
      Inc(LRawLength);
      LValue := (LValue shl 8) or LExtra;
    end;
    if LRateHint = 12 then
      FHeader.SampleRate := LValue * 1000
    else if LRateHint = 13 then
      FHeader.SampleRate := LValue
    else
      FHeader.SampleRate := LValue * 10;
  end;

  LCrc := Byte(ReadBits(8));
  if Crc8Of(LRaw, LRawLength) <> LCrc then
  begin
    FPendingError := 154;
    AResult := TFrameResult.Resync;
    Exit;
  end;

  // The sample number from the frame number, if that is what the header has
  FNextFixedBlockSize := 0;
  if not LVariable then
  begin
    if FFixedBlockSize <> 0 then
      FHeader.SampleNumber := Int64(FFixedBlockSize) * LUtf
    else if FHasInfo then
    begin
      if FInfo.MinBlockSize = FInfo.MaxBlockSize then
      begin
        FHeader.SampleNumber := Int64(FInfo.MinBlockSize) * LUtf;
        FNextFixedBlockSize := FInfo.MaxBlockSize;
      end
      else
        LUnparseable := True;
    end
    else if LUtf = 0 then
    begin
      FHeader.SampleNumber := 0;
      FNextFixedBlockSize := FHeader.BlockSize;
    end
    else
      FHeader.SampleNumber := Int64(FHeader.BlockSize) * LUtf;
  end;

  if LUnparseable then
  begin
    FPendingError := 159;
    AResult := TFrameResult.Resync;
  end;
end;

function TFlacDecoder.ReadResidual(APredictorOrder, APartitionOrder: Integer;
  AExtended: Boolean): Boolean;
var
  LPartitions, LPartitionSamples, LParameterBits, LEscape, LPartition, LSample,
  LCount, LIndex, LRawBits: Integer;
  LParameter: Cardinal;
  LQuotient, LValue: Cardinal;
begin
  Result := True;
  LPartitions := 1 shl APartitionOrder;
  LPartitionSamples := FHeader.BlockSize shr APartitionOrder;
  if AExtended then
  begin
    LParameterBits := 5;
    LEscape := 31;
  end
  else
  begin
    LParameterBits := 4;
    LEscape := 15;
  end;

  LSample := 0;
  for LPartition := 0 to LPartitions - 1 do
  begin
    LParameter := ReadBits(LParameterBits);
    if LPartition = 0 then
      LCount := LPartitionSamples - APredictorOrder
    else
      LCount := LPartitionSamples;
    if Integer(LParameter) < LEscape then
    begin
      for LIndex := 1 to LCount do
      begin
        LQuotient := ReadUnary;
        LValue := (LQuotient shl LParameter) or ReadBits(LParameter);
        // zigzag: the low bit is the sign
        FResidual[LSample] := Integer(LValue shr 1) xor -Integer(LValue and 1);
        Inc(LSample);
      end;
    end
    else
    begin
      LRawBits := Integer(ReadBits(5));
      for LIndex := 1 to LCount do
      begin
        FResidual[LSample] := ReadSigned(LRawBits);
        Inc(LSample);
      end;
    end;
  end;
end;

function TFlacDecoder.ReadSubframe(AChannel, ABitsPerSample: Integer;
  out AResult: TFrameResult): Boolean;
var
  LHeaderByte, LWasted, LOrder, LIndex, LPrecision, LShift, LPartitionOrder,
  LMethod, LType: Integer;
  LWarmup: array[0..31] of Integer;
  LCoefficients: array[0..31] of Integer;
  LOutput: TArray<Integer>;
  LSum: Int64;
  LJ: Integer;
  LConstant: Integer;
  LBlock: Integer;
begin
  Result := True;
  AResult := TFrameResult.Frame;
  LBlock := FHeader.BlockSize;
  LOutput := FOutput[AChannel];
  LHeaderByte := Integer(ReadBits(8));
  LWasted := 0;
  if (LHeaderByte and 1) <> 0 then
  begin
    LWasted := Integer(ReadUnary) + 1;
    if LWasted >= ABitsPerSample then
      Exit(False);
    Dec(ABitsPerSample, LWasted);
  end;
  LType := LHeaderByte and $FE;

  if (LType and $80) <> 0 then
  begin
    FPendingError := 157;
    AResult := TFrameResult.Resync;
    Exit;
  end
  else if LType = 0 then
  begin
    LConstant := ReadSigned(ABitsPerSample);
    for LIndex := 0 to LBlock - 1 do
      LOutput[LIndex] := LConstant;
  end
  else if LType = 2 then
  begin
    for LIndex := 0 to LBlock - 1 do
      LOutput[LIndex] := ReadSigned(ABitsPerSample);
  end
  else if LType < 16 then
  begin
    FPendingError := 159;
    AResult := TFrameResult.Resync;
    Exit;
  end
  else if LType <= 24 then
  begin
    LOrder := (LType shr 1) and 7;
    for LIndex := 0 to LOrder - 1 do
      LWarmup[LIndex] := ReadSigned(ABitsPerSample);
    LMethod := Integer(ReadBits(2));
    if LMethod > 1 then
    begin
      FPendingError := 159;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    LPartitionOrder := Integer(ReadBits(4));
    if (LBlock shr LPartitionOrder) < LOrder then
    begin
      FPendingError := 157;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    ReadResidual(LOrder, LPartitionOrder, LMethod = 1);
    for LIndex := 0 to LOrder - 1 do
      LOutput[LIndex] := LWarmup[LIndex];
    // fixed predictors, 32 bit arithmetic that wraps
    for LIndex := LOrder to LBlock - 1 do
      case LOrder of
        0: LOutput[LIndex] := FResidual[LIndex - LOrder];
        1: LOutput[LIndex] := Integer(Cardinal(FResidual[LIndex - LOrder]) + Cardinal(LOutput[LIndex - 1]));
        2: LOutput[LIndex] := Integer(Cardinal(FResidual[LIndex - LOrder]) +
             Cardinal(2) * Cardinal(LOutput[LIndex - 1]) - Cardinal(LOutput[LIndex - 2]));
        3: LOutput[LIndex] := Integer(Cardinal(FResidual[LIndex - LOrder]) +
             Cardinal(3) * Cardinal(LOutput[LIndex - 1]) - Cardinal(3) * Cardinal(LOutput[LIndex - 2]) +
             Cardinal(LOutput[LIndex - 3]));
      else
        LOutput[LIndex] := Integer(Cardinal(FResidual[LIndex - LOrder]) +
          Cardinal(4) * Cardinal(LOutput[LIndex - 1]) - Cardinal(6) * Cardinal(LOutput[LIndex - 2]) +
          Cardinal(4) * Cardinal(LOutput[LIndex - 3]) - Cardinal(LOutput[LIndex - 4]));
      end;
  end
  else if LType < 64 then
  begin
    FPendingError := 159;
    AResult := TFrameResult.Resync;
    Exit;
  end
  else
  begin
    LOrder := ((LType shr 1) and 31) + 1;
    for LIndex := 0 to LOrder - 1 do
      LWarmup[LIndex] := ReadSigned(ABitsPerSample);
    LPrecision := Integer(ReadBits(4));
    if LPrecision = 15 then
    begin
      FPendingError := 157;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    Inc(LPrecision);
    LShift := ReadSigned(5);
    if LShift < 0 then
    begin
      FPendingError := 157;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    for LIndex := 0 to LOrder - 1 do
      LCoefficients[LIndex] := ReadSigned(LPrecision);
    LMethod := Integer(ReadBits(2));
    if LMethod > 1 then
    begin
      FPendingError := 159;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    LPartitionOrder := Integer(ReadBits(4));
    if (LBlock shr LPartitionOrder) < LOrder then
    begin
      FPendingError := 157;
      AResult := TFrameResult.Resync;
      Exit;
    end;
    ReadResidual(LOrder, LPartitionOrder, LMethod = 1);
    for LIndex := 0 to LOrder - 1 do
      LOutput[LIndex] := LWarmup[LIndex];
    for LIndex := LOrder to LBlock - 1 do
    begin
      LSum := 0;
      for LJ := 0 to LOrder - 1 do
        LSum := LSum + Int64(LCoefficients[LJ]) * LOutput[LIndex - LJ - 1];
      LOutput[LIndex] := Integer(FResidual[LIndex - LOrder] + ShiftRight64(LSum, LShift));
    end;
  end;

  if LWasted > 0 then
    for LIndex := 0 to LBlock - 1 do
      LOutput[LIndex] := Integer(Cardinal(LOutput[LIndex]) shl LWasted);
end;

function TFlacDecoder.ReadFrame(out AResult: TFrameResult): Boolean;
var
  LStart, LChannel, LBitsPerSample, LIndex, LMid, LSide, LCrcCalc: Integer;
  LCrc: Word;
  LExpected: Cardinal;
  LSubframeResult: TFrameResult;
begin
  Result := True;
  LStart := FPosition - 2;
  if not ReadFrameHeader(AResult) then
    Exit(False);
  if AResult <> TFrameResult.Frame then
    Exit;

  if Length(FOutput) < FHeader.Channels then
    SetLength(FOutput, FHeader.Channels);
  for LChannel := 0 to FHeader.Channels - 1 do
    if Length(FOutput[LChannel]) < FHeader.BlockSize then
      SetLength(FOutput[LChannel], FHeader.BlockSize);
  if Length(FResidual) < FHeader.BlockSize then
    SetLength(FResidual, FHeader.BlockSize);

  for LChannel := 0 to FHeader.Channels - 1 do
  begin
    // The side channels have one bit more
    LBitsPerSample := FHeader.BitsPerSample;
    case FHeader.Assignment of
      1: if LChannel = 1 then Inc(LBitsPerSample);
      2: if LChannel = 0 then Inc(LBitsPerSample);
      3: if LChannel = 1 then Inc(LBitsPerSample);
    end;
    if not ReadSubframe(LChannel, LBitsPerSample, LSubframeResult) then
      Exit(False);
    if LSubframeResult <> TFrameResult.Frame then
    begin
      AResult := LSubframeResult;
      Exit;
    end;
  end;

  // The zero bits that make it a whole number of bytes
  if not Aligned then
  begin
    LExpected := ReadBits(8 - FBit);
    if LExpected <> 0 then
    begin
      FPendingError := 157;
      AResult := TFrameResult.Resync;
      Exit;
    end;
  end;

  // CRC-16 of every byte of the frame before its own CRC
  LCrc := 0;
  for LCrcCalc := LStart to FPosition - 1 do
    LCrc := Word((LCrc shl 8) xor Crc16Table[(LCrc shr 8) xor FData[LCrcCalc]]);
  LExpected := ReadBits(16);

  if LCrc = LExpected then
  begin
    case FHeader.Assignment of
      1:
        for LIndex := 0 to FHeader.BlockSize - 1 do
          FOutput[1][LIndex] := FOutput[0][LIndex] - FOutput[1][LIndex];
      2:
        for LIndex := 0 to FHeader.BlockSize - 1 do
          FOutput[0][LIndex] := FOutput[0][LIndex] + FOutput[1][LIndex];
      3:
        for LIndex := 0 to FHeader.BlockSize - 1 do
        begin
          LMid := FOutput[0][LIndex];
          LSide := FOutput[1][LIndex];
          LMid := Integer(Cardinal(LMid) shl 1);
          LMid := LMid or (LSide and 1);
          FOutput[0][LIndex] := ShiftRightOne(LMid + LSide);
          FOutput[1][LIndex] := ShiftRightOne(LMid - LSide);
        end;
    end;
  end
  else
  begin
    // A bad frame comes out as silence
    FPendingError := 159;
    for LChannel := 0 to FHeader.Channels - 1 do
      FillChar(FOutput[LChannel][0], FHeader.BlockSize * SizeOf(Integer), 0);
  end;

  if FNextFixedBlockSize <> 0 then
    FFixedBlockSize := FNextFixedBlockSize;
  FSamplesDecoded := FHeader.SampleNumber + FHeader.BlockSize;
  AResult := TFrameResult.Frame;
end;

function TFlacDecoder.Decode(out AInfo: TFlacStreamInfo;
  out AData: TArray<Integer>; out ADecodedFrames: Int64;
  out AEvents: TArray<TSoundErrorEvent>): Integer;
var
  LResult: TFrameResult;
  LFrames: Int64;
  LCapacity, LChannel, LSample, LShift: Integer;
  LFrameSamples: Int64;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  AData := nil;
  ADecodedFrames := 0;
  AEvents := nil;
  FEvents := nil;
  FPendingError := 0;
  FPosition := 4;
  FBit := 0;
  FCached := False;
  FHasInfo := False;
  FFixedBlockSize := 0;
  FSamplesDecoded := 0;
  FillChar(FInfo, SizeOf(FInfo), 0);
  LCapacity := 0;
  LFrames := 0;

  try
    // The metadata blocks, up to the one that says it is the last
    while ReadMetadata do
      ;
  except
    on EFlacEndOfData do
      ;
  end;
  AInfo := FInfo;
  if not FHasInfo then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  if not (FInfo.BitsPerSample in [8, 16, 24]) then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  try
    while True do
    begin
      if not FindSync then
        Break;
      LResult := TFrameResult.Frame;
      if not ReadFrame(LResult) then
        Break;
      if LResult <> TFrameResult.Frame then
        Continue;
      // A frame with other channels than the stream has cannot be told apart
      if FHeader.Channels <> FInfo.Channels then
        Break;

      LFrameSamples := Int64(FHeader.BlockSize) * FHeader.Channels;
      if (LFrames + FHeader.BlockSize) * FHeader.Channels > LCapacity then
      begin
        LCapacity := Integer((LFrames + FHeader.BlockSize) * FHeader.Channels * 2);
        SetLength(AData, LCapacity);
      end;
      LShift := 32 - FHeader.BitsPerSample;
      for LSample := 0 to FHeader.BlockSize - 1 do
        for LChannel := 0 to FHeader.Channels - 1 do
          AData[(LFrames + LSample) * FHeader.Channels + LChannel] :=
            Integer(Cardinal(FOutput[LChannel][LSample]) shl LShift);
      // The errors met on the way to this frame are reported when it is read
      if FPendingError <> 0 then
      begin
        SetLength(FEvents, Length(FEvents) + 1);
        FEvents[High(FEvents)].Frame := LFrames;
        FEvents[High(FEvents)].Code := FPendingError;
        FPendingError := 0;
      end;
      Inc(LFrames, FHeader.BlockSize);
    end;
  except
    on EFlacEndOfData do
      ;
  end;

  // Whatever was found after the last frame is met when reading past it
  if FPendingError <> 0 then
  begin
    SetLength(FEvents, Length(FEvents) + 1);
    FEvents[High(FEvents)].Frame := LFrames;
    FEvents[High(FEvents)].Code := FPendingError;
  end;
  AEvents := FEvents;
  SetLength(AData, LFrames * FInfo.Channels);
  ADecodedFrames := LFrames;
  Result := SNDFILE_OK;
end;

initialization
  InitCrcTables;

end.
