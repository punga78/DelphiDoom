{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the tile info table                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.TileInfo;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenTileInfo = class(TObject)
  private
    FBytes: TBytes;
    FInfo: IKeenTileInfo;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLeNoveTabelleDoveTorna;
    [Test]
    procedure DovrebbeLeggereLeAnimazioniConSegno;
    [Test]
    procedure DovrebbeDareIPrimiEGliUltimiTile;
    [Test]
    procedure DovrebbeDareUnaCopiaDellaTabella;
    [Test]
    procedure DovrebbeRifiutareUnTileFuoriDallaTabella;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaTroppoCorta;
  end;

implementation

uses
  DelphiDoom.Keen.TileInfo;

{ TTestKeenTileInfo }

procedure TTestKeenTileInfo.Setup;
var
  LIndex: Integer;
begin
  SetLength(FBytes, KEEN_TINF_SIZE + 5);
  for LIndex := 0 to High(FBytes) do
    FBytes[LIndex] := Byte(LIndex * 7);
  FInfo := TKeenTileInfo.Create(FBytes);
end;

procedure TTestKeenTileInfo.TearDown;
begin
  FInfo := nil;
end;

procedure TTestKeenTileInfo.DovrebbeLeggereLeNoveTabelleDoveTorna;
begin
  Assert.AreEqual(Integer(FBytes[10]), Integer(FInfo.Speed(10)));
  Assert.AreEqual(Integer(FBytes[1440 + 10]), Integer(FInfo.Animation(10)) and $FF);
  Assert.AreEqual(Integer(FBytes[2880 + 10]), Integer(FInfo.NorthWall(10)));
  Assert.AreEqual(Integer(FBytes[2880 + 1206 + 10]), Integer(FInfo.EastWall(10)));
  Assert.AreEqual(Integer(FBytes[2880 + 2 * 1206 + 10]), Integer(FInfo.SouthWall(10)));
  Assert.AreEqual(Integer(FBytes[2880 + 3 * 1206 + 10]), Integer(FInfo.WestWall(10)));
  Assert.AreEqual(Integer(FBytes[2880 + 4 * 1206 + 10]), Integer(FInfo.MaskedAnimation(10)) and $FF);
  Assert.AreEqual(Integer(FBytes[2880 + 5 * 1206 + 10]), Integer(FInfo.InTile(10)));
  Assert.AreEqual(Integer(FBytes[2880 + 6 * 1206 + 10]), Integer(FInfo.MaskedSpeed(10)));
end;

procedure TTestKeenTileInfo.DovrebbeLeggereLeAnimazioniConSegno;
var
  LBytes: TBytes;
  LInfo: IKeenTileInfo;
begin
  // the C reads (signed char)tinf[ANIM + tile]: $FF is -1, the tile before
  SetLength(LBytes, KEEN_TINF_SIZE);
  FillChar(LBytes[0], Length(LBytes), 0);
  LBytes[KEEN_TINF_ANIM + 3] := $FF;
  LBytes[KEEN_TINF_ANIM + 4] := $01;
  LBytes[KEEN_TINF_MANIM + 3] := $80;
  LInfo := TKeenTileInfo.Create(LBytes);
  Assert.AreEqual(-1, Integer(LInfo.Animation(3)));
  Assert.AreEqual(1, Integer(LInfo.Animation(4)));
  Assert.AreEqual(-128, Integer(LInfo.MaskedAnimation(3)));
end;

procedure TTestKeenTileInfo.DovrebbeDareIPrimiEGliUltimiTile;
begin
  Assert.AreEqual(Integer(FBytes[0]), Integer(FInfo.Speed(0)));
  Assert.AreEqual(Integer(FBytes[1439]), Integer(FInfo.Speed(1439)));
  Assert.AreEqual(Integer(FBytes[KEEN_TINF_SIZE - 1]), Integer(FInfo.MaskedSpeed(1205)));
end;

procedure TTestKeenTileInfo.DovrebbeDareUnaCopiaDellaTabella;
var
  LCopy: TBytes;
begin
  LCopy := FInfo.Bytes;
  Assert.AreEqual(KEEN_TINF_SIZE, Length(LCopy), 'i byte in coda non ci sono');
  LCopy[0] := LCopy[0] + 1;
  Assert.AreEqual(Integer(FBytes[0]), Integer(FInfo.Speed(0)));
end;

procedure TTestKeenTileInfo.DovrebbeRifiutareUnTileFuoriDallaTabella;
begin
  Assert.WillRaise(procedure begin FInfo.Speed(1440); end, EKeenDataException);
  Assert.WillRaise(procedure begin FInfo.Speed(-1); end, EKeenDataException);
  Assert.WillRaise(procedure begin FInfo.NorthWall(1206); end, EKeenDataException);
  Assert.WillRaise(procedure begin FInfo.MaskedSpeed(1206); end, EKeenDataException);
end;

procedure TTestKeenTileInfo.DovrebbeRifiutareUnaTabellaTroppoCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenTileInfo.Create(Copy(FBytes, 0, KEEN_TINF_SIZE - 1));
    end, EKeenDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenTileInfo);

end.
