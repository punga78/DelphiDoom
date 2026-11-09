{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .SPK pictures            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.SpkDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomSpkDecoder = class(TObject)
  private
    FDecoder: IXcomImageDecoder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDecodificareUnaSequenzaDiPixel;
    [Test]
    procedure DovrebbeDecodificareUnaSequenzaDiPixelVuoti;
    [Test]
    procedure DovrebbeIgnorareUnaParolaChePartePiuTardi;
    [Test]
    procedure DovrebbeRipetereLUltimoByteSeIlFileFinisceNellaSequenza;
    [Test]
    procedure DovrebbeUsareIlByteBassoDellaParolaTroncata;
    [Test]
    procedure DovrebbeIgnorareIPixelOltreLImmagine;
    [Test]
    procedure DovrebbeDareUnImmagineVuotaPerUnFileVuoto;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomSpkDecoder }

procedure TTestXcomSpkDecoder.Setup;
begin
  FDecoder := TXcomFactory.CreateSpkDecoder;
end;

procedure TTestXcomSpkDecoder.TearDown;
begin
  FDecoder := nil;
end;

procedure TTestXcomSpkDecoder.DovrebbeDecodificareUnaSequenzaDiPixel;
begin
  // 65534, 2: four pixels follow (the count is in pairs)
  Assert.AreEqual('01 02 03 04 00 00 00 00',
    TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FE, $FF, 2, 0, 1, 2, 3, 4]), 4, 2)));
end;

procedure TTestXcomSpkDecoder.DovrebbeDecodificareUnaSequenzaDiPixelVuoti;
begin
  Assert.AreEqual('00 00 05 00',
    TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FF, $FF, 1, 0, $FE, $FF, 1, 0, 5, 0]), 4, 1)));
end;

procedure TTestXcomSpkDecoder.DovrebbeIgnorareUnaParolaChePartePiuTardi;
begin
  Assert.AreEqual('07 08',
    TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$12, $34, $FE, $FF, 1, 0, 7, 8]), 2, 1)));
end;

procedure TTestXcomSpkDecoder.DovrebbeRipetereLUltimoByteSeIlFileFinisceNellaSequenza;
begin
  // two pixels were promised and one byte is there: the second is the same value (as the C++ does)
  Assert.AreEqual('07 07', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FE, $FF, 1, 0, 7]), 2, 1)));
end;

procedure TTestXcomSpkDecoder.DovrebbeUsareIlByteBassoDellaParolaTroncata;
begin
  // the count word has only one byte: it takes it as the low byte and keeps the high one (FF): 0xFF03 * 2 pixels
  Assert.AreEqual('00 00 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FE, $FF, 3]), 3, 1)));
end;

procedure TTestXcomSpkDecoder.DovrebbeIgnorareIPixelOltreLImmagine;
begin
  Assert.AreEqual('01 02', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FE, $FF, 2, 0, 1, 2, 3, 4]), 2, 1)));
end;

procedure TTestXcomSpkDecoder.DovrebbeDareUnImmagineVuotaPerUnFileVuoto;
begin
  Assert.AreEqual('00 00', TXcomTestBuilders.Pixels(FDecoder.Decode(nil, 2, 1)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomSpkDecoder);

end.
