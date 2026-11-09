{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the virtual files of the mods (what the   }
{  rules ask of FileMap)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ModFiles.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf;

type
  /// <summary>
  ///   The files of the active mods as one tree (FileMap): a file of a mod hides the one with the same path in
  ///   the mods before it. The rules use it for the lists of soldier names
  /// </summary>
  IXcomModFiles = interface
    ['{B3A7D1F4-5C2E-4E80-9A16-7D40E8C2B953}']
    /// <summary>getVFolderContents: the names of the files and folders in a virtual folder (path ending in /)</summary>
    function FolderContents(const AVirtualFolder: string): TArray<string>;
    /// <summary>getFilePath + LoadFile: the YAML document of a virtual file</summary>
    function LoadYaml(const AVirtualFile: string): IYamlNode;
    /// <summary>getFilePath + the bytes of the file (the data of the globe); a missing file is EXcomModException</summary>
    function LoadBytes(const AVirtualFile: string): TBytes;
  end;

implementation

end.
