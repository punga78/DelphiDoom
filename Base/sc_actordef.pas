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
//
// DESCRIPTION:
//  ACTORDEF lump parser (Custom defined enemies)
//  SNDINFO lump parser (Sound aliases)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit sc_actordef;

interface

uses
  System.SysUtils,
  d_delphi,
  info_h,
  DelphiDoom.ActorDef.Intf;

//==============================================================================
//
// SC_ParseSndInfoLumps
//
//==============================================================================
procedure SC_ParseSndInfoLumps;

//==============================================================================
//
// SC_ParseActordefLumps
//
//==============================================================================
procedure SC_ParseActordefLumps;

//==============================================================================
//
// SC_ParseActordefLump
//
//==============================================================================
procedure SC_ParseActordefLump(const in_text: string);

//==============================================================================
//
// SC_Init
//
//==============================================================================
procedure SC_Init;

//==============================================================================
//
// SC_ShutDown
//
//==============================================================================
procedure SC_ShutDown;

//==============================================================================
//
// SC_ConfigureActorDef
//
//==============================================================================
procedure SC_ConfigureActorDef(const AParser: IActorDefParser; const AParseSoundInfo: TProc<string>;
  const ASounds: IActorDefSoundResolver);

//==============================================================================
//
// SC_SoundAlias
//
//==============================================================================
function SC_SoundAlias(const snd: string): string;


//==============================================================================
//
// SC_GetActordefDeclaration
//
//==============================================================================
function SC_GetActordefDeclaration(const m: Pmobjinfo_t): string;

//==============================================================================
//
// SC_GetWeapondefDeclaration
//
//==============================================================================
function SC_GetWeapondefDeclaration(const wid: integer{$IFDEF HERETIC}; const lvl: integer{$ENDIF}{$IFDEF HEXEN}; const pcl: integer{$ENDIF}): string;

var
  decorate_as_actordef: boolean = true;

implementation

uses
  TypInfo,
  doomdef,
  {$IFDEF DOOM_OR_STRIFE}
  d_items,
  {$ENDIF}
  {$IFDEF HERETIC}
  p_pspr_h,
  {$ENDIF}
  d_main,
  c_cmds,
  deh_base,
  deh_main,
  m_fixed,
  i_system,
  {$IFNDEF FPC}
  i_startup,
  {$ENDIF}
  info,
  info_common,
  r_renderstyle,
  r_translations,
  {$IFDEF HEXEN}
  sounddata,
  {$ENDIF}
  sounds,
  sc_consts,
  sc_engine,
  sc_states,
  sc_tokens,
  sc_evaluate_actor,
  sc_utils,
  p_pspr,
  p_spec,
  p_mobj_h,
  p_gender,
  ps_main,
  w_pak,
  w_wad;

const
  ACTORDEFLUMPNAME = 'ACTORDEF';
  DECORATELUMPNAME = 'DECORATE';
  SNDINFOLUMPNAME = 'SNDINFO';

var
  GActorDefParser: IActorDefParser;
  GParseSoundInfo: TProc<string>;
  GSounds: IActorDefSoundResolver;
  sound_tx: string;

//==============================================================================
//
// SC_ConfigureActorDef
//
//==============================================================================
procedure SC_ConfigureActorDef(const AParser: IActorDefParser; const AParseSoundInfo: TProc<string>;
  const ASounds: IActorDefSoundResolver);
begin
  GActorDefParser := AParser;
  GParseSoundInfo := AParseSoundInfo;
  GSounds := ASounds;
end;

//==============================================================================
//
// SC_SoundAlias
//
//==============================================================================
function SC_SoundAlias(const snd: string): string;
begin
  if not Assigned(GSounds) then
    I_Error('SC_SoundAlias(): the sound aliases are not configured (ComposeEngine was not called)');
  Result := GSounds.Resolve(snd);
end;

//==============================================================================
//
// SC_ParseActordefLump
//
//==============================================================================
procedure SC_ParseActordefLump(const in_text: string);
begin
  if not Assigned(GActorDefParser) then
    I_Error('SC_ParseActordefLump(): the ACTORDEF parser is not configured (ComposeEngine was not called)');
  GActorDefParser.Parse(in_text);
end;

//==============================================================================
//
// SC_RetrieveSndInfo
//
//==============================================================================
procedure SC_RetrieveSndInfo(const in_text: string);
var
  LText: string;
begin
  LText := SC_Preprocess(in_text, false);
  if sound_tx = '' then
    sound_tx := LText
  else
    sound_tx := sound_tx + #13#10 + LText;
end;

//==============================================================================
//
// SC_ParseSndInfoLumps
//
//==============================================================================
procedure SC_ParseSndInfoLumps;
var
  i: integer;
begin
  if not Assigned(GParseSoundInfo) then
    I_Error('SC_ParseSndInfoLumps(): SNDINFO is not configured (ComposeEngine was not called)');

// Retrive sndinfo lumps for sound alias list
  sound_tx := '';
  for i := 0 to W_NumLumps - 1 do
  begin
    if char8tostring(W_GetNameForNum(i)) = SNDINFOLUMPNAME then
    begin
      if sound_tx = '' then
        sound_tx := W_TextLumpNum(i)
      else
        sound_tx := sound_tx + #13#10 + W_TextLumpNum(i);
    end;
  end;

  PAK_StringIterator(SNDINFOLUMPNAME, SC_RetrieveSndInfo);
  PAK_StringIterator(SNDINFOLUMPNAME + '.txt', SC_RetrieveSndInfo);

  GParseSoundInfo(sound_tx);
end;

//==============================================================================
//
// SC_ParseActordefLumps
//
//==============================================================================
procedure SC_ParseActordefLumps;
var
  i: integer;
  lumplist: TDNumberList;
begin
  SC_ParseStatedefLump;

  {$IFNDEF FPC}
  SUC_Disable;
  {$ENDIF}

// Retrive actordef lumps
  lumplist := TDNumberList.Create;
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = ACTORDEFLUMPNAME then
      lumplist.Add(i);

  if decorate_as_actordef then
    for i := 0 to W_NumLumps - 1 do
      if char8tostring(W_GetNameForNum(i)) = DECORATELUMPNAME then
        lumplist.Add(i);

  {$IFNDEF FPC}
  SUC_SecondaryProgressInit(lumplist.Count);
  {$ENDIF}

  for i := 0 to lumplist.Count - 1 do
  begin
    {$IFNDEF FPC}
    SUC_SecondaryProgress(i);
    {$ENDIF}
    SC_ParseActordefLump(W_TextLumpNum(lumplist[i]));
  end;

  {$IFNDEF FPC}
  SUC_SecondaryProgressDone;
  {$ENDIF}
  PAK_StringIterator(ACTORDEFLUMPNAME, SC_ParseActordefLump);
  PAK_StringIterator(ACTORDEFLUMPNAME + '.txt', SC_ParseActordefLump);

  if decorate_as_actordef then
  begin
    PAK_StringIterator(DECORATELUMPNAME, SC_ParseActordefLump);
    PAK_StringIterator(DECORATELUMPNAME + '.txt', SC_ParseActordefLump);
  end;

  lumplist.Free;

  {$IFNDEF FPC}
  SUC_Enable;
  {$ENDIF}
end;

//==============================================================================
//
// SC_Init
//
//==============================================================================
procedure SC_Init;
begin
  SC_InitActorEvaluator;
  SC_InitConsts;
  C_AddCmd('DEH_PrintActordef, PrintActordef', @DEH_PrintActordef);
  C_AddCmd('DEH_SaveActordef, SaveActordef', @DEH_SaveActordef);
  C_AddCmd('DEH_PrintWeapondef, PrintWeapondef', @DEH_PrintWeapondef);
  C_AddCmd('DEH_SaveWeapondef, SaveWeapondef', @DEH_SaveWeapondef);
  C_AddCmd('DEH_PrintStateOwners, PrintStateOwners', @DEH_PrintStateOwners);
  C_AddCmd('DEH_SaveStateOwners, SaveStateOwners', @DEH_SaveStateOwners);
end;

//==============================================================================
//
// SC_ShutDown
//
//==============================================================================
procedure SC_ShutDown;
begin
  statenames.Free;
  SC_ShutDownConsts;
  SC_ShutDownActorEvaluator;
end;

//==============================================================================
//
// SC_GetActordefDeclaration
//
//==============================================================================
function SC_GetActordefDeclaration(const m: Pmobjinfo_t): string;
var
  ret: string;
  plevel: integer;
  i: integer;
  id: integer;

  procedure AddLn(const s: string);
  var
    blanks: string;
    i: integer;
  begin
    if s = '}' then
      dec(plevel);
    blanks := '';
    for i := 0 to plevel - 1 do
      blanks := blanks + '  ';
    if s = '{' then
      inc(plevel);
    ret := ret + blanks + s + #13#10;
  end;

  function OtherStateGoto(const st: integer): boolean;
  begin
    result := true;
    if st = m.spawnstate then
    begin
      AddLn('Goto Spawn');
      exit;
    end;

    if st = m.seestate then
    begin
      AddLn('Goto See');
      exit;
    end;

    if st = m.meleestate then
    begin
      AddLn('Goto Melee');
      exit;
    end;

    if st = m.missilestate then
    begin
      AddLn('Goto Missile');
      exit;
    end;

    if st = m.painstate then
    begin
      AddLn('Goto Pain');
      exit;
    end;

    if st = m.deathstate then
    begin
      AddLn('Goto Death');
      exit;
    end;

    if st = m.xdeathstate then
    begin
      AddLn('Goto Xdeath');
      exit;
    end;

    if st = m.raisestate then
    begin
      AddLn('Goto Raise');
      exit;
    end;

    if st = m.healstate then
    begin
      AddLn('Goto Heal');
      exit;
    end;

    if st = m.crashstate then
    begin
      AddLn('Goto Crash');
      exit;
    end;

    if st = m.crushstate then
    begin
      AddLn('Goto Crush');
      exit;
    end;

    if st = m.interactstate then
    begin
      AddLn('Goto Interact');
      exit;
    end;

    result := false;
  end;

  procedure AddState(const s: string; const st: integer);
  var
    sst: Pstate_t;
    spr: string;
    A: TDNumberList;
    idx: integer;
    act: string;
    stics: string;
  begin
    if st <= 0 then
      exit;

    A := TDNumberList.Create;
    A.Add(st);

    sst := @states[st];

    while true do
    begin
      if A.Count = 1 then
      begin
        AddLn(s + ':');
        AddLn('{');
      end;

      spr :=
        Chr(sprnames[sst.sprite] and $FF) +
        Chr((sprnames[sst.sprite] shr 8) and $FF) +
        Chr((sprnames[sst.sprite] shr 16) and $FF) +
        Chr((sprnames[sst.sprite] shr 24) and $FF);

      if not Assigned(sst.action.acv) then
        act := ''
      else
      begin
        act := DEH_ActionName(sst.action);
        if act = 'NULL' then
          act := ''
        else
        begin
          act := ' ' + act;
          if sst.params <> nil then
            act := act + ' ' + sst.params.Declaration;  // Add the parameter list
        end;
      end;

      if sst.flags_ex and MF_EX_STATE_RANDOM_SELECT <> 0 then
        stics := 'RANDOMSELECT(' + itoa(sst.tics) + ',' + itoa(sst.tics2) + ')'
      else if sst.flags_ex and MF_EX_STATE_RANDOM_RANGE <> 0 then
        stics := 'RANDOMRANGE(' + itoa(sst.tics) + ',' + itoa(sst.tics2) + ')'
      else
        stics := itoa(sst.tics);
      AddLn(
        spr + ' ' +
        Chr(Ord('A') + sst.frame and FF_FRAMEMASK) + ' ' +
        stics +
        act +
        decide(sst.frame and FF_FULLBRIGHT <> 0, ' BRIGHT', '') +
        decide(sst.mbf21bits and STATEF_SKILL5FAST <> 0, ' FAST', '')
      );

      if sst.tics < 0 then
        break;
      if Ord(sst.nextstate) <= 0 then
      begin
        AddLn('Stop');
        break;
      end;
      idx := A.IndexOf(Ord(sst.nextstate));
      if idx >= 0 then
      begin
        if idx = 0 then
          AddLn('Loop')
        else
          AddLn('Goto ' + s + '+' + itoa(idx));
        break;
      end;
      if OtherStateGoto(Ord(sst.nextstate)) then
        break;
      A.Add(Ord(sst.nextstate));
      sst := @states[Ord(sst.nextstate)];
    end;
    AddLn('}');
    A.Free;
  end;

begin
  ret := '';
  plevel := 0;

  id := pDiff(m, mobjinfo, SizeOf(mobjinfo_t));
  if IsIntegerInRange(id, 0, Ord(DO_NUMMOBJTYPES) - 1) then
    Addln('// ' + strupper(GetENumName(TypeInfo(mobjtype_t), Ord(id))));

  AddLn('ACTOR "' + Info_GetMobjName(m) + '"' + decide(m.doomednum > 0, ' ' + itoa(m.doomednum), ''));
  AddLn('{');
  if m.spawnhealth > 0 then
    AddLn('Health ' + itoa(m.spawnhealth));
  if m.inheritsfrom >= 0 then
    AddLn('Inherits "' + Info_GetMobjName(@mobjinfo[m.inheritsfrom]) + '"');
  AddLn('Width ' + itoa(m.radius div FRACUNIT));
  AddLn('Height ' + itoa(m.height div FRACUNIT));
  if m.vspeed <> 0 then
    AddLn('Vspeed ' + ftoafmt('2.4', m.vspeed / FRACUNIT));
  if m.minmissilechance <> 0 then
    AddLn('MinMissileChance ' + itoa(m.minmissilechance));
  if m.pushfactor <> DEFPUSHFACTOR then
    AddLn('Pushfactor ' + itoa(m.pushfactor));
  if m.friction <> ORIG_FRICTION then
    AddLn('Friction ' + itoa(m.friction));
  if m.scale <> FRACUNIT then
    AddLn('Scale ' + ftoafmt('2.4', m.scale / FRACUNIT));
  if m.gravity <> FRACUNIT then
    AddLn('Gravity ' + ftoafmt('2.4', m.gravity / FRACUNIT));
  if m.speed <> 0 then
    AddLn('Speed ' + itoa(m.speed));
  if m.damage <> 0 then
    AddLn('Damage ' + itoa(m.damage));
  if m.painchance <> 0 then
    AddLn('Painchance ' + itoa(m.painchance));
  if m.mass <> 0 then
    AddLn('Mass ' + itoa(m.mass));
  if m.reactiontime <> 0 then
    AddLn('Reactiontime ' + itoa(m.reactiontime));
  if m.dropitem > 0 then
    AddLn('Dropitem "' + Info_GetMobjName(@mobjinfo[m.dropitem]) + '"');
  if m.missiletype > 0 then
    AddLn('Missiletype "' + Info_GetMobjName(@mobjinfo[m.missiletype]) + '"');
  if m.explosiondamage > 0 then
    AddLn('Explosiondamage ' + itoa(m.explosiondamage));
  if m.explosionradius > 0 then
    AddLn('Explosionradius ' + itoa(m.explosionradius));
  if m.meleedamage > 0 then
    AddLn('Meleedamage ' + itoa(m.meleedamage));
  if m.seesound > 0 then
    AddLn('Seesound ' + S_GetSoundNameForNum(m.seesound));
  if m.attacksound > 0 then
    AddLn('Attacksound ' + S_GetSoundNameForNum(m.attacksound));
  if m.painsound > 0 then
    AddLn('Painsound ' + S_GetSoundNameForNum(m.painsound));
  if m.deathsound > 0 then
    AddLn('Deathsound ' + S_GetSoundNameForNum(m.deathsound));
  if m.activesound > 0 then
    AddLn('Activesound ' + S_GetSoundNameForNum(m.activesound));
  if m.customsound1 > 0 then
    AddLn('Customsound1 ' + S_GetSoundNameForNum(m.customsound1));
  if m.customsound2 > 0 then
    AddLn('Customsound2 ' + S_GetSoundNameForNum(m.customsound2));
  if m.customsound3 > 0 then
    AddLn('Customsound3 ' + S_GetSoundNameForNum(m.customsound3));
  if m.meleesound > 0 then
    AddLn('Meleesound ' + S_GetSoundNameForNum(m.meleesound));
  if m.ripsound > 0 then
    AddLn('Ripsound ' + S_GetSoundNameForNum(m.ripsound));
  if m.floatspeed > 0 then
    AddLn('Floatspeed ' + itoa(m.floatspeed));
  if m.normalspeed > 0 then
    AddLn('Normalspeed ' + itoa(m.normalspeed));
  if m.fastspeed > 0 then
    AddLn('Fastspeed ' + itoa(m.fastspeed));
  if m.obituary <> '' then
    AddLn('Obituary ' + '"' + m.obituary + '"');
  if m.hitobituary <> '' then
    AddLn('HitObituary ' + '"' + m.hitobituary + '"');
  if m.missileheight > 0 then
    AddLn('MissileHeight ' + itoa(m.missileheight));
  if m.meleethreshold > 0 then
    AddLn('MeleeThreshold ' + itoa(m.meleethreshold));
  if m.renderstyle <> mrs_normal then
  begin
    AddLn('Renderstyle ' + renderstyle_tokens[Ord(m.renderstyle)]);
    if m.alpha > 0 then
      AddLn('Alpha ' + ftoafmt('2.4', m.alpha / FRACUNIT));
  end;
  if m.gender <> gender_Default then
    AddLn('Gender ' + GENDERINFO[Ord(m.gender)].name);
  if m.meleerange <> 0 then
    AddLn('MeleeRange ' + itoa(m.meleerange));
  if m.maxstepheight <> 0 then
    AddLn('MaxStepHeight ' + ftoafmt('2.4', m.maxstepheight / FRACUNIT));
  if m.maxdropoffheight <> 0 then
    AddLn('MaxDropOffHeight ' + ftoafmt('2.4', m.maxdropoffheight / FRACUNIT));
  if m.gibhealth <> 0 then
    AddLn('GibHealth ' + itoa(m.gibhealth));
  if m.maxtargetrange <> 0 then
    AddLn('MaxTargetRange ' + itoa(m.maxtargetrange));
  if m.WeaveIndexXY <> 0 then
    AddLn('WeaveIndexXY ' + itoa(m.WeaveIndexXY));
  if m.WeaveIndexZ <> 0 then
    AddLn('WeaveIndexZ ' + itoa(m.WeaveIndexZ));
  if m.spriteDX <> 0 then
    AddLn('spriteDX ' + itoa(m.spriteDX));
  if m.spriteDY <> 0 then
    AddLn('spriteDY ' + itoa(m.spriteDY));
  if m.infighting_group <> IG_DEFAULT then
    AddLn('InfightingGroup ' + Info_InfightingGroupToString(m.infighting_group));
  if m.projectile_group <> PG_DEFAULT then
    AddLn('ProjectileGroup ' + Info_ProjectileGroupToString(m.projectile_group));
  if m.splash_group <> SG_DEFAULT then
    AddLn('SplashGroup ' + Info_SplashGroupToString(m.splash_group));
  if R_GetBloodName(m.bloodcolor) <> '' then
    AddLn('Bloodcolor ' + R_GetBloodName(m.bloodcolor));
  if m.translationname <> '' then
    AddLn('Translation "' + m.translationname + '"');

  for i := 0 to mobj_flags.Count - 1 do
    if m.flags and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags[i]);
  for i := 0 to mobj_flags_ex.Count - 1 do
    if m.flags_ex and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags_ex[i]);
  for i := 0 to mobj_flags2_ex.Count - 1 do
    if m.flags2_ex and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags2_ex[i]);
  for i := 0 to mobj_flags3_ex.Count - 1 do
    if m.flags3_ex and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags3_ex[i]);
  for i := 0 to mobj_flags4_ex.Count - 1 do
    if m.flags4_ex and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags4_ex[i]);
  for i := 0 to mobj_flags5_ex.Count - 1 do
    if m.flags5_ex and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags5_ex[i]);
  for i := 0 to mobj_flags6_ex.Count - 1 do
    if m.flags6_ex and (1 shl i) <> 0 then
      AddLn('+' + mobj_flags6_ex[i]);

  // States
  AddLn('States');
  AddLn('{');
  AddState('Spawn', m.spawnstate);
  AddState('See', m.seestate);
  AddState('Melee', m.meleestate);
  AddState('Missile', m.missilestate);
  AddState('Pain', m.painstate);
  AddState('Death', m.deathstate);
  AddState('Xdeath', m.xdeathstate);
  AddState('Raise', m.raisestate);
  AddState('Heal', m.healstate);
  AddState('Crash', m.crashstate);
  AddState('Crush', m.crashstate);
  AddState('Interact', m.interactstate);
  AddLn('}');
  AddLn('}');
  AddLn('');
  result := ret;
end;

//==============================================================================
//
// SC_GetWeapondefDeclaration
//
//==============================================================================
function SC_GetWeapondefDeclaration(const wid: integer{$IFDEF HERETIC}; const lvl: integer{$ENDIF}{$IFDEF HEXEN}; const pcl: integer{$ENDIF}): string;
var
  ret: string;
  plevel: integer;
  aid: integer; // weapon & ammo ids
  w: Pweaponinfo_t;
  mxammo: integer;
  fl: integer;

  procedure AddLn(const s: string);
  var
    blanks: string;
    i: integer;
  begin
    if s = '}' then
      dec(plevel);
    blanks := '';
    for i := 0 to plevel - 1 do
      blanks := blanks + '  ';
    if s = '{' then
      inc(plevel);
    ret := ret + blanks + s + #13#10;
  end;

  function OtherStateGoto(const st: integer): boolean;
  begin
    result := true;
    if st = w.upstate then
    begin
      AddLn('Goto Up');
      exit;
    end;

    if st = w.downstate then
    begin
      AddLn('Goto Down');
      exit;
    end;

    if st = w.readystate then
    begin
      AddLn('Goto Ready');
      exit;
    end;

    if st = w.atkstate then
    begin
      AddLn('Goto Attack');
      exit;
    end;

    if st = w.holdatkstate then
    begin
      AddLn('Goto Hold');
      exit;
    end;

    if st = w.flashstate then
    begin
      AddLn('Goto Flash');
      exit;
    end;

    result := false;
  end;

  procedure AddState(const s: string; const st: integer);
  var
    sst: Pstate_t;
    spr: string;
    A: TDNumberList;
    idx: integer;
    act: string;
    stics: string;
  begin
    if st <= 0 then
      exit;

    A := TDNumberList.Create;
    A.Add(st);

    sst := @states[st];

    while true do
    begin
      if A.Count = 1 then
      begin
        AddLn(s + ':');
        AddLn('{');
      end;

      spr :=
        Chr(sprnames[sst.sprite] and $FF) +
        Chr((sprnames[sst.sprite] shr 8) and $FF) +
        Chr((sprnames[sst.sprite] shr 16) and $FF) +
        Chr((sprnames[sst.sprite] shr 24) and $FF);

      if not Assigned(sst.action.acv) then
        act := ''
      else
      begin
        act := DEH_ActionName(sst.action);
        if act = 'NULL' then
          act := ''
        else
        begin
          act := ' ' + act;
          if sst.params <> nil then
            act := act + ' ' + sst.params.Declaration;  // Add the parameter list
        end;
      end;

      if sst.flags_ex and MF_EX_STATE_RANDOM_SELECT <> 0 then
        stics := 'RANDOMSELECT(' + itoa(sst.tics) + ',' + itoa(sst.tics2) + ')'
      else if sst.flags_ex and MF_EX_STATE_RANDOM_RANGE <> 0 then
        stics := 'RANDOMRANGE(' + itoa(sst.tics) + ',' + itoa(sst.tics2) + ')'
      else
        stics := itoa(sst.tics);
      AddLn(
        spr + ' ' +
        Chr(Ord('A') + sst.frame and FF_FRAMEMASK) + ' ' +
        stics +
        act +
        decide(sst.frame and FF_FULLBRIGHT <> 0, ' BRIGHT', '') +
        decide(sst.mbf21bits and STATEF_SKILL5FAST <> 0, ' FAST', '')
      );

      if sst.tics < 0 then
        break;
      if Ord(sst.nextstate) <= 0 then
      begin
        AddLn('Stop');
        break;
      end;
      idx := A.IndexOf(Ord(sst.nextstate));
      if idx >= 0 then
      begin
        if idx = 0 then
          AddLn('Loop')
        else
          AddLn('Goto ' + s + '+' + itoa(idx));
        break;
      end;
      if OtherStateGoto(Ord(sst.nextstate)) then
        break;
      A.Add(Ord(sst.nextstate));
      sst := @states[Ord(sst.nextstate)];
    end;
    AddLn('}');
    A.Free;
  end;

begin
  if not IsIntegerInRange(wid, 0, Ord(NUMWEAPONS) - 1) then
  begin
    result := '';
    exit;
  end;

  {$IFDEF HERETIC}
  if not IsIntegerInRange(lvl, 1, 2) then
  begin
    result := '';
    exit;
  end;
  {$ENDIF}

  {$IFDEF HEXEN}
  if not IsIntegerInRange(pcl, 0, Ord(NUMCLASSES)) then
  begin
    result := '';
    exit;
  end;
  {$ENDIF}

  ret := '';
  plevel := 0;

  Addln('// ' + strupper(GetENumName(TypeInfo(weapontype_t), Ord(wid))));

  {$IFDEF DOOM_OR_STRIFE}
  w := @weaponinfo[wid];
  {$ENDIF}
  {$IFDEF HERETIC}
  if lvl = 1 then
    w := @wpnlev1info[wid]
  else
    w := @wpnlev2info[wid];
  {$ENDIF}
  {$IFDEF HEXEN}
  {$ENDIF}

  {$IFDEF HEXEN}
  aid := Ord(w.mana);
  mxammo := Ord(MANA_NONE);
  {$ELSE}
  aid := Ord(w.ammo);
  mxammo := Ord(NUMAMMO) + 1;
  {$ENDIF}

  AddLn('WEAPON ' + strupper(GetENumName(TypeInfo(weapontype_t), Ord(wid))));
  AddLn('{');
  {$IFDEF HERETIC}
  AddLn('Level LEVEL' + itoa(lvl));
  {$ENDIF}
  {$IFDEF HEXEN}
  AddLn('PlayerClass ' + strupper(GetENumName(TypeInfo(pclass_t), Ord(pcl))));
  {$ENDIF}

  AddLn('Ammo ' + decide(IsIntegerInRange(aid, 0, mxammo), strupper(GetENumName(TypeInfo({$IFDEF HEXEN}manatype_t{$ELSE}ammotype_t{$ENDIF}), Ord(aid))), itoa(aid)));

  {$IFDEF DOOM_OR_STRIFE}
  AddLn('AmmoPerShot ' + itoa(w.ammopershot));
  {$ENDIF}
  {$IFDEF HERETIC}
  if lvl = 1 then
    AddLn('AmmoPerShot ' + itoa(WeaponAmmoUsePL1[wid]))
  else
    AddLn('AmmoPerShot ' + itoa(WeaponAmmoUsePL2[wid]));
  {$ENDIF}
  {$IFDEF HEXEN}
  AddLn('AmmoPerShot ' + itoa(WeaponManaUse[pcl, wid]));
  {$ENDIF}

  for fl := 0 to weapon_flags_mbf21.Count - 1 do
    if w.mbf21bits and (1 shl fl) <> 0 then
      AddLn('+' + weapon_flags_mbf21[fl]);

  // States
  AddLn('States');
  AddLn('{');

  AddState('Up', w.upstate);
  AddState('Down', w.downstate);
  AddState('Ready', w.readystate);
  AddState('Attack', w.atkstate);
  AddState('Hold', w.holdatkstate);
  AddState('Flash', w.flashstate);

  AddLn('}');
  AddLn('}');
  AddLn('');
  result := ret;
end;

end.

