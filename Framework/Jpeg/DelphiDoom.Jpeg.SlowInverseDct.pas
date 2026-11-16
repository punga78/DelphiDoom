{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the accurate integer inverse DCT                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.SlowInverseDct;

interface

uses
  DelphiDoom.Jpeg.InverseDct, DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   Inverse DCT in integers (jidctint.c of libjpeg 6b, the algorithm of
  ///   Loeffler, Ligtenberg and Moschytz): a pass over the columns and one
  ///   over the rows, with 13 bits of fraction in the constants and 2 more
  ///   bits of precision between the passes
  /// </summary>
  /// <remarks>
  ///   The 32 bit sums and products wrap around, as the original does on
  ///   32 bit integers. The samples are limited to 0..255 after adding 128
  ///   (a table of 1024 entries indexed by the low 10 bits of the result: the
  ///   values that are far out of range wrap, as in the original)
  /// </remarks>
  TJpegSlowInverseDct = class(TInterfacedObject, IJpegInverseDct)
  private
    class var FRangeLimit: array[0..1023] of Byte;
    class constructor Create;
  public
    procedure Transform(const ACoefficients: TJpegBlock;
      const AQuantization: array of Integer; AOutput: PByte; AStride: NativeInt);
  end;

implementation

// The sums and products wrap around: no checks of overflow and of ranges
{$Q-}
{$R-}
{$POINTERMATH ON}

const
  CONST_BITS = 13;
  PASS1_BITS = 2;

  FIX_0_298631336 = 2446;
  FIX_0_390180644 = 3196;
  FIX_0_541196100 = 4433;
  FIX_0_765366865 = 6270;
  FIX_0_899976223 = 7373;
  FIX_1_175875602 = 9633;
  FIX_1_501321110 = 12299;
  FIX_1_847759065 = 15137;
  FIX_1_961570560 = 16069;
  FIX_2_053119869 = 16819;
  FIX_2_562915447 = 20995;
  FIX_3_072711026 = 25172;

  // Rounding of the shifts that finish the passes
  ROUND_PASS_1 = 1 shl (CONST_BITS - PASS1_BITS - 1);
  ROUND_PASS_2 = 1 shl (CONST_BITS + PASS1_BITS + 3 - 1);
  ROUND_ROW_OF_DC = 1 shl (PASS1_BITS + 3 - 1);
  RANGE_MASK = 1023;

function ArithmeticShiftRight(AValue, ACount: Integer): Integer; inline;
begin
  // The right shift of a negative number keeps the sign
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := not ((not AValue) shr ACount);
end;

{ TJpegSlowInverseDct }

class constructor TJpegSlowInverseDct.Create;
var
  LIndex: Integer;
begin
  // Entry j is the sample for a result whose low 10 bits are j: 0..127 are
  // the samples 128..255, up to 511 is too bright, from 512 on is too dark
  // (the negative values), and the last 128 are the samples 0..127
  for LIndex := 0 to 1023 do
    if LIndex < 128 then
      FRangeLimit[LIndex] := Byte(LIndex + 128)
    else if LIndex < 512 then
      FRangeLimit[LIndex] := 255
    else if LIndex < 896 then
      FRangeLimit[LIndex] := 0
    else
      FRangeLimit[LIndex] := Byte(LIndex - 896);
end;

procedure TJpegSlowInverseDct.Transform(const ACoefficients: TJpegBlock;
  const AQuantization: array of Integer; AOutput: PByte; AStride: NativeInt);
var
  LWorkspace: array[0..JPEG_DCT_SIZE2 - 1] of Integer;
  LColumn: Integer;
  LRow: Integer;
  LInput: Integer;
  LOutput: PByte;
  LTmp0, LTmp1, LTmp2, LTmp3: Integer;
  LTmp10, LTmp11, LTmp12, LTmp13: Integer;
  LZ1, LZ2, LZ3, LZ4, LZ5: Integer;
  LDc: Integer;
begin
  // Pass 1: the columns, from the input to the workspace
  for LColumn := 0 to JPEG_DCT_SIZE - 1 do
  begin
    if (ACoefficients[LColumn + 8] or ACoefficients[LColumn + 16] or
        ACoefficients[LColumn + 24] or ACoefficients[LColumn + 32] or
        ACoefficients[LColumn + 40] or ACoefficients[LColumn + 48] or
        ACoefficients[LColumn + 56]) = 0 then
    begin
      // The column is only a DC term
      LDc := (ACoefficients[LColumn] * AQuantization[LColumn]) shl PASS1_BITS;
      for LRow := 0 to JPEG_DCT_SIZE - 1 do
        LWorkspace[LColumn + LRow * 8] := LDc;
      Continue;
    end;

    // Even part
    LZ2 := ACoefficients[LColumn + 16] * AQuantization[LColumn + 16];
    LZ3 := ACoefficients[LColumn + 48] * AQuantization[LColumn + 48];
    LZ1 := (LZ2 + LZ3) * FIX_0_541196100;
    LTmp2 := LZ1 + LZ3 * (-FIX_1_847759065);
    LTmp3 := LZ1 + LZ2 * FIX_0_765366865;

    LZ2 := ACoefficients[LColumn] * AQuantization[LColumn];
    LZ3 := ACoefficients[LColumn + 32] * AQuantization[LColumn + 32];
    LTmp0 := (LZ2 + LZ3) shl CONST_BITS;
    LTmp1 := (LZ2 - LZ3) shl CONST_BITS;

    LTmp10 := LTmp0 + LTmp3;
    LTmp13 := LTmp0 - LTmp3;
    LTmp11 := LTmp1 + LTmp2;
    LTmp12 := LTmp1 - LTmp2;

    // Odd part
    LTmp0 := ACoefficients[LColumn + 56] * AQuantization[LColumn + 56];
    LTmp1 := ACoefficients[LColumn + 40] * AQuantization[LColumn + 40];
    LTmp2 := ACoefficients[LColumn + 24] * AQuantization[LColumn + 24];
    LTmp3 := ACoefficients[LColumn + 8] * AQuantization[LColumn + 8];

    LZ1 := LTmp0 + LTmp3;
    LZ2 := LTmp1 + LTmp2;
    LZ3 := LTmp0 + LTmp2;
    LZ4 := LTmp1 + LTmp3;
    LZ5 := (LZ3 + LZ4) * FIX_1_175875602;

    LTmp0 := LTmp0 * FIX_0_298631336;
    LTmp1 := LTmp1 * FIX_2_053119869;
    LTmp2 := LTmp2 * FIX_3_072711026;
    LTmp3 := LTmp3 * FIX_1_501321110;
    LZ1 := LZ1 * (-FIX_0_899976223);
    LZ2 := LZ2 * (-FIX_2_562915447);
    LZ3 := LZ3 * (-FIX_1_961570560);
    LZ4 := LZ4 * (-FIX_0_390180644);

    LZ3 := LZ3 + LZ5;
    LZ4 := LZ4 + LZ5;

    LTmp0 := LTmp0 + LZ1 + LZ3;
    LTmp1 := LTmp1 + LZ2 + LZ4;
    LTmp2 := LTmp2 + LZ2 + LZ3;
    LTmp3 := LTmp3 + LZ1 + LZ4;

    LWorkspace[LColumn] := ArithmeticShiftRight(LTmp10 + LTmp3 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 56] := ArithmeticShiftRight(LTmp10 - LTmp3 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 8] := ArithmeticShiftRight(LTmp11 + LTmp2 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 48] := ArithmeticShiftRight(LTmp11 - LTmp2 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 16] := ArithmeticShiftRight(LTmp12 + LTmp1 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 40] := ArithmeticShiftRight(LTmp12 - LTmp1 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 24] := ArithmeticShiftRight(LTmp13 + LTmp0 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
    LWorkspace[LColumn + 32] := ArithmeticShiftRight(LTmp13 - LTmp0 + ROUND_PASS_1,
      CONST_BITS - PASS1_BITS);
  end;

  // Pass 2: the rows, from the workspace to the samples
  for LRow := 0 to JPEG_DCT_SIZE - 1 do
  begin
    LInput := LRow * 8;
    LOutput := AOutput + LRow * AStride;

    if (LWorkspace[LInput + 1] or LWorkspace[LInput + 2] or LWorkspace[LInput + 3] or
        LWorkspace[LInput + 4] or LWorkspace[LInput + 5] or LWorkspace[LInput + 6] or
        LWorkspace[LInput + 7]) = 0 then
    begin
      // The row is only a DC term
      LDc := FRangeLimit[ArithmeticShiftRight(LWorkspace[LInput] + ROUND_ROW_OF_DC,
        PASS1_BITS + 3) and RANGE_MASK];
      FillChar(LOutput^, JPEG_DCT_SIZE, LDc);
      Continue;
    end;

    // Even part
    LZ2 := LWorkspace[LInput + 2];
    LZ3 := LWorkspace[LInput + 6];
    LZ1 := (LZ2 + LZ3) * FIX_0_541196100;
    LTmp2 := LZ1 + LZ3 * (-FIX_1_847759065);
    LTmp3 := LZ1 + LZ2 * FIX_0_765366865;

    LTmp0 := (LWorkspace[LInput] + LWorkspace[LInput + 4]) shl CONST_BITS;
    LTmp1 := (LWorkspace[LInput] - LWorkspace[LInput + 4]) shl CONST_BITS;

    LTmp10 := LTmp0 + LTmp3;
    LTmp13 := LTmp0 - LTmp3;
    LTmp11 := LTmp1 + LTmp2;
    LTmp12 := LTmp1 - LTmp2;

    // Odd part
    LTmp0 := LWorkspace[LInput + 7];
    LTmp1 := LWorkspace[LInput + 5];
    LTmp2 := LWorkspace[LInput + 3];
    LTmp3 := LWorkspace[LInput + 1];

    LZ1 := LTmp0 + LTmp3;
    LZ2 := LTmp1 + LTmp2;
    LZ3 := LTmp0 + LTmp2;
    LZ4 := LTmp1 + LTmp3;
    LZ5 := (LZ3 + LZ4) * FIX_1_175875602;

    LTmp0 := LTmp0 * FIX_0_298631336;
    LTmp1 := LTmp1 * FIX_2_053119869;
    LTmp2 := LTmp2 * FIX_3_072711026;
    LTmp3 := LTmp3 * FIX_1_501321110;
    LZ1 := LZ1 * (-FIX_0_899976223);
    LZ2 := LZ2 * (-FIX_2_562915447);
    LZ3 := LZ3 * (-FIX_1_961570560);
    LZ4 := LZ4 * (-FIX_0_390180644);

    LZ3 := LZ3 + LZ5;
    LZ4 := LZ4 + LZ5;

    LTmp0 := LTmp0 + LZ1 + LZ3;
    LTmp1 := LTmp1 + LZ2 + LZ4;
    LTmp2 := LTmp2 + LZ2 + LZ3;
    LTmp3 := LTmp3 + LZ1 + LZ4;

    LOutput[0] := FRangeLimit[Integer((Cardinal(LTmp10 + LTmp3 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[7] := FRangeLimit[Integer((Cardinal(LTmp10 - LTmp3 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[1] := FRangeLimit[Integer((Cardinal(LTmp11 + LTmp2 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[6] := FRangeLimit[Integer((Cardinal(LTmp11 - LTmp2 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[2] := FRangeLimit[Integer((Cardinal(LTmp12 + LTmp1 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[5] := FRangeLimit[Integer((Cardinal(LTmp12 - LTmp1 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[3] := FRangeLimit[Integer((Cardinal(LTmp13 + LTmp0 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
    LOutput[4] := FRangeLimit[Integer((Cardinal(LTmp13 - LTmp0 + ROUND_PASS_2)) shr
      (CONST_BITS + PASS1_BITS + 3)) and RANGE_MASK];
  end;
end;

end.
