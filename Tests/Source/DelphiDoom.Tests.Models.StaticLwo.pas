{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the LWO reader and converter   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticLwo;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf;

type
  [TestFixture]
  [Category('Models')]
  TTestStaticLwo = class
  strict private
    function Load(const AData: TBytes; const AOptions: TStaticLoadOptions): IStaticModel; overload;
    function Load(const AData: TBytes): IStaticModel; overload;
    procedure CheckFails(const AData: TBytes; const AFragment: string);
    /// <summary>A file with the given points and triangles and a surface that is the tag 0</summary>
    function Mesh(const APoints: array of Single; const ATriangles: array of TArray<Integer>): TBytes;
  public
    [Test]
    procedure DovrebbeFareUnaSuperficieDi24VertexPerIlCuboPiatto;
    [Test]
    procedure DovrebbeScambiareGliAssiDiLightWaveInQuelliDelMotore;
    [Test]
    procedure DovrebbeDareLeBoundsDelCuboEIlNomeDelMateriale;
    [Test]
    procedure DovrebbeDareIlColoreDellaSuperficieComeByte;
    [Test]
    procedure DovrebbeInvertereLaTDelleCoordinateDiTexture;
    [Test]
    procedure DovrebbeCalcolareLeNormaliPiatteDeiPoligoni;
    [Test]
    procedure DovrebbeUnireIVertexConLAngoloDiSmussatura;
    [Test]
    procedure DovrebbeTenereSeparateLeNormaliSeIGruppiDiSmussaturaSonoDiversi;
    [Test]
    procedure DovrebbePrendereIlColoreDallaMappaRGBA;
    [Test]
    procedure DovrebbeUnireLeSuperficiDelloStessoMaterialeSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTenereSeparateLeSuperficiSeLOpzioneNonUnisce;
    [Test]
    procedure DovrebbeCrearePerUnTagSenzaSuperficieUnaSuperficieDiDefault;
    [Test]
    procedure DovrebbeUnireIPuntiVicini;
    [Test]
    procedure DovrebbeNonUnireNullaSeFastLoad;
    [Test]
    procedure DovrebbeAvvisareSeMancanoLeCoordinateDiTexture;
    [Test]
    procedure DovrebbeSaltareIPoligoniNonTriangolatiConUnAvviso;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonELwo;
    [Test]
    procedure DovrebbeRifiutareLwobConUnMessaggio;
    [Test]
    procedure DovrebbeRifiutareUnChunkTroncatoDandoLOffset;
    [Test]
    procedure DovrebbeRifiutareUnPoligonoConUnPuntoCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnTagDiPoligonoFuoriDallaLista;
    [Test]
    procedure DovrebbeRifiutareUnOggettoSenzaSuperfici;
    [Test]
    procedure DovrebbeRifiutareUnOggettoSenzaPunti;
    [Test]
    procedure DovrebbeRifiutareIPoligoniSenzaTag;
    [Test]
    procedure DovrebbeUsareSoloLaPrimaLayer;
    [Test]
    procedure DovrebbeLeggereIndiciA4ByteEStringheVuote;
    [Test]
    procedure DovrebbeSaltareICapitoliSconosciutiEQuelliDiSuperficieNonUsati;
    [Test]
    procedure DovrebbeLeggereIlCuboDelFileDiDati;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Tests.Models.StaticBuilders;

{ TTestStaticLwo }

function TTestStaticLwo.Load(const AData: TBytes; const AOptions: TStaticLoadOptions): IStaticModel;
begin
  Result := TStaticModelFactory.CreateLwoLoader(AOptions).Load(AData, 'test.lwo');
end;

function TTestStaticLwo.Load(const AData: TBytes): IStaticModel;
begin
  Result := Load(AData, TStaticLoadOptions.Default);
end;

procedure TTestStaticLwo.CheckFails(const AData: TBytes; const AFragment: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    Load(AData);
  except
    on E: EStaticModelException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(LMessage.Contains(AFragment), 'message: "' + LMessage + '" expected: ' + AFragment);
end;

function TTestStaticLwo.Mesh(const APoints: array of Single; const ATriangles: array of TArray<Integer>): TBytes;
var
  LBuilder: TLwoFileBuilder;
  LFaces: array of TCubeTriangle;
  LTags: array of Integer;
  LIndex: Integer;
begin
  SetLength(LFaces, Length(ATriangles));
  SetLength(LTags, Length(ATriangles));
  for LIndex := 0 to High(ATriangles) do
  begin
    LFaces[LIndex][0] := ATriangles[LIndex][0];
    LFaces[LIndex][1] := ATriangles[LIndex][1];
    LFaces[LIndex][2] := ATriangles[LIndex][2];
    LTags[LIndex] := 0;
  end;
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['m']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints(APoints);
    LBuilder.AddFaces(LFaces);
    LBuilder.AddSurfaceTags(LTags);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestStaticLwo.DovrebbeFareUnaSuperficieDi24VertexPerIlCuboPiatto;
var
  LModel: IStaticModel;
begin
  LModel := Load(BuildCubeLwo(0));
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual(24, LModel.Surfaces[0].Triangles.NumVerts);
  Assert.AreEqual(36, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.IsFalse(LModel.Surfaces[0].Triangles.GenerateNormals);
  Assert.AreEqual(24, LModel.TotalVerts);
  Assert.AreEqual(36, LModel.TotalIndexes);
  Assert.AreEqual('test.lwo', LModel.Name);
end;

procedure TTestStaticLwo.DovrebbeScambiareGliAssiDiLightWaveInQuelliDelMotore;
var
  LTriangles: TStaticTriangles;
begin
  LTriangles := Load(BuildCubeLwo(0)).Surfaces[0].Triangles;
  // the first triangle is (0, 3, 2) of the file: LW (-1,-1,-1), (-1,1,-1), (1,1,-1)
  Assert.AreEqual<Integer>(0, LTriangles.Indexes[0]);
  Assert.AreEqual<Integer>(1, LTriangles.Indexes[1]);
  Assert.AreEqual<Integer>(2, LTriangles.Indexes[2]);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[0].Xyz.X);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[0].Xyz.Y);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[0].Xyz.Z);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[1].Xyz.X);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[1].Xyz.Y);
  Assert.AreEqual<Single>(1, LTriangles.Verts[1].Xyz.Z);
  Assert.AreEqual<Single>(1, LTriangles.Verts[2].Xyz.X);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[2].Xyz.Y);
  Assert.AreEqual<Single>(1, LTriangles.Verts[2].Xyz.Z);
end;

procedure TTestStaticLwo.DovrebbeDareLeBoundsDelCuboEIlNomeDelMateriale;
var
  LModel: IStaticModel;
begin
  LModel := Load(BuildCubeLwo(0));
  Assert.AreEqual('textures/test/cube', string(LModel.Surfaces[0].MaterialName));
  Assert.AreEqual<Integer>(0, LModel.Surfaces[0].Id);
  Assert.AreEqual<Single>(-1, LModel.Bounds.Mins.X);
  Assert.AreEqual<Single>(-1, LModel.Bounds.Mins.Y);
  Assert.AreEqual<Single>(-1, LModel.Bounds.Mins.Z);
  Assert.AreEqual<Single>(1, LModel.Bounds.Maxs.X);
  Assert.AreEqual<Single>(1, LModel.Bounds.Maxs.Y);
  Assert.AreEqual<Single>(1, LModel.Bounds.Maxs.Z);
end;

procedure TTestStaticLwo.DovrebbeDareIlColoreDellaSuperficieComeByte;
var
  LColor: TStaticColor;
begin
  LColor := Load(BuildCubeLwo(0)).Surfaces[0].Triangles.Verts[0].Color;
  // 0.5 * 255 = 127.5, 0.25 * 255 = 63.75: truncated like the C++ conversion
  Assert.AreEqual<Integer>(127, LColor.R);
  Assert.AreEqual<Integer>(63, LColor.G);
  Assert.AreEqual<Integer>(255, LColor.B);
  Assert.AreEqual<Integer>(255, LColor.A);
end;

procedure TTestStaticLwo.DovrebbeInvertereLaTDelleCoordinateDiTexture;
var
  LTriangles: TStaticTriangles;
begin
  LTriangles := Load(BuildCubeLwo(0)).Surfaces[0].Triangles;
  // vertex 1 is the point 3 of the file, its uv is (0, 1)
  Assert.AreEqual<Single>(0, LTriangles.Verts[1].St.X);
  Assert.AreEqual<Single>(0, LTriangles.Verts[1].St.Y);
  // vertex 2 is the point 2, its uv is (1, 1)
  Assert.AreEqual<Single>(1, LTriangles.Verts[2].St.X);
  Assert.AreEqual<Single>(0, LTriangles.Verts[2].St.Y);
  // vertex 0 is the point 0, its uv is (0, 0)
  Assert.AreEqual<Single>(1, LTriangles.Verts[0].St.Y);
end;

procedure TTestStaticLwo.DovrebbeCalcolareLeNormaliPiatteDeiPoligoni;
var
  LTriangles: TStaticTriangles;
  LIndex: Integer;
  LLength: Single;
begin
  LTriangles := Load(BuildCubeLwo(0)).Surfaces[0].Triangles;
  // the polygon (0, 3, 2) faces -z in LightWave, that is -y in the engine
  Assert.AreEqual<Single>(0, LTriangles.Verts[0].Normal.X);
  Assert.AreEqual<Single>(-1, LTriangles.Verts[0].Normal.Y);
  Assert.AreEqual<Single>(0, LTriangles.Verts[0].Normal.Z);
  for LIndex := 0 to LTriangles.NumVerts - 1 do
  begin
    LLength := Abs(LTriangles.Verts[LIndex].Normal.X) + Abs(LTriangles.Verts[LIndex].Normal.Y) +
      Abs(LTriangles.Verts[LIndex].Normal.Z);
    Assert.AreEqual<Single>(1, LLength, 'a flat normal is on an axis');
  end;
end;

procedure TTestStaticLwo.DovrebbeUnireIVertexConLAngoloDiSmussatura;
var
  LTriangles: TStaticTriangles;
  LIndex: Integer;
begin
  // 1.6 radians (91.7 degrees) are more than the 90 degrees between the faces of the cube
  LTriangles := Load(BuildCubeLwo(1.6)).Surfaces[0].Triangles;
  Assert.AreEqual(8, LTriangles.NumVerts);
  Assert.AreEqual(36, LTriangles.NumIndexes);
  for LIndex := 0 to LTriangles.NumVerts - 1 do
  begin
    // a corner has three faces; the diagonals give it four to six triangles: the normal is not
    // (1, 1, 1) / sqrt(3) everywhere but it is a unit vector that leans on the three faces
    Assert.AreEqual(1.0, Sqrt(Sqr(LTriangles.Verts[LIndex].Normal.X) + Sqr(LTriangles.Verts[LIndex].Normal.Y) +
      Sqr(LTriangles.Verts[LIndex].Normal.Z)), 1e-5);
    Assert.IsTrue((Abs(LTriangles.Verts[LIndex].Normal.X) > 0.3) and (Abs(LTriangles.Verts[LIndex].Normal.Y) > 0.3) and
      (Abs(LTriangles.Verts[LIndex].Normal.Z) > 0.3));
  end;
end;

procedure TTestStaticLwo.DovrebbeTenereSeparateLeNormaliSeIGruppiDiSmussaturaSonoDiversi;
var
  LBuilder: TLwoFileBuilder;
  LTags, LGroups: array[0..11] of Integer;
  LIndex: Integer;
  LModel: IStaticModel;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['m']);
    LBuilder.AddLayer(0, 'cube');
    LBuilder.AddPoints(CUBE_POINTS);
    LBuilder.AddTexCoords('uv', CUBE_TEXCOORDS);
    LBuilder.AddFaces(CUBE_TRIANGLES);
    for LIndex := 0 to 11 do
    begin
      LTags[LIndex] := 0;
      LGroups[LIndex] := LIndex;
    end;
    LBuilder.AddSurfaceTags(LTags);
    LBuilder.AddSmoothingGroups(LGroups);
    LBuilder.AddSurface('m', 1, 1, 1, 1.6);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(24, LModel.Surfaces[0].Triangles.NumVerts, 'every polygon in its own group: flat normals');
end;

procedure TTestStaticLwo.DovrebbePrendereIlColoreDallaMappaRGBA;
var
  LTriangles: TStaticTriangles;
  LIndex: Integer;
  LFound: Boolean;
begin
  LTriangles := Load(BuildCubeLwo(1.6, True)).Surfaces[0].Triangles;
  // the point 0 is red; the point 7 has alpha 0.5
  LFound := False;
  for LIndex := 0 to LTriangles.NumVerts - 1 do
    if (LTriangles.Verts[LIndex].Xyz.X = -1) and (LTriangles.Verts[LIndex].Xyz.Y = -1) and
      (LTriangles.Verts[LIndex].Xyz.Z = -1) then
    begin
      Assert.AreEqual<Integer>(255, LTriangles.Verts[LIndex].Color.R);
      Assert.AreEqual<Integer>(0, LTriangles.Verts[LIndex].Color.G);
      Assert.AreEqual<Integer>(255, LTriangles.Verts[LIndex].Color.A);
      LFound := True;
    end;
  Assert.IsTrue(LFound);
  for LIndex := 0 to LTriangles.NumVerts - 1 do
    if (LTriangles.Verts[LIndex].Xyz.X = -1) and (LTriangles.Verts[LIndex].Xyz.Y = 1) and
      (LTriangles.Verts[LIndex].Xyz.Z = 1) then
      Assert.AreEqual<Integer>(127, LTriangles.Verts[LIndex].Color.A, 'point 7 of LW is (-1, 1, 1)');
end;

procedure TTestStaticLwo.DovrebbeUnireLeSuperficiDelloStessoMaterialeSenzaDistinguereLeMaiuscole;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['tex/a', 'TEX/A']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0,  1, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2), Tri(1, 3, 2)]);
    LBuilder.AddSurfaceTags([0, 1]);
    LBuilder.AddSurface('tex/a', 1, 1, 1, 0);
    LBuilder.AddSurface('TEX/A', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual(6, LModel.Surfaces[0].Triangles.NumIndexes, 'both triangles are in the merged surface');
  Assert.AreEqual<Integer>(3, LModel.Surfaces[0].Triangles.Indexes[3], 'the indexes of the second move by the vertexes of the first');
end;

procedure TTestStaticLwo.DovrebbeTenereSeparateLeSuperficiSeLOpzioneNonUnisce;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
  LOptions: TStaticLoadOptions;
begin
  LOptions := TStaticLoadOptions.Default;
  LOptions.MergeSurfaces := False;
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['tex/a', 'TEX/A']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0,  1, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2), Tri(1, 3, 2)]);
    LBuilder.AddSurfaceTags([0, 1]);
    LBuilder.AddSurface('tex/a', 1, 1, 1, 0);
    LBuilder.AddSurface('TEX/A', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build, LOptions);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, LModel.NumSurfaces);
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.AreEqual(3, LModel.Surfaces[1].Triangles.NumIndexes);
end;

procedure TTestStaticLwo.DovrebbeCrearePerUnTagSenzaSuperficieUnaSuperficieDiDefault;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['textures/named', 'textures/nosurf']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0,  1, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2), Tri(1, 3, 2)]);
    LBuilder.AddSurfaceTags([0, 1]);
    LBuilder.AddSurface('textures/named', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, LModel.NumSurfaces);
  Assert.AreEqual('textures/named', string(LModel.Surfaces[0].MaterialName));
  Assert.AreEqual('textures/nosurf', string(LModel.Surfaces[1].MaterialName));
  // the default surface has the colour 0.78431
  Assert.AreEqual<Integer>(199, LModel.Surfaces[1].Triangles.Verts[0].Color.R);
end;

procedure TTestStaticLwo.DovrebbeUnireIPuntiVicini;
var
  LModel: IStaticModel;
begin
  // the point 3 is 0.005 from the point 1 (slop 0.01): the same vertex
  LModel := Load(Mesh([0, 0, 0,  1, 0, 0,  0, 1, 0,  1.005, 0, 0],
    [TArray<Integer>.Create(0, 1, 2), TArray<Integer>.Create(1, 3, 2)]));
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumVerts);
  Assert.AreEqual<Integer>(1, LModel.Surfaces[0].Triangles.Indexes[4]);
end;

procedure TTestStaticLwo.DovrebbeNonUnireNullaSeFastLoad;
var
  LOptions: TStaticLoadOptions;
  LModel: IStaticModel;
begin
  LOptions := TStaticLoadOptions.Default;
  LOptions.FastLoad := True;
  LModel := Load(Mesh([0, 0, 0,  1, 0, 0,  0, 1, 0,  1.005, 0, 0],
    [TArray<Integer>.Create(0, 1, 2), TArray<Integer>.Create(1, 3, 2)]), LOptions);
  // with normalEpsilon = 1 the test dot > 1 never holds for equal unit normals: nothing is
  // welded (a defect of the C++, kept), the three vertexes of each of the two triangles stay
  Assert.AreEqual(6, LModel.Surfaces[0].Triangles.NumVerts);
end;

procedure TTestStaticLwo.DovrebbeAvvisareSeMancanoLeCoordinateDiTexture;
var
  LModel: IStaticModel;
begin
  LModel := Load(Mesh([0, 0, 0,  1, 0, 0,  0, 1, 0], [TArray<Integer>.Create(0, 1, 2)]));
  Assert.AreEqual(1, Length(LModel.Warnings));
  Assert.IsTrue(LModel.Warnings[0].Contains('uv'));
  Assert.AreEqual<Single>(0, LModel.Surfaces[0].Triangles.Verts[0].St.X);
  Assert.AreEqual<Single>(0, LModel.Surfaces[0].Triangles.Verts[0].St.Y);
end;

procedure TTestStaticLwo.DovrebbeSaltareIPoligoniNonTriangolatiConUnAvviso;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
  LData: TBytes;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['m']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0,  1, 1, 0]);
    // a quad (4 vertexes) and a triangle
    LData := TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('FACE'))), TLwoFileBuilder.U2(4),
      TLwoFileBuilder.VX(0), TLwoFileBuilder.VX(1), TLwoFileBuilder.VX(3), TLwoFileBuilder.VX(2),
      TLwoFileBuilder.U2(3), TLwoFileBuilder.VX(0), TLwoFileBuilder.VX(1), TLwoFileBuilder.VX(2)]);
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('POLS', LData));
    LBuilder.AddSurfaceTags([0, 0]);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.AreEqual(2, Length(LModel.Warnings), 'the quad and the missing uv');
  Assert.IsTrue(LModel.Warnings[0].Contains('uv') or LModel.Warnings[1].Contains('4 vertexes'));
end;

procedure TTestStaticLwo.DovrebbeRifiutareUnFileCheNonELwo;
begin
  CheckFails(TBytes.Create(1, 2, 3), 'not a LightWave object');
  CheckFails(TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('FORM'))), TLwoFileBuilder.U4(4),
    TBytes(BytesOf(AnsiString('XXXX')))]), 'not a LightWave object');
  CheckFails(TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('LIST'))), TLwoFileBuilder.U4(4),
    TBytes(BytesOf(AnsiString('LWO2')))]), 'not a LightWave object');
end;

procedure TTestStaticLwo.DovrebbeRifiutareLwobConUnMessaggio;
begin
  CheckFails(TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('FORM'))), TLwoFileBuilder.U4(4),
    TBytes(BytesOf(AnsiString('LWOB')))]), 'LWOB');
end;

procedure TTestStaticLwo.DovrebbeRifiutareUnChunkTroncatoDandoLOffset;
var
  LData: TBytes;
  LOffset: Integer;
begin
  LData := BuildCubeLwo(0);
  SetLength(LData, 100);
  LOffset := -1;
  try
    Load(LData);
  except
    on E: EStaticModelException do
      LOffset := E.Offset;
  end;
  Assert.IsTrue(LOffset > 0, 'the offset of the truncated read');
end;

procedure TTestStaticLwo.DovrebbeRifiutareUnPoligonoConUnPuntoCheNonEsiste;
begin
  CheckFails(Mesh([0, 0, 0,  1, 0, 0,  0, 1, 0], [TArray<Integer>.Create(0, 1, 7)]), 'the point 7 does not exist');
end;

procedure TTestStaticLwo.DovrebbeRifiutareUnTagDiPoligonoFuoriDallaLista;
var
  LBuilder: TLwoFileBuilder;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['m']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2)]);
    LBuilder.AddSurfaceTags([5]);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    CheckFails(LBuilder.Build, 'the surface tag 5 does not exist');
  finally
    LBuilder.Free;
  end;
end;

procedure TTestStaticLwo.DovrebbeRifiutareUnOggettoSenzaSuperfici;
var
  LBuilder: TLwoFileBuilder;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddLayer(0, 'l');
    CheckFails(LBuilder.Build, 'no surfaces');
  finally
    LBuilder.Free;
  end;
end;

procedure TTestStaticLwo.DovrebbeRifiutareUnOggettoSenzaPunti;
var
  LBuilder: TLwoFileBuilder;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    CheckFails(LBuilder.Build, 'bad or missing vertex data');
  finally
    LBuilder.Free;
  end;
end;

procedure TTestStaticLwo.DovrebbeRifiutareIPoligoniSenzaTag;
var
  LBuilder: TLwoFileBuilder;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2)]);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    CheckFails(LBuilder.Build, 'no TAGS chunk');
  finally
    LBuilder.Free;
  end;
end;

procedure TTestStaticLwo.DovrebbeUsareSoloLaPrimaLayer;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['m']);
    LBuilder.AddLayer(0, 'first');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2)]);
    LBuilder.AddSurfaceTags([0]);
    LBuilder.AddLayer(1, 'second');
    LBuilder.AddPoints([0, 0, 0,  5, 0, 0,  0, 5, 0,  5, 5, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2), Tri(1, 3, 2)]);
    LBuilder.AddSurfaceTags([0, 0]);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.AreEqual<Single>(1, LModel.Bounds.Maxs.X);
end;

procedure TTestStaticLwo.DovrebbeLeggereIndiciA4ByteEStringheVuote;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
  LPoints: array of Single;
  LCount, LIndex: Integer;
  LData: TBytes;
begin
  // 70000 points: the indexes over $FEFF use the form of four bytes of the format
  LCount := 70000;
  SetLength(LPoints, LCount * 3);
  for LIndex := 0 to LCount - 1 do
  begin
    LPoints[LIndex * 3] := LIndex;
    LPoints[LIndex * 3 + 1] := 0;
    LPoints[LIndex * 3 + 2] := LIndex mod 7;
  end;
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['m']);
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('LAYR', TLwoFileBuilder.Join([TLwoFileBuilder.U2(0),
      TLwoFileBuilder.U2(0), TLwoFileBuilder.F4(0), TLwoFileBuilder.F4(0), TLwoFileBuilder.F4(0),
      TLwoFileBuilder.S0('')])));
    LBuilder.AddPoints(LPoints);
    LData := TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('FACE'))), TLwoFileBuilder.U2(3),
      TLwoFileBuilder.VX(0), TLwoFileBuilder.VX(1), TLwoFileBuilder.VX(69999)]);
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('POLS', LData));
    LBuilder.AddSurfaceTags([0]);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual<Single>(69999, LModel.Surfaces[0].Triangles.Verts[2].Xyz.X);
end;

procedure TTestStaticLwo.DovrebbeSaltareICapitoliSconosciutiEQuelliDiSuperficieNonUsati;
var
  LBuilder: TLwoFileBuilder;
  LModel: IStaticModel;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('ICON', TBytes.Create(1, 2, 3)));
    LBuilder.AddTags(['m']);
    LBuilder.AddLayer(0, 'l');
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('BBOX', TLwoFileBuilder.Join([TLwoFileBuilder.F4(0), TLwoFileBuilder.F4(0),
      TLwoFileBuilder.F4(0), TLwoFileBuilder.F4(1), TLwoFileBuilder.F4(1), TLwoFileBuilder.F4(1)])));
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0]);
    LBuilder.AddFaces([Tri(0, 1, 2)]);
    // a PTAG of the parts is read and ignored; one of unknown type is skipped
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('PTAG', TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('PART'))),
      TLwoFileBuilder.VX(0), TLwoFileBuilder.VX(0)])));
    LBuilder.AddRaw(TLwoFileBuilder.Chunk('PTAG', TLwoFileBuilder.Join([TBytes(BytesOf(AnsiString('XXXX'))),
      TLwoFileBuilder.VX(0), TLwoFileBuilder.VX(0)])));
    LBuilder.AddSurfaceTags([0]);
    LBuilder.AddSurface('m', 1, 1, 1, 0);
    LModel := Load(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
end;

procedure TTestStaticLwo.DovrebbeLeggereIlCuboDelFileDiDati;
var
  LData: TBytes;
  LModel: IStaticModel;
begin
  LData := StaticDataFile('cube.lwo');
  LModel := Load(LData);
  Assert.AreEqual(24, LModel.TotalVerts);
  Assert.IsTrue(TArrayEquals(LData, BuildCubeLwo(0)), 'the data file is the one of the builder');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStaticLwo);

end.
