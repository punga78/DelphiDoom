{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .MAP files               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.MapReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomMapReader = class(TObject)
  private
    FReader: IXcomMapReader;
    function Block(ASizeY, ASizeX, ASizeZ, ACells: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLeDimensioniNellOrdineYXZ;
    [Test]
    procedure DovrebbeLeggereLeDimensioniConSegno;
    [Test]
    procedure DovrebbeLeggereLeCelleDiAttroByte;
    [Test]
    procedure DovrebbeIgnorareIByteChePortanoUnaCellaIncompleta;
    [Test]
    procedure DovrebbeAccettareMenoCelleDiQuelleCheDiceLaDimensione;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNegativa;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneZero;
    [Test]
    procedure DovrebbeRifiutareTroppeCelle;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaIntestazione;
    [Test]
    procedure DovrebbeDareLaCellaDalPianoPiuBasso;
    [Test]
    procedure DovrebbeDareUnaCellaVuotaSeIlFileNonLaHa;
    [Test]
    procedure DovrebbeRifiutareUnaCellaFuoriDalBlocco;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomMapReader }

function TTestXcomMapReader.Block(ASizeY, ASizeX, ASizeZ, ACells: Integer): TBytes;
var
  LIndex: Integer;
begin
  Result := nil;
  TXcomTestBuilders.AddByte(Result, Byte(ASizeY));
  TXcomTestBuilders.AddByte(Result, Byte(ASizeX));
  TXcomTestBuilders.AddByte(Result, Byte(ASizeZ));
  // the cell number n has the bytes n, n + 1, n + 2, n + 3
  for LIndex := 0 to ACells * 4 - 1 do
    TXcomTestBuilders.AddByte(Result, Byte(LIndex div 4 * 10 + LIndex mod 4));
end;

procedure TTestXcomMapReader.Setup;
begin
  FReader := TXcomFactory.CreateMapReader;
end;

procedure TTestXcomMapReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestXcomMapReader.DovrebbeLeggereLeDimensioniNellOrdineYXZ;
var
  LMap: TXcomMap;
begin
  LMap := FReader.Read(Block(2, 3, 1, 6));
  Assert.AreEqual(2, LMap.SizeY);
  Assert.AreEqual(3, LMap.SizeX);
  Assert.AreEqual(1, LMap.SizeZ);
end;

procedure TTestXcomMapReader.DovrebbeLeggereLeDimensioniConSegno;
var
  LHeader: TXcomMapHeader;
begin
  // 200 is -56 for the char of the C++: a size that is not valid, not a big one
  LHeader := FReader.ReadHeader(TXcomTestBuilders.Bytes([200, 128, 255]));
  Assert.AreEqual(-56, Integer(LHeader.SizeY));
  Assert.AreEqual(-128, Integer(LHeader.SizeX));
  Assert.AreEqual(-1, Integer(LHeader.SizeZ));
end;

procedure TTestXcomMapReader.DovrebbeLeggereLeCelleDiAttroByte;
var
  LMap: TXcomMap;
begin
  LMap := FReader.Read(Block(1, 2, 1, 2));
  Assert.AreEqual(2, Integer(Length(LMap.Cells)));
  Assert.AreEqual(10, Integer(LMap.Cells[1].Floor));
  Assert.AreEqual(11, Integer(LMap.Cells[1].WestWall));
  Assert.AreEqual(12, Integer(LMap.Cells[1].NorthWall));
  Assert.AreEqual(13, Integer(LMap.Cells[1].Obj));
end;

procedure TTestXcomMapReader.DovrebbeIgnorareIByteChePortanoUnaCellaIncompleta;
var
  LBytes: TBytes;
begin
  LBytes := Block(1, 2, 1, 1);
  TXcomTestBuilders.AddByte(LBytes, 99);
  TXcomTestBuilders.AddByte(LBytes, 99);
  Assert.AreEqual(1, Integer(Length(FReader.Read(LBytes).Cells)));
end;

procedure TTestXcomMapReader.DovrebbeAccettareMenoCelleDiQuelleCheDiceLaDimensione;
begin
  Assert.AreEqual(1, Integer(Length(FReader.Read(Block(2, 2, 2, 1)).Cells)));
end;

procedure TTestXcomMapReader.DovrebbeRifiutareUnaDimensioneNegativa;
begin
  Assert.WillRaise(procedure begin FReader.Read(TXcomTestBuilders.Bytes([200, 2, 1])); end, EXcomDataException);
end;

procedure TTestXcomMapReader.DovrebbeRifiutareUnaDimensioneZero;
begin
  Assert.WillRaise(procedure begin FReader.Read(TXcomTestBuilders.Bytes([2, 0, 1])); end, EXcomDataException);
end;

procedure TTestXcomMapReader.DovrebbeRifiutareTroppeCelle;
begin
  Assert.WillRaise(procedure begin FReader.Read(Block(1, 1, 1, 2)); end, EXcomDataException);
end;

procedure TTestXcomMapReader.DovrebbeRifiutareUnFileSenzaIntestazione;
begin
  Assert.WillRaise(procedure begin FReader.ReadHeader(TXcomTestBuilders.Bytes([1, 2])); end, EXcomDataException);
  Assert.WillRaise(procedure begin FReader.Read(nil); end, EXcomDataException);
end;

procedure TTestXcomMapReader.DovrebbeDareLaCellaDalPianoPiuBasso;
var
  LMap: TXcomMap;
begin
  // 2 x 1 x 2 cells: the file lists the top layer first, so the cell (1, 0, 0) is the number 3, (0, 0, 1) is the number 0
  LMap := FReader.Read(Block(1, 2, 2, 4));
  Assert.AreEqual(30, Integer(LMap.CellAt(1, 0, 0).Floor));
  Assert.AreEqual(0, Integer(LMap.CellAt(0, 0, 1).Floor));
  Assert.AreEqual(10, Integer(LMap.CellAt(1, 0, 1).Floor));
  Assert.AreEqual(20, Integer(LMap.CellAt(0, 0, 0).Floor));
end;

procedure TTestXcomMapReader.DovrebbeDareUnaCellaVuotaSeIlFileNonLaHa;
var
  LMap: TXcomMap;
begin
  LMap := FReader.Read(Block(2, 2, 1, 1));
  Assert.AreEqual(0, Integer(LMap.CellAt(1, 1, 0).Floor));
  Assert.AreEqual(0, Integer(LMap.CellAt(1, 1, 0).Obj));
end;

procedure TTestXcomMapReader.DovrebbeRifiutareUnaCellaFuoriDalBlocco;
var
  LMap: TXcomMap;
begin
  LMap := FReader.Read(Block(2, 2, 1, 4));
  Assert.WillRaise(procedure begin LMap.CellAt(2, 0, 0); end, EXcomException);
  Assert.WillRaise(procedure begin LMap.CellAt(0, 0, 1); end, EXcomException);
  Assert.WillRaise(procedure begin LMap.CellAt(0, -1, 0); end, EXcomException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMapReader);

end.
