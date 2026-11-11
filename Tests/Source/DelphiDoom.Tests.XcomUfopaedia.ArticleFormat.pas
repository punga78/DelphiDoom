{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library - the rows of           }
{  statistics of the articles (TXcomArticleFormat)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomUfopaedia.ArticleFormat;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomUfopaedia.Types;

type
  [TestFixture]
  [Category('xcom-ufopaedia')]
  TTestXcomArticleFormat = class(TObject)
  strict private
    FRules: TXcomRuleset;
    function RowsText(const ARows: TArray<TXcomArticleRow>): string;
    function ShotsText(const AShots: TArray<TXcomArticleShot>): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('nessuno', '0,STR_UNKNOWN')]
    [TestCase('perforante', '1,STR_DAMAGE_ARMOR_PIERCING')]
    [TestCase('incendiario', '2,STR_DAMAGE_INCENDIARY')]
    [TestCase('esplosivo', '3,STR_DAMAGE_HIGH_EXPLOSIVE')]
    [TestCase('laser', '4,STR_DAMAGE_LASER_BEAM')]
    [TestCase('plasma', '5,STR_DAMAGE_PLASMA_BEAM')]
    [TestCase('stordente', '6,STR_DAMAGE_STUN')]
    [TestCase('corpo a corpo', '7,STR_DAMAGE_MELEE')]
    [TestCase('acido', '8,STR_DAMAGE_ACID')]
    [TestCase('fumo', '9,STR_DAMAGE_SMOKE')]
    [TestCase('fuori elenco', '10,STR_UNKNOWN')]
    procedure DovrebbeDareIlNomeDelTipoDiDanno(ADamageType: Integer; const AExpected: string);
    [Test]
    procedure DovrebbeScrivereLaPercentuale;
    [Test]
    procedure DovrebbeMettereIlPiuSoloDavantiAiPositiviQuandoRichiesto;
    [Test]
    procedure DovrebbeScrivereLaPotenzaConIPalliniDelFucileAPompa;
    [Test]
    procedure DovrebbeDareLeRigheDellaCorazzaSaltandoGliZeriEICentoPerCento;
    [Test]
    procedure DovrebbeDareSoloLeDueRigheVuotePerUnaCorazzaSenzaValori;
    [Test]
    procedure DovrebbeDareITreColpiDiUnArmaDaFuoco;
    [Test]
    procedure DovrebbeSaltareIColpiSenzaCostoEToglierePercentoConLaTariffaFissa;
    [Test]
    procedure DovrebbeDareLeRigheDelCorpoDiUnVeicolo;
    [Test]
    procedure DovrebbeDareLeRigheDellArmaDiUnVeicoloConMunizioni;
    [Test]
    procedure DovrebbeDareLeRigheDellArmaDiUnVeicoloSenzaMunizioni;
    [Test]
    procedure DovrebbeDareLeRigheDiDifesaSoloSeLaStrutturaDifende;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomUfopaedia.ArticleFormat, DelphiDoom.Tests.XcomUfopaedia.Fakes;

procedure TTestXcomArticleFormat.Setup;
begin
  FRules := TUfopaediaTestRules.Standard;
end;

procedure TTestXcomArticleFormat.TearDown;
begin
  FRules.Free;
end;

function TTestXcomArticleFormat.RowsText(const ARows: TArray<TXcomArticleRow>): string;
var
  LRow: TXcomArticleRow;
begin
  Result := '';
  for LRow in ARows do
    if LRow.Blank then
      Result := Result + '-|'
    else if LRow.ValueIsId then
      Result := Result + LRow.LabelId + '=@' + LRow.Value + '|'
    else
      Result := Result + LRow.LabelId + '=' + LRow.Value + '|';
end;

function TTestXcomArticleFormat.ShotsText(const AShots: TArray<TXcomArticleShot>): string;
var
  LShot: TXcomArticleShot;
begin
  Result := '';
  for LShot in AShots do
    Result := Result + LShot.LabelId + '=' + LShot.Accuracy + '/' + LShot.Cost + '|';
end;

procedure TTestXcomArticleFormat.DovrebbeDareIlNomeDelTipoDiDanno(ADamageType: Integer; const AExpected: string);
begin
  Assert.AreEqual(AExpected, TXcomArticleFormat.DamageTypeText(ADamageType));
end;

procedure TTestXcomArticleFormat.DovrebbeScrivereLaPercentuale;
begin
  Assert.AreEqual('110%', TXcomArticleFormat.FormatPercentage(110));
  Assert.AreEqual('0%', TXcomArticleFormat.FormatPercentage(0));
end;

procedure TTestXcomArticleFormat.DovrebbeMettereIlPiuSoloDavantiAiPositiviQuandoRichiesto;
begin
  Assert.AreEqual('+5', TXcomArticleFormat.Signed(5, True));
  Assert.AreEqual('5', TXcomArticleFormat.Signed(5, False));
  Assert.AreEqual('-3', TXcomArticleFormat.Signed(-3, True));
end;

procedure TTestXcomArticleFormat.DovrebbeScrivereLaPotenzaConIPalliniDelFucileAPompa;
var
  LRules: TXcomRuleset;
  LItem: TXcomRuleItem;
begin
  LRules := TUfopaediaTestRules.Load(
    'items:'#10'  - type: STR_SHELLS'#10'    battleType: 2'#10'    power: 22'#10'    shotgunPellets: 6'#10);
  try
    LItem := LRules.Items.Find('STR_SHELLS');
    Assert.AreEqual('22x6', TXcomArticleFormat.PowerText(LItem));
    Assert.AreEqual('22', TXcomArticleFormat.PowerText(LItem, False));
  finally
    LRules.Free;
  end;
  Assert.AreEqual('30', TXcomArticleFormat.PowerText(FRules.Items.Find('STR_RIFLE_CLIP')));
end;

procedure TTestXcomArticleFormat.DovrebbeDareLeRigheDellaCorazzaSaltandoGliZeriEICentoPerCento;
begin
  Assert.AreEqual(
    'STR_FRONT_ARMOR=50|STR_LEFT_ARMOR=40|STR_RIGHT_ARMOR=40|STR_REAR_ARMOR=30|-|' +
    'STR_DAMAGE_ARMOR_PIERCING=80%|STR_DAMAGE_HIGH_EXPLOSIVE=70%|STR_DAMAGE_ACID=130%|STR_DAMAGE_SMOKE=0%|-|' +
    'STR_TIME_UNITS=+5|STR_STRENGTH=-3|',
    RowsText(TXcomArticleFormat.ArmorRows(FRules.Armors.Find('STR_SUIT'))));
end;

procedure TTestXcomArticleFormat.DovrebbeDareSoloLeDueRigheVuotePerUnaCorazzaSenzaValori;
var
  LRules: TXcomRuleset;
begin
  LRules := TUfopaediaTestRules.Load(
    'armors:'#10'  - type: STR_NUDE'#10'    spriteInv: X'#10'    corpseBattle:'#10'      - STR_CORPSE'#10);
  try
    Assert.AreEqual('-|-|', RowsText(TXcomArticleFormat.ArmorRows(LRules.Armors.Find('STR_NUDE'))));
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomArticleFormat.DovrebbeDareITreColpiDiUnArmaDaFuoco;
begin
  Assert.AreEqual('STR_SHOT_TYPE_AUTO=35%/35%|STR_SHOT_TYPE_SNAP=60%/25%|STR_SHOT_TYPE_AIMED=110%/80%|',
    ShotsText(TXcomArticleFormat.ShotRows(FRules.Items.Find('STR_RIFLE'))));
end;

procedure TTestXcomArticleFormat.DovrebbeSaltareIColpiSenzaCostoEToglierePercentoConLaTariffaFissa;
var
  LRules: TXcomRuleset;
begin
  LRules := TUfopaediaTestRules.Load(
    'items:'#10'  - type: STR_PISTOL'#10'    battleType: 1'#10'    clipSize: 5'#10'    flatRate: true'#10 +
    '    accuracySnap: 60'#10'    tuSnap: 18'#10'    accuracyAimed: 78'#10'    tuAimed: 30'#10);
  try
    Assert.AreEqual('STR_SHOT_TYPE_SNAP=60%/18|STR_SHOT_TYPE_AIMED=78%/30|',
      ShotsText(TXcomArticleFormat.ShotRows(LRules.Items.Find('STR_PISTOL'))));
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomArticleFormat.DovrebbeDareLeRigheDelCorpoDiUnVeicolo;
begin
  Assert.AreEqual(
    'STR_TIME_UNITS=70|STR_HEALTH=90|STR_FRONT_ARMOR=90|STR_LEFT_ARMOR=75|STR_RIGHT_ARMOR=75|STR_REAR_ARMOR=60|' +
    'STR_UNDER_ARMOR=20|',
    RowsText(TXcomArticleFormat.VehicleBodyRows(FRules.Units.Find('STR_TANK'), FRules.Armors.Find('TANK_ARMOR'))));
end;

procedure TTestXcomArticleFormat.DovrebbeDareLeRigheDellArmaDiUnVeicoloConMunizioni;
begin
  // the tank has no clip of its own: the rounds are the ones of the ammunition
  Assert.AreEqual('STR_WEAPON=@STR_TANK_WEAPON|STR_WEAPON_POWER=60|STR_AMMUNITION=@STR_TANK_SHELL|STR_ROUNDS=30|',
    RowsText(TXcomArticleFormat.VehicleWeaponRows('STR_TANK_WEAPON', FRules.Items.Find('STR_TANK'),
      FRules.Items.Find('STR_TANK_SHELL'))));
  // an item with its own clip shows its own rounds
  Assert.AreEqual('STR_WEAPON=@W|STR_WEAPON_POWER=60|STR_AMMUNITION=@STR_TANK_SHELL|STR_ROUNDS=255|',
    RowsText(TXcomArticleFormat.VehicleWeaponRows('W', FRules.Items.Find('STR_LASER_TANK'),
      FRules.Items.Find('STR_TANK_SHELL'))));
end;

procedure TTestXcomArticleFormat.DovrebbeDareLeRigheDellArmaDiUnVeicoloSenzaMunizioni;
begin
  Assert.AreEqual('STR_WEAPON=@STR_LASER_WEAPON|STR_WEAPON_POWER=110|',
    RowsText(TXcomArticleFormat.VehicleWeaponRows('STR_LASER_WEAPON', FRules.Items.Find('STR_LASER_TANK'), nil)));
end;

procedure TTestXcomArticleFormat.DovrebbeDareLeRigheDiDifesaSoloSeLaStrutturaDifende;
begin
  Assert.AreEqual('', RowsText(TXcomArticleFormat.FacilityDefenseRows(FRules.Facilities.Find('STR_LAB'))));
  Assert.AreEqual('STR_DEFENSE_VALUE=500|STR_HIT_RATIO=50%|',
    RowsText(TXcomArticleFormat.FacilityDefenseRows(FRules.Facilities.Find('STR_DEFENSE'))));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomArticleFormat);

end.
