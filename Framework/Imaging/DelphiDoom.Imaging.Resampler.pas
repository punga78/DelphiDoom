{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the Lanczos resampler                          }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the kernel resampler of Graphics32 (GR32_Resamplers: TKernelResampler }
{  with TLanczosKernel, BuildMappingTable and Resample), without the bitmaps    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.Resampler;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   Resamples a picture with the Lanczos kernel of 3 lobes, the way Graphics32 does (the old
  ///   ENDEDIT used it to shrink a picture to 160x50 before it chose the text characters): for each
  ///   pixel of the result a table of weights (whole numbers that add to 256) says which pixels of
  ///   the source count; the picture is resampled in two passes, rows first and then columns, and
  ///   the sums are cut to 8 bits. The wrap-around of the integers is not needed (a sum fits 32
  ///   bits) but checks are off as in the original. The weights are computed with Single numbers
  ///   as the original does: on 32 bits they are the same, on 64 bits (SSE) a weight may differ by one
  ///   in 256 here and there, which changes a channel of a pixel by one level at most
  /// </summary>
  TImagingLanczosResampler = class(TInterfacedObject, IImagingResampler)
  strict private
    type
      TTap = record
        Position: Integer;
        Weight: Integer;
      end;
      TCluster = TArray<TTap>;
      TMappingTable = TArray<TCluster>;
    class function Sinc(AValue: Single): Single; static;
    class function Filter(AValue: Single): Single; static;
    class function BuildMappingTable(ASourceSize, ADestinationSize: Integer): TMappingTable; static;
  public
    function Resample(const ASource: TArray<Cardinal>; ASourceWidth, ASourceHeight,
      ADestinationWidth, ADestinationHeight: Integer): TArray<Cardinal>;
  end;

implementation

uses
  System.Math;

const
  /// <summary>Lobes of the kernel (the width of TLanczosKernel)</summary>
  LANCZOS_WIDTH: Single = 3;
  /// <summary>1 / the width, as a Single (FWidthReciprocal of TWindowedSincKernel)</summary>
  LANCZOS_WIDTH_RECIPROCAL: Single = 1 / 3;
  /// <summary>The weight of a whole pixel</summary>
  WEIGHT_ONE = 256;

type
  /// <summary>The sums of the four channels of a pixel after the first pass (the TBufferEntry of Graphics32)</summary>
  TChannelSums = record
    Red: Integer;
    Green: Integer;
    Blue: Integer;
    Alpha: Integer;
  end;

{ TImagingLanczosResampler }

class function TImagingLanczosResampler.Sinc(AValue: Single): Single;
begin
  if AValue <> 0 then
  begin
    AValue := AValue * Pi;
    Result := Sin(AValue) / AValue;
  end
  else
    Result := 1;
end;

class function TImagingLanczosResampler.Filter(AValue: Single): Single;
begin
  AValue := Abs(AValue);
  if AValue < LANCZOS_WIDTH then
    Result := Sinc(AValue) * Sinc(AValue * LANCZOS_WIDTH_RECIPROCAL)
  else
    Result := 0;
end;

class function TImagingLanczosResampler.BuildMappingTable(ASourceSize,
  ADestinationSize: Integer): TMappingTable;
var
  LScale: Single;
  LOldScale: Single;
  LFilterWidth: Single;
  LCenter: Single;
  LCount: Integer;
  LLeft: Integer;
  LRight: Integer;
  LIndex: Integer;
  LSource: Integer;
  LLast: Integer;
  LWeight: Integer;
  LTap: TTap;
  LCluster: TCluster;

  procedure AddTap(AIndex, ASourceIndex, AWeightValue: Integer);
  begin
    LLast := Length(Result[AIndex]);
    SetLength(Result[AIndex], LLast + 1);
    LTap.Position := EnsureRange(ASourceIndex, 0, ASourceSize - 1);
    LTap.Weight := AWeightValue;
    Result[AIndex][LLast] := LTap;
  end;

begin
  SetLength(Result, ADestinationSize);
  if ASourceSize = 1 then
  begin
    for LIndex := 0 to ADestinationSize - 1 do
    begin
      SetLength(LCluster, 1);
      LCluster[0].Position := 0;
      LCluster[0].Weight := WEIGHT_ONE;
      Result[LIndex] := LCluster;
    end;
    Exit;
  end;

  // the edges of the picture are the edges of the first and of the last pixel
  LScale := ADestinationSize / ASourceSize;
  LFilterWidth := LANCZOS_WIDTH;
  LLast := 0;
  if LScale < 1 then
  begin
    LOldScale := LScale;
    LScale := 1 / LScale;
    LFilterWidth := LFilterWidth * LScale;
    for LIndex := 0 to ADestinationSize - 1 do
    begin
      LCenter := -0.5 + (LIndex + 0.5) * LScale;
      LLeft := Floor(LCenter - LFilterWidth);
      LRight := Ceil(LCenter + LFilterWidth);
      LCount := -WEIGHT_ONE;
      for LSource := LLeft to LRight do
      begin
        LWeight := Round(256 * Filter((LCenter - LSource) * LOldScale) * LOldScale);
        if LWeight <> 0 then
        begin
          Inc(LCount, LWeight);
          AddTap(LIndex, LSource, LWeight);
        end;
      end;
      if Length(Result[LIndex]) = 0 then
      begin
        SetLength(Result[LIndex], 1);
        Result[LIndex][0].Position := Floor(LCenter);
        Result[LIndex][0].Weight := WEIGHT_ONE;
      end
      else if LCount <> 0 then
        Dec(Result[LIndex][LLast div 2].Weight, LCount);
    end;
  end
  else
  begin
    LScale := 1 / LScale;
    for LIndex := 0 to ADestinationSize - 1 do
    begin
      LCenter := -0.5 + (LIndex + 0.5) * LScale;
      LLeft := Floor(LCenter - LFilterWidth);
      LRight := Ceil(LCenter + LFilterWidth);
      LCount := -WEIGHT_ONE;
      for LSource := LLeft to LRight do
      begin
        LWeight := Round(256 * Filter(LCenter - LSource));
        if LWeight <> 0 then
        begin
          Inc(LCount, LWeight);
          AddTap(LIndex, LSource, LWeight);
        end;
      end;
      if Length(Result[LIndex]) = 0 then
        AddTap(LIndex, Floor(LCenter), WEIGHT_ONE)
      else if LCount <> 0 then
        Dec(Result[LIndex][LLast div 2].Weight, LCount);
    end;
  end;
end;

function TImagingLanczosResampler.Resample(const ASource: TArray<Cardinal>; ASourceWidth,
  ASourceHeight, ADestinationWidth, ADestinationHeight: Integer): TArray<Cardinal>;
var
  LMapX: TMappingTable;
  LMapY: TMappingTable;
  LLowPosition: Integer;
  LHighPosition: Integer;
  LBuffer: TArray<TChannelSums>;
  LRow: Integer;
  LColumn: Integer;
  LSourceColumn: Integer;
  LTap: TTap;
  LPixel: Cardinal;
  LAlpha: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LWeight: Integer;
  LCluster: TCluster;
begin
  if (ASourceWidth < 1) or (ASourceHeight < 1) or (ADestinationWidth < 1) or (ADestinationHeight < 1) or
    (Length(ASource) <> ASourceWidth * ASourceHeight) then
    raise EImagingException.CreateFmt(SImagingBadPictureSize,
      [ASourceWidth, ASourceHeight, ASourceWidth * ASourceHeight, Length(ASource)]);

  LMapX := BuildMappingTable(ASourceWidth, ADestinationWidth);
  LMapY := BuildMappingTable(ASourceHeight, ADestinationHeight);

  // the columns of the source that the second pass needs
  LLowPosition := MaxInt;
  LHighPosition := -1;
  for LCluster in LMapX do
    for LTap in LCluster do
    begin
      if LTap.Position < LLowPosition then
        LLowPosition := LTap.Position;
      if LTap.Position > LHighPosition then
        LHighPosition := LTap.Position;
    end;
  SetLength(LBuffer, LHighPosition - LLowPosition + 1);
  SetLength(Result, ADestinationWidth * ADestinationHeight);

  for LRow := 0 to ADestinationHeight - 1 do
  begin
    // first pass: the rows of the source that make the row, for each column that is needed
    LCluster := LMapY[LRow];
    for LSourceColumn := LLowPosition to LHighPosition do
    begin
      LAlpha := 0;
      LRed := 0;
      LGreen := 0;
      LBlue := 0;
      for LTap in LCluster do
      begin
        LPixel := ASource[LSourceColumn + LTap.Position * ASourceWidth];
        LWeight := LTap.Weight;
        Inc(LAlpha, Integer(LPixel shr 24) * LWeight);
        Inc(LRed, Integer((LPixel and $00FF0000) shr 16) * LWeight);
        Inc(LGreen, Integer((LPixel and $0000FF00) shr 8) * LWeight);
        Inc(LBlue, Integer(LPixel and $000000FF) * LWeight);
      end;
      LBuffer[LSourceColumn - LLowPosition].Alpha := LAlpha;
      LBuffer[LSourceColumn - LLowPosition].Red := LRed;
      LBuffer[LSourceColumn - LLowPosition].Green := LGreen;
      LBuffer[LSourceColumn - LLowPosition].Blue := LBlue;
    end;

    // second pass: the columns, then the sums (8.16 fixed point) are cut to a byte
    for LColumn := 0 to ADestinationWidth - 1 do
    begin
      LAlpha := 0;
      LRed := 0;
      LGreen := 0;
      LBlue := 0;
      for LTap in LMapX[LColumn] do
      begin
        LWeight := LTap.Weight;
        Inc(LAlpha, LBuffer[LTap.Position - LLowPosition].Alpha * LWeight);
        Inc(LRed, LBuffer[LTap.Position - LLowPosition].Red * LWeight);
        Inc(LGreen, LBuffer[LTap.Position - LLowPosition].Green * LWeight);
        Inc(LBlue, LBuffer[LTap.Position - LLowPosition].Blue * LWeight);
      end;
      if LAlpha > $FF0000 then
        LAlpha := $FF0000
      else if LAlpha < 0 then
        LAlpha := 0
      else
        LAlpha := LAlpha and $00FF0000;
      if LRed > $FF0000 then
        LRed := $FF0000
      else if LRed < 0 then
        LRed := 0
      else
        LRed := LRed and $00FF0000;
      if LGreen > $FF0000 then
        LGreen := $FF0000
      else if LGreen < 0 then
        LGreen := 0
      else
        LGreen := LGreen and $00FF0000;
      if LBlue > $FF0000 then
        LBlue := $FF0000
      else if LBlue < 0 then
        LBlue := 0
      else
        LBlue := LBlue and $00FF0000;
      Result[LRow * ADestinationWidth + LColumn] :=
        (Cardinal(LAlpha) shl 8) or Cardinal(LRed) or (Cardinal(LGreen) shr 8) or (Cardinal(LBlue) shr 16);
    end;
  end;
end;

end.
