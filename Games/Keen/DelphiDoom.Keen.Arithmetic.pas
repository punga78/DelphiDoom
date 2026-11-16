{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the arithmetic of a 16 bit int                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Arithmetic;

interface

type
  /// <summary>
  ///   The C of the game is for a 16 bit compiler: an int and an unsigned wrap at 16 bits, and the shift right
  ///   of an int keeps the sign. Delphi has a logical shr for every integer, so the shifts of the port go here
  /// </summary>
  TKeenArithmetic = class
  public
    /// <summary>AValue >> AShift for a signed int: the sign is kept (a negative number rounds toward minus infinity)</summary>
    class function ShiftRight(AValue, AShift: Integer): Integer; static; inline;
    /// <summary>The value as an unsigned 16 bit number (what an unsigned variable holds after any arithmetic)</summary>
    class function ToWord(AValue: Integer): Word; static; inline;
    /// <summary>The value as a signed 16 bit number (what an int variable holds)</summary>
    class function ToInt16(AValue: Integer): SmallInt; static; inline;
  end;

implementation

{ TKeenArithmetic }

class function TKeenArithmetic.ShiftRight(AValue, AShift: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr AShift
  else
    Result := not ((not AValue) shr AShift);
end;

class function TKeenArithmetic.ToWord(AValue: Integer): Word;
begin
  Result := Word(AValue and $FFFF);
end;

class function TKeenArithmetic.ToInt16(AValue: Integer): SmallInt;
begin
  Result := SmallInt(Word(AValue and $FFFF));
end;

end.
