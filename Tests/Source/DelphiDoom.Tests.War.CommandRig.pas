{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a whole model with its commands       }
{  ready to use in a test                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CommandRig;

interface

uses
  System.SysUtils, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Forests, DelphiDoom.War.Map.Forest, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.World, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.GatherWorld, DelphiDoom.War.Model.Selection,
  DelphiDoom.War.Model.Commands.Intf, DelphiDoom.War.Model.Commands.Dispatcher,
  DelphiDoom.Tests.War.ConstructionObserver, DelphiDoom.Tests.War.GatherScenario;

type
  /// <summary>
  ///   A world of the model with everything a game gives it: the grid of the map, the forests, the fog (off unless
  ///   asked), the observer of the tests as events, host and random generator, the commands of the player and those
  ///   of a computer player (the player 1). The player 0 is human, 1 to 3 orcs, 4 neutral; everybody has 5000 gold and
  ///   lumber and the upgrades allowed up to the level 2. A tic is the whole tic (TWarModelWorld.Tick), 1/60 s
  /// </summary>
  TCommandRig = class
  strict private
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FForests: TWarMapForests;
    FPainter: IWarTilePainter;
    FGather: TWarGatherWorld;
    FObserver: TConstructionObserver;
    FMap: IWarCommandMap;
    FCommands: TWarCommands;
    FAiSelection: TWarSelection;
    FAiCommands: TWarCommands;
    FForest: TWarMapForest;
    FWallSlot: Integer;
    function GetContext: TWarModelContext;
    function GetMachine: TWarStateMachine;
  public
    constructor Create(ASeed: Cardinal = 1; AWithFog: Boolean = False);
    destructor Destroy; override;
    /// <summary>A unit that moves with its idle state entered (one tic goes by); the slot</summary>
    function AddDude(AUnitType, AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>A finished building with its idle state entered (one tic goes by); the slot</summary>
    function AddBuilding(AUnitType, AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>A gold mine of the neutral player with the gold; the slot</summary>
    function AddMine(AX, AY, AAmount: Integer): Integer;
    /// <summary>A tree with wood in the forest of the rig (made at the first tree); the slot of the forest entity</summary>
    function AddTree(AX, AY, AAmount: Integer): Integer;
    /// <summary>A piece of wall with all its hit points (the entity of the wall is made at the first piece); the index of the piece</summary>
    function AddWallPiece(AX, AY: Integer): Integer;
    /// <summary>The corpse of a unit of the type on the tile; the slot</summary>
    function AddCorpse(AX, AY: Integer): Integer;
    /// <summary>
    ///   The tile takes the state in the fog. wmap_setMapTileState does not light the corners of its rectangle, so the
    ///   rectangle is the 3 x 3 around the tile: the tile and its four neighbours change
    /// </summary>
    procedure Reveal(AX, AY: Integer; AState: TWarMapTileState = wtsVisible);
    procedure Tick(ACount: Integer = 1; ADelta: Single = 0.016666668);
    procedure Run(ASeconds: Single; ADelta: Single = 0.016666668);
    /// <summary>Tics until the condition is true; False if the seconds went by before</summary>
    function RunUntil(const ACondition: TFunc<Boolean>; AMaxSeconds: Single = 30; ADelta: Single = 0.016666668): Boolean;
    /// <summary>The selection of the player becomes the entities of the slots</summary>
    procedure Select(const ASlots: array of Integer);
    function Entity(ASlot: Integer): PWarEntity;
    function UnitOf(ASlot: Integer): PWarUnitComponent;
    function IdOf(ASlot: Integer): Word;
    function ActiveType(ASlot: Integer): Integer;
    function Center(ASlot: Integer): TWarVec2;
    /// <summary>The centre of a tile, in pixels of the map</summary>
    function TilePoint(AX, AY: Integer): TWarVec2;
    function CountOfType(AUnitType: Integer): Integer;
    function CountEntities(AEntityType: Integer): Integer;
    property World: TWarModelWorld read FWorld;
    property Context: TWarModelContext read GetContext;
    property Machine: TWarStateMachine read GetMachine;
    property Grid: TWarPathGrid read FGrid;
    property Fog: TWarFogOfWar read FFog;
    property Forests: TWarMapForests read FForests;
    property Forest: TWarMapForest read FForest;
    property Observer: TConstructionObserver read FObserver;
    property Map: IWarCommandMap read FMap;
    property Commands: TWarCommands read FCommands;
    property AiSelection: TWarSelection read FAiSelection;
    property AiCommands: TWarCommands read FAiCommands;
    property WallSlot: Integer read FWallSlot;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types,
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.TerrainEntities,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.Commands.GridMap;

{ TCommandRig }

constructor TCommandRig.Create(ASeed: Cardinal; AWithFog: Boolean);
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LZeros: TArray<Word>;
begin
  inherited Create;
  FObserver := TConstructionObserver.Create(ASeed);
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FFog := TWarFogOfWar.Create;
  FFog.Enabled := AWithFog;
  FPainter := TRecordingPainter.Create;
  FForests := TWarMapForests.Create(FGrid, FFog, FPainter, WAR_TILESET_FOREST);
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FWorld.Context.ConstructionHost := FObserver;
  FGather := TWarGatherWorld.Create(FGrid, FForests, FObserver);
  FWorld.Context.Gather := FGather;
  if AWithFog then
    FMap := TWarGridCommandMap.Create(FGrid, FFog)
  else
    FMap := TWarGridCommandMap.Create(FGrid);
  FCommands := TWarModelFactory.CreateCommands(FWorld, FMap);
  FAiSelection := TWarSelection.Create;
  FAiCommands := TWarModelFactory.CreateComputerCommands(FWorld, FAiSelection, 1, FMap);
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    if LPlayer = 0 then
      FWorld.Context.Players[LPlayer]^.Race := wraHumans
    else if LPlayer = 4 then
      FWorld.Context.Players[LPlayer]^.Race := wraNeutral
    else
      FWorld.Context.Players[LPlayer]^.Race := wraOrcs;
    FWorld.Context.Players[LPlayer]^.Gold := 5000;
    FWorld.Context.Players[LPlayer]^.Wood := 5000;
    for LUpgrade := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
      FWorld.Context.Players[LPlayer]^.Upgrades[LUpgrade].Allowed := 2;
  end;
end;

destructor TCommandRig.Destroy;
begin
  FAiCommands.Free;
  FCommands.Free;
  FAiSelection.Free;
  FMap := nil;
  FWorld.Free;
  FGather.Free;
  FForests.Free;
  FFog.Free;
  FGrid.Free;
  FPainter := nil;
  inherited;
end;

function TCommandRig.GetContext: TWarModelContext;
begin
  Result := FWorld.Context;
end;

function TCommandRig.GetMachine: TWarStateMachine;
begin
  Result := FWorld.Machine;
end;

function TCommandRig.AddDude(AUnitType, AX, AY: Integer; APlayer: Byte): Integer;
begin
  Result := FWorld.Entities.CreateDude(AUnitType, AX, AY, APlayer, False);
  FWorld.Entities.SetInitialIdle(Result);
  Tick;
end;

function TCommandRig.AddBuilding(AUnitType, AX, AY: Integer; APlayer: Byte): Integer;
begin
  Result := FWorld.Entities.CreateBuilding(AUnitType, AX, AY, APlayer, False);
  Tick;
end;

function TCommandRig.AddMine(AX, AY, AAmount: Integer): Integer;
begin
  Result := FWorld.Entities.CreateUnit(WAR_UNIT_GOLDMINE, AX, AY, 4, wrkGold, Cardinal(AAmount), True);
  FWorld.Entities.SetInitialIdle(Result);
  Tick;
end;

function TCommandRig.AddTree(AX, AY, AAmount: Integer): Integer;
var
  LTree: TWarTree;
begin
  if not Assigned(FForest) then
    FForest := FForests.AddForest(IdOf(FWorld.Context.Pool.CreateEntity(WAR_ENTITY_FOREST, True)));
  LTree := Default(TWarTree);
  LTree.TileX := AX;
  LTree.TileY := AY;
  LTree.Amount := AAmount;
  FForest.Trees.Add(LTree);
  // the tiles of the trees are not decided: a tree alone or in a thin row has no tile and would be taken out of the forest
  FGrid.SetStaticEntity(AX, AY, 1, 1, FForest.Id);
  Result := FWorld.Context.Pool.FindSlot(FForest.Id);
end;

function TCommandRig.AddWallPiece(AX, AY: Integer): Integer;
begin
  if FWallSlot = 0 then
    FWallSlot := TWarTerrainEntities.CreateWall(FWorld.Context, FWorld.Machine);
  Result := FWorld.Context.Walls.Add(AX, AY, 0);
  FWorld.Context.Walls[Result]^.Hp := WAR_WALL_MAX_HP;
  FWorld.Context.Walls[Result]^.MaxHp := WAR_WALL_MAX_HP;
  FWorld.Context.Walls.DetermineTypes;
  // the idle state of the wall fills the tile
  Tick(2);
end;

function TCommandRig.AddCorpse(AX, AY: Integer): Integer;
begin
  Result := FWorld.Entities.CreateUnit(WAR_UNIT_HUMAN_CORPSE, AX, AY, WAR_MODEL_CORPSE_PLAYER, wrkNone, 0, True);
  FWorld.Entities.SetInitialIdle(Result);
  Tick;
end;

procedure TCommandRig.Reveal(AX, AY: Integer; AState: TWarMapTileState);
begin
  FFog.SetState(AX - 1, AY - 1, 3, 3, AState);
end;

procedure TCommandRig.Tick(ACount: Integer; ADelta: Single);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FWorld.Tick(ADelta);
end;

procedure TCommandRig.Run(ASeconds: Single; ADelta: Single);
var
  LEnd: Double;
begin
  LEnd := FWorld.Context.Clock^.GameTime + ASeconds;
  while FWorld.Context.Clock^.GameTime < LEnd do
    Tick(1, ADelta);
end;

function TCommandRig.RunUntil(const ACondition: TFunc<Boolean>; AMaxSeconds: Single; ADelta: Single): Boolean;
var
  LEnd: Double;
begin
  LEnd := FWorld.Context.Clock^.GameTime + AMaxSeconds;
  while FWorld.Context.Clock^.GameTime < LEnd do
  begin
    if ACondition() then
      Exit(True);
    Tick(1, ADelta);
  end;
  Result := ACondition();
end;

procedure TCommandRig.Select(const ASlots: array of Integer);
var
  LIndex: Integer;
begin
  FWorld.Context.Selection.Clear;
  for LIndex := 0 to High(ASlots) do
    FWorld.Context.Selection.Add(IdOf(ASlots[LIndex]));
end;

function TCommandRig.Entity(ASlot: Integer): PWarEntity;
begin
  Result := FWorld.Context.Pool.Slots[ASlot];
end;

function TCommandRig.UnitOf(ASlot: Integer): PWarUnitComponent;
begin
  Result := @FWorld.Context.Pool.Slots[ASlot]^.UnitData;
end;

function TCommandRig.IdOf(ASlot: Integer): Word;
begin
  Result := FWorld.Context.Pool.Slots[ASlot]^.Id;
end;

function TCommandRig.ActiveType(ASlot: Integer): Integer;
var
  LState: PWarStateBase;
begin
  LState := FWorld.Machine.ActiveState(ASlot);
  if Assigned(LState) then
    Result := LState^.StateType
  else
    Result := WAR_STATE_NONE;
end;

function TCommandRig.Center(ASlot: Integer): TWarVec2;
begin
  Result := TWarUnitGeometry.CenterPosition(FWorld.Context.Pool.Slots[ASlot]);
end;

function TCommandRig.TilePoint(AX, AY: Integer): TWarVec2;
begin
  Result := TWarModelMath.TileToMap(TWarModelMath.Vec(AX, AY), True);
end;

function TCommandRig.CountOfType(AUnitType: Integer): Integer;
begin
  Result := FWorld.Context.Pool.UnitsOfType[AUnitType].Count;
end;

function TCommandRig.CountEntities(AEntityType: Integer): Integer;
var
  LSlot: Integer;
begin
  Result := 0;
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    if (FWorld.Context.Pool.Slots[LSlot]^.Id <> 0) and
      (FWorld.Context.Pool.Slots[LSlot]^.EntityType = AEntityType) then
      Inc(Result);
end;

end.
