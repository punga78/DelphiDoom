{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a unit that turns (UnitTurnBState)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitTurnState;

interface

uses
  System.SysUtils, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattle.StateBase, DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step in which a unit turns towards the target of its action, one direction at a time, spending a time
  ///   unit for each (when it charges them) and looking for new enemies. With no action type it also tries to open
  ///   the door in front of the unit
  /// </summary>
  TXcomUnitTurnState = class(TXcomBattleStateBase)
  strict private
    FUnit: TXcomBattleUnit;
    FTurret: Boolean;
    FChargeTimeUnits: Boolean;
  public
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction;
      AChargeTimeUnits: Boolean = True);
    procedure Init; override;
    procedure Think; override;
    function StateName: string; override;
  end;

implementation

constructor TXcomUnitTurnState.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction;
  AChargeTimeUnits: Boolean);
begin
  inherited Create(AGame, AAction);
  FChargeTimeUnits := AChargeTimeUnits;
end;

procedure TXcomUnitTurnState.Init;
var
  LDoor: Integer;
begin
  FUnit := ActionData.Actor;
  if FUnit.IsOut then
  begin
    FGame.PopState;
    Exit;
  end;
  ActionData.TimeUnits := 0;
  if FUnit.Faction = FACTION_PLAYER then
    FGame.View.SetStateInterval(FGame.Options.BattleXcomSpeed)
  else
    FGame.View.SetStateInterval(FGame.Options.BattleAlienSpeed);
  // if the unit has a turret and we are turning during targeting, then only the turret turns
  FTurret := (FUnit.TurretType <> -1) and (ActionData.Targeting or ActionData.Strafe);
  FUnit.LookAt(ActionData.Target, FTurret);
  if FChargeTimeUnits and (FUnit.Status <> STATUS_TURNING) then
  begin
    if ActionData.ActionType = BA_NONE then
    begin
      // try to open a door
      LDoor := FGame.TileEngine.UnitOpensDoor(FUnit, True);
      if LDoor = 0 then
        FGame.View.PlaySound(FGame.Ruleset.Constants.DoorOpen, FUnit.Position); // normal door
      if LDoor = 1 then
        FGame.View.PlaySound(FGame.Ruleset.Constants.SlidingDoorOpen, FUnit.Position); // ufo door
      if LDoor = 4 then
        ActionData.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    end;
    FGame.PopState;
  end;
end;

procedure TXcomUnitTurnState.Think;
var
  LTimeUnits: Integer;
  LSpotted: Integer;
begin
  if FChargeTimeUnits then
    LTimeUnits := 1
  else
    LTimeUnits := 0;
  if FChargeTimeUnits and (FUnit.Faction = FGame.Save.Side) and FGame.PanicHandled and (not ActionData.Targeting) and
    (not FGame.CheckReservedTu(FUnit, LTimeUnits)) then
  begin
    FUnit.AbortTurn;
    FGame.PopState;
    Exit;
  end;
  if FUnit.SpendTimeUnits(LTimeUnits) then
  begin
    LSpotted := FUnit.UnitsSpottedThisTurn.Count;
    FUnit.Turn(FTurret);
    FGame.TileEngine.CalculateFov(FUnit);
    FUnit.CacheInvalid := True;
    FGame.View.CacheUnit(FUnit);
    if FChargeTimeUnits and (FUnit.Faction = FGame.Save.Side) and FGame.PanicHandled and
      (ActionData.ActionType = BA_NONE) and (FUnit.UnitsSpottedThisTurn.Count > LSpotted) then
      FUnit.AbortTurn;
    if FUnit.Status = STATUS_STANDING then
      FGame.PopState;
  end
  else if FGame.PanicHandled then
  begin
    ActionData.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    FUnit.AbortTurn;
    FGame.PopState;
  end;
end;

function TXcomUnitTurnState.StateName: string;
begin
  Result := 'UnitTurnBState';
end;

end.
