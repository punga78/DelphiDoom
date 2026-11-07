{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL math library - the angle of the view        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GlMath.ViewAngle;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>Parity with the old gld_FrustumAngle (golden file glmath.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('glmath')]
  TTestGlMathViewAngle = class(TObject)
  public
    [Test]
    procedure DovrebbeDareGliStessiAngoliDelVecchioCodice;
    [Test]
    procedure DovrebbeVedereTuttoIntornoSeSiGuardaMoltoInAltoOInBasso;
    [Test]
    procedure DovrebbeDareLoStessoAngoloGuardandoInAltoOInBasso;
    [Test]
    procedure DovrebbeAumentareLAngoloConLaLarghezzaDelloSchermo;
    [Test]
    procedure DovrebbeDareCirca47GradiConLoSchermoQuadratoEIlViso;
  end;

implementation

uses
  DelphiDoom.GlMath.Types, DelphiDoom.GlMath.ViewAngle, DelphiDoom.Tests.GlMath.Golden,
  DelphiDoom.Tests.GlMath.Scenarios, DelphiDoom.Tests.GlMath.Subject;

{ TTestGlMathViewAngle }

procedure TTestGlMathViewAngle.DovrebbeDareGliStessiAngoliDelVecchioCodice;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('viewangle.sweep', TGlMathScenarios.ViewAngles(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathViewAngle.DovrebbeVedereTuttoIntornoSeSiGuardaMoltoInAltoOInBasso;
begin
  // the look direction is in 1/32 of a degree: over 46 degrees the whole circle is kept
  Assert.AreEqual<Cardinal>(GLMATH_ANGLE_MAX, TGlViewAngle.FrustumAngle(47 * 32, 1.0));
  Assert.AreEqual<Cardinal>(GLMATH_ANGLE_MAX, TGlViewAngle.FrustumAngle(-47 * 32, 1.0));
end;

procedure TTestGlMathViewAngle.DovrebbeDareLoStessoAngoloGuardandoInAltoOInBasso;
begin
  Assert.AreEqual(TGlViewAngle.FrustumAngle(640, 1.0), TGlViewAngle.FrustumAngle(-640, 1.0));
end;

procedure TTestGlMathViewAngle.DovrebbeAumentareLAngoloConLaLarghezzaDelloSchermo;
begin
  Assert.IsTrue(TGlViewAngle.FrustumAngle(0, 1.0) < TGlViewAngle.FrustumAngle(0, 1.5));
end;

procedure TTestGlMathViewAngle.DovrebbeDareCirca47GradiConLoSchermoQuadratoEIlViso;
var
  LDegrees: Double;
begin
  // straight ahead and aspect 1: 2 + 45 = 47 degrees
  LDegrees := TGlViewAngle.FrustumAngle(0, 1.0) / GLMATH_ANG1;
  Assert.AreEqual(47.0, LDegrees, 0.001);
end;

end.
