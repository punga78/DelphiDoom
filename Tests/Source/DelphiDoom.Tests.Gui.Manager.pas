{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the manager of the guis and ListGUI  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Manager;

interface

uses
  System.Classes, DUnitX.TestFramework, DelphiDoom.Gui.Manager, DelphiDoom.Tests.Gui.DrawFakes,
  DelphiDoom.Tests.Gui.WindowFakes;

type
  [TestFixture]
  [Category('GuiManager')]
  TTestGuiManager = class
  strict private
    FLines: TStringList;
    FFiles: TGuiHarnessFiles;
    FFilesRef: IInterface;
    FManager: TGuiUserInterfaceManager;
    procedure AddGui(const AName: AnsiString; const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaGuiNonInterattivaSiCondivide;
    [Test]
    procedure UnaGuiInterattivaNonSiCondividePerNome;
    [Test]
    procedure FindGuiSenzaCaricamentoNonTrovaNulla;
    [Test]
    procedure IlNomeSiConfrontaSenzaMaiuscole;
    [Test]
    procedure ReloadLeggeSoloLeGuiPiuRecenti;
    [Test]
    procedure ReloadDiTutteLeLegge;
    [Test]
    procedure EndLevelLoadLiberaLeGuiSenzaUtenti;
    [Test]
    procedure UnaGuiCheUnMaterialUsaNonSiLibera;
    [Test]
    procedure IMenuNonPerdonoGliUtentiAllInizioDelLivello;
    [Test]
    procedure ListGuisScriveLeRighe;
    [Test]
    procedure WritePrecacheCommandsElencaLeGui;
    [Test]
    procedure TouchEControlloDelFile;
    [Test]
    procedure LaListaDiUnaGuiScriveLoStato;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Gui.ListGui, DelphiDoom.Gui.UserInterface, DelphiDoom.Gui.Window.Types;

const
  SIMPLE_GUI = 'windowDef Desktop { rect 0, 0, 640, 480 }';
  BUTTON_GUI = 'windowDef Desktop { rect 0, 0, 640, 480 windowDef b { rect 0, 0, 10, 10 onAction { set "cmd" "x" } } }';
  MENU_GUI = 'windowDef Desktop { rect 0, 0, 640, 480 menugui 1 }';

procedure TTestGuiManager.Setup;
begin
  FLines := TStringList.Create;
  FFiles := TGuiHarnessFiles.Create;
  FFilesRef := FFiles;
  FManager := TGuiUserInterfaceManager.Create(FFiles, TGuiWindowFakeLog.Create(FLines), TGuiHarnessSurface.Create(FLines),
    TGuiHarnessMaterials.Create(FLines), nil);
  TGuiHarnessFonts.AddSet(FFiles, 'fonts/english');
  FManager.Init;
end;

procedure TTestGuiManager.TearDown;
begin
  FManager.Free;
  FFilesRef := nil;
  FLines.Free;
end;

procedure TTestGuiManager.AddGui(const AName: AnsiString; const AText: AnsiString);
begin
  FFiles.Add(AName, AText);
end;

procedure TTestGuiManager.UnaGuiNonInterattivaSiCondivide;
var
  LFirst, LSecond: TGuiUserInterface;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  LFirst := FManager.FindGui('guis/a.gui', True);
  LSecond := FManager.FindGui('guis/a.gui', True);
  Assert.IsTrue(LFirst = LSecond);
  Assert.AreEqual(2, LFirst.Refs);
  Assert.AreEqual(1, FManager.Count);
end;

procedure TTestGuiManager.UnaGuiInterattivaNonSiCondividePerNome;
var
  LFirst, LSecond, LThird: TGuiUserInterface;
begin
  AddGui('guis/b.gui', BUTTON_GUI);
  LFirst := FManager.FindGui('guis/b.gui', True);
  Assert.IsTrue(LFirst.Interactive);
  LSecond := FManager.FindGui('guis/b.gui', True);
  Assert.IsFalse(LFirst = LSecond, 'an interactive gui is a copy for each user');
  LThird := FManager.FindGui('guis/b.gui', True, False, True);
  Assert.IsTrue(LThird = LFirst, 'forced not unique: the first one is shared');
  Assert.AreEqual(2, FManager.Count);
end;

procedure TTestGuiManager.FindGuiSenzaCaricamentoNonTrovaNulla;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  Assert.IsNull(FManager.FindGui('guis/a.gui'));
  Assert.IsNotNull(FManager.FindGui('guis/none.gui', True), 'a file that does not exist is an invalid gui, not nil');
end;

procedure TTestGuiManager.IlNomeSiConfrontaSenzaMaiuscole;
var
  LFirst: TGuiUserInterface;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  LFirst := FManager.FindGui('guis/a.gui', True);
  Assert.IsTrue(FManager.FindGui('GUIS/A.GUI') = LFirst);
end;

procedure TTestGuiManager.ReloadLeggeSoloLeGuiPiuRecenti;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  FManager.FindGui('guis/a.gui', True);
  FManager.Reload(False);
  // the fake file system gives a newer time at every read: the file is newer than the gui
  Assert.IsTrue(Pos('reloading guis/a.gui.', FLines.Text) > 0);
end;

procedure TTestGuiManager.ReloadDiTutteLeLegge;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  FManager.FindGui('guis/a.gui', True);
  FManager.Reload(True);
  Assert.IsTrue(Pos('reloading guis/a.gui.', FLines.Text) > 0);
end;

procedure TTestGuiManager.EndLevelLoadLiberaLeGuiSenzaUtenti;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  AddGui('guis/c.gui', SIMPLE_GUI);
  FManager.FindGui('guis/a.gui', True);
  FManager.FindGui('guis/c.gui', True);
  FManager.BeginLevelLoad;
  FManager.FindGui('guis/c.gui');
  FManager.EndLevelLoad;
  Assert.AreEqual(1, FManager.Count);
  Assert.AreEqual('guis/c.gui', string(FManager.Guis[0].SourceFile));
end;

procedure TTestGuiManager.UnaGuiCheUnMaterialUsaNonSiLibera;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  FManager.FindGui('guis/a.gui', True);
  FManager.GlobalGuiCheck := function(const AGui: TGuiUserInterface): Boolean
    begin
      Result := True;
    end;
  FManager.BeginLevelLoad;
  FManager.EndLevelLoad;
  Assert.AreEqual(1, FManager.Count);
end;

procedure TTestGuiManager.IMenuNonPerdonoGliUtentiAllInizioDelLivello;
begin
  AddGui('guis/menu.gui', MENU_GUI);
  FManager.FindGui('guis/menu.gui', True);
  FManager.BeginLevelLoad;
  FManager.EndLevelLoad;
  Assert.AreEqual(1, FManager.Count);
end;

procedure TTestGuiManager.ListGuisScriveLeRighe;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  AddGui('guis/b.gui', BUTTON_GUI);
  FManager.FindGui('guis/a.gui', True);
  FManager.FindGui('guis/b.gui', True);
  FManager.ListGuis;
  Assert.IsTrue(Pos('(copy) guis/a.gui ( 0 transitions )', FLines.Text) > 0);
  Assert.IsTrue(Pos('(unique) guis/b.gui', FLines.Text) > 0);
  Assert.IsTrue(Pos('2 total Guis ( 1 copies, 1 unique )', FLines.Text) > 0);
end;

procedure TTestGuiManager.WritePrecacheCommandsElencaLeGui;
var
  LOut: TStringList;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  FManager.FindGui('guis/a.gui', True);
  LOut := TStringList.Create;
  try
    FManager.WritePrecacheCommands(LOut);
    Assert.AreEqual('touchGui guis/a.gui', LOut[0]);
  finally
    LOut.Free;
  end;
end;

procedure TTestGuiManager.TouchEControlloDelFile;
begin
  AddGui('guis/a.gui', SIMPLE_GUI);
  Assert.IsTrue(FManager.CheckGui('guis/a.gui'));
  Assert.IsFalse(FManager.CheckGui('guis/zzz.gui'));
  FManager.Touch('guis/a.gui');
  Assert.AreEqual(1, FManager.Count);
  FManager.DeAlloc(FManager.Guis[0]);
  Assert.AreEqual(0, FManager.Count);
end;

procedure TTestGuiManager.LaListaDiUnaGuiScriveLoStato;
var
  LGui: TGuiUserInterface;
  LList: TGuiListGui;
  LText: AnsiString;
begin
  AddGui('guis/l.gui', SIMPLE_GUI);
  LGui := FManager.FindGui('guis/l.gui', True);
  LList := FManager.AllocListGui;
  try
    Assert.IsFalse(LList.IsConfigured);
    LList.Config(LGui, 'files');
    Assert.IsTrue(LList.IsConfigured);
    LList.Add(10, 'ten');
    LList.Add(20, 'twenty');
    LList.Push('pushed');
    Assert.AreEqual('ten', string(LGui.GetStateString('files_item_0')));
    Assert.AreEqual('pushed', string(LGui.GetStateString('files_item_2')));
    LList.Add(20, 'twenty again');
    Assert.AreEqual('twenty again', string(LGui.GetStateString('files_item_1')));
    Assert.IsTrue(LList.Del(10));
    Assert.IsFalse(LList.Del(99));
    Assert.AreEqual('', string(LGui.GetStateString('files_item_2')), 'the line that is left over is cleared');
    LList.SetSelection(1);
    Assert.AreEqual(2, LList.GetSelection(LText));
    Assert.AreEqual('pushed', string(LText));
    LGui.SetStateInt('files_sel_0', 7);
    Assert.AreEqual(-1, LList.GetSelection(LText), 'a selection outside the list');
    LGui.SetStateInt('files_numsel', 3);
    Assert.AreEqual(3, LList.GetNumSelections);
    LList.SetStateChanges(False);
    LList.Add(30, 'quiet');
    Assert.AreEqual('', string(LGui.GetStateString('files_item_2')));
    LList.Shutdown;
    Assert.IsFalse(LList.IsConfigured);
    Assert.AreEqual(0, LList.Count);
  finally
    LList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiManager);

end.
