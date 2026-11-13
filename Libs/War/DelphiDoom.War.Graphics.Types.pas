{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the graphic resources                    }
{                                                                              }
{  Port of war1 (acoto87/war1), the graphic part of war_resources.h and        }
{  war_resources.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see       }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>PALETTE_LENGTH of war.h: 256 colors of 3 bytes (R, G, B)</summary>
  WAR_PALETTE_LENGTH = 768;
  /// <summary>Colors of a palette; the color 0 is the transparent one</summary>
  WAR_PALETTE_COLORS = 256;
  /// <summary>MINI_TILE_WIDTH and HEIGHT of war.h: a mini tile is 8 x 8 pixels of the tiles record</summary>
  WAR_MINI_TILE_SIZE = 8;
  /// <summary>TILESET_WIDTH of war.h: width in pixels of the image of the tileset</summary>
  WAR_TILESET_WIDTH = 512;
  /// <summary>TILESET_HEIGHT of war.h</summary>
  WAR_TILESET_HEIGHT = 256;
  /// <summary>TILESET_TILES_PER_ROW of war.h: mega tiles (2 x 2 mini tiles, 16 pixels) in a row of the image</summary>
  WAR_TILESET_TILES_PER_ROW = 32;
  /// <summary>Mega tiles the image of the tileset can hold (the original wrote past the buffer beyond this)</summary>
  WAR_TILESET_MAX_TILES = 512;
  /// <summary>Bytes of a pixel of the decoded images: R, G, B, A</summary>
  WAR_PIXEL_SIZE = 4;
  /// <summary>Index of the palette whose colors the original corrects after the load</summary>
  WAR_PALETTE_UNIT_INFO = 255;
  /// <summary>Index of the other palette whose colors the original corrects</summary>
  WAR_PALETTE_PORTRAITS = 217;

type
  /// <summary>The 256 colors as the 32 bit number of buildRgbaLut: R + G shl 8 + B shl 16 + $FF000000, 0 for the color 0</summary>
  TWarColorLookup = array[0..WAR_PALETTE_COLORS - 1] of Cardinal;

  /// <summary>An image record on disk: width and height, then one palette index per pixel (little endian)</summary>
  TWarImageHeader = packed record
    Width: Word;
    Height: Word;
  end;

  /// <summary>A sprite record on disk: number of frames and size of a frame, then one frame header per frame</summary>
  TWarSpriteHeader = packed record
    FramesCount: Word;
    FrameWidth: Byte;
    FrameHeight: Byte;
  end;

  /// <summary>
  ///   A frame header on disk: where the frame is inside the area of the sprite, its size and the offset of its
  ///   pixels (palette indices) in the record
  /// </summary>
  TWarSpriteFrameEntry = packed record
    Dx: Byte;
    Dy: Byte;
    Width: Byte;
    Height: Byte;
    Offset: Cardinal;
  end;

  /// <summary>A cursor record on disk: hot spot and size, then one palette index per pixel</summary>
  TWarCursorHeader = packed record
    HotX: Word;
    HotY: Word;
    Width: Word;
    Height: Word;
  end;

  /// <summary>One mega tile of a tileset record: four mini tiles (top left, top right, bottom left, bottom right)</summary>
  TWarTilesetEntry = packed record
    MiniTiles: array[0..3] of Word;
  end;

  /// <summary>An image: Pixels has Width * Height * 4 bytes, R G B A per pixel, the color 0 is all zeros</summary>
  TWarImage = record
    Width: Word;
    Height: Word;
    Pixels: TBytes;
  end;

  /// <summary>
  ///   A frame of a sprite. Pixels has FrameWidth * FrameHeight * 4 bytes of the sprite (the frame is drawn at
  ///   Dx, Dy with Width x Height pixels, the rest is transparent)
  /// </summary>
  TWarSpriteFrame = record
    Dx: Word;
    Dy: Word;
    Width: Word;
    Height: Word;
    Offset: Cardinal;
    Pixels: TBytes;
  end;

  /// <summary>A sprite: frames that share the size of the area they are drawn in</summary>
  TWarSprite = record
    FrameWidth: Byte;
    FrameHeight: Byte;
    Frames: TArray<TWarSpriteFrame>;
  end;

  /// <summary>A mouse cursor: Pixels has Width * Height * 4 bytes</summary>
  TWarCursor = record
    HotX: Word;
    HotY: Word;
    Width: Word;
    Height: Word;
    Pixels: TBytes;
  end;

  /// <summary>
  ///   A tiles record: the bytes of the mini tiles (8 x 8 palette indices each) and the two palettes the
  ///   catalog gives it (0 = none)
  /// </summary>
  TWarTiles = record
    Palette1: Word;
    Palette2: Word;
    Data: TBytes;
  end;

  /// <summary>The image of a tileset: 512 x 256 pixels of 4 bytes, TilesCount mega tiles from the top left</summary>
  TWarTileset = record
    TilesCount: Cardinal;
    Pixels: TBytes;
  end;

resourcestring
  SWarGraphicsNoArchive = 'The graphic resources need an archive';
  SWarGraphicsNoCatalog = 'The graphic resources need the catalog of the records';
  SWarGraphicsNotListed = 'The record %d is not in the catalog';
  SWarGraphicsWrongType = 'The record %d is not a %s';
  SWarGraphicsTooShort = 'The %s of the record %d has %d bytes, %d are needed';
  SWarGraphicsPaletteIndex = 'The palette %d is not a palette of the catalog';
  SWarGraphicsPixelOutside = 'The frame %d of the sprite draws outside the pixels of the sprite';
  SWarGraphicsTileOutside = 'The mini tile %d of the tileset points at byte %d of a tiles record of %d bytes';
  SWarGraphicsTooManyTiles = 'The tileset has %d tiles, the image holds %d';
  SWarGraphicsPaletteLength = 'A palette has %d bytes, %d are needed';

implementation

end.
