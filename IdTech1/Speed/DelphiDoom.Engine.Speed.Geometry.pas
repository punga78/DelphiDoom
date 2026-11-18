{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the cars ask of the world: angles and distances   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Speed.Geometry;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   The geometry of the cars on the engine: R_PointToAngle2 and the approximate distance from the
  ///   view (it reads the historical globals viewx and viewy: this is a class of the engine)
  /// </summary>
  TEngineSpeedGeometry = class(TInterfacedObject, IRacingGeometry)
  public
    function PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
    function ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
  end;

implementation

uses
  p_maputl,
  r_main;

{ TEngineSpeedGeometry }

function TEngineSpeedGeometry.PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
begin
  Result := TRendererMain.R_PointToAngle2(AX1, AY1, AX2, AY2);
end;

function TEngineSpeedGeometry.ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
begin
  Result := P_AproxDistance(viewx - AX, viewy - AY);
end;

end.
