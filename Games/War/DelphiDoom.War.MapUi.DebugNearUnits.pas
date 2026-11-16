{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of the near units               }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (setNearUnitsDebugParams,             }
{  clearNearUnitsDebug, refreshSelectedUnitNearUnitsDebug, renderNearUnitsDebug),}
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).}
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugNearUnits;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform,
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   The flag "near-units": the box of the query that finds the units near a tile (a radius in tiles) and the units it finds,
  ///   drawn again every frame from the grid of the units. The tile and the radius are of the selected unit (when it is the
  ///   only one selected: the radius of the enemies, 5) or of a click of the modes of editing, and they are forgotten at the
  ///   start of every update of the map: a click of a mode of editing shows its box for the frame of the click. With the
  ///   flag "spatial-grid" also on the cells of the grid that the query visits are filled too
  /// </summary>
  TWarDebugNearUnits = class
  strict private
    FTransform: TWarRenderTransform;
    FContext: TWarModelContext;
    FFlags: IWarDebugRender;
    FEnabled: Boolean;
    FTile: TWarVec2;
    FDistance: Integer;
    FFound: TList<Integer>;
  public
    /// <summary>Nothing is owned but the list of the units that the drawing finds</summary>
    constructor Create(const ATransform: TWarRenderTransform; const AContext: TWarModelContext;
      const AFlags: IWarDebugRender);
    destructor Destroy; override;
    /// <summary>setNearUnitsDebugParams: nothing when the flag is off</summary>
    procedure SetParams(const ATile: TWarVec2; ADistance: Integer);
    /// <summary>clearNearUnitsDebug: nothing when the flag is off</summary>
    procedure Clear;
    /// <summary>
    ///   refreshSelectedUnitNearUnitsDebug: follows the unit when exactly one is selected, unless a mode of editing of a spell
    ///   is on (it keeps its own box); anything else clears
    /// </summary>
    procedure RefreshSelected(ASpellEditingActive: Boolean);
    /// <summary>renderNearUnitsDebug</summary>
    procedure Render;
    property Enabled: Boolean read FEnabled;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Map.Grid, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.EntityPool, DelphiDoom.War.Map.Types;

const
  /// <summary>NEAR_ENEMY_RADIUS of war.h</summary>
  NEAR_ENEMY_RADIUS = 5;
  CELL_FILL: TWarRgba = (R: 0; G: 128; B: 255; A: 48);
  CELL_STROKE: TWarRgba = (R: 0; G: 255; B: 255; A: 255);
  UNIT_FILL: TWarRgba = (R: 255; G: 255; B: 0; A: 48);
  // WAR_COLOR_YELLOW is 0xFFC7C700: as bytes R=0, G=199, B=199 (a defect of the C kept, see Ui.Types)
  BOX_STROKE: TWarRgba = (R: 0; G: $C7; B: $C7; A: $FF);

{ TWarDebugNearUnits }

constructor TWarDebugNearUnits.Create(const ATransform: TWarRenderTransform; const AContext: TWarModelContext;
  const AFlags: IWarDebugRender);
begin
  inherited Create;
  FTransform := ATransform;
  FContext := AContext;
  FFlags := AFlags;
  FFound := TList<Integer>.Create;
end;

destructor TWarDebugNearUnits.Destroy;
begin
  FFound.Free;
  inherited Destroy;
end;

procedure TWarDebugNearUnits.SetParams(const ATile: TWarVec2; ADistance: Integer);
begin
  if not FFlags.Flag[wdrNearUnits] then
    Exit;
  FEnabled := True;
  FTile := ATile;
  FDistance := ADistance;
end;

procedure TWarDebugNearUnits.Clear;
begin
  if not FFlags.Flag[wdrNearUnits] then
    Exit;
  FEnabled := False;
end;

procedure TWarDebugNearUnits.RefreshSelected(ASpellEditingActive: Boolean);
var
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  if not FFlags.Flag[wdrNearUnits] then
    Exit;
  // a mode of editing of a spell holds its own parameters
  if ASpellEditingActive then
    Exit;
  if FContext.Selection.Count <> 1 then
  begin
    Clear;
    Exit;
  end;
  LSlot := FContext.Pool.FindSlot(FContext.Selection[0]);
  if LSlot < 0 then
  begin
    Clear;
    Exit;
  end;
  LEntity := FContext.Pool.Slots[LSlot];
  if LEntity^.EntityType <> WAR_ENTITY_UNIT then
  begin
    Clear;
    Exit;
  end;
  SetParams(TWarUnitGeometry.CenterTile(LEntity), NEAR_ENEMY_RADIUS);
end;

procedure TWarDebugNearUnits.Render;
var
  LCenter: TWarVec2;
  LSize: TWarVec2;
  LArea: TWarRectF;
  LDistance: Single;
  LGridX: Integer;
  LGridY: Integer;
  LMinX: Integer;
  LMaxX: Integer;
  LMinY: Integer;
  LMaxY: Integer;
  LCorner: TWarVec2;
  LCell: TWarRectF;
  LIndex: Integer;
  LEntity: PWarEntity;
  LLow: Single;
  LHigh: Single;
begin
  if not FFlags.Flag[wdrNearUnits] then
    Exit;
  if not FEnabled then
    Exit;
  // the box of the query: the radius in tiles around the tile (the Chebyshev radius of vec2_distanceInTiles)
  LCenter := TWarModelMath.TileToMap(FTile, True);
  LSize.X := (FDistance * 2 + 1) * WAR_MEGA_TILE_SIZE;
  LSize.Y := (FDistance * 2 + 1) * WAR_MEGA_TILE_SIZE;
  LArea.X := LCenter.X - LSize.X * 0.5;
  LArea.Y := LCenter.Y - LSize.Y * 0.5;
  LArea.Width := LSize.X;
  LArea.Height := LSize.Y;
  FTransform.StrokeRect(LArea, BOX_STROKE);
  if FFlags.Flag[wdrSpatialGrid] then
  begin
    // the cells that we_getNearUnits visits (the same floor of the bounds)
    LDistance := FDistance;
    LLow := FTile.X - LDistance;
    LHigh := FTile.X + LDistance;
    LMinX := Max(0, Floor(LLow / WAR_MAP_GRID_TILE_SIZE));
    LMaxX := Min(WAR_MAP_GRID_TILES_WIDTH - 1, Floor(LHigh / WAR_MAP_GRID_TILE_SIZE));
    LLow := FTile.Y - LDistance;
    LHigh := FTile.Y + LDistance;
    LMinY := Max(0, Floor(LLow / WAR_MAP_GRID_TILE_SIZE));
    LMaxY := Min(WAR_MAP_GRID_TILES_HEIGHT - 1, Floor(LHigh / WAR_MAP_GRID_TILE_SIZE));
    for LGridY := LMinY to LMaxY do
      for LGridX := LMinX to LMaxX do
      begin
        LCorner.X := LGridX * WAR_MAP_GRID_TILE_SIZE;
        LCorner.Y := LGridY * WAR_MAP_GRID_TILE_SIZE;
        LCorner := TWarModelMath.TileToMap(LCorner, False);
        LCell.X := LCorner.X;
        LCell.Y := LCorner.Y;
        LCell.Width := WAR_MAP_GRID_TILE_SIZE * WAR_MEGA_TILE_SIZE;
        LCell.Height := WAR_MAP_GRID_TILE_SIZE * WAR_MEGA_TILE_SIZE;
        FTransform.FillRect(LCell, CELL_FILL);
        FTransform.StrokeRect(LCell, CELL_STROKE);
      end;
  end;
  // we_getNearUnits again, on the grid of the last tic, and the box of each unit it finds
  FContext.Combat.CollectNearUnits(FTile, FDistance, FFound);
  for LIndex := 0 to FFound.Count - 1 do
  begin
    LEntity := FContext.Pool.Slots[FFound[LIndex]];
    if LEntity^.EntityType <> WAR_ENTITY_UNIT then
      Continue;
    LSize := TWarUnitGeometry.SpriteSize(LEntity);
    LArea.X := LEntity^.Position.X;
    LArea.Y := LEntity^.Position.Y;
    LArea.Width := LSize.X;
    LArea.Height := LSize.Y;
    FTransform.FillRect(LArea, UNIT_FILL);
    FTransform.StrokeRect(LArea, BOX_STROKE);
  end;
end;

end.
