{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the floating point of the polygon clipper    }
{  (r_clipper.pas) with the result of the 32 bit code                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.ClipperX87;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The floating point expressions of the clipper of the slopes and of the 3D floors (r_clipper.pas, SetDx,
  ///   TopX, IntersectPointEx) with the result of the 32 bit code (issue #40): the inverse slope of an edge and
  ///   the intersection of two edges are stored in a Double after a computation in 64 bits of mantissa (x87), and
  ///   the points that come out are the integers that polygons are made of. The 32 bit clipper never links it
  /// </summary>
  TRendererClipperX87 = class
  public
    /// <summary>Dx of SetDx: ADeltaX / ADeltaY stored in a Double</summary>
    class function InverseSlope(ADeltaX, ADeltaY: Int64): Double; static;
    /// <summary>Round(ADx * ADeltaY) of TopX</summary>
    class function RoundOffset(const ADx: Double; ADeltaY: Int64): Int64; static;
    /// <summary>B of the vertical edge: ABotY - (ABotX / ADx) stored in a Double</summary>
    class function VerticalIntercept(ABotX, ABotY: Int64; const ADx: Double): Double; static;
    /// <summary>Round(AX / ADx + AIntercept)</summary>
    class function RoundAtX(AX: Int64; const ADx, AIntercept: Double): Int64; static;
    /// <summary>B of an edge: ABotX - ABotY * ADx stored in a Double</summary>
    class function Intercept(ABotX, ABotY: Int64; const ADx: Double): Double; static;
    /// <summary>M: (AIntercept2 - AIntercept1) / (ADx1 - ADx2) stored in a Double</summary>
    class function CrossingY(const AIntercept1, AIntercept2, ADx1, ADx2: Double): Double; static;
    /// <summary>Round(ADx * AY + AIntercept)</summary>
    class function RoundAtY(const ADx, AY, AIntercept: Double): Int64; static;
  end;

implementation

uses
  DelphiDoom.MathCore.SoftExtended;

function Ext(AValue: Int64): TSoftExtended; inline;
begin
  Result := TSoftExtended.FromInt64(AValue);
end;

function Dbl(const AValue: Double): TSoftExtended; inline;
begin
  Result := TSoftExtended.FromDouble(AValue);
end;

class function TRendererClipperX87.InverseSlope(ADeltaX, ADeltaY: Int64): Double;
begin
  Result := (Ext(ADeltaX) / Ext(ADeltaY)).ToDouble;
end;

class function TRendererClipperX87.RoundOffset(const ADx: Double; ADeltaY: Int64): Int64;
begin
  Result := (Dbl(ADx) * Ext(ADeltaY)).Round;
end;

class function TRendererClipperX87.VerticalIntercept(ABotX, ABotY: Int64; const ADx: Double): Double;
begin
  Result := (Ext(ABotY) - Ext(ABotX) / Dbl(ADx)).ToDouble;
end;

class function TRendererClipperX87.RoundAtX(AX: Int64; const ADx, AIntercept: Double): Int64;
begin
  Result := (Ext(AX) / Dbl(ADx) + Dbl(AIntercept)).Round;
end;

class function TRendererClipperX87.Intercept(ABotX, ABotY: Int64; const ADx: Double): Double;
begin
  Result := (Ext(ABotX) - Ext(ABotY) * Dbl(ADx)).ToDouble;
end;

class function TRendererClipperX87.CrossingY(const AIntercept1, AIntercept2, ADx1, ADx2: Double): Double;
begin
  Result := ((Dbl(AIntercept2) - Dbl(AIntercept1)) / (Dbl(ADx1) - Dbl(ADx2))).ToDouble;
end;

class function TRendererClipperX87.RoundAtY(const ADx, AY, AIntercept: Double): Int64;
begin
  Result := (Dbl(ADx) * Dbl(AY) + Dbl(AIntercept)).Round;
end;

end.
