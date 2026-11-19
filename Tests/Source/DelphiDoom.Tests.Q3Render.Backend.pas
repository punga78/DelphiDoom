{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R1) - the        }
{  backend that writes the GL calls to a recorder                              }
{                                                                              }
{  There is no oracle for this part: the C draws into a real context. The      }
{  tests pin down the GL state tracking (what GL_State, GL_Bind, GL_Cull and   }
{  GL_TexEnv send, and what they leave out), the commands and, on             }
{  maps/oa_dm1.bsp of OpenArena, a regression golden of the stream of the      }
{  first frames (Tests\Data\Q3Render\backend.golden.txt: the sum of every      }
{  frame of the recorder, the counters of the backend and the text of the 2D   }
{  frame). It is not a parity with the C: it only says that the stream does   }
{  not change by accident, on Win32 and on Win64. Ignored when OpenArena is    }
{  not there                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Backend;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3GlState = class
  public
    [Test]
    procedure DovrebbeMandareSoloQuelloCheCambia;
    [Test]
    procedure DovrebbeSegnareLeUnitaDiTexturaELaTexEnv;
    [Test]
    procedure DovrebbeTrattareLeFacceSecondoIlTipoDiCulling;
    [Test]
    procedure DovrebbeRifiutareIFattoriDiBlendNonValidi;
  end;

  [TestFixture]
  [Category('Q3Render')]
  [Category('OpenArena')]
  TTestQ3Backend = class
  public
    [Test]
    procedure DovrebbeDareLoStessoFlussoDiChiamateGlSuOpenArena;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.OpenGl.Recorder.Intf, DelphiDoom.OpenGl.Recorder.CallRecorder, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Q3Render.Scene.Types,
  DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Factory, DelphiDoom.Q3Render.Shader.Table,
  DelphiDoom.Q3Render.Scene.FrontEnd, DelphiDoom.Q3Render.Backend.Gl, DelphiDoom.Q3Render.Backend.State,
  DelphiDoom.Q3Render.Frame.Renderer, DelphiDoom.Q3Render.Backend.Executor, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Q3Render.Support;

type
  /// <summary>A sink that keeps the calls as name(first number,...): enums as hexadecimal, no blocks</summary>
  TCapturingSink = class(TInterfacedObject, IQ3GlSink)
  strict private
    FLines: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Call(const AName: string; const AArguments: array of TQ3GlArg);
    property Lines: TStringList read FLines;
  end;

constructor TCapturingSink.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TCapturingSink.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TCapturingSink.Call(const AName: string; const AArguments: array of TQ3GlArg);
var
  LText: string;
  LIndex: Integer;
begin
  LText := AName;
  for LIndex := 0 to High(AArguments) do
    case AArguments[LIndex].Kind of
      gaEnum:
        LText := LText + ' $' + IntToHex(AArguments[LIndex].IntValue, 4);
      gaInteger:
        LText := LText + ' ' + IntToStr(AArguments[LIndex].IntValue);
    else
      LText := LText + ' ?';
    end;
  FLines.Add(LText);
end;

procedure TTestQ3GlState.DovrebbeMandareSoloQuelloCheCambia;
var
  LSink: TCapturingSink;
  LKeeper: IQ3GlSink;
  LState: TQ3GlState;
begin
  LSink := TCapturingSink.Create;
  LKeeper := LSink;
  LState := TQ3GlState.Create(LKeeper);
  try
    // the default state: GLS_DEPTHTEST_DISABLE and GLS_DEPTHMASK_TRUE
    LState.State(GLS_DEPTHTEST_DISABLE or GLS_DEPTHMASK_TRUE);
    Assert.AreEqual<Integer>(0, LSink.Lines.Count, 'nothing changes');
    // GLS_DEFAULT: the depth test on
    LState.State(GLS_DEFAULT);
    Assert.AreEqual('glEnable $0B71', LSink.Lines[0]);
    Assert.AreEqual<Integer>(1, LSink.Lines.Count);
    // blend on, with the factors, and the depth mask off
    LState.State(GLS_SRCBLEND_ONE or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA);
    Assert.AreEqual('glEnable $0BE2', LSink.Lines[1]);
    Assert.AreEqual('glBlendFunc $0001 $0303', LSink.Lines[2]);
    Assert.AreEqual('glDepthMask 0', LSink.Lines[3]);
    Assert.AreEqual<Integer>(4, LSink.Lines.Count);
    // the same again: nothing
    LState.State(GLS_SRCBLEND_ONE or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA);
    Assert.AreEqual<Integer>(4, LSink.Lines.Count);
    // the alpha test
    LState.State(GLS_DEFAULT or GLS_ATEST_GE_80);
    Assert.AreEqual('glDisable $0BE2', LSink.Lines[4]);
    Assert.AreEqual('glDepthMask 1', LSink.Lines[5]);
    Assert.AreEqual('glEnable $0BC0', LSink.Lines[6]);
  finally
    LState.Free;
  end;
end;

procedure TTestQ3GlState.DovrebbeSegnareLeUnitaDiTexturaELaTexEnv;
var
  LSink: TCapturingSink;
  LKeeper: IQ3GlSink;
  LState: TQ3GlState;
begin
  LSink := TCapturingSink.Create;
  LKeeper := LSink;
  LState := TQ3GlState.Create(LKeeper);
  try
    LState.Bind(5);
    LState.Bind(5);
    Assert.AreEqual<Integer>(1, LSink.Lines.Count, 'the same texture is not bound again');
    Assert.AreEqual('glBindTexture $0DE1 5', LSink.Lines[0]);
    // the unit 1 has its own bound texture and its own environment
    LState.SelectTexture(1);
    LState.SelectTexture(1);
    LState.Bind(5);
    LState.TexEnv(GL_MODULATE);
    Assert.AreEqual('glActiveTextureARB $84C1', LSink.Lines[1]);
    Assert.AreEqual('glClientActiveTextureARB $84C1', LSink.Lines[2]);
    Assert.AreEqual('glBindTexture $0DE1 5', LSink.Lines[3]);
    Assert.AreEqual<Integer>(4, LSink.Lines.Count, 'the environment of both units starts as GL_MODULATE');
    LState.TexEnv(GL_ADD);
    Assert.AreEqual('glTexEnvf $2300 $2200 ?', LSink.Lines[4]);
    LState.SelectTexture(0);
    LState.TexEnv(GL_ADD);
    Assert.AreEqual<Integer>(8, LSink.Lines.Count);
    Assert.AreEqual('glTexEnvf $2300 $2200 ?', LSink.Lines[7]);
  finally
    LState.Free;
  end;
end;

procedure TTestQ3GlState.DovrebbeTrattareLeFacceSecondoIlTipoDiCulling;
var
  LSink: TCapturingSink;
  LKeeper: IQ3GlSink;
  LState: TQ3GlState;
begin
  LSink := TCapturingSink.Create;
  LKeeper := LSink;
  LState := TQ3GlState.Create(LKeeper);
  try
    LState.Cull(Ord(ctFrontSided), False);
    Assert.AreEqual('glEnable $0B44', LSink.Lines[0]);
    Assert.AreEqual('glCullFace $0404', LSink.Lines[1]);
    LState.Cull(Ord(ctFrontSided), False);
    Assert.AreEqual<Integer>(2, LSink.Lines.Count);
    LState.Cull(Ord(ctBackSided), True);
    Assert.AreEqual('glEnable $0B44', LSink.Lines[2]);
    Assert.AreEqual('glCullFace $0404', LSink.Lines[3], 'a mirror turns the faces around');
    LState.Cull(Ord(ctTwoSided), False);
    Assert.AreEqual('glDisable $0B44', LSink.Lines[4]);
    LState.ForgetFaceCulling;
    LState.Cull(Ord(ctTwoSided), False);
    Assert.AreEqual<Integer>(6, LSink.Lines.Count, 'after glState.faceCulling = -1 it is sent again');
  finally
    LState.Free;
  end;
end;

procedure TTestQ3GlState.DovrebbeRifiutareIFattoriDiBlendNonValidi;
var
  LKeeper: IQ3GlSink;
  LState: TQ3GlState;
begin
  LKeeper := TCapturingSink.Create;
  LState := TQ3GlState.Create(LKeeper);
  try
    Assert.WillRaise(
      procedure
      begin
        // the source factor 15 is not one of the nine
        LState.State($0000000F or GLS_DSTBLEND_ONE);
      end, EArgumentException);
  finally
    LState.Free;
  end;
end;

procedure TTestQ3Backend.DovrebbeDareLoStessoFlussoDiChiamateGlSuOpenArena;
var
  LFolder, LGoldenFile, LViewsFile: string;
  LFiles: IGameFileSystem;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LTable: TQ3ShaderTable;
  LTableKeeper: IQ3ShaderTable;
  LRenderer: TQ3Renderer;
  LStream: TMemoryStream;
  LRecorder: IGlCallRecorder;
  LViews, LActual, LGolden, LOutput: TStringList;
  LLine, LText: string;
  LNumber, LCrosshair, LWhite, LIndex, LTextures: Integer;
  LIdentity: TQ3HandleMapper;
  LWords: TArray<string>;
  LRefDef: TQ3RefDef;
  LAngles, LLight: TQ3Vec3;
  LColor: TArray<Single>;
  LInvariant: TFormatSettings;
  LStats: TQ3BackendStats;
begin
  LFolder := TTestSupport.OpenArenaFolder;
  LViewsFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\front.views.txt');
  LGoldenFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\backend.golden.txt');
  Assert.IsTrue(LViewsFile <> '', 'front.views.txt must be there');
  LInvariant := TFormatSettings.Invariant;
  LFiles := TTestSupport.OpenArenaFiles(LFolder, 'baseoa');
  LViews := TStringList.Create;
  LActual := TStringList.Create;
  LOutput := TStringList.Create;
  LStream := TMemoryStream.Create;
  try
    LSystem := TQ3RenderFactory.CreateSystem(LFiles);
    LTable := TQ3ShaderTable.Create(LSystem.Shaders);
    LTableKeeper := LTable;
    LTable.RegisterExternalShaders;
    LWorld := LSystem.WorldLoader.Load('maps/oa_dm1.bsp');
    Assert.IsTrue(Assigned(LWorld), 'oa_dm1 must load');
    LIdentity :=
      function(AHandle: Integer): Integer
      begin
        Result := AHandle;
      end;
    LRecorder := TGlCallRecorder.Create(LStream);
    LRenderer := TQ3Renderer.Create(LRecorder, LTableKeeper, LSystem.Models, LIdentity, LIdentity,
      TQ3RenderSettings.Defaults, 640, 480,
      function: Integer
      begin
        Result := 0;
      end);
    try
      LRenderer.LoadWorld(LWorld);
      // the 2D shaders: a picture with a lightmap index of 2D (the one of RE_RegisterShader), and a white one
      LCrosshair := LTable.FindShader('gfx/2d/crosshaira', LIGHTMAP_2D);
      LWhite := LTable.FindShader('white', LIGHTMAP_2D);
      LViews.LoadFromFile(LViewsFile);
      LNumber := 0;
      for LLine in LViews do
      begin
        if (LLine = '') or (LLine[1] = '#') then
          Continue;
        LWords := LLine.Split([' ']);
        LRefDef := Default(TQ3RefDef);
        LRefDef.Width := 640;
        LRefDef.Height := 480;
        LRefDef.Time := 1000 + 50 * LNumber;
        for LIndex := 0 to 2 do
          LRefDef.ViewOrigin[LIndex] := StrToFloat(LWords[1 + LIndex], LInvariant);
        LAngles[0] := StrToFloat(LWords[5], LInvariant);
        LAngles[1] := StrToFloat(LWords[4], LInvariant);
        LAngles[2] := StrToFloat(LWords[6], LInvariant);
        LRefDef.FovX := StrToFloat(LWords[7], LInvariant);
        LRefDef.FovY := StrToFloat(LWords[8], LInvariant);
        TQ3Math.AngleVectors(LAngles, LRefDef.ViewAxis[0], LRefDef.ViewAxis[1], LRefDef.ViewAxis[2]);
        LRenderer.BeginFrame;
        LRenderer.ClearScene;
        // the lights of the view: "dlight x y z radius" (white, not additive) light the surfaces they reach
        LIndex := 9;
        while LIndex + 4 < Length(LWords) + 0 do
        begin
          if LWords[LIndex] = 'dlight' then
          begin
            LLight[0] := StrToFloat(LWords[LIndex + 1], LInvariant);
            LLight[1] := StrToFloat(LWords[LIndex + 2], LInvariant);
            LLight[2] := StrToFloat(LWords[LIndex + 3], LInvariant);
            LRenderer.AddLight(LLight, StrToFloat(LWords[LIndex + 4], LInvariant), 1, 1, 1, False);
            Inc(LIndex, 5);
          end
          else
            Inc(LIndex);
        end;
        LRenderer.RenderScene(LRefDef);
        // a crosshair and a coloured rectangle on top of the view
        SetLength(LColor, 4);
        LColor[0] := 1;
        LColor[1] := 0.5;
        LColor[2] := 0.25;
        LColor[3] := 0.75;
        LRenderer.SetColor(LColor);
        LRenderer.StretchPic(304, 224, 32, 32, 0, 0, 1, 1, LCrosshair);
        LRenderer.SetColor(nil);
        LRenderer.StretchPic(0, 0, 64, 16, 0, 0, 1, 1, LWhite);
        LRenderer.EndFrame('view ' + IntToStr(LNumber));
        Inc(LNumber);
      end;
      // a frame that is only 2D: the swap has to call glFinish
      LRenderer.BeginFrame;
      LRenderer.StretchPic(0, 0, 640, 480, 0, 0, 1, 1, LWhite);
      LRenderer.EndFrame('2d only');
      LStats := LRenderer.Backend.Stats;
      LTextures := LRenderer.Backend.TextureCount;
    finally
      LRenderer.Free;
    end;
    // the text of the frames: the sum lines and the counters, then the whole 2D frame and the start of the first
    LStream.Position := 0;
    LOutput.LoadFromStream(LStream);
    for LText in LOutput do
      if LText.StartsWith('FRAME') then
        LActual.Add(LText);
    LActual.Add(Format('backend surfaces=%d batches=%d vertexes=%d indexes=%d faces=%d triangles=%d stretchpics=%d',
      [LStats.Surfaces, LStats.Batches, LStats.Vertexes, LStats.Indexes, LStats.FacesDrawn, LStats.TrianglesDrawn,
      LStats.StretchPics]));
    LActual.Add(Format('drawn grids=%d polys=%d sprites=%d beams=%d rails=%d lightning=%d md3=%d axis=%d sky=%d dlights=%d fog=%d',
      [LStats.GridsDrawn, LStats.PolysDrawn, LStats.SpritesDrawn, LStats.BeamsDrawn, LStats.RailsDrawn,
      LStats.LightningDrawn, LStats.Md3Drawn, LStats.AxisDrawn, LStats.SkiesDrawn, LStats.DlightDraws,
      LStats.FogDraws]));
    LActual.Add(Format('not ported flares=%d md3=%d', [LStats.SkippedFlares, LStats.SkippedMd3]));
    LActual.Add(Format('textures=%d', [LTextures]));
    if GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_BACKEND_OUT') <> '' then
    begin
      LOutput.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_BACKEND_OUT'));
      LActual.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_BACKEND_OUT') + '.golden');
    end;
    if LGoldenFile = '' then
      Assert.Fail('backend.golden.txt must be there')
    else
    begin
      LGolden := TTestFiles.Lines(LGoldenFile);
      try
        TTestGolden.AssertSameLines(LGolden, LActual);
      finally
        LGolden.Free;
      end;
    end;
  finally
    LViews.Free;
    LActual.Free;
    LOutput.Free;
    LStream.Free;
    LFiles.Shutdown;
  end;
end;

end.
