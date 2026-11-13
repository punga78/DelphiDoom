{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - one forest of the map                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_trees.c (we_hasTreeAtPosition,             }
{  we_getTreeAtTile) and WarForestComponent, (c) 2019 Alejandro Coto           }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Forest;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Autotile.Types;

type
  /// <summary>
  ///   The trees of one forest entity: the original has a forest for each group of trees that touch (and one more
  ///   for the trees the game plants). The id is the one of the entity, the one the occupation grid stores
  /// </summary>
  TWarMapForest = class
  strict private
    FId: Word;
    FTrees: TList<TWarTree>;
  public
    constructor Create(AId: Word);
    destructor Destroy; override;
    /// <summary>we_getTreeAtTile: the index of the first tree of the tile, -1 if there is none</summary>
    function IndexOfTile(AX, AY: Integer): Integer;
    /// <summary>we_hasTreeAtPosition</summary>
    function HasTreeAt(AX, AY: Integer): Boolean;
    /// <summary>we_getTreeAtTile</summary>
    function TryGetTreeAt(AX, AY: Integer; out ATree: TWarTree): Boolean;
    property Id: Word read FId;
    /// <summary>The trees in the order of the original (the list belongs to the forest)</summary>
    property Trees: TList<TWarTree> read FTrees;
  end;

implementation

{ TWarMapForest }

constructor TWarMapForest.Create(AId: Word);
begin
  inherited Create;
  FId := AId;
  FTrees := TList<TWarTree>.Create;
end;

destructor TWarMapForest.Destroy;
begin
  FTrees.Free;
  inherited;
end;

function TWarMapForest.IndexOfTile(AX, AY: Integer): Integer;
begin
  for Result := 0 to FTrees.Count - 1 do
    if (FTrees[Result].TileX = AX) and (FTrees[Result].TileY = AY) then
      Exit;
  Result := -1;
end;

function TWarMapForest.HasTreeAt(AX, AY: Integer): Boolean;
begin
  Result := IndexOfTile(AX, AY) >= 0;
end;

function TWarMapForest.TryGetTreeAt(AX, AY: Integer; out ATree: TWarTree): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOfTile(AX, AY);
  Result := LIndex >= 0;
  if Result then
    ATree := FTrees[LIndex]
  else
    ATree := Default(TWarTree);
end;

end.
