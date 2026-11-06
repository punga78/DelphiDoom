{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the vectors in floating point               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.VectorMath;

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   The functions of the old m_vectors on vectors of 2 and 3 single precision numbers. The
  ///   operations are the same as the old ones (same order, same types), so the results are the
  ///   same bit by bit at Win32; the pointers became const and var parameters. Do not pass the
  ///   same variable as input and output: with the old pointers it worked by chance.
  /// </summary>
  TVectorMath = class
  public
    /// <summary>True if the exponent of the number is all ones (NaN or infinity), as the old IS_NAN</summary>
    class function IsNaN(const AValue: Single): Boolean; static;
    class function DegreesToRadians(const ADegrees: Single): Single; static;

    class procedure ProjectPointOnPlane(var ADest: TVec3; const APoint, ANormal: TVec3); static;
    /// <summary>A vector perpendicular to ASource, which must be normalized</summary>
    class procedure PerpendicularVector(var ADest: TVec3; const ASource: TVec3); static;
    class procedure RotatePointAroundVector(var ADest: TVec3; const ADirection, APoint: TVec3;
      const ADegrees: Single); static;
    class function Compare3(const A, B: TVec3): Boolean; static;
    /// <summary>C = A + AScale * B</summary>
    class procedure MultiplyAdd3(const A: TVec3; const AScale: Single; const B: TVec3;
      var C: TVec3); static;
    class function Dot3(const A, B: TVec3): Single; static;
    class procedure Subtract3(const A, B: TVec3; var AOut: TVec3); static;
    class procedure Add3(const A, B: TVec3; var AOut: TVec3); static;
    class procedure Cross3(const A, B: TVec3; var ACross: TVec3); static;
    class function Length3(const A: TVec3): Single; static;
    /// <summary>Makes the vector of length 1 (a zero vector stays as it is); gives the old length</summary>
    class function Normalize3(var A: TVec3): Single; static;
    class procedure Inverse3(var A: TVec3); static;
    class procedure Scale3(const A: TVec3; const AScale: Single; var AOut: TVec3); static;
    class procedure ConcatRotations(const A, B: TMat3; var AOut: TMat3); static;

    class function Dot2(const A, B: TVec2): Single; static;
    class function Subtract2(const A, B: TVec2): TVec2; static;
    class function Add2(const A, B: TVec2): TVec2; static;
    class function Scale2(const A: TVec2; const AScale: Single): TVec2; static;
    class function Length2(const A: TVec2): Single; static;
    class function Normalize2(var A: TVec2): Single; static;
    /// <summary>The direction D after the bounce on a wall, with the length of D</summary>
    class procedure CalculateReflect2(const D, AWall: TVec2; var AReflect: TVec2); static;
  end;

implementation

const
  NAN_MASK = 255 shl 23;

{ TVectorMath }

class function TVectorMath.IsNaN(const AValue: Single): Boolean;
var
  LBits: Integer;
begin
  Move(AValue, LBits, SizeOf(LBits));
  Result := (LBits and NAN_MASK) = NAN_MASK;
end;

class function TVectorMath.DegreesToRadians(const ADegrees: Single): Single;
begin
  Result := (ADegrees * MATHCORE_PI) / 180.0;
end;

class procedure TVectorMath.ProjectPointOnPlane(var ADest: TVec3; const APoint, ANormal: TVec3);
var
  LDistance: Single;
  LNormal: TVec3;
  LInverseDenominator: Single;
begin
  LInverseDenominator := 1.0 / Dot3(ANormal, ANormal);

  LDistance := Dot3(ANormal, APoint) * LInverseDenominator;

  LNormal[0] := ANormal[0] * LInverseDenominator;
  LNormal[1] := ANormal[1] * LInverseDenominator;
  LNormal[2] := ANormal[2] * LInverseDenominator;

  ADest[0] := APoint[0] - LDistance * LNormal[0];
  ADest[1] := APoint[1] - LDistance * LNormal[1];
  ADest[2] := APoint[2] - LDistance * LNormal[2];
end;

class procedure TVectorMath.PerpendicularVector(var ADest: TVec3; const ASource: TVec3);
var
  LPosition: Integer;
  LIndex: Integer;
  LMinimum: Single;
  LTemp: TVec3;
  LAbsolute: Single;
begin
  LMinimum := 1.0;

  // find the smallest magnitude axially aligned vector
  LPosition := 0;
  for LIndex := 0 to 2 do
  begin
    if ASource[LIndex] >= 0 then
      LAbsolute := ASource[LIndex]
    else
      LAbsolute := -ASource[LIndex];
    if LAbsolute < LMinimum then
    begin
      LPosition := LIndex;
      LMinimum := LAbsolute;
    end;
  end;
  LTemp[0] := 0.0;
  LTemp[1] := 0.0;
  LTemp[2] := 0.0;
  LTemp[LPosition] := 1.0;

  // project the point onto the plane defined by src
  ProjectPointOnPlane(ADest, LTemp, ASource);

  // normalize the result
  Normalize3(ADest);
end;

class procedure TVectorMath.RotatePointAroundVector(var ADest: TVec3;
  const ADirection, APoint: TVec3; const ADegrees: Single);
var
  LM: TMat3;
  LIM: TMat3;
  LZRot: TMat3;
  LTemp: TMat3;
  LRot: TMat3;
  LIndex: Integer;
  LVR, LVUp, LVF: TVec3;
begin
  LVF[0] := ADirection[0];
  LVF[1] := ADirection[1];
  LVF[2] := ADirection[2];

  PerpendicularVector(LVR, ADirection);
  Cross3(LVR, LVF, LVUp);

  LM[0][0] := LVR[0];
  LM[1][0] := LVR[1];
  LM[2][0] := LVR[2];

  LM[0][1] := LVUp[0];
  LM[1][1] := LVUp[1];
  LM[2][1] := LVUp[2];

  LM[0][2] := LVF[0];
  LM[1][2] := LVF[1];
  LM[2][2] := LVF[2];

  LIM := LM;

  LIM[0][1] := LM[1][0];
  LIM[0][2] := LM[2][0];
  LIM[1][0] := LM[0][1];
  LIM[1][2] := LM[2][1];
  LIM[2][0] := LM[0][2];
  LIM[2][1] := LM[1][2];

  FillChar(LZRot, SizeOf(LZRot), 0);
  LZRot[0, 0] := 1.0;
  LZRot[1, 1] := 1.0;
  LZRot[2, 2] := 1.0;

  LZRot[0][0] := Cos(DegreesToRadians(ADegrees));
  LZRot[0][1] := Sin(DegreesToRadians(ADegrees));
  LZRot[1][0] := -Sin(DegreesToRadians(ADegrees));
  LZRot[1][1] := Cos(DegreesToRadians(ADegrees));

  ConcatRotations(LM, LZRot, LTemp);
  ConcatRotations(LTemp, LIM, LRot);

  for LIndex := 0 to 2 do
    ADest[LIndex] := LRot[LIndex, 0] * APoint[0] + LRot[LIndex, 1] * APoint[1] +
      LRot[LIndex, 2] * APoint[2];
end;

class function TVectorMath.Compare3(const A, B: TVec3): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    if A[LIndex] <> B[LIndex] then
      Exit(False);
  Result := True;
end;

class procedure TVectorMath.MultiplyAdd3(const A: TVec3; const AScale: Single; const B: TVec3;
  var C: TVec3);
begin
  C[0] := A[0] + AScale * B[0];
  C[1] := A[1] + AScale * B[1];
  C[2] := A[2] + AScale * B[2];
end;

class function TVectorMath.Dot3(const A, B: TVec3): Single;
begin
  Result := A[0] * B[0] + A[1] * B[1] + A[2] * B[2];
end;

class procedure TVectorMath.Subtract3(const A, B: TVec3; var AOut: TVec3);
begin
  AOut[0] := A[0] - B[0];
  AOut[1] := A[1] - B[1];
  AOut[2] := A[2] - B[2];
end;

class procedure TVectorMath.Add3(const A, B: TVec3; var AOut: TVec3);
begin
  AOut[0] := A[0] + B[0];
  AOut[1] := A[1] + B[1];
  AOut[2] := A[2] + B[2];
end;

class procedure TVectorMath.Cross3(const A, B: TVec3; var ACross: TVec3);
begin
  ACross[0] := A[1] * B[2] - A[2] * B[1];
  ACross[1] := A[2] * B[0] - A[0] * B[2];
  ACross[2] := A[0] * B[1] - A[1] * B[0];
end;

class function TVectorMath.Length3(const A: TVec3): Single;
begin
  Result := A[0] * A[0] + A[1] * A[1] + A[2] * A[2];
  Result := Sqrt(Result);
end;

class function TVectorMath.Normalize3(var A: TVec3): Single;
var
  LInverseLength: Single;
begin
  Result := A[0] * A[0] + A[1] * A[1] + A[2] * A[2];
  Result := Sqrt(Result);

  if Result > 0.0 then
  begin
    LInverseLength := 1 / Result;
    A[0] := A[0] * LInverseLength;
    A[1] := A[1] * LInverseLength;
    A[2] := A[2] * LInverseLength;
  end;
end;

class procedure TVectorMath.Inverse3(var A: TVec3);
begin
  A[0] := -A[0];
  A[1] := -A[1];
  A[2] := -A[2];
end;

class procedure TVectorMath.Scale3(const A: TVec3; const AScale: Single; var AOut: TVec3);
begin
  AOut[0] := A[0] * AScale;
  AOut[1] := A[1] * AScale;
  AOut[2] := A[2] * AScale;
end;

class procedure TVectorMath.ConcatRotations(const A, B: TMat3; var AOut: TMat3);
begin
  AOut[0][0] := A[0][0] * B[0][0] + A[0][1] * B[1][0] + A[0][2] * B[2][0];
  AOut[0][1] := A[0][0] * B[0][1] + A[0][1] * B[1][1] + A[0][2] * B[2][1];
  AOut[0][2] := A[0][0] * B[0][2] + A[0][1] * B[1][2] + A[0][2] * B[2][2];
  AOut[1][0] := A[1][0] * B[0][0] + A[1][1] * B[1][0] + A[1][2] * B[2][0];
  AOut[1][1] := A[1][0] * B[0][1] + A[1][1] * B[1][1] + A[1][2] * B[2][1];
  AOut[1][2] := A[1][0] * B[0][2] + A[1][1] * B[1][2] + A[1][2] * B[2][2];
  AOut[2][0] := A[2][0] * B[0][0] + A[2][1] * B[1][0] + A[2][2] * B[2][0];
  AOut[2][1] := A[2][0] * B[0][1] + A[2][1] * B[1][1] + A[2][2] * B[2][1];
  AOut[2][2] := A[2][0] * B[0][2] + A[2][1] * B[1][2] + A[2][2] * B[2][2];
end;

class function TVectorMath.Dot2(const A, B: TVec2): Single;
begin
  Result := A[0] * B[0] + A[1] * B[1];
end;

class function TVectorMath.Subtract2(const A, B: TVec2): TVec2;
begin
  Result[0] := A[0] - B[0];
  Result[1] := A[1] - B[1];
end;

class function TVectorMath.Add2(const A, B: TVec2): TVec2;
begin
  Result[0] := A[0] + B[0];
  Result[1] := A[1] + B[1];
end;

class function TVectorMath.Scale2(const A: TVec2; const AScale: Single): TVec2;
begin
  Result[0] := A[0] * AScale;
  Result[1] := A[1] * AScale;
end;

class function TVectorMath.Length2(const A: TVec2): Single;
begin
  Result := A[0] * A[0] + A[1] * A[1];
  Result := Sqrt(Result);
end;

class function TVectorMath.Normalize2(var A: TVec2): Single;
var
  LInverseLength: Single;
begin
  Result := A[0] * A[0] + A[1] * A[1];
  Result := Sqrt(Result);

  if Result > 0.0 then
  begin
    LInverseLength := 1 / Result;
    A[0] := A[0] * LInverseLength;
    A[1] := A[1] * LInverseLength;
  end;
end;

class procedure TVectorMath.CalculateReflect2(const D, AWall: TVec2; var AReflect: TVec2);
var
  LNormal: TVec2;
begin
  LNormal[0] := -AWall[1];
  LNormal[1] := AWall[0];

  Normalize2(LNormal);

  AReflect := Subtract2(D, Scale2(LNormal, 2 * Dot2(D, LNormal)));
  Normalize2(AReflect);
  AReflect := Scale2(AReflect, Length2(D));
end;

end.
