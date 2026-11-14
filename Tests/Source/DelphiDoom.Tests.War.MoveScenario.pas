{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of the movement        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MoveScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Map.Fog, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.FlowSteering, DelphiDoom.Tests.War.ModelObserver, DelphiDoom.Tests.War.PathScenario;

type
  /// <summary>
  ///   The scenarios `war_model_ref move` (runMove of war_path_ref.inc, Tools\Verifica\194) written again: two groups of
  ///   units that cross a map with obstacles (noise, rectangles, rooms, an open field, a strip with a gap; the two sides
  ///   free), buildings in the middle, orders every few tics (new targets, stops, waits, damage), the whole tic of
  ///   wmap_updateMap with the real flow fields, the avoidance between units and the fog. The script draws its numbers in the
  ///   same order as the C
  /// </summary>
  TMoveScenario = class
  strict private
    FScript: TPathScenario;
    FResults: Cardinal;
    FSpawned: array[0..255] of Word;
    FSpawnedCount: Integer;
    FDelta: Single;
    FTic: Integer;
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FObserver: TModelObserver;
    FSteering: TWarFlowSteering;
    procedure Setup(ASeed: Cardinal);
    procedure Teardown;
    procedure SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer);
    procedure SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
    procedure MoveOrder(ASlot, ATx, ATy: Integer; AVia: Boolean; AMx, AMy: Integer; ACheck: Boolean);
    procedure ScriptStep;
    procedure Tick;
  public
    /// <summary>
    ///   Runs the scenario of the seed for 600 tics: ALines gets 'M seed tic hash entities' for each tic; with ADumpTic >= 0
    ///   the lines are not written and ADumpText is the text of the state at that tic. ALast, if given, gets the states of
    ///   the world at the end through ACheck (the tests of the movement look at where the units went)
    /// </summary>
    class procedure Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string); static;
    /// <summary>How many flow fields the scenario computed and how many tics a unit was moving (what the tests ask)</summary>
    class procedure Measure(ASeed: Cardinal; out AFields, AMovingTics, AFogVisible: Integer); static;
  end;

const
  MOVE_SCENARIO_TICS = 600;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Path.FlowFields,
  DelphiDoom.Tests.War.ModelDump;

{$Q-}
{$R-}

const
  MOVE_POOL: array[0..13] of Integer = (WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_PEASANT, WAR_UNIT_PEON,
    WAR_UNIT_ARCHER, WAR_UNIT_KNIGHT, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CONJURER,
    WAR_UNIT_OGRE, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON, WAR_UNIT_CLERIC, WAR_UNIT_WARLOCK);
  DELTAS: array[0..3] of Single = (0.016666668, 0.033333335, 0.1, 0.25);

{ TMoveScenario }

procedure TMoveScenario.Setup(ASeed: Cardinal);
var
  LPassable: TArray<Word>;
  LRingX: Integer;
  LRingY: Integer;
  LKind: Cardinal;
  LX: Integer;
  LY: Integer;
  LCount: Integer;
  LIndex: Integer;
  LPlayer: Integer;
  LInfo: PWarPlayerInfo;
  LUpgrade: Integer;
  LType: Integer;
  LPlayerOfUnit: Byte;
  LBx: Integer;
  LBy: Integer;
begin
  FScript := TPathScenario.Create;
  FScript.FState := ASeed * 2654435761 + 31337;
  FResults := 2166136261;
  FObserver := TModelObserver.Create(ASeed xor $D1D1D1D1);
  FDelta := DELTAS[ASeed mod 4];
  FSpawnedCount := 0;
  // the map: the kind of the seed (the closed ring is a noise map here), the two sides free of obstacles
  LKind := ASeed mod 6;
  if LKind = 4 then
    LKind := 0;
  FScript.Passable(LKind, LPassable, LRingX, LRingY);
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to 23 do
    begin
      LPassable[LY * WAR_MAP_TILES_WIDTH + LX] := 0;
      LPassable[LY * WAR_MAP_TILES_WIDTH + (WAR_MAP_TILES_WIDTH - 1 - LX)] := 0;
    end;
  FGrid := TWarPathGrid.Create(LPassable);
  FFog := TWarFogOfWar.Create;
  FFog.Enabled := True;
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FWorld.Context.UnsignedDirections := True;
  TWarModelFactory.AttachFlowSteering(FWorld, FGrid);
  FSteering := FWorld.Context.Steering as TWarFlowSteering;
  FSteering.Fields.TrackSignature := True;
  TWarModelFactory.AttachFog(FWorld, FFog);
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
  LCount := 14 + FScript.Below(14);
  for LIndex := 0 to LCount - 1 do
  begin
    LPlayerOfUnit := Byte(LIndex mod 2);
    LType := MOVE_POOL[FScript.Below(14)];
    if LPlayerOfUnit = 0 then
      LX := 2
    else
      LX := 41;
    LX := LX + FScript.Below(20);
    LY := 3 + FScript.Below(58);
    if FGrid.IsEmpty(LX, LY) then
      SpawnDude(LType, LPlayerOfUnit, LX, LY);
  end;
  // some buildings as obstacles, between the groups
  for LIndex := 0 to 2 do
  begin
    LBx := 26 + FScript.Below(10);
    LBy := 5 + FScript.Below(50);
    SpawnBuilding(WAR_UNIT_FARM_HUMANS, 0, LBx, LBy);
  end;
end;

procedure TMoveScenario.Teardown;
begin
  FWorld.Free;
  FFog.Free;
  FGrid.Free;
  FScript.Free;
end;

procedure TMoveScenario.SpawnDude(AType: Integer; APlayer: Byte; AX, AY: Integer);
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

procedure TMoveScenario.SpawnBuilding(AType: Integer; APlayer: Byte; AX, AY: Integer);
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

procedure TMoveScenario.MoveOrder(ASlot, ATx, ATy: Integer; AVia: Boolean; AMx, AMy: Integer; ACheck: Boolean);
var
  LPositions: array of TWarVec2;
  LState: PWarStateMove;
begin
  if AVia then
    SetLength(LPositions, 3)
  else
    SetLength(LPositions, 2);
  LPositions[0] := TWarUnitGeometry.CenterPosition(FWorld.Context.Pool.Slots[ASlot]);
  if AVia then
  begin
    LPositions[1].X := AMx * 16 + 8;
    LPositions[1].Y := AMy * 16 + 8;
  end;
  LPositions[High(LPositions)].X := ATx * 16 + 8;
  LPositions[High(LPositions)].Y := ATy * 16 + 8;
  LState := FWorld.Machine.CreateMove(ASlot, LPositions, ACheck);
  FWorld.Machine.ResetState(ASlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TMoveScenario.ScriptStep;
var
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LLeft: Boolean;
  LTx: Integer;
  LTy: Integer;
  LVia: Boolean;
  LMx: Integer;
  LMy: Integer;
  LCheck: Boolean;
  LOp: Integer;
  LDamage: Integer;
  LWait: PWarStateWait;
begin
  // the first tic gives an order to everybody, then one now and then: new goals, stops, waits, damage
  if FTic = 0 then
  begin
    for LIndex := 0 to FSpawnedCount - 1 do
    begin
      LSlot := FWorld.Context.Pool.FindSlot(FSpawned[LIndex]);
      if LSlot = 0 then
        Continue;
      LEntity := FWorld.Context.Pool.Slots[LSlot];
      if not (LEntity^.HasUnit and TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType)) then
        Continue;
      LLeft := LEntity^.UnitData.Player = 0;
      if LLeft then
        LTx := 38
      else
        LTx := 4;
      LTx := LTx + FScript.Below(22);
      LTy := 4 + FScript.Below(56);
      LVia := FScript.Below(3) = 0;
      LMx := 4 + FScript.Below(56);
      LMy := 4 + FScript.Below(56);
      LCheck := FScript.Below(2) = 0;
      MoveOrder(LSlot, LTx, LTy, LVia, LMx, LMy, LCheck);
    end;
    Exit;
  end;
  if FScript.Below(6) <> 0 then
    Exit;
  if FSpawnedCount > 0 then
    LIndex := FScript.Below(Cardinal(FSpawnedCount))
  else
    LIndex := FScript.Below(1);
  LOp := FScript.Below(100);
  LTx := FScript.Below(WAR_MAP_TILES_WIDTH);
  LTy := FScript.Below(WAR_MAP_TILES_HEIGHT);
  LVia := FScript.Below(3) = 0;
  LMx := FScript.Below(WAR_MAP_TILES_WIDTH);
  LMy := FScript.Below(WAR_MAP_TILES_HEIGHT);
  LCheck := FScript.Below(2) = 0;
  LDamage := FScript.Below(60);
  if FSpawnedCount = 0 then
    Exit;
  LSlot := FWorld.Context.Pool.FindSlot(FSpawned[LIndex]);
  if LSlot = 0 then
    Exit;
  LEntity := FWorld.Context.Pool.Slots[LSlot];
  if not (LEntity^.HasUnit and TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType)) or FWorld.Machine.IsDead(LSlot) or
    FWorld.Machine.IsGoingToDie(LSlot) then
    Exit;
  if LOp < 70 then
    MoveOrder(LSlot, LTx, LTy, LVia, LMx, LMy, LCheck)
  else if LOp < 82 then
    FWorld.Machine.PopState(LSlot, WAR_CAUSE_PLAYER_ORDER, WAR_RESULT_SUCCESS)
  else if LOp < 92 then
  begin
    LWait := FWorld.Machine.CreateWait(LSlot, 1.0 + (LDamage mod 5) * 0.5);
    FWorld.Machine.PushState(LSlot, PWarStateBase(LWait), WAR_CAUSE_AI_ORDER);
  end
  else
    FWorld.Combat.TakeDamage(LSlot, 1, LDamage);
end;

procedure TMoveScenario.Tick;
begin
  FWorld.AdvanceClock(FDelta);
  ScriptStep;
  FWorld.Update;
  FWorld.FinishTic;
end;

class procedure TMoveScenario.Run(ASeed: Cardinal; ADumpTic: Integer; ALines: TStrings; out ADumpText: string);
var
  LScenario: TMoveScenario;
  LTic: Integer;
  LText: string;
begin
  ADumpText := '';
  LScenario := TMoveScenario.Create;
  try
    LScenario.Setup(ASeed);
    try
      for LTic := 0 to MOVE_SCENARIO_TICS - 1 do
      begin
        LScenario.FTic := LTic;
        LScenario.Tick;
        if (ADumpTic >= 0) and (LTic <> ADumpTic) then
          Continue;
        LText := TModelDump.Dump(LScenario.FWorld, LScenario.FGrid, LScenario.FObserver, LTic, LScenario.FResults, True,
          LScenario.FSteering.Fields, LScenario.FFog);
        if LTic = ADumpTic then
        begin
          ADumpText := LText;
          Break;
        end
        else if Assigned(ALines) then
          ALines.Add(Format('M %u %d %s %d', [ASeed, LTic, LowerCase(IntToHex(TModelDump.Fnv1a(LText), 8)),
            LScenario.FWorld.Context.Pool.EntityCount]));
      end;
    finally
      LScenario.Teardown;
    end;
  finally
    LScenario.Free;
  end;
end;

class procedure TMoveScenario.Measure(ASeed: Cardinal; out AFields, AMovingTics, AFogVisible: Integer);
var
  LScenario: TMoveScenario;
  LTic: Integer;
begin
  AMovingTics := 0;
  LScenario := TMoveScenario.Create;
  try
    LScenario.Setup(ASeed);
    try
      for LTic := 0 to MOVE_SCENARIO_TICS - 1 do
      begin
        LScenario.FTic := LTic;
        LScenario.Tick;
        if LScenario.FWorld.Context.Storage.ActiveCount[WAR_STATE_MOVE] > 0 then
          Inc(AMovingTics);
      end;
      AFields := LScenario.FSteering.Fields.ComputeCount;
      AFogVisible := LScenario.FFog.CountState(wtsVisible);
    finally
      LScenario.Teardown;
    end;
  finally
    LScenario.Free;
  end;
end;

end.
