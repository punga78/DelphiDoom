{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Strife for the weapon sprites (p_pspr)    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit DelphiDoom.Engine.World.PspriteRules;

interface

uses
// Needs fixed point, and BAM angles.
  m_fixed,
  tables,
  info_h,
  p_pspr_h,
  p_mobj_h,
  d_player;

const
//
// Frame flags:
// handles maximum brightness (torches, muzzle flare, light sources)
//
  FF_FULLBRIGHT = $8000; // flag in thing->frame
  FF_FRAMEMASK = $7fff;

//==============================================================================
//
// A_WeaponReady
//
//==============================================================================
procedure A_WeaponReady(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_CheckReload
//
//==============================================================================
procedure A_CheckReload(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_GunFlash
//
//==============================================================================
procedure A_GunFlash(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Punch
//
//==============================================================================
procedure A_Punch(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireMissile
//
//==============================================================================
procedure A_FireMissile(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Light1
//
//==============================================================================
procedure A_Light1(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Light2
//
//==============================================================================
procedure A_Light2(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_GunFlashThinker
//
//==============================================================================
procedure A_GunFlashThinker(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_FireElectricBolt
//
//==============================================================================
procedure A_FireElectricBolt(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_FirePoisonBolt
//
//==============================================================================
procedure A_FirePoisonBolt(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_FireRifle
//
//==============================================================================
procedure A_FireRifle(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_FireFlameThrower
//
//==============================================================================
procedure A_FireFlameThrower(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireMauler1
//
//==============================================================================
procedure A_FireMauler1(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_FireMauler2
//
//==============================================================================
procedure A_FireMauler2(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_MaulerSound
//
//==============================================================================
procedure A_MaulerSound(player: Pplayer_t; psp: pspdef_t);

//==============================================================================
//
// A_FireGrenade
//
//==============================================================================
procedure A_FireGrenade(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_SigilSound
//
//==============================================================================
procedure A_SigilSound(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_FireSigil
//
//==============================================================================
procedure A_FireSigil(player: Pplayer_t; pspr: Ppspdef_t);

//==============================================================================
//
// A_SigilShock
//
//==============================================================================
procedure A_SigilShock(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_TorpedoExplode
//
//==============================================================================
procedure A_TorpedoExplode(actor: Pmobj_t);

//==============================================================================
//
// P_CheckAmmo
//
//==============================================================================
function P_CheckAmmo(player: Pplayer_t): boolean;

//==============================================================================
//
// P_BringUpWeapon
// Starts bringing the pending weapon up from the bottom of the screen
//
//==============================================================================
procedure P_BringUpWeapon(player: Pplayer_t);

//==============================================================================
//
// P_FireWeapon
//
//==============================================================================
procedure P_FireWeapon(player: Pplayer_t);

type
  /// <summary>
  ///   What Strife does in the weapon sprite code of p_pspr (issue #185, step 2f-3). The routines that
  ///   are the same in the games are in IdTech1\Base\p_pspr.pas; the weapons and what depends on the record of the player stay here
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TPspriteGameRules = class sealed
  public
    /// <summary>What comes after the weapon sprites moved (Strife: the targeter)</summary>
    class procedure AfterMovePsprites(const player: Pplayer_t); static;
    /// <summary>The state the weapon of the player goes down to (P_DropWeapon)</summary>
    class function DropWeaponState(const player: Pplayer_t): statenum_t; static;
    /// <summary>The state the weapon goes to when it is raised all the way (A_Raise)</summary>
    class function RaisedState(const player: Pplayer_t): statenum_t; static;
    /// <summary>The weapon goes down at once, not by steps (the player is a chicken or a pig)</summary>
    class function StaysLowered(const player: Pplayer_t): boolean; static;
    /// <summary>What A_Lower does when the weapon is down and before the new one comes up (Doom: the choice of the weapon of mbf21)</summary>
    class procedure AfterLowered(const player: Pplayer_t); static;
    /// <summary>What A_ReFire does when the player does not fire again: the check of the ammo, or of the mana</summary>
    class procedure CheckSupplies(const player: Pplayer_t); static;
  end;

implementation

uses
  p_pspr,
  d_delphi,
  g_game,
  info,
  doomdef,
  d_event,
  d_items,
  m_rnd,
  i_system,
  p_common,
  p_local,
  p_tick,
  p_mobj,
  DelphiDoom.Engine.World.MobjRules,
  p_enemy,
  DelphiDoom.Engine.World.EnemyRules,
  p_map,
  p_inter,
  p_user,
  r_main,
  s_sound,
// Data.
  sounddata;

const
// plasma cells for a bfg attack
  BFGCELLS = 40;

//==============================================================================
//
// P_BringUpWeapon
// Starts bringing the pending weapon up
// from the bottom of the screen.
// Uses player
//
//==============================================================================
procedure P_BringUpWeapon(player: Pplayer_t);
var
  newstate: statenum_t;
begin
  if player.pendingweapon = wp_nochange then
    player.pendingweapon := player.readyweapon;

  if player.pendingweapon = wp_flame then
    S_StartSound(player.mo, Ord(sfx_flidl));  // villsa [STRIFE] flame sounds

  newstate := statenum_t(weaponinfo[Ord(player.pendingweapon)].upstate);

  player.psprites[Ord(ps_weapon)].sy := WEAPONBOTTOM;

  P_SetPsprite(player, Ord(ps_weapon), newstate);

  // villsa [STRIFE] set various flash states
  if player.pendingweapon = wp_elecbow then
    P_SetPsprite(player, Ord(ps_flash), S_XBOW_10) // 31
  else if (player.pendingweapon = wp_sigil) and (player.sigiltype <> 0) then
    P_SetPsprite(player, Ord(ps_flash), statenum_t(Ord(S_SIGH_00) + player.sigiltype)) // 117
  else
    P_SetPsprite(player, Ord(ps_flash), S_NULL);

  player.pendingweapon := wp_nochange;

end;

//==============================================================================
//
// P_CheckAmmo
// Returns true if there is enough ammo to shoot.
// If not, selects the next weapon to use.
//
// villsa [STRIFE] Changes to handle Strife weapons
//
//==============================================================================
function P_CheckAmmo(player: Pplayer_t): boolean;
var
  ammo: ammotype_t;
  count: integer;
begin
  ammo := weaponinfo[Ord(player.readyweapon)].ammo;

  // Minimal amount for one shot varies.
  if weaponinfo[Ord(player.readyweapon)].intflags and WIF_ENABLEAPS <> 0 then
    count := weaponinfo[Ord(player.readyweapon)].ammopershot
  else if player.readyweapon = wp_torpedo then
    count := 30
  else if player.readyweapon = wp_mauler then
    count := 20
  else
    count := 1;      // Regular.

  // Some do not need ammunition anyway.
  // Return if current ammunition sufficient.
  if (ammo = am_noammo) or (player.ammo[Ord(ammo)] >= count) then
  begin
    result := true;
    exit;
  end;

  // Out of ammo, pick a weapon to change to.
  // Preferences are set here.

  // villsa [STRIFE] new weapon preferences
  if player.weaponowned[Ord(wp_mauler)] and (player.ammo[Ord(am_cell)] >= 20) then
    player.pendingweapon := wp_mauler

  else if player.weaponowned[Ord(wp_rifle)] and (player.ammo[Ord(am_bullets)] > 0) then
    player.pendingweapon := wp_rifle

  else if player.weaponowned[Ord(wp_elecbow)] and (player.ammo[Ord(am_elecbolts)] > 0) then
    player.pendingweapon := wp_elecbow

  else if player.weaponowned[Ord(wp_missile)] and (player.ammo[Ord(am_missiles)] > 0) then
    player.pendingweapon := wp_missile

  else if player.weaponowned[Ord(wp_flame)] and (player.ammo[Ord(am_cell)] > 0) then
    player.pendingweapon := wp_flame

  else if player.weaponowned[Ord(wp_hegrenade)] and (player.ammo[Ord(am_hegrenades)] > 0) then
    player.pendingweapon := wp_hegrenade

  else if player.weaponowned[Ord(wp_poisonbow)] and (player.ammo[Ord(am_poisonbolts)] > 0) then
    player.pendingweapon := wp_poisonbow

  else if player.weaponowned[Ord(wp_wpgrenade)] and (player.ammo[Ord(am_wpgrenades)] > 0) then
    player.pendingweapon := wp_wpgrenade

    // BUG: This will *never* be selected for an automatic switch because the
    // normal Mauler is higher priority and uses less ammo.
  else if player.weaponowned[Ord(wp_torpedo)] and (player.ammo[Ord(am_cell)] >= 30) then
    player.pendingweapon := wp_torpedo

  else
    player.pendingweapon := wp_fist;

  // Now set appropriate weapon overlay.
  P_SetPsprite(player, Ord(ps_weapon), statenum_t(weaponinfo[Ord(player.readyweapon)].downstate));

  result := false;
end;

//==============================================================================
//
// P_FireWeapon.
//
// villsa [STRIFE] Changes for player state and weapons
//
//==============================================================================
procedure P_FireWeapon(player: Pplayer_t);
var
  newstate: statenum_t;
begin
  if P_CheckAmmo(player) then
  begin
    P_SetMobjState(player.mo, S_PLAY_05); // 292
    if (player.refire > 0) and (weaponinfo[Ord(player.readyweapon)].holdatkstate > 0) then
      newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].holdatkstate)
    else
      newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].atkstate);
    P_SetPsprite(player, Ord(ps_weapon), newstate);
    // villsa [STRIFE] exclude these weapons from causing noise
    if (Ord(player.readyweapon) > Ord(wp_elecbow)) and (player.readyweapon <> wp_poisonbow) then
      P_NoiseAlert(player.mo, player.mo);
  end;
end;

//==============================================================================
//
// A_WeaponReady
// The player can fire the weapon
// or change to another weapon at this time.
// Follows after getting weapon up,
// or after previous attack/fire sequence.
//
//==============================================================================
procedure A_WeaponReady(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: statenum_t;
  angle: integer;
begin
  // get out of attack state
  if (player.mo.state = @states[Ord(S_PLAY_05)]) or     // 292
     (player.mo.state = @states[Ord(S_PLAY_06)]) then   // 293
    P_SetMobjState(player.mo, S_PLAY_00); // 287

  // villsa [STRIFE] check for wp_flame instead of chainsaw
  // haleyjd 09/06/10: fixed state (00 rather than 01)
  if (player.readyweapon = wp_flame) and
     (psp.state = @states[Ord(S_FLMT_00)]) then // 62
    S_StartSound(player.mo, Ord(sfx_flidl));

  // check for change
  //  if player is dead, put the weapon away
  if (player.pendingweapon <> wp_nochange) or (player.health = 0) then
  begin
    // change weapon
    //  (pending weapon should allready be validated)
    newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].downstate);
    P_SetPsprite(player, Ord(ps_weapon), newstate);
    exit;
  end;

  // check for fire
  //  the missile launcher and bfg do not auto fire
  if player.cmd.buttons and BT_ATTACK <> 0 then
  begin
    if (not player.attackdown) or
       ((player.readyweapon <> wp_missile) and (player.readyweapon <> wp_torpedo)) then // villsa [STRIFE] replace bfg with torpedo
    begin
      player.attackdown := true;
      P_FireWeapon(player);
      exit;
    end;
  end
  else
    player.attackdown := false;

  // bob the weapon based on movement speed
  angle := (128 * TTickState.LevelTime) and FINEMASK;
  psp.sx := FRACUNIT + FixedMul(player.bob, finecosine[angle]);
  angle := angle and (FINEANGLES div 2 - 1);
  psp.sy := WEAPONTOP + FixedMul(player.bob, finesine[angle]);
end;

//==============================================================================
//
// A_CheckReload
//
//==============================================================================
procedure A_CheckReload(player: Pplayer_t; psp: Ppspdef_t);
begin
  P_CheckAmmo(player);

  // villsa [STRIFE] set animating sprite for crossbow
  if player.readyweapon = wp_elecbow then
    P_SetPsprite(player, Ord(player.readyweapon), S_XBOW_10);
end;

//==============================================================================
//
// A_GunFlash
//
//==============================================================================
procedure A_GunFlash(player: Pplayer_t; psp: Ppspdef_t);
begin
  P_SetMobjState(player.mo, S_PLAY_06);
  P_SetPsprite(player, Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate));
end;

//
// WEAPON ATTACKS
//

//==============================================================================
//
// A_Punch
//
//==============================================================================
procedure A_Punch(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
  stamina: integer;
  mrange: integer;
begin
  // villsa [STRIFE] new damage formula
  // haleyjd 09/19/10: seriously corrected...
  stamina := player.stamina;
  damage := (P_Random and ((stamina div 10) + 7)) * ((stamina div 10) + 2);

  if player.powers[Ord(pw_strength)] <> 0 then
    damage := damage * 10;

  angle := player.mo.angle;
  angle := angle + _SHLW(P_Random - P_Random, 18);
  mrange := P_GetPlayerMeleeRange(player);
  slope := P_AimLineAttack(player.mo, angle, mrange);
  P_LineAttack(player.mo, angle, mrange, slope, damage);

  // turn to face target
  if TMapAim.LineTarget <> nil then
  begin
    // villsa [STRIFE] check for non-flesh types
    if TMapAim.LineTarget.flags and MF_NOBLOOD <> 0 then
      S_StartSound(player.mo, Ord(sfx_mtalht))
    else
      S_StartSound(player.mo, Ord(sfx_meatht));

    player.mo.angle :=
      R_PointToAngle2(player.mo.x, player.mo.y, TMapAim.LineTarget.x, TMapAim.LineTarget.y);

    // villsa [STRIFE] apply flag
    player.mo.flags := player.mo.flags or MF_JUSTATTACKED;

    // villsa [STRIFE] do punch alert routine
    P_DoPunchAlert(player.mo, TMapAim.LineTarget);
  end
  else
    S_StartSound (player.mo, Ord(sfx_swish));
end;

//==============================================================================
//
// A_FireFlameThrower
//
// villsa [STRIFE] new codepointer
//
//==============================================================================
procedure A_FireFlameThrower(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
begin
  P_SetMobjState(player.mo, S_PLAY_06);
  dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)]);
  player.mo.angle := player.mo.angle + _SHLW(P_Random - P_Random, 18);

  mo := P_SpawnPlayerMissile(player.mo, Ord(MT_SFIREBALL));
  mo.momz := mo.momz + (5 * FRACUNIT);
end;

//==============================================================================
//
// A_FireMissile
//
// villsa [STRIFE] completly new compared to the original
//
//==============================================================================
procedure A_FireMissile(player: Pplayer_t; psp: Ppspdef_t);
var
  an: angle_t;
begin
  // haleyjd 09/19/10: I previously missed an add op that meant it should be
  // accuracy * 5, not 4. Checks out with other sources.
  an := player.mo.angle;
  player.mo.angle := player.mo.angle + _SHLW(P_Random - P_Random, 19 - (player.accuracy * 5) div 100);
  P_SetMobjState(player.mo, S_PLAY_06);
  dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)]);
  P_SpawnPlayerMissile(player.mo, Ord(MT_MINIMISSLE));
  player.mo.angle := an;
end;

//==============================================================================
//
// A_FireMauler2
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FireMauler2(player: Pplayer_t; pspr: Ppspdef_t);
begin
  P_SetMobjState(player.mo, S_PLAY_06);
  P_DamageMobj(player.mo, player.mo, nil, 20);
  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 30;
  P_SpawnPlayerMissile(player.mo, Ord(MT_TORPEDO));
  P_Thrust(player, player.mo.angle + ANG180, 512000);
end;

//==============================================================================
//
// A_FireGrenade
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FireGrenade(player: Pplayer_t; pspr: Ppspdef_t);
var
  _type: integer;
  mo: Pmobj_t;
  st1, st2: Pstate_t;
  an: angle_t;
  radius: fixed_t;
begin
  // decide on what type of grenade to spawn
  if player.readyweapon = wp_hegrenade then
    _type := Ord(MT_HEGRENADE)
  else if player.readyweapon = wp_wpgrenade then
    _type := Ord(MT_PGRENADE)
  else
  begin
    _type := Ord(MT_HEGRENADE);
    I_Warning('A_FireGrenade(): A_FireGrenade used on wrong weapon!'#13#10);
  end;

  dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)]);

  // set flash frame
  st1 := @states[(NativeInt(pspr.state) - NativeInt(@states[0])) div SizeOf(state_t) + weaponinfo[Ord(player.readyweapon)].flashstate];
  st2 := @states[weaponinfo[Ord(player.readyweapon)].atkstate];
  P_SetPsprite(player, Ord(ps_flash), statenum_t((NativeInt(st1) - NativeInt(st2)) div SizeOf(state_t)));

  player.mo.z := player.mo.z + 32 * FRACUNIT; // ugh
  mo := P_SpawnMortar(player.mo, _type);
  player.mo.z := player.mo.z - 32 * FRACUNIT; // ugh

  // change momz based on player's pitch
  mo.momz := FixedMul((player.lookdir * FRACUNIT) div 160, mo.info.speed) + (8 * FRACUNIT);
  S_StartSound(mo, mo.info.seesound);

  radius := mobjinfo[_type].radius + player.mo.info.radius;
  an := player.mo.angle div ANGLETOFINEUNIT;

  mo.x := mo.x + FixedMul(finecosine[an], radius + (4 * FRACUNIT));
  mo.y := mo.y + FixedMul(finesine[an], radius + (4 * FRACUNIT));

  // shoot grenade from left or right side?
  if @states[weaponinfo[Ord(player.readyweapon)].atkstate] = pspr.state then
    an := (player.mo.angle - ANG90) div ANGLETOFINEUNIT
  else
    an := (player.mo.angle + ANG90) div ANGLETOFINEUNIT;

  mo.x := mo.x + FixedMul(15 * FRACUNIT, finecosine[an]);
  mo.y := mo.y + FixedMul(15 * FRACUNIT, finesine[an]);

  // set bounce flag
  mo.flags := mo.flags or MF_BOUNCE;
end;

//==============================================================================
//
// A_FireElectricBolt
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FireElectricBolt(player: Pplayer_t; pspr: Ppspdef_t);
var
  an: angle_t;
begin
  an := player.mo.angle;
  // haleyjd 09/19/10: Use 5 mul on accuracy here as well
  player.mo.angle := player.mo.angle + _SHLW(P_Random - P_Random, 18 - (player.accuracy * 5) div 100);
  dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)]);
  P_SpawnPlayerMissile(player.mo, Ord(MT_ELECARROW));
  player.mo.angle := an;
  S_StartSound(player.mo, Ord(sfx_xbow));
end;

//==============================================================================
//
// A_FirePoisonBolt
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FirePoisonBolt(player: Pplayer_t; pspr: Ppspdef_t);
var
  an: angle_t;
begin
  an := player.mo.angle;
  // haleyjd 09/19/10: Use 5 mul on accuracy here as well
  player.mo.angle := player.mo.angle + _SHLW(P_Random - P_Random, 18 - (player.accuracy * 5) div 100);
  dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)]);
  P_SpawnPlayerMissile(player.mo, Ord(MT_POISARROW));
  player.mo.angle := an;
  S_StartSound(player.mo, Ord(sfx_xbow));
end;

//==============================================================================
//
// P_GunShot
//
// [STRIFE] Modifications to support accuracy.
//
//==============================================================================
procedure P_GunShot(mo: Pmobj_t; accurate: boolean);
var
  angle: angle_t;
  damage: integer;
begin
  angle := mo.angle;

  // villsa [STRIFE] apply player accuracy
  // haleyjd 09/18/10: made some corrections: use 5x accuracy;
  // eliminated order-of-evaluation dependency
  if not accurate then
    angle := angle + _SHLW(P_Random - P_Random, 20 - (Pplayer_t(mo.player).accuracy * 5) div 100);

  // haleyjd 09/18/10 [STRIFE] corrected damage formula and moved down to
  // preserve proper P_Random call order.
  damage := 4 * ((P_Random mod 3) + 1);

  P_LineAttack(mo, angle, MISSILERANGE, bulletslope, damage);
end;

//==============================================================================
//
// A_FireRifle
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FireRifle(player: Pplayer_t; pspr: Ppspdef_t);
begin
  S_StartSound(player.mo, Ord(sfx_rifle));

  if player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] > 0 then
  begin
    P_SetMobjState(player.mo, S_PLAY_06); // 293
    dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)]);
    P_BulletSlope(player.mo);
    if TMapAim.LineTarget <> nil then
      player.mo.target := TMapAim.LineTarget;
    P_GunShot(player.mo, player.refire = 0);
  end;
end;

//==============================================================================
//
// A_FireMauler1
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FireMauler1(player: Pplayer_t; pspr: Ppspdef_t);
var
  i: integer;
  angle: angle_t;
  damage: integer;
begin
  // haleyjd 09/18/10: Corrected ammo check to use >=
  if player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] >= 20 then
  begin
    dec(player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)], 20);
    P_BulletSlope(player.mo);
    if TMapAim.LineTarget <> nil then
      player.mo.target := TMapAim.LineTarget;
    S_StartSound(player.mo, Ord(sfx_pgrdat));

    for i := 0 to 19 do
    begin
      damage := 5 * ((P_Random and 3) + 1);
      angle := player.mo.angle;
      angle := angle + _SHLW(P_Random - P_Random, 19);
      P_LineAttack(player.mo, angle, 2112 * FRACUNIT,
                         bulletslope + (P_Random - P_Random) * 32, damage);
    end;
  end;
end;

//==============================================================================
//
// A_SigilSound
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_SigilSound(player: Pplayer_t; pspr: Ppspdef_t);
begin
  S_StartSound(player.mo, Ord(sfx_siglup));
  player.extralight := 2;
end;

//==============================================================================
//
// A_FireSigil
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_FireSigil(player: Pplayer_t; pspr: Ppspdef_t);
var
  mo: Pmobj_t;
  an: angle_t;
  i: integer;
  damage: integer;
  thrust: fixed_t;
begin
  // keep info on armor because sigil does piercing damage
  i := player.armortype;
  player.armortype := 0;

  // BUG: setting inflictor causes firing the Sigil to always push the player
  // toward the east, no matter what direction he is facing.
  damage := 4 * (player.sigiltype + 1);
  if G_NeedsCompatibilityMode then
    P_DamageMobj(player.mo, player.mo, nil, damage)
  else
  // haleyjd 20140817: [SVE] fix sigil damage thrust to be directional
  // JVAL: Only if not compatibility mode.
  begin
    P_DamageMobj(player.mo, nil, player.mo, damage);
    if player.mo.mass > 0 then
      thrust := (damage * (FRACUNIT div 8) * 100) div player.mo.mass
    else
      thrust := (damage * (FRACUNIT div 8) * 100) div 500;
    P_Thrust(player, player.mo.angle + ANG180, thrust);
  end;

  // restore armor
  player.armortype := i;

  S_StartSound(player.mo, Ord(sfx_siglup));

  case player.sigiltype of
    // falling lightning bolts from the sky
    0:
      begin
        P_BulletSlope(player.mo);
        if TMapAim.LineTarget <> nil then
          player.mo.target := TMapAim.LineTarget;
        if TMapAim.LineTarget <> nil then
        begin
          // haleyjd 09/18/10: corrected z coordinate
          mo := P_SpawnMobj(TMapAim.LineTarget.x, TMapAim.LineTarget.y, ONFLOORZ,
                            Ord(MT_SIGIL_A_GROUND));
          mo.tracer := TMapAim.LineTarget;
        end
        else
        begin
            an := player.mo.angle div ANGLETOFINEUNIT;
            mo := P_SpawnMobj(player.mo.x, player.mo.y, player.mo.z, Ord(MT_SIGIL_A_GROUND));
            mo.momx := mo.momx + FixedMul(28 * FRACUNIT, finecosine[an]);
            mo.momy := mo.momy + FixedMul(28 * FRACUNIT, finesine[an]);
        end;
        mo.health := -1;
        mo.target := player.mo;
      end;

    // simple projectile
    1:
      begin
        P_SpawnPlayerMissile(player.mo, Ord(MT_SIGIL_B_SHOT)).health := -1;
      end;

    // spread shot
    2:
      begin
        player.mo.angle := player.mo.angle - ANG90; // starting at 270...
        for i := 0 to 19 do // increment by 1/10 of 90, 20 times.
        begin
          player.mo.angle := player.mo.angle + (ANG90 div 10);
          mo := P_SpawnMortar(player.mo, Ord(MT_SIGIL_C_SHOT));
          mo.health := -1;
          mo.z := player.mo.z + (32 * FRACUNIT);
        end;
        player.mo.angle := player.mo.angle - ANG90; // subtract off the extra 90
      end;

    // tracer attack
    3:
      begin
        P_BulletSlope(player.mo);
        if TMapAim.LineTarget <> nil then
          player.mo.target := TMapAim.LineTarget;
        if TMapAim.LineTarget <> nil then
        begin
          mo := P_SpawnPlayerMissile(player.mo, Ord(MT_SIGIL_D_SHOT));
          mo.tracer := TMapAim.LineTarget;
        end
        else
        begin
          an := player.mo.angle div ANGLETOFINEUNIT;
          mo := P_SpawnPlayerMissile(player.mo, Ord(MT_SIGIL_D_SHOT));
          mo.momx := mo.momx + FixedMul(mo.info.speed, finecosine[an]);
          mo.momy := mo.momy + FixedMul(mo.info.speed, finesine[an]);
        end;
        mo.health := -1;
      end;

    // mega blast
    // JVAL: Doomworld forum thread: https://www.doomworld.com/vb/source-ports/84524-chocolate-strife-a-firesigil/
    4:
      begin
        mo := P_SpawnPlayerMissile(player.mo, Ord(MT_SIGIL_E_SHOT));
        mo.health := -1;
        if TMapAim.LineTarget = nil then
        begin
          if player.lookdir < 0 then
            mo.momz := mo.momz + FixedMul(finesine[8192], mo.info.speed)
          else
            mo.momz := mo.momz + FixedMul(finesine[0], mo.info.speed);
        end;
      end;
  end;
end;

//==============================================================================
//
// A_GunFlashThinker
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_GunFlashThinker(player: Pplayer_t; pspr: Ppspdef_t);
begin
  if (player.readyweapon = wp_sigil) and (player.sigiltype <> 0) then
    P_SetPsprite(player, Ord(ps_flash), statenum_t(Ord(S_SIGH_00) + player.sigiltype))
  else
    P_SetPsprite(player, Ord(ps_flash), S_NULL);
end;

//==============================================================================
//
// A_Light1
//
//==============================================================================
procedure A_Light1(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 1;
end;

//==============================================================================
//
// A_Light2
//
//==============================================================================
procedure A_Light2(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 2;
end;

//==============================================================================
//
// A_SigilShock
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_SigilShock(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := -3;
end;

//==============================================================================
//
// A_TorpedoExplode
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_TorpedoExplode(actor: Pmobj_t);
var
  i: integer;
begin
  actor.angle := actor.angle - ANG180;

  for i := 0 to 79 do
  begin
    actor.angle := actor.angle + (ANG90 div 20);
    P_SpawnMortar(actor, Ord(MT_TORPEDOSPREAD)).target := actor.target;
  end;
end;

//==============================================================================
//
// A_MaulerSound
//
// villsa [STRIFE] - new codepointer
//
//==============================================================================
procedure A_MaulerSound(player: Pplayer_t; psp: pspdef_t);
begin
  S_StartSound(player.mo, Ord(sfx_proton));
  psp.sx := psp.sx + (P_Random - P_Random) * 1024;
  psp.sy := psp.sy + (P_Random - P_Random) * 1024;
end;

//==============================================================================
//
// TPspriteGameRules.AfterMovePsprites
//
//==============================================================================
class procedure TPspriteGameRules.AfterMovePsprites(const player: Pplayer_t);
begin
  // villsa [STRIFE] extra stuff for targeter
  player.psprites[Ord(ps_targleft)].sx :=
        (160 * FRACUNIT) - ((100 - player.accuracy) * FRACUNIT);

  player.psprites[Ord(ps_targright)].sx :=
        ((100 - player.accuracy) * FRACUNIT) + (160 * FRACUNIT);
end;

//==============================================================================
//
// TPspriteGameRules.DropWeaponState
//
//==============================================================================
class function TPspriteGameRules.DropWeaponState(const player: Pplayer_t): statenum_t;
begin
  result := statenum_t(weaponinfo[Ord(player.readyweapon)].downstate);
end;

//==============================================================================
//
// TPspriteGameRules.RaisedState
//
//==============================================================================
class function TPspriteGameRules.RaisedState(const player: Pplayer_t): statenum_t;
begin
  result := statenum_t(weaponinfo[Ord(player.readyweapon)].readystate);
end;

//==============================================================================
//
// TPspriteGameRules.StaysLowered
//
//==============================================================================
class function TPspriteGameRules.StaysLowered(const player: Pplayer_t): boolean;
begin
  result := false;
end;

//==============================================================================
//
// TPspriteGameRules.AfterLowered
//
//==============================================================================
class procedure TPspriteGameRules.AfterLowered(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TPspriteGameRules.CheckSupplies
//
//==============================================================================
class procedure TPspriteGameRules.CheckSupplies(const player: Pplayer_t);
begin
  P_CheckAmmo(player);
end;

end.
