{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the weapon and the animations of the torso      }
{                                                                              }
{  Port of PM_Weapon, PM_BeginWeaponChange, PM_FinishWeaponChange,             }
{  PM_TorsoAnimation and PM_Animate of bg_pmove.c, from the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Weapon;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.State,
  DelphiDoom.Pmove.Events;

type
  /// <summary>
  ///   The part of the weapons that runs in the movement (so that the client can predict it): the change of
  ///   weapon, the time between shots, the ammo, the events of firing, using the holdable item
  /// </summary>
  TPmoveWeapon = class
  strict private
    FState: TPmoveState;
    FEvents: TPmoveEvents;
    procedure BeginWeaponChange(const AWeapon: Integer);
    procedure FinishWeaponChange;
  public
    constructor Create(const AState: TPmoveState; const AEvents: TPmoveEvents);
    /// <summary>PM_Weapon: generates weapon events and modifies the weapon counter</summary>
    procedure Weapon;
    /// <summary>PM_TorsoAnimation</summary>
    procedure TorsoAnimation;
    /// <summary>PM_Animate: the gesture</summary>
    procedure Animate;
  end;

implementation


constructor TPmoveWeapon.Create(const AState: TPmoveState; const AEvents: TPmoveEvents);
begin
  inherited Create;
  FState := AState;
  FEvents := AEvents;
end;

procedure TPmoveWeapon.BeginWeaponChange(const AWeapon: Integer);
begin
  if (AWeapon <= Q3_WP_NONE) or (AWeapon >= Q3_WP_NUM_WEAPONS) then
    Exit;

  if (FState.Pm.Ps.Stats[Q3_STAT_WEAPONS] and (1 shl AWeapon)) = 0 then
    Exit;

  if FState.Pm.Ps.WeaponState = Q3_WEAPON_DROPPING then
    Exit;

  FEvents.AddEvent(Q3_EV_CHANGE_WEAPON);
  FState.Pm.Ps.WeaponState := Q3_WEAPON_DROPPING;
  Inc(FState.Pm.Ps.WeaponTime, 200);
  FEvents.StartTorsoAnim(Q3_TORSO_DROP);
end;

procedure TPmoveWeapon.FinishWeaponChange;
var
  LWeapon: Integer;
begin
  LWeapon := FState.Pm.Cmd.Weapon;
  if (LWeapon < Q3_WP_NONE) or (LWeapon >= Q3_WP_NUM_WEAPONS) then
    LWeapon := Q3_WP_NONE;

  if (FState.Pm.Ps.Stats[Q3_STAT_WEAPONS] and (1 shl LWeapon)) = 0 then
    LWeapon := Q3_WP_NONE;

  FState.Pm.Ps.Weapon := LWeapon;
  FState.Pm.Ps.WeaponState := Q3_WEAPON_RAISING;
  Inc(FState.Pm.Ps.WeaponTime, 250);
  FEvents.StartTorsoAnim(Q3_TORSO_RAISE);
end;

procedure TPmoveWeapon.TorsoAnimation;
begin
  if FState.Pm.Ps.WeaponState = Q3_WEAPON_READY then
  begin
    if FState.Pm.Ps.Weapon = Q3_WP_GAUNTLET then
      FEvents.ContinueTorsoAnim(Q3_TORSO_STAND2)
    else
      FEvents.ContinueTorsoAnim(Q3_TORSO_STAND);
  end;
end;

procedure TPmoveWeapon.Animate;
begin
  if (FState.Pm.Cmd.Buttons and Q3_BUTTON_GESTURE) <> 0 then
  begin
    if FState.Pm.Ps.TorsoTimer = 0 then
    begin
      FEvents.StartTorsoAnim(Q3_TORSO_GESTURE);
      FState.Pm.Ps.TorsoTimer := Q3_TIMER_GESTURE;
      FEvents.AddEvent(Q3_EV_TAUNT);
    end;
  end;
end;

procedure TPmoveWeapon.Weapon;
var
  LAddTime, LTag: Integer;
  LQuotient: Double;
begin
  // don't allow attack until all buttons are up
  if (FState.Pm.Ps.PmFlags and Q3_PMF_RESPAWNED) <> 0 then
    Exit;

  // ignore if spectator
  if FState.Pm.Ps.Persistant[Q3_PERS_TEAM] = Q3_TEAM_SPECTATOR then
    Exit;

  // check for dead player
  if FState.Pm.Ps.Stats[Q3_STAT_HEALTH] <= 0 then
  begin
    FState.Pm.Ps.Weapon := Q3_WP_NONE;
    Exit;
  end;

  // check for item using
  if (FState.Pm.Cmd.Buttons and Q3_BUTTON_USE_HOLDABLE) <> 0 then
  begin
    if (FState.Pm.Ps.PmFlags and Q3_PMF_USE_ITEM_HELD) = 0 then
    begin
      LTag := FState.ItemTag(FState.Pm.Ps.Stats[Q3_STAT_HOLDABLE_ITEM]);
      if (LTag = Q3_HI_MEDKIT) and
        (FState.Pm.Ps.Stats[Q3_STAT_HEALTH] >= (FState.Pm.Ps.Stats[Q3_STAT_MAX_HEALTH] + 25)) then
      begin
        // don't use medkit if at max health
      end
      else
      begin
        FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_USE_ITEM_HELD;
        FEvents.AddEvent(Q3_EV_USE_ITEM0 + LTag);
        FState.Pm.Ps.Stats[Q3_STAT_HOLDABLE_ITEM] := 0;
      end;
      Exit;
    end;
  end
  else
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_USE_ITEM_HELD);

  // make weapon function
  if FState.Pm.Ps.WeaponTime > 0 then
    Dec(FState.Pm.Ps.WeaponTime, FState.Pml.Msec);

  // check for weapon change: can't change if weapon is firing, but can change again if lowering or raising
  if (FState.Pm.Ps.WeaponTime <= 0) or (FState.Pm.Ps.WeaponState <> Q3_WEAPON_FIRING) then
    if FState.Pm.Ps.Weapon <> FState.Pm.Cmd.Weapon then
      BeginWeaponChange(FState.Pm.Cmd.Weapon);

  if FState.Pm.Ps.WeaponTime > 0 then
    Exit;

  // change weapon if time
  if FState.Pm.Ps.WeaponState = Q3_WEAPON_DROPPING then
  begin
    FinishWeaponChange;
    Exit;
  end;

  if FState.Pm.Ps.WeaponState = Q3_WEAPON_RAISING then
  begin
    FState.Pm.Ps.WeaponState := Q3_WEAPON_READY;
    if FState.Pm.Ps.Weapon = Q3_WP_GAUNTLET then
      FEvents.StartTorsoAnim(Q3_TORSO_STAND2)
    else
      FEvents.StartTorsoAnim(Q3_TORSO_STAND);
    Exit;
  end;

  // check for fire
  if (FState.Pm.Cmd.Buttons and Q3_BUTTON_ATTACK) = 0 then
  begin
    FState.Pm.Ps.WeaponTime := 0;
    FState.Pm.Ps.WeaponState := Q3_WEAPON_READY;
    Exit;
  end;

  // start the animation even if out of ammo
  if FState.Pm.Ps.Weapon = Q3_WP_GAUNTLET then
  begin
    // the guantlet only "fires" when it actually hits something
    if not FState.Pm.GauntletHit then
    begin
      FState.Pm.Ps.WeaponTime := 0;
      FState.Pm.Ps.WeaponState := Q3_WEAPON_READY;
      Exit;
    end;
    FEvents.StartTorsoAnim(Q3_TORSO_ATTACK2);
  end
  else
    FEvents.StartTorsoAnim(Q3_TORSO_ATTACK);

  FState.Pm.Ps.WeaponState := Q3_WEAPON_FIRING;

  // check for out of ammo
  if FState.Pm.Ps.Ammo[FState.Pm.Ps.Weapon] = 0 then
  begin
    FEvents.AddEvent(Q3_EV_NOAMMO);
    Inc(FState.Pm.Ps.WeaponTime, 500);
    Exit;
  end;

  // take an ammo away if not infinite
  if FState.Pm.Ps.Ammo[FState.Pm.Ps.Weapon] <> -1 then
    Dec(FState.Pm.Ps.Ammo[FState.Pm.Ps.Weapon]);

  // fire weapon
  FEvents.AddEvent(Q3_EV_FIRE_WEAPON);

  case FState.Pm.Ps.Weapon of
    Q3_WP_LIGHTNING: LAddTime := 50;
    Q3_WP_SHOTGUN: LAddTime := 1000;
    Q3_WP_MACHINEGUN: LAddTime := 100;
    Q3_WP_GRENADE_LAUNCHER: LAddTime := 800;
    Q3_WP_ROCKET_LAUNCHER: LAddTime := 800;
    Q3_WP_PLASMAGUN: LAddTime := 100;
    Q3_WP_RAILGUN: LAddTime := 1500;
    Q3_WP_BFG: LAddTime := 200;
    Q3_WP_GRAPPLING_HOOK: LAddTime := 400;
  else
    // default and WP_GAUNTLET
    LAddTime := 400;
  end;

  if FState.Pm.Ps.Powerups[Q3_PW_HASTE] <> 0 then
  begin
    // addTime /= 1.3 is an integer divided as a double and truncated
    LQuotient := LAddTime / Q3_HASTE_DIVISOR;
    LAddTime := Trunc(LQuotient);
  end;

  Inc(FState.Pm.Ps.WeaponTime, LAddTime);
end;

end.
