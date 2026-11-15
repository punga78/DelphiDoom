{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the camera of the map                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (map->camera, updateViewport, the     }
{  wmap_*Coordinates functions), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Camera;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Render.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types;

type
  /// <summary>What updateViewport reads besides the input: the state of the commands and of the cheat panel of the map</summary>
  TWarCameraContext = record
    /// <summary>The map is being dragged (a rectangle of selection)</summary>
    Dragging: Boolean;
    /// <summary>map->commandState.command.type != WAR_COMMAND_NONE</summary>
    CommandActive: Boolean;
    /// <summary>cheatStatus.enabled and visible</summary>
    CheatsOpen: Boolean;
    /// <summary>context->originalWindowWidth and Height</summary>
    ScreenWidth: Single;
    ScreenHeight: Single;
    RealDeltaTime: Single;
    /// <summary>map->settings.mouseScrollSpeed and keyScrollSpeed (a level of WarMapSpeed)</summary>
    MouseScrollSpeed: Integer;
    KeyScrollSpeed: Integer;
  end;

  /// <summary>
  ///   map->camera: the window on the map in pixels of the map, with floating point numbers (the scroll adds a Single
  ///   each frame), and the coordinates that go from the screen to the map and back. All the operations are Single
  ///   operations, one at a time, rounded as the original rounds them
  /// </summary>
  TWarMapCamera = class
  strict private
    FPanels: TWarMapPanels;
    FX: Single;
    FY: Single;
    FWidth: Single;
    FHeight: Single;
    FIsScrolling: Boolean;
    FWasScrolling: Boolean;
    class procedure Normalize(var AX, AY: Single); static;
  public
    constructor Create(const APanels: TWarMapPanels; AStartX, AStartY: Integer);
    /// <summary>wmap_getDirFromArrowKeys</summary>
    class procedure DirFromArrowKeys(const AInput: IWarUiInput; out AX, AY: Single); static;
    /// <summary>wmap_getDirFromMousePos: the edge of the screen scrolls</summary>
    class procedure DirFromMousePosition(const AInput: IWarUiInput; AScreenWidth, AScreenHeight: Single;
      out AX, AY: Single); static;
    /// <summary>wmap_getMapScrollSpeed</summary>
    class function ScrollSpeed(ALevel: Integer): Single; static;
    /// <summary>
    ///   updateViewport: a click on the minimap moves the window, else the mouse at an edge or the arrow keys scroll it.
    ///   ASuppressMinimap is map->commandState.suppressMinimapViewportOnRelease
    /// </summary>
    procedure Update(const AInput: IWarUiInput; const AContext: TWarCameraContext; var ASuppressMinimap: Boolean);
    /// <summary>wmap_screenToMapCoordinatesV</summary>
    procedure ScreenToMap(AX, AY: Single; out AMapX, AMapY: Single);
    /// <summary>wmap_mapToScreenCoordinatesV</summary>
    procedure MapToScreen(AX, AY: Single; out AScreenX, AScreenY: Single);
    /// <summary>wmap_mapToTileCoordinatesV</summary>
    class procedure MapToTile(AX, AY: Single; out ATileX, ATileY: Single); static;
    /// <summary>wmap_tileToMapCoordinatesV</summary>
    class procedure TileToMap(ATileX, ATileY: Single; ACentered: Boolean; out AMapX, AMapY: Single); static;
    property X: Single read FX write FX;
    property Y: Single read FY write FY;
    property Width: Single read FWidth;
    property Height: Single read FHeight;
    property IsScrolling: Boolean read FIsScrolling write FIsScrolling;
    property WasScrolling: Boolean read FWasScrolling;
    property Panels: TWarMapPanels read FPanels;
  end;

implementation

const
  MAP_EDGE_SCROLL_GAP: Single = 5.0;
  // MINIMAP_VIEWPORT_WIDTH and HEIGHT: the size of the window on the minimap (15 x 11)
  MINIMAP_VIEWPORT_WIDTH: Single = 15.0;
  MINIMAP_VIEWPORT_HEIGHT: Single = 11.0;

{ TWarMapCamera }

constructor TWarMapCamera.Create(const APanels: TWarMapPanels; AStartX, AStartY: Integer);
begin
  inherited Create;
  FPanels := APanels;
  FX := AStartX;
  FY := AStartY;
  FWidth := WAR_MAP_VIEWPORT_WIDTH;
  FHeight := WAR_MAP_VIEWPORT_HEIGHT;
end;

class procedure TWarMapCamera.Normalize(var AX, AY: Single);
var
  LSquare: Single;
  LLength: Single;
  LInverse: Single;
begin
  // vec2_normalize: sqrtf(x * x + y * y), then each part times 1 / length (nothing for a zero vector)
  LSquare := AX * AX;
  LLength := AY * AY;
  LLength := LSquare + LLength;
  LLength := Sqrt(LLength);
  if LLength <> 0 then
  begin
    LInverse := 1 / LLength;
    AX := AX * LInverse;
    AY := AY * LInverse;
  end
  else
  begin
    AX := 0;
    AY := 0;
  end;
end;

class procedure TWarMapCamera.DirFromArrowKeys(const AInput: IWarUiInput; out AX, AY: Single);
begin
  AX := 0;
  AY := 0;
  if AInput.IsKeyHeld(wkLeft) then
    AX := -1
  else if AInput.IsKeyHeld(wkRight) then
    AX := 1;
  if AInput.IsKeyHeld(wkDown) then
    AY := 1
  else if AInput.IsKeyHeld(wkUp) then
    AY := -1;
  Normalize(AX, AY);
end;

class procedure TWarMapCamera.DirFromMousePosition(const AInput: IWarUiInput; AScreenWidth, AScreenHeight: Single;
  out AX, AY: Single);
var
  LLimit: Single;
begin
  AX := 0;
  AY := 0;
  if AInput.PositionX < MAP_EDGE_SCROLL_GAP then
    AX := -1
  else
  begin
    LLimit := AScreenWidth - MAP_EDGE_SCROLL_GAP;
    if AInput.PositionX > LLimit then
      AX := 1;
  end;
  if AInput.PositionY < MAP_EDGE_SCROLL_GAP then
    AY := -1
  else
  begin
    LLimit := AScreenHeight - MAP_EDGE_SCROLL_GAP;
    if AInput.PositionY > LLimit then
      AY := 1;
  end;
  Normalize(AX, AY);
end;

class function TWarMapCamera.ScrollSpeed(ALevel: Integer): Single;
var
  LValue: Single;
begin
  LValue := ALevel;
  LValue := LValue * 50;
  Result := 100 + LValue;
end;

procedure TWarMapCamera.Update(const AInput: IWarUiInput; const AContext: TWarCameraContext;
  var ASuppressMinimap: Boolean);
var
  LDirX: Single;
  LDirY: Single;
  LWasScrolling: Boolean;
  LMouseScroll: Boolean;
  LKeyScroll: Boolean;
  LOffsetX: Single;
  LOffsetY: Single;
  LLimitX: Single;
  LLimitY: Single;
  LSpeed: Single;
  LStep: Single;
  LMaxX: Single;
  LMaxY: Single;
begin
  FWasScrolling := False;
  if ASuppressMinimap then
  begin
    FIsScrolling := False;
    if not AInput.IsButtonHeld(wmbLeft) then
      ASuppressMinimap := False;
    Exit;
  end;
  LDirX := 0;
  LDirY := 0;
  LWasScrolling := FIsScrolling;
  LMouseScroll := False;
  LKeyScroll := False;
  // with the left button held and no command the window follows a click on the minimap and nothing else moves it
  // (not the edges of the screen, not the keys: a defect of the original kept)
  if AInput.IsButtonHeld(wmbLeft) and (not AContext.CommandActive) then
  begin
    if WarRectContains(FPanels.MinimapPanel, AInput.PositionX, AInput.PositionY) then
    begin
      LOffsetX := AInput.PositionX - FPanels.MinimapPanel.X;
      LOffsetY := AInput.PositionY - FPanels.MinimapPanel.Y;
      // wmap_minimapToViewportCoordinatesV: the middle of the window on the click, inside the panel
      LOffsetX := LOffsetX + (-MINIMAP_VIEWPORT_WIDTH / 2);
      LOffsetY := LOffsetY + (-MINIMAP_VIEWPORT_HEIGHT / 2);
      LLimitX := FPanels.MinimapPanel.Width - MINIMAP_VIEWPORT_WIDTH;
      LLimitY := FPanels.MinimapPanel.Height - MINIMAP_VIEWPORT_HEIGHT;
      LOffsetX := Max(Min(LOffsetX, LLimitX), 0);
      LOffsetY := Max(Min(LOffsetY, LLimitY), 0);
      LStep := LOffsetX * WAR_MAPUI_MAP_PIXELS;
      FX := LStep / 64;
      LStep := LOffsetY * WAR_MAPUI_MAP_PIXELS;
      FY := LStep / 64;
    end;
  end
  else
  begin
    if not AContext.Dragging then
    begin
      DirFromMousePosition(AInput, AContext.ScreenWidth, AContext.ScreenHeight, LDirX, LDirY);
      LMouseScroll := (LDirX <> 0) or (LDirY <> 0);
    end;
    // no scroll with the arrow keys if Control or Shift are held or the cheat panel is open
    if (not LMouseScroll) and (not AInput.IsKeyHeld(wkCtrl)) and (not AInput.IsKeyHeld(wkShift)) and
      (not AContext.CheatsOpen) then
    begin
      DirFromArrowKeys(AInput, LDirX, LDirY);
      LKeyScroll := (LDirX <> 0) or (LDirY <> 0);
    end;
  end;
  FIsScrolling := (LDirX <> 0) or (LDirY <> 0);
  if FIsScrolling then
  begin
    LSpeed := 0;
    if LMouseScroll then
      LSpeed := ScrollSpeed(AContext.MouseScrollSpeed)
    else if LKeyScroll then
      LSpeed := ScrollSpeed(AContext.KeyScrollSpeed);
    LMaxX := WAR_MAPUI_MAP_PIXELS - FWidth;
    LMaxY := WAR_MAPUI_MAP_PIXELS - FHeight;
    LStep := LSpeed * LDirX;
    LStep := LStep * AContext.RealDeltaTime;
    FX := FX + LStep;
    FX := Max(Min(FX, LMaxX), 0);
    LStep := LSpeed * LDirY;
    LStep := LStep * AContext.RealDeltaTime;
    FY := FY + LStep;
    FY := Max(Min(FY, LMaxY), 0);
  end
  else
    FWasScrolling := LWasScrolling;
end;

procedure TWarMapCamera.ScreenToMap(AX, AY: Single; out AMapX, AMapY: Single);
var
  LX: Single;
  LY: Single;
begin
  LX := AX + (-FPanels.MapPanel.X);
  LY := AY + (-FPanels.MapPanel.Y);
  AMapX := LX + FX;
  AMapY := LY + FY;
end;

procedure TWarMapCamera.MapToScreen(AX, AY: Single; out AScreenX, AScreenY: Single);
var
  LX: Single;
  LY: Single;
begin
  LX := AX + (-FX);
  LY := AY + (-FY);
  AScreenX := LX + FPanels.MapPanel.X;
  AScreenY := LY + FPanels.MapPanel.Y;
end;

class procedure TWarMapCamera.MapToTile(AX, AY: Single; out ATileX, ATileY: Single);
var
  LValue: Single;
begin
  LValue := AX / WAR_MODEL_MEGA_TILE;
  ATileX := Floor(LValue);
  LValue := AY / WAR_MODEL_MEGA_TILE;
  ATileY := Floor(LValue);
end;

class procedure TWarMapCamera.TileToMap(ATileX, ATileY: Single; ACentered: Boolean; out AMapX, AMapY: Single);
begin
  AMapX := ATileX * WAR_MODEL_MEGA_TILE;
  AMapY := ATileY * WAR_MODEL_MEGA_TILE;
  if ACentered then
  begin
    AMapX := AMapX + 8;
    AMapY := AMapY + 8;
  end;
end;

end.
