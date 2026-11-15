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
  /// <summary>What renderHUD reads and does not draw by itself: the player, the panel, the status line and the cheat panel</summary>
  TWarHudView = record
    Race: TWarRace;
    Gold: Integer;
    Wood: Integer;
    Panel: TWarCommandPanel;
    Status: TWarStatusLine;
    /// <summary>map->menuState != WAR_MENU_STATE_NONE</summary>
    MenuOpen: Boolean;
    /// <summary>cheatStatus.enabled and visible: the hot keys of the buttons are off</summary>
    CheatsOpen: Boolean;
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
  public
    constructor Create(const AImui: TWarImui; const APanels: TWarMapPanels);
    /// <summary>renderStaticPanels: the frame of the interface and the two icons of the resources</summary>
    procedure RenderStaticPanels(ARace: TWarRace);
    /// <summary>renderHUD (without the information of the selection, which RenderSelectionInfo draws first)</summary>
    procedure RenderHud(const AView: TWarHudView; out AClicks: TWarHudClicks);
  end;

implementation

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
end;

end.
