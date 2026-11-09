{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - types and constants of the game data            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the formats of speed_defs.pas, speed_is2.pas, speed_level.pas and   }
{  speed_xlat_wad.pas of the fork Speed (https://sourceforge.net/projects/     }
{  speed-game/): the container SPEEDH.JCL and the files inside it              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Types;

interface

{$ALIGN 1}

uses
  System.SysUtils;

const
  /// <summary>The first four bytes of the header of a JCL container (it is at the end of the file)</summary>
  SPEED_JCL_MAGIC = Cardinal($DF73B489);
  /// <summary>'.IS2': the first four bytes of a picture of the game</summary>
  SPEED_IS2_MAGIC = Cardinal(844319022);
  /// <summary>The picture is stored by rows (the other one by columns)</summary>
  SPEED_IS2_HORIZONTAL = Cardinal(1);
  /// <summary>'PATH': the signature of the .PTH file of a circuit</summary>
  SPEED_PATH_SIGNATURE = Cardinal($48544150);

  SPEED_FLAT_PREFIX = 'FLAT';
  SPEED_TRANSLATED_FLAT_PREFIX = 'FTRN';
  SPEED_WALL_PREFIX = 'WALL';
  SPEED_FLAT_SIZE_LUMP = 'FLATSIZE';
  SPEED_INFO_LUMP = 'SPEEDINF';

  /// <summary>The circuits are Doom levels E1M1 to E1M8, drawn twice as big</summary>
  SPEED_LEVEL_SCALE = 2;
  SPEED_MAP_COUNT = 8;
  SPEED_MAX_CIRCUITS = 8;
  /// <summary>A tile of a circuit is 64 x 64 pixels and a circuit is 64 x 64 tiles</summary>
  SPEED_TILE_SIZE = 64;
  SPEED_TILE_PIXELS = SPEED_TILE_SIZE * SPEED_TILE_SIZE;
  SPEED_MAP_TILES = 64 * 64;
  SPEED_MAP_BITMAP_SIDE = 4096;
  /// <summary>The flat that is made of a tile in the colors of a team</summary>
  SPEED_TRANSLATION_COUNT = 25;
  SPEED_TRANSLATED_TILE = 61;
  SPEED_PLAYPAL_PALETTES = 14;
  SPEED_COLORMAPS = 34;

  /// <summary>The first colors of the tile 61 for each translation (index 1..24)</summary>
  SPEED_TRANSLATION_ROVERS: array[1..SPEED_TRANSLATION_COUNT - 1] of Integer = (
    16, 48, 64, 80, 96, 112, 128, 144, 192, 208,
    24, 40, 56, 72, 88, 104, 120, 136, 152, 200,
    160, 168, 176, 184);

type
  /// <summary>Raised when the container or the data given to the library cannot be read</summary>
  ESpeedException = class(Exception);

  /// <summary>An entry of the directory of the JCL container: 32 bytes</summary>
  TSpeedJclEntryRecord = packed record
    FileName: array[0..23] of AnsiChar;
    /// <summary>The distance from the start of the directory, towards the start of the file</summary>
    Start: Integer;
    Size: Integer;
  end;

  /// <summary>The header at the end of a JCL container: 16 bytes</summary>
  TSpeedJclHeader = packed record
    Magic: Cardinal;
    FirstCount: Integer;
    Count: Integer;
    /// <summary>The directory starts this many bytes before the end of the file</summary>
    DirectoryOffset: Integer;
  end;

  /// <summary>The 24 bytes that start an .IS2 picture (the data follow)</summary>
  TSpeedIs2Header = packed record
    Sign: Cardinal;
    Width: Word;
    Height: Word;
    HotX: SmallInt;
    HotY: SmallInt;
    XRatio: Word;
    YRatio: Word;
    Flags: Cardinal;
    /// <summary>The bytes of data after the header</summary>
    Length: Integer;
  end;

  PSpeedIs2Header = ^TSpeedIs2Header;

  /// <summary>The start of a .DAT file of a circuit: the tiles, their angles and then the things</summary>
  TSpeedDiskMap = packed record
    Version: Word;
    Reserved: Word;
    Tiles: array[0..SPEED_MAP_TILES - 1] of Word;
    Angles: array[0..SPEED_MAP_TILES - 1] of Byte;
  end;

  /// <summary>A thing of a circuit in the .DAT file: 8 bytes</summary>
  TSpeedDiskThing = packed record
    X: Word;
    Y: Word;
    Angle: Word;
    ThingType: Word;
  end;

  /// <summary>
  ///   A point of the path, in the .PTH file (from the byte $100, the number of points is the
  ///   word 98) and in the lump PATH of the level: 16 bytes
  /// </summary>
  TSpeedPathPoint = packed record
    X: Cardinal;
    Y: Cardinal;
    Direction: Cardinal;
    Speed: Integer;
  end;

  /// <summary>One file of the container, by position in the sorted directory</summary>
  TSpeedContainerEntry = record
    Name: string;
    /// <summary>Where the data start in the container</summary>
    Position: Integer;
    Size: Integer;
  end;

  /// <summary>A file that the engine has to add to its PAK file system (the 3D models)</summary>
  TSpeedPakEntry = record
    Position: Integer;
    Size: Integer;
    /// <summary>The name inside the PAK file system, for example MODELS\CAR0N0A.I3D</summary>
    Name: string;
  end;

  /// <summary>One circuit of CIRCUITS.LST</summary>
  TSpeedCircuit = record
    Name: string;
    Number: Integer;
    Level: Integer;
    Length: Integer;
    Best: Integer;
    FirstRecord: Integer;
    SecondRecord: Integer;
    Background: Integer;
  end;

const
  SSpeedBadHeader = 'The file is not a JCL container (wrong signature or too short)';
  SSpeedBadDirectory = 'The directory of the container lies outside the file';
  SSpeedBadEntry = 'The file %s of the container lies outside the container';
  SSpeedNoSuchEntry = 'The container has no file %s';
  SSpeedBadIndex = 'The container has no file number %d';

implementation

end.
