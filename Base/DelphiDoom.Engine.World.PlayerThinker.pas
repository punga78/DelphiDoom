{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the thinker of the player (P_PlayerThink)              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerThinker;

interface

uses
  m_fixed,
  d_player;

type
  /// <summary>
  ///   P_PlayerThink for Doom, Heretic and Strife (issue #185, step 2f-1): the three copies had
  ///   the same order of things (cheats, quake, aim, death, move, height, sectors, weapon, use,
  ///   weapon sprites, counters, colormap); what a game does at each point is a method of its
  ///   TUserGameRules. Hexen has another thinker (the classes, the morph, the ice, the poison)
  ///   and keeps its method: its project does not compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface. It runs
  ///   every tic for every player
  /// </remarks>
  TPlayerThinker = class sealed
  public
    /// <summary>The thinker of a player</summary>
    class procedure Think(player: Pplayer_t); static;
  end;

implementation

uses
  d_delphi,
  m_rnd,
  d_ticcmd,
  d_event,
  info_h,
  info,
  g_game,
  p_common,
  p_playertrace,
  p_friends,
  p_mobj_h,
  p_tick,
  p_pspr,
  p_local,
  p_setup,    // JVAL: 3d Floors
  p_slopes,   // JVAL: Slopes
  p_3dfloors, // JVAL: Slopes
  p_spec,
  p_map,
  p_maputl,
  p_user,
  r_main,
  r_defs,
  doomdef,
  DelphiDoom.Engine.World.UserRules;

//==============================================================================
//
// TPlayerThinker.Think
//
//==============================================================================
class procedure TPlayerThinker.Think(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  sec: Psector_t; // JVAL: 3d Floors
begin
  // fixme: do this in the cheat code
  if TUserGameRules.GuardsNilMobj then
    if player.mo = nil then
      exit;

  if player.cheats and CF_NOCLIP <> 0 then
    player.mo.flags := player.mo.flags or MF_NOCLIP
  else
    player.mo.flags := player.mo.flags and not MF_NOCLIP;

  // chain saw run forward
  cmd := @player.cmd;
  if player.mo.flags and MF_JUSTATTACKED <> 0 then
  begin
    cmd.angleturn := 0;
    cmd.forwardmove := $c800 div 512;
    cmd.sidemove := 0;
    player.mo.flags := player.mo.flags and not MF_JUSTATTACKED;
  end;

  if player.quaketics > 0 then
  begin
    Dec(player.quaketics, FRACUNIT);
    if player.quaketics < 0 then
      player.quaketics := 0;
  end;

  if player.teleporttics > 0 then
  begin
    Dec(player.teleporttics, FRACUNIT);
    if player.teleporttics < 0 then
      player.teleporttics := 0;
  end;

  P_AimLineAttack(player.mo, player.mo.angle, 16 * 64 * FRACUNIT);
  if (player.plinetarget = nil) and (linetarget <> nil) then
    player.pcrosstic := leveltime;
  player.plinetarget := linetarget;

  if player.playerstate = PST_DEAD then
  begin
    P_DeathThink(player);
    exit;
  end;

  P_PlayerHistoryNotify(player);  // JVAL: 20211224 - Notify player history
  P_HandleFriendsNearMe(player);  // JVAL: 20220107 - Handle nearby friends

  TUserGameRules.BeforeMove(player);

  // Move around.
  // Reactiontime is used to prevent movement
  //  for a bit after a teleport.
  if player.mo.reactiontime <> 0 then
    player.mo.reactiontime := player.mo.reactiontime - 1
  else
    P_MovePlayer(player);

  P_SlopesCalcHeight(player); // JVAL: Slopes

  // JVAL: 3d Floors
  sec := Psubsector_t(player.mo.subsector).sector;
  if sec.special <> 0 then
    P_PlayerInSpecialSector(player, sec, P_FloorHeight(sec, player.mo.x, player.mo.y));    // JVAL: 3d Floors
  if sec.midsec >= 0 then
    if sectors[sec.midsec].special <> 0 then
      P_PlayerInSpecialSector(player, @sectors[sec.midsec], sectors[sec.midsec].ceilingheight);  // JVAL: 3d Floors

  TUserGameRules.AfterSector(player, cmd);

  // Check for weapon change.

  // A special event has no other buttons.
  if cmd.buttons and BT_SPECIAL <> 0 then
    cmd.buttons := 0;

  TUserGameRules.ChangeWeapon(player, cmd);

  // check for use
  if cmd.buttons and BT_USE <> 0 then
  begin
    if not player.usedown then
    begin
      TUserGameRules.BeforeUseLines(player);
      P_UseLines(player);
      player.usedown := true;
    end;
  end
  else
    player.usedown := false;

  TUserGameRules.BeforePsprites(player);

  // cycle psprites
  P_MovePsprites(player);

  // Counters, time dependend power ups.

  TUserGameRules.CountDown(player);

  TUserGameRules.Colormap(player);

  TUserGameRules.AtEnd(player);
end;

end.
