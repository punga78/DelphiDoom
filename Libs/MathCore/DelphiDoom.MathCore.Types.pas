{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the shared types and constants              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Bits of the fractional part of a fixed point number (16.16)</summary>
  FIXED_FRACBITS = 16;
  /// <summary>The number 1.0 in fixed point</summary>
  FIXED_ONE = 1 shl FIXED_FRACBITS;
  /// <summary>The biggest fixed point number</summary>
  FIXED_MAX = $7FFFFFFF;
  /// <summary>The smallest fixed point number</summary>
  FIXED_MIN = Integer($80000000);

  ANGLETOFINESHIFT = 19;
  ANGLETOFINEUNIT = 1 shl ANGLETOFINESHIFT;
  /// <summary>Angles of the fine tables (8192)</summary>
  FINEANGLES = 1 shl (32 - ANGLETOFINESHIFT);
  FINEMASK = FINEANGLES - 1;
  /// <summary>Angles of the fixed sine table (65536)</summary>
  FIXEDANGLES = FIXED_ONE;

  ANG45 = $20000000;
  ANG90 = $40000000;
  ANG180 = $80000000;
  ANG270 = $C0000000;
  ANG1 = ANG90 div 90;

  SLOPEBITS = 11;
  SLOPERANGE = 1 shl SLOPEBITS;
  SLOPEBITS_EX = 16;
  SLOPERANGE_EX = 1 shl SLOPEBITS_EX;

  /// <summary>The value of pi, as in the old m_vectors</summary>
  MATHCORE_PI = 3.14159265358979323846;

  /// <summary>Indexes of a bounding box (the old BOXTOP...BOXRIGHT)</summary>
  BOX_TOP = 0;
  BOX_BOTTOM = 1;
  BOX_LEFT = 2;
  BOX_RIGHT = 3;

resourcestring
  SDivisionByZero = 'Fixed point division by zero';
  SDivisionOverflow = 'Fixed point division overflow';
  SStackEmpty = 'The stack is empty';

type
  /// <summary>A fixed point number, 16.16 (the old fixed_t)</summary>
  TFixed = Integer;
  /// <summary>A binary angle: 2^32 is a full turn (the old angle_t)</summary>
  TAngle = Cardinal;

  /// <summary>Bounding box: TOP, BOTTOM, LEFT, RIGHT, as in the engine structures</summary>
  TBoundingBox = array[0..3] of TFixed;

  TVec2 = array[0..1] of Single;
  TVec3 = array[0..2] of Single;
  TMat3 = array[0..2, 0..2] of Single;

  /// <summary>A mistake in the arguments of the math core (division by zero, empty stack)</summary>
  EMathCoreException = class(Exception);

implementation

end.
