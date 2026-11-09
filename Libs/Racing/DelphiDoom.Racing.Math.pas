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
  LX, LY: Double;
begin
  LX := ADeltaX / FIXED_ONE;
  LY := ADeltaY / FIXED_ONE;
  Result := Round(Sqrt(LX * LX + LY * LY) * FIXED_ONE);
end;

end.
