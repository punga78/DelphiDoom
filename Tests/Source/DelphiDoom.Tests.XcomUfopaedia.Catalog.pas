{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library - the available         }
{  articles (TXcomUfopaediaCatalog)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomUfopaedia.Catalog;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomUfopaedia.Intf;

type
  [TestFixture]
  [Category('xcom-ufopaedia')]
  TTestXcomUfopaediaCatalog = class(TObject)
  strict private
    FRules: TXcomRuleset;
    FResearched: TList<string>;
    FCatalog: IXcomUfopaediaCatalog;
    function Ids(const AArticles: TArray<TXcomArticleDefinition>): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeSezioniNellOrdineDeiPulsantiSenzaQuellaNonDisponibile;
    [Test]
    procedure DovrebbeDareGliArticoliSenzaRicercaNellOrdineDelleRegole;
    [Test]
    procedure DovrebbeAggiungereUnArticoloQuandoLaSuaRicercaEFatta;
    [Test]
    procedure DovrebbeDareGliArticoliDiUnaSezione;
    [Test]
    procedure DovrebbeDareUnElencoVuotoPerUnaSezioneSconosciutaOPerQuellaNonDisponibile;
    [Test]
    procedure DovrebbeDireCheUnArticoloNascostoNonEDisponibile;
    [Test]
    procedure DovrebbeTrovareLIndiceDiUnArticoloPerId;
    [Test]
    procedure DovrebbeTrovareLArticoloConIlSuffissoUcECambiareLId;
    [Test]
    procedure DovrebbeTrovareLArticoloDallaRicercaCheRichiedeECambiareLId;
    [Test]
    procedure DovrebbeDareMenoUnoELasciareLIdPerUnArticoloNonDisponibile;
    [Test]
    procedure DovrebbeDareMenoUnoPerUnArticoloSenzaSezione;
    [Test]
    [TestCase('in mezzo', '3,10,4')]
    [TestCase('ultimo torna al primo', '9,10,0')]
    [TestCase('oltre la fine torna al primo', '12,10,0')]
    [TestCase('uno solo', '0,1,0')]
    procedure DovrebbeDareLIndiceSuccessivo(ACurrent, ACount, AExpected: Integer);
    [Test]
    [TestCase('in mezzo', '3,10,2')]
    [TestCase('primo torna all''ultimo', '0,10,9')]
    [TestCase('uno solo', '0,1,0')]
    procedure DovrebbeDareLIndicePrecedente(ACurrent, ACount, AExpected: Integer);
    [Test]
    procedure DovrebbeSollevareErroreSeNonCiSonoArticoli;
    [Test]
    procedure DovrebbeDareNilSenzaSorgenteDiSprite;
    [Test]
    procedure DovrebbeChiedereGliSpriteAllaSorgente;
  end;

implementation

uses
  DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.Catalog, DelphiDoom.Tests.XcomUfopaedia.Fakes;

const
  AVAILABLE_AT_START = 'STR_SHIP,STR_CANNON,STR_TANK,STR_RIFLE,STR_SUIT,STR_LAB,STR_PICTURE,STR_SCOUT,' +
    'STR_SHIP_TFTD,STR_TORPEDO,STR_AQUA_SUIT,STR_SUB,STR_LASER_TANK,STR_GRENADE,STR_DEFENSE';

procedure TTestXcomUfopaediaCatalog.Setup;
var
  LResearched: TList<string>;
begin
  FRules := TUfopaediaTestRules.Standard;
  FResearched := TList<string>.Create;
  // the closure holds the list, not the fixture
  LResearched := FResearched;
  FCatalog := TXcomUfopaediaCatalog.Create(FRules,
    function(const ARequirements: TArray<string>): Boolean
    var
      LName: string;
    begin
      for LName in ARequirements do
        if not LResearched.Contains(LName) then
          Exit(False);
      Result := True;
    end);
end;

procedure TTestXcomUfopaediaCatalog.TearDown;
begin
  FCatalog := nil;
  FResearched.Free;
  FRules.Free;
end;

function TTestXcomUfopaediaCatalog.Ids(const AArticles: TArray<TXcomArticleDefinition>): string;
var
  LArticle: TXcomArticleDefinition;
begin
  Result := '';
  for LArticle in AArticles do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LArticle.Id;
  end;
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareLeSezioniNellOrdineDeiPulsantiSenzaQuellaNonDisponibile;
begin
  Assert.AreEqual('STR_SECTION_A,STR_SECTION_B,STR_SECTION_C', string.Join(',', FCatalog.Sections));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareGliArticoliSenzaRicercaNellOrdineDelleRegole;
begin
  Assert.AreEqual(AVAILABLE_AT_START, Ids(FCatalog.AvailableArticles));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeAggiungereUnArticoloQuandoLaSuaRicercaEFatta;
var
  LArticles: TArray<TXcomArticleDefinition>;
begin
  FResearched.Add('STR_SECRET');
  LArticles := FCatalog.AvailableArticles;
  Assert.AreEqual(16, Integer(Length(LArticles)));
  Assert.AreEqual('STR_HIDDEN', LArticles[2].Id);
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareGliArticoliDiUnaSezione;
begin
  Assert.AreEqual('STR_SHIP,STR_CANNON', Ids(FCatalog.List('STR_SECTION_A')));
  Assert.AreEqual('STR_TANK,STR_RIFLE,STR_SUIT,STR_LAB,STR_PICTURE,STR_SCOUT', Ids(FCatalog.List('STR_SECTION_B')));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareUnElencoVuotoPerUnaSezioneSconosciutaOPerQuellaNonDisponibile;
begin
  Assert.AreEqual(0, Integer(Length(FCatalog.List('STR_NESSUNA'))));
  Assert.AreEqual(0, Integer(Length(FCatalog.List(UFOPAEDIA_NOT_AVAILABLE))));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDireCheUnArticoloNascostoNonEDisponibile;
begin
  Assert.IsFalse(FCatalog.IsArticleAvailable(FRules.Articles.Find('STR_HIDDEN')));
  Assert.IsTrue(FCatalog.IsArticleAvailable(FRules.Articles.Find('STR_RIFLE_CLIP')));
  FResearched.Add('STR_SECRET');
  Assert.IsTrue(FCatalog.IsArticleAvailable(FRules.Articles.Find('STR_HIDDEN')));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeTrovareLIndiceDiUnArticoloPerId;
var
  LId: string;
begin
  LId := 'STR_CANNON';
  Assert.AreEqual(1, FCatalog.ArticleIndex(LId));
  Assert.AreEqual('STR_CANNON', LId);
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeTrovareLArticoloConIlSuffissoUcECambiareLId;
var
  LId: string;
begin
  FResearched.Add('STR_ALIEN');
  LId := 'STR_ALIEN';
  Assert.AreEqual(8, FCatalog.ArticleIndex(LId));
  Assert.AreEqual('STR_ALIEN_UC', LId);
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeTrovareLArticoloDallaRicercaCheRichiedeECambiareLId;
var
  LId: string;
begin
  FResearched.Add('STR_SECRET');
  LId := 'STR_SECRET';
  Assert.AreEqual(2, FCatalog.ArticleIndex(LId));
  Assert.AreEqual('STR_HIDDEN', LId);
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareMenoUnoELasciareLIdPerUnArticoloNonDisponibile;
var
  LId: string;
begin
  LId := 'STR_HIDDEN';
  Assert.AreEqual(-1, FCatalog.ArticleIndex(LId));
  Assert.AreEqual('STR_HIDDEN', LId);
  LId := 'STR_NON_ESISTE';
  Assert.AreEqual(-1, FCatalog.ArticleIndex(LId));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareMenoUnoPerUnArticoloSenzaSezione;
var
  LId: string;
begin
  LId := 'STR_RIFLE_CLIP';
  Assert.AreEqual(-1, FCatalog.ArticleIndex(LId));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareLIndiceSuccessivo(ACurrent, ACount, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TXcomUfopaediaCatalog.NextIndex(ACurrent, ACount));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareLIndicePrecedente(ACurrent, ACount, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TXcomUfopaediaCatalog.PreviousIndex(ACurrent, ACount));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeSollevareErroreSeNonCiSonoArticoli;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomUfopaediaCatalog.NextIndex(0, 0);
    end, EXcomUfopaediaException);
  Assert.WillRaise(
    procedure
    begin
      TXcomUfopaediaCatalog.PreviousIndex(0, 0);
    end, EXcomUfopaediaException);
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeDareNilSenzaSorgenteDiSprite;
begin
  Assert.IsNull(FCatalog.Sprites('BASEBITS.PCK'));
end;

procedure TTestXcomUfopaediaCatalog.DovrebbeChiedereGliSpriteAllaSorgente;
var
  LSet: TXcomSurfaceSet;
  LCatalog: IXcomUfopaediaCatalog;
  LAsked: string;
begin
  LSet := TXcomSurfaceSet.Create(32, 40);
  try
    LAsked := '';
    LCatalog := TXcomUfopaediaCatalog.Create(FRules,
      function(const ARequirements: TArray<string>): Boolean
      begin
        Result := True;
      end,
      function(const AName: string): TXcomSurfaceSet
      begin
        LAsked := AName;
        Result := LSet;
      end);
    Assert.AreSame(LSet, LCatalog.Sprites('BIGOBS.PCK'));
    Assert.AreEqual('BIGOBS.PCK', LAsked);
    LCatalog := nil;
  finally
    LSet.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomUfopaediaCatalog);

end.
