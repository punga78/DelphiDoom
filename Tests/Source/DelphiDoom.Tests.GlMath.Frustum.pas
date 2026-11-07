{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL math library - the view frustum             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GlMath.Frustum;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GlMath.Types, DelphiDoom.GlMath.Intf;

type
  /// <summary>Parity with the old gl_frustum (golden file glmath.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('glmath')]
  TTestGlMathFrustum = class(TObject)
  strict private
    FFrustum: IGlFrustum;
    procedure CalculateCamera;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLaStessaImprontaDelVecchioCodiceSuiPiani;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuiPunti;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuLeSfere;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuiParallelepipedi;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuiCubi;
    [Test]
    procedure DovrebbeNormalizzareIPianiPerchePerpendicolariUnitari;
    [Test]
    procedure DovrebbeContenereUnPuntoDavantiALCameraENonUnoDietro;
    [Test]
    procedure DovrebbeEscludereUnPuntoFuoriDalCampoVisivo;
    [Test]
    procedure DovrebbeContenereUnaSferaCheTocca;
    [Test]
    procedure DovrebbeContenereUnParallelepipedoCheSiSovrappone;
    [Test]
    procedure DovrebbeEscludereUnCuboTuttoDietro;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLIndiceDelPianoNonEsiste;
  end;

implementation

uses
  DelphiDoom.GlMath.Factory, DelphiDoom.Tests.GlMath.Golden, DelphiDoom.Tests.GlMath.Scenarios,
  DelphiDoom.Tests.GlMath.Subject;

{ TTestGlMathFrustum }

procedure TTestGlMathFrustum.Setup;
begin
  FFrustum := TGlMathFactory.CreateFrustum;
end;

procedure TTestGlMathFrustum.CalculateCamera;
var
  LProjection, LModelView: TGlMatrix4;
  LIndex: Integer;
begin
  // a camera at the origin that looks down the negative Z, 90 degrees of view, square screen
  for LIndex := 0 to 15 do
  begin
    LProjection[LIndex] := 0;
    LModelView[LIndex] := 0;
  end;
  LProjection[0] := 1;
  LProjection[5] := 1;
  LProjection[10] := -1.002;
  LProjection[11] := -1;
  LProjection[14] := -0.2002;
  LModelView[0] := 1;
  LModelView[5] := 1;
  LModelView[10] := 1;
  LModelView[15] := 1;
  FFrustum.Calculate(LProjection, LModelView);
end;

procedure TTestGlMathFrustum.DovrebbeDareLaStessaImprontaDelVecchioCodiceSuiPiani;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('frustum.planes', TGlMathScenarios.FrustumPlanes(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathFrustum.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuiPunti;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('frustum.points', TGlMathScenarios.FrustumPoints(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathFrustum.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuLeSfere;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('frustum.spheres', TGlMathScenarios.FrustumSpheres(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathFrustum.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuiParallelepipedi;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('frustum.boxes', TGlMathScenarios.FrustumBoxes(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathFrustum.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuiCubi;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('frustum.cubes', TGlMathScenarios.FrustumCubes(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathFrustum.DovrebbeNormalizzareIPianiPerchePerpendicolariUnitari;
var
  LSide: TGlFrustumSide;
  LLength: Double;
begin
  CalculateCamera;
  for LSide := Low(TGlFrustumSide) to High(TGlFrustumSide) do
  begin
    LLength := Sqr(FFrustum.GetPlane(LSide, 0)) + Sqr(FFrustum.GetPlane(LSide, 1)) +
      Sqr(FFrustum.GetPlane(LSide, 2));
    Assert.AreEqual(1.0, LLength, 0.0001);
  end;
end;

procedure TTestGlMathFrustum.DovrebbeContenereUnPuntoDavantiALCameraENonUnoDietro;
begin
  CalculateCamera;
  Assert.IsTrue(FFrustum.ContainsPoint(0, 0, -10));
  Assert.IsFalse(FFrustum.ContainsPoint(0, 0, 10));
end;

procedure TTestGlMathFrustum.DovrebbeEscludereUnPuntoFuoriDalCampoVisivo;
begin
  CalculateCamera;
  // 90 degrees: at a distance of 10 the view is 10 wide on each side
  Assert.IsTrue(FFrustum.ContainsPoint(9, 0, -10));
  Assert.IsFalse(FFrustum.ContainsPoint(11, 0, -10));
  Assert.IsFalse(FFrustum.ContainsPoint(0, -11, -10));
  Assert.IsFalse(FFrustum.ContainsPoint(0, 0, -2000));
end;

procedure TTestGlMathFrustum.DovrebbeContenereUnaSferaCheTocca;
begin
  CalculateCamera;
  Assert.IsFalse(FFrustum.ContainsSphere(20, 0, -10, 1));
  Assert.IsTrue(FFrustum.ContainsSphere(12, 0, -10, 5));
end;

procedure TTestGlMathFrustum.DovrebbeContenereUnParallelepipedoCheSiSovrappone;
begin
  CalculateCamera;
  // the box goes from (5, -1, -12) to (40, 1, -8): its corner at x = 5 is in the view
  Assert.IsTrue(FFrustum.ContainsBox(5, -1, -12, 40, 1, -8));
  Assert.IsFalse(FFrustum.ContainsBox(30, -1, -12, 60, 1, -8));
end;

procedure TTestGlMathFrustum.DovrebbeEscludereUnCuboTuttoDietro;
begin
  CalculateCamera;
  Assert.IsFalse(FFrustum.ContainsCube(0, 0, 20, 3));
  Assert.IsTrue(FFrustum.ContainsCube(0, 0, -20, 3));
end;

procedure TTestGlMathFrustum.DovrebbeSollevareUnErroreSeLIndiceDelPianoNonEsiste;
begin
  CalculateCamera;
  Assert.WillRaise(
    procedure
    begin
      FFrustum.GetPlane(fsLeft, 4);
    end, EGlMathException);
end;

end.
