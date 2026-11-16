{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the float instructions on the bits of a float     }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  The float cases of VM_CallInterpreted (code/qcommon/vm_interpreted.c),      }
{  Quake III Arena 1.32, with the answers of the SSE instructions of x86       }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.FloatMath;

interface

type
  /// <summary>
  ///   The parts of the float instructions that cannot be left to the processor without depending on which
  ///   one it is: the x87 unit of Win32 compares a NaN as equal, signals on loading one and picks the NaN
  ///   of a result by another rule, and the conversion to integer of Delphi goes through 64 bit. Here the
  ///   operands are the 32 bit patterns and the answers are the ones of the C compiled for SSE
  ///   (ucomiss, cvttss2si, addss ...), the same at 32 and 64 bit
  /// </summary>
  TQvmFloatMath = class
  public
    const
      EXPONENT_MASK = Integer($7F800000);
      MAGNITUDE_MASK = Integer($7FFFFFFF);
      QUIET_BIT = Integer($00400000);
    /// <summary>The bits as an integer that sorts as the float does: -0 and +0 are both 0</summary>
    class function SortKey(ABits: Integer): Integer; static; inline;
    /// <summary>An infinite or a NaN: the operands Special must handle</summary>
    class function IsSpecial(ABits: Integer): Boolean; static; inline;
    class function IsNaN(ABits: Integer): Boolean; static; inline;
    /// <summary>a == b: false with a NaN, +0 equals -0</summary>
    class function Equal(AFirst, ASecond: Integer): Boolean; static; inline;
    /// <summary>a &lt; b: false with a NaN</summary>
    class function Less(AFirst, ASecond: Integer): Boolean; static; inline;
    /// <summary>a &lt;= b: false with a NaN</summary>
    class function LessOrEqual(AFirst, ASecond: Integer): Boolean; static; inline;
    /// <summary>
    ///   (int)a as cvttss2si: towards zero; $80000000 for a NaN and for what does not fit in 32 bit
    /// </summary>
    class function ToInteger(ABits: Integer): Integer; static;
    /// <summary>
    ///   An operation (OP_ADDF, OP_SUBF, OP_DIVF, OP_MULF) with at least one infinite or NaN operand: a NaN
    ///   operand is the result, made quiet, the first one if both are; otherwise the processor decides
    ///   (the arithmetic exceptions must be masked)
    /// </summary>
    class function Special(AOpcode, AFirst, ASecond: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes;

{$EXCESSPRECISION OFF}
{$Q-}
{$R-}


{ TQvmFloatMath }

class function TQvmFloatMath.IsSpecial(ABits: Integer): Boolean;
begin
  Result := (ABits and EXPONENT_MASK) = EXPONENT_MASK;
end;

class function TQvmFloatMath.IsNaN(ABits: Integer): Boolean;
begin
  Result := (ABits and MAGNITUDE_MASK) > EXPONENT_MASK;
end;


class function TQvmFloatMath.SortKey(ABits: Integer): Integer;
begin
  if ABits < 0 then
    Result := -(ABits and MAGNITUDE_MASK)
  else
    Result := ABits;
end;

class function TQvmFloatMath.Equal(AFirst, ASecond: Integer): Boolean;
begin
  Result := (not IsNaN(AFirst)) and (not IsNaN(ASecond)) and (SortKey(AFirst) = SortKey(ASecond));
end;

class function TQvmFloatMath.Less(AFirst, ASecond: Integer): Boolean;
begin
  Result := (not IsNaN(AFirst)) and (not IsNaN(ASecond)) and (SortKey(AFirst) < SortKey(ASecond));
end;

class function TQvmFloatMath.LessOrEqual(AFirst, ASecond: Integer): Boolean;
begin
  Result := (not IsNaN(AFirst)) and (not IsNaN(ASecond)) and (SortKey(AFirst) <= SortKey(ASecond));
end;

class function TQvmFloatMath.ToInteger(ABits: Integer): Integer;
var
  LExponent: Integer;
  LMantissa: Cardinal;
begin
  LExponent := (ABits shr 23) and $FF;
  if LExponent < 127 then
    Exit(0);
  // 2^31 and above, infinite, NaN: the "integer indefinite" of x86 (-2^31 itself is the same pattern)
  if LExponent >= 158 then
    Exit(Integer($80000000));
  LMantissa := (Cardinal(ABits) and $007FFFFF) or $00800000;
  if LExponent >= 150 then
    LMantissa := LMantissa shl (LExponent - 150)
  else
    LMantissa := LMantissa shr (150 - LExponent);
  if ABits < 0 then
    Result := -Integer(LMantissa)
  else
    Result := Integer(LMantissa);
end;

class function TQvmFloatMath.Special(AOpcode, AFirst, ASecond: Integer): Integer;
var
  LFirst, LSecond, LResult: Single;
begin
  if IsNaN(AFirst) then
    Exit(AFirst or QUIET_BIT);
  if IsNaN(ASecond) then
    Exit(ASecond or QUIET_BIT);
  LFirst := PSingle(@AFirst)^;
  LSecond := PSingle(@ASecond)^;
  case AOpcode of
    OP_ADDF:
      LResult := LFirst + LSecond;
    OP_SUBF:
      LResult := LFirst - LSecond;
    OP_DIVF:
      LResult := LFirst / LSecond;
  else
    LResult := LFirst * LSecond;
  end;
  Result := PInteger(@LResult)^;
end;

end.
