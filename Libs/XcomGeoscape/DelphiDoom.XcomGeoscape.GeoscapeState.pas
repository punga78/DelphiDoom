{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - GeoscapeState of OpenXcom (the main     }
{  screen of the strategy game: the globe, the side bar, the clock)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GeoscapeState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomGeoscape.Globe,
  DelphiDoom.XcomGeoscape.Simulation.Intf, DelphiDoom.XcomGeoscape.Navigator.Intf,
  DelphiDoom.Xcom.Types, DelphiDoom.XcomGeoscape.Control.Intf, DelphiDoom.XcomGeoscape.Screens, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Base, DelphiDoom.XcomBasescape.Navigator.Intf,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomGeoscape.DogfightState;

type
  /// <summary>
  ///   The geoscape: the globe, the sidebar with the buttons and the clock (hour, minutes, seconds, weekday, day,
  ///   month, year) and the time speeds. The game clock advances the date of the saved game; what happens as the time
  ///   goes on is the simulation that is given. The screens that the buttons open come from the navigator. Not ported:
  ///   the dogfights, the zoom effects and the pop-ups of the events (they come with their screens), the click on
  ///   the targets of the globe, the debug mode and the quick save
  /// </summary>
  TXcomGeoscapeState = class(TXcomState)
  strict private
    FSave: TXcomSavedGame;
    FRules: IXcomGameRules;
    FSimulation: IXcomGeoscapeSimulation;
    FNavigator: IXcomGeoscapeNavigator;
    FBackground: TXcomWidget;
    FSideLine: TXcomWidget;
    FSidebar: TXcomWidget;
    FGlobe: TXcomGlobe;
    FBtnIntercept: TXcomTextButton;
    FBtnBases: TXcomTextButton;
    FBtnGraphs: TXcomTextButton;
    FBtnUfopaedia: TXcomTextButton;
    FBtnOptions: TXcomTextButton;
    FBtnFunding: TXcomTextButton;
    FBtn5Secs: TXcomTextButton;
    FBtn1Min: TXcomTextButton;
    FBtn5Mins: TXcomTextButton;
    FBtn30Mins: TXcomTextButton;
    FBtn1Hour: TXcomTextButton;
    FBtn1Day: TXcomTextButton;
    FBtnRotateLeft: TXcomInteractiveSurface;
    FBtnRotateRight: TXcomInteractiveSurface;
    FBtnRotateUp: TXcomInteractiveSurface;
    FBtnRotateDown: TXcomInteractiveSurface;
    FBtnZoomIn: TXcomInteractiveSurface;
    FBtnZoomOut: TXcomInteractiveSurface;
    FSideTop: TXcomTextButton;
    FSideBottom: TXcomTextButton;
    FTxtHour: TXcomText;
    FTxtHourSep: TXcomText;
    FTxtMin: TXcomText;
    FTxtMinSep: TXcomText;
    FTxtSec: TXcomText;
    FTxtWeekday: TXcomText;
    FTxtDay: TXcomText;
    FTxtMonth: TXcomText;
    FTxtYear: TXcomText;
    FTxtFunds: TXcomText;
    FTimeSpeed: TXcomButtonGroup;
    FGameTimer: TXcomTimer;
    FPause: Boolean;
    FPopups: TList<TXcomState>;
    FControl: IXcomGeoscapeControl;
    FDogfights: TObjectList<TXcomDogfightState>;
    FDogfightsToStart: TObjectList<TXcomDogfightState>;
    FDogfightTimer: TXcomTimer;
    FDogfightStartTimer: TXcomTimer;
    FMinimizedDogfights: Integer;
    FZoomOld: Integer;
    procedure HandleDogfights;
    procedure StartDogfightNow;
    function FirstFreeDogfightSlot: Integer;
    function MinimizedDogfightsCount: Integer;
    procedure ConfigureButton(AButton: TXcomTextButton; const AText: string; ABig: Boolean; AKey: Integer;
      const AHandler: TXcomActionHandler);
    procedure ConfigureTimeButton(AButton: TXcomTextButton; const AText: string; AKey: Integer);
    procedure ConfigureHold(ASurface: TXcomInteractiveSurface; AKey: Integer; const APress,
      ARelease: TXcomActionHandler);
    procedure TimeAdvance;
    procedure GlobeClick(AAction: TXcomAction);
  public
    /// <param name="ASimulation">What runs with the time; nil: the date advances and nothing else happens</param>
    /// <param name="ANavigator">The screens of the buttons; nil: the buttons do nothing</param>
    constructor Create(AHost: TXcomStateHost; const ASimulation: IXcomGeoscapeSimulation;
      const ANavigator: IXcomGeoscapeNavigator);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    /// <summary>GeoscapeState::blit: the dogfights are drawn over the globe</summary>
    procedure Blit; override;
    /// <summary>GeoscapeState::handle: the dogfights get the events too (the geoscape only when all are minimized)</summary>
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>
    ///   A craft reached a UFO it can engage: a DogfightState is made, the time stops and the globe centers on the craft.
    ///   Declared difference: the zoom in and out effects are not ported, the globe goes to the dogfight zoom at once
    /// </summary>
    procedure StartDogfight(ACraft: TXcomCraft; AUfo: TXcomUfo);
    /// <summary>The dogfight of the craft waits minimized (the craft cannot engage yet)</summary>
    procedure DogfightImpossible(ACraft: TXcomCraft; const AReason: string);
    function DogfightCount: Integer;
    /// <summary>The dogfights with the UFO end (it is about to be deleted)</summary>
    procedure UfoRemoving(AUfo: TXcomUfo);
    /// <summary>GeoscapeState::timeDisplay: the clock of the side bar</summary>
    procedure TimeDisplay;
    /// <summary>GeoscapeState::popup: the state is shown when the geoscape thinks next, and stops the time</summary>
    procedure Popup(AState: TXcomState);
    /// <summary>GeoscapeState::timerReset: the clock goes back to 5 seconds</summary>
    procedure TimerReset;
    /// <summary>The basescape of a base, through the navigator (nothing without one)</summary>
    procedure OpenBase(ABase: TXcomBase);
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    procedure PlaceLift(ABase: TXcomBase; AFirst: Boolean);
    property Globe: TXcomGlobe read FGlobe;
    /// <summary>What the popups ask of this geoscape (valid while the geoscape lives)</summary>
    property Control: IXcomGeoscapeControl read FControl;
    /// <summary>The states that wait to be shown (popups of the events)</summary>
    function PendingPopups: Integer;
    /// <summary>True while the time is stopped for a popup</summary>
    function Paused: Boolean;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSave.GameTime,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomGeoscape.Keys, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.SaveGameState, DelphiDoom.XcomMenu.LoadGameState, DelphiDoom.XcomMenu.SaveNames;

const
  GEO_CLOCK_SPEED = 80;
  SIDEBAR_WIDTH = 64;
  ORIGINAL_HEIGHT = 200;

type
  /// <summary>The geoscape as the popups see it; it does not keep the geoscape alive and is cleared by its destructor</summary>
  TXcomGeoscapeControl = class(TInterfacedObject, IXcomGeoscapeControl, IXcomDogfightControl, IXcomMissionControl)
  strict private
    FState: TXcomGeoscapeState;
    FScreens: IXcomGeoscapeScreens;
    FLauncher: IXcomMissionLauncher;
  public
    constructor Create(AState: TXcomGeoscapeState);
    function Screens: IXcomGeoscapeScreens;
    procedure Detach;
    procedure TimerReset;
    function Globe: TXcomGlobe;
    procedure Popup(AState: TXcomState);
    procedure OpenBase(ABase: TXcomBase);
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    procedure PlaceLift(ABase: TXcomBase; AFirst: Boolean);
    function Palette: PXcomColors;
    procedure StartDogfight(ACraft: TXcomCraft; AUfo: TXcomUfo);
    procedure DogfightImpossible(ACraft: TXcomCraft; const AReason: string);
    function DogfightCount: Integer;
    procedure UfoRemoving(AUfo: TXcomUfo);
    procedure SetMissionLauncher(const ALauncher: IXcomMissionLauncher);
    function MissionLauncher: IXcomMissionLauncher;
  end;

{ TXcomGeoscapeControl }

procedure TXcomGeoscapeControl.SetMissionLauncher(const ALauncher: IXcomMissionLauncher);
begin
  FLauncher := ALauncher;
end;

function TXcomGeoscapeControl.MissionLauncher: IXcomMissionLauncher;
begin
  Result := FLauncher;
end;

procedure TXcomGeoscapeControl.StartDogfight(ACraft: TXcomCraft; AUfo: TXcomUfo);
begin
  if Assigned(FState) then
    FState.StartDogfight(ACraft, AUfo);
end;

procedure TXcomGeoscapeControl.DogfightImpossible(ACraft: TXcomCraft; const AReason: string);
begin
  if Assigned(FState) then
    FState.DogfightImpossible(ACraft, AReason);
end;

function TXcomGeoscapeControl.DogfightCount: Integer;
begin
  if Assigned(FState) then
    Result := FState.DogfightCount
  else
    Result := 0;
end;

procedure TXcomGeoscapeControl.UfoRemoving(AUfo: TXcomUfo);
begin
  if Assigned(FState) then
    FState.UfoRemoving(AUfo);
end;

function TXcomGeoscapeControl.Screens: IXcomGeoscapeScreens;
begin
  if (FScreens = nil) and Assigned(FState) then
    FScreens := TXcomGeoscapeScreens.Create(FState.Host, Self);
  Result := FScreens;
end;

procedure TXcomGeoscapeControl.PlaceLift(ABase: TXcomBase; AFirst: Boolean);
begin
  if Assigned(FState) then
    FState.PlaceLift(ABase, AFirst);
end;

function TXcomGeoscapeControl.Palette: PXcomColors;
begin
  if Assigned(FState) then
    Result := FState.Palette
  else
    Result := nil;
end;

procedure TXcomGeoscapeControl.OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
begin
  if Assigned(FState) then
    FState.OpenBaseScreen(AScreen, ABase);
end;

constructor TXcomGeoscapeControl.Create(AState: TXcomGeoscapeState);
begin
  inherited Create;
  FState := AState;
end;

procedure TXcomGeoscapeControl.Detach;
begin
  FState := nil;
  FScreens := nil;
  FLauncher := nil;
end;

procedure TXcomGeoscapeControl.TimerReset;
begin
  if Assigned(FState) then
    FState.TimerReset;
end;

function TXcomGeoscapeControl.Globe: TXcomGlobe;
begin
  if Assigned(FState) then
    Result := FState.Globe
  else
    Result := nil;
end;

procedure TXcomGeoscapeControl.Popup(AState: TXcomState);
begin
  if Assigned(FState) then
    FState.Popup(AState)
  else
    AState.Free;
end;

procedure TXcomGeoscapeControl.OpenBase(ABase: TXcomBase);
begin
  if Assigned(FState) then
    FState.OpenBase(ABase);
end;

{ TXcomGeoscapeState }

constructor TXcomGeoscapeState.Create(AHost: TXcomStateHost; const ASimulation: IXcomGeoscapeSimulation;
  const ANavigator: IXcomGeoscapeNavigator);
var
  LScreenWidth, LScreenHeight, LHeight: Integer;
  LAlt, LGeoBorder: TXcomSurface;
  LAware: IXcomGeoscapeAware;
begin
  inherited Create(AHost);
  FSimulation := ASimulation;
  FNavigator := ANavigator;
  FPopups := TList<TXcomState>.Create;
  FControl := TXcomGeoscapeControl.Create(Self);
  if Supports(FSimulation, IXcomGeoscapeAware, LAware) then
    LAware.AttachGeoscape(FControl);
  if Supports(FNavigator, IXcomGeoscapeAware, LAware) then
    LAware.AttachGeoscape(FControl);
  FSave := TXcomStrategy.SavedGame(AHost);
  FRules := TXcomStrategy.Rules(AHost);
  LScreenWidth := Host.Options.BaseXGeoscape;
  LScreenHeight := Host.Options.BaseYGeoscape;
  LAlt := Host.Resources.GetSurface('ALTGEOBORD.SCR');
  FBackground := TXcomWidget.Create(LAlt.Width, LAlt.Height, 0, 0);
  FSideLine := TXcomWidget.Create(SIDEBAR_WIDTH, LScreenHeight, LScreenWidth - SIDEBAR_WIDTH, 0);
  FSidebar := TXcomWidget.Create(SIDEBAR_WIDTH, 200, LScreenWidth - SIDEBAR_WIDTH, LScreenHeight div 2 - 100);
  FGlobe := TXcomGlobe.Create(Host, FSave, FRules.Ruleset, FRules.GetSurfaceSet('TEXTURE.DAT'),
    FRules.GetSurfaceSet('GlobeMarkers'), (LScreenWidth - SIDEBAR_WIDTH) div 2, LScreenHeight div 2,
    LScreenWidth - SIDEBAR_WIDTH, LScreenHeight, 0, 0);
  FBackground.X := (FGlobe.Width - FBackground.Width) div 2;
  FBackground.Y := (FGlobe.Height - FBackground.Height) div 2;
  FTimeSpeed := TXcomButtonGroup.Create;
  FGameTimer := TXcomTimer.Create(Host.Clock, GEO_CLOCK_SPEED);
  FZoomOld := -1;
  FDogfights := TObjectList<TXcomDogfightState>.Create(True);
  FDogfightsToStart := TObjectList<TXcomDogfightState>.Create(False);
  FDogfightTimer := TXcomTimer.Create(Host.Clock, Host.Options.GetValue('dogfightSpeed'));
  FDogfightStartTimer := TXcomTimer.Create(Host.Clock, Host.Options.GetValue('dogfightSpeed'));
  FBtnIntercept := TXcomTextButton.Create(63, 11, LScreenWidth - 63, LScreenHeight div 2 - 100);
  FBtnBases := TXcomTextButton.Create(63, 11, LScreenWidth - 63, LScreenHeight div 2 - 88);
  FBtnGraphs := TXcomTextButton.Create(63, 11, LScreenWidth - 63, LScreenHeight div 2 - 76);
  FBtnUfopaedia := TXcomTextButton.Create(63, 11, LScreenWidth - 63, LScreenHeight div 2 - 64);
  FBtnOptions := TXcomTextButton.Create(63, 11, LScreenWidth - 63, LScreenHeight div 2 - 52);
  FBtnFunding := TXcomTextButton.Create(63, 11, LScreenWidth - 63, LScreenHeight div 2 - 40);
  FBtn5Secs := TXcomTextButton.Create(31, 13, LScreenWidth - 63, LScreenHeight div 2 + 12);
  FBtn1Min := TXcomTextButton.Create(31, 13, LScreenWidth - 31, LScreenHeight div 2 + 12);
  FBtn5Mins := TXcomTextButton.Create(31, 13, LScreenWidth - 63, LScreenHeight div 2 + 26);
  FBtn30Mins := TXcomTextButton.Create(31, 13, LScreenWidth - 31, LScreenHeight div 2 + 26);
  FBtn1Hour := TXcomTextButton.Create(31, 13, LScreenWidth - 63, LScreenHeight div 2 + 40);
  FBtn1Day := TXcomTextButton.Create(31, 13, LScreenWidth - 31, LScreenHeight div 2 + 40);
  FBtnRotateLeft := TXcomInteractiveSurface.Create(12, 10, LScreenWidth - 61, LScreenHeight div 2 + 76);
  FBtnRotateRight := TXcomInteractiveSurface.Create(12, 10, LScreenWidth - 37, LScreenHeight div 2 + 76);
  FBtnRotateUp := TXcomInteractiveSurface.Create(13, 12, LScreenWidth - 49, LScreenHeight div 2 + 62);
  FBtnRotateDown := TXcomInteractiveSurface.Create(13, 12, LScreenWidth - 49, LScreenHeight div 2 + 87);
  FBtnZoomIn := TXcomInteractiveSurface.Create(23, 23, LScreenWidth - 25, LScreenHeight div 2 + 56);
  FBtnZoomOut := TXcomInteractiveSurface.Create(13, 17, LScreenWidth - 20, LScreenHeight div 2 + 82);
  LHeight := (LScreenHeight - ORIGINAL_HEIGHT) div 2 + 10;
  FSideTop := TXcomTextButton.Create(63, LHeight, LScreenWidth - 63, FSidebar.Y - LHeight - 1);
  FSideBottom := TXcomTextButton.Create(63, LHeight, LScreenWidth - 63, FSidebar.Y + FSidebar.Height + 1);
  FTxtHour := TXcomText.Create(20, 16, LScreenWidth - 61, LScreenHeight div 2 - 26);
  FTxtHourSep := TXcomText.Create(4, 16, LScreenWidth - 41, LScreenHeight div 2 - 26);
  FTxtMin := TXcomText.Create(20, 16, LScreenWidth - 37, LScreenHeight div 2 - 26);
  FTxtMinSep := TXcomText.Create(4, 16, LScreenWidth - 17, LScreenHeight div 2 - 26);
  FTxtSec := TXcomText.Create(11, 8, LScreenWidth - 13, LScreenHeight div 2 - 20);
  FTxtWeekday := TXcomText.Create(59, 8, LScreenWidth - 61, LScreenHeight div 2 - 13);
  FTxtDay := TXcomText.Create(29, 8, LScreenWidth - 61, LScreenHeight div 2 - 6);
  FTxtMonth := TXcomText.Create(29, 8, LScreenWidth - 32, LScreenHeight div 2 - 6);
  FTxtYear := TXcomText.Create(59, 8, LScreenWidth - 61, LScreenHeight div 2 + 1);
  FTxtFunds := TXcomText.Create(59, 8, LScreenWidth - 61, LScreenHeight div 2 - 27);
  FTimeSpeed.Selected := FBtn5Secs;

  SetInterface('geoscape');
  Add(FBackground);
  Add(FSideLine);
  Add(FSidebar);
  Add(FGlobe);
  Add(FBtnIntercept, 'button', 'geoscape');
  Add(FBtnBases, 'button', 'geoscape');
  Add(FBtnGraphs, 'button', 'geoscape');
  Add(FBtnUfopaedia, 'button', 'geoscape');
  Add(FBtnOptions, 'button', 'geoscape');
  Add(FBtnFunding, 'button', 'geoscape');
  Add(FBtn5Secs, 'button', 'geoscape');
  Add(FBtn1Min, 'button', 'geoscape');
  Add(FBtn5Mins, 'button', 'geoscape');
  Add(FBtn30Mins, 'button', 'geoscape');
  Add(FBtn1Hour, 'button', 'geoscape');
  Add(FBtn1Day, 'button', 'geoscape');
  Add(FBtnRotateLeft);
  Add(FBtnRotateRight);
  Add(FBtnRotateUp);
  Add(FBtnRotateDown);
  Add(FBtnZoomIn);
  Add(FBtnZoomOut);
  Add(FSideTop, 'button', 'geoscape');
  Add(FSideBottom, 'button', 'geoscape');
  Add(FTxtFunds, 'text', 'geoscape');
  Add(FTxtHour, 'text', 'geoscape');
  Add(FTxtHourSep, 'text', 'geoscape');
  Add(FTxtMin, 'text', 'geoscape');
  Add(FTxtMinSep, 'text', 'geoscape');
  Add(FTxtSec, 'text', 'geoscape');
  Add(FTxtWeekday, 'text', 'geoscape');
  Add(FTxtDay, 'text', 'geoscape');
  Add(FTxtMonth, 'text', 'geoscape');
  Add(FTxtYear, 'text', 'geoscape');

  LGeoBorder := Host.Resources.GetSurface('GEOBORD.SCR');
  LGeoBorder.X := FSidebar.X - LGeoBorder.Width + FSidebar.Width;
  LGeoBorder.Y := FSidebar.Y;
  FSidebar.Copy(LGeoBorder);
  LAlt.Blit(FBackground);
  FSideLine.DrawRect(0, 0, FSideLine.Width, FSideLine.Height, 15);

  ConfigureButton(FBtnIntercept, 'STR_INTERCEPT', False, KEY_GEO_INTERCEPT,
    procedure(AAction: TXcomAction)
    begin
      FControl.Screens.OpenIntercept(nil, nil);
    end);
  ConfigureButton(FBtnBases, 'STR_BASES', False, KEY_GEO_BASES,
    procedure(AAction: TXcomAction)
    begin
      if Assigned(FNavigator) then
        FNavigator.OpenBases(FGlobe);
    end);
  ConfigureButton(FBtnGraphs, 'STR_GRAPHS', False, KEY_GEO_GRAPHS,
    procedure(AAction: TXcomAction)
    begin
      if Assigned(FNavigator) then
        FNavigator.OpenGraphs;
    end);
  ConfigureButton(FBtnUfopaedia, 'STR_UFOPAEDIA_UC', False, KEY_GEO_UFOPAEDIA,
    procedure(AAction: TXcomAction)
    begin
      if Assigned(FNavigator) then
        FNavigator.OpenUfopaedia;
    end);
  ConfigureButton(FBtnOptions, 'STR_OPTIONS_UC', False, KEY_GEO_OPTIONS,
    procedure(AAction: TXcomAction)
    begin
      if Assigned(FNavigator) then
        FNavigator.OpenOptions;
    end);
  ConfigureButton(FBtnFunding, 'STR_FUNDING_UC', False, KEY_GEO_FUNDING,
    procedure(AAction: TXcomAction)
    begin
      if Assigned(FNavigator) then
        FNavigator.OpenFunding;
    end);
  ConfigureTimeButton(FBtn5Secs, 'STR_5_SECONDS', KEY_GEO_SPEED_1);
  ConfigureTimeButton(FBtn1Min, 'STR_1_MINUTE', KEY_GEO_SPEED_2);
  ConfigureTimeButton(FBtn5Mins, 'STR_5_MINUTES', KEY_GEO_SPEED_3);
  ConfigureTimeButton(FBtn30Mins, 'STR_30_MINUTES', KEY_GEO_SPEED_4);
  ConfigureTimeButton(FBtn1Hour, 'STR_1_HOUR', KEY_GEO_SPEED_5);
  ConfigureTimeButton(FBtn1Day, 'STR_1_DAY', KEY_GEO_SPEED_6);
  FSideBottom.SetGeoscapeButton(True);
  FSideTop.SetGeoscapeButton(True);

  ConfigureHold(FBtnRotateLeft, KEY_GEO_LEFT,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateLeft;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLon;
    end);
  ConfigureHold(FBtnRotateRight, KEY_GEO_RIGHT,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateRight;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLon;
    end);
  ConfigureHold(FBtnRotateUp, KEY_GEO_UP,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateUp;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLat;
    end);
  ConfigureHold(FBtnRotateDown, KEY_GEO_DOWN,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateDown;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLat;
    end);
  FBtnZoomIn.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomIn;
    end, XCOM_BUTTON_LEFT);
  FBtnZoomIn.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomMax;
    end, XCOM_BUTTON_RIGHT);
  FBtnZoomIn.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomIn;
    end, KEY_GEO_ZOOM_IN);
  FBtnZoomOut.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomOut;
    end, XCOM_BUTTON_LEFT);
  FBtnZoomOut.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomMin;
    end, XCOM_BUTTON_RIGHT);
  FBtnZoomOut.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomOut;
    end, KEY_GEO_ZOOM_OUT);

  // showFundsOnGeoscape is off by default
  FTxtFunds.Visible := False;
  FTxtFunds.SetAlign(haCenter);
  FTxtHour.SetBig;
  FTxtHour.SetAlign(haRight);
  FTxtHourSep.SetBig;
  FTxtHourSep.SetText(':');
  FTxtMin.SetBig;
  FTxtMinSep.SetBig;
  FTxtMinSep.SetText(':');
  FTxtWeekday.SetAlign(haCenter);
  FTxtDay.SetAlign(haCenter);
  FTxtMonth.SetAlign(haCenter);
  FTxtYear.SetAlign(haCenter);

  FGameTimer.OnTimerState(TimeAdvance);
  FGameTimer.Start;
  FDogfightStartTimer.OnTimerState(StartDogfightNow);
  FDogfightTimer.OnTimerState(HandleDogfights);
  TimeDisplay;
end;

destructor TXcomGeoscapeState.Destroy;
var
  LState: TXcomState;
begin
  // the dogfights use the crafts and the UFOs of the saved game, which outlives the states
  FDogfights.Free;
  FDogfightsToStart.Free;
  FDogfightTimer.Free;
  FDogfightStartTimer.Free;
  // the popups that were never shown are still ours
  for LState in FPopups do
    LState.Free;
  FPopups.Clear;
  (FControl as TXcomGeoscapeControl).Detach;
  FControl := nil;
  inherited Destroy;
  FPopups.Free;
  FGameTimer.Free;
  FTimeSpeed.Free;
end;

procedure TXcomGeoscapeState.ConfigureButton(AButton: TXcomTextButton; const AText: string; ABig: Boolean;
  AKey: Integer; const AHandler: TXcomActionHandler);
begin
  AButton.InitText(Host.Resources.GetFont('FONT_GEO_BIG'), Host.Resources.GetFont('FONT_GEO_SMALL'), Host.Language);
  if ABig then
    AButton.SetBig;
  AButton.SetText(Tr(AText));
  if Assigned(AHandler) then
  begin
    AButton.OnMouseClick(AHandler);
    AButton.OnKeyboardPress(AHandler, AKey);
  end;
  AButton.SetGeoscapeButton(True);
end;

procedure TXcomGeoscapeState.ConfigureTimeButton(AButton: TXcomTextButton; const AText: string; AKey: Integer);
begin
  ConfigureButton(AButton, AText, True, AKey, nil);
  AButton.SetGroup(FTimeSpeed);
  // btnTimerClick: the key does what a press of the mouse on the button does
  AButton.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    var
      LOld: TXcomTextButton;
    begin
      LOld := FTimeSpeed.Selected;
      FTimeSpeed.Selected := AButton;
      if Assigned(LOld) then
        LOld.Invalidate;
      AButton.Invalidate;
    end, AKey);
end;

procedure TXcomGeoscapeState.ConfigureHold(ASurface: TXcomInteractiveSurface; AKey: Integer; const APress,
  ARelease: TXcomActionHandler);
begin
  ASurface.OnMousePress(APress);
  ASurface.OnMouseRelease(ARelease);
  ASurface.OnKeyboardPress(APress, AKey);
  ASurface.OnKeyboardRelease(ARelease, AKey);
  ASurface.SetListButton;
end;

procedure TXcomGeoscapeState.Init;
begin
  inherited Init;
  TimeDisplay;
  // the options screen of the pause menu may have changed it
  FGlobe.FlightPaths := Host.Options.GetBool('globeFlightPaths');
  // the screens that borrow the globe set their handlers on it: they are replaced by the ones of the geoscape
  FGlobe.OnMouseClick(GlobeClick);
  FGlobe.OnMouseOver(nil);
  FGlobe.RotateStop;
  FGlobe.SetFocus(True);
  FGlobe.Draw;
  FGlobe.SetNewBaseHover(False);
  // the first month starts when the first base has its name
  if (FSave.MonthsPassed = -1) and (FSave.Bases.Count > 0) and (FSave.Bases.First.Name <> '') then
  begin
    // addMonth, determineAlienMissions and the funds: the simulation does the three (it adds the month itself)
    if Assigned(FSimulation) then
      FSimulation.StartFirstMonth
    else
      FSave.AddMonth;
  end;
end;

procedure TXcomGeoscapeState.GlobeClick(AAction: TXcomAction);
var
  LTargets: TList<TXcomTarget>;
begin
  // clicking the markers of the globe (the right click scrolls it: the globe does it)
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    LTargets := FGlobe.GetTargets(Floor(AAction.AbsoluteXMouse), Floor(AAction.AbsoluteYMouse), False);
    if LTargets.Count > 0 then
      FControl.Screens.OpenMultipleTargets(LTargets, nil)
    else
      LTargets.Free;
  end;
end;

procedure TXcomGeoscapeState.Think;
begin
  inherited Think;
  FDogfightStartTimer.Think(True, False);
  if (FPopups.Count = 0) and (FDogfights.Count = 0) then
    FGameTimer.Think(True, False)
  else
  begin
    if (FDogfights.Count > 0) or (FMinimizedDogfights <> 0) then
    begin
      // if all the dogfights are minimized the globe rotates and the time goes on
      if FDogfights.Count = FMinimizedDogfights then
      begin
        FPause := False;
        FGameTimer.Think(True, False);
      end;
      FDogfightTimer.Think(True, False);
    end;
    if FPopups.Count > 0 then
    begin
      FGlobe.RotateStop;
      Host.PushState(FPopups.First);
      FPopups.Delete(0);
    end;
  end;
end;

procedure TXcomGeoscapeState.Blit;
var
  LDogfight: TXcomDogfightState;
begin
  inherited Blit;
  for LDogfight in FDogfights do
    LDogfight.Blit;
end;

procedure TXcomGeoscapeState.Handle(AAction: TXcomAction);
var
  LDogfight: TXcomDogfightState;
begin
  if FDogfights.Count = FMinimizedDogfights then
    inherited Handle(AAction);
  // GeoscapeState::handle: quick save and quick load (not in an ironman game), as popups
  if (AAction.Details.Kind = ekKeyDown) and not FSave.Ironman then
  begin
    if AAction.Details.Key = Host.Options.GetValue('keyQuickSave') then
      Popup(TXcomSaveGameState.Create(Host, ooGeoscape, stQuick, Palette))
    else if AAction.Details.Key = Host.Options.GetValue('keyQuickLoad') then
      Popup(TXcomLoadGameState.Create(Host, ooGeoscape, TXcomSaveNames.QUICKSAVE, Palette));
  end;
  if FDogfights.Count > 0 then
  begin
    for LDogfight in FDogfights.ToArray do
      LDogfight.Handle(AAction);
    FMinimizedDogfights := MinimizedDogfightsCount;
  end;
end;

function TXcomGeoscapeState.MinimizedDogfightsCount: Integer;
var
  LDogfight: TXcomDogfightState;
begin
  Result := 0;
  for LDogfight in FDogfights do
    if LDogfight.Engine.Minimized then
      Inc(Result);
end;

function TXcomGeoscapeState.FirstFreeDogfightSlot: Integer;
var
  LDogfight: TXcomDogfightState;
begin
  Result := 1;
  for LDogfight in FDogfights do
    if LDogfight.Engine.InterceptionNumber = Result then
      Inc(Result);
end;

procedure TXcomGeoscapeState.StartDogfightNow;
var
  LDogfight: TXcomDogfightState;
begin
  // startDogfight without the zoom effect: the globe goes to the dogfight zoom
  if FGlobe.Zoom < 3 then
  begin
    if FZoomOld < 0 then
      FZoomOld := FGlobe.Zoom;
    FGlobe.SetZoom(3);
  end;
  FDogfightStartTimer.Stop;
  FDogfightTimer.Start;
  TimerReset;
  while FDogfightsToStart.Count > 0 do
  begin
    LDogfight := FDogfightsToStart.Last;
    FDogfightsToStart.Extract(LDogfight);
    FDogfights.Add(LDogfight);
    LDogfight.SetInterceptionNumber(FirstFreeDogfightSlot);
    LDogfight.SetInterceptionsCount(FDogfights.Count + FDogfightsToStart.Count);
  end;
  // the right number of interceptions for every dogfight
  for LDogfight in FDogfights do
    LDogfight.SetInterceptionsCount(FDogfights.Count);
end;

procedure TXcomGeoscapeState.StartDogfight(ACraft: TXcomCraft; AUfo: TXcomUfo);
begin
  FDogfightsToStart.Add(TXcomDogfightState.Create(Host, FControl, ACraft, AUfo));
  if not FDogfightStartTimer.IsRunning then
  begin
    FPause := True;
    TimerReset;
    FGlobe.Center(ACraft.Longitude, ACraft.Latitude);
    StartDogfightNow;
    FDogfightStartTimer.Start;
  end;
end;

procedure TXcomGeoscapeState.DogfightImpossible(ACraft: TXcomCraft; const AReason: string);
var
  LDogfight: TXcomDogfightState;
begin
  for LDogfight in FDogfightsToStart.ToArray + FDogfights.ToArray do
    if LDogfight.Craft = ACraft then
    begin
      LDogfight.SetMinimized(True);
      if AReason = 'STR_UNABLE_TO_ENGAGE_DEPTH' then
        LDogfight.Engine.SetWaitForAltitude(True)
      else
        LDogfight.Engine.SetWaitForPoly(True);
      Break;
    end;
end;

function TXcomGeoscapeState.DogfightCount: Integer;
begin
  Result := FDogfights.Count + FDogfightsToStart.Count;
end;

procedure TXcomGeoscapeState.UfoRemoving(AUfo: TXcomUfo);
var
  LIndex: Integer;
begin
  // clean up the dogfights of a dead UFO (they were minimized)
  LIndex := 0;
  while LIndex < FDogfights.Count do
    if FDogfights[LIndex].Ufo = AUfo then
      FDogfights.Delete(LIndex)
    else
      Inc(LIndex);
  LIndex := 0;
  while LIndex < FDogfightsToStart.Count do
    if FDogfightsToStart[LIndex].Ufo = AUfo then
    begin
      FDogfightsToStart[LIndex].Free;
      FDogfightsToStart.Delete(LIndex);
    end
    else
      Inc(LIndex);
  FMinimizedDogfights := MinimizedDogfightsCount;
end;

procedure TXcomGeoscapeState.HandleDogfights;
var
  LIndex: Integer;
  LDogfight: TXcomDogfightState;
  LUfo: TXcomUfo;
begin
  FMinimizedDogfights := 0;
  for LDogfight in FDogfights do
    LDogfight.Ufo.InterceptionProcessed := False;
  LIndex := 0;
  while LIndex < FDogfights.Count do
  begin
    LDogfight := FDogfights[LIndex];
    LUfo := LDogfight.Ufo;
    if LDogfight.Engine.Minimized then
    begin
      if LDogfight.Engine.WaitForPoly and FGlobe.InsideLand(LUfo.Longitude, LUfo.Latitude) then
      begin
        LDogfight.SetMinimized(False);
        LDogfight.Engine.SetWaitForPoly(False);
      end
      else if LDogfight.Engine.WaitForAltitude and (LUfo.AltitudeInt <= LDogfight.Craft.Rules.MaxAltitude) then
      begin
        LDogfight.SetMinimized(False);
        LDogfight.Engine.SetWaitForAltitude(False);
      end
      else
        Inc(FMinimizedDogfights);
    end
    else
      FGlobe.RotateStop;
    LDogfight.Think;
    if LDogfight.Engine.Ended then
    begin
      if LDogfight.Engine.Minimized then
        Dec(FMinimizedDogfights);
      FDogfights.Delete(LIndex);
    end
    else
      Inc(LIndex);
  end;
  if FDogfights.Count = 0 then
  begin
    FDogfightTimer.Stop;
    // zoomOutEffect: the globe goes back to the zoom it had (if the dogfight zoomed it)
    if FZoomOld >= 0 then
    begin
      FGlobe.SetZoom(FZoomOld);
      FZoomOld := -1;
    end;
    FGlobe.Draw;
  end;
end;

procedure TXcomGeoscapeState.TimeDisplay;
begin
  FTxtSec.SetText(Format('%.2d', [FSave.Time.Second]));
  FTxtMin.SetText(Format('%.2d', [FSave.Time.Minute]));
  FTxtHour.SetText(IntToStr(FSave.Time.Hour));
  FTxtDay.SetText(Tr(FSave.Time.DayStringKey).Arg(FSave.Time.Day));
  FTxtWeekday.SetText(Tr(FSave.Time.WeekdayString));
  FTxtMonth.SetText(Tr(FSave.Time.MonthString));
  FTxtYear.SetText(IntToStr(FSave.Time.Year));
end;

procedure TXcomGeoscapeState.TimeAdvance;
var
  LTimeSpan, LIndex: Integer;
  LTrigger: TXcomTimeTrigger;
begin
  LTimeSpan := 0;
  if FTimeSpeed.Selected = FBtn5Secs then
    LTimeSpan := 1
  else if FTimeSpeed.Selected = FBtn1Min then
    LTimeSpan := 12
  else if FTimeSpeed.Selected = FBtn5Mins then
    LTimeSpan := 12 * 5
  else if FTimeSpeed.Selected = FBtn30Mins then
    LTimeSpan := 12 * 5 * 6
  else if FTimeSpeed.Selected = FBtn1Hour then
    LTimeSpan := 12 * 5 * 6 * 2
  else if FTimeSpeed.Selected = FBtn1Day then
    LTimeSpan := 12 * 5 * 6 * 2 * 24;
  LIndex := 0;
  while (LIndex < LTimeSpan) and not FPause do
  begin
    LTrigger := FSave.Time.Advance;
    // the switch of the C++ falls through from the longest period to the shortest
    if Assigned(FSimulation) then
    begin
      if LTrigger >= ttMonth then
        FSimulation.Time1Month;
      if LTrigger >= ttDay then
        FSimulation.Time1Day;
      if LTrigger >= ttHour then
        FSimulation.Time1Hour;
      if LTrigger >= ttThirtyMinutes then
        FSimulation.Time30Minutes;
      if LTrigger >= ttTenMinutes then
        FSimulation.Time10Minutes;
      FSimulation.Time5Seconds;
    end;
    Inc(LIndex);
  end;
  // the dogfights that wait to start keep the pause (the zoom effects are not ported)
  FPause := FDogfightsToStart.Count > 0;
  TimeDisplay;
  FGlobe.Draw;
end;

procedure TXcomGeoscapeState.Popup(AState: TXcomState);
begin
  FPause := True;
  FPopups.Add(AState);
end;

function TXcomGeoscapeState.PendingPopups: Integer;
begin
  Result := FPopups.Count;
end;

function TXcomGeoscapeState.Paused: Boolean;
begin
  Result := FPause;
end;

procedure TXcomGeoscapeState.OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
begin
  if Assigned(FNavigator) then
    FNavigator.OpenBaseScreen(AScreen, ABase);
end;

procedure TXcomGeoscapeState.PlaceLift(ABase: TXcomBase; AFirst: Boolean);
begin
  if Assigned(FNavigator) then
    FNavigator.OpenPlaceLift(ABase, FGlobe, AFirst);
end;

procedure TXcomGeoscapeState.OpenBase(ABase: TXcomBase);
begin
  if Assigned(FNavigator) then
    FNavigator.OpenBase(ABase, FGlobe);
end;

procedure TXcomGeoscapeState.TimerReset;
var
  LOld: TXcomTextButton;
begin
  LOld := FTimeSpeed.Selected;
  FTimeSpeed.Selected := FBtn5Secs;
  if Assigned(LOld) then
    LOld.Invalidate;
  FBtn5Secs.Invalidate;
end;

end.
