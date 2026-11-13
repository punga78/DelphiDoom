{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the matrix of a joint (3x4)            }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\geometry\          }
{  JointTransform.h and JointTransform.cpp (idJointMat). Copyright (C)         }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.JointMat;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.Models.Md5.JointQuat;

type
  /// <summary>
  ///   A joint transform of 3x4 floats (idJointMat): rotation in the first three columns, in
  ///   the layout <c>M[row * 4 + column]</c> (the transpose of idMat3, which is stored by rows of
  ///   the other convention), translation in the fourth column. The operations are the ones of the
  ///   original with the same order of the operations, quirks included (see TransformBy).
  /// </summary>
  TMd5JointMat = record
    M: array[0..11] of Single;
    /// <summary>idJointMat::SetRotation (the idMat3 is transposed)</summary>
    procedure SetRotation(const AMatrix: TIdMat3);
    /// <summary>idJointMat::SetTranslation</summary>
    procedure SetTranslation(const ATranslation: TIdVec3);
    /// <summary>idJointMat::operator*(idVec3): rotate only</summary>
    function Rotate(const AVector: TIdVec3): TIdVec3;
    /// <summary>idJointMat::operator*(idVec4): rotate and translate (the weight scales the translation)</summary>
    function Apply(const AVector: TIdVec4): TIdVec3;
    /// <summary>
    ///   idJointMat::operator*=: the transform by the (parent) matrix A, as the original
    ///   writes it: every element is a row of this by a column of A, then A's translation is added
    /// </summary>
    procedure TransformBy(const A: TMd5JointMat);
    /// <summary>idJointMat::operator/=: the inverse of TransformBy</summary>
    procedure UntransformBy(const A: TMd5JointMat);
    /// <summary>idJointMat::Compare with epsilon</summary>
    function Compare(const A: TMd5JointMat; const AEpsilon: Single): Boolean;
    /// <summary>idJointMat::ToMat3</summary>
    function ToMat3: TIdMat3;
    /// <summary>idJointMat::ToVec3: the translation</summary>
    function ToVec3: TIdVec3;
    /// <summary>idJointMat::ToJointQuat</summary>
    function ToJointQuat: TMd5JointQuat;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TMd5JointMat }

procedure TMd5JointMat.SetRotation(const AMatrix: TIdMat3);
begin
  M[0 * 4 + 0] := AMatrix.Rows[0].X;
  M[0 * 4 + 1] := AMatrix.Rows[1].X;
  M[0 * 4 + 2] := AMatrix.Rows[2].X;
  M[1 * 4 + 0] := AMatrix.Rows[0].Y;
  M[1 * 4 + 1] := AMatrix.Rows[1].Y;
  M[1 * 4 + 2] := AMatrix.Rows[2].Y;
  M[2 * 4 + 0] := AMatrix.Rows[0].Z;
  M[2 * 4 + 1] := AMatrix.Rows[1].Z;
  M[2 * 4 + 2] := AMatrix.Rows[2].Z;
end;

procedure TMd5JointMat.SetTranslation(const ATranslation: TIdVec3);
begin
  M[0 * 4 + 3] := ATranslation.X;
  M[1 * 4 + 3] := ATranslation.Y;
  M[2 * 4 + 3] := ATranslation.Z;
end;

function TMd5JointMat.Rotate(const AVector: TIdVec3): TIdVec3;
begin
  Result.X := M[0 * 4 + 0] * AVector.X + M[0 * 4 + 1] * AVector.Y + M[0 * 4 + 2] * AVector.Z;
  Result.Y := M[1 * 4 + 0] * AVector.X + M[1 * 4 + 1] * AVector.Y + M[1 * 4 + 2] * AVector.Z;
  Result.Z := M[2 * 4 + 0] * AVector.X + M[2 * 4 + 1] * AVector.Y + M[2 * 4 + 2] * AVector.Z;
end;

function TMd5JointMat.Apply(const AVector: TIdVec4): TIdVec3;
begin
  Result.X := M[0 * 4 + 0] * AVector.X + M[0 * 4 + 1] * AVector.Y + M[0 * 4 + 2] * AVector.Z +
    M[0 * 4 + 3] * AVector.W;
  Result.Y := M[1 * 4 + 0] * AVector.X + M[1 * 4 + 1] * AVector.Y + M[1 * 4 + 2] * AVector.Z +
    M[1 * 4 + 3] * AVector.W;
  Result.Z := M[2 * 4 + 0] * AVector.X + M[2 * 4 + 1] * AVector.Y + M[2 * 4 + 2] * AVector.Z +
    M[2 * 4 + 3] * AVector.W;
end;

procedure TMd5JointMat.TransformBy(const A: TMd5JointMat);
var
  LD0, LD1, LD2: Single;
begin
  LD0 := M[0 * 4 + 0] * A.M[0 * 4 + 0] + M[1 * 4 + 0] * A.M[0 * 4 + 1] + M[2 * 4 + 0] * A.M[0 * 4 + 2];
  LD1 := M[0 * 4 + 0] * A.M[1 * 4 + 0] + M[1 * 4 + 0] * A.M[1 * 4 + 1] + M[2 * 4 + 0] * A.M[1 * 4 + 2];
  LD2 := M[0 * 4 + 0] * A.M[2 * 4 + 0] + M[1 * 4 + 0] * A.M[2 * 4 + 1] + M[2 * 4 + 0] * A.M[2 * 4 + 2];
  M[0 * 4 + 0] := LD0;
  M[1 * 4 + 0] := LD1;
  M[2 * 4 + 0] := LD2;

  LD0 := M[0 * 4 + 1] * A.M[0 * 4 + 0] + M[1 * 4 + 1] * A.M[0 * 4 + 1] + M[2 * 4 + 1] * A.M[0 * 4 + 2];
  LD1 := M[0 * 4 + 1] * A.M[1 * 4 + 0] + M[1 * 4 + 1] * A.M[1 * 4 + 1] + M[2 * 4 + 1] * A.M[1 * 4 + 2];
  LD2 := M[0 * 4 + 1] * A.M[2 * 4 + 0] + M[1 * 4 + 1] * A.M[2 * 4 + 1] + M[2 * 4 + 1] * A.M[2 * 4 + 2];
  M[0 * 4 + 1] := LD0;
  M[1 * 4 + 1] := LD1;
  M[2 * 4 + 1] := LD2;

  LD0 := M[0 * 4 + 2] * A.M[0 * 4 + 0] + M[1 * 4 + 2] * A.M[0 * 4 + 1] + M[2 * 4 + 2] * A.M[0 * 4 + 2];
  LD1 := M[0 * 4 + 2] * A.M[1 * 4 + 0] + M[1 * 4 + 2] * A.M[1 * 4 + 1] + M[2 * 4 + 2] * A.M[1 * 4 + 2];
  LD2 := M[0 * 4 + 2] * A.M[2 * 4 + 0] + M[1 * 4 + 2] * A.M[2 * 4 + 1] + M[2 * 4 + 2] * A.M[2 * 4 + 2];
  M[0 * 4 + 2] := LD0;
  M[1 * 4 + 2] := LD1;
  M[2 * 4 + 2] := LD2;

  LD0 := M[0 * 4 + 3] * A.M[0 * 4 + 0] + M[1 * 4 + 3] * A.M[0 * 4 + 1] + M[2 * 4 + 3] * A.M[0 * 4 + 2];
  LD1 := M[0 * 4 + 3] * A.M[1 * 4 + 0] + M[1 * 4 + 3] * A.M[1 * 4 + 1] + M[2 * 4 + 3] * A.M[1 * 4 + 2];
  LD2 := M[0 * 4 + 3] * A.M[2 * 4 + 0] + M[1 * 4 + 3] * A.M[2 * 4 + 1] + M[2 * 4 + 3] * A.M[2 * 4 + 2];
  M[0 * 4 + 3] := LD0;
  M[1 * 4 + 3] := LD1;
  M[2 * 4 + 3] := LD2;

  M[0 * 4 + 3] := M[0 * 4 + 3] + A.M[0 * 4 + 3];
  M[1 * 4 + 3] := M[1 * 4 + 3] + A.M[1 * 4 + 3];
  M[2 * 4 + 3] := M[2 * 4 + 3] + A.M[2 * 4 + 3];
end;

procedure TMd5JointMat.UntransformBy(const A: TMd5JointMat);
var
  LD0, LD1, LD2: Single;
begin
  M[0 * 4 + 3] := M[0 * 4 + 3] - A.M[0 * 4 + 3];
  M[1 * 4 + 3] := M[1 * 4 + 3] - A.M[1 * 4 + 3];
  M[2 * 4 + 3] := M[2 * 4 + 3] - A.M[2 * 4 + 3];

  LD0 := M[0 * 4 + 0] * A.M[0 * 4 + 0] + M[1 * 4 + 0] * A.M[1 * 4 + 0] + M[2 * 4 + 0] * A.M[2 * 4 + 0];
  LD1 := M[0 * 4 + 0] * A.M[0 * 4 + 1] + M[1 * 4 + 0] * A.M[1 * 4 + 1] + M[2 * 4 + 0] * A.M[2 * 4 + 1];
  LD2 := M[0 * 4 + 0] * A.M[0 * 4 + 2] + M[1 * 4 + 0] * A.M[1 * 4 + 2] + M[2 * 4 + 0] * A.M[2 * 4 + 2];
  M[0 * 4 + 0] := LD0;
  M[1 * 4 + 0] := LD1;
  M[2 * 4 + 0] := LD2;

  LD0 := M[0 * 4 + 1] * A.M[0 * 4 + 0] + M[1 * 4 + 1] * A.M[1 * 4 + 0] + M[2 * 4 + 1] * A.M[2 * 4 + 0];
  LD1 := M[0 * 4 + 1] * A.M[0 * 4 + 1] + M[1 * 4 + 1] * A.M[1 * 4 + 1] + M[2 * 4 + 1] * A.M[2 * 4 + 1];
  LD2 := M[0 * 4 + 1] * A.M[0 * 4 + 2] + M[1 * 4 + 1] * A.M[1 * 4 + 2] + M[2 * 4 + 1] * A.M[2 * 4 + 2];
  M[0 * 4 + 1] := LD0;
  M[1 * 4 + 1] := LD1;
  M[2 * 4 + 1] := LD2;

  LD0 := M[0 * 4 + 2] * A.M[0 * 4 + 0] + M[1 * 4 + 2] * A.M[1 * 4 + 0] + M[2 * 4 + 2] * A.M[2 * 4 + 0];
  LD1 := M[0 * 4 + 2] * A.M[0 * 4 + 1] + M[1 * 4 + 2] * A.M[1 * 4 + 1] + M[2 * 4 + 2] * A.M[2 * 4 + 1];
  LD2 := M[0 * 4 + 2] * A.M[0 * 4 + 2] + M[1 * 4 + 2] * A.M[1 * 4 + 2] + M[2 * 4 + 2] * A.M[2 * 4 + 2];
  M[0 * 4 + 2] := LD0;
  M[1 * 4 + 2] := LD1;
  M[2 * 4 + 2] := LD2;

  LD0 := M[0 * 4 + 3] * A.M[0 * 4 + 0] + M[1 * 4 + 3] * A.M[1 * 4 + 0] + M[2 * 4 + 3] * A.M[2 * 4 + 0];
  LD1 := M[0 * 4 + 3] * A.M[0 * 4 + 1] + M[1 * 4 + 3] * A.M[1 * 4 + 1] + M[2 * 4 + 3] * A.M[2 * 4 + 1];
  LD2 := M[0 * 4 + 3] * A.M[0 * 4 + 2] + M[1 * 4 + 3] * A.M[1 * 4 + 2] + M[2 * 4 + 3] * A.M[2 * 4 + 2];
  M[0 * 4 + 3] := LD0;
  M[1 * 4 + 3] := LD1;
  M[2 * 4 + 3] := LD2;
end;

function TMd5JointMat.Compare(const A: TMd5JointMat; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 11 do
    if TIdMath.Fabs(M[LIndex] - A.M[LIndex]) > AEpsilon then
      Exit(False);
  Result := True;
end;

function TMd5JointMat.ToMat3: TIdMat3;
begin
  Result := TIdMat3.Create(
    M[0 * 4 + 0], M[1 * 4 + 0], M[2 * 4 + 0],
    M[0 * 4 + 1], M[1 * 4 + 1], M[2 * 4 + 1],
    M[0 * 4 + 2], M[1 * 4 + 2], M[2 * 4 + 2]);
end;

function TMd5JointMat.ToVec3: TIdVec3;
begin
  Result := TIdVec3.Create(M[0 * 4 + 3], M[1 * 4 + 3], M[2 * 4 + 3]);
end;

function TMd5JointMat.ToJointQuat: TMd5JointQuat;
const
  NEXT: array[0..2] of Integer = (1, 2, 0);
var
  LTrace, LS, LT: Single;
  LI, LJ, LK: Integer;
begin
  LTrace := M[0 * 4 + 0] + M[1 * 4 + 1] + M[2 * 4 + 2];
  if LTrace > 0.0 then
  begin
    LT := LTrace + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    Result.Q.W := LS * LT;
    Result.Q.X := (M[1 * 4 + 2] - M[2 * 4 + 1]) * LS;
    Result.Q.Y := (M[2 * 4 + 0] - M[0 * 4 + 2]) * LS;
    Result.Q.Z := (M[0 * 4 + 1] - M[1 * 4 + 0]) * LS;
  end
  else
  begin
    LI := 0;
    if M[1 * 4 + 1] > M[0 * 4 + 0] then
      LI := 1;
    if M[2 * 4 + 2] > M[LI * 4 + LI] then
      LI := 2;
    LJ := NEXT[LI];
    LK := NEXT[LJ];
    LT := (M[LI * 4 + LI] - (M[LJ * 4 + LJ] + M[LK * 4 + LK])) + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    Result.Q[LI] := LS * LT;
    Result.Q.W := (M[LJ * 4 + LK] - M[LK * 4 + LJ]) * LS;
    Result.Q[LJ] := (M[LI * 4 + LJ] + M[LJ * 4 + LI]) * LS;
    Result.Q[LK] := (M[LI * 4 + LK] + M[LK * 4 + LI]) * LS;
  end;
  Result.T := TIdVec3.Create(M[0 * 4 + 3], M[1 * 4 + 3], M[2 * 4 + 3]);
end;

end.
