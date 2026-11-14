{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the database, the actions and the    }
{  classification of the unit types                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelTables;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarDatabase = class(TObject)
  private
    FDatabase: IWarDatabase;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLeStatisticheDiUnFante;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnTipoNonHaStatistiche;
    [Test]
    procedure DovrebbeDareFalsoSenzaEccezioneConTryGet;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnEdificioNonHaStatistiche;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnMiglioramentoOUnIncantesimoNonEsistono;
    [Test]
    procedure DovrebbeDareLaMisuraDiUnTipo;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarUnitClassifier = class(TObject)
  public
    [Test]
    procedure DovrebbeDareFalsoPerITipiFuoriTabella;
    [Test]
    procedure DovrebbeDareRazzaNeutraAiTipiSenzaRazza;
    [Test]
    procedure DovrebbeDareLoStessoTipoPerUnaRazzaNeutra;
    [Test]
    procedure DovrebbeRiconoscereLoScheletro;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarActionTable = class(TObject)
  public
    [Test]
    procedure DovrebbeDareFalsoPerAzioniOTipiFuoriTabella;
    [Test]
    procedure DovrebbeDareZeroPerUnaAzioneCheIlTipoNonHa;
    [Test]
    procedure DovrebbeImpostareLAzioneEIlSuoPasso;
    [Test]
    procedure DovrebbeLasciareTuttoSeIlTipoNonHaLAzione;
    [Test]
    procedure DovrebbeTenereLaScalaSeQuellaDataEnegativa;
    [Test]
    procedure DovrebbeLevareLAzioneCorrenteConNessuna;
    [Test]
    procedure DovrebbeInizializzareLeAzioni;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Stats.Types,
  DelphiDoom.War.Model.Database, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.ActionTable;

{ TTestWarDatabase }

procedure TTestWarDatabase.Setup;
begin
  FDatabase := TWarDatabase.Create;
end;

procedure TTestWarDatabase.DovrebbeDareLeStatisticheDiUnFante;
var
  LStats: TWarUnitStatsFull;
begin
  LStats := FDatabase.GetUnitStats(WAR_UNIT_FOOTMAN);
  Assert.AreEqual<Integer>(60, LStats.Hp);
  Assert.AreEqual<Integer>(400, LStats.GoldCost);
  Assert.AreEqual<Integer>(48, LStats.BuildTime);
end;

procedure TTestWarDatabase.DovrebbeSollevareEccezioneSeUnTipoNonHaStatistiche;
begin
  Assert.WillRaise(
    procedure
    begin
      FDatabase.GetUnitStats(WAR_UNIT_WOUNDED);
    end, EWarException);
end;

procedure TTestWarDatabase.DovrebbeDareFalsoSenzaEccezioneConTryGet;
var
  LStats: TWarUnitStatsFull;
begin
  Assert.IsFalse(FDatabase.TryGetUnitStats(WAR_UNIT_FARM_HUMANS, LStats));
  Assert.AreEqual<Integer>(0, LStats.Hp);
  Assert.IsTrue(FDatabase.TryGetUnitStats(WAR_UNIT_GRUNT, LStats));
end;

procedure TTestWarDatabase.DovrebbeSollevareEccezioneSeUnEdificioNonHaStatistiche;
begin
  Assert.WillRaise(
    procedure
    begin
      FDatabase.GetBuildingStats(WAR_UNIT_FOOTMAN);
    end, EWarException);
  Assert.AreEqual<Integer>(400, FDatabase.GetBuildingStats(WAR_UNIT_FARM_HUMANS).Hp);
end;

procedure TTestWarDatabase.DovrebbeSollevareEccezioneSeUnMiglioramentoOUnIncantesimoNonEsistono;
begin
  Assert.WillRaise(
    procedure
    begin
      FDatabase.GetUpgradeStats(99);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FDatabase.GetSpellStats(99);
    end, EWarException);
  Assert.AreEqual<Integer>(2, FDatabase.GetUpgradeStats(WAR_UPGRADE_ARROWS).MaxLevel);
  Assert.AreEqual<Integer>(6, FDatabase.GetSpellStats(WAR_SPELL_HEALING).ManaCost);
end;

procedure TTestWarDatabase.DovrebbeDareLaMisuraDiUnTipo;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  Assert.IsTrue(FDatabase.TryGetUnitSize(WAR_UNIT_TOWNHALL_HUMANS, LWidth, LHeight));
  Assert.AreEqual<Integer>(3, LWidth);
  Assert.AreEqual<Integer>(3, LHeight);
  Assert.IsFalse(FDatabase.TryGetUnitSize(WAR_UNIT_DRAGON_CYCLOPS_GIANT, LWidth, LHeight));
  Assert.AreEqual<Integer>(0, LWidth);
end;

{ TTestWarUnitClassifier }

procedure TTestWarUnitClassifier.DovrebbeDareFalsoPerITipiFuoriTabella;
begin
  Assert.IsFalse(TWarUnitClassifier.IsDude(-1));
  Assert.IsFalse(TWarUnitClassifier.IsDude(300));
  Assert.IsFalse(TWarUnitClassifier.IsBuilding(1000));
  Assert.IsFalse(TWarUnitClassifier.IsWarrior(-5));
  Assert.IsFalse(TWarUnitClassifier.IsWorker(256));
  Assert.IsFalse(TWarUnitClassifier.IsRange(-1));
  Assert.IsFalse(TWarUnitClassifier.IsMelee(-1));
  Assert.IsFalse(TWarUnitClassifier.IsFist(-1));
  Assert.IsFalse(TWarUnitClassifier.IsSword(-1));
  Assert.IsFalse(TWarUnitClassifier.IsMagic(-1));
  Assert.IsFalse(TWarUnitClassifier.IsCorpse(-1));
  Assert.IsFalse(TWarUnitClassifier.IsCatapult(-1));
  Assert.IsFalse(TWarUnitClassifier.IsConjurerOrWarlock(-1));
  Assert.IsFalse(TWarUnitClassifier.IsClericOrNecrolyte(-1));
  Assert.IsFalse(TWarUnitClassifier.IsSummon(-1));
end;

procedure TTestWarUnitClassifier.DovrebbeDareRazzaNeutraAiTipiSenzaRazza;
begin
  Assert.AreEqual<Integer>(Ord(wraNeutral), Ord(TWarUnitClassifier.RaceOf(WAR_UNIT_OGRE)));
  Assert.AreEqual<Integer>(Ord(wraNeutral), Ord(TWarUnitClassifier.RaceOf(-3)));
  Assert.AreEqual<Integer>(Ord(wraHumans), Ord(TWarUnitClassifier.RaceOf(WAR_UNIT_FOOTMAN)));
  Assert.AreEqual<Integer>(Ord(wraOrcs), Ord(TWarUnitClassifier.RaceOf(WAR_UNIT_GRUNT)));
end;

procedure TTestWarUnitClassifier.DovrebbeDareLoStessoTipoPerUnaRazzaNeutra;
begin
  Assert.AreEqual<Integer>(WAR_UNIT_GRUNT, TWarUnitClassifier.TypeForRace(WAR_UNIT_GRUNT, wraNeutral));
  Assert.AreEqual<Integer>(WAR_UNIT_FOOTMAN, TWarUnitClassifier.TypeForRace(WAR_UNIT_GRUNT, wraHumans));
  Assert.AreEqual<Integer>(WAR_UNIT_GRUNT, TWarUnitClassifier.TypeForRace(WAR_UNIT_FOOTMAN, wraOrcs));
end;

procedure TTestWarUnitClassifier.DovrebbeRiconoscereLoScheletro;
begin
  Assert.IsTrue(TWarUnitClassifier.IsSkeleton(WAR_UNIT_SKELETON));
  Assert.IsFalse(TWarUnitClassifier.IsSkeleton(WAR_UNIT_FOOTMAN));
end;

{ TTestWarActionTable }

procedure TTestWarActionTable.DovrebbeDareFalsoPerAzioniOTipiFuoriTabella;
begin
  Assert.IsFalse(TWarActionTable.Has(-1, WAR_ACTION_IDLE));
  Assert.IsFalse(TWarActionTable.Has(WAR_UNIT_COUNT, WAR_ACTION_IDLE));
  Assert.IsFalse(TWarActionTable.Has(WAR_UNIT_FOOTMAN, WAR_ACTION_NONE));
  Assert.IsFalse(TWarActionTable.Has(WAR_UNIT_FOOTMAN, WAR_ACTION_TYPE_COUNT));
end;

procedure TTestWarActionTable.DovrebbeDareZeroPerUnaAzioneCheIlTipoNonHa;
begin
  Assert.AreEqual<Integer>(0, TWarActionTable.Duration(WAR_UNIT_FOOTMAN, WAR_ACTION_BUILD));
  Assert.AreEqual<Integer>(0, TWarActionTable.Duration(WAR_UNIT_FOOTMAN, WAR_ACTION_NONE));
  Assert.IsTrue(TWarActionTable.Duration(WAR_UNIT_FOOTMAN, WAR_ACTION_DEATH) > 0);
end;

procedure TTestWarActionTable.DovrebbeImpostareLAzioneEIlSuoPasso;
var
  LUnit: TWarUnitComponent;
begin
  LUnit := Default(TWarUnitComponent);
  LUnit.UnitType := WAR_UNIT_FOOTMAN;
  TWarActionTable.InitActions(LUnit);
  LUnit.Actions[WAR_ACTION_WALK].StepIndex := 5;
  LUnit.Actions[WAR_ACTION_WALK].Status := WAR_ACTION_RUNNING;
  TWarActionTable.SetAction(LUnit, WAR_ACTION_WALK, True, 0.5);
  Assert.AreEqual<Integer>(WAR_ACTION_WALK, LUnit.ActionType);
  Assert.AreEqual<Single>(0.5, LUnit.Actions[WAR_ACTION_WALK].Scale);
  Assert.AreEqual<Integer>(0, LUnit.Actions[WAR_ACTION_WALK].StepIndex);
  Assert.AreEqual<Integer>(WAR_ACTION_NOT_STARTED, LUnit.Actions[WAR_ACTION_WALK].Status);
end;

procedure TTestWarActionTable.DovrebbeLasciareTuttoSeIlTipoNonHaLAzione;
var
  LUnit: TWarUnitComponent;
begin
  LUnit := Default(TWarUnitComponent);
  LUnit.UnitType := WAR_UNIT_FOOTMAN;
  LUnit.ActionType := WAR_ACTION_IDLE;
  TWarActionTable.SetAction(LUnit, WAR_ACTION_BUILD, True, 0.5);
  Assert.AreEqual<Integer>(WAR_ACTION_IDLE, LUnit.ActionType);
end;

procedure TTestWarActionTable.DovrebbeTenereLaScalaSeQuellaDataEnegativa;
var
  LUnit: TWarUnitComponent;
begin
  LUnit := Default(TWarUnitComponent);
  LUnit.UnitType := WAR_UNIT_FOOTMAN;
  TWarActionTable.InitActions(LUnit);
  TWarActionTable.SetAction(LUnit, WAR_ACTION_ATTACK, False, -1);
  Assert.AreEqual<Single>(1.0, LUnit.Actions[WAR_ACTION_ATTACK].Scale);
  Assert.AreEqual<Integer>(-1, LUnit.Actions[WAR_ACTION_ATTACK].StepIndex);
end;

procedure TTestWarActionTable.DovrebbeLevareLAzioneCorrenteConNessuna;
var
  LUnit: TWarUnitComponent;
begin
  LUnit := Default(TWarUnitComponent);
  LUnit.ActionType := WAR_ACTION_WALK;
  TWarActionTable.SetAction(LUnit, WAR_ACTION_NONE, True, 1);
  Assert.AreEqual<Integer>(WAR_ACTION_NONE, LUnit.ActionType);
end;

procedure TTestWarActionTable.DovrebbeInizializzareLeAzioni;
var
  LUnit: TWarUnitComponent;
  LIndex: Integer;
begin
  LUnit := Default(TWarUnitComponent);
  TWarActionTable.InitActions(LUnit);
  for LIndex := 0 to WAR_ACTION_TYPE_COUNT - 1 do
  begin
    Assert.AreEqual<Single>(1.0, LUnit.Actions[LIndex].Scale);
    Assert.AreEqual<Integer>(-1, LUnit.Actions[LIndex].StepIndex);
    Assert.AreEqual<Integer>(WAR_ACTION_NOT_STARTED, LUnit.Actions[LIndex].Status);
  end;
end;

end.
