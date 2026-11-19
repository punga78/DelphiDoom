{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - the renderer     }
{  that cgame and ui see                                                       }
{                                                                              }
{  Implements IQ3HostRenderer of IdTech4\Q3Host on top of the shader, model    }
{  and world tables of this library. Based on the Quake III Arena GPL Source   }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Host.Adapter;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Qvm.Intf,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Render.Types,
  DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Frame.Renderer;

type
  /// <summary>
  ///   A decorator: every call goes to the inner IQ3HostRenderer (the recording renderer of Q3Host, which keeps its
  ///   numbers and its counters: the handles cgame and ui get are the recorder's, and the number of system calls a
  ///   module makes is the same as with the recorder alone), and the registrations also load the real thing:
  ///   RegisterShader and RegisterShaderNoMip read the script and the images of the stages, RegisterModel reads the
  ///   md3 (with its shaders), LoadWorld loads the BSP into surface lists. **Three answers change**, where the loaded
  ///   data give a real one in place of the neutral one of the recorder: ModelBounds of a model that loaded,
  ///   LerpTag of a tag that exists (the result is then 1), and InPVS once a world is loaded. Everything else (the
  ///   scene, the 2D calls, fonts, skins, decals, LightForPoint, the glconfig) is the recorder's. **R1 (AttachRenderer):**
  ///   the scene and the 2D calls also go to a TQ3Renderer (front end and backend over a recorder of GL calls), with
  ///   the frames opened by BeginFrame and closed by EndFrame; the answers to the module do not change
  /// </summary>
  TQ3HostRendererAdapter = class(TInterfacedObject, IQ3HostRenderer)
  strict private
    FInner: IQ3HostRenderer;
    FShaders: IQ3ShaderRegistry;
    FModels: IQ3ModelRegistry;
    FWorldLoader: IQ3WorldLoader;
    FLog: ILog;
    FWorld: IQ3RenderWorld;
    FModelHandles: TDictionary<Integer, Integer>;
    FHostShaders: TDictionary<Integer, Integer>;
    FTable: IQ3ShaderTable;
    FRenderer: TQ3Renderer;
    procedure Warn(const AText: string);
  public
    constructor Create(const AInner: IQ3HostRenderer; const AShaders: IQ3ShaderRegistry;
      const AModels: IQ3ModelRegistry; const AWorldLoader: IQ3WorldLoader; const ALog: ILog = nil);
    destructor Destroy; override;
    procedure LoadWorld(const AName: AnsiString);
    function RegisterModel(const AName: AnsiString): Integer;
    function RegisterSkin(const AName: AnsiString): Integer;
    function RegisterShader(const AName: AnsiString): Integer;
    function RegisterShaderNoMip(const AName: AnsiString): Integer;
    procedure RegisterFont(const AMemory: IQvmMemory; const AName: AnsiString; APointSize, AFontAddress: Integer);
    procedure ClearScene;
    procedure AddRefEntityToScene(const AMemory: IQvmMemory; AAddress: Integer);
    procedure AddPolyToScene(const AMemory: IQvmMemory; AShader, ANumVerts, AVertsAddress, ANumPolys: Integer);
    procedure AddLightToScene(const AOrigin: TQ3HostVec3; AIntensity, ARed, AGreen, ABlue: Single;
      AAdditive: Boolean);
    procedure RenderScene(const AMemory: IQvmMemory; AAddress: Integer);
    procedure SetColor(const AMemory: IQvmMemory; AAddress: Integer);
    procedure DrawStretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single; AShader: Integer);
    procedure ModelBounds(const AMemory: IQvmMemory; AModel, AMinsAddress, AMaxsAddress: Integer);
    function LerpTag(const AMemory: IQvmMemory; ATagAddress, AModel, AStartFrame, AEndFrame: Integer;
      AFraction: Single; const ATagName: AnsiString): Integer;
    function InPVS(const APoint1, APoint2: TQ3HostVec3): Integer;
    function LightForPoint(const AMemory: IQvmMemory; const APoint: TQ3HostVec3;
      AAmbientAddress, ADirectedAddress, ALightDirAddress: Integer): Integer;
    procedure RemapShader(const AOldShader, ANewShader, ATimeOffset: AnsiString);
    function MarkFragments(const AMemory: IQvmMemory; ANumPoints, APointsAddress, AProjectionAddress,
      AMaxPoints, APointBufferAddress, AMaxFragments, AFragmentBufferAddress: Integer): Integer;
    function GlConfig: TBytes;
    /// <summary>The world of the last LoadWorld that found its file (nil before)</summary>
    property World: IQ3RenderWorld read FWorld;
    /// <summary>
    ///   R1: the adapter also builds the scene of the module into a TQ3Renderer (which it owns) and draws it into the
    ///   recorder of GL calls between BeginFrame and EndFrame. The shader table is the one the renderer uses
    /// </summary>
    procedure AttachRenderer(const ATable: IQ3ShaderTable; const ARenderer: TQ3Renderer);
    /// <summary>The index in the shader table of a shader handle of the module (0, the default shader, if unknown)</summary>
    function HostShaderEntry(AHostHandle: Integer): Integer;
    /// <summary>The handle in the model registry of a model handle of the module (0 if unknown)</summary>
    function HostModelHandle(AHostHandle: Integer): Integer;
    /// <summary>SCR_UpdateScreen starts a frame of the renderer (RE_BeginFrame)</summary>
    procedure BeginFrame;
    /// <summary>... and ends it (RE_EndFrame): the commands run and the frame of the recorder closes with the label</summary>
    procedure EndFrame(const ALabel: string);
    property Renderer: TQ3Renderer read FRenderer;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Models.Static.Md3.Intf, DelphiDoom.Q3Host.Arguments,
  DelphiDoom.Q3Render.Scene.Types,
  DelphiDoom.Q3Render.Scene.Reader;

constructor TQ3HostRendererAdapter.Create(const AInner: IQ3HostRenderer; const AShaders: IQ3ShaderRegistry;
  const AModels: IQ3ModelRegistry; const AWorldLoader: IQ3WorldLoader; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  if not Assigned(AShaders) then
    raise EArgumentNilException.Create('AShaders');
  if not Assigned(AModels) then
    raise EArgumentNilException.Create('AModels');
  if not Assigned(AWorldLoader) then
    raise EArgumentNilException.Create('AWorldLoader');
  FInner := AInner;
  FShaders := AShaders;
  FModels := AModels;
  FWorldLoader := AWorldLoader;
  FLog := ALog;
  FModelHandles := TDictionary<Integer, Integer>.Create;
  FHostShaders := TDictionary<Integer, Integer>.Create;
end;

destructor TQ3HostRendererAdapter.Destroy;
begin
  FRenderer.Free;
  FHostShaders.Free;
  FModelHandles.Free;
  inherited Destroy;
end;

procedure TQ3HostRendererAdapter.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

procedure TQ3HostRendererAdapter.AttachRenderer(const ATable: IQ3ShaderTable; const ARenderer: TQ3Renderer);
begin
  FTable := ATable;
  FRenderer := ARenderer;
  if Assigned(FRenderer) and Assigned(FWorld) then
    FRenderer.LoadWorld(FWorld);
end;

function TQ3HostRendererAdapter.HostShaderEntry(AHostHandle: Integer): Integer;
begin
  if not FHostShaders.TryGetValue(AHostHandle, Result) then
    Result := 0;
end;

function TQ3HostRendererAdapter.HostModelHandle(AHostHandle: Integer): Integer;
begin
  if not FModelHandles.TryGetValue(AHostHandle, Result) then
    Result := 0;
end;

procedure TQ3HostRendererAdapter.BeginFrame;
begin
  if Assigned(FRenderer) then
    FRenderer.BeginFrame;
end;

procedure TQ3HostRendererAdapter.EndFrame(const ALabel: string);
begin
  if Assigned(FRenderer) then
    FRenderer.EndFrame(ALabel);
end;

procedure TQ3HostRendererAdapter.LoadWorld(const AName: AnsiString);
begin
  FInner.LoadWorld(AName);
  try
    FWorld := FWorldLoader.Load(AName);
  except
    on E: EQ3RenderException do
    begin
      FWorld := nil;
      if Assigned(FLog) then
        FLog.Warning(E.Message);
    end;
  end;
  FModels.SetWorld(FWorld);
  if Assigned(FRenderer) then
    FRenderer.LoadWorld(FWorld);
end;

function TQ3HostRendererAdapter.RegisterModel(const AName: AnsiString): Integer;
var
  LHandle, LSurface: Integer;
  LModel: IMd3Model;
  LName: AnsiString;
begin
  Result := FInner.RegisterModel(AName);
  LHandle := FModels.Register(AName);
  if LHandle > 0 then
  begin
    FModelHandles.AddOrSetValue(Result, LHandle);
    // R_LoadMD3 registers the shaders of the surfaces with LIGHTMAP_NONE when the model is registered: the place
    // of a shader in the sorted list depends on the order of registration
    if Assigned(FTable) then
    begin
      LModel := FModels.GetModel(LHandle);
      if Assigned(LModel) then
        for LSurface := 0 to LModel.NumSurfaces - 1 do
          for LName in LModel.Surfaces[LSurface].Shaders do
            if LName <> '' then
              FTable.FindShader(LName, LIGHTMAP_NONE);
    end;
  end;
end;

function TQ3HostRendererAdapter.RegisterSkin(const AName: AnsiString): Integer;
begin
  Result := FInner.RegisterSkin(AName);
end;

function TQ3HostRendererAdapter.RegisterShader(const AName: AnsiString): Integer;
begin
  Result := FInner.RegisterShader(AName);
  FShaders.Register(AName);
  // RE_RegisterShader: R_FindShader(name, LIGHTMAP_2D); a defective shader is entry 0
  if Assigned(FTable) then
    FHostShaders.AddOrSetValue(Result, FTable.FindShader(AName, LIGHTMAP_2D));
end;

function TQ3HostRendererAdapter.RegisterShaderNoMip(const AName: AnsiString): Integer;
begin
  Result := FInner.RegisterShaderNoMip(AName);
  FShaders.Register(AName);
  if Assigned(FTable) then
    FHostShaders.AddOrSetValue(Result, FTable.FindShader(AName, LIGHTMAP_2D));
end;

procedure TQ3HostRendererAdapter.RegisterFont(const AMemory: IQvmMemory; const AName: AnsiString;
  APointSize, AFontAddress: Integer);
begin
  FInner.RegisterFont(AMemory, AName, APointSize, AFontAddress);
end;

procedure TQ3HostRendererAdapter.ClearScene;
begin
  FInner.ClearScene;
  if Assigned(FRenderer) then
    FRenderer.ClearScene;
end;

procedure TQ3HostRendererAdapter.AddRefEntityToScene(const AMemory: IQvmMemory; AAddress: Integer);
begin
  FInner.AddRefEntityToScene(AMemory, AAddress);
  if not Assigned(FRenderer) then
    Exit;
  try
    FRenderer.AddRefEntity(TQ3SceneReader.ReadRefEntity(AMemory, AAddress));
  except
    // ri.Error(ERR_DROP): the module's call is dropped, the program goes on
    on E: EQ3RenderException do
      Warn(E.Message);
  end;
end;

procedure TQ3HostRendererAdapter.AddPolyToScene(const AMemory: IQvmMemory; AShader, ANumVerts, AVertsAddress,
  ANumPolys: Integer);
begin
  FInner.AddPolyToScene(AMemory, AShader, ANumVerts, AVertsAddress, ANumPolys);
  if Assigned(FRenderer) and (ANumVerts > 0) and (ANumPolys > 0) then
    FRenderer.AddPolys(AShader, ANumVerts, TQ3SceneReader.ReadPolyVerts(AMemory, AVertsAddress,
      ANumVerts * ANumPolys), ANumPolys);
end;

procedure TQ3HostRendererAdapter.AddLightToScene(const AOrigin: TQ3HostVec3; AIntensity, ARed, AGreen,
  ABlue: Single; AAdditive: Boolean);
var
  LOrigin: TQ3Vec3;
begin
  FInner.AddLightToScene(AOrigin, AIntensity, ARed, AGreen, ABlue, AAdditive);
  if not Assigned(FRenderer) then
    Exit;
  LOrigin[0] := AOrigin[0];
  LOrigin[1] := AOrigin[1];
  LOrigin[2] := AOrigin[2];
  FRenderer.AddLight(LOrigin, AIntensity, ARed, AGreen, ABlue, AAdditive);
end;

procedure TQ3HostRendererAdapter.RenderScene(const AMemory: IQvmMemory; AAddress: Integer);
begin
  FInner.RenderScene(AMemory, AAddress);
  if not Assigned(FRenderer) then
    Exit;
  try
    FRenderer.RenderScene(TQ3SceneReader.ReadRefDef(AMemory, AAddress));
  except
    on E: EQ3RenderException do
      Warn(E.Message);
  end;
end;

procedure TQ3HostRendererAdapter.SetColor(const AMemory: IQvmMemory; AAddress: Integer);
begin
  FInner.SetColor(AMemory, AAddress);
  if Assigned(FRenderer) then
    FRenderer.SetColor(TQ3SceneReader.ReadColor(AMemory, AAddress));
end;

procedure TQ3HostRendererAdapter.DrawStretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single;
  AShader: Integer);
begin
  FInner.DrawStretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2, AShader);
  if Assigned(FRenderer) then
    FRenderer.StretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2, AShader);
end;

procedure TQ3HostRendererAdapter.ModelBounds(const AMemory: IQvmMemory; AModel, AMinsAddress,
  AMaxsAddress: Integer);
var
  LHandle, LIndex: Integer;
  LMins, LMaxs: TQ3RenderVec3;
begin
  if FModelHandles.TryGetValue(AModel, LHandle) and FModels.ModelBounds(LHandle, LMins, LMaxs) then
  begin
    // the inner renderer counts the call too
    FInner.ModelBounds(AMemory, AModel, AMinsAddress, AMaxsAddress);
    for LIndex := 0 to 2 do
    begin
      AMemory.WriteInt32(AMinsAddress + 4 * LIndex, TQ3SyscallArguments.FromSingle(LMins[LIndex]));
      AMemory.WriteInt32(AMaxsAddress + 4 * LIndex, TQ3SyscallArguments.FromSingle(LMaxs[LIndex]));
    end;
  end
  else
    FInner.ModelBounds(AMemory, AModel, AMinsAddress, AMaxsAddress);
end;

function TQ3HostRendererAdapter.LerpTag(const AMemory: IQvmMemory; ATagAddress, AModel, AStartFrame,
  AEndFrame: Integer; AFraction: Single; const ATagName: AnsiString): Integer;
var
  LHandle, LAxis, LComponent: Integer;
  LOrigin: TQ3RenderVec3;
  LAxes: TQ3RenderAxis;
begin
  Result := FInner.LerpTag(AMemory, ATagAddress, AModel, AStartFrame, AEndFrame, AFraction, ATagName);
  if FModelHandles.TryGetValue(AModel, LHandle) and
    FModels.LerpTag(LHandle, AStartFrame, AEndFrame, AFraction, ATagName, LOrigin, LAxes) then
  begin
    // orientation_t: origin, then the three axes (48 bytes)
    for LComponent := 0 to 2 do
      AMemory.WriteInt32(ATagAddress + 4 * LComponent, TQ3SyscallArguments.FromSingle(LOrigin[LComponent]));
    for LAxis := 0 to 2 do
      for LComponent := 0 to 2 do
        AMemory.WriteInt32(ATagAddress + 12 + 12 * LAxis + 4 * LComponent,
          TQ3SyscallArguments.FromSingle(LAxes[LAxis][LComponent]));
    Result := 1;
  end;
end;

function TQ3HostRendererAdapter.InPVS(const APoint1, APoint2: TQ3HostVec3): Integer;
var
  LFirst, LSecond: TQ3RenderVec3;
  LIndex: Integer;
begin
  Result := FInner.InPVS(APoint1, APoint2);
  if Assigned(FWorld) then
  begin
    for LIndex := 0 to 2 do
    begin
      LFirst[LIndex] := APoint1[LIndex];
      LSecond[LIndex] := APoint2[LIndex];
    end;
    if FWorld.InPvs(LFirst, LSecond) then
      Result := 1
    else
      Result := 0;
  end;
end;

function TQ3HostRendererAdapter.LightForPoint(const AMemory: IQvmMemory; const APoint: TQ3HostVec3;
  AAmbientAddress, ADirectedAddress, ALightDirAddress: Integer): Integer;
begin
  Result := FInner.LightForPoint(AMemory, APoint, AAmbientAddress, ADirectedAddress, ALightDirAddress);
end;

procedure TQ3HostRendererAdapter.RemapShader(const AOldShader, ANewShader, ATimeOffset: AnsiString);
begin
  FInner.RemapShader(AOldShader, ANewShader, ATimeOffset);
end;

function TQ3HostRendererAdapter.MarkFragments(const AMemory: IQvmMemory; ANumPoints, APointsAddress,
  AProjectionAddress, AMaxPoints, APointBufferAddress, AMaxFragments, AFragmentBufferAddress: Integer): Integer;
begin
  Result := FInner.MarkFragments(AMemory, ANumPoints, APointsAddress, AProjectionAddress, AMaxPoints,
    APointBufferAddress, AMaxFragments, AFragmentBufferAddress);
end;

function TQ3HostRendererAdapter.GlConfig: TBytes;
begin
  Result := FInner.GlConfig;
end;

end.
