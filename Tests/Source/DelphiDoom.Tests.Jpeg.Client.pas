{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegClient                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Client;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Client;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegClient = class(TObject)
  private
    FClient: TJpegClient;
    function MakeGradient(AWidth, AHeight, AComponents: Integer): TBytes;
    function MakeNoise(AWidth, AHeight, AComponents: Integer): TBytes;
    function MaxDifference(const AExpected, AActual: TBytes): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutJpegRaises;
    [Test]
    procedure TestVersion;
    [Test]
    [TestCase('Grigio', '40,24,1')]
    [TestCase('Colore', '40,24,3')]
    [TestCase('NonMultiploDiOtto', '17,13,3')]
    procedure TestRoundTrip(AWidth, AHeight, AComponents: Integer);
    [Test]
    procedure TestRoundTripOfALargeNoisyImageGrowsTheBuffer;
    [Test]
    procedure TestGetInfo;
    [Test]
    procedure TestEncodeWithTooFewPixelsRaisesInvalidArgument;
    [Test]
    procedure TestEncodeWithInvalidFormatRaisesInvalidArgument;
    [Test]
    procedure TestDecodeGarbageRaisesDataError;
    [Test]
    procedure TestDecodeTruncatedStreamRaisesTruncated;
    [Test]
    procedure TestDecodeEmptyStreamRaisesInvalidArgument;
  end;

implementation

uses
  DelphiDoom.Jpeg.Engine;

const
  // Largest difference between a pixel and its decoded value at the quality
  // used by the tests, for the smooth images they use
  PIXEL_TOLERANCE = 6;

{ TTestJpegClient }

procedure TTestJpegClient.Setup;
begin
  FClient := TJpegClient.Create(TJpegEngine.Create);
end;

procedure TTestJpegClient.TearDown;
begin
  FreeAndNil(FClient);
end;

function TTestJpegClient.MakeGradient(AWidth, AHeight, AComponents: Integer): TBytes;
var
  LX: Integer;
  LY: Integer;
  LComponent: Integer;
begin
  SetLength(Result, AWidth * AHeight * AComponents);
  for LY := 0 to AHeight - 1 do
    for LX := 0 to AWidth - 1 do
      for LComponent := 0 to AComponents - 1 do
        Result[(LY * AWidth + LX) * AComponents + LComponent] :=
          Byte(LX * 3 + LY * 2 + LComponent * 40);
end;

function TTestJpegClient.MakeNoise(AWidth, AHeight, AComponents: Integer): TBytes;
var
  LIndex: Integer;
  LSeed: Int64;
begin
  SetLength(Result, AWidth * AHeight * AComponents);
  LSeed := 987654321;
  for LIndex := 0 to High(Result) do
  begin
    LSeed := (LSeed * 1103515245 + 12345) and $7FFFFFFF;
    Result[LIndex] := Byte((LSeed shr 16) and $FF);
  end;
end;

function TTestJpegClient.MaxDifference(const AExpected, AActual: TBytes): Integer;
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

procedure TTestJpegClient.TestCreateWithoutJpegRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TJpegClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestJpegClient.TestVersion;
begin
  Assert.AreEqual('6b', FClient.Version);
end;

procedure TTestJpegClient.TestRoundTrip(AWidth, AHeight, AComponents: Integer);
var
  LPixels: TBytes;
  LImage: TJpegImage;
begin
  LPixels := MakeGradient(AWidth, AHeight, AComponents);
  LImage := FClient.Decode(FClient.Encode(LPixels, AWidth, AHeight,
    AComponents, 95));

  Assert.AreEqual(AWidth, LImage.Width);
  Assert.AreEqual(AHeight, LImage.Height);
  Assert.AreEqual(AComponents, LImage.Components);
  Assert.IsTrue(MaxDifference(LPixels, LImage.Pixels) <= PIXEL_TOLERANCE,
    'Decoded pixels differ too much from the original');
end;

procedure TTestJpegClient.TestRoundTripOfALargeNoisyImageGrowsTheBuffer;
var
  LPixels, LStream: TBytes;
  LImage: TJpegImage;
begin
  // Noise at the highest quality does not fit the first guess of the client
  LPixels := MakeNoise(128, 128, 3);
  LStream := FClient.Encode(LPixels, 128, 128, 3, 100);
  Assert.IsTrue(Length(LStream) > 128 * 128 * 3 div 2 + 4096);

  LImage := FClient.Decode(LStream);
  Assert.AreEqual(128, LImage.Width);
  Assert.AreEqual(128, LImage.Height);
  Assert.AreEqual(Length(LPixels), Length(LImage.Pixels));
end;

procedure TTestJpegClient.TestGetInfo;
var
  LInfo: TJpegInfo;
begin
  LInfo := FClient.GetInfo(FClient.Encode(MakeGradient(40, 24, 3), 40, 24, 3));
  Assert.AreEqual(40, LInfo.Width);
  Assert.AreEqual(24, LInfo.Height);
  Assert.AreEqual(3, LInfo.Components);
end;

procedure TTestJpegClient.TestEncodeWithTooFewPixelsRaisesInvalidArgument;
begin
  try
    FClient.Encode(MakeGradient(10, 10, 3), 40, 24, 3);
    Assert.Fail('EJpegException expected');
  except
    on E: EJpegException do
      Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, E.Code);
  end;
end;

procedure TTestJpegClient.TestEncodeWithInvalidFormatRaisesInvalidArgument;
begin
  try
    FClient.Encode(MakeGradient(10, 10, 2), 10, 10, 2);
    Assert.Fail('EJpegException expected');
  except
    on E: EJpegException do
      Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, E.Code);
  end;
end;

procedure TTestJpegClient.TestDecodeGarbageRaisesDataError;
var
  LGarbage: TBytes;
  LIndex: Integer;
begin
  SetLength(LGarbage, 64);
  for LIndex := 0 to High(LGarbage) do
    LGarbage[LIndex] := Byte(LIndex * 13 + 1);

  try
    FClient.Decode(LGarbage);
    Assert.Fail('EJpegException expected');
  except
    on E: EJpegException do
      Assert.AreEqual(DDJPEG_ERR_DATA, E.Code);
  end;
end;

procedure TTestJpegClient.TestDecodeTruncatedStreamRaisesTruncated;
var
  LStream: TBytes;
begin
  LStream := FClient.Encode(MakeNoise(96, 96, 3), 96, 96, 3, 90);
  SetLength(LStream, Length(LStream) div 2);

  try
    FClient.Decode(LStream);
    Assert.Fail('EJpegException expected');
  except
    on E: EJpegException do
      Assert.AreEqual(DDJPEG_ERR_TRUNCATED, E.Code);
  end;
end;

procedure TTestJpegClient.TestDecodeEmptyStreamRaisesInvalidArgument;
begin
  try
    FClient.Decode(nil, 0);
    Assert.Fail('EJpegException expected');
  except
    on E: EJpegException do
      Assert.AreEqual(DDJPEG_ERR_INVALID_ARGUMENT, E.Code);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJpegClient);

end.
