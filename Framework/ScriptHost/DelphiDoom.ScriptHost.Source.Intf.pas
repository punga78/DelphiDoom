{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the contract of the files that scripts read       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Source.Intf;

interface

type
  /// <summary>
  ///   Where the files of the scripts come from (the PAK files and the folders of the engine): the
  ///   files that a script includes with {$I}, and the .ddscript and .ddout of a map
  /// </summary>
  IScriptSourceProvider = interface
    ['{2F8D6A41-B7E3-4C09-95A2-6D1E0C38F7B5}']
    /// <summary>The text of a file; empty if there is no such file</summary>
    function ReadText(const AFileName: string): string;
  end;

implementation

end.
