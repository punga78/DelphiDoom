{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL texture buffers - the shared types                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlTexture.Types;

interface

const
  /// <summary>Size in bytes of the header of a patch: width, height, left and top offset, 16 bit each</summary>
  GLTEXTURE_PATCH_HEADER_SIZE = 8;
  /// <summary>The topdelta that ends the posts of a column</summary>
  GLTEXTURE_COLUMN_END = 255;
  /// <summary>The values of a ripple table (one row of r_defripple)</summary>
  GLTEXTURE_RIPPLE_SIZE = 128;

type
  PGlTextureByte = PByte;

  /// <summary>A row of the table of the ripple effect: 128 values in 16.16 fixed point</summary>
  TGlRippleRow = array[0..GLTEXTURE_RIPPLE_SIZE - 1] of Integer;
  PGlRippleRow = ^TGlRippleRow;

  /// <summary>
  ///   The buffer a texture is made in: the pixels (1 byte for a paletted texture, 4 for RGBA) in
  ///   rows of BufferWidth pixels, and the real size of the picture inside it
  /// </summary>
  TGlTextureTarget = record
    Pixels: PByte;
    BufferWidth: Integer;
    RealWidth: Integer;
    RealHeight: Integer;
  end;

  /// <summary>The palette of the game as the buffers need it</summary>
  TGlTexturePaletteData = record
    /// <summary>The 256 colors of 3 bytes (R, G, B) of the game</summary>
    Colors: PByte;
    /// <summary>For each color the first color with the same RGB (a paletted texture has no duplicates)</summary>
    ColorMap: PByte;
  end;

implementation

end.
