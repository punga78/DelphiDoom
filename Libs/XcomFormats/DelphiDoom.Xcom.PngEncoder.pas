{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - an image as a PNG file                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.PngEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf,
  DelphiDoom.Video.Intf, DelphiDoom.Png.Client;

type
  /// <summary>
  ///   The 256 colors of the palette go through the palette converter of the video library (as the screen of the
  ///   game does) and the PNG library writes the file: 8 bit RGBA, with the pixels of index 0 transparent when asked
  /// </summary>
  TXcomPngEncoder = class(TInterfacedObject, IXcomImageEncoder)
  strict private
    FConverter: IPaletteConverter;
    FPng: TPngClient;
  public
    /// <param name="AConverter">Turns the palette of 256 colors into $00RRGGBB</param>
    /// <param name="APng">The PNG library; the encoder does not own it</param>
    constructor Create(const AConverter: IPaletteConverter; const APng: TPngClient);
    function Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
  end;

implementation

uses
  DelphiDoom.Png.Intf;

{ TXcomPngEncoder }

constructor TXcomPngEncoder.Create(const AConverter: IPaletteConverter; const APng: TPngClient);
begin
  inherited Create;
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  FConverter := AConverter;
  FPng := APng;
end;

function TXcomPngEncoder.Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
var
  LPalette: TBytes;
  LGamma: array[0..255] of Byte;
  LColors: array[0..255] of Cardinal;
  LPixels: TBytes;
  LIndex: Integer;
  LColor: Cardinal;
  LPixel: Byte;
begin
  if (AImage.Width <= 0) or (AImage.Height <= 0) or (Length(AImage.Pixels) <> AImage.Width * AImage.Height) then
    raise EXcomException.CreateFmt(SXcomImageInvalid, [Length(AImage.Pixels), AImage.Width, AImage.Height]);
  if not AImage.HasPalette then
    raise EXcomException.Create(SXcomNoPalette);
  LPalette := AImage.Palette.ToRgbBytes;
  for LIndex := 0 to 255 do
    LGamma[LIndex] := Byte(LIndex);
  FConverter.Convert(@LPalette[0], @LGamma[0], @LColors[0]);
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
