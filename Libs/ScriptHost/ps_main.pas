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
//  Pascal Script wrapper.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit ps_main;

interface

uses
  p_mobj_h,
  ps_compiler,
  ps_runtime,
  DelphiDoom.Logging.Intf;

type
  psscripttype_t = (pst_normal, pst_global, pst_none);

//==============================================================================
//
// PS_ConfigureStateServices
// The log of the events and of the serializer of the script state, given by the
// composition root (before PS_Init)
//
//==============================================================================
procedure PS_ConfigureStateServices(const ALog: ILog);

//==============================================================================
//
// PS_Init
//
//==============================================================================
procedure PS_Init;

//==============================================================================
//
// PS_ShutDown
//
//==============================================================================
procedure PS_ShutDown;

//==============================================================================
//
// PS_AddSourceScript
//
//==============================================================================
procedure PS_AddSourceScript(const sname: string; const sc: string;
  const typ: psscripttype_t);

//==============================================================================
//
// PS_AddCompiledScript
//
//==============================================================================
procedure PS_AddCompiledScript(const sname: string; const sc: string);

//==============================================================================
//
// PS_CompileAllScripts
//
//==============================================================================
procedure PS_CompileAllScripts;

//==============================================================================
//
// PS_NewWorld
//
//==============================================================================
procedure PS_NewWorld;

//==============================================================================
//
// PS_NewMap
//
//==============================================================================
procedure PS_NewMap;

//==============================================================================
//
// PS_LinkScriptEvents
//
//==============================================================================
procedure PS_LinkScriptEvents(const mapname: string);

//==============================================================================
// PS_EventActorDied
//
// Events
// Must be in sync with ScriptOnExportCheck and TScriptEvents class
//
//==============================================================================
procedure PS_EventActorDied(actor: Pmobj_t; killer: Pmobj_t);

//==============================================================================
//
// PS_EventPlayerDied
//
//==============================================================================
procedure PS_EventPlayerDied(playerNO: Integer; killer: Pmobj_t);

//==============================================================================
//
// PS_EventPlayerEnter
//
//==============================================================================
procedure PS_EventPlayerEnter(playerNO: Integer);

//==============================================================================
//
// PS_EventCrossLine
//
//==============================================================================
procedure PS_EventCrossLine(actor: Pmobj_t; line: Integer; oldside: Integer);

//==============================================================================
//
// PS_EventShootLine
//
//==============================================================================
procedure PS_EventShootLine(actor: Pmobj_t; line: Integer; side: Integer);

//==============================================================================
//
// PS_EventUseLine
//
//==============================================================================
procedure PS_EventUseLine(actor: Pmobj_t; line: Integer; side: Integer);

//==============================================================================
//
// PS_EventTick
//
//==============================================================================
procedure PS_EventTick(tick: integer);

//==============================================================================
//
// PS_EventTimerEverySecond
//
//==============================================================================
procedure PS_EventTimerEverySecond(second: integer);

//==============================================================================
//
// PS_EventTimerEveryMinute
//
//==============================================================================
procedure PS_EventTimerEveryMinute(minute: integer);

//==============================================================================
//
// PS_EventMapStart
//
//==============================================================================
procedure PS_EventMapStart;

//-------------------- Map Script Serialization --------------------------------

//==============================================================================
//
// PS_MapScriptSaveToFile
//
//==============================================================================
function PS_MapScriptSaveToFile(const fname: string): boolean;

//==============================================================================
//
// PS_MapScriptSaveSize
//
//==============================================================================
function PS_MapScriptSaveSize: integer;

//==============================================================================
//
// PS_MapScriptLoadFromFile
//
//==============================================================================
function PS_MapScriptLoadFromFile(const fname: string): boolean;

//==============================================================================
//
// A_RunScript
//
//==============================================================================
procedure A_RunScript(actor: Pmobj_t);

//==============================================================================
//
// ScriptOnExportCheck
//
//==============================================================================
function ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;

implementation

uses
  d_delphi,
  c_cmds,
  d_main,
  d_player,
  i_system,
  p_common,
  ps_import,
  DelphiDoom.ScriptHost.Manager,
  ps_dll,
  DelphiDoom.ScriptHost.Events.Intf,
  DelphiDoom.ScriptHost.Events.Table,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Serializer.Intf,
  psi_game,
  psi_globals,
  psi_overlay,
  w_folders,
  w_pak,
  ps_defs,
  ps_utils;

var
  // given by the composition root
  ps_state_log: ILog = nil;

//==============================================================================
//
// PS_ConfigureStateServices
//
//==============================================================================
procedure PS_ConfigureStateServices(const ALog: ILog);
begin
  ps_state_log := ALog;
end;

//==============================================================================
//
// PS_StateLog
//
//==============================================================================
function PS_StateLog: ILog;
begin
  if ps_state_log = nil then
    I_Error('PS_ConfigureStateServices() was not called: the log of the script events is missing');
  Result := ps_state_log;
end;

//==============================================================================
//
// ScriptOnExportCheck
//
//==============================================================================
function ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := Low(SCRIPT_EVENT_SIGNATURES) to High(SCRIPT_EVENT_SIGNATURES) do
    if (Proc.Name = SCRIPT_EVENT_SIGNATURES[I].Name) then
      if not ExportCheck(Sender, Proc,
        Slice(SCRIPT_EVENT_SIGNATURES[I].Typ, SCRIPT_EVENT_SIGNATURES[I].ParamCount + 1),
        Slice(SCRIPT_EVENT_SIGNATURES[I].Dir, SCRIPT_EVENT_SIGNATURES[I].ParamCount)) then
      begin
        //  Parameter missmatch
        Sender.MakeErrorEx(SCRIPT_EVENT_SIGNATURES[I].Name, ecInvalidEventParameters, '',
          Proc.DeclarePos, Proc.DeclareRow, Proc.DeclareCol);
        Result := False;
        Exit;
      end;
end;

var
  ps_manager_ref: TScriptManager = nil;

//==============================================================================
//
// PS_Manager
//
//==============================================================================
function PS_Manager: TScriptManager;
begin
  if ps_manager_ref = nil then
    I_Error('PS_Init() was not called: the manager of the scripts is missing');
  Result := ps_manager_ref;
end;

//==============================================================================
//
// CmdCompileScript
//
//==============================================================================
procedure CmdCompileScript(const src, dest: string);
var
  data: TbtString;
  f: TFile;
  i: integer;
  clist: TDStringList;
begin
  if src = '' then
  begin
    printf('Please specify the source file.'#13#10);
    Exit;
  end;
  if dest = '' then
  begin
    printf('Please specify the output file.'#13#10);
    Exit;
  end;
  if strupper(fexpand(src)) = strupper(fexpand(dest)) then
  begin
    printf('Source file and destination file can not be the same.'#13#10);
    Exit;
  end;
  if not fexists(src) then
  begin
    I_Warning('CmdCompileScript(): Source file %s not found.'#13#10, [src]);
    Exit;
  end;

  if ps_manager_ref = nil then
  begin
    printf('Compiler not initialized.'#13#10);
    Exit;
  end;

  clist := TDStringList.Create;
  clist.LoadFromFile(src);
  if PS_Manager.DoomCompiler.CompileDoomScript(clist.Text, data) then
  begin
    f := TFile.Create(dest, fCreate);
    for i := 1 to Length(data) do
      f.Write(Byte(data[i]), SizeOf(byte));
    f.Free;
    printf(' "%s"...success'#13#10, [src])
  end
  else
  begin
    I_Warning('pscomp: Can not compile script:'#13#10);
    for i := 0 to clist.Count - 1 do
    begin
      I_Warning(IntToStrZfill(6, i + 1) + ': ' + clist.Strings[i] + #13#10);
    end;
    for i := 0 to PS_Manager.DoomCompiler.MsgCount - 1 do
    begin
      I_Warning('//---------------------------------------------------------'#13#10);
      I_Warning(' Pos: ' + IntToStrZFill(6, PS_Manager.DoomCompiler.Msg[i].Pos) +
                ' Compiler: ' + PS_Manager.DoomCompiler.Msg[i].MessageToString + #13#10);
      I_Warning(' <<' + Copy(clist.Text, PS_Manager.DoomCompiler.Msg[i].Pos, 80) + '>>'#13#10);
      I_Warning('//---------------------------------------------------------'#13#10);
    end;
    I_Warning(' "%s"...failed'#13#10, [src]);
    I_Warning('//---------------------------------------------------------'#13#10);
  end;
  clist.Free;
end;

//==============================================================================
//
// PS_Init
//
//==============================================================================
procedure PS_Init;
begin
  PS_InitProcLists;
  PS_InitGlobals;
  PS_InitGameImport;
  ps_manager_ref := TScriptManager.Create(PS_HostServices, PS_ActorContext, PS_StateLog, ScriptOnExportCheck,
    function: Boolean
    begin
      Result := devparm;
    end);
  C_AddCmd('compile, compilescript, pscomp', @CmdCompileScript);
end;

//==============================================================================
//
// PS_ShutDown
//
//==============================================================================
procedure PS_ShutDown;
begin
  FreeAndNil(ps_manager_ref);
  PS_ShutDownGameImport;
  PS_ShutDownOverlay;
  PS_ShutDownGlobals;
  PS_ShutDownProcLists;
  PS_ShutDownDLLLoader;
end;

//==============================================================================
//
// PS_AddSourceScript
//
//==============================================================================
procedure PS_AddSourceScript(const sname: string; const sc: string;
  const typ: psscripttype_t);
begin
  printf('PS_AddSourceScript(): Adding script "%s"'#13#10, [sname]);
  PS_Manager.AddSourceFile(sname, sc, TScriptKind(Ord(typ)));
end;

//==============================================================================
//
// PS_AddCompiledScript
//
//==============================================================================
procedure PS_AddCompiledScript(const sname: string; const sc: string);
var
  strm: TPakStream;
  data: string;
  b: PByteArray;
  size: integer;
  i: integer;
begin
  data := '';
  strm := TPakStream.Create(sc, pm_short, '', FOLDER_SCRIPTS);
  if strm.IOResult = 0 then
  begin
    printf('PS_AddCompiledScript(): Adding script "%s" (file "%s")'#13#10, [sname, sc]);
    size := strm.Size;
    b := malloc(size);
    strm.Seek(0, sFromBeginning);
    strm.Read(b^, size);
    for i := 0 to size - 1 do
      data := data + Chr(b[i]);
    memfree(pointer(b), size);
  end;
  strm.Free;
  PS_Manager.AddCompiledFile(sname, data);
end;

//==============================================================================
//
// PS_CompileAllScripts
//
//==============================================================================
procedure PS_CompileAllScripts;
begin
  PS_InitOverlay;
  PS_Manager.CompileAllScripts;
end;

//==============================================================================
//
// PS_DoRunScript
//
//==============================================================================
procedure PS_DoRunScript(actor: Pmobj_t; const scid: integer);
begin
  PS_Manager.RunScript(actor, scid);
end;

//==============================================================================
//
// PS_GetScriptIDFromName
//
//==============================================================================
function PS_GetScriptIDFromName(const scname: string): integer;
begin
  result := PS_Manager.IndexOf(scname);
end;

//==============================================================================
//
// PS_NewWorld
//
//==============================================================================
procedure PS_NewWorld;
begin
  worldvars.Clear;
  mapvars.Clear;
  overlay.Clear;
  PS_Manager.Events.Clear;
end;

//==============================================================================
//
// PS_NewMap
//
//==============================================================================
procedure PS_NewMap;
begin
  mapvars.Clear;
  overlay.Clear;
  PS_Manager.Events.Clear;
end;

//==============================================================================
//
// PS_LinkScriptEvents
//
//==============================================================================
procedure PS_LinkScriptEvents(const mapname: string);
begin
  PS_Manager.LinkScriptEvents(mapname);
end;

// Events

//==============================================================================
//
// PS_EventActorDied
//
//==============================================================================
procedure PS_EventActorDied(actor: Pmobj_t; killer: Pmobj_t);
begin
  PS_ActorContext.Enter(actor);
  PS_Manager.Events.ProcActorDied(PS_KeyFromMobj(actor), PS_KeyFromMobj(killer));
  PS_ActorContext.Leave;
end;

//==============================================================================
//
// PS_EventPlayerEnter
//
//==============================================================================
procedure PS_EventPlayerEnter(playerNO: Integer);
begin
  PS_ActorContext.Enter(players[playerNO].mo);
  PS_Manager.Events.ProcPlayerEnter(playerNO);
  PS_ActorContext.Leave;
end;

//==============================================================================
//
// PS_EventPlayerDied
//
//==============================================================================
procedure PS_EventPlayerDied(playerNO: Integer; killer: Pmobj_t);
begin
  PS_ActorContext.Enter(players[playerNO].mo);
  PS_Manager.Events.ProcPlayerDied(playerNO, PS_KeyFromMobj(killer));
  PS_ActorContext.Leave;
end;

//==============================================================================
//
// PS_EventCrossLine
//
//==============================================================================
procedure PS_EventCrossLine(actor: Pmobj_t; line: Integer; oldside: Integer);
begin
  PS_ActorContext.Enter(actor);
  PS_Manager.Events.ProcCrossLine(PS_KeyFromMobj(actor), line, oldside);
  PS_ActorContext.Leave;
end;

//==============================================================================
//
// PS_EventShootLine
//
//==============================================================================
procedure PS_EventShootLine(actor: Pmobj_t; line: Integer; side: Integer);
begin
  PS_ActorContext.Enter(actor);
  PS_Manager.Events.ProcShootLine(PS_KeyFromMobj(actor), line, side);
  PS_ActorContext.Leave;
end;

//==============================================================================
//
// PS_EventUseLine
//
//==============================================================================
procedure PS_EventUseLine(actor: Pmobj_t; line: Integer; side: Integer);
begin
  PS_ActorContext.Enter(actor);
  PS_Manager.Events.ProcUseLine(PS_KeyFromMobj(actor), line, side);
  PS_ActorContext.Leave;
end;

//==============================================================================
//
// PS_EventTick
//
//==============================================================================
procedure PS_EventTick(tick: integer);
begin
  PS_Manager.Events.ProcTick(tick);
end;

//==============================================================================
//
// PS_EventTimerEverySecond
//
//==============================================================================
procedure PS_EventTimerEverySecond(second: integer);
begin
  PS_Manager.Events.ProcTimerEverySecond(second);
end;

//==============================================================================
//
// PS_EventTimerEveryMinute
//
//==============================================================================
procedure PS_EventTimerEveryMinute(minute: integer);
begin
  PS_Manager.Events.ProcTimerEveryMinute(minute);
end;

//==============================================================================
//
// PS_EventMapStart
//
//==============================================================================
procedure PS_EventMapStart;
begin
  PS_Manager.Events.ProcMapStart;
end;

//-------------------- Map Script Serialization --------------------------------

//==============================================================================
//
// PS_MapScriptSaveToFile
//
//==============================================================================
function PS_MapScriptSaveToFile(const fname: string): boolean;
var
  psser: IScriptSerializer;
begin
  psser := TScriptHostFactory.CreateSerializer(PS_Manager.EventsExec, PS_StateLog);
  result := psser.SaveToFile(fname);
end;

//==============================================================================
//
// PS_MapScriptSaveSize
//
//==============================================================================
function PS_MapScriptSaveSize: integer;
var
  psser: IScriptSerializer;
begin
  psser := TScriptHostFactory.CreateSerializer(PS_Manager.EventsExec, PS_StateLog);
  Result := psser.SaveSize;
end;

//==============================================================================
//
// PS_MapScriptLoadFromFile
//
//==============================================================================
function PS_MapScriptLoadFromFile(const fname: string): boolean;
var
  psser: IScriptSerializer;
begin
  psser := TScriptHostFactory.CreateSerializer(PS_Manager.EventsExec, PS_StateLog);
  result := psser.LoadFromFile(fname);
end;

//==============================================================================
//
// A_RunScript
//
//==============================================================================
procedure A_RunScript(actor: Pmobj_t);
var
  scid: integer;
  i: integer;
begin
  if actor.flags2_ex and MF2_EX_DONTRUNSCRIPTS <> 0 then
    Exit;

  if not P_CheckStateParams(actor) then
    Exit;

  for i := 0 to actor.state.params.Count - 1 do
  begin
    if not actor.state.params.IsComputed[i] then
      actor.state.params.IntVal[i] := PS_GetScriptIDFromName(actor.state.params.StrVal[i]);

    scid := actor.state.params.IntVal[i];
    if scid > -1 then
      PS_DoRunScript(actor, scid);
  end;
end;

end.

