{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the shared parts of the static }
{  models (surface, vertex welding, byte reader, numbers, factory)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticSupport;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Models')]
  TTestStaticSupport = class
  public
    [Test]
    procedure DovrebbeAvereIlVertexLaDimensioneDiIdDrawVert;
    [Test]
    procedure DovrebbeConvertireIlColoreInUnDword;
    [Test]
    procedure DovrebbeDareIValoriDiDefaultDelleOpzioni;
    [TestCase('intero', '42,42')]
    [TestCase('spazi e segno', '  -17abc,-17')]
    [TestCase('niente', 'abc,0')]
    [TestCase('saturato', '99999999999999,2147483647')]
    procedure DovrebbeLeggereUnInteroComeAtoi(const AText: string; const AExpected: Integer);
    [Test]
    procedure DovrebbeLeggereUnRealeComeAtof;
    [Test]
    procedure DovrebbeLeggereIlBigEndianEIlVX;
    [Test]
    procedure DovrebbeAzzerareUnFloatDenormale;
    [Test]
    procedure DovrebbeLeggereUnaStringaPadding;
    [Test]
    procedure DovrebbeFallireLeggendoOltreLaFineConLOffset;
    [Test]
    procedure DovrebbeFallireSuUnaStringaSenzaTerminatore;
    [Test]
    procedure DovrebbeUnireDueGeometrieSpostandoGliIndici;
    [Test]
    procedure DovrebbeDareLeBoundsDiUnaGeometriaVuotaPulite;
    [Test]
    procedure DovrebbeNumerareESommareLeSuperficiDelModello;
    [Test]
    procedure DovrebbeRifiutareUnaSuperficieChePassaLIntervallo;
    [Test]
    procedure DovrebbeTrovareIlVectorGiaVistoDelSottoinsieme;
    [Test]
    procedure DovrebbeNonUnireVectorPiuLontaniDellEpsilon;
    [Test]
    procedure DovrebbeUnireTexCoordInDueDimensioni;
    [Test]
    procedure DovrebbeUnireVertexConLaStessaCombinazione;
    [Test]
    procedure DovrebbeDistinguereLeNormaliSoloSeCeNeSono;
    [Test]
    procedure DovrebbeUnireSuperficiPerMaterialeNellOrdineDiCreazione;
    [Test]
    procedure DovrebbeSceglierILoaderDallEstensione;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Numbers,
  DelphiDoom.Models.Static.ByteReader,
  DelphiDoom.Models.Static.VectorSubset,
  DelphiDoom.Models.Static.VertexWelder,
  DelphiDoom.Models.Static.SurfacePlanner,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Tests.Models.StaticBuilders;

function V3(const AX, AY, AZ: Single): TIdVec3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function V2(const AX, AY: Single): TIdVec2;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Triangles(const AVertexCount: Integer; const AIndexes: array of Integer): TStaticTriangles;
var
  LIndex: Integer;
begin
  Result.Verts := nil;
  SetLength(Result.Verts, AVertexCount);
  for LIndex := 0 to AVertexCount - 1 do
  begin
    Result.Verts[LIndex].Clear;
    Result.Verts[LIndex].Xyz := V3(LIndex, LIndex * 2, -LIndex);
  end;
  SetLength(Result.Indexes, Length(AIndexes));
  for LIndex := 0 to High(AIndexes) do
    Result.Indexes[LIndex] := AIndexes[LIndex];
  Result.GenerateNormals := True;
end;

{ TTestStaticSupport }

procedure TTestStaticSupport.DovrebbeAvereIlVertexLaDimensioneDiIdDrawVert;
begin
  Assert.AreEqual(60, SizeOf(TStaticDrawVert));
  Assert.AreEqual(4, SizeOf(TStaticColor));
end;

procedure TTestStaticSupport.DovrebbeConvertireIlColoreInUnDword;
var
  LColor: TStaticColor;
begin
  LColor := TStaticColor.Make(1, 2, 3, 4);
  Assert.AreEqual<Cardinal>($04030201, LColor.ToCardinal);
  LColor := TStaticColor.FromCardinal($FF8040C0);
  Assert.AreEqual<Integer>($C0, LColor.R);
  Assert.AreEqual<Integer>($FF, LColor.A);
end;

procedure TTestStaticSupport.DovrebbeDareIValoriDiDefaultDelleOpzioni;
var
  LOptions: TStaticLoadOptions;
begin
  LOptions := TStaticLoadOptions.Default;
  Assert.IsTrue(LOptions.MergeSurfaces);
  Assert.IsFalse(LOptions.FastLoad);
  Assert.AreEqual<Single>(0.01, LOptions.SlopVertex);
  Assert.AreEqual<Single>(0.001, LOptions.SlopTexCoord);
  Assert.AreEqual<Single>(0.02, LOptions.SlopNormal);
end;

procedure TTestStaticSupport.DovrebbeLeggereUnInteroComeAtoi(const AText: string; const AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TStaticNumbers.Atoi(AnsiString(AText)));
end;

procedure TTestStaticSupport.DovrebbeLeggereUnRealeComeAtof;
begin
  Assert.AreEqual(1.5, TStaticNumbers.Atof('1.5'), 1e-12);
  Assert.AreEqual(-0.25, TStaticNumbers.Atof(' -0.25xyz'), 1e-12);
  Assert.AreEqual(100, TStaticNumbers.Atof('1e2'), 1e-12);
  Assert.AreEqual(1, TStaticNumbers.Atof('1e'), 1e-12, 'an exponent without digits is not read');
  Assert.AreEqual(0.5, TStaticNumbers.Atof('.5'), 1e-12);
  Assert.AreEqual(5, TStaticNumbers.Atof('5.'), 1e-12);
  Assert.AreEqual(0, TStaticNumbers.Atof('-'), 1e-12);
  Assert.AreEqual(0, TStaticNumbers.Atof('*MESH_VERTCOL'), 1e-12);
  Assert.AreEqual(-1250, TStaticNumbers.Atof('-1.25E+3'), 1e-9);
end;

procedure TTestStaticSupport.DovrebbeLeggereIlBigEndianEIlVX;
var
  LReader: TStaticByteReader;
  LSize: Integer;
begin
  LReader := TStaticByteReader.Create(TLwoFileBuilder.Join([TBytes.Create($12, $34), TLwoFileBuilder.U4($89ABCDEF),
    TLwoFileBuilder.F4(1.5), TLwoFileBuilder.VX(300), TLwoFileBuilder.VX($10000), TBytes.Create(7)]));
  try
    Assert.AreEqual<Integer>($1234, LReader.ReadU2);
    Assert.AreEqual<Cardinal>($89ABCDEF, LReader.ReadU4);
    Assert.AreEqual<Single>(1.5, LReader.ReadF4);
    Assert.AreEqual(300, LReader.ReadVX(LSize));
    Assert.AreEqual(2, LSize);
    Assert.AreEqual($10000, LReader.ReadVX(LSize));
    Assert.AreEqual(4, LSize);
    Assert.AreEqual<Integer>(7, LReader.ReadU1);
    Assert.AreEqual(0, LReader.Remaining);
    Assert.AreEqual(LReader.Size, LReader.Position);
  finally
    LReader.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeAzzerareUnFloatDenormale;
var
  LReader: TStaticByteReader;
begin
  LReader := TStaticByteReader.Create(TLwoFileBuilder.U4($00000001));
  try
    Assert.AreEqual<Single>(0, LReader.ReadF4);
  finally
    LReader.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeLeggereUnaStringaPadding;
var
  LReader: TStaticByteReader;
  LSize: Integer;
begin
  LReader := TStaticByteReader.Create(TLwoFileBuilder.Join([TLwoFileBuilder.S0('ab'), TLwoFileBuilder.S0('abc'),
    TLwoFileBuilder.S0(''), TLwoFileBuilder.S0('z')]));
  try
    Assert.AreEqual('ab', string(LReader.ReadS0(LSize)));
    Assert.AreEqual(4, LSize, '"ab" and its zero are 3 bytes: padded to 4');
    Assert.AreEqual('abc', string(LReader.ReadS0(LSize)));
    Assert.AreEqual(4, LSize);
    Assert.AreEqual('', string(LReader.ReadS0(LSize)));
    Assert.AreEqual(2, LSize);
    Assert.AreEqual('z', string(LReader.ReadS0(LSize)));
    Assert.AreEqual(2, LSize);
  finally
    LReader.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeFallireLeggendoOltreLaFineConLOffset;
var
  LReader: TStaticByteReader;
  LOffset: Integer;
begin
  LReader := TStaticByteReader.Create(TBytes.Create(1, 2, 3));
  try
    LReader.ReadU2;
    LOffset := -1;
    try
      LReader.ReadU4;
    except
      on E: EStaticModelException do
        LOffset := E.Offset;
    end;
    Assert.AreEqual(2, LOffset);
    Assert.WillRaise(
    procedure
    begin
      LReader.Skip(-1);
    end,
    EStaticModelException);
    Assert.WillRaise(
    procedure
    begin
      LReader.ReadBytes(9);
    end,
    EStaticModelException);
  finally
    LReader.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeFallireSuUnaStringaSenzaTerminatore;
var
  LReader: TStaticByteReader;
begin
  LReader := TStaticByteReader.Create(TBytes.Create(65, 66, 67));
  try
    Assert.WillRaise(
    procedure
    var LSize: Integer;
    begin
      LReader.ReadS0(LSize);
    end,
    EStaticModelException);
  finally
    LReader.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeUnireDueGeometrieSpostandoGliIndici;
var
  LMerged: TStaticTriangles;
begin
  LMerged := TStaticTriangles.Merge(Triangles(3, [0, 1, 2]), Triangles(4, [3, 2, 1, 0, 1, 3]));
  Assert.AreEqual(7, LMerged.NumVerts);
  Assert.AreEqual(9, LMerged.NumIndexes);
  Assert.AreEqual<Integer>(2, LMerged.Indexes[2]);
  Assert.AreEqual<Integer>(6, LMerged.Indexes[3]);
  Assert.AreEqual<Integer>(6, LMerged.Indexes[8]);
  Assert.AreEqual<Single>(0, LMerged.Verts[3].Xyz.X);
  Assert.AreEqual<Single>(3, LMerged.Verts[6].Xyz.X);
  Assert.IsFalse(LMerged.GenerateNormals, 'R_MergeSurfaceList does not copy generateNormals');
end;

procedure TTestStaticSupport.DovrebbeDareLeBoundsDiUnaGeometriaVuotaPulite;
var
  LTriangles: TStaticTriangles;
begin
  LTriangles := Triangles(0, []);
  Assert.IsTrue(LTriangles.CalcBounds.IsCleared);
  LTriangles := Triangles(3, [0, 1, 2]);
  Assert.AreEqual<Single>(2, LTriangles.CalcBounds.Maxs.X);
  Assert.AreEqual<Single>(-2, LTriangles.CalcBounds.Mins.Z);
end;

procedure TTestStaticSupport.DovrebbeNumerareESommareLeSuperficiDelModello;
var
  LModel: TStaticModel;
  LIntf: IStaticModel;
begin
  LModel := TStaticModel.Create('m');
  LIntf := LModel;
  Assert.AreEqual(0, LModel.AddSurface('a'));
  Assert.AreEqual(1, LModel.AddSurface('b'));
  LModel.AddGeometry(0, Triangles(3, [0, 1, 2]));
  LModel.AddGeometry(0, Triangles(3, [0, 1, 2]));
  LModel.AddGeometry(1, Triangles(4, [0, 1, 3]));
  LModel.AddWarning('w');
  LModel.Finish;
  Assert.AreEqual(2, LIntf.NumSurfaces);
  Assert.AreEqual<Integer>(1, LIntf.Surfaces[1].Id);
  Assert.AreEqual('a', string(LModel.MaterialName(0)));
  Assert.AreEqual(10, LIntf.TotalVerts);
  Assert.AreEqual(9, LIntf.TotalIndexes);
  Assert.AreEqual<Single>(3, LIntf.Bounds.Maxs.X);
  Assert.AreEqual<Integer>(1, Length(LIntf.Warnings));
  Assert.IsTrue(LIntf.Surfaces[0].HasGeometry);
end;

procedure TTestStaticSupport.DovrebbeRifiutareUnaSuperficieChePassaLIntervallo;
var
  LIntf: IStaticModel;
begin
  LIntf := TStaticModel.Create('m');
  Assert.WillRaise(
    procedure
    begin
      if LIntf.Surfaces[0].Id < 0 then Exit;
    end,
    EArgumentOutOfRangeException);
end;

procedure TTestStaticSupport.DovrebbeTrovareIlVectorGiaVistoDelSottoinsieme;
var
  LRemap: TArray<Integer>;
begin
  LRemap := TStaticVectorSubset.RemapPositions([V3(0, 0, 0), V3(5, 5, 5), V3(0.004, -0.004, 0.009), V3(5, 5.0099, 5)], 0.01);
  Assert.AreEqual(0, LRemap[0]);
  Assert.AreEqual(1, LRemap[1]);
  Assert.AreEqual(0, LRemap[2], 'within 0.01 on every axis');
  Assert.AreEqual(1, LRemap[3]);
end;

procedure TTestStaticSupport.DovrebbeNonUnireVectorPiuLontaniDellEpsilon;
var
  LRemap: TArray<Integer>;
begin
  LRemap := TStaticVectorSubset.RemapPositions([V3(0, 0, 0), V3(0.011, 0, 0), V3(0, 0, 0.5)], 0.01);
  Assert.AreEqual(0, LRemap[0]);
  Assert.AreEqual(1, LRemap[1]);
  Assert.AreEqual(2, LRemap[2]);
  Assert.AreEqual<Integer>(0, Length(TStaticVectorSubset.RemapPositions([], 0.01)));
end;

procedure TTestStaticSupport.DovrebbeUnireTexCoordInDueDimensioni;
var
  LRemap: TArray<Integer>;
begin
  LRemap := TStaticVectorSubset.RemapTexCoords([V2(0.5, 0.5), V2(0.5005, 0.4996), V2(0.5, 0.502)], 0.001);
  Assert.AreEqual(0, LRemap[0]);
  Assert.AreEqual(0, LRemap[1]);
  Assert.AreEqual(2, LRemap[2]);
end;

procedure TTestStaticSupport.DovrebbeUnireVertexConLaStessaCombinazione;
var
  LWelder: TStaticVertexWelder;
begin
  LWelder := TStaticVertexWelder.Create(2, 6);
  try
    Assert.AreEqual(0, LWelder.Find(0, 0, $FFFFFFFF, V3(0, 0, 1), True, 0.98));
    Assert.AreEqual(0, LWelder.Find(0, 0, $FFFFFFFF, V3(0, 0.1, 0.995), True, 0.98), 'the normals are near');
    Assert.AreEqual(1, LWelder.Find(0, 1, $FFFFFFFF, V3(0, 0, 1), True, 0.98), 'another texture coordinate');
    Assert.AreEqual(2, LWelder.Find(0, 0, $FF000000, V3(0, 0, 1), True, 0.98), 'another colour');
    Assert.AreEqual(3, LWelder.Find(0, 0, $FFFFFFFF, V3(0, 1, 0), True, 0.98), 'another normal');
    Assert.AreEqual(4, LWelder.Find(1, 0, $FFFFFFFF, V3(0, 0, 1), True, 0.98), 'another position');
    Assert.AreEqual(5, LWelder.Count);
    Assert.AreEqual(1, LWelder.Position(4));
    Assert.AreEqual(1, LWelder.TexCoord(1));
    Assert.AreEqual<Cardinal>($FF000000, LWelder.Color(2));
    Assert.AreEqual<Single>(1, LWelder.Normal(3).Y);
  finally
    LWelder.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeDistinguereLeNormaliSoloSeCeNeSono;
var
  LWelder: TStaticVertexWelder;
begin
  LWelder := TStaticVertexWelder.Create(1, 3);
  try
    Assert.AreEqual(0, LWelder.Find(0, 0, 0, V3(0, 0, 1), False, 0.98));
    Assert.AreEqual(0, LWelder.Find(0, 0, 0, V3(0, 1, 0), False, 0.98), 'without parsed normals the texture and colour are enough');
  finally
    LWelder.Free;
  end;
end;

procedure TTestStaticSupport.DovrebbeUnireSuperficiPerMaterialeNellOrdineDiCreazione;
var
  LModel: TStaticModel;
  LKeep: IStaticModel;
  LMergeTo: TArray<Integer>;
begin
  LModel := TStaticModel.Create('m');
  LKeep := LModel;
  LMergeTo := TStaticSurfacePlanner.Plan(LModel, ['x', 'Y', 'X', 'y', 'z'], True);
  Assert.AreEqual(3, LModel.NumSurfaces);
  Assert.AreEqual(0, LMergeTo[0]);
  Assert.AreEqual(1, LMergeTo[1]);
  Assert.AreEqual(0, LMergeTo[2]);
  Assert.AreEqual(1, LMergeTo[3]);
  Assert.AreEqual(2, LMergeTo[4]);
  LMergeTo := TStaticSurfacePlanner.Plan(LModel, ['q', 'q'], False);
  Assert.AreEqual(5, LModel.NumSurfaces);
  Assert.AreEqual(4, LMergeTo[1]);
  Assert.AreEqual(5, LKeep.NumSurfaces);
end;

procedure TTestStaticSupport.DovrebbeSceglierILoaderDallEstensione;
begin
  Assert.IsNotNull(TStaticModelFactory.CreateLoaderFor('models/a.LWO', TStaticLoadOptions.Default));
  Assert.IsNotNull(TStaticModelFactory.CreateLoaderFor('models/a.ase', TStaticLoadOptions.Default));
  Assert.IsNull(TStaticModelFactory.CreateLoaderFor('models/a.md5mesh', TStaticLoadOptions.Default));
  Assert.IsNotNull(TStaticModelFactory.CreateLwoLoader);
  Assert.IsNotNull(TStaticModelFactory.CreateAseLoader);
  Assert.IsNotNull(TStaticModelFactory.CreateMd3Loader);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStaticSupport);

end.
