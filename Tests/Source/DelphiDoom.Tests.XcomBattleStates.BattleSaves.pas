{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the saves the battlescape asks by itself: the      }
{  autosave of the turns, the save of an ironman game, the quick save and the   }
{  quick load keys (with fakes of the screens and of the saver)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.BattleSaves;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.Tests.XcomBattleStates.Bench;

type
  /// <summary>The saved game in progress as the battlescape sees it: only ironman or not</summary>
  TFakeBattleSaver = class(TInterfacedObject, IXcomSavedGameSaver)
  public
    Ironman: Boolean;
    function IsIronman: Boolean;
    procedure SetName(const AName: string);
    function GetName: string;
    procedure SaveGame(const AFileName: string);
    procedure AbandonGame;
  end;

  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomBattleSaves = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    FSaver: TFakeBattleSaver;
    FSaverRef: IXcomSavedGameSaver;
    function Ready: Boolean;
    procedure PressKey(AKey: Integer);
    /// <summary>The turn screen is shown and closed with a click</summary>
    procedure PassTurnScreen;
    function Asked(const ACall: string): Integer;
    procedure RunUntilIdle;
    function InABase(ASoldier: TXcomSoldier): Boolean;
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
    procedure DopoIlCambioDiTurnoDovrebbePartireLAutosalvataggio;
    [Test]
    procedure LAutosalvataggioDovrebbeScrivereLaBattagliaNelSalvataggio;
    [Test]
    procedure ConLAutosalvataggioSpentoNonDovrebbeSalvare;
    [Test]
    procedure FuoriDallaFrequenzaNonDovrebbeSalvare;
    [Test]
    procedure InIronmanDovrebbeSalvareAncheConLAutosalvataggioSpento;
    [Test]
    procedure IlTastoDelSalvataggioRapidoDovrebbeChiedereIlSalvataggio;
    [Test]
    procedure IlTastoDelCaricamentoRapidoDovrebbeChiedereIlCaricamento;
    [Test]
    procedure InIronmanITastiRapidiNonFannoNulla;
    [Test]
    procedure LeSchermateVereDannoSalvataggioECaricamentoRapido;
    [Test]
    procedure IlSoldatoUccisoDovrebbeAndareNelMemorialeConLAssassino;
    [Test]
    procedure IlSoldatoMortoSenzaAssassinoHaSeStessoComeCausa;
    [Test]
    procedure UnAlienoUccisoNonToccaIlMemoriale;
  end;

implementation

uses
  DelphiDoom.XcomBattleStates.NextTurnState, DelphiDoom.XcomBattleStates.Screens,
  DelphiDoom.XcomMenu.SaveGameState, DelphiDoom.XcomMenu.SaveNames;

const
  KEY_F5 = 286;
  KEY_F9 = 290;

{ TFakeBattleSaver }

function TFakeBattleSaver.IsIronman: Boolean;
begin
  Result := Ironman;
end;

procedure TFakeBattleSaver.SetName(const AName: string);
begin
end;

function TFakeBattleSaver.GetName: string;
begin
  Result := 'game';
end;

procedure TFakeBattleSaver.SaveGame(const AFileName: string);
begin
end;

procedure TFakeBattleSaver.AbandonGame;
begin
end;

{ TTestXcomBattleSaves }

procedure TTestXcomBattleSaves.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomBattleSaves.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomBattleSaves.Setup;
begin
  FState := nil;
  FSaver := TFakeBattleSaver.Create;
  FSaverRef := FSaver;
  if FBench.Available then
  begin
    FBench.Start;
    FBench.World.Game.SetSavedGameSaver(FSaverRef);
    // every turn is a turn of the autosave
    FBench.World.Game.Options.SetValue('autosaveFrequency', 1);
    FState := FBench.PushBattlescape;
  end;
end;

procedure TTestXcomBattleSaves.TearDown;
begin
  FState := nil;
  FBench.Stop;
  FSaverRef := nil;
end;

function TTestXcomBattleSaves.Ready: Boolean;
begin
  Result := Assigned(FState);
  if not Result then
    Assert.Pass('the data of TFTD are not here');
end;

procedure TTestXcomBattleSaves.PressKey(AKey: Integer);
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

procedure TTestXcomBattleSaves.PassTurnScreen;
begin
  FBench.World.Game.PushState(TXcomNextTurnState.Create(FBench.World.Game, FState));
  FBench.World.Wait(40);
  FBench.World.Click(320, 100);
  FBench.World.Wait(40);
end;

function TTestXcomBattleSaves.Asked(const ACall: string): Integer;
var
  LCall: string;
begin
  Result := 0;
  for LCall in FBench.Screens.Calls do
    if LCall = ACall then
      Inc(Result);
end;

procedure TTestXcomBattleSaves.DopoIlCambioDiTurnoDovrebbePartireLAutosalvataggio;
begin
  if not Ready then
    Exit;
  Assert.AreEqual(Integer(FACTION_PLAYER), Integer(FBench.Session.Battle.Side));
  PassTurnScreen;
  Assert.AreEqual(1, Asked('SaveGame:auto'));
  // only once: the flag is cleared
  FBench.World.Wait(200);
  Assert.AreEqual(1, Asked('SaveGame:auto'));
end;

procedure TTestXcomBattleSaves.LAutosalvataggioDovrebbeScrivereLaBattagliaNelSalvataggio;
begin
  if not Ready then
    Exit;
  FBench.SavedGame.BattleGame := nil;
  PassTurnScreen;
  Assert.IsTrue(FBench.SavedGame.BattleGame <> nil, 'the saved game must hold the battle before it is written');
end;

procedure TTestXcomBattleSaves.ConLAutosalvataggioSpentoNonDovrebbeSalvare;
begin
  if not Ready then
    Exit;
  FBench.World.Game.Options.SetValue('autosave', 0);
  PassTurnScreen;
  Assert.AreEqual(0, Asked('SaveGame:auto'));
  Assert.AreEqual(0, Asked('SaveGame:ironman'));
end;

procedure TTestXcomBattleSaves.FuoriDallaFrequenzaNonDovrebbeSalvare;
begin
  if not Ready then
    Exit;
  // a frequency that the turn of the scenario is not a multiple of (and it is not the first turn)
  if FBench.Session.Battle.Turn = 1 then
  begin
    Assert.Pass('the scenario is at its first turn, always saved');
    Exit;
  end;
  FBench.World.Game.Options.SetValue('autosaveFrequency', FBench.Session.Battle.Turn + 1);
  PassTurnScreen;
  Assert.AreEqual(0, Asked('SaveGame:auto'));
end;

procedure TTestXcomBattleSaves.InIronmanDovrebbeSalvareAncheConLAutosalvataggioSpento;
begin
  if not Ready then
    Exit;
  FSaver.Ironman := True;
  FBench.World.Game.Options.SetValue('autosave', 0);
  PassTurnScreen;
  Assert.AreEqual(1, Asked('SaveGame:ironman'));
  Assert.AreEqual(0, Asked('SaveGame:auto'));
end;

procedure TTestXcomBattleSaves.IlTastoDelSalvataggioRapidoDovrebbeChiedereIlSalvataggio;
begin
  if not Ready then
    Exit;
  FBench.SavedGame.BattleGame := nil;
  PressKey(KEY_F5);
  Assert.AreEqual(1, Asked('SaveGame:quick'));
  Assert.IsTrue(FBench.SavedGame.BattleGame <> nil);
end;

procedure TTestXcomBattleSaves.IlTastoDelCaricamentoRapidoDovrebbeChiedereIlCaricamento;
begin
  if not Ready then
    Exit;
  PressKey(KEY_F9);
  Assert.AreEqual(1, Asked('QuickLoad'));
  Assert.AreEqual(0, Asked('SaveGame:quick'));
end;

procedure TTestXcomBattleSaves.InIronmanITastiRapidiNonFannoNulla;
begin
  if not Ready then
    Exit;
  FSaver.Ironman := True;
  PressKey(KEY_F5);
  PressKey(KEY_F9);
  Assert.AreEqual(0, Asked('SaveGame:quick'));
  Assert.AreEqual(0, Asked('QuickLoad'));
end;

procedure TTestXcomBattleSaves.LeSchermateVereDannoSalvataggioECaricamentoRapido;
var
  LScreens: IXcomBattleScreens;
  LState: TXcomState;
begin
  if not Ready then
    Exit;
  LScreens := TXcomBattleScreens.Create;
  LState := LScreens.SaveGame(FState, bskAuto);
  try
    Assert.IsTrue(LState is TXcomSaveGameState);
    Assert.AreEqual(TXcomSaveNames.AUTOSAVE_BATTLESCAPE, TXcomSaveGameState(LState).FileName);
  finally
    LState.Free;
  end;
  LState := LScreens.SaveGame(FState, bskQuick);
  try
    Assert.AreEqual(TXcomSaveNames.QUICKSAVE, TXcomSaveGameState(LState).FileName);
  finally
    LState.Free;
  end;
  LState := LScreens.SaveGame(FState, bskIronman);
  try
    Assert.AreEqual('game.sav', TXcomSaveGameState(LState).FileName);
  finally
    LState.Free;
  end;
  // the fake game has no catalog of saves: no quick save to load
  Assert.IsNull(LScreens.QuickLoad(FState));
end;

procedure TTestXcomBattleSaves.RunUntilIdle;
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
  Assert.IsTrue(LGuard < 1200, 'the battle never came back to idle');
end;

function TTestXcomBattleSaves.InABase(ASoldier: TXcomSoldier): Boolean;
var
  LBase: TXcomBase;
begin
  Result := False;
  for LBase in FBench.SavedGame.Bases do
    if LBase.Soldiers.IndexOf(ASoldier) >= 0 then
      Exit(True);
end;

procedure TTestXcomBattleSaves.IlSoldatoUccisoDovrebbeAndareNelMemorialeConLAssassino;
var
  LVictim: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LUnit: TXcomBattleUnit;
  LSoldier: TXcomSoldier;
  LDead: Integer;
begin
  if not Ready then
    Exit;
  LVictim := FBench.Session.Battle.SelectedUnit;
  LSoldier := LVictim.GeoscapeSoldier;
  Assert.IsNotNull(LSoldier);
  Assert.IsTrue(InABase(LSoldier));
  LAlien := nil;
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_HOSTILE) and (not LUnit.IsOut) then
    begin
      LAlien := LUnit;
      Break;
    end;
  Assert.IsNotNull(LAlien);
  LDead := FBench.SavedGame.DeadSoldiers.Count;
  LVictim.Damage(TXcomPosition.Make(0, 0, 0), 1000, TXcomRuleItem.DT_AP, True);
  Assert.AreEqual(0, LVictim.Health);
  FState.Game.CheckForCasualties(nil, LAlien);
  // SavedGame::killSoldier at once, before the death is even shown
  Assert.IsFalse(InABase(LSoldier), 'the soldier left its base');
  Assert.AreEqual(LDead + 1, FBench.SavedGame.DeadSoldiers.Count);
  Assert.IsTrue(FBench.SavedGame.DeadSoldiers.IndexOf(LSoldier) >= 0);
  Assert.IsNotNull(LSoldier.Death);
  Assert.IsNotNull(LSoldier.Death.Cause, 'the cause of the death');
  // one of our own died: the murderer is recorded instead of the victim
  Assert.AreEqual(Integer(FACTION_HOSTILE), LSoldier.Death.Cause.Faction);
  Assert.AreEqual(LAlien.UnitType, LSoldier.Death.Cause.UnitType);
  Assert.AreEqual('', LSoldier.Death.Cause.Name);
  Assert.AreEqual(Integer(STATUS_DEAD), LSoldier.Death.Cause.Status);
  Assert.AreEqual(FBench.SavedGame.Time.Day, LSoldier.Death.Time.Day);
  Assert.AreEqual(FBench.SavedGame.Time.Year, LSoldier.Death.Time.Year);
  Assert.IsTrue(LVictim.Statistics.KIA);
  Assert.IsTrue(LVictim.GeoscapeSoldier = LSoldier, 'the unit still knows its soldier');
  RunUntilIdle;
  // a second check of the casualties does not kill the soldier twice
  FState.Game.CheckForCasualties(nil, LAlien);
  Assert.AreEqual(LDead + 1, FBench.SavedGame.DeadSoldiers.Count);
end;

procedure TTestXcomBattleSaves.IlSoldatoMortoSenzaAssassinoHaSeStessoComeCausa;
var
  LVictim: TXcomBattleUnit;
  LSoldier: TXcomSoldier;
begin
  if not Ready then
    Exit;
  LVictim := FBench.Session.Battle.SelectedUnit;
  LSoldier := LVictim.GeoscapeSoldier;
  LVictim.Damage(TXcomPosition.Make(0, 0, 0), 1000, TXcomRuleItem.DT_AP, True);
  // no murderer and no explosion: a fatal wound
  FState.Game.CheckForCasualties(nil, nil);
  Assert.IsTrue(FBench.SavedGame.DeadSoldiers.IndexOf(LSoldier) >= 0);
  Assert.IsNotNull(LSoldier.Death.Cause);
  Assert.AreEqual(LSoldier.Name, LSoldier.Death.Cause.Name, 'the statistics of the kill are the ones of the victim');
  Assert.AreEqual(Integer(FACTION_PLAYER), LSoldier.Death.Cause.Faction);
  RunUntilIdle;
end;

procedure TTestXcomBattleSaves.UnAlienoUccisoNonToccaIlMemoriale;
var
  LUnit: TXcomBattleUnit;
  LAlien: TXcomBattleUnit;
  LDead: Integer;
begin
  if not Ready then
    Exit;
  LAlien := nil;
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_HOSTILE) and (not LUnit.IsOut) then
    begin
      LAlien := LUnit;
      Break;
    end;
  LDead := FBench.SavedGame.DeadSoldiers.Count;
  LAlien.Damage(TXcomPosition.Make(0, 0, 0), 1000, TXcomRuleItem.DT_AP, True);
  FState.Game.CheckForCasualties(nil, FBench.Session.Battle.SelectedUnit);
  RunUntilIdle;
  Assert.AreEqual(LDead, FBench.SavedGame.DeadSoldiers.Count);
end;

end.
