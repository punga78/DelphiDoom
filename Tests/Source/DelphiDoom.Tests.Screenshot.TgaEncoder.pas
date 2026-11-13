{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotTgaEncoder                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.TgaEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Intf, DelphiDoom.Screenshot.TgaEncoder,
  DelphiDoom.Tests.Imaging.Samples, DelphiDoom.Tests.Screenshot.Samples,
  DelphiDoom.Tests.Screenshot.Golden;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotTgaEncoder = class(TObject)
  private
    FEncoder: IScreenshotEncoder;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodice;
    [Test]
    procedure DovrebbeScrivereLIntestazioneDiUnTgaA32Bit;
    [Test]
    procedure DovrebbeDichiarareLOrigineInAltoPerIlSoftware;
    [Test]
    procedure DovrebbeDichiarareLOrigineInBassoPerOpenGL;
    [Test]
    procedure DovrebbeMettereLAlfaA255;
    [Test]
    procedure DovrebbeScrivereLeDimensioniSuDueByte;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineVuotaOConDimensioniNonValide;
    [Test]
    procedure DovrebbeDareIlFormatoTga;
  end;

implementation

procedure TTestScreenshotTgaEncoder.Setup;
begin
  FEncoder := TScreenshotTgaEncoder.Create;
end;

procedure TTestScreenshotTgaEncoder.DovrebbeDareGliStessiByteDelVecchioCodice;
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
        'tga_' + LCase.Name + '_gl' + IntToStr(LBottomUp),
        TImagingSamples.Hex(TImagingSamples.Hash(FEncoder.Encode(Pointer(LPixels),
          LCase.Width, LCase.Height, LBottomUp = 1))));
  end;
end;

procedure TTestScreenshotTgaEncoder.DovrebbeScrivereLIntestazioneDiUnTgaA32Bit;
var
  LPixels: TBytes;
  LFile: TBytes;
begin
  LPixels := TImagingSamples.RandomBytes(1, 3 * 2 * 4);
  LFile := FEncoder.Encode(Pointer(LPixels), 3, 2, False);
  Assert.AreEqual<Integer>(SCREENSHOT_TGA_HEADER_SIZE + 3 * 2 * 4, Length(LFile));
  Assert.AreEqual(0, Integer(LFile[0]));
  Assert.AreEqual(0, Integer(LFile[1]));
  Assert.AreEqual(2, Integer(LFile[2]), 'senza compressione');
  Assert.AreEqual(32, Integer(LFile[16]), 'bit per pixel');
end;

procedure TTestScreenshotTgaEncoder.DovrebbeDichiarareLOrigineInAltoPerIlSoftware;
var
  LPixels: TBytes;
begin
  LPixels := TImagingSamples.RandomBytes(2, 4);
  Assert.AreEqual(32, Integer(FEncoder.Encode(Pointer(LPixels), 1, 1, False)[17]));
end;

procedure TTestScreenshotTgaEncoder.DovrebbeDichiarareLOrigineInBassoPerOpenGL;
var
  LPixels: TBytes;
  LFile: TBytes;
begin
  LPixels := TImagingSamples.RandomBytes(2, 8);
  LFile := FEncoder.Encode(Pointer(LPixels), 1, 2, True);
  Assert.AreEqual(0, Integer(LFile[17]));
  Assert.AreEqual(Integer(LPixels[0]), Integer(LFile[SCREENSHOT_TGA_HEADER_SIZE]),
    'le righe restano come arrivano');
end;

procedure TTestScreenshotTgaEncoder.DovrebbeMettereLAlfaA255;
var
  LPixels: TBytes;
  LFile: TBytes;
  LIndex: Integer;
begin
  LPixels := TBytes.Create(1, 2, 3, 0, 4, 5, 6, 77);
  LFile := FEncoder.Encode(Pointer(LPixels), 2, 1, False);
  for LIndex := 0 to 1 do
  begin
    Assert.AreEqual(255, Integer(LFile[SCREENSHOT_TGA_HEADER_SIZE + LIndex * 4 + 3]));
    Assert.AreEqual(Integer(LPixels[LIndex * 4]), Integer(LFile[SCREENSHOT_TGA_HEADER_SIZE + LIndex * 4]));
  end;
end;

procedure TTestScreenshotTgaEncoder.DovrebbeScrivereLeDimensioniSuDueByte;
var
  LPixels: TBytes;
  LFile: TBytes;
begin
  SetLength(LPixels, 300 * 258 * 4);
  LFile := FEncoder.Encode(Pointer(LPixels), 300, 258, False);
  Assert.AreEqual(300 and 255, Integer(LFile[12]));
  Assert.AreEqual(300 shr 8, Integer(LFile[13]));
  Assert.AreEqual(258 and 255, Integer(LFile[14]));
  Assert.AreEqual(258 shr 8, Integer(LFile[15]));
end;

procedure TTestScreenshotTgaEncoder.DovrebbeRifiutareUnaImmagineVuotaOConDimensioniNonValide;
var
  LPixels: TBytes;
begin
  SetLength(LPixels, 16);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(nil, 2, 2, False);
    end, EScreenshotException);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(Pointer(LPixels), 0, 2, False);
    end, EScreenshotException);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(Pointer(LPixels), 2, -1, False);
    end, EScreenshotException);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(Pointer(LPixels), 65536, 65536, False);
    end, EScreenshotException);
end;

procedure TTestScreenshotTgaEncoder.DovrebbeDareIlFormatoTga;
begin
  Assert.AreEqual(Ord(TScreenshotFormat.Tga), Ord(FEncoder.Format));
end;

end.
