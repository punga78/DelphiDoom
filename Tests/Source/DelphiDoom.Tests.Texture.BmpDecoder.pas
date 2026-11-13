{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureBmpDecoder                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.BmpDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.Bmp, DelphiDoom.Tests.Texture.Samples;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureBmpDecoder = class(TObject)
  private
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
    function Palette4(AFirst, ASecond: Cardinal): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeLeggereUnaBitmapA8BitPartendoDalBasso;
    [Test]
    procedure DovrebbeLeggereUnaBitmapA24BitComeColoriRrggbb;
    [Test]
    procedure DovrebbeSaltareIlPaddingDelleRigheA24Bit;
    [Test]
    procedure DovrebbeLeggereUnaBitmapA1BitConLaPalette;
    [Test]
    procedure DovrebbeLeggereUnaBitmapA4BitConLaPalette;
    [Test]
    procedure DovrebbeLeggereIPixelDallOffsetDelleIntestazioni;
    [Test]
    procedure DovrebbeLeggereUnaBitmapRle8ConRipetizioniELetterali;
    [Test]
    procedure DovrebbeSaltarePixelConIlCodiceDiSpostamentoDellRle;
    [Test]
    procedure DovrebbeScartareIPixelDellRleFuoriDallImmagine;
    [Test]
    procedure DovrebbeRifiutareUnaBitmapA32Bit;
    [Test]
    procedure DovrebbeRifiutareUnaBitmapConAltezzaNegativa;
    [Test]
    procedure DovrebbeRifiutareUnaBitmapDiLatoZero;
    [Test]
    procedure DovrebbeRifiutareUnaBitmapTroppoGrande;
    [Test]
    procedure DovrebbeDareZeroPerLeRigheCheMancano;
    [Test]
    procedure DovrebbeRifiutareUnFileVuoto;
  end;

implementation

function TTestTextureBmpDecoder.Palette4(AFirst, ASecond: Cardinal): TBytes;
begin
  // entries of B, G, R, 0
  Result := TBytes.Create(Byte(AFirst), Byte(AFirst shr 8), Byte(AFirst shr 16), 0,
    Byte(ASecond), Byte(ASecond shr 8), Byte(ASecond shr 16), 0);
end;

procedure TTestTextureBmpDecoder.Setup;
begin
  FDecoder := TTextureBmpDecoder.Create;
  FImage := TTextureImage.Create;
end;

procedure TTestTextureBmpDecoder.TearDown;
begin
  FImage.Free;
end;

procedure TTestTextureBmpDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.BMP', FDecoder.Extension, 'dovrebbe dire .BMP');
end;

procedure TTestTextureBmpDecoder.DovrebbeLeggereUnaBitmapA8BitPartendoDalBasso;
var
  LPalette: TBytes;
begin
  // the first row of the file is the bottom one
  LPalette := TBytes.Create(1, 2, 3, 0, 4, 5, 6, 0);
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(2, 2, 8, 0, LPalette,
    TBytes.Create(0, 1, 0, 0, 1, 0, 0, 0)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe tenere gli indici');
  Assert.AreEqual(Byte(1), FImage.Pixels[0], 'dovrebbe mettere l''ultima riga del file in cima');
  Assert.AreEqual(Byte(0), FImage.Pixels[1], 'dovrebbe leggere il secondo pixel della riga in cima');
  Assert.AreEqual(Byte(0), FImage.Pixels[2], 'dovrebbe mettere la prima riga del file in fondo');
  Assert.AreEqual(Byte(1), FImage.Pixels[3], 'dovrebbe leggere il secondo pixel della riga in fondo');
  Assert.AreEqual(Cardinal($030201), FImage.Palette[0], 'dovrebbe leggere la palette come B, G, R');
  Assert.AreEqual(Cardinal($060504), FImage.Palette[1], 'dovrebbe leggere la seconda voce');
end;

procedure TTestTextureBmpDecoder.DovrebbeLeggereUnaBitmapA24BitComeColoriRrggbb;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(1, 2, 24, 0, nil,
    TBytes.Create($11, $22, $33, 0, $44, $55, $66, 0)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
  Assert.AreEqual(Cardinal($00665544), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare la riga in cima come $00RRGGBB');
  Assert.AreEqual(Cardinal($00332211), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe dare la riga in fondo');
  Assert.IsTrue(FImage.NeedsSwapRGB, 'dovrebbe lasciare lo scambio di rosso e blu a chi usa l''immagine');
end;

procedure TTestTextureBmpDecoder.DovrebbeSaltareIlPaddingDelleRigheA24Bit;
var
  LData: TBytes;
begin
  // 3 pixels of 3 bytes are 9 bytes, the row has 12
  LData := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 99, 99, 99, 10, 11, 12, 13, 14, 15, 16, 17, 18, 99, 99, 99);
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(3, 2, 24, 0, nil, LData), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($000C0B0A), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe leggere dall''inizio della riga');
  Assert.AreEqual(Cardinal($00090807), PTextureColorArray(FImage.PixelsPointer)^[5], 'dovrebbe leggere la riga dopo il padding');
end;

procedure TTestTextureBmpDecoder.DovrebbeLeggereUnaBitmapA1BitConLaPalette;
begin
  // regression: the old reader crashed on the files of 1 bit (it never read their palette)
  // 10 pixels: 1010101010 in two bytes, then the padding of the row up to 4 bytes
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(10, 1, 1, 0, Palette4($0000FF, $FF0000),
    TBytes.Create($AA, $80, 0, 0)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe tenere gli indici');
  Assert.AreEqual(Byte(1), FImage.Pixels[0], 'dovrebbe leggere il bit alto per primo');
  Assert.AreEqual(Byte(0), FImage.Pixels[1], 'dovrebbe leggere il secondo bit');
  Assert.AreEqual(Byte(1), FImage.Pixels[8], 'dovrebbe leggere il secondo byte');
  Assert.AreEqual(Byte(0), FImage.Pixels[9], 'dovrebbe fermarsi ai pixel della riga');
  Assert.AreEqual(Cardinal($FF0000), FImage.Palette[1], 'dovrebbe leggere la palette');
end;

procedure TTestTextureBmpDecoder.DovrebbeLeggereUnaBitmapA4BitConLaPalette;
begin
  // regression: the old reader crashed on the files of 4 bit
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(3, 1, 4, 0, TBytes.Create(1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9, 0, 10, 11, 12, 0),
    TBytes.Create($12, $30, 0, 0)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Byte(1), FImage.Pixels[0], 'dovrebbe leggere il nibble alto');
  Assert.AreEqual(Byte(2), FImage.Pixels[1], 'dovrebbe leggere il nibble basso');
  Assert.AreEqual(Byte(3), FImage.Pixels[2], 'dovrebbe leggere l''ultimo pixel dal nibble alto');
end;

procedure TTestTextureBmpDecoder.DovrebbeLeggereIPixelDallOffsetDelleIntestazioni;
begin
  // the header of this file has 4 bytes more before the data: the old reader took them for pixels
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(1, 1, 24, 0, TBytes.Create(9, 9, 9, 9),
    TBytes.Create($11, $22, $33, 0)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($00332211), PCardinal(FImage.PixelsPointer)^, 'dovrebbe leggere dall''offset dei dati');
end;

procedure TTestTextureBmpDecoder.DovrebbeLeggereUnaBitmapRle8ConRipetizioniELetterali;
var
  LRle: TBytes;
begin
  // bottom row: a run of 3 of the index 7 and a literal of 3 (padded to 4 bytes);
  // top row: a run of 6 of the index 2
  LRle := TBytes.Create(3, 7, 0, 3, 1, 2, 3, 0, 0, 0, 6, 2, 0, 0, 0, 1);
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(6, 2, 8, 1, TTextureSamples.RandomBytes(1, 1024), LRle), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(Byte(2), FImage.Pixels[0], 'dovrebbe riempire la riga in cima');
  Assert.AreEqual(Byte(2), FImage.Pixels[5], 'dovrebbe riempire tutta la riga');
  Assert.AreEqual(Byte(7), FImage.Pixels[6], 'dovrebbe mettere la ripetizione in fondo');
  Assert.AreEqual(Byte(1), FImage.Pixels[9], 'dovrebbe dopo mettere il letterale');
  Assert.AreEqual(Byte(3), FImage.Pixels[11], 'dovrebbe leggere i tre byte del letterale');
end;

procedure TTestTextureBmpDecoder.DovrebbeSaltarePixelConIlCodiceDiSpostamentoDellRle;
var
  LRle: TBytes;
begin
  // a delta of 2 to the right and 1 up from the start, then a run of 2: the run is in the row above
  LRle := TBytes.Create(0, 2, 2, 1, 2, 9, 0, 1);
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(4, 2, 8, 1, TTextureSamples.RandomBytes(2, 1024), LRle), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(Byte(9), FImage.Pixels[2], 'dovrebbe scrivere dopo lo spostamento, nella riga sopra');
  Assert.AreEqual(Byte(9), FImage.Pixels[3], 'dovrebbe scrivere il secondo pixel della ripetizione');
  Assert.AreEqual(Byte(0), FImage.Pixels[4], 'dovrebbe lasciare 0 i pixel saltati');
end;

procedure TTestTextureBmpDecoder.DovrebbeScartareIPixelDellRleFuoriDallImmagine;
var
  LRle: TBytes;
begin
  // a run of 200 in a bitmap of 4x2 pixels: the old code wrote past the end of the buffer
  LRle := TBytes.Create(200, 5, 0, 1);
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(4, 2, 8, 1, TTextureSamples.RandomBytes(3, 1024), LRle), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual<Integer>(8, Length(FImage.Pixels), 'dovrebbe tenere la dimensione');
  Assert.AreEqual(Byte(5), FImage.Pixels[7], 'dovrebbe scrivere fino alla fine dell''immagine');
end;

procedure TTestTextureBmpDecoder.DovrebbeRifiutareUnaBitmapA32Bit;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Bmp(2, 2, 32, 0, nil, TTextureSamples.RandomBytes(4, 16)), FImage),
    'dovrebbe dare false, come il vecchio codice');
end;

procedure TTestTextureBmpDecoder.DovrebbeRifiutareUnaBitmapConAltezzaNegativa;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Bmp(2, -2, 24, 0, nil, TTextureSamples.RandomBytes(5, 16)), FImage),
    'dovrebbe dare false: il vecchio codice la passava a una Word');
end;

procedure TTestTextureBmpDecoder.DovrebbeRifiutareUnaBitmapDiLatoZero;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Bmp(0, 4, 24, 0, nil, nil), FImage), 'dovrebbe rifiutare la larghezza 0');
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Bmp(4, 0, 24, 0, nil, nil), FImage), 'dovrebbe rifiutare l''altezza 0');
end;

procedure TTestTextureBmpDecoder.DovrebbeRifiutareUnaBitmapTroppoGrande;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Bmp(TEXTURE_MAX_DIMENSION + 1, 1, 24, 0, nil, nil), FImage),
    'dovrebbe rifiutare un lato oltre il limite');
end;

procedure TTestTextureBmpDecoder.DovrebbeDareZeroPerLeRigheCheMancano;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Bmp(2, 3, 24, 0, nil, TBytes.Create(1, 2, 3, 4, 5, 6, 0, 0)), FImage),
    'dovrebbe riuscire anche con il file troncato');
  Assert.AreEqual(Cardinal(0), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare zero per le righe che mancano');
end;

procedure TTestTextureBmpDecoder.DovrebbeRifiutareUnFileVuoto;
begin
  Assert.IsFalse(FDecoder.Decode(nil, FImage), 'dovrebbe dare false per un file vuoto');
end;

end.
