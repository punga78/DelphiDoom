{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsVideoState of OpenXcom (resolution,   }
{  language, filter, display mode and scales)                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsVideoState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomUi.ArrowButton,
  DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.ToggleTextButton, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The video options: the resolution (typed or chosen from the modes of the display with the arrows), the
  ///   language, the filter, the display mode, the scales of the geoscape and the battlescape, and three switches.
  ///   The filter list has the four fixed entries (the software filters Scale, HQx and xBRZ are not ported: they
  ///   only set their options) and then the OpenGL shaders of the catalog of the host. A change is kept in the
  ///   pending options (New...) until OK
  /// </summary>
  TXcomOptionsVideoState = class(TXcomOptionsBaseState)
  strict private
    FDisplaySurface: TXcomInteractiveSurface;
    FTxtDisplayResolution: TXcomText;
    FTxtDisplayWidth: TXcomTextEdit;
    FTxtDisplayX: TXcomText;
    FTxtDisplayHeight: TXcomTextEdit;
    FBtnResolutionUp: TXcomArrowButton;
    FBtnResolutionDown: TXcomArrowButton;
    FTxtLanguage: TXcomText;
    FCbxLanguage: TXcomComboBox;
    FTxtFilter: TXcomText;
    FCbxFilter: TXcomComboBox;
    FTxtMode: TXcomText;
    FCbxDisplayMode: TXcomComboBox;
    FTxtGeoScale: TXcomText;
    FCbxGeoScale: TXcomComboBox;
    FTxtBattleScale: TXcomText;
    FCbxBattleScale: TXcomComboBox;
    FTxtOptions: TXcomText;
    FBtnLetterbox: TXcomToggleTextButton;
    FBtnLockMouse: TXcomToggleTextButton;
    FBtnRootWindowedMode: TXcomToggleTextButton;
    FModes: TArray<TXcomDisplayMode>;
    FResCurrent: Integer;
    FLanguages: TArray<string>;
    FFilters: TArray<string>;
    class function UcWords(const AText: string): string; static;
    procedure FindCurrentResolution(AWidth, AHeight: Integer);
    procedure ResolutionUpClick(AAction: TXcomAction);
    procedure ResolutionDownClick(AAction: TXcomAction);
    procedure UpdateDisplayResolution;
    procedure DisplayWidthChange(AAction: TXcomAction);
    procedure DisplayHeightChange(AAction: TXcomAction);
    procedure LanguageChange(AAction: TXcomAction);
    procedure FilterChange(AAction: TXcomAction);
    procedure DisplayModeChange(AAction: TXcomAction);
    procedure LetterboxClick(AAction: TXcomAction);
    procedure LockMouseClick(AAction: TXcomAction);
    procedure RootWindowedModeClick(AAction: TXcomAction);
    procedure GeoscapeScaleChange(AAction: TXcomAction);
    procedure BattlescapeScaleChange(AAction: TXcomAction);
    procedure Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
    procedure Resize(var ADX, ADY: Integer); override;
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>OptionsVideoState::unpressRootWindowedMode</summary>
    procedure UnpressRootWindowedMode;
  end;

implementation

uses
  DelphiDoom.XcomMenu.SetWindowedRootState;

const
  // OptionsVideoState::GL_EXT, GL_FOLDER and GL_STRING
  GL_EXT = 'OpenGL.shader';
  GL_FOLDER = 'Shaders/';
  GL_STRING = '*';

class function TXcomOptionsVideoState.UcWords(const AText: string): string;
var
  LIndex: Integer;
begin
  // OptionsVideoState::ucWords: a capital first letter; space, dash and underscore become a space before a capital
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if LIndex = 1 then
      Result[1] := UpCase(Result[1])
    else if CharInSet(Result[LIndex], [' ', '-', '_']) then
    begin
      Result[LIndex] := ' ';
      if LIndex < Length(Result) then
        Result[LIndex + 1] := UpCase(Result[LIndex + 1]);
    end;
end;

procedure TXcomOptionsVideoState.Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
begin
  ASurface.Tooltip := ATooltip;
  ASurface.OnMouseIn(TooltipIn);
  ASurface.OnMouseOut(TooltipOut);
end;

procedure TXcomOptionsVideoState.FindCurrentResolution(AWidth, AHeight: Integer);
var
  LIndex: Integer;
begin
  FResCurrent := -1;
  for LIndex := 0 to High(FModes) do
    if (FResCurrent = -1) and (((FModes[LIndex].Width = AWidth) and (FModes[LIndex].Height <= AHeight)) or
      (FModes[LIndex].Width < AWidth)) then
      FResCurrent := LIndex;
end;

constructor TXcomOptionsVideoState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LOptions: TXcomOptions;
  LNames: TArray<string>;
  LFilterNames: TArray<string>;
  LModeNames: TArray<string>;
  LScales: TArray<string>;
  LIndex: Integer;
  LFilter: Integer;
  LMode: Integer;
  LShader: string;
begin
  inherited Create(AHost, AOrigin, ANavigator);
  LOptions := Host.Options;
  SetCategory(FBtnVideo);
  FDisplaySurface := TXcomInteractiveSurface.Create(110, 32, 94, 18);
  FTxtDisplayResolution := TXcomText.Create(114, 9, 94, 8);
  FTxtDisplayWidth := TXcomTextEdit.Create(Self, 40, 17, 94, 26);
  FTxtDisplayX := TXcomText.Create(16, 17, 132, 26);
  FTxtDisplayHeight := TXcomTextEdit.Create(Self, 40, 17, 144, 26);
  FBtnResolutionUp := TXcomArrowButton.Create(Host.Clock, arBigUp, 14, 14, 186, 18);
  FBtnResolutionDown := TXcomArrowButton.Create(Host.Clock, arBigDown, 14, 14, 186, 36);
  FTxtLanguage := TXcomText.Create(114, 9, 94, 52);
  FCbxLanguage := TXcomComboBox.Create(Self, 104, 16, 94, 62);
  FTxtFilter := TXcomText.Create(114, 9, 206, 52);
  FCbxFilter := TXcomComboBox.Create(Self, 104, 16, 206, 62);
  FTxtMode := TXcomText.Create(114, 9, 206, 22);
  FCbxDisplayMode := TXcomComboBox.Create(Self, 104, 16, 206, 32);
  FTxtGeoScale := TXcomText.Create(114, 9, 94, 82);
  FCbxGeoScale := TXcomComboBox.Create(Self, 104, 16, 94, 92);
  FTxtBattleScale := TXcomText.Create(114, 9, 94, 112);
  FCbxBattleScale := TXcomComboBox.Create(Self, 104, 16, 94, 122);
  FTxtOptions := TXcomText.Create(114, 9, 206, 82);
  FBtnLetterbox := TXcomToggleTextButton.Create(104, 16, 206, 92);
  FBtnLockMouse := TXcomToggleTextButton.Create(104, 16, 206, 110);
  FBtnRootWindowedMode := TXcomToggleTextButton.Create(104, 16, 206, 128);
  // the full screen modes of the display
  if (Host.DisplayModes <> nil) then
    FModes := Host.DisplayModes.Modes;
  if Length(FModes) > 0 then
    FindCurrentResolution(LOptions.DisplayWidth, LOptions.DisplayHeight)
  else
  begin
    FResCurrent := -1;
    FBtnResolutionDown.Visible := False;
    FBtnResolutionUp.Visible := False;
  end;
  Add(FDisplaySurface);
  Add(FTxtDisplayResolution, 'text', 'videoMenu');
  Add(FTxtDisplayWidth, 'resolution', 'videoMenu');
  Add(FTxtDisplayX, 'resolution', 'videoMenu');
  Add(FTxtDisplayHeight, 'resolution', 'videoMenu');
  Add(FBtnResolutionUp, 'button', 'videoMenu');
  Add(FBtnResolutionDown, 'button', 'videoMenu');
  Add(FTxtLanguage, 'text', 'videoMenu');
  Add(FTxtFilter, 'text', 'videoMenu');
  Add(FTxtMode, 'text', 'videoMenu');
  Add(FTxtOptions, 'text', 'videoMenu');
  Add(FBtnLetterbox, 'button', 'videoMenu');
  Add(FBtnLockMouse, 'button', 'videoMenu');
  Add(FBtnRootWindowedMode, 'button', 'videoMenu');
  Add(FCbxFilter, 'button', 'videoMenu');
  Add(FCbxDisplayMode, 'button', 'videoMenu');
  Add(FTxtBattleScale, 'text', 'videoMenu');
  Add(FCbxBattleScale, 'button', 'videoMenu');
  Add(FTxtGeoScale, 'text', 'videoMenu');
  Add(FCbxGeoScale, 'button', 'videoMenu');
  Add(FCbxLanguage, 'button', 'videoMenu');
  CenterAllSurfaces;
  FTxtDisplayResolution.SetText(Tr('STR_DISPLAY_RESOLUTION'));
  Tip(FDisplaySurface, 'STR_DISPLAY_RESOLUTION_DESC');
  FTxtDisplayWidth.SetAlign(haCenter);
  FTxtDisplayWidth.SetBig;
  FTxtDisplayWidth.SetConstraint(tecNumericPositive);
  FTxtDisplayWidth.OnChange(DisplayWidthChange);
  FTxtDisplayX.SetAlign(haCenter);
  FTxtDisplayX.SetBig;
  FTxtDisplayX.SetText('x');
  FTxtDisplayHeight.SetAlign(haCenter);
  FTxtDisplayHeight.SetBig;
  FTxtDisplayHeight.SetConstraint(tecNumericPositive);
  FTxtDisplayHeight.OnChange(DisplayHeightChange);
  FTxtDisplayWidth.SetText(IntToStr(LOptions.DisplayWidth));
  FTxtDisplayHeight.SetText(IntToStr(LOptions.DisplayHeight));
  FBtnResolutionUp.OnMouseClick(ResolutionUpClick);
  FBtnResolutionDown.OnMouseClick(ResolutionDownClick);
  FTxtMode.SetText(Tr('STR_DISPLAY_MODE'));
  FTxtOptions.SetText(Tr('STR_DISPLAY_OPTIONS'));
  FBtnLetterbox.SetText(Tr('STR_LETTERBOXED'));
  FBtnLetterbox.SetPressed(LOptions.KeepAspectRatio);
  FBtnLetterbox.OnMouseClick(LetterboxClick);
  Tip(FBtnLetterbox, 'STR_LETTERBOXED_DESC');
  FBtnLockMouse.SetText(Tr('STR_LOCK_MOUSE'));
  FBtnLockMouse.SetPressed(LOptions.CaptureMouse);
  FBtnLockMouse.OnMouseClick(LockMouseClick);
  Tip(FBtnLockMouse, 'STR_LOCK_MOUSE_DESC');
  FBtnRootWindowedMode.SetText(Tr('STR_FIXED_WINDOW_POSITION'));
  FBtnRootWindowedMode.SetPressed(LOptions.RootWindowedMode);
  FBtnRootWindowedMode.OnMouseClick(RootWindowedModeClick);
  Tip(FBtnRootWindowedMode, 'STR_FIXED_WINDOW_POSITION_DESC');
  FTxtLanguage.SetText(Tr('STR_DISPLAY_LANGUAGE'));
  if (Host.LanguageProvider <> nil) then
    Host.LanguageProvider.List(FLanguages, LNames);
  FCbxLanguage.SetOptions(LNames);
  for LIndex := 0 to High(LNames) do
    if FLanguages[LIndex] = LOptions.Language then
    begin
      FCbxLanguage.SetSelected(LIndex);
      Break;
    end;
  FCbxLanguage.OnChange(LanguageChange);
  Tip(FCbxLanguage, 'STR_DISPLAY_LANGUAGE_DESC');
  LFilterNames := [Tr('STR_DISABLED').Text, 'Scale', 'HQx', 'xBRZ'];
  FFilters := ['', '', '', ''];
  if Host.ShaderCatalog <> nil then
    for LShader in Host.ShaderCatalog.Files do
    begin
      // the name of the file without ".OpenGL.shader", marked with the star of the OpenGL filters
      LFilterNames := LFilterNames + [UcWords(Copy(LShader, 1, Length(LShader) - Length(GL_EXT) - 1) + GL_STRING)];
      FFilters := FFilters + [GL_FOLDER + LShader];
    end;
  LFilter := 0;
  if LOptions.UseOpenGL then
  begin
    // the first path that is the one of the option, compared as it is written (the four fixed entries are empty)
    for LIndex := High(FFilters) downto 0 do
      if FFilters[LIndex] = LOptions.UseOpenGLShader then
        LFilter := LIndex;
  end
  else if LOptions.UseScaleFilter then
    LFilter := 1
  else if LOptions.UseHQXFilter then
    LFilter := 2
  else if LOptions.UseXBRZFilter then
    LFilter := 3;
  FTxtFilter.SetText(Tr('STR_DISPLAY_FILTER'));
  FCbxFilter.SetOptions(LFilterNames);
  FCbxFilter.SetSelected(LFilter);
  FCbxFilter.OnChange(FilterChange);
  Tip(FCbxFilter, 'STR_DISPLAY_FILTER_DESC');
  LModeNames := [Tr('STR_WINDOWED').Text, Tr('STR_FULLSCREEN').Text, Tr('STR_BORDERLESS').Text,
    Tr('STR_RESIZABLE').Text];
  LMode := 0;
  if LOptions.Fullscreen then
    LMode := 1
  else if LOptions.Borderless then
    LMode := 2
  else if LOptions.AllowResize then
    LMode := 3;
  FCbxDisplayMode.SetOptions(LModeNames);
  FCbxDisplayMode.SetSelected(LMode);
  FCbxDisplayMode.OnChange(DisplayModeChange);
  Tip(FCbxDisplayMode, 'STR_DISPLAY_MODE_DESC');
  FTxtGeoScale.SetText(Tr('STR_GEOSCAPE_SCALE'));
  LScales := [Tr('STR_ORIGINAL').Text, Tr('STR_1_5X').Text, Tr('STR_2X').Text, Tr('STR_THIRD_DISPLAY').Text,
    Tr('STR_HALF_DISPLAY').Text, Tr('STR_FULL_DISPLAY').Text];
  FCbxGeoScale.SetOptions(LScales);
  FCbxGeoScale.SetSelected(LOptions.GeoscapeScale);
  FCbxGeoScale.OnChange(GeoscapeScaleChange);
  Tip(FCbxGeoScale, 'STR_GEOSCAPESCALE_SCALE_DESC');
  FTxtBattleScale.SetText(Tr('STR_BATTLESCAPE_SCALE'));
  FCbxBattleScale.SetOptions(LScales);
  FCbxBattleScale.SetSelected(LOptions.BattlescapeScale);
  FCbxBattleScale.OnChange(BattlescapeScaleChange);
  Tip(FCbxBattleScale, 'STR_BATTLESCAPE_SCALE_DESC');
end;

procedure TXcomOptionsVideoState.ResolutionUpClick(AAction: TXcomAction);
begin
  if Length(FModes) = 0 then
    Exit;
  if FResCurrent <= 0 then
    FResCurrent := Length(FModes) - 1
  else
    Dec(FResCurrent);
  UpdateDisplayResolution;
end;

procedure TXcomOptionsVideoState.ResolutionDownClick(AAction: TXcomAction);
begin
  if Length(FModes) = 0 then
    Exit;
  if FResCurrent >= Length(FModes) - 1 then
    FResCurrent := 0
  else
    Inc(FResCurrent);
  UpdateDisplayResolution;
end;

procedure TXcomOptionsVideoState.UpdateDisplayResolution;
begin
  FTxtDisplayWidth.SetText(IntToStr(FModes[FResCurrent].Width));
  FTxtDisplayHeight.SetText(IntToStr(FModes[FResCurrent].Height));
  Host.Options.NewDisplayWidth := FModes[FResCurrent].Width;
  Host.Options.NewDisplayHeight := FModes[FResCurrent].Height;
end;

procedure TXcomOptionsVideoState.DisplayWidthChange(AAction: TXcomAction);
begin
  // the stream of the C++ leaves 0 when the text is not a number
  Host.Options.NewDisplayWidth := StrToIntDef(FTxtDisplayWidth.GetText, 0);
  if Length(FModes) > 0 then
    FindCurrentResolution(Host.Options.NewDisplayWidth, Host.Options.NewDisplayHeight);
end;

procedure TXcomOptionsVideoState.DisplayHeightChange(AAction: TXcomAction);
begin
  Host.Options.NewDisplayHeight := StrToIntDef(FTxtDisplayHeight.GetText, 0);
  if Length(FModes) > 0 then
    FindCurrentResolution(Host.Options.NewDisplayWidth, Host.Options.NewDisplayHeight);
end;

procedure TXcomOptionsVideoState.LanguageChange(AAction: TXcomAction);
begin
  if FCbxLanguage.GetSelected < Length(FLanguages) then
    Host.Options.Language := FLanguages[FCbxLanguage.GetSelected];
end;

procedure TXcomOptionsVideoState.FilterChange(AAction: TXcomAction);
var
  LOptions: TXcomOptions;
  LSelected: Integer;
begin
  LOptions := Host.Options;
  LSelected := FCbxFilter.GetSelected;
  LOptions.NewOpenGL := LSelected > 3;
  LOptions.NewScaleFilter := LSelected = 1;
  LOptions.NewHQXFilter := LSelected = 2;
  LOptions.NewXBRZFilter := LSelected = 3;
  if (LSelected > 3) and (LSelected < Length(FFilters)) then
    LOptions.NewOpenGLShader := FFilters[LSelected];
end;

procedure TXcomOptionsVideoState.DisplayModeChange(AAction: TXcomAction);
var
  LSelected: Integer;
begin
  LSelected := FCbxDisplayMode.GetSelected;
  if (LSelected < 0) or (LSelected > 3) then
    Exit;
  Host.Options.NewFullscreen := LSelected = 1;
  Host.Options.NewBorderless := LSelected = 2;
  Host.Options.NewAllowResize := LSelected = 3;
end;

procedure TXcomOptionsVideoState.LetterboxClick(AAction: TXcomAction);
begin
  Host.Options.KeepAspectRatio := FBtnLetterbox.GetPressed;
end;

procedure TXcomOptionsVideoState.LockMouseClick(AAction: TXcomAction);
begin
  Host.Options.CaptureMouse := FBtnLockMouse.GetPressed;
end;

procedure TXcomOptionsVideoState.RootWindowedModeClick(AAction: TXcomAction);
begin
  if FBtnRootWindowedMode.GetPressed then
    Host.PushState(TXcomSetWindowedRootState.Create(Host, FOrigin,
      procedure
      begin
        UnpressRootWindowedMode;
      end))
  else
    Host.Options.NewRootWindowedMode := False;
end;

procedure TXcomOptionsVideoState.GeoscapeScaleChange(AAction: TXcomAction);
begin
  Host.Options.NewGeoscapeScale := FCbxGeoScale.GetSelected;
end;

procedure TXcomOptionsVideoState.BattlescapeScaleChange(AAction: TXcomAction);
begin
  Host.Options.NewBattlescapeScale := FCbxBattleScale.GetSelected;
end;

procedure TXcomOptionsVideoState.Resize(var ADX, ADY: Integer);
begin
  inherited Resize(ADX, ADY);
  FTxtDisplayWidth.SetText(IntToStr(Host.Options.DisplayWidth));
  FTxtDisplayHeight.SetText(IntToStr(Host.Options.DisplayHeight));
end;

procedure TXcomOptionsVideoState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  // Ctrl+G toggles the grab of the mouse: the button follows the option
  if (AAction.Details^.Kind = ekKeyDown) and (AAction.Details^.Key = Ord('g')) and
    ((AAction.Details^.Modifiers and XCOM_KMOD_CTRL) <> 0) then
    FBtnLockMouse.SetPressed(Host.Options.CaptureMouse);
end;

procedure TXcomOptionsVideoState.UnpressRootWindowedMode;
begin
  FBtnRootWindowedMode.SetPressed(False);
end;

end.