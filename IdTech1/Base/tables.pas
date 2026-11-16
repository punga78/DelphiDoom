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
// DESCRIPTION:
//  Lookup tables.
//  Do not try to look them up :-).
//  In the order of appearance:
//
//  int finetangent[4096]  - Tangens LUT.
//   Should work with BAM fairly well (12 of 16bit,
//      effectively, by shifting).
//
//  int finesine[10240]    - Sine lookup.
//   Guess what, serves as cosine, too.
//   Remarkable thing is, how to use BAMs with this?
//
//  int tantoangle[2049]  - ArcTan LUT,
//    maps tan(angle) to angle fast. Gotta search.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit tables;

interface

uses
  m_fixed,
  DelphiDoom.MathCore.TableFineSine,
  DelphiDoom.MathCore.TableFineTangent,
  DelphiDoom.MathCore.TableTanToAngle,
  DelphiDoom.MathCore.TableTanToAngleEx,
  DelphiDoom.MathCore.TableFixedSine;

const
  D_PI = 3.141592657;
  ANGLE_T_TO_RAD = 2 * D_PI / $100000000;

const
// 0x100000000 to 0x2000
  ANGLETOFINESHIFT = 19;
  ANGLETOFINEUNIT = 1 shl ANGLETOFINESHIFT;

  FINEANGLES = 1 shl (32 - ANGLETOFINESHIFT);
  FINEMASK = FINEANGLES - 1;

  DIR256ANGLES = 256;
  DIR256TOANGLEUNIT = ANGLETOFINEUNIT div DIR256ANGLES * FINEANGLES;
  DIR256TOANGLESHIFT = ANGLETOFINESHIFT - 8;

// Binary Angle Measument, BAM.

type
  angle_t = LongWord;
  Pangle_t = ^angle_t;
  angle_tArray = array[0..$FFFFFF] of angle_t;
  Pangle_tArray = ^angle_tArray;

const
  ANG45  = $20000000;
  ANG60  = $2AAAAAAB;
  ANG90  = $40000000;
  ANG120 = $55555555;
  ANG180 = $80000000;
  ANG240 = $AAAAAAAB;
  ANG270 = $C0000000;
  ANG300 = $D5555556;
  ANG315 = $E0000000;

const
  ANG5 = ANG90 div 18;
  ANG355 = ANG270 +  ANG5 * 17; // add by JVAL

const
  SLOPEBITS = 11;
  SLOPERANGE = 1 shl SLOPEBITS;
  DBITS = FRACBITS - SLOPEBITS;
  DRANGE = 1 shl DBITS;
  SLOPEBITS_EX = 16;
  SLOPERANGE_EX = 1 shl SLOPEBITS_EX;

const
  ANG1 = ANG90 div 90;
  ANGLE_MAX = $FFFFFFFF;
  ANGLEMAX_DIV_256 = ANGLE_MAX div 256;

var
// Effective size is 10240.
  finesine: Pfixed_tArray = @FINE_SINE_TABLE;

// Re-use data, is just PI/2 pahse shift.
  finecosine: Pfixed_tArray;

// Effective size is 4096.
  finetangent: Pfixed_tArray = @FINE_TANGENT_TABLE;

// Effective size is 2049;
// The +1 size is to handle the case when x==y
//  without additional checking.
  tantoangle: Pangle_tArray = @TAN_TO_ANGLE_TABLE;

const
  tantoangle_ex: Pangle_tArray = @TAN_TO_ANGLE_EX_TABLE;

//==============================================================================
//
// SlopeDiv
//
//==============================================================================
function SlopeDiv(const num: integer; const den: integer): LongWord;

//==============================================================================
//
// SlopeDivEx
//
//==============================================================================
function SlopeDivEx(const num: integer; const den: integer): LongWord;

const
  FIXEDANGLES = FRACUNIT;

var
// round($FFFF * sin((0.5 + i) / $10000 * 2 * pi))
  fixedsine: Pfixed_tArray = @FIXED_SINE_TABLE;

  // Re-use data, is just PI/2 pahse shift.
  fixedcosine: Pfixed_tArray;

//==============================================================================
//
// DegToSlope
//
//==============================================================================
function DegToSlope(a: fixed_t): fixed_t;

//==============================================================================
//
// FixedToAngle
//
//==============================================================================
function FixedToAngle(a: fixed_t): angle_t;

//==============================================================================
//
// AngleToFixed
//
//==============================================================================
function AngleToFixed(a: angle_t): fixed_t;

implementation

uses
  d_delphi;

//==============================================================================
//
// SlopeDiv
//
//==============================================================================
function SlopeDiv(const num: integer; const den: integer): LongWord;
begin
  if den < 512 then
    result := SLOPERANGE
  else
  begin
    result := (num * 8) div _SHR8(den);
    if result >= SLOPERANGE then
      result := SLOPERANGE;
  end;
end;

//==============================================================================
//
// SlopeDivEx
//
//==============================================================================
function SlopeDivEx(const num: integer; const den: integer): LongWord;
begin
  if den < 32 then
    result := SLOPERANGE_EX
  else
  begin
    result := Round(num / (den / FRACUNIT));
    if result >= SLOPERANGE_EX then
      result := SLOPERANGE_EX;
  end;
end;

//==============================================================================
// FixedToAngle
//
// mbf21: More utility functions, courtesy of Quasar (James Haley).
// These are straight from Eternity so demos stay in sync.
//
//==============================================================================
function FixedToAngle(a: fixed_t): angle_t;
begin
  result := trunc((a / FRACUNIT) * ANG1);
end;

//==============================================================================
//
// AngleToFixed
//
//==============================================================================
function AngleToFixed(a: angle_t): fixed_t;
begin
  result := trunc((a / ANG1) * FRACUNIT);
end;

//==============================================================================
// AngleToSlope
//
// [XA] Clamped angle->slope, for convenience
//
//==============================================================================
function AngleToSlope(a: integer): fixed_t;
begin
  if a > ANG90 then
    result := finetangent[0]
  else if -a > ANG90 then
    result := finetangent[FINEANGLES div 2 - 1]
  else
    result := finetangent[(ANG90 - a) div ANGLETOFINEUNIT];
end;

//==============================================================================
// DegToSlope
//
// [XA] Ditto, using fixed-point-degrees input
//
//==============================================================================
function DegToSlope(a: fixed_t): fixed_t;
var
  i: integer;
begin
  if a >= 0 then
    result := AngleToSlope(FixedToAngle(a))
  else
  begin
    i := FixedToAngle(-a);
    result := AngleToSlope(-i);
  end;
end;

end.
