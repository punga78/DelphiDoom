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
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.Selection, DelphiDoom.War.Model.Commands.Intf, DelphiDoom.War.Model.Commands.Dispatcher;

type
  /// <summary>
  ///   The only place that knows the concrete classes of the model. It registers every state of the original (idle,
  ///   move, patrol, follow, attack, the gathering, death, collapse, train, upgrade, build, repair, cast, wait) and makes
  ///   the commands of who gives orders
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
    /// <summary>
    ///   The commands of the player of the original: the selection of the context of the world, the player 0,
    ///   WAR_CAUSE_PLAYER_ORDER. The map tells who stands on a tile and what the player sees (TWarGridCommandMap over the
    ///   grid of the game map); nil and the orders on a point find nobody there. The caller frees it before the world
    /// </summary>
    class function CreateCommands(const AWorld: TWarModelWorld; const AMap: IWarCommandMap = nil): TWarCommands; static;
    /// <summary>
    ///   The commands of a computer player (issue #196): the same orders, given to its own selection (not owned) for its
    ///   player with WAR_CAUSE_AI_ORDER
    /// </summary>
    class function CreateComputerCommands(const AWorld: TWarModelWorld; const ASelection: TWarSelection;
      APlayer: Integer; const AMap: IWarCommandMap = nil): TWarCommands; static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Database, DelphiDoom.War.Model.NullServices, DelphiDoom.War.Model.UnitQueries,
  DelphiDoom.War.Model.EntityManager, DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Economy,
  DelphiDoom.War.Model.State.Idle, DelphiDoom.War.Model.State.Move, DelphiDoom.War.Model.State.Death,
  DelphiDoom.War.Model.State.Wait, DelphiDoom.War.Model.State.Attack.Registration,
  DelphiDoom.War.Model.State.GatherRegistry, DelphiDoom.War.Model.State.Construction,
  DelphiDoom.War.Model.Commands.Family;

{ TWarModelFactory }

class function TWarModelFactory.CreateCommands(const AWorld: TWarModelWorld; const AMap: IWarCommandMap): TWarCommands;
begin
  Result := TWarCommands.Create(AWorld.Context, AWorld.Machine, AWorld.Economy, TWarCommander.Human(AWorld.Context),
    AMap);
end;

class function TWarModelFactory.CreateComputerCommands(const AWorld: TWarModelWorld; const ASelection: TWarSelection;
  APlayer: Integer; const AMap: IWarCommandMap): TWarCommands;
begin
  Result := TWarCommands.Create(AWorld.Context, AWorld.Machine, AWorld.Economy,
    TWarCommander.Computer(ASelection, APlayer), AMap);
end;

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
  TWarAttackRegistration.Register(LContext, LMachine, LEvents);
  TWarGatherRegistry.RegisterAll(LMachine);
  TWarConstructionStates.Register(LMachine);
  Result := TWarModelWorld.Create(LContext, LMachine, LQueries, LEntities, TWarCombat.Create(LContext, LMachine),
    TWarEconomy.Create(LContext, LQueries));
end;

end.
