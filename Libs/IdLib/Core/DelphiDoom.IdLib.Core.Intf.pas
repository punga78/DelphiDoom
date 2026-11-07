{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib core - the services idLib asks of the engine              }
{                                                                              }
{  Replaces the singletons idLib::common and idLib::fileSystem of Doom 3       }
{  (idlib\Lib.h): a class that needs them gets them from its constructor.      }
{  Port of idLib (id Software, Doom 3, GPL v3), see README.md of Libs\IdLib.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later; the      }
{  parts derived from Doom 3 are GPL v3 with the additional terms of id.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Core.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Where idLib writes what <c>common->Printf</c>, <c>Warning</c> and <c>DWarning</c> printed.
  ///   Errors are not here: <c>common->Error</c> is an exception (EIdLibException). A class
  ///   that gets a nil log stays silent.
  /// </summary>
  IIdLibLog = interface
    ['{0B6E6A1C-5C0F-4F5B-9E58-2A3D6E7C1F01}']
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  /// <summary>A file that idLib read: the bytes, the name the file system resolved and its time</summary>
  TIdLibFileData = record
    Data: TBytes;
    /// <summary>idFile::GetFullPath</summary>
    FullPath: AnsiString;
    /// <summary>idFile::Timestamp</summary>
    Timestamp: Int64;
  end;

  /// <summary>
  ///   The part of idFileSystem that idLib uses (idLexer::LoadFile, idLangDict, idMapFile):
  ///   read a whole file and write a whole file
  /// </summary>
  IIdLibFileSystem = interface
    ['{0B6E6A1C-5C0F-4F5B-9E58-2A3D6E7C1F02}']
    /// <summary>
    ///   Reads a file, <c>AIsOsPath</c> = OpenExplicitFileRead (a path of the operating system) instead of
    ///   OpenFileRead (a path relative to the game); false if it does not exist
    /// </summary>
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    /// <summary>Writes a whole file; false if it cannot be written</summary>
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

implementation

end.
