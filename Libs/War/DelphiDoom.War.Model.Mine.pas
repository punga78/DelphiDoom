{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - taking gold from a mine                           }
{                                                                              }
{  Port of war1 (acoto87/war1), mine() of war_entities.c, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Mine;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.StateMachine;

type
  TWarMine = class
  public
    /// <summary>
    ///   mine: takes at most AAmount of gold from the mine (the slot of its entity) and returns what it took. When
    ///   the mine is empty it collapses (a request of the lifecycle, so that nothing can stop it) and the sound of the
    ///   collapse is told to the game, once: not if it already collapses or is going to
    /// </summary>
    class function Take(AMachine: TWarStateMachine; ASlot, AAmount: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.UnitGeometry;

{ TWarMine }

class function TWarMine.Take(AMachine: TWarStateMachine; ASlot, AAmount: Integer): Integer;
var
  LEntity: PWarEntity;
  LCollapse: PWarStateBase;
begin
  LEntity := AMachine.Context.Pool.Slots[ASlot];
  if LEntity^.UnitData.Amount < AAmount then
    AAmount := LEntity^.UnitData.Amount;
  LEntity^.UnitData.Amount := LEntity^.UnitData.Amount - AAmount;
  if LEntity^.UnitData.Amount < 0 then
    LEntity^.UnitData.Amount := 0;
  if LEntity^.UnitData.Amount = 0 then
    if not AMachine.IsCollapsing(ASlot) and not AMachine.IsGoingToCollapse(ASlot) then
    begin
      LCollapse := AMachine.CreateCollapse(ASlot);
      AMachine.ResetState(ASlot, LCollapse, WAR_CAUSE_LIFECYCLE);
      AMachine.Context.Events.BuildingCollapsing(LEntity^.Id, LEntity^.UnitData.UnitType,
        TWarUnitGeometry.CenterPosition(LEntity));
    end;
  Result := AAmount;
end;

end.
