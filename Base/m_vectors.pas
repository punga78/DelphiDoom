//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_vectors;

interface

uses
  d_delphi;

type
  vec_t = float;
  Pvec_t = ^vec_t;

  vec2_t = array[0..1] of vec_t;
  Pvec2_t = ^vec2_t;

  vec3_t = array[0..2] of vec_t;
  Pvec3_t = ^vec3_t;

  mat3_t = array[0..2, 0..2] of float;
  Pmat3_t = ^mat3_t;

  vec5_t = array[0..4] of vec_t;
  Pvec5_t = ^vec5_t;

const
  M_PI = 3.14159265358979323846;  // matches value in gcc v2 math.h

//==============================================================================
//
// IS_NAN
//
//==============================================================================
function IS_NAN(x: float): boolean;

//==============================================================================
//
// DEG2RAD
//
//==============================================================================
function DEG2RAD(a: float): float;

//==============================================================================
//
// ProjectPointOnPlane
//
//==============================================================================
procedure ProjectPointOnPlane(dst: Pvec3_t; p: Pvec3_t; normal: Pvec3_t);

//==============================================================================
//
// PerpendicularVector
//
//==============================================================================
procedure PerpendicularVector(dst: Pvec3_t; src: Pvec3_t);

//==============================================================================
//
// RotatePointAroundVector
//
//==============================================================================
procedure RotatePointAroundVector(dst: Pvec3_t; dir: Pvec3_t;
  point: Pvec3_t; degrees: float);

//==============================================================================
//
// VectorCompare
//
//==============================================================================
function VectorCompare(v1, v2: Pvec3_t): integer;

//==============================================================================
//
// VectorMA
//
//==============================================================================
procedure VectorMA(veca: Pvec3_t; scale: float; vecb: Pvec3_t; vecc: Pvec3_t);

//==============================================================================
//
// DotProduct
//
//==============================================================================
function DotProduct(v1, v2: Pvec3_t): vec_t;

//==============================================================================
//
// VectorSubtract
//
//==============================================================================
procedure VectorSubtract(veca, vecb: Pvec3_t; _out: Pvec3_t);

//==============================================================================
//
// VectorAdd
//
//==============================================================================
procedure VectorAdd(veca, vecb: Pvec3_t; _out: Pvec3_t);

//==============================================================================
//
// VectorCopy
//
//==============================================================================
procedure VectorCopy(_in: Pvec3_t; _out: Pvec3_t);

//==============================================================================
//
// CrossProduct
//
//==============================================================================
procedure CrossProduct(v1, v2: Pvec3_t; cross: Pvec3_t);

//==============================================================================
//
// VectorLength
//
//==============================================================================
function VectorLength(v: Pvec3_t): vec_t;

//==============================================================================
//
// VectorNormalize
//
//==============================================================================
function VectorNormalize(v: Pvec3_t): float;

//==============================================================================
//
// VectorInverse
//
//==============================================================================
procedure VectorInverse(v: Pvec3_t);

//==============================================================================
//
// VectorScale
//
//==============================================================================
procedure VectorScale(_in: Pvec3_t; const scale: vec_t; _out: Pvec3_t);

//==============================================================================
//
// ConcatRotations
//
//==============================================================================
procedure ConcatRotations(in1, in2: Pmat3_t; _out: Pmat3_t);

//==============================================================================
//
// DotProduct2
//
//==============================================================================
function DotProduct2(v1, v2: vec2_t): float;

//==============================================================================
//
// VectorSubtract2
//
//==============================================================================
function VectorSubtract2(veca, vecb: vec2_t): vec2_t;

//==============================================================================
//
// VectorAdd2
//
//==============================================================================
function VectorAdd2(veca, vecb: vec2_t): vec2_t;

//==============================================================================
//
// VectorScale2
//
//==============================================================================
function VectorScale2(veca: vec2_t; scale: float): vec2_t;

//==============================================================================
//
// VectorLength2
//
//==============================================================================
function VectorLength2(v: vec2_t): float;

//==============================================================================
//
// VectorNormalize2
//
//==============================================================================
function VectorNormalize2(var v: vec2_t): float;

//==============================================================================
//
// CalculateReflect2
//
//==============================================================================
procedure CalculateReflect2(const d, wall: vec2_t; var reflect: vec2_t);

implementation

uses
  DelphiDoom.MathCore.Types,
  DelphiDoom.MathCore.VectorMath;

// The calculations are the ones of TVectorMath (Libs\MathCore); these are the
// functions of the engine, with the pointers that its callers have.

//==============================================================================
//
// IS_NAN
//
//==============================================================================
function IS_NAN(x: float): boolean;
begin
  result := TVectorMath.IsNaN(x);
end;

//==============================================================================
//
// DEG2RAD
//
//==============================================================================
function DEG2RAD(a: float): float;
begin
  result := TVectorMath.DegreesToRadians(a);
end;

//==============================================================================
//
// ProjectPointOnPlane
//
//==============================================================================
procedure ProjectPointOnPlane(dst: Pvec3_t; p: Pvec3_t; normal: Pvec3_t);
begin
  TVectorMath.ProjectPointOnPlane(TVec3(dst^), TVec3(p^), TVec3(normal^));
end;

//==============================================================================
//
// PerpendicularVector
// assumes "src" is normalized
//
//==============================================================================
procedure PerpendicularVector(dst: Pvec3_t; src: Pvec3_t);
begin
  TVectorMath.PerpendicularVector(TVec3(dst^), TVec3(src^));
end;

//==============================================================================
//
// RotatePointAroundVector
//
//==============================================================================
procedure RotatePointAroundVector(dst: Pvec3_t; dir: Pvec3_t;
  point: Pvec3_t; degrees: float);
begin
  TVectorMath.RotatePointAroundVector(TVec3(dst^), TVec3(dir^), TVec3(point^), degrees);
end;

//==============================================================================
//
// VectorCompare
//
//==============================================================================
function VectorCompare(v1, v2: Pvec3_t): integer;
begin
  if TVectorMath.Compare3(TVec3(v1^), TVec3(v2^)) then
    result := 1
  else
    result := 0;
end;

//==============================================================================
//
// VectorMA
//
//==============================================================================
procedure VectorMA(veca: Pvec3_t; scale: float; vecb: Pvec3_t; vecc: Pvec3_t);
begin
  TVectorMath.MultiplyAdd3(TVec3(veca^), scale, TVec3(vecb^), TVec3(vecc^));
end;

//==============================================================================
//
// DotProduct
//
//==============================================================================
function DotProduct(v1, v2: Pvec3_t): vec_t;
begin
  result := TVectorMath.Dot3(TVec3(v1^), TVec3(v2^));
end;

//==============================================================================
//
// VectorSubtract
//
//==============================================================================
procedure VectorSubtract(veca, vecb: Pvec3_t; _out: Pvec3_t);
begin
  TVectorMath.Subtract3(TVec3(veca^), TVec3(vecb^), TVec3(_out^));
end;

//==============================================================================
//
// VectorAdd
//
//==============================================================================
procedure VectorAdd(veca, vecb: Pvec3_t; _out: Pvec3_t);
begin
  TVectorMath.Add3(TVec3(veca^), TVec3(vecb^), TVec3(_out^));
end;

//==============================================================================
//
// VectorCopy
//
//==============================================================================
procedure VectorCopy(_in: Pvec3_t; _out: Pvec3_t);
begin
  _out[0] := _in[0];
  _out[1] := _in[1];
  _out[2] := _in[2];
end;

//==============================================================================
//
// CrossProduct
//
//==============================================================================
procedure CrossProduct(v1, v2: Pvec3_t; cross: Pvec3_t);
begin
  TVectorMath.Cross3(TVec3(v1^), TVec3(v2^), TVec3(cross^));
end;

//==============================================================================
//
// VectorLength
//
//==============================================================================
function VectorLength(v: Pvec3_t): vec_t;
begin
  result := TVectorMath.Length3(TVec3(v^));
end;

//==============================================================================
//
// VectorNormalize
//
//==============================================================================
function VectorNormalize(v: Pvec3_t): float;
begin
  result := TVectorMath.Normalize3(TVec3(v^));
end;

//==============================================================================
//
// VectorInverse
//
//==============================================================================
procedure VectorInverse(v: Pvec3_t);
begin
  TVectorMath.Inverse3(TVec3(v^));
end;

//==============================================================================
//
// VectorScale
//
//==============================================================================
procedure VectorScale(_in: Pvec3_t; const scale: vec_t; _out: Pvec3_t);
begin
  TVectorMath.Scale3(TVec3(_in^), scale, TVec3(_out^));
end;

//==============================================================================
//
// ConcatRotations
//
//==============================================================================
procedure ConcatRotations(in1, in2: Pmat3_t; _out: Pmat3_t);
begin
  TVectorMath.ConcatRotations(TMat3(in1^), TMat3(in2^), TMat3(_out^));
end;

//==============================================================================
//
// DotProduct2
//
//==============================================================================
function DotProduct2(v1, v2: vec2_t): float;
begin
  result := TVectorMath.Dot2(TVec2(v1), TVec2(v2));
end;

//==============================================================================
//
// VectorSubtract2
//
//==============================================================================
function VectorSubtract2(veca, vecb: vec2_t): vec2_t;
begin
  TVec2(result) := TVectorMath.Subtract2(TVec2(veca), TVec2(vecb));
end;

//==============================================================================
//
// VectorAdd2
//
//==============================================================================
function VectorAdd2(veca, vecb: vec2_t): vec2_t;
begin
  TVec2(result) := TVectorMath.Add2(TVec2(veca), TVec2(vecb));
end;

//==============================================================================
//
// VectorScale2
//
//==============================================================================
function VectorScale2(veca: vec2_t; scale: float): vec2_t;
begin
  TVec2(result) := TVectorMath.Scale2(TVec2(veca), scale);
end;

//==============================================================================
//
// VectorLength2
//
//==============================================================================
function VectorLength2(v: vec2_t): float;
begin
  result := TVectorMath.Length2(TVec2(v));
end;

//==============================================================================
//
// VectorNormalize2
//
//==============================================================================
function VectorNormalize2(var v: vec2_t): float;
begin
  result := TVectorMath.Normalize2(TVec2(v));
end;

//==============================================================================
//
// CalculateReflect2
//
//==============================================================================
procedure CalculateReflect2(const d, wall: vec2_t; var reflect: vec2_t);
begin
  TVectorMath.CalculateReflect2(TVec2(d), TVec2(wall), TVec2(reflect));
end;

end.
