{******************************************************************************}
{                                                                              }
{  DelphiDoom: table export library - the contracts of the saving of a file    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Saver.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>What the saving of an export needs from the engine: the console, the folder of the saved files and the disk</summary>
  ITableExportOutput = interface
    ['{C93E5A71-0B24-4D86-8F1A-6E7B2D40A9C3}']
    /// <summary>Writes a text on the console (the old printf)</summary>
    procedure Print(const AText: string);
    /// <summary>The name of a file in the folder of the saved files (the old M_SaveFileName)</summary>
    function SaveFileName(const AName: string): string;
    /// <summary>Writes the lines to the file, each one followed by a line break</summary>
    procedure SaveLines(const AFileName: string; const ALines: TArray<string>);
  end;

  /// <summary>Saves an export (a patch, an ACTORDEF, a CSV, the Pascal source of the tables) to a file</summary>
  ITableExportSaver = interface
    ['{18D7B4F2-A5E0-4C39-9B62-F30C81E5D7A4}']
    /// <summary>
    ///   Saves what ALines gives. With an empty name only AMissingMessage is printed (the lines are
    ///   not computed). A name without a point gets ADefaultExtension; the file goes to the
    ///   folder of the saved files; ASavedFormat (with one %s for the file name) is printed after
    ///   it
    /// </summary>
    procedure SaveLines(const AName, ADefaultExtension, AMissingMessage, ASavedFormat: string;
      const ALines: TFunc<TArray<string>>);
    /// <summary>As SaveLines, for a text: it is cut into lines as a list of strings does when its text is set</summary>
    procedure SaveText(const AName, ADefaultExtension, AMissingMessage, ASavedFormat: string;
      const AText: TFunc<string>);
  end;

implementation

end.
