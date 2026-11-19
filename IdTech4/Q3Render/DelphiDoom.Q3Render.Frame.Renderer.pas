{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the renderer     }
{                                                                              }
{  The entry points of the refexport_t of Quake III that a frame uses          }
{  (RE_LoadWorldMap, RE_BeginFrame, RE_ClearScene, RE_AddRefEntityToScene,     }
{  RE_AddPolyToScene, RE_AddLightToScene, RE_RenderScene, RE_SetColor,         }
{  RE_StretchPic, RE_EndFrame) over the front end, the list of commands and    }
{  the backend. Written for the repository (licence GPL v2 or later) after     }
{  tr_cmds.c and tr_scene.c of the Quake III Arena GPL Source Code (id         }
{  Software).                                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Frame.Renderer;

interface

uses
  System.SysUtils, DelphiDoom.OpenGl.Recorder.Intf, DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Render.Scene.Types,
  DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Scene.FrontEnd, DelphiDoom.Q3Render.Frame.Commands,
  DelphiDoom.Q3Render.Backend.Executor;

type
  /// <summary>
  ///   A renderer that draws into a recorder of GL calls: the scene of a frame becomes a list of drawSurfs, the 2D
  ///   calls and the views become commands, and the end of the frame runs the backend, which writes the calls it
  ///   would make into the frame of the recorder. Handles are those of the module; the two mappers turn them into
  ///   the entries of the shader table and the handles of the model registry
  /// </summary>
  TQ3Renderer = class
  strict private
    FRecorder: IGlCallRecorder;
    FShaderMapper: TQ3HandleMapper;
    FFront: TQ3FrontEnd;
    FCommands: TQ3CommandList;
    FBackend: TQ3Backend;
    FFrameCount: Integer;
  public
    constructor Create(const ARecorder: IGlCallRecorder; const AShaders: IQ3ShaderTable;
      const AModels: IQ3ModelRegistry; const AShaderMapper, AModelMapper: TQ3HandleMapper;
      const ASettings: TQ3RenderSettings; AVidWidth, AVidHeight: Integer; const ANowMilliseconds: TFunc<Integer>);
    destructor Destroy; override;
    /// <summary>RE_LoadWorldMap: the world (nil forgets it)</summary>
    procedure LoadWorld(const AWorld: IQ3RenderWorld);
    /// <summary>RE_BeginFrame: opens the frame of the recorder and queues the draw buffer command</summary>
    procedure BeginFrame;
    procedure ClearScene;
    procedure AddRefEntity(const AEntity: TQ3RefEntity);
    procedure AddPolys(AHostShader, ANumVerts: Integer; const AVerts: TArray<TQ3PolyVert>; ANumPolys: Integer);
    procedure AddLight(const AOrigin: TQ3Vec3; AIntensity, ARed, AGreen, ABlue: Single; AAdditive: Boolean);
    procedure RenderScene(const ARefDef: TQ3RefDef);
    /// <summary>RE_SetColor: four floats, or none for white</summary>
    procedure SetColor(const AColor: TArray<Single>);
    procedure StretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single; AHostShader: Integer);
    /// <summary>
    ///   RE_EndFrame: the swap command, the backend runs the commands, the frame of the recorder closes with the label
    /// </summary>
    procedure EndFrame(const ALabel: string);
    property Front: TQ3FrontEnd read FFront;
    property Backend: TQ3Backend read FBackend;
    property FrameCount: Integer read FFrameCount;
  end;

implementation

uses
  DelphiDoom.Q3Render.Backend.Gl;

constructor TQ3Renderer.Create(const ARecorder: IGlCallRecorder; const AShaders: IQ3ShaderTable;
  const AModels: IQ3ModelRegistry; const AShaderMapper, AModelMapper: TQ3HandleMapper;
  const ASettings: TQ3RenderSettings; AVidWidth, AVidHeight: Integer; const ANowMilliseconds: TFunc<Integer>);
begin
  inherited Create;
  if not Assigned(ARecorder) then
    raise EArgumentNilException.Create('ARecorder');
  FRecorder := ARecorder;
  FShaderMapper := AShaderMapper;
  FFront := TQ3FrontEnd.Create(AShaders, AModels, AShaderMapper, AModelMapper, ASettings);
  FFront.VidHeight := AVidHeight;
  FCommands := TQ3CommandList.Create;
  FBackend := TQ3Backend.Create(TQ3GlRecordingSink.Create(ARecorder), AShaders, AModels, AModelMapper, AVidWidth,
    AVidHeight, ANowMilliseconds);
  FFront.OnDrawSurfs :=
    procedure(const AView: TQ3FrontViewParms; const ARefDef: TQ3RefDef; const ASurfaces: TArray<TQ3DrawSurf>;
      const AEntities: TArray<TQ3RefEntity>; const APolys: TArray<TQ3ScenePoly>;
      const ADlights: TArray<TQ3DynamicLight>)
    begin
      FCommands.AddDrawSurfs(AView, ARefDef, ASurfaces, AEntities, APolys, ADlights);
    end;
end;

destructor TQ3Renderer.Destroy;
begin
  FFront.OnDrawSurfs := nil;
  FBackend.Free;
  FCommands.Free;
  FFront.Free;
  inherited Destroy;
end;

procedure TQ3Renderer.LoadWorld(const AWorld: IQ3RenderWorld);
begin
  FFront.SetWorld(AWorld);
  FBackend.SetWorld(AWorld);
end;

procedure TQ3Renderer.BeginFrame;
begin
  Inc(FFrameCount);
  FRecorder.BeginFrame;
  FCommands.AddDrawBuffer;
end;

procedure TQ3Renderer.ClearScene;
begin
  FFront.ClearScene;
end;

procedure TQ3Renderer.AddRefEntity(const AEntity: TQ3RefEntity);
begin
  FFront.AddRefEntity(AEntity);
end;

procedure TQ3Renderer.AddPolys(AHostShader, ANumVerts: Integer; const AVerts: TArray<TQ3PolyVert>;
  ANumPolys: Integer);
begin
  FFront.AddPolys(AHostShader, ANumVerts, AVerts, ANumPolys);
end;

procedure TQ3Renderer.AddLight(const AOrigin: TQ3Vec3; AIntensity, ARed, AGreen, ABlue: Single;
  AAdditive: Boolean);
begin
  FFront.AddLight(AOrigin, AIntensity, ARed, AGreen, ABlue, AAdditive);
end;

procedure TQ3Renderer.RenderScene(const ARefDef: TQ3RefDef);
begin
  FFront.RenderScene(ARefDef);
end;

procedure TQ3Renderer.SetColor(const AColor: TArray<Single>);
begin
  FCommands.AddSetColor(AColor);
end;

procedure TQ3Renderer.StretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single; AHostShader: Integer);
begin
  FCommands.AddStretchPic(FShaderMapper(AHostShader), AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2);
end;

procedure TQ3Renderer.EndFrame(const ALabel: string);
begin
  FCommands.AddSwapBuffers;
  FBackend.Execute(FCommands);
  FCommands.Clear;
  FFront.EndFrame;
  FRecorder.EndFrame(ALabel);
end;

end.
