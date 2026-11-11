{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library - the catalog on the    }
{  real rules of X-COM: Terror from the Deep (skipped without the data)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomUfopaedia.RealData;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.Tests.XcomGeoscape.World;

type
  [TestFixture]
  [Category('xcom-ufopaedia')]
  [Category('xcom-real-data')]
  TTestXcomUfopaediaRealData = class(TObject)
  strict private
    FWorld: TXcomGeoWorld;
    function Catalog(AEverythingResearched: Boolean): IXcomUfopaediaCatalog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeNoveSezioniDiTftdNellOrdineDeiPulsanti;
    [Test]
    procedure DovrebbeDareGliArticoliDellaPartitaNuova;
    [Test]
    procedure DovrebbeDareTuttiGliArticoliConOgniRicercaFatta;
    [Test]
    procedure DovrebbeAvereUnaClasseELaRegolaDescrittaPerOgniArticolo;
  end;

implementation

uses
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleUnit,
  DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.Catalog, DelphiDoom.XcomUfopaedia.Navigator;

procedure TTestXcomUfopaediaRealData.Setup;
begin
  FWorld := TXcomGeoWorld.Create;
end;

procedure TTestXcomUfopaediaRealData.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomUfopaediaRealData.Catalog(AEverythingResearched: Boolean): IXcomUfopaediaCatalog;
begin
  Result := TXcomUfopaediaCatalog.Create(FWorld.Rules.Ruleset,
    function(const ARequirements: TArray<string>): Boolean
    begin
      Result := AEverythingResearched or (Length(ARequirements) = 0);
    end);
end;

procedure TTestXcomUfopaediaRealData.DovrebbeDareLeNoveSezioniDiTftdNellOrdineDeiPulsanti;
begin
  if not FWorld.HasData then
    Exit;
  Assert.AreEqual(
    'STR_XCOM_CRAFT_ARMAMENT,STR_HEAVY_WEAPONS_PLATFORMS,STR_WEAPONS_AND_EQUIPMENT,STR_ALIEN_ARTIFACTS,' +
    'STR_BASE_FACILITIES,STR_ALIEN_LIFE_FORMS,STR_ALIEN_RESEARCH_UC,STR_UFO_COMPONENTS,STR_UFOS',
    string.Join(',', Catalog(False).Sections));
end;

procedure TTestXcomUfopaediaRealData.DovrebbeDareGliArticoliDellaPartitaNuova;
var
  LCatalog: IXcomUfopaediaCatalog;
  LArticles: TArray<TXcomArticleDefinition>;
  LId: string;
begin
  if not FWorld.HasData then
    Exit;
  LCatalog := Catalog(False);
  LArticles := LCatalog.AvailableArticles;
  // the first article of a new game is the first submarine
  Assert.AreEqual('STR_TRITON', LArticles[0].Id);
  Assert.AreEqual('STR_TRITON', LCatalog.List('STR_XCOM_CRAFT_ARMAMENT')[0].Id);
  // no alien submarine and no alien is known at the start
  Assert.AreEqual(0, Integer(Length(LCatalog.List('STR_UFOS'))));
  Assert.AreEqual(0, Integer(Length(LCatalog.List('STR_ALIEN_LIFE_FORMS'))));
  LId := 'STR_TRITON';
  Assert.AreEqual(0, LCatalog.ArticleIndex(LId));
end;

procedure TTestXcomUfopaediaRealData.DovrebbeDareTuttiGliArticoliConOgniRicercaFatta;
var
  LCatalog: IXcomUfopaediaCatalog;
  LSection: string;
  LTotal: Integer;
begin
  if not FWorld.HasData then
    Exit;
  LCatalog := Catalog(True);
  // 133 articles of ufopaedia.rul, 11 of them without a section (the ammunition)
  Assert.AreEqual(133, FWorld.Rules.Ruleset.Articles.Count);
  Assert.AreEqual(122, Integer(Length(LCatalog.AvailableArticles)));
  LTotal := 0;
  for LSection in LCatalog.Sections do
    Inc(LTotal, Length(LCatalog.List(LSection)));
  Assert.AreEqual(122, LTotal);
  Assert.AreEqual(8, Integer(Length(LCatalog.List('STR_UFOS'))));
end;

procedure TTestXcomUfopaediaRealData.DovrebbeAvereUnaClasseELaRegolaDescrittaPerOgniArticolo;
var
  LRules: TXcomRuleset;
  LArticle: TXcomArticleDefinition;
  LUnit: TXcomRuleUnit;
  LMissing: string;
begin
  if not FWorld.HasData then
    Exit;
  LRules := FWorld.Rules.Ruleset;
  LMissing := '';
  for LArticle in Catalog(True).AvailableArticles do
  begin
    if TXcomUfopaediaNavigator.StateClassOf(LArticle.Kind) = nil then
      LMissing := LMissing + LArticle.Id + ' (class) ';
    // the kinds of TFTD: 11 craft, 12 craft weapon, 13 vehicle, 14 item, 15 armor, 16 facility, 17 alien submarine
    case LArticle.Kind of
      11:
        if LRules.Crafts.Find(LArticle.Id) = nil then
          LMissing := LMissing + LArticle.Id + ' ';
      12:
        if LRules.CraftWeapons.Find(LArticle.Id) = nil then
          LMissing := LMissing + LArticle.Id + ' ';
      13:
        begin
          LUnit := LRules.Units.Find(LArticle.Id);
          if (LUnit = nil) or (LRules.Armors.Find(LUnit.Armor) = nil) or (LRules.Items.Find(LArticle.Id) = nil) then
            LMissing := LMissing + LArticle.Id + ' ';
        end;
      14:
        if LRules.Items.Find(LArticle.Id) = nil then
          LMissing := LMissing + LArticle.Id + ' ';
      15:
        if LRules.Armors.Find(LArticle.Id) = nil then
          LMissing := LMissing + LArticle.Id + ' ';
      16:
        if LRules.Facilities.Find(LArticle.Id) = nil then
          LMissing := LMissing + LArticle.Id + ' ';
      17:
        if LRules.Ufos.Find(LArticle.Id) = nil then
          LMissing := LMissing + LArticle.Id + ' ';
    end;
  end;
  Assert.AreEqual('', LMissing);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomUfopaediaRealData);

end.
