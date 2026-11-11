{******************************************************************************}
{                                                                              }
{  DelphiDoom: the New Battle screen of the main menu of OpenXcom (the mission  }
{  generator) on the game the program composes, with the real data of TFTD      }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.NewBattle;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomMenu.NewBattleState, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>The tests do nothing when the data of the game is not there</summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourNewBattle = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    /// <summary>The main menu and a click on New Battle; False without the data of the game</summary>
    function Open: Boolean;
    function Screen: TXcomNewBattleState;
    function SoldiersOnCraft: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAprirsiDalMenuConUnaBaseFattaPerLaBattaglia;
    [Test]
    procedure DovrebbeRiempireLeListeDalleRegole;
    [Test]
    procedure DovrebbeRifareTuttoConRandomize;
    [Test]
    procedure DovrebbeTornareAlMenuConCancelESenzaPartita;
    [Test]
    procedure DovrebbeRitrovareLeScelteLaVoltaDopo;
    [Test]
    procedure DovrebbeAprireLEquipaggiamentoDelVelivolo;
    [Test]
    procedure DovrebbeArrivareAlBriefingConOk;
  end;

implementation

const
  // the buttons in the pixels of the window (twice the picture of the game)
  MENU_NEW_BATTLE_X = 420;
  MENU_NEW_BATTLE_Y = 200;
  BUTTON_OK_X = 116;
  BUTTON_CANCEL_X = 320;
  BUTTON_RANDOM_X = 524;
  BUTTONS_Y = 368;
  BUTTON_EQUIP_X = 518;
  BUTTON_EQUIP_Y = 108;
  SOLDIERS = 30;

procedure TTestXcomTourNewBattle.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourNewBattle.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourNewBattle.Open: Boolean;
begin
  Result := FWorld.HasData;
  if not Result then
    Exit;
  FWorld.Wait(5000);
  FWorld.Click(MENU_NEW_BATTLE_X, MENU_NEW_BATTLE_Y);
  FWorld.Wait(500);
end;

function TTestXcomTourNewBattle.Screen: TXcomNewBattleState;
begin
  Assert.AreEqual('TXcomNewBattleState', FWorld.Top);
  Result := TXcomNewBattleState(FWorld.Game.TopState);
end;

function TTestXcomTourNewBattle.SoldiersOnCraft: Integer;
begin
  Result := Screen.Craft.NumSoldiers(Screen.SavedGame.Bases.First.Soldiers);
end;

procedure TTestXcomTourNewBattle.DovrebbeAprirsiDalMenuConUnaBaseFattaPerLaBattaglia;
var
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
begin
  if not Open then
    Exit;
  Assert.IsNotNull(Screen.Craft, 'il velivolo della battaglia');
  Assert.AreSame(Screen.SavedGame, FWorld.Save, 'la partita della sessione e'' quella della schermata');
  LBase := Screen.SavedGame.Bases.First;
  Assert.AreEqual(1, LBase.Crafts.Count);
  Assert.AreEqual(SOLDIERS, LBase.Soldiers.Count);
  Assert.AreEqual(Screen.Craft.Rules.Soldiers, SoldiersOnCraft, 'il velivolo parte pieno');
  for LSoldier in LBase.Soldiers do
    Assert.AreEqual(0, LSoldier.CurrentStats.Bravery mod 10, 'il coraggio resta un multiplo di dieci');
  Assert.IsTrue(LBase.StorageItems.Contents.Count > 10, 'un oggetto di ogni tipo nei magazzini');
  Assert.IsTrue(Screen.Craft.Items.Contents.Count > 5, 'e le armi sul velivolo');
  Assert.IsTrue(Screen.SavedGame.Discovered.Count > 10, 'tutta la ricerca e'' fatta');
end;

procedure TTestXcomTourNewBattle.DovrebbeRiempireLeListeDalleRegole;
var
  LRace: string;
begin
  if not Open then
    Exit;
  Assert.IsTrue(Length(Screen.MissionTypes) > 5, 'le missioni sono gli schieramenti delle regole');
  Assert.IsTrue(Length(Screen.CraftTypes) > 0, 'i velivoli che portano soldati');
  Assert.IsTrue(Length(Screen.TerrainTypes) > 0, 'i terreni della prima missione');
  Assert.IsTrue(Length(Screen.AlienRaces) > 0);
  for LRace in Screen.AlienRaces do
    Assert.AreEqual(0, Pos('_UNDERWATER', LRace), 'le razze sott''acqua non si scelgono');
  Assert.AreEqual(0, Screen.MissionBox.GetSelected);
  Assert.AreEqual(Length(Screen.TerrainTypes) > 1, Screen.TerrainBox.Visible,
    'la lista dei terreni si vede solo se ce n''e'' piu'' di uno');
end;

procedure TTestXcomTourNewBattle.DovrebbeRifareTuttoConRandomize;
var
  LTurn: Integer;
begin
  if not Open then
    Exit;
  for LTurn := 1 to 5 do
  begin
    FWorld.Click(BUTTON_RANDOM_X, BUTTONS_Y);
    Assert.IsNotNull(Screen.Craft);
    Assert.AreSame(Screen.SavedGame, FWorld.Save);
    Assert.AreEqual(SOLDIERS, Screen.SavedGame.Bases.First.Soldiers.Count);
    Assert.IsTrue(SoldiersOnCraft <= Screen.Craft.Rules.Soldiers, 'nessuno resta su un velivolo troppo piccolo');
    Assert.IsTrue(Screen.MissionBox.GetSelected < Length(Screen.MissionTypes));
    Assert.IsTrue(Screen.TerrainBox.GetSelected < Length(Screen.TerrainTypes));
    Assert.IsTrue(Screen.DarknessSlider.GetValue in [0..15]);
  end;
end;

procedure TTestXcomTourNewBattle.DovrebbeTornareAlMenuConCancelESenzaPartita;
begin
  if not Open then
    Exit;
  FWorld.Click(BUTTON_CANCEL_X, BUTTONS_Y);
  Assert.AreEqual('TXcomMainMenuState', FWorld.Top);
  Assert.IsNull(FWorld.Game.Session, 'Game::setSavedGame(0)');
  Assert.IsTrue(TFile.Exists(TPath.Combine(FWorld.Game.Options.MasterUserFolder, 'battle.cfg')),
    'le scelte restano in battle.cfg');
end;

procedure TTestXcomTourNewBattle.DovrebbeRitrovareLeScelteLaVoltaDopo;
var
  LMission, LRace, LDarkness, LDifficulty: Integer;
  LName: string;
begin
  if not Open then
    Exit;
  FWorld.Click(BUTTON_RANDOM_X, BUTTONS_Y);
  LMission := Screen.MissionBox.GetSelected;
  LRace := Screen.AlienRaceBox.GetSelected;
  LDarkness := Screen.DarknessSlider.GetValue;
  LDifficulty := Screen.DifficultyBox.GetSelected;
  LName := Screen.SavedGame.Bases.First.Soldiers.First.Name;
  FWorld.Click(BUTTON_CANCEL_X, BUTTONS_Y);
  FWorld.Click(MENU_NEW_BATTLE_X, MENU_NEW_BATTLE_Y);
  FWorld.Wait(500);
  Assert.AreEqual(LMission, Screen.MissionBox.GetSelected);
  Assert.AreEqual(LRace, Screen.AlienRaceBox.GetSelected);
  Assert.AreEqual(LDarkness, Screen.DarknessSlider.GetValue);
  Assert.AreEqual(LDifficulty, Screen.DifficultyBox.GetSelected);
  Assert.AreEqual(SOLDIERS, Screen.SavedGame.Bases.First.Soldiers.Count, 'la base viene dal file');
  Assert.AreEqual(LName, Screen.SavedGame.Bases.First.Soldiers.First.Name, 'con gli stessi soldati');
  Assert.IsNotNull(Screen.Craft);
end;

procedure TTestXcomTourNewBattle.DovrebbeAprireLEquipaggiamentoDelVelivolo;
begin
  if not Open then
    Exit;
  FWorld.Click(BUTTON_EQUIP_X, BUTTON_EQUIP_Y);
  FWorld.Wait(500);
  Assert.AreEqual('TXcomCraftInfoState', FWorld.Top);
end;

procedure TTestXcomTourNewBattle.DovrebbeArrivareAlBriefingConOk;
begin
  if not Open then
    Exit;
  FWorld.Click(BUTTON_OK_X, BUTTONS_Y);
  FWorld.Wait(500);
  Assert.AreEqual('TXcomBriefingState', FWorld.Top, 'il generatore ha fatto la battaglia della prima missione');
end;

end.
