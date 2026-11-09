{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the contracts                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types;

type
  /// <summary>The Huffman expansion of the id engine (CAL_HuffExpand), with the dictionary of a file</summary>
  IKeenHuffman = interface
    ['{5A1E7C34-9B02-4D6F-8E13-C47A0B95D2F1}']
    /// <summary>
    ///   Expands ADestLength bytes from ASource, starting at ASourceOffset (the bits of a byte are taken from
    ///   the lowest). EKeenDataException when the data end before that
    /// </summary>
    function Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
    /// <summary>
    ///   Like Expand, but data that end early are not an error: the bytes they cannot give stay zero. The C reads
    ///   what is after the data in that case (whatever the buffer had)
    /// </summary>
    function ExpandAvailable(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
  end;

  /// <summary>The RLEW expansion of the maps (CA_RLEWexpand)</summary>
  IKeenRlew = interface
    ['{C83D0F52-1A6B-4E97-B4C5-7E29A1D80F36}']
    /// <summary>
    ///   Expands ADestLength bytes (words, the odd byte is not written) from the words of ASource that start
    ///   at ASourceOffset. A word equal to ATag is followed by a count and a value
    /// </summary>
    function Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer;
      ATag: Word): TBytes;
  end;

  /// <summary>Where the files of the game are: a folder, or the memory of a test</summary>
  IKeenDataFiles = interface
    ['{2F6B91D8-40C3-4A75-9E0D-83B5C6A1E274}']
    function Exists(const AName: string): Boolean;
    /// <summary>A new stream on the file, that the caller owns; EKeenFileNotFoundException if it is not there</summary>
    function OpenStream(const AName: string): TStream;
    /// <summary>The whole file; EKeenFileNotFoundException if it is not there</summary>
    function ReadAll(const AName: string): TBytes;
  end;

  /// <summary>The offsets that start every file of chunks (EGAHEAD, AUDIOHHD): 32 bit, -1 for a chunk that is not there</summary>
  IKeenOffsetTable = interface
    ['{B7094E1A-D6F2-43C8-A951-0E8C3D72B5F6}']
    /// <summary>Entries of the table, one more than the chunks: the last is the end of the file</summary>
    function GetCount: Integer;
    function GetOffset(AIndex: Integer): Integer;
    /// <summary>True if the chunk has no data (offset -1, a sparse tile)</summary>
    function IsSparse(AIndex: Integer): Boolean;
    /// <summary>Where the data of the chunk end: the offset of the next chunk that is there</summary>
    function EndOf(AIndex: Integer): Integer;
    property Count: Integer read GetCount;
    property Offsets[AIndex: Integer]: Integer read GetOffset; default;
  end;

  /// <summary>How long a chunk is once expanded, when the file does not say</summary>
  IKeenChunkLayout = interface
    ['{18D6A0C3-92E7-4F5B-B340-6C71E5A9D082}']
    /// <summary>
    ///   The expanded length of the chunk, or -1 if the chunk starts with a 32 bit number that says it
    ///   (the pictures and the sprites; the tiles have a length that is the same for all)
    /// </summary>
    function ImplicitLength(AIndex: Integer): Integer;
    /// <summary>
    ///   True for a chunk whose data may be shorter than what the header and the length say: the shareware files
    ///   have 40 of the 72 8x8 tiles that graphkdr.h declares, and an audio file shorter than its header. The
    ///   chunk is then read up to the end of the data and what is missing is zero (a short read in the C)
    /// </summary>
    function IsLenient(AIndex: Integer): Boolean;
  end;

  /// <summary>A file made of chunks: the graphics file or the audio file</summary>
  IKeenChunkSource = interface
    ['{E4D18A63-7B95-4C20-B3F7-5A0C92E86D14}']
    function GetChunkCount: Integer;
    /// <summary>False for a chunk with no data (a sparse tile)</summary>
    function HasChunk(AIndex: Integer): Boolean;
    /// <summary>The bytes of the chunk as they are in the file; empty for a sparse chunk</summary>
    function ReadCompressed(AIndex: Integer): TBytes;
    /// <summary>The expanded bytes of the chunk; empty for a sparse chunk</summary>
    function Read(AIndex: Integer): TBytes;
    property ChunkCount: Integer read GetChunkCount;
  end;

  /// <summary>One map of the game: its name, its size and its 3 planes of tiles (background, foreground, info)</summary>
  IKeenMap = interface
    ['{91C5F7B2-3E08-4D6A-A4B1-F2D70E39C85A}']
    function GetNumber: Integer;
    function GetName: string;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetHeader: TKeenMapHeader;
    /// <summary>The planes are Width * Height words, row after row</summary>
    function GetPlane(APlane: Integer): TArray<Word>;
    /// <summary>The word of a plane at the tile (X, Y)</summary>
    function GetTile(APlane, AX, AY: Integer): Word;
    property Number: Integer read GetNumber;
    property Name: string read GetName;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    property Header: TKeenMapHeader read GetHeader;
    property Planes[APlane: Integer]: TArray<Word> read GetPlane;
  end;

  /// <summary>The table that says what every tile is (the bytes of MAPHEAD after the first 502)</summary>
  IKeenTileInfo = interface
    ['{07A3E9D4-5C61-4B28-8F10-D6B24C9E7A53}']
    /// <summary>The table as it is in the file</summary>
    function GetBytes: TBytes;
    /// <summary>How many tics a background tile stays before the next of its animation</summary>
    function Speed(ATile: Integer): Byte;
    /// <summary>How far the next tile of the animation of a background tile is (signed char); 0 = no animation</summary>
    function Animation(ATile: Integer): ShortInt;
    function NorthWall(ATile: Integer): Byte;
    function EastWall(ATile: Integer): Byte;
    function SouthWall(ATile: Integer): Byte;
    function WestWall(ATile: Integer): Byte;
    /// <summary>The same as Animation for a masked (foreground) tile</summary>
    function MaskedAnimation(ATile: Integer): ShortInt;
    function InTile(ATile: Integer): Byte;
    function MaskedSpeed(ATile: Integer): Byte;
    property Bytes: TBytes read GetBytes;
  end;

  /// <summary>The maps of KDREAMS.MAP</summary>
  IKeenMapSource = interface
    ['{D2B8460E-F917-4A3C-95E7-1C0B6A8D3F29}']
    function GetRlewTag: Word;
    function GetTileInfo: IKeenTileInfo;
    /// <summary>True if the slot has a map (an offset above 0)</summary>
    function HasMap(AIndex: Integer): Boolean;
    /// <summary>The numbers of the maps that are there, in order</summary>
    function MapNumbers: TArray<Integer>;
    /// <summary>Reads the header and the planes of a map (CA_CacheMap)</summary>
    function LoadMap(AIndex: Integer): IKeenMap;
    property RlewTag: Word read GetRlewTag;
    property TileInfo: IKeenTileInfo read GetTileInfo;
  end;

  /// <summary>The graphics of the game, by what they are: tables, pictures, tiles</summary>
  IKeenGraphics = interface
    ['{6E0B35C9-A281-47D4-B8F6-3D95C1A07E82}']
    function GetChunks: IKeenChunkSource;
    function GetPictureTable: TArray<TKeenPictureEntry>;
    function GetMaskedPictureTable: TArray<TKeenPictureEntry>;
    function GetSpriteTable: TArray<TKeenSpriteEntry>;
    /// <summary>Planar bytes of a picture: 4 planes of Width * Height bytes</summary>
    function PicturePlanar(AIndex: Integer): TBytes;
    /// <summary>Planar bytes of a masked picture: the mask and 4 planes of Width * Height bytes</summary>
    function MaskedPicturePlanar(AIndex: Integer): TBytes;
    /// <summary>The planar bytes of a sprite, without shifts: the mask and 4 planes of Width * Height bytes</summary>
    function SpritePlanar(AIndex: Integer): TBytes;
    /// <summary>32 bytes of an 8x8 tile; empty if the tile has no data</summary>
    function Tile8(AIndex: Integer): TBytes;
    /// <summary>40 bytes of a masked 8x8 tile</summary>
    function Tile8Masked(AIndex: Integer): TBytes;
    /// <summary>128 bytes of a 16x16 tile of the background; empty if the tile has no data</summary>
    function Tile16(AIndex: Integer): TBytes;
    /// <summary>160 bytes of a masked 16x16 tile of the foreground; empty if the tile has no data</summary>
    function Tile16Masked(AIndex: Integer): TBytes;
    property Chunks: IKeenChunkSource read GetChunks;
    property PictureTable: TArray<TKeenPictureEntry> read GetPictureTable;
    property MaskedPictureTable: TArray<TKeenPictureEntry> read GetMaskedPictureTable;
    property SpriteTable: TArray<TKeenSpriteEntry> read GetSpriteTable;
  end;

  /// <summary>The three files of the game, opened</summary>
  IKeenGameData = interface
    ['{4C9A2E71-B053-4F8D-A6E4-82D17B0C5F93}']
    function GetGraphics: IKeenGraphics;
    function GetMaps: IKeenMapSource;
    function GetAudio: IKeenChunkSource;
    property Graphics: IKeenGraphics read GetGraphics;
    property Maps: IKeenMapSource read GetMaps;
    property Audio: IKeenChunkSource read GetAudio;
  end;

  /// <summary>Turns an image of EGA colors into the bytes of an image file</summary>
  IKeenImageEncoder = interface
    ['{A04C7E93-5D18-4B62-9F3A-C81E0D456B27}']
    function Encode(const AImage: TKeenChunkyImage): TBytes;
  end;

  /// <summary>Draws a map of the game and saves it as an image file</summary>
  IKeenMapExporter = interface
    ['{7D29B1F6-E0A4-4C35-8B71-3F5A92C0D148}']
    /// <summary>Saves the map of the slot AMapNumber; the file is overwritten</summary>
    procedure SaveMapPicture(AMapNumber: Integer; const APath: string);
  end;

  /// <summary>Draws a whole map at once: the background tiles and, over them, the masked tiles of the foreground</summary>
  IKeenMapRenderer = interface
    ['{F3185D6A-0B47-4E92-9C0A-A7E5D21C8B64}']
    function Render(const AMap: IKeenMap; const AGraphics: IKeenGraphics): TKeenChunkyImage;
  end;

implementation

end.
