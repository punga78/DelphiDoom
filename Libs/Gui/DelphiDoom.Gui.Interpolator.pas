{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - the interpolation of a transition                 }
{                                                                              }
{  Port of idlib (id Software, Doom 3, GPL v3): math\Interpolate.h             }
{  (idInterpolateAccelDecelLinear<idVec4>) and math\Extrapolate.h              }
{  (idExtrapolate<idVec4>, the none, linear, accel and decel modes).           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Interpolator;

interface

uses
  DelphiDoom.IdLib.Math.Vec4;

type
  /// <summary>EXTRAPOLATION_NONE, LINEAR, ACCELLINEAR and DECELLINEAR (the sine modes are not used by the GUI)</summary>
  TGuiExtrapolation = (exNone, exLinear, exAccelLinear, exDecelLinear);

  /// <summary>
  ///   idInterpolateAccelDecelLinear of idVec4: a value that goes from a start to an end value in a
  ///   duration, with an acceleration and a deceleration time. It keeps the state of the original
  ///   (the current phase), so <c>GetCurrentValue</c> is not a pure function of the time.
  /// </summary>
  TGuiInterpolator = class
  strict private
    FStartTime: Single;
    FAccelTime: Single;
    FLinearTime: Single;
    FDecelTime: Single;
    FStartValue: TIdVec4;
    FEndValue: TIdVec4;
    // idExtrapolate
    FExtrapolation: TGuiExtrapolation;
    FExStartTime: Single;
    FExDuration: Single;
    FExStartValue: TIdVec4;
    FExBaseSpeed: TIdVec4;
    FExSpeed: TIdVec4;
    FCurrentTime: Single;
    FCurrentValue: TIdVec4;
    procedure ExtrapolateInit(const AStartTime, ADuration: Single; const AStartValue, ABaseSpeed, ASpeed: TIdVec4;
      const AExtrapolation: TGuiExtrapolation);
    function ExtrapolateValue(ATime: Single): TIdVec4;
    procedure SetPhase(const ATime: Single);
  public
    constructor Create;
    /// <summary>Init: a duration of zero or less leaves the times as given and no extrapolation</summary>
    procedure Init(const AStartTime, AAccelTime, ADecelTime, ADuration: Single; const AStartValue,
      AEndValue: TIdVec4);
    function GetCurrentValue(const ATime: Single): TIdVec4;
    function IsDone(const ATime: Single): Boolean;
    property EndValue: TIdVec4 read FEndValue;
    property StartValue: TIdVec4 read FStartValue;
  end;

implementation

constructor TGuiInterpolator.Create;
begin
  inherited Create;
  FExtrapolation := exNone;
  FStartValue.Zero;
  FEndValue.Zero;
  FExStartValue.Zero;
  FExBaseSpeed.Zero;
  FExSpeed.Zero;
  FCurrentTime := -1;
  FCurrentValue.Zero;
end;

procedure TGuiInterpolator.ExtrapolateInit(const AStartTime, ADuration: Single; const AStartValue, ABaseSpeed,
  ASpeed: TIdVec4; const AExtrapolation: TGuiExtrapolation);
begin
  FExtrapolation := AExtrapolation;
  FExStartTime := AStartTime;
  FExDuration := ADuration;
  FExStartValue := AStartValue;
  FExBaseSpeed := ABaseSpeed;
  FExSpeed := ASpeed;
  FCurrentTime := -1;
  FCurrentValue := AStartValue;
end;

function TGuiInterpolator.ExtrapolateValue(ATime: Single): TIdVec4;
var
  LDelta: Single;
  LS: Single;
begin
  if ATime = FCurrentTime then
    Exit(FCurrentValue);
  FCurrentTime := ATime;
  if ATime < FExStartTime then
    Exit(FExStartValue);
  if ATime > FExStartTime + FExDuration then
    ATime := FExStartTime + FExDuration;
  case FExtrapolation of
    exNone:
      begin
        LDelta := (ATime - FExStartTime) * 0.001;
        FCurrentValue := FExStartValue + FExBaseSpeed * LDelta;
      end;
    exLinear:
      begin
        LDelta := (ATime - FExStartTime) * 0.001;
        FCurrentValue := FExStartValue + (FExBaseSpeed + FExSpeed) * LDelta;
      end;
    exAccelLinear:
      begin
        if FExDuration = 0 then
          FCurrentValue := FExStartValue
        else
        begin
          LDelta := (ATime - FExStartTime) / FExDuration;
          LS := (0.5 * LDelta * LDelta) * (FExDuration * 0.001);
          FCurrentValue := FExStartValue + FExBaseSpeed * LDelta + FExSpeed * LS;
        end;
      end;
    exDecelLinear:
      begin
        if FExDuration = 0 then
          FCurrentValue := FExStartValue
        else
        begin
          LDelta := (ATime - FExStartTime) / FExDuration;
          LS := (LDelta - (0.5 * LDelta * LDelta)) * (FExDuration * 0.001);
          FCurrentValue := FExStartValue + FExBaseSpeed * LDelta + FExSpeed * LS;
        end;
      end;
  end;
  Result := FCurrentValue;
end;

procedure TGuiInterpolator.Init(const AStartTime, AAccelTime, ADecelTime, ADuration: Single; const AStartValue,
  AEndValue: TIdVec4);
var
  LSpeed: TIdVec4;
  LZero: TIdVec4;
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
  LSpeed := (AEndValue - AStartValue) * (1000.0 / (FLinearTime + (FAccelTime + FDecelTime) * 0.5));
  LZero.Zero;
  if FAccelTime <> 0 then
    ExtrapolateInit(AStartTime, FAccelTime, AStartValue, LZero, LSpeed, exAccelLinear)
  else if FLinearTime <> 0 then
    ExtrapolateInit(AStartTime, FLinearTime, AStartValue, LZero, LSpeed, exLinear)
  else
    ExtrapolateInit(AStartTime, FDecelTime, AStartValue, LZero, LSpeed, exDecelLinear);
end;

procedure TGuiInterpolator.SetPhase(const ATime: Single);
var
  LDelta: Single;
begin
  LDelta := ATime - FStartTime;
  if LDelta < FAccelTime then
  begin
    if FExtrapolation <> exAccelLinear then
      ExtrapolateInit(FStartTime, FAccelTime, FStartValue, FExBaseSpeed, FExSpeed, exAccelLinear);
  end
  else if LDelta < FAccelTime + FLinearTime then
  begin
    if FExtrapolation <> exLinear then
      ExtrapolateInit(FStartTime + FAccelTime, FLinearTime, FStartValue + FExSpeed * (FAccelTime * 0.001 * 0.5),
        FExBaseSpeed, FExSpeed, exLinear);
  end
  else if FExtrapolation <> exDecelLinear then
    ExtrapolateInit(FStartTime + FAccelTime + FLinearTime, FDecelTime,
      FEndValue - (FExSpeed * (FDecelTime * 0.001 * 0.5)), FExBaseSpeed, FExSpeed, exDecelLinear);
end;

function TGuiInterpolator.GetCurrentValue(const ATime: Single): TIdVec4;
begin
  SetPhase(ATime);
  Result := ExtrapolateValue(ATime);
end;

function TGuiInterpolator.IsDone(const ATime: Single): Boolean;
begin
  Result := ATime >= FStartTime + FAccelTime + FLinearTime + FDecelTime;
end;

end.
