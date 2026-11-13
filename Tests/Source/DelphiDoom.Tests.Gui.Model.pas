{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - menus, items and the menu set        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Model;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.MenuSet,
  DelphiDoom.Tests.Gui.Fakes;

type
  [TestFixture]
  [Category('gui')]
  TTestGuiItem = class(TObject)
  public
    [Test]
    procedure DovrebbeNascereComeItem_Init;
    [Test]
    procedure DovrebbeFareIDatiDelListbox;
    [Test]
    procedure DovrebbeFareIDatiDelCampoDiTestoConIlLimiteDeiCaratteri;
    [Test]
    procedure DovrebbeFareIDatiDelCampoPerLeAltreFormeDiCampo;
    [Test]
    procedure DovrebbeFareIDatiMultiEIDatiDelModello;
    [Test]
    procedure DovrebbeNonFareDatiPerUnTipoSenzaDati;
    [Test]
    procedure DovrebbeFareIDatiUnaVoltaSola;
    [Test]
    procedure DovrebbePosizionareSullaFinestraDelMenu;
    [Test]
    procedure DovrebbeAggiungereIlBordoDelMenuEDellItem;
    [Test]
    procedure DovrebbeAzzerareIlRettangoloDelTesto;
    [Test]
    procedure DovrebbeNonFareNullaSenzaMenu;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiMenu = class(TObject)
  private
    FMenu: TGuiMenu;
    function AddItem(const AName, AGroup: AnsiString): TGuiItem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNascereComeMenu_Init;
    [Test]
    procedure DovrebbeFareUnMenuATuttoSchermo;
    [Test]
    procedure DovrebbeLasciareUnMenuNormaleDoveE;
    [Test]
    procedure DovrebbeTrovareUnItemPerNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeDareNilPerUnNomeCheNonCE;
    [Test]
    procedure DovrebbeContareGliItemDiUnGruppoOUnNome;
    [Test]
    procedure DovrebbeDareLEnesimoItemDelGruppo;
    [Test]
    procedure DovrebbeDareNilPerUnIndiceOltreIlGruppo;
    [Test]
    procedure DovrebbePossedereGliItem;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiMenuSet = class(TObject)
  private
    FWorld: TGuiWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNascereVuoto;
    [Test]
    procedure DovrebbeTenereIMenuLettiInOrdine;
    [Test]
    procedure DovrebbeNonTenereUnMenuLettoAMeta;
    [Test]
    procedure DovrebbeFermarsiA64Menu;
    [Test]
    procedure DovrebbeDimenticareIMenuConReset;
    [Test]
    procedure DovrebbeTrovareUnMenuPerNome;
    [Test]
    procedure DovrebbeDareIValoriDiFadeDegliAssetAiMenuNuovi;
    [Test]
    procedure DovrebbeNonCondividereNienteTraDueInsiemi;
    [Test]
    procedure DovrebbeTenereLeStringheNelPoolDopoUnReset;
  end;

implementation

uses
  DelphiDoom.Gui.Factory;

{ TTestGuiItem }

procedure TTestGuiItem.DovrebbeNascereComeItem_Init;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    Assert.AreEqual(Single(0.55), LItem.TextScale);
    Assert.AreEqual(Single(1), LItem.Window.BorderSize);
    Assert.AreEqual(Single(1), LItem.Window.ForeColor[3]);
    Assert.AreEqual(-1, LItem.Window.Cinematic);
    Assert.AreEqual(0, LItem.Window.Flags);
    Assert.IsTrue(LItem.DataKind = gdkNone);
    Assert.IsNull(LItem.Parent);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeFareIDatiDelListbox;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    LItem.ItemType := ITEM_TYPE_LISTBOX;
    LItem.ValidateTypeData;
    Assert.IsTrue(LItem.DataKind = gdkListBox);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeFareIDatiDelCampoDiTestoConIlLimiteDeiCaratteri;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    LItem.ItemType := ITEM_TYPE_EDITFIELD;
    LItem.ValidateTypeData;
    Assert.IsTrue(LItem.DataKind = gdkEditField);
    Assert.AreEqual(256, LItem.EditField.MaxPaintChars);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeFareIDatiDelCampoPerLeAltreFormeDiCampo;
var
  LType: Integer;
  LItem: TGuiItem;
begin
  for LType in [ITEM_TYPE_TEXT, ITEM_TYPE_NUMERICFIELD, ITEM_TYPE_YESNO, ITEM_TYPE_BIND, ITEM_TYPE_SLIDER] do
  begin
    LItem := TGuiItem.Create;
    try
      LItem.ItemType := LType;
      LItem.ValidateTypeData;
      Assert.IsTrue(LItem.DataKind = gdkEditField, 'type ' + IntToStr(LType));
      Assert.AreEqual(0, LItem.EditField.MaxPaintChars);
    finally
      LItem.Free;
    end;
  end;
end;

procedure TTestGuiItem.DovrebbeFareIDatiMultiEIDatiDelModello;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    LItem.ItemType := ITEM_TYPE_MULTI;
    LItem.ValidateTypeData;
    Assert.IsTrue(LItem.DataKind = gdkMulti);
  finally
    LItem.Free;
  end;
  LItem := TGuiItem.Create;
  try
    LItem.ItemType := ITEM_TYPE_MODEL;
    LItem.ValidateTypeData;
    Assert.IsTrue(LItem.DataKind = gdkModel);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeNonFareDatiPerUnTipoSenzaDati;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    LItem.ItemType := ITEM_TYPE_BUTTON;
    LItem.ValidateTypeData;
    Assert.IsTrue(LItem.DataKind = gdkNone);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeFareIDatiUnaVoltaSola;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    // type 0 (text) makes the data of an edit field; the type that follows does not change them
    LItem.ValidateTypeData;
    LItem.ItemType := ITEM_TYPE_LISTBOX;
    LItem.ValidateTypeData;
    Assert.IsTrue(LItem.DataKind = gdkEditField);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbePosizionareSullaFinestraDelMenu;
var
  LMenu: TGuiMenu;
  LItem: TGuiItem;
begin
  LMenu := TGuiMenu.Create(0, 0, 0);
  try
    LMenu.Window.Rect.X := 100;
    LMenu.Window.Rect.Y := 50;
    LItem := TGuiItem.Create;
    LItem.Window.RectClient.X := 7;
    LItem.Window.RectClient.Y := 8;
    LItem.Window.RectClient.W := 9;
    LItem.Window.RectClient.H := 10;
    LItem.Parent := LMenu;
    LMenu.Items.Add(LItem);
    LItem.UpdatePosition;
    Assert.AreEqual(Single(107), LItem.Window.Rect.X);
    Assert.AreEqual(Single(58), LItem.Window.Rect.Y);
    Assert.AreEqual(Single(9), LItem.Window.Rect.W);
    Assert.AreEqual(Single(10), LItem.Window.Rect.H);
  finally
    LMenu.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeAggiungereIlBordoDelMenuEDellItem;
var
  LMenu: TGuiMenu;
  LItem: TGuiItem;
begin
  LMenu := TGuiMenu.Create(0, 0, 0);
  try
    LMenu.Window.Border := 1;
    LMenu.Window.BorderSize := 3;
    LItem := TGuiItem.Create;
    LItem.Window.Border := 1;
    LItem.Window.BorderSize := 5;
    LItem.Parent := LMenu;
    LMenu.Items.Add(LItem);
    LItem.UpdatePosition;
    Assert.AreEqual(Single(8), LItem.Window.Rect.X);
  finally
    LMenu.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeAzzerareIlRettangoloDelTesto;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    LItem.TextRect.W := 10;
    LItem.TextRect.H := 20;
    LItem.SetScreenCoords(0, 0);
    Assert.AreEqual(Single(0), LItem.TextRect.W);
    Assert.AreEqual(Single(0), LItem.TextRect.H);
  finally
    LItem.Free;
  end;
end;

procedure TTestGuiItem.DovrebbeNonFareNullaSenzaMenu;
var
  LItem: TGuiItem;
begin
  LItem := TGuiItem.Create;
  try
    LItem.Window.Rect.X := 3;
    LItem.UpdatePosition;
    Assert.AreEqual(Single(3), LItem.Window.Rect.X);
  finally
    LItem.Free;
  end;
end;

{ TTestGuiMenu }

procedure TTestGuiMenu.Setup;
begin
  FMenu := TGuiMenu.Create(0.5, 0.75, 4);
end;

procedure TTestGuiMenu.TearDown;
begin
  FMenu.Free;
end;

function TTestGuiMenu.AddItem(const AName, AGroup: AnsiString): TGuiItem;
begin
  Result := TGuiItem.Create;
  Result.Window.Name := AName;
  Result.Window.Group := AGroup;
  Result.Parent := FMenu;
  FMenu.Items.Add(Result);
end;

procedure TTestGuiMenu.DovrebbeNascereComeMenu_Init;
begin
  Assert.AreEqual(-1, FMenu.CursorItem);
  Assert.AreEqual(Single(0.5), FMenu.FadeAmount);
  Assert.AreEqual(Single(0.75), FMenu.FadeClamp);
  Assert.AreEqual(4, FMenu.FadeCycle);
  Assert.AreEqual(Single(1), FMenu.Window.BorderSize);
  Assert.AreEqual(0, FMenu.Items.Count);
end;

procedure TTestGuiMenu.DovrebbeFareUnMenuATuttoSchermo;
begin
  FMenu.FullScreen := 1;
  FMenu.Window.Rect.X := 9;
  AddItem('a', '').Window.RectClient.X := 5;
  FMenu.PostParse;
  Assert.AreEqual(Single(640), FMenu.Window.Rect.W);
  Assert.AreEqual(Single(480), FMenu.Window.Rect.H);
  Assert.AreEqual(Single(0), FMenu.Window.Rect.X);
  Assert.AreEqual(Single(5), FMenu.Items[0].Window.Rect.X);
end;

procedure TTestGuiMenu.DovrebbeLasciareUnMenuNormaleDoveE;
begin
  FMenu.Window.Rect.W := 12;
  FMenu.PostParse;
  Assert.AreEqual(Single(12), FMenu.Window.Rect.W);
end;

procedure TTestGuiMenu.DovrebbeTrovareUnItemPerNomeSenzaMaiuscole;
var
  LItem: TGuiItem;
begin
  LItem := AddItem('Play', '');
  AddItem('play', '');
  Assert.IsTrue(FMenu.FindItemByName('PLAY') = LItem);
end;

procedure TTestGuiMenu.DovrebbeDareNilPerUnNomeCheNonCE;
begin
  AddItem('a', '');
  Assert.IsNull(FMenu.FindItemByName('zzz'));
end;

procedure TTestGuiMenu.DovrebbeContareGliItemDiUnGruppoOUnNome;
begin
  AddItem('a', 'g');
  AddItem('b', 'g');
  AddItem('g', '');
  AddItem('c', 'other');
  Assert.AreEqual(3, FMenu.ItemsMatchingGroup('G'));
  Assert.AreEqual(1, FMenu.ItemsMatchingGroup('c'));
  Assert.AreEqual(0, FMenu.ItemsMatchingGroup('none'));
end;

procedure TTestGuiMenu.DovrebbeDareLEnesimoItemDelGruppo;
var
  LSecond: TGuiItem;
begin
  AddItem('a', 'g');
  LSecond := AddItem('b', 'g');
  Assert.IsTrue(FMenu.GetMatchingItemByNumber(1, 'g') = LSecond);
end;

procedure TTestGuiMenu.DovrebbeDareNilPerUnIndiceOltreIlGruppo;
begin
  AddItem('a', 'g');
  Assert.IsNull(FMenu.GetMatchingItemByNumber(1, 'g'));
end;

procedure TTestGuiMenu.DovrebbePossedereGliItem;
begin
  AddItem('a', '');
  // the items are freed with the menu: the leak report of the test run proves it
  Assert.AreEqual(1, FMenu.Items.Count);
end;

{ TTestGuiMenuSet }

procedure TTestGuiMenuSet.Setup;
begin
  FWorld := TGuiWorld.Create;
end;

procedure TTestGuiMenuSet.TearDown;
begin
  FWorld.Free;
end;

procedure TTestGuiMenuSet.DovrebbeNascereVuoto;
begin
  Assert.AreEqual(0, FWorld.Menus.Count);
  Assert.IsNull(FWorld.Menus.FindByName('x'));
end;

procedure TTestGuiMenuSet.DovrebbeTenereIMenuLettiInOrdine;
begin
  FWorld.ParseMenuText('menuDef { name "a" } menuDef { name "b" }');
  Assert.AreEqual(2, FWorld.Menus.Count);
  Assert.AreEqual('a', string(FWorld.Menus[0].Window.Name));
  Assert.AreEqual('b', string(FWorld.Menus.Menus[1].Window.Name));
end;

procedure TTestGuiMenuSet.DovrebbeNonTenereUnMenuLettoAMeta;
begin
  FWorld.ParseMenuText('menuDef { name "a" rect x }');
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiMenuSet.DovrebbeFermarsiA64Menu;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 1 to 70 do
    LText := LText + 'menuDef { name "m' + AnsiString(IntToStr(LIndex)) + '" } ';
  FWorld.ParseMenuText(LText);
  Assert.AreEqual(64, FWorld.Menus.Count);
  Assert.AreEqual('m64', string(FWorld.Menus[63].Window.Name));
end;

procedure TTestGuiMenuSet.DovrebbeDimenticareIMenuConReset;
begin
  FWorld.ParseMenuText('menuDef { name "a" }');
  FWorld.Menus.Reset;
  Assert.AreEqual(0, FWorld.Menus.Count);
end;

procedure TTestGuiMenuSet.DovrebbeTrovareUnMenuPerNome;
begin
  FWorld.ParseMenuText('menuDef { name "Main" } menuDef { name "main" }');
  Assert.IsTrue(FWorld.Menus.FindByName('MAIN') = FWorld.Menus[0]);
end;

procedure TTestGuiMenuSet.DovrebbeDareIValoriDiFadeDegliAssetAiMenuNuovi;
begin
  FWorld.Menus.Assets.FadeClamp := 0.5;
  FWorld.Menus.Assets.FadeCycle := 7;
  FWorld.Menus.Assets.FadeAmount := 0.125;
  FWorld.ParseMenuText('menuDef { name "a" } menuDef { name "b" fadeCycle 2 }');
  Assert.AreEqual(7, FWorld.Menus[0].FadeCycle);
  Assert.AreEqual(Single(0.5), FWorld.Menus[0].FadeClamp);
  Assert.AreEqual(Single(0.125), FWorld.Menus[0].FadeAmount);
  Assert.AreEqual(2, FWorld.Menus[1].FadeCycle);
end;

procedure TTestGuiMenuSet.DovrebbeNonCondividereNienteTraDueInsiemi;
var
  LOther: TGuiMenuSet;
begin
  LOther := TGuiFactory.CreateMenuSet(FWorld.Assets, FWorld.Fonts);
  try
    FWorld.ParseMenuText('menuDef { name "a" text "x" }');
    Assert.AreEqual(0, LOther.Count);
    Assert.AreEqual(0, LOther.Strings.Used);
  finally
    LOther.Free;
  end;
end;

procedure TTestGuiMenuSet.DovrebbeTenereLeStringheNelPoolDopoUnReset;
var
  LUsed: Integer;
begin
  FWorld.ParseMenuText('menuDef { name "abc" }');
  LUsed := FWorld.Menus.Strings.Used;
  FWorld.Menus.Reset;
  Assert.AreEqual(LUsed, FWorld.Menus.Strings.Used);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiItem);
  TDUnitX.RegisterTestFixture(TTestGuiMenu);
  TDUnitX.RegisterTestFixture(TTestGuiMenuSet);

end.
