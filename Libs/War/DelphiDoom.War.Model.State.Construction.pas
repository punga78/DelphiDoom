{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the states of building and training in the table   }
{                                                                              }
{  Port of war1 (acoto87/war1), the entries of stateDescriptors of war_state_  }
{  machine.c for these states, (c) 2019 Alejandro Coto Gutierrez, zlib         }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Construction;

interface

uses
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The registration of the states of building, repairing, collapsing, training and upgrading in the table of
  ///   descriptors of the state machine, with the hooks that the original has for each (stateDescriptors). The factory
  ///   calls it once
  /// </summary>
  TWarConstructionStates = class
  public
    /// <summary>
    ///   Sets the hooks of collapse, train, upgrade, build, repair and repairing, and takes from the occupancy of the context
    ///   the probe for the free tiles if it can answer (a grid can, the default does not)
    /// </summary>
    class procedure Register(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Construction.Intf,
  DelphiDoom.War.Model.State.Collapse, DelphiDoom.War.Model.State.Train, DelphiDoom.War.Model.State.Upgrade,
  DelphiDoom.War.Model.State.Build, DelphiDoom.War.Model.State.Repair, DelphiDoom.War.Model.State.Repairing;

{ TWarConstructionStates }

class procedure TWarConstructionStates.Register(AMachine: TWarStateMachine);
var
  LProbe: IWarOccupancyProbe;
begin
  AMachine.RegisterHooks(WAR_STATE_COLLAPSE, TWarCollapseState.Enter, nil, TWarCollapseState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_TRAIN, TWarTrainState.Enter, TWarTrainState.Leave, TWarTrainState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_UPGRADE, TWarUpgradeState.Enter, TWarUpgradeState.Leave, TWarUpgradeState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_BUILD, TWarBuildState.Enter, TWarBuildState.Leave, TWarBuildState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_REPAIR, nil, nil, TWarRepairState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_REPAIRING, TWarRepairingState.Enter, TWarRepairingState.Leave,
    TWarRepairingState.UpdateAll);
  if Supports(AMachine.Context.Occupancy, IWarOccupancyProbe, LProbe) then
    AMachine.Context.Probe := LProbe;
end;

end.
