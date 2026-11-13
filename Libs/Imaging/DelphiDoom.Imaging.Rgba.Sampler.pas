{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - TImagingRgbaSampler, the image processing    }
{  of idTech 4 on images of 4 bytes per pixel                                  }
{                                                                              }
{  Port of renderer\Image_process.cpp (id Software, Doom 3, GPL v3):           }
{  R_ResampleTexture, R_Dropsample, R_MipMap, R_SetBorderTexels,               }
{  R_BlendOverTexture, R_HorizontalFlip, R_VerticalFlip, R_RotatePic.          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.Rgba.Sampler;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Rgba.Image;

const
  /// <summary>MAX_DIMENSION of Image_process.cpp: R_ResampleTexture never gives a bigger side</summary>
  IMAGING_RESAMPLE_MAX_DIMENSION = 4096;

  SMipMapSize = 'R_MipMap called with size %d, %d';
  SRotateNotSquare = 'The image to rotate must be square';

type
  /// <summary>
  ///   Resampling, mip maps, flips and blends of an RGBA image. Functions that C++ gives back as
  ///   a new buffer give a new image; the ones that work in place take the image as var
  /// </summary>
  TImagingRgbaSampler = class sealed
  strict private
    class procedure SetBorderTexels(var AImage: TImagingRgbaImage; const ABorder: array of Byte); static;
  public
    /// <summary>
    ///   R_ResampleTexture: averages four samples of the source for each pixel (a quartering
    ///   filter, good down to half the size). Sides above 4096 are cut to 4096
    /// </summary>
    class function Resample(const ASource: TImagingRgbaImage; const AWidth, AHeight: Integer): TImagingRgbaImage; static;
    /// <summary>R_Dropsample: the nearest pixel, for normal maps and the like that must not be filtered</summary>
    class function Dropsample(const ASource: TImagingRgbaImage; const AWidth, AHeight: Integer): TImagingRgbaImage; static;
    /// <summary>
    ///   R_MipMap: half the size (never below 1), each pixel the mean of 2x2; with
    ///   APreserveBorder the first texel of the source is written around the result.
    ///   EImagingException for a 1x1 source (the original called common->FatalError)
    /// </summary>
    class function MipMap(const ASource: TImagingRgbaImage; const APreserveBorder: Boolean): TImagingRgbaImage; static;
    /// <summary>R_BlendOverTexture: the colour ABlend (R, G, B, A) over every pixel, alpha of the pixels untouched</summary>
    class procedure BlendOver(var AImage: TImagingRgbaImage; const ABlend: array of Byte); static;
    /// <summary>R_HorizontalFlip</summary>
    class procedure HorizontalFlip(var AImage: TImagingRgbaImage); static;
    /// <summary>R_VerticalFlip</summary>
    class procedure VerticalFlip(var AImage: TImagingRgbaImage); static;
    /// <summary>R_RotatePic: transposes a square image</summary>
    class procedure RotatePic(var AImage: TImagingRgbaImage); static;
  end;

implementation

{ TImagingRgbaSampler }

class function TImagingRgbaSampler.Resample(const ASource: TImagingRgbaImage; const AWidth,
  AHeight: Integer): TImagingRgbaImage;
var
  LOutWidth, LOutHeight: Integer;
  LFracStep, LFrac: Cardinal;
  LP1, LP2: TArray<Cardinal>;
  LI, LJ, LChannel: Integer;
  LRow1, LRow2, LOut: Integer;
  LSingle: Single;
  LA, LB, LC, LD: Integer;
begin
  LOutWidth := AWidth;
  LOutHeight := AHeight;
  if LOutWidth > IMAGING_RESAMPLE_MAX_DIMENSION then
    LOutWidth := IMAGING_RESAMPLE_MAX_DIMENSION;
  if LOutHeight > IMAGING_RESAMPLE_MAX_DIMENSION then
    LOutHeight := IMAGING_RESAMPLE_MAX_DIMENSION;
  Result := TImagingRgbaImage.Create(LOutWidth, LOutHeight);

  LFracStep := Cardinal(ASource.Width * $10000 div LOutWidth);
  SetLength(LP1, LOutWidth);
  SetLength(LP2, LOutWidth);
  LFrac := LFracStep shr 2;
  for LI := 0 to LOutWidth - 1 do
  begin
    LP1[LI] := 4 * (LFrac shr 16);
    Inc(LFrac, LFracStep);
  end;
  LFrac := 3 * (LFracStep shr 2);
  for LI := 0 to LOutWidth - 1 do
  begin
    LP2[LI] := 4 * (LFrac shr 16);
    Inc(LFrac, LFracStep);
  end;

  LOut := 0;
  for LI := 0 to LOutHeight - 1 do
  begin
    // (int)((i + 0.25f) * inheight / outheight) with every step rounded to a float
    LSingle := LI + 0.25;
    LSingle := LSingle * ASource.Height;
    LSingle := LSingle / LOutHeight;
    LRow1 := 4 * ASource.Width * Trunc(LSingle);
    LSingle := LI + 0.75;
    LSingle := LSingle * ASource.Height;
    LSingle := LSingle / LOutHeight;
    LRow2 := 4 * ASource.Width * Trunc(LSingle);
    for LJ := 0 to LOutWidth - 1 do
    begin
      for LChannel := 0 to 3 do
      begin
        LA := ASource.Pixels[LRow1 + Integer(LP1[LJ]) + LChannel];
        LB := ASource.Pixels[LRow1 + Integer(LP2[LJ]) + LChannel];
        LC := ASource.Pixels[LRow2 + Integer(LP1[LJ]) + LChannel];
        LD := ASource.Pixels[LRow2 + Integer(LP2[LJ]) + LChannel];
        Result.Pixels[LOut + LChannel] := Byte((LA + LB + LC + LD) shr 2);
      end;
      Inc(LOut, 4);
    end;
  end;
end;

class function TImagingRgbaSampler.Dropsample(const ASource: TImagingRgbaImage; const AWidth,
  AHeight: Integer): TImagingRgbaImage;
var
  LI, LJ, LK, LRow, LOut: Integer;
begin
  Result := TImagingRgbaImage.Create(AWidth, AHeight);
  LOut := 0;
  for LI := 0 to AHeight - 1 do
  begin
    LRow := 4 * ASource.Width * Trunc((LI + 0.25) * ASource.Height / AHeight);
    for LJ := 0 to AWidth - 1 do
    begin
      LK := LJ * ASource.Width div AWidth;
      Move(ASource.Pixels[LRow + LK * 4], Result.Pixels[LOut], 4);
      Inc(LOut, 4);
    end;
  end;
end;

class procedure TImagingRgbaSampler.SetBorderTexels(var AImage: TImagingRgbaImage;
  const ABorder: array of Byte);
var
  LI: Integer;
begin
  for LI := 0 to AImage.Height - 1 do
  begin
    Move(ABorder[0], AImage.Pixels[LI * AImage.Width * 4], 4);
    Move(ABorder[0], AImage.Pixels[LI * AImage.Width * 4 + (AImage.Width - 1) * 4], 4);
  end;
  for LI := 0 to AImage.Width - 1 do
  begin
    Move(ABorder[0], AImage.Pixels[LI * 4], 4);
    Move(ABorder[0], AImage.Pixels[AImage.Width * 4 * (AImage.Height - 1) + LI * 4], 4);
  end;
end;

class function TImagingRgbaSampler.MipMap(const ASource: TImagingRgbaImage;
  const APreserveBorder: Boolean): TImagingRgbaImage;
var
  LBorder: array[0..3] of Byte;
  LRow, LNewWidth, LNewHeight, LWidth, LHeight: Integer;
  LI, LJ, LIn, LOut, LChannel: Integer;
begin
  if (ASource.Width < 1) or (ASource.Height < 1) or (ASource.Width + ASource.Height = 2) then
    raise EImagingException.CreateFmt(SMipMapSize, [ASource.Width, ASource.Height]);
  Move(ASource.Pixels[0], LBorder[0], 4);
  LRow := ASource.Width * 4;
  LNewWidth := ASource.Width shr 1;
  LNewHeight := ASource.Height shr 1;
  if LNewWidth = 0 then
    LNewWidth := 1;
  if LNewHeight = 0 then
    LNewHeight := 1;
  Result := TImagingRgbaImage.Create(LNewWidth, LNewHeight);
  LWidth := ASource.Width shr 1;
  LHeight := ASource.Height shr 1;
  LIn := 0;
  LOut := 0;
  if (LWidth = 0) or (LHeight = 0) then
  begin
    // one dimension is 1: a line
    Inc(LWidth, LHeight);
    for LI := 0 to LWidth - 1 do
    begin
      if APreserveBorder then
        Move(LBorder[0], Result.Pixels[LOut], 4)
      else
        for LChannel := 0 to 3 do
          Result.Pixels[LOut + LChannel] :=
            Byte((ASource.Pixels[LIn + LChannel] + ASource.Pixels[LIn + 4 + LChannel]) shr 1);
      Inc(LOut, 4);
      Inc(LIn, 8);
    end;
    Exit;
  end;
  for LI := 0 to LHeight - 1 do
  begin
    for LJ := 0 to LWidth - 1 do
    begin
      for LChannel := 0 to 3 do
        Result.Pixels[LOut + LChannel] := Byte((ASource.Pixels[LIn + LChannel]
          + ASource.Pixels[LIn + 4 + LChannel] + ASource.Pixels[LIn + LRow + LChannel]
          + ASource.Pixels[LIn + LRow + 4 + LChannel]) shr 2);
      Inc(LOut, 4);
      Inc(LIn, 8);
    end;
    Inc(LIn, LRow);
  end;
  // the C++ passes width and height of the half-size source (the result is NewWidth x NewHeight)
  if APreserveBorder then
    SetBorderTexels(Result, LBorder);
end;

class procedure TImagingRgbaSampler.BlendOver(var AImage: TImagingRgbaImage;
  const ABlend: array of Byte);
var
  LInverseAlpha: Integer;
  LPremult: array[0..2] of Integer;
  LI, LChannel: Integer;
begin
  LInverseAlpha := 255 - ABlend[3];
  for LChannel := 0 to 2 do
    LPremult[LChannel] := ABlend[LChannel] * ABlend[3];
  for LI := 0 to AImage.Width * AImage.Height - 1 do
    for LChannel := 0 to 2 do
      AImage.Pixels[LI * 4 + LChannel] :=
        Byte((AImage.Pixels[LI * 4 + LChannel] * LInverseAlpha + LPremult[LChannel]) shr 9);
end;

class procedure TImagingRgbaSampler.HorizontalFlip(var AImage: TImagingRgbaImage);
var
  LI, LJ: Integer;
  LTemp: Cardinal;
  LBase: PCardinal;
begin
  for LI := 0 to AImage.Height - 1 do
    for LJ := 0 to AImage.Width div 2 - 1 do
    begin
      LBase := PCardinal(@AImage.Pixels[LI * AImage.Width * 4]);
      LTemp := PCardinal(PByte(LBase) + LJ * 4)^;
      PCardinal(PByte(LBase) + LJ * 4)^ := PCardinal(PByte(LBase) + (AImage.Width - 1 - LJ) * 4)^;
      PCardinal(PByte(LBase) + (AImage.Width - 1 - LJ) * 4)^ := LTemp;
    end;
end;

class procedure TImagingRgbaSampler.VerticalFlip(var AImage: TImagingRgbaImage);
var
  LI, LJ: Integer;
  LTemp: Cardinal;
  LPixelA, LPixelB: PCardinal;
begin
  for LI := 0 to AImage.Width - 1 do
    for LJ := 0 to AImage.Height div 2 - 1 do
    begin
      LPixelA := PCardinal(@AImage.Pixels[(LJ * AImage.Width + LI) * 4]);
      LPixelB := PCardinal(@AImage.Pixels[((AImage.Height - 1 - LJ) * AImage.Width + LI) * 4]);
      LTemp := LPixelA^;
      LPixelA^ := LPixelB^;
      LPixelB^ := LTemp;
    end;
end;

class procedure TImagingRgbaSampler.RotatePic(var AImage: TImagingRgbaImage);
var
  LCopy: TBytes;
  LI, LJ: Integer;
begin
  if AImage.Width <> AImage.Height then
    raise EImagingException.Create(SRotateNotSquare);
  LCopy := Copy(AImage.Pixels);
  for LI := 0 to AImage.Width - 1 do
    for LJ := 0 to AImage.Width - 1 do
      Move(LCopy[(LJ * AImage.Width + LI) * 4], AImage.Pixels[(LI * AImage.Width + LJ) * 4], 4);
end;

end.
