{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the plane through three points                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.PlaneMath;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Apply.Types;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfPlaneMath = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlPianoOrizzontaleSeLeAltezzeSonoUguali;
    [Test]
    procedure DovrebbeDareIlPianoInclinatoLungoX;
    [Test]
    procedure DovrebbeFarPassareIlPianoPerITrePunti;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVecchioCalcSlopePlane;
  end;

implementation

uses
  DelphiDoom.Udmf.Apply.PlaneMath;

// the code of calc_slope_plane of the engine, as it was before the port
procedure OldCalcSlopePlane(const x1, y1, z1, x2, y2, z2, x3, y3, z3: Single;
  out fa, fb, fc, fd: Single);
var
  a1, b1, c1: Single;
  a2, b2, c2: Single;
begin
  a1 := x2 - x1;
  b1 := y2 - y1;
  c1 := z2 - z1;
  a2 := x3 - x1;
  b2 := y3 - y1;
  c2 := z3 - z1;
  fa := b1 * c2 - b2 * c1;
  fb := a2 * c1 - a1 * c2;
  fc := a1 * b2 - b1 * a2;
  fd := (- fa * x1 - fb * y1 - fc * z1);
end;

{ TTestUdmfPlaneMath }

procedure TTestUdmfPlaneMath.DovrebbeDareIlPianoOrizzontaleSeLeAltezzeSonoUguali;
var
  LPlane: TUdmfPlane;
begin
  LPlane := TUdmfPlaneMath.ThroughPoints(0, 0, 32, 64, 0, 32, 0, 64, 32);
  Assert.AreEqual(Single(0), LPlane.A);
  Assert.AreEqual(Single(0), LPlane.B);
  Assert.AreEqual(Single(1 / 4096), LPlane.InverseC);
  Assert.AreEqual(Single(-131072), LPlane.D);
end;

procedure TTestUdmfPlaneMath.DovrebbeDareIlPianoInclinatoLungoX;
var
  LPlane: TUdmfPlane;
begin
  // z = x / 2: the plane is -2048 x + 0 y + 4096 z + 0 = 0
  LPlane := TUdmfPlaneMath.ThroughPoints(0, 0, 0, 64, 0, 32, 0, 64, 0);
  Assert.AreEqual(Single(-2048), LPlane.A);
  Assert.AreEqual(Single(0), LPlane.B);
  Assert.AreEqual(Single(1 / 4096), LPlane.InverseC);
  Assert.AreEqual(Single(0), LPlane.D);
end;

procedure TTestUdmfPlaneMath.DovrebbeFarPassareIlPianoPerITrePunti;
var
  LPlane: TUdmfPlane;
  LC: Double;
begin
  LPlane := TUdmfPlaneMath.ThroughPoints(10, 20, 8, 110, 30, 40, 50, 140, -16);
  LC := 1 / LPlane.InverseC;
  Assert.AreEqual(0.0, LPlane.A * 10 + LPlane.B * 20 + LC * 8 + LPlane.D, 0.5);
  Assert.AreEqual(0.0, LPlane.A * 110 + LPlane.B * 30 + LC * 40 + LPlane.D, 0.5);
  Assert.AreEqual(0.0, LPlane.A * 50 + LPlane.B * 140 + LC * -16 + LPlane.D, 0.5);
end;

procedure TTestUdmfPlaneMath.DovrebbeDareLeStesseRisposteDelVecchioCalcSlopePlane;
var
  LIndex: Integer;
  LPlane: TUdmfPlane;
  LA, LB, LC, LD: Single;
  LX1, LY1, LZ1, LX2, LY2, LZ2, LX3, LY3, LZ3: Single;
begin
  RandSeed := 1234;
  for LIndex := 1 to 5000 do
  begin
    LX1 := Random(2000) - 1000 + Random(4) / 4;
    LY1 := Random(2000) - 1000 + Random(4) / 4;
    LZ1 := Random(600) - 300 + Random(4) / 4;
    LX2 := Random(2000) - 1000;
    LY2 := Random(2000) - 1000;
    LZ2 := Random(600) - 300;
    LX3 := Random(2000) - 1000;
    LY3 := Random(2000) - 1000;
    LZ3 := Random(600) - 300 + Random(8) / 8;
    OldCalcSlopePlane(LX1, LY1, LZ1, LX2, LY2, LZ2, LX3, LY3, LZ3, LA, LB, LC, LD);
    if LC = 0 then
      Continue;
    LPlane := TUdmfPlaneMath.ThroughPoints(LX1, LY1, LZ1, LX2, LY2, LZ2, LX3, LY3, LZ3);
    Assert.AreEqual(LA, LPlane.A);
    Assert.AreEqual(LB, LPlane.B);
    Assert.AreEqual(Single(1 / LC), LPlane.InverseC);
    Assert.AreEqual(LD, LPlane.D);
  end;
end;

end.
