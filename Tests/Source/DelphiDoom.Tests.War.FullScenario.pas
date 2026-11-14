{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of the commands, of the }
{  spells and of the whole tic                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.FullScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Forests, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.GatherWorld, DelphiDoom.War.Model.Selection, DelphiDoom.War.Model.Commands.Dispatcher,
  DelphiDoom.War.Model.FlowSteering, DelphiDoom.Tests.War.ConstructionObserver, DelphiDoom.Tests.War.GatherScenario,
  DelphiDoom.War.Ai.Players;

type
  /// <summary>
  ///   The kinds of scenario of war_full_ref.inc: the lines of the golden start with O, I and A, and W for the computer
  ///   player (issue #196: the same world with the AI of war_ai.c playing the player 1, 3000 tics)
  /// </summary>
  TFullMode = (fmCommands, fmSpells, fmFull, fmAi);

  /// <summary>
  ///   The scenarios of war_full_ref.inc (Tools\Verifica\194) written again: two bases, a forest, a mine, a wall, the
  ///   same script (the LCG of the seed, the same operations drawn in the same order) and the same text of the state.
  ///   Where the C goes through the true wcmd_executeCommand, updateCommandFromRightClick, updateSelectionFromList and
  ///   updateSelectionGroups with a synthetic click, here the orders go through TWarCommands (and the ones of the
  ///   computer through a second TWarCommands with its own selection); the tic is TWarModelWorld.Update + FinishTic
  /// </summary>
  TFullScenario = class
  strict private
    FMode: TFullMode;
    FScriptState: Cardinal;
    FResults: Cardinal;
    FSpawned: array[0..255] of Word;
    FSpawnedCount: Integer;
    FDelta: Single;
    FForestId: Word;
    FMineId: Word;
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FForests: TWarMapForests;
    FPainter: TRecordingPainter;
    FPainterRef: IWarTilePainter;
    FGather: TWarGatherWorld;
    FObserver: TConstructionObserver;
    FCommands: TWarCommands;
    FAiSelection: TWarSelection;
    FAiCommands: TWarCommands;
    FSteering: TWarFlowSteering;
    FAi: TWarComputerPlayers;
    FRealFactor: Double;
    function ScriptBelow(ALimit: Cardinal): Integer;
    procedure ResultMix(AValue: Cardinal);
    procedure Setup(ASeed: Cardinal; AMode: TFullMode; AReal: Boolean);
    procedure Teardown;
    procedure CreateForest(AX, AY, AWidth, AHeight: Integer);
    function SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer): Integer;
    procedure SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
    function Matches(ASlot, AKind: Integer): Boolean;
    function PickWhere(AKind: Integer): Integer;
    procedure Prune;
    procedure SelectMany(AKind: Integer; AMax: Cardinal);
    procedure SelectOnly(ASlot: Integer);
    function RandomPoint: TWarVec2;
    function TilePoint(AX, AY: Integer): TWarVec2;
    function Center(ASlot: Integer): TWarVec2;
    function CountType(AUnitType: Integer): Integer;
    function WallPoint(out APoint: TWarVec2): Boolean;
    function MinePoint(out APoint: TWarVec2): Boolean;
    function TreePoint(out APoint: TWarVec2): Boolean;
    function EnemyOrRandomPoint: TWarVec2;
    procedure OpMove;
    procedure OpAttackUnit;
    procedure OpAttackPoint;
    procedure OpAttackWall;
    procedure OpHarvestMine;
    procedure OpHarvestTree;
    procedure OpDeliver;
    procedure OpRepair;
    procedure OpRight;
    procedure OpTrain;
    procedure OpUpgrade;
    procedure OpCancel;
    procedure OpBuild;
    procedure OpWallOrRoad(AWall: Boolean);
    procedure OpGroup;
    procedure OpHurt;
    procedure OpDamageBuilding;
    procedure OpWallDamage;
    procedure OpAi;
    procedure OpEconomy;
    procedure OpRemove;
    procedure OpSummon;
    procedure OpRain;
    procedure OpPoison;
    procedure OpOnFriend(ACommandType: Integer);
    procedure OpRaise;
    procedure OpSight;
    procedure OpMana;
    // the operations of the scenarios with the computer player (aiOp* of war_ai_ref.inc)
    procedure OpAiEconomy;
    procedure OpAiFarm;
    procedure OpAiHall;
    procedure OpAiPreempt;
    procedure OpAiCancel;
    procedure OpAiDamage;
    procedure OpAiTime;
    procedure OpAiHurry;
    procedure RunOp(AIndex: Integer);
    procedure ScriptStep;
    procedure Tick;
    function DumpNow(ATic: Integer): string;
    procedure DumpAi(const AText: TStringBuilder);
  public
    /// <summary>
    ///   Runs the scenario of the seed (900 tics). For each tic ALines gets 'O|I|A seed tic hash entities'; with
    ///   ADumpTic >= 0 the lines are not written and ADumpText is the text of the state at that tic
    /// </summary>
    ///   With AReal the units have the flow fields and the avoidance and the fog is updated at the end of every tic
    ///   (`war_model_ref real commands|spells|full`, issue #195)
    class procedure Run(AMode: TFullMode; ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings;
      out ADumpText: string; AReal: Boolean = False); static;
    /// <summary>
    ///   Runs the scenario and counts, for each type of state, the tics with at least one active state of the type, and
    ///   for each type of entity the tics with at least one entity (what `war_model_ref fullstats` prints)
    /// </summary>
    class procedure Coverage(AMode: TFullMode; ASeed: Cardinal; out AStates, AEntities: TArray<Integer>); static;
    /// <summary>
    ///   What the computer player did in a scenario of the mode fmAi: the id of the last command (the pauses count), how far
    ///   the script went, how many times a training told the AI that a request was paid (AProgressCalls) and the tics with a
    ///   sleep running
    /// </summary>
    class procedure AiCoverage(ASeed: Cardinal; out ALastCommandId: Cardinal; out AScriptIndex: Integer;
      out AProgressCalls, ASleepTics: Integer); static;
    /// <summary>How many tics a scenario of the mode lasts</summary>
    class function ScenarioTics(AMode: TFullMode): Integer; static;
  end;

const
  FULL_SCENARIO_TICS = 900;
  /// <summary>The length of the scenarios with the computer player (AI_TICS_FULL of war_full_ref.inc)</summary>
  AI_SCENARIO_TICS = 3000;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Forest,
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.Intf,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.Walls, DelphiDoom.War.Model.TerrainEntities, DelphiDoom.War.Model.Construction.Types,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.Model.Commands.Intf, DelphiDoom.War.Model.Commands.GridMap,
  DelphiDoom.War.Path.FlowFields, DelphiDoom.Tests.War.ModelDump, DelphiDoom.War.Ai.Intf, DelphiDoom.War.Ai.Player,
  DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Types;

{$Q-}
{$R-}

type
  /// <summary>Counts how many times a training state tells the AI that a request was paid, and passes it on</summary>
  TProgressProbe = class(TInterfacedObject, IWarAiProgress)
  strict private
    FTarget: IWarAiProgress;
    FCalls: Integer;
  public
    constructor Create(const ATarget: IWarAiProgress);
    procedure UnitRequestProgress(AHandle: Cardinal);
    property Calls: Integer read FCalls;
  end;

  TPlacedUnit = record
    UnitType: Integer;
    X: Integer;
    Y: Integer;
  end;

  TFullOp = record
    Weights: array[TFullMode] of Integer;
  end;

const
  DELTAS: array[0..3] of Single = (0.016666668, 0.033333335, 0.1, 0.25);
  PICK_OWN_DUDE = 0;
  PICK_OWN_WORKER = 1;
  PICK_OWN_WARRIOR = 2;
  PICK_OWN_CONJURER = 3;
  PICK_OWN_CLERIC = 4;
  PICK_OWN_BUILDING = 5;
  PICK_OWN_TOWNHALL = 6;
  PICK_ENEMY = 7;
  PICK_ENEMY_BUILDING = 8;
  PICK_ANY_LIVE = 9;
  PICK_CORPSE = 10;
  // predBuilding of war_construction_ref.inc: a building of the player 0, whatever it is doing
  PICK_ANY_OWN_BUILDING = 11;
  // the farms and the town halls of the player 1 (fAiFarm, fAiHall of war_ai_ref.inc), alive
  PICK_AI_FARM = 12;
  PICK_AI_HALL = 13;
  // kAiRealFactors: how many seconds of real time pass for each second of the game, by seed
  REAL_FACTORS: array[0..3] of Double = (1.0, 4.0, 10.0, 40.0);

  BASE: array[0..9] of TPlacedUnit = (
    (UnitType: WAR_UNIT_TOWNHALL_HUMANS; X: 6; Y: 6), (UnitType: WAR_UNIT_BARRACKS_HUMANS; X: 11; Y: 6),
    (UnitType: WAR_UNIT_CHURCH; X: 16; Y: 6), (UnitType: WAR_UNIT_TOWER_HUMANS; X: 21; Y: 6),
    (UnitType: WAR_UNIT_FARM_HUMANS; X: 26; Y: 6), (UnitType: WAR_UNIT_FARM_HUMANS; X: 29; Y: 6),
    (UnitType: WAR_UNIT_FARM_HUMANS; X: 32; Y: 6), (UnitType: WAR_UNIT_FARM_HUMANS; X: 35; Y: 6),
    (UnitType: WAR_UNIT_LUMBERMILL_HUMANS; X: 6; Y: 11), (UnitType: WAR_UNIT_BLACKSMITH_HUMANS; X: 11; Y: 11));
  DUDES: array[0..16] of TPlacedUnit = (
    (UnitType: WAR_UNIT_PEASANT; X: 6; Y: 18), (UnitType: WAR_UNIT_PEASANT; X: 8; Y: 18),
    (UnitType: WAR_UNIT_PEASANT; X: 10; Y: 18), (UnitType: WAR_UNIT_PEON; X: 12; Y: 18),
    (UnitType: WAR_UNIT_FOOTMAN; X: 14; Y: 18), (UnitType: WAR_UNIT_FOOTMAN; X: 16; Y: 18),
    (UnitType: WAR_UNIT_ARCHER; X: 18; Y: 18), (UnitType: WAR_UNIT_KNIGHT; X: 20; Y: 18),
    (UnitType: WAR_UNIT_CATAPULT_HUMANS; X: 22; Y: 18), (UnitType: WAR_UNIT_CONJURER; X: 6; Y: 21),
    (UnitType: WAR_UNIT_CONJURER; X: 8; Y: 21), (UnitType: WAR_UNIT_WARLOCK; X: 10; Y: 21),
    (UnitType: WAR_UNIT_WARLOCK; X: 12; Y: 21), (UnitType: WAR_UNIT_CLERIC; X: 14; Y: 21),
    (UnitType: WAR_UNIT_CLERIC; X: 16; Y: 21), (UnitType: WAR_UNIT_NECROLYTE; X: 18; Y: 21),
    (UnitType: WAR_UNIT_NECROLYTE; X: 20; Y: 21));
  ENEMY_BASE: array[0..3] of TPlacedUnit = (
    (UnitType: WAR_UNIT_TOWNHALL_ORCS; X: 40; Y: 30), (UnitType: WAR_UNIT_BARRACKS_ORCS; X: 45; Y: 30),
    (UnitType: WAR_UNIT_FARM_ORCS; X: 40; Y: 35), (UnitType: WAR_UNIT_FARM_ORCS; X: 43; Y: 35));
  ENEMY_DUDES: array[0..5] of TPlacedUnit = (
    (UnitType: WAR_UNIT_GRUNT; X: 30; Y: 26), (UnitType: WAR_UNIT_GRUNT; X: 32; Y: 26),
    (UnitType: WAR_UNIT_GRUNT; X: 34; Y: 26), (UnitType: WAR_UNIT_SPEARMAN; X: 36; Y: 26),
    (UnitType: WAR_UNIT_PEON; X: 38; Y: 26), (UnitType: WAR_UNIT_RAIDER; X: 30; Y: 28));

  // kFullOps of war_full_ref.inc: the weights of each operation for the three kinds of scenario, in the same order
  OPS: array[0..42] of TFullOp = (
    (Weights: (40, 10, 25, 25)), (Weights: (30, 10, 20, 20)), (Weights: (30, 0, 15, 15)), (Weights: (25, 6, 12, 12)),
    (Weights: (6, 2, 3, 3)), (Weights: (20, 10, 12, 12)), (Weights: (8, 0, 4, 4)), (Weights: (10, 0, 5, 5)),
    (Weights: (12, 0, 8, 8)), (Weights: (12, 0, 8, 8)), (Weights: (6, 0, 3, 3)), (Weights: (8, 0, 4, 4)),
    (Weights: (30, 4, 14, 14)), (Weights: (6, 0, 4, 4)), (Weights: (3, 0, 2, 2)), (Weights: (3, 0, 2, 2)),
    (Weights: (5, 0, 3, 3)), (Weights: (5, 0, 3, 3)), (Weights: (5, 0, 3, 3)), (Weights: (10, 2, 5, 5)),
    (Weights: (15, 25, 18, 18)), (Weights: (5, 0, 4, 4)), (Weights: (2, 0, 1, 1)), (Weights: (5, 0, 3, 0)),
    (Weights: (2, 0, 1, 1)), (Weights: (1, 1, 1, 1)), (Weights: (0, 8, 4, 4)), (Weights: (0, 10, 5, 5)),
    (Weights: (0, 8, 4, 4)), (Weights: (0, 10, 5, 5)), (Weights: (0, 8, 4, 4)), (Weights: (0, 8, 4, 4)),
    (Weights: (0, 10, 5, 5)), (Weights: (0, 8, 4, 4)), (Weights: (0, 10, 5, 5)),
    (Weights: (0, 0, 0, 20)), (Weights: (0, 0, 0, 15)), (Weights: (0, 0, 0, 12)), (Weights: (0, 0, 0, 12)),
    (Weights: (0, 0, 0, 12)), (Weights: (0, 0, 0, 15)), (Weights: (0, 0, 0, 12)), (Weights: (0, 0, 0, 3)));

  BUILD_TYPES: array[0..15] of Integer = (WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_HUMANS,
    WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_CHURCH, WAR_UNIT_TEMPLE, WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS,
    WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_LUMBERMILL_ORCS,
    WAR_UNIT_STABLE, WAR_UNIT_KENNEL, WAR_UNIT_BLACKSMITH_HUMANS, WAR_UNIT_BLACKSMITH_ORCS);

{ TProgressProbe }

constructor TProgressProbe.Create(const ATarget: IWarAiProgress);
begin
  inherited Create;
  FTarget := ATarget;
end;

procedure TProgressProbe.UnitRequestProgress(AHandle: Cardinal);
begin
  Inc(FCalls);
  FTarget.UnitRequestProgress(AHandle);
end;

{ TFullScenario }

function TFullScenario.ScriptBelow(ALimit: Cardinal): Integer;
begin
  Result := 0;
  if ALimit <> 0 then
  begin
    FScriptState := FScriptState * 1664525 + 1013904223;
    Result := Integer((FScriptState shr 8) mod ALimit);
  end;
end;

procedure TFullScenario.ResultMix(AValue: Cardinal);
begin
  FResults := (FResults * 16777619) xor AValue;
end;

procedure TFullScenario.CreateForest(AX, AY, AWidth, AHeight: Integer);
var
  LSlot: Integer;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LX: Integer;
  LY: Integer;
  LPresent: Integer;
  LAmount: Integer;
begin
  LSlot := FWorld.Context.Pool.CreateEntity(WAR_ENTITY_FOREST, True);
  LForest := FForests.AddForest(FWorld.Context.Pool.Slots[LSlot]^.Id);
  for LY := 0 to AHeight - 1 do
    for LX := 0 to AWidth - 1 do
    begin
      LPresent := ScriptBelow(100);
      LAmount := 2 + ScriptBelow(15);
      if LPresent >= 85 then
        Continue;
      LTree := Default(TWarTree);
      LTree.TileX := AX + LX;
      LTree.TileY := AY + LY;
      LTree.Amount := LAmount;
      LForest.Trees.Add(LTree);
      FGrid.SetStaticEntity(AX + LX, AY + LY, 1, 1, LForest.Id);
    end;
  FForests.DetermineTiles(LForest);
  FForestId := LForest.Id;
end;

procedure TFullScenario.Setup(ASeed: Cardinal; AMode: TFullMode; AReal: Boolean);
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
  LIndex: Integer;
  LZeros: TArray<Word>;
  LSlot: Integer;
  LAmount: Integer;
  LMap: IWarCommandMap;
  LPiece: Integer;
  LHumanAi: Boolean;
begin
  FMode := AMode;
  FAi := nil;
  FRealFactor := REAL_FACTORS[(ASeed div 4) mod 4];
  FObserver := TConstructionObserver.Create(ASeed xor $C3C3C3C3);
  FScriptState := ASeed * 2654435761 + 4242 + Cardinal(Ord(AMode)) * 977;
  FResults := 2166136261;
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FFog := TWarFogOfWar.Create;
  FFog.Enabled := AReal;
  FPainter := TRecordingPainter.Create;
  FPainterRef := FPainter;
  FForests := TWarMapForests.Create(FGrid, FFog, FPainterRef, WAR_TILESET_FOREST);
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FWorld.Context.ConstructionHost := FObserver;
  FGather := TWarGatherWorld.Create(FGrid, FForests, FObserver);
  FWorld.Context.Gather := FGather;
  // the C of the golden was built with gcc, where the enum of the directions is unsigned
  FWorld.Context.UnsignedDirections := True;
  if AReal then
  begin
    // the real paths and the fog of war: the units walk around what is on the grid and each other, the fog is updated
    // at the end of every tic, and the commands see it
    TWarModelFactory.AttachFlowSteering(FWorld, FGrid);
    FSteering := FWorld.Context.Steering as TWarFlowSteering;
    FSteering.Fields.TrackSignature := True;
    TWarModelFactory.AttachFog(FWorld, FFog);
    LMap := TWarGridCommandMap.Create(FGrid, FFog);
  end
  else
    LMap := TWarGridCommandMap.Create(FGrid);
  FCommands := TWarModelFactory.CreateCommands(FWorld, LMap);
  FAiSelection := TWarSelection.Create;
  FAiCommands := TWarModelFactory.CreateComputerCommands(FWorld, FAiSelection, 1, LMap);
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    LInfo := FWorld.Context.Players[LPlayer];
    if LPlayer = 0 then
      LInfo^.Race := wraHumans
    else if LPlayer = 4 then
      LInfo^.Race := wraNeutral
    else
      LInfo^.Race := wraOrcs;
    LInfo^.Gold := 5000;
    LInfo^.Wood := 5000;
    for LUpgrade := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
      LInfo^.Upgrades[LUpgrade].Allowed := 2;
  end;
  FDelta := DELTAS[ASeed mod 4];
  FWorld.Context.ViewportTop := 16 * Integer(ASeed mod 5);
  FSpawnedCount := 0;
  FWorld.Context.Players[0]^.Gold := 3000 + ScriptBelow(6000);
  FWorld.Context.Players[0]^.Wood := 2000 + ScriptBelow(4000);
  // the map makes the forest first, then the road, the wall (with its idle state) and the ruins, then its units
  CreateForest(46, 8, 6, 5);
  LSlot := TWarTerrainEntities.CreateRoad(FWorld.Context);
  Assert(LSlot <> 0);
  LSlot := TWarTerrainEntities.CreateWall(FWorld.Context, FWorld.Machine);
  Assert(LSlot <> 0);
  LSlot := TWarTerrainEntities.CreateRuins(FWorld.Context);
  Assert(LSlot <> 0);
  for LIndex := 0 to High(BASE) do
    SpawnBuilding(BASE[LIndex].UnitType, 0, BASE[LIndex].X, BASE[LIndex].Y);
  LAmount := 300 + ScriptBelow(400);
  LSlot := FWorld.Entities.CreateUnit(WAR_UNIT_GOLDMINE, 16, 12, 4, wrkGold, Cardinal(LAmount), True);
  FWorld.Entities.SetInitialIdle(LSlot);
  FMineId := FWorld.Context.Pool.Slots[LSlot]^.Id;
  for LIndex := 0 to High(DUDES) do
    SpawnDude(DUDES[LIndex].UnitType, 0, DUDES[LIndex].X, DUDES[LIndex].Y);
  // the scenarios with the computer: with an odd seed the player 1 is of the humans (same places, the types of the race)
  LHumanAi := (AMode = fmAi) and Odd(ASeed);
  if LHumanAi then
    FWorld.Context.Players[1]^.Race := wraHumans;
  for LIndex := 0 to High(ENEMY_BASE) do
    if LHumanAi then
      SpawnBuilding(TWarUnitClassifier.TypeForRace(ENEMY_BASE[LIndex].UnitType, wraHumans), 1, ENEMY_BASE[LIndex].X,
        ENEMY_BASE[LIndex].Y)
    else
      SpawnBuilding(ENEMY_BASE[LIndex].UnitType, 1, ENEMY_BASE[LIndex].X, ENEMY_BASE[LIndex].Y);
  for LIndex := 0 to High(ENEMY_DUDES) do
    if LHumanAi then
      SpawnDude(TWarUnitClassifier.TypeForRace(ENEMY_DUDES[LIndex].UnitType, wraHumans), 1, ENEMY_DUDES[LIndex].X,
        ENEMY_DUDES[LIndex].Y)
    else
      SpawnDude(ENEMY_DUDES[LIndex].UnitType, 1, ENEMY_DUDES[LIndex].X, ENEMY_DUDES[LIndex].Y);
  if AMode = fmAi then
  begin
    // wmap_enterMap: wai_initAIPlayers after the starting units
    FWorld.Context.RealTime := 0;
    FAi := TWarModelFactory.AttachComputerPlayers(FWorld, [1]);
  end;
  // a stretch of wall already standing between the two bases
  for LIndex := 28 to 33 do
  begin
    LPiece := FWorld.Context.Walls.Add(LIndex, 23, 0);
    FWorld.Context.Walls[LPiece]^.Hp := WAR_WALL_MAX_HP;
    FWorld.Context.Walls[LPiece]^.MaxHp := WAR_WALL_MAX_HP;
  end;
  FWorld.Context.Walls.DetermineTypes;
end;

procedure TFullScenario.Teardown;
begin
  FAiCommands.Free;
  FCommands.Free;
  FAiSelection.Free;
  FWorld.Free;
  FGather.Free;
  FForests.Free;
  FFog.Free;
  FGrid.Free;
  FPainterRef := nil;
end;

function TFullScenario.SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer): Integer;
begin
  Result := FWorld.Entities.CreateDude(AType, AX, AY, APlayer, False);
  if Result <> 0 then
  begin
    FWorld.Entities.SetInitialIdle(Result);
    if FSpawnedCount < 256 then
    begin
      FSpawned[FSpawnedCount] := FWorld.Context.Pool.Slots[Result]^.Id;
      Inc(FSpawnedCount);
    end;
  end;
end;

procedure TFullScenario.SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateBuilding(AType, AX, AY, APlayer, False);
  if (LSlot <> 0) and (FSpawnedCount < 256) then
  begin
    FSpawned[FSpawnedCount] := FWorld.Context.Pool.Slots[LSlot]^.Id;
    Inc(FSpawnedCount);
  end;
end;

function TFullScenario.Matches(ASlot, AKind: Integer): Boolean;
var
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LMachine: TWarStateMachine;
  LAlive: Boolean;
  LOwnDude: Boolean;
begin
  LEntity := FWorld.Context.Pool.Slots[ASlot];
  if not LEntity^.HasUnit then
    Exit(False);
  LUnit := @LEntity^.UnitData;
  LMachine := FWorld.Machine;
  LAlive := not LMachine.IsDead(ASlot) and not LMachine.IsGoingToDie(ASlot) and not LMachine.IsCollapsing(ASlot) and
    not LMachine.IsGoingToCollapse(ASlot);
  LOwnDude := (LUnit^.Player = 0) and TWarUnitClassifier.IsDude(LUnit^.UnitType) and LAlive;
  case AKind of
    PICK_OWN_DUDE:
      Result := LOwnDude;
    PICK_OWN_WORKER:
      Result := LOwnDude and TWarUnitClassifier.IsWorker(LUnit^.UnitType) and not LMachine.IsInsideBuilding(ASlot);
    PICK_OWN_WARRIOR:
      Result := LOwnDude and TWarUnitClassifier.IsWarrior(LUnit^.UnitType);
    PICK_OWN_CONJURER:
      Result := LOwnDude and TWarUnitClassifier.IsConjurerOrWarlock(LUnit^.UnitType);
    PICK_OWN_CLERIC:
      Result := LOwnDude and TWarUnitClassifier.IsClericOrNecrolyte(LUnit^.UnitType);
    PICK_OWN_BUILDING:
      Result := (LUnit^.Player = 0) and TWarUnitClassifier.IsBuilding(LUnit^.UnitType) and LAlive;
    PICK_OWN_TOWNHALL:
      Result := (LUnit^.Player = 0) and (LUnit^.UnitType = WAR_UNIT_TOWNHALL_HUMANS) and LAlive;
    PICK_ENEMY:
      Result := (LUnit^.Player = 1) and LAlive;
    PICK_ENEMY_BUILDING:
      Result := (LUnit^.Player = 1) and TWarUnitClassifier.IsBuilding(LUnit^.UnitType) and LAlive;
    PICK_ANY_LIVE:
      Result := (LUnit^.Player <> 4) and LAlive;
    PICK_CORPSE:
      Result := TWarUnitClassifier.IsCorpse(LUnit^.UnitType);
    PICK_ANY_OWN_BUILDING:
      Result := (LUnit^.Player = 0) and TWarUnitClassifier.IsBuilding(LUnit^.UnitType);
    PICK_AI_FARM:
      Result := (LUnit^.Player = 1) and ((LUnit^.UnitType = WAR_UNIT_FARM_HUMANS) or
        (LUnit^.UnitType = WAR_UNIT_FARM_ORCS)) and LAlive;
    PICK_AI_HALL:
      Result := (LUnit^.Player = 1) and ((LUnit^.UnitType = WAR_UNIT_TOWNHALL_HUMANS) or
        (LUnit^.UnitType = WAR_UNIT_TOWNHALL_ORCS)) and LAlive;
  else
    Result := False;
  end;
end;

function TFullScenario.PickWhere(AKind: Integer): Integer;
var
  LUnits: TList<Integer>;
  LStart: Integer;
  LCount: Integer;
  LStep: Integer;
  LSlot: Integer;
begin
  LUnits := FWorld.Context.Pool.OfType[WAR_ENTITY_UNIT];
  LCount := LUnits.Count;
  if LCount > 0 then
    LStart := ScriptBelow(Cardinal(LCount))
  else
    LStart := ScriptBelow(1);
  for LStep := 0 to LCount - 1 do
  begin
    LSlot := LUnits[(LStart + LStep) mod LCount];
    if Matches(LSlot, AKind) then
      Exit(LSlot);
  end;
  Result := 0;
end;

procedure TFullScenario.Prune;
var
  LSelection: TWarSelection;
  LIndex: Integer;
begin
  LSelection := FWorld.Context.Selection;
  for LIndex := LSelection.Count - 1 downto 0 do
    if FWorld.Context.Pool.FindSlot(LSelection[LIndex]) = 0 then
      LSelection.Remove(LSelection[LIndex]);
end;

procedure TFullScenario.SelectMany(AKind: Integer; AMax: Cardinal);
var
  LCount: Integer;
  LIndex: Integer;
  LSlot: Integer;
  LSlots: TArray<Integer>;
  LUsed: Integer;
begin
  LCount := 1 + ScriptBelow(AMax);
  SetLength(LSlots, LCount);
  LUsed := 0;
  for LIndex := 0 to LCount - 1 do
  begin
    LSlot := PickWhere(AKind);
    if LSlot <> 0 then
    begin
      LSlots[LUsed] := LSlot;
      Inc(LUsed);
    end;
  end;
  SetLength(LSlots, LUsed);
  FCommands.Selecting.Select(LSlots);
end;

procedure TFullScenario.SelectOnly(ASlot: Integer);
begin
  FWorld.Context.Selection.Assign([FWorld.Context.Pool.Slots[ASlot]^.Id]);
end;

function TFullScenario.RandomPoint: TWarVec2;
var
  LX: Integer;
  LY: Integer;
begin
  LX := 64 + ScriptBelow(880);
  LY := 64 + ScriptBelow(880);
  Result := TWarModelMath.Vec(LX, LY);
end;

function TFullScenario.TilePoint(AX, AY: Integer): TWarVec2;
begin
  Result := TWarModelMath.TileToMap(TWarModelMath.Vec(AX, AY), True);
end;

function TFullScenario.Center(ASlot: Integer): TWarVec2;
begin
  Result := TWarUnitGeometry.CenterPosition(FWorld.Context.Pool.Slots[ASlot]);
end;

function TFullScenario.CountType(AUnitType: Integer): Integer;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
begin
  Result := 0;
  LUnits := FWorld.Context.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
    if FWorld.Context.Pool.Slots[LUnits[LIndex]]^.UnitData.UnitType = AUnitType then
      Inc(Result);
end;

function TFullScenario.WallPoint(out APoint: TWarVec2): Boolean;
var
  LCount: Integer;
  LIndex: Integer;
begin
  LCount := FWorld.Context.Walls.Count;
  if LCount > 0 then
    LIndex := ScriptBelow(Cardinal(LCount))
  else
    LIndex := ScriptBelow(1);
  if LCount = 0 then
    Exit(False);
  APoint := TilePoint(FWorld.Context.Walls[LIndex]^.TileX, FWorld.Context.Walls[LIndex]^.TileY);
  Result := True;
end;

function TFullScenario.MinePoint(out APoint: TWarVec2): Boolean;
var
  LSlot: Integer;
begin
  LSlot := FWorld.Context.Pool.FindSlot(FMineId);
  if LSlot = 0 then
    Exit(False);
  APoint := Center(LSlot);
  Result := True;
end;

function TFullScenario.TreePoint(out APoint: TWarVec2): Boolean;
var
  LPick: Integer;
  LForest: TWarMapForest;
  LTree: TWarTree;
begin
  LPick := ScriptBelow(40);
  if FWorld.Context.Pool.FindSlot(FForestId) = 0 then
    Exit(False);
  LForest := FForests.FindForest(FForestId);
  if LForest.Trees.Count = 0 then
    Exit(False);
  LTree := LForest.Trees[Cardinal(LPick) mod Cardinal(LForest.Trees.Count)];
  APoint := TilePoint(LTree.TileX, LTree.TileY);
  Result := True;
end;

function TFullScenario.EnemyOrRandomPoint: TWarVec2;
var
  LKind: Integer;
  LEnemy: Integer;
begin
  LKind := ScriptBelow(3);
  Result := RandomPoint;
  LEnemy := PickWhere(PICK_ENEMY);
  if (LKind <> 0) and (LEnemy <> 0) then
    Result := Center(LEnemy);
end;

procedure TFullScenario.OpMove;
var
  LShift: Boolean;
  LPoint: TWarVec2;
begin
  LShift := ScriptBelow(4) = 0;
  LPoint := RandomPoint;
  FCommands.Execute(WAR_COMMAND_MOVE, LPoint, LShift);
end;

procedure TFullScenario.OpAttackUnit;
var
  LEnemy: Integer;
begin
  SelectMany(PICK_OWN_WARRIOR, 4);
  LEnemy := PickWhere(PICK_ENEMY);
  if LEnemy = 0 then
    Exit;
  FCommands.Execute(WAR_COMMAND_ATTACK, Center(LEnemy));
end;

procedure TFullScenario.OpAttackPoint;
begin
  SelectMany(PICK_OWN_WARRIOR, 4);
  FCommands.Execute(WAR_COMMAND_ATTACK, RandomPoint);
end;

procedure TFullScenario.OpAttackWall;
var
  LPoint: TWarVec2;
begin
  SelectMany(PICK_OWN_WARRIOR, 4);
  if WallPoint(LPoint) then
    FCommands.Execute(WAR_COMMAND_ATTACK, LPoint);
end;

procedure TFullScenario.OpHarvestMine;
var
  LPoint: TWarVec2;
begin
  if MinePoint(LPoint) then
    FCommands.Execute(WAR_COMMAND_HARVEST, LPoint);
end;

procedure TFullScenario.OpHarvestTree;
var
  LPoint: TWarVec2;
begin
  if TreePoint(LPoint) then
    FCommands.Execute(WAR_COMMAND_HARVEST, LPoint);
end;

procedure TFullScenario.OpDeliver;
begin
  SelectMany(PICK_OWN_WORKER, 3);
  if (CountType(WAR_UNIT_TOWNHALL_HUMANS) = 0) or (CountType(WAR_UNIT_TOWNHALL_ORCS) = 0) then
    Exit;
  FCommands.Execute(WAR_COMMAND_DELIVER);
end;

procedure TFullScenario.OpRepair;
var
  LBuilding: Integer;
begin
  LBuilding := PickWhere(PICK_OWN_BUILDING);
  if LBuilding = 0 then
    Exit;
  FCommands.Execute(WAR_COMMAND_REPAIR, Center(LBuilding));
end;

procedure TFullScenario.OpRight;
var
  LKind: Integer;
  LShift: Boolean;
  LPoint: TWarVec2;
  LSlot: Integer;
begin
  // only dudes get a right click: the remake stops on an assert when a building is told to follow
  SelectMany(PICK_OWN_DUDE, 3);
  LKind := ScriptBelow(7);
  LShift := ScriptBelow(4) = 0;
  LPoint := RandomPoint;
  LSlot := 0;
  case LKind of
    1: LSlot := PickWhere(PICK_ENEMY);
    2: LSlot := PickWhere(PICK_OWN_DUDE);
    3: MinePoint(LPoint);
    4: TreePoint(LPoint);
    5: LSlot := PickWhere(PICK_OWN_TOWNHALL);
    6: WallPoint(LPoint);
  end;
  if LSlot <> 0 then
    LPoint := Center(LSlot);
  FCommands.RightClick(LPoint, LShift);
end;

procedure TFullScenario.OpTrain;
var
  LBuilding: Integer;
  LK: Integer;
  LType: Integer;
  LMatches: array[0..13] of Integer;
  LCount: Integer;
  LCommand: Integer;
  LUnitType: Integer;
  LBuildingType: Integer;
begin
  LBuilding := PickWhere(PICK_ANY_OWN_BUILDING);
  LK := ScriptBelow(4);
  if LBuilding = 0 then
    Exit;
  LType := FWorld.Context.Pool.Slots[LBuilding]^.UnitData.UnitType;
  LCount := 0;
  for LCommand := WAR_COMMAND_TRAIN_FIRST to WAR_COMMAND_TRAIN_LAST do
  begin
    TWarCommands.TrainOf(LCommand, LUnitType, LBuildingType);
    if LBuildingType = LType then
    begin
      LMatches[LCount] := LCommand;
      Inc(LCount);
    end;
  end;
  if LCount = 0 then
    Exit;
  SelectOnly(LBuilding);
  FCommands.Execute(LMatches[LK mod LCount]);
  // wcmd_executeCommand answers True whatever the order did
  ResultMix(1);
end;

procedure TFullScenario.OpUpgrade;
var
  LBuilding: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
begin
  LBuilding := PickWhere(PICK_ANY_OWN_BUILDING);
  LUpgrade := ScriptBelow(19);
  if LBuilding = 0 then
    Exit;
  LInfo := FWorld.Context.Players[0];
  if LInfo^.Upgrades[LUpgrade div 2].Level >= LInfo^.Upgrades[LUpgrade div 2].Allowed then
    Exit;
  if LInfo^.Upgrades[LUpgrade div 2].Level + FCommands.Construction.UpgradesInProgress(0, LUpgrade div 2) >=
    LInfo^.Upgrades[LUpgrade div 2].Allowed then
    Exit;
  SelectOnly(LBuilding);
  // the C gives the upgrade with the command of the swords whatever the upgrade is: here the order itself
  FCommands.Construction.OrderUpgrade(LBuilding, LUpgrade);
  ResultMix(1);
end;

procedure TFullScenario.OpCancel;
var
  LBuilding: Integer;
begin
  LBuilding := PickWhere(PICK_ANY_OWN_BUILDING);
  if LBuilding = 0 then
    Exit;
  SelectOnly(LBuilding);
  FCommands.Execute(WAR_COMMAND_CANCEL);
end;

procedure TFullScenario.OpBuild;
var
  LWorker: Integer;
  LTypeIndex: Integer;
  LRow: Integer;
  LSizeX: Integer;
  LSizeY: Integer;
  LTile: TWarVec2;
  LX: Integer;
  LY: Integer;
begin
  LWorker := PickWhere(PICK_OWN_WORKER);
  LTypeIndex := ScriptBelow(16);
  LRow := ScriptBelow(4);
  if LWorker = 0 then
    Exit;
  FWorld.Context.Database.TryGetUnitSize(BUILD_TYPES[LTypeIndex], LSizeX, LSizeY);
  LTile := TWarUnitGeometry.CenterTile(FWorld.Context.Pool.Slots[LWorker]);
  LX := Trunc(LTile.X) + 1;
  LY := Trunc(LTile.Y) - (LRow mod LSizeY);
  if LY < 0 then
    LY := 0;
  SelectOnly(LWorker);
  FCommands.Execute(WAR_COMMAND_BUILD_FIRST + LTypeIndex, TilePoint(LX, LY));
end;

procedure TFullScenario.OpWallOrRoad(AWall: Boolean);
const
  DX: array[0..3] of Integer = (0, 1, 0, -1);
  DY: array[0..3] of Integer = (-1, 0, 1, 0);
var
  LTownHall: Integer;
  LNear: Integer;
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LLastWall: PWarWallPiece;
  LRoad: TArray<TWarLinePiece>;
begin
  LTownHall := PickWhere(PICK_OWN_TOWNHALL);
  LNear := ScriptBelow(100);
  LDirection := ScriptBelow(4);
  LX := 6 + ScriptBelow(40);
  if AWall then
    LY := 30 + ScriptBelow(8)
  else
    LY := 42 + ScriptBelow(8);
  if LTownHall = 0 then
    Exit;
  if LNear < 70 then
  begin
    if AWall then
    begin
      if FWorld.Context.Walls.Count > 0 then
      begin
        LLastWall := FWorld.Context.Walls[FWorld.Context.Walls.Count - 1];
        LX := LLastWall^.TileX + DX[LDirection];
        LY := LLastWall^.TileY + DY[LDirection];
      end;
    end
    else
    begin
      LRoad := FWorld.Context.Roads.Pieces;
      if Length(LRoad) > 0 then
      begin
        LX := LRoad[High(LRoad)].TileX + DX[LDirection];
        LY := LRoad[High(LRoad)].TileY + DY[LDirection];
      end;
    end;
  end;
  if LX < 0 then
    LX := 0;
  if LX > 63 then
    LX := 63;
  if LY < 0 then
    LY := 0;
  if LY > 63 then
    LY := 63;
  SelectOnly(LTownHall);
  if AWall then
    FCommands.Execute(WAR_COMMAND_BUILD_WALL, TilePoint(LX, LY))
  else
    FCommands.Execute(WAR_COMMAND_BUILD_ROAD, TilePoint(LX, LY));
end;

procedure TFullScenario.OpGroup;
var
  LGroup: Integer;
  LStore: Boolean;
begin
  LGroup := ScriptBelow(WAR_MODEL_SELECTION_GROUPS);
  LStore := ScriptBelow(3) = 0;
  if LStore then
    FCommands.Selecting.StoreGroup(LGroup)
  else
    FCommands.Selecting.RecallGroup(LGroup);
end;

procedure TFullScenario.OpHurt;
var
  LSlot: Integer;
  LMin: Integer;
  LRnd: Integer;
begin
  LSlot := PickWhere(PICK_ANY_LIVE);
  LMin := ScriptBelow(40);
  LRnd := ScriptBelow(60);
  if LSlot = 0 then
    Exit;
  FWorld.Combat.TakeDamage(LSlot, LMin, LRnd);
end;

procedure TFullScenario.OpDamageBuilding;
var
  LBuilding: Integer;
  LMin: Integer;
  LRnd: Integer;
begin
  LBuilding := PickWhere(PICK_ANY_OWN_BUILDING);
  LMin := ScriptBelow(200);
  LRnd := ScriptBelow(300);
  if LBuilding = 0 then
    Exit;
  FWorld.Combat.TakeDamage(LBuilding, LMin, LRnd);
end;

procedure TFullScenario.OpWallDamage;
var
  LCount: Integer;
  LIndex: Integer;
  LMin: Integer;
  LRnd: Integer;
begin
  LCount := FWorld.Context.Walls.Count;
  if LCount > 0 then
    LIndex := ScriptBelow(Cardinal(LCount))
  else
    LIndex := ScriptBelow(1);
  LMin := ScriptBelow(60);
  LRnd := ScriptBelow(60);
  if LCount = 0 then
    Exit;
  FWorld.Context.Walls.TakeDamage(LIndex, LMin, LRnd);
end;

procedure TFullScenario.OpAi;
var
  LBuilding: Integer;
  LType: Integer;
begin
  LBuilding := PickWhere(PICK_ENEMY_BUILDING);
  if LBuilding = 0 then
    Exit;
  LType := FWorld.Context.Pool.Slots[LBuilding]^.UnitData.UnitType;
  FAiSelection.Assign([FWorld.Context.Pool.Slots[LBuilding]^.Id]);
  // the computer gives the same train command as the player, with its own selection and its cause
  if LType = WAR_UNIT_TOWNHALL_ORCS then
    FAiCommands.Execute(WAR_COMMAND_TRAIN_FIRST + 3)
  else if LType = WAR_UNIT_BARRACKS_ORCS then
    FAiCommands.Execute(WAR_COMMAND_TRAIN_FIRST + 1);
end;

procedure TFullScenario.OpEconomy;
var
  LPlayer: Integer;
  LGold: Integer;
  LWood: Integer;
  LKind: Integer;
begin
  LPlayer := ScriptBelow(5);
  LGold := ScriptBelow(300);
  LWood := ScriptBelow(300);
  LKind := ScriptBelow(3);
  if LKind = 0 then
    FWorld.Economy.IncreaseResources(FWorld.Context.Players[LPlayer], LGold, LWood)
  else if LKind = 1 then
    ResultMix(Ord(FWorld.Economy.DecreaseResources(FWorld.Context.Players[LPlayer], LGold * 8, LWood * 8)))
  else
    ResultMix(Ord(FWorld.Economy.EnoughResources(FWorld.Context.Players[LPlayer], LGold * 4, LWood * 4)));
end;

procedure TFullScenario.OpRemove;
var
  LCount: Cardinal;
  LIndex: Integer;
  LSlot: Integer;
begin
  if FSpawnedCount > 0 then
    LCount := Cardinal(FSpawnedCount)
  else
    LCount := 1;
  LIndex := ScriptBelow(LCount);
  if FSpawnedCount = 0 then
    Exit;
  LSlot := FWorld.Context.Pool.FindSlot(FSpawned[LIndex]);
  if LSlot = 0 then
    Exit;
  FWorld.Entities.RemoveEntityById(FWorld.Context.Pool.Slots[LSlot]^.Id);
end;

procedure TFullScenario.OpSummon;
var
  LKind: Integer;
begin
  SelectMany(PICK_OWN_CONJURER, 2);
  LKind := ScriptBelow(4);
  // the pool of the entities is finite and the remake does not check it: no summon when it is almost full
  if FWorld.Context.Pool.EntityCount > 800 then
    Exit;
  FCommands.Execute(WAR_COMMAND_SUMMON_SPIDER + LKind);
end;

procedure TFullScenario.OpRain;
var
  LPoint: TWarVec2;
begin
  SelectMany(PICK_OWN_CONJURER, 2);
  LPoint := EnemyOrRandomPoint;
  if FWorld.Context.Pool.EntityCount > 800 then
    Exit;
  FCommands.Execute(WAR_COMMAND_SPELL_RAIN_OF_FIRE, LPoint);
end;

procedure TFullScenario.OpPoison;
var
  LPoint: TWarVec2;
begin
  SelectMany(PICK_OWN_CONJURER, 2);
  LPoint := EnemyOrRandomPoint;
  FCommands.Execute(WAR_COMMAND_SPELL_POISON_CLOUD, LPoint);
end;

procedure TFullScenario.OpOnFriend(ACommandType: Integer);
var
  LFriend: Integer;
begin
  SelectMany(PICK_OWN_CLERIC, 2);
  LFriend := PickWhere(PICK_OWN_DUDE);
  if LFriend = 0 then
    Exit;
  FCommands.Execute(ACommandType, Center(LFriend));
end;

procedure TFullScenario.OpRaise;
var
  LPoint: TWarVec2;
  LCorpse: Integer;
begin
  SelectMany(PICK_OWN_CLERIC, 2);
  LPoint := RandomPoint;
  LCorpse := PickWhere(PICK_CORPSE);
  if LCorpse <> 0 then
    LPoint := Center(LCorpse);
  if FWorld.Context.Pool.EntityCount > 800 then
    Exit;
  FCommands.Execute(WAR_COMMAND_SPELL_RAISE_DEAD, LPoint);
end;

procedure TFullScenario.OpSight;
var
  LPoint: TWarVec2;
begin
  SelectMany(PICK_OWN_CLERIC, 2);
  LPoint := RandomPoint;
  FCommands.Execute(WAR_COMMAND_SPELL_FAR_SIGHT, LPoint);
end;

procedure TFullScenario.OpMana;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
begin
  LSlot := PickWhere(PICK_OWN_DUDE);
  if LSlot = 0 then
    Exit;
  LUnit := @FWorld.Context.Pool.Slots[LSlot]^.UnitData;
  if TWarUnitClassifier.IsMagic(LUnit^.UnitType) and not TWarUnitClassifier.IsSummon(LUnit^.UnitType) then
    LUnit^.Mana := LUnit^.MaxMana;
end;

procedure TFullScenario.OpAiEconomy;
var
  LKind: Integer;
  LGold: Integer;
  LWood: Integer;
  LPlayer: PWarPlayerInfo;
begin
  LKind := ScriptBelow(4);
  LGold := ScriptBelow(900);
  LWood := ScriptBelow(900);
  LPlayer := FWorld.Context.Players[1];
  case LKind of
    0:
      begin
        LPlayer^.Gold := LGold;
        LPlayer^.Wood := LWood;
      end;
    1:
      begin
        Inc(LPlayer^.Gold, 400);
        Inc(LPlayer^.Wood, 200);
      end;
    2:
      LPlayer^.Gold := 0;
  else
    LPlayer^.Gold := 5000;
    LPlayer^.Wood := 5000;
  end;
end;

procedure TFullScenario.OpAiFarm;
var
  LKind: Integer;
  LColumn: Integer;
  LRow: Integer;
  LSlot: Integer;
begin
  LKind := ScriptBelow(3);
  LColumn := ScriptBelow(6);
  LRow := ScriptBelow(3);
  if LKind = 0 then
  begin
    SpawnBuilding(TWarUnitClassifier.TypeForRace(WAR_UNIT_FARM_HUMANS, FWorld.Context.Players[1]^.Race), 1,
      36 + 3 * LColumn, 41 + 3 * LRow);
    Exit;
  end;
  LSlot := PickWhere(PICK_AI_FARM);
  if LSlot = 0 then
    Exit;
  if LKind = 1 then
    FWorld.Entities.RemoveEntityById(FWorld.Context.Pool.Slots[LSlot]^.Id)
  else
    FWorld.Combat.TakeDamage(LSlot, 200, 200);
end;

procedure TFullScenario.OpAiHall;
var
  LKind: Integer;
  LColumn: Integer;
  LRow: Integer;
  LRace: TWarRace;
  LHall: Integer;
  LX: Integer;
  LY: Integer;
  LWorker: Integer;
begin
  LKind := ScriptBelow(2);
  LColumn := ScriptBelow(5);
  LRow := ScriptBelow(3);
  LRace := FWorld.Context.Players[1]^.Race;
  LHall := TWarUnitClassifier.TypeForRace(WAR_UNIT_TOWNHALL_HUMANS, LRace);
  LX := 34 + 4 * LColumn;
  LY := 44 + 4 * LRow;
  if LKind = 0 then
  begin
    SpawnBuilding(LHall, 1, LX, LY);
    Exit;
  end;
  // a town hall under construction: a worker of the player 1 places it
  LWorker := SpawnDude(TWarUnitClassifier.TypeForRace(WAR_UNIT_PEON, LRace), 1, LX - 2, LY);
  if LWorker = 0 then
    Exit;
  FCommands.Construction.PlaceBuilding(LWorker, LHall, LX, LY);
end;

procedure TFullScenario.OpAiPreempt;
var
  LBuilding: Integer;
  LType: Integer;
  LUnit: Integer;
begin
  LBuilding := PickWhere(PICK_ENEMY_BUILDING);
  if LBuilding = 0 then
    Exit;
  LType := FWorld.Context.Pool.Slots[LBuilding]^.UnitData.UnitType;
  if LType = WAR_UNIT_TOWNHALL_ORCS then
    LUnit := WAR_UNIT_PEON
  else if LType = WAR_UNIT_TOWNHALL_HUMANS then
    LUnit := WAR_UNIT_PEASANT
  else if LType = WAR_UNIT_BARRACKS_ORCS then
    LUnit := WAR_UNIT_GRUNT
  else if LType = WAR_UNIT_BARRACKS_HUMANS then
    LUnit := WAR_UNIT_FOOTMAN
  else
    Exit;
  // an order of the PLAYER to a building of the computer: the same train order with the cause of the player
  FCommands.Construction.OrderTrain(LBuilding, LUnit, WAR_CAUSE_PLAYER_ORDER);
end;

procedure TFullScenario.OpAiCancel;
var
  LBuilding: Integer;
begin
  LBuilding := PickWhere(PICK_ENEMY_BUILDING);
  if LBuilding = 0 then
    Exit;
  SelectOnly(LBuilding);
  FCommands.Execute(WAR_COMMAND_CANCEL);
end;

procedure TFullScenario.OpAiDamage;
var
  LMin: Integer;
  LRnd: Integer;
  LWhich: Integer;
  LSlot: Integer;
begin
  LMin := ScriptBelow(300);
  LRnd := ScriptBelow(400);
  LWhich := ScriptBelow(2);
  if LWhich <> 0 then
    LSlot := PickWhere(PICK_AI_HALL)
  else
    LSlot := PickWhere(PICK_ENEMY_BUILDING);
  if LSlot = 0 then
    Exit;
  FWorld.Combat.TakeDamage(LSlot, LMin, LRnd);
end;

procedure TFullScenario.OpAiTime;
begin
  FWorld.Context.RealTime := FWorld.Context.RealTime + ScriptBelow(20);
end;

procedure TFullScenario.OpAiHurry;
begin
  FWorld.Context.HurryUp := not FWorld.Context.HurryUp;
end;

procedure TFullScenario.RunOp(AIndex: Integer);
begin
  case AIndex of
    0: SelectMany(PICK_OWN_DUDE, 5);
    1: SelectMany(PICK_OWN_WARRIOR, 4);
    2: SelectMany(PICK_OWN_WORKER, 3);
    3: OpMove;
    4: FCommands.Execute(WAR_COMMAND_STOP);
    5: OpAttackUnit;
    6: OpAttackPoint;
    7: OpAttackWall;
    8: OpHarvestMine;
    9: OpHarvestTree;
    10: OpDeliver;
    11: OpRepair;
    12: OpRight;
    13: OpTrain;
    14: OpUpgrade;
    15: OpCancel;
    16: OpBuild;
    17: OpWallOrRoad(True);
    18: OpWallOrRoad(False);
    19: OpGroup;
    20: OpHurt;
    21: OpDamageBuilding;
    22: OpWallDamage;
    23: OpAi;
    24: OpEconomy;
    25: OpRemove;
    26: OpSummon;
    27: OpRain;
    28: OpPoison;
    29: OpOnFriend(WAR_COMMAND_SPELL_HEALING);
    30: OpOnFriend(WAR_COMMAND_SPELL_INVISIBILITY);
    31: OpOnFriend(WAR_COMMAND_SPELL_UNHOLY_ARMOR);
    32: OpRaise;
    33: OpSight;
    34: OpMana;
    35: OpAiEconomy;
    36: OpAiFarm;
    37: OpAiHall;
    38: OpAiPreempt;
    39: OpAiCancel;
    40: OpAiDamage;
    41: OpAiTime;
    42: OpAiHurry;
  end;
end;

procedure TFullScenario.ScriptStep;
var
  LRoll: Integer;
  LSum: Integer;
  LIndex: Integer;
begin
  Prune;
  LRoll := ScriptBelow(1000);
  LSum := 0;
  for LIndex := 0 to High(OPS) do
  begin
    Inc(LSum, OPS[LIndex].Weights[FMode]);
    if LRoll < LSum then
    begin
      RunOp(LIndex);
      Exit;
    end;
  end;
end;

procedure TFullScenario.Tick;
begin
  FWorld.AdvanceClock(FDelta);
  // the real time of the scenarios with the computer: the length of the tic times a factor of the seed
  if FMode = fmAi then
    FWorld.Context.RealTime := FWorld.Context.RealTime + Double(FDelta) * FRealFactor;
  ScriptStep;
  FWorld.Update;
  FWorld.FinishTic;
end;

procedure TFullScenario.DumpAi(const AText: TStringBuilder);

  function DoubleBits(AValue: Double): string;
  var
    LBits: UInt64;
  begin
    LBits := PUInt64(@AValue)^;
    Result := LowerCase(IntToHex(Cardinal(LBits shr 32), 8) + IntToHex(Cardinal(LBits and $FFFFFFFF), 8));
  end;

var
  LPlayer: TWarComputerPlayer;
  LCommand: TWarAiCommand;
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateTrain;
begin
  LContext := FWorld.Context;
  LPlayer := FAi.FindPlayer(1);
  // the line I of dumpAi: the ids, how far the script went, the running commands and their state
  AText.AppendFormat('I id=%u idx=%d rt=%s cur=%d nxt=%d', [LPlayer.StaticCommandId, LPlayer.ScriptIndex,
    DoubleBits(LContext.RealTime), LPlayer.CurrentCount, LPlayer.NextCount]);
  for LIndex := 0 to LPlayer.CurrentCount - 1 do
  begin
    LCommand := LPlayer.Current[LIndex];
    AText.AppendFormat(' %u,%d,%d,', [LCommand.Id, LCommand.CommandType, LCommand.Status]);
    if LCommand.CommandType = WAR_AI_COMMAND_SLEEP then
      AText.Append(DoubleBits(LCommand.EndRealTime))
    else
      AText.AppendFormat('%d,%d', [LCommand.UnitType, LCommand.Count]);
  end;
  AText.Append(#10);
  // the line J: the request that each training state keeps
  AText.Append('J');
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
    if LContext.Storage.Occupied[WAR_STATE_TRAIN, LIndex] then
    begin
      LState := PWarStateTrain(LContext.Storage.StateAt(WAR_STATE_TRAIN, LIndex));
      AText.AppendFormat(' %d:%u', [LIndex, TWarAiCommand.HandleId(LState^.AiCommand)]);
    end;
  AText.Append(#10);
end;

function TFullScenario.DumpNow(ATic: Integer): string;
var
  LText: TStringBuilder;
  LContext: TWarModelContext;
  LSlot: Integer;
  LEntity: PWarEntity;
  LIndex: Integer;
  LGroup: Integer;
  LPiece: PWarWallPiece;
  LRuins: TArray<TWarRuinPiece>;
  LRoad: TArray<TWarLinePiece>;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LAnimation: PWarAnimation;
  LTop: Single;

  function Bits(AValue: Single): string;
  begin
    Result := LowerCase(IntToHex(PCardinal(@AValue)^, 8));
  end;

begin
  LContext := FWorld.Context;
  LText := TStringBuilder.Create;
  try
    if Assigned(FSteering) then
      LText.Append(TModelDump.Dump(FWorld, FGrid, FObserver, ATic, FResults, True, FSteering.Fields, FFog))
    else
      LText.Append(TModelDump.Dump(FWorld, FGrid, FObserver, ATic, FResults, True));
    // the lines of the construction scenarios (dumpConstruction)
    LText.AppendFormat('X audio=%u mix=%s hurry=%d'#10, [FObserver.AudioCount, LowerCase(IntToHex(FObserver.AudioMix, 8)),
      Ord(LContext.HurryUp)]);
    for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    begin
      LEntity := LContext.Pool.Slots[LSlot];
      if (LEntity^.Id = 0) or not LEntity^.HasUnit then
        Continue;
      LText.AppendFormat('Y slot=%d', [LSlot]);
      if LEntity^.HasSprite then
        LText.AppendFormat(' en=%d fr=%d fi=%d', [Ord(LEntity^.SpriteEnabled), LEntity^.SpriteFrames,
          LEntity^.SpriteFrame])
      else
        LText.Append(' nosprite');
      if LEntity^.HasTransform then
        LText.AppendFormat(' sx=%s', [Bits(LEntity^.ScaleX)]);
      LText.Append(#10);
    end;
    LRuins := LContext.Ruins.Pieces;
    LText.AppendFormat('R %d', [Length(LRuins)]);
    for LIndex := 0 to High(LRuins) do
      LText.AppendFormat(' %d,%d,%d', [LRuins[LIndex].PieceType, LRuins[LIndex].TileX, LRuins[LIndex].TileY]);
    LText.Append(#10);
    LText.AppendFormat('V %d', [LContext.Walls.Count]);
    for LIndex := 0 to LContext.Walls.Count - 1 do
    begin
      LPiece := LContext.Walls[LIndex];
      LText.AppendFormat(' %d,%d/%d,%d,%d,%d', [LPiece^.PieceType, LPiece^.Hp, LPiece^.MaxHp, LPiece^.TileX,
        LPiece^.TileY, LPiece^.Player]);
    end;
    LText.Append(#10);
    // the lines of dumpFull
    LTop := LContext.ViewportTop;
    LText.AppendFormat('U vy=%s sel=%d', [Bits(LTop), LContext.Selection.Count]);
    for LIndex := 0 to LContext.Selection.Count - 1 do
      LText.AppendFormat(' %d', [LContext.Selection[LIndex]]);
    for LGroup := 0 to WAR_MODEL_SELECTION_GROUPS - 1 do
    begin
      LText.AppendFormat(' g%d=%d', [LGroup, LContext.Selection.GroupCount(LGroup)]);
      for LIndex := 0 to LContext.Selection.GroupCount(LGroup) - 1 do
        LText.AppendFormat(':%d', [LContext.Selection.GroupItem(LGroup, LIndex)]);
    end;
    LText.Append(#10);
    LRoad := LContext.Roads.Pieces;
    LText.AppendFormat('D %d', [Length(LRoad)]);
    for LIndex := 0 to High(LRoad) do
      LText.AppendFormat(' %d,%d,%d,%d', [LRoad[LIndex].PieceType, LRoad[LIndex].TileX, LRoad[LIndex].TileY,
        LRoad[LIndex].Player]);
    LText.Append(#10);
    LText.AppendFormat('M n=%u h=%s'#10, [FPainter.Writes, LowerCase(IntToHex(FPainter.Hash, 8))]);
    for LIndex := 0 to FForests.Count - 1 do
    begin
      LForest := FForests[LIndex];
      LText.AppendFormat('F id=%d n=%d', [LForest.Id, LForest.Trees.Count]);
      for LTree in LForest.Trees do
        LText.AppendFormat(' %d,%d,%d,%d', [LTree.TileX, LTree.TileY, LTree.Amount, LTree.TileType]);
      LText.Append(#10);
    end;
    for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    begin
      LEntity := LContext.Pool.Slots[LSlot];
      if LEntity^.Id = 0 then
        Continue;
      if LEntity^.AnimationCount > 0 then
      begin
        LText.AppendFormat('A slot=%d n=%d', [LSlot, LEntity^.AnimationCount]);
        for LIndex := 0 to LEntity^.AnimationCount - 1 do
        begin
          LAnimation := @LEntity^.Animations[LIndex];
          LText.AppendFormat(' %d,%d,%d,%d,%s,%s,%s', [LAnimation^.Kind, Ord(LAnimation^.Loop), LAnimation^.Status,
            LAnimation^.FramesCount, Bits(LAnimation^.FrameDelay), Bits(LAnimation^.AnimTime),
            Bits(LAnimation^.LoopTime)]);
        end;
        LText.Append(#10);
      end;
      if LEntity^.HasSight then
        LText.AppendFormat('S slot=%d %s,%s %s'#10, [LSlot, Bits(LEntity^.SpellTile.X), Bits(LEntity^.SpellTile.Y),
          Bits(LEntity^.SpellTime)]);
      if LEntity^.HasPoisonCloud then
        LText.AppendFormat('Q slot=%d %s,%s %s %s'#10, [LSlot, Bits(LEntity^.SpellTile.X), Bits(LEntity^.SpellTile.Y),
          Bits(LEntity^.SpellTime), Bits(LEntity^.SpellDamageTime)]);
      if LEntity^.EntityType = WAR_ENTITY_UNIT then
        LText.AppendFormat('K %d spr=%d'#10, [LEntity^.Id, LEntity^.SpriteResource - Ord(LEntity^.SpriteResource = 0)]);
    end;
    if FMode = fmAi then
      DumpAi(LText);
    Result := LText.ToString;
  finally
    LText.Free;
  end;
end;

class procedure TFullScenario.Run(AMode: TFullMode; ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings;
  out ADumpText: string; AReal: Boolean);
const
  PREFIX: array[TFullMode] of Char = ('O', 'I', 'A', 'W');
var
  LScenario: TFullScenario;
  LTic: Integer;
  LTics: Integer;
  LText: string;
begin
  ADumpText := '';
  LTics := ScenarioTics(AMode);
  LScenario := TFullScenario.Create;
  try
    LScenario.Setup(ASeed, AMode, AReal);
    try
      for LTic := 0 to LTics - 1 do
      begin
        LScenario.Tick;
        if (ADumpTic >= 0) and (LTic <> ADumpTic) then
          Continue;
        LText := LScenario.DumpNow(LTic);
        if LTic = ADumpTic then
        begin
          ADumpText := LText;
          Break;
        end
        else if Assigned(ALines) then
          ALines.Add(Format('%s %u %d %s %d', [PREFIX[AMode], ASeed, LTic,
            LowerCase(IntToHex(TModelDump.Fnv1a(LText), 8)), LScenario.FWorld.Context.Pool.EntityCount]));
      end;
    finally
      LScenario.Teardown;
    end;
  finally
    LScenario.Free;
  end;
end;

class procedure TFullScenario.AiCoverage(ASeed: Cardinal; out ALastCommandId: Cardinal; out AScriptIndex: Integer;
  out AProgressCalls, ASleepTics: Integer);
var
  LScenario: TFullScenario;
  LTic: Integer;
  LIndex: Integer;
  LContext: TWarModelContext;
  LPlayer: TWarComputerPlayer;
  LSleeping: Boolean;
  LProbe: TProgressProbe;
begin
  AProgressCalls := 0;
  ASleepTics := 0;
  LScenario := TFullScenario.Create;
  try
    LScenario.Setup(ASeed, fmAi, False);
    try
      LContext := LScenario.FWorld.Context;
      LPlayer := LScenario.FAi.FindPlayer(1);
      // a probe between the training states and the AI counts what they tell it
      LProbe := TProgressProbe.Create(LScenario.FAi);
      LContext.AiProgress := LProbe;
      for LTic := 0 to AI_SCENARIO_TICS - 1 do
      begin
        LScenario.Tick;
        LSleeping := False;
        for LIndex := 0 to LPlayer.CurrentCount - 1 do
          if LPlayer.Current[LIndex].CommandType = WAR_AI_COMMAND_SLEEP then
            LSleeping := True;
        Inc(ASleepTics, Ord(LSleeping));
      end;
      AProgressCalls := LProbe.Calls;
      ALastCommandId := LPlayer.StaticCommandId;
      AScriptIndex := LPlayer.ScriptIndex;
    finally
      LScenario.Teardown;
    end;
  finally
    LScenario.Free;
  end;
end;

class function TFullScenario.ScenarioTics(AMode: TFullMode): Integer;
begin
  if AMode = fmAi then
    Result := AI_SCENARIO_TICS
  else
    Result := FULL_SCENARIO_TICS;
end;

class procedure TFullScenario.Coverage(AMode: TFullMode; ASeed: Cardinal; out AStates, AEntities: TArray<Integer>);
var
  LScenario: TFullScenario;
  LTic: Integer;
  LType: Integer;
  LSlot: Integer;
  LSeen: array[0..WAR_ENTITY_TYPE_COUNT - 1] of Boolean;
  LEntity: PWarEntity;
begin
  SetLength(AStates, WAR_STATE_COUNT);
  SetLength(AEntities, WAR_ENTITY_TYPE_COUNT);
  LScenario := TFullScenario.Create;
  try
    LScenario.Setup(ASeed, AMode, False);
    try
      for LTic := 0 to ScenarioTics(AMode) - 1 do
      begin
        LScenario.Tick;
        for LType := 0 to WAR_STATE_COUNT - 1 do
          if LScenario.FWorld.Context.Storage.ActiveCount[LType] > 0 then
            Inc(AStates[LType]);
        for LType := 0 to High(LSeen) do
          LSeen[LType] := False;
        for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
        begin
          LEntity := LScenario.FWorld.Context.Pool.Slots[LSlot];
          if (LEntity^.Id <> 0) and (LEntity^.EntityType < WAR_ENTITY_TYPE_COUNT) then
            LSeen[LEntity^.EntityType] := True;
        end;
        for LType := 0 to High(LSeen) do
          if LSeen[LType] then
            Inc(AEntities[LType]);
      end;
    finally
      LScenario.Teardown;
    end;
  finally
    LScenario.Free;
  end;
end;

end.
