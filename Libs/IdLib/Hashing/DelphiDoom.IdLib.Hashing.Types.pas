{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib hashing - shared types                                    }
{                                                                              }
{  Rewrite of the digests of idLib (id Software, Doom 3, GPL v3): the          }
{  algorithms are RFC 1320 (MD4) and RFC 1321 (MD5); the code is written from  }
{  the specification and checked against the original (see README.md).        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Hashing.Types;

interface

type
  /// <summary>A 128-bit message digest (MD4 and MD5), in the byte order of the RFCs</summary>
  TIdDigest128 = array[0..15] of Byte;

  /// <summary>Helpers on digests that idLib needs: the text form and the 32-bit fold</summary>
  TIdDigests = class
  public
    /// <summary>The digest as 32 hexadecimal digits in lower case</summary>
    class function ToHex(const ADigest: TIdDigest128): string; static;
    /// <summary>
    ///   The 32-bit value of MD4_BlockChecksum / MD5_BlockChecksum of idLib: the four little endian
    ///   words of the digest combined with xor
    /// </summary>
    class function FoldToCardinal(const ADigest: TIdDigest128): Cardinal; static;
  end;

implementation

{ TIdDigests }

class function TIdDigests.ToHex(const ADigest: TIdDigest128): string;
const
  HEX_DIGITS: string = '0123456789abcdef';
var
  LIndex: Integer;
begin
  SetLength(Result, 32);
  for LIndex := 0 to 15 do
  begin
    Result[LIndex * 2 + 1] := HEX_DIGITS[(ADigest[LIndex] shr 4) + 1];
    Result[LIndex * 2 + 2] := HEX_DIGITS[(ADigest[LIndex] and $0F) + 1];
  end;
end;

class function TIdDigests.FoldToCardinal(const ADigest: TIdDigest128): Cardinal;
var
  LWord: Integer;
  LValue: Cardinal;
begin
  Result := 0;
  for LWord := 0 to 3 do
  begin
    LValue := Cardinal(ADigest[LWord * 4]) or (Cardinal(ADigest[LWord * 4 + 1]) shl 8) or
      (Cardinal(ADigest[LWord * 4 + 2]) shl 16) or (Cardinal(ADigest[LWord * 4 + 3]) shl 24);
    Result := Result xor LValue;
  end;
end;

end.
