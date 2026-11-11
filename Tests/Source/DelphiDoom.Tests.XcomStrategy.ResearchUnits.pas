{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the small rules of     }
{  research that need no data (IsResearched, score, the order of new topics)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.ResearchUnits;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomMod.RuleResearch,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomStrategy.ResearchRules;

type
  [TestFixture]
  [Category('xcom-strategy')]
  TTestXcomResearchUnits = class(TObject)
  strict private
    FGame: TXcomSavedGame;
    FRules: array of TXcomRuleResearch;
    function Rule(const AName: string): TXcomRuleResearch;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareFalsoPerUnaRicercaNonScoperta;
    [Test]
    procedure DovrebbeDareVeroPerUnaRicercaScoperta;
    [Test]
    procedure DovrebbeDareVeroPerUnElencoVuoto;
    [Test]
    procedure DovrebbeVolereTutteLeRicercheDellElenco;
    [Test]
    procedure DovrebbeSommareIlPunteggioDelMeseCorrente;
    [Test]
    procedure DovrebbeOrdinareLeNuoveRicerchePerNomeEToglierePerEsistenti;
  end;

implementation

{ TTestXcomResearchUnits }

procedure TTestXcomResearchUnits.Setup;
begin
  FGame := TXcomSavedGame.Create;
end;

procedure TTestXcomResearchUnits.TearDown;
var
  LRule: TXcomRuleResearch;
begin
  FGame.Free;
  for LRule in FRules do
    LRule.Free;
  FRules := nil;
end;

function TTestXcomResearchUnits.Rule(const AName: string): TXcomRuleResearch;
begin
  Result := TXcomRuleResearch.Create(AName);
  FRules := FRules + [Result];
end;

procedure TTestXcomResearchUnits.DovrebbeDareFalsoPerUnaRicercaNonScoperta;
begin
  Assert.IsFalse(FGame.IsResearched('STR_LASER', False));
end;

procedure TTestXcomResearchUnits.DovrebbeDareVeroPerUnaRicercaScoperta;
begin
  FGame.Discovered.Add(Rule('STR_LASER'));
  Assert.IsTrue(FGame.IsResearched('STR_LASER', False));
  Assert.IsFalse(FGame.IsResearched('STR_PLASMA', False));
end;

procedure TTestXcomResearchUnits.DovrebbeDareVeroPerUnElencoVuoto;
begin
  Assert.IsTrue(FGame.IsResearched(TArray<string>.Create(), False));
end;

procedure TTestXcomResearchUnits.DovrebbeVolereTutteLeRicercheDellElenco;
begin
  FGame.Discovered.Add(Rule('A'));
  Assert.IsFalse(FGame.IsResearched(TArray<string>.Create('A', 'B'), False), 'manca B');
  FGame.Discovered.Add(Rule('B'));
  Assert.IsTrue(FGame.IsResearched(TArray<string>.Create('A', 'B'), False));
end;

procedure TTestXcomResearchUnits.DovrebbeSommareIlPunteggioDelMeseCorrente;
begin
  FGame.AddResearchScore(50);
  FGame.AddResearchScore(25);
  Assert.AreEqual(75, FGame.ResearchScores[High(FGame.ResearchScores)]);
end;

procedure TTestXcomResearchUnits.DovrebbeOrdinareLeNuoveRicerchePerNomeEToglierePerEsistenti;
var
  LRules: TXcomResearchRules;
  LBefore, LAfter, LNew: TList<TXcomRuleResearch>;
  LB, LA, LC: TXcomRuleResearch;
begin
  LA := Rule('STR_A');
  LB := Rule('STR_B');
  LC := Rule('STR_C');
  LRules := TXcomResearchRules.Create(FGame, nil);
  LBefore := TList<TXcomRuleResearch>.Create;
  LAfter := TList<TXcomRuleResearch>.Create;
  try
    LBefore.Add(LB);
    LAfter.Add(LC);
    LAfter.Add(LB);
    LAfter.Add(LA);
    LNew := LRules.NewlyAvailable(LBefore, LAfter);
    try
      Assert.AreEqual(2, LNew.Count);
      Assert.AreEqual('STR_A', LNew[0].Name, 'per nome, come CompareRuleResearch');
      Assert.AreEqual('STR_C', LNew[1].Name);
    finally
      LNew.Free;
    end;
  finally
    LAfter.Free;
    LBefore.Free;
    LRules.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomResearchUnits);

end.
