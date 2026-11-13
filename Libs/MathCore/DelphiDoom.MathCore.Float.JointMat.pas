{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdJointMat, the joint matrix       }
{                                                                              }
{  Port of idJointMat (idlib\geometry\JointTransform.h and .cpp) of the        }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.JointMat;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.MathCore.Float.JointQuat;

type
  /// <summary>
  ///   A 3x4 joint transform stored as 12 Singles, three rows of four (idJointMat), 48 bytes: the
  ///   rotation (transposed with respect to <c>TIdMat3</c>) in the first three columns and the
  ///   translation in the last. Not zeroed on creation: use <c>Zero</c> or set the parts.
  /// </summary>
  TIdJointMat = record
    Mat: array[0..11] of Single;
  public
    procedure Zero;
    /// <summary>Stores the transpose of the matrix (idMat3 is stored by rows, the joint by columns)</summary>
    procedure SetRotation(const AMatrix: TIdMat3);
    procedure SetTranslation(const ATranslation: TIdVec3);
    /// <summary>Rotates only (idJointMat::operator* with a vec3)</summary>
    function Rotate(const AVector: TIdVec3): TIdVec3;
    /// <summary>Rotates and translates; W scales the translation (operator* with a vec4)</summary>
    function Transform(const AVector: TIdVec4): TIdVec3;
    /// <summary>Concatenates a joint transform after this one (operator*=)</summary>
    procedure MultiplySelf(const AOther: TIdJointMat);
    /// <summary>Removes a joint transform from this one (operator/=)</summary>
    procedure DivideSelf(const AOther: TIdJointMat);
    /// <summary>Exact comparison</summary>
    function Compare(const AOther: TIdJointMat): Boolean; overload;
    function Compare(const AOther: TIdJointMat; const AEpsilon: Single): Boolean; overload;
    function ToMat3: TIdMat3;
    function ToVec3: TIdVec3;
    function ToJointQuat: TIdJointQuat;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdJointMat }

procedure TIdJointMat.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 11 do
    Mat[LIndex] := 0;
end;

procedure TIdJointMat.SetRotation(const AMatrix: TIdMat3);
var
  LRow, LColumn: Integer;
begin
  // NOTE: idMat3 is transposed because it is column-major
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
      Mat[LRow * 4 + LColumn] := AMatrix.Rows[LColumn][LRow];
end;

procedure TIdJointMat.SetTranslation(const ATranslation: TIdVec3);
begin
  Mat[0 * 4 + 3] := ATranslation.X;
  Mat[1 * 4 + 3] := ATranslation.Y;
  Mat[2 * 4 + 3] := ATranslation.Z;
end;

function TIdJointMat.Rotate(const AVector: TIdVec3): TIdVec3;
begin
  Result.X := Mat[0 * 4 + 0] * AVector.X + Mat[0 * 4 + 1] * AVector.Y + Mat[0 * 4 + 2] * AVector.Z;
  Result.Y := Mat[1 * 4 + 0] * AVector.X + Mat[1 * 4 + 1] * AVector.Y + Mat[1 * 4 + 2] * AVector.Z;
  Result.Z := Mat[2 * 4 + 0] * AVector.X + Mat[2 * 4 + 1] * AVector.Y + Mat[2 * 4 + 2] * AVector.Z;
end;

function TIdJointMat.Transform(const AVector: TIdVec4): TIdVec3;
begin
  Result.X := Mat[0 * 4 + 0] * AVector.X + Mat[0 * 4 + 1] * AVector.Y + Mat[0 * 4 + 2] * AVector.Z +
    Mat[0 * 4 + 3] * AVector.W;
  Result.Y := Mat[1 * 4 + 0] * AVector.X + Mat[1 * 4 + 1] * AVector.Y + Mat[1 * 4 + 2] * AVector.Z +
    Mat[1 * 4 + 3] * AVector.W;
  Result.Z := Mat[2 * 4 + 0] * AVector.X + Mat[2 * 4 + 1] * AVector.Y + Mat[2 * 4 + 2] * AVector.Z +
    Mat[2 * 4 + 3] * AVector.W;
end;

procedure TIdJointMat.MultiplySelf(const AOther: TIdJointMat);
var
  LDst: array[0..2] of Single;
  LColumn: Integer;
begin
  // the same pattern for the three rotation columns and for the translation column
  for LColumn := 0 to 3 do
  begin
    LDst[0] := Mat[0 * 4 + LColumn] * AOther.Mat[0 * 4 + 0] + Mat[1 * 4 + LColumn] * AOther.Mat[0 * 4 + 1] +
      Mat[2 * 4 + LColumn] * AOther.Mat[0 * 4 + 2];
    LDst[1] := Mat[0 * 4 + LColumn] * AOther.Mat[1 * 4 + 0] + Mat[1 * 4 + LColumn] * AOther.Mat[1 * 4 + 1] +
      Mat[2 * 4 + LColumn] * AOther.Mat[1 * 4 + 2];
    LDst[2] := Mat[0 * 4 + LColumn] * AOther.Mat[2 * 4 + 0] + Mat[1 * 4 + LColumn] * AOther.Mat[2 * 4 + 1] +
      Mat[2 * 4 + LColumn] * AOther.Mat[2 * 4 + 2];
    Mat[0 * 4 + LColumn] := LDst[0];
    Mat[1 * 4 + LColumn] := LDst[1];
    Mat[2 * 4 + LColumn] := LDst[2];
  end;
  Mat[0 * 4 + 3] := Mat[0 * 4 + 3] + AOther.Mat[0 * 4 + 3];
  Mat[1 * 4 + 3] := Mat[1 * 4 + 3] + AOther.Mat[1 * 4 + 3];
  Mat[2 * 4 + 3] := Mat[2 * 4 + 3] + AOther.Mat[2 * 4 + 3];
end;

procedure TIdJointMat.DivideSelf(const AOther: TIdJointMat);
var
  LDst: array[0..2] of Single;
  LColumn: Integer;
begin
  Mat[0 * 4 + 3] := Mat[0 * 4 + 3] - AOther.Mat[0 * 4 + 3];
  Mat[1 * 4 + 3] := Mat[1 * 4 + 3] - AOther.Mat[1 * 4 + 3];
  Mat[2 * 4 + 3] := Mat[2 * 4 + 3] - AOther.Mat[2 * 4 + 3];
  for LColumn := 0 to 3 do
  begin
    LDst[0] := Mat[0 * 4 + LColumn] * AOther.Mat[0 * 4 + 0] + Mat[1 * 4 + LColumn] * AOther.Mat[1 * 4 + 0] +
      Mat[2 * 4 + LColumn] * AOther.Mat[2 * 4 + 0];
    LDst[1] := Mat[0 * 4 + LColumn] * AOther.Mat[0 * 4 + 1] + Mat[1 * 4 + LColumn] * AOther.Mat[1 * 4 + 1] +
      Mat[2 * 4 + LColumn] * AOther.Mat[2 * 4 + 1];
    LDst[2] := Mat[0 * 4 + LColumn] * AOther.Mat[0 * 4 + 2] + Mat[1 * 4 + LColumn] * AOther.Mat[1 * 4 + 2] +
      Mat[2 * 4 + LColumn] * AOther.Mat[2 * 4 + 2];
    Mat[0 * 4 + LColumn] := LDst[0];
    Mat[1 * 4 + LColumn] := LDst[1];
    Mat[2 * 4 + LColumn] := LDst[2];
  end;
end;

function TIdJointMat.Compare(const AOther: TIdJointMat): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 11 do
    if Mat[LIndex] <> AOther.Mat[LIndex] then
      Exit(False);
  Result := True;
end;

function TIdJointMat.Compare(const AOther: TIdJointMat; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 11 do
    if TIdMath.Fabs(Mat[LIndex] - AOther.Mat[LIndex]) > AEpsilon then
      Exit(False);
  Result := True;
end;

function TIdJointMat.ToMat3: TIdMat3;
begin
  Result := TIdMat3.Create(Mat[0 * 4 + 0], Mat[1 * 4 + 0], Mat[2 * 4 + 0],
    Mat[0 * 4 + 1], Mat[1 * 4 + 1], Mat[2 * 4 + 1],
    Mat[0 * 4 + 2], Mat[1 * 4 + 2], Mat[2 * 4 + 2]);
end;

function TIdJointMat.ToVec3: TIdVec3;
begin
  Result := TIdVec3.Create(Mat[0 * 4 + 3], Mat[1 * 4 + 3], Mat[2 * 4 + 3]);
end;

function TIdJointMat.ToJointQuat: TIdJointQuat;
const
  NEXT: array[0..2] of Integer = (1, 2, 0);
var
  LTrace, LS, LT: Single;
  LI, LJ, LK: Integer;
begin
  LTrace := Mat[0 * 4 + 0] + Mat[1 * 4 + 1] + Mat[2 * 4 + 2];
  if LTrace > 0 then
  begin
    LT := LTrace + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    Result.Q.W := LS * LT;
    Result.Q.X := (Mat[1 * 4 + 2] - Mat[2 * 4 + 1]) * LS;
    Result.Q.Y := (Mat[2 * 4 + 0] - Mat[0 * 4 + 2]) * LS;
    Result.Q.Z := (Mat[0 * 4 + 1] - Mat[1 * 4 + 0]) * LS;
  end
  else
  begin
    LI := 0;
    if Mat[1 * 4 + 1] > Mat[0 * 4 + 0] then
      LI := 1;
    if Mat[2 * 4 + 2] > Mat[LI * 4 + LI] then
      LI := 2;
    LJ := NEXT[LI];
    LK := NEXT[LJ];
    LT := (Mat[LI * 4 + LI] - (Mat[LJ * 4 + LJ] + Mat[LK * 4 + LK])) + 1.0;
    LS := TIdMath.InvSqrt(LT) * 0.5;
    Result.Q[LI] := LS * LT;
    Result.Q.W := (Mat[LJ * 4 + LK] - Mat[LK * 4 + LJ]) * LS;
    Result.Q[LJ] := (Mat[LI * 4 + LJ] + Mat[LJ * 4 + LI]) * LS;
    Result.Q[LK] := (Mat[LI * 4 + LK] + Mat[LK * 4 + LI]) * LS;
  end;
  Result.T.X := Mat[0 * 4 + 3];
  Result.T.Y := Mat[1 * 4 + 3];
  Result.T.Z := Mat[2 * 4 + 3];
end;

end.
