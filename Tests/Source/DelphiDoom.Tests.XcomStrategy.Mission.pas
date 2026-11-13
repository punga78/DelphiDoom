{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the missions of the   }
{  aliens (think, spawnUfo, ufoReachedWaypoint, ufoLifting) on the real saved  }
{  games, against what the real OpenXcom objects did (simgen mission)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Mission;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Yaml.Convert,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.UfoTrajectory, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.AlienMission,
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.LandMap.Intf,
  DelphiDoom.XcomStrategy.PolygonLandMap, DelphiDoom.XcomStrategy.UfoSpawner, DelphiDoom.XcomStrategy.MissionSites,
  DelphiDoom.XcomStrategy.MissionThinker, DelphiDoom.XcomStrategy.UfoWaypointHandler, DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomMissionScenario = class(TObject)
  strict private
    FSim: TXcomSim;
    FLines: TStringList;
    FRandom: IXcomRandom;
    FLand: IXcomLandMap;
    FSpawner: TXcomUfoSpawner;
    FSites: TXcomMissionSites;
    FThinker: TXcomMissionThinker;
    FHandler: TXcomUfoWaypointHandler;
    function Pick(AValue: Integer): Integer;
    function Real17(AValue: Double): string;
    procedure PrintUfo(AVariant, AMission, ARound, AIndex: Integer; const AAction: string; const AUfo: TXcomUfo);
    procedure Run(const AGame: TXcomSavedGame; AVariant: Integer);
    procedure CreateMissions(const AGame: TXcomSavedGame; AVariant: Integer);
    procedure PlayMission(const AGame: TXcomSavedGame; const AMission: TXcomAlienMission; AVariant,
      AMissionIndex: Integer);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareLeStesseMissioniDelVeroOpenXcom;
  end;

implementation

const
  // the positions of the UFOs are a sum of trigonometric terms: the C++ build is x87 with extended intermediates and
  // the 64 bit build is SSE, so they differ in the last bit or two (radians)
  POSITION_TOLERANCE = 1E-12;

{ TTestXcomMissionScenario }

procedure TTestXcomMissionScenario.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomMissionScenario.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomMissionScenario.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

function TTestXcomMissionScenario.Real17(AValue: Double): string;
begin
  Result := string(TYamlConvert.FormatGeneral(AValue, 17));
end;

procedure TTestXcomMissionScenario.PrintUfo(AVariant, AMission, ARound, AIndex: Integer; const AAction: string;
  const AUfo: TXcomUfo);
begin
  FLines.Add(Format('ufo|%d|%d|%d|%d|%s|status=%d|tp=%s|lon=%s|lat=%s|alt=%s|secs=%s|land=%d|det=%d|speed=%d|dest=%d',
    [AVariant, AMission, ARound, AIndex, AAction, AUfo.Status, UIntToStr(AUfo.TrajectoryPoint), Real17(AUfo.Longitude),
    Real17(AUfo.Latitude), AUfo.Altitude, UIntToStr(AUfo.SecondsRemaining), AUfo.LandId, Ord(AUfo.Detected),
    AUfo.Speed, Ord(AUfo.Destination <> nil)]));
end;

procedure TTestXcomMissionScenario.CreateMissions(const AGame: TXcomSavedGame; AVariant: Integer);
var
  LK, LR, LInitial: Integer;
  LRule: TXcomRuleAlienMission;
  LRegionRule: TXcomRuleRegion;
  LEffective: string;
  LOk: TList<string>;
  LMission: TXcomAlienMission;
begin
  if AGame.Bases.Count > 0 then
    AGame.Bases.First.RetaliationTarget := True;
  for LK := 0 to FSim.Ruleset.AlienMissions.Count - 1 do
  begin
    LRule := FSim.Ruleset.AlienMissions.Find(FSim.Ruleset.AlienMissions.Index[LK]);
    // the regions where the mission can run, in the order of the list
    LOk := TList<string>.Create;
    try
      for LR := 0 to Length(FSim.Ruleset.Regions.Index) - 1 do
      begin
        LRegionRule := FSim.Ruleset.Regions.Find(FSim.Ruleset.Regions.Index[LR]);
        if LRegionRule.MissionRegion = '' then
          LEffective := FSim.Ruleset.Regions.Index[LR]
        else
          LEffective := LRegionRule.MissionRegion;
        if FSim.RegionOk(LRule, FSim.Ruleset.Regions.Find(LEffective)) then
          LOk.Add(FSim.Ruleset.Regions.Index[LR]);
      end;
      if LOk.Count = 0 then
      begin
        FLines.Add(Format('skip|%d|%s', [AVariant, FSim.Ruleset.AlienMissions.Index[LK]]));
        Continue;
      end;
      LMission := TXcomAlienMission.Create(LRule);
      AGame.ActiveMissions.Add(LMission);
      LMission.SetId(AGame.GetId('ALIEN_MISSIONS'));
      LEffective := LOk[Pick(LOk.Count)];
      LMission.SetRegion(LEffective, FSim.Ruleset.Regions.Find(LEffective));
      if AGame.MonthsPassed < 0 then
        LMission.Race := LRule.GenerateRace(0, FRandom)
      else
        LMission.Race := LRule.GenerateRace(Cardinal(AGame.MonthsPassed), FRandom);
      if Pick(2) = 0 then
        LInitial := 0
      else
        LInitial := 30 * (1 + Pick(5));
      LMission.Start(Cardinal(LInitial), FRandom);
      if Pick(3) = 0 then
        LMission.MissionSiteZone := 0;
      if (AGame.AlienBases.Count > 0) and (Pick(2) = 0) then
        LMission.AlienBase := AGame.AlienBases.First;
      FLines.Add(Format('mission|%d|%s|region=%s|race=%s|countdown=%s', [AVariant, FSim.Ruleset.AlienMissions.Index[LK],
        LMission.Region, LMission.Race, UIntToStr(LMission.SpawnCountdown)]));
    finally
      LOk.Free;
    end;
  end;
end;

procedure TTestXcomMissionScenario.PlayMission(const AGame: TXcomSavedGame; const AMission: TXcomAlienMission;
  AVariant, AMissionIndex: Integer);
var
  LRound, LIndex: Integer;
  LUfo: TXcomUfo;
  LAction: string;
begin
  for LRound := 0 to 39 do
  begin
    if (AMission.SpawnCountdown > 30) and (Pick(2) = 0) then
      AMission.SpawnCountdown := 30;
    FThinker.Think(AMission, AGame);
    FLines.Add(Format('think|%d|%d|%d|wave=%s|ctr=%s|cd=%s|live=%s|ufos=%d|sites=%d|bases=%d', [AVariant, AMissionIndex,
      LRound, UIntToStr(AMission.NextWave), UIntToStr(AMission.NextUfoCounter), UIntToStr(AMission.SpawnCountdown),
      UIntToStr(AMission.LiveUfos), AGame.Ufos.Count, AGame.MissionSites.Count, AGame.AlienBases.Count]));
    LIndex := 0;
    while LIndex < AGame.Ufos.Count do
    begin
      LUfo := AGame.Ufos[LIndex];
      if (LUfo.Mission <> AMission) or (Pick(3) = 0) then
      begin
        Inc(LIndex);
        Continue;
      end;
      LAction := 'none';
      if LUfo.Status = TXcomUfo.STATUS_FLYING then
      begin
        if Pick(2) = 0 then
          LUfo.Detected := True;
        FHandler.UfoReachedWaypoint(AMission, LUfo, AGame);
        LAction := 'reach';
      end
      else if (LUfo.Status = TXcomUfo.STATUS_LANDED) or (LUfo.Status = TXcomUfo.STATUS_CRASHED) then
      begin
        if (LUfo.Status = TXcomUfo.STATUS_LANDED) and (Pick(8) = 0) then
          LUfo.Status := TXcomUfo.STATUS_CRASHED;
        FHandler.UfoLifting(AMission, LUfo, AGame);
        LAction := 'lift';
      end;
      PrintUfo(AVariant, AMissionIndex, LRound, LIndex, LAction, LUfo);
      if LUfo.Status = TXcomUfo.STATUS_DESTROYED then
        AGame.Ufos.Delete(LIndex)
      else
        Inc(LIndex);
    end;
  end;
end;

procedure TTestXcomMissionScenario.Run(const AGame: TXcomSavedGame; AVariant: Integer);
var
  LMission: Integer;
begin
  CreateMissions(AGame, AVariant);
  for LMission := 0 to AGame.ActiveMissions.Count - 1 do
  begin
    // the missions of the saved game have a region chosen at random: the ones that lack a zone are skipped
    if not FSim.RegionOk(AGame.ActiveMissions[LMission].Rule,
      FSim.Ruleset.Regions.Find(AGame.ActiveMissions[LMission].Region)) then
    begin
      FLines.Add(Format('skipmission|%d|%d', [AVariant, LMission]));
      Continue;
    end;
    PlayMission(AGame, AGame.ActiveMissions[LMission], AVariant, LMission);
  end;
end;

procedure TTestXcomMissionScenario.DovrebbeFareLeStesseMissioniDelVeroOpenXcom;
var
  LFolder: string;
  LVariant: Integer;
  LGame: TXcomSavedGame;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if not FSim.Available or (LFolder = '') then
  begin
    TTestSkip.Ignore('senza i dati di TFTD o i golden il confronto non si fa');
    Exit;
  end;
  FLines := TStringList.Create;
  try
    for LVariant := 0 to 15 do
    begin
      FLines.Clear;
      FRandom := TXcomRandom.Create(1);
      LGame := FSim.LoadSave(LVariant, FRandom);
      FLand := TXcomPolygonLandMap.Create(FSim.Ruleset.Globe);
      FSpawner := TXcomUfoSpawner.Create(FSim.Ruleset, FLand, FRandom);
      FSites := TXcomMissionSites.Create(FSim.Ruleset, FSim.Rules, FRandom);
      FThinker := TXcomMissionThinker.Create(FSim.Ruleset, FLand, FRandom, FSpawner, FSites);
      FHandler := TXcomUfoWaypointHandler.Create(FSim.Ruleset, FLand, FSpawner, FSites);
      try
        FRandom.SetSeed(5000 + LVariant);
        try
          Run(LGame, LVariant);
        except
          on E: Exception do
            raise Exception.CreateFmt('%s (variant %d, after: %s)', [E.Message, LVariant,
              FLines[FLines.Count - 1]]);
        end;
        FLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        Assert.AreEqual('', TXcomSim.FirstDifferenceTolerant(string(TXcomSim.GoldenText(LFolder +
          Format('sim%.2d.mission.txt', [LVariant]))), FLines.Text, POSITION_TOLERANCE),
          Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.CompareSave(LFolder + Format('sim%.2d.mission.sav', [LVariant]),
          FSim.SaveText(LGame, FRandom)), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LGame.Free;
        FHandler.Free;
        FThinker.Free;
        FSites.Free;
        FSpawner.Free;
        FLand := nil;
      end;
    end;
  finally
    FLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMissionScenario);

end.
