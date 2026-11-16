{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the vector macros of be_aas_reach.c               }
{                                                                              }
{  VectorMA with a scale that is an int or a float (the macro gives two        }
{  roundings: the product is a float, then the sum), VectorScale, VectorAdd,   }
{  VectorMiddle, VectorDistance and VectorBetweenVectors of be_aas_reach.c.    }
{  The macros with a double scale (VectorMA(.., 0.1, ..)) are                  }
{  TAasVectorMath.MultiplyAdd. Based on the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Vectors;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>The vector operations of be_aas_reach.c; every operation is rounded to a float on its own, as the SSE code does</summary>
  TAasReachVectors = class sealed
  public
    /// <summary>VectorMA(v, s, b, o) with s an int or a float: o = v + b * s; o may be v or b</summary>
    class procedure MultiplyAdd(const V: TVec3; const AScale: Single; const B: TVec3; var AOut: TVec3); static;
    /// <summary>VectorScale(v, s, o) with s an int, a float or 0.5: o = v * s</summary>
    class procedure Scale(const V: TVec3; const AScale: Single; var AOut: TVec3); static;
    /// <summary>VectorAdd(a, b, o): o may be a or b</summary>
    class procedure Add(const A, B: TVec3; var AOut: TVec3); static;
    /// <summary>VectorMiddle: the middle of the two vectors</summary>
    class procedure Middle(const A, B: TVec3; var AOut: TVec3); static;
    /// <summary>VectorDistance: the length of b - a</summary>
    class function Distance(const A, B: TVec3): Single; static;
    /// <summary>VectorBetweenVectors: (v - v1) . (v - v2) &lt;= 0</summary>
    class function Between(const V, V1, V2: TVec3): Boolean; static;
    /// <summary>VectorLength of the vector with the z set to zero</summary>
    class function HorizontalLength(const V: TVec3): Single; static;
    /// <summary>traveltime += value: the sum is a float, the conversion to unsigned short keeps the low 16 bits of the int</summary>
    class function AddTravelTime(const ATime: Word; const AValue: Single): Word; static;
    /// <summary>traveltime = value (a float or a double converted to unsigned short)</summary>
    class function ToTravelTime(const AValue: Double): Word; static;
  end;

implementation

uses
  DelphiDoom.Aas.VectorMath;

{ TAasReachVectors }

class procedure TAasReachVectors.MultiplyAdd(const V: TVec3; const AScale: Single; const B: TVec3; var AOut: TVec3);
var
  LIndex: Integer;
  LProduct, LSum: Single;
begin
  for LIndex := 0 to 2 do
  begin
    LProduct := B[LIndex] * AScale;
    LSum := V[LIndex] + LProduct;
    AOut[LIndex] := LSum;
  end;
end;

class procedure TAasReachVectors.Scale(const V: TVec3; const AScale: Single; var AOut: TVec3);
var
  LIndex: Integer;
  LProduct: Single;
begin
  for LIndex := 0 to 2 do
  begin
    LProduct := V[LIndex] * AScale;
    AOut[LIndex] := LProduct;
  end;
end;

class procedure TAasReachVectors.Add(const A, B: TVec3; var AOut: TVec3);
var
  LIndex: Integer;
  LSum: Single;
begin
  for LIndex := 0 to 2 do
  begin
    LSum := A[LIndex] + B[LIndex];
    AOut[LIndex] := LSum;
  end;
end;

class procedure TAasReachVectors.Middle(const A, B: TVec3; var AOut: TVec3);
var
  LSum: TVec3;
begin
  Add(A, B, LSum);
  Scale(LSum, 0.5, AOut);
end;

class function TAasReachVectors.Distance(const A, B: TVec3): Single;
var
  LDirection: TVec3;
begin
  TAasVectorMath.Subtract(B, A, LDirection);
  Result := TAasVectorMath.Length(LDirection);
end;

class function TAasReachVectors.Between(const V, V1, V2: TVec3): Boolean;
var
  LDirection1, LDirection2: TVec3;
begin
  TAasVectorMath.Subtract(V, V1, LDirection1);
  TAasVectorMath.Subtract(V, V2, LDirection2);
  Result := TAasVectorMath.Dot(LDirection1, LDirection2) <= 0;
end;

class function TAasReachVectors.AddTravelTime(const ATime: Word; const AValue: Single): Word;
var
  LSum: Single;
begin
  LSum := ATime;
  LSum := LSum + AValue;
  Result := Word(Trunc(LSum) and $FFFF);
end;

class function TAasReachVectors.ToTravelTime(const AValue: Double): Word;
begin
  Result := Word(Trunc(AValue) and $FFFF);
end;

class function TAasReachVectors.HorizontalLength(const V: TVec3): Single;
var
  LHorizontal: TVec3;
begin
  LHorizontal := V;
  LHorizontal[2] := 0;
  Result := TAasVectorMath.Length(LHorizontal);
end;

end.
