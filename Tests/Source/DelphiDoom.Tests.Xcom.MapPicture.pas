{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the picture of a map         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.MapPicture;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Image;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomMapPicture = class(TObject)
  private
    /// <summary>A block of 2 x 1 x 1 whose two cells have the bytes given</summary>
    function Block(const AFirst, ASecond: TXcomMapCell): TXcomMap;
  public
    [Test]
    procedure DovrebbeFare8PixelPerCella;
    [Test]
    procedure DovrebbeRiempireLaCellaConIlPavimento;
    [Test]
    procedure DovrebbeLasciareVuotaUnaCellaSenzaNulla;
    [Test]
    procedure DovrebbeDisegnareUnOggettoAlCentro;
    [Test]
    procedure DovrebbeDisegnareLeParetiSuiLati;
    [Test]
    procedure DovrebbeRifiutareUnPianoCheNonCe;
  end;

implementation

uses
  DelphiDoom.Xcom.MapPicture, DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomMapPicture }

function TTestXcomMapPicture.Block(const AFirst, ASecond: TXcomMapCell): TXcomMap;
begin
  Result.Header.SizeY := 1;
  Result.Header.SizeX := 2;
  Result.Header.SizeZ := 1;
  SetLength(Result.Cells, 2);
  Result.Cells[0] := AFirst;
  Result.Cells[1] := ASecond;
end;

procedure TTestXcomMapPicture.DovrebbeFare8PixelPerCella;
var
  LImage: TXcomImage;
begin
  LImage := TXcomMapPicture.Render(Block(Default(TXcomMapCell), Default(TXcomMapCell)), 0);
  Assert.AreEqual(16, LImage.Width);
  Assert.AreEqual(8, LImage.Height);
end;

procedure TTestXcomMapPicture.DovrebbeRiempireLaCellaConIlPavimento;
var
  LCell: TXcomMapCell;
  LImage: TXcomImage;
begin
  LCell := Default(TXcomMapCell);
  LCell.Floor := 3;
  LImage := TXcomMapPicture.Render(Block(LCell, Default(TXcomMapCell)), 0);
  Assert.AreEqual(XCOM_MAP_PICTURE_FLOOR, Integer(LImage.GetPixel(3, 3)));
  Assert.AreEqual(XCOM_MAP_PICTURE_FLOOR, Integer(LImage.GetPixel(7, 7)));
  Assert.AreEqual(0, Integer(LImage.GetPixel(8, 3)));
end;

procedure TTestXcomMapPicture.DovrebbeLasciareVuotaUnaCellaSenzaNulla;
var
  LImage: TXcomImage;
  LByte: Byte;
begin
  LImage := TXcomMapPicture.Render(Block(Default(TXcomMapCell), Default(TXcomMapCell)), 0);
  for LByte in LImage.Pixels do
    Assert.AreEqual(0, Integer(LByte));
end;

procedure TTestXcomMapPicture.DovrebbeDisegnareUnOggettoAlCentro;
var
  LCell: TXcomMapCell;
  LImage: TXcomImage;
begin
  LCell := Default(TXcomMapCell);
  LCell.Obj := 1;
  LImage := TXcomMapPicture.Render(Block(Default(TXcomMapCell), LCell), 0);
  Assert.AreEqual(XCOM_MAP_PICTURE_OBJECT, Integer(LImage.GetPixel(8 + 4, 4)));
  Assert.AreEqual(0, Integer(LImage.GetPixel(8 + 1, 4)));
end;

procedure TTestXcomMapPicture.DovrebbeDisegnareLeParetiSuiLati;
var
  LCell: TXcomMapCell;
  LImage: TXcomImage;
begin
  LCell := Default(TXcomMapCell);
  LCell.WestWall := 1;
  LCell.NorthWall := 1;
  LImage := TXcomMapPicture.Render(Block(LCell, Default(TXcomMapCell)), 0);
  Assert.AreEqual(XCOM_MAP_PICTURE_WEST_WALL, Integer(LImage.GetPixel(0, 5)));
  Assert.AreEqual(XCOM_MAP_PICTURE_NORTH_WALL, Integer(LImage.GetPixel(5, 0)));
  Assert.AreEqual(0, Integer(LImage.GetPixel(5, 5)));
end;

procedure TTestXcomMapPicture.DovrebbeRifiutareUnPianoCheNonCe;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomMapPicture.Render(Block(Default(TXcomMapCell), Default(TXcomMapCell)), 1);
    end, EXcomException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMapPicture);

end.
