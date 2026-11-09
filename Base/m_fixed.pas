//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Fixed point arithemtics, implementation.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_fixed;

interface

uses
  d_delphi;

//
// Fixed point, 32bit as 16.16.
//

const
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;

type
  fixed_t = integer;
  Pfixed_t = ^fixed_t;
  fixed_tArray = packed array[0..$FFFF] of fixed_t;
  Pfixed_tArray = ^fixed_tArray;
  fixed64_t = int64;
  fixedfloat_t = double;

//==============================================================================
//
// FixedMul
//
//==============================================================================
function FixedMul(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulShl3
//
//==============================================================================
function FixedMulShl3(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulShl4
//
//==============================================================================
function FixedMulShl4(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulShl5
//
//==============================================================================
function FixedMulShl5(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulShl8
//
//==============================================================================
function FixedMulShl8(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulShl10
//
//==============================================================================
function FixedMulShl10(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulShl14
//
//==============================================================================
function FixedMulShl14(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulDiv8
//
//==============================================================================
function FixedMulDiv8(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulDiv16
//
//==============================================================================
function FixedMulDiv16(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulDiv256
//
//==============================================================================
function FixedMulDiv256(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMulEx
//
//==============================================================================
function FixedMulEx(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMul88
//
//==============================================================================
function FixedMul88(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedMul8
//
//==============================================================================
function FixedMul8(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedIntMul
//
//==============================================================================
function FixedIntMul(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// IntFixedMul
//
//==============================================================================
function IntFixedMul(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedDiv
//
//==============================================================================
function FixedDiv(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedDiv_Positive
//
//==============================================================================

//==============================================================================
//
// FixedDivLW
//
//==============================================================================
function FixedDivLW(const a, b: LongWord): LongWord;

//==============================================================================
//
// FixedDiv_fast
//
//==============================================================================
function FixedDiv_fast(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedDivEx
//
//==============================================================================
function FixedDivEx(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedDiv2
//
//==============================================================================
function FixedDiv2(const a, b: fixed_t): fixed_t; register;

//==============================================================================
//
// FixedInt
//
//==============================================================================
function FixedInt(const x: integer): integer;

//==============================================================================
//
// FloatToFixed
//
//==============================================================================
function FloatToFixed(const f: float): fixed_t;

//==============================================================================
//
// DoubleToFixed
//
//==============================================================================
function DoubleToFixed(const f: double): fixed_t;

//==============================================================================
//
// ExtendedToFixed
//
//==============================================================================
function ExtendedToFixed(const f: extended): fixed_t;

//==============================================================================
//
// FixedToFloat
//
//==============================================================================
function FixedToFloat(const x: fixed_t): float;

//==============================================================================
//
// FixedToDouble
//
//==============================================================================
function FixedToDouble(const x: fixed_t): double;

//==============================================================================
//
// FixedToExtended
//
//==============================================================================
function FixedToExtended(const x: fixed_t): extended;

//==============================================================================
//
// FixedInt_FixedMul
//
//==============================================================================
function FixedInt_FixedMul(const a, b: fixed_t): fixed_t;

//==============================================================================
//
// FixedSqrt
//
//==============================================================================
function FixedSqrt(const a: fixed_t): fixed_t;

//==============================================================================
//
// FixedInt64
//
//==============================================================================
function FixedInt64(const x: fixed64_t): integer;

//==============================================================================
//
// FixedMul64
//
//==============================================================================
function FixedMul64(const a, b: fixed64_t): fixed64_t;

//==============================================================================
//
// FloatDiv
//
//==============================================================================

//==============================================================================
//
// FloatMul
//
//==============================================================================
function FloatMul(const a, b: fixedfloat_t): fixedfloat_t;

//==============================================================================
//
// FixedMod
//
//==============================================================================
function FixedMod(const a, b: fixed_t): fixed_t;

implementation

uses
  doomtype
{$IFNDEF CPUX86}
  , DelphiDoom.MathCore.FixedMath
{$ENDIF}
  ;

//==============================================================================
//
// FixedMul
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMul(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
end;
{$ELSE}
function FixedMul(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.Mul(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulShl3
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulShl3(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 3
end;
{$ELSE}
function FixedMulShl3(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulShl3(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulShl4
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulShl4(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 4
end;
{$ELSE}
function FixedMulShl4(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulShl4(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulShl5
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulShl5(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 5
end;
{$ELSE}
function FixedMulShl5(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulShl5(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulShl8
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulShl8(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 8
end;
{$ELSE}
function FixedMulShl8(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulShl8(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulShl10
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulShl10(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 10
end;
{$ELSE}
function FixedMulShl10(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulShl10(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulShl14
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulShl14(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 14
end;
{$ELSE}
function FixedMulShl14(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulShl14(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulDiv8
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulDiv8(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 19
end;
{$ELSE}
function FixedMulDiv8(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulDiv8(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulDiv16
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulDiv16(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 20
end;
{$ELSE}
function FixedMulDiv16(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulDiv16(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulDiv256
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMulDiv256(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 24
end;
{$ELSE}
function FixedMulDiv256(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulDiv256(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMulEx
//
//==============================================================================
function FixedMulEx(const a, b: fixed_t): fixed_t;
begin
  result := Round(a / FRACUNIT * b);
end;

//==============================================================================
//
// FixedMul88
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMul88(const a, b: fixed_t): fixed_t; assembler;
asm
  sar a, 8
  sar b, 8
  imul b
  shrd eax, edx, 16
end;
{$ELSE}
function FixedMul88(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.Mul88(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedMul8
//
//==============================================================================
{$IFDEF CPUX86}
function FixedMul8(const a, b: fixed_t): fixed_t; assembler;
asm
  sar a, 8
  imul b
  shrd eax, edx, 16
end;
{$ELSE}
function FixedMul8(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.Mul8(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedIntMul
//
//==============================================================================
{$IFDEF CPUX86}
function FixedIntMul(const a, b: fixed_t): fixed_t; assembler;
asm
  sar b, FRACBITS
  imul b
  shrd eax, edx, 16
end;
{$ELSE}
function FixedIntMul(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.MulByInteger(a, b);
end;
{$ENDIF}

//==============================================================================
//
// IntFixedMul
//
//==============================================================================
{$IFDEF CPUX86}
function IntFixedMul(const a, b: fixed_t): fixed_t; assembler;
asm
  sar eax, FRACBITS
  imul b
  shrd eax, edx, 16
end;
{$ELSE}
function IntFixedMul(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.IntegerMul(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedDiv
//
//==============================================================================
function FixedDiv(const a, b: fixed_t): fixed_t;
begin
  if _SHR14(abs(a)) >= abs(b) then
  begin
    if a xor b < 0 then
      result := MININT
    else
      result := MAXINT;
  end
  else
    result := FixedDiv2(a, b);
end;

//==============================================================================
//
// FixedDivLW
//
//==============================================================================
{$IFDEF CPUX86}
function FixedDivLW(const a, b: LongWord): LongWord; assembler;
asm
  push ebx
  mov ebx, eax
  shr ebx, $0e
  cmp edx, ebx
  jbe @@retmax
  mov ebx, edx
  cmp ebx, 0
  jne @@loop1
@@retmax:
  mov eax, MAXINT
  jmp @@exit
@@loop1:
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
@@exit:
  pop ebx
end;
{$ELSE}
function FixedDivLW(const a, b: LongWord): LongWord;
begin
  result := TFixedMath.DivideUnsigned(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedDiv_fast
//
//==============================================================================
{$IFDEF CPUX86}
function FixedDiv_fast(const a, b: fixed_t): fixed_t; assembler;
asm
  mov ebx, b
  cmp ebx, 0
  jne @@loop1
  mov eax, MAXINT
  jmp @@exit
@@loop1:
  mov ebx, b
  mov eax, a
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
@@exit:
end;
{$ELSE}
function FixedDiv_fast(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.DivideFast(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedDivEx
//
//==============================================================================
function FixedDivEx(const a, b: fixed_t): fixed_t;
var
  ret: Double;
begin
  if b = 0 then
  begin
    if a < 0 then
      result := MININT
    else
      result := MAXINT;
  end
  else
  begin
    ret := (a / b) * FRACUNIT;
    if ret < MININT + 1 then
      result := MININT
    else if ret > MAXINT - 1 then
      result := MAXINT
    else
    begin
      // http://stereopsis.com/sree/fpu2006.html - Fast round double
      ret := ret + 6755399441055744.0;
      result := PInteger(@ret)^;
    end;
  end;
end;

//==============================================================================
//
// FixedDiv2
//
//==============================================================================
{$IFDEF CPUX86}
function FixedDiv2(const a, b: fixed_t): fixed_t;  register; assembler;
asm
  mov ebx, b
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
end;
{$ELSE}
function FixedDiv2(const a, b: fixed_t): fixed_t; register;
begin
  result := TFixedMath.DivideRaw(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedInt
//
//==============================================================================
{$IFDEF CPUX86}
function FixedInt(const x: integer): integer; assembler;
asm
  sar eax, FRACBITS
end;
{$ELSE}
function FixedInt(const x: integer): integer;
begin
  result := TFixedMath.ToInteger(x);
end;
{$ENDIF}

//==============================================================================
//
// FloatToFixed
//
//==============================================================================
function FloatToFixed(const f: float): fixed_t;
begin
  result := Round(f * FRACUNIT);
end;

//==============================================================================
//
// DoubleToFixed
//
//==============================================================================
function DoubleToFixed(const f: double): fixed_t;
begin
  result := Round(f * FRACUNIT);
end;

//==============================================================================
//
// ExtendedToFixed
//
//==============================================================================
function ExtendedToFixed(const f: extended): fixed_t;
begin
  result := Round(f * FRACUNIT);
end;

//==============================================================================
//
// FixedToFloat
//
//==============================================================================
function FixedToFloat(const x: fixed_t): float;
begin
  result := x / FRACUNIT;
end;

//==============================================================================
//
// FixedToDouble
//
//==============================================================================
function FixedToDouble(const x: fixed_t): double;
begin
  result := x / FRACUNIT;
end;

//==============================================================================
//
// FixedToExtended
//
//==============================================================================
function FixedToExtended(const x: fixed_t): extended;
begin
  result := x / FRACUNIT;
end;

//==============================================================================
//
// FixedInt_FixedMul
//
//==============================================================================
{$IFDEF CPUX86}
function FixedInt_FixedMul(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
  sar eax, FRACBITS
end;
{$ELSE}
function FixedInt_FixedMul(const a, b: fixed_t): fixed_t;
begin
  result := TFixedMath.IntegerOfMul(a, b);
end;
{$ENDIF}

//==============================================================================
//
// FixedSqrt
//
//==============================================================================
function FixedSqrt(const a: fixed_t): fixed_t;
begin
  Result := Round(Sqrt(a / FRACUNIT) * FRACUNIT);
end;

//==============================================================================
//
// FixedInt64
// JVAL: This is 30 times faster than using  result := x div FRACUNIT;
//
//==============================================================================
function FixedInt64(const x: fixed64_t): integer;
var
  x2: fixed64_t;
begin
  if x < 0 then
  begin
    x2 := -x;
    result := -PInteger(integer(@x2) + 2)^;
  end
  else
    result := PInteger(integer(@x) + 2)^;
end;

//==============================================================================
//
// FixedMul64
//
//==============================================================================
function FixedMul64(const a, b: fixed64_t): fixed64_t;
begin
  result := Round(a / FRACUNIT * b);
end;

//==============================================================================
//
// FloatMul
//
//==============================================================================
function FloatMul(const a, b: fixedfloat_t): fixedfloat_t;
begin
  result := a / FRACUNIT * b;
end;

// CPhipps -
// FixedMod - returns a % b, guaranteeing 0<=a<b
// (notice that the C standard for % does not guarantee this)
//
//==============================================================================
function FixedMod(const a, b: fixed_t): fixed_t;
begin
  if b and (b - 1) <> 0 then
  begin
    result := a mod b;
    if result < 0 then
      result := result + b;
  end
  else
    result := a and (b - 1);
end;

end.

