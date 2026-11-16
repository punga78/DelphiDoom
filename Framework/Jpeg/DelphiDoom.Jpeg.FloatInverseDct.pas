{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the floating point inverse DCT                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.FloatInverseDct;

interface

uses
  DelphiDoom.Jpeg.InverseDct, DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   Inverse DCT in single precision floating point (jidctflt.c of libjpeg 6b, the algorithm of
  ///   Arai, Agui and Nakajima). It is what Doom 3 uses for the frames of its videos: the
  ///   <c>jconfig.h</c> of its <c>jpeg-6</c> defines <c>JDCT_FASTEST</c> as <c>JDCT_FLOAT</c>. The
  ///   quantization table is multiplied by the scale factors of the algorithm as <c>jddctmgr.c</c>
  ///   does (in double, then stored as single), and each statement is written as in
  ///   the C source, so the intermediate results of a statement have the precision of the floating point
  ///   unit (extended on Win32, as the x87 code of the original compilers; double on Win64) and only
  ///   the variables are single; the final sum is truncated to an integer and rounded with a shift as
  ///   <c>DESCALE</c> does
  /// </summary>
  /// <remarks>
  ///   An addition of this unit: the decoder uses <c>TJpegSlowInverseDct</c> unless it is asked for
  ///   the fast one (<c>TJpegDecodeOptions</c>)
  /// </remarks>
  TJpegFloatInverseDct = class(TInterfacedObject, IJpegInverseDct)
  private
    class var FRangeLimit: array[0..1023] of Byte;
    class constructor Create;
  public
    procedure Transform(const ACoefficients: TJpegBlock;
      const AQuantization: array of Integer; AOutput: PByte; AStride: NativeInt);
  end;

implementation

{$POINTERMATH ON}
{$Q-}
{$R-}

const
  RANGE_MASK = 1023;
  /// <summary>aanscalefactor[] of jddctmgr.c</summary>
  AAN_SCALE_FACTOR: array[0..JPEG_DCT_SIZE - 1] of Double = (
    1.0, 1.387039845, 1.306562965, 1.175875602, 1.0, 0.785694958, 0.541196100, 0.275899379);

function ToInt32(AValue: Extended): Integer; inline;
begin
  // (INT32) of a float: the value that does not fit is the "integer indefinite" of the processor
  if (AValue >= 2147483648.0) or (AValue < -2147483648.0) or (AValue <> AValue) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

function Descale3(AValue: Integer): Integer; inline;
var
  LSum: Integer;
begin
  // DESCALE(x, 3): (x + 4) >> 3, the shift keeps the sign
  LSum := AValue + 4;
  if LSum >= 0 then
    Result := LSum shr 3
  else
    Result := not ((not LSum) shr 3);
end;

{ TJpegFloatInverseDct }

class constructor TJpegFloatInverseDct.Create;
var
  LIndex: Integer;
begin
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

procedure TJpegFloatInverseDct.Transform(const ACoefficients: TJpegBlock;
  const AQuantization: array of Integer; AOutput: PByte; AStride: NativeInt);
const
  C1_414213562: Single = 1.414213562;
  C1_847759065: Single = 1.847759065;
  C1_082392200: Single = 1.082392200;
  CM2_613125930: Single = -2.613125930;
var
  LMultipliers: array[0..JPEG_DCT_SIZE2 - 1] of Single;
  LWorkspace: array[0..JPEG_DCT_SIZE2 - 1] of Single;
  LColumn: Integer;
  LRow: Integer;
  LIndex: Integer;
  LOutput: PByte;
  LTmp0, LTmp1, LTmp2, LTmp3, LTmp4, LTmp5, LTmp6, LTmp7: Single;
  LTmp10, LTmp11, LTmp12, LTmp13: Single;
  LZ5, LZ10, LZ11, LZ12, LZ13: Single;
  LDc: Single;
begin
  // The multipliers: the quantization value times the scale factors of its row and its column
  for LIndex := 0 to JPEG_DCT_SIZE2 - 1 do
    LMultipliers[LIndex] := Single(AQuantization[LIndex] * AAN_SCALE_FACTOR[LIndex shr 3] *
      AAN_SCALE_FACTOR[LIndex and 7]);

  // Pass 1: the columns, from the input to the workspace
  for LColumn := 0 to JPEG_DCT_SIZE - 1 do
  begin
    if (ACoefficients[LColumn + 8] or ACoefficients[LColumn + 16] or
        ACoefficients[LColumn + 24] or ACoefficients[LColumn + 32] or
        ACoefficients[LColumn + 40] or ACoefficients[LColumn + 48] or
        ACoefficients[LColumn + 56]) = 0 then
    begin
      LDc := ACoefficients[LColumn] * LMultipliers[LColumn];
      for LRow := 0 to JPEG_DCT_SIZE - 1 do
        LWorkspace[LColumn + LRow * 8] := LDc;
      Continue;
    end;

    // Even part
    LTmp0 := ACoefficients[LColumn] * LMultipliers[LColumn];
    LTmp1 := ACoefficients[LColumn + 16] * LMultipliers[LColumn + 16];
    LTmp2 := ACoefficients[LColumn + 32] * LMultipliers[LColumn + 32];
    LTmp3 := ACoefficients[LColumn + 48] * LMultipliers[LColumn + 48];

    LTmp10 := LTmp0 + LTmp2;
    LTmp11 := LTmp0 - LTmp2;

    LTmp13 := LTmp1 + LTmp3;
    LTmp12 := (LTmp1 - LTmp3) * C1_414213562 - LTmp13;

    LTmp0 := LTmp10 + LTmp13;
    LTmp3 := LTmp10 - LTmp13;
    LTmp1 := LTmp11 + LTmp12;
    LTmp2 := LTmp11 - LTmp12;

    // Odd part
    LTmp4 := ACoefficients[LColumn + 8] * LMultipliers[LColumn + 8];
    LTmp5 := ACoefficients[LColumn + 24] * LMultipliers[LColumn + 24];
    LTmp6 := ACoefficients[LColumn + 40] * LMultipliers[LColumn + 40];
    LTmp7 := ACoefficients[LColumn + 56] * LMultipliers[LColumn + 56];

    LZ13 := LTmp6 + LTmp5;
    LZ10 := LTmp6 - LTmp5;
    LZ11 := LTmp4 + LTmp7;
    LZ12 := LTmp4 - LTmp7;

    LTmp7 := LZ11 + LZ13;
    LTmp11 := (LZ11 - LZ13) * C1_414213562;

    LZ5 := (LZ10 + LZ12) * C1_847759065;
    LTmp10 := C1_082392200 * LZ12 - LZ5;
    LTmp12 := CM2_613125930 * LZ10 + LZ5;

    LTmp6 := LTmp12 - LTmp7;
    LTmp5 := LTmp11 - LTmp6;
    LTmp4 := LTmp10 + LTmp5;

    LWorkspace[LColumn] := LTmp0 + LTmp7;
    LWorkspace[LColumn + 56] := LTmp0 - LTmp7;
    LWorkspace[LColumn + 8] := LTmp1 + LTmp6;
    LWorkspace[LColumn + 48] := LTmp1 - LTmp6;
    LWorkspace[LColumn + 16] := LTmp2 + LTmp5;
    LWorkspace[LColumn + 40] := LTmp2 - LTmp5;
    LWorkspace[LColumn + 32] := LTmp3 + LTmp4;
    LWorkspace[LColumn + 24] := LTmp3 - LTmp4;
  end;

  // Pass 2: the rows, from the workspace to the output
  for LRow := 0 to JPEG_DCT_SIZE - 1 do
  begin
    LOutput := AOutput + LRow * AStride;
    LIndex := LRow * 8;

    LTmp10 := LWorkspace[LIndex] + LWorkspace[LIndex + 4];
    LTmp11 := LWorkspace[LIndex] - LWorkspace[LIndex + 4];

    LTmp13 := LWorkspace[LIndex + 2] + LWorkspace[LIndex + 6];
    LTmp12 := (LWorkspace[LIndex + 2] - LWorkspace[LIndex + 6]) * C1_414213562 - LTmp13;

    LTmp0 := LTmp10 + LTmp13;
    LTmp3 := LTmp10 - LTmp13;
    LTmp1 := LTmp11 + LTmp12;
    LTmp2 := LTmp11 - LTmp12;

    LZ13 := LWorkspace[LIndex + 5] + LWorkspace[LIndex + 3];
    LZ10 := LWorkspace[LIndex + 5] - LWorkspace[LIndex + 3];
    LZ11 := LWorkspace[LIndex + 1] + LWorkspace[LIndex + 7];
    LZ12 := LWorkspace[LIndex + 1] - LWorkspace[LIndex + 7];

    LTmp7 := LZ11 + LZ13;
    LTmp11 := (LZ11 - LZ13) * C1_414213562;

    LZ5 := (LZ10 + LZ12) * C1_847759065;
    LTmp10 := C1_082392200 * LZ12 - LZ5;
    LTmp12 := CM2_613125930 * LZ10 + LZ5;

    LTmp6 := LTmp12 - LTmp7;
    LTmp5 := LTmp11 - LTmp6;
    LTmp4 := LTmp10 + LTmp5;

    LOutput[0] := FRangeLimit[Descale3(ToInt32(LTmp0 + LTmp7)) and RANGE_MASK];
    LOutput[7] := FRangeLimit[Descale3(ToInt32(LTmp0 - LTmp7)) and RANGE_MASK];
    LOutput[1] := FRangeLimit[Descale3(ToInt32(LTmp1 + LTmp6)) and RANGE_MASK];
    LOutput[6] := FRangeLimit[Descale3(ToInt32(LTmp1 - LTmp6)) and RANGE_MASK];
    LOutput[2] := FRangeLimit[Descale3(ToInt32(LTmp2 + LTmp5)) and RANGE_MASK];
    LOutput[5] := FRangeLimit[Descale3(ToInt32(LTmp2 - LTmp5)) and RANGE_MASK];
    LOutput[4] := FRangeLimit[Descale3(ToInt32(LTmp3 + LTmp4)) and RANGE_MASK];
    LOutput[3] := FRangeLimit[Descale3(ToInt32(LTmp3 - LTmp4)) and RANGE_MASK];
  end;
end;

end.