{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - IDeclSource, where the decl files are     }
{                                                                              }
{  The part of idFileSystem the declaration manager uses (ListFiles,           }
{  ReadFile, OpenFileWrite). Written from the description of the calls; the    }
{  manager gets it from its constructor, nothing here touches the disk.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later; the      }
{  parts derived from Doom 3 are GPL v3 with the additional terms of id.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Source.Intf;

interface

type
  /// <summary>
  ///   The files of declarations. Names use '/' and are relative to the game; they are compared without
  ///   regard to case. A game that keeps its files in a PK4 or in the file system of <c>Libs\Wad</c>
  ///   implements this interface over it; the tests use <c>TDeclMemorySource</c>.
  /// </summary>
  IDeclSource = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0001}']
    /// <summary>
    ///   <c>fileSystem->ListFiles(folder, extension, true)</c>: the files below the folder (subfolders too)
    ///   whose name ends with the extension, as paths relative to the folder, sorted
    /// </summary>
    function ListFiles(const AFolder, AExtension: AnsiString): TArray<AnsiString>;
    /// <summary><c>ReadFile(name, &buffer, &timestamp)</c>: the whole text and the time of the file; false if it does not exist</summary>
    function TryReadFile(const AName: AnsiString; out AText: AnsiString; out ATimestamp: Int64): Boolean;
    /// <summary><c>ReadFile(name, NULL, &timestamp)</c>: only the length and the time</summary>
    function TryGetFileInfo(const AName: AnsiString; out ALength: Integer; out ATimestamp: Int64): Boolean;
    /// <summary>Writes a whole file (the editors' <c>OpenFileWrite(name, "fs_devpath")</c>); false if it cannot be written</summary>
    function WriteFile(const AName, AText: AnsiString): Boolean;
  end;

implementation

end.
