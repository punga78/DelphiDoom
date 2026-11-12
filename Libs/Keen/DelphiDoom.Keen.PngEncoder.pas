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
  System.SysUtils, DelphiDoom.Png.IndexedEncoder.Intf, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The rules of Keen for the common encoder of Libs\Png: the 16 colors of the EGA are the palette, and
  ///   KEEN_PIXEL_TRANSPARENT is a pixel that is not drawn (black with alpha 0). The file is 8 bit RGBA
  /// </summary>
  TKeenPngEncoder = class(TInterfacedObject, IKeenImageEncoder)
  strict private
    FEncoder: IPngIndexedEncoder;
  public
    /// <param name="AEncoder">The encoder of the pictures with a palette</param>
    constructor Create(const AEncoder: IPngIndexedEncoder);
    function Encode(const AImage: TKeenChunkyImage): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.EgaPalette;

constructor TKeenPngEncoder.Create(const AEncoder: IPngIndexedEncoder);
begin
  inherited Create;
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  FEncoder := AEncoder;
end;

function TKeenPngEncoder.Encode(const AImage: TKeenChunkyImage): TBytes;
var
  LIndex: Integer;
  LPixel: Byte;
begin
  if not AImage.IsValid then
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AImage.Width, AImage.Height]);
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    LPixel := AImage.Pixels[LIndex];
    if (LPixel <> KEEN_PIXEL_TRANSPARENT) and (LPixel >= KEEN_EGA_COLORS) then
      raise EKeenException.CreateFmt(SKeenColorInvalid, [LPixel]);
  end;
  Result := FEncoder.Encode(AImage, TKeenEgaPalette.GamePalette, KEEN_PIXEL_TRANSPARENT, ptcBlack);
end;

end.
