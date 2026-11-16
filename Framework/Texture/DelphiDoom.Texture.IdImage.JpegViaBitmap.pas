{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture library - JPEG through the converter                    }
{                                                                              }
{  Port of renderer\Image_files.cpp of the Doom 3 GPL Source Code (id          }
{  Software). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.}
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.IdImage.JpegViaBitmap;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image, DelphiDoom.Texture.Intf, DelphiDoom.Texture.IdImage.Intf;

type
  /// <summary>
  ///   LoadJPG made of the JPEG converter of the engine (<c>ITextureJpegConverter</c>: the bytes of a JPEG file
  ///   become the bytes of a BMP file) and the BMP reader of Doom 3 with the rows padded as a BMP has them. The
  ///   original calls libjpeg directly; the pixels are the ones of the decoder behind the converter. Not
  ///   ported: the 4 bytes pixel of a CMYK JPEG. A JPEG the converter refuses (ETextureException) answers False.
  /// </summary>
  TIdImageJpegViaBitmap = class(TInterfacedObject, IIdImageJpegDecoder)
  strict private
    FConverter: ITextureJpegConverter;
  public
    constructor Create(const AConverter: ITextureJpegConverter);
    function Decode(const ABytes: TBytes; out AImage: TImagingRgbaImage): Boolean;
  end;

implementation

uses
  DelphiDoom.Texture.IdImage.Bmp, DelphiDoom.Texture.Types;

{ TIdImageJpegViaBitmap }

constructor TIdImageJpegViaBitmap.Create(const AConverter: ITextureJpegConverter);
begin
  inherited Create;
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  FConverter := AConverter;
end;

function TIdImageJpegViaBitmap.Decode(const ABytes: TBytes; out AImage: TImagingRgbaImage): Boolean;
begin
  AImage := Default(TImagingRgbaImage);
  try
    AImage := TIdBmpReader.Read(FConverter.ToBitmap(ABytes), 'jpeg', True);
    Result := True;
  except
    on ETextureException do
      Result := False;
  end;
end;

end.