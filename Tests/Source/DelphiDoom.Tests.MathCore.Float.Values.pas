{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the floating point math of MathCore - values worked    }
{  out by hand, identities and sizes                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Float.Values;

{$Q-}
{$R-}

interface

uses
  System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Checks of TIdAngles, TIdQuat, TIdCQuat, TIdMat3, TIdRotation, TIdComplex and TIdPolynomial
  ///   against values calculated by hand and identities (a rotation times its inverse, quaternion
  ///   matrix angles round trips). Tolerance 1e-5 unless the test says otherwise.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestFloatValues = class(TObject)
  private
    FOldMask: TArithmeticExceptionMask;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IRecordDovrebberoAvereLaDimensioneDelCpp;
    [Test]
    procedure GliAngoliDovrebberoNormalizzarsiETrasformarsiInVettori;
    [Test]
    procedure GliAngoliDovrebberoOperareComponenteVersoComponente;
    [Test]
    procedure LaMatriceDiGuidaturaDovrebbeRuotareIlVettoreAvanti;
    [Test]
    procedure LaMatriceDovrebbeMoltiplicareEInvertire;
    [Test]
    procedure LaMatriceSingolareNonDovrebbeInvertirsi;
    [Test]
    procedure LaMatriceDovrebbeDareDeterminanteTracciaETrasposta;
    [Test]
    procedure LaMatriceDovrebbeRiconoscereDiagonaleSimmetricaEIdentita;
    [Test]
    procedure LaMatriceDovrebbeOrtonormalizzare;
    [Test]
    procedure LInerziaDovrebbeSeguireIlTeoremaDegliAssiParalleli;
    [Test]
    procedure IlQuaternioneDovrebbeComporreEInvertire;
    [Test]
    procedure IlQuaternioneDovrebbeRuotareUnVettore;
    [Test]
    procedure LeConversioniAngoliMatriceQuaternioneRotazioneDovrebberoTornare;
    [Test]
    procedure LoSlerpDovrebbeDareIlPuntoMedioEGliEstremi;
    [Test]
    procedure IlQuaternioneCompressoDovrebbeRicostruireW;
    [Test]
    procedure LaRotazioneDovrebbeRuotareUnPuntoAttornoAllOrigine;
    [Test]
    procedure LaRotazioneDovrebbeScalareNormalizzareEInvertire;
    [Test]
    procedure IComplessiDovrebberoFareLeOperazioni;
    [Test]
    procedure IlPolinomioDovrebbeValutareDerivareEOperare;
    [Test]
    procedure IlPolinomioDovrebbeTrovareLeRadici;
    [Test]
    procedure IlPolinomioDovrebbeConfrontareESeparareLeCopie;
    [Test]
    procedure LeRappresentazioniTestualiDovrebberoUsareLaPrecisione;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Complex,
  DelphiDoom.MathCore.Float.Conversions, DelphiDoom.MathCore.Float.CQuat,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Polynomial,
  DelphiDoom.MathCore.Float.Quat, DelphiDoom.MathCore.Float.Rotation;

const
  TOLERANCE = 1E-5;

procedure CheckVec(const AExpected, AActual: TIdVec3; const AMessage: string = '');
begin
  Assert.AreEqual(Double(AExpected.X), Double(AActual.X), TOLERANCE, AMessage + ' x');
  Assert.AreEqual(Double(AExpected.Y), Double(AActual.Y), TOLERANCE, AMessage + ' y');
  Assert.AreEqual(Double(AExpected.Z), Double(AActual.Z), TOLERANCE, AMessage + ' z');
end;

procedure CheckMat(const AExpected, AActual: TIdMat3; const AMessage: string = '');
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    CheckVec(AExpected.Rows[LRow], AActual.Rows[LRow], AMessage + ' riga ' + IntToStr(LRow));
end;

procedure CheckQuat(const AExpected, AActual: TIdQuat);
begin
  Assert.AreEqual(Double(AExpected.X), Double(AActual.X), TOLERANCE, 'x');
  Assert.AreEqual(Double(AExpected.Y), Double(AActual.Y), TOLERANCE, 'y');
  Assert.AreEqual(Double(AExpected.Z), Double(AActual.Z), TOLERANCE, 'z');
  Assert.AreEqual(Double(AExpected.W), Double(AActual.W), TOLERANCE, 'w');
end;

{ TTestFloatValues }

procedure TTestFloatValues.Setup;
begin
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
end;

procedure TTestFloatValues.TearDown;
begin
  SetExceptionMask(FOldMask);
end;

procedure TTestFloatValues.IRecordDovrebberoAvereLaDimensioneDelCpp;
begin
  Assert.AreEqual(12, SizeOf(TIdAngles));
  Assert.AreEqual(16, SizeOf(TIdQuat));
  Assert.AreEqual(12, SizeOf(TIdCQuat));
  Assert.AreEqual(36, SizeOf(TIdMat3));
  Assert.AreEqual(8, SizeOf(TIdComplex));
end;

procedure TTestFloatValues.GliAngoliDovrebberoNormalizzarsiETrasformarsiInVettori;
var
  LAngles: TIdAngles;
  LForward, LRight, LUp: TIdVec3;
begin
  LAngles := TIdAngles.Create(-90, 450, 540);
  LAngles.Normalize360;
  Assert.AreEqual(Double(270), Double(LAngles.Pitch), TOLERANCE);
  Assert.AreEqual(Double(90), Double(LAngles.Yaw), TOLERANCE);
  Assert.AreEqual(Double(180), Double(LAngles.Roll), TOLERANCE);
  LAngles := TIdAngles.Create(270, 90, 180);
  LAngles.Normalize180;
  Assert.AreEqual(Double(-90), Double(LAngles.Pitch), TOLERANCE);
  Assert.AreEqual(Double(90), Double(LAngles.Yaw), TOLERANCE);
  Assert.AreEqual(Double(180), Double(LAngles.Roll), TOLERANCE);
  // yaw 90: forward is +y, right is +x (idTech 4: x forward, y left, z up)
  TIdAngles.Create(0, 90, 0).ToVectors(LForward, LRight, LUp);
  CheckVec(TIdVec3.Create(0, 1, 0), LForward, 'avanti');
  CheckVec(TIdVec3.Create(1, 0, 0), LRight, 'destra');
  CheckVec(TIdVec3.Create(0, 0, 1), LUp, 'alto');
  CheckVec(TIdVec3.Create(0, 0, -1), TIdAngles.Create(90, 0, 0).ToForward, 'pitch 90');
end;

procedure TTestFloatValues.GliAngoliDovrebberoOperareComponenteVersoComponente;
var
  LAngles, LOther: TIdAngles;
begin
  LAngles := TIdAngles.Create(10, 20, 30);
  LOther := TIdAngles.Create(1, 2, 3);
  Assert.IsTrue((LAngles + LOther) = TIdAngles.Create(11, 22, 33));
  Assert.IsTrue((LAngles - LOther) = TIdAngles.Create(9, 18, 27));
  Assert.IsTrue((-LAngles) = TIdAngles.Create(-10, -20, -30));
  Assert.IsTrue((LAngles * 2) = TIdAngles.Create(20, 40, 60));
  Assert.IsTrue((2 * LAngles) = TIdAngles.Create(20, 40, 60));
  Assert.IsTrue((LAngles / 2) = TIdAngles.Create(5, 10, 15));
  Assert.IsTrue(LAngles <> LOther);
  Assert.IsTrue(LAngles.Compare(TIdAngles.Create(10.5, 20, 30), 0.6));
  Assert.IsFalse(LAngles.Compare(TIdAngles.Create(10.5, 20, 30), 0.4));
  Assert.IsFalse(LAngles.Compare(TIdAngles.Create(10, 21, 30), 0.4));
  Assert.IsFalse(LAngles.Compare(TIdAngles.Create(10, 20, 31), 0.4));
  LAngles[2] := 99;
  Assert.AreEqual(Double(99), Double(LAngles.Roll));
  LAngles.Clamp(TIdAngles.Create(0, 0, 0), TIdAngles.Create(5, 50, 50));
  Assert.IsTrue(LAngles = TIdAngles.Create(5, 20, 50));
  LAngles.Clamp(TIdAngles.Create(6, 30, 0), TIdAngles.Create(9, 40, 60));
  Assert.IsTrue(LAngles = TIdAngles.Create(6, 30, 50));
  LAngles.Zero;
  Assert.IsTrue(LAngles = TIdAngles.Create(0, 0, 0));
  Assert.IsTrue(TIdAngles.FromVec3(TIdVec3.Create(1, 2, 3)) = TIdAngles.Create(1, 2, 3));
  Assert.AreEqual(3, LAngles.GetDimension);
end;

procedure TTestFloatValues.LaMatriceDiGuidaturaDovrebbeRuotareIlVettoreAvanti;
var
  LMatrix: TIdMat3;
begin
  LMatrix := TIdRotationConversions.AnglesToMat(TIdAngles.Create(0, 90, 0));
  // M * v takes the rows as the columns: the first row is where the x axis goes
  CheckVec(TIdVec3.Create(0, 1, 0), LMatrix * TIdVec3.Create(1, 0, 0), 'x');
  CheckVec(TIdVec3.Create(-1, 0, 0), LMatrix * TIdVec3.Create(0, 1, 0), 'y');
  CheckVec(TIdVec3.Create(0, 1, 0), TIdVec3.Create(1, 0, 0) * LMatrix, 'v * M come M * v');
  CheckVec(TIdVec3.Create(1, 0, 0), LMatrix.Rows[1] * -1.0, 'riga');
end;

procedure TTestFloatValues.LaMatriceDovrebbeMoltiplicareEInvertire;
var
  LMatrix, LInverse, LProduct: TIdMat3;
begin
  LMatrix := TIdMat3.Create(2, 0, 1, 1, 3, 0, 0, 1, 4);
  LInverse := LMatrix.Inverse;
  LProduct := LMatrix * LInverse;
  CheckMat(TIdMat3.Identity, LProduct, 'm * inversa');
  CheckMat(LMatrix, LInverse.Inverse, 'inversa dell inversa');
  LProduct := LMatrix.InverseFast;
  CheckMat(LInverse, LProduct, 'inversa veloce');
  // a rotation: the inverse is the transpose
  LMatrix := TIdRotationConversions.AnglesToMat(TIdAngles.Create(30, 40, 50));
  CheckMat(LMatrix.Transpose, LMatrix.Inverse, 'rotazione');
  CheckMat(TIdMat3.Identity, LMatrix.TransposeMultiply(LMatrix), 'trasposta per la matrice');
  CheckMat(TIdMat3.Create(2, 4, 6, 8, 10, 12, 14, 16, 18),
    TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9) * 2.0, 'per scalare');
  CheckMat(TIdMat3.Create(2, 4, 6, 8, 10, 12, 14, 16, 18),
    2.0 * TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9), 'scalare per');
  CheckMat(TIdMat3.Create(-1, -2, -3, -4, -5, -6, -7, -8, -9),
    -TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9), 'negata');
  CheckMat(TIdMat3.Create(2, 4, 6, 8, 10, 12, 14, 16, 18),
    TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9) + TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9), 'somma');
  CheckMat(TIdMat3.Create(0, 0, 0, 0, 0, 0, 0, 0, 0),
    TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9) - TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9), 'differenza');
end;

procedure TTestFloatValues.LaMatriceSingolareNonDovrebbeInvertirsi;
var
  LMatrix: TIdMat3;
begin
  LMatrix := TIdMat3.Create(1, 2, 3, 2, 4, 6, 0, 0, 1);
  Assert.IsFalse(LMatrix.InverseSelf);
  // unchanged
  Assert.IsTrue(LMatrix = TIdMat3.Create(1, 2, 3, 2, 4, 6, 0, 0, 1));
  Assert.IsFalse(LMatrix.InverseFastSelf);
end;

procedure TTestFloatValues.LaMatriceDovrebbeDareDeterminanteTracciaETrasposta;
var
  LMatrix: TIdMat3;
begin
  LMatrix := TIdMat3.Create(2, 0, 1, 1, 3, 0, 0, 1, 4);
  // 2 * (3*4 - 0) - 0 + 1 * (1*1 - 0) = 25
  Assert.AreEqual(Double(25), Double(LMatrix.Determinant), TOLERANCE);
  Assert.AreEqual(Double(9), Double(LMatrix.Trace), TOLERANCE);
  CheckMat(TIdMat3.Create(2, 1, 0, 0, 3, 1, 1, 0, 4), LMatrix.Transpose);
  LMatrix.TransposeSelf;
  CheckMat(TIdMat3.Create(2, 1, 0, 0, 3, 1, 1, 0, 4), LMatrix);
  CheckMat(TIdMat3.Create(0, -3, 2, 3, 0, -1, -2, 1, 0), TIdMat3.SkewSymmetric(TIdVec3.Create(1, 2, 3)));
  Assert.AreEqual(9, LMatrix.GetDimension);
end;

procedure TTestFloatValues.LaMatriceDovrebbeRiconoscereDiagonaleSimmetricaEIdentita;
var
  LMatrix: TIdMat3;
  LDestination: TIdVec3;
begin
  Assert.IsTrue(TIdMat3.Identity.IsIdentity);
  Assert.IsFalse(TIdMat3.Identity.IsRotated);
  Assert.IsTrue(TIdMat3.Create(2, 0, 0, 0, 3, 0, 0, 0, 4).IsDiagonal);
  Assert.IsFalse(TIdMat3.Create(2, 1, 0, 0, 3, 0, 0, 0, 4).IsDiagonal);
  Assert.IsTrue(TIdMat3.Create(1, 2, 3, 2, 5, 6, 3, 6, 9).IsSymmetric);
  Assert.IsFalse(TIdMat3.Create(1, 2, 3, 0, 5, 6, 3, 6, 9).IsSymmetric);
  Assert.IsFalse(TIdMat3.Create(1, 2, 3, 2, 5, 6, 0, 6, 9).IsSymmetric);
  Assert.IsFalse(TIdMat3.Create(1, 2, 3, 2, 5, 6, 3, 0, 9).IsSymmetric);
  LMatrix := TIdMat3.Create(0.9999995, 1E-7, 0, 0, 1, 0, 0, 0, 1);
  Assert.IsTrue(LMatrix.IsIdentity);
  Assert.IsTrue(LMatrix.IsRotated);
  LMatrix := TIdMat3.Create(1, 0, 0, 0, 1, 0, 0, 0, 1E-40);
  Assert.IsTrue(LMatrix.FixDenormals);
  // the exact zeros count as denormals too (|x| < 1e-30), as in the original
  Assert.IsFalse(TIdMat3.Create(1, 1, 1, 1, 1, 1, 1, 1, 1).FixDenormals);
  // an almost axial row (two exact zeros) is made exact
  LMatrix := TIdMat3.Create(0.9999999, 0, 0, 0, 1, 0, 0, 0, 1);
  Assert.IsTrue(LMatrix.FixDegeneracies);
  Assert.IsTrue(LMatrix.Rows[0].X = 1.0);
  LMatrix.Zero;
  Assert.IsTrue(LMatrix = TIdMat3.Create(0, 0, 0, 0, 0, 0, 0, 0, 0));
  LMatrix.SetIdentity;
  Assert.IsTrue(LMatrix.IsIdentity);
  LMatrix := TIdMat3.Create(1, 2, 3, 4, 5, 6, 7, 8, 9);
  LMatrix.ProjectVector(TIdVec3.Create(1, 0, 0), LDestination);
  CheckVec(TIdVec3.Create(1, 4, 7), LDestination, 'proietta');
  LMatrix.UnprojectVector(TIdVec3.Create(1, 0, 0), LDestination);
  CheckVec(TIdVec3.Create(1, 2, 3), LDestination, 'proietta all indietro');
end;

procedure TTestFloatValues.LaMatriceDovrebbeOrtonormalizzare;
var
  LMatrix, LOrthonormal: TIdMat3;
begin
  LMatrix := TIdMat3.Create(3, 0.1, 0, 0.2, 2, 0, 0, 0, 5);
  LOrthonormal := LMatrix.OrthoNormalize;
  CheckMat(TIdMat3.Identity, LOrthonormal.TransposeMultiply(LOrthonormal), 'ortonormale');
  LMatrix.OrthoNormalizeSelf;
  CheckMat(LOrthonormal, LMatrix, 'sul posto');
end;

procedure TTestFloatValues.LInerziaDovrebbeSeguireIlTeoremaDegliAssiParalleli;
var
  LMatrix, LResult: TIdMat3;
begin
  LMatrix.Zero;
  // a mass of 2 whose center moves from the origin to (0, 3, 0): the original gives the change
  // of the inertia tensor, mass * (|c|^2 - |c'|^2) on the axes perpendicular to the move
  LResult := LMatrix.InertiaTranslate(2, TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 3, 0));
  Assert.AreEqual(Double(-18), Double(LResult.Rows[0].X), TOLERANCE);
  Assert.AreEqual(Double(0), Double(LResult.Rows[1].Y), TOLERANCE);
  Assert.AreEqual(Double(-18), Double(LResult.Rows[2].Z), TOLERANCE);
  LMatrix.InertiaTranslateSelf(2, TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 3, 0));
  CheckMat(LResult, LMatrix, 'sul posto');
  // rotating by the identity changes nothing
  LResult := LMatrix.InertiaRotate(TIdMat3.Identity);
  CheckMat(LMatrix, LResult, 'rotazione identita');
  LMatrix.InertiaRotateSelf(TIdMat3.Identity);
  CheckMat(LResult, LMatrix, 'rotazione identita sul posto');
end;

procedure TTestFloatValues.IlQuaternioneDovrebbeComporreEInvertire;
var
  LQuat, LOther, LProduct: TIdQuat;
begin
  LQuat := TIdRotationConversions.AnglesToQuat(TIdAngles.Create(10, 20, 30));
  LProduct := LQuat * LQuat.Inverse;
  CheckQuat(TIdQuat.Create(0, 0, 0, 1), LProduct);
  // i * j = k
  LQuat := TIdQuat.Create(1, 0, 0, 0);
  LOther := TIdQuat.Create(0, 1, 0, 0);
  CheckQuat(TIdQuat.Create(0, 0, 1, 0), LQuat * LOther);
  CheckQuat(TIdQuat.Create(1, 1, 0, 0), LQuat + LOther);
  CheckQuat(TIdQuat.Create(1, -1, 0, 0), LQuat - LOther);
  CheckQuat(TIdQuat.Create(2, 0, 0, 0), LQuat * 2.0);
  CheckQuat(TIdQuat.Create(2, 0, 0, 0), 2.0 * LQuat);
  CheckQuat(TIdQuat.Create(-1, 0, 0, 0), -LQuat);
  LQuat := TIdQuat.Create(0, 0, 3, 4);
  Assert.AreEqual(Double(5), Double(LQuat.Length), TOLERANCE);
  LQuat.Normalize;
  CheckQuat(TIdQuat.Create(0, 0, 0.6, 0.8), LQuat);
  LQuat := TIdQuat.Create(0, 0, 0, 0);
  LQuat.Normalize;
  CheckQuat(TIdQuat.Create(0, 0, 0, 0), LQuat);
  Assert.AreEqual(Double(0.8), Double(TIdQuat.Create(0, 0, 0.6, 0).CalcW), TOLERANCE);
  Assert.IsTrue(TIdQuat.Create(1, 2, 3, 4).Compare(TIdQuat.Create(1, 2, 3, 4.5), 0.6));
  Assert.IsFalse(TIdQuat.Create(1, 2, 3, 4).Compare(TIdQuat.Create(1, 2, 3, 4.5), 0.4));
  Assert.IsFalse(TIdQuat.Create(1, 2, 3, 4).Compare(TIdQuat.Create(1, 2, 3.5, 4), 0.4));
  Assert.IsFalse(TIdQuat.Create(1, 2, 3, 4).Compare(TIdQuat.Create(1, 2.5, 3, 4), 0.4));
  Assert.IsFalse(TIdQuat.Create(1, 2, 3, 4).Compare(TIdQuat.Create(1.5, 2, 3, 4), 0.4));
  Assert.IsTrue(TIdQuat.Create(1, 2, 3, 4) <> TIdQuat.Create(1, 2, 3, 5));
  Assert.AreEqual(4, LQuat.GetDimension);
  LQuat[3] := 7;
  Assert.AreEqual(Double(7), Double(LQuat.W));
end;

procedure TTestFloatValues.IlQuaternioneDovrebbeRuotareUnVettore;
var
  LQuat: TIdQuat;
begin
  // 90 degrees about z: the sandwich of idQuat::operator*( idVec3 ) turns x into y
  LQuat := TIdRotationConversions.AnglesToQuat(TIdAngles.Create(0, 90, 0));
  CheckVec(TIdVec3.Create(0, 1, 0), LQuat * TIdVec3.Create(1, 0, 0), 'x in y');
  CheckVec(TIdVec3.Create(-1, 0, 0), LQuat * TIdVec3.Create(0, 1, 0), 'y in -x');
  CheckVec(TIdVec3.Create(0, 0, 1), LQuat * TIdVec3.Create(0, 0, 1), 'z resta');
  // the same as the matrix of the quaternion
  CheckVec(TIdRotationConversions.QuatToMat(LQuat) * TIdVec3.Create(1, 2, 3), LQuat * TIdVec3.Create(1, 2, 3),
    'come la matrice');
end;

procedure TTestFloatValues.LeConversioniAngoliMatriceQuaternioneRotazioneDovrebberoTornare;
var
  LAngles, LBack: TIdAngles;
  LMatrix: TIdMat3;
  LQuat: TIdQuat;
  LRotation: TIdRotation;
  LCQuat: TIdCQuat;
begin
  LAngles := TIdAngles.Create(20, 40, 60);
  LMatrix := TIdRotationConversions.AnglesToMat(LAngles);
  LBack := TIdRotationConversions.MatToAngles(LMatrix);
  Assert.IsTrue(LAngles.Compare(LBack, 1E-3), 'angoli -> matrice -> angoli');
  LQuat := TIdRotationConversions.AnglesToQuat(LAngles);
  CheckMat(LMatrix, TIdRotationConversions.QuatToMat(LQuat), 'angoli -> quaternione -> matrice');
  CheckQuat(LQuat, TIdRotationConversions.MatToQuat(LMatrix));
  Assert.IsTrue(LAngles.Compare(TIdRotationConversions.QuatToAngles(LQuat), 1E-3), 'quaternione -> angoli');
  LRotation := TIdRotationConversions.AnglesToRotation(LAngles);
  CheckMat(LMatrix, LRotation.ToMat3, 'rotazione -> matrice');
  CheckQuat(LQuat, LRotation.ToQuat);
  Assert.IsTrue(LAngles.Compare(TIdRotationConversions.RotationToAngles(LRotation), 1E-3), 'rotazione -> angoli');
  LRotation := TIdRotationConversions.MatToRotation(LMatrix);
  Assert.IsTrue(LRotation.AxisValid, 'la matrice resta nella cache');
  CheckMat(LMatrix, LRotation.ToMat3);
  CheckQuat(LQuat, TIdRotationConversions.QuatToRotation(LQuat).ToQuat);
  LCQuat := TIdRotationConversions.MatToCQuat(LMatrix);
  CheckQuat(LQuat, LCQuat.ToQuat);
  LCQuat := TIdRotationConversions.QuatToCQuat(TIdQuat.Create(0.5, 0.5, 0.5, -0.5));
  Assert.AreEqual(Double(-0.5), Double(LCQuat.X), TOLERANCE, 'w negativo: cambia il segno');
  Assert.IsTrue(TIdRotationConversions.CQuatToAngles(LCQuat).Compare(
    TIdRotationConversions.QuatToAngles(LCQuat.ToQuat), 1E-4));
  CheckMat(TIdRotationConversions.CQuatToMat(LCQuat), TIdRotationConversions.QuatToMat(LCQuat.ToQuat));
  Assert.AreEqual(Double(TIdRotationConversions.CQuatToRotation(LCQuat).Angle),
    Double(TIdRotationConversions.QuatToRotation(LCQuat.ToQuat).Angle), TOLERANCE);
  // the velocity of a rotation of 90 degrees about z is pi / 2 on z
  // idAngles::ToRotation turns a positive yaw about -z
  CheckVec(TIdVec3.Create(0, 0, -Pi / 2),
    TIdRotationConversions.AnglesToAngularVelocity(TIdAngles.Create(0, 90, 0)), 'velocita angolare');
  CheckVec(TIdVec3.Create(0, 0, -Pi / 2),
    TIdRotationConversions.MatToAngularVelocity(TIdRotationConversions.AnglesToMat(TIdAngles.Create(0, 90, 0))),
    'velocita angolare dalla matrice');
  // idQuat::ToAngularVelocity scales by acos( w ), the half angle
  CheckVec(TIdVec3.Create(0, 0, -Pi / 4),
    TIdRotationConversions.AnglesToQuat(TIdAngles.Create(0, 90, 0)).ToAngularVelocity, 'velocita angolare del quaternione');
  // gimbal lock: pitch 90, the roll is lost
  LBack := TIdRotationConversions.MatToAngles(TIdRotationConversions.AnglesToMat(TIdAngles.Create(90, 30, 0)));
  Assert.AreEqual(Double(90), Double(LBack.Pitch), 1E-2);
  // the special cases of idAngles::ToRotation
  Assert.AreEqual(Double(30), Double(TIdRotationConversions.AnglesToRotation(TIdAngles.Create(0, 0, 30)).Angle));
  Assert.AreEqual(Double(30), Double(TIdRotationConversions.AnglesToRotation(TIdAngles.Create(0, 30, 0)).Angle));
  Assert.AreEqual(Double(30), Double(TIdRotationConversions.AnglesToRotation(TIdAngles.Create(30, 0, 0)).Angle));
  // a null rotation
  LRotation := TIdRotationConversions.QuatToRotation(TIdQuat.Create(0, 0, 0, 1));
  Assert.AreEqual(Double(0), Double(LRotation.Angle));
  CheckVec(TIdVec3.Create(0, 0, 1), LRotation.Vector);
  LRotation := TIdRotationConversions.MatToRotation(TIdMat3.Identity);
  Assert.AreEqual(Double(0), Double(LRotation.Angle));
  // trace <= 0: a half turn about x
  LRotation := TIdRotationConversions.MatToRotation(TIdMat3.Create(1, 0, 0, 0, -1, 0, 0, 0, -1));
  Assert.AreEqual(Double(180), Double(LRotation.Angle), 1E-3);
  CheckVec(TIdVec3.Create(1, 0, 0), LRotation.Vector);
end;

procedure TTestFloatValues.LoSlerpDovrebbeDareIlPuntoMedioEGliEstremi;
var
  LFrom, LTo, LResult: TIdQuat;
  LHalf: Double;
begin
  LFrom := TIdQuat.Create(0, 0, 0, 1);
  LTo := TIdRotationConversions.AnglesToQuat(TIdAngles.Create(0, 90, 0));
  LResult.Slerp(LFrom, LTo, 0.0);
  CheckQuat(LFrom, LResult);
  LResult.Slerp(LFrom, LTo, 1.0);
  CheckQuat(LTo, LResult);
  LResult.Slerp(LFrom, LTo, 0.5);
  // the quaternion of a positive yaw has a negative z
  LHalf := -Sin(DegToRad(22.5));
  Assert.AreEqual(LHalf, Double(LResult.Z), 1E-3, 'punto medio z');
  Assert.AreEqual(Cos(DegToRad(22.5)), Double(LResult.W), 1E-3, 'punto medio w');
  // the same quaternions: no interpolation
  LResult.Slerp(LTo, LTo, 0.5);
  CheckQuat(LTo, LResult);
  // opposite quaternion: the shortest way
  LResult.Slerp(LFrom, -LTo, 0.5);
  Assert.AreEqual(LHalf, Double(LResult.Z), 1E-3, 'via piu corta');
  // almost the same: linear
  LResult.Slerp(LFrom, TIdQuat.Create(0, 0, 0.0000001, 1), 0.5);
  Assert.AreEqual(Double(1), Double(LResult.W), 1E-5);
end;

procedure TTestFloatValues.IlQuaternioneCompressoDovrebbeRicostruireW;
var
  LCQuat: TIdCQuat;
begin
  LCQuat := TIdCQuat.Create(0, 0, 0.6);
  CheckQuat(TIdQuat.Create(0, 0, 0.6, 0.8), LCQuat.ToQuat);
  // more than unit length: the absolute value avoids a NaN
  Assert.AreEqual(Double(0), Double(TIdCQuat.Create(0, 0, 1.0000001).ToQuat.W), 1E-3);
  Assert.IsTrue(LCQuat = TIdCQuat.Create(0, 0, 0.6));
  Assert.IsTrue(LCQuat <> TIdCQuat.Create(0, 0, 0.7));
  Assert.IsTrue(LCQuat.Compare(TIdCQuat.Create(0.1, 0, 0.6), 0.2));
  Assert.IsFalse(LCQuat.Compare(TIdCQuat.Create(0.3, 0, 0.6), 0.2));
  Assert.IsFalse(LCQuat.Compare(TIdCQuat.Create(0, 0.3, 0.6), 0.2));
  Assert.IsFalse(LCQuat.Compare(TIdCQuat.Create(0, 0, 0.9), 0.2));
  LCQuat[1] := 0.25;
  Assert.AreEqual(Double(0.25), Double(LCQuat.Y));
  Assert.AreEqual(3, LCQuat.GetDimension);
  LCQuat.SetValues(1, 2, 3);
  Assert.AreEqual(Double(3), Double(LCQuat.Z));
end;

procedure TTestFloatValues.LaRotazioneDovrebbeRuotareUnPuntoAttornoAllOrigine;
var
  LRotation: TIdRotation;
  LPoint: TIdVec3;
begin
  // 90 degrees about z through (1, 0, 0): the point (2, 0, 0) goes to (1, -1, 0) (the matrix of the
  // rotation is stored column-major, as the original says)
  LRotation := TIdRotation.Create(TIdVec3.Create(1, 0, 0), TIdVec3.Create(0, 0, 1), 90);
  CheckVec(TIdVec3.Create(1, -1, 0), LRotation * TIdVec3.Create(2, 0, 0), 'operatore');
  Assert.IsFalse(LRotation.AxisValid, 'l operatore non scrive la cache');
  CheckVec(TIdVec3.Create(1, -1, 0), LRotation.Rotate(TIdVec3.Create(2, 0, 0)), 'Rotate');
  Assert.IsTrue(LRotation.AxisValid);
  LPoint := TIdVec3.Create(2, 0, 0);
  LRotation.RotatePoint(LPoint);
  CheckVec(TIdVec3.Create(1, -1, 0), LPoint, 'RotatePoint');
  LRotation.ReCalculateMatrix;
  Assert.IsTrue(LRotation.AxisValid);
  LRotation.SetOrigin(TIdVec3.Create(0, 0, 0));
  CheckVec(TIdVec3.Create(0, -2, 0), LRotation.Rotate(TIdVec3.Create(2, 0, 0)), 'origine nuova');
  CheckVec(TIdVec3.Create(0, 0, Pi / 2), LRotation.ToAngularVelocity, 'velocita angolare');
end;

procedure TTestFloatValues.LaRotazioneDovrebbeScalareNormalizzareEInvertire;
var
  LRotation, LOther: TIdRotation;
begin
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 90);
  LOther := LRotation * 2.0;
  Assert.AreEqual(Double(180), Double(LOther.Angle));
  LOther := 0.5 * LRotation;
  Assert.AreEqual(Double(45), Double(LOther.Angle));
  LOther := LRotation / 3.0;
  Assert.AreEqual(Double(30), Double(LOther.Angle), TOLERANCE);
  LOther := -LRotation;
  Assert.AreEqual(Double(-90), Double(LOther.Angle));
  LOther.SetAngle(270);
  LOther.Normalize180;
  Assert.AreEqual(Double(-90), Double(LOther.Angle), TOLERANCE);
  LOther.SetAngle(-200);
  LOther.Normalize180;
  Assert.AreEqual(Double(160), Double(LOther.Angle), TOLERANCE);
  LOther.SetAngle(-90);
  LOther.Normalize360;
  Assert.AreEqual(Double(270), Double(LOther.Angle), TOLERANCE);
  LOther.SetAngle(720.5);
  LOther.Normalize360;
  Assert.AreEqual(Double(0.5), Double(LOther.Angle), TOLERANCE);
  LRotation.Scale(0.5);
  Assert.AreEqual(Double(45), Double(LRotation.Angle));
  LRotation.SetVector(1, 0, 0);
  CheckVec(TIdVec3.Create(1, 0, 0), LRotation.Vector);
  LRotation.SetVector(TIdVec3.Create(0, 1, 0));
  CheckVec(TIdVec3.Create(0, 1, 0), LRotation.Vector);
  LRotation.SetValues(TIdVec3.Create(1, 1, 1), TIdVec3.Create(0, 0, 1), 10);
  CheckVec(TIdVec3.Create(1, 1, 1), LRotation.Origin);
end;

procedure TTestFloatValues.IComplessiDovrebberoFareLeOperazioni;
var
  LA, LB: TIdComplex;
begin
  LA := TIdComplex.Create(1, 2);
  LB := TIdComplex.Create(3, 4);
  Assert.IsTrue((LA * LB) = TIdComplex.Create(-5, 10));
  Assert.IsTrue((LA + LB) = TIdComplex.Create(4, 6));
  Assert.IsTrue((LA - LB) = TIdComplex.Create(-2, -2));
  Assert.IsTrue((-LA) = TIdComplex.Create(-1, -2));
  // (1 + 2i) / (3 + 4i) = (11 + 2i) / 25
  Assert.IsTrue((LA / LB).Compare(TIdComplex.Create(0.44, 0.08), 1E-6), 'divisione');
  // the other branch of the division, |im| > |re|
  Assert.IsTrue((LB / TIdComplex.Create(1, 3)).Compare(TIdComplex.Create(1.5, -0.5), 1E-6), 'divisione 2');
  Assert.IsTrue((LA * 2.0).Compare(TIdComplex.Create(2, 4), 1E-6));
  Assert.IsTrue((2.0 * LA).Compare(TIdComplex.Create(2, 4), 1E-6));
  Assert.IsTrue((LA / 2.0).Compare(TIdComplex.Create(0.5, 1), 1E-6));
  Assert.IsTrue((LA + 1.0).Compare(TIdComplex.Create(2, 2), 1E-6));
  Assert.IsTrue((1.0 + LA).Compare(TIdComplex.Create(2, 2), 1E-6));
  Assert.IsTrue((LA - 1.0).Compare(TIdComplex.Create(0, 2), 1E-6));
  Assert.IsTrue((1.0 - LA).Compare(TIdComplex.Create(0, -2), 1E-6));
  Assert.IsTrue((1.0 / LB).Compare(TIdComplex.Create(0.12, -0.16), 1E-6));
  Assert.IsTrue((1.0 / TIdComplex.Create(1, 3)).Compare(TIdComplex.Create(0.1, -0.3), 1E-6));
  Assert.IsTrue(LB.Reciprocal.Compare(TIdComplex.Create(0.12, -0.16), 1E-6));
  Assert.IsTrue(TIdComplex.Create(1, 3).Reciprocal.Compare(TIdComplex.Create(0.1, -0.3), 1E-6));
  Assert.AreEqual(Double(5), Double(LB.Abs), 1E-5);
  Assert.AreEqual(Double(5), Double(TIdComplex.Create(4, 3).Abs), 1E-5);
  Assert.AreEqual(Double(3), Double(TIdComplex.Create(0, 3).Abs), 1E-5);
  Assert.AreEqual(Double(4), Double(TIdComplex.Create(4, 0).Abs), 1E-5);
  Assert.IsTrue(TIdComplex.Create(-4, 0).Sqrt.Compare(TIdComplex.Create(0, 2), 1E-5), 'radice di -4');
  Assert.IsTrue(TIdComplex.Create(4, 0).Sqrt.Compare(TIdComplex.Create(2, 0), 1E-5), 'radice di 4');
  Assert.IsTrue(TIdComplex.Create(-3, -4).Sqrt.Compare(TIdComplex.Create(1, -2), 1E-5), 'radice di -3 - 4i');
  Assert.IsTrue(TIdComplex.Create(0, 2).Sqrt.Compare(TIdComplex.Create(1, 1), 1E-5), 'radice di 2i');
  Assert.IsTrue(TIdComplex.Create(0, 0).Sqrt = TIdComplex.Create(0, 0));
  Assert.IsTrue(LA <> LB);
  Assert.AreEqual(2, LA.GetDimension);
  LA.Zero;
  Assert.IsTrue(LA = TIdComplex.Create(0, 0));
  Assert.IsFalse(LB.Compare(TIdComplex.Create(3.5, 4), 0.1));
  Assert.IsFalse(LB.Compare(TIdComplex.Create(3, 4.5), 0.1));
end;

procedure TTestFloatValues.IlPolinomioDovrebbeValutareDerivareEOperare;
var
  LPoly, LOther, LResult: TIdPolynomial;
  LValue: TIdComplex;
begin
  // 3x^2 + 2x + 1
  LPoly := TIdPolynomial.Create(3, 2, 1);
  Assert.AreEqual(2, LPoly.Degree);
  Assert.AreEqual(Double(6), Double(LPoly.GetValue(1.0)), TOLERANCE);
  Assert.AreEqual(Double(17), Double(LPoly.GetValue(2.0)), TOLERANCE);
  // at x = i: -3 + 2i + 1 = -2 + 2i
  LValue := LPoly.GetValue(TIdComplex.Create(0, 1));
  Assert.AreEqual(Double(-2), Double(LValue.R), TOLERANCE);
  Assert.AreEqual(Double(2), Double(LValue.I), TOLERANCE);
  LResult := LPoly.GetDerivative;
  Assert.AreEqual(1, LResult.Degree);
  Assert.AreEqual(Double(2), Double(LResult[0]));
  Assert.AreEqual(Double(6), Double(LResult[1]));
  LResult := LPoly.GetAntiDerivative;
  Assert.AreEqual(3, LResult.Degree);
  Assert.AreEqual(Double(0), Double(LResult[0]));
  Assert.AreEqual(Double(1), Double(LResult[1]));
  Assert.AreEqual(Double(1), Double(LResult[2]));
  Assert.AreEqual(Double(1), Double(LResult[3]));
  // sum of different degrees and of the same degree, which can lower the degree
  LOther := TIdPolynomial.Create(2, 1);
  LResult := LPoly + LOther;
  Assert.AreEqual(2, LResult.Degree);
  Assert.AreEqual(Double(2), Double(LResult[0]));
  Assert.AreEqual(Double(4), Double(LResult[1]));
  LResult := LOther + LPoly;
  Assert.AreEqual(Double(4), Double(LResult[1]));
  LResult := LPoly + (-LPoly);
  Assert.AreEqual(0, LResult.Degree);
  LResult := LPoly - LOther;
  Assert.AreEqual(Double(0), Double(LResult[0]));
  Assert.AreEqual(Double(0), Double(LResult[1]));
  LResult := LOther - LPoly;
  Assert.AreEqual(2, LResult.Degree);
  Assert.AreEqual(Double(-3), Double(LResult[2]));
  LResult := LPoly - LPoly;
  Assert.AreEqual(Double(0), Double(LResult[0]));
  LResult := LPoly * 2.0;
  Assert.AreEqual(Double(6), Double(LResult[2]));
  LResult := LPoly / 2.0;
  Assert.AreEqual(Double(1.5), Double(LResult[2]));
  LResult := LPoly * 0.0;
  Assert.AreEqual(0, LResult.Degree);
  LResult := TIdPolynomial.Create(5);
  LResult.Zero(2);
  Assert.AreEqual(2, LResult.GetDimension);
  Assert.AreEqual(Double(0), Double(LResult[2]));
  LResult.Zero;
  Assert.AreEqual(0, LResult.Degree);
  Assert.AreEqual(1, TIdPolynomial.Create(1, 2).Degree);
  Assert.AreEqual(3, TIdPolynomial.Create(1, 2, 3, 4).Degree);
  Assert.AreEqual(4, TIdPolynomial.Create(1, 2, 3, 4, 5).Degree);
  // the derivative of a constant is empty, as in the original (degree -1)
  Assert.AreEqual(-1, TIdPolynomial.Create(0).GetDerivative.Degree);
  Assert.AreEqual(-1, TIdPolynomial.Create(0).GetAntiDerivative.Degree);
end;

procedure TTestFloatValues.IlPolinomioDovrebbeTrovareLeRadici;
var
  LRoots: array[0..7] of Single;
  LComplexRoots: TArray<TIdComplex>;
  LCount, LIndex: Integer;
  LPoly: TIdPolynomial;
begin
  // x^2 - 3x + 2
  LCount := TIdPolynomial.Create(1, -3, 2).GetRoots(LRoots);
  Assert.AreEqual(2, LCount);
  Assert.AreEqual(Double(1), Double(LRoots[0]), TOLERANCE);
  Assert.AreEqual(Double(2), Double(LRoots[1]), TOLERANCE);
  // a double root, no real root, a != 1
  Assert.AreEqual(1, TIdPolynomial.Create(2, 4, 2).GetRoots(LRoots));
  Assert.AreEqual(0, TIdPolynomial.Create(1, 0, 1).GetRoots(LRoots));
  Assert.AreEqual(1, TIdPolynomial.Create(2, -4).GetRoots(LRoots));
  Assert.AreEqual(Double(2), Double(LRoots[0]), TOLERANCE);
  // x^3 - 6x^2 + 11x - 6: three real roots
  LCount := TIdPolynomial.Create(1, -6, 11, -6).GetRoots(LRoots);
  Assert.AreEqual(3, LCount);
  LPoly := TIdPolynomial.Create(1, -6, 11, -6);
  Assert.AreEqual(Double(6), Double(LRoots[0]) + LRoots[1] + LRoots[2], 1E-3, 'la somma delle radici');
  for LIndex := 0 to 2 do
    Assert.AreEqual(Double(0), Double(LPoly.GetValue(LRoots[LIndex])), 1E-3, 'radice ' + IntToStr(LIndex));
  Assert.AreEqual(1, TIdPolynomial.Create(1, 0, 0, 1).GetRoots(LRoots), 'una radice reale');
  Assert.AreEqual(Double(-1), Double(LRoots[0]), TOLERANCE);
  // a triple root: the discriminant is zero or a rounding error from it
  Assert.IsTrue(TIdPolynomial.Create(1, -3, 3, -1).GetRoots(LRoots) in [1, 3], 'radice tripla');
  Assert.AreEqual(Double(1), Double(LRoots[0]), 0.05);
  // x^4 - 5x^2 + 4: -2, -1, 1, 2
  LCount := TIdPolynomial.Create(1, 0, -5, 0, 4).GetRoots(LRoots);
  Assert.AreEqual(4, LCount);
  Assert.AreEqual(Double(-2), Double(Min(Min(LRoots[0], LRoots[1]), Min(LRoots[2], LRoots[3]))), 1E-3);
  Assert.AreEqual(Double(2), Double(Max(Max(LRoots[0], LRoots[1]), Max(LRoots[2], LRoots[3]))), 1E-3);
  Assert.AreEqual(0, TIdPolynomial.Create(1, 0, 0, 0, 1).GetRoots(LRoots), 'x^4 + 1');
  // a degree 5 polynomial with the roots 1..5 goes through the numerical solver
  LPoly := TIdPolynomial.Create(5);
  LPoly[5] := 1;
  LPoly[4] := -15;
  LPoly[3] := 85;
  LPoly[2] := -225;
  LPoly[1] := 274;
  LPoly[0] := -120;
  Assert.AreEqual(5, LPoly.GetRoots(LComplexRoots));
  for LIndex := 0 to 4 do
  begin
    Assert.AreEqual(Double(LIndex + 1), Double(LComplexRoots[LIndex].R), 0.05, 'radice ' + IntToStr(LIndex));
    Assert.AreEqual(Double(0), Double(LComplexRoots[LIndex].I), 0.05);
  end;
  LCount := LPoly.GetRoots(LRoots);
  Assert.IsTrue(LCount >= 1);
  // the complex roots of x^2 + 1 (through the numerical solver of the polynomial class)
  Assert.AreEqual(2, TIdPolynomial.Create(1, 0, 1).GetRoots(LComplexRoots));
  Assert.AreEqual(Double(1), Abs(Double(LComplexRoots[0].I)), 1E-4);
  // a polynomial of degree 0 has no root
  Assert.AreEqual(0, TIdPolynomial.Create(0).GetRoots(LRoots));
end;

procedure TTestFloatValues.IlPolinomioDovrebbeConfrontareESeparareLeCopie;
var
  LPoly, LCopy: TIdPolynomial;
begin
  LPoly := TIdPolynomial.Create(1, 2, 3);
  LCopy := LPoly;
  Assert.IsTrue(LPoly = LCopy);
  LCopy[0] := 9;
  Assert.AreEqual(Double(3), Double(LPoly[0]), 'la copia non cambia l originale');
  Assert.IsTrue(LPoly <> LCopy);
  Assert.IsTrue(LPoly.Compare(TIdPolynomial.Create(1, 2, 3.0000001), 1E-5));
  Assert.IsFalse(LPoly.Compare(TIdPolynomial.Create(1, 2, 3.5), 1E-5));
  Assert.IsFalse(LPoly.Compare(TIdPolynomial.Create(1, 2), 1E-5));
  Assert.IsFalse(LPoly = TIdPolynomial.Create(1, 2));
  Assert.IsFalse(LPoly = TIdPolynomial.Create(1, 2, 4));
end;

procedure TTestFloatValues.LeRappresentazioniTestualiDovrebberoUsareLaPrecisione;
begin
  // idStr::FloatArrayToString drops the trailing zeros
  Assert.AreEqual('1.5 2.25 3', string(TIdAngles.Create(1.5, 2.25, 3).ToString));
  Assert.AreEqual('1 2 3 4', string(TIdQuat.Create(1, 2, 3, 4).ToString(1)));
  Assert.AreEqual('1 0 0 0 1 0 0 0 1', string(TIdMat3.Identity.ToString));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFloatValues);

end.
