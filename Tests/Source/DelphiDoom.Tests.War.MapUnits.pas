{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the tables of the units              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUnits;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Map.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarUnitCatalog = class(TObject)
  private
    FCatalog: IWarUnitCatalog;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLaRisorsaELaMisuraDiUnTipo;
    [Test]
    procedure DovrebbeDareFalsoPerUnTipoSenzaTabella;
    [Test]
    procedure DovrebbeDistinguereLeUnitaCheSiMuovonoDagliEdifici;
    [Test]
    procedure DovrebbeRiconoscereLeUnitaEvocateEICadaveri;
    [Test]
    procedure DovrebbeDareLaVistaDiUnEdificioEQuelladiUnaUnita;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaVistaDiUnTipoNonHaTabella;
    [Test]
    procedure DovrebbeCreareUnaUnitaConIPuntiFerita;
    [Test]
    procedure DovrebbeDareAUnaUnitaEvocataTuttaLaMana;
    [Test]
    procedure DovrebbeCreareUnaMinieraConLOro;
    [Test]
    procedure DovrebbeCreareUnCadavereSenzaStatistiche;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnTipoNonEInTabella;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnaUnitaCheSiMuoveNonHaStatistiche;
  end;

implementation

uses
  DelphiDoom.War.Map.Factory;

{ TTestWarUnitCatalog }

procedure TTestWarUnitCatalog.Setup;
begin
  FCatalog := TWarMapFactory.CreateUnitCatalog;
end;

procedure TTestWarUnitCatalog.DovrebbeDareLaRisorsaELaMisuraDiUnTipo;
var
  LData: TWarUnitData;
begin
  Assert.IsTrue(FCatalog.TryGetData(WAR_UNIT_GOLDMINE, LData));
  Assert.AreEqual<Integer>(325, LData.ResourceIndex);
  Assert.AreEqual<Integer>(3, LData.SizeX);
  Assert.AreEqual<Integer>(3, LData.SizeY);
end;

procedure TTestWarUnitCatalog.DovrebbeDareFalsoPerUnTipoSenzaTabella;
var
  LData: TWarUnitData;
begin
  Assert.IsFalse(FCatalog.TryGetData(WAR_UNIT_DRAGON_CYCLOPS_GIANT, LData));
  Assert.AreEqual<Integer>(0, LData.SizeX);
end;

procedure TTestWarUnitCatalog.DovrebbeDistinguereLeUnitaCheSiMuovonoDagliEdifici;
begin
  Assert.IsTrue(FCatalog.IsDudeType(WAR_UNIT_FOOTMAN));
  Assert.IsTrue(FCatalog.IsDudeType(WAR_UNIT_WATER_ELEMENTAL));
  Assert.IsFalse(FCatalog.IsDudeType(WAR_UNIT_FARM_HUMANS));
  Assert.IsTrue(FCatalog.IsBuildingType(WAR_UNIT_FARM_HUMANS));
  Assert.IsTrue(FCatalog.IsBuildingType(WAR_UNIT_GOLDMINE));
  Assert.IsFalse(FCatalog.IsBuildingType(WAR_UNIT_HUMAN_CORPSE));
  Assert.IsFalse(FCatalog.IsBuildingType(WAR_UNIT_ARCHER));
end;

procedure TTestWarUnitCatalog.DovrebbeRiconoscereLeUnitaEvocateEICadaveri;
begin
  Assert.IsTrue(FCatalog.IsSummonType(WAR_UNIT_SPIDER));
  Assert.IsTrue(FCatalog.IsSummonType(WAR_UNIT_THE_DEAD));
  Assert.IsFalse(FCatalog.IsSummonType(WAR_UNIT_OGRE));
  Assert.IsTrue(FCatalog.IsCorpseType(WAR_UNIT_ORC_CORPSE));
  Assert.IsFalse(FCatalog.IsCorpseType(WAR_UNIT_GRUNT));
end;

procedure TTestWarUnitCatalog.DovrebbeDareLaVistaDiUnEdificioEQuelladiUnaUnita;
begin
  Assert.AreEqual<Integer>(3, FCatalog.SightRange(WAR_UNIT_TOWNHALL_HUMANS));
  Assert.AreEqual<Integer>(2, FCatalog.SightRange(WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(5, FCatalog.SightRange(WAR_UNIT_CATAPULT_ORCS));
end;

procedure TTestWarUnitCatalog.DovrebbeSollevareEccezioneSeLaVistaDiUnTipoNonHaTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      FCatalog.SightRange(WAR_UNIT_WOUNDED);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FCatalog.SightRange(WAR_UNIT_51);
    end, EWarException);
end;

procedure TTestWarUnitCatalog.DovrebbeCreareUnaUnitaConIPuntiFerita;
var
  LUnit: TWarMapUnit;
begin
  LUnit := FCatalog.CreateUnit(7, WAR_UNIT_FOOTMAN, 10, 12, 1, wrkNone, 0);
  Assert.AreEqual<Integer>(7, LUnit.Id);
  Assert.AreEqual<Integer>(60, LUnit.Hp);
  Assert.AreEqual<Integer>(60, LUnit.MaxHp);
  Assert.AreEqual<Integer>(100, LUnit.Mana);
  Assert.AreEqual<Integer>(-1, LUnit.MaxMana);
  Assert.AreEqual<Integer>(2, LUnit.Armor);
  Assert.AreEqual<Integer>(1, LUnit.Range);
  Assert.AreEqual<Integer>(1, LUnit.MinDamage);
  Assert.AreEqual<Integer>(9, LUnit.RndDamage);
  Assert.AreEqual<Integer>(-1, LUnit.Decay);
  Assert.AreEqual<Integer>(1, LUnit.ManaTime);
  Assert.AreEqual<Integer>(0, LUnit.Direction);
  Assert.AreEqual<Integer>(1, LUnit.SizeX);
  Assert.AreEqual<Integer>(10, LUnit.TileX);
  Assert.AreEqual<Integer>(1, Integer(LUnit.Player));
  Assert.IsFalse(LUnit.HasBeenSeen);
end;

procedure TTestWarUnitCatalog.DovrebbeDareAUnaUnitaEvocataTuttaLaMana;
var
  LUnit: TWarMapUnit;
begin
  LUnit := FCatalog.CreateUnit(1, WAR_UNIT_SPIDER, 0, 0, 0, wrkNone, 0);
  Assert.AreEqual<Integer>(255, LUnit.Mana);
  Assert.AreEqual<Integer>(255, LUnit.MaxMana);
  Assert.AreEqual<Integer>(45, LUnit.Decay);
end;

procedure TTestWarUnitCatalog.DovrebbeCreareUnaMinieraConLOro;
var
  LUnit: TWarMapUnit;
begin
  LUnit := FCatalog.CreateUnit(2, WAR_UNIT_GOLDMINE, 20, 30, 4, wrkGold, 23500);
  Assert.AreEqual<Integer>(25500, LUnit.Hp);
  Assert.AreEqual<Integer>(3, LUnit.SizeY);
  Assert.AreEqual<Integer>(23500, LUnit.Amount);
  Assert.IsTrue(LUnit.ResourceKind = wrkGold);
  Assert.AreEqual<Integer>(0, LUnit.Mana);
  Assert.AreEqual<Integer>(0, LUnit.ManaTime);
end;

procedure TTestWarUnitCatalog.DovrebbeCreareUnCadavereSenzaStatistiche;
var
  LUnit: TWarMapUnit;
begin
  LUnit := FCatalog.CreateUnit(3, WAR_UNIT_HUMAN_CORPSE, 4, 4, 0, wrkNone, 0);
  Assert.AreEqual<Integer>(0, LUnit.Hp);
  Assert.AreEqual<Integer>(1, LUnit.SizeX);
end;

procedure TTestWarUnitCatalog.DovrebbeSollevareEccezioneSeUnTipoNonEInTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      FCatalog.CreateUnit(1, WAR_UNIT_DRAGON_CYCLOPS_GIANT, 0, 0, 0, wrkNone, 0);
    end, EWarException);
end;

procedure TTestWarUnitCatalog.DovrebbeSollevareEccezioneSeUnaUnitaCheSiMuoveNonHaStatistiche;
begin
  // the wounded has a sprite but no statistics: the original stops on an assert
  Assert.WillRaise(
    procedure
    begin
      FCatalog.CreateUnit(1, WAR_UNIT_WOUNDED, 0, 0, 0, wrkNone, 0);
    end, EWarException);
end;

end.
