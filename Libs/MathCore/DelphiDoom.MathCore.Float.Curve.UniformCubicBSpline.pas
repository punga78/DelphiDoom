{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveUniformCubicBSpline, the    }
{  uniform non-rational cubic B-spline                                         }
{                                                                              }
{  Port of idCurve_UniformCubicBSpline (idlib\math\Curve.h) of the Doom 3 GPL  }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.UniformCubicBSpline;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.BSpline, DelphiDoom.MathCore.Float.Curve.Intf,
  DelphiDoom.MathCore.Float.Curve.Types;

type
  /// <summary>Uniform non-rational cubic B-spline (idCurve_UniformCubicBSpline); the order is always 4</summary>
  TIdCurveUniformCubicBSpline<T> = class(TIdCurveBSpline<T>)
  strict private
    function Combine(const AIndex: Integer; const ABasis: TIdCurveBasis4): T;
  protected
    procedure Basis(const AIndex: Integer; const ATime: Single; out ABasis: TIdCurveBasis4);
      overload;
    procedure BasisFirstDerivative(const AIndex: Integer; const ATime: Single;
      out ABasis: TIdCurveBasis4); overload;
    procedure BasisSecondDerivative(const AIndex: Integer; const ATime: Single;
      out ABasis: TIdCurveBasis4); overload;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

{ TIdCurveUniformCubicBSpline<T> }

constructor TIdCurveUniformCubicBSpline<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create(AArithmetic);
  FOrder := 4; // always cubic
end;

function TIdCurveUniformCubicBSpline<T>.Combine(const AIndex: Integer;
  const ABasis: TIdCurveBasis4): T;
var
  LJ: Integer;
begin
  Result := Arithmetic.Subtract(FValues[0], FValues[0]);
  for LJ := 0 to 3 do
    Result := Arithmetic.Add(Result, Arithmetic.Multiply(ValueForIndex(AIndex + LJ - 2),
      ABasis[LJ]));
end;

function TIdCurveUniformCubicBSpline<T>.GetCurrentValue(const ATime: Single): T;
var
  LIndex: Integer;
  LBasis: TIdCurveBasis4;
  LClampedTime: Single;
begin
  if FTimes.Count = 1 then
  begin
    Result := FValues[0];
    Exit;
  end;
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  Basis(LIndex - 1, LClampedTime, LBasis);
  Result := Combine(LIndex, LBasis);
end;

function TIdCurveUniformCubicBSpline<T>.GetCurrentFirstDerivative(const ATime: Single): T;
var
  LIndex: Integer;
  LBasis: TIdCurveBasis4;
  LClampedTime, LDuration: Single;
begin
  if FTimes.Count = 1 then
  begin
    Result := Arithmetic.Subtract(FValues[0], FValues[0]);
    Exit;
  end;
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  BasisFirstDerivative(LIndex - 1, LClampedTime, LBasis);
  Result := Combine(LIndex, LBasis);
  LDuration := TimeForIndex(LIndex) - TimeForIndex(LIndex - 1);
  Result := Arithmetic.Divide(Result, LDuration);
end;

function TIdCurveUniformCubicBSpline<T>.GetCurrentSecondDerivative(const ATime: Single): T;
var
  LIndex: Integer;
  LBasis: TIdCurveBasis4;
  LClampedTime, LDuration, LSquare: Single;
begin
  if FTimes.Count = 1 then
  begin
    Result := Arithmetic.Subtract(FValues[0], FValues[0]);
    Exit;
  end;
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  BasisSecondDerivative(LIndex - 1, LClampedTime, LBasis);
  Result := Combine(LIndex, LBasis);
  LDuration := TimeForIndex(LIndex) - TimeForIndex(LIndex - 1);
  LSquare := LDuration * LDuration;
  Result := Arithmetic.Divide(Result, LSquare);
end;

procedure TIdCurveUniformCubicBSpline<T>.Basis(const AIndex: Integer; const ATime: Single;
  out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := (((-LS + 3.0) * LS - 3.0) * LS + 1.0) * ID_CURVE_ONE_SIXTH;
  ABasis[1] := (((3.0 * LS - 6.0) * LS) * LS + 4.0) * ID_CURVE_ONE_SIXTH;
  ABasis[2] := (((-3.0 * LS + 3.0) * LS + 3.0) * LS + 1.0) * ID_CURVE_ONE_SIXTH;
  ABasis[3] := (LS * LS * LS) * ID_CURVE_ONE_SIXTH;
end;

procedure TIdCurveUniformCubicBSpline<T>.BasisFirstDerivative(const AIndex: Integer;
  const ATime: Single; out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := -0.5 * LS * LS + LS - 0.5;
  ABasis[1] := 1.5 * LS * LS - 2.0 * LS;
  ABasis[2] := -1.5 * LS * LS + LS + 0.5;
  ABasis[3] := 0.5 * LS * LS;
end;

procedure TIdCurveUniformCubicBSpline<T>.BasisSecondDerivative(const AIndex: Integer;
  const ATime: Single; out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := -LS + 1.0;
  ABasis[1] := 3.0 * LS - 2.0;
  ABasis[2] := -3.0 * LS + 1.0;
  ABasis[3] := LS;
end;

end.
