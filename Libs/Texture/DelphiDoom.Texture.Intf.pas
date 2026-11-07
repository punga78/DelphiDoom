{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - contracts                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image;

type
  /// <summary>Reads the files of one image format into a TTextureImage</summary>
  ITextureDecoder = interface
    ['{4E1B7C92-6A35-4D08-B3F1-9C20D5A87E46}']
    function GetExtension: string;
    /// <summary>
    ///   Decodes the bytes of a file into AImage. When it gives false the image can be
    ///   half written: the caller drops it
    /// </summary>
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
    /// <summary>The extension that names the format in capitals, with the dot: '.BMP'</summary>
    property Extension: string read GetExtension;
  end;

  /// <summary>The decoders that the engine has, one for each extension</summary>
  ITextureFormats = interface
    ['{B90D2A6F-1E74-4C53-8A0B-37F6E1D48C95}']
    /// <summary>
    ///   The decoder for an extension. As the old GetImageFormat it takes the first of the
    ///   decoders, from the last one added, whose extension contains the text that it is
    ///   given: so '.PNG' finds the decoder of '.PNGSPRITE' when that one was added after
    ///   the one of '.PNG'. nil when there is none
    /// </summary>
    function FindDecoder(const AExtension: string): ITextureDecoder;
    /// <summary>True when an extension is exactly one of those of the decoders (not case sensitive)</summary>
    function IsKnownExtension(const AExtension: string): Boolean;
    /// <summary>The extensions in the order in which the decoders were added</summary>
    function Extensions: TArray<string>;
    /// <summary>
    ///   Decodes the bytes of a file of the format of AExtension into AImage; false when
    ///   there is no decoder for it or when the decoder fails
    /// </summary>
    function Decode(const AExtension: string; const ASource: TBytes;
      const AImage: TTextureImage): Boolean;
  end;

  /// <summary>The 256 colors that a patch or a flat is read with, as $00RRGGBB</summary>
  ITexturePaletteSource = interface
    ['{7A35F0C8-D4B1-49E6-9C72-1B8E6F03A5D7}']
    /// <summary>The colors of the palette in use now (256 of them)</summary>
    function GetColors: TTexturePixels;
  end;

  /// <summary>Gives a texture by its name: what a material needs to put an image and its alpha together</summary>
  ITextureResolver = interface
    ['{E2C48B15-93A7-4F60-B1D9-5C6A07E3F842}']
    /// <summary>The image of an external texture, or nil when there is none; the caller owns it</summary>
    function Load(const AName: string): TTextureImage;
  end;

  /// <summary>An image of a PNG file as the decoder reads it</summary>
  TTexturePngData = record
    Width: Integer;
    Height: Integer;
    /// <summary>True when the pixels are indices of the palette</summary>
    Indexed: Boolean;
    /// <summary>True for the color types that carry an alpha for each pixel (RGBA, gray with alpha)</summary>
    HasAlphaChannel: Boolean;
    /// <summary>True when some entry of the palette may be not opaque</summary>
    HasPaletteAlpha: Boolean;
    HasTransparentColor: Boolean;
    /// <summary>The color of the tRNS chunk, $00RRGGBB</summary>
    TransparentColor: Cardinal;
    OffsetX: Integer;
    OffsetY: Integer;
    /// <summary>Width * Height indices, or Width * Height pixels of 4 bytes (B, G, R, A)</summary>
    Pixels: TBytes;
    /// <summary>For an indexed image 256 entries of 4 bytes (B, G, R, A)</summary>
    Palette: TBytes;
  end;

  /// <summary>Decodes the PNG files (the engine uses the PNG library)</summary>
  ITexturePngReader = interface
    ['{91D6A3E0-5B82-4C17-A4F9-0E7B2C58D361}']
    /// <summary>False with a message when the file cannot be decoded</summary>
    function Read(const ASource: TBytes; out AData: TTexturePngData; out AMessage: string): Boolean;
  end;

  /// <summary>The colors that the PNG textures treat as transparent, besides the one of the file</summary>
  ITexturePngSettings = interface
    ['{3F8C61B4-A2D5-47E9-8B03-C1D95E720A68}']
    /// <summary>The first color, in the byte order of a Windows COLORREF ($00BBGGRR)</summary>
    function GetTransparentColor: Cardinal;
    /// <summary>The second color, in the byte order of a Windows COLORREF ($00BBGGRR)</summary>
    function GetTransparentColor2: Cardinal;
    /// <summary>Also the colors made only of 00 and FF bytes with at least two FF are transparent</summary>
    function GetAssumeCommonColors: Boolean;
  end;

  /// <summary>Turns the bytes of a JPEG file into the bytes of an uncompressed BMP file</summary>
  ITextureJpegConverter = interface
    ['{C5A07E39-4D61-4B2F-90E8-82F1B6D3A740}']
    /// <summary>A BMP file; ETextureException (or the engine stops) when the JPEG is bad</summary>
    function ToBitmap(const ASource: TBytes): TBytes;
  end;

implementation

end.
