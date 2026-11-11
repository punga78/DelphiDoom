{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what the geoscape tells the screen      }
{  (the popups that GeoscapeState opens while the time goes on)                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Events.Intf;

interface

uses
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Waypoint,
  DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.Production, DelphiDoom.XcomSave.ResearchProject,
  DelphiDoom.XcomStrategy.Types;

type
  /// <summary>
  ///   The things the strategic simulation reports to the screen: each one is a popup that GeoscapeState opens in
  ///   the C++ (UfoDetectedState, MissionDetectedState, LowFuelState...). The logic does not open them: the screen
  ///   implements this; the tests implement it to record what happened. Objects given are borrowed, except where
  ///   a method says it takes ownership
  /// </summary>
  IXcomGeoscapeEvents = interface
    ['{6F2B4C1D-9A3E-4B75-8D10-176000000102}']
    /// <summary>The last base is gone (GeoscapeState pushes the lost game cutscene)</summary>
    procedure GameLost;
    /// <summary>UfoDetectedState: a UFO came into the radar range (AHyperDetected: by a hyper-wave decoder)</summary>
    procedure UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean);
    /// <summary>UfoLostState: a UFO that was followed went out of the range, or landed unseen</summary>
    procedure UfoLost(const AUfo: TXcomUfo);
    /// <summary>MissionDetectedState: a mission site shows on the globe</summary>
    procedure MissionDetected(const ASite: TXcomMissionSite);
    /// <summary>BaseDefenseState / handleBaseDefense: a UFO reached a base (the battle is not ported)</summary>
    procedure BaseAttacked(const ABase: TXcomBase; const AUfo: TXcomUfo);
    /// <summary>
    ///   GeoscapeCraftState: the UFO that a craft follows is not seen any more; the craft has no destination.
    ///   The waypoint is at the last position of the UFO and is given to the receiver, which frees it or adds
    ///   it to the game
    /// </summary>
    procedure CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint);
    /// <summary>DogfightState: a craft reached a flying UFO that it can engage</summary>
    procedure DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
    /// <summary>DogfightErrorState: the craft cannot engage (AReason: STR_UNABLE_TO_ENGAGE_DEPTH or _AIRBORNE)</summary>
    procedure DogfightImpossible(const ACraft: TXcomCraft; const AReason: string);
    /// <summary>ConfirmLandingState: a craft with soldiers reached a UFO on the ground, a site or an alien base</summary>
    procedure LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget);
    /// <summary>CraftPatrolState: a craft reached its waypoint</summary>
    procedure CraftPatrolling(const ACraft: TXcomCraft);
    /// <summary>LowFuelState</summary>
    procedure LowFuel(const ACraft: TXcomCraft);
    /// <summary>CraftErrorState: the storage of the base lacks the item to rearm or refuel the craft</summary>
    procedure CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft; const AItem: string; ARearming: Boolean);
    /// <summary>ItemsArrivingState: a transfer arrived</summary>
    procedure ItemsArriving;
    /// <summary>ProductionCompleteState: a production ended (AProgress tells why) and was taken off the base</summary>
    procedure ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
      AProgress: TXcomProductionProgress);
    /// <summary>ProductionCompleteState with PROGRESS_CONSTRUCTION: a facility was built</summary>
    procedure FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility);
    /// <summary>ResearchCompleteState: a project was finished and taken off the base</summary>
    procedure ResearchFinished(const ABase: TXcomBase; const AResearchName: string);
    /// <summary>The storage of the base is over its capacity (ErrorMessageState and SellState)</summary>
    procedure StorageExceeded(const ABase: TXcomBase);
    /// <summary>AlienBaseState: an alien base was discovered</summary>
    procedure AlienBaseDiscovered(const ABase: TXcomAlienBase);
    /// <summary>SaveGameState: the automatic save of the days 10 and 20 (AIronman: the ironman save)</summary>
    procedure AutosaveDue(AIronman: Boolean);
    /// <summary>MonthlyReportState</summary>
    procedure MonthlyReport(APsiTraining: Boolean);
  end;

implementation

end.
