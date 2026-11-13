{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - a map and its reader                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Map;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMap = class(TObject)
  private
    FMap: IGreedMap;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareOgniPianoDi4096Byte;
    [Test]
    procedure DovrebbeLeggereIPianiUnoDopoLAltro;
    [Test]
    procedure DovrebbeDareIlByteDiUnTile;
    [Test]
    procedure DovrebbeIndicizzareUnTileConRigaPerSessantaquattro;
    [Test]
    procedure DovrebbeRifiutareUnTileFuoriDallaMappa;
    [Test]
    procedure DovrebbeTenereIByteDopoIPiani;
    [Test]
    procedure DovrebbeDareUnaCodaVuotaSenzaByteInPiu;
    [Test]
    procedure DovrebbeDareCopieDeiPiani;
    [Test]
    procedure DovrebbeRifiutareUnaMappaTroppoCorta;
    [Test]
    procedure DovrebbeLeggereLaMappaConIlLettore;
  end;

implementation

uses
  DelphiDoom.Greed.Map, DelphiDoom.Greed.Factory, DelphiDoom.Tests.Greed.Builders;

{ TTestGreedMap }

procedure TTestGreedMap.Setup;
begin
  FMap := TGreedMap.Create(TGreedTestArchive.Map0);
end;

procedure TTestGreedMap.TearDown;
begin
  FMap := nil;
end;

procedure TTestGreedMap.DovrebbeDareOgniPianoDi4096Byte;
var
  LPlane: TGreedPlane;
begin
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    Assert.AreEqual<Integer>(GREED_MAP_TILES, Length(FMap.Planes[LPlane]));
end;

procedure TTestGreedMap.DovrebbeLeggereIPianiUnoDopoLAltro;
begin
  // the byte i of the plane p is (p * 16 + i) mod 256
  Assert.AreEqual(0, Integer(FMap.Planes[gpNorthWall][0]));
  Assert.AreEqual(5, Integer(FMap.Planes[gpNorthWall][5]));
  Assert.AreEqual(32, Integer(FMap.Planes[gpWestWall][0]));
  Assert.AreEqual(4 * 16 + 100, Integer(FMap.Planes[gpFloorPic][100]));
  Assert.AreEqual((17 * 16 + 4095) mod 256, Integer(FMap.Planes[gpMapSlopes][4095]));
end;

procedure TTestGreedMap.DovrebbeDareIlByteDiUnTile;
begin
  Assert.AreEqual(Integer(FMap.Planes[gpFloorPic][3 * 64 + 7]), Integer(FMap.Tiles[gpFloorPic, 7, 3]));
end;

procedure TTestGreedMap.DovrebbeIndicizzareUnTileConRigaPerSessantaquattro;
begin
  // the tile (x, y) is at y * 64 + x: the plane has (x + y * 64) mod 256 + 0 in the first plane
  Assert.AreEqual((10 + 20 * 64) mod 256, Integer(FMap.Tiles[gpNorthWall, 10, 20]));
  Assert.AreEqual((63 + 63 * 64) mod 256, Integer(FMap.Tiles[gpNorthWall, 63, 63]));
end;

procedure TTestGreedMap.DovrebbeRifiutareUnTileFuoriDallaMappa;
begin
  Assert.WillRaise(procedure begin FMap.Tiles[gpNorthWall, -1, 0]; end, EGreedDataException);
  Assert.WillRaise(procedure begin FMap.Tiles[gpNorthWall, 0, -1]; end, EGreedDataException);
  Assert.WillRaise(procedure begin FMap.Tiles[gpNorthWall, 64, 0]; end, EGreedDataException);
  Assert.WillRaise(procedure begin FMap.Tiles[gpNorthWall, 0, 64]; end, EGreedDataException);
end;

procedure TTestGreedMap.DovrebbeTenereIByteDopoIPiani;
begin
  Assert.AreEqual<Integer>(3, Length(FMap.Trailer));
  Assert.AreEqual(65, Integer(FMap.Trailer[0]));
  Assert.AreEqual(67, Integer(FMap.Trailer[2]));
end;

procedure TTestGreedMap.DovrebbeDareUnaCodaVuotaSenzaByteInPiu;
var
  LMap: IGreedMap;
begin
  LMap := TGreedMap.Create(TGreedLumps.MapBytes(nil));
  Assert.AreEqual<Integer>(0, Length(LMap.Trailer));
end;

procedure TTestGreedMap.DovrebbeDareCopieDeiPiani;
var
  LPlane: TBytes;
begin
  LPlane := FMap.Planes[gpNorthWall];
  LPlane[0] := 200;
  Assert.AreEqual(0, Integer(FMap.Planes[gpNorthWall][0]));
  LPlane := FMap.Trailer;
  LPlane[0] := 0;
  Assert.AreEqual(65, Integer(FMap.Trailer[0]));
end;

procedure TTestGreedMap.DovrebbeRifiutareUnaMappaTroppoCorta;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, GREED_MAP_BYTES - 1);
  Assert.WillRaise(procedure begin TGreedMap.Create(LBytes); end, EGreedDataException);
  Assert.WillRaise(procedure begin TGreedMap.Create(nil); end, EGreedDataException);
end;

procedure TTestGreedMap.DovrebbeLeggereLaMappaConIlLettore;
var
  LMap: IGreedMap;
begin
  LMap := TGreedFactory.CreateMapReader.Read(TGreedTestArchive.Map0);
  Assert.AreEqual(5, Integer(LMap.Planes[gpNorthWall][5]));
  Assert.AreEqual<Integer>(3, Length(LMap.Trailer));
  Assert.WillRaise(procedure begin TGreedFactory.CreateMapReader.Read(TBytes.Create(1)); end, EGreedDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMap);

end.
