{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the vector functions it uses                                                }
{                                                                              }
{  Port of the macros of q_shared.h (DotProduct, PlaneTypeForNormal) and of    }
{  SetPlaneSignbits, BoxOnPlaneSide and AngleVectors of q_math.c and of the    }
{  rotation helpers of cm_trace.c, from the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Math;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types;

type
  /// <summary>vec3_t matrix[3]</summary>
  TQ3Mat3 = array[0..2] of TQ3Vec3;

  /// <summary>
  ///   The float arithmetic of the C code: every operation is rounded to a float on its own
  ///   (a local Single holds each partial result), as the code of the engine is compiled; the
  ///   32 bit x87 code of Delphi would otherwise keep the intermediate results in extended.
  /// </summary>
  TQ3Math = class
  public
    /// <summary>DotProduct</summary>
    class function Dot(const AFirst, ASecond: TQ3Vec3): Single; static;
    /// <summary>PlaneTypeForNormal: an axial plane has a component that is exactly 1</summary>
    class function PlaneTypeForNormal(const ANormal: TQ3Vec3): Byte; static;
    /// <summary>SetPlaneSignbits: bit j is set if the component j of the normal is negative</summary>
    class function SignBitsOf(const ANormal: TQ3Vec3): Byte; static;
    /// <summary>
    ///   BoxOnPlaneSide, the portable version: 1 if the box is in front of the plane, 2 if it is
    ///   behind, 3 if it crosses it
    /// </summary>
    class function BoxOnPlaneSide(const AMins, AMaxs: TQ3Vec3; const APlane: TQ3Plane): Integer; static;
    /// <summary>AngleVectors (pitch, yaw, roll in degrees)</summary>
    class procedure AngleVectors(const AAngles: TQ3Vec3; out AForward, ARight, AUp: TQ3Vec3); static;
    /// <summary>CreateRotationMatrix</summary>
    class procedure CreateRotationMatrix(const AAngles: TQ3Vec3; out AMatrix: TQ3Mat3); static;
    /// <summary>RotatePoint</summary>
    class procedure RotatePoint(var APoint: TQ3Vec3; const AMatrix: TQ3Mat3); static;
    /// <summary>TransposeMatrix</summary>
    class procedure TransposeMatrix(const AMatrix: TQ3Mat3; out ATranspose: TQ3Mat3); static;
  end;

implementation

const
  // M_PI of q_shared.h is a float constant
  Q3_PI: Single = 3.14159265358979323846;

class function TQ3Math.Dot(const AFirst, ASecond: TQ3Vec3): Single;
var
  LX, LY, LZ: Single;
begin
  LX := AFirst[0] * ASecond[0];
  LY := AFirst[1] * ASecond[1];
  LZ := AFirst[2] * ASecond[2];
  Result := LX + LY;
  Result := Result + LZ;
end;

class function TQ3Math.PlaneTypeForNormal(const ANormal: TQ3Vec3): Byte;
begin
  if ANormal[0] = 1.0 then
    Result := Q3_PLANE_X
  else if ANormal[1] = 1.0 then
    Result := Q3_PLANE_Y
  else if ANormal[2] = 1.0 then
    Result := Q3_PLANE_Z
  else
    Result := Q3_PLANE_NON_AXIAL;
end;

class function TQ3Math.SignBitsOf(const ANormal: TQ3Vec3): Byte;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 2 do
    if ANormal[LIndex] < 0 then
      Result := Result or (1 shl LIndex);
end;

class function TQ3Math.BoxOnPlaneSide(const AMins, AMaxs: TQ3Vec3; const APlane: TQ3Plane): Integer;
var
  LFirst, LSecond: TQ3Vec3;
  LIndex: Integer;
  LDist1, LDist2: Single;
begin
  // fast axial cases
  if APlane.PlaneType < 3 then
  begin
    if APlane.Dist <= AMins[APlane.PlaneType] then
      Exit(1);
    if APlane.Dist >= AMaxs[APlane.PlaneType] then
      Exit(2);
    Exit(3);
  end;

  // general case: the corner of the box that is the most in front, and the one that is the most behind
  for LIndex := 0 to 2 do
    if (APlane.SignBits and (1 shl LIndex)) <> 0 then
    begin
      LFirst[LIndex] := AMins[LIndex];
      LSecond[LIndex] := AMaxs[LIndex];
    end
    else
    begin
      LFirst[LIndex] := AMaxs[LIndex];
      LSecond[LIndex] := AMins[LIndex];
    end;
  if APlane.SignBits > 7 then
  begin
    // "shut up compiler" of the original
    LDist1 := 0;
    LDist2 := 0;
  end
  else
  begin
    LDist1 := Dot(APlane.Normal, LFirst);
    LDist2 := Dot(APlane.Normal, LSecond);
  end;

  Result := 0;
  if LDist1 >= APlane.Dist then
    Result := 1;
  if LDist2 < APlane.Dist then
    Result := Result or 2;
end;

class procedure TQ3Math.AngleVectors(const AAngles: TQ3Vec3; out AForward, ARight, AUp: TQ3Vec3);
var
  LFactor, LAngle: Single;
  LSinRoll, LSinPitch, LSinYaw, LCosRoll, LCosPitch, LCosYaw: Single;
  LFirst, LSecond: Single;
begin
  // (M_PI*2 / 360) is a float expression
  LFactor := Q3_PI * 2;
  LFactor := LFactor / 360;
  LAngle := AAngles[1] * LFactor;
  LSinYaw := Sin(Double(LAngle));
  LCosYaw := Cos(Double(LAngle));
  LAngle := AAngles[0] * LFactor;
  LSinPitch := Sin(Double(LAngle));
  LCosPitch := Cos(Double(LAngle));
  LAngle := AAngles[2] * LFactor;
  LSinRoll := Sin(Double(LAngle));
  LCosRoll := Cos(Double(LAngle));

  AForward[0] := LCosPitch * LCosYaw;
  AForward[1] := LCosPitch * LSinYaw;
  AForward[2] := -LSinPitch;

  // (-1*sr*sp*cy + -1*cr*-sy)
  LFirst := -LSinRoll;
  LFirst := LFirst * LSinPitch;
  LFirst := LFirst * LCosYaw;
  LSecond := -LCosRoll;
  LSecond := LSecond * (-LSinYaw);
  ARight[0] := LFirst + LSecond;
  // (-1*sr*sp*sy + -1*cr*cy)
  LFirst := -LSinRoll;
  LFirst := LFirst * LSinPitch;
  LFirst := LFirst * LSinYaw;
  LSecond := -LCosRoll;
  LSecond := LSecond * LCosYaw;
  ARight[1] := LFirst + LSecond;
  LFirst := -LSinRoll;
  ARight[2] := LFirst * LCosPitch;

  // (cr*sp*cy + -sr*-sy)
  LFirst := LCosRoll * LSinPitch;
  LFirst := LFirst * LCosYaw;
  LSecond := -LSinRoll;
  LSecond := LSecond * (-LSinYaw);
  AUp[0] := LFirst + LSecond;
  // (cr*sp*sy + -sr*cy)
  LFirst := LCosRoll * LSinPitch;
  LFirst := LFirst * LSinYaw;
  LSecond := -LSinRoll;
  LSecond := LSecond * LCosYaw;
  AUp[1] := LFirst + LSecond;
  AUp[2] := LCosRoll * LCosPitch;
end;

class procedure TQ3Math.CreateRotationMatrix(const AAngles: TQ3Vec3; out AMatrix: TQ3Mat3);
var
  LIndex: Integer;
begin
  AngleVectors(AAngles, AMatrix[0], AMatrix[1], AMatrix[2]);
  // VectorInverse(matrix[1])
  for LIndex := 0 to 2 do
    AMatrix[1][LIndex] := -AMatrix[1][LIndex];
end;

class procedure TQ3Math.RotatePoint(var APoint: TQ3Vec3; const AMatrix: TQ3Mat3);
var
  LTemp: TQ3Vec3;
begin
  LTemp := APoint;
  APoint[0] := Dot(AMatrix[0], LTemp);
  APoint[1] := Dot(AMatrix[1], LTemp);
  APoint[2] := Dot(AMatrix[2], LTemp);
end;

class procedure TQ3Math.TransposeMatrix(const AMatrix: TQ3Mat3; out ATranspose: TQ3Mat3);
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
      ATranspose[LRow][LColumn] := AMatrix[LColumn][LRow];
end;

end.
