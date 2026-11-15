{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what is under the mouse on the map                }
{                                                                              }
{  Port of war1 (acoto87/war1), we_findEntityUnderCursor of war_entities.c,     }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Picker;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Types, DelphiDoom.War.Map.Game, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.MapUi.Types;

type
  /// <summary>
  ///   we_findEntityUnderCursor: the first unit whose rectangle holds the point (the units that are dying, corpses,
  ///   collapsing or out of sight are not there), else a forest that has a tree on the tile, else a wall that has a piece
  ///   with hit points on it. The units are walked in the order of the list of the pool, which is the order of the last
  ///   drawing (sorted by y), so the one drawn first of two that overlap is the one that is found
  /// </summary>
  TWarMapPicker = class
  strict private
    FMap: TWarGameMap;
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
  public
    constructor Create(const AMap: TWarGameMap; const AContext: TWarModelContext; const AMachine: TWarStateMachine);
    /// <summary>
    ///   The entity at the point of the map (pixels): its kind and the slot of the pool (the forest or wall entity for a
    ///   tree or a wall). Kind is a WAR_ENTITY_*: none (0) if there is nothing
    /// </summary>
    function Find(AMapX, AMapY: Single; AIncludeTrees, AIncludeWalls: Boolean; out ASlot: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Forest, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Walls,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.MapUi.Camera;

{ TWarMapPicker }

constructor TWarMapPicker.Create(const AMap: TWarGameMap; const AContext: TWarModelContext;
  const AMachine: TWarStateMachine);
begin
  inherited Create;
  FMap := AMap;
  FContext := AContext;
  FMachine := AMachine;
end;

function TWarMapPicker.Find(AMapX, AMapY: Single; AIncludeTrees, AIncludeWalls: Boolean; out ASlot: Integer): Integer;
var
  LTileX: Single;
  LTileY: Single;
  LUnits: TArray<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LTile: TWarVec2;
  LRect: TWarRectF;
  LForest: TWarMapForest;
  LTree: Integer;
  LWalls: TWarWalls;
  LPiece: PWarWallPiece;
begin
  ASlot := 0;
  Result := WAR_ENTITY_NONE;
  TWarMapCamera.MapToTile(AMapX, AMapY, LTileX, LTileY);
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT].ToArray;
  for LIndex := 0 to High(LUnits) do
  begin
    LSlot := LUnits[LIndex];
    LEntity := FContext.Pool.Slots[LSlot];
    if LEntity^.HasUnit then
    begin
      // not the dead, the corpses, the buildings that collapse and the units that are not in sight
      if FMachine.IsDead(LSlot) or FMachine.IsGoingToDie(LSlot) or
        TWarUnitClassifier.IsCorpse(LEntity^.UnitData.UnitType) then
        Continue;
      if FMachine.IsCollapsing(LSlot) or FMachine.IsGoingToCollapse(LSlot) then
        Continue;
      LTile := TWarUnitGeometry.Tile(LEntity);
      if not FMap.Fog.IsAnyTileInState(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
        LEntity^.UnitData.SizeY, wtsVisible) then
        Continue;
    end;
    // wu_getUnitRect: the position and the size of the unit in pixels
    LRect.X := LEntity^.Position.X;
    LRect.Y := LEntity^.Position.Y;
    LRect.Width := LEntity^.UnitData.SizeX * WAR_MODEL_MEGA_TILE;
    LRect.Height := LEntity^.UnitData.SizeY * WAR_MODEL_MEGA_TILE;
    if WarRectContains(LRect, AMapX, AMapY) then
    begin
      ASlot := LSlot;
      Exit(WAR_ENTITY_UNIT);
    end;
  end;
  if AIncludeTrees then
    for LIndex := 0 to FMap.Forests.Count - 1 do
    begin
      LForest := FMap.Forests[LIndex];
      for LTree := 0 to LForest.Trees.Count - 1 do
        if (LForest.Trees[LTree].TileX = Trunc(LTileX)) and (LForest.Trees[LTree].TileY = Trunc(LTileY)) then
        begin
          if (LForest.Trees[LTree].TileType <> WAR_PIECE_NONE) and (LForest.Trees[LTree].TileType <> WAR_TREE_CHOPPED) then
          begin
            ASlot := FContext.Pool.FindSlot(LForest.Id);
            Exit(WAR_ENTITY_FOREST);
          end;
          Break;
        end;
    end;
  if AIncludeWalls then
  begin
    LWalls := FContext.Walls;
    for LIndex := 0 to LWalls.Count - 1 do
    begin
      LPiece := LWalls[LIndex];
      if (LPiece^.TileX = Trunc(LTileX)) and (LPiece^.TileY = Trunc(LTileY)) then
      begin
        if LPiece^.Hp > 0 then
        begin
          ASlot := FContext.Pool.OfType[WAR_ENTITY_WALL][0];
          Exit(WAR_ENTITY_WALL);
        end;
        Break;
      end;
    end;
  end;
end;

end.
