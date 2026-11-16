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
// DESCRIPTION:
//  Pascal Script RTL - global variables.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit psi_globals;

interface

uses
  d_delphi,
  SysUtils,
  Classes,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Variables.Intf;

// The variables of the scripts of the map and of the world (Delphi Doom ScriptHost library:
// TScriptVariables, created by PS_InitGlobals); this unit keeps the old API
type
  TGlobalVariablesList = IScriptVariables;

var
  mapvars: IScriptVariables;
  worldvars: IScriptVariables;

//==============================================================================
//
// PS_GetMapStr
//
//==============================================================================
function PS_GetMapStr(const x: string): string;

//==============================================================================
//
// PS_SetMapStr
//
//==============================================================================
procedure PS_SetMapStr(const x: string; const v: string);

//==============================================================================
//
// PS_GetMapInt
//
//==============================================================================
function PS_GetMapInt(const x: string): integer;

//==============================================================================
//
// PS_SetMapInt
//
//==============================================================================
procedure PS_SetMapInt(const x: string; const v: integer);

//==============================================================================
//
// PS_GetMapFloat
//
//==============================================================================
function PS_GetMapFloat(const x: string): float;

//==============================================================================
//
// PS_SetMapFloat
//
//==============================================================================
procedure PS_SetMapFloat(const x: string; const v: float);

//==============================================================================
//
// PS_GetWorldStr
//
//==============================================================================
function PS_GetWorldStr(const x: string): string;

//==============================================================================
//
// PS_SetWorldStr
//
//==============================================================================
procedure PS_SetWorldStr(const x: string; const v: string);

//==============================================================================
//
// PS_GetWorldInt
//
//==============================================================================
function PS_GetWorldInt(const x: string): integer;

//==============================================================================
//
// PS_SetWorldInt
//
//==============================================================================
procedure PS_SetWorldInt(const x: string; const v: integer);

//==============================================================================
//
// PS_GetWorldFloat
//
//==============================================================================
function PS_GetWorldFloat(const x: string): float;

//==============================================================================
//
// PS_SetWorldFloat
//
//==============================================================================
procedure PS_SetWorldFloat(const x: string; const v: float);

//==============================================================================
//
// PS_InitGlobals
//
//==============================================================================
procedure PS_InitGlobals;

//==============================================================================
//
// PS_ShutDownGlobals
//
//==============================================================================
procedure PS_ShutDownGlobals;

// Script Runtime Helpers
// Global strings
type
  TGlobalStrings = class(TObject)
  protected
    flist: IScriptVariables;
    function Get(vname: string): string; virtual;
    procedure Put(vname: string; const value: string); virtual;
  public
    constructor Create(const alist: IScriptVariables); virtual;
  end;

  TMapStrings = class(TGlobalStrings)
  public
    constructor Create; reintroduce;
    property value[Name: string]: string read Get write Put; default;
  end;

  TWorldStrings = class(TGlobalStrings)
  public
    constructor Create; reintroduce;
    property value[Name: string]: string read Get write Put; default;
  end;

// Script Runtime Helpers
// Global integers
type
  TGlobalIntegers = class(TObject)
  protected
    flist: IScriptVariables;
    function Get(vname: string): integer; virtual;
    procedure Put(vname: string; const value: integer); virtual;
  public
    constructor Create(const alist: IScriptVariables); virtual;
  end;

  TMapIntegers = class(TGlobalIntegers)
  public
    constructor Create; reintroduce;
    property value[Name: string]: integer read Get write Put; default;
  end;

  TWorldIntegers = class(TGlobalIntegers)
  public
    constructor Create; reintroduce;
    property value[Name: string]: integer read Get write Put; default;
  end;

// Script Runtime Helpers
// Global floats
type
  TGlobalFloats = class(TObject)
  protected
    flist: IScriptVariables;
    function Get(vname: string): float; virtual;
    procedure Put(vname: string; const value: float); virtual;
  public
    constructor Create(const alist: IScriptVariables); virtual;
  end;

  TMapFloats = class(TGlobalFloats)
  public
    constructor Create; reintroduce;
    property value[Name: string]: float read Get write Put; default;
  end;

  TWorldFloats = class(TGlobalFloats)
  public
    constructor Create; reintroduce;
    property value[Name: string]: float read Get write Put; default;
  end;

//==============================================================================
//
// PS_DescribeGlobalClasses
// The classes of the variables of the scripts (MapStrings, WorldIntegers...)
// for the compiler and the interpreter
//
//==============================================================================
procedure PS_DescribeGlobalClasses(const ACatalog: IScriptClassCatalog);

//==============================================================================
//
// PS_ConfigureVariables
// The files and the failure of the variables, given by the composition root
//
//==============================================================================
procedure PS_ConfigureVariables(const AFiles: IScriptVariablesFiles;
  const AFailure: IScriptVariablesFailure);

implementation

uses
  c_cmds,
  i_system,
  DelphiDoom.ScriptHost.Factory;

var
  // given by the composition root
  ps_variables_files: IScriptVariablesFiles = nil;
  ps_variables_failure: IScriptVariablesFailure = nil;

//==============================================================================
//
// PS_ConfigureVariables
//
//==============================================================================
procedure PS_ConfigureVariables(const AFiles: IScriptVariablesFiles;
  const AFailure: IScriptVariablesFailure);
begin
  ps_variables_files := AFiles;
  ps_variables_failure := AFailure;
end;

//==============================================================================
//
// PS_NewVariables
//
//==============================================================================
function PS_NewVariables: IScriptVariables;
begin
  if (ps_variables_files = nil) or (ps_variables_failure = nil) then
    I_Error('PS_ConfigureVariables() was not called: the variables of the scripts are missing');
  Result := TScriptHostFactory.CreateVariables(ps_variables_files, ps_variables_failure);
end;

//==============================================================================
//
// PS_GetMapStr
//
//==============================================================================
function PS_GetMapStr(const x: string): string;
begin
  Result := mapvars.StrVal[x];
end;

//==============================================================================
//
// PS_SetMapStr
//
//==============================================================================
procedure PS_SetMapStr(const x: string; const v: string);
begin
  mapvars.StrVal[x] := v;
end;

//==============================================================================
//
// PS_GetMapInt
//
//==============================================================================
function PS_GetMapInt(const x: string): integer;
begin
  Result := mapvars.IntVal[x];
end;

//==============================================================================
//
// PS_SetMapInt
//
//==============================================================================
procedure PS_SetMapInt(const x: string; const v: integer);
begin
  mapvars.IntVal[x] := v;
end;

//==============================================================================
//
// PS_GetMapFloat
//
//==============================================================================
function PS_GetMapFloat(const x: string): float;
begin
  Result := mapvars.FloatVal[x];
end;

//==============================================================================
//
// PS_SetMapFloat
//
//==============================================================================
procedure PS_SetMapFloat(const x: string; const v: float);
begin
  mapvars.FloatVal[x] := v;
end;

//==============================================================================
//
// PS_GetWorldStr
//
//==============================================================================
function PS_GetWorldStr(const x: string): string;
begin
  Result := worldvars.StrVal[x];
end;

//==============================================================================
//
// PS_SetWorldStr
//
//==============================================================================
procedure PS_SetWorldStr(const x: string; const v: string);
begin
  worldvars.StrVal[x] := v;
end;

//==============================================================================
//
// PS_GetWorldInt
//
//==============================================================================
function PS_GetWorldInt(const x: string): integer;
begin
  Result := worldvars.IntVal[x];
end;

//==============================================================================
//
// PS_SetWorldInt
//
//==============================================================================
procedure PS_SetWorldInt(const x: string; const v: integer);
begin
  worldvars.IntVal[x] := v;
end;

//==============================================================================
//
// PS_GetWorldFloat
//
//==============================================================================
function PS_GetWorldFloat(const x: string): float;
begin
  Result := worldvars.FloatVal[x];
end;

//==============================================================================
//
// PS_SetWorldFloat
//
//==============================================================================
procedure PS_SetWorldFloat(const x: string; const v: float);
begin
  worldvars.FloatVal[x] := v;
end;

//==============================================================================
//
// CmdGetVar
//
//==============================================================================
procedure CmdGetVar(const s1, s2: string; const vars: IScriptVariables;
  const desc: string);
var
  s: string;
  v1, v2: string;
begin
  if s1 = '' then
  begin
    printf('Please specify the names of the %s variables to display.'#13#10, [desc]);
    Exit;
  end;

  s := UpperCase(Trim(s1 + ' ' + s2));
  repeat
    splitstring_ch(s, v1, v2);
    if v1 <> '' then
    begin
      if vars.HasString(v1) then
        printf('[%s]=%s'#13#10, [v1, vars.StrVal[v1]])
      else if vars.HasInteger(v1) then
        printf('[%s]=%d'#13#10, [v1, vars.IntVal[v1]])
      else if vars.HasFloat(v1) then
        printf('[%s]=%2.3f'#13#10, [v1, vars.FloatVal[v1]])
      else
        printf('[%s] - (undeclared %s variable)'#13#10, [v1, desc]);
    end;
    s := strtrim(v2);
  until s = '';
end;

//==============================================================================
//
// CmdGetWorldVar
//
//==============================================================================
procedure CmdGetWorldVar(const s1, s2: string);
begin
  CmdGetVar(s1, s2, worldvars, 'world');
end;

//==============================================================================
//
// CmdGetMapVar
//
//==============================================================================
procedure CmdGetMapVar(const s1, s2: string);
begin
  CmdGetVar(s1, s2, mapvars, 'map');
end;

//==============================================================================
//
// CmdSetVar
//
//==============================================================================
procedure CmdSetVar(const s1, s2: string; const vars: IScriptVariables;
  const desc: string);
begin
  if s1 = '' then
  begin
    printf('Please specify the names of the %s variable to set.'#13#10, [desc]);
    Exit;
  end;

  if s2 = '' then
  begin
    vars.StrVal[s1] := '';
    Exit;
  end;

  if CharPos(' ', s2) > 0 then
  begin
    vars.StrVal[s1] := s2;
    Exit;
  end;

  if vars.HasString(s1) then
    vars.StrVal[s1] := s2
  else if vars.HasInteger(s1) then
    vars.IntVal[s1] := atoi(s2)
  else if vars.HasFloat(s1) then
    vars.FloatVal[s1] := atof(s2)
  else
  begin
    if StrIsInteger(s2) then
      vars.IntVal[s1] := atoi(s2)
    else if StrIsFloat(s2) then
      vars.FloatVal[s1] := atof(s2)
    else
      vars.StrVal[s1] := s2
  end;
end;

//==============================================================================
//
// CmdSetWorldVar
//
//==============================================================================
procedure CmdSetWorldVar(const s1, s2: string);
begin
  CmdSetVar(s1, s2, worldvars, 'world');
end;

//==============================================================================
//
// CmdSetMapVar
//
//==============================================================================
procedure CmdSetMapVar(const s1, s2: string);
begin
  CmdSetVar(s1, s2, mapvars, 'map');
end;

var
  RTL_MapVarS: TMapStrings;
  RTL_WorldVarS: TWorldStrings;
  RTL_MapVarI: TMapIntegers;
  RTL_WorldVarI: TWorldIntegers;
  RTL_MapVarF: TMapFloats;
  RTL_WorldVarF: TWorldFloats;

//==============================================================================
//
// PS_InitGlobals
//
//==============================================================================
procedure PS_InitGlobals;
begin
  mapvars := PS_NewVariables;
  worldvars := PS_NewVariables;

  RTL_MapVarS := TMapStrings.Create;
  RTL_WorldVarS := TWorldStrings.Create;
  RTL_MapVarI := TMapIntegers.Create;
  RTL_WorldVarI := TWorldIntegers.Create;
  RTL_MapVarF := TMapFloats.Create;
  RTL_WorldVarF := TWorldFloats.Create;

  C_AddCmd('getworldvar', @CmdGetWorldVar);
  C_AddCmd('getmapvar', @CmdGetMapVar);
  C_AddCmd('setworldvar', @CmdSetWorldVar);
  C_AddCmd('setmapvar', @CmdSetMapVar);
end;

//==============================================================================
//
// PS_ShutDownGlobals
//
//==============================================================================
procedure PS_ShutDownGlobals;
begin
  RTL_MapVarS.Free;
  RTL_WorldVarS.Free;
  RTL_MapVarI.Free;
  RTL_WorldVarI.Free;
  RTL_MapVarF.Free;
  RTL_WorldVarF.Free;

  mapvars := nil;
  worldvars := nil;
end;

//==============================================================================
// TGlobalStrings.Create
//
// Script Runtime Helpers
// Global strings
//
//==============================================================================
constructor TGlobalStrings.Create(const alist: IScriptVariables);
begin
  fList := alist;
  inherited Create;
end;

//==============================================================================
//
// TGlobalStrings.Get
//
//==============================================================================
function TGlobalStrings.Get(vname: string): string;
begin
  Result := flist.GetString(vname);
end;

//==============================================================================
//
// TGlobalStrings.Put
//
//==============================================================================
procedure TGlobalStrings.Put(vname: string; const value: string);
begin
  flist.PutString(vname, value);
end;

//==============================================================================
//
// TMapStrings.Create
//
//==============================================================================
constructor TMapStrings.Create;
begin
  inherited Create(mapvars);
end;

//==============================================================================
//
// TWorldStrings.Create
//
//==============================================================================
constructor TWorldStrings.Create;
begin
  inherited Create(worldvars);
end;

//==============================================================================
// TGlobalIntegers.Create
//
// Script Runtime Helpers
// Global integers
//
//==============================================================================
constructor TGlobalIntegers.Create(const alist: IScriptVariables);
begin
  fList := alist;
  inherited Create;
end;

//==============================================================================
//
// TGlobalIntegers.Get
//
//==============================================================================
function TGlobalIntegers.Get(vname: string): integer;
begin
  Result := flist.GetInteger(vname);
end;

//==============================================================================
//
// TGlobalIntegers.Put
//
//==============================================================================
procedure TGlobalIntegers.Put(vname: string; const value: integer);
begin
  flist.PutInteger(vname, value);
end;

//==============================================================================
//
// TMapIntegers.Create
//
//==============================================================================
constructor TMapIntegers.Create;
begin
  inherited Create(mapvars);
end;

//==============================================================================
//
// TWorldIntegers.Create
//
//==============================================================================
constructor TWorldIntegers.Create;
begin
  inherited Create(worldvars);
end;

//==============================================================================
// TGlobalFloats.Create
//
// Script Runtime Helpers
// Global floats
//
//==============================================================================
constructor TGlobalFloats.Create(const alist: IScriptVariables);
begin
  fList := alist;
  inherited Create;
end;

//==============================================================================
//
// TGlobalFloats.Get
//
//==============================================================================
function TGlobalFloats.Get(vname: string): float;
begin
  Result := flist.GetFloat(vname);
end;

//==============================================================================
//
// TGlobalFloats.Put
//
//==============================================================================
procedure TGlobalFloats.Put(vname: string; const value: float);
begin
  flist.PutFloat(vname, value);
end;

//==============================================================================
//
// TMapFloats.Create
//
//==============================================================================
constructor TMapFloats.Create;
begin
  inherited Create(mapvars);
end;

//==============================================================================
//
// TWorldFloats.Create
//
//==============================================================================
constructor TWorldFloats.Create;
begin
  inherited Create(worldvars);
end;

(* === run-time registration functions === *)

//==============================================================================
//
// TWorldFloatsvalue_W
//
//==============================================================================
procedure TWorldFloatsvalue_W(Self: TWorldFloats; const T: single; const t1: string);
begin
  Self.value[t1] := T;
end;

//==============================================================================
//
// TWorldFloatsvalue_R
//
//==============================================================================
procedure TWorldFloatsvalue_R(Self: TWorldFloats; var T: single; const t1: string);
begin
  T := Self.value[t1];
end;

//==============================================================================
//
// TMapFloatsvalue_W
//
//==============================================================================
procedure TMapFloatsvalue_W(Self: TMapFloats; const T: single; const t1: string);
begin
  Self.value[t1] := T;
end;

//==============================================================================
//
// TMapFloatsvalue_R
//
//==============================================================================
procedure TMapFloatsvalue_R(Self: TMapFloats; var T: single; const t1: string);
begin
  T := Self.value[t1];
end;

//==============================================================================
//
// TWorldIntegersvalue_W
//
//==============================================================================
procedure TWorldIntegersvalue_W(Self: TWorldIntegers; const T: integer; const t1: string);
begin
  Self.value[t1] := T;
end;

//==============================================================================
//
// TWorldIntegersvalue_R
//
//==============================================================================
procedure TWorldIntegersvalue_R(Self: TWorldIntegers; var T: integer; const t1: string);
begin
  T := Self.value[t1];
end;

//==============================================================================
//
// TMapIntegersvalue_W
//
//==============================================================================
procedure TMapIntegersvalue_W(Self: TMapIntegers; const T: integer; const t1: string);
begin
  Self.value[t1] := T;
end;

//==============================================================================
//
// TMapIntegersvalue_R
//
//==============================================================================
procedure TMapIntegersvalue_R(Self: TMapIntegers; var T: integer; const t1: string);
begin
  T := Self.value[t1];
end;

//==============================================================================
//
// TWorldStringsvalue_W
//
//==============================================================================
procedure TWorldStringsvalue_W(Self: TWorldStrings; const T: string; const t1: string);
begin
  Self.value[t1] := T;
end;

//==============================================================================
//
// TWorldStringsvalue_R
//
//==============================================================================
procedure TWorldStringsvalue_R(Self: TWorldStrings; var T: string; const t1: string);
begin
  T := Self.value[t1];
end;

//==============================================================================
//
// TMapStringsvalue_W
//
//==============================================================================
procedure TMapStringsvalue_W(Self: TMapStrings; const T: string; const t1: string);
begin
  Self.value[t1] := T;
end;

//==============================================================================
//
// TMapStringsvalue_R
//
//==============================================================================
procedure TMapStringsvalue_R(Self: TMapStrings; var T: string; const t1: string);
begin
  T := Self.value[t1];
end;

//==============================================================================
//
// PS_DescribeGlobalClasses
// The classes of the variables of the scripts (MapStrings, WorldIntegers...)
//
//==============================================================================
procedure PS_DescribeGlobalClasses(const ACatalog: IScriptClassCatalog);
var
  LClass: IScriptClassDescriptor;
begin
  LClass := ACatalog.AddClass('!TMapStrings', TMapStrings);
  LClass.AddConstructor(@TMapStrings.Create);
  LClass.AddProperty('value', 'string string', iptRW, @TMapStringsvalue_R, @TMapStringsvalue_W);
  LClass.AddDefaultProperty('value');
  LClass.AddVariable('MapStrings',
    function: TObject
    begin
      Result := RTL_MapVarS;
    end);

  LClass := ACatalog.AddClass('!TWorldStrings', TWorldStrings);
  LClass.AddConstructor(@TWorldStrings.Create);
  LClass.AddProperty('value', 'string string', iptRW, @TWorldStringsvalue_R, @TWorldStringsvalue_W);
  LClass.AddDefaultProperty('value');
  LClass.AddVariable('WorldStrings',
    function: TObject
    begin
      Result := RTL_WorldVarS;
    end);

  LClass := ACatalog.AddClass('!TMapIntegers', TMapIntegers);
  LClass.AddConstructor(@TMapIntegers.Create);
  LClass.AddProperty('value', 'integer string', iptRW, @TMapIntegersvalue_R, @TMapIntegersvalue_W);
  LClass.AddDefaultProperty('value');
  LClass.AddVariable('MapIntegers',
    function: TObject
    begin
      Result := RTL_MapVarI;
    end);

  LClass := ACatalog.AddClass('!TWorldIntegers', TWorldIntegers);
  LClass.AddConstructor(@TWorldIntegers.Create);
  LClass.AddProperty('value', 'integer string', iptRW, @TWorldIntegersvalue_R, @TWorldIntegersvalue_W);
  LClass.AddDefaultProperty('value');
  LClass.AddVariable('WorldIntegers',
    function: TObject
    begin
      Result := RTL_WorldVarI;
    end);

  LClass := ACatalog.AddClass('!TMapFloats', TMapFloats);
  LClass.AddConstructor(@TMapFloats.Create);
  LClass.AddProperty('value', 'single string', iptRW, @TMapFloatsvalue_R, @TMapFloatsvalue_W);
  LClass.AddDefaultProperty('value');
  LClass.AddVariable('MapFloats',
    function: TObject
    begin
      Result := RTL_MapVarF;
    end);

  LClass := ACatalog.AddClass('!TWorldFloats', TWorldFloats);
  LClass.AddConstructor(@TWorldFloats.Create);
  LClass.AddProperty('value', 'single string', iptRW, @TWorldFloatsvalue_R, @TWorldFloatsvalue_W);
  LClass.AddDefaultProperty('value');
  LClass.AddVariable('WorldFloats',
    function: TObject
    begin
      Result := RTL_WorldVarF;
    end);
end;

end.

