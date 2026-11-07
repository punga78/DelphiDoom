{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of PNG files as sprites               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of TPNGSpriteTextureManager (t_png.pas)                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.PngSprite;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.PngBase;

type
  /// <summary>
  ///   A PNG file as a sprite ('.PNGSPRITE'). The transparent pixels are 0 and the black ones
  ///   (which would be taken for transparent) become a near black, $010100 or $000100 when
  ///   the transparent color of the file is $010100. The pixels have their alpha channel
  ///   when the file has one; an image with a palette keeps it unless the palette has an alpha,
  ///   then it becomes 32 bit. The offsets of the file (grAb) are kept
  /// </summary>
  TTexturePngSpriteDecoder = class(TTexturePngDecoderBase)
  protected
    function Apply(const AData: TTexturePngData; const AImage: TTextureImage): Boolean; override;
  end;

implementation

{ TTexturePngSpriteDecoder }

function TTexturePngSpriteDecoder.Apply(const AData: TTexturePngData;
  const AImage: TTextureImage): Boolean;
var
  LTransparent: Cardinal;
  LNearBlack: Cardinal;
  LPalette: TTexturePixels;
  LPixels: PTextureColorArray;
  LIndex: Integer;
  LX, LY: Integer;
  LPixel: Cardinal;
  LCount: Integer;
begin
  LTransparent := TransparentColorOfFile(AData);
  AImage.TransparentColor := 0;
  AImage.TransparentColor2 := 0;
  AImage.TransparentColor3 := 0;
  AImage.ScaleTo(AData.Width, AData.Height);
  AImage.LeftOffset := AData.OffsetX;
  AImage.TopOffset := AData.OffsetY;

  if LTransparent = $010100 then
    LNearBlack := $000100
  else
    LNearBlack := $010100;
  LCount := AData.Width * AData.Height;
  SetLength(LPalette, TEXTURE_PALETTE_SIZE);

  if AData.Indexed then
  begin
    if AData.HasPaletteAlpha then
    begin
      // the entries with a zero alpha are transparent, so a 32 bit image is needed
      for LIndex := 0 to TEXTURE_PALETTE_SIZE - 1 do
      begin
        LPixel := PaletteColorAt(AData, LIndex);
        if PaletteAlphaAt(AData, LIndex) = 0 then
          LPalette[LIndex] := 0
        else if (LPixel = LTransparent) or (LPixel = 0) then
          LPalette[LIndex] := 0
        else
          LPalette[LIndex] := LPixel;
      end;
      AImage.SetBytesPerPixel(4);
      if Length(AImage.Pixels) < LCount * 4 then
        Exit(False);
      LPixels := PTextureColorArray(AImage.PixelsPointer);
      for LIndex := 0 to LCount - 1 do
      begin
        if PaletteAlphaAt(AData, AData.Pixels[LIndex]) = 0 then
          LPixels^[LIndex] := 0
        else
        begin
          LPixels^[LIndex] := LPalette[AData.Pixels[LIndex]];
          if (LPixels^[LIndex] = LTransparent) or ((LPixels^[LIndex] and $FFFFFF) = 0) then
            LPixels^[LIndex] := LNearBlack;
        end;
      end;
    end
    else
    begin
      AImage.SetBytesPerPixel(1);
      for LIndex := 0 to TEXTURE_PALETTE_SIZE - 1 do
      begin
        LPixel := PaletteColorAt(AData, LIndex);
        if LPixel = LTransparent then
          LPalette[LIndex] := 0
        else if LPixel = 0 then
          LPalette[LIndex] := LNearBlack
        else
          LPalette[LIndex] := LPixel;
      end;
      AImage.SetPalette(LPalette);
      if Length(AImage.Pixels) < LCount then
        Exit(False);
      Move(AData.Pixels[0], AImage.Pixels[0], LCount);
    end;
  end
  else
  begin
    AImage.SetBytesPerPixel(4);
    if Length(AImage.Pixels) < LCount * 4 then
      Exit(False);
    LPixels := PTextureColorArray(AImage.PixelsPointer);
    // only the images with an alpha channel have an alpha for each pixel: the others, also
    // those with a color in the tRNS chunk, are tested against that color
    if AData.HasAlphaChannel then
    begin
      for LY := 0 to AData.Height - 1 do
        for LX := 0 to AData.Width - 1 do
        begin
          if (RawPixelAt(AData, LX, LY) shr 24) = 0 then
            LPixel := 0
          else
          begin
            LPixel := PixelAt(AData, LX, LY);
            if (LPixel = LTransparent) or ((LPixel and $FFFFFF) = 0) then
              LPixel := LNearBlack;
          end;
          LPixels^[LY * AData.Width + LX] := LPixel;
        end;
    end
    else
    begin
      for LY := 0 to AData.Height - 1 do
        for LX := 0 to AData.Width - 1 do
        begin
          LPixel := PixelAt(AData, LX, LY);
          if LPixel <> LTransparent then
            if (LPixel and $FFFFFF) = 0 then
              LPixel := LNearBlack;
          LPixels^[LY * AData.Width + LX] := LPixel;
        end;
    end;
  end;
  Result := True;
end;

end.
