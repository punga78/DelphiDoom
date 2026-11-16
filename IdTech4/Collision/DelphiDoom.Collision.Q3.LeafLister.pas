{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the leaves and brushes a box touches                                        }
{                                                                              }
{  Port of leafList_t, CM_StoreLeafs, CM_StoreBrushes, CM_BoxLeafnums_r,       }
{  CM_BoxLeafnums and CM_BoxBrushes of cm_test.c from the Quake III Arena GPL  }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.LeafLister;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap;

type
  /// <summary>leafList_t: what the walk of the tree collects (leaf numbers, or brush numbers)</summary>
  TQ3LeafList = record
    Count: Integer;
    MaxCount: Integer;
    Overflowed: Boolean;
    List: TArray<Integer>;
    Bounds: array[0..1] of TQ3Vec3;
    /// <summary>for overflows where each leaf cannot be stored individually</summary>
    LastLeaf: Integer;
    /// <summary>True: store the brushes of the leaves (CM_StoreBrushes); False: the leaves (CM_StoreLeafs)</summary>
    StoreBrushes: Boolean;
  end;

  /// <summary>Walks the tree with a box and stores what it finds in a TQ3LeafList</summary>
  TQ3LeafLister = class
  strict private
    FMap: TQ3ClipMap;
    procedure StoreLeafs(var AList: TQ3LeafList; const ANodeNum: Integer);
    procedure StoreBrushes(var AList: TQ3LeafList; const ANodeNum: Integer);
  public
    constructor Create(const AMap: TQ3ClipMap);
    /// <summary>Prepares a list for a box (the list array has AMaxCount entries)</summary>
    class procedure Start(out AList: TQ3LeafList; const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer;
      const AStoreBrushes: Boolean); static;
    /// <summary>CM_BoxLeafnums_r</summary>
    procedure Walk(var AList: TQ3LeafList; ANodeNum: Integer);
    /// <summary>CM_BoxLeafnums: count of the leaves; the list has that length</summary>
    function BoxLeafnums(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer; out ALeafs: TArray<Integer>;
      out ALastLeaf: Integer): Integer;
    /// <summary>CM_BoxBrushes: the brush numbers</summary>
    function BoxBrushes(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer): TArray<Integer>;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math;

constructor TQ3LeafLister.Create(const AMap: TQ3ClipMap);
begin
  inherited Create;
  FMap := AMap;
end;

class procedure TQ3LeafLister.Start(out AList: TQ3LeafList; const AMins, AMaxs: TQ3Vec3;
  const AMaxCount: Integer; const AStoreBrushes: Boolean);
begin
  AList.Bounds[0] := AMins;
  AList.Bounds[1] := AMaxs;
  AList.Count := 0;
  AList.MaxCount := AMaxCount;
  // a negative size overflows at once, as in the original
  if AMaxCount > 0 then
    SetLength(AList.List, AMaxCount)
  else
    AList.List := nil;
  AList.LastLeaf := 0;
  AList.Overflowed := False;
  AList.StoreBrushes := AStoreBrushes;
end;

procedure TQ3LeafLister.StoreLeafs(var AList: TQ3LeafList; const ANodeNum: Integer);
var
  LLeafNum: Integer;
begin
  LLeafNum := -1 - ANodeNum;

  // store the lastLeaf even if the list is overflowed
  if FMap.Leafs[LLeafNum].Cluster <> -1 then
    AList.LastLeaf := LLeafNum;

  if AList.Count >= AList.MaxCount then
  begin
    AList.Overflowed := True;
    Exit;
  end;
  AList.List[AList.Count] := LLeafNum;
  Inc(AList.Count);
end;

procedure TQ3LeafLister.StoreBrushes(var AList: TQ3LeafList; const ANodeNum: Integer);
var
  LLeaf: PQ3Leaf;
  LIndex, LK, LBrushNum: Integer;
  LBrush: PQ3Brush;
begin
  LLeaf := @FMap.Leafs[-1 - ANodeNum];

  for LK := 0 to LLeaf^.NumLeafBrushes - 1 do
  begin
    LBrushNum := FMap.LeafBrushes[LLeaf^.FirstLeafBrush + LK];
    LBrush := @FMap.Brushes[LBrushNum];
    if LBrush^.CheckCount = FMap.CheckCount then
      Continue; // already checked this brush in another leaf
    LBrush^.CheckCount := FMap.CheckCount;
    LIndex := 0;
    while LIndex < 3 do
    begin
      if (LBrush^.Bounds[0][LIndex] >= AList.Bounds[1][LIndex]) or
         (LBrush^.Bounds[1][LIndex] <= AList.Bounds[0][LIndex]) then
        Break;
      Inc(LIndex);
    end;
    if LIndex <> 3 then
      Continue;
    if AList.Count >= AList.MaxCount then
    begin
      AList.Overflowed := True;
      Exit;
    end;
    AList.List[AList.Count] := LBrushNum;
    Inc(AList.Count);
  end;
end;

procedure TQ3LeafLister.Walk(var AList: TQ3LeafList; ANodeNum: Integer);
var
  LNode: PQ3Node;
  LSide: Integer;
begin
  while True do
  begin
    if ANodeNum < 0 then
    begin
      if AList.StoreBrushes then
        StoreBrushes(AList, ANodeNum)
      else
        StoreLeafs(AList, ANodeNum);
      Exit;
    end;

    LNode := @FMap.Nodes[ANodeNum];
    LSide := TQ3Math.BoxOnPlaneSide(AList.Bounds[0], AList.Bounds[1], FMap.Planes[LNode^.PlaneNum]);
    if LSide = 1 then
      ANodeNum := LNode^.Children[0]
    else if LSide = 2 then
      ANodeNum := LNode^.Children[1]
    else
    begin
      // go down both
      Walk(AList, LNode^.Children[0]);
      ANodeNum := LNode^.Children[1];
    end;
  end;
end;

function TQ3LeafLister.BoxLeafnums(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer;
  out ALeafs: TArray<Integer>; out ALastLeaf: Integer): Integer;
var
  LList: TQ3LeafList;
begin
  Inc(FMap.CheckCount);
  Start(LList, AMins, AMaxs, AMaxCount, False);
  // the original reads the nodes of a map that is not loaded
  if FMap.NumNodes > 0 then
    Walk(LList, 0);
  ALastLeaf := LList.LastLeaf;
  SetLength(LList.List, LList.Count);
  ALeafs := LList.List;
  Result := LList.Count;
end;

function TQ3LeafLister.BoxBrushes(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer): TArray<Integer>;
var
  LList: TQ3LeafList;
begin
  Inc(FMap.CheckCount);
  Start(LList, AMins, AMaxs, AMaxCount, True);
  if FMap.NumNodes > 0 then
    Walk(LList, 0);
  SetLength(LList.List, LList.Count);
  Result := LList.List;
end;

end.
