{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the scripts, time and transitions    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WindowScripts;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Gui.WindowFakes;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiWindowScripts = class
  strict private
    FWorld: TGuiWindowWorld;
    procedure Start(const AText: AnsiString);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SetCambiaUnaVariabileDellaFinestra;
    [Test]
    procedure SetCmdAccodaICommandi;
    [Test]
    procedure RunScriptAggiungeIlComandoInCoda;
    [Test]
    procedure LocalSoundEEndGameVannoAlGioco;
    [Test]
    procedure IfElseSceglieLaLista;
    [Test]
    procedure ElseIfSiConcatena;
    [Test]
    procedure UnaLineaIfSenzaOperazioniNonEseguePerRegistri;
    [Test]
    procedure OnTimeEseguePassatoIlTempo;
    [Test]
    procedure ResetTimeRiarmaGliEventi;
    [Test]
    procedure IlComandoDiUnaFinestraAttivaVaAlGuiInSospeso;
    [Test]
    procedure TransitionMuoveUnRettangoloNelTempo;
    [Test]
    procedure TransitionSiConcludeEPulisceIlFlag;
    [Test]
    procedure TransitionConDollaroLeggeLaVariabileDiUnAltraFinestra;
    [Test]
    procedure UnaTransitionConPochiParametriDaUnAvviso;
    [Test]
    procedure UnComandoSconosciutoDaUnErroreDelParser;
    [Test]
    procedure UnNumeroSbagliatoDiParametriDaUnErrore;
    [Test]
    procedure ShowCursorCambiaIlFlagDelDesktop;
    [Test]
    procedure SetFocusSpostaIlFocus;
    [Test]
    procedure ResetCinematicsChiamaIlGioco;
    [Test]
    procedure SetConGuiPrefissoCreaUnaVariabileDelloStato;
    [Test]
    procedure ILaStringaDellaLinguaSiTraducePrimaDellEsecuzione;
    [Test]
    procedure OnNamedEventEseguePerNome;
    [Test]
    procedure OnTriggerEOnDeactivateSiEseguono;
    [Test]
    procedure InterpolatoreLineare;
    [Test]
    procedure InterpolatoreConAccelerazioneEDecelerazione;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.Interpolator, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.Window.Intf;

procedure TTestGuiWindowScripts.Start(const AText: AnsiString);
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.Load(AText);
end;

procedure TTestGuiWindowScripts.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestGuiWindowScripts.SetCambiaUnaVariabileDellaFinestra;
begin
  Start('windowDef Desktop { text "a" onActivate { set "text" "changed" ; set "visible" "0" } }');
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual('changed', string(FWorld.UserInterface.Desktop.Text.AsText));
  Assert.IsFalse(FWorld.UserInterface.Desktop.Visible.Value);
  // a variable that a script set is no longer driven by its register
  Assert.IsFalse(FWorld.UserInterface.Desktop.Text.Eval);
end;

procedure TTestGuiWindowScripts.SetCmdAccodaICommandi;
begin
  Start('windowDef Desktop { onActivate { set "cmd" "quit" ; set "cmd" "play" "x y" "z" } }');
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual('quit ; play "x y" "z"', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.RunScriptAggiungeIlComandoInCoda;
begin
  Start('windowDef Desktop { onActivate { set "cmd" "quit" ; runScript "go" } }');
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual('quit ; runScript go', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.LocalSoundEEndGameVannoAlGioco;
begin
  Start('windowDef Desktop { onActivate { localSound "beep" ; endGame ; evalRegs } }');
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual('host sound beep', FWorld.Lines[0]);
  Assert.AreEqual('host endgame', FWorld.Lines[1]);
end;

procedure TTestGuiWindowScripts.IfElseSceglieLaLista;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.UserInterface.SetStateInt('flag', 1);
  FWorld.Load('windowDef Desktop { onActivate { if ( "gui::flag" == 1 ) { set "cmd" "yes" } else { set "cmd" "no" } } }');
  FWorld.UserInterface.RunFrame(100);
  FWorld.UserInterface.Activate(True, 100);
  Assert.AreEqual('yes', string(FWorld.UserInterface.Desktop.Command));
  FWorld.UserInterface.Desktop.Command := '';
  FWorld.UserInterface.SetStateInt('flag', 0);
  FWorld.UserInterface.RunFrame(200);
  FWorld.UserInterface.Activate(True, 200);
  Assert.AreEqual('no', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.ElseIfSiConcatena;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.UserInterface.SetStateInt('n', 2);
  FWorld.Load('windowDef Desktop { onActivate { ' +
    'if ( "gui::n" == 1 ) { set "cmd" "one" } else if ( "gui::n" == 2 ) { set "cmd" "two" } else { set "cmd" "other" } } }');
  FWorld.UserInterface.RunFrame(100);
  FWorld.UserInterface.Activate(True, 100);
  Assert.AreEqual('two', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.UnaLineaIfSenzaOperazioniNonEseguePerRegistri;
begin
  // a condition that is a constant has no operations: the window does not evaluate, nothing runs
  Start('windowDef Desktop { onActivate { if ( 1 ) { set "cmd" "yes" } } }');
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual('', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.OnTimeEseguePassatoIlTempo;
begin
  Start('windowDef Desktop { onTime 100 { set "cmd" "late" } onTime 0 { set "cmd" "early" } }');
  FWorld.UserInterface.RunFrame(16);
  Assert.AreEqual('early', string(FWorld.UserInterface.Desktop.Command));
  Assert.AreEqual(16, FWorld.UserInterface.Desktop.TimeLine);
  FWorld.UserInterface.RunFrame(200);
  Assert.AreEqual('late', string(FWorld.UserInterface.Desktop.Command));
  FWorld.UserInterface.RunFrame(300);
  // nothing pending: the command text is cleared at the start of each step
  Assert.AreEqual('', string(FWorld.UserInterface.Desktop.Command));
  Assert.AreEqual(2, FWorld.UserInterface.Desktop.TimeLineEventCount);
end;

procedure TTestGuiWindowScripts.ResetTimeRiarmaGliEventi;
begin
  Start('windowDef Desktop { onTime 100 { set "cmd" "late" } onTime 0 { set "cmd" "early" } }');
  FWorld.UserInterface.RunFrame(16);
  FWorld.UserInterface.RunFrame(200);
  FWorld.UserInterface.Desktop.ResetTime(0);
  FWorld.UserInterface.RunFrame(220);
  Assert.AreEqual('early', string(FWorld.UserInterface.Desktop.Command));
  FWorld.UserInterface.RunFrame(260);
  Assert.AreEqual('', string(FWorld.UserInterface.Desktop.Command));
  FWorld.UserInterface.RunFrame(330);
  Assert.AreEqual('late', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.IlComandoDiUnaFinestraAttivaVaAlGuiInSospeso;
begin
  Start('windowDef Desktop { onTime 0 { set "cmd" "go" } }');
  FWorld.UserInterface.Activate(True, 0);
  FWorld.UserInterface.RunFrame(16);
  Assert.AreEqual('go', string(FWorld.UserInterface.PendingCommand));
end;

procedure TTestGuiWindowScripts.TransitionMuoveUnRettangoloNelTempo;
var
  LRect: TGuiRectangle;
begin
  Start('windowDef Desktop { rect 0, 0, 640, 480 onActivate { ' +
    'transition "rect" "0 0 10 10" "100 100 10 10" "200" } }');
  FWorld.UserInterface.Activate(True, 1000);
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.TransitionCount);
  Assert.IsTrue((FWorld.UserInterface.Desktop.Flags and WIN_INTRANSITION) <> 0);
  FWorld.UserInterface.RunFrame(1100);
  LRect := FWorld.UserInterface.Desktop.Rect.Value;
  Assert.AreEqual(Double(50.0), Double(LRect.X), 0.01);
  Assert.AreEqual(Double(50.0), Double(LRect.Y), 0.01);
  Assert.AreEqual(Double(10.0), Double(LRect.W), 0.01);
end;

procedure TTestGuiWindowScripts.TransitionSiConcludeEPulisceIlFlag;
begin
  Start('windowDef Desktop { rect 0, 0, 640, 480 onActivate { ' +
    'transition "rect" "0 0 10 10" "100 100 10 10" "200" } }');
  FWorld.UserInterface.Activate(True, 1000);
  FWorld.UserInterface.RunFrame(1300);
  Assert.AreEqual(Single(100.0), FWorld.UserInterface.Desktop.Rect.Value.X);
  Assert.AreEqual(0, FWorld.UserInterface.Desktop.TransitionCount);
  Assert.IsTrue((FWorld.UserInterface.Desktop.Flags and WIN_INTRANSITION) = 0);
end;

procedure TTestGuiWindowScripts.TransitionConDollaroLeggeLaVariabileDiUnAltraFinestra;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { rect 0, 0, 640, 480 ' +
    'windowDef box { rect 20, 30, 40, 50 backcolor 0.25, 0.5, 0.75, 1 } ' +
    'onActivate { transition "backcolor" "$box::backcolor" "1 1 1 1" "100" } }');
  LDesktop := FWorld.UserInterface.Desktop;
  FWorld.UserInterface.Activate(True, 0);
  // the start is the color of box (the text of its variable), the end is the given color
  FWorld.UserInterface.RunFrame(50);
  Assert.AreEqual(Double(0.625), Double(LDesktop.BackColor.Value.X), 0.001);
  FWorld.UserInterface.RunFrame(200);
  Assert.AreEqual(Single(1.0), LDesktop.BackColor.Value.X);
end;

procedure TTestGuiWindowScripts.UnaTransitionConPochiParametriDaUnAvviso;
begin
  Start('windowDef Desktop { onActivate { transition "rect" "0 0 1 1" } }');
  Assert.IsTrue(FWorld.Lines.IndexOf('W: Window Desktop in gui test.gui has a bad transition definition') >= 0);
end;

procedure TTestGuiWindowScripts.UnComandoSconosciutoDaUnErroreDelParser;
var
  LIndex: Integer;
  LFound: Boolean;
begin
  Start('windowDef Desktop { onActivate { frobnicate "x" ; set "cmd" "ok" } }');
  LFound := False;
  for LIndex := 0 to FWorld.Lines.Count - 1 do
    if Pos('Uknown script call frobnicate', FWorld.Lines[LIndex]) > 0 then
      LFound := True;
  Assert.IsTrue(LFound);
  // the line is kept without a command; the next one runs
  FWorld.UserInterface.Activate(True, 5);
  Assert.AreEqual('ok', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.UnNumeroSbagliatoDiParametriDaUnErrore;
var
  LIndex: Integer;
  LFound: Boolean;
begin
  Start('windowDef Desktop { onActivate { setFocus ; } }');
  LFound := False;
  for LIndex := 0 to FWorld.Lines.Count - 1 do
    if Pos('incorrect number of parameters for script setFocus', FWorld.Lines[LIndex]) > 0 then
      LFound := True;
  Assert.IsTrue(LFound);
end;

procedure TTestGuiWindowScripts.ShowCursorCambiaIlFlagDelDesktop;
begin
  Start('windowDef Desktop { onActivate { showCursor "0" } onDeactivate { showCursor "1" } }');
  FWorld.UserInterface.Activate(True, 1);
  Assert.IsTrue((FWorld.UserInterface.Desktop.Flags and WIN_NOCURSOR) <> 0);
  FWorld.UserInterface.Activate(False, 2);
  Assert.IsTrue((FWorld.UserInterface.Desktop.Flags and WIN_NOCURSOR) = 0);
end;

procedure TTestGuiWindowScripts.SetFocusSpostaIlFocus;
var
  LDesktop: TGuiWindow;
begin
  Start('windowDef Desktop { windowDef a { onAction { } } windowDef b { onAction { } } ' +
    'onActivate { setFocus "a" } }');
  LDesktop := FWorld.UserInterface.Desktop;
  Assert.AreEqual('b', string(LDesktop.FocusedChild.Name));
  FWorld.UserInterface.Activate(True, 1);
  Assert.AreEqual('a', string(LDesktop.FocusedChild.Name));
  Assert.IsTrue((LDesktop.FocusedChild.Flags and WIN_FOCUS) <> 0);
  Assert.IsTrue((LDesktop.Children[1].Flags and WIN_FOCUS) = 0);
end;

procedure TTestGuiWindowScripts.ResetCinematicsChiamaIlGioco;
begin
  Start('windowDef Desktop { background "movie" onActivate { resetCinematics } }');
  FWorld.UserInterface.Activate(True, 77);
  Assert.AreEqual('host cinematic movie 77', FWorld.Lines[0]);
end;

procedure TTestGuiWindowScripts.SetConGuiPrefissoCreaUnaVariabileDelloStato;
begin
  Start('windowDef Desktop { onActivate { set "text" "gui::title" } }');
  FWorld.UserInterface.SetStateString('title', 'dal gui');
  FWorld.UserInterface.Activate(True, 1);
  Assert.AreEqual('dal gui', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindowScripts.ILaStringaDellaLinguaSiTraducePrimaDellEsecuzione;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create(nil, TGuiWindowFakeLanguage.Create('#str_01', 'Ciao'));
  FWorld.Load('windowDef Desktop { onActivate { set "text" "#str_01" } }');
  FWorld.UserInterface.Activate(True, 1);
  Assert.AreEqual('Ciao', string(FWorld.UserInterface.Desktop.Text.AsText));
end;

procedure TTestGuiWindowScripts.OnNamedEventEseguePerNome;
begin
  Start('windowDef Desktop { onNamedEvent hello { set "cmd" "hi" } windowDef c { rect 0, 0, 1, 1 ' +
    'onNamedEvent hello { set "cmd" "child" } } }');
  FWorld.UserInterface.HandleNamedEvent('HELLO');
  Assert.AreEqual('hi', string(FWorld.UserInterface.Desktop.Command));
  Assert.AreEqual('child', string(FWorld.UserInterface.Desktop.Children[0].Command));
  FWorld.UserInterface.Desktop.Command := '';
  FWorld.UserInterface.HandleNamedEvent('other');
  Assert.AreEqual('', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.OnTriggerEOnDeactivateSiEseguono;
begin
  Start('windowDef Desktop { onTrigger { set "cmd" "trig" } onDeactivate { set "cmd" "off" } }');
  FWorld.UserInterface.Trigger(5);
  Assert.AreEqual('trig', string(FWorld.UserInterface.Desktop.Command));
  FWorld.UserInterface.Desktop.Command := '';
  FWorld.UserInterface.Activate(False, 6);
  Assert.AreEqual('off', string(FWorld.UserInterface.Desktop.Command));
end;

procedure TTestGuiWindowScripts.InterpolatoreLineare;
var
  LInterpolator: TGuiInterpolator;
begin
  LInterpolator := TGuiInterpolator.Create;
  try
    LInterpolator.Init(1000, 0, 0, 1000, TIdVec4.Create(0, 0, 0, 0), TIdVec4.Create(100, 200, 0, 0));
    Assert.AreEqual(Double(50.0), Double(LInterpolator.GetCurrentValue(1500).X), 0.01);
    Assert.AreEqual(Double(100.0), Double(LInterpolator.GetCurrentValue(1500).Y), 0.01);
    Assert.IsFalse(LInterpolator.IsDone(1999));
    Assert.IsTrue(LInterpolator.IsDone(2000));
    Assert.AreEqual(Double(100.0), Double(LInterpolator.EndValue.X), 0.0001);
  finally
    LInterpolator.Free;
  end;
end;

procedure TTestGuiWindowScripts.InterpolatoreConAccelerazioneEDecelerazione;
var
  LInterpolator: TGuiInterpolator;
begin
  LInterpolator := TGuiInterpolator.Create;
  try
    LInterpolator.Init(0, 250, 250, 1000, TIdVec4.Create(0, 0, 0, 0), TIdVec4.Create(100, 0, 0, 0));
    Assert.AreEqual(Double(16.667), Double(LInterpolator.GetCurrentValue(250).X), 0.01);
    Assert.AreEqual(Double(50.0), Double(LInterpolator.GetCurrentValue(500).X), 0.01);
    Assert.AreEqual(Double(100.0), Double(LInterpolator.GetCurrentValue(1000).X), 0.01);
  finally
    LInterpolator.Free;
  end;
  // a duration of zero or less: the times as given, done at the start
  LInterpolator := TGuiInterpolator.Create;
  try
    LInterpolator.Init(0, 0, 0, 0, TIdVec4.Create(5, 0, 0, 0), TIdVec4.Create(9, 0, 0, 0));
    Assert.IsTrue(LInterpolator.IsDone(0));
  finally
    LInterpolator.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiWindowScripts);

end.
