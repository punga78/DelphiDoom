{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: writing, contracts      }
{                                                                              }
{  Port of the writing side of the file system of Doom 3 (id Software, GPL     }
{  v3): OpenFileWrite, OpenFileAppend, WriteFile, RemoveFile and               }
{  RelativePathToOSPath of framework\FileSystem.cpp. Copyright (C) 1999-2011   }
{  id Software LLC, a ZeniMax Media company.                                   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Write.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Types;

type
  /// <summary>
  ///   The disk as the writing side of the file system needs it. It is injected so that the tests use a
  ///   disk in memory. Paths are OS paths (the file system builds them with the separator of the platform).
  /// </summary>
  IGameDiskWriter = interface
    ['{4C7A2E18-D9B3-4F60-8E15-A3B07C6D2F94}']
    /// <summary>Sys_Mkdir: creates one folder (its parent must exist); True if it is there afterwards</summary>
    function CreateDirectory(const ADirectory: string): Boolean;
    /// <summary>
    ///   A new stream to write a file, owned by the caller: the file is emptied, or with <c>AAppend</c> the
    ///   position is the end of the file. nil when the file cannot be opened
    /// </summary>
    function OpenWrite(const AFileName: string; AAppend: Boolean): TStream;
    /// <summary>remove(): False when the file is not there or cannot be removed</summary>
    function RemoveFile(const AFileName: string): Boolean;
  end;

  /// <summary>An open file for writing (idFile_Permanent opened with "wb" or "ab")</summary>
  IGameWriteFile = interface
    ['{B2E86D03-5F4A-4719-9C0B-E6A1D8723F55}']
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Int64;
    function GetIsAppend: Boolean;
    /// <summary>Appends the bytes at the current end; returns how many were written</summary>
    function Write(const ABytes: TBytes): Integer;
    /// <summary>Appends the bytes of a text as they are; returns how many were written</summary>
    function WriteText(const AText: AnsiString): Integer;
    /// <summary>idFile::Flush</summary>
    procedure Flush;
    /// <summary>The path asked for, without the leading slash</summary>
    property Name: string read GetName;
    /// <summary>The OS path of the file</summary>
    property FullPath: string read GetFullPath;
    /// <summary>The bytes the file holds: written by this object, plus the ones an appended file already had</summary>
    property Length: Int64 read GetLength;
    /// <summary>It was opened with OpenFileAppend</summary>
    property IsAppend: Boolean read GetIsAppend;
  end;

  /// <summary>The writing side of idFileSystem: files go to the save path (or the one asked for) below the game folder</summary>
  IGameFileWriter = interface
    ['{7F0D4A92-1E86-4B35-A7C9-52D8E3B10A6C}']
    /// <summary>
    ///   OpenFileWrite: creates the folders and a file that is empty; nil when it cannot be opened. A path
    ///   with '..' or '::' is refused (nil): the original only refuses to create the folders for it.
    ///   Raises EGameFsException before Startup
    /// </summary>
    function OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    /// <summary>OpenFileAppend: like OpenFileWrite but the file keeps what it has; <c>ASync</c> flushes after each write</summary>
    function OpenFileAppend(const ARelativePath: string; ASync: Boolean = False;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    /// <summary>WriteFile: the whole file in one call; the number of bytes written, -1 when it cannot be opened</summary>
    function WriteFile(const ARelativePath: string; const AData: TBytes;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): Integer;
    /// <summary>RemoveFile: removes the file from the dev path (if there is one) and from the save path</summary>
    procedure RemoveFile(const ARelativePath: string);
    /// <summary>RelativePathToOSPath: the OS path a relative path is written to</summary>
    function RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): string;
  end;

implementation

end.
