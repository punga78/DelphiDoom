{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsGeoscapeState of OpenXcom (geoscape speeds and display)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.OptionsGeoscapeState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Slider, DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.ToggleTextButton,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The geoscape options: drag scroll button, scroll, dogfight and clock speeds, what the globe shows and the
  ///   funds on the screen
  /// </summary>
  TXcomOptionsGeoscapeState = class(TXcomOptionsBaseState)
  strict private
    FTxtDragScroll: TXcomText;
    FCbxDragScroll: TXcomComboBox;
    FTxtScrollSpeed: TXcomText;
    FSlrScrollSpeed: TXcomSlider;
    FTxtDogfightSpeed: TXcomText;
    FSlrDogfightSpeed: TXcomSlider;
    FTxtClockSpeed: TXcomText;
    FSlrClockSpeed: TXcomSlider;
    FTxtGlobeDetails: TXcomText;
    FBtnGlobeCountries: TXcomToggleTextButton;
    FBtnGlobeRadars: TXcomToggleTextButton;
    FBtnGlobePaths: TXcomToggleTextButton;
    FTxtOptions: TXcomText;
    FBtnShowFunds: TXcomToggleTextButton;
    procedure Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
    procedure DragScrollChange(AAction: TXcomAction);
    procedure ScrollSpeedChange(AAction: TXcomAction);
    procedure DogfightSpeedChange(AAction: TXcomAction);
    procedure ClockSpeedChange(AAction: TXcomAction);
    procedure GlobeCountriesClick(AAction: TXcomAction);
    procedure GlobeRadarsClick(AAction: TXcomAction);
    procedure GlobePathsClick(AAction: TXcomAction);
    procedure ShowFundsClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
  end;

implementation

procedure TXcomOptionsGeoscapeState.Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
begin
  ASurface.Tooltip := ATooltip;
  ASurface.OnMouseIn(TooltipIn);
  ASurface.OnMouseOut(TooltipOut);
end;

constructor TXcomOptionsGeoscapeState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LOptions: TXcomOptions;
begin
  inherited Create(AHost, AOrigin, ANavigator);
  LOptions := Host.Options;
  SetCategory(FBtnGeoscape);
  FTxtDragScroll := TXcomText.Create(114, 9, 206, 8);
  FCbxDragScroll := TXcomComboBox.Create(Self, 104, 16, 206, 18);
  FTxtScrollSpeed := TXcomText.Create(114, 9, 94, 8);
  FSlrScrollSpeed := TXcomSlider.Create(104, 16, 94, 18);
  FTxtDogfightSpeed := TXcomText.Create(114, 9, 206, 40);
  FSlrDogfightSpeed := TXcomSlider.Create(104, 16, 206, 50);
  FTxtClockSpeed := TXcomText.Create(114, 9, 94, 40);
  FSlrClockSpeed := TXcomSlider.Create(104, 16, 94, 50);
  FTxtGlobeDetails := TXcomText.Create(114, 9, 94, 82);
  FBtnGlobeCountries := TXcomToggleTextButton.Create(104, 16, 94, 92);
  FBtnGlobeRadars := TXcomToggleTextButton.Create(104, 16, 94, 110);
  FBtnGlobePaths := TXcomToggleTextButton.Create(104, 16, 94, 128);
  FTxtOptions := TXcomText.Create(114, 9, 206, 82);
  FBtnShowFunds := TXcomToggleTextButton.Create(104, 16, 206, 92);
  Add(FTxtScrollSpeed, 'text', 'geoscapeMenu');
  Add(FSlrScrollSpeed, 'button', 'geoscapeMenu');
  Add(FTxtDogfightSpeed, 'text', 'geoscapeMenu');
  Add(FSlrDogfightSpeed, 'button', 'geoscapeMenu');
  Add(FTxtClockSpeed, 'text', 'geoscapeMenu');
  Add(FSlrClockSpeed, 'button', 'geoscapeMenu');
  Add(FTxtGlobeDetails, 'text', 'geoscapeMenu');
  Add(FBtnGlobeCountries, 'button', 'geoscapeMenu');
  Add(FBtnGlobeRadars, 'button', 'geoscapeMenu');
  Add(FBtnGlobePaths, 'button', 'geoscapeMenu');
  Add(FTxtOptions, 'text', 'geoscapeMenu');
  Add(FBtnShowFunds, 'button', 'geoscapeMenu');
  Add(FTxtDragScroll, 'text', 'geoscapeMenu');
  Add(FCbxDragScroll, 'button', 'geoscapeMenu');
  CenterAllSurfaces;
  FTxtDragScroll.SetText(Tr('STR_DRAG_SCROLL'));
  FCbxDragScroll.SetOptions([Tr('STR_DISABLED').Text, Tr('STR_LEFT_MOUSE_BUTTON').Text,
    Tr('STR_MIDDLE_MOUSE_BUTTON').Text, Tr('STR_RIGHT_MOUSE_BUTTON').Text]);
  FCbxDragScroll.SetSelected(LOptions.GetValue('geoDragScrollButton'));
  FCbxDragScroll.OnChange(DragScrollChange);
  Tip(FCbxDragScroll, 'STR_DRAG_SCROLL_DESC');
  FTxtScrollSpeed.SetText(Tr('STR_SCROLL_SPEED'));
  FSlrScrollSpeed.SetRange(100, 10);
  FSlrScrollSpeed.SetValue(LOptions.GetValue('geoScrollSpeed'));
  FSlrScrollSpeed.OnChange(ScrollSpeedChange);
  Tip(FSlrScrollSpeed, 'STR_SCROLL_SPEED_GEO_DESC');
  FTxtDogfightSpeed.SetText(Tr('STR_DOGFIGHT_SPEED'));
  FSlrDogfightSpeed.SetRange(50, 20);
  FSlrDogfightSpeed.SetValue(LOptions.GetValue('dogfightSpeed'));
  FSlrDogfightSpeed.OnChange(DogfightSpeedChange);
  Tip(FSlrDogfightSpeed, 'STR_DOGFIGHT_SPEED_DESC');
  FTxtClockSpeed.SetText(Tr('STR_CLOCK_SPEED'));
  FSlrClockSpeed.SetRange(250, 10);
  FSlrClockSpeed.SetValue(LOptions.GetValue('geoClockSpeed'));
  FSlrClockSpeed.OnChange(ClockSpeedChange);
  Tip(FSlrClockSpeed, 'STR_CLOCK_SPEED_DESC');
  FTxtGlobeDetails.SetText(Tr('STR_GLOBE_DETAILS'));
  FBtnGlobeCountries.SetText(Tr('STR_GLOBE_COUNTRIES'));
  FBtnGlobeCountries.SetPressed(LOptions.GetBool('globeDetail'));
  FBtnGlobeCountries.OnMouseClick(GlobeCountriesClick);
  Tip(FBtnGlobeCountries, 'STR_GLOBE_COUNTRIES_DESC');
  FBtnGlobeRadars.SetText(Tr('STR_GLOBE_RADARS'));
  FBtnGlobeRadars.SetPressed(LOptions.GetBool('globeRadarLines'));
  FBtnGlobeRadars.OnMouseClick(GlobeRadarsClick);
  Tip(FBtnGlobeRadars, 'STR_GLOBE_RADARS_DESC');
  FBtnGlobePaths.SetText(Tr('STR_GLOBE_FLIGHT_PATHS'));
  FBtnGlobePaths.SetPressed(LOptions.GetBool('globeFlightPaths'));
  FBtnGlobePaths.OnMouseClick(GlobePathsClick);
  Tip(FBtnGlobePaths, 'STR_GLOBE_FLIGHT_PATHS_DESC');
  FTxtOptions.SetText(Tr('STR_USER_INTERFACE_OPTIONS'));
  FBtnShowFunds.SetText(Tr('STR_SHOW_FUNDS'));
  FBtnShowFunds.SetPressed(LOptions.GetBool('showFundsOnGeoscape'));
  FBtnShowFunds.OnMouseClick(ShowFundsClick);
  Tip(FBtnShowFunds, 'STR_SHOW_FUNDS_DESC');
end;

procedure TXcomOptionsGeoscapeState.DragScrollChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('geoDragScrollButton', FCbxDragScroll.GetSelected);
end;

procedure TXcomOptionsGeoscapeState.ScrollSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('geoScrollSpeed', FSlrScrollSpeed.GetValue);
end;

procedure TXcomOptionsGeoscapeState.DogfightSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('dogfightSpeed', FSlrDogfightSpeed.GetValue);
end;

procedure TXcomOptionsGeoscapeState.ClockSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('geoClockSpeed', FSlrClockSpeed.GetValue);
end;

procedure TXcomOptionsGeoscapeState.GlobeCountriesClick(AAction: TXcomAction);
begin
  Host.Options.SetBool('globeDetail', FBtnGlobeCountries.GetPressed);
end;

procedure TXcomOptionsGeoscapeState.GlobeRadarsClick(AAction: TXcomAction);
begin
  Host.Options.SetBool('globeRadarLines', FBtnGlobeRadars.GetPressed);
end;

procedure TXcomOptionsGeoscapeState.GlobePathsClick(AAction: TXcomAction);
begin
  Host.Options.SetBool('globeFlightPaths', FBtnGlobePaths.GetPressed);
end;

procedure TXcomOptionsGeoscapeState.ShowFundsClick(AAction: TXcomAction);
begin
  Host.Options.SetBool('showFundsOnGeoscape', FBtnShowFunds.GetPressed);
end;

end.