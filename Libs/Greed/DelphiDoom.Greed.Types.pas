{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - constants, records of the data files, exceptions }
{  Port of xGreed (Jim Valavanis, GPL v2 or later), a source port of           }
{  "In Pursuit of Greed" (Raven 3D engine, Softdisk Publishing 1996)           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Types;

interface

uses
  System.SysUtils;

const
  // ---- r_public_h.pas: the fixed point numbers and the grid of the world ----

  /// <summary>Bits of the fraction of a fixed point number (FRACBITS)</summary>
  GREED_FRACBITS = 16;
  /// <summary>1.0 as a fixed point number (FRACUNIT)</summary>
  GREED_FRACUNIT = 1 shl GREED_FRACBITS;
  /// <summary>Tiles on a side of the map (MAPCOLS, MAPROWS)</summary>
  GREED_MAP_SIZE = 64;
  /// <summary>Bytes of a plane of the map: one byte for each of the 64 x 64 tiles</summary>
  GREED_MAP_TILES = GREED_MAP_SIZE * GREED_MAP_SIZE;
  /// <summary>Planes that DoLoadMapData reads one after the other</summary>
  GREED_MAP_PLANES = 18;
  /// <summary>Bytes of the planes of a map; a map in the archive can have more after them (its script)</summary>
  GREED_MAP_BYTES = GREED_MAP_PLANES * GREED_MAP_TILES;

  /// <summary>Last angle: the circle has 1024 angles (ANGLES = 1023)</summary>
  GREED_ANGLES = 1023;
  /// <summary>Bits of a tile in fixed point units (FRACTILESHIFT = FRACBITS + TILESHIFT)</summary>
  GREED_FRACTILESHIFT = 22;
  /// <summary>One tile in fixed point units (FRACTILEUNIT)</summary>
  GREED_FRACTILEUNIT = 1 shl GREED_FRACTILESHIFT;

  // ---- d_disk.pas: the archive ----

  /// <summary>Bytes of the header of the archive (fileinfo_t)</summary>
  GREED_FILEINFO_BYTES = 10;
  /// <summary>Bytes of an entry of the lump table (lumpinfo_t)</summary>
  GREED_LUMPINFO_BYTES = 12;

  // ---- the images ----

  /// <summary>Colors of the palette; the lump has 3 bytes for each, with 6 bits of value (VGA)</summary>
  GREED_PALETTE_COLORS = 256;
  GREED_PALETTE_BYTES = GREED_PALETTE_COLORS * 3;
  /// <summary>A flat is 64 x 64 pixels, one row after the other (index y * 64 + x)</summary>
  GREED_FLAT_SIZE = 64;
  GREED_FLAT_BYTES = GREED_FLAT_SIZE * GREED_FLAT_SIZE;
  /// <summary>A wall has 64 columns; the first byte of its lump is the height divided by 4</summary>
  GREED_WALL_WIDTH = 64;
  /// <summary>Bytes before the columns of a wall (65 words)</summary>
  GREED_WALL_HEADER_BYTES = 65 * 2;
  /// <summary>Bytes before the pixels of a picture (pic_t: width, height, origin x and y)</summary>
  GREED_PICTURE_HEADER_BYTES = 8;
  /// <summary>Bytes before the table of the columns of a sprite (scalepic_t: left offset, width)</summary>
  GREED_SPRITE_HEADER_BYTES = 4;

  // ---- lumps of the archive that mark a group, as the game looks for them ----

  GREED_LUMP_PALETTE = 'palette';
  GREED_LUMP_MAP = 'map';
  GREED_LUMP_START_SPRITES = 'startsprites';
  GREED_LUMP_END_SPRITES = 'endsprites';
  GREED_LUMP_START_FLATS = 'startflats';
  GREED_LUMP_END_FLATS = 'endflats';
  GREED_LUMP_START_WALLS = 'startwalls';
  GREED_LUMP_END_WALLS = 'endwalls';

resourcestring
  SGreedReadPastEnd = 'Greed: %d bytes at %d are outside the buffer of %d bytes';
  SGreedArchiveTooShort = 'Greed: the archive has %d bytes, the header needs %d';
  SGreedArchiveHeader = 'Greed: the header of the archive says %d lumps and a table of %d bytes at %d';
  SGreedArchiveTable = 'Greed: the table of the lumps (%d bytes at %d) goes past the end of the file (%d bytes)';
  SGreedArchiveName = 'Greed: the lump %d has its name at %d, outside the table of %d bytes or without an end';
  SGreedLumpInvalid = 'Greed: the lump %d does not exist (the archive has %d)';
  SGreedLumpOutside = 'Greed: the lump %d (%d bytes at %d) goes past the end of the file (%d bytes)';
  SGreedLumpNotFound = 'Greed: the lump %s was not found';
  SGreedFileNotFound = 'Greed: the file %s was not found';
  SGreedFileNotWritten = 'Greed: the file %s cannot be written';
  SGreedMapTooShort = 'Greed: a map needs %d bytes, %d given';
  SGreedMapInvalid = 'Greed: the map %d does not exist (the lumps after "map" are %d)';
  SGreedMapEmpty = 'Greed: the lump of the map %d (%s) has no data and there is no file with that name';
  SGreedMapFileSize = 'Greed: the file %s of a map has %d bytes, %d needed';
  SGreedPlaneInvalid = 'Greed: the plane %d does not exist (a map has %d)';
  SGreedTileOutside = 'Greed: the tile (%d, %d) is outside the map';
  SGreedPaletteTooShort = 'Greed: the palette has %d bytes, %d needed';
  SGreedImageTooShort = 'Greed: the %s lump has %d bytes, %d needed';
  SGreedImageSize = 'Greed: the size %d x %d of the %s is not valid';
  SGreedImageColumn = 'Greed: column %d of the sprite is not valid (offset %d, top %d, bottom %d, lump of %d bytes)';
  SGreedImageKind = 'Greed: the lump %d (%s) is not a picture that can be saved';
  SGreedSaveTooShort = 'Greed: the file %s has %d bytes, %d needed';
  SGreedSettingUnknown = 'Greed: the setting %s does not exist, or it has another kind';
  SGreedArgumentRange = 'Greed: the value %d of %s is outside %d..%d';

type
  /// <summary>Something wrong with the data or the arguments of the greed library</summary>
  EGreedException = class(Exception);

  /// <summary>A data file that does not say what the format says: corrupted or of another version</summary>
  EGreedDataException = class(EGreedException);

  /// <summary>A lump, a map or a file that is not there</summary>
  EGreedNotFoundException = class(EGreedException);

  /// <summary>Number of the 16.16 fixed point type of the engine (fixed_t): an Integer, as in the original</summary>
  TGreedFixed = Integer;

  /// <summary>
  ///   A name of 8 characters padded with zeros (the records of the engine have them as char arrays, that here
  ///   are bytes: AnsiChar, never the 2 byte Char of Delphi 11)
  /// </summary>
  TGreedName8 = array[0..7] of AnsiChar;

  /// <summary>The header of the archive at its start (fileinfo_t), 10 bytes</summary>
  TGreedFileInfo = packed record
    NumLumps: SmallInt;
    InfoTableOffset: Integer;
    InfoTableSize: Integer;
  end;

  /// <summary>
  ///   An entry of the table of the lumps (lumpinfo_t), 12 bytes. NameOffset counts from the start of the table
  ///   (0 is a lump without a name) to a name that ends with a zero. Compress is stored but the game never
  ///   reads it, and it is 0 in every lump of the demos
  /// </summary>
  TGreedLumpInfo = packed record
    FilePosition: Integer;
    Size: Cardinal;
    NameOffset: SmallInt;
    Compress: SmallInt;
  end;

  /// <summary>The start of a picture (pic_t before its data), 8 bytes</summary>
  TGreedPictureHeader = packed record
    Width: SmallInt;
    Height: SmallInt;
    OriginX: SmallInt;
    OriginY: SmallInt;
  end;

  /// <summary>The start of a sprite (scalepic_t before the offsets of its columns), 4 bytes</summary>
  TGreedSpriteHeader = packed record
    LeftOffset: SmallInt;
    Width: SmallInt;
  end;

  /// <summary>
  ///   The planes of a map, in the order they are in the file (northwall ... mapslopes of DoLoadMapData).
  ///   Each has one byte for the tile (x, y) at index y * 64 + x
  /// </summary>
  TGreedPlane = (
    gpNorthWall, gpNorthFlags, gpWestWall, gpWestFlags, gpFloorPic, gpFloorFlags, gpCeilingPic,
    gpCeilingFlags, gpFloorHeight, gpCeilingHeight, gpFloorDef, gpFloorDefFlags, gpCeilingDef,
    gpCeilingDefFlags, gpMapLights, gpMapEffects, gpMapSprites, gpMapSlopes);

  /// <summary>What a lump of the archive is, for the programs that show it</summary>
  TGreedLumpKind = (glkOther, glkPalette, glkPicture, glkFlat, glkWall, glkSprite);

  /// <summary>
  ///   An image of 8 bit pixels, a row after the other from the top. The color is an index in the palette;
  ///   0 is transparent in the pictures that are masked and in the sprites. Origin is the point of the image
  ///   that the game puts on its position (the offsets of the header of a picture; for a sprite the left
  ///   offset and the bottom of the image)
  /// </summary>
  TGreedImage = record
    Width: Integer;
    Height: Integer;
    OriginX: Integer;
    OriginY: Integer;
    Pixels: TBytes;
  end;

implementation

end.
