{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of parity of the model }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.World, DelphiDoom.Tests.War.ModelObserver;

type
  /// <summary>
  ///   The scenarios of war_model_ref.c (Tools\Verifica\194) written again: the same generator of the script (the LCG of
  ///   the seed), the same units and the same operations drawn in the same order, so that the model of Delphi lives the
  ///   same life as the original. Friendly: all the units of the player 0 (no fight). Hostile: two armies that march
  ///   against each other, until a unit asks to attack (the attack is not ported yet)
  /// </summary>
  TModelScenario = class
  strict private
    FHostile: Boolean;
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
    procedure SpawnRandom;
    function PickSpawned: Integer;
    procedure OpMove;
    procedure OpDamage;
    procedure OpWait;
    procedure OpPop;
    procedure OpHeal;
    procedure OpEconomy;
    procedure OpRemove;
    procedure OpUpgrade;
    procedure OpFood;
    procedure ScriptStep;
    procedure Tick;
    function AnyAttack: Boolean;
    function DumpNow(ATic: Integer): string;
  public
    /// <summary>
    ///   Runs the scenario of the seed. For each tic ALines gets 'F|H seed tic hash entities' (and 'S seed tic' where a hostile
    ///   scenario stops); with ADumpTic >= 0 the lines are not written and ADumpText is the text of the state at that tic
    /// </summary>
    class procedure Run(AHostile: Boolean; ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings;
      out ADumpText: string); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.GridOccupancy,
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Combat,
  DelphiDoom.War.Model.Math, DelphiDoom.Tests.War.ModelDump;

{$Q-}
{$R-}

const
  DUDE_POOL: array[0..11] of Integer = (WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_PEASANT, WAR_UNIT_PEON,
    WAR_UNIT_ARCHER, WAR_UNIT_KNIGHT, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_CONJURER, WAR_UNIT_CLERIC, WAR_UNIT_SPIDER,
    WAR_UNIT_SKELETON, WAR_UNIT_OGRE);
  BUILDING_POOL: array[0..4] of Integer = (WAR_UNIT_FARM_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_BARRACKS_HUMANS,
    WAR_UNIT_TEMPLE, WAR_UNIT_GOLDMINE);
  FRIENDLY_TICS = 300;
  HOSTILE_TICS = 900;
  TIC_SECONDS: Single = 0.016666668;

{ TModelScenario }

function TModelScenario.ScriptBelow(ALimit: Cardinal): Integer;
begin
  Result := 0;
  if ALimit <> 0 then
  begin
    FScriptState := FScriptState * 1664525 + 1013904223;
    Result := Integer((FScriptState shr 8) mod ALimit);
  end;
end;

procedure TModelScenario.ResultMix(AValue: Cardinal);
begin
  FResults := (FResults * 16777619) xor AValue;
end;

procedure TModelScenario.Setup(ASeed: Cardinal);
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
  // the C of the golden was built with gcc, where the enum of the directions is unsigned
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
  LCount := 6 + ScriptBelow(7);
  for LIndex := 1 to LCount do
    SpawnRandom;
end;

procedure TModelScenario.SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer);
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

procedure TModelScenario.SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
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

procedure TModelScenario.SpawnRandom;
var
  LKind: Integer;
  LX: Integer;
  LY: Integer;
  LType: Integer;
  LPlayer: Byte;
begin
  LKind := ScriptBelow(100);
  LX := 6 + ScriptBelow(40);
  LY := 6 + ScriptBelow(40);
  if LKind < 80 then
  begin
    LType := ScriptBelow(12);
    LPlayer := 0;
    if FHostile then
    begin
      LPlayer := Byte(ScriptBelow(2));
      if LPlayer = 0 then
        LX := 10 + (LX mod 8)
      else
        LX := 25 + (LX mod 8);
    end;
    SpawnDude(DUDE_POOL[LType], LPlayer, LX, LY);
  end
  else
  begin
    LType := ScriptBelow(5);
    if BUILDING_POOL[LType] = WAR_UNIT_GOLDMINE then
      LPlayer := 4
    else
      LPlayer := 0;
    SpawnBuilding(BUILDING_POOL[LType], LPlayer, LX, LY);
  end;
end;

function TModelScenario.PickSpawned: Integer;
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

procedure TModelScenario.OpMove;
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
  if FHostile then
  begin
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

procedure TModelScenario.OpDamage;
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

procedure TModelScenario.OpWait;
var
  LSlot: Integer;
  LTime: Single;
  LEntity: PWarEntity;
  LState: PWarStateWait;
begin
  LSlot := PickSpawned;
  LTime := 1.0 + ScriptBelow(5) * 0.5;
  if LSlot = 0 then
    Exit;
  LEntity := FWorld.Context.Pool.Slots[LSlot];
  if not LEntity^.HasUnit or not TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) or FWorld.Machine.IsDead(LSlot) or
    FWorld.Machine.IsGoingToDie(LSlot) then
    Exit;
  LState := FWorld.Machine.CreateWait(LSlot, LTime);
  FWorld.Machine.PushState(LSlot, PWarStateBase(LState), WAR_CAUSE_AI_ORDER);
end;

procedure TModelScenario.OpPop;
var
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  LSlot := PickSpawned;
  if LSlot = 0 then
    Exit;
  LEntity := FWorld.Context.Pool.Slots[LSlot];
  if not LEntity^.HasUnit or not TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) then
    Exit;
  FWorld.Machine.PopState(LSlot, WAR_CAUSE_PLAYER_ORDER, WAR_RESULT_SUCCESS);
end;

procedure TModelScenario.OpHeal;
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

procedure TModelScenario.OpEconomy;
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

procedure TModelScenario.OpRemove;
var
  LSlot: Integer;
begin
  LSlot := PickSpawned;
  if LSlot = 0 then
    Exit;
  FWorld.Entities.RemoveEntityById(FWorld.Context.Pool.Slots[LSlot]^.Id);
end;

procedure TModelScenario.OpUpgrade;
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LInfo: PWarPlayerInfo;
begin
  LPlayer := ScriptBelow(2);
  LUpgrade := ScriptBelow(19);
  LInfo := FWorld.Context.Players[LPlayer];
  if LInfo^.Upgrades[LUpgrade div 2].Level < LInfo^.Upgrades[LUpgrade div 2].Allowed then
    FWorld.Economy.IncreaseUpgradeLevel(LInfo, LUpgrade);
end;

procedure TModelScenario.OpFood;
var
  LPlayer: Integer;
begin
  LPlayer := ScriptBelow(4);
  ResultMix(Ord(FWorld.Economy.EnoughFarmFood(FWorld.Context.Players[LPlayer])));
end;

procedure TModelScenario.ScriptStep;
var
  LRoll: Integer;
  LMove: Boolean;
begin
  LRoll := ScriptBelow(100);
  if FHostile then
    LMove := LRoll < 20
  else
    LMove := LRoll < 8;
  if LMove then
    OpMove
  else if LRoll < 12 then
    OpDamage
  else if LRoll < 14 then
    OpWait
  else if LRoll < 16 then
    OpPop
  else if LRoll < 18 then
    OpHeal
  else if LRoll < 20 then
    OpEconomy
  else if LRoll < 21 then
    OpRemove
  else if LRoll < 24 then
    SpawnRandom
  else if LRoll < 25 then
    OpUpgrade
  else if LRoll < 27 then
    OpFood;
end;

procedure TModelScenario.Tick;
begin
  FWorld.AdvanceClock(TIC_SECONDS);
  ScriptStep;
  FWorld.Update;
end;

function TModelScenario.AnyAttack: Boolean;
var
  LSlot: Integer;
begin
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    if (FWorld.Context.Pool.Slots[LSlot]^.Id <> 0) and
      (FWorld.Machine.IsAttacking(LSlot) or FWorld.Machine.IsGoingToAttack(LSlot)) then
      Exit(True);
  Result := False;
end;

function TModelScenario.DumpNow(ATic: Integer): string;
begin
  Result := TModelDump.Dump(FWorld, FGrid, FObserver, ATic, FResults);
end;

class procedure TModelScenario.Run(AHostile: Boolean; ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings;
  out ADumpText: string);
var
  LScenario: TModelScenario;
  LLimit: Integer;
  LTic: Integer;
  LStop: Boolean;
  LText: string;
  LTag: Char;
begin
  ADumpText := '';
  LScenario := TModelScenario.Create;
  try
    LScenario.FHostile := AHostile;
    LScenario.Setup(ASeed);
    try
      if AHostile then
      begin
        LLimit := HOSTILE_TICS;
        LTag := 'H';
      end
      else
      begin
        LLimit := FRIENDLY_TICS;
        LTag := 'F';
      end;
      for LTic := 0 to LLimit - 1 do
      begin
        LScenario.Tick;
        LStop := AHostile and LScenario.AnyAttack;
        LText := LScenario.DumpNow(LTic);
        if (ADumpTic >= 0) and (LTic = ADumpTic) then
          ADumpText := LText
        else if (ADumpTic < 0) and Assigned(ALines) then
        begin
          ALines.Add(Format('%s %u %d %s %d', [LTag, ASeed, LTic, LowerCase(IntToHex(TModelDump.Fnv1a(LText), 8)),
            LScenario.FWorld.Context.Pool.EntityCount]));
          if LStop then
            ALines.Add(Format('S %u %d', [ASeed, LTic]));
        end;
        if LStop then
          Break;
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
