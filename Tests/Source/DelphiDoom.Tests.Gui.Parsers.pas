{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the parsers and the file readers     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Parsers;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Tests.Gui.Fakes;

type
  [TestFixture]
  [Category('gui')]
  TTestGuiItemParser = class(TObject)
  private
    FWorld: TGuiWorld;
    function FirstItem: TGuiItem;
    procedure ParseItem(const AItemText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeTrovareLeParolaChiaveSenzaMaiuscole;
    [Test]
    procedure DovrebbeSegnalareEContinuareSuUnaParolaChiaveSconosciuta;
    [Test]
    procedure DovrebbeFermarsiSuUnaParolaChiaveCheNonSiLegge;
    [Test]
    procedure DovrebbeSegnalareLaFineDelFileDentroUnItem;
    [Test]
    procedure DovrebbeFareIDatiDelTipoDopoLaParolaType;
    [Test]
    procedure DovrebbeFareIDatiDelCampoPerLeParoleCheLiVogliono;
    [Test]
    procedure DovrebbeMettereIlCvarDelCampoA_1;
    [Test]
    procedure DovrebbeLeggereLeListeDiStringheEDiNumeri;
    [Test]
    procedure DovrebbeFermarsiAlTrentaduesimoElementoDiUnaLista;
    [Test]
    procedure DovrebbeFermarsiAlTrentaduesimoElementoDiUnaListaDiNumeri;
    [Test]
    procedure DovrebbeTenereAl10IIntervalliDiColore;
    [Test]
    procedure DovrebbeLimitareLeColonneA16;
    [Test]
    procedure DovrebbeSegnareIlTipoOwnerDraw;
    [Test]
    procedure DovrebbeScartareUnItemConUnColoreAMeta;
    [Test]
    procedure DovrebbeUsareLAngoloCasualeDelModello;
    [Test]
    procedure DovrebbeUsareAngolo0SenzaGeneratore;
    [Test]
    procedure DovrebbeLasciareLAngoloDelModelloSeSiDa;
    [Test]
    procedure DovrebbeRifiutareLeParoleDelListboxSuUnItemSenzaListbox;
    [Test]
    procedure DovrebbeRifiutareLeParoleDelModelloSuUnItemSenzaModello;
    [Test]
    procedure DovrebbeRifiutareLeParoleDelCampoSuUnItemSenzaCampo;
    [Test]
    procedure DovrebbeRifiutareLeListeSuUnItemSenzaDatiMulti;
    [Test]
    procedure DovrebbeLeggereSenzaMemorizzareLeParoleDiUnAltroTipoDiDati;
    [Test]
    procedure DovrebbeSegnareLeAzioniDelCvar;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiMenuParser = class(TObject)
  private
    FWorld: TGuiWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLeParoleChiaveDelMenu;
    [Test]
    procedure DovrebbeSegnareIlColoreDelPrimoPianoDelMenu;
    [Test]
    procedure DovrebbeSegnalareUnaParolaChiaveSconosciutaEContinuare;
    [Test]
    procedure DovrebbeLeggereUnItemEMetterloNelMenu;
    [Test]
    procedure DovrebbeScartareUnItemChePerdeUnaParola;
    [Test]
    procedure DovrebbeLeggereLeParoleDelMenuDentroUnItemSuperiorePerLimite;
    [Test]
    procedure DovrebbeRegistrareIlFontUnaVoltaSola;
    [Test]
    procedure DovrebbeNonRegistrareIlFontSeGiaRegistrato;
    [Test]
    procedure DovrebbeLeggereLeStringheComeNullaSeIlPoolEPieno;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiAssetParser = class(TObject)
  private
    FWorld: TGuiWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIValoriDegliAsset;
    [Test]
    procedure DovrebbeSaltareLeParoleChiaveSconosciute;
    [Test]
    procedure DovrebbeFermarsiSuUnFontSenzaGrandezza;
    [Test]
    procedure DovrebbeFermarsiSuUnaParolaChiaveSenzaValore;
    [Test]
    procedure DovrebbeImpostareIlLimiteDellOmbraDalColore;
    [Test]
    procedure DovrebbeRegistrareISuoniEIlCursore;
    [Test]
    procedure DovrebbeRegistrareITreFont;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiMenuFileReader = class(TObject)
  private
    FWorld: TGuiWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareFalsoPerUnFileMancanteSenzaFermarsi;
    [Test]
    procedure DovrebbeScrivereIlNomeDelFileCheLegge;
    [Test]
    procedure DovrebbeFermarsiAlPrimoMenuCheFallisce;
    [Test]
    procedure DovrebbeLeggereLaListaDeiFile;
    [Test]
    procedure DovrebbeFermarsiAllaListaSeUnLoadmenuNonSiLegge;
    [Test]
    procedure DovrebbeUsareLaListaDiPredefinitaSeMancaQuellaChiesta;
    [Test]
    procedure DovrebbeSollevareSeMancaAncheLaListaDiPredefinita;
    [Test]
    procedure DovrebbeDimenticareIMenuSeSiChiedeIlReset;
    [Test]
    procedure DovrebbeTenereIMenuSeNonSiChiedeIlReset;
    [Test]
    procedure DovrebbeLeggereUnFileCheIncludeUnAltro;
    [Test]
    procedure DovrebbeSegnalareUnIncludeCheNonCE;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiPrecompilerSource = class(TObject)
  public
    [Test]
    procedure DovrebbeDareITipiEIValoriDeiToken;
    [Test]
    procedure DovrebbeDareLeStringheSenzaVirgolette;
    [Test]
    procedure DovrebbeDareNomeDelFileERiga;
    [Test]
    procedure DovrebbeDareNilPerUnFileMancante;
    [Test]
    procedure DovrebbeEspandereIDefineConParametri;
    [Test]
    procedure DovrebbeInoltrareIMessaggiDelLexerAlLog;
    [Test]
    procedure DovrebbeNonFallireSenzaLog;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeDareFileERigaNellEccezioneDiSintassi;
    [Test]
    procedure DovrebbeDareIlNomeDelFileNellEccezioneDiFileMancante;
    [Test]
    procedure DovrebbeFareUnaFinestraComeWindow_Init;
  end;

implementation

uses
  System.Classes, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Factory, DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.MenuFileReader,
  DelphiDoom.Gui.Font.Types, DelphiDoom.Gui.PrecompilerSource, DelphiDoom.Gui.IdLibLog, DelphiDoom.IdLib.Core.Intf;

{ TTestGuiItemParser }

procedure TTestGuiItemParser.Setup;
begin
  FWorld := TGuiWorld.Create;
end;

procedure TTestGuiItemParser.TearDown;
begin
  FWorld.Free;
end;

function TTestGuiItemParser.FirstItem: TGuiItem;
begin
  Result := FWorld.Menus[0].Items[0];
end;

procedure TTestGuiItemParser.ParseItem(const AItemText: AnsiString);
begin
  FWorld.ParseMenuText('menuDef { name "m" itemDef { ' + AItemText + ' } }');
end;

procedure TTestGuiItemParser.DovrebbeTrovareLeParolaChiaveSenzaMaiuscole;
begin
  ParseItem('NAME "x" TextScale 2 ONFOCUS { a }');
  Assert.AreEqual('x', string(FirstItem.Window.Name));
  Assert.AreEqual(Single(2), FirstItem.TextScale);
  Assert.AreEqual('a ', string(FirstItem.OnFocus));
end;

procedure TTestGuiItemParser.DovrebbeSegnalareEContinuareSuUnaParolaChiaveSconosciuta;
begin
  ParseItem('bogus name "x"');
  Assert.AreEqual('x', string(FirstItem.Window.Name));
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: unknown menu item keyword bogus', FWorld.Transcript[1]);
end;

procedure TTestGuiItemParser.DovrebbeFermarsiSuUnaParolaChiaveCheNonSiLegge;
begin
  ParseItem('rect 1 2 x 4');
  Assert.AreEqual(0, FWorld.Menus.Count);
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: couldn''t parse menu item keyword rect', FWorld.Transcript[2]);
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: couldn''t parse menu keyword itemDef', FWorld.Transcript[3]);
end;

procedure TTestGuiItemParser.DovrebbeSegnalareLaFineDelFileDentroUnItem;
begin
  FWorld.ParseMenuText('menuDef { itemDef { name "x"');
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: end of file inside menu item', FWorld.Transcript[1]);
end;

procedure TTestGuiItemParser.DovrebbeFareIDatiDelTipoDopoLaParolaType;
begin
  ParseItem('type 6');
  Assert.IsTrue(FirstItem.DataKind = gdkListBox);
  Assert.AreEqual(6, FirstItem.ItemType);
end;

procedure TTestGuiItemParser.DovrebbeFareIDatiDelCampoPerLeParoleCheLiVogliono;
begin
  ParseItem('type 4 maxChars 12 maxPaintChars 8 cvarFloat "c" 1 2 3');
  Assert.AreEqual(12, FirstItem.EditField.MaxChars);
  Assert.AreEqual(8, FirstItem.EditField.MaxPaintChars);
  Assert.AreEqual('c', string(FirstItem.Cvar));
  Assert.AreEqual(Single(1), FirstItem.EditField.DefVal);
  Assert.AreEqual(Single(2), FirstItem.EditField.MinVal);
  Assert.AreEqual(Single(3), FirstItem.EditField.MaxVal);
end;

procedure TTestGuiItemParser.DovrebbeMettereIlCvarDelCampoA_1;
begin
  ParseItem('type 4 cvar "ui_x"');
  Assert.AreEqual(Single(-1), FirstItem.EditField.MinVal);
  Assert.AreEqual(Single(-1), FirstItem.EditField.MaxVal);
  Assert.AreEqual(Single(-1), FirstItem.EditField.DefVal);
end;

procedure TTestGuiItemParser.DovrebbeLeggereLeListeDiStringheEDiNumeri;
begin
  ParseItem('type 12 cvarStrList { "a", "1" ; b 2 }');
  Assert.AreEqual(2, FirstItem.Multi.Count);
  Assert.IsTrue(FirstItem.Multi.StrDef);
  Assert.AreEqual('b', string(FirstItem.Multi.CvarList[1]));
  Assert.AreEqual('2', string(FirstItem.Multi.CvarStr[1]));
  FWorld.Menus.Reset;
  ParseItem('type 12 cvarFloatList { x 1.5 y -2 }');
  Assert.AreEqual(2, FirstItem.Multi.Count);
  Assert.IsFalse(FirstItem.Multi.StrDef);
  Assert.AreEqual(Single(-2), FirstItem.Multi.CvarValue[1]);
end;

procedure TTestGuiItemParser.DovrebbeFermarsiAlTrentaduesimoElementoDiUnaLista;
var
  LText: string;
  LIndex: Integer;
begin
  LText := 'type 12 cvarStrList {';
  for LIndex := 1 to 33 do
    LText := LText + ' a b';
  LText := LText + ' }';
  ParseItem(AnsiString(LText));
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeFermarsiAlTrentaduesimoElementoDiUnaListaDiNumeri;
var
  LText: string;
  LIndex: Integer;
begin
  LText := 'type 12 cvarFloatList {';
  for LIndex := 1 to 33 do
    LText := LText + ' a 1';
  LText := LText + ' }';
  ParseItem(AnsiString(LText));
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeTenereAl10IIntervalliDiColore;
var
  LText: string;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 1 to 12 do
    LText := LText + Format(' addColorRange %d 20 1 1 1 1', [LIndex]);
  ParseItem(AnsiString(LText));
  Assert.AreEqual(10, FirstItem.NumColors);
  Assert.AreEqual(Single(10), FirstItem.ColorRanges[9].Low);
end;

procedure TTestGuiItemParser.DovrebbeLimitareLeColonneA16;
begin
  ParseItem('type 6 columns 17 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8 9 9 9 10 10 10 11 11 11 12 12 12 13 13 13 ' +
    '14 14 14 15 15 15 16 16 16');
  Assert.AreEqual(16, FirstItem.ListBox.NumColumns);
  Assert.AreEqual(16, FirstItem.ListBox.ColumnInfo[15].Pos);
end;

procedure TTestGuiItemParser.DovrebbeSegnareIlTipoOwnerDraw;
begin
  ParseItem('ownerdraw 12');
  Assert.AreEqual(ITEM_TYPE_OWNERDRAW, FirstItem.ItemType);
  Assert.AreEqual(12, FirstItem.Window.OwnerDraw);
end;

procedure TTestGuiItemParser.DovrebbeScartareUnItemConUnColoreAMeta;
begin
  FWorld.ParseMenuText('menuDef { itemDef { forecolor 0.5 x } }');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeUsareLAngoloCasualeDelModello;
var
  LItems: IGuiFakeFiles;
  LSet: TGuiMenuSet;
  LReader: TGuiMenuFileReader;
begin
  LItems := TGuiFakeFileSystem.Create;
  LItems.Add('m.menu', 'menuDef { itemDef { type 7 asset_model "x.md3" } }');
  LSet := TGuiFactory.CreateMenuSet(FWorld.Assets, FWorld.Fonts, TGuiFakeRandom.Create(1000));
  try
    LReader := TGuiFactory.CreateMenuFileReader(TGuiFactory.CreateSourceLoader(LItems), LSet);
    try
      LReader.ParseMenu('m.menu');
    finally
      LReader.Free;
    end;
    // rand() % 360
    Assert.AreEqual(1000 mod 360, LSet[0].Items[0].Model.Angle);
  finally
    LSet.Free;
  end;
end;

procedure TTestGuiItemParser.DovrebbeUsareAngolo0SenzaGeneratore;
begin
  ParseItem('type 7 asset_model "x.md3"');
  Assert.AreEqual(0, FirstItem.Model.Angle);
  Assert.AreEqual(1, FirstItem.Asset);
end;

procedure TTestGuiItemParser.DovrebbeLasciareLAngoloDelModelloSeSiDa;
begin
  ParseItem('type 7 asset_model "x.md3" model_angle 90 model_rotation 8 model_fovx 40 model_fovy 50 model_origin 1 2 3');
  Assert.AreEqual(90, FirstItem.Model.Angle);
  Assert.AreEqual(8, FirstItem.Model.RotationSpeed);
  Assert.AreEqual(Single(50), FirstItem.Model.FovY);
  Assert.AreEqual(Single(3), FirstItem.Model.Origin[2]);
end;

procedure TTestGuiItemParser.DovrebbeRifiutareLeParoleDelListboxSuUnItemSenzaListbox;
begin
  // DIFFERENCE: the original reads and writes through a null pointer (a crash) or one of another kind
  ParseItem('type 1 elementwidth 5');
  Assert.AreEqual(0, FWorld.Menus.Count);
  FWorld.Transcript.Clear;
  ParseItem('type 1 elementheight 5');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 elementtype 1');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 columns 1 1 1 1');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 doubleclick { }');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeRifiutareLeParoleDelModelloSuUnItemSenzaModello;
begin
  // DIFFERENCE: null pointer in the original
  ParseItem('type 1 asset_model "x"');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 model_origin 1 2 3');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 model_fovx 1');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 model_fovy 1');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 model_rotation 1');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 model_angle 1');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeRifiutareLeParoleDelCampoSuUnItemSenzaCampo;
begin
  ParseItem('type 1 maxChars 5');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 maxPaintChars 5');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 cvarFloat "c" 1 2 3');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeRifiutareLeListeSuUnItemSenzaDatiMulti;
begin
  ParseItem('type 1 cvarStrList { a b }');
  Assert.AreEqual(0, FWorld.Menus.Count);
  ParseItem('type 1 cvarFloatList { a 1 }');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiItemParser.DovrebbeLeggereSenzaMemorizzareLeParoleDiUnAltroTipoDiDati;
begin
  // DIFFERENCE: the original writes into the fields of the other kind of data (and succeeds, as real menus
  // need: OpenArena's score.menu has elementwidth on a text item); here the arguments are read and dropped
  ParseItem('type 4 elementwidth 5 elementheight 6 elementtype 2 columns 1 1 1 1 doubleclick { a } cvarFloatList { a 1 } ' +
    'cvarStrList { a b } model_fovx 1 model_origin 1 2 3 asset_model "m"');
  Assert.AreEqual(1, FWorld.Menus.Count);
  Assert.IsTrue(FirstItem.DataKind = gdkEditField);
  Assert.AreEqual(0, FirstItem.Multi.Count);
  Assert.AreEqual(Single(0), FirstItem.ListBox.ElementWidth);
  Assert.AreEqual(1, FirstItem.Asset);
  FWorld.Menus.Reset;
  ParseItem('type 6 maxChars 5 maxPaintChars 6 cvarFloat "c" 1 2 3');
  Assert.AreEqual(1, FWorld.Menus.Count);
  Assert.AreEqual(0, FirstItem.EditField.MaxChars);
  Assert.AreEqual('c', string(FirstItem.Cvar));
end;

procedure TTestGuiItemParser.DovrebbeSegnareLeAzioniDelCvar;
begin
  ParseItem('enableCvar { a } showCvar { b }');
  Assert.AreEqual(CVAR_SHOW, FirstItem.CvarFlags);
  Assert.AreEqual('b ', string(FirstItem.EnableCvar));
  FWorld.Menus.Reset;
  ParseItem('disableCvar { a }');
  Assert.AreEqual(CVAR_DISABLE, FirstItem.CvarFlags);
  FWorld.Menus.Reset;
  ParseItem('hideCvar { a }');
  Assert.AreEqual(CVAR_HIDE, FirstItem.CvarFlags);
  FWorld.Menus.Reset;
  ParseItem('enableCvar { a }');
  Assert.AreEqual(CVAR_ENABLE, FirstItem.CvarFlags);
end;

{ TTestGuiMenuParser }

procedure TTestGuiMenuParser.Setup;
begin
  FWorld := TGuiWorld.Create;
end;

procedure TTestGuiMenuParser.TearDown;
begin
  FWorld.Free;
end;

procedure TTestGuiMenuParser.DovrebbeLeggereLeParoleChiaveDelMenu;
var
  LMenu: TGuiMenu;
begin
  FWorld.ParseMenuText('MENUDEF { Name "m" rect 1 2 3 4 style 5 visible 1 border 2 borderSize 3 background "bg" cinematic "c" ' +
    'ownerdraw 6 ownerdrawFlag 1 ownerdrawFlag 4 popup outOfBoundsClick soundLoop "s" fadeClamp 0.5 fadeCycle 3 fadeAmount 0.25 ' +
    'onOpen { a } onClose { b } onESC { c } focuscolor 1 2 3 4 disablecolor 5 6 7 8 backcolor 1 1 1 1 bordercolor 2 2 2 2 ' +
    'outlinecolor 3 3 3 3 fullscreen 0 }');
  LMenu := FWorld.Menus[0];
  Assert.AreEqual('m', string(LMenu.Window.Name));
  Assert.AreEqual(Single(3), LMenu.Window.Rect.W);
  Assert.AreEqual(5, LMenu.Window.Style);
  Assert.AreEqual(WINDOW_VISIBLE or WINDOW_POPUP or WINDOW_OOB_CLICK, LMenu.Window.Flags);
  Assert.AreEqual(2, LMenu.Window.Border);
  Assert.AreEqual(Single(3), LMenu.Window.BorderSize);
  Assert.AreEqual(1, LMenu.Window.Background);
  Assert.AreEqual('c', string(LMenu.Window.CinematicName));
  Assert.AreEqual(6, LMenu.Window.OwnerDraw);
  Assert.AreEqual(5, LMenu.Window.OwnerDrawFlags);
  Assert.AreEqual('s', string(LMenu.SoundName));
  Assert.AreEqual(Single(0.5), LMenu.FadeClamp);
  Assert.AreEqual(3, LMenu.FadeCycle);
  Assert.AreEqual(Single(0.25), LMenu.FadeAmount);
  Assert.AreEqual('a ', string(LMenu.OnOpen));
  Assert.AreEqual('b ', string(LMenu.OnClose));
  Assert.AreEqual('c ', string(LMenu.OnESC));
  Assert.AreEqual(Single(2), LMenu.FocusColor[1]);
  Assert.AreEqual(Single(8), LMenu.DisableColor[3]);
  Assert.AreEqual(Single(1), LMenu.Window.BackColor[0]);
  Assert.AreEqual(Single(2), LMenu.Window.BorderColor[0]);
  Assert.AreEqual(Single(3), LMenu.Window.OutlineColor[0]);
end;

procedure TTestGuiMenuParser.DovrebbeSegnareIlColoreDelPrimoPianoDelMenu;
begin
  FWorld.ParseMenuText('menuDef { forecolor 1 2 3 4 }');
  Assert.AreEqual(WINDOW_FORECOLORSET, FWorld.Menus[0].Window.Flags);
end;

procedure TTestGuiMenuParser.DovrebbeSegnalareUnaParolaChiaveSconosciutaEContinuare;
begin
  FWorld.ParseMenuText('menuDef { bogus name "m" }');
  Assert.AreEqual('m', string(FWorld.Menus[0].Window.Name));
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: unknown menu keyword bogus', FWorld.Transcript[1]);
end;

procedure TTestGuiMenuParser.DovrebbeLeggereUnItemEMetterloNelMenu;
begin
  FWorld.ParseMenuText('menuDef { rect 10 20 1 1 itemDef { name "i" rect 1 2 3 4 } }');
  Assert.AreEqual(1, FWorld.Menus[0].Items.Count);
  Assert.IsTrue(FWorld.Menus[0].Items[0].Parent = FWorld.Menus[0]);
  // Menu_PostParse placed the item
  Assert.AreEqual(Single(11), FWorld.Menus[0].Items[0].Window.Rect.X);
end;

procedure TTestGuiMenuParser.DovrebbeScartareUnItemChePerdeUnaParola;
begin
  FWorld.ParseMenuText('menuDef { itemDef { rect } }');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiMenuParser.DovrebbeLeggereLeParoleDelMenuDentroUnItemSuperiorePerLimite;
var
  LText: string;
  LIndex: Integer;
begin
  // past 96 items the original returns success without reading the block: "{" is an unknown keyword of
  // the menu, and the words of the block are read as words of the menu ("name" sets the menu name)
  LText := 'menuDef { name "m" ';
  for LIndex := 1 to 96 do
    LText := LText + 'itemDef { name "i" } ';
  LText := LText + 'itemDef { name "late" } }';
  FWorld.ParseMenuText(AnsiString(LText));
  Assert.AreEqual(96, FWorld.Menus[0].Items.Count);
  Assert.AreEqual('late', string(FWorld.Menus[0].Window.Name));
end;

procedure TTestGuiMenuParser.DovrebbeRegistrareIlFontUnaVoltaSola;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, GUI_FONT_FILE_SIZE);
  FWorld.Files.Add('fonts/fontImage_48.dat', LBytes);
  FWorld.ParseMenuText('menuDef { font "fonts/x" } menuDef { font "fonts/y" }');
  Assert.AreEqual(1, FWorld.Fonts.Count);
  Assert.IsTrue(FWorld.Menus.Assets.FontRegistered);
  Assert.AreEqual('fonts/x', string(FWorld.Menus[0].Font));
  Assert.AreEqual('fonts/y', string(FWorld.Menus[1].Font));
end;

procedure TTestGuiMenuParser.DovrebbeNonRegistrareIlFontSeGiaRegistrato;
begin
  FWorld.Menus.Assets.FontRegistered := True;
  FWorld.ParseMenuText('menuDef { font "fonts/x" }');
  Assert.AreEqual(0, FWorld.Fonts.Count);
  Assert.AreEqual(0, FWorld.Transcript.Count - 1);
end;

procedure TTestGuiMenuParser.DovrebbeLeggereLeStringheComeNullaSeIlPoolEPieno;
var
  LText: string;
  LIndex: Integer;
begin
  // the string pool holds 384 KB: strings that do not fit are empty, the keyword still succeeds
  LText := 'menuDef { ';
  for LIndex := 1 to 20 do
    LText := LText + 'soundLoop "' + StringOfChar(Char(Ord('a') + LIndex mod 20), 30000) + '" ';
  LText := LText + ' name "' + StringOfChar('z', 30000) + '" }';
  FWorld.ParseMenuText(AnsiString(LText));
  Assert.IsTrue(FWorld.Menus.Strings.Refused > 0);
  Assert.AreEqual('', string(FWorld.Menus[0].Window.Name));
end;

{ TTestGuiAssetParser }

procedure TTestGuiAssetParser.Setup;
begin
  FWorld := TGuiWorld.Create;
end;

procedure TTestGuiAssetParser.TearDown;
begin
  FWorld.Free;
end;

procedure TTestGuiAssetParser.DovrebbeLeggereIValoriDegliAsset;
begin
  FWorld.ParseMenuText('assetGlobalDef { fadeClamp 0.5 fadeCycle 6 fadeAmount 0.25 shadowX 2 shadowY -3 }');
  Assert.AreEqual(Single(0.5), FWorld.Menus.Assets.FadeClamp);
  Assert.AreEqual(6, FWorld.Menus.Assets.FadeCycle);
  Assert.AreEqual(Single(0.25), FWorld.Menus.Assets.FadeAmount);
  Assert.AreEqual(Single(2), FWorld.Menus.Assets.ShadowX);
  Assert.AreEqual(Single(-3), FWorld.Menus.Assets.ShadowY);
end;

procedure TTestGuiAssetParser.DovrebbeSaltareLeParoleChiaveSconosciute;
begin
  FWorld.ParseMenuText('assetGlobalDef { whatever fadeCycle 6 }');
  Assert.AreEqual(6, FWorld.Menus.Assets.FadeCycle);
  Assert.AreEqual(1, FWorld.Transcript.Count);
end;

procedure TTestGuiAssetParser.DovrebbeFermarsiSuUnFontSenzaGrandezza;
begin
  FWorld.ParseMenuText('assetGlobalDef { font "f" } menuDef { name "x" }');
  // the block fails and the file ends there
  Assert.AreEqual(0, FWorld.Menus.Count);
  Assert.IsFalse(FWorld.Menus.Assets.FontRegistered);
end;

procedure TTestGuiAssetParser.DovrebbeFermarsiSuUnaParolaChiaveSenzaValore;
begin
  FWorld.ParseMenuText('assetGlobalDef { fadeClamp x } menuDef { name "x" }');
  Assert.AreEqual(0, FWorld.Menus.Count);
  FWorld.ParseMenuText('assetGlobalDef { fadeCycle');
  FWorld.ParseMenuText('assetGlobalDef { shadowColor 1 2');
  FWorld.ParseMenuText('assetGlobalDef { cursor');
  FWorld.ParseMenuText('assetGlobalDef { gradientbar');
  FWorld.ParseMenuText('assetGlobalDef { menuEnterSound');
  FWorld.ParseMenuText('assetGlobalDef { menuExitSound');
  FWorld.ParseMenuText('assetGlobalDef { itemFocusSound');
  FWorld.ParseMenuText('assetGlobalDef { menuBuzzSound');
  FWorld.ParseMenuText('assetGlobalDef { fadeAmount');
  FWorld.ParseMenuText('assetGlobalDef { shadowX');
  FWorld.ParseMenuText('assetGlobalDef { shadowY');
  FWorld.ParseMenuText('assetGlobalDef { smallFont "x"');
  FWorld.ParseMenuText('assetGlobalDef { bigFont "x"');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiAssetParser.DovrebbeImpostareIlLimiteDellOmbraDalColore;
begin
  FWorld.ParseMenuText('assetGlobalDef { shadowColor 0 0.5 1 0.25 }');
  Assert.AreEqual(Single(0.25), FWorld.Menus.Assets.ShadowFadeClamp);
  Assert.AreEqual(Single(0.5), FWorld.Menus.Assets.ShadowColor[1]);
end;

procedure TTestGuiAssetParser.DovrebbeRegistrareISuoniEIlCursore;
begin
  FWorld.ParseMenuText('assetGlobalDef { cursor "c.tga" gradientbar "g.tga" menuEnterSound "a" menuExitSound "b" ' +
    'itemFocusSound "c" menuBuzzSound "d" }');
  Assert.AreEqual('c.tga', string(FWorld.Menus.Assets.CursorStr));
  Assert.AreEqual(1, FWorld.Menus.Assets.Cursor);
  Assert.AreEqual(2, FWorld.Menus.Assets.GradientBar);
  Assert.AreEqual(1, FWorld.Menus.Assets.MenuEnterSound);
  Assert.AreEqual(2, FWorld.Menus.Assets.MenuExitSound);
  Assert.AreEqual(3, FWorld.Menus.Assets.ItemFocusSound);
  Assert.AreEqual(4, FWorld.Menus.Assets.MenuBuzzSound);
end;

procedure TTestGuiAssetParser.DovrebbeRegistrareITreFont;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, GUI_FONT_FILE_SIZE);
  FWorld.Files.Add('fonts/fontImage_16.dat', LBytes);
  FWorld.Files.Add('fonts/fontImage_20.dat', LBytes);
  FWorld.Files.Add('fonts/fontImage_24.dat', LBytes);
  FWorld.ParseMenuText('assetGlobalDef { font "a" 16 smallFont "b" 20 bigFont "c" 24 }');
  Assert.AreEqual(3, FWorld.Fonts.Count);
  Assert.IsTrue(FWorld.Menus.Assets.FontRegistered);
  Assert.AreEqual('fonts/fontImage_16.dat', string(FWorld.Menus.Assets.TextFont.Name));
  Assert.AreEqual('fonts/fontImage_20.dat', string(FWorld.Menus.Assets.SmallFont.Name));
  Assert.AreEqual('fonts/fontImage_24.dat', string(FWorld.Menus.Assets.BigFont.Name));
end;

{ TTestGuiMenuFileReader }

procedure TTestGuiMenuFileReader.Setup;
begin
  FWorld := TGuiWorld.Create;
end;

procedure TTestGuiMenuFileReader.TearDown;
begin
  FWorld.Free;
end;

procedure TTestGuiMenuFileReader.DovrebbeDareFalsoPerUnFileMancanteSenzaFermarsi;
begin
  Assert.IsFalse(FWorld.Reader.ParseMenu('missing.menu'));
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiMenuFileReader.DovrebbeScrivereIlNomeDelFileCheLegge;
begin
  FWorld.AddFile('a.menu', 'menuDef { name "a" }');
  Assert.IsTrue(FWorld.Reader.ParseMenu('a.menu'));
  Assert.AreEqual('log Parsing menu file:a.menu', FWorld.Transcript[0]);
end;

procedure TTestGuiMenuFileReader.DovrebbeFermarsiAlPrimoMenuCheFallisce;
begin
  FWorld.ParseMenuText('menuDef { rect x } menuDef { name "second" }');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiMenuFileReader.DovrebbeLeggereLaListaDeiFile;
begin
  FWorld.AddFile('list.txt', '{ loadmenu { "a.menu" } loadmenu { "b.menu" "c.menu" } }');
  FWorld.AddFile('a.menu', 'menuDef { name "a" }');
  FWorld.AddFile('b.menu', 'menuDef { name "b" }');
  FWorld.AddFile('c.menu', 'menuDef { name "c" }');
  FWorld.AddFile('bc.menu', 'menuDef { name "bc" }');
  FWorld.Reader.LoadMenus('list.txt', False);
  // the strings of one loadmenu join into one file name ("b.menuc.menu"): there is no such file
  Assert.AreEqual(1, FWorld.Menus.Count);
  Assert.AreEqual('a', string(FWorld.Menus[0].Window.Name));
end;

procedure TTestGuiMenuFileReader.DovrebbeFermarsiAllaListaSeUnLoadmenuNonSiLegge;
begin
  FWorld.AddFile('list.txt', '{ loadmenu "a.menu" loadmenu { "b.menu" } }');
  FWorld.AddFile('b.menu', 'menuDef { name "b" }');
  FWorld.Reader.LoadMenus('list.txt', False);
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiMenuFileReader.DovrebbeUsareLaListaDiPredefinitaSeMancaQuellaChiesta;
begin
  FWorld.AddFile('ui/menus.txt', '{ loadmenu { "a.menu" } }');
  FWorld.AddFile('a.menu', 'menuDef { name "a" }');
  FWorld.Reader.LoadMenus('mine.txt', False);
  Assert.AreEqual(1, FWorld.Menus.Count);
  Assert.AreEqual('log menu file not found: mine.txt, using default', FWorld.Transcript[0]);
end;

procedure TTestGuiMenuFileReader.DovrebbeSollevareSeMancaAncheLaListaDiPredefinita;
var
  LName: AnsiString;
begin
  LName := '';
  try
    FWorld.Reader.LoadMenus('mine.txt', False);
    Assert.Fail('no exception');
  except
    on E: EGuiFileNotFoundException do
      LName := E.FileName;
  end;
  Assert.AreEqual('ui/menus.txt', string(LName));
end;

procedure TTestGuiMenuFileReader.DovrebbeDimenticareIMenuSeSiChiedeIlReset;
begin
  FWorld.ParseMenuText('menuDef { name "old" }');
  FWorld.AddFile('list.txt', '{ loadmenu { "a.menu" } }');
  FWorld.AddFile('a.menu', 'menuDef { name "a" }');
  FWorld.Reader.LoadMenus('list.txt', True);
  Assert.AreEqual(1, FWorld.Menus.Count);
  Assert.AreEqual('a', string(FWorld.Menus[0].Window.Name));
end;

procedure TTestGuiMenuFileReader.DovrebbeTenereIMenuSeNonSiChiedeIlReset;
begin
  FWorld.ParseMenuText('menuDef { name "old" }');
  FWorld.AddFile('list.txt', '{ loadmenu { "a.menu" } }');
  FWorld.AddFile('a.menu', 'menuDef { name "a" }');
  FWorld.Reader.LoadMenus('list.txt', False);
  Assert.AreEqual(2, FWorld.Menus.Count);
end;

procedure TTestGuiMenuFileReader.DovrebbeLeggereUnFileCheIncludeUnAltro;
begin
  FWorld.AddFile('defs.h', '#define NAME "included"');
  FWorld.ParseMenuText('#include "defs.h"' + #10 + 'menuDef { name NAME }');
  Assert.AreEqual('included', string(FWorld.Menus[0].Window.Name));
end;

procedure TTestGuiMenuFileReader.DovrebbeSegnalareUnIncludeCheNonCE;
begin
  FWorld.ParseMenuText('#include "nothere.h"' + #10 + 'menuDef { name "x" }');
  Assert.IsTrue(FWorld.Transcript.Count > 1);
end;

{ TTestGuiPrecompilerSource }

procedure TTestGuiPrecompilerSource.DovrebbeDareITipiEIValoriDeiToken;
var
  LSource: IGuiTokenSource;
  LToken: TGuiToken;
begin
  LSource := OpenGuiSource('word 42 0x1F 1.5 { ;');
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual(4, LToken.TokenType);
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual(3, LToken.TokenType);
  Assert.AreEqual(42, LToken.IntValue);
  Assert.AreEqual(Single(42), LToken.FloatValue);
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual(31, LToken.IntValue);
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual(Single(1.5), LToken.FloatValue);
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual(5, LToken.TokenType);
  Assert.AreEqual('{', string(LToken.Text));
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.IsFalse(LSource.ReadToken(LToken));
end;

procedure TTestGuiPrecompilerSource.DovrebbeDareLeStringheSenzaVirgolette;
var
  LSource: IGuiTokenSource;
  LToken: TGuiToken;
begin
  LSource := OpenGuiSource('"a b"');
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual(1, LToken.TokenType);
  Assert.AreEqual('a b', string(LToken.Text));
end;

procedure TTestGuiPrecompilerSource.DovrebbeDareNomeDelFileERiga;
var
  LSource: IGuiTokenSource;
  LToken: TGuiToken;
begin
  LSource := OpenGuiSource('a' + #10 + #10 + 'b');
  LSource.ReadToken(LToken);
  Assert.AreEqual(1, LSource.Line);
  LSource.ReadToken(LToken);
  Assert.AreEqual(3, LSource.Line);
  Assert.AreEqual('test.menu', string(LSource.FileName));
end;

procedure TTestGuiPrecompilerSource.DovrebbeDareNilPerUnFileMancante;
var
  LFiles: IGuiFakeFiles;
begin
  LFiles := TGuiFakeFileSystem.Create;
  Assert.IsNull(TGuiFactory.CreateSourceLoader(LFiles).Load('none.menu'));
end;

procedure TTestGuiPrecompilerSource.DovrebbeEspandereIDefineConParametri;
var
  LSource: IGuiTokenSource;
  LToken: TGuiToken;
begin
  LSource := OpenGuiSource('#define TWICE(a) a a' + #10 + 'TWICE(x)');
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual('x', string(LToken.Text));
  Assert.IsTrue(LSource.ReadToken(LToken));
  Assert.AreEqual('x', string(LToken.Text));
  Assert.IsFalse(LSource.ReadToken(LToken));
end;

procedure TTestGuiPrecompilerSource.DovrebbeInoltrareIMessaggiDelLexerAlLog;
var
  LLines: TStringList;
  LLog: IGuiLog;
  LSource: IGuiTokenSource;
  LToken: TGuiToken;
begin
  LLines := TStringList.Create;
  try
    LLog := TGuiFakeLog.Create(LLines);
    LSource := OpenGuiSource('#error broken' + #10 + 'x', LLog);
    while LSource.ReadToken(LToken) do
      ;
    Assert.IsTrue(LLines.Count > 0);
  finally
    LLines.Free;
  end;
end;

procedure TTestGuiPrecompilerSource.DovrebbeNonFallireSenzaLog;
var
  LAdapter: IIdLibLog;
  LLines: TStringList;
begin
  LAdapter := TGuiIdLibLog.Create(nil);
  LAdapter.Printf('x');
  LAdapter.Warning('y');
  LLines := TStringList.Create;
  try
    LAdapter := TGuiIdLibLog.Create(TGuiFakeLog.Create(LLines));
    LAdapter.Printf('x');
    LAdapter.Warning('y');
    Assert.AreEqual('log x', LLines[0]);
    Assert.AreEqual('log y', LLines[1]);
  finally
    LLines.Free;
  end;
end;

{ TTestGuiTypes }

procedure TTestGuiTypes.DovrebbeDareFileERigaNellEccezioneDiSintassi;
var
  LException: EGuiParseException;
begin
  LException := EGuiParseException.Create('x.menu', 12, 'bad');
  try
    Assert.AreEqual('x.menu', string(LException.FileName));
    Assert.AreEqual(12, LException.Line);
    Assert.AreEqual('x.menu, line 12: bad', LException.Message);
  finally
    LException.Free;
  end;
end;

procedure TTestGuiTypes.DovrebbeDareIlNomeDelFileNellEccezioneDiFileMancante;
var
  LException: EGuiFileNotFoundException;
begin
  LException := EGuiFileNotFoundException.Create('a/b.menu');
  try
    Assert.AreEqual('a/b.menu', string(LException.FileName));
    Assert.AreEqual('menu file not found: a/b.menu', LException.Message);
  finally
    LException.Free;
  end;
end;

procedure TTestGuiTypes.DovrebbeFareUnaFinestraComeWindow_Init;
var
  LWindow: TGuiWindowDef;
begin
  LWindow := TGuiWindowDef.Create;
  Assert.AreEqual(Single(1), LWindow.BorderSize);
  Assert.AreEqual(Single(1), LWindow.ForeColor[0]);
  Assert.AreEqual(Single(0), LWindow.BackColor[0]);
  Assert.AreEqual(-1, LWindow.Cinematic);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiItemParser);
  TDUnitX.RegisterTestFixture(TTestGuiMenuParser);
  TDUnitX.RegisterTestFixture(TTestGuiAssetParser);
  TDUnitX.RegisterTestFixture(TTestGuiMenuFileReader);
  TDUnitX.RegisterTestFixture(TTestGuiPrecompilerSource);
  TDUnitX.RegisterTestFixture(TTestGuiTypes);

end.
