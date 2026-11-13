{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 profile, composition                 }
{                                                                              }
{  Assembles the command system and the cvar system of Doom 3 (the two         }
{  singletons cmdSystem and cvarSystem) as objects that reference each other   }
{  only through interfaces. The one place that knows the concrete classes.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.IdTech4.Factory;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Console.CmdSystem.System,
  DelphiDoom.Console.CmdSystem.FolderCompletion, DelphiDoom.Console.CmdSystem.StandardCommands,
  DelphiDoom.Console.CVar.Intf, DelphiDoom.Console.CVar.System, DelphiDoom.Console.CVar.Commands;

type
  /// <summary>
  ///   The idTech 4 profile of the console: a command system and a cvar system that know each other
  ///   (a line that is not a command is a variable, "$name" and vstr read variables, set and
  ///   toggle are commands), with their own commands registered (idCmdSystem::Init and
  ///   idCVarSystem::Init). It is separate from the console of the DelphiDoom engine (<c>ICommandRegistry</c>)
  ///   and does not change it. The objects are its own, not singletons: make as many as needed.
  /// </summary>
  TIdTech4Console = class
  strict private
    FCmdSystem: TCmdSystem;
    FCmdCommands: ICmdCommands;
    FCmdBuffer: ICmdBuffer;
    FCVars: ICVarSystem;
    FFolderCompletion: TCmdFolderCompletion;
    FStandardCommands: TCmdStandardCommands;
    FCVarCommands: TCVarCommands;
  public
    /// <summary>
    ///   The log, the session, the file system (exec) and the file lister (completion of file
    ///   names) are optional
    /// </summary>
    constructor Create(const ALog: IIdLibLog = nil; const ASession: IConsoleSession = nil;
      const AFileSystem: IIdLibFileSystem = nil; const AFileLister: ICmdFileLister = nil);
    destructor Destroy; override;
    /// <summary>Init of both systems: registers their commands and marks the cvar system initialized</summary>
    procedure Init;
    /// <summary>Shutdown of both systems</summary>
    procedure Shutdown;
    property Commands: ICmdCommands read FCmdCommands;
    property Buffer: ICmdBuffer read FCmdBuffer;
    property CVars: ICVarSystem read FCVars;
  end;

implementation

{ TIdTech4Console }

constructor TIdTech4Console.Create(const ALog: IIdLibLog; const ASession: IConsoleSession;
  const AFileSystem: IIdLibFileSystem; const AFileLister: ICmdFileLister);
var
  LCVarSystem: TCVarSystem;
begin
  inherited Create;
  // the interface references keep the systems alive; FCmdSystem is only the way to call Shutdown
  LCVarSystem := TCVarSystem.Create(ALog, ASession);
  FCVars := LCVarSystem;
  FCmdSystem := TCmdSystem.Create(ALog, ASession, LCVarSystem, LCVarSystem);
  FCmdCommands := FCmdSystem;
  FCmdBuffer := FCmdSystem;
  if Assigned(AFileLister) then
    FFolderCompletion := TCmdFolderCompletion.Create(AFileLister);
  FStandardCommands := TCmdStandardCommands.Create(FCmdCommands, FCmdBuffer, ALog, AFileSystem, LCVarSystem,
    FFolderCompletion);
  FCVarCommands := TCVarCommands.Create(FCmdCommands, FCVars, ALog);
end;

destructor TIdTech4Console.Destroy;
begin
  FCVarCommands.Free;
  FStandardCommands.Free;
  FFolderCompletion.Free;
  FCmdCommands := nil;
  FCmdBuffer := nil;
  FCVars := nil;
  inherited Destroy;
end;

procedure TIdTech4Console.Init;
begin
  FStandardCommands.Register;
  FCVars.Init;
  FCVarCommands.Register;
end;

procedure TIdTech4Console.Shutdown;
begin
  FCmdSystem.Shutdown;
  FCVars.Shutdown;
end;

end.
