{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: constants,       }
{  records of the file and the error                                           }
{                                                                              }
{  Port of the BSP part of qfiles.h (id Tech 3). Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions;

const
  /// <summary>BSP_IDENT: "IBSP" as a little endian integer</summary>
  BSP_IDENT = $50534249;
  /// <summary>BSP_VERSION</summary>
  BSP_VERSION = 46;
  /// <summary>HEADER_LUMPS</summary>
  HEADER_LUMPS = 17;
  /// <summary>MAX_QPATH: the size of the shader names</summary>
  BSP_MAX_QPATH = 64;
  /// <summary>MAX_SUBMODELS of cm_local.h: the collision model refuses more models</summary>
  BSP_MAX_SUBMODELS = 256;
  /// <summary>LIGHTMAP_WIDTH and LIGHTMAP_HEIGHT; a lightmap is 128 x 128 RGB</summary>
  BSP_LIGHTMAP_BYTES = 128 * 128 * 3;
  /// <summary>SURF_NODRAW of surfaceflags.h: the surface is not drawn (a patch is skipped)</summary>
  SURF_NODRAW = $80;

  LUMP_ENTITIES = 0;
  LUMP_SHADERS = 1;
  LUMP_PLANES = 2;
  LUMP_NODES = 3;
  LUMP_LEAFS = 4;
  LUMP_LEAFSURFACES = 5;
  LUMP_LEAFBRUSHES = 6;
  LUMP_MODELS = 7;
  LUMP_BRUSHES = 8;
  LUMP_BRUSHSIDES = 9;
  LUMP_DRAWVERTS = 10;
  LUMP_DRAWINDEXES = 11;
  LUMP_FOGS = 12;
  LUMP_SURFACES = 13;
  LUMP_LIGHTMAPS = 14;
  LUMP_LIGHTGRID = 15;
  LUMP_VISIBILITY = 16;

  /// <summary>mapSurfaceType_t</summary>
  MST_BAD = 0;
  MST_PLANAR = 1;
  MST_PATCH = 2;
  MST_TRIANGLE_SOUP = 3;
  MST_FLARE = 4;

type
  /// <summary>lump_t: where a lump is in the file</summary>
  TBspLump = packed record
    FileOfs: Integer;
    FileLen: Integer;
  end;

  /// <summary>dheader_t: 144 bytes</summary>
  TBspHeader = packed record
    Ident: Integer;
    Version: Integer;
    Lumps: array[0..HEADER_LUMPS - 1] of TBspLump;
  end;

  /// <summary>dmodel_t: 40 bytes</summary>
  TBspModel = packed record
    Mins: array[0..2] of Single;
    Maxs: array[0..2] of Single;
    FirstSurface: Integer;
    NumSurfaces: Integer;
    FirstBrush: Integer;
    NumBrushes: Integer;
  end;

  /// <summary>dshader_t: 72 bytes</summary>
  TBspShader = packed record
    Shader: array[0..BSP_MAX_QPATH - 1] of AnsiChar;
    SurfaceFlags: Integer;
    ContentFlags: Integer;
  end;

  /// <summary>dplane_t: 16 bytes</summary>
  TBspPlane = packed record
    Normal: array[0..2] of Single;
    Dist: Single;
  end;

  /// <summary>dnode_t: 36 bytes; a negative child is -(leaf + 1)</summary>
  TBspNode = packed record
    PlaneNum: Integer;
    Children: array[0..1] of Integer;
    Mins: array[0..2] of Integer;
    Maxs: array[0..2] of Integer;
  end;

  /// <summary>dleaf_t: 48 bytes</summary>
  TBspLeaf = packed record
    Cluster: Integer;
    Area: Integer;
    Mins: array[0..2] of Integer;
    Maxs: array[0..2] of Integer;
    FirstLeafSurface: Integer;
    NumLeafSurfaces: Integer;
    FirstLeafBrush: Integer;
    NumLeafBrushes: Integer;
  end;

  /// <summary>dbrushside_t: 8 bytes</summary>
  TBspBrushSide = packed record
    PlaneNum: Integer;
    ShaderNum: Integer;
  end;

  /// <summary>dbrush_t: 12 bytes</summary>
  TBspBrush = packed record
    FirstSide: Integer;
    NumSides: Integer;
    ShaderNum: Integer;
  end;

  /// <summary>dfog_t: 72 bytes</summary>
  TBspFog = packed record
    Shader: array[0..BSP_MAX_QPATH - 1] of AnsiChar;
    BrushNum: Integer;
    VisibleSide: Integer;
  end;

  /// <summary>drawVert_t: 44 bytes</summary>
  TBspDrawVert = packed record
    Xyz: array[0..2] of Single;
    St: array[0..1] of Single;
    Lightmap: array[0..1] of Single;
    Normal: array[0..2] of Single;
    Color: array[0..3] of Byte;
  end;

  /// <summary>dsurface_t: 104 bytes. For a patch LightmapVecs[0] and [1] are the LOD bounds</summary>
  TBspSurface = packed record
    ShaderNum: Integer;
    FogNum: Integer;
    SurfaceType: Integer;
    FirstVert: Integer;
    NumVerts: Integer;
    FirstIndex: Integer;
    NumIndexes: Integer;
    LightmapNum: Integer;
    LightmapX: Integer;
    LightmapY: Integer;
    LightmapWidth: Integer;
    LightmapHeight: Integer;
    LightmapOrigin: array[0..2] of Single;
    LightmapVecs: array[0..2, 0..2] of Single;
    PatchWidth: Integer;
    PatchHeight: Integer;
  end;

  /// <summary>
  ///   A BSP file that cannot be read (header, lump out of the file, size that is not a
  ///   multiple of the record, no planes...) or a surface that cannot be turned into a grid.
  ///   Where the original stops with ERR_DROP the message is the one of the original.
  /// </summary>
  EBspFileException = class(EIdLibException);

implementation

end.
