{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - registering the states of the gatherers           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.GatherRegistry;

interface

uses
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   Puts the procedures of the five states of the gatherers (gather gold, mining, gather wood, chopping, deliver) in
  ///   the table of the machine: the one line that the composition root writes for them
  /// </summary>
  TWarGatherRegistry = class
  public
    class procedure RegisterAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.GatherGold, DelphiDoom.War.Model.State.Mining,
  DelphiDoom.War.Model.State.GatherWood, DelphiDoom.War.Model.State.Chopping, DelphiDoom.War.Model.State.Deliver;

{ TWarGatherRegistry }

class procedure TWarGatherRegistry.RegisterAll(AMachine: TWarStateMachine);
begin
  AMachine.RegisterHooks(WAR_STATE_GOLD, nil, nil, TWarGatherGoldState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_MINING, TWarMiningState.Enter, TWarMiningState.Leave, TWarMiningState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_WOOD, nil, nil, TWarGatherWoodState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_CHOPPING, TWarChoppingState.Enter, nil, TWarChoppingState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_DELIVER, nil, nil, TWarDeliverState.UpdateAll);
end;

end.
