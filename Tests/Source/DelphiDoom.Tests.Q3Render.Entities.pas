{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R1b) - the        }
{  surfaces of the entities in a scene, through the whole renderer              }
{                                                                              }
{  The formulas of the surfaces are checked against the C in                    }
{  DelphiDoom.Tests.Q3Render.Surfaces; here a scene built by hand (a polygon,   }
{  a sprite, a beam, a rail, a lightning bolt, an md3 model and a model that    }
{  is not there) goes from the scene to the backend and the counters and the    }
{  calls of the recorder say what was drawn. No OpenArena, no world             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Entities;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3Entities = class
  public
    [Test]
    procedure DovrebbeDisegnarePoligonoSpriteRaggiEModelli;
    [Test]
    procedure DovrebbeTenereIFotogrammiCheIlModelloHa;
    [Test]
    procedure DovrebbeScegliereIlLivelloDiDettaglioDalladistanza;
    [Test]
    procedure DovrebbeDisegnareIlCieloDiUnaShaderSky;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.OpenGl.Recorder.Intf, DelphiDoom.OpenGl.Recorder.CallRecorder,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf,
  DelphiDoom.Q3Render.Shader.Table, DelphiDoom.Q3Render.Scene.FrontEnd, DelphiDoom.Q3Render.Frame.Renderer,
  DelphiDoom.Q3Render.Backend.Executor, DelphiDoom.Tests.Q3Render.Support;

type
  /// <summary>A renderer over files in memory and a recorder that writes into a stream</summary>
  TEntityScene = class
  strict private
    FFiles: TMemoryFiles;
    FSystem: IQ3RenderSystem;
    FTableKeeper: IQ3ShaderTable;
    FStream: TMemoryStream;
    FRecorder: IGlCallRecorder;
    FRenderer: TQ3Renderer;
    FModel: Integer;
    FLodModel: Integer;
    FWhite: Integer;
    FSkyShader: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Entity(AType: Integer): TQ3RefEntity;
    procedure Draw(const AEntities: array of TQ3RefEntity; APolys: Boolean; ASkyPoly: Boolean = False);
    function Calls: string;
    property Renderer: TQ3Renderer read FRenderer;
    property Model: Integer read FModel;
    property LodModel: Integer read FLodModel;
    function LodCount: Integer;
  end;

constructor TEntityScene.Create;
var
  LTable: TQ3ShaderTable;
  LIdentity: TQ3HandleMapper;
begin
  inherited Create;
  FFiles := TMemoryFiles.Create;
  FFiles.Add('models/test.md3', TTestSupport.Md3Bytes('textures/test/surf'));
  // three levels of detail: lodtest.md3, lodtest_1.md3 and lodtest_2.md3
  FFiles.Add('models/lodtest.md3', TTestSupport.Md3Bytes('textures/test/lod0'));
  FFiles.Add('models/lodtest_1.md3', TTestSupport.Md3Bytes('textures/test/lod1'));
  FFiles.Add('models/lodtest_2.md3', TTestSupport.Md3Bytes('textures/test/lod2'));
  FSystem := TTestSupport.BuildSystem(FFiles as IQ3RenderFiles,
    [TPair<string, string>.Create('scripts/test.shader', 'textures/test/poly' + sLineBreak + '{' + sLineBreak +
      '{ map $whiteimage' + sLineBreak + 'blendFunc add }' + sLineBreak + '}' + sLineBreak +
      'textures/test/sky' + sLineBreak + '{' + sLineBreak + 'skyParms env/test 512 -' + sLineBreak +
      '{ map $whiteimage' + sLineBreak + 'blendFunc add }' + sLineBreak + '}' + sLineBreak)]);
  FModel := FSystem.Models.Register('models/test.md3');
  FLodModel := FSystem.Models.Register('models/lodtest.md3');
  LTable := TQ3ShaderTable.Create(FSystem.Shaders);
  FTableKeeper := LTable;
  LTable.RegisterExternalShaders;
  FWhite := LTable.FindShader('textures/test/poly', LIGHTMAP_NONE);
  Assert.IsTrue(FWhite > 0, 'the shader of the polygon must be defined');
  FSkyShader := LTable.FindShader('textures/test/sky', LIGHTMAP_NONE);
  Assert.IsTrue(FSkyShader > 0, 'the shader of the sky must be defined');
  FStream := TMemoryStream.Create;
  FRecorder := TGlCallRecorder.Create(FStream);
  LIdentity :=
    function(AHandle: Integer): Integer
    begin
      Result := AHandle;
    end;
  FRenderer := TQ3Renderer.Create(FRecorder, FTableKeeper, FSystem.Models, LIdentity, LIdentity,
    TQ3RenderSettings.Defaults, 640, 480,
    function: Integer
    begin
      Result := 0;
    end);
end;

destructor TEntityScene.Destroy;
begin
  FRenderer.Free;
  FStream.Free;
  inherited Destroy;
end;

function TEntityScene.LodCount: Integer;
begin
  Result := FSystem.Models.LodCount(FLodModel);
end;

function TEntityScene.Entity(AType: Integer): TQ3RefEntity;
begin
  Result := Default(TQ3RefEntity);
  Result.ReType := AType;
  Result.Axis[0][0] := 1;
  Result.Axis[1][1] := 1;
  Result.Axis[2][2] := 1;
  Result.Radius := 8;
  Result.ShaderRGBA[0] := 255;
  Result.ShaderRGBA[1] := 128;
  Result.ShaderRGBA[2] := 64;
  Result.ShaderRGBA[3] := 255;
end;

procedure TEntityScene.Draw(const AEntities: array of TQ3RefEntity; APolys: Boolean; ASkyPoly: Boolean);
var
  LRefDef: TQ3RefDef;
  LIndex: Integer;
  LVerts: TArray<TQ3PolyVert>;
begin
  LRefDef := Default(TQ3RefDef);
  LRefDef.Width := 640;
  LRefDef.Height := 480;
  LRefDef.FovX := 90;
  LRefDef.FovY := 73.74;
  LRefDef.Time := 1000;
  LRefDef.RdFlags := RDF_NOWORLDMODEL;
  LRefDef.ViewAxis[0][0] := 1;
  LRefDef.ViewAxis[1][1] := 1;
  LRefDef.ViewAxis[2][2] := 1;
  FRenderer.BeginFrame;
  FRenderer.ClearScene;
  for LIndex := 0 to High(AEntities) do
    FRenderer.AddRefEntity(AEntities[LIndex]);
  if APolys or ASkyPoly then
  begin
    SetLength(LVerts, 3);
    for LIndex := 0 to 2 do
    begin
      LVerts[LIndex] := Default(TQ3PolyVert);
      LVerts[LIndex].Xyz[0] := 100 + LIndex * 10;
      LVerts[LIndex].Xyz[1] := LIndex;
      LVerts[LIndex].Modulate[3] := 255;
    end;
    // the null shader is refused (the C warns), so the polygon has the white one
    if ASkyPoly then
      FRenderer.AddPolys(FSkyShader, 3, LVerts, 1)
    else
      FRenderer.AddPolys(FWhite, 3, LVerts, 1);
  end;
  FRenderer.RenderScene(LRefDef);
  FRenderer.EndFrame('entities');
end;

function TEntityScene.Calls: string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, FStream.Size);
  FStream.Position := 0;
  if FStream.Size > 0 then
    FStream.ReadBuffer(LBytes[0], FStream.Size);
  Result := TEncoding.ANSI.GetString(LBytes);
end;

{ TTestQ3Entities }

procedure TTestQ3Entities.DovrebbeDisegnarePoligonoSpriteRaggiEModelli;
var
  LScene: TEntityScene;
  LEntities: array of TQ3RefEntity;
  LStats: TQ3BackendStats;
begin
  LScene := TEntityScene.Create;
  try
    SetLength(LEntities, 7);
    LEntities[0] := LScene.Entity(RT_SPRITE);
    LEntities[0].Origin[0] := 200;
    LEntities[1] := LScene.Entity(RT_BEAM);
    LEntities[1].OldOrigin[0] := 100;
    LEntities[1].OldOrigin[2] := 50;
    LEntities[2] := LScene.Entity(RT_RAIL_CORE);
    LEntities[2].OldOrigin[0] := 300;
    LEntities[3] := LScene.Entity(RT_RAIL_RINGS);
    LEntities[3].OldOrigin[0] := 300;
    LEntities[4] := LScene.Entity(RT_LIGHTNING);
    LEntities[4].OldOrigin[1] := 300;
    LEntities[5] := LScene.Entity(RT_MODEL);
    LEntities[5].HModel := LScene.Model;
    LEntities[5].Frame := 0;
    LEntities[5].OldFrame := 1;
    LEntities[5].BackLerp := 0.5;
    LEntities[5].Origin[0] := 150;
    // a model that is not there: the null model, three lines
    LEntities[6] := LScene.Entity(RT_MODEL);
    LEntities[6].HModel := 0;
    LScene.Draw(LEntities, True);
    LStats := LScene.Renderer.Backend.Stats;
    Assert.AreEqual<Integer>(1, LStats.PolysDrawn, Format('polygon (front: polys %d entities %d drawsurfs %d, backend surfaces %d)',
      [LScene.Renderer.Front.Stats.PolySurfaces, LScene.Renderer.Front.Stats.EntitySurfaces,
      LScene.Renderer.Front.Stats.DrawSurfs, LStats.Surfaces]));
    Assert.AreEqual<Integer>(1, LStats.SpritesDrawn, 'sprite');
    Assert.AreEqual<Integer>(1, LStats.BeamsDrawn, 'beam');
    Assert.AreEqual<Integer>(2, LStats.RailsDrawn, 'rail core and rings');
    Assert.AreEqual<Integer>(1, LStats.LightningDrawn, 'lightning');
    Assert.AreEqual<Integer>(1, LStats.Md3Drawn, 'md3 surface');
    Assert.AreEqual<Integer>(1, LStats.AxisDrawn, 'null model');
    Assert.IsTrue(LScene.Calls.Contains('glBegin'), 'the beam and the axis draw with glBegin');
  finally
    LScene.Free;
  end;
end;

procedure TTestQ3Entities.DovrebbeTenereIFotogrammiCheIlModelloHa;
var
  LScene: TEntityScene;
  LEntities: array of TQ3RefEntity;
begin
  LScene := TEntityScene.Create;
  try
    SetLength(LEntities, 1);
    LEntities[0] := LScene.Entity(RT_MODEL);
    LEntities[0].HModel := LScene.Model;
    // the model has two frames: the front end puts frames out of range back to 0, the backend then reads 0
    LEntities[0].Frame := 7;
    LEntities[0].OldFrame := 9;
    LEntities[0].BackLerp := 0.25;
    LScene.Draw(LEntities, False);
    Assert.AreEqual<Integer>(1, LScene.Renderer.Backend.Stats.Md3Drawn);
  finally
    LScene.Free;
  end;
end;

procedure TTestQ3Entities.DovrebbeScegliereIlLivelloDiDettaglioDalladistanza;
var
  LScene: TEntityScene;
  LEntities: array of TQ3RefEntity;
  LIndex, LFirst, LNear, LFar: Integer;
  LItem: TQ3DrawSurf;
begin
  LScene := TEntityScene.Create;
  try
    SetLength(LEntities, 2);
    // the same model near the viewer and far away (the view looks along +x)
    LEntities[0] := LScene.Entity(RT_MODEL);
    LEntities[0].HModel := LScene.LodModel;
    LEntities[0].Origin[0] := 30;
    LEntities[1] := LScene.Entity(RT_MODEL);
    LEntities[1].HModel := LScene.LodModel;
    LEntities[1].Origin[0] := 5000;
    LScene.Draw(LEntities, False);
    LNear := -1;
    LFar := -1;
    LFirst := LScene.Renderer.Front.LastResult.FirstDrawSurf;
    for LIndex := LFirst to LFirst + LScene.Renderer.Front.LastResult.NumDrawSurfs - 1 do
    begin
      LItem := LScene.Renderer.Front.DrawList.Item(LIndex);
      if LItem.Surface.Kind = skMd3 then
        if LItem.Surface.Index = 0 then
          LNear := LItem.Surface.Lod
        else
          LFar := LItem.Surface.Lod;
    end;
    Assert.AreEqual<Integer>(0, LNear, 'near: the most detailed level');
    Assert.AreEqual<Integer>(2, LFar, 'far: the lowest level');
    Assert.AreEqual<Integer>(3, LScene.LodCount);
  finally
    LScene.Free;
  end;
end;

procedure TTestQ3Entities.DovrebbeDisegnareIlCieloDiUnaShaderSky;
var
  LScene: TEntityScene;
  LEntities: array of TQ3RefEntity;
begin
  LScene := TEntityScene.Create;
  try
    SetLength(LEntities, 0);
    // a polygon with a shader that has skyParms goes to the sky iterator: the box, the clouds, the depth ranges
    LScene.Draw(LEntities, False, True);
    Assert.AreEqual<Integer>(1, LScene.Renderer.Backend.Stats.SkiesDrawn, 'sky');
    Assert.IsTrue(LScene.Calls.Contains('glDepthRange'), 'the sky draws at the farthest depth');
    Assert.IsTrue(LScene.Calls.Contains('glTranslatef'), 'the box is moved to the viewer');
  finally
    LScene.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Entities);

end.
