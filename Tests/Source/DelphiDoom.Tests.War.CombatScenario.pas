{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of combat              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CombatScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.World, DelphiDoom.Tests.War.ModelObserver;

type
  /// <summary>
  ///   The combat scenarios of war_model_ref.c (runCombat, Tools\Verifica\194) written again: two armies that stand near each
  ///   other (the warriors see each other and attack), orders to attack, follow, patrol and move, damage, removals, new
  ///   units, rains of fire and other projectiles; the tic is the one of wmap_updateMap (states, grid, actions,
  ///   projectiles). The script draws its numbers in the same order as the C
  /// </summary>
  TCombatScenario = class
  strict private
    FScriptState: Cardinal;
    FResults: Cardinal;
    FSpawned: array[0..255] of Word;
    FSpawnedCount: Integer;
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FObserver: TModelObserver;
    function ScriptBelow(ALimit: Cardinal): Integer;
    procedure ResultMix(AValue: Cardinal);
    procedure Setup(ASeed: Cardinal);
    procedure SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer);
    procedure SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
    procedure SpawnCombat;
    function PickSpawned: Integer;
    function IsLiveDude(ASlot: Integer): Boolean;
    procedure OpMove;
    procedure OpDamage;
    procedure OpWait;
    procedure OpHeal;
    procedure OpRemove;
    procedure OpAttack;
    procedure OpFollow;
    procedure OpPatrol;
    procedure OpRain;
    procedure ScriptStep;
    procedure Tick;
  public
    /// <summary>
    ///   Runs the scenario of the seed for 600 tics: ALines gets 'C seed tic hash entities' for each tic; with
    ///   ADumpTic >= 0 the lines are not written and ADumpText is the text of the state at that tic
    /// </summary>
    class procedure Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.GridOccupancy,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.EntityPool, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Math, DelphiDoom.Tests.War.ModelDump;

{$Q-}
{$R-}

const
  COMBAT_POOL: array[0..15] of Integer = (WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN,
    WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC,
    WAR_UNIT_NECROLYTE, WAR_UNIT_KNIGHT, WAR_UNIT_OGRE, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON,
    WAR_UNIT_WATER_ELEMENTAL, WAR_UNIT_PEASANT);
  COMBAT_BUILDING_POOL: array[0..2] of Integer = (WAR_UNIT_FARM_HUMANS, WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_CHURCH);
  COMBAT_TICS = 600;
  TIC_SECONDS: Single = 0.016666668;

{ TCombatScenario }

function TCombatScenario.ScriptBelow(ALimit: Cardinal): Integer;
begin
  Result := 0;
  if ALimit <> 0 then
  begin
    FScriptState := FScriptState * 1664525 + 1013904223;
    Result := Integer((FScriptState shr 8) mod ALimit);
  end;
end;

procedure TCombatScenario.ResultMix(AValue: Cardinal);
begin
  FResults := (FResults * 16777619) xor AValue;
end;

procedure TCombatScenario.Setup(ASeed: Cardinal);
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
  LCount: Integer;
  LIndex: Integer;
  LZeros: TArray<Word>;
begin
  FObserver := TModelObserver.Create(ASeed xor $A5A5A5A5);
  FScriptState := ASeed * 2654435761 + 12345;
  FResults := 2166136261;
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FWorld.Context.UnsignedDirections := True;
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
  LCount := 10 + ScriptBelow(8);
  for LIndex := 1 to LCount do
    SpawnCombat;
end;

procedure TCombatScenario.SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer);
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateDude(AType, AX, AY, APlayer, False);
  if LSlot <> 0 then
  begin
    FWorld.Entities.SetInitialIdle(LSlot);
    if FSpawnedCount < 256 then
    begin
      FSpawned[FSpawnedCount] := FWorld.Context.Pool.Slots[LSlot]^.Id;
      Inc(FSpawnedCount);
    end;
  end;
end;

procedure TCombatScenario.SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
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

procedure TCombatScenario.SpawnCombat;
var
  LKind: Integer;
  LYr: Integer;
  LXr: Integer;
  LType: Integer;
  LPlayer: Byte;
  LX: Integer;
begin
  LKind := ScriptBelow(100);
  LYr := ScriptBelow(24);
  LXr := ScriptBelow(8);
  if LKind < 88 then
  begin
    LType := ScriptBelow(16);
    LPlayer := Byte(ScriptBelow(2));
    if LPlayer = 0 then
      LX := 14 + LXr
    else
      LX := 21 + LXr;
    SpawnDude(COMBAT_POOL[LType], LPlayer, LX, 8 + LYr);
  end
  else
  begin
    LType := ScriptBelow(3);
    LPlayer := Byte(ScriptBelow(2));
    if LPlayer = 0 then
      LX := 12 + LXr
    else
      LX := 26 + LXr;
    SpawnBuilding(COMBAT_BUILDING_POOL[LType], LPlayer, LX, 8 + LYr);
  end;
end;

function TCombatScenario.PickSpawned: Integer;
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

function TCombatScenario.IsLiveDude(ASlot: Integer): Boolean;
var
  LEntity: PWarEntity;
begin
  if ASlot = 0 then
    Exit(False);
  LEntity := FWorld.Context.Pool.Slots[ASlot];
  Result := LEntity^.HasUnit and TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) and
    not FWorld.Machine.IsDead(ASlot) and not FWorld.Machine.IsGoingToDie(ASlot);
end;

procedure TCombatScenario.OpMove;
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
  if not IsLiveDude(LSlot) then
    Exit;
  LEntity := FWorld.Context.Pool.Slots[LSlot];
  if LEntity^.UnitData.Player = 0 then
  begin
    LTx := 25 + LTx mod 8;
    LMx := 25 + LMx mod 8;
  end
  else
  begin
    LTx := 10 + LTx mod 8;
    LMx := 10 + LMx mod 8;
  end;
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

procedure TCombatScenario.OpDamage;
var
  LSlot: Integer;
  LMin: Integer;
  LRnd: Integer;
  LEntity: PWarEntity;
begin
  LSlot := PickSpawned;
  LMin := ScriptBelow(5);
  LRnd := ScriptBelow(80);
  if LSlot = 0 then
    Exit;
  LEntity := FWorld.Context.Pool.Slots[LSlot];
  if not LEntity^.HasUnit or TWarUnitClassifier.IsBuilding(LEntity^.UnitData.UnitType) then
    Exit;
  FWorld.Combat.TakeDamage(LSlot, LMin, LRnd);
end;

procedure TCombatScenario.OpWait;
var
  LSlot: Integer;
  LTime: Single;
  LState: PWarStateWait;
begin
  LSlot := PickSpawned;
  LTime := 1.0 + ScriptBelow(5) * 0.5;
  if not IsLiveDude(LSlot) then
    Exit;
  LState := FWorld.Machine.CreateWait(LSlot, LTime);
  FWorld.Machine.PushState(LSlot, PWarStateBase(LState), WAR_CAUSE_AI_ORDER);
end;

procedure TCombatScenario.OpHeal;
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

procedure TCombatScenario.OpRemove;
var
  LSlot: Integer;
begin
  LSlot := PickSpawned;
  if LSlot = 0 then
    Exit;
  FWorld.Entities.RemoveEntityById(FWorld.Context.Pool.Slots[LSlot]^.Id);
end;

procedure TCombatScenario.OpAttack;
var
  LSlot: Integer;
  LTarget: Integer;
  LPoint: Integer;
  LPx: Integer;
  LPy: Integer;
  LPush: Integer;
  LTargetId: Word;
  LPosition: TWarVec2;
  LState: PWarStateAttack;
begin
  LSlot := PickSpawned;
  LTarget := PickSpawned;
  LPoint := ScriptBelow(10);
  LPx := ScriptBelow(60);
  LPy := ScriptBelow(60);
  LPush := ScriptBelow(2);
  if not IsLiveDude(LSlot) then
    Exit;
  LTargetId := 0;
  if (LPoint = 0) or (LTarget = 0) then
    LPosition := TWarModelMath.Vec(LPx * 16 + 8, LPy * 16 + 8)
  else
  begin
    LTargetId := FWorld.Context.Pool.Slots[LTarget]^.Id;
    LPosition := TWarUnitGeometry.CenterPosition(FWorld.Context.Pool.Slots[LTarget]);
  end;
  LState := FWorld.Machine.CreateAttack(LSlot, LTargetId, LPosition);
  if LPush <> 0 then
    FWorld.Machine.PushState(LSlot, PWarStateBase(LState), WAR_CAUSE_AI_ORDER)
  else
    FWorld.Machine.ResetState(LSlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TCombatScenario.OpFollow;
var
  LSlot: Integer;
  LTarget: Integer;
  LDistance: Integer;
  LPush: Integer;
  LPx: Integer;
  LPy: Integer;
  LTargetId: Word;
  LPosition: TWarVec2;
  LState: PWarStateFollow;
begin
  LSlot := PickSpawned;
  LTarget := PickSpawned;
  LDistance := 1 + ScriptBelow(4);
  LPush := ScriptBelow(2);
  LPx := ScriptBelow(60);
  LPy := ScriptBelow(60);
  if not IsLiveDude(LSlot) then
    Exit;
  if LTarget <> 0 then
  begin
    LTargetId := FWorld.Context.Pool.Slots[LTarget]^.Id;
    LPosition := TWarModelMath.Vec(0, 0);
  end
  else
  begin
    LTargetId := 0;
    LPosition := TWarModelMath.Vec(LPx * 16 + 8, LPy * 16 + 8);
  end;
  LState := FWorld.Machine.CreateFollow(LSlot, LTargetId, LPosition, LDistance * 16);
  if LPush <> 0 then
    FWorld.Machine.PushState(LSlot, PWarStateBase(LState), WAR_CAUSE_AI_ORDER)
  else
    FWorld.Machine.ResetState(LSlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TCombatScenario.OpPatrol;
var
  LSlot: Integer;
  LCount: Integer;
  LPx: array[0..2] of Integer;
  LPy: array[0..2] of Integer;
  LIndex: Integer;
  LPositions: array of TWarVec2;
  LState: PWarStatePatrol;
begin
  LSlot := PickSpawned;
  LCount := 2 + ScriptBelow(3);
  for LIndex := 0 to 2 do
  begin
    LPx[LIndex] := 10 + ScriptBelow(24);
    LPy[LIndex] := 8 + ScriptBelow(24);
  end;
  if not IsLiveDude(LSlot) then
    Exit;
  SetLength(LPositions, LCount);
  LPositions[0] := TWarUnitGeometry.CenterPosition(FWorld.Context.Pool.Slots[LSlot]);
  for LIndex := 1 to LCount - 1 do
    LPositions[LIndex] := TWarModelMath.Vec(LPx[LIndex - 1] * 16 + 8, LPy[LIndex - 1] * 16 + 8);
  LState := FWorld.Machine.CreatePatrol(LSlot, LPositions);
  FWorld.Machine.ResetState(LSlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TCombatScenario.OpRain;
var
  LSlot: Integer;
  LTarget: Integer;
  LKind: Integer;
  LTx: Integer;
  LTy: Integer;
  LGoal: TWarVec2;
  LOrigin: TWarVec2;
  LType: Integer;
  LTargetId: Word;
  LSourceId: Word;
begin
  LSlot := PickSpawned;
  LTarget := PickSpawned;
  LKind := ScriptBelow(4);
  LTx := 10 + ScriptBelow(24);
  LTy := 8 + ScriptBelow(24);
  LGoal := TWarModelMath.Vec(LTx * 16 + 8, LTy * 16 + 8);
  LOrigin := TWarModelMath.Vec(LGoal.X - 80.0, LGoal.Y - 120.0);
  if LKind < 2 then
    LType := WAR_PROJECTILE_RAIN_OF_FIRE
  else if LKind = 2 then
    LType := WAR_PROJECTILE_FIREBALL_2
  else
    LType := WAR_PROJECTILE_CATAPULT;
  LTargetId := 0;
  if (LKind >= 2) and (LTarget <> 0) then
    LTargetId := FWorld.Context.Pool.Slots[LTarget]^.Id;
  LSourceId := 0;
  if LSlot <> 0 then
    LSourceId := FWorld.Context.Pool.Slots[LSlot]^.Id;
  FWorld.Context.Combat.CreateProjectile(LType, LSourceId, LTargetId, LOrigin, LGoal);
end;

procedure TCombatScenario.ScriptStep;
var
  LRoll: Integer;
begin
  LRoll := ScriptBelow(100);
  if LRoll < 6 then
    OpAttack
  else if LRoll < 9 then
    OpFollow
  else if LRoll < 11 then
    OpPatrol
  else if LRoll < 14 then
    OpMove
  else if LRoll < 16 then
    OpDamage
  else if LRoll < 17 then
    OpRemove
  else if LRoll < 20 then
    SpawnCombat
  else if LRoll < 22 then
    OpRain
  else if LRoll < 26 then
    OpHeal
  else if LRoll < 27 then
    OpWait;
end;

procedure TCombatScenario.Tick;
begin
  FWorld.AdvanceClock(TIC_SECONDS);
  ScriptStep;
  FWorld.Update;
  FWorld.UpdateAfterStates;
end;

class procedure TCombatScenario.Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string);
var
  LScenario: TCombatScenario;
  LTic: Integer;
  LText: string;
begin
  ADumpText := '';
  LScenario := TCombatScenario.Create;
  try
    LScenario.Setup(ASeed);
    try
      for LTic := 0 to COMBAT_TICS - 1 do
      begin
        LScenario.Tick;
        LText := TModelDump.Dump(LScenario.FWorld, LScenario.FGrid, LScenario.FObserver, LTic, LScenario.FResults, True);
        if (ADumpTic >= 0) and (LTic = ADumpTic) then
          ADumpText := LText
        else if (ADumpTic < 0) and Assigned(ALines) then
          ALines.Add(Format('C %u %d %s %d', [ASeed, LTic, LowerCase(IntToHex(TModelDump.Fnv1a(LText), 8)),
            LScenario.FWorld.Context.Pool.EntityCount]));
      end;
    finally
      LScenario.FWorld.Free;
      LScenario.FGrid.Free;
    end;
  finally
    LScenario.Free;
  end;
end;

end.
