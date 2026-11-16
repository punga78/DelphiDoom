{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: vertex, limits, error    }
{                                                                              }
{  Port of drawVert_t (qfiles.h) and of the limits of tr_local.h.              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>MAX_PATCH_SIZE: the largest width or height of a patch of a map file</summary>
  MAX_PATCH_SIZE = 32;
  /// <summary>MAX_GRID_SIZE: the largest width or height of a subdivided grid</summary>
  MAX_GRID_SIZE = 65;
  /// <summary>The smallest width or height of a patch (3x3 control points)</summary>
  MIN_PATCH_SIZE = 3;
  /// <summary>
  ///   The value in the LOD error table that marks a row or column that is collinear and is
  ///   removed from the grid (999 in tr_curve.c)
  /// </summary>
  PATCH_COLLINEAR_ERROR: Single = 999.0;
  /// <summary>The cvar r_subdivisions of the original: default 4 (Quake III)</summary>
  DEFAULT_PATCH_SUBDIVISIONS: Single = 4.0;

type
  /// <summary>
  ///   A vertex of a patch (drawVert_t): position, texture and lightmap coordinates, normal and
  ///   colour, 44 bytes as in the original. There was no vertex type with a lightmap and a byte
  ///   colour in the repository (the map file keeps position and texture only), so this is new;
  ///   the fields are the vectors of idLib.
  /// </summary>
  TPatchVertex = record
    Position: TIdVec3;
    TexCoord: TIdVec2;
    Lightmap: TIdVec2;
    Normal: TIdVec3;
    Color: array[0..3] of Byte;
  end;

  /// <summary>A patch or a grid that cannot be processed (size, index or point out of range)</summary>
  EPatchException = class(Exception);

resourcestring
  SPatchSizeInvalid = 'Patch size %dx%d is not valid: width and height must be odd numbers from %d to %d';
  SPatchPointsMissing = 'Patch %dx%d needs %d control points, %d given';
  SPatchCellOutOfRange = 'Control mesh cell (%d, %d) is out of range';
  SPatchInsertPositionInvalid = 'Cannot insert at %d: the position must be inside the grid (1 to %d)';

implementation

end.
