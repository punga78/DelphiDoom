{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R1) - the pieces }
{  of the front end                                                            }
{                                                                              }
{  The sort, the culling, the buffers of a scene, the structures of cgame in    }
{  memory, the shader table and the commands, with data built in memory.       }
{  The whole front end against the C is in DelphiDoom.Tests.Q3Render.Front.    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.FrontPieces;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3DrawSurfSorter = class
  public
    [Test]
    procedure DovrebbeOrdinareInModoCrescenteEConservareLeSuperfici;
    [Test]
    procedure DovrebbeOrdinareAncheICasiCortiEQuelliCheNonVannoOrdinati;
    [Test]
    procedure DovrebbeLasciareStareCioCheStaFuoriDalIntervallo;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ViewCuller = class
  public
    [Test]
    procedure DovrebbeTagliareIPuntiDietroOFuoriDallaPiramide;
    [Test]
    procedure DovrebbeDireClipPerUnaSferaCheTagliaUnPiano;
    [Test]
    procedure DovrebbeClassificareUnaScatolaInLocale;
    [Test]
    procedure DovrebbeNonTagliareNullaConNoCull;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3SceneBuffers = class
  public
    [Test]
    procedure DovrebbeFermarsiAlLimiteDelleEntita;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiEntitaCheNonEsiste;
    [Test]
    procedure DovrebbeScartareLeLuciSenzaIntensitaEOltreIlLimite;
    [Test]
    procedure DovrebbeIniziareUnaScenaDopoQuellaChiusa;
    [Test]
    procedure DovrebbeTrovareLaNebbiaDiUnPoligono;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3SceneReader = class
  public
    [Test]
    procedure DovrebbeAvereLeDimensioniDelleStrutture;
    [Test]
    procedure DovrebbeLeggereUnRefdefDallaMemoria;
    [Test]
    procedure DovrebbeLeggereUnaEntitaEUnColore;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ShaderTable = class
  public
    [Test]
    procedure DovrebbeCominciareConLoShaderDiDefaultELOmbra;
    [Test]
    procedure DovrebbeFareLeVarianteDiUnoShaderImplicitoPerOgniIndiceDiLightmap;
    [Test]
    procedure DovrebbeTenereLeVarianteDiUnoScriptSecondoLaLightmap;
    [Test]
    procedure DovrebbeDareZeroPerNomiVuotiEShaderDifettosi;
    [Test]
    procedure DovrebbeInserireNellaListaOrdinataDopoQuelliConLaStessaSort;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3CommandList = class
  public
    [Test]
    procedure DovrebbeTenereICommandiNellOrdineEIlBiancoDiSetColor;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.IOUtils, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Q3Host.Arguments,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf, DelphiDoom.Qvm.Intf,
  DelphiDoom.Q3Render.Draw.Sorter,
  DelphiDoom.Q3Render.View.Setup, DelphiDoom.Q3Render.View.Culler, DelphiDoom.Q3Render.Scene.Buffers,
  DelphiDoom.Q3Render.Scene.Reader, DelphiDoom.Q3Render.Shader.Table, DelphiDoom.Q3Render.Frame.Commands,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Q3Render.Support;

function Vec(AX, AY, AZ: Single): TQ3Vec3;
begin
  Result[0] := AX;
  Result[1] := AY;
  Result[2] := AZ;
end;

{ TTestQ3DrawSurfSorter }

procedure TTestQ3DrawSurfSorter.DovrebbeOrdinareInModoCrescenteEConservareLeSuperfici;
var
  LSurfaces: TArray<TQ3DrawSurf>;
  LIndex, LSeed: Integer;
  LSeen: TArray<Boolean>;
begin
  for LSeed := 1 to 20 do
  begin
    RandSeed := LSeed;
    SetLength(LSurfaces, 100 + LSeed * 97);
    SetLength(LSeen, 0);
    SetLength(LSeen, Length(LSurfaces));
    for LIndex := 0 to High(LSurfaces) do
    begin
      // few distinct keys: many ties, which is where the order of the algorithm shows
      LSurfaces[LIndex].Sort := Cardinal(Random(12)) shl 17;
      LSurfaces[LIndex].Surface.Index := LIndex;
    end;
    TQ3DrawSurfSorter.Sort(LSurfaces, 0, Length(LSurfaces));
    for LIndex := 1 to High(LSurfaces) do
      Assert.IsTrue(LSurfaces[LIndex - 1].Sort <= LSurfaces[LIndex].Sort, 'sorted');
    for LIndex := 0 to High(LSurfaces) do
    begin
      Assert.IsFalse(LSeen[LSurfaces[LIndex].Surface.Index], 'a surface is not there twice');
      LSeen[LSurfaces[LIndex].Surface.Index] := True;
    end;
  end;
end;

procedure TTestQ3DrawSurfSorter.DovrebbeOrdinareAncheICasiCortiEQuelliCheNonVannoOrdinati;
var
  LSurfaces: TArray<TQ3DrawSurf>;
  LCount, LIndex: Integer;
begin
  // zero and one element: nothing to do; up to 8: the selection sort; reversed, already sorted and equal
  for LCount := 0 to 12 do
  begin
    SetLength(LSurfaces, LCount);
    for LIndex := 0 to LCount - 1 do
      LSurfaces[LIndex].Sort := Cardinal(LCount - LIndex);
    TQ3DrawSurfSorter.Sort(LSurfaces, 0, LCount);
    for LIndex := 1 to LCount - 1 do
      Assert.IsTrue(LSurfaces[LIndex - 1].Sort <= LSurfaces[LIndex].Sort);
    TQ3DrawSurfSorter.Sort(LSurfaces, 0, LCount);
    for LIndex := 0 to LCount - 1 do
      LSurfaces[LIndex].Sort := 7;
    TQ3DrawSurfSorter.Sort(LSurfaces, 0, LCount);
    for LIndex := 0 to LCount - 1 do
      Assert.AreEqual<Cardinal>(7, LSurfaces[LIndex].Sort);
  end;
end;

procedure TTestQ3DrawSurfSorter.DovrebbeLasciareStareCioCheStaFuoriDalIntervallo;
var
  LSurfaces: TArray<TQ3DrawSurf>;
  LIndex: Integer;
begin
  SetLength(LSurfaces, 30);
  for LIndex := 0 to 29 do
    LSurfaces[LIndex].Sort := Cardinal(30 - LIndex);
  // the views of a scene are sorted one after the other in the same array: only the range of the view
  TQ3DrawSurfSorter.Sort(LSurfaces, 10, 15);
  Assert.AreEqual<Cardinal>(30, LSurfaces[0].Sort);
  Assert.AreEqual<Cardinal>(21, LSurfaces[9].Sort);
  Assert.AreEqual<Cardinal>(6, LSurfaces[10].Sort, 'the smallest of the range is the first of it');
  Assert.AreEqual<Cardinal>(20, LSurfaces[24].Sort);
  Assert.AreEqual<Cardinal>(5, LSurfaces[25].Sort);
end;

{ TTestQ3ViewCuller }

function MakeView(const AOrigin: TQ3Vec3; AYaw: Single; var AView: TQ3FrontViewParms): TQ3ViewOrientation;
var
  LAngles: TQ3Vec3;
begin
  AView := Default(TQ3FrontViewParms);
  AView.Orientation.Origin := AOrigin;
  LAngles[0] := 0;
  LAngles[1] := AYaw;
  LAngles[2] := 0;
  TQ3Math.AngleVectors(LAngles, AView.Orientation.Axis[0], AView.Orientation.Axis[1], AView.Orientation.Axis[2]);
  AView.FovX := 90;
  AView.FovY := 90;
  TQ3ViewSetup.RotateForViewer(AView, Result);
  TQ3ViewSetup.SetupFrustum(AView);
end;

procedure TTestQ3ViewCuller.DovrebbeTagliareIPuntiDietroOFuoriDallaPiramide;
var
  LView: TQ3FrontViewParms;
  LCuller: TQ3ViewCuller;
  LOrientation: TQ3ViewOrientation;
begin
  LCuller := TQ3ViewCuller.Create(False);
  try
    LOrientation := MakeView(Vec(0, 0, 0), 0, LView);
    LCuller.SetView(LView, LOrientation);
    // the viewer looks along +X
    Assert.AreEqual(CULL_IN, LCuller.CullPointAndRadius(Vec(100, 0, 0), 1));
    Assert.AreEqual(CULL_OUT, LCuller.CullPointAndRadius(Vec(-100, 0, 0), 1), 'behind');
    Assert.AreEqual(CULL_OUT, LCuller.CullPointAndRadius(Vec(10, 500, 0), 1), 'far to the left');
    Assert.AreEqual(CULL_OUT, LCuller.CullPointAndRadius(Vec(10, 0, -500), 1), 'far down');
  finally
    LCuller.Free;
  end;
end;

procedure TTestQ3ViewCuller.DovrebbeDireClipPerUnaSferaCheTagliaUnPiano;
var
  LView: TQ3FrontViewParms;
  LCuller: TQ3ViewCuller;
  LOrientation: TQ3ViewOrientation;
begin
  LCuller := TQ3ViewCuller.Create(False);
  try
    LOrientation := MakeView(Vec(0, 0, 0), 0, LView);
    LCuller.SetView(LView, LOrientation);
    // on the left plane of a 90 degree field: x = y; a sphere across it is clipped, a small one just inside is not
    Assert.AreEqual(CULL_CLIP, LCuller.CullPointAndRadius(Vec(100, 100, 0), 20));
    Assert.AreEqual(CULL_IN, LCuller.CullPointAndRadius(Vec(100, 0, 0), 20));
  finally
    LCuller.Free;
  end;
end;

procedure TTestQ3ViewCuller.DovrebbeClassificareUnaScatolaInLocale;
var
  LView: TQ3FrontViewParms;
  LCuller: TQ3ViewCuller;
  LOrientation: TQ3ViewOrientation;
begin
  LCuller := TQ3ViewCuller.Create(False);
  try
    LOrientation := MakeView(Vec(0, 0, 0), 0, LView);
    LCuller.SetView(LView, LOrientation);
    LOrientation := TQ3ViewSetup.IdentityOrientation;
    LCuller.SetOrientation(LOrientation);
    Assert.AreEqual(CULL_IN, LCuller.CullLocalBox(Vec(90, -5, -5), Vec(110, 5, 5)));
    Assert.AreEqual(CULL_OUT, LCuller.CullLocalBox(Vec(-110, -5, -5), Vec(-90, 5, 5)));
    Assert.AreEqual(CULL_CLIP, LCuller.CullLocalBox(Vec(-10, -5, -5), Vec(110, 5, 5)), 'across the viewer');
    // the box moves with the orientation of the entity: placed 1000 units to the right it is out
    LOrientation.Origin := Vec(0, 1000, 0);
    LCuller.SetOrientation(LOrientation);
    Assert.AreEqual(CULL_OUT, LCuller.CullLocalBox(Vec(90, -5, -5), Vec(110, 5, 5)));
  finally
    LCuller.Free;
  end;
end;

procedure TTestQ3ViewCuller.DovrebbeNonTagliareNullaConNoCull;
var
  LView: TQ3FrontViewParms;
  LCuller: TQ3ViewCuller;
  LOrientation: TQ3ViewOrientation;
begin
  LCuller := TQ3ViewCuller.Create(True);
  try
    LOrientation := MakeView(Vec(0, 0, 0), 0, LView);
    LCuller.SetView(LView, LOrientation);
    Assert.AreEqual(CULL_CLIP, LCuller.CullPointAndRadius(Vec(-100, 0, 0), 1), 'r_nocull answers clip');
    Assert.AreEqual(CULL_CLIP, LCuller.CullLocalBox(Vec(-110, -5, -5), Vec(-90, 5, 5)));
  finally
    LCuller.Free;
  end;
end;

{ TTestQ3SceneBuffers }

procedure TTestQ3SceneBuffers.DovrebbeFermarsiAlLimiteDelleEntita;
var
  LBuffers: TQ3SceneBuffers;
  LEntity: TQ3RefEntity;
  LIndex: Integer;
begin
  LBuffers := TQ3SceneBuffers.Create(Q3_MAX_POLYS, Q3_MAX_POLYVERTS);
  try
    LEntity := Default(TQ3RefEntity);
    LEntity.ReType := RT_SPRITE;
    for LIndex := 1 to Q3_ENTITYNUM_WORLD + 50 do
      LBuffers.AddEntity(LEntity);
    // ENTITYNUM_WORLD entities: the number of the world is not an entity
    Assert.AreEqual(Q3_ENTITYNUM_WORLD, LBuffers.EntityCount);
  finally
    LBuffers.Free;
  end;
end;

procedure TTestQ3SceneBuffers.DovrebbeRifiutareUnTipoDiEntitaCheNonEsiste;
var
  LBuffers: TQ3SceneBuffers;
  LEntity: TQ3RefEntity;
begin
  LBuffers := TQ3SceneBuffers.Create(Q3_MAX_POLYS, Q3_MAX_POLYVERTS);
  try
    LEntity := Default(TQ3RefEntity);
    LEntity.ReType := RT_MAX_REF_ENTITY_TYPE;
    Assert.WillRaise(
      procedure
      begin
        LBuffers.AddEntity(LEntity);
      end, EQ3RenderException);
  finally
    LBuffers.Free;
  end;
end;

procedure TTestQ3SceneBuffers.DovrebbeScartareLeLuciSenzaIntensitaEOltreIlLimite;
var
  LBuffers: TQ3SceneBuffers;
  LIndex: Integer;
begin
  LBuffers := TQ3SceneBuffers.Create(Q3_MAX_POLYS, Q3_MAX_POLYVERTS);
  try
    LBuffers.AddLight(Vec(0, 0, 0), 0, 1, 1, 1, False);
    LBuffers.AddLight(Vec(0, 0, 0), -5, 1, 1, 1, False);
    Assert.AreEqual(0, LBuffers.DlightCount, 'a light without intensity is not added');
    for LIndex := 1 to 40 do
      LBuffers.AddLight(Vec(0, 0, 0), 100, 1, 1, 1, LIndex mod 2 = 0);
    Assert.AreEqual(Q3_MAX_DLIGHTS, LBuffers.DlightCount);
    Assert.AreEqual<Integer>(100, Round(LBuffers.SceneDlights[0].Radius), 'the radius is the intensity');
  finally
    LBuffers.Free;
  end;
end;

procedure TTestQ3SceneBuffers.DovrebbeIniziareUnaScenaDopoQuellaChiusa;
var
  LBuffers: TQ3SceneBuffers;
  LEntity: TQ3RefEntity;
begin
  LBuffers := TQ3SceneBuffers.Create(Q3_MAX_POLYS, Q3_MAX_POLYVERTS);
  try
    LEntity := Default(TQ3RefEntity);
    LEntity.ReType := RT_BEAM;
    LBuffers.AddEntity(LEntity);
    LBuffers.AddEntity(LEntity);
    Assert.AreEqual<Integer>(2, Length(LBuffers.SceneEntities));
    // RE_RenderScene closes the scene: the next one sees only what it adds
    LBuffers.CloseScene;
    Assert.AreEqual<Integer>(0, Length(LBuffers.SceneEntities));
    LBuffers.AddEntity(LEntity);
    Assert.AreEqual<Integer>(1, Length(LBuffers.SceneEntities));
    Assert.AreEqual(3, LBuffers.EntityCount);
    LBuffers.ResetFrame;
    Assert.AreEqual(0, LBuffers.EntityCount);
  finally
    LBuffers.Free;
  end;
end;

procedure TTestQ3SceneBuffers.DovrebbeTrovareLaNebbiaDiUnPoligono;
var
  LBuffers: TQ3SceneBuffers;
  LFogs: TArray<TQ3WorldFog>;
  LVerts: TArray<TQ3PolyVert>;
  LIndex: Integer;
begin
  LBuffers := TQ3SceneBuffers.Create(Q3_MAX_POLYS, Q3_MAX_POLYVERTS);
  try
    SetLength(LFogs, 3);
    // the fog 1 is the box 0..100, the fog 2 the box 200..300
    LFogs[1].Mins := Vec(0, 0, 0);
    LFogs[1].Maxs := Vec(100, 100, 100);
    LFogs[2].Mins := Vec(200, 200, 200);
    LFogs[2].Maxs := Vec(300, 300, 300);
    LBuffers.SetFogs(LFogs);
    SetLength(LVerts, 3);
    for LIndex := 0 to 2 do
      LVerts[LIndex].Xyz := Vec(250 + LIndex, 250, 250);
    LBuffers.AddPolys(5, 3, LVerts, 1);
    for LIndex := 0 to 2 do
      LVerts[LIndex].Xyz := Vec(1000 + LIndex, 0, 0);
    LBuffers.AddPolys(5, 3, LVerts, 1);
    // two polys of the same call share the vertex list one after the other
    SetLength(LVerts, 6);
    for LIndex := 0 to 5 do
      LVerts[LIndex].Xyz := Vec(10 + LIndex, 10, 10);
    LBuffers.AddPolys(6, 3, LVerts, 2);
    Assert.AreEqual(4, LBuffers.PolyCount);
    Assert.AreEqual(2, LBuffers.ScenePolys[0].FogIndex);
    Assert.AreEqual(0, LBuffers.ScenePolys[1].FogIndex, 'in no fog');
    Assert.AreEqual(1, LBuffers.ScenePolys[2].FogIndex);
    Assert.AreEqual(6, LBuffers.ScenePolys[3].HShader);
  finally
    LBuffers.Free;
  end;
end;

{ TTestQ3SceneReader }

procedure TTestQ3SceneReader.DovrebbeAvereLeDimensioniDelleStrutture;
begin
  Assert.AreEqual(Q3_REFENTITY_SIZE, SizeOf(TQ3RefEntity), 'refEntity_t');
  Assert.AreEqual(Q3_POLYVERT_SIZE, SizeOf(TQ3PolyVert), 'polyVert_t');
end;

procedure TTestQ3SceneReader.DovrebbeLeggereUnRefdefDallaMemoria;
var
  LMemory: TFlatMemory;
  LKeeper: IQvmMemory;
  LRefDef: TQ3RefDef;
  LIndex: Integer;
begin
  LMemory := TFlatMemory.Create;
  LKeeper := LMemory;
  LMemory.WriteInt32(1000 + 0, 10);
  LMemory.WriteInt32(1000 + 4, 20);
  LMemory.WriteInt32(1000 + 8, 640);
  LMemory.WriteInt32(1000 + 12, 480);
  LMemory.WriteInt32(1000 + 16, TQ3SyscallArguments.FromSingle(90));
  LMemory.WriteInt32(1000 + 20, TQ3SyscallArguments.FromSingle(73.5));
  for LIndex := 0 to 2 do
    LMemory.WriteInt32(1000 + 24 + 4 * LIndex, TQ3SyscallArguments.FromSingle(100 + LIndex));
  for LIndex := 0 to 8 do
    LMemory.WriteInt32(1000 + 36 + 4 * LIndex, TQ3SyscallArguments.FromSingle(LIndex));
  LMemory.WriteInt32(1000 + 72, 5555);
  LMemory.WriteInt32(1000 + 76, RDF_NOWORLDMODEL);
  LMemory.WriteByte(1000 + 80 + 31, 129);
  LRefDef := TQ3SceneReader.ReadRefDef(LKeeper, 1000);
  Assert.AreEqual(10, LRefDef.X);
  Assert.AreEqual(480, LRefDef.Height);
  Assert.AreEqual<Single>(73.5, LRefDef.FovY);
  Assert.AreEqual<Single>(102, LRefDef.ViewOrigin[2]);
  Assert.AreEqual<Single>(5, LRefDef.ViewAxis[1][2]);
  Assert.AreEqual<Single>(8, LRefDef.ViewAxis[2][2]);
  Assert.AreEqual(5555, LRefDef.Time);
  Assert.AreEqual(RDF_NOWORLDMODEL, LRefDef.RdFlags);
  Assert.AreEqual<Integer>(129, LRefDef.AreaMask[31]);
end;

procedure TTestQ3SceneReader.DovrebbeLeggereUnaEntitaEUnColore;
var
  LMemory: TFlatMemory;
  LKeeper: IQvmMemory;
  LEntity: TQ3RefEntity;
  LColor: TArray<Single>;
begin
  LMemory := TFlatMemory.Create;
  LKeeper := LMemory;
  // reType 2 (sprite), renderfx 4, hModel 9, nonNormalizedAxes at 64, origin at 68, frame at 80, skinNum at 104,
  // customSkin at 108, shaderRGBA at 116, radius at 132
  LMemory.WriteInt32(2000, RT_SPRITE);
  LMemory.WriteInt32(2000 + 4, 4);
  LMemory.WriteInt32(2000 + 8, 9);
  LMemory.WriteInt32(2000 + 64, 1);
  LMemory.WriteInt32(2000 + 68, TQ3SyscallArguments.FromSingle(1.5));
  LMemory.WriteInt32(2000 + 72, TQ3SyscallArguments.FromSingle(2.5));
  LMemory.WriteInt32(2000 + 80, 11);
  LMemory.WriteInt32(2000 + 104, 4);
  LMemory.WriteInt32(2000 + 108, 5);
  LMemory.WriteByte(2000 + 116, 200);
  LMemory.WriteInt32(2000 + 132, TQ3SyscallArguments.FromSingle(16));
  LEntity := TQ3SceneReader.ReadRefEntity(LKeeper, 2000);
  Assert.AreEqual(RT_SPRITE, LEntity.ReType);
  Assert.AreEqual(4, LEntity.RenderFx);
  Assert.AreEqual(9, LEntity.HModel);
  Assert.AreEqual(1, LEntity.NonNormalizedAxes);
  Assert.AreEqual<Single>(1.5, LEntity.Origin[0]);
  Assert.AreEqual<Single>(2.5, LEntity.Origin[1]);
  Assert.AreEqual(11, LEntity.Frame);
  Assert.AreEqual(4, LEntity.SkinNum);
  Assert.AreEqual(5, LEntity.CustomSkin);
  Assert.AreEqual<Integer>(200, LEntity.ShaderRGBA[0]);
  Assert.AreEqual<Single>(16, LEntity.Radius);
  LColor := TQ3SceneReader.ReadColor(LKeeper, 0);
  Assert.AreEqual<Integer>(0, Length(LColor), 'NULL is white for the caller');
  LMemory.WriteInt32(3000, TQ3SyscallArguments.FromSingle(0.25));
  LColor := TQ3SceneReader.ReadColor(LKeeper, 3000);
  Assert.AreEqual<Integer>(4, Length(LColor));
  Assert.AreEqual<Single>(0.25, LColor[0]);
end;

{ TTestQ3ShaderTable }

const
  TABLE_SCRIPT =
    'textures/test/two' + #10 + '{' + #10 + '  { map textures/a.tga' + #10 + '    blendFunc add }' + #10 +
    '  { map $lightmap }' + #10 + '}' + #10 +
    'textures/test/missing' + #10 + '{' + #10 + '  { map textures/nowhere.tga }' + #10 + '}' + #10;

function TableRig(out ATable: TQ3ShaderTable; out AKeeper: IQ3ShaderTable; out AFiles: IQ3RenderFiles;
  out ASystem: IQ3RenderSystem): Boolean;
var
  LMemory: TMemoryFiles;
  LImage: TBytes;
begin
  LMemory := TMemoryFiles.Create;
  AFiles := LMemory;
  LImage := TFile.ReadAllBytes(TTestFiles.FindFileUp('Tests\Data\Q3Render\tga\rgba32.tga'));
  LMemory.Add('textures/a.tga', LImage);
  LMemory.Add('textures/implicit.tga', LImage);
  ASystem := TTestSupport.BuildSystem(AFiles, [TPair<string, string>.Create('scripts/test.shader', TABLE_SCRIPT)]);
  ATable := TQ3ShaderTable.Create(ASystem.Shaders);
  AKeeper := ATable;
  Result := True;
end;

procedure TTestQ3ShaderTable.DovrebbeCominciareConLoShaderDiDefaultELOmbra;
var
  LTable: TQ3ShaderTable;
  LKeeper: IQ3ShaderTable;
  LFiles: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  TableRig(LTable, LKeeper, LFiles, LSystem);
  Assert.AreEqual(2, LKeeper.Count);
  Assert.IsTrue(LKeeper.GetEntry(0).IsDefault);
  Assert.AreEqual<Single>(SS_OPAQUE, LKeeper.GetEntry(0).Data.Sort);
  // a shader with no passes sorts as the fog: the shadow marker is one
  Assert.AreEqual<Single>(SS_FOG, LKeeper.GetEntry(1).Data.Sort);
  Assert.AreEqual(0, LKeeper.SortedIndexOf(0));
  Assert.AreEqual(1, LKeeper.SortedIndexOf(1));
  // an index that is not in the table is the default shader
  Assert.AreEqual(0, LKeeper.GetEntry(77).SortedIndex);
end;

procedure TTestQ3ShaderTable.DovrebbeFareLeVarianteDiUnoShaderImplicitoPerOgniIndiceDiLightmap;
var
  LTable: TQ3ShaderTable;
  LKeeper: IQ3ShaderTable;
  LFiles: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LNone, LVertex, L2D, LLightmap, LWhite, LAgain: Integer;
  LEntry: TQ3ShaderEntry;
begin
  TableRig(LTable, LKeeper, LFiles, LSystem);
  LKeeper.SetLightmapCount(2);
  LNone := LKeeper.FindShader('textures/implicit', LIGHTMAP_NONE);
  LVertex := LKeeper.FindShader('textures/implicit', LIGHTMAP_BY_VERTEX);
  L2D := LKeeper.FindShader('textures/implicit', LIGHTMAP_2D);
  LLightmap := LKeeper.FindShader('textures/implicit', 1);
  LWhite := LKeeper.FindShader('textures/implicit', LIGHTMAP_WHITEIMAGE);
  Assert.AreEqual(5, LKeeper.Count - 2, 'five variants, five entries');
  LEntry := LKeeper.GetEntry(LNone);
  Assert.IsTrue(LEntry.Data.Stages[0].RgbGen = cgLightingDiffuse, 'dynamic colours at the vertexes');
  LEntry := LKeeper.GetEntry(LVertex);
  Assert.IsTrue(LEntry.Data.Stages[0].RgbGen = cgExactVertex);
  Assert.IsTrue(LEntry.Data.Stages[0].AlphaGen = agSkip);
  LEntry := LKeeper.GetEntry(L2D);
  Assert.IsTrue((LEntry.Data.Stages[0].StateBits and GLS_DEPTHTEST_DISABLE) <> 0, 'the interface has no depth test');
  Assert.IsTrue(LEntry.Data.Stages[0].AlphaGen = agVertex);
  Assert.AreEqual<Single>(SS_BLEND0, LEntry.Data.Sort);
  LEntry := LKeeper.GetEntry(LLightmap);
  // two passes: the lightmap and the image: with two texture units they are one pass with a second bundle
  Assert.AreEqual(1, LEntry.Data.NumUnfoggedPasses);
  Assert.AreEqual('textures/implicit.tga', string(LEntry.Data.Stages[0].Bundle.ImageNames[0]));
  Assert.IsTrue(LEntry.Data.Stages[0].Bundle2.IsLightmap);
  Assert.AreEqual(1, LEntry.LightmapIndex);
  Assert.IsTrue(LEntry.Data.MultitextureEnv = meModulate);
  Assert.AreEqual('$whiteimage', string(LKeeper.GetEntry(LWhite).Data.Stages[0].Bundle.ImageNames[0]),
    'the white image for the fullbright level');
  // the same name and lightmap again is the same entry, whatever the case
  LAgain := LKeeper.FindShader('TEXTURES/IMPLICIT.tga', 1);
  Assert.AreEqual(LLightmap, LAgain);
  // a lightmap that the world does not have is vertex lighting
  Assert.AreEqual(LVertex, LKeeper.FindShader('textures/implicit', 7));
end;

procedure TTestQ3ShaderTable.DovrebbeTenereLeVarianteDiUnoScriptSecondoLaLightmap;
var
  LTable: TQ3ShaderTable;
  LKeeper: IQ3ShaderTable;
  LFiles: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LWith, LWithout: Integer;
begin
  TableRig(LTable, LKeeper, LFiles, LSystem);
  LKeeper.SetLightmapCount(4);
  LWith := LKeeper.FindShader('textures/test/two', 3);
  LWithout := LKeeper.FindShader('textures/test/two', LIGHTMAP_NONE);
  Assert.AreNotEqual(LWith, LWithout);
  Assert.AreEqual(3, LKeeper.GetEntry(LWith).LightmapIndex, 'the shader has a lightmap stage: it keeps the number');
  Assert.AreEqual(LIGHTMAP_NONE, LKeeper.GetEntry(LWithout).LightmapIndex);
end;

procedure TTestQ3ShaderTable.DovrebbeDareZeroPerNomiVuotiEShaderDifettosi;
var
  LTable: TQ3ShaderTable;
  LKeeper: IQ3ShaderTable;
  LFiles: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  TableRig(LTable, LKeeper, LFiles, LSystem);
  Assert.AreEqual(0, LKeeper.FindShader('', LIGHTMAP_NONE));
  Assert.AreEqual(0, LKeeper.FindShader('textures/test/missing', LIGHTMAP_NONE), 'an image is not there');
  Assert.AreEqual(0, LKeeper.FindShader('textures/not_a_shader', LIGHTMAP_2D));
  Assert.AreEqual(2, LKeeper.Count, 'a defective shader is the default shader, not a new entry');
end;

procedure TTestQ3ShaderTable.DovrebbeInserireNellaListaOrdinataDopoQuelliConLaStessaSort;
var
  LTable: TQ3ShaderTable;
  LKeeper: IQ3ShaderTable;
  LFiles: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LBlend, LOpaque: Integer;
begin
  TableRig(LTable, LKeeper, LFiles, LSystem);
  // default (opaque 3), shadow (fog 7), then a blend (9): sorted 0, 1, 2
  LBlend := LKeeper.FindShader('textures/implicit', LIGHTMAP_2D);
  Assert.AreEqual(2, LKeeper.SortedIndexOf(LBlend));
  // an opaque one goes after the default and before the shadow: the later ones move up
  LOpaque := LKeeper.FindShader('textures/implicit', LIGHTMAP_BY_VERTEX);
  Assert.AreEqual(1, LKeeper.SortedIndexOf(LOpaque));
  Assert.AreEqual(2, LKeeper.SortedIndexOf(1), 'the shadow moved');
  Assert.AreEqual(3, LKeeper.SortedIndexOf(LBlend), 'the blend moved');
  Assert.AreEqual(LOpaque, LKeeper.GetSortedShader(1));
  Assert.AreEqual(LBlend, LKeeper.GetSortedShader(3));
end;

{ TTestQ3CommandList }

procedure TTestQ3CommandList.DovrebbeTenereICommandiNellOrdineEIlBiancoDiSetColor;
var
  LList: TQ3CommandList;
  LColor: TArray<Single>;
begin
  LList := TQ3CommandList.Create;
  try
    LList.AddDrawBuffer;
    LList.AddSetColor(nil);
    SetLength(LColor, 4);
    LColor[0] := 0.5;
    LColor[1] := 0.25;
    LColor[2] := 1;
    LColor[3] := 0;
    LList.AddSetColor(LColor);
    LList.AddStretchPic(7, 1, 2, 3, 4, 0, 0, 1, 1);
    LList.AddSwapBuffers;
    Assert.AreEqual(5, LList.Count);
    Assert.IsTrue(LList.Item(0).Kind = rcDrawBuffer);
    Assert.AreEqual<Single>(1, LList.Item(1).Color[3], 'NULL is white');
    Assert.AreEqual<Single>(0.25, LList.Item(2).Color[1]);
    Assert.AreEqual(7, LList.Item(3).Shader);
    Assert.AreEqual<Single>(4, LList.Item(3).H);
    Assert.IsTrue(LList.Item(4).Kind = rcSwapBuffers);
    LList.Clear;
    Assert.AreEqual(0, LList.Count);
  finally
    LList.Free;
  end;
end;

end.
