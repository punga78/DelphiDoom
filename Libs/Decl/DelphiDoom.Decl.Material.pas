{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclMaterial, the "material" declaration }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.h, Material.cpp. Copyright (C) 1999-2011 id Software LLC, }
{  a ZeniMax Media company.                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Base, DelphiDoom.Decl.Material.Types,
  DelphiDoom.Decl.Material.Intf, DelphiDoom.Decl.Material.Data;

type
  /// <summary>
  ///   <c>name { ... }</c> of a <c>.mtr</c> file (idMaterial). The data is read through
  ///   <c>IDeclMaterial</c> and <c>IMaterialRegisters</c>. A material with an error is replaced by the default
  ///   material (one stage, <c>blend blend / map _default</c>) and the parse says false. A name without a
  ///   definition gets the implicit material that blends the image of the same name.
  ///   <para><c>Save</c> and <c>ReloadImages</c> are <c>IMaterialPersistence</c> (the images go to an injected
  ///   <c>IMaterialImageReloader</c>). Not ported: loading images, cinematics, guis and programs (they are
  ///   named), the reference counting of images, <c>CinematicLength</c> and the other cinematic calls.</para>
  /// </summary>
  TDeclMaterial = class(TDecl, IDeclMaterial, IMaterialRegisters, IMaterialPersistence)
  strict private
    FNamer: IMaterialImageNamer;
    FOptions: TMaterialOptions;
    FData: TMaterialData;
    function FirstStageImageName(const AStage: TMaterialStage): AnsiString;
  public
    constructor Create(const ANamer: IMaterialImageNamer; const AOptions: TMaterialOptions);
    destructor Destroy; override;
    function GetNumStages: Integer;
    function GetStage(const AIndex: Integer): TMaterialStage;
    function GetBumpStageIndex: Integer;
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
    function GetLightFalloffImageName: AnsiString;
    function GetRenderBump: AnsiString;
    procedure SetMaterialFlag(const AFlag: Integer);
    procedure ClearMaterialFlag(const AFlag: Integer);
    function TestMaterialFlag(const AFlag: Integer): Boolean;
    function GetContentFlags: Integer;
    function GetSurfaceFlags: Integer;
    function GetSurfaceType: Integer;
    function GetDescription: AnsiString;
    function GetSort: Single;
    procedure SetSort(const ASort: Single);
    function Deform: TMaterialDeform;
    function GetDeformRegister(const AIndex: Integer): Integer;
    function GetDeformDecl: IDecl;
    function Texgen: TMaterialTexgen;
    function GetTexGenRegister(const AIndex: Integer): Integer;
    function GetCullType: TMaterialCullType;
    function GetEditorAlpha: Single;
    function GetEditorImageName: AnsiString;
    function GetEntityGui: Integer;
    function GetGuiName: AnsiString;
    function GetDecalInfo: TMaterialDecalInfo;
    function Spectrum: Integer;
    function GetPolygonOffset: Single;
    function GetSurfaceArea: Single;
    procedure AddToSurfaceArea(const AArea: Single);
    function SuppressInSubview: Boolean;
    function IsPortalSky: Boolean;
    function ImageName: AnsiString;
    function GetNumRegisters: Integer;
    function GetNumOps: Integer;
    function GetOp(const AIndex: Integer): TMaterialOp;
    function GetParsedRegister(const AIndex: Integer): Single;
    procedure EvaluateRegisters(var ARegisters: TArray<Single>; const AInput: TMaterialEvaluationInput);
    function ConstantRegisters: TArray<Single>;
    function Save(const AFileName: string = ''): Boolean;
    procedure ReloadImages(const AReloader: IMaterialImageReloader; const AForce: Boolean);
    function SetDefaultText: Boolean; override;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
    /// <summary>Writes the registers and the operations of the material to the log (idMaterial::Print)</summary>
    procedure Print; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Material.Parser, DelphiDoom.Decl.Material.Evaluator, DelphiDoom.Decl.Material.ImageNames;

const
  OP_NAMES: array[TMaterialOpType] of string = ('OP_TYPE_ADD', 'OP_TYPE_SUBTRACT', 'OP_TYPE_MULTIPLY',
    'OP_TYPE_DIVIDE', 'OP_TYPE_MOD', 'OP_TYPE_TABLE', 'OP_TYPE_GT', 'OP_TYPE_GE', 'OP_TYPE_LT', 'OP_TYPE_LE',
    'OP_TYPE_EQ', 'OP_TYPE_NE', 'OP_TYPE_AND', 'OP_TYPE_OR', 'OP_TYPE_SOUND');

{ TDeclMaterial }

constructor TDeclMaterial.Create(const ANamer: IMaterialImageNamer; const AOptions: TMaterialOptions);
begin
  inherited Create;
  if not Assigned(ANamer) then
    raise EDeclMaterialException.Create('a material needs a reader of image programs');
  FNamer := ANamer;
  FOptions := AOptions;
  FData := TMaterialData.Create;
end;

destructor TDeclMaterial.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

function TDeclMaterial.GetNumStages: Integer;
begin
  Result := Length(FData.Stages);
end;

function TDeclMaterial.Save(const AFileName: string): Boolean;
begin
  Result := ReplaceSourceFileText;
end;

procedure TDeclMaterial.ReloadImages(const AReloader: IMaterialImageReloader; const AForce: Boolean);
var
  LStage: TMaterialStage;
  LIndex: Integer;
begin
  if not Assigned(AReloader) then
    raise EArgumentNilException.Create('TDeclMaterial.ReloadImages: the reloader is nil');
  for LStage in FData.Stages do
    if LStage.HasNewStage then
    begin
      for LIndex := 0 to LStage.NewStage.NumFragmentImages - 1 do
        if LStage.NewStage.FragmentImages[LIndex].Name <> '' then
          AReloader.ReloadImage(LStage.NewStage.FragmentImages[LIndex], AForce);
    end
    else if LStage.Texture.HasImage then
      AReloader.ReloadImage(LStage.Texture.Image, AForce);
end;

function TDeclMaterial.GetStage(const AIndex: Integer): TMaterialStage;
begin
  if (AIndex < 0) or (AIndex >= Length(FData.Stages)) then
    raise EDeclMaterialException.CreateFmt('stage %d of material ''%s'' (it has %d)',
      [AIndex, string(GetName), Length(FData.Stages)]);
  Result := FData.Stages[AIndex];
end;

function TDeclMaterial.GetBumpStageIndex: Integer;
begin
  for Result := 0 to High(FData.Stages) do
    if FData.Stages[Result].Lighting = TMaterialLighting.Bump then
      Exit;
  Result := -1;
end;

function TDeclMaterial.IsDrawn: Boolean;
begin
  Result := (Length(FData.Stages) > 0) or (FData.EntityGui <> 0) or FData.HasGlobalGui;
end;

function TDeclMaterial.HasAmbient: Boolean;
begin
  Result := FData.NumAmbientStages > 0;
end;

function TDeclMaterial.HasGui: Boolean;
begin
  Result := (FData.EntityGui <> 0) or FData.HasGlobalGui;
end;

function TDeclMaterial.HasSubview: Boolean;
begin
  Result := FData.HasSubview;
end;

function TDeclMaterial.SurfaceCastsShadow: Boolean;
begin
  Result := TestMaterialFlag(MF_FORCESHADOWS) or not TestMaterialFlag(MF_NOSHADOWS);
end;

function TDeclMaterial.ReceivesFog: Boolean;
begin
  Result := IsDrawn and (not FData.NoFog) and (FData.Coverage <> TMaterialCoverage.Translucent);
end;

function TDeclMaterial.ReceivesLighting: Boolean;
begin
  Result := FData.NumAmbientStages <> Length(FData.Stages);
end;

function TDeclMaterial.ReceivesLightingOnBackSides: Boolean;
begin
  Result := (FData.MaterialFlags and (MF_NOSELFSHADOW or MF_NOSHADOWS)) <> 0;
end;

function TDeclMaterial.ShouldCreateBackSides: Boolean;
begin
  Result := FData.ShouldCreateBackSides;
end;

function TDeclMaterial.UseUnsmoothedTangents: Boolean;
begin
  Result := FData.UnsmoothedTangents;
end;

function TDeclMaterial.AllowOverlays: Boolean;
begin
  Result := FData.AllowOverlays;
end;

function TDeclMaterial.Coverage: TMaterialCoverage;
begin
  Result := FData.Coverage;
end;

function TDeclMaterial.HasHigherDmapPriority(const AOther: IDeclMaterial): Boolean;
begin
  Result := (IsDrawn and not AOther.IsDrawn) or (Coverage < AOther.Coverage);
end;

function TDeclMaterial.IsDiscrete: Boolean;
begin
  Result := (FData.EntityGui <> 0) or FData.HasGlobalGui or (FData.Deform <> TMaterialDeform.None)
    or (FData.Sort = SS_SUBVIEW) or ((FData.SurfaceFlags and SURF_DISCRETE) <> 0);
end;

function TDeclMaterial.NoFragment: Boolean;
begin
  Result := (FData.SurfaceFlags and SURF_NOFRAGMENT) <> 0;
end;

function TDeclMaterial.IsFogLight: Boolean;
begin
  Result := FData.FogLight;
end;

function TDeclMaterial.IsBlendLight: Boolean;
begin
  Result := FData.BlendLight;
end;

function TDeclMaterial.IsAmbientLight: Boolean;
begin
  Result := FData.AmbientLight;
end;

function TDeclMaterial.LightCastsShadows: Boolean;
begin
  Result := TestMaterialFlag(MF_FORCESHADOWS) or
    ((not FData.FogLight) and (not FData.AmbientLight) and (not FData.BlendLight) and
    (not TestMaterialFlag(MF_NOSHADOWS)));
end;

function TDeclMaterial.LightEffectsBackSides: Boolean;
begin
  Result := FData.FogLight or FData.AmbientLight or FData.BlendLight;
end;

function TDeclMaterial.GetLightFalloffImageName: AnsiString;
begin
  Result := FData.LightFalloffImageName;
end;

function TDeclMaterial.GetRenderBump: AnsiString;
begin
  Result := FData.RenderBump;
end;

procedure TDeclMaterial.SetMaterialFlag(const AFlag: Integer);
begin
  FData.MaterialFlags := FData.MaterialFlags or AFlag;
end;

procedure TDeclMaterial.ClearMaterialFlag(const AFlag: Integer);
begin
  FData.MaterialFlags := FData.MaterialFlags and not AFlag;
end;

function TDeclMaterial.TestMaterialFlag(const AFlag: Integer): Boolean;
begin
  Result := (FData.MaterialFlags and AFlag) <> 0;
end;

function TDeclMaterial.GetContentFlags: Integer;
begin
  Result := FData.ContentFlags;
end;

function TDeclMaterial.GetSurfaceFlags: Integer;
begin
  Result := FData.SurfaceFlags;
end;

function TDeclMaterial.GetSurfaceType: Integer;
begin
  Result := FData.SurfaceFlags and SURF_TYPE_MASK;
end;

function TDeclMaterial.GetDescription: AnsiString;
begin
  Result := FData.Description;
end;

function TDeclMaterial.GetSort: Single;
begin
  Result := FData.Sort;
end;

procedure TDeclMaterial.SetSort(const ASort: Single);
begin
  FData.Sort := ASort;
end;

function TDeclMaterial.Deform: TMaterialDeform;
begin
  Result := FData.Deform;
end;

function TDeclMaterial.GetDeformRegister(const AIndex: Integer): Integer;
begin
  Result := FData.DeformRegisters[AIndex];
end;

function TDeclMaterial.GetDeformDecl: IDecl;
begin
  Result := FData.DeformDecl;
end;

function TDeclMaterial.Texgen: TMaterialTexgen;
var
  LStage: TMaterialStage;
begin
  for LStage in FData.Stages do
    if LStage.Texture.Texgen <> TMaterialTexgen.Explicit then
      Exit(LStage.Texture.Texgen);
  Result := TMaterialTexgen.Explicit;
end;

function TDeclMaterial.GetTexGenRegister(const AIndex: Integer): Integer;
begin
  Result := FData.TexGenRegisters[AIndex];
end;

function TDeclMaterial.GetCullType: TMaterialCullType;
begin
  Result := FData.CullType;
end;

function TDeclMaterial.GetEditorAlpha: Single;
begin
  Result := FData.EditorAlpha;
end;

function TDeclMaterial.FirstStageImageName(const AStage: TMaterialStage): AnsiString;
begin
  if AStage.Texture.HasImage then
    Result := TMaterialImageNames.ResolvedName(AStage.Texture.Image.Name)
  else
    Result := '_default';
end;

function TDeclMaterial.GetEditorImageName: AnsiString;
var
  LIndex: Integer;
begin
  // look for an explicit one
  if FData.EditorImageName <> '' then
    Exit(TMaterialImageNames.ResolvedName(FData.EditorImageName));
  if Length(FData.Stages) = 0 then
    Exit('_default');
  // first check for a diffuse image, then use the first
  for LIndex := 0 to High(FData.Stages) do
    if FData.Stages[LIndex].Lighting = TMaterialLighting.Diffuse then
      Exit(FirstStageImageName(FData.Stages[LIndex]));
  Result := FirstStageImageName(FData.Stages[0]);
end;

function TDeclMaterial.GetEntityGui: Integer;
begin
  Result := FData.EntityGui;
end;

function TDeclMaterial.GetGuiName: AnsiString;
begin
  Result := FData.GuiName;
end;

function TDeclMaterial.GetDecalInfo: TMaterialDecalInfo;
begin
  Result := FData.DecalInfo;
end;

function TDeclMaterial.Spectrum: Integer;
begin
  Result := FData.Spectrum;
end;

function TDeclMaterial.GetPolygonOffset: Single;
begin
  Result := FData.PolygonOffset;
end;

function TDeclMaterial.GetSurfaceArea: Single;
begin
  Result := FData.SurfaceArea;
end;

procedure TDeclMaterial.AddToSurfaceArea(const AArea: Single);
begin
  FData.SurfaceArea := FData.SurfaceArea + AArea;
end;

function TDeclMaterial.SuppressInSubview: Boolean;
begin
  Result := FData.SuppressInSubview;
end;

function TDeclMaterial.IsPortalSky: Boolean;
begin
  Result := FData.PortalSky;
end;

function TDeclMaterial.ImageName: AnsiString;
begin
  if (Length(FData.Stages) = 0) or (not FData.Stages[0].Texture.HasImage) then
    Result := '_scratch'
  else
    Result := TMaterialImageNames.ResolvedName(FData.Stages[0].Texture.Image.Name);
end;

function TDeclMaterial.GetNumRegisters: Integer;
begin
  Result := Length(FData.ExpressionRegisters);
end;

function TDeclMaterial.GetNumOps: Integer;
begin
  Result := Length(FData.Ops);
end;

function TDeclMaterial.GetOp(const AIndex: Integer): TMaterialOp;
begin
  Result := FData.Ops[AIndex];
end;

function TDeclMaterial.GetParsedRegister(const AIndex: Integer): Single;
begin
  Result := FData.ExpressionRegisters[AIndex];
end;

procedure TDeclMaterial.EvaluateRegisters(var ARegisters: TArray<Single>;
  const AInput: TMaterialEvaluationInput);
var
  LEvaluator: TMaterialExpressionEvaluator;
begin
  LEvaluator := TMaterialExpressionEvaluator.Create(GetFinder);
  try
    LEvaluator.Evaluate(FData.ExpressionRegisters, FData.Ops, AInput, ARegisters);
  finally
    LEvaluator.Free;
  end;
end;

function TDeclMaterial.ConstantRegisters: TArray<Single>;
begin
  if FOptions.UseConstantMaterials then
    Result := FData.ConstantRegisters
  else
    Result := nil;
end;

function TDeclMaterial.SetDefaultText: Boolean;
begin
  // the original tests for an image file with this name and, as that test is commented out, always generates
  SetText(AnsiString(Format('material %s // IMPLICITLY GENERATED'#10'{'#10'{'#10'blend blend'#10'colored'#10
    + 'map "%s"'#10'clamp'#10'}'#10'}'#10, [string(GetName), string(GetName)])));
  Result := True;
end;

function TDeclMaterial.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'{'#10#9#9'blend'#9'blend'#10#9#9'map'#9#9'_default'#10#9'}'#10'}';
end;

function TDeclMaterial.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LParser: TMaterialParser;
  LParsed: Boolean;
begin
  LSource := OpenLexer(AText);
  try
    LParser := TMaterialParser.Create(GetName, GetLog, GetFinder, FNamer, FOptions);
    try
      LParsed := LParser.Parse(LSource, FData);
    finally
      LParser.Free;
    end;
  finally
    LSource.Free;
  end;
  // an error: the material falls back to the default one (and parses it)
  if not LParsed then
    MakeDefault;
  Result := LParsed;
end;

procedure TDeclMaterial.FreeData;
begin
  FData.Reset;
end;

function TDeclMaterial.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclMaterial.Print;
var
  LIndex: Integer;
  LOp: TMaterialOp;
  LLog: IIdLibLog;
  LDecl: IDecl;
  LFormat: TFormatSettings;
begin
  LLog := GetLog;
  if not Assigned(LLog) then
    Exit;
  LFormat := TFormatSettings.Invariant;
  for LIndex := EXP_REG_NUM_PREDEFINED to GetNumRegisters - 1 do
    LLog.Printf(Format('register %d: %.6f'#10, [LIndex, FData.ExpressionRegisters[LIndex]], LFormat));
  LLog.Printf(#10);
  for LOp in FData.Ops do
    if LOp.OpType = TMaterialOpType.Table then
    begin
      LDecl := GetFinder.DeclByIndex(DECL_TABLE, LOp.A);
      LLog.Printf(Format('%d = %s[ %d ]'#10, [LOp.C, string(LDecl.GetName), LOp.B]));
    end
    else
      LLog.Printf(Format('%d = %d %s %d'#10, [LOp.C, LOp.A, OP_NAMES[LOp.OpType], LOp.B]));
end;

end.
