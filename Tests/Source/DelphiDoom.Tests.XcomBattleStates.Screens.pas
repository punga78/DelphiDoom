{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the screens of the battle made by the library           }
{  (TXcomBattleScreens) on a real battle of TFTD: every button of the           }
{  battlescape opens its screen, which draws and closes                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.Screens;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomBattleScreens = class
  strict private
    FBench: TBattleBench;
    FScreens: IXcomBattleScreens;
    FState: TXcomBattlescapeState;
    FDebriefings: Integer;
    FOptions: Integer;
    function Ready: Boolean;
    procedure ClickPanel(AX, AY: Integer);
    procedure Show(AState: TXcomState; const AClassName: string);
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
    procedure DovrebbeDareOgniSchermataDellaLibreriaEDisegnarla;
    [Test]
    procedure DovrebbeChiedereDebriefingEPausaAlProgramma;
    [Test]
    procedure SenzaFunzioniDebriefingEPausaNonDannoSchermate;
    [Test]
    procedure IlPulsanteDellInventarioDovrebbeAprirloEOkChiuderlo;
    [Test]
    procedure IlPulsanteDelleStatisticheDovrebbeAprireLaSchedaDelSoldato;
    [Test]
    procedure IlTurnoDovrebbeFinireConLaSchermataVeraEIlClic;
  end;

implementation

uses
  DelphiDoom.XcomBattleStates.Screens;

procedure TTestXcomBattleScreens.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomBattleScreens.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomBattleScreens.Setup;
begin
  FState := nil;
  FDebriefings := 0;
  FOptions := 0;
  if FBench.Available then
  begin
    FBench.Start;
    FScreens := TXcomBattleScreens.Create(
      function(AParent: TXcomState): TXcomState
      begin
        Inc(FDebriefings);
        Result := TXcomState.Create(AParent.Host);
      end,
      function(AParent: TXcomState): TXcomState
      begin
        Inc(FOptions);
        Result := TXcomState.Create(AParent.Host);
      end);
    FState := TXcomBattlescapeState.Create(FBench.World.Game, FBench.Session, FScreens, nil);
    FBench.World.Game.PushState(FState);
    FBench.World.Wait(40);
  end;
end;

procedure TTestXcomBattleScreens.TearDown;
begin
  FState := nil;
  FBench.Stop;
  FScreens := nil;
end;

function TTestXcomBattleScreens.Ready: Boolean;
begin
  Result := Assigned(FState);
  if not Result then
    Assert.Pass('the data of TFTD are not here');
end;

procedure TTestXcomBattleScreens.ClickPanel(AX, AY: Integer);
begin
  FBench.World.Click(AX * 2, (144 + AY) * 2);
end;

procedure TTestXcomBattleScreens.Show(AState: TXcomState; const AClassName: string);
begin
  Assert.IsNotNull(AState, AClassName);
  Assert.AreEqual(AClassName, AState.ClassName);
  FBench.World.Game.PushState(AState);
  // long enough for a popup window to open and for every surface to be drawn
  FBench.World.Wait(400);
  Assert.IsTrue(FBench.World.Game.IsState(AState), AClassName + ' closed by itself');
  FBench.World.Game.PopState;
  FBench.World.Wait(40);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomBattleScreens.DovrebbeDareOgniSchermataDellaLibreriaEDisegnarla;
begin
  if not Ready then
    Exit;
  // the action menu and the grenade timer need the interface of the real rules: their own tests cover them
  Show(FScreens.UnitInfo(FState, FBench.Session.Battle.SelectedUnit, False, False), 'TXcomUnitInfoState');
  Show(FScreens.UnitInfo(FState, FBench.Session.Battle.SelectedUnit, False, True), 'TXcomUnitInfoState');
  Show(FScreens.Inventory(FState, True), 'TXcomInventoryState');
  Show(FScreens.Inventory(FState, False), 'TXcomInventoryState');
  Show(FScreens.MiniMap(FState), 'TXcomMiniMapState');
  Show(FScreens.AbortMission(FState), 'TXcomAbortMissionState');
  Show(FScreens.NextTurn(FState), 'TXcomNextTurnState');
  Show(FScreens.Infobox(FState, 'x'), 'TXcomInfoboxState');
  Show(FScreens.InfoboxOk(FState, 'x'), 'TXcomInfoboxOkState');
end;

procedure TTestXcomBattleScreens.DovrebbeChiedereDebriefingEPausaAlProgramma;
var
  LState: TXcomState;
begin
  if not Ready then
    Exit;
  LState := FScreens.Debriefing(FState);
  Assert.IsNotNull(LState);
  LState.Free;
  LState := FScreens.Options(FState);
  Assert.IsNotNull(LState);
  LState.Free;
  Assert.AreEqual(1, FDebriefings);
  Assert.AreEqual(1, FOptions);
end;

procedure TTestXcomBattleScreens.SenzaFunzioniDebriefingEPausaNonDannoSchermate;
var
  LScreens: IXcomBattleScreens;
begin
  if not Ready then
    Exit;
  LScreens := TXcomBattleScreens.Create;
  Assert.IsNull(LScreens.Debriefing(FState));
  Assert.IsNull(LScreens.Options(FState));
end;

procedure TTestXcomBattleScreens.IlPulsanteDellInventarioDovrebbeAprirloEOkChiuderlo;
begin
  if not Ready then
    Exit;
  ClickPanel(144 + 16, 8);
  FBench.World.Wait(300);
  Assert.IsFalse(FBench.World.Game.IsState(FState), 'the inventory did not open');
  // the OK button of the inventory: top right, 35x22 at (237,1)
  FBench.World.Click((237 + 17) * 2, (1 + 11) * 2);
  FBench.World.Wait(100);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'the inventory did not close');
end;

procedure TTestXcomBattleScreens.IlPulsanteDelleStatisticheDovrebbeAprireLaSchedaDelSoldato;
var
  LEvent: TXcomInputEvent;
begin
  if not Ready then
    Exit;
  ClickPanel(200, 44);
  FBench.World.Wait(300);
  Assert.IsFalse(FBench.World.Game.IsState(FState), 'the unit info did not open');
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := XCOM_KEY_ESCAPE;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(40);
  LEvent.Kind := ekKeyUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(100);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'the unit info did not close');
end;

procedure TTestXcomBattleScreens.IlTurnoDovrebbeFinireConLaSchermataVeraEIlClic;
var
  LGuard: Integer;
begin
  if not Ready then
    Exit;
  ClickPanel(240 + 16, 8);
  FBench.World.Wait(200);
  Assert.IsFalse(FBench.World.Game.IsState(FState), 'the next turn screen did not open');
  Assert.AreEqual(FACTION_HOSTILE, FBench.Session.Battle.Side);
  // a click closes every turn screen; the other sides play in between
  LGuard := 0;
  while ((FBench.Session.Battle.Side <> FACTION_PLAYER) or (not FBench.World.Game.IsState(FState))) and
    (LGuard < 600) do
  begin
    if not FBench.World.Game.IsState(FState) then
      FBench.World.Click(320, 100)
    else
      FBench.World.Wait(100);
    Inc(LGuard);
  end;
  Assert.AreEqual(FACTION_PLAYER, FBench.Session.Battle.Side);
  Assert.AreEqual(2, FBench.Session.Battle.Turn);
  Assert.IsFalse(FState.Finished);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBattleScreens);

end.
