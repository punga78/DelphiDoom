{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - interfaces of the material                }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.h. Copyright (C) 1999-2011 id Software LLC, a ZeniMax     }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.Intf;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types;

type
  /// <summary>
  ///   Reads one image program from a lexer that is in the middle of a material and gives its canonical text
  ///   (<c>R_ParsePastImageProgram</c>); the images are not loaded. The implementation over the interpreter of
  ///   <c>Libs\Imaging</c> is <c>TMaterialImageProgramNamer</c>.
  /// </summary>
  IMaterialImageNamer = interface
    ['{7A3B2C10-5D4E-4F61-9A72-8B1C0D3E4F01}']
    function ParsePastImageProgram(const ALexer: TIdLexer): AnsiString;
  end;

  /// <summary>
  ///   What a material is (idMaterial): stages, flags, sort, deform, decal info. Get it with
  ///   <c>Supports(Decl, IDeclMaterial, Material)</c>. The images are named, never loaded.
  /// </summary>
  IDeclMaterial = interface
    ['{7A3B2C10-5D4E-4F61-9A72-8B1C0D3E4F02}']
    function GetNumStages: Integer;
    function GetStage(const AIndex: Integer): TMaterialStage;
    /// <summary>The index of the first bump stage, -1 if there is none</summary>
    function GetBumpStageIndex: Integer;
    /// <summary>True if the material draws anything at all (stages or a gui)</summary>
    function IsDrawn: Boolean;
    function HasAmbient: Boolean;
    function HasGui: Boolean;
    function HasSubview: Boolean;
    function SurfaceCastsShadow: Boolean;
    function ReceivesFog: Boolean;
    function ReceivesLighting: Boolean;
    function ReceivesLightingOnBackSides: Boolean;
    function ShouldCreateBackSides: Boolean;
    function UseUnsmoothedTangents: Boolean;
    function AllowOverlays: Boolean;
    function Coverage: TMaterialCoverage;
    function HasHigherDmapPriority(const AOther: IDeclMaterial): Boolean;
    function IsDiscrete: Boolean;
    function NoFragment: Boolean;
    function IsFogLight: Boolean;
    function IsBlendLight: Boolean;
    function IsAmbientLight: Boolean;
    function LightCastsShadows: Boolean;
    function LightEffectsBackSides: Boolean;
    /// <summary>The image of "lightFalloffImage", '' if none</summary>
    function GetLightFalloffImageName: AnsiString;
    function GetRenderBump: AnsiString;
    procedure SetMaterialFlag(const AFlag: Integer);
    procedure ClearMaterialFlag(const AFlag: Integer);
    function TestMaterialFlag(const AFlag: Integer): Boolean;
    function GetContentFlags: Integer;
    function GetSurfaceFlags: Integer;
    /// <summary>SURFTYPE_*: the surface flags masked with SURF_TYPE_MASK</summary>
    function GetSurfaceType: Integer;
    function GetDescription: AnsiString;
    function GetSort: Single;
    procedure SetSort(const ASort: Single);
    function Deform: TMaterialDeform;
    function GetDeformRegister(const AIndex: Integer): Integer;
    /// <summary>The table or the particle of a turbulent, particle or particle2 deform; nil otherwise</summary>
    function GetDeformDecl: IDecl;
    /// <summary>The texgen of the first stage that has one (a surface has only one for all its stages)</summary>
    function Texgen: TMaterialTexgen;
    function GetTexGenRegister(const AIndex: Integer): Integer;
    function GetCullType: TMaterialCullType;
    function GetEditorAlpha: Single;
    /// <summary>The name given in "qer_editorimage", or the image of the first diffuse stage, or the first stage, else _default</summary>
    function GetEditorImageName: AnsiString;
    function GetEntityGui: Integer;
    /// <summary>The gui named by "guisurf" ('' for "guisurf entity" or none); the gui is not loaded</summary>
    function GetGuiName: AnsiString;
    function GetDecalInfo: TMaterialDecalInfo;
    function Spectrum: Integer;
    function GetPolygonOffset: Single;
    function GetSurfaceArea: Single;
    procedure AddToSurfaceArea(const AArea: Single);
    function SuppressInSubview: Boolean;
    function IsPortalSky: Boolean;
    /// <summary>The image of stage 0 for the renderer, "_scratch" without stages or without an image</summary>
    function ImageName: AnsiString;
  end;

  /// <summary>The expression registers of a material and their evaluation (a different interface: ISP)</summary>
  IMaterialRegisters = interface
    ['{7A3B2C10-5D4E-4F61-9A72-8B1C0D3E4F03}']
    function GetNumRegisters: Integer;
    function GetNumOps: Integer;
    function GetOp(const AIndex: Integer): TMaterialOp;
    /// <summary>The value the parse gave a register (a constant; the others are 0)</summary>
    function GetParsedRegister(const AIndex: Integer): Single;
    /// <summary>
    ///   Fills <c>ARegisters</c> (resized to <c>GetNumRegisters</c>): the constants, then the parameters of
    ///   <c>AInput</c>, then the operations in order. Division by zero and overflow give infinity (as in C).
    /// </summary>
    procedure EvaluateRegisters(var ARegisters: TArray<Single>; const AInput: TMaterialEvaluationInput);
    /// <summary>
    ///   The registers of a material that only uses constants (no time, parm, global or sound); nil when the
    ///   material is not constant or the option <c>UseConstantMaterials</c> is off
    /// </summary>
    function ConstantRegisters: TArray<Single>;
  end;

implementation

end.
