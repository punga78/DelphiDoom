{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the pieces of the geometry checksum          }
{                                                                              }
{  Port of FloatCRC and StringCRC of MapFile.cpp (idlib), Doom 3 GPL Source    }
{  Code. Based on the Doom 3 GPL Source Code (id Software). Copyright (C)      }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.GeometryCrc;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The "CRC" of a map is not a CRC-32: it is the exclusive or of the bit patterns of the
  ///   floats and of a text hash, so it cannot be computed with TCrc32 of Libs\MathCore
  /// </summary>
  TMapGeometryCrc = class
  public
    /// <summary>The bit pattern of the float (FloatCRC)</summary>
    class function FloatCrc(const AValue: Single): Cardinal; static;
    /// <summary>
    ///   StringCRC: each character, as a signed char, shifted left by its index modulo 4 and
    ///   combined with exclusive or; the text stops at the first #0 as a C string does
    /// </summary>
    class function StringCrc(const AText: AnsiString): Cardinal; static;
  end;

implementation

{ TMapGeometryCrc }

class function TMapGeometryCrc.FloatCrc(const AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

class function TMapGeometryCrc.StringCrc(const AText: AnsiString): Cardinal;
var
  LIndex: Integer;
  LSigned: Integer;
begin
  Result := 0;
  for LIndex := 0 to Length(AText) - 1 do
  begin
    if AText[LIndex + 1] = #0 then
      Break;
    // char is signed in the compiler of the original: a character above 127 is negative
    LSigned := ShortInt(Byte(AText[LIndex + 1]));
    Result := Result xor Cardinal(LSigned shl (LIndex and 3));
  end;
end;

end.
