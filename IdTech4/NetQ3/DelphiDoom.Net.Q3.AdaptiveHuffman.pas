{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the adaptive Huffman tree of Quake III            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): huffman.c.      }
{  Copyright (C) 1999-2005 id Software, Inc. The algorithm is the Adaptive     }
{  Huffman of Sayood's Data Compression book.                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.AdaptiveHuffman;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types;

type
  /// <summary>
  ///   huff_t: the tree and the list of nodes of one adaptive Huffman coder. The C pointers are indexes:
  ///   a node is an index in the node list, a "head" is an index in the table of slots (node_t** of the
  ///   original), -1 is NULL. The tree is not shared: the compressor and the decompressor of the original
  ///   are two instances
  /// </summary>
  TQ3AdaptiveHuffman = class
  strict private
    const
      NodeCount = 768;
      NullIndex = -1;
    type
      TNode = record
        Left, Right, Parent, Next, Prev: Integer;
        Head: Integer;
        Weight: Integer;
        Symbol: Integer;
      end;
    var
      FBlocNode: Integer;
      FBlocPtrs: Integer;
      FTree: Integer;
      FListHead: Integer;
      FLoc: array[0..Q3_HUFFMAN_MAX] of Integer;
      FFreeList: Integer;
      FNodes: array[0..NodeCount - 1] of TNode;
      FSlots: array[0..NodeCount - 1] of Integer;
    function GetSlot: Integer;
    procedure FreeSlot(ASlot: Integer);
    procedure Swap(ANode1, ANode2: Integer);
    procedure SwapList(ANode1, ANode2: Integer);
    procedure Increment(ANode: Integer);
    procedure Send(ANode, AChild: Integer; var AData: TBytes; var AOffset: Integer);
  public
    /// <summary>A tree with only the NYT node (the state of Huff_Init)</summary>
    constructor Create;
    /// <summary>Huff_putBit: one bit; the byte is cleared when the bit is its first</summary>
    class procedure PutBit(ABit: Integer; var AData: TBytes; var AOffset: Integer); static;
    /// <summary>Huff_getBit; a bit past the end of the buffer is 0 (the original reads outside it)</summary>
    class function GetBit(const AData: TBytes; var AOffset: Integer): Integer; static;
    /// <summary>Huff_addRef: counts one occurrence of a byte and updates the tree</summary>
    procedure AddRef(ASymbol: Byte);
    /// <summary>
    ///   Huff_transmit: the code of a byte; a byte that is not in the tree yet is sent as the code of the
    ///   NYT node followed by its 8 bits
    /// </summary>
    procedure Transmit(ASymbol: Integer; var AData: TBytes; var AOffset: Integer);
    /// <summary>Huff_offsetTransmit: the code of a byte that is in the tree (an error if it is not)</summary>
    procedure OffsetTransmit(ASymbol: Integer; var AData: TBytes; var AOffset: Integer);
    /// <summary>Huff_Receive: walks the tree with the bits; the symbol of the leaf</summary>
    function Receive(const AData: TBytes; var AOffset: Integer): Integer;
    /// <summary>Huff_offsetReceive: as Receive; the leaf that is not there leaves the offset where it was</summary>
    function OffsetReceive(const AData: TBytes; var AOffset: Integer): Integer;
    /// <summary>The nodes used so far (a test of the bound of the node list)</summary>
    property UsedNodes: Integer read FBlocNode;
  end;

implementation

{ TQ3AdaptiveHuffman }

constructor TQ3AdaptiveHuffman.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to Q3_HUFFMAN_MAX do
    FLoc[LIndex] := NullIndex;
  for LIndex := 0 to NodeCount - 1 do
  begin
    FNodes[LIndex].Left := NullIndex;
    FNodes[LIndex].Right := NullIndex;
    FNodes[LIndex].Parent := NullIndex;
    FNodes[LIndex].Next := NullIndex;
    FNodes[LIndex].Prev := NullIndex;
    FNodes[LIndex].Head := NullIndex;
    FNodes[LIndex].Weight := 0;
    FNodes[LIndex].Symbol := 0;
    FSlots[LIndex] := NullIndex;
  end;
  FFreeList := NullIndex;
  FBlocPtrs := 0;
  FBlocNode := 1;
  FTree := 0;
  FListHead := 0;
  FLoc[Q3_HUFFMAN_NYT] := 0;
  FNodes[0].Symbol := Q3_HUFFMAN_NYT;
end;

class procedure TQ3AdaptiveHuffman.PutBit(ABit: Integer; var AData: TBytes; var AOffset: Integer);
var
  LByte: Integer;
begin
  LByte := AOffset shr 3;
  if LByte >= Length(AData) then
    raise EQ3MessageOverflowException.CreateFmt(SQ3MessageBufferOverrun, [LByte, Length(AData)]);
  if (AOffset and 7) = 0 then
    AData[LByte] := 0;
  AData[LByte] := AData[LByte] or Byte(ABit shl (AOffset and 7));
  Inc(AOffset);
end;

class function TQ3AdaptiveHuffman.GetBit(const AData: TBytes; var AOffset: Integer): Integer;
var
  LByte: Integer;
begin
  LByte := AOffset shr 3;
  if (LByte >= 0) and (LByte < Length(AData)) then
    Result := (AData[LByte] shr (AOffset and 7)) and 1
  else
    Result := 0;
  Inc(AOffset);
end;

function TQ3AdaptiveHuffman.GetSlot: Integer;
begin
  if FFreeList = NullIndex then
  begin
    Result := FBlocPtrs;
    Inc(FBlocPtrs);
  end
  else
  begin
    Result := FFreeList;
    FFreeList := FSlots[Result];
  end;
end;

procedure TQ3AdaptiveHuffman.FreeSlot(ASlot: Integer);
begin
  FSlots[ASlot] := FFreeList;
  FFreeList := ASlot;
end;

procedure TQ3AdaptiveHuffman.Swap(ANode1, ANode2: Integer);
var
  LParent1, LParent2: Integer;
begin
  LParent1 := FNodes[ANode1].Parent;
  LParent2 := FNodes[ANode2].Parent;

  if LParent1 <> NullIndex then
  begin
    if FNodes[LParent1].Left = ANode1 then
      FNodes[LParent1].Left := ANode2
    else
      FNodes[LParent1].Right := ANode2;
  end
  else
    FTree := ANode2;

  if LParent2 <> NullIndex then
  begin
    if FNodes[LParent2].Left = ANode2 then
      FNodes[LParent2].Left := ANode1
    else
      FNodes[LParent2].Right := ANode1;
  end
  else
    FTree := ANode1;

  FNodes[ANode1].Parent := LParent2;
  FNodes[ANode2].Parent := LParent1;
end;

procedure TQ3AdaptiveHuffman.SwapList(ANode1, ANode2: Integer);
var
  LTemp: Integer;
begin
  LTemp := FNodes[ANode1].Next;
  FNodes[ANode1].Next := FNodes[ANode2].Next;
  FNodes[ANode2].Next := LTemp;

  LTemp := FNodes[ANode1].Prev;
  FNodes[ANode1].Prev := FNodes[ANode2].Prev;
  FNodes[ANode2].Prev := LTemp;

  if FNodes[ANode1].Next = ANode1 then
    FNodes[ANode1].Next := ANode2;
  if FNodes[ANode2].Next = ANode2 then
    FNodes[ANode2].Next := ANode1;
  if FNodes[ANode1].Next <> NullIndex then
    FNodes[FNodes[ANode1].Next].Prev := ANode1;
  if FNodes[ANode2].Next <> NullIndex then
    FNodes[FNodes[ANode2].Next].Prev := ANode2;
  if FNodes[ANode1].Prev <> NullIndex then
    FNodes[FNodes[ANode1].Prev].Next := ANode1;
  if FNodes[ANode2].Prev <> NullIndex then
    FNodes[FNodes[ANode2].Prev].Next := ANode2;
end;

procedure TQ3AdaptiveHuffman.Increment(ANode: Integer);
var
  LLeader: Integer;
begin
  if ANode = NullIndex then
    Exit;

  if (FNodes[ANode].Next <> NullIndex) and (FNodes[FNodes[ANode].Next].Weight = FNodes[ANode].Weight) then
  begin
    LLeader := FSlots[FNodes[ANode].Head];
    if LLeader <> FNodes[ANode].Parent then
      Swap(LLeader, ANode);
    SwapList(LLeader, ANode);
  end;
  if (FNodes[ANode].Prev <> NullIndex) and (FNodes[FNodes[ANode].Prev].Weight = FNodes[ANode].Weight) then
    FSlots[FNodes[ANode].Head] := FNodes[ANode].Prev
  else
  begin
    FSlots[FNodes[ANode].Head] := NullIndex;
    FreeSlot(FNodes[ANode].Head);
  end;
  Inc(FNodes[ANode].Weight);
  if (FNodes[ANode].Next <> NullIndex) and (FNodes[FNodes[ANode].Next].Weight = FNodes[ANode].Weight) then
    FNodes[ANode].Head := FNodes[FNodes[ANode].Next].Head
  else
  begin
    FNodes[ANode].Head := GetSlot;
    FSlots[FNodes[ANode].Head] := ANode;
  end;
  if FNodes[ANode].Parent <> NullIndex then
  begin
    Increment(FNodes[ANode].Parent);
    if FNodes[ANode].Prev = FNodes[ANode].Parent then
    begin
      SwapList(ANode, FNodes[ANode].Parent);
      if FSlots[FNodes[ANode].Head] = ANode then
        FSlots[FNodes[ANode].Head] := FNodes[ANode].Parent;
    end;
  end;
end;

procedure TQ3AdaptiveHuffman.AddRef(ASymbol: Byte);
var
  LLeaf, LInternal, LAfterHead: Integer;
begin
  if FLoc[ASymbol] = NullIndex then
  begin
    // the first transmission of this symbol
    LLeaf := FBlocNode;
    Inc(FBlocNode);
    LInternal := FBlocNode;
    Inc(FBlocNode);

    FNodes[LInternal].Symbol := Q3_HUFFMAN_INTERNAL_NODE;
    FNodes[LInternal].Weight := 1;
    LAfterHead := FNodes[FListHead].Next;
    FNodes[LInternal].Next := LAfterHead;
    if LAfterHead <> NullIndex then
    begin
      FNodes[LAfterHead].Prev := LInternal;
      if FNodes[LAfterHead].Weight = 1 then
        FNodes[LInternal].Head := FNodes[LAfterHead].Head
      else
      begin
        FNodes[LInternal].Head := GetSlot;
        FSlots[FNodes[LInternal].Head] := LInternal;
      end;
    end
    else
    begin
      FNodes[LInternal].Head := GetSlot;
      FSlots[FNodes[LInternal].Head] := LInternal;
    end;
    FNodes[FListHead].Next := LInternal;
    FNodes[LInternal].Prev := FListHead;

    FNodes[LLeaf].Symbol := ASymbol;
    FNodes[LLeaf].Weight := 1;
    LAfterHead := FNodes[FListHead].Next;
    FNodes[LLeaf].Next := LAfterHead;
    if LAfterHead <> NullIndex then
    begin
      FNodes[LAfterHead].Prev := LLeaf;
      if FNodes[LAfterHead].Weight = 1 then
        FNodes[LLeaf].Head := FNodes[LAfterHead].Head
      else
      begin
        // this should never happen
        FNodes[LLeaf].Head := GetSlot;
        FSlots[FNodes[LLeaf].Head] := LInternal;
      end;
    end
    else
    begin
      // this should never happen
      FNodes[LLeaf].Head := GetSlot;
      FSlots[FNodes[LLeaf].Head] := LLeaf;
    end;
    FNodes[FListHead].Next := LLeaf;
    FNodes[LLeaf].Prev := FListHead;
    FNodes[LLeaf].Left := NullIndex;
    FNodes[LLeaf].Right := NullIndex;

    if FNodes[FListHead].Parent <> NullIndex then
    begin
      // the list head is guaranteed to be the NYT
      if FNodes[FNodes[FListHead].Parent].Left = FListHead then
        FNodes[FNodes[FListHead].Parent].Left := LInternal
      else
        FNodes[FNodes[FListHead].Parent].Right := LInternal;
    end
    else
      FTree := LInternal;

    FNodes[LInternal].Right := LLeaf;
    FNodes[LInternal].Left := FListHead;

    FNodes[LInternal].Parent := FNodes[FListHead].Parent;
    FNodes[FListHead].Parent := LInternal;
    FNodes[LLeaf].Parent := LInternal;

    FLoc[ASymbol] := LLeaf;

    Increment(FNodes[LInternal].Parent);
  end
  else
    Increment(FLoc[ASymbol]);
end;

procedure TQ3AdaptiveHuffman.Send(ANode, AChild: Integer; var AData: TBytes; var AOffset: Integer);
begin
  if FNodes[ANode].Parent <> NullIndex then
    Send(FNodes[ANode].Parent, ANode, AData, AOffset);
  if AChild <> NullIndex then
  begin
    if FNodes[ANode].Right = AChild then
      PutBit(1, AData, AOffset)
    else
      PutBit(0, AData, AOffset);
  end;
end;

procedure TQ3AdaptiveHuffman.Transmit(ASymbol: Integer; var AData: TBytes; var AOffset: Integer);
var
  LBit: Integer;
begin
  if FLoc[ASymbol] = NullIndex then
  begin
    // not transmitted yet: the NYT, then the symbol
    Transmit(Q3_HUFFMAN_NYT, AData, AOffset);
    for LBit := 7 downto 0 do
      PutBit((ASymbol shr LBit) and 1, AData, AOffset);
  end
  else
    Send(FLoc[ASymbol], NullIndex, AData, AOffset);
end;

procedure TQ3AdaptiveHuffman.OffsetTransmit(ASymbol: Integer; var AData: TBytes; var AOffset: Integer);
begin
  if (ASymbol < 0) or (ASymbol > Q3_HUFFMAN_MAX) or (FLoc[ASymbol] = NullIndex) then
    raise EQ3MessageException.CreateFmt(SQ3HuffmanUnknownSymbol, [ASymbol]);
  Send(FLoc[ASymbol], NullIndex, AData, AOffset);
end;

function TQ3AdaptiveHuffman.Receive(const AData: TBytes; var AOffset: Integer): Integer;
var
  LNode: Integer;
begin
  LNode := FTree;
  while (LNode <> NullIndex) and (FNodes[LNode].Symbol = Q3_HUFFMAN_INTERNAL_NODE) do
  begin
    if GetBit(AData, AOffset) <> 0 then
      LNode := FNodes[LNode].Right
    else
      LNode := FNodes[LNode].Left;
  end;
  if LNode = NullIndex then
    Result := 0
  else
    Result := FNodes[LNode].Symbol;
end;

function TQ3AdaptiveHuffman.OffsetReceive(const AData: TBytes; var AOffset: Integer): Integer;
var
  LNode, LBit: Integer;
begin
  LNode := FTree;
  LBit := AOffset;
  while (LNode <> NullIndex) and (FNodes[LNode].Symbol = Q3_HUFFMAN_INTERNAL_NODE) do
  begin
    if GetBit(AData, LBit) <> 0 then
      LNode := FNodes[LNode].Right
    else
      LNode := FNodes[LNode].Left;
  end;
  if LNode = NullIndex then
  begin
    Result := 0;
    Exit;
  end;
  Result := FNodes[LNode].Symbol;
  AOffset := LBit;
end;

end.
