{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TIdJointMat and TIdJointQuat (idJointMat)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.JointMat;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The joint matrix: hand worked values and parity with the real idJointMat of Doom 3
  ///   (Tests\Data\Geometry\surface.golden.txt, lines jm_*)
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometryJointMat = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLeStesseDimensioniDelCpp;
    [Test]
    procedure SetRotationDovrebbeMemorizzareLaTrasposta;
    [Test]
    procedure RotateNonDovrebbeTraslare;
    [Test]
    procedure TransformDovrebbeTraslarePerIlPesoW;
    [Test]
    procedure MultiplySelfEDivideSelfDovrebberoEssereInversi;
    [Test]
    procedure CompareDovrebbeUsareLEpsilon;
    [Test]
    procedure ToJointQuatDovrebbeDareLaRotazioneDiUnAsse;
    [Test]
    procedure LeOperazioniDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure ToJointQuatDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.JointQuat, DelphiDoom.MathCore.Float.JointMat,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.MathCore.Float.GeometryAdapter,
  DelphiDoom.Tests.Geometry.Golden;

function ReadMatrix(var AReader: TGeoGoldenReader): TIdMat3;
begin
  Result := TIdGeometryAdapter.ToId(AReader.Mat3);
end;

function ReadVector(var AReader: TGeoGoldenReader): TIdVec3;
begin
  Result := TIdGeometryAdapter.ToId(AReader.Vec3);
end;

procedure PutMatrix(AWriter: TGeoGoldenWriter; const AMatrix: TIdMat3);
begin
  AWriter.Mat3(TIdGeometryAdapter.ToGeo(AMatrix));
end;

procedure PutVector(AWriter: TGeoGoldenWriter; const AVector: TIdVec3);
begin
  AWriter.Vec3(TIdGeometryAdapter.ToGeo(AVector));
end;

procedure TTestGeometryJointMat.DovrebbeAvereLeStesseDimensioniDelCpp;
begin
  Assert.AreEqual(48, SizeOf(TIdJointMat));
  Assert.AreEqual(28, SizeOf(TIdJointQuat));
end;

procedure TTestGeometryJointMat.SetRotationDovrebbeMemorizzareLaTrasposta;
var
  LJoint: TIdJointMat;
begin
  LJoint.Zero;
  LJoint.SetRotation(TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9));
  // mat[r * 4 + c] = m[c][r]
  Assert.AreEqual<Single>(1, LJoint.Mat[0]);
  Assert.AreEqual<Single>(4, LJoint.Mat[1]);
  Assert.AreEqual<Single>(7, LJoint.Mat[2]);
  Assert.AreEqual<Single>(2, LJoint.Mat[4]);
  Assert.AreEqual<Single>(8, LJoint.Mat[6]);
  Assert.AreEqual<Single>(0, LJoint.Mat[3]);
  Assert.AreEqual<Single>(6, LJoint.ToMat3.Rows[1].Z);
end;

procedure TTestGeometryJointMat.RotateNonDovrebbeTraslare;
var
  LJoint: TIdJointMat;
  LResult: TIdVec3;
begin
  LJoint.Zero;
  LJoint.SetRotation(TIdMat3.Identity);
  LJoint.SetTranslation(TIdVec3.Create(10, 20, 30));
  LResult := LJoint.Rotate(TIdVec3.Create(1, 2, 3));
  Assert.AreEqual<Single>(1, LResult.X);
  Assert.AreEqual<Single>(3, LResult.Z);
  Assert.AreEqual<Single>(20, LJoint.ToVec3.Y);
end;

procedure TTestGeometryJointMat.TransformDovrebbeTraslarePerIlPesoW;
var
  LJoint: TIdJointMat;
  LResult: TIdVec3;
begin
  LJoint.Zero;
  LJoint.SetRotation(TIdMat3.Identity);
  LJoint.SetTranslation(TIdVec3.Create(10, 20, 30));
  LResult := LJoint.Transform(TIdVec4.Create(1, 2, 3, 1));
  Assert.AreEqual<Single>(11, LResult.X);
  Assert.AreEqual<Single>(33, LResult.Z);
  LResult := LJoint.Transform(TIdVec4.Create(1, 2, 3, 0));
  Assert.AreEqual<Single>(1, LResult.X);
end;

procedure TTestGeometryJointMat.MultiplySelfEDivideSelfDovrebberoEssereInversi;
var
  LFirst, LSecond, LProduct: TIdJointMat;
  LRotation: TIdMat3;
begin
  // a rotation of 90 degrees about z, as the transposed matrix of idlib wants it
  LRotation := TIdMat3.Create(0, 1, 0, -1, 0, 0, 0, 0, 1);
  LFirst.Zero;
  LFirst.SetRotation(LRotation);
  LFirst.SetTranslation(TIdVec3.Create(1, 2, 3));
  LSecond.Zero;
  LSecond.SetRotation(TIdMat3.Identity);
  LSecond.SetTranslation(TIdVec3.Create(5, 0, 0));
  LProduct := LFirst;
  LProduct.MultiplySelf(LSecond);
  Assert.AreEqual<Single>(6, LProduct.ToVec3.X);
  LProduct.DivideSelf(LSecond);
  Assert.IsTrue(LProduct.Compare(LFirst, 1E-6));
end;

procedure TTestGeometryJointMat.CompareDovrebbeUsareLEpsilon;
var
  LFirst, LSecond: TIdJointMat;
begin
  LFirst.Zero;
  LSecond.Zero;
  LSecond.Mat[5] := 0.001;
  Assert.IsFalse(LFirst.Compare(LSecond));
  Assert.IsFalse(LFirst.Compare(LSecond, 0.0005));
  Assert.IsTrue(LFirst.Compare(LSecond, 0.01));
end;

procedure TTestGeometryJointMat.ToJointQuatDovrebbeDareLaRotazioneDiUnAsse;
var
  LJoint: TIdJointMat;
  LQuat: TIdJointQuat;
begin
  LJoint.Zero;
  LJoint.SetRotation(TIdMat3.Identity);
  LJoint.SetTranslation(TIdVec3.Create(1, 2, 3));
  LQuat := LJoint.ToJointQuat;
  AssertNear(1, LQuat.Q.W, 1E-5);
  AssertNear(0, LQuat.Q.X, 1E-5);
  Assert.AreEqual<Single>(2, LQuat.T.Y);
end;

procedure TTestGeometryJointMat.LeOperazioniDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LA, LB, LProduct, LQuotient: TIdJointMat;
  LMatrixA, LMatrixB: TIdMat3;
  LTranslationA, LTranslationB, LVector: TIdVec3;
  LVector4: TIdVec4;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['jm_ops']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LMatrixA := ReadMatrix(LReader);
      LTranslationA := ReadVector(LReader);
      LMatrixB := ReadMatrix(LReader);
      LTranslationB := ReadVector(LReader);
      LVector := ReadVector(LReader);
      LVector4.X := LReader.Float;
      LVector4.Y := LReader.Float;
      LVector4.Z := LReader.Float;
      LVector4.W := LReader.Float;
      LA.Zero;
      LA.SetRotation(LMatrixA);
      LA.SetTranslation(LTranslationA);
      LB.Zero;
      LB.SetRotation(LMatrixB);
      LB.SetTranslation(LTranslationB);
      LWriter := TGeoGoldenWriter.Create;
      try
        PutVector(LWriter, LA.Rotate(LVector));
        PutVector(LWriter, LA.Transform(LVector4));
        LProduct := LA;
        LProduct.MultiplySelf(LB);
        PutMatrix(LWriter, LProduct.ToMat3);
        PutVector(LWriter, LProduct.ToVec3);
        LQuotient := LA;
        LQuotient.DivideSelf(LB);
        PutMatrix(LWriter, LQuotient.ToMat3);
        PutVector(LWriter, LQuotient.ToVec3);
        PutMatrix(LWriter, LA.ToMat3);
        PutVector(LWriter, LA.ToVec3);
        LWriter.Flag(LA.Compare(LA));
        LWriter.Flag(LA.Compare(LB));
        LWriter.Flag(LA.Compare(LB, 1.0));
        LWriter.Flag(LA.Compare(LA, 0.0));
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryJointMat.ToJointQuatDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LJoint: TIdJointMat;
  LQuat: TIdJointQuat;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['jm_quat']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LJoint.Zero;
      LJoint.SetRotation(ReadMatrix(LReader));
      LJoint.SetTranslation(ReadVector(LReader));
      LQuat := LJoint.ToJointQuat;
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.Float(LQuat.Q.X);
        LWriter.Float(LQuat.Q.Y);
        LWriter.Float(LQuat.Q.Z);
        LWriter.Float(LQuat.Q.W);
        PutVector(LWriter, LQuat.T);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

end.
