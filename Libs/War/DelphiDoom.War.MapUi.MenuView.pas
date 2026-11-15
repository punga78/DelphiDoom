{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the drawing of the menus of the map                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map_ui.c (renderMenus), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.MenuView;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Text.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Imui, DelphiDoom.War.Ui.Widgets, DelphiDoom.War.MapUi.Types,
  DelphiDoom.War.MapUi.Menu;

type
  /// <summary>
  ///   The menus of the map, drawn with the immediate interface as renderMenus does: the buttons tell the menu what they do
  ///   in the same frame they are clicked, one after the other in the order of the original, so a click can also reach
  ///   the buttons that follow it. The state that decides what is drawn is read once, before the first button
  /// </summary>
  TWarMapMenuView = class
  strict private
    FImui: TWarImui;
    FPanels: TWarMapPanels;
    FMenu: TWarMapMenu;
    FRace: TWarRace;
    /// <summary>The menu that is being drawn: its buttons may change the state of the menu while they are drawn</summary>
    FDrawn: TWarMenuState;
    procedure Backdrop(AWidth, AHeight: Integer);
    procedure Picture(const AId: AnsiString; AMessage: Boolean);
    procedure Title(const AId, AText: AnsiString; AMessage: Boolean);
    function Button(const AId, AText: AnsiString; AX, AY: Single; AHotKey: TWarKey; ASmall: Boolean): Boolean;
    function Arrow(const AId: AnsiString; AX, AY: Single; ARight: Boolean): Boolean;
    procedure Value(const AId, AText: AnsiString; AY: Single);
    function SpeedText(AValue: Integer): AnsiString;
    procedure RenderMain;
    procedure RenderOptions;
    procedure RenderObjectives(const AObjectives: AnsiString);
    procedure RenderRestart;
    procedure RenderGameOver(AResult: TWarLevelResult);
    procedure RenderQuit;
    procedure RenderDemoEnd;
  public
    /// <summary>Nothing is owned: the menu belongs to the scene</summary>
    constructor Create(const AImui: TWarImui; const APanels: TWarMapPanels; const AMenu: TWarMapMenu);
    /// <summary>
    ///   renderMenus: nothing if no menu is open. The backdrop covers the window (AWindowWidth x AWindowHeight), the text of
    ///   the objectives is the one of the map, the race is the one of the player
    /// </summary>
    procedure Render(ARace: TWarRace; AResult: TWarLevelResult; const AObjectives: AnsiString; AWindowWidth,
      AWindowHeight: Integer);
  end;

implementation

{ TWarMapMenuView }

constructor TWarMapMenuView.Create(const AImui: TWarImui; const APanels: TWarMapPanels; const AMenu: TWarMapMenu);
begin
  inherited Create;
  FImui := AImui;
  FPanels := APanels;
  FMenu := AMenu;
end;

procedure TWarMapMenuView.Backdrop(AWidth, AHeight: Integer);
var
  LArgs: TWarUiRectArgs;
begin
  // a translucent black over the whole window
  LArgs := TWarUiRectArgs.Default;
  LArgs.SizeX := AWidth;
  LArgs.SizeY := AHeight;
  LArgs.Color.R := 0;
  LArgs.Color.G := 0;
  LArgs.Color.B := 0;
  LArgs.Color.A := 150;
  FImui.Rect('menuBackdrop', LArgs);
end;

procedure TWarMapMenuView.Picture(const AId: AnsiString; AMessage: Boolean);
var
  LArgs: TWarUiImageArgs;
begin
  // imageResourceRefFromPlayer: the humans have the first image, the orcs the second
  LArgs := TWarUiImageArgs.Default;
  if AMessage then
  begin
    if FRace = wraHumans then
      LArgs.SpriteRef := 235
    else
      LArgs.SpriteRef := 236;
    LArgs.PositionX := FPanels.MessagePanel.X;
    LArgs.PositionY := FPanels.MessagePanel.Y;
  end
  else
  begin
    if FRace = wraHumans then
      LArgs.SpriteRef := 233
    else
      LArgs.SpriteRef := 234;
    LArgs.PositionX := FPanels.MenuPanel.X;
    LArgs.PositionY := FPanels.MenuPanel.Y;
  end;
  FImui.Image(AId, LArgs);
end;

procedure TWarMapMenuView.Title(const AId, AText: AnsiString; AMessage: Boolean);
begin
  // the header: the width of the panel, a line of 12, centered
  if AMessage then
    FImui.Text(AId, TWarUiWidgets.Caption(AText, FPanels.MessagePanel.X, FPanels.MessagePanel.Y + 10,
      FPanels.MessagePanel.Width, wtaCenter))
  else
    FImui.Text(AId, TWarUiWidgets.Caption(AText, FPanels.MenuPanel.X, FPanels.MenuPanel.Y + 10,
      FPanels.MenuPanel.Width, wtaCenter));
end;

function TWarMapMenuView.Button(const AId, AText: AnsiString; AX, AY: Single; AHotKey: TWarKey;
  ASmall: Boolean): Boolean;
var
  LBase: TWarRectF;
begin
  // the position is relative to the panel of the menu that is open (the message panel for the questions)
  if FDrawn in [wmsRestart, wmsGameOver, wmsQuit] then
    LBase := FPanels.MessagePanel
  else
    LBase := FPanels.MenuPanel;
  Result := FImui.TextButton(AId, TWarUiWidgets.MenuButton(AText, LBase.X + AX, LBase.Y + AY, AHotKey, ASmall));
end;

function TWarMapMenuView.Arrow(const AId: AnsiString; AX, AY: Single; ARight: Boolean): Boolean;
begin
  Result := FImui.ImageButton(AId, TWarUiWidgets.ArrowButton(FPanels.MenuPanel.X + AX, FPanels.MenuPanel.Y + AY, ARight));
end;

procedure TWarMapMenuView.Value(const AId, AText: AnsiString; AY: Single);
begin
  // the value of an option: centered in 42 pixels, 92 pixels from the left of the panel
  FImui.Text(AId, TWarUiWidgets.Caption(AText, FPanels.MenuPanel.X + 92, FPanels.MenuPanel.Y + AY, 42, wtaCenter));
end;

function TWarMapMenuView.SpeedText(AValue: Integer): AnsiString;
begin
  case AValue of
    WAR_SPEED_SLOWEST: Result := 'Slowest';
    WAR_SPEED_SLOW: Result := 'Slow';
    WAR_SPEED_NORMAL: Result := 'Normal';
    WAR_SPEED_FASTER: Result := 'Faster';
    WAR_SPEED_FASTEST: Result := 'Fastest';
  else
    Result := '';
  end;
end;

procedure TWarMapMenuView.RenderMain;
begin
  Picture('imgMenuBackground', False);
  Title('txtMenuHeader', 'Warcraft', False);
  // Save and Load are not implemented in the original: no handler (the menu has one if its host saves games)
  if Button('btnMenuSave', 'Save', 20, 25, wkS, True) then
    FMenu.SaveGame;
  if Button('btnMenuLoad', 'Load', 78, 25, wkL, True) then
    FMenu.LoadGame;
  if Button('btnMenuOptions', 'Options', 20, 45, wkO, False) then
    FMenu.OpenOptions;
  if Button('btnMenuObjectives', 'Objectives', 20, 65, wkJ, False) then
    FMenu.OpenObjectives;
  if Button('btnMenuRestart', 'Restart scenario', 20, 85, wkR, False) then
    FMenu.OpenRestart;
  if Button('btnMenuContinue', 'Continue', 20, 105, wkC, True) then
    FMenu.Resume;
  if Button('btnMenuQuit', 'Quit', 78, 105, wkQ, True) then
    FMenu.OpenQuit;
end;

procedure TWarMapMenuView.RenderOptions;
const
  LABELS: array[0..4] of AnsiString = ('Game Speed', 'Music Vol', 'SFX Vol', 'Mouse Scroll', 'Key Scroll');
  LABEL_Y: array[0..4] of Integer = (25, 42, 59, 76, 93);
var
  LIndex: Integer;
begin
  Picture('imgMenuBackground', False);
  Title('txtOptionsHeader', 'Options', False);
  // the labels: right aligned in 75 pixels
  for LIndex := 0 to 4 do
    FImui.Text(AnsiString('txtOptionsLabel' + IntToStr(LIndex)), TWarUiWidgets.Caption(LABELS[LIndex],
      FPanels.MenuPanel.X, FPanels.MenuPanel.Y + LABEL_Y[LIndex], 75, wtaRight));
  Value('txtOptionsGameSpeedValue', SpeedText(FMenu.Pending.GameSpeed), 25);
  Value('txtOptionsMusicVolValue', AnsiString(IntToStr(FMenu.Pending.MusicVolume)), 42);
  Value('txtOptionsSFXVolValue', AnsiString(IntToStr(FMenu.Pending.SoundVolume)), 59);
  Value('txtOptionsMouseScrollValue', SpeedText(FMenu.Pending.MouseScrollSpeed), 76);
  Value('txtOptionsKeyScrollValue', SpeedText(FMenu.Pending.KeyScrollSpeed), 93);
  // the arrows: the left one 76 pixels from the left, the right one 133
  if Arrow('btnOptionsGameSpeedDec', 76, 22, False) then
    FMenu.GameSpeedDown;
  if Arrow('btnOptionsGameSpeedInc', 133, 22, True) then
    FMenu.GameSpeedUp;
  if Arrow('btnOptionsMusicVolDec', 76, 39, False) then
    FMenu.MusicVolumeDown;
  if Arrow('btnOptionsMusicVolInc', 133, 39, True) then
    FMenu.MusicVolumeUp;
  if Arrow('btnOptionsSFXVolDec', 76, 56, False) then
    FMenu.SoundVolumeDown;
  if Arrow('btnOptionsSFXVolInc', 133, 56, True) then
    FMenu.SoundVolumeUp;
  if Arrow('btnOptionsMouseScrollDec', 76, 73, False) then
    FMenu.MouseScrollDown;
  if Arrow('btnOptionsMouseScrollInc', 133, 73, True) then
    FMenu.MouseScrollUp;
  if Arrow('btnOptionsKeyScrollDec', 76, 90, False) then
    FMenu.KeyScrollDown;
  if Arrow('btnOptionsKeyScrollInc', 133, 90, True) then
    FMenu.KeyScrollUp;
  if Button('btnOptionsOk', 'Ok', 20, 115, wkO, True) then
    FMenu.ApplyOptions;
  if Button('btnOptionsCancel', 'Cancel', 78, 115, wkC, True) then
    FMenu.Back;
end;

procedure TWarMapMenuView.RenderObjectives(const AObjectives: AnsiString);
var
  LText: TWarUiTextArgs;
begin
  Picture('imgMenuBackground', False);
  Title('txtObjectivesHeader', 'Objectives', False);
  LText := TWarUiTextArgs.Default;
  LText.PositionX := FPanels.MenuPanel.X + 10;
  LText.PositionY := FPanels.MenuPanel.Y + 26;
  LText.FontIndex := 1;
  LText.Multiline := True;
  LText.BoundingsX := FPanels.MenuPanel.Width - 20;
  LText.BoundingsY := 75;
  LText.Wrapping := wtwChar;
  LText.Trimming := wttSpaces;
  LText.Text := AObjectives;
  FImui.Text('txtObjectivesText', LText);
  if Button('btnObjectivesMenu', 'Menu', 20, 105, wkM, False) then
    FMenu.Back;
end;

procedure TWarMapMenuView.RenderRestart;
begin
  Picture('imgMessageMenuBackground', True);
  Title('txtRestartText', 'Are you sure you want to restart?', True);
  if Button('btnRestartRestart', 'Restart', 20, 25, wkR, True) then
    FMenu.Restart;
  if Button('btnRestartCancel', 'Cancel', 210, 25, wkC, True) then
    FMenu.Back;
end;

procedure TWarMapMenuView.RenderGameOver(AResult: TWarLevelResult);
begin
  Picture('imgMessageMenuBackground', True);
  // "archieve" is in the original
  if AResult = wlrWin then
    Title('txtGameOverText', 'You are victorious!', True)
  else
    Title('txtGameOverText', 'You failed to archieve victory...', True);
  if AResult = wlrWin then
  begin
    if Button('btnGameOverSave', 'Save', 20, 25, wkS, True) then
      FMenu.SaveAfterGameOver;
    if Button('btnGameOverContinue', 'Continue', 210, 25, wkC, True) then
      FMenu.ContinueAfterGameOver;
  end
  else
  begin
    if Button('btnGameOverOk', 'Ok', 116, 25, wkO, True) then
      FMenu.ContinueAfterGameOver;
  end;
end;

procedure TWarMapMenuView.RenderQuit;
begin
  Picture('imgMessageMenuBackground', True);
  Title('txtQuitText', 'Are you sure you want to quit?', True);
  if Button('btnQuitQuit', 'Quit', 20, 25, wkQ, True) then
    FMenu.QuitGame;
  if Button('btnQuitMenu', 'Menu', 115, 25, wkM, True) then
    FMenu.ReturnToMainMenu;
  if Button('btnQuitCancel', 'Cancel', 210, 25, wkC, True) then
    FMenu.Back;
end;

procedure TWarMapMenuView.RenderDemoEnd;
var
  LText: TWarUiTextArgs;
begin
  Picture('imgMenuBackground', False);
  Title('txtDemoEndHeader', 'Thanks for playing!', False);
  LText := TWarUiTextArgs.Default;
  LText.PositionX := FPanels.MenuPanel.X + 8;
  LText.PositionY := FPanels.MenuPanel.Y + 26;
  LText.FontIndex := 1;
  LText.FontSize := 7;
  LText.Multiline := True;
  LText.BoundingsX := FPanels.MenuPanel.Width - 16;
  LText.BoundingsY := 75;
  LText.Wrapping := wtwChar;
  LText.Text := 'This is a non-profit project with'#10 + 'the personal goal of learning to'#10 + 'do RTS engines'#10#10 +
    'This is not an official Blizzard'#10 + 'product. Warcraft and all assets'#10 + 'you see are registered trademarks'#10 +
    'of Blizzard Entertainment.'#10#10 + 'Made by @acoro87';
  FImui.Text('txtDemoEndText', LText);
  if Button('btnDemoEndMenu', 'Menu', 20, 105, wkM, False) then
    FMenu.ReturnToMainMenu;
end;

procedure TWarMapMenuView.Render(ARace: TWarRace; AResult: TWarLevelResult; const AObjectives: AnsiString;
  AWindowWidth, AWindowHeight: Integer);
begin
  if FMenu.State = wmsNone then
    Exit;
  FRace := ARace;
  Backdrop(AWindowWidth, AWindowHeight);
  // the menu that was open when the drawing began is the one that is drawn, whatever its buttons do to the state
  FDrawn := FMenu.State;
  case FDrawn of
    wmsMain: RenderMain;
    wmsOptions: RenderOptions;
    wmsObjectives: RenderObjectives(AObjectives);
    wmsRestart: RenderRestart;
    wmsGameOver: RenderGameOver(AResult);
    wmsQuit: RenderQuit;
    wmsDemoEnd: RenderDemoEnd;
  end;
end;

end.
