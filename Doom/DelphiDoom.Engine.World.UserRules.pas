{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Doom for the player (p_user)              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.UserRules;

interface

uses
  m_fixed,
  tables,
  p_mobj_h,
  d_player;

type
  /// <summary>
  ///   What Doom does in the player code of p_user (issue #185, step 2f-1). The routines that
  ///   are the same in the games are in Base\p_user.pas; the ones that only this game has stay here
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TUserGameRules = class sealed
  public
    const
      /// <summary>The slopes version of P_SlopesCalcHeight keeps the old view height when the player is in the air</summary>
      KeepsOldViewZInAir = True;
      /// <summary>The distance from the floor under which the view height is not let to go (slopes version)</summary>
      SlopesFloorMargin = 4 * FRACUNIT;
      /// <summary>P_DeathThink is a method of the rules (Hexen: the skull and the ice chunk, the poison, the palette, the reborn state)</summary>
      OwnsDeathThink = False;

    /// <summary>The death of the player (only when OwnsDeathThink)</summary>
    class procedure DeathThink(player: Pplayer_t); static;
    /// <summary>The player thinker (called every tic for every player)</summary>
    class procedure PlayerThink(player: Pplayer_t); static;
    /// <summary>The thrust of P_Thrust: Heretic and Hexen weaken it on ice and keep it when flying</summary>
    class function ThrustMove(const player: Pplayer_t; const move: fixed_t): fixed_t; static;
    /// <summary>The bob of a player that flies is fixed (Heretic, Hexen)</summary>
    class function FlyBobs(const player: Pplayer_t): boolean; static; inline;
    /// <summary>The player is a chicken (Heretic) or a pig (Hexen): no crouch, lower view</summary>
    class function IsMorphed(const player: Pplayer_t): boolean; static; inline;
    /// <summary>What a game does to the view height before the ceiling clamp (feet in water)</summary>
    class procedure AdjustViewZ(const player: Pplayer_t); static; inline;
    /// <summary>What a game does to the view height after the ceiling clamp (the floor clamp)</summary>
    class procedure ClampViewZ(const player: Pplayer_t); static; inline;
  end;

implementation

uses
  d_delphi,
  m_rnd,
  d_ticcmd,
  d_event,
  info_h,
  info,
{$IFDEF DEBUG}
  i_io,
{$ENDIF}
  g_game,
  p_common,
  p_genlin,
  p_playertrace,
  p_friends,
  p_mobj,
  p_tick,
  p_pspr,
  p_local,
  p_setup,    // JVAL: 3d Floors
  p_slopes,   // JVAL: Slopes
  p_3dfloors, // JVAL: Slopes
  p_spec,
  p_map,
  p_maputl,
  r_main,
  r_defs,
  sounds,
  s_sound,
  doomdef,
  doomstat,
  p_user,
  DelphiDoom.Engine.World.PlayerExtras;


//==============================================================================
//
// P_MovePlayer
//
//==============================================================================
procedure P_MovePlayer(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  look: integer;
  look16: integer; // JVAL Smooth Look Up/Down
  look2: integer;
  movefactor: fixed_t;
  cmd_crouch, cmd_jump: byte;
begin
  cmd := @player.cmd;

  player.mo.angle := player.mo.angle + _SHLW(cmd.angleturn, 16);

  // Do not let the player control movement
  //  if not onground.
  onground := player.mo.z <= player.mo.floorz;

  if not onground then
    if G_PlayingEngineVersion > VERSION120 then
      onground := player.mo.flags2_ex and MF2_EX_ONMOBJ <> 0;

  if onground then
    player.lastongroundtime := leveltime; // JVAL: 20211101 - Crouch

  // JVAL: 20220225 - NOJUMP sector flag (UDMF)
  if Psubsector_t(player.mo.subsector).sector.flags and SF_NOJUMP <> 0 then
    cmd_jump := 0
  else if (gamemapinfo <> nil) and gamemapinfo.nojump then
    cmd_jump := 0
  else
    cmd_jump := (cmd.jump_crouch and CMD_JUMP_MASK) shr CMD_JUMP_SHIFT;

  // JVAL: 20220226 - NOCROUCH sector flag (UDMF)
  if Psubsector_t(player.mo.subsector).sector.flags and SF_NOCROUCH <> 0 then
    cmd_crouch := 0
  else if (gamemapinfo <> nil) and gamemapinfo.nocrouch then
    cmd_crouch := 0
  else
    cmd_crouch := (cmd.jump_crouch and CMD_CROUCH_MASK) shr CMD_CROUCH_SHIFT;

  // villsa [STRIFE] allows player to climb over things by jumping
  // haleyjd 20110205: air control thrust should be 256, not cmd.forwardmove
  if (G_PlayingEngineVersion >= VERSION121) and not onground and (player.cheats and CF_LOWGRAVITY = 0) and (cmd.forwardmove <> 0) then
  begin
    P_Thrust(player, player.mo.angle, 256);
  end
  else
  begin
    movefactor := ORIG_FRICTION_FACTOR;

    if player.cheats and CF_LOWGRAVITY = 0 then
      if G_PlayingEngineVersion >= VERSION120 then
        if Psubsector_t(player.mo.subsector).sector.special and FRICTION_MASK <> 0 then
          movefactor := P_GetMoveFactor(player.mo); //movefactor * 2;

    // JVAL: 20211101 - Crouch
    if cmd_crouch > 0 then
      movefactor := FixedMul(FixedDiv(CROUCH_FRICTION_FACTOR, ORIG_FRICTION_FACTOR), movefactor);

    if (player.cheats and CF_LOWGRAVITY <> 0) or
      ((cmd.forwardmove <> 0) and
       (onground or ((cmd_jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0)))) then
      P_Thrust(player, player.mo.angle, cmd.forwardmove * movefactor);

    if (player.cheats and CF_LOWGRAVITY <> 0) or
      ((cmd.sidemove <> 0) and
       (onground or ((cmd_jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0)))) then
      P_Thrust(player, player.mo.angle - ANG90, cmd.sidemove * movefactor);
  end;

  if G_PlayingEngineVersion >= VERSION115 then
  begin
    // JVAL: Adjust speed while flying
    if (player.cheats and CF_LOWGRAVITY <> 0) and (player.mo.z > player.mo.floorz) then
    begin
      if player.mo.momx > 18 * FRACUNIT then
        player.mo.momx := 18 * FRACUNIT
      else if player.mo.momx < -18 * FRACUNIT then
        player.mo.momx := -18 * FRACUNIT;
      if player.mo.momy > 18 * FRACUNIT then
        player.mo.momy := 18 * FRACUNIT
      else if player.mo.momy < -18 * FRACUNIT then
        player.mo.momy := -18 * FRACUNIT;

      if (cmd.forwardmove = 0) and (cmd.sidemove = 0) then
      begin
        player.mo.momx := player.mo.momx * 15 div 16;
        player.mo.momy := player.mo.momy * 15 div 16;
      end;
    end
    else if (G_PlayingEngineVersion >= VERSION205) and (player.mo.flags2_ex and MF2_EX_ONMOBJ <> 0) then
    begin
      if (cmd.forwardmove = 0) and (cmd.sidemove = 0) then
      begin
        player.mo.momx := player.mo.momx * 15 div 16;
        player.mo.momy := player.mo.momy * 15 div 16;
      end;
    end;
  end;

  if ((cmd.forwardmove <> 0) or (cmd.sidemove <> 0)) and
     (player.mo.state = @states[Ord(S_PLAY)]) then
    P_SetMobjState(player.mo, S_PLAY_RUN1);

// JVAL Look UP and DOWN
  if zaxisshift then
  begin
    if G_PlayingEngineVersion < VERSION203 then // JVAL Smooth Look Up/Down
    begin
      look := cmd.lookupdown;
      if look > 7 then
        look := look - 16;

      if player.angletargetticks > 0 then
        player.centering := true
      else if look <> 0 then
      begin
        if look = TOCENTER then
          player.centering := true
        else
        begin
          player.lookdir := player.lookdir + 5 * look;
          if player.lookdir > MAXLOOKDIR then
            player.lookdir := MAXLOOKDIR
          else if player.lookdir < MINLOOKDIR then
            player.lookdir := MINLOOKDIR;
        end;
      end;
      player.lookdir16 := player.lookdir * 16;
    end
    else
    begin // JVAL Smooth Look Up/Down
      look16 := cmd.lookupdown16;
      if look16 > 7 * 256 then
        look16 := look16 - 16 * 256;

      if player.angletargetticks > 0 then
        player.centering := true
      else if look16 <> 0 then
      begin
        if look16 = TOCENTER * 256 then
          player.centering := true
        else
        begin
          player.lookdir16 := player.lookdir16 + Round(5 * look16 / 16);
          player.lookdir := player.lookdir16 div 16;

          if player.lookdir16 > MAXLOOKDIR * 16 then
            player.lookdir16 := MAXLOOKDIR * 16
          else if player.lookdir16 < MINLOOKDIR * 16 then
            player.lookdir16 := MINLOOKDIR * 16;

          if player.lookdir > MAXLOOKDIR then
            player.lookdir := MAXLOOKDIR
          else if player.lookdir < MINLOOKDIR then
            player.lookdir := MINLOOKDIR;
        end;
      end;
    end;

    if player.centering then
    begin
      if G_PlayingEngineVersion < VERSION203 then // JVAL Smooth Look Up/Down
      begin
        if player.lookdir > 0 then
          player.lookdir := player.lookdir - 8
        else if player.lookdir < 0 then
          player.lookdir := player.lookdir + 8;

        if abs(player.lookdir) < 8 then
        begin
          player.lookdir := 0;
          player.centering := false;
        end;

        player.lookdir16 := player.lookdir * 16;
      end
      else
      begin // JVAL Smooth Look Up/Down
        if player.lookdir16 > 0 then
          player.lookdir16 := player.lookdir16 - 8 * 16
        else if player.lookdir16 < 0 then
          player.lookdir16 := player.lookdir16 + 8 * 16;

        if abs(player.lookdir16) < 8 * 16 then
        begin
          player.lookdir16 := 0;
          player.centering := false;
        end;

        player.lookdir := player.lookdir16 div 16;
      end;
    end;
  end;

  if not G_NeedsCompatibilityMode then
  begin
  // JVAL Look LEFT and RIGHT
    look2 := cmd.lookleftright;
    if look2 > 7 then
      look2 := look2 - 16;

    if player.angletargetticks > 0 then
      player.forwarding := true
    else if look2 <> 0 then
    begin
      if look2 = TOFORWARD then
        player.forwarding := true
      else
      begin
        player.lookdir2 := (player.lookdir2 + 2 * look2) and 255;
        if player.lookdir2 in [64..127] then
          player.lookdir2 := 63
        else if player.lookdir2 in [128..191] then
          player.lookdir2 := 192;
      end;
    end
    else
      if player.oldlook2 <> 0 then
        player.forwarding := true;

    if player.forwarding then
    begin
      if player.lookdir2 in [3..63] then
        player.lookdir2 := player.lookdir2 - 6
      else if player.lookdir2 in [192..251] then
        player.lookdir2 := player.lookdir2 + 6;

      if (player.lookdir2 < 8) or (player.lookdir2 > 247) then
      begin
        player.lookdir2 := 0;
        player.forwarding := false;
      end;
    end;
    player.mo.viewangle := player.lookdir2 shl 24;

    player.oldlook2 := look2;

    if (onground or (player.cheats and CF_LOWGRAVITY <> 0)) and (cmd_jump > 1) then
    begin
      // JVAL: 20211101 - Crouch
      if cmd_crouch > 0 then
        player.mo.momz := 4 * FRACUNIT
      else
        player.mo.momz := 8 * FRACUNIT;
    end;

    // JVAL: 20211101 - Crouch
    if (leveltime - player.lastongroundtime < TICRATE) and (cmd_crouch <> 0) then
    begin
      player.crouchheight := player.crouchheight + cmd_crouch * FRACUNIT;
      if player.crouchheight > PMAXCROUCHHEIGHT then
        player.crouchheight := PMAXCROUCHHEIGHT;
    end
    else if (leveltime - player.lastautocrouchtime > TICRATE) and (player.crouchheight <> 0) then
    begin
      player.crouchheight := player.crouchheight - 2 * FRACUNIT;
      if player.crouchheight < 0 then
        player.crouchheight := 0;
    end;
    if not onground and (cmd_crouch <> 0) then
      if player.mo.momz > -4 * FRACUNIT then
      begin
        player.mo.momz := player.mo.momz - FRACUNIT div 2;
        if player.mo.momz < -4 * FRACUNIT then
          player.mo.momz := -4 * FRACUNIT;
      end;
  end
  else
    player.lookdir2 := 0;
end;

//==============================================================================
//
// P_PlayerThink
//
//==============================================================================
class procedure TUserGameRules.PlayerThink(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  newweapon: weapontype_t;
  sec: Psector_t; // JVAL: 3d Floors
begin
  // fixme: do this in the cheat code
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

  P_AngleTarget(player);

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

  // Check for weapon change.

  // A special event has no other buttons.
  if cmd.buttons and BT_SPECIAL <> 0 then
    cmd.buttons := 0;

  if cmd.buttons and BT_CHANGE <> 0 then
  begin
    // The actual changing of the weapon is done
    //  when the weapon psprite can do it
    //  (read: not in the middle of an attack).
    newweapon := weapontype_t(_SHR(cmd.buttons and BT_WEAPONMASK, BT_WEAPONSHIFT));

    if (newweapon = wp_fist) and
       (player.weaponowned[Ord(wp_chainsaw)] <> 0) and (not (
       (player.readyweapon = wp_chainsaw) and (player.powers[Ord(pw_strength)] <> 0))) then
    begin
      newweapon := wp_chainsaw;
      // JVAL: If readyweapon is already the chainsaw return to fist
      // Only if we don't have old compatibility mode suspended
      if not G_NeedsCompatibilityMode then
        if player.readyweapon = wp_chainsaw then
          newweapon := wp_fist;
    end;

    if (gamemode = commercial) and
       (newweapon = wp_shotgun) and
       (player.weaponowned[Ord(wp_supershotgun)] <> 0) and
       (player.readyweapon <> wp_supershotgun) then
      newweapon := wp_supershotgun;

    if (player.weaponowned[Ord(newweapon)] <> 0) and
       (newweapon <> player.readyweapon) then
      // Do not go to plasma or BFG in shareware,
      //  even if cheated.
      if ((newweapon <> wp_plasma) and (newweapon <> wp_bfg)) or
         (gamemode <> shareware) then
        player.pendingweapon := newweapon;

  end;

  // check for use
  if cmd.buttons and BT_USE <> 0 then
  begin
    if not player.usedown then
    begin
      P_UseLines(player);
      player.usedown := true;
    end;
  end
  else
    player.usedown := false;

  // cycle psprites
  P_MovePsprites(player);

  // Counters, time dependend power ups.

  // Strength counts up to diminish fade.
  if player.powers[Ord(pw_strength)] <> 0 then
    player.powers[Ord(pw_strength)] := player.powers[Ord(pw_strength)] + 1;

  if player.powers[Ord(pw_invulnerability)] <> 0 then
    player.powers[Ord(pw_invulnerability)] := player.powers[Ord(pw_invulnerability)] - 1;

  if player.powers[Ord(pw_invisibility)] <> 0 then
  begin
    player.powers[Ord(pw_invisibility)] := player.powers[Ord(pw_invisibility)] - 1;
    if player.powers[Ord(pw_invisibility)] = 0 then
      player.mo.flags := player.mo.flags and not MF_SHADOW;
  end;

  if player.powers[Ord(pw_infrared)] <> 0 then
    player.powers[Ord(pw_infrared)] := player.powers[Ord(pw_infrared)] - 1;

  if player.powers[Ord(pw_ironfeet)] <> 0 then
    player.powers[Ord(pw_ironfeet)] := player.powers[Ord(pw_ironfeet)] - 1;

  if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.hardbreathtics > 0 then
    player.hardbreathtics := player.hardbreathtics - 1;

  if player.bonuscount <> 0 then
    player.bonuscount := player.bonuscount - 1;

  // Handling colormaps.
  if player.powers[Ord(pw_invulnerability)] <> 0 then
  begin
    if (player.powers[Ord(pw_invulnerability)] > 4 * 32) or
       (player.powers[Ord(pw_invulnerability)] and 8 <> 0) then
      player.fixedcolormap := INVERSECOLORMAP
    else
      player.fixedcolormap := 0;
  end
  else if player.powers[Ord(pw_infrared)] <> 0 then
  begin
    if (player.powers[Ord(pw_infrared)] > 4 * 32) or
       (player.powers[Ord(pw_infrared)] and 8 <> 0) then
      // almost full bright
      player.fixedcolormap := 1
    else
      player.fixedcolormap := 0;
  end
  else
    player.fixedcolormap := 0;

  if G_PlayingEngineVersion >= VERSION119 then
    A_PlayerBreath(player);
end;

//==============================================================================
//
// TUserGameRules.ThrustMove
//
//==============================================================================
class function TUserGameRules.ThrustMove(const player: Pplayer_t; const move: fixed_t): fixed_t;
begin
  result := move;
end;

//==============================================================================
//
// TUserGameRules.FlyBobs
//
//==============================================================================
class function TUserGameRules.FlyBobs(const player: Pplayer_t): boolean;
begin
  result := false;
end;

//==============================================================================
//
// TUserGameRules.IsMorphed
//
//==============================================================================
class function TUserGameRules.IsMorphed(const player: Pplayer_t): boolean;
begin
  result := false;
end;

//==============================================================================
//
// TUserGameRules.AdjustViewZ
//
//==============================================================================
class procedure TUserGameRules.AdjustViewZ(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.ClampViewZ
//
//==============================================================================
class procedure TUserGameRules.ClampViewZ(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.DeathThink
//
//==============================================================================
class procedure TUserGameRules.DeathThink(player: Pplayer_t);
begin
end;

end.

