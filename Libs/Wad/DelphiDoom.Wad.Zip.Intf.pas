{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - the entries of a ZIP as they are stored           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Zip.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The central directory of a ZIP seen without the lump rules of IWadSource: every entry, folders
  ///   included, with the name as stored, the CRC-32 and the size. The file system of id Tech 4 needs
  ///   exactly this (folder entries to list folders, CRCs for the checksum of a pak).
  /// </summary>
  IZipArchive = interface
    ['{4E9A1C73-D2B8-4F05-A6C1-93E7B0D5F248}']
    /// <summary>The name of the file the archive was read from</summary>
    function ArchiveName: string;
    function ArchiveEntryCount: Integer;
    /// <summary>The name as stored (a folder entry ends with a slash); raises EWadException if out of range</summary>
    function ArchiveEntryName(AIndex: Integer): string;
    function ArchiveEntryCrc(AIndex: Integer): Cardinal;
    function ArchiveEntrySize(AIndex: Integer): Int64;
    /// <summary>The uncompressed bytes of an entry</summary>
    function ReadArchiveEntry(AIndex: Integer): TBytes;
  end;

implementation

end.
