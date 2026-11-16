{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, the inverse MDCT                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Mdct;

interface

{$POINTERMATH ON}

type
  /// <summary>
  ///   The inverse MDCT of one block size, with the trigonometric tables it
  ///   needs. The operations are those of libvorbis, in the same order, so the
  ///   floating point results are the same
  /// </summary>
  TVorbisMdct = class
  private
    FSize: Integer;
    FLog2Size: Integer;
    FTrig: TArray<Single>;
    FBitReverse: TArray<Integer>;
    class procedure Butterfly8(AData: PSingle); static;
    class procedure Butterfly16(AData: PSingle); static;
    class procedure Butterfly32(AData: PSingle); static;
    class procedure ButterflyFirst(ATrig, AData: PSingle; APoints: Integer); static;
    class procedure ButterflyGeneric(ATrig, AData: PSingle; APoints, ATrigStep: Integer); static;
    procedure Butterflies(AData: PSingle; APoints: Integer);
    procedure BitReverse(AData: PSingle);
  public
    /// <summary>ASize is the length of the block, a power of two of at least 64</summary>
    constructor Create(ASize: Integer);
    /// <summary>
    ///   Transforms in place the ASize / 2 values of the spectrum at the start
    ///   of AData into the ASize samples of the block, still to be windowed
    /// </summary>
    procedure Backward(AData: PSingle);
  end;

implementation

uses
  System.Math;

const
  CPI3_8: Single = 0.38268343236508977175;
  CPI2_8: Single = 0.70710678118654752441;
  CPI1_8: Single = 0.92387953251128675613;
  // The double of C's M_PI, which is what the tables are computed with
  PI_DOUBLE: Double = 3.14159265358979323846;

{ TVorbisMdct }

constructor TVorbisMdct.Create(ASize: Integer);
var
  LIndex, LJ, LHalf, LMask, LMsb, LAcc: Integer;
begin
  inherited Create;
  FSize := ASize;
  LHalf := ASize shr 1;
  FLog2Size := Round(Ln(Single(ASize)) / Ln(Single(2.0)));
  SetLength(FTrig, ASize + ASize div 4);
  SetLength(FBitReverse, ASize div 4);

  for LIndex := 0 to ASize div 4 - 1 do
  begin
    FTrig[LIndex * 2] := Cos((PI_DOUBLE / ASize) * (4 * LIndex));
    FTrig[LIndex * 2 + 1] := -Sin((PI_DOUBLE / ASize) * (4 * LIndex));
    FTrig[LHalf + LIndex * 2] := Cos((PI_DOUBLE / (2 * ASize)) * (2 * LIndex + 1));
    FTrig[LHalf + LIndex * 2 + 1] := Sin((PI_DOUBLE / (2 * ASize)) * (2 * LIndex + 1));
  end;
  for LIndex := 0 to ASize div 8 - 1 do
  begin
    FTrig[ASize + LIndex * 2] := Cos((PI_DOUBLE / ASize) * (4 * LIndex + 2)) * 0.5;
    FTrig[ASize + LIndex * 2 + 1] := -Sin((PI_DOUBLE / ASize) * (4 * LIndex + 2)) * 0.5;
  end;

  LMask := (1 shl (FLog2Size - 1)) - 1;
  LMsb := 1 shl (FLog2Size - 2);
  for LIndex := 0 to ASize div 8 - 1 do
  begin
    LAcc := 0;
    LJ := 0;
    while (LMsb shr LJ) <> 0 do
    begin
      if ((LMsb shr LJ) and LIndex) <> 0 then
        LAcc := LAcc or (1 shl LJ);
      Inc(LJ);
    end;
    FBitReverse[LIndex * 2] := ((not LAcc) and LMask) - 1;
    FBitReverse[LIndex * 2 + 1] := LAcc;
  end;
end;

class procedure TVorbisMdct.Butterfly8(AData: PSingle);
var
  LR0, LR1, LR2, LR3: Single;
begin
  LR0 := AData[6] + AData[2];
  LR1 := AData[6] - AData[2];
  LR2 := AData[4] + AData[0];
  LR3 := AData[4] - AData[0];

  AData[6] := LR0 + LR2;
  AData[4] := LR0 - LR2;

  LR0 := AData[5] - AData[1];
  LR2 := AData[7] - AData[3];
  AData[0] := LR1 + LR0;
  AData[2] := LR1 - LR0;

  LR0 := AData[5] + AData[1];
  LR1 := AData[7] + AData[3];
  AData[3] := LR2 + LR3;
  AData[1] := LR2 - LR3;
  AData[7] := LR1 + LR0;
  AData[5] := LR1 - LR0;
end;

class procedure TVorbisMdct.Butterfly16(AData: PSingle);
var
  LR0, LR1: Single;
begin
  LR0 := AData[1] - AData[9];
  LR1 := AData[0] - AData[8];

  AData[8] := AData[8] + AData[0];
  AData[9] := AData[9] + AData[1];
  AData[0] := (LR0 + LR1) * CPI2_8;
  AData[1] := (LR0 - LR1) * CPI2_8;

  LR0 := AData[3] - AData[11];
  LR1 := AData[10] - AData[2];
  AData[10] := AData[10] + AData[2];
  AData[11] := AData[11] + AData[3];
  AData[2] := LR0;
  AData[3] := LR1;

  LR0 := AData[12] - AData[4];
  LR1 := AData[13] - AData[5];
  AData[12] := AData[12] + AData[4];
  AData[13] := AData[13] + AData[5];
  AData[4] := (LR0 - LR1) * CPI2_8;
  AData[5] := (LR0 + LR1) * CPI2_8;

  LR0 := AData[14] - AData[6];
  LR1 := AData[15] - AData[7];
  AData[14] := AData[14] + AData[6];
  AData[15] := AData[15] + AData[7];
  AData[6] := LR0;
  AData[7] := LR1;

  Butterfly8(AData);
  Butterfly8(AData + 8);
end;

class procedure TVorbisMdct.Butterfly32(AData: PSingle);
var
  LR0, LR1: Single;
begin
  LR0 := AData[30] - AData[14];
  LR1 := AData[31] - AData[15];

  AData[30] := AData[30] + AData[14];
  AData[31] := AData[31] + AData[15];
  AData[14] := LR0;
  AData[15] := LR1;

  LR0 := AData[28] - AData[12];
  LR1 := AData[29] - AData[13];
  AData[28] := AData[28] + AData[12];
  AData[29] := AData[29] + AData[13];
  AData[12] := LR0 * CPI1_8 - LR1 * CPI3_8;
  AData[13] := LR0 * CPI3_8 + LR1 * CPI1_8;

  LR0 := AData[26] - AData[10];
  LR1 := AData[27] - AData[11];
  AData[26] := AData[26] + AData[10];
  AData[27] := AData[27] + AData[11];
  AData[10] := (LR0 - LR1) * CPI2_8;
  AData[11] := (LR0 + LR1) * CPI2_8;

  LR0 := AData[24] - AData[8];
  LR1 := AData[25] - AData[9];
  AData[24] := AData[24] + AData[8];
  AData[25] := AData[25] + AData[9];
  AData[8] := LR0 * CPI3_8 - LR1 * CPI1_8;
  AData[9] := LR1 * CPI3_8 + LR0 * CPI1_8;

  LR0 := AData[22] - AData[6];
  LR1 := AData[7] - AData[23];
  AData[22] := AData[22] + AData[6];
  AData[23] := AData[23] + AData[7];
  AData[6] := LR1;
  AData[7] := LR0;

  LR0 := AData[4] - AData[20];
  LR1 := AData[5] - AData[21];
  AData[20] := AData[20] + AData[4];
  AData[21] := AData[21] + AData[5];
  AData[4] := LR1 * CPI1_8 + LR0 * CPI3_8;
  AData[5] := LR1 * CPI3_8 - LR0 * CPI1_8;

  LR0 := AData[2] - AData[18];
  LR1 := AData[3] - AData[19];
  AData[18] := AData[18] + AData[2];
  AData[19] := AData[19] + AData[3];
  AData[2] := (LR1 + LR0) * CPI2_8;
  AData[3] := (LR1 - LR0) * CPI2_8;

  LR0 := AData[0] - AData[16];
  LR1 := AData[1] - AData[17];
  AData[16] := AData[16] + AData[0];
  AData[17] := AData[17] + AData[1];
  AData[0] := LR1 * CPI3_8 + LR0 * CPI1_8;
  AData[1] := LR1 * CPI1_8 - LR0 * CPI3_8;

  Butterfly16(AData);
  Butterfly16(AData + 16);
end;

class procedure TVorbisMdct.ButterflyFirst(ATrig, AData: PSingle; APoints: Integer);
var
  LX1, LX2, LT: PSingle;
  LR0, LR1: Single;
begin
  LX1 := AData + APoints - 8;
  LX2 := AData + (APoints shr 1) - 8;
  LT := ATrig;
  repeat
    LR0 := LX1[6] - LX2[6];
    LR1 := LX1[7] - LX2[7];
    LX1[6] := LX1[6] + LX2[6];
    LX1[7] := LX1[7] + LX2[7];
    LX2[6] := LR1 * LT[1] + LR0 * LT[0];
    LX2[7] := LR1 * LT[0] - LR0 * LT[1];

    LR0 := LX1[4] - LX2[4];
    LR1 := LX1[5] - LX2[5];
    LX1[4] := LX1[4] + LX2[4];
    LX1[5] := LX1[5] + LX2[5];
    LX2[4] := LR1 * LT[5] + LR0 * LT[4];
    LX2[5] := LR1 * LT[4] - LR0 * LT[5];

    LR0 := LX1[2] - LX2[2];
    LR1 := LX1[3] - LX2[3];
    LX1[2] := LX1[2] + LX2[2];
    LX1[3] := LX1[3] + LX2[3];
    LX2[2] := LR1 * LT[9] + LR0 * LT[8];
    LX2[3] := LR1 * LT[8] - LR0 * LT[9];

    LR0 := LX1[0] - LX2[0];
    LR1 := LX1[1] - LX2[1];
    LX1[0] := LX1[0] + LX2[0];
    LX1[1] := LX1[1] + LX2[1];
    LX2[0] := LR1 * LT[13] + LR0 * LT[12];
    LX2[1] := LR1 * LT[12] - LR0 * LT[13];

    LX1 := LX1 - 8;
    LX2 := LX2 - 8;
    LT := LT + 16;
  until LX2 < AData;
end;

class procedure TVorbisMdct.ButterflyGeneric(ATrig, AData: PSingle; APoints,
  ATrigStep: Integer);
var
  LX1, LX2, LT: PSingle;
  LR0, LR1: Single;
begin
  LX1 := AData + APoints - 8;
  LX2 := AData + (APoints shr 1) - 8;
  LT := ATrig;
  repeat
    LR0 := LX1[6] - LX2[6];
    LR1 := LX1[7] - LX2[7];
    LX1[6] := LX1[6] + LX2[6];
    LX1[7] := LX1[7] + LX2[7];
    LX2[6] := LR1 * LT[1] + LR0 * LT[0];
    LX2[7] := LR1 * LT[0] - LR0 * LT[1];
    LT := LT + ATrigStep;

    LR0 := LX1[4] - LX2[4];
    LR1 := LX1[5] - LX2[5];
    LX1[4] := LX1[4] + LX2[4];
    LX1[5] := LX1[5] + LX2[5];
    LX2[4] := LR1 * LT[1] + LR0 * LT[0];
    LX2[5] := LR1 * LT[0] - LR0 * LT[1];
    LT := LT + ATrigStep;

    LR0 := LX1[2] - LX2[2];
    LR1 := LX1[3] - LX2[3];
    LX1[2] := LX1[2] + LX2[2];
    LX1[3] := LX1[3] + LX2[3];
    LX2[2] := LR1 * LT[1] + LR0 * LT[0];
    LX2[3] := LR1 * LT[0] - LR0 * LT[1];
    LT := LT + ATrigStep;

    LR0 := LX1[0] - LX2[0];
    LR1 := LX1[1] - LX2[1];
    LX1[0] := LX1[0] + LX2[0];
    LX1[1] := LX1[1] + LX2[1];
    LX2[0] := LR1 * LT[1] + LR0 * LT[0];
    LX2[1] := LR1 * LT[0] - LR0 * LT[1];
    LT := LT + ATrigStep;

    LX1 := LX1 - 8;
    LX2 := LX2 - 8;
  until LX2 < AData;
end;

procedure TVorbisMdct.Butterflies(AData: PSingle; APoints: Integer);
var
  LStages, LI, LJ: Integer;
begin
  LStages := FLog2Size - 5;
  Dec(LStages);
  if LStages > 0 then
    ButterflyFirst(@FTrig[0], AData, APoints);

  LI := 1;
  while True do
  begin
    Dec(LStages);
    if LStages <= 0 then
      Break;
    for LJ := 0 to (1 shl LI) - 1 do
      ButterflyGeneric(@FTrig[0], AData + (APoints shr LI) * LJ, APoints shr LI, 4 shl LI);
    Inc(LI);
  end;

  LJ := 0;
  while LJ < APoints do
  begin
    Butterfly32(AData + LJ);
    Inc(LJ, 32);
  end;
end;

procedure TVorbisMdct.BitReverse(AData: PSingle);
var
  LW0, LW1, LX0, LX1, LT, LBase: PSingle;
  LBit: Integer;
  LR0, LR1, LR2, LR3: Single;
begin
  LW0 := AData;
  LBase := AData + (FSize shr 1);
  LW1 := LBase;
  LT := @FTrig[FSize];
  LBit := 0;
  repeat
    LX0 := LBase + FBitReverse[LBit];
    LX1 := LBase + FBitReverse[LBit + 1];

    LR0 := LX0[1] - LX1[1];
    LR1 := LX0[0] + LX1[0];
    LR2 := LR1 * LT[0] + LR0 * LT[1];
    LR3 := LR1 * LT[1] - LR0 * LT[0];

    LW1 := LW1 - 4;

    LR0 := (LX0[1] + LX1[1]) * 0.5;
    LR1 := (LX0[0] - LX1[0]) * 0.5;

    LW0[0] := LR0 + LR2;
    LW1[2] := LR0 - LR2;
    LW0[1] := LR1 + LR3;
    LW1[3] := LR3 - LR1;

    LX0 := LBase + FBitReverse[LBit + 2];
    LX1 := LBase + FBitReverse[LBit + 3];

    LR0 := LX0[1] - LX1[1];
    LR1 := LX0[0] + LX1[0];
    LR2 := LR1 * LT[2] + LR0 * LT[3];
    LR3 := LR1 * LT[3] - LR0 * LT[2];

    LR0 := (LX0[1] + LX1[1]) * 0.5;
    LR1 := (LX0[0] - LX1[0]) * 0.5;

    LW0[2] := LR0 + LR2;
    LW1[0] := LR0 - LR2;
    LW0[3] := LR1 + LR3;
    LW1[1] := LR3 - LR1;

    LT := LT + 4;
    Inc(LBit, 4);
    LW0 := LW0 + 4;
  until LW0 >= LW1;
end;

procedure TVorbisMdct.Backward(AData: PSingle);
var
  LN, LN2, LN4: Integer;
  LIX, LOX, LOX1, LOX2, LT: PSingle;
begin
  LN := FSize;
  LN2 := LN shr 1;
  LN4 := LN shr 2;

  // rotate
  LIX := AData + LN2 - 7;
  LOX := AData + LN2 + LN4;
  LT := @FTrig[LN4];
  repeat
    LOX := LOX - 4;
    LOX[0] := -LIX[2] * LT[3] - LIX[0] * LT[2];
    LOX[1] := LIX[0] * LT[3] - LIX[2] * LT[2];
    LOX[2] := -LIX[6] * LT[1] - LIX[4] * LT[0];
    LOX[3] := LIX[4] * LT[1] - LIX[6] * LT[0];
    LIX := LIX - 8;
    LT := LT + 4;
  until LIX < AData;

  LIX := AData + LN2 - 8;
  LOX := AData + LN2 + LN4;
  LT := @FTrig[LN4];
  repeat
    LT := LT - 4;
    LOX[0] := LIX[4] * LT[3] + LIX[6] * LT[2];
    LOX[1] := LIX[4] * LT[2] - LIX[6] * LT[3];
    LOX[2] := LIX[0] * LT[1] + LIX[2] * LT[0];
    LOX[3] := LIX[0] * LT[0] - LIX[2] * LT[1];
    LIX := LIX - 8;
    LOX := LOX + 4;
  until LIX < AData;

  Butterflies(AData + LN2, LN2);
  BitReverse(AData);

  // rotate + window
  LOX1 := AData + LN2 + LN4;
  LOX2 := AData + LN2 + LN4;
  LIX := AData;
  LT := @FTrig[LN2];
  repeat
    LOX1 := LOX1 - 4;

    LOX1[3] := LIX[0] * LT[1] - LIX[1] * LT[0];
    LOX2[0] := -(LIX[0] * LT[0] + LIX[1] * LT[1]);

    LOX1[2] := LIX[2] * LT[3] - LIX[3] * LT[2];
    LOX2[1] := -(LIX[2] * LT[2] + LIX[3] * LT[3]);

    LOX1[1] := LIX[4] * LT[5] - LIX[5] * LT[4];
    LOX2[2] := -(LIX[4] * LT[4] + LIX[5] * LT[5]);

    LOX1[0] := LIX[6] * LT[7] - LIX[7] * LT[6];
    LOX2[3] := -(LIX[6] * LT[6] + LIX[7] * LT[7]);

    LOX2 := LOX2 + 4;
    LIX := LIX + 8;
    LT := LT + 8;
  until LIX >= LOX1;

  LIX := AData + LN2 + LN4;
  LOX1 := AData + LN4;
  LOX2 := LOX1;
  repeat
    LOX1 := LOX1 - 4;
    LIX := LIX - 4;

    LOX1[3] := LIX[3];
    LOX2[0] := -LOX1[3];
    LOX1[2] := LIX[2];
    LOX2[1] := -LOX1[2];
    LOX1[1] := LIX[1];
    LOX2[2] := -LOX1[1];
    LOX1[0] := LIX[0];
    LOX2[3] := -LOX1[0];

    LOX2 := LOX2 + 4;
  until LOX2 >= LIX;

  LIX := AData + LN2 + LN4;
  LOX1 := AData + LN2 + LN4;
  LOX2 := AData + LN2;
  repeat
    LOX1 := LOX1 - 4;
    LOX1[0] := LIX[3];
    LOX1[1] := LIX[2];
    LOX1[2] := LIX[1];
    LOX1[3] := LIX[0];
    LIX := LIX + 4;
  until LOX1 <= LOX2;
end;

end.
