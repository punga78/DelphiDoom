{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a melee attack (MeleeAttackBState)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.MeleeAttackState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.StateBase,
  DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step of a hit with a melee weapon (or a rifle butt): it checks the unit and the target, pushes the
  ///   (cosmetic) explosion, and after it decides whether the attack hit and what it does to the target. An alien
  ///   that has time units left attacks again
  /// </summary>
  TXcomMeleeAttackState = class(TXcomBattleStateBase)
  strict private
    FUnit: TXcomBattleUnit;
    FTarget: TXcomBattleUnit;
    FWeapon: TXcomBattleItem;
    FAmmo: TXcomBattleItem;
    FInitialized: Boolean;
    FVoxel: TXcomPosition;
    procedure PerformMeleeAttack;
    procedure ResolveHit;
  public
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
    procedure Init; override;
    procedure Think; override;
    function StateName: string; override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.AIModule, DelphiDoom.XcomBattle.ExplosionState;

const
  SNoTarget = 'The melee attack has no unit to hit at the target tile';

constructor TXcomMeleeAttackState.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
begin
  inherited Create(AGame, AAction);
end;

function TXcomMeleeAttackState.StateName: string;
begin
  Result := 'MeleeAttackBState';
end;

procedure TXcomMeleeAttackState.Init;
var
  LTile: TXcomTile;
  LAI: TXcomAIModule;
  LHeight: Integer;
begin
  if FInitialized then
    Exit;
  FInitialized := True;
  FWeapon := ActionData.Weapon;
  if not Assigned(FWeapon) then
  begin
    // can't shoot without weapon
    FGame.PopState;
    Exit;
  end;
  FAmmo := FWeapon.AmmoItem;
  if not Assigned(FAmmo) then
    FAmmo := FWeapon;
  LTile := FGame.Save.TileAt(ActionData.Target);
  if not Assigned(LTile) then
  begin
    // invalid target position
    FGame.PopState;
    Exit;
  end;
  FUnit := ActionData.Actor;
  if FUnit.IsOut or (FUnit.Health = 0) or (FUnit.Health < FUnit.StunLevel) then
  begin
    // something went wrong - we can't shoot when dead or unconscious, or if we're about to fall over
    FGame.PopState;
    Exit;
  end;
  // reaction fire
  if FUnit.Faction <> FGame.Save.Side then
  begin
    // no ammo or target is dead: give the time units back and cancel the shot
    if (not Assigned(FAmmo)) or (not Assigned(LTile.CurrentUnit)) or LTile.CurrentUnit.IsOut or
      (LTile.CurrentUnit <> FGame.Save.SelectedUnit) then
    begin
      FUnit.SetTimeUnits(FUnit.TimeUnits + FUnit.GetActionTus(ActionData.ActionType, ActionData.Weapon));
      FGame.PopState;
      Exit;
    end;
    FUnit.LookAt(ActionData.Target, FUnit.TurretType <> -1);
    while FUnit.Status = STATUS_TURNING do
      FUnit.Turn;
  end;
  LAI := nil;
  if Assigned(FUnit.AI) then
    LAI := FUnit.AI as TXcomAIModule;
  if (FUnit.Faction = FGame.Save.Side) and (FUnit.Faction <> FACTION_PLAYER) and (not FGame.GetDebugPlay) and
    Assigned(LAI) and Assigned(LAI.AggroTarget) then
    FTarget := LAI.AggroTarget
  else
    FTarget := LTile.CurrentUnit;
  if not Assigned(FTarget) then
    raise EXcomBattleException.Create(SNoTarget);
  LHeight := FTarget.FloatHeight + (FTarget.GetHeight div 2) - LTile.GetTerrainLevel;
  FVoxel := ActionData.Target * TXcomPosition.Make(16, 16, 24) + TXcomPosition.Make(8, 8, LHeight);
  PerformMeleeAttack;
end;

procedure TXcomMeleeAttackState.Think;
var
  LSecondAttack: Boolean;
begin
  // if the unit burns floortiles, burn floortiles
  if (FUnit.SpecialAbility = SPECAB_BURNFLOOR) or (FUnit.SpecialAbility = SPECAB_BURN_AND_EXPLODE) then
    FGame.Save.TileAt(ActionData.Target).Ignite(15);
  // Determine if the attack was successful: melee attacks can MISS, so the damage and the casualty check are
  // done here and not by the explosion
  ResolveHit;
  // aliens, not performing a reaction attack, with enough time units for a second attack (*2 because they will
  // be charged for the initial attack when this state pops), whose target is still alive or at least
  // conscious, and with ammo to make the attack
  LSecondAttack := (FUnit.Faction <> FACTION_PLAYER) and (FUnit.Faction = FGame.Save.Side) and
    (FUnit.TimeUnits >= FUnit.GetActionTus(BA_HIT, ActionData.Weapon) * 2) and Assigned(FTarget) and
    (FTarget.Health > 0) and (FTarget.Health > FTarget.StunLevel) and Assigned(FWeapon.AmmoItem);
  if LSecondAttack then
  begin
    // spend the time units immediately
    FUnit.SpendTimeUnits(FUnit.GetActionTus(BA_HIT, FWeapon));
    PerformMeleeAttack;
  end
  else
  begin
    if ActionData.CameraPosition.Z <> -1 then
      FGame.View.CenterOnPosition(ActionData.CameraPosition, False);
    // melee doesn't trigger a reaction
    if FUnit.Faction = FGame.Save.Side then
      // not a reaction attack: this restores the cursor
      FGame.GetCurrentAction.ActionType := BA_NONE;
    if (FGame.Save.Side = FACTION_PLAYER) or FGame.Save.DebugMode then
      FGame.SetupCursor;
    FGame.ConvertInfected;
    FGame.PopState;
  end;
end;

procedure TXcomMeleeAttackState.PerformMeleeAttack;
begin
  // set the soldier in an aiming position
  FUnit.Aim(True);
  FUnit.CacheInvalid := True;
  FGame.View.CacheUnit(FUnit);
  // make some noise
  if Assigned(FAmmo) and (FAmmo.Rules.MeleeSound <> -1) then
    FGame.View.PlaySound(FAmmo.Rules.MeleeSound, ActionData.Target)
  else if FWeapon.Rules.MeleeSound <> -1 then
    FGame.View.PlaySound(FWeapon.Rules.MeleeSound, ActionData.Target);
  // use up ammo if applicable
  if (not FGame.Save.DebugMode) and (FWeapon.Rules.BattleType = TXcomRuleItem.BT_MELEE) and Assigned(FAmmo) and
    (not FAmmo.SpendBullet) then
  begin
    FGame.Save.RemoveItem(FAmmo);
    ActionData.Weapon.SetAmmoItem(nil);
  end;
  FGame.View.SetCursorType(-1);
  // make an explosion animation
  FGame.StatePushFront(TXcomExplosionState.Create(FGame, FVoxel, ActionData.Weapon, ActionData.Actor, nil, True,
    True));
end;

procedure TXcomMeleeAttackState.ResolveHit;
var
  LType: Integer;
  LPower: Integer;
  LDifference: TXcomPosition;
  LDamagePosition: TXcomPosition;
begin
  if not TXcomBattleRandom.Percent(FGame.Save.Random, FUnit.GetFiringAccuracy(BA_HIT, FWeapon)) then
    Exit;
  // give soldiers XP
  if Assigned(FUnit.GeoscapeSoldier) and Assigned(FTarget) and (FTarget.OriginalFaction = FACTION_HOSTILE) then
    FUnit.AddMeleeExp;
  // check if this unit turns others into zombies
  if (FWeapon.Rules.BattleType = TXcomRuleItem.BT_MELEE) and Assigned(FAmmo) and (FAmmo.Rules.ZombieUnit <> '') and
    Assigned(FTarget) and (Assigned(FTarget.GeoscapeSoldier) or (FTarget.UnitRules.Race = 'STR_CIVILIAN')) and
    (FTarget.SpawnUnit = '') then
  begin
    // converts the victim to a zombie on death
    FTarget.Respawn := True;
    FTarget.SpawnUnit := FAmmo.Rules.ZombieUnit;
  end;
  // assume rifle butt to begin with, override it as needed
  LType := TXcomRuleItem.DT_STUN;
  LPower := FWeapon.Rules.MeleePower;
  if (FWeapon.Rules.BattleType = TXcomRuleItem.BT_MELEE) and Assigned(FAmmo) then
  begin
    LType := FAmmo.Rules.DamageType;
    LPower := FAmmo.Rules.Power;
  end;
  // since melee aliens don't use a conventional weapon type, we use their strength instead
  if FWeapon.Rules.StrengthApplied then
    LPower := LPower + FUnit.Stats.Strength;
  // make some noise to signal the hit
  if FWeapon.Rules.MeleeHitSound <> -1 then
    FGame.View.PlaySound(FWeapon.Rules.MeleeHitSound, ActionData.Target);
  // offset the damage voxel ever so slightly so that the target knows which side the attack came from; large
  // units may cause it to offset too much, so the values are clamped
  LDifference := FUnit.Position - ActionData.Target;
  LDifference.X := EnsureRange(LDifference.X, -1, 1);
  LDifference.Y := EnsureRange(LDifference.Y, -1, 1);
  LDamagePosition := FVoxel + LDifference;
  FGame.TileEngine.Hit(LDamagePosition, LPower, LType, FUnit);
  // now check for new casualties
  FGame.CheckForCasualties(FAmmo, FUnit);
end;

end.
