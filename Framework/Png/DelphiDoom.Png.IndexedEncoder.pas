{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG library - from a picture with a palette to a PNG file        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.IndexedEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Png.Client, DelphiDoom.Png.IndexedImage, DelphiDoom.Png.IndexedEncoder.Intf;

type
  /// <summary>
  ///   IPngIndexedEncoder over the PNG library: every pixel becomes B, G, R, A through the palette and the client
  ///   writes the file (8 bit RGBA, the default compression level). It took the place of the three encoders of
  ///   the Keen, Greed and OpenXcom libraries, and writes the same bytes they wrote
  /// </summary>
  TPngIndexedEncoder = class(TInterfacedObject, IPngIndexedEncoder)
  strict private
    FPng: TPngClient;
  public
    /// <param name="APng">The PNG library; the encoder does not own it</param>
    constructor Create(const APng: TPngClient);
    function Encode(const AImage: TIndexedImage; const APalette: TBytes;
      ATransparentIndex: Integer = PNG_INDEXED_OPAQUE;
      ATransparentColor: TPngTransparentColor = ptcPalette): TBytes;
  end;

implementation

uses
  DelphiDoom.Png.Intf;

const
  SIndexedImageSize = 'A picture of %d x %d pixels cannot have %d bytes';
  SIndexedPaletteShort = 'The palette has %d bytes, it needs %d';
  BYTES_PER_PIXEL = 4;
  ALPHA_OPAQUE = $FF;

constructor TPngIndexedEncoder.Create(const APng: TPngClient);
begin
  inherited Create;
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  FPng := APng;
end;

function TPngIndexedEncoder.Encode(const AImage: TIndexedImage; const APalette: TBytes;
  ATransparentIndex: Integer; ATransparentColor: TPngTransparentColor): TBytes;
var
  LPixels: TBytes;
  LIndex: Integer;
  LTarget: Integer;
  LColor: Integer;
  LPixel: Byte;
begin
  if not AImage.IsValid then
    raise EPngIndexedImageException.CreateFmt(SIndexedImageSize, [AImage.Width, AImage.Height,
      Length(AImage.Pixels)]);
  if Length(APalette) < PNG_INDEXED_PALETTE_BYTES then
    raise EPngIndexedImageException.CreateFmt(SIndexedPaletteShort, [Length(APalette),
      PNG_INDEXED_PALETTE_BYTES]);
  SetLength(LPixels, Length(AImage.Pixels) * BYTES_PER_PIXEL);
  LTarget := 0;
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    LPixel := AImage.Pixels[LIndex];
    if (LPixel = ATransparentIndex) and (ATransparentColor = ptcBlack) then
    begin
      LPixels[LTarget] := 0;
      LPixels[LTarget + 1] := 0;
      LPixels[LTarget + 2] := 0;
      LPixels[LTarget + 3] := 0;
    end
    else
    begin
      // the palette is R, G, B and the PNG library is given B, G, R, A
      LColor := LPixel * 3;
      LPixels[LTarget] := APalette[LColor + 2];
      LPixels[LTarget + 1] := APalette[LColor + 1];
      LPixels[LTarget + 2] := APalette[LColor];
      if LPixel = ATransparentIndex then
        LPixels[LTarget + 3] := 0
      else
        LPixels[LTarget + 3] := ALPHA_OPAQUE;
    end;
    Inc(LTarget, BYTES_PER_PIXEL);
  end;
  Result := FPng.Encode(LPixels, AImage.Width, AImage.Height, DDPNG_FORMAT_BGRA);
end;

end.
