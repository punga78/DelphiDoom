{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - a Huffman table ready to decode                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.HuffmanTable;

interface

uses
  DelphiDoom.Jpeg.Types;

const
  // The codes of up to 8 bits are decoded with one look at a table
  JPEG_HUFFMAN_LOOKAHEAD = 8;

type
  /// <summary>
  ///   The tables to decode one Huffman code: the code of each length that is
  ///   the largest, where its symbols start, and a table that gives the symbol
  ///   of every code of up to 8 bits in one step
  /// </summary>
  /// <remarks>
  ///   Port of jpeg_make_d_derived_tbl of libjpeg 6b (jdhuff.c). The table
  ///   keeps its own copy of the symbols
  /// </remarks>
  TJpegHuffmanTable = class
  private
    FMaxCode: array[0..17] of Integer;
    FValueOffset: array[0..16] of Integer;
    FValues: array[0..255] of Byte;
    FLookBits: array[0..(1 shl JPEG_HUFFMAN_LOOKAHEAD) - 1] of Integer;
    FLookSymbol: array[0..(1 shl JPEG_HUFFMAN_LOOKAHEAD) - 1] of Byte;
  public
    /// <summary>
    ///   Builds the table of a definition
    /// </summary>
    /// <param name="AIsDc">
    ///   A table of DC coefficients: its symbols are numbers of bits, 0 to 15
    /// </param>
    /// <exception cref="EJpegDecodeException">
    ///   The definition is not a Huffman code (more than 256 codes, more codes
    ///   of a length than there are bit strings, a symbol out of range)
    /// </exception>
    constructor Create(const ADefinition: TJpegHuffmanDefinition; AIsDc: Boolean);

    /// <summary>
    ///   Number of bits of the code that starts with the 8 bits ALook, or 0 if
    ///   the code is longer than 8 bits
    /// </summary>
    function LookBits(ALook: Integer): Integer; inline;

    /// <summary>The symbol of the code that starts with the 8 bits ALook</summary>
    function LookSymbol(ALook: Integer): Integer; inline;

    /// <summary>
    ///   The largest code of AIndex bits; -1 when there is none and a very
    ///   large number for 17 bits so that a search for a code always ends
    /// </summary>
    function MaxCode(ABits: Integer): Integer; inline;

    /// <summary>
    ///   The symbol of the code ACode of ABits bits (a code that MaxCode
    ///   accepts)
    /// </summary>
    function SymbolOf(ABits, ACode: Integer): Integer; inline;
  end;

implementation

{ TJpegHuffmanTable }

constructor TJpegHuffmanTable.Create(const ADefinition: TJpegHuffmanDefinition;
  AIsDc: Boolean);
var
  LSizes: array[0..256] of Byte;
  LCodes: array[0..256] of Cardinal;
  LCode: Cardinal;
  LPosition: Integer;
  LLength: Integer;
  LCount: Integer;
  LSize: Integer;
  LSymbols: Integer;
  LLookBits: Integer;
  LRepeat: Integer;
begin
  inherited Create;
  Move(ADefinition.Values, FValues, SizeOf(FValues));

  // The size of the code of each symbol, in order
  LPosition := 0;
  for LLength := 1 to 16 do
  begin
    LCount := ADefinition.Bits[LLength];
    if LPosition + LCount > 256 then
      EJpegDecodeException.Fail(jdeBadHuffmanTable);
    while LCount > 0 do
    begin
      LSizes[LPosition] := Byte(LLength);
      Inc(LPosition);
      Dec(LCount);
    end;
  end;
  LSizes[LPosition] := 0;
  LSymbols := LPosition;

  // The codes themselves: consecutive within a length, shifted when the
  // length grows. A code that does not fit in its length is an error
  LCode := 0;
  LSize := LSizes[0];
  LPosition := 0;
  while LSizes[LPosition] <> 0 do
  begin
    while LSizes[LPosition] = LSize do
    begin
      LCodes[LPosition] := LCode;
      Inc(LPosition);
      Inc(LCode);
    end;
    if Integer(LCode) >= (1 shl LSize) then
      EJpegDecodeException.Fail(jdeBadHuffmanTable);
    LCode := LCode shl 1;
    Inc(LSize);
  end;

  // For each length: the largest code and where its symbols start
  LPosition := 0;
  for LLength := 1 to 16 do
  begin
    if ADefinition.Bits[LLength] <> 0 then
    begin
      FValueOffset[LLength] := LPosition - Integer(LCodes[LPosition]);
      Inc(LPosition, ADefinition.Bits[LLength]);
      FMaxCode[LLength] := Integer(LCodes[LPosition - 1]);
    end
    else
      FMaxCode[LLength] := -1;
  end;
  // Makes sure that a search for a code stops
  FMaxCode[17] := $FFFFF;

  // The table for the codes of up to 8 bits
  FillChar(FLookBits, SizeOf(FLookBits), 0);
  FillChar(FLookSymbol, SizeOf(FLookSymbol), 0);
  LPosition := 0;
  for LLength := 1 to JPEG_HUFFMAN_LOOKAHEAD do
    for LCount := 1 to ADefinition.Bits[LLength] do
    begin
      LLookBits := Integer(LCodes[LPosition]) shl (JPEG_HUFFMAN_LOOKAHEAD - LLength);
      for LRepeat := (1 shl (JPEG_HUFFMAN_LOOKAHEAD - LLength)) - 1 downto 0 do
      begin
        FLookBits[LLookBits] := LLength;
        FLookSymbol[LLookBits] := ADefinition.Values[LPosition];
        Inc(LLookBits);
      end;
      Inc(LPosition);
    end;

  // The symbols of the DC table are the sizes of the differences
  if AIsDc then
    for LPosition := 0 to LSymbols - 1 do
      if ADefinition.Values[LPosition] > 15 then
        EJpegDecodeException.Fail(jdeBadHuffmanTable);
end;

function TJpegHuffmanTable.LookBits(ALook: Integer): Integer;
begin
  Result := FLookBits[ALook];
end;

function TJpegHuffmanTable.LookSymbol(ALook: Integer): Integer;
begin
  Result := FLookSymbol[ALook];
end;

function TJpegHuffmanTable.MaxCode(ABits: Integer): Integer;
begin
  Result := FMaxCode[ABits];
end;

function TJpegHuffmanTable.SymbolOf(ABits, ACode: Integer): Integer;
begin
  Result := FValues[ACode + FValueOffset[ABits]];
end;

end.
