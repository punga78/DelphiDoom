{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a shot or a throw in flight           }
{  (ProjectileFlyBState)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ProjectileFlyState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.StateBase,
  DelphiDoom.XcomBattle.Game.Intf, DelphiDoom.XcomBattle.Projectile;

type
  /// <summary>
  ///   The step in which a unit fires a weapon or throws an item: it checks the ammunition, the range and the
  ///   target, makes the Projectile (which calculates the trajectory with the deviation of the accuracy), moves it
  ///   one step a tick and at the impact starts the explosion or the hit, drops the thrown item, fires the next
  ///   shot of an auto burst and the pellets of a shotgun. The Projectile belongs to the step; the view draws it
  /// </summary>
  TXcomProjectileFlyState = class(TXcomBattleStateBase)
  strict private
    FUnit: TXcomBattleUnit;
    FAmmo: TXcomBattleItem;
    FProjectileItem: TXcomBattleItem;
    FOrigin: TXcomPosition;
    FOriginVoxel: TXcomPosition;
    FTargetVoxel: TXcomPosition;
    FProjectileImpact: Integer;
    FInitialized: Boolean;
    FTargetFloor: Boolean;
    FProjectile: TXcomProjectile;
    function ProjectileOptions: TXcomProjectileOptions;
    function CreateNewProjectile: Boolean;
    procedure DestroyProjectile;
    procedure ProjectileHitUnit(const APosition: TXcomPosition);
  public
    /// <param name="AOrigin">The tile the projectile starts from (a waypoint of a missile)</param>
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction;
      const AOrigin: TXcomPosition); overload;
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction); overload;
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Cancel; override;
    function StateName: string; override;
    /// <summary>setOriginVoxel: the next missile of a waypoint cascade starts where the last one ended</summary>
    procedure SetOriginVoxel(const APosition: TXcomPosition);
    /// <summary>targetFloor: a missile with two waypoints on the same tile aims at the floor</summary>
    procedure TargetFloor;
    /// <summary>The voxel of the projectile in flight and the length of its trajectory, for the traces ('' when none)</summary>
    function ProjectileText: string;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomBattle.ViewVapor, DelphiDoom.XcomBattle.Trajectory,
  DelphiDoom.XcomBattle.ThrowRange, DelphiDoom.XcomBattle.ExplosionState, DelphiDoom.XcomBattle.AIModule;

constructor TXcomProjectileFlyState.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction;
  const AOrigin: TXcomPosition);
begin
  inherited Create(AGame, AAction);
  FOrigin := AOrigin;
  FOriginVoxel := TXcomPosition.Make(-1, -1, -1);
end;

constructor TXcomProjectileFlyState.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
begin
  Create(AGame, AAction, AAction.Actor.Position);
end;

destructor TXcomProjectileFlyState.Destroy;
begin
  FProjectile.Free;
  inherited Destroy;
end;

function TXcomProjectileFlyState.StateName: string;
begin
  Result := 'ProjectileFlyBState';
end;

procedure TXcomProjectileFlyState.SetOriginVoxel(const APosition: TXcomPosition);
begin
  FOriginVoxel := APosition;
end;

procedure TXcomProjectileFlyState.TargetFloor;
begin
  FTargetFloor := True;
end;

function TXcomProjectileFlyState.ProjectileText: string;
var
  LPosition: TXcomPosition;
begin
  if not Assigned(FProjectile) then
    Exit('none');
  LPosition := FProjectile.GetPosition;
  Result := Format('%d/%d/%d n=%d', [LPosition.X, LPosition.Y, LPosition.Z, FProjectile.Trajectory.Count]);
end;

function TXcomProjectileFlyState.ProjectileOptions: TXcomProjectileOptions;
begin
  Result.FireSpeed := FGame.Options.FireSpeed;
  Result.UfoExtenderAccuracy := FGame.Options.UfoExtenderAccuracy;
  Result.ForceFire := FGame.Options.ForceFire;
  Result.ControlHeld := FGame.Options.ControlHeld;
end;

procedure TXcomProjectileFlyState.DestroyProjectile;
begin
  FGame.View.SetProjectile(nil);
  FreeAndNil(FProjectile);
end;

procedure TXcomProjectileFlyState.Init;
var
  LWeapon: TXcomBattleItem;
  LEndTile: TXcomTile;
  LDistanceSq: Integer;
  LIsPlayer: Boolean;
  LForceEnableObstacles: Boolean;
  LTargetTile: TXcomTile;
  LOriginVoxel: TXcomPosition;
  LTarget: TXcomPosition;
begin
  if FInitialized then
    Exit;
  FInitialized := True;
  LWeapon := ActionData.Weapon;
  FProjectileItem := nil;
  if not Assigned(LWeapon) then // can't shoot without weapon
  begin
    FGame.PopState;
    Exit;
  end;
  if not Assigned(FGame.Save.TileAt(ActionData.Target)) then // invalid target position
  begin
    FGame.PopState;
    Exit;
  end;
  if FGame.PanicHandled and (ActionData.Actor.TimeUnits < ActionData.TimeUnits) then
  begin
    ActionData.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    FGame.PopState;
    Exit;
  end;
  FUnit := ActionData.Actor;
  FAmmo := LWeapon.AmmoItem;
  if FUnit.IsOut or (FUnit.Health = 0) or (FUnit.Health < FUnit.StunLevel) then
  begin
    // something went wrong - we can't shoot when dead or unconscious, or if we're about to fall over.
    FGame.PopState;
    Exit;
  end;
  // reaction fire
  if FUnit.Faction <> FGame.Save.Side then
  begin
    // no ammo or target is dead: give the time units back and cancel the shot.
    LTargetTile := FGame.Save.TileAt(ActionData.Target);
    if (not Assigned(FAmmo)) or (not Assigned(LTargetTile.CurrentUnit)) or LTargetTile.CurrentUnit.IsOut or
      (LTargetTile.CurrentUnit <> FGame.Save.SelectedUnit) then
    begin
      FUnit.SetTimeUnits(FUnit.TimeUnits + FUnit.GetActionTus(ActionData.ActionType, ActionData.Weapon));
      FGame.PopState;
      Exit;
    end;
    FUnit.LookAt(ActionData.Target, FUnit.TurretType <> -1);
    while FUnit.Status = STATUS_TURNING do
      FUnit.Turn;
  end;
  LEndTile := FGame.Save.TileAt(ActionData.Target);
  LDistanceSq := FGame.TileEngine.DistanceUnitToPositionSq(ActionData.Actor, ActionData.Target, False);
  LIsPlayer := FGame.Save.Side = FACTION_PLAYER;
  if LIsPlayer then
    FGame.View.ResetObstacles;
  case ActionData.ActionType of
    BA_SNAPSHOT, BA_AIMEDSHOT, BA_AUTOSHOT, BA_LAUNCH:
      begin
        if not Assigned(FAmmo) then
        begin
          ActionData.ResultText := 'STR_NO_AMMUNITION_LOADED';
          FGame.PopState;
          Exit;
        end;
        if FAmmo.AmmoQuantity = 0 then
        begin
          ActionData.ResultText := 'STR_NO_ROUNDS_LEFT';
          FGame.PopState;
          Exit;
        end;
        if LDistanceSq > LWeapon.Rules.MaxRangeSquared then
          // special handling for short ranges and diagonals
          if not (((LWeapon.Rules.MaxRange = 1) and (LDistanceSq <= 3)) or
            ((LWeapon.Rules.MaxRange = 2) and (LDistanceSq <= 6))) then
          begin
            // out of range
            ActionData.ResultText := 'STR_OUT_OF_RANGE';
            FGame.PopState;
            Exit;
          end;
      end;
    BA_THROW:
      begin
        if not TXcomThrowRange.IsValid(ActionData, FGame.TileEngine.GetOriginVoxel(ActionData, nil),
          FGame.Save.TileAt(ActionData.Target)) then
        begin
          // out of range
          ActionData.ResultText := 'STR_OUT_OF_RANGE';
          FGame.PopState;
          Exit;
        end;
        if Assigned(LEndTile) and (LEndTile.GetTerrainLevel = -24) and
          (LEndTile.Position.Z + 1 < FGame.Save.MapSizeZ) then
          ActionData.Target := ActionData.Target + TXcomPosition.Make(0, 0, 1);
        FProjectileItem := LWeapon;
      end;
  else
    FGame.PopState;
    Exit;
  end;
  LForceEnableObstacles := False;
  if (ActionData.ActionType = BA_LAUNCH) or (FGame.Options.ForceFire and FGame.Options.ControlHeld and LIsPlayer) or
    (not FGame.PanicHandled) then
  begin
    // target nothing, targets the middle of the tile
    FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16 + 8, ActionData.Target.Y * 16 + 8,
      ActionData.Target.Z * 24 + 12);
    if ActionData.ActionType = BA_LAUNCH then
    begin
      if FTargetFloor then
        // launched missiles with two waypoints placed on the same tile: target the floor.
        FTargetVoxel := FTargetVoxel - TXcomPosition.Make(0, 0, 10)
      else
        // launched missiles go slightly higher than the middle.
        FTargetVoxel := FTargetVoxel + TXcomPosition.Make(0, 0, 4);
    end;
  end
  else if not ActionData.Weapon.Rules.ArcingShot then
  begin
    // determine the target voxel: aim at the center of the unit, the object, the walls or the floor (in that
    // priority); if there is no LOF to the center, try elsewhere (more outward).
    LTargetTile := FGame.Save.TileAt(ActionData.Target);
    LOriginVoxel := FGame.TileEngine.GetOriginVoxel(ActionData, FGame.Save.TileAt(FOrigin));
    if Assigned(LTargetTile.CurrentUnit) and ((FUnit.Faction <> FACTION_PLAYER) or LTargetTile.CurrentUnit.Visible) then
    begin
      if (FOrigin = ActionData.Target) or (LTargetTile.CurrentUnit = FUnit) then
        // don't shoot at yourself but shoot at the floor
        FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16 + 8, ActionData.Target.Y * 16 + 8,
          ActionData.Target.Z * 24)
      else if not FGame.TileEngine.CanTargetUnit(LOriginVoxel, LTargetTile, FTargetVoxel, FUnit, LIsPlayer) then
      begin
        FTargetVoxel := TXcomPosition.Make(-16, -16, -24); // out of bounds, even after voxel to tile calculation.
        if LIsPlayer then
          LForceEnableObstacles := True;
      end;
    end
    else if Assigned(LTargetTile.MapData[XCOM_PART_OBJECT]) then
    begin
      if not FGame.TileEngine.CanTargetTile(LOriginVoxel, LTargetTile, XCOM_PART_OBJECT, FTargetVoxel, FUnit,
        LIsPlayer) then
        FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16 + 8, ActionData.Target.Y * 16 + 8,
          ActionData.Target.Z * 24 + 10);
    end
    else if Assigned(LTargetTile.MapData[XCOM_PART_NORTHWALL]) then
    begin
      if not FGame.TileEngine.CanTargetTile(LOriginVoxel, LTargetTile, XCOM_PART_NORTHWALL, FTargetVoxel, FUnit,
        LIsPlayer) then
        FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16 + 8, ActionData.Target.Y * 16,
          ActionData.Target.Z * 24 + 9);
    end
    else if Assigned(LTargetTile.MapData[XCOM_PART_WESTWALL]) then
    begin
      if not FGame.TileEngine.CanTargetTile(LOriginVoxel, LTargetTile, XCOM_PART_WESTWALL, FTargetVoxel, FUnit,
        LIsPlayer) then
        FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16, ActionData.Target.Y * 16 + 8,
          ActionData.Target.Z * 24 + 9);
    end
    else if Assigned(LTargetTile.MapData[XCOM_PART_FLOOR]) then
    begin
      if not FGame.TileEngine.CanTargetTile(LOriginVoxel, LTargetTile, XCOM_PART_FLOOR, FTargetVoxel, FUnit,
        LIsPlayer) then
        FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16 + 8, ActionData.Target.Y * 16 + 8,
          ActionData.Target.Z * 24 + 2);
    end
    else
    begin
      // dummy attempt (only to highlight obstacles)
      FGame.TileEngine.CanTargetTile(LOriginVoxel, LTargetTile, XCOM_PART_DUMMY, FTargetVoxel, FUnit, LIsPlayer);
      // target nothing, targets the middle of the tile
      FTargetVoxel := TXcomPosition.Make(ActionData.Target.X * 16 + 8, ActionData.Target.Y * 16 + 8,
        ActionData.Target.Z * 24 + 12);
    end;
  end;
  LTarget := ActionData.Target;
  if CreateNewProjectile then
  begin
    FGame.View.SetCursorType(CT_NONE);
    FGame.View.DisableObstacles;
  end
  else if LIsPlayer and ((FTargetVoxel.Z >= 0) or LForceEnableObstacles) then
    FGame.View.EnableObstacles;
end;

function TXcomProjectileFlyState.CreateNewProjectile: Boolean;
var
  LAccuracyDivider: Double;
begin
  Inc(ActionData.AutoShotCounter);
  // create a new projectile
  FProjectile := TXcomProjectile.Create(FGame.Save, FGame.TileEngine, FGame, ProjectileOptions, ActionData, FOrigin,
    FTargetVoxel, FAmmo, TXcomViewVapor.Create(FGame.View));
  // add the projectile on the map
  FGame.View.SetProjectile(FProjectile);
  FGame.View.SetStateInterval(16);
  // let it calculate a trajectory
  FProjectileImpact := V_EMPTY;
  LAccuracyDivider := 100.0;
  // berserking units are half as accurate
  if not FGame.PanicHandled then
    LAccuracyDivider := 200.0;
  if ActionData.ActionType = BA_THROW then
  begin
    FProjectileImpact := FProjectile.CalculateThrow(FUnit.GetThrowingAccuracy / LAccuracyDivider);
    if (FProjectileImpact = V_FLOOR) or (FProjectileImpact = V_UNIT) or (FProjectileImpact = V_OBJECT) then
    begin
      if (FUnit.Faction <> FACTION_PLAYER) and (FProjectileItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE) then
        FProjectileItem.FuseTimer := 0;
      FProjectileItem.MoveToOwner(nil);
      FUnit.CacheInvalid := True;
      FGame.View.CacheUnit(FUnit);
      FGame.View.PlaySound(FGame.Ruleset.Constants.ItemThrow, FUnit.Position);
      FUnit.AddThrowingExp;
    end
    else
    begin
      // unable to throw here
      DestroyProjectile;
      ActionData.ResultText := 'STR_UNABLE_TO_THROW_HERE';
      ActionData.TimeUnits := 0;
      FGame.PopState;
      Exit(False);
    end;
  end
  else if ActionData.Weapon.Rules.ArcingShot then // special code for the "spit" trajectory
  begin
    FProjectileImpact := FProjectile.CalculateThrow(FUnit.GetFiringAccuracy(ActionData.ActionType,
      ActionData.Weapon) / LAccuracyDivider);
    if (FProjectileImpact <> V_EMPTY) and (FProjectileImpact <> V_OUTOFBOUNDS) then
    begin
      // set the soldier in an aiming position
      FUnit.Aim(True);
      FUnit.CacheInvalid := True;
      FGame.View.CacheUnit(FUnit);
      // and we have a lift-off
      if FAmmo.Rules.FireSound <> -1 then
        FGame.View.PlaySound(FAmmo.Rules.FireSound, FUnit.Position)
      else if ActionData.Weapon.Rules.FireSound <> -1 then
        FGame.View.PlaySound(ActionData.Weapon.Rules.FireSound, FUnit.Position);
      if (not FGame.Save.DebugMode) and (ActionData.ActionType <> BA_LAUNCH) and (not FAmmo.SpendBullet) then
      begin
        FGame.Save.RemoveItem(FAmmo);
        ActionData.Weapon.SetAmmoItem(nil);
      end;
    end
    else
    begin
      // no line of fire
      DestroyProjectile;
      if FGame.PanicHandled then
        ActionData.ResultText := 'STR_NO_LINE_OF_FIRE'
      else
        FUnit.SetTimeUnits(FUnit.TimeUnits + ActionData.TimeUnits); // refund shot TUs for berserking
      FUnit.AbortTurn;
      FGame.PopState;
      Exit(False);
    end;
  end
  else
  begin
    if FOriginVoxel <> TXcomPosition.Make(-1, -1, -1) then
      FProjectileImpact := FProjectile.CalculateTrajectory(FUnit.GetFiringAccuracy(ActionData.ActionType,
        ActionData.Weapon) / LAccuracyDivider, FOriginVoxel, False)
    else
      FProjectileImpact := FProjectile.CalculateTrajectory(FUnit.GetFiringAccuracy(ActionData.ActionType,
        ActionData.Weapon) / LAccuracyDivider);
    if (FTargetVoxel <> TXcomPosition.Make(-16, -16, -24)) and
      ((FProjectileImpact <> V_EMPTY) or (ActionData.ActionType = BA_LAUNCH)) then
    begin
      // set the soldier in an aiming position
      FUnit.Aim(True);
      FUnit.CacheInvalid := True;
      FGame.View.CacheUnit(FUnit);
      // and we have a lift-off
      if FAmmo.Rules.FireSound <> -1 then
        FGame.View.PlaySound(FAmmo.Rules.FireSound, FProjectile.GetOrigin)
      else if ActionData.Weapon.Rules.FireSound <> -1 then
        FGame.View.PlaySound(ActionData.Weapon.Rules.FireSound, FProjectile.GetOrigin);
      if (not FGame.Save.DebugMode) and (ActionData.ActionType <> BA_LAUNCH) and (not FAmmo.SpendBullet) then
      begin
        FGame.Save.RemoveItem(FAmmo);
        ActionData.Weapon.SetAmmoItem(nil);
      end;
    end
    else
    begin
      // no line of fire
      DestroyProjectile;
      if FGame.PanicHandled then
        ActionData.ResultText := 'STR_NO_LINE_OF_FIRE'
      else
        FUnit.SetTimeUnits(FUnit.TimeUnits + ActionData.TimeUnits); // refund shot TUs for berserking
      FUnit.AbortTurn;
      FGame.PopState;
      Exit(False);
    end;
  end;
  if (ActionData.ActionType <> BA_THROW) and (ActionData.ActionType <> BA_LAUNCH) then
    FUnit.Statistics.ShotsFiredCounter := FUnit.Statistics.ShotsFiredCounter + 1;
  Result := True;
end;

procedure TXcomProjectileFlyState.Think;
var
  LTile: TXcomTile;
  LBelow: TXcomTile;
  LHasFloor: Boolean;
  LUnitCanFly: Boolean;
  LPosition: TXcomPosition;
  LItem: TXcomBattleItem;
  LNext: TXcomProjectileFlyState;
  LOffset: Integer;
  LFiringXp: Integer;
  LPellet: Integer;
  LProjectile: TXcomProjectile;
  LSecondary: Integer;
  LRules: TXcomRuleItem;
  LLastShot: Boolean;
begin
  if not Assigned(FProjectile) then
  begin
    LTile := FGame.Save.TileAt(ActionData.Actor.Position);
    LBelow := FGame.Save.TileAt(ActionData.Actor.Position + TXcomPosition.Make(0, 0, -1));
    LHasFloor := Assigned(LTile) and (not LTile.HasNoFloor(LBelow));
    LUnitCanFly := ActionData.Actor.MovementType = MT_FLY;
    if (ActionData.ActionType = BA_AUTOSHOT) and (ActionData.AutoShotCounter < ActionData.Weapon.Rules.AutoShots) and
      (not ActionData.Actor.IsOut) and (FAmmo.AmmoQuantity <> 0) and (LHasFloor or LUnitCanFly) then
      CreateNewProjectile
    else
    begin
      if (not FGame.Save.UnitsFalling) and FGame.PanicHandled then
        FGame.CheckReactionFire(FUnit);
      if not FUnit.IsOut then
        FUnit.AbortTurn;
      if (FGame.Save.Side = FACTION_PLAYER) or FGame.Save.DebugMode then
        FGame.SetupCursor;
      FGame.ConvertInfected;
      FGame.PopState;
    end;
  end
  else
  begin
    if (ActionData.ActionType <> BA_THROW) and Assigned(FAmmo) and (FAmmo.Rules.ShotgunPellets <> 0) then
      // shotgun pellets move to their terminal location instantly as fast as possible
      FProjectile.SkipTrajectory;
    if not FProjectile.Move then
    begin
      // impact !
      if ActionData.ActionType = BA_THROW then
      begin
        LPosition := FProjectile.GetPosition(ITEM_DROP_VOXEL_OFFSET);
        LPosition := TXcomPosition.Make(LPosition.X div 16, LPosition.Y div 16, LPosition.Z div 24);
        if LPosition.Y > FGame.Save.MapSizeY then
          LPosition := LPosition - TXcomPosition.Make(0, 1, 0);
        if LPosition.X > FGame.Save.MapSizeX then
          LPosition := LPosition - TXcomPosition.Make(1, 0, 0);
        LItem := FProjectile.Item;
        FGame.View.PlaySound(FGame.Ruleset.Constants.ItemDrop, LPosition);
        if FGame.Options.BattleInstantGrenade and (LItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE) and
          (LItem.FuseTimer = 0) then
          // it's a hot grenade to explode immediately
          FGame.StatePushFront(TXcomExplosionState.Create(FGame, FProjectile.GetPosition(ITEM_DROP_VOXEL_OFFSET),
            LItem, ActionData.Actor, nil))
        else
        begin
          FGame.DropItem(LPosition, LItem);
          if (FUnit.Faction <> FACTION_PLAYER) and (FProjectileItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE) then
            FGame.TileEngine.SetDangerZone(LPosition, LItem.Rules.ExplosionRadius, ActionData.Actor);
        end;
      end
      else if (ActionData.ActionType = BA_LAUNCH) and (ActionData.Waypoints.Count > 1) and
        (FProjectileImpact = V_EMPTY) then
      begin
        FOrigin := ActionData.Waypoints[0];
        ActionData.Waypoints.Delete(0);
        ActionData.Target := ActionData.Waypoints[0];
        // launch the next projectile in the waypoint cascade
        LNext := TXcomProjectileFlyState.Create(FGame, ActionData, FOrigin);
        LNext.SetOriginVoxel(FProjectile.GetPosition(-1));
        if FOrigin = ActionData.Target then
          LNext.TargetFloor;
        FGame.StatePushNext(LNext);
      end
      else
      begin
        if Assigned(FGame.Save.TileAt(ActionData.Target).CurrentUnit) then
          // Only counts for guns, not throws or launches
          FGame.Save.TileAt(ActionData.Target).CurrentUnit.Statistics.ShotAtCounter :=
            FGame.Save.TileAt(ActionData.Target).CurrentUnit.Statistics.ShotAtCounter + 1;
        if Assigned(FAmmo) and (ActionData.ActionType = BA_LAUNCH) and (not FAmmo.SpendBullet) then
        begin
          FGame.Save.RemoveItem(FAmmo);
          ActionData.Weapon.SetAmmoItem(nil);
        end;
        if FProjectileImpact <> V_OUTOFBOUNDS then
        begin
          LOffset := 0;
          // explosions impact not inside the voxel but two steps back (projectiles generally move 2 voxels at a time)
          if Assigned(FAmmo) and (FAmmo.Rules.ExplosionRadius <> 0) and (FProjectileImpact <> V_UNIT) then
            LOffset := -2;
          LLastShot := (ActionData.ActionType <> BA_AUTOSHOT) or
            (ActionData.AutoShotCounter = ActionData.Weapon.Rules.AutoShots) or
            (not Assigned(ActionData.Weapon.AmmoItem));
          FGame.StatePushFront(TXcomExplosionState.Create(FGame, FProjectile.GetPosition(LOffset), FAmmo,
            ActionData.Actor, nil, LLastShot));
          if FProjectileImpact = V_UNIT then
            ProjectileHitUnit(FProjectile.GetPosition(LOffset));
          LFiringXp := FUnit.FiringXp;
          // special shotgun behaviour: trace extra projectile paths, and add bullet hits at their termination points.
          if Assigned(FAmmo) and (FAmmo.Rules.ShotgunPellets <> 0) then
          begin
            LPellet := 1;
            while LPellet <> FAmmo.Rules.ShotgunPellets do
            begin
              // create a projectile, let it trace to the point where it hits
              LProjectile := TXcomProjectile.Create(FGame.Save, FGame.TileEngine, FGame, ProjectileOptions, ActionData,
                FOrigin, FTargetVoxel, FAmmo, TXcomViewVapor.Create(FGame.View));
              try
                LSecondary := LProjectile.CalculateTrajectory(Max(0.0, (FUnit.GetFiringAccuracy(ActionData.ActionType,
                  ActionData.Weapon) / 100.0) - LPellet * 5.0));
                if LSecondary <> V_EMPTY then
                begin
                  // as above: skip the shot to the end of it's path
                  LProjectile.SkipTrajectory;
                  // insert an explosion and hit
                  if LSecondary <> V_OUTOFBOUNDS then
                  begin
                    if LSecondary = V_UNIT then
                      ProjectileHitUnit(LProjectile.GetPosition(LOffset));
                    FGame.View.AddExplosion(LProjectile.GetPosition(LOffset), FAmmo.Rules.HitAnimation, 0, False, False);
                    LRules := FAmmo.Rules;
                    if LRules.ExplosionRadius <> 0 then
                      FGame.TileEngine.Explode(LProjectile.GetPosition(LOffset), LRules.Power, LRules.DamageType,
                        LRules.ExplosionRadius, FUnit)
                    else
                      FGame.TileEngine.Hit(LProjectile.GetPosition(LOffset), LRules.Power, LRules.DamageType, FUnit);
                  end;
                end;
              finally
                LProjectile.Free;
              end;
              Inc(LPellet);
            end;
          end;
          if FUnit.FiringXp > LFiringXp + 1 then
            FUnit.NerfFiringXp(LFiringXp + 1);
        end
        else if (ActionData.ActionType <> BA_AUTOSHOT) or
          (ActionData.AutoShotCounter = ActionData.Weapon.Rules.AutoShots) or
          (not Assigned(ActionData.Weapon.AmmoItem)) then
        begin
          FUnit.Aim(False);
          FUnit.CacheInvalid := True;
          FGame.View.CacheUnits;
        end;
      end;
      DestroyProjectile;
    end;
  end;
end;

procedure TXcomProjectileFlyState.Cancel;
begin
  if Assigned(FProjectile) then
    FProjectile.SkipTrajectory;
end;

procedure TXcomProjectileFlyState.ProjectileHitUnit(const APosition: TXcomPosition);
var
  LVictim: TXcomBattleUnit;
  LTargetVictim: TXcomBattleUnit;
  LDistanceSq: Integer;
  LDistance: Integer;
  LAccuracy: Integer;
  LSingle: Single;
  LRules: TXcomRuleItem;
  LUpperLimit: Integer;
  LLowerLimit: Integer;
begin
  LVictim := FGame.Save.TileAt(APosition div TXcomPosition.Make(16, 16, 24)).CurrentUnit;
  LTargetVictim := FGame.Save.TileAt(ActionData.Target).CurrentUnit; // Who we were aiming at (not necessarily who we hit)
  if Assigned(LVictim) and (not LVictim.IsOut) then
  begin
    LVictim.Statistics.HitCounter := LVictim.Statistics.HitCounter + 1;
    if (FUnit.OriginalFaction = FACTION_PLAYER) and (LVictim.OriginalFaction = FACTION_PLAYER) then
    begin
      LVictim.Statistics.ShotByFriendlyCounter := LVictim.Statistics.ShotByFriendlyCounter + 1;
      FUnit.Statistics.ShotFriendlyCounter := FUnit.Statistics.ShotFriendlyCounter + 1;
    end;
    if LVictim = LTargetVictim then // Hit our target
    begin
      LDistanceSq := FGame.TileEngine.DistanceUnitToPositionSq(ActionData.Actor, LVictim.Position, False);
      LSingle := LDistanceSq;
      LSingle := Sqrt(LSingle);
      LDistance := Ceil(LSingle);
      LAccuracy := FUnit.GetFiringAccuracy(ActionData.ActionType, ActionData.Weapon);
      // code from Map::drawTerrain(), where the crosshair accuracy is calculated
      if FGame.Options.UfoExtenderAccuracy then
      begin
        LRules := ActionData.Weapon.Rules;
        LUpperLimit := LRules.AimRange;
        LLowerLimit := LRules.MinRange;
        if ActionData.ActionType = BA_AUTOSHOT then
          LUpperLimit := LRules.AutoRange
        else if ActionData.ActionType = BA_SNAPSHOT then
          LUpperLimit := LRules.SnapRange;
        if LDistance > LUpperLimit then
          Dec(LAccuracy, (LDistance - LUpperLimit) * LRules.Dropoff)
        else if LDistance < LLowerLimit then
          Dec(LAccuracy, (LLowerLimit - LDistance) * LRules.Dropoff);
        if LAccuracy < 0 then
          LAccuracy := 0;
      end;
      FUnit.Statistics.ShotsLandedCounter := FUnit.Statistics.ShotsLandedCounter + 1;
      if LDistance > 30 then
        FUnit.Statistics.LongDistanceHitCounter := FUnit.Statistics.LongDistanceHitCounter + 1;
      if LAccuracy < LDistance then
        FUnit.Statistics.LowAccuracyHitCounter := FUnit.Statistics.LowAccuracyHitCounter + 1;
    end;
    if LVictim.Faction = FACTION_HOSTILE then
      if Assigned(LVictim.AI) then
      begin
        (LVictim.AI as TXcomAIModule).SetWasHitBy(FUnit);
        FUnit.TurnsSinceSpotted := 0;
      end;
    // Record the last unit to hit our victim. If a victim dies without warning (a fire, bled out), this unit gets the credit.
    LVictim.MurdererId := FUnit.Id;
    if Assigned(ActionData.Weapon) then
      LVictim.MurdererWeapon := ActionData.Weapon.Rules.Name;
    if Assigned(FAmmo) then
      LVictim.MurdererWeaponAmmo := FAmmo.Rules.Name;
  end;
end;

end.
