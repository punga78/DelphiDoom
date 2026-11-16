{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the octree color quantizer                        }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL, from            }
{  rosettacode.org)                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Quantizer;

interface

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The reduction of the colors of a voxel to at most 256 (vxe_quantize of DD_VOXEL): an octree of the colors
  ///   with the nodes that cost less folded first into their parent, kept in a heap. The nodes are the cells of an
  ///   array and the pointers of the old code are indexes (0 is "none"); the heap and the order of the folds are
  ///   the same, so the colors are the same
  /// </summary>
  TVoxelEditorQuantizer = class
  strict private
    type
      TNode = record
        R, G, B: Int64;
        Count, HeapIndex: Integer;
        Kids: array[0..7] of Integer;
        Parent: Integer;
        KidCount, KidIndex, Flags, Depth: Byte;
      end;
    const
      ON_HEAP = 1;
  strict private
    FNodes: TArray<TNode>;
    FNodeCount: Integer;
    FHeap: TArray<Integer>;
    FHeapCount: Integer;
    FRoot: Integer;
    function NewNode(AIndex, ADepth: Byte; AParent: Integer): Integer;
    function Compare(AFirst, ASecond: Integer): Integer;
    procedure DownHeap(ANode: Integer);
    procedure UpHeap(ANode: Integer);
    procedure HeapAdd(ANode: Integer);
    function PopHeap: Integer;
    function Insert(AColor: Cardinal): Integer;
    function Fold(ANode: Integer): Integer;
    class function BitValue(AValue: Integer): Byte; static; inline;
  public
    /// <summary>The tree of the colors, reduced to ANumColors leaves (and the mean color of each leaf)</summary>
    constructor Create(const AColors: TArray<Cardinal>; ANumColors: Integer);
    /// <summary>The color of the leaf that holds AColor; a result of 0 is made 1 unless AAllowZero</summary>
    function Lookup(AColor: Cardinal; AAllowZero: Boolean): Cardinal;
    /// <summary>
    ///   The palette of a voxel with at most ANumColors colors (up to 256), in the order the colors are met: the
    ///   colors of the voxel themselves if they are few, else the reduced ones. False if it cannot be done
    /// </summary>
    class function GetPalette(const AModel: TVoxelEditorModel; ANumColors: Integer;
      var APalette: TVoxelEditorPalette): Boolean; static;
    /// <summary>Every color of the voxel becomes the color of its leaf (the command "Optimized Octree")</summary>
    class procedure Quantize(const AModel: TVoxelEditorModel; ANumColors: Integer); static;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections;

{ TVoxelEditorQuantizer }

class function TVoxelEditorQuantizer.BitValue(AValue: Integer): Byte;
begin
  if AValue <> 0 then
    Result := 1
  else
    Result := 0;
end;

function TVoxelEditorQuantizer.NewNode(AIndex, ADepth: Byte; AParent: Integer): Integer;
begin
  // the nodes are numbered from 1: the new one needs the cell FNodeCount + 1
  if FNodeCount + 1 >= Length(FNodes) then
    SetLength(FNodes, Length(FNodes) * 2 + 2048);
  Inc(FNodeCount);
  Result := FNodeCount; // node 0 is "none"
  FillChar(FNodes[Result], SizeOf(TNode), 0);
  FNodes[Result].KidIndex := AIndex;
  FNodes[Result].Depth := ADepth;
  FNodes[Result].Parent := AParent;
  if AParent <> 0 then
    Inc(FNodes[AParent].KidCount);
end;

// the order of the heap decides which node is folded next: the fewest kids first, then the cheapest
function TVoxelEditorQuantizer.Compare(AFirst, ASecond: Integer): Integer;
var
  LFirstCost, LSecondCost: Integer;
begin
  if FNodes[AFirst].KidCount < FNodes[ASecond].KidCount then
    Exit(-1);
  if FNodes[AFirst].KidCount > FNodes[ASecond].KidCount then
    Exit(1);
  LFirstCost := (FNodes[AFirst].Count * (1 + FNodes[AFirst].KidIndex)) shr FNodes[AFirst].Depth;
  LSecondCost := (FNodes[ASecond].Count * (1 + FNodes[ASecond].KidIndex)) shr FNodes[ASecond].Depth;
  if LFirstCost < LSecondCost then
    Result := -1
  else if LFirstCost > LSecondCost then
    Result := 1
  else
    Result := 0;
end;

procedure TVoxelEditorQuantizer.DownHeap(ANode: Integer);
var
  LPosition, LChild: Integer;
begin
  LPosition := FNodes[ANode].HeapIndex;
  while True do
  begin
    LChild := LPosition * 2;
    if LChild >= FHeapCount then
      Break;
    if (LChild + 1 < FHeapCount) and (Compare(FHeap[LChild], FHeap[LChild + 1]) > 0) then
      Inc(LChild);
    if Compare(ANode, FHeap[LChild]) <= 0 then
      Break;
    FHeap[LPosition] := FHeap[LChild];
    FNodes[FHeap[LPosition]].HeapIndex := LPosition;
    LPosition := LChild;
  end;
  FHeap[LPosition] := ANode;
  FNodes[ANode].HeapIndex := LPosition;
end;

procedure TVoxelEditorQuantizer.UpHeap(ANode: Integer);
var
  LPosition, LParent: Integer;
begin
  LPosition := FNodes[ANode].HeapIndex;
  while LPosition > 1 do
  begin
    LParent := FHeap[LPosition div 2];
    if Compare(ANode, LParent) >= 0 then
      Break;
    FHeap[LPosition] := LParent;
    FNodes[LParent].HeapIndex := LPosition;
    LPosition := LPosition div 2;
  end;
  FHeap[LPosition] := ANode;
  FNodes[ANode].HeapIndex := LPosition;
end;

procedure TVoxelEditorQuantizer.HeapAdd(ANode: Integer);
begin
  if FNodes[ANode].Flags and ON_HEAP <> 0 then
  begin
    DownHeap(ANode);
    UpHeap(ANode);
    Exit;
  end;
  FNodes[ANode].Flags := FNodes[ANode].Flags or ON_HEAP;
  if FHeapCount = 0 then
    FHeapCount := 1;
  if FHeapCount >= Length(FHeap) then
    SetLength(FHeap, Length(FHeap) + 1024);
  FNodes[ANode].HeapIndex := FHeapCount;
  FHeap[FHeapCount] := ANode;
  Inc(FHeapCount);
  UpHeap(ANode);
end;

function TVoxelEditorQuantizer.PopHeap: Integer;
begin
  if FHeapCount <= 1 then
    Exit(0);
  Result := FHeap[1];
  Dec(FHeapCount);
  FHeap[1] := FHeap[FHeapCount];
  FHeap[FHeapCount] := 0;
  FNodes[FHeap[1]].HeapIndex := 1;
  DownHeap(FHeap[1]);
end;

function TVoxelEditorQuantizer.Insert(AColor: Cardinal): Integer;
var
  LNode, LDepth, LKid, LNew: Integer;
  LRed, LGreen, LBlue, LBit: Byte;
begin
  LRed := AColor and $FF;
  LGreen := (AColor shr 8) and $FF;
  LBlue := (AColor shr 16) and $FF;
  LBit := 1 shl 7;
  LNode := FRoot;
  for LDepth := 0 to 7 do
  begin
    LKid := (1 - BitValue(LGreen and LBit)) * 4 + (1 - BitValue(LRed and LBit)) * 2 + (1 - BitValue(LBlue and LBit));
    if FNodes[LNode].Kids[LKid] = 0 then
    begin
      // NewNode can move the array: its result is taken before the cell is addressed
      LNew := NewNode(LKid, LDepth, LNode);
      FNodes[LNode].Kids[LKid] := LNew;
    end;
    LNode := FNodes[LNode].Kids[LKid];
    LBit := LBit shr 1;
  end;
  Inc(FNodes[LNode].R, LRed);
  Inc(FNodes[LNode].G, LGreen);
  Inc(FNodes[LNode].B, LBlue);
  Inc(FNodes[LNode].Count);
  Result := LNode;
end;

// takes a node out of the tree: its count and colors go to the parent
function TVoxelEditorQuantizer.Fold(ANode: Integer): Integer;
var
  LParent: Integer;
begin
  if FNodes[ANode].KidCount > 0 then
    Exit(0);
  LParent := FNodes[ANode].Parent;
  Inc(FNodes[LParent].Count, FNodes[ANode].Count);
  Inc(FNodes[LParent].R, FNodes[ANode].R);
  Inc(FNodes[LParent].G, FNodes[ANode].G);
  Inc(FNodes[LParent].B, FNodes[ANode].B);
  Dec(FNodes[LParent].KidCount);
  FNodes[LParent].Kids[FNodes[ANode].KidIndex] := 0;
  Result := LParent;
end;

constructor TVoxelEditorQuantizer.Create(const AColors: TArray<Cardinal>; ANumColors: Integer);
var
  LIndex, LNode: Integer;
  LCount: Double;
begin
  inherited Create;
  FRoot := NewNode(0, 0, 0);
  for LIndex := 0 to High(AColors) do
    HeapAdd(Insert(AColors[LIndex]));
  while FHeapCount > ANumColors + 1 do
    HeapAdd(Fold(PopHeap));
  for LIndex := 1 to FHeapCount - 1 do
  begin
    LNode := FHeap[LIndex];
    LCount := FNodes[LNode].Count;
    FNodes[LNode].R := Round(FNodes[LNode].R / LCount);
    FNodes[LNode].G := Round(FNodes[LNode].G / LCount);
    FNodes[LNode].B := Round(FNodes[LNode].B / LCount);
    if FNodes[LNode].R < 0 then FNodes[LNode].R := 0 else if FNodes[LNode].R > 255 then FNodes[LNode].R := 255;
    if FNodes[LNode].G < 0 then FNodes[LNode].G := 0 else if FNodes[LNode].G > 255 then FNodes[LNode].G := 255;
    if FNodes[LNode].B < 0 then FNodes[LNode].B := 0 else if FNodes[LNode].B > 255 then FNodes[LNode].B := 255;
  end;
end;

function TVoxelEditorQuantizer.Lookup(AColor: Cardinal; AAllowZero: Boolean): Cardinal;
var
  LNode, LKid: Integer;
  LRed, LGreen, LBlue, LBit: Byte;
begin
  LRed := AColor and $FF;
  LGreen := (AColor shr 8) and $FF;
  LBlue := (AColor shr 16) and $FF;
  LBit := 1 shl 7;
  LNode := FRoot;
  while LBit <> 0 do
  begin
    LKid := (1 - BitValue(LGreen and LBit)) * 4 + (1 - BitValue(LRed and LBit)) * 2 + (1 - BitValue(LBlue and LBit));
    if FNodes[LNode].Kids[LKid] = 0 then
      Break;
    LNode := FNodes[LNode].Kids[LKid];
    LBit := LBit shr 1;
  end;
  LRed := Byte(FNodes[LNode].R);
  LGreen := Byte(FNodes[LNode].G);
  LBlue := Byte(FNodes[LNode].B);
  Result := LRed or (Cardinal(LGreen) shl 8) or (Cardinal(LBlue) shl 16);
  if (not AAllowZero) and (Result = 0) then
    Result := 1;
end;

class function TVoxelEditorQuantizer.GetPalette(const AModel: TVoxelEditorModel; ANumColors: Integer;
  var APalette: TVoxelEditorPalette): Boolean;
var
  LIndex: Integer;
  LColors: TList<Cardinal>;
  LAll: TArray<Cardinal>;
  LAllCount: Integer;
  LQuantizer: TVoxelEditorQuantizer;
  LCell: Cardinal;
begin
  if ANumColors > 256 then
    Exit(False);
  LColors := TList<Cardinal>.Create;
  try
    SetLength(LAll, AModel.CountVoxels);
    LAllCount := 0;
    for LIndex := 0 to High(AModel.Cells) do
    begin
      LCell := AModel.Cells[LIndex];
      if LCell <> 0 then
      begin
        LAll[LAllCount] := LCell;
        Inc(LAllCount);
        if LColors.Count <= ANumColors + 1 then
          if LColors.IndexOf(LCell) < 0 then
            LColors.Add(LCell);
      end;
    end;
    if LColors.Count <= ANumColors then
    begin
      for LIndex := 0 to LColors.Count - 1 do
        APalette[LIndex] := LColors[LIndex];
      Exit(True);
    end;
    LColors.Clear;
    LQuantizer := TVoxelEditorQuantizer.Create(LAll, ANumColors);
    try
      for LIndex := 0 to LAllCount - 1 do
      begin
        LCell := LQuantizer.Lookup(LAll[LIndex], False);
        if LColors.IndexOf(LCell) < 0 then
          LColors.Add(LCell);
      end;
    finally
      LQuantizer.Free;
    end;
    Result := LColors.Count <= ANumColors;
    if Result then
      for LIndex := 0 to LColors.Count - 1 do
        APalette[LIndex] := LColors[LIndex];
  finally
    LColors.Free;
  end;
end;

class procedure TVoxelEditorQuantizer.Quantize(const AModel: TVoxelEditorModel; ANumColors: Integer);
var
  LIndex, LCount: Integer;
  LAll: TArray<Cardinal>;
  LQuantizer: TVoxelEditorQuantizer;
begin
  SetLength(LAll, AModel.CountVoxels);
  LCount := 0;
  for LIndex := 0 to High(AModel.Cells) do
    if AModel.Cells[LIndex] <> 0 then
    begin
      LAll[LCount] := AModel.Cells[LIndex];
      Inc(LCount);
    end;
  LQuantizer := TVoxelEditorQuantizer.Create(LAll, ANumColors);
  try
    for LIndex := 0 to High(AModel.Cells) do
      if AModel.Cells[LIndex] <> 0 then
        AModel.Cells[LIndex] := LQuantizer.Lookup(AModel.Cells[LIndex], False);
  finally
    LQuantizer.Free;
  end;
end;

end.
