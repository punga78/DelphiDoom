{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the actions of the action menu that need a target  }
{  or a button of the battlescape: the guided missile (waypoints and launch),   }
{  the mind probe, the psi-amp (panic and mind control) and the melee hit, on   }
{  real battles through the battlescape state                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.SpecialActions;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattleStates.BattlescapeState,
  DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomSpecialActions = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    FOwnItem: TXcomBattleItem;
    function Open(const AScenario: string): Boolean;
    /// <summary>
    ///   The first item of a battle type of the battle, whoever has it (nil: none): in the scenarios the aliens
    ///   carry them, and an action only needs the item, not the inventory of its actor
    /// </summary>
    function HeldItem(ABattleType: Integer; AWithWaypoints: Boolean = False): TXcomBattleItem;
    function FirstAlien: TXcomBattleUnit;
    /// <summary>The action the action menu would leave: the actor selected, the weapon and the type, waiting for a target</summary>
    procedure Choose(AActor: TXcomBattleUnit; AWeapon: TXcomBattleItem; AType: Integer; ATargeting: Boolean);
    procedure Teleport(AUnit: TXcomBattleUnit; const APosition: TXcomPosition);
    /// <summary>Puts the unit on a free tile next to the actor that the actor can hit, and turns the actor to it</summary>
    function PutInFrontOf(AActor, AUnit: TXcomBattleUnit): Boolean;
    /// <summary>Puts the unit on a free tile two tiles from the actor, on screen</summary>
    function PutNear(AActor, AUnit: TXcomBattleUnit): Boolean;
    /// <summary>Clicks the tile at ADistance from the actor in the first direction where the map has it and it is on screen</summary>
    function ClickAway(AActor: TXcomBattleUnit; ADistance: Integer): Boolean;
    procedure Click(ASurface: TXcomInteractiveSurface);
    procedure RunUntilIdle;
    function Asked(const ACall: string): Integer;
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
    procedure IlMissileGuidatoDovrebbePrendereIWaypointEPartireColPulsante;
    [Test]
    procedure UnClicSulLOggettoAnnullaIWaypoint;
    [Test]
    procedure LaSondaMentaleDovrebbeMostrareLaSchedaDellAlieno;
    [Test]
    procedure LaSondaMentaleSenzaUnitaDiTempoDovrebbeAvvisare;
    [Test]
    procedure IlPanicoPsionicoDovrebbeSpendereLeUnitaDiTempo;
    [Test]
    procedure IlControlloMentaleDovrebbeSpendereLeUnitaDiTempoEFinire;
    [Test]
    procedure LAttaccoPsionicoSuUnAlienoNonVistoNonParte;
    [Test]
    procedure IlCorpoACorpoDovrebbeColpireChiStaDavanti;
  end;

implementation

const
  DIRECTION_X: array[0..7] of Integer = (0, 1, 1, 1, 0, -1, -1, -1);
  DIRECTION_Y: array[0..7] of Integer = (-1, -1, 0, 1, 1, 1, 0, -1);
  PSI_AMP = 'STR_MC_DISRUPTOR';

procedure TTestXcomSpecialActions.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomSpecialActions.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomSpecialActions.Setup;
begin
  FState := nil;
  FOwnItem := nil;
end;

procedure TTestXcomSpecialActions.TearDown;
begin
  FState := nil;
  FBench.Stop;
  FOwnItem.Free;
  FOwnItem := nil;
end;

function TTestXcomSpecialActions.Open(const AScenario: string): Boolean;
begin
  Result := FBench.Available;
  if not Result then
  begin
    TXcomTestSkip.Ignore('the data of TFTD are not here');
    Exit;
  end;
  FBench.Start(AScenario);
  FState := FBench.PushBattlescape;
  FBench.World.Wait(60);
end;

function TTestXcomSpecialActions.HeldItem(ABattleType: Integer; AWithWaypoints: Boolean): TXcomBattleItem;
var
  LItem: TXcomBattleItem;
  LWaypoints: Integer;
begin
  for LItem in FBench.Session.Battle.Items do
    if Assigned(LItem.Rules) and (LItem.Rules.BattleType = ABattleType) then
    begin
      if AWithWaypoints then
      begin
        LWaypoints := LItem.Rules.Waypoints;
        if (LWaypoints = 0) and Assigned(LItem.AmmoItem) then
          LWaypoints := LItem.AmmoItem.Rules.Waypoints;
        // a launcher with its missile loaded
        if (LWaypoints = 0) or (not Assigned(LItem.AmmoItem)) or (LItem.AmmoItem.AmmoQuantity <= 0) then
          Continue;
      end;
      Exit(LItem);
    end;
  Result := nil;
end;

function TTestXcomSpecialActions.FirstAlien: TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit.Faction = FACTION_HOSTILE) and (not LUnit.IsOut) and (LUnit.Armor.Size = 1) then
      Exit(LUnit);
  Result := nil;
end;

procedure TTestXcomSpecialActions.Choose(AActor: TXcomBattleUnit; AWeapon: TXcomBattleItem; AType: Integer;
  ATargeting: Boolean);
var
  LAction: TXcomBattleAction;
begin
  FBench.Session.Battle.SelectedUnit := AActor;
  FState.UpdateSoldierInfo;
  FState.Map.Camera.CenterOnPosition(AActor.Position);
  LAction := FState.Game.CurrentAction;
  LAction.Actor := AActor;
  LAction.Weapon := AWeapon;
  LAction.ActionType := AType;
  LAction.TimeUnits := AActor.GetActionTus(AType, AWeapon);
  LAction.Targeting := ATargeting;
  FState.Game.SetupCursor;
  FBench.World.Wait(40);
end;

procedure TTestXcomSpecialActions.Teleport(AUnit: TXcomBattleUnit; const APosition: TXcomPosition);
var
  LTile: TXcomTile;
begin
  if Assigned(AUnit.Tile) then
    AUnit.Tile.SetUnit(nil);
  AUnit.SetPosition(APosition);
  LTile := FBench.Session.Battle.TileAt(APosition);
  LTile.SetUnit(AUnit, FBench.Session.Battle.TileAt(TXcomPosition.Make(APosition.X, APosition.Y, APosition.Z - 1)));
end;

function TTestXcomSpecialActions.PutInFrontOf(AActor, AUnit: TXcomBattleUnit): Boolean;
var
  LDirection: Integer;
  LPosition: TXcomPosition;
  LTile: TXcomTile;
  LFound: TXcomPosition;
begin
  for LDirection := 0 to 7 do
  begin
    LPosition := TXcomPosition.Make(AActor.Position.X + DIRECTION_X[LDirection],
      AActor.Position.Y + DIRECTION_Y[LDirection], AActor.Position.Z);
    LTile := FBench.Session.Battle.TileAt(LPosition);
    if (not Assigned(LTile)) or Assigned(LTile.CurrentUnit) then
      Continue;
    Teleport(AUnit, LPosition);
    AActor.SetDirection(LDirection);
    if FBench.Session.TileEngine.ValidMeleeRange(AActor.Position, LDirection, AActor, AUnit, LFound) then
      Exit(True);
  end;
  Result := False;
end;

function TTestXcomSpecialActions.PutNear(AActor, AUnit: TXcomBattleUnit): Boolean;
var
  LDirection: Integer;
  LPosition: TXcomPosition;
  LTile: TXcomTile;
begin
  for LDirection := 0 to 7 do
  begin
    LPosition := TXcomPosition.Make(AActor.Position.X + 2 * DIRECTION_X[LDirection],
      AActor.Position.Y + 2 * DIRECTION_Y[LDirection], AActor.Position.Z);
    LTile := FBench.Session.Battle.TileAt(LPosition);
    if Assigned(LTile) and (not Assigned(LTile.CurrentUnit)) then
    begin
      Teleport(AUnit, LPosition);
      Exit(True);
    end;
  end;
  Result := False;
end;

function TTestXcomSpecialActions.ClickAway(AActor: TXcomBattleUnit; ADistance: Integer): Boolean;
var
  LDirection: Integer;
  LPosition: TXcomPosition;
begin
  for LDirection := 0 to 7 do
  begin
    LPosition := TXcomPosition.Make(AActor.Position.X + ADistance * DIRECTION_X[LDirection],
      AActor.Position.Y + ADistance * DIRECTION_Y[LDirection], AActor.Position.Z);
    if Assigned(FBench.Session.Battle.TileAt(LPosition)) and
      FBench.ClickTile(FState, LPosition.X, LPosition.Y) then
      Exit(True);
  end;
  Result := False;
end;

procedure TTestXcomSpecialActions.Click(ASurface: TXcomInteractiveSurface);
begin
  FBench.World.Click(Round((ASurface.X + ASurface.Width div 2) * FBench.World.Game.Screen.XScale),
    Round((ASurface.Y + ASurface.Height div 2) * FBench.World.Game.Screen.YScale));
end;

procedure TTestXcomSpecialActions.RunUntilIdle;
var
  LGuard: Integer;
begin
  LGuard := 0;
  FBench.World.Wait(60);
  while FState.Game.IsBusy and (not FState.Finished) and (LGuard < 1200) do
  begin
    FBench.World.Wait(50);
    Inc(LGuard);
  end;
  Assert.IsTrue(LGuard < 1200, 'the action never ended (' + FState.Game.FrontStateName + ')');
end;

function TTestXcomSpecialActions.Asked(const ACall: string): Integer;
var
  LCall: string;
begin
  Result := 0;
  for LCall in FBench.Screens.Calls do
    if LCall = ACall then
      Inc(Result);
end;

procedure TTestXcomSpecialActions.IlMissileGuidatoDovrebbePrendereIWaypointEPartireColPulsante;
var
  LWeapon: TXcomBattleItem;
  LAmmo: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LTimeUnits: Integer;
  LAmmoBefore: Integer;
  LAction: TXcomBattleAction;
begin
  if not Open('g03_2') then
    Exit;
  LWeapon := HeldItem(TXcomRuleItem.BT_FIREARM, True);
  Assert.IsNotNull(LWeapon, 'the scenario has no launcher');
  Assert.IsNotNull(LWeapon.AmmoItem, 'the launcher of the scenario is not loaded');
  LActor := FBench.Session.Battle.SelectedUnit;
  LAmmo := LWeapon.AmmoItem;
  LAmmoBefore := LAmmo.AmmoQuantity;
  Choose(LActor, LWeapon, BA_LAUNCH, True);
  LAction := FState.Game.CurrentAction;
  LTimeUnits := LActor.TimeUnits;
  Assert.IsFalse(FState.LaunchButton.Visible, 'no waypoint yet');
  Assert.IsTrue(ClickAway(LActor, 3), 'first waypoint on screen');
  Assert.AreEqual(1, LAction.Waypoints.Count);
  Assert.IsTrue(FState.LaunchButton.Visible, 'the launch button comes with the first waypoint');
  Assert.IsTrue(ClickAway(LActor, 4), 'second waypoint on screen');
  Assert.AreEqual(2, LAction.Waypoints.Count);
  Assert.AreEqual(LTimeUnits, LActor.TimeUnits, 'the waypoints cost nothing');
  Click(FState.LaunchButton);
  Assert.IsFalse(FState.LaunchButton.Visible, 'the button goes away at the launch');
  RunUntilIdle;
  Assert.IsTrue(LActor.IsOut or (LActor.TimeUnits < LTimeUnits), 'the launch costs time units');
  // the missile left the launcher: one round less (the item of an empty clip is removed)
  Assert.IsTrue((LWeapon.AmmoItem <> LAmmo) or (LAmmo.AmmoQuantity = LAmmoBefore - 1), 'one round less');
  Assert.AreEqual(0, FState.Game.CurrentAction.Waypoints.Count);
end;

procedure TTestXcomSpecialActions.UnClicSulLOggettoAnnullaIWaypoint;
var
  LWeapon: TXcomBattleItem;
  LActor: TXcomBattleUnit;
begin
  if not Open('g03_2') then
    Exit;
  LWeapon := HeldItem(TXcomRuleItem.BT_FIREARM, True);
  Assert.IsNotNull(LWeapon, 'the scenario has no launcher');
  Assert.IsNotNull(LWeapon.AmmoItem, 'the launcher of the scenario is not loaded');
  LActor := FBench.Session.Battle.SelectedUnit;
  Choose(LActor, LWeapon, BA_LAUNCH, True);
  Assert.IsTrue(ClickAway(LActor, 3));
  Assert.IsTrue(FState.LaunchButton.Visible);
  FState.Game.CancelCurrentAction;
  FBench.World.Wait(40);
  Assert.AreEqual(0, FState.Game.CurrentAction.Waypoints.Count);
  Assert.IsFalse(FState.LaunchButton.Visible);
end;

procedure TTestXcomSpecialActions.LaSondaMentaleDovrebbeMostrareLaSchedaDellAlieno;
var
  LProbe: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LTimeUnits: Integer;
  LCost: Integer;
begin
  if not Open('g36_3') then
    Exit;
  LProbe := HeldItem(TXcomRuleItem.BT_MINDPROBE);
  LAlien := FirstAlien;
  if (not Assigned(LProbe)) or (not Assigned(LAlien)) then
  begin
    Assert.Fail('the scenario has no mind probe');
    Exit;
  end;
  LActor := FBench.Session.Battle.SelectedUnit;
  Assert.IsTrue(PutNear(LActor, LAlien), 'a free tile near the soldier');
  LAlien.Visible := True;
  if LActor.VisibleUnits.IndexOf(LAlien) < 0 then
    LActor.VisibleUnits.Add(LAlien);
  Choose(LActor, LProbe, BA_USE, True);
  LTimeUnits := LActor.TimeUnits;
  LCost := FState.Game.CurrentAction.TimeUnits;
  Assert.IsTrue(LCost > 0);
  Assert.IsTrue(FBench.ClickTile(FState, LAlien.Position.X, LAlien.Position.Y));
  FBench.World.Wait(60);
  Assert.AreEqual(1, Asked('UnitInfo'), 'the screen of the alien');
  Assert.AreEqual(LTimeUnits - LCost, LActor.TimeUnits);
  Assert.IsFalse(FState.Game.CurrentAction.Targeting, 'the action is over');
end;

procedure TTestXcomSpecialActions.LaSondaMentaleSenzaUnitaDiTempoDovrebbeAvvisare;
var
  LProbe: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
begin
  if not Open('g36_3') then
    Exit;
  LProbe := HeldItem(TXcomRuleItem.BT_MINDPROBE);
  LAlien := FirstAlien;
  if (not Assigned(LProbe)) or (not Assigned(LAlien)) then
  begin
    Assert.Fail('the scenario has no mind probe');
    Exit;
  end;
  LActor := FBench.Session.Battle.SelectedUnit;
  Assert.IsTrue(PutNear(LActor, LAlien));
  LAlien.Visible := True;
  if LActor.VisibleUnits.IndexOf(LAlien) < 0 then
    LActor.VisibleUnits.Add(LAlien);
  Choose(LActor, LProbe, BA_USE, True);
  LActor.SetTimeUnits(0);
  Assert.IsTrue(FBench.ClickTile(FState, LAlien.Position.X, LAlien.Position.Y));
  FBench.World.Wait(60);
  Assert.AreEqual(0, Asked('UnitInfo'));
  Assert.IsTrue(FState.WarningMessage.Visible, 'not enough time units');
end;

procedure TTestXcomSpecialActions.IlPanicoPsionicoDovrebbeSpendereLeUnitaDiTempo;
var
  LActor: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LStats: TXcomUnitStats;
  LId: Integer;
  LTimeUnits: Integer;
  LCost: Integer;
begin
  if not Open('g01_2') then
    Exit;
  LActor := FBench.Session.Battle.SelectedUnit;
  LAlien := FirstAlien;
  Assert.IsNotNull(LAlien);
  LId := 9100;
  FOwnItem := TXcomBattleItem.Create(FBench.Ruleset.Items.Find(PSI_AMP), LId);
  LStats := LActor.Stats;
  LStats.PsiSkill := 90;
  LStats.PsiStrength := 90;
  LActor.Stats := LStats;
  Assert.IsTrue(PutNear(LActor, LAlien));
  LAlien.Visible := True;
  if LActor.VisibleUnits.IndexOf(LAlien) < 0 then
    LActor.VisibleUnits.Add(LAlien);
  Choose(LActor, FOwnItem, BA_PANIC, True);
  LTimeUnits := LActor.TimeUnits;
  LCost := LActor.GetActionTus(BA_PANIC, FOwnItem);
  Assert.IsTrue(LCost > 0);
  Assert.IsTrue(FBench.ClickTile(FState, LAlien.Position.X, LAlien.Position.Y));
  RunUntilIdle;
  Assert.AreEqual(LTimeUnits - LCost, LActor.TimeUnits);
  Assert.AreEqual(Integer(FACTION_HOSTILE), Integer(LAlien.Faction), 'a panic never changes the side');
end;

procedure TTestXcomSpecialActions.IlControlloMentaleDovrebbeSpendereLeUnitaDiTempoEFinire;
var
  LActor: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LStats: TXcomUnitStats;
  LId: Integer;
  LTimeUnits: Integer;
  LCost: Integer;
begin
  if not Open('g01_2') then
    Exit;
  LActor := FBench.Session.Battle.SelectedUnit;
  LAlien := FirstAlien;
  Assert.IsNotNull(LAlien);
  LId := 9100;
  FOwnItem := TXcomBattleItem.Create(FBench.Ruleset.Items.Find(PSI_AMP), LId);
  LStats := LActor.Stats;
  LStats.PsiSkill := 100;
  LStats.PsiStrength := 100;
  LActor.Stats := LStats;
  Assert.IsTrue(PutNear(LActor, LAlien));
  LAlien.Visible := True;
  if LActor.VisibleUnits.IndexOf(LAlien) < 0 then
    LActor.VisibleUnits.Add(LAlien);
  Choose(LActor, FOwnItem, BA_MINDCONTROL, True);
  LTimeUnits := LActor.TimeUnits;
  LCost := LActor.GetActionTus(BA_MINDCONTROL, FOwnItem);
  Assert.IsTrue(FBench.ClickTile(FState, LAlien.Position.X, LAlien.Position.Y));
  RunUntilIdle;
  Assert.AreEqual(LTimeUnits - LCost, LActor.TimeUnits);
  // the attack can fail: the alien is either still hostile or under control, never anything else
  Assert.IsTrue((LAlien.Faction = FACTION_HOSTILE) or (LAlien.Faction = FACTION_PLAYER));
  Assert.AreEqual(Integer(FACTION_HOSTILE), Integer(LAlien.OriginalFaction));
end;

procedure TTestXcomSpecialActions.LAttaccoPsionicoSuUnAlienoNonVistoNonParte;
var
  LActor: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LId: Integer;
  LTimeUnits: Integer;
begin
  if not Open('g01_2') then
    Exit;
  LActor := FBench.Session.Battle.SelectedUnit;
  LAlien := FirstAlien;
  LId := 9100;
  FOwnItem := TXcomBattleItem.Create(FBench.Ruleset.Items.Find(PSI_AMP), LId);
  Assert.IsTrue(PutNear(LActor, LAlien));
  // on the tile but not seen by anybody: the click does nothing
  LAlien.Visible := False;
  Choose(LActor, FOwnItem, BA_PANIC, True);
  LTimeUnits := LActor.TimeUnits;
  Assert.IsTrue(FBench.ClickTile(FState, LAlien.Position.X, LAlien.Position.Y));
  FBench.World.Wait(100);
  Assert.IsFalse(FState.Game.IsBusy);
  Assert.AreEqual(LTimeUnits, LActor.TimeUnits);
end;

procedure TTestXcomSpecialActions.IlCorpoACorpoDovrebbeColpireChiStaDavanti;
var
  LWeapon: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LTimeUnits: Integer;
  LCost: Integer;
  LTarget: TXcomPosition;
  LAction: TXcomBattleAction;
begin
  if not Open('g03_2') then
    Exit;
  LWeapon := HeldItem(TXcomRuleItem.BT_MELEE);
  LAlien := FirstAlien;
  if (not Assigned(LWeapon)) or (not Assigned(LAlien)) then
  begin
    Assert.Fail('the scenario has no melee weapon');
    Exit;
  end;
  LActor := FBench.Session.Battle.SelectedUnit;
  Assert.IsTrue(PutInFrontOf(LActor, LAlien), 'a tile the soldier can hit');
  LAlien.Visible := True;
  // what ActionMenuState does for BA_HIT: the cost and the tile of the target, then the menu closes
  Choose(LActor, LWeapon, BA_HIT, False);
  LAction := FState.Game.CurrentAction;
  LTimeUnits := LActor.TimeUnits;
  LCost := LAction.TimeUnits;
  Assert.IsTrue(LCost > 0);
  Assert.IsTrue(LCost <= LTimeUnits, 'the soldier of the scenario can afford the hit');
  Assert.IsTrue(FBench.Session.TileEngine.ValidMeleeRange(LActor.Position, LActor.Direction, LActor, nil, LTarget));
  LAction.Target := LTarget;
  Assert.IsTrue(LTarget = LAlien.Position);
  FState.Game.HandleNonTargetAction;
  RunUntilIdle;
  Assert.AreEqual(LTimeUnits - LCost, LActor.TimeUnits);
  Assert.AreEqual(Integer(BA_NONE), Integer(FState.Game.CurrentAction.ActionType), 'the action is over');
end;

end.
