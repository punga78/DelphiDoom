{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - MissionDetectedState of OpenXcom (a      }
{  mission site appeared on the globe)                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.MissionDetectedState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>The alert of a mission site (terror site...): intercept, center on it, cancel</summary>
  TXcomMissionDetectedState = class(TXcomState)
  strict private
    FSite: TXcomMissionSite;
    FControl: IXcomGeoscapeControl;
    FOnIntercept: TProc<TXcomMissionSite>;
    FWindow: TXcomWindow;
    FBtnIntercept: TXcomTextButton;
    FBtnCenter: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtCity: TXcomText;
    procedure InterceptClick(AAction: TXcomAction);
    procedure CenterClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    /// <param name="ASite">The site (not owned)</param>
    /// <param name="AOnIntercept">Opens the InterceptState for the site (nil: nothing more)</param>
    constructor Create(AHost: TXcomStateHost; ASite: TXcomMissionSite; const AControl: IXcomGeoscapeControl;
      const AOnIntercept: TProc<TXcomMissionSite>);
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.AlienDeployment;

{ TXcomMissionDetectedState }

constructor TXcomMissionDetectedState.Create(AHost: TXcomStateHost; ASite: TXcomMissionSite;
  const AControl: IXcomGeoscapeControl; const AOnIntercept: TProc<TXcomMissionSite>);
var
  LDeployment: TXcomAlienDeployment;
begin
  inherited Create(AHost);
  FSite := ASite;
  FControl := AControl;
  FOnIntercept := AOnIntercept;
  LDeployment := TXcomStrategy.Ruleset(AHost).AlienDeployments.Find(ASite.Deployment.DeploymentType);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 200, 0, 0, wpBoth);
  FBtnIntercept := TXcomTextButton.Create(200, 16, 28, 130);
  FBtnCenter := TXcomTextButton.Create(200, 16, 28, 150);
  FBtnCancel := TXcomTextButton.Create(200, 16, 28, 170);
  FTxtTitle := TXcomText.Create(246, 32, 5, 48);
  FTxtCity := TXcomText.Create(246, 17, 5, 80);
  SetInterface('terrorSite');
  Add(FWindow, 'window', 'terrorSite');
  Add(FBtnIntercept, 'button', 'terrorSite');
  Add(FBtnCenter, 'button', 'terrorSite');
  Add(FBtnCancel, 'button', 'terrorSite');
  Add(FTxtTitle, 'text', 'terrorSite');
  Add(FTxtCity, 'text', 'terrorSite');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface(LDeployment.AlertBackground));
  FBtnIntercept.SetText(Tr('STR_INTERCEPT'));
  FBtnIntercept.OnMouseClick(InterceptClick);
  FBtnCenter.SetText(Tr('STR_CENTER_ON_SITE_TIME_5_SECONDS'));
  FBtnCenter.OnMouseClick(CenterClick);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr(LDeployment.Alert));
  FTxtCity.SetBig;
  FTxtCity.SetAlign(haCenter);
  FTxtCity.SetText(Tr(ASite.City));
end;

procedure TXcomMissionDetectedState.InterceptClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  FControl.Globe.Center(FSite.Longitude, FSite.Latitude);
  if Assigned(FOnIntercept) then
    FOnIntercept(FSite);
end;

procedure TXcomMissionDetectedState.CenterClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  FControl.Globe.Center(FSite.Longitude, FSite.Latitude);
  Host.PopState;
end;

procedure TXcomMissionDetectedState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
