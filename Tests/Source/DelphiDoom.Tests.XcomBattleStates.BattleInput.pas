{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the input of the battlescape that has no button:   }
{  the scrolling of the map by dragging, the side buttons of the mouse and the  }
{  debug keys (Options::debug), on a real battle                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.BattleInput;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomBattleInput = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    function Ready: Boolean;
    procedure Mouse(AKind: TXcomEventKind; AX, AY, AButton: Integer);
    procedure PressKey(AKey: Integer; AControl: Boolean = False);
    procedure RunUntilIdle;
    function LiveAliens: Integer;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TrascinareColTastoCentraleDovrebbeScorrereLaMappa;
    [Test]
    procedure IlTrascinamentoInvertitoDovrebbeScorrereAlContrario;
    [Test]
    procedure DuranteIlTrascinamentoGliAltriTastiNonFannoNulla;
    [Test]
    procedure UnTrascinamentoBreveESenzaMovimentoEUnClic;
    [Test]
    procedure ITastiLateraliDelMouseDovrebberoCambiareSoldato;
    [Test]
    procedure SenzaLOpzioneDiDebugCtrlDNonFaNulla;
    [Test]
    procedure CtrlDDovrebbeAccendereIlModoDiDebug;
    [Test]
    procedure ITastiDiDebugVoglionoIlModoDiDebug;
    [Test]
    procedure CtrlKDovrebbeUccidereTuttiGliAlieni;
    [Test]
    procedure CtrlJDovrebbeStordireTuttiGliAlieni;
    [Test]
    procedure CtrlVDovrebbeAzzerareLaVisibilitaDelleTegole;
    [Test]
    procedure CtrlWDovrebbePortareIlSoldatoSottoIlCursore;
    [Test]
    procedure NelModoDiDebugIlClicDovrebbeDireLaTegola;
    [Test]
    procedure NelModoDiDebugLInventarioNonCostaUnitaDiTempo;
    [Test]
    procedure LaRotellaDovrebbeCambiareIlLivelloDellaVista;
    [Test]
    procedure ITastiDelleFrecceDovrebberoScorrereLaMappaFinoAlRilascio;
    [Test]
    procedure IlMouseSulBordoDovrebbeScorrereLaMappa;
    [Test]
    procedure ConLoScorrimentoAGrillettoServeIlTastoPremuto;
  end;

implementation

const
  BUTTON_X1 = 6;
  BUTTON_X2 = 7;
  KMOD_LEFT_CTRL = $0040;

procedure TTestXcomBattleInput.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomBattleInput.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomBattleInput.Setup;
begin
  FState := nil;
  if FBench.Available then
  begin
    FBench.Start;
    FState := FBench.PushBattlescape;
    FBench.World.Wait(60);
  end;
end;

procedure TTestXcomBattleInput.TearDown;
begin
  FState := nil;
  FBench.Stop;
end;

function TTestXcomBattleInput.Ready: Boolean;
begin
  Result := Assigned(FState);
  if not Result then
    Assert.Pass('the data of TFTD are not here');
end;

procedure TTestXcomBattleInput.Mouse(AKind: TXcomEventKind; AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := AButton;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
end;

procedure TTestXcomBattleInput.PressKey(AKey: Integer; AControl: Boolean);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  if AControl then
    LEvent.Modifiers := KMOD_LEFT_CTRL;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent.Kind := ekKeyUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
end;

procedure TTestXcomBattleInput.RunUntilIdle;
var
  LGuard: Integer;
begin
  LGuard := 0;
  FBench.World.Wait(60);
  while FState.Game.IsBusy and (not FState.Finished) and (LGuard < 2000) do
  begin
    FBench.World.Wait(50);
    Inc(LGuard);
  end;
  Assert.IsTrue(LGuard < 2000, 'the battle never came back to idle (' + FState.Game.FrontStateName + ')');
end;

function TTestXcomBattleInput.LiveAliens: Integer;
var
  LUnit: TXcomBattleUnit;
begin
  Result := 0;
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_HOSTILE) and (not LUnit.IsOut) then
      Inc(Result);
end;

procedure TTestXcomBattleInput.TrascinareColTastoCentraleDovrebbeScorrereLaMappa;
var
  LBefore: TXcomPosition;
  LAfter: TXcomPosition;
begin
  if not Ready then
    Exit;
  // the middle of the map, far from the borders that scroll by themselves
  Mouse(ekMouseMotion, 300, 120, 0);
  LBefore := FState.Map.Camera.MapOffset;
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_MIDDLE);
  Assert.IsTrue(FState.IsMouseScrolling);
  Mouse(ekMouseMotion, 320, 130, 0);
  Mouse(ekMouseMotion, 340, 140, 0);
  LAfter := FState.Map.Camera.MapOffset;
  // 40 x 20 pixels of the window are 20 x 10 of the screen
  Assert.AreEqual(LBefore.X + 20, LAfter.X);
  Assert.AreEqual(LBefore.Y + 10, LAfter.Y);
  FBench.World.Wait(400);
  Mouse(ekMouseUp, 340, 140, XCOM_BUTTON_MIDDLE);
  Assert.IsFalse(FState.IsMouseScrolling);
  Assert.AreEqual(LAfter.X, FState.Map.Camera.MapOffset.X, 'the map stays where it was dragged');
  Assert.IsFalse(FState.Game.IsBusy, 'the release of a drag is not a click on the map');
end;

procedure TTestXcomBattleInput.IlTrascinamentoInvertitoDovrebbeScorrereAlContrario;
var
  LBefore: TXcomPosition;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('battleDragScrollInvert', 1);
  Mouse(ekMouseMotion, 300, 120, 0);
  LBefore := FState.Map.Camera.MapOffset;
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_MIDDLE);
  Mouse(ekMouseMotion, 340, 140, 0);
  Assert.AreEqual(LBefore.X - 20, FState.Map.Camera.MapOffset.X);
  Assert.AreEqual(LBefore.Y - 10, FState.Map.Camera.MapOffset.Y);
  Assert.AreEqual(Integer(CT_NONE), Integer(FState.Map.Map.CursorType), 'no cursor of the tiles while dragging');
  FBench.World.Wait(400);
  Mouse(ekMouseUp, 340, 140, XCOM_BUTTON_MIDDLE);
  Assert.AreNotEqual(Integer(CT_NONE), Integer(FState.Map.Map.CursorType), 'the cursor comes back');
end;

procedure TTestXcomBattleInput.DuranteIlTrascinamentoGliAltriTastiNonFannoNulla;
var
  LUnit: TXcomBattleUnit;
  LPosition: TXcomPosition;
begin
  if not Ready then
    Exit;
  LUnit := FBench.Session.Battle.SelectedUnit;
  LPosition := LUnit.Position;
  Mouse(ekMouseMotion, 300, 120, 0);
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_MIDDLE);
  Mouse(ekMouseMotion, 330, 130, 0);
  // a left click while the middle button is down
  Mouse(ekMouseDown, 330, 130, XCOM_BUTTON_LEFT);
  Mouse(ekMouseUp, 330, 130, XCOM_BUTTON_LEFT);
  FBench.World.Wait(100);
  Assert.IsFalse(FState.Game.IsBusy, 'nobody walks');
  Assert.IsTrue(LUnit.Position = LPosition);
  Assert.IsTrue(FState.IsMouseScrolling, 'the drag goes on');
  FBench.World.Wait(400);
  Mouse(ekMouseUp, 330, 130, XCOM_BUTTON_MIDDLE);
  Assert.IsFalse(FState.IsMouseScrolling);
end;

procedure TTestXcomBattleInput.UnTrascinamentoBreveESenzaMovimentoEUnClic;
var
  LBefore: TXcomPosition;
begin
  if not Ready then
    Exit;
  Mouse(ekMouseMotion, 300, 120, 0);
  LBefore := FState.Map.Camera.MapOffset;
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_MIDDLE);
  Mouse(ekMouseUp, 300, 120, XCOM_BUTTON_MIDDLE);
  Assert.IsFalse(FState.IsMouseScrolling);
  Assert.IsTrue(FState.Map.Camera.MapOffset = LBefore);
  // entering the map again forgets a drag whose release was lost
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_MIDDLE);
  FState.ClearMouseScrollingState;
  Assert.IsFalse(FState.IsMouseScrolling);
end;

procedure TTestXcomBattleInput.ITastiLateraliDelMouseDovrebberoCambiareSoldato;
var
  LFirst: TXcomBattleUnit;
  LSecond: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  LFirst := FBench.Session.Battle.SelectedUnit;
  Mouse(ekMouseMotion, 300, 120, 0);
  Mouse(ekMouseDown, 300, 120, BUTTON_X1);
  Mouse(ekMouseUp, 300, 120, BUTTON_X1);
  LSecond := FBench.Session.Battle.SelectedUnit;
  Assert.IsTrue(LSecond <> LFirst, 'the next soldier');
  Mouse(ekMouseDown, 300, 120, BUTTON_X2);
  Mouse(ekMouseUp, 300, 120, BUTTON_X2);
  Assert.IsTrue(FBench.Session.Battle.SelectedUnit = LFirst, 'the previous soldier');
end;

procedure TTestXcomBattleInput.SenzaLOpzioneDiDebugCtrlDNonFaNulla;
begin
  if not Ready then
    Exit;
  PressKey(Ord('d'), True);
  Assert.IsFalse(FBench.Session.Battle.DebugMode);
end;

procedure TTestXcomBattleInput.CtrlDDovrebbeAccendereIlModoDiDebug;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  // the key alone is not the debug key
  PressKey(Ord('d'), False);
  Assert.IsFalse(FBench.Session.Battle.DebugMode);
  PressKey(Ord('d'), True);
  Assert.IsTrue(FBench.Session.Battle.DebugMode);
  Assert.AreEqual('Debug Mode', FState.DebugText);
end;

procedure TTestXcomBattleInput.ITastiDiDebugVoglionoIlModoDiDebug;
var
  LAliens: Integer;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  LAliens := LiveAliens;
  Assert.IsTrue(LAliens > 0);
  PressKey(Ord('k'), True);
  PressKey(Ord('j'), True);
  FBench.World.Wait(100);
  Assert.AreEqual(LAliens, LiveAliens, 'without Ctrl+D first nothing happens');
end;

procedure TTestXcomBattleInput.CtrlKDovrebbeUccidereTuttiGliAlieni;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  PressKey(Ord('d'), True);
  PressKey(Ord('k'), True);
  Assert.AreEqual('Influenza bacterium dispersed', FState.DebugText);
  RunUntilIdle;
  Assert.AreEqual(0, LiveAliens);
end;

procedure TTestXcomBattleInput.CtrlJDovrebbeStordireTuttiGliAlieni;
var
  LUnit: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  PressKey(Ord('d'), True);
  PressKey(Ord('j'), True);
  Assert.AreEqual('Deploying Celine Dion album', FState.DebugText);
  RunUntilIdle;
  Assert.AreEqual(0, LiveAliens);
  // stunned, not dead: the units that can be stunned still have their health
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_HOSTILE) and (LUnit.Status = STATUS_UNCONSCIOUS) then
      Assert.IsTrue(LUnit.Health > 0);
end;

procedure TTestXcomBattleInput.CtrlVDovrebbeAzzerareLaVisibilitaDelleTegole;
var
  LTile: TXcomTile;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  LTile := FBench.Session.Battle.SelectedUnit.Tile;
  Assert.IsTrue(LTile.IsDiscovered(2), 'the soldier sees the tile it stands on');
  PressKey(Ord('d'), True);
  PressKey(Ord('v'), True);
  Assert.AreEqual('Resetting tile visibility', FState.DebugText);
  Assert.IsFalse(LTile.IsDiscovered(2));
end;

procedure TTestXcomBattleInput.CtrlWDovrebbePortareIlSoldatoSottoIlCursore;
var
  LUnit: TXcomBattleUnit;
  LTarget: TXcomPosition;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  LUnit := FBench.Session.Battle.SelectedUnit;
  PressKey(Ord('d'), True);
  // the cursor of the tiles goes two tiles away, on a free tile of the map
  Mouse(ekMouseMotion, 300, 120, 0);
  LTarget := FState.Map.Map.SelectorPosition;
  if (not Assigned(FBench.Session.Battle.TileAt(LTarget))) or
    Assigned(FBench.Session.Battle.TileAt(LTarget).CurrentUnit) then
  begin
    Assert.Pass('the tile under the middle of the screen is not free in this scenario');
    Exit;
  end;
  PressKey(Ord('w'), True);
  Assert.AreEqual('Beam me up Scotty', FState.DebugText);
  Assert.IsTrue(LUnit.Position = LTarget);
  Assert.IsTrue(FBench.Session.Battle.TileAt(LTarget).CurrentUnit = LUnit);
end;

procedure TTestXcomBattleInput.NelModoDiDebugIlClicDovrebbeDireLaTegola;
var
  LPosition: TXcomPosition;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  PressKey(Ord('d'), True);
  Mouse(ekMouseMotion, 300, 120, 0);
  LPosition := FState.Map.Map.SelectorPosition;
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_RIGHT);
  Mouse(ekMouseUp, 300, 120, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(Format('Clicked (%d,%d,%d)', [LPosition.X, LPosition.Y, LPosition.Z]), FState.DebugText);
end;

procedure TTestXcomBattleInput.NelModoDiDebugLInventarioNonCostaUnitaDiTempo;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('debug', 1);
  PressKey(Ord('d'), True);
  PressKey(FBench.World.Game.Options.GetValue('keyBattleInventory'));
  Assert.AreEqual('Inventory', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
end;

procedure TTestXcomBattleInput.LaRotellaDovrebbeCambiareIlLivelloDellaVista;
var
  LLevel: Integer;
begin
  if not Ready then
    Exit;
  if FBench.Session.Battle.MapSizeZ < 2 then
  begin
    Assert.Pass('the map of the scenario has one level');
    Exit;
  end;
  Mouse(ekMouseMotion, 300, 120, 0);
  LLevel := FState.Map.Camera.ViewLevel;
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_WHEELUP);
  Mouse(ekMouseUp, 300, 120, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual(LLevel + 1, FState.Map.Camera.ViewLevel);
  Mouse(ekMouseDown, 300, 120, XCOM_BUTTON_WHEELDOWN);
  Mouse(ekMouseUp, 300, 120, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(LLevel, FState.Map.Camera.ViewLevel);
end;

procedure TTestXcomBattleInput.ITastiDelleFrecceDovrebberoScorrereLaMappaFinoAlRilascio;
var
  LBefore: TXcomPosition;
  LAfter: TXcomPosition;
  LEvent: TXcomInputEvent;
  LKey: Integer;
begin
  if not Ready then
    Exit;
  Mouse(ekMouseMotion, 300, 120, 0);
  for LKey in [FBench.World.Game.Options.GetValue('keyBattleRight'),
    FBench.World.Game.Options.GetValue('keyBattleDown'), FBench.World.Game.Options.GetValue('keyBattleLeft'),
    FBench.World.Game.Options.GetValue('keyBattleUp')] do
  begin
    LBefore := FState.Map.Camera.MapOffset;
    LEvent := TXcomInputEvent.Make(ekKeyDown);
    LEvent.Key := LKey;
    FBench.World.Events.Enqueue(LEvent);
    FBench.World.Wait(200);
    LAfter := FState.Map.Camera.MapOffset;
    Assert.IsFalse(LAfter = LBefore, 'the map scrolls while the key is down');
    LEvent.Kind := ekKeyUp;
    FBench.World.Events.Enqueue(LEvent);
    FBench.World.Wait(40);
    LBefore := FState.Map.Camera.MapOffset;
    FBench.World.Wait(200);
    Assert.IsTrue(FState.Map.Camera.MapOffset = LBefore, 'and stops when it is released');
  end;
end;

procedure TTestXcomBattleInput.IlMouseSulBordoDovrebbeScorrereLaMappa;
var
  LBefore: TXcomPosition;
begin
  if not Ready then
    Exit;
  // battleEdgeScroll 2: the mouse on a border is enough
  FBench.World.Game.Options.SetValue('battleEdgeScroll', 2);
  Mouse(ekMouseMotion, 300, 120, 0);
  LBefore := FState.Map.Camera.MapOffset;
  FBench.World.Wait(200);
  Assert.IsTrue(FState.Map.Camera.MapOffset = LBefore, 'in the middle nothing scrolls');
  Mouse(ekMouseMotion, 2, 120, 0);
  FBench.World.Wait(300);
  Assert.IsFalse(FState.Map.Camera.MapOffset = LBefore, 'the left border scrolls');
  Mouse(ekMouseMotion, 300, 120, 0);
  LBefore := FState.Map.Camera.MapOffset;
  FBench.World.Wait(200);
  Assert.IsTrue(FState.Map.Camera.MapOffset = LBefore, 'back in the middle it stops');
  Mouse(ekMouseMotion, 637, 120, 0);
  FBench.World.Wait(300);
  Assert.IsFalse(FState.Map.Camera.MapOffset = LBefore, 'the right border scrolls');
end;

procedure TTestXcomBattleInput.ConLoScorrimentoAGrillettoServeIlTastoPremuto;
var
  LBefore: TXcomPosition;
begin
  if not Ready then
    Exit;
  // battleEdgeScroll 1: the border scrolls only while the left button is down
  // the mouse of the test starts in the corner, which scrolls in the automatic mode: it goes to the middle first
  // (as in the C++ a change of the option does not stop a scroll that is already going)
  Mouse(ekMouseMotion, 300, 120, 0);
  FBench.World.Game.Options.SetValue('battleEdgeScroll', 1);
  LBefore := FState.Map.Camera.MapOffset;
  FBench.World.Wait(300);
  Assert.IsTrue(FState.Map.Camera.MapOffset = LBefore, 'in the middle nothing scrolls');
  Mouse(ekMouseMotion, 2, 120, 0);
  LBefore := FState.Map.Camera.MapOffset;
  FBench.World.Wait(300);
  Assert.AreEqual(LBefore.X, FState.Map.Camera.MapOffset.X, 'without the button nothing scrolls (x)');
  Assert.AreEqual(LBefore.Y, FState.Map.Camera.MapOffset.Y, 'without the button nothing scrolls (y)');
  Mouse(ekMouseDown, 2, 120, XCOM_BUTTON_LEFT);
  FBench.World.Wait(300);
  Assert.IsFalse(FState.Map.Camera.MapOffset = LBefore, 'with the button down it scrolls');
  Mouse(ekMouseUp, 2, 120, XCOM_BUTTON_LEFT);
  LBefore := FState.Map.Camera.MapOffset;
  FBench.World.Wait(300);
  Assert.IsTrue(FState.Map.Camera.MapOffset = LBefore, 'the release stops it');
  Assert.IsFalse(FState.Game.IsBusy, 'and is not a click on the map');
end;

end.
