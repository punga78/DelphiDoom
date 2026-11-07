{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the rotation of the points       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Rotation;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapRotation = class(TObject)
  public
    [Test]
    procedure DovrebbeLasciareIlCentroDoveEra;
    [Test]
    procedure DovrebbeRuotareDiUnQuartoDiGiro;
    [Test]
    procedure DovrebbeRuotareIntornoAUnCentro;
    [Test]
    procedure DovrebbeRuotareDiMezzoGiro;
    [Test]
    procedure DovrebbeRuotareInVirgolaMobileDiUnQuartoDiGiro;
    [Test]
    procedure DovrebbeLasciareIlCentroDoveEraInVirgolaMobile;
    [Test]
    procedure DovrebbeNonRuotareConAngoloZeroInVirgolaMobile;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Automap.Rotation;

const
  // the tables of the fixed angles are sampled at the middle of each angle (0.5 / 65536 of a turn):
  // the cosine of 90 degrees is about -3 / 65536, so a result is off by a few hundredths of a unit
  TOLERANCE = 400;

{ TTestAutomapRotation }

procedure TTestAutomapRotation.DovrebbeLasciareIlCentroDoveEra;
var
  LX, LY: TFixed;
begin
  LX := 123456;
  LY := -654321;
  TAutomapRotation.Rotate(LX, LY, $12345678, LX, LY);
  Assert.AreEqual(123456, LX);
  Assert.AreEqual(-654321, LY);
end;

procedure TTestAutomapRotation.DovrebbeRuotareDiUnQuartoDiGiro;
var
  LX, LY: TFixed;
begin
  LX := 100 * FIXED_ONE;
  LY := 0;
  TAutomapRotation.Rotate(LX, LY, ANG90, 0, 0);
  Assert.IsTrue(Abs(LX) <= TOLERANCE, 'x ' + IntToStr(LX));
  Assert.IsTrue(Abs(LY - 100 * FIXED_ONE) <= TOLERANCE, 'y ' + IntToStr(LY));
end;

procedure TTestAutomapRotation.DovrebbeRuotareDiMezzoGiro;
var
  LX, LY: TFixed;
begin
  LX := 100 * FIXED_ONE;
  LY := 50 * FIXED_ONE;
  TAutomapRotation.Rotate(LX, LY, ANG180, 0, 0);
  Assert.IsTrue(Abs(LX + 100 * FIXED_ONE) <= TOLERANCE, 'x ' + IntToStr(LX));
  Assert.IsTrue(Abs(LY + 50 * FIXED_ONE) <= TOLERANCE, 'y ' + IntToStr(LY));
end;

procedure TTestAutomapRotation.DovrebbeRuotareIntornoAUnCentro;
var
  LX, LY: TFixed;
begin
  // (110, 50) turned by 90 degrees around (100, 50) goes to (100, 60)
  LX := 110 * FIXED_ONE;
  LY := 50 * FIXED_ONE;
  TAutomapRotation.Rotate(LX, LY, ANG90, 100 * FIXED_ONE, 50 * FIXED_ONE);
  Assert.IsTrue(Abs(LX - 100 * FIXED_ONE) <= TOLERANCE, 'x ' + IntToStr(LX));
  Assert.IsTrue(Abs(LY - 60 * FIXED_ONE) <= TOLERANCE, 'y ' + IntToStr(LY));
end;

procedure TTestAutomapRotation.DovrebbeRuotareInVirgolaMobileDiUnQuartoDiGiro;
var
  LX, LY: TFixed;
begin
  LX := 100000;
  LY := 0;
  TAutomapRotation.RotateExact(LX, LY, ANG90, 0, 0);
  Assert.AreEqual(0, LX);
  Assert.AreEqual(100000, LY);
end;

procedure TTestAutomapRotation.DovrebbeLasciareIlCentroDoveEraInVirgolaMobile;
var
  LX, LY: TFixed;
begin
  LX := 4242;
  LY := -2424;
  TAutomapRotation.RotateExact(LX, LY, $9ABCDEF0, LX, LY);
  Assert.AreEqual(4242, LX);
  Assert.AreEqual(-2424, LY);
end;

procedure TTestAutomapRotation.DovrebbeNonRuotareConAngoloZeroInVirgolaMobile;
var
  LX, LY: TFixed;
begin
  LX := 777;
  LY := -888;
  TAutomapRotation.RotateExact(LX, LY, 0, 10, 20);
  Assert.AreEqual(777, LX);
  Assert.AreEqual(-888, LY);
end;

end.
