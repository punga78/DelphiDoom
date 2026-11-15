{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scene of the map on real data    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiScene;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Ui.Game, DelphiDoom.War.MapUi.Scene;

type
  /// <summary>What the scene of the map does besides drawing: what it answers to the harness, the status bar, the speed and the end</summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapUiScene = class(TObject)
  strict private
    FGame: TWarUiGame;
    FScene: TWarMapScene;
    procedure Run(const ALines: array of string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereLaScenaDellaMappaECapireSoloICommandiDellaMappa;
    [Test]
    procedure DovrebbeDireCheIlContadinoPortaOroOLegnaSeEPieno;
    [Test]
    procedure DovrebbeScalareIlTempoDelGiocoConLaVelocita;
    [Test]
    procedure DovrebbeFermarsiQuandoLaMappaFinisce;
    [Test]
    procedure DovrebbeRifiutareUnComandoDelloScriptCheNonEDellaMappa;
    [Test]
    procedure DovrebbeAprireIlMenuConF10ERiprendereConC;
    [Test]
    procedure DovrebbeAprireIlMenuDellaFineConLaVittoriaELaDemoSullUltimaMappa;
    [Test]
    procedure DovrebbePortareAlBriefingDopoLaFine;
    [Test]
    procedure DovrebbeTornareAlMenuPrincipaleDopoUnaPartitaPersonalizzata;
    [Test]
    procedure DovrebbeRifiutareIlProseguireSenzaUnRisultato;
    [Test]
    procedure DovrebbeRicominciareLaMappaEUscire;
    [Test]
    procedure DovrebbeFarCorrereIlTempoDelGiocoAnchePrimaDiRiprendere;
    [Test]
    procedure DovrebbeFarScrivereIlPannelloDeiTrucchiESpegnereIGruppi;
    [Test]
    procedure DovrebbeScegliereUnModoDiModificaEFarlo;
    [Test]
    procedure DovrebbeSpegnereLaNebbiaESaltareAUnBriefing;
    [Test]
    procedure DovrebbeFermarsiConIlTrucco;
    [Test]
    procedure DovrebbeMostrareIlTestoDiDebugEScrivereLeRigheNellaTraccia;
    [Test]
    procedure DovrebbeDisegnareIlDebugDelleGriglie;
  end;

implementation

uses
  Winapi.Windows, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.Campaign.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.MapUi.Types,
  DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.UiRig;

{ TTestWarMapUiScene }

procedure TTestWarMapUiScene.Setup;
begin
  TWarRealData.RequireDataWar;
  FGame := TWarUiRig.CreateRealMapGame;
  Run(['campaign human 1', 'move 190 100', 'run 10 1']);
  FScene := FGame.Manager.Scene as TWarMapScene;
end;

procedure TTestWarMapUiScene.TearDown;
begin
  FScene := nil;
  FGame.Free;
end;

procedure TTestWarMapUiScene.Run(const ALines: array of string);
var
  LLines: TArray<string>;
  LIndex: Integer;
  LOutput: TStringList;
begin
  SetLength(LLines, Length(ALines));
  for LIndex := 0 to High(ALines) do
    LLines[LIndex] := ALines[LIndex];
  LOutput := TWarUiRig.RunScript(FGame, LLines, nil);
  LOutput.Free;
end;

procedure TTestWarMapUiScene.DovrebbeEssereLaScenaDellaMappaECapireSoloICommandiDellaMappa;
begin
  Assert.IsTrue(FScene.GetSceneType = wstMap);
  FScene.HandleTextInput('abc');
  Assert.IsFalse(FScene.ScriptCommand('inesistente', []));
  Assert.IsTrue(FScene.ScriptCommand('gold', ['123', '45']));
  Assert.AreEqual(123, FScene.Binding.World.Context.Players[0]^.Gold);
  Assert.AreEqual(45, FScene.Binding.World.Context.Players[0]^.Wood);
  Assert.IsTrue(FScene.Playing);
end;

procedure TTestWarMapUiScene.DovrebbeDireCheIlContadinoPortaOroOLegnaSeEPieno;
var
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  // a peasant made on the screen and selected with a click
  Run(['unit 2 150 90 0', 'run 3 1', 'move 150 90', 'run 3 1', 'lbutton down', 'run 2 1', 'lbutton up', 'run 4 1']);
  Assert.AreEqual(1, FScene.Binding.World.Context.Selection.Count);
  LSlot := FScene.Binding.World.Context.Pool.FindSlot(FScene.Binding.World.Context.Selection[0]);
  LEntity := FScene.Binding.World.Context.Pool.Slots[LSlot];
  Assert.AreEqual(WAR_UNIT_PEASANT, LEntity^.UnitData.UnitType);
  LEntity^.UnitData.ResourceKind := wrkGold;
  LEntity^.UnitData.Amount := WAR_MODEL_MAX_CARRY;
  Run(['run 2 1']);
  Assert.AreEqual('CARRYING GOLD', string(FScene.StatusText));
  LEntity^.UnitData.ResourceKind := wrkWood;
  Run(['run 2 1']);
  Assert.AreEqual('CARRYING LUMBER', string(FScene.StatusText));
end;

procedure TTestWarMapUiScene.DovrebbeScalareIlTempoDelGiocoConLaVelocita;
var
  LStart: Double;
  LNormal: Double;
  LFast: Double;
  LSlow: Double;
begin
  LStart := FScene.Binding.World.Context.Clock^.GameTime;
  Run(['run 30 30']);
  LNormal := FScene.Binding.World.Context.Clock^.GameTime - LStart;
  FScene.GameSpeed := 4;
  LStart := FScene.Binding.World.Context.Clock^.GameTime;
  Run(['run 30 30']);
  LFast := FScene.Binding.World.Context.Clock^.GameTime - LStart;
  FScene.GameSpeed := 0;
  LStart := FScene.Binding.World.Context.Clock^.GameTime;
  Run(['run 30 30']);
  LSlow := FScene.Binding.World.Context.Clock^.GameTime - LStart;
  Assert.IsTrue(LFast > LNormal * 1.5, 'la velocita'' piu'' alta corre di piu''');
  Assert.IsTrue(LSlow < LNormal * 0.8, 'la velocita'' piu'' bassa corre di meno');
end;

procedure TTestWarMapUiScene.DovrebbeFermarsiQuandoLaMappaFinisce;
begin
  FScene.Conclude(wlrWin);
  Run(['run 3 1']);
  Assert.IsTrue(FScene.Result = wlrWin);
  Assert.IsFalse(FScene.Playing, 'la mappa e'' finita: non gira piu''');
end;

procedure TTestWarMapUiScene.DovrebbeRifiutareUnComandoDelloScriptCheNonEDellaMappa;
begin
  Assert.WillRaise(
    procedure
    begin
      Run(['comando_che_non_esiste']);
    end, EWarException);
end;

procedure TTestWarMapUiScene.DovrebbeAprireIlMenuConF10ERiprendereConC;
begin
  Run(['key f10 down', 'run 1 1', 'key f10 up', 'run 3 1']);
  Assert.IsTrue(FScene.Menu.State = wmsMain);
  Assert.IsFalse(FScene.Playing);
  // the mouse is dropped: no drag survives a menu
  Run(['key c down', 'run 1 1', 'key c up', 'run 3 1']);
  Assert.IsTrue(FScene.Menu.State = wmsNone);
  Assert.IsTrue(FScene.Playing);
end;

procedure TTestWarMapUiScene.DovrebbeAprireIlMenuDellaFineConLaVittoriaELaDemoSullUltimaMappa;
begin
  FScene.Conclude(wlrWin);
  Run(['run 3 1']);
  Assert.IsTrue(FScene.Menu.State = wmsGameOver);
  Assert.IsFalse(FScene.Playing);
  // the last map of the demo opens the menu of the end of the demo
  FScene := nil;
  FGame.Free;
  FGame := TWarUiRig.CreateRealMapGame;
  Run(['campaign human 2', 'run 5 1']);
  FScene := FGame.Manager.Scene as TWarMapScene;
  FScene.Conclude(wlrWin);
  Run(['run 3 1']);
  Assert.IsTrue(FScene.Menu.State = wmsDemoEnd);
  // a defeat on it is the usual one
  FScene := nil;
  FGame.Free;
  FGame := TWarUiRig.CreateRealMapGame;
  Run(['campaign human 2', 'run 5 1']);
  FScene := FGame.Manager.Scene as TWarMapScene;
  FScene.Conclude(wlrLose);
  Run(['run 3 1']);
  Assert.IsTrue(FScene.Menu.State = wmsGameOver);
end;

procedure TTestWarMapUiScene.DovrebbePortareAlBriefingDopoLaFine;
begin
  FScene.Conclude(wlrWin);
  Run(['run 3 1', 'key c down', 'run 1 1', 'key c up', 'run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstBriefing);
  // a defeat shows the same briefing again (the second map after a victory, the first after a defeat)
  FScene := nil;
  FGame.Free;
  FGame := TWarUiRig.CreateRealMapGame;
  Run(['campaign orc 1', 'run 5 1']);
  FScene := FGame.Manager.Scene as TWarMapScene;
  FScene.Conclude(wlrLose);
  Run(['run 3 1', 'key o down', 'run 1 1', 'key o up', 'run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstBriefing);
end;

procedure TTestWarMapUiScene.DovrebbeTornareAlMenuPrincipaleDopoUnaPartitaPersonalizzata;
begin
  FScene := nil;
  FGame.Free;
  FGame := TWarUiRig.CreateRealMapGame;
  Run(['custom 147', 'run 5 1']);
  FScene := FGame.Manager.Scene as TWarMapScene;
  FScene.Conclude(wlrWin);
  Run(['run 3 1', 'key c down', 'run 1 1', 'key c up', 'run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstMainMenu);
end;

procedure TTestWarMapUiScene.DovrebbeRifiutareIlProseguireSenzaUnRisultato;
begin
  Assert.WillRaise(
    procedure
    begin
      FScene.ContinueAfterGameOver;
    end, EWarException);
end;

procedure TTestWarMapUiScene.DovrebbeRicominciareLaMappaEUscire;
var
  LBefore: TWarMapScene;
begin
  LBefore := FScene;
  FScene.RestartMap;
  Run(['run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstMap);
  Assert.IsFalse(FGame.Manager.Scene = IWarScene(LBefore));
  FScene := FGame.Manager.Scene as TWarMapScene;
  Assert.IsFalse(FGame.Manager.QuitRequested);
  FScene.QuitGame;
  Assert.IsTrue(FGame.Manager.QuitRequested);
  FScene.ReturnToMainMenu;
  Run(['run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstMainMenu);
end;

procedure TTestWarMapUiScene.DovrebbeFarCorrereIlTempoDelGiocoAnchePrimaDiRiprendere;
var
  LStart: Double;
begin
  LStart := FScene.Binding.World.Context.Clock^.GameTime;
  Run(['key f10 down', 'run 1 1', 'key f10 up', 'run 30 30']);
  // the menu is open: nothing is updated but the time of the game goes on, as in the original
  Assert.IsTrue(FScene.Binding.World.Context.Clock^.GameTime - LStart > 0.4);
end;

procedure TTestWarMapUiScene.DovrebbeFarScrivereIlPannelloDeiTrucchiESpegnereIGruppi;
begin
  Run(['key enter down', 'run 1 1', 'key enter up', 'run 2 1', 'text 12ab']);
  Assert.IsTrue(FScene.Cheats.Visible);
  Assert.AreEqual('12ab', string(FScene.Cheats.Text));
  // the line says what it holds, in the status bar
  Run(['run 2 1']);
  Assert.AreEqual('MSG: 12ab', string(FScene.StatusText));
  Run(['key esc down', 'run 1 1', 'key esc up', 'run 3 1']);
  Assert.IsFalse(FScene.Cheats.Visible);
  Assert.AreEqual('', string(FScene.StatusText));
  // a text sent with the line closed is dropped
  FScene.HandleTextInput('zzz');
  Assert.AreEqual('', string(FScene.Cheats.Text));
end;

procedure TTestWarMapUiScene.DovrebbeScegliereUnModoDiModificaEFarlo;
begin
  Assert.IsTrue(FScene.GetEditMode = wemNone);
  FScene.SetEditing(wemAddUnit, WAR_UNIT_FOOTMAN);
  Assert.IsTrue(FScene.GetEditMode = wemAddUnit);
  Run(['move 190 100', 'lbutton down', 'run 2 1', 'lbutton up', 'run 3 1']);
  Assert.IsTrue(FScene.Binding.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count > 0);
  FScene.SetEditing(wemTrees, 0);
  Assert.IsTrue(FScene.GetEditMode = wemTrees);
  // a mode that only edits the ground does nothing with a click, and the click is still free
  Run(['move 190 100', 'lbutton down', 'run 2 1', 'lbutton up', 'run 3 1']);
  FScene.SetEditing(wemRainOfFire, 0);
  Run(['move 190 100', 'lbutton down', 'run 2 1', 'lbutton up', 'run 3 1']);
  FScene.SetEditing(wemNone, 0);
end;

procedure TTestWarMapUiScene.DovrebbeSpegnereLaNebbiaESaltareAUnBriefing;
begin
  Assert.IsTrue(FScene.Map.Fog.Enabled);
  FScene.ToggleFog;
  Assert.IsFalse(FScene.Map.Fog.Enabled);
  FScene.ToggleFog;
  Assert.IsTrue(FScene.Map.Fog.Enabled);
  FScene.SkipToBriefing(wraOrcs, WAR_CAMPAIGN_ORCS_02);
  Run(['run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstBriefing);
end;

procedure TTestWarMapUiScene.DovrebbeFermarsiConIlTrucco;
begin
  FScene.ShowDemoEnd;
  Assert.IsFalse(FScene.Playing);
  Assert.IsTrue(FScene.Menu.State = wmsDemoEnd);
  Run(['run 3 1', 'key m down', 'run 1 1', 'key m up', 'run 70 1']);
  Assert.IsTrue(FGame.Manager.Scene.GetSceneType = wstMainMenu);
end;

procedure TTestWarMapUiScene.DovrebbeDisegnareIlDebugDelleGriglie;
begin
  Run(['key enter down', 'run 1 1', 'key enter up', 'run 2 1', 'text Debug render map-grid',
    'key enter down', 'run 1 1', 'key enter up', 'run 2 1']);
  Assert.AreEqual('map-grid on', string(FScene.Cheats.FeedbackText));
end;

procedure TTestWarMapUiScene.DovrebbeMostrareIlTestoDiDebugEScrivereLeRigheNellaTraccia;
var
  LTrace: TStringList;
  LOutput: TStringList;
  LCount: Integer;
begin
  // the debug text of the cheat line is drawn when there is no feedback
  FScene.Cheats.SetDebugText('debug');
  Run(['run 200 100']);
  Assert.IsTrue(FScene.Cheats.DebugTextActive);
  // the lines of the debug drawing and the state of the generator go in the trace and the output of the runner
  LTrace := TStringList.Create;
  try
    Run(['key enter down', 'run 1 1', 'key enter up', 'run 2 1', 'text Debug render map-grid', 'key enter down',
      'run 1 1', 'key enter up', 'run 2 1']);
    Winapi.Windows.SetEnvironmentVariable('DELPHIDOOM_WAR_RNGTRACE', '1');
    try
      LOutput := TWarUiRig.RunScript(FGame, ['trace on', 'run 2 1', 'trace off'], LTrace);
    finally
      Winapi.Windows.SetEnvironmentVariable('DELPHIDOOM_WAR_RNGTRACE', nil);
    end;
    try
      Assert.IsTrue(LOutput.Count > 2, 'the lines D of the generator');
    finally
      LOutput.Free;
    end;
    Assert.IsTrue(Pos('L ', LTrace.Text) > 0, 'a line of the grid in the trace');
  finally
    LTrace.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiScene);

end.
