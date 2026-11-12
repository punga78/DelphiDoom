{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the screen of the battle (BattlescapeState) on a real   }
{  battle of TFTD, with fake screens and sounds                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.BattlescapeState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattleStates.BattlescapeState,
  DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomBattlescapeState = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    function Ready: Boolean;
    procedure ClickPanel(AX, AY: Integer);
    procedure WaitIdle;
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
    procedure DovrebbeScegliereUnSoldatoEMostrareIlCursoreAllInizio;
    [Test]
    procedure DovrebbeFarCamminareIlSoldatoColClicSullaMappa;
    [Test]
    procedure DovrebbeMostrareLAnteprimaAlPrimoClicECamminareAlSecondo;
    [Test]
    procedure DovrebbeInginocchiareIlSoldatoColPulsante;
    [Test]
    procedure DovrebbeRiservareITuColPulsanteDelColpoRapido;
    [Test]
    procedure DovrebbeAzzerareITuColTastoDestro;
    [Test]
    procedure DovrebbePassareAlSoldatoSuccessivo;
    [Test]
    procedure DovrebbeChiedereIlMenuDelleAzioniPerLaManoDestra;
    [Test]
    procedure DovrebbeChiedereMinimappaInventarioStatisticheEAbbandono;
    [Test]
    procedure DovrebbeFinireIlTurnoEFarGiocareGliAlieni;
    [Test]
    procedure DovrebbeMostrareUnAvviso;
    [Test]
    procedure DovrebbeSuonareConLAngoloDellaPosizione;
    [Test]
    procedure DovrebbeAprireUnPopupAlPensieroSuccessivo;
    [Test]
    procedure DovrebbeChiudersiEChiedereIlResocontoAllaFineDellaBattaglia;
    [Test]
    procedure DovrebbeCambiareLivelloDellaVista;
    [Test]
    procedure DovrebbeMostrareIlMessaggioDiUnUnita;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types;

procedure TTestXcomBattlescapeState.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomBattlescapeState.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomBattlescapeState.Setup;
begin
  FState := nil;
  if FBench.Available then
  begin
    FBench.Start;
    FState := FBench.PushBattlescape;
  end;
end;

procedure TTestXcomBattlescapeState.TearDown;
begin
  FState := nil;
  FBench.Stop;
end;

function TTestXcomBattlescapeState.Ready: Boolean;
begin
  Result := Assigned(FState);
  if not Result then
    TTestSkip.Ignore('the data of TFTD are not here');
end;

procedure TTestXcomBattlescapeState.ClickPanel(AX, AY: Integer);
begin
  // the panel is the bottom 56 rows of the 320x200 screen, shown doubled
  FBench.World.Click(AX * 2, (144 + AY) * 2);
end;

procedure TTestXcomBattlescapeState.WaitIdle;
var
  LGuard: Integer;
begin
  LGuard := 0;
  FBench.World.Wait(50);
  while FState.Game.IsBusy and (LGuard < 400) do
  begin
    FBench.World.Wait(50);
    Inc(LGuard);
  end;
end;

procedure TTestXcomBattlescapeState.DovrebbeScegliereUnSoldatoEMostrareIlCursoreAllInizio;
begin
  if not Ready then
    Exit;
  Assert.IsNotNull(FBench.Session.Battle.SelectedUnit);
  Assert.AreEqual(FACTION_PLAYER, FBench.Session.Battle.SelectedUnit.Faction);
  Assert.AreEqual(CT_NORMAL, FState.Map.Map.CursorType);
  Assert.IsTrue(FState.PlayableUnitSelected);
  Assert.IsTrue(FState.AllowButtons);
end;

procedure TTestXcomBattlescapeState.DovrebbeFarCamminareIlSoldatoColClicSullaMappa;
var
  LUnit: TXcomBattleUnit;
  LStart: TXcomPosition;
  LTimeUnits: Integer;
  LStep: Integer;
  LMoved: Boolean;
begin
  if not Ready then
    Exit;
  LUnit := FBench.Session.Battle.SelectedUnit;
  LStart := LUnit.Position;
  LTimeUnits := LUnit.TimeUnits;
  LMoved := False;
  // a free tile next to the soldier: the first of the four that the path reaches
  for LStep := 0 to 3 do
  begin
    case LStep of
      0: FBench.ClickTile(FState, LStart.X + 1, LStart.Y);
      1: FBench.ClickTile(FState, LStart.X, LStart.Y + 1);
      2: FBench.ClickTile(FState, LStart.X - 1, LStart.Y);
      3: FBench.ClickTile(FState, LStart.X, LStart.Y - 1);
    end;
    WaitIdle;
    if (FBench.Session.Battle.SelectedUnit = LUnit) and (LUnit.Position <> LStart) then
    begin
      LMoved := True;
      Break;
    end;
    // the click may have selected the soldier that stands there: back to ours
    FBench.Session.Battle.SelectedUnit := LUnit;
  end;
  Assert.IsTrue(LMoved, 'the soldier did not walk');
  Assert.IsTrue(LUnit.TimeUnits < LTimeUnits);
  Assert.IsTrue(FBench.Audio.Calls.Count > 0, 'no footstep was played');
end;

procedure TTestXcomBattlescapeState.DovrebbeMostrareLAnteprimaAlPrimoClicECamminareAlSecondo;
var
  LUnit: TXcomBattleUnit;
  LStart: TXcomPosition;
  LTarget: TXcomPosition;
  LStep: Integer;
  LFound: Boolean;
begin
  if not Ready then
    Exit;
  // the option is read when the game of the battle is made: a new battle and a new state with the preview on
  FState := nil;
  FBench.Start;
  FBench.World.Game.Options.SetValue('battleNewPreviewPath', 3);
  FState := FBench.PushBattlescape;
  LUnit := FBench.Session.Battle.SelectedUnit;
  LStart := LUnit.Position;
  LFound := False;
  for LStep := 0 to 3 do
  begin
    LTarget := LStart;
    case LStep of
      0: Inc(LTarget.X);
      1: Inc(LTarget.Y);
      2: Dec(LTarget.X);
      3: Dec(LTarget.Y);
    end;
    FBench.ClickTile(FState, LTarget.X, LTarget.Y);
    WaitIdle;
    FBench.Session.Battle.SelectedUnit := LUnit;
    if FBench.Session.Pathfinding.PathPreviewed then
    begin
      LFound := True;
      Break;
    end;
  end;
  Assert.IsTrue(LFound, 'no path was previewed');
  // the first click only marks the tile: the soldier stays, the tile has the arrow of the arrival and the time units
  Assert.IsTrue(LUnit.Position = LStart);
  Assert.AreEqual(10, FBench.Session.Battle.TileAt(LTarget).Preview);
  Assert.IsTrue(FBench.Session.Battle.TileAt(LTarget).TuMarker >= 0);
  // the second click on the same tile walks and removes the marks
  FBench.ClickTile(FState, LTarget.X, LTarget.Y);
  WaitIdle;
  Assert.IsTrue(LUnit.Position = LTarget);
  Assert.IsFalse(FBench.Session.Pathfinding.PathPreviewed);
  Assert.AreEqual(-1, FBench.Session.Battle.TileAt(LTarget).Preview);
end;

procedure TTestXcomBattlescapeState.DovrebbeInginocchiareIlSoldatoColPulsante;
var
  LUnit: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  LUnit := FBench.Session.Battle.SelectedUnit;
  Assert.IsFalse(LUnit.IsKneeled);
  ClickPanel(112 + 16, 16 + 8);
  Assert.IsTrue(LUnit.IsKneeled);
  ClickPanel(112 + 16, 16 + 8);
  Assert.IsFalse(LUnit.IsKneeled);
end;

procedure TTestXcomBattlescapeState.DovrebbeRiservareITuColPulsanteDelColpoRapido;
begin
  if not Ready then
    Exit;
  ClickPanel(78 + 8, 33 + 5);
  Assert.AreEqual(BA_SNAPSHOT, FBench.Session.Battle.TuReserved);
  ClickPanel(60 + 8, 33 + 5);
  Assert.AreEqual(BA_NONE, FBench.Session.Battle.TuReserved);
end;

procedure TTestXcomBattlescapeState.DovrebbeAzzerareITuColTastoDestro;
var
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
begin
  if not Ready then
    Exit;
  Assert.IsTrue(FBench.Session.Battle.SelectedUnit.TimeUnits > 0);
  LX := (49 + 5) * 2;
  LY := (144 + 33 + 11) * 2;
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := LX;
  LEvent.Y := LY;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := LX;
  LEvent.Y := LY;
  LEvent.Button := XCOM_BUTTON_RIGHT;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent.Kind := ekMouseUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  Assert.AreEqual(0, FBench.Session.Battle.SelectedUnit.TimeUnits);
end;

procedure TTestXcomBattlescapeState.DovrebbePassareAlSoldatoSuccessivo;
var
  LFirst: TXcomBattleUnit;
begin
  if not Ready then
    Exit;
  LFirst := FBench.Session.Battle.SelectedUnit;
  ClickPanel(176 + 16, 8);
  Assert.AreNotSame(LFirst, FBench.Session.Battle.SelectedUnit);
  Assert.AreSame(FBench.Session.Battle.SelectedUnit, FState.Game.CurrentAction.Actor);
end;

procedure TTestXcomBattlescapeState.DovrebbeChiedereIlMenuDelleAzioniPerLaManoDestra;
begin
  if not Ready then
    Exit;
  if not Assigned(FState.RightHandItem(FBench.Session.Battle.SelectedUnit)) then
    TTestSkip.Ignore('the selected soldier has an empty right hand');
  ClickPanel(280 + 16, 4 + 24);
  FBench.World.Wait(40);
  Assert.AreEqual('ActionMenu:0,160', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  Assert.AreSame(FState.RightHandItem(FBench.Session.Battle.SelectedUnit), FState.Game.CurrentAction.Weapon);
end;

procedure TTestXcomBattlescapeState.DovrebbeChiedereMinimappaInventarioStatisticheEAbbandono;
begin
  if not Ready then
    Exit;
  ClickPanel(112 + 16, 8);
  Assert.AreEqual('MiniMap', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  ClickPanel(144 + 16, 8);
  Assert.AreEqual('Inventory', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  ClickPanel(240 + 16, 16 + 8);
  Assert.AreEqual('AbortMission', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  ClickPanel(208 + 16, 16 + 8);
  Assert.AreEqual('Options', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  ClickPanel(200, 44);
  Assert.AreEqual('UnitInfo', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
end;

procedure TTestXcomBattlescapeState.DovrebbeFinireIlTurnoEFarGiocareGliAlieni;
var
  LGuard: Integer;
begin
  if not Ready then
    Exit;
  Assert.AreEqual(1, FBench.Session.Battle.Turn);
  ClickPanel(240 + 16, 8);
  FBench.World.Wait(100);
  Assert.AreEqual('NextTurn', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  // the other sides play by themselves until the turn is the player's again
  LGuard := 0;
  while ((FBench.Session.Battle.Side <> FACTION_PLAYER) or (FBench.Session.Battle.Turn < 2)) and (LGuard < 3000) do
  begin
    FBench.World.Wait(100);
    Inc(LGuard);
  end;
  Assert.AreEqual(FACTION_PLAYER, FBench.Session.Battle.Side);
  Assert.AreEqual(2, FBench.Session.Battle.Turn);
end;

procedure TTestXcomBattlescapeState.DovrebbeMostrareUnAvviso;
begin
  if not Ready then
    Exit;
  Assert.IsFalse(FState.WarningMessage.Visible);
  FState.Warning('STR_NOT_ENOUGH_TIME_UNITS');
  Assert.IsTrue(FState.WarningMessage.Visible);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FState.WarningMessage.Text);
  FBench.World.Wait(1500);
  Assert.IsFalse(FState.WarningMessage.Visible);
end;

procedure TTestXcomBattlescapeState.DovrebbeSuonareConLAngoloDellaPosizione;
var
  LParts: TArray<string>;
  LAngle: Integer;
begin
  if not Ready then
    Exit;
  FBench.Audio.Calls.Clear;
  FState.PlaySound(7, FBench.Session.Battle.SelectedUnit.Position);
  FState.PlaySound(9, TXcomPosition.Make(-1, -1, -1));
  FState.PlaySound(-1, FBench.Session.Battle.SelectedUnit.Position);
  Assert.AreEqual(2, FBench.Audio.Calls.Count);
  LParts := FBench.Audio.Calls[0].Split([' ']);
  Assert.AreEqual('7', LParts[2]);
  LAngle := StrToInt(LParts[3]);
  Assert.IsTrue((LAngle >= 280) and (LAngle <= 440), 'angle ' + LParts[3]);
  Assert.IsTrue(FBench.Audio.Calls[1].EndsWith(' 9 0'));
end;

procedure TTestXcomBattlescapeState.DovrebbeAprireUnPopupAlPensieroSuccessivo;
var
  LPopup: TXcomState;
begin
  if not Ready then
    Exit;
  LPopup := TXcomState.Create(FBench.World.Game);
  FState.Popup(LPopup);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
  FBench.World.Wait(40);
  Assert.IsTrue(FBench.World.Game.IsState(LPopup));
end;

procedure TTestXcomBattlescapeState.DovrebbeChiudersiEChiedereIlResocontoAllaFineDellaBattaglia;
var
  LDebriefing: TXcomState;
begin
  if not Ready then
    Exit;
  LDebriefing := TXcomState.Create(FBench.World.Game);
  FBench.Screens.Next := LDebriefing;
  FState.FinishBattle(True, 0);
  Assert.AreEqual('Debriefing', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
  Assert.IsTrue(FBench.World.Game.IsState(LDebriefing));
  Assert.IsTrue(FBench.Audio.Calls.IndexOf('stop') >= 0);
  // the state was popped: the game frees it
  FState := nil;
  FBench.World.Wait(40);
end;

procedure TTestXcomBattlescapeState.DovrebbeCambiareLivelloDellaVista;
var
  LLevel: Integer;
begin
  if not Ready then
    Exit;
  LLevel := FState.Map.Camera.ViewLevel;
  ClickPanel(80 + 16, 8);
  if FBench.Session.Battle.MapSizeZ > LLevel + 1 then
    Assert.AreEqual(LLevel + 1, FState.Map.Camera.ViewLevel)
  else
    Assert.AreEqual(LLevel, FState.Map.Camera.ViewLevel);
  ClickPanel(80 + 16, 16 + 8);
  Assert.AreEqual(LLevel, FState.Map.Camera.ViewLevel);
end;

procedure TTestXcomBattlescapeState.DovrebbeMostrareIlMessaggioDiUnUnita;
begin
  if not Ready then
    Exit;
  FState.ShowUnitMessage(FBench.Session.Battle.SelectedUnit, 'STR_HAS_PANICKED', False);
  Assert.IsTrue(FBench.Screens.Calls[FBench.Screens.Calls.Count - 1].StartsWith('Infobox:'));
  FState.ShowUnitMessage(nil, 'STR_MIND_CONTROL_SUCCESSFUL', True);
  Assert.AreEqual('InfoboxOk:STR_MIND_CONTROL_SUCCESSFUL', FBench.Screens.Calls[FBench.Screens.Calls.Count - 1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBattlescapeState);

end.
