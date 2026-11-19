{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the types of     }
{  the front end                                                               }
{                                                                              }
{  refEntity_t, refdef_t, dlight_t, srfPoly_t, drawSurf_t, viewParms_t and     }
{  the cvars of the renderer as data. Based on the Quake III Arena GPL Source  }
{  Code (id Software): tr_types.h, tr_local.h. Copyright (C) 1999-2005 Id      }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Scene.Types;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types;

const
  /// <summary>MAX_DLIGHTS of tr_types.h</summary>
  Q3_MAX_DLIGHTS = 32;
  /// <summary>MAX_ENTITIES of tr_types.h</summary>
  Q3_MAX_ENTITIES = 1023;
  /// <summary>ENTITYNUM_WORLD (MAX_GENTITIES - 2)</summary>
  Q3_ENTITYNUM_WORLD = 1022;
  /// <summary>MAX_POLYS and MAX_POLYVERTS of tr_local.h</summary>
  Q3_MAX_POLYS = 600;
  Q3_MAX_POLYVERTS = 3000;
  /// <summary>MAX_DRAWSURFS and DRAWSURF_MASK: the index wraps instead of overflowing</summary>
  Q3_MAX_DRAWSURFS = $10000;
  Q3_DRAWSURF_MASK = Q3_MAX_DRAWSURFS - 1;
  /// <summary>MAX_SHADERS</summary>
  Q3_MAX_SHADERS = 16384;
  /// <summary>The packing of the sort key of a drawSurf_t</summary>
  Q3_QSORT_SHADERNUM_SHIFT = 17;
  Q3_QSORT_ENTITYNUM_SHIFT = 7;
  Q3_QSORT_FOGNUM_SHIFT = 2;
  /// <summary>MAX_MAP_AREA_BYTES</summary>
  Q3_MAX_MAP_AREA_BYTES = 32;

  /// <summary>refEntityType_t</summary>
  RT_MODEL = 0;
  RT_POLY = 1;
  RT_SPRITE = 2;
  RT_BEAM = 3;
  RT_RAIL_CORE = 4;
  RT_RAIL_RINGS = 5;
  RT_LIGHTNING = 6;
  RT_PORTALSURFACE = 7;
  RT_MAX_REF_ENTITY_TYPE = 8;

  /// <summary>renderfx flags</summary>
  RF_THIRD_PERSON = 2;
  RF_FIRST_PERSON = 4;
  RF_DEPTHHACK = 8;
  RF_NOSHADOW = 64;
  RF_WRAP_FRAMES = 512;

  /// <summary>rdflags</summary>
  RDF_NOWORLDMODEL = 1;
  RDF_HYPERSPACE = 4;

  /// <summary>The answers of the culling functions</summary>
  CULL_IN = 0;
  CULL_CLIP = 1;
  CULL_OUT = 2;

  /// <summary>The lightmap indexes that are not a lightmap</summary>
  LIGHTMAP_2D = -4;
  LIGHTMAP_BY_VERTEX = -3;
  LIGHTMAP_WHITEIMAGE = -2;
  LIGHTMAP_NONE = -1;

  /// <summary>GLS_DEPTHTEST_DISABLE and GLS_POLYMODE_LINE: state bits that IdTech4\Decl does not need</summary>
  GLS_DEPTHTEST_DISABLE = $00010000;
  GLS_POLYMODE_LINE = $00001000;

  /// <summary>The size of refEntity_t, refdef_t and polyVert_t as the modules lay them out</summary>
  Q3_REFENTITY_SIZE = 140;
  Q3_REFDEF_SIZE = 368;
  Q3_POLYVERT_SIZE = 24;

type
  /// <summary>polyVert_t: position, texture coordinates and the colour of the vertex</summary>
  TQ3PolyVert = packed record
    Xyz: TQ3Vec3;
    St: array[0..1] of Single;
    Modulate: array[0..3] of Byte;
  end;

  /// <summary>refEntity_t</summary>
  TQ3RefEntity = packed record
    ReType: Integer;
    RenderFx: Integer;
    HModel: Integer;
    LightingOrigin: TQ3Vec3;
    ShadowPlane: Single;
    Axis: array[0..2] of TQ3Vec3;
    NonNormalizedAxes: Integer;
    Origin: TQ3Vec3;
    Frame: Integer;
    OldOrigin: TQ3Vec3;
    OldFrame: Integer;
    BackLerp: Single;
    SkinNum: Integer;
    CustomSkin: Integer;
    CustomShader: Integer;
    ShaderRGBA: array[0..3] of Byte;
    ShaderTexCoord: array[0..1] of Single;
    ShaderTime: Single;
    Radius: Single;
    Rotation: Single;
  end;

  /// <summary>dlight_t: the radius is the intensity that the module gave</summary>
  TQ3DynamicLight = record
    Origin: TQ3Vec3;
    Radius: Single;
    Color: TQ3Vec3;
    Additive: Integer;
  end;

  /// <summary>srfPoly_t</summary>
  TQ3ScenePoly = record
    HShader: Integer;
    FogIndex: Integer;
    Verts: TArray<TQ3PolyVert>;
  end;

  /// <summary>
  ///   refdef_t without the text of the deform shaders (nothing in the front end reads it): the window, the field of
  ///   view, the viewpoint, the time, the flags and the mask of the areas that are shut
  /// </summary>
  TQ3RefDef = record
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    FovX: Single;
    FovY: Single;
    ViewOrigin: TQ3Vec3;
    ViewAxis: array[0..2] of TQ3Vec3;
    Time: Integer;
    RdFlags: Integer;
    AreaMask: array[0..Q3_MAX_MAP_AREA_BYTES - 1] of Byte;
  end;

  /// <summary>orientationr_t: where a model is and how the viewer sees it</summary>
  TQ3ViewOrientation = record
    Origin: TQ3Vec3;
    Axis: array[0..2] of TQ3Vec3;
    ViewOrigin: TQ3Vec3;
    ModelMatrix: array[0..15] of Single;
  end;

  /// <summary>viewParms_t</summary>
  TQ3FrontViewParms = record
    Orientation: TQ3ViewOrientation;
    World: TQ3ViewOrientation;
    PvsOrigin: TQ3Vec3;
    IsPortal: Boolean;
    IsMirror: Boolean;
    ViewportX: Integer;
    ViewportY: Integer;
    ViewportWidth: Integer;
    ViewportHeight: Integer;
    FovX: Single;
    FovY: Single;
    ProjectionMatrix: array[0..15] of Single;
    Frustum: array[0..3] of TQ3Plane;
    VisBounds: array[0..1] of TQ3Vec3;
    ZFar: Single;
  end;

  /// <summary>The kinds of surface a drawSurf_t can point at (surfaceType_t)</summary>
  TQ3SurfaceKind = (skBad, skSkip, skFace, skGrid, skTriangles, skPoly, skFlare, skEntity, skMd3);

  /// <summary>
  ///   What the pointer of a drawSurf_t pointed at: the kind, an index (the surface of the world, the poly of the
  ///   scene, the entity) and a second index (the surface of an md3)
  /// </summary>
  TQ3SurfaceRef = record
    Kind: TQ3SurfaceKind;
    Index: Integer;
    Sub: Integer;
    /// <summary>
    ///   The dlights that reach the surface (what R_DlightSurface keeps in the surface: dlightBits). The C keeps it in
    ///   the surface itself, where it stays from frame to frame; here it belongs to the drawSurf of the frame
    /// </summary>
    DlightMask: Integer;
    /// <summary>The level of detail of the md3 that the surface of kind skMd3 is of (R_ComputeLOD)</summary>
    Lod: Integer;
  end;

  /// <summary>drawSurf_t: the sort key packs the shader, the entity, the fog and the dlight bits</summary>
  TQ3DrawSurf = record
    Sort: Cardinal;
    Surface: TQ3SurfaceRef;
  end;

  /// <summary>The cvars of the renderer that the front end reads, with their defaults</summary>
  TQ3RenderSettings = record
    /// <summary>r_znear</summary>
    ZNear: Single;
    /// <summary>r_facePlaneCull</summary>
    FacePlaneCull: Boolean;
    /// <summary>r_nocull</summary>
    NoCull: Boolean;
    /// <summary>r_nocurves</summary>
    NoCurves: Boolean;
    /// <summary>r_novis</summary>
    NoVis: Boolean;
    /// <summary>r_lockpvs</summary>
    LockPvs: Boolean;
    /// <summary>r_drawworld</summary>
    DrawWorld: Boolean;
    /// <summary>r_drawentities</summary>
    DrawEntities: Boolean;
    /// <summary>r_dynamiclight</summary>
    DynamicLight: Boolean;
    /// <summary>r_vertexLight</summary>
    VertexLight: Boolean;
    /// <summary>r_fullbright</summary>
    FullBright: Boolean;
    /// <summary>r_singleShader</summary>
    SingleShader: Boolean;
    /// <summary>r_shadows (0 none, 1 blobs, 2 stencil, 3 projection)</summary>
    Shadows: Integer;
    /// <summary>r_maxpolys and r_maxpolyverts</summary>
    MaxPolys: Integer;
    MaxPolyVerts: Integer;
    /// <summary>r_fastsky (the sky is not drawn), r_showsky (the sky in front of everything), r_drawSun</summary>
    FastSky: Boolean;
    ShowSky: Boolean;
    DrawSun: Boolean;
    /// <summary>r_lodCurveError (the error that a grid of a patch may have, divided by the distance)</summary>
    LodCurveError: Single;
    /// <summary>r_railWidth, r_railCoreWidth and r_railSegmentLength</summary>
    RailWidth: Integer;
    RailCoreWidth: Integer;
    RailSegmentLength: Single;
    /// <summary>r_lodscale and r_lodbias (the level of detail of the md3 models)</summary>
    LodScale: Single;
    LodBias: Integer;
    class function Defaults: TQ3RenderSettings; static;
  end;

  /// <summary>
  ///   One msurface_t of the world, in the order of the surface lump (the marksurfaces of the leafs index it): the
  ///   kind, where its data are (the index in the faces, the triangle soups or the flares of the world; for a grid the
  ///   surface number itself), the shader number of the BSP, the lightmap number the shader is looked up with and the
  ///   fog index (the fog number plus one)
  /// </summary>
  TQ3WorldSurface = record
    Kind: TQ3SurfaceKind;
    DataIndex: Integer;
    ShaderNum: Integer;
    LightmapNum: Integer;
    FogIndex: Integer;
    /// <summary>MAX_FACE_POINTS exceeded: tr.defaultShader</summary>
    UsesDefaultShader: Boolean;
  end;

  /// <summary>fog_t: the bounds of the brush of a fog volume and the name of its shader</summary>
  TQ3WorldFog = record
    Mins: TQ3Vec3;
    Maxs: TQ3Vec3;
    ShaderName: AnsiString;
  end;

  /// <summary>The numbers the front end counts (the parts of trPerf_t it needs, and the drawSurf totals)</summary>
  TQ3FrontEndStats = record
    DrawSurfs: Integer;
    WorldSurfaces: Integer;
    PolySurfaces: Integer;
    EntitySurfaces: Integer;
    Leafs: Integer;
    PortalSurfaces: Integer;
    Scenes: Integer;
  end;

implementation

{ TQ3RenderSettings }

class function TQ3RenderSettings.Defaults: TQ3RenderSettings;
begin
  Result := Default(TQ3RenderSettings);
  Result.ZNear := 4;
  Result.FacePlaneCull := True;
  Result.DrawWorld := True;
  Result.DrawEntities := True;
  Result.DynamicLight := True;
  Result.Shadows := 1;
  Result.MaxPolys := Q3_MAX_POLYS;
  Result.MaxPolyVerts := Q3_MAX_POLYVERTS;
  Result.LodCurveError := 250;
  Result.RailWidth := 16;
  Result.RailCoreWidth := 6;
  Result.RailSegmentLength := 32;
  Result.LodScale := 5;
end;

end.
