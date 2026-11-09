{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingMath                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Math;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingMath = class(TObject)
  public
    [Test]
    procedure DovrebbeTenereUnValoreNelIntervallo;
    [Test]
    procedure DovrebbeAccettareGliEstremiInQualsiasiOrdine;
    [Test]
    procedure DovrebbeDareIlSegno;
    [Test]
    procedure DovrebbeDareIlMinimo;
    [Test]
    procedure DovrebbeCalcolareLaDistanzaEsatta;
    [Test]
    procedure DovrebbeDareZeroPerUnVettoreNullo;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Math;

{ TTestRacingMath }

procedure TTestRacingMath.DovrebbeTenereUnValoreNelIntervallo;
begin
  Assert.AreEqual(3, TRacingMath.Clamp(5, 0, 3));
  Assert.AreEqual(0, TRacingMath.Clamp(-5, 0, 3));
  Assert.AreEqual(2, TRacingMath.Clamp(2, 0, 3));
end;

procedure TTestRacingMath.DovrebbeAccettareGliEstremiInQualsiasiOrdine;
begin
  Assert.IsTrue(TRacingMath.IsInRange(5, 1, 10));
  Assert.IsTrue(TRacingMath.IsInRange(5, 10, 1));
  Assert.IsTrue(TRacingMath.IsInRange(10, 10, 1));
  Assert.IsFalse(TRacingMath.IsInRange(11, 10, 1));
  Assert.IsFalse(TRacingMath.IsInRange(0, 1, 10));
end;

procedure TTestRacingMath.DovrebbeDareIlSegno;
begin
  Assert.AreEqual(1, TRacingMath.Sign(77));
  Assert.AreEqual(-1, TRacingMath.Sign(-77));
  Assert.AreEqual(0, TRacingMath.Sign(0));
end;

procedure TTestRacingMath.DovrebbeDareIlMinimo;
begin
  Assert.AreEqual(2, TRacingMath.Minimum(2, 9));
  Assert.AreEqual(2, TRacingMath.Minimum(9, 2));
end;

procedure TTestRacingMath.DovrebbeCalcolareLaDistanzaEsatta;
begin
  Assert.AreEqual(5 * FIXED_ONE, TRacingMath.Distance(3 * FIXED_ONE, 4 * FIXED_ONE));
  Assert.AreEqual(5 * FIXED_ONE, TRacingMath.Distance(-3 * FIXED_ONE, -4 * FIXED_ONE));
end;

procedure TTestRacingMath.DovrebbeDareZeroPerUnVettoreNullo;
begin
  Assert.AreEqual(0, TRacingMath.Distance(0, 0));
end;

end.
