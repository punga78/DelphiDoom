{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ConfirmLandingState of OpenXcom (a craft }
{  is ready to land near its destination)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ConfirmLandingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomGeoscape.MissionLauncher.Intf;

type
  /// <summary>"Craft ready to land near Target. Begin mission?": Yes starts the mission, No sends the craft home</summary>
  TXcomConfirmLandingState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FLauncher: IXcomMissionLauncher;
    FTexture: Integer;
    FShade: Integer;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtMessage: TXcomText;
    FTxtBegin: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    /// <param name="ACraft">The craft, with a destination (not owned)</param>
    /// <param name="ALauncher">Starts the battle (the Battlescape is not part of this library; nil: nothing)</param>
    /// <param name="ATexture">The texture id of the landing site (-1 none)</param>
    /// <param name="AShade">The shade of the landing site (0..15)</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; const ALauncher: IXcomMissionLauncher;
      ATexture: Integer = -1; AShade: Integer = 0);
    /// <summary>What "Yes" of ConfirmLandingState::btnYesClick gives to the launcher; EXcomGeoscapeException with no mission</summary>
    function Request: TXcomMissionRequest;
    /// <summary>ConfirmLandingState::init: a craft that goes back to its own base has nothing to confirm</summary>
    procedure Init; override;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Target;

resourcestring
  SNoMissionAvailable = 'No mission available!';

{ TXcomConfirmLandingState }

constructor TXcomConfirmLandingState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft;
  const ALauncher: IXcomMissionLauncher; ATexture: Integer; AShade: Integer);
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FLauncher := ALauncher;
  FTexture := ATexture;
  FShade := AShade;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 216, 160, 20, 20, wpBoth);
  FBtnYes := TXcomTextButton.Create(80, 20, 40, 150);
  FBtnNo := TXcomTextButton.Create(80, 20, 136, 150);
  FTxtMessage := TXcomText.Create(206, 80, 25, 40);
  FTxtBegin := TXcomText.Create(206, 17, 25, 130);
  SetInterface('confirmLanding');
  Add(FWindow, 'window', 'confirmLanding');
  Add(FBtnYes, 'button', 'confirmLanding');
  Add(FBtnNo, 'button', 'confirmLanding');
  Add(FTxtMessage, 'text', 'confirmLanding');
  Add(FTxtBegin, 'text', 'confirmLanding');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnYes.OnKeyboardPress(YesClick, Host.Options.KeyOk);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FBtnNo.OnKeyboardPress(NoClick, Host.Options.KeyCancel);
  FTxtMessage.SetBig;
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(Tr('STR_CRAFT_READY_TO_LAND_NEAR_DESTINATION')
    .Arg(TXcomTargetNames.Name(ACraft, Host.Language))
    .Arg(TXcomTargetNames.Name(ACraft.Destination, Host.Language)));
  FTxtBegin.SetBig;
  FTxtBegin.SetAlign(haCenter);
  FTxtBegin.SetText(Chr(XCOM_TOKEN_COLOR_FLIP) + Tr('STR_BEGIN_MISSION').Text);
end;

procedure TXcomConfirmLandingState.Init;
begin
  inherited Init;
  if FCraft.Destination = FCraft.Base then
    Host.PopState;
end;

procedure TXcomConfirmLandingState.YesClick(AAction: TXcomAction);
var
  LRequest: TXcomMissionRequest;
begin
  Host.PopState;
  LRequest := Request;
  if Assigned(FLauncher) then
    FLauncher.BeginMission(LRequest);
end;

function TXcomConfirmLandingState.Request: TXcomMissionRequest;
begin
  Result := Default(TXcomMissionRequest);
  Result.Craft := FCraft;
  Result.WorldTexture := FTexture;
  Result.WorldShade := FShade;
  if FCraft.Destination is TXcomUfo then
  begin
    Result.Ufo := TXcomUfo(FCraft.Destination);
    if Result.Ufo.Status = TXcomUfo.STATUS_CRASHED then
      Result.MissionType := 'STR_UFO_CRASH_RECOVERY'
    else
      Result.MissionType := 'STR_UFO_GROUND_ASSAULT';
    // a UFO of a saved game always has its mission; one made by hand may not
    if Assigned(Result.Ufo.Mission) then
      Result.AlienRace := Result.Ufo.AlienRace;
  end
  else if FCraft.Destination is TXcomMissionSite then
  begin
    Result.Site := TXcomMissionSite(FCraft.Destination);
    Result.MissionType := Result.Site.Deployment.DeploymentType;
    Result.AlienRace := Result.Site.AlienRace;
  end
  else if FCraft.Destination is TXcomAlienBase then
  begin
    Result.AlienBase := TXcomAlienBase(FCraft.Destination);
    Result.MissionType := Result.AlienBase.Deployment.DeploymentType;
    Result.AlienRace := Result.AlienBase.AlienRace;
    Result.WorldTexture := -1;
  end
  else
    raise EXcomGeoscapeException.Create(SNoMissionAvailable);
end;

procedure TXcomConfirmLandingState.NoClick(AAction: TXcomAction);
begin
  FCraft.ReturnToBase;
  Host.PopState;
end;

end.
