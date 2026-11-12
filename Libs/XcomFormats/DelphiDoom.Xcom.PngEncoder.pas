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
  System.SysUtils, DelphiDoom.Png.IndexedEncoder.Intf, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   The rules of X-COM for the common encoder of Libs\Png: the palette is the one of the image and the pixels of
  ///   index 0 are transparent when asked (they keep their color). The file is 8 bit RGBA
  /// </summary>
  TXcomPngEncoder = class(TInterfacedObject, IXcomImageEncoder)
  strict private
    FEncoder: IPngIndexedEncoder;
  public
    /// <param name="AEncoder">The encoder of the pictures with a palette</param>
    constructor Create(const AEncoder: IPngIndexedEncoder);
    function Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
  end;

implementation

uses
  DelphiDoom.Png.IndexedImage;

constructor TXcomPngEncoder.Create(const AEncoder: IPngIndexedEncoder);
begin
  inherited Create;
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  FEncoder := AEncoder;
end;

function TXcomPngEncoder.Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
var
  LTransparent: Integer;
begin
  if (AImage.Width <= 0) or (AImage.Height <= 0) or (Length(AImage.Pixels) <> AImage.Width * AImage.Height) then
    raise EXcomException.CreateFmt(SXcomImageInvalid, [Length(AImage.Pixels), AImage.Width, AImage.Height]);
  if not AImage.HasPalette then
    raise EXcomException.Create(SXcomNoPalette);
  if ATransparentZero then
    LTransparent := 0
  else
    LTransparent := PNG_INDEXED_OPAQUE;
  Result := FEncoder.Encode(TIndexedImage.Wrap(AImage.Width, AImage.Height, AImage.Pixels),
    AImage.Palette.ToRgbBytes, LTransparent, ptcPalette);
end;

end.
