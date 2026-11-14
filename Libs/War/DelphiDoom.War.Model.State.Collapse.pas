{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the collapse state                                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_collapse.c, (c) 2019         }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Collapse;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A building that has no hit points left: its sprite is hidden (the game plays the animation of the collapse, 17
  ///   frames of a tenth of a second at the speed of the map), its tiles are free, it leaves ruins and nobody can
  ///   select it; when the animation is over the building is removed
  /// </summary>
  TWarCollapseState = class
  public
    /// <summary>wst_createCollapseState</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot: Integer): PWarStateBase; static;
    /// <summary>wst_enterCollapseState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_updateCollapseStates: the removal of the building</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.Construction.Types,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.Animations;

const
  // 0.1f of the original: the float, not the double 0.1
  FRAME_DELAY: Single = 0.1;

{ TWarCollapseState }

class function TWarCollapseState.CreateState(AMachine: TWarStateMachine; ASlot: Integer): PWarStateBase;
begin
  Result := AMachine.CreateCollapse(ASlot);
end;

class procedure TWarCollapseState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LDuration: Single;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  // the animations of damage go away (the game draws them) and the sprite is hidden
  TWarAnimations.Remove(LEntity, WAR_ANIMATION_LITTLE_DAMAGE);
  TWarAnimations.Remove(LEntity, WAR_ANIMATION_HUGE_DAMAGE);
  LEntity^.SpriteEnabled := False;
  TWarAnimations.CreateCollapse(LEntity);
  LContext.Selection.Remove(LEntity^.Id);
  // wanim_getAnimationDuration of the collapse animation: the delay of a frame by the frames
  LDuration := FRAME_DELAY * WAR_COLLAPSE_FRAMES;
  AState^.NextUpdateGameTime := LContext.Clock^.GameTime + TWarModelMath.ScaledTime(LContext.Clock^, LDuration);
  LContext.Ruins.AddSquare(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX);
  LContext.Ruins.DetermineTypes;
  LContext.Occupancy.SetFreeTiles(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY);
  LContext.Events.EntityLeftSelection(LEntity^.Id);
end;

class procedure TWarCollapseState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_COLLAPSE, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_COLLAPSE, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    LContext.Entities.RemoveEntityById(LContext.Pool.Slots[LSlot]^.Id);
  end;
end;

end.
