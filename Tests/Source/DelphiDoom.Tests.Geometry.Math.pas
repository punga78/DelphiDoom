{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the geometry library - vector, matrix, plane, box and  }
{  Pluecker coordinates                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Math;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('geometry')]
  TTestGeometryMath = class(TObject)
  public
    [Test]
    procedure TestRecordSizesMatchTheCppLayout;
    [Test]
    procedure TestVectorOperators;
    [Test]
    procedure TestCrossProductIsRightHanded;
    [Test]
    procedure TestNormalizeReturnsTheOldLength;
    [Test]
    procedure TestNormalVectorsAreOrthogonal;
    [Test]
    procedure TestFixDegenerateNormalSnapsAxialNormals;
    [Test]
    procedure TestRintIsFloorOfHalfUp;
    [Test]
    procedure TestSignBitMacros;
    [Test]
    procedure TestMatrixTimesVector;
    [Test]
    procedure TestIdentityIsNotRotated;
    [Test]
    procedure TestTransposeOfRotationIsInverse;
    [Test]
    procedure TestPlaneTypes;
    [Test]
    procedure TestPlaneDistanceAndSide;
    [Test]
    procedure TestPlaneFromPoints;
    [Test]
    procedure TestPlaneDistIsMinusD;
    [Test]
    procedure TestPlaneFixDegeneraciesSnapsDistance;
    [Test]
    procedure TestBoundsClearAndAddPoint;
    [Test]
    procedure TestBoundsPlaneSideAndDistance;
    [Test]
    procedure TestBoundsIntersection;
    [Test]
    procedure TestPlueckerSidednessOfCrossingLines;
    [Test]
    procedure TestPlueckerFromRayAndFromLineAgree;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath, DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Pluecker;

const
  EPS = 1e-5;

{ TTestGeometryMath }

procedure TTestGeometryMath.TestRecordSizesMatchTheCppLayout;
begin
  // idVec3 12, idMat3 36, idPlane 16, idBounds 24, idPluecker 24 bytes
  Assert.AreEqual(12, SizeOf(TGeoVec3));
  Assert.AreEqual(36, SizeOf(TGeoMat3));
  Assert.AreEqual(16, SizeOf(TGeoPlane));
  Assert.AreEqual(24, SizeOf(TGeoBounds));
  Assert.AreEqual(24, SizeOf(TGeoPluecker));
end;

procedure TTestGeometryMath.TestVectorOperators;
var
  LA: TGeoVec3;
  LB: TGeoVec3;
  LC: TGeoVec3;
begin
  LA := TGeoVec3.Make(1, 2, 3);
  LB := TGeoVec3.Make(4, 5, 6);
  LC := LA + LB;
  Assert.AreEqual(5.0, LC.X, EPS);
  Assert.AreEqual(7.0, LC.Y, EPS);
  Assert.AreEqual(9.0, LC.Z, EPS);
  LC := LB - LA;
  Assert.AreEqual(3.0, LC.X, EPS);
  LC := -LA;
  Assert.AreEqual(-3.0, LC.Z, EPS);
  LC := LA * 2.0;
  Assert.AreEqual(4.0, LC.Y, EPS);
  LC := 0.5 * LB;
  Assert.AreEqual(2.5, LC.Y, EPS);
  Assert.AreEqual(32.0, LA.Dot(LB), EPS);
  Assert.AreEqual(2.0, LA[1], EPS);
  LA[1] := 9;
  Assert.AreEqual(9.0, LA.Y, EPS);
  Assert.IsTrue(LA.Compare(LA));
  Assert.IsFalse(LA.Compare(LB));
end;

procedure TTestGeometryMath.TestCrossProductIsRightHanded;
var
  LC: TGeoVec3;
begin
  LC := TGeoVec3.Make(1, 0, 0).Cross(TGeoVec3.Make(0, 1, 0));
  Assert.AreEqual(0.0, LC.X, EPS);
  Assert.AreEqual(0.0, LC.Y, EPS);
  Assert.AreEqual(1.0, LC.Z, EPS);
end;

procedure TTestGeometryMath.TestNormalizeReturnsTheOldLength;
var
  LV: TGeoVec3;
  LLength: Single;
begin
  LV := TGeoVec3.Make(3, 4, 12);
  LLength := LV.NormalizeSelf;
  Assert.AreEqual(13.0, LLength, 1e-4);
  Assert.AreEqual(1.0, LV.Length, 1e-5);
  Assert.AreEqual(3.0 / 13.0, LV.X, 1e-5);
end;

procedure TTestGeometryMath.TestNormalVectorsAreOrthogonal;
var
  LNormal: TGeoVec3;
  LLeft: TGeoVec3;
  LDown: TGeoVec3;
begin
  LNormal := TGeoVec3.Make(1, 2, 2);
  LNormal.NormalizeSelf;
  LNormal.NormalVectors(LLeft, LDown);
  Assert.AreEqual(0.0, LNormal.Dot(LLeft), 1e-5);
  Assert.AreEqual(0.0, LNormal.Dot(LDown), 1e-5);
  Assert.AreEqual(0.0, LLeft.Dot(LDown), 1e-5);
  // the vertical case: x and y are zero, left is X and down = left x normal = -Y
  LNormal := TGeoVec3.Make(0, 0, 1);
  LNormal.NormalVectors(LLeft, LDown);
  Assert.AreEqual(1.0, LLeft.X, EPS);
  Assert.AreEqual(-1.0, LDown.Y, EPS);
end;

procedure TTestGeometryMath.TestFixDegenerateNormalSnapsAxialNormals;
var
  LV: TGeoVec3;
begin
  LV := TGeoVec3.Make(1, 1e-9, 0);
  Assert.IsTrue(LV.FixDegenerateNormal);
  Assert.AreEqual(1.0, LV.X, 0.0);
  Assert.AreEqual(0.0, LV.Y, 0.0);
  LV := TGeoVec3.Make(0, 0, -1);
  Assert.IsFalse(LV.FixDegenerateNormal);
  LV := TGeoVec3.Make(0.6, 0.8, 0);
  Assert.IsFalse(LV.FixDegenerateNormal);
  Assert.AreEqual(0.6, LV.X, EPS);
end;

procedure TTestGeometryMath.TestRintIsFloorOfHalfUp;
begin
  // idMath::Rint is floorf(f + 0.5f): 2.5 gives 3 (the C rint would give 2), -2.5 gives -2
  Assert.AreEqual(3.0, TGeoMath.Rint(2.5), 0.0);
  Assert.AreEqual(-2.0, TGeoMath.Rint(-2.5), 0.0);
  Assert.AreEqual(2.0, TGeoMath.Rint(2.4), 0.0);
  Assert.AreEqual(-3.0, TGeoMath.Rint(-2.6), 0.0);
  Assert.AreEqual(0.0, TGeoMath.Rint(0.49), 0.0);
end;

procedure TTestGeometryMath.TestSignBitMacros;
begin
  Assert.AreEqual(1, Integer(TGeoMath.FloatSignBitSet(-0.5)));
  Assert.AreEqual(0, Integer(TGeoMath.FloatSignBitSet(0.5)));
  Assert.AreEqual(1, Integer(TGeoMath.FloatSignBitNotSet(0.0)));
  Assert.AreEqual(0, Integer(TGeoMath.FloatSignBitNotSet(-1.0)));
  Assert.AreEqual(1, Integer(TGeoMath.IntSignBitSet(-3)));
  Assert.AreEqual(0, Integer(TGeoMath.IntSignBitSet(0)));
  Assert.AreEqual(1, Integer(TGeoMath.IntSignBitNotSet(0)));
  // "1 << 32" wraps to "1 << 0" like the x86 shift of the C++ code
  Assert.AreEqual(1, Integer(TGeoMath.BitMask(32)));
  Assert.IsTrue(TGeoMath.BitMask(31) = $80000000);
end;

procedure TTestGeometryMath.TestMatrixTimesVector;
var
  LM: TGeoMat3;
  LV: TGeoVec3;
begin
  // a quarter turn about Z in the idlib convention (v * M): X goes to Y
  LM := TGeoMat3.RotationAboutZ(90);
  LV := TGeoVec3.Make(1, 0, 0) * LM;
  Assert.AreEqual(0.0, LV.X, 1e-6);
  Assert.AreEqual(1.0, LV.Y, 1e-6);
  LV := TGeoVec3.Make(0, 1, 0) * LM;
  Assert.AreEqual(-1.0, LV.X, 1e-6);
  // v * (A * B) = (v * A) * B
  LM := TGeoMat3.RotationAboutZ(30) * TGeoMat3.RotationAboutZ(60);
  LV := TGeoVec3.Make(1, 0, 0) * LM;
  Assert.AreEqual(0.0, LV.X, 1e-6);
  Assert.AreEqual(1.0, LV.Y, 1e-6);
end;

procedure TTestGeometryMath.TestIdentityIsNotRotated;
begin
  Assert.IsFalse(TGeoMat3.Identity.IsRotated);
  Assert.IsTrue(TGeoMat3.RotationAboutZ(1).IsRotated);
end;

procedure TTestGeometryMath.TestTransposeOfRotationIsInverse;
var
  LM: TGeoMat3;
  LV: TGeoVec3;
begin
  LM := TGeoMat3.RotationAboutZ(37);
  LV := TGeoVec3.Make(3, -2, 5) * LM * LM.Transpose;
  Assert.AreEqual(3.0, LV.X, 1e-5);
  Assert.AreEqual(-2.0, LV.Y, 1e-5);
  Assert.AreEqual(5.0, LV.Z, 1e-5);
end;

procedure TTestGeometryMath.TestPlaneTypes;
begin
  Assert.AreEqual(PLANETYPE_X, TGeoPlane.Make(1, 0, 0, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_NEGX, TGeoPlane.Make(-1, 0, 0, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_Y, TGeoPlane.Make(0, 1, 0, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_NEGY, TGeoPlane.Make(0, -1, 0, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_Z, TGeoPlane.Make(0, 0, 1, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_NEGZ, TGeoPlane.Make(0, 0, -1, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_ZEROX, TGeoPlane.Make(0, 0.6, 0.8, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_ZEROY, TGeoPlane.Make(0.6, 0, 0.8, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_ZEROZ, TGeoPlane.Make(0.6, 0.8, 0, 0).PlaneType);
  Assert.AreEqual(PLANETYPE_NONAXIAL, TGeoPlane.Make(0.5, 0.5, 0.7, 0).PlaneType);
end;

procedure TTestGeometryMath.TestPlaneDistanceAndSide;
var
  LPlane: TGeoPlane;
begin
  // the plane z = 10 with the normal up: a*x+b*y+c*z+d with d = -10
  LPlane := TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 10);
  Assert.AreEqual(-10.0, LPlane.D, 0.0);
  Assert.AreEqual(5.0, LPlane.Distance(TGeoVec3.Make(7, 7, 15)), EPS);
  Assert.AreEqual(-3.0, LPlane.Distance(TGeoVec3.Make(0, 0, 7)), EPS);
  Assert.AreEqual(PLANESIDE_FRONT, LPlane.Side(TGeoVec3.Make(0, 0, 11)));
  Assert.AreEqual(PLANESIDE_BACK, LPlane.Side(TGeoVec3.Make(0, 0, 9)));
  Assert.AreEqual(PLANESIDE_ON, LPlane.Side(TGeoVec3.Make(0, 0, 10.05)));
end;

procedure TTestGeometryMath.TestPlaneFromPoints;
var
  LPlane: TGeoPlane;
begin
  // idPlane::FromPoints uses (p1-p2) x (p3-p2): counter clockwise seen from +Z gives +Z up
  Assert.IsTrue(LPlane.FromPoints(TGeoVec3.Make(1, 0, 4), TGeoVec3.Make(0, 0, 4), TGeoVec3.Make(0, 1, 4)));
  Assert.AreEqual(1.0, LPlane.C, EPS);
  Assert.AreEqual(4.0, LPlane.Dist, EPS);
  Assert.IsFalse(LPlane.FromPoints(TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(1, 0, 0), TGeoVec3.Make(2, 0, 0)));
end;

procedure TTestGeometryMath.TestPlaneDistIsMinusD;
var
  LPlane: TGeoPlane;
  LNormal: TGeoVec3;
begin
  LPlane.Zero;
  LPlane.SetNormal(TGeoVec3.Make(1, 0, 0));
  LPlane.SetDist(7);
  Assert.AreEqual(-7.0, LPlane.D, 0.0);
  LNormal := LPlane.Normal;
  Assert.AreEqual(1.0, LNormal.X, 0.0);
  LPlane.FitThroughPoint(TGeoVec3.Make(3, 9, 9));
  Assert.AreEqual(3.0, LPlane.Dist, EPS);
end;

procedure TTestGeometryMath.TestPlaneFixDegeneraciesSnapsDistance;
var
  LPlane: TGeoPlane;
begin
  LPlane := TGeoPlane.Make(1, 0.0000001, 0, -64.00005);
  Assert.IsTrue(LPlane.FixDegeneracies(DEGENERATE_DIST_EPSILON));
  Assert.AreEqual(1.0, LPlane.A, 0.0);
  Assert.AreEqual(-64.0, LPlane.D, 0.0);
  // a normal that is not degenerate leaves the distance alone
  LPlane := TGeoPlane.Make(0.6, 0.8, 0, -64.00005);
  Assert.IsFalse(LPlane.FixDegeneracies(DEGENERATE_DIST_EPSILON));
  Assert.AreEqual(-64.00005, LPlane.D, 1e-4);
end;

procedure TTestGeometryMath.TestBoundsClearAndAddPoint;
var
  LBounds: TGeoBounds;
begin
  LBounds.Clear;
  Assert.IsTrue(LBounds.IsCleared);
  Assert.IsTrue(LBounds.AddPoint(TGeoVec3.Make(1, 2, 3)));
  Assert.IsFalse(LBounds.AddPoint(TGeoVec3.Make(1, 2, 3)));
  Assert.IsTrue(LBounds.AddPoint(TGeoVec3.Make(-4, 5, 0)));
  Assert.AreEqual(-4.0, LBounds.Mins.X, 0.0);
  Assert.AreEqual(5.0, LBounds.Maxs.Y, 0.0);
  Assert.AreEqual(0.0, LBounds.Mins.Z, 0.0);
  Assert.AreEqual(-1.5, LBounds.GetCenter.X, EPS);
  Assert.IsFalse(LBounds.IsCleared);
end;

procedure TTestGeometryMath.TestBoundsPlaneSideAndDistance;
var
  LBounds: TGeoBounds;
  LPlane: TGeoPlane;
begin
  LBounds.Mins := TGeoVec3.Make(-1, -1, -1);
  LBounds.Maxs := TGeoVec3.Make(1, 1, 1);
  LPlane := TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 5);
  Assert.AreEqual(PLANESIDE_BACK, LBounds.PlaneSide(LPlane));
  Assert.AreEqual(-4.0, LBounds.PlaneDistance(LPlane), EPS);
  LPlane := TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), -5);
  Assert.AreEqual(PLANESIDE_FRONT, LBounds.PlaneSide(LPlane));
  Assert.AreEqual(4.0, LBounds.PlaneDistance(LPlane), EPS);
  LPlane := TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0.5);
  Assert.AreEqual(PLANESIDE_CROSS, LBounds.PlaneSide(LPlane));
  Assert.AreEqual(0.0, LBounds.PlaneDistance(LPlane), 0.0);
end;

procedure TTestGeometryMath.TestBoundsIntersection;
var
  LA: TGeoBounds;
  LB: TGeoBounds;
begin
  LA.Mins := TGeoVec3.Make(0, 0, 0);
  LA.Maxs := TGeoVec3.Make(2, 2, 2);
  LB.Mins := TGeoVec3.Make(2, 2, 2);
  LB.Maxs := TGeoVec3.Make(3, 3, 3);
  // touching boxes intersect (idBounds uses strict comparisons for the "no" case)
  Assert.IsTrue(LA.IntersectsBounds(LB));
  LB.Mins := TGeoVec3.Make(2.5, 0, 0);
  Assert.IsFalse(LA.IntersectsBounds(LB));
  Assert.IsTrue(LA.ContainsPoint(TGeoVec3.Make(2, 0, 1)));
  Assert.IsFalse(LA.ContainsPoint(TGeoVec3.Make(2.01, 0, 1)));
end;

procedure TTestGeometryMath.TestPlueckerSidednessOfCrossingLines;
var
  LX: TGeoPluecker;
  LYBefore: TGeoPluecker;
  LYAfter: TGeoPluecker;
begin
  // the X axis and a line parallel to Y that passes above and a line that passes below:
  // the permuted inner products have opposite signs
  LX.FromLine(TGeoVec3.Make(-10, 0, 0), TGeoVec3.Make(10, 0, 0));
  LYBefore.FromLine(TGeoVec3.Make(0, -10, 1), TGeoVec3.Make(0, 10, 1));
  LYAfter.FromLine(TGeoVec3.Make(0, -10, -1), TGeoVec3.Make(0, 10, -1));
  Assert.IsTrue(LX.PermutedInnerProduct(LYBefore) * LX.PermutedInnerProduct(LYAfter) < 0);
  // lines that cross have inner product zero
  LYBefore.FromLine(TGeoVec3.Make(0, -10, 0), TGeoVec3.Make(0, 10, 0));
  Assert.AreEqual(0.0, LX.PermutedInnerProduct(LYBefore), 0.0);
  // the product is symmetric
  LYAfter.FromLine(TGeoVec3.Make(0, -10, -1), TGeoVec3.Make(0, 10, -1));
  Assert.AreEqual(LX.PermutedInnerProduct(LYAfter), LYAfter.PermutedInnerProduct(LX), 0.0);
end;

procedure TTestGeometryMath.TestPlueckerFromRayAndFromLineAgree;
var
  LLine: TGeoPluecker;
  LRay: TGeoPluecker;
  LIndex: Integer;
begin
  // the ray with direction d from point s equals the line from s to s+d
  LLine.FromLine(TGeoVec3.Make(5, 6, 7), TGeoVec3.Make(5, 6, 7) + TGeoVec3.Make(1, 2, 3));
  LRay.FromRay(TGeoVec3.Make(5, 6, 7), TGeoVec3.Make(1, 2, 3));
  for LIndex := 0 to 5 do
    Assert.AreEqual(LLine.P[LIndex], LRay.P[LIndex], 1e-4);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGeometryMath);

end.
