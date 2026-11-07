//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit c_cmds;

interface

uses
  d_delphi,
  DelphiDoom.Console.Intf;

type
  cmdproc_t = procedure(const parm1, parm2: string);

//==============================================================================
//
// C_ConfigureCommands
// The registry and the interpreter of Libs\Console, given by the composition root
//
//==============================================================================
procedure C_ConfigureCommands(const ARegistry: ICommandRegistry; const AInterpreter: IConsoleInterpreter);

//==============================================================================
//
// C_AddCmd
//
//==============================================================================
procedure C_AddCmd(const name: string; proc: cmdproc_t);

//==============================================================================
//
// C_ExecuteCmd
//
//==============================================================================
function C_ExecuteCmd(const name: string): boolean; overload;

//==============================================================================
//
// C_ExecuteCmd
//
//==============================================================================
function C_ExecuteCmd(const name: string; const parm: string): boolean; overload;

//==============================================================================
//
// C_ExecuteCmd
//
//==============================================================================
function C_ExecuteCmd(name: string; const parm1, parm2: string): boolean; overload;

//==============================================================================
//
// C_BoolEval
//
//==============================================================================
function C_BoolEval(parm: string; const default: boolean): boolean;

//==============================================================================
//
// C_GetMachingList
//
//==============================================================================
function C_GetMachingList(const src: TDStringList; const mask: string): TDStringList;

implementation

uses
  i_system,
  DelphiDoom.Console.Numbers,
  DelphiDoom.Console.MaskMatcher;

var
  cmd_registry: ICommandRegistry;
  cmd_interpreter: IConsoleInterpreter;

//==============================================================================
//
// C_ConfigureCommands
//
//==============================================================================
procedure C_ConfigureCommands(const ARegistry: ICommandRegistry; const AInterpreter: IConsoleInterpreter);
begin
  cmd_registry := ARegistry;
  cmd_interpreter := AInterpreter;
end;

procedure C_CheckConfigured;
begin
  if cmd_registry = nil then
    I_Error('The console is not configured (ComposeEngine was not called)');
end;

//==============================================================================
//
// C_AddCmd
//
//==============================================================================
procedure C_AddCmd(const name: string; proc: cmdproc_t);
begin
  if name = '' then
    exit;
  C_CheckConfigured;

  // The commands have always been called with both parameters, whatever their own declaration
  cmd_registry.Add(name,
    procedure(const aparm1, aparm2: string)
    begin
      proc(aparm1, aparm2);
    end);
end;

//==============================================================================
//
// C_ExecuteCmd
//
//==============================================================================
function C_ExecuteCmd(const name: string): boolean;
begin
  C_CheckConfigured;
  result := cmd_interpreter.Execute(name);
end;

//==============================================================================
//
// C_ExecuteCmd
//
//==============================================================================
function C_ExecuteCmd(const name: string; const parm: string): boolean;
begin
  C_CheckConfigured;
  result := cmd_interpreter.Execute(name, parm);
end;

//==============================================================================
//
// C_ExecuteCmd
//
//==============================================================================
function C_ExecuteCmd(name: string; const parm1, parm2: string): boolean;
begin
  C_CheckConfigured;
  result := cmd_interpreter.Execute(name, parm1, parm2);
end;

//==============================================================================
//
// C_BoolEval
//
//==============================================================================
function C_BoolEval(parm: string; const default: boolean): boolean;
begin
  result := TConsoleNumbers.EvaluateBoolean(parm, default);
end;

//==============================================================================
//
// C_GetMachingList
//
//==============================================================================
function C_GetMachingList(const src: TDStringList; const mask: string): TDStringList;
var
  names: TArray<string>;
  matching: TArray<string>;
  i: integer;
begin
  SetLength(names, src.Count);
  for i := 0 to src.Count - 1 do
    names[i] := src[i];

  matching := TConsoleMaskMatcher.Filter(names, mask);

  result := TDStringList.Create;
  for i := 0 to Length(matching) - 1 do
    result.Add(matching[i]);
end;

const
  S_UNKNOWNCOMMAND = 'Unknown command'#13#10;

end.
