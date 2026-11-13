{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - constants, types and the error of .proc      }
{                                                                              }
{  Port of the constants of RenderWorld.h and the vertex of the .proc model    }
{  (RenderWorld_load.cpp), Doom 3 GPL Source Code.                             }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Types;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Text.Types, DelphiDoom.MapFile.Types;

const
  /// <summary>The first token of a .proc file (PROC_FILE_ID)</summary>
  PROC_FILE_ID = 'mapProcFile003';
  /// <summary>The extension of the file (PROC_FILE_EXT)</summary>
  PROC_FILE_EXT = 'proc';
  /// <summary>The flags of the lexer of idRenderWorldLocal::InitFromMap</summary>
  PROC_LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NODOLLARPRECOMPILE;
  /// <summary>
  ///   Upper bound of any count of the file (surfaces, vertices, indexes, portals, points,
  ///   nodes). The original allocates what the file says; a hostile file would exhaust the memory
  /// </summary>
  MAX_PROC_ELEMENTS = 1 shl 22;
  /// <summary>Vertices written on a line by the compiler (dmap, WriteUTriangles)</summary>
  PROC_VERTICES_PER_LINE = 3;
  /// <summary>Vertices of a shadow model written on a line (dmap, WriteShadowTriangles)</summary>
  PROC_SHADOW_VERTICES_PER_LINE = 5;
  /// <summary>Indexes written on a line</summary>
  PROC_INDEXES_PER_LINE = 18;

type
  /// <summary>
  ///   The part of idDrawVert that a .proc surface holds: position, texture coordinates and
  ///   normal (tangents and colour are computed later by the renderer)
  /// </summary>
  TProcVertex = record
    Position: TGeoVec3;
    S: Single;
    T: Single;
    Normal: TGeoVec3;
  end;

  /// <summary>
  ///   A node of the BSP tree of the areas (areaNode_t): the plane as the file has it (a, b, c, d
  ///   with a point in front when a*x+b*y+c*z+d is positive) and the two children. A child of 0
  ///   is an opaque solid area; a negative child is an area, number -1-child; a positive one is
  ///   the index of another node
  /// </summary>
  TProcNode = record
    Plane: TGeoPlane;
    PositiveChild: Integer;
    NegativeChild: Integer;
  end;

  /// <summary>
  ///   A .proc file that cannot be read or written; the message and the line are those of
  ///   EMapFileException
  /// </summary>
  EProcFileException = class(EMapFileException);

implementation

end.
