{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG library - the contract of the encoder of PNG files that      }
{  keep the palette                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.PaletteEncoder.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Png.IndexedImage;

const
  /// <summary>No index of the palette is transparent</summary>
  PNG_PALETTE_OPAQUE = -1;

type
  /// <summary>
  ///   Writes a picture of 8 bit pixels as a PNG file that is still indexed (color type 3, with its PLTE): who
  ///   reads it gets the same indexes back. IPngIndexedEncoder writes RGBA instead, and the indexes are lost
  /// </summary>
  IPngPaletteEncoder = interface
    ['{7A3C5E90-1F4B-4D86-B2A7-6E0D9C8F1354}']
    /// <summary>
    ///   The PNG file. APalette is R, G, B of the colors in use (3 to 768 bytes, a multiple of 3); a pixel must
    ///   not point past it. The pixels of index ATransparentIndex are written as fully transparent (a tRNS chunk)
    /// </summary>
    /// <exception cref="EPngPaletteEncoderException">The picture or the palette is not whole, or a pixel has no color</exception>
    function Encode(const AImage: TIndexedImage; const APalette: TBytes;
      ATransparentIndex: Integer = PNG_PALETTE_OPAQUE): TBytes;
  end;

  EPngPaletteEncoderException = class(Exception);

implementation

end.
