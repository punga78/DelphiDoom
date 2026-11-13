{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - UfoDetectedState of OpenXcom (a UFO     }
{  came into the range of a radar)                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.UfoDetectedState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   The popup of a UFO that was detected: size, altitude, heading and speed (and, with a hyper-wave decoder, the
  ///   type, race, mission and zone), with the buttons to intercept it, to center the globe on it and to cancel
  /// </summary>
  TXcomUfoDetectedState = class(TXcomState)
  strict private
    FUfo: TXcomUfo;
    FControl: IXcomGeoscapeControl;
    FOnIntercept: TProc<TXcomUfo>;
    FWindow: TXcomWindow;
    FBtnIntercept: TXcomTextButton;
    FBtnCentre: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtUfo: TXcomText;
    FTxtDetected: TXcomText;
    FTxtHyperwave: TXcomText;
    FLstInfo: TXcomTextList;
    FLstInfo2: TXcomTextList;
    procedure InterceptClick(AAction: TXcomAction);
    procedure CentreClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    function Flip(const AText: string): string;
  public
    /// <param name="AUfo">The UFO (not owned; it takes an id here when it has none, as in the C++)</param>
    /// <param name="AOnIntercept">Opens the InterceptState for the UFO (nil: the button does nothing more)</param>
    constructor Create(AHost: TXcomStateHost; AUfo: TXcomUfo; const AControl: IXcomGeoscapeControl; ADetected,
      AHyperwave: Boolean; const AOnIntercept: TProc<TXcomUfo>);
    property Info: TXcomTextList read FLstInfo;
    property Info2: TXcomTextList read FLstInfo2;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.TargetNames,
  DelphiDoom.XcomGeoscape.Funding;

{ TXcomUfoDetectedState }

constructor TXcomUfoDetectedState.Create(AHost: TXcomStateHost; AUfo: TXcomUfo; const AControl: IXcomGeoscapeControl;
  ADetected, AHyperwave: Boolean; const AOnIntercept: TProc<TXcomUfo>);
var
  LSave: TXcomSavedGame;
  LAltitude, LHeading, LCraft: string;
  LUnderwater: Boolean;
begin
  inherited Create(AHost);
  FUfo := AUfo;
  FControl := AControl;
  FOnIntercept := AOnIntercept;
  LSave := TXcomStrategy.SavedGame(AHost);
  if FUfo.Id = 0 then
    FUfo.Id := LSave.GetId('STR_UFO');
  if (FUfo.Altitude = 'STR_GROUND') and (FUfo.LandId = 0) then
    FUfo.LandId := LSave.GetId('STR_LANDING_SITE');
  ToggleScreen;
  if AHyperwave then
    FWindow := TXcomWindow.Create(Self, 224, 180, 16, 10, wpBoth)
  else
    FWindow := TXcomWindow.Create(Self, 224, 128, 16, 44, wpBoth);
  FBtnIntercept := TXcomTextButton.Create(200, 12, 28, 118);
  FBtnCentre := TXcomTextButton.Create(200, 12, 28, 134);
  FBtnCancel := TXcomTextButton.Create(200, 12, 28, 150);
  FTxtUfo := TXcomText.Create(207, 17, 28, 53);
  FTxtDetected := TXcomText.Create(100, 9, 28, 69);
  FTxtHyperwave := TXcomText.Create(214, 17, 21, 44);
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 217, 32, 28, 80);
  FLstInfo2 := TXcomTextList.Create(Host.Options, Host.Clock, 217, 32, 28, 96);
  if AHyperwave then
  begin
    FBtnIntercept.Y := 136;
    FBtnCentre.Y := 152;
    FBtnCancel.Y := 168;
    FTxtUfo.Y := 20;
    FTxtDetected.Y := 36;
    FLstInfo.Y := 60;
  end
  else
  begin
    FTxtHyperwave.Visible := False;
    FLstInfo2.Visible := False;
  end;
  SetInterface('UFOInfo', AHyperwave);
  Add(FWindow, 'window', 'UFOInfo');
  Add(FBtnIntercept, 'button', 'UFOInfo');
  Add(FBtnCentre, 'button', 'UFOInfo');
  Add(FBtnCancel, 'button', 'UFOInfo');
  Add(FTxtUfo, 'text', 'UFOInfo');
  Add(FTxtDetected, 'text', 'UFOInfo');
  Add(FTxtHyperwave, 'text', 'UFOInfo');
  Add(FLstInfo, 'text', 'UFOInfo');
  Add(FLstInfo2, 'text', 'UFOInfo');
  FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
  CenterAllSurfaces;
  FBtnIntercept.SetText(Tr('STR_INTERCEPT'));
  FBtnIntercept.OnMouseClick(InterceptClick);
  FBtnCentre.SetText(Tr('STR_CENTER_ON_UFO_TIME_5_SECONDS'));
  FBtnCentre.OnMouseClick(CentreClick);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  if ADetected then
    FTxtDetected.SetText(Tr('STR_DETECTED'))
  else
    FTxtDetected.SetText('');
  FTxtHyperwave.SetAlign(haCenter);
  FTxtHyperwave.SetWordWrap(True);
  FTxtHyperwave.SetText(Tr('STR_HYPER_WAVE_TRANSMISSIONS_ARE_DECODED'));
  FTxtUfo.SetBig;
  FTxtUfo.SetText(TXcomTargetNames.Name(FUfo, Host.Language));
  FLstInfo.SetColumns([77, 140]);
  FLstInfo.SetDot(True);
  FLstInfo.AddRow([Tr('STR_SIZE_UC').Text, Flip(Tr(FUfo.Rules.Size).Text)]);
  if FUfo.Altitude = 'STR_GROUND' then
    LAltitude := 'STR_GROUNDED'
  else
    LAltitude := FUfo.Altitude;
  // if there is any underwater craft the UFOs are underwater too
  LUnderwater := False;
  for LCraft in TXcomStrategy.Ruleset(AHost).Crafts.Index do
    if TXcomStrategy.Ruleset(AHost).Crafts.Find(LCraft).MaxAltitude > -1 then
    begin
      LUnderwater := True;
      Break;
    end;
  if LUnderwater and not FControl.Globe.InsideLand(FUfo.Longitude, FUfo.Latitude) then
    LAltitude := 'STR_AIRBORNE';
  FLstInfo.AddRow([Tr('STR_ALTITUDE').Text, Flip(Tr(LAltitude).Text)]);
  LHeading := FUfo.Direction;
  if FUfo.Status <> TXcomUfo.STATUS_FLYING then
    LHeading := 'STR_NONE_UC';
  FLstInfo.AddRow([Tr('STR_HEADING').Text, Flip(Tr(LHeading).Text)]);
  FLstInfo.AddRow([Tr('STR_SPEED').Text, Flip(TXcomFunding.FormatNumber(FUfo.Speed, ''))]);
  FLstInfo2.SetColumns([77, 140]);
  FLstInfo2.SetDot(True);
  FLstInfo2.AddRow([Tr('STR_CRAFT_TYPE').Text, Flip(Tr(FUfo.Rules.UfoType).Text)]);
  FLstInfo2.AddRow([Tr('STR_RACE').Text, Flip(Tr(FUfo.AlienRace).Text)]);
  FLstInfo2.AddRow([Tr('STR_MISSION').Text, Flip(Tr(FUfo.MissionType).Text)]);
  FLstInfo2.AddRow([Tr('STR_ZONE').Text, Flip(Tr(FUfo.Mission.Region).Text)]);
end;

function TXcomUfoDetectedState.Flip(const AText: string): string;
begin
  Result := Chr(XCOM_TOKEN_COLOR_FLIP) + AText;
end;

procedure TXcomUfoDetectedState.InterceptClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  FControl.Globe.Center(FUfo.Longitude, FUfo.Latitude);
  if Assigned(FOnIntercept) then
    FOnIntercept(FUfo);
end;

procedure TXcomUfoDetectedState.CentreClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  FControl.Globe.Center(FUfo.Longitude, FUfo.Latitude);
  Host.PopState;
end;

procedure TXcomUfoDetectedState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
