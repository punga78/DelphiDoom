{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the trigonometric tables and the angles     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Trigonometry;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   The tables of sine, cosine, tangent and arc tangent of the old tables unit and the
  ///   functions of the angles (slope, fixed point degrees). The tables are constants: the
  ///   cosine is the sine moved by a quarter of a turn (the old finecosine / fixedcosine). The
  ///   accessors do not check the index (they are meant for the hot paths): the caller masks it
  ///   with FINEMASK or checks the range.
  /// </summary>
  TTrigonometry = class
  public
    /// <summary>Sine of a fine angle (0..8191, up to 10239 for the cosine table)</summary>
    class function FineSine(const AIndex: Integer): TFixed; static;
    /// <summary>Cosine of a fine angle (0..8191)</summary>
    class function FineCosine(const AIndex: Integer): TFixed; static;
    /// <summary>Tangent of a fine angle (0..4096, from -90 to +90 degrees)</summary>
    class function FineTangent(const AIndex: Integer): TFixed; static;
    /// <summary>Angle of a slope (0..2048)</summary>
    class function TanToAngle(const AIndex: Integer): TAngle; static;
    /// <summary>Angle of a slope in 65536 steps (0..65536)</summary>
    class function TanToAngleEx(const AIndex: Integer): TAngle; static;
    /// <summary>Sine of the angle in 65536 steps (0..65535)</summary>
    class function FixedSine(const AIndex: Integer): TFixed; static;
    /// <summary>Cosine of the angle in 65536 steps (0..65535)</summary>
    class function FixedCosine(const AIndex: Integer): TFixed; static;

    /// <summary>The index of the fine tables for an angle (angle shr 19)</summary>
    class function AngleToFine(const AAngle: TAngle): Integer; static; inline;
    /// <summary>The slope (0..2048) of a / b, SLOPERANGE if the ratio is bigger (the old SlopeDiv)</summary>
    class function SlopeDiv(const ANum, ADen: Integer): Cardinal; static;
    /// <summary>As SlopeDiv with 65536 steps (the old SlopeDivEx)</summary>
    class function SlopeDivEx(const ANum, ADen: Integer): Cardinal; static;
    /// <summary>The angle for a number of degrees in fixed point (the old FixedToAngle)</summary>
    class function FixedToAngle(const AValue: TFixed): TAngle; static;
    /// <summary>The degrees in fixed point of an angle (the old AngleToFixed)</summary>
    class function AngleToFixed(const AAngle: TAngle): TFixed; static;
    /// <summary>The slope of an angle, clamped to +-90 degrees (the old AngleToSlope)</summary>
    class function AngleToSlope(const AAngle: Integer): TFixed; static;
    /// <summary>The slope of a number of degrees in fixed point (the old DegToSlope)</summary>
    class function DegreesToSlope(const AValue: TFixed): TFixed; static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.TableFineSine,
  DelphiDoom.MathCore.TableFineTangent, DelphiDoom.MathCore.TableTanToAngle,
  DelphiDoom.MathCore.TableTanToAngleEx, DelphiDoom.MathCore.TableFixedSine;

{ TTrigonometry }

class function TTrigonometry.FineSine(const AIndex: Integer): TFixed;
begin
  Result := FINE_SINE_TABLE[AIndex];
end;

class function TTrigonometry.FineCosine(const AIndex: Integer): TFixed;
begin
  Result := FINE_SINE_TABLE[AIndex + FINEANGLES div 4];
end;

class function TTrigonometry.FineTangent(const AIndex: Integer): TFixed;
begin
  Result := FINE_TANGENT_TABLE[AIndex];
end;

class function TTrigonometry.TanToAngle(const AIndex: Integer): TAngle;
begin
  Result := TAN_TO_ANGLE_TABLE[AIndex];
end;

class function TTrigonometry.TanToAngleEx(const AIndex: Integer): TAngle;
begin
  Result := TAN_TO_ANGLE_EX_TABLE[AIndex];
end;

class function TTrigonometry.FixedSine(const AIndex: Integer): TFixed;
begin
  Result := FIXED_SINE_TABLE[AIndex];
end;

class function TTrigonometry.FixedCosine(const AIndex: Integer): TFixed;
begin
  Result := FIXED_SINE_TABLE[AIndex + FIXEDANGLES div 4];
end;

class function TTrigonometry.AngleToFine(const AAngle: TAngle): Integer;
begin
  Result := AAngle shr ANGLETOFINESHIFT;
end;

class function TTrigonometry.SlopeDiv(const ANum, ADen: Integer): Cardinal;
begin
  if ADen < 512 then
    Result := SLOPERANGE
  else
  begin
    // a negative quotient becomes a huge number and is clamped, as it was
    Result := Cardinal((ANum * 8) div TFixedMath.ShiftRight(ADen, 8));
    if Result >= SLOPERANGE then
      Result := SLOPERANGE;
  end;
end;

class function TTrigonometry.SlopeDivEx(const ANum, ADen: Integer): Cardinal;
begin
  if ADen < 32 then
    Result := SLOPERANGE_EX
  else
  begin
    // the old code was Round(num / (den / 65536)): the same rounding, halves to even
    Result := Cardinal(TFixedMath.RoundDivide(Int64(ANum) * FIXED_ONE, ADen));
    if Result >= SLOPERANGE_EX then
      Result := SLOPERANGE_EX;
  end;
end;

class function TTrigonometry.FixedToAngle(const AValue: TFixed): TAngle;
begin
  // the old code was trunc((a / 65536) * ANG1); the product fits the 64 bit mantissa of the FPU
  Result := Cardinal((Int64(AValue) * ANG1) div FIXED_ONE);
end;

class function TTrigonometry.AngleToFixed(const AAngle: TAngle): TFixed;
begin
  // the old code was trunc((a / ANG1) * 65536)
  Result := Integer((Int64(AAngle) * FIXED_ONE) div ANG1);
end;

class function TTrigonometry.AngleToSlope(const AAngle: Integer): TFixed;
begin
  if AAngle > ANG90 then
    Result := FINE_TANGENT_TABLE[0]
  else if -Int64(AAngle) > ANG90 then
    Result := FINE_TANGENT_TABLE[FINEANGLES div 2 - 1]
  else
    // Int64: for -90 degrees and for the smallest integer the old code overflowed and read
    // outside the table
    Result := FINE_TANGENT_TABLE[(Int64(ANG90) - AAngle) div ANGLETOFINEUNIT];
end;

class function TTrigonometry.DegreesToSlope(const AValue: TFixed): TFixed;
begin
  if AValue >= 0 then
    Result := AngleToSlope(Integer(FixedToAngle(AValue)))
  else
    Result := AngleToSlope(-Integer(FixedToAngle(-AValue)));
end;

end.
