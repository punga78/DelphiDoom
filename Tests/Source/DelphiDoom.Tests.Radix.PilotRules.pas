{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixPilotRules                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PilotRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.ActorProperties, DelphiDoom.Radix.Pilot.Rules;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPilotRules = class(TObject)
  strict private
    FLimits: TRadixPilotLimits;
    FInventory: TRadixInventory;
    FInfo: TRadixActorInfo;
    function Take(ADoomedNum: Integer = 0; AEpisode: Integer = 1; ADouble: Boolean = False): TRadixPickupResult;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLasciareUnOggettoCheNonServe;
    [Test]
    procedure DovrebbeRiportareScudoCorazzaEdEnergiaAlValoreDato;
    [Test]
    procedure DovrebbeNonSuperareIMassimi;
    [Test]
    procedure DovrebbeDareLeMunizioniFinoAlMassimo;
    [Test]
    procedure DovrebbeRaddoppiareLeMunizioniAlLivelloPiuDifficile;
    [Test]
    procedure DovrebbeNonDareSiluriENucleariNelPrimoEpisodio;
    [Test]
    procedure DovrebbeDareUnArmaNuovaEPrepararla;
    [Test]
    procedure DovrebbeNonRiprendereUnArmaCheHaGia;
    [Test]
    procedure DovrebbeFarDiventarePotenziatoUnEpcTrovatoDueVolte;
    [Test]
    procedure DovrebbeDareIlSuperEpcSoloDopoIlPrimoEpisodio;
    [Test]
    procedure DovrebbeAllungareUnPotenziamentoSoloSeDuraDiPiu;
    [Test]
    procedure DovrebbeDareLeBombeAlPlasmaFinoAlMassimo;
    [Test]
    procedure DovrebbeAlzareIlLivelloDeiCannoniAiNeutroni;
    [Test]
    procedure DovrebbeAlzareIlLivelloDelloSpargitoreSoloSeLoAvevaGia;
    [Test]
    procedure DovrebbeRigenerareOgniTrentadueTic;
    [Test]
    procedure DovrebbeNonRigenerareMentreSubisceDanni;
    [Test]
    procedure DovrebbeRigenerareIlDoppioConIPotenziamentiRapidi;
    [Test]
    procedure DovrebbeNonRigenerareOltreIValoriDiPartenza;
    [Test]
    procedure DovrebbeRiempireLaRiservaMentreSparaConLEnergiaRapida;
    [Test]
    procedure DovrebbeConsumareIPotenziamentiNelTempo;
    [Test]
    procedure DovrebbeSegnalareLaMinacciaSottoUnQuartoDiScudo;
  end;

implementation

{ TTestRadixPilotRules }

procedure TTestRadixPilotRules.Setup;
begin
  FLimits := TRadixPilotLimits.Default;
  FInventory := Default(TRadixInventory);
  FInventory.Shield := 100;
  FInventory.Armor := 100;
  FInventory.Energy := 100;
  FInventory.MaxAmmo[0] := 5000;
  FInventory.MaxAmmo[1] := 400;
  FInventory.MaxAmmo[2] := 1500;
  FInventory.MaxAmmo[3] := 50;
  FInventory.WeaponOwned[0] := True;
  FInventory.PendingWeapon := -1;
  FInfo := TRadixActorInfo.Empty;
end;

function TTestRadixPilotRules.Take(ADoomedNum, AEpisode: Integer; ADouble: Boolean): TRadixPickupResult;
begin
  Result := TRadixPilotRules.Pickup(FInfo, ADoomedNum, AEpisode, ADouble, FLimits, FInventory);
end;

procedure TTestRadixPilotRules.DovrebbeLasciareUnOggettoCheNonServe;
begin
  FInfo.ShieldSet := 100;
  FInfo.EnergySet := 100;
  FInfo.ArmorSet := 100;
  Assert.IsFalse(Take.Taken, 'la navetta e'' gia'' piena');
  Assert.AreEqual(100, FInventory.Shield);
end;

procedure TTestRadixPilotRules.DovrebbeRiportareScudoCorazzaEdEnergiaAlValoreDato;
begin
  FInventory.Shield := 40;
  FInventory.Armor := 60;
  FInventory.Energy := 5;
  FInfo.ShieldSet := 100;
  FInfo.EnergySet := 100;
  FInfo.ArmorSet := 100;
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(100, FInventory.Shield);
  Assert.AreEqual(100, FInventory.Armor, 'il vecchio codice dava 4000');
  Assert.AreEqual(100, FInventory.Energy);
end;

procedure TTestRadixPilotRules.DovrebbeNonSuperareIMassimi;
begin
  FInventory.Shield := 95;
  FInventory.Energy := 95;
  FInventory.Armor := 190;
  FInfo.ShieldInc := 50;
  FInfo.EnergyInc := 50;
  FInfo.ArmorInc := 50;
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(100, FInventory.Shield);
  Assert.AreEqual(100, FInventory.Energy);
  Assert.AreEqual(200, FInventory.Armor);
  Assert.IsFalse(Take.Taken, 'la seconda volta non serve piu''');
end;

procedure TTestRadixPilotRules.DovrebbeDareLeMunizioniFinoAlMassimo;
begin
  FInventory.Ammo[0] := 4900;
  FInfo.AmmoInc[0] := 250;
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(5000, FInventory.Ammo[0]);
  Assert.IsFalse(Take.Taken);
end;

procedure TTestRadixPilotRules.DovrebbeRaddoppiareLeMunizioniAlLivelloPiuDifficile;
begin
  FInfo.AmmoInc[1] := 20;
  Assert.IsTrue(Take(0, 1, True).Taken);
  Assert.AreEqual(40, FInventory.Ammo[1]);
end;

procedure TTestRadixPilotRules.DovrebbeNonDareSiluriENucleariNelPrimoEpisodio;
begin
  FInfo.AmmoInc[TRadixPilotRules.AMMO_TORPEDOES] := 15;
  FInfo.AmmoInc[TRadixPilotRules.AMMO_NUKES] := 4;
  Assert.IsFalse(Take(0, 1).Taken);
  Assert.AreEqual(0, FInventory.Ammo[2]);
  Assert.IsTrue(Take(0, 2).Taken);
  Assert.AreEqual(15, FInventory.Ammo[2]);
  Assert.AreEqual(4, FInventory.Ammo[3]);
end;

procedure TTestRadixPilotRules.DovrebbeDareUnArmaNuovaEPrepararla;
var
  LResult: TRadixPickupResult;
begin
  FInfo.WeaponInc[3] := True;
  LResult := Take;
  Assert.IsTrue(LResult.Taken);
  Assert.IsTrue(LResult.Message = TRadixPickupMessage.Pickup);
  Assert.IsTrue(FInventory.WeaponOwned[3]);
  Assert.AreEqual(3, FInventory.PendingWeapon);
end;

procedure TTestRadixPilotRules.DovrebbeNonRiprendereUnArmaCheHaGia;
begin
  FInventory.WeaponOwned[3] := True;
  FInfo.WeaponInc[3] := True;
  Assert.IsFalse(Take.Taken);
  Assert.AreEqual(-1, FInventory.PendingWeapon);
  // with ammo that fits it is taken for the ammo
  FInfo.AmmoInc[1] := 20;
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(-1, FInventory.PendingWeapon);
end;

procedure TTestRadixPilotRules.DovrebbeFarDiventarePotenziatoUnEpcTrovatoDueVolte;
var
  LResult: TRadixPickupResult;
begin
  FInfo.WeaponInc[TRadixPilotRules.WEAPON_STANDARD_EPC] := True;
  Assert.IsTrue(Take.Message = TRadixPickupMessage.Pickup);
  Assert.IsTrue(FInventory.WeaponOwned[TRadixPilotRules.WEAPON_STANDARD_EPC]);
  LResult := Take;
  Assert.IsTrue(LResult.Taken);
  Assert.IsTrue(LResult.Message = TRadixPickupMessage.EnhancedEpc);
  Assert.IsTrue(FInventory.WeaponOwned[TRadixPilotRules.WEAPON_ENHANCED_EPC]);
  Assert.AreEqual(TRadixPilotRules.WEAPON_ENHANCED_EPC, FInventory.PendingWeapon);
end;

procedure TTestRadixPilotRules.DovrebbeDareIlSuperEpcSoloDopoIlPrimoEpisodio;
var
  LResult: TRadixPickupResult;
begin
  FInventory.WeaponOwned[TRadixPilotRules.WEAPON_STANDARD_EPC] := True;
  FInventory.WeaponOwned[TRadixPilotRules.WEAPON_ENHANCED_EPC] := True;
  FInfo.WeaponInc[TRadixPilotRules.WEAPON_STANDARD_EPC] := True;
  Assert.IsFalse(Take(0, 1).Taken, 'nel primo episodio ci si ferma al potenziato');
  LResult := Take(0, 2);
  Assert.IsTrue(LResult.Taken);
  Assert.IsTrue(LResult.Message = TRadixPickupMessage.SuperEpc);
  Assert.IsTrue(FInventory.WeaponOwned[TRadixPilotRules.WEAPON_SUPER_EPC]);
end;

procedure TTestRadixPilotRules.DovrebbeAllungareUnPotenziamentoSoloSeDuraDiPiu;
begin
  FInfo.ManeuverJets := 3500;
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(3500, FInventory.Powers[TRadixPowerUp.ManeuverJets]);
  FInventory.Powers[TRadixPowerUp.ManeuverJets] := 3500;
  Assert.IsFalse(Take.Taken);
  FInventory.Powers[TRadixPowerUp.ManeuverJets] := 10;
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(3500, FInventory.Powers[TRadixPowerUp.ManeuverJets]);
end;

procedure TTestRadixPilotRules.DovrebbeDareLeBombeAlPlasmaFinoAlMassimo;
begin
  FLimits.MaxPlasmaBombs := 3;
  FInfo.PlasmaBomb := 2;
  Assert.IsTrue(Take.Taken);
  Assert.IsTrue(Take.Taken);
  Assert.AreEqual(3, FInventory.PlasmaBombs);
  Assert.IsFalse(Take.Taken);
end;

procedure TTestRadixPilotRules.DovrebbeAlzareIlLivelloDeiCannoniAiNeutroni;
var
  LResult: TRadixPickupResult;
  LIndex: Integer;
begin
  LResult := Take(TRadixPilotRules.DOOMEDNUM_NEUTRON_CANNONS);
  Assert.IsTrue(LResult.Taken);
  Assert.IsTrue(LResult.Message = TRadixPickupMessage.NeutronCannons);
  Assert.AreEqual(1, FInventory.NeutronCannonLevel);
  for LIndex := 1 to 10 do
    Take(TRadixPilotRules.DOOMEDNUM_NEUTRON_CANNONS);
  Assert.AreEqual(TRadixPilotRules.MAX_NEUTRON_LEVEL, FInventory.NeutronCannonLevel);
  Assert.IsFalse(Take(TRadixPilotRules.DOOMEDNUM_NEUTRON_CANNONS).Taken);
end;

procedure TTestRadixPilotRules.DovrebbeAlzareIlLivelloDelloSpargitoreSoloSeLoAvevaGia;
var
  LResult: TRadixPickupResult;
begin
  FInfo.WeaponInc[TRadixPilotRules.WEAPON_PLASMA_SPREADER] := True;
  LResult := Take(TRadixPilotRules.DOOMEDNUM_PLASMA_SPREADER);
  Assert.IsTrue(LResult.Taken);
  Assert.IsTrue(LResult.Message = TRadixPickupMessage.Pickup, 'la prima volta e'' solo l''arma');
  Assert.AreEqual(0, FInventory.NeutronSpreaderLevel);
  LResult := Take(TRadixPilotRules.DOOMEDNUM_PLASMA_SPREADER);
  Assert.IsTrue(LResult.Taken);
  Assert.IsTrue(LResult.Message = TRadixPickupMessage.NeutronSpreader);
  Assert.AreEqual(1, FInventory.NeutronSpreaderLevel);
end;

procedure TTestRadixPilotRules.DovrebbeRigenerareOgniTrentadueTic;
begin
  FInventory.Shield := 50;
  FInventory.Energy := 50;
  TRadixPilotRules.Regenerate(31, False, False, FLimits, FInventory);
  Assert.AreEqual(50, FInventory.Shield);
  TRadixPilotRules.Regenerate(32, False, False, FLimits, FInventory);
  Assert.AreEqual(51, FInventory.Shield);
  Assert.AreEqual(51, FInventory.Energy);
end;

procedure TTestRadixPilotRules.DovrebbeNonRigenerareMentreSubisceDanni;
begin
  FInventory.Shield := 50;
  FInventory.Energy := 50;
  TRadixPilotRules.Regenerate(64, True, False, FLimits, FInventory);
  Assert.AreEqual(50, FInventory.Shield);
  Assert.AreEqual(50, FInventory.Energy);
end;

procedure TTestRadixPilotRules.DovrebbeRigenerareIlDoppioConIPotenziamentiRapidi;
begin
  FInventory.Shield := 50;
  FInventory.Energy := 50;
  FInventory.Powers[TRadixPowerUp.RapidShield] := 10;
  FInventory.Powers[TRadixPowerUp.RapidEnergy] := 10;
  TRadixPilotRules.Regenerate(64, False, False, FLimits, FInventory);
  Assert.AreEqual(52, FInventory.Shield);
  Assert.AreEqual(52, FInventory.Energy);
end;

procedure TTestRadixPilotRules.DovrebbeNonRigenerareOltreIValoriDiPartenza;
begin
  FInventory.Shield := 100;
  FInventory.Energy := 99;
  FInventory.Powers[TRadixPowerUp.RapidEnergy] := 10;
  TRadixPilotRules.Regenerate(64, False, False, FLimits, FInventory);
  Assert.AreEqual(100, FInventory.Shield);
  Assert.AreEqual(99, FInventory.Energy, '99 + 2 passa il massimo: come il vecchio, non cambia');
  // the ultra shields (over 100) are not taken away
  FInventory.Shield := 150;
  TRadixPilotRules.Regenerate(96, False, False, FLimits, FInventory);
  Assert.AreEqual(150, FInventory.Shield);
end;

procedure TTestRadixPilotRules.DovrebbeRiempireLaRiservaMentreSparaConLEnergiaRapida;
var
  LTic: Integer;
begin
  FInventory.Energy := 50;
  TRadixPilotRules.Regenerate(32, False, True, FLimits, FInventory);
  Assert.AreEqual(50, FInventory.Energy, 'senza energia rapida niente');
  Assert.AreEqual(0, FInventory.EnergyReserve);
  FInventory.Powers[TRadixPowerUp.RapidEnergy] := 1000;
  for LTic := 1 to 10 do
    TRadixPilotRules.Regenerate(32 * LTic, False, True, FLimits, FInventory);
  Assert.AreEqual(50, FInventory.Energy);
  Assert.AreEqual(FLimits.ReserveEnergy, FInventory.EnergyReserve);
end;

procedure TTestRadixPilotRules.DovrebbeConsumareIPotenziamentiNelTempo;
begin
  FInventory.Powers[TRadixPowerUp.Alds] := 2;
  TRadixPilotRules.TickPowers(FInventory);
  TRadixPilotRules.TickPowers(FInventory);
  TRadixPilotRules.TickPowers(FInventory);
  Assert.AreEqual(0, FInventory.Powers[TRadixPowerUp.Alds]);
  Assert.AreEqual(0, FInventory.Powers[TRadixPowerUp.NightVision]);
end;

procedure TTestRadixPilotRules.DovrebbeSegnalareLaMinacciaSottoUnQuartoDiScudo;
begin
  Assert.IsTrue(TRadixPilotRules.Threat(24, FLimits));
  Assert.IsFalse(TRadixPilotRules.Threat(25, FLimits));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPilotRules);

end.
