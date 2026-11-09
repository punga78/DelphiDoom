{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - the number helpers of fmath.h           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Math;

interface

uses
  System.SysUtils, System.Math;

type
  /// <summary>Round and Clamp of OpenXcom (fmath.h): the interface classes use them for positions and values</summary>
  TXcomMath = class sealed
  public
    /// <summary>Round(double): half away from zero (not the banker's rounding of System.Round)</summary>
    class function RoundHalfAway(AValue: Double): Double; static;
    /// <summary>Round(double) then the conversion to int</summary>
    class function RoundToInt(AValue: Double): Integer; static;
    class function Clamp(AValue, AMin, AMax: Integer): Integer; overload; static;
    class function Clamp(AValue, AMin, AMax: Double): Double; overload; static;
    /// <summary>The cast (Uint16) of a double that is not negative: the low 16 bits of the truncated value</summary>
    class function ToWord(AValue: Double): Integer; static;
  end;

implementation

class function TXcomMath.RoundHalfAway(AValue: Double): Double;
begin
  if AValue < 0.0 then
    Result := Ceil(AValue - 0.5)
  else
    Result := Floor(AValue + 0.5);
end;

class function TXcomMath.RoundToInt(AValue: Double): Integer;
begin
  Result := Trunc(RoundHalfAway(AValue));
end;

class function TXcomMath.Clamp(AValue, AMin, AMax: Integer): Integer;
begin
  // std::min(std::max(x, min), max)
  if AValue < AMin then
    AValue := AMin;
  if AValue > AMax then
    AValue := AMax;
  Result := AValue;
end;

class function TXcomMath.Clamp(AValue, AMin, AMax: Double): Double;
begin
  if AValue < AMin then
    AValue := AMin;
  if AValue > AMax then
    AValue := AMax;
  Result := AValue;
end;

class function TXcomMath.ToWord(AValue: Double): Integer;
begin
  Result := Trunc(AValue) and $FFFF;
end;

end.
