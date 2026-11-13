{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the Single of the test series  }
{  that does not depend on the FPU                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Interpolation;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Models.ExactSingle;

type
  /// <summary>
  ///   TModelsExactSingle: the inputs of the golden series are the same Single on 32 and 64 bit.
  ///   The expected bits of the near-ties come from a computation with rational numbers (Perl,
  ///   Math::BigRat) on the exact value of the Double operands.
  /// </summary>
  [TestFixture]
  [Category('models')]
  TTestModelsInterpolation = class(TObject)
  strict private
    class function BitsOf(const AValue: Single): Integer; static;
  public
    [Test]
    procedure DovrebbeDareIValoriEsattiQuandoNonServeArrotondare;
    [Test]
    procedure DovrebbeDareGliEstremiConFrazioneZeroEUno;
    [Test]
    procedure DovrebbeDareLaStessaSingleDellaFpuA32BitSuiCasiQuasiPari;
    [Test]
    procedure DovrebbeUsareLaFrazioneIntera;
    [Test]
    procedure DovrebbeDareUnaSingleVicinaAlValoreEsattoSuMolteFrazioni;
  end;

implementation

uses
  System.SysUtils;

{ TTestModelsInterpolation }

class function TTestModelsInterpolation.BitsOf(const AValue: Single): Integer;
begin
  Result := PInteger(@AValue)^;
end;

procedure TTestModelsInterpolation.DovrebbeDareIValoriEsattiQuandoNonServeArrotondare;
begin
  Assert.AreEqual(0.5, TModelsExactSingle.Interpolate(0, 1, 0.5), 0.0);
  Assert.AreEqual(-2.5, TModelsExactSingle.Interpolate(-5, 5, 0.25), 0.0);
  Assert.AreEqual(12.0, TModelsExactSingle.Interpolate(10, 20, 0.2), 0.001);
end;

procedure TTestModelsInterpolation.DovrebbeDareGliEstremiConFrazioneZeroEUno;
begin
  Assert.AreEqual(-30.0, TModelsExactSingle.Interpolate(-30, 30, 0), 0.0);
  Assert.AreEqual(30.0, TModelsExactSingle.Interpolate(-30, 30, 1), 0.0);
  Assert.AreEqual(BitsOf(Single(0.2)), BitsOf(TModelsExactSingle.Interpolate(0.2, 3, 0)));
end;

procedure TTestModelsInterpolation.DovrebbeDareLaStessaSingleDellaFpuA32BitSuiCasiQuasiPari;
begin
  // the value is within 2^-59 of the middle of two Singles: the 64 bit FPU, that rounds the
  // product to a Double first, gives the other neighbour (regression: the md2.merges series)
  Assert.AreEqual(1071403937, BitsOf(TModelsExactSingle.Interpolate(0.2, 3, 2333550976 / 4294967296.0)));
  Assert.AreEqual(1068765847, BitsOf(TModelsExactSingle.Interpolate(0.2, 3, 1851157376 / 4294967296.0)));
  Assert.AreEqual(1070643940, BitsOf(TModelsExactSingle.Interpolate(0.2, 3, 2194580096 / 4294967296.0)));
end;

procedure TTestModelsInterpolation.DovrebbeUsareLaFrazioneIntera;
begin
  // the draw is a Cardinal over 2^32: the last one is just below 1
  Assert.IsTrue(TModelsExactSingle.Interpolate(0, 1, 4294967295 / 4294967296.0) <= 1.0);
  Assert.AreEqual(0.0, TModelsExactSingle.Interpolate(0, 1, 0), 0.0);
end;

procedure TTestModelsInterpolation.DovrebbeDareUnaSingleVicinaAlValoreEsattoSuMolteFrazioni;
var
  LIndex: Integer;
  LFraction: Double;
  LResult: Single;
  LExpected: Double;
begin
  for LIndex := 0 to 999 do
  begin
    LFraction := (Int64(LIndex) * 4294967) / 4294967296.0;
    LResult := TModelsExactSingle.Interpolate(-30, 30, LFraction);
    LExpected := -30 + 60 * LFraction;
    // within half a ULP of the Single (the value is a Double with some error)
    Assert.IsTrue(Abs(LResult - LExpected) <= 1.2e-6 * (1 + Abs(LExpected)), Format('i=%d', [LIndex]));
  end;
end;

end.
