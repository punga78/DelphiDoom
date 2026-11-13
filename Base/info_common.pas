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

unit info_common;

interface

uses
  d_delphi,
  doomtype,
  info_h,
  DelphiDoom.Engine.Info.Intf;

//==============================================================================
//
// Info_ConfigureThings
//
// What finds the things by editor number and by name, and their ancestors: ComposeEngine
// gives it (issue #185, the rules are in Libs\Info)
//
//==============================================================================
procedure Info_ConfigureThings(const AThings: IEngineInfoThings);

//==============================================================================
//
// Info_ConfigureStates
//
// What walks the chains of states
//
//==============================================================================
procedure Info_ConfigureStates(const AStates: IEngineInfoStates);

//==============================================================================
//
// Info_ConfigureGroups
//
// The names of the MBF21 groups
//
//==============================================================================
procedure Info_ConfigureGroups(const AGroups: IEngineInfoGroups);

//==============================================================================
//
// Info_States
//
// The configured walker of the chains of states (info_fnd uses it)
//
//==============================================================================
function Info_States: IEngineInfoStates;

//==============================================================================
//
// Info_GetMobjNumForDoomNum
//
//==============================================================================
function Info_GetMobjNumForDoomNum(const dn: integer): integer;

//==============================================================================
//
// Info_InitDnLookUp
//
//==============================================================================
procedure Info_InitDnLookUp;

//==============================================================================
//
// Info_ShutDownDnLookUp
//
//==============================================================================
procedure Info_ShutDownDnLookUp;

//==============================================================================
//
// Info_CheckStates
//
//==============================================================================
procedure Info_CheckStates;

//==============================================================================
//
// Info_CheckStatesArgs
//
//==============================================================================
procedure Info_CheckStatesArgs;

//==============================================================================
//
// Info_GetNewState
//
//==============================================================================
function Info_GetNewState: integer;

//==============================================================================
//
// Info_GetNewMobjInfo
//
//==============================================================================
function Info_GetNewMobjInfo: integer;

//==============================================================================
//
// Info_GetSpriteNumForName
//
//==============================================================================
function Info_GetSpriteNumForName(const name: string): integer;

//==============================================================================
//
// Info_GetSpriteNameForNum
//
//==============================================================================
function Info_GetSpriteNameForNum(const id: integer): string;

//==============================================================================
//
// Info_CheckSpriteNumForName
//
//==============================================================================
function Info_CheckSpriteNumForName(const name: string): integer;

//==============================================================================
//
// Info_GetMobjNumForName
//
//==============================================================================
function Info_GetMobjNumForName(const name: string): integer;

//==============================================================================
//
// Info_SetMobjName
//
//==============================================================================
procedure Info_SetMobjName(const mobj_no: integer; const name: string);

//==============================================================================
//
// Info_GetMobjName
//
//==============================================================================
function Info_GetMobjName(const mobj_no: integer): string; overload;

//==============================================================================
//
// Info_GetMobjName
//
//==============================================================================
function Info_GetMobjName(const minfo: Pmobjinfo_t): string; overload;

//==============================================================================
//
// Info_ShutDown
//
//==============================================================================
procedure Info_ShutDown;

//==============================================================================
//
// Info_GetInheritance
//
//==============================================================================
function Info_GetInheritance(const imo: Pmobjinfo_t): integer;

//==============================================================================
//
// Info_AddMobjNameAlias
//
//==============================================================================
function Info_AddMobjNameAlias(const alias1: string; const alias2: string): boolean;

//==============================================================================
//
// Info_GetStatesForMobjInfo
//
//==============================================================================
function Info_GetStatesForMobjInfo(const mobjno: integer): TDNumberList;

//==============================================================================
//
// Info_AddStateOwner
//
//==============================================================================
procedure Info_AddStateOwner(const st: Pstate_t; const moidx: integer);

//==============================================================================
//
// Info_InitStateOwners
//
//==============================================================================
procedure Info_InitStateOwners;

//==============================================================================
//
// Info_ResolveMobjType
//
//==============================================================================
function Info_ResolveMobjType(const name: string; const mt: PInteger): boolean;

//==============================================================================
//
// Info_SaveActions
//
//==============================================================================
procedure Info_SaveActions;

//==============================================================================
//
// Info_RestoreActions
//
//==============================================================================
function Info_RestoreActions: boolean;

// MBF21 groups
const
  // infighting groups
  IG_INVALID = MININT;
  IG_DEFAULT = 0;
  IG_END = 1;
  // projectile groups
  PG_INVALID = MININT;
  PG_GROUPLESS = -1;
  PG_DEFAULT = 0;
  {$IFDEF DOOM}
  PG_BARON = 1;
  PG_END = 2;
  {$ELSE}
  PG_END = 1;
  {$ENDIF}
  // Splash groups
  SG_INVALID = MININT;
  SG_DEFAULT = 0;
  SG_END = 1;

//==============================================================================
//
// Info_InfightingGroupToString
//
//==============================================================================
function Info_InfightingGroupToString(const i: integer): string;

//==============================================================================
//
// Info_InfightingGroupToInt
//
//==============================================================================
function Info_InfightingGroupToInt(const s: string): integer;

//==============================================================================
//
// Info_ProjectileGroupToString
//
//==============================================================================
function Info_ProjectileGroupToString(const i: integer): string;

//==============================================================================
//
// Info_ProjectileGroupToInt
//
//==============================================================================
function Info_ProjectileGroupToInt(const s: string): integer;

//==============================================================================
//
// Info_SplashGroupToString
//
//==============================================================================
function Info_SplashGroupToString(const i: integer): string;

//==============================================================================
//
// Info_SplashGroupToInt
//
//==============================================================================
function Info_SplashGroupToInt(const s: string): integer;

implementation

uses
  d_think,
  i_system,
  m_fixed,
  p_common,
  p_spec,
  info,
  DelphiDoom.Info.SpriteNames;

var
  // given by ComposeEngine (Info_ConfigureThings, Info_ConfigureStates, Info_ConfigureGroups)
  things_service: IEngineInfoThings = nil;
  states_service: IEngineInfoStates = nil;
  groups_service: IEngineInfoGroups = nil;

//==============================================================================
//
// Info_ConfigureThings
//
//==============================================================================
procedure Info_ConfigureThings(const AThings: IEngineInfoThings);
begin
  things_service := AThings;
end;

//==============================================================================
//
// Info_ConfigureStates
//
//==============================================================================
procedure Info_ConfigureStates(const AStates: IEngineInfoStates);
begin
  states_service := AStates;
end;

//==============================================================================
//
// Info_ConfigureGroups
//
//==============================================================================
procedure Info_ConfigureGroups(const AGroups: IEngineInfoGroups);
begin
  groups_service := AGroups;
end;

//==============================================================================
//
// Info_Things
//
//==============================================================================
function Info_Things: IEngineInfoThings;
begin
  if things_service = nil then
    I_Error('Info_Things(): the info tables are not configured (ComposeEngine was not called)');
  result := things_service;
end;

//==============================================================================
//
// Info_States
//
//==============================================================================
function Info_States: IEngineInfoStates;
begin
  if states_service = nil then
    I_Error('Info_States(): the info tables are not configured (ComposeEngine was not called)');
  result := states_service;
end;

//==============================================================================
//
// Info_Groups
//
//==============================================================================
function Info_Groups: IEngineInfoGroups;
begin
  if groups_service = nil then
    I_Error('Info_Groups(): the info tables are not configured (ComposeEngine was not called)');
  result := groups_service;
end;

//==============================================================================
//
// Info_InitDnLookUp
//
//==============================================================================
procedure Info_InitDnLookUp;
begin
  Info_Things.Initialize;
end;

//==============================================================================
//
// Info_ShutDownDnLookUp
//
//==============================================================================
procedure Info_ShutDownDnLookUp;
begin
  if things_service <> nil then
    things_service.ShutDown;
end;

//==============================================================================
//
// Info_AddMobjNameAlias
//
//==============================================================================
function Info_AddMobjNameAlias(const alias1: string; const alias2: string): boolean;
begin
  result := Info_Things.AddAlias(alias1, alias2);
end;

//==============================================================================
//
// Info_GetMobjNumForDoomNum
//
//==============================================================================
function Info_GetMobjNumForDoomNum(const dn: integer): integer;
begin
  result := Info_Things.ThingForDoomedNumber(dn);
end;

//==============================================================================
//
// Info_CheckStates
//
//==============================================================================
procedure Info_CheckStates;
var
  endless: TArray<Integer>;
  i: integer;
begin
  endless := Info_States.StatesWithEndlessChain;
  for i := 0 to Length(endless) - 1 do
    I_Warning('Info_CheckStates(): State %d has possible infinite loop.'#13#10, [endless[i]]);
end;

//==============================================================================
//
// Info_CheckStatesArgs
//
//==============================================================================
procedure Info_CheckStatesArgs;
var
  i: integer;
begin
  for i := 0 to numstates - 1 do
    P_CheckStateArgs(@states[i]);
end;

//==============================================================================
//
// Info_GetNewState
//
//==============================================================================
function Info_GetNewState: integer;
const
  ST_GROWSTEP = 256;
begin
  if numstates >= numrealstates then
  begin
    realloc(pointer(states), numrealstates * SizeOf(state_t), (numrealstates + ST_GROWSTEP) * SizeOf(state_t));
    ZeroMemory(@states[numrealstates], ST_GROWSTEP * SizeOf(state_t));
    numrealstates := numrealstates + ST_GROWSTEP;
  end;
  states[numstates].sprite := Ord(SPR_NULL);
  states[numstates].tics := -1;
  states[numstates].tics2 := -1;
  states[numstates].nextstate := statenum_t(numstates);
  result := numstates;
  inc(numstates);
end;

//==============================================================================
//
// Info_GetNewMobjInfo
//
//==============================================================================
function Info_GetNewMobjInfo: integer;
const
  MI_GROWSTEP = 64;
begin
  if nummobjtypes >= numrealmobjtypes then
  begin
    realloc(pointer(mobjinfo), numrealmobjtypes * SizeOf(mobjinfo_t), (numrealmobjtypes + MI_GROWSTEP) * SizeOf(mobjinfo_t));
    ZeroMemory(@mobjinfo[numrealmobjtypes], MI_GROWSTEP * SizeOf(mobjinfo_t));
    numrealmobjtypes := numrealmobjtypes + MI_GROWSTEP;
  end;
  {$IFDEF STRIFE}
  mobjinfo[nummobjtypes].name2 := '';
  {$ENDIF}
  mobjinfo[nummobjtypes].inheritsfrom := -1; // Set to -1
  mobjinfo[nummobjtypes].doomednum := -1; // Set to -1
  mobjinfo[nummobjtypes].pushfactor := DEFPUSHFACTOR;
  mobjinfo[nummobjtypes].friction := ORIG_FRICTION;
  mobjinfo[nummobjtypes].scale := FRACUNIT;
  mobjinfo[nummobjtypes].gravity := FRACUNIT;
  mobjinfo[nummobjtypes].infighting_group := IG_DEFAULT;
  mobjinfo[nummobjtypes].projectile_group := PG_DEFAULT;
  mobjinfo[nummobjtypes].splash_group := SG_DEFAULT;
  result := nummobjtypes;
  inc(nummobjtypes);
end;

//==============================================================================
//
// Info_GetSpriteNumForName
//
//==============================================================================
function Info_GetSpriteNumForName(const name: string): integer;
var
  i: integer;
  check: integer;
begin
  if TInfoSpriteNames.TryParseIndex(name, numsprites, result) then
    exit;

  if not TInfoSpriteNames.TryCode(name, check) then
    I_Error('Info_GetSpriteNumForName(): Sprite name "%s" must have 4 characters', [name]);

  for i := 0 to numsprites - 1 do
    if sprnames[i] = check then
    begin
      result := i;
      exit;
    end;

  result := numsprites;

  sprnames[numsprites] := check;
  inc(numsprites);
  realloc(pointer(sprnames), numsprites * 4, (numsprites + 1) * 4);
  sprnames[numsprites] := 0;
end;

//==============================================================================
//
// Info_GetSpriteNameForNum
//
//==============================================================================
function Info_GetSpriteNameForNum(const id: integer): string;
begin
  result := '';
  if (id < 0) or (id >= numsprites) then
    exit;

  result := TInfoSpriteNames.NameOfCode(sprnames[id]);
end;

//==============================================================================
//
// Info_CheckSpriteNumForName
//
//==============================================================================
function Info_CheckSpriteNumForName(const name: string): integer;
var
  i: integer;
  check: integer;
begin
  if TInfoSpriteNames.TryParseIndex(name, numsprites, result) then
    exit;

  if not TInfoSpriteNames.TryCode(name, check) then
    I_Error('Info_CheckSpriteNumForName(): Sprite name "%s" must have 4 characters', [name]);

  for i := 0 to numsprites - 1 do
    if sprnames[i] = check then
    begin
      result := i;
      exit;
    end;

  result := -1;
end;

//==============================================================================
//
// Info_GetMobjNumForName
//
//==============================================================================
function Info_GetMobjNumForName(const name: string): integer;
begin
  result := Info_Things.ThingForName(name);
end;

//==============================================================================
//
// Info_SetMobjName
//
//==============================================================================
procedure Info_SetMobjName(const mobj_no: integer; const name: string);
var
  i: integer;
  len: integer;
begin
  len := Length(name);
  if len > MOBJINFONAMESIZE then
    len := MOBJINFONAMESIZE;
  for i := 0 to len - 1 do
    mobjinfo[mobj_no].name[i] := AnsiChar(name[i + 1]);
  for i := len to MOBJINFONAMESIZE - 1 do
    mobjinfo[mobj_no].name[i] := #0;
end;

//==============================================================================
//
// Info_GetMobjName
//
//==============================================================================
function Info_GetMobjName(const mobj_no: integer): string;
var
  i: integer;
  p: PAnsiChar;
begin
  result := '';
  p := @mobjinfo[mobj_no].name[0];
  for i := 0 to MOBJINFONAMESIZE - 1 do
    if p^ = #0 then
      exit
    else
    begin
      result := result + p^;
      inc(p);
    end;
end;

//==============================================================================
//
// Info_GetMobjName
//
//==============================================================================
function Info_GetMobjName(const minfo: Pmobjinfo_t): string; overload;
var
  i: integer;
  p: PAnsiChar;
begin
  result := '';
  p := @minfo.name[0];
  for i := 0 to MOBJINFONAMESIZE - 1 do
    if p^ = #0 then
      exit
    else
    begin
      result := result + p^;
      inc(p);
    end;
end;

//==============================================================================
//
// Info_ShutDown
//
//==============================================================================
procedure Info_ShutDown;
var
  i: integer;
begin
  Info_ShutDownDnLookUp;
  for i := 0 to numstates - 1 do
  begin
    if states[i].params <> nil then
      FreeAndNil(states[i].params);
    if states[i].owners <> nil then
      FreeAndNil(states[i].owners);
    if states[i].dlights <> nil then
      FreeAndNil(states[i].dlights);
{$IFDEF OPENGL}
    if states[i].models <> nil then
      FreeAndNil(states[i].models);
{$ENDIF}
    if states[i].voxels <> nil then
      FreeAndNil(states[i].voxels);
  end;

  memfree(pointer(states), numrealstates * SizeOf(state_t));
  memfree(pointer(mobjinfo), numrealmobjtypes * SizeOf(mobjinfo_t));
  memfree(pointer(sprnames), (numsprites + 1) * 4);
end;

//==============================================================================
//
// Info_GetInheritance
//
//==============================================================================
function Info_GetInheritance(const imo: Pmobjinfo_t): integer;
begin
  result := Info_Things.RootOf((NativeInt(imo) - NativeInt(@mobjinfo[0])) div SizeOf(mobjinfo_t));
end;

//==============================================================================
//
// Info_GetStatesForMobjInfo
//
//==============================================================================
function Info_GetStatesForMobjInfo(const mobjno: integer): TDNumberList;
var
  N: TDNumberList;
  found: TArray<Integer>;
  i: integer;
begin
  N := TDNumberList.Create;
  found := Info_States.StatesOfThing(mobjno);
  for i := 0 to Length(found) - 1 do
    N.Add(found[i]);
  result := N;
end;

//==============================================================================
//
// Info_AddStateOwner
//
//==============================================================================
procedure Info_AddStateOwner(const st: Pstate_t; const moidx: integer);
begin
  if (moidx < 0) or (moidx >= nummobjtypes) then
    exit;

  if st.owners = nil then
    st.owners := TDNumberList.Create;
  if st.owners.IndexOf(moidx) < 0 then
    st.owners.Add(moidx);
end;

//==============================================================================
//
// Info_InitStateOwners
//
//==============================================================================
procedure Info_InitStateOwners;
var
  N: TDNumberList;
  i, j: integer;
begin
  for i := 0 to nummobjtypes - 1 do
  begin
    N := Info_GetStatesForMobjInfo(i);
    for j := 0 to N.Count - 1 do
      Info_AddStateOwner(@states[N.Numbers[j]], i);
    N.Free;
  end;
end;

//==============================================================================
//
// Info_ResolveMobjType
//
//==============================================================================
function Info_ResolveMobjType(const name: string; const mt: PInteger): boolean;
begin
  if mt^ >= 0 then
  begin
    result := true;
    exit;
  end;

  if mt^ = -2 then
    mt^ := Info_GetMobjNumForName(name);

  result := mt^ >= 0;
end;

var
  save_actions: array[0..Ord(DO_NUMSTATES) - 1] of actionf_t;
  actions_saved: boolean = false;

//==============================================================================
//
// Info_SaveActions
//
//==============================================================================
procedure Info_SaveActions;
var
  i: integer;
begin
  for i := 0 to Ord(DO_NUMSTATES) - 1 do
    save_actions[i] := states[i].action;
  actions_saved := true;
end;

//==============================================================================
//
// Info_RestoreActions
//
//==============================================================================
function Info_RestoreActions: boolean;
var
  i: integer;
begin
  result := actions_saved;
  if not result then
    exit;

  for i := 0 to Ord(DO_NUMSTATES) - 1 do
    states[i].action := save_actions[i];
end;

//==============================================================================
//
// Info_InfightingGroupToString
//
//==============================================================================
function Info_InfightingGroupToString(const i: integer): string;
begin
  result := Info_Groups.InfightingToText(i);
end;

//==============================================================================
//
// Info_InfightingGroupToInt
//
//==============================================================================
function Info_InfightingGroupToInt(const s: string): integer;
begin
  result := Info_Groups.InfightingToValue(s);
end;

//==============================================================================
//
// Info_ProjectileGroupToString
//
//==============================================================================
function Info_ProjectileGroupToString(const i: integer): string;
begin
  result := Info_Groups.ProjectileToText(i);
end;

//==============================================================================
//
// Info_ProjectileGroupToInt
//
//==============================================================================
function Info_ProjectileGroupToInt(const s: string): integer;
begin
  result := Info_Groups.ProjectileToValue(s);
end;

//==============================================================================
//
// Info_SplashGroupToString
//
//==============================================================================
function Info_SplashGroupToString(const i: integer): string;
begin
  result := Info_Groups.SplashToText(i);
end;

//==============================================================================
//
// Info_SplashGroupToInt
//
//==============================================================================
function Info_SplashGroupToInt(const s: string): integer;
begin
  result := Info_Groups.SplashToValue(s);
end;

end.
