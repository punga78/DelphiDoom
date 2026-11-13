{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdPolynomial, a polynomial with    }
{  real coefficients                                                           }
{                                                                              }
{  Port of idPolynomial (idlib\math\Polynomial.h and Polynomial.cpp) of the    }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Polynomial;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Complex;

type
  /// <summary>
  ///   A polynomial of arbitrary degree with Single coefficients (idPolynomial); coefficient i is
  ///   the one of x^i. A value type: the coefficients are a dynamic array that every operation
  ///   copies before writing, so a copy of the record never changes the original. Differences from
  ///   the original: the compound assignments (<c>+=</c>, <c>-=</c>, <c>*=</c>, <c>/=</c>) are not
  ///   ported (the original <c>/=</c> stores the reciprocal instead of multiplying, a defect), and
  ///   a polynomial that the original leaves without storage (degree 0 after a multiplication by
  ///   zero, or <c>Zero</c>) has one zero coefficient here.
  /// </summary>
  TIdPolynomial = record
  private
    FDegree: Integer;
    FCoefficients: TArray<Single>;
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
    procedure Resize(const ADegree: Integer; const AKeep: Boolean);
    class function Laguer(const ACoefficients: array of TIdComplex; const ADegree: Integer;
      var AX: TIdComplex): Integer; static;
  public
    /// <summary>idPolynomial( int d ): degree d, coefficients not set (zero here)</summary>
    class function Create(const ADegree: Integer): TIdPolynomial; overload; static;
    /// <summary>a*x + b</summary>
    class function Create(const A, B: Single): TIdPolynomial; overload; static;
    /// <summary>a*x^2 + b*x + c</summary>
    class function Create(const A, B, C: Single): TIdPolynomial; overload; static;
    class function Create(const A, B, C, D: Single): TIdPolynomial; overload; static;
    class function Create(const A, B, C, D, E: Single): TIdPolynomial; overload; static;
    /// <summary>The coefficient of x^AIndex, 0 to degree</summary>
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    property Degree: Integer read FDegree;
    class operator Negative(const A: TIdPolynomial): TIdPolynomial;
    class operator Add(const A, B: TIdPolynomial): TIdPolynomial;
    class operator Subtract(const A, B: TIdPolynomial): TIdPolynomial;
    class operator Multiply(const A: TIdPolynomial; const B: Single): TIdPolynomial;
    class operator Divide(const A: TIdPolynomial; const B: Single): TIdPolynomial;
    class operator Equal(const A, B: TIdPolynomial): Boolean;
    class operator NotEqual(const A, B: TIdPolynomial): Boolean;
    function Compare(const A: TIdPolynomial; const AEpsilon: Single): Boolean;
    procedure Zero; overload;
    procedure Zero(const ADegree: Integer); overload;
    function GetDimension: Integer;
    function GetValue(const AX: Single): Single; overload;
    function GetValue(const AX: TIdComplex): TIdComplex; overload;
    function GetDerivative: TIdPolynomial;
    function GetAntiDerivative: TIdPolynomial;
    /// <summary>All the roots, real and complex, sorted by the real part; returns the degree</summary>
    function GetRoots(out ARoots: TArray<TIdComplex>): Integer; overload;
    /// <summary>The real roots (ARoots needs room for the degree); returns how many</summary>
    function GetRoots(var ARoots: array of Single): Integer; overload;
    class function GetRoots1(const A, B: Single; var ARoots: array of Single): Integer; static;
    class function GetRoots2(A, B, C: Single; var ARoots: array of Single): Integer; static;
    class function GetRoots3(A, B, C, D: Single; var ARoots: array of Single): Integer; static;
    class function GetRoots4(A, B, C, D, E: Single; var ARoots: array of Single): Integer; static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

const
  // the float constants of the original (1.0f / 3.0f is rounded to a float before it is used)
  ONE_THIRD: Single = 1.0 / 3.0;
  MINUS_ONE_THIRD: Single = -1.0 / 3.0;
  ONE_TWENTY_SEVENTH: Single = 1.0 / 27.0;
  POLY_EPSILON: Single = 1E-6;
  FLOAT_TWO: Single = 2.0;
  ITERATIONS_PER_STEP = 10;
  FRACTIONS: array[0..8] of Single = (0.0, 0.5, 0.25, 0.75, 0.13, 0.38, 0.62, 0.88, 1.0);

{ TIdPolynomial }

procedure TIdPolynomial.Resize(const ADegree: Integer; const AKeep: Boolean);
var
  LNew: TArray<Single>;
  LIndex: Integer;
begin
  SetLength(LNew, ADegree + 1);
  if AKeep then
    for LIndex := 0 to Min(FDegree, ADegree) do
      LNew[LIndex] := FCoefficients[LIndex];
  FCoefficients := LNew;
  FDegree := ADegree;
end;

function TIdPolynomial.GetItem(const AIndex: Integer): Single;
begin
  Result := FCoefficients[AIndex];
end;

procedure TIdPolynomial.SetItem(const AIndex: Integer; const AValue: Single);
begin
  // a copy of the record shares the array until one of them writes
  SetLength(FCoefficients, Length(FCoefficients));
  FCoefficients[AIndex] := AValue;
end;

class function TIdPolynomial.Create(const ADegree: Integer): TIdPolynomial;
begin
  Result.FDegree := -1;
  Result.Resize(ADegree, False);
end;

class function TIdPolynomial.Create(const A, B: Single): TIdPolynomial;
begin
  Result := Create(1);
  Result.FCoefficients[0] := B;
  Result.FCoefficients[1] := A;
end;

class function TIdPolynomial.Create(const A, B, C: Single): TIdPolynomial;
begin
  Result := Create(2);
  Result.FCoefficients[0] := C;
  Result.FCoefficients[1] := B;
  Result.FCoefficients[2] := A;
end;

class function TIdPolynomial.Create(const A, B, C, D: Single): TIdPolynomial;
begin
  Result := Create(3);
  Result.FCoefficients[0] := D;
  Result.FCoefficients[1] := C;
  Result.FCoefficients[2] := B;
  Result.FCoefficients[3] := A;
end;

class function TIdPolynomial.Create(const A, B, C, D, E: Single): TIdPolynomial;
begin
  Result := Create(4);
  Result.FCoefficients[0] := E;
  Result.FCoefficients[1] := D;
  Result.FCoefficients[2] := C;
  Result.FCoefficients[3] := B;
  Result.FCoefficients[4] := A;
end;

class operator TIdPolynomial.Negative(const A: TIdPolynomial): TIdPolynomial;
var
  LIndex: Integer;
begin
  Result := Create(A.FDegree);
  for LIndex := 0 to A.FDegree do
    Result.FCoefficients[LIndex] := -A.FCoefficients[LIndex];
end;

class operator TIdPolynomial.Add(const A, B: TIdPolynomial): TIdPolynomial;
var
  I: Integer;
begin
  if A.FDegree > B.FDegree then
  begin
    Result := Create(A.FDegree);
    for I := 0 to B.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I] + B.FCoefficients[I];
    for I := B.FDegree + 1 to A.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I];
  end
  else if B.FDegree > A.FDegree then
  begin
    Result := Create(B.FDegree);
    for I := 0 to A.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I] + B.FCoefficients[I];
    for I := A.FDegree + 1 to B.FDegree do
      Result.FCoefficients[I] := B.FCoefficients[I];
  end
  else
  begin
    Result := Create(A.FDegree);
    // the degree drops to the highest non-zero sum
    Result.FDegree := 0;
    for I := 0 to A.FDegree do
    begin
      Result.FCoefficients[I] := A.FCoefficients[I] + B.FCoefficients[I];
      if Result.FCoefficients[I] <> 0.0 then
        Result.FDegree := I;
    end;
  end;
end;

class operator TIdPolynomial.Subtract(const A, B: TIdPolynomial): TIdPolynomial;
var
  I: Integer;
begin
  if A.FDegree > B.FDegree then
  begin
    Result := Create(A.FDegree);
    for I := 0 to B.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I] - B.FCoefficients[I];
    for I := B.FDegree + 1 to A.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I];
  end
  else if B.FDegree >= A.FDegree then
  begin
    Result := Create(B.FDegree);
    for I := 0 to A.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I] - B.FCoefficients[I];
    for I := A.FDegree + 1 to B.FDegree do
      Result.FCoefficients[I] := -B.FCoefficients[I];
  end
  else
    Result := Create(0);
end;

class operator TIdPolynomial.Multiply(const A: TIdPolynomial; const B: Single): TIdPolynomial;
var
  I: Integer;
begin
  if B = 0.0 then
    Result := Create(0)
  else
  begin
    Result := Create(A.FDegree);
    for I := 0 to A.FDegree do
      Result.FCoefficients[I] := A.FCoefficients[I] * B;
  end;
end;

class operator TIdPolynomial.Divide(const A: TIdPolynomial; const B: Single): TIdPolynomial;
var
  LInverse: Single;
  I: Integer;
begin
  Result := Create(A.FDegree);
  LInverse := 1.0 / B;
  for I := 0 to A.FDegree do
    Result.FCoefficients[I] := A.FCoefficients[I] * LInverse;
end;

class operator TIdPolynomial.Equal(const A, B: TIdPolynomial): Boolean;
var
  I: Integer;
begin
  if A.FDegree <> B.FDegree then
    Exit(False);
  for I := 0 to A.FDegree do
    if A.FCoefficients[I] <> B.FCoefficients[I] then
      Exit(False);
  Result := True;
end;

class operator TIdPolynomial.NotEqual(const A, B: TIdPolynomial): Boolean;
begin
  Result := not (A = B);
end;

function TIdPolynomial.Compare(const A: TIdPolynomial; const AEpsilon: Single): Boolean;
var
  I: Integer;
begin
  if FDegree <> A.FDegree then
    Exit(False);
  for I := 0 to FDegree do
    if TIdMath.Fabs(FCoefficients[I] - A.FCoefficients[I]) > AEpsilon then
      Exit(False);
  Result := True;
end;

procedure TIdPolynomial.Zero;
begin
  if Length(FCoefficients) = 0 then
    Resize(0, False);
  FDegree := 0;
end;

procedure TIdPolynomial.Zero(const ADegree: Integer);
var
  I: Integer;
begin
  Resize(ADegree, False);
  for I := 0 to FDegree do
    FCoefficients[I] := 0.0;
end;

function TIdPolynomial.GetDimension: Integer;
begin
  Result := FDegree;
end;

function TIdPolynomial.GetValue(const AX: Single): Single;
var
  LZ: Single;
  I: Integer;
begin
  Result := FCoefficients[0];
  LZ := AX;
  for I := 1 to FDegree do
  begin
    Result := Result + FCoefficients[I] * LZ;
    LZ := LZ * AX;
  end;
end;

function TIdPolynomial.GetValue(const AX: TIdComplex): TIdComplex;
var
  LZ: TIdComplex;
  I: Integer;
begin
  Result.SetValues(FCoefficients[0], 0.0);
  LZ := AX;
  for I := 1 to FDegree do
  begin
    Result := Result + FCoefficients[I] * LZ;
    LZ := LZ * AX;
  end;
end;

function TIdPolynomial.GetDerivative: TIdPolynomial;
var
  I: Integer;
begin
  if FDegree = 0 then
  begin
    // the original returns an empty polynomial (degree -1)
    Result.FDegree := -1;
    Result.FCoefficients := nil;
    Exit;
  end;
  Result := Create(FDegree - 1);
  for I := 1 to FDegree do
    Result.FCoefficients[I - 1] := I * FCoefficients[I];
end;

function TIdPolynomial.GetAntiDerivative: TIdPolynomial;
var
  I: Integer;
begin
  if FDegree = 0 then
  begin
    Result.FDegree := -1;
    Result.FCoefficients := nil;
    Exit;
  end;
  Result := Create(FDegree + 1);
  Result.FCoefficients[0] := 0.0;
  for I := 0 to FDegree do
    Result.FCoefficients[I + 1] := FCoefficients[I] / (I + 1);
end;

class function TIdPolynomial.Laguer(const ACoefficients: array of TIdComplex; const ADegree: Integer;
  var AX: TIdComplex): Integer;
const
  MAX_ITERATIONS = ITERATIONS_PER_STEP * 8;
var
  I, J: Integer;
  LAbsX, LAbsP, LAbsM, LError, LMaximum: Single;
  LDX, LCX, LB, LD, LF, LG, LS, LGPS, LGMS, LG2: TIdComplex;
begin
  for I := 1 to MAX_ITERATIONS do
  begin
    LB := ACoefficients[ADegree];
    LError := LB.Abs;
    LD.Zero;
    LF.Zero;
    LAbsX := AX.Abs;
    for J := ADegree - 1 downto 0 do
    begin
      LF := AX * LF + LD;
      LD := AX * LD + LB;
      LB := AX * LB + ACoefficients[J];
      LError := LB.Abs + LAbsX * LError;
    end;
    if LB.Abs < LError * POLY_EPSILON then
      Exit(I);
    LG := LD / LB;
    LG2 := LG * LG;
    LS := (Single(ADegree - 1) * (Single(ADegree) * (LG2 - FLOAT_TWO * LF / LB) - LG2)).Sqrt;
    LGPS := LG + LS;
    LGMS := LG - LS;
    LAbsP := LGPS.Abs;
    LAbsM := LGMS.Abs;
    if LAbsP < LAbsM then
      LGPS := LGMS;
    // Max( x, y ) of idLib is (x > y) ? x : y; a NaN (0 / 0 at a double root) selects the second
    // argument and the comparison with zero is false, so the original falls into the else branch
    if LAbsP > LAbsM then
      LMaximum := LAbsP
    else
      LMaximum := LAbsM;
    if (not IsNan(LMaximum)) and (LMaximum > 0.0) then
      LDX := Single(ADegree) / LGPS
    else
      LDX := TIdMath.Exp(TIdMath.Log(1.0 + LAbsX)) *
        TIdComplex.Create(TIdMath.Cos(I), TIdMath.Sin(I));
    LCX := AX - LDX;
    if AX = LCX then
      Exit(I);
    if I mod ITERATIONS_PER_STEP = 0 then
      AX := LCX
    else
      AX := AX - FRACTIONS[I div ITERATIONS_PER_STEP] * LDX;
  end;
  Result := MAX_ITERATIONS + 1;
end;

function TIdPolynomial.GetRoots(out ARoots: TArray<TIdComplex>): Integer;
var
  LCoefficients: array of TIdComplex;
  LX, LB, LC, LValue: TIdComplex;
  I, J: Integer;
begin
  SetLength(ARoots, FDegree);
  SetLength(LCoefficients, FDegree + 1);
  for I := 0 to FDegree do
    LCoefficients[I].SetValues(FCoefficients[I], 0.0);
  for I := FDegree - 1 downto 0 do
  begin
    LX.Zero;
    Laguer(LCoefficients, I + 1, LX);
    if TIdMath.Fabs(LX.I) < 2.0 * POLY_EPSILON * TIdMath.Fabs(LX.R) then
      LX.I := 0.0;
    ARoots[I] := LX;
    LB := LCoefficients[I + 1];
    for J := I downto 0 do
    begin
      LC := LCoefficients[J];
      LCoefficients[J] := LB;
      LB := LX * LB + LC;
    end;
  end;
  for I := 0 to FDegree do
    LCoefficients[I].SetValues(FCoefficients[I], 0.0);
  for I := 0 to FDegree - 1 do
    Laguer(LCoefficients, FDegree, ARoots[I]);
  // insertion sort by the real part
  for I := 1 to FDegree - 1 do
  begin
    LValue := ARoots[I];
    J := I - 1;
    while J >= 0 do
    begin
      if ARoots[J].R <= LValue.R then
        Break;
      ARoots[J + 1] := ARoots[J];
      Dec(J);
    end;
    ARoots[J + 1] := LValue;
  end;
  Result := FDegree;
end;

function TIdPolynomial.GetRoots(var ARoots: array of Single): Integer;
var
  LComplexRoots: TArray<TIdComplex>;
  I: Integer;
begin
  case FDegree of
    0: Exit(0);
    1: Exit(GetRoots1(FCoefficients[1], FCoefficients[0], ARoots));
    2: Exit(GetRoots2(FCoefficients[2], FCoefficients[1], FCoefficients[0], ARoots));
    3: Exit(GetRoots3(FCoefficients[3], FCoefficients[2], FCoefficients[1], FCoefficients[0], ARoots));
    4: Exit(GetRoots4(FCoefficients[4], FCoefficients[3], FCoefficients[2], FCoefficients[1],
      FCoefficients[0], ARoots));
  end;
  // no solution in radicals from degree five up (Abel-Ruffini): numerical roots
  GetRoots(LComplexRoots);
  Result := 0;
  for I := 0 to FDegree - 1 do
    if LComplexRoots[I].I = 0.0 then
    begin
      // as the original, the real root keeps the index of its complex root
      ARoots[I] := LComplexRoots[I].R;
      Inc(Result);
    end;
end;

class function TIdPolynomial.GetRoots1(const A, B: Single; var ARoots: array of Single): Integer;
begin
  ARoots[0] := -B / A;
  Result := 1;
end;

class function TIdPolynomial.GetRoots2(A, B, C: Single; var ARoots: array of Single): Integer;
var
  LInverseA, LDiscriminant: Single;
begin
  if A <> 1.0 then
  begin
    LInverseA := 1.0 / A;
    C := C * LInverseA;
    B := B * LInverseA;
  end;
  LDiscriminant := B * B - 4.0 * C;
  if LDiscriminant < 0.0 then
    Result := 0
  else if LDiscriminant > 0.0 then
  begin
    LDiscriminant := TIdMath.Sqrt(LDiscriminant);
    ARoots[0] := 0.5 * (-B - LDiscriminant);
    ARoots[1] := 0.5 * (-B + LDiscriminant);
    Result := 2;
  end
  else
  begin
    ARoots[0] := 0.5 * -B;
    Result := 1;
  end;
end;

class function TIdPolynomial.GetRoots3(A, B, C, D: Single; var ARoots: array of Single): Integer;
var
  LInverseA, F, G, LHalfG, LOffset, LDiscriminant, LDistance, LAngle, LCos, LSin, T: Single;
begin
  if A <> 1.0 then
  begin
    LInverseA := 1.0 / A;
    D := D * LInverseA;
    C := C * LInverseA;
    B := B * LInverseA;
  end;
  F := ONE_THIRD * (3.0 * C - B * B);
  G := ONE_TWENTY_SEVENTH * (2.0 * B * B * B - 9.0 * C * B + 27.0 * D);
  LHalfG := 0.5 * G;
  LOffset := ONE_THIRD * B;
  LDiscriminant := 0.25 * G * G + ONE_TWENTY_SEVENTH * F * F * F;
  if LDiscriminant < 0.0 then
  begin
    LDistance := TIdMath.Sqrt(MINUS_ONE_THIRD * F);
    LAngle := ONE_THIRD * TIdMath.ATan(TIdMath.Sqrt(-LDiscriminant), -LHalfG);
    LCos := TIdMath.Cos(LAngle);
    LSin := TIdMath.Sin(LAngle);
    ARoots[0] := 2.0 * LDistance * LCos - LOffset;
    ARoots[1] := -LDistance * (LCos + ID_SQRT_THREE * LSin) - LOffset;
    ARoots[2] := -LDistance * (LCos - ID_SQRT_THREE * LSin) - LOffset;
    Result := 3;
  end
  else if LDiscriminant > 0.0 then
  begin
    LDiscriminant := TIdMath.Sqrt(LDiscriminant);
    T := -LHalfG + LDiscriminant;
    if T >= 0.0 then
      ARoots[0] := TIdMath.Pow(T, ONE_THIRD)
    else
      ARoots[0] := -TIdMath.Pow(-T, ONE_THIRD);
    T := -LHalfG - LDiscriminant;
    if T >= 0.0 then
      ARoots[0] := ARoots[0] + TIdMath.Pow(T, ONE_THIRD)
    else
      ARoots[0] := ARoots[0] - TIdMath.Pow(-T, ONE_THIRD);
    ARoots[0] := ARoots[0] - LOffset;
    Result := 1;
  end
  else
  begin
    if LHalfG >= 0.0 then
      T := -TIdMath.Pow(LHalfG, ONE_THIRD)
    else
      T := TIdMath.Pow(-LHalfG, ONE_THIRD);
    ARoots[0] := 2.0 * T - LOffset;
    ARoots[1] := -T - LOffset;
    ARoots[2] := ARoots[1];
    Result := 3;
  end;
end;

class function TIdPolynomial.GetRoots4(A, B, C, D, E: Single; var ARoots: array of Single): Integer;
var
  LCount: Integer;
  LInverseA, Y, LDiscriminant, R, S1, S2, T1, T2, TP, TM: Single;
  LRoots3: array[0..2] of Single;
begin
  if A <> 1.0 then
  begin
    LInverseA := 1.0 / A;
    E := E * LInverseA;
    D := D * LInverseA;
    C := C * LInverseA;
    B := B * LInverseA;
  end;
  LCount := 0;
  GetRoots3(1.0, -C, B * D - 4.0 * E, -B * B * E + 4.0 * C * E - D * D, LRoots3);
  Y := LRoots3[0];
  LDiscriminant := 0.25 * B * B - C + Y;
  if LDiscriminant < 0.0 then
    Exit(0);
  if LDiscriminant > 0.0 then
  begin
    R := TIdMath.Sqrt(LDiscriminant);
    T1 := 0.75 * B * B - R * R - 2.0 * C;
    T2 := (4.0 * B * C - 8.0 * D - B * B * B) / (4.0 * R);
    TP := T1 + T2;
    TM := T1 - T2;
    if TP >= 0.0 then
    begin
      S1 := TIdMath.Sqrt(TP);
      ARoots[LCount] := -0.25 * B + 0.5 * (R + S1);
      Inc(LCount);
      ARoots[LCount] := -0.25 * B + 0.5 * (R - S1);
      Inc(LCount);
    end;
    if TM >= 0.0 then
    begin
      S2 := TIdMath.Sqrt(TM);
      ARoots[LCount] := -0.25 * B + 0.5 * (S2 - R);
      Inc(LCount);
      ARoots[LCount] := -0.25 * B - 0.5 * (S2 + R);
      Inc(LCount);
    end;
    Result := LCount;
  end
  else
  begin
    T2 := Y * Y - 4.0 * E;
    if T2 >= 0.0 then
    begin
      T2 := 2.0 * TIdMath.Sqrt(T2);
      T1 := 0.75 * B * B - 2.0 * C;
      if T1 + T2 >= 0.0 then
      begin
        S1 := TIdMath.Sqrt(T1 + T2);
        ARoots[LCount] := -0.25 * B + 0.5 * S1;
        Inc(LCount);
        ARoots[LCount] := -0.25 * B - 0.5 * S1;
        Inc(LCount);
      end;
      if T1 - T2 >= 0.0 then
      begin
        S2 := TIdMath.Sqrt(T1 - T2);
        ARoots[LCount] := -0.25 * B + 0.5 * S2;
        Inc(LCount);
        ARoots[LCount] := -0.25 * B - 0.5 * S2;
        Inc(LCount);
      end;
    end;
    Result := LCount;
  end;
end;

end.
