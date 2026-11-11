{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the screens around a turn of the battle: NextTurnState, }
{  InfoboxState, InfoboxOKState, BriefingState, AliensCrashState                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.TurnScreens;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattleStates.BattlescapeState,
  DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomTurnScreens = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    function Ready: Boolean;
    procedure PressKey(AKey: Integer);
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
    procedure IlCambioDiTurnoDovrebbeChiudersiConUnClicETornareAllaBattaglia;
    [Test]
    procedure IlCambioDiTurnoDovrebbeChiudersiDaSoloConLOpzione;
    [Test]
    procedure IlCambioDiTurnoSenzaAlieniViviDovrebbeFinireLaBattaglia;
    [Test]
    procedure IlCambioDiTurnoSenzaSoldatiViviDovrebbeFinireLaBattagliaAncheNellaMissioneFinale;
    [Test]
    procedure NellaMissioneFinaleGliAlieniMortiNonFinisconoLaBattaglia;
    [Test]
    procedure IlMessaggioDovrebbeSparireDopoDueSecondi;
    [Test]
    procedure IlMessaggioDovrebbeSparireConUnTasto;
    [Test]
    procedure IlMessaggioConOkDovrebbeAspettareIlPulsante;
    [Test]
    procedure IlBriefingDovrebbeMostrareLaMissioneEChiamareIlSeguitoConOk;
    [Test]
    procedure GliAlieniMortiNelloSchiantoDovrebberoPortareAlSeguitoConOk;
    [Test]
    procedure GliAlieniMortiNelloSchiantoDovrebberoTenereVivaLaGraficaFinoAllaChiusura;
  end;

implementation

uses
  DelphiDoom.XcomBattleStates.NextTurnState, DelphiDoom.XcomBattleStates.InfoboxState,
  DelphiDoom.XcomBattleStates.InfoboxOkState, DelphiDoom.XcomBattleStates.BriefingState,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomBattleStates.AliensCrashState,
  DelphiDoom.XcomBattleStates.Graphics.Intf;

procedure TTestXcomTurnScreens.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomTurnScreens.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomTurnScreens.Setup;
begin
  FState := nil;
  if FBench.Available then
  begin
    FBench.Start;
    FState := FBench.PushBattlescape;
  end;
end;

procedure TTestXcomTurnScreens.TearDown;
begin
  FState := nil;
  FBench.Stop;
end;

function TTestXcomTurnScreens.Ready: Boolean;
begin
  Result := Assigned(FState);
  if not Result then
    Assert.Pass('the data of TFTD are not here');
end;

procedure TTestXcomTurnScreens.PressKey(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent.Kind := ekKeyUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
end;

procedure TTestXcomTurnScreens.IlCambioDiTurnoDovrebbeChiudersiConUnClicETornareAllaBattaglia;
var
  LNext: TXcomState;
begin
  if not Ready then
    Exit;
  LNext := TXcomNextTurnState.Create(FBench.World.Game, FState);
  FBench.World.Game.PushState(LNext);
  FBench.World.Wait(40);
  Assert.IsTrue(FBench.World.Game.IsState(LNext));
  FBench.World.Wait(1000);
  Assert.IsTrue(FBench.World.Game.IsState(LNext), 'it must wait for the player');
  FBench.World.Click(320, 100);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
  Assert.IsFalse(FState.Finished);
end;

procedure TTestXcomTurnScreens.IlCambioDiTurnoDovrebbeChiudersiDaSoloConLOpzione;
var
  LNext: TXcomState;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('skipNextTurnScreen', 1);
  LNext := TXcomNextTurnState.Create(FBench.World.Game, FState);
  FBench.World.Game.PushState(LNext);
  FBench.World.Wait(300);
  Assert.IsTrue(FBench.World.Game.IsState(LNext));
  FBench.World.Wait(400);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.IlCambioDiTurnoSenzaAlieniViviDovrebbeFinireLaBattaglia;
var
  LNext: TXcomState;
  LUnit: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  for LUnit in FBench.Session.Battle.Units do
    if LUnit.OriginalFaction = FACTION_HOSTILE then
      LUnit.InstaKill;
  // not the final mission, where the objective and not the aliens ends the battle
  FBench.Session.Battle.ObjectiveType := -1;
  LNext := TXcomNextTurnState.Create(FBench.World.Game, FState);
  FBench.World.Game.PushState(LNext);
  FBench.World.Wait(40);
  FBench.World.Click(320, 100);
  Assert.IsTrue(FState.Finished);
  Assert.AreEqual('Debriefing', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  FState := nil;
  FBench.World.Wait(40);
end;

procedure TTestXcomTurnScreens.IlCambioDiTurnoSenzaSoldatiViviDovrebbeFinireLaBattagliaAncheNellaMissioneFinale;
var
  LNext: TXcomState;
  LUnit: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  for LUnit in FBench.Session.Battle.Units do
    if LUnit.OriginalFaction = FACTION_PLAYER then
      LUnit.InstaKill;
  // the final mission: the aliens do not matter, the soldiers always do
  FBench.Session.Battle.ObjectiveType := XCOM_TILE_SPECIAL_MUST_DESTROY;
  LNext := TXcomNextTurnState.Create(FBench.World.Game, FState);
  FBench.World.Game.PushState(LNext);
  FBench.World.Wait(40);
  FBench.World.Click(320, 100);
  Assert.IsTrue(FState.Finished);
  Assert.AreEqual('Debriefing', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  FState := nil;
  FBench.World.Wait(40);
end;

procedure TTestXcomTurnScreens.NellaMissioneFinaleGliAlieniMortiNonFinisconoLaBattaglia;
var
  LNext: TXcomState;
  LUnit: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  for LUnit in FBench.Session.Battle.Units do
    if LUnit.OriginalFaction = FACTION_HOSTILE then
      LUnit.InstaKill;
  FBench.Session.Battle.ObjectiveType := XCOM_TILE_SPECIAL_MUST_DESTROY;
  LNext := TXcomNextTurnState.Create(FBench.World.Game, FState);
  FBench.World.Game.PushState(LNext);
  FBench.World.Wait(40);
  FBench.World.Click(320, 100);
  Assert.IsFalse(FState.Finished, 'the objective, not the aliens, ends the final mission');
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.IlMessaggioDovrebbeSparireDopoDueSecondi;
var
  LBox: TXcomState;
begin
  if not Ready then
    Exit;
  LBox := TXcomInfoboxState.Create(FBench.World.Game, @FState.Palette^[0], 'Someone has panicked');
  FBench.World.Game.PushState(LBox);
  FBench.World.Wait(1900);
  Assert.IsTrue(FBench.World.Game.IsState(LBox));
  FBench.World.Wait(200);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.IlMessaggioDovrebbeSparireConUnTasto;
var
  LBox: TXcomState;
begin
  if not Ready then
    Exit;
  LBox := TXcomInfoboxState.Create(FBench.World.Game, @FState.Palette^[0], 'x');
  FBench.World.Game.PushState(LBox);
  FBench.World.Wait(40);
  PressKey(XCOM_KEY_RETURN);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.IlMessaggioConOkDovrebbeAspettareIlPulsante;
var
  LBox: TXcomState;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Cursor.Visible := False;
  LBox := TXcomInfoboxOkState.Create(FBench.World.Game, @FState.Palette^[0], 'Someone has died');
  FBench.World.Game.PushState(LBox);
  Assert.IsTrue(FBench.World.Game.Cursor.Visible, 'the pointer is needed for OK');
  FBench.World.Wait(3000);
  Assert.IsTrue(FBench.World.Game.IsState(LBox));
  // the OK button: 120x18 at (100,112)
  FBench.World.Click(160 * 2, 121 * 2);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.IlBriefingDovrebbeMostrareLaMissioneEChiamareIlSeguitoConOk;
var
  LBriefing: TXcomBriefingState;
  LCalled: Boolean;
begin
  if not Ready then
    Exit;
  LCalled := False;
  LBriefing := TXcomBriefingState.Create(FBench.World.Game, FBench.Ruleset, 'STR_UFO_CRASH_RECOVERY', nil, nil,
    procedure
    begin
      LCalled := True;
    end);
  FBench.World.Game.PushState(LBriefing);
  FBench.World.Wait(400);
  Assert.AreEqual('STR_UFO_CRASH_RECOVERY', LBriefing.TitleText.GetText);
  Assert.AreEqual('', LBriefing.CraftText.GetText);
  FBench.World.Click((LBriefing.OkButton.X + 60) * 2, (LBriefing.OkButton.Y + 9) * 2);
  Assert.IsTrue(LCalled);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.GliAlieniMortiNelloSchiantoDovrebberoPortareAlSeguitoConOk;
var
  LCrash: TXcomState;
  LCalled: Boolean;
begin
  if not Ready then
    Exit;
  LCalled := False;
  LCrash := TXcomAliensCrashState.Create(FBench.World.Game, FBench.Session.Graphics,
    procedure
    begin
      LCalled := True;
    end);
  FBench.World.Game.PushState(LCrash);
  FBench.World.Wait(400);
  Assert.IsFalse(LCalled);
  PressKey(XCOM_KEY_RETURN);
  Assert.IsTrue(LCalled);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
end;

procedure TTestXcomTurnScreens.GliAlieniMortiNelloSchiantoDovrebberoTenereVivaLaGraficaFinoAllaChiusura;
var
  LGraphics: IXcomBattleGraphics;
  LCounted: TInterfacedObject;
  LBefore: Integer;
  LCrash: TXcomState;
begin
  if not Ready then
    Exit;
  // the launcher shows the message for a battle that does not start: nothing else holds its session, and the
  // window blits TAC00.SCR of the pictures of that session at every redraw (an access violation in the blit when
  // the pictures were freed with the briefing)
  LGraphics := FBench.Session.Graphics;
  LCounted := LGraphics as TInterfacedObject;
  LBefore := LCounted.RefCount;
  LCrash := TXcomAliensCrashState.Create(FBench.World.Game, LGraphics, nil);
  FBench.World.Game.PushState(LCrash);
  FBench.World.Wait(400);
  Assert.AreEqual(LBefore + 1, LCounted.RefCount, 'the message must hold the pictures it draws');
  PressKey(XCOM_KEY_RETURN);
  // a popped state is freed at the start of the next turn of the game
  FBench.World.Wait(40);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
  Assert.AreEqual(LBefore, LCounted.RefCount, 'the pictures are let go with the message');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomTurnScreens);

end.
