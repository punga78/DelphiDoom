{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - units that fall when the floor is     }
{  gone (UnitFallBState)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitFallState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step that makes the units of SavedBattleGame::getFallingUnits() fall one level at a time, squashes or
  ///   moves the units under them (UnitFallBState)
  /// </summary>
  TXcomUnitFallState = class(TInterfacedObject, IXcomBattleState)
  strict private
    FGame: IXcomBattlescapeGame;
    FTilesToFallInto: TList<TXcomTile>;
    FUnitsToMove: TList<TXcomBattleUnit>;
    procedure MoveUnitsOutOfTheWay;
  public
    constructor Create(const AGame: IXcomBattlescapeGame);
    destructor Destroy; override;
    procedure Init;
    procedure Think;
    procedure Cancel;
    procedure Deinit;
    function StateName: string;
    function Action: TXcomBattleAction;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Directions;

constructor TXcomUnitFallState.Create(const AGame: IXcomBattlescapeGame);
begin
  inherited Create;
  FGame := AGame;
  FTilesToFallInto := TList<TXcomTile>.Create;
  FUnitsToMove := TList<TXcomBattleUnit>.Create;
end;

destructor TXcomUnitFallState.Destroy;
begin
  FUnitsToMove.Free;
  FTilesToFallInto.Free;
  inherited Destroy;
end;

function TXcomUnitFallState.Action: TXcomBattleAction;
begin
  Result := nil;
end;

procedure TXcomUnitFallState.Init;
begin
  if FGame.Save.Side = FACTION_PLAYER then
    FGame.View.SetStateInterval(FGame.Options.BattleXcomSpeed)
  else
    FGame.View.SetStateInterval(FGame.Options.BattleAlienSpeed);
end;

procedure TXcomUnitFallState.Think;
var
  LFalling: TList<TXcomBattleUnit>;
  LIndex: Integer;
  LUnit: TXcomBattleUnit;
  LLargeCheck: Boolean;
  LFallingNow: Boolean;
  LSize: Integer;
  LOnScreen: Boolean;
  LTileBelow: TXcomTile;
  LOtherBelow: TXcomTile;
  LX: Integer;
  LY: Integer;
  LTile: TXcomTile;
  LUnitBelow: TXcomBattleUnit;
  LDestination: TXcomPosition;
  LGroundVoxel: TXcomPosition;
begin
  LFalling := FGame.Save.FallingUnits;
  LIndex := 0;
  while LIndex < LFalling.Count do
  begin
    LUnit := LFalling[LIndex];
    if LUnit.Status = STATUS_TURNING then
      LUnit.AbortTurn;
    LLargeCheck := True;
    LSize := LUnit.Armor.Size - 1;
    if (LUnit.Health = 0) or (LUnit.StunLevel >= LUnit.Health) then
    begin
      LFalling.Delete(LIndex);
      Continue;
    end;
    LOnScreen := LUnit.Visible and FGame.View.IsOnScreen(LUnit.Position, True, LSize, False);
    LTileBelow := FGame.Save.TileAt(LUnit.Position + TXcomPosition.Make(0, 0, -1));
    for LX := LSize downto 0 do
      for LY := LSize downto 0 do
      begin
        LOtherBelow := FGame.Save.TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, -1));
        if (not FGame.Save.TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, 0)).HasNoFloor(LOtherBelow)) or
          (LUnit.MovementType = MT_FLY) then
          LLargeCheck := False;
      end;
    if (LUnit.Status = STATUS_WALKING) or (LUnit.Status = STATUS_FLYING) then
    begin
      LUnit.KeepWalking(LTileBelow, True); // advances the phase
      FGame.View.CacheUnit(LUnit);
      if LUnit.Position <> LUnit.LastPosition then
      begin
        // Reset tiles moved from.
        for LX := LSize downto 0 do
          for LY := LSize downto 0 do
          begin
            // A falling unit might have already taken up this position so check that this unit is still here.
            LTile := FGame.Save.TileAt(LUnit.LastPosition + TXcomPosition.Make(LX, LY, 0));
            if LTile.CurrentUnit = LUnit then
              LTile.SetUnit(nil);
          end;
        // Update tiles moved to.
        for LX := LSize downto 0 do
          for LY := LSize downto 0 do
            FGame.Save.TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, 0)).SetUnit(LUnit,
              FGame.Save.TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, -1)));
      end;
      Inc(LIndex);
      Continue;
    end;
    LFallingNow := LLargeCheck and (LUnit.Position.Z <> 0) and LUnit.Tile.HasNoFloor(LTileBelow) and
      (LUnit.MovementType <> MT_FLY) and (LUnit.WalkingPhase = 0);
    if LFallingNow then
    begin
      // Tile(s) unit is falling into.
      for LX := LUnit.Armor.Size - 1 downto 0 do
        for LY := LUnit.Armor.Size - 1 downto 0 do
          FTilesToFallInto.Add(FGame.Save.TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, -1)));
      // Check each tile for units that need moving out of the way.
      for LTile in FTilesToFallInto do
      begin
        LUnitBelow := LTile.CurrentUnit;
        if Assigned(LUnitBelow) and (LFalling.IndexOf(LUnitBelow) < 0) and (FUnitsToMove.IndexOf(LUnitBelow) < 0) then
          FUnitsToMove.Add(LUnitBelow);
      end;
    end;
    // we are just standing around, we are done falling.
    if LUnit.Status = STATUS_STANDING then
    begin
      if LFallingNow then
      begin
        LDestination := LUnit.Position + TXcomPosition.Make(0, 0, -1);
        LUnit.StartWalking(DIR_DOWN, LDestination, FGame.Save.TileAt(LDestination), LOnScreen);
        LUnit.CacheInvalid := True;
        FGame.View.CacheUnit(LUnit);
        Inc(LIndex);
      end
      else
      begin
        // if the unit burns floortiles, burn floortiles
        if (LUnit.SpecialAbility = SPECAB_BURNFLOOR) or (LUnit.SpecialAbility = SPECAB_BURN_AND_EXPLODE) then
        begin
          LUnit.Tile.Ignite(1);
          LGroundVoxel := (LUnit.Position * TXcomPosition.Make(16, 16, 24)) +
            TXcomPosition.Make(8, 8, -LUnit.Tile.GetTerrainLevel);
          FGame.TileEngine.Hit(LGroundVoxel, LUnit.Stats.Strength, TXcomRuleItem.DT_IN, LUnit);
          if LUnit.Status <> STATUS_STANDING then // ie: we burned a hole in the floor and fell through it
            FGame.Pathfinding.AbortPath;
        end;
        // move our personal lighting with us
        FGame.TileEngine.CalculateUnitLighting;
        FGame.View.CacheUnit(LUnit);
        LUnit.CacheInvalid := True;
        FGame.TileEngine.CalculateFov(LUnit);
        FGame.CheckForProximityGrenades(LUnit);
        if LUnit.Status = STATUS_STANDING then
        begin
          if FGame.CheckReactionFire(LUnit) then
            FGame.Pathfinding.AbortPath;
          LFalling.Remove(LUnit);
        end;
      end;
    end
    else
      Inc(LIndex);
  end;
  // Find somewhere to move the unit(s) In danger of being squashed.
  if FUnitsToMove.Count > 0 then
  begin
    MoveUnitsOutOfTheWay;
    FGame.CheckForCasualties(nil, nil);
  end;
  if FGame.Save.FallingUnits.Count = 0 then
  begin
    FTilesToFallInto.Clear;
    FUnitsToMove.Clear;
    FGame.PopState;
  end;
end;

procedure TXcomUnitFallState.MoveUnitsOutOfTheWay;
var
  LEscapeTiles: TList<TXcomTile>;
  LUnitBelow: TXcomBattleUnit;
  LEscapeFound: Boolean;
  LSections: TList<TXcomPosition>;
  LX: Integer;
  LY: Integer;
  LDirection: Integer;
  LOffset: TXcomPosition;
  LDestination: TXcomPosition;
  LSection: Integer;
  LOriginal: TXcomPosition;
  LEnd: TXcomPosition;
  LTile: TXcomTile;
  LBelowTile: TXcomTile;
  LCanMove: Boolean;
  LEscapeTile: TXcomTile;
begin
  LEscapeTiles := TList<TXcomTile>.Create;
  LSections := TList<TXcomPosition>.Create;
  try
    while FUnitsToMove.Count > 0 do
    begin
      LUnitBelow := FUnitsToMove[0];
      LEscapeFound := False;
      // We need to move all sections of the unit out of the way.
      LSections.Clear;
      for LX := LUnitBelow.Armor.Size - 1 downto 0 do
        for LY := LUnitBelow.Armor.Size - 1 downto 0 do
          LSections.Add(LUnitBelow.Position + TXcomPosition.Make(LX, LY, 0));
      // Check in each compass direction.
      LDirection := 0;
      while (LDirection < DIR_UP) and (not LEscapeFound) do
      begin
        LOffset := TXcomDirections.ToVector(LDirection);
        LDestination := LUnitBelow.Position + LOffset;
        if FGame.Pathfinding.GetTuCost(LUnitBelow.Position, LDirection, LDestination, LUnitBelow, nil, False) = 255 then
        begin
          // can't move this way, try another direction
          Inc(LDirection);
          Continue;
        end;
        LSection := 0;
        while LSection < LSections.Count do
        begin
          LOriginal := LSections[LSection];
          LEnd := LOriginal + LOffset;
          LTile := FGame.Save.TileAt(LEnd);
          LBelowTile := FGame.Save.TileAt(LEnd + TXcomPosition.Make(0, 0, -1));
          LCanMove := Assigned(LTile) and
            ((not Assigned(LTile.CurrentUnit)) or (LTile.CurrentUnit = LUnitBelow)) and
            (LEscapeTiles.IndexOf(LTile) < 0) and (FTilesToFallInto.IndexOf(LTile) < 0) and
            ((not LTile.HasNoFloor(LBelowTile)) or (LUnitBelow.MovementType = MT_FLY));
          if LCanMove then
            // Check next section of the unit.
            Inc(LSection)
          else
            // Try next direction.
            Break;
          // If all sections of the fallen onto unit can be moved, then we move it.
          if LSection = LSections.Count then
            if FGame.Save.AddFallingUnit(LUnitBelow) then
            begin
              LEscapeFound := True;
              // Now ensure no other unit escapes to here too.
              for LX := LUnitBelow.Armor.Size - 1 downto 0 do
                for LY := LUnitBelow.Armor.Size - 1 downto 0 do
                begin
                  LEscapeTile := FGame.Save.TileAt(LTile.Position + TXcomPosition.Make(LX, LY, 0));
                  LEscapeTiles.Add(LEscapeTile);
                end;
              LBelowTile := FGame.Save.TileAt(LOriginal + TXcomPosition.Make(0, 0, -1));
              LUnitBelow.StartWalking(LDirection, LUnitBelow.Position + LOffset, LBelowTile,
                LUnitBelow.Visible and FGame.View.IsOnScreen(LUnitBelow.Position, True, LUnitBelow.Armor.Size - 1,
                False));
            end;
        end;
        Inc(LDirection);
      end;
      if not LEscapeFound then
        // STOMP THAT GOOMBA!
        FGame.KnockOut(LUnitBelow);
      FUnitsToMove.Delete(0);
    end;
  finally
    LSections.Free;
    LEscapeTiles.Free;
  end;
end;

procedure TXcomUnitFallState.Cancel;
begin
end;

procedure TXcomUnitFallState.Deinit;
begin
end;

function TXcomUnitFallState.StateName: string;
begin
  Result := 'UnitFallBState';
end;

end.
