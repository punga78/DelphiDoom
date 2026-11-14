{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the death state                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_death.c, (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Death;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that dies: its tiles are free, it plays its death for as many frames as the animation lasts (at the speed
  ///   of the map), then it is removed; the units that are not a corpse, a catapult, a summoned one or a skeleton leave a
  ///   corpse of their race (of the neutral player, turned as they were), which is removed after its own death
  /// </summary>
  TWarDeathState = class
  public
    /// <summary>wst_enterDeathState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_updateDeathStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionTable,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.StateStorage;

{ TWarDeathState }

class procedure TWarDeathState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LDuration: Integer;
  LSeconds: Single;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetFreeTiles(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY);
  TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_DEATH, True, 1.0);
  LContext.Events.EntityLeftSelection(LEntity^.Id);
  LDuration := TWarActionTable.Duration(LEntity^.UnitData.UnitType, WAR_ACTION_DEATH);
  LSeconds := TWarModelMath.ScaledTime(LContext.Clock^, TWarModelMath.FramesToSeconds(LDuration));
  AState^.NextUpdateGameTime := LContext.Clock^.GameTime + LSeconds;
end;

class procedure TWarDeathState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
  LEntity: PWarEntity;
  LTile: TWarVec2;
  LCorpseType: Integer;
  LCorpse: Integer;
  LDirection: Integer;
  LDeath: PWarStateDeath;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_DEATH, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_DEATH, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    LEntity := LContext.Pool.Slots[LSlot];
    // the time of the death animation has passed
    if not TWarUnitClassifier.IsCorpse(LEntity^.UnitData.UnitType) and
      not TWarUnitClassifier.IsCatapult(LEntity^.UnitData.UnitType) and
      not TWarUnitClassifier.IsSummon(LEntity^.UnitData.UnitType) and
      not TWarUnitClassifier.IsSkeleton(LEntity^.UnitData.UnitType) then
    begin
      LTile := TWarUnitGeometry.CenterTile(LEntity);
      if TWarUnitClassifier.RaceOf(LEntity^.UnitData.UnitType) = wraOrcs then
        LCorpseType := WAR_UNIT_ORC_CORPSE
      else
        LCorpseType := WAR_UNIT_HUMAN_CORPSE;
      LDirection := LEntity^.UnitData.Direction;
      LCorpse := LContext.Entities.CreateUnit(LCorpseType, Trunc(LTile.X), Trunc(LTile.Y), WAR_MODEL_CORPSE_PLAYER,
        wrkNone, 0, True);
      if LCorpse <> 0 then
      begin
        LContext.Pool.Slots[LCorpse]^.UnitData.Direction := LDirection;
        LDeath := AMachine.CreateDeath(LCorpse);
        AMachine.ResetState(LCorpse, PWarStateBase(LDeath), WAR_CAUSE_LIFECYCLE);
      end;
    end;
    LContext.Entities.RemoveEntityById(LEntity^.Id);
  end;
end;

end.
