{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - constants, records of the data files,     }
{  exceptions                                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Colors of an X-Com palette in PALETTES.DAT (a 8 bit image)</summary>
  XCOM_PALETTE_COLORS = 256;
  /// <summary>Colors of BACKPALS.DAT: one 128 color palette for every background</summary>
  XCOM_BACKPALS_COLORS = 128;
  /// <summary>Bytes of one palette of PALETTES.DAT: 256 colors of 3 bytes, then 6 bytes that nobody reads</summary>
  XCOM_PALETTE_STRIDE = 768 + 6;
  /// <summary>The first color of the background block of a palette (Palette::backPos)</summary>
  XCOM_BACKPOS = 224;
  /// <summary>The 16 last colors of the battlescape palette are a greyish gradient</summary>
  XCOM_GRADIENT_COLORS = 16;

  /// <summary>Bytes of one record of a .RMP file (the nodes of a map block)</summary>
  XCOM_RMP_RECORD_BYTES = 24;
  /// <summary>Links of every node of a .RMP file</summary>
  XCOM_RMP_LINKS = 5;
  /// <summary>Bytes of one record of a .MCD file (a tile of the terrain)</summary>
  XCOM_MCD_RECORD_BYTES = 62;
  /// <summary>Bytes of one polygon of WORLD.DAT</summary>
  XCOM_WORLD_RECORD_BYTES = 20;

  /// <summary>The 4 parts of a cell of a .MAP: floor, west wall, north wall, object (O_FLOOR..O_OBJECT)</summary>
  XCOM_MAP_PART_FLOOR = 0;
  XCOM_MAP_PART_WEST_WALL = 1;
  XCOM_MAP_PART_NORTH_WALL = 2;
  XCOM_MAP_PART_OBJECT = 3;

  /// <summary>A .RMP link to a node that is not in the block: unused, north, east, south, west</summary>
  XCOM_LINK_UNUSED = -1;
  XCOM_LINK_NORTH = -2;
  XCOM_LINK_EAST = -3;
  XCOM_LINK_SOUTH = -4;
  XCOM_LINK_WEST = -5;

  /// <summary>An entry of a CAT file starts with a name of at most this many bytes (CatFile::load)</summary>
  XCOM_CAT_NAME_LIMIT = 56;

resourcestring
  SXcomFileMissing = 'Xcom: the file %s was not found in the data folders';
  SXcomFileUnreadable = 'Xcom: the file %s cannot be read';
  SXcomFileNotWritten = 'Xcom: the file %s cannot be written';
  SXcomSizeInvalid = 'Xcom: the size %d x %d is not valid';
  SXcomNoPalette = 'Xcom: the image has no palette, so it has no colors';
  SXcomImageInvalid = 'Xcom: the image does not have the %d bytes of %d x %d pixels';
  SXcomHeaderTooShort = 'Xcom: %s needs %d bytes at least and has %d';
  SXcomCatIndexInvalid = 'Xcom: the CAT file has %d entries, the number %d does not exist';
  SXcomCatEntryTooBig = 'Xcom: the entry %d of the CAT file has %d bytes: the index is damaged';
  SXcomCatBadIndex = 'Xcom: the index of the CAT file says %d entries of 8 bytes, the file has %d bytes';
  SXcomMapBadSize = 'Xcom: the MAP says %d x %d x %d (the sizes are signed bytes and must be more than 0)';
  SXcomMapTooManyCells = 'Xcom: the MAP says %d x %d x %d = %d cells and has %d';
  SXcomMapCellOutside = 'Xcom: the cell (%d, %d, %d) is outside the %d x %d x %d of the MAP';
  SXcomMcdBadReference = 'Xcom: the object %d of the MCD has %s %d, and the MCD has %d objects';
  SXcomMcdNoArmor = 'Xcom: the object %d of the MCD has 0 armor';
  SXcomPaletteBadCount = 'Xcom: a palette of %d colors is not valid (at most %d)';
  SXcomPaletteBadIndex = 'Xcom: the color %d does not exist in a palette of %d colors';
  SXcomDecoderBadSize = 'Xcom: the pictures of %d x %d pixels are not valid';
  SXcomTooManyFrames = 'Xcom: the TAB file says %d frames, the limit is %d';
  SXcomOffsetInvalid = 'Xcom: the offset %d is not valid';

type
  /// <summary>Something wrong with the data or the arguments of the xcom formats library</summary>
  EXcomException = class(Exception);

  /// <summary>A data file that does not say what its format says: corrupted, or of another game</summary>
  EXcomDataException = class(EXcomException);

  /// <summary>A data file that is not in any of the folders</summary>
  EXcomFileNotFoundException = class(EXcomException);

  /// <summary>
  ///   A color of an X-Com palette as OpenXcom keeps it (SDL_Color): 8 bits per channel and the alpha that
  ///   the "unused" byte of SDL_Color carried: 255 for a color that was in the file, 0 for the color 0 and
  ///   for the colors that the file did not have
  /// </summary>
  TXcomColor = packed record
    Red: Byte;
    Green: Byte;
    Blue: Byte;
    Alpha: Byte;
  end;

  /// <summary>
  ///   The size of a .MAP file, the three bytes that start it (char size[3] of loadMAP). They are SIGNED bytes:
  ///   (int)size[0] of a C char with sign gives a negative number for 128..255, and the sizes of a block
  ///   are Y, X, Z in this order
  /// </summary>
  TXcomMapHeader = packed record
    SizeY: Shortint;
    SizeX: Shortint;
    SizeZ: Shortint;
  end;

  /// <summary>One cell of a .MAP: the four bytes of the floor, the west wall, the north wall and the object</summary>
  TXcomMapCell = packed record
    Floor: Byte;
    WestWall: Byte;
    NorthWall: Byte;
    Obj: Byte;
  end;

  /// <summary>A link of a node of a .RMP file: the node it goes to, the distance and the kind of way</summary>
  TXcomRmpLink = packed record
    Target: Byte;
    Distance: Byte;
    Kind: Byte;
  end;

  /// <summary>
  ///   One node of a .RMP file as the 24 bytes say it (value[24] of loadRMP): the position (Y, X, Z in this order),
  ///   five links of three bytes (the node, the distance and the kind of the way) and the data of the node
  /// </summary>
  TXcomRmpRecord = packed record
    PosY: Byte;
    PosX: Byte;
    PosZ: Byte;
    Unknown: Byte;
    Links: array[0..XCOM_RMP_LINKS - 1] of TXcomRmpLink;
    NodeType: Byte;
    Rank: Byte;
    Flags: Byte;
    Reserved: Byte;
    Priority: Byte;
  end;

  /// <summary>
  ///   One tile of the terrain, the 62 bytes of a .MCD file (struct MCD of MapDataSet::loadData); the fields
  ///   named U23 and the like are the ones that the game does not use
  /// </summary>
  TXcomMcdRecord = packed record
    Frame: array[0..7] of Byte;
    Loft: array[0..11] of Byte;
    ScanG: Word;
    U23, U24, U25, U26, U27, U28, U29, U30: Byte;
    UfoDoor: Byte;
    StopLos: Byte;
    NoFloor: Byte;
    BigWall: Byte;
    Gravlift: Byte;
    Door: Byte;
    BlockFire: Byte;
    BlockSmoke: Byte;
    U39: Byte;
    TuWalk: Byte;
    TuSlide: Byte;
    TuFly: Byte;
    Armor: Byte;
    HeBlock: Byte;
    DieMcd: Byte;
    Flammable: Byte;
    AltMcd: Byte;
    U48: Byte;
    TerrainLevel: Shortint;
    PLevel: Byte;
    U51: Byte;
    LightBlock: Byte;
    Footstep: Byte;
    TileType: Byte;
    HeType: Byte;
    HeStrength: Byte;
    SmokeBlockage: Byte;
    Fuel: Byte;
    LightSource: Byte;
    TargetType: Byte;
    XcomBase: Byte;
    U62: Byte;
  end;

  /// <summary>One polygon of WORLD.DAT, the 10 words (short value[10] of RuleGlobe::loadDat)</summary>
  TXcomWorldRecord = packed record
    Values: array[0..9] of SmallInt;
  end;

  /// <summary>The nodes of a .RMP file once they are in the battle map (BattlescapeGenerator::loadRMP)</summary>
  TXcomRouteNode = record
    /// <summary>A node outside the block, kept so the numbers of the links still agree</summary>
    IsDummy: Boolean;
    /// <summary>Position in the battle map: the block offset added, the layer counted from the lowest one</summary>
    X, Y, Z: Integer;
    /// <summary>The node number in the whole battle map, nodeOffset more than the number in the file</summary>
    Index: Integer;
    NodeType: Integer;
    Rank: Integer;
    Flags: Integer;
    Reserved: Integer;
    Priority: Integer;
    /// <summary>
    ///   The five links: a node number of the battle map (the number in the file plus nodeOffset) or one of
    ///   XCOM_LINK_UNUSED / NORTH / EAST / SOUTH / WEST. The links to a node that was culled are XCOM_LINK_UNUSED
    /// </summary>
    Links: array[0..XCOM_RMP_LINKS - 1] of Integer;
  end;

  /// <summary>A polygon of the globe: 3 or 4 points in radians</summary>
  TXcomWorldPolygon = record
    Points: Integer;
    Longitude: array[0..3] of Double;
    Latitude: array[0..3] of Double;
    Texture: Integer;
  end;

  /// <summary>An entry of the index that starts a CAT file: where the entry is and how long it is</summary>
  TXcomCatEntry = packed record
    Offset: Cardinal;
    Size: Cardinal;
  end;

implementation

end.
