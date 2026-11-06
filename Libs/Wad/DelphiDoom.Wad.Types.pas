{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - types shared by the library                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>'IWAD', 'PWAD' and the DelphiDoom specific 'DWAD' (little endian)</summary>
  WAD_ID_IWAD = Integer($44415749);
  WAD_ID_PWAD = Integer($44415750);
  WAD_ID_DWAD = Integer($44415744);
  /// <summary>'PACK' of the Quake PAK files</summary>
  PAK_ID = Integer($4B434150);
  /// <summary>'PK' 03 04 of the first local header of a ZIP (PK3)</summary>
  ZIP_ID = Integer($04034B50);

  WAD_LUMP_NAME_SIZE = 8;
  WAD_HEADER_SIZE = 12;
  WAD_DIRECTORY_RECORD_SIZE = 16;
  PAK_NAME_SIZE = 56;
  PAK_DIRECTORY_RECORD_SIZE = 64;

  // Kinds of lumps delimited by the marker pairs (F_START/F_END, S_START/S_END ...)
  IND_FLOOR = 1;
  IND_SPRITE = 2;
  IND_PATCH = 3;
  IND_VOXEL = 4;
  IND_HIRES = 5;
  IND_MAX = 6;
  TYPE_FLOOR = 1 shl IND_FLOOR;
  TYPE_SPRITE = 1 shl IND_SPRITE;
  TYPE_PATCH = 1 shl IND_PATCH;
  TYPE_VOXEL = 1 shl IND_VOXEL;
  TYPE_HIRES = 1 shl IND_HIRES;

type
  /// <summary>What a source of lumps is made of</summary>
  TWadSourceKind = (Wad, Pak, Zip, Folder, SingleFile);

  /// <summary>Type of a WAD: the original game, a patch or the DelphiDoom system WAD</summary>
  TWadKind = (IWad, PWad, DWad);

  /// <summary>Raised for damaged files, incoherent directories and bad arguments</summary>
  EWadException = class(Exception);

  /// <summary>Header of a WAD on disk (12 bytes)</summary>
  TWadHeader = packed record
    Identification: Integer;
    NumLumps: Integer;
    InfoTableOfs: Integer;
  end;

  /// <summary>Record of the directory of a WAD on disk (16 bytes)</summary>
  TWadDirectoryRecord = packed record
    FilePos: Integer;
    Size: Integer;
    Name: array[0..WAD_LUMP_NAME_SIZE - 1] of AnsiChar;
  end;

  /// <summary>Record of the directory of a PAK on disk (64 bytes)</summary>
  TPakDirectoryRecord = packed record
    Name: array[0..PAK_NAME_SIZE - 1] of AnsiChar;
    FilePos: Integer;
    Size: Integer;
  end;

  /// <summary>
  ///   A lump of a source. Name is upper case: at most 8 characters for the
  ///   lumps of a WAD, a path with '/' for PAK, ZIP and folders
  /// </summary>
  TWadEntry = record
    Name: string;
    Offset: Integer;
    Size: Integer;
  end;

implementation

end.
