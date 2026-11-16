{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - what the renderer builds from a BSP          }
{                                                                              }
{  Based on mnode_t and world_t (tr_local.h) of the Quake III Arena GPL Source }
{  Code (id Software), GPL v2 or later.                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.RenderTypes;

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Bsp.ColorShift, DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   A node or a leaf of the tree of the renderer (mnode_t), in the array of the tree: the
  ///   decision nodes first, then the leafs. Pointers are indexes into that array (-1 for none)
  /// </summary>
  TBspRenderNode = record
    /// <summary>True for a decision node (CONTENTS_NODE = -1 in the original), False for a leaf</summary>
    IsNode: Boolean;
    /// <summary>The bounds for culling, from the integers of the file</summary>
    Mins: TGeoVec3;
    Maxs: TGeoVec3;
    /// <summary>The node that has this one as a child; -1 for the root</summary>
    Parent: Integer;
    // node specific
    /// <summary>Index into the plane lump</summary>
    PlaneNum: Integer;
    /// <summary>Indexes into the array of the tree: the front and the back</summary>
    Children: array[0..1] of Integer;
    // leaf specific
    Cluster: Integer;
    Area: Integer;
    /// <summary>Index into the leaf surface lump (marksurfaces)</summary>
    FirstMarkSurface: Integer;
    NumMarkSurfaces: Integer;
  end;

  /// <summary>R_LoadNodesAndLeafs: the tree as the renderer chains it</summary>
  TBspRenderTree = record
    /// <summary>The numDecisionNodes nodes, then the leafs; the root is index 0</summary>
    Nodes: TArray<TBspRenderNode>;
    NumDecisionNodes: Integer;
    /// <summary>The highest cluster of the leafs plus one (0 if no leaf has a cluster)</summary>
    NumClusters: Integer;
  end;

  /// <summary>
  ///   The light grid of the world (lightGrid* of world_t): where it starts, the size of a cell,
  ///   how many cells in each direction and the 8 bytes of each cell (ambient colour, directed
  ///   colour, two direction bytes) with the overbright shift applied. <c>Data</c> is empty when
  ///   the lump did not have the size the box of the world needs
  /// </summary>
  TBspLightGrid = record
    Origin: TGeoVec3;
    Size: TGeoVec3;
    InverseSize: TGeoVec3;
    Bounds: array[0..2] of Integer;
    Data: TBytes;
  end;

  /// <summary>
  ///   A point of a planar face (the eight floats of srfSurfaceFace_t.points): position, texture
  ///   and lightmap coordinates, and the colour with the overbright shift applied
  /// </summary>
  TBspFacePoint = record
    Xyz: array[0..2] of Single;
    St: array[0..1] of Single;
    Lightmap: array[0..1] of Single;
    Color: TBspColor;
  end;

  /// <summary>ParseFace: srfSurfaceFace_t of a planar surface (MST_PLANAR) and its msurface_t fields</summary>
  TBspFaceSurface = record
    /// <summary>msurface_t.fogIndex: the fog number of the file plus one</summary>
    FogIndex: Integer;
    /// <summary>The shader number of the file</summary>
    ShaderNum: Integer;
    /// <summary>True when the renderer must use tr.defaultShader (MAX_FACE_POINTS exceeded)</summary>
    UsesDefaultShader: Boolean;
    /// <summary>At most MAX_FACE_POINTS (64) points</summary>
    Points: TArray<TBspFacePoint>;
    Indexes: TArray<Integer>;
    /// <summary>The plane, from the third lightmap vector: normal, distance, type (0..3) and sign bits</summary>
    PlaneNormal: array[0..2] of Single;
    PlaneDist: Single;
    PlaneType: Byte;
    PlaneSignBits: Byte;
  end;

  /// <summary>ParseTriSurf: srfTriangles_t of a triangle soup (MST_TRIANGLE_SOUP)</summary>
  TBspTriangleSurface = record
    FogIndex: Integer;
    ShaderNum: Integer;
    Verts: TArray<TBspDrawVert>;
    Indexes: TArray<Integer>;
    /// <summary>The bounds of the vertices (99999 and -99999 when there are none)</summary>
    Mins: array[0..2] of Single;
    Maxs: array[0..2] of Single;
  end;

  /// <summary>ParseFlare: srfFlare_t (MST_FLARE)</summary>
  TBspFlareSurface = record
    FogIndex: Integer;
    ShaderNum: Integer;
    Origin: array[0..2] of Single;
    Color: array[0..2] of Single;
    Normal: array[0..2] of Single;
  end;

  /// <summary>R_LoadVisibility: what the world keeps of the visibility lump</summary>
  TBspVisibility = record
    NumClusters: Integer;
    ClusterBytes: Integer;
    /// <summary>The rows after the two integers (empty when the lump is empty)</summary>
    Vis: TBytes;
    /// <summary>The "no visibility" row: (clusters + 63) and not 63 bytes of 255</summary>
    Novis: TBytes;
  end;

implementation

end.
