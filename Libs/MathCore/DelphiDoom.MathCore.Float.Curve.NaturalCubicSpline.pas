{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveNaturalCubicSpline, the     }
{  cubic interpolating spline                                                  }
{                                                                              }
{  Port of idCurve_NaturalCubicSpline (idlib\math\Curve.h) of the Doom 3 GPL   }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.NaturalCubicSpline;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.MathCore.Float.Curve.Spline,
  DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   Cubic interpolating spline (idCurve_NaturalCubicSpline): the curve goes through all the
  ///   knots. The coefficients are computed when the curve is evaluated after a change.
  ///   Differences from the original: the closed boundary solves its system with a zero filled
  ///   matrix (the original builds the matrix on uninitialised stack memory, so only the entries
  ///   it sets are defined), the coefficient lists have zeros where the original leaves memory
  ///   unwritten, and an index out of range raises EArgumentOutOfRangeException. As in the
  ///   original, the polynomial of knot <c>i</c> is evaluated for the times up to knot <c>i</c>
  ///   (the index is the first knot not before the time), so the result for times in the last
  ///   interval uses coefficients the original does not write.
  /// </summary>
  TIdCurveNaturalCubicSpline<T> = class(TIdCurveSpline<T>)
  strict private
    FB: TList<T>;
    FC: TList<T>;
    FD: TList<T>;
    procedure AssureSize(const AList: TList<T>; const ASize: Integer);
    procedure SetupFree;
    procedure SetupClamped;
    procedure SetupClosed;
  protected
    procedure Setup;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    destructor Destroy; override;
    procedure Clear; override;
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Curve.LuSolver, DelphiDoom.MathCore.Float.Curve.Types;

{ TIdCurveNaturalCubicSpline<T> }

constructor TIdCurveNaturalCubicSpline<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create(AArithmetic);
  FB := TList<T>.Create;
  FC := TList<T>.Create;
  FD := TList<T>.Create;
end;

destructor TIdCurveNaturalCubicSpline<T>.Destroy;
begin
  FD.Free;
  FC.Free;
  FB.Free;
  inherited Destroy;
end;

procedure TIdCurveNaturalCubicSpline<T>.Clear;
begin
  inherited Clear;
  FValues.Clear;
  FB.Clear;
  FC.Clear;
  FD.Clear;
end;

procedure TIdCurveNaturalCubicSpline<T>.AssureSize(const AList: TList<T>; const ASize: Integer);
begin
  if AList.Count <> ASize then
    AList.Count := ASize;
end;

function TIdCurveNaturalCubicSpline<T>.GetCurrentValue(const ATime: Single): T;
var
  LClampedTime, LS: Single;
  LIndex: Integer;
begin
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  LS := ATime - TimeForIndex(LIndex);
  Setup;
  // values[i] + s * ( b[i] + s * ( c[i] + s * d[i] ) )
  Result := Arithmetic.Add(FValues[LIndex], Arithmetic.Multiply(Arithmetic.Add(FB[LIndex],
    Arithmetic.Multiply(Arithmetic.Add(FC[LIndex], Arithmetic.Multiply(FD[LIndex], LS)), LS)), LS));
end;

function TIdCurveNaturalCubicSpline<T>.GetCurrentFirstDerivative(const ATime: Single): T;
var
  LClampedTime, LS, LThreeS: Single;
  LIndex: Integer;
begin
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  LS := ATime - TimeForIndex(LIndex);
  Setup;
  // b[i] + s * ( 2.0f * c[i] + 3.0f * s * d[i] )
  LThreeS := 3.0 * LS;
  Result := Arithmetic.Add(FB[LIndex], Arithmetic.Multiply(Arithmetic.Add(
    Arithmetic.Multiply(FC[LIndex], 2.0), Arithmetic.Multiply(FD[LIndex], LThreeS)), LS));
end;

function TIdCurveNaturalCubicSpline<T>.GetCurrentSecondDerivative(const ATime: Single): T;
var
  LClampedTime, LS, LSixS: Single;
  LIndex: Integer;
begin
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  LS := ATime - TimeForIndex(LIndex);
  Setup;
  // 2.0f * c[i] + 6.0f * s * d[i]
  LSixS := 6.0 * LS;
  Result := Arithmetic.Add(Arithmetic.Multiply(FC[LIndex], 2.0),
    Arithmetic.Multiply(FD[LIndex], LSixS));
end;

procedure TIdCurveNaturalCubicSpline<T>.Setup;
begin
  if FChanged then
  begin
    case BoundaryType of
      TIdCurveBoundary.Free: SetupFree;
      TIdCurveBoundary.Clamped: SetupClamped;
      TIdCurveBoundary.Closed: SetupClosed;
    end;
    FChanged := False;
  end;
end;

procedure TIdCurveNaturalCubicSpline<T>.SetupFree;
var
  LCount, LIndex: Integer;
  LInverse, LScalar: Single;
  LD0, LD1, LBeta, LGamma: TArray<Single>;
  LAlpha, LDelta: TArray<T>;
  LSum: T;
begin
  LCount := FValues.Count;
  SetLength(LD0, LCount);
  SetLength(LD1, LCount);
  SetLength(LAlpha, LCount);
  SetLength(LBeta, LCount);
  SetLength(LGamma, LCount);
  SetLength(LDelta, LCount);

  for LIndex := 0 to LCount - 2 do
    LD0[LIndex] := FTimes[LIndex + 1] - FTimes[LIndex];

  for LIndex := 1 to LCount - 2 do
    LD1[LIndex] := FTimes[LIndex + 1] - FTimes[LIndex - 1];

  for LIndex := 1 to LCount - 2 do
  begin
    LSum := Arithmetic.Multiply(Arithmetic.Add(Arithmetic.Subtract(
      Arithmetic.Multiply(FValues[LIndex + 1], LD0[LIndex - 1]),
      Arithmetic.Multiply(FValues[LIndex], LD1[LIndex])),
      Arithmetic.Multiply(FValues[LIndex - 1], LD0[LIndex])), 3.0);
    LInverse := 1.0 / (LD0[LIndex - 1] * LD0[LIndex]);
    LAlpha[LIndex] := Arithmetic.Multiply(LSum, LInverse);
  end;

  LBeta[0] := 1.0;
  LGamma[0] := 0.0;
  LDelta[0] := Arithmetic.Subtract(FValues[0], FValues[0]);

  for LIndex := 1 to LCount - 2 do
  begin
    LBeta[LIndex] := 2.0 * LD1[LIndex] - LD0[LIndex - 1] * LGamma[LIndex - 1];
    LInverse := 1.0 / LBeta[LIndex];
    LGamma[LIndex] := LInverse * LD0[LIndex];
    LDelta[LIndex] := Arithmetic.Multiply(Arithmetic.Subtract(LAlpha[LIndex],
      Arithmetic.Multiply(LDelta[LIndex - 1], LD0[LIndex - 1])), LInverse);
  end;
  LBeta[LCount - 1] := 1.0;
  LDelta[LCount - 1] := Arithmetic.Subtract(FValues[0], FValues[0]);

  AssureSize(FB, LCount);
  AssureSize(FC, LCount);
  AssureSize(FD, LCount);

  FC[LCount - 1] := Arithmetic.Subtract(FValues[0], FValues[0]);

  for LIndex := LCount - 2 downto 0 do
  begin
    FC[LIndex] := Arithmetic.Subtract(LDelta[LIndex], Arithmetic.Multiply(FC[LIndex + 1],
      LGamma[LIndex]));
    LInverse := 1.0 / LD0[LIndex];
    LScalar := ID_CURVE_ONE_THIRD * LD0[LIndex];
    FB[LIndex] := Arithmetic.Subtract(Arithmetic.Multiply(Arithmetic.Subtract(
      FValues[LIndex + 1], FValues[LIndex]), LInverse), Arithmetic.Multiply(Arithmetic.Add(
      FC[LIndex + 1], Arithmetic.Multiply(FC[LIndex], 2.0)), LScalar));
    LScalar := ID_CURVE_ONE_THIRD * LInverse;
    FD[LIndex] := Arithmetic.Multiply(Arithmetic.Subtract(FC[LIndex + 1], FC[LIndex]), LScalar);
  end;
end;

procedure TIdCurveNaturalCubicSpline<T>.SetupClamped;
var
  LCount, LIndex: Integer;
  LInverse, LScalar: Single;
  LD0, LD1, LBeta, LGamma: TArray<Single>;
  LAlpha, LDelta: TArray<T>;
  LSum: T;
begin
  LCount := FValues.Count;
  SetLength(LD0, LCount);
  SetLength(LD1, LCount);
  SetLength(LAlpha, LCount);
  SetLength(LBeta, LCount);
  SetLength(LGamma, LCount);
  SetLength(LDelta, LCount);

  for LIndex := 0 to LCount - 2 do
    LD0[LIndex] := FTimes[LIndex + 1] - FTimes[LIndex];

  for LIndex := 1 to LCount - 2 do
    LD1[LIndex] := FTimes[LIndex + 1] - FTimes[LIndex - 1];

  LInverse := 1.0 / LD0[0];
  LScalar := 3.0 * (LInverse - 1.0);
  LAlpha[0] := Arithmetic.Multiply(Arithmetic.Subtract(FValues[1], FValues[0]), LScalar);
  LInverse := 1.0 / LD0[LCount - 2];
  LScalar := 3.0 * (1.0 - LInverse);
  LAlpha[LCount - 1] := Arithmetic.Multiply(Arithmetic.Subtract(FValues[LCount - 1],
    FValues[LCount - 2]), LScalar);

  for LIndex := 1 to LCount - 2 do
  begin
    LSum := Arithmetic.Multiply(Arithmetic.Add(Arithmetic.Subtract(
      Arithmetic.Multiply(FValues[LIndex + 1], LD0[LIndex - 1]),
      Arithmetic.Multiply(FValues[LIndex], LD1[LIndex])),
      Arithmetic.Multiply(FValues[LIndex - 1], LD0[LIndex])), 3.0);
    LInverse := 1.0 / (LD0[LIndex - 1] * LD0[LIndex]);
    LAlpha[LIndex] := Arithmetic.Multiply(LSum, LInverse);
  end;

  LBeta[0] := 2.0 * LD0[0];
  LGamma[0] := 0.5;
  LInverse := 1.0 / LBeta[0];
  LDelta[0] := Arithmetic.Multiply(LAlpha[0], LInverse);

  for LIndex := 1 to LCount - 2 do
  begin
    LBeta[LIndex] := 2.0 * LD1[LIndex] - LD0[LIndex - 1] * LGamma[LIndex - 1];
    LInverse := 1.0 / LBeta[LIndex];
    LGamma[LIndex] := LInverse * LD0[LIndex];
    LDelta[LIndex] := Arithmetic.Multiply(Arithmetic.Subtract(LAlpha[LIndex],
      Arithmetic.Multiply(LDelta[LIndex - 1], LD0[LIndex - 1])), LInverse);
  end;

  LBeta[LCount - 1] := LD0[LCount - 2] * (2.0 - LGamma[LCount - 2]);
  LInverse := 1.0 / LBeta[LCount - 1];
  LDelta[LCount - 1] := Arithmetic.Multiply(Arithmetic.Subtract(LAlpha[LCount - 1],
    Arithmetic.Multiply(LDelta[LCount - 2], LD0[LCount - 2])), LInverse);

  AssureSize(FB, LCount);
  AssureSize(FC, LCount);
  AssureSize(FD, LCount);

  FC[LCount - 1] := LDelta[LCount - 1];

  for LIndex := LCount - 2 downto 0 do
  begin
    FC[LIndex] := Arithmetic.Subtract(LDelta[LIndex], Arithmetic.Multiply(FC[LIndex + 1],
      LGamma[LIndex]));
    LInverse := 1.0 / LD0[LIndex];
    LScalar := ID_CURVE_ONE_THIRD * LD0[LIndex];
    FB[LIndex] := Arithmetic.Subtract(Arithmetic.Multiply(Arithmetic.Subtract(
      FValues[LIndex + 1], FValues[LIndex]), LInverse), Arithmetic.Multiply(Arithmetic.Add(
      FC[LIndex + 1], Arithmetic.Multiply(FC[LIndex], 2.0)), LScalar));
    LScalar := ID_CURVE_ONE_THIRD * LInverse;
    FD[LIndex] := Arithmetic.Multiply(Arithmetic.Subtract(FC[LIndex + 1], FC[LIndex]), LScalar);
  end;
end;

procedure TIdCurveNaturalCubicSpline<T>.SetupClosed;
var
  LCount, LIndex, LJ: Integer;
  LC0, LC1, LScalar: Single;
  LD0: TArray<Single>;
  LMatrix, LX: TArray<Single>;
  LComponent: Single;
  LDimension: Integer;
  LValue: T;
begin
  LCount := FValues.Count;
  SetLength(LD0, LCount);
  // zero filled, see the remarks of the class
  SetLength(LMatrix, LCount * LCount);
  SetLength(LX, LCount);

  AssureSize(FB, LCount);
  AssureSize(FC, LCount);
  AssureSize(FD, LCount);

  for LIndex := 0 to LCount - 2 do
    LD0[LIndex] := FTimes[LIndex + 1] - FTimes[LIndex];

  // matrix of system
  LMatrix[0 * LCount + 0] := 1.0;
  LMatrix[0 * LCount + LCount - 1] := -1.0;
  for LIndex := 1 to LCount - 2 do
  begin
    LMatrix[LIndex * LCount + LIndex - 1] := LD0[LIndex - 1];
    LMatrix[LIndex * LCount + LIndex] := 2.0 * (LD0[LIndex - 1] + LD0[LIndex]);
    LMatrix[LIndex * LCount + LIndex + 1] := LD0[LIndex];
  end;
  LMatrix[(LCount - 1) * LCount + LCount - 2] := LD0[LCount - 2];
  LMatrix[(LCount - 1) * LCount + 0] := 2.0 * (LD0[LCount - 2] + LD0[0]);
  LMatrix[(LCount - 1) * LCount + 1] := LD0[0];

  // right-hand side
  FC[0] := Arithmetic.Subtract(FValues[0], FValues[0]);
  for LIndex := 1 to LCount - 2 do
  begin
    LC0 := 1.0 / LD0[LIndex];
    LC1 := 1.0 / LD0[LIndex - 1];
    FC[LIndex] := Arithmetic.Multiply(Arithmetic.Subtract(Arithmetic.Multiply(
      Arithmetic.Subtract(FValues[LIndex + 1], FValues[LIndex]), LC0), Arithmetic.Multiply(
      Arithmetic.Subtract(FValues[LIndex], FValues[LIndex - 1]), LC1)), 3.0);
  end;
  LC0 := 1.0 / LD0[0];
  LC1 := 1.0 / LD0[LCount - 2];
  FC[LCount - 1] := Arithmetic.Multiply(Arithmetic.Subtract(Arithmetic.Multiply(
    Arithmetic.Subtract(FValues[1], FValues[0]), LC0), Arithmetic.Multiply(
    Arithmetic.Subtract(FValues[0], FValues[LCount - 2]), LC1)), 3.0);

  // solve system for each dimension
  TIdCurveLuSolver.Factor(LMatrix, LCount);
  LDimension := Arithmetic.GetDimension(FValues[0]);
  for LIndex := 0 to LDimension - 1 do
  begin
    for LJ := 0 to LCount - 1 do
      LX[LJ] := Arithmetic.GetComponent(FC[LJ], LIndex);
    TIdCurveLuSolver.Solve(LMatrix, LCount, LX);
    for LJ := 0 to LCount - 1 do
    begin
      LValue := FC[LJ];
      LComponent := LX[LJ];
      Arithmetic.SetComponent(LValue, LIndex, LComponent);
      FC[LJ] := LValue;
    end;
  end;

  for LIndex := 0 to LCount - 2 do
  begin
    LC0 := 1.0 / LD0[LIndex];
    LScalar := ID_CURVE_ONE_THIRD;
    // c0 * ( v[i+1] - v[i] ) - ( 1/3 * ( c[i+1] + 2 c[i] ) ) * d0[i]
    FB[LIndex] := Arithmetic.Subtract(Arithmetic.Multiply(Arithmetic.Subtract(
      FValues[LIndex + 1], FValues[LIndex]), LC0), Arithmetic.Multiply(Arithmetic.Multiply(
      Arithmetic.Add(FC[LIndex + 1], Arithmetic.Multiply(FC[LIndex], 2.0)), LScalar),
      LD0[LIndex]));
    LScalar := ID_CURVE_ONE_THIRD * LC0;
    FD[LIndex] := Arithmetic.Multiply(Arithmetic.Subtract(FC[LIndex + 1], FC[LIndex]), LScalar);
  end;
end;

end.
