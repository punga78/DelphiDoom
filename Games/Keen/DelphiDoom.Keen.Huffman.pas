{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - Huffman expansion                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CAL_OptimizeNodes and CAL_HuffExpand of id_ca.c                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Huffman;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   A dictionary of 255 nodes; the walk starts at node 254 and goes down for each bit, taking the
  ///   lowest bit of every byte first. A value under 256 is the byte to write, then the walk starts again.
  ///   The original is in assembler (two versions, under and over 64 KB); this is the same walk
  /// </summary>
  /// <remarks>
  ///   Difference from the C: the data that end too early raise EKeenDataException, the C goes on reading
  ///   what is after the buffer. CAL_OptimizeNodes (the values 256 and more become addresses) is not needed
  ///   here: a value stays an index, and every one is checked when the dictionary is read
  /// </remarks>
  TKeenHuffman = class(TInterfacedObject, IKeenHuffman)
  strict private
    FNodes: array[0..KEEN_HUFF_NODES - 1] of TKeenHuffNode;
    function Run(const ASource: TBytes; ASourceOffset, ADestLength: Integer; ALenient: Boolean): TBytes;
  public
    /// <param name="ADictionary">The bytes of the .KDR dictionary: 255 nodes of two little endian words (the extra bytes of the file are ignored)</param>
    constructor Create(const ADictionary: TBytes);
    function Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
    function ExpandAvailable(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.LittleEndian;

{ TKeenHuffman }

constructor TKeenHuffman.Create(const ADictionary: TBytes);
var
  LIndex: Integer;
begin
  inherited Create;
  if Length(ADictionary) < KEEN_HUFF_DICT_BYTES then
    raise EKeenDataException.CreateFmt(SKeenDictionaryTooShort,
      [Length(ADictionary), KEEN_HUFF_DICT_BYTES]);
  for LIndex := 0 to KEEN_HUFF_NODES - 1 do
  begin
    FNodes[LIndex].Bit0 := TKeenLittleEndian.ReadWord(ADictionary, LIndex * 4);
    FNodes[LIndex].Bit1 := TKeenLittleEndian.ReadWord(ADictionary, LIndex * 4 + 2);
    if FNodes[LIndex].Bit0 >= 256 + KEEN_HUFF_NODES then
      raise EKeenDataException.CreateFmt(SKeenDictionaryBadNode, [LIndex, FNodes[LIndex].Bit0]);
    if FNodes[LIndex].Bit1 >= 256 + KEEN_HUFF_NODES then
      raise EKeenDataException.CreateFmt(SKeenDictionaryBadNode, [LIndex, FNodes[LIndex].Bit1]);
  end;
end;

function TKeenHuffman.Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
begin
  Result := Run(ASource, ASourceOffset, ADestLength, False);
end;

function TKeenHuffman.ExpandAvailable(const ASource: TBytes; ASourceOffset,
  ADestLength: Integer): TBytes;
begin
  Result := Run(ASource, ASourceOffset, ADestLength, True);
end;

function TKeenHuffman.Run(const ASource: TBytes; ASourceOffset, ADestLength: Integer;
  ALenient: Boolean): TBytes;
var
  LNode: Integer;
  LCode: Integer;
  LCurrent: Byte;
  LMask: Integer;
  LPosition: Integer;
  LWritten: Integer;
begin
  if ADestLength < 0 then
    raise EKeenDataException.CreateFmt(SKeenLengthInvalid, [ADestLength]);
  SetLength(Result, ADestLength);
  if ADestLength = 0 then
    Exit;
  FillChar(Result[0], ADestLength, 0);
  if (ASourceOffset < 0) or (ASourceOffset >= Length(ASource)) then
  begin
    if ALenient and (ASourceOffset >= 0) then
      Exit;
    raise EKeenDataException.CreateFmt(SKeenHuffmanBadStart, [ASourceOffset, Length(ASource)]);
  end;

  LCurrent := ASource[ASourceOffset];
  LPosition := ASourceOffset + 1;
  LMask := 1;
  LNode := KEEN_HUFF_HEAD;
  LWritten := 0;
  while LWritten < ADestLength do
  begin
    if LMask > $80 then
    begin
      // the 8 bits of the byte are used: the C loads the next byte at once, here when it is needed
      if LPosition >= Length(ASource) then
      begin
        if ALenient then
          Exit;
        raise EKeenDataException.CreateFmt(SKeenHuffmanTruncated, [LWritten, ADestLength]);
      end;
      LCurrent := ASource[LPosition];
      Inc(LPosition);
      LMask := 1;
    end;
    if (LCurrent and LMask) <> 0 then
      LCode := FNodes[LNode].Bit1
    else
      LCode := FNodes[LNode].Bit0;
    LMask := LMask shl 1;
    if LCode < 256 then
    begin
      Result[LWritten] := Byte(LCode);
      Inc(LWritten);
      LNode := KEEN_HUFF_HEAD;
    end
    else
      LNode := LCode - 256;
  end;
end;

end.
