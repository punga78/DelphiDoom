{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - gold, lumber, food and upgrades      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelEconomy;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ModelRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarEconomy = class(TObject)
  private
    FRig: TModelRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDireSeBastanoOroELegna;
    [Test]
    procedure DovrebbeSpendereTuttoONiente;
    [Test]
    procedure DovrebbeDireDiCheCosaMancaPrimaLOroPoiLaLegna;
    [Test]
    procedure DovrebbeAggiungereRisorse;
    [Test]
    procedure DovrebbeDareUnCiboDiUnoSenzaFattorie;
    [Test]
    procedure DovrebbeDareQuattroDiCiboPerFattoriaFinita;
    [Test]
    procedure DovrebbeNonContareLeFattorieInCostruzioneNeGliEvocati;
    [Test]
    procedure DovrebbeSegnalareLaMancanzaDiCibo;
    [Test]
    procedure DovrebbeCercareLaFattoriaDellaRazzaDelGiocatore;
    [Test]
    procedure DovrebbeDareDueDiDannoAgliArcieriConLeFrecce;
    [Test]
    procedure DovrebbeDareUnoEPoiDueAlleSpadePerLivello;
    [Test]
    procedure DovrebbeDareArmaturaConLoScudo;
    [Test]
    procedure DovrebbeAumentareLaVelocitaDelleUnitaConICavalli;
    [Test]
    procedure DovrebbeCambiareSoloLeUnitaDelGiocatore;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIlMiglioramentoEAlMassimo;
    [Test]
    procedure DovrebbeLasciareTuttoPerUnMiglioramentoSenzaEffetto;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types;

{ TTestWarEconomy }

procedure TTestWarEconomy.Setup;
begin
  FRig := TModelRig.Create;
end;

procedure TTestWarEconomy.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarEconomy.DovrebbeDireSeBastanoOroELegna;
begin
  Assert.IsTrue(FRig.World.Economy.EnoughResources(FRig.World.Context.Players[0], 1000, 1000));
  Assert.IsFalse(FRig.World.Economy.EnoughResources(FRig.World.Context.Players[0], 1001, 0));
  Assert.IsFalse(FRig.World.Economy.EnoughResources(FRig.World.Context.Players[0], 0, 1001));
end;

procedure TTestWarEconomy.DovrebbeSpendereTuttoONiente;
begin
  Assert.IsTrue(FRig.World.Economy.DecreaseResources(FRig.World.Context.Players[0], 300, 400));
  Assert.AreEqual<Integer>(700, FRig.World.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(600, FRig.World.Context.Players[0]^.Wood);
  Assert.IsFalse(FRig.World.Economy.DecreaseResources(FRig.World.Context.Players[0], 100, 601));
  Assert.AreEqual<Integer>(700, FRig.World.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(600, FRig.World.Context.Players[0]^.Wood);
end;

procedure TTestWarEconomy.DovrebbeDireDiCheCosaMancaPrimaLOroPoiLaLegna;
begin
  FRig.World.Economy.DecreaseResources(FRig.World.Context.Players[0], 1001, 1001);
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughGold), Ord(FRig.Observer.LastMessage));
  FRig.World.Economy.DecreaseResources(FRig.World.Context.Players[0], 0, 1001);
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughLumber), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Cardinal>(2, FRig.Observer.FlashCount);
end;

procedure TTestWarEconomy.DovrebbeAggiungereRisorse;
begin
  FRig.World.Economy.IncreaseResources(FRig.World.Context.Players[1], 50, 70);
  Assert.AreEqual<Integer>(1050, FRig.World.Context.Players[1]^.Gold);
  Assert.AreEqual<Integer>(1070, FRig.World.Context.Players[1]^.Wood);
end;

procedure TTestWarEconomy.DovrebbeDareUnCiboDiUnoSenzaFattorie;
begin
  Assert.IsTrue(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[0]));
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  Assert.IsFalse(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[0]));
end;

procedure TTestWarEconomy.DovrebbeDareQuattroDiCiboPerFattoriaFinita;
var
  LIndex: Integer;
begin
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 30, 30);
  for LIndex := 1 to 4 do
    FRig.AddDude(WAR_UNIT_FOOTMAN, 10 + LIndex, 10);
  Assert.IsTrue(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[0]));
  FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 10);
  Assert.IsFalse(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[0]));
end;

procedure TTestWarEconomy.DovrebbeNonContareLeFattorieInCostruzioneNeGliEvocati;
var
  LIndex: Integer;
begin
  FRig.World.Entities.CreateBuilding(WAR_UNIT_FARM_HUMANS, 30, 30, 0, True);
  FRig.Tick;
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  Assert.IsFalse(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[0]));
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 34, 30);
  for LIndex := 1 to 3 do
    FRig.AddDude(WAR_UNIT_SPIDER, 40 + LIndex, 10);
  FRig.AddDude(WAR_UNIT_SKELETON, 44, 10);
  Assert.IsTrue(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[0]));
end;

procedure TTestWarEconomy.DovrebbeSegnalareLaMancanzaDiCibo;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  Assert.IsFalse(FRig.World.Economy.CheckFarmFood(FRig.World.Context.Players[0]));
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughFood), Ord(FRig.Observer.LastMessage));
  Assert.IsTrue(FRig.World.Economy.CheckFarmFood(FRig.World.Context.Players[1]));
  Assert.AreEqual<Cardinal>(1, FRig.Observer.FlashCount);
end;

procedure TTestWarEconomy.DovrebbeCercareLaFattoriaDellaRazzaDelGiocatore;
begin
  // the player 1 is orc: its farm is the orc one
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 30, 30, 1);
  FRig.AddDude(WAR_UNIT_GRUNT, 10, 10, 1);
  Assert.IsFalse(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[1]));
  FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 34, 30, 1);
  Assert.IsTrue(FRig.World.Economy.EnoughFarmFood(FRig.World.Context.Players[1]));
end;

procedure TTestWarEconomy.DovrebbeDareDueDiDannoAgliArcieriConLeFrecce;
var
  LArcher: Integer;
  LFootman: Integer;
begin
  LArcher := FRig.AddDude(WAR_UNIT_ARCHER, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 10);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_ARROWS);
  Assert.AreEqual<Integer>(6, FRig.Entity(LArcher)^.UnitData.MinDamage);
  Assert.AreEqual<Integer>(1, FRig.Entity(LFootman)^.UnitData.MinDamage);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Players[0]^.Upgrades[0].Level);
end;

procedure TTestWarEconomy.DovrebbeDareUnoEPoiDueAlleSpadePerLivello;
var
  LFootman: Integer;
  LKnight: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LKnight := FRig.AddDude(WAR_UNIT_KNIGHT, 12, 10);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_SWORDS);
  Assert.AreEqual<Integer>(2, FRig.Entity(LFootman)^.UnitData.MinDamage);
  Assert.AreEqual<Integer>(10, FRig.Entity(LFootman)^.UnitData.RndDamage);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_SWORDS);
  Assert.AreEqual<Integer>(4, FRig.Entity(LFootman)^.UnitData.MinDamage);
  Assert.AreEqual<Integer>(12, FRig.Entity(LFootman)^.UnitData.RndDamage);
  Assert.AreEqual<Integer>(4, FRig.Entity(LKnight)^.UnitData.MinDamage);
end;

procedure TTestWarEconomy.DovrebbeDareArmaturaConLoScudo;
var
  LFootman: Integer;
begin
  FRig.World.Context.Players[0]^.Upgrades[WAR_UPGRADE_SHIELD div 2].Allowed := 2;
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_SHIELD);
  Assert.AreEqual<Integer>(3, FRig.Entity(LFootman)^.UnitData.Armor);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_SHIELD);
  Assert.AreEqual<Integer>(5, FRig.Entity(LFootman)^.UnitData.Armor);
end;

procedure TTestWarEconomy.DovrebbeAumentareLaVelocitaDelleUnitaConICavalli;
var
  LDude: Integer;
  LFarm: Integer;
begin
  LDude := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 30, 30);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_HORSES);
  Assert.AreEqual<Integer>(1, FRig.Entity(LDude)^.UnitData.Speed);
  Assert.AreEqual<Integer>(0, FRig.Entity(LFarm)^.UnitData.Speed);
end;

procedure TTestWarEconomy.DovrebbeCambiareSoloLeUnitaDelGiocatore;
var
  LMine: Integer;
  LTheirs: Integer;
begin
  LMine := FRig.AddDude(WAR_UNIT_ARCHER, 10, 10, 0);
  LTheirs := FRig.AddDude(WAR_UNIT_SPEARMAN, 12, 10, 1);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_SPEARS);
  Assert.AreEqual<Integer>(6, FRig.Entity(LMine)^.UnitData.MinDamage);
  Assert.AreEqual<Integer>(5, FRig.Entity(LTheirs)^.UnitData.MinDamage);
end;

procedure TTestWarEconomy.DovrebbeSollevareEccezioneSeIlMiglioramentoEAlMassimo;
begin
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_ARROWS);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_ARROWS);
  Assert.WillRaise(
    procedure
    begin
      FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_ARROWS);
    end, EWarException);
  Assert.AreEqual<Integer>(2, FRig.World.Context.Players[0]^.Upgrades[0].Level);
end;

procedure TTestWarEconomy.DovrebbeLasciareTuttoPerUnMiglioramentoSenzaEffetto;
var
  LDude: Integer;
begin
  FRig.World.Context.Players[0]^.Upgrades[WAR_UPGRADE_POISON_CLOUD div 2].Allowed := 1;
  LDude := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_POISON_CLOUD);
  Assert.AreEqual<Integer>(60, FRig.Entity(LDude)^.UnitData.Hp);
  Assert.AreEqual<Integer>(2, FRig.Entity(LDude)^.UnitData.Armor);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Players[0]^.Upgrades[WAR_UPGRADE_POISON_CLOUD div 2].Level);
end;

end.
