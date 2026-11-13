{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorHuffman                        }
{  (idCompressor_Huffman)                                                      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): framework\Compressor.cpp }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Compression.Huffman;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Compression.Types, DelphiDoom.Compression.None;

const
  HUFFMAN_HMAX = 256;
  /// <summary>NYT: Not Yet Transmitted</summary>
  HUFFMAN_NYT = HUFFMAN_HMAX;
  HUFFMAN_INTERNAL_NODE = HUFFMAN_HMAX + 1;
  HUFFMAN_NODE_COUNT = 768;

type
  /// <summary>
  ///   idCompressor_Huffman: adaptive Huffman coding (after Sayood's Data Compression book): the tree is
  ///   not stored, both sides build it symbol by symbol, and a new symbol is sent as the NYT code and eight
  ///   bits. The word length is ignored (symbols are bytes). The pointers of the original's tree and
  ///   lists are indexes into node arrays (-1 is NULL) and the "pointer to node pointer" of the block
  ///   heads is an index into the <c>FNodePtrs</c> array, whose free slots form a list through their values.
  ///   <para>As in the original the decompressor stops when it has used all the bytes it read from the
  ///   stream, so ask for exactly the number of bytes that were compressed.</para>
  /// </summary>
  TCompressorHuffman = class(TCompressorNone)
  strict private
    FSeq: TBytes;
    FBloc: Integer;
    FBlocMax: Integer;
    FBlocIn: Integer;
    FBlocNode: Integer;
    FBlocPtrs: Integer;
    FCompressedSize: Integer;
    FUnCompressedSize: Integer;
    FTree: Integer;
    FLHead: Integer;
    FLTail: Integer;
    FLoc: array[0..HUFFMAN_HMAX] of Integer;
    FFreeList: Integer;
    FLeft, FRight, FParent, FNext, FPrev, FHead, FWeight, FSymbol: array[0..HUFFMAN_NODE_COUNT - 1] of Integer;
    FNodePtrs: array[0..HUFFMAN_NODE_COUNT - 1] of Integer;
    procedure ResetNode(AIndex: Integer);
    procedure AddBit(ABit: Integer; AOut: PByte);
    function GetBit: Integer;
    function GetNodePtr: Integer;
    procedure FreeNodePtr(ASlot: Integer);
    procedure Swap(ANode1, ANode2: Integer);
    procedure SwapList(ANode1, ANode2: Integer);
    procedure Increment(ANode: Integer);
    procedure AddRef(ACh: Byte);
    function Receive(ANode: Integer; var ACh: Integer): Integer;
    procedure Send(ANode, AChild: Integer; AOut: PByte);
    procedure Transmit(ACh: Integer; AOut: PByte);
  public
    constructor Create;
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
    procedure FinishCompress; override;
    function GetCompressionRatio: Single; override;
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{$POINTERMATH ON}

{ TCompressorHuffman }

constructor TCompressorHuffman.Create;
begin
  inherited Create;
  SetLength(FSeq, COMPRESSOR_BUFFER_SIZE);
  FillChar(FSeq[0], COMPRESSOR_BUFFER_SIZE, 0);
end;

procedure TCompressorHuffman.ResetNode(AIndex: Integer);
begin
  FLeft[AIndex] := -1;
  FRight[AIndex] := -1;
  FParent[AIndex] := -1;
  FNext[AIndex] := -1;
  FPrev[AIndex] := -1;
  FHead[AIndex] := -1;
  FWeight[AIndex] := 0;
  FSymbol[AIndex] := 0;
end;

procedure TCompressorHuffman.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
var
  LIndex: Integer;
begin
  inherited Init(AStream, ACompress, AWordLength);
  FBloc := 0;
  FBlocMax := 0;
  FBlocIn := 0;
  FBlocNode := 0;
  FBlocPtrs := 0;
  FCompressedSize := 0;
  FUnCompressedSize := 0;
  FTree := -1;
  FLHead := -1;
  FLTail := -1;
  for LIndex := 0 to HUFFMAN_HMAX do
    FLoc[LIndex] := -1;
  FFreeList := -1;
  for LIndex := 0 to HUFFMAN_NODE_COUNT - 1 do
  begin
    ResetNode(LIndex);
    FNodePtrs[LIndex] := -1;
  end;
  // the NYT (not yet transmitted) node is the whole tree and the head of the list
  FTree := FBlocNode;
  Inc(FBlocNode);
  FLHead := FTree;
  FLoc[HUFFMAN_NYT] := FTree;
  if not ACompress then
    FLTail := FTree;
  FSymbol[FTree] := HUFFMAN_NYT;
  FWeight[FTree] := 0;
  FNext[FLHead] := -1;
  FPrev[FLHead] := -1;
  FParent[FTree] := -1;
  FLeft[FTree] := -1;
  FRight[FTree] := -1;
end;

procedure TCompressorHuffman.AddBit(ABit: Integer; AOut: PByte);
begin
  if (FBloc and 7) = 0 then
    AOut[FBloc shr 3] := 0;
  AOut[FBloc shr 3] := AOut[FBloc shr 3] or Byte(ABit shl (FBloc and 7));
  Inc(FBloc);
end;

function TCompressorHuffman.GetBit: Integer;
var
  LByteIndex, LBlock: Integer;
begin
  LByteIndex := FBloc shr 3;
  LBlock := LByteIndex shr 16;
  if LBlock <> FBlocIn then
  begin
    Inc(FBlocMax, FStream.Read(FSeq[0], COMPRESSOR_BUFFER_SIZE));
    Inc(FBlocIn);
  end;
  LByteIndex := LByteIndex and $FFFF;
  Result := (FSeq[LByteIndex] shr (FBloc and 7)) and 1;
  Inc(FBloc);
end;

function TCompressorHuffman.GetNodePtr: Integer;
begin
  if FFreeList < 0 then
  begin
    Result := FBlocPtrs;
    Inc(FBlocPtrs);
  end
  else
  begin
    Result := FFreeList;
    FFreeList := FNodePtrs[Result];
  end;
end;

procedure TCompressorHuffman.FreeNodePtr(ASlot: Integer);
begin
  FNodePtrs[ASlot] := FFreeList;
  FFreeList := ASlot;
end;

procedure TCompressorHuffman.Swap(ANode1, ANode2: Integer);
var
  LParent1, LParent2: Integer;
begin
  LParent1 := FParent[ANode1];
  LParent2 := FParent[ANode2];
  if LParent1 >= 0 then
  begin
    if FLeft[LParent1] = ANode1 then
      FLeft[LParent1] := ANode2
    else
      FRight[LParent1] := ANode2;
  end
  else
    FTree := ANode2;
  if LParent2 >= 0 then
  begin
    if FLeft[LParent2] = ANode2 then
      FLeft[LParent2] := ANode1
    else
      FRight[LParent2] := ANode1;
  end
  else
    FTree := ANode1;
  FParent[ANode1] := LParent2;
  FParent[ANode2] := LParent1;
end;

procedure TCompressorHuffman.SwapList(ANode1, ANode2: Integer);
var
  LTemp: Integer;
begin
  LTemp := FNext[ANode1];
  FNext[ANode1] := FNext[ANode2];
  FNext[ANode2] := LTemp;
  LTemp := FPrev[ANode1];
  FPrev[ANode1] := FPrev[ANode2];
  FPrev[ANode2] := LTemp;
  if FNext[ANode1] = ANode1 then
    FNext[ANode1] := ANode2;
  if FNext[ANode2] = ANode2 then
    FNext[ANode2] := ANode1;
  if FNext[ANode1] >= 0 then
    FPrev[FNext[ANode1]] := ANode1;
  if FNext[ANode2] >= 0 then
    FPrev[FNext[ANode2]] := ANode2;
  if FPrev[ANode1] >= 0 then
    FNext[FPrev[ANode1]] := ANode1;
  if FPrev[ANode2] >= 0 then
    FNext[FPrev[ANode2]] := ANode2;
end;

procedure TCompressorHuffman.Increment(ANode: Integer);
var
  LNode: Integer;
begin
  if ANode < 0 then
    Exit;
  if (FNext[ANode] >= 0) and (FWeight[FNext[ANode]] = FWeight[ANode]) then
  begin
    LNode := FNodePtrs[FHead[ANode]];
    if LNode <> FParent[ANode] then
      Swap(LNode, ANode);
    SwapList(LNode, ANode);
  end;
  if (FPrev[ANode] >= 0) and (FWeight[FPrev[ANode]] = FWeight[ANode]) then
    FNodePtrs[FHead[ANode]] := FPrev[ANode]
  else
  begin
    FNodePtrs[FHead[ANode]] := -1;
    FreeNodePtr(FHead[ANode]);
  end;
  Inc(FWeight[ANode]);
  if (FNext[ANode] >= 0) and (FWeight[FNext[ANode]] = FWeight[ANode]) then
    FHead[ANode] := FHead[FNext[ANode]]
  else
  begin
    FHead[ANode] := GetNodePtr;
    FNodePtrs[FHead[ANode]] := ANode;
  end;
  if FParent[ANode] >= 0 then
  begin
    Increment(FParent[ANode]);
    if FPrev[ANode] = FParent[ANode] then
    begin
      SwapList(ANode, FParent[ANode]);
      if FNodePtrs[FHead[ANode]] = ANode then
        FNodePtrs[FHead[ANode]] := FParent[ANode];
    end;
  end;
end;

procedure TCompressorHuffman.AddRef(ACh: Byte);
var
  LNode, LNode2: Integer;
begin
  if FLoc[ACh] < 0 then
  begin
    // the first transmission of this symbol
    LNode := FBlocNode;
    Inc(FBlocNode);
    LNode2 := FBlocNode;
    Inc(FBlocNode);
    FSymbol[LNode2] := HUFFMAN_INTERNAL_NODE;
    FWeight[LNode2] := 1;
    FNext[LNode2] := FNext[FLHead];
    if FNext[FLHead] >= 0 then
    begin
      FPrev[FNext[FLHead]] := LNode2;
      if FWeight[FNext[FLHead]] = 1 then
        FHead[LNode2] := FHead[FNext[FLHead]]
      else
      begin
        FHead[LNode2] := GetNodePtr;
        FNodePtrs[FHead[LNode2]] := LNode2;
      end;
    end
    else
    begin
      FHead[LNode2] := GetNodePtr;
      FNodePtrs[FHead[LNode2]] := LNode2;
    end;
    FNext[FLHead] := LNode2;
    FPrev[LNode2] := FLHead;
    FSymbol[LNode] := ACh;
    FWeight[LNode] := 1;
    FNext[LNode] := FNext[FLHead];
    if FNext[FLHead] >= 0 then
    begin
      FPrev[FNext[FLHead]] := LNode;
      if FWeight[FNext[FLHead]] = 1 then
        FHead[LNode] := FHead[FNext[FLHead]]
      else
      begin
        // this should never happen (the original stores LNode2 here)
        FHead[LNode] := GetNodePtr;
        FNodePtrs[FHead[LNode]] := LNode2;
      end;
    end
    else
    begin
      // this should never happen
      FHead[LNode] := GetNodePtr;
      FNodePtrs[FHead[LNode]] := LNode;
    end;
    FNext[FLHead] := LNode;
    FPrev[LNode] := FLHead;
    FLeft[LNode] := -1;
    FRight[LNode] := -1;
    if FParent[FLHead] >= 0 then
    begin
      // FLHead is guaranteed to be the NYT
      if FLeft[FParent[FLHead]] = FLHead then
        FLeft[FParent[FLHead]] := LNode2
      else
        FRight[FParent[FLHead]] := LNode2;
    end
    else
      FTree := LNode2;
    FRight[LNode2] := LNode;
    FLeft[LNode2] := FLHead;
    FParent[LNode2] := FParent[FLHead];
    FParent[FLHead] := LNode2;
    FParent[LNode] := LNode2;
    FLoc[ACh] := LNode;
    Increment(FParent[LNode2]);
  end
  else
    Increment(FLoc[ACh]);
end;

function TCompressorHuffman.Receive(ANode: Integer; var ACh: Integer): Integer;
begin
  while (ANode >= 0) and (FSymbol[ANode] = HUFFMAN_INTERNAL_NODE) do
  begin
    if GetBit <> 0 then
      ANode := FRight[ANode]
    else
      ANode := FLeft[ANode];
  end;
  if ANode < 0 then
    Exit(0);
  ACh := FSymbol[ANode];
  Result := ACh;
end;

procedure TCompressorHuffman.Send(ANode, AChild: Integer; AOut: PByte);
begin
  if FParent[ANode] >= 0 then
    Send(FParent[ANode], ANode, AOut);
  if AChild >= 0 then
  begin
    if FRight[ANode] = AChild then
      AddBit(1, AOut)
    else
      AddBit(0, AOut);
  end;
end;

procedure TCompressorHuffman.Transmit(ACh: Integer; AOut: PByte);
var
  LIndex: Integer;
begin
  if FLoc[ACh] < 0 then
  begin
    // the symbol was not transmitted yet: send the NYT, then the symbol
    Transmit(HUFFMAN_NYT, AOut);
    for LIndex := 7 downto 0 do
      AddBit((ACh shr LIndex) and 1, AOut);
  end
  else
    Send(FLoc[ACh], -1, AOut);
end;

function TCompressorHuffman.Write(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LCh, LBytes: Integer;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  for LIndex := 0 to ALength - 1 do
  begin
    LCh := AData[LIndex];
    Transmit(LCh, PByte(FSeq));
    AddRef(Byte(LCh));
    LBytes := FBloc shr 3;
    if LBytes > 32768 then
    begin
      FStream.Write(FSeq[0], LBytes);
      FSeq[0] := FSeq[LBytes];
      FBloc := FBloc and 7;
      Inc(FCompressedSize, LBytes);
    end;
  end;
  Inc(FUnCompressedSize, ALength);
  Result := ALength;
end;

procedure TCompressorHuffman.FinishCompress;
var
  LBytes: Integer;
begin
  if not FCompress then
    Exit;
  Inc(FBloc, 7);
  LBytes := FBloc shr 3;
  if LBytes <> 0 then
  begin
    FStream.Write(FSeq[0], LBytes);
    Inc(FCompressedSize, LBytes);
  end;
end;

function TCompressorHuffman.Read(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LJ, LCh: Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  if FBloc = 0 then
  begin
    FBlocMax := FStream.Read(FSeq[0], COMPRESSOR_BUFFER_SIZE);
    FBlocIn := 0;
  end;
  LIndex := 0;
  while LIndex < ALength do
  begin
    LCh := 0;
    // don't overflow reading from the file
    if (FBloc shr 3) > FBlocMax then
      Break;
    Receive(FTree, LCh);
    if LCh = HUFFMAN_NYT then
    begin
      // a NYT: the symbol follows in eight bits
      LCh := 0;
      for LJ := 0 to 7 do
        LCh := (LCh shl 1) + GetBit;
    end;
    AData[LIndex] := Byte(LCh);
    AddRef(Byte(LCh));
    Inc(LIndex);
  end;
  FCompressedSize := FBloc shr 3;
  Inc(FUnCompressedSize, LIndex);
  Result := LIndex;
end;

function TCompressorHuffman.GetCompressionRatio: Single;
begin
  Result := Percent(FUnCompressedSize - FCompressedSize, FUnCompressedSize);
end;

end.
