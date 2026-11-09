{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .SCR pictures            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.ScrDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomScrDecoder = class(TObject)
  private
    FDecoder: IXcomImageDecoder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCopiareIPixelRigaPerRiga;
    [Test]
    procedure DovrebbeLasciareAZeroLaFineDiUnFileCorto;
    [Test]
    procedure DovrebbeIgnorareIByteOltreLImmagine;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeDecodificareUnoSchermoIntero;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomScrDecoder }

procedure TTestXcomScrDecoder.Setup;
begin
  FDecoder := TXcomFactory.CreateScrDecoder;
end;

procedure TTestXcomScrDecoder.TearDown;
begin
  FDecoder := nil;
end;

procedure TTestXcomScrDecoder.DovrebbeCopiareIPixelRigaPerRiga;
var
  LImage: TXcomImage;
begin
  LImage := FDecoder.Decode(TXcomTestBuilders.Bytes([1, 2, 3, 4, 5, 6]), 3, 2);
  Assert.AreEqual(3, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  Assert.AreEqual('01 02 03 04 05 06', TXcomTestBuilders.Pixels(LImage));
end;

procedure TTestXcomScrDecoder.DovrebbeLasciareAZeroLaFineDiUnFileCorto;
begin
  Assert.AreEqual('01 02 00 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([1, 2]), 2, 2)));
  Assert.AreEqual('00 00', TXcomTestBuilders.Pixels(FDecoder.Decode(nil, 2, 1)));
end;

procedure TTestXcomScrDecoder.DovrebbeIgnorareIByteOltreLImmagine;
begin
  Assert.AreEqual('01 02', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([1, 2, 3, 4]), 2, 1)));
end;

procedure TTestXcomScrDecoder.DovrebbeRifiutareUnaDimensioneNonValida;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(nil, 0, 0); end, EXcomException);
end;

procedure TTestXcomScrDecoder.DovrebbeDecodificareUnoSchermoIntero;
var
  LBytes: TBytes;
  LIndex: Integer;
  LImage: TXcomImage;
begin
  SetLength(LBytes, 320 * 200);
  for LIndex := 0 to High(LBytes) do
    LBytes[LIndex] := Byte(LIndex);
  LImage := FDecoder.Decode(LBytes, 320, 200);
  Assert.AreEqual(320 * 200, Integer(Length(LImage.Pixels)));
  Assert.AreEqual(Integer(Byte(320 * 199 + 5)), Integer(LImage.GetPixel(5, 199)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomScrDecoder);

end.
