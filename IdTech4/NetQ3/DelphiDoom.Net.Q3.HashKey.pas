{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - Com_HashKey of Quake III, the key of the user     }
{  commands                                                                    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): common.c        }
{  (Com_HashKey). Copyright (C) 1999-2005 id Software, Inc.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.HashKey;

// Overflow and range checks are off: hash is a 32 bit int that wraps, as in the C.
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The hash of the last server command the client acknowledged, which both sides xor into the key of the
  ///   user commands (SV_UserMove and CL_WritePacket)
  /// </summary>
  TQ3HashKey = class sealed
  public
    /// <summary>
    ///   Com_HashKey( string, maxlen ): the characters are signed (char of the C), the right shifts are
    ///   arithmetic, the string ends at its first NUL or at maxlen
    /// </summary>
    class function Compute(const AText: AnsiString; AMaxLength: Integer): Integer; static;
  end;

implementation

function ArithmeticShift(AValue, ACount: Integer): Integer; inline;
begin
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := not ((not AValue) shr ACount);
end;

class function TQ3HashKey.Compute(const AText: AnsiString; AMaxLength: Integer): Integer;
var
  LIndex: Integer;
  LHash: Integer;
begin
  LHash := 0;
  LIndex := 0;
  while (LIndex < AMaxLength) and (LIndex < Length(AText)) and (AText[LIndex + 1] <> #0) do
  begin
    LHash := LHash + ShortInt(Ord(AText[LIndex + 1])) * (119 + LIndex);
    Inc(LIndex);
  end;
  Result := LHash xor ArithmeticShift(LHash, 10) xor ArithmeticShift(LHash, 20);
end;

end.
