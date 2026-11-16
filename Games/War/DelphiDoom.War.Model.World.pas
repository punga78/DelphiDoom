{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the game model that the game runs                 }
{                                                                              }
{  Port of war1 (acoto87/war1), the order of wmap_updateMap for the entities,  }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Games\War\LICENSE-war1.txt). This is an altered version.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.World;

interface

uses
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Economy, DelphiDoom.War.Ai.Intf;

type
  /// <summary>
  ///   The entities of a game and everything that acts on them: units, states, life and money. It is made by
  ///   TWarModelFactory and owns what it holds. The game calls AdvanceClock and Update once per tic
  /// </summary>
  TWarModelWorld = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FQueries: IWarUnitQueries;
    FEntities: IWarEntityManager;
    FCombat: TWarCombat;
    FEconomy: TWarEconomy;
    FComputerPlayers: IWarComputerUpdate;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const AQueries: IWarUnitQueries; const AEntities: IWarEntityManager; const ACombat: TWarCombat;
      const AEconomy: TWarEconomy);
    destructor Destroy; override;
    /// <summary>The start of a tic: the game time goes forward by the length of the tic (seconds)</summary>
    procedure AdvanceClock(ADeltaTime: Single);
    /// <summary>
    ///   The states of a tic, in the order of wmap_updateMap: the requests of change that wait, then the update of each
    ///   type of state
    /// </summary>
    procedure Update;
    /// <summary>
    ///   The rest of the tic of wmap_updateMap that the model has, after the states, in its order: the grid of the units,
    ///   the steps of the actions of every unit (the frames, the blow, the sounds: TWarActionRunner) and the projectiles,
    ///   then the fog if the world has an updater (TWarModelFactory.AttachFog). The game calls it after Update. This is the
    ///   only place that runs the actions
    /// </summary>
    procedure UpdateAfterStates;
    /// <summary>
    ///   The whole rest of the tic of wmap_updateMap, in its order: the grid of the units, the steps of the actions, the
    ///   animations, the projectiles, the mana, the spells and the fog (updateFoW and determineFoWTypes, if the world has an
    ///   updater). It is UpdateAfterStates with the animations, the mana and the spells (UpdateAfterStates stays for who
    ///   wants the tic without them)
    /// </summary>
    procedure FinishTic;
    /// <summary>A whole tic: AdvanceClock, Update and FinishTic. The orders of the tic are given before it</summary>
    procedure Tick(ADeltaTime: Single);
    property Context: TWarModelContext read FContext;
    property Machine: TWarStateMachine read FMachine;
    property Queries: IWarUnitQueries read FQueries;
    property Entities: IWarEntityManager read FEntities;
    property Combat: TWarCombat read FCombat;
    property Economy: TWarEconomy read FEconomy;
    /// <summary>
    ///   The computer players (TWarModelFactory.AttachComputerPlayers), nil if nobody plays the computer. Update runs them
    ///   first, as wmap_updateMap does (wai_updateAIPlayers comes after the orders of the player and before the requests of
    ///   change of the states)
    /// </summary>
    property ComputerPlayers: IWarComputerUpdate read FComputerPlayers write FComputerPlayers;
  end;

implementation

uses
  DelphiDoom.War.Model.ActionRunner, DelphiDoom.War.Model.Animations, DelphiDoom.War.Model.Spells;

{ TWarModelWorld }

constructor TWarModelWorld.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const AQueries: IWarUnitQueries; const AEntities: IWarEntityManager; const ACombat: TWarCombat;
  const AEconomy: TWarEconomy);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FQueries := AQueries;
  FEntities := AEntities;
  FCombat := ACombat;
  FEconomy := AEconomy;
end;

destructor TWarModelWorld.Destroy;
begin
  // the training states call the computer players: they go before the context does
  FContext.AiProgress := nil;
  FComputerPlayers := nil;
  FEconomy.Free;
  FCombat.Free;
  FQueries := nil;
  FEntities := nil;
  FContext.Queries := nil;
  FContext.Entities := nil;
  FContext.Combat := nil;
  FMachine.Free;
  FContext.Free;
  inherited;
end;

procedure TWarModelWorld.AdvanceClock(ADeltaTime: Single);
begin
  FContext.Clock^.DeltaTime := ADeltaTime;
  FContext.Clock^.GameTime := FContext.Clock^.GameTime + ADeltaTime;
end;

procedure TWarModelWorld.Update;
begin
  if Assigned(FComputerPlayers) then
    FComputerPlayers.UpdateComputerPlayers;
  FMachine.ProcessPendingTransitions;
  FMachine.UpdateStates;
end;

procedure TWarModelWorld.UpdateAfterStates;
begin
  // the order of wmap_updateMap: the grid of the units, the steps of the actions, the projectiles
  if Assigned(FContext.Combat) then
    FContext.Combat.BuildNearUnits;
  TWarActionRunner.UpdateAll(FContext);
  if Assigned(FContext.Combat) then
    FContext.Combat.UpdateProjectiles;
  // the fog is the last thing of wmap_updateMap that the model has (nothing if the game gave no updater)
  if Assigned(FContext.FogUpdater) then
    FContext.FogUpdater.Update;
end;

procedure TWarModelWorld.FinishTic;
begin
  if Assigned(FContext.Combat) then
    FContext.Combat.BuildNearUnits;
  TWarActionRunner.UpdateAll(FContext);
  TWarAnimations.UpdateAll(FContext);
  if Assigned(FContext.Combat) then
    FContext.Combat.UpdateProjectiles;
  TWarSpells.UpdateMagic(FMachine);
  TWarSpells.UpdateSpells(FMachine);
  // updateFoW and determineFoWTypes come after the spells (a Holy Sight that was just cast shows in this very tic)
  if Assigned(FContext.FogUpdater) then
    FContext.FogUpdater.Update;
end;

procedure TWarModelWorld.Tick(ADeltaTime: Single);
begin
  AdvanceClock(ADeltaTime);
  Update;
  FinishTic;
end;

end.
