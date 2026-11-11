{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape states library - the window   }
{  that asks to abort the mission (TXcomAbortMissionState) over a real saved    }
{  battle                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.AbortMissionState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattleStates.AbortMissionState,
  DelphiDoom.Tests.XcomBattleStates.BattleWorld;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomAbortMissionState = class
  strict private
    FWorld: TBattleTestWorld;
    function Open: TXcomAbortMissionState;
    function Available: Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeContareTuttiISoldatiVivi;
    [Test]
    procedure DovrebbeLasciareVisibileLaBattaglia;
    [Test]
    procedure DovrebbeTornareAllaBattagliaConAnnulla;
    [Test]
    procedure DovrebbeTornareAllaBattagliaColTastoAnnulla;
    [Test]
    procedure DovrebbeFinireLaBattagliaComeAbbandonataConOk;
  end;

implementation

procedure TTestXcomAbortMissionState.Setup;
begin
  FWorld := TBattleTestWorld.TryCreate;
end;

procedure TTestXcomAbortMissionState.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomAbortMissionState.Available: Boolean;
begin
  Result := Assigned(FWorld);
  if not Result then
    Assert.Pass('The data of the real game are not on this machine');
end;

function TTestXcomAbortMissionState.Open: TXcomAbortMissionState;
begin
  Result := FWorld.Parent.Screens.AbortMission(FWorld.Parent) as TXcomAbortMissionState;
  FWorld.World.Game.PushState(Result);
  FWorld.World.Wait(40);
end;

procedure TTestXcomAbortMissionState.DovrebbeContareTuttiISoldatiVivi;
var
  LState: TXcomAbortMissionState;
  LUnit: TXcomBattleUnit;
  LAlive: Integer;
begin
  if not Available then
    Exit;
  LState := Open;
  LAlive := 0;
  for LUnit in FWorld.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_PLAYER) and (LUnit.Status <> STATUS_DEAD) and
      (LUnit.Status <> STATUS_IGNORE_ME) then
      Inc(LAlive);
  Assert.IsTrue(LAlive > 0, 'the battle has soldiers');
  Assert.AreEqual(LAlive, LState.InEntrance + LState.InExit + LState.Outside);
end;

procedure TTestXcomAbortMissionState.DovrebbeLasciareVisibileLaBattaglia;
var
  LState: TXcomAbortMissionState;
begin
  if not Available then
    Exit;
  LState := Open;
  Assert.IsFalse(LState.IsScreen, 'a window over the battlescape');
end;

procedure TTestXcomAbortMissionState.DovrebbeTornareAllaBattagliaConAnnulla;
begin
  if not Available then
    Exit;
  Open;
  FWorld.ClickButton(244, 118, XCOM_BUTTON_LEFT);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
  Assert.IsFalse(FWorld.Battle.Aborted);
  Assert.IsFalse(FWorld.Parent.Finished);
end;

procedure TTestXcomAbortMissionState.DovrebbeTornareAllaBattagliaColTastoAnnulla;
begin
  if not Available then
    Exit;
  Open;
  FWorld.PressKey(FWorld.World.Game.Options.KeyCancel);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
  Assert.IsFalse(FWorld.Battle.Aborted);
end;

procedure TTestXcomAbortMissionState.DovrebbeFinireLaBattagliaComeAbbandonataConOk;
begin
  if not Available then
    Exit;
  Open;
  FWorld.ClickButton(76, 118, XCOM_BUTTON_LEFT);
  Assert.IsTrue(FWorld.Battle.Aborted, 'the battle is aborted');
  Assert.AreEqual(1, FWorld.Debriefings, 'finishBattle asks for the debriefing');
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Debriefing),
    'the debriefing takes the place of the battle');
end;

end.
