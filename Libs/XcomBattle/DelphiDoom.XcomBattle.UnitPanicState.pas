{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a unit that panics or goes berserk    }
{  (UnitPanicBState)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitPanicState;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.StateBase, DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step that ends the panic of a unit: a berserk unit fires up to ten times (at the closest enemy it
  ///   sees, or at random), then the unit stands again with no time units left
  /// </summary>
  TXcomUnitPanicState = class(TXcomBattleStateBase)
  strict private
    FUnit: TXcomBattleUnit;
    FShotsFired: Integer;
    FBerserking: Boolean;
    procedure FireBerserk;
  public
    constructor Create(const AGame: IXcomBattlescapeGame; const AUnit: TXcomBattleUnit);
    procedure Init; override;
    procedure Think; override;
    procedure Cancel; override;
    function StateName: string; override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.UnitTurnState, DelphiDoom.XcomBattle.ProjectileFlyState;

constructor TXcomUnitPanicState.Create(const AGame: IXcomBattlescapeGame; const AUnit: TXcomBattleUnit);
begin
  inherited Create(AGame);
  FUnit := AUnit;
  FBerserking := FUnit.Status = STATUS_BERSERK;
  // makes the unit go to status STANDING
  FUnit.AbortTurn;
end;

function TXcomUnitPanicState.StateName: string;
begin
  Result := 'UnitPanicBState';
end;

procedure TXcomUnitPanicState.Init;
begin
end;

procedure TXcomUnitPanicState.Cancel;
begin
  // panicking cannot be cancelled
end;

procedure TXcomUnitPanicState.FireBerserk;
var
  LAction: TXcomBattleAction;
  LDistance: Integer;
  LNewDistance: Integer;
  LVisible: TXcomBattleUnit;
  LTurnCost: Integer;
  LRandomY: Integer;
  LRandomX: Integer;
begin
  Inc(FShotsFired);
  LAction := TXcomBattleAction.Create;
  try
    LAction.Actor := FUnit;
    LAction.Weapon := FUnit.GetMainHandWeapon;
    if Assigned(LAction.Weapon) and
      ((LAction.Weapon.Rules.TimeUnitsSnap <> 0) or (LAction.Weapon.Rules.TimeUnitsAuto <> 0)) and
      FGame.Save.IsItemUsable(LAction.Weapon) then
    begin
      // make autoshots if possible
      if LAction.Weapon.Rules.TimeUnitsAuto <> 0 then
        LAction.ActionType := BA_AUTOSHOT
      else
        LAction.ActionType := BA_SNAPSHOT;
      LAction.TimeUnits := FUnit.GetActionTus(LAction.ActionType, LAction.Weapon);
      if FUnit.TimeUnits >= LAction.TimeUnits then
      begin
        // if we see enemies, shoot at the closest living one
        if FUnit.VisibleUnits.Count > 0 then
        begin
          LDistance := 255;
          for LVisible in FUnit.VisibleUnits do
          begin
            LNewDistance := FGame.TileEngine.Distance(FUnit.Position, LVisible.Position);
            if LNewDistance < LDistance then
            begin
              LAction.Target := LVisible.Position;
              LDistance := LNewDistance;
            end;
          end;
        end
        else
        begin
          // otherwise shoot randomly (the arguments of Position() are evaluated from the last to the first)
          LRandomY := FGame.Save.Random.Generate(-6, 6);
          LRandomX := FGame.Save.Random.Generate(-6, 6);
          LAction.Target := TXcomPosition.Make(FUnit.Position.X + LRandomX, FUnit.Position.Y + LRandomY,
            FUnit.Position.Z);
        end;
        // include the cost for facing our target
        LTurnCost := Abs(FUnit.Direction - FUnit.DirectionTo(LAction.Target));
        if LTurnCost > 4 then
          LTurnCost := 8 - LTurnCost;
        FGame.StatePushFront(TXcomUnitTurnState.Create(FGame, LAction, False));
        // even if we don't have enough time units to turn AND shoot, we still want to turn
        if FUnit.SpendTimeUnits(LAction.TimeUnits + LTurnCost) then
          FGame.StatePushNext(TXcomProjectileFlyState.Create(FGame, LAction))
        else
          FUnit.SpendTimeUnits(LTurnCost);
      end;
    end;
  finally
    LAction.Free;
  end;
end;

procedure TXcomUnitPanicState.Think;
begin
  if Assigned(FUnit) then
  begin
    // berserking requires handling here, as the target selection isn't completely random and needs updating
    // between shots
    if (not FUnit.IsOut) and (FShotsFired < 10) and FBerserking then
    begin
      FireBerserk;
      Exit;
    end;
    if not FUnit.IsOut then
      // set the unit status to standing in case it wasn't otherwise changed from berserk/panicked
      FUnit.AbortTurn;
    // reset the unit's time units when all panicking is done
    FUnit.SetTimeUnits(0);
  end;
  FGame.PopState;
  FGame.SetupCursor;
end;

end.
