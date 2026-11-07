{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib math - TIdVec2, the 2D vector of idTech 4                 }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idVec2 of idlib\math\Vector.h  }
{  and Vector.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media    }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Math.Vec2;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A 2D vector of Singles (idVec2), 8 bytes, no padding. The operators <c>+ - *</c> and <c>/</c>
  ///   build new vectors; the in-place operators of C++ are written <c>A := A + B</c>. The product of
  ///   two vectors is the dot product (a Single). A new variable is not zeroed: use
  ///   <c>TIdVec2.Create(0, 0)</c> or <c>Zero</c>.
  /// </summary>
  TIdVec2 = record
    X: Single;
    Y: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const AX, AY: Single): TIdVec2; static;
    procedure SetValues(const AX, AY: Single);
    procedure Zero;
    /// <summary>The coordinates by index 0..1 (like operator[]); no range check, as in C++</summary>
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Negative(const A: TIdVec2): TIdVec2;
    class operator Add(const A, B: TIdVec2): TIdVec2;
    class operator Subtract(const A, B: TIdVec2): TIdVec2;
    /// <summary>The dot product</summary>
    class operator Multiply(const A, B: TIdVec2): Single;
    class operator Multiply(const A: TIdVec2; const B: Single): TIdVec2;
    class operator Multiply(const A: Single; const B: TIdVec2): TIdVec2;
    class operator Divide(const A: TIdVec2; const B: Single): TIdVec2;
    /// <summary>Exact comparison (idVec2::Compare / operator==)</summary>
    class operator Equal(const A, B: TIdVec2): Boolean;
    class operator NotEqual(const A, B: TIdVec2): Boolean;
    /// <summary>The comparison with a tolerance per component</summary>
    function Compare(const A: TIdVec2; const AEpsilon: Single): Boolean;
    function Length: Single;
    function LengthFast: Single;
    function LengthSqr: Single;
    /// <summary>Normalizes with the 32-bit inverse square root, returns the old length</summary>
    function Normalize: Single;
    function NormalizeFast: Single;
    procedure Truncate(const ALength: Single);
    procedure Clamp(const AMin, AMax: TIdVec2);
    procedure Snap;
    procedure SnapInt;
    function GetDimension: Integer;
    /// <summary>Linear interpolation from V1 to V2 (clamped to the ends)</summary>
    procedure Lerp(const AV1, AV2: TIdVec2; const AL: Single);
    /// <summary>idVec2::ToString: the components with the given precision, space separated</summary>
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdVec2 }

class function TIdVec2.Create(const AX, AY: Single): TIdVec2;
begin
  Result.X := AX;
  Result.Y := AY;
end;

procedure TIdVec2.SetValues(const AX, AY: Single);
begin
  X := AX;
  Y := AY;
end;

procedure TIdVec2.Zero;
begin
  X := 0.0;
  Y := 0.0;
end;

function TIdVec2.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@X) + AIndex * SizeOf(Single))^;
end;

procedure TIdVec2.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@X) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdVec2.Negative(const A: TIdVec2): TIdVec2;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
end;

class operator TIdVec2.Add(const A, B: TIdVec2): TIdVec2;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

class operator TIdVec2.Subtract(const A, B: TIdVec2): TIdVec2;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

class operator TIdVec2.Multiply(const A, B: TIdVec2): Single;
begin
  Result := A.X * B.X + A.Y * B.Y;
end;

class operator TIdVec2.Multiply(const A: TIdVec2; const B: Single): TIdVec2;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
end;

class operator TIdVec2.Multiply(const A: Single; const B: TIdVec2): TIdVec2;
begin
  Result.X := B.X * A;
  Result.Y := B.Y * A;
end;

class operator TIdVec2.Divide(const A: TIdVec2; const B: Single): TIdVec2;
var
  LInverse: Single;
begin
  LInverse := 1.0 / B;
  Result.X := A.X * LInverse;
  Result.Y := A.Y * LInverse;
end;

class operator TIdVec2.Equal(const A, B: TIdVec2): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TIdVec2.NotEqual(const A, B: TIdVec2): Boolean;
begin
  Result := not ((A.X = B.X) and (A.Y = B.Y));
end;

function TIdVec2.Compare(const A: TIdVec2; const AEpsilon: Single): Boolean;
begin
  if TIdMath.Fabs(X - A.X) > AEpsilon then
    Exit(False);
  if TIdMath.Fabs(Y - A.Y) > AEpsilon then
    Exit(False);
  Result := True;
end;

function TIdVec2.Length: Single;
begin
  Result := TIdMath.Sqrt(X * X + Y * Y);
end;

function TIdVec2.LengthFast: Single;
var
  LSqrLength: Single;
begin
  LSqrLength := X * X + Y * Y;
  Result := LSqrLength * TIdMath.RSqrt(LSqrLength);
end;

function TIdVec2.LengthSqr: Single;
begin
  Result := X * X + Y * Y;
end;

function TIdVec2.Normalize: Single;
var
  LSqrLength, LInvLength: Single;
begin
  LSqrLength := X * X + Y * Y;
  LInvLength := TIdMath.InvSqrt(LSqrLength);
  X := X * LInvLength;
  Y := Y * LInvLength;
  Result := LInvLength * LSqrLength;
end;

function TIdVec2.NormalizeFast: Single;
var
  LSqrLength, LInvLength: Single;
begin
  LSqrLength := X * X + Y * Y;
  LInvLength := TIdMath.RSqrt(LSqrLength);
  X := X * LInvLength;
  Y := Y * LInvLength;
  Result := LInvLength * LSqrLength;
end;

procedure TIdVec2.Truncate(const ALength: Single);
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
    end;
  end;
end;

procedure TIdVec2.Clamp(const AMin, AMax: TIdVec2);
begin
  if X < AMin.X then
    X := AMin.X
  else if X > AMax.X then
    X := AMax.X;
  if Y < AMin.Y then
    Y := AMin.Y
  else if Y > AMax.Y then
    Y := AMax.Y;
end;

procedure TIdVec2.Snap;
var
  LSumX, LSumY: Double;
begin
  // floor( x + 0.5f ) of the C library takes a double
  LSumX := X + 0.5;
  LSumY := Y + 0.5;
  X := System.Int(LSumX) - Ord((LSumX < 0) and (Frac(LSumX) <> 0));
  Y := System.Int(LSumY) - Ord((LSumY < 0) and (Frac(LSumY) <> 0));
end;

procedure TIdVec2.SnapInt;
begin
  X := TIdMath.Ftoi(X);
  Y := TIdMath.Ftoi(Y);
end;

function TIdVec2.GetDimension: Integer;
begin
  Result := 2;
end;

procedure TIdVec2.Lerp(const AV1, AV2: TIdVec2; const AL: Single);
begin
  if AL <= 0.0 then
    Self := AV1
  else if AL >= 1.0 then
    Self := AV2
  else
    Self := AV1 + AL * (AV2 - AV1);
end;

function TIdVec2.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([X, Y], APrecision);
end;

end.
