{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveCatmullRomSpline, the       }
{  uniform cubic interpolating spline                                          }
{                                                                              }
{  Port of idCurve_CatmullRomSpline (idlib\math\Curve.h) of the Doom 3 GPL     }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.CatmullRomSpline;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Spline, DelphiDoom.MathCore.Float.Curve.Types;

type
  /// <summary>Uniform cubic interpolating spline (idCurve_CatmullRomSpline): goes through all the knots</summary>
  TIdCurveCatmullRomSpline<T> = class(TIdCurveSpline<T>)
  strict private
    function Combine(const AIndex: Integer; const ABasis: TIdCurveBasis4): T;
  protected
    procedure Basis(const AIndex: Integer; const ATime: Single; out ABasis: TIdCurveBasis4);
    procedure BasisFirstDerivative(const AIndex: Integer; const ATime: Single;
      out ABasis: TIdCurveBasis4);
    procedure BasisSecondDerivative(const AIndex: Integer; const ATime: Single;
      out ABasis: TIdCurveBasis4);
  public
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

{ TIdCurveCatmullRomSpline<T> }

function TIdCurveCatmullRomSpline<T>.Combine(const AIndex: Integer;
  const ABasis: TIdCurveBasis4): T;
var
  LJ: Integer;
begin
  Result := Arithmetic.Subtract(FValues[0], FValues[0]);
  for LJ := 0 to 3 do
    Result := Arithmetic.Add(Result, Arithmetic.Multiply(ValueForIndex(AIndex + LJ - 2),
      ABasis[LJ]));
end;

function TIdCurveCatmullRomSpline<T>.GetCurrentValue(const ATime: Single): T;
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

function TIdCurveCatmullRomSpline<T>.GetCurrentFirstDerivative(const ATime: Single): T;
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

function TIdCurveCatmullRomSpline<T>.GetCurrentSecondDerivative(const ATime: Single): T;
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

procedure TIdCurveCatmullRomSpline<T>.Basis(const AIndex: Integer; const ATime: Single;
  out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := ((-LS + 2.0) * LS - 1.0) * LS * 0.5;
  ABasis[1] := (((3.0 * LS - 5.0) * LS) * LS + 2.0) * 0.5;
  ABasis[2] := ((-3.0 * LS + 4.0) * LS + 1.0) * LS * 0.5;
  ABasis[3] := ((LS - 1.0) * LS * LS) * 0.5;
end;

procedure TIdCurveCatmullRomSpline<T>.BasisFirstDerivative(const AIndex: Integer;
  const ATime: Single; out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
  LFactor: Double;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := (-1.5 * LS + 2.0) * LS - 0.5;
  ABasis[1] := (4.5 * LS - 5.0) * LS;
  // the original has -4.5 as a double here: the sum is computed in double
  LFactor := -4.5 * LS + 4.0;
  ABasis[2] := LFactor * LS + 0.5;
  ABasis[3] := 1.5 * LS * LS - LS;
end;

procedure TIdCurveCatmullRomSpline<T>.BasisSecondDerivative(const AIndex: Integer;
  const ATime: Single; out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := -3.0 * LS + 2.0;
  ABasis[1] := 9.0 * LS - 5.0;
  ABasis[2] := -9.0 * LS + 4.0;
  ABasis[3] := 3.0 * LS - 1.0;
end;

end.
