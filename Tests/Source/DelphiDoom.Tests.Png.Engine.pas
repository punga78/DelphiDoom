{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TPngEngine                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf,
  DelphiDoom.Png.Intf;

type
  [TestFixture]
  [Category('png')]
  TTestPngEngine = class(TObject)
  private
    FZlib: IZlib;
    FPng: IPng;

    function Decode(const APng: TBytes; out AInfo: TPngInfo): TBytes;
    function DecodeCode(const APng: TBytes): Integer;
    function InfoCode(const APng: TBytes): Integer;
    function EncodeAll(const APixels: TBytes; AWidth, AHeight, AFormat,
      ALevel: Integer): TBytes;
    function MakeGradient(AWidth, AHeight, ABytesPerPixel: Integer): TBytes;
    function MakeInterlaced(const APixels: TBytes; AWidth, AHeight,
      ABytesPerPixel: Integer): TBytes;
    function FilteredNoise(AWidth, AHeight, ABytesPerPixel,
      ASeed: Integer): TBytes;
    function RgbaToBgra(const ARgba: TBytes): TBytes;
    function GrayToBgra(const AGrays: array of Byte): TBytes;
    function CustomHeader(AWidth, AHeight, ABitDepth, AColorType,
      ACompression, AFilter, AInterlace: Integer): TBytes;
    function GrayImage(AWidth, AHeight: Integer; const ARaw: TBytes;
      const AExtraChunks: TBytes = nil): TBytes;
    procedure AssertBytes(const AExpected, AActual: TBytes;
      const AMessage: string = '');
    procedure AssertDecodes(const APng, AExpectedBgra: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutZlibRaises;
    [Test]
    procedure TestVersion;

    // CRC
    [Test]
    procedure TestCrcOfTheCheckString;
    [Test]
    procedure TestCrcOfTheIendType;
    [Test]
    procedure TestCrcCanBeContinued;

    // Filters
    [Test]
    procedure TestDecodeFilterSubUpAndAverage;
    [Test]
    procedure TestDecodeFilterPaeth;
    [Test]
    procedure TestDecodeFilterSubWithThreeBytesPerPixel;
    [Test]
    procedure TestDecodeInvalidFilterTypeReturnsData;

    // Color types and bit depths
    [Test]
    procedure TestDecodeGray1Bit;
    [Test]
    procedure TestDecodeGray2Bit;
    [Test]
    procedure TestDecodeGray4Bit;
    [Test]
    procedure TestDecodeGray16Bit;
    [Test]
    procedure TestDecodeSubByteRowsArePadded;
    [Test]
    procedure TestDecodeGrayAlpha8Bit;
    [Test]
    procedure TestDecodeGrayAlpha16Bit;
    [Test]
    procedure TestDecodeRgb16Bit;
    [Test]
    procedure TestDecodeRgba8Bit;
    [Test]
    procedure TestDecodeRgba16Bit;
    [Test]
    procedure TestDecodePalette1Bit;
    [Test]
    procedure TestDecodePalette4Bit;
    [Test]
    procedure TestPaletteIndexBeyondThePaletteIsBlack;

    // Transparency
    [Test]
    procedure TestDecodeGrayTransparentColor;
    [Test]
    procedure TestDecodeGray2BitTransparentColor;
    [Test]
    procedure TestDecodeGray16TransparentColor;
    [Test]
    procedure TestDecodeRgbTransparentColor;
    [Test]
    procedure TestDecodePaletteTransparency;

    // Palette images without expanding them
    [Test]
    procedure TestDecodeIndexed8Bit;
    [Test]
    procedure TestDecodeIndexed4Bit;
    [Test]
    procedure TestDecodeIndexedOfAnRgbImageReturnsUnsupported;
    [Test]
    procedure TestDecodeIndexedWithoutPaletteBufferReturnsInvalidArgument;

    // Chunks
    [Test]
    procedure TestOffsetsOfTheGrAbChunk;
    [Test]
    procedure TestOffsetsAfterTheImageData;
    [Test]
    procedure TestAncillaryChunksAreSkipped;
    [Test]
    procedure TestUnknownCriticalChunkReturnsUnsupported;
    [Test]
    procedure TestImageDataSplitInSeveralChunks;

    // Interlacing
    [Test]
    procedure TestDecodeAdam7ByHand;
    [Test]
    [TestCase('UnPixel', '1,1')]
    [TestCase('Riga', '11,1')]
    [TestCase('Colonna', '1,11')]
    [TestCase('Otto', '8,8')]
    [TestCase('Nove', '9,9')]
    [TestCase('Irregolare', '13,7')]
    procedure TestDecodeAdam7(AWidth, AHeight: Integer);

    // Damaged files
    [Test]
    procedure TestBadSignatureReturnsData;
    [Test]
    procedure TestEveryTruncationReturnsTruncated;
    [Test]
    procedure TestGetInfoOfTruncatedFileKeepsWorkingAfterTheHeader;
    [Test]
    procedure TestBadCrcOfTheHeader;
    [Test]
    procedure TestBadCrcOfTheImageData;
    [Test]
    procedure TestBadCrcOfAnAncillaryChunk;
    [Test]
    procedure TestMissingIendReturnsTruncated;
    [Test]
    procedure TestFileWithoutImageDataReturnsData;
    [Test]
    procedure TestCorruptedZlibStreamReturnsData;
    [Test]
    procedure TestBadZlibChecksumReturnsData;
    [Test]
    procedure TestTooMuchPixelDataReturnsData;
    [Test]
    procedure TestTooLittlePixelDataReturnsData;
    [Test]
    procedure TestImageDataEndingInTheMiddleOfTheStreamReturnsTruncated;
    [Test]
    procedure TestPaletteImageWithoutPaletteReturnsData;
    [Test]
    procedure TestPaletteChunkOfBadSizeReturnsData;
    [Test]
    procedure TestPaletteLargerThanTheDepthAllowsReturnsData;
    [Test]
    procedure TestTwoPaletteChunksReturnData;
    [Test]
    procedure TestTransparencyChunkOfBadSizeReturnsData;

    // Headers
    [Test]
    procedure TestEnormousImageIsRefused;
    [Test]
    procedure TestImageLargerThanThePixelLimitIsRefused;
    [Test]
    procedure TestWidthOfZeroReturnsData;
    [Test]
    procedure TestWidthAboveTheSpecificationReturnsData;
    [Test]
    [TestCase('RgbA4Bit', '4,2')]
    [TestCase('PaletteA16Bit', '16,3')]
    [TestCase('ProfonditaZero', '0,0')]
    [TestCase('ProfonditaTre', '3,0')]
    [TestCase('TipoColoreCinque', '8,5')]
    procedure TestInvalidDepthAndColorTypeReturnData(ABitDepth, AColorType: Integer);
    [Test]
    procedure TestInvalidInterlaceMethodReturnsData;
    [Test]
    procedure TestInvalidCompressionMethodReturnsData;
    [Test]
    procedure TestGetInfoReadsTheHeader;

    // Arguments
    [Test]
    procedure TestDecodeWithoutSourceReturnsInvalidArgument;
    [Test]
    procedure TestDecodeIntoTooSmallBufferReturnsBufferTooSmallWithInfo;

    // Encoder
    [Test]
    [TestCase('UnPixel', '1,1')]
    [TestCase('Piccola', '7,5')]
    [TestCase('Gradiente', '64,48')]
    [TestCase('Grande', '300,200')]
    procedure TestRoundTripBgra(AWidth, AHeight: Integer);
    [Test]
    [TestCase('Rumore', '0')]
    [TestCase('Gradiente', '1')]
    procedure TestRoundTripKeepsTheAlpha(AContent: Integer);
    [Test]
    procedure TestRoundTripBgr;
    [Test]
    procedure TestRoundTripBgrxIgnoresTheFourthByte;
    [Test]
    procedure TestRoundTripGray;
    [Test]
    [TestCase('Predefinito', '-1')]
    [TestCase('Memorizza', '0')]
    [TestCase('Veloce', '1')]
    [TestCase('Migliore', '9')]
    [TestCase('SottoIlMinimo', '-7')]
    [TestCase('SopraIlMassimo', '99')]
    procedure TestEveryLevelRoundTrips(ALevel: Integer);
    [Test]
    procedure TestEncodeWritesTheExpectedHeader;
    [Test]
    [TestCase('Bgra', '0')]
    [TestCase('Bgrx', '1')]
    [TestCase('Bgr', '2')]
    [TestCase('Gray', '3')]
    procedure TestEncodeBoundIsNotSmallerThanTheFile(AFormat: Integer);
    [Test]
    procedure TestEncodeBoundOfInvalidFormatIsZero;
    [Test]
    procedure TestLevelZeroStoresAndLevelNineCompresses;
    [Test]
    procedure TestEncodeHonorsAStrideWithPadding;
    [Test]
    procedure TestEncodeWithNegativeStrideWritesTheRowsUpsideDown;
    [Test]
    procedure TestEncodeIntoTooSmallBufferReturnsBufferTooSmall;
    [Test]
    procedure TestEncodeIntoExactlyTheRightBuffer;
    [Test]
    procedure TestEncodeInvalidArgumentsReturnInvalidArgument;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine, DelphiDoom.Png.Engine, DelphiDoom.Png.Crc,
  DelphiDoom.Tests.Png.Samples;

function Bytes(const AValues: array of Byte): TBytes;
begin
  Result := TPngSamples.Bytes(AValues);
end;

{ TTestPngEngine }

procedure TTestPngEngine.Setup;
begin
  FZlib := TZlibEngine.Create;
  FPng := TPngEngine.Create(FZlib);
end;

procedure TTestPngEngine.TearDown;
begin
  FPng := nil;
  FZlib := nil;
end;

function TTestPngEngine.Decode(const APng: TBytes; out AInfo: TPngInfo): TBytes;
begin
  Result := nil;
  Assert.AreEqual(DDPNG_OK, FPng.GetInfo(Pointer(APng), Length(APng), AInfo));
  SetLength(Result, AInfo.Width * AInfo.Height * 4);
  Assert.AreEqual(DDPNG_OK, FPng.Decode(Pointer(APng), Length(APng),
    Pointer(Result), Length(Result), AInfo));
end;

function TTestPngEngine.DecodeCode(const APng: TBytes): Integer;
var
  LPixels: TBytes;
  LInfo: TPngInfo;
begin
  // Large enough for every image the tests build
  SetLength(LPixels, 65536);
  Result := FPng.Decode(Pointer(APng), Length(APng), Pointer(LPixels),
    Length(LPixels), LInfo);
end;

function TTestPngEngine.InfoCode(const APng: TBytes): Integer;
var
  LInfo: TPngInfo;
begin
  Result := FPng.GetInfo(Pointer(APng), Length(APng), LInfo);
end;

function TTestPngEngine.EncodeAll(const APixels: TBytes; AWidth, AHeight,
  AFormat, ALevel: Integer): TBytes;
var
  LSize: Cardinal;
begin
  LSize := FPng.EncodeBound(AWidth, AHeight, AFormat);
  Assert.IsTrue(LSize > 0, 'EncodeBound');
  SetLength(Result, LSize);
  Assert.AreEqual(DDPNG_OK, FPng.Encode(Pointer(APixels), AWidth, AHeight,
    AFormat, 0, ALevel, Pointer(Result), LSize));
  SetLength(Result, LSize);
end;

function TTestPngEngine.MakeGradient(AWidth, AHeight,
  ABytesPerPixel: Integer): TBytes;
var
  LX: Integer;
  LY: Integer;
  LByte: Integer;
begin
  SetLength(Result, AWidth * AHeight * ABytesPerPixel);
  for LY := 0 to AHeight - 1 do
    for LX := 0 to AWidth - 1 do
      for LByte := 0 to ABytesPerPixel - 1 do
        Result[(LY * AWidth + LX) * ABytesPerPixel + LByte] :=
          Byte(LX * 3 + LY * 5 + LByte * 50);
end;

function TTestPngEngine.MakeInterlaced(const APixels: TBytes; AWidth, AHeight,
  ABytesPerPixel: Integer): TBytes;
const
  START_X: array[0..6] of Integer = (0, 4, 0, 2, 0, 1, 0);
  START_Y: array[0..6] of Integer = (0, 0, 4, 0, 2, 0, 1);
  STEP_X: array[0..6] of Integer = (8, 8, 4, 4, 2, 2, 1);
  STEP_Y: array[0..6] of Integer = (8, 8, 8, 4, 4, 2, 2);
var
  LPass: Integer;
  LX: Integer;
  LY: Integer;
  LByte: Integer;
  LCount: Integer;
begin
  // The scanlines of the seven passes, each with the filter "none"
  Result := nil;
  SetLength(Result, AWidth * AHeight * ABytesPerPixel + 7 * AHeight + 16);
  LCount := 0;
  for LPass := 0 to 6 do
  begin
    LY := START_Y[LPass];
    while LY < AHeight do
    begin
      if START_X[LPass] < AWidth then
      begin
        Result[LCount] := 0;
        Inc(LCount);
        LX := START_X[LPass];
        while LX < AWidth do
        begin
          for LByte := 0 to ABytesPerPixel - 1 do
          begin
            Result[LCount] := APixels[(LY * AWidth + LX) * ABytesPerPixel + LByte];
            Inc(LCount);
          end;
          Inc(LX, STEP_X[LPass]);
        end;
      end;
      Inc(LY, STEP_Y[LPass]);
    end;
  end;
  SetLength(Result, LCount);
end;

function TTestPngEngine.FilteredNoise(AWidth, AHeight, ABytesPerPixel,
  ASeed: Integer): TBytes;
var
  LRow: Integer;
  LRowBytes: Integer;
  LNoise: TBytes;
begin
  // Scanlines with the filter "none" and random content
  LRowBytes := AWidth * ABytesPerPixel;
  LNoise := TPngSamples.Noise(LRowBytes * AHeight, ASeed);
  SetLength(Result, AHeight * (LRowBytes + 1));
  for LRow := 0 to AHeight - 1 do
  begin
    Result[LRow * (LRowBytes + 1)] := 0;
    Move(LNoise[LRow * LRowBytes], Result[LRow * (LRowBytes + 1) + 1], LRowBytes);
  end;
end;

function TTestPngEngine.RgbaToBgra(const ARgba: TBytes): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ARgba));
  for LIndex := 0 to (Length(ARgba) div 4) - 1 do
  begin
    Result[LIndex * 4] := ARgba[LIndex * 4 + 2];
    Result[LIndex * 4 + 1] := ARgba[LIndex * 4 + 1];
    Result[LIndex * 4 + 2] := ARgba[LIndex * 4];
    Result[LIndex * 4 + 3] := ARgba[LIndex * 4 + 3];
  end;
end;

function TTestPngEngine.GrayToBgra(const AGrays: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AGrays) * 4);
  for LIndex := 0 to High(AGrays) do
  begin
    Result[LIndex * 4] := AGrays[LIndex];
    Result[LIndex * 4 + 1] := AGrays[LIndex];
    Result[LIndex * 4 + 2] := AGrays[LIndex];
    Result[LIndex * 4 + 3] := 255;
  end;
end;

function TTestPngEngine.CustomHeader(AWidth, AHeight, ABitDepth, AColorType,
  ACompression, AFilter, AInterlace: Integer): TBytes;
begin
  // Sizes below 256: the high bytes are zero
  Result := TPngSamples.Chunk('IHDR', Bytes([0, 0, 0, Byte(AWidth), 0, 0, 0,
    Byte(AHeight), Byte(ABitDepth), Byte(AColorType), Byte(ACompression),
    Byte(AFilter), Byte(AInterlace)]));
end;

function TTestPngEngine.GrayImage(AWidth, AHeight: Integer; const ARaw: TBytes;
  const AExtraChunks: TBytes): TBytes;
begin
  Result := TPngSamples.Assemble(FZlib, AWidth, AHeight, 8, DDPNG_COLOR_GRAY,
    0, AExtraChunks, ARaw);
end;

procedure TTestPngEngine.AssertBytes(const AExpected, AActual: TBytes;
  const AMessage: string);
var
  LIndex: Integer;
begin
  Assert.AreEqual(Length(AExpected), Length(AActual), AMessage + ' (length)');
  for LIndex := 0 to High(AExpected) do
    if AExpected[LIndex] <> AActual[LIndex] then
      Assert.Fail(Format('%s: byte %d should be %d and is %d',
        [AMessage, LIndex, AExpected[LIndex], AActual[LIndex]]));
end;

procedure TTestPngEngine.AssertDecodes(const APng, AExpectedBgra: TBytes);
var
  LInfo: TPngInfo;
begin
  AssertBytes(AExpectedBgra, Decode(APng, LInfo));
end;

procedure TTestPngEngine.TestCreateWithoutZlibRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TPngEngine.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestPngEngine.TestVersion;
begin
  Assert.AreEqual('DDPng 1.0', string(AnsiString(FPng.GetVersion)));
end;

procedure TTestPngEngine.TestCrcOfTheCheckString;
var
  LCheck: TBytes;
begin
  // The standard check value of CRC-32 for the ASCII text "123456789"
  LCheck := TEncoding.ASCII.GetBytes('123456789');
  Assert.AreEqual(Cardinal($CBF43926),
    TPngCrc.Compute(@LCheck[0], Length(LCheck)));
end;

procedure TTestPngEngine.TestCrcOfTheIendType;
var
  LType: TBytes;
begin
  // The CRC at the end of every IEND chunk
  LType := TEncoding.ASCII.GetBytes('IEND');
  Assert.AreEqual(Cardinal($AE426082), TPngCrc.Compute(@LType[0], Length(LType)));
end;

procedure TTestPngEngine.TestCrcCanBeContinued;
var
  LText: TBytes;
  LCrc: Cardinal;
begin
  LText := TEncoding.ASCII.GetBytes('123456789');
  LCrc := TPngCrc.Update(0, @LText[0], 4);
  LCrc := TPngCrc.Update(LCrc, @LText[4], 5);
  Assert.AreEqual(Cardinal($CBF43926), LCrc);
end;

procedure TTestPngEngine.TestDecodeFilterSubUpAndAverage;
begin
  // 4x3 gray image:  10 20 30 40 / 15 25 35 45 / 12 22 32 42
  // row 0 with Sub, row 1 with Up, row 2 with Average
  AssertDecodes(
    GrayImage(4, 3, Bytes([
      1, 10, 10, 10, 10,
      2, 5, 5, 5, 5,
      3, 5, 4, 4, 4])),
    GrayToBgra([10, 20, 30, 40, 15, 25, 35, 45, 12, 22, 32, 42]));
end;

procedure TTestPngEngine.TestDecodeFilterPaeth;
begin
  // Row 0: 10 10 10 10 without filter. Row 1 with Paeth: the first pixel
  // takes the pixel above (10), the others the pixel on the left
  AssertDecodes(
    GrayImage(4, 2, Bytes([
      0, 10, 10, 10, 10,
      4, 40, 10, 10, 10])),
    GrayToBgra([10, 10, 10, 10, 50, 60, 70, 80]));
end;

procedure TTestPngEngine.TestDecodeFilterSubWithThreeBytesPerPixel;
begin
  // 2x1 RGB image, Sub: the left neighbour is three bytes back
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 2, 1, 8, DDPNG_COLOR_RGB, 0, nil,
      Bytes([1, 10, 20, 30, 5, 5, 5])),
    Bytes([30, 20, 10, 255, 35, 25, 15, 255]));
end;

procedure TTestPngEngine.TestDecodeInvalidFilterTypeReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(GrayImage(1, 1, Bytes([5, 0]))));
end;

procedure TTestPngEngine.TestDecodeGray1Bit;
begin
  // 10100101
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 8, 1, 1, DDPNG_COLOR_GRAY, 0, nil,
      Bytes([0, $A5])),
    GrayToBgra([255, 0, 255, 0, 0, 255, 0, 255]));
end;

procedure TTestPngEngine.TestDecodeGray2Bit;
begin
  // 00 01 10 11 -> 0, 85, 170, 255
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 4, 1, 2, DDPNG_COLOR_GRAY, 0, nil,
      Bytes([0, $1B])),
    GrayToBgra([0, 85, 170, 255]));
end;

procedure TTestPngEngine.TestDecodeGray4Bit;
begin
  // 8 and 4 out of 15
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 2, 1, 4, DDPNG_COLOR_GRAY, 0, nil,
      Bytes([0, $84])),
    GrayToBgra([136, 68]));
end;

procedure TTestPngEngine.TestDecodeGray16Bit;
begin
  // The high byte of each sample
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 2, 1, 16, DDPNG_COLOR_GRAY, 0, nil,
      Bytes([0, $12, $34, $AB, $CD])),
    GrayToBgra([$12, $AB]));
end;

procedure TTestPngEngine.TestDecodeSubByteRowsArePadded;
begin
  // 3 pixels of 1 bit: each row takes a whole byte, the low 5 bits are unused
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 3, 2, 1, DDPNG_COLOR_GRAY, 0, nil,
      Bytes([0, $A0, 0, $5F])),
    GrayToBgra([255, 0, 255, 0, 255, 0]));
end;

procedure TTestPngEngine.TestDecodeGrayAlpha8Bit;
begin
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 2, 1, 8, DDPNG_COLOR_GRAY_ALPHA, 0, nil,
      Bytes([0, $10, $20, $30, $40])),
    Bytes([$10, $10, $10, $20, $30, $30, $30, $40]));
end;

procedure TTestPngEngine.TestDecodeGrayAlpha16Bit;
begin
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 1, 1, 16, DDPNG_COLOR_GRAY_ALPHA, 0, nil,
      Bytes([0, $11, $11, $22, $22])),
    Bytes([$11, $11, $11, $22]));
end;

procedure TTestPngEngine.TestDecodeRgb16Bit;
begin
  // R, G, B = 11, 22, 33 in the high bytes; the result is B, G, R, A
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 1, 1, 16, DDPNG_COLOR_RGB, 0, nil,
      Bytes([0, $11, $00, $22, $00, $33, $00])),
    Bytes([$33, $22, $11, 255]));
end;

procedure TTestPngEngine.TestDecodeRgba8Bit;
begin
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 1, 1, 8, DDPNG_COLOR_RGBA, 0, nil,
      Bytes([0, 1, 2, 3, 4])),
    Bytes([3, 2, 1, 4]));
end;

procedure TTestPngEngine.TestDecodeRgba16Bit;
begin
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 1, 1, 16, DDPNG_COLOR_RGBA, 0, nil,
      Bytes([0, 1, $FF, 2, $FF, 3, $FF, 4, $FF])),
    Bytes([3, 2, 1, 4]));
end;

procedure TTestPngEngine.TestDecodePalette1Bit;
begin
  // Palette: red, blue. Pixels: 0 1 0
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 3, 1, 1, DDPNG_COLOR_PALETTE, 0,
      TPngSamples.Chunk('PLTE', Bytes([255, 0, 0, 0, 0, 255])),
      Bytes([0, $40])),
    Bytes([0, 0, 255, 255, 255, 0, 0, 255, 0, 0, 255, 255]));
end;

procedure TTestPngEngine.TestDecodePalette4Bit;
begin
  // Palette: red, green, blue. Pixels: 0 1 2 (two per byte)
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 3, 1, 4, DDPNG_COLOR_PALETTE, 0,
      TPngSamples.Chunk('PLTE', Bytes([255, 0, 0, 0, 255, 0, 0, 0, 255])),
      Bytes([0, $01, $20])),
    Bytes([0, 0, 255, 255, 0, 255, 0, 255, 255, 0, 0, 255]));
end;

procedure TTestPngEngine.TestPaletteIndexBeyondThePaletteIsBlack;
begin
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 2, 1, 8, DDPNG_COLOR_PALETTE, 0,
      TPngSamples.Chunk('PLTE', Bytes([255, 0, 0, 0, 255, 0, 0, 0, 255])),
      Bytes([0, 0, 5])),
    Bytes([0, 0, 255, 255, 0, 0, 0, 255]));
end;

procedure TTestPngEngine.TestDecodeGrayTransparentColor;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // The sample 20 is transparent
  LPng := GrayImage(3, 1, Bytes([0, 10, 20, 30]),
    TPngSamples.Chunk('tRNS', Bytes([0, 20])));
  AssertBytes(Bytes([10, 10, 10, 255, 20, 20, 20, 0, 30, 30, 30, 255]),
    Decode(LPng, LInfo));
  Assert.AreEqual(1, LInfo.HasAlpha);
  Assert.AreEqual(1, LInfo.HasTransparentColor);
  Assert.AreEqual(Cardinal($141414), LInfo.TransparentColor);
end;

procedure TTestPngEngine.TestDecodeGray2BitTransparentColor;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // The key is compared with the samples before they are scaled: 2 -> 170
  LPng := TPngSamples.Assemble(FZlib, 4, 1, 2, DDPNG_COLOR_GRAY, 0,
    TPngSamples.Chunk('tRNS', Bytes([0, 2])), Bytes([0, $1B]));
  AssertBytes(Bytes([0, 0, 0, 255, 85, 85, 85, 255, 170, 170, 170, 0,
    255, 255, 255, 255]), Decode(LPng, LInfo));
  Assert.AreEqual(Cardinal($AAAAAA), LInfo.TransparentColor);
end;

procedure TTestPngEngine.TestDecodeGray16TransparentColor;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // The whole 16 bit sample must match: $1234 is transparent, $1235 is not
  LPng := TPngSamples.Assemble(FZlib, 2, 1, 16, DDPNG_COLOR_GRAY, 0,
    TPngSamples.Chunk('tRNS', Bytes([$12, $34])),
    Bytes([0, $12, $34, $12, $35]));
  AssertBytes(Bytes([$12, $12, $12, 0, $12, $12, $12, 255]),
    Decode(LPng, LInfo));
end;

procedure TTestPngEngine.TestDecodeRgbTransparentColor;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // R, G, B = 10, 20, 30 is transparent; 10, 20, 31 is not
  LPng := TPngSamples.Assemble(FZlib, 2, 1, 8, DDPNG_COLOR_RGB, 0,
    TPngSamples.Chunk('tRNS', Bytes([0, 10, 0, 20, 0, 30])),
    Bytes([0, 10, 20, 30, 10, 20, 31]));
  AssertBytes(Bytes([30, 20, 10, 0, 31, 20, 10, 255]), Decode(LPng, LInfo));
  Assert.AreEqual(1, LInfo.HasTransparentColor);
  Assert.AreEqual(Cardinal($0A141E), LInfo.TransparentColor);
end;

procedure TTestPngEngine.TestDecodePaletteTransparency;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // Entry 0 fully transparent, entry 1 half, entry 2 (not in tRNS) opaque
  LPng := TPngSamples.Assemble(FZlib, 3, 1, 8, DDPNG_COLOR_PALETTE, 0,
    TPngSamples.Concat([
      TPngSamples.Chunk('PLTE', Bytes([255, 0, 0, 0, 255, 0, 0, 0, 255])),
      TPngSamples.Chunk('tRNS', Bytes([0, $80]))]),
    Bytes([0, 0, 1, 2]));
  AssertBytes(Bytes([0, 0, 255, 0, 0, 255, 0, $80, 255, 0, 0, 255]),
    Decode(LPng, LInfo));
  Assert.AreEqual(1, LInfo.HasAlpha);
  Assert.AreEqual(1, LInfo.HasTransparentColor);
  Assert.AreEqual(Cardinal($FF0000), LInfo.TransparentColor);
  Assert.AreEqual(3, LInfo.PaletteCount);
end;

procedure TTestPngEngine.TestDecodeIndexed8Bit;
var
  LPng: TBytes;
  LPixels: TBytes;
  LPalette: TBytes;
  LInfo: TPngInfo;
begin
  LPng := TPngSamples.Assemble(FZlib, 3, 1, 8, DDPNG_COLOR_PALETTE, 0,
    TPngSamples.Concat([
      TPngSamples.Chunk('PLTE',
        Bytes([10, 20, 30, 40, 50, 60, 70, 80, 90])),
      TPngSamples.Chunk('tRNS', Bytes([0]))]),
    Bytes([0, 2, 0, 1]));

  SetLength(LPixels, 3);
  SetLength(LPalette, DDPNG_PALETTE_BYTES);
  Assert.AreEqual(DDPNG_OK, FPng.DecodeIndexed(Pointer(LPng), Length(LPng),
    Pointer(LPixels), Length(LPixels), Pointer(LPalette), LInfo));

  AssertBytes(Bytes([2, 0, 1]), LPixels, 'indices');
  Assert.AreEqual(3, LInfo.PaletteCount);
  // B, G, R, A of the entries; the alpha of entry 0 comes from tRNS
  Assert.AreEqual(Integer($1E), Integer(LPalette[0]));
  Assert.AreEqual(Integer($14), Integer(LPalette[1]));
  Assert.AreEqual(Integer($0A), Integer(LPalette[2]));
  Assert.AreEqual(Integer(0), Integer(LPalette[3]));
  Assert.AreEqual(Integer($3C), Integer(LPalette[4]));
  Assert.AreEqual(Integer($32), Integer(LPalette[5]));
  Assert.AreEqual(Integer($28), Integer(LPalette[6]));
  Assert.AreEqual(Integer(255), Integer(LPalette[7]));
  Assert.AreEqual(Integer($5A), Integer(LPalette[8]));
  // Entries after the PLTE chunk: opaque black
  Assert.AreEqual(Integer(0), Integer(LPalette[12]));
  Assert.AreEqual(Integer(255), Integer(LPalette[15]));
  Assert.AreEqual(Integer(255), Integer(LPalette[DDPNG_PALETTE_BYTES - 1]));
end;

procedure TTestPngEngine.TestDecodeIndexed4Bit;
var
  LPng: TBytes;
  LPixels: TBytes;
  LPalette: TBytes;
  LInfo: TPngInfo;
begin
  // Indices 0, 1, 2 packed two per byte
  LPng := TPngSamples.Assemble(FZlib, 3, 1, 4, DDPNG_COLOR_PALETTE, 0,
    TPngSamples.Chunk('PLTE', Bytes([255, 0, 0, 0, 255, 0, 0, 0, 255])),
    Bytes([0, $01, $20]));

  SetLength(LPixels, 3);
  SetLength(LPalette, DDPNG_PALETTE_BYTES);
  Assert.AreEqual(DDPNG_OK, FPng.DecodeIndexed(Pointer(LPng), Length(LPng),
    Pointer(LPixels), Length(LPixels), Pointer(LPalette), LInfo));
  AssertBytes(Bytes([0, 1, 2]), LPixels);
end;

procedure TTestPngEngine.TestDecodeIndexedOfAnRgbImageReturnsUnsupported;
var
  LPng: TBytes;
  LPixels: TBytes;
  LPalette: TBytes;
  LInfo: TPngInfo;
begin
  LPng := TPngSamples.Assemble(FZlib, 1, 1, 8, DDPNG_COLOR_RGB, 0, nil,
    Bytes([0, 1, 2, 3]));
  SetLength(LPixels, 16);
  SetLength(LPalette, DDPNG_PALETTE_BYTES);
  Assert.AreEqual(DDPNG_ERR_UNSUPPORTED, FPng.DecodeIndexed(Pointer(LPng),
    Length(LPng), Pointer(LPixels), Length(LPixels), Pointer(LPalette), LInfo));
  // The information tells what the image is
  Assert.AreEqual(DDPNG_COLOR_RGB, LInfo.ColorType);
end;

procedure TTestPngEngine.TestDecodeIndexedWithoutPaletteBufferReturnsInvalidArgument;
var
  LPng: TBytes;
  LPixels: TBytes;
  LInfo: TPngInfo;
begin
  LPng := TPngSamples.Assemble(FZlib, 1, 1, 8, DDPNG_COLOR_PALETTE, 0,
    TPngSamples.Chunk('PLTE', Bytes([1, 2, 3])), Bytes([0, 0]));
  SetLength(LPixels, 4);
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.DecodeIndexed(Pointer(LPng),
    Length(LPng), Pointer(LPixels), Length(LPixels), nil, LInfo));
end;

procedure TTestPngEngine.TestOffsetsOfTheGrAbChunk;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // x = 5, y = -3 (signed, big endian)
  LPng := GrayImage(1, 1, Bytes([0, $7F]),
    TPngSamples.Chunk('grAb', Bytes([0, 0, 0, 5, $FF, $FF, $FF, $FD])));

  Assert.AreEqual(DDPNG_OK, FPng.GetInfo(Pointer(LPng), Length(LPng), LInfo));
  Assert.AreEqual(5, LInfo.OffsetX);
  Assert.AreEqual(-3, LInfo.OffsetY);

  Decode(LPng, LInfo);
  Assert.AreEqual(5, LInfo.OffsetX);
  Assert.AreEqual(-3, LInfo.OffsetY);
end;

procedure TTestPngEngine.TestOffsetsAfterTheImageData;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // A private chunk is allowed after IDAT
  LPng := TPngSamples.AssembleWithChunks(1, 1, 8, DDPNG_COLOR_GRAY, 0, nil,
    TPngSamples.Concat([
      TPngSamples.Chunk('IDAT', TPngSamples.Compress(FZlib, Bytes([0, $7F]))),
      TPngSamples.Chunk('grAb', Bytes([0, 0, 0, 7, 0, 0, 0, 9]))]),
    True);

  Assert.AreEqual(DDPNG_OK, FPng.GetInfo(Pointer(LPng), Length(LPng), LInfo));
  Assert.AreEqual(7, LInfo.OffsetX);
  Assert.AreEqual(9, LInfo.OffsetY);

  Decode(LPng, LInfo);
  Assert.AreEqual(7, LInfo.OffsetX);
  Assert.AreEqual(9, LInfo.OffsetY);
end;

procedure TTestPngEngine.TestAncillaryChunksAreSkipped;
begin
  AssertDecodes(
    GrayImage(1, 1, Bytes([0, $7F]), TPngSamples.Concat([
      TPngSamples.Chunk('gAMA', Bytes([0, 1, $86, $A0])),
      TPngSamples.Chunk('tEXt', TEncoding.ASCII.GetBytes('Comment' + #0 + 'hi')),
      TPngSamples.Chunk('teSt', nil)])),
    GrayToBgra([$7F]));
end;

procedure TTestPngEngine.TestUnknownCriticalChunkReturnsUnsupported;
begin
  // The first letter is upper case: a decoder that does not know the chunk
  // cannot decode the image
  Assert.AreEqual(DDPNG_ERR_UNSUPPORTED, DecodeCode(
    GrayImage(1, 1, Bytes([0, $7F]), TPngSamples.Chunk('ZZZZ', nil))));
end;

procedure TTestPngEngine.TestImageDataSplitInSeveralChunks;
var
  LRaw: TBytes;
  LStream: TBytes;
  LChunks: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // 4x4 gray image
  LRaw := FilteredNoise(4, 4, 1, 21);
  LStream := TPngSamples.Compress(FZlib, LRaw);
  Assert.IsTrue(Length(LStream) > 6);

  // Three pieces, with an empty IDAT chunk between the first two
  LChunks := TPngSamples.Concat([
    TPngSamples.Chunk('IDAT', TPngSamples.Slice(LStream, 0, 3)),
    TPngSamples.Chunk('IDAT', nil),
    TPngSamples.Chunk('IDAT', TPngSamples.Slice(LStream, 3, Length(LStream) - 2)),
    TPngSamples.Chunk('IDAT', TPngSamples.Slice(LStream, Length(LStream) - 2,
      Length(LStream)))]);
  LPng := TPngSamples.AssembleWithChunks(4, 4, 8, DDPNG_COLOR_GRAY, 0, nil,
    LChunks, True);

  // The expectation is the same data in a single IDAT chunk
  AssertBytes(Decode(TPngSamples.Assemble(FZlib, 4, 4, 8, DDPNG_COLOR_GRAY, 0,
    nil, LRaw), LInfo), Decode(LPng, LInfo));
end;

procedure TTestPngEngine.TestDecodeAdam7ByHand;
begin
  // 3x3 gray image  1 2 3 / 11 12 13 / 21 22 23  in the seven passes:
  // 1: (0,0)   2: nothing   3: nothing   4: (2,0)
  // 5: (0,2) (2,2)   6: (1,0) and (1,2)   7: the row 1
  AssertDecodes(
    TPngSamples.Assemble(FZlib, 3, 3, 8, DDPNG_COLOR_GRAY, 1, nil,
      Bytes([
        0, 1,
        0, 3,
        0, 21, 23,
        0, 2,
        0, 22,
        0, 11, 12, 13])),
    GrayToBgra([1, 2, 3, 11, 12, 13, 21, 22, 23]));
end;

procedure TTestPngEngine.TestDecodeAdam7(AWidth, AHeight: Integer);
var
  LRgba: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  LRgba := TPngSamples.Noise(AWidth * AHeight * 4, AWidth * 100 + AHeight);
  LPng := TPngSamples.Assemble(FZlib, AWidth, AHeight, 8, DDPNG_COLOR_RGBA, 1,
    nil, MakeInterlaced(LRgba, AWidth, AHeight, 4));

  AssertBytes(RgbaToBgra(LRgba), Decode(LPng, LInfo));
  Assert.AreEqual(1, LInfo.Interlaced);
end;

procedure TTestPngEngine.TestBadSignatureReturnsData;
var
  LPng: TBytes;
begin
  LPng := GrayImage(1, 1, Bytes([0, 1]));
  LPng[1] := Ord('X');
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(LPng));
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(LPng));
  // Text that is not a PNG file at all
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(TEncoding.ASCII.GetBytes(
    'This is not a PNG file, it is a sentence')));
end;

procedure TTestPngEngine.TestEveryTruncationReturnsTruncated;
var
  LPng: TBytes;
  LLength: Integer;
begin
  LPng := TPngSamples.Assemble(FZlib, 6, 4, 8, DDPNG_COLOR_RGB, 0, nil,
    FilteredNoise(6, 4, 3, 1));
  Assert.AreEqual(DDPNG_OK, DecodeCode(LPng));

  for LLength := 1 to Length(LPng) - 1 do
    Assert.AreEqual(DDPNG_ERR_TRUNCATED,
      DecodeCode(TPngSamples.Slice(LPng, 0, LLength)),
      Format('file cut to %d bytes of %d', [LLength, Length(LPng)]));
end;

procedure TTestPngEngine.TestGetInfoOfTruncatedFileKeepsWorkingAfterTheHeader;
var
  LPng: TBytes;
  LLength: Integer;
  LInfo: TPngInfo;
begin
  LPng := GrayImage(5, 2, TPngSamples.Noise(12));

  // The signature and the header are the first 8 + 25 bytes
  for LLength := 1 to 8 + 25 - 1 do
    Assert.AreEqual(DDPNG_ERR_TRUNCATED,
      InfoCode(TPngSamples.Slice(LPng, 0, LLength)),
      Format('file cut to %d bytes', [LLength]));

  for LLength := 8 + 25 to Length(LPng) do
  begin
    Assert.AreEqual(DDPNG_OK, FPng.GetInfo(Pointer(LPng), LLength, LInfo),
      Format('file cut to %d bytes', [LLength]));
    Assert.AreEqual(5, LInfo.Width);
    Assert.AreEqual(2, LInfo.Height);
  end;
end;

procedure TTestPngEngine.TestBadCrcOfTheHeader;
var
  LPng: TBytes;
begin
  LPng := GrayImage(1, 1, Bytes([0, 1]));
  // The CRC of IHDR is the last of the 8 + 25 bytes
  LPng[8 + 25 - 1] := LPng[8 + 25 - 1] xor $01;
  Assert.AreEqual(DDPNG_ERR_CRC, InfoCode(LPng));
  Assert.AreEqual(DDPNG_ERR_CRC, DecodeCode(LPng));
end;

procedure TTestPngEngine.TestBadCrcOfTheImageData;
var
  LPng: TBytes;
begin
  LPng := GrayImage(1, 1, Bytes([0, 1]));
  // First data byte of the IDAT chunk, which follows the header
  LPng[8 + 25 + 8] := LPng[8 + 25 + 8] xor $01;
  Assert.AreEqual(DDPNG_ERR_CRC, DecodeCode(LPng));
end;

procedure TTestPngEngine.TestBadCrcOfAnAncillaryChunk;
var
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  LPng := GrayImage(1, 1, Bytes([0, 1]),
    TPngSamples.Chunk('tEXt', TEncoding.ASCII.GetBytes('abc')));
  // The tEXt chunk follows the header: 12 bytes of overhead and 3 of data
  LPng[8 + 25 + 12 + 3 - 1] := LPng[8 + 25 + 12 + 3 - 1] xor $01;
  Assert.AreEqual(DDPNG_ERR_CRC, DecodeCode(LPng));
  // The header was good: the information is still given
  Assert.AreEqual(DDPNG_OK, FPng.GetInfo(Pointer(LPng), Length(LPng), LInfo));
  Assert.AreEqual(1, LInfo.Width);
end;

procedure TTestPngEngine.TestMissingIendReturnsTruncated;
begin
  Assert.AreEqual(DDPNG_ERR_TRUNCATED, DecodeCode(
    TPngSamples.AssembleWithChunks(1, 1, 8, DDPNG_COLOR_GRAY, 0, nil,
      TPngSamples.Chunk('IDAT', TPngSamples.Compress(FZlib, Bytes([0, 1]))),
      False)));
end;

procedure TTestPngEngine.TestFileWithoutImageDataReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.AssembleWithChunks(1, 1, 8, DDPNG_COLOR_GRAY, 0, nil, nil,
      True)));
end;

procedure TTestPngEngine.TestCorruptedZlibStreamReturnsData;
begin
  // The CRC of the chunk is right: it is the zlib data that is not
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.AssembleWithChunks(1, 1, 8, DDPNG_COLOR_GRAY, 0, nil,
      TPngSamples.Chunk('IDAT', Bytes([$FF, $FF, $FF, $FF])), True)));
end;

procedure TTestPngEngine.TestBadZlibChecksumReturnsData;
var
  LStream: TBytes;
begin
  LStream := TPngSamples.Compress(FZlib, Bytes([0, 1]));
  // The last byte of the stream is part of the Adler-32 checksum
  LStream[High(LStream)] := LStream[High(LStream)] xor $FF;
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.AssembleWithChunks(1, 1, 8, DDPNG_COLOR_GRAY, 0, nil,
      TPngSamples.Chunk('IDAT', LStream), True)));
end;

procedure TTestPngEngine.TestTooMuchPixelDataReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA,
    DecodeCode(GrayImage(1, 1, Bytes([0, 1, 0, 2]))));
end;

procedure TTestPngEngine.TestTooLittlePixelDataReturnsData;
begin
  // Two rows declared, one present
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(GrayImage(1, 2, Bytes([0, 1]))));
end;

procedure TTestPngEngine.TestImageDataEndingInTheMiddleOfTheStreamReturnsTruncated;
var
  LStream: TBytes;
begin
  LStream := TPngSamples.Compress(FZlib, FilteredNoise(4, 4, 1, 22));
  // Half of the zlib stream, then IEND
  Assert.AreEqual(DDPNG_ERR_TRUNCATED, DecodeCode(
    TPngSamples.AssembleWithChunks(4, 4, 8, DDPNG_COLOR_GRAY, 0, nil,
      TPngSamples.Chunk('IDAT', TPngSamples.Slice(LStream, 0,
        Length(LStream) div 2)), True)));
end;

procedure TTestPngEngine.TestPaletteImageWithoutPaletteReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.Assemble(FZlib, 1, 1, 8, DDPNG_COLOR_PALETTE, 0, nil,
      Bytes([0, 0]))));
end;

procedure TTestPngEngine.TestPaletteChunkOfBadSizeReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.Assemble(FZlib, 1, 1, 8, DDPNG_COLOR_PALETTE, 0,
      TPngSamples.Chunk('PLTE', Bytes([1, 2, 3, 4])), Bytes([0, 0]))));
end;

procedure TTestPngEngine.TestPaletteLargerThanTheDepthAllowsReturnsData;
begin
  // 17 entries for an image of 4 bits (16 colors at most)
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.Assemble(FZlib, 1, 1, 4, DDPNG_COLOR_PALETTE, 0,
      TPngSamples.Chunk('PLTE', TPngSamples.Noise(17 * 3)), Bytes([0, 0]))));
end;

procedure TTestPngEngine.TestTwoPaletteChunksReturnData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    TPngSamples.Assemble(FZlib, 1, 1, 8, DDPNG_COLOR_PALETTE, 0,
      TPngSamples.Concat([
        TPngSamples.Chunk('PLTE', Bytes([1, 2, 3])),
        TPngSamples.Chunk('PLTE', Bytes([1, 2, 3]))]),
      Bytes([0, 0]))));
end;

procedure TTestPngEngine.TestTransparencyChunkOfBadSizeReturnsData;
begin
  // A grayscale image takes one 16 bit sample
  Assert.AreEqual(DDPNG_ERR_DATA, DecodeCode(
    GrayImage(1, 1, Bytes([0, 1]), TPngSamples.Chunk('tRNS', Bytes([0, 1, 2])))));
end;

procedure TTestPngEngine.TestEnormousImageIsRefused;
var
  LPng: TBytes;
  LPixels: TBytes;
  LInfo: TPngInfo;
begin
  // Only the header: the declared size alone is enough to refuse the file,
  // before any memory is allocated for the pixels
  LPng := TPngSamples.Concat([TPngSamples.Signature,
    TPngSamples.Header(100000, 100000, 8, DDPNG_COLOR_RGB, 0),
    TPngSamples.Chunk('IEND', nil)]);
  SetLength(LPixels, 16);
  Assert.AreEqual(DDPNG_ERR_TOO_LARGE, InfoCode(LPng));
  Assert.AreEqual(DDPNG_ERR_TOO_LARGE, FPng.Decode(Pointer(LPng), Length(LPng),
    Pointer(LPixels), Length(LPixels), LInfo));

  LPng := TPngSamples.Concat([TPngSamples.Signature,
    TPngSamples.Header($7FFFFFFF, $7FFFFFFF, 8, DDPNG_COLOR_RGBA, 1),
    TPngSamples.Chunk('IEND', nil)]);
  Assert.AreEqual(DDPNG_ERR_TOO_LARGE, InfoCode(LPng));

  LPng := TPngSamples.Concat([TPngSamples.Signature,
    TPngSamples.Header(DDPNG_MAX_DIMENSION + 1, 1, 8, DDPNG_COLOR_RGB, 0),
    TPngSamples.Chunk('IEND', nil)]);
  Assert.AreEqual(DDPNG_ERR_TOO_LARGE, InfoCode(LPng));
end;

procedure TTestPngEngine.TestImageLargerThanThePixelLimitIsRefused;
var
  LPng: TBytes;
begin
  // Each side is allowed, the area is not
  LPng := TPngSamples.Concat([TPngSamples.Signature,
    TPngSamples.Header(DDPNG_MAX_DIMENSION, DDPNG_MAX_DIMENSION, 8,
      DDPNG_COLOR_GRAY, 0),
    TPngSamples.Chunk('IEND', nil)]);
  Assert.AreEqual(DDPNG_ERR_TOO_LARGE, InfoCode(LPng));
end;

procedure TTestPngEngine.TestWidthOfZeroReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(
    TPngSamples.Concat([TPngSamples.Signature,
      TPngSamples.Header(0, 4, 8, DDPNG_COLOR_GRAY, 0),
      TPngSamples.Chunk('IEND', nil)])));
end;

procedure TTestPngEngine.TestWidthAboveTheSpecificationReturnsData;
begin
  // -1 is $FFFFFFFF in the file: more than 2^31 - 1
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(
    TPngSamples.Concat([TPngSamples.Signature,
      TPngSamples.Header(-1, 4, 8, DDPNG_COLOR_GRAY, 0),
      TPngSamples.Chunk('IEND', nil)])));
end;

procedure TTestPngEngine.TestInvalidDepthAndColorTypeReturnData(ABitDepth,
  AColorType: Integer);
begin
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(
    TPngSamples.Concat([TPngSamples.Signature,
      CustomHeader(4, 4, ABitDepth, AColorType, 0, 0, 0),
      TPngSamples.Chunk('IEND', nil)])));
end;

procedure TTestPngEngine.TestInvalidInterlaceMethodReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(
    TPngSamples.Concat([TPngSamples.Signature,
      CustomHeader(4, 4, 8, DDPNG_COLOR_GRAY, 0, 0, 2),
      TPngSamples.Chunk('IEND', nil)])));
end;

procedure TTestPngEngine.TestInvalidCompressionMethodReturnsData;
begin
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(
    TPngSamples.Concat([TPngSamples.Signature,
      CustomHeader(4, 4, 8, DDPNG_COLOR_GRAY, 1, 0, 0),
      TPngSamples.Chunk('IEND', nil)])));
  Assert.AreEqual(DDPNG_ERR_DATA, InfoCode(
    TPngSamples.Concat([TPngSamples.Signature,
      CustomHeader(4, 4, 8, DDPNG_COLOR_GRAY, 0, 1, 0),
      TPngSamples.Chunk('IEND', nil)])));
end;

procedure TTestPngEngine.TestGetInfoReadsTheHeader;
var
  LInfo: TPngInfo;
  LPng: TBytes;
begin
  LPng := TPngSamples.Assemble(FZlib, 5, 3, 16, DDPNG_COLOR_RGBA, 1, nil,
    nil);
  Assert.AreEqual(DDPNG_OK, FPng.GetInfo(Pointer(LPng), Length(LPng), LInfo));
  Assert.AreEqual(5, LInfo.Width);
  Assert.AreEqual(3, LInfo.Height);
  Assert.AreEqual(16, LInfo.BitDepth);
  Assert.AreEqual(DDPNG_COLOR_RGBA, LInfo.ColorType);
  Assert.AreEqual(1, LInfo.Interlaced);
  Assert.AreEqual(1, LInfo.HasAlpha);
  Assert.AreEqual(0, LInfo.HasTransparentColor);
  Assert.AreEqual(0, LInfo.PaletteCount);
  Assert.AreEqual(0, LInfo.OffsetX);
  Assert.AreEqual(0, LInfo.OffsetY);
end;

procedure TTestPngEngine.TestDecodeWithoutSourceReturnsInvalidArgument;
var
  LPixels: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  SetLength(LPixels, 100);
  LPng := GrayImage(1, 1, Bytes([0, 1]));
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Decode(nil, 0,
    Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Decode(nil, 10,
    Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Decode(Pointer(LPng), 0,
    Pointer(LPixels), Length(LPixels), LInfo));
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Decode(Pointer(LPng),
    Length(LPng), nil, 100, LInfo));
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.GetInfo(nil, 10, LInfo));
end;

procedure TTestPngEngine.TestDecodeIntoTooSmallBufferReturnsBufferTooSmallWithInfo;
var
  LPng: TBytes;
  LPixels: TBytes;
  LInfo: TPngInfo;
begin
  LPng := GrayImage(4, 3, TPngSamples.Noise(15));
  SetLength(LPixels, 10);
  Assert.AreEqual(DDPNG_ERR_BUFFER_TOO_SMALL, FPng.Decode(Pointer(LPng),
    Length(LPng), Pointer(LPixels), Length(LPixels), LInfo));
  // The caller can size the buffer from the information
  Assert.AreEqual(4, LInfo.Width);
  Assert.AreEqual(3, LInfo.Height);
end;

procedure TTestPngEngine.TestRoundTripBgra(AWidth, AHeight: Integer);
var
  LPixels: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  // Random colors and alpha
  LPixels := TPngSamples.Noise(AWidth * AHeight * 4, AWidth + AHeight);
  LPng := EncodeAll(LPixels, AWidth, AHeight, DDPNG_FORMAT_BGRA,
    DDPNG_DEFAULT_LEVEL);

  AssertBytes(LPixels, Decode(LPng, LInfo));
  Assert.AreEqual(AWidth, LInfo.Width);
  Assert.AreEqual(AHeight, LInfo.Height);
end;

procedure TTestPngEngine.TestRoundTripKeepsTheAlpha(AContent: Integer);
var
  LPixels: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  if AContent = 0 then
    LPixels := TPngSamples.Noise(40 * 30 * 4, 99)
  else
    LPixels := MakeGradient(40, 30, 4);
  LPng := EncodeAll(LPixels, 40, 30, DDPNG_FORMAT_BGRA, 6);

  AssertBytes(LPixels, Decode(LPng, LInfo));
  Assert.AreEqual(DDPNG_COLOR_RGBA, LInfo.ColorType);
  Assert.AreEqual(1, LInfo.HasAlpha);
end;

procedure TTestPngEngine.TestRoundTripBgr;
var
  LPixels: TBytes;
  LExpected: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
  LIndex: Integer;
begin
  LPixels := TPngSamples.Noise(17 * 9 * 3, 5);
  LPng := EncodeAll(LPixels, 17, 9, DDPNG_FORMAT_BGR, 6);

  SetLength(LExpected, 17 * 9 * 4);
  for LIndex := 0 to 17 * 9 - 1 do
  begin
    LExpected[LIndex * 4] := LPixels[LIndex * 3];
    LExpected[LIndex * 4 + 1] := LPixels[LIndex * 3 + 1];
    LExpected[LIndex * 4 + 2] := LPixels[LIndex * 3 + 2];
    LExpected[LIndex * 4 + 3] := 255;
  end;
  AssertBytes(LExpected, Decode(LPng, LInfo));
  Assert.AreEqual(DDPNG_COLOR_RGB, LInfo.ColorType);
  Assert.AreEqual(0, LInfo.HasAlpha);
end;

procedure TTestPngEngine.TestRoundTripBgrxIgnoresTheFourthByte;
var
  LPixels: TBytes;
  LExpected: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
  LIndex: Integer;
begin
  // The fourth byte of the pixels is garbage, as in a screen buffer
  LPixels := TPngSamples.Noise(12 * 7 * 4, 6);
  LPng := EncodeAll(LPixels, 12, 7, DDPNG_FORMAT_BGRX, 6);

  LExpected := Copy(LPixels);
  for LIndex := 0 to 12 * 7 - 1 do
    LExpected[LIndex * 4 + 3] := 255;
  AssertBytes(LExpected, Decode(LPng, LInfo));
  Assert.AreEqual(DDPNG_COLOR_RGB, LInfo.ColorType);
end;

procedure TTestPngEngine.TestRoundTripGray;
var
  LPixels: TBytes;
  LExpected: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
  LIndex: Integer;
begin
  LPixels := TPngSamples.Noise(23 * 5, 7);
  LPng := EncodeAll(LPixels, 23, 5, DDPNG_FORMAT_GRAY, 6);

  SetLength(LExpected, 23 * 5 * 4);
  for LIndex := 0 to 23 * 5 - 1 do
  begin
    LExpected[LIndex * 4] := LPixels[LIndex];
    LExpected[LIndex * 4 + 1] := LPixels[LIndex];
    LExpected[LIndex * 4 + 2] := LPixels[LIndex];
    LExpected[LIndex * 4 + 3] := 255;
  end;
  AssertBytes(LExpected, Decode(LPng, LInfo));
  Assert.AreEqual(DDPNG_COLOR_GRAY, LInfo.ColorType);
end;

procedure TTestPngEngine.TestEveryLevelRoundTrips(ALevel: Integer);
var
  LPixels: TBytes;
  LPng: TBytes;
  LInfo: TPngInfo;
begin
  LPixels := MakeGradient(50, 40, 4);
  LPng := EncodeAll(LPixels, 50, 40, DDPNG_FORMAT_BGRA, ALevel);
  AssertBytes(LPixels, Decode(LPng, LInfo));
end;

procedure TTestPngEngine.TestEncodeWritesTheExpectedHeader;
var
  LPng: TBytes;
begin
  LPng := EncodeAll(MakeGradient(9, 4, 3), 9, 4, DDPNG_FORMAT_BGR, 6);

  AssertBytes(TPngSamples.Signature, TPngSamples.Slice(LPng, 0, 8), 'signature');
  AssertBytes(TPngSamples.Header(9, 4, 8, DDPNG_COLOR_RGB, 0),
    TPngSamples.Slice(LPng, 8, 8 + 25), 'IHDR');
  // The file ends with the IEND chunk
  AssertBytes(Bytes([0, 0, 0, 0, $49, $45, $4E, $44, $AE, $42, $60, $82]),
    TPngSamples.Slice(LPng, Length(LPng) - 12, Length(LPng)), 'IEND');
end;

procedure TTestPngEngine.TestEncodeBoundIsNotSmallerThanTheFile(AFormat: Integer);
const
  LEVELS: array[0..2] of Integer = (0, 1, 9);
var
  LBytesPerPixel: Integer;
  LPixels: TBytes;
  LBound: Cardinal;
  LIndex: Integer;
begin
  case AFormat of
    DDPNG_FORMAT_BGRA, DDPNG_FORMAT_BGRX: LBytesPerPixel := 4;
    DDPNG_FORMAT_BGR:                      LBytesPerPixel := 3;
  else
    LBytesPerPixel := 1;
  end;

  // Noise does not compress: the worst case, at the lowest and highest level
  LPixels := TPngSamples.Noise(64 * 32 * LBytesPerPixel, 8);
  LBound := FPng.EncodeBound(64, 32, AFormat);
  for LIndex := 0 to High(LEVELS) do
    Assert.IsTrue(Cardinal(Length(EncodeAll(LPixels, 64, 32, AFormat,
      LEVELS[LIndex]))) <= LBound, Format('level %d', [LEVELS[LIndex]]));
end;

procedure TTestPngEngine.TestEncodeBoundOfInvalidFormatIsZero;
begin
  Assert.AreEqual(Cardinal(0), FPng.EncodeBound(0, 10, DDPNG_FORMAT_BGRA));
  Assert.AreEqual(Cardinal(0), FPng.EncodeBound(10, 0, DDPNG_FORMAT_BGRA));
  Assert.AreEqual(Cardinal(0), FPng.EncodeBound(10, 10, 9));
  Assert.AreEqual(Cardinal(0), FPng.EncodeBound(10, 10, -1));
  Assert.AreEqual(Cardinal(0),
    FPng.EncodeBound(DDPNG_MAX_DIMENSION + 1, 10, DDPNG_FORMAT_BGRA));
  Assert.AreEqual(Cardinal(0), FPng.EncodeBound(DDPNG_MAX_DIMENSION,
    DDPNG_MAX_DIMENSION, DDPNG_FORMAT_BGRA));
end;

procedure TTestPngEngine.TestLevelZeroStoresAndLevelNineCompresses;
var
  LPixels: TBytes;
  LIndex: Integer;
begin
  // A solid image compresses very well, and level 0 does not compress
  SetLength(LPixels, 64 * 64 * 4);
  for LIndex := 0 to High(LPixels) do
    LPixels[LIndex] := Byte(LIndex and 3);

  Assert.IsTrue(Length(EncodeAll(LPixels, 64, 64, DDPNG_FORMAT_BGRA, 0)) >
    64 * 64 * 4);
  Assert.IsTrue(Length(EncodeAll(LPixels, 64, 64, DDPNG_FORMAT_BGRA, 9)) <
    1000);
end;

procedure TTestPngEngine.TestEncodeHonorsAStrideWithPadding;
var
  LTight: TBytes;
  LPadded: TBytes;
  LExpected: TBytes;
  LDest: TBytes;
  LSize: Cardinal;
  LInfo: TPngInfo;
  LRow: Integer;
begin
  // 5x4 BGRA, rows 8 bytes longer than needed and filled with a marker
  LTight := TPngSamples.Noise(5 * 4 * 4, 11);
  SetLength(LPadded, 4 * (5 * 4 + 8));
  FillChar(LPadded[0], Length(LPadded), $EE);
  for LRow := 0 to 3 do
    Move(LTight[LRow * 20], LPadded[LRow * 28], 20);

  LSize := FPng.EncodeBound(5, 4, DDPNG_FORMAT_BGRA);
  SetLength(LDest, LSize);
  Assert.AreEqual(DDPNG_OK, FPng.Encode(Pointer(LPadded), 5, 4,
    DDPNG_FORMAT_BGRA, 28, 6, Pointer(LDest), LSize));
  SetLength(LDest, LSize);

  LExpected := LTight;
  AssertBytes(LExpected, Decode(LDest, LInfo));
end;

procedure TTestPngEngine.TestEncodeWithNegativeStrideWritesTheRowsUpsideDown;
var
  LTopDown: TBytes;
  LBottomUp: TBytes;
  LDest: TBytes;
  LSize: Cardinal;
  LInfo: TPngInfo;
  LRow: Integer;
begin
  // 6x5 BGRA kept bottom-up in memory, as OpenGL returns it: the pointer is
  // the first row to write, which is the last row in memory
  LTopDown := TPngSamples.Noise(6 * 5 * 4, 12);
  SetLength(LBottomUp, Length(LTopDown));
  for LRow := 0 to 4 do
    Move(LTopDown[LRow * 24], LBottomUp[(4 - LRow) * 24], 24);

  LSize := FPng.EncodeBound(6, 5, DDPNG_FORMAT_BGRA);
  SetLength(LDest, LSize);
  Assert.AreEqual(DDPNG_OK, FPng.Encode(
    Pointer(NativeUInt(Pointer(LBottomUp)) + NativeUInt(4 * 24)),
    6, 5, DDPNG_FORMAT_BGRA, -24, 6, Pointer(LDest), LSize));
  SetLength(LDest, LSize);

  AssertBytes(LTopDown, Decode(LDest, LInfo));
end;

procedure TTestPngEngine.TestEncodeIntoTooSmallBufferReturnsBufferTooSmall;
var
  LPixels: TBytes;
  LDest: TBytes;
  LSize: Cardinal;
begin
  LPixels := TPngSamples.Noise(32 * 32 * 4, 13);

  // Not even room for the signature and the header
  SetLength(LDest, 20);
  LSize := Length(LDest);
  Assert.AreEqual(DDPNG_ERR_BUFFER_TOO_SMALL, FPng.Encode(Pointer(LPixels),
    32, 32, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize));
  Assert.AreEqual(Cardinal(20), LSize);

  // Room for the headers but not for the data
  SetLength(LDest, 200);
  LSize := Length(LDest);
  Assert.AreEqual(DDPNG_ERR_BUFFER_TOO_SMALL, FPng.Encode(Pointer(LPixels),
    32, 32, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize));
  Assert.AreEqual(Cardinal(200), LSize);
end;

procedure TTestPngEngine.TestEncodeIntoExactlyTheRightBuffer;
var
  LPixels: TBytes;
  LDest: TBytes;
  LSize: Cardinal;
  LExact: Cardinal;
  LInfo: TPngInfo;
begin
  LPixels := TPngSamples.Noise(20 * 10 * 4, 14);
  LDest := EncodeAll(LPixels, 20, 10, DDPNG_FORMAT_BGRA, 6);
  LExact := Length(LDest);

  // One byte less is not enough, the exact size is
  SetLength(LDest, LExact - 1);
  LSize := LExact - 1;
  Assert.AreEqual(DDPNG_ERR_BUFFER_TOO_SMALL, FPng.Encode(Pointer(LPixels),
    20, 10, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize));

  SetLength(LDest, LExact);
  LSize := LExact;
  Assert.AreEqual(DDPNG_OK, FPng.Encode(Pointer(LPixels), 20, 10,
    DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize));
  Assert.AreEqual(LExact, LSize);
  AssertBytes(LPixels, Decode(LDest, LInfo));
end;

procedure TTestPngEngine.TestEncodeInvalidArgumentsReturnInvalidArgument;
var
  LPixels: TBytes;
  LDest: TBytes;
  LSize: Cardinal;
begin
  LPixels := TPngSamples.Noise(16 * 16 * 4, 15);
  SetLength(LDest, 4096);
  LSize := Length(LDest);

  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(Pointer(LPixels),
    0, 16, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize), 'width 0');
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(Pointer(LPixels),
    16, 0, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize), 'height 0');
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(Pointer(LPixels),
    16, 16, 7, 0, 6, Pointer(LDest), LSize), 'format');
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(nil,
    16, 16, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize), 'no pixels');
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(Pointer(LPixels),
    16, 16, DDPNG_FORMAT_BGRA, 0, 6, nil, LSize), 'no destination');
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(Pointer(LPixels),
    16, 16, DDPNG_FORMAT_BGRA, 10, 6, Pointer(LDest), LSize),
    'stride smaller than a row');
  Assert.AreEqual(DDPNG_ERR_INVALID_ARGUMENT, FPng.Encode(Pointer(LPixels),
    DDPNG_MAX_DIMENSION + 1, 1, DDPNG_FORMAT_BGRA, 0, 6, Pointer(LDest), LSize),
    'too wide');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPngEngine);

end.
