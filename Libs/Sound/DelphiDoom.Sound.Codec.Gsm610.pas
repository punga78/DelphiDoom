{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - GSM 6.10 (RPE-LTP)                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the decoder of the GSM 06.10 library of Jutta Degener and Carsten   }
{  Bormann (Technische Universitaet Berlin), as libsndfile includes it.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.Gsm610;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Decoder of GSM 6.10 frames: 33 bytes make 160 samples. In the WAV
  ///   flavour (also called WAV49) two frames share 65 bytes. The state of
  ///   the filters goes from one frame to the next
  /// </summary>
  TGsm610Decoder = class
  private
    FDp0: array[0..279] of SmallInt;
    FMsr: SmallInt;
    FNrp: SmallInt;
    FV: array[0..8] of SmallInt;
    FLarpp: array[0..1, 0..7] of SmallInt;
    FJ: Integer;
    procedure Synthesise(const ALarc: array of SmallInt; const ANc, ABc, AMc,
      AXmaxc: array of SmallInt; const AXmc: array of SmallInt;
      var ATarget: array of SmallInt; ATargetOffset: Integer);
  public
    constructor Create;
    procedure Reset;
    /// <summary>
    ///   One frame of the standard flavour from ABytes at AOffset: false when
    ///   it does not start with the magic number (then nothing is written)
    /// </summary>
    function DecodeStandard(const ABytes: TBytes; AOffset: Integer;
      var ATarget: array of SmallInt; ATargetOffset: Integer): Boolean;
    /// <summary>
    ///   The two frames of a block of the WAV flavour, from ABytes at AOffset
    ///   (at least 65 bytes), into 320 samples at ATargetOffset
    /// </summary>
    procedure DecodeWav49(const ABytes: TBytes; AOffset: Integer;
      var ATarget: array of SmallInt; ATargetOffset: Integer);
    /// <summary>
    ///   Decodes the blocks of a sound as libsndfile does (the blocks are 65
    ///   bytes with AWav49, 33 otherwise). A last block that is cut short is
    ///   decoded with the bytes left from the one before
    /// </summary>
    class function Decode(const ASource: TBytes; ADataOffset, ADataLength: Int64;
      AWav49: Boolean; out AData: TBytes; out AFrames: Int64): Integer; static;
  end;

implementation

const
  MIN_WORD = -32768;
  MAX_WORD = 32767;
  GSM_MAGIC = $D;
  FRAME_BYTES = 33;
  WAV_BLOCK_BYTES = 65;
  FRAME_SAMPLES = 160;

  TABLE_QLB: array[0..3] of SmallInt = (3277, 11469, 21299, 32767);
  TABLE_FAC: array[0..7] of SmallInt = (18431, 20479, 22527, 24575, 26623, 28671, 30719, 32767);

  // For each of the eight LARs: B, MIC and INVA
  LAR_B: array[0..7] of Integer = (0, 0, 2048, -2560, 94, -1792, -341, -1144);
  LAR_MIC: array[0..7] of Integer = (-32, -32, -16, -16, -8, -8, -4, -4);
  LAR_INVA: array[0..7] of Integer = (13107, 13107, 13107, 13107, 19223, 17476, 31454, 29708);

/// <summary>Arithmetic shift right of a 32 bit value</summary>
function ShiftRight(AValue, ABy: Integer): Integer;
begin
  if ABy <= 0 then
    Exit(AValue);
  Result := (AValue - (AValue and ((1 shl ABy) - 1))) div (1 shl ABy);
end;

function Word16(AValue: Integer): SmallInt;
begin
  Result := SmallInt(AValue and $FFFF);
end;

function Saturate(AValue: Integer): Integer;
begin
  if AValue < MIN_WORD then
    Result := MIN_WORD
  else if AValue > MAX_WORD then
    Result := MAX_WORD
  else
    Result := AValue;
end;

function GsmAdd(A, B: Integer): Integer;
begin
  Result := Saturate(A + B);
end;

function GsmSub(A, B: Integer): Integer;
begin
  Result := Saturate(A - B);
end;

/// <summary>GSM_MULT_R of the inlined macros: no special case for -32768 twice</summary>
function MultR(A, B: Integer): Integer;
begin
  Result := ShiftRight(A * B + 16384, 15);
end;

/// <summary>SASR_W: signed shift right of a 16 bit value</summary>
function ShiftRightWord(A: Integer; ABy: Integer): Integer;
begin
  Result := ShiftRight(A, ABy);
end;

function GsmAsr(A: SmallInt; N: Integer): SmallInt;
begin
  if N >= 16 then
  begin
    if A < 0 then
      Result := -1
    else
      Result := 0;
  end
  else if N <= -16 then
    Result := 0
  else if N < 0 then
    Result := Word16(A shl (-N))
  else
    Result := SmallInt(ShiftRightWord(A, N));
end;

function GsmAsl(A: SmallInt; N: Integer): SmallInt;
begin
  if N >= 16 then
    Result := 0
  else if N <= -16 then
  begin
    if A < 0 then
      Result := -1
    else
      Result := 0;
  end
  else if N < 0 then
    Result := GsmAsr(A, -N)
  else
    Result := Word16(A shl N);
end;

{ TGsm610Decoder }

constructor TGsm610Decoder.Create;
begin
  inherited Create;
  Reset;
end;

procedure TGsm610Decoder.Reset;
begin
  FillChar(FDp0, SizeOf(FDp0), 0);
  FillChar(FV, SizeOf(FV), 0);
  FillChar(FLarpp, SizeOf(FLarpp), 0);
  FMsr := 0;
  FJ := 0;
  FNrp := 40;
end;

procedure TGsm610Decoder.Synthesise(const ALarc: array of SmallInt; const ANc,
  ABc, AMc, AXmaxc: array of SmallInt; const AXmc: array of SmallInt;
  var ATarget: array of SmallInt; ATargetOffset: Integer);
var
  LSubframe, LK, LI, LNr, LExponent, LMantissa, LTemp, LTemp1, LTemp2, LTemp3,
  LBrp, LDrpp, LMsr: Integer;
  LXmp: array[0..12] of SmallInt;
  LErp: array[0..39] of SmallInt;
  LWt: array[0..159] of SmallInt;
  LLarp: array[0..7] of SmallInt;
  LCurrent, LPrevious: Integer;

  procedure RunFilter(AFirst, ACount: Integer);
  var
    LStep, LIndex: Integer;
    LSri, LTmp1, LTmp2: Integer;
  begin
    for LStep := 0 to ACount - 1 do
    begin
      LSri := LWt[AFirst + LStep];
      for LIndex := 7 downto 0 do
      begin
        LTmp1 := LLarp[LIndex];
        LTmp2 := FV[LIndex];
        if (LTmp1 = MIN_WORD) and (LTmp2 = MIN_WORD) then
          LTmp2 := MAX_WORD
        else
          LTmp2 := Word16(ShiftRight(LTmp1 * LTmp2 + 16384, 15));
        LSri := GsmSub(LSri, LTmp2);

        if (LTmp1 = MIN_WORD) and (LSri = MIN_WORD) then
          LTmp1 := MAX_WORD
        else
          LTmp1 := Word16(ShiftRight(LTmp1 * LSri + 16384, 15));
        FV[LIndex + 1] := SmallInt(GsmAdd(FV[LIndex], LTmp1));
      end;
      FV[0] := SmallInt(LSri);
      ATarget[ATargetOffset + AFirst + LStep] := SmallInt(LSri);
    end;
  end;

  procedure ToReflection;
  var
    LElement, LValue, LAbs: Integer;
  begin
    for LElement := 0 to 7 do
    begin
      if LLarp[LElement] < 0 then
      begin
        if LLarp[LElement] = MIN_WORD then
          LAbs := MAX_WORD
        else
          LAbs := -LLarp[LElement];
        if LAbs < 11059 then
          LValue := LAbs shl 1
        else if LAbs < 20070 then
          LValue := LAbs + 11059
        else
          LValue := GsmAdd(ShiftRight(LAbs, 2), 26112);
        LLarp[LElement] := Word16(-LValue);
      end
      else
      begin
        LAbs := LLarp[LElement];
        if LAbs < 11059 then
          LValue := LAbs shl 1
        else if LAbs < 20070 then
          LValue := LAbs + 11059
        else
          LValue := GsmAdd(ShiftRight(LAbs, 2), 26112);
        LLarp[LElement] := Word16(LValue);
      end;
    end;
  end;

begin
  // The four sub-frames of 40 samples
  for LSubframe := 0 to 3 do
  begin
    // Decoding of the RPE sequence: exponent and mantissa of xmaxc
    LExponent := 0;
    if AXmaxc[LSubframe] > 15 then
      LExponent := Word16(ShiftRightWord(AXmaxc[LSubframe], 3) - 1);
    LMantissa := Word16(AXmaxc[LSubframe] - (LExponent shl 3));
    if LMantissa = 0 then
    begin
      LExponent := -4;
      LMantissa := 7;
    end
    else
    begin
      while LMantissa <= 7 do
      begin
        LMantissa := Word16((LMantissa shl 1) or 1);
        Dec(LExponent);
      end;
      Dec(LMantissa, 8);
    end;

    // Inverse quantization of the 13 samples
    LTemp1 := TABLE_FAC[LMantissa];
    LTemp2 := GsmSub(6, LExponent);
    LTemp3 := GsmAsl(1, GsmSub(LTemp2, 1));
    for LK := 0 to 12 do
    begin
      LTemp := (AXmc[LSubframe * 13 + LK] shl 1) - 7;
      LTemp := Word16(LTemp shl 12);
      LTemp := Word16(MultR(LTemp1, LTemp));
      LTemp := GsmAdd(LTemp, LTemp3);
      LXmp[LK] := GsmAsr(SmallInt(LTemp), LTemp2);
    end;

    // The grid: the 13 samples every third position from Mc, zeros elsewhere
    FillChar(LErp, SizeOf(LErp), 0);
    for LK := 0 to 12 do
      LErp[AMc[LSubframe] + 3 * LK] := LXmp[LK];

    // Long term synthesis filtering
    if (ANc[LSubframe] < 40) or (ANc[LSubframe] > 120) then
      LNr := FNrp
    else
      LNr := ANc[LSubframe];
    FNrp := SmallInt(LNr);
    LBrp := TABLE_QLB[ABc[LSubframe]];
    for LK := 0 to 39 do
    begin
      LDrpp := Word16(MultR(LBrp, FDp0[120 + LK - LNr]));
      FDp0[120 + LK] := SmallInt(GsmAdd(LErp[LK], LDrpp));
    end;
    for LK := 0 to 119 do
      FDp0[LK] := FDp0[40 + LK];
    for LK := 0 to 39 do
      LWt[LSubframe * 40 + LK] := FDp0[120 + LK];
    // what was just computed stays at the end of the history
  end;

  // Short term synthesis filtering: the LARs of this frame and of the one before
  LCurrent := FJ;
  FJ := FJ xor 1;
  LPrevious := FJ;
  for LI := 0 to 7 do
  begin
    LTemp1 := Word16(GsmAdd(ALarc[LI], LAR_MIC[LI]) shl 10);
    LTemp1 := GsmSub(LTemp1, LAR_B[LI] * 2);
    LTemp1 := Word16(MultR(LAR_INVA[LI], LTemp1));
    FLarpp[LCurrent, LI] := SmallInt(GsmAdd(LTemp1, LTemp1));
  end;

  for LI := 0 to 7 do
  begin
    LLarp[LI] := SmallInt(GsmAdd(ShiftRightWord(FLarpp[LPrevious, LI], 2), ShiftRightWord(FLarpp[LCurrent, LI], 2)));
    LLarp[LI] := SmallInt(GsmAdd(LLarp[LI], ShiftRightWord(FLarpp[LPrevious, LI], 1)));
  end;
  ToReflection;
  RunFilter(0, 13);

  for LI := 0 to 7 do
    LLarp[LI] := SmallInt(GsmAdd(ShiftRightWord(FLarpp[LPrevious, LI], 1), ShiftRightWord(FLarpp[LCurrent, LI], 1)));
  ToReflection;
  RunFilter(13, 14);

  for LI := 0 to 7 do
  begin
    LLarp[LI] := SmallInt(GsmAdd(ShiftRightWord(FLarpp[LPrevious, LI], 2), ShiftRightWord(FLarpp[LCurrent, LI], 2)));
    LLarp[LI] := SmallInt(GsmAdd(LLarp[LI], ShiftRightWord(FLarpp[LCurrent, LI], 1)));
  end;
  ToReflection;
  RunFilter(27, 13);

  for LI := 0 to 7 do
    LLarp[LI] := FLarpp[LCurrent, LI];
  ToReflection;
  RunFilter(40, 120);

  // Postprocessing: de-emphasis, truncation and upscaling
  LMsr := FMsr;
  for LK := 0 to FRAME_SAMPLES - 1 do
  begin
    LTemp := Word16(MultR(LMsr, 28180));
    LMsr := Word16(GsmAdd(ATarget[ATargetOffset + LK], LTemp));
    ATarget[ATargetOffset + LK] := SmallInt(Word16(GsmAdd(LMsr, LMsr) and $FFF8));
  end;
  FMsr := SmallInt(LMsr);
end;

function TGsm610Decoder.DecodeStandard(const ABytes: TBytes; AOffset: Integer;
  var ATarget: array of SmallInt; ATargetOffset: Integer): Boolean;
var
  LBit: Integer;
  LLarc: array[0..7] of SmallInt;
  LNc, LBc, LMc, LXmaxc: array[0..3] of SmallInt;
  LXmc: array[0..51] of SmallInt;
  LSubframe, LK, LWidth: Integer;

  function Take(ACount: Integer): Integer;
  var
    LIndex, LByte: Integer;
  begin
    Result := 0;
    for LIndex := 1 to ACount do
    begin
      if AOffset + (LBit shr 3) < Length(ABytes) then
        LByte := ABytes[AOffset + (LBit shr 3)]
      else
        LByte := 0;
      Result := (Result shl 1) or ((LByte shr (7 - (LBit and 7))) and 1);
      Inc(LBit);
    end;
  end;

begin
  LBit := 0;
  if Take(4) <> GSM_MAGIC then
    Exit(False);
  for LK := 0 to 7 do
  begin
    case LK of
      0, 1: LWidth := 6;
      2, 3: LWidth := 5;
      4, 5: LWidth := 4;
    else
      LWidth := 3;
    end;
    LLarc[LK] := Take(LWidth);
  end;
  for LSubframe := 0 to 3 do
  begin
    LNc[LSubframe] := Take(7);
    LBc[LSubframe] := Take(2);
    LMc[LSubframe] := Take(2);
    LXmaxc[LSubframe] := Take(6);
    for LK := 0 to 12 do
      LXmc[LSubframe * 13 + LK] := Take(3);
  end;
  Synthesise(LLarc, LNc, LBc, LMc, LXmaxc, LXmc, ATarget, ATargetOffset);
  Result := True;
end;

procedure TGsm610Decoder.DecodeWav49(const ABytes: TBytes; AOffset: Integer;
  var ATarget: array of SmallInt; ATargetOffset: Integer);
var
  LBit, LHalf: Integer;
  LLarc: array[0..7] of SmallInt;
  LNc, LBc, LMc, LXmaxc: array[0..3] of SmallInt;
  LXmc: array[0..51] of SmallInt;
  LSubframe, LK, LWidth: Integer;

  function Take(ACount: Integer): Integer;
  var
    LIndex, LByte: Integer;
  begin
    Result := 0;
    for LIndex := 0 to ACount - 1 do
    begin
      if AOffset + (LBit shr 3) < Length(ABytes) then
        LByte := ABytes[AOffset + (LBit shr 3)]
      else
        LByte := 0;
      Result := Result or (((LByte shr (LBit and 7)) and 1) shl LIndex);
      Inc(LBit);
    end;
  end;

begin
  // The two frames are one stream of bits, the first bit of a byte being the low one
  for LHalf := 0 to 1 do
  begin
    LBit := LHalf * 260;
    for LK := 0 to 7 do
    begin
      case LK of
        0, 1: LWidth := 6;
        2, 3: LWidth := 5;
        4, 5: LWidth := 4;
      else
        LWidth := 3;
      end;
      LLarc[LK] := Take(LWidth);
    end;
    for LSubframe := 0 to 3 do
    begin
      LNc[LSubframe] := Take(7);
      LBc[LSubframe] := Take(2);
      LMc[LSubframe] := Take(2);
      LXmaxc[LSubframe] := Take(6);
      for LK := 0 to 12 do
        LXmc[LSubframe * 13 + LK] := Take(3);
    end;
    Synthesise(LLarc, LNc, LBc, LMc, LXmaxc, LXmc, ATarget,
      ATargetOffset + LHalf * FRAME_SAMPLES);
  end;
end;

class function TGsm610Decoder.Decode(const ASource: TBytes; ADataOffset,
  ADataLength: Int64; AWav49: Boolean; out AData: TBytes;
  out AFrames: Int64): Integer;
var
  LDecoder: TGsm610Decoder;
  LBlockSize, LSamplesPerBlock, LRead: Integer;
  LBlocks, LBlock, LPosition: Int64;
  LBytes: TBytes;
  LSamples: TArray<SmallInt>;
begin
  AData := nil;
  AFrames := 0;
  if AWav49 then
  begin
    LBlockSize := WAV_BLOCK_BYTES;
    LSamplesPerBlock := FRAME_SAMPLES * 2;
  end
  else
  begin
    LBlockSize := FRAME_BYTES;
    LSamplesPerBlock := FRAME_SAMPLES;
  end;
  if ADataLength < 0 then
    ADataLength := 0;

  if (ADataLength mod LBlockSize) = 0 then
    LBlocks := ADataLength div LBlockSize
  else if ((ADataLength mod LBlockSize) = 1) and (LBlockSize = FRAME_BYTES) then
    // An AIFF chunk of odd length is padded: the byte is not a block
    LBlocks := ADataLength div LBlockSize
  else
    LBlocks := ADataLength div LBlockSize + 1;
  AFrames := LSamplesPerBlock * LBlocks;
  SetLength(AData, AFrames * SizeOf(SmallInt));
  SetLength(LBytes, LBlockSize);
  SetLength(LSamples, LSamplesPerBlock);

  LDecoder := TGsm610Decoder.Create;
  try
    for LBlock := 0 to LBlocks - 1 do
    begin
      LPosition := ADataOffset + LBlock * LBlockSize;
      LRead := Length(ASource) - LPosition;
      if LRead > LBlockSize then
        LRead := LBlockSize;
      if LRead > 0 then
        Move(ASource[Integer(LPosition)], LBytes[0], LRead);
      if AWav49 then
        LDecoder.DecodeWav49(LBytes, 0, LSamples, 0)
      else
        // A block without the magic number leaves the previous samples as they are
        LDecoder.DecodeStandard(LBytes, 0, LSamples, 0);
      Move(LSamples[0], AData[Integer(LBlock * LSamplesPerBlock * SizeOf(SmallInt))],
        LSamplesPerBlock * SizeOf(SmallInt));
    end;
  finally
    LDecoder.Free;
  end;
  Result := SNDFILE_OK;
end;

end.
