{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveSpline, the base of the     }
{  splines                                                                     }
{                                                                              }
{  Port of idCurve_Spline (idlib\math\Curve.h) of the Doom 3 GPL Source Code.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Spline;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve, DelphiDoom.MathCore.Float.Curve.Intf,
  DelphiDoom.MathCore.Float.Curve.Types;

type
  /// <summary>
  ///   Spline base (idCurve_Spline): adds the boundary type (free, clamped or closed) to the
  ///   curve, with the knot extrapolation and the time clamping that go with it. A closed curve
  ///   repeats its knots; <c>CloseTime</c> is the time added after the last knot to close it.
  /// </summary>
  TIdCurveSpline<T> = class(TIdCurve<T>)
  strict private
    FBoundaryType: TIdCurveBoundary;
    FCloseTime: Single;
    function GetCloseTime: Single;
  protected
    /// <summary>The value of a knot; outside the list it is extrapolated or, if closed, repeated</summary>
    function ValueForIndex(const AIndex: Integer): T; reintroduce;
    function TimeForIndex(const AIndex: Integer): Single; reintroduce;
    /// <summary>The time clamped to the first and last knot if the boundary is clamped</summary>
    function ClampedTime(const ATime: Single): Single;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    function IsDone(const ATime: Single): Boolean; override;
    procedure SetBoundaryType(const ABoundaryType: TIdCurveBoundary); virtual;
    function GetBoundaryType: TIdCurveBoundary; virtual;
    procedure SetCloseTime(const ATime: Single); virtual;
    property BoundaryType: TIdCurveBoundary read GetBoundaryType write SetBoundaryType;
    /// <summary>The closing time if the curve is closed, zero otherwise (as in the original)</summary>
    property CloseTime: Single read GetCloseTime write SetCloseTime;
  end;

implementation

{ TIdCurveSpline<T> }

constructor TIdCurveSpline<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create(AArithmetic);
  FBoundaryType := TIdCurveBoundary.Free;
  FCloseTime := 0.0;
end;

procedure TIdCurveSpline<T>.SetBoundaryType(const ABoundaryType: TIdCurveBoundary);
begin
  FBoundaryType := ABoundaryType;
  FChanged := True;
end;

function TIdCurveSpline<T>.GetBoundaryType: TIdCurveBoundary;
begin
  Result := FBoundaryType;
end;

procedure TIdCurveSpline<T>.SetCloseTime(const ATime: Single);
begin
  FCloseTime := ATime;
  FChanged := True;
end;

function TIdCurveSpline<T>.GetCloseTime: Single;
begin
  if FBoundaryType = TIdCurveBoundary.Closed then
    Result := FCloseTime
  else
    Result := 0.0;
end;

function TIdCurveSpline<T>.ValueForIndex(const AIndex: Integer): T;
var
  LLast: Integer;
begin
  LLast := FValues.Count - 1;
  if AIndex < 0 then
  begin
    if FBoundaryType = TIdCurveBoundary.Closed then
      Result := FValues[FValues.Count + AIndex mod FValues.Count]
    else
      Result := Arithmetic.Add(FValues[0], Arithmetic.Multiply(
        Arithmetic.Subtract(FValues[1], FValues[0]), AIndex));
  end
  else if AIndex > LLast then
  begin
    if FBoundaryType = TIdCurveBoundary.Closed then
      Result := FValues[AIndex mod FValues.Count]
    else
      Result := Arithmetic.Add(FValues[LLast], Arithmetic.Multiply(
        Arithmetic.Subtract(FValues[LLast], FValues[LLast - 1]), AIndex - LLast));
  end
  else
    Result := FValues[AIndex];
end;

function TIdCurveSpline<T>.TimeForIndex(const AIndex: Integer): Single;
var
  LLast: Integer;
  LPeriod, LWhole: Single;
begin
  LLast := FTimes.Count - 1;
  if AIndex < 0 then
  begin
    if FBoundaryType = TIdCurveBoundary.Closed then
    begin
      LPeriod := FTimes[LLast] + FCloseTime;
      LWhole := (AIndex div FTimes.Count) * LPeriod;
      Result := LWhole - (LPeriod - FTimes[FTimes.Count + AIndex mod FTimes.Count]);
    end
    else
      Result := FTimes[0] + AIndex * (FTimes[1] - FTimes[0]);
  end
  else if AIndex > LLast then
  begin
    if FBoundaryType = TIdCurveBoundary.Closed then
    begin
      LPeriod := FTimes[LLast] + FCloseTime;
      LWhole := (AIndex div FTimes.Count) * LPeriod;
      Result := LWhole + FTimes[AIndex mod FTimes.Count];
    end
    else
      Result := FTimes[LLast] + (AIndex - LLast) * (FTimes[LLast] - FTimes[LLast - 1]);
  end
  else
    Result := FTimes[AIndex];
end;

function TIdCurveSpline<T>.ClampedTime(const ATime: Single): Single;
begin
  Result := ATime;
  if FBoundaryType = TIdCurveBoundary.Clamped then
  begin
    if ATime < FTimes[0] then
      Result := FTimes[0]
    else if ATime >= FTimes[FTimes.Count - 1] then
      Result := FTimes[FTimes.Count - 1];
  end;
end;

function TIdCurveSpline<T>.IsDone(const ATime: Single): Boolean;
begin
  Result := (FBoundaryType <> TIdCurveBoundary.Closed) and (ATime >= FTimes[FTimes.Count - 1]);
end;

end.
