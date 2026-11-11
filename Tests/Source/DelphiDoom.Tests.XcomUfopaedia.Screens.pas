{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library - the screens and the   }
{  navigator on the fake game of the engine tests                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomUfopaedia.Screens;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomUfopaedia.Intf,
  DelphiDoom.XcomUfopaedia.Navigator, DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomUfopaedia.Fakes;

type
  [TestFixture]
  [Category('xcom-ufopaedia')]
  TTestXcomUfopaediaScreens = class(TObject)
  strict private
    FWorld: TTestWorld;
    FResources: TUfopaediaResources;
    FResourcesRef: IXcomResources;
    FRules: TXcomRuleset;
    FResearched: TList<string>;
    FSprites: TXcomSurfaceSet;
    FCatalog: IXcomUfopaediaCatalog;
    FNavigatorObject: TXcomUfopaediaNavigator;
    FNavigator: IXcomUfopaediaNavigator;
    FFake: TFakeUfopaediaNavigator;
    FFakeRef: IXcomUfopaediaNavigator;
    procedure ClickBase(AX, AY: Integer);
    function TopId: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMostrareUnPulsantePerSezioneEAprireLaSezioneCliccata;
    [Test]
    procedure DovrebbeChiudereLaSchermataInizialeConOk;
    [Test]
    procedure DovrebbeMostrareAlMassimoDieciSezioniEScorrereFinoInFondo;
    [Test]
    procedure DovrebbeElencareITitoliDellaSezioneEAprireLArticoloCliccato;
    [Test]
    procedure DovrebbeAprireLaSchermataInizialeELaSezioneDalNavigatore;
    [Test]
    procedure DovrebbeAprireUnArticoloDisponibilePerId;
    [Test]
    procedure DovrebbeNonAprireUnArticoloNonDisponibile;
    [Test]
    procedure DovrebbeAprireLArticoloDellaRicercaRichiesta;
    [Test]
    procedure DovrebbePassareDallUltimoAlPrimoEDalPrimoAllUltimo;
    [Test]
    procedure DovrebbeMostrareOgniTipoDiArticoloScorrendoliTutti;
    [Test]
    procedure DovrebbeAndareAvantiEIndietroConIPulsantiDellArticolo;
    [Test]
    procedure DovrebbeChiudereLArticoloConOk;
    [Test]
    procedure DovrebbeCercareLImmagineDellaCorazzaInTreNomi;
    [Test]
    procedure DovrebbeSollevareErroreSeLaRegolaDellArticoloManca;
    [Test]
    [TestCase('craft', '1,TXcomArticleStateCraft')]
    [TestCase('arma del velivolo', '2,TXcomArticleStateCraftWeapon')]
    [TestCase('veicolo', '3,TXcomArticleStateVehicle')]
    [TestCase('oggetto', '4,TXcomArticleStateItem')]
    [TestCase('corazza', '5,TXcomArticleStateArmor')]
    [TestCase('struttura', '6,TXcomArticleStateBaseFacility')]
    [TestCase('testo e immagine', '7,TXcomArticleStateTextImage')]
    [TestCase('testo', '8,TXcomArticleStateText')]
    [TestCase('ufo', '9,TXcomArticleStateUfo')]
    [TestCase('tftd', '10,TXcomArticleStateTftd')]
    [TestCase('tftd craft', '11,TXcomArticleStateTftdCraft')]
    [TestCase('tftd arma del velivolo', '12,TXcomArticleStateTftdCraftWeapon')]
    [TestCase('tftd veicolo', '13,TXcomArticleStateTftdVehicle')]
    [TestCase('tftd oggetto', '14,TXcomArticleStateTftdItem')]
    [TestCase('tftd corazza', '15,TXcomArticleStateTftdArmor')]
    [TestCase('tftd struttura', '16,TXcomArticleStateTftdFacility')]
    [TestCase('tftd uso', '17,TXcomArticleStateTftdUso')]
    procedure DovrebbeScegliereLaClasseDelloStatoDalTipo(AKind: Integer; const AClassName: string);
    [Test]
    procedure DovrebbeDareNilPerUnTipoSenzaClasse;
  end;

implementation

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.Catalog,
  DelphiDoom.XcomUfopaedia.StartState, DelphiDoom.XcomUfopaedia.SelectState,
  DelphiDoom.XcomUfopaedia.ArticleState, DelphiDoom.XcomUfopaedia.ArticleStateCraft,
  DelphiDoom.XcomUfopaedia.ArticleStateCraftWeapon, DelphiDoom.XcomUfopaedia.ArticleStateText,
  DelphiDoom.XcomUfopaedia.ArticleStateTftdFacility;

const
  // the popup of a window takes 200 ms of clock; a frame every 17
  POPUP_WAIT = 400;
  ALL_ARTICLES: array[0..16] of string = ('STR_SHIP', 'STR_CANNON', 'STR_HIDDEN', 'STR_TANK', 'STR_RIFLE',
    'STR_SUIT', 'STR_LAB', 'STR_PICTURE', 'STR_SCOUT', 'STR_ALIEN_UC', 'STR_SHIP_TFTD', 'STR_TORPEDO',
    'STR_AQUA_SUIT', 'STR_SUB', 'STR_LASER_TANK', 'STR_GRENADE', 'STR_DEFENSE');

procedure TTestXcomUfopaediaScreens.Setup;
var
  LResearched: TList<string>;
  LSprites: TXcomSurfaceSet;
  LIndex: Integer;
begin
  FWorld := TTestWorld.Create;
  FResources := TUfopaediaResources.Create(FWorld.Game.Resources);
  FResourcesRef := FResources;
  FWorld.Game.AdoptData(FResourcesRef, nil);
  FRules := TUfopaediaTestRules.Standard;
  FResearched := TList<string>.Create;
  FSprites := TXcomSurfaceSet.Create(32, 48);
  for LIndex := 0 to 15 do
    FSprites.AddFrame(LIndex);
  LResearched := FResearched;
  LSprites := FSprites;
  FCatalog := TXcomUfopaediaCatalog.Create(FRules,
    function(const ARequirements: TArray<string>): Boolean
    var
      LName: string;
    begin
      for LName in ARequirements do
        if not LResearched.Contains(LName) then
          Exit(False);
      Result := True;
    end,
    function(const AName: string): TXcomSurfaceSet
    begin
      Result := LSprites;
    end);
  FNavigatorObject := TXcomUfopaediaNavigator.Create(FWorld.Game, FCatalog);
  FNavigator := FNavigatorObject;
  FFake := TFakeUfopaediaNavigator.Create;
  FFakeRef := FFake;
end;

procedure TTestXcomUfopaediaScreens.TearDown;
begin
  // the states hold the navigator and the catalog: the game goes first
  FWorld.Free;
  FFakeRef := nil;
  FNavigator := nil;
  FCatalog := nil;
  FResourcesRef := nil;
  FSprites.Free;
  FResearched.Free;
  FRules.Free;
end;

procedure TTestXcomUfopaediaScreens.ClickBase(AX, AY: Integer);
begin
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

function TTestXcomUfopaediaScreens.TopId: string;
begin
  Result := (FWorld.Game.TopState as TXcomArticleState).Id;
end;

procedure TTestXcomUfopaediaScreens.DovrebbeMostrareUnPulsantePerSezioneEAprireLaSezioneCliccata;
var
  LState: TXcomUfopaediaStartState;
begin
  LState := TXcomUfopaediaStartState.Create(FWorld.Game, FFakeRef, FCatalog.Sections);
  FWorld.Game.PushState(LState);
  FWorld.Wait(POPUP_WAIT);
  Assert.AreEqual(3, LState.ButtonCount);
  Assert.AreEqual('STR_SECTION_B', LState.ButtonSection(1));
  // nine buttons or fewer start at 50, one every 13
  ClickBase(160, 50 + 13 + 6);
  Assert.AreEqual('section:STR_SECTION_B', string.Join(',', FFake.Calls.ToArray));
end;

procedure TTestXcomUfopaediaScreens.DovrebbeChiudereLaSchermataInizialeConOk;
var
  LState: TXcomState;
begin
  LState := TXcomUfopaediaStartState.Create(FWorld.Game, FFakeRef, FCatalog.Sections);
  FWorld.Game.PushState(LState);
  FWorld.Wait(POPUP_WAIT);
  ClickBase(160, 167 + 6);
  FWorld.Wait(40);
  Assert.AreNotSame(LState, FWorld.Game.TopState);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeMostrareAlMassimoDieciSezioniEScorrereFinoInFondo;
var
  LState: TXcomUfopaediaStartState;
  LSections: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LSections, 12);
  for LIndex := 0 to 11 do
    LSections[LIndex] := 'STR_S' + IntToStr(LIndex);
  LState := TXcomUfopaediaStartState.Create(FWorld.Game, FFakeRef, LSections);
  FWorld.Game.PushState(LState);
  FWorld.Wait(POPUP_WAIT);
  Assert.AreEqual(10, LState.ButtonCount);
  Assert.AreEqual(0, LState.Offset);
  // the arrow down, held: the timer scrolls every 50 ms and stops at the last ten
  FWorld.ClickHeld(Round(276 * FWorld.Game.Screen.XScale), Round(159 * FWorld.Game.Screen.YScale), 400);
  Assert.AreEqual(2, LState.Offset);
  Assert.AreEqual('STR_S2', LState.ButtonSection(0));
  // the tenth button moved all of them up by 13: the first is at 37
  ClickBase(160, 37 + 6);
  Assert.AreEqual('section:STR_S2', string.Join(',', FFake.Calls.ToArray));
  // and up again, to the top
  FWorld.ClickHeld(Round(276 * FWorld.Game.Screen.XScale), Round(44 * FWorld.Game.Screen.YScale), 400);
  Assert.AreEqual(0, LState.Offset);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeElencareITitoliDellaSezioneEAprireLArticoloCliccato;
var
  LState: TXcomUfopaediaSelectState;
begin
  LState := TXcomUfopaediaSelectState.Create(FWorld.Game, FFakeRef, FCatalog.List('STR_SECTION_A'));
  FWorld.Game.PushState(LState);
  FWorld.Wait(100);
  Assert.AreEqual(2, LState.List.GetRows);
  Assert.AreEqual('STR_CANNON', LState.List.GetCellText(1, 0));
  // the list starts at 50 and a row of the small font is 8 pixels tall
  ClickBase(160, 50 + 8 + 4);
  Assert.AreEqual('article:STR_CANNON', string.Join(',', FFake.Calls.ToArray));
end;

procedure TTestXcomUfopaediaScreens.DovrebbeAprireLaSchermataInizialeELaSezioneDalNavigatore;
begin
  FNavigator.Open;
  Assert.IsTrue(FWorld.Game.TopState is TXcomUfopaediaStartState);
  FNavigator.OpenSection('STR_SECTION_B');
  Assert.IsTrue(FWorld.Game.TopState is TXcomUfopaediaSelectState);
  Assert.AreEqual(6, (FWorld.Game.TopState as TXcomUfopaediaSelectState).List.GetRows);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeAprireUnArticoloDisponibilePerId;
begin
  FNavigator.OpenArticle('STR_CANNON');
  Assert.IsTrue(FWorld.Game.TopState is TXcomArticleStateCraftWeapon);
  Assert.AreEqual('STR_CANNON', TopId);
  Assert.AreEqual(1, FNavigatorObject.CurrentIndex);
  FWorld.Wait(40);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeNonAprireUnArticoloNonDisponibile;
var
  LBefore: TXcomState;
begin
  // a screen under the article: the game has no top state when it is empty
  FNavigator.Open;
  LBefore := FWorld.Game.TopState;
  FNavigator.OpenArticle('STR_HIDDEN');
  Assert.AreSame(LBefore, FWorld.Game.TopState);
  Assert.AreEqual(-1, FNavigatorObject.CurrentIndex);
  FNavigator.OpenArticle(FRules.Articles.Find('STR_HIDDEN'));
  Assert.AreSame(LBefore, FWorld.Game.TopState);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeAprireLArticoloDellaRicercaRichiesta;
begin
  FResearched.Add('STR_SECRET');
  FNavigator.OpenArticle('STR_SECRET');
  Assert.IsTrue(FWorld.Game.TopState is TXcomArticleStateText);
  Assert.AreEqual('STR_HIDDEN', TopId);
end;

procedure TTestXcomUfopaediaScreens.DovrebbePassareDallUltimoAlPrimoEDalPrimoAllUltimo;
begin
  FNavigator.OpenArticle('STR_DEFENSE');
  Assert.AreEqual(14, FNavigatorObject.CurrentIndex);
  FNavigator.Next;
  Assert.IsTrue(FWorld.Game.TopState is TXcomArticleStateCraft);
  Assert.AreEqual('STR_SHIP', TopId);
  FNavigator.Prev;
  Assert.IsTrue(FWorld.Game.TopState is TXcomArticleStateTftdFacility);
  Assert.AreEqual('STR_DEFENSE', TopId);
  FWorld.Wait(40);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeMostrareOgniTipoDiArticoloScorrendoliTutti;
var
  LIndex: Integer;
  LClasses: TList<TClass>;
begin
  FResearched.Add('STR_SECRET');
  FResearched.Add('STR_ALIEN');
  LClasses := TList<TClass>.Create;
  try
    FNavigator.OpenArticle(ALL_ARTICLES[0]);
    for LIndex := 0 to High(ALL_ARTICLES) do
    begin
      Assert.AreEqual(ALL_ARTICLES[LIndex], TopId);
      if not LClasses.Contains(FWorld.Game.TopState.ClassType) then
        LClasses.Add(FWorld.Game.TopState.ClassType);
      // the article is drawn (and the one before is freed)
      FWorld.Wait(40);
      FNavigator.Next;
    end;
    // after the last one the first again
    Assert.AreEqual(ALL_ARTICLES[0], TopId);
    // 17 articles of 17 kinds: a class for each
    Assert.AreEqual(17, LClasses.Count);
  finally
    LClasses.Free;
  end;
end;

procedure TTestXcomUfopaediaScreens.DovrebbeAndareAvantiEIndietroConIPulsantiDellArticolo;
var
  LState: TXcomArticleState;
begin
  LState := TXcomArticleStateText.Create(FWorld.Game, FFakeRef, FCatalog, FRules.Articles.Find('STR_HIDDEN'));
  FWorld.Game.PushState(LState);
  FWorld.Wait(40);
  // the buttons of the UFO articles: previous at 40, next at 75, 30 x 14 at the top
  ClickBase(75 + 15, 5 + 7);
  ClickBase(40 + 15, 5 + 7);
  Assert.AreEqual('next,prev', string.Join(',', FFake.Calls.ToArray));
end;

procedure TTestXcomUfopaediaScreens.DovrebbeChiudereLArticoloConOk;
var
  LState: TXcomState;
begin
  LState := TXcomArticleStateText.Create(FWorld.Game, FFakeRef, FCatalog, FRules.Articles.Find('STR_HIDDEN'));
  FWorld.Game.PushState(LState);
  FWorld.Wait(40);
  ClickBase(5 + 15, 5 + 7);
  FWorld.Wait(40);
  Assert.AreNotSame(LState, FWorld.Game.TopState);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeCercareLImmagineDellaCorazzaInTreNomi;
begin
  FResources.Missing.Add('SUITM0.SPK');
  FResources.Missing.Add('SUIT.SPK');
  FNavigator.OpenArticle('STR_SUIT');
  Assert.AreEqual('SUITM0.SPK,SUIT.SPK,SUIT', string.Join(',', FResources.Asked.ToArray));
end;

procedure TTestXcomUfopaediaScreens.DovrebbeSollevareErroreSeLaRegolaDellArticoloManca;
var
  LRules: TXcomRuleset;
  LCatalog: IXcomUfopaediaCatalog;
  LNavigator: IXcomUfopaediaNavigator;
  LBefore: TXcomState;
begin
  LRules := TUfopaediaTestRules.Load(
    'ufopaedia:'#10'  - id: STR_GHOST'#10'    type_id: 1'#10'    section: STR_SECTION_A'#10'    image_id: X.SPK'#10);
  try
    LCatalog := TXcomUfopaediaCatalog.Create(LRules,
      function(const ARequirements: TArray<string>): Boolean
      begin
        Result := True;
      end);
    LNavigator := TXcomUfopaediaNavigator.Create(FWorld.Game, LCatalog);
    FNavigator.Open;
    LBefore := FWorld.Game.TopState;
    Assert.WillRaise(
      procedure
      begin
        LNavigator.OpenArticle('STR_GHOST');
      end, EXcomUfopaediaException);
    Assert.AreSame(LBefore, FWorld.Game.TopState);
    LNavigator := nil;
    LCatalog := nil;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomUfopaediaScreens.DovrebbeScegliereLaClasseDelloStatoDalTipo(AKind: Integer;
  const AClassName: string);
begin
  Assert.AreEqual(AClassName, TXcomUfopaediaNavigator.StateClassOf(AKind).ClassName);
end;

procedure TTestXcomUfopaediaScreens.DovrebbeDareNilPerUnTipoSenzaClasse;
begin
  Assert.IsNull(TXcomUfopaediaNavigator.StateClassOf(0));
  Assert.IsNull(TXcomUfopaediaNavigator.StateClassOf(18));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomUfopaediaScreens);

end.
