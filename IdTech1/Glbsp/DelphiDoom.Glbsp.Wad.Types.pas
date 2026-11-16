{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - shared types and constants of the WAD model             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of wad.h / structs.h of glBSP 2.24 (C) 2000-2007 Andrew Apted          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Wad.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The level information holds GL lumps</summary>
  LEVEL_IS_GL = $0002;

  // Limit flags: they show what went wrong while building a level
  LIMIT_VERTEXES = $000001;
  LIMIT_SECTORS = $000002;
  LIMIT_SIDEDEFS = $000004;
  LIMIT_LINEDEFS = $000008;
  LIMIT_SEGS = $000010;
  LIMIT_SSECTORS = $000020;
  LIMIT_NODES = $000040;
  LIMIT_GL_VERT = $000100;
  LIMIT_GL_SEGS = $000200;
  LIMIT_GL_SSECT = $000400;
  LIMIT_GL_NODES = $000800;
  LIMIT_BAD_SIDE = $001000;
  LIMIT_BMAP_TRUNC = $002000;
  LIMIT_BLOCKMAP = $004000;
  LIMIT_ZDBSP = $008000;

  /// <summary>The lump is copied from the input WAD when it is written</summary>
  LUMP_COPY_ME = $0004;
  /// <summary>The lump is not written to the output WAD</summary>
  LUMP_IGNORE_ME = $0008;
  /// <summary>The lump has to be loaded in memory</summary>
  LUMP_READ_ME = $0100;
  /// <summary>The lump is new (it did not exist in the input WAD)</summary>
  LUMP_NEW = $0200;

  WAD_HEADER_SIZE = 12;
  WAD_ENTRY_SIZE = 16;
  WAD_LUMP_NAME_SIZE = 8;

type
  TGlbspWadKind = (wkIWad, wkPWad);

  /// <summary>Header of a WAD file as it is stored on disk (little endian)</summary>
  TRawWadHeader = packed record
    MagicType: array[0..3] of AnsiChar;
    NumEntries: Integer;
    DirStart: Integer;
  end;

  /// <summary>Entry of the directory of a WAD file as it is stored on disk</summary>
  TRawWadEntry = packed record
    Start: Integer;
    Length: Integer;
    Name: array[0..WAD_LUMP_NAME_SIZE - 1] of AnsiChar;
  end;

  /// <summary>Raised when a WAD cannot be read, written or is inconsistent</summary>
  EGlbspWadException = class(Exception);

implementation

end.
