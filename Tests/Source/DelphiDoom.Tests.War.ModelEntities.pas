{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - creating and removing units, the     }
{  questions about them and the assembly of the model                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelEntities;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ModelRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarEntityManager = class(TObject)
  private
    FRig: TModelRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCreareUnaUnitaConLeStatisticheDelDatabase;
    [Test]
    procedure DovrebbeDareTuttaLaManaAUnEvocatoEUnaFissaAGliAltri;
    [Test]
    procedure DovrebbeCreareUnEdificioConIPuntiFerita;
    [Test]
    procedure DovrebbeMettereLaPosizioneEIlTipoNelleListe;
    [Test]
    procedure DovrebbeTirareLaDirezioneDalGeneratore;
    [Test]
    procedure DovrebbeLasciareUnaUnitaDaAddestrareFuoriDalleListe;
    [Test]
    procedure DovrebbeCreareUnEdificioDaCostruireConLoStatoDiCostruzione;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIlTipoNonHaMisuraONonHaStatistiche;
    [Test]
    procedure DovrebbeDareSlotZeroSeIlPoolEPieno;
    [Test]
    procedure DovrebbeTogliereUnaEntitaDalleListeEDallaGriglia;
    [Test]
    procedure DovrebbeIgnorareLaRimozioneDiUnIdCheNonEsiste;
    [Test]
    procedure DovrebbeDareIlRisultatoDelleDomandeSullUnitaSenzaStati;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarUnitQueries = class(TObject)
  private
    FRig: TModelRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDireChiENemicoDiChi;
    [Test]
    procedure DovrebbeDireChiPuoAttaccare;
    [Test]
    procedure DovrebbeTrovareIlPrimoNemicoVicinoNellOrdineDelleUnita;
    [Test]
    procedure DovrebbeTrovareChiAttaccaUnaUnita;
    [Test]
    procedure DovrebbeContareLeUnita;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarModelWorld = class(TObject)
  public
    [Test]
    procedure DovrebbeUsareLeTabelleDelGiocoSenzaFinti;
    [Test]
    procedure DovrebbeUsareLeDipendenzeDate;
    [Test]
    procedure DovrebbeFarAndareAvantiIlTempo;
    [Test]
    procedure DovrebbeRifiutareUnGiocatoreCheNonEsiste;
    [Test]
    procedure DovrebbeLasciareLaVelocitaDelleUnitaSenzaStatistichePariAZero;
    [Test]
    procedure DovrebbeUsareLEventoNulloELaGrigliaNulla;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.World, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.Database, DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.NullServices,
  DelphiDoom.War.Sound.SeededRandom;

{ TTestWarEntityManager }

procedure TTestWarEntityManager.Setup;
begin
  FRig := TModelRig.Create;
end;

procedure TTestWarEntityManager.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarEntityManager.DovrebbeCreareUnaUnitaConLeStatisticheDelDatabase;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
begin
  LSlot := FRig.World.Entities.CreateDude(WAR_UNIT_ARCHER, 7, 9, 0, False);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  Assert.AreEqual<Integer>(60, LUnit^.Hp);
  Assert.AreEqual<Integer>(60, LUnit^.MaxHp);
  Assert.AreEqual<Integer>(1, LUnit^.Armor);
  Assert.AreEqual<Integer>(5, LUnit^.Range);
  Assert.AreEqual<Integer>(4, LUnit^.MinDamage);
  Assert.AreEqual<Integer>(0, LUnit^.RndDamage);
  Assert.AreEqual<Integer>(-1, LUnit^.Decay);
  Assert.AreEqual<Integer>(7, LUnit^.TileX);
  Assert.AreEqual<Integer>(9, LUnit^.TileY);
  Assert.AreEqual<Single>(7 * 16, FRig.Entity(LSlot)^.Position.X);
  Assert.AreEqual<Single>(9 * 16, FRig.Entity(LSlot)^.Position.Y);
  Assert.AreEqual<Single>(1.0, LUnit^.ManaTime);
  Assert.AreEqual<Integer>(WAR_ACTION_IDLE, LUnit^.ActionType);
  Assert.AreEqual<Integer>(0, FRig.Entity(LSlot)^.StateMachine.Depth);
end;

procedure TTestWarEntityManager.DovrebbeDareTuttaLaManaAUnEvocatoEUnaFissaAGliAltri;
var
  LSpider: Integer;
  LCleric: Integer;
begin
  LSpider := FRig.World.Entities.CreateDude(WAR_UNIT_SPIDER, 5, 5, 0, False);
  LCleric := FRig.World.Entities.CreateDude(WAR_UNIT_CLERIC, 6, 5, 0, False);
  Assert.AreEqual<Integer>(255, FRig.Entity(LSpider)^.UnitData.Mana);
  Assert.AreEqual<Integer>(100, FRig.Entity(LCleric)^.UnitData.Mana);
  Assert.AreEqual<Integer>(45, FRig.Entity(LSpider)^.UnitData.Decay);
end;

procedure TTestWarEntityManager.DovrebbeCreareUnEdificioConIPuntiFerita;
var
  LSlot: Integer;
begin
  LSlot := FRig.World.Entities.CreateBuilding(WAR_UNIT_TOWNHALL_HUMANS, 20, 20, 0, False);
  Assert.AreEqual<Integer>(2500, FRig.Entity(LSlot)^.UnitData.Hp);
  Assert.AreEqual<Integer>(3, FRig.Entity(LSlot)^.UnitData.SizeX);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSlot));
  Assert.IsTrue(FRig.Entity(LSlot)^.StateMachine.Depth = 1);
end;

procedure TTestWarEntityManager.DovrebbeMettereLaPosizioneEIlTipoNelleListe;
var
  LSlot: Integer;
begin
  LSlot := FRig.World.Entities.CreateDude(WAR_UNIT_PEON, 5, 5, 0, False);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(LSlot, FRig.World.Context.Pool.UnitsOfType[WAR_UNIT_PEON][0]);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.UnitsOfType[WAR_UNIT_PEASANT].Count);
end;

procedure TTestWarEntityManager.DovrebbeTirareLaDirezioneDalGeneratore;
var
  LRig: TModelRig;
  LSlot: Integer;
begin
  LRig := TModelRig.Create(TScriptedRandom.Create([5]));
  try
    LSlot := LRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 5, 5, 0, False);
    Assert.AreEqual<Integer>(5, LRig.Entity(LSlot)^.UnitData.Direction);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarEntityManager.DovrebbeLasciareUnaUnitaDaAddestrareFuoriDalleListe;
var
  LSlot: Integer;
begin
  LSlot := FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 5, 5, 0, True);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(LSlot, FRig.World.Context.Pool.FindSlot(FRig.Entity(LSlot)^.Id));
end;

procedure TTestWarEntityManager.DovrebbeCreareUnEdificioDaCostruireConLoStatoDiCostruzione;
var
  LSlot: Integer;
  LBuild: PWarStateBuild;
begin
  LSlot := FRig.World.Entities.CreateBuilding(WAR_UNIT_BARRACKS_HUMANS, 20, 20, 0, True);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_BUILD, FRig.ActiveType(LSlot));
  LBuild := PWarStateBuild(FRig.World.Machine.ActiveState(LSlot));
  Assert.AreEqual<Single>(120, LBuild^.TotalBuildTime);
  Assert.AreEqual<Integer>(600, LBuild^.GoldCost);
  Assert.AreEqual<Integer>(500, LBuild^.WoodCost);
  Assert.IsTrue(LBuild^.TransactionApplied);
  Assert.IsFalse(LBuild^.Cancelled);
end;

procedure TTestWarEntityManager.DovrebbeSollevareEccezioneSeIlTipoNonHaMisuraONonHaStatistiche;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.World.Entities.CreateDude(WAR_UNIT_DRAGON_CYCLOPS_GIANT, 5, 5, 0, False);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.World.Entities.CreateDude(WAR_UNIT_WOUNDED, 5, 5, 0, False);
    end, EWarException);
  // nothing is left behind: the original makes the entity and then stops on an assert
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.EntityCount);
end;

procedure TTestWarEntityManager.DovrebbeDareSlotZeroSeIlPoolEPieno;
var
  LIndex: Integer;
begin
  for LIndex := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    Assert.AreNotEqual<Integer>(0, FRig.World.Entities.CreateDude(WAR_UNIT_PEASANT, 5, 5, 0, True));
  Assert.AreEqual<Integer>(0, FRig.World.Entities.CreateDude(WAR_UNIT_PEASANT, 5, 5, 0, True));
  Assert.AreEqual<Integer>(0, FRig.World.Entities.CreateBuilding(WAR_UNIT_FARM_HUMANS, 5, 5, 0, False));
end;

procedure TTestWarEntityManager.DovrebbeTogliereUnaEntitaDalleListeEDallaGriglia;
var
  LSlot: Integer;
  LId: Word;
begin
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5);
  LId := FRig.Entity(LSlot)^.Id;
  Assert.IsTrue(FRig.Grid.IsStatic(5, 5));
  FRig.World.Entities.RemoveEntityById(LId);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.FindSlot(LId));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.UnitsOfType[WAR_UNIT_FOOTMAN].Count);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.EntityCount);
  Assert.IsTrue(FRig.Grid.IsEmpty(5, 5));
end;

procedure TTestWarEntityManager.DovrebbeIgnorareLaRimozioneDiUnIdCheNonEsiste;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5);
  FRig.World.Entities.RemoveEntityById(0);
  FRig.World.Entities.RemoveEntityById(777);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Pool.EntityCount);
end;

procedure TTestWarEntityManager.DovrebbeDareIlRisultatoDelleDomandeSullUnitaSenzaStati;
var
  LSlot: Integer;
begin
  LSlot := FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 5, 5, 0, False);
  Assert.IsFalse(FRig.World.Machine.IsDead(LSlot));
  Assert.IsFalse(FRig.World.Machine.IsBuilding(LSlot));
  Assert.IsFalse(FRig.World.Machine.HasPending(LSlot, WAR_STATE_IDLE));
  FRig.World.Entities.SetInitialIdle(LSlot);
  Assert.IsTrue(FRig.World.Machine.HasPending(LSlot, WAR_STATE_IDLE));
end;

{ TTestWarUnitQueries }

procedure TTestWarUnitQueries.Setup;
begin
  FRig := TModelRig.Create;
end;

procedure TTestWarUnitQueries.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarUnitQueries.DovrebbeDireChiENemicoDiChi;
var
  LHuman: Integer;
  LOrc: Integer;
  LAlly: Integer;
  LNeutral: Integer;
begin
  LHuman := FRig.AddDude(WAR_UNIT_PEASANT, 5, 5, 0);
  LOrc := FRig.AddDude(WAR_UNIT_PEON, 40, 40, 1);
  LAlly := FRig.AddDude(WAR_UNIT_PEASANT, 6, 5, 0);
  LNeutral := FRig.AddDude(WAR_UNIT_OGRE, 40, 5, 4);
  Assert.IsTrue(FRig.World.Queries.AreEnemies(LHuman, LOrc));
  Assert.IsFalse(FRig.World.Queries.AreEnemies(LHuman, LAlly));
  Assert.IsFalse(FRig.World.Queries.AreEnemies(LHuman, LHuman));
  // nobody is the enemy of a neutral unit, but a neutral unit is the enemy of the others
  Assert.IsFalse(FRig.World.Queries.AreEnemies(LHuman, LNeutral));
  Assert.IsTrue(FRig.World.Queries.AreEnemies(LNeutral, LHuman));
end;

procedure TTestWarUnitQueries.DovrebbeDireChiPuoAttaccare;
var
  LWarrior: Integer;
  LTarget: Integer;
  LWorker: Integer;
begin
  LWarrior := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 40, 40, 1);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 6, 5, 0);
  Assert.IsTrue(FRig.World.Queries.CanAttack(LWarrior, LTarget));
  Assert.IsFalse(FRig.World.Queries.CanAttack(LWorker, LTarget));
  FRig.World.Combat.TakeDamage(LTarget, 255, 255);
  Assert.IsFalse(FRig.World.Queries.CanAttack(LWarrior, LTarget));
  FRig.Tick;
  Assert.IsFalse(FRig.World.Queries.CanAttack(LWarrior, LTarget));
  FRig.World.Combat.TakeDamage(LWarrior, 255, 255);
  Assert.IsFalse(FRig.World.Queries.CanAttack(LWarrior, FRig.AddDude(WAR_UNIT_GRUNT, 41, 40, 1)));
end;

procedure TTestWarUnitQueries.DovrebbeTrovareIlPrimoNemicoVicinoNellOrdineDelleUnita;
var
  LWatcher: Integer;
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FRig.AddDude(WAR_UNIT_PEON, 12, 10, 1);
  LSecond := FRig.AddDude(WAR_UNIT_PEON, 11, 10, 1);
  LWatcher := FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 10, 10, 0, False);
  Assert.AreEqual<Integer>(LFirst, FRig.World.Queries.NearEnemy(LWatcher));
  FRig.Entity(LFirst)^.UnitData.Invisible := True;
  Assert.AreEqual<Integer>(LSecond, FRig.World.Queries.NearEnemy(LWatcher));
  FRig.Entity(LSecond)^.Position.X := 40 * 16;
  Assert.AreEqual<Integer>(0, FRig.World.Queries.NearEnemy(LWatcher));
end;

procedure TTestWarUnitQueries.DovrebbeTrovareChiAttaccaUnaUnita;
var
  LVictim: Integer;
  LAttacker: Integer;
  LAttack: PWarStateAttack;
begin
  LVictim := FRig.AddDude(WAR_UNIT_PEASANT, 5, 5, 0);
  LAttacker := FRig.AddDude(WAR_UNIT_GRUNT, 30, 30, 1);
  Assert.AreEqual<Integer>(0, FRig.World.Queries.Attacker(LVictim));
  LAttack := FRig.World.Machine.CreateAttack(LAttacker, FRig.Entity(LVictim)^.Id, FRig.Entity(LVictim)^.Position);
  FRig.World.Machine.ResetState(LAttacker, PWarStateBase(LAttack), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  Assert.AreEqual<Integer>(LAttacker, FRig.World.Queries.Attacker(LVictim));
end;

procedure TTestWarUnitQueries.DovrebbeContareLeUnita;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  FRig.AddDude(WAR_UNIT_FOOTMAN, 6, 5, 0);
  FRig.AddDude(WAR_UNIT_SKELETON, 7, 5, 0);
  FRig.AddDude(WAR_UNIT_FOOTMAN, 8, 5, 1);
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 20, 0);
  Assert.AreEqual<Integer>(2, FRig.World.Queries.CountDudes(0));
  Assert.AreEqual<Integer>(2, FRig.World.Queries.CountUnitsOfType(0, WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(1, FRig.World.Queries.CountBuildingsOfType(0, WAR_UNIT_FARM_HUMANS, False));
  Assert.AreEqual<Integer>(1, FRig.World.Queries.CountBuildingsOfType(0, WAR_UNIT_FARM_HUMANS, True));
end;

{ TTestWarModelWorld }

procedure TTestWarModelWorld.DovrebbeUsareLeTabelleDelGiocoSenzaFinti;
var
  LWorld: TWarModelWorld;
  LSlot: Integer;
begin
  LWorld := TWarModelFactory.CreateWorld(TWarSeededRandom.Create(1));
  try
    LSlot := LWorld.Entities.CreateDude(WAR_UNIT_FOOTMAN, 5, 5, 0, False);
    LWorld.Entities.SetInitialIdle(LSlot);
    LWorld.AdvanceClock(0.1);
    LWorld.Update;
    Assert.AreEqual<Integer>(1, LWorld.Context.Pool.EntityCount);
    Assert.AreEqual<Integer>(WAR_STATE_IDLE, LWorld.Machine.ActiveState(LSlot)^.StateType);
    Assert.IsFalse(Assigned(LWorld.Context.Steering));
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarModelWorld.DovrebbeUsareLeDipendenzeDate;
var
  LWorld: TWarModelWorld;
  LDatabase: IWarDatabase;
begin
  LDatabase := TWarDatabase.Create;
  LWorld := TWarModelFactory.CreateWorld(TWarSeededRandom.Create(1), TWarNullOccupancy.Create,
    TWarNullModelEvents.Create, LDatabase);
  try
    Assert.AreEqual<Integer>(60, LWorld.Context.Database.GetUnitStats(WAR_UNIT_FOOTMAN).Hp);
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarModelWorld.DovrebbeFarAndareAvantiIlTempo;
var
  LWorld: TWarModelWorld;
begin
  LWorld := TWarModelFactory.CreateWorld(TWarSeededRandom.Create(1));
  try
    LWorld.AdvanceClock(0.25);
    LWorld.AdvanceClock(0.25);
    Assert.AreEqual<Double>(0.5, LWorld.Context.Clock^.GameTime);
    Assert.AreEqual<Single>(0.25, LWorld.Context.Clock^.DeltaTime);
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarModelWorld.DovrebbeRifiutareUnGiocatoreCheNonEsiste;
var
  LWorld: TWarModelWorld;
begin
  LWorld := TWarModelFactory.CreateWorld(TWarSeededRandom.Create(1));
  try
    Assert.WillRaise(
      procedure
      begin
        LWorld.Context.Players[WAR_MAX_PLAYERS_COUNT];
      end, EWarException);
    Assert.AreEqual<Integer>(WAR_MAX_PLAYERS_COUNT, LWorld.Context.PlayersCount);
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarModelWorld.DovrebbeLasciareLaVelocitaDelleUnitaSenzaStatistichePariAZero;
var
  LWorld: TWarModelWorld;
begin
  LWorld := TWarModelFactory.CreateWorld(TWarSeededRandom.Create(1));
  try
    Assert.AreEqual<Single>(0, LWorld.Context.UnitSpeed(WAR_UNIT_WOUNDED, 0));
    Assert.AreEqual<Single>(0, LWorld.Context.UnitSpeed(-1, 0));
    Assert.AreEqual<Single>(0, LWorld.Context.UnitSpeed(WAR_UNIT_COUNT, 0));
    Assert.AreEqual<Single>(LWorld.Context.UnitSpeed(WAR_UNIT_KNIGHT, 2), LWorld.Context.UnitSpeed(WAR_UNIT_KNIGHT, 7));
    Assert.AreEqual<Single>(LWorld.Context.UnitSpeed(WAR_UNIT_KNIGHT, 0), LWorld.Context.UnitSpeed(WAR_UNIT_KNIGHT, -3));
    Assert.IsTrue(LWorld.Context.UnitSpeed(WAR_UNIT_KNIGHT, 2) > LWorld.Context.UnitSpeed(WAR_UNIT_KNIGHT, 0));
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarModelWorld.DovrebbeUsareLEventoNulloELaGrigliaNulla;
var
  LEvents: IWarModelEvents;
  LOccupancy: IWarOccupancy;
begin
  LEvents := TWarNullModelEvents.Create;
  LOccupancy := TWarNullOccupancy.Create;
  LEvents.FlashStatus(wsmNotEnoughFood);
  LEvents.EntityLeftSelection(1);
  LEvents.UnitDied(1, 0, Default(TWarVec2));
  LEvents.BuildingCollapsing(1, 0, Default(TWarVec2));
  LEvents.BuildingDamaged(1, 50);
  LOccupancy.SetStaticEntity(0, 0, 1, 1, 1);
  LOccupancy.SetFreeTiles(0, 0, 1, 1);
  Assert.IsTrue(Assigned(LEvents));
end;

end.
