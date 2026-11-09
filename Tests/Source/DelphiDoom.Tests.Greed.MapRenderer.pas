{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - a map seen from above               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.MapRenderer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMapRenderer = class(TObject)
  private
    FRenderer: IGreedMapRenderer;
    FImage: TGreedImage;
    function Pixel(X, Y: Integer): Integer;
    function MapWith(const AEdit: TProc<TBytes, TBytes, TBytes>): IGreedMap;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDisegnareOttoPixelPerTile;
    [Test]
    procedure DovrebbeDisegnareIlPavimentoCampionandoOgniOttoPixel;
    [Test]
    procedure DovrebbeDisegnareILatiNordConIlColoreDelMuro;
    [Test]
    procedure DovrebbeDisegnareILatiOvestConIlColoreDelMuro;
    [Test]
    procedure DovrebbeLasciareVuotoUnTileSenzaPavimentoNeMuri;
    [Test]
    procedure DovrebbeIgnorareUnNumeroDiPavimentoOltreIFlat;
    [Test]
    procedure DovrebbeIgnorareUnNumeroDiMuroOltreIMuri;
    [Test]
    procedure DovrebbeDisegnareSenzaIGruppiDelleTexture;
    [Test]
    procedure DovrebbeRifiutareUnaMappaNil;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Greed.Map, DelphiDoom.Greed.MapRenderer, DelphiDoom.Greed.FlatDecoder, DelphiDoom.Greed.WallDecoder,
  DelphiDoom.Greed.Factory, DelphiDoom.Tests.Greed.Builders;

{ TTestGreedMapRenderer }

function TTestGreedMapRenderer.MapWith(const AEdit: TProc<TBytes, TBytes, TBytes>): IGreedMap;
var
  LBytes: TBytes;
  LFloor: TBytes;
  LNorth: TBytes;
  LWest: TBytes;
begin
  // a map of zeros, then the edit of the floor, north wall and west wall planes
  SetLength(LBytes, GREED_MAP_BYTES);
  LFloor := Copy(LBytes, Ord(gpFloorPic) * GREED_MAP_TILES, GREED_MAP_TILES);
  LNorth := Copy(LBytes, Ord(gpNorthWall) * GREED_MAP_TILES, GREED_MAP_TILES);
  LWest := Copy(LBytes, Ord(gpWestWall) * GREED_MAP_TILES, GREED_MAP_TILES);
  AEdit(LFloor, LNorth, LWest);
  Move(LFloor[0], LBytes[Ord(gpFloorPic) * GREED_MAP_TILES], GREED_MAP_TILES);
  Move(LNorth[0], LBytes[Ord(gpNorthWall) * GREED_MAP_TILES], GREED_MAP_TILES);
  Move(LWest[0], LBytes[Ord(gpWestWall) * GREED_MAP_TILES], GREED_MAP_TILES);
  Result := TGreedMap.Create(LBytes);
end;

function TTestGreedMapRenderer.Pixel(X, Y: Integer): Integer;
begin
  Result := FImage.Pixels[Y * FImage.Width + X];
end;

procedure TTestGreedMapRenderer.Setup;
begin
  FRenderer := TGreedFactory.CreateMapRenderer(TGreedTestArchive.Open);
  FImage := FRenderer.Render(MapWith(
    procedure(AFloor, ANorth, AWest: TBytes)
    begin
      AFloor[0] := 1;      // tile (0, 0): flat 1
      AFloor[1] := 2;      // tile (1, 0): flat 2, wall 1 on the north side
      ANorth[1] := 1;
      AWest[2] := 2;       // tile (2, 0): wall 2 on the west side
      AFloor[3] := 3;      // tile (3, 0): flat 3, that does not exist
      ANorth[3] := 3;      // wall 3, that does not exist
    end));
end;

procedure TTestGreedMapRenderer.TearDown;
begin
  FRenderer := nil;
end;

procedure TTestGreedMapRenderer.DovrebbeDisegnareOttoPixelPerTile;
begin
  Assert.AreEqual(512, FImage.Width);
  Assert.AreEqual(512, FImage.Height);
  Assert.AreEqual(512 * 512, Length(FImage.Pixels));
  Assert.AreEqual(8, GREED_MAP_TILE_PIXELS);
end;

procedure TTestGreedMapRenderer.DovrebbeDisegnareIlPavimentoCampionandoOgniOttoPixel;
begin
  // the flat has the pixel i = i mod 251 + 1: the pixel (dx * 8, dy * 8) is at (dy * 8) * 64 + dx * 8
  Assert.AreEqual(1, Pixel(0, 0));
  Assert.AreEqual(8 mod 251 + 1, Pixel(1, 0));
  Assert.AreEqual((8 * 64) mod 251 + 1, Pixel(0, 1));
  Assert.AreEqual((7 * 8 * 64 + 7 * 8) mod 251 + 1, Pixel(7, 7));
end;

procedure TTestGreedMapRenderer.DovrebbeDisegnareILatiNordConIlColoreDelMuro;
var
  LDeltaX: Integer;
begin
  // wall 1 has 8 rows; the color is the pixel (32, 4): 32 + 4 + 1
  for LDeltaX := 0 to 7 do
    Assert.AreEqual(37, Pixel(8 + LDeltaX, 0));
  Assert.AreNotEqual(37, Pixel(8, 1));
end;

procedure TTestGreedMapRenderer.DovrebbeDisegnareILatiOvestConIlColoreDelMuro;
var
  LDeltaY: Integer;
begin
  // wall 2 has 64 rows; the color is the pixel (32, 32): 65
  for LDeltaY := 0 to 7 do
    Assert.AreEqual(65, Pixel(16, LDeltaY));
  Assert.AreNotEqual(65, Pixel(17, 1));
end;

procedure TTestGreedMapRenderer.DovrebbeLasciareVuotoUnTileSenzaPavimentoNeMuri;
begin
  Assert.AreEqual(0, Pixel(8 * 10 + 3, 5));
  Assert.AreEqual(0, Pixel(511, 511));
end;

procedure TTestGreedMapRenderer.DovrebbeIgnorareUnNumeroDiPavimentoOltreIFlat;
begin
  // tile (3, 0): flat 3 is the lump of endflats
  Assert.AreEqual(0, Pixel(24 + 2, 3));
end;

procedure TTestGreedMapRenderer.DovrebbeIgnorareUnNumeroDiMuroOltreIMuri;
begin
  // wall 3 is the lump of endwalls: no row on the north side of the tile (3, 0)
  Assert.AreEqual(0, Pixel(24 + 2, 0));
end;

procedure TTestGreedMapRenderer.DovrebbeDisegnareSenzaIGruppiDelleTexture;
var
  LBlo: TGreedBlo;
  LRenderer: IGreedMapRenderer;
  LImage: TGreedImage;
begin
  LBlo := TGreedBlo.Create;
  try
    LRenderer := TGreedFactory.CreateMapRenderer(LBlo.Add('x', nil).Open);
  finally
    LBlo.Free;
  end;
  LImage := LRenderer.Render(MapWith(
    procedure(AFloor, ANorth, AWest: TBytes)
    begin
      AFloor[0] := 1;
      ANorth[0] := 1;
      AWest[0] := 1;
    end));
  Assert.AreEqual(512 * 512, Length(LImage.Pixels));
  Assert.AreEqual(0, Integer(LImage.Pixels[0]));
end;

procedure TTestGreedMapRenderer.DovrebbeRifiutareUnaMappaNil;
begin
  Assert.WillRaise(procedure begin FRenderer.Render(nil); end, EArgumentNilException);
end;

procedure TTestGreedMapRenderer.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(procedure begin TGreedMapRenderer.Create(nil, TGreedFlatDecoder.Create, TGreedWallDecoder.Create); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedMapRenderer.Create(TGreedTestArchive.Open, nil, TGreedWallDecoder.Create); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedMapRenderer.Create(TGreedTestArchive.Open, TGreedFlatDecoder.Create, nil); end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMapRenderer);

end.
