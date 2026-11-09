{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - an image of palette indexes as a PNG file        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PngEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Video.Intf,
  DelphiDoom.Png.Client;

type
  /// <summary>
  ///   The palette goes through the palette converter of the video library (the one of the game screen) and
  ///   the PNG library writes the file: 8 bit RGBA
  /// </summary>
  TGreedPngEncoder = class(TInterfacedObject, IGreedImageEncoder)
  strict private
    FConverter: IPaletteConverter;
    FPng: TPngClient;
  public
    /// <param name="AConverter">Turns the palette of 256 colors into $00RRGGBB</param>
    /// <param name="APng">The PNG library; the encoder does not own it</param>
    constructor Create(const AConverter: IPaletteConverter; const APng: TPngClient);
    function Encode(const AImage: TGreedImage; const APalette: TBytes; ATransparentZero: Boolean): TBytes;
  end;

implementation

uses
  DelphiDoom.Png.Intf;

{ TGreedPngEncoder }

constructor TGreedPngEncoder.Create(const AConverter: IPaletteConverter; const APng: TPngClient);
begin
  inherited Create;
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  FConverter := AConverter;
  FPng := APng;
end;

function TGreedPngEncoder.Encode(const AImage: TGreedImage; const APalette: TBytes;
  ATransparentZero: Boolean): TBytes;
var
  LGamma: array[0..255] of Byte;
  LColors: array[0..255] of Cardinal;
  LPixels: TBytes;
  LIndex: Integer;
  LPixel: Byte;
  LColor: Cardinal;
begin
  if (AImage.Width <= 0) or (AImage.Height <= 0) or (Length(AImage.Pixels) <> AImage.Width * AImage.Height) then
    raise EGreedDataException.CreateFmt(SGreedImageSize, [AImage.Width, AImage.Height, 'image']);
  if Length(APalette) < GREED_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(APalette), GREED_PALETTE_BYTES]);
  for LIndex := 0 to 255 do
    LGamma[LIndex] := Byte(LIndex);
  FConverter.Convert(@APalette[0], @LGamma[0], @LColors[0]);
  SetLength(LPixels, Length(AImage.Pixels) * 4);
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    LPixel := AImage.Pixels[LIndex];
    LColor := LColors[LPixel];
    LPixels[LIndex * 4] := Byte(LColor);
    LPixels[LIndex * 4 + 1] := Byte(LColor shr 8);
    LPixels[LIndex * 4 + 2] := Byte(LColor shr 16);
    if ATransparentZero and (LPixel = 0) then
      LPixels[LIndex * 4 + 3] := 0
    else
      LPixels[LIndex * 4 + 3] := $FF;
  end;
  Result := FPng.Encode(LPixels, AImage.Width, AImage.Height, DDPNG_FORMAT_BGRA);
end;

end.
