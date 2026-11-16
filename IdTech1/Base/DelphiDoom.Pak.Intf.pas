{******************************************************************************}
{                                                                              }
{  DelphiDoom: PAK - what the engine asks of the PAK file system               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit DelphiDoom.Pak.Intf;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Pak.EntryReader;

type
  /// <summary>
  ///   The files of the PAK file system: the files on disk and the entries of the PAK, PK3, PK4,
  ///   WAD2/WAD3 and of the WAD with PK3ENTRY, HI_START and TX_START that were added
  /// </summary>
  IPakFileSystem = interface
    ['{C3E5A1F7-6B28-4D94-9E0A-57B2D8C4F163}']
    /// <summary>
    ///   A stream on AFileName (TPakStream of the engine): IOResult is not 0 when nothing was
    ///   found. The caller frees it
    /// </summary>
    function Open(const AFileName: string; AMode: TPakLookupMode;
      const APreferred: TArray<string>; const ADirectory: string): TDStream;
    /// <summary>A stream on the entry number AIndex; IOResult is not 0 when it cannot be read</summary>
    function OpenEntry(AIndex: Integer): TDStream;
    /// <summary>
    ///   The rules of the engine to open a name: ADisk and AEntry are asked as TPakPathResolver
    ///   says (the streams open their files with it)
    /// </summary>
    function Locate(const AFileName: string; AMode: TPakLookupMode; const APreferred: TArray<string>;
      const ADirectory: string; const ADisk: TPakDiskOpener; const AEntry: TPakEntryOpener): Boolean;
    /// <summary>The bytes of the entry AIndex, or nil with a warning when they cannot be read</summary>
    function ReadEntry(AIndex: Integer): TPakEntryReader;
    /// <summary>The entries with the short name of AName, from the first added</summary>
    function MatchingEntries(const AName: string): TArray<Integer>;
    function EntryCount: Integer;
    /// <summary>The upper case path of the entry AIndex</summary>
    function EntryName(AIndex: Integer): string;
    /// <summary>The text of every entry named AName, from the first added (PAK_StringIterator)</summary>
    function Texts(const AName: string): TArray<string>;
    /// <summary>The text of the last entry named AName, or '' (PAK_ReadFileAsString)</summary>
    function ReadText(const AName: string): string;
    /// <summary>The texts of every entry named AName, each one followed by CR LF</summary>
    function ReadAllTexts(const AName: string): string;
    /// <summary>The hash of all the entries (the names of the cache files of the PK3 textures)</summary>
    function GlobalHash: Cardinal;
  end;

  /// <summary>
  ///   The files that make the PAK file system. Before Initialize the files and the folders
  ///   wait in a list; they are added at the first call after it
  /// </summary>
  IPakContainers = interface
    ['{8A4D02B6-E15C-4F37-B9D8-3C6F1A07E2B9}']
    /// <summary>Starts an empty file system (PAK_InitFileSystem)</summary>
    procedure Initialize;
    /// <summary>Forgets every file (PAK_ShutDown)</summary>
    procedure ShutDown;
    /// <summary>A PAK, PK3, PK4, WAD, WAD2/3 or a folder; False when it could not be added</summary>
    function AddFile(const AFileName: string): Boolean;
    /// <summary>The PAK, PK3, PK4, WAD and IWAD files of a folder</summary>
    procedure AddDirectory(const APath: string);
    /// <summary>Adds what was given before Initialize</summary>
    procedure LoadPending;
  end;

implementation

end.
