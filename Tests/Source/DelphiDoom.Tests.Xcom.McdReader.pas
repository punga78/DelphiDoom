{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .MCD files               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.McdReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomMcdReader = class(TObject)
  private
    FReader: IXcomMcdReader;
    /// <summary>A record of 62 bytes with armor 1 and no reference to other objects (die 0, alt 0)</summary>
    function Record62: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIRecordDa62Byte;
    [Test]
    procedure DovrebbeLeggereICampiAgliOffsetDelFile;
    [Test]
    procedure DovrebbeLeggereLaParolaDelMinimapComeLittleEndian;
    [Test]
    procedure DovrebbeLeggereLAltezzaDelTerrenoConSegno;
    [Test]
    procedure DovrebbeIgnorareIByteDiUnRecordIncompleto;
    [Test]
    procedure DovrebbeAccettareUnTerrenoGiusto;
    [Test]
    procedure DovrebbeRifiutareUnaDistruzioneCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaAlternativaCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaCorazzaZero;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomMcdReader }

function TTestXcomMcdReader.Record62: TBytes;
begin
  Result := TXcomTestBuilders.Zeros(XCOM_MCD_RECORD_BYTES);
  Result[42] := 1;
end;

procedure TTestXcomMcdReader.Setup;
begin
  FReader := TXcomFactory.CreateMcdReader;
end;

procedure TTestXcomMcdReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestXcomMcdReader.DovrebbeLeggereIRecordDa62Byte;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  SetLength(LBytes, XCOM_MCD_RECORD_BYTES * 3);
  Assert.AreEqual(3, Integer(Length(FReader.Read(LBytes))));
end;

procedure TTestXcomMcdReader.DovrebbeLeggereICampiAgliOffsetDelFile;
var
  LBytes: TBytes;
  LRecords: TArray<TXcomMcdRecord>;
begin
  LBytes := Record62;
  LBytes[0] := 7;
  LBytes[7] := 8;
  LBytes[8] := 9;
  LBytes[19] := 10;
  LBytes[30] := 11;
  LBytes[31] := 12;
  LBytes[39] := 13;
  LBytes[44] := 0;
  LBytes[49] := 14;
  LBytes[53] := 15;
  LBytes[59] := 16;
  LBytes[60] := 17;
  LRecords := FReader.Read(LBytes);
  Assert.AreEqual(7, Integer(LRecords[0].Frame[0]));
  Assert.AreEqual(8, Integer(LRecords[0].Frame[7]));
  Assert.AreEqual(9, Integer(LRecords[0].Loft[0]));
  Assert.AreEqual(10, Integer(LRecords[0].Loft[11]));
  Assert.AreEqual(11, Integer(LRecords[0].UfoDoor));
  Assert.AreEqual(12, Integer(LRecords[0].StopLos));
  Assert.AreEqual(13, Integer(LRecords[0].TuWalk));
  Assert.AreEqual(1, Integer(LRecords[0].Armor));
  Assert.AreEqual(14, Integer(LRecords[0].PLevel));
  Assert.AreEqual(15, Integer(LRecords[0].TileType));
  Assert.AreEqual(16, Integer(LRecords[0].TargetType));
  Assert.AreEqual(17, Integer(LRecords[0].XcomBase));
end;

procedure TTestXcomMcdReader.DovrebbeLeggereLaParolaDelMinimapComeLittleEndian;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  LBytes[20] := $34;
  LBytes[21] := $12;
  Assert.AreEqual($1234, Integer(FReader.Read(LBytes)[0].ScanG));
end;

procedure TTestXcomMcdReader.DovrebbeLeggereLAltezzaDelTerrenoConSegno;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  LBytes[48] := $F0;
  Assert.AreEqual(-16, Integer(FReader.Read(LBytes)[0].TerrainLevel));
end;

procedure TTestXcomMcdReader.DovrebbeIgnorareIByteDiUnRecordIncompleto;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  SetLength(LBytes, 100);
  Assert.AreEqual(1, Integer(Length(FReader.Read(LBytes))));
  Assert.AreEqual(0, Integer(Length(FReader.Read(nil))));
end;

procedure TTestXcomMcdReader.DovrebbeAccettareUnTerrenoGiusto;
begin
  FReader.Validate(FReader.Read(Record62));
  FReader.Validate(nil);
  Assert.Pass;
end;

procedure TTestXcomMcdReader.DovrebbeRifiutareUnaDistruzioneCheNonCe;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  LBytes[44] := 1;
  Assert.WillRaise(procedure begin FReader.Validate(FReader.Read(LBytes)); end, EXcomDataException);
end;

procedure TTestXcomMcdReader.DovrebbeRifiutareUnaAlternativaCheNonCe;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  LBytes[46] := 5;
  Assert.WillRaise(procedure begin FReader.Validate(FReader.Read(LBytes)); end, EXcomDataException);
end;

procedure TTestXcomMcdReader.DovrebbeRifiutareUnaCorazzaZero;
var
  LBytes: TBytes;
begin
  LBytes := Record62;
  LBytes[42] := 0;
  Assert.WillRaise(procedure begin FReader.Validate(FReader.Read(LBytes)); end, EXcomDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMcdReader);

end.
