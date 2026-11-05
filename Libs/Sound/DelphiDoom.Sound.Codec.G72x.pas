{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - G.721 and G.723 ADPCM                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the decoders of the Sun Microsystems reference code for CCITT       }
{  G.721 (32 kbit/s) and G.723 (24 and 40 kbit/s), as libsndfile includes it.  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.G72x;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Decoder of the G.721 / G.723 ADPCM streams: 3 to 5 bits per sample, in
  ///   blocks of 120 samples. The state of the predictor goes from one sample
  ///   to the next
  /// </summary>
  TG72xDecoder = class
  private
    FYl: Integer;
    FYu: SmallInt;
    FDms: SmallInt;
    FDml: SmallInt;
    FAp: SmallInt;
    FA: array[0..1] of SmallInt;
    FB: array[0..5] of SmallInt;
    FPk: array[0..1] of SmallInt;
    FDq: array[0..5] of SmallInt;
    FSr: array[0..1] of SmallInt;
    FTd: Integer;
    FBits: Integer;
    function PredictorZero: Integer;
    function PredictorPole: Integer;
    function StepSize: Integer;
    procedure Update(ACodeSize, AY, AWi, AFi, ADq, ASr, ADqsez: Integer);
    function DecodeSample(ACode: Integer): Integer;
  public
    /// <summary>ABits is 3 (G.723 24 kbit/s), 4 (G.721) or 5 (G.723 40 kbit/s)</summary>
    constructor Create(ABits: Integer);
    /// <summary>
    ///   Decodes the blocks of a sound. The last one, if cut short, is decoded
    ///   with the bytes the buffer still held from the block before
    /// </summary>
    class function Decode(const ASource: TBytes; ADataOffset, ADataLength: Int64;
      ABits: Integer; out AData: TBytes; out AFrames: Int64): Integer; static;
  end;

implementation

const
  BLOCK_SAMPLES = 120;

  POWER_2: array[0..14] of Integer = (1, 2, 4, 8, $10, $20, $40, $80, $100, $200,
    $400, $800, $1000, $2000, $4000);

  G721_DQLN: array[0..15] of SmallInt = (-2048, 4, 135, 213, 273, 323, 373, 425,
    425, 373, 323, 273, 213, 135, 4, -2048);
  G721_WI: array[0..15] of SmallInt = (-12, 18, 41, 64, 112, 198, 355, 1122,
    1122, 355, 198, 112, 64, 41, 18, -12);
  G721_FI: array[0..15] of SmallInt = (0, 0, 0, $200, $200, $200, $600, $E00,
    $E00, $600, $200, $200, $200, 0, 0, 0);

  G723_24_DQLN: array[0..7] of SmallInt = (-2048, 135, 273, 373, 373, 273, 135, -2048);
  G723_24_WI: array[0..7] of SmallInt = (-128, 960, 4384, 18624, 18624, 4384, 960, -128);
  G723_24_FI: array[0..7] of SmallInt = (0, $200, $400, $E00, $E00, $400, $200, 0);

  G723_40_DQLN: array[0..31] of SmallInt = (-2048, -66, 28, 104, 169, 224, 274, 318,
    358, 395, 429, 459, 488, 514, 539, 566, 566, 539, 514, 488, 459, 429, 395, 358,
    318, 274, 224, 169, 104, 28, -66, -2048);
  G723_40_WI: array[0..31] of SmallInt = (448, 448, 768, 1248, 1280, 1312, 1856, 3200,
    4512, 5728, 7008, 8960, 11456, 14080, 16928, 22272, 22272, 16928, 14080, 11456,
    8960, 7008, 5728, 4512, 3200, 1856, 1312, 1280, 1248, 768, 448, 448);
  G723_40_FI: array[0..31] of SmallInt = (0, 0, 0, 0, 0, $200, $200, $200, $200, $200,
    $400, $600, $800, $A00, $C00, $C00, $C00, $C00, $A00, $800, $600, $400, $200,
    $200, $200, $200, $200, 0, 0, 0, 0, 0);

/// <summary>The low 16 bits of a number, as a C short</summary>
function S16(AValue: Integer): SmallInt;
begin
  Result := SmallInt(AValue and $FFFF);
end;

/// <summary>Arithmetic shift right (Delphi's shr does not keep the sign)</summary>
function Sar(AValue, ABy: Integer): Integer;
begin
  if ABy <= 0 then
    Exit(AValue shl (-ABy));
  if ABy >= 31 then
  begin
    if AValue < 0 then
      Exit(-1);
    Exit(0);
  end;
  Result := (AValue - (AValue and ((1 shl ABy) - 1))) div (1 shl ABy);
end;

function Quan(AValue: Integer; const ATable: array of Integer): Integer;
begin
  Result := 0;
  while (Result < Length(ATable)) and (AValue >= ATable[Result]) do
    Inc(Result);
end;

/// <summary>Product of a 14 bit number and a "floating point" one (4 bit exponent, 6 bit mantissa)</summary>
function FMult(AN, ASrn: Integer): Integer;
var
  LAnMag, LAnExp, LAnMant, LWanExp, LWanMant, LResult: Integer;
begin
  if AN > 0 then
    LAnMag := S16(AN)
  else
    LAnMag := S16((-AN) and $1FFF);
  LAnExp := S16(Quan(LAnMag, POWER_2) - 6);
  if LAnMag = 0 then
    LAnMant := 32
  else if LAnExp >= 0 then
    LAnMant := S16(Sar(LAnMag, LAnExp))
  else
    LAnMant := S16(LAnMag shl (-LAnExp));
  LWanExp := S16(LAnExp + (Sar(ASrn, 6) and $F) - 13);
  LWanMant := S16(Sar(LAnMant * (ASrn and $3F), 4));
  if LWanExp >= 0 then
    LResult := S16((LWanMant shl LWanExp) and $7FFF)
  else
    LResult := S16(Sar(LWanMant, -LWanExp));
  if (AN xor ASrn) < 0 then
    Result := -LResult
  else
    Result := LResult;
end;

{ TG72xDecoder }

constructor TG72xDecoder.Create(ABits: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FBits := ABits;
  FYl := 34816;
  FYu := 544;
  FDms := 0;
  FDml := 0;
  FAp := 0;
  for LIndex := 0 to 1 do
  begin
    FA[LIndex] := 0;
    FPk[LIndex] := 0;
    FSr[LIndex] := 32;
  end;
  for LIndex := 0 to 5 do
  begin
    FB[LIndex] := 0;
    FDq[LIndex] := 32;
  end;
  FTd := 0;
end;

function TG72xDecoder.PredictorZero: Integer;
var
  LIndex: Integer;
begin
  Result := FMult(Sar(FB[0], 2), FDq[0]);
  for LIndex := 1 to 5 do
    Inc(Result, FMult(Sar(FB[LIndex], 2), FDq[LIndex]));
end;

function TG72xDecoder.PredictorPole: Integer;
begin
  Result := FMult(Sar(FA[1], 2), FSr[1]) + FMult(Sar(FA[0], 2), FSr[0]);
end;

function TG72xDecoder.StepSize: Integer;
var
  LY, LDif, LAl: Integer;
begin
  if FAp >= 256 then
    Exit(FYu);
  LY := Sar(FYl, 6);
  LDif := FYu - LY;
  LAl := Sar(FAp, 2);
  if LDif > 0 then
    Inc(LY, Sar(LDif * LAl, 6))
  else if LDif < 0 then
    Inc(LY, Sar(LDif * LAl + $3F, 6));
  Result := LY;
end;

procedure TG72xDecoder.Update(ACodeSize, AY, AWi, AFi, ADq, ASr, ADqsez: Integer);
var
  LCount, LMag, LExponent, LA2p, LA1ul, LPks1, LFa1, LYlInt, LThr2, LDqThr,
  LYlFrac, LThr1, LPk0, LTr: Integer;
begin
  LA2p := 0;
  if ADqsez < 0 then
    LPk0 := 1
  else
    LPk0 := 0;
  LMag := S16(ADq and $7FFF);

  // Tone / transition detector
  LYlInt := S16(Sar(FYl, 15));
  LYlFrac := S16(Sar(FYl, 10) and $1F);
  LThr1 := S16((32 + LYlFrac) shl LYlInt);
  if LYlInt > 9 then
    LThr2 := S16(31 shl 10)
  else
    LThr2 := LThr1;
  LDqThr := S16(Sar(LThr2 + Sar(LThr2, 1), 1));
  if FTd = 0 then
    LTr := 0
  else if LMag <= LDqThr then
    LTr := 0
  else
    LTr := 1;

  // Quantizer scale factor adaptation
  FYu := S16(AY + Sar(AWi - AY, 5));
  if FYu < 544 then
    FYu := 544
  else if FYu > 5120 then
    FYu := 5120;
  Inc(FYl, FYu + Sar(-FYl, 6));

  // Adaptive predictor coefficients
  if LTr = 1 then
  begin
    FA[0] := 0;
    FA[1] := 0;
    for LCount := 0 to 5 do
      FB[LCount] := 0;
  end
  else
  begin
    LPks1 := S16(LPk0 xor FPk[0]);
    LA2p := S16(FA[1] - Sar(FA[1], 7));
    if ADqsez <> 0 then
    begin
      if LPks1 <> 0 then
        LFa1 := FA[0]
      else
        LFa1 := S16(-FA[0]);
      if LFa1 < -8191 then
        LA2p := S16(LA2p - $100)
      else if LFa1 > 8191 then
        LA2p := S16(LA2p + $FF)
      else
        LA2p := S16(LA2p + Sar(LFa1, 5));
      if (LPk0 xor FPk[1]) <> 0 then
      begin
        if LA2p <= -12160 then
          LA2p := -12288
        else if LA2p >= 12416 then
          LA2p := 12288
        else
          LA2p := S16(LA2p - $80);
      end
      else if LA2p <= -12416 then
        LA2p := -12288
      else if LA2p >= 12160 then
        LA2p := 12288
      else
        LA2p := S16(LA2p + $80);
    end;

    FA[1] := LA2p;
    FA[0] := S16(FA[0] - Sar(FA[0], 8));
    if ADqsez <> 0 then
    begin
      if LPks1 = 0 then
        FA[0] := S16(FA[0] + 192)
      else
        FA[0] := S16(FA[0] - 192);
    end;
    LA1ul := S16(15360 - LA2p);
    if FA[0] < -LA1ul then
      FA[0] := S16(-LA1ul)
    else if FA[0] > LA1ul then
      FA[0] := S16(LA1ul);

    for LCount := 0 to 5 do
    begin
      if ACodeSize = 5 then
        FB[LCount] := S16(FB[LCount] - Sar(FB[LCount], 9))
      else
        FB[LCount] := S16(FB[LCount] - Sar(FB[LCount], 8));
      if (ADq and $7FFF) <> 0 then
      begin
        if (ADq xor FDq[LCount]) >= 0 then
          FB[LCount] := S16(FB[LCount] + 128)
        else
          FB[LCount] := S16(FB[LCount] - 128);
      end;
    end;
  end;

  for LCount := 5 downto 1 do
    FDq[LCount] := FDq[LCount - 1];

  // The quantized difference as a float of 4 bit exponent and 6 bit mantissa
  if LMag = 0 then
  begin
    if ADq >= 0 then
      FDq[0] := $20
    else
      FDq[0] := S16($FC20);
  end
  else
  begin
    LExponent := S16(Quan(LMag, POWER_2));
    if ADq >= 0 then
      FDq[0] := S16((LExponent shl 6) + Sar(LMag shl 6, LExponent))
    else
      FDq[0] := S16((LExponent shl 6) + Sar(LMag shl 6, LExponent) - $400);
  end;

  FSr[1] := FSr[0];
  if ASr = 0 then
    FSr[0] := $20
  else if ASr > 0 then
  begin
    LExponent := S16(Quan(ASr, POWER_2));
    FSr[0] := S16((LExponent shl 6) + Sar(ASr shl 6, LExponent));
  end
  else if ASr > -32768 then
  begin
    LMag := S16(-ASr);
    LExponent := S16(Quan(LMag, POWER_2));
    FSr[0] := S16((LExponent shl 6) + Sar(LMag shl 6, LExponent) - $400);
  end
  else
    FSr[0] := S16($FC20);

  FPk[1] := FPk[0];
  FPk[0] := S16(LPk0);

  // Tone detection
  if LTr = 1 then
    FTd := 0
  else if LA2p < -11776 then
    FTd := 1
  else
    FTd := 0;

  // Adaptation speed control
  FDms := S16(FDms + Sar(AFi - FDms, 5));
  FDml := S16(FDml + Sar((AFi shl 2) - FDml, 7));
  if LTr = 1 then
    FAp := 256
  else if AY < 1536 then
    FAp := S16(FAp + Sar($200 - FAp, 4))
  else if FTd = 1 then
    FAp := S16(FAp + Sar($200 - FAp, 4))
  else if Abs((FDms shl 2) - FDml) >= Sar(FDml, 3) then
    FAp := S16(FAp + Sar($200 - FAp, 4))
  else
    FAp := S16(FAp + Sar(-FAp, 4));
end;

function TG72xDecoder.DecodeSample(ACode: Integer): Integer;
var
  LSezi, LSei, LSez, LSe, LY, LSr, LDq, LDqsez, LMask, LSignBit, LWi, LFi, LDqln,
  LMagMask: Integer;
begin
  case FBits of
    4:
      begin
        LMask := $0F;
        LSignBit := $08;
        LMagMask := $3FFF;
      end;
    3:
      begin
        LMask := $07;
        LSignBit := $04;
        LMagMask := $3FFF;
      end;
  else
    begin
      LMask := $1F;
      LSignBit := $10;
      LMagMask := $7FFF;
    end;
  end;
  ACode := ACode and LMask;
  case FBits of
    4:
      begin
        LDqln := G721_DQLN[ACode];
        LWi := Integer(G721_WI[ACode]) shl 5;
        LFi := G721_FI[ACode];
      end;
    3:
      begin
        LDqln := G723_24_DQLN[ACode];
        LWi := G723_24_WI[ACode];
        LFi := G723_24_FI[ACode];
      end;
  else
    begin
      LDqln := G723_40_DQLN[ACode];
      LWi := G723_40_WI[ACode];
      LFi := G723_40_FI[ACode];
    end;
  end;

  LSezi := S16(PredictorZero);
  LSez := Sar(LSezi, 1);
  LSei := S16(LSezi + PredictorPole);
  LSe := S16(Sar(LSei, 1));
  LY := S16(StepSize);

  // The reconstruction of the quantized difference
  begin
    var LDql: Integer := S16(LDqln + Sar(LY, 2));
    var LDex, LDqt: Integer;
    if LDql < 0 then
    begin
      if (ACode and LSignBit) <> 0 then
        LDq := S16(-$8000)
      else
        LDq := 0;
    end
    else
    begin
      LDex := S16(Sar(LDql, 7) and 15);
      LDqt := S16(128 + (LDql and 127));
      LDq := S16(Sar(LDqt shl 7, 14 - LDex));
      if (ACode and LSignBit) <> 0 then
        LDq := S16(LDq - $8000);
    end;
  end;

  if LDq < 0 then
    LSr := S16(LSe - (LDq and LMagMask))
  else
    LSr := S16(LSe + LDq);
  LDqsez := S16(LSr - LSe + LSez);
  Update(FBits, LY, LWi, LFi, LDq, LSr, LDqsez);
  Result := S16(LSr shl 2);
end;

class function TG72xDecoder.Decode(const ASource: TBytes; ADataOffset,
  ADataLength: Int64; ABits: Integer; out AData: TBytes;
  out AFrames: Int64): Integer;
var
  LDecoder: TG72xDecoder;
  LBytesPerBlock, LBlocks, LRead, LBit, LSample, LByteIndex: Integer;
  LBlock, LPosition: Int64;
  LBytes: TBytes;
  LBuffer: Cardinal;
  LBufferBits, LPacked: Integer;
  LSamples: array[0..BLOCK_SAMPLES - 1] of SmallInt;
begin
  AData := nil;
  AFrames := 0;
  if (ABits < 3) or (ABits > 5) then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  if ADataLength < 0 then
    ADataLength := 0;
  LBytesPerBlock := ABits * BLOCK_SAMPLES div 8;

  LBlocks := Integer(ADataLength div LBytesPerBlock);
  if (ADataLength mod LBytesPerBlock) <> 0 then
    Inc(LBlocks);
  AFrames := Int64(LBlocks) * BLOCK_SAMPLES;
  SetLength(AData, AFrames * SizeOf(SmallInt));
  // The buffer of libsndfile is as big as the biggest block
  SetLength(LBytes, BLOCK_SAMPLES);

  LDecoder := TG72xDecoder.Create(ABits);
  try
    for LBlock := 0 to LBlocks - 1 do
    begin
      LPosition := ADataOffset + LBlock * LBytesPerBlock;
      LRead := Length(ASource) - LPosition;
      if LRead > LBytesPerBlock then
        LRead := LBytesPerBlock;
      if LRead > 0 then
        Move(ASource[Integer(LPosition)], LBytes[0], LRead);

      // Unpack: the codes come low bits first
      LBuffer := 0;
      LBufferBits := 0;
      LByteIndex := 0;
      for LSample := 0 to BLOCK_SAMPLES - 1 do
      begin
        if LBufferBits < ABits then
        begin
          LBuffer := LBuffer or (Cardinal(LBytes[LByteIndex]) shl LBufferBits);
          Inc(LByteIndex);
          Inc(LBufferBits, 8);
        end;
        LPacked := Integer(LBuffer and ((1 shl ABits) - 1));
        LBuffer := LBuffer shr ABits;
        Dec(LBufferBits, ABits);
        LSamples[LSample] := SmallInt(LPacked);
      end;
      for LBit := 0 to BLOCK_SAMPLES - 1 do
        LSamples[LBit] := SmallInt(LDecoder.DecodeSample(LSamples[LBit]));
      Move(LSamples[0], AData[Integer(LBlock * BLOCK_SAMPLES * SizeOf(SmallInt))],
        BLOCK_SAMPLES * SizeOf(SmallInt));
    end;
  finally
    LDecoder.Free;
  end;
  Result := SNDFILE_OK;
end;

end.
