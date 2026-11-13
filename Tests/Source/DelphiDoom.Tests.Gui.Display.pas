{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the display of the menus             }
{                                                                              }
{  The classes one by one, on the menus of Tests\Data\Gui\files\ui\input.menu: }
{  what the scenarios of the C driver do not reach.                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Display;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Gui.InputScenario;

type
  [TestFixture]
  [Category('gui')]
  TTestGuiDisplay = class(TObject)
  strict private
    FRig: TGuiDisplayRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrovareUnPuntoSoloDentroIlRettangolo;
    [Test]
    procedure DovrebbeVedereVisibileSoloChiNonSvanisce;
    [Test]
    procedure DovrebbeCorreggereIlRettangoloDelTestoSoloSeHaLarghezza;
    [Test]
    procedure DovrebbeTroncareICalcoliInIntero;
    [Test]
    procedure DovrebbeDareIlMassimoDiScorrimentoZeroConElementiSenzaAltezza;
    [Test]
    procedure DovrebbeSeguireIlCursoreConIlPollice;
    [Test]
    procedure DovrebbeTenereIlPollicePrecedenteSeIlCursoreEFuoriDallaBarra;
    [Test]
    procedure DovrebbeNonUsareUnTastoSenzaIlFocus;
    [Test]
    procedure DovrebbeDareLEtichettaDellImpostazioneCorrente;
    [Test]
    procedure DovrebbeDareZeroImpostazioniAChiNonEUnMulti;
    [Test]
    procedure DovrebbeLasciarePassareUnItemSenzaTestCvar;
    [Test]
    procedure DovrebbeDareLaPosizioneSinistraSenzaDatiDelloSlider;
    [Test]
    procedure DovrebbeLimitareIlValoreDelloSliderAgliEstremi;
    [Test]
    procedure DovrebbeLimitareIlTrascinamentoDelloSliderAlleSueEstremita;
    [Test]
    procedure DovrebbeTrascinareIlPolliceOrizzontale;
    [Test]
    procedure DovrebbeNonFareNienteSeIlCursoreNonSiMuove;
    [Test]
    procedure DovrebbeNonFareNienteSenzaCattura;
    [Test]
    procedure DovrebbeCancellareConControlHDopoIlLimiteDiPittura;
    [Test]
    procedure DovrebbeRifiutareUnaLetteraInUnCampoNumerico;
    [Test]
    procedure DovrebbePassareAlCampoPrecedenteConLaFreccia;
    [Test]
    procedure DovrebbeSuonareIlSuonoDelTestoQuandoIlPuntoELiDentro;
    [Test]
    procedure DovrebbeSegnareEToglierIlMouseOver;
    [Test]
    procedure DovrebbeDareIlPrimoItemConIlFocus;
    [Test]
    procedure DovrebbeFunzionareSenzaHostDiScript;
  end;

implementation

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display, DelphiDoom.Gui.Display.State,
  DelphiDoom.Gui.Display.Pointer, DelphiDoom.Gui.Factory, DelphiDoom.Gui.Keys;

procedure TTestGuiDisplay.Setup;
begin
  FRig := TGuiDisplayRig.Create;
end;

procedure TTestGuiDisplay.TearDown;
begin
  FRig.Free;
end;

procedure TTestGuiDisplay.DovrebbeTrovareUnPuntoSoloDentroIlRettangolo;
var
  LRect: TGuiRect;
begin
  LRect.X := 10;
  LRect.Y := 20;
  LRect.W := 30;
  LRect.H := 40;
  Assert.IsTrue(TGuiDisplayState.RectContains(LRect, 11, 21));
  Assert.IsFalse(TGuiDisplayState.RectContains(LRect, 10, 21));
  Assert.IsFalse(TGuiDisplayState.RectContains(LRect, 40, 21));
  Assert.IsFalse(TGuiDisplayState.RectContains(LRect, 20, 60));
end;

procedure TTestGuiDisplay.DovrebbeVedereVisibileSoloChiNonSvanisce;
begin
  Assert.IsTrue(TGuiDisplayState.IsVisible(WINDOW_VISIBLE));
  Assert.IsFalse(TGuiDisplayState.IsVisible(WINDOW_VISIBLE or WINDOW_FADINGOUT));
  Assert.IsFalse(TGuiDisplayState.IsVisible(0));
end;

procedure TTestGuiDisplay.DovrebbeCorreggereIlRettangoloDelTestoSoloSeHaLarghezza;
var
  LItem: TGuiItem;
  LRect: TGuiRect;
begin
  LItem := FRig.Item('main', 'label');
  LItem.TextRect.X := 5;
  LItem.TextRect.Y := 30;
  LItem.TextRect.W := 0;
  LItem.TextRect.H := 10;
  LRect := TGuiDisplayState.CorrectedTextRect(LItem);
  Assert.AreEqual(Double(30), Double(LRect.Y));
  LItem.TextRect.W := 12;
  LRect := TGuiDisplayState.CorrectedTextRect(LItem);
  Assert.AreEqual(Double(20), Double(LRect.Y));
  LRect := TGuiDisplayState.CorrectedTextRect(nil);
  Assert.AreEqual(Double(0), Double(LRect.W));
end;

procedure TTestGuiDisplay.DovrebbeTroncareICalcoliInIntero;
begin
  Assert.AreEqual(2, TGuiDisplayState.FloatToInt(2.9));
  Assert.AreEqual(-2, TGuiDisplayState.FloatToInt(-2.9));
  Assert.AreEqual(Low(Integer), TGuiDisplayState.FloatToInt(1.0E20));
  Assert.AreEqual(Low(Integer), TGuiDisplayState.FloatToInt(-1.0E20));
  Assert.AreEqual(Low(Integer), TGuiDisplayState.FloatToInt(Double.NaN));
end;

procedure TTestGuiDisplay.DovrebbeDareIlMassimoDiScorrimentoZeroConElementiSenzaAltezza;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'list');
  Assert.AreEqual(6, FRig.Display.ListBoxes.MaxScroll(LItem));
  LItem.ListBox.ElementHeight := 0;
  // 80 / 0 is an infinity: the integer of it is the smallest one, the maximum is then 0
  Assert.AreEqual(0, FRig.Display.ListBoxes.MaxScroll(LItem));
  FRig.Host.SetFeeder(1, 2);
  LItem.ListBox.ElementHeight := 16;
  Assert.AreEqual(0, FRig.Display.ListBoxes.MaxScroll(LItem));
end;

procedure TTestGuiDisplay.DovrebbeSeguireIlCursoreConIlPollice;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'list');
  Assert.AreEqual(37, FRig.Display.ListBoxes.ThumbDrawPosition(LItem));
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(292, 60);
  Assert.AreEqual(52, FRig.Display.ListBoxes.ThumbDrawPosition(LItem));
  // the horizontal list: the thumb follows the x of the cursor
  LItem := FRig.Item('main', 'hlist');
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(250, 150);
  Assert.AreEqual(242, FRig.Display.ListBoxes.ThumbDrawPosition(LItem));
end;

procedure TTestGuiDisplay.DovrebbeTenereIlPollicePrecedenteSeIlCursoreEFuoriDallaBarra;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'list');
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(292, 5);
  Assert.AreEqual(37, FRig.Display.ListBoxes.ThumbDrawPosition(LItem));
  LItem := FRig.Item('main', 'hlist');
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(10, 150);
  Assert.AreEqual(217, FRig.Display.ListBoxes.ThumbDrawPosition(LItem));
end;

procedure TTestGuiDisplay.DovrebbeNonUsareUnTastoSenzaIlFocus;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'list');
  FRig.Host.SetCursor(210, 30);
  Assert.IsFalse(FRig.Display.ListBoxes.HandleKey(LItem, K_DOWNARROW, True, False));
  Assert.IsTrue(FRig.Display.ListBoxes.HandleKey(LItem, K_DOWNARROW, True, True));
  Assert.IsFalse(FRig.Display.ListBoxes.HandleKey(LItem, K_ESCAPE, True, True));
end;

procedure TTestGuiDisplay.DovrebbeDareLEtichettaDellImpostazioneCorrente;
var
  LMulti, LFloat: TGuiItem;
begin
  LMulti := FRig.Item('main', 'multi');
  LFloat := FRig.Item('main', 'multif');
  FRig.Host.SetCvarEntry('mode', 'hard');
  FRig.Host.SetCvarEntry('level', '2.5');
  Assert.AreEqual('Hard', string(FRig.Display.CvarItems.MultiSetting(LMulti)));
  Assert.AreEqual(1, FRig.Display.CvarItems.MultiFindCvarByValue(LMulti));
  Assert.AreEqual('Mid', string(FRig.Display.CvarItems.MultiSetting(LFloat)));
  Assert.AreEqual(3, FRig.Display.CvarItems.MultiCountSettings(LMulti));
  // a value that is not a setting: no label, and the first setting for the search
  FRig.Host.SetCvarEntry('mode', 'nope');
  FRig.Host.SetCvarEntry('level', '9');
  Assert.AreEqual('', string(FRig.Display.CvarItems.MultiSetting(LMulti)));
  Assert.AreEqual('', string(FRig.Display.CvarItems.MultiSetting(LFloat)));
  Assert.AreEqual(0, FRig.Display.CvarItems.MultiFindCvarByValue(LFloat));
end;

procedure TTestGuiDisplay.DovrebbeDareZeroImpostazioniAChiNonEUnMulti;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'play');
  Assert.AreEqual(0, FRig.Display.CvarItems.MultiCountSettings(LItem));
  Assert.AreEqual(0, FRig.Display.CvarItems.MultiFindCvarByValue(LItem));
  Assert.AreEqual('', string(FRig.Display.CvarItems.MultiSetting(LItem)));
  Assert.IsFalse(FRig.Display.CvarItems.MultiHandleKey(LItem, K_ENTER));
end;

procedure TTestGuiDisplay.DovrebbeLasciarePassareUnItemSenzaTestCvar;
begin
  Assert.IsTrue(FRig.Display.CvarItems.EnableShowViaCvar(FRig.Item('main', 'play'), CVAR_ENABLE));
  Assert.IsTrue(FRig.Display.CvarItems.EnableShowViaCvar(nil, CVAR_ENABLE));
  FRig.Host.SetCvarEntry('mode', 'easy');
  Assert.IsTrue(FRig.Display.CvarItems.EnableShowViaCvar(FRig.Item('main', 'gated'), CVAR_ENABLE));
  FRig.Host.SetCvarEntry('mode', 'insane');
  Assert.IsFalse(FRig.Display.CvarItems.EnableShowViaCvar(FRig.Item('main', 'gated'), CVAR_ENABLE));
end;

procedure TTestGuiDisplay.DovrebbeDareLaPosizioneSinistraSenzaDatiDelloSlider;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'slide');
  LItem.DataKind := gdkNone;
  Assert.AreEqual(Double(320), Double(FRig.Display.Sliders.ThumbPosition(LItem)));
  LItem.DataKind := gdkEditField;
  FRig.Host.SetCvarEntry('vol', '10');
  Assert.AreEqual(Double(416), Double(FRig.Display.Sliders.ThumbPosition(LItem)));
  Assert.AreEqual(Integer(WINDOW_LB_THUMB), FRig.Display.Sliders.OverSlider(LItem, 416, 120));
  Assert.AreEqual(0, FRig.Display.Sliders.OverSlider(LItem, 300, 120));
end;

procedure TTestGuiDisplay.DovrebbeLimitareIlValoreDelloSliderAgliEstremi;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'slide');
  FRig.Host.SetCvarEntry('vol', '-4');
  Assert.AreEqual(Double(320), Double(FRig.Display.Sliders.ThumbPosition(LItem)));
  FRig.Host.SetCvarEntry('vol', '99');
  Assert.AreEqual(Double(416), Double(FRig.Display.Sliders.ThumbPosition(LItem)));
  // with a text the slider starts after it
  LItem := FRig.Item('main', 'slide2');
  LItem.TextRect.X := 322;
  LItem.TextRect.W := 60;
  Assert.AreEqual(Double(390 + 96), Double(FRig.Display.Sliders.ThumbPosition(LItem)));
end;

procedure TTestGuiDisplay.DovrebbeLimitareIlTrascinamentoDelloSliderAlleSueEstremita;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'slide');
  FRig.Host.SetCvarEntry('vol', '5');
  FRig.Display.State.ScrollInfo.Item := LItem;
  FRig.Display.State.CaptureKind := gckSliderThumb;
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(10, 120);
  FRig.Display.ItemKeys.RunCapture;
  Assert.AreEqual('0.000000', string(FRig.Host.GetCvarString('vol')));
  FRig.Host.SetCursor(600, 120);
  FRig.Display.ItemKeys.RunCapture;
  Assert.AreEqual('10.000000', string(FRig.Host.GetCvarString('vol')));
end;

procedure TTestGuiDisplay.DovrebbeTrascinareIlPolliceOrizzontale;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'hlist');
  FRig.Display.State.ScrollInfo.Item := LItem;
  FRig.Display.State.ScrollInfo.XStart := 200;
  FRig.Display.State.ScrollInfo.NextScrollTime := 1000000;
  FRig.Display.State.ScrollInfo.NextAdjustTime := 1000000;
  FRig.Display.State.CaptureKind := gckListBoxThumb;
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(250, 150);
  FRig.Display.ItemKeys.RunCapture;
  // ( 250 - 217 - 8 ) * 4 / ( 66 - 16 ) = 2
  Assert.AreEqual(2, LItem.ListBox.StartPos);
  Assert.AreEqual(Double(250), Double(FRig.Display.State.ScrollInfo.XStart));
  FRig.Host.SetCursor(210, 150);
  FRig.Display.ItemKeys.RunCapture;
  Assert.AreEqual(0, LItem.ListBox.StartPos);
  FRig.Host.SetCursor(299, 150);
  FRig.Display.ItemKeys.RunCapture;
  Assert.AreEqual(4, LItem.ListBox.StartPos);
end;

procedure TTestGuiDisplay.DovrebbeNonFareNienteSeIlCursoreNonSiMuove;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'hlist');
  LItem.ListBox.StartPos := 3;
  FRig.Display.State.ScrollInfo.Item := LItem;
  FRig.Display.State.ScrollInfo.XStart := 250;
  FRig.Display.State.CaptureKind := gckListBoxThumb;
  FRig.Display.State.ItemCapture := LItem;
  FRig.Host.SetCursor(250, 150);
  FRig.Display.ItemKeys.RunCapture;
  Assert.AreEqual(3, LItem.ListBox.StartPos);
end;

procedure TTestGuiDisplay.DovrebbeNonFareNienteSenzaCattura;
begin
  FRig.Transcript.Clear;
  FRig.Display.ItemKeys.RunCapture;
  Assert.AreEqual(0, FRig.Transcript.Count);
end;

procedure TTestGuiDisplay.DovrebbeCancellareConControlHDopoIlLimiteDiPittura;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'edit');
  FRig.Host.SetCvarEntry('ed', 'abcd');
  LItem.CursorPos := 2;
  LItem.EditField.PaintOffset := 3;
  FRig.Display.State.EditingField := True;
  FRig.Display.State.EditItem := LItem;
  FRig.Display.MenuKeys.HandleKey(FRig.Menu('main'), K_CHAR_FLAG or 8, True);
  Assert.AreEqual(1, LItem.CursorPos);
  Assert.AreEqual(2, LItem.EditField.PaintOffset);
  Assert.AreEqual('acd', string(FRig.Host.GetCvarString('ed')));
end;

procedure TTestGuiDisplay.DovrebbeRifiutareUnaLetteraInUnCampoNumerico;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'num');
  FRig.Host.SetCvarEntry('nm', '12');
  FRig.Display.State.EditingField := True;
  FRig.Display.State.EditItem := LItem;
  FRig.Display.MenuKeys.HandleKey(FRig.Menu('main'), K_CHAR_FLAG or Ord('x'), True);
  // the field does not use the key: the editing ends
  Assert.IsFalse(FRig.Display.State.EditingField);
  Assert.AreEqual('12', string(FRig.Host.GetCvarString('nm')));
end;

procedure TTestGuiDisplay.DovrebbePassareAlCampoPrecedenteConLaFreccia;
var
  LMenu: TGuiMenu;
begin
  LMenu := FRig.Menu('main');
  FRig.Display.Stack.OpenByName('main');
  FRig.Host.SetCursor(330, 180);
  FRig.Display.Pointer.MouseMove(nil, 330, 180);
  FRig.Display.MenuKeys.HandleKey(LMenu, K_ENTER, True);
  Assert.IsTrue(FRig.Display.State.EditingField);
  FRig.Display.MenuKeys.HandleKey(LMenu, K_UPARROW, True);
  Assert.AreEqual('edit', string(FRig.Display.State.EditItem.Window.Name));
end;

procedure TTestGuiDisplay.DovrebbeSuonareIlSuonoDelTestoQuandoIlPuntoELiDentro;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'label');
  LItem.TextRect.X := 22;
  LItem.TextRect.Y := 214;
  LItem.TextRect.W := 40;
  LItem.TextRect.H := 14;
  LItem.FocusSound := 77;
  FRig.Display.Stack.Activate(FRig.Menu('main'));
  FRig.Transcript.Clear;
  Assert.IsTrue(FRig.Display.Pointer.SetFocus(LItem, 25, 205));
  Assert.AreEqual('host sound 77 6', FRig.Transcript[FRig.Transcript.Count - 1]);
  Assert.IsTrue((LItem.Window.Flags and WINDOW_HASFOCUS) <> 0);
end;

procedure TTestGuiDisplay.DovrebbeSegnareEToglierIlMouseOver;
var
  LItem: TGuiItem;
begin
  LItem := FRig.Item('main', 'play');
  TGuiPointer.SetMouseOver(LItem, True);
  Assert.IsTrue((LItem.Window.Flags and WINDOW_MOUSEOVER) <> 0);
  TGuiPointer.SetMouseOver(LItem, False);
  Assert.IsTrue((LItem.Window.Flags and WINDOW_MOUSEOVER) = 0);
  TGuiPointer.SetMouseOver(nil, True);
end;

procedure TTestGuiDisplay.DovrebbeDareIlPrimoItemConIlFocus;
var
  LMenu: TGuiMenu;
begin
  LMenu := FRig.Menu('main');
  Assert.IsNull(FRig.Display.Stack.GetFocusedItem(LMenu));
  Assert.IsNull(FRig.Display.Stack.GetFocusedItem(nil));
  FRig.Item('main', 'quit').Window.Flags := FRig.Item('main', 'quit').Window.Flags or WINDOW_HASFOCUS;
  Assert.AreEqual('quit', string(FRig.Display.Stack.GetFocusedItem(LMenu).Window.Name));
end;

procedure TTestGuiDisplay.DovrebbeFunzionareSenzaHostDiScript;
var
  LBare: TGuiDisplay;
  LItem: TGuiItem;
begin
  // a display without script and media hosts: the commands that need them do nothing
  LBare := TGuiFactory.CreateDisplay(FRig.Menus, FRig.Runner, FRig.Host, nil, nil);
  try
    FRig.Transcript.Clear;
    FRig.Host.SetCursor(330, 30);
    LBare.Stack.OpenByName('main');
    LBare.Pointer.MouseMove(nil, 330, 30);
    LItem := FRig.Item('main', 'yn');
    Assert.IsTrue(LBare.ItemKeys.HandleKey(LItem, K_MOUSE1, True));
    LItem := FRig.Item('main', 'slide');
    FRig.Host.SetCursor(368, 120);
    LItem.Window.Flags := LItem.Window.Flags or WINDOW_HASFOCUS;
    Assert.IsTrue(LBare.ItemKeys.HandleKey(LItem, K_ENTER, True));
    FRig.Host.SetCursor(330, 150);
    LBare.Pointer.MouseMove(nil, 330, 150);
    LBare.MenuKeys.HandleKey(FRig.Menu('main'), K_ENTER, True);
    LBare.MenuKeys.HandleKey(FRig.Menu('main'), K_CHAR_FLAG or Ord('z'), True);
    LBare.MenuKeys.HandleKey(FRig.Menu('main'), K_F12, True);
    // nothing reached the host that records its calls, except what the menu scripts do through the runner
    Assert.IsFalse(FRig.Transcript.IndexOf('host exec 2 "screenshot') >= 0);
  finally
    LBare.Free;
  end;
end;

end.
