{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the strategic game that runs while the  }
{  time of the geoscape goes on (GeoscapeState::time5Seconds ... time1Month)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Simulation;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.GameTime, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomStrategy.Simulation.Intf, DelphiDoom.XcomStrategy.Events.Intf,
  DelphiDoom.XcomStrategy.Settings.Intf, DelphiDoom.XcomStrategy.UfoTracker, DelphiDoom.XcomStrategy.CraftTracker,
  DelphiDoom.XcomStrategy.BaseWork, DelphiDoom.XcomStrategy.AlienPlanner,
  DelphiDoom.XcomStrategy.MissionScriptRunner;

type
  /// <summary>
  ///   The strategic game of the geoscape: what happens at each step of the game time. The steps are called by
  ///   the screen (or by Tick, which does what GeoscapeState::timeAdvance does for one tick of five seconds).
  ///   The collaborators are given and owned by the simulation
  /// </summary>
  TXcomGeoscapeSimulation = class(TInterfacedObject, IXcomGeoscapeSimulation)
  strict private
    FGame: TXcomSavedGame;
    FRandom: IXcomRandom;
    FEvents: IXcomGeoscapeEvents;
    FSettings: IXcomStrategySettings;
    FSaveSettings: IXcomSaveSettings;
    FUfos: TXcomUfoTracker;
    FCrafts: TXcomCraftTracker;
    FBases: TXcomBaseWork;
    FAliens: TXcomAlienPlanner;
    FScripts: TXcomMissionScriptRunner;
    FCapacity: TXcomBaseCapacity;
    FHelpers: TArray<TObject>;
    FStage: string;
    procedure CleanWaypoints;
  public
    /// <param name="AUfos">Owned</param>
    /// <param name="ACrafts">Owned</param>
    /// <param name="ABases">Owned</param>
    /// <param name="AAliens">Owned</param>
    /// <param name="AScripts">Owned</param>
    /// <param name="ACapacity">Owned: the capacities of the bases</param>
    /// <param name="AHelpers">Owned: the objects that the collaborators use (spawners, handlers...), freed last</param>
    constructor Create(const AGame: TXcomSavedGame; const ARandom: IXcomRandom; const AEvents: IXcomGeoscapeEvents;
      const ASettings: IXcomStrategySettings; const ASaveSettings: IXcomSaveSettings; const AUfos: TXcomUfoTracker;
      const ACrafts: TXcomCraftTracker; const ABases: TXcomBaseWork; const AAliens: TXcomAlienPlanner;
      const AScripts: TXcomMissionScriptRunner; const ACapacity: TXcomBaseCapacity;
      const AHelpers: TArray<TObject>);
    destructor Destroy; override;
    /// <summary>
    ///   time5Seconds: UFOs and crafts move; the game is lost when no base is left (GameLost), and a UFO that
    ///   attacks a base ends the step (BaseAttacked: the battle is not ported)
    /// </summary>
    procedure Time5Seconds;
    procedure Time10Minutes;
    procedure Time30Minutes;
    procedure Time1Hour;
    procedure Time1Day;
    procedure Time1Month;
    /// <summary>GeoscapeState::init when the first base has a name: the month, the missions and the maintenance</summary>
    procedure StartFirstMonth;
    /// <summary>
    ///   One tick of five seconds of GeoscapeState::timeAdvance: the game time advances and the steps that it
    ///   triggers run, from the longest to the shortest (a new month also runs the day, the hour, ...)
    /// </summary>
    procedure Tick;
    property Crafts: TXcomCraftTracker read FCrafts;
    property Stage: string read FStage;
  end;

implementation

const
  END_LOSE = 2;

{ TXcomGeoscapeSimulation }

constructor TXcomGeoscapeSimulation.Create(const AGame: TXcomSavedGame; const ARandom: IXcomRandom;
  const AEvents: IXcomGeoscapeEvents; const ASettings: IXcomStrategySettings; const ASaveSettings: IXcomSaveSettings;
  const AUfos: TXcomUfoTracker; const ACrafts: TXcomCraftTracker; const ABases: TXcomBaseWork;
  const AAliens: TXcomAlienPlanner; const AScripts: TXcomMissionScriptRunner; const ACapacity: TXcomBaseCapacity;
  const AHelpers: TArray<TObject>);
begin
  inherited Create;
  FHelpers := AHelpers;
  FGame := AGame;
  FRandom := ARandom;
  FEvents := AEvents;
  FSettings := ASettings;
  FSaveSettings := ASaveSettings;
  FUfos := AUfos;
  FCrafts := ACrafts;
  FBases := ABases;
  FAliens := AAliens;
  FScripts := AScripts;
  FCapacity := ACapacity;
end;

destructor TXcomGeoscapeSimulation.Destroy;
var
  LIndex: Integer;
begin
  FCapacity.Free;
  FScripts.Free;
  FAliens.Free;
  FBases.Free;
  FCrafts.Free;
  FUfos.Free;
  for LIndex := High(FHelpers) downto 0 do
    FHelpers[LIndex].Free;
  inherited Destroy;
end;

procedure TXcomGeoscapeSimulation.CleanWaypoints;
var
  LIndex: Integer;
begin
  LIndex := 0;
  while LIndex < FGame.Waypoints.Count do
    if FGame.Waypoints[LIndex].Followers.Count = 0 then
      FGame.Waypoints.Delete(LIndex)
    else
      Inc(LIndex);
end;

procedure TXcomGeoscapeSimulation.Time5Seconds;
begin
  if FGame.Bases.Count = 0 then
    FGame.EndingKind := END_LOSE;
  if FGame.EndingKind = END_LOSE then
  begin
    FEvents.GameLost;
    Exit;
  end;
  FStage := 'ufos';
  if not FUfos.Move then
    Exit;
  FStage := 'crafts';
  FCrafts.Move;
  FStage := 'remove';
  FUfos.RemoveDestroyed;
  CleanWaypoints;
end;

procedure TXcomGeoscapeSimulation.Time10Minutes;
begin
  FCrafts.BurnFuel;
  FAliens.ScanForBases;
end;

procedure TXcomGeoscapeSimulation.Time30Minutes;
begin
  FAliens.ThinkMissions;
  FUfos.ExpireCrashed;
  FCrafts.Refuel;
  FUfos.ScoreAndDetect;
  FAliens.ProcessSites;
end;

procedure TXcomGeoscapeSimulation.Time1Hour;
begin
  FCrafts.RepairAndRearm;
  FBases.Hourly;
end;

procedure TXcomGeoscapeSimulation.Time1Day;
begin
  FBases.Daily;
  FAliens.Daily;
  if (FGame.Time.Day = 10) or (FGame.Time.Day = 20) then
  begin
    if FGame.Ironman then
      FEvents.AutosaveDue(True)
    else if FSettings.Autosave then
      FEvents.AutosaveDue(False);
  end;
end;

procedure TXcomGeoscapeSimulation.Time1Month;
var
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LPsi: Boolean;
  LAlienBase: TXcomAlienBase;
begin
  FGame.AddMonth;
  FScripts.DetermineAlienMissions;
  LPsi := False;
  if not FSettings.AnytimePsiTraining then
    for LBase in FGame.Bases do
      if FCapacity.AvailablePsiLabs(LBase) > 0 then
      begin
        LPsi := True;
        for LSoldier in LBase.Soldiers do
          if LSoldier.PsiTraining then
            // the stat string of the soldier is not ported
            LSoldier.TrainPsi(FSaveSettings, FRandom);
      end;
  FGame.MonthlyFunding(Integer(FCapacity.BaseMaintenance(FGame)));
  FEvents.MonthlyReport(LPsi);
  if (FGame.AlienBases.Count > 0) and (FRandom.Generate(0, 99) < 20) then
    for LAlienBase in FGame.AlienBases do
      if not LAlienBase.Discovered then
      begin
        LAlienBase.Discovered := True;
        FEvents.AlienBaseDiscovered(LAlienBase);
        Break;
      end;
end;

procedure TXcomGeoscapeSimulation.StartFirstMonth;
begin
  FGame.AddMonth;
  FScripts.DetermineAlienMissions;
  FGame.SetFunds(FGame.Funds - (FCapacity.BaseMaintenance(FGame) -
    FCapacity.PersonnelMaintenance(FGame.Bases.First)));
end;

procedure TXcomGeoscapeSimulation.Tick;
var
  LTrigger: TXcomTimeTrigger;
begin
  LTrigger := FGame.Time.Advance;
  // the C++ switch falls through: the longest step first, then every shorter one
  if LTrigger >= ttMonth then
    Time1Month;
  if LTrigger >= ttDay then
    Time1Day;
  if LTrigger >= ttHour then
    Time1Hour;
  if LTrigger >= ttThirtyMinutes then
    Time30Minutes;
  if LTrigger >= ttTenMinutes then
    Time10Minutes;
  Time5Seconds;
end;

end.
