{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - constants, records of the data files, exceptions  }
{  Port of Commander Keen in Keen Dreams (id Software 1991, source code        }
{  released in 2014 by Javier M. Chavez), GPL v2 or later: graphkdr.h,          }
{  audiokdr.h, id_ca.h, id_vw.h                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Types;

interface

uses
  System.SysUtils;

const
  // ---- graphkdr.h: how many items the graphics file has ----

  /// <summary>Chunks of the graphics file (NUMCHUNKS); the header has one offset more</summary>
  KEEN_NUMCHUNKS = 3016;
  KEEN_NUMFONT = 1;
  /// <summary>Pictures (NUMPICS)</summary>
  KEEN_NUMPICS = 65;
  /// <summary>Masked pictures (NUMPICM)</summary>
  KEEN_NUMPICM = 2;
  KEEN_NUMSPRITES = 297;
  /// <summary>8x8 tiles, all in one chunk</summary>
  KEEN_NUMTILE8 = 72;
  KEEN_NUMTILE8M = 36;
  /// <summary>16x16 tiles of the background, one chunk each</summary>
  KEEN_NUMTILE16 = 1440;
  /// <summary>Masked 16x16 tiles of the foreground, one chunk each</summary>
  KEEN_NUMTILE16M = 1206;

  // ---- graphkdr.h: first chunk of each kind ----

  KEEN_STRUCTPIC = 0;
  KEEN_STRUCTPICM = 1;
  KEEN_STRUCTSPRITE = 2;
  KEEN_STARTFONT = 3;
  KEEN_STARTPICS = 4;
  KEEN_STARTPICM = 69;
  KEEN_STARTSPRITES = 71;
  KEEN_STARTTILE8 = 368;
  KEEN_STARTTILE8M = 369;
  KEEN_STARTTILE16 = 370;
  KEEN_STARTTILE16M = 1810;
  /// <summary>STARTTILE32: here the chunks end (there are no 32x32 tiles)</summary>
  KEEN_STARTTILE32 = 3016;

  // ---- sizes of the EGA planar data (BLOCK and MASKBLOCK of id_ca.c) ----

  /// <summary>Planes of a picture</summary>
  KEEN_EGA_PLANES = 4;
  /// <summary>Bytes of an 8x8 tile: 4 planes of 8 rows of one byte</summary>
  KEEN_TILE8_BYTES = 32;
  /// <summary>Bytes of a masked 8x8 tile: a mask plane and 4 planes of 8 rows</summary>
  KEEN_TILE8M_BYTES = 40;
  /// <summary>Bytes of a 16x16 tile: 4 planes of 16 rows of two bytes</summary>
  KEEN_TILE16_BYTES = 128;
  /// <summary>Bytes of a masked 16x16 tile: a mask plane and 4 planes of 16 rows</summary>
  KEEN_TILE16M_BYTES = 160;
  KEEN_TILE8_SIZE = 8;
  KEEN_TILE16_SIZE = 16;

  // ---- id_ca.h / audiokdr.h ----

  /// <summary>Maps the game has (NUMMAPS); the header of the file has room for 100</summary>
  KEEN_NUMMAPS = 30;
  /// <summary>Entries of headeroffsets[] and headersize[] of MAPHEAD</summary>
  KEEN_MAP_SLOTS = 100;
  /// <summary>Bytes of the start of MAPHEAD that are not the tile info: RLEWtag, offsets, header sizes</summary>
  KEEN_MAPHEAD_PREFIX = 502;
  /// <summary>Chunks of the audio file (NUMSNDCHUNKS); the header has one offset more</summary>
  KEEN_NUMSNDCHUNKS = 84;
  KEEN_NUMSOUNDS = 28;
  KEEN_STARTPCSOUNDS = 0;
  KEEN_STARTADLIBSOUNDS = 28;
  KEEN_STARTDIGISOUNDS = 56;

  // ---- the tile info table (the bytes of MAPHEAD after the first 502): offsets inside the table ----

  KEEN_TINF_SPEED = 0;
  KEEN_TINF_ANIM = KEEN_TINF_SPEED + KEEN_NUMTILE16;
  KEEN_TINF_NORTHWALL = KEEN_TINF_ANIM + KEEN_NUMTILE16;
  KEEN_TINF_EASTWALL = KEEN_TINF_NORTHWALL + KEEN_NUMTILE16M;
  KEEN_TINF_SOUTHWALL = KEEN_TINF_EASTWALL + KEEN_NUMTILE16M;
  KEEN_TINF_WESTWALL = KEEN_TINF_SOUTHWALL + KEEN_NUMTILE16M;
  KEEN_TINF_MANIM = KEEN_TINF_WESTWALL + KEEN_NUMTILE16M;
  KEEN_TINF_INTILE = KEEN_TINF_MANIM + KEEN_NUMTILE16M;
  KEEN_TINF_MSPEED = KEEN_TINF_INTILE + KEEN_NUMTILE16M;
  /// <summary>Bytes of the tile info table</summary>
  KEEN_TINF_SIZE = KEEN_TINF_MSPEED + KEEN_NUMTILE16M;

  // ---- Huffman ----

  /// <summary>Nodes of a Huffman dictionary; the head is always the last (CAL_HuffExpand)</summary>
  KEEN_HUFF_NODES = 255;
  KEEN_HUFF_HEAD = 254;
  /// <summary>Bytes the dictionary needs; the files have 1020 (map) or 1024 (graphics and audio)</summary>
  KEEN_HUFF_DICT_BYTES = KEEN_HUFF_NODES * 4;

  /// <summary>
  ///   Value of a pixel of the chunky image that the mask of a masked picture leaves open
  ///   (the colors of the EGA are 0..15)
  /// </summary>
  KEEN_PIXEL_TRANSPARENT = $FF;

  // ---- id_vw.h: the EGA screen ----

  /// <summary>Bytes of a row of the virtual screen (SCREENWIDTH): 512 pixels</summary>
  KEEN_SCREENWIDTH = 64;
  /// <summary>Rows that ylookup knows (VIRTUALHEIGHT)</summary>
  KEEN_VIRTUALHEIGHT = 300;
  /// <summary>Bytes of each of the 4 planes of the EGA memory (64 KB: the offsets wrap)</summary>
  KEEN_EGA_PLANE_BYTES = 65536;
  /// <summary>Shifted copies of a sprite (MAXSHIFTS)</summary>
  KEEN_MAXSHIFTS = 8;
  KEEN_WHITE = 15;
  KEEN_BLACK = 0;
  KEEN_FIRSTCOLOR = 1;
  KEEN_SECONDCOLOR = 12;
  /// <summary>Pixels of the visible screen</summary>
  KEEN_DISPLAY_WIDTH = 320;
  KEEN_DISPLAY_HEIGHT = 200;

  // ---- id_rf.h: the tile refresh manager ----

  KEEN_MINTICS = 2;
  KEEN_MAXTICS = 6;
  KEEN_MAPBORDER = 2;
  KEEN_MAXSPRITES = 100;
  KEEN_MAXANIMTILES = 90;
  KEEN_MAXANIMTYPES = 50;
  KEEN_MAXMAPHEIGHT = 128;
  KEEN_PRIORITIES = 4;
  KEEN_MASKEDTILEPRIORITY = 3;
  KEEN_TILEGLOBAL = 256;
  KEEN_PORTTILESWIDE = 21;
  KEEN_PORTTILESHIGH = 14;
  KEEN_UPDATEWIDE = KEEN_PORTTILESWIDE + 1;
  KEEN_UPDATEHIGH = KEEN_PORTTILESHIGH;

resourcestring
  SKeenDictionaryTooShort = 'Keen: the Huffman dictionary has %d bytes, %d needed';
  SKeenDictionaryBadNode = 'Keen: the node %d of the Huffman dictionary points to %d';
  SKeenHuffmanTruncated = 'Keen: the Huffman data ends after %d of %d bytes';
  SKeenHuffmanBadStart = 'Keen: the Huffman data start at %d, the buffer has %d bytes';
  SKeenLengthInvalid = 'Keen: the expanded length %d is not valid';
  SKeenRlewTruncated = 'Keen: the RLEW data end after %d of %d words';
  SKeenRlewOverflow = 'Keen: a RLEW run goes past the end of the %d words that were asked';
  SKeenReadPastEnd = 'Keen: %d bytes at %d are outside the buffer of %d bytes';
  SKeenChunkInvalid = 'Keen: the chunk %d does not exist (the file has %d)';
  SKeenChunkOffsets = 'Keen: the chunk %d goes from %d to %d, and the file has %d bytes';
  SKeenChunkNoEnd = 'Keen: the chunk %d has no end: the offsets finish with sparse chunks';
  SKeenHeaderInvalid = 'Keen: the header of %s has %d bytes, %d needed at least';
  SKeenMapInvalid = 'Keen: the map %d does not exist';
  SKeenMapBadHeader = 'Keen: the header of the map %d says %d x %d';
  SKeenMapBadPlane = 'Keen: the plane %d of the map %d is not valid (%s)';
  SKeenColorInvalid = 'Keen: the color %d does not exist (the EGA has 16)';
  SKeenTileOutside = 'Keen: the tile (%d, %d) is outside the map %d';
  SKeenTileInvalid ='Keen: the tile %d does not exist (the table has %d)';
  SKeenPictureInvalid = 'Keen: the picture %d does not exist (the table has %d)';
  SKeenPlanarTooShort = 'Keen: the picture needs %d bytes, %d given';
  SKeenFileMissing = 'Keen: the file %s was not found in the data folders';
  SKeenFileMissingAny = 'Keen: none of the files %s was found in the data folders';
  SKeenFileUnreadable = 'Keen: the file %s cannot be read';
  SKeenFileNotWritten = 'Keen: the file %s cannot be written';
  SKeenSizeInvalid = 'Keen: the size %d x %d is not valid';
  SKeenSpriteShifts = 'Keen: the sprite %d has %d shifts (1, 2 or 4)';
  SKeenSpriteInvalid = 'Keen: the sprite %d does not exist (the table has %d)';
  SKeenSpriteTooShort = 'Keen: the sprite needs %d bytes, %d given';
  SKeenVideoOutside = 'Keen: the screen has no row %d (the table has %d rows)';
  SKeenVideoNoGraphics = 'Keen: the video manager has no graphics to draw %s';
  SKeenRefreshNoSprites = 'Keen: RF_PlaceSprite: no free spots in spritearray';
  SKeenRefreshNoAnimTiles = 'Keen: RF_CheckForAnimTile: no free spots in tilearray';
  SKeenRefreshTooManyAnims = 'Keen: RF_MarkTileGraphics: too many unique animated tiles';
  SKeenRefreshUnendingAnim = 'Keen: RF_MarkTileGraphics: the animation of tile %d does not end';
  SKeenRefreshOutOfBounds = 'Keen: RFL_AnimateTiles: the tile (%d, %d) is out of the port';
  SKeenRefreshNoChain = 'Keen: the animated tile at (%d, %d) has no animation chain (RF_MarkTileGraphics was not called)';
  SKeenRefreshNoMap = 'Keen: RF_NewMap must be called before the map is used';
  SKeenRefreshBadPriority = 'Keen: the priority %d of a sprite is not 0..%d';
  SKeenDemoTruncated = 'Keen: the demo has %d bytes and needs at least %d';
  SKeenDemoBadLength = 'Keen: the demo says it has %d tics and only %d bytes follow';
  SKeenDemoOverflow = 'Keen: demo buffer overflow (%d of %d bytes)';
  SKeenDemoExceeded = 'Keen: demo playback exceeded';
  SKeenDemoNotRecording = 'Keen: no demo is being recorded';
  SKeenStateInvalid = 'Keen: the state %d does not exist (the table has %d)';
  SKeenObjectListFull = 'Keen: GetNewObj: no free spots in objarray';
  SKeenObjectRemovePlayer = 'Keen: RemoveObj: tried to remove the player';
  SKeenActionMissing = 'Keen: the function %s of a state has no code yet';
  SKeenObjectInvalid = 'Keen: the actor %d does not exist';
  SKeenNoSpriteShape = 'Keen: the actor has the shape %d, that is not a sprite';
  SKeenInputBadScan = 'Keen: the scan code %d is not valid';

type
  /// <summary>Something wrong with the data or the arguments of the keen library</summary>
  EKeenException = class(Exception);

  /// <summary>A data file that does not say what the format says: corrupted or of another version</summary>
  EKeenDataException = class(EKeenException);

  /// <summary>A data file that is not in any of the folders</summary>
  EKeenFileNotFoundException = class(EKeenException);

  /// <summary>
  ///   A node of a Huffman dictionary (huffnode): the two values it gives for a 0 and a 1 bit.
  ///   A value under 256 is a byte, 256 and more is the node (value - 256) to go on from
  /// </summary>
  TKeenHuffNode = packed record
    Bit0: Word;
    Bit1: Word;
  end;

  /// <summary>
  ///   The header of a map (maptype), 38 bytes: where each of the 3 planes starts in the file and how
  ///   long it is (compressed), the size in tiles and the name
  /// </summary>
  TKeenMapHeader = packed record
    PlaneStart: array[0..2] of Integer;
    PlaneLength: array[0..2] of Word;
    Width: Word;
    Height: Word;
    Name: array[0..15] of AnsiChar;
  end;

  /// <summary>
  ///   The start of MAPHEAD (mapfiletype), 502 bytes: the RLEW tag, where the header of each map is in
  ///   KDREAMS.MAP (-1 or 0: no map) and how many compressed bytes it has. The tile info table follows
  /// </summary>
  TKeenMapFileHeader = packed record
    RlewTag: Word;
    HeaderOffsets: array[0..KEEN_MAP_SLOTS - 1] of Integer;
    HeaderSizes: array[0..KEEN_MAP_SLOTS - 1] of Byte;
  end;

  /// <summary>An entry of pictable and picmtable (pictabletype): the width is in bytes (8 pixels)</summary>
  TKeenPictureEntry = packed record
    Width: SmallInt;
    Height: SmallInt;
  end;

  /// <summary>An entry of spritetable (spritetabletype); the width is in bytes</summary>
  TKeenSpriteEntry = packed record
    Width: SmallInt;
    Height: SmallInt;
    OriginX: SmallInt;
    OriginY: SmallInt;
    XL: SmallInt;
    YL: SmallInt;
    XH: SmallInt;
    YH: SmallInt;
    Shifts: SmallInt;
  end;

  /// <summary>The start of every sound of the audio file (SoundCommon)</summary>
  TKeenSoundCommon = packed record
    Length: Cardinal;
    Priority: Word;
  end;

  /// <summary>
  ///   A sprite with its shifted copies (spritetype of id_vw.h): the four shifts that a pel panning of
  ///   0, 2, 4 and 6 pixels needs. Offsets are from the start of Data (the C counts from the start of the
  ///   block, after its three tables of MAXSHIFTS words: 48 bytes more). Each copy is the mask plane and the
  ///   4 color planes of PlaneSize bytes (Width * height), Width in bytes
  /// </summary>
  TKeenSprite = record
    SourceOffset: array[0..KEEN_MAXSHIFTS - 1] of Word;
    PlaneSize: array[0..KEEN_MAXSHIFTS - 1] of Word;
    Width: array[0..KEEN_MAXSHIFTS - 1] of Word;
    Data: TBytes;
  end;

  /// <summary>How RF_PlaceSprite draws a sprite (drawtype): maskdraw puts it on the list and draws nothing</summary>
  TKeenDrawType = (kdtSpriteDraw, kdtMaskDraw);

  /// <summary>
  ///   What RF_PlaceSprite keeps in the pointer of the actor (the void ** user): 0 = the actor has no
  ///   sprite on the list, otherwise the slot of the sprite plus one
  /// </summary>
  TKeenSpriteHandle = Integer;

  /// <summary>A sprite to put on a view of the map: the chunk, the global position (1/16 of a pixel) and the priority</summary>
  TKeenViewSprite = record
    SpriteChunk: Integer;
    GlobalX: Integer;
    GlobalY: Integer;
    Priority: Integer;
  end;

  /// <summary>An image with one byte for each pixel: the EGA color 0..15, or KEEN_PIXEL_TRANSPARENT</summary>
  TKeenChunkyImage = record
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
  end;

implementation

end.
