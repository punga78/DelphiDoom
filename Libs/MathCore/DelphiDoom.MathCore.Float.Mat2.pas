{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMat2, the 2x2 matrix             }
{                                                                              }
{  Port of idMat2 (idlib\math\Matrix.h and Matrix.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Mat2;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.MathCore.Float.Mat3;

type
  /// <summary>A 2x2 matrix of Single stored by rows (idMat2), 16 bytes</summary>
  TIdMat2 = record
    Rows: array[0..1] of TIdVec2;
  public
    class function Create(const AX, AY: TIdVec2): TIdMat2; overload; static;
    class function Create(const AXX, AXY, AYX, AYY: Single): TIdMat2; overload; static;
    class function Identity: TIdMat2; static;
    class operator Negative(const A: TIdMat2): TIdMat2;
    class operator Add(const A, B: TIdMat2): TIdMat2;
    class operator Subtract(const A, B: TIdMat2): TIdMat2;
    class operator Multiply(const A, B: TIdMat2): TIdMat2;
    class operator Multiply(const A: TIdMat2; const B: Single): TIdMat2;
    class operator Multiply(const A: Single; const B: TIdMat2): TIdMat2;
    class operator Multiply(const A: TIdMat2; const B: TIdVec2): TIdVec2;
    class operator Multiply(const A: TIdVec2; const B: TIdMat2): TIdVec2;
    class operator Equal(const A, B: TIdMat2): Boolean;
    class operator NotEqual(const A, B: TIdMat2): Boolean;
    function Compare(const A: TIdMat2; const AEpsilon: Single): Boolean;
    procedure Zero;
    procedure SetIdentity;
    function IsIdentity(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsSymmetric(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function Trace: Single;
    function Determinant: Single;
    function Transpose: TIdMat2;
    procedure TransposeSelf;
    function Inverse: TIdMat2;
    /// <summary>Inverts in place; false (and no change) if the determinant is almost zero</summary>
    function InverseSelf: Boolean;
    function InverseFast: TIdMat2;
    function InverseFastSelf: Boolean;
    function GetDimension: Integer;
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdMat2 }

class function TIdMat2.Create(const AX, AY: TIdVec2): TIdMat2;
begin
  Result.Rows[0] := AX;
  Result.Rows[1] := AY;
end;

class function TIdMat2.Create(const AXX, AXY, AYX, AYY: Single): TIdMat2;
begin
  Result.Rows[0].SetValues(AXX, AXY);
  Result.Rows[1].SetValues(AYX, AYY);
end;

class function TIdMat2.Identity: TIdMat2;
begin
  Result := Create(1.0, 0.0, 0.0, 1.0);
end;

class operator TIdMat2.Negative(const A: TIdMat2): TIdMat2;
begin
  Result := Create(-A.Rows[0].X, -A.Rows[0].Y, -A.Rows[1].X, -A.Rows[1].Y);
end;

class operator TIdMat2.Add(const A, B: TIdMat2): TIdMat2;
begin
  Result := Create(A.Rows[0].X + B.Rows[0].X, A.Rows[0].Y + B.Rows[0].Y,
    A.Rows[1].X + B.Rows[1].X, A.Rows[1].Y + B.Rows[1].Y);
end;

class operator TIdMat2.Subtract(const A, B: TIdMat2): TIdMat2;
begin
  Result := Create(A.Rows[0].X - B.Rows[0].X, A.Rows[0].Y - B.Rows[0].Y,
    A.Rows[1].X - B.Rows[1].X, A.Rows[1].Y - B.Rows[1].Y);
end;

class operator TIdMat2.Multiply(const A, B: TIdMat2): TIdMat2;
begin
  Result := Create(
    A.Rows[0].X * B.Rows[0].X + A.Rows[0].Y * B.Rows[1].X,
    A.Rows[0].X * B.Rows[0].Y + A.Rows[0].Y * B.Rows[1].Y,
    A.Rows[1].X * B.Rows[0].X + A.Rows[1].Y * B.Rows[1].X,
    A.Rows[1].X * B.Rows[0].Y + A.Rows[1].Y * B.Rows[1].Y);
end;

class operator TIdMat2.Multiply(const A: TIdMat2; const B: Single): TIdMat2;
begin
  Result := Create(A.Rows[0].X * B, A.Rows[0].Y * B, A.Rows[1].X * B, A.Rows[1].Y * B);
end;

class operator TIdMat2.Multiply(const A: Single; const B: TIdMat2): TIdMat2;
begin
  Result := B * A;
end;

class operator TIdMat2.Multiply(const A: TIdMat2; const B: TIdVec2): TIdVec2;
begin
  Result.X := A.Rows[0].X * B.X + A.Rows[0].Y * B.Y;
  Result.Y := A.Rows[1].X * B.X + A.Rows[1].Y * B.Y;
end;

class operator TIdMat2.Multiply(const A: TIdVec2; const B: TIdMat2): TIdVec2;
begin
  Result := B * A;
end;

class operator TIdMat2.Equal(const A, B: TIdMat2): Boolean;
begin
  Result := (A.Rows[0] = B.Rows[0]) and (A.Rows[1] = B.Rows[1]);
end;

class operator TIdMat2.NotEqual(const A, B: TIdMat2): Boolean;
begin
  Result := not (A = B);
end;

function TIdMat2.Compare(const A: TIdMat2; const AEpsilon: Single): Boolean;
begin
  Result := Rows[0].Compare(A.Rows[0], AEpsilon) and Rows[1].Compare(A.Rows[1], AEpsilon);
end;

procedure TIdMat2.Zero;
begin
  Rows[0].Zero;
  Rows[1].Zero;
end;

procedure TIdMat2.SetIdentity;
begin
  Self := Identity;
end;

function TIdMat2.IsIdentity(const AEpsilon: Single): Boolean;
begin
  Result := Compare(Identity, AEpsilon);
end;

function TIdMat2.IsSymmetric(const AEpsilon: Single): Boolean;
begin
  Result := TIdMath.Fabs(Rows[0].Y - Rows[1].X) < AEpsilon;
end;

function TIdMat2.IsDiagonal(const AEpsilon: Single): Boolean;
begin
  Result := not ((TIdMath.Fabs(Rows[0].Y) > AEpsilon) or (TIdMath.Fabs(Rows[1].X) > AEpsilon));
end;

function TIdMat2.Trace: Single;
begin
  Result := Rows[0].X + Rows[1].Y;
end;

function TIdMat2.Determinant: Single;
begin
  Result := Rows[0].X * Rows[1].Y - Rows[0].Y * Rows[1].X;
end;

function TIdMat2.Transpose: TIdMat2;
begin
  Result := Create(Rows[0].X, Rows[1].X, Rows[0].Y, Rows[1].Y);
end;

procedure TIdMat2.TransposeSelf;
var
  LTemp: Single;
begin
  LTemp := Rows[0].Y;
  Rows[0].Y := Rows[1].X;
  Rows[1].X := LTemp;
end;

function TIdMat2.Inverse: TIdMat2;
begin
  Result := Self;
  Result.InverseSelf;
end;

function TIdMat2.InverseSelf: Boolean;
var
  LDet, LInvDet, LFirst: Double;
begin
  // the determinant is a double in the C++ (the products are floats)
  LDet := Rows[0].X * Rows[1].Y - Rows[0].Y * Rows[1].X;
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  LInvDet := 1.0 / LDet;
  LFirst := Rows[0].X;
  Rows[0].X := Rows[1].Y * LInvDet;
  Rows[0].Y := -Rows[0].Y * LInvDet;
  Rows[1].X := -Rows[1].X * LInvDet;
  Rows[1].Y := LFirst * LInvDet;
  Result := True;
end;

function TIdMat2.InverseFast: TIdMat2;
begin
  Result := Self;
  Result.InverseFastSelf;
end;

function TIdMat2.InverseFastSelf: Boolean;
begin
  // the active branch of the original (#if 1) is the same code as InverseSelf
  Result := InverseSelf;
end;

function TIdMat2.GetDimension: Integer;
begin
  Result := 4;
end;

function TIdMat2.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([Rows[0].X, Rows[0].Y, Rows[1].X, Rows[1].Y],
    APrecision);
end;

end.
