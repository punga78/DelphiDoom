{******************************************************************************}
{                                                                              }
{  DelphiDoom: tour of the xcom game - from the geoscape into the battle of     }
{  every kind of mission and back (landing, mission site, alien base, defense   }
{  of a base, last mission)                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the libraries of the game are derived from OpenXcom, GPL v3 or later)       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Missions;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   The missions of the saved games of Tests\Data\XcomSave\missions, played with the mouse on the game that the
  ///   program composes: the confirmation, the briefing, the inventory, the first turn, the mission aborted, the
  ///   debriefing and the geoscape again. The tests do nothing when the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourMissions = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Mission(const AName: string): Boolean;
    /// <summary>The mission type of the battle of the saved game</summary>
    function MissionType: string;
    /// <summary>From the briefing on top to the battlescape with the first turn started</summary>
    procedure EnterBattle;
    /// <summary>Aborts the mission of the battlescape on top and stops at the debriefing</summary>
    procedure AbortBattle;
    /// <summary>OK of the debriefing and of whatever follows it, to the geoscape</summary>
    procedure LeaveDebriefing;
    /// <summary>"Yes" of the landing confirmation with the mouse, the battle aborted, the geoscape again</summary>
    procedure LandAndComeBack(const AMissionType: string);
    /// <summary>Lets the defenses of the base fire until OK shows, and clicks it</summary>
    procedure WatchTheDefenses;
    /// <summary>Puts the soldiers of the battlescape on top onto the tiles of the exit; how many found a place</summary>
    function MoveSoldiersToExit: Integer;
    /// <summary>Soldiers on the exit, the mission aborted: the briefing of the next stage must follow</summary>
    procedure GoOnToStage(const AMissionType: string);
    /// <summary>Every alien of the battlescape on top dies, then the turn is ended until the battle is over</summary>
    procedure WinTheBattle;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareIlGiroDiUnUfoSchiantato;
    [Test]
    procedure DovrebbeFareIlGiroDiUnUfoAtterrato;
    [Test]
    procedure DovrebbeFareIlGiroDiUnSitoDiTerrore;
    [Test]
    procedure DovrebbeFareIlGiroDiUnaBaseAliena;
    [Test]
    procedure DovrebbeRimandareIlVelivoloAllaBaseConNo;
    [Test]
    procedure DovrebbeCombattereNellaBaseSenzaDifese;
    [Test]
    procedure DovrebbeFarSparareLeDifeseEPoiCombattereNellaBase;
    [Test]
    procedure DovrebbeDistruggereLUfoConLeDifeseDellaBase;
    [Test]
    procedure DovrebbePerdereLaBaseSenzaSoldati;
    [Test]
    procedure DovrebbePartirePerLUltimaMissione;
    [Test]
    procedure DovrebbeNascondereIlPulsanteDellUltimaMissioneSenzaLaRicerca;
    [Test]
    procedure DovrebbePassareAllaSecondaParteDellaBaseAliena;
    [Test]
    procedure DovrebbePassareAllaSecondaParteDiUnaNave;
    [Test]
    procedure DovrebbePassareAllaSecondaParteDiUnSitoDiArtefatti;
    [Test]
    procedure DovrebbeFareLeTrePartiDellUltimaMissione;
    [Test]
    procedure DovrebbeFareIlDebriefingSeNessunoEAllUscita;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.MapData,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattleStates.BattlescapeState;

const
  GEOSCAPE = 'TXcomGeoscapeState';
  BRIEFING = 'TXcomBriefingState';
  BATTLESCAPE = 'TXcomBattlescapeState';
  DEBRIEFING = 'TXcomDebriefingState';
  CONFIRM_LANDING = 'TXcomConfirmLandingState';
  BASE_DEFENSE = 'TXcomBaseDefenseState';
  /// <summary>SpecialTileType END_POINT</summary>
  END_POINT = 13;

procedure TTestXcomTourMissions.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourMissions.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourMissions.Mission(const AName: string): Boolean;
begin
  Result := FWorld.HasData and FWorld.LoadMission(AName);
  if not Result then
    TTestSkip.Ignore('i dati di TFTD o il salvataggio non ci sono');
end;

function TTestXcomTourMissions.MissionType: string;
begin
  Result := TXcomNodeReader.ReadString(FWorld.Save.BattleGame, 'missionType', '');
end;

procedure TTestXcomTourMissions.EnterBattle;
begin
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.IsTrue(Assigned(FWorld.Save.BattleGame), 'la battaglia e'' nel salvataggio dal briefing');
  // OK of the briefing: the inventory of the soldiers is on top of the screen of the first turn
  FWorld.Click(320, 346);
  FWorld.Wait(1000);
  Assert.AreEqual('TXcomInventoryState', FWorld.Top);
  FWorld.Click(508, 22);
  FWorld.Wait(1000);
  Assert.AreEqual('TXcomNextTurnState', FWorld.Top);
  FWorld.Click(320, 200);
  FWorld.Wait(1000);
  Assert.AreEqual(BATTLESCAPE, FWorld.Top);
end;

procedure TTestXcomTourMissions.AbortBattle;
begin
  // the abort button of the panel, then OK
  FWorld.Click(512, 336);
  Assert.AreEqual('TXcomAbortMissionState', FWorld.Top);
  FWorld.Click(150, 235);
  FWorld.Wait(1000);
  Assert.AreEqual(DEBRIEFING, FWorld.Top);
end;

procedure TTestXcomTourMissions.LeaveDebriefing;
var
  LTurn: Integer;
begin
  FWorld.Click(72, 372);
  FWorld.Wait(1000);
  // what follows the debriefing (missing items, promotions, the autosave) closes with OK
  for LTurn := 1 to 6 do
    if FWorld.Top <> GEOSCAPE then
    begin
      FWorld.Key(XCOM_KEY_RETURN);
      FWorld.Wait(1000);
    end;
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsFalse(Assigned(FWorld.Save.BattleGame), 'la battaglia e'' tolta dal salvataggio');
end;

procedure TTestXcomTourMissions.LandAndComeBack(const AMissionType: string);
begin
  // the craft is over its target: the first step of the time asks whether to land
  FWorld.Wait(1500);
  Assert.AreEqual(CONFIRM_LANDING, FWorld.Top);
  // Yes, with the mouse
  FWorld.Click(160, 320);
  FWorld.Wait(500);
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.AreEqual(AMissionType, MissionType);
  EnterBattle;
  AbortBattle;
  LeaveDebriefing;
end;

procedure TTestXcomTourMissions.WatchTheDefenses;
begin
  FWorld.Wait(1500);
  Assert.AreEqual(BASE_DEFENSE, FWorld.Top);
  // a line and two steps for every shot, three explosions for a destroyed UFO
  FWorld.Wait(12000);
  FWorld.Click(320, 358);
  FWorld.Wait(1000);
end;

procedure TTestXcomTourMissions.DovrebbeFareIlGiroDiUnUfoSchiantato;
begin
  if not Mission('crash') then
    Exit;
  LandAndComeBack('STR_UFO_CRASH_RECOVERY');
end;

procedure TTestXcomTourMissions.DovrebbeFareIlGiroDiUnUfoAtterrato;
begin
  if not Mission('landed') then
    Exit;
  LandAndComeBack('STR_UFO_GROUND_ASSAULT');
end;

procedure TTestXcomTourMissions.DovrebbeFareIlGiroDiUnSitoDiTerrore;
begin
  if not Mission('site_port') then
    Exit;
  LandAndComeBack('STR_PORT_TERROR');
  // the site of a mission that was fought is gone, whatever the result
  Assert.AreEqual(0, FWorld.Save.MissionSites.Count);
end;

procedure TTestXcomTourMissions.DovrebbeFareIlGiroDiUnaBaseAliena;
begin
  if not Mission('alienbase') then
    Exit;
  // the battle of an alien base has large units: the generator needs the pathfinding to place them
  LandAndComeBack('STR_ALIEN_BASE_ASSAULT');
  Assert.AreEqual(2, FWorld.Save.AlienBases.Count, 'la base aliena abbandonata resta');
end;

procedure TTestXcomTourMissions.DovrebbeRimandareIlVelivoloAllaBaseConNo;
begin
  if not Mission('crash') then
    Exit;
  FWorld.Wait(1500);
  Assert.AreEqual(CONFIRM_LANDING, FWorld.Top);
  FWorld.Click(350, 320);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsFalse(Assigned(FWorld.Save.BattleGame));
  Assert.IsTrue(FWorld.FirstBase.Crafts[0].Destination = FWorld.FirstBase, 'il velivolo torna alla base');
end;

procedure TTestXcomTourMissions.DovrebbeCombattereNellaBaseSenzaDifese;
begin
  if not Mission('defense') then
    Exit;
  // no defense facility: the briefing of the battle in the base comes at once
  FWorld.Wait(1500);
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.AreEqual('STR_BASE_DEFENSE', MissionType);
  EnterBattle;
  AbortBattle;
  LeaveDebriefing;
  Assert.AreEqual(0, FWorld.Save.Bases.Count, 'la base abbandonata e'' persa');
end;

procedure TTestXcomTourMissions.DovrebbeFarSparareLeDifeseEPoiCombattereNellaBase;
begin
  if not Mission('defense_one') then
    Exit;
  // one torpedo defense cannot destroy a battleship: the battle follows
  WatchTheDefenses;
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.AreEqual('STR_BASE_DEFENSE', MissionType);
end;

procedure TTestXcomTourMissions.DovrebbeDistruggereLUfoConLeDifeseDellaBase;
var
  LUfo: TXcomUfo;
begin
  if not Mission('defense_weak_ufo') then
    Exit;
  WatchTheDefenses;
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.AreEqual(1, FWorld.Save.Bases.Count);
  Assert.IsFalse(Assigned(FWorld.Save.BattleGame));
  for LUfo in FWorld.Save.Ufos do
    Assert.AreEqual(TXcomUfo.STATUS_DESTROYED, LUfo.Status);
end;

procedure TTestXcomTourMissions.DovrebbePerdereLaBaseSenzaSoldati;
begin
  if not Mission('undefended') then
    Exit;
  FWorld.Wait(1500);
  Assert.AreEqual('TXcomBaseDestroyedState', FWorld.Top);
  Assert.AreEqual(1, FWorld.Save.Bases.Count, 'la base c''e'' fino a OK');
  // the UFO has finished its duty (the retaliation of the saved game is of another region: it goes on)
  Assert.AreEqual(TXcomUfo.STATUS_DESTROYED, FWorld.Save.Ufos[0].Status);
  FWorld.Click(320, 305);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.AreEqual(0, FWorld.Save.Bases.Count);
end;

procedure TTestXcomTourMissions.DovrebbePartirePerLUltimaMissione;
begin
  if not Mission('final') then
    Exit;
  // Intercept, the first craft of the list (the Leviathan), the button of the last mission, Yes
  FWorld.Click(575, 12);
  FWorld.Click(100, 161);
  Assert.AreEqual('TXcomSelectDestinationState', FWorld.Top);
  FWorld.Click(420, 28);
  Assert.AreEqual('TXcomConfirmCydoniaState', FWorld.Top);
  FWorld.Click(220, 305);
  FWorld.Wait(500);
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.AreEqual('STR_TLETH_P1', MissionType);
  EnterBattle;
end;

procedure TTestXcomTourMissions.DovrebbeNascondereIlPulsanteDellUltimaMissioneSenzaLaRicerca;
begin
  // the same craft, but the research of the last mission is not done
  if not Mission('final_locked') then
    Exit;
  FWorld.Click(575, 12);
  FWorld.Click(100, 161);
  Assert.AreEqual('TXcomSelectDestinationState', FWorld.Top);
  FWorld.Click(420, 28);
  Assert.AreEqual('TXcomSelectDestinationState', FWorld.Top);
end;

function TTestXcomTourMissions.MoveSoldiersToExit: Integer;
var
  LBattle: TXcomSavedBattleGame;
  LExits: TArray<TXcomTile>;
  LIndex, LNext: Integer;
  LTile: TXcomTile;
  LFloor: TXcomMapData;
  LUnit: TXcomBattleUnit;
begin
  LBattle := (FWorld.Game.TopState as TXcomBattlescapeState).Session.Battle;
  LExits := nil;
  for LIndex := 0 to LBattle.MapSizeXyz - 1 do
  begin
    LTile := LBattle.TileByIndex(LIndex);
    LFloor := LTile.MapData[XCOM_PART_FLOOR];
    if Assigned(LFloor) and (LFloor.SpecialType = END_POINT) and not Assigned(LTile.CurrentUnit) then
      LExits := LExits + [LTile];
  end;
  Result := 0;
  LNext := 0;
  for LUnit in LBattle.Units do
    if (LUnit.OriginalFaction = FACTION_PLAYER) and (not LUnit.IsOut) and (LUnit.Armor.Size = 1) then
      while LNext <= High(LExits) do
      begin
        LTile := LUnit.Tile;
        if LBattle.SetUnitPosition(LUnit, LExits[LNext].Position) then
        begin
          // the tile the unit has left
          if Assigned(LTile) and (LTile <> LUnit.Tile) then
            LTile.SetUnit(nil);
          Inc(Result);
          Inc(LNext);
          Break;
        end;
        Inc(LNext);
      end;
end;

procedure TTestXcomTourMissions.WinTheBattle;
var
  LUnit: TXcomBattleUnit;
  LTurn: Integer;
begin
  for LUnit in (FWorld.Game.TopState as TXcomBattlescapeState).Session.Battle.Units do
    if (LUnit.OriginalFaction = FACTION_HOSTILE) and not LUnit.IsOut then
      LUnit.InstaKill;
  // the end turn button of the panel; the screens of the turns close with a click
  FWorld.Click(512, 304);
  for LTurn := 1 to 30 do
  begin
    if (FWorld.Top <> BATTLESCAPE) and (FWorld.Top <> 'TXcomNextTurnState') then
      Exit;
    if FWorld.Top = 'TXcomNextTurnState' then
      FWorld.Click(320, 200);
    FWorld.Wait(1000);
  end;
end;

procedure TTestXcomTourMissions.GoOnToStage(const AMissionType: string);
var
  LSoldiers: Integer;
begin
  Assert.AreEqual(BATTLESCAPE, FWorld.Top);
  LSoldiers := MoveSoldiersToExit;
  Assert.IsTrue(LSoldiers > 0, 'la mappa ha un''uscita con posto per un soldato');
  FWorld.Click(512, 336);
  Assert.AreEqual('TXcomAbortMissionState', FWorld.Top);
  FWorld.Click(150, 235);
  FWorld.Wait(1000);
  // no debriefing yet: the briefing of the next stage, with the battle still in the saved game
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.AreEqual(AMissionType, MissionType);
  EnterBattle;
  Assert.AreEqual(AMissionType, (FWorld.Game.TopState as TXcomBattlescapeState).Session.Battle.MissionType);
end;

procedure TTestXcomTourMissions.DovrebbePassareAllaSecondaParteDellaBaseAliena;
begin
  if not Mission('alienbase') then
    Exit;
  FWorld.Wait(1500);
  FWorld.Click(160, 320);
  FWorld.Wait(500);
  EnterBattle;
  GoOnToStage('STR_ALIEN_COLONY_P2');
  // the second part is the last: abandoned, the mission ends with its debriefing
  AbortBattle;
  LeaveDebriefing;
end;

procedure TTestXcomTourMissions.DovrebbePassareAllaSecondaParteDiUnaNave;
begin
  if not Mission('site_cargo') then
    Exit;
  FWorld.Wait(1500);
  FWorld.Click(160, 320);
  FWorld.Wait(500);
  Assert.AreEqual('STR_CARGO_SHIP_P1', MissionType);
  EnterBattle;
  // the deck of the ship has no exit: the second part comes when every alien of the first is dead
  Assert.AreEqual(0, MoveSoldiersToExit);
  WinTheBattle;
  Assert.AreEqual(BRIEFING, FWorld.Top);
  Assert.AreEqual('STR_CARGO_SHIP_P2', MissionType);
  EnterBattle;
  AbortBattle;
  LeaveDebriefing;
  Assert.AreEqual(0, FWorld.Save.MissionSites.Count);
end;

procedure TTestXcomTourMissions.DovrebbePassareAllaSecondaParteDiUnSitoDiArtefatti;
begin
  if not Mission('site_artifact') then
    Exit;
  FWorld.Wait(1500);
  FWorld.Click(160, 320);
  FWorld.Wait(500);
  Assert.AreEqual('STR_ARTIFACT_SITE_P1', MissionType);
  EnterBattle;
  GoOnToStage('STR_ARTIFACT_SITE_P2');
  AbortBattle;
  LeaveDebriefing;
end;

procedure TTestXcomTourMissions.DovrebbeFareLeTrePartiDellUltimaMissione;
var
  LSoldiers: Integer;
begin
  if not Mission('final') then
    Exit;
  FWorld.Click(575, 12);
  FWorld.Click(100, 161);
  FWorld.Click(420, 28);
  FWorld.Click(220, 305);
  FWorld.Wait(500);
  EnterBattle;
  LSoldiers := (FWorld.Game.TopState as TXcomBattlescapeState).Session.Battle.Units.Count;
  Assert.IsTrue(LSoldiers > 0);
  GoOnToStage('STR_TLETH_P2');
  GoOnToStage('STR_TLETH_P3');
end;

procedure TTestXcomTourMissions.DovrebbeFareIlDebriefingSeNessunoEAllUscita;
begin
  if not Mission('site_cargo') then
    Exit;
  FWorld.Wait(1500);
  FWorld.Click(160, 320);
  FWorld.Wait(500);
  EnterBattle;
  // the soldiers are still in the craft: the mission is abandoned, the second part never comes
  AbortBattle;
  LeaveDebriefing;
end;

end.
