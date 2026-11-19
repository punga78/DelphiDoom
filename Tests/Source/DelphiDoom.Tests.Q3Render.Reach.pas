{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - what       }
{  OpenArena 0.8.8 loads for real when cgame and ui run CG_INIT, UI_INIT and   }
{  their first frames against the adapter of this library (the recording       }
{  renderer of Q3Host stays under it: same calls, same numbers). The setup is  }
{  that of Tests\DelphiDoom.Tests.Q3Host.ClientReach: file system of            }
{  Framework\Wad over the real folder, map oa_dm1, a qagame that ran GAME_INIT.  }
{  Golden: Tests\Data\Q3Render\reach.golden.txt. Ignored when OpenArena is not }
{  there                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Reach;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  [Category('OpenArena')]
  TTestQ3RenderReach = class
  public
    [Test]
    procedure CgameEUiDovrebberoCaricareLeCoseVereDiOpenArena;
    [Test]
    procedure CgameEUiDovrebberoDisegnareConIlRendererSenzaGl;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Factory, DelphiDoom.Scanner.Q3.GlobalDefines,
  DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Scanner.Q3.ScriptLoader, DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.GameFiles,
  DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.ServerState,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.Client.Services,
  DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientKeys, DelphiDoom.Q3Host.ClientCdKey,
  DelphiDoom.Q3Host.ClientRecordingRenderer, DelphiDoom.Q3Host.UiLanServers, DelphiDoom.Q3Host.ClientScriptFiles,
  DelphiDoom.Q3Host.ClientScriptLog, DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Q3Host.Services,
  DelphiDoom.Tests.Q3Host.ClientSupport, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Factory,
  DelphiDoom.Q3Render.Host.Adapter, DelphiDoom.Q3Render.Backend.Executor, DelphiDoom.Q3Render.Scene.Types,
  DelphiDoom.OpenGl.Recorder.Intf, DelphiDoom.OpenGl.Recorder.CallRecorder, DelphiDoom.Tests.Q3Render.Support;

const
  UIMENU_MAIN = 1;
  CA_DISCONNECTED = 1;

function MapOf(const AFiles: IGameFileSystem): AnsiString;
var
  LNames: TArray<string>;
  LName: string;
begin
  LNames := AFiles.ListFiles('maps', '.bsp', True);
  Assert.IsTrue(Length(LNames) > 0, 'no map in the paks');
  for LName in LNames do
    if SameText(LName, 'oa_dm1.bsp') then
      Exit('maps/' + AnsiString(LName));
  Result := 'maps/' + AnsiString(LNames[0]);
end;

function Joined(const ANames: TArray<string>; ACount: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(ANames) do
    if LIndex < ACount then
      Result := Result + IfThen(Result = '', '', ', ') + ANames[LIndex];
end;

// the names the module itself asked for (the recorder keeps them) against what loaded: the tables also hold the
// shaders that the md3 surfaces name, so their totals are larger. Register is cached: asking again changes nothing
function Asked(const ARecorder: TQ3RecordingRenderer; const ASystem: IQ3RenderSystem): string;
var
  LName: string;
  LShaders, LShadersLoaded, LModels, LModelsLoaded: Integer;
begin
  LShaders := 0;
  LShadersLoaded := 0;
  for LName in ARecorder.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER) do
  begin
    Inc(LShaders);
    if ASystem.Shaders.Register(AnsiString(LName)) > 0 then
      Inc(LShadersLoaded);
  end;
  LModels := 0;
  LModelsLoaded := 0;
  for LName in ARecorder.RegisteredNames(TQ3RecordingRenderer.KIND_MODEL) do
  begin
    Inc(LModels);
    if ASystem.Models.Register(AnsiString(LName)) > 0 then
      Inc(LModelsLoaded);
  end;
  Result := Format('asked shaders=%d loaded=%d defective=%d | asked models=%d loaded=%d missing=%d',
    [LShaders, LShadersLoaded, LShaders - LShadersLoaded, LModels, LModelsLoaded, LModels - LModelsLoaded]);
end;

// what the tables hold, as one line
function Stats(const ASystem: IQ3RenderSystem; const AAdapter: TQ3HostRendererAdapter): string;
var
  LWorld: IQ3RenderWorld;
begin
  Result := Format('shaders=%d defined=%d implicit=%d defective=%d | images=%d missing=%d | models=%d missing=%d',
    [ASystem.Shaders.RegisteredCount, ASystem.Shaders.DefinedCount, ASystem.Shaders.ImplicitCount,
    Length(ASystem.Shaders.DefectiveNames), ASystem.Images.LoadedCount, Length(ASystem.Images.MissingNames),
    ASystem.Models.LoadedCount, Length(ASystem.Models.MissingNames)]);
  LWorld := AAdapter.World;
  if Assigned(LWorld) then
    Result := Result + Format(' | world: surfaces=%d faces=%d triangles=%d flares=%d patches=%d refused=%d fogs=%d' +
      ' lightmaps=%d submodels=%d clusters=%d lightgrid=%d bytes', [LWorld.SurfaceCount, Length(LWorld.GetFaces),
      Length(LWorld.GetTriangleSurfaces), Length(LWorld.GetFlares), LWorld.PatchCount, LWorld.RefusedCount,
      LWorld.FogCount, Length(LWorld.GetLightmaps), LWorld.SubmodelCount, LWorld.GetVisibility.NumClusters,
      Length(LWorld.GetLightGrid.Data)])
  else
    Result := Result + ' | world: none';
end;

function RenderStats(const ALabel: string; const AAdapter: TQ3HostRendererAdapter): string;
var
  LFront: TQ3FrontEndStats;
  LBackend: TQ3BackendStats;
begin
  LFront := AAdapter.Renderer.Front.Stats;
  LBackend := AAdapter.Renderer.Backend.Stats;
  Result := Format('%s render: scenes=%d drawsurfs(last scene)=%d world=%d polys=%d entities=%d portal=%d | ' +
    'backend: surfaces=%d batches=%d faces=%d triangles=%d stretchpics=%d textures=%d | drawn: grids=%d polys=%d ' +
    'sprites=%d beams=%d rails=%d lightning=%d md3=%d axis=%d sky=%d dlights=%d fog=%d | not ported: flares=%d md3=%d',
    [ALabel, LFront.Scenes, LFront.DrawSurfs, LFront.WorldSurfaces, LFront.PolySurfaces, LFront.EntitySurfaces,
    LFront.PortalSurfaces, LBackend.Surfaces, LBackend.Batches, LBackend.FacesDrawn, LBackend.TrianglesDrawn,
    LBackend.StretchPics, AAdapter.Renderer.Backend.TextureCount, LBackend.GridsDrawn, LBackend.PolysDrawn,
    LBackend.SpritesDrawn, LBackend.BeamsDrawn, LBackend.RailsDrawn, LBackend.LightningDrawn, LBackend.Md3Drawn,
    LBackend.AxisDrawn, LBackend.SkiesDrawn, LBackend.DlightDraws, LBackend.FogDraws, LBackend.SkippedFlares,
    LBackend.SkippedMd3]);
end;

function Measure(const AFiles: IGameFileSystem; const AMap: AnsiString; ALines, ADetails: TStrings;
  const AGame: string; ARender: Boolean = False): string;
var
  LGlStream: TMemoryStream;
  LGl: IGlCallRecorder;
  LAdapter: TQ3HostRendererAdapter;
  LConsole: TQ3Console;
  LClipMap: IQ3HostClipMap;
  LServerState: TQ3HostServerState;
  LClient: TQ3ClientState;
  LGlobals: TQ3GlobalDefines;
  LSources: TQ3SourceHandles;
  LRecorder: TQ3RecordingRenderer;
  LInner, LRenderer: IQ3HostRenderer;
  LSystem: IQ3RenderSystem;
  LSound: TQ3FakeSound;
  LConnection: TQ3FakeConnection;
  LKeys: TQ3ClientKeys;
  LLan: TQ3LanServers;
  LCdKey: TQ3ClientCdKey;
  LBase, LServices: TQ3HostServices;
  LClientServices: TQ3HostClientServices;
  LHost: IQ3SyscallHost;
  LFingerprint: TQ3FingerprintHost;
  LKeeper: IQvmHost;
  LMachine: IQvmMachine;
  LData: TBytes;
  LStage, LResult: string;
  LFrame, LIndex: Integer;
  LUiState: TQ3HostUiClientState;
  LSnapshot: TQ3ClientSnapshot;
  LCommand: TQ3HostUserCmd;
  LStateIntf: IQ3HostServerState;
begin
  LConsole := TQ3Console.Create;
  try
    LConsole.Init;
    LConsole.CVars.Get('sv_maxclients', '8', 0);
    LClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(AFiles));
    LClipMap.Load(AMap);
    LGlobals := TQ3GlobalDefines.Create;
    LSources := TQ3SourceHandles.Create(TQ3ScriptLoader.Create(TQ3HostScriptFiles.Create(AFiles), nil), nil, LGlobals);
    LClient := TQ3ClientState.Create(LConsole.Arguments);
    LRecorder := TQ3RecordingRenderer.Create;
    LInner := LRecorder;
    LSystem := TQ3RenderFactory.CreateSystem(AFiles);
    LGlStream := nil;
    LAdapter := nil;
    if ARender then
    begin
      LGlStream := TMemoryStream.Create;
      LGl := TGlCallRecorder.Create(LGlStream);
      LRenderer := TQ3RenderFactory.CreateRenderingHostRenderer(LInner, LSystem, LGl, nil,
        function: Integer
        begin
          Result := 0;
        end);
      LAdapter := LRenderer as TQ3HostRendererAdapter;
    end
    else
      LRenderer := TQ3RenderFactory.CreateHostRenderer(LInner, LSystem);
    LSound := TQ3FakeSound.Create;
    LConnection := TQ3FakeConnection.Create;
    LKeys := TQ3ClientKeys.Create(LConsole.CVars);
    LLan := TQ3LanServers.Create;
    LCdKey := TQ3ClientCdKey.Create;
    LServerState := TQ3HostServerState.Create(LConsole.CVars);
    LStateIntf := LServerState;
    try
      LServerState.OnConfigstringChanged :=
        procedure(AIndex: Integer; const AValue: AnsiString)
        begin
          LClient.ConfigstringModified(AIndex, AValue);
        end;

      LBase := Default(TQ3HostServices);
      LBase.CVars := LConsole.CVars;
      LBase.Arguments := LConsole.Arguments;
      LBase.Buffer := LConsole.Buffer;
      LBase.Commands := LConsole.Commands;
      LBase.Files := TQ3GameHostFiles.Create(AFiles, nil);
      LBase.ClipMap := LClipMap;
      LBase.State := LServerState;
      LBase.ServerCommands := TQ3RecordingServerCommands.Create;
      LBase.Calendar := TQ3FixedCalendar.Create;

      LClientServices := Default(TQ3HostClientServices);
      LClientServices.State := LClient;
      LClientServices.Connection := LConnection;
      LClientServices.ClientSystem := TQ3FakeClientSystem.Create;
      LClientServices.Keys := LKeys;
      LClientServices.Sound := LSound;
      LClientServices.Cinematics := TQ3FakeCinematics.Create;
      LClientServices.Renderer := LRenderer;
      LClientServices.Lan := LLan;
      LClientServices.CdKey := LCdKey;
      LClientServices.Sources := LSources;
      LClientServices.Math := True;

      // 1. the server game: GAME_INIT, a client that connects and begins, three frames
      LServices := LBase;
      LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(0), LServices);
      Assert.IsTrue(AFiles.ReadFile('vm/qagame.qvm', LData));
      LMachine := TQvmFactory.CreateMachine('qagame', LData, LHost);
      LMachine.Call(0, [1000, 12345, 0]);
      LServerState.SetUserinfo(0, '\name\Tester\model\sarge\skill\3\rate\25000\cl_voip\0');
      LServerState.SetClientActive(0, True);
      LMachine.Call(2, [0, 1, 0]);
      LMachine.Call(3, [0]);
      for LFrame := 1 to 3 do
        LMachine.Call(8, [1000 + 100 * LFrame]);
      LClient.ConfigstringModified(0, AnsiString('\sv_hostname\Test\mapname\' + Copy(AMap, 6, Length(AMap) - 9) +
        '\sv_maxclients\8\g_gametype\0\timelimit\0\fraglimit\20\capturelimit\8\g_maxGameClients\0'));
      LClient.ConfigstringModified(1, '\sv_serverid\1234\sv_pure\0');

      // 2. cgame: CG_INIT, one snapshot and a few user commands, the first frame
      LServices := LBase;
      LServices.Client := LClientServices;
      LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.CGame, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(5000), LServices);
      LFingerprint := TQ3FingerprintHost.Create(LHost);
      LKeeper := LFingerprint;
      Assert.IsTrue(AFiles.ReadFile('vm/cgame.qvm', LData));
      LMachine := TQvmFactory.CreateMachine('cgame', LData, LKeeper);
      LStage := 'init';
      try
        // the screen updates of the loading screens of CG_INIT are one frame of the renderer
        if ARender then
          LAdapter.BeginFrame;
        LMachine.Call(0, [0, 0, 0]);
        if ARender then
        begin
          LAdapter.EndFrame('cgame init');
          ALines.Add(RenderStats(AGame + '/cgame after CG_INIT', LAdapter));
        end;
        LStage := 'frame';
        LSnapshot := Default(TQ3ClientSnapshot);
        LSnapshot.MessageNum := 1;
        LSnapshot.ServerTime := 1300;
        LSnapshot.PlayerState[0] := Byte(1300 and $FF);
        LSnapshot.PlayerState[1] := Byte(1300 shr 8);
        LClient.AddSnapshot(LSnapshot, nil);
        for LIndex := 1 to 70 do
        begin
          LCommand := Default(TQ3HostUserCmd);
          PInteger(@LCommand[0])^ := 1300 + 8 * LIndex;
          LClient.AddUserCommand(LCommand);
        end;
        if ARender then
          LAdapter.BeginFrame;
        LMachine.Call(3, [1400, 0, 0]);
        if ARender then
        begin
          LAdapter.EndFrame('cgame frame');
          ALines.Add(RenderStats(AGame + '/cgame after the first frame', LAdapter));
        end;
        LResult := Format('served=%d finished', [LFingerprint.Count]);
      except
        on E: Exception do
          LResult := Format('served=%d exception=%s: %s in %s', [LFingerprint.Count, E.ClassName, Trim(E.Message),
            LStage]);
      end;
      ALines.Add(AGame + '/cgame ' + LResult + ' | recorder shaders=' +
        IntToStr(Length(LRecorder.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER))) + ' models=' +
        IntToStr(Length(LRecorder.RegisteredNames(TQ3RecordingRenderer.KIND_MODEL))));
      ALines.Add(AGame + '/cgame asked by the module: ' + Asked(LRecorder, LSystem));
      ALines.Add(AGame + '/cgame tables (with the shaders of the md3 surfaces): ' +
        Stats(LSystem, LRenderer as TQ3HostRendererAdapter));
      ADetails.Add(AGame + '/cgame defective shaders: ' + Joined(LSystem.Shaders.DefectiveNames, 400));
      ADetails.Add(AGame + '/cgame missing images: ' + Joined(LSystem.Images.MissingNames, 400));
      ADetails.Add(AGame + '/cgame missing models: ' + Joined(LSystem.Models.MissingNames, 40));

      // 3. ui: UI_INIT, the main menu, a refresh (the same renderer and tables as cgame)
      LUiState := Default(TQ3HostUiClientState);
      LUiState.ConnectionState := CA_DISCONNECTED;
      LConnection.State := LUiState;
      LServices := LBase;
      LServices.Client := LClientServices;
      LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Ui, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(5000), LServices);
      LFingerprint := TQ3FingerprintHost.Create(LHost);
      LKeeper := LFingerprint;
      Assert.IsTrue(AFiles.ReadFile('vm/ui.qvm', LData));
      LMachine := TQvmFactory.CreateMachine('ui', LData, LKeeper);
      LStage := 'init';
      try
        LMachine.Call(0, []);
        LMachine.Call(1, [0]);
        LStage := 'menu';
        LMachine.Call(UI_SET_ACTIVE_MENU, [UIMENU_MAIN]);
        LStage := 'refresh';
        for LFrame := 1 to 3 do
        begin
          if ARender then
            LAdapter.BeginFrame;
          LMachine.Call(5, [6000 + 20 * LFrame]);
          if ARender then
            LAdapter.EndFrame('ui refresh ' + IntToStr(LFrame));
        end;
        if ARender then
          ALines.Add(RenderStats(AGame + '/ui after three refreshes (cumulative)', LAdapter));
        LResult := Format('served=%d finished', [LFingerprint.Count]);
      except
        on E: Exception do
          LResult := Format('served=%d exception=%s: %s in %s', [LFingerprint.Count, E.ClassName, Trim(E.Message),
            LStage]);
      end;
      ALines.Add(AGame + '/ui ' + LResult + ' | recorder shaders=' +
        IntToStr(Length(LRecorder.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER))));
      ALines.Add(AGame + '/ui (cumulative with cgame) asked by the modules: ' + Asked(LRecorder, LSystem));
      ALines.Add(AGame + '/ui (cumulative) tables: ' + Stats(LSystem, LRenderer as TQ3HostRendererAdapter));
      ADetails.Add(AGame + '/ui defective shaders: ' + Joined(LSystem.Shaders.DefectiveNames, 400));
      ADetails.Add(AGame + '/ui missing images: ' + Joined(LSystem.Images.MissingNames, 400));
      Result := LResult;
    finally
      LStateIntf := nil;
      LClient := nil;
      LSources.Free;
      LGlobals.Free;
      LCdKey.Free;
      LGlStream.Free;
    end;
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3RenderReach.CgameEUiDovrebberoCaricareLeCoseVereDiOpenArena;
var
  LFolder, LGame, LOut, LGoldenFile: string;
  LFiles: IGameFileSystem;
  LActual, LDetails, LGolden: TStringList;
begin
  LFolder := TTestSupport.OpenArenaFolder;
  LActual := TStringList.Create;
  LDetails := TStringList.Create;
  try
    for LGame in ['baseoa', 'missionpack'] do
    begin
      LFiles := TTestSupport.OpenArenaFiles(LFolder, LGame);
      Measure(LFiles, MapOf(LFiles), LActual, LDetails, LGame);
      LFiles.Shutdown;
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_REACH_OUT');
    if LOut <> '' then
    begin
      LActual.SaveToFile(LOut);
      LDetails.SaveToFile(LOut + '.details');
    end;
    LGoldenFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\reach.golden.txt');
    if LGoldenFile <> '' then
    begin
      LGolden := TTestFiles.Lines(LGoldenFile);
      try
        TTestGolden.AssertSameLines(LGolden, LActual);
      finally
        LGolden.Free;
      end;
    end;
  finally
    LActual.Free;
    LDetails.Free;
  end;
end;

procedure TTestQ3RenderReach.CgameEUiDovrebberoDisegnareConIlRendererSenzaGl;
var
  LFolder, LOut, LGoldenFile: string;
  LFiles: IGameFileSystem;
  LActual, LDetails, LGolden: TStringList;
begin
  LFolder := TTestSupport.OpenArenaFolder;
  LActual := TStringList.Create;
  LDetails := TStringList.Create;
  try
    // the same run as above with the renderer of phase R1 behind the adapter: the scene that cgame builds goes
    // through the front end, and the frames through the backend into a recorder of GL calls (no GL context)
    LFiles := TTestSupport.OpenArenaFiles(LFolder, 'baseoa');
    Measure(LFiles, MapOf(LFiles), LActual, LDetails, 'baseoa', True);
    LFiles.Shutdown;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_RENDER_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    LGoldenFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\reach.render.golden.txt');
    Assert.IsTrue(LGoldenFile <> '', 'reach.render.golden.txt must be there');
    LGolden := TTestFiles.Lines(LGoldenFile);
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LGolden.Free;
    end;
  finally
    LActual.Free;
    LDetails.Free;
  end;
end;

end.
