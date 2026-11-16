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

resourcestring
  SGlMathInvalidRangeIndex = 'The range %d of the clipper does not exist';

type
  /// <summary>A binary angle: 2^32 is a full turn (the old angle_t)</summary>
  TGlAngle = Cardinal;

  /// <summary>A mistake in the arguments of the OpenGL math library</summary>
  EGlMathException = class(Exception);

implementation

end.
