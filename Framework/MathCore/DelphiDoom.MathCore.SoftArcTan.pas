{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the arc tangent of the 80 bit FPU in        }
{  software                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.SoftArcTan;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.SoftExtended;

type
  /// <summary>
  ///   ArcTan and ArcTan2 of TSoftExtended, for the 64 bit code that must give the integer that the 32 bit code
  ///   (fpatan) gives after a Round
  /// </summary>
  /// <remarks>
  ///   Not bit exact with fpatan: the argument is halved three times (x / (1 + Sqrt(1 + x * x))) and the series
  ///   is summed, so the error is a few units of the last of the 64 bits (about 1e-19 relative). A Round of a
  ///   value that is not within that distance of a half gives the same integer. Slow (microseconds): load time
  ///   and set up of the view, never per pixel
  /// </remarks>
  TSoftArcTan = class
  strict private
    class function Series(const AValue: TSoftExtended): TSoftExtended; static;
  public
    /// <summary>ArcTan(AValue), in -Pi/2..Pi/2</summary>
    class function ArcTan(const AValue: TSoftExtended): TSoftExtended; static;
    /// <summary>ArcTan2(AY, AX), in -Pi..Pi; 0 for 0, 0</summary>
    class function ArcTan2(const AY, AX: TSoftExtended): TSoftExtended; static;
  end;

implementation

const
  // Pi rounded to 64 bits (the constant of the FPU)
  PI_MANTISSA = UInt64($C90FDAA22168C235);
  PI_EXPONENT = -62;
  HALVINGS = 3;
  SERIES_TERMS = 14;

class function TSoftArcTan.Series(const AValue: TSoftExtended): TSoftExtended;
var
  LSquare: TSoftExtended;
  LSum: TSoftExtended;
  LIndex: Integer;
begin
  // x * (1 - t / 3 + t^2 / 5 - ...), t = x * x, by Horner from the last term
  LSquare := AValue * AValue;
  LSum := TSoftExtended.FromRatio(1, 2 * SERIES_TERMS + 1);
  for LIndex := SERIES_TERMS - 1 downto 0 do
    LSum := TSoftExtended.FromRatio(1, 2 * LIndex + 1) - LSquare * LSum;
  Result := AValue * LSum;
end;

class function TSoftArcTan.ArcTan(const AValue: TSoftExtended): TSoftExtended;
var
  LValue: TSoftExtended;
  LOne: TSoftExtended;
  LInverted: Boolean;
  LIndex: Integer;
  LPi: TSoftExtended;
begin
  if AValue.IsZero then
    Exit(AValue);
  LOne := TSoftExtended.FromInt64(1);
  LValue := AValue;
  if LValue.IsNegative then
    LValue := -LValue;
  LInverted := LValue > LOne;
  if LInverted then
    LValue := LOne / LValue;
  for LIndex := 1 to HALVINGS do
    LValue := LValue / (LOne + TSoftExtended.Sqrt(LOne + LValue * LValue));
  Result := Series(LValue);
  for LIndex := 1 to HALVINGS do
    Result := Result + Result;
  if LInverted then
  begin
    LPi := TSoftExtended.FromMantissa(PI_MANTISSA, PI_EXPONENT);
    Result := LPi / TSoftExtended.FromInt64(2) - Result;
  end;
  if AValue.IsNegative then
    Result := -Result;
end;

class function TSoftArcTan.ArcTan2(const AY, AX: TSoftExtended): TSoftExtended;
var
  LPi: TSoftExtended;
begin
  LPi := TSoftExtended.FromMantissa(PI_MANTISSA, PI_EXPONENT);
  if AX.IsZero then
  begin
    if AY.IsZero then
      Exit(AY);
    if AY.IsNegative then
      Exit(-(LPi / TSoftExtended.FromInt64(2)));
    Exit(LPi / TSoftExtended.FromInt64(2));
  end;
  if AY.IsZero then
  begin
    if AX.IsNegative then
      Exit(LPi);
    Exit(AY);
  end;
  Result := ArcTan(AY / AX);
  if AX.IsNegative then
  begin
    if AY.IsNegative then
      Result := Result - LPi
    else
      Result := Result + LPi;
  end;
end;

end.
