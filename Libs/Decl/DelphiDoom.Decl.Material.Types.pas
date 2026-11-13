{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - types and constants of the material       }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.h, tr_local.h (GLS_*). Copyright (C) 1999-2011 id         }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.Types;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions;

const
  // MAX_EXPRESSION_OPS, MAX_EXPRESSION_REGISTERS (idlib\precompiled.h)
  MAX_EXPRESSION_OPS = 4096;
  MAX_EXPRESSION_REGISTERS = 4096;
  // MAX_SHADER_STAGES, MAX_TEXGEN_REGISTERS, MAX_ENTITY_SHADER_PARMS, MAX_FRAGMENT_IMAGES, MAX_VERTEX_PARMS
  MAX_SHADER_STAGES = 256;
  MAX_TEXGEN_REGISTERS = 4;
  MAX_ENTITY_SHADER_PARMS = 12;
  MAX_GLOBAL_SHADER_PARMS = 8;
  MAX_FRAGMENT_IMAGES = 8;
  MAX_VERTEX_PARMS = 4;

  // expRegister_t: the registers that are not constants nor temporaries
  EXP_REG_TIME = 0;
  EXP_REG_PARM0 = 1;
  EXP_REG_PARM1 = 2;
  EXP_REG_PARM2 = 3;
  EXP_REG_PARM3 = 4;
  EXP_REG_PARM11 = 12;
  EXP_REG_GLOBAL0 = 13;
  EXP_REG_GLOBAL7 = 20;
  EXP_REG_NUM_PREDEFINED = 21;

  // the draw state bits of a stage (GLS_*)
  GLS_SRCBLEND_ZERO = $00000001;
  GLS_SRCBLEND_ONE = $0;
  GLS_SRCBLEND_DST_COLOR = $00000003;
  GLS_SRCBLEND_ONE_MINUS_DST_COLOR = $00000004;
  GLS_SRCBLEND_SRC_ALPHA = $00000005;
  GLS_SRCBLEND_ONE_MINUS_SRC_ALPHA = $00000006;
  GLS_SRCBLEND_DST_ALPHA = $00000007;
  GLS_SRCBLEND_ONE_MINUS_DST_ALPHA = $00000008;
  GLS_SRCBLEND_ALPHA_SATURATE = $00000009;
  GLS_SRCBLEND_BITS = $0000000F;
  GLS_DSTBLEND_ZERO = $0;
  GLS_DSTBLEND_ONE = $00000020;
  GLS_DSTBLEND_SRC_COLOR = $00000030;
  GLS_DSTBLEND_ONE_MINUS_SRC_COLOR = $00000040;
  GLS_DSTBLEND_SRC_ALPHA = $00000050;
  GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA = $00000060;
  GLS_DSTBLEND_DST_ALPHA = $00000070;
  GLS_DSTBLEND_ONE_MINUS_DST_ALPHA = $00000080;
  GLS_DSTBLEND_BITS = $000000F0;
  GLS_DEPTHMASK = $00000100;
  GLS_REDMASK = $00000200;
  GLS_GREENMASK = $00000400;
  GLS_BLUEMASK = $00000800;
  GLS_ALPHAMASK = $00001000;
  GLS_COLORMASK = GLS_REDMASK or GLS_GREENMASK or GLS_BLUEMASK;
  GLS_DEPTHFUNC_ALWAYS = $00010000;
  GLS_DEPTHFUNC_EQUAL = $00020000;
  GLS_DEPTHFUNC_LESS = $0;

  // materialFlags_t
  MF_DEFAULTED = 1 shl 0;
  MF_POLYGONOFFSET = 1 shl 1;
  MF_NOSHADOWS = 1 shl 2;
  MF_FORCESHADOWS = 1 shl 3;
  MF_NOSELFSHADOW = 1 shl 4;
  MF_NOPORTALFOG = 1 shl 5;
  MF_EDITOR_VISIBLE = 1 shl 6;

  // contentsFlags_t
  CONTENTS_SOLID = 1 shl 0;
  CONTENTS_OPAQUE = 1 shl 1;
  CONTENTS_WATER = 1 shl 2;
  CONTENTS_PLAYERCLIP = 1 shl 3;
  CONTENTS_MONSTERCLIP = 1 shl 4;
  CONTENTS_MOVEABLECLIP = 1 shl 5;
  CONTENTS_IKCLIP = 1 shl 6;
  CONTENTS_BLOOD = 1 shl 7;
  CONTENTS_BODY = 1 shl 8;
  CONTENTS_PROJECTILE = 1 shl 9;
  CONTENTS_CORPSE = 1 shl 10;
  CONTENTS_RENDERMODEL = 1 shl 11;
  CONTENTS_TRIGGER = 1 shl 12;
  CONTENTS_AAS_SOLID = 1 shl 13;
  CONTENTS_AAS_OBSTACLE = 1 shl 14;
  CONTENTS_FLASHLIGHT_TRIGGER = 1 shl 15;
  CONTENTS_AREAPORTAL = 1 shl 20;
  CONTENTS_NOCSG = 1 shl 21;

  // surfTypes_t
  SURFTYPE_NONE = 0;
  SURFTYPE_METAL = 1;
  SURFTYPE_STONE = 2;
  SURFTYPE_FLESH = 3;
  SURFTYPE_WOOD = 4;
  SURFTYPE_CARDBOARD = 5;
  SURFTYPE_LIQUID = 6;
  SURFTYPE_GLASS = 7;
  SURFTYPE_PLASTIC = 8;
  SURFTYPE_RICOCHET = 9;
  SURFTYPE_10 = 10;
  SURFTYPE_11 = 11;
  SURFTYPE_12 = 12;
  SURFTYPE_13 = 13;
  SURFTYPE_14 = 14;
  SURFTYPE_15 = 15;
  NUM_SURFACE_BITS = 4;

  // surfaceFlags_t
  SURF_TYPE_MASK = (1 shl NUM_SURFACE_BITS) - 1;
  SURF_NODAMAGE = 1 shl 4;
  SURF_SLICK = 1 shl 5;
  SURF_COLLISION = 1 shl 6;
  SURF_LADDER = 1 shl 7;
  SURF_NOIMPACT = 1 shl 8;
  SURF_NOSTEPS = 1 shl 9;
  SURF_DISCRETE = 1 shl 10;
  SURF_NOFRAGMENT = 1 shl 11;
  SURF_NULLNORMAL = 1 shl 12;

  // materialSort_t: the sort value of a material is a float
  SS_SUBVIEW = -3;
  SS_GUI = -2;
  SS_BAD = -1;
  SS_OPAQUE = 0;
  SS_PORTAL_SKY = 1;
  SS_DECAL = 2;
  SS_FAR = 3;
  SS_MEDIUM = 4;
  SS_CLOSE = 5;
  SS_ALMOST_NEAREST = 6;
  SS_NEAREST = 7;
  SS_POST_PROCESS = 100;

type
  /// <summary>textureFilter_t</summary>
  TMaterialTextureFilter = (Linear, Nearest, Default);

  /// <summary>textureRepeat_t</summary>
  TMaterialTextureRepeat = (Repeated, Clamp, ClampToBorder, ClampToZero, ClampToZeroAlpha);

  /// <summary>textureDepth_t: the quality an image is requested with</summary>
  TMaterialTextureDepth = (Specular, Diffuse, Default, Bump, HighQuality);

  /// <summary>cubeFiles_t</summary>
  TMaterialCubeMap = (Flat2D, Native, Camera);

  /// <summary>deform_t</summary>
  TMaterialDeform = (None, Sprite, Tube, Flare, Expand, Move, EyeBall, Particle, Particle2, Turbulent);

  /// <summary>dynamicidImage_t</summary>
  TMaterialDynamicImage = (Static, Scratch, CubeRender, MirrorRender, XRayRender, RemoteRender);

  /// <summary>expOpType_t (the order is the one of the original: a test prints the names)</summary>
  TMaterialOpType = (Add, Subtract, Multiply, Divide, Modulo, Table, GreaterThan, GreaterOrEqual, LessThan,
    LessOrEqual, Equal, NotEqual, LogicalAnd, LogicalOr, Sound);

  /// <summary>texgen_t</summary>
  TMaterialTexgen = (Explicit, DiffuseCube, ReflectCube, SkyboxCube, WobbleSkyCube, Screen, Screen2, GlassWarp);

  /// <summary>stageLighting_t: the order Bump, Diffuse, Specular is needed to sort the stages</summary>
  TMaterialLighting = (Ambient, Bump, Diffuse, Specular);

  /// <summary>stageVertexColor_t</summary>
  TMaterialVertexColor = (Ignore, Modulate, InverseModulate);

  /// <summary>materialCoverage_t</summary>
  TMaterialCoverage = (Bad, Opaque, Perforated, Translucent);

  /// <summary>cullType_t</summary>
  TMaterialCullType = (FrontSided, BackSided, TwoSided);

  /// <summary>The registers an expression reads, copied before the operations run</summary>
  TMaterialEvaluationInput = record
    /// <summary>The time in seconds (<c>view->floatTime</c>)</summary>
    Time: Single;
    /// <summary>The 12 parameters of the entity (<c>shaderParms</c>)</summary>
    Parms: array[0..MAX_ENTITY_SHADER_PARMS - 1] of Single;
    /// <summary>The 8 global parameters of the view (<c>renderView.shaderParms</c>)</summary>
    GlobalParms: array[0..MAX_GLOBAL_SHADER_PARMS - 1] of Single;
    /// <summary>The value of the "sound" term: <c>soundEmitter->CurrentAmplitude()</c></summary>
    SoundAmplitude: Single;
    /// <summary>False when there is no sound emitter (the term is then 0)</summary>
    HasSoundEmitter: Boolean;
  end;

  /// <summary>expOp_t: <c>registers[C] := registers[A] op registers[B]</c> (for a table A is the index of the table)</summary>
  TMaterialOp = record
    OpType: TMaterialOpType;
    A, B, C: Integer;
  end;

  /// <summary>decalInfo_t</summary>
  TMaterialDecalInfo = record
    /// <summary>Milliseconds without a change</summary>
    StayTime: Integer;
    /// <summary>Milliseconds to fade the vertex colors over</summary>
    FadeTime: Integer;
    Start: array[0..3] of Single;
    Finish: array[0..3] of Single;
  end;

  /// <summary>
  ///   An image named by a material with the way it is to be loaded (the parameters of
  ///   <c>idImageManager::ImageFromFile</c>); the image is not loaded here
  /// </summary>
  TMaterialImageReference = record
    /// <summary>The canonical text of the image program ("_white", "addnormals( a, b )")</summary>
    Name: AnsiString;
    Filter: TMaterialTextureFilter;
    RepeatMode: TMaterialTextureRepeat;
    Depth: TMaterialTextureDepth;
    CubeMap: TMaterialCubeMap;
    AllowPicmip: Boolean;
  end;

  /// <summary>The 2x3 texture matrix as register indexes</summary>
  TMaterialTextureMatrix = array[0..1, 0..2] of Integer;

  /// <summary>textureStage_t</summary>
  TMaterialTextureStage = record
    /// <summary>False for a stage that is a video, a dynamic image or a program without map</summary>
    HasImage: Boolean;
    Image: TMaterialImageReference;
    Texgen: TMaterialTexgen;
    HasMatrix: Boolean;
    /// <summary>Register indexes of the 2x3 texture matrix</summary>
    Matrix: TMaterialTextureMatrix;
    Dynamic: TMaterialDynamicImage;
    Width, Height: Integer;
    /// <summary>The file of a videoMap (the cinematic is not opened) or of a soundMap</summary>
    CinematicName: AnsiString;
    HasCinematic: Boolean;
    CinematicLoop: Boolean;
    IsSoundMap: Boolean;
  end;

  /// <summary>newShaderStage_t: a stage with a vertex and fragment program</summary>
  TMaterialNewStage = record
    VertexProgram: AnsiString;
    FragmentProgram: AnsiString;
    NumVertexParms: Integer;
    VertexParms: array[0..MAX_VERTEX_PARMS - 1, 0..3] of Integer;
    NumFragmentImages: Integer;
    FragmentImages: array[0..MAX_FRAGMENT_IMAGES - 1] of TMaterialImageReference;
    MegaTexture: AnsiString;
  end;

  /// <summary>shaderStage_t</summary>
  TMaterialStage = record
    /// <summary>If <c>registers[ConditionRegister] = 0</c> the stage is skipped</summary>
    ConditionRegister: Integer;
    Lighting: TMaterialLighting;
    DrawStateBits: Integer;
    ColorRegisters: array[0..3] of Integer;
    HasAlphaTest: Boolean;
    AlphaTestRegister: Integer;
    Texture: TMaterialTextureStage;
    VertexColor: TMaterialVertexColor;
    IgnoreAlphaTest: Boolean;
    PrivatePolygonOffset: Single;
    HasNewStage: Boolean;
    NewStage: TMaterialNewStage;
  end;

  /// <summary>
  ///   What the material declaration needs besides the finder: the cvars the parse reads and the answers of the
  ///   renderer that the original asks the OpenGL configuration
  /// </summary>
  TMaterialOptions = record
    /// <summary><c>image_ignoreHighQuality</c>: "uncompressed" and "highquality" are ignored</summary>
    IgnoreHighQuality: Boolean;
    /// <summary><c>glConfig.ARBFragmentProgramAvailable</c>: the value of the term "fragmentPrograms"</summary>
    FragmentProgramsAvailable: Boolean;
    /// <summary><c>r_useConstantMaterials</c>: <c>ConstantRegisters</c> gives the table of a constant material</summary>
    UseConstantMaterials: Boolean;
    /// <summary>
    ///   The original never sets <c>registersAreConstant</c> (it is cleared and nothing makes it true), so
    ///   <c>ConstantRegisters</c> is always nil. False keeps that; True does what the comment of the original says:
    ///   a material that never reads time, a parameter, a global or the sound gets its registers evaluated once.
    /// </summary>
    FixConstantRegisters: Boolean;
    class function Standard: TMaterialOptions; static;
  end;

  /// <summary>An error in the use of the material classes (not in the text of a material, that is a warning)</summary>
  EDeclMaterialException = class(EIdLibException);

implementation

{ TMaterialOptions }

class function TMaterialOptions.Standard: TMaterialOptions;
begin
  Result.IgnoreHighQuality := False;
  Result.FragmentProgramsAvailable := True;
  Result.UseConstantMaterials := True;
  Result.FixConstantRegisters := False;
end;

end.
