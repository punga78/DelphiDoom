{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - shader table     }
{                                                                              }
{  R_FindShader and RE_RegisterShader of renderer\tr_shader.c as data: the     }
{  parsing is IdTech4\Decl (Q3Shader); this unit adds what the parser leaves   }
{  to the renderer, the images of the stages. Based on the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Shader.Registry;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Q3Shader.Types,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   The shaders a game asks for by name. A shader of a script is read by the declaration manager of IdTech4\Decl
  ///   (the shader type, folder scripts/*.shader); one without a script is the implicit shader of an image. Every
  ///   image of a stage is loaded through the image catalog: if one is missing the shader is defective, as in the C
  ///   (ParseStage fails, shader.defaultShader is set, RE_RegisterShader answers 0). The images of a sky are
  ///   loaded and may be missing (the C uses the default image for them)
  /// </summary>
  TQ3ShaderRegistry = class(TInterfacedObject, IQ3ShaderRegistry)
  strict private
    FFinder: IDeclFinder;
    FImages: IQ3ImageCatalog;
    FHandles: TDictionary<string, Integer>;
    FShaders: TList<TQ3ShaderData>;
    FDefective: TList<string>;
    FDefined: Integer;
    FImplicit: Integer;
    class function Key(const AName: AnsiString): string; static;
    function StagesLoad(const AShader: TQ3ShaderData): Boolean;
    function BundleLoads(const ABundle: TQ3TextureBundle): Boolean;
  public
    constructor Create(const AFinder: IDeclFinder; const AImages: IQ3ImageCatalog);
    destructor Destroy; override;
    function Register(const AName: AnsiString): Integer;
    function GetShader(AHandle: Integer; out AShader: TQ3ShaderData): Boolean;
    function RegisteredCount: Integer;
    function DefinedCount: Integer;
    function ImplicitCount: Integer;
    function DefectiveNames: TArray<string>;
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Q3Shader.Intf;

constructor TQ3ShaderRegistry.Create(const AFinder: IDeclFinder; const AImages: IQ3ImageCatalog);
begin
  inherited Create;
  if not Assigned(AFinder) then
    raise EArgumentNilException.Create('AFinder');
  if not Assigned(AImages) then
    raise EArgumentNilException.Create('AImages');
  FFinder := AFinder;
  FImages := AImages;
  FHandles := TDictionary<string, Integer>.Create;
  FShaders := TList<TQ3ShaderData>.Create;
  FDefective := TList<string>.Create;
end;

destructor TQ3ShaderRegistry.Destroy;
begin
  FHandles.Free;
  FShaders.Free;
  FDefective.Free;
  inherited Destroy;
end;

class function TQ3ShaderRegistry.Key(const AName: AnsiString): string;
var
  LText: string;
  LDot: Integer;
begin
  // COM_StripExtension and the slashes the way the declaration manager canonicalises its names
  LText := LowerCase(StringReplace(string(AName), '\', '/', [rfReplaceAll]));
  LDot := LastDelimiter('.', LText);
  if (LDot > 0) and (LastDelimiter('/', LText) < LDot) then
    LText := Copy(LText, 1, LDot - 1);
  Result := LText;
end;

function TQ3ShaderRegistry.BundleLoads(const ABundle: TQ3TextureBundle): Boolean;
var
  LIndex: Integer;
  LName: AnsiString;
begin
  Result := True;
  if ABundle.IsLightmap or ABundle.IsVideoMap then
    Exit;
  // a plain map has only image[0] (numImageAnimations stays 0 unless it is an animMap)
  for LIndex := 0 to System.Math.Max(ABundle.NumImageAnimations, 1) - 1 do
  begin
    LName := ABundle.ImageNames[LIndex];
    // $whiteimage and $lightmap, and the images whose names start with * ("*white", "*default", "*scratch")
    // are made by the renderer itself
    if (LName = '') or (LName[1] = '$') or (LName[1] = '*') then
      Continue;
    if FImages.Find(LName) = 0 then
      Result := False;
  end;
end;

function TQ3ShaderRegistry.StagesLoad(const AShader: TQ3ShaderData): Boolean;
var
  LStage, LIndex: Integer;
begin
  Result := True;
  for LStage := 0 to Q3_MAX_SHADER_STAGES - 1 do
  begin
    if not AShader.Stages[LStage].Active then
      Break;
    if not BundleLoads(AShader.Stages[LStage].Bundle) then
      Result := False;
    if AShader.Stages[LStage].Bundle2.ImageNames[0] <> '' then
      if not BundleLoads(AShader.Stages[LStage].Bundle2) then
        Result := False;
  end;
  if AShader.IsSky then
  begin
    for LIndex := 0 to 5 do
    begin
      if (AShader.Sky.OuterBox[LIndex] <> '') and (AShader.Sky.OuterBox[LIndex] <> '-') then
        FImages.Find(AShader.Sky.OuterBox[LIndex]);
      if (AShader.Sky.InnerBox[LIndex] <> '') and (AShader.Sky.InnerBox[LIndex] <> '-') then
        FImages.Find(AShader.Sky.InnerBox[LIndex]);
    end;
  end;
end;

function TQ3ShaderRegistry.Register(const AName: AnsiString): Integer;
var
  LKey: string;
  LDecl: IDecl;
  LShader: IDeclQ3Shader;
  LData: TQ3ShaderData;
begin
  if (AName = '') or (Length(AName) >= Q3_RENDER_MAX_QPATH) then
    Exit(0);
  LKey := Key(AName);
  if FHandles.TryGetValue(LKey, Result) then
    Exit;
  Result := 0;
  LDecl := FFinder.FindType(DECL_Q3SHADER, AnsiString(LKey), True);
  if not Supports(LDecl, IDeclQ3Shader, LShader) then
  begin
    FDefective.Add(string(AName));
    FHandles.Add(LKey, 0);
    Exit;
  end;
  LData := LShader.GetData;
  // the stage images are loaded even when the parser already gave up: the C stops at the first image it cannot
  // find, so a shader after it is not touched; here the warning list says which images are missing
  if LShader.IsDefaultShader or not StagesLoad(LData) then
  begin
    FDefective.Add(string(AName));
    FHandles.Add(LKey, 0);
    Exit;
  end;
  if LShader.IsExplicitlyDefined then
    Inc(FDefined)
  else
    Inc(FImplicit);
  FShaders.Add(LData);
  Result := FShaders.Count;
  FHandles.Add(LKey, Result);
end;

function TQ3ShaderRegistry.GetShader(AHandle: Integer; out AShader: TQ3ShaderData): Boolean;
begin
  Result := (AHandle >= 1) and (AHandle <= FShaders.Count);
  if Result then
    AShader := FShaders[AHandle - 1]
  else
    AShader := Default(TQ3ShaderData);
end;

function TQ3ShaderRegistry.RegisteredCount: Integer;
begin
  Result := FShaders.Count;
end;

function TQ3ShaderRegistry.DefinedCount: Integer;
begin
  Result := FDefined;
end;

function TQ3ShaderRegistry.ImplicitCount: Integer;
begin
  Result := FImplicit;
end;

function TQ3ShaderRegistry.DefectiveNames: TArray<string>;
begin
  Result := FDefective.ToArray;
end;

end.
