{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the small interfaces of the script parser of  }
{  Quake III Arena (what botimport gave to l_script.c and l_precomp.c)         }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib.     }
{  Copyright (C) 1999-2005 Id Software, Inc. Licensed under the GNU General    }
{  Public License, version 2 or later.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>botimport.Print: where the errors and warnings of the parser go</summary>
  IQ3ScriptLog = interface
    ['{5E0C2B6A-3D41-4E0F-9B6C-0A7C1D2E3F41}']
    /// <summary>One message, already formatted as "file F, line N: text" with its line feed</summary>
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
  end;

  /// <summary>botimport.FS_FOpenFile, FS_Read and FS_FCloseFile as one call</summary>
  IQ3ScriptFiles = interface
    ['{7A1D9C34-5B2E-4F60-8C7D-1B8D2E3F4A52}']
    /// <summary>The whole file with the given path (relative to the game), or False if it is not there</summary>
    function TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

implementation

end.
