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
  d_player,
  d_ticcmd;

type
  /// <summary>
  ///   What Doom does in the player code of p_user (issue #185, step 2f-1). The routines that
  ///   are the same in the games are in IdTech1\Base\p_user.pas; the ones that only this game has stay here
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
      /// <summary>The jump and the crouch work out of the new engine too (Strife); the other games run them only in it</summary>
      JumpsAlways = False;
      /// <summary>P_PlayerThink starts by leaving when the player has no thing</summary>
      GuardsNilMobj = True;

    /// <summary>Sets onground, the state of the player towards the floor</summary>
    class procedure SetOnGround(const player: Pplayer_t); static;
    /// <summary>The sector or the map forbids the jump</summary>
    class function MapNoJump: boolean; static;
    /// <summary>The sector or the map forbids the crouch</summary>
    class function MapNoCrouch: boolean; static;
    /// <summary>The movement of the player for the commands of the tic (thrust, flight, the running state)</summary>
    class procedure MoveByCommand(const player: Pplayer_t; const cmd: Pticcmd_t; const cmd_jump, cmd_crouch: byte); static;
    /// <summary>The look up and down of the command</summary>
    class function LookUpDown(const cmd: Pticcmd_t): integer; static; inline;
    /// <summary>The player turns to a target: the look commands only center the view (Doom, Strife)</summary>
    class function AimsAtTarget(const player: Pplayer_t): boolean; static; inline;
    /// <summary>What comes after the movement and the look (Heretic, Hexen: the flight)</summary>
    class procedure AfterMove(const player: Pplayer_t; const cmd: Pticcmd_t); static;
    /// <summary>The death of the player (only when OwnsDeathThink)</summary>
    class procedure DeathThink(player: Pplayer_t); static;
    /// <summary>The player thinker (called every tic for every player)</summary>
    class procedure PlayerThink(player: Pplayer_t); static;
    /// <summary>What the player does before the move (Doom, Strife: turn towards a target; Heretic: the chicken)</summary>
    class procedure BeforeMove(const player: Pplayer_t); static;
    /// <summary>What comes after the special sectors (Heretic: the artifacts; Strife: the breath and the inventory)</summary>
    class procedure AfterSector(const player: Pplayer_t; const cmd: Pticcmd_t); static;
    /// <summary>The change of the weapon the buttons ask for</summary>
    class procedure ChangeWeapon(const player: Pplayer_t; const cmd: Pticcmd_t); static;
    /// <summary>What comes before the use of the lines (Strife: the dialogs)</summary>
    class procedure BeforeUseLines(const player: Pplayer_t); static;
    /// <summary>What comes before the weapon sprites move (Heretic: the chicken counter)</summary>
    class procedure BeforePsprites(const player: Pplayer_t); static;
    /// <summary>The counters of the powers and of the screen effects</summary>
    class procedure CountDown(const player: Pplayer_t); static;
    /// <summary>The colormap of the view</summary>
    class procedure Colormap(const player: Pplayer_t); static;
    /// <summary>The last thing of the thinker (Doom: the breath of the player)</summary>
    class procedure AtEnd(const player: Pplayer_t); static;
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
  p_spec_h,
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
  DelphiDoom.Engine.World.PlayerExtras,
  DelphiDoom.Engine.World.PlayerThinker,
  DelphiDoom.Engine.World.PlayerColormap;


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

//==============================================================================
//
// TUserGameRules.SetOnGround
//
//==============================================================================
class procedure TUserGameRules.SetOnGround(const player: Pplayer_t);
begin
  onground := player.mo.z <= player.mo.floorz;

  if not onground then
    if G_PlayingEngineVersion > VERSION120 then
      onground := player.mo.flags2_ex and MF2_EX_ONMOBJ <> 0;
end;

//==============================================================================
//
// TUserGameRules.MapNoJump
//
//==============================================================================
class function TUserGameRules.MapNoJump: boolean;
begin
  result := (gamemapinfo <> nil) and gamemapinfo.nojump;
end;

//==============================================================================
//
// TUserGameRules.MapNoCrouch
//
//==============================================================================
class function TUserGameRules.MapNoCrouch: boolean;
begin
  result := (gamemapinfo <> nil) and gamemapinfo.nocrouch;
end;

//==============================================================================
//
// TUserGameRules.MoveByCommand
//
//==============================================================================
class procedure TUserGameRules.MoveByCommand(const player: Pplayer_t; const cmd: Pticcmd_t; const cmd_jump, cmd_crouch: byte);
var
  movefactor: fixed_t;
begin
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
end;

//==============================================================================
//
// TUserGameRules.LookUpDown
//
//==============================================================================
class function TUserGameRules.LookUpDown(const cmd: Pticcmd_t): integer;
begin
  result := cmd.lookupdown;
end;

//==============================================================================
//
// TUserGameRules.AimsAtTarget
//
//==============================================================================
class function TUserGameRules.AimsAtTarget(const player: Pplayer_t): boolean;
begin
  result := player.angletargetticks > 0;
end;

//==============================================================================
//
// TUserGameRules.AfterMove
//
//==============================================================================
class procedure TUserGameRules.AfterMove(const player: Pplayer_t; const cmd: Pticcmd_t);
begin
end;

//==============================================================================
//
// TUserGameRules.PlayerThink
//
//==============================================================================
class procedure TUserGameRules.PlayerThink(player: Pplayer_t);
begin
  TPlayerThinker.Think(player);
end;

//==============================================================================
//
// TUserGameRules.BeforeMove
//
//==============================================================================
class procedure TUserGameRules.BeforeMove(const player: Pplayer_t);
begin
  P_AngleTarget(player);
end;

//==============================================================================
//
// TUserGameRules.AfterSector
//
//==============================================================================
class procedure TUserGameRules.AfterSector(const player: Pplayer_t; const cmd: Pticcmd_t);
begin
end;

//==============================================================================
//
// TUserGameRules.ChangeWeapon
//
//==============================================================================
class procedure TUserGameRules.ChangeWeapon(const player: Pplayer_t; const cmd: Pticcmd_t);
var
  newweapon: weapontype_t;
begin
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
end;

//==============================================================================
//
// TUserGameRules.BeforeUseLines
//
//==============================================================================
class procedure TUserGameRules.BeforeUseLines(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.BeforePsprites
//
//==============================================================================
class procedure TUserGameRules.BeforePsprites(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.CountDown
//
//==============================================================================
class procedure TUserGameRules.CountDown(const player: Pplayer_t);
begin
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
end;

//==============================================================================
//
// TUserGameRules.Colormap
//
//==============================================================================
class procedure TUserGameRules.Colormap(const player: Pplayer_t);
begin
  TPlayerColormap.Standard(player);
end;

//==============================================================================
//
// TUserGameRules.AtEnd
//
//==============================================================================
class procedure TUserGameRules.AtEnd(const player: Pplayer_t);
begin
  if G_PlayingEngineVersion >= VERSION119 then
    A_PlayerBreath(player);
end;

end.

