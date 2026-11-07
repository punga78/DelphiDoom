{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib math - TIdVec3, the 3D vector of idTech 4                 }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idVec3 of idlib\math\Vector.h  }
{  and Vector.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media    }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Math.Vec3;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2;

type
  /// <summary>
  ///   A 3D vector of Singles (idVec3), 12 bytes, no padding. Operators as in TIdVec2: the product
  ///   of two vectors is the dot product, <c>Cross</c> is the cross product. Not ported: ToMat3,
  ///   ToAngles and ToPolar return idMat3, idAngles and idPolar3 in C++, types of other units: here
  ///   <c>ToAngles</c> and <c>ToPolar</c> give the three numbers (pitch, yaw, roll / radius, theta,
  ///   phi) as out parameters.
  /// </summary>
  TIdVec3 = record
    X: Single;
    Y: Single;
    Z: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const AX, AY, AZ: Single): TIdVec3; static;
    procedure SetValues(const AX, AY, AZ: Single);
    procedure Zero;
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Negative(const A: TIdVec3): TIdVec3;
    class operator Add(const A, B: TIdVec3): TIdVec3;
    class operator Subtract(const A, B: TIdVec3): TIdVec3;
    /// <summary>The dot product</summary>
    class operator Multiply(const A, B: TIdVec3): Single;
    class operator Multiply(const A: TIdVec3; const B: Single): TIdVec3;
    class operator Multiply(const A: Single; const B: TIdVec3): TIdVec3;
    class operator Divide(const A: TIdVec3; const B: Single): TIdVec3;
    class operator Equal(const A, B: TIdVec3): Boolean;
    class operator NotEqual(const A, B: TIdVec3): Boolean;
    function Compare(const A: TIdVec3; const AEpsilon: Single): Boolean;
    /// <summary>operator/=(idVec3): divides component by component</summary>
    procedure DivideComponents(const A: TIdVec3);
    function Cross(const A: TIdVec3): TIdVec3; overload;
    /// <summary>Sets the vector to the cross product of A and B</summary>
    procedure Cross(const A, B: TIdVec3); overload;
    function Length: Single;
    function LengthSqr: Single;
    function LengthFast: Single;
    function Normalize: Single;
    function NormalizeFast: Single;
    /// <summary>
    ///   Cleans a normal that should be axial: true if it changed (the exact 0 and 1 are restored)
    /// </summary>
    function FixDegenerateNormal: Boolean;
    function FixDenormals: Boolean;
    procedure Truncate(const ALength: Single);
    procedure Clamp(const AMin, AMax: TIdVec3);
    procedure Snap;
    procedure SnapInt;
    function GetDimension: Integer;
    function ToVec2: TIdVec2;
    /// <summary>The yaw in degrees, in [0, 360)</summary>
    function ToYaw: Single;
    function ToPitch: Single;
    /// <summary>idVec3::ToAngles: pitch, yaw and roll (the original gives -pitch, yaw, 0)</summary>
    procedure ToAngles(out APitch, AYaw, ARoll: Single);
    /// <summary>idVec3::ToPolar: radius, theta (yaw) and phi (-pitch)</summary>
    procedure ToPolar(out ARadius, ATheta, APhi: Single);
    /// <summary>Two vectors that are orthogonal to this one and to each other</summary>
    procedure NormalVectors(out ALeft, ADown: TIdVec3);
    procedure OrthogonalBasis(out ALeft, AUp: TIdVec3);
    procedure ProjectOntoPlane(const ANormal: TIdVec3; const AOverBounce: Single);
    function ProjectAlongPlane(const ANormal: TIdVec3; const AEpsilon, AOverBounce: Single): Boolean;
    procedure ProjectSelfOntoSphere(const ARadius: Single);
    procedure Lerp(const AV1, AV2: TIdVec3; const AL: Single);
    /// <summary>Spherical linear interpolation from V1 to V2 (normalized vectors)</summary>
    procedure SLerp(const AV1, AV2: TIdVec3; const AT: Single);
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

const
  LERP_DELTA: Double = 1E-6;

function FloorDouble(const AValue: Double): Double;
begin
  Result := System.Int(AValue);
  if (AValue < 0) and (Result <> AValue) then
    Result := Result - 1;
end;

// the float overloads of the math functions of the C++ library: the result is rounded to a float
function SqrtF(const AValue: Single): Single;
var
  LRounded: Single;
begin
  // a Single result of a function stays in the FPU unrounded: the local variable rounds it to a float
  LRounded := System.Sqrt(AValue);
  Result := LRounded;
end;

function SinF(const AValue: Single): Single;
var
  LRounded: Single;
begin
  LRounded := System.Sin(AValue);
  Result := LRounded;
end;

function ArcCosF(const AValue: Single): Single;
var
  LRounded: Single;
begin
  LRounded := ArcCos(AValue);
  Result := LRounded;
end;

// RAD2DEG( atan2( y, x ) ) with the float overload of atan2 of the C++ library: the angle is a float before the product
function Atan2Degrees(const AY, AX: Single): Single;
var
  LRadians: Single;
begin
  LRadians := ArcTan2(Double(AY), Double(AX));
  Result := LRadians * ID_RAD2DEG;
end;

{ TIdVec3 }

class function TIdVec3.Create(const AX, AY, AZ: Single): TIdVec3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

procedure TIdVec3.SetValues(const AX, AY, AZ: Single);
begin
  X := AX;
  Y := AY;
  Z := AZ;
end;

procedure TIdVec3.Zero;
begin
  X := 0.0;
  Y := 0.0;
  Z := 0.0;
end;

function TIdVec3.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@X) + AIndex * SizeOf(Single))^;
end;

procedure TIdVec3.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@X) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdVec3.Negative(const A: TIdVec3): TIdVec3;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
end;

class operator TIdVec3.Add(const A, B: TIdVec3): TIdVec3;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class operator TIdVec3.Subtract(const A, B: TIdVec3): TIdVec3;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class operator TIdVec3.Multiply(const A, B: TIdVec3): Single;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;

class operator TIdVec3.Multiply(const A: TIdVec3; const B: Single): TIdVec3;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
end;

class operator TIdVec3.Multiply(const A: Single; const B: TIdVec3): TIdVec3;
begin
  Result.X := B.X * A;
  Result.Y := B.Y * A;
  Result.Z := B.Z * A;
end;

class operator TIdVec3.Divide(const A: TIdVec3; const B: Single): TIdVec3;
var
  LInverse: Single;
begin
  LInverse := 1.0 / B;
  Result.X := A.X * LInverse;
  Result.Y := A.Y * LInverse;
  Result.Z := A.Z * LInverse;
end;

class operator TIdVec3.Equal(const A, B: TIdVec3): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class operator TIdVec3.NotEqual(const A, B: TIdVec3): Boolean;
begin
  Result := not ((A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z));
end;

function TIdVec3.Compare(const A: TIdVec3; const AEpsilon: Single): Boolean;
begin
  if TIdMath.Fabs(X - A.X) > AEpsilon then
    Exit(False);
  if TIdMath.Fabs(Y - A.Y) > AEpsilon then
    Exit(False);
  if TIdMath.Fabs(Z - A.Z) > AEpsilon then
    Exit(False);
  Result := True;
end;

procedure TIdVec3.DivideComponents(const A: TIdVec3);
begin
  X := X / A.X;
  Y := Y / A.Y;
  Z := Z / A.Z;
end;

function TIdVec3.Cross(const A: TIdVec3): TIdVec3;
begin
  Result.X := Y * A.Z - Z * A.Y;
  Result.Y := Z * A.X - X * A.Z;
  Result.Z := X * A.Y - Y * A.X;
end;

procedure TIdVec3.Cross(const A, B: TIdVec3);
var
  LX, LY, LZ: Single;
begin
  // A or B may be Self: the original writes x before reading it, which gives a wrong result there;
  // the three components are computed first here
  LX := A.Y * B.Z - A.Z * B.Y;
  LY := A.Z * B.X - A.X * B.Z;
  LZ := A.X * B.Y - A.Y * B.X;
  X := LX;
  Y := LY;
  Z := LZ;
end;

function TIdVec3.Length: Single;
begin
  Result := TIdMath.Sqrt(X * X + Y * Y + Z * Z);
end;

function TIdVec3.LengthSqr: Single;
begin
  Result := X * X + Y * Y + Z * Z;
end;

function TIdVec3.LengthFast: Single;
var
  LSqrLength: Single;
begin
  LSqrLength := X * X + Y * Y + Z * Z;
  Result := LSqrLength * TIdMath.RSqrt(LSqrLength);
end;

function TIdVec3.Normalize: Single;
var
  LSqrLength, LInvLength: Single;
begin
  LSqrLength := X * X + Y * Y + Z * Z;
  LInvLength := TIdMath.InvSqrt(LSqrLength);
  X := X * LInvLength;
  Y := Y * LInvLength;
  Z := Z * LInvLength;
  Result := LInvLength * LSqrLength;
end;

function TIdVec3.NormalizeFast: Single;
var
  LSqrLength, LInvLength: Single;
begin
  LSqrLength := X * X + Y * Y + Z * Z;
  LInvLength := TIdMath.RSqrt(LSqrLength);
  X := X * LInvLength;
  Y := Y * LInvLength;
  Z := Z * LInvLength;
  Result := LInvLength * LSqrLength;
end;

function TIdVec3.FixDegenerateNormal: Boolean;
begin
  if X = 0.0 then
  begin
    if Y = 0.0 then
    begin
      if Z > 0.0 then
      begin
        if Z <> 1.0 then
        begin
          Z := 1.0;
          Exit(True);
        end;
      end
      else
      begin
        if Z <> -1.0 then
        begin
          Z := -1.0;
          Exit(True);
        end;
      end;
      Exit(False);
    end
    else if Z = 0.0 then
    begin
      if Y > 0.0 then
      begin
        if Y <> 1.0 then
        begin
          Y := 1.0;
          Exit(True);
        end;
      end
      else
      begin
        if Y <> -1.0 then
        begin
          Y := -1.0;
          Exit(True);
        end;
      end;
      Exit(False);
    end;
  end
  else if Y = 0.0 then
  begin
    if Z = 0.0 then
    begin
      if X > 0.0 then
      begin
        if X <> 1.0 then
        begin
          X := 1.0;
          Exit(True);
        end;
      end
      else
      begin
        if X <> -1.0 then
        begin
          X := -1.0;
          Exit(True);
        end;
      end;
      Exit(False);
    end;
  end;
  if TIdMath.Fabs(X) = 1.0 then
  begin
    if (Y <> 0.0) or (Z <> 0.0) then
    begin
      Y := 0.0;
      Z := 0.0;
      Exit(True);
    end;
    Exit(False);
  end
  else if TIdMath.Fabs(Y) = 1.0 then
  begin
    if (X <> 0.0) or (Z <> 0.0) then
    begin
      X := 0.0;
      Z := 0.0;
      Exit(True);
    end;
    Exit(False);
  end
  else if TIdMath.Fabs(Z) = 1.0 then
  begin
    if (X <> 0.0) or (Y <> 0.0) then
    begin
      X := 0.0;
      Y := 0.0;
      Exit(True);
    end;
    Exit(False);
  end;
  Result := False;
end;

function TIdVec3.FixDenormals: Boolean;
begin
  Result := False;
  if System.Abs(X) < Single(1E-30) then
  begin
    X := 0.0;
    Result := True;
  end;
  if System.Abs(Y) < Single(1E-30) then
  begin
    Y := 0.0;
    Result := True;
  end;
  if System.Abs(Z) < Single(1E-30) then
  begin
    Z := 0.0;
    Result := True;
  end;
end;

procedure TIdVec3.Truncate(const ALength: Single);
var
  LLength2, LInvLength: Single;
begin
  if ALength = 0 then
    Zero
  else
  begin
    LLength2 := LengthSqr;
    if LLength2 > ALength * ALength then
    begin
      LInvLength := ALength * TIdMath.InvSqrt(LLength2);
      X := X * LInvLength;
      Y := Y * LInvLength;
      Z := Z * LInvLength;
    end;
  end;
end;

procedure TIdVec3.Clamp(const AMin, AMax: TIdVec3);
begin
  if X < AMin.X then
    X := AMin.X
  else if X > AMax.X then
    X := AMax.X;
  if Y < AMin.Y then
    Y := AMin.Y
  else if Y > AMax.Y then
    Y := AMax.Y;
  if Z < AMin.Z then
    Z := AMin.Z
  else if Z > AMax.Z then
    Z := AMax.Z;
end;

procedure TIdVec3.Snap;
begin
  X := FloorDouble(Double(X + 0.5));
  Y := FloorDouble(Double(Y + 0.5));
  Z := FloorDouble(Double(Z + 0.5));
end;

procedure TIdVec3.SnapInt;
begin
  X := TIdMath.Ftoi(X);
  Y := TIdMath.Ftoi(Y);
  Z := TIdMath.Ftoi(Z);
end;

function TIdVec3.GetDimension: Integer;
begin
  Result := 3;
end;

function TIdVec3.ToVec2: TIdVec2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function TIdVec3.ToYaw: Single;
begin
  if (Y = 0.0) and (X = 0.0) then
    Result := 0.0
  else
  begin
    Result := Atan2Degrees(Y, X);
    if Result < 0.0 then
      Result := Result + 360.0;
  end;
end;

function TIdVec3.ToPitch: Single;
var
  LForward: Single;
begin
  if (X = 0.0) and (Y = 0.0) then
  begin
    if Z > 0.0 then
      Result := 90.0
    else
      Result := 270.0;
  end
  else
  begin
    LForward := TIdMath.Sqrt(X * X + Y * Y);
    Result := Atan2Degrees(Z, LForward);
    if Result < 0.0 then
      Result := Result + 360.0;
  end;
end;

procedure TIdVec3.ToAngles(out APitch, AYaw, ARoll: Single);
var
  LForward, LYaw, LPitch: Single;
begin
  if (X = 0.0) and (Y = 0.0) then
  begin
    LYaw := 0.0;
    if Z > 0.0 then
      LPitch := 90.0
    else
      LPitch := 270.0;
  end
  else
  begin
    LYaw := Atan2Degrees(Y, X);
    if LYaw < 0.0 then
      LYaw := LYaw + 360.0;
    LForward := TIdMath.Sqrt(X * X + Y * Y);
    LPitch := Atan2Degrees(Z, LForward);
    if LPitch < 0.0 then
      LPitch := LPitch + 360.0;
  end;
  APitch := -LPitch;
  AYaw := LYaw;
  ARoll := 0.0;
end;

procedure TIdVec3.ToPolar(out ARadius, ATheta, APhi: Single);
var
  LForward, LYaw, LPitch: Single;
begin
  if (X = 0.0) and (Y = 0.0) then
  begin
    LYaw := 0.0;
    if Z > 0.0 then
      LPitch := 90.0
    else
      LPitch := 270.0;
  end
  else
  begin
    LYaw := Atan2Degrees(Y, X);
    if LYaw < 0.0 then
      LYaw := LYaw + 360.0;
    LForward := TIdMath.Sqrt(X * X + Y * Y);
    LPitch := Atan2Degrees(Z, LForward);
    if LPitch < 0.0 then
      LPitch := LPitch + 360.0;
  end;
  ARadius := TIdMath.Sqrt(X * X + Y * Y + Z * Z);
  ATheta := LYaw;
  APhi := -LPitch;
end;

procedure TIdVec3.NormalVectors(out ALeft, ADown: TIdVec3);
var
  LD: Single;
begin
  LD := X * X + Y * Y;
  if LD = 0 then
  begin
    ALeft.X := 1;
    ALeft.Y := 0;
    ALeft.Z := 0;
  end
  else
  begin
    LD := TIdMath.InvSqrt(LD);
    ALeft.X := -Y * LD;
    ALeft.Y := X * LD;
    ALeft.Z := 0;
  end;
  ADown := ALeft.Cross(Self);
end;

procedure TIdVec3.OrthogonalBasis(out ALeft, AUp: TIdVec3);
var
  LL, LS: Single;
begin
  if TIdMath.Fabs(Z) > 0.7 then
  begin
    LL := Y * Y + Z * Z;
    LS := TIdMath.InvSqrt(LL);
    AUp.X := 0;
    AUp.Y := Z * LS;
    AUp.Z := -Y * LS;
    ALeft.X := LL * LS;
    ALeft.Y := -X * AUp.Z;
    ALeft.Z := X * AUp.Y;
  end
  else
  begin
    LL := X * X + Y * Y;
    LS := TIdMath.InvSqrt(LL);
    ALeft.X := -Y * LS;
    ALeft.Y := X * LS;
    ALeft.Z := 0;
    AUp.X := -Z * ALeft.Y;
    AUp.Y := Z * ALeft.X;
    AUp.Z := LL * LS;
  end;
end;

procedure TIdVec3.ProjectOntoPlane(const ANormal: TIdVec3; const AOverBounce: Single);
var
  LBackoff: Single;
begin
  LBackoff := Self * ANormal;
  if AOverBounce <> 1.0 then
  begin
    if LBackoff < 0 then
      LBackoff := LBackoff * AOverBounce
    else
      LBackoff := LBackoff / AOverBounce;
  end;
  Self := Self - LBackoff * ANormal;
end;

function TIdVec3.ProjectAlongPlane(const ANormal: TIdVec3; const AEpsilon, AOverBounce: Single): Boolean;
var
  LCross: TIdVec3;
  LLength: Single;
begin
  LCross := Self.Cross(ANormal).Cross(Self);
  // normalize so a fixed epsilon can be used
  LCross.Normalize;
  LLength := ANormal * LCross;
  if TIdMath.Fabs(LLength) < AEpsilon then
    Exit(False);
  LCross := LCross * (AOverBounce * (ANormal * Self) / LLength);
  Self := Self - LCross;
  Result := True;
end;

procedure TIdVec3.ProjectSelfOntoSphere(const ARadius: Single);
var
  LRadiusSqr, LLength: Single;
begin
  LRadiusSqr := ARadius * ARadius;
  LLength := Length;
  if LLength < LRadiusSqr * 0.5 then
    Z := SqrtF(LRadiusSqr - LLength)
  else
    Z := LRadiusSqr / (2.0 * SqrtF(LLength));
end;

procedure TIdVec3.Lerp(const AV1, AV2: TIdVec3; const AL: Single);
begin
  if AL <= 0.0 then
    Self := AV1
  else if AL >= 1.0 then
    Self := AV2
  else
    Self := AV1 + AL * (AV2 - AV1);
end;

procedure TIdVec3.SLerp(const AV1, AV2: TIdVec3; const AT: Single);
var
  LOmega, LCosOm, LSinOm, LScale0, LScale1: Single;
begin
  if AT <= 0.0 then
  begin
    Self := AV1;
    Exit;
  end
  else if AT >= 1.0 then
  begin
    Self := AV2;
    Exit;
  end;
  LCosOm := AV1 * AV2;
  if (1.0 - LCosOm) > LERP_DELTA then
  begin
    LOmega := ArcCosF(LCosOm);
    LSinOm := SinF(LOmega);
    LScale0 := SinF((1.0 - AT) * LOmega) / LSinOm;
    LScale1 := SinF(AT * LOmega) / LSinOm;
  end
  else
  begin
    LScale0 := 1.0 - AT;
    LScale1 := AT;
  end;
  Self := AV1 * LScale0 + AV2 * LScale1;
end;

function TIdVec3.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([X, Y, Z], APrecision);
end;

end.
