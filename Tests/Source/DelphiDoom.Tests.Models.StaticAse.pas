{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the ASE reader and converter   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticAse;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf;

type
  [TestFixture]
  [Category('Models')]
  TTestStaticAse = class
  strict private
    function Load(const AText: AnsiString; const AOptions: TStaticLoadOptions): IStaticModel; overload;
    function Load(const AText: AnsiString): IStaticModel; overload;
    /// <summary>The line of the exception that the text raises, 0 if it does not raise one with ATextPart</summary>
    function FailLine(const AText: AnsiString; const AFragment: string): Integer;
    function Fails(const AText: AnsiString; const AFragment: string): Boolean;
    /// <summary>A triangle in an object with a material, with the lines of the mesh given</summary>
    function Wrap(const AMeshLines: AnsiString; const AMaterialRef: Integer = 0): AnsiString;
  public
    [Test]
    procedure DovrebbeFareOttoVertexPerIlCuboSenzaNormali;
    [Test]
    procedure DovrebbeDareIlNomeDelMaterialeDalPercorsoDellaBitmap;
    [Test]
    procedure DovrebbeUsareIlRisolutoreDeiPercorsi;
    [Test]
    procedure DovrebbeApplicareLaMatriceDiTextureDelMateriale;
    [Test]
    procedure DovrebbeInvertereLaVDelleCoordinateDiTexture;
    [Test]
    procedure DovrebbeInvertireLOrdineDeiVertexDelleFacce;
    [Test]
    procedure DovrebbeChiedereLaGenerazioneDelleNormaliSeNonCiSono;
    [Test]
    procedure DovrebbeFare16VertexQuandoLeNormaliDifferiscono;
    [Test]
    procedure DovrebbeNormalizzareLeNormaliDelFile;
    [Test]
    procedure DovrebbeApplicareLaMatriceDelNodoAlleNormali;
    [Test]
    procedure DovrebbeMetterePiattoUnModelloSenzaMateriali;
    [Test]
    procedure DovrebbeUnireGliOggettiDelloStessoMateriale;
    [Test]
    procedure DovrebbeTenereSeparatiGliOggettiSeLOpzioneNonUnisce;
    [Test]
    procedure DovrebbeLeggereIFotogrammiDiUnaAnimazione;
    [Test]
    procedure DovrebbeLeggereIColoriDeiVertexConIlDifettoDelCpp;
    [Test]
    procedure DovrebbeRifiutareUnTokenSconosciutoNellaListaDeiVertexConLaRiga;
    [Test]
    procedure DovrebbeRifiutareUnaParentesiGraffaInPiu;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiFacceDiTextureDiverso;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiVertexFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiTextureFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareLeFacceDiTexturePrimaDelleFacce;
    [Test]
    procedure DovrebbeRifiutareUnaNormaleDiVertexCheNonEDellaFaccia;
    [Test]
    procedure DovrebbeRifiutareUnaNormaleDiFacciaFuoriPosto;
    [Test]
    procedure DovrebbeRifiutareUnMaterialeCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaOggetti;
    [Test]
    procedure DovrebbeSaltareScenaCameraEForme;
    [Test]
    procedure DovrebbeTrattareICaratteriOltre127ComeSeparatori;
    [Test]
    procedure DovrebbeLeggereIlGruppoDiOggetti;
    [Test]
    procedure DovrebbeLeggereIFileDiDati;
  end;

implementation

uses
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Ase.Types,
  DelphiDoom.Models.Static.Ase.Parser,
  DelphiDoom.Tests.Models.StaticBuilders;

{ TTestStaticAse }

function TTestStaticAse.Load(const AText: AnsiString; const AOptions: TStaticLoadOptions): IStaticModel;
begin
  Result := TStaticModelFactory.CreateAseLoader(AOptions).Load(TBytes(BytesOf(AText)), 'test.ase');
end;

function TTestStaticAse.Load(const AText: AnsiString): IStaticModel;
begin
  Result := Load(AText, TStaticLoadOptions.Default);
end;

function TTestStaticAse.FailLine(const AText: AnsiString; const AFragment: string): Integer;
begin
  Result := 0;
  try
    Load(AText);
  except
    on E: EStaticModelException do
      if E.Message.Contains(AFragment) then
        Result := E.Line;
  end;
end;

function TTestStaticAse.Fails(const AText: AnsiString; const AFragment: string): Boolean;
begin
  Result := False;
  try
    Load(AText);
  except
    on E: EStaticModelException do
      Result := E.Message.Contains(AFragment);
  end;
end;

function TTestStaticAse.Wrap(const AMeshLines: AnsiString; const AMaterialRef: Integer): AnsiString;
begin
  Result := '*MATERIAL_LIST {'#10'*MATERIAL_COUNT 1'#10'*MATERIAL 0 {'#10'*MAP_DIFFUSE {'#10 +
    '*BITMAP "a\b.tga"'#10'}'#10'}'#10'}'#10'*GEOMOBJECT {'#10'*NODE_TM {'#10'*TM_ROW0 1 0 0'#10'*TM_ROW1 0 1 0'#10 +
    '*TM_ROW2 0 0 1'#10'*TM_ROW3 0 0 0'#10'}'#10'*MESH {'#10 + AMeshLines +
    '}'#10'*MATERIAL_REF ' + AnsiString(IntToStr(AMaterialRef)) + #10'}'#10;
end;

procedure TTestStaticAse.DovrebbeFareOttoVertexPerIlCuboSenzaNormali;
var
  LModel: IStaticModel;
begin
  LModel := Load(BuildCubeAse(False));
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual(8, LModel.Surfaces[0].Triangles.NumVerts);
  Assert.AreEqual(36, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.AreEqual<Single>(-1, LModel.Bounds.Mins.X);
  Assert.AreEqual<Single>(1, LModel.Bounds.Maxs.Z);
end;

procedure TTestStaticAse.DovrebbeDareIlNomeDelMaterialeDalPercorsoDellaBitmap;
begin
  Assert.AreEqual('C:/work/base/textures/test/cube.tga', string(Load(BuildCubeAse(False)).Surfaces[0].MaterialName));
end;

procedure TTestStaticAse.DovrebbeUsareIlRisolutoreDeiPercorsi;
var
  LModel: IStaticModel;
begin
  LModel := TStaticModelFactory.CreateAseLoader(TStaticLoadOptions.Default,
    function(const APath: AnsiString): AnsiString
    begin
      Result := Copy(APath, Pos('textures', string(APath)), MaxInt);
    end).Load(TBytes(BytesOf(BuildCubeAse(False))), 'x.ase');
  Assert.AreEqual('textures/test/cube.tga', string(LModel.Surfaces[0].MaterialName));
end;

procedure TTestStaticAse.DovrebbeApplicareLaMatriceDiTextureDelMateriale;
var
  LVertex: TStaticDrawVert;
begin
  // the vertex of the point 0: tvert (0, 1 - 0); u = 0 * 2 - 0.25, v = 1 * 0.5 + 0.5; angle 0.5
  LVertex := Load(BuildCubeAse(False)).Surfaces[0].Triangles.Verts[0];
  Assert.AreEqual(-0.25 * Cos(0.5) + 1.0 * Sin(0.5), LVertex.St.X, 1e-6);
  Assert.AreEqual(0.25 * Sin(0.5) + 1.0 * Cos(0.5), LVertex.St.Y, 1e-6);
end;

procedure TTestStaticAse.DovrebbeInvertereLaVDelleCoordinateDiTexture;
var
  LModel: IStaticModel;
begin
  LModel := Load(Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1 BC: 1 CA: 1'#10'}'#10 +
    '*MESH_NUMTVERTEX 3'#10'*MESH_TVERTLIST {'#10'*MESH_TVERT 0 0.25 0.75 0'#10'*MESH_TVERT 1 0.5 0.5 0'#10 +
    '*MESH_TVERT 2 0 0 0'#10'}'#10'*MESH_NUMTVFACES 1'#10'*MESH_TFACELIST {'#10'*MESH_TFACE 0 0 1 2'#10'}'#10));
  // no texture matrix: st = (u, 1 - v); the vertex of the face 0 is the first
  Assert.AreEqual<Single>(0.25, LModel.Surfaces[0].Triangles.Verts[0].St.X);
  Assert.AreEqual<Single>(0.25, LModel.Surfaces[0].Triangles.Verts[0].St.Y);
end;

procedure TTestStaticAse.DovrebbeInvertireLOrdineDeiVertexDelleFacce;
var
  LTriangles: TStaticTriangles;
begin
  // the file says A: 0 B: 1 C: 2; the engine wants 0, 2, 1
  LTriangles := Load(Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1 BC: 1 CA: 1'#10'}'#10)).Surfaces[0].Triangles;
  Assert.AreEqual<Single>(0, LTriangles.Verts[LTriangles.Indexes[0]].Xyz.X);
  Assert.AreEqual<Single>(0, LTriangles.Verts[LTriangles.Indexes[1]].Xyz.X, 'the second is the point 2');
  Assert.AreEqual<Single>(1, LTriangles.Verts[LTriangles.Indexes[1]].Xyz.Y);
  Assert.AreEqual<Single>(1, LTriangles.Verts[LTriangles.Indexes[2]].Xyz.X);
end;

procedure TTestStaticAse.DovrebbeChiedereLaGenerazioneDelleNormaliSeNonCiSono;
begin
  Assert.IsTrue(Load(BuildCubeAse(False)).Surfaces[0].Triangles.GenerateNormals);
  Assert.IsFalse(Load(BuildCubeAse(True)).Surfaces[0].Triangles.GenerateNormals);
end;

procedure TTestStaticAse.DovrebbeFare16VertexQuandoLeNormaliDifferiscono;
begin
  Assert.AreEqual(16, Load(BuildCubeAse(True)).Surfaces[0].Triangles.NumVerts);
end;

procedure TTestStaticAse.DovrebbeNormalizzareLeNormaliDelFile;
var
  LModel: IStaticModel;
begin
  LModel := Load(Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1 BC: 1 CA: 1'#10'}'#10 +
    '*MESH_NORMALS {'#10'*MESH_FACENORMAL 0 0 0 3'#10'*MESH_VERTEXNORMAL 0 0 3 4'#10 +
    '*MESH_VERTEXNORMAL 1 0 0 2'#10'*MESH_VERTEXNORMAL 2 0 0 5'#10'}'#10));
  Assert.AreEqual(0.6, LModel.Surfaces[0].Triangles.Verts[0].Normal.Y, 1e-4);
  Assert.AreEqual(0.8, LModel.Surfaces[0].Triangles.Verts[0].Normal.Z, 1e-4);
end;

procedure TTestStaticAse.DovrebbeApplicareLaMatriceDelNodoAlleNormali;
var
  LModel: IStaticModel;
begin
  // the rows of the matrix: a normal (0, 0, 1) goes to row 2, (0, 1, 0)
  LModel := Load('*MATERIAL_LIST {'#10'*MATERIAL 0 {'#10'}'#10'}'#10'*GEOMOBJECT {'#10'*NODE_TM {'#10 +
    '*TM_ROW0 1 0 0'#10'*TM_ROW1 0 1 0'#10'*TM_ROW2 0 1 0'#10'*TM_ROW3 0 0 0'#10'}'#10'*MESH {'#10 +
    '*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10'*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10 +
    '*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10'*MESH_FACE_LIST {'#10 +
    '*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'}'#10'*MESH_NORMALS {'#10'*MESH_FACENORMAL 0 0 0 1'#10 +
    '*MESH_VERTEXNORMAL 0 0 0 1'#10'*MESH_VERTEXNORMAL 1 0 0 1'#10'*MESH_VERTEXNORMAL 2 0 0 1'#10'}'#10 +
    '}'#10'}'#10);
  Assert.AreEqual(1, LModel.Surfaces[0].Triangles.Verts[0].Normal.Y, 1e-6);
  Assert.AreEqual(0, LModel.Surfaces[0].Triangles.Verts[0].Normal.Z, 1e-6);
end;

procedure TTestStaticAse.DovrebbeMetterePiattoUnModelloSenzaMateriali;
var
  LModel: IStaticModel;
  LVertex: TStaticDrawVert;
begin
  LModel := Load(BuildCubeAse(False, False));
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual(STATIC_DEFAULT_MATERIAL, string(LModel.Surfaces[0].MaterialName));
  // no matrix: st = (u, 1 - v) of the point 0 (0, 1)
  LVertex := LModel.Surfaces[0].Triangles.Verts[0];
  Assert.AreEqual<Single>(0, LVertex.St.X);
  Assert.AreEqual<Single>(1, LVertex.St.Y);
end;

procedure TTestStaticAse.DovrebbeUnireGliOggettiDelloStessoMateriale;
var
  LText: AnsiString;
  LModel: IStaticModel;
begin
  LText := BuildCubeAse(False);
  // the same object twice, the same material: one surface, the geometry of both
  LModel := Load(LText + Copy(LText, Pos('*GEOMOBJECT', string(LText)), MaxInt));
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual(16, LModel.Surfaces[0].Triangles.NumVerts);
  Assert.AreEqual(72, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.AreEqual<Integer>(8, LModel.Surfaces[0].Triangles.Indexes[36]);
end;

procedure TTestStaticAse.DovrebbeTenereSeparatiGliOggettiSeLOpzioneNonUnisce;
var
  LText: AnsiString;
  LModel: IStaticModel;
  LOptions: TStaticLoadOptions;
begin
  LOptions := TStaticLoadOptions.Default;
  LOptions.MergeSurfaces := False;
  LText := BuildCubeAse(False);
  LModel := Load(LText + Copy(LText, Pos('*GEOMOBJECT', string(LText)), MaxInt), LOptions);
  Assert.AreEqual(2, LModel.NumSurfaces);
  Assert.AreEqual(8, LModel.Surfaces[1].Triangles.NumVerts);
end;

procedure TTestStaticAse.DovrebbeLeggereIFotogrammiDiUnaAnimazione;
const
  TEXT_FRAMES = '*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMVERTEX 1'#10'*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'}'#10'}'#10 +
    '*MESH_ANIMATION {'#10'*MESH {'#10'*TIMEVALUE 160'#10'*MESH_NUMVERTEX 1'#10'*MESH_VERTEX_LIST {'#10 +
    '*MESH_VERTEX 0 5 6 7'#10'}'#10'}'#10'*MESH {'#10'*TIMEVALUE 320'#10'}'#10'}'#10'}'#10;
var
  LParser: TAseParser;
  LModel: TAseModel;
begin
  LParser := TAseParser.Create;
  try
    LModel := LParser.Parse(TEXT_FRAMES);
  finally
    LParser.Free;
  end;
  Assert.AreEqual(1, Length(LModel.Objects));
  Assert.AreEqual(2, Length(LModel.Objects[0].Frames));
  Assert.AreEqual(160, LModel.Objects[0].Frames[0].TimeValue);
  Assert.AreEqual<Single>(6, LModel.Objects[0].Frames[0].Vertexes[0].Y);
  Assert.AreEqual(320, LModel.Objects[0].Frames[1].TimeValue);
  Assert.AreEqual<Single>(0, LModel.Objects[0].Mesh.Vertexes[0].Y, 'the frames do not touch the mesh');
end;

procedure TTestStaticAse.DovrebbeLeggereIColoriDeiVertexConIlDifettoDelCpp;
var
  LModel: IStaticModel;
begin
  // the original reads the colour from the name of the key: every colour is (0, 0, 0)
  LModel := Load(Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'}'#10 +
    '*MESH_NUMTVFACES 1'#10'*MESH_NUMCVERTEX 3'#10'*MESH_CVERTLIST {'#10'*MESH_VERTCOL 0 1.0 0.5 0.25'#10 +
    '*MESH_VERTCOL 1 1 1 1'#10'*MESH_VERTCOL 2 1 1 1'#10'}'#10'*MESH_NUMCVFACES 1'#10 +
    '*MESH_CFACELIST {'#10'*MESH_CFACE 0 0 1 2'#10'}'#10));
  Assert.AreEqual<Integer>(0, LModel.Surfaces[0].Triangles.Verts[0].Color.R);
  Assert.AreEqual<Integer>(0, LModel.Surfaces[0].Triangles.Verts[0].Color.G);
  Assert.AreEqual<Integer>(0, LModel.Surfaces[0].Triangles.Verts[0].Color.B);
end;

procedure TTestStaticAse.DovrebbeRifiutareUnTokenSconosciutoNellaListaDeiVertexConLaRiga;
begin
  Assert.AreEqual(5, FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMVERTEX 1'#10'*MESH_VERTEX_LIST {'#10'*BOH 1'#10'}'#10'}'#10'}'#10,
    'unknown token "*BOH"'));
end;

procedure TTestStaticAse.DovrebbeRifiutareUnaParentesiGraffaInPiu;
begin
  Assert.AreEqual(2, FailLine('*GROUP "g"'#10'}'#10, 'unexpected'));
end;

procedure TTestStaticAse.DovrebbeRifiutareUnNumeroDiFacceDiTextureDiverso;
begin
  Assert.IsTrue(FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMFACES 2'#10'*MESH_NUMTVFACES 1'#10'}'#10'}'#10,
    'MESH_NUMTVFACES') > 0);
  // the check of NUMCVFACES compares the texture faces (as the original)
  Assert.IsTrue(FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMFACES 2'#10'*MESH_NUMCVFACES 2'#10'}'#10'}'#10,
    'MESH_NUMTVFACES') > 0);
end;

procedure TTestStaticAse.DovrebbeRifiutareUnIndiceDiVertexFuoriIntervallo;
begin
  Assert.IsTrue(Fails(Wrap('*MESH_NUMVERTEX 2'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 5 AB: 1'#10'}'#10), 'bad vertex index'));
end;

procedure TTestStaticAse.DovrebbeRifiutareUnIndiceDiTextureFuoriIntervallo;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    Load(Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10 +
      '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
      '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'}'#10 +
      '*MESH_NUMTVERTEX 1'#10'*MESH_TVERTLIST {'#10'*MESH_TVERT 0 0 0 0'#10'}'#10'*MESH_NUMTVFACES 1'#10 +
      '*MESH_TFACELIST {'#10'*MESH_TFACE 0 0 1 9'#10'}'#10));
  except
    on E: EStaticModelException do
      LRaised := E.Message.Contains('tex coord');
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestStaticAse.DovrebbeRifiutareLeFacceDiTexturePrimaDelleFacce;
begin
  Assert.IsTrue(FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_TFACELIST {'#10'}'#10'}'#10'}'#10, 'before *MESH_FACE_LIST') > 0);
end;

procedure TTestStaticAse.DovrebbeRifiutareUnaNormaleDiVertexCheNonEDellaFaccia;
begin
  Assert.IsTrue(FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMVERTEX 5'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'}'#10'*MESH_NORMALS {'#10'*MESH_FACENORMAL 0 0 0 1'#10 +
    '*MESH_VERTEXNORMAL 4 0 0 1'#10'}'#10'}'#10'}'#10, 'vertex index does not match') > 0);
end;

procedure TTestStaticAse.DovrebbeRifiutareUnaNormaleDiFacciaFuoriPosto;
begin
  Assert.IsTrue(FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 2'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'*MESH_FACE 1: A: 0 B: 1 C: 2 AB: 1'#10'}'#10 +
    '*MESH_NORMALS {'#10'*MESH_FACENORMAL 1 0 0 1'#10'}'#10'}'#10'}'#10, 'face index != currentFace') > 0);
  Assert.IsTrue(FailLine('*GEOMOBJECT {'#10'*MESH {'#10'*MESH_NUMFACES 2'#10'*MESH_NORMALS {'#10 +
    '*MESH_FACENORMAL 9 0 0 1'#10'}'#10'}'#10'}'#10, 'face index out of range') > 0);
end;

procedure TTestStaticAse.DovrebbeRifiutareUnMaterialeCheNonEsiste;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    Load(Wrap('*MESH_NUMVERTEX 0'#10'*MESH_NUMFACES 0'#10, 4));
  except
    on E: EStaticModelException do
      LRaised := E.Message.Contains('material 4');
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestStaticAse.DovrebbeRifiutareUnFileSenzaOggetti;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    Load('*3DSMAX_ASCIIEXPORT 200'#10'*SCENE {'#10'}'#10);
  except
    on E: EStaticModelException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestStaticAse.DovrebbeSaltareScenaCameraEForme;
var
  LModel: IStaticModel;
begin
  LModel := Load('*COMMENT "x y z"'#10'*SCENE { *SCENE_AMBIENT_STATIC 0 0 0 }'#10'*CAMERAOBJECT { *NODE_NAME "c" }'#10 +
    '*SHAPEOBJECT { *NODE_NAME "s" }'#10'*UNKNOWN_KEY 1'#10 + Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'}'#10));
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
end;

procedure TTestStaticAse.DovrebbeTrattareICaratteriOltre127ComeSeparatori;
var
  LText: AnsiString;
  LModel: IStaticModel;
begin
  // the original compares a signed char: a byte of 128 or more is a delimiter
  LText := Wrap('*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES' + AnsiChar($E0) + '1'#10 +
    '*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10'*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10 +
    '*MESH_FACE_LIST {'#10'*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1'#10'}'#10);
  LModel := Load(LText);
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
end;

procedure TTestStaticAse.DovrebbeLeggereIlGruppoDiOggetti;
var
  LText: AnsiString;
  LModel: IStaticModel;
begin
  LText := BuildCubeAse(False);
  LText := Copy(LText, 1, Pos('*GEOMOBJECT', string(LText)) - 1) + '*GROUP "g" {'#10 +
    Copy(LText, Pos('*GEOMOBJECT', string(LText)), MaxInt) + '}'#10;
  LModel := Load(LText);
  Assert.AreEqual(8, LModel.TotalVerts);
end;

procedure TTestStaticAse.DovrebbeLeggereIFileDiDati;
var
  LData: TBytes;
begin
  LData := StaticDataFile('cube.ase');
  Assert.AreEqual(8, TStaticModelFactory.CreateAseLoader.Load(LData, 'cube.ase').TotalVerts);
  LData := StaticDataFile('cube_normals.ase');
  Assert.AreEqual(16, TStaticModelFactory.CreateAseLoader.Load(LData, 'n.ase').TotalVerts);
  LData := StaticDataFile('cube_nomaterial.ase');
  Assert.AreEqual(8, TStaticModelFactory.CreateAseLoader.Load(LData, 'm.ase').TotalVerts);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStaticAse);

end.
