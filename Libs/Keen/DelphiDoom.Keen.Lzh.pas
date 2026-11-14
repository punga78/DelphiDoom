{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - LZH expansion (LZSS with adaptive Huffman)        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  lzhDecompress, StartHuff, reconst, update, GetBit, GetByte, DecodeChar and   }
{  DecodePosition of lzhuf.c (LZHUF of Haruyasu Yoshizaki and Haruhiko          }
{  Okumura, as Softdisk changed it: a look-ahead of 30 bytes)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Lzh;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

type
  /// <summary>
  ///   Expands the LZH data of the SoftLib libraries (KDREAMS.CMP). A code under 256 is a byte; a higher one is a
  ///   copy of 3 to 30 bytes from the last 4096 written, at a distance whose upper 6 bits come from a table
  ///   and the lower 6 from the stream. The codes are Huffman codes of a tree that changes with each code. The
  ///   state is in the object: a call starts the tree of the codes again, but the window of 4096 bytes keeps what an
  ///   earlier call left in it, as the static buffer of the C does. The 16 bit numbers of the C
  ///   (the bit buffer, the frequencies) are kept at 16 bits
  /// </summary>
  TKeenLzh = class
  strict private
    const
      N = 4096;
      F = 30;
      THRESHOLD = 2;
      N_CHAR = 256 - THRESHOLD + F;
      T = N_CHAR * 2 - 1;
      R = T - 1;
      MAX_FREQ = $8000;
    var
      FFreq: array[0..T] of Word;
      FParent: array[0..T + N_CHAR - 1] of Integer;
      FSon: array[0..T - 1] of Integer;
      FTextBuffer: array[0..N + F - 2] of Byte;
      FSource: TBytes;
      FPosition: Integer;
      FLeft: Cardinal;
      FGetBuf: Word;
      FGetLen: Integer;
      // the compressor: the tree of the strings of the window, the match found, the bits not written yet
      FLeftSon: array[0..N] of Integer;
      FRightSon: array[0..N + 256] of Integer;
      FDad: array[0..N] of Integer;
      FMatchPosition: Integer;
      FMatchLength: Integer;
      FPutBuf: Word;
      FPutLen: Integer;
      FOutput: TBytes;
      FOutputLength: Integer;
    procedure StartHuff;
    procedure Reconst;
    procedure Update(ACode: Integer);
    procedure Fill;
    function GetBit: Integer;
    function GetByte: Integer;
    function DecodeChar: Integer;
    function DecodePosition: Integer;
    class function PositionCode(AByte: Integer): Integer; static;
    class function PositionLength(AByte: Integer): Integer; static;
    procedure DeleteNode(AIndex: Integer);
    procedure InsertNode(AIndex: Integer);
    procedure InitTree;
    procedure PutCode(ALength: Integer; ACode: Word);
    procedure EncodeChar(ACode: Integer);
    procedure EncodePosition(APosition: Integer);
    procedure EncodeEnd;
    procedure Emit(AValue: Byte);
  public
    /// <summary>
    ///   lzhDecompress: AOriginalLength bytes from the ACompressedLength bytes at AOffset of ASource. As in the C,
    ///   data that end early are read as zeros (the last code often needs bits that are not there); data outside
    ///   the buffer are an EKeenDataException
    /// </summary>
    function Decompress(const ASource: TBytes; AOffset, ACompressedLength, AOriginalLength: Integer): TBytes;
    /// <summary>
    ///   lzhCompress (the compressor of lzhuf.c, that the game does not use: SoftLib made the library with it). The
    ///   dictionary of 4096 bytes is a static of the C and keeps what a call left in it, and so it does here: a
    ///   short buffer after a long one can see bytes of the long one past its end, and the stream depends on them.
    ///   Compress the same buffers in the same order on a new object to get the same streams as the C
    ///   (the golden of the harness does)
    /// </summary>
    function Compress(const ASource: TBytes): TBytes;
  end;

implementation

const
  // p_len and p_code of the C: how many bits and which bits the upper 6 bits of a distance have when they are written
  P_LEN: array[0..63] of Byte = (
    3, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8);
  P_CODE: array[0..63] of Byte = (
    $00, $20, $30, $40, $50, $58, $60, $68, $70, $78, $80, $88, $90, $94, $98, $9C,
    $A0, $A4, $A8, $AC, $B0, $B4, $B8, $BC, $C0, $C2, $C4, $C6, $C8, $CA, $CC, $CE,
    $D0, $D2, $D4, $D6, $D8, $DA, $DC, $DE, $E0, $E2, $E4, $E6, $E8, $EA, $EC, $EE,
    $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF);

{ TKeenLzh }

class function TKeenLzh.PositionCode(AByte: Integer): Integer;
begin
  // d_code: the upper 6 bits of the distance for the first byte of its code (0 for 32 bytes, 1..3 for 16 each,
  // 4..11 for 8 each, 12..23 for 4 each, 24..47 for 2 each, 48..63 for one each)
  if AByte < 32 then
    Result := 0
  else if AByte < 80 then
    Result := 1 + (AByte - 32) div 16
  else if AByte < 144 then
    Result := 4 + (AByte - 80) div 8
  else if AByte < 192 then
    Result := 12 + (AByte - 144) div 4
  else if AByte < 240 then
    Result := 24 + (AByte - 192) div 2
  else
    Result := 48 + (AByte - 240);
end;

class function TKeenLzh.PositionLength(AByte: Integer): Integer;
begin
  // d_len: how many bits the code of the upper 6 bits has
  if AByte < 32 then
    Result := 3
  else if AByte < 80 then
    Result := 4
  else if AByte < 144 then
    Result := 5
  else if AByte < 192 then
    Result := 6
  else if AByte < 240 then
    Result := 7
  else
    Result := 8;
end;

procedure TKeenLzh.StartHuff;
var
  LIndex: Integer;
  LNode: Integer;
begin
  for LIndex := 0 to N_CHAR - 1 do
  begin
    FFreq[LIndex] := 1;
    FSon[LIndex] := LIndex + T;
    FParent[LIndex + T] := LIndex;
  end;
  LIndex := 0;
  LNode := N_CHAR;
  while LNode <= R do
  begin
    FFreq[LNode] := Word(FFreq[LIndex] + FFreq[LIndex + 1]);
    FSon[LNode] := LIndex;
    FParent[LIndex] := LNode;
    FParent[LIndex + 1] := LNode;
    Inc(LIndex, 2);
    Inc(LNode);
  end;
  FFreq[T] := $FFFF;
  FParent[R] := 0;
end;

procedure TKeenLzh.Reconst;
var
  LIndex: Integer;
  LLeaf: Integer;
  LNode: Integer;
  LPlace: Integer;
  LMove: Integer;
  LFrequency: Word;
begin
  // halve the frequencies of the leaves and put them first
  LLeaf := 0;
  for LIndex := 0 to T - 1 do
    if FSon[LIndex] >= T then
    begin
      FFreq[LLeaf] := Word((FFreq[LIndex] + 1) div 2);
      FSon[LLeaf] := FSon[LIndex];
      Inc(LLeaf);
    end;
  // make the tree: connect the children, keeping the nodes in the order of their frequency
  LIndex := 0;
  LNode := N_CHAR;
  while LNode < T do
  begin
    LFrequency := Word(FFreq[LIndex] + FFreq[LIndex + 1]);
    FFreq[LNode] := LFrequency;
    LPlace := LNode - 1;
    while LFrequency < FFreq[LPlace] do
      Dec(LPlace);
    Inc(LPlace);
    // memmove of the nodes from LPlace up by one
    for LMove := LNode downto LPlace + 1 do
    begin
      FFreq[LMove] := FFreq[LMove - 1];
      FSon[LMove] := FSon[LMove - 1];
    end;
    FFreq[LPlace] := LFrequency;
    FSon[LPlace] := LIndex;
    Inc(LIndex, 2);
    Inc(LNode);
  end;
  // connect the parents
  for LIndex := 0 to T - 1 do
  begin
    LPlace := FSon[LIndex];
    if LPlace >= T then
      FParent[LPlace] := LIndex
    else
    begin
      FParent[LPlace] := LIndex;
      FParent[LPlace + 1] := LIndex;
    end;
  end;
end;

procedure TKeenLzh.Update(ACode: Integer);
var
  LNode: Integer;
  LOther: Integer;
  LCount: Word;
  LChild: Integer;
  LOtherChild: Integer;
begin
  if FFreq[R] = MAX_FREQ then
    Reconst;
  LNode := FParent[ACode + T];
  repeat
    Inc(FFreq[LNode]);
    LCount := FFreq[LNode];
    // swap the nodes to keep the tree in the order of the frequencies
    LOther := LNode + 1;
    if LCount > FFreq[LOther] then
    begin
      repeat
        Inc(LOther);
      until not (LCount > FFreq[LOther]);
      Dec(LOther);
      FFreq[LNode] := FFreq[LOther];
      FFreq[LOther] := LCount;
      LChild := FSon[LNode];
      FParent[LChild] := LOther;
      if LChild < T then
        FParent[LChild + 1] := LOther;
      LOtherChild := FSon[LOther];
      FSon[LOther] := LChild;
      FParent[LOtherChild] := LNode;
      if LOtherChild < T then
        FParent[LOtherChild + 1] := LNode;
      FSon[LNode] := LOtherChild;
      LNode := LOther;
    end;
    LNode := FParent[LNode];
  until LNode = 0; // until the root
end;

procedure TKeenLzh.Fill;
var
  LByte: Integer;
begin
  while FGetLen <= 8 do
  begin
    if FLeft > 0 then
    begin
      LByte := FSource[FPosition];
      Inc(FPosition);
      Dec(FLeft);
    end
    else
      LByte := 0;
    FGetBuf := FGetBuf or Word(LByte shl (8 - FGetLen));
    Inc(FGetLen, 8);
  end;
end;

function TKeenLzh.GetBit: Integer;
begin
  Fill;
  // the top bit of the 16
  Result := (FGetBuf shr 15) and 1;
  FGetBuf := Word(FGetBuf shl 1);
  Dec(FGetLen);
end;

function TKeenLzh.GetByte: Integer;
begin
  Fill;
  Result := FGetBuf shr 8;
  FGetBuf := Word(FGetBuf shl 8);
  Dec(FGetLen, 8);
end;

function TKeenLzh.DecodeChar: Integer;
var
  LNode: Integer;
begin
  // from the root to a leaf: the node son[] for a 0 bit, son[] + 1 for a 1 bit
  LNode := FSon[R];
  while LNode < T do
  begin
    Inc(LNode, GetBit);
    LNode := FSon[LNode];
  end;
  Dec(LNode, T);
  Update(LNode);
  Result := LNode;
end;

function TKeenLzh.DecodePosition: Integer;
var
  LByte: Integer;
  LCode: Integer;
  LBits: Integer;
begin
  // the upper 6 bits from the table, the lower 6 bits as they are
  LByte := GetByte;
  LCode := PositionCode(LByte) shl 6;
  LBits := PositionLength(LByte) - 2;
  while LBits > 0 do
  begin
    LByte := ((LByte shl 1) + GetBit) and $FFFF;
    Dec(LBits);
  end;
  Result := LCode or (LByte and $3F);
end;

procedure TKeenLzh.Emit(AValue: Byte);
begin
  if FOutputLength >= Length(FOutput) then
    SetLength(FOutput, (FOutputLength + 256) * 2);
  FOutput[FOutputLength] := AValue;
  Inc(FOutputLength);
end;

procedure TKeenLzh.DeleteNode(AIndex: Integer);
var
  LNode: Integer;
begin
  // DeleteNode: a node that is not in the tree is left alone
  if FDad[AIndex] = N then
    Exit;
  if FRightSon[AIndex] = N then
    LNode := FLeftSon[AIndex]
  else if FLeftSon[AIndex] = N then
    LNode := FRightSon[AIndex]
  else
  begin
    LNode := FLeftSon[AIndex];
    if FRightSon[LNode] <> N then
    begin
      repeat
        LNode := FRightSon[LNode];
      until FRightSon[LNode] = N;
      FRightSon[FDad[LNode]] := FLeftSon[LNode];
      FDad[FLeftSon[LNode]] := FDad[LNode];
      FLeftSon[LNode] := FLeftSon[AIndex];
      FDad[FLeftSon[AIndex]] := LNode;
    end;
    FRightSon[LNode] := FRightSon[AIndex];
    FDad[FRightSon[AIndex]] := LNode;
  end;
  FDad[LNode] := FDad[AIndex];
  if FRightSon[FDad[AIndex]] = AIndex then
    FRightSon[FDad[AIndex]] := LNode
  else
    FLeftSon[FDad[AIndex]] := LNode;
  FDad[AIndex] := N;
end;

procedure TKeenLzh.InsertNode(AIndex: Integer);
var
  LIndex: Integer;
  LNode: Integer;
  LCompare: Integer;
  LDistance: Integer;
begin
  LCompare := 1;
  LNode := N + 1 + FTextBuffer[AIndex];
  FRightSon[AIndex] := N;
  FLeftSon[AIndex] := N;
  FMatchLength := 0;
  while True do
  begin
    if LCompare >= 0 then
    begin
      if FRightSon[LNode] <> N then
        LNode := FRightSon[LNode]
      else
      begin
        FRightSon[LNode] := AIndex;
        FDad[AIndex] := LNode;
        Exit;
      end;
    end
    else
    begin
      if FLeftSon[LNode] <> N then
        LNode := FLeftSon[LNode]
      else
      begin
        FLeftSon[LNode] := AIndex;
        FDad[AIndex] := LNode;
        Exit;
      end;
    end;
    LIndex := 1;
    while LIndex < F do
    begin
      LCompare := Integer(FTextBuffer[AIndex + LIndex]) - Integer(FTextBuffer[LNode + LIndex]);
      if LCompare <> 0 then
        Break;
      Inc(LIndex);
    end;
    if LIndex > THRESHOLD then
    begin
      if LIndex > FMatchLength then
      begin
        FMatchPosition := ((AIndex - LNode) and (N - 1)) - 1;
        FMatchLength := LIndex;
        if FMatchLength >= F then
          Break;
      end;
      if LIndex = FMatchLength then
      begin
        LDistance := ((AIndex - LNode) and (N - 1)) - 1;
        if LDistance < FMatchPosition then
          FMatchPosition := LDistance;
      end;
    end;
  end;
  FDad[AIndex] := FDad[LNode];
  FLeftSon[AIndex] := FLeftSon[LNode];
  FRightSon[AIndex] := FRightSon[LNode];
  FDad[FLeftSon[LNode]] := AIndex;
  FDad[FRightSon[LNode]] := AIndex;
  if FRightSon[FDad[LNode]] = LNode then
    FRightSon[FDad[LNode]] := AIndex
  else
    FLeftSon[FDad[LNode]] := AIndex;
  FDad[LNode] := N;
end;

procedure TKeenLzh.InitTree;
var
  LIndex: Integer;
begin
  for LIndex := N + 1 to N + 256 do
    FRightSon[LIndex] := N;
  for LIndex := 0 to N - 1 do
    FDad[LIndex] := N;
end;

procedure TKeenLzh.PutCode(ALength: Integer; ACode: Word);
begin
  FPutBuf := Word(FPutBuf or (ACode shr FPutLen));
  Inc(FPutLen, ALength);
  if FPutLen >= 8 then
  begin
    Emit(Byte(FPutBuf shr 8));
    Dec(FPutLen, 8);
    if FPutLen >= 8 then
    begin
      Emit(Byte(FPutBuf));
      Dec(FPutLen, 8);
      FPutBuf := Word(ACode shl (ALength - FPutLen));
    end
    else
      FPutBuf := Word(FPutBuf shl 8);
  end;
end;

procedure TKeenLzh.EncodeChar(ACode: Integer);
var
  LBits: Word;
  LCount: Integer;
  LNode: Integer;
begin
  LBits := 0;
  LCount := 0;
  LNode := FParent[ACode + T];
  // from the leaf to the root: the bit of each step is 1 when the address of the node is odd
  repeat
    LBits := Word(LBits shr 1);
    if (LNode and 1) <> 0 then
      LBits := Word(LBits + $8000);
    Inc(LCount);
    LNode := FParent[LNode];
  until LNode = R;
  PutCode(LCount, LBits);
  Update(ACode);
end;

procedure TKeenLzh.EncodePosition(APosition: Integer);
var
  LUpper: Integer;
begin
  // the upper 6 bits with their code, the lower 6 as they are
  LUpper := APosition shr 6;
  PutCode(P_LEN[LUpper], Word(P_CODE[LUpper] shl 8));
  PutCode(6, Word((APosition and $3F) shl 10));
end;

procedure TKeenLzh.EncodeEnd;
begin
  if FPutLen <> 0 then
    Emit(Byte(FPutBuf shr 8));
end;

function TKeenLzh.Compress(const ASource: TBytes): TBytes;
var
  LIndex: Integer;
  LLength: Integer;
  LRing: Integer;
  LSlot: Integer;
  LLastMatchLength: Integer;
  LRead: Integer;
  LByte: Byte;

  function NextByte: Byte;
  begin
    Result := ASource[LRead];
    Inc(LRead);
  end;

begin
  FOutputLength := 0;
  FOutput := nil;
  if Length(ASource) = 0 then
    Exit(nil);
  FPutBuf := 0;
  FPutLen := 0;
  LRead := 0;
  StartHuff;
  InitTree;
  LSlot := 0;
  LRing := N - F;
  for LIndex := LSlot to LRing - 1 do
    FTextBuffer[LIndex] := Ord(' ');
  LLength := 0;
  while (LLength < F) and (LRead < Length(ASource)) do
  begin
    FTextBuffer[LRing + LLength] := NextByte;
    Inc(LLength);
  end;
  for LIndex := 1 to F do
    InsertNode(LRing - LIndex);
  InsertNode(LRing);
  repeat
    if FMatchLength > LLength then
      FMatchLength := LLength;
    if FMatchLength <= THRESHOLD then
    begin
      FMatchLength := 1;
      EncodeChar(FTextBuffer[LRing]);
    end
    else
    begin
      EncodeChar(255 - THRESHOLD + FMatchLength);
      EncodePosition(FMatchPosition);
    end;
    LLastMatchLength := FMatchLength;
    LIndex := 0;
    while (LIndex < LLastMatchLength) and (LRead < Length(ASource)) do
    begin
      LByte := NextByte;
      DeleteNode(LSlot);
      FTextBuffer[LSlot] := LByte;
      if LSlot < F - 1 then
        FTextBuffer[LSlot + N] := LByte;
      LSlot := (LSlot + 1) and (N - 1);
      LRing := (LRing + 1) and (N - 1);
      InsertNode(LRing);
      Inc(LIndex);
    end;
    while LIndex < LLastMatchLength do
    begin
      Inc(LIndex);
      DeleteNode(LSlot);
      LSlot := (LSlot + 1) and (N - 1);
      LRing := (LRing + 1) and (N - 1);
      Dec(LLength);
      if LLength <> 0 then
        InsertNode(LRing);
    end;
  until LLength <= 0;
  EncodeEnd;
  SetLength(FOutput, FOutputLength);
  Result := FOutput;
  FOutput := nil;
end;

function TKeenLzh.Decompress(const ASource: TBytes; AOffset, ACompressedLength, AOriginalLength: Integer): TBytes;
var
  LIndex: Integer;
  LRing: Integer;
  LCount: Integer;
  LCode: Integer;
  LFrom: Integer;
  LLength: Integer;
  LByte: Byte;
begin
  if AOriginalLength < 0 then
    raise EKeenDataException.CreateFmt(SKeenLengthInvalid, [AOriginalLength]);
  if (AOffset < 0) or (ACompressedLength < 0) or (Int64(AOffset) + ACompressedLength > Length(ASource)) then
    raise EKeenDataException.CreateFmt(SKeenReadPastEnd, [ACompressedLength, AOffset, Length(ASource)]);
  SetLength(Result, AOriginalLength);
  if AOriginalLength = 0 then
    Exit;
  FSource := ASource;
  FPosition := AOffset;
  FLeft := Cardinal(ACompressedLength);
  FGetBuf := 0;
  FGetLen := 0;
  StartHuff;
  // the buffer of the C is static: what an earlier call left in it stays (zeros in a new object); the spaces are
  // written in the part that a copy can reach first
  for LIndex := 0 to N - F - 1 do
    FTextBuffer[LIndex] := Ord(' ');
  LRing := N - F;
  LCount := 0;
  while LCount < AOriginalLength do
  begin
    LCode := DecodeChar;
    if LCode < 256 then
    begin
      Result[LCount] := Byte(LCode);
      Inc(LCount);
      FTextBuffer[LRing] := Byte(LCode);
      LRing := (LRing + 1) and (N - 1);
    end
    else
    begin
      LFrom := (LRing - DecodePosition - 1) and (N - 1);
      LLength := LCode - 255 + THRESHOLD;
      for LIndex := 0 to LLength - 1 do
      begin
        LByte := FTextBuffer[(LFrom + LIndex) and (N - 1)];
        // the C writes the whole copy, also past the length that was asked: here the output ends at its length
        if LCount < AOriginalLength then
          Result[LCount] := LByte;
        Inc(LCount);
        FTextBuffer[LRing] := LByte;
        LRing := (LRing + 1) and (N - 1);
      end;
    end;
  end;
  FSource := nil;
end;

end.
