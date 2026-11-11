{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a unit that walks along a path        }
{  (UnitWalkBState)                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitWalkState;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.StateBase, DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step in which a unit walks along the path that Pathfinding calculated: it turns, opens doors, spends
  ///   time units and energy, moves from tile to tile one phase per tick, and stops when it sees a new unit, is
  ///   shot at by reaction fire or falls. The sprites and the camera are the business of the view
  /// </summary>
  TXcomUnitWalkState = class(TXcomBattleStateBase)
  strict private
    FUnit: TXcomBattleUnit;
    FFalling: Boolean;
    FBeforeFirstStep: Boolean;
    FNumUnitsSpotted: Integer;
    FPreMovementCost: Integer;
    procedure PostPathProcedures;
    procedure SetNormalWalkSpeed;
    procedure PlayMovementSound;
  public
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
    procedure Init; override;
    procedure Think; override;
    procedure Cancel; override;
    function StateName: string; override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.UnitFallState;

const
  SNotPorted = 'Not ported yet: %s';

constructor TXcomUnitWalkState.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
begin
  inherited Create(AGame, AAction);
end;

function TXcomUnitWalkState.StateName: string;
begin
  Result := 'UnitWalkBState';
end;

procedure TXcomUnitWalkState.SetNormalWalkSpeed;
begin
  if FUnit.Faction = FACTION_PLAYER then
    FGame.View.SetStateInterval(FGame.Options.BattleXcomSpeed)
  else
    FGame.View.SetStateInterval(FGame.Options.BattleAlienSpeed);
end;

procedure TXcomUnitWalkState.Init;
var
  LDirection: Integer;
begin
  FUnit := ActionData.Actor;
  FNumUnitsSpotted := FUnit.UnitsSpottedThisTurn.Count;
  SetNormalWalkSpeed;
  LDirection := FGame.Pathfinding.GetStartDirection;
  if (not ActionData.Strafe) and (LDirection <> -1) and (LDirection <> FUnit.Direction) then
    FBeforeFirstStep := True;
end;

procedure TXcomUnitWalkState.Cancel;
begin
  if (FGame.Save.Side = FACTION_PLAYER) and FGame.PanicHandled then
    FGame.Pathfinding.AbortPath;
end;

procedure TXcomUnitWalkState.PlayMovementSound;
var
  LTile: TXcomTile;
  LBelow: TXcomTile;
  LSize: Integer;
  LFootstep: Integer;
begin
  LSize := FUnit.Armor.Size - 1;
  if ((not FUnit.Visible) and (not FGame.Save.DebugMode)) or
    (not FGame.View.IsOnScreen(FUnit.Position, True, LSize, False)) then
    Exit;
  if FUnit.MoveSound <> -1 then
  begin
    // if a sound is configured in the ruleset, play that one
    if FUnit.WalkingPhase = 0 then
      FGame.View.PlaySound(FUnit.MoveSound, FUnit.Position);
  end
  else if FUnit.Status = STATUS_WALKING then
  begin
    LTile := FUnit.Tile;
    LBelow := FGame.Save.TileAt(LTile.Position + TXcomPosition.Make(0, 0, -1));
    LFootstep := LTile.GetFootstepSound(LBelow);
    // play footstep sound 1 and 2
    if (FUnit.WalkingPhase = 3) and (LFootstep > -1) then
      FGame.View.PlaySound(FGame.Ruleset.Constants.WalkOffset + LFootstep * 2, FUnit.Position);
    if (FUnit.WalkingPhase = 7) and (LFootstep > -1) then
      FGame.View.PlaySound(1 + FGame.Ruleset.Constants.WalkOffset + LFootstep * 2, FUnit.Position);
  end
  else if FUnit.MovementType = MT_FLY then
    // play default flying sound
    if (FUnit.WalkingPhase = 1) and (not FFalling) then
      FGame.View.PlaySound(FGame.Ruleset.Constants.FlyingSound, FUnit.Position);
end;

procedure TXcomUnitWalkState.PostPathProcedures;
var
  LDirection: Integer;
begin
  ActionData.TimeUnits := 0;
  if FUnit.Faction <> FACTION_PLAYER then
  begin
    LDirection := ActionData.FinalFacing;
    if ActionData.FinalAction then
      FUnit.DontReselect := True;
    if Assigned(FUnit.Charging) then
    begin
      LDirection := FGame.TileEngine.GetDirectionTo(FUnit.Position, FUnit.Charging.Position);
      if FGame.TileEngine.ValidMeleeRange(FUnit, ActionData.Actor.Charging, LDirection) then
        raise EXcomBattleException.CreateFmt(SNotPorted, ['the melee attack of a charging unit (MeleeAttackBState)']);
    end
    else if FUnit.IsHiding then
    begin
      LDirection := FUnit.Direction + 4;
      FUnit.IsHiding := False;
      FUnit.DontReselect := True;
    end;
    if LDirection <> -1 then
    begin
      if LDirection >= 8 then
        Dec(LDirection, 8);
      FUnit.LookAt(LDirection);
      while FUnit.Status = STATUS_TURNING do
      begin
        FUnit.Turn;
        FGame.TileEngine.CalculateFov(FUnit);
      end;
    end;
  end
  else if not FGame.PanicHandled then
    // todo (C++): set the unit to aggrostate and try to find cover?
    FUnit.SetTimeUnits(0);
  FUnit.CacheInvalid := True;
  FGame.TileEngine.CalculateUnitLighting;
  FGame.TileEngine.CalculateFov(FUnit);
  FGame.View.CacheUnit(FUnit);
  if not FFalling then
    FGame.PopState;
end;

procedure TXcomUnitWalkState.Think;
var
  LUnitSpotted: Boolean;
  LSize: Integer;
  LOnScreen: Boolean;
  LOnScreenBoundary: Boolean;
  LTileBelow: TXcomTile;
  LDestinationTile: TXcomTile;
  LLargeCheck: Boolean;
  LX: Integer;
  LY: Integer;
  LOtherBelow: TXcomTile;
  LPosition: TXcomPosition;
  LVoxel: TXcomPosition;
  LDirection: Integer;
  LDestination: TXcomPosition;
  LTimeUnits: Integer;
  LEnergy: Integer;
  LDoor: Integer;
  LInMyWay: TXcomBattleUnit;
  LBelowMyWay: TXcomBattleUnit;
  LBelowDestination: TXcomTile;
  LScaled: Double;
begin
  LUnitSpotted := False;
  LSize := FUnit.Armor.Size - 1;
  LOnScreen := FUnit.Visible and FGame.View.IsOnScreen(FUnit.Position, True, LSize, False);
  if FUnit.IsKneeled then
  begin
    if FGame.Kneel(FUnit) then
    begin
      FUnit.CacheInvalid := True;
      FGame.TileEngine.CalculateFov(FUnit);
      FGame.View.CacheUnit(FUnit);
      Exit;
    end
    else
    begin
      ActionData.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
      FGame.Pathfinding.AbortPath;
      FGame.PopState;
      Exit;
    end;
  end;
  if FUnit.IsOut then
  begin
    FGame.Pathfinding.AbortPath;
    FGame.PopState;
    Exit;
  end;
  if (FUnit.Status = STATUS_WALKING) or (FUnit.Status = STATUS_FLYING) then
  begin
    LTileBelow := FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(0, 0, -1));
    LDestinationTile := FGame.Save.TileAt(FUnit.Destination);
    // next tile must be not occupied
    if (not Assigned(LDestinationTile.CurrentUnit)) or (LDestinationTile.CurrentUnit = FUnit) then
    begin
      LOnScreenBoundary := FUnit.Visible and FGame.View.IsOnScreen(FUnit.Position, True, LSize, True);
      FUnit.KeepWalking(LTileBelow, LOnScreenBoundary); // advances the phase
      PlayMovementSound;
    end
    else if not FFalling then
    begin
      FUnit.LookAt(FUnit.Destination, FUnit.TurretType <> -1); // turn to undiscovered unit
      FGame.Pathfinding.AbortPath;
    end;
    // unit moved from one tile to the other, update the tiles
    if FUnit.Position <> FUnit.LastPosition then
    begin
      LLargeCheck := True;
      for LX := LSize downto 0 do
        for LY := LSize downto 0 do
        begin
          LOtherBelow := FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(LX, LY, -1));
          if (not FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(LX, LY, 0)).HasNoFloor(LOtherBelow)) or
            (FUnit.MovementType = MT_FLY) then
            LLargeCheck := False;
          FGame.Save.TileAt(FUnit.LastPosition + TXcomPosition.Make(LX, LY, 0)).SetUnit(nil);
        end;
      for LX := LSize downto 0 do
        for LY := LSize downto 0 do
          FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(LX, LY, 0)).SetUnit(FUnit,
            FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(LX, LY, -1)));
      FFalling := LLargeCheck and (FUnit.Position.Z <> 0) and FUnit.Tile.HasNoFloor(LTileBelow) and
        (FUnit.MovementType <> MT_FLY) and (FUnit.WalkingPhase = 0);
      if FFalling then
        for LX := LSize downto 0 do
          for LY := LSize downto 0 do
          begin
            LOtherBelow := FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(LX, LY, -1));
            if Assigned(LOtherBelow) and Assigned(LOtherBelow.CurrentUnit) then
            begin
              FFalling := False;
              FGame.Pathfinding.DequeuePath;
              FGame.Save.AddFallingUnit(FUnit);
              FGame.StatePushFront(TXcomUnitFallState.Create(FGame));
              Exit;
            end;
          end;
      if (not FGame.View.IsOnScreen(FUnit.Position, True, LSize, False)) and (FUnit.Faction <> FACTION_PLAYER) and
        FUnit.Visible then
        FGame.View.CenterOnPosition(FUnit.Position);
      // if the unit changed level, camera changes level with
      FGame.View.SetViewLevel(FUnit.Position.Z);
    end;
    // is the step finished?
    if FUnit.Status = STATUS_STANDING then
    begin
      // update the TU display
      FGame.View.UpdateSoldierInfo;
      // if the unit burns floortiles, burn floortiles as long as we're not falling
      if (not FFalling) and ((FUnit.SpecialAbility = SPECAB_BURNFLOOR) or
        (FUnit.SpecialAbility = SPECAB_BURN_AND_EXPLODE)) then
      begin
        FUnit.Tile.Ignite(1);
        LPosition := FUnit.Position;
        LVoxel := (LPosition * TXcomPosition.Make(16, 16, 24)) +
          TXcomPosition.Make(8, 8, -FUnit.Tile.GetTerrainLevel);
        FGame.TileEngine.Hit(LVoxel, FUnit.Stats.Strength, TXcomRuleItem.DT_IN, FUnit);
        if FUnit.Status <> STATUS_STANDING then // ie: we burned a hole in the floor and fell through it
        begin
          FGame.Pathfinding.AbortPath;
          Exit;
        end;
      end;
      // move our personal lighting with us
      FGame.TileEngine.CalculateUnitLighting;
      if FUnit.Faction <> FACTION_PLAYER then
        FUnit.Visible := False;
      FGame.TileEngine.CalculateFovAt(FUnit.Position);
      LUnitSpotted := (not FFalling) and (not ActionData.Desperate) and FGame.PanicHandled and
        (FNumUnitsSpotted <> FUnit.UnitsSpottedThisTurn.Count);
      if FGame.CheckForProximityGrenades(FUnit) then
      begin
        FGame.PopState;
        Exit;
      end;
      if LUnitSpotted then
      begin
        FUnit.CacheInvalid := True;
        FGame.View.CacheUnit(FUnit);
        FGame.Pathfinding.AbortPath;
        FGame.PopState;
        Exit;
      end;
      // check for reaction fire
      if not FFalling then
        if FGame.CheckReactionFire(FUnit) then
        begin
          // unit got fired upon - stop walking
          FUnit.CacheInvalid := True;
          FGame.View.CacheUnit(FUnit);
          FGame.Pathfinding.AbortPath;
          FGame.PopState;
          Exit;
        end;
    end
    else if LOnScreen then
      FGame.View.CacheUnit(FUnit);
  end;
  // we are just standing around, shouldn't we be walking?
  if (FUnit.Status = STATUS_STANDING) or (FUnit.Status = STATUS_PANICKING) then
  begin
    // check if we did spot new units
    if LUnitSpotted and (not ActionData.Desperate) and (not Assigned(FUnit.Charging)) and (not FFalling) then
    begin
      FUnit.IsHiding := False; // clearly we're not hidden now
      FGame.View.CacheUnit(FUnit);
      PostPathProcedures;
      Exit;
    end;
    if LOnScreen or FGame.Save.DebugMode then
      SetNormalWalkSpeed
    else
      FGame.View.SetStateInterval(0);
    LDirection := FGame.Pathfinding.GetStartDirection;
    if FFalling then
      LDirection := DIR_DOWN;
    if LDirection <> -1 then
    begin
      // gets tu cost, but also gets the destination position.
      LTimeUnits := FGame.Pathfinding.GetTuCost(FUnit.Position, LDirection, LDestination, FUnit, nil, False);
      if (FUnit.Faction <> FACTION_PLAYER) and (FUnit.SpecialAbility < SPECAB_BURNFLOOR) and
        Assigned(FGame.Save.TileAt(LDestination)) and (FGame.Save.TileAt(LDestination).Fire > 0) then
        Dec(LTimeUnits, 32); // we artificially inflate the TU cost by 32 points in getTUCost under these conditions
      if FFalling then
        LTimeUnits := 0;
      LEnergy := LTimeUnits;
      if LDirection >= DIR_UP then
        LEnergy := 0
      else if ActionData.Run then
      begin
        LScaled := LTimeUnits * 0.75;
        LTimeUnits := Trunc(LScaled);
        LScaled := LEnergy * 1.5;
        LEnergy := Trunc(LScaled);
      end;
      if LTimeUnits > FUnit.TimeUnits then
      begin
        if FGame.PanicHandled and (LTimeUnits < 255) then
          ActionData.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
        FGame.Pathfinding.AbortPath;
        FUnit.CacheInvalid := True;
        FGame.View.CacheUnit(FUnit);
        FGame.PopState;
        Exit;
      end;
      if LEnergy div 2 > FUnit.Energy then
      begin
        if FGame.PanicHandled then
          ActionData.ResultText := 'STR_NOT_ENOUGH_ENERGY';
        FGame.Pathfinding.AbortPath;
        FUnit.CacheInvalid := True;
        FGame.View.CacheUnit(FUnit);
        FGame.PopState;
        Exit;
      end;
      if FGame.PanicHandled and (not FGame.CheckReservedTu(FUnit, LTimeUnits)) then
      begin
        FGame.Pathfinding.AbortPath;
        FUnit.CacheInvalid := True;
        FGame.View.CacheUnit(FUnit);
        Exit;
      end;
      // we are looking in the wrong way, turn first (unless strafing)
      // we are not using the turn state, because turning during walking costs no tu
      if (LDirection <> FUnit.Direction) and (LDirection < DIR_UP) then
      begin
        FUnit.LookAt(LDirection);
        FUnit.CacheInvalid := True;
        FGame.View.CacheUnit(FUnit);
        Exit;
      end;
      // now open doors (if any)
      if LDirection < DIR_UP then
      begin
        LDoor := FGame.TileEngine.UnitOpensDoor(FUnit, False, LDirection);
        if LDoor = 3 then
          Exit; // don't start walking yet, wait for the ufo door to open
        if LDoor = 0 then
          FGame.View.PlaySound(FGame.Ruleset.Constants.DoorOpen, FUnit.Position); // normal door
        if LDoor = 1 then
        begin
          FGame.View.PlaySound(FGame.Ruleset.Constants.SlidingDoorOpen, FUnit.Position); // ufo door
          Exit; // don't start walking yet, wait for the ufo door to open
        end;
      end;
      for LX := LSize downto 0 do
        for LY := LSize downto 0 do
        begin
          LInMyWay := FGame.Save.TileAt(LDestination + TXcomPosition.Make(LX, LY, 0)).CurrentUnit;
          LBelowMyWay := nil;
          LBelowDestination := FGame.Save.TileAt(LDestination + TXcomPosition.Make(LX, LY, -1));
          if Assigned(LBelowDestination) then
            LBelowMyWay := LBelowDestination.CurrentUnit;
          // can't walk into units in this tile, or on top of other units sticking their head into this tile
          if (not FFalling) and ((Assigned(LInMyWay) and (LInMyWay <> FUnit)) or
            (Assigned(LBelowDestination) and Assigned(LBelowMyWay) and (LBelowMyWay <> FUnit) and
            ((-LBelowDestination.GetTerrainLevel + LBelowMyWay.FloatHeight + LBelowMyWay.GetHeight) >= 28))) then
          begin
            // 4+ voxels poking into the tile above, we don't kick people in the head here at XCom.
            ActionData.TimeUnits := 0;
            FGame.Pathfinding.AbortPath;
            FUnit.CacheInvalid := True;
            FGame.View.CacheUnit(FUnit);
            FGame.PopState;
            Exit;
          end;
        end;
      // now start moving
      LDirection := FGame.Pathfinding.DequeuePath;
      if FFalling then
        LDirection := DIR_DOWN;
      if FUnit.SpendTimeUnits(LTimeUnits) then
        if FUnit.SpendEnergy(LEnergy) then
        begin
          LTileBelow := FGame.Save.TileAt(FUnit.Position + TXcomPosition.Make(0, 0, -1));
          FUnit.StartWalking(LDirection, LDestination, LTileBelow, LOnScreen);
          FBeforeFirstStep := False;
        end;
      // make sure the unit sprites are up to date
      if LOnScreen then
        FGame.View.CacheUnit(FUnit);
    end
    else
    begin
      PostPathProcedures;
      Exit;
    end;
  end;
  // turning during walking costs no tu
  if FUnit.Status = STATUS_TURNING then
  begin
    // except before the first step.
    if FBeforeFirstStep then
      Inc(FPreMovementCost);
    FUnit.Turn;
    // calculateFOV is unreliable for setting the unitSpotted bool, as it can be called from various other places
    FGame.TileEngine.CalculateFov(FUnit);
    LUnitSpotted := (not FFalling) and (not ActionData.Desperate) and FGame.PanicHandled and
      (FNumUnitsSpotted <> FUnit.UnitsSpottedThisTurn.Count);
    // make sure the unit sprites are up to date
    FUnit.CacheInvalid := True;
    FGame.View.CacheUnit(FUnit);
    if LUnitSpotted and (not ActionData.Desperate) and (not Assigned(FUnit.Charging)) and (not FFalling) then
    begin
      if FBeforeFirstStep then
        FUnit.SpendTimeUnits(FPreMovementCost);
      FUnit.IsHiding := False; // not hidden, are we...
      FGame.Pathfinding.AbortPath;
      FUnit.AbortTurn; // revert to a standing state.
      FUnit.CacheInvalid := True;
      FGame.View.CacheUnit(FUnit);
      FGame.PopState;
    end;
  end;
end;

end.
