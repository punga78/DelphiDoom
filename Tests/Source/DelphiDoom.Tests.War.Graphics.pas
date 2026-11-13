{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the graphic resources of an archive  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Graphics;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Graphics.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarGraphics = class(TObject)
  private
    function Entry(AIndex: Integer; AType: TWarRecordType; AParam1, AParam2: Word): TWarCatalogEntry;
    function Palette(AFill: Integer): TBytes;
    function Make: IWarGraphics;
  public
    [Test]
    procedure DovrebbeRifiutareUnArchivioNil;
    [Test]
    procedure DovrebbeRifiutareUnCatalogoNil;
    [Test]
    procedure DovrebbeLeggereUnaPaletta;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCheNonLoE;
    [Test]
    procedure DovrebbeRifiutareUnIndiceCheNonEInTabella;
    [Test]
    procedure DovrebbeComporreDuePalette;
    [Test]
    procedure DovrebbeDareTuttiZeriSenzaPalette;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaDiUnaVoceChePalettaNonE;
    [Test]
    procedure DovrebbeLeggereUnImmagineConLaPalettaDellaTabella;
    [Test]
    procedure DovrebbeLeggereUnImmagineConDuePalette;
    [Test]
    procedure DovrebbeRifiutareUnImmagineDiUnaPalettaCheNonE;
    [Test]
    procedure DovrebbeRifiutareUnaVoceDiTipoDiverso;
    [Test]
    procedure DovrebbeRifiutareUnRecordCheNonSiPuoLeggere;
    [Test]
    procedure DovrebbeLeggereUnoSprite;
    [Test]
    procedure DovrebbeLeggereUnCursore;
    [Test]
    procedure DovrebbeDareLeTegoleCosiCome;
    [Test]
    procedure DovrebbeLeggereLImmagineDiUnTileset;
    [Test]
    procedure DovrebbeRifiutareUnTilesetSenzaLeTegole;
  end;

implementation

uses
  DelphiDoom.War.Catalog, DelphiDoom.War.Factory, DelphiDoom.Tests.War.Builders;

const
  REC_TEXT = 0;
  REC_PALETTE = 1;
  REC_PALETTE_2 = 2;
  REC_IMAGE = 3;
  REC_IMAGE_TWO_PALETTES = 4;
  REC_SPRITE = 5;
  REC_CURSOR = 6;
  REC_TILES = 7;
  REC_TILESET = 8;
  REC_IMAGE_BAD_PALETTE = 9;
  REC_IMAGE_UNLISTED_PALETTE = 10;
  REC_IMAGE_PLACEHOLDER = 11;
  REC_TILESET_NO_TILES = 12;

{ TTestWarGraphics }

function TTestWarGraphics.Entry(AIndex: Integer; AType: TWarRecordType; AParam1, AParam2: Word): TWarCatalogEntry;
begin
  Result := Default(TWarCatalogEntry);
  Result.Index := AIndex;
  Result.RecordType := AType;
  Result.Name := IntToStr(AIndex);
  Result.Param1 := AParam1;
  Result.Param2 := AParam2;
end;

function TTestWarGraphics.Palette(AFill: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 768);
  for LIndex := 0 to 767 do
    if AFill >= 0 then
      Result[LIndex] := Byte(AFill)
    else
      Result[LIndex] := Byte(LIndex mod 64);
end;

function TTestWarGraphics.Make: IWarGraphics;
var
  LBuilder: TWarArchiveBuilder;
  LSprite: TBytes;
  LTilesetRaw: TBytes;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(TBytes.Create(1, 2, 3));                                   // 0 text
    LBuilder.AddUncompressed(Palette(-1));                                              // 1 palette
    LBuilder.AddUncompressed(Palette(63));                                              // 2 palette
    LBuilder.AddUncompressed(TBytes.Create(1, 0, 1, 0, 1));                             // 3 image, color 1
    LBuilder.AddUncompressed(TBytes.Create(1, 0, 2, 0, 1, 200));                        // 4 image, 2 palettes
    LSprite := TBytes.Create(1, 0, 2, 2, 1, 1, 1, 1, 12, 0, 0, 0, 7);                   // 5 sprite
    LBuilder.AddUncompressed(LSprite);
    LBuilder.AddUncompressed(TBytes.Create(3, 0, 4, 0, 1, 0, 1, 0, 1));                 // 6 cursor
    LBuilder.AddUncompressed(Palette(0));                                               // 7 tiles (zeros: 768 bytes)
    LTilesetRaw := TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0);
    LBuilder.AddUncompressed(LTilesetRaw);                                              // 8 tileset
    LBuilder.AddUncompressed(TBytes.Create(1, 0, 1, 0, 1));                             // 9 image
    LBuilder.AddUncompressed(TBytes.Create(1, 0, 1, 0, 1));                             // 10 image
    LBuilder.AddPlaceholder(0);                                                         // 11 placeholder
    LBuilder.AddUncompressed(LTilesetRaw);                                              // 12 tileset
    Result := TWarFactory.CreateGraphics(
      TWarFactory.OpenStream(TBytesStream.Create(LBuilder.Build(WAR_ARCHIVE_ID_RETAIL_DOS)), True, nil),
      TWarCatalog.Create(TArray<TWarCatalogEntry>.Create(
        Entry(REC_TEXT, wrtText, 0, 0), Entry(REC_PALETTE, wrtPalette, 0, 0), Entry(REC_PALETTE_2, wrtPalette, 0, 0),
        Entry(REC_IMAGE, wrtImage, REC_PALETTE, 0), Entry(REC_IMAGE_TWO_PALETTES, wrtImage, REC_PALETTE, REC_PALETTE_2),
        Entry(REC_SPRITE, wrtSprite, REC_PALETTE, 0), Entry(REC_CURSOR, wrtCursor, REC_PALETTE, 0),
        Entry(REC_TILES, wrtTiles, REC_PALETTE, 0), Entry(REC_TILESET, wrtTileset, REC_TILES, 0),
        Entry(REC_IMAGE_BAD_PALETTE, wrtImage, REC_IMAGE, 0), Entry(REC_IMAGE_UNLISTED_PALETTE, wrtImage, 99, 0),
        Entry(REC_IMAGE_PLACEHOLDER, wrtImage, REC_PALETTE, 0), Entry(REC_TILESET_NO_TILES, wrtTileset, REC_TEXT, 0))));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnArchivioNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarFactory.CreateGraphics(nil, TWarFactory.CreateCatalog);
    end, EArgumentNilException);
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnCatalogoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarFactory.CreateGraphics(TWarFactory.OpenStream(TBytesStream.Create(TBytes.Create($18, 0, 0, 0, 0, 0, 0, 0)), True, nil), nil);
    end, EArgumentNilException);
end;

procedure TTestWarGraphics.DovrebbeLeggereUnaPaletta;
var
  LPalette: TBytes;
begin
  LPalette := Make.GetPalette(REC_PALETTE);
  Assert.AreEqual(768, Length(LPalette));
  Assert.AreEqual(12, Integer(LPalette[3]));
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnaPalettaCheNonLoE;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.GetPalette(REC_IMAGE);
    end, EWarException);
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnIndiceCheNonEInTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.GetPalette(500);
    end, EWarException);
end;

procedure TTestWarGraphics.DovrebbeComporreDuePalette;
var
  LPalette: TBytes;
begin
  LPalette := Make.ComposePalette(REC_PALETTE, REC_PALETTE_2);
  // il colore 1 e' della prima, il 200 della seconda (252 = 63 * 4)
  Assert.AreEqual(12, Integer(LPalette[3]));
  Assert.AreEqual(252, Integer(LPalette[200 * 3]));
end;

procedure TTestWarGraphics.DovrebbeDareTuttiZeriSenzaPalette;
var
  LPalette: TBytes;
begin
  LPalette := Make.ComposePalette(0, 0);
  Assert.AreEqual(768, Length(LPalette));
  Assert.AreEqual(0, Integer(LPalette[3]));
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnaPalettaDiUnaVoceChePalettaNonE;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.ComposePalette(REC_IMAGE, 0);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      Make.ComposePalette(0, 99);
    end, EWarException);
end;

procedure TTestWarGraphics.DovrebbeLeggereUnImmagineConLaPalettaDellaTabella;
var
  LImage: TWarImage;
begin
  LImage := Make.GetImage(REC_IMAGE);
  Assert.AreEqual(1, Integer(LImage.Width));
  Assert.AreEqual(12, Integer(LImage.Pixels[0]));
  Assert.AreEqual(16, Integer(LImage.Pixels[1]));
  Assert.AreEqual(20, Integer(LImage.Pixels[2]));
  Assert.AreEqual(255, Integer(LImage.Pixels[3]));
end;

procedure TTestWarGraphics.DovrebbeLeggereUnImmagineConDuePalette;
var
  LImage: TWarImage;
begin
  LImage := Make.GetImage(REC_IMAGE_TWO_PALETTES);
  Assert.AreEqual(12, Integer(LImage.Pixels[0]));
  Assert.AreEqual(252, Integer(LImage.Pixels[4]));
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnImmagineDiUnaPalettaCheNonE;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.GetImage(REC_IMAGE_BAD_PALETTE);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      Make.GetImage(REC_IMAGE_UNLISTED_PALETTE);
    end, EWarException);
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnaVoceDiTipoDiverso;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.GetSprite(REC_IMAGE);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      Make.GetImage(REC_TEXT);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      Make.GetCursor(REC_SPRITE);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      Make.GetTiles(REC_TILESET);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      Make.GetTileset(REC_TILES);
    end, EWarException);
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnRecordCheNonSiPuoLeggere;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.GetImage(REC_IMAGE_PLACEHOLDER);
    end, EWarException);
end;

procedure TTestWarGraphics.DovrebbeLeggereUnoSprite;
var
  LSprite: TWarSprite;
begin
  LSprite := Make.GetSprite(REC_SPRITE);
  Assert.AreEqual(1, Length(LSprite.Frames));
  Assert.AreEqual(2, Integer(LSprite.FrameWidth));
  // il pixel (1, 1) dell'area ha il colore 7 = (7 * 3 mod 64) * 4
  Assert.AreEqual(((7 * 3) mod 64) * 4, Integer(LSprite.Frames[0].Pixels[3 * 4]));
end;

procedure TTestWarGraphics.DovrebbeLeggereUnCursore;
var
  LCursor: TWarCursor;
begin
  LCursor := Make.GetCursor(REC_CURSOR);
  Assert.AreEqual(3, Integer(LCursor.HotX));
  Assert.AreEqual(4, Integer(LCursor.HotY));
  Assert.AreEqual(12, Integer(LCursor.Pixels[0]));
end;

procedure TTestWarGraphics.DovrebbeDareLeTegoleCosiCome;
var
  LTiles: TWarTiles;
begin
  LTiles := Make.GetTiles(REC_TILES);
  Assert.AreEqual(768, Length(LTiles.Data));
  Assert.AreEqual(REC_PALETTE, Integer(LTiles.Palette1));
  Assert.AreEqual(0, Integer(LTiles.Palette2));
end;

procedure TTestWarGraphics.DovrebbeLeggereLImmagineDiUnTileset;
var
  LTileset: TWarTileset;
begin
  LTileset := Make.GetTileset(REC_TILESET);
  Assert.AreEqual(Cardinal(1), LTileset.TilesCount);
  Assert.AreEqual(512 * 256 * 4, Length(LTileset.Pixels));
  // tutte le tegole leggono il byte 0 delle tegole, il colore 0: trasparente
  Assert.AreEqual(0, Integer(LTileset.Pixels[3]));
end;

procedure TTestWarGraphics.DovrebbeRifiutareUnTilesetSenzaLeTegole;
begin
  Assert.WillRaise(
    procedure
    begin
      Make.GetTileset(REC_TILESET_NO_TILES);
    end, EWarException);
end;

end.
