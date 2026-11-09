{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - an image of EGA colors as a PNG file              }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.PngEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Video.Intf,
  DelphiDoom.Png.Client;

type
  /// <summary>
  ///   The 16 colors of the EGA go through the palette converter of the video library and the PNG library writes
  ///   the file: 8 bit RGBA, with KEEN_PIXEL_TRANSPARENT as a pixel that is not drawn (alpha 0)
  /// </summary>
  TKeenPngEncoder = class(TInterfacedObject, IKeenImageEncoder)
  strict private
    FConverter: IPaletteConverter;
    FPng: TPngClient;
  public
    /// <param name="AConverter">Turns the palette of 256 colors into $00RRGGBB</param>
    /// <param name="APng">The PNG library; the encoder does not own it</param>
    constructor Create(const AConverter: IPaletteConverter; const APng: TPngClient);
    function Encode(const AImage: TKeenChunkyImage): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.EgaPalette, DelphiDoom.Png.Intf;

{ TKeenPngEncoder }

constructor TKeenPngEncoder.Create(const AConverter: IPaletteConverter; const APng: TPngClient);
begin
  inherited Create;
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  FConverter := AConverter;
  FPng := APng;
end;

function TKeenPngEncoder.Encode(const AImage: TKeenChunkyImage): TBytes;
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
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AImage.Width, AImage.Height]);
  LPalette := TKeenEgaPalette.GamePalette;
  for LIndex := 0 to 255 do
    LGamma[LIndex] := Byte(LIndex);
  FConverter.Convert(@LPalette[0], @LGamma[0], @LColors[0]);
  SetLength(LPixels, Length(AImage.Pixels) * 4);
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    LPixel := AImage.Pixels[LIndex];
    if LPixel = KEEN_PIXEL_TRANSPARENT then
    begin
      LPixels[LIndex * 4] := 0;
      LPixels[LIndex * 4 + 1] := 0;
      LPixels[LIndex * 4 + 2] := 0;
      LPixels[LIndex * 4 + 3] := 0;
    end
    else
    begin
      if LPixel >= KEEN_EGA_COLORS then
        raise EKeenException.CreateFmt(SKeenColorInvalid, [LPixel]);
      LColor := LColors[LPixel];
      LPixels[LIndex * 4] := Byte(LColor);
      LPixels[LIndex * 4 + 1] := Byte(LColor shr 8);
      LPixels[LIndex * 4 + 2] := Byte(LColor shr 16);
      LPixels[LIndex * 4 + 3] := $FF;
    end;
  end;
  Result := FPng.Encode(LPixels, AImage.Width, AImage.Height, DDPNG_FORMAT_BGRA);
end;

end.
