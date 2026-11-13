{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: contracts               }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): the public        }
{  surface of idFileSystem (framework\FileSystem.h) split in small            }
{  interfaces. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company.                                                                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Types;

type
  /// <summary>
  ///   The disk as the file system needs it: a file can be opened, a folder listed. It is injected so
  ///   that the tests use a disk in memory. Paths are the OS paths the file system builds (with the
  ///   separator of the platform); the disk decides how much the case counts.
  /// </summary>
  IGameDisk = interface
    ['{A41D7E92-0B35-4C68-9F1A-6E28D3B05C74}']
    /// <summary>
    ///   Sys_ListFiles: the names (no folder) in ADirectory. AExtension '/' means the folders; any other
    ///   text, such as '.pk4' or '', the files whose name ends with it (compared without case). Empty
    ///   when the folder is not there. The entries '.' and '..' are never returned (the file system
    ///   removes them anyway). The order is the one of the disk: the caller sorts if it matters
    /// </summary>
    function ListFiles(const ADirectory, AExtension: string): TArray<string>;
    /// <summary>A new stream to read a file, owned by the caller; nil when it is not there or is a folder</summary>
    function OpenRead(const AFileName: string): TStream;
    /// <summary>The last write time as seconds from 1970 (Sys_FileTimeStamp); 0 if the file is not there</summary>
    function FileTimestamp(const AFileName: string): Int64;
  end;

  /// <summary>The files of a pak (pack_t): a ZIP with the hash of its names already built</summary>
  IGamePack = interface
    ['{2B6F90C4-7D13-4A8E-B5E0-C19A47D8F326}']
    function GetFileName: string;
    function GetEntryCount: Integer;
    function GetChecksum: Cardinal;
    function GetLength: Int64;
    function GetIsAddon: Boolean;
    function GetReferenced: Boolean;
    procedure SetReferenced(AValue: Boolean);
    /// <summary>The name of entry AIndex as the file system compares it: lower case, '/' as separator</summary>
    function EntryName(AIndex: Integer): string;
    /// <summary>
    ///   The entry of a relative path (compared without case and with '\', '/' and ':' alike), -1 if there is
    ///   none. With the same name twice in the ZIP the last one wins
    /// </summary>
    function FindEntry(const ARelativePath: string): Integer;
    function EntrySize(AIndex: Integer): Int64;
    function ReadEntry(AIndex: Integer): TBytes;
    /// <summary>c:\doom\base\pak0.pk4</summary>
    property FileName: string read GetFileName;
    property EntryCount: Integer read GetEntryCount;
    /// <summary>
    ///   pack_t.checksum: MD4_BlockChecksum of the CRC-32 of the files that are not empty, in the order
    ///   of the ZIP. It is what a server asks for with the pure checksums
    /// </summary>
    property Checksum: Cardinal read GetChecksum;
    /// <summary>The size of the file of the pak</summary>
    property Length: Int64 read GetLength;
    /// <summary>It holds an addon.conf</summary>
    property IsAddon: Boolean read GetIsAddon;
    /// <summary>A file was read from it (the paks a pure server is told about)</summary>
    property Referenced: Boolean read GetReferenced write SetReferenced;
  end;

  /// <summary>LoadZipFile: makes a pak out of a file; nil when it cannot be opened or is not a ZIP</summary>
  IGamePackLoader = interface
    ['{C8E3A5F1-4D72-4B90-8A16-F07B2E9D3C45}']
    function Load(const AFileName: string): IGamePack;
  end;

  /// <summary>An open file for reading: a file of a folder or one inside a pak (idFile_Permanent, idFile_InZip)</summary>
  IGameFile = interface
    ['{57D0B8E6-A2C9-4F31-9E74-1B6A8C3D5F02}']
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Integer;
    function GetTimestamp: Int64;
    function GetPack: IGamePack;
    /// <summary>All the bytes of the file</summary>
    function ReadAll: TBytes;
    /// <summary>The path asked for, without the leading slash</summary>
    property Name: string read GetName;
    /// <summary>A file in a folder: its OS path; in a pak: the file of the pak, a slash and the name</summary>
    property FullPath: string read GetFullPath;
    property Length: Integer read GetLength;
    /// <summary>The write time of a file in a folder; 0 inside a pak (as idFile_InZip)</summary>
    property Timestamp: Int64 read GetTimestamp;
    /// <summary>The pak the file is in; nil for a file in a folder</summary>
    property Pack: IGamePack read GetPack;
  end;

  /// <summary>
  ///   The reading side of idFileSystem: search list of folders and paks, files by relative path, lists
  ///   of files by extension. Calls before Startup raise EGameFsException
  /// </summary>
  IGameFileSystem = interface
    ['{E1F47A93-6C28-4D05-B9A3-8D70C5E2146B}']
    /// <summary>Startup: builds the search list from the settings (cd, base, dev and save path, game_base and game)</summary>
    procedure Startup;
    /// <summary>Shutdown and Startup again (Restart)</summary>
    procedure Restart;
    /// <summary>Forgets the search list and the addon paks (Shutdown)</summary>
    procedure Shutdown;
    function IsInitialized: Boolean;
    /// <summary>
    ///   OpenFileRead / OpenFileReadFlags: the first file with that relative path in the search list (a
    ///   folder or a pak, the ones added last first); nil when there is none. A path with '..' or '::' is
    ///   never found. AGameDir, when not empty, limits the folders to that game folder (the paks are not
    ///   limited, as in the original)
    /// </summary>
    function OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags = [TGameSearchFlag.SearchDirs, TGameSearchFlag.SearchPaks];
      const AGameDir: string = ''): IGameFile;
    /// <summary>ReadFile: the bytes of a file; False when it is not there. An empty name raises EGameFsException</summary>
    function ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
    /// <summary>ReadFile with no buffer: the length of the file, -1 when it is not there</summary>
    function FileLength(const ARelativePath: string): Integer;
    /// <summary>FileIsInPAK: the file is in a pak of the search list (folders do not count)</summary>
    function FileIsInPak(const ARelativePath: string): Boolean;
    /// <summary>
    ///   ListFiles: the files of a relative folder whose name ends with one of the extensions (separated
    ///   by '|'; '/' means the folders), each name once whatever the case, from folders and paks
    /// </summary>
    function ListFiles(const ARelativePath, AExtension: string; ASort: Boolean = False;
      AFullRelativePath: Boolean = False; const AGameDir: string = ''): TArray<string>;
    /// <summary>ListFilesTree: like ListFiles but also the subfolders, always with the full relative path</summary>
    function ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean = False;
      const AGameDir: string = ''): TArray<string>;
    /// <summary>The search list in the order it is searched (the "path" command)</summary>
    function SearchPaths: TArray<TGameSearchPath>;
    /// <summary>The paks that are in the search list, in order; their checksums are what the pure server uses</summary>
    function PackChecksums: TArray<Cardinal>;
    /// <summary>The addon paks that were left out of the search list</summary>
    function AddonPackFileNames: TArray<string>;
  end;

implementation

end.
