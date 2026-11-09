{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed32 - the geometry of the simulated race                    }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Sim.Geometry;

// Positions are 16.16 fixed point and wrap as in the engine
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   What the engine answers to the cars (the angle between two points, the distance from the view)
  ///   for a race without the engine: the angle is exact, the distance is the approximation of the
  ///   engine for a map of 32 bit, and the view is a point that the program sets
  /// </summary>
  TSpeedSimGeometry = class(TInterfacedObject, IRacingGeometry)
  strict private
    FViewX: TFixed;
    FViewY: TFixed;
  public
    function PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
    function ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
    property ViewX: TFixed read FViewX write FViewX;
    property ViewY: TFixed read FViewY write FViewY;
  end;

implementation

uses
  System.Math;

{ TSpeedSimGeometry }

function TSpeedSimGeometry.PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
var
  LAngle: Double;
begin
  LAngle := ArcTan2(AY2 - AY1, AX2 - AX1);
  if LAngle < 0 then
    LAngle := LAngle + 2 * Pi;
  Result := TAngle(Int64(Round(LAngle / (2 * Pi) * 4294967296.0)));
end;

function TSpeedSimGeometry.ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
var
  LDeltaX, LDeltaY: TFixed;
begin
  LDeltaX := Abs(FViewX - AX);
  LDeltaY := Abs(FViewY - AY);
  if LDeltaX < LDeltaY then
    Result := LDeltaX + LDeltaY - (LDeltaX shr 1)
  else
    Result := LDeltaX + LDeltaY - (LDeltaY shr 1);
end;

end.
