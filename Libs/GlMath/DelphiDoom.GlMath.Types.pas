{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL math library - the shared types and constants            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlMath.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The biggest binary angle (the old ANGLE_MAX): 2^32 - 1</summary>
  GLMATH_ANGLE_MAX = $FFFFFFFF;
  /// <summary>One degree as a binary angle (the old ANG1)</summary>
  GLMATH_ANG1 = $40000000 div 90;
  /// <summary>Half a turn as a binary angle (the old ANG180)</summary>
  GLMATH_ANG180 = $80000000;
  /// <summary>The number of planes of a view frustum</summary>
  GLMATH_FRUSTUM_SIDES = 6;

resourcestring
  SGlMathInvalidFrustumIndex = 'The index %d of a plane does not exist (0..3)';
  SGlMathInvalidRangeIndex = 'The range %d of the clipper does not exist';

type
  /// <summary>A binary angle: 2^32 is a full turn (the old angle_t)</summary>
  TGlAngle = Cardinal;

  /// <summary>A 4x4 matrix of OpenGL (16 values in column order, as glGetFloatv gives it)</summary>
  TGlMatrix4 = array[0..15] of Single;

  /// <summary>The sides of a frustum, in the order of the old gl_frustum</summary>
  TGlFrustumSide = (fsRight, fsLeft, fsBottom, fsTop, fsBack, fsFront);

  /// <summary>A mistake in the arguments of the OpenGL math library</summary>
  EGlMathException = class(Exception);

implementation

end.
