{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - MD5 joints and skeleton        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md5Skeleton;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>TMd5JointMat, TMd5JointQuat and TMd5Skeleton with values worked out by hand</summary>
  [TestFixture]
  [Category('Md5')]
  TTestMd5Skeleton = class
  strict private
    FSkeleton: IMd5Skeleton;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeRifiutareUnGenitoreNonPrecedente;
    [Test]
    procedure DovrebbeRifiutareUnGenitoreCheNonEsiste;
    [Test]
    procedure DovrebbeDareIlGenitoreDiUnGiunto;
    [Test]
    procedure DovrebbeRifiutareUnGiuntoFuoriDallIntervallo;
    [Test]
    procedure DovrebbeSommareLeTraslazioniDiUnaCatenaSenzaRotazioni;
    [Test]
    procedure DovrebbeRuotareLaTraslazioneDelFiglioConLaRotazioneDelPadre;
    [Test]
    procedure DovrebbeNonTrasformareLaRadiceQuandoIlPrimoGiuntoE1;
    [Test]
    procedure DovrebbeDisfareLaTrasformazione;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiGiuntiDiverso;
    [Test]
    procedure DovrebbeRifiutareUnIntervalloDiGiuntiNonValido;
    [Test]
    procedure DovrebbeMescolareMetaStradaPosizioneERotazione;
    [Test]
    procedure DovrebbeMescolareSoloIGiuntiDellIndice;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiMescolanzaFuoriDallIntervallo;
    [Test]
    procedure DovrebbeTornareDalleMatriciAiQuaternioniPerLeRotazioniDi180Gradi;
    [Test]
    procedure DovrebbeTornareDalleMatriciAiQuaternioniPerUnaRotazioneDi90Gradi;
    [Test]
    procedure DovrebbeRuotareESpostareUnVettore;
    [Test]
    procedure DovrebbeConfrontareLeMatriciConUnaTolleranza;
  end;

implementation

uses
  DelphiDoom.Tests.Models.Md5Golden,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Factory;

const
  EPSILON = 1E-5;
  HALF_SQRT2 = 0.70710678118654752;

function Joint(const AX, AY, AZ: Single; const AQX, AQY, AQZ, AQW: Single): TMd5JointQuat;
begin
  Result.T := TIdVec3.Create(AX, AY, AZ);
  Result.Q := TIdQuat.Create(AQX, AQY, AQZ, AQW);
end;

{ TTestMd5Skeleton }

procedure TTestMd5Skeleton.Setup;
begin
  // a chain: 0 <- 1 <- 2
  FSkeleton := TMd5Factory.CreateSkeleton([-1, 0, 1]);
end;

procedure TTestMd5Skeleton.DovrebbeRifiutareUnGenitoreNonPrecedente;
begin
  Assert.WillRaise(
    procedure
    begin
      TMd5Factory.CreateSkeleton([-1, 2, 0]);
    end, EModelsException);
end;

procedure TTestMd5Skeleton.DovrebbeRifiutareUnGenitoreCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      TMd5Factory.CreateSkeleton([-2]);
    end, EModelsException);
end;

procedure TTestMd5Skeleton.DovrebbeDareIlGenitoreDiUnGiunto;
begin
  Assert.AreEqual<Integer>(3, FSkeleton.NumJoints);
  Assert.AreEqual<Integer>(-1, FSkeleton.Parent[0]);
  Assert.AreEqual<Integer>(1, FSkeleton.Parent[2]);
end;

procedure TTestMd5Skeleton.DovrebbeRifiutareUnGiuntoFuoriDallIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      FSkeleton.GetParent(3);
    end, EModelsException);
end;

procedure TTestMd5Skeleton.DovrebbeSommareLeTraslazioniDiUnaCatenaSenzaRotazioni;
var
  LMatrices: TArray<TMd5JointMat>;
begin
  LMatrices := FSkeleton.ToAbsolute([Joint(1, 0, 0, 0, 0, 0, 1), Joint(2, 0, 0, 0, 0, 0, 1), Joint(4, 0, 0, 0, 0, 0, 1)]);
  CheckNear(1, LMatrices[0].ToVec3.X, EPSILON);
  CheckNear(3, LMatrices[1].ToVec3.X, EPSILON);
  CheckNear(7, LMatrices[2].ToVec3.X, EPSILON);
  CheckNear(0, LMatrices[2].ToVec3.Y, EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeRuotareLaTraslazioneDelFiglioConLaRotazioneDelPadre;
var
  LMatrices: TArray<TMd5JointMat>;
  LChild: TIdVec3;
begin
  // the root turns 90 degrees around z: the point (1,0,0) of the child goes to (0,1,0) of the model,
  // or to (0,-1,0) if the transform went the other way round
  LMatrices := FSkeleton.ToAbsolute([Joint(0, 0, 0, 0, 0, HALF_SQRT2, HALF_SQRT2), Joint(1, 0, 0, 0, 0, 0, 1),
    Joint(0, 0, 0, 0, 0, 0, 1)]);
  LChild := LMatrices[1].ToVec3;
  CheckNear(0, LChild.X, EPSILON, 'x');
  CheckNear(1, Abs(LChild.Y), EPSILON, 'y');
  // and the rotation of the child is the one of the root
  CheckNear(0, LMatrices[1].Rotate(TIdVec3.Create(1, 0, 0)).X, EPSILON);
  CheckNear(1, Abs(LMatrices[1].Rotate(TIdVec3.Create(1, 0, 0)).Y), EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeNonTrasformareLaRadiceQuandoIlPrimoGiuntoE1;
var
  LMatrices: TArray<TMd5JointMat>;
begin
  LMatrices := FSkeleton.ConvertToMatrices([Joint(5, 6, 7, 0, 0, 0, 1), Joint(1, 0, 0, 0, 0, 0, 1), Joint(1, 0, 0, 0, 0, 0, 1)]);
  FSkeleton.TransformJoints(LMatrices, 1, 2);
  CheckNear(5, LMatrices[0].ToVec3.X, EPSILON);
  CheckNear(6, LMatrices[1].ToVec3.X, EPSILON);
  CheckNear(7, LMatrices[2].ToVec3.X, EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeDisfareLaTrasformazione;
var
  LMatrices, LOriginal: TArray<TMd5JointMat>;
  LIndex, LElement: Integer;
begin
  LOriginal := FSkeleton.ConvertToMatrices([Joint(1, 2, 3, 0, 0, HALF_SQRT2, HALF_SQRT2), Joint(0.5, 0, 1, 0.5, 0.5, 0.5, 0.5),
    Joint(1, 1, 1, 0, HALF_SQRT2, 0, HALF_SQRT2)]);
  LMatrices := Copy(LOriginal);
  FSkeleton.TransformJoints(LMatrices, 1, 2);
  FSkeleton.UntransformJoints(LMatrices, 1, 2);
  for LIndex := 0 to 2 do
    for LElement := 0 to 11 do
      CheckNear(LOriginal[LIndex].M[LElement], LMatrices[LIndex].M[LElement], 1E-4);
end;

procedure TTestMd5Skeleton.DovrebbeRifiutareUnNumeroDiGiuntiDiverso;
begin
  Assert.WillRaise(
    procedure
    begin
      FSkeleton.ConvertToMatrices([Joint(0, 0, 0, 0, 0, 0, 1)]);
    end, EModelsException);
end;

procedure TTestMd5Skeleton.DovrebbeRifiutareUnIntervalloDiGiuntiNonValido;
var
  LMatrices: TArray<TMd5JointMat>;
begin
  LMatrices := FSkeleton.ConvertToMatrices([Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1)]);
  Assert.WillRaise(
    procedure
    begin
      FSkeleton.TransformJoints(LMatrices, 1, 3);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      FSkeleton.UntransformJoints(LMatrices, -1, 2);
    end, EModelsException);
end;

procedure TTestMd5Skeleton.DovrebbeMescolareMetaStradaPosizioneERotazione;
var
  LJoints, LBlend: TArray<TMd5JointQuat>;
begin
  LJoints := [Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1)];
  LBlend := [Joint(2, 4, 6, 0, 0, HALF_SQRT2, HALF_SQRT2), Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1)];
  FSkeleton.BlendJoints(LJoints, LBlend, 0.5, [0]);
  CheckNear(1, LJoints[0].T.X, EPSILON);
  CheckNear(2, LJoints[0].T.Y, EPSILON);
  CheckNear(3, LJoints[0].T.Z, EPSILON);
  // half of 90 degrees: sin(22.5) and cos(22.5)
  CheckNear(0.38268343, LJoints[0].Q.Z, EPSILON);
  CheckNear(0.92387953, LJoints[0].Q.W, EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeMescolareSoloIGiuntiDellIndice;
var
  LJoints, LBlend: TArray<TMd5JointQuat>;
begin
  LJoints := [Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1)];
  LBlend := [Joint(2, 0, 0, 0, 0, 0, 1), Joint(4, 0, 0, 0, 0, 0, 1), Joint(8, 0, 0, 0, 0, 0, 1)];
  FSkeleton.BlendJoints(LJoints, LBlend, 0.25, [2]);
  CheckNear(0, LJoints[0].T.X, EPSILON);
  CheckNear(0, LJoints[1].T.X, EPSILON);
  CheckNear(2, LJoints[2].T.X, EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeRifiutareUnIndiceDiMescolanzaFuoriDallIntervallo;
var
  LJoints, LBlend: TArray<TMd5JointQuat>;
begin
  LJoints := [Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1)];
  LBlend := Copy(LJoints);
  Assert.WillRaise(
    procedure
    begin
      FSkeleton.BlendJoints(LJoints, LBlend, 0.5, [3]);
    end, EModelsException);
end;

procedure TTestMd5Skeleton.DovrebbeTornareDalleMatriciAiQuaternioniPerLeRotazioniDi180Gradi;
var
  LQuats: TArray<TMd5JointQuat>;
begin
  // the trace is -1 for a half turn: the second branch of idJointMat::ToJointQuat, once for every axis
  LQuats := FSkeleton.ConvertToQuats(FSkeleton.ConvertToMatrices([Joint(1, 2, 3, 1, 0, 0, 0), Joint(0, 0, 0, 0, 1, 0, 0),
    Joint(0, 0, 0, 0, 0, 1, 0)]));
  CheckNear(1, Abs(LQuats[0].Q.X), 1E-3, 'x');
  CheckNear(1, Abs(LQuats[1].Q.Y), 1E-3, 'y');
  CheckNear(1, Abs(LQuats[2].Q.Z), 1E-3, 'z');
  CheckNear(1, LQuats[0].T.X, EPSILON);
  CheckNear(3, LQuats[0].T.Z, EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeTornareDalleMatriciAiQuaternioniPerUnaRotazioneDi90Gradi;
var
  LQuats: TArray<TMd5JointQuat>;
begin
  LQuats := FSkeleton.ConvertToQuats(FSkeleton.ConvertToMatrices([Joint(0, 0, 0, 0, 0, HALF_SQRT2, HALF_SQRT2),
    Joint(0, 0, 0, 0, 0, 0, 1), Joint(0, 0, 0, 0, 0, 0, 1)]));
  CheckNear(HALF_SQRT2, LQuats[0].Q.Z, 1E-3);
  CheckNear(HALF_SQRT2, LQuats[0].Q.W, 1E-3);
  CheckNear(1, LQuats[1].Q.W, 1E-3);
end;

procedure TTestMd5Skeleton.DovrebbeRuotareESpostareUnVettore;
var
  LMatrix: TMd5JointMat;
  LResult: TIdVec3;
begin
  FillChar(LMatrix, SizeOf(LMatrix), 0);
  // diagonal 1, 2, 3 and translation (10, 20, 30)
  LMatrix.M[0] := 1;
  LMatrix.M[5] := 2;
  LMatrix.M[10] := 3;
  LMatrix.M[3] := 10;
  LMatrix.M[7] := 20;
  LMatrix.M[11] := 30;
  LResult := LMatrix.Rotate(TIdVec3.Create(1, 1, 1));
  CheckNear(1, LResult.X, EPSILON);
  CheckNear(3, LResult.Z, EPSILON);
  LResult := LMatrix.Apply(TIdVec4.Create(1, 1, 1, 0.5));
  CheckNear(6, LResult.X, EPSILON);
  CheckNear(12, LResult.Y, EPSILON);
  CheckNear(18, LResult.Z, EPSILON);
end;

procedure TTestMd5Skeleton.DovrebbeConfrontareLeMatriciConUnaTolleranza;
var
  LFirst, LSecond: TMd5JointMat;
begin
  FillChar(LFirst, SizeOf(LFirst), 0);
  LSecond := LFirst;
  LSecond.M[4] := 0.001;
  Assert.IsTrue(LFirst.Compare(LSecond, 0.01));
  Assert.IsFalse(LFirst.Compare(LSecond, 0.0001));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMd5Skeleton);

end.
