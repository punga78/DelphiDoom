{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  vector macros                                                               }
{                                                                              }
{  Port of the vector macros of q_shared.h and of VectorNormalize and          }
{  VectorLength of q_math.c of the Quake III Arena GPL Source Code (id         }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.VectorMath;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types;

type
  /// <summary>
  ///   The vector macros of the C code with their float arithmetic: every operation is rounded to a
  ///   float on its own (a local Single holds each partial result), where the C mixes a double
  ///   (sqrt, a literal like 0.5) the Double is kept
  /// </summary>
  TQ3VectorMath = class sealed
  public
    /// <summary>VectorSubtract(a, b, out)</summary>
    class function Subtract(const AFirst, ASecond: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorAdd(a, b, out)</summary>
    class function Add(const AFirst, ASecond: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorMA(v, s, b, out): v + b * s</summary>
    class function MultiplyAdd(const AVector: TQ3Vec3; AScale: Single; const ADirection: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorScale(v, s, out)</summary>
    class function Scale(const AVector: TQ3Vec3; AScale: Single): TQ3Vec3; static;
    /// <summary>VectorNegate</summary>
    class function Negate(const AVector: TQ3Vec3): TQ3Vec3; static;
    /// <summary>CrossProduct(v1, v2, out)</summary>
    class function Cross(const AFirst, ASecond: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorLength: (float) sqrt( x*x + y*y + z*z )</summary>
    class function Length(const AVector: TQ3Vec3): Single; static;
    /// <summary>VectorNormalize: normalizes in place and returns the length (0 leaves the vector as it was)</summary>
    class function Normalize(var AVector: TQ3Vec3): Single; static;
    /// <summary>The sum of the squares x*x + y*y + z*z, every operation in float</summary>
    class function LengthSquared(const AVector: TQ3Vec3): Single; static;
    /// <summary>DotProduct: x*x + y*y + z*z in floats, from the left</summary>
    class function Dot(const AFirst, ASecond: TQ3Vec3): Single; static;
    /// <summary>ProjectPointOnPlane of q_math.c (the normal need not be a unit vector)</summary>
    class function ProjectPointOnPlane(const APoint, ANormal: TQ3Vec3): TQ3Vec3; static;
    /// <summary>PerpendicularVector of q_math.c: a unit vector perpendicular to the source</summary>
    class function PerpendicularVector(const ASource: TQ3Vec3): TQ3Vec3; static;
    /// <summary>
    ///   RotatePointAroundVector of q_math.c: the point turned by ADegrees around the direction (which is a unit
    ///   vector), with the rotation matrix of the original and every operation in floats; sin and cos go through a
    ///   double as the C library does
    /// </summary>
    class function RotatePointAroundVector(const ADirection, APoint: TQ3Vec3; ADegrees: Single): TQ3Vec3; static;
    /// <summary>MakeNormalVectors of q_math.c: two vectors perpendicular to a unit forward vector</summary>
    class procedure MakeNormalVectors(const AForward: TQ3Vec3; out ARight, AUp: TQ3Vec3); static;
  end;

implementation

uses
  System.SysUtils;

class function TQ3VectorMath.Subtract(const AFirst, ASecond: TQ3Vec3): TQ3Vec3;
begin
  Result[0] := AFirst[0] - ASecond[0];
  Result[1] := AFirst[1] - ASecond[1];
  Result[2] := AFirst[2] - ASecond[2];
end;

class function TQ3VectorMath.Add(const AFirst, ASecond: TQ3Vec3): TQ3Vec3;
begin
  Result[0] := AFirst[0] + ASecond[0];
  Result[1] := AFirst[1] + ASecond[1];
  Result[2] := AFirst[2] + ASecond[2];
end;

class function TQ3VectorMath.MultiplyAdd(const AVector: TQ3Vec3; AScale: Single;
  const ADirection: TQ3Vec3): TQ3Vec3;
var
  LProduct: Single;
begin
  LProduct := ADirection[0] * AScale;
  Result[0] := AVector[0] + LProduct;
  LProduct := ADirection[1] * AScale;
  Result[1] := AVector[1] + LProduct;
  LProduct := ADirection[2] * AScale;
  Result[2] := AVector[2] + LProduct;
end;

class function TQ3VectorMath.Scale(const AVector: TQ3Vec3; AScale: Single): TQ3Vec3;
begin
  Result[0] := AVector[0] * AScale;
  Result[1] := AVector[1] * AScale;
  Result[2] := AVector[2] * AScale;
end;

class function TQ3VectorMath.Negate(const AVector: TQ3Vec3): TQ3Vec3;
begin
  Result[0] := -AVector[0];
  Result[1] := -AVector[1];
  Result[2] := -AVector[2];
end;

class function TQ3VectorMath.Cross(const AFirst, ASecond: TQ3Vec3): TQ3Vec3;
var
  LFirst, LSecond: Single;
begin
  LFirst := AFirst[1] * ASecond[2];
  LSecond := AFirst[2] * ASecond[1];
  Result[0] := LFirst - LSecond;
  LFirst := AFirst[2] * ASecond[0];
  LSecond := AFirst[0] * ASecond[2];
  Result[1] := LFirst - LSecond;
  LFirst := AFirst[0] * ASecond[1];
  LSecond := AFirst[1] * ASecond[0];
  Result[2] := LFirst - LSecond;
end;

class function TQ3VectorMath.LengthSquared(const AVector: TQ3Vec3): Single;
var
  LX, LY, LZ: Single;
begin
  LX := AVector[0] * AVector[0];
  LY := AVector[1] * AVector[1];
  LZ := AVector[2] * AVector[2];
  Result := LX + LY;
  Result := Result + LZ;
end;

class function TQ3VectorMath.Length(const AVector: TQ3Vec3): Single;
var
  LRoot: Double;
begin
  LRoot := Sqrt(Double(LengthSquared(AVector)));
  Result := LRoot;
end;

class function TQ3VectorMath.Normalize(var AVector: TQ3Vec3): Single;
var
  LInverse: Single;
  LRoot: Double;
begin
  LRoot := Sqrt(Double(LengthSquared(AVector)));
  Result := LRoot;
  if Result <> 0 then
  begin
    LInverse := 1 / Result;
    AVector[0] := AVector[0] * LInverse;
    AVector[1] := AVector[1] * LInverse;
    AVector[2] := AVector[2] * LInverse;
  end;
end;

class function TQ3VectorMath.Dot(const AFirst, ASecond: TQ3Vec3): Single;
var
  LTerm: Single;
begin
  Result := AFirst[0] * ASecond[0];
  LTerm := AFirst[1] * ASecond[1];
  Result := Result + LTerm;
  LTerm := AFirst[2] * ASecond[2];
  Result := Result + LTerm;
end;

class function TQ3VectorMath.ProjectPointOnPlane(const APoint, ANormal: TQ3Vec3): TQ3Vec3;
var
  LInverse, LDistance, LTerm: Single;
  LScaled: TQ3Vec3;
  LAxis: Integer;
begin
  LInverse := Dot(ANormal, ANormal);
  LInverse := 1.0 / LInverse;
  LDistance := Dot(ANormal, APoint);
  LDistance := LDistance * LInverse;
  for LAxis := 0 to 2 do
  begin
    LScaled[LAxis] := ANormal[LAxis] * LInverse;
    LTerm := LDistance * LScaled[LAxis];
    Result[LAxis] := APoint[LAxis] - LTerm;
  end;
end;

class function TQ3VectorMath.PerpendicularVector(const ASource: TQ3Vec3): TQ3Vec3;
var
  LPosition, LIndex: Integer;
  LMinimum, LAbsolute: Single;
  LTemp: TQ3Vec3;
begin
  // find the smallest magnitude axially aligned vector
  LMinimum := 1.0;
  LPosition := 0;
  for LIndex := 0 to 2 do
  begin
    LAbsolute := Abs(ASource[LIndex]);
    if LAbsolute < LMinimum then
    begin
      LPosition := LIndex;
      LMinimum := LAbsolute;
    end;
  end;
  LTemp[0] := 0;
  LTemp[1] := 0;
  LTemp[2] := 0;
  LTemp[LPosition] := 1.0;
  // project the point onto the plane defined by src, then normalize the result
  Result := ProjectPointOnPlane(LTemp, ASource);
  Normalize(Result);
end;

class function TQ3VectorMath.RotatePointAroundVector(const ADirection, APoint: TQ3Vec3; ADegrees: Single): TQ3Vec3;
type
  TMatrix = array[0..2, 0..2] of Single;
const
  PiFloat: Single = 3.14159265358979323846;

  procedure Multiply(const AFirst, ASecond: TMatrix; out AResult: TMatrix);
  var
    LRow, LColumn: Integer;
    LSum, LTerm: Single;
  begin
    for LRow := 0 to 2 do
      for LColumn := 0 to 2 do
      begin
        LSum := AFirst[LRow, 0] * ASecond[0, LColumn];
        LTerm := AFirst[LRow, 1] * ASecond[1, LColumn];
        LSum := LSum + LTerm;
        LTerm := AFirst[LRow, 2] * ASecond[2, LColumn];
        AResult[LRow, LColumn] := LSum + LTerm;
      end;
  end;

var
  LM, LIM, LZRot, LTemp, LRot: TMatrix;
  LVR, LVUp: TQ3Vec3;
  LIndex: Integer;
  LRadians, LValue, LTerm: Single;
  LDouble: Double;
begin
  LVR := PerpendicularVector(ADirection);
  LVUp := Cross(LVR, ADirection);
  for LIndex := 0 to 2 do
  begin
    LM[LIndex, 0] := LVR[LIndex];
    LM[LIndex, 1] := LVUp[LIndex];
    LM[LIndex, 2] := ADirection[LIndex];
  end;
  LIM := LM;
  LIM[0, 1] := LM[1, 0];
  LIM[0, 2] := LM[2, 0];
  LIM[1, 0] := LM[0, 1];
  LIM[1, 2] := LM[2, 1];
  LIM[2, 0] := LM[0, 2];
  LIM[2, 1] := LM[1, 2];
  FillChar(LZRot, SizeOf(LZRot), 0);
  LZRot[0, 0] := 1.0;
  LZRot[1, 1] := 1.0;
  LZRot[2, 2] := 1.0;
  // DEG2RAD(a) is ((a) * M_PI) / 180.0f with the float M_PI of q_shared.h
  LRadians := ADegrees * PiFloat;
  LRadians := LRadians / 180.0;
  LDouble := Cos(Double(LRadians));
  LZRot[0, 0] := LDouble;
  LDouble := Sin(Double(LRadians));
  LZRot[0, 1] := LDouble;
  LDouble := -Sin(Double(LRadians));
  LZRot[1, 0] := LDouble;
  LDouble := Cos(Double(LRadians));
  LZRot[1, 1] := LDouble;
  Multiply(LM, LZRot, LTemp);
  Multiply(LTemp, LIM, LRot);
  for LIndex := 0 to 2 do
  begin
    LValue := LRot[LIndex, 0] * APoint[0];
    LTerm := LRot[LIndex, 1] * APoint[1];
    LValue := LValue + LTerm;
    LTerm := LRot[LIndex, 2] * APoint[2];
    Result[LIndex] := LValue + LTerm;
  end;
end;

class procedure TQ3VectorMath.MakeNormalVectors(const AForward: TQ3Vec3; out ARight, AUp: TQ3Vec3);
var
  LDistance: Single;
begin
  // this rotate and negate guarantees a vector not colinear with the original
  ARight[1] := -AForward[0];
  ARight[2] := AForward[1];
  ARight[0] := AForward[2];
  LDistance := Dot(ARight, AForward);
  ARight := MultiplyAdd(ARight, -LDistance, AForward);
  Normalize(ARight);
  AUp := Cross(ARight, AForward);
end;

end.
