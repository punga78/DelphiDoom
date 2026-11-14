{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - registration of the attack, follow and patrol     }
{  states                                                                      }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Attack.Registration;

interface

uses
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   Gives the model the attack, follow and patrol states and the combat (blows, projectiles, the steps of the actions)
  ///   they need. The events object, if it also supports IWarCombatEvents, hears the sounds and the explosions
  /// </summary>
  TWarAttackRegistration = class
  public
    class procedure Register(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const AEvents: IWarModelEvents); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Combat.Intf, DelphiDoom.War.Model.CombatServices,
  DelphiDoom.War.Model.State.Attack, DelphiDoom.War.Model.State.Follow, DelphiDoom.War.Model.State.Patrol,
  DelphiDoom.War.Model.State.Cast;

{ TWarAttackRegistration }

class procedure TWarAttackRegistration.Register(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const AEvents: IWarModelEvents);
var
  LCombatEvents: IWarCombatEvents;
  LSpellEvents: IWarSpellEvents;
begin
  if Supports(AEvents, IWarCombatEvents, LCombatEvents) then
    AContext.CombatEvents := LCombatEvents;
  if Supports(AEvents, IWarSpellEvents, LSpellEvents) then
    AContext.SpellEvents := LSpellEvents;
  // the spells are blows too: the cast state reads the same step of the attack action and asks the same services
  AMachine.RegisterHooks(WAR_STATE_CAST, nil, nil, TWarCastState.UpdateAll);
  AContext.Combat := TWarCombatServices.Create(AContext, AMachine);
  AMachine.RegisterHooks(WAR_STATE_ATTACK, nil, nil, TWarAttackState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_FOLLOW, nil, nil, TWarFollowState.UpdateAll);
  AMachine.RegisterHooks(WAR_STATE_PATROL, TWarPatrolState.Enter, nil, TWarPatrolState.UpdateAll);
end;

end.
