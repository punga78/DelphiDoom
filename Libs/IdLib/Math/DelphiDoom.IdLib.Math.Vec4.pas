{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib math - TIdVec4, the 4D vector of idTech 4                 }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idVec4 of idlib\math\Vector.h  }
{  and Vector.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media    }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Math.Vec4;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>A 4D vector of Singles (idVec4), 16 bytes, no padding; operators as in TIdVec2</summary>
  TIdVec4 = record
    X: Single;
    Y: Single;
    Z: Single;
    W: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const AX, AY, AZ, AW: Single): TIdVec4; static;
    procedure SetValues(const AX, AY, AZ, AW: Single);
    procedure Zero;
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Negative(const A: TIdVec4): TIdVec4;
    class operator Add(const A, B: TIdVec4): TIdVec4;
    class operator Subtract(const A, B: TIdVec4): TIdVec4;
    /// <summary>The dot product</summary>
    class operator Multiply(const A, B: TIdVec4): Single;
    class operator Multiply(const A: TIdVec4; const B: Single): TIdVec4;
    class operator Multiply(const A: Single; const B: TIdVec4): TIdVec4;
    class operator Divide(const A: TIdVec4; const B: Single): TIdVec4;
    class operator Equal(const A, B: TIdVec4): Boolean;
    class operator NotEqual(const A, B: TIdVec4): Boolean;
    function Compare(const A: TIdVec4; const AEpsilon: Single): Boolean;
    procedure DivideComponents(const A: TIdVec4);
    function Length: Single;
    function LengthSqr: Single;
    function Normalize: Single;
    function NormalizeFast: Single;
    function GetDimension: Integer;
    /// <summary>The first two components</summary>
    function ToVec2: TIdVec2;
    /// <summary>The first three components</summary>
    function ToVec3: TIdVec3;
    procedure Lerp(const AV1, AV2: TIdVec4; const AL: Single);
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdVec4 }

class function TIdVec4.Create(const AX, AY, AZ, AW: Single): TIdVec4;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
  Result.W := AW;
end;

procedure TIdVec4.SetValues(const AX, AY, AZ, AW: Single);
begin
  X := AX;
  Y := AY;
  Z := AZ;
  W := AW;
end;

procedure TIdVec4.Zero;
begin
  X := 0.0;
  Y := 0.0;
  Z := 0.0;
  W := 0.0;
end;

function TIdVec4.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@X) + AIndex * SizeOf(Single))^;
end;

procedure TIdVec4.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@X) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdVec4.Negative(const A: TIdVec4): TIdVec4;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
  Result.W := -A.W;
end;

class operator TIdVec4.Add(const A, B: TIdVec4): TIdVec4;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
  Result.W := A.W + B.W;
end;

class operator TIdVec4.Subtract(const A, B: TIdVec4): TIdVec4;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
  Result.W := A.W - B.W;
end;

class operator TIdVec4.Multiply(const A, B: TIdVec4): Single;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z + A.W * B.W;
end;

class operator TIdVec4.Multiply(const A: TIdVec4; const B: Single): TIdVec4;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
  Result.W := A.W * B;
end;

class operator TIdVec4.Multiply(const A: Single; const B: TIdVec4): TIdVec4;
begin
  Result.X := B.X * A;
  Result.Y := B.Y * A;
  Result.Z := B.Z * A;
  Result.W := B.W * A;
end;

class operator TIdVec4.Divide(const A: TIdVec4; const B: Single): TIdVec4;
var
  LInverse: Single;
begin
  LInverse := 1.0 / B;
  Result.X := A.X * LInverse;
  Result.Y := A.Y * LInverse;
  Result.Z := A.Z * LInverse;
  Result.W := A.W * LInverse;
end;

class operator TIdVec4.Equal(const A, B: TIdVec4): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and (A.W = B.W);
end;

class operator TIdVec4.NotEqual(const A, B: TIdVec4): Boolean;
begin
  Result := not ((A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and (A.W = B.W));
end;

function TIdVec4.Compare(const A: TIdVec4; const AEpsilon: Single): Boolean;
begin
  if TIdMath.Fabs(X - A.X) > AEpsilon then
    Exit(False);
  if TIdMath.Fabs(Y - A.Y) > AEpsilon then
    Exit(False);
  if TIdMath.Fabs(Z - A.Z) > AEpsilon then
    Exit(False);
  if TIdMath.Fabs(W - A.W) > AEpsilon then
    Exit(False);
  Result := True;
end;

procedure TIdVec4.DivideComponents(const A: TIdVec4);
begin
  X := X / A.X;
  Y := Y / A.Y;
  Z := Z / A.Z;
  W := W / A.W;
end;

function TIdVec4.Length: Single;
begin
  Result := TIdMath.Sqrt(X * X + Y * Y + Z * Z + W * W);
end;

function TIdVec4.LengthSqr: Single;
begin
  Result := X * X + Y * Y + Z * Z + W * W;
end;

function TIdVec4.Normalize: Single;
var
  LSqrLength, LInvLength: Single;
begin
  LSqrLength := X * X + Y * Y + Z * Z + W * W;
  LInvLength := TIdMath.InvSqrt(LSqrLength);
  X := X * LInvLength;
  Y := Y * LInvLength;
  Z := Z * LInvLength;
  W := W * LInvLength;
  Result := LInvLength * LSqrLength;
end;

function TIdVec4.NormalizeFast: Single;
var
  LSqrLength, LInvLength: Single;
begin
  LSqrLength := X * X + Y * Y + Z * Z + W * W;
  LInvLength := TIdMath.RSqrt(LSqrLength);
  X := X * LInvLength;
  Y := Y * LInvLength;
  Z := Z * LInvLength;
  W := W * LInvLength;
  Result := LInvLength * LSqrLength;
end;

function TIdVec4.GetDimension: Integer;
begin
  Result := 4;
end;

function TIdVec4.ToVec2: TIdVec2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function TIdVec4.ToVec3: TIdVec3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

procedure TIdVec4.Lerp(const AV1, AV2: TIdVec4; const AL: Single);
begin
  if AL <= 0.0 then
    Self := AV1
  else if AL >= 1.0 then
    Self := AV2
  else
    Self := AV1 + AL * (AV2 - AV1);
end;

function TIdVec4.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([X, Y, Z, W], APrecision);
end;

end.
