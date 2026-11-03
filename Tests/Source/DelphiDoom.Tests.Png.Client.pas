{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TPngClient                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.Client;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf,
  DelphiDoom.Png.Intf, DelphiDoom.Png.Client;

type
  [TestFixture]
  [Category('png')]
  TTestPngClient = class(TObject)
  private
    FZlib: IZlib;
    FClient: TPngClient;
    procedure AssertRaisesCode(AExpectedCode: Integer; const AAction: TProc);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutPngRaises;
    [Test]
    procedure TestVersion;
    [Test]
    [TestCase('UnPixel', '1,1')]
    [TestCase('Piccola', '17,13')]
    [TestCase('Grande', '320,200')]
    procedure TestRoundTrip(AWidth, AHeight: Integer);
    [Test]
    procedure TestEncodeOfOtherFormats;
    [Test]
    procedure TestEncodeWithLevelZeroAndNine;
    [Test]
    procedure TestEncodeWithNegativeStride;
    [Test]
    procedure TestGetInfo;
    [Test]
    procedure TestDecodeIndexed;
    [Test]
    procedure TestDecodeIndexedOfAnRgbImageRaisesUnsupported;
    [Test]
    procedure TestDecodeGarbageRaisesData;
    [Test]
    procedure TestDecodeTruncatedFileRaisesTruncated;
    [Test]
    procedure TestDecodeEmptyArrayRaisesInvalidArgument;
    [Test]
    procedure TestGetInfoOfEnormousImageRaisesTooLarge;
    [Test]
    procedure TestEncodeWithTooFewPixelsRaisesInvalidArgument;
    [Test]
    procedure TestEncodeWithInvalidFormatRaisesInvalidArgument;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine, DelphiDoom.Png.Engine, DelphiDoom.Tests.Png.Samples;

{ TTestPngClient }

procedure TTestPngClient.Setup;
begin
  FZlib := TZlibEngine.Create;
  FClient := TPngClient.Create(TPngEngine.Create(FZlib));
end;

procedure TTestPngClient.TearDown;
begin
  FreeAndNil(FClient);
  FZlib := nil;
end;

procedure TTestPngClient.AssertRaisesCode(AExpectedCode: Integer;
  const AAction: TProc);
begin
  try
    AAction();
  except
    on E: EPngException do
    begin
      Assert.AreEqual(AExpectedCode, E.Code);
      Exit;
    end;
  end;
  Assert.Fail('EPngException expected');
end;

procedure TTestPngClient.TestCreateWithoutPngRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TPngClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestPngClient.TestVersion;
begin
  Assert.AreEqual('DDPng 1.0', FClient.Version);
end;

procedure TTestPngClient.TestRoundTrip(AWidth, AHeight: Integer);
var
  LPixels: TBytes;
  LImage: TPngImage;
  LIndex: Integer;
begin
  LPixels := TPngSamples.Noise(AWidth * AHeight * 4, AWidth * 7 + AHeight);
  LImage := FClient.Decode(FClient.Encode(LPixels, AWidth, AHeight));

  Assert.AreEqual(AWidth, LImage.Info.Width);
  Assert.AreEqual(AHeight, LImage.Info.Height);
  Assert.AreEqual(Length(LPixels), Length(LImage.Pixels));
  for LIndex := 0 to High(LPixels) do
    if LPixels[LIndex] <> LImage.Pixels[LIndex] then
      Assert.Fail(Format('byte %d differs', [LIndex]));
end;

procedure TTestPngClient.TestEncodeOfOtherFormats;
var
  LGray: TBytes;
  LImage: TPngImage;
begin
  // A 2x2 gray image: every pixel comes back as B = G = R = gray, A = 255
  LGray := TPngSamples.Bytes([10, 20, 30, 40]);
  LImage := FClient.Decode(FClient.Encode(LGray, 2, 2, DDPNG_FORMAT_GRAY));

  Assert.AreEqual(DDPNG_COLOR_GRAY, LImage.Info.ColorType);
  Assert.AreEqual(Integer(30), Integer(LImage.Pixels[8]));
  Assert.AreEqual(Integer(30), Integer(LImage.Pixels[9]));
  Assert.AreEqual(Integer(30), Integer(LImage.Pixels[10]));
  Assert.AreEqual(Integer(255), Integer(LImage.Pixels[11]));

  // One BGR pixel: B, G, R in memory, written as RGB
  LImage := FClient.Decode(FClient.Encode(TPngSamples.Bytes([1, 2, 3]), 1, 1,
    DDPNG_FORMAT_BGR));
  Assert.AreEqual(DDPNG_COLOR_RGB, LImage.Info.ColorType);
  Assert.AreEqual(Integer(1), Integer(LImage.Pixels[0]));
  Assert.AreEqual(Integer(3), Integer(LImage.Pixels[2]));
  Assert.AreEqual(Integer(255), Integer(LImage.Pixels[3]));
end;

procedure TTestPngClient.TestEncodeWithLevelZeroAndNine;
var
  LPixels: TBytes;
  LIndex: Integer;
begin
  SetLength(LPixels, 32 * 32 * 4);
  for LIndex := 0 to High(LPixels) do
    LPixels[LIndex] := Byte(LIndex and 3);

  Assert.IsTrue(Length(FClient.Encode(LPixels, 32, 32, DDPNG_FORMAT_BGRA, 0)) >
    Length(FClient.Encode(LPixels, 32, 32, DDPNG_FORMAT_BGRA, 9)));
end;

procedure TTestPngClient.TestEncodeWithNegativeStride;
var
  LTopDown: TBytes;
  LBottomUp: TBytes;
  LImage: TPngImage;
  LRow: Integer;
  LIndex: Integer;
begin
  // 4x3 BGRA kept bottom-up: the first row of the array is the last row of
  // the image
  LTopDown := TPngSamples.Noise(4 * 3 * 4, 31);
  SetLength(LBottomUp, Length(LTopDown));
  for LRow := 0 to 2 do
    Move(LTopDown[LRow * 16], LBottomUp[(2 - LRow) * 16], 16);

  LImage := FClient.Decode(FClient.Encode(LBottomUp, 4, 3, DDPNG_FORMAT_BGRA,
    DDPNG_DEFAULT_LEVEL, -16));
  for LIndex := 0 to High(LTopDown) do
    if LTopDown[LIndex] <> LImage.Pixels[LIndex] then
      Assert.Fail(Format('byte %d differs', [LIndex]));
end;

procedure TTestPngClient.TestGetInfo;
var
  LInfo: TPngInfo;
begin
  LInfo := FClient.GetInfo(FClient.Encode(TPngSamples.Noise(9 * 4 * 3), 9, 4,
    DDPNG_FORMAT_BGR));
  Assert.AreEqual(9, LInfo.Width);
  Assert.AreEqual(4, LInfo.Height);
  Assert.AreEqual(8, LInfo.BitDepth);
  Assert.AreEqual(DDPNG_COLOR_RGB, LInfo.ColorType);
  Assert.AreEqual(0, LInfo.Interlaced);
end;

procedure TTestPngClient.TestDecodeIndexed;
var
  LPng: TBytes;
  LImage: TPngIndexedImage;
begin
  LPng := TPngSamples.Assemble(FZlib, 2, 2, 8, DDPNG_COLOR_PALETTE, 0,
    TPngSamples.Chunk('PLTE', TPngSamples.Bytes([10, 20, 30, 40, 50, 60])),
    TPngSamples.Bytes([0, 0, 1, 0, 1, 0]));

  LImage := FClient.DecodeIndexed(LPng);
  Assert.AreEqual(2, LImage.Info.PaletteCount);
  Assert.AreEqual(4, Length(LImage.Pixels));
  Assert.AreEqual(DDPNG_PALETTE_BYTES, Length(LImage.Palette));
  Assert.AreEqual(Integer(0), Integer(LImage.Pixels[0]));
  Assert.AreEqual(Integer(1), Integer(LImage.Pixels[1]));
  Assert.AreEqual(Integer(1), Integer(LImage.Pixels[2]));
  Assert.AreEqual(Integer(0), Integer(LImage.Pixels[3]));
  // Entry 1 is (R, G, B) = (40, 50, 60): B, G, R, A in the palette
  Assert.AreEqual(Integer(60), Integer(LImage.Palette[4]));
  Assert.AreEqual(Integer(50), Integer(LImage.Palette[5]));
  Assert.AreEqual(Integer(40), Integer(LImage.Palette[6]));
  Assert.AreEqual(Integer(255), Integer(LImage.Palette[7]));
end;

procedure TTestPngClient.TestDecodeIndexedOfAnRgbImageRaisesUnsupported;
var
  LPng: TBytes;
begin
  LPng := FClient.Encode(TPngSamples.Noise(4 * 4 * 3), 4, 4, DDPNG_FORMAT_BGR);
  AssertRaisesCode(DDPNG_ERR_UNSUPPORTED,
    procedure
    begin
      FClient.DecodeIndexed(LPng);
    end);
end;

procedure TTestPngClient.TestDecodeGarbageRaisesData;
begin
  AssertRaisesCode(DDPNG_ERR_DATA,
    procedure
    begin
      FClient.Decode(TPngSamples.Noise(200));
    end);
end;

procedure TTestPngClient.TestDecodeTruncatedFileRaisesTruncated;
var
  LPng: TBytes;
begin
  LPng := FClient.Encode(TPngSamples.Noise(32 * 32 * 4), 32, 32);
  AssertRaisesCode(DDPNG_ERR_TRUNCATED,
    procedure
    begin
      FClient.Decode(TPngSamples.Slice(LPng, 0, Length(LPng) div 2));
    end);
end;

procedure TTestPngClient.TestDecodeEmptyArrayRaisesInvalidArgument;
begin
  AssertRaisesCode(DDPNG_ERR_INVALID_ARGUMENT,
    procedure
    begin
      FClient.Decode(nil, 0);
    end);
end;

procedure TTestPngClient.TestGetInfoOfEnormousImageRaisesTooLarge;
var
  LPng: TBytes;
begin
  LPng := TPngSamples.Concat([TPngSamples.Signature,
    TPngSamples.Header(100000, 100000, 8, DDPNG_COLOR_RGBA, 0),
    TPngSamples.Chunk('IEND', nil)]);
  AssertRaisesCode(DDPNG_ERR_TOO_LARGE,
    procedure
    begin
      FClient.GetInfo(LPng);
    end);
  AssertRaisesCode(DDPNG_ERR_TOO_LARGE,
    procedure
    begin
      FClient.Decode(LPng);
    end);
end;

procedure TTestPngClient.TestEncodeWithTooFewPixelsRaisesInvalidArgument;
begin
  AssertRaisesCode(DDPNG_ERR_INVALID_ARGUMENT,
    procedure
    begin
      FClient.Encode(TPngSamples.Noise(10), 4, 4);
    end);
end;

procedure TTestPngClient.TestEncodeWithInvalidFormatRaisesInvalidArgument;
begin
  AssertRaisesCode(DDPNG_ERR_INVALID_ARGUMENT,
    procedure
    begin
      FClient.Encode(TPngSamples.Noise(64), 4, 4, 9);
    end);
  AssertRaisesCode(DDPNG_ERR_INVALID_ARGUMENT,
    procedure
    begin
      FClient.Encode(TPngSamples.Noise(64), 0, 4);
    end);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPngClient);

end.
