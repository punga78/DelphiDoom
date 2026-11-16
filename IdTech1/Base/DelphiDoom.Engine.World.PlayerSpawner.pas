{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a player is spawned on the level (P_SpawnPlayer)       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerSpawner;

interface

uses
  doomdata,
  p_mobj_h,
  p_udmf;

type
  /// <summary>
  ///   P_SpawnPlayer for Doom, Heretic and Strife (issue #185, step 2c-3): the three copies were
  ///   one routine; what a game does differently is in TMobjGameRules of the game
  ///   (PlayerTranslation, ResetBreath, FinishPlayerSpawn). Hexen spawns its players with the
  ///   class and the colors of its own and keeps its method: its project does not compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TMobjPlayerSpawner = class sealed
  public
    /// <summary>
    ///   Called when a player is spawned on the level. Most of the player structure stays
    ///   unchanged between levels. Gives nil when the player is not in the game
    /// </summary>
    class function Spawn(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t; static;
  end;

implementation

uses
  d_delphi,
  doomstat,
  d_player,
  doomdef,
  tables,
  m_fixed,
  info_h,
  r_defs,
  p_setup,
  r_main,
  p_playertrace,
  p_local,
  p_tick,
  p_pspr,
  g_game,
  p_mobj,
  DelphiDoom.Engine.World.MapRules,
  DelphiDoom.Engine.World.MobjRules;

class function TMobjPlayerSpawner.Spawn(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
var
  p: Pplayer_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  plnum: integer;
  ss: Psector_t;
begin
  // not playing?
  if not playeringame[mthing._type - 1] then
  begin
    result := nil;
    exit;
  end;

  plnum := mthing._type - 1;
  p := @players[plnum];

  if p.playerstate = PST_REBORN then
    G_PlayerReborn(plnum);

  if uthing <> nil then
  begin
    x := uthing.x;
    y := uthing.y;
    if uthing.extraflags and UDMF_TF_HASZ <> 0 then
      z := uthing.z
    else
      z := ONFLOORZ;
  end
  else
  begin
    x := mthing.x * FRACUNIT;
    y := mthing.y * FRACUNIT;
    z := ONFLOORZ;
  end;

  // JVAL: 20191209 - 3d floors - Fixed Player spawned in 3d floor
  ss := TMapGameRules.PointInSector(x, y);
  if ss.midsec >= 0 then
    if mthing.options and MTF_ONMIDSECTOR <> 0 then
      z := sectors[ss.midsec].ceilingheight;

  result := P_SpawnMobj(x, y, z, Ord(MT_PLAYER), @mthing);

  // set color translations for player sprites
  if mthing._type > 1 then
    result.flags := result.flags or TMobjGameRules.PlayerTranslation(plnum);

  if result.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    result.angle := ANG1 * mthing.angle
  else
    result.angle := ANG45 * (mthing.angle div 45);
  result.player := p;
  result.health := p.health;
  result.customparams := nil; // JVAL: Should keep the old params!

  p.mo := result;
  p.playerstate := PST_LIVE;
  p.refire := 0;
  p._message := '';
  p.damagecount := 0;
  p.bonuscount := 0;
  p.extralight := 0;
  p.fixedcolormap := 0;
  p.viewheight := PVIEWHEIGHT;
  // JVAL: 20211117 - Reset extra player fields when spawning player
  TMobjGameRules.ResetBreath(p);
  p.laddertics := 0;
  p.slopetics := 0;
  p.teleporttics := 0;
  p.nextoof := 0;
  p.quakeintensity := 0;
  p.quaketics := 0;
  p.oldcrouch := 0;
  p.lastongroundtime := 0;
  p.lastautocrouchtime := 0;
  p.crouchheight := 0;
  p.plinetarget := nil;
  p.pcrosstic := leveltime;
  // JVAL: 20211224 - Clear player history
  P_ClearPlayerHistory(p);
  p.nextfire := 0;

  // JVAL: 20220123 - Gravity & Health from UDMF
  if uthing <> nil then
  begin
    if uthing.extraflags and UDMF_TF_HASGRAVITY <> 0 then
    begin
      if uthing.gravity < 0.0 then
        p.mo.gravity := -Round(uthing.gravity * FRACUNIT)
      else
        p.mo.gravity := Round(p.mo.gravity * uthing.gravity);
    end;
    if uthing.extraflags and UDMF_TF_HASHEALTH <> 0 then
    begin
      if uthing.health < 0.0 then
      begin
        p.health := -Round(uthing.health);
        p.mo.health := p.health;
      end
      else
      begin
        p.health := Round(p.health * uthing.health);
        p.mo.health := p.health;
      end
    end;
    p.mo.tid := uthing.id;
  end;

  // setup gun psprite
  P_SetupPsprites(p);

  TMobjGameRules.FinishPlayerSpawn(p, plnum);
end;

end.