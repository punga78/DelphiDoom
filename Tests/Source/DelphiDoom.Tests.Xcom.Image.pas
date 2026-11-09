{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the image                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Image;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomImage = class(TObject)
  public
    [Test]
    procedure DovrebbeCrearePixelATuttiZeroESenzaPalette;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeScrivereEDareUnPixel;
    [Test]
    procedure DovrebbeIgnorareUnPixelFuoriDallImmagine;
    [Test]
    procedure DovrebbeDareZeroPerUnPixelFuoriDallImmagine;
    [Test]
    procedure DovrebbeAndareACapoConSetPixelIterative;
    [Test]
    procedure DovrebbeIgnorareLeRigheOltreLUltima;
  end;

implementation

{ TTestXcomImage }

procedure TTestXcomImage.DovrebbeCrearePixelATuttiZeroESenzaPalette;
var
  LImage: TXcomImage;
  LByte: Byte;
begin
  LImage := TXcomImage.Create(3, 2);
  Assert.AreEqual(3, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  Assert.AreEqual(6, Integer(Length(LImage.Pixels)));
  Assert.IsFalse(LImage.HasPalette);
  for LByte in LImage.Pixels do
    Assert.AreEqual(0, Integer(LByte));
end;

procedure TTestXcomImage.DovrebbeRifiutareUnaDimensioneNonValida;
begin
  Assert.WillRaise(procedure begin TXcomImage.Create(0, 5); end, EXcomException);
  Assert.WillRaise(procedure begin TXcomImage.Create(5, -1); end, EXcomException);
  Assert.WillRaise(procedure begin TXcomImage.Create(100000, 100000); end, EXcomException);
end;

procedure TTestXcomImage.DovrebbeScrivereEDareUnPixel;
var
  LImage: TXcomImage;
begin
  LImage := TXcomImage.Create(3, 2);
  LImage.SetPixel(2, 1, 77);
  Assert.AreEqual(77, Integer(LImage.GetPixel(2, 1)));
  Assert.AreEqual(77, Integer(LImage.Pixels[5]));
end;

procedure TTestXcomImage.DovrebbeIgnorareUnPixelFuoriDallImmagine;
var
  LImage: TXcomImage;
  LByte: Byte;
begin
  LImage := TXcomImage.Create(2, 2);
  LImage.SetPixel(-1, 0, 9);
  LImage.SetPixel(2, 0, 9);
  LImage.SetPixel(0, -1, 9);
  LImage.SetPixel(0, 2, 9);
  for LByte in LImage.Pixels do
    Assert.AreEqual(0, Integer(LByte));
end;

procedure TTestXcomImage.DovrebbeDareZeroPerUnPixelFuoriDallImmagine;
var
  LImage: TXcomImage;
begin
  LImage := TXcomImage.Create(2, 2);
  LImage.SetPixel(1, 1, 5);
  Assert.AreEqual(0, Integer(LImage.GetPixel(2, 1)));
  Assert.AreEqual(0, Integer(LImage.GetPixel(1, 2)));
  Assert.AreEqual(0, Integer(LImage.GetPixel(-1, 1)));
  Assert.AreEqual(0, Integer(LImage.GetPixel(1, -1)));
end;

procedure TTestXcomImage.DovrebbeAndareACapoConSetPixelIterative;
var
  LImage: TXcomImage;
  LX: Integer;
  LY: Integer;
begin
  LImage := TXcomImage.Create(2, 2);
  LX := 0;
  LY := 0;
  LImage.SetPixelIterative(LX, LY, 1);
  Assert.AreEqual(1, LX);
  Assert.AreEqual(0, LY);
  LImage.SetPixelIterative(LX, LY, 2);
  Assert.AreEqual(0, LX);
  Assert.AreEqual(1, LY);
  Assert.AreEqual(1, Integer(LImage.GetPixel(0, 0)));
  Assert.AreEqual(2, Integer(LImage.GetPixel(1, 0)));
end;

procedure TTestXcomImage.DovrebbeIgnorareLeRigheOltreLUltima;
var
  LImage: TXcomImage;
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  LImage := TXcomImage.Create(2, 1);
  LX := 0;
  LY := 0;
  for LIndex := 1 to 6 do
    LImage.SetPixelIterative(LX, LY, 9);
  Assert.AreEqual(3, LY);
  Assert.AreEqual(2, Integer(Length(LImage.Pixels)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomImage);

end.
