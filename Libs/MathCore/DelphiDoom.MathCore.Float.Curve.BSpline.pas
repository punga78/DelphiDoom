{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveBSpline, the recursive      }
{  B-spline                                                                    }
{                                                                              }
{  Port of idCurve_BSpline (idlib\math\Curve.h) of the Doom 3 GPL Source       }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.BSpline;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Spline, DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   B-spline base (idCurve_BSpline), defined recursively and slow: use
  ///   TIdCurveUniformCubicBSpline or TIdCurveNonUniformBSpline instead. The order is 4 (cubic)
  ///   by default and can be 1 to 9. Like the original, the first and second derivative of a
  ///   curve with a single knot return the knot value (not zero).
  /// </summary>
  TIdCurveBSpline<T> = class(TIdCurveSpline<T>)
  strict private
    function Combine(const ADerivative: Integer; const ATime: Single): T;
  protected
    FOrder: Integer;
    function Basis(const AIndex, AOrder: Integer; const ATime: Single): Single; overload;
    function BasisFirstDerivative(const AIndex, AOrder: Integer; const ATime: Single): Single;
      overload;
    function BasisSecondDerivative(const AIndex, AOrder: Integer; const ATime: Single): Single;
      overload;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    function GetOrder: Integer; virtual;
    procedure SetOrder(const AOrder: Integer); virtual;
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
    property Order: Integer read GetOrder write SetOrder;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Float.Curve.Types;

{ TIdCurveBSpline<T> }

constructor TIdCurveBSpline<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create(AArithmetic);
  FOrder := 4; // default to cubic
end;

function TIdCurveBSpline<T>.GetOrder: Integer;
begin
  Result := FOrder;
end;

procedure TIdCurveBSpline<T>.SetOrder(const AOrder: Integer);
begin
  if (AOrder <= 0) or (AOrder >= 10) then
    raise EIdCurveException.CreateFmt(SIdCurveOrderRange, [AOrder]);
  FOrder := AOrder;
end;

/// ADerivative: 0 value, 1 first derivative, 2 second derivative
function TIdCurveBSpline<T>.Combine(const ADerivative: Integer; const ATime: Single): T;
var
  LIndex, LJ, LK: Integer;
  LClampedTime, LWeight: Single;
begin
  if FTimes.Count = 1 then
  begin
    Result := FValues[0];
    Exit;
  end;
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  Result := Arithmetic.Subtract(FValues[0], FValues[0]);
  for LJ := 0 to FOrder - 1 do
  begin
    LK := LIndex + LJ - (FOrder shr 1);
    case ADerivative of
      0: LWeight := Basis(LK - 2, FOrder, LClampedTime);
      1: LWeight := BasisFirstDerivative(LK - 2, FOrder, LClampedTime);
    else
      LWeight := BasisSecondDerivative(LK - 2, FOrder, LClampedTime);
    end;
    Result := Arithmetic.Add(Result, Arithmetic.Multiply(ValueForIndex(LK), LWeight));
  end;
end;

function TIdCurveBSpline<T>.GetCurrentValue(const ATime: Single): T;
begin
  Result := Combine(0, ATime);
end;

function TIdCurveBSpline<T>.GetCurrentFirstDerivative(const ATime: Single): T;
begin
  Result := Combine(1, ATime);
end;

function TIdCurveBSpline<T>.GetCurrentSecondDerivative(const ATime: Single): T;
begin
  Result := Combine(2, ATime);
end;

function TIdCurveBSpline<T>.Basis(const AIndex, AOrder: Integer; const ATime: Single): Single;
var
  LD1, LD2, LNumerator, LTerm: Single;
begin
  if AOrder <= 1 then
  begin
    if (TimeForIndex(AIndex) < ATime) and (ATime <= TimeForIndex(AIndex + 1)) then
      Result := 1.0
    else
      Result := 0.0;
  end
  else
  begin
    Result := 0.0;
    LD1 := TimeForIndex(AIndex + AOrder - 1) - TimeForIndex(AIndex);
    if LD1 <> 0.0 then
    begin
      LNumerator := ATime - TimeForIndex(AIndex);
      LTerm := LNumerator * Basis(AIndex, AOrder - 1, ATime);
      Result := Result + LTerm / LD1;
    end;

    LD2 := TimeForIndex(AIndex + AOrder) - TimeForIndex(AIndex + 1);
    if LD2 <> 0.0 then
    begin
      LNumerator := TimeForIndex(AIndex + AOrder) - ATime;
      LTerm := LNumerator * Basis(AIndex + 1, AOrder - 1, ATime);
      Result := Result + LTerm / LD2;
    end;
  end;
end;

function TIdCurveBSpline<T>.BasisFirstDerivative(const AIndex, AOrder: Integer;
  const ATime: Single): Single;
var
  LDifference, LNumerator, LDenominator: Single;
begin
  LDifference := Basis(AIndex, AOrder - 1, ATime) - Basis(AIndex + 1, AOrder - 1, ATime);
  LNumerator := LDifference * Single(AOrder - 1);
  LDenominator := TimeForIndex(AIndex + (AOrder - 1) - 2) - TimeForIndex(AIndex - 2);
  Result := LNumerator / LDenominator;
end;

function TIdCurveBSpline<T>.BasisSecondDerivative(const AIndex, AOrder: Integer;
  const ATime: Single): Single;
var
  LDifference, LNumerator, LDenominator: Single;
begin
  LDifference := BasisFirstDerivative(AIndex, AOrder - 1, ATime) -
    BasisFirstDerivative(AIndex + 1, AOrder - 1, ATime);
  LNumerator := LDifference * Single(AOrder - 1);
  LDenominator := TimeForIndex(AIndex + (AOrder - 1) - 2) - TimeForIndex(AIndex - 2);
  Result := LNumerator / LDenominator;
end;

end.
