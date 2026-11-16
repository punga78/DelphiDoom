{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdInterpolateAccelDecel<T>         }
{                                                                              }
{  Port of the common part of idInterpolateAccelDecelLinear and                }
{  idInterpolateAccelDecelSine (idlib\math\Interpolate.h) of the Doom 3 GPL    }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Interpolate.AccelDecel;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Intf, DelphiDoom.MathCore.Float.Extrapolate;

type
  /// <summary>
  ///   Continuous interpolation with an acceleration phase, a linear phase and a deceleration
  ///   phase. The two C++ classes (linear and sinusoidal phases) are the same code with three
  ///   differences, which a descendant gives: the extrapolation type of the acceleration and of
  ///   the deceleration and the factor that turns the duration of a phase into covered distance
  ///   (0.5 for linear, sqrt(0.5) for sinusoidal). Times are in milliseconds.
  /// </summary>
  TIdInterpolateAccelDecel<T> = class abstract
  strict private
    FArithmetic: IIdCurveArithmetic<T>;
    FStartTime: Single;
    FAccelTime: Single;
    FLinearTime: Single;
    FDecelTime: Single;
    FStartValue: T;
    FEndValue: T;
    FExtrapolate: TIdExtrapolate<T>;
    procedure Invalidate;
    procedure SetPhase(const ATime: Single);
  strict protected
    /// <summary>ID_EXTRAPOLATION_ACCELLINEAR or ID_EXTRAPOLATION_ACCELSINE</summary>
    function GetAccelerationType: Integer; virtual; abstract;
    /// <summary>ID_EXTRAPOLATION_DECELLINEAR or ID_EXTRAPOLATION_DECELSINE</summary>
    function GetDecelerationType: Integer; virtual; abstract;
    /// <summary>0.5 for the linear phases, sqrt(0.5) for the sinusoidal ones</summary>
    function GetPhaseFactor: Single; virtual; abstract;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    destructor Destroy; override;
    procedure Init(const AStartTime, AAccelTime, ADecelTime, ADuration: Single; const AStartValue,
      AEndValue: T);
    procedure SetStartTime(const ATime: Single);
    procedure SetStartValue(const AStartValue: T);
    procedure SetEndValue(const AEndValue: T);
    function GetCurrentValue(const ATime: Single): T;
    function GetCurrentSpeed(const ATime: Single): T;
    function IsDone(const ATime: Single): Boolean;
    function GetStartTime: Single;
    function GetEndTime: Single;
    function GetDuration: Single;
    function GetAcceleration: Single;
    function GetDeceleration: Single;
    function GetStartValue: T;
    function GetEndValue: T;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math;

{ TIdInterpolateAccelDecel<T> }

constructor TIdInterpolateAccelDecel<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create;
  if not Assigned(AArithmetic) then
    raise EArgumentNilException.Create('AArithmetic');
  FArithmetic := AArithmetic;
  FExtrapolate := TIdExtrapolate<T>.Create(AArithmetic);
  FStartTime := 0.0;
  FAccelTime := 0.0;
  FLinearTime := 0.0;
  FDecelTime := 0.0;
  FStartValue := Default(T);
  FEndValue := FStartValue;
end;

destructor TIdInterpolateAccelDecel<T>.Destroy;
begin
  FExtrapolate.Free;
  inherited Destroy;
end;

procedure TIdInterpolateAccelDecel<T>.Init(const AStartTime, AAccelTime, ADecelTime,
  ADuration: Single; const AStartValue, AEndValue: T);
var
  LSpeed, LZero: T;
  LFactor: Single;
begin
  FStartTime := AStartTime;
  FAccelTime := AAccelTime;
  FDecelTime := ADecelTime;
  FStartValue := AStartValue;
  FEndValue := AEndValue;
  if ADuration <= 0.0 then
    Exit;
  if FAccelTime + FDecelTime > ADuration then
  begin
    FAccelTime := FAccelTime * ADuration / (FAccelTime + FDecelTime);
    FDecelTime := ADuration - FAccelTime;
  end;
  FLinearTime := ADuration - FAccelTime - FDecelTime;
  LFactor := 1000.0 / (FLinearTime + (FAccelTime + FDecelTime) * GetPhaseFactor);
  LSpeed := FArithmetic.Multiply(FArithmetic.Subtract(AEndValue, AStartValue), LFactor);
  LZero := FArithmetic.Subtract(AStartValue, AStartValue);
  if FAccelTime <> 0.0 then
    FExtrapolate.Init(AStartTime, FAccelTime, AStartValue, LZero, LSpeed, GetAccelerationType)
  else if FLinearTime <> 0.0 then
    FExtrapolate.Init(AStartTime, FLinearTime, AStartValue, LZero, LSpeed, ID_EXTRAPOLATION_LINEAR)
  else
    FExtrapolate.Init(AStartTime, FDecelTime, AStartValue, LZero, LSpeed, GetDecelerationType);
end;

procedure TIdInterpolateAccelDecel<T>.Invalidate;
begin
  FExtrapolate.Init(0.0, 0.0, FExtrapolate.GetStartValue, FExtrapolate.GetBaseSpeed,
    FExtrapolate.GetSpeed, ID_EXTRAPOLATION_NONE);
end;

procedure TIdInterpolateAccelDecel<T>.SetPhase(const ATime: Single);
var
  LDeltaTime, LDistance: Single;
begin
  LDeltaTime := ATime - FStartTime;
  if LDeltaTime < FAccelTime then
  begin
    if FExtrapolate.GetExtrapolationType <> GetAccelerationType then
      FExtrapolate.Init(FStartTime, FAccelTime, FStartValue, FExtrapolate.GetBaseSpeed,
        FExtrapolate.GetSpeed, GetAccelerationType);
  end
  else if LDeltaTime < FAccelTime + FLinearTime then
  begin
    if FExtrapolate.GetExtrapolationType <> ID_EXTRAPOLATION_LINEAR then
    begin
      LDistance := FAccelTime * ID_MS2SEC;
      LDistance := LDistance * GetPhaseFactor;
      FExtrapolate.Init(FStartTime + FAccelTime, FLinearTime,
        FArithmetic.Add(FStartValue, FArithmetic.Multiply(FExtrapolate.GetSpeed, LDistance)),
        FExtrapolate.GetBaseSpeed, FExtrapolate.GetSpeed, ID_EXTRAPOLATION_LINEAR);
    end;
  end
  else
  begin
    if FExtrapolate.GetExtrapolationType <> GetDecelerationType then
    begin
      LDistance := FDecelTime * ID_MS2SEC;
      LDistance := LDistance * GetPhaseFactor;
      FExtrapolate.Init(FStartTime + FAccelTime + FLinearTime, FDecelTime,
        FArithmetic.Subtract(FEndValue, FArithmetic.Multiply(FExtrapolate.GetSpeed, LDistance)),
        FExtrapolate.GetBaseSpeed, FExtrapolate.GetSpeed, GetDecelerationType);
    end;
  end;
end;

procedure TIdInterpolateAccelDecel<T>.SetStartTime(const ATime: Single);
begin
  FStartTime := ATime;
  Invalidate;
end;

procedure TIdInterpolateAccelDecel<T>.SetStartValue(const AStartValue: T);
begin
  FStartValue := AStartValue;
  Invalidate;
end;

procedure TIdInterpolateAccelDecel<T>.SetEndValue(const AEndValue: T);
begin
  FEndValue := AEndValue;
  Invalidate;
end;

function TIdInterpolateAccelDecel<T>.GetCurrentValue(const ATime: Single): T;
begin
  SetPhase(ATime);
  Result := FExtrapolate.GetCurrentValue(ATime);
end;

function TIdInterpolateAccelDecel<T>.GetCurrentSpeed(const ATime: Single): T;
begin
  SetPhase(ATime);
  Result := FExtrapolate.GetCurrentSpeed(ATime);
end;

function TIdInterpolateAccelDecel<T>.IsDone(const ATime: Single): Boolean;
begin
  Result := ATime >= FStartTime + FAccelTime + FLinearTime + FDecelTime;
end;

function TIdInterpolateAccelDecel<T>.GetStartTime: Single;
begin
  Result := FStartTime;
end;

function TIdInterpolateAccelDecel<T>.GetEndTime: Single;
begin
  Result := FStartTime + FAccelTime + FLinearTime + FDecelTime;
end;

function TIdInterpolateAccelDecel<T>.GetDuration: Single;
begin
  Result := FAccelTime + FLinearTime + FDecelTime;
end;

function TIdInterpolateAccelDecel<T>.GetAcceleration: Single;
begin
  Result := FAccelTime;
end;

function TIdInterpolateAccelDecel<T>.GetDeceleration: Single;
begin
  Result := FDecelTime;
end;

function TIdInterpolateAccelDecel<T>.GetStartValue: T;
begin
  Result := FStartValue;
end;

function TIdInterpolateAccelDecel<T>.GetEndValue: T;
begin
  Result := FEndValue;
end;

end.
