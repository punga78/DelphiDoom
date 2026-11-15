{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the sequential reader        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Bytes.StreamReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Bytes.StreamReader;

type
  [TestFixture]
  [Category('bytes')]
  TTestBytesStreamReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIByteInSequenza;
    [Test]
    procedure DovrebbeLasciareIlValoreSeIByteFiniscono;
    [Test]
    procedure DovrebbeLeggereUnaParolaLittleEndian;
    [Test]
    procedure DovrebbeCopiareSoloIlByteBassoDiUnaParolaTroncata;
    [Test]
    procedure DovrebbeFallireSempreDopoIlPrimoFallimento;
    [Test]
    procedure DovrebbeDareIlProssimoByteSenzaLeggerlo;
    [Test]
    procedure DovrebbeDareMenoUnoAllaFineEDopoUnFallimento;
    [Test]
    procedure DovrebbeSpostarsiConSeek;
    [Test]
    procedure DovrebbeIgnorareSeekDopoUnFallimento;
    [Test]
    procedure DovrebbeLeggereUnBloccoVuotoSenzaFallire;
    [Test]
    procedure DovrebbeDareLaDimensione;
  end;

implementation

{ TTestBytesStreamReader }

procedure TTestBytesStreamReader.DovrebbeLeggereIByteInSequenza;
var
  LReader: TByteStreamReader;
  LValue: Byte;
begin
  LReader := TByteStreamReader.Create([1, 2]);
  try
    LValue := 0;
    Assert.IsTrue(LReader.ReadByte(LValue));
    Assert.AreEqual(1, Integer(LValue));
    Assert.IsTrue(LReader.ReadByte(LValue));
    Assert.AreEqual(2, Integer(LValue));
    Assert.AreEqual(2, LReader.Position);
    Assert.IsFalse(LReader.Failed);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeLasciareIlValoreSeIByteFiniscono;
var
  LReader: TByteStreamReader;
  LValue: Byte;
begin
  LReader := TByteStreamReader.Create([7]);
  try
    LValue := 0;
    LReader.ReadByte(LValue);
    Assert.IsFalse(LReader.ReadByte(LValue));
    Assert.AreEqual(7, Integer(LValue), 'il valore di prima, come la variabile del C++');
    Assert.IsTrue(LReader.Failed);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeLeggereUnaParolaLittleEndian;
var
  LReader: TByteStreamReader;
  LValue: Word;
begin
  LReader := TByteStreamReader.Create([$34, $12]);
  try
    LValue := 0;
    Assert.IsTrue(LReader.ReadWord(LValue));
    Assert.AreEqual($1234, Integer(LValue));
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeCopiareSoloIlByteBassoDiUnaParolaTroncata;
var
  LReader: TByteStreamReader;
  LValue: Word;
begin
  LReader := TByteStreamReader.Create([$AB]);
  try
    LValue := $FFFE;
    Assert.IsFalse(LReader.ReadWord(LValue));
    Assert.AreEqual($FFAB, Integer(LValue));
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeFallireSempreDopoIlPrimoFallimento;
var
  LReader: TByteStreamReader;
  LWord: Word;
  LByte: Byte;
begin
  LReader := TByteStreamReader.Create([1, 2, 3]);
  try
    LWord := 0;
    LByte := 0;
    LReader.ReadWord(LWord);
    LReader.ReadWord(LWord);
    Assert.IsTrue(LReader.Failed);
    Assert.IsFalse(LReader.ReadByte(LByte), 'dopo il fallimento non si legge piu');
    Assert.AreEqual(0, Integer(LByte));
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeDareIlProssimoByteSenzaLeggerlo;
var
  LReader: TByteStreamReader;
begin
  LReader := TByteStreamReader.Create([9, 8]);
  try
    Assert.AreEqual(9, LReader.Peek);
    Assert.AreEqual(0, LReader.Position);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeDareMenoUnoAllaFineEDopoUnFallimento;
var
  LReader: TByteStreamReader;
  LByte: Byte;
begin
  LReader := TByteStreamReader.Create([9]);
  try
    LByte := 0;
    LReader.ReadByte(LByte);
    Assert.AreEqual(-1, LReader.Peek);
    LReader.ReadByte(LByte);
    Assert.AreEqual(-1, LReader.Peek);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeSpostarsiConSeek;
var
  LReader: TByteStreamReader;
  LByte: Byte;
begin
  LReader := TByteStreamReader.Create([1, 2, 3]);
  try
    LByte := 0;
    LReader.Seek(2);
    LReader.ReadByte(LByte);
    Assert.AreEqual(3, Integer(LByte));
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeIgnorareSeekDopoUnFallimento;
var
  LReader: TByteStreamReader;
  LByte: Byte;
begin
  LReader := TByteStreamReader.Create([1]);
  try
    LByte := 0;
    LReader.ReadByte(LByte);
    LReader.ReadByte(LByte);
    LReader.Seek(0);
    Assert.AreEqual(1, LReader.Position);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeLeggereUnBloccoVuotoSenzaFallire;
var
  LReader: TByteStreamReader;
  LByte: Byte;
begin
  LReader := TByteStreamReader.Create(nil);
  try
    LByte := 0;
    Assert.IsTrue(LReader.ReadBlock(LByte, 0));
    Assert.IsFalse(LReader.Failed);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesStreamReader.DovrebbeDareLaDimensione;
var
  LReader: TByteStreamReader;
begin
  LReader := TByteStreamReader.Create([1, 2, 3, 4]);
  try
    Assert.AreEqual(4, LReader.Size);
  finally
    LReader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBytesStreamReader);

end.
