{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - types, constants and the data of a shader   }
{                                                                              }
{  Port of the data of renderer\tr_shader.c and renderer\tr_local.h            }
{  (shader_t, shaderStage_t, textureBundle_t, texModInfo_t, waveForm_t,        }
{  deformStage_t, skyParms_t, fogParms_t, GLS_*, SS_*) and of                  }
{  game\surfaceflags.h of Quake III Arena (id Software, GPL v2 or later).      }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions;

const
  /// <summary>The number of the declaration type "shader" (the first free numbers are taken by other libraries)</summary>
  DECL_Q3SHADER = 30;

  // MAX_SHADER_STAGES, TR_MAX_TEXMODS, MAX_SHADER_DEFORMS, MAX_IMAGE_ANIMATIONS
  Q3_MAX_SHADER_STAGES = 8;
  Q3_MAX_TEXMODS = 4;
  Q3_MAX_SHADER_DEFORMS = 3;
  Q3_MAX_IMAGE_ANIMATIONS = 8;

  // shaderSort_t
  SS_BAD = 0;
  SS_PORTAL = 1;
  SS_ENVIRONMENT = 2;
  SS_OPAQUE = 3;
  SS_DECAL = 4;
  SS_SEE_THROUGH = 5;
  SS_BANNER = 6;
  SS_FOG = 7;
  SS_UNDERWATER = 8;
  SS_BLEND0 = 9;
  SS_BLEND1 = 10;
  SS_BLEND2 = 11;
  SS_BLEND3 = 12;
  SS_BLEND6 = 13;
  SS_STENCIL_SHADOW = 14;
  SS_ALMOST_NEAREST = 15;
  SS_NEAREST = 16;

  // GLS_* (the state bits of a stage)
  GLS_SRCBLEND_ZERO = $00000001;
  GLS_SRCBLEND_ONE = $00000002;
  GLS_SRCBLEND_DST_COLOR = $00000003;
  GLS_SRCBLEND_ONE_MINUS_DST_COLOR = $00000004;
  GLS_SRCBLEND_SRC_ALPHA = $00000005;
  GLS_SRCBLEND_ONE_MINUS_SRC_ALPHA = $00000006;
  GLS_SRCBLEND_DST_ALPHA = $00000007;
  GLS_SRCBLEND_ONE_MINUS_DST_ALPHA = $00000008;
  GLS_SRCBLEND_ALPHA_SATURATE = $00000009;
  GLS_SRCBLEND_BITS = $0000000F;
  GLS_DSTBLEND_ZERO = $00000010;
  GLS_DSTBLEND_ONE = $00000020;
  GLS_DSTBLEND_SRC_COLOR = $00000030;
  GLS_DSTBLEND_ONE_MINUS_SRC_COLOR = $00000040;
  GLS_DSTBLEND_SRC_ALPHA = $00000050;
  GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA = $00000060;
  GLS_DSTBLEND_DST_ALPHA = $00000070;
  GLS_DSTBLEND_ONE_MINUS_DST_ALPHA = $00000080;
  GLS_DSTBLEND_BITS = $000000F0;
  GLS_DEPTHMASK_TRUE = $00000100;
  GLS_DEPTHFUNC_EQUAL = $00020000;
  GLS_ATEST_GT_0 = $10000000;
  GLS_ATEST_LT_80 = $20000000;
  GLS_ATEST_GE_80 = $40000000;
  GLS_DEFAULT = GLS_DEPTHMASK_TRUE;

  // game\surfaceflags.h
  CONTENTS_SOLID = $00000001;
  CONTENTS_LAVA = $00000008;
  CONTENTS_SLIME = $00000010;
  CONTENTS_WATER = $00000020;
  CONTENTS_FOG = $00000040;
  CONTENTS_AREAPORTAL = $00008000;
  CONTENTS_PLAYERCLIP = $00010000;
  CONTENTS_MONSTERCLIP = $00020000;
  CONTENTS_CLUSTERPORTAL = $00100000;
  CONTENTS_DONOTENTER = $00200000;
  CONTENTS_ORIGIN = $01000000;
  CONTENTS_DETAIL = $08000000;
  CONTENTS_STRUCTURAL = $10000000;
  CONTENTS_TRANSLUCENT = $20000000;
  CONTENTS_NODROP = Integer($80000000);
  SURF_NODAMAGE = $1;
  SURF_SLICK = $2;
  SURF_SKY = $4;
  SURF_LADDER = $8;
  SURF_NOIMPACT = $10;
  SURF_NOMARKS = $20;
  SURF_FLESH = $40;
  SURF_NODRAW = $80;
  SURF_HINT = $100;
  SURF_NOLIGHTMAP = $400;
  SURF_POINTLIGHT = $800;
  SURF_METALSTEPS = $1000;
  SURF_NOSTEPS = $2000;
  SURF_NONSOLID = $4000;
  SURF_LIGHTFILTER = $8000;
  SURF_ALPHASHADOW = $10000;
  SURF_NODLIGHT = $20000;
  SURF_DUST = $40000;

type
  /// <summary>genFunc_t</summary>
  TQ3GenFunc = (gfNone, gfSin, gfSquare, gfTriangle, gfSawtooth, gfInverseSawtooth, gfNoise);

  /// <summary>deform_t</summary>
  TQ3Deform = (dfNone, dfWave, dfNormals, dfBulge, dfMove, dfProjectionShadow, dfAutoSprite, dfAutoSprite2,
    dfText0, dfText1, dfText2, dfText3, dfText4, dfText5, dfText6, dfText7);

  /// <summary>alphaGen_t</summary>
  TQ3AlphaGen = (agIdentity, agSkip, agEntity, agOneMinusEntity, agVertex, agOneMinusVertex, agLightingSpecular,
    agWaveform, agPortal, agConst);

  /// <summary>colorGen_t</summary>
  TQ3ColorGen = (cgBad, cgIdentityLighting, cgIdentity, cgEntity, cgOneMinusEntity, cgExactVertex, cgVertex,
    cgOneMinusVertex, cgWaveform, cgLightingDiffuse, cgFog, cgConst);

  /// <summary>texCoordGen_t</summary>
  TQ3TexCoordGen = (tgBad, tgIdentity, tgLightmap, tgTexture, tgEnvironmentMapped, tgFog, tgVector);

  /// <summary>acff_t</summary>
  TQ3AdjustColorsForFog = (acNone, acModulateRgb, acModulateRgba, acModulateAlpha);

  /// <summary>texMod_t</summary>
  TQ3TexModType = (tmNone, tmTransform, tmTurbulent, tmScroll, tmScale, tmStretch, tmRotate, tmEntityTranslate);

  /// <summary>cullType_t</summary>
  TQ3CullType = (ctFrontSided, ctBackSided, ctTwoSided);

  /// <summary>waveForm_t</summary>
  TQ3WaveForm = record
    Func: TQ3GenFunc;
    Base: Single;
    Amplitude: Single;
    Phase: Single;
    Frequency: Single;
  end;

  /// <summary>texModInfo_t</summary>
  TQ3TexMod = record
    ModType: TQ3TexModType;
    /// <summary>For tmTurbulent and tmStretch</summary>
    Wave: TQ3WaveForm;
    Matrix: array[0..1, 0..1] of Single;
    Translate: array[0..1] of Single;
    Scale: array[0..1] of Single;
    Scroll: array[0..1] of Single;
    RotateSpeed: Single;
  end;

  /// <summary>
  ///   textureBundle_t (the first bundle: the second one is only used by the multitexture collapse of the
  ///   renderer, which is not ported). An image is a name, never loaded; an empty name is "no image".
  ///   "$whiteimage" and "$lightmap" are the names of the images the renderer makes itself; the image of
  ///   a <c>videoMap</c> is "$scratch" (the renderer's scratch image).
  /// </summary>
  TQ3TextureBundle = record
    ImageNames: array[0..Q3_MAX_IMAGE_ANIMATIONS - 1] of AnsiString;
    NumImageAnimations: Integer;
    ImageAnimationSpeed: Single;
    TcGen: TQ3TexCoordGen;
    TcGenVectors: array[0..1, 0..2] of Single;
    NumTexMods: Integer;
    TexMods: array[0..Q3_MAX_TEXMODS - 1] of TQ3TexMod;
    IsLightmap: Boolean;
    IsVideoMap: Boolean;
    /// <summary>The name of the cinematic of a videoMap</summary>
    VideoMapName: AnsiString;
  end;

  /// <summary>shaderStage_t</summary>
  TQ3ShaderStage = record
    Active: Boolean;
    Bundle: TQ3TextureBundle;
    RgbWave: TQ3WaveForm;
    RgbGen: TQ3ColorGen;
    AlphaWave: TQ3WaveForm;
    AlphaGen: TQ3AlphaGen;
    ConstantColor: array[0..3] of Byte;
    StateBits: Cardinal;
    AdjustColorsForFog: TQ3AdjustColorsForFog;
    IsDetail: Boolean;
  end;

  /// <summary>deformStage_t</summary>
  TQ3DeformStage = record
    Deformation: TQ3Deform;
    MoveVector: array[0..2] of Single;
    DeformationWave: TQ3WaveForm;
    DeformationSpread: Single;
    BulgeWidth: Single;
    BulgeHeight: Single;
    BulgeSpeed: Single;
  end;

  /// <summary>skyParms_t: the names of the twelve images</summary>
  TQ3SkyParms = record
    CloudHeight: Single;
    OuterBox: array[0..5] of AnsiString;
    InnerBox: array[0..5] of AnsiString;
  end;

  /// <summary>fogParms_t</summary>
  TQ3FogParms = record
    Color: array[0..2] of Single;
    DepthForOpaque: Single;
  end;

  /// <summary>
  ///   What <c>ParseShader</c> and the data part of <c>FinishShader</c> leave in <c>shader_t</c> (plus the
  ///   sun of <c>q3map_sun</c>, which the original keeps in the renderer's <c>tr</c>)
  /// </summary>
  TQ3ShaderData = record
    Name: AnsiString;
    Sort: Single;
    DefaultShader: Boolean;
    ExplicitlyDefined: Boolean;
    SurfaceFlags: Integer;
    ContentFlags: Integer;
    EntityMergable: Boolean;
    IsSky: Boolean;
    Sky: TQ3SkyParms;
    FogParms: TQ3FogParms;
    PortalRange: Single;
    CullType: TQ3CullType;
    PolygonOffset: Boolean;
    NoMipMaps: Boolean;
    NoPicMip: Boolean;
    NumDeforms: Integer;
    Deforms: array[0..Q3_MAX_SHADER_DEFORMS - 1] of TQ3DeformStage;
    NumUnfoggedPasses: Integer;
    Stages: array[0..Q3_MAX_SHADER_STAGES - 1] of TQ3ShaderStage;
    ClampTime: Single;
    HasSun: Boolean;
    SunLight: array[0..2] of Single;
    SunDirection: array[0..2] of Single;
  end;

  /// <summary>
  ///   What the renderer cvars change in the reading of a shader (<c>r_detailTextures</c>); the other
  ///   cvars of <c>FinishShader</c> (<c>r_vertexLight</c>, the multitexture collapse) are not ported
  /// </summary>
  TQ3ShaderOptions = record
    /// <summary>r_detailTextures (default 1): false drops the stages marked <c>detail</c></summary>
    DetailTextures: Boolean;
    class function Standard: TQ3ShaderOptions; static;
  end;

  /// <summary>
  ///   <c>ri.Error(ERR_DROP, ...)</c> of tr_shader.c (too many <c>tcMod</c> in a shader): the original drops
  ///   the whole frame; the declaration turns it into a warning and a shader that failed
  /// </summary>
  EDeclQ3ShaderException = class(EIdLibException);

implementation

class function TQ3ShaderOptions.Standard: TQ3ShaderOptions;
begin
  Result.DetailTextures := True;
end;

end.
