{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotJpegEncoder                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.JpegEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Engine, DelphiDoom.Jpeg.Client,
  DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.Intf, DelphiDoom.Screenshot.JpegEncoder;

type
  /// <remarks>
  ///   The JPEG is lossy and the encoder is not the one of the VCL that the old code used
  ///   (that one gave a mean error of about 1 on a smooth image and the same here): the tests
  ///   declare a tolerance instead of comparing bytes
  /// </remarks>
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotJpegEncoder = class(TObject)
  private
    FJpeg: TJpegClient;
    FEncoder: IScreenshotEncoder;
    class function SmoothImage(AWidth, AHeight: Integer): TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnClientNil;
    [Test]
    procedure DovrebbeDareUnaImmagineVicinaAllOriginale;
    [Test]
    procedure DovrebbeTenereLoStessoOrdineDeiColori;
    [Test]
    procedure DovrebbeCapovolgereLeRigheSeIlPrimoRigoEQuelloInBasso;
    [Test]
    procedure DovrebbeScrivereUnaImmagineDiDimensioniNonMultipleDiOtto;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineVuota;
    [Test]
    procedure DovrebbeDareIlFormatoJpg;
  end;

implementation

class function TTestScreenshotJpegEncoder.SmoothImage(AWidth, AHeight: Integer): TBytes;
var
  LX: Integer;
  LY: Integer;
begin
  SetLength(Result, AWidth * AHeight * 4);
  for LY := 0 to AHeight - 1 do
    for LX := 0 to AWidth - 1 do
    begin
      Result[(LY * AWidth + LX) * 4] := Byte(LX * 255 div AWidth);
      Result[(LY * AWidth + LX) * 4 + 1] := Byte(LY * 255 div AHeight);
      Result[(LY * AWidth + LX) * 4 + 2] := Byte((LX + LY) * 255 div (AWidth + AHeight));
      Result[(LY * AWidth + LX) * 4 + 3] := 7;
    end;
end;

procedure TTestScreenshotJpegEncoder.Setup;
begin
  FJpeg := TJpegClient.Create(TJpegEngine.Create);
  FEncoder := TScreenshotJpegEncoder.Create(FJpeg);
end;

procedure TTestScreenshotJpegEncoder.TearDown;
begin
  FEncoder := nil;
  FJpeg.Free;
end;

procedure TTestScreenshotJpegEncoder.DovrebbeRifiutareUnClientNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScreenshotJpegEncoder.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestScreenshotJpegEncoder.DovrebbeDareUnaImmagineVicinaAllOriginale;
var
  LPixels: TBytes;
  LImage: TJpegImage;
  LIndex: Integer;
  LSum: Int64;
  LMax: Integer;
  LDelta: Integer;
begin
  LPixels := SmoothImage(64, 48);
  LImage := FJpeg.Decode(FEncoder.Encode(Pointer(LPixels), 64, 48, False));
  Assert.AreEqual(64, LImage.Width);
  Assert.AreEqual(48, LImage.Height);
  Assert.AreEqual(3, LImage.Components);
  LSum := 0;
  LMax := 0;
  for LIndex := 0 to 64 * 48 - 1 do
  begin
    LDelta := Abs(Integer(LPixels[LIndex * 4]) - Integer(LImage.Pixels[LIndex * 3]));
    LSum := LSum + LDelta;
    if LDelta > LMax then
      LMax := LDelta;
    LDelta := Abs(Integer(LPixels[LIndex * 4 + 2]) - Integer(LImage.Pixels[LIndex * 3 + 2]));
    LSum := LSum + LDelta;
    if LDelta > LMax then
      LMax := LDelta;
  end;
  Assert.IsTrue(LSum / (64 * 48 * 2) <= 2.0, 'errore medio al massimo 2 su 255');
  Assert.IsTrue(LMax <= 12, 'errore massimo al massimo 12 su 255');
end;

procedure TTestScreenshotJpegEncoder.DovrebbeTenereLoStessoOrdineDeiColori;
var
  LPixels: TBytes;
  LImage: TJpegImage;
  LIndex: Integer;
begin
  // a field of pure red (B, G, R = 0, 0, 255)
  SetLength(LPixels, 16 * 16 * 4);
  for LIndex := 0 to 16 * 16 - 1 do
    LPixels[LIndex * 4 + 2] := 255;
  LImage := FJpeg.Decode(FEncoder.Encode(Pointer(LPixels), 16, 16, False));
  Assert.IsTrue(LImage.Pixels[2] > 240, 'rosso');
  Assert.IsTrue(LImage.Pixels[0] < 15, 'blu');
  Assert.IsTrue(LImage.Pixels[1] < 15, 'verde');
end;

procedure TTestScreenshotJpegEncoder.DovrebbeCapovolgereLeRigheSeIlPrimoRigoEQuelloInBasso;
var
  LPixels: TBytes;
  LImage: TJpegImage;
  LIndex: Integer;
begin
  // the first row of the buffer is red, the last one blue: bottom up means red goes down
  SetLength(LPixels, 16 * 16 * 4);
  for LIndex := 0 to 16 * 8 - 1 do
    LPixels[LIndex * 4 + 2] := 255;
  for LIndex := 16 * 8 to 16 * 16 - 1 do
    LPixels[LIndex * 4] := 255;
  LImage := FJpeg.Decode(FEncoder.Encode(Pointer(LPixels), 16, 16, True));
  Assert.IsTrue(LImage.Pixels[(1 * 16 + 4) * 3] > 240, 'in alto è blu');
  Assert.IsTrue(LImage.Pixels[(14 * 16 + 4) * 3 + 2] > 240, 'in basso è rosso');
end;

procedure TTestScreenshotJpegEncoder.DovrebbeScrivereUnaImmagineDiDimensioniNonMultipleDiOtto;
var
  LPixels: TBytes;
  LImage: TJpegImage;
begin
  LPixels := SmoothImage(13, 5);
  LImage := FJpeg.Decode(FEncoder.Encode(Pointer(LPixels), 13, 5, False));
  Assert.AreEqual(13, LImage.Width);
  Assert.AreEqual(5, LImage.Height);
end;

procedure TTestScreenshotJpegEncoder.DovrebbeRifiutareUnaImmagineVuota;
begin
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(nil, 8, 8, False);
    end, EScreenshotException);
end;

procedure TTestScreenshotJpegEncoder.DovrebbeDareIlFormatoJpg;
begin
  Assert.AreEqual(Ord(TScreenshotFormat.Jpg), Ord(FEncoder.Format));
end;

end.
