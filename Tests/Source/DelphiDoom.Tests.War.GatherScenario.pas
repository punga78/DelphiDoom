{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of gathering            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.GatherScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Forests, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.GatherWorld, DelphiDoom.Tests.War.ModelObserver;

type
  /// <summary>
  ///   IWarTilePainter that only remembers what was written, in order: the number of the writes and the FNV-1a of
  ///   (x, y, tile), as wmap_setMapTileIndex of war_model_ref.c does in the scenarios of gathering
  /// </summary>
  TRecordingPainter = class(TInterfacedObject, IWarTilePainter)
  strict private
    FWrites: Cardinal;
    FHash: Cardinal;
    FLastTile: Integer;
  public
    constructor Create;
    procedure SetTileIndex(AX, AY, ATile: Integer);
    function GetTileIndex(AX, AY: Integer): Integer;
    function GetVisual: TArray<Word>;
    property Writes: Cardinal read FWrites;
    property Hash: Cardinal read FHash;
    property LastTile: Integer read FLastTile;
  end;

  /// <summary>
  ///   The scenarios of gathering of war_model_ref.c (Tools\Verifica\194, `gather`) written again: two factions with a
  ///   town hall, a gold mine, a forest and three workers each, orders drawn from the same generator in the same order.
  ///   The follow state is not ported: the scenario brings the unit to its target and pops the state as the follow would
  ///   (as the C does), and the collapse of a mine has no procedure (as in the C harness)
  /// </summary>
  TGatherScenario = class
  strict private
    FScriptState: Cardinal;
    FResults: Cardinal;
    FSpawned: array[0..255] of Word;
    FSpawnedCount: Integer;
    FTownHalls: array[0..1] of Word;
    FMines: array[0..1] of Word;
    FForestIds: array[0..1] of Word;
    FForestX: array[0..1] of Integer;
    FForestY: array[0..1] of Integer;
    FWorkers: array[0..5] of Word;
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FForests: TWarMapForests;
    FPainter: TRecordingPainter;
    FPainterRef: IWarTilePainter;
    FGather: TWarGatherWorld;
    FObserver: TModelObserver;
    function ScriptBelow(ALimit: Cardinal): Integer;
    procedure ResultMix(AValue: Cardinal);
    procedure Setup(ASeed: Cardinal);
    procedure Teardown;
    function SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer): Integer;
    procedure CreateForest(AIndex, AX, AY, AWidth, AHeight: Integer);
    function PickSpawned: Integer;
    function PickWorker: Integer;
    function IsOrderable(ASlot: Integer): Boolean;
    function PlayerOf(ASlot: Integer): Integer;
    procedure OrderGold(ASlot, AMine: Integer);
    procedure OrderWood(ASlot, AForest, APick: Integer);
    procedure OrderDeliver(ASlot, ATownHall: Integer);
    procedure OpMove;
    procedure OpEconomy;
    procedure OpHeal;
    procedure ScriptStep;
    procedure ResolveFollows;
    procedure Tick;
    function DumpNow(ATic: Integer): string;
    function Summary(ASeed: Cardinal): string;
  public
    /// <summary>
    ///   Runs the scenario of the seed (1800 tics). For each tic ALines gets 'G seed tic hash entities' and at the end the
    ///   line 'Q ...'; with ADumpTic >= 0 ADumpText is the text of the state at that tic and ALines is not written
    /// </summary>
    class procedure Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string); static;
  end;

const
  GATHER_TICS = 1800;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.UnitRange, DelphiDoom.War.Model.ActionStepper,
  DelphiDoom.War.Model.State.GatherFactory, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Forest,
  DelphiDoom.War.Model.Math, DelphiDoom.Tests.War.ModelDump;

{$Q-}
{$R-}

const
  TIC_SECONDS: Single = 0.016666668;

{ TRecordingPainter }

constructor TRecordingPainter.Create;
begin
  inherited Create;
  FHash := 2166136261;
end;

procedure TRecordingPainter.SetTileIndex(AX, AY, ATile: Integer);
begin
  Inc(FWrites);
  FLastTile := ATile;
  FHash := (FHash xor Cardinal(AX)) * 16777619;
  FHash := (FHash xor Cardinal(AY)) * 16777619;
  FHash := (FHash xor Cardinal(ATile)) * 16777619;
end;

function TRecordingPainter.GetTileIndex(AX, AY: Integer): Integer;
begin
  Result := 0;
end;

function TRecordingPainter.GetVisual: TArray<Word>;
begin
  SetLength(Result, 0);
end;

{ TGatherScenario }

function TGatherScenario.ScriptBelow(ALimit: Cardinal): Integer;
begin
  Result := 0;
  if ALimit <> 0 then
  begin
    FScriptState := FScriptState * 1664525 + 1013904223;
    Result := Integer((FScriptState shr 8) mod ALimit);
  end;
end;

procedure TGatherScenario.ResultMix(AValue: Cardinal);
begin
  FResults := (FResults * 16777619) xor AValue;
end;

function TGatherScenario.SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer): Integer;
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

procedure TGatherScenario.CreateForest(AIndex, AX, AY, AWidth, AHeight: Integer);
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
  FForestIds[AIndex] := LForest.Id;
  FForestX[AIndex] := AX;
  FForestY[AIndex] := AY;
end;

procedure TGatherScenario.Setup(ASeed: Cardinal);
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
  LZeros: TArray<Word>;
  LFaction: Integer;
  LBaseX: Integer;
  LBaseY: Integer;
  LMineX: Integer;
  LMineY: Integer;
  LAmount: Integer;
  LSlot: Integer;
  LForestX: Integer;
  LForestY: Integer;
  LForestWidth: Integer;
  LForestHeight: Integer;
  LIndex: Integer;
  LCarryKind: Integer;
  LCarry: Integer;
  LWorker: Integer;
  LWhat: Integer;
  LGate: Integer;
  LPick: Integer;
  LOwn: Integer;
  LWhere: Integer;
begin
  FObserver := TModelObserver.Create(ASeed xor $B7B7B7B7);
  FScriptState := ASeed * 2654435761 + 777;
  FResults := 2166136261;
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FFog := TWarFogOfWar.Create;
  FFog.Enabled := False;
  FPainter := TRecordingPainter.Create;
  FPainterRef := FPainter;
  FForests := TWarMapForests.Create(FGrid, FFog, FPainterRef, WAR_TILESET_FOREST);
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FGather := TWarGatherWorld.Create(FGrid, FForests, FObserver);
  FWorld.Context.Gather := FGather;
  // the C of the golden was built with gcc, where the enum of the directions is unsigned
  FWorld.Context.UnsignedDirections := True;
  // the collapse is another slice: no procedure, as in the C harness
  FWorld.Machine.RegisterHooks(WAR_STATE_COLLAPSE, nil, nil, nil);
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
  FSpawnedCount := 0;
  for LFaction := 0 to 1 do
  begin
    if LFaction = 0 then
      LBaseX := 6
    else
      LBaseX := 38;
    LBaseY := 8 + ScriptBelow(6);
    if LFaction = 0 then
      LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_TOWNHALL_HUMANS, LBaseX, LBaseY, Byte(LFaction), False)
    else
      LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_TOWNHALL_ORCS, LBaseX, LBaseY, Byte(LFaction), False);
    FTownHalls[LFaction] := FWorld.Context.Pool.Slots[LSlot]^.Id;
    LMineX := LBaseX + 5 + ScriptBelow(3);
    LMineY := LBaseY + ScriptBelow(3);
    LAmount := 100 + ScriptBelow(300);
    LSlot := FWorld.Entities.CreateUnit(WAR_UNIT_GOLDMINE, LMineX, LMineY, 4, wrkGold, Cardinal(LAmount), True);
    FWorld.Entities.SetInitialIdle(LSlot);
    FMines[LFaction] := FWorld.Context.Pool.Slots[LSlot]^.Id;
    LForestX := LBaseX + ScriptBelow(4);
    LForestY := LBaseY + 8 + ScriptBelow(3);
    LForestWidth := 4 + ScriptBelow(3);
    LForestHeight := 3 + ScriptBelow(3);
    CreateForest(LFaction, LForestX, LForestY, LForestWidth, LForestHeight);
    for LIndex := 0 to 2 do
    begin
      LCarryKind := ScriptBelow(4);
      LCarry := 60 + ScriptBelow(41);
      if LFaction = 0 then
        LWorker := SpawnDude(WAR_UNIT_PEASANT, Byte(LFaction), LBaseX + LIndex * 2, LBaseY + 5 + (LIndex mod 2))
      else
        LWorker := SpawnDude(WAR_UNIT_PEON, Byte(LFaction), LBaseX + LIndex * 2, LBaseY + 5 + (LIndex mod 2));
      FWorkers[LFaction * 3 + LIndex] := FWorld.Context.Pool.Slots[LWorker]^.Id;
      if LCarryKind = 0 then
      begin
        FWorld.Context.Pool.Slots[LWorker]^.UnitData.ResourceKind := wrkWood;
        FWorld.Context.Pool.Slots[LWorker]^.UnitData.Amount := LCarry;
      end
      else if LCarryKind = 1 then
      begin
        FWorld.Context.Pool.Slots[LWorker]^.UnitData.ResourceKind := wrkGold;
        FWorld.Context.Pool.Slots[LWorker]^.UnitData.Amount := LCarry;
      end;
    end;
  end;
  // the first orders: every worker gets one
  for LIndex := 0 to 5 do
  begin
    LWhat := ScriptBelow(3);
    LGate := ScriptBelow(4);
    LPick := ScriptBelow(40);
    LOwn := LIndex div 3;
    if LGate = 0 then
      LWhere := 1 - LOwn
    else
      LWhere := LOwn;
    LSlot := FWorld.Context.Pool.FindSlot(FWorkers[LIndex]);
    if LWhat = 0 then
      OrderGold(LSlot, LWhere)
    else if LWhat = 1 then
      OrderWood(LSlot, LWhere, LPick)
    else
      OrderDeliver(LSlot, LWhere);
  end;
end;

procedure TGatherScenario.Teardown;
begin
  FWorld.Free;
  FGather.Free;
  FForests.Free;
  FFog.Free;
  FGrid.Free;
  FPainterRef := nil;
end;

function TGatherScenario.PickSpawned: Integer;
var
  LCount: Cardinal;
  LIndex: Integer;
begin
  if FSpawnedCount > 0 then
    LCount := Cardinal(FSpawnedCount)
  else
    LCount := 1;
  LIndex := ScriptBelow(LCount);
  if FSpawnedCount = 0 then
    Exit(0);
  Result := FWorld.Context.Pool.FindSlot(FSpawned[LIndex]);
end;

function TGatherScenario.PickWorker: Integer;
begin
  Result := FWorld.Context.Pool.FindSlot(FWorkers[ScriptBelow(6)]);
end;

function TGatherScenario.IsOrderable(ASlot: Integer): Boolean;
begin
  Result := (ASlot <> 0) and FWorld.Context.Pool.Slots[ASlot]^.HasUnit and
    TWarUnitClassifier.IsDude(FWorld.Context.Pool.Slots[ASlot]^.UnitData.UnitType) and
    not FWorld.Machine.IsDead(ASlot) and not FWorld.Machine.IsGoingToDie(ASlot);
end;

function TGatherScenario.PlayerOf(ASlot: Integer): Integer;
begin
  if ASlot <> 0 then
    Result := FWorld.Context.Pool.Slots[ASlot]^.UnitData.Player
  else
    Result := 0;
end;

procedure TGatherScenario.OrderGold(ASlot, AMine: Integer);
var
  LState: PWarStateGold;
begin
  if not IsOrderable(ASlot) then
    Exit;
  LState := TWarGatherStateFactory.NewGold(FWorld.Machine, ASlot, FMines[AMine]);
  FWorld.Machine.ResetState(ASlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TGatherScenario.OrderWood(ASlot, AForest, APick: Integer);
var
  LState: PWarStateWood;
  LTileX: Integer;
  LTileY: Integer;
  LForest: TWarMapForest;
  LTree: TWarTree;
begin
  if not IsOrderable(ASlot) then
    Exit;
  LTileX := FForestX[AForest];
  LTileY := FForestY[AForest];
  if FWorld.Context.Pool.FindSlot(FForestIds[AForest]) <> 0 then
  begin
    LForest := FForests.FindForest(FForestIds[AForest]);
    if LForest.Trees.Count > 0 then
    begin
      LTree := LForest.Trees[Cardinal(APick) mod Cardinal(LForest.Trees.Count)];
      LTileX := LTree.TileX;
      LTileY := LTree.TileY;
    end;
  end;
  LState := TWarGatherStateFactory.NewWood(FWorld.Machine, ASlot, FForestIds[AForest],
    TWarModelMath.TileToMap(TWarModelMath.Vec(LTileX, LTileY), True));
  FWorld.Machine.ResetState(ASlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TGatherScenario.OrderDeliver(ASlot, ATownHall: Integer);
var
  LState: PWarStateDeliver;
begin
  if not IsOrderable(ASlot) then
    Exit;
  LState := TWarGatherStateFactory.NewDeliver(FWorld.Machine, ASlot, FTownHalls[ATownHall]);
  FWorld.Machine.ResetState(ASlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TGatherScenario.OpMove;
var
  LSlot: Integer;
  LTx: Integer;
  LTy: Integer;
  LMid: Integer;
  LMx: Integer;
  LMy: Integer;
  LCheck: Integer;
  LEntity: PWarEntity;
  LPositions: array of TWarVec2;
  LState: PWarStateMove;
begin
  LSlot := PickSpawned;
  LTx := ScriptBelow(60);
  LTy := ScriptBelow(60);
  LMid := ScriptBelow(2);
  LMx := ScriptBelow(60);
  LMy := ScriptBelow(60);
  LCheck := ScriptBelow(2);
  if LSlot = 0 then
    Exit;
  LEntity := FWorld.Context.Pool.Slots[LSlot];
  if not LEntity^.HasUnit or not TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) or FWorld.Machine.IsDead(LSlot) or
    FWorld.Machine.IsGoingToDie(LSlot) then
    Exit;
  if LMid <> 0 then
    SetLength(LPositions, 3)
  else
    SetLength(LPositions, 2);
  LPositions[0] := TWarUnitGeometry.CenterPosition(LEntity);
  if LMid <> 0 then
    LPositions[1] := TWarModelMath.Vec(LMx * 16 + 8, LMy * 16 + 8);
  LPositions[High(LPositions)] := TWarModelMath.Vec(LTx * 16 + 8, LTy * 16 + 8);
  LState := FWorld.Machine.CreateMove(LSlot, LPositions, LCheck <> 0);
  FWorld.Machine.ResetState(LSlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TGatherScenario.OpEconomy;
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

procedure TGatherScenario.OpHeal;
var
  LSlot: Integer;
  LHp: Integer;
  LMana: Integer;
  LAmount: Integer;
begin
  LSlot := PickSpawned;
  LHp := ScriptBelow(30);
  LMana := ScriptBelow(2);
  LAmount := ScriptBelow(60);
  if (LSlot = 0) or not FWorld.Context.Pool.Slots[LSlot]^.HasUnit then
    Exit;
  FWorld.Combat.IncreaseHp(LSlot, LHp);
  if LMana <> 0 then
    FWorld.Combat.IncreaseMana(LSlot, LAmount)
  else
    ResultMix(Ord(FWorld.Combat.DecreaseMana(LSlot, LAmount)));
end;

procedure TGatherScenario.ScriptStep;
var
  LRoll: Integer;
  LSlot: Integer;
  LGate: Integer;
  LPick: Integer;
  LMin: Integer;
  LRnd: Integer;
  LWhich: Integer;
  LId: Word;
begin
  LRoll := ScriptBelow(1000);
  if LRoll < 3 then
  begin
    LSlot := PickWorker;
    LGate := ScriptBelow(4);
    if LGate = 0 then
      OrderGold(LSlot, 1 - PlayerOf(LSlot))
    else
      OrderGold(LSlot, PlayerOf(LSlot));
  end
  else if LRoll < 6 then
  begin
    LSlot := PickWorker;
    LGate := ScriptBelow(4);
    LPick := ScriptBelow(40);
    if LGate = 0 then
      OrderWood(LSlot, 1 - PlayerOf(LSlot), LPick)
    else
      OrderWood(LSlot, PlayerOf(LSlot), LPick);
  end
  else if LRoll < 8 then
  begin
    LSlot := PickWorker;
    LGate := ScriptBelow(4);
    if LGate = 0 then
      OrderDeliver(LSlot, 1 - PlayerOf(LSlot))
    else
      OrderDeliver(LSlot, PlayerOf(LSlot));
  end
  else if LRoll < 10 then
  begin
    LSlot := PickWorker;
    LGate := ScriptBelow(2);
    LMin := ScriptBelow(3);
    LRnd := ScriptBelow(40);
    if (LSlot <> 0) and (LGate = 0) and FWorld.Context.Pool.Slots[LSlot]^.HasUnit then
      FWorld.Combat.TakeDamage(LSlot, LMin, LRnd);
  end
  else if LRoll < 12 then
  begin
    LSlot := PickWorker;
    if (LSlot <> 0) and FWorld.Context.Pool.Slots[LSlot]^.HasUnit and
      TWarUnitClassifier.IsDude(FWorld.Context.Pool.Slots[LSlot]^.UnitData.UnitType) then
      FWorld.Machine.PopState(LSlot, WAR_CAUSE_PLAYER_ORDER, WAR_RESULT_SUCCESS);
  end
  else if LRoll < 14 then
    OpMove
  else if LRoll < 20 then
    OpEconomy
  else if LRoll < 26 then
    OpHeal
  else if LRoll < 28 then
  begin
    LGate := ScriptBelow(4);
    LWhich := ScriptBelow(4);
    if LWhich < 2 then
      LId := FMines[LWhich]
    else
      LId := FTownHalls[LWhich - 2];
    if LGate = 0 then
      FWorld.Entities.RemoveEntityById(LId);
  end;
end;

procedure TGatherScenario.ResolveFollows;
var
  LSlot: Integer;
  LEntity: PWarEntity;
  LActive: PWarStateBase;
  LFollow: PWarStateFollow;
  LTarget: Integer;
begin
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FWorld.Context.Pool.Slots[LSlot];
    if (LEntity^.Id = 0) or (LEntity^.EntityType <> WAR_ENTITY_UNIT) then
      Continue;
    LActive := FWorld.Machine.ActiveState(LSlot);
    if not Assigned(LActive) or (LActive^.StateType <> WAR_STATE_FOLLOW) then
      Continue;
    LFollow := PWarStateFollow(LActive);
    LTarget := FWorld.Context.Pool.FindSlot(LFollow^.TargetEntityId);
    if LTarget = 0 then
    begin
      FWorld.Machine.PopState(LSlot, WAR_CAUSE_COMPLETION, WAR_RESULT_TARGET_INVALID);
      Continue;
    end;
    TWarUnitGeometry.SetCenterPosition(LEntity,
      TWarUnitRange.PointOnTarget(LEntity, FWorld.Context.Pool.Slots[LTarget]));
    FWorld.Machine.PopState(LSlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
  end;
end;

procedure TGatherScenario.Tick;
begin
  FWorld.AdvanceClock(TIC_SECONDS);
  ScriptStep;
  FWorld.Machine.ProcessPendingTransitions;
  ResolveFollows;
  FWorld.Machine.UpdateStates;
  TWarActionStepper.UpdateAll(FWorld.Context);
end;

function TGatherScenario.DumpNow(ATic: Integer): string;
var
  LText: string;
  LIndex: Integer;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LSlot: Integer;
  LEntity: PWarEntity;
  LFrame: Integer;
begin
  LText := TModelDump.Dump(FWorld, FGrid, FObserver, ATic, FResults);
  LText := LText + Format('M n=%u h=%s'#10, [FPainter.Writes, LowerCase(IntToHex(FPainter.Hash, 8))]);
  for LIndex := 0 to FForests.Count - 1 do
  begin
    LForest := FForests[LIndex];
    LText := LText + Format('F id=%d n=%d', [LForest.Id, LForest.Trees.Count]);
    for LTree in LForest.Trees do
      LText := LText + Format(' %d,%d,%d,%d', [LTree.TileX, LTree.TileY, LTree.Amount, LTree.TileType]);
    LText := LText + #10;
  end;
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FWorld.Context.Pool.Slots[LSlot];
    if (LEntity^.Id = 0) or (LEntity^.EntityType <> WAR_ENTITY_UNIT) then
      Continue;
    if LEntity^.UnitData.SpriteResource <> 0 then
      LFrame := LEntity^.UnitData.SpriteFrame
    else
      LFrame := -1;
    LText := LText + Format('K %d spr=%d en=%d fr=%d mx=%d'#10, [LEntity^.Id,
      LEntity^.UnitData.SpriteResource - Ord(LEntity^.UnitData.SpriteResource = 0),
      Ord((LEntity^.UnitData.SpriteResource <> 0) and LEntity^.UnitData.SpriteEnabled), LFrame,
      Ord(LEntity^.UnitData.Mirrored)]);
  end;
  Result := LText;
end;

function TGatherScenario.Summary(ASeed: Cardinal): string;
var
  LTrees: array[0..1] of Integer;
  LMines: array[0..1] of Integer;
  LFaction: Integer;
  LSlot: Integer;
  LForest: TWarMapForest;
begin
  for LFaction := 0 to 1 do
  begin
    LTrees[LFaction] := 0;
    if FWorld.Context.Pool.FindSlot(FForestIds[LFaction]) <> 0 then
    begin
      LForest := FForests.FindForest(FForestIds[LFaction]);
      LTrees[LFaction] := LForest.Trees.Count;
    end;
    LMines[LFaction] := -1;
    LSlot := FWorld.Context.Pool.FindSlot(FMines[LFaction]);
    if LSlot <> 0 then
      LMines[LFaction] := FWorld.Context.Pool.Slots[LSlot]^.UnitData.Amount;
  end;
  Result := Format('Q %u gold=%d,%d wood=%d,%d mines=%d,%d trees=%d,%d tiles=%u', [ASeed,
    FWorld.Context.Players[0]^.Gold, FWorld.Context.Players[1]^.Gold, FWorld.Context.Players[0]^.Wood,
    FWorld.Context.Players[1]^.Wood, LMines[0], LMines[1], LTrees[0], LTrees[1], FPainter.Writes]);
end;

class procedure TGatherScenario.Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string);
var
  LScenario: TGatherScenario;
  LTic: Integer;
  LText: string;
begin
  ADumpText := '';
  LScenario := TGatherScenario.Create;
  try
    LScenario.Setup(ASeed);
    try
      for LTic := 0 to GATHER_TICS - 1 do
      begin
        LScenario.Tick;
        if (ADumpTic >= 0) and (LTic <> ADumpTic) then
          Continue;
        LText := LScenario.DumpNow(LTic);
        if LTic = ADumpTic then
          ADumpText := LText
        else if Assigned(ALines) then
          ALines.Add(Format('G %u %d %s %d', [ASeed, LTic, LowerCase(IntToHex(TModelDump.Fnv1a(LText), 8)),
            LScenario.FWorld.Context.Pool.EntityCount]));
      end;
      if (ADumpTic < 0) and Assigned(ALines) then
        ALines.Add(LScenario.Summary(ASeed));
    finally
      LScenario.Teardown;
    end;
  finally
    LScenario.Free;
  end;
end;

end.
