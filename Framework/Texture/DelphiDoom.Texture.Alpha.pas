{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - alpha channel and transparent colors          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of the alpha methods of TTexture (t_main.pas)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Alpha;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Image;

type
  /// <summary>
  ///   The operations that decide which pixels of an image are visible. All of them work
  ///   on a 32 bit image (they convert it first); the alpha is the top byte of a pixel
  /// </summary>
  TTextureAlpha = class sealed
  public
    /// <summary>The same alpha for every pixel</summary>
    class procedure SetChannel(const AImage: TTextureImage; AValue: Byte); static;
    /// <summary>
    ///   The alpha of each pixel from the gray scale of ASource, which is scaled to the size
    ///   of the image and turned to gray (so it changes); the image keeps that it has an
    ///   external alpha
    /// </summary>
    class procedure SetChannelFromImage(const AImage, ASource: TTextureImage); static;
    /// <summary>
    ///   A pixel of the transparent colors becomes 0, any other gets the full alpha
    /// </summary>
    class procedure SetDefaultChannel(const AImage: TTextureImage); static;
    /// <summary>A black pixel becomes $FF010101, any other gets the full alpha</summary>
    class procedure RemoveTransparency(const AImage: TTextureImage); static;
    /// <summary>A pixel of the transparent colors becomes 0, the others do not change</summary>
    class procedure AdjustTransparency(const AImage: TTextureImage); static;
  end;

implementation

{ TTextureAlpha }

class procedure TTextureAlpha.SetChannel(const AImage: TTextureImage; AValue: Byte);
var
  LPixels: TBytes;
  LIndex: Integer;
begin
  AImage.ConvertTo32bit;
  LPixels := AImage.Pixels;
  for LIndex := 0 to AImage.Width * AImage.Height - 1 do
    LPixels[LIndex * 4 + 3] := AValue;
end;

class procedure TTextureAlpha.SetChannelFromImage(const AImage, ASource: TTextureImage);
var
  LPixels: TBytes;
  LGray: TBytes;
  LIndex: Integer;
begin
  AImage.ConvertTo32bit;
  ASource.ScaleTo(AImage.Width, AImage.Height);
  ASource.ConvertToGrayScale;
  LPixels := AImage.Pixels;
  LGray := ASource.Pixels;
  if (Length(LPixels) > 0) and (Length(LGray) >= AImage.Width * AImage.Height) then
    for LIndex := 0 to AImage.Width * AImage.Height - 1 do
      LPixels[LIndex * 4 + 3] := LGray[LIndex];
  AImage.ExternalAlphaPresent := True;
end;

class procedure TTextureAlpha.SetDefaultChannel(const AImage: TTextureImage);
var
  LColors: PTextureColorArray;
  LIndex: Integer;
  LColor: Cardinal;
  LSingle: Boolean;
begin
  AImage.ConvertTo32bit;
  if Length(AImage.Pixels) = 0 then
    Exit;
  LColors := PTextureColorArray(AImage.PixelsPointer);
  // all the three colors the same: one test is enough
  LSingle := (AImage.TransparentColor = AImage.TransparentColor2) and
             (AImage.TransparentColor = AImage.TransparentColor3);
  for LIndex := 0 to AImage.Width * AImage.Height - 1 do
  begin
    LColor := LColors^[LIndex];
    if LColor = AImage.TransparentColor then
      LColors^[LIndex] := 0
    else if (not LSingle) and ((LColor = AImage.TransparentColor2) or
                               (LColor = AImage.TransparentColor3)) then
      LColors^[LIndex] := 0
    else
      LColors^[LIndex] := LColor or $FF000000;
  end;
end;

class procedure TTextureAlpha.RemoveTransparency(const AImage: TTextureImage);
var
  LColors: PTextureColorArray;
  LIndex: Integer;
begin
  AImage.ConvertTo32bit;
  if Length(AImage.Pixels) = 0 then
    Exit;
  LColors := PTextureColorArray(AImage.PixelsPointer);
  for LIndex := 0 to AImage.Width * AImage.Height - 1 do
    if (LColors^[LIndex] and $FFFFFF) = 0 then
      LColors^[LIndex] := $FF010101
    else
      LColors^[LIndex] := LColors^[LIndex] or $FF000000;
end;

class procedure TTextureAlpha.AdjustTransparency(const AImage: TTextureImage);
var
  LColors: PTextureColorArray;
  LIndex: Integer;
  LColor: Cardinal;
  LSingle: Boolean;
begin
  if (AImage.TransparentColor = 0) and (AImage.TransparentColor2 = 0) and
     (AImage.TransparentColor3 = 0) then
    Exit;
  AImage.ConvertTo32bit;
  if Length(AImage.Pixels) = 0 then
    Exit;
  LColors := PTextureColorArray(AImage.PixelsPointer);
  LSingle := (AImage.TransparentColor = AImage.TransparentColor2) and
             (AImage.TransparentColor = AImage.TransparentColor3);
  for LIndex := 0 to AImage.Width * AImage.Height - 1 do
  begin
    LColor := LColors^[LIndex];
    if LColor = AImage.TransparentColor then
      LColors^[LIndex] := 0
    else if (not LSingle) and ((LColor = AImage.TransparentColor2) or
                               (LColor = AImage.TransparentColor3)) then
      LColors^[LIndex] := 0;
  end;
end;

end.
