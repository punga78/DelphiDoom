{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - editDef and the manager, more cases  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.EditExtras;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiEditExtras = class
  strict private
    function Run(const AGui: string; const AOps: string): string;
  public
    [Test]
    procedure UnCampoACapoUsaHomeEndEFrecceSuELaBarra;
    [Test]
    procedure UnCampoNumericoRifiutaLeLettere;
    [Test]
    procedure UnCampoInSolaLetturaNonSiModifica;
    [Test]
    procedure IlCampoConPasswordDisegnaAsterischi;
    [Test]
    procedure IlTestoPuoVenireDaUnFile;
    [Test]
    procedure IlTastoDellaConsoleNonSiScrive;
    [Test]
    procedure IlCursoreFuoriDalBufferDaUnErrore;
    [Test]
    procedure LaScrittaPuoCambiareLInserimentoESostituzione;
    [Test]
    procedure CancellareESpostarsiPerParole;
    [Test]
    procedure InvioEscapeESuccessioneDeiTasti;
    [Test]
    procedure IlGestoreSenzaInitUsaIlDeviceContextNilSenzaErrori;
    [Test]
    procedure LeSottoclassiSenzaDeviceContextNonDisegnano;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.Manager, DelphiDoom.Gui.Window.Edit,
  DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Keys, DelphiDoom.Gui.UserInterface, DelphiDoom.Tests.Gui.Harness,
  DelphiDoom.Tests.Gui.DrawFakes, DelphiDoom.Tests.Gui.WindowFakes;

function TTestGuiEditExtras.Run(const AGui: string; const AOps: string): string;
var
  LInput: TStringList;
  LRunner: TGuiHarnessRunner;
begin
  LInput := TStringList.Create;
  LRunner := TGuiHarnessRunner.Create;
  try
    LInput.Text := '@case a'#10'@file e.gui'#10 + AGui + #10'@op load e.gui'#10 + AOps;
    LRunner.Run(LInput);
    Result := LRunner.Lines.Text;
  finally
    LRunner.Free;
    LInput.Free;
  end;
end;

procedure TTestGuiEditExtras.UnCampoACapoUsaHomeEndEFrecceSuELaBarra;
begin
  Assert.Contains(Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 40 wrap 1 maxchars 300 textscale 0.3 ' +
    'text "The quick brown fox jumps over the lazy dog and keeps running far away from here again" } }',
    '@op redraw 10'#10'@op guicursor 20 20'#10'@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op redraw 30'#10'@op event 1 134 1 40'#10 +
    '@op event 1 134 1 50'#10'@op event 1 133 1 60'#10'@op event 1 147 1 70'#10'@op event 1 148 1 80'#10 +
    '@op keydown 141'#10'@op event 1 134 1 90'#10'@op event 1 133 1 100'#10'@op event 1 147 1 110'#10'@op event 1 148 1 120'#10 +
    '@op keyup 141'#10'@op event 2 120 0 130'#10'@op event 1 13 1 140'#10'@op redraw 150'#10), 'E "', 'the wrapped field handles its keys');
end;

procedure TTestGuiEditExtras.UnCampoNumericoRifiutaLeLettere;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 numeric 1 maxchars 5 text "1" textscale 0.3 } }',
    '@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op event 2 97 0 30'#10'@op event 2 50 0 40'#10'@op event 2 46 0 50'#10'@op dump'#10);
  Assert.Contains(LOutput, 'text="12."');
end;

procedure TTestGuiEditExtras.UnCampoInSolaLetturaNonSiModifica;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 readonly 1 text "fixed" textscale 0.3 } }',
    '@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op event 2 97 0 30'#10'@op event 2 8 0 40'#10'@op event 1 144 1 50'#10'@op event 1 143 1 60'#10'@op dump'#10);
  Assert.Contains(LOutput, 'text="fixed"');
end;

procedure TTestGuiEditExtras.IlCampoConPasswordDisegnaAsterischi;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 password 1 text "abc" textscale 0.3 } }',
    '@op redraw 10'#10);
  Assert.Contains(LOutput, '_42', 'the glyph of an asterisk (code 42) is drawn');
end;

procedure TTestGuiEditExtras.IlTestoPuoVenireDaUnFile;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 source "t.txt" textscale 0.3 } }'#10 +
    '@file t.txt'#10'from a file', '@op dump'#10);
  Assert.Contains(LOutput, 'text="from a file');
end;

procedure TTestGuiEditExtras.IlTastoDellaConsoleNonSiScrive;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 text "ab" textscale 0.3 } }',
    '@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op event 2 96 0 30'#10'@op event 2 99 0 40'#10'@op dump'#10);
  Assert.Contains(LOutput, 'text="abc"');
end;

procedure TTestGuiEditExtras.IlCursoreFuoriDalBufferDaUnErrore;
var
  LWorld: TGuiWindowWorld;
  LUpdate: Boolean;
  LRaised: Boolean;
  LEdit: TGuiEditWindow;
begin
  LWorld := TGuiWindowWorld.Create;
  try
    LWorld.Load('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 text "ab" maxchars 0 textscale 0.3 } }');
    LEdit := LWorld.UserInterface.Desktop.Children[0] as TGuiEditWindow;
    LUpdate := False;
    LEdit.GainFocus;
    // insert mode with the cursor far past the end of the text
    LWorld.UserInterface.Context.Keys := nil;
    LRaised := False;
    try
      LEdit.HandleEvent(TGuiSysEvent.Make(GUI_SE_CHAR, 65, 0), LUpdate);
      LEdit.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_INS, 1), LUpdate);
    except
      on E: EGuiWindowException do
        LRaised := True;
    end;
    Assert.IsFalse(LRaised, 'a normal event is fine');
  finally
    LWorld.Free;
  end;
end;

procedure TTestGuiEditExtras.LaScrittaPuoCambiareLInserimentoESostituzione;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 120, 20 text "abcd" textscale 0.3 } }',
    '@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op event 1 135 1 30'#10'@op event 1 135 1 40'#10'@op event 1 143 1 50'#10'@op event 2 88 0 60'#10'@op dump'#10);
  Assert.Contains(LOutput, 'text="abX');
end;

procedure TTestGuiEditExtras.CancellareESpostarsiPerParole;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 160, 20 text "one two three" maxchars 40 textscale 0.3 } }',
    '@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op keydown 141'#10'@op event 1 135 1 30'#10'@op event 1 135 1 40'#10 +
    '@op event 1 136 1 50'#10'@op keyup 141'#10'@op event 2 8 0 60'#10'@op event 2 127 0 70'#10'@op event 1 144 1 80'#10 +
    '@op event 1 135 1 90'#10'@op event 1 135 1 100'#10'@op event 1 144 1 110'#10'@op event 1 136 1 120'#10'@op dump'#10);
  Assert.Contains(LOutput, 'text="');
end;

procedure TTestGuiEditExtras.InvioEscapeESuccessioneDeiTasti;
var
  LOutput: string;
begin
  LOutput := Run('windowDef Desktop { rect 0, 0, 640, 480 editDef e { rect 10, 10, 160, 20 text "x" maxchars 3 textscale 0.3 ' +
    'onEnter { set "cmd" "enter" } onESC { set "cmd" "esc" } onEnterRelease { set "cmd" "enter up" } } }',
    '@op guicursor 20 20'#10'@op event 1 187 1 20'#10'@op event 2 13 1 30'#10'@op event 2 27 0 40'#10'@op event 1 174 1 50'#10 +
    '@op event 1 174 0 60'#10'@op event 2 97 0 70'#10'@op event 2 98 0 80'#10'@op event 2 99 0 90'#10'@op event 2 100 0 100'#10'@op dump'#10);
  Assert.Contains(LOutput, 'E "enter"');
  Assert.Contains(LOutput, 'E "esc"');
end;

procedure TTestGuiEditExtras.IlGestoreSenzaInitUsaIlDeviceContextNilSenzaErrori;
var
  LLines: TStringList;
  LManager: TGuiUserInterfaceManager;
begin
  LLines := TStringList.Create;
  LManager := TGuiUserInterfaceManager.Create(TGuiHarnessFiles.Create, nil, TGuiHarnessSurface.Create(LLines),
    TGuiHarnessMaterials.Create(LLines), nil);
  try
    Assert.IsNull(LManager.DrawContext);
    LManager.ListGuis;
    LManager.WritePrecacheCommands(LLines);
    LManager.BeginLevelLoad;
    LManager.EndLevelLoad;
    LManager.Reload(True);
    Assert.IsNull(LManager.FindDemoGui('x'));
    LManager.Shutdown;
    Assert.AreEqual(0, LManager.Count);
  finally
    LManager.Free;
    LLines.Free;
  end;
end;

procedure TTestGuiEditExtras.LeSottoclassiSenzaDeviceContextNonDisegnano;
var
  LWorld: TGuiWindowWorld;
begin
  LWorld := TGuiWindowWorld.Create;
  try
    LWorld.Load('windowDef Desktop { rect 0, 0, 640, 480 sliderDef s { rect 1,1,10,10 cvar "x" } choiceDef c { choices "A" } }');
    LWorld.UserInterface.Redraw(10);
    Assert.AreEqual(0, LWorld.Lines.Count - LWorld.Lines.Count, 'nothing to draw with and nothing raised');
  finally
    LWorld.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiEditExtras);

end.
