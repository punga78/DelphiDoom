{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvar system, contract                }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.h (idCVarSystem).}
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.Intf;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CVar.Types,
  DelphiDoom.Console.CVar.Variable;

type
  /// <summary>
  ///   idCVarSystem without the reading of values by name (ICVarReader) and the line command
  ///   (ICVarCommand), which the command system asks of it. The variables it gives are owned by
  ///   the system.
  /// </summary>
  ICVarSystem = interface
    ['{5A93D1E8-7C20-4B64-9F3A-D08E62B715C4}']
    procedure Init;
    procedure Shutdown;
    function IsInitialized: Boolean;
    /// <summary>
    ///   Registers a declaration. The first declaration of a name makes the variable; the next
    ///   ones are merged into it (idCVarSystemLocal::Register). A boolean variable without
    ///   completion gets "name 0" and "name 1"
    /// </summary>
    function Register(const ADefinition: TCVarDefinition): TCVar;
    /// <summary>The variable with the name (not case sensitive), nil if there is none</summary>
    function Find(const AName: AnsiString): TCVar;
    /// <summary>Sets a variable by name, making it if it does not exist; AFlags are added to it</summary>
    procedure SetCVarString(const AName, AValue: AnsiString; const AFlags: Integer = 0);
    procedure SetCVarBool(const AName: AnsiString; const AValue: Boolean; const AFlags: Integer = 0);
    procedure SetCVarInteger(const AName: AnsiString; const AValue: Integer; const AFlags: Integer = 0);
    procedure SetCVarFloat(const AName: AnsiString; const AValue: Single; const AFlags: Integer = 0);
    /// <summary>The name of each variable to the callback, in the order they were made</summary>
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    /// <summary>The value completion of the variable named by the first word, if it has one</summary>
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    procedure SetModifiedFlags(const AFlags: Integer);
    function GetModifiedFlags: Integer;
    procedure ClearModifiedFlags(const AFlags: Integer);
    /// <summary>Resets (to the reset value, forced) the variables with one of the flags</summary>
    procedure ResetFlaggedVariables(const AFlags: Integer);
    /// <summary>Removes the value completion of the variables with one of the flags</summary>
    procedure RemoveFlaggedAutoCompletion(const AFlags: Integer);
    /// <summary>
    ///   The lines <c>setCmd name "value"</c> (each ended by a line feed) of the variables with one
    ///   of the flags, to be written to a file (WriteFlaggedVariables)
    /// </summary>
    function WriteFlaggedVariables(const AFlags: Integer; const ASetCommand: AnsiString): AnsiString;
    /// <summary>
    ///   The variables with one of the flags in a dictionary that belongs to the system and is
    ///   emptied by the next call (MoveCVarsToDict)
    /// </summary>
    function MoveCVarsToDict(const AFlags: Integer): TIdDict;
    /// <summary>Gives each variable named in the dictionary the value there, as sent by the server</summary>
    procedure SetCVarsFromDict(const ADict: TIdDict);
    function Count: Integer;
    /// <summary>The variables in the order they were made</summary>
    function Item(const AIndex: Integer): TCVar;
    /// <summary>
    ///   cvar_restart: every variable that is not read only or init goes back to its reset value, and
    ///   the ones the user made (not static) are removed
    /// </summary>
    procedure Restart;
  end;

implementation

end.
