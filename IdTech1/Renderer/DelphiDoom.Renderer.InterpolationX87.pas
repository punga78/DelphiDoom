{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the floating point of the interpolation of   }
{  the frames, with the result of the 32 bit code                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The expressions are those of r_intrpl.pas                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.InterpolationX87;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.SoftExtended;

type
  /// <summary>
  ///   The expressions of r_intrpl.pas whose intermediate values the 32 bit code keeps in 64 bits of mantissa
  ///   (x87) and stores in a Single, computed without the FPU for the 64 bit renderer (issue #40). The integer
  ///   forms (a difference of 32 bits times a Single of 17 bits) are exact in a Double and need nothing
  /// </summary>
  TRendererInterpolationX87 = class
  strict private
    class function Fraction(const AValue: Single): TSoftExtended; static;
  public
    /// <summary>
    ///   The angle of R_InterpolationCalcA when the two angles are on the two sides of the 0: the angles as
    ///   fractions of the circle (each stored in a Single), the middle one, Round(mid * ANGLE_MAX)
    /// </summary>
    class function AngleAcrossZero(APrevious, ANext: Cardinal; const AFraction: Single): Int64; static;
    /// <summary>APrevious + (ANext - APrevious) * AFraction stored in a Single (R_InterpolationCalcF, FF)</summary>
    class function InterpolateSingle(const APrevious, ANext, AFraction: Single): Single; static;
  end;

implementation

const
  ANGLE_MAX = $FFFFFFFF;

class function TRendererInterpolationX87.Fraction(const AValue: Single): TSoftExtended;
begin
  Result := TSoftExtended.FromDouble(AValue);
end;

class function TRendererInterpolationX87.AngleAcrossZero(APrevious, ANext: Cardinal;
  const AFraction: Single): Int64;
var
  LPrevious, LNext, LMiddle: Single;
  LOne: TSoftExtended;
begin
  LOne := TSoftExtended.FromInt64(1);
  LPrevious := (TSoftExtended.FromInt64(APrevious) / TSoftExtended.FromInt64(ANGLE_MAX)).ToSingle;
  LNext := (TSoftExtended.FromInt64(ANext) / TSoftExtended.FromInt64(ANGLE_MAX)).ToSingle;
  if APrevious > ANext then
    LNext := (Fraction(LNext) + LOne).ToSingle
  else
    LPrevious := (Fraction(LPrevious) + LOne).ToSingle;
  LMiddle := (Fraction(LPrevious) + (Fraction(LNext) - Fraction(LPrevious)) * Fraction(AFraction)).ToSingle;
  if Fraction(LMiddle) > LOne then
    LMiddle := (Fraction(LMiddle) - LOne).ToSingle;
  Result := (Fraction(LMiddle) * TSoftExtended.FromInt64(ANGLE_MAX)).Round;
end;

class function TRendererInterpolationX87.InterpolateSingle(const APrevious, ANext, AFraction: Single): Single;
begin
  Result := (Fraction(APrevious) + (Fraction(ANext) - Fraction(APrevious)) * Fraction(AFraction)).ToSingle;
end;

end.
