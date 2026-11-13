{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdRotation, a rotation about an    }
{  arbitrary axis                                                              }
{                                                                              }
{  Port of idRotation (idlib\math\Rotation.h and Rotation.cpp) of the Doom 3   }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Rotation;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Quat;

type
  /// <summary>
  ///   A rotation in degrees about an arbitrary axis through an origin (idRotation). The matrix
  ///   of the rotation is a cache (the <c>mutable</c> members of the original): the methods that
  ///   read it (<c>ToMat3</c>, <c>Rotate</c>, <c>RotatePoint</c>) update the record, so they need
  ///   a variable, not a constant. The axis vector has to be normalised.
  /// </summary>
  TIdRotation = record
  private
    FOrigin: TIdVec3;
    FVector: TIdVec3;
    FAngle: Single;
    FAxis: TIdMat3;
    FAxisValid: Boolean;
  public
    class function Create(const AOrigin, AVector: TIdVec3; const AAngle: Single): TIdRotation; static;
    procedure SetValues(const AOrigin, AVector: TIdVec3; const AAngle: Single);
    procedure SetOrigin(const AOrigin: TIdVec3);
    procedure SetVector(const AVector: TIdVec3); overload;
    procedure SetVector(const AX, AY, AZ: Single); overload;
    procedure SetAngle(const AAngle: Single);
    /// <summary>Stores a matrix as the cache (used by the conversion from a matrix)</summary>
    procedure SetCachedAxis(const AAxis: TIdMat3);
    procedure Scale(const AScale: Single);
    procedure ReCalculateMatrix;
    property Origin: TIdVec3 read FOrigin;
    property Vector: TIdVec3 read FVector;
    property Angle: Single read FAngle;
    property AxisValid: Boolean read FAxisValid;
    /// <summary>Flips the rotation (negates the angle)</summary>
    class operator Negative(const A: TIdRotation): TIdRotation;
    class operator Multiply(const A: TIdRotation; const B: Single): TIdRotation;
    class operator Multiply(const A: Single; const B: TIdRotation): TIdRotation;
    class operator Divide(const A: TIdRotation; const B: Single): TIdRotation;
    /// <summary>Rotates the vector; the cache is not updated (use <c>Rotate</c> in a loop)</summary>
    class operator Multiply(const A: TIdRotation; const B: TIdVec3): TIdVec3;
    /// <summary>The rotation matrix, computed and cached</summary>
    function ToMat3: TIdMat3;
    function ToQuat: TIdQuat;
    function ToAngularVelocity: TIdVec3;
    /// <summary>Rotates a point about the origin of the rotation, using the cached matrix</summary>
    function Rotate(const APoint: TIdVec3): TIdVec3;
    procedure RotatePoint(var APoint: TIdVec3);
    procedure Normalize180;
    procedure Normalize360;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdRotation }

class function TIdRotation.Create(const AOrigin, AVector: TIdVec3; const AAngle: Single): TIdRotation;
begin
  Result.SetValues(AOrigin, AVector, AAngle);
end;

procedure TIdRotation.SetValues(const AOrigin, AVector: TIdVec3; const AAngle: Single);
begin
  FOrigin := AOrigin;
  FVector := AVector;
  FAngle := AAngle;
  FAxisValid := False;
end;

procedure TIdRotation.SetOrigin(const AOrigin: TIdVec3);
begin
  FOrigin := AOrigin;
end;

procedure TIdRotation.SetVector(const AVector: TIdVec3);
begin
  FVector := AVector;
  FAxisValid := False;
end;

procedure TIdRotation.SetVector(const AX, AY, AZ: Single);
begin
  FVector.SetValues(AX, AY, AZ);
  FAxisValid := False;
end;

procedure TIdRotation.SetAngle(const AAngle: Single);
begin
  FAngle := AAngle;
  FAxisValid := False;
end;

procedure TIdRotation.SetCachedAxis(const AAxis: TIdMat3);
begin
  FAxis := AAxis;
  FAxisValid := True;
end;

procedure TIdRotation.Scale(const AScale: Single);
begin
  FAngle := FAngle * AScale;
  FAxisValid := False;
end;

procedure TIdRotation.ReCalculateMatrix;
begin
  FAxisValid := False;
  ToMat3;
end;

class operator TIdRotation.Negative(const A: TIdRotation): TIdRotation;
begin
  Result.SetValues(A.FOrigin, A.FVector, -A.FAngle);
end;

class operator TIdRotation.Multiply(const A: TIdRotation; const B: Single): TIdRotation;
begin
  Result.SetValues(A.FOrigin, A.FVector, A.FAngle * B);
end;

class operator TIdRotation.Multiply(const A: Single; const B: TIdRotation): TIdRotation;
begin
  Result.SetValues(B.FOrigin, B.FVector, B.FAngle * A);
end;

class operator TIdRotation.Divide(const A: TIdRotation; const B: Single): TIdRotation;
begin
  Result.SetValues(A.FOrigin, A.FVector, A.FAngle / B);
end;

class operator TIdRotation.Multiply(const A: TIdRotation; const B: TIdVec3): TIdVec3;
var
  LCopy: TIdRotation;
begin
  LCopy := A;
  Result := LCopy.Rotate(B);
end;

function TIdRotation.ToMat3: TIdMat3;
var
  LWX, LWY, LWZ, LXX, LYY, LYZ, LXY, LXZ, LZZ, LX2, LY2, LZ2: Single;
  LA, LC, LS, LX, LY, LZ: Single;
begin
  if FAxisValid then
    Exit(FAxis);
  LA := FAngle * (ID_DEG2RAD * 0.5);
  TIdMath.SinCos(LA, LS, LC);
  LX := FVector.X * LS;
  LY := FVector.Y * LS;
  LZ := FVector.Z * LS;
  LX2 := LX + LX;
  LY2 := LY + LY;
  LZ2 := LZ + LZ;
  LXX := LX * LX2;
  LXY := LX * LY2;
  LXZ := LX * LZ2;
  LYY := LY * LY2;
  LYZ := LY * LZ2;
  LZZ := LZ * LZ2;
  LWX := LC * LX2;
  LWY := LC * LY2;
  LWZ := LC * LZ2;
  FAxis.Rows[0].X := 1.0 - (LYY + LZZ);
  FAxis.Rows[0].Y := LXY - LWZ;
  FAxis.Rows[0].Z := LXZ + LWY;
  FAxis.Rows[1].X := LXY + LWZ;
  FAxis.Rows[1].Y := 1.0 - (LXX + LZZ);
  FAxis.Rows[1].Z := LYZ - LWX;
  FAxis.Rows[2].X := LXZ - LWY;
  FAxis.Rows[2].Y := LYZ + LWX;
  FAxis.Rows[2].Z := 1.0 - (LXX + LYY);
  FAxisValid := True;
  Result := FAxis;
end;

function TIdRotation.ToQuat: TIdQuat;
var
  LA, LS, LC: Single;
begin
  LA := FAngle * (ID_DEG2RAD * 0.5);
  TIdMath.SinCos(LA, LS, LC);
  Result.X := FVector.X * LS;
  Result.Y := FVector.Y * LS;
  Result.Z := FVector.Z * LS;
  Result.W := LC;
end;

function TIdRotation.ToAngularVelocity: TIdVec3;
begin
  Result := FVector * (FAngle * ID_DEG2RAD);
end;

function TIdRotation.Rotate(const APoint: TIdVec3): TIdVec3;
begin
  if not FAxisValid then
    ToMat3;
  Result := (APoint - FOrigin) * FAxis + FOrigin;
end;

procedure TIdRotation.RotatePoint(var APoint: TIdVec3);
begin
  APoint := Rotate(APoint);
end;

procedure TIdRotation.Normalize180;
begin
  FAngle := FAngle - TIdMath.Floor(FAngle / 360.0) * 360.0;
  if FAngle > 180.0 then
    FAngle := FAngle - 360.0
  else if FAngle < -180.0 then
    FAngle := FAngle + 360.0;
end;

procedure TIdRotation.Normalize360;
begin
  FAngle := FAngle - TIdMath.Floor(FAngle / 360.0) * 360.0;
  if FAngle > 360.0 then
    FAngle := FAngle - 360.0
  else if FAngle < 0.0 then
    FAngle := FAngle + 360.0;
end;

end.
