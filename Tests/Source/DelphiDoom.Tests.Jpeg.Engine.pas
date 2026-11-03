{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegEngine                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegEngine = class(TObject)
  private
    FJpeg: IJpeg;
    function MakeGradient(AWidth, AHeight, AComponents: Integer): TBytes;
    function MakeNoise(AWidth, AHeight, AComponents: Integer): TBytes;
    function HexToBytes(const AHex: string): TBytes;
    function MaxDifference(const AExpected, AActual: TBytes): Integer;
    function EncodeAll(const APixels: TBytes; AWidth, AHeight, AComponents,
      AQuality: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVersion;

    [Test]
    [TestCase('Grigio', '40,24,1')]
    [TestCase('Colore', '40,24,3')]
    [TestCase('NonMultiploDiOtto', '17,13,3')]
    [TestCase('UnPixel', '1,1,3')]
    procedure TestRoundTrip(AWidth, AHeight, AComponents: Integer);
    [Test]
    procedure TestRoundTripKeepsTheOrderOfColors;
    [Test]
    [TestCase('Grigio', '40,24,1')]
    [TestCase('Colore', '40,24,3')]
    [TestCase('NonMultiploDiOtto', '17,13,3')]
    procedure TestEncodeBoundIsNotSmallerThanTheStream(AWidth, AHeight,
      AComponents: Integer);
    [Test]
    procedure TestEncodeBoundOfInvalidFormatIsZero;
    [Test]
    procedure TestHigherQualityGivesLargerStream;
    [Test]
    procedure TestQualityOutOfRangeIsClamped;
    [Test]
    procedure TestEncodeIntoTooSmallBufferReturnsBufferTooSmall;
    [Test]
    procedure TestEncodeInvalidArgumentsReturnInvalidArgument;

    [Test]
    procedure TestGetInfoReadsTheHeader;
    [Test]
    procedure TestDecodeColorImageOfAnotherEncoder;
    [Test]
    procedure TestDecodeGrayImageOfAnotherEncoder;
    [Test]
    procedure TestDecodeIntoTooSmallBufferReturnsBufferTooSmallWithInfo;
    [Test]
    procedure TestDecodeGarbageReturnsDataError;
    [Test]
    procedure TestDecodeTruncatedStreamReturnsTruncated;
    [Test]
    procedure TestDecodeWithoutSourceReturnsInvalidArgument;
  end;

implementation

uses
  DelphiDoom.Jpeg.Engine;

const
  // 16x16 solid red image, 4:2:0, made with an encoder other than ours
  RED_IMAGE_HEX =
    'FFD8FFE000104A46494600010100000100010000FFDB00430003020203020203' +
    '03030304030304050805050404050A070706080C0A0C0C0B0A0B0B0D0E12100D' +
    '0E110E0B0B1016101113141515150C0F171816141812141514FFDB0043010304' +
    '0405040509050509140D0B0D1414141414141414141414141414141414141414' +
    '141414141414141414141414141414141414141414141414141414141414FFC0' +
    '0011080010001003012200021101031101FFC4001F0000010501010101010100' +
    '000000000000000102030405060708090A0BFFC400B510000201030302040305' +
    '0504040000017D01020300041105122131410613516107227114328191A10823' +
    '42B1C11552D1F02433627282090A161718191A25262728292A3435363738393A' +
    '434445464748494A535455565758595A636465666768696A737475767778797A' +
    '838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7' +
    'B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1' +
    'F2F3F4F5F6F7F8F9FAFFC4001F01000301010101010101010100000000000001' +
    '02030405060708090A0BFFC400B5110002010204040304070504040001027700' +
    '0102031104052131061241510761711322328108144291A1B1C109233352F015' +
    '6272D10A162434E125F11718191A262728292A35363738393A43444546474849' +
    '4A535455565758595A636465666768696A737475767778797A82838485868788' +
    '898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4' +
    'C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9' +
    'FAFFDA000C03010002110311003F00F9D28A28AFC30FF54CFFD9';

  // 8x8 solid gray image (value 200), made with an encoder other than ours
  GRAY_IMAGE_HEX =
    'FFD8FFE000104A46494600010100000100010000FFDB00430003020203020203' +
    '03030304030304050805050404050A070706080C0A0C0C0B0A0B0B0D0E12100D' +
    '0E110E0B0B1016101113141515150C0F171816141812141514FFC0000B080008' +
    '000801011100FFC4001F00000105010101010101000000000000000001020304' +
    '05060708090A0BFFC400B5100002010303020403050504040000017D01020300' +
    '041105122131410613516107227114328191A1082342B1C11552D1F024336272' +
    '82090A161718191A25262728292A3435363738393A434445464748494A535455' +
    '565758595A636465666768696A737475767778797A838485868788898A929394' +
    '95969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9' +
    'CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1F2F3F4F5F6F7F8F9FAFFDA' +
    '0008010100003F00FB02BFFFD9';

  // Largest difference between a pixel and its decoded value at the quality
  // used by the tests, for the smooth images they use
  PIXEL_TOLERANCE = 6;

{ TTestJpegEngine }

procedure TTestJpegEngine.Setup;
begin
  FJpeg := TJpegEngine.Create;
end;

procedure TTestJpegEngine.TearDown;
begin
  FJpeg := nil;
end;

function TTestJpegEngine.MakeGradient(AWidth, AHeight, AComponents: Integer): TBytes;
var
  LX: Integer;
  LY: Integer;
  LComponent: Integer;
begin
  // Smooth image: a JPEG reproduces it closely at high quality
  SetLength(Result, AWidth * AHeight * AComponents);
  for LY := 0 to AHeight - 1 do
    for LX := 0 to AWidth - 1 do
      for LComponent := 0 to AComponents - 1 do
        Result[(LY * AWidth + LX) * AComponents + LComponent] :=
          Byte(LX * 3 + LY * 2 + LComponent * 40);
end;

function TTestJpegEngine.MakeNoise(AWidth, AHeight, AComponents: Integer): TBytes;
var
  LIndex: Integer;
  LSeed: Int64;
begin
  SetLength(Result, AWidth * AHeight * AComponents);
  LSeed := 12345;
  for LIndex := 0 to High(Result) do
  begin
    LSeed := (LSeed * 1103515245 + 12345) and $7FFFFFFF;
    Result[LIndex] := Byte((LSeed shr 16) and $FF);
  end;
end;

function TTestJpegEngine.HexToBytes(const AHex: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(StrToInt('$' + Copy(AHex, LIndex * 2 + 1, 2)));
end;

function TTestJpegEngine.MaxDifference(const AExpected, AActual: TBytes): Integer;
var
  LIndex: Integer;
  LDifference: Integer;
begin
  Assert.AreEqual(Length(AExpected), Length(AActual));
  Result := 0;
  for LIndex := 0 to High(AExpected) do
  begin
    LDifference := Abs(Integer(AExpected[LIndex]) - Integer(AActual[LIndex]));
    if LDifference > Result then
      Result := LDifference;
  end;
end;

function TTestJpegEngine.EncodeAll(const APixels: TBytes; AWidth, AHeight,
  AComponents, AQuality: Integer): TBytes;
var
  LSize: Cardinal;
begin
  LSize := FJpeg.EncodeBound(AWidth, AHeight, AComponents);
  SetLength(Result, LSize);
  Assert.AreEqual(DDJPEG_OK, FJpeg.Encode(Pointer(APixels), AWidth, AHeight,
    AComponents, AQuality, Pointer(Result), LSize));
  SetLength(Result, LSize);
end;

procedure TTestJpegEngine.TestVersion;
begin
  Assert.AreEqual('6b', string(AnsiString(FJpeg.GetVersion)));
end;

procedure TTestJpegEngine.TestRoundTrip(AWidth, AHeight, AComponents: Integer);
var
  LPixels, LStream, LRestored: TBytes;
  LInfo: TJpegInfo;
begin
  LPixels := MakeGradient(AWidth, AHeight, AComponents);
  LStream := EncodeAll(LPixels, AWidth, AHeight, AComponents, 95);

  SetLength(LRestored, Length(LPixels));
  Assert.AreEqual(DDJPEG_OK, FJpeg.Decode(Pointer(LStream), Length(LStream),
    Pointer(LRestored), Length(LRestored), LInfo));
  Assert.AreEqual(AWidth, LInfo.Width);
  Assert.AreEqual(AHeight, LInfo.Height);
  Assert.AreEqual(AComponents, LInfo.Components);
  Assert.IsTrue(MaxDifference(LPixels, LRestored) <= PIXEL_TOLERANCE,
    'Decoded pixels differ too much from the original');
end;

procedure TTestJpegEngine.TestRoundTripKeepsTheOrderOfColors;
var
  LPixels, LStream, LRestored: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  // Solid color with B, G, R all different
  SetLength(LPixels, 16 * 16 * 3);
  for LIndex := 0 to 16 * 16 - 1 do
  begin
    LPixels[LIndex * 3] := 200;
    LPixels[LIndex * 3 + 1] := 100;
    LPixels[LIndex * 3 + 2] := 20;
  end;
  LStream := EncodeAll(LPixels, 16, 16, 3, 95);

  SetLength(LRestored, Length(LPixels));
  Assert.AreEqual(DDJPEG_OK, FJpeg.Decode(Pointer(LStream), Length(LStream),
    Pointer(LRestored), Length(LRestored), LInfo));
  Assert.IsTrue(MaxDifference(LPixels, LRestored) <= PIXEL_TOLERANCE,
    'The order of the color components is not preserved');
end;

procedure TTestJpegEngine.TestEncodeBoundIsNotSmallerThanTheStream(AWidth,
  AHeight, AComponents: Integer);
var
  LBound: Cardinal;
  LStream: TBytes;
begin
  // The worst case for the entropy coder is noise at the highest quality
  LBound := FJpeg.EncodeBound(AWidth, AHeight, AComponents);
  LStream := EncodeAll(MakeNoise(AWidth, AHeight, AComponents), AWidth, AHeight,
    AComponents, 100);
  Assert.IsTrue(Cardinal(Length(LStream)) <= LBound);
end;

procedure TTestJpegEngine.TestEncodeBoundOfInvalidFormatIsZero;
begin
  Assert.AreEqual(Cardinal(0), FJpeg.EncodeBound(0, 10, 3));
  Assert.AreEqual(Cardinal(0), FJpeg.EncodeBound(10, 0, 3));
  Assert.AreEqual(Cardinal(0), FJpeg.EncodeBound(10, 10, 2));
  Assert.AreEqual(Cardinal(0), FJpeg.EncodeBound(DDJPEG_MAX_DIMENSION + 1, 10, 3));
end;

procedure TTestJpegEngine.TestHigherQualityGivesLargerStream;
var
  LPixels: TBytes;
begin
  LPixels := MakeNoise(48, 48, 3);
  Assert.IsTrue(Length(EncodeAll(LPixels, 48, 48, 3, 95)) >
    Length(EncodeAll(LPixels, 48, 48, 3, 20)));
end;

procedure TTestJpegEngine.TestQualityOutOfRangeIsClamped;
var
  LPixels: TBytes;
begin
  LPixels := MakeGradient(16, 16, 3);
  Assert.IsTrue(Length(EncodeAll(LPixels, 16, 16, 3, -5)) > 0);
  Assert.IsTrue(Length(EncodeAll(LPixels, 16, 16, 3, 1000)) > 0);
end;

procedure TTestJpegEngine.TestEncodeIntoTooSmallBufferReturnsBufferTooSmall;
var
  LPixels, LDest: TBytes;
  LSize: Cardinal;
begin
  LPixels := MakeNoise(32, 32, 3);
  SetLength(LDest, 100);
  LSize := Length(LDest);
  Assert.AreEqual(DDJPEG_ERR_BUFFER_TOO_SMALL, FJpeg.Encode(Pointer(LPixels),
    32, 32, 3, 90, Pointer(LDest), LSize));
end;

procedure TTestJpegEngine.TestEncodeInvalidArgumentsReturnInvalidArgument;
var
  LPixels, LDest: TBytes;
  LSize: Cardinal;
begin
  LPixels := MakeGradient(16, 16, 3);
  SetLength(LDest, 4096);

  LSize := Length(LDest);
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, FJpeg.Encode(Pointer(LPixels),
    0, 16, 3, 90, Pointer(LDest), LSize), 'width 0');
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, FJpeg.Encode(Pointer(LPixels),
    16, 16, 2, 90, Pointer(LDest), LSize), 'two components');
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, FJpeg.Encode(nil,
    16, 16, 3, 90, Pointer(LDest), LSize), 'no pixels');
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, FJpeg.Encode(Pointer(LPixels),
    16, 16, 3, 90, nil, LSize), 'no destination');
end;

procedure TTestJpegEngine.TestGetInfoReadsTheHeader;
var
  LStream: TBytes;
  LInfo: TJpegInfo;
begin
  LStream := EncodeAll(MakeGradient(40, 24, 3), 40, 24, 3, 90);
  Assert.AreEqual(DDJPEG_OK, FJpeg.GetInfo(Pointer(LStream), Length(LStream), LInfo));
  Assert.AreEqual(40, LInfo.Width);
  Assert.AreEqual(24, LInfo.Height);
  Assert.AreEqual(3, LInfo.Components);

  LStream := EncodeAll(MakeGradient(8, 8, 1), 8, 8, 1, 90);
  Assert.AreEqual(DDJPEG_OK, FJpeg.GetInfo(Pointer(LStream), Length(LStream), LInfo));
  Assert.AreEqual(1, LInfo.Components);
end;

procedure TTestJpegEngine.TestDecodeColorImageOfAnotherEncoder;
var
  LStream, LPixels: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  LStream := HexToBytes(RED_IMAGE_HEX);
  SetLength(LPixels, 16 * 16 * 3);
  Assert.AreEqual(DDJPEG_OK, FJpeg.Decode(Pointer(LStream), Length(LStream),
    Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(16, LInfo.Width);
  Assert.AreEqual(16, LInfo.Height);
  Assert.AreEqual(3, LInfo.Components);

  // Red in B, G, R order is (0, 0, 255)
  for LIndex := 0 to 16 * 16 - 1 do
  begin
    Assert.IsTrue(LPixels[LIndex * 3] <= 4, 'blue');
    Assert.IsTrue(LPixels[LIndex * 3 + 1] <= 4, 'green');
    Assert.IsTrue(LPixels[LIndex * 3 + 2] >= 250, 'red');
  end;
end;

procedure TTestJpegEngine.TestDecodeGrayImageOfAnotherEncoder;
var
  LStream, LPixels: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  LStream := HexToBytes(GRAY_IMAGE_HEX);
  SetLength(LPixels, 8 * 8);
  Assert.AreEqual(DDJPEG_OK, FJpeg.Decode(Pointer(LStream), Length(LStream),
    Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(8, LInfo.Width);
  Assert.AreEqual(8, LInfo.Height);
  Assert.AreEqual(1, LInfo.Components);

  for LIndex := 0 to High(LPixels) do
    Assert.IsTrue(Abs(Integer(LPixels[LIndex]) - 200) <= 4);
end;

procedure TTestJpegEngine.TestDecodeIntoTooSmallBufferReturnsBufferTooSmallWithInfo;
var
  LStream, LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  LStream := EncodeAll(MakeGradient(40, 24, 3), 40, 24, 3, 90);
  SetLength(LPixels, 10);
  Assert.AreEqual(DDJPEG_ERR_BUFFER_TOO_SMALL, FJpeg.Decode(Pointer(LStream),
    Length(LStream), Pointer(LPixels), Length(LPixels), LInfo));
  // The caller can size the buffer from the information
  Assert.AreEqual(40, LInfo.Width);
  Assert.AreEqual(24, LInfo.Height);
  Assert.AreEqual(3, LInfo.Components);
end;

procedure TTestJpegEngine.TestDecodeGarbageReturnsDataError;
var
  LGarbage, LPixels: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  SetLength(LGarbage, 64);
  for LIndex := 0 to High(LGarbage) do
    LGarbage[LIndex] := Byte(LIndex * 13 + 1);
  SetLength(LPixels, 1000);
  Assert.AreEqual(DDJPEG_ERR_DATA, FJpeg.Decode(Pointer(LGarbage),
    Length(LGarbage), Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(DDJPEG_ERR_DATA, FJpeg.GetInfo(Pointer(LGarbage),
    Length(LGarbage), LInfo));
end;

procedure TTestJpegEngine.TestDecodeTruncatedStreamReturnsTruncated;
var
  LStream, LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  // Noise does not compress: half of the stream is far beyond the header
  LStream := EncodeAll(MakeNoise(96, 96, 3), 96, 96, 3, 90);
  SetLength(LPixels, 96 * 96 * 3);
  Assert.AreEqual(DDJPEG_ERR_TRUNCATED, FJpeg.Decode(Pointer(LStream),
    Length(LStream) div 2, Pointer(LPixels), Length(LPixels), LInfo));
end;

procedure TTestJpegEngine.TestDecodeWithoutSourceReturnsInvalidArgument;
var
  LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  SetLength(LPixels, 100);
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, FJpeg.Decode(nil, 0,
    Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, FJpeg.GetInfo(nil, 10, LInfo));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJpegEngine);

end.
