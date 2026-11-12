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
  ///   state is in the object: a call starts from zero, two calls share nothing. The 16 bit numbers of the C
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
  public
    /// <summary>
    ///   lzhDecompress: AOriginalLength bytes from the ACompressedLength bytes at AOffset of ASource. As in the C,
    ///   data that end early are read as zeros (the last code often needs bits that are not there); data outside
    ///   the buffer are an EKeenDataException
    /// </summary>
    function Decompress(const ASource: TBytes; AOffset, ACompressedLength, AOriginalLength: Integer): TBytes;
  end;

implementation

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
  // the buffer of the C is static: zeros at the first call, then spaces in the part that a copy can reach first
  FillChar(FTextBuffer, SizeOf(FTextBuffer), 0);
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
