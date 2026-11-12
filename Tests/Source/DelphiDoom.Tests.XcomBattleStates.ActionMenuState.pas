{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the menu of the actions of an item (ActionMenuState)    }
{  on a real battle of TFTD; the time units of the lines are the ones the      }
{  real OpenXcom shows for the same saved game                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.ActionMenuState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomBattleStates.ActionMenuState, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomBattleStates.Battle;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomActionMenuState = class
  strict private
    FBattle: TTestBattle;
    FWorld: TTestWorld;
    FScreens: TTestBattleScreens;
    FScreensRef: IXcomBattleScreens;
    FAction: TXcomBattleAction;
    FBase: TXcomState;
    FMenu: TXcomActionMenuState;
    FOwnItem: TXcomBattleItem;
    function Skip: Boolean;
    procedure OpenMenu(AActor: TXcomBattleUnit; AWeapon: TXcomBattleItem);
    procedure OpenSoldierMenu(AWeaponId: Integer);
    procedure ClickItem(AIndex: Integer);
    procedure Press(AKind: TXcomEventKind; AButton, AKey: Integer);
    function NewItem(const AType: string): TXcomBattleItem;
    function MayUse(AUnit: TXcomBattleUnit; AItem: TXcomBattleItem): Boolean;
    function FindActor(AItem: TXcomBattleItem; AWithSomeoneInFront: Boolean): TXcomBattleUnit;
    function AnAlien: TXcomBattleUnit;
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
    procedure DovrebbeElencareLancioEColpiDelCannoneAGasComeIlVeroOpenXcom;
    [Test]
    procedure DovrebbeElencareLancioEInnescoPerLaGranataComeIlVeroOpenXcom;
    [Test]
    procedure DovrebbeNonOffrireLInnescoPerLaGranataGiaInnescata;
    [Test]
    procedure DovrebbeMettereInMiraIlColpoScelto;
    [Test]
    procedure DovrebbeMettereInMiraIlLancio;
    [Test]
    procedure DovrebbeChiudersiColTastoDestroSenzaScegliere;
    [Test]
    procedure DovrebbeChiudersiColTastoDiAnnulla;
    [Test]
    procedure DovrebbeRifiutareLArmaAlienaNonStudiata;
    [Test]
    procedure DovrebbeAprireLaSceltaDelTimerSopraIlMenu;
    [Test]
    procedure DovrebbeNonFareNullaSenzaLoSchermoDelTimer;
    [Test]
    procedure DovrebbeDireCheNonCeNessunoDaCurare;
    [Test]
    procedure DovrebbeAprireIlMedikitSuChiStaDavanti;
    [Test]
    procedure DovrebbeSpendereITuEAprireLoScanner;
    [Test]
    procedure DovrebbeNonSpendereTuSenzaLoSchermoDelloScanner;
    [Test]
    procedure DovrebbeDireCheMancanoITuPerLoScanner;
    [Test]
    procedure IlLanciamissiliScaricoDovrebbeDireCheNonHaMunizioni;
    [Test]
    procedure IlLanciamissiliSenzaTuDovrebbeDireCheMancano;
    [Test]
    procedure IlColpoCorpoACorpoSenzaNessunoDavantiDovrebbeDirlo;
    [Test]
    procedure IlColpoCorpoACorpoSenzaTuDovrebbeDireCheMancano;
    [Test]
    procedure IlBastoneStordenteDovrebbeOffrireLoStordimento;
    [Test]
    procedure LoPsiAmpDovrebbeOffrireControlloEPanicoAChiHaLAbilita;
    [Test]
    procedure LoPsiAmpSenzaAbilitaPsionicaOffreSoloIlLancio;
    [Test]
    procedure LaSondaMentaleDovrebbeAspettareIlBersaglio;
  end;

implementation

const
  MENU_X = 0;
  MENU_Y = 160;

procedure TTestXcomActionMenuState.SetupFixture;
begin
  FBattle := TTestBattle.Create;
end;

procedure TTestXcomActionMenuState.TearDownFixture;
begin
  FBattle.Free;
end;

procedure TTestXcomActionMenuState.Setup;
begin
  FOwnItem := nil;
  FMenu := nil;
  if not FBattle.Available then
    Exit;
  FWorld := TTestWorld.Create;
  FWorld.Game.AdoptData(TTestBattleResources.Create(FWorld.Game.Resources), nil);
  FBattle.Open;
  FScreens := TTestBattleScreens.Create;
  FScreensRef := FScreens;
  FAction := TXcomBattleAction.Create;
  FBase := TXcomState.Create(FWorld.Game);
  FWorld.Game.PushState(FBase);
end;

procedure TTestXcomActionMenuState.TearDown;
begin
  if not FBattle.Available then
    Exit;
  // a screen that nobody asked for is still ours
  FScreens.Next.Free;
  // the states hold the session: they go first
  FreeAndNil(FWorld);
  FScreensRef := nil;
  FreeAndNil(FAction);
  FreeAndNil(FOwnItem);
  FBattle.Close;
end;

function TTestXcomActionMenuState.Skip: Boolean;
begin
  Result := not FBattle.Available;
  if Result then
    TTestSkip.Ignore('the data of TFTD is not on this machine');
end;

procedure TTestXcomActionMenuState.OpenMenu(AActor: TXcomBattleUnit; AWeapon: TXcomBattleItem);
begin
  FAction.Actor := AActor;
  FAction.Weapon := AWeapon;
  FMenu := TXcomActionMenuState.Create(FWorld.Game, FBase, FBattle.Session, FScreensRef, FAction, MENU_X, MENU_Y);
  FWorld.Game.PushState(FMenu);
  FWorld.Wait(20);
end;

procedure TTestXcomActionMenuState.OpenSoldierMenu(AWeaponId: Integer);
begin
  OpenMenu(FBattle.FindUnit(TEST_BATTLE_SOLDIER), FBattle.FindItem(AWeaponId));
end;

procedure TTestXcomActionMenuState.ClickItem(AIndex: Integer);
begin
  // the window is twice the screen of the game
  FWorld.Click((MENU_X + 24 + 100) * 2, (MENU_Y - AIndex * 40 + 20) * 2);
end;

procedure TTestXcomActionMenuState.Press(AKind: TXcomEventKind; AButton, AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  LEvent.X := 5;
  LEvent.Y := 5;
  LEvent.Button := AButton;
  LEvent.Key := AKey;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

function TTestXcomActionMenuState.NewItem(const AType: string): TXcomBattleItem;
var
  LId: Integer;
begin
  LId := 90000;
  FOwnItem := TXcomBattleItem.Create(FBattle.Ruleset.Items.Find(AType), LId);
  Result := FOwnItem;
end;

function TTestXcomActionMenuState.MayUse(AUnit: TXcomBattleUnit; AItem: TXcomBattleItem): Boolean;
begin
  Result := Assigned(AUnit.Tile) and ((AUnit.OriginalFaction <> FACTION_PLAYER) or
    FBattle.Session.SavedGame.IsResearched(AItem.Rules.Requirements));
end;

function TTestXcomActionMenuState.FindActor(AItem: TXcomBattleItem; AWithSomeoneInFront: Boolean): TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
  LTarget: TXcomPosition;
  LTile: TXcomTile;
  LFound: Boolean;
begin
  Result := nil;
  for LUnit in FBattle.Session.Battle.Units do
  begin
    if not MayUse(LUnit, AItem) then
      Continue;
    LFound := FBattle.Session.TileEngine.ValidMeleeRange(LUnit.Position, LUnit.Direction, LUnit, nil, LTarget, False);
    if LFound then
    begin
      LTile := FBattle.Session.Battle.TileAt(LTarget);
      LFound := Assigned(LTile) and Assigned(LTile.CurrentUnit) and LTile.CurrentUnit.IsWoundable;
    end;
    if LFound = AWithSomeoneInFront then
      Exit(LUnit);
  end;
end;

procedure TTestXcomActionMenuState.DovrebbeElencareLancioEColpiDelCannoneAGasComeIlVeroOpenXcom;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_GAS_CANNON);
  // the real menu: Throw TU>12, Snap Shot TU>20, Aimed Shot TU>38 (from the bottom)
  Assert.AreEqual(3, FMenu.ItemCount);
  Assert.AreEqual(BA_THROW, FMenu.Item(0).ActionType);
  Assert.AreEqual(12, FMenu.Item(0).TimeUnits);
  Assert.AreEqual(BA_SNAPSHOT, FMenu.Item(1).ActionType);
  Assert.AreEqual(20, FMenu.Item(1).TimeUnits);
  Assert.AreEqual(BA_AIMEDSHOT, FMenu.Item(2).ActionType);
  Assert.AreEqual(38, FMenu.Item(2).TimeUnits);
  Assert.IsFalse(FMenu.Item(3).Visible);
  Assert.IsFalse(FMenu.IsScreen, 'the battle stays visible under the menu');
end;

procedure TTestXcomActionMenuState.DovrebbeElencareLancioEInnescoPerLaGranataComeIlVeroOpenXcom;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_GRENADE);
  // the real menu: Throw TU>12, Prime Grenade TU>25
  Assert.AreEqual(2, FMenu.ItemCount);
  Assert.AreEqual(BA_THROW, FMenu.Item(0).ActionType);
  Assert.AreEqual(12, FMenu.Item(0).TimeUnits);
  Assert.AreEqual(BA_PRIME, FMenu.Item(1).ActionType);
  Assert.AreEqual(25, FMenu.Item(1).TimeUnits);
end;

procedure TTestXcomActionMenuState.DovrebbeNonOffrireLInnescoPerLaGranataGiaInnescata;
begin
  if Skip then
    Exit;
  FBattle.FindItem(TEST_BATTLE_GRENADE).FuseTimer := 3;
  OpenSoldierMenu(TEST_BATTLE_GRENADE);
  Assert.AreEqual(1, FMenu.ItemCount);
  Assert.AreEqual(BA_THROW, FMenu.Item(0).ActionType);
end;

procedure TTestXcomActionMenuState.DovrebbeMettereInMiraIlColpoScelto;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_GAS_CANNON);
  ClickItem(1);
  Assert.AreEqual(BA_SNAPSHOT, FAction.ActionType);
  Assert.AreEqual(20, FAction.TimeUnits);
  Assert.IsTrue(FAction.Targeting);
  Assert.AreEqual('', FAction.ResultText);
  Assert.AreSame(FBase, FWorld.Game.TopState, 'the menu is closed');
end;

procedure TTestXcomActionMenuState.DovrebbeMettereInMiraIlLancio;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_SONIC_CANNON);
  ClickItem(0);
  // throwing needs no research
  Assert.AreEqual(BA_THROW, FAction.ActionType);
  Assert.IsTrue(FAction.Targeting);
  Assert.AreEqual('', FAction.ResultText);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.DovrebbeChiudersiColTastoDestroSenzaScegliere;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_GAS_CANNON);
  Press(ekMouseDown, XCOM_BUTTON_RIGHT, 0);
  Assert.AreSame(FBase, FWorld.Game.TopState);
  Assert.AreEqual(BA_NONE, FAction.ActionType);
  Assert.IsFalse(FAction.Targeting);
end;

procedure TTestXcomActionMenuState.DovrebbeChiudersiColTastoDiAnnulla;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_GAS_CANNON);
  Press(ekKeyDown, 0, FWorld.Game.Options.GetValue('keyCancel'));
  Assert.AreSame(FBase, FWorld.Game.TopState);
  Assert.AreEqual(BA_NONE, FAction.ActionType);
end;

procedure TTestXcomActionMenuState.DovrebbeRifiutareLArmaAlienaNonStudiata;
var
  LWeapon: TXcomBattleItem;
begin
  if Skip then
    Exit;
  LWeapon := FBattle.FindItem(TEST_BATTLE_SONIC_CANNON);
  if FBattle.Session.SavedGame.IsResearched(LWeapon.Rules.Requirements) then
  begin
    TTestSkip.Ignore('the sonic cannon is researched in this saved game');
    Exit;
  end;
  OpenSoldierMenu(TEST_BATTLE_SONIC_CANNON);
  ClickItem(1);
  Assert.AreEqual('STR_UNABLE_TO_USE_ALIEN_ARTIFACT_UNTIL_RESEARCHED', FAction.ResultText);
  Assert.IsFalse(FAction.Targeting);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.DovrebbeAprireLaSceltaDelTimerSopraIlMenu;
var
  LTimer: TXcomState;
begin
  if Skip then
    Exit;
  LTimer := TXcomState.Create(FWorld.Game);
  FScreens.Next := LTimer;
  OpenSoldierMenu(TEST_BATTLE_GRENADE);
  ClickItem(1);
  Assert.AreEqual('PrimeGrenade;', FScreens.Calls);
  Assert.AreSame(FBase, FScreens.LastParent);
  Assert.AreSame(FAction, FScreens.LastAction);
  Assert.AreEqual(BA_PRIME, FAction.ActionType);
  Assert.AreEqual(25, FAction.TimeUnits);
  Assert.AreSame(LTimer, FWorld.Game.TopState, 'the timer is over the menu, which stays open');
end;

procedure TTestXcomActionMenuState.DovrebbeNonFareNullaSenzaLoSchermoDelTimer;
begin
  if Skip then
    Exit;
  OpenSoldierMenu(TEST_BATTLE_GRENADE);
  ClickItem(1);
  Assert.AreEqual('PrimeGrenade;', FScreens.Calls);
  Assert.AreEqual(BA_NONE, FAction.ActionType);
  Assert.AreSame(FMenu, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.DovrebbeDireCheNonCeNessunoDaCurare;
var
  LKit: TXcomBattleItem;
  LActor: TXcomBattleUnit;
begin
  if Skip then
    Exit;
  LKit := NewItem('STR_MEDI_KIT');
  Assert.AreEqual(TXcomRuleItem.BT_MEDIKIT, LKit.Rules.BattleType);
  LActor := FindActor(LKit, False);
  if not Assigned(LActor) then
  begin
    TTestSkip.Ignore('no unit of this battle may use the medi-kit with nobody in front');
    Exit;
  end;
  OpenMenu(LActor, LKit);
  Assert.AreEqual(BA_USE, FMenu.Item(1).ActionType);
  ClickItem(1);
  Assert.AreEqual('STR_THERE_IS_NO_ONE_THERE', FAction.ResultText);
  Assert.AreEqual('', FScreens.Calls);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.DovrebbeAprireIlMedikitSuChiStaDavanti;
var
  LKit: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LScreen: TXcomState;
begin
  if Skip then
    Exit;
  LKit := NewItem('STR_MEDI_KIT');
  LActor := FindActor(LKit, True);
  if not Assigned(LActor) then
  begin
    TTestSkip.Ignore('no unit of this battle may use the medi-kit on someone in front');
    Exit;
  end;
  LScreen := TXcomState.Create(FWorld.Game);
  FScreens.Next := LScreen;
  OpenMenu(LActor, LKit);
  ClickItem(1);
  Assert.AreEqual('Medikit;', FScreens.Calls);
  Assert.IsNotNull(FScreens.LastTarget);
  Assert.AreSame(FBattle.Session.Battle.TileAt(FAction.Target).CurrentUnit, FScreens.LastTarget);
  Assert.AreEqual('', FAction.ResultText);
  Assert.AreSame(LScreen, FWorld.Game.TopState, 'the medi-kit takes the place of the menu');
end;

procedure TTestXcomActionMenuState.DovrebbeSpendereITuEAprireLoScanner;
var
  LScanner: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LScreen: TXcomState;
  LBefore: Integer;
  LCost: Integer;
begin
  if Skip then
    Exit;
  LScanner := NewItem('STR_PARTICLE_DISTURBANCE_SENSOR');
  Assert.AreEqual(TXcomRuleItem.BT_SCANNER, LScanner.Rules.BattleType);
  LActor := FindActor(LScanner, False);
  if not Assigned(LActor) then
    LActor := FindActor(LScanner, True);
  LScreen := TXcomState.Create(FWorld.Game);
  FScreens.Next := LScreen;
  OpenMenu(LActor, LScanner);
  LBefore := LActor.TimeUnits;
  // read before the click: the menu is popped by it and freed at the next frame
  LCost := FMenu.Item(1).TimeUnits;
  Assert.IsTrue(LCost > 0);
  ClickItem(1);
  Assert.AreEqual('Scanner;', FScreens.Calls);
  Assert.AreEqual(LBefore - LCost, LActor.TimeUnits);
  Assert.AreSame(LScreen, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.DovrebbeNonSpendereTuSenzaLoSchermoDelloScanner;
var
  LScanner: TXcomBattleItem;
  LActor: TXcomBattleUnit;
  LBefore: Integer;
begin
  if Skip then
    Exit;
  LScanner := NewItem('STR_PARTICLE_DISTURBANCE_SENSOR');
  LActor := FindActor(LScanner, False);
  if not Assigned(LActor) then
    LActor := FindActor(LScanner, True);
  OpenMenu(LActor, LScanner);
  LBefore := LActor.TimeUnits;
  ClickItem(1);
  Assert.AreEqual(LBefore, LActor.TimeUnits);
  Assert.AreEqual(BA_NONE, FAction.ActionType);
  Assert.AreSame(FMenu, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.DovrebbeDireCheMancanoITuPerLoScanner;
var
  LScanner: TXcomBattleItem;
  LActor: TXcomBattleUnit;
begin
  if Skip then
    Exit;
  LScanner := NewItem('STR_PARTICLE_DISTURBANCE_SENSOR');
  LActor := FindActor(LScanner, False);
  if not Assigned(LActor) then
    LActor := FindActor(LScanner, True);
  LActor.SpendTimeUnits(LActor.TimeUnits);
  FScreens.Next := TXcomState.Create(FWorld.Game);
  OpenMenu(LActor, LScanner);
  ClickItem(1);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FAction.ResultText);
  Assert.AreEqual('', FScreens.Calls);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

function TTestXcomActionMenuState.AnAlien: TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  // an alien may use every item: the research of the player does not matter
  for LUnit in FBattle.Session.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_HOSTILE) and Assigned(LUnit.Tile) and (not LUnit.IsOut) then
      Exit(LUnit);
  Result := nil;
end;

procedure TTestXcomActionMenuState.IlLanciamissiliScaricoDovrebbeDireCheNonHaMunizioni;
var
  LActor: TXcomBattleUnit;
begin
  if Skip then
    Exit;
  LActor := AnAlien;
  Assert.IsNotNull(LActor);
  OpenMenu(LActor, NewItem('STR_DISRUPTOR_PULSE_LAUNCHER'));
  Assert.AreEqual(BA_LAUNCH, FMenu.Item(1).ActionType);
  ClickItem(1);
  Assert.AreEqual('STR_NO_AMMUNITION_LOADED', FAction.ResultText);
  Assert.IsFalse(FAction.Targeting);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.IlLanciamissiliSenzaTuDovrebbeDireCheMancano;
var
  LActor: TXcomBattleUnit;
begin
  if Skip then
    Exit;
  LActor := AnAlien;
  OpenMenu(LActor, NewItem('STR_DISRUPTOR_PULSE_LAUNCHER'));
  LActor.SetTimeUnits(0);
  ClickItem(1);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FAction.ResultText);
  Assert.IsFalse(FAction.Targeting);
end;

procedure TTestXcomActionMenuState.IlColpoCorpoACorpoSenzaNessunoDavantiDovrebbeDirlo;
var
  LLance: TXcomBattleItem;
  LActor: TXcomBattleUnit;
begin
  if Skip then
    Exit;
  LLance := NewItem('STR_HEAVY_THERMIC_LANCE');
  Assert.AreEqual(TXcomRuleItem.BT_MELEE, LLance.Rules.BattleType);
  LActor := FindActor(LLance, False);
  if not Assigned(LActor) then
  begin
    TTestSkip.Ignore('every unit of this battle that may use the lance has someone in front');
    Exit;
  end;
  OpenMenu(LActor, LLance);
  Assert.AreEqual(BA_HIT, FMenu.Item(1).ActionType);
  ClickItem(1);
  Assert.AreEqual('STR_THERE_IS_NO_ONE_THERE', FAction.ResultText);
  // MeleeAttackBState will not be there to clear the action: the menu does
  Assert.AreEqual(BA_NONE, FAction.ActionType);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.IlColpoCorpoACorpoSenzaTuDovrebbeDireCheMancano;
var
  LActor: TXcomBattleUnit;
begin
  if Skip then
    Exit;
  LActor := AnAlien;
  OpenMenu(LActor, NewItem('STR_HEAVY_THERMIC_LANCE'));
  LActor.SetTimeUnits(0);
  ClickItem(1);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FAction.ResultText);
  Assert.AreEqual(BA_NONE, FAction.ActionType);
end;

procedure TTestXcomActionMenuState.IlBastoneStordenteDovrebbeOffrireLoStordimento;
var
  LTazer: TXcomBattleItem;
begin
  if Skip then
    Exit;
  LTazer := NewItem('STR_THERMAL_TAZER');
  OpenMenu(AnAlien, LTazer);
  Assert.AreEqual(BA_HIT, FMenu.Item(1).ActionType);
  Assert.AreEqual(Integer(TXcomRuleItem.DT_STUN), Integer(LTazer.Rules.DamageType));
  Assert.AreEqual(2, FMenu.ItemCount, 'throw and stun');
end;

procedure TTestXcomActionMenuState.LoPsiAmpDovrebbeOffrireControlloEPanicoAChiHaLAbilita;
var
  LActor: TXcomBattleUnit;
  LStats: TXcomUnitStats;
begin
  if Skip then
    Exit;
  LActor := AnAlien;
  LStats := LActor.Stats;
  LStats.PsiSkill := 60;
  LActor.Stats := LStats;
  OpenMenu(LActor, NewItem('STR_MC_DISRUPTOR'));
  Assert.AreEqual(3, FMenu.ItemCount, 'throw, mind control and panic');
  Assert.AreEqual(BA_MINDCONTROL, FMenu.Item(1).ActionType);
  Assert.AreEqual(BA_PANIC, FMenu.Item(2).ActionType);
  ClickItem(2);
  Assert.AreEqual(BA_PANIC, FAction.ActionType);
  Assert.IsTrue(FAction.Targeting, 'the attack waits for its target');
  Assert.AreEqual('', FAction.ResultText);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomActionMenuState.LoPsiAmpSenzaAbilitaPsionicaOffreSoloIlLancio;
var
  LActor: TXcomBattleUnit;
  LStats: TXcomUnitStats;
begin
  if Skip then
    Exit;
  LActor := AnAlien;
  LStats := LActor.Stats;
  LStats.PsiSkill := 0;
  LActor.Stats := LStats;
  OpenMenu(LActor, NewItem('STR_MC_DISRUPTOR'));
  Assert.AreEqual(1, FMenu.ItemCount);
  Assert.AreEqual(BA_THROW, FMenu.Item(0).ActionType);
end;

procedure TTestXcomActionMenuState.LaSondaMentaleDovrebbeAspettareIlBersaglio;
begin
  if Skip then
    Exit;
  OpenMenu(AnAlien, NewItem('STR_MC_READER'));
  Assert.AreEqual(BA_USE, FMenu.Item(1).ActionType);
  ClickItem(1);
  Assert.AreEqual(BA_USE, FAction.ActionType);
  Assert.IsTrue(FAction.Targeting);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

end.
