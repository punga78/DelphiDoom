{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib containers - the scenarios of the golden     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Containers.Cases;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The same scenarios as the C++ harness that wrote containers.golden.txt (hash index, link
  ///   list, hierarchy, B-tree, binary search, string pool), each as its own procedure so that
  ///   a fixture per class can compare its part
  /// </summary>
  TIdLibContainersCases = class
  public
    class procedure HashIndex(const ALines: TStrings); static;
    class procedure LinkList(const ALines: TStrings); static;
    class procedure Hierarchy(const ALines: TStrings); static;
    class procedure BTree(const ALines: TStrings); static;
    class procedure BinSearch(const ALines: TStrings); static;
    class procedure StrPool(const ALines: TStrings); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Containers.HashIndex, DelphiDoom.IdLib.Containers.LinkList,
  DelphiDoom.IdLib.Containers.Hierarchy, DelphiDoom.IdLib.Containers.BTree,
  DelphiDoom.IdLib.Containers.BinSearch, DelphiDoom.IdLib.Containers.StrPool;

var
  GRandom: Cardinal;

function Rnd: Integer;
begin
  GRandom := GRandom * 1664525 + 1013904223;
  Result := Integer(GRandom shr 16);
end;

function B(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

// ---------------------------------------------------------------- hash index

procedure DumpHash(const ALines: TStrings; const AHash: TIdHashIndex; const APrefix: string = '');
var
  LLine: string;
  LKey, LCount, LIndex: Integer;
begin
  LLine := APrefix + Format('  sizes %d %d spread %d chains', [AHash.GetHashSize, AHash.GetIndexSize, AHash.GetSpread]);
  for LKey := 0 to 15 do
  begin
    LLine := LLine + ' [';
    LCount := 0;
    LIndex := AHash.First(LKey);
    while (LIndex <> -1) and (LCount < 40) do
    begin
      LLine := LLine + IntToStr(LIndex) + ',';
      LIndex := AHash.Next(LIndex);
      Inc(LCount);
    end;
    LLine := LLine + ']';
  end;
  ALines.Add(LLine);
end;

class procedure TIdLibContainersCases.HashIndex(const ALines: TStrings);
const
  WORDS: array[0..6] of AnsiString = ('', 'a', 'hello', 'Hello', 'HELLO world', 'textures/common/caulk', #$E9't'#$E9);
var
  LVariant, LHashSize, LStep, LOp, LR1, LR2, LCount, LKey, LPos, LIndex, LWalk, LNs: Integer;
  LHash, LCopy: TIdHashIndex;
  LKeys: array[0..1023] of Integer;
  LLine: string;
begin
  ALines.Add('== hashindex');
  for LVariant := 0 to 2 do
  begin
    GRandom := Cardinal(1000 + LVariant);
    case LVariant of
      0: LHashSize := 16;
      1: LHashSize := 64;
    else
      LHashSize := 1024;
    end;
    if LVariant = 2 then
      LHash := TIdHashIndex.Create(LHashSize, 4)
    else
      LHash := TIdHashIndex.Create(LHashSize, 8);
    try
      if LVariant = 1 then
        LHash.SetGranularity(8);
      LCount := 0;
      ALines.Add(Format('variant %d', [LVariant]));
      DumpHash(ALines, LHash);
      for LStep := 0 to 149 do
      begin
        LOp := Rnd mod 8;
        LR1 := Rnd;
        LR2 := Rnd;
        LLine := Format('step %d op %d:', [LStep, LOp]);
        case LOp of
          0, 1:
            begin
              LKey := LR1 mod 300;
              LHash.Add(LKey, LCount);
              LKeys[LCount] := LKey;
              Inc(LCount);
              ALines.Add(LLine + Format(' add key=%d idx=%d', [LKey, LCount - 1]));
            end;
          2:
            if LCount > 0 then
            begin
              LIndex := LR1 mod LCount;
              LHash.Remove(LKeys[LIndex], LIndex);
              ALines.Add(LLine + Format(' remove %d', [LIndex]));
            end
            else
              ALines.Add(LLine + ' nop');
          3:
            begin
              if LCount > 0 then
                LPos := LR1 mod (LCount + 1)
              else
                LPos := 0;
              LKey := LR2 mod 300;
              LHash.InsertIndex(LKey, LPos);
              for LIndex := LCount downto LPos + 1 do
                LKeys[LIndex] := LKeys[LIndex - 1];
              LKeys[LPos] := LKey;
              Inc(LCount);
              ALines.Add(LLine + Format(' insertindex key=%d pos=%d', [LKey, LPos]));
            end;
          4:
            if LCount > 0 then
            begin
              LIndex := LR1 mod LCount;
              LHash.RemoveIndex(LKeys[LIndex], LIndex);
              for LWalk := LIndex to LCount - 2 do
                LKeys[LWalk] := LKeys[LWalk + 1];
              Dec(LCount);
              ALines.Add(LLine + Format(' removeindex %d', [LIndex]));
            end
            else
              ALines.Add(LLine + ' nop');
          5:
            begin
              LKey := LR1 mod 300;
              LLine := LLine + Format(' walk key=%d:', [LKey]);
              LWalk := 0;
              LIndex := LHash.First(LKey);
              while (LIndex <> -1) and (LWalk < 60) do
              begin
                LLine := LLine + ' ' + IntToStr(LIndex);
                LIndex := LHash.Next(LIndex);
                Inc(LWalk);
              end;
              ALines.Add(LLine);
            end;
          6:
            if (LR1 mod 6) = 0 then
            begin
              LHash.Clear;
              LCount := 0;
              ALines.Add(LLine + ' clear');
            end
            else
              ALines.Add(LLine + ' nop');
          7:
            begin
              LNs := LCount + (LR1 mod 40);
              LHash.ResizeIndex(LNs);
              ALines.Add(LLine + Format(' resize %d', [LNs]));
            end;
        end;
        DumpHash(ALines, LHash);
      end;
      LCopy := TIdHashIndex.Create;
      try
        LCopy.Assign(LHash);
        DumpHash(ALines, LCopy, 'copy:');
      finally
        LCopy.Free;
      end;
      LHash.FreeMemory;
      DumpHash(ALines, LHash, 'freed:');
      LHash.Clear(32, 16);
      DumpHash(ALines, LHash, 'cleared:');
      ALines.Add(Format('alloc %d', [LHash.Allocated]));
    finally
      LHash.Free;
    end;
  end;
  LHash := TIdHashIndex.Create(256, 16);
  try
    for LIndex := 0 to 6 do
      ALines.Add(Format('key %d %d %d', [LIndex, LHash.GenerateKey(WORDS[LIndex], True),
        LHash.GenerateKey(WORDS[LIndex], False)]));
    ALines.Add(Format('vkey %d %d', [0, LHash.GenerateKey(0, 0, 0)]));
    ALines.Add(Format('vkey %d %d', [1, LHash.GenerateKey(1.5, 2.5, 3.5)]));
    ALines.Add(Format('vkey %d %d', [2, LHash.GenerateKey(-1.5, -2.5, -3.5)]));
    ALines.Add(Format('vkey %d %d', [3, LHash.GenerateKey(100.9, 200.9, 300.9)]));
    ALines.Add(Format('vkey %d %d', [4, LHash.GenerateKey(-0.5, 0.5, 7)]));
    ALines.Add(Format('ikey %d %d %d', [LHash.GenerateKey(3, 4), LHash.GenerateKey(300, 400), LHash.GenerateKey(-3, 1)]));
  finally
    LHash.Free;
  end;
end;

// ---------------------------------------------------------------- link list

type
  TLinkItem = class
  public
    Id: Integer;
    Node: TIdLinkList<TLinkItem>;
    constructor Create(const AId: Integer);
    destructor Destroy; override;
  end;

constructor TLinkItem.Create(const AId: Integer);
begin
  inherited Create;
  Id := AId;
  Node := TIdLinkList<TLinkItem>.Create;
  Node.SetOwner(Self);
end;

destructor TLinkItem.Destroy;
begin
  Node.Free;
  inherited Destroy;
end;

function LinkId(const AItem: TLinkItem): Integer;
begin
  if Assigned(AItem) then
    Result := AItem.Id
  else
    Result := -1;
end;

class procedure TIdLibContainersCases.LinkList(const ALines: TStrings);
var
  LItems: array[0..11] of TLinkItem;
  LHead: TIdLinkList<TLinkItem>;
  LStep, LOp, LA, LB, LIndex: Integer;
  LLine, LSign: string;
  LNode: TIdLinkList<TLinkItem>;
  LNext, LPrev: TLinkItem;
begin
  ALines.Add('== linklist');
  GRandom := 77;
  LHead := TIdLinkList<TLinkItem>.Create;
  try
    for LIndex := 0 to 11 do
      LItems[LIndex] := TLinkItem.Create(LIndex);
    try
      for LStep := 0 to 299 do
      begin
        LOp := Rnd mod 8;
        LA := Rnd mod 12;
        LB := Rnd mod 12;
        LLine := Format('step %d op %d a=%d b=%d:', [LStep, LOp, LA, LB]);
        case LOp of
          0: if LA <> LB then LItems[LA].Node.InsertBefore(LItems[LB].Node);
          1: if LA <> LB then LItems[LA].Node.InsertAfter(LItems[LB].Node);
          2: LItems[LA].Node.AddToEnd(LHead);
          3: LItems[LA].Node.AddToFront(LHead);
          4: LItems[LA].Node.Remove;
          5: if (Rnd mod 10) = 0 then LHead.Clear;
          6: LItems[LA].Node.Clear;
          7: if LA <> LB then LItems[LA].Node.AddToEnd(LItems[LB].Node);
        end;
        LLine := LLine + Format(' num=%d empty=%d list:', [LHead.Num, B(LHead.IsListEmpty)]);
        LNode := LHead.NextNode;
        while Assigned(LNode) do
        begin
          LLine := LLine + ' ' + IntToStr(LNode.Owner.Id);
          LNode := LNode.NextNode;
        end;
        LLine := LLine + ' | back:';
        LNode := LHead.PrevNode;
        while Assigned(LNode) do
        begin
          LLine := LLine + ' ' + IntToStr(LNode.Owner.Id);
          LNode := LNode.PrevNode;
        end;
        LLine := LLine + ' | in:';
        for LIndex := 0 to 11 do
        begin
          LNext := LItems[LIndex].Node.Next;
          LPrev := LItems[LIndex].Node.Prev;
          if LItems[LIndex].Node.InList then
            LSign := '+'
          else
            LSign := '-';
          LLine := LLine + Format(' %d%s%d,%d', [LIndex, LSign, LinkId(LNext), LinkId(LPrev)]);
        end;
        ALines.Add(LLine);
      end;
    finally
      // the nodes leave their list when freed, the head last as in the C++ scope
      for LIndex := 0 to 11 do
        LItems[LIndex].Free;
    end;
  finally
    LHead.Free;
  end;
end;

// ---------------------------------------------------------------- hierarchy

type
  THierItem = class
  public
    Id: Integer;
    Node: TIdHierarchy<THierItem>;
    constructor Create(const AId: Integer);
    destructor Destroy; override;
  end;

constructor THierItem.Create(const AId: Integer);
begin
  inherited Create;
  Id := AId;
  Node := TIdHierarchy<THierItem>.Create;
  Node.SetOwner(Self);
end;

destructor THierItem.Destroy;
begin
  Node.Free;
  inherited Destroy;
end;

function HierId(const AItem: THierItem): Integer;
begin
  if Assigned(AItem) then
    Result := AItem.Id
  else
    Result := -1;
end;

class procedure TIdLibContainersCases.Hierarchy(const ALines: TStrings);
var
  LItems: array[0..13] of THierItem;
  LStep, LOp, LA, LB, LIndex, LCount: Integer;
  LLine: string;
  LX: THierItem;
begin
  ALines.Add('== hierarchy');
  GRandom := 4242;
  for LIndex := 0 to 13 do
    LItems[LIndex] := THierItem.Create(LIndex);
  try
    for LStep := 0 to 299 do
    begin
      LOp := Rnd mod 6;
      LA := Rnd mod 14;
      LB := Rnd mod 14;
      LLine := Format('step %d op %d a=%d b=%d:', [LStep, LOp, LA, LB]);
      case LOp of
        0: if (LA <> LB) and not LItems[LB].Node.ParentedBy(LItems[LA].Node) then LItems[LA].Node.ParentTo(LItems[LB].Node);
        1: if (LA <> LB) and not LItems[LB].Node.ParentedBy(LItems[LA].Node) then LItems[LA].Node.MakeSiblingAfter(LItems[LB].Node);
        2: LItems[LA].Node.RemoveFromParent;
        3: LItems[LA].Node.RemoveFromHierarchy;
      end;
      ALines.Add(LLine);
      LLine := '  links:';
      for LIndex := 0 to 13 do
        LLine := LLine + Format(' %d(%d,%d,%d,%d)', [LIndex, HierId(LItems[LIndex].Node.GetParent),
          HierId(LItems[LIndex].Node.GetChild), HierId(LItems[LIndex].Node.GetSibling),
          HierId(LItems[LIndex].Node.GetPriorSibling)]);
      ALines.Add(LLine);
      LLine := '  walk:';
      for LIndex := 0 to 13 do
      begin
        if LItems[LIndex].Node.GetParent <> nil then
          Continue;
        LLine := LLine + Format(' r%d:', [LIndex]);
        LCount := 0;
        LX := LItems[LIndex];
        while Assigned(LX) and (LCount < 30) do
        begin
          LLine := LLine + IntToStr(LX.Id) + ',';
          LX := LX.Node.GetNext;
          Inc(LCount);
        end;
        LLine := LLine + 'L:';
        LCount := 0;
        LX := LItems[LIndex].Node.GetNextLeaf;
        while Assigned(LX) and (LCount < 30) do
        begin
          LLine := LLine + IntToStr(LX.Id) + ',';
          LX := LX.Node.GetNextLeaf;
          Inc(LCount);
        end;
      end;
      ALines.Add(LLine);
    end;
  finally
    for LIndex := 0 to 13 do
      LItems[LIndex].Free;
  end;
end;

// ---------------------------------------------------------------- B-tree

type
  TTreeObject = class
  public
    Id: Integer;
  end;

procedure DumpBTree(const ALines: TStrings; const ATree: TIdBTree<TTreeObject, Integer>);
var
  LLine: string;
  LNode: TIdBTree<TTreeObject, Integer>.TNode;
  LCount, LValue: Integer;
begin
  LLine := Format('  nodes %d tree:', [ATree.GetNodeCount]);
  LCount := 0;
  LNode := ATree.GetRoot;
  while Assigned(LNode) and (LCount < 400) do
  begin
    if Assigned(LNode.Obj) then
      LValue := LNode.Obj.Id
    else
      LValue := -1;
    LLine := LLine + Format(' (%d,%d,%d)', [LNode.Key, LNode.NumChildren, LValue]);
    LNode := ATree.GetNext(LNode);
    Inc(LCount);
  end;
  ALines.Add(LLine);
  LLine := '  leaves:';
  LCount := 0;
  LNode := ATree.GetNextLeaf(ATree.GetRoot);
  while Assigned(LNode) and (LCount < 400) do
  begin
    LLine := LLine + ' ' + IntToStr(LNode.Key);
    LNode := ATree.GetNextLeaf(LNode);
    Inc(LCount);
  end;
  ALines.Add(LLine);
end;

function ObjId(const AObject: TTreeObject): Integer;
begin
  if Assigned(AObject) then
    Result := AObject.Id
  else
    Result := -1;
end;

class procedure TIdLibContainersCases.BTree(const ALines: TStrings);
var
  LTree: TIdBTree<TTreeObject, Integer>;
  LObjects: array[0..399] of TTreeObject;
  LNodes: array[0..399] of TIdBTree<TTreeObject, Integer>.TNode;
  LAlive: array[0..399] of Boolean;
  LCount, LStep, LOp, LR1, LKey, LIndex: Integer;
begin
  ALines.Add('== btree');
  GRandom := 31337;
  LTree := TIdBTree<TTreeObject, Integer>.Create(5);
  try
    LCount := 0;
    for LStep := 0 to 399 do
    begin
      LOp := Rnd mod 5;
      LR1 := Rnd;
      if (LOp <= 2) or (LCount = 0) then
      begin
        LKey := LR1 mod 120;
        LObjects[LCount] := TTreeObject.Create;
        LObjects[LCount].Id := LCount;
        LNodes[LCount] := LTree.Add(LObjects[LCount], LKey);
        LAlive[LCount] := True;
        ALines.Add(Format('step %d op %d: add key=%d obj=%d', [LStep, LOp, LKey, LCount]));
        Inc(LCount);
      end
      else if LOp = 3 then
      begin
        LIndex := LR1 mod LCount;
        if LAlive[LIndex] then
        begin
          LTree.Remove(LNodes[LIndex]);
          LAlive[LIndex] := False;
          ALines.Add(Format('step %d op %d: remove %d', [LStep, LOp, LIndex]));
        end
        else
          ALines.Add(Format('step %d op %d: nop', [LStep, LOp]));
      end
      else
      begin
        LKey := LR1 mod 130 - 5;
        ALines.Add(Format('step %d op %d: find %d -> %d %d %d', [LStep, LOp, LKey, ObjId(LTree.Find(LKey)),
          ObjId(LTree.FindSmallestLargerEqual(LKey)), ObjId(LTree.FindLargestSmallerEqual(LKey))]));
      end;
      if ((LStep mod 7) = 0) or (LStep > 380) then
        DumpBTree(ALines, LTree);
    end;
  finally
    LTree.Free;
    for LIndex := 0 to LCount - 1 do
      LObjects[LIndex].Free;
  end;
end;

// ---------------------------------------------------------------- binary search

class procedure TIdLibContainersCases.BinSearch(const ALines: TStrings);
const
  ARRAYS: array[0..2, 0..11] of Integer = (
    (1, 3, 3, 3, 5, 7, 7, 9, 10, 10, 12, 15),
    (2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2),
    (-5, -3, 0, 1, 2, 4, 8, 16, 32, 64, 128, 256));
  SIZES: array[0..2] of Integer = (12, 7, 12);
var
  LA, LSize, LValue: Integer;
  LData: array[0..11] of Integer;
  LIndex: Integer;
begin
  ALines.Add('== binsearch');
  for LA := 0 to 2 do
  begin
    for LIndex := 0 to 11 do
      LData[LIndex] := ARRAYS[LA, LIndex];
    LSize := 0;
    while LSize <= SIZES[LA] do
    begin
      LValue := -7;
      while LValue <= 260 do
      begin
        if LSize = 0 then
          ALines.Add(Format('a%d n%d v%d skip', [LA, LSize, LValue]))
        else
          ALines.Add(Format('a%d n%d v%d %d %d %d %d', [LA, LSize, LValue, TIdBinSearch<Integer>.Less(LData, LSize, LValue),
            TIdBinSearch<Integer>.LessEqual(LData, LSize, LValue), TIdBinSearch<Integer>.Greater(LData, LSize, LValue),
            TIdBinSearch<Integer>.GreaterEqual(LData, LSize, LValue)]));
        if LValue < 20 then
          Inc(LValue)
        else
          Inc(LValue, 17);
      end;
      if LSize < 3 then
        Inc(LSize)
      else
        Inc(LSize, 4);
    end;
  end;
end;

// ---------------------------------------------------------------- string pool

procedure DumpPool(const ALines: TStrings; const APool: TIdStrPool; const AName: string);
var
  LLine: string;
  LIndex: Integer;
begin
  LLine := Format('  %s num=%d:', [AName, APool.Num]);
  for LIndex := 0 to APool.Num - 1 do
    LLine := LLine + ' ' + string(APool[LIndex].Text);
  ALines.Add(LLine);
end;

function PoolIndex(const APool: TIdStrPool; const AString: TIdPoolStr): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to APool.Num - 1 do
    if APool[LIndex] = AString then
      Result := LIndex;
end;

class procedure TIdLibContainersCases.StrPool(const ALines: TStrings);
const
  WORDS: array[0..11] of AnsiString = ('alpha', 'Alpha', 'ALPHA', 'beta', 'Beta', 'gamma', 'delta', 'textures/a',
    'TEXTURES/A', '', 'x', 'X');
var
  LPools: array[0..1] of TIdStrPool;
  LHeld: array[0..1, 0..199] of TIdPoolStr;
  LNumHeld: array[0..1] of Integer;
  LStep, LOp, LP, LW, LR, LIdx, LIndex: Integer;
  LString: TIdPoolStr;
  LLine: string;
begin
  ALines.Add('== strpool');
  GRandom := 555;
  LPools[0] := TIdStrPool.Create;
  LPools[1] := TIdStrPool.Create;
  try
    LPools[1].SetCaseSensitive(False);
    LNumHeld[0] := 0;
    LNumHeld[1] := 0;
    for LStep := 0 to 199 do
    begin
      LOp := Rnd mod 4;
      LP := Rnd mod 2;
      LW := Rnd mod 12;
      LR := Rnd;
      LLine := Format('step %d op %d pool %d:', [LStep, LOp, LP]);
      if LOp <= 1 then
      begin
        LString := LPools[LP].AllocString(WORDS[LW]);
        LHeld[LP, LNumHeld[LP]] := LString;
        Inc(LNumHeld[LP]);
        ALines.Add(LLine + Format(' alloc %s -> %d', [string(WORDS[LW]), PoolIndex(LPools[LP], LString)]));
      end
      else if (LOp = 2) and (LNumHeld[LP] > 0) then
      begin
        LIndex := LR mod LNumHeld[LP];
        LPools[LP].FreeString(LHeld[LP, LIndex]);
        Dec(LNumHeld[LP]);
        LHeld[LP, LIndex] := LHeld[LP, LNumHeld[LP]];
        ALines.Add(LLine + Format(' free %d', [LIndex]));
      end
      else if (LOp = 3) and (LNumHeld[1 - LP] > 0) then
      begin
        LIndex := LR mod LNumHeld[1 - LP];
        LString := LPools[LP].CopyString(LHeld[1 - LP, LIndex]);
        LHeld[LP, LNumHeld[LP]] := LString;
        Inc(LNumHeld[LP]);
        LIdx := PoolIndex(LPools[LP], LString);
        ALines.Add(LLine + Format(' copy -> %d (same pool %d)', [LIdx, B(LString.Pool = LPools[LP])]));
      end
      else
        ALines.Add(LLine + ' nop');
      DumpPool(ALines, LPools[0], 'p0');
      DumpPool(ALines, LPools[1], 'p1');
    end;
  finally
    LPools[1].Free;
    LPools[0].Free;
  end;
end;

end.
