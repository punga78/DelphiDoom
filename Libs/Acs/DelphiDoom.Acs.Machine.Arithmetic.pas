{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the arithmetic of the virtual machine             }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine.Arithmetic;

// The numbers of a script wrap around at 32 bits, as they did in the engine of Raven
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The operations of the commands that can fail or that are not the same in every
  ///   processor: a division by zero gives zero, the shifts use the five low bits of the count and
  ///   the right shift keeps the sign
  /// </summary>
  TAcsArithmetic = class
  public
    /// <summary>Zero if the divisor is zero</summary>
    class function Divide(ADividend, ADivisor: Integer): Integer; static;
    /// <summary>Zero if the divisor is zero; the sign is the one of the dividend</summary>
    class function Modulo(ADividend, ADivisor: Integer): Integer; static;
    class function ShiftLeft(AValue, ACount: Integer): Integer; static;
    /// <summary>Arithmetic shift: a negative number stays negative</summary>
    class function ShiftRight(AValue, ACount: Integer): Integer; static;
  end;

implementation

{ TAcsArithmetic }

class function TAcsArithmetic.Divide(ADividend, ADivisor: Integer): Integer;
begin
  if ADivisor = 0 then
    Result := 0
  else if ADivisor = -1 then
    Result := -ADividend // the smallest number divided by -1 does not raise
  else
    Result := ADividend div ADivisor;
end;

class function TAcsArithmetic.Modulo(ADividend, ADivisor: Integer): Integer;
begin
  if (ADivisor = 0) or (ADivisor = -1) then
    Result := 0
  else
    Result := ADividend mod ADivisor;
end;

class function TAcsArithmetic.ShiftLeft(AValue, ACount: Integer): Integer;
begin
  Result := Integer(Cardinal(AValue) shl (ACount and 31));
end;

class function TAcsArithmetic.ShiftRight(AValue, ACount: Integer): Integer;
var
  LCount: Integer;
begin
  LCount := ACount and 31;
  if AValue >= 0 then
    Result := AValue shr LCount
  else
    Result := not ((not AValue) shr LCount);
end;

end.
