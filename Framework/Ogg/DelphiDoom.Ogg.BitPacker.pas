{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - words of variable size packed in a stream of bytes        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libogg by the Xiph.Org Foundation (BSD licence)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.BitPacker;

interface

uses
  DelphiDoom.Ogg.Types;

type
  /// <summary>
  ///   Writes and reads words of up to 32 bits. The order is the one of Ogg: the least
  ///   significant bit goes first, so a word that is written whole is read back by
  ///   its low bits first (the oggpack_* functions)
  /// </summary>
  /// <remarks>
  ///   The reads that go beyond the end of the data do not fail with an exception: they
  ///   return -1 and leave the buffer at its end, with Ptr nil, as the C code does
  /// </remarks>
  TOggBitPacker = class
  public
    class procedure WriteInit(const ABuffer: POggPackBuffer); static;
    /// <returns>0, or -1 when the buffer has been cleared after an error</returns>
    class function WriteCheck(const ABuffer: POggPackBuffer): Integer; static;
    /// <summary>Cuts the buffer to ABits bits</summary>
    class procedure WriteTruncate(const ABuffer: POggPackBuffer; const ABits: Longint); static;
    /// <summary>Writes the low ABits bits of AValue (0 to 32 of them)</summary>
    class procedure Write(const ABuffer: POggPackBuffer; const AValue: Cardinal; const ABits: Integer); static;
    /// <summary>Fills the byte that is being written with zeros</summary>
    class procedure WriteAlign(const ABuffer: POggPackBuffer); static;
    /// <summary>Copies ABits bits that begin at ASource</summary>
    class procedure WriteCopy(const ABuffer: POggPackBuffer; const ASource: Pointer; const ABits: Longint); static;
    /// <summary>Starts writing again at the beginning, keeping the storage</summary>
    class procedure Reset(const ABuffer: POggPackBuffer); static;
    class procedure WriteClear(const ABuffer: POggPackBuffer); static;

    class procedure ReadInit(const ABuffer: POggPackBuffer; const AData: PByte; const ABytes: Integer); static;
    /// <summary>The next ABits bits (0 to 32), without moving; -1 beyond the end</summary>
    class function Look(const ABuffer: POggPackBuffer; const ABits: Integer): Longint; static;
    class function Look1(const ABuffer: POggPackBuffer): Longint; static;
    /// <summary>Skips ABits bits</summary>
    class procedure Advance(const ABuffer: POggPackBuffer; const ABits: Integer); static;
    class procedure Advance1(const ABuffer: POggPackBuffer); static;
    /// <summary>The next ABits bits (0 to 32); -1 beyond the end</summary>
    class function Read(const ABuffer: POggPackBuffer; const ABits: Integer): Longint; static;
    class function Read1(const ABuffer: POggPackBuffer): Longint; static;
    /// <summary>The bytes that the bits written or read so far take</summary>
    class function Bytes(const ABuffer: POggPackBuffer): Longint; static;
    class function Bits(const ABuffer: POggPackBuffer): Longint; static;
    class function GetBuffer(const ABuffer: POggPackBuffer): PByte; static;
  end;

implementation

uses
  DelphiDoom.Ogg.Memory;

const
  BUFFER_INCREMENT = 256;
  MAX_LONG = 2147483647;
  MAX_BITS = 32;
  BITS_PER_BYTE = 8;

  // MASK[n] has the n low bits set
  MASK: array[0..32] of Cardinal = (
    $00000000, $00000001, $00000003, $00000007, $0000000F,
    $0000001F, $0000003F, $0000007F, $000000FF, $000001FF,
    $000003FF, $000007FF, $00000FFF, $00001FFF, $00003FFF,
    $00007FFF, $0000FFFF, $0001FFFF, $0003FFFF, $0007FFFF,
    $000FFFFF, $001FFFFF, $003FFFFF, $007FFFFF, $00FFFFFF,
    $01FFFFFF, $03FFFFFF, $07FFFFFF, $0FFFFFFF, $1FFFFFFF,
    $3FFFFFFF, $7FFFFFFF, $FFFFFFFF);

{ TOggBitPacker }

class procedure TOggBitPacker.WriteInit(const ABuffer: POggPackBuffer);
begin
  FillChar(ABuffer^, SizeOf(ABuffer^), 0);
  ABuffer.Buffer := TOggMemory.Allocate(BUFFER_INCREMENT);
  ABuffer.Ptr := ABuffer.Buffer;
  if Assigned(ABuffer.Buffer) then
    ABuffer.Buffer[0] := 0;
  ABuffer.Storage := BUFFER_INCREMENT;
end;

class function TOggBitPacker.WriteCheck(const ABuffer: POggPackBuffer): Integer;
begin
  if not Assigned(ABuffer.Ptr) or (ABuffer.Storage = 0) then
    Exit(-1);
  Result := 0;
end;

class procedure TOggBitPacker.WriteTruncate(const ABuffer: POggPackBuffer; const ABits: Longint);
var
  LBytes, LBits: Longint;
begin
  LBytes := ABits shr 3;
  if Assigned(ABuffer.Ptr) then
  begin
    LBits := ABits - LBytes * 8;
    ABuffer.Ptr := ABuffer.Buffer + LBytes;
    ABuffer.EndBit := LBits;
    ABuffer.EndByte := LBytes;
    ABuffer.Ptr^ := ABuffer.Ptr^ and Byte(MASK[LBits]);
  end;
end;

class procedure TOggBitPacker.Write(const ABuffer: POggPackBuffer; const AValue: Cardinal;
  const ABits: Integer);
var
  LValue: Cardinal;
  LBits: Integer;
  LNew: Pointer;
begin
  if (ABits < 0) or (ABits > MAX_BITS) then
  begin
    WriteClear(ABuffer);
    Exit;
  end;

  if ABuffer.EndByte >= ABuffer.Storage - 4 then
  begin
    if not Assigned(ABuffer.Ptr) then
      Exit;
    if ABuffer.Storage > MAX_LONG - BUFFER_INCREMENT then
    begin
      WriteClear(ABuffer);
      Exit;
    end;
    LNew := TOggMemory.Reallocate(ABuffer.Buffer, ABuffer.Storage + BUFFER_INCREMENT);
    if not Assigned(LNew) then
    begin
      WriteClear(ABuffer);
      Exit;
    end;
    ABuffer.Buffer := LNew;
    Inc(ABuffer.Storage, BUFFER_INCREMENT);
    ABuffer.Ptr := ABuffer.Buffer + ABuffer.EndByte;
  end;

  LValue := AValue and MASK[ABits];
  LBits := ABits + ABuffer.EndBit;

  ABuffer.Ptr[0] := ABuffer.Ptr[0] or Byte(LValue shl ABuffer.EndBit);

  if LBits >= 8 then
  begin
    ABuffer.Ptr[1] := Byte(LValue shr (8 - ABuffer.EndBit));
    if LBits >= 16 then
    begin
      ABuffer.Ptr[2] := Byte(LValue shr (16 - ABuffer.EndBit));
      if LBits >= 24 then
      begin
        ABuffer.Ptr[3] := Byte(LValue shr (24 - ABuffer.EndBit));
        if LBits >= 32 then
        begin
          if ABuffer.EndBit <> 0 then
            ABuffer.Ptr[4] := Byte(LValue shr (32 - ABuffer.EndBit))
          else
            ABuffer.Ptr[4] := 0;
        end;
      end;
    end;
  end;

  Inc(ABuffer.EndByte, LBits div 8);
  Inc(ABuffer.Ptr, LBits div 8);
  ABuffer.EndBit := LBits and 7;
end;

class procedure TOggBitPacker.WriteAlign(const ABuffer: POggPackBuffer);
var
  LBits: Integer;
begin
  LBits := 8 - ABuffer.EndBit;
  if LBits < 8 then
    Write(ABuffer, 0, LBits);
end;

class procedure TOggBitPacker.WriteCopy(const ABuffer: POggPackBuffer; const ASource: Pointer;
  const ABits: Longint);
var
  LSource: PByte;
  LBytes, LPackedBytes, LBits: Longint;
  LIndex: Longint;
  LNew: Pointer;
begin
  LSource := ASource;
  LBytes := ABits div 8;
  LPackedBytes := (ABuffer.EndBit + ABits) div 8;
  LBits := ABits - LBytes * 8;

  // Room for all of it first
  if ABuffer.EndByte + LPackedBytes >= ABuffer.Storage then
  begin
    if not Assigned(ABuffer.Ptr) or (ABuffer.Storage > ABuffer.EndByte + LPackedBytes + BUFFER_INCREMENT) then
    begin
      WriteClear(ABuffer);
      Exit;
    end;
    ABuffer.Storage := ABuffer.EndByte + LPackedBytes + BUFFER_INCREMENT;
    LNew := TOggMemory.Reallocate(ABuffer.Buffer, ABuffer.Storage);
    if not Assigned(LNew) then
    begin
      WriteClear(ABuffer);
      Exit;
    end;
    ABuffer.Buffer := LNew;
    ABuffer.Ptr := ABuffer.Buffer + ABuffer.EndByte;
  end;

  if ABuffer.EndBit <> 0 then
  begin
    // Not on a byte boundary: one byte at a time
    for LIndex := 0 to LBytes - 1 do
      Write(ABuffer, LSource[LIndex], 8);
  end
  else
  begin
    Move(LSource^, ABuffer.Ptr^, LBytes);
    Inc(ABuffer.Ptr, LBytes);
    Inc(ABuffer.EndByte, LBytes);
    ABuffer.Ptr^ := 0;
  end;

  if LBits <> 0 then
    Write(ABuffer, LSource[LBytes], LBits);
end;

class procedure TOggBitPacker.Reset(const ABuffer: POggPackBuffer);
begin
  if not Assigned(ABuffer.Ptr) then
    Exit;
  ABuffer.Ptr := ABuffer.Buffer;
  ABuffer.Buffer[0] := 0;
  ABuffer.EndBit := 0;
  ABuffer.EndByte := 0;
end;

class procedure TOggBitPacker.WriteClear(const ABuffer: POggPackBuffer);
begin
  TOggMemory.Release(ABuffer.Buffer);
  FillChar(ABuffer^, SizeOf(ABuffer^), 0);
end;

class procedure TOggBitPacker.ReadInit(const ABuffer: POggPackBuffer; const AData: PByte;
  const ABytes: Integer);
begin
  FillChar(ABuffer^, SizeOf(ABuffer^), 0);
  ABuffer.Buffer := AData;
  ABuffer.Ptr := AData;
  ABuffer.Storage := ABytes;
end;

class function TOggBitPacker.Look(const ABuffer: POggPackBuffer; const ABits: Integer): Longint;
var
  LResult, LMask: Cardinal;
  LBits: Integer;
begin
  if (ABits < 0) or (ABits > MAX_BITS) then
    Exit(-1);
  LMask := MASK[ABits];
  LBits := ABits + ABuffer.EndBit;

  if ABuffer.EndByte >= ABuffer.Storage - 4 then
  begin
    // Not the main path: the end of the data is near
    if ABuffer.EndByte > ABuffer.Storage - ((LBits + 7) shr 3) then
      Exit(-1)
    else if LBits = 0 then
      Exit(0);
  end;

  LResult := Cardinal(ABuffer.Ptr[0]) shr ABuffer.EndBit;
  if LBits > 8 then
  begin
    LResult := LResult or (Cardinal(ABuffer.Ptr[1]) shl (8 - ABuffer.EndBit));
    if LBits > 16 then
    begin
      LResult := LResult or (Cardinal(ABuffer.Ptr[2]) shl (16 - ABuffer.EndBit));
      if LBits > 24 then
      begin
        LResult := LResult or (Cardinal(ABuffer.Ptr[3]) shl (24 - ABuffer.EndBit));
        if (LBits > 32) and (ABuffer.EndBit <> 0) then
          LResult := LResult or (Cardinal(ABuffer.Ptr[4]) shl (32 - ABuffer.EndBit));
      end;
    end;
  end;
  Result := Longint(LMask and LResult);
end;

class function TOggBitPacker.Look1(const ABuffer: POggPackBuffer): Longint;
begin
  if ABuffer.EndByte >= ABuffer.Storage then
    Exit(-1);
  Result := (ABuffer.Ptr[0] shr ABuffer.EndBit) and 1;
end;

class procedure TOggBitPacker.Advance(const ABuffer: POggPackBuffer; const ABits: Integer);
var
  LBits: Integer;
begin
  LBits := ABits + ABuffer.EndBit;

  if ABuffer.EndByte > ABuffer.Storage - ((LBits + 7) shr 3) then
  begin
    ABuffer.Ptr := nil;
    ABuffer.EndByte := ABuffer.Storage;
    ABuffer.EndBit := 1;
    Exit;
  end;

  Inc(ABuffer.Ptr, LBits div 8);
  Inc(ABuffer.EndByte, LBits div 8);
  ABuffer.EndBit := LBits and 7;
end;

class procedure TOggBitPacker.Advance1(const ABuffer: POggPackBuffer);
begin
  Inc(ABuffer.EndBit);
  if ABuffer.EndBit > 7 then
  begin
    ABuffer.EndBit := 0;
    Inc(ABuffer.Ptr);
    Inc(ABuffer.EndByte);
  end;
end;

class function TOggBitPacker.Read(const ABuffer: POggPackBuffer; const ABits: Integer): Longint;
var
  LResult, LMask: Cardinal;
  LBits: Integer;

  function Overflow: Longint;
  begin
    ABuffer.Ptr := nil;
    ABuffer.EndByte := ABuffer.Storage;
    ABuffer.EndBit := 1;
    Result := -1;
  end;

begin
  if (ABits < 0) or (ABits > MAX_BITS) then
    Exit(Overflow);
  LMask := MASK[ABits];
  LBits := ABits + ABuffer.EndBit;

  if ABuffer.EndByte >= ABuffer.Storage - 4 then
  begin
    // Not the main path: the end of the data is near
    if ABuffer.EndByte > ABuffer.Storage - ((LBits + 7) shr 3) then
      Exit(Overflow)
    else if LBits = 0 then
      Exit(0);
  end;

  LResult := Cardinal(ABuffer.Ptr[0]) shr ABuffer.EndBit;
  if LBits > 8 then
  begin
    LResult := LResult or (Cardinal(ABuffer.Ptr[1]) shl (8 - ABuffer.EndBit));
    if LBits > 16 then
    begin
      LResult := LResult or (Cardinal(ABuffer.Ptr[2]) shl (16 - ABuffer.EndBit));
      if LBits > 24 then
      begin
        LResult := LResult or (Cardinal(ABuffer.Ptr[3]) shl (24 - ABuffer.EndBit));
        if (LBits > 32) and (ABuffer.EndBit <> 0) then
          LResult := LResult or (Cardinal(ABuffer.Ptr[4]) shl (32 - ABuffer.EndBit));
      end;
    end;
  end;
  LResult := LResult and LMask;
  Inc(ABuffer.Ptr, LBits div 8);
  Inc(ABuffer.EndByte, LBits div 8);
  ABuffer.EndBit := LBits and 7;
  Result := Longint(LResult);
end;

class function TOggBitPacker.Read1(const ABuffer: POggPackBuffer): Longint;
begin
  if ABuffer.EndByte >= ABuffer.Storage then
  begin
    ABuffer.Ptr := nil;
    ABuffer.EndByte := ABuffer.Storage;
    ABuffer.EndBit := 1;
    Exit(-1);
  end;
  Result := (ABuffer.Ptr[0] shr ABuffer.EndBit) and 1;

  Inc(ABuffer.EndBit);
  if ABuffer.EndBit > 7 then
  begin
    ABuffer.EndBit := 0;
    Inc(ABuffer.Ptr);
    Inc(ABuffer.EndByte);
  end;
end;

class function TOggBitPacker.Bytes(const ABuffer: POggPackBuffer): Longint;
begin
  Result := ABuffer.EndByte + (ABuffer.EndBit + 7) div 8;
end;

class function TOggBitPacker.Bits(const ABuffer: POggPackBuffer): Longint;
begin
  Result := ABuffer.EndByte * 8 + ABuffer.EndBit;
end;

class function TOggBitPacker.GetBuffer(const ABuffer: POggPackBuffer): PByte;
begin
  Result := ABuffer.Buffer;
end;

end.
