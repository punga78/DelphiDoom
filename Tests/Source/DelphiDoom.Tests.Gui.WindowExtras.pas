{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the variables bound to the state,    }
{  the names of the windows, errors of the scripts                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WindowExtras;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Gui.WindowFakes;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiWindowExtras = class
  strict private
    FWorld: TGuiWindowWorld;
    procedure Start(const AText: AnsiString);
    function HasLine(const AText: string): Boolean;
    function Contains(const AText: string): Boolean;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaBoolLegataLeggeScriveEAggiorna;
    [Test]
    procedure UnIntLegatoLeggeScriveEAggiorna;
    [Test]
    procedure UnFloatLegatoLeggeScriveEAggiorna;
    [Test]
    procedure UnVec2LegatoLeggeScriveEAggiorna;
    [Test]
    procedure UnVec3LegatoLeggeScriveEAggiorna;
    [Test]
    procedure UnVec4LegatoLeggeScriveEAggiorna;
    [Test]
    procedure UnRettangoloLegatoLeggeScriveEAggiorna;
    [Test]
    procedure UnaStringaLegataCopiaConAssignVar;
    [Test]
    procedure UnaVariabileNonLegataNonAggiornaNulla;
    [Test]
    procedure IVariabiliDiOgniFinestraSiTrovanoPerNome;
    [Test]
    procedure UnaVariabileDiUnaFinestraSiTrovaConIlNomeDellaFinestra;
    [Test]
    procedure ResetTimeConDueParametriAgisceSuUnAltraFinestra;
    [Test]
    procedure SetConUnaVariabileDiUnAltraFinestraCopiaIlValore;
    [Test]
    procedure UnaTransitionTraRettangoliAggiustaLeCoordinate;
    [Test]
    procedure UnaGraffaInPiuInUnoScriptDaUnErrore;
    [Test]
    procedure UnoScriptNonChiusoDaUnErrore;
    [Test]
    procedure UnOnTimeSenzaCorpoDaUnErrore;
    [Test]
    procedure PlayDaUnAvvisoEVieneSaltato;
    [Test]
    procedure UnaShearSenzaVirgolaDaUnErrore;
    [Test]
    procedure ChoiceDiTipoStringaCercaNelleScelte;
    [Test]
    procedure UnaFinestraTrovataDaIlProprioPadre;
    [Test]
    procedure NumTransitionsContaIFigli;
    [Test]
    procedure UnaFinestraRiparsataSiSvuota;
    [Test]
    procedure LeFinestreSottoUnaStessaFinestraSiRiparsanoPerNome;
    [Test]
    procedure UnaListaLeggeTuttiITabEIconeDelleColonne;
    [Test]
    procedure UnNumeroNegativoSbagliatoEUnaVariabileDiTipoSbagliatoDannoAvvisi;
    [Test]
    procedure UnVec4InUnEspressioneConEsenzaIndice;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Scanner.IdDict, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.Window.Choice, DelphiDoom.Gui.Window.Edit,
  DelphiDoom.Gui.Window.Render, DelphiDoom.Gui.Window.Slider, DelphiDoom.Gui.Window.Bind, DelphiDoom.Gui.Window.List,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Int, DelphiDoom.Gui.WinVar.Float,
  DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.WinVar.Vec2, DelphiDoom.Gui.WinVar.Vec3, DelphiDoom.Gui.WinVar.Vec4,
  DelphiDoom.Gui.WinVar.Rectangle;

procedure TTestGuiWindowExtras.Start(const AText: AnsiString);
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.Load(AText);
end;

function TTestGuiWindowExtras.HasLine(const AText: string): Boolean;
begin
  Result := FWorld.Lines.IndexOf(AText) >= 0;
end;

function TTestGuiWindowExtras.Contains(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to FWorld.Lines.Count - 1 do
    if Pos(AText, FWorld.Lines[LIndex]) > 0 then
      Exit(True);
end;

procedure TTestGuiWindowExtras.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestGuiWindowExtras.UnaBoolLegataLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinBool;
  LCopy: TGuiWinBool;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinBool.Create;
  LCopy := TGuiWinBool.Create;
  try
    LDict.SetBool('b', True);
    LVar.Init('gui::b', LDict);
    Assert.IsTrue(LVar.Value);
    LVar.Value := False;
    Assert.IsFalse(LDict.GetBool('b'));
    LVar.SetFromText('1');
    Assert.IsTrue(LDict.GetBool('b'));
    LDict.SetBool('b', False);
    LVar.Update;
    Assert.IsFalse(LVar.Value);
    LCopy.AssignVar(LVar);
    Assert.IsTrue(LCopy.NeedsUpdate);
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnIntLegatoLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinInt;
  LCopy: TGuiWinInt;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinInt.Create;
  LCopy := TGuiWinInt.Create;
  try
    LDict.SetInt('i', 5);
    LVar.Init('gui::i', LDict);
    Assert.AreEqual(5, LVar.Value);
    LDict.SetInt('i', 9);
    LVar.Update;
    Assert.AreEqual(9, LVar.Value);
    LCopy.AssignVar(LVar);
    Assert.AreEqual(9, LCopy.Value);
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnFloatLegatoLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinFloat;
  LCopy: TGuiWinFloat;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinFloat.Create;
  LCopy := TGuiWinFloat.Create;
  try
    LDict.SetFloat('f', 1.5);
    LVar.Init('gui::f', LDict);
    Assert.AreEqual(Single(1.5), LVar.Value);
    LVar.SetFromText('2.5');
    Assert.AreEqual(Single(2.5), LDict.GetFloat('f'));
    LDict.SetFloat('f', 4);
    LVar.Update;
    Assert.AreEqual(Single(4.0), LVar.Value);
    LCopy.AssignVar(LVar);
    Assert.AreEqual(Single(4.0), LCopy.Value);
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnVec2LegatoLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinVec2;
  LCopy: TGuiWinVec2;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinVec2.Create;
  LCopy := TGuiWinVec2.Create;
  try
    LDict.SetVec2('v', TIdVec2.Create(1, 2));
    LVar.Init('gui::v', LDict);
    Assert.AreEqual(Single(2.0), LVar.Value.Y);
    LVar.SetFromText('3 4');
    Assert.AreEqual(Single(4.0), LDict.GetVec2('v').Y);
    LDict.SetVec2('v', TIdVec2.Create(7, 8));
    LVar.Update;
    Assert.AreEqual(Single(7.0), LVar.Value.X);
    LCopy.AssignVar(LVar);
    Assert.AreEqual(Single(8.0), LCopy.Value.Y);
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnVec3LegatoLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinVec3;
  LCopy: TGuiWinVec3;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinVec3.Create;
  LCopy := TGuiWinVec3.Create;
  try
    LDict.SetVector('v', TIdVec3.Create(1, 2, 3));
    LVar.Init('gui::v', LDict);
    Assert.AreEqual(Single(3.0), LVar.Value.Z);
    LVar.SetFromText('4 5 6');
    Assert.AreEqual(Single(6.0), LDict.GetVector('v').Z);
    LDict.SetVector('v', TIdVec3.Create(7, 8, 9));
    LVar.Update;
    Assert.AreEqual(Single(7.0), LVar.Value.X);
    LCopy.AssignVar(LVar);
    Assert.AreEqual(Single(9.0), LCopy.Value.Z);
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnVec4LegatoLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinVec4;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinVec4.Create;
  try
    LDict.SetVec4('c', TIdVec4.Create(1, 2, 3, 4));
    LVar.Init('gui::c', LDict);
    Assert.AreEqual(Single(4.0), LVar.Value.W);
    LVar.Zero;
    Assert.AreEqual(Single(0.0), LDict.GetVec4('c').W);
    LDict.SetVec4('c', TIdVec4.Create(5, 6, 7, 8));
    LVar.Update;
    Assert.AreEqual(Single(5.0), LVar.X);
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnRettangoloLegatoLeggeScriveEAggiorna;
var
  LDict: TIdDict;
  LVar: TGuiWinRectangle;
  LCopy: TGuiWinRectangle;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinRectangle.Create;
  LCopy := TGuiWinRectangle.Create;
  try
    LDict.SetVec4('r', TIdVec4.Create(1, 2, 3, 4));
    LVar.Init('gui::r', LDict);
    Assert.AreEqual(Single(4.0), LVar.Value.H);
    LVar.SetFromText('5 6 7 8');
    Assert.AreEqual(Single(7.0), LDict.GetVec4('r').Z);
    LDict.SetVec4('r', TIdVec4.Create(9, 10, 11, 12));
    LVar.Update;
    Assert.AreEqual(Single(11.0), LVar.Value.W);
    LCopy.AssignVar(LVar);
    Assert.AreEqual(Single(12.0), LCopy.Value.H);
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnaStringaLegataCopiaConAssignVar;
var
  LDict: TIdDict;
  LVar: TGuiWinStr;
  LCopy: TGuiWinStr;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinStr.Create;
  LCopy := TGuiWinStr.Create;
  try
    LDict.SetValue('s', 'one');
    LVar.Init('gui::s', LDict);
    LCopy.AssignVar(LVar);
    Assert.AreEqual('one', string(LCopy.AsText));
    Assert.AreEqual(3, LCopy.Length);
    LVar.Value := 'twotwo';
    Assert.AreEqual('twotwo', string(LDict.GetString('s')));
  finally
    LCopy.Free;
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWindowExtras.UnaVariabileNonLegataNonAggiornaNulla;
var
  LFloat: TGuiWinFloat;
  LBool: TGuiWinBool;
  LInt: TGuiWinInt;
  LVec: TGuiWinVec4;
  LRect: TGuiWinRectangle;
  LVec2: TGuiWinVec2;
  LVec3: TGuiWinVec3;
  LString: TGuiWinStr;
begin
  LFloat := TGuiWinFloat.Create;
  LBool := TGuiWinBool.Create;
  LInt := TGuiWinInt.Create;
  LVec := TGuiWinVec4.Create;
  LRect := TGuiWinRectangle.Create;
  LVec2 := TGuiWinVec2.Create;
  LVec3 := TGuiWinVec3.Create;
  LString := TGuiWinStr.Create;
  try
    LFloat.Value := 3;
    LBool.Value := True;
    LInt.Value := 3;
    LVec.Zero;
    LFloat.Update;
    LBool.Update;
    LInt.Update;
    LVec.Update;
    LRect.Update;
    LVec2.Update;
    LVec3.Update;
    LString.Update;
    Assert.AreEqual(Single(3.0), LFloat.Value);
    Assert.IsTrue(LBool.Value);
    Assert.AreEqual(3, LInt.Value);
    Assert.AreEqual(Single(0.0), LVec.X);
    Assert.AreEqual(Single(0.0), LRect.X);
    Assert.AreEqual('', string(LString.AsText));
  finally
    LString.Free;
    LVec3.Free;
    LVec2.Free;
    LRect.Free;
    LVec.Free;
    LInt.Free;
    LBool.Free;
    LFloat.Free;
  end;
end;

procedure TTestGuiWindowExtras.IVariabiliDiOgniFinestraSiTrovanoPerNome;
var
  LDesktop: TGuiWindow;
  LOwner: IGuiWindowNode;

  function Found(const AWindow: TGuiWindow; const AName: AnsiString): Boolean;
  begin
    Result := Assigned(AWindow.GetWinVarByName(AName, False, LOwner));
  end;

begin
  Start('windowDef Desktop { choiceDef c { } editDef e { } sliderDef s { } bindDef b { } renderDef r { } }');
  LDesktop := FWorld.UserInterface.Desktop;
  for var LName in ['notime', 'background', 'visible', 'rect', 'backColor', 'matColor', 'foreColor', 'hoverColor',
    'borderColor', 'textScale', 'rotate', 'noEvents', 'text', 'backGroundName', 'hidecursor'] do
    Assert.IsTrue(Found(LDesktop, AnsiString(LName)), LName);
  Assert.IsFalse(Found(LDesktop, 'nothing'));
  for var LName in ['choices', 'values', 'cvar', 'gui', 'liveUpdate', 'updateGroup'] do
    Assert.IsTrue(Found(LDesktop.Children[0], AnsiString(LName)), LName);
  for var LName in ['cvar', 'password', 'liveUpdate', 'cvarGroup'] do
    Assert.IsTrue(Found(LDesktop.Children[1], AnsiString(LName)), LName);
  for var LName in ['value', 'cvar', 'liveUpdate', 'cvarGroup'] do
    Assert.IsTrue(Found(LDesktop.Children[2], AnsiString(LName)), LName);
  Assert.IsTrue(Found(LDesktop.Children[3], 'bind'));
  for var LName in ['model', 'anim', 'lightOrigin', 'lightColor', 'modelOrigin', 'modelRotate', 'viewOffset',
    'needsRender'] do
    Assert.IsTrue(Found(LDesktop.Children[4], AnsiString(LName)), LName);
end;

procedure TTestGuiWindowExtras.UnaVariabileDiUnaFinestraSiTrovaConIlNomeDellaFinestra;
var
  LOwner: IGuiWindowNode;
  LVar: TGuiWinVar;
begin
  Start('windowDef Desktop { windowDef plain { rect 1, 2, 3, 4 text "x" } windowDef act { onAction { } } }');
  // a simple window answers with fewer names than a window
  LVar := FWorld.UserInterface.Desktop.GetWinVarByName('plain::text', True, LOwner);
  Assert.IsNotNull(LVar);
  Assert.AreEqual('x', string(LVar.AsText));
  Assert.IsNotNull(LOwner);
  Assert.IsNull(FWorld.UserInterface.Desktop.GetWinVarByName('plain::hovercolor', True, LOwner));
  LVar := FWorld.UserInterface.Desktop.GetWinVarByName('act::hovercolor', True, LOwner);
  Assert.IsNotNull(LVar);
  Assert.IsNull(FWorld.UserInterface.Desktop.GetWinVarByName('nobody::text', True, LOwner));
  // without a fixup the names of other windows are not looked up
  Assert.IsNull(FWorld.UserInterface.Desktop.GetWinVarByName('plain::text', False, LOwner));
end;

procedure TTestGuiWindowExtras.ResetTimeConDueParametriAgisceSuUnAltraFinestra;
begin
  Start('windowDef Desktop { windowDef other { onAction { } onTime 0 { set "cmd" "again" } } ' +
    'onActivate { resetTime "other" "0" } }');
  FWorld.UserInterface.RunFrame(16);
  FWorld.UserInterface.Desktop.Children[0].Command := '';
  FWorld.UserInterface.Activate(True, 100);
  Assert.AreEqual(100, FWorld.UserInterface.Desktop.Children[0].TimeLine);
  FWorld.UserInterface.RunFrame(120);
  Assert.AreEqual('again', string(FWorld.UserInterface.Desktop.Children[0].Command));
end;

procedure TTestGuiWindowExtras.SetConUnaVariabileDiUnAltraFinestraCopiaIlValore;
begin
  Start('windowDef Desktop { windowDef other { rect 1, 2, 3, 4 onAction { } } onActivate { set "text" "$other::text" } }');
  FWorld.UserInterface.Desktop.Children[0].Text.Value := 'moved';
  FWorld.UserInterface.Activate(True, 1);
  Assert.AreEqual('moved', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindowExtras.UnaTransitionTraRettangoliAggiustaLeCoordinate;
var
  LMover: TGuiWindow;
begin
  Start('windowDef Desktop { rect 100, 50, 640, 480 windowDef box { rect 10, 20, 30, 40 } ' +
    'windowDef mover { rect 0, 0, 5, 5 onAction { } onActivate { transition "rect" "$box::rect" "0 0 1 1" "100" } } }');
  LMover := FWorld.UserInterface.Desktop.Children[0];
  FWorld.UserInterface.Activate(True, 0);
  FWorld.UserInterface.RunFrame(50);
  // from the rectangle of box in the space of its parent, to the space of the parent of mover: the same here
  Assert.AreEqual(Double(5.0), Double(LMover.Rect.Value.X), 0.01);
  Assert.AreEqual(Double(10.0), Double(LMover.Rect.Value.Y), 0.01);
  FWorld.UserInterface.RunFrame(200);
  Assert.AreEqual(Single(0.0), LMover.Rect.Value.X);
  Assert.AreEqual(Single(1.0), LMover.Rect.Value.W);
end;

procedure TTestGuiWindowExtras.UnaGraffaInPiuInUnoScriptDaUnErrore;
begin
  Start('windowDef Desktop { onActivate { { } } }');
  Assert.IsTrue(Contains('Unexpected {'));
end;

procedure TTestGuiWindowExtras.UnoScriptNonChiusoDaUnErrore;
begin
  Start('windowDef Desktop { onActivate { set "cmd" "x" ;');
  Assert.IsTrue(Contains('Unexpected end of file'));
end;

procedure TTestGuiWindowExtras.UnOnTimeSenzaCorpoDaUnErrore;
begin
  Start('windowDef Desktop { onTime 5');
  Assert.IsTrue(FWorld.Lines.Count > 0);
  Start('windowDef Desktop { onTime');
  Assert.IsTrue(Contains('Unexpected end of file'));
  Start('windowDef Desktop { onNamedEvent');
  Assert.IsTrue(Contains('Expected event name'));
  Start('windowDef Desktop { onNamedEvent x');
  Assert.IsTrue(FWorld.Lines.Count > 0);
end;

procedure TTestGuiWindowExtras.PlayDaUnAvvisoEVieneSaltato;
begin
  Start('windowDef Desktop { play "snd/x" text "after" }');
  Assert.IsTrue(HasLine('W: play encountered during gui parse.. see Robert'));
  Assert.AreEqual('after', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindowExtras.UnaShearSenzaVirgolaDaUnErrore;
begin
  Start('windowDef Desktop { shear 1 2 }');
  Assert.IsTrue(Contains('Expected comma in shear definiation'));
end;

procedure TTestGuiWindowExtras.ChoiceDiTipoStringaCercaNelleScelte;
var
  LChoice: TGuiChoiceWindow;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.UserInterface.SetStateString('gui::mode', 'b');
  FWorld.Load('windowDef Desktop { choiceDef c { choices "A;B;C" values "a;b;c" choicetype 1 gui "gui::mode" ' +
    'cvar "b" } choiceDef d { choices "A;B" choicetype 1 gui "gui::mode" cvar "zzz" } }');
  LChoice := FWorld.UserInterface.Desktop.Children[0] as TGuiChoiceWindow;
  Assert.AreEqual(1, LChoice.CurrentChoice);
  Assert.AreEqual(0, (FWorld.UserInterface.Desktop.Children[1] as TGuiChoiceWindow).CurrentChoice);
end;

procedure TTestGuiWindowExtras.UnaFinestraTrovataDaIlProprioPadre;
var
  LOwner: IGuiWindowNode;
begin
  Start('windowDef Desktop { windowDef act { onAction { } } }');
  Assert.IsNotNull(FWorld.UserInterface.Desktop.Children[0].GetWinVarByName('rect', False, LOwner));
  Assert.IsNotNull(LOwner);
  Assert.AreEqual('act', string(LOwner.GetName));
  // the desktop has no parent: no owner
  Assert.IsNotNull(FWorld.UserInterface.Desktop.GetWinVarByName('rect', False, LOwner));
  Assert.IsTrue(LOwner = nil);
end;

procedure TTestGuiWindowExtras.NumTransitionsContaIFigli;
begin
  Start('windowDef Desktop { windowDef a { onAction { } onActivate { transition "rect" "0 0 1 1" "1 1 1 1" "100" } } ' +
    'onActivate { transition "rect" "0 0 1 1" "1 1 1 1" "100" } }');
  Assert.AreEqual(0, FWorld.UserInterface.Desktop.NumTransitions);
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual(2, FWorld.UserInterface.Desktop.NumTransitions);
end;

procedure TTestGuiWindowExtras.UnaFinestraRiparsataSiSvuota;
begin
  Start('windowDef Desktop { windowDef a { onAction { } } text "one" float f 3 }');
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.ChildCount);
  FWorld.Files.Add('second.gui', 'windowDef Desktop { text "two" }');
  FWorld.UserInterface.InitFromFile('second.gui');
  Assert.AreEqual(0, FWorld.UserInterface.Desktop.ChildCount);
  Assert.AreEqual(0, FWorld.UserInterface.Desktop.DefinedVarCount);
  Assert.AreEqual('two', string(FWorld.UserInterface.Desktop.Text.AsText));
  // the desktop is parsed again without rebuilding: the window keeps what it had
  FWorld.Files.Add('third.gui', 'windowDef Desktop { windowDef b { onAction { } } }');
  FWorld.UserInterface.InitFromFile('third.gui', False);
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.ChildCount);
end;

procedure TTestGuiWindowExtras.LeFinestreSottoUnaStessaFinestraSiRiparsanoPerNome;
begin
  // a second windowDef with the name of an existing child is read into that child
  Start('windowDef Desktop { windowDef a { onAction { } text "first" } windowDef a { text "second" } }');
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.ChildCount);
  Assert.AreEqual('second', string(FWorld.UserInterface.Desktop.Children[0].Text.AsText));
end;
procedure TTestGuiWindowExtras.UnaListaLeggeTuttiITabEIconeDelleColonne;
var
  LList: TGuiListWindow;
begin
  Start('windowDef Desktop { listDef l { tabstops "0, 50" tabaligns "1" tabvaligns "1, 2" tabTypes "0, 1" ' +
    'tabIconSizes "16, 16, 32, 32" tabIconVOffset "2, 3.5" } listDef m { tabstops "10, 60, 90" tabaligns "1, 2, 3" } }');
  LList := FWorld.UserInterface.Desktop.Children[0] as TGuiListWindow;
  Assert.AreEqual(2, LList.TabInfo.Count);
  Assert.AreEqual(46, LList.TabInfo[0].Width);
  // the aligns do not have one entry per stop: they are not used
  Assert.AreEqual(0, LList.TabInfo[0].Align);
  Assert.AreEqual(2, LList.TabInfo[1].VAlign);
  Assert.AreEqual(1, LList.TabInfo[1].TabType);
  Assert.AreEqual(Single(32.0), LList.TabInfo[1].IconSize.X);
  Assert.AreEqual(Single(3.5), LList.TabInfo[1].IconVOffset);
  LList := FWorld.UserInterface.Desktop.Children[1] as TGuiListWindow;
  Assert.AreEqual(3, LList.TabInfo[2].Align);
end;

procedure TTestGuiWindowExtras.UnNumeroNegativoSbagliatoEUnaVariabileDiTipoSbagliatoDannoAvvisi;
begin
  Start('windowDef Desktop { rect - x, 0, 0, 0 }');
  Assert.IsTrue(Contains('Bad negative number ''x'''));
  Start('windowDef Desktop { rect rect * 2, 0, 0, 0 }');
  Assert.IsTrue(Contains('Var expression not vec4, float or int'));
end;

procedure TTestGuiWindowExtras.UnVec4InUnEspressioneConEsenzaIndice;
begin
  Start('windowDef Desktop { backcolor 1, 2, 3, 4 rect backcolor [ 1 ], backcolor + 1, 0, 0 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(0, FWorld.UserInterface.Desktop.ChildCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiWindowExtras);

end.
