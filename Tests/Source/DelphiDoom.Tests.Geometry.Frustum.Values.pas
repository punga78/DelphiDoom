{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the frustum of id Tech 4 (idFrustum) - values worked   }
{  out by hand                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Frustum.Values;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Frustum;

type
  [TestFixture]
  [Category('geometry')]
  TTestGeometryFrustumValues = class(TObject)
  private
    FOldMask: TArithmeticExceptionMask;
    // near 1, far 10, half size 5 at the far plane, looking along +x from the origin
    function Standard: TGeoFrustum;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlRecordDovrebbeAvereLaDimensioneDelCpp;
    [Test]
    procedure UnFrustumNuovoNonDovrebbeEssereValido;
    [Test]
    procedure SetSizeDovrebbeCalcolareIlReciprocoDellaDistanzaLontana;
    [Test]
    procedure SetPyramidDovrebbeUsareLaDistanzaLontanaPerLeDimensioni;
    [Test]
    procedure IlCentroDovrebbeStareASuMetaDelleDistanze;
    [Test]
    procedure MoveFarDistanceDovrebbeScalareLeDimensioni;
    [Test]
    procedure ExpandDovrebbeConservareIlReciprocoVecchioMaExpandSelfNo;
    [Test]
    procedure IlCullDelPuntoDovrebbeUsareLePianeLaterali;
    [Test]
    procedure GliOtroPuntiDovrebberoEssereQuelliDelleDueFacce;
    [Test]
    procedure ToPlanesDovrebbeDareLePianeVersoLEsterno;
    [Test]
    procedure PlaneSideDovrebbeDistinguereFrontaleEIncrocio;
    [Test]
    procedure LaLineaDovrebbeIncontrareIlFrustumSoloSeLoAttraversa;
    [Test]
    procedure IlRaggioDovrebbeDareLeScaleDiIngressoEUscita;
    [Test]
    procedure IlCullDiBoundsESfereDovrebbeEscludereQuelliLontani;
    [Test]
    procedure LIntersezioneConLaSferaDovrebbeUsareLeRegioniDiVoronoi;
    [Test]
    procedure FromProjectionDellaSferaDovrebbeCreareUnFrustumConIlAngoloGiusto;
    [Test]
    procedure FromProjectionDovrebbeFallireSeLOrigineEVicina;
    [Test]
    procedure ConstrainToBoundsDovrebbeSpostareIlPianoLontano;
    [Test]
    procedure ProjectionBoundsDellaSferaDovrebbeCoprireTuttoIlFrustum;
    [Test]
    procedure ProjectionBoundsDiUnBoundsCheContieneLOrigineDovrebbeCoprireTuttoIlFrustum;
    [Test]
    procedure IlWindingDovrebbeDareIlPianoELeIntersezioni;
  end;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Sphere, DelphiDoom.Geometry.Box, DelphiDoom.Geometry.Winding;

{ TTestGeometryFrustumValues }

procedure TTestGeometryFrustumValues.Setup;
begin
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
end;

procedure TTestGeometryFrustumValues.TearDown;
begin
  SetExceptionMask(FOldMask);
end;

function TTestGeometryFrustumValues.Standard: TGeoFrustum;
begin
  Result := TGeoFrustum.Make;
  Result.SetSize(1, 10, 5, 5);
end;

procedure TTestGeometryFrustumValues.IlRecordDovrebbeAvereLaDimensioneDelCpp;
begin
  // idVec3 12, idMat3 36, five floats 20
  Assert.AreEqual(68, SizeOf(TGeoFrustum));
end;

procedure TTestGeometryFrustumValues.UnFrustumNuovoNonDovrebbeEssereValido;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := TGeoFrustum.Make;
  Assert.IsFalse(LFrustum.IsValid);
  Assert.IsTrue(Standard.IsValid);
end;

procedure TTestGeometryFrustumValues.SetSizeDovrebbeCalcolareIlReciprocoDellaDistanzaLontana;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  Assert.AreEqual(Double(0.1), Double(LFrustum.InvFar), 1E-7);
  Assert.AreEqual(Double(5), Double(LFrustum.DLeft), 0);
  Assert.AreEqual(Double(1), Double(LFrustum.DNear), 0);
end;

procedure TTestGeometryFrustumValues.SetPyramidDovrebbeUsareLaDistanzaLontanaPerLeDimensioni;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := TGeoFrustum.Make;
  LFrustum.SetPyramid(2, 8);
  Assert.AreEqual(Double(8), Double(LFrustum.DLeft), 0);
  Assert.AreEqual(Double(8), Double(LFrustum.DUp), 0);
  Assert.AreEqual(Double(0.125), Double(LFrustum.InvFar), 0);
end;

procedure TTestGeometryFrustumValues.IlCentroDovrebbeStareASuMetaDelleDistanze;
var
  LFrustum: TGeoFrustum;
  LCenter: TGeoVec3;
begin
  LFrustum := Standard;
  LFrustum.SetOrigin(TGeoVec3.Make(1, 2, 3));
  LCenter := LFrustum.GetCenter;
  Assert.AreEqual(Double(5.5), Double(LCenter.X), 1E-6);
  Assert.AreEqual(Double(2), Double(LCenter.Y), 1E-6);
  Assert.AreEqual(Double(3), Double(LCenter.Z), 1E-6);
end;

procedure TTestGeometryFrustumValues.MoveFarDistanceDovrebbeScalareLeDimensioni;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  LFrustum.MoveFarDistance(20);
  Assert.AreEqual(Double(10), Double(LFrustum.DLeft), 1E-6);
  Assert.AreEqual(Double(10), Double(LFrustum.DUp), 1E-6);
  Assert.AreEqual(Double(0.05), Double(LFrustum.InvFar), 1E-7);
  LFrustum.MoveNearDistance(3);
  Assert.AreEqual(Double(3), Double(LFrustum.DNear), 0);
end;

procedure TTestGeometryFrustumValues.ExpandDovrebbeConservareIlReciprocoVecchioMaExpandSelfNo;
var
  LFrustum, LExpanded: TGeoFrustum;
begin
  LFrustum := Standard;
  LExpanded := LFrustum.Expand(1);
  Assert.AreEqual(Double(12), Double(LExpanded.DFar), 1E-6);
  Assert.AreEqual(Double(-1), Double(LExpanded.Origin.X), 1E-6);
  // defect of the original: 1 / old far
  Assert.AreEqual(Double(0.1), Double(LExpanded.InvFar), 1E-7);
  LFrustum.ExpandSelf(1);
  Assert.AreEqual(Double(1) / 12, Double(LFrustum.InvFar), 1E-7);
  // the sizes grow with the far plane
  Assert.AreEqual(Double(6), Double(LFrustum.DLeft), 1E-5);
end;

procedure TTestGeometryFrustumValues.IlCullDelPuntoDovrebbeUsareLePianeLaterali;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  // at x = 5 the half width is 2.5
  Assert.IsFalse(LFrustum.CullPoint(TGeoVec3.Make(5, 2, 0)));
  Assert.IsTrue(LFrustum.CullPoint(TGeoVec3.Make(5, 3, 0)));
  Assert.IsTrue(LFrustum.CullPoint(TGeoVec3.Make(5, 0, -3)));
  Assert.IsTrue(LFrustum.CullPoint(TGeoVec3.Make(0.5, 0, 0)));
  Assert.IsTrue(LFrustum.CullPoint(TGeoVec3.Make(11, 0, 0)));
  Assert.IsTrue(LFrustum.ContainsPoint(TGeoVec3.Make(10, 5, 5)));
end;

procedure TTestGeometryFrustumValues.GliOtroPuntiDovrebberoEssereQuelliDelleDueFacce;
var
  LFrustum: TGeoFrustum;
  LPoints: TGeoFrustumPoints;
begin
  LFrustum := Standard;
  LFrustum.ToPoints(LPoints);
  // near face: half size 5 * 1 / 10
  Assert.AreEqual(Double(1), Double(LPoints[0].X), 1E-6);
  Assert.AreEqual(Double(0.5), Double(Abs(LPoints[0].Y)), 1E-6);
  Assert.AreEqual(Double(0.5), Double(Abs(LPoints[2].Z)), 1E-6);
  Assert.AreEqual(Double(10), Double(LPoints[4].X), 1E-6);
  Assert.AreEqual(Double(5), Double(Abs(LPoints[7].Y)), 1E-6);
  Assert.AreEqual(Double(5), Double(Abs(LPoints[6].Z)), 1E-6);
end;

procedure TTestGeometryFrustumValues.ToPlanesDovrebbeDareLePianeVersoLEsterno;
var
  LFrustum: TGeoFrustum;
  LPlanes: TGeoFrustumPlanes;
  LIndex: Integer;
begin
  LFrustum := Standard;
  LFrustum.ToPlanes(LPlanes);
  // near plane: the point (1, 0, 0) is on it, the origin is in front of it (outside)
  Assert.AreEqual(Double(0), Double(LPlanes[0].Distance(TGeoVec3.Make(1, 0, 0))), 1E-6);
  Assert.IsTrue(LPlanes[0].Distance(TGeoVec3.Origin) > 0);
  Assert.AreEqual(Double(0), Double(LPlanes[1].Distance(TGeoVec3.Make(10, 0, 0))), 1E-6);
  // defect of the original, kept: the points used for the side planes lie in the plane perpendicular
  // to the forward axis, so the four side planes are all the plane x = 0 with the normal along the axis
  for LIndex := 2 to 5 do
  begin
    Assert.AreEqual(Double(1), Double(LPlanes[LIndex].A), 1E-6, 'piano ' + IntToStr(LIndex));
    Assert.AreEqual(Double(0), Double(LPlanes[LIndex].D), 1E-6, 'piano ' + IntToStr(LIndex));
  end;
end;

procedure TTestGeometryFrustumValues.PlaneSideDovrebbeDistinguereFrontaleEIncrocio;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  // plane x = 0: the whole frustum (x from 1 to 10) is in front
  Assert.AreEqual(PLANESIDE_FRONT, LFrustum.PlaneSide(TGeoPlane.Make(1, 0, 0, 0)));
  // plane x = 5: crosses
  Assert.AreEqual(PLANESIDE_CROSS, LFrustum.PlaneSide(TGeoPlane.Make(1, 0, 0, -5)));
  // plane x = 20: behind
  Assert.AreEqual(PLANESIDE_BACK, LFrustum.PlaneSide(TGeoPlane.Make(1, 0, 0, -20)));
  Assert.AreEqual(Double(0), Double(LFrustum.PlaneDistance(TGeoPlane.Make(1, 0, 0, -5))), 0);
  Assert.AreEqual(Double(1), Double(LFrustum.PlaneDistance(TGeoPlane.Make(1, 0, 0, 0))), 1E-6);
end;

procedure TTestGeometryFrustumValues.LaLineaDovrebbeIncontrareIlFrustumSoloSeLoAttraversa;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  Assert.IsTrue(LFrustum.LineIntersection(TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(20, 0, 0)));
  Assert.IsTrue(LFrustum.LineIntersection(TGeoVec3.Make(4, 0, 0), TGeoVec3.Make(6, 0, 0)));
  Assert.IsFalse(LFrustum.LineIntersection(TGeoVec3.Make(0, 100, 0), TGeoVec3.Make(20, 100, 0)));
  Assert.IsFalse(LFrustum.LineIntersection(TGeoVec3.Make(-5, 0, 0), TGeoVec3.Make(0, 0, 0)));
end;

procedure TTestGeometryFrustumValues.IlRaggioDovrebbeDareLeScaleDiIngressoEUscita;
var
  LFrustum: TGeoFrustum;
  LScale1, LScale2: Single;
begin
  LFrustum := Standard;
  Assert.IsTrue(LFrustum.RayIntersection(TGeoVec3.Make(-5, 0, 0), TGeoVec3.Make(1, 0, 0), LScale1, LScale2));
  Assert.AreEqual(Double(6), Double(LScale1), 1E-5);
  Assert.AreEqual(Double(15), Double(LScale2), 1E-5);
  // a ray that misses
  Assert.IsFalse(LFrustum.RayIntersection(TGeoVec3.Make(-5, 100, 0), TGeoVec3.Make(1, 0, 0), LScale1, LScale2));
  // a ray that starts inside: the first scale is negative
  Assert.IsTrue(LFrustum.RayIntersection(TGeoVec3.Make(5, 0, 0), TGeoVec3.Make(1, 0, 0), LScale1, LScale2));
  Assert.IsTrue(LScale1 < 0);
  Assert.AreEqual(Double(5), Double(LScale2), 1E-5);
end;

procedure TTestGeometryFrustumValues.IlCullDiBoundsESfereDovrebbeEscludereQuelliLontani;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  Assert.IsFalse(LFrustum.CullBounds(TGeoBounds.Make(TGeoVec3.Make(4, -1, -1), TGeoVec3.Make(6, 1, 1))));
  Assert.IsTrue(LFrustum.CullBounds(TGeoBounds.Make(TGeoVec3.Make(20, -1, -1), TGeoVec3.Make(22, 1, 1))));
  Assert.IsTrue(LFrustum.CullBounds(TGeoBounds.Make(TGeoVec3.Make(4, 40, -1), TGeoVec3.Make(6, 42, 1))));
  // on the edge of the frustum the sphere is not culled
  Assert.IsFalse(LFrustum.CullSphere(TGeoSphere.Make(TGeoVec3.Make(5, 2.5, 2.5), 1)));
  // defect of the original, kept: the left/right and up/down tests square a signed distance, so a
  // sphere well inside the frustum is "culled"
  Assert.IsTrue(LFrustum.CullSphere(TGeoSphere.Make(TGeoVec3.Make(5, 0, 0), 1)));
  Assert.IsTrue(LFrustum.CullSphere(TGeoSphere.Make(TGeoVec3.Make(-5, 0, 0), 1)));
  Assert.IsTrue(LFrustum.CullSphere(TGeoSphere.Make(TGeoVec3.Make(5, 0, 30), 1)));
  Assert.IsTrue(LFrustum.CullBox(TGeoBox.Make(TGeoVec3.Make(30, 0, 0), TGeoVec3.Make(1, 1, 1),
    TGeoMat3.Identity)));
end;

procedure TTestGeometryFrustumValues.LIntersezioneConLaSferaDovrebbeUsareLeRegioniDiVoronoi;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  // on the edge of the frustum, inside
  Assert.IsTrue(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(5, 2.5, 2.5), 0.5)));
  // the first test is CullSphere: a sphere well inside is rejected by its defect
  Assert.IsFalse(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(5, 0, 0), 0.5)));
  // in front of the near plane, reaching it or not
  Assert.IsTrue(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(0.5, 0.25, 0.25), 0.75)));
  Assert.IsFalse(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(0.5, 0.25, 0.25), 0.25)));
  // beyond the far plane
  Assert.IsTrue(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(10.5, 5, 5), 1)));
  Assert.IsFalse(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(11.5, 5, 5), 1)));
  // beside the far corner (10, 5, 5): outside, then reaching the corner
  Assert.IsFalse(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(10, 6, 6), 1)));
  Assert.IsTrue(LFrustum.IntersectsSphere(TGeoSphere.Make(TGeoVec3.Make(10, 6, 6), 1.5)));
end;

procedure TTestGeometryFrustumValues.FromProjectionDellaSferaDovrebbeCreareUnFrustumConIlAngoloGiusto;
var
  LFrustum: TGeoFrustum;
  LRadius, LDistance, LTangent: Double;
begin
  LFrustum := TGeoFrustum.Make;
  Assert.IsTrue(LFrustum.FromProjection(TGeoSphere.Make(TGeoVec3.Make(10, 0, 0), 1), TGeoVec3.Origin, 100));
  Assert.AreEqual(Double(9), Double(LFrustum.DNear), 1E-4);
  Assert.AreEqual(Double(100), Double(LFrustum.DFar), 0);
  // the half width at the far plane is far * tan of the half angle of the cone
  LRadius := 1;
  LDistance := 10;
  LTangent := LRadius / Sqrt(LDistance * LDistance - LRadius * LRadius);
  Assert.AreEqual(LTangent * 100, Double(LFrustum.DLeft), 0.02);
  Assert.AreEqual(Double(LFrustum.DLeft), Double(LFrustum.DUp), 0);
  // the forward axis points to the sphere
  Assert.AreEqual(Double(1), Double(LFrustum.Axis.Rows[0].X), 1E-5);
end;

procedure TTestGeometryFrustumValues.FromProjectionDovrebbeFallireSeLOrigineEVicina;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  Assert.IsFalse(LFrustum.FromProjection(TGeoSphere.Make(TGeoVec3.Make(10, 0, 0), 20), TGeoVec3.Origin, 100));
  Assert.IsFalse(LFrustum.IsValid);
  LFrustum := Standard;
  Assert.IsFalse(LFrustum.FromProjection(TGeoBounds.Make(TGeoVec3.Make(-1, -1, -1), TGeoVec3.Make(1, 1, 1)),
    TGeoVec3.Origin, 100));
  Assert.IsFalse(LFrustum.IsValid);
  // a projection origin on the centre of the box has no direction
  Assert.IsFalse(LFrustum.FromProjection(TGeoBox.Make(TGeoVec3.Make(3, 3, 3), TGeoVec3.Make(1, 1, 1),
    TGeoMat3.Identity), TGeoVec3.Make(3, 3, 3), 100));
end;

procedure TTestGeometryFrustumValues.ConstrainToBoundsDovrebbeSpostareIlPianoLontano;
var
  LFrustum: TGeoFrustum;
begin
  LFrustum := Standard;
  Assert.IsTrue(LFrustum.ConstrainToBounds(TGeoBounds.Make(TGeoVec3.Make(2, -1, -1), TGeoVec3.Make(6, 1, 1))));
  Assert.AreEqual(Double(6), Double(LFrustum.DFar), 1E-5);
  // the volume ends before the near plane: the far plane goes just beyond the near one
  LFrustum := Standard;
  Assert.IsFalse(LFrustum.ConstrainToBounds(TGeoBounds.Make(TGeoVec3.Make(-5, -1, -1), TGeoVec3.Make(0, 1, 1))));
  Assert.AreEqual(Double(2), Double(LFrustum.DFar), 1E-5);
  LFrustum := Standard;
  Assert.IsTrue(LFrustum.ConstrainToSphere(TGeoSphere.Make(TGeoVec3.Make(4, 0, 0), 1)));
  Assert.AreEqual(Double(5), Double(LFrustum.DFar), 1E-5);
end;

procedure TTestGeometryFrustumValues.ProjectionBoundsDellaSferaDovrebbeCoprireTuttoIlFrustum;
var
  LFrustum: TGeoFrustum;
  LBounds: TGeoBounds;
begin
  LFrustum := Standard;
  Assert.IsTrue(LFrustum.ProjectionBounds(TGeoSphere.Make(TGeoVec3.Make(5, 2.5, 2.5), 1), LBounds));
  Assert.AreEqual(Double(0), Double(LBounds.Mins.X), 0);
  Assert.AreEqual(Double(10), Double(LBounds.Maxs.X), 0);
  Assert.AreEqual(Double(-1), Double(LBounds.Mins.Y), 0);
  Assert.AreEqual(Double(1), Double(LBounds.Maxs.Z), 0);
  Assert.IsFalse(LFrustum.ProjectionBounds(TGeoSphere.Make(TGeoVec3.Make(5, 50, 0), 1), LBounds));
  Assert.IsTrue(LBounds.IsCleared);
end;

procedure TTestGeometryFrustumValues.ProjectionBoundsDiUnBoundsCheContieneLOrigineDovrebbeCoprireTuttoIlFrustum;
var
  LFrustum: TGeoFrustum;
  LBounds: TGeoBounds;
begin
  LFrustum := Standard;
  Assert.IsTrue(LFrustum.ProjectionBounds(TGeoBounds.Make(TGeoVec3.Make(-2, -2, -2), TGeoVec3.Make(3, 2, 2)), LBounds));
  Assert.AreEqual(Double(-2), Double(LBounds.Mins.X), 1E-6);
  Assert.AreEqual(Double(3), Double(LBounds.Maxs.X), 1E-6);
  Assert.AreEqual(Double(-1), Double(LBounds.Mins.Z), 0);
  Assert.AreEqual(Double(1), Double(LBounds.Maxs.Y), 0);
end;

procedure TTestGeometryFrustumValues.IlWindingDovrebbeDareIlPianoELeIntersezioni;
var
  LWinding: TGeoWinding;
  LPlane: TGeoPlane;
  LScale: Single;
  LFrustum: TGeoFrustum;
  LFar: TGeoWinding;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(-3, 0, 0), TGeoVec3.Make(-2, 0, 0), TGeoVec3.Make(-2, 1, 0),
    TGeoVec3.Make(-3, 1, 0)]);
  LFar := TGeoWinding.Create([TGeoVec3.Make(5, -1, -1), TGeoVec3.Make(5, 1, -1), TGeoVec3.Make(5, 1, 1),
    TGeoVec3.Make(5, -1, 1)]);
  try
    Assert.AreEqual(Double(-2.5), Double(LWinding.GetCenter.X), 0);
    LWinding.GetPlane(LPlane);
    Assert.AreEqual(Double(-1), Double(LPlane.C), 1E-6);
    Assert.AreEqual(Double(0), Double(LPlane.D), 1E-6);
    Assert.IsTrue(LWinding.LineIntersection(LPlane, TGeoVec3.Make(-2.5, 0.5, -1), TGeoVec3.Make(-2.5, 0.5, 1)));
    Assert.IsFalse(LWinding.LineIntersection(LPlane, TGeoVec3.Make(2, 2, -1), TGeoVec3.Make(2, 2, 1)));
    Assert.IsFalse(LWinding.LineIntersection(LPlane, TGeoVec3.Make(-2.5, 0.5, 1), TGeoVec3.Make(-2.5, 0.5, 2)));
    Assert.IsTrue(LWinding.RayIntersection(LPlane, TGeoVec3.Make(-2.5, 0.5, -2), TGeoVec3.Make(0, 0, 1), LScale));
    Assert.AreEqual(Double(2), Double(LScale), 1E-6);
    Assert.IsFalse(LWinding.RayIntersection(LPlane, TGeoVec3.Make(3, 3, -2), TGeoVec3.Make(0, 0, 1), LScale));
    Assert.AreEqual(Double(0), Double(LScale), 0);
    Assert.IsTrue(LWinding.PointInside(LPlane.Normal, TGeoVec3.Make(-2.5, 0.5, 0), 0));
    Assert.IsFalse(LWinding.PointInside(LPlane.Normal, TGeoVec3.Make(2, 0.5, 0), 0));

    LFrustum := Standard;
    Assert.IsTrue(LFrustum.IntersectsWinding(LFar));
    Assert.IsFalse(LFrustum.CullWinding(LFar));
    Assert.IsFalse(LFrustum.IntersectsWinding(LWinding));
    Assert.IsTrue(LFrustum.CullWinding(LWinding));
  finally
    LFar.Free;
    LWinding.Free;
  end;
end;

end.
