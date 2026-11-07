{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureTgaDecoder                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.TgaDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.Tga, DelphiDoom.Tests.Texture.Samples;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureTgaDecoder = class(TObject)
  private
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeLeggereUnaTga24BitPartendoDalBasso;
    [Test]
    procedure DovrebbeLeggereUnaTga32BitConLAlfa;
    [Test]
    procedure DovrebbeLeggereUnaTga16BitComeParole;
    [Test]
    procedure DovrebbeLeggereUnaTgaConMappaDeiColoriA24Bit;
    [Test]
    procedure DovrebbeSaltareLaIdentificazione;
    [Test]
    procedure DovrebbeLeggereUnaTgaRle24BitConRipetizioneCheAttraversaLeRighe;
    [Test]
    procedure DovrebbeLeggereUnaTgaRleConPixelLetterali;
    [Test]
    procedure DovrebbeRifiutareUnaTgaInScalaDiGrigi;
    [Test]
    procedure DovrebbeRifiutareUnaMappaDeiColoriDiUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeRifiutareUnaProfonditaDiPixelNonValida;
    [Test]
    procedure DovrebbeRifiutareUnTipoCheNonVaConLaProfondita;
    [Test]
    procedure DovrebbeRifiutareUnaTgaDiLatoZero;
    [Test]
    procedure DovrebbeDareZeroPerIPixelCheMancano;
  end;

implementation

procedure TTestTextureTgaDecoder.Setup;
begin
  FDecoder := TTextureTgaDecoder.Create;
  FImage := TTextureImage.Create;
end;

procedure TTestTextureTgaDecoder.TearDown;
begin
  FImage.Free;
end;

procedure TTestTextureTgaDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.TGA', FDecoder.Extension, 'dovrebbe dire .TGA');
end;

procedure TTestTextureTgaDecoder.DovrebbeLeggereUnaTga24BitPartendoDalBasso;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 1, 2, 24, nil, nil,
    TBytes.Create($11, $22, $33, $44, $55, $66)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
  Assert.AreEqual(Cardinal($00665544), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe mettere l''ultima riga del file in cima');
  Assert.AreEqual(Cardinal($00332211), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe mettere la prima riga in fondo');
end;

procedure TTestTextureTgaDecoder.DovrebbeLeggereUnaTga32BitConLAlfa;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 1, 1, 32, nil, nil,
    TBytes.Create($11, $22, $33, $80)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($80332211), PCardinal(FImage.PixelsPointer)^, 'dovrebbe tenere l''alfa');
end;

procedure TTestTextureTgaDecoder.DovrebbeLeggereUnaTga16BitComeParole;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 2, 1, 16, nil, nil,
    TBytes.Create($34, $12, $FF, $7F)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(2, FImage.BytesPerPixel, 'dovrebbe tenere 2 byte per pixel');
  Assert.AreEqual(Word($1234), PWord(@FImage.Pixels[0])^, 'dovrebbe tenere la parola del file');
end;

procedure TTestTextureTgaDecoder.DovrebbeLeggereUnaTgaConMappaDeiColoriA24Bit;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 1, 1, 2, 24, 2, 1, 8, nil,
    TBytes.Create(1, 2, 3, 4, 5, 6), TBytes.Create(1, 0)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe tenere gli indici');
  Assert.AreEqual(Byte(1), FImage.Pixels[0], 'dovrebbe tenere l''indice');
  Assert.AreEqual(Cardinal($030201), FImage.Palette[0], 'dovrebbe leggere la mappa come B, G, R');
  Assert.AreEqual(Cardinal($060504), FImage.Palette[1], 'dovrebbe leggere la seconda voce');
  Assert.AreEqual(Cardinal(0), FImage.Palette[2], 'dovrebbe lasciare 0 le voci che la mappa non ha');
end;

procedure TTestTextureTgaDecoder.DovrebbeSaltareLaIdentificazione;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(3, 0, 2, 0, 0, 1, 1, 24, TBytes.Create(7, 8, 9), nil,
    TBytes.Create($11, $22, $33)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($00332211), PCardinal(FImage.PixelsPointer)^, 'dovrebbe leggere i pixel dopo l''identificazione');
end;

procedure TTestTextureTgaDecoder.DovrebbeLeggereUnaTgaRle24BitConRipetizioneCheAttraversaLeRighe;
begin
  // 2 x 2 = 4 pixels: a run of 3 (it goes over the end of the first row) and a raw pixel
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 0, 10, 0, 0, 2, 2, 24, nil, nil,
    TBytes.Create($82, 1, 2, 3, $00, 4, 5, 6)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($00030201), PTextureColorArray(FImage.PixelsPointer)^[3], 'dovrebbe riempire la riga in fondo');
  Assert.AreEqual(Cardinal($00030201), PTextureColorArray(FImage.PixelsPointer)^[2], 'dovrebbe riempire anche il secondo pixel');
  Assert.AreEqual(Cardinal($00030201), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe attraversare la riga e riempire quella sopra');
  Assert.AreEqual(Cardinal($00060504), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe leggere il pixel letterale');
end;

procedure TTestTextureTgaDecoder.DovrebbeLeggereUnaTgaRleConPixelLetterali;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 0, 10, 0, 0, 2, 1, 32, nil, nil,
    TBytes.Create($01, 1, 2, 3, 4, 5, 6, 7, 8)), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($04030201), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe leggere il primo pixel letterale');
  Assert.AreEqual(Cardinal($08070605), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe leggere il secondo');
end;

procedure TTestTextureTgaDecoder.DovrebbeRifiutareUnaTgaInScalaDiGrigi;
begin
  // regression: the old code answered true with a blank image
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Tga(0, 0, 3, 0, 0, 2, 2, 8, nil, nil, TBytes.Create(1, 2, 3, 4)), FImage),
    'dovrebbe dare false');
end;

procedure TTestTextureTgaDecoder.DovrebbeRifiutareUnaMappaDeiColoriDiUnaDimensioneNonValida;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Tga(0, 1, 1, 2, 8, 2, 1, 8, nil, TBytes.Create(1, 2), TBytes.Create(0, 1)), FImage),
    'dovrebbe dare false (il vecchio codice dava true e un''immagine vuota)');
end;

procedure TTestTextureTgaDecoder.DovrebbeRifiutareUnaProfonditaDiPixelNonValida;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 2, 2, 12, nil, nil, TBytes.Create(1, 2, 3, 4, 5, 6)), FImage),
    'dovrebbe dare false');
end;

procedure TTestTextureTgaDecoder.DovrebbeRifiutareUnTipoCheNonVaConLaProfondita;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Tga(0, 0, 1, 0, 0, 1, 1, 24, nil, nil, TBytes.Create(1, 2, 3)), FImage),
    'dovrebbe dare false per il tipo 1 con 24 bit (il vecchio codice dava true)');
end;

procedure TTestTextureTgaDecoder.DovrebbeRifiutareUnaTgaDiLatoZero;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 0, 3, 24, nil, nil, nil), FImage), 'dovrebbe rifiutare la larghezza 0');
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 3, 0, 24, nil, nil, nil), FImage), 'dovrebbe rifiutare l''altezza 0');
  Assert.IsFalse(FDecoder.Decode(nil, FImage), 'dovrebbe rifiutare un file vuoto');
end;

procedure TTestTextureTgaDecoder.DovrebbeDareZeroPerIPixelCheMancano;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.Tga(0, 0, 2, 0, 0, 2, 2, 24, nil, nil,
    TBytes.Create(1, 2, 3, 4, 5, 6)), FImage), 'dovrebbe riuscire anche con il file troncato');
  Assert.AreEqual(Cardinal(0), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare zero per le righe che mancano');
end;

end.
