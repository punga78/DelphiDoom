{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvars, the commands                  }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.cpp              }
{  (Toggle_f, Set_f, SetS_f, SetU_f, SetT_f, SetA_f, Reset_f, List_f,          }
{  Restart_f and idCVarSystemLocal::Init).                                     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.Commands;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Intf,
  DelphiDoom.Console.CVar.Intf, DelphiDoom.Console.CVar.Lister;

type
  /// <summary>
  ///   The commands of the cvar system: toggle, set, sets, setu, sett, seta, reset, listCvars and
  ///   cvar_restart. They are methods of this object, registered in a command system with
  ///   <c>Register</c> (the body of idCVarSystemLocal::Init).
  /// </summary>
  TCVarCommands = class
  strict private
    FCommands: ICmdCommands;
    FCVars: ICVarSystem;
    FLog: IIdLibLog;
    FLister: TCVarLister;
    procedure Print(const AText: string);
  public
    constructor Create(const ACommands: ICmdCommands; const ACVars: ICVarSystem; const ALog: IIdLibLog);
    destructor Destroy; override;
    procedure Register;
    procedure Toggle(const AArgs: TIdCmdArgs);
    procedure SetCommand(const AArgs: TIdCmdArgs);
    /// <summary>sets: set and flag as server info and archive</summary>
    procedure SetServerInfo(const AArgs: TIdCmdArgs);
    /// <summary>setu: set and flag as user info and archive</summary>
    procedure SetUserInfo(const AArgs: TIdCmdArgs);
    /// <summary>sett: set and flag as tool</summary>
    procedure SetTool(const AArgs: TIdCmdArgs);
    /// <summary>seta: set (the original does not flag it as archive: it is commented out)</summary>
    procedure SetArchive(const AArgs: TIdCmdArgs);
    procedure ResetCommand(const AArgs: TIdCmdArgs);
    procedure ListCvars(const AArgs: TIdCmdArgs);
    procedure Restart(const AArgs: TIdCmdArgs);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Console.CVar.Types, DelphiDoom.Console.CVar.Variable;

{ TCVarCommands }

constructor TCVarCommands.Create(const ACommands: ICmdCommands; const ACVars: ICVarSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FCommands := ACommands;
  FCVars := ACVars;
  FLog := ALog;
  FLister := TCVarLister.Create(ACVars, ALog);
end;

destructor TCVarCommands.Destroy;
begin
  FLister.Free;
  inherited Destroy;
end;

procedure TCVarCommands.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

procedure TCVarCommands.Register;
begin
  FCommands.AddCommand('toggle', Toggle, CMD_FL_SYSTEM, 'toggles a cvar');
  FCommands.AddCommand('set', SetCommand, CMD_FL_SYSTEM, 'sets a cvar');
  FCommands.AddCommand('sets', SetServerInfo, CMD_FL_SYSTEM, 'sets a cvar and flags it as server info');
  FCommands.AddCommand('setu', SetUserInfo, CMD_FL_SYSTEM, 'sets a cvar and flags it as user info');
  FCommands.AddCommand('sett', SetTool, CMD_FL_SYSTEM, 'sets a cvar and flags it as tool');
  FCommands.AddCommand('seta', SetArchive, CMD_FL_SYSTEM, 'sets a cvar and flags it as archive');
  FCommands.AddCommand('reset', ResetCommand, CMD_FL_SYSTEM, 'resets a cvar');
  FCommands.AddCommand('listCvars', ListCvars, CMD_FL_SYSTEM, 'lists cvars');
  FCommands.AddCommand('cvar_restart', Restart, CMD_FL_SYSTEM, 'restart the cvar system');
end;

procedure TCVarCommands.Toggle(const AArgs: TIdCmdArgs);
var
  LArgc, LIndex: Integer;
  LCurrent, LSet: Single;
  LText: AnsiString;
  LVariable: TCVar;
begin
  LArgc := AArgs.Argc;
  if LArgc < 2 then
  begin
    Print('usage:'#10 +
      '   toggle <variable>  - toggles between 0 and 1'#10 +
      '   toggle <variable> <value> - toggles between 0 and <value>'#10 +
      '   toggle <variable> [string 1] [string 2]...[string n] - cycles through all strings'#10);
    Exit;
  end;

  LVariable := FCVars.Find(AArgs.Argv(1));

  if LVariable = nil then
  begin
    if Assigned(FLog) then
      FLog.Warning('Toggle_f: cvar "' + string(AArgs.Argv(1)) + '" not found');
    Exit;
  end;

  if LArgc > 3 then
  begin
    // cycle through multiple values
    LText := LVariable.GetString;
    LIndex := 2;
    while LIndex < LArgc do
    begin
      if TIdStrings.Icmp(LText, AArgs.Argv(LIndex)) = 0 then
      begin
        // point to next value
        Inc(LIndex);
        Break;
      end;
      Inc(LIndex);
    end;
    if LIndex >= LArgc then
      LIndex := 2;

    Print('set ' + string(AArgs.Argv(1)) + ' = ' + string(AArgs.Argv(LIndex)) + #10);
    LVariable.SetValue(AArgs.Argv(LIndex), False, False);
  end
  else
  begin
    // toggle between 0 and 1
    LCurrent := LVariable.GetFloat;
    if LArgc = 3 then
      LSet := TIdCNumbers.Atof(AArgs.Argv(2))
    else
      LSet := 1.0;
    if LCurrent = 0.0 then
      LCurrent := LSet
    else
      LCurrent := 0.0;
    Print('set ' + string(AArgs.Argv(1)) + ' = ' + string(TIdStrings.FloatToPlainText(LCurrent)) + #10);
    LVariable.SetValue(TIdStrings.FloatToText(LCurrent), False, False);
  end;
end;

procedure TCVarCommands.SetCommand(const AArgs: TIdCmdArgs);
begin
  FCVars.SetCVarString(AArgs.Argv(1), AArgs.Args(2, AArgs.Argc - 1));
end;

procedure TCVarCommands.SetServerInfo(const AArgs: TIdCmdArgs);
var
  LVariable: TCVar;
begin
  SetCommand(AArgs);
  LVariable := FCVars.Find(AArgs.Argv(1));
  if LVariable = nil then
    Exit;
  LVariable.AddFlags(CVAR_SERVERINFO or CVAR_ARCHIVE);
end;

procedure TCVarCommands.SetUserInfo(const AArgs: TIdCmdArgs);
var
  LVariable: TCVar;
begin
  SetCommand(AArgs);
  LVariable := FCVars.Find(AArgs.Argv(1));
  if LVariable = nil then
    Exit;
  LVariable.AddFlags(CVAR_USERINFO or CVAR_ARCHIVE);
end;

procedure TCVarCommands.SetTool(const AArgs: TIdCmdArgs);
var
  LVariable: TCVar;
begin
  SetCommand(AArgs);
  LVariable := FCVars.Find(AArgs.Argv(1));
  if LVariable = nil then
    Exit;
  LVariable.AddFlags(CVAR_TOOL);
end;

procedure TCVarCommands.SetArchive(const AArgs: TIdCmdArgs);
begin
  // the original looks the variable up and does nothing with it (obsolete variables must not be saved)
  SetCommand(AArgs);
end;

procedure TCVarCommands.ResetCommand(const AArgs: TIdCmdArgs);
var
  LVariable: TCVar;
begin
  if AArgs.Argc <> 2 then
  begin
    Print('usage: reset <variable>'#10);
    Exit;
  end;
  LVariable := FCVars.Find(AArgs.Argv(1));
  if LVariable = nil then
    Exit;
  LVariable.Reset;
end;

procedure TCVarCommands.ListCvars(const AArgs: TIdCmdArgs);
begin
  FLister.ListByFlags(AArgs, CVAR_ALL);
end;

procedure TCVarCommands.Restart(const AArgs: TIdCmdArgs);
begin
  FCVars.Restart;
end;

end.
