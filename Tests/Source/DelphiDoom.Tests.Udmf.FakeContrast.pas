{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the fake contrast of a wall                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.FakeContrast;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Apply.Intf;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfFakeContrast = class(TObject)
  private
    FContrast: IUdmfFakeContrast;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareMenoUnoPerUnMuroOrizzontale;
    [Test]
    procedure DovrebbeDareUnoPerUnMuroVerticale;
    [Test]
    procedure DovrebbeDareZeroPerUnMuroInclinato;
    [Test]
    procedure DovrebbeDareZeroSeIlLatoNonVuoleIlContrasto;
    [Test]
    procedure DovrebbeDareMenoUnoPerUnMuroDiLunghezzaZero;
  end;

implementation

uses
  DelphiDoom.Udmf.Apply.Factory;

{ TTestUdmfFakeContrast }

procedure TTestUdmfFakeContrast.Setup;
begin
  FContrast := TUdmfApplyFactory.CreateFakeContrast;
end;

procedure TTestUdmfFakeContrast.TearDown;
begin
  FContrast := nil;
end;

procedure TTestUdmfFakeContrast.DovrebbeDareMenoUnoPerUnMuroOrizzontale;
begin
  Assert.AreEqual(-1, FContrast.Calculate(False, 0, 64, 128, 64));
end;

procedure TTestUdmfFakeContrast.DovrebbeDareUnoPerUnMuroVerticale;
begin
  Assert.AreEqual(1, FContrast.Calculate(False, 64, 0, 64, 128));
end;

procedure TTestUdmfFakeContrast.DovrebbeDareZeroPerUnMuroInclinato;
begin
  Assert.AreEqual(0, FContrast.Calculate(False, 0, 0, 128, 64));
end;

procedure TTestUdmfFakeContrast.DovrebbeDareZeroSeIlLatoNonVuoleIlContrasto;
begin
  Assert.AreEqual(0, FContrast.Calculate(True, 0, 64, 128, 64));
  Assert.AreEqual(0, FContrast.Calculate(True, 64, 0, 64, 128));
end;

procedure TTestUdmfFakeContrast.DovrebbeDareMenoUnoPerUnMuroDiLunghezzaZero;
begin
  // the horizontal test comes first, as in the engine
  Assert.AreEqual(-1, FContrast.Calculate(False, 5, 5, 5, 5));
end;

end.
