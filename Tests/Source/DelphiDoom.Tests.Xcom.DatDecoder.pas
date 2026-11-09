{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .DAT pictures            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.DatDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomDatDecoder = class(TObject)
  private
    FDecoder: IXcomDatDecoder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeTagliareIlFileInFotogrammi;
    [Test]
    procedure DovrebbeScartareIByteCheNonFannoUnFotogramma;
    [Test]
    procedure DovrebbeDareNessunFotogrammaSeIlFileELCorto;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonValida;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomDatDecoder }

procedure TTestXcomDatDecoder.Setup;
begin
  FDecoder := TXcomFactory.CreateDatDecoder;
end;

procedure TTestXcomDatDecoder.TearDown;
begin
  FDecoder := nil;
end;

procedure TTestXcomDatDecoder.DovrebbeTagliareIlFileInFotogrammi;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([1, 2, 3, 4, 5, 6, 7, 8]), 2, 2);
  Assert.AreEqual(2, Integer(Length(LFrames)));
  Assert.AreEqual('01 02 03 04', TXcomTestBuilders.Pixels(LFrames[0]));
  Assert.AreEqual('05 06 07 08', TXcomTestBuilders.Pixels(LFrames[1]));
end;

procedure TTestXcomDatDecoder.DovrebbeScartareIByteCheNonFannoUnFotogramma;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FDecoder.Decode(TXcomTestBuilders.Bytes([1, 2, 3, 4, 5]), 2, 2);
  Assert.AreEqual(1, Integer(Length(LFrames)));
end;

procedure TTestXcomDatDecoder.DovrebbeDareNessunFotogrammaSeIlFileELCorto;
begin
  Assert.AreEqual(0, Integer(Length(FDecoder.Decode(TXcomTestBuilders.Bytes([1, 2, 3]), 2, 2))));
end;

procedure TTestXcomDatDecoder.DovrebbeRifiutareUnaDimensioneNonValida;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(nil, 0, 2); end, EXcomException);
  Assert.WillRaise(procedure begin FDecoder.Decode(nil, 2, -1); end, EXcomException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomDatDecoder);

end.
