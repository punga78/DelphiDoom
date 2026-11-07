{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotPngEncoder                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.PngEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Engine, DelphiDoom.Png.Engine,
  DelphiDoom.Png.Client, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.Intf,
  DelphiDoom.Screenshot.PngEncoder, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Screenshot.Samples, DelphiDoom.Tests.Screenshot.Golden;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotPngEncoder = class(TObject)
  private
    FPng: TPngClient;
    FEncoder: IScreenshotEncoder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnClientNil;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodice;
    [Test]
    procedure DovrebbeScrivereUnPngCheSiRilegge;
    [Test]
    procedure DovrebbeCapovolgereLeRigheSeIlPrimoRigoEQuelloInBasso;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineVuota;
    [Test]
    procedure DovrebbeDareIlFormatoPng;
  end;

implementation

procedure TTestScreenshotPngEncoder.Setup;
begin
  FPng := TPngClient.Create(TPngEngine.Create(TZlibEngine.Create));
  FEncoder := TScreenshotPngEncoder.Create(FPng);
end;

procedure TTestScreenshotPngEncoder.TearDown;
begin
  FEncoder := nil;
  FPng.Free;
end;

procedure TTestScreenshotPngEncoder.DovrebbeRifiutareUnClientNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScreenshotPngEncoder.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestScreenshotPngEncoder.DovrebbeDareGliStessiByteDelVecchioCodice;
var
  LCase: TScreenshotSampleCase;
  LPixels: TBytes;
  LBottomUp: Integer;
begin
  for LCase in TScreenshotSamples.Cases do
  begin
    LPixels := TScreenshotSamples.Pixels(LCase);
    for LBottomUp := 0 to 1 do
      TScreenshotGolden.Check('encoders.golden.txt',
        'png_' + LCase.Name + '_gl' + IntToStr(LBottomUp),
        TImagingSamples.Hex(TImagingSamples.Hash(FEncoder.Encode(Pointer(LPixels),
          LCase.Width, LCase.Height, LBottomUp = 1))));
  end;
end;

procedure TTestScreenshotPngEncoder.DovrebbeScrivereUnPngCheSiRilegge;
var
  LPixels: TBytes;
  LImage: TPngImage;
  LIndex: Integer;
begin
  LPixels := TImagingSamples.RandomBytes(7, 5 * 3 * 4);
  LImage := FPng.Decode(FEncoder.Encode(Pointer(LPixels), 5, 3, False));
  Assert.AreEqual(5, LImage.Info.Width);
  Assert.AreEqual(3, LImage.Info.Height);
  for LIndex := 0 to 5 * 3 - 1 do
  begin
    Assert.AreEqual(Integer(LPixels[LIndex * 4]), Integer(LImage.Pixels[LIndex * 4]), 'blu');
    Assert.AreEqual(Integer(LPixels[LIndex * 4 + 1]), Integer(LImage.Pixels[LIndex * 4 + 1]), 'verde');
    Assert.AreEqual(Integer(LPixels[LIndex * 4 + 2]), Integer(LImage.Pixels[LIndex * 4 + 2]), 'rosso');
  end;
end;

procedure TTestScreenshotPngEncoder.DovrebbeCapovolgereLeRigheSeIlPrimoRigoEQuelloInBasso;
var
  LPixels: TBytes;
  LImage: TPngImage;
begin
  LPixels := TBytes.Create(10, 20, 30, 0, 40, 50, 60, 0); // two rows of one pixel
  LImage := FPng.Decode(FEncoder.Encode(Pointer(LPixels), 1, 2, True));
  Assert.AreEqual(40, Integer(LImage.Pixels[0]), 'in alto c''è l''ultimo rigo');
  Assert.AreEqual(10, Integer(LImage.Pixels[4]));
end;

procedure TTestScreenshotPngEncoder.DovrebbeRifiutareUnaImmagineVuota;
begin
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(nil, 1, 1, False);
    end, EScreenshotException);
end;

procedure TTestScreenshotPngEncoder.DovrebbeDareIlFormatoPng;
begin
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(FEncoder.Format));
end;

end.
