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
//  Support MUSINFO lump (dynamic music changing)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_musinfo;

interface

uses
  p_mobj_h,
  DelphiDoom.MusInfo.Intf;

//==============================================================================
//
// A_MusicChanger
//
//==============================================================================
procedure A_MusicChanger(actor: Pmobj_t);

const
  S_MUSINFO_PARAM = 'MUSINFOPARAM';

const
  MUSICCHANGER_LO = 14100;
  MUSICCHANGER_HI = 14164;
  MUSICCHANGER = 14165;

//==============================================================================
//
// P_ConfigureMusInfo
//
//==============================================================================
procedure P_ConfigureMusInfo(const ACatalog: IMusInfoCatalog);

//==============================================================================
//
// P_FindMusinfoMusic
//
//==============================================================================
function P_FindMusinfoMusic(const id: integer; const mapname: string): integer;

implementation

uses
  d_delphi,
  i_system,
  d_player,
  g_game,
  r_defs,
  p_params,
  p_setup,
  p_levelinfo,
  sounddata,
  sounds,
  s_sound,
  w_wad;

const
  S_MC_COUNTDOWN = 'COUNTDOWN';
  S_MC_PLAYERONSECTOR = 'PLAYERONSECTOR';

const
  MUSINFOTICS = 30;

//==============================================================================
//
// A_MusicChanger
//
//==============================================================================
procedure A_MusicChanger(actor: Pmobj_t);
var
  countdown: integer;
  oldplayeronsector: integer;
  playeronsector: integer;
  sec: Psector_t;
  mo: Pmobj_t;
  musid, musnumber: integer;
  levelname: string;
  levelinfo: Plevelinfo_t;
begin
  countdown := P_GetMobjCustomParamValue(actor, S_MC_COUNTDOWN, -1);

  oldplayeronsector := P_GetMobjCustomParamValue(actor, S_MC_PLAYERONSECTOR, 0);
  playeronsector := 0;

  sec := Psubsector_t(actor.subsector).sector;
  mo := sec.thinglist;
  while mo <> nil do
  begin
    if mo.player <> nil then
      if mo.player = @players[consoleplayer] then
      begin
        playeronsector := 1;
        break;
      end;
    mo := mo.snext;
  end;

  P_SetMobjCustomParam(actor, S_MC_PLAYERONSECTOR, playeronsector);

  if playeronsector = 0 then
  begin
    P_SetMobjCustomParam(actor, S_MC_COUNTDOWN, -1);
    exit;
  end;

  if playeronsector = 1 then
    if oldplayeronsector = 0 then
      P_SetMobjCustomParam(actor, S_MC_COUNTDOWN, MUSINFOTICS);

  if countdown < 0 then
    exit;

  if countdown > 0 then
  begin
    dec(countdown);
    P_SetMobjCustomParam(actor, S_MC_COUNTDOWN, countdown);
    exit;
  end;

  if countdown = 0 then
  begin
    P_SetMobjCustomParam(actor, S_MC_COUNTDOWN, -1);
    musid := P_GetMobjCustomParamValue(actor, S_MUSINFO_PARAM, -1);
    if musid >= 0 then
    begin
      levelname := P_GetMapName({$IFDEF DOOM_OR_HERETIC}gameepisode, {$ENDIF}gamemap);
      if musid = 0 then
        musnumber := S_DefaultMusicForMap({$IFDEF DOOM_OR_HERETIC}gameepisode, {$ENDIF}gamemap)
      else
        musnumber := P_FindMusinfoMusic(musid, levelname);
      if musnumber > 0 then
      begin
        S_ChangeMusic(musnumber, true);
        levelinfo := P_GetLevelInfo(levelname);
        levelinfo.musname := stringtochar8(strupper(S_music[musnumber].name));
      end;
    end;
  end;
end;

var
  musinfo_catalog: IMusInfoCatalog;

//==============================================================================
//
// P_ConfigureMusInfo
//
//==============================================================================
procedure P_ConfigureMusInfo(const ACatalog: IMusInfoCatalog);
begin
  musinfo_catalog := ACatalog;
end;

//==============================================================================
//
// P_FindMusinfoMusic
//
//==============================================================================
function P_FindMusinfoMusic(const id: integer; const mapname: string): integer;
begin
  if musinfo_catalog = nil then
    I_Error('P_FindMusinfoMusic(): MUSINFO is not configured (ComposeEngine was not called)');
  result := musinfo_catalog.Find(id, mapname);
end;

end.
