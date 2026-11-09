{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .PCK and .TAB files      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.PckDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomPckDecoder = class(TObject)
  private
    FDecoder: IXcomPckDecoder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDecodificarePixelETrasparenze;
    [Test]
    procedure DovrebbeSaltareLeRigheVuoteDellInizio;
    [Test]
    procedure DovrebbeTrattareIlPrimoByteComeRigheVuoteEAnche255;
    [Test]
    procedure DovrebbeContareIFotogrammiDaUnTabA32Bit;
    [Test]
    procedure DovrebbeContareIFotogrammiDaUnTabA16Bit;
    [Test]
    procedure DovrebbeFarUnFotogrammaSenzaTab;
    [Test]
    procedure DovrebbeLasciareVuotiIFotogrammiCheIlPckNonHa;
    [Test]
    procedure DovrebbeIgnorareIPixelOltreLImmagine;
    [Test]
    procedure DovrebbeRifiutareUnTabTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnTabCheDaTroppiFotogrammi;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeDareIlNumeroDiFotogrammi;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Xcom.PckDecoder, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomPckDecoder }

procedure TTestXcomPckDecoder.Setup;
begin
  FDecoder := TXcomFactory.CreatePckDecoder;
end;

procedure TTestXcomPckDecoder.TearDown;
begin
  FDecoder := nil;
end;

procedure TTestXcomPckDecoder.DovrebbeDecodificarePixelETrasparenze;
var
  LFrames: TArray<TXcomImage>;
begin
  // 0 empty rows, pixels 1 2, 254 2 = two empty pixels, 3, end of the frame
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([0, 1, 2, 254, 2, 3, 255]), TXcomTestBuilders.Bytes([0, 0, 0, 0]), 4, 2);
  Assert.AreEqual(1, Integer(Length(LFrames)));
  Assert.AreEqual('01 02 00 00 03 00 00 00', TXcomTestBuilders.Pixels(LFrames[0]));
end;

procedure TTestXcomPckDecoder.DovrebbeSaltareLeRigheVuoteDellInizio;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([1, 9, 255]), TXcomTestBuilders.Bytes([0, 0, 0, 0]), 4, 2);
  Assert.AreEqual('00 00 00 00 09 00 00 00', TXcomTestBuilders.Pixels(LFrames[0]));
end;

procedure TTestXcomPckDecoder.DovrebbeTrattareIlPrimoByteComeRigheVuoteEAnche255;
var
  LFrames: TArray<TXcomImage>;
begin
  // the first byte of a frame is a number of rows even when it is 255 (it does not end the frame)
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([255, 5, 255]), TXcomTestBuilders.Bytes([0, 0, 0, 0]), 2, 1);
  Assert.AreEqual('00 00', TXcomTestBuilders.Pixels(LFrames[0]));
end;

procedure TTestXcomPckDecoder.DovrebbeContareIFotogrammiDaUnTabA32Bit;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([0, 1, 255, 0, 2, 255, 0, 3, 255]),
    TXcomTestBuilders.Bytes([0, 0, 0, 0, 3, 0, 0, 0, 6, 0, 0, 0]), 2, 1);
  Assert.AreEqual(3, Integer(Length(LFrames)));
  Assert.AreEqual('01 00', TXcomTestBuilders.Pixels(LFrames[0]));
  Assert.AreEqual('02 00', TXcomTestBuilders.Pixels(LFrames[1]));
  Assert.AreEqual('03 00', TXcomTestBuilders.Pixels(LFrames[2]));
end;

procedure TTestXcomPckDecoder.DovrebbeContareIFotogrammiDaUnTabA16Bit;
var
  LFrames: TArray<TXcomImage>;
begin
  // 16 bit offsets: 0, 3, 6, 9 (the first 4 bytes are not zero), so 4 frames in 8 bytes
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([0, 1, 255]), TXcomTestBuilders.Bytes([0, 0, 3, 0, 6, 0, 9, 0]), 2, 1);
  Assert.AreEqual(4, Integer(Length(LFrames)));
  Assert.AreEqual(4, TXcomPckDecoder.FrameCount(TXcomTestBuilders.Bytes([0, 0, 3, 0, 6, 0, 9, 0])));
end;

procedure TTestXcomPckDecoder.DovrebbeFarUnFotogrammaSenzaTab;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([0, 7, 255]), nil, 2, 1);
  Assert.AreEqual(1, Integer(Length(LFrames)));
  Assert.AreEqual('07 00', TXcomTestBuilders.Pixels(LFrames[0]));
end;

procedure TTestXcomPckDecoder.DovrebbeLasciareVuotiIFotogrammiCheIlPckNonHa;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([0, 1, 255]), TXcomTestBuilders.Bytes([0, 0, 0, 0, 3, 0, 0, 0]), 2, 1);
  Assert.AreEqual(2, Integer(Length(LFrames)));
  Assert.AreEqual('01 00', TXcomTestBuilders.Pixels(LFrames[0]));
  Assert.AreEqual('00 00', TXcomTestBuilders.Pixels(LFrames[1]));
end;

procedure TTestXcomPckDecoder.DovrebbeIgnorareIPixelOltreLImmagine;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([0, 1, 2, 3, 4, 5, 255]), TXcomTestBuilders.Bytes([0, 0, 0, 0]), 2, 1);
  Assert.AreEqual('01 02', TXcomTestBuilders.Pixels(LFrames[0]));
end;

procedure TTestXcomPckDecoder.DovrebbeRifiutareUnTabTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      FDecoder.Decode(TXcomTestBuilders.Bytes([0, 255]), TXcomTestBuilders.Bytes([1, 2]), 2, 1);
    end, EXcomDataException);
end;

procedure TTestXcomPckDecoder.DovrebbeRifiutareUnTabCheDaTroppiFotogrammi;
var
  LTab: TBytes;
begin
  LTab := TXcomTestBuilders.Zeros(4 * 70000);
  Assert.WillRaise(procedure begin FDecoder.Decode(nil, LTab, 2, 1); end, EXcomDataException);
end;

procedure TTestXcomPckDecoder.DovrebbeRifiutareUnaDimensioneNonValida;
begin
  Assert.WillRaise(
    procedure
    begin
      FDecoder.Decode(TXcomTestBuilders.Bytes([0, 255]), nil, 0, 1);
    end, EXcomException);
end;

procedure TTestXcomPckDecoder.DovrebbeDareIlNumeroDiFotogrammi;
begin
  Assert.AreEqual(1, TXcomPckDecoder.FrameCount(nil));
  Assert.AreEqual(2, TXcomPckDecoder.FrameCount(TXcomTestBuilders.Bytes([0, 0, 0, 0, 5, 0, 0, 0])));
  Assert.AreEqual(3, TXcomPckDecoder.FrameCount(TXcomTestBuilders.Bytes([0, 0, 5, 0, 8, 0])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomPckDecoder);

end.
