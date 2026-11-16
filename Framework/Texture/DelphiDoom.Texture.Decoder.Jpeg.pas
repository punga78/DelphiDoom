{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of JPEG files                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of TJPGTextureManager (t_jpeg.pas)                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Jpeg;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   A JPEG file ('.JPG' and '.JPEG'): the converter turns it into a BMP file, the BMP decoder
  ///   reads it and the image is flipped horizontally
  /// </summary>
  TTextureJpegDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    FExtension: string;
    FConverter: ITextureJpegConverter;
    FBitmapDecoder: ITextureDecoder;
    function GetExtension: string;
  public
    constructor Create(const AExtension: string; const AConverter: ITextureJpegConverter;
      const ABitmapDecoder: ITextureDecoder);
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

implementation

{ TTextureJpegDecoder }

constructor TTextureJpegDecoder.Create(const AExtension: string;
  const AConverter: ITextureJpegConverter; const ABitmapDecoder: ITextureDecoder);
begin
  inherited Create;
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  if not Assigned(ABitmapDecoder) then
    raise EArgumentNilException.Create('ABitmapDecoder');
  FExtension := AExtension;
  FConverter := AConverter;
  FBitmapDecoder := ABitmapDecoder;
end;

function TTextureJpegDecoder.GetExtension: string;
begin
  Result := FExtension;
end;

function TTextureJpegDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
begin
  Result := FBitmapDecoder.Decode(FConverter.ToBitmap(ASource), AImage);
  if Result then
    AImage.Mirror;
end;

end.
