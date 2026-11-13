{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info tables - the old code of info_common,         }
{  info_fnd, info_rnd and of the state names of sc_states                      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// The routines of Base\info_common.pas, info_fnd.pas, info_rnd.pas and of the names of the states
// of sc_states.pas as they were before issue #185 (commit 63a151cc), cut out by the script that
// made this file and renamed with the prefix Legacy_ (the Doom branch of info_rnd). The tables of
// the game (mobjinfo, states, sprnames) are the variables below, filled by the test; the
// functions of the engine around the code (warnings, errors, N_Random, SC_AddConst, SC_EvalString)
// are replaced by stubs that write a log.
{$DEFINE DOOM}
unit DelphiDoom.Tests.InfoTables.LegacyInfo;

interface

uses
  System.SysUtils,
  System.Classes,
  d_delphi,
  DelphiDoom.Tests.InfoTables.LegacyTokens,
  DelphiDoom.Tests.InfoTables.LegacyParams;

const
  MOBJINFONAMESIZE = 30;
  // the things that are "built in": the first ones of the table
  DO_NUMMOBJTYPES = 10;
  S_NULL = 0;
  FF_FRAMEMASK = $7fff;
  MAXPLAYERS = 4;
  MF_SHOOTABLE = 4;
  MF_COUNTKILL = 4194304;
  MININT = Low(Integer);
  IG_INVALID = MININT;
  IG_DEFAULT = 0;
  IG_END = 1;
  PG_INVALID = MININT;
  PG_GROUPLESS = -1;
  PG_DEFAULT = 0;
  PG_BARON = 1;
  PG_END = 2;
  SG_INVALID = MININT;
  SG_DEFAULT = 0;
  SG_END = 1;
  MAXTABLE = 256;

type
  Pmobjinfo_t = ^mobjinfo_t;
  mobjinfo_t = record
    name: array[0..MOBJINFONAMESIZE - 1] of AnsiChar;
    inheritsfrom: integer;
    doomednum: integer;
    spawnstate: integer;
    spawnhealth: integer;
    seestate: integer;
    painstate: integer;
    meleestate: integer;
    missilestate: integer;
    deathstate: integer;
    xdeathstate: integer;
    raisestate: integer;
    healstate: integer;
    crashstate: integer;
    crushstate: integer;
    interactstate: integer;
    flags: integer;
  end;
  mobjinfo_tArray = array[0..MAXTABLE - 1] of mobjinfo_t;
  Pmobjinfo_tArray = ^mobjinfo_tArray;

  Pstate_t = ^state_t;
  state_t = record
    sprite: integer;
    frame: integer;
    tics: integer;
    nextstate: integer;
    owners: TDNumberList;
  end;
  state_tArray = array[0..MAXTABLE - 1] of state_t;
  Pstate_tArray = ^state_tArray;

  Pmobj_t = ^mobj_t;
  mobj_t = record
    info: Pmobjinfo_t;
    state: Pstate_t;
  end;

var
  mobjinfo: Pmobjinfo_tArray;
  states: Pstate_tArray;
  nummobjtypes: integer;
  numstates: integer;
  numsprites: integer;
  sprnames: PIntegerArray;
  legacy_statenames: TLegacyTokenList;
  infighting_groups: TDTextList;
  projectile_groups: TDTextList;
  splash_groups: TDTextList;
  // what the stubs write: warnings, errors and the constants added by the group names
  LegacyLog: TStringList;
  Legacy_NRandomFunc: TFunc<Integer>;
  Legacy_ValidFunc: TFunc<Integer, Boolean>;
  Legacy_SeedValue: Integer;

function Legacy_NRandom: integer;
function Legacy_ValidThing(const doomnum: integer): boolean;
function Legacy_SystemRandomSeed: integer;
procedure Legacy_Warning(const fmt: string); overload;
procedure Legacy_Warning(const fmt: string; const args: array of const); overload;
procedure Legacy_Error(const fmt: string); overload;
procedure Legacy_Error(const fmt: string; const args: array of const); overload;
function Legacy_SC_AddConst(const name: string; const value: integer): boolean;
function Legacy_IsMonsterOf(_type: integer): boolean;

procedure Legacy_Info_InitDnLookUp;
procedure Legacy_Info_ShutDownDnLookUp;
function Legacy_Info_AddMobjNameAlias(const alias1: string; const alias2: string): boolean;
function Legacy_Info_GetMobjNumForDoomNum(const dn: integer): integer;
procedure Legacy_Info_CheckStates;
function Legacy_Info_GetSpriteNumForName(const name: string): integer;
function Legacy_Info_GetSpriteNameForNum(const id: integer): string;
function Legacy_Info_CheckSpriteNumForName(const name: string): integer;
function Legacy_Info_GetMobjNumForName(const name: string): integer;
function Legacy_Info_GetMobjName(const mobj_no: integer): string;
function Legacy_Info_GetInheritance(const imo: Pmobjinfo_t): integer;
function Legacy_Info_GetStatesForMobjInfo(const mobjno: integer): TDNumberList;
function Legacy_Info_InfightingGroupToString(const i: integer): string;
function Legacy_Info_InfightingGroupToInt(const s: string): integer;
function Legacy_Info_ProjectileGroupToString(const i: integer): string;
function Legacy_Info_ProjectileGroupToInt(const s: string): integer;
function Legacy_Info_SplashGroupToString(const i: integer): string;
function Legacy_Info_SplashGroupToInt(const s: string): integer;
function Legacy_Info_FindStatesFromSprite(const sp: string): TDNumberList;
procedure Legacy_Info_InitRandomMonsters;
procedure Legacy_Info_ShutDownRandomMonsters;
function Legacy_Info_SelectRandomMonster(_type: integer): integer;
function Legacy_Info_IsMonster(_type: integer): boolean;
function Legacy_P_GetStateFromName(const actor: Pmobj_t; const s1: string): integer;
function Legacy_P_GetStateFromNameWithOffsetCheck(const actor: Pmobj_t; const s1: string): integer;

implementation

type
  randompool_t = record
    check: integer;
    list: TDNumberList;
  end;

const
  DNLOOKUPSIZE = $10000;
  NUMMONSTERSCATEGORIES = 5;

var
  dnLookUp: PIntegerArray = nil;
  mobjinfo_aliases: TDStringList = nil;
  rnd_monsters: array[0..NUMMONSTERSCATEGORIES - 1] of randompool_t;
  rnd_monstersinitialized: boolean = false;

function Legacy_NRandom: integer;
begin
  result := Legacy_NRandomFunc();
end;

function Legacy_ValidThing(const doomnum: integer): boolean;
begin
  result := Legacy_ValidFunc(doomnum);
end;

function Legacy_SystemRandomSeed: integer;
begin
  result := Legacy_SeedValue;
end;

procedure Legacy_Warning(const fmt: string);
begin
  LegacyLog.Add('warning ' + fmt);
end;

procedure Legacy_Warning(const fmt: string; const args: array of const);
begin
  LegacyLog.Add('warning ' + Format(fmt, args));
end;

procedure Legacy_Error(const fmt: string);
begin
  raise Exception.Create('error ' + fmt);
end;

procedure Legacy_Error(const fmt: string; const args: array of const);
begin
  raise Exception.Create('error ' + Format(fmt, args));
end;

function Legacy_SC_AddConst(const name: string; const value: integer): boolean;
begin
  LegacyLog.Add('const ' + name + ' ' + IntToStr(value));
  result := true;
end;

function Legacy_IsMonsterOf(_type: integer): boolean;
begin
  result := Legacy_Info_IsMonster(_type);
end;

procedure Legacy_Info_InitDnLookUp;
begin
  if dnLookUp = nil then
    dnLookUp := mallocz(DNLOOKUPSIZE * SizeOf(integer));

  if mobjinfo_aliases = nil then
    mobjinfo_aliases := TDStringList.Create;
end;


procedure Legacy_Info_ShutDownDnLookUp;
begin
  memfree(pointer(dnLookUp), DNLOOKUPSIZE * SizeOf(integer));
  mobjinfo_aliases.Free;
  mobjinfo_aliases := nil;
end;


function Legacy_Info_GetMobjNumForAlias(const name: string): integer;
const
  DEH_ACTOR_PREFIX = 'DEH_ACTOR_';
var
  i: integer;
  check: string;
  snum: string;
begin
  if mobjinfo_aliases = nil then
  begin
    result := -1;
    exit;
  end;

  check := strupper(strremovespaces(name));
  if Pos1(DEH_ACTOR_PREFIX, check) then
  begin
    snum := Copy(check, Length(DEH_ACTOR_PREFIX) + 1, Length(check) - Length(DEH_ACTOR_PREFIX));
    if StrIsLongWord(snum) then
    begin
      result := atoi(snum);
      if IsIntegerInRange(result, 0, nummobjtypes - 1) then
        exit;
    end;
  end;

  check := check + '=';
  for i := mobjinfo_aliases.Count - 1 downto 0 do
  begin
    if Pos1(check, mobjinfo_aliases.Strings[i]) then
    begin
      splitstring_ch(mobjinfo_aliases.Strings[i], check, snum, '=');
      result := atoi(snum);
      exit;
    end;
  end;

  result := -1;
end;


function Legacy_Info_AddMobjNameAlias(const alias1: string; const alias2: string): boolean;
var
  num1, num2: integer;
  str: string;
begin
  if mobjinfo_aliases = nil then
  begin
    result := false;
    exit;
  end;
  num1 := Legacy_Info_GetMobjNumForName(alias1);
  if num1 >= 0 then
  begin
    str := strupper(strremovespaces(alias2)) + '=' + itoa(num1);
    if mobjinfo_aliases.IndexOf(str) < 0 then
      mobjinfo_aliases.Add(str);
  end;
  num2 := Legacy_Info_GetMobjNumForName(alias2);
  if num2 >= 0 then
  begin
    str := strupper(strremovespaces(alias1)) + '=' + itoa(num2);
    if mobjinfo_aliases.IndexOf(str) < 0 then
      mobjinfo_aliases.Add(str);
  end;
  result := (num1 >= 0) or (num2 >= 0);
end;


function Legacy_Info_GetMobjNumForDoomNum(const dn: integer): integer;
var
  i: integer;
  idx: integer;
begin
  if dnLookUp <> nil then
  begin
    idx := dn mod DNLOOKUPSIZE;
    if (idx >= 0) and (idx < DNLOOKUPSIZE) then
    begin
      idx := dnLookUp[idx];
      if (idx >= 0) and (idx < nummobjtypes) then
        if mobjinfo[idx].doomednum = dn then
        begin
          result := idx;
          Exit;
        end;
    end;
  end;

  // JVAL 20201215
  // Changed traverse order of mobjinfo table.
  // For custom content [Ord(DO_NUMMOBJTYPES)..nummobjtypes - 1] the search is
  // done backwards.
  // For build-in content [0..Ord(DO_NUMMOBJTYPES) - 1] the search is done
  // forward

  // First Backward search for custom content
  for i := nummobjtypes - 1 downto Ord(DO_NUMMOBJTYPES) do
  begin
    if mobjinfo[i].doomednum = dn then
    begin
      result := i;
      if dnLookUp <> nil then
        dnLookUp[dn mod DNLOOKUPSIZE] := i;
      Exit;
    end;
  end;

  // Forward search for build-in content
  for i := 1 to Ord(DO_NUMMOBJTYPES) - 1 do
  begin
    if mobjinfo[i].doomednum = dn then
    begin
      result := i;
      if dnLookUp <> nil then
        dnLookUp[dn mod DNLOOKUPSIZE] := i;
      Exit;
    end;
  end;
  result := -1;
end;


procedure Legacy_Info_CheckStates;
var
  i: integer;
  loops: integer;
  st: Pstate_t;
begin
  for i := 0 to numstates - 1 do
  begin
    loops := 0;
    st := @states[i];
    repeat
      if st.nextstate = S_NULL then
        break;
      st := @states[Ord(st.nextstate)];
      inc(loops);
      if loops > $FFFF then
      begin
        Legacy_Warning('Legacy_Info_CheckStates(): State %d has possible infinite loop.'#13#10, [i]);
        break;
      end;
    until st.tics <> 0;
  end;
end;


function Legacy_Info_GetSpriteNumForName(const name: string): integer;
var
  spr_name: string;
  i: integer;
  check: integer;
begin
  result := atoi(name, -1);

  if (result >= 0) and (result < numsprites) and (itoa(result) = name) then
    exit;

  if Length(name) <> 4 then
    Legacy_Error('Legacy_Info_GetSpriteNumForName(): Sprite name "%s" must have 4 characters', [name]);

  spr_name := strupper(name);

  check := Ord(spr_name[1]) +
           Ord(spr_name[2]) shl 8 +
           Ord(spr_name[3]) shl 16 +
           Ord(spr_name[4]) shl 24;

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


function Legacy_Info_GetSpriteNameForNum(const id: integer): string;
var
  check: LongWord;
begin
  result := '';
  if (id < 0) or (id >= numsprites) then
    exit;

  check := PLongWord(@sprnames[id])^;
  result := Chr(check and $FF) + Chr((check shr 8) and $FF) + Chr((check shr 16) and $FF) + Chr((check shr 24) and $FF);
end;


function Legacy_Info_CheckSpriteNumForName(const name: string): integer;
var
  spr_name: string;
  i: integer;
  check: integer;
begin
  result := atoi(name, -1);

  if (result >= 0) and (result < numsprites) and (itoa(result) = name) then
    exit;

  if Length(name) <> 4 then
    Legacy_Error('Legacy_Info_CheckSpriteNumForName(): Sprite name "%s" must have 4 characters', [name]);

  spr_name := strupper(name);

  check := Ord(spr_name[1]) +
           Ord(spr_name[2]) shl 8 +
           Ord(spr_name[3]) shl 16 +
           Ord(spr_name[4]) shl 24;

  for i := 0 to numsprites - 1 do
    if sprnames[i] = check then
    begin
      result := i;
      exit;
    end;

  result := -1;
end;


function Legacy_Info_GetMobjNumForName(const name: string): integer;
var
  mobj_name: string;
  check: string;
  i: integer;
begin
  if (name = '') or (name = '-1') then
  begin
    result := -1;
    exit;
  end;

  result := atoi(name, -1);

  if (result >= 0) and (result < nummobjtypes) and (itoa(result) = name) then
    exit;

  mobj_name := strupper(strtrim(name));
  if Length(mobj_name) > MOBJINFONAMESIZE then
    SetLength(mobj_name, MOBJINFONAMESIZE);
  for i := nummobjtypes - 1 downto 0 do
  begin
    check := Legacy_Info_GetMobjName(i);
    trimprocU(check);
    if check = mobj_name then
    begin
      result := i;
      exit;
    end;
  end;

  mobj_name := strremovespaces(strupper(strtrim(name)));
  if Length(mobj_name) > MOBJINFONAMESIZE then
    SetLength(mobj_name, MOBJINFONAMESIZE);
  for i := nummobjtypes - 1 downto 0 do
  begin
    check := Legacy_Info_GetMobjName(i);
    check := strremovespaces(strupper(strtrim(check)));
    if check = mobj_name then
    begin
      result := i;
      exit;
    end;
  end;

  result := Legacy_Info_GetMobjNumForAlias(mobj_name);
end;


function Legacy_Info_GetMobjName(const mobj_no: integer): string;
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


function Legacy_Info_GetInheritance(const imo: Pmobjinfo_t): integer;
var
  mo: Pmobjinfo_t;
  loops: integer;
begin
  mo := imo;
  result := mo.inheritsfrom;

  if result <> -1 then
  begin
    loops := 0;
    while true do
    begin
      mo := @mobjinfo[mo.inheritsfrom];
      if mo.inheritsfrom = -1 then
        exit
      else
        result := mo.inheritsfrom;
      // JVAL: Prevent wrong inheritances of actordef lumps
      inc(loops);
      if loops > nummobjtypes then
      begin
        result := -1;
        break;
      end;
    end;
  end;

  if result = -1 then
    result :=  (integer(imo) - integer(@mobjinfo[0])) div SizeOf(mobjinfo_t);

end;


function Legacy_Info_GetStatesForMobjInfo(const mobjno: integer): TDNumberList;
var
  N: TDNumberList;
  st: integer;

  procedure _AddStates(stnum: integer);
  var
    i: integer;
  begin
    for i := 0 to numstates - 1 do
    begin
      if N.IndexOf(stnum) >= 0 then
        exit
      else
      begin
        if stnum <= 0 then
          exit;
        N.Add(stnum);
        stnum := Ord(states[stnum].nextstate);
        if stnum <= 0 then
          exit;
      end;
    end;
  end;

begin
  N := TDNumberList.Create;
  if mobjno < 0 then
  begin
    result := N;
    exit;
  end;

  _AddStates(mobjinfo[mobjno].spawnstate);
  _AddStates(mobjinfo[mobjno].seestate);
  _AddStates(mobjinfo[mobjno].painstate);
  _AddStates(mobjinfo[mobjno].meleestate);
  _AddStates(mobjinfo[mobjno].missilestate);
  _AddStates(mobjinfo[mobjno].deathstate);
  _AddStates(mobjinfo[mobjno].xdeathstate);
  _AddStates(mobjinfo[mobjno].raisestate);
  _AddStates(mobjinfo[mobjno].healstate);
  _AddStates(mobjinfo[mobjno].crashstate);
  _AddStates(mobjinfo[mobjno].crushstate);
  _AddStates(mobjinfo[mobjno].interactstate);

  for st := 0 to numstates - 1 do
    if states[st].owners <> nil then
      if N.IndexOf(st) < 0 then
        if states[st].owners.IndexOf(mobjno) >= 0 then
          N.Add(st);

  result := N;
end;


function Legacy_Info_InfightingGroupToString(const i: integer): string;
begin
  if i = IG_DEFAULT then
    result := 'IG_DEFAULT'
  else if i = IG_INVALID then
    result := 'IG_INVALID'
  else if IsIntegerInRange(i, 0, infighting_groups.Count - 1) then
    result := infighting_groups.Strings[i]
  else
    result := itoa(i);
end;


function Legacy_Info_InfightingGroupToInt(const s: string): integer;
var
  check: string;
begin
  check := strupper(s);
  if not Pos1('IG_', check) then
    check := 'IG_' + check;

  if check = 'IG_DEFAULT' then
  begin
    result := IG_DEFAULT;
    exit;
  end;

  if check = 'IG_INVALID' then
  begin
    result := IG_INVALID;
    exit;
  end;

  result := infighting_groups.IndexOf(check);
  if result >= 0 then
    exit;

  result := atoi(s);
  if result < 0 then
    result := IG_INVALID
  else
  begin
    check := 'IG_' + itoa(result);
    result := infighting_groups.Add(check);
    Legacy_SC_AddConst(check, result); // JVAL: 20220104 - Dynamically add const
  end;
end;


function Legacy_Info_ProjectileGroupToString(const i: integer): string;
begin
  if i = PG_GROUPLESS then
    result := 'PG_GROUPLESS'
  else if i = PG_INVALID then
    result := 'PG_INVALID'
  else if i = PG_DEFAULT then
    result := 'PG_DEFAULT'
  {$IFDEF DOOM}
  else if i = PG_BARON then
    result := 'PG_BARON'
  {$ENDIF}
  else if IsIntegerInRange(i, 0, projectile_groups.Count - 1) then
    result := projectile_groups.Strings[i]
  else
    result := itoa(i);
end;


function Legacy_Info_ProjectileGroupToInt(const s: string): integer;
var
  check: string;
begin
  check := strupper(s);
  if not Pos1('PG_', check) then
    check := 'PG_' + check;

  if check = 'PG_GROUPLESS' then
  begin
    result := PG_GROUPLESS;
    exit;
  end;

  if check = 'PG_INVALID' then
  begin
    result := PG_INVALID;
    exit;
  end;

  if check = 'PG_DEFAULT' then
  begin
    result := PG_DEFAULT;
    exit;
  end;

  {$IFDEF DOOM}
  if check = 'PG_BARON' then
  begin
    result := PG_BARON;
    exit;
  end;
  {$ENDIF}

  result := projectile_groups.IndexOf(check);
  if result >= 0 then
    exit;

  result := atoi(s);
  if result < 0 then
    result := PG_GROUPLESS
  else
  begin
    check := 'PG_' + itoa(result);
    result := projectile_groups.Add(check);
    Legacy_SC_AddConst(check, result); // JVAL: 20220104 - Dynamically add const
  end;
end;


function Legacy_Info_SplashGroupToString(const i: integer): string;
begin
  if i = SG_DEFAULT then
    result := 'SG_DEFAULT'
  else if i = SG_INVALID then
    result := 'SG_INVALID'
  else if IsIntegerInRange(i, 0, splash_groups.Count - 1) then
    result := splash_groups.Strings[i]
  else
    result := itoa(i);
end;


function Legacy_Info_SplashGroupToInt(const s: string): integer;
var
  check: string;
begin
  check := strupper(s);
  if not Pos1('SG_', check) then
    check := 'SG_' + check;

  if check = 'SG_DEFAULT' then
  begin
    result := SG_DEFAULT;
    exit;
  end;

  if check = 'SG_INVALID' then
  begin
    result := SG_INVALID;
    exit;
  end;

  result := splash_groups.IndexOf(check);
  if result >= 0 then
    exit;

  result := atoi(s);
  if result < 0 then
    result := SG_INVALID
  else
  begin
    check := 'SG_' + itoa(result);
    result := splash_groups.Add(check);
    Legacy_SC_AddConst(check, result); // JVAL: 20220104 - Dynamically add const
  end;
end;


function Legacy_Info_FindStatesFromSprite(const sp: string): TDNumberList;
var
  spr: string;
  spr_idx: integer;
  frm: integer;
  i: integer;
  sp_idx: integer;
begin
  result := TDNumberList.Create;

  if length(sp) = 4 then
  begin
    spr := strupper(sp);
    spr_idx := Ord(spr[1]) +
               Ord(spr[2]) shl 8 +
               Ord(spr[3]) shl 16 +
               Ord(spr[4]) shl 24;

    sp_idx := -1;
    for i := 0 to numsprites - 1 do
      if sprnames[i] = spr_idx then
      begin
        sp_idx := i;
        break;
      end;
    if sp_idx = -1 then
      exit;

    for i := 0 to numstates - 1 do
    begin
      if states[i].sprite = sp_idx then
        result.Add(i)
    end;

    exit;
  end;

  if length(sp) = 5 then
  begin
    spr := strupper(sp[1] + sp[2] + sp[3] + sp[4]);
    spr_idx := Ord(spr[1]) +
               Ord(spr[2]) shl 8 +
               Ord(spr[3]) shl 16 +
               Ord(spr[4]) shl 24;

    sp_idx := -1;
    for i := 0 to numsprites - 1 do
      if sprnames[i] = spr_idx then
      begin
        sp_idx := i;
        break;
      end;
    if sp_idx = -1 then
      exit;

    frm := Ord(toupper(sp[5])) - Ord('A');

    for i := 0 to numstates - 1 do
    begin
      if states[i].sprite = sp_idx then
        if states[i].frame and FF_FRAMEMASK = frm then
          result.Add(i)
    end;

    exit;
  end;

end;


procedure Legacy_Info_InitRandomMonsters;
var
  i: integer;
  idx: integer;
  check: integer;
begin
  if rnd_monstersinitialized then
    exit;

{$IF DEFINED(HERETIC)}
  if G_PlayingEngineVersion > VERSION110 then
  begin
    rnd_monsters[0].check := 90;
    rnd_monsters[1].check := 120;
    rnd_monsters[2].check := 220;
    rnd_monsters[3].check := 1000;
  end
  else
  begin
    rnd_monsters[0].check := 80;
    rnd_monsters[1].check := 400;
    rnd_monsters[2].check := 1200;
    rnd_monsters[3].check := 2500;
  end;
{$ELSEIF DEFINED(HEXEN)}
{  rnd_monsters[0].check := 290;
  rnd_monsters[1].check := 360;
  rnd_monsters[2].check := 400;
  rnd_monsters[3].check := 2000;}
  rnd_monsters[0].check := 1000000;
  rnd_monsters[1].check := 1000000;
  rnd_monsters[2].check := 1000000;
  rnd_monsters[3].check := 1000000;
{$ELSE}
  rnd_monsters[0].check := 80;
  rnd_monsters[1].check := 400;
  rnd_monsters[2].check := 1200;
  rnd_monsters[3].check := 2500;
{$ENDIF}
  rnd_monsters[4].check := MAXINT;

  for i := 0 to NUMMONSTERSCATEGORIES - 1 do
    rnd_monsters[i].list := TDNumberList.Create;

  rnd_monstersinitialized := true;

  for i := 0 to nummobjtypes - 1 do
    if Legacy_Info_IsMonster(i) and Legacy_ValidThing(mobjinfo[i].doomednum) then
    begin
      check := mobjinfo[i].spawnhealth;
      idx := 0;
      while (idx < NUMMONSTERSCATEGORIES) and (check >= rnd_monsters[idx].check) do
        inc(idx);
      rnd_monsters[idx].list.Add(i);
    end;
end;


procedure Legacy_Info_ShutDownRandomMonsters;
var
  i: integer;
begin
  if not rnd_monstersinitialized then
    exit;

  for i := 0 to NUMMONSTERSCATEGORIES - 1 do
    FreeAndNil(rnd_monsters[i].list);

  rnd_monstersinitialized := false;
end;


function Legacy_Info_SelectRandomMonster(_type: integer): integer;
var
  idx: integer;
  check: integer;
{$IFNDEF HEXEN}
  i: integer;
{$ENDIF}
begin
  check := mobjinfo[_type].spawnhealth;
  idx := 0;
  while (idx < NUMMONSTERSCATEGORIES) and (check >= rnd_monsters[idx].check) do
    inc(idx);
{$IFNDEF HEXEN}

  for i := 0 to Legacy_SystemRandomSeed - 1 do
    Legacy_NRandom;
{$ENDIF}

  result := rnd_monsters[idx].list[Legacy_NRandom mod rnd_monsters[idx].list.Count];
end;


function Legacy_Info_IsMonster(_type: integer): boolean;
begin
{$IFDEF HEXEN}
  result := (mobjinfo[_type].doomednum > MAXPLAYERS) and      // Not player
            (mobjinfo[_type].doomednum <> 9100) and           // Not player
            (mobjinfo[_type].doomednum <> 9101) and           // Not player
            (mobjinfo[_type].doomednum <> 9102) and           // Not player
            (mobjinfo[_type].doomednum <> 9103) and           // Not player
            (mobjinfo[_type].flags and MF_SHOOTABLE <> 0) and // Shootable
            (mobjinfo[_type].flags and MF_COUNTKILL <> 0);    // Count kill or can attack
{$ELSE}
  result := (mobjinfo[_type].doomednum > MAXPLAYERS) and // Not player
            (mobjinfo[_type].flags and MF_SHOOTABLE <> 0) and  // Shootable
            ((mobjinfo[_type].flags and MF_COUNTKILL <> 0) or (mobjinfo[_type].missilestate <> 0) or (mobjinfo[_type].meleestate <> 0));  // Count kill or can attack
{$ENDIF}
end;


function Legacy_P_GetStateFromName(const actor: Pmobj_t; const s1: string): integer;
var
  s, st: string;
  fw, sw: string;
  pps, ppp, ppb: integer;

  function _stindex(const sss: string): integer;
  var
    sss1, sss2: string;
    p, idx: integer;
    inf: Pmobjinfo_t;
  begin
    result := legacy_statenames.IndexOfToken(sss);
    if result >= 0 then
      exit;

    sss1 := strupper(sss);

    p := Pos('::', sss1);
    if p < 2 then // eg allow "goto ::spawn"
      inf := actor.info
    else
    begin
      sss2 := strtrim(Copy(sss1, 1, p - 1));
      sss1 := Copy(sss1, p + 2, Length(sss1) - p - 3);
      if sss2 = 'SUPER' then
        idx := actor.info.inheritsfrom
      else
        idx := Legacy_Info_GetMobjNumForName(sss2);
      if (idx >= 0) and (idx < nummobjtypes) then
        inf := @mobjinfo[idx]
      else if sss2 = 'SELF' then // eg allow "goto self::spawn"
        inf := actor.info
      else
        inf := nil;
    end;

    if inf <> nil then
    begin
      if sss1 = 'SPAWN' then
      begin
        result := inf.spawnstate;
        exit;
      end
      else if sss1 = 'SEE' then
      begin
        result := inf.seestate;
        exit;
      end
      else if sss1 = 'MELEE' then
      begin
        result := inf.meleestate;
        exit;
      end
      else if sss1 = 'MISSILE' then
      begin
        result := inf.missilestate;
        exit;
      end
      else if sss1 = 'MISSILE' then
      begin
        result := inf.missilestate;
        exit;
      end
      else if sss1 = 'PAIN' then
      begin
        result := inf.painstate;
        exit;
      end
      else if sss1 = 'DEATH' then
      begin
        result := inf.deathstate;
        exit;
      end
      else if sss1 = 'XDEATH' then
      begin
        result := inf.xdeathstate;
        exit;
      end
      else if sss1 = 'RAISE' then
      begin
        result := inf.raisestate;
        exit;
      end
      else if sss1 = 'CRASH' then
      begin
        result := inf.crashstate;
        exit;
      end
      else if sss1 = 'CRUSH' then
      begin
        result := inf.crushstate;
        exit;
      end
      else if sss1 = 'INTERACT' then
      begin
        result := inf.interactstate;
        exit;
      end
    end;

    sss1 := 'S_' + strupper(actor.info.name) + '_' + sss;
    result := legacy_statenames.IndexOfToken(sss1);
    if result < 0 then
      if StrIsLongWord(s1) then
        result := atoi(s1);
  end;

begin
  s := Legacy_EvalString(s1);
  st := strupper(strtrim(s));
  pps := CharPos('+', st);
  ppp := CharPos('-', st);
  ppb := CharPos(' ', st);
  if (ppb = 0) and (ppp = 0) and (pps = 0) then
  begin
    Result := _stindex(st);
    Exit;
  end
  else
  // JVAL: 20170927 evaluate small expressions
  //       20191003 rewritten, fixed
  begin
    st := strremovespaces(st);
    pps := CharPos('+', st);
    ppp := CharPos('-', st);
    if pps > 0 then
    begin
      splitstring_ch(st, fw, sw, '+');
      Result := _stindex(fw) + atoi(sw, 0);
      Exit;
    end;
    if ppp > 0 then
    begin
      splitstring_ch(st, fw, sw, '-');
      Result := _stindex(fw) - atoi(sw, 0);
      Exit;
    end;
  end;
  Result := -1; // JVAL: No match
end;


function Legacy_P_GetStateFromNameWithOffsetCheck(const actor: Pmobj_t; const s1: string): integer;
var
  s: string;
  check: string;
begin
  s := Legacy_EvalString(s1);
  check := s;
  if check = '' then
  begin
    Result := 0;
    Exit;
  end;

  if check[1] in ['-', '+'] then
    Delete(check, 1, 1);

  if StrIsLongWord(check) then
    Result := ((integer(actor.state) - integer(states)) div SizeOf(state_t)) + atoi(s)
  else
    Result := Legacy_P_GetStateFromName(actor, s);
end;


end.