{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - LOFTEMPS.DAT                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.WordTableReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomWordTableReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereParoleLittleEndian;
    [Test]
    procedure DovrebbeIgnorareUnByteInAvanzo;
    [Test]
    procedure DovrebbeLeggereUnFileVuoto;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomWordTableReader }

procedure TTestXcomWordTableReader.DovrebbeLeggereParoleLittleEndian;
var
  LWords: TArray<Word>;
begin
  LWords := TXcomFactory.CreateWordTableReader.Read(TXcomTestBuilders.Bytes([1, 2, $FF, $FF, 0, 0]));
  Assert.AreEqual(3, Integer(Length(LWords)));
  Assert.AreEqual($0201, Integer(LWords[0]));
  Assert.AreEqual($FFFF, Integer(LWords[1]));
  Assert.AreEqual(0, Integer(LWords[2]));
end;

procedure TTestXcomWordTableReader.DovrebbeIgnorareUnByteInAvanzo;
begin
  Assert.AreEqual(1, Integer(Length(TXcomFactory.CreateWordTableReader.Read(TXcomTestBuilders.Bytes([1, 2, 3])))));
end;

procedure TTestXcomWordTableReader.DovrebbeLeggereUnFileVuoto;
begin
  Assert.AreEqual(0, Integer(Length(TXcomFactory.CreateWordTableReader.Read(nil))));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomWordTableReader);

end.
