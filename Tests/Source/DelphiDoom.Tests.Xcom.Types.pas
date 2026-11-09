{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the records of the files     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLaDimensioneDeiRecordSuDisco;
    [Test]
    procedure DovrebbeTenereIcampiDelloMcdAgliOffsetDelFile;
    [Test]
    procedure DovrebbeTenereICampiDelloRmpAgliOffsetDelFile;
    [Test]
    procedure DovrebbeLeggereLaLarghezzaDellaMappaConSegno;
  end;

implementation

{ TTestXcomTypes }

procedure TTestXcomTypes.DovrebbeAvereLaDimensioneDeiRecordSuDisco;
begin
  // the same sizes on 32 and 64 bit: they are the formats of the original files
  Assert.AreEqual(3, Integer(SizeOf(TXcomMapHeader)));
  Assert.AreEqual(4, Integer(SizeOf(TXcomMapCell)));
  Assert.AreEqual(3, Integer(SizeOf(TXcomRmpLink)));
  Assert.AreEqual(XCOM_RMP_RECORD_BYTES, Integer(SizeOf(TXcomRmpRecord)));
  Assert.AreEqual(XCOM_MCD_RECORD_BYTES, Integer(SizeOf(TXcomMcdRecord)));
  Assert.AreEqual(XCOM_WORLD_RECORD_BYTES, Integer(SizeOf(TXcomWorldRecord)));
  Assert.AreEqual(8, Integer(SizeOf(TXcomCatEntry)));
  Assert.AreEqual(4, Integer(SizeOf(TXcomColor)));
end;

procedure TTestXcomTypes.DovrebbeTenereIcampiDelloMcdAgliOffsetDelFile;
var
  LRecord: TXcomMcdRecord;
  LBase: NativeInt;
begin
  LBase := NativeInt(@LRecord);
  Assert.AreEqual(0, Integer(NativeInt(@LRecord.Frame) - LBase));
  Assert.AreEqual(8, Integer(NativeInt(@LRecord.Loft) - LBase));
  Assert.AreEqual(20, Integer(NativeInt(@LRecord.ScanG) - LBase));
  Assert.AreEqual(30, Integer(NativeInt(@LRecord.UfoDoor) - LBase));
  Assert.AreEqual(39, Integer(NativeInt(@LRecord.TuWalk) - LBase));
  Assert.AreEqual(42, Integer(NativeInt(@LRecord.Armor) - LBase));
  Assert.AreEqual(44, Integer(NativeInt(@LRecord.DieMcd) - LBase));
  Assert.AreEqual(46, Integer(NativeInt(@LRecord.AltMcd) - LBase));
  Assert.AreEqual(48, Integer(NativeInt(@LRecord.TerrainLevel) - LBase));
  Assert.AreEqual(49, Integer(NativeInt(@LRecord.PLevel) - LBase));
  Assert.AreEqual(53, Integer(NativeInt(@LRecord.TileType) - LBase));
  Assert.AreEqual(59, Integer(NativeInt(@LRecord.TargetType) - LBase));
  Assert.AreEqual(60, Integer(NativeInt(@LRecord.XcomBase) - LBase));
  Assert.AreEqual(61, Integer(NativeInt(@LRecord.U62) - LBase));
end;

procedure TTestXcomTypes.DovrebbeTenereICampiDelloRmpAgliOffsetDelFile;
var
  LRecord: TXcomRmpRecord;
  LBase: NativeInt;
begin
  LBase := NativeInt(@LRecord);
  Assert.AreEqual(0, Integer(NativeInt(@LRecord.PosY) - LBase));
  Assert.AreEqual(1, Integer(NativeInt(@LRecord.PosX) - LBase));
  Assert.AreEqual(2, Integer(NativeInt(@LRecord.PosZ) - LBase));
  Assert.AreEqual(4, Integer(NativeInt(@LRecord.Links[0]) - LBase));
  Assert.AreEqual(16, Integer(NativeInt(@LRecord.Links[4]) - LBase));
  Assert.AreEqual(19, Integer(NativeInt(@LRecord.NodeType) - LBase));
  Assert.AreEqual(23, Integer(NativeInt(@LRecord.Priority) - LBase));
end;

procedure TTestXcomTypes.DovrebbeLeggereLaLarghezzaDellaMappaConSegno;
var
  LHeader: TXcomMapHeader;
  LByte: Byte;
begin
  // 200 in a signed byte is -56: the char of the C++
  LByte := 200;
  LHeader.SizeX := Shortint(LByte);
  Assert.AreEqual(-56, Integer(LHeader.SizeX));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomTypes);

end.
