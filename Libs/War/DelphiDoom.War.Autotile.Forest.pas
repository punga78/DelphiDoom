{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the forest                                        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_trees.c (we_hasTreeAtPosition,             }
{  we_getTreeAtTile, we_determineTreeTiles, we_validTree), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Autotile.Forest;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Autotile.Types;

type
  /// <summary>
  ///   The trees of a level and the tile each one shows. The original asks the path finder which entity is on a
  ///   tile and takes the tree of that forest; here the forest is the one set of trees, a tile has a tree if it
  ///   is in the set. Planting, felling and chopping (they change the map of the game) are not here
  /// </summary>
  TWarForest = class
  strict private
    FTrees: TList<TWarTree>;
    function GetCount: Integer;
    function GetTrees: TArray<TWarTree>;
    function FindIndex(AX, AY: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a tree (the original does not look whether the tile has one: the caller does)</summary>
    procedure AddTree(const ATree: TWarTree);
    /// <summary>we_hasTreeAtPosition</summary>
    function HasTreeAt(AX, AY: Integer): Boolean;
    /// <summary>we_getTreeAtTile: the first tree of the tile</summary>
    function TryGetTreeAt(AX, AY: Integer; out ATree: TWarTree): Boolean;
    /// <summary>
    ///   we_determineTreeTiles: the tile of each tree from the eight neighbors that have a tree with wood (a
    ///   neighbor outside the map counts); a cut tree is skipped, the trees that get no tile are removed
    /// </summary>
    procedure DetermineTiles;
    /// <summary>we_validTree: a tree stands if there is another above or below it in the same column</summary>
    function IsValidTree(const ATree: TWarTree): Boolean;
    property Count: Integer read GetCount;
    property Trees: TArray<TWarTree> read GetTrees;
  end;

implementation

uses
  DelphiDoom.War.Autotile.Data;

const
  DIR_X: array[0..7] of Integer = (-1, 0, 1, 1, 1, 0, -1, -1);
  DIR_Y: array[0..7] of Integer = (-1, -1, -1, 0, 1, 1, 1, 0);

{ TWarForest }

constructor TWarForest.Create;
begin
  inherited Create;
  FTrees := TList<TWarTree>.Create;
end;

destructor TWarForest.Destroy;
begin
  FTrees.Free;
  inherited;
end;

function TWarForest.GetCount: Integer;
begin
  Result := FTrees.Count;
end;

function TWarForest.GetTrees: TArray<TWarTree>;
begin
  Result := FTrees.ToArray;
end;

function TWarForest.FindIndex(AX, AY: Integer): Integer;
begin
  for Result := 0 to FTrees.Count - 1 do
    if (FTrees[Result].TileX = AX) and (FTrees[Result].TileY = AY) then
      Exit;
  Result := -1;
end;

procedure TWarForest.AddTree(const ATree: TWarTree);
begin
  FTrees.Add(ATree);
end;

function TWarForest.HasTreeAt(AX, AY: Integer): Boolean;
begin
  Result := FindIndex(AX, AY) >= 0;
end;

function TWarForest.TryGetTreeAt(AX, AY: Integer; out ATree: TWarTree): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FindIndex(AX, AY);
  Result := LIndex >= 0;
  if Result then
    ATree := FTrees[LIndex]
  else
    ATree := Default(TWarTree);
end;

procedure TWarForest.DetermineTiles;
var
  LWood: TDictionary<Integer, Boolean>;
  LKey: Integer;
  LHasWood: Boolean;
  LTree: TWarTree;
  LPosition: Integer;
  LDirection: Integer;
  LMask: Integer;
  LX: Integer;
  LY: Integer;
begin
  LWood := TDictionary<Integer, Boolean>.Create;
  try
    // the tree of a tile is the first one; it counts only if it has wood
    for LTree in FTrees do
    begin
      LKey := WarTileKey(LTree.TileX, LTree.TileY);
      if not LWood.ContainsKey(LKey) then
        LWood.Add(LKey, LTree.Amount > 0);
    end;
    for LPosition := 0 to FTrees.Count - 1 do
    begin
      LTree := FTrees[LPosition];
      if LTree.TileType = WAR_TREE_CHOPPED then
        Continue;
      LMask := 0;
      for LDirection := 0 to 7 do
      begin
        LX := LTree.TileX + DIR_X[LDirection];
        LY := LTree.TileY + DIR_Y[LDirection];
        if WarTileInside(LX, LY) then
        begin
          if LWood.TryGetValue(WarTileKey(LX, LY), LHasWood) and LHasWood then
            LMask := LMask or (1 shl LDirection);
        end
        else
          LMask := LMask or (1 shl LDirection);
      end;
      LTree.TileType := WAR_TREE_TILE_TYPE_MAP[LMask];
      FTrees[LPosition] := LTree;
    end;
  finally
    LWood.Free;
  end;
  for LPosition := FTrees.Count - 1 downto 0 do
    if FTrees[LPosition].TileType = WAR_PIECE_NONE then
      FTrees.Delete(LPosition);
end;

function TWarForest.IsValidTree(const ATree: TWarTree): Boolean;
var
  LOther: TWarTree;
begin
  for LOther in FTrees do
    if (LOther.TileX = ATree.TileX) and ((LOther.TileY = ATree.TileY - 1) or (LOther.TileY = ATree.TileY + 1)) then
      Exit(True);
  Result := False;
end;

end.
