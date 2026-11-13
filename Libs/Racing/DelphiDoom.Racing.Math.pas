{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the small arithmetic of the cars               }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Math;

// The distances wrap and the products are Int64 as in the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>The functions of the old d_delphi and p_maputl that the cars use, without state</summary>
  TRacingMath = class
  public
    /// <summary>A value in the range (the old GetIntegerInRange)</summary>
    class function Clamp(AValue, AMinimum, AMaximum: Integer): Integer; static; inline;
    /// <summary>True if a value is between two limits, in either order (the old IsIntegerInRange)</summary>
    class function IsInRange(ATest, ALimit1, ALimit2: Integer): Boolean; static; inline;
    /// <summary>-1, 0 or 1 (the old iSign)</summary>
    class function Sign(AValue: Integer): Integer; static; inline;
    /// <summary>The smaller of two values (the old MinI)</summary>
    class function Minimum(AValue1, AValue2: Integer): Integer; static; inline;
    /// <summary>
    ///   The exact distance of a vector, rounded to the nearest fixed point number (the old
    ///   P_Distance, which the cars use for speeds and for the distances of the path). It is
    ///   computed in the precision of the floating point unit like the old code: in Win32 the
    ///   intermediate values are Extended
    /// </summary>
    class function Distance(ADeltaX, ADeltaY: TFixed): TFixed; static;
  end;

implementation

{ TRacingMath }

class function TRacingMath.Clamp(AValue, AMinimum, AMaximum: Integer): Integer;
begin
  if AValue < AMinimum then
    Result := AMinimum
  else if AValue > AMaximum then
    Result := AMaximum
  else
    Result := AValue;
end;

class function TRacingMath.IsInRange(ATest, ALimit1, ALimit2: Integer): Boolean;
begin
  if ALimit1 < ALimit2 then
    Result := (ATest >= ALimit1) and (ATest <= ALimit2)
  else
    Result := (ATest >= ALimit2) and (ATest <= ALimit1);
end;

class function TRacingMath.Sign(AValue: Integer): Integer;
begin
  if AValue > 0 then
    Result := 1
  else if AValue < 0 then
    Result := -1
  else
    Result := 0;
end;

class function TRacingMath.Minimum(AValue1, AValue2: Integer): Integer;
begin
  if AValue1 > AValue2 then
    Result := AValue2
  else
    Result := AValue1;
end;

class function TRacingMath.Distance(ADeltaX, ADeltaY: TFixed): TFixed;
var
  LSquares: Int64;
  LRoot: Int64;
begin
  // The old code computed Round(Sqrt(x * x + y * y) * 65536) on the values divided by 65536, with the
  // 64 bits of mantissa of the 32 bit FPU. That is the square root of the exact sum of the squares of
  // the fixed point values, rounded to the nearest integer (the sum has no tie): done with integers it
  // is the same number at 32 and 64 bit, where Double (53 bits) would round some large distances the
  // other way
  LSquares := Int64(ADeltaX) * ADeltaX + Int64(ADeltaY) * ADeltaY;
  LRoot := Trunc(Sqrt(LSquares));
  while LRoot * LRoot > LSquares do
    Dec(LRoot);
  while (LRoot + 1) * (LRoot + 1) <= LSquares do
    Inc(LRoot);
  // the root is between LRoot and LRoot + 1: above the middle when the square is above LRoot^2 + LRoot
  if LSquares > LRoot * LRoot + LRoot then
    Inc(LRoot);
  Result := LRoot;
end;

end.
