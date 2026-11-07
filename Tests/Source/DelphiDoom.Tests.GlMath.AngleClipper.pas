{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL math library - the clipper of angles        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GlMath.AngleClipper;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GlMath.Types, DelphiDoom.GlMath.Intf;

type
  /// <summary>Parity with the old gl_clipper (golden file glmath.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('glmath')]
  TTestGlMathAngleClipper = class(TObject)
  strict private
    FClipper: IGlAngleClipper;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeSeguireLeSequenzeDelVecchioClipper;
    [Test]
    procedure DovrebbeVedereTuttoSeLaListaELaVuota;
    [Test]
    procedure DovrebbeNascondereUnIntervalloGiaAggiunto;
    [Test]
    procedure DovrebbeVedereUnIntervalloSoloInParteNascosto;
    [Test]
    procedure DovrebbeUnireGliIntervalliCheSiSovrappongono;
    [Test]
    procedure DovrebbeTenereOrdinatiGliIntervalliDisgiunti;
    [Test]
    procedure DovrebbeAssorbireGliIntervalliContenutiInUnoPiuGrande;
    [Test]
    procedure DovrebbeAggiungereInDueParteUnIntervalloCheAttraversaLoZero;
    [Test]
    procedure DovrebbeControllareInDueParteUnIntervalloCheAttraversaLoZero;
    [Test]
    procedure DovrebbeSvuotareLaListaConClear;
    [Test]
    procedure DovrebbeRiusareLaMemoriaDopoClear;
    [Test]
    procedure DovrebbeSvuotareLaListaConRelease;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlNumeroDellIntervalloNonEsiste;
  end;

implementation

uses
  DelphiDoom.GlMath.Factory, DelphiDoom.Tests.GlMath.Golden, DelphiDoom.Tests.GlMath.Scenarios,
  DelphiDoom.Tests.GlMath.Subject;

{ TTestGlMathAngleClipper }

procedure TTestGlMathAngleClipper.Setup;
begin
  FClipper := TGlMathFactory.CreateAngleClipper;
end;

procedure TTestGlMathAngleClipper.DovrebbeSeguireLeSequenzeDelVecchioClipper;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('glmath.golden.txt');
  try
    LGolden.Check('clipper.sequences', TGlMathScenarios.ClipperSequences(TGlMathSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGlMathAngleClipper.DovrebbeVedereTuttoSeLaListaELaVuota;
begin
  Assert.IsTrue(FClipper.SafeCheckRange(100, 200));
  Assert.IsTrue(FClipper.SafeCheckRange(0, GLMATH_ANGLE_MAX));
  Assert.AreEqual(0, FClipper.GetRangeCount);
end;

procedure TTestGlMathAngleClipper.DovrebbeNascondereUnIntervalloGiaAggiunto;
begin
  FClipper.SafeAddRange(100, 200);
  Assert.IsFalse(FClipper.SafeCheckRange(100, 200));
  Assert.IsFalse(FClipper.SafeCheckRange(120, 150));
  Assert.AreEqual(1, FClipper.GetRangeCount);
  Assert.AreEqual<Cardinal>(100, FClipper.GetRangeStart(0));
  Assert.AreEqual<Cardinal>(200, FClipper.GetRangeFinish(0));
end;

procedure TTestGlMathAngleClipper.DovrebbeVedereUnIntervalloSoloInParteNascosto;
begin
  FClipper.SafeAddRange(100, 200);
  Assert.IsTrue(FClipper.SafeCheckRange(50, 150));
  Assert.IsTrue(FClipper.SafeCheckRange(150, 250));
  Assert.IsTrue(FClipper.SafeCheckRange(300, 400));
end;

procedure TTestGlMathAngleClipper.DovrebbeUnireGliIntervalliCheSiSovrappongono;
begin
  FClipper.SafeAddRange(100, 200);
  FClipper.SafeAddRange(150, 300);
  Assert.AreEqual(1, FClipper.GetRangeCount);
  Assert.AreEqual<Cardinal>(100, FClipper.GetRangeStart(0));
  Assert.AreEqual<Cardinal>(300, FClipper.GetRangeFinish(0));
  Assert.IsFalse(FClipper.SafeCheckRange(120, 280));
end;

procedure TTestGlMathAngleClipper.DovrebbeTenereOrdinatiGliIntervalliDisgiunti;
begin
  FClipper.SafeAddRange(500, 600);
  FClipper.SafeAddRange(100, 200);
  FClipper.SafeAddRange(300, 400);
  Assert.AreEqual(3, FClipper.GetRangeCount);
  Assert.AreEqual<Cardinal>(100, FClipper.GetRangeStart(0));
  Assert.AreEqual<Cardinal>(300, FClipper.GetRangeStart(1));
  Assert.AreEqual<Cardinal>(500, FClipper.GetRangeStart(2));
  Assert.AreEqual<Cardinal>(600, FClipper.GetRangeFinish(2));
end;

procedure TTestGlMathAngleClipper.DovrebbeAssorbireGliIntervalliContenutiInUnoPiuGrande;
begin
  FClipper.SafeAddRange(100, 200);
  FClipper.SafeAddRange(300, 400);
  FClipper.SafeAddRange(50, 450);
  Assert.AreEqual(1, FClipper.GetRangeCount);
  Assert.AreEqual<Cardinal>(50, FClipper.GetRangeStart(0));
  Assert.AreEqual<Cardinal>(450, FClipper.GetRangeFinish(0));
end;

procedure TTestGlMathAngleClipper.DovrebbeAggiungereInDueParteUnIntervalloCheAttraversaLoZero;
begin
  FClipper.SafeAddRange(GLMATH_ANGLE_MAX - 99, 100);
  Assert.AreEqual(2, FClipper.GetRangeCount);
  Assert.AreEqual<Cardinal>(0, FClipper.GetRangeStart(0));
  Assert.AreEqual<Cardinal>(100, FClipper.GetRangeFinish(0));
  Assert.AreEqual<Cardinal>(GLMATH_ANGLE_MAX - 99, FClipper.GetRangeStart(1));
  Assert.AreEqual<Cardinal>(GLMATH_ANGLE_MAX, FClipper.GetRangeFinish(1));
end;

procedure TTestGlMathAngleClipper.DovrebbeControllareInDueParteUnIntervalloCheAttraversaLoZero;
begin
  FClipper.SafeAddRange(GLMATH_ANGLE_MAX - 99, 100);
  Assert.IsFalse(FClipper.SafeCheckRange(GLMATH_ANGLE_MAX - 50, 50));
  // a range that is hidden only on one side of the zero is still visible
  FClipper.Clear;
  FClipper.SafeAddRange(0, 100);
  Assert.IsTrue(FClipper.SafeCheckRange(GLMATH_ANGLE_MAX - 50, 50));
end;

procedure TTestGlMathAngleClipper.DovrebbeSvuotareLaListaConClear;
begin
  FClipper.SafeAddRange(100, 200);
  FClipper.Clear;
  Assert.AreEqual(0, FClipper.GetRangeCount);
  Assert.IsTrue(FClipper.SafeCheckRange(100, 200));
end;

procedure TTestGlMathAngleClipper.DovrebbeRiusareLaMemoriaDopoClear;
var
  LStep, LIndex: Integer;
begin
  // many frames with the same ranges: the nodes freed by Clear are used again
  for LStep := 1 to 50 do
  begin
    FClipper.Clear;
    for LIndex := 0 to 99 do
      FClipper.SafeAddRange(LIndex * 1000, LIndex * 1000 + 500);
    Assert.AreEqual(100, FClipper.GetRangeCount);
  end;
  Assert.AreEqual<Cardinal>(99000, FClipper.GetRangeStart(99));
end;

procedure TTestGlMathAngleClipper.DovrebbeSvuotareLaListaConRelease;
begin
  FClipper.SafeAddRange(100, 200);
  FClipper.Release;
  Assert.AreEqual(0, FClipper.GetRangeCount);
  FClipper.SafeAddRange(300, 400);
  Assert.AreEqual(1, FClipper.GetRangeCount);
  Assert.AreEqual<Cardinal>(300, FClipper.GetRangeStart(0));
end;

procedure TTestGlMathAngleClipper.DovrebbeSollevareUnErroreSeIlNumeroDellIntervalloNonEsiste;
begin
  FClipper.SafeAddRange(100, 200);
  Assert.WillRaise(
    procedure
    begin
      FClipper.GetRangeStart(1);
    end, EGlMathException);
  Assert.WillRaise(
    procedure
    begin
      FClipper.GetRangeFinish(-1);
    end, EGlMathException);
end;

end.
