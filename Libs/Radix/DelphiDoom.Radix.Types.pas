{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - types                                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{  Copyright (C) 1995 by Epic MegaGames, Inc. (Radix - beyond the void)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_defs.pas of the fork Rad-X. The record are the ones of the    }
{  file RADIX.DAT: packed, no pointers, one byte per character of a name       }
{  (the fork declared them as arrays of Char, 2 bytes in Delphi 11)            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Raised when RADIX.DAT is not a container of Radix or a lump is not good</summary>
  ERadixException = class(Exception);

  /// <summary>The header of RADIX.DAT: the signature "NSRes:Radix", the directory at Start</summary>
  TRadixHeaderRecord = packed record
    Id: packed array[0..10] of AnsiChar;
    Unknown: packed array[0..5] of Byte;
    NumLumps: Integer;
    Start: Integer;
  end;

  /// <summary>An entry of the directory of RADIX.DAT</summary>
  TRadixLumpRecord = packed record
    Name: packed array[0..31] of AnsiChar;
    Position: Integer;
    Length: Integer;
    UnknownWord: SmallInt;
    UnknownInteger: Integer;
  end;

  /// <summary>An entry of the table of the wall bitmaps (the lump "WallBitmaps")</summary>
  TRadixBitmapRecord = packed record
    Name: packed array[0..31] of AnsiChar;
    Position: Integer;
    Height: SmallInt;
    Width: SmallInt;
  end;

  /// <summary>A lump of the container: its name and where its bytes are</summary>
  TRadixLumpInfo = record
    Name: string;
    Position: Integer;
    Length: Integer;
  end;

  /// <summary>An entry that the engine adds to the PAK file system (a picture kept in the DAT)</summary>
  TRadixPakEntry = record
    Position: Integer;
    Size: Integer;
    Name: string;
  end;

const
  RADIX_SIGNATURE = 'NSRes:Radix';
  RADIX_WALL_PREFIX = 'RDXW';
  RADIX_FLAT_PREFIX = 'RDXF';
  RADIX_PALETTE_LUMP = 'PALETTE';
  RADIX_COLORMAP_LUMP = 'SHADES';
  RADIX_ALIASES_LUMP = 'RADIXINF';
  RADIX_PAK_EXTENSION = '.RADIX32';

  SRadixNotContainer = 'The file is not a container of Radix (NSRes:Radix)';
  SRadixBadDirectory = 'The directory of the container is not good (%d lumps at %d)';
  SRadixBadLump = 'The lump "%s" lies outside the container';
  SRadixBadBitmapTable = 'The table of the bitmaps "%s" is not good';

implementation

end.
