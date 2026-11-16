{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - CRC-32 of the chunks                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Crc;

interface

{$POINTERMATH ON}

type
  /// <summary>
  ///   CRC-32 as the PNG specification defines it (the one of zlib)
  /// </summary>
  TPngCrc = class sealed
  private
    class var FTable: array[0..255] of Cardinal;
    class constructor Create;
  public
    /// <summary>
    ///   Continues a CRC with ALength more bytes: ACrc is 0 at the beginning
    ///   and the result of the previous call afterwards
    /// </summary>
    class function Update(ACrc: Cardinal; AData: PByte;
      ALength: Cardinal): Cardinal; static;

    /// <summary>
    ///   CRC of ALength bytes
    /// </summary>
    class function Compute(AData: PByte; ALength: Cardinal): Cardinal; static;
  end;

implementation

{ TPngCrc }

class constructor TPngCrc.Create;
var
  LIndex: Integer;
  LBit: Integer;
  LValue: Cardinal;
begin
  for LIndex := 0 to 255 do
  begin
    LValue := Cardinal(LIndex);
    for LBit := 0 to 7 do
      if (LValue and 1) <> 0 then
        LValue := $EDB88320 xor (LValue shr 1)
      else
        LValue := LValue shr 1;
    FTable[LIndex] := LValue;
  end;
end;

class function TPngCrc.Update(ACrc: Cardinal; AData: PByte;
  ALength: Cardinal): Cardinal;
var
  LIndex: Cardinal;
begin
  Result := ACrc xor $FFFFFFFF;
  LIndex := 0;
  while LIndex < ALength do
  begin
    Result := FTable[(Result xor AData[LIndex]) and $FF] xor (Result shr 8);
    Inc(LIndex);
  end;
  Result := Result xor $FFFFFFFF;
end;

class function TPngCrc.Compute(AData: PByte; ALength: Cardinal): Cardinal;
begin
  Result := Update(0, AData, ALength);
end;

end.
