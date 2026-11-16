{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  vector macros                                                               }
{                                                                              }
{  Port of the vector macros of q_shared.h and of VectorNormalize and          }
{  VectorLength of q_math.c of the Quake III Arena GPL Source Code (id         }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.VectorMath;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types;

type
  /// <summary>
  ///   The vector macros of the C code with their float arithmetic: every operation is rounded to a
  ///   float on its own (a local Single holds each partial result), where the C mixes a double
  ///   (sqrt, a literal like 0.5) the Double is kept
  /// </summary>
  TQ3VectorMath = class sealed
  public
    /// <summary>VectorSubtract(a, b, out)</summary>
    class function Subtract(const AFirst, ASecond: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorAdd(a, b, out)</summary>
    class function Add(const AFirst, ASecond: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorMA(v, s, b, out): v + b * s</summary>
    class function MultiplyAdd(const AVector: TQ3Vec3; AScale: Single; const ADirection: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorScale(v, s, out)</summary>
    class function Scale(const AVector: TQ3Vec3; AScale: Single): TQ3Vec3; static;
    /// <summary>VectorNegate</summary>
    class function Negate(const AVector: TQ3Vec3): TQ3Vec3; static;
    /// <summary>CrossProduct(v1, v2, out)</summary>
    class function Cross(const AFirst, ASecond: TQ3Vec3): TQ3Vec3; static;
    /// <summary>VectorLength: (float) sqrt( x*x + y*y + z*z )</summary>
    class function Length(const AVector: TQ3Vec3): Single; static;
    /// <summary>VectorNormalize: normalizes in place and returns the length (0 leaves the vector as it was)</summary>
    class function Normalize(var AVector: TQ3Vec3): Single; static;
    /// <summary>The sum of the squares x*x + y*y + z*z, every operation in float</summary>
    class function LengthSquared(const AVector: TQ3Vec3): Single; static;
  end;

implementation

uses
  System.SysUtils;

class function TQ3VectorMath.Subtract(const AFirst, ASecond: TQ3Vec3): TQ3Vec3;
begin
  Result[0] := AFirst[0] - ASecond[0];
  Result[1] := AFirst[1] - ASecond[1];
  Result[2] := AFirst[2] - ASecond[2];
end;

class function TQ3VectorMath.Add(const AFirst, ASecond: TQ3Vec3): TQ3Vec3;
begin
  Result[0] := AFirst[0] + ASecond[0];
  Result[1] := AFirst[1] + ASecond[1];
  Result[2] := AFirst[2] + ASecond[2];
end;

class function TQ3VectorMath.MultiplyAdd(const AVector: TQ3Vec3; AScale: Single;
  const ADirection: TQ3Vec3): TQ3Vec3;
var
  LProduct: Single;
begin
  LProduct := ADirection[0] * AScale;
  Result[0] := AVector[0] + LProduct;
  LProduct := ADirection[1] * AScale;
  Result[1] := AVector[1] + LProduct;
  LProduct := ADirection[2] * AScale;
  Result[2] := AVector[2] + LProduct;
end;

class function TQ3VectorMath.Scale(const AVector: TQ3Vec3; AScale: Single): TQ3Vec3;
begin
  Result[0] := AVector[0] * AScale;
  Result[1] := AVector[1] * AScale;
  Result[2] := AVector[2] * AScale;
end;

class function TQ3VectorMath.Negate(const AVector: TQ3Vec3): TQ3Vec3;
begin
  Result[0] := -AVector[0];
  Result[1] := -AVector[1];
  Result[2] := -AVector[2];
end;

class function TQ3VectorMath.Cross(const AFirst, ASecond: TQ3Vec3): TQ3Vec3;
var
  LFirst, LSecond: Single;
begin
  LFirst := AFirst[1] * ASecond[2];
  LSecond := AFirst[2] * ASecond[1];
  Result[0] := LFirst - LSecond;
  LFirst := AFirst[2] * ASecond[0];
  LSecond := AFirst[0] * ASecond[2];
  Result[1] := LFirst - LSecond;
  LFirst := AFirst[0] * ASecond[1];
  LSecond := AFirst[1] * ASecond[0];
  Result[2] := LFirst - LSecond;
end;

class function TQ3VectorMath.LengthSquared(const AVector: TQ3Vec3): Single;
var
  LX, LY, LZ: Single;
begin
  LX := AVector[0] * AVector[0];
  LY := AVector[1] * AVector[1];
  LZ := AVector[2] * AVector[2];
  Result := LX + LY;
  Result := Result + LZ;
end;

class function TQ3VectorMath.Length(const AVector: TQ3Vec3): Single;
var
  LRoot: Double;
begin
  LRoot := Sqrt(Double(LengthSquared(AVector)));
  Result := LRoot;
end;

class function TQ3VectorMath.Normalize(var AVector: TQ3Vec3): Single;
var
  LInverse: Single;
  LRoot: Double;
begin
  LRoot := Sqrt(Double(LengthSquared(AVector)));
  Result := LRoot;
  if Result <> 0 then
  begin
    LInverse := 1 / Result;
    AVector[0] := AVector[0] * LInverse;
    AVector[1] := AVector[1] * LInverse;
    AVector[2] := AVector[2] * LInverse;
  end;
end;

end.
