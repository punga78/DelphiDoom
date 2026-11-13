{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdQuat, the quaternion             }
{                                                                              }
{  Port of idQuat (idlib\math\Quat.h and Quat.cpp) of the Doom 3 GPL Source    }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Quat;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>
  ///   A quaternion (idQuat): x, y, z, w as Single, 16 bytes. The product of two quaternions is
  ///   the Hamilton product (this * A); a quaternion times a vector rotates the vector. The
  ///   conversions to angles, matrix and rotation are in <c>TIdRotationConversions</c>.
  /// </summary>
  TIdQuat = record
    X: Single;
    Y: Single;
    Z: Single;
    W: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const AX, AY, AZ, AW: Single): TIdQuat; static;
    procedure SetValues(const AX, AY, AZ, AW: Single);
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Negative(const A: TIdQuat): TIdQuat;
    class operator Add(const A, B: TIdQuat): TIdQuat;
    class operator Subtract(const A, B: TIdQuat): TIdQuat;
    class operator Multiply(const A, B: TIdQuat): TIdQuat;
    /// <summary>Rotates the vector (idQuat::operator*( idVec3 ), the inverse-sandwich form)</summary>
    class operator Multiply(const A: TIdQuat; const B: TIdVec3): TIdVec3;
    class operator Multiply(const A: TIdQuat; const B: Single): TIdQuat;
    class operator Multiply(const A: Single; const B: TIdQuat): TIdQuat;
    class operator Equal(const A, B: TIdQuat): Boolean;
    class operator NotEqual(const A, B: TIdQuat): Boolean;
    function Compare(const A: TIdQuat; const AEpsilon: Single): Boolean;
    function Inverse: TIdQuat;
    function Length: Single;
    /// <summary>Normalises in place; a zero quaternion is left as it is</summary>
    procedure Normalize;
    /// <summary>The w that makes the quaternion unit length, from x, y and z</summary>
    function CalcW: Single;
    function GetDimension: Integer;
    /// <summary>idQuat::ToCQuat, as the three components: x, y, z negated when w is negative</summary>
    procedure ToCompressed(out AX, AY, AZ: Single);
    /// <summary>idQuat::ToAngularVelocity</summary>
    function ToAngularVelocity: TIdVec3;
    /// <summary>Spherical linear interpolation (idQuat::Slerp), the polynomial functions of idMath</summary>
    procedure Slerp(const AFrom, ATo: TIdQuat; const AT: Single);
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdQuat }

class function TIdQuat.Create(const AX, AY, AZ, AW: Single): TIdQuat;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
  Result.W := AW;
end;

procedure TIdQuat.SetValues(const AX, AY, AZ, AW: Single);
begin
  X := AX;
  Y := AY;
  Z := AZ;
  W := AW;
end;

function TIdQuat.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@X) + AIndex * SizeOf(Single))^;
end;

procedure TIdQuat.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@X) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdQuat.Negative(const A: TIdQuat): TIdQuat;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
  Result.W := -A.W;
end;

class operator TIdQuat.Add(const A, B: TIdQuat): TIdQuat;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
  Result.W := A.W + B.W;
end;

class operator TIdQuat.Subtract(const A, B: TIdQuat): TIdQuat;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
  Result.W := A.W - B.W;
end;

class operator TIdQuat.Multiply(const A, B: TIdQuat): TIdQuat;
var
  LX, LY, LZ, LW: Single;
begin
  // the result may alias an operand: compute first
  LX := A.W * B.X + A.X * B.W + A.Y * B.Z - A.Z * B.Y;
  LY := A.W * B.Y + A.Y * B.W + A.Z * B.X - A.X * B.Z;
  LZ := A.W * B.Z + A.Z * B.W + A.X * B.Y - A.Y * B.X;
  LW := A.W * B.W - A.X * B.X - A.Y * B.Y - A.Z * B.Z;
  Result.X := LX;
  Result.Y := LY;
  Result.Z := LZ;
  Result.W := LW;
end;

class operator TIdQuat.Multiply(const A: TIdQuat; const B: TIdVec3): TIdVec3;
var
  LXXZZ, LWWYY, LXW2, LXY2, LXZ2, LYW2, LYZ2, LZW2: Single;
begin
  LXXZZ := A.X * A.X - A.Z * A.Z;
  LWWYY := A.W * A.W - A.Y * A.Y;
  LXW2 := A.X * A.W * 2.0;
  LXY2 := A.X * A.Y * 2.0;
  LXZ2 := A.X * A.Z * 2.0;
  LYW2 := A.Y * A.W * 2.0;
  LYZ2 := A.Y * A.Z * 2.0;
  LZW2 := A.Z * A.W * 2.0;
  Result.X := (LXXZZ + LWWYY) * B.X + (LXY2 + LZW2) * B.Y + (LXZ2 - LYW2) * B.Z;
  Result.Y := (LXY2 - LZW2) * B.X + (A.Y * A.Y + A.W * A.W - A.X * A.X - A.Z * A.Z) * B.Y +
    (LYZ2 + LXW2) * B.Z;
  Result.Z := (LXZ2 + LYW2) * B.X + (LYZ2 - LXW2) * B.Y + (LWWYY - LXXZZ) * B.Z;
end;

class operator TIdQuat.Multiply(const A: TIdQuat; const B: Single): TIdQuat;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
  Result.W := A.W * B;
end;

class operator TIdQuat.Multiply(const A: Single; const B: TIdQuat): TIdQuat;
begin
  Result := B * A;
end;

class operator TIdQuat.Equal(const A, B: TIdQuat): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and (A.W = B.W);
end;

class operator TIdQuat.NotEqual(const A, B: TIdQuat): Boolean;
begin
  Result := not (A = B);
end;

function TIdQuat.Compare(const A: TIdQuat; const AEpsilon: Single): Boolean;
begin
  Result := False;
  if TIdMath.Fabs(X - A.X) > AEpsilon then
    Exit;
  if TIdMath.Fabs(Y - A.Y) > AEpsilon then
    Exit;
  if TIdMath.Fabs(Z - A.Z) > AEpsilon then
    Exit;
  if TIdMath.Fabs(W - A.W) > AEpsilon then
    Exit;
  Result := True;
end;

function TIdQuat.Inverse: TIdQuat;
begin
  Result.X := -X;
  Result.Y := -Y;
  Result.Z := -Z;
  Result.W := W;
end;

function TIdQuat.Length: Single;
var
  LSquared: Single;
begin
  LSquared := X * X + Y * Y + Z * Z + W * W;
  Result := TIdMath.Sqrt(LSquared);
end;

procedure TIdQuat.Normalize;
var
  LLength, LInverseLength: Single;
begin
  LLength := Length;
  if LLength <> 0 then
  begin
    LInverseLength := 1 / LLength;
    X := X * LInverseLength;
    Y := Y * LInverseLength;
    Z := Z * LInverseLength;
    W := W * LInverseLength;
  end;
end;

function TIdQuat.CalcW: Single;
var
  LValue: Single;
begin
  // the absolute value: rounding may make x*x + y*y + z*z a little larger than 1
  LValue := System.Abs(1.0 - (X * X + Y * Y + Z * Z));
  Result := System.Sqrt(LValue);
end;

function TIdQuat.GetDimension: Integer;
begin
  Result := 4;
end;

procedure TIdQuat.ToCompressed(out AX, AY, AZ: Single);
begin
  if W < 0.0 then
  begin
    AX := -X;
    AY := -Y;
    AZ := -Z;
  end
  else
  begin
    AX := X;
    AY := Y;
    AZ := Z;
  end;
end;

function TIdQuat.ToAngularVelocity: TIdVec3;
var
  LVector: TIdVec3;
begin
  LVector.X := X;
  LVector.Y := Y;
  LVector.Z := Z;
  LVector.Normalize;
  Result := LVector * TIdMath.ACos(W);
end;

procedure TIdQuat.Slerp(const AFrom, ATo: TIdQuat; const AT: Single);
var
  LTemp: TIdQuat;
  LOmega, LCosOmega, LSinOmega, LScale0, LScale1: Single;
begin
  if AT <= 0.0 then
  begin
    Self := AFrom;
    Exit;
  end;
  if AT >= 1.0 then
  begin
    Self := ATo;
    Exit;
  end;
  if AFrom = ATo then
  begin
    Self := ATo;
    Exit;
  end;
  LCosOmega := AFrom.X * ATo.X + AFrom.Y * ATo.Y + AFrom.Z * ATo.Z + AFrom.W * ATo.W;
  if LCosOmega < 0.0 then
  begin
    LTemp := -ATo;
    LCosOmega := -LCosOmega;
  end
  else
    LTemp := ATo;
  if (1.0 - LCosOmega) > Single(1E-6) then
  begin
    LScale0 := 1.0 - LCosOmega * LCosOmega;
    LSinOmega := TIdMath.InvSqrt(LScale0);
    LOmega := TIdMath.ATan16(LScale0 * LSinOmega, LCosOmega);
    LScale0 := TIdMath.Sin16((1.0 - AT) * LOmega) * LSinOmega;
    LScale1 := TIdMath.Sin16(AT * LOmega) * LSinOmega;
  end
  else
  begin
    LScale0 := 1.0 - AT;
    LScale1 := AT;
  end;
  Self := (LScale0 * AFrom) + (LScale1 * LTemp);
end;

function TIdQuat.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([X, Y, Z, W], APrecision);
end;

end.
