{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - the checksum of the pages                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libogg by the Xiph.Org Foundation (BSD licence)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.Crc;

interface

type
  /// <summary>
  ///   The 32 bit CRC of the pages: the polynomial 04C11DB7, not reflected, with
  ///   zero at the start and at the end. It reads eight bytes at a time
  /// </summary>
  TOggCrc = class
  private
    class var FTable: array[0..7, 0..255] of Cardinal;
    class constructor Create;
  public
    /// <summary>Goes on with a checksum over ASize more bytes; start with zero</summary>
    class function Update(const ACrc: Cardinal; const ABuffer: PByte; const ASize: Integer): Cardinal; static;
  end;

implementation

const
  POLYNOMIAL = $04C11DB7;
  HIGH_BIT = $80000000;

{ TOggCrc }

class constructor TOggCrc.Create;
var
  LIndex, LStep: Integer;
  LCrc: Cardinal;
begin
  for LIndex := 0 to 255 do
  begin
    LCrc := Cardinal(LIndex) shl 24;
    for LStep := 0 to 7 do
    begin
      if (LCrc and HIGH_BIT) <> 0 then
        LCrc := (LCrc shl 1) xor POLYNOMIAL
      else
        LCrc := LCrc shl 1;
    end;
    FTable[0, LIndex] := LCrc;
  end;

  // The other seven tables are the first one, a byte further
  for LIndex := 0 to 255 do
  begin
    for LStep := 1 to 7 do
      FTable[LStep, LIndex] := FTable[0, (FTable[LStep - 1, LIndex] shr 24) and $FF] xor
        (FTable[LStep - 1, LIndex] shl 8);
  end;
end;

class function TOggCrc.Update(const ACrc: Cardinal; const ABuffer: PByte; const ASize: Integer): Cardinal;
var
  LBuffer: PByte;
  LSize: Integer;
begin
  Result := ACrc;
  LBuffer := ABuffer;
  LSize := ASize;

  while LSize >= 8 do
  begin
    Result := Result xor ((Cardinal(LBuffer[0]) shl 24) or (Cardinal(LBuffer[1]) shl 16) or
      (Cardinal(LBuffer[2]) shl 8) or Cardinal(LBuffer[3]));

    Result := FTable[7, Result shr 24] xor FTable[6, (Result shr 16) and $FF] xor
      FTable[5, (Result shr 8) and $FF] xor FTable[4, Result and $FF] xor
      FTable[3, LBuffer[4]] xor FTable[2, LBuffer[5]] xor
      FTable[1, LBuffer[6]] xor FTable[0, LBuffer[7]];

    Inc(LBuffer, 8);
    Dec(LSize, 8);
  end;

  while LSize > 0 do
  begin
    Result := (Result shl 8) xor FTable[0, ((Result shr 24) and $FF) xor LBuffer^];
    Inc(LBuffer);
    Dec(LSize);
  end;
end;

end.
