{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - constants and exceptions                     }
{                                                                              }
{  Port of the constants of idlib (Plane.h, Lib.h) of Doom 3 GPL Source Code.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore available  }
{  under the GNU General Public License, version 3 or (at your option) any     }
{  later version, with the additional terms of the Doom 3 Source Code License  }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Result of a side test: in front of the plane (idlib PLANESIDE_FRONT)</summary>
  PLANESIDE_FRONT = 0;
  PLANESIDE_BACK = 1;
  PLANESIDE_ON = 2;
  PLANESIDE_CROSS = 3;

  /// <summary>Plane types (idlib PLANETYPE_*): all types below PLANETYPE_TRUEAXIAL are axial</summary>
  PLANETYPE_X = 0;
  PLANETYPE_Y = 1;
  PLANETYPE_Z = 2;
  PLANETYPE_NEGX = 3;
  PLANETYPE_NEGY = 4;
  PLANETYPE_NEGZ = 5;
  PLANETYPE_TRUEAXIAL = 6;
  PLANETYPE_ZEROX = 6;
  PLANETYPE_ZEROY = 7;
  PLANETYPE_ZEROZ = 8;
  PLANETYPE_NONAXIAL = 9;

  /// <summary>Default epsilon of the side tests (idlib ON_EPSILON)</summary>
  ON_EPSILON: Single = 0.1;
  /// <summary>Distance below which a degenerate plane is snapped (idlib DEGENERATE_DIST_EPSILON)</summary>
  DEGENERATE_DIST_EPSILON: Single = 1e-4;
  /// <summary>The value idMath::INFINITY: a big number, not a real infinity</summary>
  GEO_INFINITY: Single = 1e30;

  MAX_WORLD_COORD = 128 * 1024;
  MIN_WORLD_COORD = -128 * 1024;
  MAX_WORLD_SIZE = MAX_WORLD_COORD - MIN_WORLD_COORD;

type
  /// <summary>Base of the errors of the geometry library</summary>
  EGeometryException = class(Exception);

implementation

end.
