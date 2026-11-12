{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - TI3dMeshBuilder                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dMeshBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

type
  [TestFixture]
  [Category('models')]
  TTestModelsI3dMeshBuilder = class(TObject)
  strict private
    FMesh: II3dMeshBuilder;
    procedure Fan(ACount: Integer);
    procedure AssertVertex(const AVertex: TI3dMeshVertex; AX, AY, AZ: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeFareDiUnVentaglioITriangoliDalPrimoVertice;
    [Test]
    procedure DovrebbeFareDueTriangoliDiUnQuadrilatero;
    [Test]
    procedure DovrebbeGirareITriangoliDispariDiUnaStriscia;
    [Test]
    procedure DovrebbePrendereITriangoliATreATre;
    [Test]
    procedure DovrebbeScartareLineeEPrimitiveConMenoDiTreVertici;
    [Test]
    procedure DovrebbeIgnorareIVerticiFuoriDaUnaPrimitiva;
    [Test]
    procedure DovrebbeTenereIlPuntoDellaTexturaDiOgniVertice;
    [Test]
    procedure DovrebbeSepararePerTexturaEPerColore;
    [Test]
    procedure DovrebbeRiunireLeFacceConLoStessoStato;
    [Test]
    procedure DovrebbeNonDareTexturaSenzaTexturing;
    [Test]
    procedure DovrebbeTraslareIVertici;
    [Test]
    procedure DovrebbeScalarePrimaDiTraslareComeOpenGl;
    [Test]
    procedure DovrebbeRuotareDiNovantaGradiAttornoAZ;
    [Test]
    procedure DovrebbeNonRuotareAttornoAUnAsseNullo;
    [Test]
    procedure DovrebbeRipristinareLaMatriceConPop;
    [Test]
    procedure DovrebbeDareEccezioneSeLoStackEVuoto;
    [Test]
    procedure DovrebbeDareEccezionePerUnLottoCheNonEsiste;
    [Test]
    procedure DovrebbeDimenticareTuttoConClear;
    [Test]
    procedure DovrebbeDareITriangoliDiUnModelloDisegnatoDalRenderer;
    [Test]
    procedure DovrebbeSpostareLeGommeDiUnAutoQuandoGirano;
    [Test]
    procedure DovrebbeAvereUnVerticeDiVentiByte;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Factory, DelphiDoom.Models.I3d.MeshBuilder,
  DelphiDoom.Tests.Models.I3dFileBuilder;

const
  TOLERANCE = 0.0001;

{ TTestModelsI3dMeshBuilder }

procedure TTestModelsI3dMeshBuilder.Setup;
begin
  FMesh := TI3dFactory.CreateMeshBuilder;
end;

procedure TTestModelsI3dMeshBuilder.TearDown;
begin
  FMesh := nil;
end;

procedure TTestModelsI3dMeshBuilder.Fan(ACount: Integer);
var
  LIndex: Integer;
begin
  FMesh.BeginPrimitive(I3D_MESH_TRIANGLE_FAN);
  for LIndex := 0 to ACount - 1 do
    FMesh.Vertex3f(LIndex, LIndex * 10, 0);
  FMesh.EndPrimitive;
end;

procedure TTestModelsI3dMeshBuilder.AssertVertex(const AVertex: TI3dMeshVertex; AX, AY, AZ: Single);
begin
  Assert.AreEqual(Double(AX), Double(AVertex.X), TOLERANCE);
  Assert.AreEqual(Double(AY), Double(AVertex.Y), TOLERANCE);
  Assert.AreEqual(Double(AZ), Double(AVertex.Z), TOLERANCE);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, FMesh.BatchCount);
  Assert.AreEqual(0, FMesh.TriangleCount);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeFareDiUnVentaglioITriangoliDalPrimoVertice;
var
  LBatch: TI3dMeshBatch;
begin
  Fan(5);

  Assert.AreEqual(1, FMesh.BatchCount);
  Assert.AreEqual(3, FMesh.TriangleCount);
  LBatch := FMesh.Batches[0];
  Assert.AreEqual(9, Integer(Length(LBatch.Vertices)));
  AssertVertex(LBatch.Vertices[0], 0, 0, 0);
  AssertVertex(LBatch.Vertices[1], 1, 10, 0);
  AssertVertex(LBatch.Vertices[2], 2, 20, 0);
  AssertVertex(LBatch.Vertices[6], 0, 0, 0);
  AssertVertex(LBatch.Vertices[7], 3, 30, 0);
  AssertVertex(LBatch.Vertices[8], 4, 40, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeFareDueTriangoliDiUnQuadrilatero;
var
  LBatch: TI3dMeshBatch;
  LIndex: Integer;
begin
  FMesh.BeginPrimitive(I3D_MESH_QUADS);
  for LIndex := 0 to 8 do
    FMesh.Vertex3f(LIndex, 0, 0);
  FMesh.EndPrimitive;

  // nine vertexes: two quadrilaterals and one vertex too many
  Assert.AreEqual(4, FMesh.TriangleCount);
  LBatch := FMesh.Batches[0];
  AssertVertex(LBatch.Vertices[3], 0, 0, 0);
  AssertVertex(LBatch.Vertices[4], 2, 0, 0);
  AssertVertex(LBatch.Vertices[5], 3, 0, 0);
  AssertVertex(LBatch.Vertices[6], 4, 0, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeGirareITriangoliDispariDiUnaStriscia;
var
  LBatch: TI3dMeshBatch;
  LIndex: Integer;
begin
  FMesh.BeginPrimitive(I3D_MESH_TRIANGLE_STRIP);
  for LIndex := 0 to 3 do
    FMesh.Vertex3f(LIndex, 0, 0);
  FMesh.EndPrimitive;

  Assert.AreEqual(2, FMesh.TriangleCount);
  LBatch := FMesh.Batches[0];
  AssertVertex(LBatch.Vertices[3], 2, 0, 0);
  AssertVertex(LBatch.Vertices[4], 1, 0, 0);
  AssertVertex(LBatch.Vertices[5], 3, 0, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbePrendereITriangoliATreATre;
var
  LIndex: Integer;
begin
  FMesh.BeginPrimitive(I3D_MESH_TRIANGLES);
  for LIndex := 0 to 7 do
    FMesh.Vertex3f(LIndex, 0, 0);
  FMesh.EndPrimitive;

  Assert.AreEqual(2, FMesh.TriangleCount);
  AssertVertex(FMesh.Batches[0].Vertices[3], 3, 0, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeScartareLineeEPrimitiveConMenoDiTreVertici;
begin
  // 1 is GL_LINES
  FMesh.BeginPrimitive(1);
  FMesh.Vertex3f(0, 0, 0);
  FMesh.Vertex3f(1, 0, 0);
  FMesh.Vertex3f(2, 0, 0);
  FMesh.Vertex3f(3, 0, 0);
  FMesh.EndPrimitive;
  Fan(2);

  Assert.AreEqual(0, FMesh.BatchCount);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeIgnorareIVerticiFuoriDaUnaPrimitiva;
begin
  FMesh.Vertex3f(1, 2, 3);
  FMesh.Vertex3f(4, 5, 6);
  FMesh.Vertex3f(7, 8, 9);
  FMesh.EndPrimitive;

  Assert.AreEqual(0, FMesh.TriangleCount);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeTenereIlPuntoDellaTexturaDiOgniVertice;
var
  LBatch: TI3dMeshBatch;
begin
  FMesh.BeginPrimitive(I3D_MESH_TRIANGLE_FAN);
  FMesh.TexCoord2f(0.25, 0.5);
  FMesh.Vertex3f(0, 0, 0);
  FMesh.TexCoord2f(1.0, 0.0);
  FMesh.Vertex3f(1, 0, 0);
  FMesh.Vertex3f(1, 1, 0);
  FMesh.EndPrimitive;

  LBatch := FMesh.Batches[0];
  Assert.AreEqual(0.25, Double(LBatch.Vertices[0].U), TOLERANCE);
  Assert.AreEqual(0.5, Double(LBatch.Vertices[0].V), TOLERANCE);
  Assert.AreEqual(1.0, Double(LBatch.Vertices[1].U), TOLERANCE);
  // the point of the texture stays until it is changed
  Assert.AreEqual(1.0, Double(LBatch.Vertices[2].U), TOLERANCE);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeSepararePerTexturaEPerColore;
begin
  FMesh.SetTexturing(True);
  FMesh.BindTexture(2);
  Fan(3);
  FMesh.BindTexture(5);
  Fan(3);
  FMesh.SetTexturing(False);
  FMesh.Color4f(0.5, 0.25, 0.125, 0.5);
  Fan(3);
  FMesh.Color3f(0.5, 0.25, 0.125);
  Fan(3);

  Assert.AreEqual(4, FMesh.BatchCount);
  Assert.IsTrue(FMesh.Batches[0].Textured);
  Assert.AreEqual(2, FMesh.Batches[0].TextureIndex);
  Assert.AreEqual(5, FMesh.Batches[1].TextureIndex);
  Assert.IsFalse(FMesh.Batches[2].Textured);
  Assert.AreEqual(0.25, Double(FMesh.Batches[2].Green), TOLERANCE);
  Assert.AreEqual(0.5, Double(FMesh.Batches[2].Alpha), TOLERANCE);
  Assert.AreEqual(1.0, Double(FMesh.Batches[3].Alpha), TOLERANCE);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeRiunireLeFacceConLoStessoStato;
begin
  FMesh.SetTexturing(True);
  FMesh.BindTexture(1);
  Fan(3);
  FMesh.BindTexture(2);
  Fan(3);
  FMesh.BindTexture(1);
  Fan(4);

  Assert.AreEqual(2, FMesh.BatchCount);
  Assert.AreEqual(9, Integer(Length(FMesh.Batches[0].Vertices)));
  Assert.AreEqual(3, Integer(Length(FMesh.Batches[1].Vertices)));
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeNonDareTexturaSenzaTexturing;
begin
  FMesh.BindTexture(7);
  Fan(3);

  Assert.IsFalse(FMesh.Batches[0].Textured);
  Assert.AreEqual(-1, FMesh.Batches[0].TextureIndex);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeTraslareIVertici;
begin
  FMesh.Translatef(10, 20, 30);
  Fan(3);

  AssertVertex(FMesh.Batches[0].Vertices[0], 10, 20, 30);
  AssertVertex(FMesh.Batches[0].Vertices[1], 11, 30, 30);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeScalarePrimaDiTraslareComeOpenGl;
begin
  // glTranslatef and then glScalef: the vertex is scaled first
  FMesh.Translatef(100, 0, 0);
  FMesh.Scalef(2, 3, 4);
  Fan(3);

  AssertVertex(FMesh.Batches[0].Vertices[1], 102, 30, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeRuotareDiNovantaGradiAttornoAZ;
begin
  FMesh.Rotatef(90, 0, 0, 2);
  FMesh.BeginPrimitive(I3D_MESH_TRIANGLES);
  FMesh.Vertex3f(1, 0, 5);
  FMesh.Vertex3f(0, 1, 5);
  FMesh.Vertex3f(0, 0, 5);
  FMesh.EndPrimitive;

  AssertVertex(FMesh.Batches[0].Vertices[0], 0, 1, 5);
  AssertVertex(FMesh.Batches[0].Vertices[1], -1, 0, 5);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeNonRuotareAttornoAUnAsseNullo;
begin
  FMesh.Rotatef(45, 0, 0, 0);
  Fan(3);

  AssertVertex(FMesh.Batches[0].Vertices[1], 1, 10, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeRipristinareLaMatriceConPop;
begin
  FMesh.Translatef(1, 0, 0);
  FMesh.PushMatrix;
  FMesh.Translatef(0, 50, 0);
  FMesh.LoadIdentity;
  FMesh.Scalef(9, 9, 9);
  FMesh.PopMatrix;
  Fan(3);

  AssertVertex(FMesh.Batches[0].Vertices[0], 1, 0, 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeDareEccezioneSeLoStackEVuoto;
begin
  Assert.WillRaise(
    procedure
    begin
      FMesh.PopMatrix;
    end, EModelsException);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeDareEccezionePerUnLottoCheNonEsiste;
begin
  Fan(3);

  Assert.WillRaise(
    procedure
    begin
      FMesh.Batches[1];
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      FMesh.Batches[-1];
    end, EModelsException);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeDimenticareTuttoConClear;
begin
  FMesh.SetTexturing(True);
  FMesh.BindTexture(3);
  FMesh.Color4f(0, 0, 0, 0);
  FMesh.Translatef(5, 5, 5);
  FMesh.PushMatrix;
  Fan(3);

  FMesh.Clear;
  Fan(3);

  Assert.AreEqual(1, FMesh.BatchCount);
  Assert.IsFalse(FMesh.Batches[0].Textured);
  Assert.AreEqual(1.0, Double(FMesh.Batches[0].Red), TOLERANCE);
  AssertVertex(FMesh.Batches[0].Vertices[0], 0, 0, 0);
  Assert.WillRaise(
    procedure
    begin
      FMesh.PopMatrix;
    end, EModelsException);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeDareITriangoliDiUnModelloDisegnatoDalRenderer;
var
  LModel: II3dModel;
  LPlacement: TModelPlacement;
  LTires: TI3dTireState;
  LDrawn: Integer;
begin
  LModel := TI3dFactory.CreateParser.Parse(TI3dFileBuilder.SmallModel);
  LPlacement := Default(TModelPlacement);
  LPlacement.ScaleX := 1.0;
  LPlacement.ScaleY := 1.0;
  LPlacement.ScaleZ := 1.0;
  LTires := Default(TI3dTireState);

  LDrawn := TI3dFactory.CreateRenderer.Render(LModel, FMesh, LPlacement, -1, LTires);

  // two triangles, a quadrilateral and a face with no vertexes: the renderer counts the empty
  // face as -2 (as the old code did), the mesh has only the triangles that exist
  Assert.AreEqual(2, LDrawn);
  Assert.AreEqual(4, FMesh.TriangleCount);
  Assert.AreEqual(2, FMesh.BatchCount);
  Assert.IsFalse(FMesh.Batches[0].Textured);
  Assert.IsTrue(FMesh.Batches[1].Textured);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeSpostareLeGommeDiUnAutoQuandoGirano;
var
  LModel: II3dModel;
  LPlacement: TModelPlacement;
  LTires: TI3dTireState;
  LStill: II3dMeshBuilder;
  LBatch: Integer;
  LVertex: Integer;
  LMoved: Integer;
begin
  LModel := TI3dFactory.CreateParser.Parse(TI3dFileBuilder.CarModel);
  LPlacement := Default(TModelPlacement);
  LPlacement.ScaleX := 1.0;
  LPlacement.ScaleY := 1.0;
  LPlacement.ScaleZ := 1.0;
  LTires := Default(TI3dTireState);
  LStill := TI3dFactory.CreateMeshBuilder;
  TI3dFactory.CreateRenderer.Render(LModel, LStill, LPlacement, -1, LTires);

  LTires.Rotation[0] := 90.0;
  LTires.Rotation[1] := 90.0;
  LTires.Rotation[2] := 90.0;
  LTires.Rotation[3] := 90.0;
  TI3dFactory.CreateRenderer.Render(LModel, FMesh, LPlacement, -1, LTires);

  // the same batches and triangles, with the vertexes of the tires somewhere else
  Assert.AreEqual(LStill.BatchCount, FMesh.BatchCount);
  Assert.AreEqual(LStill.TriangleCount, FMesh.TriangleCount);
  LMoved := 0;
  for LBatch := 0 to FMesh.BatchCount - 1 do
    for LVertex := 0 to High(FMesh.Batches[LBatch].Vertices) do
      if Abs(FMesh.Batches[LBatch].Vertices[LVertex].Y - LStill.Batches[LBatch].Vertices[LVertex].Y) +
         Abs(FMesh.Batches[LBatch].Vertices[LVertex].Z - LStill.Batches[LBatch].Vertices[LVertex].Z) > TOLERANCE then
        Inc(LMoved);
  Assert.IsTrue(LMoved > 0);
end;

procedure TTestModelsI3dMeshBuilder.DovrebbeAvereUnVerticeDiVentiByte;
begin
  Assert.AreEqual(20, Integer(SizeOf(TI3dMeshVertex)));
end;

end.
