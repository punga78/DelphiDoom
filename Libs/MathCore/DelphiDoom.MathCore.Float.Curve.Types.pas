{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - shared types of the curves          }
{                                                                              }
{  Port of idCurve (idlib\math\Curve.h) of the Doom 3 GPL Source Code.         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Types;

{$Q-}
{$R-}
{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils;

type
  /// <summary>How a spline behaves outside the knots (idCurve_Spline::boundary_t)</summary>
  TIdCurveBoundary = (
    /// <summary>BT_FREE: the curve is extrapolated linearly from the first and last pair of knots</summary>
    Free,
    /// <summary>BT_CLAMPED: the time is clamped to the first and last knot</summary>
    Clamped,
    /// <summary>BT_CLOSED: the knots repeat, a closing time follows the last one</summary>
    Closed);

  /// <summary>Four basis function values (the <c>float bvals[4]</c> of the cubic splines)</summary>
  TIdCurveBasis4 = array[0..3] of Single;

  /// <summary>Raised when a curve is used in a way the original only checks with an assert</summary>
  EIdCurveException = class(Exception);

const
  /// <summary>1.0f / 3.0f as a float (the C++ rounds the quotient to a float)</summary>
  ID_CURVE_ONE_THIRD: Single = 1.0 / 3.0;
  /// <summary>1.0f / 6.0f as a float</summary>
  ID_CURVE_ONE_SIXTH: Single = 1.0 / 6.0;

resourcestring
  SIdCurveKnotCount = 'This curve needs exactly %d knots, it has %d';
  SIdCurveOrderRange = 'The order of a B-spline must be between 1 and 9, not %d';
  SIdCurveComponentRange = 'A scalar value has only the component 0, not %d';

implementation

end.
