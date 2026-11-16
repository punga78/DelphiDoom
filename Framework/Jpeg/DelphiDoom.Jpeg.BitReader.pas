{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - reads the bits of the entropy coded data                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.BitReader;

interface

uses
  DelphiDoom.Jpeg.ByteSource, DelphiDoom.Jpeg.HuffmanTable,
  DelphiDoom.Jpeg.MarkerReader;

type
  /// <summary>
  ///   Gives the bits of the data of a scan: removes the zero that follows an
  ///   FF byte, stops at a marker, decodes Huffman codes
  /// </summary>
  /// <remarks>
  ///   Port of the bit reader of jdhuff.c of libjpeg 6b
  ///   (jpeg_fill_bit_buffer, jpeg_huff_decode and the macros that use them).
  ///   When the data end at a marker the reader gives zero bits until the
  ///   decoder has finished the block, and tells (InsufficientData) that the
  ///   rest of the scan is lost; if the marker is not in the stream but is
  ///   the one that the source makes up for the missing bytes the stream is
  ///   cut and the reader raises EJpegDecodeException (jdeTruncated)
  /// </remarks>
  TJpegBitReader = class
  private
    FSource: TJpegByteSource;
    FMarkers: TJpegMarkerReader;
    FBuffer: Cardinal;
    FBitsLeft: Integer;
    FInsufficientData: Boolean;
    procedure Fill(ANeeded: Integer);
    function DecodeLongCode(ATable: TJpegHuffmanTable; AMinimumBits: Integer): Integer;
  public
    constructor Create(ASource: TJpegByteSource; AMarkers: TJpegMarkerReader);

    /// <summary>
    ///   Starts a scan: no bit is left and the data are not lost
    /// </summary>
    procedure Start;

    /// <summary>
    ///   Gets rid of the bits that are left (they are the padding before a
    ///   restart marker)
    /// </summary>
    procedure DiscardBits;

    /// <summary>
    ///   The next ACount bits (1 to 16) as a number
    /// </summary>
    function ReadBits(ACount: Integer): Integer; inline;

    /// <summary>
    ///   The symbol of the next Huffman code. A code that is not in the table
    ///   gives 0
    /// </summary>
    function DecodeSymbol(ATable: TJpegHuffmanTable): Integer;

    /// <summary>
    ///   True after the data ran into a marker that is not a restart marker
    ///   the decoder expects; the decoder does not read data any more until a
    ///   restart marker
    /// </summary>
    property InsufficientData: Boolean read FInsufficientData write FInsufficientData;
  end;

implementation

uses
  DelphiDoom.Jpeg.Types;

const
  // The reader fills the buffer up to this number of bits (libjpeg has 25 on
  // machines where shifting by 32 is not a problem; this is the other value)
  MIN_GET_BITS = 15;

{ TJpegBitReader }

constructor TJpegBitReader.Create(ASource: TJpegByteSource; AMarkers: TJpegMarkerReader);
begin
  inherited Create;
  FSource := ASource;
  FMarkers := AMarkers;
end;

procedure TJpegBitReader.Start;
begin
  FBitsLeft := 0;
  FBuffer := 0;
  FInsufficientData := False;
end;

procedure TJpegBitReader.DiscardBits;
begin
  FBitsLeft := 0;
end;

procedure TJpegBitReader.Fill(ANeeded: Integer);
var
  LByte: Integer;
  LAtMarker: Boolean;
begin
  LAtMarker := FMarkers.UnreadMarker <> 0;
  if not LAtMarker then
  begin
    while FBitsLeft < MIN_GET_BITS do
    begin
      LByte := FSource.ReadByte;
      if LByte = $FF then
      begin
        // FF 00 is the byte FF; FF and anything else is a marker
        repeat
          LByte := FSource.ReadByte;
        until LByte <> $FF;
        if LByte = 0 then
          LByte := $FF
        else
        begin
          FMarkers.UnreadMarker := LByte;
          LAtMarker := True;
          Break;
        end;
      end;
      FBuffer := (FBuffer shl 8) or Cardinal(LByte);
      Inc(FBitsLeft, 8);
    end;
  end;

  if LAtMarker and (ANeeded > FBitsLeft) then
  begin
    // The data are over and the decoder wants more bits: it gets zeros. The
    // first time the scan is damaged, and if the stream is not a whole one
    // (the marker is the one that the source invents) it is cut
    if not FInsufficientData then
    begin
      if FSource.Exhausted then
        EJpegDecodeException.Fail(jdeTruncated);
      FInsufficientData := True;
    end;
    FBuffer := FBuffer shl (MIN_GET_BITS - FBitsLeft);
    FBitsLeft := MIN_GET_BITS;
  end;
end;

function TJpegBitReader.ReadBits(ACount: Integer): Integer;
begin
  if FBitsLeft < ACount then
    Fill(ACount);
  Dec(FBitsLeft, ACount);
  Result := Integer(FBuffer shr FBitsLeft) and ((1 shl ACount) - 1);
end;

function TJpegBitReader.DecodeLongCode(ATable: TJpegHuffmanTable;
  AMinimumBits: Integer): Integer;
var
  LBits: Integer;
  LCode: Integer;
begin
  // jpeg_huff_decode: the code is read a bit at a time until its length is
  // one that has symbols
  LBits := AMinimumBits;
  if FBitsLeft < LBits then
    Fill(LBits);
  Dec(FBitsLeft, LBits);
  LCode := Integer(FBuffer shr FBitsLeft) and ((1 shl LBits) - 1);

  while LCode > ATable.MaxCode(LBits) do
  begin
    LCode := LCode shl 1;
    if FBitsLeft < 1 then
      Fill(1);
    Dec(FBitsLeft);
    LCode := LCode or (Integer(FBuffer shr FBitsLeft) and 1);
    Inc(LBits);
  end;

  // No code is longer than 16 bits
  if LBits > 16 then
    Result := 0
  else
    Result := ATable.SymbolOf(LBits, LCode);
end;

function TJpegBitReader.DecodeSymbol(ATable: TJpegHuffmanTable): Integer;
var
  LLook: Integer;
  LBits: Integer;
begin
  if FBitsLeft < JPEG_HUFFMAN_LOOKAHEAD then
  begin
    Fill(0);
    if FBitsLeft < JPEG_HUFFMAN_LOOKAHEAD then
      // The data ended: the code is read a bit at a time
      Exit(DecodeLongCode(ATable, 1));
  end;

  LLook := Integer(FBuffer shr (FBitsLeft - JPEG_HUFFMAN_LOOKAHEAD)) and
    ((1 shl JPEG_HUFFMAN_LOOKAHEAD) - 1);
  LBits := ATable.LookBits(LLook);
  if LBits <> 0 then
  begin
    Dec(FBitsLeft, LBits);
    Result := ATable.LookSymbol(LLook);
  end
  else
    Result := DecodeLongCode(ATable, JPEG_HUFFMAN_LOOKAHEAD + 1);
end;

end.
