{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the assembly of the simulation of the   }
{  geoscape (the one place that knows the concrete classes)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Factory;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomGeoscape.Simulation.Intf, DelphiDoom.XcomStrategy.Events.Intf, DelphiDoom.XcomStrategy.Settings.Intf,
  DelphiDoom.XcomStrategy.LandMap.Intf, DelphiDoom.XcomStrategy.PolygonLandMap, DelphiDoom.XcomStrategy.UfoSpawner,
  DelphiDoom.XcomStrategy.MissionSites, DelphiDoom.XcomStrategy.MissionThinker,
  DelphiDoom.XcomStrategy.UfoWaypointHandler, DelphiDoom.XcomStrategy.BaseRadar, DelphiDoom.XcomStrategy.UfoTracker,
  DelphiDoom.XcomStrategy.CraftTracker, DelphiDoom.XcomStrategy.BaseWork, DelphiDoom.XcomStrategy.AlienPlanner,
  DelphiDoom.XcomStrategy.MissionScriptRunner, DelphiDoom.XcomStrategy.Simulation;

type
  /// <summary>Builds the simulation of the geoscape on a saved game, with all that it needs</summary>
  TXcomStrategyFactory = class
  public
    /// <summary>
    ///   The simulation of the strategic game of AGame. The land checks come from the polygons of the globe of
    ///   the ruleset when ALand is nil. ARules nil: the simulation makes (and owns) its own adapters of the rules.
    ///   The saved game, ruleset and rules are borrowed: they must outlive it
    /// </summary>
    class function CreateSimulation(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
      const ARules: TXcomRulesetRules; const ARandom: IXcomRandom; const ALand: IXcomLandMap;
      const AEvents: IXcomGeoscapeEvents; const ASettings: IXcomStrategySettings;
      const ASaveSettings: IXcomSaveSettings; AResearchCascade: Boolean = False): TXcomGeoscapeSimulation; static;
  end;

implementation

{ TXcomStrategyFactory }

class function TXcomStrategyFactory.CreateSimulation(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const ARules: TXcomRulesetRules; const ARandom: IXcomRandom; const ALand: IXcomLandMap;
  const AEvents: IXcomGeoscapeEvents; const ASettings: IXcomStrategySettings;
  const ASaveSettings: IXcomSaveSettings; AResearchCascade: Boolean): TXcomGeoscapeSimulation;
var
  LLand: IXcomLandMap;
  LSpawner: TXcomUfoSpawner;
  LSites: TXcomMissionSites;
  LThinker: TXcomMissionThinker;
  LHandler: TXcomUfoWaypointHandler;
  LRadar: TXcomBaseRadar;
  LUfos: TXcomUfoTracker;
  LCrafts: TXcomCraftTracker;
  LBases: TXcomBaseWork;
  LAliens: TXcomAlienPlanner;
  LScripts: TXcomMissionScriptRunner;
  LCapacity: TXcomBaseCapacity;
  LRules: TXcomRulesetRules;
  LHelpers: TArray<TObject>;
begin
  LLand := ALand;
  LRules := ARules;
  if not Assigned(LRules) then
    LRules := TXcomRulesetRules.Create(ARuleset);
  if not Assigned(LLand) then
    LLand := TXcomPolygonLandMap.Create(ARuleset.Globe);
  // the spawner, sites, thinker, handler and radar are used by the trackers: the simulation owns them too
  LSpawner := TXcomUfoSpawner.Create(ARuleset, LLand, ARandom);
  LSites := TXcomMissionSites.Create(ARuleset, LRules, ARandom);
  LThinker := TXcomMissionThinker.Create(ARuleset, LLand, ARandom, LSpawner, LSites);
  LHandler := TXcomUfoWaypointHandler.Create(ARuleset, LLand, LSpawner, LSites);
  LRadar := TXcomBaseRadar.Create(ARuleset, ARandom);
  LUfos := TXcomUfoTracker.Create(AGame, ARandom, LHandler, LRadar, AEvents);
  LCrafts := TXcomCraftTracker.Create(AGame, ARuleset, ARandom, LLand, AEvents);
  LBases := TXcomBaseWork.Create(AGame, ARuleset, ARandom, AEvents, ASettings, ASaveSettings);
  if AResearchCascade then
    LBases.EnableResearchCascade;
  LAliens := TXcomAlienPlanner.Create(AGame, ARuleset, ARandom, LThinker, ASettings);
  LScripts := TXcomMissionScriptRunner.Create(AGame, ARuleset, ARandom);
  LCapacity := TXcomBaseCapacity.Create(ARuleset);
  LHelpers := TArray<TObject>.Create(LSpawner, LSites, LThinker, LHandler, LRadar);
  if LRules <> ARules then
    LHelpers := LHelpers + [LRules];
  Result := TXcomGeoscapeSimulation.Create(AGame, ARandom, AEvents, ASettings, ASaveSettings, LUfos, LCrafts, LBases,
    LAliens, LScripts, LCapacity, LHelpers);
end;

end.
