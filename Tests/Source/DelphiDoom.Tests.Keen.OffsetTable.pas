{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the table of the offsets             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.OffsetTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenOffsetTable = class(TObject)
  private
    function Table(const AOffsets: array of Integer): IKeenOffsetTable;
  public
    [Test]
    procedure DovrebbeContareLeVociDellaTestata;
    [Test]
    procedure DovrebbeLeggereGliOffsetConSegno;
    [Test]
    procedure DovrebbeRiconoscereUnChunkVuoto;
    [Test]
    procedure DovrebbeDareLaFineDalProssimoChunkPresente;
    [Test]
    procedure DovrebbeRifiutareUnChunkCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaFineCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaTestataTroppoCorta;
    [Test]
    procedure DovrebbeIgnorareIByteInAvanzo;
  end;

implementation

uses
  DelphiDoom.Keen.Factory;

{ TTestKeenOffsetTable }

function TTestKeenOffsetTable.Table(const AOffsets: array of Integer): IKeenOffsetTable;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AOffsets) * 4);
  for LIndex := 0 to High(AOffsets) do
  begin
    LBytes[LIndex * 4] := Byte(AOffsets[LIndex]);
    LBytes[LIndex * 4 + 1] := Byte(AOffsets[LIndex] shr 8);
    LBytes[LIndex * 4 + 2] := Byte(AOffsets[LIndex] shr 16);
    LBytes[LIndex * 4 + 3] := Byte(AOffsets[LIndex] shr 24);
  end;
  Result := TKeenFactory.CreateOffsetTable(LBytes, 'TEST');
end;

procedure TTestKeenOffsetTable.DovrebbeContareLeVociDellaTestata;
begin
  Assert.AreEqual(4, Table([0, 10, 20, 30]).Count);
end;

procedure TTestKeenOffsetTable.DovrebbeLeggereGliOffsetConSegno;
var
  LTable: IKeenOffsetTable;
begin
  LTable := Table([0, -1, 70000, 213045]);
  Assert.AreEqual(0, LTable[0]);
  Assert.AreEqual(-1, LTable[1]);
  Assert.AreEqual(70000, LTable[2]);
  Assert.AreEqual(213045, LTable.Offsets[3]);
end;

procedure TTestKeenOffsetTable.DovrebbeRiconoscereUnChunkVuoto;
var
  LTable: IKeenOffsetTable;
begin
  LTable := Table([0, -1, 20, 30]);
  Assert.IsFalse(LTable.IsSparse(0));
  Assert.IsTrue(LTable.IsSparse(1));
end;

procedure TTestKeenOffsetTable.DovrebbeDareLaFineDalProssimoChunkPresente;
var
  LTable: IKeenOffsetTable;
begin
  LTable := Table([0, 10, -1, -1, 40, 50]);
  Assert.AreEqual(10, LTable.EndOf(0));
  Assert.AreEqual(40, LTable.EndOf(1), 'salta i chunk -1');
  Assert.AreEqual(50, LTable.EndOf(4));
end;

procedure TTestKeenOffsetTable.DovrebbeRifiutareUnChunkCheNonCe;
var
  LTable: IKeenOffsetTable;
begin
  LTable := Table([0, 10]);
  Assert.WillRaise(
    procedure
    begin
      LTable.IsSparse(2);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      LTable.IsSparse(-1);
    end, EKeenDataException);
end;

procedure TTestKeenOffsetTable.DovrebbeRifiutareUnaFineCheNonCe;
var
  LTable: IKeenOffsetTable;
begin
  LTable := Table([0, 10, -1]);
  Assert.WillRaise(
    procedure
    begin
      LTable.EndOf(1);
    end, EKeenDataException);
end;

procedure TTestKeenOffsetTable.DovrebbeRifiutareUnaTestataTroppoCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenFactory.CreateOffsetTable(TBytes.Create(1, 2, 3, 4), 'EGAHEAD.KDR');
    end, EKeenDataException);
end;

procedure TTestKeenOffsetTable.DovrebbeIgnorareIByteInAvanzo;
begin
  Assert.AreEqual(2, TKeenFactory.CreateOffsetTable(TBytes.Create(0, 0, 0, 0, 1, 0, 0, 0, 9, 9), 'T').Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenOffsetTable);

end.
