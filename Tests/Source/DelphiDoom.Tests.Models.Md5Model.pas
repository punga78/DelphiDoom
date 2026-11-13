{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - MD5 models and meshes          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md5Model;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>The reader of md5mesh, TMd5Model and TMd5Mesh with small models written here</summary>
  [TestFixture]
  [Category('Md5')]
  TTestMd5Model = class
  strict private
    FParser: IMd5ModelParser;
    function Parse(const AText: AnsiString): IMd5Model;
    /// <summary>A model with two joints, a mesh body to fill and the lines of the joints</summary>
    function ModelText(const AMeshBody: AnsiString; const AJointLines: AnsiString = ''): AnsiString;
    procedure CheckError(const AText: AnsiString; const AFragment: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereIGiuntiEIlNomeDellaMesh;
    [Test]
    procedure DovrebbeDarePosaRelativaDelFiglioRuotandoILocalDelGenitore;
    [Test]
    procedure DovrebbeTrattareOgniGenitoreNegativoComeRadice;
    [Test]
    procedure DovrebbeCercareUnGiuntoSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeDareUnNomeDiGiuntoPerUnaManigliaNonValida;
    [Test]
    procedure DovrebbeCalcolareLaPosizioneDiUnVerticeConDuePesi;
    [Test]
    procedure DovrebbeScalareIPesiNelModelloGrasso;
    [Test]
    procedure DovrebbeRifiutareUnaMatriceConMenoGiuntiDelNecessario;
    [Test]
    procedure DovrebbeDareLeBoundsDellaMeshEDelModello;
    [Test]
    procedure DovrebbeDareIlGiuntoDelPesoMaggioreSenzaGuardareLUltimoPeso;
    [Test]
    procedure DovrebbeRifiutareUnaMeshFuoriDallIntervalloNelGiuntoPiuVicino;
    [Test]
    procedure DovrebbeDareIlPrimoIndiceValidoQuandoGliAltriNonLoSono;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneDiversa;
    [Test]
    procedure DovrebbeDirelaRigaEIlFileNellErrore;
    [Test]
    procedure DovrebbeRifiutareUnGenitoreNonPrecedente;
    [Test]
    procedure DovrebbeRifiutareUnVerticeSenzaPesi;
    [Test]
    procedure DovrebbeRifiutareUnGiuntoDelPesoFuoriDallIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnTriangoloConUnVerticeCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutarePesiCheNonCiSono;
    [Test]
    procedure DovrebbeRifiutareUnNumeroNegativoDiVertici;
    [Test]
    procedure DovrebbeRifiutareUnaMeshSenzaChiusura;
    [Test]
    procedure DovrebbeRifiutareUnPesoConIndiciNegativi;
  end;

implementation

uses
  DelphiDoom.Tests.Models.Md5Golden,
  System.StrUtils,
  DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Factory;

const
  EPSILON = 1E-5;
  HALF_SQRT2 = '0.70710678';

  // two vertexes of the mesh: the first on the root, the second on both joints; one triangle
  SIMPLE_MESH =
    'mesh {'#10 +
    '  name "body"'#10 +
    '  shader "models/test/body"'#10 +
    '  numverts 2'#10 +
    '  vert 0 ( 0 0 ) 0 1'#10 +
    '  vert 1 ( 1 1 ) 1 2'#10 +
    '  numtris 1'#10 +
    '  tri 0 0 1 1'#10 +
    '  numweights 3'#10 +
    '  weight 0 0 1.0 ( 1 0 0 )'#10 +
    '  weight 1 0 0.25 ( 0 4 0 )'#10 +
    '  weight 2 1 0.75 ( 0 0 4 )'#10 +
    '}'#10;

{ TTestMd5Model }

procedure TTestMd5Model.Setup;
begin
  FParser := TMd5Factory.CreateModelParser;
end;

function TTestMd5Model.Parse(const AText: AnsiString): IMd5Model;
begin
  Result := FParser.Parse(AText, 'test.md5mesh');
end;

function TTestMd5Model.ModelText(const AMeshBody, AJointLines: AnsiString): AnsiString;
var
  LJoints: AnsiString;
begin
  LJoints := AJointLines;
  if LJoints = '' then
    LJoints :=
      '  "root" -1 ( 0 0 0 ) ( 0 0 0 )'#10 +
      '  "Arm" 0 ( 10 0 0 ) ( 0 0 0 )'#10;
  Result :=
    'MD5Version 10'#10 +
    'commandline ""'#10 +
    'numJoints 2'#10 +
    'numMeshes 1'#10 +
    'joints {'#10 + LJoints + '}'#10 + AMeshBody;
end;

procedure TTestMd5Model.CheckError(const AText: AnsiString; const AFragment: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    Parse(AText);
  except
    on E: EIdLexerException do
      LMessage := E.Message;
  end;
  Assert.IsTrue((LMessage <> '') and ContainsText(LMessage, AFragment), 'messaggio atteso con "' + AFragment + '", ottenuto "' + LMessage + '"');
end;

procedure TTestMd5Model.DovrebbeLeggereIGiuntiEIlNomeDellaMesh;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  Assert.AreEqual<Integer>(2, LModel.NumJoints);
  Assert.AreEqual('root', string(LModel.Joints[0].Name));
  Assert.AreEqual<Integer>(-1, LModel.Joints[0].Parent);
  Assert.AreEqual<Integer>(0, LModel.Joints[1].Parent);
  Assert.AreEqual<Integer>(1, LModel.NumMeshes);
  Assert.AreEqual('body', string(LModel.Meshes[0].Name));
  Assert.AreEqual('models/test/body', string(LModel.Meshes[0].ShaderName));
  Assert.AreEqual<Integer>(2, LModel.Meshes[0].NumVerts);
  Assert.AreEqual<Integer>(1, LModel.Meshes[0].NumTris);
  Assert.AreEqual<Integer>(3, LModel.Meshes[0].NumWeights);
  CheckNear(1, LModel.Meshes[0].TexCoords[1].X, EPSILON);
  Assert.AreEqual<Integer>(3, Length(LModel.Meshes[0].Triangles));
end;

procedure TTestMd5Model.DovrebbeDarePosaRelativaDelFiglioRuotandoILocalDelGenitore;
var
  LModel: IMd5Model;
  LAbsolute, LReference: TArray<TMd5JointMat>;
  LElement: Integer;
begin
  // the file has absolute poses: the root turned 90 degrees around z, the child at (0,2,0)
  LModel := Parse(ModelText(SIMPLE_MESH,
    '  "root" -1 ( 0 0 0 ) ( 0 0 ' + HALF_SQRT2 + ' )'#10 + '  "Arm" 0 ( 0 2 0 ) ( 0 0 0 )'#10));
  // the pose of the child is relative: the distance from the root in the axes of the root
  CheckNear(2, Abs(LModel.DefaultPose[1].T.X), 1E-4, 'x');
  CheckNear(0, LModel.DefaultPose[1].T.Y, 1E-4, 'y');
  // and putting the relative poses back on the skeleton gives the absolute ones of the file
  LAbsolute := LModel.Skeleton.ToAbsolute(LModel.DefaultPose);
  LReference := LModel.ReferenceMatrices;
  for LElement := 0 to 11 do
  begin
    CheckNear(LReference[0].M[LElement], LAbsolute[0].M[LElement], 1E-4, 'radice ' + IntToStr(LElement));
    CheckNear(LReference[1].M[LElement], LAbsolute[1].M[LElement], 1E-4, 'figlio ' + IntToStr(LElement));
  end;
end;
procedure TTestMd5Model.DovrebbeTrattareOgniGenitoreNegativoComeRadice;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH, '  "root" -7 ( 0 0 0 ) ( 0 0 0 )'#10 + '  "Arm" 0 ( 10 0 0 ) ( 0 0 0 )'#10));
  Assert.AreEqual<Integer>(-1, LModel.Joints[0].Parent);
end;

procedure TTestMd5Model.DovrebbeCercareUnGiuntoSenzaDistinguereLeMaiuscole;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  Assert.AreEqual<Integer>(1, LModel.GetJointHandle('ARM'));
  Assert.AreEqual<Integer>(MD5_INVALID_JOINT, LModel.GetJointHandle('leg'));
  Assert.AreEqual('Arm', string(LModel.GetJointName(1)));
end;

procedure TTestMd5Model.DovrebbeDareUnNomeDiGiuntoPerUnaManigliaNonValida;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  Assert.AreEqual(MD5_INVALID_JOINT_NAME, string(LModel.GetJointName(-1)));
  Assert.AreEqual(MD5_INVALID_JOINT_NAME, string(LModel.GetJointName(2)));
end;

procedure TTestMd5Model.DovrebbeCalcolareLaPosizioneDiUnVerticeConDuePesi;
var
  LModel: IMd5Model;
  LVerts: TArray<TIdVec3>;
begin
  // joints in the pose of the file: the root at the origin, the arm at (10,0,0), no rotation
  LModel := Parse(ModelText(SIMPLE_MESH));
  LVerts := LModel.Meshes[0].TransformVerts(LModel.ReferenceMatrices);
  // vertex 0: offset (1,0,0) with weight 1 on the root
  CheckNear(1, LVerts[0].X, EPSILON);
  // vertex 1: (0,1,0) from the root, and (0,0,3) + 10*0.75 along x from the arm
  CheckNear(7.5, LVerts[1].X, EPSILON, 'x');
  CheckNear(1, LVerts[1].Y, EPSILON, 'y');
  CheckNear(3, LVerts[1].Z, EPSILON, 'z');
end;

procedure TTestMd5Model.DovrebbeScalareIPesiNelModelloGrasso;
var
  LModel: IMd5Model;
  LVerts: TArray<TIdVec3>;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  LVerts := LModel.Meshes[0].TransformScaledVerts(LModel.ReferenceMatrices, 2.0);
  CheckNear(2, LVerts[0].X, EPSILON);
  CheckNear(15, LVerts[1].X, EPSILON);
  CheckNear(2, LVerts[1].Y, EPSILON);
  CheckNear(6, LVerts[1].Z, EPSILON);
end;

procedure TTestMd5Model.DovrebbeRifiutareUnaMatriceConMenoGiuntiDelNecessario;
var
  LModel: IMd5Model;
  LMatrices: TArray<TMd5JointMat>;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  LMatrices := Copy(LModel.ReferenceMatrices, 0, 1);
  Assert.WillRaise(
    procedure
    begin
      LModel.Meshes[0].TransformVerts(LMatrices);
    end, EModelsException);
end;

procedure TTestMd5Model.DovrebbeDareLeBoundsDellaMeshEDelModello;
var
  LModel: IMd5Model;
  LBounds: TGeoBounds;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  LBounds := LModel.Meshes[0].CalcBounds(LModel.ReferenceMatrices);
  CheckNear(1, LBounds.Mins.X, EPSILON);
  CheckNear(7.5, LBounds.Maxs.X, EPSILON);
  CheckNear(0, LBounds.Mins.Y, EPSILON);
  CheckNear(1, LBounds.Maxs.Y, EPSILON);
  CheckNear(3, LModel.Bounds.Maxs.Z, EPSILON);
  CheckNear(1, LModel.Bounds.Mins.X, EPSILON);
end;

procedure TTestMd5Model.DovrebbeDareIlGiuntoDelPesoMaggioreSenzaGuardareLUltimoPeso;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  // vertex 1 has the weights 0.25 (root) and 0.75 (arm), but the original never looks at the last
  // weight of a vertex: the answer is the root
  Assert.AreEqual<Integer>(0, LModel.NearestJoint(0, 1, -1, -1));
  Assert.AreEqual<Integer>(0, LModel.NearestJoint(0, 0, -1, -1));
end;

procedure TTestMd5Model.DovrebbeRifiutareUnaMeshFuoriDallIntervalloNelGiuntoPiuVicino;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  Assert.WillRaise(
    procedure
    begin
      LModel.NearestJoint(1, 0, 0, 0);
    end, EModelsException);
end;

procedure TTestMd5Model.DovrebbeDareIlPrimoIndiceValidoQuandoGliAltriNonLoSono;
var
  LModel: IMd5Model;
begin
  LModel := Parse(ModelText(SIMPLE_MESH));
  Assert.AreEqual<Integer>(0, LModel.NearestJoint(0, -1, 1, 5));
  Assert.AreEqual<Integer>(0, LModel.NearestJoint(0, 9, 9, 1));
  Assert.AreEqual<Integer>(0, LModel.NearestJoint(0, 9, 9, 9));
end;

procedure TTestMd5Model.DovrebbeRifiutareUnaVersioneDiversa;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'MD5Version 10', 'MD5Version 11'), 'Invalid version 11');
end;

procedure TTestMd5Model.DovrebbeDirelaRigaEIlFileNellErrore;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'MD5Version 10', 'MD5Version 11'), 'test.md5mesh');
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'MD5Version 10', 'MD5Version 11'), 'line 1');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnGenitoreNonPrecedente;
begin
  CheckError(ModelText(SIMPLE_MESH, '  "root" -1 ( 0 0 0 ) ( 0 0 0 )'#10 + '  "Arm" 1 ( 10 0 0 ) ( 0 0 0 )'#10),
    'Invalid parent for joint ''Arm''');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnVerticeSenzaPesi;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'vert 0 ( 0 0 ) 0 1', 'vert 0 ( 0 0 ) 0 0'), 'Vertex without any joint weights');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnGiuntoDelPesoFuoriDallIntervallo;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'weight 2 1 0.75', 'weight 2 2 0.75'), 'Joint Index out of range(2): 2');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnTriangoloConUnVerticeCheNonEsiste;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'tri 0 0 1 1', 'tri 0 0 1 2'), 'Triangle vertex out of range(2): 2');
end;

procedure TTestMd5Model.DovrebbeRifiutarePesiCheNonCiSono;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'numweights 3', 'numweights 2'), 'out of range weights');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnNumeroNegativoDiVertici;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'numverts 2', 'numverts -1'), 'Invalid size: -1');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnaMeshSenzaChiusura;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), '}'#10, ''), 'expected ''}''');
end;

procedure TTestMd5Model.DovrebbeRifiutareUnPesoConIndiciNegativi;
begin
  CheckError(Replace8(ModelText(SIMPLE_MESH), 'vert 1 ( 1 1 ) 1 2', 'vert 1 ( 1 1 ) -1 2'), 'Invalid weights for a vertex');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMd5Model);

end.
