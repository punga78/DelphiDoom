{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - how the screens over the globe lead to   }
{  one another (InterceptState, SelectDestinationState, MultipleTargetsState,   }
{  ConfirmDestinationState, UfoDetectedState, GeoscapeCraftState...)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Screens;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   The `new XState(...)` and `pushState` calls that the states of the geoscape make on one another, in one place:
  ///   each state receives what to do next as a closure, and this class makes them. It does not own the host or the
  ///   control; the states that it creates are owned by the game
  /// </summary>
  TXcomGeoscapeScreens = class(TInterfacedObject, IXcomGeoscapeScreens)
  strict private
    FHost: TXcomStateHost;
    // weak: the control owns these screens
    [weak] FControl: IXcomGeoscapeControl;
  public
    constructor Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl);
    /// <summary>InterceptState (ABase nil: all the crafts; ATarget nil: the target is chosen afterwards)</summary>
    procedure OpenIntercept(ABase: TXcomBase; ATarget: TXcomTarget);
    /// <summary>SelectDestinationState for a craft</summary>
    procedure OpenSelectDestination(ACraft: TXcomCraft);
    /// <summary>ConfirmDestinationState</summary>
    procedure OpenConfirmDestination(ACraft: TXcomCraft; ATarget: TXcomTarget);
    /// <summary>MultipleTargetsState: takes the list (not the targets)</summary>
    procedure OpenMultipleTargets(const ATargets: TList<TXcomTarget>; ACraft: TXcomCraft);
    /// <summary>MultipleTargetsState::popupTarget: the screen of one target (for a craft that is being sent: the confirmation)</summary>
    procedure OpenTarget(ATarget: TXcomTarget; ACraft: TXcomCraft);
    /// <summary>TargetInfoState</summary>
    procedure OpenTargetInfo(ATarget: TXcomTarget);
    /// <summary>UfoDetectedState, not shown yet (the geoscape queues it as a popup)</summary>
    function MakeUfoDetected(AUfo: TXcomUfo; ADetected, AHyperwave: Boolean): TXcomState;
    /// <summary>MissionDetectedState, not shown yet</summary>
    function MakeMissionDetected(ASite: TXcomMissionSite): TXcomState;
    /// <summary>GeoscapeCraftState, not shown yet (it owns the waypoint)</summary>
    function MakeGeoscapeCraft(ACraft: TXcomCraft; AWaypoint: TXcomWaypoint): TXcomState;
    /// <summary>CraftPatrolState, not shown yet</summary>
    function MakeCraftPatrol(ACraft: TXcomCraft): TXcomState;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.InterceptState, DelphiDoom.XcomGeoscape.SelectDestinationState,
  DelphiDoom.XcomGeoscape.ConfirmDestinationState, DelphiDoom.XcomGeoscape.MultipleTargetsState,
  DelphiDoom.XcomGeoscape.TargetInfoState, DelphiDoom.XcomGeoscape.UfoDetectedState,
  DelphiDoom.XcomGeoscape.MissionDetectedState, DelphiDoom.XcomGeoscape.GeoscapeCraftState,
  DelphiDoom.XcomGeoscape.CraftPatrolState, DelphiDoom.XcomGeoscape.ConfirmCydoniaState,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.XcomGeoscape.Strategy;

{ TXcomGeoscapeScreens }

constructor TXcomGeoscapeScreens.Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl);
begin
  inherited Create;
  FHost := AHost;
  FControl := AControl;
end;

procedure TXcomGeoscapeScreens.OpenIntercept(ABase: TXcomBase; ATarget: TXcomTarget);
begin
  FHost.PushState(TXcomInterceptState.Create(FHost, FControl.Globe, ABase, ATarget, FControl,
    procedure(ACraft: TXcomCraft)
    begin
      OpenSelectDestination(ACraft);
    end,
    procedure(ACraft: TXcomCraft; ATargetChosen: TXcomTarget)
    begin
      OpenConfirmDestination(ACraft, ATargetChosen);
    end));
end;

procedure TXcomGeoscapeScreens.OpenSelectDestination(ACraft: TXcomCraft);
begin
  FHost.PushState(TXcomSelectDestinationState.Create(FHost, ACraft, FControl.Globe,
    procedure(ATargets: TList<TXcomTarget>; ACraftToSend: TXcomCraft)
    begin
      OpenMultipleTargets(ATargets, ACraftToSend);
    end,
    procedure(ACraftToSend: TXcomCraft)
    var
      LMission: IXcomMissionControl;
      LLauncher: IXcomMissionLauncher;
    begin
      // SelectDestinationState::btnCydoniaClick: the battle is started by the launcher that the geoscape was given
      LLauncher := nil;
      if Supports(FControl, IXcomMissionControl, LMission) then
        LLauncher := LMission.MissionLauncher;
      FHost.PushState(TXcomConfirmCydoniaState.Create(FHost, ACraftToSend, TXcomStrategy.Ruleset(FHost), LLauncher));
    end));
end;

procedure TXcomGeoscapeScreens.OpenConfirmDestination(ACraft: TXcomCraft; ATarget: TXcomTarget);
begin
  FHost.PushState(TXcomConfirmDestinationState.Create(FHost, ACraft, ATarget));
end;

procedure TXcomGeoscapeScreens.OpenMultipleTargets(const ATargets: TList<TXcomTarget>; ACraft: TXcomCraft);
begin
  FHost.PushState(TXcomMultipleTargetsState.Create(FHost, ATargets,
    procedure(ATarget: TXcomTarget)
    begin
      OpenTarget(ATarget, ACraft);
    end));
end;

procedure TXcomGeoscapeScreens.OpenTarget(ATarget: TXcomTarget; ACraft: TXcomCraft);
begin
  if ACraft <> nil then
    OpenConfirmDestination(ACraft, ATarget)
  else if ATarget is TXcomBase then
    OpenIntercept(TXcomBase(ATarget), nil)
  else if ATarget is TXcomCraft then
    FHost.PushState(MakeGeoscapeCraft(TXcomCraft(ATarget), nil))
  else if ATarget is TXcomUfo then
    FHost.PushState(MakeUfoDetected(TXcomUfo(ATarget), False, TXcomUfo(ATarget).HyperDetected))
  else
    OpenTargetInfo(ATarget);
end;

procedure TXcomGeoscapeScreens.OpenTargetInfo(ATarget: TXcomTarget);
begin
  FHost.PushState(TXcomTargetInfoState.Create(FHost, ATarget,
    procedure(ATargetToIntercept: TXcomTarget)
    begin
      OpenIntercept(nil, ATargetToIntercept);
    end));
end;

function TXcomGeoscapeScreens.MakeUfoDetected(AUfo: TXcomUfo; ADetected, AHyperwave: Boolean): TXcomState;
begin
  Result := TXcomUfoDetectedState.Create(FHost, AUfo, FControl, ADetected, AHyperwave,
    procedure(AUfoToIntercept: TXcomUfo)
    begin
      OpenIntercept(nil, AUfoToIntercept);
    end);
end;

function TXcomGeoscapeScreens.MakeMissionDetected(ASite: TXcomMissionSite): TXcomState;
begin
  Result := TXcomMissionDetectedState.Create(FHost, ASite, FControl,
    procedure(ASiteToIntercept: TXcomMissionSite)
    begin
      OpenIntercept(nil, ASiteToIntercept);
    end);
end;

function TXcomGeoscapeScreens.MakeGeoscapeCraft(ACraft: TXcomCraft; AWaypoint: TXcomWaypoint): TXcomState;
begin
  Result := TXcomGeoscapeCraftState.Create(FHost, ACraft, FControl.Globe, AWaypoint,
    procedure(ACraftToSend: TXcomCraft)
    begin
      OpenSelectDestination(ACraftToSend);
    end);
end;

function TXcomGeoscapeScreens.MakeCraftPatrol(ACraft: TXcomCraft): TXcomState;
begin
  Result := TXcomCraftPatrolState.Create(FHost, ACraft,
    procedure(ACraftToRedirect: TXcomCraft)
    begin
      FHost.PushState(MakeGeoscapeCraft(ACraftToRedirect, nil));
    end);
end;

end.
