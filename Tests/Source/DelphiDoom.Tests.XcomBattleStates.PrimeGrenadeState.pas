{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the choice of the turns of the fuse of a grenade        }
{  (PrimeGrenadeState) on a real battle of TFTD                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.PrimeGrenadeState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattleStates.PrimeGrenadeState,
  DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomBattleStates.Battle;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomPrimeGrenadeState = class
  strict private
    FBattle: TTestBattle;
    FWorld: TTestWorld;
    FAction: TXcomBattleAction;
    FBase: TXcomState;
    FMenu: TXcomState;
    FTimer: TXcomPrimeGrenadeState;
    function Skip: Boolean;
    procedure OpenTimer(AInInventoryView: Boolean);
    procedure ClickButton(AIndex: Integer);
    procedure RightClick;
    function Grenade: TXcomBattleItem;
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
    procedure DovrebbeMettereIVentiquattroBottoniSuTreRighe;
    [Test]
    procedure DovrebbeScrivereITurniNellAzioneEChiudereAncheIlMenu;
    [Test]
    procedure DovrebbeRinunciareColTastoDestroLasciandoIlMenu;
    [Test]
    procedure DovrebbeInnescareLaGranataDellInventario;
    [Test]
    procedure DovrebbeNonToccareLaGranataDellInventarioColTastoDestro;
  end;

implementation

procedure TTestXcomPrimeGrenadeState.SetupFixture;
begin
  FBattle := TTestBattle.Create;
end;

procedure TTestXcomPrimeGrenadeState.TearDownFixture;
begin
  FBattle.Free;
end;

procedure TTestXcomPrimeGrenadeState.Setup;
begin
  if not FBattle.Available then
    Exit;
  FWorld := TTestWorld.Create;
  FWorld.Game.AdoptData(TTestBattleResources.Create(FWorld.Game.Resources), nil);
  FBattle.Open;
  FAction := TXcomBattleAction.Create;
  FAction.Value := 99;
  FBase := TXcomState.Create(FWorld.Game);
  FWorld.Game.PushState(FBase);
  // what stands for the action menu under the timer
  FMenu := TXcomState.Create(FWorld.Game);
  FWorld.Game.PushState(FMenu);
end;

procedure TTestXcomPrimeGrenadeState.TearDown;
begin
  if not FBattle.Available then
    Exit;
  // the states hold the session: they go first
  FreeAndNil(FWorld);
  FreeAndNil(FAction);
  FBattle.Close;
end;

function TTestXcomPrimeGrenadeState.Skip: Boolean;
begin
  Result := not FBattle.Available;
  if Result then
    TTestSkip.Ignore('the data of TFTD is not on this machine');
end;

function TTestXcomPrimeGrenadeState.Grenade: TXcomBattleItem;
begin
  Result := FBattle.FindItem(TEST_BATTLE_GRENADE);
end;

procedure TTestXcomPrimeGrenadeState.OpenTimer(AInInventoryView: Boolean);
begin
  if AInInventoryView then
    FTimer := TXcomPrimeGrenadeState.Create(FWorld.Game, FBattle.Session, nil, True, Grenade)
  else
    FTimer := TXcomPrimeGrenadeState.Create(FWorld.Game, FBattle.Session, FAction, False, nil);
  FWorld.Game.PushState(FTimer);
  FWorld.Wait(20);
end;

procedure TTestXcomPrimeGrenadeState.ClickButton(AIndex: Integer);
begin
  // the window is twice the screen of the game
  FWorld.Click((FTimer.Button(AIndex).X + 11) * 2, (FTimer.Button(AIndex).Y + 11) * 2);
end;

procedure TTestXcomPrimeGrenadeState.RightClick;
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := 5;
  LEvent.Y := 5;
  LEvent.Button := XCOM_BUTTON_RIGHT;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

procedure TTestXcomPrimeGrenadeState.DovrebbeMettereIVentiquattroBottoniSuTreRighe;
begin
  if Skip then
    Exit;
  OpenTimer(False);
  Assert.IsFalse(FTimer.IsScreen);
  Assert.AreEqual(66, FTimer.Button(0).X);
  Assert.AreEqual(64, FTimer.Button(0).Y);
  Assert.AreEqual(22, FTimer.Button(0).Width);
  Assert.AreEqual(22, FTimer.Button(0).Height);
  Assert.AreEqual(66 + 7 * 24, FTimer.Button(7).X);
  Assert.AreEqual(64, FTimer.Button(7).Y);
  Assert.AreEqual(66, FTimer.Button(8).X);
  Assert.AreEqual(64 + 25, FTimer.Button(8).Y);
  Assert.AreEqual(66 + 7 * 24, FTimer.Button(23).X);
  Assert.AreEqual(64 + 50, FTimer.Button(23).Y);
  // the border (grenadeBackground.border) around the inside (color2)
  Assert.AreEqual(55, Integer(FTimer.Button(0).GetPixel(0, 0)));
  Assert.AreEqual(63, Integer(FTimer.Button(0).GetPixel(1, 1)));
end;

procedure TTestXcomPrimeGrenadeState.DovrebbeScrivereITurniNellAzioneEChiudereAncheIlMenu;
begin
  if Skip then
    Exit;
  OpenTimer(False);
  ClickButton(3);
  Assert.AreEqual(3, FAction.Value);
  Assert.AreSame(FBase, FWorld.Game.TopState, 'the timer and the menu are closed');
end;

procedure TTestXcomPrimeGrenadeState.DovrebbeRinunciareColTastoDestroLasciandoIlMenu;
begin
  if Skip then
    Exit;
  OpenTimer(False);
  RightClick;
  Assert.AreEqual(-1, FAction.Value);
  Assert.AreSame(FMenu, FWorld.Game.TopState);
end;

procedure TTestXcomPrimeGrenadeState.DovrebbeInnescareLaGranataDellInventario;
begin
  if Skip then
    Exit;
  Assert.AreEqual(-1, Grenade.FuseTimer);
  OpenTimer(True);
  ClickButton(10);
  Assert.AreEqual(10, Grenade.FuseTimer);
  Assert.AreSame(FMenu, FWorld.Game.TopState, 'only the timer is closed');
end;

procedure TTestXcomPrimeGrenadeState.DovrebbeNonToccareLaGranataDellInventarioColTastoDestro;
begin
  if Skip then
    Exit;
  OpenTimer(True);
  RightClick;
  Assert.AreEqual(-1, Grenade.FuseTimer);
  Assert.AreSame(FMenu, FWorld.Game.TopState);
end;

end.
