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
  DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.NullEvents, DelphiDoom.XcomGeoscape.Control.Intf,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf;

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
    FLauncher: IXcomMissionLauncher;
    procedure Show(AState: TXcomState);
    function Attached: Boolean;
  public
    /// <param name="AHost">The game that runs the states (not owned)</param>
    /// <param name="ALauncher">What "Yes" of the landing confirmation starts: the battle (the Battlescape's; nil: nothing)</param>
    constructor Create(AHost: TXcomStateHost; const ALauncher: IXcomMissionLauncher = nil);
    property Launcher: IXcomMissionLauncher read FLauncher write FLauncher;
    procedure AttachGeoscape(const AControl: IXcomGeoscapeControl);
    procedure UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean); override;
    procedure UfoLost(const AUfo: TXcomUfo); override;
    procedure MissionDetected(const ASite: TXcomMissionSite); override;
    procedure CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint); override;
    procedure DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo); override;
    procedure DogfightImpossible(const ACraft: TXcomCraft; const AReason: string); override;
    function ActiveDogfights: Integer; override;
    procedure UfoRemoving(const AUfo: TXcomUfo); override;
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
    procedure ResearchCompleted(const ABase: TXcomBase; const AOutcome: TXcomResearchOutcome); override;
    procedure StorageExceeded(const ABase: TXcomBase); override;
    procedure MonthlyReport(APsiTraining: Boolean); override;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.UfoDetectedState, DelphiDoom.XcomGeoscape.UfoLostState,
  DelphiDoom.XcomGeoscape.MissionDetectedState, DelphiDoom.XcomGeoscape.DogfightErrorState,
  DelphiDoom.XcomGeoscape.CraftPatrolState, DelphiDoom.XcomGeoscape.LowFuelState,
  DelphiDoom.XcomGeoscape.CraftErrorState, DelphiDoom.XcomGeoscape.AlienBaseState,
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomGeoscape.GeoscapeCraftState,
  DelphiDoom.XcomGeoscape.ConfirmLandingState,
  DelphiDoom.XcomGeoscape.ItemsArrivingState, DelphiDoom.XcomGeoscape.ProductionCompleteState,
  DelphiDoom.XcomGeoscape.ResearchCompleteState, DelphiDoom.XcomGeoscape.NewPossibleResearchState,
  DelphiDoom.XcomGeoscape.NewPossibleManufactureState, DelphiDoom.XcomGeoscape.ResearchRequiredState,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.MonthlyReportState,
  DelphiDoom.XcomStrategy.MonthlyReport, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleResearch,
  DelphiDoom.XcomMod.RuleItem, System.Generics.Collections, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMenu.OptionsTypes;

{ TXcomPopupGeoscapeEvents }

constructor TXcomPopupGeoscapeEvents.Create(AHost: TXcomStateHost; const ALauncher: IXcomMissionLauncher);
begin
  inherited Create;
  FHost := AHost;
  FLauncher := ALauncher;
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
    Show(FControl.Screens.MakeUfoDetected(AUfo, True, AHyperDetected));
end;

procedure TXcomPopupGeoscapeEvents.UfoLost(const AUfo: TXcomUfo);
begin
  if Attached then
    Show(TXcomUfoLostState.Create(FHost, TXcomTargetNames.Name(AUfo, FHost.Language)));
end;

procedure TXcomPopupGeoscapeEvents.MissionDetected(const ASite: TXcomMissionSite);
begin
  if Attached then
    Show(FControl.Screens.MakeMissionDetected(ASite));
end;

procedure TXcomPopupGeoscapeEvents.CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint);
begin
  if Attached then
    // the state owns the waypoint until an order takes it
    Show(FControl.Screens.MakeGeoscapeCraft(ACraft, AWaypoint))
  else
    inherited CraftNeedsOrders(ACraft, AWaypoint);
end;

procedure TXcomPopupGeoscapeEvents.DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
var
  LControl: IXcomDogfightControl;
begin
  if Attached and Supports(FControl, IXcomDogfightControl, LControl) then
    LControl.StartDogfight(ACraft, AUfo);
end;

function TXcomPopupGeoscapeEvents.ActiveDogfights: Integer;
var
  LControl: IXcomDogfightControl;
begin
  if Attached and Supports(FControl, IXcomDogfightControl, LControl) then
    Result := LControl.DogfightCount
  else
    Result := -1;
end;

procedure TXcomPopupGeoscapeEvents.UfoRemoving(const AUfo: TXcomUfo);
var
  LControl: IXcomDogfightControl;
begin
  if Attached and Supports(FControl, IXcomDogfightControl, LControl) then
    LControl.UfoRemoving(AUfo);
end;

procedure TXcomPopupGeoscapeEvents.DogfightImpossible(const ACraft: TXcomCraft; const AReason: string);
var
  LControl: IXcomDogfightControl;
begin
  if Attached and Supports(FControl, IXcomDogfightControl, LControl) then
    LControl.DogfightImpossible(ACraft, AReason);
  if Attached then
    Show(TXcomDogfightErrorState.Create(FHost, ACraft, TXcomTargetNames.Name(ACraft, FHost.Language),
      FHost.Language.GetString(AReason).Text));
end;

procedure TXcomPopupGeoscapeEvents.CraftPatrolling(const ACraft: TXcomCraft);
begin
  if Attached then
    Show(FControl.Screens.MakeCraftPatrol(ACraft));
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
var
  LTexture, LShade: Integer;
  LGlobe: TXcomGlobe;
begin
  if not Attached then
    Exit;
  // GeoscapeState::handle: the texture of the polygon under the target (a site can ask for its own), the shade there
  LTexture := -1;
  LShade := 0;
  // a control without a globe (the fakes of the tests) has no texture to look up
  LGlobe := FControl.Globe;
  if Assigned(ATarget) and (LGlobe <> nil) then
  begin
    LGlobe.GetPolygonTextureAndShade(ATarget.Longitude, ATarget.Latitude, LTexture, LShade);
    if (ATarget is TXcomMissionSite) and LGlobe.HasTexture(TXcomMissionSite(ATarget).Texture) then
      LTexture := TXcomMissionSite(ATarget).Texture;
    if not LGlobe.HasTexture(LTexture) then
      LTexture := -1;
  end;
  // timerReset first, as the C++ does; the battle itself is the Battlescape's (the launcher)
  FControl.TimerReset;
  if Attached then
    Show(TXcomConfirmLandingState.Create(FHost, ACraft, FLauncher, LTexture, LShade));
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

procedure TXcomPopupGeoscapeEvents.ResearchCompleted(const ABase: TXcomBase; const AOutcome: TXcomResearchOutcome);
var
  LRuleset: TXcomRuleset;
  LNames: TArray<string>;
  LIndex: Integer;
  LPossible: TList<TXcomRuleResearch>;
  LResearch: TXcomRuleResearch;
  LRule: TXcomRuleItem;
begin
  if not Attached then
    Exit;
  LRuleset := TXcomStrategy.Ruleset(FHost);
  // the cutscenes (research and bonus) are not ported
  Show(TXcomResearchCompleteState.Create(FHost, AOutcome.Research.Name, nil));
  FControl.TimerReset;
  if AOutcome.WeaponNeedingAmmo <> '' then
  begin
    LRule := LRuleset.Items.Find(AOutcome.WeaponNeedingAmmo);
    Show(TXcomResearchRequiredState.Create(FHost, LRule.ItemType, LRule.CompatibleAmmo[0]));
  end;
  LPossible := TList<TXcomRuleResearch>.Create;
  try
    for LResearch in AOutcome.NewPossibleResearch do
      LPossible.Add(LResearch);
    Show(TXcomNewPossibleResearchState.Create(FHost, ABase, LPossible, FControl));
  finally
    LPossible.Free;
  end;
  if Length(AOutcome.NewPossibleManufacture) > 0 then
  begin
    SetLength(LNames, Length(AOutcome.NewPossibleManufacture));
    for LIndex := 0 to High(LNames) do
      LNames[LIndex] := AOutcome.NewPossibleManufacture[LIndex].Name;
    Show(TXcomNewPossibleManufactureState.Create(FHost, ABase, LNames, FControl));
  end;
end;

procedure TXcomPopupGeoscapeEvents.MonthlyReport(APsiTraining: Boolean);
var
  LReport: TXcomMonthlyReport;
begin
  if not Attached then
    Exit;
  // the state of the C++ calculates the month when it is made: the funding of the countries changes now, before
  // the next random number of the month is drawn
  LReport := TXcomMonthlyReport.Create(TXcomStrategy.SavedGame(FHost), TXcomStrategy.Ruleset(FHost),
    TXcomStrategy.Random(FHost));
  try
    Show(TXcomMonthlyReportState.Create(FHost, LReport.Calculate));
  finally
    LReport.Free;
  end;
end;

procedure TXcomPopupGeoscapeEvents.StorageExceeded(const ABase: TXcomBase);
begin
  if Attached then
    Show(TXcomErrorMessageState.ForOrigin(FHost, ooGeoscape,
      FHost.Language.GetString('STR_STORAGE_EXCEEDED').Arg(ABase.Name).Text, FControl.Palette));
end;

end.
