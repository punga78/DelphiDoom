{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - twenty days of the    }
{  geoscape (time5Seconds ... time1Day) on the real saved games, against the   }
{  code of GeoscapeState run on the real OpenXcom objects (simgen time)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Time;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Convert,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.Events.Intf,
  DelphiDoom.XcomStrategy.NullEvents, DelphiDoom.XcomStrategy.DefaultSettings, DelphiDoom.XcomStrategy.Factory,
  DelphiDoom.XcomStrategy.Simulation, DelphiDoom.Tests.XcomSave.Sim;

type
  /// <summary>Writes the events as the lines of the harness (ev|...)</summary>
  TXcomRecordingEvents = class(TXcomNullGeoscapeEvents)
  strict private
    FGame: TXcomSavedGame;
    FLines: TStringList;
    function BaseIndex(const ABase: TXcomBase): Integer;
  public
    constructor Create(const AGame: TXcomSavedGame; const ALines: TStringList);
    procedure GameLost; override;
    procedure UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean); override;
    procedure UfoLost(const AUfo: TXcomUfo); override;
    procedure MissionDetected(const ASite: TXcomMissionSite); override;
    procedure BaseAttacked(const ABase: TXcomBase; const AUfo: TXcomUfo); override;
    procedure CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint); override;
    procedure DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo); override;
    procedure DogfightImpossible(const ACraft: TXcomCraft; const AReason: string); override;
    procedure LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget); override;
    procedure CraftPatrolling(const ACraft: TXcomCraft); override;
    procedure LowFuel(const ACraft: TXcomCraft); override;
    procedure CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft; const AItem: string;
      ARearming: Boolean); override;
    procedure ItemsArriving; override;
    procedure ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
      AProgress: TXcomProductionProgress); override;
    procedure FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility); override;
    procedure ResearchFinished(const ABase: TXcomBase; const AResearchName: string); override;
    procedure StorageExceeded(const ABase: TXcomBase); override;
    procedure AutosaveDue(AIronman: Boolean); override;
    procedure MonthlyReport(APsiTraining: Boolean); override;
    procedure AlienBaseDiscovered(const ABase: TXcomAlienBase); override;
  end;

  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomTimeScenario = class(TObject)
  strict private
    FSim: TXcomSim;
    FLines: TStringList;
    FRandom: IXcomRandom;
    FStage: string;
    function Pick(AValue: Integer): Integer;
    procedure SetClock(const AGame: TXcomSavedGame);
    procedure CreateMissions(const AGame: TXcomSavedGame);
    procedure LaunchCrafts(const AGame: TXcomSavedGame; AVariant: Integer);
    procedure Prepare(const AGame: TXcomSavedGame; AVariant: Integer);
    procedure RunDays(const AGame: TXcomSavedGame; const ASimulation: TXcomGeoscapeSimulation; AVariant, ADays: Integer);
    procedure RunScenario(const AGame: TXcomSavedGame; const ASimulation: TXcomGeoscapeSimulation; AVariant: Integer;
      AMonths: Boolean);
    procedure Compare(const AScenario: string; AMonths: Boolean);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareVentiGiorniComeIlCodiceDiGeoscapeStateSuiVeriOggetti;
    [Test]
    procedure DovrebbeFareTreMesiComeIlCodiceDiGeoscapeStateSuiVeriOggetti;
  end;

implementation

const
  // after 20 days of moves the positions differ in the last bits (the C++ build is x87 with extended intermediates)
  POSITION_TOLERANCE = 1E-9;

{ TXcomRecordingEvents }

constructor TXcomRecordingEvents.Create(const AGame: TXcomSavedGame; const ALines: TStringList);
begin
  inherited Create;
  FGame := AGame;
  FLines := ALines;
end;

function TXcomRecordingEvents.BaseIndex(const ABase: TXcomBase): Integer;
begin
  Result := FGame.Bases.IndexOf(ABase);
end;

procedure TXcomRecordingEvents.GameLost;
begin
  FLines.Add('ev|GameLost');
end;

procedure TXcomRecordingEvents.UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean);
begin
  FLines.Add(Format('ev|UfoDetected|%d|%d', [AUfo.Id, Ord(AHyperDetected)]));
end;

procedure TXcomRecordingEvents.UfoLost(const AUfo: TXcomUfo);
begin
  FLines.Add(Format('ev|UfoLost|%d', [AUfo.Id]));
end;

procedure TXcomRecordingEvents.MissionDetected(const ASite: TXcomMissionSite);
begin
  FLines.Add(Format('ev|MissionDetected|%d', [ASite.Id]));
end;

procedure TXcomRecordingEvents.BaseAttacked(const ABase: TXcomBase; const AUfo: TXcomUfo);
begin
  FLines.Add(Format('ev|BaseAttacked|%d|%d', [Ord(ABase.Longitude > 0), AUfo.Id]));
end;

procedure TXcomRecordingEvents.CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint);
begin
  FLines.Add(Format('ev|CraftNeedsOrders|%d|%d', [ACraft.Id, AWaypoint.Id]));
  inherited CraftNeedsOrders(ACraft, AWaypoint);
end;

procedure TXcomRecordingEvents.DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
begin
  FLines.Add(Format('ev|Dogfight|%d|%d', [ACraft.Id, AUfo.Id]));
end;

procedure TXcomRecordingEvents.DogfightImpossible(const ACraft: TXcomCraft; const AReason: string);
begin
  if AReason = 'STR_UNABLE_TO_ENGAGE_DEPTH' then
    FLines.Add(Format('ev|DogfightImpossible|%d|depth', [ACraft.Id]))
  else
    FLines.Add(Format('ev|DogfightImpossible|%d|airborne', [ACraft.Id]));
end;

procedure TXcomRecordingEvents.LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget);
var
  LKind: string;
begin
  if ATarget is TXcomUfo then
    LKind := 'ufo'
  else if ATarget is TXcomMissionSite then
    LKind := 'site'
  else
    LKind := 'alienbase';
  FLines.Add(Format('ev|Landing|%d|%s', [ACraft.Id, LKind]));
end;

procedure TXcomRecordingEvents.CraftPatrolling(const ACraft: TXcomCraft);
begin
  FLines.Add(Format('ev|Patrol|%d', [ACraft.Id]));
end;

procedure TXcomRecordingEvents.LowFuel(const ACraft: TXcomCraft);
begin
  FLines.Add(Format('ev|LowFuel|%d', [ACraft.Id]));
end;

procedure TXcomRecordingEvents.CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft; const AItem: string;
  ARearming: Boolean);
begin
  if ARearming then
    FLines.Add(Format('ev|CraftShortage|%d|%s|rearm', [ACraft.Id, AItem]))
  else
    FLines.Add(Format('ev|CraftShortage|%d|%s|refuel', [ACraft.Id, AItem]));
end;

procedure TXcomRecordingEvents.ItemsArriving;
begin
  FLines.Add('ev|ItemsArriving');
end;

procedure TXcomRecordingEvents.ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
  AProgress: TXcomProductionProgress);
begin
  FLines.Add(Format('ev|ProductionFinished|%d|%s|%d', [BaseIndex(ABase), AProductionName, Ord(AProgress)]));
end;

procedure TXcomRecordingEvents.FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility);
begin
  FLines.Add(Format('ev|FacilityBuilt|%d|%s', [BaseIndex(ABase), AFacility.Rules.FacilityType]));
end;

procedure TXcomRecordingEvents.ResearchFinished(const ABase: TXcomBase; const AResearchName: string);
begin
  FLines.Add(Format('ev|ResearchFinished|%d|%s', [BaseIndex(ABase), AResearchName]));
end;

procedure TXcomRecordingEvents.StorageExceeded(const ABase: TXcomBase);
begin
  FLines.Add(Format('ev|StorageExceeded|%d', [BaseIndex(ABase)]));
end;

procedure TXcomRecordingEvents.AutosaveDue(AIronman: Boolean);
begin
  if AIronman then
    FLines.Add('ev|Autosave|ironman')
  else
    FLines.Add('ev|Autosave|auto');
end;

procedure TXcomRecordingEvents.MonthlyReport(APsiTraining: Boolean);
begin
  FLines.Add(Format('ev|MonthlyReport|%d', [Ord(APsiTraining)]));
end;

procedure TXcomRecordingEvents.AlienBaseDiscovered(const ABase: TXcomAlienBase);
begin
  FLines.Add('ev|AlienBaseDiscovered');
end;

{ TTestXcomTimeScenario }

procedure TTestXcomTimeScenario.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomTimeScenario.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomTimeScenario.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

procedure TTestXcomTimeScenario.SetClock(const AGame: TXcomSavedGame);
var
  LNode: IYamlNode;
begin
  // day 2 at midnight, so that twenty days do not reach the end of the month
  LNode := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(LNode, 'second', 0);
  TXcomNodeWriter.SetInteger(LNode, 'minute', 0);
  TXcomNodeWriter.SetInteger(LNode, 'hour', 0);
  TXcomNodeWriter.SetInteger(LNode, 'weekday', 3);
  TXcomNodeWriter.SetInteger(LNode, 'day', 2);
  TXcomNodeWriter.SetInteger(LNode, 'month', AGame.Time.Month);
  TXcomNodeWriter.SetInteger(LNode, 'year', AGame.Time.Year);
  AGame.Time.Load(LNode);
end;

procedure TTestXcomTimeScenario.CreateMissions(const AGame: TXcomSavedGame);
var
  LK, LR, LInitial: Integer;
  LRule: TXcomRuleAlienMission;
  LRegionRule: TXcomRuleRegion;
  LEffective: string;
  LOk: TList<string>;
  LMission: TXcomAlienMission;
begin
  for LK := 0 to FSim.Ruleset.AlienMissions.Count - 1 do
  begin
    LRule := FSim.Ruleset.AlienMissions.Find(FSim.Ruleset.AlienMissions.Index[LK]);
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
        Continue;
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
    finally
      LOk.Free;
    end;
  end;
end;

procedure TTestXcomTimeScenario.LaunchCrafts(const AGame: TXcomSavedGame; AVariant: Integer);
var
  LBase, LCraftIndex: Integer;
  LCraft: TXcomCraft;
  LUfo: TXcomUfo;
  LWaypoint: TXcomWaypoint;
begin
  for LBase := 0 to AGame.Bases.Count - 1 do
    for LCraftIndex := 0 to AGame.Bases[LBase].Crafts.Count - 1 do
    begin
      LCraft := AGame.Bases[LBase].Crafts[LCraftIndex];
      if Pick(3) <> 0 then
        Continue;
      LCraft.Status := 'STR_OUT';
      if (AGame.Ufos.Count > 0) and (Pick(2) = 0) then
      begin
        LUfo := AGame.Ufos[Pick(AGame.Ufos.Count)];
        LUfo.Detected := True;
        LCraft.SetDestination(LUfo);
      end
      else
      begin
        LWaypoint := TXcomWaypoint.Create;
        LWaypoint.SetLongitude(Pick(628) * 0.01);
        LWaypoint.SetLatitude((Pick(200) - 100) * 0.01);
        LWaypoint.Id := AGame.GetId('STR_WAYPOINT');
        AGame.Waypoints.Add(LWaypoint);
        LCraft.SetDestination(LWaypoint);
      end;
      FLines.Add(Format('ev|launch|%d|%d|%d', [AVariant, LBase, LCraftIndex]));
    end;
end;

procedure TTestXcomTimeScenario.Prepare(const AGame: TXcomSavedGame; AVariant: Integer);
var
  LUfo, LMission: Integer;
begin
  FStage := 'clock';
  SetClock(AGame);
  // the UFOs that the first saved games have with no mission and no trajectory cannot fly: removed
  LUfo := 0;
  while LUfo < AGame.Ufos.Count do
    if (AGame.Ufos[LUfo].Mission = nil) or (AGame.Ufos[LUfo].Trajectory = nil) then
      AGame.Ufos.Delete(LUfo)
    else
      Inc(LUfo);
  // the missions of the saved game have a region chosen at random: the ones that lack a zone stop, with their UFOs
  for LMission := 0 to AGame.ActiveMissions.Count - 1 do
  begin
    if FSim.RegionOk(AGame.ActiveMissions[LMission].Rule, FSim.Ruleset.Regions.Find(AGame.ActiveMissions[LMission].Region)) then
      Continue;
    AGame.ActiveMissions[LMission].NextWave := Cardinal(AGame.ActiveMissions[LMission].Rule.WaveCount);
    LUfo := 0;
    while LUfo < AGame.Ufos.Count do
      if AGame.Ufos[LUfo].Mission = AGame.ActiveMissions[LMission] then
        AGame.Ufos.Delete(LUfo)
      else
        Inc(LUfo);
  end;
  FStage := 'missions';
  CreateMissions(AGame);
  FStage := 'launch';
  LaunchCrafts(AGame, AVariant);
end;

procedure TTestXcomTimeScenario.RunDays(const AGame: TXcomSavedGame; const ASimulation: TXcomGeoscapeSimulation;
  AVariant, ADays: Integer);
var
  LTick, LDay, LUfo: Integer;
begin
  LDay := 0;
  for LTick := 0 to ADays * 24 * 720 - 1 do
  begin
    if LTick < 3 then
      FStage := Format('tick %d (%s)', [LTick, ASimulation.Stage]);
    ASimulation.Tick;
    if LTick < 3 then
      FStage := 'tick ok';
    if LTick mod (24 * 720) = 24 * 720 - 1 then
    begin
      Inc(LDay);
      FLines.Add(Format('day|%d|%d|ufos=%d|sites=%d|bases=%d|missions=%d|waypoints=%d|funds=%d', [AVariant, LDay,
        AGame.Ufos.Count, AGame.MissionSites.Count, AGame.AlienBases.Count, AGame.ActiveMissions.Count,
        AGame.Waypoints.Count, AGame.Funds]));
    end;
  end;
  for LUfo := 0 to AGame.Ufos.Count - 1 do
    FLines.Add(Format('ufo|%d|0|0|%d|final|status=%d|tp=%s|lon=%s|lat=%s|alt=%s|secs=%s|land=%d|det=%d|speed=%d|dest=%d',
      [AVariant, LUfo, AGame.Ufos[LUfo].Status, UIntToStr(AGame.Ufos[LUfo].TrajectoryPoint),
      string(TYamlConvert.FormatGeneral(AGame.Ufos[LUfo].Longitude, 17)),
      string(TYamlConvert.FormatGeneral(AGame.Ufos[LUfo].Latitude, 17)), AGame.Ufos[LUfo].Altitude,
      UIntToStr(AGame.Ufos[LUfo].SecondsRemaining), AGame.Ufos[LUfo].LandId, Ord(AGame.Ufos[LUfo].Detected),
      AGame.Ufos[LUfo].Speed, Ord(AGame.Ufos[LUfo].Destination <> nil)]));
end;

procedure TTestXcomTimeScenario.RunScenario(const AGame: TXcomSavedGame; const ASimulation: TXcomGeoscapeSimulation;
  AVariant: Integer; AMonths: Boolean);
var
  LMonth: Integer;
begin
  Prepare(AGame, AVariant);
  if not AMonths then
  begin
    RunDays(AGame, ASimulation, AVariant, 20);
    Exit;
  end;
  // the month, then ten days of time; eight times
  for LMonth := 0 to 7 do
  begin
    ASimulation.Time1Month;
    FLines.Add(Format('month|%d|%d|missions=%d|funds=%d|months=%d', [AVariant, LMonth, AGame.ActiveMissions.Count,
      AGame.Funds, AGame.MonthsPassed]));
    SetClock(AGame);
    RunDays(AGame, ASimulation, AVariant, 10);
  end;
end;

procedure TTestXcomTimeScenario.Compare(const AScenario: string; AMonths: Boolean);
var
  LFolder, LLast: string;
  LVariant: Integer;
  LGame: TXcomSavedGame;
  LSimulation: TXcomGeoscapeSimulation;
  LEvents: IXcomGeoscapeEvents;
  LHolder: IInterface;
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
      LEvents := TXcomRecordingEvents.Create(LGame, FLines);
      LSimulation := TXcomStrategyFactory.CreateSimulation(LGame, FSim.Ruleset, FSim.Rules, FRandom, nil, LEvents,
        TXcomDefaultStrategySettings.Create, FSim.Settings);
      LHolder := LSimulation;
      try
        FRandom.SetSeed(5000 + LVariant);
        try
          RunScenario(LGame, LSimulation, LVariant, AMonths);
        except
          on E: Exception do
          begin
            FLines.SaveToFile(ExtractFilePath(ParamStr(0)) + 'time_fail.txt');
            if FLines.Count > 0 then
              LLast := FLines[FLines.Count - 1]
            else
              LLast := '-';
            raise Exception.CreateFmt('%s: %s (variant %d, stage %s, after: %s)', [E.ClassName, E.Message, LVariant,
              FStage + '/' + LSimulation.Stage, LLast]);
          end;
        end;
        FLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        Assert.AreEqual('', TXcomSim.FirstDifferenceTolerant(string(TXcomSim.GoldenText(LFolder +
          Format('sim%.2d.%s.txt', [LVariant, AScenario]))), FLines.Text, POSITION_TOLERANCE),
          Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.CompareSaveTolerant(LFolder + Format('sim%.2d.%s.sav', [LVariant, AScenario]),
          FSim.SaveText(LGame, FRandom), POSITION_TOLERANCE), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LHolder := nil;
        LEvents := nil;
        LGame.Free;
      end;
    end;
  finally
    FLines.Free;
  end;
end;

procedure TTestXcomTimeScenario.DovrebbeFareVentiGiorniComeIlCodiceDiGeoscapeStateSuiVeriOggetti;
begin
  Compare('time', False);
end;

procedure TTestXcomTimeScenario.DovrebbeFareTreMesiComeIlCodiceDiGeoscapeStateSuiVeriOggetti;
begin
  Compare('month', True);
end;
initialization
  TDUnitX.RegisterTestFixture(TTestXcomTimeScenario);

end.
