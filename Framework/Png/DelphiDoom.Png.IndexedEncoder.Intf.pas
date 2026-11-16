{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG library - from a picture with a palette to a PNG file: the   }
{  contract                                                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.IndexedEncoder.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Png.IndexedImage;

const
  /// <summary>The bytes of a palette: 256 colors of R, G, B, 8 bit each</summary>
  PNG_INDEXED_PALETTE_BYTES = 768;
  /// <summary>No pixel is transparent</summary>
  PNG_INDEXED_OPAQUE = -1;

type
  /// <summary>What the PNG file keeps of a pixel that is not drawn</summary>
  TPngTransparentColor = (
    /// <summary>The color the palette has at that index, with alpha 0</summary>
    ptcPalette,
    /// <summary>Black with alpha 0: the index is a marker and not a color of the palette</summary>
    ptcBlack);

  /// <summary>
  ///   The one encoder of the pictures of the games outside the engine of Doom: 8 bit pixels and a palette become
  ///   a PNG file of 8 bit RGBA
  /// </summary>
  IPngIndexedEncoder = interface
    ['{E5B0473A-91C6-4D2F-8A7E-3B6D0C19F584}']
    /// <summary>
    ///   The PNG file of the picture. APalette has at least PNG_INDEXED_PALETTE_BYTES bytes (R, G, B of 256 colors).
    ///   The pixels of index ATransparentIndex get alpha 0 (PNG_INDEXED_OPAQUE: none) and the color
    ///   ATransparentColor says. Raises EPngIndexedImageException when the picture or the palette is not whole
    /// </summary>
    function Encode(const AImage: TIndexedImage; const APalette: TBytes;
      ATransparentIndex: Integer = PNG_INDEXED_OPAQUE;
      ATransparentColor: TPngTransparentColor = ptcPalette): TBytes;
  end;

  /// <summary>A picture whose pixels are not Width * Height, or a palette that is too short</summary>
  EPngIndexedImageException = class(Exception);

implementation

end.
