{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveNURBS, the non-uniform      }
{  rational B-spline                                                           }
{                                                                              }
{  Port of idCurve_NURBS (idlib\math\Curve.h) of the Doom 3 GPL Source Code.   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.NURBS;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.MathCore.Float.Curve.NonUniformBSpline,
  DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   Non-uniform rational B-spline, NURBS (idCurve_NURBS): a NUBS with a weight per knot (1 for
  ///   a knot added without weight). As in the original, adding or removing a knot does not mark
  ///   the curve as changed, and the derivatives of a curve with one knot return the knot value.
  /// </summary>
  TIdCurveNURBS<T> = class(TIdCurveNonUniformBSpline<T>)
  strict private
    FWeights: TList<Single>;
  protected
    /// <summary>The weight of a knot, extrapolated (or repeated, if closed) outside the list</summary>
    function WeightForIndex(const AIndex: Integer): Single;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    destructor Destroy; override;
    /// <summary>Adds a knot with weight 1</summary>
    function AddValue(const ATime: Single; const AValue: T): Integer; overload; override;
    function AddValue(const ATime: Single; const AValue: T; const AWeight: Single): Integer;
      reintroduce; overload;
    procedure RemoveIndex(const AIndex: Integer); override;
    procedure Clear; override;
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Curve.Types;

{ TIdCurveNURBS<T> }

constructor TIdCurveNURBS<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create(AArithmetic);
  FWeights := TList<Single>.Create;
end;

destructor TIdCurveNURBS<T>.Destroy;
begin
  FWeights.Free;
  inherited Destroy;
end;

function TIdCurveNURBS<T>.AddValue(const ATime: Single; const AValue: T): Integer;
begin
  Result := IndexForTime(ATime);
  FTimes.Insert(Result, ATime);
  FValues.Insert(Result, AValue);
  FWeights.Insert(Result, 1.0);
end;

function TIdCurveNURBS<T>.AddValue(const ATime: Single; const AValue: T;
  const AWeight: Single): Integer;
begin
  Result := IndexForTime(ATime);
  FTimes.Insert(Result, ATime);
  FValues.Insert(Result, AValue);
  FWeights.Insert(Result, AWeight);
end;

procedure TIdCurveNURBS<T>.RemoveIndex(const AIndex: Integer);
begin
  FValues.Delete(AIndex);
  FTimes.Delete(AIndex);
  FWeights.Delete(AIndex);
end;

procedure TIdCurveNURBS<T>.Clear;
begin
  FValues.Clear;
  FTimes.Clear;
  FWeights.Clear;
  FCurrentIndex := -1;
end;

function TIdCurveNURBS<T>.WeightForIndex(const AIndex: Integer): Single;
var
  LLast: Integer;
begin
  LLast := FWeights.Count - 1;
  if AIndex < 0 then
  begin
    if BoundaryType = TIdCurveBoundary.Closed then
      Result := FWeights[FWeights.Count + AIndex mod FWeights.Count]
    else
      Result := FWeights[0] + AIndex * (FWeights[1] - FWeights[0]);
  end
  else if AIndex > LLast then
  begin
    if BoundaryType = TIdCurveBoundary.Closed then
      Result := FWeights[AIndex mod FWeights.Count]
    else
      Result := FWeights[LLast] + (AIndex - LLast) * (FWeights[LLast] - FWeights[LLast - 1]);
  end
  else
    Result := FWeights[AIndex];
end;

function TIdCurveNURBS<T>.GetCurrentValue(const ATime: Single): T;
var
  LIndex, LJ, LK: Integer;
  LW, LB, LClampedTime: Single;
  LBasis: TArray<Single>;
  LV: T;
begin
  if FTimes.Count = 1 then
  begin
    Result := FValues[0];
    Exit;
  end;
  SetLength(LBasis, FOrder + 2);
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  Basis(LIndex - 1, FOrder, LClampedTime, LBasis, 0);
  LV := Arithmetic.Subtract(FValues[0], FValues[0]);
  LW := 0.0;
  for LJ := 0 to FOrder - 1 do
  begin
    LK := LIndex + LJ - (FOrder shr 1);
    LB := LBasis[LJ] * WeightForIndex(LK);
    LW := LW + LB;
    LV := Arithmetic.Add(LV, Arithmetic.Multiply(ValueForIndex(LK), LB));
  end;
  Result := Arithmetic.Divide(LV, LW);
end;

function TIdCurveNURBS<T>.GetCurrentFirstDerivative(const ATime: Single): T;
var
  LIndex, LJ, LK: Integer;
  LW, LWb, LWd1, LB, LD1, LClampedTime, LDenominator: Single;
  LBasis, LD1Values: TArray<Single>;
  LV, LVb, LVd1: T;
begin
  if FTimes.Count = 1 then
  begin
    Result := FValues[0];
    Exit;
  end;
  SetLength(LBasis, FOrder + 2);
  SetLength(LD1Values, FOrder + 2);
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  Basis(LIndex - 1, FOrder, LClampedTime, LBasis, 0);
  BasisFirstDerivative(LIndex - 1, FOrder, LClampedTime, LD1Values, 0);
  LVb := Arithmetic.Subtract(FValues[0], FValues[0]);
  LVd1 := LVb;
  LWb := 0.0;
  LWd1 := 0.0;
  for LJ := 0 to FOrder - 1 do
  begin
    LK := LIndex + LJ - (FOrder shr 1);
    LW := WeightForIndex(LK);
    LB := LBasis[LJ] * LW;
    LD1 := LD1Values[LJ] * LW;
    LWb := LWb + LB;
    LWd1 := LWd1 + LD1;
    LV := ValueForIndex(LK);
    LVb := Arithmetic.Add(LVb, Arithmetic.Multiply(LV, LB));
    LVd1 := Arithmetic.Add(LVd1, Arithmetic.Multiply(LV, LD1));
  end;
  LDenominator := LWb * LWb;
  Result := Arithmetic.Divide(Arithmetic.Subtract(Arithmetic.Multiply(LVd1, LWb),
    Arithmetic.Multiply(LVb, LWd1)), LDenominator);
end;

function TIdCurveNURBS<T>.GetCurrentSecondDerivative(const ATime: Single): T;
var
  LIndex, LJ, LK: Integer;
  LW, LWb, LWd1, LWd2, LB, LD1, LD2, LClampedTime: Single;
  LBasis, LD1Values, LD2Values: TArray<Single>;
  LV, LVb, LVd1, LVd2, LLeft, LRight: T;
  LSquare, LFourth: Single;
begin
  if FTimes.Count = 1 then
  begin
    Result := FValues[0];
    Exit;
  end;
  SetLength(LBasis, FOrder + 2);
  SetLength(LD1Values, FOrder + 2);
  SetLength(LD2Values, FOrder + 2);
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  Basis(LIndex - 1, FOrder, LClampedTime, LBasis, 0);
  BasisFirstDerivative(LIndex - 1, FOrder, LClampedTime, LD1Values, 0);
  BasisSecondDerivative(LIndex - 1, FOrder, LClampedTime, LD2Values, 0);
  LVb := Arithmetic.Subtract(FValues[0], FValues[0]);
  LVd1 := LVb;
  LVd2 := LVb;
  LWb := 0.0;
  LWd1 := 0.0;
  LWd2 := 0.0;
  for LJ := 0 to FOrder - 1 do
  begin
    LK := LIndex + LJ - (FOrder shr 1);
    LW := WeightForIndex(LK);
    LB := LBasis[LJ] * LW;
    LD1 := LD1Values[LJ] * LW;
    LD2 := LD2Values[LJ] * LW;
    LWb := LWb + LB;
    LWd1 := LWd1 + LD1;
    LWd2 := LWd2 + LD2;
    LV := ValueForIndex(LK);
    LVb := Arithmetic.Add(LVb, Arithmetic.Multiply(LV, LB));
    LVd1 := Arithmetic.Add(LVd1, Arithmetic.Multiply(LV, LD1));
    LVd2 := Arithmetic.Add(LVd2, Arithmetic.Multiply(LV, LD2));
  end;
  // ( ( wb * wb ) * ( wb * vd2 - vb * wd2 ) - ( wb * vd1 - vb * wd1 ) * 2.0f * wb * wd1 ) / ( wb^4 )
  LSquare := LWb * LWb;
  LLeft := Arithmetic.Multiply(Arithmetic.Subtract(Arithmetic.Multiply(LVd2, LWb),
    Arithmetic.Multiply(LVb, LWd2)), LSquare);
  LRight := Arithmetic.Subtract(Arithmetic.Multiply(LVd1, LWb), Arithmetic.Multiply(LVb, LWd1));
  // the original scales the vector three times: ( v * 2.0f ) * wb ) * wd1
  LRight := Arithmetic.Multiply(Arithmetic.Multiply(Arithmetic.Multiply(LRight, 2.0), LWb), LWd1);
  LFourth := LWb * LWb * LWb * LWb;
  Result := Arithmetic.Divide(Arithmetic.Subtract(LLeft, LRight), LFourth);
end;

end.
