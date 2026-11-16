{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, the commands of cvar.c     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cvar.c          }
{  (Cvar_Command, Cvar_Toggle_f, Cvar_Set_f, Cvar_SetU_f, Cvar_SetS_f,         }
{  Cvar_SetA_f, Cvar_Reset_f, Cvar_List_f, Cvar_Restart_f).                    }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.CVarCommands;

interface

uses
  System.SysUtils, System.Generics.Defaults,DelphiDoom.IdLib.Text.Strings, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Console.Q3.CVar, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   <c>toggle</c>, <c>set</c>, <c>sets</c>, <c>setu</c>, <c>seta</c>, <c>reset</c>, <c>cvarlist</c> and
  ///   <c>cvar_restart</c>, and the handling of a line that starts with a variable name. The class is not
  ///   reference counted: the command system holds it as <c>IQ3CVarCommandHandler</c> and the commands it
  ///   registers are its methods. <c>set</c> joins the arguments from the third with spaces and stops
  ///   adding when their length (each without its first character, as the original counts) reaches 1022;
  ///   an empty argument counts as 0 (the original reads past it)
  /// </summary>
  TQ3CVarCommands = class(TSingletonImplementation, IQ3CVarCommandHandler)
  strict private
    FRegistry: IQ3CommandRegistry;
    FCVars: IQ3CVarSystem;
    FArguments: IQ3CommandArguments;
    FLog: IQ3ConsoleLog;
    procedure Print(const AText: string);
    procedure SetAndFlag(const AUsage: string; AFlag: Integer);
  public
    constructor Create(const ARegistry: IQ3CommandRegistry; const ACVars: IQ3CVarSystem;
      const AArguments: IQ3CommandArguments; const ALog: IQ3ConsoleLog = nil);
    /// <summary>The registration of Cvar_Init (after the variable system's own Init)</summary>
    procedure Init;
    function Command: Boolean;
    procedure Toggle;
    procedure SetCommand;
    procedure SetServerInfo;
    procedure SetUserInfo;
    procedure SetArchive;
    procedure ResetCommand;
    procedure List;
    procedure RestartCommand;
  end;

implementation

{ TQ3CVarCommands }

constructor TQ3CVarCommands.Create(const ARegistry: IQ3CommandRegistry; const ACVars: IQ3CVarSystem;
  const AArguments: IQ3CommandArguments; const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(ACVars) then
    raise EArgumentNilException.Create('ACVars');
  if not Assigned(AArguments) then
    raise EArgumentNilException.Create('AArguments');
  FRegistry := ARegistry;
  FCVars := ACVars;
  FArguments := AArguments;
  FLog := ALog;
end;

procedure TQ3CVarCommands.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

procedure TQ3CVarCommands.Init;
begin
  FRegistry.AddCommand('toggle', Toggle);
  FRegistry.AddCommand('set', SetCommand);
  FRegistry.AddCommand('sets', SetServerInfo);
  FRegistry.AddCommand('setu', SetUserInfo);
  FRegistry.AddCommand('seta', SetArchive);
  FRegistry.AddCommand('reset', ResetCommand);
  FRegistry.AddCommand('cvarlist', List);
  FRegistry.AddCommand('cvar_restart', RestartCommand);
end;

function TQ3CVarCommands.Command: Boolean;
var
  LVar: TQ3CVar;
begin
  LVar := FCVars.Find(FArguments.Argv(0));
  Result := Assigned(LVar);
  if not Result then
    Exit;
  if FArguments.Count = 1 then
  begin
    Print(Format('"%s" is:"%s%s" default:"%s%s"'#10, [string(LVar.Name), string(LVar.StringValue), Q3_COLOR_WHITE,
      string(LVar.ResetString), Q3_COLOR_WHITE]));
    if LVar.HasLatched then
      Print(Format('latched: "%s"'#10, [string(LVar.LatchedString)]));
    Exit;
  end;
  FCVars.Set2(LVar.Name, FArguments.Argv(1), False);
end;

procedure TQ3CVarCommands.Toggle;
var
  LValue: Integer;
begin
  if FArguments.Count <> 2 then
  begin
    Print('usage: toggle <variable>'#10);
    Exit;
  end;
  LValue := Trunc(FCVars.VariableValue(FArguments.Argv(1)));
  if LValue = 0 then
    LValue := 1
  else
    LValue := 0;
  FCVars.Set2(FArguments.Argv(1), AnsiString(IntToStr(LValue)), False);
end;

procedure TQ3CVarCommands.SetCommand;
var
  LIndex: Integer;
  LCombined: AnsiString;
  LArgument: AnsiString;
  LArgumentLength: Integer;
  LLength: Integer;
  LCount: Integer;
begin
  LCount := FArguments.Count;
  if LCount < 3 then
  begin
    Print('usage: set <variable> <value>'#10);
    Exit;
  end;
  LCombined := '';
  LLength := 0;
  for LIndex := 2 to LCount - 1 do
  begin
    LArgument := FArguments.Argv(LIndex);
    LArgumentLength := Length(LArgument) - 1;
    if LArgumentLength < 0 then
      LArgumentLength := 0;
    if LLength + LArgumentLength >= Q3_MAX_STRING_TOKENS - 2 then
      Break;
    LCombined := LCombined + LArgument;
    if LIndex <> LCount - 1 then
      LCombined := LCombined + ' ';
    Inc(LLength, LArgumentLength);
  end;
  FCVars.Set2(FArguments.Argv(1), LCombined, False);
end;

procedure TQ3CVarCommands.SetAndFlag(const AUsage: string; AFlag: Integer);
var
  LVar: TQ3CVar;
begin
  if FArguments.Count <> 3 then
  begin
    Print(AUsage);
    Exit;
  end;
  SetCommand;
  LVar := FCVars.Find(FArguments.Argv(1));
  if Assigned(LVar) then
    LVar.Flags := LVar.Flags or AFlag;
end;

procedure TQ3CVarCommands.SetServerInfo;
begin
  SetAndFlag('usage: sets <variable> <value>'#10, Q3_CVAR_SERVERINFO);
end;

procedure TQ3CVarCommands.SetUserInfo;
begin
  SetAndFlag('usage: setu <variable> <value>'#10, Q3_CVAR_USERINFO);
end;

procedure TQ3CVarCommands.SetArchive;
begin
  SetAndFlag('usage: seta <variable> <value>'#10, Q3_CVAR_ARCHIVE);
end;

procedure TQ3CVarCommands.ResetCommand;
begin
  if FArguments.Count <> 2 then
  begin
    Print('usage: reset <variable>'#10);
    Exit;
  end;
  FCVars.Reset(FArguments.Argv(1));
end;

procedure TQ3CVarCommands.List;
var
  LVar: TQ3CVar;
  LMatch: AnsiString;
  LHasMatch: Boolean;
  LCount: Integer;

  procedure Letter(AFlag: Integer; AChar: Char);
  begin
    if (LVar.Flags and AFlag) <> 0 then
      Print(AChar)
    else
      Print(' ');
  end;

begin
  LHasMatch := FArguments.Count > 1;
  if LHasMatch then
    LMatch := FArguments.Argv(1);
  LCount := 0;
  for LVar in FCVars.Variables do
  begin
    // the counter of the original is in the for statement: it also counts the variables that do not match
    Inc(LCount);
    if LHasMatch and not TIdStrings.Filter(LMatch, LVar.Name, False) then
      Continue;
    Letter(Q3_CVAR_SERVERINFO, 'S');
    Letter(Q3_CVAR_USERINFO, 'U');
    Letter(Q3_CVAR_ROM, 'R');
    Letter(Q3_CVAR_INIT, 'I');
    Letter(Q3_CVAR_ARCHIVE, 'A');
    Letter(Q3_CVAR_LATCH, 'L');
    Letter(Q3_CVAR_CHEAT, 'C');
    Print(Format(' %s "%s"'#10, [string(LVar.Name), string(LVar.StringValue)]));
  end;
  Print(Format(#10'%d total cvars'#10, [LCount]));
  Print(Format('%d cvar indexes'#10, [FCVars.IndexCount]));
end;

procedure TQ3CVarCommands.RestartCommand;
begin
  FCVars.Restart;
end;

end.
