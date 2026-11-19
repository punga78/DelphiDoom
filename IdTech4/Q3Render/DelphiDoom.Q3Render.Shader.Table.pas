{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the shader table }
{                                                                              }
{  R_FindShader (the key is the name and the lightmap index), the stages that  }
{  it makes for a shader that is only an image, CreateInternalShaders and the  }
{  sorted list of SortNewShader (renderer\tr_shader.c). Based on the Quake III }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Shader.Table;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Q3Render.Scene.Types,
  DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   The shaders by name and lightmap index. The script and the images come from the shader registry; here the
  ///   shader is made for a lightmap index: a shader of a script keeps its stages and learns its lightmap index (one
  ///   without a lightmap stage goes back to LIGHTMAP_NONE), one that is only an image gets the stages of
  ///   R_FindShader for that index (a lightmap and the image, vertex colours, the 2D state of the interface, the
  ///   white image). Every shader goes through the multitexture collapse (the graphics card of the renderer has two
  ///   texture units and the add environment)
  /// </summary>
  TQ3ShaderTable = class(TInterfacedObject, IQ3ShaderTable)
  strict private
    FRegistry: IQ3ShaderRegistry;
    FOptions: TQ3ShaderOptions;
    FEntries: TList<TQ3ShaderEntry>;
    FSorted: TList<Integer>;
    FIndex: TDictionary<string, Integer>;
    FLightmapCount: Integer;
    class function Key(const AName: AnsiString): string; static;
    procedure AddEntry(var AEntry: TQ3ShaderEntry);
    function MakeFromScript(const ABase: TQ3ShaderData; ALightmapIndex: Integer): TQ3ShaderData;
    function MakeFromImage(const ABase: TQ3ShaderData; ALightmapIndex: Integer): TQ3ShaderData;
    procedure CreateInternalShaders;
  public
    constructor Create(const ARegistry: IQ3ShaderRegistry);
    destructor Destroy; override;
    function FindShader(const AName: AnsiString; ALightmapIndex: Integer): Integer;
    function GetEntry(AIndex: Integer): TQ3ShaderEntry;
    function SortedIndexOf(AIndex: Integer): Integer;
    function GetSortedEntry(ASortedIndex: Integer): TQ3ShaderEntry;
    function Count: Integer;
    procedure SetLightmapCount(ACount: Integer);
    function GetLightmapCount: Integer;
    /// <summary>The shaders the renderer asks for at the start (projectionShadow, flareShader, sun)</summary>
    procedure RegisterExternalShaders;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.Context, DelphiDoom.Decl.Q3Shader.Finisher, DelphiDoom.Decl.Q3Shader.MultitextureCollapse;


constructor TQ3ShaderTable.Create(const ARegistry: IQ3ShaderRegistry);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  FRegistry := ARegistry;
  FOptions := TQ3ShaderOptions.Standard;
  FOptions.MultitextureAvailable := True;
  FOptions.TextureEnvAddAvailable := True;
  FEntries := TList<TQ3ShaderEntry>.Create;
  FSorted := TList<Integer>.Create;
  FIndex := TDictionary<string, Integer>.Create;
  CreateInternalShaders;
end;

destructor TQ3ShaderTable.Destroy;
begin
  FIndex.Free;
  FSorted.Free;
  FEntries.Free;
  inherited Destroy;
end;

class function TQ3ShaderTable.Key(const AName: AnsiString): string;
var
  LText: string;
  LDot: Integer;
begin
  // COM_StripExtension and the case: the hash of the shaders ignores it
  LText := LowerCase(StringReplace(string(AName), '\', '/', [rfReplaceAll]));
  LDot := LastDelimiter('.', LText);
  if (LDot > 0) and (LastDelimiter('/', LText) < LDot) then
    LText := Copy(LText, 1, LDot - 1);
  Result := LText;
end;

procedure TQ3ShaderTable.AddEntry(var AEntry: TQ3ShaderEntry);
var
  LPosition, LIndex: Integer;
  LEntry: TQ3ShaderEntry;
begin
  FEntries.Add(AEntry);
  // SortNewShader: from the end, the shaders that sort after the new one move up; it goes after the ones that
  // have the same sort (the order of registration is kept)
  LPosition := FSorted.Count - 1;
  while (LPosition >= 0) and (FEntries[FSorted[LPosition]].Data.Sort > AEntry.Data.Sort) do
    Dec(LPosition);
  FSorted.Insert(LPosition + 1, FEntries.Count - 1);
  for LIndex := 0 to FSorted.Count - 1 do
  begin
    LEntry := FEntries[FSorted[LIndex]];
    LEntry.SortedIndex := LIndex;
    FEntries[FSorted[LIndex]] := LEntry;
  end;
  AEntry := FEntries[FEntries.Count - 1];
end;

procedure TQ3ShaderTable.CreateInternalShaders;
var
  LContext: TQ3ShaderContext;
  LEntry: TQ3ShaderEntry;
begin
  // the default shader: the default image, no colour generation (CGEN_BAD), GLS_DEFAULT
  LContext := TQ3ShaderContext.Create('<default>', nil, FOptions);
  try
    LContext.Data.LightmapIndex := LIGHTMAP_NONE;
    LContext.Data.Stages[0].Active := True;
    LContext.Data.Stages[0].Bundle.ImageNames[0] := '*default';
    LContext.Data.Stages[0].StateBits := GLS_DEFAULT;
    TQ3ShaderFinisher.FinishShader(LContext);
    LEntry := Default(TQ3ShaderEntry);
    LEntry.Name := '<default>';
    LEntry.Data := LContext.Data^;
    LEntry.LightmapIndex := LIGHTMAP_NONE;
    LEntry.IsDefault := True;
  finally
    LContext.Free;
  end;
  AddEntry(LEntry);
  // the shadow shader is a marker: no stage, sort SS_STENCIL_SHADOW, which FinishShader turns into SS_FOG as the
  // C does for a shader with no passes
  LContext := TQ3ShaderContext.Create('<stencil shadow>', nil, FOptions);
  try
    LContext.Data.LightmapIndex := LIGHTMAP_NONE;
    LContext.Data.Sort := SS_STENCIL_SHADOW;
    TQ3ShaderFinisher.FinishShader(LContext);
    LEntry := Default(TQ3ShaderEntry);
    LEntry.Name := '<stencil shadow>';
    LEntry.Data := LContext.Data^;
    LEntry.LightmapIndex := LIGHTMAP_NONE;
  finally
    LContext.Free;
  end;
  AddEntry(LEntry);
end;

procedure TQ3ShaderTable.RegisterExternalShaders;
begin
  // CreateExternalShaders: the three shaders the renderer needs, all with LIGHTMAP_NONE
  FindShader('projectionShadow', LIGHTMAP_NONE);
  FindShader('flareShader', LIGHTMAP_NONE);
  FindShader('sun', LIGHTMAP_NONE);
end;

function TQ3ShaderTable.MakeFromScript(const ABase: TQ3ShaderData; ALightmapIndex: Integer): TQ3ShaderData;
var
  LStage: Integer;
  LHasLightmapStage: Boolean;
begin
  Result := ABase;
  // the collapse that the registry's reading left out (no second texture unit there): a pass that goes into the
  // one before it takes a stage off the count
  if (Result.NumUnfoggedPasses > 1) and TQ3ShaderMultitextureCollapse.Apply(Result, FOptions) then
    Dec(Result.NumUnfoggedPasses);
  LHasLightmapStage := False;
  for LStage := 0 to Q3_MAX_SHADER_STAGES - 1 do
  begin
    if not Result.Stages[LStage].Active then
      Break;
    if Result.Stages[LStage].Bundle.IsLightmap or Result.Stages[LStage].Bundle2.IsLightmap then
      LHasLightmapStage := True;
  end;
  // a lightmap that the shader does not use is no lightmap
  if (ALightmapIndex >= 0) and (not LHasLightmapStage) then
    Result.LightmapIndex := LIGHTMAP_NONE
  else
    Result.LightmapIndex := ALightmapIndex;
end;

function TQ3ShaderTable.MakeFromImage(const ABase: TQ3ShaderData; ALightmapIndex: Integer): TQ3ShaderData;
var
  LContext: TQ3ShaderContext;
  LImage: AnsiString;
  LData: PQ3ShaderData;
begin
  LImage := ABase.Stages[0].Bundle.ImageNames[0];
  LContext := TQ3ShaderContext.Create(ABase.Name, nil, FOptions);
  try
    LData := LContext.Data;
    LData.LightmapIndex := ALightmapIndex;
    if ALightmapIndex = LIGHTMAP_NONE then
    begin
      // dynamic colours at the vertexes
      LData.Stages[0].Bundle.ImageNames[0] := LImage;
      LData.Stages[0].Active := True;
      LData.Stages[0].RgbGen := cgLightingDiffuse;
      LData.Stages[0].StateBits := GLS_DEFAULT;
    end
    else if ALightmapIndex = LIGHTMAP_BY_VERTEX then
    begin
      // explicit colours at the vertexes
      LData.Stages[0].Bundle.ImageNames[0] := LImage;
      LData.Stages[0].Active := True;
      LData.Stages[0].RgbGen := cgExactVertex;
      LData.Stages[0].AlphaGen := agSkip;
      LData.Stages[0].StateBits := GLS_DEFAULT;
    end
    else if ALightmapIndex = LIGHTMAP_2D then
    begin
      // elements of the interface
      LData.Stages[0].Bundle.ImageNames[0] := LImage;
      LData.Stages[0].Active := True;
      LData.Stages[0].RgbGen := cgVertex;
      LData.Stages[0].AlphaGen := agVertex;
      LData.Stages[0].StateBits := GLS_DEPTHTEST_DISABLE or GLS_SRCBLEND_SRC_ALPHA or
        GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA;
    end
    else if ALightmapIndex = LIGHTMAP_WHITEIMAGE then
    begin
      // a fullbright level
      LData.Stages[0].Bundle.ImageNames[0] := '$whiteimage';
      LData.Stages[0].Active := True;
      LData.Stages[0].RgbGen := cgIdentityLighting;
      LData.Stages[0].StateBits := GLS_DEFAULT;
      LData.Stages[1].Bundle.ImageNames[0] := LImage;
      LData.Stages[1].Active := True;
      LData.Stages[1].RgbGen := cgIdentity;
      LData.Stages[1].StateBits := GLS_SRCBLEND_DST_COLOR or GLS_DSTBLEND_ZERO;
    end
    else
    begin
      // two passes: the lightmap (scaled when it was made) and the image times it
      LData.Stages[0].Bundle.ImageNames[0] := '$lightmap';
      LData.Stages[0].Bundle.IsLightmap := True;
      LData.Stages[0].Active := True;
      LData.Stages[0].RgbGen := cgIdentity;
      LData.Stages[0].StateBits := GLS_DEFAULT;
      LData.Stages[1].Bundle.ImageNames[0] := LImage;
      LData.Stages[1].Active := True;
      LData.Stages[1].RgbGen := cgIdentity;
      LData.Stages[1].StateBits := GLS_SRCBLEND_DST_COLOR or GLS_DSTBLEND_ZERO;
    end;
    TQ3ShaderFinisher.FinishShader(LContext);
    Result := LContext.Data^;
  finally
    LContext.Free;
  end;
end;

function TQ3ShaderTable.FindShader(const AName: AnsiString; ALightmapIndex: Integer): Integer;
var
  LKey: string;
  LHandle: Integer;
  LBase: TQ3ShaderData;
  LEntry: TQ3ShaderEntry;
begin
  if AName = '' then
    Exit(0);
  // vertex lighting where the BSP has no lightmaps
  if (ALightmapIndex >= 0) and (ALightmapIndex >= FLightmapCount) then
    ALightmapIndex := LIGHTMAP_BY_VERTEX;
  LKey := Key(AName) + '#' + IntToStr(ALightmapIndex);
  if FIndex.TryGetValue(LKey, Result) then
    Exit;
  LHandle := FRegistry.Register(AName);
  if (LHandle = 0) or not FRegistry.GetShader(LHandle, LBase) then
  begin
    FIndex.Add(LKey, 0);
    Exit(0);
  end;
  LEntry := Default(TQ3ShaderEntry);
  LEntry.Name := AnsiString(Key(AName));
  if LBase.ExplicitlyDefined then
    LEntry.Data := MakeFromScript(LBase, ALightmapIndex)
  else
    LEntry.Data := MakeFromImage(LBase, ALightmapIndex);
  LEntry.LightmapIndex := LEntry.Data.LightmapIndex;
  AddEntry(LEntry);
  Result := FEntries.Count - 1;
  FIndex.Add(LKey, Result);
end;

function TQ3ShaderTable.GetEntry(AIndex: Integer): TQ3ShaderEntry;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    AIndex := 0;
  Result := FEntries[AIndex];
end;

function TQ3ShaderTable.GetSortedEntry(ASortedIndex: Integer): TQ3ShaderEntry;
begin
  if (ASortedIndex < 0) or (ASortedIndex >= FSorted.Count) then
    Exit(FEntries[0]);
  Result := FEntries[FSorted[ASortedIndex]];
end;

function TQ3ShaderTable.SortedIndexOf(AIndex: Integer): Integer;
begin
  Result := GetEntry(AIndex).SortedIndex;
end;

function TQ3ShaderTable.Count: Integer;
begin
  Result := FEntries.Count;
end;

procedure TQ3ShaderTable.SetLightmapCount(ACount: Integer);
begin
  FLightmapCount := ACount;
end;

function TQ3ShaderTable.GetLightmapCount: Integer;
begin
  Result := FLightmapCount;
end;

end.
