{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the vector operations of q_shared.h and q_math.c  }
{                                                                              }
{  Port of DotProduct, VectorSubtract, CrossProduct, VectorLength and          }
{  VectorNormalize. Based on the Quake III Arena GPL Source Code (id Software).}
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.VectorMath;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   The operations of the original on vec3_t, each one rounded to a float on its own: the
  ///   C code is compiled for SSE, where every operation gives a float, while the x87 of the
  ///   32 bit compiler would keep the intermediate results in extended precision if a whole
  ///   expression were written in one statement. Same reason why TVectorMath of MathCore
  ///   (made to give the bits of the old Win32 code) is not used.
  /// </summary>
  TAasVectorMath = class
  public
    class function Dot(const A, B: TVec3): Single; static;
    class procedure Subtract(const A, B: TVec3; var AOut: TVec3); static;
    /// <summary>CrossProduct: AOut must not be A or B</summary>
    class procedure Cross(const A, B: TVec3; var AOut: TVec3); static;
    /// <summary>VectorLength: the square root is taken in double precision</summary>
    class function Length(const A: TVec3): Single; static;
    /// <summary>VectorNormalize: returns the length, a vector of length 0 is left as it is</summary>
    class function Normalize(var A: TVec3): Single; static;
    /// <summary>VectorMA with a double scale (the macro receives a literal such as -0.125): AOut = A + B * AScale</summary>
    class procedure MultiplyAdd(const A, B: TVec3; const AScale: Double; var AOut: TVec3); static;
  end;

implementation

uses
  System.Math;

{ TAasVectorMath }

class function TAasVectorMath.Dot(const A, B: TVec3): Single;
var
  LProduct0, LProduct1, LProduct2: Single;
begin
  LProduct0 := A[0] * B[0];
  LProduct1 := A[1] * B[1];
  LProduct0 := LProduct0 + LProduct1;
  LProduct2 := A[2] * B[2];
  Result := LProduct0 + LProduct2;
end;

class procedure TAasVectorMath.Subtract(const A, B: TVec3; var AOut: TVec3);
begin
  AOut[0] := A[0] - B[0];
  AOut[1] := A[1] - B[1];
  AOut[2] := A[2] - B[2];
end;

class procedure TAasVectorMath.Cross(const A, B: TVec3; var AOut: TVec3);
var
  LLeft, LRight: Single;
begin
  LLeft := A[1] * B[2];
  LRight := A[2] * B[1];
  AOut[0] := LLeft - LRight;
  LLeft := A[2] * B[0];
  LRight := A[0] * B[2];
  AOut[1] := LLeft - LRight;
  LLeft := A[0] * B[1];
  LRight := A[1] * B[0];
  AOut[2] := LLeft - LRight;
end;

class function TAasVectorMath.Length(const A: TVec3): Single;
var
  LSum: Single;
  LRoot: Double;
begin
  LSum := Dot(A, A);
  LRoot := Sqrt(Double(LSum));
  Result := LRoot;
end;

class function TAasVectorMath.Normalize(var A: TVec3): Single;
var
  LSum, LInverse: Single;
  LRoot: Double;
begin
  LSum := Dot(A, A);
  LRoot := Sqrt(Double(LSum));
  Result := LRoot;
  if Result <> 0 then
  begin
    LInverse := 1 / Result;
    A[0] := A[0] * LInverse;
    A[1] := A[1] * LInverse;
    A[2] := A[2] * LInverse;
  end;
end;

class procedure TAasVectorMath.MultiplyAdd(const A, B: TVec3; const AScale: Double; var AOut: TVec3);
var
  LProduct, LSum: Double;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    LProduct := B[LIndex] * AScale;
    LSum := A[LIndex] + LProduct;
    AOut[LIndex] := LSum;
  end;
end;

end.
