{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsBattlescapeState of OpenXcom (battlescape speeds and display)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.OptionsBattlescapeState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Slider, DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.ToggleTextButton,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The battlescape options: edge and drag scroll, scroll, fire and movement speeds, the path preview (arrows
  ///   and time unit cost bits of battleNewPreviewPath), tooltips and death notifications
  /// </summary>
  TXcomOptionsBattlescapeState = class(TXcomOptionsBaseState)
  strict private
    const
      PATH_ARROWS = 1;
      PATH_TU_COST = 2;
    var
      FTxtEdgeScroll: TXcomText;
      FCbxEdgeScroll: TXcomComboBox;
      FTxtDragScroll: TXcomText;
      FCbxDragScroll: TXcomComboBox;
      FTxtScrollSpeed: TXcomText;
      FSlrScrollSpeed: TXcomSlider;
      FTxtFireSpeed: TXcomText;
      FSlrFireSpeed: TXcomSlider;
      FTxtXcomSpeed: TXcomText;
      FSlrXcomSpeed: TXcomSlider;
      FTxtAlienSpeed: TXcomText;
      FSlrAlienSpeed: TXcomSlider;
      FTxtPathPreview: TXcomText;
      FBtnArrows: TXcomToggleTextButton;
      FBtnTuCost: TXcomToggleTextButton;
      FTxtOptions: TXcomText;
      FBtnTooltips: TXcomToggleTextButton;
      FBtnDeaths: TXcomToggleTextButton;
    procedure Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
    procedure EdgeScrollChange(AAction: TXcomAction);
    procedure DragScrollChange(AAction: TXcomAction);
    procedure ScrollSpeedChange(AAction: TXcomAction);
    procedure FireSpeedChange(AAction: TXcomAction);
    procedure XcomSpeedChange(AAction: TXcomAction);
    procedure AlienSpeedChange(AAction: TXcomAction);
    procedure PathPreviewClick(AAction: TXcomAction);
    procedure TooltipsClick(AAction: TXcomAction);
    procedure DeathsClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
  end;

implementation

procedure TXcomOptionsBattlescapeState.Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
begin
  ASurface.Tooltip := ATooltip;
  ASurface.OnMouseIn(TooltipIn);
  ASurface.OnMouseOut(TooltipOut);
end;

constructor TXcomOptionsBattlescapeState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LOptions: TXcomOptions;
begin
  inherited Create(AHost, AOrigin, ANavigator);
  LOptions := Host.Options;
  SetCategory(FBtnBattlescape);
  FTxtEdgeScroll := TXcomText.Create(114, 9, 94, 8);
  FCbxEdgeScroll := TXcomComboBox.Create(Self, 104, 16, 94, 18);
  FTxtDragScroll := TXcomText.Create(114, 9, 206, 8);
  FCbxDragScroll := TXcomComboBox.Create(Self, 104, 16, 206, 18);
  FTxtScrollSpeed := TXcomText.Create(114, 9, 94, 40);
  FSlrScrollSpeed := TXcomSlider.Create(104, 16, 94, 50);
  FTxtFireSpeed := TXcomText.Create(114, 9, 206, 40);
  FSlrFireSpeed := TXcomSlider.Create(104, 16, 206, 50);
  FTxtXcomSpeed := TXcomText.Create(114, 9, 94, 72);
  FSlrXcomSpeed := TXcomSlider.Create(104, 16, 94, 82);
  FTxtAlienSpeed := TXcomText.Create(114, 9, 206, 72);
  FSlrAlienSpeed := TXcomSlider.Create(104, 16, 206, 82);
  FTxtPathPreview := TXcomText.Create(114, 9, 94, 100);
  FBtnArrows := TXcomToggleTextButton.Create(104, 16, 94, 110);
  FBtnTuCost := TXcomToggleTextButton.Create(104, 16, 94, 128);
  FTxtOptions := TXcomText.Create(114, 9, 206, 100);
  FBtnTooltips := TXcomToggleTextButton.Create(104, 16, 206, 110);
  FBtnDeaths := TXcomToggleTextButton.Create(104, 16, 206, 128);
  Add(FTxtEdgeScroll, 'text', 'battlescapeMenu');
  Add(FTxtDragScroll, 'text', 'battlescapeMenu');
  Add(FTxtScrollSpeed, 'text', 'battlescapeMenu');
  Add(FSlrScrollSpeed, 'button', 'battlescapeMenu');
  Add(FTxtFireSpeed, 'text', 'battlescapeMenu');
  Add(FSlrFireSpeed, 'button', 'battlescapeMenu');
  Add(FTxtXcomSpeed, 'text', 'battlescapeMenu');
  Add(FSlrXcomSpeed, 'button', 'battlescapeMenu');
  Add(FTxtAlienSpeed, 'text', 'battlescapeMenu');
  Add(FSlrAlienSpeed, 'button', 'battlescapeMenu');
  Add(FTxtPathPreview, 'text', 'battlescapeMenu');
  Add(FBtnArrows, 'button', 'battlescapeMenu');
  Add(FBtnTuCost, 'button', 'battlescapeMenu');
  Add(FTxtOptions, 'text', 'battlescapeMenu');
  Add(FBtnTooltips, 'button', 'battlescapeMenu');
  Add(FBtnDeaths, 'button', 'battlescapeMenu');
  Add(FCbxEdgeScroll, 'button', 'battlescapeMenu');
  Add(FCbxDragScroll, 'button', 'battlescapeMenu');
  CenterAllSurfaces;
  FTxtEdgeScroll.SetText(Tr('STR_EDGE_SCROLL'));
  FCbxEdgeScroll.SetOptions([Tr('STR_DISABLED').Text, Tr('STR_TRIGGER_SCROLL').Text, Tr('STR_AUTO_SCROLL').Text]);
  FCbxEdgeScroll.SetSelected(LOptions.GetValue('battleEdgeScroll'));
  FCbxEdgeScroll.OnChange(EdgeScrollChange);
  Tip(FCbxEdgeScroll, 'STR_EDGE_SCROLL_DESC');
  FTxtDragScroll.SetText(Tr('STR_DRAG_SCROLL'));
  FCbxDragScroll.SetOptions([Tr('STR_DISABLED').Text, Tr('STR_LEFT_MOUSE_BUTTON').Text,
    Tr('STR_MIDDLE_MOUSE_BUTTON').Text, Tr('STR_RIGHT_MOUSE_BUTTON').Text]);
  FCbxDragScroll.SetSelected(LOptions.GetValue('battleDragScrollButton'));
  FCbxDragScroll.OnChange(DragScrollChange);
  Tip(FCbxDragScroll, 'STR_DRAG_SCROLL_DESC');
  FTxtScrollSpeed.SetText(Tr('STR_SCROLL_SPEED'));
  FSlrScrollSpeed.SetRange(2, 20);
  FSlrScrollSpeed.SetValue(LOptions.GetValue('battleScrollSpeed'));
  FSlrScrollSpeed.OnChange(ScrollSpeedChange);
  Tip(FSlrScrollSpeed, 'STR_SCROLL_SPEED_BATTLE_DESC');
  FTxtFireSpeed.SetText(Tr('STR_FIRE_SPEED'));
  FSlrFireSpeed.SetRange(1, 20);
  FSlrFireSpeed.SetValue(LOptions.GetValue('battleFireSpeed'));
  FSlrFireSpeed.OnChange(FireSpeedChange);
  Tip(FSlrFireSpeed, 'STR_FIRE_SPEED_DESC');
  FTxtXcomSpeed.SetText(Tr('STR_PLAYER_MOVEMENT_SPEED'));
  FSlrXcomSpeed.SetRange(40, 1);
  FSlrXcomSpeed.SetValue(LOptions.GetValue('battleXcomSpeed'));
  FSlrXcomSpeed.OnChange(XcomSpeedChange);
  Tip(FSlrXcomSpeed, 'STR_PLAYER_MOVEMENT_SPEED_DESC');
  FTxtAlienSpeed.SetText(Tr('STR_COMPUTER_MOVEMENT_SPEED'));
  FSlrAlienSpeed.SetRange(40, 1);
  FSlrAlienSpeed.SetValue(LOptions.GetValue('battleAlienSpeed'));
  FSlrAlienSpeed.OnChange(AlienSpeedChange);
  Tip(FSlrAlienSpeed, 'STR_COMPUTER_MOVEMENT_SPEED_DESC');
  FTxtPathPreview.SetText(Tr('STR_PATH_PREVIEW'));
  FBtnArrows.SetText(Tr('STR_PATH_ARROWS'));
  FBtnArrows.SetPressed((LOptions.GetValue('battleNewPreviewPath') and PATH_ARROWS) <> 0);
  FBtnArrows.OnMouseClick(PathPreviewClick);
  Tip(FBtnArrows, 'STR_PATH_ARROWS_DESC');
  FBtnTuCost.SetText(Tr('STR_PATH_TIME_UNIT_COST'));
  FBtnTuCost.SetPressed((LOptions.GetValue('battleNewPreviewPath') and PATH_TU_COST) <> 0);
  FBtnTuCost.OnMouseClick(PathPreviewClick);
  Tip(FBtnTuCost, 'STR_PATH_TIME_UNIT_COST_DESC');
  FTxtOptions.SetText(Tr('STR_USER_INTERFACE_OPTIONS'));
  FBtnTooltips.SetText(Tr('STR_TOOLTIPS'));
  FBtnTooltips.SetPressed(LOptions.GetBool('battleTooltips'));
  FBtnTooltips.OnMouseClick(TooltipsClick);
  Tip(FBtnTooltips, 'STR_TOOLTIPS_DESC');
  FBtnDeaths.SetText(Tr('STR_DEATH_NOTIFICATIONS'));
  FBtnDeaths.SetPressed(LOptions.GetBool('battleNotifyDeath'));
  FBtnDeaths.OnMouseClick(DeathsClick);
  Tip(FBtnDeaths, 'STR_DEATH_NOTIFICATIONS_DESC');
end;

procedure TXcomOptionsBattlescapeState.EdgeScrollChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('battleEdgeScroll', FCbxEdgeScroll.GetSelected);
end;

procedure TXcomOptionsBattlescapeState.DragScrollChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('battleDragScrollButton', FCbxDragScroll.GetSelected);
end;

procedure TXcomOptionsBattlescapeState.ScrollSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('battleScrollSpeed', FSlrScrollSpeed.GetValue);
end;

procedure TXcomOptionsBattlescapeState.FireSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('battleFireSpeed', FSlrFireSpeed.GetValue);
end;

procedure TXcomOptionsBattlescapeState.XcomSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('battleXcomSpeed', FSlrXcomSpeed.GetValue);
end;

procedure TXcomOptionsBattlescapeState.AlienSpeedChange(AAction: TXcomAction);
begin
  Host.Options.SetValue('battleAlienSpeed', FSlrAlienSpeed.GetValue);
end;

procedure TXcomOptionsBattlescapeState.PathPreviewClick(AAction: TXcomAction);
var
  LMode: Integer;
begin
  LMode := 0;
  if FBtnArrows.GetPressed then
    LMode := LMode or PATH_ARROWS;
  if FBtnTuCost.GetPressed then
    LMode := LMode or PATH_TU_COST;
  Host.Options.SetValue('battleNewPreviewPath', LMode);
end;

procedure TXcomOptionsBattlescapeState.TooltipsClick(AAction: TXcomAction);
begin
  Host.Options.SetBool('battleTooltips', FBtnTooltips.GetPressed);
end;

procedure TXcomOptionsBattlescapeState.DeathsClick(AAction: TXcomAction);
begin
  Host.Options.SetBool('battleNotifyDeath', FBtnDeaths.GetPressed);
end;

end.