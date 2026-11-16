{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: vertex and vector math   }
{                                                                              }
{  Port of LerpDrawVert (tr_curve.c) and of the vector functions of q_shared.h }
{  and q_math.c that it needs (VectorNormalize, VectorNormalize2, CrossProduct,}
{  VectorLength...). Based on the Quake III Arena GPL Source Code (id          }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.VertexMath;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>
  ///   The float arithmetic of Quake III: every operation is rounded to Single before the next
  ///   (the C code is compiled for SSE, one operation per rounding); the Delphi x87 would keep
  ///   an expression in extended precision, so each step is stored in a Single. The square
  ///   roots are computed in Double and rounded, as sqrt() of C does.
  /// </summary>
  TPatchVertexMath = class
  public
    /// <summary>LerpDrawVert: the middle of two vertices (colour channels halved as integers)</summary>
    class function Lerp(const A, B: TPatchVertex): TPatchVertex; static;
    /// <summary>DotProduct</summary>
    class function Dot(const A, B: TIdVec3): Single; static;
    /// <summary>VectorLengthSquared</summary>
    class function LengthSquared(const A: TIdVec3): Single; static;
    /// <summary>VectorLength</summary>
    class function Length(const A: TIdVec3): Single; static;
    /// <summary>CrossProduct</summary>
    class function Cross(const A, B: TIdVec3): TIdVec3; static;
    /// <summary>VectorNormalize: in place, returns the length (a vector of length 0 is left as is)</summary>
    class function Normalize(var AVector: TIdVec3): Single; static;
    /// <summary>VectorNormalize2: AOut is the normalized V (the zero vector for length 0)</summary>
    class function Normalize2(const AVector: TIdVec3; var AOut: TIdVec3): Single; static;
    /// <summary>(A + B * 2 + C) * 0.25, the point of the curve at the middle of three controls</summary>
    class function QuadraticMidpoint(const A, B, C: Single): Single; static;
    /// <summary>The square root of a Single as sqrt() of C gives it, rounded to Single</summary>
    class function SqrtSingle(const AValue: Single): Single; static;
  end;

implementation

class function TPatchVertexMath.Lerp(const A, B: TPatchVertex): TPatchVertex;
var
  LSum: Single;
  LIndex: Integer;
begin
  LSum := A.Position.X + B.Position.X;
  Result.Position.X := 0.5 * LSum;
  LSum := A.Position.Y + B.Position.Y;
  Result.Position.Y := 0.5 * LSum;
  LSum := A.Position.Z + B.Position.Z;
  Result.Position.Z := 0.5 * LSum;
  LSum := A.TexCoord.X + B.TexCoord.X;
  Result.TexCoord.X := 0.5 * LSum;
  LSum := A.TexCoord.Y + B.TexCoord.Y;
  Result.TexCoord.Y := 0.5 * LSum;
  LSum := A.Lightmap.X + B.Lightmap.X;
  Result.Lightmap.X := 0.5 * LSum;
  LSum := A.Lightmap.Y + B.Lightmap.Y;
  Result.Lightmap.Y := 0.5 * LSum;
  // The original leaves the normal of the result as it was (a fresh local: here zero)
  Result.Normal.Zero;
  for LIndex := 0 to 3 do
    Result.Color[LIndex] := Byte((Integer(A.Color[LIndex]) + Integer(B.Color[LIndex])) shr 1);
end;

class function TPatchVertexMath.Dot(const A, B: TIdVec3): Single;
var
  LX, LY, LZ: Single;
begin
  LX := A.X * B.X;
  LY := A.Y * B.Y;
  LZ := A.Z * B.Z;
  LX := LX + LY;
  LX := LX + LZ;
  Result := LX;
end;

class function TPatchVertexMath.LengthSquared(const A: TIdVec3): Single;
begin
  Result := Dot(A, A);
end;

class function TPatchVertexMath.SqrtSingle(const AValue: Single): Single;
var
  LValue: Double;
begin
  LValue := AValue;
  Result := Single(System.Sqrt(LValue));
end;

class function TPatchVertexMath.Length(const A: TIdVec3): Single;
begin
  Result := SqrtSingle(LengthSquared(A));
end;

class function TPatchVertexMath.Cross(const A, B: TIdVec3): TIdVec3;
var
  LFirst, LSecond: Single;
begin
  LFirst := A.Y * B.Z;
  LSecond := A.Z * B.Y;
  Result.X := LFirst - LSecond;
  LFirst := A.Z * B.X;
  LSecond := A.X * B.Z;
  Result.Y := LFirst - LSecond;
  LFirst := A.X * B.Y;
  LSecond := A.Y * B.X;
  Result.Z := LFirst - LSecond;
end;

class function TPatchVertexMath.Normalize(var AVector: TIdVec3): Single;
var
  LInverse: Single;
begin
  Result := Length(AVector);
  if Result <> 0 then
  begin
    LInverse := 1 / Result;
    AVector.X := AVector.X * LInverse;
    AVector.Y := AVector.Y * LInverse;
    AVector.Z := AVector.Z * LInverse;
  end;
end;

class function TPatchVertexMath.Normalize2(const AVector: TIdVec3; var AOut: TIdVec3): Single;
var
  LInverse: Single;
  LSource: TIdVec3;
begin
  LSource := AVector;
  Result := Length(LSource);
  if Result <> 0 then
  begin
    LInverse := 1 / Result;
    AOut.X := LSource.X * LInverse;
    AOut.Y := LSource.Y * LInverse;
    AOut.Z := LSource.Z * LInverse;
  end
  else
    AOut.Zero;
end;

class function TPatchVertexMath.QuadraticMidpoint(const A, B, C: Single): Single;
var
  LTwice, LSum: Single;
begin
  LTwice := B * 2;
  LSum := A + LTwice;
  LSum := LSum + C;
  Result := LSum * 0.25;
end;

end.
