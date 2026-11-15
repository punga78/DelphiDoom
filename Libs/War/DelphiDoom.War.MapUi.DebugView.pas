{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of the map                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (renderPassableInfo, renderMapGrid,    }
{  renderSpatialGrid), (c) 2019 Alejandro Coto Gutierrez, zlib License (see     }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugView;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   What the debug flags of the map draw on the ground, between the forests and the units: the tiles that nothing can
  ///   cross (passable-info), the lines between the tiles (map-grid) and the lines between the cells of the grid of the
  ///   units (spatial-grid). Unit-info and unit-animations are drawn by the renderer with the unit and the animation (it asks
  ///   IsOn); near-units, map-animations (the original draws nothing for it), font, projectiles, flow-field, rvo and
  ///   state-machine are the part of the debug drawing that is not ported
  /// </summary>
  TWarMapDebugView = class
  strict private
    FTransform: TWarRenderTransform;
    FGrid: TWarPathGrid;
    FFlags: IWarDebugRender;
    procedure RenderPassableInfo;
    procedure RenderMapGrid;
    procedure RenderSpatialGrid;
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(const ATransform: TWarRenderTransform; const AGrid: TWarPathGrid; const AFlags: IWarDebugRender);
    /// <summary>renderPassableInfo, renderMapGrid and renderSpatialGrid, in this order</summary>
    procedure Render;
    /// <summary>context->debugRender.flags[AFlag]: the renderer reads the flags of the drawings that are part of a unit or an animation</summary>
    function IsOn(AFlag: TWarDebugRenderFlag): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types;

const
  /// <summary>MAP_GRID_TILE_SIZE: tiles of a side of a cell of the grid of the units</summary>
  GRID_CELL_TILES = 4;
  PASSABLE_COLOR: TWarRgba = (R: 255; G: 0; B: 0; A: 100);
  SPATIAL_COLOR: TWarRgba = (R: 0; G: 255; B: 255; A: 255);

{ TWarMapDebugView }

constructor TWarMapDebugView.Create(const ATransform: TWarRenderTransform; const AGrid: TWarPathGrid;
  const AFlags: IWarDebugRender);
begin
  inherited Create;
  FTransform := ATransform;
  FGrid := AGrid;
  FFlags := AFlags;
end;

procedure TWarMapDebugView.RenderPassableInfo;
var
  LX: Integer;
  LY: Integer;
  LRect: TWarRectF;
begin
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
      if FGrid.IsStatic(LX, LY) then
      begin
        LRect.X := LX * WAR_MEGA_TILE_SIZE;
        LRect.Y := LY * WAR_MEGA_TILE_SIZE;
        LRect.Width := WAR_MEGA_TILE_SIZE;
        LRect.Height := WAR_MEGA_TILE_SIZE;
        FTransform.FillRect(LRect, PASSABLE_COLOR);
      end;
end;

procedure TWarMapDebugView.RenderMapGrid;
var
  LIndex: Integer;
begin
  for LIndex := 1 to WAR_MAP_TILES_WIDTH - 1 do
    FTransform.StrokeLine(LIndex * WAR_MEGA_TILE_SIZE, 0, LIndex * WAR_MEGA_TILE_SIZE,
      WAR_MAP_TILES_HEIGHT * WAR_MEGA_TILE_SIZE, WAR_COLOR_WHITE);
  for LIndex := 1 to WAR_MAP_TILES_HEIGHT - 1 do
    FTransform.StrokeLine(0, LIndex * WAR_MEGA_TILE_SIZE, WAR_MAP_TILES_WIDTH * WAR_MEGA_TILE_SIZE,
      LIndex * WAR_MEGA_TILE_SIZE, WAR_COLOR_WHITE);
end;

procedure TWarMapDebugView.RenderSpatialGrid;
var
  LIndex: Integer;
begin
  // the cells of four tiles: wmap_tileToMapCoordinatesV of the corner of each
  for LIndex := 1 to WAR_MAP_TILES_WIDTH div GRID_CELL_TILES - 1 do
    FTransform.StrokeLine(LIndex * GRID_CELL_TILES * WAR_MEGA_TILE_SIZE, 0, LIndex * GRID_CELL_TILES * WAR_MEGA_TILE_SIZE,
      WAR_MAP_TILES_HEIGHT * WAR_MEGA_TILE_SIZE, SPATIAL_COLOR);
  for LIndex := 1 to WAR_MAP_TILES_HEIGHT div GRID_CELL_TILES - 1 do
    FTransform.StrokeLine(0, LIndex * GRID_CELL_TILES * WAR_MEGA_TILE_SIZE, WAR_MAP_TILES_WIDTH * WAR_MEGA_TILE_SIZE,
      LIndex * GRID_CELL_TILES * WAR_MEGA_TILE_SIZE, SPATIAL_COLOR);
end;

function TWarMapDebugView.IsOn(AFlag: TWarDebugRenderFlag): Boolean;
begin
  Result := FFlags.Flag[AFlag];
end;

procedure TWarMapDebugView.Render;
begin
  if FFlags.Flag[wdrPassableInfo] then
    RenderPassableInfo;
  if FFlags.Flag[wdrMapGrid] then
    RenderMapGrid;
  if FFlags.Flag[wdrSpatialGrid] then
    RenderSpatialGrid;
end;

end.
