{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of building and         }
{  training                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.Commands.Construction, DelphiDoom.Tests.War.ConstructionObserver;

type
  /// <summary>
  ///   The scenarios of construction of war_construction_ref.inc (Tools\Verifica\194) written again: the same base (twelve
  ///   buildings of the player 0 and five units), the same script (the LCG of the seed, the same operations drawn in the
  ///   same order) and the same text of the state, so that the model of Delphi lives the same life as the original. The
  ///   orders are the ones of TWarConstructionCommands, where the C calls the true wcmd_* functions
  /// </summary>
  TConstructionScenario = class
  strict private
    FScriptState: Cardinal;
    FResults: Cardinal;
    FSpawned: array[0..255] of Word;
    FSpawnedCount: Integer;
    FDelta: Single;
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FObserver: TConstructionObserver;
    FCommands: TWarConstructionCommands;
    function ScriptBelow(ALimit: Cardinal): Integer;
    procedure ResultMix(AValue: Cardinal);
    procedure Setup(ASeed: Cardinal);
    function SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer): Integer;
    procedure SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
    function PickWhere(AKind: Integer): Integer;
    procedure OpBuild;
    procedure OpTrain;
    procedure OpUpgrade;
    procedure OpCancel;
    procedure OpRepair;
    procedure OpDamageBuilding;
    procedure OpWall;
    procedure OpWallDamage;
    procedure OpPopAny;
    procedure OpEconomy;
    procedure OpRemove;
    procedure ScriptStep;
    procedure Tick;
    function DumpNow(ATic: Integer): string;
  public
    /// <summary>
    ///   Runs the scenario of the seed. For each tic ALines gets 'C seed tic hash entities'; with ADumpTic >= 0 the lines
    ///   are not written and ADumpText is the text of the state at that tic
    /// </summary>
    class procedure Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string); static;
    /// <summary>
    ///   Runs the scenario of the seed and counts, for each type of state, the tics in which at least one state of that type
    ///   was active (the same numbers that `WAR_REF_COVER=1 war_model_ref construction` prints)
    /// </summary>
    class function Coverage(ASeed: Cardinal): TArray<Integer>; static;
  end;

const
  CONSTRUCTION_SCENARIO_TICS = 400;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Walls,
  DelphiDoom.War.Model.TerrainEntities, DelphiDoom.War.Model.Construction.Types, DelphiDoom.Tests.War.ModelDump,
  DelphiDoom.Tests.War.ModelObserver, DelphiDoom.War.Autotile.Types;

{$Q-}
{$R-}

type
  TTrainEntry = record
    UnitType: Integer;
    Building: Integer;
  end;

const
  BUILD_TYPES: array[0..15] of Integer = (WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_HUMANS,
    WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_CHURCH, WAR_UNIT_TEMPLE, WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS,
    WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_LUMBERMILL_ORCS,
    WAR_UNIT_STABLE, WAR_UNIT_KENNEL, WAR_UNIT_BLACKSMITH_HUMANS, WAR_UNIT_BLACKSMITH_ORCS);
  TRAIN_TABLE: array[0..13] of TTrainEntry = (
    (UnitType: WAR_UNIT_FOOTMAN; Building: WAR_UNIT_BARRACKS_HUMANS),
    (UnitType: WAR_UNIT_GRUNT; Building: WAR_UNIT_BARRACKS_ORCS),
    (UnitType: WAR_UNIT_PEASANT; Building: WAR_UNIT_TOWNHALL_HUMANS),
    (UnitType: WAR_UNIT_PEON; Building: WAR_UNIT_TOWNHALL_ORCS),
    (UnitType: WAR_UNIT_CATAPULT_HUMANS; Building: WAR_UNIT_BARRACKS_HUMANS),
    (UnitType: WAR_UNIT_CATAPULT_ORCS; Building: WAR_UNIT_BARRACKS_ORCS),
    (UnitType: WAR_UNIT_KNIGHT; Building: WAR_UNIT_BARRACKS_HUMANS),
    (UnitType: WAR_UNIT_RAIDER; Building: WAR_UNIT_BARRACKS_ORCS),
    (UnitType: WAR_UNIT_ARCHER; Building: WAR_UNIT_BARRACKS_HUMANS),
    (UnitType: WAR_UNIT_SPEARMAN; Building: WAR_UNIT_BARRACKS_ORCS),
    (UnitType: WAR_UNIT_CONJURER; Building: WAR_UNIT_TOWER_HUMANS),
    (UnitType: WAR_UNIT_WARLOCK; Building: WAR_UNIT_TOWER_ORCS),
    (UnitType: WAR_UNIT_CLERIC; Building: WAR_UNIT_CHURCH),
    (UnitType: WAR_UNIT_NECROLYTE; Building: WAR_UNIT_TEMPLE));
  DELTAS: array[0..3] of Single = (0.016666668, 0.25, 2.0, 5.0);
  PICK_WORKER = 0;
  PICK_BUILDING = 1;
  PICK_ANY_OWN = 2;

type
  TBaseBuilding = record
    UnitType: Integer;
    X: Integer;
    Y: Integer;
  end;

const
  BASE_BUILDINGS: array[0..16] of TBaseBuilding = (
    (UnitType: WAR_UNIT_TOWNHALL_HUMANS; X: 6; Y: 6), (UnitType: WAR_UNIT_BARRACKS_HUMANS; X: 11; Y: 6),
    (UnitType: WAR_UNIT_BARRACKS_ORCS; X: 16; Y: 6), (UnitType: WAR_UNIT_CHURCH; X: 21; Y: 6),
    (UnitType: WAR_UNIT_TEMPLE; X: 26; Y: 6), (UnitType: WAR_UNIT_FARM_HUMANS; X: 31; Y: 6),
    (UnitType: WAR_UNIT_TOWER_HUMANS; X: 6; Y: 12), (UnitType: WAR_UNIT_TOWER_ORCS; X: 11; Y: 12),
    (UnitType: WAR_UNIT_BLACKSMITH_HUMANS; X: 16; Y: 12), (UnitType: WAR_UNIT_BLACKSMITH_ORCS; X: 21; Y: 12),
    (UnitType: WAR_UNIT_TOWNHALL_ORCS; X: 26; Y: 12), (UnitType: WAR_UNIT_FARM_ORCS; X: 31; Y: 12),
    (UnitType: WAR_UNIT_FARM_HUMANS; X: 35; Y: 6), (UnitType: WAR_UNIT_FARM_HUMANS; X: 35; Y: 9),
    (UnitType: WAR_UNIT_FARM_ORCS; X: 35; Y: 12), (UnitType: WAR_UNIT_FARM_ORCS; X: 35; Y: 15),
    (UnitType: WAR_UNIT_LUMBERMILL_HUMANS; X: 6; Y: 16));
  BASE_DUDES: array[0..4] of TBaseBuilding = (
    (UnitType: WAR_UNIT_PEASANT; X: 6; Y: 20), (UnitType: WAR_UNIT_PEASANT; X: 9; Y: 20),
    (UnitType: WAR_UNIT_PEON; X: 12; Y: 20), (UnitType: WAR_UNIT_FOOTMAN; X: 15; Y: 20),
    (UnitType: WAR_UNIT_GRUNT; X: 18; Y: 20));

{ TConstructionScenario }

function TConstructionScenario.ScriptBelow(ALimit: Cardinal): Integer;
begin
  Result := 0;
  if ALimit <> 0 then
  begin
    FScriptState := FScriptState * 1664525 + 1013904223;
    Result := Integer((FScriptState shr 8) mod ALimit);
  end;
end;

procedure TConstructionScenario.ResultMix(AValue: Cardinal);
begin
  FResults := (FResults * 16777619) xor AValue;
end;

procedure TConstructionScenario.Setup(ASeed: Cardinal);
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
  LIndex: Integer;
  LZeros: TArray<Word>;
  LSlot: Integer;
begin
  FObserver := TConstructionObserver.Create(ASeed xor $A5A5A5A5);
  FScriptState := ASeed * 2654435761 + 12345;
  FResults := 2166136261;
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FWorld.Context.ConstructionHost := FObserver;
  // the C of the golden was built with gcc, where the enum of the directions is unsigned
  FWorld.Context.UnsignedDirections := True;
  FCommands := TWarConstructionCommands.Create(FWorld.Context, FWorld.Machine, FWorld.Economy);
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
  FWorld.Context.HurryUp := (ASeed mod 3 = 0) or (ASeed mod 4 = 0);
  FSpawnedCount := 0;
  FWorld.Context.Players[0]^.Gold := 1500 + ScriptBelow(9000);
  FWorld.Context.Players[0]^.Wood := 800 + ScriptBelow(6000);
  // the map makes the entity of the wall (with its idle state) and the one of the ruins before its units
  LSlot := TWarTerrainEntities.CreateWall(FWorld.Context, FWorld.Machine);
  Assert(LSlot <> 0);
  LSlot := TWarTerrainEntities.CreateRuins(FWorld.Context);
  Assert(LSlot <> 0);
  for LIndex := 0 to High(BASE_BUILDINGS) do
    SpawnBuilding(BASE_BUILDINGS[LIndex].UnitType, 0, BASE_BUILDINGS[LIndex].X, BASE_BUILDINGS[LIndex].Y);
  for LIndex := 0 to High(BASE_DUDES) do
    SpawnDude(BASE_DUDES[LIndex].UnitType, 0, BASE_DUDES[LIndex].X, BASE_DUDES[LIndex].Y);
end;

function TConstructionScenario.SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer): Integer;
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

procedure TConstructionScenario.SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
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

function TConstructionScenario.PickWhere(AKind: Integer): Integer;
var
  LUnits: TList<Integer>;
  LStart: Integer;
  LCount: Integer;
  LStep: Integer;
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LMatch: Boolean;
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
    LUnit := @FWorld.Context.Pool.Slots[LSlot]^.UnitData;
    LMatch := LUnit^.Player = 0;
    case AKind of
      PICK_WORKER:
        LMatch := LMatch and TWarUnitClassifier.IsDude(LUnit^.UnitType) and TWarUnitClassifier.IsWorker(LUnit^.UnitType) and
          not FWorld.Machine.IsDead(LSlot) and not FWorld.Machine.IsGoingToDie(LSlot);
      PICK_BUILDING:
        LMatch := LMatch and TWarUnitClassifier.IsBuilding(LUnit^.UnitType);
    end;
    if LMatch then
      Exit(LSlot);
  end;
  Result := 0;
end;

procedure TConstructionScenario.OpBuild;
var
  LWorker: Integer;
  LTypeIndex: Integer;
  LRow: Integer;
  LType: Integer;
  LSizeX: Integer;
  LSizeY: Integer;
  LTile: TWarVec2;
  LX: Integer;
  LY: Integer;
begin
  LWorker := PickWhere(PICK_WORKER);
  LTypeIndex := ScriptBelow(16);
  LRow := ScriptBelow(4);
  if LWorker = 0 then
    Exit;
  LType := BUILD_TYPES[LTypeIndex];
  FWorld.Context.Database.TryGetUnitSize(LType, LSizeX, LSizeY);
  LTile := TWarUnitGeometry.CenterTile(FWorld.Context.Pool.Slots[LWorker]);
  LX := Trunc(LTile.X) + 1;
  LY := Trunc(LTile.Y) - (LRow mod LSizeY);
  if LY < 0 then
    LY := 0;
  if FCommands.CheckTileToBuild(LType, LX, LY) then
    ResultMix(Ord(FCommands.TryPlaceBuilding(LWorker, LType, LX, LY)))
  else
    FObserver.PlaySound(WAR_SOUND_UI_CANCEL);
end;

procedure TConstructionScenario.OpTrain;
var
  LBuilding: Integer;
  LK: Integer;
  LType: Integer;
  LMatches: array[0..13] of Integer;
  LCount: Integer;
  LIndex: Integer;
begin
  LBuilding := PickWhere(PICK_BUILDING);
  LK := ScriptBelow(4);
  if LBuilding = 0 then
    Exit;
  LType := FWorld.Context.Pool.Slots[LBuilding]^.UnitData.UnitType;
  LCount := 0;
  for LIndex := 0 to 13 do
    if TRAIN_TABLE[LIndex].Building = LType then
    begin
      LMatches[LCount] := LIndex;
      Inc(LCount);
    end;
  if LCount = 0 then
    Exit;
  FCommands.OrderTrain(LBuilding, TRAIN_TABLE[LMatches[LK mod LCount]].UnitType);
  // wcmd_executeCommand answers True whatever the order did
  ResultMix(1);
end;

procedure TConstructionScenario.OpUpgrade;
var
  LBuilding: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
begin
  LBuilding := PickWhere(PICK_BUILDING);
  LUpgrade := ScriptBelow(19);
  if LBuilding = 0 then
    Exit;
  LInfo := FWorld.Context.Players[0];
  if LInfo^.Upgrades[LUpgrade div 2].Level >= LInfo^.Upgrades[LUpgrade div 2].Allowed then
    Exit;
  if LInfo^.Upgrades[LUpgrade div 2].Level + FCommands.UpgradesInProgress(0, LUpgrade div 2) >=
    LInfo^.Upgrades[LUpgrade div 2].Allowed then
    Exit;
  FCommands.OrderUpgrade(LBuilding, LUpgrade);
  ResultMix(1);
end;

procedure TConstructionScenario.OpCancel;
var
  LBuilding: Integer;
begin
  LBuilding := PickWhere(PICK_BUILDING);
  if LBuilding = 0 then
    Exit;
  FCommands.Cancel(LBuilding);
end;

procedure TConstructionScenario.OpRepair;
var
  LBuilding: Integer;
  LKind: Integer;
  LSide: Integer;
  LUnit: PWarUnitComponent;
  LX: Integer;
  LY: Integer;
  LWorker: Integer;
begin
  LBuilding := PickWhere(PICK_BUILDING);
  LKind := ScriptBelow(2);
  LSide := ScriptBelow(4);
  if LBuilding = 0 then
    Exit;
  LUnit := @FWorld.Context.Pool.Slots[LBuilding]^.UnitData;
  LX := LUnit^.TileX - 1;
  LY := LUnit^.TileY + (LSide mod LUnit^.SizeY);
  if LX < 0 then
    Exit;
  if LKind <> 0 then
    LWorker := SpawnDude(WAR_UNIT_PEON, 0, LX, LY)
  else
    LWorker := SpawnDude(WAR_UNIT_PEASANT, 0, LX, LY);
  if LWorker = 0 then
    Exit;
  FCommands.OrderRepair([LWorker], LBuilding);
end;

procedure TConstructionScenario.OpDamageBuilding;
var
  LBuilding: Integer;
  LMin: Integer;
  LRnd: Integer;
begin
  LBuilding := PickWhere(PICK_BUILDING);
  LMin := ScriptBelow(200);
  LRnd := ScriptBelow(300);
  if LBuilding = 0 then
    Exit;
  FWorld.Combat.TakeDamage(LBuilding, LMin, LRnd);
end;

procedure TConstructionScenario.OpWall;
var
  LNear: Integer;
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LLast: PWarWallPiece;
const
  DX: array[0..3] of Integer = (0, 1, 0, -1);
  DY: array[0..3] of Integer = (-1, 0, 1, 0);
begin
  LNear := ScriptBelow(100);
  LDirection := ScriptBelow(4);
  LX := 6 + ScriptBelow(40);
  LY := 30 + ScriptBelow(10);
  if (LNear < 70) and (FWorld.Context.Walls.Count > 0) then
  begin
    LLast := FWorld.Context.Walls[FWorld.Context.Walls.Count - 1];
    LX := LLast^.TileX + DX[LDirection];
    LY := LLast^.TileY + DY[LDirection];
  end;
  FCommands.PlaceWall(0, LX, LY);
end;

procedure TConstructionScenario.OpWallDamage;
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

procedure TConstructionScenario.OpPopAny;
var
  LSlot: Integer;
begin
  LSlot := PickWhere(PICK_ANY_OWN);
  if LSlot = 0 then
    Exit;
  FWorld.Machine.PopState(LSlot, WAR_CAUSE_PLAYER_ORDER, WAR_RESULT_CANCELLED);
end;

procedure TConstructionScenario.OpEconomy;
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

procedure TConstructionScenario.OpRemove;
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

procedure TConstructionScenario.ScriptStep;
var
  LRoll: Integer;
begin
  LRoll := ScriptBelow(100);
  if LRoll < 6 then
    OpBuild
  else if LRoll < 13 then
    OpTrain
  else if LRoll < 16 then
    OpUpgrade
  else if LRoll < 18 then
    OpCancel
  else if LRoll < 20 then
    OpRepair
  else if LRoll < 26 then
    OpDamageBuilding
  else if LRoll < 29 then
    OpWall
  else if LRoll < 31 then
    OpWallDamage
  else if LRoll < 33 then
    OpEconomy
  else if LRoll < 34 then
    OpRemove
  else if LRoll < 36 then
    OpPopAny;
end;

procedure TConstructionScenario.Tick;
begin
  FWorld.AdvanceClock(FDelta);
  ScriptStep;
  FWorld.Update;
  FWorld.UpdateActions;
end;

function TConstructionScenario.DumpNow(ATic: Integer): string;
var
  LText: string;
  LSlot: Integer;
  LEntity: PWarEntity;
  LIndex: Integer;
  LPiece: PWarWallPiece;
  LRuins: TArray<TWarRuinPiece>;
begin
  LText := TModelDump.Dump(FWorld, FGrid, FObserver, ATic, FResults);
  LText := LText + Format('X audio=%u mix=%s hurry=%d'#10, [FObserver.AudioCount,
    LowerCase(IntToHex(FObserver.AudioMix, 8)), Ord(FWorld.Context.HurryUp)]);
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FWorld.Context.Pool.Slots[LSlot];
    if (LEntity^.Id = 0) or not LEntity^.HasUnit then
      Continue;
    LText := LText + Format('Y slot=%d', [LSlot]);
    if LEntity^.HasSprite then
      LText := LText + Format(' en=%d fr=%d fi=%d', [Ord(LEntity^.SpriteEnabled), LEntity^.SpriteFrames,
        LEntity^.SpriteFrame])
    else
      LText := LText + ' nosprite';
    if LEntity^.HasTransform then
      LText := LText + Format(' sx=%s', [LowerCase(IntToHex(PCardinal(@LEntity^.ScaleX)^, 8))]);
    LText := LText + #10;
  end;
  LRuins := FWorld.Context.Ruins.Pieces;
  LText := LText + Format('R %d', [Length(LRuins)]);
  for LIndex := 0 to High(LRuins) do
    LText := LText + Format(' %d,%d,%d', [LRuins[LIndex].PieceType, LRuins[LIndex].TileX, LRuins[LIndex].TileY]);
  LText := LText + #10;
  LText := LText + Format('V %d', [FWorld.Context.Walls.Count]);
  for LIndex := 0 to FWorld.Context.Walls.Count - 1 do
  begin
    LPiece := FWorld.Context.Walls[LIndex];
    LText := LText + Format(' %d,%d/%d,%d,%d,%d', [LPiece^.PieceType, LPiece^.Hp, LPiece^.MaxHp, LPiece^.TileX,
      LPiece^.TileY, LPiece^.Player]);
  end;
  LText := LText + #10;
  Result := LText;
end;

class function TConstructionScenario.Coverage(ASeed: Cardinal): TArray<Integer>;
var
  LScenario: TConstructionScenario;
  LTic: Integer;
  LType: Integer;
begin
  SetLength(Result, WAR_STATE_COUNT);
  LScenario := TConstructionScenario.Create;
  try
    LScenario.Setup(ASeed);
    try
      for LTic := 0 to CONSTRUCTION_SCENARIO_TICS - 1 do
      begin
        LScenario.Tick;
        for LType := 0 to WAR_STATE_COUNT - 1 do
          if LScenario.FWorld.Context.Storage.ActiveCount[LType] > 0 then
            Inc(Result[LType]);
      end;
    finally
      LScenario.FCommands.Free;
      LScenario.FWorld.Free;
      LScenario.FGrid.Free;
    end;
  finally
    LScenario.Free;
  end;
end;

class procedure TConstructionScenario.Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings;
  out ADumpText: string);
var
  LScenario: TConstructionScenario;
  LTic: Integer;
  LText: string;
begin
  ADumpText := '';
  LScenario := TConstructionScenario.Create;
  try
    LScenario.Setup(ASeed);
    try
      for LTic := 0 to CONSTRUCTION_SCENARIO_TICS - 1 do
      begin
        LScenario.Tick;
        LText := LScenario.DumpNow(LTic);
        if (ADumpTic >= 0) and (LTic = ADumpTic) then
        begin
          ADumpText := LText;
          Break;
        end
        else if (ADumpTic < 0) and Assigned(ALines) then
          ALines.Add(Format('C %u %d %s %d', [ASeed, LTic, LowerCase(IntToHex(TModelDump.Fnv1a(LText), 8)),
            LScenario.FWorld.Context.Pool.EntityCount]));
      end;
    finally
      LScenario.FCommands.Free;
      LScenario.FWorld.Free;
      LScenario.FGrid.Free;
    end;
  finally
    LScenario.Free;
  end;
end;

end.
