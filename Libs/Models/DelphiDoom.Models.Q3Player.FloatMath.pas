{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, float math         }
{                                                                              }
{  Port of AngleMod, AngleSubtract, AnglesSubtract, AnglesToAxis, AngleVectors,}
{  AxisClear and MatrixMultiply of game\q_math.c. Based on the Quake III Arena }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.FloatMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  System.Math,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Q3Player.Types;

type
  /// <summary>
  ///   The float arithmetic of Quake III: every operation is rounded to Single before the next
  ///   (the C code is compiled for SSE); the Delphi x87 would keep an expression in extended
  ///   precision, so each step is stored in a Single. Overflow is not checked (as in C).
  /// </summary>
  TQ3FloatMath = class
  public
    /// <summary>(int)x of C: a value that does not fit gives $80000000 (the x86 "integer indefinite")</summary>
    class function ToInt(const AValue: Double): Integer; static;
    /// <summary>AngleMod: the angle brought to 0..360 in steps of 360/65536</summary>
    class function AngleMod(const AAngle: Single): Single; static;
    /// <summary>
    ///   AngleSubtract: always from -180 to 180. Raises EQ3PlayerException for an angle of 2^31 and
    ///   more, where the loop of the original never ends (360 is lost in the rounding).
    /// </summary>
    class function AngleSubtract(const AAngle1, AAngle2: Single): Single; static;
    /// <summary>AnglesSubtract: component by component</summary>
    class function AnglesSubtract(const AAngles1, AAngles2: TIdVec3): TIdVec3; static;
    /// <summary>AnglesToAxis: pitch, yaw and roll in degrees (X, Y, Z of the vector are pitch, yaw, roll) to the three axes</summary>
    class procedure AnglesToAxis(const AAngles: TIdVec3; out AAxis: TQ3Axis); static;
    /// <summary>AxisClear: the identity</summary>
    class procedure AxisClear(out AAxis: TQ3Axis); static;
    /// <summary>MatrixMultiply: AOut = AIn1 * AIn2, the row of the first by the column of the second</summary>
    class procedure MatrixMultiply(const AIn1, AIn2: TQ3Axis; out AOut: TQ3Axis); static;
    /// <summary>DotProduct</summary>
    class function Dot(const A, B: TIdVec3): Single; static;
  end;

implementation

type
  TDoubleBits = record
    case Integer of
      0: (Bits: UInt64);
      1: (Value: Double);
  end;

function DoubleFromBits(const ABits: UInt64): Double;
var
  LValue: TDoubleBits;
begin
  LValue.Bits := ABits;
  Result := LValue.Value;
end;

var
  // 65536 / 360.0 as the C compiler folds it: the double nearest to the quotient
  GAngleToUnits: Double;
  // (360.0 / 65536) is exact in a double
  GUnitsToAngle: Double;
  // (M_PI * 2 / 360) with M_PI a float constant: the float operations in order
  GDegreesToRadians: Single;

class function TQ3FloatMath.ToInt(const AValue: Double): Integer;
begin
  if IsNan(AValue) or (AValue >= 2147483648.0) or (AValue <= -2147483649.0) then
    Result := Integer($80000000)
  else
    Result := Trunc(AValue);
end;

class function TQ3FloatMath.AngleMod(const AAngle: Single): Single;
var
  LScaled: Double;
  LUnits: Integer;
begin
  LScaled := Double(AAngle);
  LScaled := LScaled * GAngleToUnits;
  LUnits := ToInt(LScaled) and 65535;
  LScaled := GUnitsToAngle * LUnits;
  Result := Single(LScaled);
end;

class function TQ3FloatMath.AngleSubtract(const AAngle1, AAngle2: Single): Single;
var
  LAngle: Single;
begin
  LAngle := AAngle1 - AAngle2;
  // NaN compares false with everything: the loops of the original do not run
  if IsNan(LAngle) then
    Exit(LAngle);
  if Abs(LAngle) >= 2147483648.0 then
    raise EQ3PlayerException.CreateFmt(SQ3AngleOutOfRange, [Double(LAngle)]);
  while LAngle > 180 do
    LAngle := LAngle - 360;
  while LAngle < -180 do
    LAngle := LAngle + 360;
  Result := LAngle;
end;

class function TQ3FloatMath.AnglesSubtract(const AAngles1, AAngles2: TIdVec3): TIdVec3;
begin
  Result.X := AngleSubtract(AAngles1.X, AAngles2.X);
  Result.Y := AngleSubtract(AAngles1.Y, AAngles2.Y);
  Result.Z := AngleSubtract(AAngles1.Z, AAngles2.Z);
end;

class procedure TQ3FloatMath.AnglesToAxis(const AAngles: TIdVec3; out AAxis: TQ3Axis);
var
  LAngle, LSinYaw, LCosYaw, LSinPitch, LCosPitch, LSinRoll, LCosRoll: Single;
  LFirst, LSecond: Single;
  LRight: TIdVec3;
begin
  // AngleVectors
  LAngle := AAngles.Y * GDegreesToRadians;
  LSinYaw := Single(Sin(Double(LAngle)));
  LCosYaw := Single(Cos(Double(LAngle)));
  LAngle := AAngles.X * GDegreesToRadians;
  LSinPitch := Single(Sin(Double(LAngle)));
  LCosPitch := Single(Cos(Double(LAngle)));
  LAngle := AAngles.Z * GDegreesToRadians;
  LSinRoll := Single(Sin(Double(LAngle)));
  LCosRoll := Single(Cos(Double(LAngle)));

  // forward
  AAxis[0].X := LCosPitch * LCosYaw;
  AAxis[0].Y := LCosPitch * LSinYaw;
  AAxis[0].Z := -LSinPitch;
  // right: (-1*sr*sp*cy + -1*cr*-sy)
  LFirst := -LSinRoll * LSinPitch;
  LFirst := LFirst * LCosYaw;
  LSecond := -LCosRoll * -LSinYaw;
  LRight.X := LFirst + LSecond;
  LFirst := -LSinRoll * LSinPitch;
  LFirst := LFirst * LSinYaw;
  LSecond := -LCosRoll * LCosYaw;
  LRight.Y := LFirst + LSecond;
  LFirst := -LSinRoll;
  LRight.Z := LFirst * LCosPitch;
  // up: (cr*sp*cy + -sr*-sy)
  LFirst := LCosRoll * LSinPitch;
  LFirst := LFirst * LCosYaw;
  LSecond := -LSinRoll * -LSinYaw;
  AAxis[2].X := LFirst + LSecond;
  LFirst := LCosRoll * LSinPitch;
  LFirst := LFirst * LSinYaw;
  LSecond := -LSinRoll * LCosYaw;
  AAxis[2].Y := LFirst + LSecond;
  AAxis[2].Z := LCosRoll * LCosPitch;
  // AnglesToAxis: the y axis is "vec3_origin - right" (0 - 0 is +0, not the -0 of a negation)
  LFirst := 0;
  AAxis[1].X := LFirst - LRight.X;
  AAxis[1].Y := LFirst - LRight.Y;
  AAxis[1].Z := LFirst - LRight.Z;
end;

class procedure TQ3FloatMath.AxisClear(out AAxis: TQ3Axis);
begin
  AAxis[0] := TIdVec3.Create(1, 0, 0);
  AAxis[1] := TIdVec3.Create(0, 1, 0);
  AAxis[2] := TIdVec3.Create(0, 0, 1);
end;

class procedure TQ3FloatMath.MatrixMultiply(const AIn1, AIn2: TQ3Axis; out AOut: TQ3Axis);
var
  LRow, LColumn: Integer;
  LFirst, LSecond, LThird: Single;
  LResult: TQ3Axis;
begin
  // the output may be one of the inputs in a caller of the original; here it is computed apart
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
    begin
      LFirst := AIn1[LRow][0] * AIn2[0][LColumn];
      LSecond := AIn1[LRow][1] * AIn2[1][LColumn];
      LThird := AIn1[LRow][2] * AIn2[2][LColumn];
      LFirst := LFirst + LSecond;
      LFirst := LFirst + LThird;
      LResult[LRow][LColumn] := LFirst;
    end;
  AOut := LResult;
end;

class function TQ3FloatMath.Dot(const A, B: TIdVec3): Single;
var
  LX, LY, LZ: Single;
begin
  LX := A.X * B.X;
  LY := A.Y * B.Y;
  LZ := A.Z * B.Z;
  LX := LX + LY;
  Result := LX + LZ;
end;

initialization
  GAngleToUnits := DoubleFromBits($4066C16C16C16C17);
  GUnitsToAngle := 360.0 / 65536;
  GDegreesToRadians := Single(3.14159265358979323846);
  GDegreesToRadians := GDegreesToRadians * 2;
  GDegreesToRadians := GDegreesToRadians / 360;

end.
