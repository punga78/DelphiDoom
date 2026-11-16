{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdExtrapolate<T>                   }
{                                                                              }
{  Port of idExtrapolate (idlib\math\Extrapolate.h) of the Doom 3 GPL Source   }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Extrapolate;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Intf;

const
  /// <summary>No extrapolation: covered distance = duration * 0.001 * baseSpeed</summary>
  ID_EXTRAPOLATION_NONE = $01;
  /// <summary>Linear extrapolation: duration * 0.001 * (baseSpeed + speed)</summary>
  ID_EXTRAPOLATION_LINEAR = $02;
  /// <summary>Linear acceleration: duration * 0.001 * (baseSpeed + 0.5 * speed)</summary>
  ID_EXTRAPOLATION_ACCELLINEAR = $04;
  /// <summary>Linear deceleration: duration * 0.001 * (baseSpeed + 0.5 * speed)</summary>
  ID_EXTRAPOLATION_DECELLINEAR = $08;
  /// <summary>Sinusoidal acceleration: duration * 0.001 * (baseSpeed + sqrt(0.5) * speed)</summary>
  ID_EXTRAPOLATION_ACCELSINE = $10;
  /// <summary>Sinusoidal deceleration: duration * 0.001 * (baseSpeed + sqrt(0.5) * speed)</summary>
  ID_EXTRAPOLATION_DECELSINE = $20;
  /// <summary>Flag: do not stop at startTime + duration</summary>
  ID_EXTRAPOLATION_NOSTOP = $40;

type
  /// <summary>
  ///   The extrapolation of a value of any type with a speed (idExtrapolate&lt;type&gt;): the
  ///   arithmetic of the value type is the strategy of the curves, <c>IIdCurveArithmetic</c>
  ///   (only <c>Add</c>, <c>Subtract</c> and <c>Multiply</c> are used). Times are in milliseconds. As
  ///   in the C++ the last result is cached by time: asking for a time before the start returns
  ///   the start value but still records that time, so a second call with the same time returns
  ///   the value cached before (conserved).
  /// </summary>
  TIdExtrapolate<T> = class
  strict private
    FArithmetic: IIdCurveArithmetic<T>;
    FExtrapolationType: Integer;
    FStartTime: Single;
    FDuration: Single;
    FStartValue: T;
    FBaseSpeed: T;
    FSpeed: T;
    FCurrentTime: Single;
    FCurrentValue: T;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    procedure Init(const AStartTime, ADuration: Single; const AStartValue, ABaseSpeed,
      ASpeed: T; const AExtrapolationType: Integer);
    function GetCurrentValue(const ATime: Single): T;
    function GetCurrentSpeed(const ATime: Single): T;
    function IsDone(const ATime: Single): Boolean;
    procedure SetStartTime(const ATime: Single);
    function GetStartTime: Single;
    /// <summary>0 when the extrapolation does not stop or has no duration</summary>
    function GetEndTime: Single;
    function GetDuration: Single;
    procedure SetStartValue(const AValue: T);
    function GetStartValue: T;
    function GetBaseSpeed: T;
    function GetSpeed: T;
    function GetExtrapolationType: Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math;

{ TIdExtrapolate<T> }

constructor TIdExtrapolate<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create;
  if not Assigned(AArithmetic) then
    raise EArgumentNilException.Create('AArithmetic');
  FArithmetic := AArithmetic;
  FExtrapolationType := ID_EXTRAPOLATION_NONE;
  FStartTime := 0.0;
  FDuration := 0.0;
  FStartValue := Default(T);
  FBaseSpeed := Default(T);
  FSpeed := Default(T);
  FCurrentTime := -1.0;
  FCurrentValue := FStartValue;
end;

procedure TIdExtrapolate<T>.Init(const AStartTime, ADuration: Single; const AStartValue,
  ABaseSpeed, ASpeed: T; const AExtrapolationType: Integer);
begin
  FExtrapolationType := AExtrapolationType;
  FStartTime := AStartTime;
  FDuration := ADuration;
  FStartValue := AStartValue;
  FBaseSpeed := ABaseSpeed;
  FSpeed := ASpeed;
  FCurrentTime := -1.0;
  FCurrentValue := AStartValue;
end;

function TIdExtrapolate<T>.GetCurrentValue(const ATime: Single): T;
var
  LTime, LDeltaTime, LS, LDuration: Single;
begin
  if ATime = FCurrentTime then
    Exit(FCurrentValue);
  FCurrentTime := ATime;
  if ATime < FStartTime then
    Exit(FStartValue);
  LTime := ATime;
  // the C++ compares in the precision of the FPU (x87: extended) and stores one float
  if ((FExtrapolationType and ID_EXTRAPOLATION_NOSTOP) = 0) and (LTime > FStartTime + FDuration) then
    LTime := FStartTime + FDuration;
  case FExtrapolationType and not ID_EXTRAPOLATION_NOSTOP of
    ID_EXTRAPOLATION_NONE:
      begin
        LDeltaTime := LTime - FStartTime;
        LDeltaTime := LDeltaTime * ID_MS2SEC;
        FCurrentValue := FArithmetic.Add(FStartValue, FArithmetic.Multiply(FBaseSpeed, LDeltaTime));
      end;
    ID_EXTRAPOLATION_LINEAR:
      begin
        LDeltaTime := LTime - FStartTime;
        LDeltaTime := LDeltaTime * ID_MS2SEC;
        FCurrentValue := FArithmetic.Add(FStartValue,
          FArithmetic.Multiply(FArithmetic.Add(FBaseSpeed, FSpeed), LDeltaTime));
      end;
    ID_EXTRAPOLATION_ACCELLINEAR:
      begin
        if FDuration = 0.0 then
          FCurrentValue := FStartValue
        else
        begin
          LDeltaTime := LTime - FStartTime;
          LDeltaTime := LDeltaTime / FDuration;
          LS := 0.5 * LDeltaTime;
          LS := LS * LDeltaTime;
          LDuration := FDuration * ID_MS2SEC;
          LS := LS * LDuration;
          FCurrentValue := FArithmetic.Add(
            FArithmetic.Add(FStartValue, FArithmetic.Multiply(FBaseSpeed, LDeltaTime)),
            FArithmetic.Multiply(FSpeed, LS));
        end;
      end;
    ID_EXTRAPOLATION_DECELLINEAR:
      begin
        if FDuration = 0.0 then
          FCurrentValue := FStartValue
        else
        begin
          LDeltaTime := LTime - FStartTime;
          LDeltaTime := LDeltaTime / FDuration;
          LS := 0.5 * LDeltaTime;
          LS := LS * LDeltaTime;
          LS := LDeltaTime - LS;
          LDuration := FDuration * ID_MS2SEC;
          LS := LS * LDuration;
          FCurrentValue := FArithmetic.Add(
            FArithmetic.Add(FStartValue, FArithmetic.Multiply(FBaseSpeed, LDeltaTime)),
            FArithmetic.Multiply(FSpeed, LS));
        end;
      end;
    ID_EXTRAPOLATION_ACCELSINE:
      begin
        if FDuration = 0.0 then
          FCurrentValue := FStartValue
        else
        begin
          LDeltaTime := LTime - FStartTime;
          LDeltaTime := LDeltaTime / FDuration;
          LS := LDeltaTime * ID_HALF_PI;
          LS := 1.0 - TIdMath.Cos(LS);
          LS := LS * FDuration;
          LS := LS * ID_MS2SEC;
          LS := LS * ID_SQRT_1OVER2;
          FCurrentValue := FArithmetic.Add(
            FArithmetic.Add(FStartValue, FArithmetic.Multiply(FBaseSpeed, LDeltaTime)),
            FArithmetic.Multiply(FSpeed, LS));
        end;
      end;
    ID_EXTRAPOLATION_DECELSINE:
      begin
        if FDuration = 0.0 then
          FCurrentValue := FStartValue
        else
        begin
          LDeltaTime := LTime - FStartTime;
          LDeltaTime := LDeltaTime / FDuration;
          LS := LDeltaTime * ID_HALF_PI;
          LS := TIdMath.Sin(LS);
          LS := LS * FDuration;
          LS := LS * ID_MS2SEC;
          LS := LS * ID_SQRT_1OVER2;
          FCurrentValue := FArithmetic.Add(
            FArithmetic.Add(FStartValue, FArithmetic.Multiply(FBaseSpeed, LDeltaTime)),
            FArithmetic.Multiply(FSpeed, LS));
        end;
      end;
  end;
  Result := FCurrentValue;
end;

function TIdExtrapolate<T>.GetCurrentSpeed(const ATime: Single): T;
var
  LDeltaTime, LS: Single;
begin
  if (ATime < FStartTime) or (FDuration = 0.0) then
    Exit(FArithmetic.Subtract(FStartValue, FStartValue));
  if ((FExtrapolationType and ID_EXTRAPOLATION_NOSTOP) = 0) and (ATime > FStartTime + FDuration) then
    Exit(FArithmetic.Subtract(FStartValue, FStartValue));
  case FExtrapolationType and not ID_EXTRAPOLATION_NOSTOP of
    ID_EXTRAPOLATION_NONE:
      Result := FBaseSpeed;
    ID_EXTRAPOLATION_LINEAR:
      Result := FArithmetic.Add(FBaseSpeed, FSpeed);
    ID_EXTRAPOLATION_ACCELLINEAR:
      begin
        LDeltaTime := ATime - FStartTime;
        LDeltaTime := LDeltaTime / FDuration;
        Result := FArithmetic.Add(FBaseSpeed, FArithmetic.Multiply(FSpeed, LDeltaTime));
      end;
    ID_EXTRAPOLATION_DECELLINEAR:
      begin
        LDeltaTime := ATime - FStartTime;
        LDeltaTime := LDeltaTime / FDuration;
        LS := 1.0 - LDeltaTime;
        Result := FArithmetic.Add(FBaseSpeed, FArithmetic.Multiply(FSpeed, LS));
      end;
    ID_EXTRAPOLATION_ACCELSINE:
      begin
        LDeltaTime := ATime - FStartTime;
        LDeltaTime := LDeltaTime / FDuration;
        LS := LDeltaTime * ID_HALF_PI;
        LS := TIdMath.Sin(LS);
        Result := FArithmetic.Add(FBaseSpeed, FArithmetic.Multiply(FSpeed, LS));
      end;
    ID_EXTRAPOLATION_DECELSINE:
      begin
        LDeltaTime := ATime - FStartTime;
        LDeltaTime := LDeltaTime / FDuration;
        LS := LDeltaTime * ID_HALF_PI;
        LS := TIdMath.Cos(LS);
        Result := FArithmetic.Add(FBaseSpeed, FArithmetic.Multiply(FSpeed, LS));
      end;
  else
    Result := FBaseSpeed;
  end;
end;

function TIdExtrapolate<T>.IsDone(const ATime: Single): Boolean;
begin
  Result := ((FExtrapolationType and ID_EXTRAPOLATION_NOSTOP) = 0) and (ATime >= FStartTime + FDuration);
end;

procedure TIdExtrapolate<T>.SetStartTime(const ATime: Single);
begin
  FStartTime := ATime;
  FCurrentTime := -1.0;
end;

function TIdExtrapolate<T>.GetStartTime: Single;
begin
  Result := FStartTime;
end;

function TIdExtrapolate<T>.GetEndTime: Single;
begin
  if ((FExtrapolationType and ID_EXTRAPOLATION_NOSTOP) = 0) and (FDuration > 0.0) then
    Result := FStartTime + FDuration
  else
    Result := 0.0;
end;

function TIdExtrapolate<T>.GetDuration: Single;
begin
  Result := FDuration;
end;

procedure TIdExtrapolate<T>.SetStartValue(const AValue: T);
begin
  FStartValue := AValue;
  FCurrentTime := -1.0;
end;

function TIdExtrapolate<T>.GetStartValue: T;
begin
  Result := FStartValue;
end;

function TIdExtrapolate<T>.GetBaseSpeed: T;
begin
  Result := FBaseSpeed;
end;

function TIdExtrapolate<T>.GetSpeed: T;
begin
  Result := FSpeed;
end;

function TIdExtrapolate<T>.GetExtrapolationType: Integer;
begin
  Result := FExtrapolationType;
end;

end.
