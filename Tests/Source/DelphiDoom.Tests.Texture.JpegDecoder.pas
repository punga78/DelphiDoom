{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureJpegDecoder                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.JpegDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.Bmp, DelphiDoom.Texture.Decoder.Jpeg,
  DelphiDoom.Tests.Texture.Samples, DelphiDoom.Tests.Texture.Fakes;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureJpegDecoder = class(TObject)
  private
    FConverter: TFakeJpegConverter;
    FConverterInterface: ITextureJpegConverter;
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLEstensioneCheHaRicevuto;
    [Test]
    procedure DovrebbeLeggereLaBitmapDelConvertitore;
    [Test]
    procedure DovrebbeRispecchiareLImmagineDopoLaLettura;
    [Test]
    procedure DovrebbeDareFalseSeLaBitmapNonSiLegge;
    [Test]
    procedure DovrebbeLasciarePassareLErroreDelConvertitore;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzaNil;
  end;

implementation

procedure TTestTextureJpegDecoder.Setup;
begin
  FConverter := TFakeJpegConverter.Create;
  FConverterInterface := FConverter;
  // a bitmap of 24 bit, 3x1: the pixels $010203, $040506 and $070809 as B, G, R (so $00RRGGBB with the bytes in reverse)
  FConverter.Bitmap := TTextureSamples.Bmp(3, 1, 24, 0, nil, TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0));
  FDecoder := TTextureJpegDecoder.Create('.JPG', FConverter, TTextureBmpDecoder.Create);
  FImage := TTextureImage.Create;
end;

procedure TTestTextureJpegDecoder.TearDown;
begin
  FImage.Free;
  FDecoder := nil;
  FConverterInterface := nil;
end;

procedure TTestTextureJpegDecoder.DovrebbeDireLEstensioneCheHaRicevuto;
var
  LOther: ITextureDecoder;
begin
  Assert.AreEqual('.JPG', FDecoder.Extension, 'dovrebbe dire .JPG');
  LOther := TTextureJpegDecoder.Create('.JPEG', FConverter, TTextureBmpDecoder.Create);
  Assert.AreEqual('.JPEG', LOther.Extension, 'dovrebbe dire .JPEG');
end;

procedure TTestTextureJpegDecoder.DovrebbeLeggereLaBitmapDelConvertitore;
begin
  Assert.IsTrue(FDecoder.Decode(TBytes.Create(1, 2, 3), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(1, FConverter.Calls, 'dovrebbe chiamare il convertitore una volta');
  Assert.AreEqual(3, FImage.Width, 'dovrebbe avere la larghezza della bitmap');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
end;

procedure TTestTextureJpegDecoder.DovrebbeRispecchiareLImmagineDopoLaLettura;
begin
  Assert.IsTrue(FDecoder.Decode(TBytes.Create(1, 2, 3), FImage), 'dovrebbe riuscire');
  // the bitmap has the pixel with the bytes 1, 2, 3 first; after the mirror it is the last one
  Assert.AreEqual(Cardinal($00030201), PTextureColorArray(FImage.PixelsPointer)^[2], 'dovrebbe avere il primo pixel per ultimo');
  Assert.AreEqual(Cardinal($00090807), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe avere l''ultimo pixel per primo');
end;

procedure TTestTextureJpegDecoder.DovrebbeDareFalseSeLaBitmapNonSiLegge;
begin
  FConverter.Bitmap := TTextureSamples.Bmp(2, 2, 32, 0, nil, TTextureSamples.RandomBytes(1, 16));
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(1, 2, 3), FImage), 'dovrebbe dare false');
end;

procedure TTestTextureJpegDecoder.DovrebbeLasciarePassareLErroreDelConvertitore;
begin
  FConverter.Fails := True;
  Assert.WillRaise(
    procedure
    begin
      FDecoder.Decode(TBytes.Create(1, 2, 3), FImage);
    end, ETextureException, 'dovrebbe lasciar passare l''errore');
end;

procedure TTestTextureJpegDecoder.DovrebbeRifiutareLeDipendenzaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTextureJpegDecoder.Create('.JPG', nil, TTextureBmpDecoder.Create);
    end, EArgumentNilException, 'dovrebbe rifiutare un convertitore nil');
  Assert.WillRaise(
    procedure
    begin
      TTextureJpegDecoder.Create('.JPG', FConverter, nil);
    end, EArgumentNilException, 'dovrebbe rifiutare un decoder di bitmap nil');
end;

end.
