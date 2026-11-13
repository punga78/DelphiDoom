{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the geometry of id Tech 4 (planes, bounds, spheres,    }
{  boxes) - values worked out by hand, special cases and sizes                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Geometry.Values;

{$Q-}
{$R-}

interface

uses
  System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Checks of TGeoPlane, TGeoBounds, TGeoSphere, TGeoBox and of the adapter with values
  ///   calculated by hand. Tolerance 1e-5 unless the test says otherwise.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestGeometryValues = class(TObject)
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
    procedure IlPianoDovrebbeIntersecareRaggiSegmentiEPiani;
    [Test]
    procedure IlPianoDovrebbeTraslarsiRuotarsiEConfrontarsi;
    [Test]
    procedure LaSferaDovrebbeCrescereConUnPuntoEUnaSfera;
    [Test]
    procedure LaSferaDovrebbeIntersecareRaggiESegmenti;
    [Test]
    procedure LaSferaDovrebbeStareDallaParteDelPiano;
    [Test]
    procedure LaSferaDovrebbeCostruirsiDaPuntiETraslazioni;
    [Test]
    procedure IBoundsDovrebberoIntersecareRaggiESegmenti;
    [Test]
    procedure IBoundsDovrebberoSpostarsiRuotarsiEProiettarsi;
    [Test]
    procedure IBoundsDovrebberoFarsiDaPuntiETraslazioni;
    [Test]
    procedure IBoundsInRotazioneDovrebberoSeguireLArco;
    [Test]
    procedure LaScatolaDovrebbeCrescereConUnPuntoEUnaScatola;
    [Test]
    procedure LaScatolaDovrebbeIntersecarsiEContenere;
    [Test]
    procedure LaScatolaDovrebbeDareLeSilhouette;
    [Test]
    procedure IlVolumeDellaScatolaDovrebbeEssereQuelloDelCpp;
    [Test]
    procedure LAdattatoreDovrebbeConvertireEIndietro;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Rotation,
  DelphiDoom.MathCore.Float.GeometryAdapter, DelphiDoom.MathCore.Float.BoundsRotation,
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Sphere,
  DelphiDoom.Geometry.Box;

const
  EPS = 1E-5;

function V(const AX, AY, AZ: Single): TGeoVec3;
begin
  Result.SetValues(AX, AY, AZ);
end;

function UnitBounds: TGeoBounds;
begin
  Result.Mins := V(-1, -2, -3);
  Result.Maxs := V(1, 2, 3);
end;

// a rotation of 90 degrees about z, in the matrix convention of idlib (a vector times it)
function Turn90: TGeoMat3;
begin
  Result := TGeoMat3.Make(0, 1, 0, -1, 0, 0, 0, 0, 1);
end;

procedure CheckVec(const AExpected, AActual: TGeoVec3; const AMessage: string = '');
begin
  Assert.AreEqual(Double(AExpected.X), Double(AActual.X), EPS, AMessage + ' x');
  Assert.AreEqual(Double(AExpected.Y), Double(AActual.Y), EPS, AMessage + ' y');
  Assert.AreEqual(Double(AExpected.Z), Double(AActual.Z), EPS, AMessage + ' z');
end;

procedure CheckBounds(const AExpected, AActual: TGeoBounds; const AMessage: string = '');
begin
  CheckVec(AExpected.Mins, AActual.Mins, AMessage + ' mins');
  CheckVec(AExpected.Maxs, AActual.Maxs, AMessage + ' maxs');
end;

{ TTestGeometryValues }

procedure TTestGeometryValues.Setup;
begin
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
end;

procedure TTestGeometryValues.TearDown;
begin
  SetExceptionMask(FOldMask);
end;

procedure TTestGeometryValues.IRecordDovrebberoAvereLaDimensioneDelCpp;
begin
  Assert.AreEqual(16, SizeOf(TGeoPlane), 'piano');
  Assert.AreEqual(16, SizeOf(TGeoSphere), 'sfera');
  Assert.AreEqual(24, SizeOf(TGeoBounds), 'bounds');
  Assert.AreEqual(60, SizeOf(TGeoBox), 'scatola');
  Assert.AreEqual(36, SizeOf(TGeoMat3), 'matrice');
end;

procedure TTestGeometryValues.IlPianoDovrebbeIntersecareRaggiSegmentiEPiani;
var
  LPlaneX, LPlaneY, LParallel: TGeoPlane;
  LStart, LDir: TGeoVec3;
  LScale: Single;
begin
  LPlaneX := TGeoPlane.Make(1, 0, 0, -1);
  LPlaneY := TGeoPlane.Make(0, 1, 0, -2);
  // the line where x = 1 and y = 2 meet: through (1, 2, 0) along z
  Assert.IsTrue(LPlaneX.PlaneIntersection(LPlaneY, LStart, LDir));
  CheckVec(V(1, 2, 0), LStart, 'inizio');
  CheckVec(V(0, 0, 1), LDir, 'direzione');
  LParallel := TGeoPlane.Make(1, 0, 0, -5);
  Assert.IsFalse(LPlaneX.PlaneIntersection(LParallel, LStart, LDir), 'piani paralleli');
  // the ray from the origin along x meets x = 1 at scale 1, a ray along y is parallel
  Assert.IsTrue(LPlaneX.RayIntersection(V(0, 0, 0), V(1, 0, 0), LScale));
  Assert.AreEqual(1.0, Double(LScale), EPS);
  Assert.IsFalse(LPlaneX.RayIntersection(V(0, 0, 0), V(0, 1, 0), LScale));
  Assert.AreEqual(0.0, Double(LScale), EPS);
  Assert.IsTrue(LPlaneX.LineIntersection(V(0, 0, 0), V(3, 0, 0)));
  Assert.IsFalse(LPlaneX.LineIntersection(V(2, 0, 0), V(3, 0, 0)), 'segmento davanti');
  Assert.IsFalse(LPlaneX.LineIntersection(V(-2, 0, 0), V(-3, 0, 0)), 'segmento dietro');
  Assert.IsFalse(LPlaneX.LineIntersection(V(2, 0, 0), V(2, 5, 0)), 'segmento parallelo');
end;

procedure TTestGeometryValues.IlPianoDovrebbeTraslarsiRuotarsiEConfrontarsi;
var
  LPlane, LMoved, LTurned, LThrough: TGeoPlane;
begin
  LPlane := TGeoPlane.Make(1, 0, 0, -1);
  // x = 1 moved by 2 along x is x = 3: d = -3
  LMoved := LPlane.Translate(V(2, 0, 0));
  Assert.AreEqual(-3.0, Double(LMoved.D), EPS);
  LMoved := LPlane;
  LMoved.TranslateSelf(V(2, 0, 0));
  Assert.AreEqual(-3.0, Double(LMoved.D), EPS);
  // x = 1 turned by 90 degrees about the origin: its normal goes to +y (vector times matrix: the rows
  // are the images of the axes), the distance from the origin stays 1
  LTurned := LPlane.Rotate(V(0, 0, 0), Turn90);
  CheckVec(V(0, 1, 0), LTurned.Normal, 'normale');
  Assert.AreEqual(-1.0, Double(LTurned.D), EPS);
  LTurned := LPlane;
  LTurned.RotateSelf(V(0, 0, 0), Turn90);
  CheckVec(V(0, 1, 0), LTurned.Normal, 'normale sul posto');
  Assert.IsTrue(LThrough.FromVecs(V(1, 0, 0), V(0, 1, 0), V(0, 0, 4)), 'da due direzioni');
  Assert.AreEqual(-4.0, Double(LThrough.D), EPS);
  Assert.IsFalse(LThrough.FromVecs(V(1, 0, 0), V(2, 0, 0), V(0, 0, 4)), 'direzioni parallele');
  Assert.IsTrue(LPlane.Compare(LPlane, Single(0)));
  Assert.IsTrue(LPlane.Compare(TGeoPlane.Make(1.1, 0, 0, -1), Single(0.2)));
  Assert.IsFalse(LPlane.Compare(TGeoPlane.Make(1.1, 0, 0, -1), Single(0.05)));
  Assert.IsFalse(LPlane.Compare(TGeoPlane.Make(1, 0, 0, -2), Single(0.1), Single(0.5)), 'distanza');
  Assert.IsFalse(LPlane.Compare(TGeoPlane.Make(1, 0.5, 0, -1), Single(0.1), Single(0.5)), 'normale');
  Assert.IsTrue(LPlane.Compare(TGeoPlane.Make(1, 0.05, 0, -1.2), Single(0.1), Single(0.5)));
end;

procedure TTestGeometryValues.LaSferaDovrebbeCrescereConUnPuntoEUnaSfera;
var
  LSphere, LOther: TGeoSphere;
begin
  LSphere := TGeoSphere.Make(V(0, 0, 0), 1);
  // a point at distance 3: the sphere grows to radius 2 with the origin at x = 1
  Assert.IsTrue(LSphere.AddPoint(V(3, 0, 0)));
  CheckVec(V(1, 0, 0), LSphere.Origin, 'centro');
  Assert.AreEqual(2.0, Double(LSphere.Radius), EPS);
  Assert.IsFalse(LSphere.AddPoint(V(1, 1, 0)), 'punto dentro');
  // a sphere of radius 1 at x = 5: radius 2 + (5 - 2) / 2 = 3.5, centre 1 + 4 * 0.5 * (1 - 2 / 5) = 2.2
  LOther := TGeoSphere.Make(V(5, 0, 0), 1);
  Assert.IsTrue(LSphere.AddSphere(LOther));
  CheckVec(V(2.2, 0, 0), LSphere.Origin, 'centro dopo la somma');
  Assert.AreEqual(3.5, Double(LSphere.Radius), EPS);
  Assert.IsFalse(LSphere.AddSphere(TGeoSphere.Make(V(2.5, 0, 0), 1)), 'sfera dentro');
  // the cleared sphere takes the first thing added
  LSphere.Clear;
  Assert.IsTrue(LSphere.IsCleared);
  Assert.IsTrue(LSphere.AddPoint(V(1, 2, 3)));
  CheckVec(V(1, 2, 3), LSphere.Origin);
  Assert.AreEqual(0.0, Double(LSphere.Radius), EPS);
  LSphere.Clear;
  Assert.IsTrue(LSphere.AddSphere(LOther));
  Assert.IsTrue(LSphere.Compare(LOther));
  LSphere.Zero;
  Assert.IsFalse(LSphere.IsCleared);
  Assert.IsTrue(LSphere.Compare(TGeoSphere.Make(V(0, 0, 0), 0)));
  Assert.IsTrue(LSphere.Compare(TGeoSphere.Make(V(0.05, 0, 0), 0.05), Single(0.1)));
  Assert.IsFalse(LSphere.Compare(TGeoSphere.Make(V(0.5, 0, 0), 0), Single(0.1)));
  LSphere := LOther.Expand(2);
  Assert.AreEqual(3.0, Double(LSphere.Radius), EPS);
  LSphere.ExpandSelf(1);
  Assert.AreEqual(4.0, Double(LSphere.Radius), EPS);
  LSphere := LOther.Translate(V(1, 1, 1));
  CheckVec(V(6, 1, 1), LSphere.Origin);
  LSphere.TranslateSelf(V(-1, -1, -1));
  CheckVec(V(5, 0, 0), LSphere.Origin);
  Assert.IsTrue(LOther.ContainsPoint(V(6, 0, 0)), 'toccare conta');
  Assert.IsFalse(LOther.ContainsPoint(V(6.1, 0, 0)));
  Assert.IsTrue(LOther.IntersectsSphere(TGeoSphere.Make(V(7, 0, 0), 1)), 'sfere che si toccano');
  Assert.IsFalse(LOther.IntersectsSphere(TGeoSphere.Make(V(7.1, 0, 0), 1)));
end;

procedure TTestGeometryValues.LaSferaDovrebbeIntersecareRaggiESegmenti;
var
  LSphere: TGeoSphere;
  LScale1, LScale2: Single;
begin
  LSphere := TGeoSphere.Make(V(0, 0, 0), 1);
  // from (-5, 0, 0) along x: a = 1, b = -5, c = 24, discriminant 1: scales 6 and 4
  Assert.IsTrue(LSphere.RayIntersection(V(-5, 0, 0), V(1, 0, 0), LScale1, LScale2));
  Assert.AreEqual(6.0, Double(LScale1), EPS);
  Assert.AreEqual(4.0, Double(LScale2), EPS);
  // from inside: one scale is negative and the other positive
  Assert.IsTrue(LSphere.RayIntersection(V(0, 0, 0), V(1, 0, 0), LScale1, LScale2));
  Assert.AreEqual(1.0, Double(LScale1), EPS);
  Assert.AreEqual(-1.0, Double(LScale2), EPS);
  Assert.IsFalse(LSphere.RayIntersection(V(-5, 3, 0), V(1, 0, 0), LScale1, LScale2), 'raggio che manca');
  // segments: crossing, ending before, starting inside, ending inside, passing at the side
  Assert.IsTrue(LSphere.LineIntersection(V(-3, 0, 0), V(3, 0, 0)), 'attraversa');
  Assert.IsFalse(LSphere.LineIntersection(V(-5, 0, 0), V(-3, 0, 0)), 'finisce prima');
  Assert.IsFalse(LSphere.LineIntersection(V(3, 0, 0), V(5, 0, 0)), 'comincia dopo');
  Assert.IsTrue(LSphere.LineIntersection(V(0, 0, 0), V(5, 0, 0)), 'comincia dentro');
  Assert.IsTrue(LSphere.LineIntersection(V(-5, 0, 0), V(0, 0, 0)), 'finisce dentro');
  Assert.IsFalse(LSphere.LineIntersection(V(-3, 2, 0), V(3, 2, 0)), 'passa di lato');
end;

procedure TTestGeometryValues.LaSferaDovrebbeStareDallaParteDelPiano;
var
  LSphere: TGeoSphere;
  LPlane: TGeoPlane;
begin
  LSphere := TGeoSphere.Make(V(0, 0, 5), 1);
  LPlane := TGeoPlane.Make(0, 0, 1, 0);
  Assert.AreEqual(4.0, Double(LSphere.PlaneDistance(LPlane)), EPS, 'davanti');
  Assert.AreEqual(PLANESIDE_FRONT, LSphere.PlaneSide(LPlane));
  LSphere.Origin := V(0, 0, -5);
  Assert.AreEqual(-4.0, Double(LSphere.PlaneDistance(LPlane)), EPS, 'dietro');
  Assert.AreEqual(PLANESIDE_BACK, LSphere.PlaneSide(LPlane));
  LSphere.Origin := V(0, 0, 0.5);
  Assert.AreEqual(0.0, Double(LSphere.PlaneDistance(LPlane)), EPS, 'attraversata');
  Assert.AreEqual(PLANESIDE_CROSS, LSphere.PlaneSide(LPlane));
end;

procedure TTestGeometryValues.LaSferaDovrebbeCostruirsiDaPuntiETraslazioni;
var
  LSphere: TGeoSphere;
  LMin, LMax: Single;
begin
  // two opposite corners: centre in the middle, radius half the diagonal
  LSphere.FromPoints([V(-1, 0, 0), V(1, 0, 0)]);
  CheckVec(V(0, 0, 0), LSphere.Origin);
  Assert.AreEqual(1.0, Double(LSphere.Radius), EPS);
  LSphere.FromPointTranslation(V(1, 0, 0), V(0, 4, 0));
  CheckVec(V(1, 2, 0), LSphere.Origin);
  Assert.AreEqual(Sqrt(8.0), Double(LSphere.Radius), EPS);
  LSphere.FromSphereTranslation(TGeoSphere.Make(V(1, 0, 0), 0.5), V(10, 0, 0), V(0, 4, 0));
  CheckVec(V(11, 2, 0), LSphere.Origin);
  Assert.AreEqual(Sqrt(8.0) + 0.5, Double(LSphere.Radius), EPS);
  LSphere := TGeoSphere.Make(V(2, 0, 0), 1);
  LSphere.AxisProjection(V(1, 0, 0), LMin, LMax);
  Assert.AreEqual(1.0, Double(LMin), EPS);
  Assert.AreEqual(3.0, Double(LMax), EPS);
  LSphere := TGeoSphere.Make(V(1, 2, 3));
  Assert.AreEqual(0.0, Double(LSphere.Radius), EPS);
end;

procedure TTestGeometryValues.IBoundsDovrebberoIntersecareRaggiESegmenti;
var
  LBounds: TGeoBounds;
  LScale: Single;
begin
  LBounds := UnitBounds;
  // the ray from (-5, 0, 0) along x meets the face x = -1 at scale 4
  Assert.IsTrue(LBounds.RayIntersection(V(-5, 0, 0), V(1, 0, 0), LScale));
  Assert.AreEqual(4.0, Double(LScale), EPS);
  // the same ray, aimed away, still meets it (both directions): scale -4 -> reported as 4
  Assert.IsFalse(LBounds.RayIntersection(V(-5, 5, 0), V(1, -0.1, 0), LScale), 'raggio che passa sopra');
  Assert.IsTrue(LBounds.RayIntersection(V(0, 0, 0), V(1, 0, 0), LScale), 'partenza dentro');
  Assert.AreEqual(0.0, Double(LScale), EPS);
  Assert.IsTrue(LBounds.RayIntersection(V(0, 0, 0), V(0, 0, 0), LScale), 'direzione nulla, dentro');
  Assert.IsFalse(LBounds.RayIntersection(V(0, 9, 0), V(0, 0, 0), LScale), 'direzione nulla, fuori');
  Assert.IsFalse(LBounds.RayIntersection(V(5, 0, 0), V(0, 1, 0), LScale), 'parallelo fuori');
  Assert.IsTrue(LBounds.LineIntersection(V(-3, 0, 0), V(3, 0, 0)));
  Assert.IsFalse(LBounds.LineIntersection(V(-3, 5, 0), V(3, 5, 0)), 'asse y');
  Assert.IsFalse(LBounds.LineIntersection(V(5, 0, 0), V(8, 0, 0)), 'asse x');
  Assert.IsFalse(LBounds.LineIntersection(V(0, 0, 9), V(0, 1, 12)), 'asse z');
  // a diagonal segment that passes the corner without entering: caught by the cross product tests
  Assert.IsFalse(LBounds.LineIntersection(V(2, 0, 4), V(4, 0, 2)), 'angolo');
  Assert.IsFalse(LBounds.LineIntersection(V(2, 4, 0), V(4, 2, 0)), 'angolo y');
  Assert.IsFalse(LBounds.LineIntersection(V(0, 3, 4), V(0, 4, 3)), 'angolo x');
end;

procedure TTestGeometryValues.IBoundsDovrebberoSpostarsiRuotarsiEProiettarsi;
var
  LBounds, LOther, LResult: TGeoBounds;
  LPoints: array[0..7] of TGeoVec3;
  LMin, LMax: Single;
begin
  LBounds := UnitBounds;
  // the radius around the origin: the farthest corner (1, 2, 3)
  Assert.AreEqual(Sqrt(14.0), Double(LBounds.GetRadius), EPS);
  Assert.AreEqual(Sqrt(29.0), Double(LBounds.GetRadius(V(-3, 0, 0))), EPS);
  Assert.AreEqual(48.0, Double(LBounds.GetVolume), EPS);
  LResult.Mins := V(0, 0, 0);
  LResult.Maxs := V(0, 1, 1);
  Assert.AreEqual(0.0, Double(LResult.GetVolume), EPS, 'bounds piatti');
  LOther.Mins := V(0, 0, 0);
  LOther.Maxs := V(5, 5, 5);
  LResult := LBounds.Intersect(LOther);
  CheckBounds(TGeoBounds.Make(V(0, 0, 0), V(1, 2, 3)), LResult, 'intersezione');
  LResult := LBounds;
  LResult.IntersectSelf(LOther);
  CheckBounds(TGeoBounds.Make(V(0, 0, 0), V(1, 2, 3)), LResult, 'intersezione sul posto');
  CheckBounds(TGeoBounds.Make(V(-2, -3, -4), V(2, 3, 4)), LBounds.Expand(1), 'espansione');
  LResult := LBounds;
  LResult.ExpandSelf(1);
  CheckBounds(TGeoBounds.Make(V(-2, -3, -4), V(2, 3, 4)), LResult, 'espansione sul posto');
  CheckBounds(TGeoBounds.Make(V(0, 0, 0), V(2, 4, 6)), LBounds.Translate(V(1, 2, 3)), 'traslazione');
  // turned by 90 degrees about z: x and y swap their sizes
  CheckBounds(TGeoBounds.Make(V(-2, -1, -3), V(2, 1, 3)), LBounds.Rotate(Turn90), 'rotazione');
  LResult := LBounds;
  LResult.RotateSelf(Turn90);
  CheckBounds(TGeoBounds.Make(V(-2, -1, -3), V(2, 1, 3)), LResult, 'rotazione sul posto');
  LBounds.ToPoints(LPoints);
  CheckVec(V(-1, -2, -3), LPoints[0], 'angolo 0');
  CheckVec(V(1, -2, -3), LPoints[1], 'angolo 1');
  CheckVec(V(1, 2, -3), LPoints[2], 'angolo 2');
  CheckVec(V(-1, 2, -3), LPoints[3], 'angolo 3');
  CheckVec(V(-1, -2, 3), LPoints[4], 'angolo 4');
  CheckVec(V(-1, 2, 3), LPoints[7], 'angolo 7');
  LBounds.AxisProjection(V(0, 1, 0), LMin, LMax);
  Assert.AreEqual(-2.0, Double(LMin), EPS);
  Assert.AreEqual(2.0, Double(LMax), EPS);
  LBounds.AxisProjection(V(10, 0, 0), TGeoMat3.Identity, V(1, 0, 0), LMin, LMax);
  Assert.AreEqual(9.0, Double(LMin), EPS);
  Assert.AreEqual(11.0, Double(LMax), EPS);
  Assert.AreEqual(Sqrt(14.0), Double(LBounds.ToSphere.Radius), EPS);
  Assert.IsTrue(LBounds.Compare(UnitBounds, Single(0)));
  Assert.IsFalse(LBounds.Compare(LOther, Single(0.5)));
end;

procedure TTestGeometryValues.IBoundsDovrebberoFarsiDaPuntiETraslazioni;
var
  LBounds: TGeoBounds;
begin
  LBounds.FromPoints([V(1, 5, 0), V(-2, 3, 4)]);
  CheckBounds(TGeoBounds.Make(V(-2, 3, 0), V(1, 5, 4)), LBounds, 'punti');
  LBounds.FromPoints([]);
  Assert.IsTrue(LBounds.IsCleared, 'nessun punto');
  // a point moved by (-1, 2, 0)
  LBounds.FromPointTranslation(V(1, 1, 1), V(-1, 2, 0));
  CheckBounds(TGeoBounds.Make(V(0, 1, 1), V(1, 3, 1)), LBounds, 'punto che si muove');
  // a box that is not rotated is only moved, then grown along the translation
  LBounds.FromBoundsTranslation(UnitBounds, V(10, 0, 0), TGeoMat3.Identity, V(0, -1, 2));
  CheckBounds(TGeoBounds.Make(V(9, -3, -3), V(11, 2, 5)), LBounds, 'box che si muove');
  LBounds.FromBoundsTranslation(UnitBounds, V(10, 0, 0), Turn90, V(0, 0, 0));
  CheckBounds(TGeoBounds.Make(V(8, -1, -3), V(12, 1, 3)), LBounds, 'box ruotato');
end;

procedure TTestGeometryValues.IBoundsInRotazioneDovrebberoSeguireLArco;
var
  LRotation: TIdRotation;
  LBounds: TGeoBounds;
  LSphere: TGeoSphere;
begin
  // the point (1, 0, 0) turned by 90 degrees about z goes to (0, -1, 0) (idlib convention): the
  // arc covers x in [0, 1] and, since it passes the circle, y between -1 and 0
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 90);
  LBounds := TIdBoundsRotation.ForPointRotation(V(1, 0, 0), LRotation);
  CheckBounds(TGeoBounds.Make(V(0, -1, 0), V(1, 0, 0)), LBounds, 'arco');
  LBounds := TIdBoundsRotation.FromPointRotation(V(1, 0, 0), LRotation);
  CheckBounds(TGeoBounds.Make(V(0, -1, 0), V(1, 0, 0)), LBounds, 'punto sotto 180');
  // 180 degrees or more: the cube of the distance from the rotation origin
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 200);
  LBounds := TIdBoundsRotation.FromPointRotation(V(3, 0, 0), LRotation);
  CheckBounds(TGeoBounds.Make(V(-3, -3, -3), V(3, 3, 3)), LBounds, 'punto sopra 180');
  // a box under 180 degrees: contains the box before and after
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 90);
  LBounds := TIdBoundsRotation.FromBoundsRotation(TGeoBounds.Make(V(1, 0, 0), V(2, 1, 1)), V(0, 0, 0),
    TGeoMat3.Identity, LRotation);
  Assert.IsTrue(LBounds.ContainsPoint(V(1, 0, 0)), 'punto di partenza');
  // (cos 90 is about -4e-8 in a float: the point is taken a little inside)
  Assert.IsTrue(LBounds.ContainsPoint(V(0.001, -1.999, 0.999)), 'punto di arrivo');
  // above 180: the cube around the origin of the rotation, radius from half the size
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 200);
  LBounds := TIdBoundsRotation.FromBoundsRotation(TGeoBounds.Make(V(-1, -1, -1), V(1, 1, 1)), V(0, 0, 0),
    TGeoMat3.Identity, LRotation);
  Assert.IsTrue(LBounds.Maxs.X > 1, 'cubo grande');
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 180);
  LSphere := TIdBoundsRotation.SphereFromPointRotation(V(1, 0, 0), LRotation);
  CheckVec(V(0, 0, 0), LSphere.Origin, 'centro della sfera');
  Assert.AreEqual(Sqrt(2.0), Double(LSphere.Radius), EPS);
  LSphere := TIdBoundsRotation.SphereFromSphereRotation(TGeoSphere.Make(V(1, 0, 0), 0.5), V(10, 0, 0), LRotation);
  CheckVec(V(10, 0, 0), LSphere.Origin, 'centro della sfera in movimento');
  Assert.AreEqual(Sqrt(2.0) + 0.5, Double(LSphere.Radius), EPS);
end;

procedure TTestGeometryValues.LaScatolaDovrebbeCrescereConUnPuntoEUnaScatola;
var
  LBox, LOther: TGeoBox;
begin
  LBox := TGeoBox.Make(V(0, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  Assert.IsFalse(LBox.AddPoint(V(0.5, 0.5, 0.5)), 'punto dentro');
  // a point on the x axis keeps the axes: the extents grow to 2, the centre moves to x = 1
  Assert.IsTrue(LBox.AddPoint(V(3, 0, 0)));
  Assert.AreEqual(1.0, Double(LBox.Center.X), 1E-4);
  Assert.AreEqual(2.0, Double(LBox.Extents.X), 1E-4);
  Assert.IsTrue(LBox.ContainsPoint(V(3, 0, 0)));
  // the cleared box takes the first thing added
  LBox.Clear;
  Assert.IsTrue(LBox.IsCleared);
  Assert.IsTrue(LBox.AddPoint(V(1, 2, 3)));
  CheckVec(V(1, 2, 3), LBox.Center);
  CheckVec(V(0, 0, 0), LBox.Extents);
  LOther := TGeoBox.Make(V(5, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  LBox.Clear;
  Assert.IsTrue(LBox.AddBox(LOther));
  Assert.IsTrue(LBox.Compare(LOther));
  // adding a cleared box does nothing
  LOther.Clear;
  Assert.IsFalse(LBox.AddBox(LOther));
  Assert.AreEqual(5.0, Double(LBox.Center.X), EPS);
  // a box inside is not added; a box that contains this one replaces it
  LOther := TGeoBox.Make(V(5, 0, 0), V(0.5, 0.5, 0.5), TGeoMat3.Identity);
  Assert.IsFalse(LBox.AddBox(LOther), 'dentro');
  LOther := TGeoBox.Make(V(5, 0, 0), V(2, 2, 2), TGeoMat3.Identity);
  Assert.IsTrue(LBox.AddBox(LOther), 'contenitore');
  Assert.IsTrue(LBox.Compare(LOther));
  // two separate boxes: the result contains both (the original returns false: kept)
  LOther := TGeoBox.Make(V(10, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  Assert.IsFalse(LBox.AddBox(LOther), 'il C++ restituisce false anche se e'' cresciuta');
  Assert.IsTrue(LBox.ContainsPoint(V(11, 0, 0)));
  Assert.IsTrue(LBox.ContainsPoint(V(3, 0, 0)));
  LBox.Zero;
  Assert.IsTrue(LBox.Compare(TGeoBox.Make(V(0, 0, 0))));
  LBox := TGeoBox.Make(UnitBounds);
  CheckVec(V(1, 2, 3), LBox.Extents);
  LBox := TGeoBox.Make(UnitBounds, V(10, 0, 0), Turn90);
  CheckVec(V(10, 0, 0), LBox.Center);
  Assert.IsTrue(LBox.Compare(LBox, Single(0)));
end;

procedure TTestGeometryValues.LaScatolaDovrebbeIntersecarsiEContenere;
var
  LBox, LOther, LResult: TGeoBox;
  LScale1, LScale2: Single;
  LBounds: TGeoBounds;
  LMin, LMax: Single;
begin
  LBox := TGeoBox.Make(V(0, 0, 0), V(1, 2, 3), TGeoMat3.Identity);
  LOther := TGeoBox.Make(V(2, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  Assert.IsTrue(LBox.IntersectsBox(LOther), 'toccare conta');
  LOther.Center := V(2.5, 0, 0);
  Assert.IsFalse(LBox.IntersectsBox(LOther));
  // turned by 90 degrees about z the box of extents (1, 2, 3) covers x within 2: it now touches
  LBox := LBox.Rotate(Turn90);
  Assert.IsTrue(LBox.IntersectsBox(LOther));
  LResult := LBox;
  LResult.RotateSelf(Turn90);
  Assert.IsTrue(LResult.ContainsPoint(V(0, 0, 2.9)));
  Assert.IsFalse(LResult.ContainsPoint(V(0, 0, 3.1)));
  // two boxes at 45 degrees apart on a corner: the cross product axes separate them
  LBox := TGeoBox.Make(V(0, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  LOther := TGeoBox.Make(V(2.6, 2.6, 0), V(1, 1, 1), TGeoMat3.Make(0.7071068, 0.7071068, 0, -0.7071068, 0.7071068, 0, 0, 0, 1));
  Assert.IsFalse(LBox.IntersectsBox(LOther), 'angolo');
  LOther.Center := V(1.5, 1.5, 0);
  Assert.IsTrue(LBox.IntersectsBox(LOther), 'angolo vicino');
  LOther := TGeoBox.Make(V(0, 5, 5), V(1, 1, 1), TGeoMat3.Make(0, 0.7071068, 0.7071068, 1, 0, 0, 0, 0.7071068, -0.7071068));
  Assert.IsFalse(LBox.IntersectsBox(LOther), 'assi ruotati');
  // rays and segments
  LBox := TGeoBox.Make(V(0, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  Assert.IsTrue(LBox.RayIntersection(V(-5, 0, 0), V(1, 0, 0), LScale1, LScale2));
  Assert.AreEqual(4.0, Double(LScale1), EPS);
  Assert.AreEqual(6.0, Double(LScale2), EPS);
  Assert.IsTrue(LBox.RayIntersection(V(0, 0, 0), V(0, 1, 0), LScale1, LScale2), 'dentro');
  Assert.AreEqual(-1.0, Double(LScale1), EPS);
  Assert.AreEqual(1.0, Double(LScale2), EPS);
  Assert.IsFalse(LBox.RayIntersection(V(-5, 3, 0), V(1, 0, 0), LScale1, LScale2), 'parallelo fuori');
  Assert.IsFalse(LBox.RayIntersection(V(-5, 3, 0), V(1, -0.1, 0), LScale1, LScale2), 'sbaglia');
  // the ray is taken in both directions: a box behind the start is met at negative scales
  Assert.IsTrue(LBox.RayIntersection(V(5, 0, 0), V(1, 0, 0), LScale1, LScale2), 'box alle spalle');
  Assert.AreEqual(-6.0, Double(LScale1), EPS);
  Assert.AreEqual(-4.0, Double(LScale2), EPS);
  Assert.IsTrue(LBox.LineIntersection(V(-5, 0, 0), V(5, 0, 0)));
  Assert.IsFalse(LBox.LineIntersection(V(-5, 3, 0), V(5, 3, 0)), 'asse y');
  Assert.IsFalse(LBox.LineIntersection(V(3, 0, 0), V(5, 0, 0)), 'asse x');
  Assert.IsFalse(LBox.LineIntersection(V(0, 0, 3), V(0, 1, 5)), 'asse z');
  Assert.IsFalse(LBox.LineIntersection(V(0, 2, 2.2), V(0, 2.2, 2)), 'angolo x');
  Assert.IsFalse(LBox.LineIntersection(V(2, 0, 2.2), V(2.2, 0, 2)), 'angolo y');
  Assert.IsFalse(LBox.LineIntersection(V(2, 2.2, 0), V(2.2, 2, 0)), 'angolo z');
  // plane sides
  Assert.AreEqual(PLANESIDE_FRONT, LBox.PlaneSide(TGeoPlane.Make(0, 0, 1, 5)));
  Assert.AreEqual(PLANESIDE_BACK, LBox.PlaneSide(TGeoPlane.Make(0, 0, 1, -5)));
  Assert.AreEqual(PLANESIDE_CROSS, LBox.PlaneSide(TGeoPlane.Make(0, 0, 1, 0)));
  Assert.AreEqual(4.0, Double(LBox.PlaneDistance(TGeoPlane.Make(0, 0, 1, 5))), EPS);
  Assert.AreEqual(-4.0, Double(LBox.PlaneDistance(TGeoPlane.Make(0, 0, 1, -5))), EPS);
  Assert.AreEqual(0.0, Double(LBox.PlaneDistance(TGeoPlane.Make(0, 0, 1, 0))), EPS);
  // projections
  LBox.AxisProjection(V(1, 0, 0), LMin, LMax);
  Assert.AreEqual(-1.0, Double(LMin), EPS);
  Assert.AreEqual(1.0, Double(LMax), EPS);
  LBox.AxisProjection(TGeoMat3.Identity, LBounds);
  CheckBounds(TGeoBounds.Make(V(-1, -1, -1), V(1, 1, 1)), LBounds, 'proiezione sugli assi');
  Assert.AreEqual(Sqrt(3.0), Double(LBox.ToSphere.Radius), EPS);
  // translation, expansion, in place
  LResult := LBox.Translate(V(1, 0, 0));
  CheckVec(V(1, 0, 0), LResult.Center);
  LResult.TranslateSelf(V(1, 0, 0));
  CheckVec(V(2, 0, 0), LResult.Center);
  LResult := LBox.Expand(1);
  CheckVec(V(2, 2, 2), LResult.Extents);
  LResult.ExpandSelf(1);
  CheckVec(V(3, 3, 3), LResult.Extents);
end;

procedure TTestGeometryValues.LaScatolaDovrebbeDareLeSilhouette;
var
  LBox: TGeoBox;
  LSilhouette: array[0..5] of TGeoVec3;
  LPoints: array[0..7] of TGeoVec3;
begin
  LBox := TGeoBox.Make(V(0, 0, 0), V(1, 1, 1), TGeoMat3.Identity);
  LBox.ToPoints(LPoints);
  CheckVec(V(-1, -1, -1), LPoints[0], 'angolo 0');
  CheckVec(V(1, -1, -1), LPoints[1], 'angolo 1');
  CheckVec(V(1, 1, -1), LPoints[2], 'angolo 2');
  CheckVec(V(-1, 1, 1), LPoints[7], 'angolo 7');
  // looking straight at a face from far away: four corners; from a corner direction: six
  Assert.AreEqual(4, LBox.GetProjectionSilhouetteVerts(V(10, 0, 0), LSilhouette));
  Assert.AreEqual(6, LBox.GetProjectionSilhouetteVerts(V(10, 10, 10), LSilhouette));
  Assert.AreEqual(0, LBox.GetProjectionSilhouetteVerts(V(0, 0, 0), LSilhouette), 'dentro la scatola');
  Assert.AreEqual(4, LBox.GetParallelProjectionSilhouetteVerts(V(1, 0, 0), LSilhouette));
  Assert.AreEqual(6, LBox.GetParallelProjectionSilhouetteVerts(V(1, 1, 1), LSilhouette));
  Assert.AreEqual(0, LBox.GetParallelProjectionSilhouetteVerts(V(0, 0, 0), LSilhouette), 'direzione nulla');
end;

procedure TTestGeometryValues.IlVolumeDellaScatolaDovrebbeEssereQuelloDelCpp;
var
  LBox: TGeoBox;
begin
  // idBox::GetVolume is ( extents * 2 ).LengthSqr(), not the volume: (2, 4, 4) gives 4 + 16 + 16
  // where the volume is 32
  LBox := TGeoBox.Make(V(0, 0, 0), V(1, 2, 2), TGeoMat3.Identity);
  Assert.AreEqual(36.0, Double(LBox.GetVolume), EPS);
end;

procedure TTestGeometryValues.LAdattatoreDovrebbeConvertireEIndietro;
var
  LVector: TIdVec3;
  LMatrix: TIdMat3;
  LGeoMatrix: TGeoMat3;
begin
  LVector := TIdVec3.Create(1, 2, 3);
  CheckVec(V(1, 2, 3), TIdGeometryAdapter.ToGeo(LVector));
  LGeoMatrix := TGeoMat3.Make(1, 2, 3, 4, 5, 6, 7, 8, 9);
  LMatrix := TIdGeometryAdapter.ToId(LGeoMatrix);
  Assert.AreEqual(6.0, Double(LMatrix.Rows[1].Z), EPS);
  Assert.IsTrue(LGeoMatrix.Compare(TIdGeometryAdapter.ToGeo(LMatrix)));
  Assert.IsFalse(LGeoMatrix.Compare(TGeoMat3.Identity, Single(0.5)));
  Assert.AreEqual(3.0, Double(TIdGeometryAdapter.ToId(V(1, 2, 3)).Z), EPS);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGeometryValues);

end.
