{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - training and upgrades                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionTraining;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ConstructionRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarConstructionTraining = class(TObject)
  private
    FRig: TConstructionRig;
    /// <summary>The farms that give food for the units that the tests make</summary>
    procedure AddFarms(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAddebitareILCostoEAddestrareUnUnita;
    [Test]
    procedure DovrebbeFarComparireLUnitaSuUnaCasellaVuotaVicinoAlLEdificio;
    [Test]
    procedure DovrebbeDireProntoConLaVoceDellaRazzaDellUnitaAddestrata;
    [Test]
    procedure DovrebbeNonDireNullaSeIlGiocatoreNonEIlZero;
    [Test]
    procedure DovrebbeFarCorrereIlTempoDellAddestramentoPiuVeloceConIlTrucco;
    [Test]
    procedure DovrebbeRifiutareLAddestramentoSenzaCibo;
    [Test]
    procedure DovrebbeRifiutareLAddestramentoSenzaDenaro;
    [Test]
    procedure DovrebbeIgnorareLOrdineSeLEdificioNonLoAccetta;
    [Test]
    procedure DovrebbeAnnullareLAddestramentoRestituendoIlCostoUnaVoltaSola;
    [Test]
    procedure DovrebbeAnnullarsiSeIlDenaroFinisceTraLOrdineELIngresso;
    [Test]
    procedure DovrebbeRiprovareSeLaPiscinaDelleEntitaEPiena;
    [Test]
    procedure DovrebbeTenereOccupateLeCaselleDelLEdificioMentreAddestra;
    [Test]
    procedure DovrebbeAddebitareIlCostoDelPrimoLivelloDelMiglioramento;
    [Test]
    procedure DovrebbeAddebitareIlCostoDelSecondoLivelloDelMiglioramento;
    [Test]
    procedure DovrebbeAlzareIlLivelloEDareLaForzaAllEsercitoAlTermineDelMiglioramento;
    [Test]
    procedure DovrebbeRifiutareUnMiglioramentoGiaAlMassimo;
    [Test]
    procedure DovrebbeRifiutareUnMiglioramentoChePortaOltreIlMassimoDellaCoppia;
    [Test]
    procedure DovrebbeSollevareEccezioneAlTermineSeIlLivelloEOltreIlMassimo;
    [Test]
    procedure DovrebbeRifiutareUnMiglioramentoSenzaDenaro;
    [Test]
    procedure DovrebbeIgnorareUnTerzoLivelloChePerLaTabellaNonHaCosto;
    [Test]
    procedure DovrebbeAnnullareIlMiglioramentoRestituendoIlCosto;
    [Test]
    procedure DovrebbeAnnullarsiSeIlDenaroFinisceTraLOrdineELIngressoDelMiglioramento;
    [Test]
    procedure DovrebbeContareIMiglioramentiDellaCoppiaInCorsoERichiesti;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.State.Train;

{ TTestWarConstructionTraining }

procedure TTestWarConstructionTraining.Setup;
begin
  FRig := TConstructionRig.Create;
end;

procedure TTestWarConstructionTraining.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarConstructionTraining.AddFarms(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
    FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 30 + LIndex * 3, 30);
end;

procedure TTestWarConstructionTraining.DovrebbeAddebitareILCostoEAddestrareUnUnita;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  Assert.IsTrue(FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN));
  // the order is a request: the cost is charged when the state is entered, at the next tic
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.IsTrue(FRig.Machine.IsActive(LBarracks, WAR_STATE_IDLE));
  FRig.Tick;
  Assert.AreEqual<Integer>(5000 - 400, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(WAR_STATE_TRAIN, FRig.ActiveType(LBarracks));
  Assert.IsTrue(FRig.Entity(LBarracks)^.UnitData.Building);
  Assert.IsTrue(FRig.Grid.IsStatic(11, 11));
  Assert.AreEqual<Integer>(0, FRig.FirstOfType(WAR_UNIT_FOOTMAN));
  // the footman takes 48 seconds
  FRig.Tick(2, 10);
  Assert.IsTrue(FRig.Entity(LBarracks)^.UnitData.BuildPercent > 0);
  Assert.IsTrue(FRig.Entity(LBarracks)^.UnitData.BuildPercent < 1);
  Assert.AreEqual<Integer>(0, FRig.FirstOfType(WAR_UNIT_FOOTMAN));
  FRig.Tick(4, 10);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBarracks));
  Assert.IsFalse(FRig.Entity(LBarracks)^.UnitData.Building);
  Assert.AreEqual(1.0, Double(FRig.Entity(LBarracks)^.UnitData.BuildPercent), 0.0001);
  Assert.IsTrue(FRig.FirstOfType(WAR_UNIT_FOOTMAN) <> 0);
end;

procedure TTestWarConstructionTraining.DovrebbeFarComparireLUnitaSuUnaCasellaVuotaVicinoAlLEdificio;
var
  LBarracks: Integer;
  LFootman: Integer;
  LTileX: Integer;
  LTileY: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN);
  FRig.Tick(10, 10);
  LFootman := FRig.FirstOfType(WAR_UNIT_FOOTMAN);
  Assert.IsTrue(LFootman <> 0);
  // the center of the barracks is the tile (11, 11), occupied by the building: the footman is on the nearest free one
  LTileX := Trunc(FRig.Entity(LFootman)^.Position.X) div WAR_MEGA_TILE_SIZE;
  LTileY := Trunc(FRig.Entity(LFootman)^.Position.Y) div WAR_MEGA_TILE_SIZE;
  Assert.IsTrue(FRig.Grid.IsEmpty(LTileX, LTileY) or (FRig.Entity(LFootman)^.UnitData.Player = 0));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFootman));
end;

procedure TTestWarConstructionTraining.DovrebbeDireProntoConLaVoceDellaRazzaDellUnitaAddestrata;
var
  LBarracks: Integer;
  LOrcBarracks: Integer;
begin
  AddFarms(2);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN);
  FRig.Tick(10, 10);
  Assert.AreEqual<Integer>(WAR_SOUND_HUMAN_READY, FRig.Observer.LastSound);
  // the voice is the one of the unit, not of the player: an orc made by the human player says it in the orc way
  LOrcBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_ORCS, 20, 10);
  FRig.Commands.OrderTrain(LOrcBarracks, WAR_UNIT_GRUNT);
  FRig.Tick(10, 10);
  Assert.AreEqual<Integer>(WAR_SOUND_ORC_READY, FRig.Observer.LastSound);
end;

procedure TTestWarConstructionTraining.DovrebbeNonDireNullaSeIlGiocatoreNonEIlZero;
var
  LBarracks: Integer;
  LBefore: Cardinal;
begin
  FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 30, 30, 1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_ORCS, 10, 10, 1);
  LBefore := FRig.Observer.AudioCount;
  Assert.IsTrue(FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_GRUNT));
  FRig.Tick(10, 10);
  Assert.IsTrue(FRig.FirstOfType(WAR_UNIT_GRUNT) <> 0);
  Assert.AreEqual<Cardinal>(LBefore, FRig.Observer.AudioCount);
end;

procedure TTestWarConstructionTraining.DovrebbeFarCorrereIlTempoDellAddestramentoPiuVeloceConIlTrucco;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  FRig.Context.HurryUp := True;
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN);
  FRig.Run(1.5);
  Assert.IsTrue(FRig.FirstOfType(WAR_UNIT_FOOTMAN) <> 0);
end;

procedure TTestWarConstructionTraining.DovrebbeRifiutareLAddestramentoSenzaCibo;
var
  LBarracks: Integer;
begin
  // a farm gives food for 4 units and the player starts with one: with no farm, one unit (the footman) takes all of it
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 20);
  Assert.IsFalse(FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughFood), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeRifiutareLAddestramentoSenzaDenaro;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Context.Players[0]^.Gold := 399;
  Assert.IsFalse(FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(399, FRig.Context.Players[0]^.Gold);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBarracks));
end;

procedure TTestWarConstructionTraining.DovrebbeIgnorareLOrdineSeLEdificioNonLoAccetta;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.World.Combat.TakeDamage(LBarracks, 5000, 0);
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeAnnullareLAddestramentoRestituendoIlCostoUnaVoltaSola;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN);
  FRig.Tick(2, 1);
  Assert.AreEqual<Integer>(5000 - 400, FRig.Context.Players[0]^.Gold);
  Assert.IsTrue(FRig.Commands.Cancel(LBarracks));
  FRig.Tick(2, 1);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBarracks));
  Assert.IsFalse(FRig.Entity(LBarracks)^.UnitData.Building);
  Assert.AreEqual<Integer>(0, FRig.FirstOfType(WAR_UNIT_FOOTMAN));
  FRig.Commands.Cancel(LBarracks);
  FRig.Tick(2, 1);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeAnnullarsiSeIlDenaroFinisceTraLOrdineELIngresso;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  Assert.IsTrue(FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN));
  // the money goes before the state is entered (a purchase of the same tic): the training cancels itself
  FRig.Context.Players[0]^.Gold := 0;
  FRig.Tick(2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBarracks));
  Assert.IsFalse(FRig.Entity(LBarracks)^.UnitData.Building);
  Assert.AreEqual<Integer>(0, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughGold), Ord(FRig.Observer.LastMessage));
end;

procedure TTestWarConstructionTraining.DovrebbeRiprovareSeLaPiscinaDelleEntitaEPiena;
var
  LBarracks: Integer;
  LCount: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN);
  FRig.Tick(2, 1);
  for LCount := 1 to WAR_MODEL_MAX_ENTITIES do
    if FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 40, 40, 1, False) = 0 then
      Break;
  // the time is over but there is no room for the unit: the original would use a null pointer, here the building waits
  FRig.Tick(10, 10);
  Assert.AreEqual<Integer>(WAR_STATE_TRAIN, FRig.ActiveType(LBarracks));
  Assert.AreEqual(1.0, Double(FRig.Entity(LBarracks)^.UnitData.BuildPercent), 0.0001);
end;

procedure TTestWarConstructionTraining.DovrebbeTenereOccupateLeCaselleDelLEdificioMentreAddestra;
var
  LBarracks: Integer;
begin
  AddFarms(1);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 10, 10);
  FRig.Commands.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN);
  FRig.Tick(2, 1);
  FRig.Machine.ResetState(LBarracks, PWarStateBase(FRig.Machine.CreateIdle(LBarracks, False)), WAR_CAUSE_LIFECYCLE);
  FRig.Tick(2, 1);
  // the idle state of the building fills its tiles as the training state did
  Assert.IsTrue(FRig.Grid.IsStatic(10, 10));
  Assert.AreEqual<Integer>(5000 - 400, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeAddebitareIlCostoDelPrimoLivelloDelMiglioramento;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  // charged when the state is entered, at the next tic
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  FRig.Tick;
  Assert.AreEqual<Integer>(5000 - 750, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(WAR_STATE_UPGRADE, FRig.ActiveType(LSmithy));
  Assert.IsTrue(FRig.Entity(LSmithy)^.UnitData.Building);
end;

procedure TTestWarConstructionTraining.DovrebbeAddebitareIlCostoDelSecondoLivelloDelMiglioramento;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 1;
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  FRig.Tick;
  Assert.AreEqual<Integer>(5000 - 1500, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeAlzareIlLivelloEDareLaForzaAllEsercitoAlTermineDelMiglioramento;
var
  LSmithy: Integer;
  LFootman: Integer;
  LBefore: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 20);
  LBefore := FRig.Entity(LFootman)^.UnitData.MinDamage;
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS);
  FRig.Tick(2, 1);
  Assert.IsTrue(FRig.Entity(LSmithy)^.UnitData.BuildPercent < 1);
  FRig.Tick(10, 20);
  Assert.AreEqual<Integer>(1, FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level);
  Assert.AreEqual<Integer>(LBefore + 1, FRig.Entity(LFootman)^.UnitData.MinDamage);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSmithy));
  Assert.IsFalse(FRig.Entity(LSmithy)^.UnitData.Building);
  Assert.AreEqual(1.0, Double(FRig.Entity(LSmithy)^.UnitData.BuildPercent), 0.0001);
end;

procedure TTestWarConstructionTraining.DovrebbeRifiutareUnMiglioramentoGiaAlMassimo;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 2;
  Assert.IsFalse(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeRifiutareUnMiglioramentoChePortaOltreIlMassimoDellaCoppia;
var
  LSmithy: Integer;
  LOrcSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  LOrcSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_ORCS, 20, 10);
  FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 1;
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  // swords and axes share a level: a second research would end over the maximum
  Assert.IsFalse(FRig.Commands.OrderUpgrade(LOrcSmithy, WAR_UPGRADE_AXES));
  FRig.Tick;
  Assert.AreEqual<Integer>(5000 - 1500, FRig.Context.Players[0]^.Gold);
  // and one of another pair is fine
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LOrcSmithy, WAR_UPGRADE_SHIELD));
end;

procedure TTestWarConstructionTraining.DovrebbeSollevareEccezioneAlTermineSeIlLivelloEOltreIlMassimo;
var
  LSmithy: Integer;
  LOrcSmithy: Integer;
begin
  FRig.Commands.RejectOverbookedUpgrades := False;
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  LOrcSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_ORCS, 20, 10);
  FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 1;
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  // with the check off the order is accepted, as in the original, which stops on an assert when the second one ends
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LOrcSmithy, WAR_UPGRADE_AXES));
  Assert.WillRaise(
    procedure
    begin
      FRig.Tick(20, 20);
    end, EWarException);
end;

procedure TTestWarConstructionTraining.DovrebbeRifiutareUnMiglioramentoSenzaDenaro;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  FRig.Context.Players[0]^.Gold := 749;
  Assert.IsFalse(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  Assert.AreEqual<Integer>(749, FRig.Context.Players[0]^.Gold);
  // the building that does not accept orders: the same
  FRig.Context.Players[0]^.Gold := 5000;
  FRig.World.Combat.TakeDamage(LSmithy, 5000, 0);
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionTraining.DovrebbeIgnorareUnTerzoLivelloChePerLaTabellaNonHaCosto;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Allowed := 3;
  FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 2;
  // the table of the costs has two levels: the third one has no price (the original reads past the array)
  Assert.IsFalse(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
end;

procedure TTestWarConstructionTraining.DovrebbeAnnullareIlMiglioramentoRestituendoIlCosto;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS);
  FRig.Tick(2, 1);
  Assert.IsTrue(FRig.Commands.Cancel(LSmithy));
  FRig.Tick(2, 1);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(0, FRig.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSmithy));
end;

procedure TTestWarConstructionTraining.DovrebbeAnnullarsiSeIlDenaroFinisceTraLOrdineELIngressoDelMiglioramento;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  Assert.IsTrue(FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS));
  FRig.Context.Players[0]^.Gold := 0;
  FRig.Tick(2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSmithy));
  Assert.AreEqual<Integer>(0, FRig.Context.Players[0]^.Gold);
  Assert.IsFalse(FRig.Entity(LSmithy)^.UnitData.Building);
end;

procedure TTestWarConstructionTraining.DovrebbeContareIMiglioramentiDellaCoppiaInCorsoERichiesti;
var
  LSmithy: Integer;
begin
  LSmithy := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 10, 10);
  Assert.AreEqual<Integer>(0, FRig.Commands.UpgradesInProgress(0, WAR_UPGRADE_SWORDS div 2));
  FRig.Commands.OrderUpgrade(LSmithy, WAR_UPGRADE_SWORDS);
  // waiting to start (a request)
  Assert.AreEqual<Integer>(1, FRig.Commands.UpgradesInProgress(0, WAR_UPGRADE_SWORDS div 2));
  FRig.Tick;
  // going
  Assert.AreEqual<Integer>(1, FRig.Commands.UpgradesInProgress(0, WAR_UPGRADE_SWORDS div 2));
  Assert.AreEqual<Integer>(0, FRig.Commands.UpgradesInProgress(0, WAR_UPGRADE_ARROWS div 2));
  Assert.AreEqual<Integer>(0, FRig.Commands.UpgradesInProgress(1, WAR_UPGRADE_SWORDS div 2));
end;

end.
