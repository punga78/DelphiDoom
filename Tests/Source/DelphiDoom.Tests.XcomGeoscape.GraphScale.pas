{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom geoscape library - the scale of the       }
{  graphs (GraphsState)                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.GraphScale;

interface

uses
  DUnitX.TestFramework, DelphiDoom.XcomGeoscape.GraphScale;

type
  [TestFixture]
  [Category('xcom-geoscape')]
  TTestXcomGraphScale = class(TObject)
  public
    [Test]
    procedure DovrebbeDareNoveCelleDaDieciSenzaValori;
    [Test]
    procedure DovrebbeRaddoppiareLaCellaFinoAContenereIlMassimo;
    [Test]
    procedure DovrebbeScendereSottoZeroPerIValoriNegativi;
    [Test]
    procedure DovrebbePartireDaCinquantaPerIlReddito;
    [Test]
    procedure DovrebbePartireDaDuecentocinquantaPerLeFinanze;
    [Test]
    procedure DovrebbeMettereLoZeroSullaLineaDiBase;
    [Test]
    procedure DovrebbeDareLeEtichetteDellAsse;
    [Test]
    procedure DovrebbeTroncareLeAltezzeVersoZero;
  end;

implementation

procedure TTestXcomGraphScale.DovrebbeDareNoveCelleDaDieciSenzaValori;
var
  LScale: TXcomGraphScale;
begin
  LScale := TXcomGraphScale.Fit(0, 0, 10);
  Assert.AreEqual(0, LScale.LowerLimit);
  Assert.AreEqual(90, LScale.UpperLimit);
  Assert.AreEqual(90 / 126, LScale.Units, 1E-12);
end;

procedure TTestXcomGraphScale.DovrebbeRaddoppiareLaCellaFinoAContenereIlMassimo;
begin
  // 90 entra in nove celle da 10, 91 no: venti, e 181 ne vuole quaranta
  Assert.AreEqual(90, TXcomGraphScale.Fit(90, 0, 10).UpperLimit);
  Assert.AreEqual(180, TXcomGraphScale.Fit(91, 0, 10).UpperLimit);
  Assert.AreEqual(360, TXcomGraphScale.Fit(181, 0, 10).UpperLimit);
end;

procedure TTestXcomGraphScale.DovrebbeScendereSottoZeroPerIValoriNegativi;
var
  LScale: TXcomGraphScale;
begin
  // il -25 non sta in -20: la finestra scende di tre celle da 10 e tiene nove celle
  LScale := TXcomGraphScale.Fit(0, -25, 10);
  Assert.AreEqual(-30, LScale.LowerLimit);
  Assert.AreEqual(60, LScale.UpperLimit);
end;

procedure TTestXcomGraphScale.DovrebbePartireDaCinquantaPerIlReddito;
begin
  Assert.AreEqual(450, TXcomGraphScale.Fit(0, 0, 50).UpperLimit);
  Assert.AreEqual(900, TXcomGraphScale.Fit(451, 0, 50).UpperLimit);
end;

procedure TTestXcomGraphScale.DovrebbePartireDaDuecentocinquantaPerLeFinanze;
begin
  Assert.AreEqual(2250, TXcomGraphScale.Fit(1000, 0, 250).UpperLimit);
  Assert.AreEqual(4500, TXcomGraphScale.Fit(2251, 0, 250).UpperLimit);
end;

procedure TTestXcomGraphScale.DovrebbeMettereLoZeroSullaLineaDiBase;
begin
  Assert.AreEqual(175, TXcomGraphScale.Fit(0, 0, 10).BaseY);
  Assert.AreEqual(175, TXcomGraphScale.Fit(0, 0, 10).PointY(0));
end;

procedure TTestXcomGraphScale.DovrebbeDareLeEtichetteDellAsse;
var
  LScale: TXcomGraphScale;
  LIndex: Integer;
begin
  LScale := TXcomGraphScale.Fit(100, 0, 10);
  for LIndex := 0 to 9 do
    Assert.AreEqual(LIndex * 20, LScale.AxisLabel(LIndex));
  LScale := TXcomGraphScale.Fit(0, -25, 10);
  Assert.AreEqual(-30, LScale.AxisLabel(0));
  Assert.AreEqual(50, LScale.AxisLabel(8));
end;

procedure TTestXcomGraphScale.DovrebbeTroncareLeAltezzeVersoZero;
var
  LScale: TXcomGraphScale;
begin
  // 126 pixel per 180 unita': 1,4286 unita' per pixel; 10 / 1,4286 = 7,0 troncato, 1 sta sotto il pixel
  LScale := TXcomGraphScale.Fit(100, 0, 10);
  Assert.AreEqual(175, LScale.PointY(1));
  Assert.IsTrue(LScale.PointY(100) < 175 - 60);
  Assert.IsTrue(LScale.PointY(-100) > 175 + 60);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGraphScale);

end.
