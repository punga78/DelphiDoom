{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTexturePngSpriteDecoder                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.PngSpriteDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.PngSprite, DelphiDoom.Tests.Texture.Samples,
  DelphiDoom.Tests.Texture.Fakes, DelphiDoom.Tests.Texture.Golden;

type
  [TestFixture]
  [Category('texture')]
  TTestTexturePngSpriteDecoder = class(TObject)
  private
    FLog: TFakeLog;
    FLogInterface: IInterface;
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
    function Decode(AIndex: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodice;
    [Test]
    procedure DovrebbeTeneregliIndiciSenzaAlfaNellaPalette;
    [Test]
    procedure DovrebbeDiventareA32BitSeLaPaletteHaUnAlfa;
    [Test]
    procedure DovrebbeMettereZeroIPixelConAlfaZeroDiUnImmagineRgba;
    [Test]
    procedure DovrebbeSostituireIlNeroConUnQuasiNero;
    [Test]
    procedure DovrebbeTenereGliOffsetDelFile;
    [Test]
    procedure DovrebbeNonUsareLeImpostazioniDeiColoriDelleTexture;
    [Test]
    procedure DovrebbeDareUnAvvisoEFalseSeIlFileNonSiLegge;
  end;

implementation

procedure TTestTexturePngSpriteDecoder.Setup;
begin
  FLog := TFakeLog.Create;
  FLogInterface := FLog;
  FDecoder := TTexturePngSpriteDecoder.Create('.PNGSPRITE', TFakePngReader.Create, FLog);
  FImage := TTextureImage.Create;
end;

procedure TTestTexturePngSpriteDecoder.TearDown;
begin
  FImage.Free;
  FDecoder := nil;
  FLogInterface := nil;
end;

function TTestTexturePngSpriteDecoder.Decode(AIndex: Integer): Boolean;
begin
  Result := FDecoder.Decode(TTextureSamples.PngToken(AIndex), FImage);
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.PNGSPRITE', FDecoder.Extension, 'dovrebbe dire .PNGSPRITE');
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeDareGliStessiRisultatiDelVecchioCodice;
var
  LCases: TTextureSamplePngs;
  LCase: TTextureSamplePng;
  LImage: TTextureImage;
  LOk: Boolean;
  LSuffix: string;
begin
  // the sprites do not read the settings of the colors: the two runs of the harness have the same results
  LCases := TTextureSamples.PngCases;
  for LSuffix in TArray<string>.Create('|default', '|plain') do
    for LCase in LCases do
    begin
      LImage := TTextureImage.Create;
      try
        LOk := FDecoder.Decode(LCase.Token, LImage);
        TTextureGolden.Check('png.golden.txt', 'png-sprite-' + LCase.Name + LSuffix,
          TTextureSamples.Describe(LOk, LImage, False, 256));
      finally
        LImage.Free;
      end;
    end;
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeTeneregliIndiciSenzaAlfaNellaPalette;
begin
  // the case 1: a palette without alpha and a color in the file that is not black
  Assert.IsTrue(Decode(1), 'dovrebbe riuscire');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe tenere gli indici');
  Assert.AreEqual(Cardinal($010100), FImage.Palette[0], 'dovrebbe dare un quasi nero al posto del nero della palette');
  // the case 0 has no color: the black is the color that the file says to be transparent (the old rule)
  FImage.Free;
  FImage := TTextureImage.Create;
  Assert.IsTrue(Decode(0), 'dovrebbe riuscire anche senza il colore');
  Assert.AreEqual(Cardinal(0), FImage.Palette[0], 'dovrebbe lasciare il nero trasparente se il file non ha un colore');
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeDiventareA32BitSeLaPaletteHaUnAlfa;
begin
  // the case 3: a palette with some entries of alpha 0
  Assert.IsTrue(Decode(3), 'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe passare a 32 bit');
  Assert.AreEqual<Integer>(6 * 4 * 4, Length(FImage.Pixels), 'dovrebbe avere 4 byte per pixel');
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeMettereZeroIPixelConAlfaZeroDiUnImmagineRgba;
var
  LIndex: Integer;
  LZeros: Integer;
begin
  // the case 5: RGBA with alpha 0 for a third of the pixels
  Assert.IsTrue(Decode(5), 'dovrebbe riuscire');
  LZeros := 0;
  for LIndex := 0 to 7 * 5 - 1 do
    if PTextureColorArray(FImage.PixelsPointer)^[LIndex] = 0 then
      Inc(LZeros);
  Assert.IsTrue(LZeros >= 11, 'dovrebbe avere i pixel con alfa 0 a zero');
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeSostituireIlNeroConUnQuasiNero;
var
  LIndex: Integer;
begin
  // the case 10: RGB with black pixels and a color of the file ($010100) that is not black: no pixel can be 0
  Assert.IsTrue(Decode(10), 'dovrebbe riuscire');
  for LIndex := 0 to 8 * 6 - 1 do
    if PTextureColorArray(FImage.PixelsPointer)^[LIndex] = 0 then
      Assert.Fail('dovrebbe sostituire il nero del pixel ' + IntToStr(LIndex));
  Assert.Pass;
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeTenereGliOffsetDelFile;
begin
  Assert.IsTrue(Decode(5), 'dovrebbe riuscire');
  Assert.AreEqual(2, FImage.LeftOffset, 'dovrebbe tenere l''offset a sinistra');
  Assert.AreEqual(3, FImage.TopOffset, 'dovrebbe tenere l''offset in alto');
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeNonUsareLeImpostazioniDeiColoriDelleTexture;
begin
  Assert.IsTrue(Decode(8), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal(0), FImage.TransparentColor, 'dovrebbe non avere colori trasparenti');
  Assert.AreEqual(Cardinal(0), FImage.TransparentColor2, 'dovrebbe non avere un secondo colore');
  Assert.AreEqual(Cardinal(0), FImage.TransparentColor3, 'dovrebbe non avere un terzo colore');
end;

procedure TTestTexturePngSpriteDecoder.DovrebbeDareUnAvvisoEFalseSeIlFileNonSiLegge;
begin
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(250, 0, 0, 0), FImage), 'dovrebbe dare false');
  Assert.AreEqual(1, FLog.Warnings.Count, 'dovrebbe dare un avviso');
end;

end.
