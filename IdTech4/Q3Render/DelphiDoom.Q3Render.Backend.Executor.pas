{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the backend      }
{                                                                              }
{  RB_ExecuteRenderCommands, RB_DrawSurfs, RB_RenderDrawSurfList,              }
{  RB_BeginDrawingView, RB_SetGL2D, RB_StretchPic, RB_BeginSurface,            }
{  RB_EndSurface, RB_StageIteratorGeneric, RB_StageIteratorVertexLitTexture,   }
{  RB_StageIteratorLightmappedMultitexture, DrawMultitextured and the          }
{  surface functions RB_SurfaceFace and RB_SurfaceTriangles of renderer\       }
{  tr_backend.c, tr_shade.c and tr_surface.c, down to the stream of GL calls   }
{  (IQ3GlSink). Based on the Quake III Arena GPL Source Code (id Software).    }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Backend.Executor;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types,
  DelphiDoom.Decl.Q3Shader.Calc.Kit, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf,
  DelphiDoom.Q3Render.Backend.Gl, DelphiDoom.Q3Render.Backend.State, DelphiDoom.Q3Render.Frame.Commands;

type
  /// <summary>What the backend drew and what it left out (a surface kind that is not ported draws nothing)</summary>
  TQ3BackendStats = record
    Surfaces: Integer;
    Batches: Integer;
    Vertexes: Integer;
    Indexes: Integer;
    FacesDrawn: Integer;
    TrianglesDrawn: Integer;
    StretchPics: Integer;
    SkippedGrids: Integer;
    SkippedFlares: Integer;
    SkippedPolys: Integer;
    SkippedEntities: Integer;
    SkippedMd3: Integer;
    SkippedSky: Integer;
    SkippedDlightPasses: Integer;
    SkippedFogPasses: Integer;
  end;

  /// <summary>
  ///   The backend of the renderer: it executes the commands of a frame and the GL calls it would make go to the
  ///   sink. The state of the GL (bound textures, blend, culling) is tracked as the C tracks it. Texture numbers are
  ///   made up (1, 2, 3 ... in the order the images are first bound: no texture is ever created)
  /// </summary>
  /// <remarks>
  ///   Not ported, and counted in the stats: the grids of patches, flares, the surfaces of polys, sprites, beams and
  ///   md3 models, the sky, the dynamic light pass, the fog pass and the stencil shadows. The compiled vertex array
  ///   extension and two texture units are taken as there (glLockArraysEXT, the multitexture iterators), the colours
  ///   are those of overbright bits 1 (identity light 0.5)
  /// </remarks>
  TQ3Backend = class
  strict private
    const
      SHADER_MAX_VERTEXES = 1000;
      SHADER_MAX_INDEXES = 6 * SHADER_MAX_VERTEXES;
      PTR_XYZ = 1;
      PTR_TEXCOORDS0 = 2;
      PTR_TEXCOORDS1 = 3;
      PTR_SV_TEXCOORDS0 = 4;
      PTR_SV_TEXCOORDS1 = 5;
      PTR_SV_COLORS = 6;
      PTR_CONSTANT255 = 7;
  strict private
    FSink: IQ3GlSink;
    FState: TQ3GlState;
    FShaders: IQ3ShaderTable;
    FWorld: IQ3RenderWorld;
    FCalc: TQ3ShaderCalc;
    FVidWidth: Integer;
    FVidHeight: Integer;
    FNowMilliseconds: TFunc<Integer>;
    FTextureIds: TDictionary<string, Integer>;
    FStats: TQ3BackendStats;
    // tess
    FTess: TQ3ShaderTess;
    FTessShader: Integer;
    FTessEntry: TQ3ShaderEntry;
    FTessFog: Integer;
    FTessShaderTime: Single;
    FSvarColors: TBytes;
    FSvarTexCoords: array[0..1] of TArray<Single>;
    // backEnd
    FRefDef: TQ3RefDef;
    FFloatTime: Single;
    FView: TQ3FrontViewParms;
    FOrientation: TQ3ViewOrientation;
    FEntities: TArray<TQ3RefEntity>;
    FCurrentEntityWorld: Boolean;
    FCurrentEntity: TQ3RefEntity;
    FProjection2D: Boolean;
    FFinishCalled: Boolean;
    FColor2D: array[0..3] of Byte;
    // the client arrays: which source each pointer was last given
    FVertexPointer: Integer;
    FColorPointer: Integer;
    FTexCoordPointer: array[0..1] of Integer;
    FColorArray: Boolean;
    FTexCoordArray: array[0..1] of Boolean;
    function TextureNumber(const AName: AnsiString; ALightmapIndex: Integer): Integer;
    procedure BindImage(const AName: AnsiString; ALightmapIndex: Integer);
    procedure BindAnimatedImage(const ABundle: TQ3TextureBundle);
    procedure ClientState(AEnable: Boolean; ACapability: Cardinal);
    procedure SetPointer(const AName: string; ASize: Integer; AStride: Integer; ASource: Integer);
    function ArrayBlock(ASource, AStride: Integer): TBytes;
    procedure DrawElements;
    procedure CheckOverflow(AVertexes, AIndexes: Integer);
    procedure BeginSurface(AShader, AFogNumber: Integer);
    procedure EndSurface;
    procedure DeformGeometry;
    procedure ComputeStage(const AStage: TQ3ShaderStage);
    procedure DrawMultitextured(const AStage: TQ3ShaderStage);
    procedure StageIteratorGeneric;
    procedure StageIteratorVertexLitTexture;
    procedure StageIteratorLightmappedMultitexture;
    function IteratorKind(const AEntry: TQ3ShaderEntry): Integer;
    procedure SurfaceFace(AIndex: Integer);
    procedure SurfaceTriangles(AIndex: Integer);
    procedure SetGL2D;
    procedure BeginDrawingView;
    procedure RenderDrawSurfList(const ASurfaces: TArray<TQ3DrawSurf>);
    procedure StretchPic(const ACommand: TQ3RenderCommand);
    procedure DrawSurfs(const ACommand: TQ3RenderCommand);
    procedure MatrixCall(const AName: string; const AMatrix: array of Single);
    procedure PrepareTessEntity;
  public
    constructor Create(const ASink: IQ3GlSink; const AShaders: IQ3ShaderTable; AVidWidth, AVidHeight: Integer;
      const ANowMilliseconds: TFunc<Integer>);
    destructor Destroy; override;
    /// <summary>RE_LoadWorldMap: the surfaces the draw commands refer to (nil forgets them)</summary>
    procedure SetWorld(const AWorld: IQ3RenderWorld);
    /// <summary>RB_ExecuteRenderCommands</summary>
    procedure Execute(const ACommands: TQ3CommandList);
    property Stats: TQ3BackendStats read FStats;
    /// <summary>The number of images that got a texture number</summary>
    function TextureCount: Integer;
  end;

implementation

uses
  System.Math, DelphiDoom.Collision.Q3.Types, DelphiDoom.MapFile.Bsp.RenderTypes, DelphiDoom.MapFile.Bsp.Types,
  DelphiDoom.Decl.Q3Shader.Calc.StageColors, DelphiDoom.Decl.Q3Shader.Calc.LightCalc,
  DelphiDoom.Q3Render.View.Setup, DelphiDoom.Q3Render.Draw.List;

const
  // 0.5 and 127 for r_overBrightBits 1 (R_SetColorMappings: identityLight = 1 / (1 << overbrightBits))
  IdentityLight: Single = 0.5;
  IdentityLightByte = 127;
  Thousandth: Single = 0.001;
  // r_offsetFactor and r_offsetUnits
  OffsetFactor: Single = -1;
  OffsetUnits: Single = -2;

function FloatBytes(const AValues: TArray<Single>; ACount: Integer): TBytes;
begin
  SetLength(Result, ACount * 4);
  if ACount > 0 then
    Move(AValues[0], Result[0], ACount * 4);
end;

constructor TQ3Backend.Create(const ASink: IQ3GlSink; const AShaders: IQ3ShaderTable; AVidWidth,
  AVidHeight: Integer; const ANowMilliseconds: TFunc<Integer>);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  if not Assigned(AShaders) then
    raise EArgumentNilException.Create('AShaders');
  FSink := ASink;
  FState := TQ3GlState.Create(ASink);
  FShaders := AShaders;
  FCalc := TQ3ShaderCalc.Create;
  FVidWidth := AVidWidth;
  FVidHeight := AVidHeight;
  FNowMilliseconds := ANowMilliseconds;
  FTextureIds := TDictionary<string, Integer>.Create;
  FTessShader := -1;
  SetLength(FTess.Xyz, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.Normal, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.TexCoords, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.VertexColors, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.Indexes, SHADER_MAX_INDEXES);
  SetLength(FSvarColors, SHADER_MAX_VERTEXES * 4);
  for LIndex := 0 to 1 do
    SetLength(FSvarTexCoords[LIndex], SHADER_MAX_VERTEXES * 2);
  FTess.Entity.AmbientLightInt := 0;
end;

destructor TQ3Backend.Destroy;
begin
  FTextureIds.Free;
  FCalc.Free;
  FState.Free;
  inherited Destroy;
end;

procedure TQ3Backend.SetWorld(const AWorld: IQ3RenderWorld);
begin
  FWorld := AWorld;
end;

function TQ3Backend.TextureCount: Integer;
begin
  Result := FTextureIds.Count;
end;

function TQ3Backend.TextureNumber(const AName: AnsiString; ALightmapIndex: Integer): Integer;
var
  LKey: string;
begin
  // the images the renderer makes itself: the lightmap of the shader, the white image when there is none
  if AName = '$lightmap' then
  begin
    if ALightmapIndex >= 0 then
      LKey := 'lightmap:' + IntToStr(ALightmapIndex)
    else
      LKey := '$whiteimage';
  end
  else
    LKey := LowerCase(string(AName));
  if not FTextureIds.TryGetValue(LKey, Result) then
  begin
    Result := FTextureIds.Count + 1;
    FTextureIds.Add(LKey, Result);
  end;
end;

procedure TQ3Backend.BindImage(const AName: AnsiString; ALightmapIndex: Integer);
begin
  FState.Bind(TextureNumber(AName, ALightmapIndex));
end;

procedure TQ3Backend.BindAnimatedImage(const ABundle: TQ3TextureBundle);
var
  LIndex: Integer;
begin
  // a video map runs the cinematic and uploads it: no GL call that a sink can show
  if ABundle.IsVideoMap then
    Exit;
  if ABundle.NumImageAnimations <= 1 then
  begin
    BindImage(ABundle.ImageNames[0], FTessEntry.LightmapIndex);
    Exit;
  end;
  // the animation lines up with the waveforms of the same frequency
  LIndex := TQ3CMath.FloatToInt(FTessShaderTime * ABundle.ImageAnimationSpeed * Q3_FUNCTABLE_SIZE);
  LIndex := LIndex div Q3_FUNCTABLE_SIZE;
  if LIndex < 0 then
    LIndex := 0;
  LIndex := LIndex mod ABundle.NumImageAnimations;
  BindImage(ABundle.ImageNames[LIndex], FTessEntry.LightmapIndex);
end;

procedure TQ3Backend.ClientState(AEnable: Boolean; ACapability: Cardinal);
begin
  if AEnable then
    FSink.Call('glEnableClientState', [TQ3GlArg.FromEnum(ACapability)])
  else
    FSink.Call('glDisableClientState', [TQ3GlArg.FromEnum(ACapability)]);
  case ACapability of
    GL_COLOR_ARRAY:
      FColorArray := AEnable;
    GL_TEXTURE_COORD_ARRAY:
      FTexCoordArray[FState.CurrentTmu] := AEnable;
  end;
end;

procedure TQ3Backend.SetPointer(const AName: string; ASize, AStride, ASource: Integer);
var
  LType: Cardinal;
begin
  if AName = 'glColorPointer' then
    LType := GL_UNSIGNED_BYTE
  else
    LType := GL_FLOAT;
  // the pointer is symbolic: the number says which buffer of the renderer it is
  FSink.Call(AName, [TQ3GlArg.FromInt(ASize), TQ3GlArg.FromEnum(LType), TQ3GlArg.FromInt(AStride),
    TQ3GlArg.FromInt(ASource)]);
  if AName = 'glVertexPointer' then
    FVertexPointer := ASource
  else if AName = 'glColorPointer' then
    FColorPointer := ASource
  else
    FTexCoordPointer[FState.CurrentTmu] := ASource;
end;

function TQ3Backend.ArrayBlock(ASource, AStride: Integer): TBytes;
var
  LIndex, LComponent, LCount: Integer;
  LValues: TArray<Single>;
begin
  LCount := FTess.NumVertexes;
  case ASource of
    PTR_XYZ:
      begin
        SetLength(LValues, LCount * 3);
        for LIndex := 0 to LCount - 1 do
          for LComponent := 0 to 2 do
            LValues[LIndex * 3 + LComponent] := FTess.Xyz[LIndex * 4 + LComponent];
        Result := FloatBytes(LValues, LCount * 3);
      end;
    PTR_TEXCOORDS0, PTR_TEXCOORDS1:
      begin
        SetLength(LValues, LCount * 2);
        for LIndex := 0 to LCount - 1 do
          for LComponent := 0 to 1 do
            LValues[LIndex * 2 + LComponent] := FTess.TexCoords[LIndex * 4 + (ASource - PTR_TEXCOORDS0) * 2 + LComponent];
        Result := FloatBytes(LValues, LCount * 2);
      end;
    PTR_SV_TEXCOORDS0, PTR_SV_TEXCOORDS1:
      Result := FloatBytes(FSvarTexCoords[ASource - PTR_SV_TEXCOORDS0], LCount * 2);
    PTR_SV_COLORS:
      Result := Copy(FSvarColors, 0, LCount * 4);
    PTR_CONSTANT255:
      begin
        SetLength(Result, LCount * 4);
        for LIndex := 0 to High(Result) do
          Result[LIndex] := $FF;
      end;
  else
    SetLength(Result, 0);
  end;
end;

procedure TQ3Backend.DrawElements;
var
  LIndexes: TBytes;
  LIndex: Integer;
  LTex0, LTex1, LColors: TBytes;
begin
  // R_DrawElements with the compiled vertex arrays of the card: triangles
  SetLength(LIndexes, FTess.NumIndexes * 4);
  for LIndex := 0 to FTess.NumIndexes - 1 do
    PCardinal(@LIndexes[LIndex * 4])^ := Cardinal(FTess.Indexes[LIndex]);
  SetLength(LTex0, 0);
  SetLength(LTex1, 0);
  SetLength(LColors, 0);
  if FTexCoordArray[0] then
    LTex0 := ArrayBlock(FTexCoordPointer[0], 0);
  if FTexCoordArray[1] then
    LTex1 := ArrayBlock(FTexCoordPointer[1], 0);
  if FColorArray then
    LColors := ArrayBlock(FColorPointer, 0);
  // what the card reads through the pointers is part of the call: the arrays follow the elements
  FSink.Call('glDrawElements', [TQ3GlArg.FromEnum(GL_TRIANGLES), TQ3GlArg.FromInt(FTess.NumIndexes),
    TQ3GlArg.FromEnum(GL_UNSIGNED_INT), TQ3GlArg.FromBytes(LIndexes),
    TQ3GlArg.FromBytes(ArrayBlock(FVertexPointer, 16)), TQ3GlArg.FromBytes(LTex0), TQ3GlArg.FromBytes(LTex1),
    TQ3GlArg.FromBytes(LColors)]);
end;

procedure TQ3Backend.MatrixCall(const AName: string; const AMatrix: array of Single);
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AMatrix) * 4);
  for LIndex := 0 to High(AMatrix) do
    PSingle(@LBytes[LIndex * 4])^ := AMatrix[LIndex];
  FSink.Call(AName, [TQ3GlArg.FromBytes(LBytes)]);
end;

procedure TQ3Backend.PrepareTessEntity;
var
  LAxis: Integer;
begin
  FTess.Entity := Default(TQ3EntityShading);
  FTess.Entity.Present := True;
  FTess.Entity.IsWorld := FCurrentEntityWorld;
  if FCurrentEntityWorld then
  begin
    for LAxis := 0 to 3 do
      FTess.Entity.ShaderRGBA[LAxis] := 0;
  end
  else
  begin
    for LAxis := 0 to 3 do
      FTess.Entity.ShaderRGBA[LAxis] := FCurrentEntity.ShaderRGBA[LAxis];
    FTess.Entity.ShaderTexCoord[0] := FCurrentEntity.ShaderTexCoord[0];
    FTess.Entity.ShaderTexCoord[1] := FCurrentEntity.ShaderTexCoord[1];
  end;
  for LAxis := 0 to 2 do
  begin
    FTess.View.Origin[LAxis] := FView.Orientation.Origin[LAxis];
    FTess.View.Axis[0][LAxis] := FView.Orientation.Axis[0][LAxis];
    FTess.View.Axis[1][LAxis] := FView.Orientation.Axis[1][LAxis];
    FTess.View.Axis[2][LAxis] := FView.Orientation.Axis[2][LAxis];
    FTess.ViewOrigin[LAxis] := FOrientation.ViewOrigin[LAxis];
    FTess.Orientation.Origin[LAxis] := FOrientation.Origin[LAxis];
    FTess.Orientation.Axis[0][LAxis] := FOrientation.Axis[0][LAxis];
    FTess.Orientation.Axis[1][LAxis] := FOrientation.Axis[1][LAxis];
    FTess.Orientation.Axis[2][LAxis] := FOrientation.Axis[2][LAxis];
  end;
  FTess.View.IsMirror := FView.IsMirror;
  for LAxis := 0 to 15 do
    FTess.Orientation.ModelMatrix[LAxis] := FOrientation.ModelMatrix[LAxis];
end;

procedure TQ3Backend.BeginSurface(AShader, AFogNumber: Integer);
begin
  FTess.NumIndexes := 0;
  FTess.NumVertexes := 0;
  FTessShader := AShader;
  FTessEntry := FShaders.GetEntry(AShader);
  FTessFog := AFogNumber;
  FTessShaderTime := FFloatTime;
  if (FTessEntry.Data.ClampTime <> 0) and (FTessShaderTime >= FTessEntry.Data.ClampTime) then
    FTessShaderTime := FTessEntry.Data.ClampTime;
end;

function TQ3Backend.IteratorKind(const AEntry: TQ3ShaderEntry): Integer;
var
  LData: TQ3ShaderData;
begin
  // ComputeStageIteratorFunc: 0 generic, 1 sky, 2 vertex lit texture, 3 lightmapped multitexture
  LData := AEntry.Data;
  Result := 0;
  if LData.IsSky then
    Exit(1);
  if LData.NumUnfoggedPasses = 1 then
  begin
    if (LData.Stages[0].RgbGen = cgLightingDiffuse) and (LData.Stages[0].AlphaGen = agIdentity) and
      (LData.Stages[0].Bundle.TcGen = tgTexture) and (not LData.PolygonOffset) and
      (LData.MultitextureEnv = meNone) and (LData.NumDeforms = 0) then
      Exit(2);
    if (LData.Stages[0].RgbGen = cgIdentity) and (LData.Stages[0].AlphaGen = agIdentity) and
      (LData.Stages[0].Bundle.TcGen = tgTexture) and (LData.Stages[0].Bundle2.TcGen = tgLightmap) and
      (not LData.PolygonOffset) and (LData.NumDeforms = 0) and (LData.MultitextureEnv <> meNone) then
      Exit(3);
  end;
end;

procedure TQ3Backend.EndSurface;
begin
  if FTess.NumIndexes = 0 then
    Exit;
  // the stencil shadow marker has nothing to draw here
  if FTessShader = 1 then
  begin
    FTess.NumIndexes := 0;
    Exit;
  end;
  Inc(FStats.Batches);
  Inc(FStats.Vertexes, FTess.NumVertexes);
  Inc(FStats.Indexes, FTess.NumIndexes);
  PrepareTessEntity;
  FTess.ShaderTime := FTessShaderTime;
  FTess.RefDefTime := FRefDef.Time;
  case IteratorKind(FTessEntry) of
    1:
      Inc(FStats.SkippedSky);
    2:
      StageIteratorVertexLitTexture;
    3:
      StageIteratorLightmappedMultitexture;
  else
    StageIteratorGeneric;
  end;
  FTess.NumIndexes := 0;
end;

procedure TQ3Backend.CheckOverflow(AVertexes, AIndexes: Integer);
var
  LShader, LFog: Integer;
begin
  if (FTess.NumVertexes + AVertexes < SHADER_MAX_VERTEXES) and (FTess.NumIndexes + AIndexes < SHADER_MAX_INDEXES) then
    Exit;
  EndSurface;
  if AVertexes >= SHADER_MAX_VERTEXES then
    raise EArgumentException.CreateFmt('RB_CheckOverflow: verts > MAX (%d > %d)', [AVertexes, SHADER_MAX_VERTEXES]);
  if AIndexes >= SHADER_MAX_INDEXES then
    raise EArgumentException.CreateFmt('RB_CheckOverflow: indices > MAX (%d > %d)', [AIndexes, SHADER_MAX_INDEXES]);
  LShader := FTessShader;
  LFog := FTessFog;
  BeginSurface(LShader, LFog);
end;

procedure TQ3Backend.DeformGeometry;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FTessEntry.Data.NumDeforms - 1 do
    FCalc.Deforms.Apply(FTessEntry.Data.Deforms[LIndex], FTess);
end;

procedure TQ3Backend.ComputeStage(const AStage: TQ3ShaderStage);
var
  LLighting: TQ3StageLighting;
  LBundle: Integer;
begin
  LLighting.IdentityLight := IdentityLight;
  LLighting.IdentityLightByte := IdentityLightByte;
  LLighting.PortalRange := FTessEntry.Data.PortalRange;
  // the fog pass and the fog colours are not ported: the surface is computed as if it were out of the fog
  FTess.FogNumber := 0;
  FCalc.StageColors.Compute(AStage, FTess, LLighting, FSvarColors);
  for LBundle := 0 to 1 do
  begin
    if LBundle = 0 then
      FCalc.TexCoords.Compute(AStage.Bundle, FTess, FSvarTexCoords[0])
    else
      FCalc.TexCoords.Compute(AStage.Bundle2, FTess, FSvarTexCoords[1]);
  end;
end;

procedure TQ3Backend.DrawMultitextured(const AStage: TQ3ShaderStage);
begin
  FState.State(AStage.StateBits);
  // the base
  FState.SelectTexture(0);
  SetPointer('glTexCoordPointer', 2, 0, PTR_SV_TEXCOORDS0);
  BindAnimatedImage(AStage.Bundle);
  // the lightmap or the second pass
  FState.SelectTexture(1);
  FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_TEXTURE_2D)]);
  ClientState(True, GL_TEXTURE_COORD_ARRAY);
  if FTessEntry.Data.MultitextureEnv = meAdd then
    FState.TexEnv(GL_ADD)
  else
    FState.TexEnv(GL_MODULATE);
  SetPointer('glTexCoordPointer', 2, 0, PTR_SV_TEXCOORDS1);
  BindAnimatedImage(AStage.Bundle2);
  DrawElements;
  // texturing off on the second unit, then back to the first
  FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_TEXTURE_2D)]);
  FState.SelectTexture(0);
end;

procedure TQ3Backend.StageIteratorGeneric;
var
  LStage: Integer;
  LSetArraysOnce: Boolean;
begin
  DeformGeometry;
  FState.Cull(Ord(FTessEntry.Data.CullType), FView.IsMirror);
  if FTessEntry.Data.PolygonOffset then
  begin
    FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_POLYGON_OFFSET_FILL)]);
    FSink.Call('glPolygonOffset', [TQ3GlArg.FromSingle(OffsetFactor), TQ3GlArg.FromSingle(OffsetUnits)]);
  end;
  // one pass: the colour and texture arrays are set before the lock; several: they change from pass to pass
  if (FTessEntry.Data.NumUnfoggedPasses > 1) or (FTessEntry.Data.MultitextureEnv <> meNone) then
  begin
    LSetArraysOnce := False;
    ClientState(False, GL_COLOR_ARRAY);
    ClientState(False, GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    LSetArraysOnce := True;
    ClientState(True, GL_COLOR_ARRAY);
    SetPointer('glColorPointer', 4, 0, PTR_SV_COLORS);
    ClientState(True, GL_TEXTURE_COORD_ARRAY);
    SetPointer('glTexCoordPointer', 2, 0, PTR_SV_TEXCOORDS0);
  end;
  SetPointer('glVertexPointer', 3, 16, PTR_XYZ);
  FSink.Call('glLockArraysEXT', [TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(FTess.NumVertexes)]);
  if not LSetArraysOnce then
  begin
    ClientState(True, GL_TEXTURE_COORD_ARRAY);
    ClientState(True, GL_COLOR_ARRAY);
  end;
  // RB_IterateStagesGeneric
  for LStage := 0 to Q3_MAX_SHADER_STAGES - 1 do
  begin
    if (LStage >= FTessEntry.Data.NumUnfoggedPasses) or (not FTessEntry.Data.Stages[LStage].Active) then
      Break;
    ComputeStage(FTessEntry.Data.Stages[LStage]);
    if not LSetArraysOnce then
    begin
      ClientState(True, GL_COLOR_ARRAY);
      SetPointer('glColorPointer', 4, 0, PTR_SV_COLORS);
    end;
    if FTessEntry.Data.Stages[LStage].Bundle2.ImageNames[0] <> '' then
      DrawMultitextured(FTessEntry.Data.Stages[LStage])
    else
    begin
      if not LSetArraysOnce then
        SetPointer('glTexCoordPointer', 2, 0, PTR_SV_TEXCOORDS0);
      BindAnimatedImage(FTessEntry.Data.Stages[LStage].Bundle);
      FState.State(FTessEntry.Data.Stages[LStage].StateBits);
      DrawElements;
    end;
  end;
  // the dynamic lights and the fog are not drawn
  if (FTessFog <> 0) and (FTessEntry.Data.FogPass <> fpNone) then
    Inc(FStats.SkippedFogPasses);
  FSink.Call('glUnlockArraysEXT', []);
  if FTessEntry.Data.PolygonOffset then
    FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_POLYGON_OFFSET_FILL)]);
end;

procedure TQ3Backend.StageIteratorVertexLitTexture;
begin
  // RB_CalcDiffuseColor into the colours of the stage
  FTess.FogNumber := 0;
  TQ3LightCalc.CalcDiffuseColor(FTess, FSvarColors);
  FState.Cull(Ord(FTessEntry.Data.CullType), FView.IsMirror);
  ClientState(True, GL_COLOR_ARRAY);
  ClientState(True, GL_TEXTURE_COORD_ARRAY);
  SetPointer('glColorPointer', 4, 0, PTR_SV_COLORS);
  SetPointer('glTexCoordPointer', 2, 16, PTR_TEXCOORDS0);
  SetPointer('glVertexPointer', 3, 16, PTR_XYZ);
  FSink.Call('glLockArraysEXT', [TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(FTess.NumVertexes)]);
  BindAnimatedImage(FTessEntry.Data.Stages[0].Bundle);
  FState.State(FTessEntry.Data.Stages[0].StateBits);
  DrawElements;
  if (FTessFog <> 0) and (FTessEntry.Data.FogPass <> fpNone) then
    Inc(FStats.SkippedFogPasses);
  FSink.Call('glUnlockArraysEXT', []);
end;

procedure TQ3Backend.StageIteratorLightmappedMultitexture;
begin
  FState.Cull(Ord(FTessEntry.Data.CullType), FView.IsMirror);
  // the colour is constant (all 255: the lightmaps are scaled when they are made)
  FState.State(GLS_DEFAULT);
  SetPointer('glVertexPointer', 3, 16, PTR_XYZ);
  ClientState(True, GL_COLOR_ARRAY);
  SetPointer('glColorPointer', 4, 0, PTR_CONSTANT255);
  // the base stage
  FState.SelectTexture(0);
  ClientState(True, GL_TEXTURE_COORD_ARRAY);
  BindAnimatedImage(FTessEntry.Data.Stages[0].Bundle);
  SetPointer('glTexCoordPointer', 2, 16, PTR_TEXCOORDS0);
  // the second stage
  FState.SelectTexture(1);
  FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_TEXTURE_2D)]);
  FState.TexEnv(GL_MODULATE);
  BindAnimatedImage(FTessEntry.Data.Stages[0].Bundle2);
  ClientState(True, GL_TEXTURE_COORD_ARRAY);
  SetPointer('glTexCoordPointer', 2, 16, PTR_TEXCOORDS1);
  FSink.Call('glLockArraysEXT', [TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(FTess.NumVertexes)]);
  DrawElements;
  FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_TEXTURE_2D)]);
  ClientState(False, GL_TEXTURE_COORD_ARRAY);
  FState.SelectTexture(0);
  if (FTessFog <> 0) and (FTessEntry.Data.FogPass <> fpNone) then
    Inc(FStats.SkippedFogPasses);
  FSink.Call('glUnlockArraysEXT', []);
end;

procedure TQ3Backend.SurfaceFace(AIndex: Integer);
var
  LFace: TBspFaceSurface;
  LIndex, LNumber, LAxis: Integer;
begin
  LFace := FWorld.GetFaces[AIndex];
  CheckOverflow(Length(LFace.Points), Length(LFace.Indexes));
  LNumber := FTess.NumVertexes;
  for LIndex := 0 to High(LFace.Indexes) do
    FTess.Indexes[FTess.NumIndexes + LIndex] := LFace.Indexes[LIndex] + LNumber;
  Inc(FTess.NumIndexes, Length(LFace.Indexes));
  // needsNormal is always set: the normal of the plane for every point
  for LIndex := 0 to High(LFace.Points) do
  begin
    for LAxis := 0 to 2 do
    begin
      FTess.Normal[(LNumber + LIndex) * 4 + LAxis] := LFace.PlaneNormal[LAxis];
      FTess.Xyz[(LNumber + LIndex) * 4 + LAxis] := LFace.Points[LIndex].Xyz[LAxis];
    end;
    FTess.TexCoords[(LNumber + LIndex) * 4] := LFace.Points[LIndex].St[0];
    FTess.TexCoords[(LNumber + LIndex) * 4 + 1] := LFace.Points[LIndex].St[1];
    FTess.TexCoords[(LNumber + LIndex) * 4 + 2] := LFace.Points[LIndex].Lightmap[0];
    FTess.TexCoords[(LNumber + LIndex) * 4 + 3] := LFace.Points[LIndex].Lightmap[1];
    for LAxis := 0 to 3 do
      FTess.VertexColors[(LNumber + LIndex) * 4 + LAxis] := LFace.Points[LIndex].Color[LAxis];
  end;
  Inc(FTess.NumVertexes, Length(LFace.Points));
  Inc(FStats.FacesDrawn);
end;

procedure TQ3Backend.SurfaceTriangles(AIndex: Integer);
var
  LSurface: TBspTriangleSurface;
  LIndex, LNumber, LAxis: Integer;
begin
  LSurface := FWorld.GetTriangleSurfaces[AIndex];
  CheckOverflow(Length(LSurface.Verts), Length(LSurface.Indexes));
  LNumber := FTess.NumVertexes;
  for LIndex := 0 to High(LSurface.Indexes) do
    FTess.Indexes[FTess.NumIndexes + LIndex] := LNumber + LSurface.Indexes[LIndex];
  Inc(FTess.NumIndexes, Length(LSurface.Indexes));
  for LIndex := 0 to High(LSurface.Verts) do
  begin
    for LAxis := 0 to 2 do
    begin
      FTess.Xyz[(LNumber + LIndex) * 4 + LAxis] := LSurface.Verts[LIndex].Xyz[LAxis];
      FTess.Normal[(LNumber + LIndex) * 4 + LAxis] := LSurface.Verts[LIndex].Normal[LAxis];
    end;
    FTess.TexCoords[(LNumber + LIndex) * 4] := LSurface.Verts[LIndex].St[0];
    FTess.TexCoords[(LNumber + LIndex) * 4 + 1] := LSurface.Verts[LIndex].St[1];
    FTess.TexCoords[(LNumber + LIndex) * 4 + 2] := LSurface.Verts[LIndex].Lightmap[0];
    FTess.TexCoords[(LNumber + LIndex) * 4 + 3] := LSurface.Verts[LIndex].Lightmap[1];
    for LAxis := 0 to 3 do
      FTess.VertexColors[(LNumber + LIndex) * 4 + LAxis] := LSurface.Verts[LIndex].Color[LAxis];
  end;
  Inc(FTess.NumVertexes, Length(LSurface.Verts));
  Inc(FStats.TrianglesDrawn);
end;

procedure TQ3Backend.SetGL2D;
begin
  FProjection2D := True;
  // the virtual screen
  FSink.Call('glViewport', [TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(FVidWidth),
    TQ3GlArg.FromInt(FVidHeight)]);
  FSink.Call('glScissor', [TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(0), TQ3GlArg.FromInt(FVidWidth),
    TQ3GlArg.FromInt(FVidHeight)]);
  FSink.Call('glMatrixMode', [TQ3GlArg.FromEnum(GL_PROJECTION)]);
  FSink.Call('glLoadIdentity', []);
  FSink.Call('glOrtho', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(FVidWidth), TQ3GlArg.FromDouble(FVidHeight),
    TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(1)]);
  FSink.Call('glMatrixMode', [TQ3GlArg.FromEnum(GL_MODELVIEW)]);
  FSink.Call('glLoadIdentity', []);
  FState.State(GLS_DEPTHTEST_DISABLE or GLS_SRCBLEND_SRC_ALPHA or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA);
  FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_CULL_FACE)]);
  FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_CLIP_PLANE0)]);
  // the time of the 2D shaders
  FRefDef.Time := FNowMilliseconds();
  FFloatTime := FRefDef.Time * Thousandth;
end;

procedure TQ3Backend.StretchPic(const ACommand: TQ3RenderCommand);
var
  LVertexes, LIndexes, LIndex: Integer;
begin
  if not FProjection2D then
    SetGL2D;
  if ACommand.Shader <> FTessShader then
  begin
    if FTess.NumIndexes <> 0 then
      EndSurface;
    FCurrentEntityWorld := False;
    FCurrentEntity := Default(TQ3RefEntity);
    for LIndex := 0 to 3 do
      FCurrentEntity.ShaderRGBA[LIndex] := 255;
    BeginSurface(ACommand.Shader, 0);
  end;
  CheckOverflow(4, 6);
  LVertexes := FTess.NumVertexes;
  LIndexes := FTess.NumIndexes;
  Inc(FTess.NumVertexes, 4);
  Inc(FTess.NumIndexes, 6);
  FTess.Indexes[LIndexes] := LVertexes + 3;
  FTess.Indexes[LIndexes + 1] := LVertexes + 0;
  FTess.Indexes[LIndexes + 2] := LVertexes + 2;
  FTess.Indexes[LIndexes + 3] := LVertexes + 2;
  FTess.Indexes[LIndexes + 4] := LVertexes + 0;
  FTess.Indexes[LIndexes + 5] := LVertexes + 1;
  for LIndex := 0 to 3 do
  begin
    FTess.VertexColors[(LVertexes + LIndex) * 4] := FColor2D[0];
    FTess.VertexColors[(LVertexes + LIndex) * 4 + 1] := FColor2D[1];
    FTess.VertexColors[(LVertexes + LIndex) * 4 + 2] := FColor2D[2];
    FTess.VertexColors[(LVertexes + LIndex) * 4 + 3] := FColor2D[3];
    FTess.Xyz[(LVertexes + LIndex) * 4 + 2] := 0;
  end;
  FTess.Xyz[LVertexes * 4] := ACommand.X;
  FTess.Xyz[LVertexes * 4 + 1] := ACommand.Y;
  FTess.TexCoords[LVertexes * 4] := ACommand.S1;
  FTess.TexCoords[LVertexes * 4 + 1] := ACommand.T1;
  FTess.Xyz[(LVertexes + 1) * 4] := ACommand.X + ACommand.W;
  FTess.Xyz[(LVertexes + 1) * 4 + 1] := ACommand.Y;
  FTess.TexCoords[(LVertexes + 1) * 4] := ACommand.S2;
  FTess.TexCoords[(LVertexes + 1) * 4 + 1] := ACommand.T1;
  FTess.Xyz[(LVertexes + 2) * 4] := ACommand.X + ACommand.W;
  FTess.Xyz[(LVertexes + 2) * 4 + 1] := ACommand.Y + ACommand.H;
  FTess.TexCoords[(LVertexes + 2) * 4] := ACommand.S2;
  FTess.TexCoords[(LVertexes + 2) * 4 + 1] := ACommand.T2;
  FTess.Xyz[(LVertexes + 3) * 4] := ACommand.X;
  FTess.Xyz[(LVertexes + 3) * 4 + 1] := ACommand.Y + ACommand.H;
  FTess.TexCoords[(LVertexes + 3) * 4] := ACommand.S1;
  FTess.TexCoords[(LVertexes + 3) * 4 + 1] := ACommand.T2;
  Inc(FStats.StretchPics);
end;

procedure TQ3Backend.BeginDrawingView;
var
  LBits: Cardinal;
begin
  // the projection is changed before 2D images are drawn again
  FProjection2D := False;
  FSink.Call('glMatrixMode', [TQ3GlArg.FromEnum(GL_PROJECTION)]);
  MatrixCall('glLoadMatrixf', FView.ProjectionMatrix);
  FSink.Call('glMatrixMode', [TQ3GlArg.FromEnum(GL_MODELVIEW)]);
  FSink.Call('glViewport', [TQ3GlArg.FromInt(FView.ViewportX), TQ3GlArg.FromInt(FView.ViewportY),
    TQ3GlArg.FromInt(FView.ViewportWidth), TQ3GlArg.FromInt(FView.ViewportHeight)]);
  FSink.Call('glScissor', [TQ3GlArg.FromInt(FView.ViewportX), TQ3GlArg.FromInt(FView.ViewportY),
    TQ3GlArg.FromInt(FView.ViewportWidth), TQ3GlArg.FromInt(FView.ViewportHeight)]);
  // r_finish is 0: no glFinish, and the swap does not need one
  FFinishCalled := True;
  // the depth writes are on for the depth clear
  FState.State(GLS_DEFAULT);
  LBits := GL_DEPTH_BUFFER_BIT;
  FSink.Call('glClear', [TQ3GlArg.FromInt(LBits)]);
  FState.ForgetFaceCulling;
  FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_CLIP_PLANE0)]);
end;

procedure TQ3Backend.RenderDrawSurfList(const ASurfaces: TArray<TQ3DrawSurf>);
var
  LIndex, LEntity, LSortedShader, LFog, LDlight: Integer;
  LOldEntity, LOldFog, LOldDlighted, LShader, LOldShaderSorted: Integer;
  LOldSort: Int64;
  LDepthRange, LOldDepthRange, LHaveShader: Boolean;
  LEntry: TQ3ShaderEntry;
  LOriginalTime: Single;
  LSurface: TQ3SurfaceRef;
begin
  LOriginalTime := FFloatTime;
  BeginDrawingView;
  LOldEntity := -1;
  FCurrentEntityWorld := True;
  FCurrentEntity := Default(TQ3RefEntity);
  LHaveShader := False;
  LOldFog := -1;
  LOldDepthRange := False;
  LOldDlighted := 0;
  LOldSort := -1;
  LOldShaderSorted := -1;
  LDepthRange := False;
  Inc(FStats.Surfaces, Length(ASurfaces));
  for LIndex := 0 to High(ASurfaces) do
  begin
    LSurface := ASurfaces[LIndex].Surface;
    if Int64(ASurfaces[LIndex].Sort) <> LOldSort then
    begin
      LOldSort := ASurfaces[LIndex].Sort;
      TQ3DrawList.Decompose(ASurfaces[LIndex].Sort, LEntity, LSortedShader, LFog, LDlight);
      LEntry := FShaders.GetSortedEntry(LSortedShader);
      LShader := FShaders.GetSortedShader(LSortedShader);
      // a new batch when the shader, the fog or the dlights change (or the entity, if the shader is not mergable)
      if (not LHaveShader) or (LSortedShader <> LOldShaderSorted) or (LFog <> LOldFog) or (LDlight <> LOldDlighted) or
        ((LEntity <> LOldEntity) and (not LEntry.Data.EntityMergable)) then
      begin
        if LHaveShader then
          EndSurface;
        BeginSurface(LShader, LFog);
        LHaveShader := True;
        LOldShaderSorted := LSortedShader;
        LOldFog := LFog;
        LOldDlighted := LDlight;
      end;
      // the modelview matrix of the entity
      if LEntity <> LOldEntity then
      begin
        LDepthRange := False;
        if LEntity <> Q3_ENTITYNUM_WORLD then
        begin
          if LEntity < Length(FEntities) then
            FCurrentEntity := FEntities[LEntity]
          else
            FCurrentEntity := Default(TQ3RefEntity);
          FCurrentEntityWorld := False;
          FFloatTime := LOriginalTime - FCurrentEntity.ShaderTime;
          FTessShaderTime := FFloatTime;
          TQ3ViewSetup.RotateForEntity(FCurrentEntity, FView, FOrientation);
          // the weapon is drawn in a part of the depth range so that it does not poke into walls
          if (FCurrentEntity.RenderFx and RF_DEPTHHACK) <> 0 then
            LDepthRange := True;
        end
        else
        begin
          FCurrentEntityWorld := True;
          FCurrentEntity := Default(TQ3RefEntity);
          FFloatTime := LOriginalTime;
          FOrientation := FView.World;
          FTessShaderTime := FFloatTime;
        end;
        MatrixCall('glLoadMatrixf', FOrientation.ModelMatrix);
        if LOldDepthRange <> LDepthRange then
        begin
          if LDepthRange then
            FSink.Call('glDepthRange', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(0.3)])
          else
            FSink.Call('glDepthRange', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(1)]);
          LOldDepthRange := LDepthRange;
        end;
        LOldEntity := LEntity;
      end;
    end;
    // the triangles of the surface
    case LSurface.Kind of
      skFace:
        SurfaceFace(FWorld.GetSurfaces[LSurface.Index].DataIndex);
      skTriangles:
        SurfaceTriangles(FWorld.GetSurfaces[LSurface.Index].DataIndex);
      skGrid:
        Inc(FStats.SkippedGrids);
      skFlare:
        Inc(FStats.SkippedFlares);
      skPoly:
        Inc(FStats.SkippedPolys);
      skEntity:
        Inc(FStats.SkippedEntities);
      skMd3:
        Inc(FStats.SkippedMd3);
    end;
  end;
  FFloatTime := LOriginalTime;
  // the contents of the last batch
  if LHaveShader then
    EndSurface;
  // back to the modelview matrix of the world
  MatrixCall('glLoadMatrixf', FView.World.ModelMatrix);
  if LDepthRange then
    FSink.Call('glDepthRange', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(1)]);
end;

procedure TQ3Backend.DrawSurfs(const ACommand: TQ3RenderCommand);
begin
  // the 2D that is still waiting
  if FTess.NumIndexes <> 0 then
    EndSurface;
  FRefDef := ACommand.RefDef;
  FFloatTime := ACommand.FloatTime;
  FView := ACommand.View;
  FEntities := ACommand.Entities;
  RenderDrawSurfList(ACommand.DrawSurfs);
end;

procedure TQ3Backend.Execute(const ACommands: TQ3CommandList);
var
  LIndex, LChannel: Integer;
  LCommand: TQ3RenderCommand;
  LValue: Single;
begin
  for LIndex := 0 to ACommands.Count - 1 do
  begin
    LCommand := ACommands.Item(LIndex);
    case LCommand.Kind of
      rcSetColor:
        for LChannel := 0 to 3 do
        begin
          LValue := LCommand.Color[LChannel] * 255;
          FColor2D[LChannel] := Byte(Trunc(LValue));
        end;
      rcStretchPic:
        StretchPic(LCommand);
      rcDrawSurfs:
        DrawSurfs(LCommand);
      rcDrawBuffer:
        begin
          FFinishCalled := False;
          FSink.Call('glDrawBuffer', [TQ3GlArg.FromEnum(LCommand.Buffer)]);
        end;
      rcSwapBuffers:
        begin
          // the 2D that is still waiting
          if FTess.NumIndexes <> 0 then
            EndSurface;
          if not FFinishCalled then
            FSink.Call('glFinish', []);
          FProjection2D := False;
        end;
    end;
  end;
end;

end.
