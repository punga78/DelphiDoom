{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - big-endian integers                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.ByteOrder;

interface

{$POINTERMATH ON}

type
  /// <summary>
  ///   Reads and writes the big-endian integers of the PNG format, whatever
  ///   the alignment of the address
  /// </summary>
  TPngByteOrder = class sealed
  public
    class function ReadWord(AData: PByte): Cardinal; static;
    class function ReadCardinal(AData: PByte): Cardinal; static;
    class procedure WriteCardinal(AData: PByte; AValue: Cardinal); static;
  end;

implementation

{ TPngByteOrder }

class function TPngByteOrder.ReadWord(AData: PByte): Cardinal;
begin
  Result := (Cardinal(AData[0]) shl 8) or Cardinal(AData[1]);
end;

class function TPngByteOrder.ReadCardinal(AData: PByte): Cardinal;
begin
  Result := (Cardinal(AData[0]) shl 24) or (Cardinal(AData[1]) shl 16) or
    (Cardinal(AData[2]) shl 8) or Cardinal(AData[3]);
end;

class procedure TPngByteOrder.WriteCardinal(AData: PByte; AValue: Cardinal);
begin
  AData[0] := Byte(AValue shr 24);
  AData[1] := Byte(AValue shr 16);
  AData[2] := Byte(AValue shr 8);
  AData[3] := Byte(AValue);
end;

end.
