{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the plane through three points                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.PlaneMath;

interface

uses
  DelphiDoom.Udmf.Apply.Types;

type
  /// <summary>The plane through three points, in the same Single arithmetic as calc_slope_plane of the engine</summary>
  TUdmfPlaneMath = class
  public
    /// <summary>The plane through (X1, Y1, Z1), (X2, Y2, Z2) and (X3, Y3, Z3); InverseC is 1 / c</summary>
    class function ThroughPoints(const AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3, AZ3: Single): TUdmfPlane; static;
  end;

implementation

{ TUdmfPlaneMath }

class function TUdmfPlaneMath.ThroughPoints(const AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3,
  AZ3: Single): TUdmfPlane;
var
  LA1, LB1, LC1: Single;
  LA2, LB2, LC2: Single;
  LA, LB, LC, LD: Single;
begin
  LA1 := AX2 - AX1;
  LB1 := AY2 - AY1;
  LC1 := AZ2 - AZ1;
  LA2 := AX3 - AX1;
  LB2 := AY3 - AY1;
  LC2 := AZ3 - AZ1;
  LA := LB1 * LC2 - LB2 * LC1;
  LB := LA2 * LC1 - LA1 * LC2;
  LC := LA1 * LB2 - LB1 * LA2;
  LD := (-LA * AX1 - LB * AY1 - LC * AZ1);
  Result.A := LA;
  Result.B := LB;
  Result.InverseC := 1 / LC;
  Result.D := LD;
end;

end.
