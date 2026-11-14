{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - what the gatherers use               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.GatherSupport;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.GatherRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarGatherSupport = class(TObject)
  private
    FRig: TGatherRig;
    procedure Near(AExpected, AActual, ATolerance: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLaCasellaSteessaSeELibera;
    [Test]
    procedure DovrebbeTrovareLaPrimaCasellaLiberaNellOrdineDelC;
    [Test]
    procedure DovrebbeDareLaCasellaDiPartenzaSeNonCeNessunaLibera;
    [TestCase('Dentro', '11,11,11,11')]
    [TestCase('Sopra a sinistra', '5,5,10,10')]
    [TestCase('Sopra', '12,5,12,10')]
    [TestCase('Sopra a destra', '30,5,13,10')]
    [TestCase('A destra', '30,11,13,11')]
    [TestCase('Sotto a destra', '30,30,13,12')]
    [TestCase('Sotto', '12,30,12,12')]
    [TestCase('Sotto a sinistra', '5,30,10,12')]
    [TestCase('A sinistra', '5,11,10,11')]
    procedure DovrebbeDareIlPuntoDelRettangoloPiuVicino(APointX, APointY, AExpectedX, AExpectedY: Integer);
    [Test]
    procedure DovrebbeMisurareLaDistanzaInCaselleDalBordoDelBersaglio;
    [Test]
    procedure DovrebbeTrovareIlMunicipioPiuVicino;
    [Test]
    procedure DovrebbeNonTrovareNulla;
    [Test]
    procedure DovrebbeDareIlMunicipioDellaRazza;
    [Test]
    procedure DovrebbeLasciareCheLaMinieraPartaUnaSolaVoltaPerEsaurimento;
    [Test]
    procedure DovrebbeNonDareMenoDiZeroDallaMiniera;
    [Test]
    procedure DovrebbeEseguireIPassiDellaRaccoltaEImpostareLUltimoPasso;
    [Test]
    procedure DovrebbeSpecchiareLUnitaCheGuardaVersoOvest;
    [Test]
    procedure DovrebbeLasciareStareLeAzioniSenzaPassi;
    [Test]
    procedure DovrebbeRipartireDaCapoUnAzione;
    [Test]
    procedure DovrebbeDareNilSeLoStorageDegliStatiEPieno;
    [Test]
    procedure DovrebbeUsareLImmagineDelFanteSeIlTipoNonEInTabella;
    [Test]
    procedure DovrebbeUsareEventiMutiSeNessunoAscolta;
  end;

implementation

uses
  System.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.TargetGeometry,
  DelphiDoom.War.Model.UnitSearch, DelphiDoom.War.Model.Mine, DelphiDoom.War.Model.ActionRunner,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.UnitSprites, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.State.GatherFactory,
  DelphiDoom.War.Model.GatherWorld;

{ TTestWarGatherSupport }

procedure TTestWarGatherSupport.Near(AExpected, AActual, ATolerance: Single);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= ATolerance, Format('atteso %f, trovato %f', [AExpected, AActual]));
end;

procedure TTestWarGatherSupport.Setup;
begin
  FRig := TGatherRig.Create(3);
end;

procedure TTestWarGatherSupport.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarGatherSupport.DovrebbeDareLaCasellaSteessaSeELibera;
begin
  Assert.AreEqual(Point(10, 10), FRig.Rig.Grid.FindEmptyTile(10, 10));
end;

procedure TTestWarGatherSupport.DovrebbeTrovareLaPrimaCasellaLiberaNellOrdineDelC;
begin
  // a mine of 3 by 3 at (10, 10): from its center (11, 11) the first free one is the tile above the top row
  FRig.Rig.Grid.SetStaticEntity(10, 10, 3, 3, 5);
  Assert.AreEqual(Point(11, 9), FRig.Rig.Grid.FindEmptyTile(11, 11));
end;

procedure TTestWarGatherSupport.DovrebbeDareLaCasellaDiPartenzaSeNonCeNessunaLibera;
var
  LX: Integer;
  LY: Integer;
begin
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
      FRig.Rig.Grid.SetStaticEntity(LX, LY, 1, 1, 5);
  Assert.AreEqual(Point(20, 20), FRig.Rig.Grid.FindEmptyTile(20, 20));
end;

procedure TTestWarGatherSupport.DovrebbeDareIlPuntoDelRettangoloPiuVicino(APointX, APointY, AExpectedX,
  AExpectedY: Integer);
var
  LPoint: TWarVec2;
begin
  // the rectangle of the tests: (10, 10) with a size of 4 by 3, the last cell is (13, 12)
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 10, 4, 3, TWarModelMath.Vec(APointX, APointY));
  Near(AExpectedX, LPoint.X, 0.0001);
  Near(AExpectedY, LPoint.Y, 0.0001);
end;

procedure TTestWarGatherSupport.DovrebbeMisurareLaDistanzaInCaselleDalBordoDelBersaglio;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(20, 20, 100);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 17, 21);
  Assert.AreEqual(3, TWarTargetGeometry.DistanceInTiles(FRig.Rig.Entity(LWorker), FRig.Rig.Entity(LMine)));
  Assert.IsTrue(TWarTargetGeometry.UnitInRange(FRig.Rig.Entity(LWorker), FRig.Rig.Entity(LMine), 3));
  Assert.IsFalse(TWarTargetGeometry.UnitInRange(FRig.Rig.Entity(LWorker), FRig.Rig.Entity(LMine), 2));
  TWarTargetGeometry.SetCenterTile(FRig.Rig.Entity(LWorker), 19, 21);
  Assert.AreEqual(1, TWarTargetGeometry.DistanceInTiles(FRig.Rig.Entity(LWorker), FRig.Rig.Entity(LMine)));
  Near(19 * 16, FRig.Rig.Entity(LWorker)^.Position.X, 0.0001);
end;

procedure TTestWarGatherSupport.DovrebbeTrovareIlMunicipioPiuVicino;
var
  LWorker: Integer;
  LNear: Integer;
begin
  FRig.AddTownHall(40, 40);
  LNear := FRig.AddTownHall(10, 10);
  FRig.AddTownHall(30, 5);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 8, 10);
  Assert.AreEqual(LNear, TWarUnitSearch.FindClosestOfType(FRig.Rig.World.Context, LWorker, WAR_UNIT_TOWNHALL_HUMANS));
end;

procedure TTestWarGatherSupport.DovrebbeNonTrovareNulla;
var
  LWorker: Integer;
begin
  FRig.AddTownHall(40, 40);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 8, 10);
  Assert.AreEqual(0, TWarUnitSearch.FindClosestOfType(FRig.Rig.World.Context, LWorker, WAR_UNIT_TOWNHALL_ORCS));
end;

procedure TTestWarGatherSupport.DovrebbeDareIlMunicipioDellaRazza;
begin
  Assert.AreEqual(WAR_UNIT_TOWNHALL_HUMANS, TWarUnitSearch.TownHallOfRace(wraHumans));
  Assert.AreEqual(WAR_UNIT_TOWNHALL_ORCS, TWarUnitSearch.TownHallOfRace(wraOrcs));
  Assert.AreEqual(WAR_UNIT_TOWNHALL_HUMANS, TWarUnitSearch.TownHallOfRace(wraNeutral));
end;

procedure TTestWarGatherSupport.DovrebbeLasciareCheLaMinieraPartaUnaSolaVoltaPerEsaurimento;
var
  LMine: Integer;
begin
  LMine := FRig.AddMine(20, 20, 150);
  Assert.AreEqual(100, TWarMine.Take(FRig.Rig.World.Machine, LMine, 100));
  Assert.AreEqual(0, FRig.Rig.Observer.Collapsing);
  Assert.AreEqual(50, TWarMine.Take(FRig.Rig.World.Machine, LMine, 100));
  Assert.AreEqual(1, FRig.Rig.Observer.Collapsing);
  Assert.IsTrue(FRig.Rig.World.Machine.IsGoingToCollapse(LMine));
  Assert.AreEqual(0, TWarMine.Take(FRig.Rig.World.Machine, LMine, 100));
  Assert.AreEqual(1, FRig.Rig.Observer.Collapsing);
end;

procedure TTestWarGatherSupport.DovrebbeNonDareMenoDiZeroDallaMiniera;
var
  LMine: Integer;
begin
  LMine := FRig.AddMine(20, 20, 0);
  Assert.AreEqual(0, TWarMine.Take(FRig.Rig.World.Machine, LMine, 100));
  Assert.AreEqual(0, FRig.Rig.Entity(LMine)^.UnitData.Amount);
end;

procedure TTestWarGatherSupport.DovrebbeEseguireIPassiDellaRaccoltaEImpostareLUltimoPasso;
var
  LWorker: Integer;
  LUnit: PWarUnitComponent;
  LHit: Boolean;
  LSound: Boolean;
  LTic: Integer;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LUnit := @FRig.Rig.Entity(LWorker)^.UnitData;
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_HARVEST, True, 1.0);
  LUnit^.Direction := WAR_DIRECTION_EAST;
  LHit := False;
  LSound := False;
  for LTic := 1 to 60 do
  begin
    FRig.Rig.TickAll;
    if LUnit^.Actions[WAR_ACTION_HARVEST].LastActionStep = WAR_ACTION_STEP_ATTACK then
      LHit := True;
    if LUnit^.Actions[WAR_ACTION_HARVEST].LastSoundStep = WAR_ACTION_STEP_SOUND_CHOPPING then
      LSound := True;
  end;
  Assert.IsTrue(LHit, 'il passo del colpo');
  Assert.IsTrue(LSound, 'il passo del suono');
  Assert.AreEqual(WAR_ACTION_RUNNING, LUnit^.Actions[WAR_ACTION_HARVEST].Status);
  // directional: the frame is the one of the step plus 4 - |4 - direction|
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.SpriteFrame >= 0);
end;

procedure TTestWarGatherSupport.DovrebbeSpecchiareLUnitaCheGuardaVersoOvest;
var
  LWorker: Integer;
  LUnit: PWarUnitComponent;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LUnit := @FRig.Rig.Entity(LWorker)^.UnitData;
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_HARVEST, True, 1.0);
  LUnit^.Direction := WAR_DIRECTION_WEST;
  FRig.Rig.TickAll(2);
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.ScaleX < 0);
  LUnit^.Direction := WAR_DIRECTION_EAST;
  FRig.Rig.RunAll(1);
  Assert.IsFalse(FRig.Rig.Entity(LWorker)^.ScaleX < 0);
end;

procedure TTestWarGatherSupport.DovrebbeLasciareStareLeAzioniSenzaPassi;
var
  LWorker: Integer;
  LUnit: PWarUnitComponent;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LUnit := @FRig.Rig.Entity(LWorker)^.UnitData;
  LUnit^.ActionType := WAR_ACTION_NONE;
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_ACTION_NONE, LUnit^.ActionType);
  // the one runner of the actions runs every action that has steps, not only the harvest one
  LUnit^.ActionType := WAR_ACTION_IDLE;
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_ACTION_RUNNING, LUnit^.Actions[WAR_ACTION_IDLE].Status);
  // an action that the unit type does not have is finished and the unit has none (the original warns)
  LWorker := FRig.Rig.AddDude(WAR_UNIT_FOOTMAN, 12, 12);
  LUnit := @FRig.Rig.Entity(LWorker)^.UnitData;
  LUnit^.ActionType := WAR_ACTION_HARVEST;
  FRig.Rig.TickAll(2);
  Assert.AreEqual(WAR_ACTION_NONE, LUnit^.ActionType);
  Assert.AreEqual(WAR_ACTION_FINISHED, LUnit^.Actions[WAR_ACTION_HARVEST].Status);
end;

procedure TTestWarGatherSupport.DovrebbeRipartireDaCapoUnAzione;
var
  LUnit: TWarUnitComponent;
begin
  LUnit := Default(TWarUnitComponent);
  LUnit.Actions[WAR_ACTION_HARVEST].StepIndex := 9;
  LUnit.Actions[WAR_ACTION_HARVEST].Status := WAR_ACTION_RUNNING;
  LUnit.Actions[WAR_ACTION_HARVEST].WaitEndGameTime := 12.5;
  TWarActionRunner.Reset(LUnit, WAR_ACTION_HARVEST);
  Assert.AreEqual(0, LUnit.Actions[WAR_ACTION_HARVEST].StepIndex);
  Assert.AreEqual(WAR_ACTION_NOT_STARTED, LUnit.Actions[WAR_ACTION_HARVEST].Status);
  Near(0, LUnit.Actions[WAR_ACTION_HARVEST].WaitEndGameTime, 0.0001);
  // an action that does not exist changes nothing
  TWarActionRunner.Reset(LUnit, WAR_ACTION_NONE);
end;

procedure TTestWarGatherSupport.DovrebbeDareNilSeLoStorageDegliStatiEPieno;
var
  LWorker: Integer;
  LIndex: Integer;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  for LIndex := 1 to WAR_MODEL_MAX_STATES_PER_TYPE do
    TWarGatherStateFactory.NewGold(FRig.Rig.World.Machine, LWorker, 1);
  Assert.IsNull(TWarGatherStateFactory.NewGold(FRig.Rig.World.Machine, LWorker, 1));
  Assert.IsTrue(Assigned(FRig.Rig.World.Machine.CreateFollow(LWorker, 1, TWarModelMath.Vec(0, 0), 16)));
end;

procedure TTestWarGatherSupport.DovrebbeUsareEventiMutiSeNessunoAscolta;
var
  LWorld: TWarGatherWorld;
begin
  LWorld := TWarGatherWorld.Create(FRig.Rig.Grid, FRig.Forests);
  try
    Assert.IsNotNull(LWorld.Events);
    LWorld.Events.TreeChopped(TWarModelMath.Vec(1, 1));
    Assert.AreSame(FRig.Rig.Grid, LWorld.Grid);
    Assert.AreSame(FRig.Forests, LWorld.Forests);
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarGatherSupport.DovrebbeUsareLImmagineDelFanteSeIlTipoNonEInTabella;
begin
  Assert.AreEqual(279, TWarUnitSprites.DefaultResource(9999));
  Assert.AreEqual(281, TWarUnitSprites.DefaultResource(WAR_UNIT_PEASANT));
end;

end.
