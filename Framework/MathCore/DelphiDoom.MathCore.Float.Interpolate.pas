{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdInterpolate<T>                   }
{                                                                              }
{  Port of idInterpolate (idlib\math\Interpolate.h) of the Doom 3 GPL Source   }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Interpolate;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   The linear interpolation of a value of any type between two values over a duration
  ///   (idInterpolate&lt;type&gt;). The arithmetic of the value type is the strategy of the
  ///   curves, <c>IIdCurveArithmetic</c>. Times are in milliseconds. The last result is cached by
  ///   time as in the C++.
  /// </summary>
  TIdInterpolate<T> = class
  strict private
    FArithmetic: IIdCurveArithmetic<T>;
    FStartTime: Single;
    FDuration: Single;
    FStartValue: T;
    FEndValue: T;
    FCurrentTime: Single;
    FCurrentValue: T;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    procedure Init(const AStartTime, ADuration: Single; const AStartValue, AEndValue: T);
    procedure SetStartTime(const ATime: Single);
    procedure SetDuration(const ADuration: Single);
    procedure SetStartValue(const AStartValue: T);
    procedure SetEndValue(const AEndValue: T);
    function GetCurrentValue(const ATime: Single): T;
    function IsDone(const ATime: Single): Boolean;
    function GetStartTime: Single;
    function GetEndTime: Single;
    function GetDuration: Single;
    function GetStartValue: T;
    function GetEndValue: T;
  end;

implementation

uses
  System.SysUtils;

{ TIdInterpolate<T> }

constructor TIdInterpolate<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create;
  if not Assigned(AArithmetic) then
    raise EArgumentNilException.Create('AArithmetic');
  FArithmetic := AArithmetic;
  FCurrentTime := 0.0;
  FStartTime := 0.0;
  FDuration := 0.0;
  FCurrentValue := Default(T);
  FStartValue := FCurrentValue;
  FEndValue := FCurrentValue;
end;

procedure TIdInterpolate<T>.Init(const AStartTime, ADuration: Single; const AStartValue,
  AEndValue: T);
begin
  FStartTime := AStartTime;
  FDuration := ADuration;
  FStartValue := AStartValue;
  FEndValue := AEndValue;
  FCurrentTime := AStartTime - 1.0;
  FCurrentValue := AStartValue;
end;

procedure TIdInterpolate<T>.SetStartTime(const ATime: Single);
begin
  FStartTime := ATime;
end;

procedure TIdInterpolate<T>.SetDuration(const ADuration: Single);
begin
  FDuration := ADuration;
end;

procedure TIdInterpolate<T>.SetStartValue(const AStartValue: T);
begin
  FStartValue := AStartValue;
end;

procedure TIdInterpolate<T>.SetEndValue(const AEndValue: T);
begin
  FEndValue := AEndValue;
end;

function TIdInterpolate<T>.GetCurrentValue(const ATime: Single): T;
var
  LDeltaTime, LFraction: Single;
begin
  LDeltaTime := ATime - FStartTime;
  if ATime <> FCurrentTime then
  begin
    FCurrentTime := ATime;
    if LDeltaTime <= 0.0 then
      FCurrentValue := FStartValue
    else if LDeltaTime >= FDuration then
      FCurrentValue := FEndValue
    else
    begin
      LFraction := LDeltaTime / FDuration;
      FCurrentValue := FArithmetic.Add(FStartValue,
        FArithmetic.Multiply(FArithmetic.Subtract(FEndValue, FStartValue), LFraction));
    end;
  end;
  Result := FCurrentValue;
end;

function TIdInterpolate<T>.IsDone(const ATime: Single): Boolean;
begin
  Result := ATime >= FStartTime + FDuration;
end;

function TIdInterpolate<T>.GetStartTime: Single;
begin
  Result := FStartTime;
end;

function TIdInterpolate<T>.GetEndTime: Single;
begin
  Result := FStartTime + FDuration;
end;

function TIdInterpolate<T>.GetDuration: Single;
begin
  Result := FDuration;
end;

function TIdInterpolate<T>.GetStartValue: T;
begin
  Result := FStartValue;
end;

function TIdInterpolate<T>.GetEndValue: T;
begin
  Result := FEndValue;
end;

end.
