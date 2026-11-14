{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - creation of the game model                        }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Factory;

interface

uses
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.World;

type
  /// <summary>
  ///   The only place that knows the concrete classes of the model. It registers the states that are ported (idle, move,
  ///   death, wait); the others (attack, patrol, follow, gathering, building, ...) have their records and are created, but
  ///   no procedure updates them yet
  /// </summary>
  TWarModelFactory = class
  public
    /// <summary>
    ///   A model with the given random generator (the original uses SDL_rand, which can not be repeated: give a
    ///   TWarSeededRandom for a game that has to be). The events, the occupation of the tiles and the database are
    ///   optional: without them nobody listens, no tile is occupied and the tables of the game are used
    /// </summary>
    class function CreateWorld(const ARandom: IWarRandom; const AOccupancy: IWarOccupancy = nil;
      const AEvents: IWarModelEvents = nil; const ADatabase: IWarDatabase = nil): TWarModelWorld; static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Database, DelphiDoom.War.Model.NullServices, DelphiDoom.War.Model.UnitQueries,
  DelphiDoom.War.Model.EntityManager, DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Economy,
  DelphiDoom.War.Model.State.Idle, DelphiDoom.War.Model.State.Move, DelphiDoom.War.Model.State.Death,
  DelphiDoom.War.Model.State.Wait, DelphiDoom.War.Model.State.Construction;

{ TWarModelFactory }

class function TWarModelFactory.CreateWorld(const ARandom: IWarRandom; const AOccupancy: IWarOccupancy;
  const AEvents: IWarModelEvents; const ADatabase: IWarDatabase): TWarModelWorld;
var
  LDatabase: IWarDatabase;
  LEvents: IWarModelEvents;
  LOccupancy: IWarOccupancy;
  LContext: TWarModelContext;
  LMachine: TWarStateMachine;
  LQueries: IWarUnitQueries;
  LEntities: IWarEntityManager;
begin
  LDatabase := ADatabase;
  if not Assigned(LDatabase) then
    LDatabase := TWarDatabase.Create;
  LEvents := AEvents;
  if not Assigned(LEvents) then
    LEvents := TWarNullModelEvents.Create;
  LOccupancy := AOccupancy;
  if not Assigned(LOccupancy) then
    LOccupancy := TWarNullOccupancy.Create;
  LContext := TWarModelContext.Create(LDatabase, ARandom, LEvents, LOccupancy);
  LMachine := TWarStateMachine.Create(LContext);
  LQueries := TWarUnitQueries.Create(LContext, LMachine);
  LEntities := TWarEntityManager.Create(LContext, LMachine);
  LContext.Queries := LQueries;
  LContext.Entities := LEntities;
  LMachine.RegisterHooks(WAR_STATE_IDLE, TWarIdleState.Enter, TWarIdleState.Leave, TWarIdleState.UpdateAll);
  LMachine.RegisterHooks(WAR_STATE_MOVE, TWarMoveState.Enter, TWarMoveState.Leave, TWarMoveState.UpdateAll);
  LMachine.RegisterHooks(WAR_STATE_DEATH, TWarDeathState.Enter, nil, TWarDeathState.UpdateAll);
  LMachine.RegisterHooks(WAR_STATE_WAIT, TWarWaitState.Enter, TWarWaitState.Leave, TWarWaitState.UpdateAll);
  TWarConstructionStates.Register(LMachine);
  Result := TWarModelWorld.Create(LContext, LMachine, LQueries, LEntities, TWarCombat.Create(LContext, LMachine),
    TWarEconomy.Create(LContext, LQueries));
end;

end.
