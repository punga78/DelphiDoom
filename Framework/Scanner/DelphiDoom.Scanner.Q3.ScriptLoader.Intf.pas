{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - IQ3ScriptLoader, how the precompiler of       }
{  Quake III Arena gets the scripts it reads                                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software), code\botlib\    }
{  l_script.c. Licensed under the GNU General Public License, version 2 or     }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.ScriptLoader.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Scanner.Q3.Script;

type
  /// <summary>LoadScriptFile, LoadScriptMemory and PS_SetBaseFolder: the scripts the precompiler reads</summary>
  IQ3ScriptLoader = interface
    ['{2B8E4F10-6C3A-4D75-A1E9-3F5B7C9D0E63}']
    /// <summary>LoadScriptFile: nil if the file is not there; the caller owns the script</summary>
    function LoadFile(const AFileName: AnsiString): TQ3Script;
    /// <summary>LoadScriptMemory: a script made of a copy of the text; the caller owns it</summary>
    function LoadMemory(const AText: TBytes; const AName: AnsiString): TQ3Script;
    /// <summary>PS_SetBaseFolder: the folder the files are read from ("" for none)</summary>
    procedure SetBaseFolder(const APath: AnsiString);
  end;

implementation

end.
