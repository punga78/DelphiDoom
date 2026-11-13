{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMat3, the 3x3 matrix            }
{                                                                              }
{  Port of idMat3 (idlib\math\Matrix.h and Matrix.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Mat3;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>MATRIX_INVERSE_EPSILON: a determinant smaller than this is taken as zero</summary>
  MAT_INVERSE_EPSILON = 1E-14;
  /// <summary>MATRIX_EPSILON, the default tolerance of the Is... tests</summary>
  MAT_EPSILON = 1E-6;

type
  /// <summary>
  ///   A 3x3 matrix of Single stored by rows (idMat3), 36 bytes. As in idTech 4 the matrix times
  ///   a vector uses the columns of the rows (M*v = row0*x + row1*y + row2*z) and
  ///   <c>vector * matrix</c> is the same product, not the row vector product. The conversions to
  ///   angles, quaternion and rotation are in <c>TIdRotationConversions</c>.
  /// </summary>
  TIdMat3 = record
    Rows: array[0..2] of TIdVec3;
  public
    class function Create(const AX, AY, AZ: TIdVec3): TIdMat3; overload; static;
    class function Create(const AXX, AXY, AXZ, AYX, AYY, AYZ, AZX, AZY, AZZ: Single): TIdMat3;
      overload; static;
    class function Identity: TIdMat3; static;
    /// <summary>The matrix of the cross product with the vector (SkewSymmetric)</summary>
    class function SkewSymmetric(const ASource: TIdVec3): TIdMat3; static;
    class operator Negative(const A: TIdMat3): TIdMat3;
    class operator Add(const A, B: TIdMat3): TIdMat3;
    class operator Subtract(const A, B: TIdMat3): TIdMat3;
    class operator Multiply(const A, B: TIdMat3): TIdMat3;
    class operator Multiply(const A: TIdMat3; const B: TIdVec3): TIdVec3;
    class operator Multiply(const A: TIdVec3; const B: TIdMat3): TIdVec3;
    class operator Multiply(const A: TIdMat3; const B: Single): TIdMat3;
    class operator Multiply(const A: Single; const B: TIdMat3): TIdMat3;
    class operator Equal(const A, B: TIdMat3): Boolean;
    class operator NotEqual(const A, B: TIdMat3): Boolean;
    function Compare(const A: TIdMat3; const AEpsilon: Single): Boolean;
    procedure Zero;
    procedure SetIdentity;
    function IsIdentity(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsSymmetric(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    /// <summary>True when the matrix is not exactly the identity</summary>
    function IsRotated: Boolean;
    procedure ProjectVector(const ASource: TIdVec3; out ADestination: TIdVec3);
    procedure UnprojectVector(const ASource: TIdVec3; out ADestination: TIdVec3);
    function FixDegeneracies: Boolean;
    function FixDenormals: Boolean;
    function Trace: Single;
    function Determinant: Single;
    function OrthoNormalize: TIdMat3;
    procedure OrthoNormalizeSelf;
    function Transpose: TIdMat3;
    procedure TransposeSelf;
    function Inverse: TIdMat3;
    /// <summary>Inverts in place; false (and no change) if the determinant is almost zero</summary>
    function InverseSelf: Boolean;
    function InverseFast: TIdMat3;
    function InverseFastSelf: Boolean;
    /// <summary>this transposed times B</summary>
    function TransposeMultiply(const B: TIdMat3): TIdMat3;
    function InertiaTranslate(const AMass: Single; const ACenterOfMass, ATranslation: TIdVec3): TIdMat3;
    procedure InertiaTranslateSelf(const AMass: Single; const ACenterOfMass, ATranslation: TIdVec3);
    function InertiaRotate(const ARotation: TIdMat3): TIdMat3;
    procedure InertiaRotateSelf(const ARotation: TIdMat3);
    function GetDimension: Integer;
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdMat3 }

class function TIdMat3.Create(const AX, AY, AZ: TIdVec3): TIdMat3;
begin
  Result.Rows[0] := AX;
  Result.Rows[1] := AY;
  Result.Rows[2] := AZ;
end;

class function TIdMat3.Create(const AXX, AXY, AXZ, AYX, AYY, AYZ, AZX, AZY, AZZ: Single): TIdMat3;
begin
  Result.Rows[0].SetValues(AXX, AXY, AXZ);
  Result.Rows[1].SetValues(AYX, AYY, AYZ);
  Result.Rows[2].SetValues(AZX, AZY, AZZ);
end;

class function TIdMat3.Identity: TIdMat3;
begin
  Result := Create(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
end;

class function TIdMat3.SkewSymmetric(const ASource: TIdVec3): TIdMat3;
begin
  Result := Create(0.0, -ASource.Z, ASource.Y, ASource.Z, 0.0, -ASource.X, -ASource.Y, ASource.X, 0.0);
end;

class operator TIdMat3.Negative(const A: TIdMat3): TIdMat3;
begin
  Result := Create(
    -A.Rows[0].X, -A.Rows[0].Y, -A.Rows[0].Z,
    -A.Rows[1].X, -A.Rows[1].Y, -A.Rows[1].Z,
    -A.Rows[2].X, -A.Rows[2].Y, -A.Rows[2].Z);
end;

class operator TIdMat3.Add(const A, B: TIdMat3): TIdMat3;
begin
  Result := Create(
    A.Rows[0].X + B.Rows[0].X, A.Rows[0].Y + B.Rows[0].Y, A.Rows[0].Z + B.Rows[0].Z,
    A.Rows[1].X + B.Rows[1].X, A.Rows[1].Y + B.Rows[1].Y, A.Rows[1].Z + B.Rows[1].Z,
    A.Rows[2].X + B.Rows[2].X, A.Rows[2].Y + B.Rows[2].Y, A.Rows[2].Z + B.Rows[2].Z);
end;

class operator TIdMat3.Subtract(const A, B: TIdMat3): TIdMat3;
begin
  Result := Create(
    A.Rows[0].X - B.Rows[0].X, A.Rows[0].Y - B.Rows[0].Y, A.Rows[0].Z - B.Rows[0].Z,
    A.Rows[1].X - B.Rows[1].X, A.Rows[1].Y - B.Rows[1].Y, A.Rows[1].Z - B.Rows[1].Z,
    A.Rows[2].X - B.Rows[2].X, A.Rows[2].Y - B.Rows[2].Y, A.Rows[2].Z - B.Rows[2].Z);
end;

class operator TIdMat3.Multiply(const A, B: TIdMat3): TIdMat3;
var
  LRow, LColumn: Integer;
  LDestination: TIdMat3;
begin
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
      LDestination.Rows[LRow][LColumn] :=
        A.Rows[LRow].X * B.Rows[0][LColumn] +
        A.Rows[LRow].Y * B.Rows[1][LColumn] +
        A.Rows[LRow].Z * B.Rows[2][LColumn];
  Result := LDestination;
end;

class operator TIdMat3.Multiply(const A: TIdMat3; const B: TIdVec3): TIdVec3;
begin
  Result.X := A.Rows[0].X * B.X + A.Rows[1].X * B.Y + A.Rows[2].X * B.Z;
  Result.Y := A.Rows[0].Y * B.X + A.Rows[1].Y * B.Y + A.Rows[2].Y * B.Z;
  Result.Z := A.Rows[0].Z * B.X + A.Rows[1].Z * B.Y + A.Rows[2].Z * B.Z;
end;

class operator TIdMat3.Multiply(const A: TIdVec3; const B: TIdMat3): TIdVec3;
begin
  Result := B * A;
end;

class operator TIdMat3.Multiply(const A: TIdMat3; const B: Single): TIdMat3;
begin
  Result := Create(
    A.Rows[0].X * B, A.Rows[0].Y * B, A.Rows[0].Z * B,
    A.Rows[1].X * B, A.Rows[1].Y * B, A.Rows[1].Z * B,
    A.Rows[2].X * B, A.Rows[2].Y * B, A.Rows[2].Z * B);
end;

class operator TIdMat3.Multiply(const A: Single; const B: TIdMat3): TIdMat3;
begin
  Result := B * A;
end;

class operator TIdMat3.Equal(const A, B: TIdMat3): Boolean;
begin
  Result := (A.Rows[0] = B.Rows[0]) and (A.Rows[1] = B.Rows[1]) and (A.Rows[2] = B.Rows[2]);
end;

class operator TIdMat3.NotEqual(const A, B: TIdMat3): Boolean;
begin
  Result := not (A = B);
end;

function TIdMat3.Compare(const A: TIdMat3; const AEpsilon: Single): Boolean;
begin
  Result := Rows[0].Compare(A.Rows[0], AEpsilon) and Rows[1].Compare(A.Rows[1], AEpsilon) and
    Rows[2].Compare(A.Rows[2], AEpsilon);
end;

procedure TIdMat3.Zero;
begin
  Rows[0].Zero;
  Rows[1].Zero;
  Rows[2].Zero;
end;

procedure TIdMat3.SetIdentity;
begin
  Self := Identity;
end;

function TIdMat3.IsIdentity(const AEpsilon: Single): Boolean;
begin
  Result := Compare(Identity, AEpsilon);
end;

function TIdMat3.IsSymmetric(const AEpsilon: Single): Boolean;
begin
  Result := False;
  if TIdMath.Fabs(Rows[0].Y - Rows[1].X) > AEpsilon then
    Exit;
  if TIdMath.Fabs(Rows[0].Z - Rows[2].X) > AEpsilon then
    Exit;
  if TIdMath.Fabs(Rows[1].Z - Rows[2].Y) > AEpsilon then
    Exit;
  Result := True;
end;

function TIdMat3.IsDiagonal(const AEpsilon: Single): Boolean;
begin
  Result := not ((TIdMath.Fabs(Rows[0].Y) > AEpsilon) or (TIdMath.Fabs(Rows[0].Z) > AEpsilon) or
    (TIdMath.Fabs(Rows[1].X) > AEpsilon) or (TIdMath.Fabs(Rows[1].Z) > AEpsilon) or
    (TIdMath.Fabs(Rows[2].X) > AEpsilon) or (TIdMath.Fabs(Rows[2].Y) > AEpsilon));
end;

function TIdMat3.IsRotated: Boolean;
begin
  Result := not (Self = Identity);
end;

procedure TIdMat3.ProjectVector(const ASource: TIdVec3; out ADestination: TIdVec3);
begin
  ADestination.X := ASource * Rows[0];
  ADestination.Y := ASource * Rows[1];
  ADestination.Z := ASource * Rows[2];
end;

procedure TIdMat3.UnprojectVector(const ASource: TIdVec3; out ADestination: TIdVec3);
begin
  ADestination := Rows[0] * ASource.X + Rows[1] * ASource.Y + Rows[2] * ASource.Z;
end;

function TIdMat3.FixDegeneracies: Boolean;
begin
  Result := Rows[0].FixDegenerateNormal;
  if Rows[1].FixDegenerateNormal then
    Result := True;
  if Rows[2].FixDegenerateNormal then
    Result := True;
end;

function TIdMat3.FixDenormals: Boolean;
begin
  Result := Rows[0].FixDenormals;
  if Rows[1].FixDenormals then
    Result := True;
  if Rows[2].FixDenormals then
    Result := True;
end;

function TIdMat3.Trace: Single;
begin
  Result := Rows[0].X + Rows[1].Y + Rows[2].Z;
end;

function TIdMat3.Determinant: Single;
var
  LDet2_12_01, LDet2_12_02, LDet2_12_12: Single;
begin
  LDet2_12_01 := Rows[1].X * Rows[2].Y - Rows[1].Y * Rows[2].X;
  LDet2_12_02 := Rows[1].X * Rows[2].Z - Rows[1].Z * Rows[2].X;
  LDet2_12_12 := Rows[1].Y * Rows[2].Z - Rows[1].Z * Rows[2].Y;
  Result := Rows[0].X * LDet2_12_12 - Rows[0].Y * LDet2_12_02 + Rows[0].Z * LDet2_12_01;
end;

function TIdMat3.OrthoNormalize: TIdMat3;
begin
  Result := Self;
  Result.Rows[0].Normalize;
  Result.Rows[2].Cross(Rows[0], Rows[1]);
  Result.Rows[2].Normalize;
  Result.Rows[1].Cross(Rows[2], Rows[0]);
  Result.Rows[1].Normalize;
end;

procedure TIdMat3.OrthoNormalizeSelf;
begin
  Rows[0].Normalize;
  Rows[2].Cross(Rows[0], Rows[1]);
  Rows[2].Normalize;
  Rows[1].Cross(Rows[2], Rows[0]);
  Rows[1].Normalize;
end;

function TIdMat3.Transpose: TIdMat3;
begin
  Result := Create(
    Rows[0].X, Rows[1].X, Rows[2].X,
    Rows[0].Y, Rows[1].Y, Rows[2].Y,
    Rows[0].Z, Rows[1].Z, Rows[2].Z);
end;

procedure TIdMat3.TransposeSelf;
var
  LTemp: Single;
begin
  LTemp := Rows[0].Y;
  Rows[0].Y := Rows[1].X;
  Rows[1].X := LTemp;
  LTemp := Rows[0].Z;
  Rows[0].Z := Rows[2].X;
  Rows[2].X := LTemp;
  LTemp := Rows[1].Z;
  Rows[1].Z := Rows[2].Y;
  Rows[2].Y := LTemp;
end;

function TIdMat3.Inverse: TIdMat3;
begin
  Result := Self;
  Result.InverseSelf;
end;

function TIdMat3.InverseSelf: Boolean;
var
  LInverse: TIdMat3;
  LDet, LInvDet: Double;
begin
  LInverse.Rows[0].X := Rows[1].Y * Rows[2].Z - Rows[1].Z * Rows[2].Y;
  LInverse.Rows[1].X := Rows[1].Z * Rows[2].X - Rows[1].X * Rows[2].Z;
  LInverse.Rows[2].X := Rows[1].X * Rows[2].Y - Rows[1].Y * Rows[2].X;
  LDet := Rows[0].X * LInverse.Rows[0].X + Rows[0].Y * LInverse.Rows[1].X +
    Rows[0].Z * LInverse.Rows[2].X;
  // idMath::Fabs takes a float: the double determinant is narrowed first
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  LInvDet := 1.0 / LDet;
  LInverse.Rows[0].Y := Rows[0].Z * Rows[2].Y - Rows[0].Y * Rows[2].Z;
  LInverse.Rows[0].Z := Rows[0].Y * Rows[1].Z - Rows[0].Z * Rows[1].Y;
  LInverse.Rows[1].Y := Rows[0].X * Rows[2].Z - Rows[0].Z * Rows[2].X;
  LInverse.Rows[1].Z := Rows[0].Z * Rows[1].X - Rows[0].X * Rows[1].Z;
  LInverse.Rows[2].Y := Rows[0].Y * Rows[2].X - Rows[0].X * Rows[2].Y;
  LInverse.Rows[2].Z := Rows[0].X * Rows[1].Y - Rows[0].Y * Rows[1].X;
  Rows[0].X := LInverse.Rows[0].X * LInvDet;
  Rows[0].Y := LInverse.Rows[0].Y * LInvDet;
  Rows[0].Z := LInverse.Rows[0].Z * LInvDet;
  Rows[1].X := LInverse.Rows[1].X * LInvDet;
  Rows[1].Y := LInverse.Rows[1].Y * LInvDet;
  Rows[1].Z := LInverse.Rows[1].Z * LInvDet;
  Rows[2].X := LInverse.Rows[2].X * LInvDet;
  Rows[2].Y := LInverse.Rows[2].Y * LInvDet;
  Rows[2].Z := LInverse.Rows[2].Z * LInvDet;
  Result := True;
end;

function TIdMat3.InverseFast: TIdMat3;
begin
  Result := Self;
  Result.InverseFastSelf;
end;

function TIdMat3.InverseFastSelf: Boolean;
begin
  // the active branch of the original (#if 1) is the same code as InverseSelf
  Result := InverseSelf;
end;

function TIdMat3.TransposeMultiply(const B: TIdMat3): TIdMat3;
begin
  Result := Create(
    Rows[0].X * B.Rows[0].X + Rows[1].X * B.Rows[1].X + Rows[2].X * B.Rows[2].X,
    Rows[0].X * B.Rows[0].Y + Rows[1].X * B.Rows[1].Y + Rows[2].X * B.Rows[2].Y,
    Rows[0].X * B.Rows[0].Z + Rows[1].X * B.Rows[1].Z + Rows[2].X * B.Rows[2].Z,
    Rows[0].Y * B.Rows[0].X + Rows[1].Y * B.Rows[1].X + Rows[2].Y * B.Rows[2].X,
    Rows[0].Y * B.Rows[0].Y + Rows[1].Y * B.Rows[1].Y + Rows[2].Y * B.Rows[2].Y,
    Rows[0].Y * B.Rows[0].Z + Rows[1].Y * B.Rows[1].Z + Rows[2].Y * B.Rows[2].Z,
    Rows[0].Z * B.Rows[0].X + Rows[1].Z * B.Rows[1].X + Rows[2].Z * B.Rows[2].X,
    Rows[0].Z * B.Rows[0].Y + Rows[1].Z * B.Rows[1].Y + Rows[2].Z * B.Rows[2].Y,
    Rows[0].Z * B.Rows[0].Z + Rows[1].Z * B.Rows[1].Z + Rows[2].Z * B.Rows[2].Z);
end;

function TIdMat3.InertiaTranslate(const AMass: Single; const ACenterOfMass, ATranslation: TIdVec3): TIdMat3;
var
  LMatrix: TIdMat3;
  LNewCenter: TIdVec3;
begin
  LNewCenter := ACenterOfMass + ATranslation;
  LMatrix.Rows[0].X := AMass * ((ACenterOfMass.Y * ACenterOfMass.Y + ACenterOfMass.Z * ACenterOfMass.Z) -
    (LNewCenter.Y * LNewCenter.Y + LNewCenter.Z * LNewCenter.Z));
  LMatrix.Rows[1].Y := AMass * ((ACenterOfMass.X * ACenterOfMass.X + ACenterOfMass.Z * ACenterOfMass.Z) -
    (LNewCenter.X * LNewCenter.X + LNewCenter.Z * LNewCenter.Z));
  LMatrix.Rows[2].Z := AMass * ((ACenterOfMass.X * ACenterOfMass.X + ACenterOfMass.Y * ACenterOfMass.Y) -
    (LNewCenter.X * LNewCenter.X + LNewCenter.Y * LNewCenter.Y));
  LMatrix.Rows[1].X := AMass * (LNewCenter.X * LNewCenter.Y - ACenterOfMass.X * ACenterOfMass.Y);
  LMatrix.Rows[0].Y := LMatrix.Rows[1].X;
  LMatrix.Rows[2].Y := AMass * (LNewCenter.Y * LNewCenter.Z - ACenterOfMass.Y * ACenterOfMass.Z);
  LMatrix.Rows[1].Z := LMatrix.Rows[2].Y;
  LMatrix.Rows[2].X := AMass * (LNewCenter.X * LNewCenter.Z - ACenterOfMass.X * ACenterOfMass.Z);
  LMatrix.Rows[0].Z := LMatrix.Rows[2].X;
  Result := Self + LMatrix;
end;

procedure TIdMat3.InertiaTranslateSelf(const AMass: Single; const ACenterOfMass, ATranslation: TIdVec3);
begin
  Self := InertiaTranslate(AMass, ACenterOfMass, ATranslation);
end;

function TIdMat3.InertiaRotate(const ARotation: TIdMat3): TIdMat3;
begin
  // the rotation matrix is stored column-major
  Result := ARotation.Transpose * Self * ARotation;
end;

procedure TIdMat3.InertiaRotateSelf(const ARotation: TIdMat3);
begin
  Self := ARotation.Transpose * Self * ARotation;
end;

function TIdMat3.GetDimension: Integer;
begin
  Result := 9;
end;

function TIdMat3.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([Rows[0].X, Rows[0].Y, Rows[0].Z, Rows[1].X, Rows[1].Y,
    Rows[1].Z, Rows[2].X, Rows[2].Y, Rows[2].Z], APrecision);
end;

end.
