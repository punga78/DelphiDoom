{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a psionic attack (PsiAttackBState)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.PsiAttackState;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.StateBase,
  DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step of a panic or mind control attack: it checks the action, pushes a cosmetic explosion, and when it
  ///   is over compares the psionic strength of the attacker (less the distance, plus a random 0..55) with the
  ///   defense of the target
  /// </summary>
  TXcomPsiAttackState = class(TXcomBattleStateBase)
  strict private
    FUnit: TXcomBattleUnit;
    FTarget: TXcomBattleUnit;
    FItem: TXcomBattleItem;
    FInitialized: Boolean;
    procedure PsiAttack;
    procedure AwardSuccess(const AKill: TXcomBattleUnitKills);
  public
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
    procedure Init; override;
    procedure Think; override;
    function StateName: string; override;
  end;

implementation

uses
  DelphiDoom.XcomBattle.ExplosionState, DelphiDoom.XcomBattle.KillStatistics;

constructor TXcomPsiAttackState.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
begin
  inherited Create(AGame, AAction);
end;

function TXcomPsiAttackState.StateName: string;
begin
  Result := 'PsiAttackBState';
end;

procedure TXcomPsiAttackState.Init;
var
  LTile: TXcomTile;
  LHeight: Integer;
  LVoxel: TXcomPosition;
begin
  if FInitialized then
    Exit;
  FInitialized := True;
  FItem := ActionData.Weapon;
  FUnit := ActionData.Actor;
  LTile := FGame.Save.TileAt(ActionData.Target);
  if not Assigned(LTile) then
  begin
    // invalid target position
    FGame.PopState;
    Exit;
  end;
  if FUnit.TimeUnits < ActionData.TimeUnits then
  begin
    // not enough time units
    ActionData.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    FGame.PopState;
    Exit;
  end;
  FTarget := LTile.CurrentUnit;
  if not Assigned(FTarget) then
  begin
    // invalid target
    FGame.PopState;
    Exit;
  end;
  if not Assigned(FItem) then
  begin
    // can't make a psi attack without a weapon
    FGame.PopState;
    Exit;
  end
  else if FItem.Rules.HitSound <> -1 then
    FGame.View.PlaySound(FItem.Rules.HitSound, ActionData.Target);
  // make a cosmetic explosion
  LHeight := FTarget.FloatHeight + (FTarget.GetHeight div 2) - LTile.GetTerrainLevel;
  LVoxel := ActionData.Target * TXcomPosition.Make(16, 16, 24) + TXcomPosition.Make(8, 8, LHeight);
  FGame.StatePushFront(TXcomExplosionState.Create(FGame, LVoxel, FItem, FUnit, nil, False, True));
end;

procedure TXcomPsiAttackState.Think;
begin
  // after the explosion animation is done: make the actual psi attack, and restore the camera and the cursor
  PsiAttack;
  if ActionData.CameraPosition.Z <> -1 then
    FGame.View.CenterOnPosition(ActionData.CameraPosition, False);
  if (FGame.Save.Side = FACTION_PLAYER) or FGame.Save.DebugMode then
    FGame.SetupCursor;
  FGame.PopState;
end;

procedure TXcomPsiAttackState.AwardSuccess(const AKill: TXcomBattleUnitKills);
begin
  // an attack is rewarded once for each target
  if not FUnit.Statistics.DuplicateEntry(AKill.Status, FTarget.Id) then
    FUnit.Statistics.Kills.Add(TXcomKillStatistics.Copy(AKill));
end;

procedure TXcomPsiAttackState.PsiAttack;
var
  LAttackStrength: Double;
  LDefenseStrength: Double;
  LDistance: Double;
  LKill: TXcomBattleUnitKills;
  LMoraleLoss: Integer;
begin
  LAttackStrength := FUnit.Stats.PsiStrength * FUnit.Stats.PsiSkill / 50.0;
  if FTarget.Stats.PsiSkill > 0 then
    LDefenseStrength := FTarget.Stats.PsiStrength + (10.0 + FTarget.Stats.PsiSkill / 5.0)
  else
    LDefenseStrength := FTarget.Stats.PsiStrength + 10.0;
  LDistance := FGame.TileEngine.Distance(FUnit.Position, ActionData.Target);
  LAttackStrength := LAttackStrength - LDistance;
  LAttackStrength := LAttackStrength + FGame.Save.Random.Generate(0, 55);
  if ActionData.ActionType = BA_MINDCONTROL then
    LDefenseStrength := LDefenseStrength + 20;
  FUnit.AddPsiSkillExp;
  if FGame.Options.AllowPsiStrengthImprovement then
    FTarget.AddPsiStrengthExp;
  if LAttackStrength > LDefenseStrength then
  begin
    ActionData.Actor.AddPsiSkillExp;
    ActionData.Actor.AddPsiSkillExp;
    LKill := TXcomBattleUnitKills.Create;
    try
      TXcomKillStatistics.Fill(LKill, FTarget);
      LKill.SetTurn(FGame.Save.Turn, FGame.Save.Side);
      LKill.Weapon := ActionData.Weapon.Rules.Name;
      // psi weapons got no ammo, just filling up the field
      LKill.WeaponAmmo := ActionData.Weapon.Rules.Name;
      LKill.Faction := FTarget.Faction;
      LKill.Mission := FGame.GetMissionCount;
      LKill.Id := FTarget.Id;
      if ActionData.ActionType = BA_PANIC then
      begin
        LMoraleLoss := 110 - FTarget.Stats.Bravery;
        if LMoraleLoss > 0 then
          FTarget.MoraleChange(-LMoraleLoss);
        FTarget.MindControllerId := FUnit.Id;
        // award panic battle unit kill
        LKill.Status := STATUS_PANICKING;
        AwardSuccess(LKill);
        if FGame.Save.Side = FACTION_PLAYER then
          FGame.View.ShowUnitMessage(nil, 'STR_MORALE_ATTACK_SUCCESSFUL', False);
      end
      else if ActionData.ActionType = BA_MINDCONTROL then
      begin
        // award mind control battle unit kill
        LKill.Status := STATUS_TURNING;
        AwardSuccess(LKill);
        FTarget.MindControllerId := FUnit.Id;
        FTarget.ConvertToFaction(FUnit.Faction);
        FGame.TileEngine.CalculateFovAt(FTarget.Position);
        FGame.TileEngine.CalculateUnitLighting;
        FTarget.RecoverTimeUnits;
        FTarget.DontReselect := False;
        FTarget.AbortTurn;
        // if all units from either faction are mind controlled - auto-end the mission
        if FGame.Save.Side = FACTION_PLAYER then
        begin
          if FGame.Options.AllowPsionicCapture then
            FGame.AutoEndBattle;
          FGame.View.ShowUnitMessage(nil, 'STR_MIND_CONTROL_SUCCESSFUL', False);
          FGame.View.UpdateSoldierInfo;
        end
        else
          // a little infobox with the name of the unit and "... is under alien control"
          FGame.View.ShowUnitMessage(FTarget, 'STR_IS_UNDER_ALIEN_CONTROL', False);
      end;
    finally
      LKill.Free;
    end;
  end
  else if FGame.Options.AllowPsiStrengthImprovement then
    FTarget.AddPsiStrengthExp;
end;

end.
