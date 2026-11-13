{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - images, cursors, sprites, tilesets   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Pixels;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Graphics.Types;

type
  /// <summary>The colors of the tests: the color N has R = N (G and B zero), the color 0 is transparent</summary>
  TWarTestColors = class
  public
    class function Lookup: TWarColorLookup; static;
    /// <summary>The red byte of the pixel PixelIndex of a decoded buffer</summary>
    class function Red(const APixels: TBytes; APixelIndex: Integer): Integer; static;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarGraphicsTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereOttoByteLaTestataDelFotogramma;
    [Test]
    procedure DovrebbeAvereQuattroByteLaTestataDiImmagineESprite;
    [Test]
    procedure DovrebbeAvereOttoByteLaTestataDelCursoreEDellaTegola;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarImageDecoder = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereDimensioniEPixel;
    [Test]
    procedure DovrebbeFareTrasparenteIlColoreZero;
    [Test]
    procedure DovrebbeAccettareUnaImmagineVuota;
    [Test]
    procedure DovrebbeIgnorareICodiciOltreLeDimensioni;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaTuttiIPixel;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaTestata;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarCursorDecoder = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggerePuntoCaldoDimensioniEPixel;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaTuttiIPixel;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaTestata;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarSpriteDecoder = class(TObject)
  private
    function Header(AFrames, AWidth, AHeight: Integer): TBytes;
    procedure AddFrame(var ARaw: TBytes; ADx, ADy, AWidth, AHeight: Integer; AOffset: Cardinal);
    procedure AddBytes(var ARaw: TBytes; const AValues: array of Byte);
  public
    [Test]
    procedure DovrebbeLeggereLeDimensioniEIFotogrammi;
    [Test]
    procedure DovrebbeDisegnareIlFotogrammaNellaSuaPosizione;
    [Test]
    procedure DovrebbeLasciareTrasparenteCioCheNonDisegna;
    [Test]
    procedure DovrebbeTenereIFotogrammiSeparati;
    [Test]
    procedure DovrebbeScrivereNellaRigaSuccessivaSeIlFotogrammaEsceDallaRiga;
    [Test]
    procedure DovrebbeScrivereNelFotogrammaSuccessivoSeEsceDallArea;
    [Test]
    procedure DovrebbeRifiutareChiScriveOltreIlBloccoDeiPixel;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaTuttiIPixel;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaTutteLeTestate;
    [Test]
    procedure DovrebbeRifiutareUnRecordSenzaLaTestata;
    [Test]
    procedure DovrebbeAccettareUnoSpriteSenzaFotogrammi;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarTilesetDecoder = class(TObject)
  private
    function Tiles(AMiniTiles: Integer): TBytes;
    function Entry(AMini0, AMini1, AMini2, AMini3: Word): TBytes;
    function Decode(const ARaw, ATiles: TBytes): TWarTileset;
    function Pixel(const ATileset: TWarTileset; AX, AY: Integer): Integer;
  public
    [Test]
    procedure DovrebbeContareLeTegoleDaOttoByteLUna;
    [Test]
    procedure DovrebbeDisporreIQuattroMiniTegolaNelQuadrato;
    [Test]
    procedure DovrebbeLeggereLaMiniTegolaDalloScartoDelRecordDelleTegole;
    [Test]
    procedure DovrebbeSpecchiareInOrizzontaleConIlBitDue;
    [Test]
    procedure DovrebbeSpecchiareInVerticaleConIlBitUno;
    [Test]
    procedure DovrebbeSpecchiareInEntrambeLeDirezioni;
    [Test]
    procedure DovrebbeAndareAcapoDopo32Tegole;
    [Test]
    procedure DovrebbeFareTrasparenteIlColoreZero;
    [Test]
    procedure DovrebbeDareUnaImmagineDi512Per256;
    [Test]
    procedure DovrebbeRifiutareUnaMiniTegolaFuoriDalRecordDelleTegole;
    [Test]
    procedure DovrebbeTroncareA16BitLoScartoDellaMiniTegola;
    [Test]
    procedure DovrebbeRifiutareTroppeTegole;
    [Test]
    procedure DovrebbeIgnorareIByteOltreLUltimaTegola;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Graphics.ImageDecoder, DelphiDoom.War.Graphics.CursorDecoder,
  DelphiDoom.War.Graphics.SpriteDecoder, DelphiDoom.War.Graphics.TilesetDecoder;

{ TWarTestColors }

class function TWarTestColors.Lookup: TWarColorLookup;
var
  LColor: Integer;
begin
  Result[0] := 0;
  for LColor := 1 to 255 do
    Result[LColor] := Cardinal(LColor) or $FF000000;
end;

class function TWarTestColors.Red(const APixels: TBytes; APixelIndex: Integer): Integer;
begin
  Result := APixels[APixelIndex * 4];
end;

{ TTestWarGraphicsTypes }

procedure TTestWarGraphicsTypes.DovrebbeAvereOttoByteLaTestataDelFotogramma;
begin
  Assert.AreEqual(8, SizeOf(TWarSpriteFrameEntry));
end;

procedure TTestWarGraphicsTypes.DovrebbeAvereQuattroByteLaTestataDiImmagineESprite;
begin
  Assert.AreEqual(4, SizeOf(TWarImageHeader));
  Assert.AreEqual(4, SizeOf(TWarSpriteHeader));
end;

procedure TTestWarGraphicsTypes.DovrebbeAvereOttoByteLaTestataDelCursoreEDellaTegola;
begin
  Assert.AreEqual(8, SizeOf(TWarCursorHeader));
  Assert.AreEqual(8, SizeOf(TWarTilesetEntry));
end;

{ TTestWarImageDecoder }

procedure TTestWarImageDecoder.DovrebbeLeggereDimensioniEPixel;
var
  LImage: TWarImage;
begin
  LImage := TWarImageDecoder.Decode(1, TBytes.Create(3, 0, 2, 0, 1, 2, 3, 4, 5, 6), TWarTestColors.Lookup);
  Assert.AreEqual(3, Integer(LImage.Width));
  Assert.AreEqual(2, Integer(LImage.Height));
  Assert.AreEqual<Integer>(24, Length(LImage.Pixels));
  Assert.AreEqual(1, TWarTestColors.Red(LImage.Pixels, 0));
  Assert.AreEqual(6, TWarTestColors.Red(LImage.Pixels, 5));
  Assert.AreEqual(255, Integer(LImage.Pixels[3]));
end;

procedure TTestWarImageDecoder.DovrebbeFareTrasparenteIlColoreZero;
var
  LImage: TWarImage;
begin
  LImage := TWarImageDecoder.Decode(1, TBytes.Create(1, 0, 1, 0, 0), TWarTestColors.Lookup);
  Assert.AreEqual(0, Integer(LImage.Pixels[0]));
  Assert.AreEqual(0, Integer(LImage.Pixels[3]));
end;

procedure TTestWarImageDecoder.DovrebbeAccettareUnaImmagineVuota;
var
  LImage: TWarImage;
begin
  LImage := TWarImageDecoder.Decode(1, TBytes.Create(0, 0, 5, 0), TWarTestColors.Lookup);
  Assert.AreEqual<Integer>(0, Length(LImage.Pixels));
end;

procedure TTestWarImageDecoder.DovrebbeIgnorareICodiciOltreLeDimensioni;
var
  LImage: TWarImage;
begin
  LImage := TWarImageDecoder.Decode(1, TBytes.Create(1, 0, 1, 0, 7, 8, 9), TWarTestColors.Lookup);
  Assert.AreEqual<Integer>(4, Length(LImage.Pixels));
  Assert.AreEqual(7, TWarTestColors.Red(LImage.Pixels, 0));
end;

procedure TTestWarImageDecoder.DovrebbeRifiutareUnRecordSenzaTuttiIPixel;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarImageDecoder.Decode(1, TBytes.Create(2, 0, 2, 0, 1, 2, 3), TWarTestColors.Lookup);
    end, EWarException);
end;

procedure TTestWarImageDecoder.DovrebbeRifiutareUnRecordSenzaTestata;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarImageDecoder.Decode(1, TBytes.Create(2, 0), TWarTestColors.Lookup);
    end, EWarException);
end;

{ TTestWarCursorDecoder }

procedure TTestWarCursorDecoder.DovrebbeLeggerePuntoCaldoDimensioniEPixel;
var
  LCursor: TWarCursor;
begin
  LCursor := TWarCursorDecoder.Decode(1, TBytes.Create(4, 0, 5, 0, 2, 0, 1, 0, 9, 8), TWarTestColors.Lookup);
  Assert.AreEqual(4, Integer(LCursor.HotX));
  Assert.AreEqual(5, Integer(LCursor.HotY));
  Assert.AreEqual(2, Integer(LCursor.Width));
  Assert.AreEqual(1, Integer(LCursor.Height));
  Assert.AreEqual<Integer>(8, Length(LCursor.Pixels));
  Assert.AreEqual(9, TWarTestColors.Red(LCursor.Pixels, 0));
  Assert.AreEqual(8, TWarTestColors.Red(LCursor.Pixels, 1));
end;

procedure TTestWarCursorDecoder.DovrebbeRifiutareUnRecordSenzaTuttiIPixel;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarCursorDecoder.Decode(1, TBytes.Create(0, 0, 0, 0, 2, 0, 2, 0, 1), TWarTestColors.Lookup);
    end, EWarException);
end;

procedure TTestWarCursorDecoder.DovrebbeRifiutareUnRecordSenzaTestata;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarCursorDecoder.Decode(1, TBytes.Create(0, 0, 0, 0), TWarTestColors.Lookup);
    end, EWarException);
end;

{ TTestWarSpriteDecoder }

function TTestWarSpriteDecoder.Header(AFrames, AWidth, AHeight: Integer): TBytes;
begin
  Result := TBytes.Create(Byte(AFrames), Byte(AFrames shr 8), Byte(AWidth), Byte(AHeight));
end;

procedure TTestWarSpriteDecoder.AddBytes(var ARaw: TBytes; const AValues: array of Byte);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AValues) do
  begin
    SetLength(ARaw, Length(ARaw) + 1);
    ARaw[High(ARaw)] := AValues[LIndex];
  end;
end;

procedure TTestWarSpriteDecoder.AddFrame(var ARaw: TBytes; ADx, ADy, AWidth, AHeight: Integer; AOffset: Cardinal);
begin
  AddBytes(ARaw, [Byte(ADx), Byte(ADy), Byte(AWidth), Byte(AHeight), Byte(AOffset), Byte(AOffset shr 8),
    Byte(AOffset shr 16), Byte(AOffset shr 24)]);
end;

procedure TTestWarSpriteDecoder.DovrebbeLeggereLeDimensioniEIFotogrammi;
var
  LRaw: TBytes;
  LSprite: TWarSprite;
begin
  // fotogrammi senza pixel da disegnare: si leggono solo le testate
  LRaw := Header(2, 4, 3);
  AddFrame(LRaw, 1, 2, 0, 0, 20);
  AddFrame(LRaw, 5, 6, 0, 0, 300);
  LSprite := TWarSpriteDecoder.Decode(7, LRaw, TWarTestColors.Lookup);
  Assert.AreEqual(4, Integer(LSprite.FrameWidth));
  Assert.AreEqual(3, Integer(LSprite.FrameHeight));
  Assert.AreEqual<Integer>(2, Length(LSprite.Frames));
  Assert.AreEqual(5, Integer(LSprite.Frames[1].Dx));
  Assert.AreEqual(6, Integer(LSprite.Frames[1].Dy));
  Assert.AreEqual(Cardinal(300), LSprite.Frames[1].Offset);
  Assert.AreEqual<Integer>(48, Length(LSprite.Frames[0].Pixels));
end;

procedure TTestWarSpriteDecoder.DovrebbeDisegnareIlFotogrammaNellaSuaPosizione;
var
  LRaw: TBytes;
  LSprite: TWarSprite;
begin
  LRaw := Header(1, 4, 4);
  AddFrame(LRaw, 1, 1, 2, 2, 12);
  AddBytes(LRaw, [10, 11, 12, 13]);
  LSprite := TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
  Assert.AreEqual(10, TWarTestColors.Red(LSprite.Frames[0].Pixels, 1 + 1 * 4));
  Assert.AreEqual(11, TWarTestColors.Red(LSprite.Frames[0].Pixels, 2 + 1 * 4));
  Assert.AreEqual(12, TWarTestColors.Red(LSprite.Frames[0].Pixels, 1 + 2 * 4));
  Assert.AreEqual(13, TWarTestColors.Red(LSprite.Frames[0].Pixels, 2 + 2 * 4));
end;

procedure TTestWarSpriteDecoder.DovrebbeLasciareTrasparenteCioCheNonDisegna;
var
  LRaw: TBytes;
  LSprite: TWarSprite;
begin
  LRaw := Header(1, 4, 4);
  AddFrame(LRaw, 1, 1, 1, 1, 12);
  AddBytes(LRaw, [10]);
  LSprite := TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
  Assert.AreEqual(0, TWarTestColors.Red(LSprite.Frames[0].Pixels, 0));
  Assert.AreEqual(0, Integer(LSprite.Frames[0].Pixels[3]));
  Assert.AreEqual(255, Integer(LSprite.Frames[0].Pixels[(1 + 4) * 4 + 3]));
end;

procedure TTestWarSpriteDecoder.DovrebbeTenereIFotogrammiSeparati;
var
  LRaw: TBytes;
  LSprite: TWarSprite;
begin
  LRaw := Header(2, 2, 2);
  AddFrame(LRaw, 0, 0, 1, 1, 20);
  AddFrame(LRaw, 1, 1, 1, 1, 21);
  AddBytes(LRaw, [30, 31]);
  LSprite := TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
  Assert.AreEqual(30, TWarTestColors.Red(LSprite.Frames[0].Pixels, 0));
  Assert.AreEqual(0, TWarTestColors.Red(LSprite.Frames[0].Pixels, 3));
  Assert.AreEqual(31, TWarTestColors.Red(LSprite.Frames[1].Pixels, 3));
  Assert.AreEqual(0, TWarTestColors.Red(LSprite.Frames[1].Pixels, 0));
end;

procedure TTestWarSpriteDecoder.DovrebbeScrivereNellaRigaSuccessivaSeIlFotogrammaEsceDallaRiga;
var
  LRaw: TBytes;
  LSprite: TWarSprite;
begin
  // area 2 x 2, il fotogramma parte da x = 1 e ha larghezza 2: il secondo pixel va a x = 2, cioe' (0, 1)
  LRaw := Header(1, 2, 2);
  AddFrame(LRaw, 1, 0, 2, 1, 12);
  AddBytes(LRaw, [40, 41]);
  LSprite := TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
  Assert.AreEqual(40, TWarTestColors.Red(LSprite.Frames[0].Pixels, 1));
  Assert.AreEqual(41, TWarTestColors.Red(LSprite.Frames[0].Pixels, 2));
end;

procedure TTestWarSpriteDecoder.DovrebbeScrivereNelFotogrammaSuccessivoSeEsceDallArea;
var
  LRaw: TBytes;
  LSprite: TWarSprite;
begin
  // area 1 x 1: il fotogramma 0 disegna 2 pixel, il secondo cade nel fotogramma 1 (come nel remake)
  LRaw := Header(2, 1, 1);
  AddFrame(LRaw, 0, 0, 2, 1, 20);
  AddFrame(LRaw, 0, 0, 0, 0, 20);
  AddBytes(LRaw, [50, 51]);
  LSprite := TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
  Assert.AreEqual(50, TWarTestColors.Red(LSprite.Frames[0].Pixels, 0));
  Assert.AreEqual(51, TWarTestColors.Red(LSprite.Frames[1].Pixels, 0));
end;

procedure TTestWarSpriteDecoder.DovrebbeRifiutareChiScriveOltreIlBloccoDeiPixel;
var
  LRaw: TBytes;
begin
  LRaw := Header(1, 2, 2);
  AddFrame(LRaw, 0, 0, 5, 1, 12);
  AddBytes(LRaw, [1, 2, 3, 4, 5]);
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
    end, EWarException);
end;

procedure TTestWarSpriteDecoder.DovrebbeRifiutareUnRecordSenzaTuttiIPixel;
var
  LRaw: TBytes;
begin
  LRaw := Header(1, 4, 4);
  AddFrame(LRaw, 0, 0, 2, 2, 12);
  AddBytes(LRaw, [1, 2, 3]);
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
    end, EWarException);
end;

procedure TTestWarSpriteDecoder.DovrebbeRifiutareUnRecordSenzaTutteLeTestate;
var
  LRaw: TBytes;
begin
  LRaw := Header(2, 4, 4);
  AddFrame(LRaw, 0, 0, 0, 0, 12);
  AddBytes(LRaw, [1, 2, 3]);
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteDecoder.Decode(1, LRaw, TWarTestColors.Lookup);
    end, EWarException);
end;

procedure TTestWarSpriteDecoder.DovrebbeRifiutareUnRecordSenzaLaTestata;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteDecoder.Decode(1, TBytes.Create(1, 0), TWarTestColors.Lookup);
    end, EWarException);
end;

procedure TTestWarSpriteDecoder.DovrebbeAccettareUnoSpriteSenzaFotogrammi;
var
  LSprite: TWarSprite;
begin
  LSprite := TWarSpriteDecoder.Decode(1, Header(0, 8, 8), TWarTestColors.Lookup);
  Assert.AreEqual<Integer>(0, Length(LSprite.Frames));
  Assert.AreEqual(8, Integer(LSprite.FrameWidth));
end;

{ TTestWarTilesetDecoder }

function TTestWarTilesetDecoder.Tiles(AMiniTiles: Integer): TBytes;
var
  LIndex: Integer;
begin
  // the pixel P of the mini tile M has the color 1 + (M * 64 + P) mod 255, so every pixel tells where it comes from
  SetLength(Result, AMiniTiles * 64);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(1 + LIndex mod 255);
end;

function TTestWarTilesetDecoder.Entry(AMini0, AMini1, AMini2, AMini3: Word): TBytes;
var
  LValues: array[0..3] of Word;
  LIndex: Integer;
begin
  LValues[0] := AMini0;
  LValues[1] := AMini1;
  LValues[2] := AMini2;
  LValues[3] := AMini3;
  SetLength(Result, 8);
  for LIndex := 0 to 3 do
  begin
    Result[LIndex * 2] := Byte(LValues[LIndex]);
    Result[LIndex * 2 + 1] := Byte(LValues[LIndex] shr 8);
  end;
end;

function TTestWarTilesetDecoder.Decode(const ARaw, ATiles: TBytes): TWarTileset;
begin
  Result := TWarTilesetDecoder.Decode(ARaw, ATiles, TWarTestColors.Lookup);
end;

function TTestWarTilesetDecoder.Pixel(const ATileset: TWarTileset; AX, AY: Integer): Integer;
begin
  Result := TWarTestColors.Red(ATileset.Pixels, AX + AY * 512);
end;

procedure TTestWarTilesetDecoder.DovrebbeContareLeTegoleDaOttoByteLUna;
begin
  Assert.AreEqual(Cardinal(3), Decode(Entry(0, 0, 0, 0) + Entry(0, 0, 0, 0) + Entry(0, 0, 0, 0) + TBytes.Create(1, 2, 3), Tiles(1)).TilesCount);
end;

procedure TTestWarTilesetDecoder.DovrebbeDisporreIQuattroMiniTegolaNelQuadrato;
var
  LTileset: TWarTileset;
begin
  // il valore e' lo scarto in byte diviso 2: la mini tegola M sta a 64 * M byte, cioe' al valore 32 * M
  LTileset := Decode(Entry(0, 32, 64, 96), Tiles(4));
  Assert.AreEqual(1, Pixel(LTileset, 0, 0));
  Assert.AreEqual(1 + 64, Pixel(LTileset, 8, 0));
  Assert.AreEqual(1 + 128, Pixel(LTileset, 0, 8));
  Assert.AreEqual(1 + 192, Pixel(LTileset, 8, 8));
  Assert.AreEqual(1 + 7, Pixel(LTileset, 7, 0));
  Assert.AreEqual(1 + 8, Pixel(LTileset, 0, 1));
  Assert.AreEqual(1 + 63, Pixel(LTileset, 7, 7));
end;

procedure TTestWarTilesetDecoder.DovrebbeLeggereLaMiniTegolaDalloScartoDelRecordDelleTegole;
var
  LTileset: TWarTileset;
begin
  LTileset := Decode(Entry(4, 4, 4, 4), Tiles(2));
  // valore 4 -> scarto 8 byte (il valore senza i due bit bassi, per due)
  Assert.AreEqual(1 + 8, Pixel(LTileset, 0, 0));
end;

procedure TTestWarTilesetDecoder.DovrebbeSpecchiareInOrizzontaleConIlBitDue;
var
  LTileset: TWarTileset;
begin
  LTileset := Decode(Entry(2, 0, 0, 0), Tiles(1));
  Assert.AreEqual(1 + 7, Pixel(LTileset, 0, 0));
  Assert.AreEqual(1, Pixel(LTileset, 7, 0));
  Assert.AreEqual(1 + 8, Pixel(LTileset, 7, 1));
end;

procedure TTestWarTilesetDecoder.DovrebbeSpecchiareInVerticaleConIlBitUno;
var
  LTileset: TWarTileset;
begin
  LTileset := Decode(Entry(1, 0, 0, 0), Tiles(1));
  Assert.AreEqual(1 + 56, Pixel(LTileset, 0, 0));
  Assert.AreEqual(1, Pixel(LTileset, 0, 7));
  Assert.AreEqual(1 + 57, Pixel(LTileset, 1, 0));
end;

procedure TTestWarTilesetDecoder.DovrebbeSpecchiareInEntrambeLeDirezioni;
var
  LTileset: TWarTileset;
begin
  LTileset := Decode(Entry(3, 0, 0, 0), Tiles(1));
  Assert.AreEqual(1 + 63, Pixel(LTileset, 0, 0));
  Assert.AreEqual(1, Pixel(LTileset, 7, 7));
end;

procedure TTestWarTilesetDecoder.DovrebbeAndareAcapoDopo32Tegole;
var
  LRaw: TBytes;
  LTileset: TWarTileset;
  LIndex: Integer;
begin
  for LIndex := 0 to 32 do
    LRaw := LRaw + Entry(0, 0, 0, 0);
  LTileset := Decode(LRaw, Tiles(1));
  Assert.AreEqual(Cardinal(33), LTileset.TilesCount);
  // la tegola 31 e' l'ultima della prima riga (x da 496), la 32 e' la prima della seconda (y da 16)
  Assert.AreEqual(1, Pixel(LTileset, 496, 0));
  Assert.AreEqual(1, Pixel(LTileset, 0, 16));
  Assert.AreEqual(0, Pixel(LTileset, 16, 16));
end;

procedure TTestWarTilesetDecoder.DovrebbeFareTrasparenteIlColoreZero;
var
  LTileset: TWarTileset;
begin
  LTileset := Decode(Entry(0, 0, 0, 0), Tiles(1));
  Assert.AreEqual(0, Pixel(LTileset, 100, 100));
  Assert.AreEqual(0, Integer(LTileset.Pixels[(100 + 100 * 512) * 4 + 3]));
  Assert.AreEqual(255, Integer(LTileset.Pixels[3]));
end;

procedure TTestWarTilesetDecoder.DovrebbeDareUnaImmagineDi512Per256;
begin
  Assert.AreEqual<Integer>(512 * 256 * 4, Length(Decode(nil, nil).Pixels));
end;

procedure TTestWarTilesetDecoder.DovrebbeRifiutareUnaMiniTegolaFuoriDalRecordDelleTegole;
begin
  Assert.WillRaise(
    procedure
    begin
      Decode(Entry(0, 32, 0, 0), Tiles(1));
    end, EWarException);
end;

procedure TTestWarTilesetDecoder.DovrebbeTroncareA16BitLoScartoDellaMiniTegola;
begin
  // $FFFC * 2 = $1FFF8: il remake lo tiene a 16 bit ($FFF8), fuori da qualunque record dei test
  Assert.WillRaise(
    procedure
    begin
      Decode(Entry($FFFC, 0, 0, 0), Tiles(100));
    end, EWarException);
  // $8000 * 2 = $10000 -> 0: si legge dall'inizio
  Assert.AreEqual(1, Pixel(Decode(Entry($8000, 0, 0, 0), Tiles(1)), 0, 0));
end;

procedure TTestWarTilesetDecoder.DovrebbeRifiutareTroppeTegole;
var
  LRaw: TBytes;
begin
  SetLength(LRaw, 513 * 8);
  Assert.WillRaise(
    procedure
    begin
      Decode(LRaw, Tiles(1));
    end, EWarException);
end;

procedure TTestWarTilesetDecoder.DovrebbeIgnorareIByteOltreLUltimaTegola;
begin
  // 7 byte non sono una tegola (la lunghezza e' divisa per 8 per difetto): 0 tegole, ma tutta l'immagine
  Assert.AreEqual(Cardinal(0), Decode(TBytes.Create(1, 2, 3, 4, 5, 6, 7), Tiles(1)).TilesCount);
end;

end.
