{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the panels and the HUD of the map                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map_ui.c (renderStaticPanels, renderHUD),   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Hud;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Imui, DelphiDoom.War.MapUi.Types;

type
  /// <summary>One of the first four selected entities as the information panel shows it (a missing entity is not Valid)</summary>
  TWarHudSelected = record
    Valid: Boolean;
    UnitType: Integer;
    Hp: Integer;
    MaxHp: Integer;
    Mana: Integer;
    MaxMana: Integer;
    IsDude: Boolean;
    IsMagic: Boolean;
    IsBuilding: Boolean;
    /// <summary>unit->building: a building that is being built</summary>
    UnderConstruction: Boolean;
    BuildPercent: Single;
  end;

  /// <summary>What renderHUD reads and does not draw by itself: the player, the panel, the status line and the cheat panel</summary>
  TWarHudView = record
    Race: TWarRace;
    Gold: Integer;
    Wood: Integer;
    /// <summary>MIN(selected, 4): how many of Selected are in use</summary>
    SelectedCount: Integer;
    Selected: array[0..3] of TWarHudSelected;
    Panel: TWarCommandPanel;
    Status: TWarStatusLine;
    /// <summary>map->menuState != WAR_MENU_STATE_NONE</summary>
    MenuOpen: Boolean;
    /// <summary>cheatStatus.enabled and visible: the hot keys of the buttons are off</summary>
    CheatsOpen: Boolean;
    /// <summary>cheatStatus->cursorX: where the cursor of the cheat line is in the bottom panel, negative for none</summary>
    CheatCursorX: Single;
    /// <summary>The feedback of the last cheat, while it lasts (an empty text is none)</summary>
    CheatFeedback: AnsiString;
    /// <summary>The debug text, shown when there is no feedback (an empty text is none)</summary>
    CheatDebugText: AnsiString;
    /// <summary>originalWindowWidth and originalWindowHeight: the box of the debug text</summary>
    OriginalWidth: Integer;
    OriginalHeight: Integer;
  end;

  /// <summary>What was clicked in the HUD this frame (the buttons answer the frame they are clicked)</summary>
  TWarHudClicks = record
    /// <summary>The index of the button of the command panel that was clicked, -1 if none</summary>
    Command: Integer;
    Menu: Boolean;
  end;

  /// <summary>
  ///   The panels of the interface of the map and the HUD, drawn with the immediate interface as the original does: the
  ///   ids of the items are the strings of the original (the buttons keep their state by them)
  /// </summary>
  TWarMapHud = class
  strict private
    FImui: TWarImui;
    FPanels: TWarMapPanels;
    function ByRace(ARace: TWarRace; AHumans, AOrcs: Integer): Integer;
    procedure DrawImage(const AId: AnsiString; AResource: Integer; AX, AY: Single);
    procedure DrawText(const AId, AText: AnsiString; AX, AY: Single; AHighlightIndex, AHighlightCount: Integer);
    procedure DrawRect(const AId: AnsiString; AX, AY: Single; AWidth, AHeight: Integer; const AColor: TWarRgba);
    procedure DrawFrame(const AId: AnsiString; AResource: Integer; AX, AY: Single; AFrame: Integer);
    function LifeColor(APercent: Single): TWarRgba;
    procedure RenderSelectionInfo(const AView: TWarHudView);
    procedure RenderCheatLine(const AView: TWarHudView);
  public
    constructor Create(const AImui: TWarImui; const APanels: TWarMapPanels);
    /// <summary>renderStaticPanels: the frame of the interface and the two icons of the resources</summary>
    procedure RenderStaticPanels(ARace: TWarRace);
    /// <summary>renderHUD (without the information of the selection, which RenderSelectionInfo draws first)</summary>
    procedure RenderHud(const AView: TWarHudView; out AClicks: TWarHudClicks);
  end;

implementation

uses
  DelphiDoom.War.MapUi.UnitNames.Data;

{ TWarMapHud }

constructor TWarMapHud.Create(const AImui: TWarImui; const APanels: TWarMapPanels);
begin
  inherited Create;
  FImui := AImui;
  FPanels := APanels;
end;

function TWarMapHud.ByRace(ARace: TWarRace; AHumans, AOrcs: Integer): Integer;
begin
  // imageResourceRefFromPlayer
  if ARace = wraHumans then
    Result := AHumans
  else
    Result := AOrcs;
end;

procedure TWarMapHud.DrawImage(const AId: AnsiString; AResource: Integer; AX, AY: Single);
var
  LArgs: TWarUiImageArgs;
begin
  LArgs := TWarUiImageArgs.Default;
  LArgs.SpriteRef := AResource;
  LArgs.PositionX := AX;
  LArgs.PositionY := AY;
  FImui.Image(AId, LArgs);
end;

procedure TWarMapHud.DrawText(const AId, AText: AnsiString; AX, AY: Single; AHighlightIndex, AHighlightCount: Integer);
var
  LArgs: TWarUiTextArgs;
begin
  LArgs := TWarUiTextArgs.Default;
  LArgs.PositionX := AX;
  LArgs.PositionY := AY;
  LArgs.FontSize := 6;
  LArgs.HighlightIndex := AHighlightIndex;
  LArgs.HighlightCount := AHighlightCount;
  LArgs.Text := AText;
  FImui.Text(AId, LArgs);
end;

procedure TWarMapHud.DrawRect(const AId: AnsiString; AX, AY: Single; AWidth, AHeight: Integer; const AColor: TWarRgba);
var
  LArgs: TWarUiRectArgs;
begin
  LArgs := TWarUiRectArgs.Default;
  LArgs.PositionX := AX;
  LArgs.PositionY := AY;
  LArgs.SizeX := AWidth;
  LArgs.SizeY := AHeight;
  LArgs.Color := AColor;
  FImui.Rect(AId, LArgs);
end;

procedure TWarMapHud.DrawFrame(const AId: AnsiString; AResource: Integer; AX, AY: Single; AFrame: Integer);
var
  LArgs: TWarUiImageArgs;
begin
  LArgs := TWarUiImageArgs.Default;
  LArgs.SpriteRef := AResource;
  LArgs.PositionX := AX;
  LArgs.PositionY := AY;
  FImui.ImageFrame(AId, LArgs, AFrame);
end;

function TWarMapHud.LifeColor(APercent: Single): TWarRgba;
const
  RED_THRESHOLD: Single = 0.35;
  YELLOW_THRESHOLD: Single = 0.70;
begin
  // the bar is green, yellow (a cyan: see WAR_COLOR_YELLOW) up to 70 percent, red up to 35
  Result := WAR_MAPUI_GREEN;
  if APercent <= RED_THRESHOLD then
    Result := WAR_MAPUI_RED
  else if APercent <= YELLOW_THRESHOLD then
    Result := WAR_COLOR_YELLOW;
end;

function UnitNameOf(AUnitType: Integer): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(WAR_UNIT_NAMES) do
    if WAR_UNIT_NAMES[LIndex].UnitType = AUnitType then
      Exit(WAR_UNIT_NAMES[LIndex].Name);
end;

function PortraitOf(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(WAR_UNIT_NAMES) do
    if WAR_UNIT_NAMES[LIndex].UnitType = AUnitType then
      Exit(WAR_UNIT_NAMES[LIndex].Portrait);
end;

procedure TWarMapHud.RenderSelectionInfo(const AView: TWarHudView);
const
  PORTRAIT_X: array[1..4] of Integer = (4, 38, 4, 38);
  PORTRAIT_Y: array[1..4] of Integer = (1, 1, 23, 23);
  LIFE_X: array[1..4] of Integer = (4, 38, 4, 38);
  LIFE_Y: array[1..4] of Integer = (17, 17, 39, 39);
var
  LBottom: TWarRectF;
  LSelected: TWarHudSelected;
  LFrame: Integer;
  LIndex: Integer;
  LPercent: Single;
  LStep: Single;
  LBackground: Integer;
begin
  LBottom := FPanels.LeftBottom;
  LBackground := ByRace(AView.Race, 360, 359);
  if AView.SelectedCount = 1 then
  begin
    LSelected := AView.Selected[0];
    if not LSelected.Valid then
      Exit;
    // the background by what is selected: 0 a unit, 1 a unit that casts, 2 a building under construction
    LFrame := 0;
    if LSelected.IsDude and LSelected.IsMagic then
      LFrame := 1
    else if LSelected.IsBuilding and LSelected.UnderConstruction then
      LFrame := 2;
    DrawFrame('imgUnitInfo', LBackground, LBottom.X + 2, LBottom.Y + 0, LFrame);
    DrawFrame('imgUnitPortrait0', 361, LBottom.X + 6, LBottom.Y + 4, PortraitOf(LSelected.UnitType));
    DrawText('txtUnitName', UnitNameOf(LSelected.UnitType), LBottom.X + 6, LBottom.Y + 26, WAR_NO_HIGHLIGHT, 0);
    LPercent := Single(LSelected.Hp) / LSelected.MaxHp;
    LStep := LPercent * 27;
    DrawRect('rectLifeBar0', LBottom.X + 37, LBottom.Y + 20, Trunc(LStep), 3, LifeColor(LPercent));
    if LSelected.IsDude and LSelected.IsMagic then
    begin
      LPercent := Single(LSelected.Mana) / LSelected.MaxMana;
      LStep := LPercent * 27;
      DrawRect('rectMagicBar', LBottom.X + 37, LBottom.Y + 9, Trunc(LStep), 3, WAR_MAPUI_GREEN);
    end;
    if LSelected.IsBuilding and LSelected.UnderConstruction then
    begin
      LStep := LSelected.BuildPercent * 64;
      DrawRect('rectPercentBar', LBottom.X + 4, LBottom.Y + 37, Trunc(LStep), 5, WAR_MAPUI_GREEN);
      DrawFrame('rectPercentText', 410, LBottom.X + 15, LBottom.Y + 37, 0);
    end;
  end
  else if AView.SelectedCount > 1 then
  begin
    DrawFrame('imgUnitInfo', LBackground, LBottom.X + 2, LBottom.Y + 0, AView.SelectedCount + 1);
    DrawFrame('imgUnitInfoLife', LBackground, LBottom.X + 3, LBottom.Y + 16, AView.SelectedCount + 4);
    for LIndex := 1 to AView.SelectedCount do
    begin
      LSelected := AView.Selected[LIndex - 1];
      if not LSelected.Valid then
        Continue;
      DrawFrame(AnsiString('imgUnitPortrait' + IntToStr(LIndex)), 361, LBottom.X + PORTRAIT_X[LIndex],
        LBottom.Y + PORTRAIT_Y[LIndex], PortraitOf(LSelected.UnitType));
      LPercent := Single(LSelected.Hp) / LSelected.MaxHp;
      LStep := LPercent * 27;
      DrawRect(AnsiString('rectLifeBar' + IntToStr(LIndex)), LBottom.X + LIFE_X[LIndex], LBottom.Y + LIFE_Y[LIndex],
        Trunc(LStep), 3, LifeColor(LPercent));
    end;
  end;
end;

procedure TWarMapHud.RenderStaticPanels(ARace: TWarRace);
var
  LTop: Single;
begin
  DrawImage('panelLeftTop', ByRace(ARace, 224, 225), FPanels.LeftTop.X, FPanels.LeftTop.Y);
  DrawImage('panelLeftBottom', ByRace(ARace, 226, 227), FPanels.LeftBottom.X, FPanels.LeftBottom.Y);
  DrawImage('panelTop', ByRace(ARace, 218, 219), FPanels.TopPanel.X, FPanels.TopPanel.Y);
  DrawImage('panelRight', ByRace(ARace, 220, 221), FPanels.RightPanel.X, FPanels.RightPanel.Y);
  DrawImage('panelBottom', ByRace(ARace, 222, 223), FPanels.BottomPanel.X, FPanels.BottomPanel.Y);
  LTop := FPanels.TopPanel.X + 201;
  DrawImage('imgGold', 406, LTop, FPanels.TopPanel.Y + 1);
  LTop := FPanels.TopPanel.X + 102;
  DrawImage('imgLumber', 407, LTop, FPanels.TopPanel.Y + 0);
end;

procedure TWarMapHud.RenderHud(const AView: TWarHudView; out AClicks: TWarHudClicks);
const
  COMMAND_X: array[0..5] of Integer = (2, 36, 2, 36, 2, 36);
  COMMAND_Y: array[0..5] of Integer = (44, 44, 67, 67, 90, 90);
  TEXT_X: array[0..3] of Integer = (3, 3, 7, 11);
  TEXT_Y: array[0..3] of Integer = (46, 56, 64, 54);
var
  LIndex: Integer;
  LImageButton: TWarUiImageButtonArgs;
begin
  AClicks.Command := -1;
  AClicks.Menu := False;
  // the hot keys are off while the cheat panel is open, so the keys of the cheats do not give orders
  if AView.CheatsOpen then
    FImui.HotkeysEnabled := False;
  DrawText('txtGold', AnsiString(Format('GOLD:%6d', [AView.Gold])), FPanels.TopPanel.X + 135, FPanels.TopPanel.Y + 2,
    WAR_NO_HIGHLIGHT, 0);
  DrawText('txtWood', AnsiString(Format('LUMBER:%6d', [AView.Wood])), FPanels.TopPanel.X + 24,
    FPanels.TopPanel.Y + 2, WAR_NO_HIGHLIGHT, 0);
  // the information of what is selected
  RenderSelectionInfo(AView);
  // the command panel (only when no menu is open)
  if not AView.MenuOpen then
  begin
    for LIndex := 0 to 5 do
    begin
      if not AView.Panel.SlotsActive[LIndex] then
        Continue;
      LImageButton := TWarUiImageButtonArgs.Default;
      LImageButton.BackgroundNormal := 364;
      LImageButton.BackgroundPressed := 365;
      LImageButton.Foreground := 361;
      LImageButton.ForegroundFrameIndex := AView.Panel.Slots[LIndex].FrameIndex;
      LImageButton.PositionX := FPanels.LeftBottom.X + COMMAND_X[LIndex];
      LImageButton.PositionY := FPanels.LeftBottom.Y + COMMAND_Y[LIndex];
      LImageButton.HotKey := AView.Panel.Slots[LIndex].HotKey;
      LImageButton.Tooltip := AView.Panel.Slots[LIndex].Tooltip;
      LImageButton.TooltipHighlightIndex := AView.Panel.Slots[LIndex].HighlightIndex;
      LImageButton.TooltipHighlightCount := AView.Panel.Slots[LIndex].HighlightCount;
      LImageButton.Gold := AView.Panel.Slots[LIndex].Gold;
      LImageButton.Wood := AView.Panel.Slots[LIndex].Wood;
      if FImui.ImageButton(AnsiString('btnCommand' + IntToStr(LIndex)), LImageButton) then
        AClicks.Command := LIndex;
    end;
    for LIndex := 0 to 3 do
    begin
      if not AView.Panel.TextsVisible[LIndex] then
        Continue;
      DrawText(AnsiString('txtCommand' + IntToStr(LIndex)), AView.Panel.Texts[LIndex],
        FPanels.LeftBottom.X + TEXT_X[LIndex], FPanels.LeftBottom.Y + TEXT_Y[LIndex],
        AView.Panel.TextsHighlightIndex[LIndex], AView.Panel.TextsHighlightCount[LIndex]);
    end;
    // the menu button
    LImageButton := TWarUiImageButtonArgs.Default;
    LImageButton.BackgroundNormal := 362;
    LImageButton.BackgroundPressed := 363;
    LImageButton.PositionX := FPanels.LeftBottom.X + 3;
    LImageButton.PositionY := FPanels.LeftBottom.Y + 116;
    LImageButton.HotKey := wkF10;
    LImageButton.Tooltip := 'MENU (F10)';
    LImageButton.TooltipHighlightIndex := 6;
    LImageButton.TooltipHighlightCount := 3;
    if FImui.ImageButton('btnMenu', LImageButton) then
      AClicks.Menu := True;
  end;
  // the status line is the tooltip when the mouse is not on a button that has one
  if (not FImui.ShowTooltip) and (AView.Status.Text <> '') then
    FImui.DeferTooltip(AView.Status.Text, AView.Status.HighlightIndex, AView.Status.HighlightCount, AView.Status.Gold,
      AView.Status.Wood);
  RenderCheatLine(AView);
end;

procedure TWarMapHud.RenderCheatLine(const AView: TWarHudView);
var
  LText: TWarUiTextArgs;
begin
  // the cursor of the cheat line (a rectangle of 1 x 7 where the typing goes), while the line is open
  if AView.CheatsOpen and (AView.CheatCursorX >= 0) then
    DrawRect('rectStatusCursor', FPanels.BottomPanel.X + AView.CheatCursorX, FPanels.BottomPanel.Y + 4, 1, 7,
      WAR_COLOR_WHITE);
  // the feedback of the cheat (in a cyan: see WAR_COLOR_YELLOW), or the debug text when there is no feedback
  if AView.CheatFeedback <> '' then
  begin
    LText := TWarUiTextArgs.Default;
    LText.PositionX := FPanels.BottomPanel.X + 15;
    LText.PositionY := FPanels.BottomPanel.Y - 20;
    LText.FontIndex := 1;
    LText.FontSize := 8;
    LText.FontColor := WAR_COLOR_YELLOW;
    LText.Text := AView.CheatFeedback;
    FImui.Text('txtCheatFeedback', LText);
  end
  else if AView.CheatDebugText <> '' then
  begin
    LText := TWarUiTextArgs.Default;
    LText.PositionX := FPanels.BottomPanel.X + 15;
    LText.PositionY := FPanels.BottomPanel.Y - 36;
    LText.BoundingsX := AView.OriginalWidth - 15;
    LText.BoundingsY := AView.OriginalHeight;
    LText.FontIndex := 1;
    LText.FontSize := 6;
    LText.FontColor := WAR_COLOR_YELLOW;
    LText.Multiline := True;
    LText.Text := AView.CheatDebugText;
    FImui.Text('txtDebugFeedback', LText);
  end;
end;

end.
