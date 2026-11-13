{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the decoders of the images          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.ImageDecoders;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedPictureDecoder = class(TObject)
  private
    FDecoder: IGreedImageDecoder;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLeDimensioniEdIlPuntoDiOrigine;
    [Test]
    procedure DovrebbeLeggereIPixelRigaPerRiga;
    [Test]
    procedure DovrebbeLeggereUnOriginePersino;
    [Test]
    procedure DovrebbeIgnorareICoseDopoIPixel;
    [Test]
    procedure DovrebbeRifiutareUnLumpSenzaIntestazione;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNulla;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNegativa;
    [Test]
    procedure DovrebbeRifiutareUnLumpPiuCortoDeiPixel;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedFlatDecoder = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnaImmagine64Per64;
    [Test]
    procedure DovrebbeTenereIPixelRigaPerRiga;
    [Test]
    procedure DovrebbeRifiutareUnLumpCorto;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedWallDecoder = class(TObject)
  private
    FDecoder: IGreedImageDecoder;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLAltezzaDalPrimoByte;
    [Test]
    procedure DovrebbeTrasporreLeColonneInRighe;
    [Test]
    procedure DovrebbeLeggereUnMuroAlto64;
    [Test]
    procedure DovrebbeRifiutareUnLumpVuoto;
    [Test]
    procedure DovrebbeRifiutareUnMuroAlto0;
    [Test]
    procedure DovrebbeRifiutareUnLumpPiuCortoDelleColonne;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedSpriteDecoder = class(TObject)
  private
    FDecoder: IGreedImageDecoder;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLarghezzaEAltezza;
    [Test]
    procedure DovrebbeTenereLOffsetSinistroELaBase;
    [Test]
    procedure DovrebbeDisegnareIPostDallAltoInBasso;
    [Test]
    procedure DovrebbeLasciareATrasparenteUnaColonnaVuota;
    [Test]
    procedure DovrebbeLasciareATrasparenteLoZero;
    [Test]
    procedure DovrebbeDareUnaImmagineSenzaRigheSeNonCeNulla;
    [Test]
    procedure DovrebbeRifiutareUnLumpCorto;
    [Test]
    procedure DovrebbeRifiutareUnaLarghezzaNulla;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaDiColonneTroncata;
    [Test]
    procedure DovrebbeRifiutareUnaColonnaFuoriDalLump;
    [Test]
    procedure DovrebbeRifiutareUnaColonnaConOffsetNegativo;
    [Test]
    procedure DovrebbeRifiutareUnPostConLaCimaSottoLaBase;
    [Test]
    procedure DovrebbeRifiutareUnPostChePassaLaFineDelLump;
  end;

implementation

uses
  DelphiDoom.Greed.PictureDecoder, DelphiDoom.Greed.FlatDecoder, DelphiDoom.Greed.WallDecoder,
  DelphiDoom.Greed.SpriteDecoder, DelphiDoom.Tests.Greed.Builders;

{ TTestGreedPictureDecoder }

procedure TTestGreedPictureDecoder.Setup;
begin
  FDecoder := TGreedPictureDecoder.Create;
end;

procedure TTestGreedPictureDecoder.DovrebbeLeggereLeDimensioniEdIlPuntoDiOrigine;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Picture(3, 2, 5, -4));
  Assert.AreEqual(3, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  Assert.AreEqual(5, LImage.OriginX);
  Assert.AreEqual(-4, LImage.OriginY);
end;

procedure TTestGreedPictureDecoder.DovrebbeLeggereIPixelRigaPerRiga;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Picture(3, 2, 0, 0, 10));
  Assert.AreEqual<Integer>(6, Length(LImage.Pixels));
  Assert.AreEqual(10, Integer(LImage.Pixels[0]));
  Assert.AreEqual(12, Integer(LImage.Pixels[2]));
  Assert.AreEqual(13, Integer(LImage.Pixels[3]));
  Assert.AreEqual(15, Integer(LImage.Pixels[5]));
end;

procedure TTestGreedPictureDecoder.DovrebbeLeggereUnOriginePersino;
begin
  Assert.AreEqual(-32768, FDecoder.Decode(TGreedLumps.Picture(1, 1, -32768, 0)).OriginX);
end;

procedure TTestGreedPictureDecoder.DovrebbeIgnorareICoseDopoIPixel;
var
  LLump: TBytes;
begin
  LLump := TGreedLumps.Picture(2, 2, 0, 0);
  SetLength(LLump, Length(LLump) + 5);
  Assert.AreEqual<Integer>(4, Length(FDecoder.Decode(LLump).Pixels));
end;

procedure TTestGreedPictureDecoder.DovrebbeRifiutareUnLumpSenzaIntestazione;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TBytes.Create(1, 0, 1, 0)); end, EGreedDataException);
end;

procedure TTestGreedPictureDecoder.DovrebbeRifiutareUnaDimensioneNulla;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Picture(0, 3, 0, 0)); end, EGreedDataException);
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Picture(3, 0, 0, 0)); end, EGreedDataException);
end;

procedure TTestGreedPictureDecoder.DovrebbeRifiutareUnaDimensioneNegativa;
var
  LLump: TBytes;
begin
  LLump := TGreedLumps.Picture(2, 2, 0, 0);
  LLump[1] := $FF;
  Assert.WillRaise(procedure begin FDecoder.Decode(LLump); end, EGreedDataException);
end;

procedure TTestGreedPictureDecoder.DovrebbeRifiutareUnLumpPiuCortoDeiPixel;
var
  LLump: TBytes;
begin
  LLump := TGreedLumps.Picture(2, 2, 0, 0);
  SetLength(LLump, Length(LLump) - 1);
  Assert.WillRaise(procedure begin FDecoder.Decode(LLump); end, EGreedDataException);
end;

{ TTestGreedFlatDecoder }

procedure TTestGreedFlatDecoder.DovrebbeDareUnaImmagine64Per64;
var
  LImage: TGreedImage;
begin
  LImage := TGreedFlatDecoder.Create.Decode(TGreedLumps.Flat);
  Assert.AreEqual(64, LImage.Width);
  Assert.AreEqual(64, LImage.Height);
  Assert.AreEqual<Integer>(4096, Length(LImage.Pixels));
end;

procedure TTestGreedFlatDecoder.DovrebbeTenereIPixelRigaPerRiga;
var
  LImage: TGreedImage;
begin
  LImage := TGreedFlatDecoder.Create.Decode(TGreedLumps.Flat);
  // the pixel (x, y) is at y * 64 + x
  Assert.AreEqual(1, Integer(LImage.Pixels[0]));
  Assert.AreEqual((3 * 64 + 7) mod 251 + 1, Integer(LImage.Pixels[3 * 64 + 7]));
end;

procedure TTestGreedFlatDecoder.DovrebbeRifiutareUnLumpCorto;
var
  LLump: TBytes;
begin
  SetLength(LLump, 4095);
  Assert.WillRaise(procedure begin TGreedFlatDecoder.Create.Decode(LLump); end, EGreedDataException);
end;

{ TTestGreedWallDecoder }

procedure TTestGreedWallDecoder.Setup;
begin
  FDecoder := TGreedWallDecoder.Create;
end;

procedure TTestGreedWallDecoder.DovrebbeLeggereLAltezzaDalPrimoByte;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Wall(2));
  Assert.AreEqual(64, LImage.Width);
  Assert.AreEqual(8, LImage.Height);
  Assert.AreEqual<Integer>(64 * 8, Length(LImage.Pixels));
end;

procedure TTestGreedWallDecoder.DovrebbeTrasporreLeColonneInRighe;
var
  LImage: TGreedImage;
begin
  // the byte of the column x and the row y is x + y + 1; the image has the rows from the top
  LImage := FDecoder.Decode(TGreedLumps.Wall(2));
  Assert.AreEqual(1, Integer(LImage.Pixels[0]));
  Assert.AreEqual(1 + 5, Integer(LImage.Pixels[5]));
  Assert.AreEqual(1 + 3, Integer(LImage.Pixels[3 * 64]));
  Assert.AreEqual(1 + 63 + 7, Integer(LImage.Pixels[7 * 64 + 63]));
end;

procedure TTestGreedWallDecoder.DovrebbeLeggereUnMuroAlto64;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Wall(16));
  Assert.AreEqual(64, LImage.Height);
  Assert.AreEqual(Integer(Byte(1 + 10 + 20)), Integer(LImage.Pixels[20 * 64 + 10]));
end;

procedure TTestGreedWallDecoder.DovrebbeRifiutareUnLumpVuoto;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(nil); end, EGreedDataException);
end;

procedure TTestGreedWallDecoder.DovrebbeRifiutareUnMuroAlto0;
var
  LLump: TBytes;
begin
  SetLength(LLump, 200);
  Assert.WillRaise(procedure begin FDecoder.Decode(LLump); end, EGreedDataException);
end;

procedure TTestGreedWallDecoder.DovrebbeRifiutareUnLumpPiuCortoDelleColonne;
var
  LLump: TBytes;
begin
  LLump := TGreedLumps.Wall(2);
  SetLength(LLump, Length(LLump) - 1);
  Assert.WillRaise(procedure begin FDecoder.Decode(LLump); end, EGreedDataException);
end;

{ TTestGreedSpriteDecoder }

procedure TTestGreedSpriteDecoder.Setup;
begin
  FDecoder := TGreedSpriteDecoder.Create;
end;

procedure TTestGreedSpriteDecoder.DovrebbeDareLarghezzaEAltezza;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Sprite);
  Assert.AreEqual(3, LImage.Width);
  Assert.AreEqual(5, LImage.Height);
  Assert.AreEqual<Integer>(15, Length(LImage.Pixels));
end;

procedure TTestGreedSpriteDecoder.DovrebbeTenereLOffsetSinistroELaBase;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Sprite);
  Assert.AreEqual(7, LImage.OriginX);
  Assert.AreEqual(5, LImage.OriginY);
end;

procedure TTestGreedSpriteDecoder.DovrebbeDisegnareIPostDallAltoInBasso;
var
  LImage: TGreedImage;
begin
  // post of the column 0: top 5, bottom 2, pixels 1 2 3 -> the rows 0, 1, 2; post of the column 2: top 2, bottom 1,
  // pixel 9 at the height 1 -> the row 3
  LImage := FDecoder.Decode(TGreedLumps.Sprite);
  Assert.AreEqual(1, Integer(LImage.Pixels[0 * 3 + 0]));
  Assert.AreEqual(2, Integer(LImage.Pixels[1 * 3 + 0]));
  Assert.AreEqual(3, Integer(LImage.Pixels[2 * 3 + 0]));
  Assert.AreEqual(9, Integer(LImage.Pixels[3 * 3 + 2]));
end;

procedure TTestGreedSpriteDecoder.DovrebbeLasciareATrasparenteUnaColonnaVuota;
var
  LImage: TGreedImage;
  LRow: Integer;
begin
  LImage := FDecoder.Decode(TGreedLumps.Sprite);
  for LRow := 0 to 4 do
    Assert.AreEqual(0, Integer(LImage.Pixels[LRow * 3 + 1]));
end;

procedure TTestGreedSpriteDecoder.DovrebbeLasciareATrasparenteLoZero;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Sprite);
  Assert.AreEqual(0, Integer(LImage.Pixels[4 * 3 + 0]));
  Assert.AreEqual(0, Integer(LImage.Pixels[0 * 3 + 2]));
end;

procedure TTestGreedSpriteDecoder.DovrebbeDareUnaImmagineSenzaRigheSeNonCeNulla;
var
  LImage: TGreedImage;
begin
  LImage := FDecoder.Decode(TGreedLumps.Bytes([0, 0, 2, 0, 0, 0, 0, 0]));
  Assert.AreEqual(2, LImage.Width);
  Assert.AreEqual(0, LImage.Height);
  Assert.AreEqual<Integer>(0, Length(LImage.Pixels));
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnLumpCorto;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TBytes.Create(1, 2, 3)); end, EGreedDataException);
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnaLarghezzaNulla;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 0, 0])); end, EGreedDataException);
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, $FF, $FF])); end, EGreedDataException);
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnaTabellaDiColonneTroncata;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 3, 0, 0, 0])); end, EGreedDataException);
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnaColonnaFuoriDalLump;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 1, 0, 99, 0])); end, EGreedDataException);
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 1, 0, 6, 0, 1])); end, EGreedDataException);
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnaColonnaConOffsetNegativo;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 1, 0, $FE, $FF, 0, 0])); end, EGreedDataException);
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnPostConLaCimaSottoLaBase;
begin
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 1, 0, 6, 0, 2, 5, 1, 1, 1])); end, EGreedDataException);
end;

procedure TTestGreedSpriteDecoder.DovrebbeRifiutareUnPostChePassaLaFineDelLump;
begin
  // top 5, bottom 1: 4 pixels, the lump has 2
  Assert.WillRaise(procedure begin FDecoder.Decode(TGreedLumps.Bytes([0, 0, 1, 0, 6, 0, 5, 1, 7, 7])); end, EGreedDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedPictureDecoder);
  TDUnitX.RegisterTestFixture(TTestGreedFlatDecoder);
  TDUnitX.RegisterTestFixture(TTestGreedWallDecoder);
  TDUnitX.RegisterTestFixture(TTestGreedSpriteDecoder);

end.
