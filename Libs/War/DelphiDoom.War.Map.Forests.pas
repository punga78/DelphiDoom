{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the forests of the map                            }
{                                                                              }
{  Port of war1 (acoto87/war1), war_trees.c (we_determineTreeTiles,            }
{  we_findAccesibleTree, we_plantTree, we_validTree, we_takeTreeDown,          }
{  we_chopTree) and createForestEntities of war_map.c, (c) 2019 Alejandro Coto }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Forests;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Types, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Forest;

type
  /// <summary>
  ///   All the forests of a map and what the game does to them: the first trees (the groups of tiles of wood of the
  ///   passable map), the tile each tree shows, planting, chopping, felling and the search of a tree a worker can
  ///   reach. The trees occupy the grid: a tree plants its forest id in its tile, a felled tree frees it and the
  ///   painter writes the felled tile in the map
  /// </summary>
  TWarMapForests = class
  strict private
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FPainter: IWarTilePainter;
    FTilesetType: Integer;
    FForests: TObjectList<TWarMapForest>;
    FEditingForest: TWarMapForest;
    function GetCount: Integer;
    function GetForest(AIndex: Integer): TWarMapForest;
  public
    /// <summary>The grid and the fog are the ones of the map (they are not owned)</summary>
    constructor Create(const AGrid: TWarPathGrid; const AFog: TWarFogOfWar; const APainter: IWarTilePainter;
      ATilesetType: Integer);
    destructor Destroy; override;
    /// <summary>A new, empty forest with the id of its entity; the forests are kept in the order they are created</summary>
    function AddForest(AId: Word): TWarMapForest;
    /// <summary>
    ///   createForestEntities: a forest for each group of tiles of wood (128) of the passable map that touch
    ///   (eight neighbors), found from the first tile in reading order; AAllocateId gives the id of each new forest
    ///   (taken when its trees are known). The tile of each tree is decided as its forest is made
    /// </summary>
    procedure CreateFromPassable(const APassable: TArray<Word>; const AAllocateId: TFunc<Word>);
    /// <summary>The forest with the id, nil if there is none (the grid also holds the ids of the units)</summary>
    function FindForest(AId: Word): TWarMapForest;
    /// <summary>
    ///   we_determineTreeTiles: the tile of each tree of the forest from the eight neighbors that have a tree with
    ///   wood (in any forest; outside the map counts); a felled tree is skipped, a tree that gets no tile is removed
    /// </summary>
    procedure DetermineTiles(const AForest: TWarMapForest);
    /// <summary>we_determineAllTreeTiles</summary>
    procedure DetermineAllTiles;
    /// <summary>
    ///   we_findAccesibleTree: from the tile, looking at the neighbors that are in the map, the first tree with wood
    ///   that has an empty tile next to it and is in sight or in fog; False if there is none
    /// </summary>
    function FindAccessibleTree(const AForest: TWarMapForest; AX, AY: Integer; out ATree: TWarTree): Boolean;
    /// <summary>
    ///   we_plantTree: on an empty tile; on the top row only if there is a tree below it (and then one tree), elsewhere
    ///   a tree and, if the tile above is empty, another above it. Nothing is done if the tile is not empty
    /// </summary>
    procedure PlantTree(const AForest: TWarMapForest; AX, AY: Integer);
    /// <summary>we_validTree: the tree stands if there is another above or below it in the forest</summary>
    function IsValidTree(const AForest: TWarMapForest; const ATree: TWarTree): Boolean;
    /// <summary>
    ///   we_takeTreeDown: the tile is free, the map shows the felled tile, the tree leaves the forest and the trees
    ///   above and below that no longer stand fall too
    /// </summary>
    procedure TakeTreeDown(const AForest: TWarMapForest; const ATree: TWarTree);
    /// <summary>
    ///   we_chopTree: takes wood from the first tree of the tile (at most what it has); at zero the tree is felled
    ///   and the tiles of the forest are decided again. Returns the wood taken; EWarException if the forest has no tree there
    /// </summary>
    function ChopTree(const AForest: TWarMapForest; AX, AY, AAmount: Integer): Integer;
    property Count: Integer read GetCount;
    property Forests[AIndex: Integer]: TWarMapForest read GetForest; default;
    /// <summary>map->editing.forest: where the game plants the trees</summary>
    property EditingForest: TWarMapForest read FEditingForest write FEditingForest;
  end;

implementation

uses
  DelphiDoom.War.Autotile.Data;

const
  SPREAD_X: array[0..7] of Integer = (0, 1, 1, 1, 0, -1, -1, -1);
  SPREAD_Y: array[0..7] of Integer = (-1, -1, 0, 1, 1, 1, 0, -1);
  AROUND_X: array[0..7] of Integer = (-1, 0, 1, 1, 1, 0, -1, -1);
  AROUND_Y: array[0..7] of Integer = (-1, -1, -1, 0, 1, 1, 1, 0);

function NewTree(AX, AY: Integer): TWarTree;
begin
  Result := Default(TWarTree);
  Result.TileX := AX;
  Result.TileY := AY;
  Result.Amount := WAR_TREE_MAX_WOOD;
end;

{ TWarMapForests }

constructor TWarMapForests.Create(const AGrid: TWarPathGrid; const AFog: TWarFogOfWar; const APainter: IWarTilePainter;
  ATilesetType: Integer);
begin
  inherited Create;
  FGrid := AGrid;
  FFog := AFog;
  FPainter := APainter;
  FTilesetType := ATilesetType;
  FForests := TObjectList<TWarMapForest>.Create(True);
end;

destructor TWarMapForests.Destroy;
begin
  FForests.Free;
  inherited;
end;

function TWarMapForests.GetCount: Integer;
begin
  Result := FForests.Count;
end;

function TWarMapForests.GetForest(AIndex: Integer): TWarMapForest;
begin
  Result := FForests[AIndex];
end;

function TWarMapForests.AddForest(AId: Word): TWarMapForest;
begin
  Result := TWarMapForest.Create(AId);
  FForests.Add(Result);
end;

function TWarMapForests.FindForest(AId: Word): TWarMapForest;
begin
  for Result in FForests do
    if Result.Id = AId then
      Exit;
  Result := nil;
end;

procedure TWarMapForests.CreateFromPassable(const APassable: TArray<Word>; const AAllocateId: TFunc<Word>);
var
  LProcessed: array[0..WAR_MAP_TILE_COUNT - 1] of Boolean;
  LTrees: TList<TWarTree>;
  LForest: TWarMapForest;
  LIndex: Integer;
  LCursor: Integer;
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LNeighbor: Integer;
  LTree: TWarTree;
begin
  if Length(APassable) < WAR_MAP_TILE_COUNT then
    raise EWarException.CreateFmt(SWarMapPassableShort, [Length(APassable), WAR_MAP_TILE_COUNT]);
  FillChar(LProcessed, SizeOf(LProcessed), 0);
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
  begin
    if LProcessed[LIndex] or (APassable[LIndex] <> 128) then
      Continue;
    LTrees := TList<TWarTree>.Create;
    try
      LTrees.Add(NewTree(LIndex mod WAR_MAP_TILES_WIDTH, LIndex div WAR_MAP_TILES_WIDTH));
      LProcessed[LIndex] := True;
      LCursor := 0;
      while LCursor < LTrees.Count do
      begin
        LTree := LTrees[LCursor];
        for LDirection := 0 to 7 do
        begin
          LX := LTree.TileX + SPREAD_X[LDirection];
          LY := LTree.TileY + SPREAD_Y[LDirection];
          if TWarPathGrid.IsInside(LX, LY) then
          begin
            LNeighbor := LY * WAR_MAP_TILES_WIDTH + LX;
            if (not LProcessed[LNeighbor]) and (APassable[LNeighbor] = 128) then
            begin
              // mark it processed right away, to not process it later
              LProcessed[LNeighbor] := True;
              LTrees.Add(NewTree(LX, LY));
            end;
          end;
        end;
        Inc(LCursor);
      end;
      LForest := AddForest(AAllocateId());
      LForest.Trees.AddRange(LTrees);
      for LTree in LForest.Trees do
        FGrid.SetStaticEntity(LTree.TileX, LTree.TileY, 1, 1, LForest.Id);
      DetermineTiles(LForest);
    finally
      LTrees.Free;
    end;
  end;
end;

procedure TWarMapForests.DetermineTiles(const AForest: TWarMapForest);
var
  LInvalid: TList<Integer>;
  LTree: TWarTree;
  LNeighborTree: TWarTree;
  LNeighborForest: TWarMapForest;
  LIndex: Integer;
  LDirection: Integer;
  LMask: Integer;
  LX: Integer;
  LY: Integer;
begin
  LInvalid := TList<Integer>.Create;
  try
    for LIndex := 0 to AForest.Trees.Count - 1 do
    begin
      LTree := AForest.Trees[LIndex];
      if LTree.TileType = WAR_TREE_CHOPPED then
        Continue;
      LMask := 0;
      for LDirection := 0 to 7 do
      begin
        LX := LTree.TileX + AROUND_X[LDirection];
        LY := LTree.TileY + AROUND_Y[LDirection];
        if TWarPathGrid.IsInside(LX, LY) then
        begin
          // the tile belongs to the forest whose id the grid holds there (a unit, a building or nothing is not a forest)
          LNeighborForest := FindForest(FGrid.GetTileEntityId(LX, LY));
          if Assigned(LNeighborForest) and LNeighborForest.TryGetTreeAt(LX, LY, LNeighborTree) and
            (LNeighborTree.Amount > 0) then
            LMask := LMask or (1 shl LDirection);
        end
        else
          LMask := LMask or (1 shl LDirection);
      end;
      LTree.TileType := WAR_TREE_TILE_TYPE_MAP[LMask];
      AForest.Trees[LIndex] := LTree;
      if LTree.TileType = WAR_PIECE_NONE then
        LInvalid.Add(LIndex);
    end;
    for LIndex := LInvalid.Count - 1 downto 0 do
      AForest.Trees.Delete(LInvalid[LIndex]);
  finally
    LInvalid.Free;
  end;
end;

procedure TWarMapForests.DetermineAllTiles;
var
  LForest: TWarMapForest;
begin
  for LForest in FForests do
    DetermineTiles(LForest);
end;

function TWarMapForests.FindAccessibleTree(const AForest: TWarMapForest; AX, AY: Integer; out ATree: TWarTree): Boolean;
var
  LPositions: TList<TPoint>;
  LIndex: Integer;
  LTile: TPoint;
  LDirection: Integer;
  LNext: TPoint;
begin
  LPositions := TList<TPoint>.Create;
  try
    LPositions.Add(Point(AX, AY));
    LIndex := 0;
    while LIndex < LPositions.Count do
    begin
      LTile := LPositions[LIndex];
      if AForest.TryGetTreeAt(LTile.X, LTile.Y, ATree) then
        if FGrid.IsTileAccessible(LTile.X, LTile.Y) and
          (FFog.IsTileVisible(LTile.X, LTile.Y) or FFog.IsTileFog(LTile.X, LTile.Y)) and (ATree.Amount > 0) then
          Exit(True);
      for LDirection := 0 to 7 do
      begin
        LNext := Point(LTile.X + SPREAD_X[LDirection], LTile.Y + SPREAD_Y[LDirection]);
        if TWarPathGrid.IsInside(LNext.X, LNext.Y) and (not LPositions.Contains(LNext)) then
          LPositions.Add(LNext);
      end;
      Inc(LIndex);
    end;
  finally
    LPositions.Free;
  end;
  ATree := Default(TWarTree);
  Result := False;
end;

procedure TWarMapForests.PlantTree(const AForest: TWarMapForest; AX, AY: Integer);
begin
  // if the tile is not empty, there can't be tree there
  if not FGrid.IsEmpty(AX, AY) then
    Exit;
  // only plant a tree in the top border of the map, if there are one below
  if not TWarPathGrid.IsInside(AX, AY - 1) then
  begin
    if AForest.HasTreeAt(AX, AY + 1) then
    begin
      AForest.Trees.Add(NewTree(AX, AY));
      FGrid.SetStaticEntity(AX, AY, 1, 1, AForest.Id);
    end;
  end
  else
  begin
    AForest.Trees.Add(NewTree(AX, AY));
    FGrid.SetStaticEntity(AX, AY, 1, 1, AForest.Id);
    if FGrid.IsEmpty(AX, AY - 1) then
    begin
      AForest.Trees.Add(NewTree(AX, AY - 1));
      FGrid.SetStaticEntity(AX, AY - 1, 1, 1, AForest.Id);
    end;
  end;
end;

function TWarMapForests.IsValidTree(const AForest: TWarMapForest; const ATree: TWarTree): Boolean;
var
  LOther: TWarTree;
begin
  for LOther in AForest.Trees do
    if (LOther.TileX = ATree.TileX) and ((LOther.TileY = ATree.TileY - 1) or (LOther.TileY = ATree.TileY + 1)) then
      Exit(True);
  Result := False;
end;

procedure TWarMapForests.TakeTreeDown(const AForest: TWarMapForest; const ATree: TWarTree);
var
  LChoppedTile: Integer;
  LIndex: Integer;
  LNeighbor: TWarTree;
begin
  if FTilesetType = WAR_TILESET_FOREST then
    LChoppedTile := WAR_TREE_DATA[WAR_TREE_CHOPPED].Forest
  else
    LChoppedTile := WAR_TREE_DATA[WAR_TREE_CHOPPED].Swamp;
  FGrid.SetFreeTiles(ATree.TileX, ATree.TileY, 1, 1);
  FPainter.SetTileIndex(ATree.TileX, ATree.TileY, LChoppedTile);
  LIndex := AForest.IndexOfTile(ATree.TileX, ATree.TileY);
  if LIndex >= 0 then
    AForest.Trees.Delete(LIndex);
  if AForest.TryGetTreeAt(ATree.TileX, ATree.TileY - 1, LNeighbor) and (not IsValidTree(AForest, LNeighbor)) then
    TakeTreeDown(AForest, LNeighbor);
  if AForest.TryGetTreeAt(ATree.TileX, ATree.TileY + 1, LNeighbor) and (not IsValidTree(AForest, LNeighbor)) then
    TakeTreeDown(AForest, LNeighbor);
end;

function TWarMapForests.ChopTree(const AForest: TWarMapForest; AX, AY, AAmount: Integer): Integer;
var
  LIndex: Integer;
  LTree: TWarTree;
begin
  LIndex := AForest.IndexOfTile(AX, AY);
  if LIndex < 0 then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AX, AY]);
  LTree := AForest.Trees[LIndex];
  if LTree.Amount < AAmount then
    AAmount := LTree.Amount;
  LTree.Amount := LTree.Amount - AAmount;
  if LTree.Amount < 0 then
    LTree.Amount := 0;
  AForest.Trees[LIndex] := LTree;
  if LTree.Amount = 0 then
  begin
    TakeTreeDown(AForest, LTree);
    DetermineTiles(AForest);
  end;
  Result := AAmount;
end;

end.
