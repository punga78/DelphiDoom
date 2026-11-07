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

  vec2_t = array[0..1] of vec_t;

  vec3_t = array[0..2] of vec_t;
  Pvec3_t = ^vec3_t;

  mat3_t = array[0..2, 0..2] of float;
  Pmat3_t = ^mat3_t;

  vec5_t = array[0..4] of vec_t;

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
// VectorAdd
//
//==============================================================================
procedure VectorAdd(veca, vecb: Pvec3_t; _out: Pvec3_t);

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
// ConcatRotations
//
//==============================================================================
procedure ConcatRotations(in1, in2: Pmat3_t; _out: Pmat3_t);

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
// VectorAdd
//
//==============================================================================
procedure VectorAdd(veca, vecb: Pvec3_t; _out: Pvec3_t);
begin
  TVectorMath.Add3(TVec3(veca^), TVec3(vecb^), TVec3(_out^));
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
// ConcatRotations
//
//==============================================================================
procedure ConcatRotations(in1, in2: Pmat3_t; _out: Pmat3_t);
begin
  TVectorMath.ConcatRotations(TMat3(in1^), TMat3(in2^), TMat3(_out^));
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
