{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - whole buffer adaptive Huffman of Quake III        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): huffman.c.      }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.HuffmanCompressor;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.AdaptiveHuffman, DelphiDoom.Net.Q3.Message;

type
  /// <summary>
  ///   Huff_Compress and Huff_Decompress: compress the bytes of a message from an offset on with a fresh
  ///   adaptive tree (the tree learns the bytes as they go, nothing is shared between calls). The stream is
  ///   the size in two bytes (high byte first) followed by the codes
  /// </summary>
  TQ3HuffmanCompressor = class
  public
    /// <summary>
    ///   Replaces the bytes from AOffset with their compressed form and sets the size. The original keeps
    ///   one byte of garbage after the codes when they end exactly on a byte (it copies one byte more than it
    ///   wrote): here it is 0
    /// </summary>
    class procedure Compress(AMessage: TQ3Message; AOffset: Integer); static;
    /// <summary>
    ///   Replaces the compressed bytes from AOffset with the original ones. A stream that ends early gives
    ///   zeros for the missing bytes (the original: whatever was on the stack); the size in the stream is
    ///   cut to what fits in the message
    /// </summary>
    class procedure Decompress(AMessage: TQ3Message; AOffset: Integer); static;
  end;

implementation

const
  SequenceSize = 65536;

{ TQ3HuffmanCompressor }

class procedure TQ3HuffmanCompressor.Compress(AMessage: TQ3Message; AOffset: Integer);
var
  LSize, LIndex, LBit, LCount: Integer;
  LSequence: TBytes;
  LTree: TQ3AdaptiveHuffman;
  LChar: Byte;
begin
  LSize := AMessage.CurSize - AOffset;
  if LSize <= 0 then
    Exit;

  SetLength(LSequence, SequenceSize);
  LTree := TQ3AdaptiveHuffman.Create;
  try
    LSequence[0] := Byte(LSize shr 8);
    LSequence[1] := Byte(LSize and $FF);
    LBit := 16;
    for LIndex := 0 to LSize - 1 do
    begin
      LChar := AMessage.Data[AOffset + LIndex];
      LTree.Transmit(LChar, LSequence, LBit);
      LTree.AddRef(LChar);
    end;
    Inc(LBit, 8); // next byte
    LCount := LBit shr 3;
    if AOffset + LCount > Length(AMessage.Data) then
      raise EQ3MessageOverflowException.CreateFmt(SQ3MessageBufferOverrun, [AOffset + LCount, Length(AMessage.Data)]);
    AMessage.CurSize := LCount + AOffset;
    Move(LSequence[0], AMessage.Data[AOffset], LCount);
  finally
    LTree.Free;
  end;
end;

class procedure TQ3HuffmanCompressor.Decompress(AMessage: TQ3Message; AOffset: Integer);
var
  LSize, LCount, LIndex, LBit, LChar, LBitIndex: Integer;
  LSequence, LBuffer: TBytes;
  LTree: TQ3AdaptiveHuffman;
begin
  LSize := AMessage.CurSize - AOffset;
  if LSize <= 0 then
    Exit;

  SetLength(LSequence, SequenceSize);
  // all the bytes after the offset, as the original sees them (it may look past the used size)
  LBuffer := Copy(AMessage.Data, AOffset, Length(AMessage.Data) - AOffset);
  LTree := TQ3AdaptiveHuffman.Create;
  try
    LCount := LBuffer[0] * 256;
    if Length(LBuffer) > 1 then
      Inc(LCount, LBuffer[1]);
    // don't overflow with bad messages
    if LCount > AMessage.MaxSize - AOffset then
      LCount := AMessage.MaxSize - AOffset;
    if LCount < 0 then
      LCount := 0;
    LBit := 16;
    for LIndex := 0 to LCount - 1 do
    begin
      // don't overflow reading from the messages
      if (LBit shr 3) > LSize then
      begin
        LSequence[LIndex] := 0;
        Break;
      end;
      LChar := LTree.Receive(LBuffer, LBit); // get a character
      if LChar = Q3_HUFFMAN_NYT then
      begin
        // a NYT: the symbol is in the next 8 bits
        LChar := 0;
        for LBitIndex := 0 to 7 do
          LChar := (LChar shl 1) + TQ3AdaptiveHuffman.GetBit(LBuffer, LBit);
      end;
      LSequence[LIndex] := Byte(LChar);
      LTree.AddRef(Byte(LChar));
    end;
    if AOffset + LCount > Length(AMessage.Data) then
      raise EQ3MessageOverflowException.CreateFmt(SQ3MessageBufferOverrun, [AOffset + LCount, Length(AMessage.Data)]);
    AMessage.CurSize := LCount + AOffset;
    if LCount > 0 then
      Move(LSequence[0], AMessage.Data[AOffset], LCount);
  finally
    LTree.Free;
  end;
end;

end.
