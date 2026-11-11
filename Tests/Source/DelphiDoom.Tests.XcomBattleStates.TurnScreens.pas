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
    procedure IlMessaggioDovrebbeSparireDopoDueSecondi;
    [Test]
    procedure IlMessaggioDovrebbeSparireConUnTasto;
    [Test]
    procedure IlMessaggioConOkDovrebbeAspettareIlPulsante;
    [Test]
    procedure IlBriefingDovrebbeMostrareLaMissioneEChiamareIlSeguitoConOk;
    [Test]
    procedure GliAlieniMortiNelloSchiantoDovrebberoPortareAlSeguitoConOk;
  end;

implementation

uses
  DelphiDoom.XcomBattleStates.NextTurnState, DelphiDoom.XcomBattleStates.InfoboxState,
  DelphiDoom.XcomBattleStates.InfoboxOkState, DelphiDoom.XcomBattleStates.BriefingState,
  DelphiDoom.XcomBattleStates.AliensCrashState;

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
  LCrash := TXcomAliensCrashState.Create(FBench.World.Game, FBench.Session.Graphics.Surface('TAC00.SCR'),
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

initialization
  TDUnitX.RegisterTestFixture(TTestXcomTurnScreens);

end.
