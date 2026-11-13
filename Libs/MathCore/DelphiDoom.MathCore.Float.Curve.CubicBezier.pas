{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveCubicBezier, a Bezier       }
{  curve with four knots                                                       }
{                                                                              }
{  Port of idCurve_CubicBezier (idlib\math\Curve.h) of the Doom 3 GPL Source   }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.CubicBezier;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve;

type
  /// <summary>
  ///   Cubic Bezier curve (idCurve_CubicBezier). It must have exactly four knots; the original
  ///   only asserts it, here the evaluation raises EIdCurveException otherwise.
  /// </summary>
  TIdCurveCubicBezier<T> = class(TIdCurve<T>)
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

{ TIdCurveCubicBezier<T> }

procedure TIdCurveCubicBezier<T>.CheckKnots;
begin
  if FValues.Count <> 4 then
    raise EIdCurveException.CreateFmt(SIdCurveKnotCount, [4, FValues.Count]);
end;

function TIdCurveCubicBezier<T>.Combine(const ABasis: array of Single): T;
begin
  Result := Arithmetic.Add(Arithmetic.Add(Arithmetic.Add(
    Arithmetic.Multiply(FValues[0], ABasis[0]), Arithmetic.Multiply(FValues[1], ABasis[1])),
    Arithmetic.Multiply(FValues[2], ABasis[2])), Arithmetic.Multiply(FValues[3], ABasis[3]));
end;

function TIdCurveCubicBezier<T>.GetCurrentValue(const ATime: Single): T;
var
  LBasis: array[0..3] of Single;
begin
  CheckKnots;
  Basis(ATime, LBasis);
  Result := Combine(LBasis);
end;

function TIdCurveCubicBezier<T>.GetCurrentFirstDerivative(const ATime: Single): T;
var
  LBasis: array[0..3] of Single;
  LDuration: Single;
begin
  CheckKnots;
  BasisFirstDerivative(ATime, LBasis);
  LDuration := FTimes[3] - FTimes[0];
  Result := Arithmetic.Divide(Combine(LBasis), LDuration);
end;

function TIdCurveCubicBezier<T>.GetCurrentSecondDerivative(const ATime: Single): T;
var
  LBasis: array[0..3] of Single;
  LDuration, LSquare: Single;
begin
  CheckKnots;
  BasisSecondDerivative(ATime, LBasis);
  LDuration := FTimes[3] - FTimes[0];
  LSquare := LDuration * LDuration;
  Result := Arithmetic.Divide(Combine(LBasis), LSquare);
end;

procedure TIdCurveCubicBezier<T>.Basis(const ATime: Single; out ABasis: array of Single);
var
  LS1, LS2, LS3, LValue: Single;
begin
  LValue := ATime - FTimes[0];
  LS1 := LValue / (FTimes[3] - FTimes[0]);
  LS2 := LS1 * LS1;
  LS3 := LS2 * LS1;
  ABasis[0] := -LS3 + 3.0 * LS2 - 3.0 * LS1 + 1.0;
  ABasis[1] := 3.0 * LS3 - 6.0 * LS2 + 3.0 * LS1;
  ABasis[2] := -3.0 * LS3 + 3.0 * LS2;
  ABasis[3] := LS3;
end;

procedure TIdCurveCubicBezier<T>.BasisFirstDerivative(const ATime: Single;
  out ABasis: array of Single);
var
  LS1, LS2, LValue: Single;
begin
  LValue := ATime - FTimes[0];
  LS1 := LValue / (FTimes[3] - FTimes[0]);
  LS2 := LS1 * LS1;
  ABasis[0] := -3.0 * LS2 + 6.0 * LS1 - 3.0;
  ABasis[1] := 9.0 * LS2 - 12.0 * LS1 + 3.0;
  ABasis[2] := -9.0 * LS2 + 6.0 * LS1;
  ABasis[3] := 3.0 * LS2;
end;

procedure TIdCurveCubicBezier<T>.BasisSecondDerivative(const ATime: Single;
  out ABasis: array of Single);
var
  LS1, LValue: Single;
begin
  LValue := ATime - FTimes[0];
  LS1 := LValue / (FTimes[3] - FTimes[0]);
  ABasis[0] := -6.0 * LS1 + 6.0;
  ABasis[1] := 18.0 * LS1 - 12.0;
  ABasis[2] := -18.0 * LS1 + 6.0;
  ABasis[3] := 6.0 * LS1;
end;

end.
