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
  System.SysUtils, DelphiDoom.Png.IndexedEncoder.Intf, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The rules of Greed for the common encoder of Libs\Png: the palette is the one given with the image and the
  ///   pixels of index 0 are transparent when asked (they keep their color). The file is 8 bit RGBA
  /// </summary>
  TGreedPngEncoder = class(TInterfacedObject, IGreedImageEncoder)
  strict private
    FEncoder: IPngIndexedEncoder;
  public
    /// <param name="AEncoder">The encoder of the pictures with a palette</param>
    constructor Create(const AEncoder: IPngIndexedEncoder);
    function Encode(const AImage: TGreedImage; const APalette: TBytes; ATransparentZero: Boolean): TBytes;
  end;

implementation

uses
  DelphiDoom.Png.IndexedImage;

constructor TGreedPngEncoder.Create(const AEncoder: IPngIndexedEncoder);
begin
  inherited Create;
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  FEncoder := AEncoder;
end;

function TGreedPngEncoder.Encode(const AImage: TGreedImage; const APalette: TBytes;
  ATransparentZero: Boolean): TBytes;
var
  LTransparent: Integer;
begin
  if (AImage.Width <= 0) or (AImage.Height <= 0) or (Length(AImage.Pixels) <> AImage.Width * AImage.Height) then
    raise EGreedDataException.CreateFmt(SGreedImageSize, [AImage.Width, AImage.Height, 'image']);
  if Length(APalette) < GREED_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(APalette), GREED_PALETTE_BYTES]);
  if ATransparentZero then
    LTransparent := 0
  else
    LTransparent := PNG_INDEXED_OPAQUE;
  Result := FEncoder.Encode(TIndexedImage.Wrap(AImage.Width, AImage.Height, AImage.Pixels), APalette, LTransparent,
    ptcPalette);
end;

end.
