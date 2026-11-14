{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the cost of the path finding and of  }
{  the movement (only when asked)                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PathBench;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Two measurements, made only if the environment asks (no cost in a normal run). DELPHIDOOM_WAR_BENCH_PATH=rounds,file:
  ///   the same maps and the same pairs as `war_model_ref benchpaths` (Tools\Verifica\194): microseconds per A star search
  ///   and per flow field. DELPHIDOOM_WAR_BENCH_MOVE=units,tics,file: the same world as `war_model_ref benchmove`: units
  ///   that cross a map with obstacles, microseconds per unit and tic for the states (with the paths and the avoidance)
  ///   and for the rest (grid of the units, steps of the actions, fog)
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarPathBench = class(TObject)
  public
    [Test]
    procedure DovrebbeMisurareIlCostoDelleRicercheSeRichiesto;
    [Test]
    procedure DovrebbeMisurareIlCostoDelMovimentoSeRichiesto;
  end;

implementation

uses
  System.Diagnostics, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Map.Fog,
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.ActionRunner, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.FlowSteering, DelphiDoom.War.Path.Types, DelphiDoom.War.Path.AStar,
  DelphiDoom.War.Path.FlowFields, DelphiDoom.Tests.War.PathScenario, DelphiDoom.Tests.War.ModelObserver;

{ TTestWarPathBench }

procedure TTestWarPathBench.DovrebbeMisurareIlCostoDelleRicercheSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LRounds: Integer;
  LRound: Integer;
  LSeed: Cardinal;
  LScenario: TPathScenario;
  LGrid: TWarPathGrid;
  LAStar: TWarAStar;
  LFields: TWarFlowFields;
  LPath: TWarMapPath;
  LRingX: Integer;
  LRingY: Integer;
  LIndex: Integer;
  LSx: Integer;
  LSy: Integer;
  LEx: Integer;
  LEy: Integer;
  LWatch: TStopwatch;
  LAStarTicks: Int64;
  LFieldTicks: Int64;
  LAStars: Integer;
  LFieldCount: Integer;
  LSum: Cardinal;
  LLine: string;
  LOutput: TStringList;
begin
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_BENCH_PATH');
  if LRequest = '' then
  begin
    Assert.Pass('DELPHIDOOM_WAR_BENCH_PATH non impostata');
    Exit;
  end;
  LParts := LRequest.Split([',']);
  Assert.AreEqual<Integer>(2, Length(LParts), 'giri,file');
  LRounds := StrToInt(LParts[0]);
  LAStarTicks := 0;
  LFieldTicks := 0;
  LAStars := 0;
  LFieldCount := 0;
  LSum := 0;
  for LRound := 1 to LRounds do
    for LSeed := 1 to 20 do
    begin
      LScenario := TPathScenario.Create;
      LGrid := LScenario.BuildGrid(LSeed, LRingX, LRingY);
      LAStar := TWarAStar.Create(LGrid);
      LFields := TWarFlowFields.Create(LGrid);
      try
        for LIndex := 0 to 9 do
        begin
          LSx := LScenario.Below(WAR_MAP_TILES_WIDTH);
          LSy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
          LEx := LScenario.Below(WAR_MAP_TILES_WIDTH);
          LEy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
          LPath.Count := 0;
          LWatch := TStopwatch.StartNew;
          LAStar.FindPath(LSx, LSy, LEx, LEy, LPath);
          Inc(LAStarTicks, LWatch.ElapsedTicks);
          Inc(LAStars);
          Inc(LSum, Cardinal(LPath.Count));
        end;
        for LIndex := 0 to 3 do
        begin
          LSx := LScenario.Below(WAR_MAP_TILES_WIDTH);
          LSy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
          LWatch := TStopwatch.StartNew;
          LFields.Compute(LSx, LSy);
          Inc(LFieldTicks, LWatch.ElapsedTicks);
          Inc(LFieldCount);
        end;
      finally
        LFields.Free;
        LAStar.Free;
        LGrid.Free;
        LScenario.Free;
      end;
    end;
  LLine := Format('D A star: %d ricerche, %.1f us per ricerca; campi di flusso: %d, %.1f us per campo (somma di controllo %u)',
    [LAStars, 1E6 * LAStarTicks / TStopwatch.Frequency / LAStars, LFieldCount,
    1E6 * LFieldTicks / TStopwatch.Frequency / LFieldCount, LSum]);
  LOutput := TStringList.Create;
  try
    LOutput.Add(LLine);
    LOutput.SaveToFile(LParts[1]);
  finally
    LOutput.Free;
  end;
end;

procedure TTestWarPathBench.DovrebbeMisurareIlCostoDelMovimentoSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LUnits: Integer;
  LTics: Integer;
  LScenario: TPathScenario;
  LObserver: TModelObserver;
  LGrid: TWarPathGrid;
  LFog: TWarFogOfWar;
  LWorld: TWarModelWorld;
  LSteering: TWarFlowSteering;
  LPassable: TArray<Word>;
  LRingX: Integer;
  LRingY: Integer;
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
  LSlot: Integer;
  LSlots: array of Integer;
  LPositions: array[0..1] of TWarVec2;
  LState: PWarStateMove;
  LTic: Integer;
  LWatch: TStopwatch;
  LStateTicks: Int64;
  LRestTicks: Int64;
  LLast: Int64;
  LCount: Integer;
  LMoving: Integer;
  LLine: string;
  LOutput: TStringList;
  LPlayer: Integer;
begin
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_BENCH_MOVE');
  if LRequest = '' then
  begin
    Assert.Pass('DELPHIDOOM_WAR_BENCH_MOVE non impostata');
    Exit;
  end;
  LParts := LRequest.Split([',']);
  Assert.AreEqual<Integer>(3, Length(LParts), 'unita,tic,file');
  LUnits := StrToInt(LParts[0]);
  LTics := StrToInt(LParts[1]);
  LScenario := TPathScenario.Create;
  LObserver := TModelObserver.Create(12345);
  LFog := TWarFogOfWar.Create;
  LFog.Enabled := True;
  LScenario.FState := 4242;
  LScenario.Passable(0, LPassable, LRingX, LRingY);
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to 5 do
    begin
      LPassable[LY * WAR_MAP_TILES_WIDTH + LX] := 0;
      LPassable[LY * WAR_MAP_TILES_WIDTH + (WAR_MAP_TILES_WIDTH - 1 - LX)] := 0;
    end;
  LGrid := TWarPathGrid.Create(LPassable);
  LWorld := TWarModelFactory.CreateWorld(LObserver, TWarGridOccupancy.Create(LGrid), LObserver);
  try
    LWorld.Context.UnsignedDirections := True;
    TWarModelFactory.AttachFlowSteering(LWorld, LGrid);
    LSteering := LWorld.Context.Steering as TWarFlowSteering;
    TWarModelFactory.AttachFog(LWorld, LFog);
    for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
    begin
      LWorld.Context.Players[LPlayer]^.Gold := 5000;
      LWorld.Context.Players[LPlayer]^.Wood := 5000;
    end;
    SetLength(LSlots, 0);
    for LIndex := 0 to LUnits - 1 do
    begin
      LSlot := LWorld.Entities.CreateDude(WAR_UNIT_FOOTMAN, 1 + (LIndex mod 4), 1 + (LIndex div 4) mod 62, 0, False);
      if LSlot = 0 then
        Break;
      LWorld.Entities.SetInitialIdle(LSlot);
      SetLength(LSlots, Length(LSlots) + 1);
      LSlots[High(LSlots)] := LSlot;
    end;
    for LIndex := 0 to High(LSlots) do
    begin
      LPositions[0].X := (1 + (LIndex mod 4)) * 16 + 8;
      LPositions[0].Y := (1 + (LIndex div 4) mod 62) * 16 + 8;
      LPositions[1].X := (58 + (LIndex mod 4)) * 16 + 8;
      LPositions[1].Y := (1 + (LIndex div 4) mod 62) * 16 + 8;
      LState := LWorld.Machine.CreateMove(LSlots[LIndex], LPositions, False);
      LWorld.Machine.ResetState(LSlots[LIndex], PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
    end;
    LStateTicks := 0;
    LRestTicks := 0;
    for LTic := 1 to LTics do
    begin
      LWorld.AdvanceClock(0.016666668);
      LWatch := TStopwatch.StartNew;
      LWorld.Update;
      LLast := LWatch.ElapsedTicks;
      Inc(LStateTicks, LLast);
      LWatch := TStopwatch.StartNew;
      LWorld.Context.Combat.BuildNearUnits;
      TWarActionRunner.UpdateAll(LWorld.Context);
      LWorld.Context.FogUpdater.Update;
      Inc(LRestTicks, LWatch.ElapsedTicks);
    end;
    LCount := LWorld.Context.Pool.OfType[WAR_ENTITY_UNIT].Count;
    LMoving := LWorld.Context.Storage.ActiveCount[WAR_STATE_MOVE];
    LLine := Format('D %d unita'', %d tic, %d in marcia alla fine: stati %.4f us, griglia+azioni+nebbia %.4f us per unita'' e tic; %d campi',
      [LCount, LTics, LMoving, 1E6 * LStateTicks / TStopwatch.Frequency / (LCount * LTics),
      1E6 * LRestTicks / TStopwatch.Frequency / (LCount * LTics), LSteering.Fields.ComputeCount]);
  finally
    LWorld.Free;
    LFog.Free;
    LGrid.Free;
    LScenario.Free;
  end;
  LOutput := TStringList.Create;
  try
    LOutput.Add(LLine);
    LOutput.SaveToFile(LParts[2]);
  finally
    LOutput.Free;
  end;
end;

end.
