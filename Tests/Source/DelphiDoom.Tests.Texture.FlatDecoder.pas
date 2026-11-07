{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureFlatDecoder                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.FlatDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.Flat, DelphiDoom.Tests.Texture.Samples,
  DelphiDoom.Tests.Texture.Fakes, DelphiDoom.Tests.Texture.Golden;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureFlatDecoder = class(TObject)
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
    procedure DovrebbeLeggereUnFlatDi64PerQuaranta;
    [Test]
    procedure DovrebbeVedereUnLumpDi64Per128ComeUnFlatDi64Per64;
    [Test]
    procedure DovrebbeLeggereUnFlatQuadrato;
    [Test]
    procedure DovrebbeDareIColoriDellaPaletteConLAlfaESenzaIlRossoNelBlu;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaCheNonEUnFlat;
    [Test]
    procedure DovrebbeRiconoscereLeLunghezzeDeiFlat;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerLeLunghezzeDelVecchioCodice;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteCorta;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteNil;
  end;

  TShortPalette = class(TInterfacedObject, ITexturePaletteSource)
  public
    function GetColors: TTexturePixels;
  end;

implementation

function TShortPalette.GetColors: TTexturePixels;
begin
  SetLength(Result, 10);
end;

procedure TTestTextureFlatDecoder.Setup;
begin
  FDecoder := TTextureFlatDecoder.Create(TFakePaletteSource.Create);
  FImage := TTextureImage.Create;
end;

procedure TTestTextureFlatDecoder.TearDown;
begin
  FImage.Free;
end;

procedure TTestTextureFlatDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.FLAT', FDecoder.Extension, 'dovrebbe dire .FLAT');
end;

procedure TTestTextureFlatDecoder.DovrebbeLeggereUnFlatDi64PerQuaranta;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.RandomBytes(1, 64 * 64), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(64, FImage.Width, 'dovrebbe avere 64 di larghezza');
  Assert.AreEqual(64, FImage.Height, 'dovrebbe avere 64 di altezza');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
end;

procedure TTestTextureFlatDecoder.DovrebbeVedereUnLumpDi64Per128ComeUnFlatDi64Per64;
var
  LBytes: TBytes;
begin
  LBytes := TTextureSamples.RandomBytes(2, 64 * 128);
  Assert.IsTrue(FDecoder.Decode(LBytes, FImage), 'dovrebbe riuscire');
  Assert.AreEqual(64, FImage.Height, 'dovrebbe prendere solo i primi 64 x 64 byte');
end;

procedure TTestTextureFlatDecoder.DovrebbeLeggereUnFlatQuadrato;
begin
  Assert.IsTrue(FDecoder.Decode(TTextureSamples.RandomBytes(3, 256 * 256), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(256, FImage.Width, 'dovrebbe avere 256 di larghezza');
  Assert.AreEqual(256, FImage.Height, 'dovrebbe avere 256 di altezza');
end;

procedure TTestTextureFlatDecoder.DovrebbeDareIColoriDellaPaletteConLAlfaESenzaIlRossoNelBlu;
var
  LPalette: TTexturePixels;
  LBytes: TBytes;
  LExpected: Cardinal;
begin
  LPalette := TTextureSamples.GamePalette;
  LBytes := TTextureSamples.RandomBytes(4, 64 * 64);
  Assert.IsTrue(FDecoder.Decode(LBytes, FImage), 'dovrebbe riuscire');
  // the decoder swaps red and blue, as the old one: so the colors are the palette ones with the channels exchanged
  LExpected := ((LPalette[LBytes[7]] or $FF000000) and $FF00FF00) or ((LPalette[LBytes[7]] and $FF) shl 16) or
    ((LPalette[LBytes[7]] shr 16) and $FF);
  Assert.AreEqual(LExpected, PTextureColorArray(FImage.PixelsPointer)^[7], 'dovrebbe dare il colore con l''alfa e i canali scambiati');
  Assert.IsFalse(FImage.NeedsSwapRGB, 'dovrebbe ricordare che li ha scambiati');
end;

procedure TTestTextureFlatDecoder.DovrebbeRifiutareUnaLunghezzaCheNonEUnFlat;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.RandomBytes(5, 5000), FImage), 'dovrebbe rifiutare 5000 byte');
  Assert.IsFalse(FDecoder.Decode(nil, FImage), 'dovrebbe rifiutare un lump vuoto');
end;

procedure TTestTextureFlatDecoder.DovrebbeRiconoscereLeLunghezzeDeiFlat;
begin
  Assert.IsTrue(TTextureFlatDecoder.IsFlatLength(64 * 64), 'dovrebbe riconoscere 64x64');
  Assert.IsTrue(TTextureFlatDecoder.IsFlatLength(64 * 128), 'dovrebbe riconoscere 64x128');
  Assert.IsTrue(TTextureFlatDecoder.IsFlatLength(4096 * 4096), 'dovrebbe riconoscere 4096x4096');
  Assert.IsFalse(TTextureFlatDecoder.IsFlatLength(128 * 256), 'dovrebbe rifiutare 128x256');
  Assert.IsFalse(TTextureFlatDecoder.IsFlatLength(0), 'dovrebbe rifiutare la lunghezza 0');
  Assert.IsFalse(TTextureFlatDecoder.IsFlatLength(8193 * 2), 'dovrebbe rifiutare una lunghezza vicina');
end;

procedure TTestTextureFlatDecoder.DovrebbeDareLeStesseRispostePerLeLunghezzeDelVecchioCodice;
var
  LFile: TTextureSampleFile;
begin
  for LFile in TTextureSamples.FlatFiles do
    TTextureGolden.Check('inspect.golden.txt', 'inspect-flat-' + LFile.Name,
      BoolToStr(TTextureFlatDecoder.IsFlatLength(Length(LFile.Bytes)), True));
end;

procedure TTestTextureFlatDecoder.DovrebbeRifiutareUnaPaletteCorta;
var
  LDecoder: ITextureDecoder;
begin
  LDecoder := TTextureFlatDecoder.Create(TShortPalette.Create);
  Assert.IsFalse(LDecoder.Decode(TTextureSamples.RandomBytes(6, 64 * 64), FImage), 'dovrebbe dare false con meno di 256 colori');
end;

procedure TTestTextureFlatDecoder.DovrebbeRifiutareUnaPaletteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTextureFlatDecoder.Create(nil);
    end, EArgumentNilException, 'dovrebbe rifiutare una palette nil');
end;

end.
