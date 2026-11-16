{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of the map                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (renderPassableInfo, renderMapGrid,    }
{  renderSpatialGrid), (c) 2019 Alejandro Coto Gutierrez, zlib License (see     }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
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
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.DebugNearUnits, DelphiDoom.War.MapUi.DebugFlowField,
  DelphiDoom.War.MapUi.DebugRvo, DelphiDoom.War.MapUi.DebugStateMachine, DelphiDoom.War.Ui.Canvas;

type
  /// <summary>
  ///   What the debug flags of the map draw on the ground, between the forests and the units: the tiles that nothing can
  ///   cross (passable-info), the lines between the tiles (map-grid), the lines between the cells of the grid of the
  ///   units (spatial-grid) and the units near a tile (near-units, TWarDebugNearUnits). Unit-info and unit-animations are
  ///   drawn by the renderer with the unit and the animation (it asks IsOn); map-animations is a flag the original does
  ///   not draw anything for
  /// </summary>
  TWarMapDebugView = class
  strict private
    FTransform: TWarRenderTransform;
    FGrid: TWarPathGrid;
    FFlags: IWarDebugRender;
    FNearUnits: TWarDebugNearUnits;
    FFlowField: TWarDebugFlowField;
    FRvo: TWarDebugRvo;
    FStateMachine: TWarDebugStateMachine;
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    procedure RenderPassableInfo;
    procedure RenderMapGrid;
    procedure RenderSpatialGrid;
  public
    /// <summary>The context of the model is where the drawings of the units read them; nothing is owned</summary>
    constructor Create(const ATransform: TWarRenderTransform; const AGrid: TWarPathGrid; const AFlags: IWarDebugRender;
      const AContext: TWarModelContext; const AMachine: TWarStateMachine; const ACamera: TWarMapCamera;
      const ACanvas: TWarUiCanvas);
    destructor Destroy; override;
    /// <summary>
    ///   The start of an update of the map that plays: clearNearUnitsDebug (a box shown by a click of editing lasts one frame)
    /// </summary>
    procedure BeginUpdate;
    /// <summary>
    ///   The end of the update, after the status line: refreshSelectedUnitNearUnitsDebug; AEditingSpell is whether the mode of
    ///   editing is one of the spells (rain of fire, poison cloud, raise dead)
    /// </summary>
    procedure EndUpdate(AEditingSpell: Boolean);
    /// <summary>renderPassableInfo, renderMapGrid, renderSpatialGrid, renderFlowField and renderNearUnitsDebug, in this order</summary>
    procedure Render;
    /// <summary>The text of the cheat line for the selected unit (wstdbg_updateDebugText); empty when there is none</summary>
    function StateText: AnsiString;
    /// <summary>renderRvoDebug: what is drawn over the units, the projectiles and the animations (under the fog)</summary>
    procedure RenderOverUnits;
    /// <summary>updateFlowFieldDebug: the click that chooses the goal of the flow field that is drawn</summary>
    procedure UpdateClicks(const AInput: IWarUiInput);
    /// <summary>The near units of the debug drawing, where a click of editing sets the box of its spell</summary>
    property NearUnits: TWarDebugNearUnits read FNearUnits;
    /// <summary>context->debugRender.flags[AFlag]: the renderer reads the flags of the drawings that are part of a unit or an animation</summary>
    function IsOn(AFlag: TWarDebugRenderFlag): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Path.Intf,
  DelphiDoom.War.MapUi.DebugStateText, DelphiDoom.War.Model.EntityPool;

const
  /// <summary>MAP_GRID_TILE_SIZE: tiles of a side of a cell of the grid of the units</summary>
  GRID_CELL_TILES = 4;
  PASSABLE_COLOR: TWarRgba = (R: 255; G: 0; B: 0; A: 100);
  SPATIAL_COLOR: TWarRgba = (R: 0; G: 255; B: 255; A: 255);

{ TWarMapDebugView }

constructor TWarMapDebugView.Create(const ATransform: TWarRenderTransform; const AGrid: TWarPathGrid;
  const AFlags: IWarDebugRender; const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const ACamera: TWarMapCamera; const ACanvas: TWarUiCanvas);
var
  LSource: IWarFlowFieldSource;
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FTransform := ATransform;
  FGrid := AGrid;
  FFlags := AFlags;
  FNearUnits := TWarDebugNearUnits.Create(ATransform, AContext, AFlags);
  // the flow fields are the ones of the movement of the units (a model with no steering has none: the click does nothing)
  if not Supports(AContext.Steering, IWarFlowFieldSource, LSource) then
    LSource := nil;
  FFlowField := TWarDebugFlowField.Create(ATransform, AGrid, AFlags, ACamera, LSource);
  FRvo := TWarDebugRvo.Create(ATransform, AContext, AMachine, AFlags);
  FStateMachine := TWarDebugStateMachine.Create(ATransform, ACanvas, AContext, AMachine, AFlags);
end;

destructor TWarMapDebugView.Destroy;
begin
  FStateMachine.Free;
  FRvo.Free;
  FFlowField.Free;
  FNearUnits.Free;
  inherited Destroy;
end;

procedure TWarMapDebugView.BeginUpdate;
begin
  FNearUnits.Clear;
end;

procedure TWarMapDebugView.EndUpdate(AEditingSpell: Boolean);
begin
  FNearUnits.RefreshSelected(AEditingSpell);
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
  FFlowField.Render;
  FNearUnits.Render;
  FStateMachine.Render;
end;

function TWarMapDebugView.StateText: AnsiString;
var
  LSlot: Integer;
begin
  // wstdbg_updateDebugText: empty unless the flag is on and exactly one entity is selected
  Result := '';
  if (not FFlags.Flag[wdrStateMachine]) or (FContext.Selection.Count <> 1) then
    Exit;
  LSlot := FContext.Pool.FindSlot(FContext.Selection[0]);
  if LSlot < 0 then
    Exit;
  Result := TWarDebugStateText.Build(FContext, FMachine, LSlot);
end;

procedure TWarMapDebugView.RenderOverUnits;
begin
  FRvo.Render;
end;

procedure TWarMapDebugView.UpdateClicks(const AInput: IWarUiInput);
begin
  FFlowField.Update(AInput);
end;

end.
