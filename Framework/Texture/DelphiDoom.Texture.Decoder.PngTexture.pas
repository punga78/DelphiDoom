{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of PNG files as textures              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of TPNGTextureManager (t_png.pas)                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.PngTexture;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.PngBase, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   A PNG file as a texture ('.PNG'). A pixel is transparent (0) when it has the color of
  ///   the tRNS chunk, one of the two colors of the settings or, when the settings say so,
  ///   a color of 00 and FF bytes with at least two FF. An image with a palette stays
  ///   as it is (indices and palette with the transparent entries at 0), the others
  ///   are 32 bit. The offsets of the file (grAb) are kept
  /// </summary>
  TTexturePngTextureDecoder = class(TTexturePngDecoderBase)
  strict private
    FSettings: ITexturePngSettings;
  protected
    function Apply(const AData: TTexturePngData; const AImage: TTextureImage): Boolean; override;
  public
    constructor Create(const AExtension: string; const AReader: ITexturePngReader;
      const ASettings: ITexturePngSettings; const ALog: ILog);
  end;

implementation

{ TTexturePngTextureDecoder }

constructor TTexturePngTextureDecoder.Create(const AExtension: string;
  const AReader: ITexturePngReader; const ASettings: ITexturePngSettings; const ALog: ILog);
begin
  inherited Create(AExtension, AReader, ALog);
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  FSettings := ASettings;
end;

function TTexturePngTextureDecoder.Apply(const AData: TTexturePngData;
  const AImage: TTextureImage): Boolean;
var
  LColor, LColor2, LColor3: Cardinal;
  LCommon: Boolean;
  LPalette: TTexturePixels;
  LIndex: Integer;
  LX, LY: Integer;
  LPixel: Cardinal;
  LPixels: PTextureColorArray;

  function IsTransparent(AColor: Cardinal): Boolean;
  begin
    Result := (AColor = LColor) or (AColor = LColor2) or (AColor = LColor3) or
              (LCommon and IsCommonTransparentColor(AColor));
  end;

begin
  AImage.TransparentColor := TransparentColorOfFile(AData);
  AImage.TransparentColor2 := SwapRedBlue(FSettings.GetTransparentColor);
  AImage.TransparentColor3 := SwapRedBlue(FSettings.GetTransparentColor2);
  AImage.ScaleTo(AData.Width, AData.Height);
  AImage.LeftOffset := AData.OffsetX;
  AImage.TopOffset := AData.OffsetY;

  LColor := AImage.TransparentColor;
  LColor2 := AImage.TransparentColor2;
  LColor3 := AImage.TransparentColor3;
  LCommon := FSettings.GetAssumeCommonColors;
  if AData.Indexed then
  begin
    AImage.SetBytesPerPixel(1);
    SetLength(LPalette, TEXTURE_PALETTE_SIZE);
    for LIndex := 0 to TEXTURE_PALETTE_SIZE - 1 do
    begin
      LPixel := PaletteColorAt(AData, LIndex);
      if IsTransparent(LPixel) then
        LPalette[LIndex] := 0
      else
        LPalette[LIndex] := LPixel;
    end;
    AImage.SetPalette(LPalette);
    if Length(AImage.Pixels) < AData.Width * AData.Height then
      Exit(False);
    Move(AData.Pixels[0], AImage.Pixels[0], AData.Width * AData.Height);
  end
  else
  begin
    AImage.SetBytesPerPixel(4);
    if Length(AImage.Pixels) < AData.Width * AData.Height * 4 then
      Exit(False);
    LPixels := PTextureColorArray(AImage.PixelsPointer);
    for LY := 0 to AData.Height - 1 do
      for LX := 0 to AData.Width - 1 do
      begin
        LPixel := PixelAt(AData, LX, LY);
        if IsTransparent(LPixel) then
          LPixel := 0;
        LPixels^[LY * AData.Width + LX] := LPixel;
      end;
    AImage.TransparentColor := 0;
    AImage.TransparentColor2 := 0;
    AImage.TransparentColor3 := 0;
  end;
  Result := True;
end;

end.
