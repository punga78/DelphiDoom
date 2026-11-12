{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsBaseState of OpenXcom (the frame of   }
{  every options screen: the category buttons, OK, Cancel and the defaults)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsBaseState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf;

type
  /// <summary>
  ///   The window of the options with the buttons of the categories on the left (the one of the screen is pressed),
  ///   OK, Cancel and Restore Defaults below, and the line where the tooltip of the control under the mouse is
  ///   shown. The screens of the categories derive from it. Opened from a battle they take the palette of the
  ///   battle and the battlescape theme (TXcomBattlescapeTheme) at every Init
  /// </summary>
  TXcomOptionsBaseState = class(TXcomState)
  strict private
    FGroup: TXcomButtonGroup;
    FCurrentTooltip: string;
    procedure GroupPress(AAction: TXcomAction);
    procedure DefaultClick(AAction: TXcomAction);
    function CategoryOf(ASender: TObject; out ACategory: TXcomOptionsCategory): Boolean;
  protected
    FOrigin: TXcomOptionsOrigin;
    FNavigator: IXcomOptionsNavigator;
    FWindow: TXcomWindow;
    FBtnVideo: TXcomTextButton;
    FBtnAudio: TXcomTextButton;
    FBtnControls: TXcomTextButton;
    FBtnGeoscape: TXcomTextButton;
    FBtnBattlescape: TXcomTextButton;
    FBtnAdvanced: TXcomTextButton;
    FBtnFolders: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FBtnDefault: TXcomTextButton;
    FTxtTooltip: TXcomText;
    /// <summary>OptionsBaseState::setCategory: the button of the screen is the pressed one of the group</summary>
    procedure SetCategory(AButton: TXcomTextButton);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
    destructor Destroy; override;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    /// <summary>OptionsBaseState::txtTooltipIn: shows the tooltip of the surface that sent the action</summary>
    procedure TooltipIn(AAction: TXcomAction);
    procedure TooltipOut(AAction: TXcomAction);
    /// <summary>OptionsBaseState::init: the colors of the battlescape when opened from a battle</summary>
    procedure Init; override;
    procedure Resize(var ADX, ADY: Integer); override;
    property Origin: TXcomOptionsOrigin read FOrigin;
    /// <summary>The text the tooltip shows now</summary>
    function TooltipText: string;
  end;

implementation

uses
  DelphiDoom.XcomMenu.BattlescapeTheme,
  DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomMenu.OptionsDefaultsState, DelphiDoom.XcomMenu.OptionsConfirmState;

function TXcomOptionsBaseState.TooltipText: string;
begin
  Result := FTxtTooltip.GetText;
end;

constructor TXcomOptionsBaseState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FNavigator := ANavigator;
  FGroup := TXcomButtonGroup.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnVideo := TXcomTextButton.Create(80, 16, 8, 8);
  FBtnAudio := TXcomTextButton.Create(80, 16, 8, 28);
  FBtnControls := TXcomTextButton.Create(80, 16, 8, 48);
  FBtnGeoscape := TXcomTextButton.Create(80, 16, 8, 68);
  FBtnBattlescape := TXcomTextButton.Create(80, 16, 8, 88);
  FBtnAdvanced := TXcomTextButton.Create(80, 16, 8, 108);
  FBtnFolders := TXcomTextButton.Create(80, 16, 8, 128);
  FBtnOk := TXcomTextButton.Create(100, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(100, 16, 110, 176);
  FBtnDefault := TXcomTextButton.Create(100, 16, 212, 176);
  FTxtTooltip := TXcomText.Create(305, 25, 8, 148);
  SetInterface('optionsMenu', False, True);
  Add(FWindow, 'window', 'optionsMenu');
  Add(FBtnVideo, 'button', 'optionsMenu');
  Add(FBtnAudio, 'button', 'optionsMenu');
  Add(FBtnControls, 'button', 'optionsMenu');
  Add(FBtnGeoscape, 'button', 'optionsMenu');
  Add(FBtnBattlescape, 'button', 'optionsMenu');
  Add(FBtnAdvanced, 'button', 'optionsMenu');
  Add(FBtnFolders, 'button', 'optionsMenu');
  Add(FBtnOk, 'button', 'optionsMenu');
  Add(FBtnCancel, 'button', 'optionsMenu');
  Add(FBtnDefault, 'button', 'optionsMenu');
  Add(FTxtTooltip, 'tooltip', 'optionsMenu');
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnVideo.SetText(Tr('STR_VIDEO'));
  FBtnVideo.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnAudio.SetText(Tr('STR_AUDIO'));
  FBtnAudio.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnControls.SetText(Tr('STR_CONTROLS'));
  FBtnControls.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnGeoscape.SetText(Tr('STR_GEOSCAPE_UC'));
  FBtnGeoscape.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnBattlescape.SetText(Tr('STR_BATTLESCAPE_UC'));
  FBtnBattlescape.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnAdvanced.SetText(Tr('STR_ADVANCED'));
  FBtnAdvanced.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnFolders.SetText(Tr('STR_FOLDERS'));
  FBtnFolders.OnMousePress(GroupPress, XCOM_BUTTON_LEFT);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FBtnDefault.SetText(Tr('STR_RESTORE_DEFAULTS'));
  FBtnDefault.OnMouseClick(DefaultClick);
  FTxtTooltip.SetWordWrap(True);
end;

destructor TXcomOptionsBaseState.Destroy;
begin
  // the buttons of the group are freed with the state, before the group they point to
  inherited Destroy;
  FGroup.Free;
end;

procedure TXcomOptionsBaseState.SetCategory(AButton: TXcomTextButton);
begin
  FGroup.Selected := AButton;
  FBtnVideo.SetGroup(FGroup);
  FBtnAudio.SetGroup(FGroup);
  FBtnControls.SetGroup(FGroup);
  FBtnGeoscape.SetGroup(FGroup);
  FBtnBattlescape.SetGroup(FGroup);
  FBtnAdvanced.SetGroup(FGroup);
  FBtnFolders.SetGroup(FGroup);
end;

procedure TXcomOptionsBaseState.OkClick(AAction: TXcomAction);
var
  LDX: Integer;
  LDY: Integer;
  LOptions: TXcomOptions;
begin
  LOptions := Host.Options;
  LOptions.SwitchDisplay;
  LDX := LOptions.BaseXResolution;
  LDY := LOptions.BaseYResolution;
  TXcomScreen.UpdateScale(LOptions, LOptions.BattlescapeScale, LOptions.BaseXBattlescape, LOptions.BaseYBattlescape,
    FOrigin = ooBattlescape);
  TXcomScreen.UpdateScale(LOptions, LOptions.GeoscapeScale, LOptions.BaseXGeoscape, LOptions.BaseYGeoscape,
    FOrigin <> ooBattlescape);
  LDX := LOptions.BaseXResolution - LDX;
  LDY := LOptions.BaseYResolution - LDY;
  Recenter(LDX, LDY);
  if (Host.OptionsStore <> nil) then
    Host.OptionsStore.Save(LOptions);
  Host.LoadLanguages;
  Host.Screen.ResetDisplay;
  Host.SetVolume(LOptions.SoundVolume, LOptions.MusicVolume, LOptions.UiVolume);
  // a change of the video options must be confirmed
  if (LOptions.DisplayWidth <> LOptions.NewDisplayWidth) or (LOptions.DisplayHeight <> LOptions.NewDisplayHeight) or
    (LOptions.UseOpenGL <> LOptions.NewOpenGL) or (LOptions.UseScaleFilter <> LOptions.NewScaleFilter) or
    (LOptions.UseHQXFilter <> LOptions.NewHQXFilter) or (LOptions.UseOpenGLShader <> LOptions.NewOpenGLShader) then
    Host.PushState(TXcomOptionsConfirmState.Create(Host, FOrigin, FNavigator))
  else
    FNavigator.Restart(FOrigin, Host);
end;

procedure TXcomOptionsBaseState.CancelClick(AAction: TXcomAction);
begin
  Host.Options.Reload := False;
  if (Host.OptionsStore <> nil) then
    Host.OptionsStore.Load(Host.Options);
  TXcomScreen.UpdateScale(Host.Options, Host.Options.BattlescapeScale, Host.Options.BaseXBattlescape,
    Host.Options.BaseYBattlescape, FOrigin = ooBattlescape);
  TXcomScreen.UpdateScale(Host.Options, Host.Options.GeoscapeScale, Host.Options.BaseXGeoscape,
    Host.Options.BaseYGeoscape, FOrigin <> ooBattlescape);
  Host.SetVolume(Host.Options.SoundVolume, Host.Options.MusicVolume, Host.Options.UiVolume);
  Host.PopState;
end;

procedure TXcomOptionsBaseState.DefaultClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomOptionsDefaultsState.Create(Host, FOrigin,
    procedure(AOk: TXcomAction)
    begin
      OkClick(AOk);
    end));
end;

function TXcomOptionsBaseState.CategoryOf(ASender: TObject; out ACategory: TXcomOptionsCategory): Boolean;
begin
  Result := True;
  if ASender = FBtnVideo then
    ACategory := ocVideo
  else if ASender = FBtnAudio then
    ACategory := ocAudio
  else if ASender = FBtnControls then
    ACategory := ocControls
  else if ASender = FBtnGeoscape then
    ACategory := ocGeoscape
  else if ASender = FBtnBattlescape then
    ACategory := ocBattlescape
  else if ASender = FBtnAdvanced then
    ACategory := ocAdvanced
  else if ASender = FBtnFolders then
    ACategory := ocFolders
  else
    Result := False;
end;

procedure TXcomOptionsBaseState.GroupPress(AAction: TXcomAction);
var
  LCategory: TXcomOptionsCategory;
  LState: TXcomState;
begin
  if not CategoryOf(AAction.Sender, LCategory) then
    Exit;
  // the screen is made first: a category that is not available leaves the current one
  LState := FNavigator.CreateCategory(LCategory, FOrigin, Host);
  if LState = nil then
    Exit;
  Host.PopState;
  Host.PushState(LState);
end;

procedure TXcomOptionsBaseState.TooltipIn(AAction: TXcomAction);
begin
  FCurrentTooltip := TXcomWidget(AAction.Sender).Tooltip;
  FTxtTooltip.SetText(Tr(FCurrentTooltip));
end;

procedure TXcomOptionsBaseState.TooltipOut(AAction: TXcomAction);
begin
  if FCurrentTooltip = TXcomWidget(AAction.Sender).Tooltip then
    FTxtTooltip.SetText('');
end;

procedure TXcomOptionsBaseState.Init;
begin
  inherited Init;
  if FOrigin = ooBattlescape then
    TXcomBattlescapeTheme.Apply(Self);
end;

procedure TXcomOptionsBaseState.Resize(var ADX, ADY: Integer);
begin
  Host.Options.NewDisplayWidth := Host.Options.DisplayWidth;
  Host.Options.NewDisplayHeight := Host.Options.DisplayHeight;
  inherited Resize(ADX, ADY);
end;

end.
