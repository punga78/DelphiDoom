{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdComplex, the complex number      }
{                                                                              }
{  Port of idComplex (idlib\math\Complex.h and Complex.cpp) of the Doom 3 GPL  }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Complex;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A complex number of two Single (idComplex), 8 bytes. The division is the one of the
  ///   original (Smith's algorithm, no overflow for large parts).
  /// </summary>
  TIdComplex = record
    R: Single;
    I: Single;
  public
    class function Create(const AReal, AImaginary: Single): TIdComplex; static;
    procedure SetValues(const AReal, AImaginary: Single);
    procedure Zero;
    class operator Negative(const A: TIdComplex): TIdComplex;
    class operator Add(const A, B: TIdComplex): TIdComplex;
    class operator Subtract(const A, B: TIdComplex): TIdComplex;
    class operator Multiply(const A, B: TIdComplex): TIdComplex;
    class operator Divide(const A, B: TIdComplex): TIdComplex;
    class operator Add(const A: TIdComplex; const B: Single): TIdComplex;
    class operator Subtract(const A: TIdComplex; const B: Single): TIdComplex;
    class operator Multiply(const A: TIdComplex; const B: Single): TIdComplex;
    /// <summary>Multiplies by the reciprocal of B, as the original</summary>
    class operator Divide(const A: TIdComplex; const B: Single): TIdComplex;
    class operator Add(const A: Single; const B: TIdComplex): TIdComplex;
    class operator Subtract(const A: Single; const B: TIdComplex): TIdComplex;
    class operator Multiply(const A: Single; const B: TIdComplex): TIdComplex;
    class operator Divide(const A: Single; const B: TIdComplex): TIdComplex;
    class operator Equal(const A, B: TIdComplex): Boolean;
    class operator NotEqual(const A, B: TIdComplex): Boolean;
    function Compare(const A: TIdComplex; const AEpsilon: Single): Boolean;
    function Reciprocal: TIdComplex;
    function Sqrt: TIdComplex;
    /// <summary>The modulus, computed without overflow</summary>
    function Abs: Single;
    function GetDimension: Integer;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdComplex }

class function TIdComplex.Create(const AReal, AImaginary: Single): TIdComplex;
begin
  Result.R := AReal;
  Result.I := AImaginary;
end;

procedure TIdComplex.SetValues(const AReal, AImaginary: Single);
begin
  R := AReal;
  I := AImaginary;
end;

procedure TIdComplex.Zero;
begin
  R := 0.0;
  I := 0.0;
end;

class operator TIdComplex.Negative(const A: TIdComplex): TIdComplex;
begin
  Result.R := -A.R;
  Result.I := -A.I;
end;

class operator TIdComplex.Add(const A, B: TIdComplex): TIdComplex;
begin
  Result.R := A.R + B.R;
  Result.I := A.I + B.I;
end;

class operator TIdComplex.Subtract(const A, B: TIdComplex): TIdComplex;
begin
  Result.R := A.R - B.R;
  Result.I := A.I - B.I;
end;

class operator TIdComplex.Multiply(const A, B: TIdComplex): TIdComplex;
var
  LReal, LImaginary: Single;
begin
  LReal := A.R * B.R - A.I * B.I;
  LImaginary := A.I * B.R + A.R * B.I;
  Result.R := LReal;
  Result.I := LImaginary;
end;

class operator TIdComplex.Divide(const A, B: TIdComplex): TIdComplex;
var
  LS, LT, LReal, LImaginary: Single;
begin
  if TIdMath.Fabs(B.R) >= TIdMath.Fabs(B.I) then
  begin
    LS := B.I / B.R;
    LT := 1.0 / (B.R + LS * B.I);
    LReal := (A.R + LS * A.I) * LT;
    LImaginary := (A.I - LS * A.R) * LT;
  end
  else
  begin
    LS := B.R / B.I;
    LT := 1.0 / (LS * B.R + B.I);
    LReal := (A.R * LS + A.I) * LT;
    LImaginary := (A.I * LS - A.R) * LT;
  end;
  Result.R := LReal;
  Result.I := LImaginary;
end;

class operator TIdComplex.Add(const A: TIdComplex; const B: Single): TIdComplex;
begin
  Result.R := A.R + B;
  Result.I := A.I;
end;

class operator TIdComplex.Subtract(const A: TIdComplex; const B: Single): TIdComplex;
begin
  Result.R := A.R - B;
  Result.I := A.I;
end;

class operator TIdComplex.Multiply(const A: TIdComplex; const B: Single): TIdComplex;
begin
  Result.R := A.R * B;
  Result.I := A.I * B;
end;

class operator TIdComplex.Divide(const A: TIdComplex; const B: Single): TIdComplex;
var
  LS: Single;
begin
  LS := 1.0 / B;
  Result.R := A.R * LS;
  Result.I := A.I * LS;
end;

class operator TIdComplex.Add(const A: Single; const B: TIdComplex): TIdComplex;
begin
  Result.R := A + B.R;
  Result.I := B.I;
end;

class operator TIdComplex.Subtract(const A: Single; const B: TIdComplex): TIdComplex;
begin
  Result.R := A - B.R;
  Result.I := -B.I;
end;

class operator TIdComplex.Multiply(const A: Single; const B: TIdComplex): TIdComplex;
begin
  Result.R := A * B.R;
  Result.I := A * B.I;
end;

class operator TIdComplex.Divide(const A: Single; const B: TIdComplex): TIdComplex;
var
  LS, LT: Single;
begin
  if TIdMath.Fabs(B.R) >= TIdMath.Fabs(B.I) then
  begin
    LS := B.I / B.R;
    LT := A / (B.R + LS * B.I);
    Result.R := LT;
    Result.I := -LS * LT;
  end
  else
  begin
    LS := B.R / B.I;
    LT := A / (LS * B.R + B.I);
    Result.R := LS * LT;
    Result.I := -LT;
  end;
end;

class operator TIdComplex.Equal(const A, B: TIdComplex): Boolean;
begin
  Result := (A.R = B.R) and (A.I = B.I);
end;

class operator TIdComplex.NotEqual(const A, B: TIdComplex): Boolean;
begin
  Result := not (A = B);
end;

function TIdComplex.Compare(const A: TIdComplex; const AEpsilon: Single): Boolean;
begin
  // written as the original (a NaN difference does not make the comparison fail)
  Result := not (TIdMath.Fabs(R - A.R) > AEpsilon) and not (TIdMath.Fabs(I - A.I) > AEpsilon);
end;

function TIdComplex.Reciprocal: TIdComplex;
var
  LS, LT: Single;
begin
  if TIdMath.Fabs(R) >= TIdMath.Fabs(I) then
  begin
    LS := I / R;
    LT := 1.0 / (R + LS * I);
    Result.R := LT;
    Result.I := -LS * LT;
  end
  else
  begin
    LS := R / I;
    LT := 1.0 / (LS * R + I);
    Result.R := LS * LT;
    Result.I := -LT;
  end;
end;

function TIdComplex.Sqrt: TIdComplex;
var
  LX, LY, LW: Single;
begin
  if (R = 0.0) and (I = 0.0) then
  begin
    Result.R := 0.0;
    Result.I := 0.0;
    Exit;
  end;
  LX := TIdMath.Fabs(R);
  LY := TIdMath.Fabs(I);
  if LX >= LY then
  begin
    LW := LY / LX;
    LW := TIdMath.Sqrt(LX) * TIdMath.Sqrt(0.5 * (1.0 + TIdMath.Sqrt(1.0 + LW * LW)));
  end
  else
  begin
    LW := LX / LY;
    LW := TIdMath.Sqrt(LY) * TIdMath.Sqrt(0.5 * (LW + TIdMath.Sqrt(1.0 + LW * LW)));
  end;
  if LW = 0.0 then
  begin
    Result.R := 0.0;
    Result.I := 0.0;
    Exit;
  end;
  if R >= 0.0 then
  begin
    Result.R := LW;
    Result.I := 0.5 * I / LW;
  end
  else
  begin
    Result.R := 0.5 * LY / LW;
    if I >= 0.0 then
      Result.I := LW
    else
      Result.I := -LW;
  end;
end;

function TIdComplex.Abs: Single;
var
  LX, LY, LT: Single;
begin
  LX := TIdMath.Fabs(R);
  LY := TIdMath.Fabs(I);
  if LX = 0.0 then
    Result := LY
  else if LY = 0.0 then
    Result := LX
  else if LX > LY then
  begin
    LT := LY / LX;
    Result := LX * TIdMath.Sqrt(1.0 + LT * LT);
  end
  else
  begin
    LT := LX / LY;
    Result := LY * TIdMath.Sqrt(1.0 + LT * LT);
  end;
end;

function TIdComplex.GetDimension: Integer;
begin
  Result := 2;
end;

end.
