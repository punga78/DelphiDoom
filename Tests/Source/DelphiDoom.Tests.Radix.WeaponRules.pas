{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixWeaponRules                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.WeaponRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Weapon.Rules;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixWeaponRules = class(TObject)
  strict private
    const
      F = TRadixWeaponRules.FRACUNIT;
      SIDE = TRadixWeaponRules.WEAPON_SIDE_OFFSET;
    var
      FEnergy: TRadixWeaponEnergy;
      FOwned: array[0..TRadixWeaponRules.WEAPONS - 1] of Boolean;
      FAmmo: array[0..TRadixWeaponRules.AMMO_TYPES - 1] of Integer;
    procedure CheckShot(const AShot: TRadixShot; AKind: TRadixShotKind; AOffset, AZ: Integer;
      const AMessage: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    [TestCase('cannoni', '0,5,3')]
    [TestCase('epc', '1,2,2')]
    [TestCase('spargitore', '2,5,3')]
    [TestCase('missili', '3,20,18')]
    [TestCase('nucleare', '4,18,16')]
    [TestCase('siluri', '5,20,0')]
    [TestCase('onda', '6,35,30')]
    [TestCase('epc potenziato', '7,2,2')]
    [TestCase('super epc', '8,3,3')]
    procedure DovrebbeDareITicTraDueColpi(AWeapon, ANormal, AFast: Integer);
    [Test]
    procedure DovrebbeDareZeroTicPerUnArmaCheNonEsiste;
    [Test]
    procedure DovrebbeNonRisparareFinoAlTempoDellArma;
    [Test]
    [TestCase('0', '0,0')]
    [TestCase('1', '1,1')]
    [TestCase('2', '2,1')]
    [TestCase('3', '3,2')]
    [TestCase('5', '5,2')]
    [TestCase('6', '6,3')]
    [TestCase('oltre', '9,3')]
    [TestCase('negativo', '-1,0')]
    procedure DovrebbeDareIlLivelloDiFuoco(ALevel, AExpected: Integer);
    [Test]
    procedure DovrebbeVolereDuePuntiDiEnergiaPerSparare;
    [Test]
    procedure DovrebbeConsumareUnPuntoDiEnergiaQuandoIlContoFinisce;
    [Test]
    procedure DovrebbeConsumarePrimaLaRiserva;
    [Test]
    procedure DovrebbeScalareIlContoDellaQuantitaDelColpo;
    [Test]
    procedure DovrebbeNonPortareLEnergiaSottoZero;
    [Test]
    procedure DovrebbeAlternareICannoniAlPrimoLivello;
    [Test]
    procedure DovrebbeSparareADueCannoniOgniDueColpiComeLOriginale;
    [Test]
    procedure DovrebbeSparareDueTreEQuattroColpiConIlLivello;
    [Test]
    procedure DovrebbeTornareAlPrimoLivelloConPocaEnergia;
    [Test]
    procedure DovrebbeAlternareLoSpargitoreAlPrimoLivello;
    [Test]
    procedure DovrebbeConsumareEnergiaAncheAlColpoAVuotoDelloSpargitoreOriginale;
    [Test]
    procedure DovrebbeIncrociareIlTerzoColpoDelloSpargitoreAlTerzoLivello;
    [Test]
    procedure DovrebbeSparareQuattroColpiDelloSpargitoreAlLivelloMassimo;
    [Test]
    procedure DovrebbeDareLeTabelleDellEpc;
    [Test]
    procedure DovrebbeDareUnColpoVuotoFuoriDallaTabellaDellEpc;
    [Test]
    procedure DovrebbeSparareSoloIProiettiliCheRestano;
    [Test]
    procedure DovrebbeVolereLEnergiaPerLOndaGravitazionale;
    [Test]
    procedure DovrebbeVolereDueMissiliACaccia;
    [Test]
    procedure DovrebbeSparareSenzaMunizioniConUnArmaAdEnergia;
    [Test]
    procedure DovrebbeScegliereLaProssimaArmaNellOrdineDiRadX;
    [Test]
    procedure DovrebbeNonScegliereSiluriENucleariNellaVersioneShareware;
    [Test]
    procedure DovrebbeTornareAllaPrimaArmaDopoLUltimaOnda;
    [Test]
    procedure DovrebbeLanciareLaBombaSoloSeCeEdIlLampoEFinito;
  end;

implementation

{ TTestRadixWeaponRules }

procedure TTestRadixWeaponRules.Setup;
var
  LIndex: Integer;
begin
  FEnergy := Default(TRadixWeaponEnergy);
  FEnergy.Energy := 100;
  for LIndex := Low(FOwned) to High(FOwned) do
    FOwned[LIndex] := False;
  FOwned[TRadixWeaponRules.WEAPON_NEUTRON_CANNONS] := True;
  for LIndex := Low(FAmmo) to High(FAmmo) do
    FAmmo[LIndex] := 0;
end;

procedure TTestRadixWeaponRules.CheckShot(const AShot: TRadixShot; AKind: TRadixShotKind;
  AOffset, AZ: Integer; const AMessage: string);
begin
  Assert.AreEqual(AKind, AShot.Kind, AMessage + ': tipo');
  Assert.AreEqual(AOffset, AShot.Offset, AMessage + ': lato');
  Assert.AreEqual(AZ, AShot.Z, AMessage + ': altezza');
end;

procedure TTestRadixWeaponRules.DovrebbeDareITicTraDueColpi(AWeapon, ANormal, AFast: Integer);
begin
  Assert.AreEqual(ANormal, TRadixWeaponRules.RefireTics(AWeapon, False));
  Assert.AreEqual(AFast, TRadixWeaponRules.RefireTics(AWeapon, True));
end;

procedure TTestRadixWeaponRules.DovrebbeDareZeroTicPerUnArmaCheNonEsiste;
begin
  Assert.AreEqual(0, TRadixWeaponRules.RefireTics(-1, False));
  Assert.AreEqual(0, TRadixWeaponRules.RefireTics(TRadixWeaponRules.WEAPONS, True));
end;

procedure TTestRadixWeaponRules.DovrebbeNonRisparareFinoAlTempoDellArma;
begin
  Assert.IsFalse(TRadixWeaponRules.CanRefire(100, 100, 5), 'stesso tic');
  Assert.IsFalse(TRadixWeaponRules.CanRefire(104, 100, 5), 'un tic prima');
  Assert.IsTrue(TRadixWeaponRules.CanRefire(105, 100, 5), 'al tempo giusto');
  Assert.IsTrue(TRadixWeaponRules.CanRefire(3, 0, 0), 'senza attesa');
end;

procedure TTestRadixWeaponRules.DovrebbeDareIlLivelloDiFuoco(ALevel, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixWeaponRules.FireLevel(ALevel));
end;

procedure TTestRadixWeaponRules.DovrebbeVolereDuePuntiDiEnergiaPerSparare;
begin
  Assert.IsFalse(TRadixWeaponRules.HasPlasmaEnergy(0));
  Assert.IsFalse(TRadixWeaponRules.HasPlasmaEnergy(1));
  Assert.IsTrue(TRadixWeaponRules.HasPlasmaEnergy(2));
end;

procedure TTestRadixWeaponRules.DovrebbeConsumareUnPuntoDiEnergiaQuandoIlContoFinisce;
begin
  TRadixWeaponRules.DrainPlasmaEnergy(FEnergy, 3);
  Assert.AreEqual(99, FEnergy.Energy);
  Assert.AreEqual(TRadixWeaponRules.PLASMA_ENERGY_DRAIN_TICS, FEnergy.Countdown);
  Assert.AreEqual(TRadixWeaponRules.PLASMA_ENERGY_FIRE_TICS, FEnergy.FireTics);
end;

procedure TTestRadixWeaponRules.DovrebbeConsumarePrimaLaRiserva;
begin
  FEnergy.Reserve := 1;
  TRadixWeaponRules.DrainPlasmaEnergy(FEnergy, 3);
  Assert.AreEqual(0, FEnergy.Reserve);
  Assert.AreEqual(100, FEnergy.Energy, 'l''energia non si tocca finche'' c''e'' la riserva');
end;

procedure TTestRadixWeaponRules.DovrebbeScalareIlContoDellaQuantitaDelColpo;
begin
  FEnergy.Countdown := 5;
  TRadixWeaponRules.DrainPlasmaEnergy(FEnergy, 3);
  Assert.AreEqual(2, FEnergy.Countdown);
  Assert.AreEqual(100, FEnergy.Energy);
  TRadixWeaponRules.DrainPlasmaEnergy(FEnergy, 3);
  Assert.AreEqual(-1, FEnergy.Countdown);
  Assert.AreEqual(100, FEnergy.Energy);
  TRadixWeaponRules.DrainPlasmaEnergy(FEnergy, 3);
  Assert.AreEqual(99, FEnergy.Energy, 'al terzo colpo il conto e'' finito');
  Assert.AreEqual(5, FEnergy.Countdown);
end;

procedure TTestRadixWeaponRules.DovrebbeNonPortareLEnergiaSottoZero;
begin
  FEnergy.Energy := 0;
  TRadixWeaponRules.DrainPlasmaEnergy(FEnergy, 2);
  Assert.AreEqual(0, FEnergy.Energy);
  Assert.AreEqual(0, FEnergy.Reserve);
end;

procedure TTestRadixWeaponRules.DovrebbeAlternareICannoniAlPrimoLivello;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.NeutronVolley(0, 100, False, False);
  Assert.AreEqual(1, LVolley.Count);
  Assert.AreEqual(2, LVolley.Drain);
  CheckShot(LVolley.Shots[0], TRadixShotKind.Standard, SIDE, 24 * F, 'destra');
  Assert.IsTrue(LVolley.Alternate);

  LVolley := TRadixWeaponRules.NeutronVolley(0, 100, True, False);
  Assert.AreEqual(1, LVolley.Count);
  CheckShot(LVolley.Shots[0], TRadixShotKind.Standard, -SIDE, 24 * F, 'sinistra');
  Assert.IsFalse(LVolley.Alternate);
end;

procedure TTestRadixWeaponRules.DovrebbeSparareADueCannoniOgniDueColpiComeLOriginale;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.NeutronVolley(0, 100, False, True);
  Assert.AreEqual(0, LVolley.Count, 'il primo colpo e'' a vuoto');
  Assert.AreEqual(0, LVolley.Drain, 'e non consuma');
  Assert.IsTrue(LVolley.Alternate);

  LVolley := TRadixWeaponRules.NeutronVolley(0, 100, True, True);
  Assert.AreEqual(2, LVolley.Count);
  Assert.AreEqual(3, LVolley.Drain);
  CheckShot(LVolley.Shots[0], TRadixShotKind.Standard, -SIDE, 0, 'sinistra');
  CheckShot(LVolley.Shots[1], TRadixShotKind.Standard, SIDE, 0, 'destra');
  Assert.IsFalse(LVolley.Alternate);
end;

procedure TTestRadixWeaponRules.DovrebbeSparareDueTreEQuattroColpiConIlLivello;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.NeutronVolley(1, 100, True, False);
  Assert.AreEqual(2, LVolley.Count, 'livello di fuoco 1');
  Assert.AreEqual(3, LVolley.Drain);
  Assert.IsTrue(LVolley.Alternate, 'il lato non cambia');

  LVolley := TRadixWeaponRules.NeutronVolley(3, 100, False, False);
  Assert.AreEqual(3, LVolley.Count, 'livello di fuoco 2');
  CheckShot(LVolley.Shots[0], TRadixShotKind.Standard, -SIDE, 0, 'sinistra');
  CheckShot(LVolley.Shots[1], TRadixShotKind.Standard, 0, 32 * F, 'centro');
  CheckShot(LVolley.Shots[2], TRadixShotKind.Standard, SIDE, 0, 'destra');

  LVolley := TRadixWeaponRules.NeutronVolley(6, 100, False, False);
  Assert.AreEqual(4, LVolley.Count, 'livello di fuoco 3');
  Assert.AreEqual(3, LVolley.Drain);
  CheckShot(LVolley.Shots[0], TRadixShotKind.Standard, -SIDE, 0, 'sinistra in basso');
  CheckShot(LVolley.Shots[1], TRadixShotKind.Standard, -SIDE, 64 * F, 'sinistra in alto');
  CheckShot(LVolley.Shots[2], TRadixShotKind.Standard, SIDE, 0, 'destra in basso');
  CheckShot(LVolley.Shots[3], TRadixShotKind.Standard, SIDE, 64 * F, 'destra in alto');
end;

procedure TTestRadixWeaponRules.DovrebbeTornareAlPrimoLivelloConPocaEnergia;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.NeutronVolley(6, 3, False, False);
  Assert.AreEqual(1, LVolley.Count, 'un colpo solo');
  Assert.AreEqual(2, LVolley.Drain);

  // nel modo originale il colpo doppio a poca energia consuma 2 invece di 3
  LVolley := TRadixWeaponRules.NeutronVolley(6, 3, True, True);
  Assert.AreEqual(2, LVolley.Count);
  Assert.AreEqual(2, LVolley.Drain);

  LVolley := TRadixWeaponRules.NeutronVolley(6, 4, False, False);
  Assert.AreEqual(4, LVolley.Count, 'con 4 punti il livello resta');
end;

procedure TTestRadixWeaponRules.DovrebbeAlternareLoSpargitoreAlPrimoLivello;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.SpreaderVolley(0, 100, False, False);
  Assert.AreEqual(1, LVolley.Count);
  Assert.AreEqual(1, LVolley.Drain);
  CheckShot(LVolley.Shots[0], TRadixShotKind.SpreadRight, SIDE, 24 * F, 'destra');
  Assert.IsTrue(LVolley.Alternate);

  LVolley := TRadixWeaponRules.SpreaderVolley(0, 100, True, False);
  CheckShot(LVolley.Shots[0], TRadixShotKind.SpreadLeft, -SIDE, 24 * F, 'sinistra');
  Assert.IsFalse(LVolley.Alternate);
end;

procedure TTestRadixWeaponRules.DovrebbeConsumareEnergiaAncheAlColpoAVuotoDelloSpargitoreOriginale;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.SpreaderVolley(0, 100, False, True);
  Assert.AreEqual(0, LVolley.Count);
  Assert.AreEqual(1, LVolley.Drain);
  Assert.IsTrue(LVolley.Alternate);

  LVolley := TRadixWeaponRules.SpreaderVolley(0, 100, True, True);
  Assert.AreEqual(2, LVolley.Count);
  CheckShot(LVolley.Shots[0], TRadixShotKind.SpreadLeft, -SIDE, 0, 'sinistra');
  CheckShot(LVolley.Shots[1], TRadixShotKind.SpreadRight, SIDE, 0, 'destra');
  Assert.IsFalse(LVolley.Alternate);
end;

procedure TTestRadixWeaponRules.DovrebbeIncrociareIlTerzoColpoDelloSpargitoreAlTerzoLivello;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.SpreaderVolley(3, 100, True, False);
  Assert.AreEqual(3, LVolley.Count);
  Assert.AreEqual(2, LVolley.Drain);
  CheckShot(LVolley.Shots[2], TRadixShotKind.SpreadRight, -SIDE, 64 * F, 'il destro parte da sinistra');
  Assert.IsFalse(LVolley.Alternate);

  LVolley := TRadixWeaponRules.SpreaderVolley(3, 100, False, False);
  CheckShot(LVolley.Shots[2], TRadixShotKind.SpreadLeft, SIDE, 64 * F, 'il sinistro parte da destra');
  Assert.IsTrue(LVolley.Alternate);

  LVolley := TRadixWeaponRules.SpreaderVolley(3, 3, False, False);
  Assert.AreEqual(1, LVolley.Count, 'con poca energia torna al primo livello');
  Assert.AreEqual(1, LVolley.Drain);
end;

procedure TTestRadixWeaponRules.DovrebbeSparareQuattroColpiDelloSpargitoreAlLivelloMassimo;
var
  LVolley: TRadixVolley;
begin
  LVolley := TRadixWeaponRules.SpreaderVolley(6, 100, True, False);
  Assert.AreEqual(4, LVolley.Count);
  Assert.AreEqual(3, LVolley.Drain);
  CheckShot(LVolley.Shots[0], TRadixShotKind.SpreadLeft, SIDE, 0, '1');
  CheckShot(LVolley.Shots[1], TRadixShotKind.SpreadRight, SIDE, 64 * F, '2');
  CheckShot(LVolley.Shots[2], TRadixShotKind.SpreadRight, -SIDE, 0, '3');
  CheckShot(LVolley.Shots[3], TRadixShotKind.SpreadLeft, -SIDE, 64 * F, '4');
  Assert.IsTrue(LVolley.Alternate, 'il lato non cambia');
end;

procedure TTestRadixWeaponRules.DovrebbeDareLeTabelleDellEpc;
begin
  Assert.AreEqual(2, TRadixWeaponRules.EpcSize(TRadixEpcTable.Standard));
  Assert.AreEqual(4, TRadixWeaponRules.EpcSize(TRadixEpcTable.Enhanced));
  Assert.AreEqual(6, TRadixWeaponRules.EpcSize(TRadixEpcTable.Super1));
  Assert.AreEqual(6, TRadixWeaponRules.EpcSize(TRadixEpcTable.Super2));
  Assert.AreEqual(1, TRadixWeaponRules.EpcAccuracy(TRadixEpcTable.Standard));
  Assert.AreEqual(2, TRadixWeaponRules.EpcAccuracy(TRadixEpcTable.Enhanced));
  Assert.AreEqual(3, TRadixWeaponRules.EpcAccuracy(TRadixEpcTable.Super1));
  Assert.AreEqual(3, TRadixWeaponRules.EpcAccuracy(TRadixEpcTable.Super2));

  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Standard, 0), TRadixShotKind.Standard, -SIDE, 0, 'standard 0');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Standard, 1), TRadixShotKind.Standard, SIDE, 0, 'standard 1');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Enhanced, 0), TRadixShotKind.Standard, -SIDE, 64 * F, 'potenziato 0');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Enhanced, 3), TRadixShotKind.Standard, SIDE, 0, 'potenziato 3');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super1, 0), TRadixShotKind.Standard, 0, 64 * F, 'super1 0');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super1, 1), TRadixShotKind.Standard, 28 * F, 48 * F, 'super1 1');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super1, 4), TRadixShotKind.Standard, -28 * F, 16 * F, 'super1 4');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super2, 0), TRadixShotKind.Standard, 16 * F, 60 * F, 'super2 0');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super2, 1), TRadixShotKind.Standard, 32 * F, 32 * F, 'super2 1');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super2, 3), TRadixShotKind.Standard, -16 * F, 4 * F, 'super2 3');
end;

procedure TTestRadixWeaponRules.DovrebbeDareUnColpoVuotoFuoriDallaTabellaDellEpc;
begin
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Standard, 2), TRadixShotKind.Standard, 0, 0, 'oltre');
  CheckShot(TRadixWeaponRules.EpcShot(TRadixEpcTable.Super2, -1), TRadixShotKind.Standard, 0, 0, 'negativo');
end;

procedure TTestRadixWeaponRules.DovrebbeSparareSoloIProiettiliCheRestano;
begin
  Assert.AreEqual(6, TRadixWeaponRules.EpcShells(100, 6));
  Assert.AreEqual(6, TRadixWeaponRules.EpcShells(6, 6));
  Assert.AreEqual(3, TRadixWeaponRules.EpcShells(3, 6));
  Assert.AreEqual(0, TRadixWeaponRules.EpcShells(0, 6));
  Assert.AreEqual(0, TRadixWeaponRules.EpcShells(-2, 6));
end;

procedure TTestRadixWeaponRules.DovrebbeVolereLEnergiaPerLOndaGravitazionale;
begin
  Assert.IsFalse(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_GRAVITY_WAVE,
    TRadixWeaponRules.NO_AMMO, 0, 29, TRadixWeaponRules.GRAVITY_WAVE_ENERGY));
  Assert.IsTrue(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_GRAVITY_WAVE,
    TRadixWeaponRules.NO_AMMO, 0, 30, TRadixWeaponRules.GRAVITY_WAVE_ENERGY));
end;

procedure TTestRadixWeaponRules.DovrebbeVolereDueMissiliACaccia;
begin
  Assert.IsFalse(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_SEEKING_MISSILES,
    TRadixWeaponRules.AMMO_MISSILES, 1, 100, 30));
  Assert.IsTrue(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_SEEKING_MISSILES,
    TRadixWeaponRules.AMMO_MISSILES, 2, 100, 30));
  Assert.IsTrue(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_NUKE,
    TRadixWeaponRules.AMMO_NUKES, 1, 100, 30), 'alle altre ne basta una');
  Assert.IsFalse(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_NUKE,
    TRadixWeaponRules.AMMO_NUKES, 0, 100, 30));
end;

procedure TTestRadixWeaponRules.DovrebbeSparareSenzaMunizioniConUnArmaAdEnergia;
begin
  Assert.IsTrue(TRadixWeaponRules.CanFire(TRadixWeaponRules.WEAPON_NEUTRON_CANNONS,
    TRadixWeaponRules.NO_AMMO, 0, 0, 30));
end;

procedure TTestRadixWeaponRules.DovrebbeScegliereLaProssimaArmaNellOrdineDiRadX;
begin
  Assert.AreEqual(TRadixWeaponRules.WEAPON_NEUTRON_CANNONS,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, False), 'solo i cannoni');

  FOwned[TRadixWeaponRules.WEAPON_PLASMA_SPREADER] := True;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_PLASMA_SPREADER,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, False), 'lo spargitore se i cannoni sono al primo livello');
  Assert.AreEqual(TRadixWeaponRules.WEAPON_NEUTRON_CANNONS,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 1, False), 'i cannoni potenziati vincono');

  FOwned[TRadixWeaponRules.WEAPON_SEEKING_MISSILES] := True;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_PLASMA_SPREADER,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, False), 'i missili senza munizioni no');
  FAmmo[TRadixWeaponRules.AMMO_MISSILES] := 1;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_SEEKING_MISSILES,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, False));

  FOwned[TRadixWeaponRules.WEAPON_NUKE] := True;
  FAmmo[TRadixWeaponRules.AMMO_NUKES] := 1;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_NUKE, TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, False));

  FOwned[TRadixWeaponRules.WEAPON_PHASE_TORPEDOES] := True;
  FAmmo[TRadixWeaponRules.AMMO_TORPEDOES] := 1;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_PHASE_TORPEDOES,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, False));
end;

procedure TTestRadixWeaponRules.DovrebbeNonScegliereSiluriENucleariNellaVersioneShareware;
begin
  FOwned[TRadixWeaponRules.WEAPON_NUKE] := True;
  FAmmo[TRadixWeaponRules.AMMO_NUKES] := 5;
  FOwned[TRadixWeaponRules.WEAPON_PHASE_TORPEDOES] := True;
  FAmmo[TRadixWeaponRules.AMMO_TORPEDOES] := 5;
  FOwned[TRadixWeaponRules.WEAPON_SEEKING_MISSILES] := True;
  FAmmo[TRadixWeaponRules.AMMO_MISSILES] := 5;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_SEEKING_MISSILES,
    TRadixWeaponRules.NextWeapon(FOwned, FAmmo, 0, True));
end;

procedure TTestRadixWeaponRules.DovrebbeTornareAllaPrimaArmaDopoLUltimaOnda;
begin
  FOwned[TRadixWeaponRules.WEAPON_NUKE] := True;
  FOwned[TRadixWeaponRules.WEAPON_GRAVITY_WAVE] := True;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_NEUTRON_CANNONS, TRadixWeaponRules.WeaponAfterGravityWave(FOwned));

  FOwned[TRadixWeaponRules.WEAPON_NEUTRON_CANNONS] := False;
  Assert.AreEqual(TRadixWeaponRules.WEAPON_NUKE, TRadixWeaponRules.WeaponAfterGravityWave(FOwned));

  FOwned[TRadixWeaponRules.WEAPON_NUKE] := False;
  FOwned[TRadixWeaponRules.WEAPON_SUPER_EPC] := True;
  Assert.AreEqual(-1, TRadixWeaponRules.WeaponAfterGravityWave(FOwned), 'le armi dopo l''onda non contano');
end;

procedure TTestRadixWeaponRules.DovrebbeLanciareLaBombaSoloSeCeEdIlLampoEFinito;
begin
  Assert.IsFalse(TRadixWeaponRules.CanFirePlasmaBomb(0, 0), 'nessuna bomba');
  Assert.IsFalse(TRadixWeaponRules.CanFirePlasmaBomb(2, 3), 'il lampo non e'' finito');
  Assert.IsTrue(TRadixWeaponRules.CanFirePlasmaBomb(1, 0));
end;

end.
