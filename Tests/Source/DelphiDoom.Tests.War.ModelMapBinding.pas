{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the model of a game map               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelMapBinding;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Builder, DelphiDoom.War.Map.Game, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.MapBinding, DelphiDoom.Tests.War.ModelObserver;

type
  [TestFixture]
  [Category('war')]
  TTestWarMapBinding = class(TObject)
  private
    FBuilder: TWarMapBuilder;
    FMap: TWarGameMap;
    FBinding: TWarMapBinding;
    FObserver: TModelObserver;
    FKeep: IInterface;
    function MakeInfo: TWarLevelInfo;
    procedure Bind;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCreareLeUnitaDelLivelloConGliStessiId;
    [Test]
    procedure DovrebbeDareAlleEntitaDelTerrenoGliIdDellaMappa;
    [Test]
    procedure DovrebbePortareNelModelloStradeMuraEGiocatori;
    [Test]
    procedure DovrebbeTenereLaListaDellaMappaUgualeAlleUnitaDelModello;
    [Test]
    procedure DovrebbeFarVedereAllaMappaLeUnitaCheSiMuovonoEQuelleNuove;
    [Test]
    procedure DovrebbeSegnareChiMuoreComeSparito;
    [Test]
    procedure DovrebbeRiportareNelModelloCioCheLaNebbiaHaVisto;
    [Test]
    procedure DovrebbeDareAiComandiLaGrigliaELaNebbiaDellaMappa;
    [Test]
    procedure DovrebbeRaccogliereNelleForesteDellaMappa;
    [Test]
    procedure DovrebbeSollevareSeGliIdNonCoincidono;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Map.Factory, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.Model.Construction.Types,
  DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Math, DelphiDoom.Tests.War.MapSupport;

{ TTestWarMapBinding }

procedure TTestWarMapBinding.Setup;
begin
  FBuilder := TWarMapFactory.CreateBuilder;
  FObserver := TModelObserver.Create(7);
  FKeep := FObserver;
end;

procedure TTestWarMapBinding.TearDown;
begin
  FBinding.Free;
  FBinding := nil;
  FMap.Free;
  FMap := nil;
  FBuilder.Free;
  FKeep := nil;
end;

function TTestWarMapBinding.MakeInfo: TWarLevelInfo;
var
  LConstruct: TWarLevelConstruct;
begin
  Result := TMapFixtures.BasicInfo;
  Result.StartEntities := [
    TMapFixtures.StartUnit(10, 10, WAR_UNIT_TOWNHALL_HUMANS, 0, wrkNone, 0),
    TMapFixtures.StartUnit(14, 10, WAR_UNIT_FOOTMAN, 0, wrkNone, 0),
    TMapFixtures.StartUnit(14, 12, WAR_UNIT_PEASANT, 0, wrkNone, 0),
    TMapFixtures.StartUnit(40, 40, WAR_UNIT_TOWNHALL_ORCS, 1, wrkNone, 0),
    TMapFixtures.StartUnit(20, 20, WAR_UNIT_GOLDMINE, 4, wrkGold, 10000)];
  LConstruct := Default(TWarLevelConstruct);
  LConstruct.ConstructType := wctRoad;
  LConstruct.X1 := 30;
  LConstruct.Y1 := 30;
  LConstruct.X2 := 33;
  LConstruct.Y2 := 30;
  Result.StartRoads := [LConstruct];
  LConstruct.ConstructType := wctWall;
  LConstruct.X1 := 50;
  LConstruct.Y1 := 50;
  LConstruct.X2 := 50;
  LConstruct.Y2 := 52;
  Result.StartWalls := [LConstruct];
end;

procedure TTestWarMapBinding.Bind;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  FMap := FBuilder.Build(TMapFixtures.MakeLevel(MakeInfo, LPassable), TMapFixtures.Tileset);
  FBinding := TWarModelFactory.CreateMapBinding(FMap, FObserver, FObserver);
end;

procedure TTestWarMapBinding.DovrebbeCreareLeUnitaDelLivelloConGliStessiId;
var
  LBefore: TArray<TWarMapUnit>;
  LPassable: TArray<Word>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  FMap := FBuilder.Build(TMapFixtures.MakeLevel(MakeInfo, LPassable), TMapFixtures.Tileset);
  LBefore := FMap.Units.ToArray;
  FBinding := TWarModelFactory.CreateMapBinding(FMap, FObserver, FObserver);
  Assert.AreEqual<Integer>(5, Length(LBefore));
  Assert.AreEqual(5, FBinding.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  for LIndex := 0 to High(LBefore) do
  begin
    // the unit that the map made from the level and the one that TWarEntityManager made are the same unit
    LSlot := FBinding.World.Context.Pool.FindSlot(LBefore[LIndex].Id);
    Assert.AreNotEqual(0, LSlot, Format('unita'' %d', [LIndex]));
    LEntity := FBinding.World.Context.Pool.Slots[LSlot];
    Assert.AreEqual(LBefore[LIndex].UnitType, LEntity^.UnitData.UnitType);
    Assert.AreEqual(LBefore[LIndex].TileX, LEntity^.UnitData.TileX);
    Assert.AreEqual(LBefore[LIndex].TileY, LEntity^.UnitData.TileY);
    Assert.AreEqual(LBefore[LIndex].SizeX, LEntity^.UnitData.SizeX);
    Assert.AreEqual(LBefore[LIndex].SizeY, LEntity^.UnitData.SizeY);
    Assert.AreEqual<Integer>(LBefore[LIndex].Player, LEntity^.UnitData.Player);
    Assert.AreEqual(LBefore[LIndex].Amount, LEntity^.UnitData.Amount);
    Assert.AreEqual(LBefore[LIndex].MaxHp, LEntity^.UnitData.MaxHp);
    Assert.AreEqual(LBefore[LIndex].Hp, LEntity^.UnitData.Hp);
    Assert.AreEqual(LBefore[LIndex].MaxMana, LEntity^.UnitData.MaxMana);
    Assert.AreEqual(LBefore[LIndex].Mana, LEntity^.UnitData.Mana);
    Assert.AreEqual(LBefore[LIndex].Armor, LEntity^.UnitData.Armor);
    Assert.AreEqual(LBefore[LIndex].Range, LEntity^.UnitData.Range);
    Assert.AreEqual(LBefore[LIndex].MinDamage, LEntity^.UnitData.MinDamage);
    Assert.AreEqual(LBefore[LIndex].RndDamage, LEntity^.UnitData.RndDamage);
    Assert.AreEqual(LBefore[LIndex].Decay, LEntity^.UnitData.Decay);
    Assert.IsTrue(LEntity^.HasStateMachine);
  end;
  Assert.AreEqual<Integer>(Integer(FMap.LastEntityId), FBinding.World.Context.Pool.LastId, 'gli stessi id dati finora');
end;

procedure TTestWarMapBinding.DovrebbeDareAlleEntitaDelTerrenoGliIdDellaMappa;
var
  LPool: TList<Integer>;
begin
  Bind;
  LPool := FBinding.World.Context.Pool.OfType[WAR_ENTITY_FOREST];
  Assert.AreEqual(FMap.Forests.Count, LPool.Count);
  Assert.AreEqual<Integer>(FMap.Forests[0].Id, FBinding.World.Context.Pool.Slots[LPool[0]]^.Id);
  Assert.AreEqual<Integer>(FMap.Forests.EditingForest.Id, FBinding.World.Context.Pool.Slots[LPool[LPool.Count - 1]]^.Id);
  Assert.AreEqual<Integer>(FMap.RoadId,
    FBinding.World.Context.Pool.Slots[FBinding.World.Context.Pool.OfType[WAR_ENTITY_ROAD][0]]^.Id);
  Assert.AreEqual<Integer>(FMap.WallId,
    FBinding.World.Context.Pool.Slots[FBinding.World.Context.Pool.OfType[WAR_ENTITY_WALL][0]]^.Id);
  Assert.AreEqual<Integer>(FMap.RuinsId,
    FBinding.World.Context.Pool.Slots[FBinding.World.Context.Pool.OfType[WAR_ENTITY_RUIN][0]]^.Id);
end;

procedure TTestWarMapBinding.DovrebbePortareNelModelloStradeMuraEGiocatori;
var
  LContext: PWarPlayerInfo;
begin
  Bind;
  Assert.AreEqual(FMap.Road.Count, FBinding.World.Context.Roads.Count);
  Assert.AreEqual<Integer>(FMap.Road.Pieces[0].PieceType, FBinding.World.Context.Roads.Pieces[0].PieceType);
  Assert.AreEqual(FMap.Wall.Count, FBinding.World.Context.Walls.Count);
  Assert.AreEqual(WAR_WALL_MAX_HP, FBinding.World.Context.Walls[0]^.Hp);
  Assert.AreEqual<Integer>(FMap.Wall.Pieces[1].PieceType, FBinding.World.Context.Walls[1]^.PieceType);
  LContext := FBinding.World.Context.Players[0];
  Assert.AreEqual(2000, LContext^.Gold);
  Assert.IsTrue(LContext^.Race = wraHumans);
  Assert.AreEqual(800, FBinding.World.Context.Players[1]^.Wood);
  Assert.AreEqual(2, FBinding.World.Context.PlayersCount);
  Assert.AreEqual<Single>(7 * 16, FBinding.World.Context.ViewportTop);
  // the wall takes its tiles when its idle state has run
  FBinding.Tick(0.016666668);
  FBinding.Tick(0.016666668);
  Assert.AreEqual<Integer>(FMap.WallId, FMap.Grid.GetTileEntityId(50, 51));
end;

procedure TTestWarMapBinding.DovrebbeTenereLaListaDellaMappaUgualeAlleUnitaDelModello;
var
  LIndex: Integer;
  LSlot: Integer;
begin
  Bind;
  Assert.AreEqual(5, FMap.Units.Count);
  for LIndex := 0 to FMap.Units.Count - 1 do
  begin
    LSlot := FBinding.World.Context.Pool.OfType[WAR_ENTITY_UNIT][LIndex];
    Assert.AreEqual<Integer>(FBinding.World.Context.Pool.Slots[LSlot]^.Id, FMap.Units[LIndex].Id);
    Assert.AreEqual(FBinding.World.Context.Pool.Slots[LSlot]^.UnitData.Direction, FMap.Units[LIndex].Direction,
      'la direzione e'' quella del modello');
    Assert.IsFalse(FMap.Units[LIndex].IsGone);
  end;
  // the fog and the minimap of the map work on the list as before
  FMap.UpdateFog;
  Assert.IsTrue(FMap.Fog.IsTileVisible(14, 10));
  Assert.AreEqual<Integer>(64 * 64 * 4, Length(FMap.RenderMinimap));
end;

procedure TTestWarMapBinding.DovrebbeFarVedereAllaMappaLeUnitaCheSiMuovonoEQuelleNuove;
var
  LFootman: Integer;
  LIndex: Integer;
  LNew: Integer;
begin
  Bind;
  LFootman := FBinding.World.Context.Pool.FindSlot(FMap.Units[1].Id);
  FBinding.World.Context.Selection.Assign([FMap.Units[1].Id]);
  FBinding.Commands.Execute(WAR_COMMAND_MOVE, TWarModelMath.TileToMap(TWarModelMath.Vec(24, 10), True));
  for LIndex := 1 to 600 do
    FBinding.Tick(0.016666668);
  Assert.AreEqual(Integer(Trunc(TWarUnitGeometry.Tile(FBinding.World.Context.Pool.Slots[LFootman]).X)), FMap.Units[1].TileX);
  Assert.IsTrue(FMap.Units[1].TileX > 14, 'il fante ha camminato e la mappa lo sa');
  LNew := FBinding.World.Entities.CreateDude(WAR_UNIT_ARCHER, 30, 12, 0, False);
  FBinding.World.Entities.SetInitialIdle(LNew);
  FBinding.Tick(0.016666668);
  Assert.AreEqual(6, FMap.Units.Count);
  Assert.AreEqual<Integer>(WAR_UNIT_ARCHER, FMap.Units[5].UnitType);
end;

procedure TTestWarMapBinding.DovrebbeSegnareChiMuoreComeSparito;
var
  LFootman: Integer;
begin
  Bind;
  LFootman := FBinding.World.Context.Pool.FindSlot(FMap.Units[1].Id);
  FBinding.World.Combat.TakeDamage(LFootman, 500, 0);
  FBinding.Tick(0.016666668);
  Assert.IsTrue(FMap.Units[1].IsGone);
  Assert.AreEqual(0, FMap.Units[1].Hp);
end;

procedure TTestWarMapBinding.DovrebbeRiportareNelModelloCioCheLaNebbiaHaVisto;
var
  LUnit: TWarMapUnit;
  LSlot: Integer;
begin
  Bind;
  LUnit := FMap.Units[3];
  LUnit.HasBeenSeen := True;
  FMap.Units[3] := LUnit;
  LSlot := FBinding.World.Context.Pool.FindSlot(LUnit.Id);
  Assert.IsFalse(FBinding.World.Context.Pool.Slots[LSlot]^.UnitData.HasBeenSeen);
  FBinding.SyncUnits;
  Assert.IsTrue(FBinding.World.Context.Pool.Slots[LSlot]^.UnitData.HasBeenSeen);
  Assert.IsTrue(FMap.Units[3].HasBeenSeen);
end;

procedure TTestWarMapBinding.DovrebbeDareAiComandiLaGrigliaELaNebbiaDellaMappa;
begin
  Bind;
  Assert.AreEqual<Integer>(FMap.Units[0].Id, FBinding.CommandMap.EntityIdAt(10, 10));
  Assert.IsTrue(FBinding.CommandMap.IsTileUnknown(60, 60), 'la nebbia e'' quella della mappa');
  Assert.AreSame(FMap, FBinding.Map);
end;

procedure TTestWarMapBinding.DovrebbeRaccogliereNelleForesteDellaMappa;
var
  LPeasant: Integer;
begin
  Bind;
  FMap.UpdateFog;
  LPeasant := FBinding.World.Context.Pool.FindSlot(FMap.Units[2].Id);
  FBinding.World.Context.Selection.Assign([FMap.Units[2].Id]);
  Assert.IsTrue(FBinding.Commands.Gather.Harvest(FBinding.World.Context.Pool.FindSlot(FMap.Forests[0].Id), 7, 6));
  FBinding.Tick(0.016666668);
  Assert.IsTrue(FBinding.World.Machine.Contains(LPeasant, WAR_STATE_WOOD));
end;

procedure TTestWarMapBinding.DovrebbeSollevareSeGliIdNonCoincidono;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  FMap := FBuilder.Build(TMapFixtures.MakeLevel(MakeInfo, LPassable), TMapFixtures.Tileset);
  // an entity that the model does not know took an id of the map: the units would not be those of the level
  FMap.AllocateEntityId;
  FMap.SpawnUnit(WAR_UNIT_FOOTMAN, 30, 30, 0, wrkNone, 0);
  Assert.WillRaise(
    procedure
    begin
      FBinding := TWarModelFactory.CreateMapBinding(FMap, FObserver, FObserver);
    end, EWarException);
end;

end.
