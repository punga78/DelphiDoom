{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the 3x3 matrix (idMat3)                      }
{                                                                              }
{  Port of the used part of idMat3 (Matrix.h) of Doom 3 GPL Source Code.       }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Mat3;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   A 3x3 matrix stored by rows, as idMat3. A vector multiplied by a matrix is
  ///   M[0]*x + M[1]*y + M[2]*z (idlib convention: v*M rotates by the matrix)
  /// </summary>
  TGeoMat3 = record
    Rows: array[0..2] of TGeoVec3;
  public
    class function Identity: TGeoMat3; static;
    class function Make(AXX, AXY, AXZ, AYX, AYY, AYZ, AZX, AZY, AZZ: Single): TGeoMat3; static;
    /// <summary>Rotation about the Z axis by an angle in degrees (a test helper, not in idlib's collision code)</summary>
    class function RotationAboutZ(ADegrees: Single): TGeoMat3; static;

    /// <summary>True when the matrix differs from the identity (exact test, idMat3::IsRotated)</summary>
    function IsRotated: Boolean;
    function Transpose: TGeoMat3;
    /// <summary>Exact comparison of the three rows (idMat3::Compare)</summary>
    function Compare(const AMatrix: TGeoMat3): Boolean; overload;
    /// <summary>Comparison of the rows within the epsilon (idMat3::Compare with epsilon)</summary>
    function Compare(const AMatrix: TGeoMat3; AEpsilon: Single): Boolean; overload;

    class operator Multiply(const A, B: TGeoMat3): TGeoMat3;
    /// <summary>vec * mat of idlib</summary>
    class operator Multiply(const AVector: TGeoVec3; const AMatrix: TGeoMat3): TGeoVec3;
  end;

implementation

uses
  System.Math;

{ TGeoMat3 }

class function TGeoMat3.Identity: TGeoMat3;
begin
  Result := Make(1, 0, 0, 0, 1, 0, 0, 0, 1);
end;

class function TGeoMat3.Make(AXX, AXY, AXZ, AYX, AYY, AYZ, AZX, AZY, AZZ: Single): TGeoMat3;
begin
  Result.Rows[0] := TGeoVec3.Make(AXX, AXY, AXZ);
  Result.Rows[1] := TGeoVec3.Make(AYX, AYY, AYZ);
  Result.Rows[2] := TGeoVec3.Make(AZX, AZY, AZZ);
end;

class function TGeoMat3.RotationAboutZ(ADegrees: Single): TGeoMat3;
var
  LSin: Double;
  LCos: Double;
begin
  SinCos(Double(ADegrees) * Pi / 180.0, LSin, LCos);
  // idRotation about +Z turns X into Y: with v*M the rows are the images of the axes
  Result := Make(LCos, LSin, 0, -LSin, LCos, 0, 0, 0, 1);
end;

function TGeoMat3.IsRotated: Boolean;
var
  LIdentity: TGeoMat3;
begin
  LIdentity := Identity;
  Result := not (Rows[0].Compare(LIdentity.Rows[0]) and Rows[1].Compare(LIdentity.Rows[1]) and
    Rows[2].Compare(LIdentity.Rows[2]));
end;

function TGeoMat3.Transpose: TGeoMat3;
begin
  Result := Make(Rows[0].X, Rows[1].X, Rows[2].X,
    Rows[0].Y, Rows[1].Y, Rows[2].Y,
    Rows[0].Z, Rows[1].Z, Rows[2].Z);
end;

function TGeoMat3.Compare(const AMatrix: TGeoMat3): Boolean;
begin
  Result := Rows[0].Compare(AMatrix.Rows[0]) and Rows[1].Compare(AMatrix.Rows[1]) and
    Rows[2].Compare(AMatrix.Rows[2]);
end;

function TGeoMat3.Compare(const AMatrix: TGeoMat3; AEpsilon: Single): Boolean;
begin
  Result := Rows[0].Compare(AMatrix.Rows[0], AEpsilon) and Rows[1].Compare(AMatrix.Rows[1], AEpsilon) and
    Rows[2].Compare(AMatrix.Rows[2], AEpsilon);
end;

class operator TGeoMat3.Multiply(const A, B: TGeoMat3): TGeoMat3;
var
  LRow: Integer;
  LColumn: Integer;
begin
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
      Result.Rows[LRow][LColumn] :=
        A.Rows[LRow][0] * B.Rows[0][LColumn] +
        A.Rows[LRow][1] * B.Rows[1][LColumn] +
        A.Rows[LRow][2] * B.Rows[2][LColumn];
end;

class operator TGeoMat3.Multiply(const AVector: TGeoVec3; const AMatrix: TGeoMat3): TGeoVec3;
begin
  Result.X := AMatrix.Rows[0].X * AVector.X + AMatrix.Rows[1].X * AVector.Y + AMatrix.Rows[2].X * AVector.Z;
  Result.Y := AMatrix.Rows[0].Y * AVector.X + AMatrix.Rows[1].Y * AVector.Y + AMatrix.Rows[2].Y * AVector.Z;
  Result.Z := AMatrix.Rows[0].Z * AVector.X + AMatrix.Rows[1].Z * AVector.Y + AMatrix.Rows[2].Z * AVector.Z;
end;

end.
