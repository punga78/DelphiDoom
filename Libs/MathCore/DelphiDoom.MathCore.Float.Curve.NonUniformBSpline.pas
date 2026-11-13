{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveNonUniformBSpline, the      }
{  non-uniform non-rational B-spline                                           }
{                                                                              }
{  Port of idCurve_NonUniformBSpline (idlib\math\Curve.h) of the Doom 3 GPL    }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.NonUniformBSpline;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.BSpline;

type
  /// <summary>
  ///   Non-uniform non-rational B-spline, NUBS (idCurve_NonUniformBSpline), of any order from 1
  ///   to 9 (4 by default). The basis arrays have two spare elements here, because the
  ///   derivative functions of the original work on an offset of the array.
  /// </summary>
  TIdCurveNonUniformBSpline<T> = class(TIdCurveBSpline<T>)
  strict private
    function Combine(const ADerivative: Integer; const ATime: Single): T;
  protected
    /// <summary>Basis functions of the given order, written from index <c>AOffset</c></summary>
    procedure Basis(const AIndex, AOrder: Integer; const ATime: Single; var ABasis: TArray<Single>;
      const AOffset: Integer); overload;
    procedure BasisFirstDerivative(const AIndex, AOrder: Integer; const ATime: Single;
      var ABasis: TArray<Single>; const AOffset: Integer); overload;
    procedure BasisSecondDerivative(const AIndex, AOrder: Integer; const ATime: Single;
      var ABasis: TArray<Single>; const AOffset: Integer); overload;
  public
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

{ TIdCurveNonUniformBSpline<T> }

/// ADerivative: 0 value, 1 first derivative, 2 second derivative
function TIdCurveNonUniformBSpline<T>.Combine(const ADerivative: Integer;
  const ATime: Single): T;
var
  LIndex, LJ, LK: Integer;
  LBasis: TArray<Single>;
  LClampedTime: Single;
begin
  SetLength(LBasis, FOrder + 2);
  if FTimes.Count = 1 then
  begin
    if ADerivative = 0 then
      Result := FValues[0]
    else
      Result := Arithmetic.Subtract(FValues[0], FValues[0]);
    Exit;
  end;
  LClampedTime := ClampedTime(ATime);
  LIndex := IndexForTime(LClampedTime);
  case ADerivative of
    0: Basis(LIndex - 1, FOrder, LClampedTime, LBasis, 0);
    1: BasisFirstDerivative(LIndex - 1, FOrder, LClampedTime, LBasis, 0);
  else
    BasisSecondDerivative(LIndex - 1, FOrder, LClampedTime, LBasis, 0);
  end;
  Result := Arithmetic.Subtract(FValues[0], FValues[0]);
  for LJ := 0 to FOrder - 1 do
  begin
    LK := LIndex + LJ - (FOrder shr 1);
    Result := Arithmetic.Add(Result, Arithmetic.Multiply(ValueForIndex(LK), LBasis[LJ]));
  end;
end;

function TIdCurveNonUniformBSpline<T>.GetCurrentValue(const ATime: Single): T;
begin
  Result := Combine(0, ATime);
end;

function TIdCurveNonUniformBSpline<T>.GetCurrentFirstDerivative(const ATime: Single): T;
begin
  Result := Combine(1, ATime);
end;

function TIdCurveNonUniformBSpline<T>.GetCurrentSecondDerivative(const ATime: Single): T;
begin
  Result := Combine(2, ATime);
end;

procedure TIdCurveNonUniformBSpline<T>.Basis(const AIndex, AOrder: Integer; const ATime: Single;
  var ABasis: TArray<Single>; const AOffset: Integer);
var
  LR, LS, LI: Integer;
  LOmega, LValue, LOneMinus: Single;
begin
  ABasis[AOffset + AOrder - 1] := 1.0;
  for LR := 2 to AOrder do
  begin
    LI := AIndex - LR + 1;
    ABasis[AOffset + AOrder - LR] := 0.0;
    for LS := AOrder - LR + 1 to AOrder - 1 do
    begin
      Inc(LI);
      LValue := ATime - TimeForIndex(LI);
      LOmega := LValue / (TimeForIndex(LI + LR - 1) - TimeForIndex(LI));
      LOneMinus := 1.0 - LOmega;
      ABasis[AOffset + LS - 1] := ABasis[AOffset + LS - 1] + LOneMinus * ABasis[AOffset + LS];
      ABasis[AOffset + LS] := ABasis[AOffset + LS] * LOmega;
    end;
  end;
end;

procedure TIdCurveNonUniformBSpline<T>.BasisFirstDerivative(const AIndex, AOrder: Integer;
  const ATime: Single; var ABasis: TArray<Single>; const AOffset: Integer);
var
  LIndex: Integer;
  LFactor: Single;
begin
  Basis(AIndex, AOrder - 1, ATime, ABasis, AOffset + 1);
  ABasis[AOffset] := 0.0;
  for LIndex := 0 to AOrder - 2 do
  begin
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] - ABasis[AOffset + LIndex + 1];
    LFactor := Single(AOrder - 1) / (TimeForIndex(AIndex + LIndex + (AOrder - 1) - 2) -
      TimeForIndex(AIndex + LIndex - 2));
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] * LFactor;
  end;
  // the loop variable of the original is AOrder - 1 here
  LIndex := AOrder - 1;
  LFactor := Single(AOrder - 1) / (TimeForIndex(AIndex + LIndex + (AOrder - 1) - 2) -
    TimeForIndex(AIndex + LIndex - 2));
  ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] * LFactor;
end;

procedure TIdCurveNonUniformBSpline<T>.BasisSecondDerivative(const AIndex, AOrder: Integer;
  const ATime: Single; var ABasis: TArray<Single>; const AOffset: Integer);
var
  LIndex: Integer;
  LFactor: Single;
begin
  BasisFirstDerivative(AIndex, AOrder - 1, ATime, ABasis, AOffset + 1);
  ABasis[AOffset] := 0.0;
  for LIndex := 0 to AOrder - 2 do
  begin
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] - ABasis[AOffset + LIndex + 1];
    LFactor := Single(AOrder - 1) / (TimeForIndex(AIndex + LIndex + (AOrder - 1) - 2) -
      TimeForIndex(AIndex + LIndex - 2));
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] * LFactor;
  end;
  LIndex := AOrder - 1;
  LFactor := Single(AOrder - 1) / (TimeForIndex(AIndex + LIndex + (AOrder - 1) - 2) -
    TimeForIndex(AIndex + LIndex - 2));
  ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] * LFactor;
end;

end.
