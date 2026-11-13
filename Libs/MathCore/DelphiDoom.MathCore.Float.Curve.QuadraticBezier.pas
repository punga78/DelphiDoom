{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveQuadraticBezier, a Bezier   }
{  curve with three knots                                                      }
{                                                                              }
{  Port of idCurve_QuadraticBezier (idlib\math\Curve.h) of the Doom 3 GPL      }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.QuadraticBezier;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve;

type
  /// <summary>
  ///   Quadratic Bezier curve (idCurve_QuadraticBezier). It must have exactly three knots; the
  ///   original only asserts it, here the evaluation raises EIdCurveException otherwise.
  /// </summary>
  TIdCurveQuadraticBezier<T> = class(TIdCurve<T>)
  strict private
    procedure CheckKnots;
    function Combine(const ABasis: array of Single): T;
  protected
    procedure Basis(const ATime: Single; out ABasis: array of Single);
    procedure BasisFirstDerivative(const ATime: Single; out ABasis: array of Single);
    procedure BasisSecondDerivative(const ATime: Single; out ABasis: array of Single);
  public
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Float.Curve.Types;

{ TIdCurveQuadraticBezier<T> }

procedure TIdCurveQuadraticBezier<T>.CheckKnots;
begin
  if FValues.Count <> 3 then
    raise EIdCurveException.CreateFmt(SIdCurveKnotCount, [3, FValues.Count]);
end;

function TIdCurveQuadraticBezier<T>.Combine(const ABasis: array of Single): T;
begin
  Result := Arithmetic.Add(Arithmetic.Add(Arithmetic.Multiply(FValues[0], ABasis[0]),
    Arithmetic.Multiply(FValues[1], ABasis[1])), Arithmetic.Multiply(FValues[2], ABasis[2]));
end;

function TIdCurveQuadraticBezier<T>.GetCurrentValue(const ATime: Single): T;
var
  LBasis: array[0..2] of Single;
begin
  CheckKnots;
  Basis(ATime, LBasis);
  Result := Combine(LBasis);
end;

function TIdCurveQuadraticBezier<T>.GetCurrentFirstDerivative(const ATime: Single): T;
var
  LBasis: array[0..2] of Single;
  LDuration: Single;
begin
  CheckKnots;
  BasisFirstDerivative(ATime, LBasis);
  LDuration := FTimes[2] - FTimes[0];
  Result := Arithmetic.Divide(Combine(LBasis), LDuration);
end;

function TIdCurveQuadraticBezier<T>.GetCurrentSecondDerivative(const ATime: Single): T;
var
  LBasis: array[0..2] of Single;
  LDuration, LSquare: Single;
begin
  CheckKnots;
  BasisSecondDerivative(ATime, LBasis);
  LDuration := FTimes[2] - FTimes[0];
  LSquare := LDuration * LDuration;
  Result := Arithmetic.Divide(Combine(LBasis), LSquare);
end;

procedure TIdCurveQuadraticBezier<T>.Basis(const ATime: Single; out ABasis: array of Single);
var
  LS1, LS2, LValue: Single;
begin
  LValue := ATime - FTimes[0];
  LS1 := LValue / (FTimes[2] - FTimes[0]);
  LS2 := LS1 * LS1;
  ABasis[0] := LS2 - 2.0 * LS1 + 1.0;
  ABasis[1] := -2.0 * LS2 + 2.0 * LS1;
  ABasis[2] := LS2;
end;

procedure TIdCurveQuadraticBezier<T>.BasisFirstDerivative(const ATime: Single;
  out ABasis: array of Single);
var
  LS1, LValue: Single;
begin
  LValue := ATime - FTimes[0];
  LS1 := LValue / (FTimes[2] - FTimes[0]);
  ABasis[0] := 2.0 * LS1 - 2.0;
  ABasis[1] := -4.0 * LS1 + 2.0;
  ABasis[2] := 2.0 * LS1;
end;

procedure TIdCurveQuadraticBezier<T>.BasisSecondDerivative(const ATime: Single;
  out ABasis: array of Single);
begin
  ABasis[0] := 2.0;
  ABasis[1] := -4.0;
  ABasis[2] := 2.0;
end;

end.
