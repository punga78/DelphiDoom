{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - MD5 surfaces and deform info   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md5Surface;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Md5.SurfaceBuilder;

type
  /// <summary>TMd5SurfaceBuilder on the synthetic cube of Tests\Data\Models\md5</summary>
  [TestFixture]
  [Category('Md5')]
  TTestMd5Surface = class
  strict private
    FModel: IMd5Model;
    FBuilder: TMd5SurfaceBuilder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIlNomeDelMateriale;
    [Test]
    procedure DovrebbeDareNormaliETangentiUnitarieESuilPianoDellaNormale;
    [Test]
    procedure DovrebbeNonDerivareNulla;
    [Test]
    procedure DovrebbeTenereLeTexCoordEIFoglietti;
    [Test]
    procedure DovrebbeUsareLaScalaDellaPelleSuiVertici;
    [Test]
    procedure DovrebbeUsareLeTangentiNonLevigate;
  end;

  /// <summary>The deform info and the deriver on small meshes written by hand</summary>
  [TestFixture]
  [Category('Deform')]
  TTestDeformBuilder = class
  public
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareIndiciNonMultipliDiTre;
    [Test]
    procedure DovrebbeAccettareUnaMeshVuota;
    [Test]
    procedure DovrebbeDuplicareIVerticiSullaCucituraSpecchiata;
    [Test]
    procedure DovrebbeTrovareIVerticiConLaStessaPosizione;
    [Test]
    procedure DovrebbeLasciareINormaliNulleSeIFotogrammiSonoDegeneri;
    [Test]
    procedure DovrebbeDareIlPianoDiUnTriangoloSulPianoZ;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Geometry.Plane,
  DelphiDoom.Models.Md5.Factory,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Deform.Types,
  DelphiDoom.Models.Static.DeformBuilder,
  DelphiDoom.Models.Static.TangentDeriver,
  DelphiDoom.Tests.Models.Md5Golden;

function Vert(const AX, AY, AZ, AU, AV: Single): TStaticDrawVert;
begin
  Result.Clear;
  Result.Xyz := TIdVec3.Create(AX, AY, AZ);
  Result.St := TIdVec2.Create(AU, AV);
end;

{ TTestMd5Surface }

procedure TTestMd5Surface.Setup;
begin
  FModel := TMd5Factory.CreateModelParser.Parse(TMd5Golden.ReadText('cube.md5mesh'), 'cube.md5mesh');
  FBuilder := TMd5SurfaceBuilder.Create(FModel.Meshes[0], FModel.ReferenceMatrices, False);
end;

procedure TTestMd5Surface.TearDown;
begin
  FBuilder.Free;
end;

procedure TTestMd5Surface.DovrebbeDareIlNomeDelMateriale;
begin
  Assert.AreEqual('models/test/cube', string(FBuilder.MaterialName));
end;

procedure TTestMd5Surface.DovrebbeDareNormaliETangentiUnitarieESuilPianoDellaNormale;
var
  LTriangles: TStaticTriangles;
  LIndex, LTangent: Integer;
begin
  LTriangles := FBuilder.Build(FModel.ReferenceMatrices, 0);
  Assert.AreEqual<Integer>(FBuilder.DeformInfo.NumOutputVerts, LTriangles.NumVerts);
  Assert.IsFalse(LTriangles.GenerateNormals);
  for LIndex := 0 to LTriangles.NumVerts - 1 do
  begin
    Assert.AreEqual(1.0, LTriangles.Verts[LIndex].Normal.Length, 0.01, 'normale');
    for LTangent := 0 to 1 do
    begin
      Assert.AreEqual(1.0, LTriangles.Verts[LIndex].Tangents[LTangent].Length, 0.01, 'tangente');
      Assert.AreEqual(0.0, LTriangles.Verts[LIndex].Tangents[LTangent] * LTriangles.Verts[LIndex].Normal, 0.02,
        'ortogonale alla normale');
    end;
  end;
end;

procedure TTestMd5Surface.DovrebbeNonDerivareNulla;
var
  LTriangles: TStaticTriangles;
begin
  LTriangles := FBuilder.Build(FModel.ReferenceMatrices, 0, False);
  Assert.AreEqual(0.0, LTriangles.Verts[0].Normal.Length, 0.0, 'normale ancora nulla');
end;

procedure TTestMd5Surface.DovrebbeTenereLeTexCoordEIFoglietti;
var
  LTriangles: TStaticTriangles;
begin
  LTriangles := FBuilder.Build(FModel.ReferenceMatrices, 0);
  Assert.AreEqual<Integer>(36, LTriangles.NumIndexes);
  Assert.AreEqual(1.0, LTriangles.Verts[1].St.X, 0.0);
  Assert.AreEqual(0.0, LTriangles.Verts[1].St.Y, 0.0);
end;

procedure TTestMd5Surface.DovrebbeUsareLaScalaDellaPelleSuiVertici;
var
  LNormal, LScaled: TStaticTriangles;
begin
  LNormal := FBuilder.Build(FModel.ReferenceMatrices, 0);
  LScaled := FBuilder.Build(FModel.ReferenceMatrices, 0.5);
  Assert.AreEqual<Integer>(LNormal.NumVerts, LScaled.NumVerts);
end;

procedure TTestMd5Surface.DovrebbeUsareLeTangentiNonLevigate;
var
  LBuilder: TMd5SurfaceBuilder;
  LTriangles: TStaticTriangles;
begin
  LBuilder := TMd5SurfaceBuilder.Create(FModel.Meshes[0], FModel.ReferenceMatrices, True);
  try
    Assert.AreEqual<Integer>(LBuilder.DeformInfo.NumOutputVerts, Length(LBuilder.DeformInfo.DominantTris));
    LTriangles := LBuilder.Build(FModel.ReferenceMatrices, 0);
    Assert.AreEqual(1.0, LTriangles.Verts[2].Normal.Length, 0.01);
  finally
    LBuilder.Free;
  end;
end;

{ TTestDeformBuilder }

procedure TTestDeformBuilder.DovrebbeRifiutareUnIndiceFuoriIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      TStaticDeformBuilder.Build([Vert(0, 0, 0, 0, 0), Vert(1, 0, 0, 1, 0)], [0, 1, 2], False);
    end, EStaticModelException);
end;

procedure TTestDeformBuilder.DovrebbeRifiutareIndiciNonMultipliDiTre;
begin
  Assert.WillRaise(
    procedure
    begin
      TStaticDeformBuilder.Build([Vert(0, 0, 0, 0, 0), Vert(1, 0, 0, 1, 0)], [0, 1], False);
    end, EStaticModelException);
end;

procedure TTestDeformBuilder.DovrebbeAccettareUnaMeshVuota;
var
  LInfo: TStaticDeformInfo;
begin
  LInfo := TStaticDeformBuilder.Build(nil, nil, True);
  Assert.AreEqual<Integer>(0, LInfo.NumOutputVerts);
  Assert.AreEqual<Integer>(0, LInfo.NumIndexes);
end;

procedure TTestDeformBuilder.DovrebbeDuplicareIVerticiSullaCucituraSpecchiata;
var
  LVerts: TArray<TStaticDrawVert>;
  LInfo: TStaticDeformInfo;
begin
  // vertexes 1 and 2 are shared by a triangle with positive polarity and one with negative polarity
  LVerts := [Vert(0, 0, 0, 0, 0), Vert(1, 0, 0, 1, 0), Vert(0, 1, 0, 0, 1), Vert(2, 0, 0, 0, 0)];
  LInfo := TStaticDeformBuilder.Build(LVerts, [0, 1, 2, 1, 3, 2], False);
  Assert.AreEqual<Integer>(6, LInfo.NumOutputVerts);
  Assert.AreEqual<Integer>(2, LInfo.NumMirroredVerts);
  Assert.AreEqual<Integer>(4, LInfo.Indexes[3], 'il triangolo negativo usa il vertice duplicato');
  Assert.AreEqual<Integer>(5, LInfo.Indexes[5]);
  Assert.AreEqual<Integer>(1, LInfo.MirroredVerts[0]);
  Assert.AreEqual<Integer>(2, LInfo.MirroredVerts[1]);
end;

procedure TTestDeformBuilder.DovrebbeTrovareIVerticiConLaStessaPosizione;
var
  LVerts: TArray<TStaticDrawVert>;
  LInfo: TStaticDeformInfo;
begin
  LVerts := [Vert(0, 0, 0, 0, 0), Vert(1, 0, 0, 1, 0), Vert(0, 1, 0, 0, 1), Vert(0, 0, 0, 0.5, 0.5)];
  LInfo := TStaticDeformBuilder.Build(LVerts, [0, 1, 2, 3, 1, 2], False);
  Assert.AreEqual<Integer>(1, LInfo.NumDupVerts);
  Assert.AreEqual<Integer>(3, LInfo.DupVerts[0]);
  Assert.AreEqual<Integer>(0, LInfo.DupVerts[1]);
  Assert.AreEqual<Integer>(0, LInfo.SilIndexes[3]);
end;

procedure TTestDeformBuilder.DovrebbeLasciareINormaliNulleSeIFotogrammiSonoDegeneri;
var
  LVerts: TArray<TStaticDrawVert>;
begin
  // a triangle without area: the original gets an infinite factor for the normal, not an error
  LVerts := [Vert(0, 0, 0, 0, 0), Vert(0, 0, 0, 0, 0), Vert(0, 0, 0, 0, 0)];
  TStaticTangentDeriver.DeriveTangentsWithoutNormals(LVerts, [0, 1, 2]);
  Assert.AreEqual(0.0, LVerts[0].Tangents[0].Length, 0.0);
end;

procedure TTestDeformBuilder.DovrebbeDareIlPianoDiUnTriangoloSulPianoZ;
var
  LVerts: TArray<TStaticDrawVert>;
  LPlanes: TArray<TGeoPlane>;
begin
  LVerts := [Vert(0, 0, 2, 0, 0), Vert(1, 0, 2, 1, 0), Vert(0, 1, 2, 0, 1)];
  LPlanes := TStaticTangentDeriver.DeriveFacePlanes(LVerts, [0, 1, 2]);
  Assert.AreEqual<Integer>(1, Length(LPlanes));
  Assert.AreEqual(-1.0, LPlanes[0].C, 0.01);
  Assert.AreEqual(2.0, LPlanes[0].D, 0.05);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMd5Surface);
  TDUnitX.RegisterTestFixture(TTestDeformBuilder);

end.
