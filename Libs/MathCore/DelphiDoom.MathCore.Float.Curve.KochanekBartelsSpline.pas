{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveKochanekBartelsSpline, the  }
{  cubic spline with tension, continuity and bias                              }
{                                                                              }
{  Port of idCurve_KochanekBartelsSpline (idlib\math\Curve.h) of the Doom 3    }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.KochanekBartelsSpline;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.MathCore.Float.Curve.Spline,
  DelphiDoom.MathCore.Float.Curve.Intf, DelphiDoom.MathCore.Float.Curve.Types;

type
  /// <summary>
  ///   Cubic interpolating spline with tension, continuity and bias per knot
  ///   (idCurve_KochanekBartelsSpline): the Catmull-Rom spline if all three are zero. Like the
  ///   original, it can only be evaluated for times after the first knot up to the last one: for
  ///   other times the original reads outside its lists, here EArgumentOutOfRangeException is
  ///   raised. Unlike the other splines, adding or removing a knot does not mark the curve as
  ///   changed (the original does not).
  /// </summary>
  TIdCurveKochanekBartelsSpline<T> = class(TIdCurveSpline<T>)
  strict private
    FTension: TList<Single>;
    FContinuity: TList<Single>;
    FBias: TList<Single>;
    function Combine(const AIndex: Integer; const ABasis: TIdCurveBasis4): T;
  protected
    procedure TangentsForIndex(const AIndex: Integer; out ATangent0, ATangent1: T);
    procedure Basis(const AIndex: Integer; const ATime: Single; out ABasis: TIdCurveBasis4);
    procedure BasisFirstDerivative(const AIndex: Integer; const ATime: Single;
      out ABasis: TIdCurveBasis4);
    procedure BasisSecondDerivative(const AIndex: Integer; const ATime: Single;
      out ABasis: TIdCurveBasis4);
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    destructor Destroy; override;
    /// <summary>Adds a knot with zero tension, continuity and bias</summary>
    function AddValue(const ATime: Single; const AValue: T): Integer; overload; override;
    function AddValue(const ATime: Single; const AValue: T; const ATension, AContinuity,
      ABias: Single): Integer; reintroduce; overload;
    procedure RemoveIndex(const AIndex: Integer); override;
    procedure Clear; override;
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

{ TIdCurveKochanekBartelsSpline<T> }

constructor TIdCurveKochanekBartelsSpline<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create(AArithmetic);
  FTension := TList<Single>.Create;
  FContinuity := TList<Single>.Create;
  FBias := TList<Single>.Create;
end;

destructor TIdCurveKochanekBartelsSpline<T>.Destroy;
begin
  FBias.Free;
  FContinuity.Free;
  FTension.Free;
  inherited Destroy;
end;

function TIdCurveKochanekBartelsSpline<T>.AddValue(const ATime: Single; const AValue: T): Integer;
begin
  Result := IndexForTime(ATime);
  FTimes.Insert(Result, ATime);
  FValues.Insert(Result, AValue);
  FTension.Insert(Result, 0.0);
  FContinuity.Insert(Result, 0.0);
  FBias.Insert(Result, 0.0);
end;

function TIdCurveKochanekBartelsSpline<T>.AddValue(const ATime: Single; const AValue: T;
  const ATension, AContinuity, ABias: Single): Integer;
begin
  Result := IndexForTime(ATime);
  FTimes.Insert(Result, ATime);
  FValues.Insert(Result, AValue);
  FTension.Insert(Result, ATension);
  FContinuity.Insert(Result, AContinuity);
  FBias.Insert(Result, ABias);
end;

procedure TIdCurveKochanekBartelsSpline<T>.RemoveIndex(const AIndex: Integer);
begin
  FValues.Delete(AIndex);
  FTimes.Delete(AIndex);
  FTension.Delete(AIndex);
  FContinuity.Delete(AIndex);
  FBias.Delete(AIndex);
end;

procedure TIdCurveKochanekBartelsSpline<T>.Clear;
begin
  FValues.Clear;
  FTimes.Clear;
  FTension.Clear;
  FContinuity.Clear;
  FBias.Clear;
  FCurrentIndex := -1;
end;

function TIdCurveKochanekBartelsSpline<T>.Combine(const AIndex: Integer;
  const ABasis: TIdCurveBasis4): T;
var
  LTangent0, LTangent1: T;
begin
  TangentsForIndex(AIndex - 1, LTangent0, LTangent1);
  Result := Arithmetic.Multiply(ValueForIndex(AIndex - 1), ABasis[0]);
  Result := Arithmetic.Add(Result, Arithmetic.Multiply(ValueForIndex(AIndex), ABasis[1]));
  Result := Arithmetic.Add(Result, Arithmetic.Multiply(LTangent0, ABasis[2]));
  Result := Arithmetic.Add(Result, Arithmetic.Multiply(LTangent1, ABasis[3]));
end;

function TIdCurveKochanekBartelsSpline<T>.GetCurrentValue(const ATime: Single): T;
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

function TIdCurveKochanekBartelsSpline<T>.GetCurrentFirstDerivative(const ATime: Single): T;
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

function TIdCurveKochanekBartelsSpline<T>.GetCurrentSecondDerivative(const ATime: Single): T;
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

procedure TIdCurveKochanekBartelsSpline<T>.TangentsForIndex(const AIndex: Integer;
  out ATangent0, ATangent1: T);
var
  LDelta: T;
  LDt, LOmt, LOmc, LOpc, LOmb, LOpb, LAdj, LS0, LS1, LDuration: Single;
begin
  LDelta := Arithmetic.Subtract(ValueForIndex(AIndex + 1), ValueForIndex(AIndex));
  LDt := TimeForIndex(AIndex + 1) - TimeForIndex(AIndex);

  LOmt := 1.0 - FTension[AIndex];
  LOmc := 1.0 - FContinuity[AIndex];
  LOpc := 1.0 + FContinuity[AIndex];
  LOmb := 1.0 - FBias[AIndex];
  LOpb := 1.0 + FBias[AIndex];
  LDuration := TimeForIndex(AIndex + 1) - TimeForIndex(AIndex - 1);
  LAdj := 2.0 * LDt / LDuration;
  LS0 := 0.5 * LAdj * LOmt * LOpc * LOpb;
  LS1 := 0.5 * LAdj * LOmt * LOmc * LOmb;

  // outgoing tangent at first point
  ATangent0 := Arithmetic.Add(Arithmetic.Multiply(LDelta, LS1), Arithmetic.Multiply(
    Arithmetic.Subtract(ValueForIndex(AIndex), ValueForIndex(AIndex - 1)), LS0));

  LOmt := 1.0 - FTension[AIndex + 1];
  LOmc := 1.0 - FContinuity[AIndex + 1];
  LOpc := 1.0 + FContinuity[AIndex + 1];
  LOmb := 1.0 - FBias[AIndex + 1];
  LOpb := 1.0 + FBias[AIndex + 1];
  LDuration := TimeForIndex(AIndex + 2) - TimeForIndex(AIndex);
  LAdj := 2.0 * LDt / LDuration;
  LS0 := 0.5 * LAdj * LOmt * LOmc * LOpb;
  LS1 := 0.5 * LAdj * LOmt * LOpc * LOmb;

  // incoming tangent at second point
  ATangent1 := Arithmetic.Add(Arithmetic.Multiply(Arithmetic.Subtract(
    ValueForIndex(AIndex + 2), ValueForIndex(AIndex + 1)), LS1), Arithmetic.Multiply(LDelta, LS0));
end;

procedure TIdCurveKochanekBartelsSpline<T>.Basis(const AIndex: Integer; const ATime: Single;
  out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := ((2.0 * LS - 3.0) * LS) * LS + 1.0;
  ABasis[1] := ((-2.0 * LS + 3.0) * LS) * LS;
  ABasis[2] := ((LS - 2.0) * LS) * LS + LS;
  ABasis[3] := ((LS - 1.0) * LS) * LS;
end;

procedure TIdCurveKochanekBartelsSpline<T>.BasisFirstDerivative(const AIndex: Integer;
  const ATime: Single; out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := (6.0 * LS - 6.0) * LS;
  ABasis[1] := (-6.0 * LS + 6.0) * LS;
  ABasis[2] := (3.0 * LS - 4.0) * LS + 1.0;
  ABasis[3] := (3.0 * LS - 2.0) * LS;
end;

procedure TIdCurveKochanekBartelsSpline<T>.BasisSecondDerivative(const AIndex: Integer;
  const ATime: Single; out ABasis: TIdCurveBasis4);
var
  LS, LValue: Single;
begin
  LValue := ATime - TimeForIndex(AIndex);
  LS := LValue / (TimeForIndex(AIndex + 1) - TimeForIndex(AIndex));
  ABasis[0] := 12.0 * LS - 6.0;
  ABasis[1] := -12.0 * LS + 6.0;
  ABasis[2] := 6.0 * LS - 4.0;
  ABasis[3] := 6.0 * LS - 2.0;
end;

end.
