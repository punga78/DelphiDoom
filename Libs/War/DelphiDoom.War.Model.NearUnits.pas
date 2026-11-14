{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the units near a tile                             }
{                                                                              }
{  Port of war1 (acoto87/war1), wgrid_build and we_getNearUnits, (c) 2019      }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.NearUnits;

{$R-}
{$Q-}

interface

uses
  System.Generics.Collections, DelphiDoom.War.Map.Grid, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The grid of the units (cells of 4 x 4 tiles) is built once per tic, after the states, and the splash damage asks it for
  ///   the units within a distance of a tile, cell by cell, the last unit put in a cell first: the order is the one of
  ///   the original and decides who is hit first (the blows draw numbers). A unit that starts to die after the grid
  ///   was built stays in it for the rest of the tic
  /// </summary>
  TWarNearUnits = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FGrid: TWarMapGrid;
    FUnits: TArray<TWarGridUnit>;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
    destructor Destroy; override;
    /// <summary>wgrid_build: the units in the order of their list, but the ones that are going to die or are collapsing</summary>
    procedure Build;
    /// <summary>we_getNearUnits: the slots go to AResult (cleared before)</summary>
    procedure Collect(const ATile: TWarVec2; ADistance: Integer; AResult: TList<Integer>);
  end;

implementation

uses
  System.Math, DelphiDoom.War.Model.UnitGeometry;

{ TWarNearUnits }

constructor TWarNearUnits.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FGrid := TWarMapGrid.Create;
end;

destructor TWarNearUnits.Destroy;
begin
  FGrid.Free;
  inherited;
end;

procedure TWarNearUnits.Build;
var
  LList: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LTile: TWarVec2;
begin
  LList := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  if System.Length(FUnits) < LList.Count then
    SetLength(FUnits, LList.Count);
  for LIndex := 0 to LList.Count - 1 do
  begin
    LSlot := LList[LIndex];
    LTile := TWarUnitGeometry.CenterTile(FContext.Pool.Slots[LSlot]);
    FUnits[LIndex].Slot := LSlot;
    FUnits[LIndex].TileX := LTile.X;
    FUnits[LIndex].TileY := LTile.Y;
    FUnits[LIndex].Active := FContext.Pool.Slots[LSlot]^.HasTransform and not FMachine.IsGoingToDie(LSlot) and
      not FMachine.IsCollapsing(LSlot) and not FMachine.IsGoingToCollapse(LSlot);
  end;
  FGrid.Build(Copy(FUnits, 0, LList.Count));
end;

procedure TWarNearUnits.Collect(const ATile: TWarVec2; ADistance: Integer; AResult: TList<Integer>);
var
  LDistance: Single;
  LLow: Single;
  LHigh: Single;
  LXMin: Integer;
  LXMax: Integer;
  LYMin: Integer;
  LYMax: Integer;
  LGx: Integer;
  LGy: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  AResult.Clear;
  LDistance := ADistance;
  LLow := ATile.X - LDistance;
  LHigh := ATile.X + LDistance;
  LXMin := Max(0, Floor(LLow / WAR_MAP_GRID_TILE_SIZE));
  LXMax := Min(WAR_MAP_GRID_TILES_WIDTH - 1, Floor(LHigh / WAR_MAP_GRID_TILE_SIZE));
  LLow := ATile.Y - LDistance;
  LHigh := ATile.Y + LDistance;
  LYMin := Max(0, Floor(LLow / WAR_MAP_GRID_TILE_SIZE));
  LYMax := Min(WAR_MAP_GRID_TILES_HEIGHT - 1, Floor(LHigh / WAR_MAP_GRID_TILE_SIZE));
  for LGy := LYMin to LYMax do
    for LGx := LXMin to LXMax do
    begin
      LSlot := FGrid.Head(TWarMapGrid.GetTileIndex(LGx, LGy));
      while LSlot <> -1 do
      begin
        LEntity := FContext.Pool.Slots[LSlot];
        if (LEntity^.Id <> 0) and (LEntity^.EntityType = WAR_ENTITY_UNIT) and
          TWarUnitGeometry.TileInRange(LEntity, ATile, ADistance) then
          AResult.Add(LSlot);
        LSlot := FGrid.Next(LSlot);
      end;
    end;
end;

end.
