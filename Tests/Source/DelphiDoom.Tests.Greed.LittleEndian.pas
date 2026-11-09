{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - little endian numbers               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LittleEndian;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.LittleEndian;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedLittleEndian = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereUnaParolaConSegno;
    [Test]
    procedure DovrebbeLeggereUnIntero32ConSegno;
    [Test]
    procedure DovrebbeLeggereDaUnOffset;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaFuoriDalBuffer;
  end;

implementation

{ TTestGreedLittleEndian }

procedure TTestGreedLittleEndian.DovrebbeLeggereUnaParolaConSegno;
begin
  Assert.AreEqual(Integer($0201), Integer(TGreedLittleEndian.ReadSmallInt(TBytes.Create(1, 2), 0)));
  Assert.AreEqual(-1, Integer(TGreedLittleEndian.ReadSmallInt(TBytes.Create($FF, $FF), 0)));
  Assert.AreEqual(-32768, Integer(TGreedLittleEndian.ReadSmallInt(TBytes.Create(0, $80), 0)));
end;

procedure TTestGreedLittleEndian.DovrebbeLeggereUnIntero32ConSegno;
begin
  Assert.AreEqual($04030201, TGreedLittleEndian.ReadInt32(TBytes.Create(1, 2, 3, 4), 0));
  Assert.AreEqual(-1, TGreedLittleEndian.ReadInt32(TBytes.Create($FF, $FF, $FF, $FF), 0));
  Assert.AreEqual(Integer($80000000), TGreedLittleEndian.ReadInt32(TBytes.Create(0, 0, 0, $80), 0));
end;

procedure TTestGreedLittleEndian.DovrebbeLeggereDaUnOffset;
begin
  Assert.AreEqual(Integer($0403), Integer(TGreedLittleEndian.ReadSmallInt(TBytes.Create(1, 2, 3, 4), 2)));
  Assert.AreEqual($05040302, TGreedLittleEndian.ReadInt32(TBytes.Create(1, 2, 3, 4, 5), 1));
end;

procedure TTestGreedLittleEndian.DovrebbeRifiutareUnaLetturaFuoriDalBuffer;
begin
  Assert.WillRaise(procedure begin TGreedLittleEndian.ReadSmallInt(TBytes.Create(1), 0); end, EGreedDataException);
  Assert.WillRaise(procedure begin TGreedLittleEndian.ReadSmallInt(TBytes.Create(1, 2), -1); end, EGreedDataException);
  Assert.WillRaise(procedure begin TGreedLittleEndian.ReadSmallInt(TBytes.Create(1, 2), 1); end, EGreedDataException);
  Assert.WillRaise(procedure begin TGreedLittleEndian.ReadInt32(TBytes.Create(1, 2, 3), 0); end, EGreedDataException);
  Assert.WillRaise(procedure begin TGreedLittleEndian.ReadInt32(TBytes.Create(1, 2, 3, 4), 1); end, EGreedDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedLittleEndian);

end.
