{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the hash                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.Hasher;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.Hasher;

type
  [TestFixture]
  [Category('parity')]
  TTestParityHasher = class(TObject)
  public
    [Test]
    procedure DovrebbePartireDalValoreDiOffsetDiFnv;
    [Test]
    procedure DovrebbeDareIlVettoreNotoDiFnvPerUnaLettera;
    [Test]
    procedure DovrebbeDareIlVettoreNotoDiFnvPerFoobar;
    [Test]
    procedure DovrebbeRipartireDopoReset;
    [Test]
    procedure DovrebbeDipendereDallOrdineDeiNumeri;
    [Test]
    procedure DovrebbeDistinguereUnNumeroNegativoDaUnoPositivo;
    [Test]
    procedure DovrebbeDistinguereUnSoloNumeroDiverso;
    [Test]
    procedure UnInt64DovrebbeEssereDueNumeriDa32Bit;
    [Test]
    procedure UnBloccoDovrebbeEssereQuattroByteAllaVolta;
    [Test]
    procedure UnBloccoDiTreByteDovrebbeEssereByteAByte;
    [Test]
    procedure UnaStringaDovrebbeTenereContoDellaLunghezza;
    [Test]
    procedure DovrebbeDareSedicicifreEsadecimali;
    [Test]
    procedure LaFormaCortaDovrebbeAvereOttoCifre;
  end;

implementation

procedure TTestParityHasher.DovrebbePartireDalValoreDiOffsetDiFnv;
var
  LHasher: TParityHasher;
begin
  LHasher.Reset;
  Assert.AreEqual('cbf29ce484222325', TParityHasher.ToHex(LHasher.Value));
end;

procedure TTestParityHasher.DovrebbeDareIlVettoreNotoDiFnvPerUnaLettera;
var
  LHasher: TParityHasher;
begin
  LHasher.Reset;
  LHasher.AddByte(Ord('a'));
  Assert.AreEqual('af63dc4c8601ec8c', TParityHasher.ToHex(LHasher.Value));
end;

procedure TTestParityHasher.DovrebbeDareIlVettoreNotoDiFnvPerFoobar;
var
  LHasher: TParityHasher;
  LByte: Byte;
begin
  LHasher.Reset;
  for LByte in TEncoding.ASCII.GetBytes('foobar') do
    LHasher.AddByte(LByte);
  Assert.AreEqual('85944171f73967e8', TParityHasher.ToHex(LHasher.Value));
end;

procedure TTestParityHasher.DovrebbeRipartireDopoReset;
var
  LFirst: TParityHasher;
  LSecond: TParityHasher;
begin
  LFirst.Reset;
  LFirst.AddInteger(7);
  LSecond.Reset;
  LSecond.AddInteger(99);
  LSecond.Reset;
  LSecond.AddInteger(7);
  Assert.AreEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.DovrebbeDipendereDallOrdineDeiNumeri;
var
  LFirst: TParityHasher;
  LSecond: TParityHasher;
begin
  LFirst.Reset;
  LFirst.AddInteger(1);
  LFirst.AddInteger(2);
  LSecond.Reset;
  LSecond.AddInteger(2);
  LSecond.AddInteger(1);
  Assert.AreNotEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.DovrebbeDistinguereUnNumeroNegativoDaUnoPositivo;
var
  LFirst: TParityHasher;
  LSecond: TParityHasher;
begin
  LFirst.Reset;
  LFirst.AddInteger(-1);
  LSecond.Reset;
  LSecond.AddInteger(1);
  Assert.AreNotEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.DovrebbeDistinguereUnSoloNumeroDiverso;
var
  LFirst: TParityHasher;
  LSecond: TParityHasher;
  LIndex: Integer;
begin
  // a value of the middle of a long series changes the hash, whatever the bit
  for LIndex := 0 to 31 do
  begin
    LFirst.Reset;
    LSecond.Reset;
    LFirst.AddInteger(5);
    LSecond.AddInteger(5);
    LFirst.AddInteger(0);
    LSecond.AddInteger(Integer(Cardinal(1) shl LIndex));
    LFirst.AddInteger(9);
    LSecond.AddInteger(9);
    Assert.AreNotEqual(LFirst.Value, LSecond.Value, 'bit ' + IntToStr(LIndex));
  end;
end;

procedure TTestParityHasher.UnInt64DovrebbeEssereDueNumeriDa32Bit;
var
  LFirst: TParityHasher;
  LSecond: TParityHasher;
begin
  LFirst.Reset;
  LFirst.AddInt64($0000000500000003);
  LSecond.Reset;
  LSecond.AddInteger(3);
  LSecond.AddInteger(5);
  Assert.AreEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.UnBloccoDovrebbeEssereQuattroByteAllaVolta;
var
  LBlock: array[0..7] of Byte;
  LFirst: TParityHasher;
  LSecond: TParityHasher;
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    LBlock[LIndex] := Byte(LIndex + 1);
  LFirst.Reset;
  LFirst.AddSpan(@LBlock[0], 8);
  // the words of the little endian memory
  LSecond.Reset;
  LSecond.AddInteger($04030201);
  LSecond.AddInteger($08070605);
  Assert.AreEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.UnBloccoDiTreByteDovrebbeEssereByteAByte;
var
  LBlock: array[0..2] of Byte;
  LFirst: TParityHasher;
  LSecond: TParityHasher;
begin
  LBlock[0] := 10;
  LBlock[1] := 20;
  LBlock[2] := 30;
  LFirst.Reset;
  LFirst.AddSpan(@LBlock[0], 3);
  LSecond.Reset;
  LSecond.AddByte(10);
  LSecond.AddByte(20);
  LSecond.AddByte(30);
  Assert.AreEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.UnaStringaDovrebbeTenereContoDellaLunghezza;
var
  LFirst: TParityHasher;
  LSecond: TParityHasher;
begin
  // "ab" + "c" and "a" + "bc" are not the same sequence
  LFirst.Reset;
  LFirst.AddString('ab');
  LFirst.AddString('c');
  LSecond.Reset;
  LSecond.AddString('a');
  LSecond.AddString('bc');
  Assert.AreNotEqual(LFirst.Value, LSecond.Value);
end;

procedure TTestParityHasher.DovrebbeDareSedicicifreEsadecimali;
begin
  Assert.AreEqual('00000000000000ff', TParityHasher.ToHex(255));
  Assert.AreEqual('ffffffffffffffff', TParityHasher.ToHex(UInt64($FFFFFFFFFFFFFFFF)));
end;

procedure TTestParityHasher.LaFormaCortaDovrebbeAvereOttoCifre;
begin
  Assert.AreEqual('00000000', TParityHasher.ToShortHex(UInt64($1234567812345678)));
  Assert.AreEqual('0000000f', TParityHasher.ToShortHex(15));
end;

end.
