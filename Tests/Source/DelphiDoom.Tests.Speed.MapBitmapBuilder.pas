{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedMapBitmapBuilder                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.MapBitmapBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Speed.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedMapBitmapBuilder = class(TObject)
  strict private
    FBuilder: ISpeedMapBitmapBuilder;
    /// <summary>A map of tiles all of the tile ATile, turned by AAngle</summary>
    function Map(ATile: SmallInt; AAngle: Byte): TBytes;
    /// <summary>ACount tiles; in the tile T the pixel P has the value (T * 7 + P) mod 251</summary>
    function Tiles(ACount: Integer): TBytes;
    function Pixel(const ABitmap: TBytes; AColumn, ARow: Integer): Byte;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMetterelePiastrelleAlLoroPostoCapovolte;
    [Test]
    procedure DovrebbeGirareUnaPiastrellaDiUnQuarto;
    [Test]
    procedure DovrebbeGirareUnaPiastrellaDiMezzo;
    [Test]
    procedure DovrebbeGirareUnaPiastrellaDiTreQuarti;
    [Test]
    procedure DovrebbeNonGirareConUnAngoloOltreIlTre;
    [Test]
    procedure DovrebbeLasciareNereLePiastrelleCheNonCe;
    [Test]
    procedure DovrebbeDareLaPrimaPiastrella;
    [Test]
    procedure DovrebbeRifiutareUnFileDelCircuitoCorto;
    [Test]
    procedure DovrebbeDareUnaImmagineDiSediciMegabyte;
  end;

implementation

uses
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Factory;

{ TTestSpeedMapBitmapBuilder }

procedure TTestSpeedMapBitmapBuilder.Setup;
begin
  FBuilder := TSpeedFactory.CreateMapBitmapBuilder;
end;

procedure TTestSpeedMapBitmapBuilder.TearDown;
begin
  FBuilder := nil;
end;

function TTestSpeedMapBitmapBuilder.Map(ATile: SmallInt; AAngle: Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 4 + 4096 * 2 + 4096);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to 4095 do
  begin
    PSmallInt(@Result[4 + LIndex * 2])^ := ATile;
    Result[4 + 8192 + LIndex] := AAngle;
  end;
end;

function TTestSpeedMapBitmapBuilder.Tiles(ACount: Integer): TBytes;
var
  LTile: Integer;
  LPixel: Integer;
begin
  SetLength(Result, ACount * 4096);
  for LTile := 0 to ACount - 1 do
    for LPixel := 0 to 4095 do
      Result[LTile * 4096 + LPixel] := Byte((LTile * 7 + LPixel) mod 251);
end;

function TTestSpeedMapBitmapBuilder.Pixel(const ABitmap: TBytes; AColumn, ARow: Integer): Byte;
begin
  // the picture is by columns and upside down
  Result := ABitmap[AColumn * 4096 + (4095 - ARow)];
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeMetterelePiastrelleAlLoroPostoCapovolte;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(2, 0), Tiles(3), LBitmap, LFirst));
  // the pixel (5, 9) of the first tile (the columns of the tile are the x): tile[9 * 64 + 5]
  Assert.AreEqual<Byte>(Byte((2 * 7 + 9 * 64 + 5) mod 251), Pixel(LBitmap, 5, 9));
  // in the last tile of the map (63, 63) the pixel (4095, 4095)
  Assert.AreEqual<Byte>(Byte((2 * 7 + 63 * 64 + 63) mod 251), Pixel(LBitmap, 4095, 4095));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeGirareUnaPiastrellaDiUnQuarto;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(1, 1), Tiles(2), LBitmap, LFirst));
  // rotated by 1: tile'[row * 64 + col] = tile[(63 - col) * 64 + row]; (col 5, row 9) -> tile[58 * 64 + 9]
  Assert.AreEqual<Byte>(Byte((1 * 7 + 58 * 64 + 9) mod 251), Pixel(LBitmap, 5, 9));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeGirareUnaPiastrellaDiMezzo;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(1, 2), Tiles(2), LBitmap, LFirst));
  // rotated by 2: tile'[row * 64 + col] = tile[(63 - row) * 64 + 63 - col]
  Assert.AreEqual<Byte>(Byte((1 * 7 + 54 * 64 + 58) mod 251), Pixel(LBitmap, 5, 9));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeGirareUnaPiastrellaDiTreQuarti;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(1, 3), Tiles(2), LBitmap, LFirst));
  // rotated by 3: tile'[row * 64 + col] = tile[col * 64 + 63 - row]
  Assert.AreEqual<Byte>(Byte((1 * 7 + 5 * 64 + 54) mod 251), Pixel(LBitmap, 5, 9));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeNonGirareConUnAngoloOltreIlTre;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(1, 5), Tiles(2), LBitmap, LFirst));
  Assert.AreEqual<Byte>(Byte((1 * 7 + 9 * 64 + 5) mod 251), Pixel(LBitmap, 5, 9));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeLasciareNereLePiastrelleCheNonCe;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  // the tile 9 is not in the file of 2 tiles, nor is a negative one
  Assert.IsTrue(FBuilder.Build(Map(9, 0), Tiles(2), LBitmap, LFirst));
  Assert.AreEqual<Byte>(0, Pixel(LBitmap, 10, 10));
  Assert.IsTrue(FBuilder.Build(Map(-1, 0), Tiles(2), LBitmap, LFirst));
  Assert.AreEqual<Byte>(0, Pixel(LBitmap, 10, 10));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeDareLaPrimaPiastrella;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(4, 0), Tiles(5), LBitmap, LFirst));
  Assert.AreEqual(4, LFirst);
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeRifiutareUnFileDelCircuitoCorto;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsFalse(FBuilder.Build(TBytes.Create(1, 2, 3), Tiles(1), LBitmap, LFirst));
  Assert.AreEqual(0, Length(LBitmap));
end;

procedure TTestSpeedMapBitmapBuilder.DovrebbeDareUnaImmagineDiSediciMegabyte;
var
  LBitmap: TBytes;
  LFirst: Integer;
begin
  Assert.IsTrue(FBuilder.Build(Map(0, 0), Tiles(1), LBitmap, LFirst));
  Assert.AreEqual(4096 * 4096, Length(LBitmap));
end;

end.
