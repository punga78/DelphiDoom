{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib math - TIdMath, the scalar functions of idMath            }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\math\Math.h and          }
{  Math.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Math.Math;

{$Q-}
{$R-}

interface

const
  /// <summary>The constants of idMath, typed Single: a plain literal of Delphi is an Extended</summary>
  ID_PI: Single = 3.14159265358979323846;
  ID_TWO_PI: Single = 6.2831853071795864769;
  ID_HALF_PI: Single = 1.5707963267948966192;
  ID_ONEFOURTH_PI: Single = 0.78539816339744830962;
  ID_E: Single = 2.71828182845904523536;
  ID_SQRT_TWO: Single = 1.41421356237309504880;
  ID_SQRT_THREE: Single = 1.73205080756887729352;
  ID_SQRT_1OVER2: Single = 0.70710678118654752440;
  ID_SQRT_1OVER3: Single = 0.57735026918962576450;
  // PI / 180.0f and 180.0f / PI computed with the float value of PI, as the original does (not the exact ratios)
  ID_DEG2RAD: Single = 3.1415927410125732 / 180.0;
  ID_RAD2DEG: Single = 180.0 / 3.1415927410125732;
  ID_SEC2MS: Single = 1000.0;
  ID_MS2SEC: Single = 0.001;
  /// <summary>A huge number which should be larger than any valid number used</summary>
  ID_INFINITY: Single = 1E30;
  /// <summary>The smallest positive number such that 1.0 + FLT_EPSILON &lt;&gt; 1.0</summary>
  ID_FLT_EPSILON: Single = 1.192092896E-07;

type
  /// <summary>
  ///   The static functions of idMath. Everything is Single like the original (<c>float</c>); the
  ///   functions with the 64 suffix return Double. The "16" functions are the polynomial
  ///   approximations of the original, the others use the run time library (so they can differ from
  ///   the C library in the last bit). The tables of the fast inverse square root are built once,
  ///   when the unit starts, and never change (the original builds them in <c>idMath::Init</c>).
  ///   Not ported: the functions that are only aliases of another one.
  /// </summary>
  TIdMath = class
  private
    class var FSqrtTable: array[0..511] of Cardinal;
    class constructor Create;
    class function SeedFor(const ABits: Cardinal): Single; static;
  public
    /// <summary>Reciprocal square root (Quake style), returns a huge number when x is 0</summary>
    class function RSqrt(const AValue: Single): Single; static;
    /// <summary>Inverse square root with 32 bits precision</summary>
    class function InvSqrt(const AValue: Single): Single; static;
    class function InvSqrt16(const AValue: Single): Single; static;
    class function InvSqrt64(const AValue: Single): Double; static;
    class function Sqrt(const AValue: Single): Single; static;
    class function Sqrt16(const AValue: Single): Single; static;
    class function Sqrt64(const AValue: Single): Double; static;
    class function Sin(const AAngle: Single): Single; static;
    class function Sin16(AAngle: Single): Single; static;
    class function Sin64(const AAngle: Single): Double; static;
    class function Cos(const AAngle: Single): Single; static;
    class function Cos16(AAngle: Single): Single; static;
    class function Cos64(const AAngle: Single): Double; static;
    class procedure SinCos(const AAngle: Single; out ASin, ACos: Single); static;
    class procedure SinCos16(AAngle: Single; out ASin, ACos: Single); static;
    class procedure SinCos64(const AAngle: Single; out ASin, ACos: Double); static;
    class function Tan(const AAngle: Single): Single; static;
    class function Tan16(AAngle: Single): Single; static;
    class function Tan64(const AAngle: Single): Double; static;
    /// <summary>Arc sine; the input is clamped to [-1, 1] to avoid a silent NaN</summary>
    class function ASin(const AValue: Single): Single; static;
    class function ASin16(AValue: Single): Single; static;
    class function ASin64(const AValue: Single): Double; static;
    class function ACos(const AValue: Single): Single; static;
    class function ACos16(AValue: Single): Single; static;
    class function ACos64(const AValue: Single): Double; static;
    class function ATan(const AValue: Single): Single; overload; static;
    class function ATan16(AValue: Single): Single; overload; static;
    class function ATan64(const AValue: Single): Double; overload; static;
    class function ATan(const AY, AX: Single): Single; overload; static;
    class function ATan16(const AY, AX: Single): Single; overload; static;
    class function ATan64(const AY, AX: Single): Double; overload; static;
    class function Pow(const AX, AY: Single): Single; static;
    class function Pow16(const AX, AY: Single): Single; static;
    class function Pow64(const AX, AY: Single): Double; static;
    class function Exp(const AValue: Single): Single; static;
    class function Exp16(const AValue: Single): Single; static;
    class function Exp64(const AValue: Single): Double; static;
    class function Log(const AValue: Single): Single; static;
    class function Log16(const AValue: Single): Single; static;
    class function Log64(const AValue: Single): Double; static;
    /// <summary>Integral x raised to the power y (for y &lt; 2 the original returns x)</summary>
    class function IPow(const AX, AY: Integer): Integer; static;
    /// <summary>Integral base-2 logarithm of the exponent of the float</summary>
    class function ILog2(const AValue: Single): Integer; overload; static;
    class function ILog2(const AValue: Integer): Integer; overload; static;
    /// <summary>Minimum number of bits required to represent ceil(f)</summary>
    class function BitsForFloat(const AValue: Single): Integer; static;
    class function BitsForInteger(const AValue: Integer): Integer; static;
    /// <summary>0 if x &gt;= 0, $FFFFFFFF (-1) if x &lt;= -0.0</summary>
    class function MaskForFloatSign(const AValue: Single): Integer; static;
    class function MaskForIntegerSign(const AValue: Integer): Integer; static;
    class function FloorPowerOfTwo(const AValue: Integer): Integer; static;
    class function CeilPowerOfTwo(AValue: Integer): Integer; static;
    class function IsPowerOfTwo(const AValue: Integer): Boolean; static;
    class function BitCount(AValue: Integer): Integer; static;
    class function BitReverse(AValue: Integer): Integer; static;
    class function Abs(const AValue: Integer): Integer; overload; static;
    class function Fabs(const AValue: Single): Single; static;
    class function Floor(const AValue: Single): Single; static;
    class function Ceil(const AValue: Single): Single; static;
    /// <summary>The nearest integer: floor(f + 0.5), as the original (not a banker's rounding)</summary>
    class function Rint(const AValue: Single): Single; static;
    /// <summary>Float to int, truncated; a value that does not fit gives $80000000</summary>
    class function Ftoi(const AValue: Single): Integer; static;
    /// <summary>Float to int with the rounding of the FPU (nearest, ties to even)</summary>
    class function FtoiFast(const AValue: Single): Integer; static;
    /// <summary>Float to unsigned long (32 bits); see TIdToken for what happens outside the range</summary>
    class function Ftol(const AValue: Single): Cardinal; static;
    class function FtolFast(const AValue: Single): Cardinal; static;
    class function ClampChar(const AValue: Integer): ShortInt; static;
    class function ClampShort(const AValue: Integer): SmallInt; static;
    class function ClampInt(const AMin, AMax, AValue: Integer): Integer; static;
    class function ClampFloat(const AMin, AMax, AValue: Single): Single; static;
    class function AngleNormalize360(AAngle: Single): Single; static;
    class function AngleNormalize180(AAngle: Single): Single; static;
    class function AngleDelta(const AAngle1, AAngle2: Single): Single; static;
    class function FloatToBits(AValue: Single; AExponentBits, AMantissaBits: Integer): Integer; static;
    class function BitsToFloat(AValue, AExponentBits, AMantissaBits: Integer): Single; static;
    /// <summary>xor of the bit patterns of the floats</summary>
    class function FloatHash(const AValues: array of Single; const ACount: Integer): Integer; static;
    /// <summary>Arithmetic shift to the right (the sign is copied), the <c>&gt;&gt;</c> of C on a signed int; Delphi's <c>shr</c> is logical</summary>
    // not inline: an inlined body is never measured by the coverage of the tests
    class function Sar(const AValue, AShift: Integer): Integer; static;
    /// <summary>The bit pattern of a float (the original reads it through a pointer cast)</summary>
    class function SingleToBits(const AValue: Single): Integer; static;
    class function BitsToSingle(const ABits: Integer): Single; static;
  end;

implementation

uses
  System.SysUtils, System.Math;

const
  EXP_POS = 23;
  EXP_BIAS = 127;
  LOOKUP_BITS = 8;
  LOOKUP_POS = EXP_POS - LOOKUP_BITS;
  SEED_POS = EXP_POS - 8;
  SQRT_TABLE_SIZE = 2 shl LOOKUP_BITS;
  LOOKUP_MASK = SQRT_TABLE_SIZE - 1;
  IEEE_FLT_MANTISSA_BITS = 23;
  IEEE_FLT_EXPONENT_BITS = 8;
  IEEE_FLT_EXPONENT_BIAS = 127;
  IEEE_FLT_SIGN_BIT = 31;

  // float constants of the original: typed, so that they keep the precision of a float
  F_HALF: Single = 0.5;
  F_ONE_AND_HALF: Single = 1.5;
  F_ONE: Single = 1.0;
  F_ZERO: Single = 0.0;
  F_SQRT2: Single = 1.4142135623730950488;
  F_INV_LOG2: Single = 1.44269504088896340;
  F_LN2: Single = 0.693147180559945;

  // the coefficients of the polynomial approximations (all floats in the original)
  C_SIN_0: Single = -2.39E-08;
  C_SIN_1: Single = 2.7526E-06;
  C_SIN_2: Single = 1.98409E-04;
  C_SIN_3: Single = 8.3333315E-03;
  C_SIN_4: Single = 1.666666664E-01;
  C_COS_0: Single = -2.605E-07;
  C_COS_1: Single = 2.47609E-05;
  C_COS_2: Single = 1.3888397E-03;
  C_COS_3: Single = 4.16666418E-02;
  C_COS_4: Single = 4.999999963E-01;
  C_TAN_0: Single = 9.5168091E-03;
  C_TAN_1: Single = 2.900525E-03;
  C_TAN_2: Single = 2.45650893E-02;
  C_TAN_3: Single = 5.33740603E-02;
  C_TAN_4: Single = 1.333923995E-01;
  C_TAN_5: Single = 3.333314036E-01;
  C_ASIN_0: Single = -0.0187293;
  C_ASIN_1: Single = 0.0742610;
  C_ASIN_2: Single = 0.2121144;
  C_ASIN_3: Single = 1.5707288;
  C_ATAN_0: Single = 0.0028662257;
  C_ATAN_1: Single = 0.0161657367;
  C_ATAN_2: Single = 0.0429096138;
  C_ATAN_3: Single = 0.0752896400;
  C_ATAN_4: Single = 0.1065626393;
  C_ATAN_5: Single = 0.1420889944;
  C_ATAN_6: Single = 0.1999355085;
  C_ATAN_7: Single = 0.3333314528;
  C_EXP_0: Single = 7.2152891511493;
  C_EXP_1: Single = 0.0576900723731;
  C_EXP_2: Single = 20.8189237930062;
  C_LOG_0: Single = 2.000000000046727;
  C_LOG_1: Single = 0.666666635059382;
  C_LOG_2: Single = 0.4000059794795;
  C_LOG_3: Single = 0.28525381498;
  C_LOG_4: Single = 0.2376245609;

// the float overload of sqrt of the C++ library: the result is rounded to a float
function SqrtF(const AValue: Single): Single;
var
  LRounded: Single;
begin
  // a Single result of a function stays in the FPU unrounded: the local variable rounds it to a float
  LRounded := System.Sqrt(AValue);
  Result := LRounded;
end;

{ TIdMath }

class constructor TIdMath.Create;
var
  LIndex: Integer;
  LInput, LOutput: Cardinal;
  LValue: Single;
begin
  for LIndex := 0 to SQRT_TABLE_SIZE - 1 do
  begin
    LInput := Cardinal(((EXP_BIAS - 1) shl EXP_POS) or (LIndex shl LOOKUP_POS));
    LValue := PSingle(@LInput)^;
    LValue := 1.0 / System.Sqrt(Double(LValue));
    LOutput := PCardinal(@LValue)^;
    FSqrtTable[LIndex] := Cardinal(((LOutput + (1 shl (SEED_POS - 2))) shr SEED_POS) and $FF) shl SEED_POS;
  end;
  FSqrtTable[SQRT_TABLE_SIZE div 2] := Cardinal($FF) shl SEED_POS;
end;

class function TIdMath.Sar(const AValue, AShift: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr AShift
  else
    Result := not ((not AValue) shr AShift);
end;

class function TIdMath.SingleToBits(const AValue: Single): Integer;
begin
  Result := PInteger(@AValue)^;
end;

class function TIdMath.BitsToSingle(const ABits: Integer): Single;
begin
  Result := PSingle(@ABits)^;
end;

class function TIdMath.SeedFor(const ABits: Cardinal): Single;
var
  LSeed: Cardinal;
begin
  LSeed := Cardinal(((((3 * EXP_BIAS - 1) - Integer((ABits shr EXP_POS) and $FF)) shr 1) shl EXP_POS)) or
    FSqrtTable[(ABits shr (EXP_POS - LOOKUP_BITS)) and LOOKUP_MASK];
  Result := PSingle(@LSeed)^;
end;

class function TIdMath.RSqrt(const AValue: Single): Single;
var
  LHalf, LRoot: Single;
  LBits: Integer;
begin
  LHalf := AValue * F_HALF;
  LBits := PInteger(@AValue)^;
  LBits := $5F3759DF - Sar(LBits, 1);
  LRoot := PSingle(@LBits)^;
  Result := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
end;

class function TIdMath.InvSqrt16(const AValue: Single): Single;
var
  LHalf, LRoot: Double;
begin
  LHalf := AValue * F_HALF;
  LRoot := SeedFor(PCardinal(@AValue)^);
  LRoot := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
  Result := LRoot;
end;

class function TIdMath.InvSqrt(const AValue: Single): Single;
var
  LHalf, LRoot: Double;
begin
  LHalf := AValue * F_HALF;
  LRoot := SeedFor(PCardinal(@AValue)^);
  LRoot := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
  LRoot := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
  Result := LRoot;
end;

class function TIdMath.InvSqrt64(const AValue: Single): Double;
var
  LHalf, LRoot: Double;
begin
  LHalf := AValue * F_HALF;
  LRoot := SeedFor(PCardinal(@AValue)^);
  LRoot := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
  LRoot := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
  LRoot := LRoot * (F_ONE_AND_HALF - LRoot * LRoot * LHalf);
  Result := LRoot;
end;

class function TIdMath.Sqrt16(const AValue: Single): Single;
begin
  Result := AValue * InvSqrt16(AValue);
end;

class function TIdMath.Sqrt(const AValue: Single): Single;
begin
  Result := AValue * InvSqrt(AValue);
end;

class function TIdMath.Sqrt64(const AValue: Single): Double;
begin
  Result := AValue * InvSqrt64(AValue);
end;

class function TIdMath.Sin(const AAngle: Single): Single;
begin
  Result := System.Sin(AAngle);
end;

class function TIdMath.Sin16(AAngle: Single): Single;
var
  LS: Single;
begin
  if (AAngle < 0.0) or (AAngle >= ID_TWO_PI) then
    AAngle := AAngle - Floor(AAngle / ID_TWO_PI) * ID_TWO_PI;
  if AAngle < ID_PI then
  begin
    if AAngle > ID_HALF_PI then
      AAngle := ID_PI - AAngle;
  end
  else
  begin
    if AAngle > ID_PI + ID_HALF_PI then
      AAngle := AAngle - ID_TWO_PI
    else
      AAngle := ID_PI - AAngle;
  end;
  LS := AAngle * AAngle;
  Result := AAngle * (((((C_SIN_0 * LS + C_SIN_1) * LS - C_SIN_2) * LS + C_SIN_3) * LS - C_SIN_4) * LS + F_ONE);
end;

class function TIdMath.Sin64(const AAngle: Single): Double;
begin
  Result := System.Sin(Double(AAngle));
end;

class function TIdMath.Cos(const AAngle: Single): Single;
begin
  Result := System.Cos(AAngle);
end;

class function TIdMath.Cos16(AAngle: Single): Single;
var
  LS, LD: Single;
begin
  if (AAngle < 0.0) or (AAngle >= ID_TWO_PI) then
    AAngle := AAngle - Floor(AAngle / ID_TWO_PI) * ID_TWO_PI;
  if AAngle < ID_PI then
  begin
    if AAngle > ID_HALF_PI then
    begin
      AAngle := ID_PI - AAngle;
      LD := -1.0;
    end
    else
      LD := 1.0;
  end
  else
  begin
    if AAngle > ID_PI + ID_HALF_PI then
    begin
      AAngle := AAngle - ID_TWO_PI;
      LD := 1.0;
    end
    else
    begin
      AAngle := ID_PI - AAngle;
      LD := -1.0;
    end;
  end;
  LS := AAngle * AAngle;
  Result := LD * (((((C_COS_0 * LS + C_COS_1) * LS - C_COS_2) * LS + C_COS_3) * LS - C_COS_4) * LS + F_ONE);
end;

class function TIdMath.Cos64(const AAngle: Single): Double;
begin
  Result := System.Cos(Double(AAngle));
end;

class procedure TIdMath.SinCos(const AAngle: Single; out ASin, ACos: Single);
var
  LSin, LCos: Extended;
begin
  System.Math.SinCos(Extended(AAngle), LSin, LCos);
  ASin := LSin;
  ACos := LCos;
end;

class procedure TIdMath.SinCos16(AAngle: Single; out ASin, ACos: Single);
var
  LT, LD: Single;
begin
  if (AAngle < 0.0) or (AAngle >= ID_TWO_PI) then
    AAngle := AAngle - Floor(AAngle / ID_TWO_PI) * ID_TWO_PI;
  if AAngle < ID_PI then
  begin
    if AAngle > ID_HALF_PI then
    begin
      AAngle := ID_PI - AAngle;
      LD := -1.0;
    end
    else
      LD := 1.0;
  end
  else
  begin
    if AAngle > ID_PI + ID_HALF_PI then
    begin
      AAngle := AAngle - ID_TWO_PI;
      LD := 1.0;
    end
    else
    begin
      AAngle := ID_PI - AAngle;
      LD := -1.0;
    end;
  end;
  LT := AAngle * AAngle;
  ASin := AAngle * (((((C_SIN_0 * LT + C_SIN_1) * LT - C_SIN_2) * LT + C_SIN_3) * LT - C_SIN_4) * LT + F_ONE);
  ACos := LD * (((((C_COS_0 * LT + C_COS_1) * LT - C_COS_2) * LT + C_COS_3) * LT - C_COS_4) * LT + F_ONE);
end;

class procedure TIdMath.SinCos64(const AAngle: Single; out ASin, ACos: Double);
var
  LSin, LCos: Extended;
begin
  System.Math.SinCos(Extended(AAngle), LSin, LCos);
  ASin := LSin;
  ACos := LCos;
end;

class function TIdMath.Tan(const AAngle: Single): Single;
begin
  Result := System.Math.Tan(AAngle);
end;

class function TIdMath.Tan16(AAngle: Single): Single;
var
  LS: Single;
  LReciprocal: Boolean;
begin
  if (AAngle < 0.0) or (AAngle >= ID_PI) then
    AAngle := AAngle - Floor(AAngle / ID_PI) * ID_PI;
  if AAngle < ID_HALF_PI then
  begin
    if AAngle > ID_ONEFOURTH_PI then
    begin
      AAngle := ID_HALF_PI - AAngle;
      LReciprocal := True;
    end
    else
      LReciprocal := False;
  end
  else
  begin
    if AAngle > ID_HALF_PI + ID_ONEFOURTH_PI then
    begin
      AAngle := AAngle - ID_PI;
      LReciprocal := False;
    end
    else
    begin
      AAngle := ID_HALF_PI - AAngle;
      LReciprocal := True;
    end;
  end;
  LS := AAngle * AAngle;
  LS := AAngle * ((((((C_TAN_0 * LS + C_TAN_1) * LS + C_TAN_2) * LS + C_TAN_3) * LS + C_TAN_4) * LS + C_TAN_5) * LS + F_ONE);
  if LReciprocal then
    Result := F_ONE / LS
  else
    Result := LS;
end;

class function TIdMath.Tan64(const AAngle: Single): Double;
begin
  Result := System.Math.Tan(Double(AAngle));
end;

class function TIdMath.ASin(const AValue: Single): Single;
begin
  if AValue <= -1.0 then
    Exit(-ID_HALF_PI);
  if AValue >= 1.0 then
    Exit(ID_HALF_PI);
  Result := System.Math.ArcSin(AValue);
end;

class function TIdMath.ASin16(AValue: Single): Single;
var
  LPolynomial: Single;
begin
  if (PCardinal(@AValue)^ shr 31) <> 0 then
  begin
    if AValue <= -1.0 then
      Exit(-ID_HALF_PI);
    AValue := System.Abs(AValue);
    // the polynomial is a float before the product: the compiler of the original spills it across the call of sqrt
    LPolynomial := ((C_ASIN_0 * AValue + C_ASIN_1) * AValue - C_ASIN_2) * AValue + C_ASIN_3;
    Result := LPolynomial * SqrtF(F_ONE - AValue) - ID_HALF_PI;
  end
  else
  begin
    if AValue >= 1.0 then
      Exit(ID_HALF_PI);
    LPolynomial := ((C_ASIN_0 * AValue + C_ASIN_1) * AValue - C_ASIN_2) * AValue + C_ASIN_3;
    Result := ID_HALF_PI - LPolynomial * SqrtF(F_ONE - AValue);
  end;
end;

class function TIdMath.ASin64(const AValue: Single): Double;
begin
  if AValue <= -1.0 then
    Exit(-ID_HALF_PI);
  if AValue >= 1.0 then
    Exit(ID_HALF_PI);
  Result := System.Math.ArcSin(Double(AValue));
end;

class function TIdMath.ACos(const AValue: Single): Single;
begin
  if AValue <= -1.0 then
    Exit(ID_PI);
  if AValue >= 1.0 then
    Exit(0.0);
  Result := System.Math.ArcCos(AValue);
end;

class function TIdMath.ACos16(AValue: Single): Single;
var
  LPolynomial: Single;
begin
  if (PCardinal(@AValue)^ shr 31) <> 0 then
  begin
    if AValue <= -1.0 then
      Exit(ID_PI);
    AValue := System.Abs(AValue);
    LPolynomial := ((C_ASIN_0 * AValue + C_ASIN_1) * AValue - C_ASIN_2) * AValue + C_ASIN_3;
    Result := ID_PI - LPolynomial * SqrtF(F_ONE - AValue);
  end
  else
  begin
    if AValue >= 1.0 then
      Exit(0.0);
    LPolynomial := ((C_ASIN_0 * AValue + C_ASIN_1) * AValue - C_ASIN_2) * AValue + C_ASIN_3;
    Result := LPolynomial * SqrtF(F_ONE - AValue);
  end;
end;

class function TIdMath.ACos64(const AValue: Single): Double;
begin
  if AValue <= -1.0 then
    Exit(ID_PI);
  if AValue >= 1.0 then
    Exit(0.0);
  Result := System.Math.ArcCos(Double(AValue));
end;

class function TIdMath.ATan(const AValue: Single): Single;
begin
  Result := System.ArcTan(AValue);
end;

class function TIdMath.ATan16(AValue: Single): Single;
var
  LS: Single;
begin
  if System.Abs(AValue) > 1.0 then
  begin
    AValue := F_ONE / AValue;
    LS := AValue * AValue;
    LS := -((((((((((C_ATAN_0 * LS - C_ATAN_1) * LS + C_ATAN_2) * LS - C_ATAN_3) * LS + C_ATAN_4) * LS - C_ATAN_5) *
      LS + C_ATAN_6) * LS - C_ATAN_7) * LS) + F_ONE) * AValue);
    if (PCardinal(@AValue)^ shr 31) <> 0 then
      Result := LS - ID_HALF_PI
    else
      Result := LS + ID_HALF_PI;
  end
  else
  begin
    LS := AValue * AValue;
    Result := ((((((((C_ATAN_0 * LS - C_ATAN_1) * LS + C_ATAN_2) * LS - C_ATAN_3) * LS + C_ATAN_4) * LS - C_ATAN_5) *
      LS + C_ATAN_6) * LS - C_ATAN_7) * LS + F_ONE) * AValue;
  end;
end;

class function TIdMath.ATan64(const AValue: Single): Double;
begin
  Result := System.ArcTan(Double(AValue));
end;

class function TIdMath.ATan(const AY, AX: Single): Single;
begin
  Result := System.Math.ArcTan2(AY, AX);
end;

class function TIdMath.ATan16(const AY, AX: Single): Single;
var
  LA, LS: Single;
begin
  if System.Abs(AY) > System.Abs(AX) then
  begin
    LA := AX / AY;
    LS := LA * LA;
    LS := -((((((((((C_ATAN_0 * LS - C_ATAN_1) * LS + C_ATAN_2) * LS - C_ATAN_3) * LS + C_ATAN_4) * LS - C_ATAN_5) *
      LS + C_ATAN_6) * LS - C_ATAN_7) * LS) + F_ONE) * LA);
    if (PCardinal(@LA)^ shr 31) <> 0 then
      Result := LS - ID_HALF_PI
    else
      Result := LS + ID_HALF_PI;
  end
  else
  begin
    LA := AY / AX;
    LS := LA * LA;
    Result := ((((((((C_ATAN_0 * LS - C_ATAN_1) * LS + C_ATAN_2) * LS - C_ATAN_3) * LS + C_ATAN_4) * LS - C_ATAN_5) *
      LS + C_ATAN_6) * LS - C_ATAN_7) * LS + F_ONE) * LA;
  end;
end;

class function TIdMath.ATan64(const AY, AX: Single): Double;
begin
  Result := System.Math.ArcTan2(Double(AY), Double(AX));
end;

class function TIdMath.Pow(const AX, AY: Single): Single;
begin
  Result := System.Math.Power(AX, AY);
end;

class function TIdMath.Pow16(const AX, AY: Single): Single;
begin
  Result := Exp16(AY * Log16(AX));
end;

class function TIdMath.Pow64(const AX, AY: Single): Double;
begin
  Result := System.Math.Power(Double(AX), Double(AY));
end;

class function TIdMath.Exp(const AValue: Single): Single;
begin
  Result := System.Exp(AValue);
end;

class function TIdMath.Exp16(const AValue: Single): Single;
var
  LI, LS, LE, LM, LExponent: Integer;
  LX, LX2, LY, LP, LQ: Single;
begin
  LX := AValue * F_INV_LOG2;
  LI := PInteger(@LX)^;
  LS := Sar(LI, IEEE_FLT_SIGN_BIT);
  LE := ((LI shr IEEE_FLT_MANTISSA_BITS) and ((1 shl IEEE_FLT_EXPONENT_BITS) - 1)) - IEEE_FLT_EXPONENT_BIAS;
  LM := (LI and ((1 shl IEEE_FLT_MANTISSA_BITS) - 1)) or (1 shl IEEE_FLT_MANTISSA_BITS);
  LI := ((LM shr (IEEE_FLT_MANTISSA_BITS - LE)) and (not Sar(LE, 31))) xor LS;
  LExponent := (LI + IEEE_FLT_EXPONENT_BIAS) shl IEEE_FLT_MANTISSA_BITS;
  LY := PSingle(@LExponent)^;
  LX := LX - LI;
  if LX >= F_HALF then
  begin
    LX := LX - F_HALF;
    LY := LY * F_SQRT2;
  end;
  LX2 := LX * LX;
  LP := LX * (C_EXP_0 + LX2 * C_EXP_1);
  LQ := C_EXP_2 + LX2;
  LX := LY * (LQ + LP) / (LQ - LP);
  Result := LX;
end;

class function TIdMath.Exp64(const AValue: Single): Double;
begin
  Result := System.Exp(Double(AValue));
end;

class function TIdMath.Log(const AValue: Single): Single;
begin
  Result := System.Ln(AValue);
end;

class function TIdMath.Log16(const AValue: Single): Single;
var
  LI, LExponent: Integer;
  LF, LY, LY2: Single;
begin
  LF := AValue;
  LI := PInteger(@LF)^;
  LExponent := ((LI shr IEEE_FLT_MANTISSA_BITS) and ((1 shl IEEE_FLT_EXPONENT_BITS) - 1)) - IEEE_FLT_EXPONENT_BIAS;
  Dec(LI, (LExponent + 1) shl IEEE_FLT_MANTISSA_BITS);
  LY := PSingle(@LI)^;
  LY := LY * F_SQRT2;
  LY := (LY - F_ONE) / (LY + F_ONE);
  LY2 := LY * LY;
  LY := LY * (C_LOG_0 + LY2 * (C_LOG_1 + LY2 * (C_LOG_2 + LY2 * (C_LOG_3 + LY2 * C_LOG_4))));
  LY := LY + F_LN2 * (LExponent + F_HALF);
  Result := LY;
end;

class function TIdMath.Log64(const AValue: Single): Double;
begin
  Result := System.Ln(Double(AValue));
end;

class function TIdMath.IPow(const AX, AY: Integer): Integer;
var
  LY: Integer;
begin
  Result := AX;
  LY := AY;
  while LY > 1 do
  begin
    Result := Result * AX;
    Dec(LY);
  end;
end;

class function TIdMath.ILog2(const AValue: Single): Integer;
begin
  Result := ((PInteger(@AValue)^ shr IEEE_FLT_MANTISSA_BITS) and ((1 shl IEEE_FLT_EXPONENT_BITS) - 1)) -
    IEEE_FLT_EXPONENT_BIAS;
end;

class function TIdMath.ILog2(const AValue: Integer): Integer;
begin
  Result := ILog2(Single(AValue));
end;

class function TIdMath.BitsForFloat(const AValue: Single): Integer;
begin
  Result := ILog2(AValue) + 1;
end;

class function TIdMath.BitsForInteger(const AValue: Integer): Integer;
begin
  Result := ILog2(Single(AValue)) + 1;
end;

class function TIdMath.MaskForFloatSign(const AValue: Single): Integer;
begin
  Result := Sar(PInteger(@AValue)^, 31);
end;

class function TIdMath.MaskForIntegerSign(const AValue: Integer): Integer;
begin
  Result := Sar(AValue, 31);
end;

class function TIdMath.FloorPowerOfTwo(const AValue: Integer): Integer;
begin
  Result := Sar(CeilPowerOfTwo(AValue), 1);
end;

class function TIdMath.CeilPowerOfTwo(AValue: Integer): Integer;
begin
  Dec(AValue);
  AValue := AValue or Sar(AValue, 1);
  AValue := AValue or Sar(AValue, 2);
  AValue := AValue or Sar(AValue, 4);
  AValue := AValue or Sar(AValue, 8);
  AValue := AValue or Sar(AValue, 16);
  Inc(AValue);
  Result := AValue;
end;

class function TIdMath.IsPowerOfTwo(const AValue: Integer): Boolean;
begin
  Result := ((AValue and (AValue - 1)) = 0) and (AValue > 0);
end;

class function TIdMath.BitCount(AValue: Integer): Integer;
begin
  AValue := AValue - ((AValue shr 1) and $55555555);
  AValue := ((AValue shr 2) and $33333333) + (AValue and $33333333);
  AValue := ((AValue shr 4) + AValue) and $0F0F0F0F;
  AValue := AValue + (AValue shr 8);
  Result := (AValue + (AValue shr 16)) and $0000003F;
end;

class function TIdMath.BitReverse(AValue: Integer): Integer;
begin
  AValue := ((AValue shr 1) and $55555555) or ((AValue and $55555555) shl 1);
  AValue := ((AValue shr 2) and $33333333) or ((AValue and $33333333) shl 2);
  AValue := ((AValue shr 4) and $0F0F0F0F) or ((AValue and $0F0F0F0F) shl 4);
  AValue := ((AValue shr 8) and $00FF00FF) or ((AValue and $00FF00FF) shl 8);
  Result := Sar(AValue, 16) or (AValue shl 16);
end;

class function TIdMath.Abs(const AValue: Integer): Integer;
var
  LSign: Integer;
begin
  LSign := Sar(AValue, 31);
  Result := (AValue xor LSign) - LSign;
end;

class function TIdMath.Fabs(const AValue: Single): Single;
var
  LBits: Integer;
begin
  LBits := PInteger(@AValue)^ and $7FFFFFFF;
  Result := PSingle(@LBits)^;
end;

class function TIdMath.Floor(const AValue: Single): Single;
begin
  Result := System.Int(AValue);
  if (AValue < 0) and (Result <> AValue) then
    Result := Result - 1;
end;

class function TIdMath.Ceil(const AValue: Single): Single;
begin
  Result := System.Int(AValue);
  if (AValue > 0) and (Result <> AValue) then
    Result := Result + 1
  else if (AValue < 0) and (Result = 0) then
    // ceil(-0.5) is -0 (the C function and the 32 bit Int); the 64 bit Int gives +0
    Result := -System.Abs(Result);
end;

class function TIdMath.Rint(const AValue: Single): Single;
var
  LSum: Single;
begin
  LSum := AValue + F_HALF;
  Result := Floor(LSum);
end;

class function TIdMath.Ftoi(const AValue: Single): Integer;
begin
  if (AValue <> AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Integer($80000000)
  else
    Result := Trunc(AValue);
end;

class function TIdMath.FtoiFast(const AValue: Single): Integer;
begin
  if (AValue <> AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Integer($80000000)
  else
    Result := Round(AValue);
end;

class function TIdMath.Ftol(const AValue: Single): Cardinal;
var
  LRest: Single;
begin
  if AValue <> AValue then
    Exit($80000000);
  if AValue < 2147483648.0 then
  begin
    if AValue < -2147483648.0 then
      Exit($80000000);
    Exit(Cardinal(Trunc(AValue)));
  end;
  LRest := AValue - 2147483648.0;
  if LRest >= 2147483648.0 then
    Exit(0);
  Result := Cardinal(Trunc(LRest)) xor $80000000;
end;

class function TIdMath.FtolFast(const AValue: Single): Cardinal;
begin
  Result := Cardinal(FtoiFast(AValue));
end;

class function TIdMath.ClampChar(const AValue: Integer): ShortInt;
begin
  if AValue < -128 then
    Exit(-128);
  if AValue > 127 then
    Exit(127);
  Result := AValue;
end;

class function TIdMath.ClampShort(const AValue: Integer): SmallInt;
begin
  if AValue < -32768 then
    Exit(-32768);
  if AValue > 32767 then
    Exit(32767);
  Result := AValue;
end;

class function TIdMath.ClampInt(const AMin, AMax, AValue: Integer): Integer;
begin
  if AValue < AMin then
    Exit(AMin);
  if AValue > AMax then
    Exit(AMax);
  Result := AValue;
end;

class function TIdMath.ClampFloat(const AMin, AMax, AValue: Single): Single;
begin
  if AValue < AMin then
    Exit(AMin);
  if AValue > AMax then
    Exit(AMax);
  Result := AValue;
end;

class function TIdMath.AngleNormalize360(AAngle: Single): Single;
var
  LQuotient: Single;
  LFloor: Double;
begin
  if (AAngle >= 360.0) or (AAngle < 0.0) then
  begin
    // the quotient is a float (the compiler rounds it before the call of floor( double ))
    LQuotient := AAngle / 360.0;
    LFloor := System.Int(LQuotient);
    if (LQuotient < 0) and (LFloor <> LQuotient) then
      LFloor := LFloor - 1;
    AAngle := AAngle - LFloor * 360.0;
  end;
  Result := AAngle;
end;

class function TIdMath.AngleNormalize180(AAngle: Single): Single;
begin
  AAngle := AngleNormalize360(AAngle);
  if AAngle > 180.0 then
    AAngle := AAngle - 360.0;
  Result := AAngle;
end;

class function TIdMath.AngleDelta(const AAngle1, AAngle2: Single): Single;
begin
  Result := AngleNormalize180(AAngle1 - AAngle2);
end;

class function TIdMath.FloatToBits(AValue: Single; AExponentBits, AMantissaBits: Integer): Integer;
var
  LI, LSign, LExponent, LMantissa, LValue, LMaxBits, LMinBits: Integer;
  LMax, LMin: Single;
begin
  LMaxBits := (((1 shl (AExponentBits - 1)) - 1) shl AMantissaBits) or ((1 shl AMantissaBits) - 1);
  LMinBits := (((1 shl AExponentBits) - 2) shl AMantissaBits) or 1;
  LMax := BitsToFloat(LMaxBits, AExponentBits, AMantissaBits);
  LMin := BitsToFloat(LMinBits, AExponentBits, AMantissaBits);
  if AValue >= 0.0 then
  begin
    if AValue >= LMax then
      Exit(LMaxBits)
    else if AValue <= LMin then
      Exit(LMinBits);
  end
  else
  begin
    if AValue <= -LMax then
      Exit(LMaxBits or (1 shl (AExponentBits + AMantissaBits)))
    else if AValue >= -LMin then
      Exit(LMinBits or (1 shl (AExponentBits + AMantissaBits)));
  end;
  Dec(AExponentBits);
  LI := PInteger(@AValue)^;
  LSign := (LI shr IEEE_FLT_SIGN_BIT) and 1;
  LExponent := ((LI shr IEEE_FLT_MANTISSA_BITS) and ((1 shl IEEE_FLT_EXPONENT_BITS) - 1)) - IEEE_FLT_EXPONENT_BIAS;
  LMantissa := LI and ((1 shl IEEE_FLT_MANTISSA_BITS) - 1);
  LValue := LSign shl (1 + AExponentBits + AMantissaBits);
  // The sign bit of the exponent as an Integer: mixing Cardinal and Integer
  // would widen the whole expression to Int64 (same low 32 bits)
  LValue := LValue or (((Integer(Cardinal(LExponent) shr 31) shl AExponentBits) or
    (System.Abs(LExponent) and ((1 shl AExponentBits) - 1))) shl AMantissaBits);
  LValue := LValue or (LMantissa shr (IEEE_FLT_MANTISSA_BITS - AMantissaBits));
  Result := LValue;
end;

class function TIdMath.BitsToFloat(AValue, AExponentBits, AMantissaBits: Integer): Single;
const
  EXPONENT_SIGN: array[0..1] of Integer = (1, -1);
var
  LSign, LExponent, LMantissa, LValue: Integer;
begin
  Dec(AExponentBits);
  LSign := Sar(AValue, 1 + AExponentBits + AMantissaBits);
  LExponent := ((AValue shr AMantissaBits) and ((1 shl AExponentBits) - 1)) *
    EXPONENT_SIGN[(AValue shr (AExponentBits + AMantissaBits)) and 1];
  LMantissa := (AValue and ((1 shl AMantissaBits) - 1)) shl (IEEE_FLT_MANTISSA_BITS - AMantissaBits);
  LValue := (LSign shl IEEE_FLT_SIGN_BIT) or ((LExponent + IEEE_FLT_EXPONENT_BIAS) shl IEEE_FLT_MANTISSA_BITS) or LMantissa;
  Result := PSingle(@LValue)^;
end;

class function TIdMath.FloatHash(const AValues: array of Single; const ACount: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to ACount - 1 do
    Result := Result xor PInteger(@AValues[LIndex])^;
end;

end.
