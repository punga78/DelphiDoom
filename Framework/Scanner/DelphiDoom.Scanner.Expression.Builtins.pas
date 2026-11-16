{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the functions that every expression has        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Expression.Builtins;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Expression.Intf;

type
  /// <summary>Receives a function: its name, its code and the number of arguments (-1 for any)</summary>
  TExpressionRegistrar = reference to procedure(const AName: string; const AFunction: TExpressionFunction;
    AParams: Integer);

  /// <summary>
  ///   The strings, the math and the trigonometry of the old TEvaluator. The angles are in
  ///   degrees. LOG10 and LOG2 give the same values as the old code (they were not the
  ///   logarithms)
  /// </summary>
  TExpressionBuiltins = class
  private
    FLog: ILog;
    procedure Warn(const AMessage: string);
    function StringCat(const AParams: TArray<string>): string;
    function StringLength(const AParams: TArray<string>): string;
    function StringInsert(const AParams: TArray<string>): string;
    function StringDelete(const AParams: TArray<string>): string;
    function StringPosition(const AParams: TArray<string>): string;
    function Choose(const AParams: TArray<string>): string;
    function Minimum(const AParams: TArray<string>): string;
    function Maximum(const AParams: TArray<string>): string;
    function Power(const AParams: TArray<string>): string;
    function AbsoluteValue(const AParams: TArray<string>): string;
  public
    constructor Create(const ALog: ILog);
    procedure RegisterAll(const ARegistrar: TExpressionRegistrar);
    /// <summary>Removes the first and the last character (the quotes of a text)</summary>
    class function StripQuotes(const AText: string): string; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Scanner.Numbers, DelphiDoom.Scanner.Strings;

//==============================================================================
//
// FloatOf
//
//==============================================================================
function FloatOf(const AText: string): Single;
begin
  Result := TScannerNumbers.ToFloat(AText);
end;

//==============================================================================
//
// RadiansOf
//
// The old code computed this in the extended type: the same here
//
//==============================================================================
function RadiansOf(const AText: string): Extended;
begin
  Result := FloatOf(AText) / 360 * 2 * Pi;
end;

//==============================================================================
//
// Text
//
//==============================================================================
function Text(AValue: Single): string;
begin
  Result := TScannerNumbers.FloatToText(AValue);
end;

{ TExpressionBuiltins }

constructor TExpressionBuiltins.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TExpressionBuiltins.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

class function TExpressionBuiltins.StripQuotes(const AText: string): string;
begin
  Result := AText;
  Delete(Result, 1, 1);
  Delete(Result, Length(Result), 1);
end;

function TExpressionBuiltins.StringCat(const AParams: TArray<string>): string;
begin
  Result := AParams[0] + AParams[1];
  Delete(Result, Length(AParams[0]), 2);
end;

function TExpressionBuiltins.StringLength(const AParams: TArray<string>): string;
begin
  Result := TScannerNumbers.IntToText(Length(AParams[0]) - 2);
end;

function TExpressionBuiltins.StringInsert(const AParams: TArray<string>): string;
begin
  Result := StripQuotes(AParams[1]);
  Insert(StripQuotes(AParams[0]), Result, TScannerStrings.ToInteger(AParams[2]));
end;

function TExpressionBuiltins.StringDelete(const AParams: TArray<string>): string;
begin
  Result := StripQuotes(AParams[0]);
  Delete(Result, TScannerStrings.ToInteger(AParams[1]), TScannerStrings.ToInteger(AParams[2]));
end;

function TExpressionBuiltins.StringPosition(const AParams: TArray<string>): string;
begin
  Result := TScannerNumbers.IntToText(Pos(StripQuotes(AParams[0]), StripQuotes(AParams[1])));
end;

function TExpressionBuiltins.Choose(const AParams: TArray<string>): string;
var
  LUpper: string;
begin
  LUpper := TScannerStrings.UpperAscii(AParams[0]);
  if (LUpper = 'FALSE') or (LUpper = 'TRUE') then
  begin
    if LUpper = 'TRUE' then
      Result := AParams[1]
    else
      Result := AParams[2];
  end
  else if FloatOf(AParams[0]) <> 0 then
    Result := AParams[1]
  else
    Result := AParams[2];
end;

function TExpressionBuiltins.AbsoluteValue(const AParams: TArray<string>): string;
begin
  Result := AParams[0];
  if (Result <> '') and (Result[1] = '-') then
    Delete(Result, 1, 1);
end;

function TExpressionBuiltins.Minimum(const AParams: TArray<string>): string;
var
  LResult: Single;
  LValue: Single;
  LIndex: Integer;
begin
  if Length(AParams) < 2 then
    Warn('TEvaluator.PF_min(): At least 2 parameters expected'#13#10);
  LResult := 3E38;
  for LIndex := 0 to High(AParams) do
  begin
    LValue := FloatOf(AParams[LIndex]);
    if LValue < LResult then
      LResult := LValue;
  end;
  Result := Text(LResult);
end;

function TExpressionBuiltins.Maximum(const AParams: TArray<string>): string;
var
  LResult: Single;
  LValue: Single;
  LIndex: Integer;
begin
  if Length(AParams) < 2 then
    Warn('TEvaluator.PF_max(): At least 2 parameters expected'#13#10);
  LResult := -3E38;
  for LIndex := 0 to High(AParams) do
  begin
    LValue := FloatOf(AParams[LIndex]);
    if LValue > LResult then
      LResult := LValue;
  end;
  Result := Text(LResult);
end;

function TExpressionBuiltins.Power(const AParams: TArray<string>): string;
begin
  if (AParams[0] = 'INF') or (AParams[1] = 'INF') then
    Result := 'INF'
  else
    Result := Text(Exp(FloatOf(AParams[1]) * Ln(FloatOf(AParams[0]))));
end;

procedure TExpressionBuiltins.RegisterAll(const ARegistrar: TExpressionRegistrar);
begin
  // strings
  ARegistrar('STRCAT', StringCat, 2);
  ARegistrar('STRLEN', StringLength, 1);
  ARegistrar('STRINS', StringInsert, 3);
  ARegistrar('STRDEF', StringDelete, 3);
  ARegistrar('STRPOS', StringPosition, 2);
  ARegistrar('IF', Choose, 3);
  ARegistrar('IFF', Choose, 3);

  // math
  ARegistrar('VAL',
    function(const AParams: TArray<string>): string
    begin
      Result := AParams[0];
    end, 1);
  ARegistrar('ABS', AbsoluteValue, 1);
  ARegistrar('MIN', Minimum, -1);
  ARegistrar('MAX', Maximum, -1);
  ARegistrar('EXP',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Exp(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('LOG',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Ln(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('LOG10',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Ln(FloatOf(AParams[0]) * 0.4342944819032518));
    end, 1);
  ARegistrar('LOG2',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Ln(FloatOf(AParams[0]) * 1.4426950408889634));
    end, 1);
  ARegistrar('CEIL',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Ceil(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('FLOOR',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Floor(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('ROUND',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Round(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('TRUNC',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Trunc(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('INT',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Trunc(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('SQR',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Sqr(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('SQRT',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Sqrt(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('FRAC',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Frac(FloatOf(AParams[0])));
    end, 1);
  ARegistrar('POWER', Power, 1);

  // trigonometry (degrees)
  ARegistrar('SIN',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Sin(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('COS',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Cos(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('TAN',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(Tan(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('ASIN',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(ArcSin(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('ACOS',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(ArcCos(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('ATAN',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(ArcTan(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('SINH',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(SinH(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('COSH',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(CosH(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('TANH',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(TanH(RadiansOf(AParams[0])));
    end, 1);
  ARegistrar('ATAN2',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(ArcTan2(RadiansOf(AParams[0]), RadiansOf(AParams[1])));
    end, 2);
  ARegistrar('VECTORANGLE',
    function(const AParams: TArray<string>): string
    begin
      Result := Text(ArcTan2(RadiansOf(AParams[1]), RadiansOf(AParams[0])));
    end, 2);
end;

end.
