{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  constants, records and the error                                            }
{                                                                              }
{  Port of cm_local.h and of the types of q_shared.h (cplane_t, trace_t) of    }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc. This unit is derived from the Quake III Arena source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions;

const
  /// <summary>MAX_SUBMODELS of cm_local.h</summary>
  Q3_MAX_SUBMODELS = 256;
  /// <summary>BOX_MODEL_HANDLE: the model of CM_TempBoxModel</summary>
  Q3_BOX_MODEL_HANDLE = 255;
  /// <summary>CAPSULE_MODEL_HANDLE: what CM_TempBoxModel returns for a capsule (see the README)</summary>
  Q3_CAPSULE_MODEL_HANDLE = 254;

  /// <summary>BOX_BRUSHES, BOX_SIDES, BOX_PLANES: the extra entries of the box hull</summary>
  Q3_BOX_BRUSHES = 1;
  Q3_BOX_SIDES = 6;
  Q3_BOX_PLANES = 12;

  /// <summary>SURFACE_CLIP_EPSILON: keep 1/8 unit away from a surface (a double in the C)</summary>
  Q3_SURFACE_CLIP_EPSILON = 0.125;

  /// <summary>PLANE_X ... PLANE_NON_AXIAL of q_shared.h</summary>
  Q3_PLANE_X = 0;
  Q3_PLANE_Y = 1;
  Q3_PLANE_Z = 2;
  Q3_PLANE_NON_AXIAL = 3;

  /// <summary>CONTENTS_SOLID, CONTENTS_BODY ... of surfaceflags.h (the ones the model itself uses)</summary>
  Q3_CONTENTS_SOLID = 1;
  Q3_CONTENTS_BODY = $2000000;

  /// <summary>MAX_POSITION_LEAFS of cm_trace.c</summary>
  Q3_MAX_POSITION_LEAFS = 1024;
  /// <summary>MAX_PATCH_VERTS of cm_load.c</summary>
  Q3_MAX_PATCH_VERTS = 1024;

type
  /// <summary>vec3_t</summary>
  TQ3Vec3 = array[0..2] of Single;
  PQ3Vec3 = ^TQ3Vec3;

  /// <summary>cplane_t: normal, distance, type (0..2 axial, 3 and over not) and the sign bits</summary>
  TQ3Plane = record
    Normal: TQ3Vec3;
    Dist: Single;
    PlaneType: Byte;
    SignBits: Byte;
  end;
  PQ3Plane = ^TQ3Plane;

  /// <summary>cNode_t: the plane is an index in the planes; a negative child is -(leaf + 1)</summary>
  TQ3Node = record
    PlaneNum: Integer;
    Children: array[0..1] of Integer;
  end;
  PQ3Node = ^TQ3Node;

  /// <summary>cLeaf_t</summary>
  TQ3Leaf = record
    Cluster: Integer;
    Area: Integer;
    FirstLeafBrush: Integer;
    NumLeafBrushes: Integer;
    FirstLeafSurface: Integer;
    NumLeafSurfaces: Integer;
  end;
  PQ3Leaf = ^TQ3Leaf;

  /// <summary>cmodel_t: the bounds (spread by one unit) and a "leaf" that holds the model's brushes</summary>
  TQ3Model = record
    Mins: TQ3Vec3;
    Maxs: TQ3Vec3;
    Leaf: TQ3Leaf;
  end;
  PQ3Model = ^TQ3Model;

  /// <summary>cbrushside_t: the plane is an index in the planes (the box hull has its own)</summary>
  TQ3BrushSide = record
    PlaneNum: Integer;
    SurfaceFlags: Integer;
    ShaderNum: Integer;
  end;
  PQ3BrushSide = ^TQ3BrushSide;

  /// <summary>cbrush_t: the sides are NumSides entries of the brush sides from FirstSide</summary>
  TQ3Brush = record
    ShaderNum: Integer;
    Contents: Integer;
    Bounds: array[0..1] of TQ3Vec3;
    NumSides: Integer;
    FirstSide: Integer;
    CheckCount: Integer;
  end;
  PQ3Brush = ^TQ3Brush;

  /// <summary>cArea_t</summary>
  TQ3Area = record
    FloodNum: Integer;
    FloodValid: Integer;
  end;
  PQ3Area = ^TQ3Area;

  /// <summary>sphere_t: the capsule of an oriented trace</summary>
  TQ3Sphere = record
    Use: Boolean;
    Radius: Single;
    HalfHeight: Single;
    Offset: TQ3Vec3;
  end;
  PQ3Sphere = ^TQ3Sphere;

  /// <summary>trace_t: what a box swept through the model returns</summary>
  TQ3Trace = record
    /// <summary>if True the plane is not valid</summary>
    AllSolid: Boolean;
    /// <summary>if True the initial point was in a solid area</summary>
    StartSolid: Boolean;
    /// <summary>time completed, 1.0 = did not hit anything</summary>
    Fraction: Single;
    EndPos: TQ3Vec3;
    Plane: TQ3Plane;
    SurfaceFlags: Integer;
    Contents: Integer;
    EntityNum: Integer;
  end;

  /// <summary>traceWork_t: the state of one trace (the C has it on the stack of CM_Trace)</summary>
  TQ3TraceWork = record
    Start: TQ3Vec3;
    EndPoint: TQ3Vec3;
    Size: array[0..1] of TQ3Vec3;
    /// <summary>[signbits][x] = either Size[0][x] or Size[1][x]</summary>
    Offsets: array[0..7] of TQ3Vec3;
    MaxOffset: Single;
    Extents: TQ3Vec3;
    Bounds: array[0..1] of TQ3Vec3;
    ModelOrigin: TQ3Vec3;
    Contents: Integer;
    IsPoint: Boolean;
    Trace: TQ3Trace;
    Sphere: TQ3Sphere;
  end;
  PQ3TraceWork = ^TQ3TraceWork;

  /// <summary>
  ///   cPatch_t: a patch surface of the BSP. The grid is kept (Width x Height control points);
  ///   the collision geometry of the original (patchCollide_t) is a separate object, see
  ///   IQ3PatchCollide: when there is none, the patch does not collide.
  /// </summary>
  TQ3Patch = record
    /// <summary>False for a surface that is not a patch (the C has a NULL pointer)</summary>
    Present: Boolean;
    CheckCount: Integer;
    SurfaceFlags: Integer;
    Contents: Integer;
    Width: Integer;
    Height: Integer;
    Points: TArray<TQ3Vec3>;
  end;
  PQ3Patch = ^TQ3Patch;

  /// <summary>
  ///   An error that the original reports with Com_Error( ERR_DROP, ... ): a bad handle, a map
  ///   that cannot be used, an index outside a lump. The messages of the original are kept.
  /// </summary>
  EQ3CollisionException = class(EIdLibException);

implementation

end.
