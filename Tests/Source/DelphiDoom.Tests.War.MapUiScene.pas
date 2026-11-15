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
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.Campaign.Types, DelphiDoom.War.Model.Types, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.UiRig;

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

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiScene);

end.
