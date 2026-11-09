{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - numbers of the files                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.LittleEndian;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.LittleEndian;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenLittleEndian = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereUnaParolaSenzaSegno;
    [Test]
    procedure DovrebbeLeggereUnaParolaConSegno;
    [Test]
    procedure DovrebbeLeggereUnNumeroAA32BitConSegno;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaFuoriDalBuffer;
  end;

implementation

{ TTestKeenLittleEndian }

procedure TTestKeenLittleEndian.DovrebbeLeggereUnaParolaSenzaSegno;
begin
  Assert.AreEqual($FF01, Integer(TKeenLittleEndian.ReadWord(TBytes.Create(0, $01, $FF), 1)));
end;

procedure TTestKeenLittleEndian.DovrebbeLeggereUnaParolaConSegno;
begin
  Assert.AreEqual(-1, Integer(TKeenLittleEndian.ReadSmallInt(TBytes.Create($FF, $FF), 0)));
  Assert.AreEqual(-32768, Integer(TKeenLittleEndian.ReadSmallInt(TBytes.Create($00, $80), 0)));
end;

procedure TTestKeenLittleEndian.DovrebbeLeggereUnNumeroAA32BitConSegno;
begin
  Assert.AreEqual($04030201, TKeenLittleEndian.ReadInt32(TBytes.Create(1, 2, 3, 4), 0));
  Assert.AreEqual(-1, TKeenLittleEndian.ReadInt32(TBytes.Create($FF, $FF, $FF, $FF), 0), 'gli offset -1 dei tile vuoti');
  Assert.AreEqual(Integer($80000000), TKeenLittleEndian.ReadInt32(TBytes.Create(0, 0, 0, $80), 0));
end;

procedure TTestKeenLittleEndian.DovrebbeRifiutareUnaLetturaFuoriDalBuffer;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenLittleEndian.ReadWord(TBytes.Create(1), 0);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      TKeenLittleEndian.ReadInt32(TBytes.Create(1, 2, 3, 4), 1);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      TKeenLittleEndian.ReadInt32(TBytes.Create(1, 2, 3, 4), -1);
    end, EKeenDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenLittleEndian);

end.
