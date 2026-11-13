{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - conversions between angles,         }
{  matrix, quaternion and rotation                                             }
{                                                                              }
{  Port of the ToAngles, ToQuat, ToCQuat, ToRotation, ToMat3 and               }
{  ToAngularVelocity members of idAngles, idMat3, idQuat, idCQuat and          }
{  idRotation (idlib\math) of the Doom 3 GPL Source Code. Copyright (C)        }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3     }
{  GPL Source Code (id Software).                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Conversions;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.CQuat,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Quat, DelphiDoom.MathCore.Float.Rotation;

type
  /// <summary>
  ///   The conversions between the rotation types of idTech 4. In C++ every type has members that
  ///   return the others (<c>idMat3::ToQuat</c>, <c>idQuat::ToMat3</c>...); units cannot refer to
  ///   each other, so they are static functions here, named after the original member
  ///   (<c>idMat3::ToQuat</c> is <c>MatToQuat</c>). Stateless.
  /// </summary>
  TIdRotationConversions = class
  public
    class function MatToAngles(const AMatrix: TIdMat3): TIdAngles; static;
    class function MatToQuat(const AMatrix: TIdMat3): TIdQuat; static;
    class function MatToCQuat(const AMatrix: TIdMat3): TIdCQuat; static;
    class function MatToRotation(const AMatrix: TIdMat3): TIdRotation; static;
    class function MatToAngularVelocity(const AMatrix: TIdMat3): TIdVec3; static;
    class function QuatToAngles(const AQuat: TIdQuat): TIdAngles; static;
    class function QuatToRotation(const AQuat: TIdQuat): TIdRotation; static;
    class function QuatToMat(const AQuat: TIdQuat): TIdMat3; static;
    class function QuatToCQuat(const AQuat: TIdQuat): TIdCQuat; static;
    class function CQuatToAngles(const ACQuat: TIdCQuat): TIdAngles; static;
    class function CQuatToRotation(const ACQuat: TIdCQuat): TIdRotation; static;
    class function CQuatToMat(const ACQuat: TIdCQuat): TIdMat3; static;
    class function AnglesToQuat(const AAngles: TIdAngles): TIdQuat; static;
    class function AnglesToRotation(const AAngles: TIdAngles): TIdRotation; static;
    class function AnglesToMat(const AAngles: TIdAngles): TIdMat3; static;
    class function AnglesToAngularVelocity(const AAngles: TIdAngles): TIdVec3; static;
    class function RotationToAngles(const ARotation: TIdRotation): TIdAngles; static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

const
  NEXT_INDEX: array[0..2] of Integer = (1, 2, 0);

// the common end of idQuat::ToRotation and idAngles::ToRotation: axis and angle from x, y, z and w
function AxisAngleFromQuat(const AX, AY, AZ, AW: Single): TIdRotation;
var
  LVector: TIdVec3;
  LAngle: Single;
begin
  LVector.SetValues(AX, AY, AZ);
  LAngle := TIdMath.ACos(AW);
  if LAngle = 0.0 then
    LVector.SetValues(0.0, 0.0, 1.0)
  else
  begin
    LVector.Normalize;
    LVector.FixDegenerateNormal;
    LAngle := LAngle * (2.0 * ID_RAD2DEG);
  end;
  Result := TIdRotation.Create(TIdVec3.Create(0.0, 0.0, 0.0), LVector, LAngle);
end;

{ TIdRotationConversions }

class function TIdRotationConversions.MatToAngles(const AMatrix: TIdMat3): TIdAngles;
var
  LTheta, LCosPitch: Double;
  LSinPitch: Single;
  LRadians: Double;
begin
  LSinPitch := AMatrix.Rows[0].Z;
  // cap the sine so that the arc sine cannot give a NaN
  if LSinPitch > 1.0 then
    LSinPitch := 1.0
  else if LSinPitch < -1.0 then
    LSinPitch := -1.0;
  LTheta := -ArcSin(Double(LSinPitch));
  LCosPitch := Cos(LTheta);
  if LCosPitch > 8192.0 * ID_FLT_EPSILON then
  begin
    Result.Pitch := LTheta * Double(ID_RAD2DEG);
    LRadians := ArcTan2(Double(AMatrix.Rows[0].Y), Double(AMatrix.Rows[0].X));
    Result.Yaw := LRadians * Double(ID_RAD2DEG);
    LRadians := ArcTan2(Double(AMatrix.Rows[1].Z), Double(AMatrix.Rows[2].Z));
    Result.Roll := LRadians * Double(ID_RAD2DEG);
  end
  else
  begin
    Result.Pitch := LTheta * Double(ID_RAD2DEG);
    LRadians := -ArcTan2(Double(AMatrix.Rows[1].X), Double(AMatrix.Rows[1].Y));
    Result.Yaw := LRadians * Double(ID_RAD2DEG);
    Result.Roll := 0;
  end;
end;

class function TIdRotationConversions.MatToQuat(const AMatrix: TIdMat3): TIdQuat;
var
  LTrace, LS, LT: Single;
  I, J, K: Integer;
begin
  LTrace := AMatrix.Rows[0].X + AMatrix.Rows[1].Y + AMatrix.Rows[2].Z;
  if LTrace > 0.0 then
  begin
    LT := LTrace + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    Result.W := LS * LT;
    Result.X := (AMatrix.Rows[2].Y - AMatrix.Rows[1].Z) * LS;
    Result.Y := (AMatrix.Rows[0].Z - AMatrix.Rows[2].X) * LS;
    Result.Z := (AMatrix.Rows[1].X - AMatrix.Rows[0].Y) * LS;
  end
  else
  begin
    I := 0;
    if AMatrix.Rows[1].Y > AMatrix.Rows[0].X then
      I := 1;
    if AMatrix.Rows[2].Z > AMatrix.Rows[I][I] then
      I := 2;
    J := NEXT_INDEX[I];
    K := NEXT_INDEX[J];
    LT := (AMatrix.Rows[I][I] - (AMatrix.Rows[J][J] + AMatrix.Rows[K][K])) + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    Result[I] := LS * LT;
    Result.W := (AMatrix.Rows[K][J] - AMatrix.Rows[J][K]) * LS;
    Result[J] := (AMatrix.Rows[J][I] + AMatrix.Rows[I][J]) * LS;
    Result[K] := (AMatrix.Rows[K][I] + AMatrix.Rows[I][K]) * LS;
  end;
end;

class function TIdRotationConversions.MatToCQuat(const AMatrix: TIdMat3): TIdCQuat;
var
  LQuat: TIdQuat;
begin
  LQuat := MatToQuat(AMatrix);
  if LQuat.W < 0.0 then
    Result := TIdCQuat.Create(-LQuat.X, -LQuat.Y, -LQuat.Z)
  else
    Result := TIdCQuat.Create(LQuat.X, LQuat.Y, LQuat.Z);
end;

class function TIdRotationConversions.MatToRotation(const AMatrix: TIdMat3): TIdRotation;
var
  LTrace, LS, LT, LAngle: Single;
  LVector: TIdVec3;
  I, J, K: Integer;
begin
  LTrace := AMatrix.Rows[0].X + AMatrix.Rows[1].Y + AMatrix.Rows[2].Z;
  if LTrace > 0.0 then
  begin
    LT := LTrace + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    LAngle := LS * LT;
    LVector.X := (AMatrix.Rows[2].Y - AMatrix.Rows[1].Z) * LS;
    LVector.Y := (AMatrix.Rows[0].Z - AMatrix.Rows[2].X) * LS;
    LVector.Z := (AMatrix.Rows[1].X - AMatrix.Rows[0].Y) * LS;
  end
  else
  begin
    I := 0;
    if AMatrix.Rows[1].Y > AMatrix.Rows[0].X then
      I := 1;
    if AMatrix.Rows[2].Z > AMatrix.Rows[I][I] then
      I := 2;
    J := NEXT_INDEX[I];
    K := NEXT_INDEX[J];
    LT := (AMatrix.Rows[I][I] - (AMatrix.Rows[J][J] + AMatrix.Rows[K][K])) + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    LVector[I] := LS * LT;
    LAngle := (AMatrix.Rows[K][J] - AMatrix.Rows[J][K]) * LS;
    LVector[J] := (AMatrix.Rows[J][I] + AMatrix.Rows[I][J]) * LS;
    LVector[K] := (AMatrix.Rows[K][I] + AMatrix.Rows[I][K]) * LS;
  end;
  LAngle := TIdMath.ACos(LAngle);
  if TIdMath.Fabs(LAngle) < Single(1E-10) then
  begin
    LVector.SetValues(0.0, 0.0, 1.0);
    LAngle := 0.0;
  end
  else
  begin
    LVector.Normalize;
    LVector.FixDegenerateNormal;
    LAngle := LAngle * (2.0 * ID_RAD2DEG);
  end;
  Result := TIdRotation.Create(TIdVec3.Create(0.0, 0.0, 0.0), LVector, LAngle);
  Result.SetCachedAxis(AMatrix);
end;

class function TIdRotationConversions.MatToAngularVelocity(const AMatrix: TIdMat3): TIdVec3;
var
  LRotation: TIdRotation;
begin
  LRotation := MatToRotation(AMatrix);
  Result := LRotation.Vector * (LRotation.Angle * ID_DEG2RAD);
end;

class function TIdRotationConversions.QuatToAngles(const AQuat: TIdQuat): TIdAngles;
begin
  Result := MatToAngles(QuatToMat(AQuat));
end;

class function TIdRotationConversions.QuatToRotation(const AQuat: TIdQuat): TIdRotation;
begin
  Result := AxisAngleFromQuat(AQuat.X, AQuat.Y, AQuat.Z, AQuat.W);
end;

class function TIdRotationConversions.QuatToMat(const AQuat: TIdQuat): TIdMat3;
var
  LWX, LWY, LWZ, LXX, LYY, LYZ, LXY, LXZ, LZZ, LX2, LY2, LZ2: Single;
begin
  LX2 := AQuat.X + AQuat.X;
  LY2 := AQuat.Y + AQuat.Y;
  LZ2 := AQuat.Z + AQuat.Z;
  LXX := AQuat.X * LX2;
  LXY := AQuat.X * LY2;
  LXZ := AQuat.X * LZ2;
  LYY := AQuat.Y * LY2;
  LYZ := AQuat.Y * LZ2;
  LZZ := AQuat.Z * LZ2;
  LWX := AQuat.W * LX2;
  LWY := AQuat.W * LY2;
  LWZ := AQuat.W * LZ2;
  Result.Rows[0].X := 1.0 - (LYY + LZZ);
  Result.Rows[0].Y := LXY - LWZ;
  Result.Rows[0].Z := LXZ + LWY;
  Result.Rows[1].X := LXY + LWZ;
  Result.Rows[1].Y := 1.0 - (LXX + LZZ);
  Result.Rows[1].Z := LYZ - LWX;
  Result.Rows[2].X := LXZ - LWY;
  Result.Rows[2].Y := LYZ + LWX;
  Result.Rows[2].Z := 1.0 - (LXX + LYY);
end;

class function TIdRotationConversions.QuatToCQuat(const AQuat: TIdQuat): TIdCQuat;
begin
  AQuat.ToCompressed(Result.X, Result.Y, Result.Z);
end;

class function TIdRotationConversions.CQuatToAngles(const ACQuat: TIdCQuat): TIdAngles;
begin
  Result := QuatToAngles(ACQuat.ToQuat);
end;

class function TIdRotationConversions.CQuatToRotation(const ACQuat: TIdCQuat): TIdRotation;
begin
  Result := QuatToRotation(ACQuat.ToQuat);
end;

class function TIdRotationConversions.CQuatToMat(const ACQuat: TIdCQuat): TIdMat3;
begin
  Result := QuatToMat(ACQuat.ToQuat);
end;

class function TIdRotationConversions.AnglesToQuat(const AAngles: TIdAngles): TIdQuat;
var
  LSX, LCX, LSY, LCY, LSZ, LCZ, LSXCY, LCXCY, LSXSY, LCXSY: Single;
begin
  TIdMath.SinCos(AAngles.Yaw * ID_DEG2RAD * 0.5, LSZ, LCZ);
  TIdMath.SinCos(AAngles.Pitch * ID_DEG2RAD * 0.5, LSY, LCY);
  TIdMath.SinCos(AAngles.Roll * ID_DEG2RAD * 0.5, LSX, LCX);
  LSXCY := LSX * LCY;
  LCXCY := LCX * LCY;
  LSXSY := LSX * LSY;
  LCXSY := LCX * LSY;
  Result.X := LCXSY * LSZ - LSXCY * LCZ;
  Result.Y := -LCXSY * LCZ - LSXCY * LSZ;
  Result.Z := LSXSY * LCZ - LCXCY * LSZ;
  Result.W := LCXCY * LCZ + LSXSY * LSZ;
end;

class function TIdRotationConversions.AnglesToRotation(const AAngles: TIdAngles): TIdRotation;
var
  LQuat: TIdQuat;
begin
  if AAngles.Pitch = 0.0 then
  begin
    if AAngles.Yaw = 0.0 then
      Exit(TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(-1.0, 0.0, 0.0), AAngles.Roll));
    if AAngles.Roll = 0.0 then
      Exit(TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0.0, 0.0, -1.0), AAngles.Yaw));
  end
  else if (AAngles.Yaw = 0.0) and (AAngles.Roll = 0.0) then
    Exit(TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0.0, -1.0, 0.0), AAngles.Pitch));
  // the same products as AnglesToQuat
  LQuat := AnglesToQuat(AAngles);
  Result := AxisAngleFromQuat(LQuat.X, LQuat.Y, LQuat.Z, LQuat.W);
end;

class function TIdRotationConversions.AnglesToMat(const AAngles: TIdAngles): TIdMat3;
var
  LSR, LSP, LSY, LCR, LCP, LCY: Single;
begin
  TIdMath.SinCos(AAngles.Yaw * ID_DEG2RAD, LSY, LCY);
  TIdMath.SinCos(AAngles.Pitch * ID_DEG2RAD, LSP, LCP);
  TIdMath.SinCos(AAngles.Roll * ID_DEG2RAD, LSR, LCR);
  Result.Rows[0].SetValues(LCP * LCY, LCP * LSY, -LSP);
  Result.Rows[1].SetValues(LSR * LSP * LCY + LCR * -LSY, LSR * LSP * LSY + LCR * LCY, LSR * LCP);
  Result.Rows[2].SetValues(LCR * LSP * LCY + -LSR * -LSY, LCR * LSP * LSY + -LSR * LCY, LCR * LCP);
end;

class function TIdRotationConversions.AnglesToAngularVelocity(const AAngles: TIdAngles): TIdVec3;
var
  LRotation: TIdRotation;
begin
  LRotation := AnglesToRotation(AAngles);
  Result := LRotation.Vector * (LRotation.Angle * ID_DEG2RAD);
end;

class function TIdRotationConversions.RotationToAngles(const ARotation: TIdRotation): TIdAngles;
var
  LCopy: TIdRotation;
begin
  LCopy := ARotation;
  Result := MatToAngles(LCopy.ToMat3);
end;

end.
