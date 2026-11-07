{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegDecoder                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Decoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegDecoder = class(TObject)
  private
    function Decode(const AStream: TBytes; out APixels: TBytes; out AInfo: TJpegInfo): Integer;
  public
    [Test]
    procedure TestVersionIsThatOfLibjpeg;
    [Test]
    procedure TestReadInfoGivesTheSizeAndTheComponents;
    [Test]
    [TestCase('Zero', '0')]
    [TestCase('Plus8', '8')]
    [TestCase('Minus8', '-8')]
    [TestCase('Plus100', '100')]
    [TestCase('Minus100', '-100')]
    [TestCase('Plus1000', '1000')]
    [TestCase('Minus1000', '-1000')]
    [TestCase('Largest', '2047')]
    [TestCase('Smallest', '-2047')]
    procedure TestDecodesABlockThatHasOnlyTheDc(ADc: Integer);
    [Test]
    [TestCase('Zero', '0')]
    [TestCase('Plus100', '100')]
    [TestCase('Minus100', '-100')]
    [TestCase('Plus1000', '1000')]
    procedure TestDecodesAProgressiveBlockThatHasOnlyTheDc(ADc: Integer);
    [Test]
    procedure TestSmallBufferGivesTheSizeOfTheImage;
    [Test]
    procedure TestNoStreamIsAnInvalidArgument;
    [Test]
    procedure TestNoBufferIsTooSmall;
    [Test]
    procedure TestStreamThatEndsInTheDataIsTruncated;
    [Test]
    procedure TestNotJpegIsADataError;
    [Test]
    procedure TestUnsupportedFrameHasItsCode;
    [Test]
    procedure TestHeaderErrorLeavesTheInfoEmpty;
    [Test]
    procedure TestTwoCallsGiveTheSameImage;
  end;

implementation

uses
  DelphiDoom.Jpeg.Decoder, DelphiDoom.Tests.Jpeg.TinyStream;

{ TTestJpegDecoder }

function TTestJpegDecoder.Decode(const AStream: TBytes; out APixels: TBytes;
  out AInfo: TJpegInfo): Integer;
begin
  SetLength(APixels, 64);
  Result := TJpegDecoder.Decode(Pointer(AStream), Length(AStream), Pointer(APixels),
    Length(APixels), AInfo);
end;

procedure TTestJpegDecoder.TestVersionIsThatOfLibjpeg;
begin
  Assert.AreEqual('6b', string(AnsiString(TJpegDecoder.Version)));
end;

procedure TTestJpegDecoder.TestReadInfoGivesTheSizeAndTheComponents;
var
  LStream: TBytes;
  LInfo: TJpegInfo;
begin
  LStream := TJpegTinyStream.Build(8, False);
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.ReadInfo(Pointer(LStream), Length(LStream), LInfo));
  Assert.AreEqual(8, LInfo.Width);
  Assert.AreEqual(8, LInfo.Height);
  Assert.AreEqual(1, LInfo.Components);
end;

procedure TTestJpegDecoder.TestDecodesABlockThatHasOnlyTheDc(ADc: Integer);
var
  LPixels: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  Assert.AreEqual(DDJPEG_OK, Decode(TJpegTinyStream.Build(ADc, False), LPixels, LInfo));
  for LIndex := 0 to 63 do
    Assert.AreEqual(Integer(TJpegTinyStream.ExpectedSample(ADc)), Integer(LPixels[LIndex]));
end;

procedure TTestJpegDecoder.TestDecodesAProgressiveBlockThatHasOnlyTheDc(ADc: Integer);
var
  LPixels: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  // The AC coefficients were never sent, so the block is smoothed: with
  // neighbours equal to itself there is nothing to estimate
  Assert.AreEqual(DDJPEG_OK, Decode(TJpegTinyStream.Build(ADc, True), LPixels, LInfo));
  for LIndex := 0 to 63 do
    Assert.AreEqual(Integer(TJpegTinyStream.ExpectedSample(ADc)), Integer(LPixels[LIndex]));
end;

procedure TTestJpegDecoder.TestSmallBufferGivesTheSizeOfTheImage;
var
  LStream: TBytes;
  LSmall: array[0..7] of Byte;
  LInfo: TJpegInfo;
begin
  LStream := TJpegTinyStream.Build(8, False);
  Assert.AreEqual(DDJPEG_ERR_BUFFER_TOO_SMALL, TJpegDecoder.Decode(Pointer(LStream),
    Length(LStream), @LSmall[0], SizeOf(LSmall), LInfo));
  Assert.AreEqual(8, LInfo.Width);
  Assert.AreEqual(8, LInfo.Height);
  Assert.AreEqual(1, LInfo.Components);
end;

procedure TTestJpegDecoder.TestNoStreamIsAnInvalidArgument;
var
  LInfo: TJpegInfo;
  LPixels: array[0..63] of Byte;
begin
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, TJpegDecoder.ReadInfo(nil, 10, LInfo));
  Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, TJpegDecoder.Decode(@LPixels[0], 0,
    @LPixels[0], SizeOf(LPixels), LInfo));
end;

procedure TTestJpegDecoder.TestNoBufferIsTooSmall;
var
  LStream: TBytes;
  LInfo: TJpegInfo;
begin
  LStream := TJpegTinyStream.Build(8, False);
  Assert.AreEqual(DDJPEG_ERR_BUFFER_TOO_SMALL, TJpegDecoder.Decode(Pointer(LStream),
    Length(LStream), nil, 64, LInfo));
end;

procedure TTestJpegDecoder.TestStreamThatEndsInTheDataIsTruncated;
var
  LStream: TBytes;
  LPixels: TBytes;
  LInfo: TJpegInfo;
  LScan: Integer;
begin
  LStream := TJpegTinyStream.Build(8, False);
  // Cut right after the header of the scan
  LScan := 0;
  while not ((LStream[LScan] = $FF) and (LStream[LScan + 1] = $DA)) do
    Inc(LScan);
  SetLength(LStream, LScan + 10);
  Assert.AreEqual(DDJPEG_ERR_TRUNCATED, Decode(LStream, LPixels, LInfo));
  Assert.AreEqual(8, LInfo.Width, 'The header was read');
end;

procedure TTestJpegDecoder.TestNotJpegIsADataError;
var
  LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  Assert.AreEqual(DDJPEG_ERR_DATA, Decode(TEncoding.ASCII.GetBytes('GIF89a not a jpeg'), LPixels, LInfo));
end;

procedure TTestJpegDecoder.TestUnsupportedFrameHasItsCode;
var
  LStream: TBytes;
  LPixels: TBytes;
  LInfo: TJpegInfo;
  LFrame: Integer;
begin
  // The marker of the frame becomes a lossless one
  LStream := TJpegTinyStream.Build(8, False);
  LFrame := 0;
  while not ((LStream[LFrame] = $FF) and (LStream[LFrame + 1] = $C0)) do
    Inc(LFrame);
  LStream[LFrame + 1] := $C3;
  Assert.AreEqual(DDJPEG_ERR_UNSUPPORTED, Decode(LStream, LPixels, LInfo));
end;

procedure TTestJpegDecoder.TestHeaderErrorLeavesTheInfoEmpty;
var
  LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  Decode(TEncoding.ASCII.GetBytes('not a jpeg'), LPixels, LInfo);
  Assert.AreEqual(0, LInfo.Width);
  Assert.AreEqual(0, LInfo.Height);
  Assert.AreEqual(0, LInfo.Components);
end;

procedure TTestJpegDecoder.TestTwoCallsGiveTheSameImage;
var
  LStream: TBytes;
  LFirst, LSecond: TBytes;
  LInfo: TJpegInfo;
begin
  LStream := TJpegTinyStream.Build(-300, True);
  Assert.AreEqual(DDJPEG_OK, Decode(LStream, LFirst, LInfo));
  Assert.AreEqual(DDJPEG_OK, Decode(LStream, LSecond, LInfo));
  Assert.IsTrue(CompareMem(Pointer(LFirst), Pointer(LSecond), 64));
end;

end.
