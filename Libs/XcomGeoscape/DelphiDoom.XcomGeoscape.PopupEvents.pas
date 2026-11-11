{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - the popups of GeoscapeState (the events  }
{  of the strategic simulation shown as the states of OpenXcom)                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.PopupEvents;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.MissionSite,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.NullEvents, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   What GeoscapeState does with the things that the simulation reports: it creates the popup of each one (as the
  ///   C++ does when it notices the event) and gives it to the geoscape, which shows it and stops the time. Before a
  ///   geoscape is attached (AttachGeoscape) the events go nowhere
  /// </summary>
  TXcomPopupGeoscapeEvents = class(TXcomNullGeoscapeEvents, IXcomGeoscapeAware)
  strict private
    FHost: TXcomStateHost;
    FControl: IXcomGeoscapeControl;
    FOnBeginMission: TProc<TXcomCraft>;
    procedure Show(AState: TXcomState);
    function Attached: Boolean;
  public
    /// <param name="AHost">The game that runs the states (not owned)</param>
    constructor Create(AHost: TXcomStateHost);
    /// <summary>What "Yes" of the landing confirmation does: starts the battle (the Battlescape's; nil: nothing)</summary>
    property OnBeginMission: TProc<TXcomCraft> read FOnBeginMission write FOnBeginMission;
    procedure AttachGeoscape(const AControl: IXcomGeoscapeControl);
    procedure UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean); override;
    procedure UfoLost(const AUfo: TXcomUfo); override;
    procedure MissionDetected(const ASite: TXcomMissionSite); override;
    procedure CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint); override;
    procedure DogfightImpossible(const ACraft: TXcomCraft; const AReason: string); override;
    procedure CraftPatrolling(const ACraft: TXcomCraft); override;
    procedure LowFuel(const ACraft: TXcomCraft); override;
    procedure CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft; const AItem: string;
      ARearming: Boolean); override;
    procedure AlienBaseDiscovered(const ABase: TXcomAlienBase); override;
    procedure LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget); override;
    procedure ItemsArriving; override;
    procedure ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
      AProgress: TXcomProductionProgress); override;
    procedure FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility); override;
    procedure ResearchFinished(const ABase: TXcomBase; const AResearchName: string); override;
    procedure StorageExceeded(const ABase: TXcomBase); override;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.UfoDetectedState, DelphiDoom.XcomGeoscape.UfoLostState,
  DelphiDoom.XcomGeoscape.MissionDetectedState, DelphiDoom.XcomGeoscape.DogfightErrorState,
  DelphiDoom.XcomGeoscape.CraftPatrolState, DelphiDoom.XcomGeoscape.LowFuelState,
  DelphiDoom.XcomGeoscape.CraftErrorState, DelphiDoom.XcomGeoscape.AlienBaseState,
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomGeoscape.GeoscapeCraftState,
  DelphiDoom.XcomGeoscape.ConfirmLandingState,
  DelphiDoom.XcomGeoscape.ItemsArrivingState, DelphiDoom.XcomGeoscape.ProductionCompleteState,
  DelphiDoom.XcomGeoscape.ResearchCompleteState, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMenu.OptionsTypes;

{ TXcomPopupGeoscapeEvents }

constructor TXcomPopupGeoscapeEvents.Create(AHost: TXcomStateHost);
begin
  inherited Create;
  FHost := AHost;
end;

procedure TXcomPopupGeoscapeEvents.AttachGeoscape(const AControl: IXcomGeoscapeControl);
begin
  FControl := AControl;
end;

function TXcomPopupGeoscapeEvents.Attached: Boolean;
begin
  Result := FControl <> nil;
end;

procedure TXcomPopupGeoscapeEvents.Show(AState: TXcomState);
begin
  FControl.Popup(AState);
end;

procedure TXcomPopupGeoscapeEvents.UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean);
begin
  if Attached then
    Show(TXcomUfoDetectedState.Create(FHost, AUfo, FControl, True, AHyperDetected, nil));
end;

procedure TXcomPopupGeoscapeEvents.UfoLost(const AUfo: TXcomUfo);
begin
  if Attached then
    Show(TXcomUfoLostState.Create(FHost, TXcomTargetNames.Name(AUfo, FHost.Language)));
end;

procedure TXcomPopupGeoscapeEvents.MissionDetected(const ASite: TXcomMissionSite);
begin
  if Attached then
    Show(TXcomMissionDetectedState.Create(FHost, ASite, FControl, nil));
end;

procedure TXcomPopupGeoscapeEvents.CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint);
begin
  if Attached then
    // the state owns the waypoint until an order takes it
    Show(TXcomGeoscapeCraftState.Create(FHost, ACraft, FControl.Globe, AWaypoint, nil))
  else
    inherited CraftNeedsOrders(ACraft, AWaypoint);
end;

procedure TXcomPopupGeoscapeEvents.DogfightImpossible(const ACraft: TXcomCraft; const AReason: string);
begin
  if Attached then
    Show(TXcomDogfightErrorState.Create(FHost, ACraft, TXcomTargetNames.Name(ACraft, FHost.Language),
      FHost.Language.GetString(AReason).Text));
end;

procedure TXcomPopupGeoscapeEvents.CraftPatrolling(const ACraft: TXcomCraft);
begin
  if Attached then
    Show(TXcomCraftPatrolState.Create(FHost, ACraft, nil));
end;

procedure TXcomPopupGeoscapeEvents.LowFuel(const ACraft: TXcomCraft);
begin
  if Attached then
    Show(TXcomLowFuelState.Create(FHost, TXcomTargetNames.Name(ACraft, FHost.Language), FControl));
end;

procedure TXcomPopupGeoscapeEvents.CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft;
  const AItem: string; ARearming: Boolean);
var
  LKey: string;
begin
  if not Attached then
    Exit;
  if ARearming then
    LKey := 'STR_NOT_ENOUGH_ITEM_TO_REARM_CRAFT_AT_BASE'
  else
    LKey := 'STR_NOT_ENOUGH_ITEM_TO_REFUEL_CRAFT_AT_BASE';
  Show(TXcomCraftErrorState.Create(FHost, FControl, FHost.Language.GetString(LKey)
    .Arg(FHost.Language.GetString(AItem).Text).Arg(TXcomTargetNames.Name(ACraft, FHost.Language)).Arg(ABase.Name).Text));
end;

procedure TXcomPopupGeoscapeEvents.AlienBaseDiscovered(const ABase: TXcomAlienBase);
begin
  if Attached then
    Show(TXcomAlienBaseState.Create(FHost, ABase, FControl));
end;

procedure TXcomPopupGeoscapeEvents.LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget);
begin
  if Attached then
    // timerReset first, as the C++ does; the battle itself is the Battlescape's (FOnBeginMission)
    FControl.TimerReset;
  if Attached then
    Show(TXcomConfirmLandingState.Create(FHost, ACraft, FOnBeginMission));
end;

procedure TXcomPopupGeoscapeEvents.ItemsArriving;
begin
  if Attached then
    Show(TXcomItemsArrivingState.Create(FHost, FControl));
end;

procedure TXcomPopupGeoscapeEvents.ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
  AProgress: TXcomProductionProgress);
const
  ENDS: array[TXcomProductionProgress] of TXcomProductionEnd = (peComplete, peComplete, peNotEnoughMoney,
    peNotEnoughMaterials);
begin
  if Attached then
    Show(TXcomProductionCompleteState.Create(FHost, ABase, FHost.Language.GetString(AProductionName).Text, FControl,
      ENDS[AProgress]));
end;

procedure TXcomPopupGeoscapeEvents.FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility);
begin
  if Attached then
    Show(TXcomProductionCompleteState.Create(FHost, ABase,
      FHost.Language.GetString(AFacility.Rules.FacilityType).Text, FControl, peConstruction));
end;

procedure TXcomPopupGeoscapeEvents.ResearchFinished(const ABase: TXcomBase; const AResearchName: string);
begin
  if Attached then
    Show(TXcomResearchCompleteState.Create(FHost, AResearchName, nil));
end;

procedure TXcomPopupGeoscapeEvents.StorageExceeded(const ABase: TXcomBase);
begin
  if Attached then
    Show(TXcomErrorMessageState.ForOrigin(FHost, ooGeoscape,
      FHost.Language.GetString('STR_STORAGE_EXCEEDED').Arg(ABase.Name).Text, FControl.Palette));
end;

end.
