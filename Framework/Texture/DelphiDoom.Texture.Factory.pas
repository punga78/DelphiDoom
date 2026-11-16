{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - the factory: the composition root             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Factory;

interface

uses
  DelphiDoom.Texture.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>What the decoders need from the engine</summary>
  TTextureServices = record
    /// <summary>The palette of the game, for the patches and the flats</summary>
    Palette: ITexturePaletteSource;
    /// <summary>Gives an external texture by its name, for the materials</summary>
    Resolver: ITextureResolver;
    PngReader: ITexturePngReader;
    PngSettings: ITexturePngSettings;
    JpegConverter: ITextureJpegConverter;
    Log: ILog;
  end;

  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TTextureFactory = class sealed
  public
    /// <summary>
    ///   The decoders in the order of the old T_Init: PNG, PNG sprite, JPG, JPEG, PCX, TGA,
    ///   BMP, material, patch, flat. An extension finds its decoder as GetImageFormat did
    /// </summary>
    class function CreateFormats(const AServices: TTextureServices): ITextureFormats; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Formats, DelphiDoom.Texture.Decoder.PngTexture,
  DelphiDoom.Texture.Decoder.PngSprite, DelphiDoom.Texture.Decoder.Jpeg,
  DelphiDoom.Texture.Decoder.Pcx, DelphiDoom.Texture.Decoder.Tga,
  DelphiDoom.Texture.Decoder.Bmp, DelphiDoom.Texture.Decoder.Material,
  DelphiDoom.Texture.Decoder.Patch, DelphiDoom.Texture.Decoder.Flat;

{ TTextureFactory }

class function TTextureFactory.CreateFormats(const AServices: TTextureServices): ITextureFormats;
var
  LBitmap: ITextureDecoder;
  LDecoders: TArray<ITextureDecoder>;
begin
  LBitmap := TTextureBmpDecoder.Create;
  SetLength(LDecoders, 10);
  LDecoders[0] := TTexturePngTextureDecoder.Create('.PNG', AServices.PngReader,
    AServices.PngSettings, AServices.Log);
  LDecoders[1] := TTexturePngSpriteDecoder.Create(TEXTURE_PNG_SPRITE_EXTENSION, AServices.PngReader,
    AServices.Log);
  LDecoders[2] := TTextureJpegDecoder.Create('.JPG', AServices.JpegConverter, LBitmap);
  LDecoders[3] := TTextureJpegDecoder.Create('.JPEG', AServices.JpegConverter, LBitmap);
  LDecoders[4] := TTexturePcxDecoder.Create(AServices.Log);
  LDecoders[5] := TTextureTgaDecoder.Create;
  LDecoders[6] := LBitmap;
  LDecoders[7] := TTextureMaterialDecoder.Create(AServices.Resolver);
  LDecoders[8] := TTexturePatchDecoder.Create(AServices.Palette);
  LDecoders[9] := TTextureFlatDecoder.Create(AServices.Palette);
  Result := TTextureFormats.Create(LDecoders);
end;

end.
