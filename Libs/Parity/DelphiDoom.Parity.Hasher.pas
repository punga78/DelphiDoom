{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the 64 bit hash                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Hasher;

// the hash wraps around on purpose: no overflow and no range checks
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The hash of the parity tools: FNV-1a with 64 bits. Bytes are mixed one by one as in the real FNV-1a;
  ///   a whole number (AddInteger, AddInt64) and the 4 bytes of a span are mixed in one step (xor, multiply by
  ///   the FNV prime, then the high half is folded into the low one): every step is reversible, so two
  ///   sequences that differ in a single value never give the same hash. The result depends only on the
  ///   values, never on addresses, so two builds of the engine give the same hash for the same state
  /// </summary>
  TParityHasher = record
  strict private
    FValue: UInt64;
  public
    /// <summary>Starts again from the offset basis of FNV-1a</summary>
    procedure Reset;
    procedure AddByte(AValue: Byte);
    /// <summary>A 32 bit value (negative ones included) as one step</summary>
    procedure AddInteger(AValue: Integer);
    procedure AddInt64(AValue: Int64);
    procedure AddString(const AValue: AnsiString);
    /// <summary>
    ///   A block of memory: 4 bytes at a time while they last, then the remaining bytes one by one. The
    ///   same bytes cut in different blocks give a different hash: hash a buffer always the same way
    /// </summary>
    procedure AddSpan(AData: Pointer; ACount: Integer);
    /// <summary>The hash of what was added until now</summary>
    property Value: UInt64 read FValue;
    /// <summary>The 16 hexadecimal digits (lowercase) of a hash</summary>
    class function ToHex(AValue: UInt64): string; static;
    /// <summary>The 8 hexadecimal digits of the two halves of a hash xored together</summary>
    class function ToShortHex(AValue: UInt64): string; static;
  end;

implementation

uses
  System.SysUtils;

const
  FNV_OFFSET_BASIS = UInt64($CBF29CE484222325);
  FNV_PRIME = UInt64($00000100000001B3);

procedure TParityHasher.Reset;
begin
  FValue := FNV_OFFSET_BASIS;
end;

procedure TParityHasher.AddByte(AValue: Byte);
begin
  FValue := (FValue xor AValue) * FNV_PRIME;
end;

procedure TParityHasher.AddInteger(AValue: Integer);
begin
  FValue := (FValue xor UInt64(Cardinal(AValue))) * FNV_PRIME;
  FValue := FValue xor (FValue shr 32);
end;

procedure TParityHasher.AddInt64(AValue: Int64);
begin
  AddInteger(Integer(AValue and $FFFFFFFF));
  AddInteger(Integer((AValue shr 32) and $FFFFFFFF));
end;

procedure TParityHasher.AddString(const AValue: AnsiString);
var
  LIndex: Integer;
begin
  AddInteger(Length(AValue));
  for LIndex := 1 to Length(AValue) do
    AddByte(Byte(AValue[LIndex]));
end;

procedure TParityHasher.AddSpan(AData: Pointer; ACount: Integer);
var
  LWords: PCardinal;
  LBytes: PByte;
  LCount: Integer;
begin
  LWords := PCardinal(AData);
  LCount := ACount;
  while LCount >= 4 do
  begin
    FValue := (FValue xor UInt64(LWords^)) * FNV_PRIME;
    FValue := FValue xor (FValue shr 32);
    Inc(LWords);
    Dec(LCount, 4);
  end;
  LBytes := PByte(LWords);
  while LCount > 0 do
  begin
    AddByte(LBytes^);
    Inc(LBytes);
    Dec(LCount);
  end;
end;

class function TParityHasher.ToHex(AValue: UInt64): string;
begin
  Result := LowerCase(IntToHex(Int64(AValue), 16));
end;

class function TParityHasher.ToShortHex(AValue: UInt64): string;
begin
  Result := LowerCase(IntToHex(Int64(Cardinal(AValue and $FFFFFFFF) xor Cardinal(AValue shr 32)), 8));
end;

end.
