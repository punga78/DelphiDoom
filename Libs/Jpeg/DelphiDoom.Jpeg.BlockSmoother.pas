{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - smoothing of the blocks of an incomplete progressive     }
{  image                                                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.BlockSmoother;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.ComponentBuffers, DelphiDoom.Jpeg.Frame,
  DelphiDoom.Jpeg.ProgressiveDecoder, DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   When a progressive stream ends before the low bits of the first AC
  ///   coefficients (the five that give the gradients) were sent, the blocks
  ///   look like tiles. This estimates the missing coefficients from the DC of
  ///   the nine blocks around the block, so that the image is smooth
  /// </summary>
  /// <remarks>
  ///   Port of smoothing_ok and decompress_smooth_data of jdcoefct.c of
  ///   libjpeg 6b. Beyond the first and the last row and column the blocks
  ///   are taken to be equal to the nearest block that exists
  /// </remarks>
  TJpegBlockSmoother = class
  private
    // How many bits are missing of the coefficients 1 to 5 (zigzag), for
    // each component
    FMissingBits: array[0..JPEG_MAX_COMPONENTS - 1] of array[1..5] of Integer;
    class function Predict(ANumerator, AQuantization, AMissingBits: Integer): Integer; static;
  public
    /// <summary>
    ///   The smoother, if there is something to estimate: every component
    ///   has the DC and a quantization table without zeros in the first six
    ///   places, and the five coefficients are not all complete. Otherwise nil
    /// </summary>
    class function TryCreate(AFrame: TJpegFrame;
      ADecoder: TJpegProgressiveDecoder): TJpegBlockSmoother; static;

    /// <summary>
    ///   The coefficients of a block with the estimated ones in place of
    ///   those that are zero (and are missing bits)
    /// </summary>
    procedure SmoothBlock(AComponentIndex: Integer; AComponent: PJpegComponentInfo;
      ABuffers: TJpegComponentBuffers; ARow, AColumn: Integer; var AWorkspace: TJpegBlock);
  end;

implementation

{$Q-}
{$R-}

const
  // Places of the coefficients in a block (natural order)
  Q01_POSITION = 1;
  Q10_POSITION = 8;
  Q20_POSITION = 16;
  Q11_POSITION = 9;
  Q02_POSITION = 2;

{ TJpegBlockSmoother }

class function TJpegBlockSmoother.TryCreate(AFrame: TJpegFrame;
  ADecoder: TJpegProgressiveDecoder): TJpegBlockSmoother;
var
  LIndex: Integer;
  LCoefficient: Integer;
  LComponent: PJpegComponentInfo;
  LUseful: Boolean;
begin
  Result := TJpegBlockSmoother.Create;
  LUseful := False;
  for LIndex := 0 to AFrame.ComponentCount - 1 do
  begin
    LComponent := AFrame.ComponentByIndex[LIndex];
    if not LComponent^.HasQuantization or
       (LComponent^.Quantization[0] = 0) or
       (LComponent^.Quantization[Q01_POSITION] = 0) or
       (LComponent^.Quantization[Q10_POSITION] = 0) or
       (LComponent^.Quantization[Q20_POSITION] = 0) or
       (LComponent^.Quantization[Q11_POSITION] = 0) or
       (LComponent^.Quantization[Q02_POSITION] = 0) or
       (ADecoder.CoefficientBit(LIndex, 0) < 0) then
    begin
      // The DC is not known or a quantizer is zero: nothing can be estimated
      FreeAndNil(Result);
      Exit;
    end;
    for LCoefficient := 1 to 5 do
    begin
      Result.FMissingBits[LIndex][LCoefficient] := ADecoder.CoefficientBit(LIndex, LCoefficient);
      if Result.FMissingBits[LIndex][LCoefficient] <> 0 then
        LUseful := True;
    end;
  end;

  if not LUseful then
    FreeAndNil(Result);
end;

class function TJpegBlockSmoother.Predict(ANumerator, AQuantization,
  AMissingBits: Integer): Integer;
begin
  // The estimate is the number divided by 256 times the quantizer, rounded,
  // without going over the largest value that the missing bits can have
  if ANumerator >= 0 then
  begin
    Result := ((AQuantization shl 7) + ANumerator) div (AQuantization shl 8);
    if (AMissingBits > 0) and (Result >= (1 shl AMissingBits)) then
      Result := (1 shl AMissingBits) - 1;
  end
  else
  begin
    Result := ((AQuantization shl 7) - ANumerator) div (AQuantization shl 8);
    if (AMissingBits > 0) and (Result >= (1 shl AMissingBits)) then
      Result := (1 shl AMissingBits) - 1;
    Result := -Result;
  end;
end;

procedure TJpegBlockSmoother.SmoothBlock(AComponentIndex: Integer;
  AComponent: PJpegComponentInfo; ABuffers: TJpegComponentBuffers; ARow,
  AColumn: Integer; var AWorkspace: TJpegBlock);
var
  LAbove, LBelow, LLeft, LRight: Integer;
  LCurrent: PJpegBlock;
  LDc1, LDc2, LDc3, LDc4, LDc5, LDc6, LDc7, LDc8, LDc9: Integer;
  LQ00, LQ01, LQ10, LQ20, LQ11, LQ02: Integer;
  LBits: Integer;
begin
  LCurrent := ABuffers.Block(ARow, AColumn);
  AWorkspace := LCurrent^;

  // The nine blocks around this one; the missing ones are the nearest that exist
  LAbove := ARow - 1;
  if LAbove < 0 then
    LAbove := 0;
  LBelow := ARow + 1;
  if LBelow >= AComponent^.HeightInBlocks then
    LBelow := AComponent^.HeightInBlocks - 1;
  LLeft := AColumn - 1;
  if LLeft < 0 then
    LLeft := 0;
  LRight := AColumn + 1;
  if LRight >= AComponent^.WidthInBlocks then
    LRight := AComponent^.WidthInBlocks - 1;

  LDc1 := ABuffers.Block(LAbove, LLeft)^[0];
  LDc2 := ABuffers.Block(LAbove, AColumn)^[0];
  LDc3 := ABuffers.Block(LAbove, LRight)^[0];
  LDc4 := ABuffers.Block(ARow, LLeft)^[0];
  LDc5 := LCurrent^[0];
  LDc6 := ABuffers.Block(ARow, LRight)^[0];
  LDc7 := ABuffers.Block(LBelow, LLeft)^[0];
  LDc8 := ABuffers.Block(LBelow, AColumn)^[0];
  LDc9 := ABuffers.Block(LBelow, LRight)^[0];

  LQ00 := AComponent^.Quantization[0];
  LQ01 := AComponent^.Quantization[Q01_POSITION];
  LQ10 := AComponent^.Quantization[Q10_POSITION];
  LQ20 := AComponent^.Quantization[Q20_POSITION];
  LQ11 := AComponent^.Quantization[Q11_POSITION];
  LQ02 := AComponent^.Quantization[Q02_POSITION];

  // Horizontal gradient
  LBits := FMissingBits[AComponentIndex][1];
  if (LBits <> 0) and (AWorkspace[Q01_POSITION] = 0) then
    AWorkspace[Q01_POSITION] := Predict(36 * LQ00 * (LDc4 - LDc6), LQ01, LBits);

  // Vertical gradient
  LBits := FMissingBits[AComponentIndex][2];
  if (LBits <> 0) and (AWorkspace[Q10_POSITION] = 0) then
    AWorkspace[Q10_POSITION] := Predict(36 * LQ00 * (LDc2 - LDc8), LQ10, LBits);

  // Second derivative in the vertical direction
  LBits := FMissingBits[AComponentIndex][3];
  if (LBits <> 0) and (AWorkspace[Q20_POSITION] = 0) then
    AWorkspace[Q20_POSITION] := Predict(9 * LQ00 * (LDc2 + LDc8 - 2 * LDc5), LQ20, LBits);

  // Diagonal
  LBits := FMissingBits[AComponentIndex][4];
  if (LBits <> 0) and (AWorkspace[Q11_POSITION] = 0) then
    AWorkspace[Q11_POSITION] := Predict(5 * LQ00 * (LDc1 - LDc3 - LDc7 + LDc9), LQ11, LBits);

  // Second derivative in the horizontal direction
  LBits := FMissingBits[AComponentIndex][5];
  if (LBits <> 0) and (AWorkspace[Q02_POSITION] = 0) then
    AWorkspace[Q02_POSITION] := Predict(9 * LQ00 * (LDc4 + LDc6 - 2 * LDc5), LQ02, LBits);
end;

end.
