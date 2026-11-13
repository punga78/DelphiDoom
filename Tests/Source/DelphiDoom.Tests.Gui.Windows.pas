{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the windows of a .gui of Doom 3      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Windows;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Gui.WindowFakes;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiWindows = class
  strict private
    FWorld: TGuiWindowWorld;
    procedure Start(const AText: AnsiString);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ILaFinestraSemplicePartecipaSoloAlDisegno;
    [Test]
    procedure UnaFinestraConAzioneEUnFiglioCheRiceveIlFocus;
    [Test]
    procedure IValoriPredefinitiDiUnaFinestra;
    [Test]
    procedure IColoriELaRettangoloSiLeggono;
    [Test]
    procedure ILeChiaviInterneImpostanoFlagECampi;
    [Test]
    procedure IlFontSiCercaNelFornitore;
    [Test]
    procedure ILaStringaDiTestoUsaLaLingua;
    [Test]
    procedure UnTestoDelGuiSiAggiornaDallaStato;
    [Test]
    procedure ChiaviSconosciuteDiventanoVariabili;
    [Test]
    procedure DefineFloatEDefineVec4;
    [Test]
    procedure UnaDefineVec4VaAlDesktop;
    [Test]
    procedure UnAnimationDefNascondeLaFinestraCheLoContiene;
    [Test]
    procedure UnaParolaDiGiocoNonPortataESaltataComeChiave;
    [Test]
    procedure ConUnBordoCalcolaRettangoloDelClient;
    [Test]
    procedure LaFinestraCentrataSiCalcolaDalPadre;
    [Test]
    procedure ClientToScreenSommaIRettangoliDeiPadri;
    [Test]
    procedure TrovaUnaFinestraPerNomeSenzaMaiuscole;
    [Test]
    procedure UnFileMancanteDaUnDesktopInvalido;
    [Test]
    procedure UnNomeVuotoNonSiCarica;
    [Test]
    procedure UnaFinestraChePrimaNonFinisceDaUnErrore;
    [Test]
    procedure InModoSeveroUnErroreDiLetturaSolleva;
    [Test]
    procedure LeVariabiliDelloStatoEIlDesktopNonInterattivo;
    [Test]
    procedure RicaricareSostituisceIlDesktop;
    [Test]
    procedure ChoiceTagliaLeScelteEIValori;
    [Test]
    procedure ChoiceConValoriNegativi;
    [Test]
    procedure ChoiceConVariabileDelGuiLeggeLaScelta;
    [Test]
    procedure SliderLeggeLeChiavi;
    [Test]
    procedure EditLeggeLeChiavi;
    [Test]
    procedure ListCalcolaLeColonne;
    [Test]
    procedure BindLegaIlNomeAlloStato;
    [Test]
    procedure RenderLeggeLeVariabili;
    [Test]
    procedure MarkerLeggeIColori;
    [Test]
    procedure FieldLeggeLeChiavi;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.Window.Choice, DelphiDoom.Gui.Window.Slider, DelphiDoom.Gui.Window.Edit,
  DelphiDoom.Gui.Window.List, DelphiDoom.Gui.Window.Bind, DelphiDoom.Gui.Window.Render,
  DelphiDoom.Gui.Window.Marker, DelphiDoom.Gui.Window.Field, DelphiDoom.Gui.Rectangle,
  DelphiDoom.Gui.UserInterface, DelphiDoom.Tests.Gui.WindowDump;

procedure TTestGuiWindows.Start(const AText: AnsiString);
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.Load(AText);
end;

procedure TTestGuiWindows.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestGuiWindows.ILaFinestraSemplicePartecipaSoloAlDisegno;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { rect 0, 0, 640, 480 windowDef plain { rect 1, 2, 3, 4 text "x" } ' +
    'windowDef busy { rect 0, 0, 5, 5 visible time > 10 } windowDef act { onAction { } } }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual(3, LDesktop.DrawWindowCount);
  Assert.AreEqual(2, LDesktop.ChildCount);
  Assert.IsTrue(LDesktop.DrawWindows[0].IsSimple);
  Assert.AreEqual('plain', string(LDesktop.DrawWindows[0].Window.Name));
  Assert.IsFalse(LDesktop.DrawWindows[1].IsSimple);
  Assert.AreEqual('busy', string(LDesktop.Children[0].Name));
  Assert.AreEqual('act', string(LDesktop.Children[1].Name));
  Assert.IsTrue(LDesktop.DrawWindows[0].Window.Parent = LDesktop);
end;

procedure TTestGuiWindows.UnaFinestraConAzioneEUnFiglioCheRiceveIlFocus;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { windowDef act { onAction { set "cmd" "x" } } windowDef plain { } }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.IsTrue((LDesktop.Children[0].Flags and WIN_CANFOCUS) <> 0);
  Assert.AreEqual(1, LDesktop.Children[0].Cursor);
  Assert.IsTrue(LDesktop.FocusedChild = LDesktop.Children[0]);
  Assert.IsTrue(FWorld.UserInterface.Interactive);
  Assert.IsTrue(LDesktop.Interactive);
end;

procedure TTestGuiWindows.IValoriPredefinitiDiUnaFinestra;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual('Desktop', string(LDesktop.Name));
  Assert.AreEqual(Cardinal(WIN_DESKTOP), LDesktop.Flags);
  Assert.IsTrue(LDesktop.Visible.Value);
  Assert.IsFalse(LDesktop.NoTime.Value);
  Assert.AreEqual(Single(0.35), LDesktop.TextScale.Value);
  Assert.AreEqual(Single(1.0), LDesktop.ForeColor.Value.X);
  Assert.AreEqual(Single(0.0), LDesktop.BackColor.Value.X);
  Assert.AreEqual(Single(640.0), LDesktop.ForceAspectWidth);
  Assert.AreEqual(Single(480.0), LDesktop.ForceAspectHeight);
  Assert.AreEqual(Single(1.0), LDesktop.MatScaleX);
  Assert.AreEqual(-1, LDesktop.TimeLine);
  Assert.IsFalse(FWorld.UserInterface.Interactive);
end;

procedure TTestGuiWindows.IColoriELaRettangoloSiLeggono;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { rect 10, 20, 300, 200 backcolor 1, 0.5, 0, 1 forecolor 0, 0, 0, 1 matcolor 1, 1, 1, 0.5 }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual(Single(300.0), LDesktop.Rect.Value.W);
  Assert.AreEqual(Single(0.5), LDesktop.BackColor.Value.Y);
  Assert.AreEqual(Single(0.0), LDesktop.ForeColor.Value.X);
  Assert.AreEqual(Single(0.5), LDesktop.MatColor.Value.W);
  Assert.AreEqual(Single(10.0), LDesktop.DrawRect.X);
  Assert.AreEqual(Single(160.0), LDesktop.Origin.X);
  Assert.AreEqual(Single(120.0), LDesktop.Origin.Y);
end;

procedure TTestGuiWindows.ILeChiaviInterneImpostanoFlagECampi;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { bordersize 2 modal 1 nocursor 1 menugui 1 noclip 0 showtime 1 invertrect 1 ' +
    'shadow 2 textalign 1 textalignx 3 textaligny 4 matscalex 2 forceaspectwidth 800 shear 1, 2 ' +
    'comment "una nota" name "Renamed" }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual('Renamed', string(LDesktop.Name));
  Assert.AreEqual('una nota', string(LDesktop.Comment));
  Assert.IsTrue((LDesktop.Flags and (WIN_BORDER or WIN_MODAL or WIN_NOCURSOR or WIN_MENUGUI or WIN_SHOWTIME or
    WIN_INVERTRECT)) = (WIN_BORDER or WIN_MODAL or WIN_NOCURSOR or WIN_MENUGUI or WIN_SHOWTIME or WIN_INVERTRECT));
  Assert.IsTrue((LDesktop.Flags and WIN_NOCLIP) = 0);
  Assert.AreEqual(Single(2.0), LDesktop.BorderSize);
  Assert.AreEqual(2, LDesktop.TextShadow);
  Assert.AreEqual(1, LDesktop.TextAlign);
  Assert.AreEqual(Single(3.0), LDesktop.TextAlignX);
  Assert.AreEqual(Single(4.0), LDesktop.TextAlignY);
  Assert.AreEqual(Single(2.0), LDesktop.MatScaleX);
  Assert.AreEqual(Single(800.0), LDesktop.ForceAspectWidth);
  Assert.AreEqual(Single(1.0), LDesktop.Shear.X);
  Assert.AreEqual(Single(2.0), LDesktop.Shear.Y);
end;

procedure TTestGuiWindows.IlFontSiCercaNelFornitore;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create(nil, nil, TGuiWindowFakeFonts.Create);
  FWorld.Load('windowDef Desktop { font "fonts/a" windowDef c { font "fonts/b" } windowDef d { font "fonts/a" } }');
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.FontNum);
  Assert.AreEqual(2, FWorld.UserInterface.Desktop.DrawWindows[0].Window.FontNum);
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.DrawWindows[1].Window.FontNum);
end;

procedure TTestGuiWindows.ILaStringaDiTestoUsaLaLingua;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create(nil, TGuiWindowFakeLanguage.Create('#str_07', 'Salve'));
  FWorld.Load('windowDef Desktop { text "#str_07" }');
  Assert.AreEqual('Salve', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindows.UnTestoDelGuiSiAggiornaDallaStato;
begin
  Start('windowDef Desktop { text "gui::title" }');
  Assert.IsTrue(FWorld.UserInterface.Desktop.UpdateVarCount > 0);
  Assert.IsTrue(FWorld.UserInterface.Desktop.ContainsStateVars);
  FWorld.UserInterface.SetStateString('title', 'Bella');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual('Bella', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindows.ChiaviSconosciuteDiventanoVariabili;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { count 12 ratio 1.5 title hello }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual(3, LDesktop.DefinedVarCount);
  Assert.AreEqual('12', string(LDesktop.DefinedVars[0].AsText));
  Assert.AreEqual('1.500000', string(LDesktop.DefinedVars[1].AsText));
  Assert.AreEqual('hello', string(LDesktop.DefinedVars[2].AsText));
  Assert.AreEqual('ratio', string(LDesktop.DefinedVars[1].GetName));
end;

procedure TTestGuiWindows.DefineFloatEDefineVec4;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { definefloat Speed 2.5 float other 1 + 1 }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual(2, LDesktop.DefinedVarCount);
  // the name is in lower case; the value is the one of the register evaluated after the parse
  Assert.AreEqual('speed', string(LDesktop.DefinedVars[0].GetName));
  Assert.AreEqual('2.500000', string(LDesktop.DefinedVars[0].AsText));
  Assert.AreEqual('2.000000', string(LDesktop.DefinedVars[1].AsText));
  Assert.IsNotNull(LDesktop.RegList.FindReg('SPEED'));
end;

procedure TTestGuiWindows.UnaDefineVec4VaAlDesktop;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { windowDef child { definevec4 tint 1, 0.5, 0.25, 1 } windowDef x { onAction { } } }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual(1, LDesktop.DefinedVarCount);
  Assert.AreEqual('tint', string(LDesktop.DefinedVars[0].GetName));
  Assert.AreEqual(0, LDesktop.DrawWindows[0].Window.DefinedVarCount);
end;

procedure TTestGuiWindows.UnAnimationDefNascondeLaFinestraCheLoContiene;
var
  LDesktop: TGuiWindow;
begin
  // as in the original: the window that holds the animationDef is hidden and emptied, not the new one
  Start('windowDef Desktop { animationDef anim { rect 1, 1, 1, 1 } }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.IsFalse(LDesktop.Visible.Value);
  Assert.AreEqual(1, LDesktop.DrawWindowCount);
end;

procedure TTestGuiWindows.UnaParolaDiGiocoNonPortataESaltataComeChiave;
begin
  Start('windowDef Desktop { gameSSDDef 5 text "after" }');
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.DefinedVarCount);
  Assert.AreEqual('after', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindows.ConUnBordoCalcolaRettangoloDelClient;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { rect 10, 20, 100, 80 bordersize 4 textalignx 1 textaligny 2 }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual(Single(14.0), LDesktop.ClientRect.X);
  Assert.AreEqual(Single(96.0), LDesktop.ClientRect.W);
  Assert.AreEqual(Single(76.0), LDesktop.ClientRect.H);
  // the text rectangle: 2 inside the client rectangle and the alignment
  Assert.AreEqual(Single(17.0), LDesktop.TextRect.X);
  Assert.AreEqual(Single(28.0), LDesktop.TextRect.Y);
  Assert.AreEqual(Single(94.0), LDesktop.TextRect.W);
end;

procedure TTestGuiWindows.LaFinestraCentrataSiCalcolaDalPadre;
var
  LChild: TGuiWindow;
begin
  Start('windowDef Desktop { rect 0, 0, 640, 480 windowDef c { rect 0, 0, 100, 50 } }');
  LChild := FWorld.UserInterface.Desktop.DrawWindows[0].Window;
  LChild.SetFlag(WIN_HCENTER);
  LChild.CalcClientRect(0, 0);
  Assert.AreEqual(Single(270.0), LChild.DrawRect.X);
  LChild.ClearFlag(WIN_HCENTER);
  LChild.SetFlag(WIN_VCENTER);
  LChild.CalcClientRect(5, 5);
  Assert.AreEqual(Single(215.0 + 5), LChild.DrawRect.Y);
end;

procedure TTestGuiWindows.ClientToScreenSommaIRettangoliDeiPadri;
var
  LChild: TGuiWindow;
  LRect: TGuiRectangle;
begin
  Start('windowDef Desktop { rect 100, 50, 640, 480 windowDef c { rect 10.7, 20, 100, 50 } }');
  LChild := FWorld.UserInterface.Desktop.DrawWindows[0].Window;
  LRect := TGuiRectangle.Create(1, 1, 5, 5);
  LChild.ClientToScreen(LRect);
  // the sums are integers: 10.7 -> 10
  Assert.AreEqual(Single(111.0), LRect.X);
  Assert.AreEqual(Single(71.0), LRect.Y);
  LChild.ScreenToClient(LRect);
  Assert.AreEqual(Single(1.0), LRect.X);
end;

procedure TTestGuiWindows.TrovaUnaFinestraPerNomeSenzaMaiuscole;
var
  LSimple: Boolean;
begin
  Start('windowDef Desktop { windowDef Outer { onAction { } windowDef Inner { rect 1, 1, 1, 1 } } }');
  Assert.IsTrue(FWorld.UserInterface.Desktop.FindDrawWindow('inner', LSimple) <> nil);
  Assert.IsTrue(LSimple);
  Assert.IsTrue(FWorld.UserInterface.Desktop.FindDrawWindow('OUTER', LSimple) <> nil);
  Assert.IsFalse(LSimple);
  Assert.IsTrue(FWorld.UserInterface.Desktop.FindDrawWindow('desktop', LSimple) = FWorld.UserInterface.Desktop);
  Assert.IsTrue(FWorld.UserInterface.Desktop.FindDrawWindow('nope', LSimple) = nil);
end;

procedure TTestGuiWindows.UnFileMancanteDaUnDesktopInvalido;
var
  LDesktop: TGuiWindow;
  LIndex: Integer;
  LFound: Boolean;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  Assert.IsTrue(FWorld.UserInterface.InitFromFile('missing.gui'));
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual('Desktop', string(LDesktop.Name));
  Assert.AreEqual('Invalid GUI: missing.gui', string(LDesktop.Text.AsText));
  Assert.AreEqual(Single(640.0), LDesktop.Rect.Value.W);
  Assert.AreEqual(Single(1.0), LDesktop.BackColor.Value.W);
  Assert.IsTrue((LDesktop.Flags and WIN_DESKTOP) <> 0);
  LFound := False;
  for LIndex := 0 to FWorld.Lines.Count - 1 do
    if FWorld.Lines[LIndex] = 'W: Couldn''t load gui: ''missing.gui''' then
      LFound := True;
  Assert.IsTrue(LFound);
end;

procedure TTestGuiWindows.UnNomeVuotoNonSiCarica;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  Assert.IsFalse(FWorld.UserInterface.InitFromFile(''));
  Assert.IsTrue(FWorld.UserInterface.Desktop = nil);
end;

procedure TTestGuiWindows.UnaFinestraChePrimaNonFinisceDaUnErrore;
var
  LIndex: Integer;
  LFound: Boolean;
begin
  Start('windowDef Desktop { text "a" ');
  LFound := False;
  for LIndex := 0 to FWorld.Lines.Count - 1 do
    if Pos('Unexpected end of file', FWorld.Lines[LIndex]) > 0 then
      LFound := True;
  Assert.IsTrue(LFound);
  // the window keeps what it read before
  Assert.AreEqual('a', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindows.InModoSeveroUnErroreDiLetturaSolleva;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.UserInterface.StrictParsing := True;
  FWorld.Files.Add('bad.gui', 'windowDef Desktop { text "a" ');
  Assert.WillRaise(
    procedure
    begin
      FWorld.UserInterface.InitFromFile('bad.gui');
    end, EGuiWindowParseException);
end;

procedure TTestGuiWindows.LeVariabiliDelloStatoEIlDesktopNonInterattivo;
begin
  Start('windowDef Desktop { windowDef a { onAction { } } }');
  Assert.IsTrue(FWorld.UserInterface.Interactive);
  FWorld.UserInterface.SetStateBool('noninteractive', True);
  FWorld.UserInterface.StateChanged(10, False);
  Assert.IsFalse(FWorld.UserInterface.Interactive);
  Assert.AreEqual(10, FWorld.UserInterface.Time);
  FWorld.UserInterface.SetStateInt('n', 4);
  FWorld.UserInterface.SetStateFloat('f', 1.5);
  Assert.AreEqual(4, FWorld.UserInterface.GetStateInt('n'));
  Assert.AreEqual(Single(1.5), FWorld.UserInterface.GetStateFloat('f'));
  Assert.AreEqual('test.gui', string(FWorld.UserInterface.GetStateString('name')));
  Assert.AreEqual('Test Text!', string(FWorld.UserInterface.GetStateString('text')));
  FWorld.UserInterface.DeleteStateVar('n');
  Assert.AreEqual(0, FWorld.UserInterface.GetStateInt('n'));
  Assert.AreEqual('x', string(FWorld.UserInterface.GetStateString('missing', 'x')));
end;

procedure TTestGuiWindows.RicaricareSostituisceIlDesktop;
begin
  Start('windowDef Desktop { text "one" }');
  FWorld.Files.Add('second.gui', 'windowDef Desktop { text "two" }');
  FWorld.UserInterface.InitFromFile('second.gui');
  Assert.AreEqual('two', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindows.ChoiceTagliaLeScelteEIValori;
var
  LChoice: TGuiChoiceWindow;
begin
  Start('windowDef Desktop { choiceDef c { rect 0, 0, 100, 20 choices "One;Two Words;Three" values "1;2;3" ' +
    'choicetype 0 currentchoice 1 } }');
  LChoice := FWorld.UserInterface.Desktop.Children[0] as TGuiChoiceWindow;
  Assert.AreEqual(3, LChoice.Choices.Count);
  Assert.AreEqual('Two Words', string(LChoice.Choices[1]));
  Assert.AreEqual('3', string(LChoice.Values[2]));
  Assert.AreEqual(1, LChoice.CurrentChoice);
  Assert.IsTrue((LChoice.Flags and WIN_CANFOCUS) <> 0);
end;

procedure TTestGuiWindows.ChoiceConValoriNegativi;
var
  LChoice: TGuiChoiceWindow;
begin
  Start('windowDef Desktop { choiceDef c { choices "a;b" values "-1;5" } }');
  LChoice := FWorld.UserInterface.Desktop.Children[0] as TGuiChoiceWindow;
  Assert.AreEqual('-1', string(LChoice.Values[0]));
  Assert.AreEqual('5', string(LChoice.Values[1]));
end;

procedure TTestGuiWindows.ChoiceConVariabileDelGuiLeggeLaScelta;
var
  LChoice: TGuiChoiceWindow;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.UserInterface.SetStateInt('gui::pick', 2);
  FWorld.Load('windowDef Desktop { choiceDef c { choices "a;b;c" gui "gui::pick" } }');
  LChoice := FWorld.UserInterface.Desktop.Children[0] as TGuiChoiceWindow;
  Assert.AreEqual(3, LChoice.Choices.Count);
  Assert.AreEqual(2, LChoice.CurrentChoice);
end;

procedure TTestGuiWindows.SliderLeggeLeChiavi;
var
  LSlider: TGuiSliderWindow;
begin
  Start('windowDef Desktop { sliderDef s { low 10 high 20 step 2 vertical 1 verticalflip 1 scrollbar 1 ' +
    'thumbshader "t/x" } }');
  LSlider := FWorld.UserInterface.Desktop.Children[0] as TGuiSliderWindow;
  Assert.AreEqual(Single(10.0), LSlider.Low);
  Assert.AreEqual(Single(20.0), LSlider.High);
  Assert.AreEqual(Single(2.0), LSlider.StepSize);
  Assert.IsTrue(LSlider.Vertical and LSlider.VerticalFlip and LSlider.Scrollbar);
  Assert.AreEqual('t/x', string(LSlider.ThumbShader));
  Assert.IsTrue((LSlider.Flags and (WIN_HOLDCAPTURE or WIN_CANFOCUS)) = (WIN_HOLDCAPTURE or WIN_CANFOCUS));
end;

procedure TTestGuiWindows.EditLeggeLeChiavi;
var
  LEdit: TGuiEditWindow;
begin
  Start('windowDef Desktop { editDef e { maxchars 20 numeric 1 wrap 1 readonly 1 password 1 cvarMax 3 ' +
    'source "a.txt" } editDef z { maxchars 0 } }');
  LEdit := FWorld.UserInterface.Desktop.Children[0] as TGuiEditWindow;
  Assert.AreEqual(20, LEdit.MaxChars);
  Assert.IsTrue(LEdit.Numeric and LEdit.Wrap and LEdit.ReadOnly and LEdit.Password.Value);
  Assert.AreEqual(3, LEdit.CvarMax);
  Assert.AreEqual('a.txt', string(LEdit.TextSourceFile));
  Assert.AreEqual(10, (FWorld.UserInterface.Desktop.Children[1] as TGuiEditWindow).MaxChars);
end;

procedure TTestGuiWindows.ListCalcolaLeColonne;
var
  LList: TGuiListWindow;
begin
  Start('windowDef Desktop { listDef l { tabstops "0, 100, 200" tabaligns "0,1,2" horizontal 1 multipleSel 1 ' +
    'listname "items" mtr_icon "guis/icon" } }');
  LList := FWorld.UserInterface.Desktop.Children[0] as TGuiListWindow;
  Assert.AreEqual(3, LList.TabInfo.Count);
  Assert.AreEqual(0, LList.TabInfo[0].Start);
  Assert.AreEqual(96, LList.TabInfo[0].Width);
  Assert.AreEqual(1, LList.TabInfo[1].Align);
  Assert.AreEqual(-1, LList.TabInfo[2].Width);
  Assert.AreEqual(0, LList.TabInfo[2].TabType);
  Assert.IsTrue(LList.Horizontal and LList.MultipleSel);
  Assert.AreEqual('items', string(LList.ListName));
  Assert.AreEqual('guis/icon', string(LList.IconMaterials['mtr_icon']));
end;

procedure TTestGuiWindows.BindLegaIlNomeAlloStato;
var
  LBind: TGuiBindWindow;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.UserInterface.SetStateString('attack', 'MOUSE1');
  FWorld.Load('windowDef Desktop { bindDef b { bind "attack" } }');
  LBind := FWorld.UserInterface.Desktop.Children[0] as TGuiBindWindow;
  Assert.AreEqual('attack', string(LBind.BindName.GetName));
  Assert.AreEqual('MOUSE1', string(LBind.BindName.AsText));
  Assert.IsTrue((LBind.Flags and WIN_HOLDCAPTURE) <> 0);
end;

procedure TTestGuiWindows.RenderLeggeLeVariabili;
var
  LRender: TGuiRenderWindow;
begin
  Start('windowDef Desktop { renderDef r { model "m.md5mesh" anim "idle" animClass "idAnimated" ' +
    'lightOrigin 0, 0, 10, 1 } }');
  LRender := FWorld.UserInterface.Desktop.Children[0] as TGuiRenderWindow;
  Assert.AreEqual('m.md5mesh', string(LRender.ModelName.AsText));
  Assert.AreEqual('idle', string(LRender.AnimName.AsText));
  Assert.AreEqual('idAnimated', string(LRender.AnimClass));
  Assert.AreEqual(Single(10.0), LRender.LightOrigin.Value.Z);
  Assert.AreEqual(Single(-128.0), LRender.ViewOffset.Value.X);
  Assert.IsTrue(LRender.NeedsRender.Value);
end;

procedure TTestGuiWindows.MarkerLeggeIColori;
var
  LMarker: TGuiMarkerWindow;
begin
  Start('windowDef Desktop { markerDef m { markerMat "a" markerStop "b" markerColor 1, 0.5, 0, 1 } }');
  LMarker := FWorld.UserInterface.Desktop.Children[0] as TGuiMarkerWindow;
  Assert.AreEqual('a', string(LMarker.MarkerMaterial));
  Assert.AreEqual('b', string(LMarker.MarkerStopMaterial));
  Assert.AreEqual(Single(0.5), LMarker.MarkerColor.Y);
end;

procedure TTestGuiWindows.FieldLeggeLeChiavi;
var
  LField: TGuiFieldWindow;
begin
  Start('windowDef Desktop { fieldDef f { cursorvar "cv" showcursor 1 } }');
  LField := FWorld.UserInterface.Desktop.Children[0] as TGuiFieldWindow;
  Assert.AreEqual('cv', string(LField.CursorVar));
  Assert.IsTrue(LField.ShowCursor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiWindows);

end.
