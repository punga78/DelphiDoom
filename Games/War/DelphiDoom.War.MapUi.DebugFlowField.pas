{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of the flow field                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (updateFlowFieldDebug,               }
{  renderFlowField), (c) 2019 Alejandro Coto Gutierrez, zlib License (see      }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugFlowField;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Path.FlowField, DelphiDoom.War.Path.Intf, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.MapUi.Camera;

type
  /// <summary>
  ///   The flag "flow-field": a click of the left button on the map (with the flag on) makes the flow field of the tile that
  ///   was clicked and keeps it; the field is the one the units keep for that goal (it is made again in place), so it changes
  ///   when a unit goes to that tile. Every tile of the window that is not static and has a direction gets an arrow of a
  ///   shaft and two strokes of a head, in cyan; the goal and the tiles with no direction have none
  /// </summary>
  TWarDebugFlowField = class
  strict private
    FTransform: TWarRenderTransform;
    FGrid: TWarPathGrid;
    FFlags: IWarDebugRender;
    FCamera: TWarMapCamera;
    FSource: IWarFlowFieldSource;
    FField: TWarFlowField;
    FGoalX: Integer;
    FGoalY: Integer;
  public
    /// <summary>The source may be nil (no flow fields: the click does nothing); nothing is owned</summary>
    constructor Create(const ATransform: TWarRenderTransform; const AGrid: TWarPathGrid; const AFlags: IWarDebugRender;
      const ACamera: TWarMapCamera; const ASource: IWarFlowFieldSource);
    /// <summary>updateFlowFieldDebug</summary>
    procedure Update(const AInput: IWarUiInput);
    /// <summary>renderFlowField</summary>
    procedure Render;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Path.Types, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.DebugArrow;

const
  // the cyan of WAR_COLOR_RGB(0, 255, 255)
  ARROW_COLOR: TWarRgba = (R: 0; G: 255; B: 255; A: 255);
  // MEGA_TILE_WIDTH * 0.35f
  SHAFT_FACTOR: Single = 0.35;

{ TWarDebugFlowField }

constructor TWarDebugFlowField.Create(const ATransform: TWarRenderTransform; const AGrid: TWarPathGrid;
  const AFlags: IWarDebugRender; const ACamera: TWarMapCamera; const ASource: IWarFlowFieldSource);
begin
  inherited Create;
  FTransform := ATransform;
  FGrid := AGrid;
  FFlags := AFlags;
  FCamera := ACamera;
  FSource := ASource;
end;

procedure TWarDebugFlowField.Update(const AInput: IWarUiInput);
var
  LMapX: Single;
  LMapY: Single;
  LTileX: Single;
  LTileY: Single;
  LX: Integer;
  LY: Integer;
begin
  if not FFlags.Flag[wdrFlowField] then
    Exit;
  if (not Assigned(FSource)) or (not AInput.IsButtonJustPressed(wmbLeft)) then
    Exit;
  if not WarRectContains(FCamera.Panels.MapPanel, AInput.PositionX, AInput.PositionY) then
    Exit;
  FCamera.ScreenToMap(AInput.PositionX, AInput.PositionY, LMapX, LMapY);
  TWarMapCamera.MapToTile(LMapX, LMapY, LTileX, LTileY);
  LX := Trunc(LTileX);
  LY := Trunc(LTileY);
  if (LX < 0) or (LX >= WAR_MAP_TILES_WIDTH) or (LY < 0) or (LY >= WAR_MAP_TILES_HEIGHT) then
    Exit;
  FField := FSource.ComputeFlowField(LX, LY);
  FGoalX := LX;
  FGoalY := LY;
end;

procedure TWarDebugFlowField.Render;
var
  LStartX: Integer;
  LStartY: Integer;
  LEndX: Integer;
  LEndY: Integer;
  LX: Integer;
  LY: Integer;
  LDirection: Integer;
  LCenterX: Single;
  LCenterY: Single;
  LShaft: Single;
  LDeltaX: Single;
  LDeltaY: Single;
  LEndPointX: Single;
  LEndPointY: Single;
  LAngle: Single;
  LTemp: Single;
begin
  if not FFlags.Flag[wdrFlowField] then
    Exit;
  if not Assigned(FField) then
    Exit;
  // the tiles of the window, one more at the right and at the bottom
  LTemp := FCamera.X / WAR_MEGA_TILE_SIZE;
  LStartX := Trunc(LTemp);
  LTemp := FCamera.Y / WAR_MEGA_TILE_SIZE;
  LStartY := Trunc(LTemp);
  LTemp := FCamera.X + FCamera.Width;
  LTemp := LTemp / WAR_MEGA_TILE_SIZE;
  LEndX := Trunc(LTemp) + 1;
  LTemp := FCamera.Y + FCamera.Height;
  LTemp := LTemp / WAR_MEGA_TILE_SIZE;
  LEndY := Trunc(LTemp) + 1;
  LStartX := Max(LStartX, 0);
  LStartY := Max(LStartY, 0);
  LEndX := Min(LEndX, WAR_MAP_TILES_WIDTH);
  LEndY := Min(LEndY, WAR_MAP_TILES_HEIGHT);
  LShaft := WAR_MEGA_TILE_SIZE;
  LShaft := LShaft * SHAFT_FACTOR;
  for LY := LStartY to LEndY - 1 do
    for LX := LStartX to LEndX - 1 do
    begin
      if (LX = FGoalX) and (LY = FGoalY) then
        Continue;
      if FGrid.IsStatic(LX, LY) then
        Continue;
      LDirection := FField.Direction[LY * WAR_MAP_TILES_WIDTH + LX];
      if (LDirection < 0) or (LDirection >= WAR_PATH_DIRECTION_COUNT) then
        Continue;
      TWarMapCamera.TileToMap(LX, LY, True, LCenterX, LCenterY);
      LDeltaX := WAR_PATH_DIR_X[LDirection] * LShaft;
      LDeltaY := WAR_PATH_DIR_Y[LDirection] * LShaft;
      LEndPointX := LCenterX + LDeltaX;
      LEndPointY := LCenterY + LDeltaY;
      FTransform.StrokeLine(LCenterX, LCenterY, LEndPointX, LEndPointY, ARROW_COLOR);
      LAngle := TWarDebugArrow.AngleOf(WAR_PATH_DIR_X[LDirection], WAR_PATH_DIR_Y[LDirection]);
      TWarDebugArrow.DrawHead(FTransform, LEndPointX, LEndPointY, LAngle, ARROW_COLOR);
    end;
end;

end.
