{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMp3Engine and of the decoder it creates               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Engine;

// Not covered: the audio itself. The tests have no recording, so they feed
// silent frames (valid layer III frames with zero side info and data, see
// DelphiDoom.Tests.Mp3.Samples) and check framing, buffering, output sizes,
// channel selection and the rejection of invalid data. A bug in the
// reconstruction of real sound (Huffman tables, IMDCT, synthesis filter) would
// not be found here: verify by playing a real MP3 in the engine.

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mp3.Intf;

type
  [TestFixture]
  [Category('mp3')]
  TTestMp3Engine = class(TObject)
  private
    FMp3: IMp3;
    function NewDecoder(AChannels: Integer = MP3_CHANNELS_BOTH;
      AVolume: Integer = MP3_DEFAULT_VOLUME): IMp3Decoder;
    function DecodeInChunks(const ADecoder: IMp3Decoder; const AData: TBytes;
      AFeedChunk, APcmChunk: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVersion;
    [Test]
    [TestCase('Negativo', '-1')]
    [TestCase('Troppo alto', '4')]
    procedure TestCreateDecoderWithInvalidChannelsFails(AChannels: Integer);
    [Test]
    [TestCase('Negativo', '-1')]
    [TestCase('Troppo alto', '101')]
    procedure TestCreateDecoderWithInvalidVolumeFails(AVolume: Integer);
    [Test]
    [TestCase('Zero', '0')]
    [TestCase('Meta', '50')]
    [TestCase('Pieno', '100')]
    procedure TestCreateDecoderAcceptsVolume(AVolume: Integer);
    [Test]
    procedure TestNewDecoderHasNoFormatYet;
    [Test]
    procedure TestDecodeWithoutDataNeedsData;
    [Test]
    [TestCase('Uno', '1')]
    [TestCase('Cinque', '5')]
    [TestCase('Venti', '20')]
    procedure TestDecodeSilentMonoFrames(AFrameCount: Integer);
    [Test]
    procedure TestDecodeSilentStereoFrames;
    [Test]
    [TestCase('Sinistro', '1')]
    [TestCase('Destro', '2')]
    [TestCase('Mix', '3')]
    procedure TestSingleChannelOutputOfStereoStream(AChannels: Integer);
    [Test]
    [TestCase('Un byte', '1')]
    [TestCase('Sette byte', '7')]
    [TestCase('Cento byte', '100')]
    [TestCase('Un frame', '417')]
    [TestCase('Mille byte', '1000')]
    procedure TestSplitFeedGivesSamePcm(AFeedChunk: Integer);
    [Test]
    [TestCase('Un campione', '2')]
    [TestCase('Cento byte', '100')]
    [TestCase('Dispari', '1001')]
    [TestCase('Grande', '5000')]
    procedure TestSmallOutputBufferGivesSamePcm(APcmChunk: Integer);
    [Test]
    procedure TestFeedWithNilDataFails;
    [Test]
    procedure TestDecodeWithInvalidBufferFails;
    [Test]
    procedure TestFeedBeyondTheLimitFails;
    [Test]
    procedure TestGarbageNeedsDataAndKeepsLittle;
    [Test]
    [TestCase('Bitrate libero', '255,251,0,192')]
    [TestCase('Bitrate riservato', '255,251,240,192')]
    [TestCase('Frequenza riservata', '255,251,156,192')]
    [TestCase('Layer riservato', '255,249,144,192')]
    procedure TestInvalidHeaderIsSkipped(AByte0, AByte1, AByte2, AByte3: Integer);
    [Test]
    procedure TestLayer2FrameIsUnsupported;
    [Test]
    [TestCase('Tutto insieme', '100000')]
    [TestCase('Un byte', '1')]
    [TestCase('Tredici byte', '13')]
    procedure TestId3TagIsSkipped(AFeedChunk: Integer);
    [Test]
    procedure TestJunkBeforeTheFirstFrameIsSkipped;
    [Test]
    procedure TestIncompleteFrameWaitsForTheRest;
    [Test]
    procedure TestResetStartsANewStream;
  end;

implementation

uses
  DelphiDoom.Mp3.Engine, DelphiDoom.Tests.Mp3.Samples;

{ TTestMp3Engine }

procedure TTestMp3Engine.Setup;
begin
  FMp3 := TMp3Engine.Create;
end;

procedure TTestMp3Engine.TearDown;
begin
  FMp3 := nil;
end;

function TTestMp3Engine.NewDecoder(AChannels, AVolume: Integer): IMp3Decoder;
begin
  Assert.AreEqual(MP3_OK, FMp3.CreateDecoder(AChannels, AVolume, Result));
  Assert.IsNotNull(Result);
end;

function TTestMp3Engine.DecodeInChunks(const ADecoder: IMp3Decoder;
  const AData: TBytes; AFeedChunk, APcmChunk: Integer): TBytes;
var
  LOffset, LCount, LUsed: Integer;
  LCode: Integer;
  LWritten: Cardinal;
  LBuffer: TBytes;
begin
  SetLength(LBuffer, APcmChunk);
  Result := nil;
  LOffset := 0;
  repeat
    LCount := Length(AData) - LOffset;
    if LCount > AFeedChunk then
      LCount := AFeedChunk;
    if LCount > 0 then
      Assert.AreEqual(MP3_OK, ADecoder.Feed(@AData[LOffset], Cardinal(LCount)));
    Inc(LOffset, LCount);

    repeat
      LCode := ADecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten);
      Assert.IsTrue(LCode >= MP3_OK, 'Decode failed with ' + IntToStr(LCode));
      if LWritten > 0 then
      begin
        LUsed := Length(Result);
        SetLength(Result, LUsed + Integer(LWritten));
        Move(LBuffer[0], Result[LUsed], LWritten);
      end;
    until LCode <> MP3_OK;
  until LOffset >= Length(AData);
end;

procedure TTestMp3Engine.TestVersion;
begin
  Assert.AreEqual(string(AnsiString(DDMP3_VERSION_TEXT)),
    string(AnsiString(FMp3.GetVersion)));
end;

procedure TTestMp3Engine.TestCreateDecoderWithInvalidChannelsFails(
  AChannels: Integer);
var
  LDecoder: IMp3Decoder;
begin
  Assert.AreEqual(MP3_ERROR_INVALID_ARGUMENT,
    FMp3.CreateDecoder(AChannels, MP3_DEFAULT_VOLUME, LDecoder));
  Assert.IsNull(LDecoder);
end;

procedure TTestMp3Engine.TestCreateDecoderWithInvalidVolumeFails(AVolume: Integer);
var
  LDecoder: IMp3Decoder;
begin
  Assert.AreEqual(MP3_ERROR_INVALID_ARGUMENT,
    FMp3.CreateDecoder(MP3_CHANNELS_BOTH, AVolume, LDecoder));
  Assert.IsNull(LDecoder);
end;

procedure TTestMp3Engine.TestCreateDecoderAcceptsVolume(AVolume: Integer);
begin
  Assert.IsNotNull(NewDecoder(MP3_CHANNELS_BOTH, AVolume));
end;

procedure TTestMp3Engine.TestNewDecoderHasNoFormatYet;
var
  LDecoder: IMp3Decoder;
begin
  LDecoder := NewDecoder;
  Assert.AreEqual(0, Integer(LDecoder.GetFrequency));
  Assert.AreEqual(0, Integer(LDecoder.GetChannels));
  Assert.AreEqual(0, Integer(LDecoder.GetPendingSize));
end;

procedure TTestMp3Engine.TestDecodeWithoutDataNeedsData;
var
  LDecoder: IMp3Decoder;
  LBuffer: TBytes;
  LWritten: Cardinal;
begin
  LDecoder := NewDecoder;
  SetLength(LBuffer, 1000);
  Assert.AreEqual(MP3_NEED_DATA,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(0, Integer(LWritten));
end;

procedure TTestMp3Engine.TestDecodeSilentMonoFrames(AFrameCount: Integer);
var
  LDecoder: IMp3Decoder;
  LPcm: TBytes;
begin
  LDecoder := NewDecoder;
  LPcm := DecodeInChunks(LDecoder, TMp3Samples.SilentStream(AFrameCount),
    MaxInt, 4096);

  Assert.AreEqual(AFrameCount * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
  Assert.IsTrue(TMp3Samples.IsSilent(LPcm), 'silent frames must decode to zeros');
  Assert.AreEqual(SAMPLE_FREQUENCY, Integer(LDecoder.GetFrequency));
  Assert.AreEqual(1, Integer(LDecoder.GetChannels));
  Assert.AreEqual(0, Integer(LDecoder.GetPendingSize));
end;

procedure TTestMp3Engine.TestDecodeSilentStereoFrames;
var
  LDecoder: IMp3Decoder;
  LPcm: TBytes;
begin
  LDecoder := NewDecoder;
  LPcm := DecodeInChunks(LDecoder, TMp3Samples.SilentStream(3, False),
    MaxInt, 4096);

  Assert.AreEqual(3 * SAMPLE_STEREO_PCM_BYTES, Length(LPcm));
  Assert.AreEqual(2, Integer(LDecoder.GetChannels));
end;

procedure TTestMp3Engine.TestSingleChannelOutputOfStereoStream(AChannels: Integer);
var
  LDecoder: IMp3Decoder;
  LPcm: TBytes;
begin
  LDecoder := NewDecoder(AChannels);
  LPcm := DecodeInChunks(LDecoder, TMp3Samples.SilentStream(3, False),
    MaxInt, 4096);

  Assert.AreEqual(3 * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
  Assert.AreEqual(1, Integer(LDecoder.GetChannels));
end;

procedure TTestMp3Engine.TestSplitFeedGivesSamePcm(AFeedChunk: Integer);
var
  LStream, LExpected, LActual: TBytes;
begin
  LStream := TMp3Samples.SilentStream(4);
  LExpected := DecodeInChunks(NewDecoder, LStream, MaxInt, 4096);
  LActual := DecodeInChunks(NewDecoder, LStream, AFeedChunk, 4096);

  Assert.AreEqual(4 * SAMPLE_MONO_PCM_BYTES, Length(LExpected));
  Assert.AreEqual(Length(LExpected), Length(LActual));
  Assert.AreEqualMemory(Pointer(LExpected), Pointer(LActual), Length(LExpected));
end;

procedure TTestMp3Engine.TestSmallOutputBufferGivesSamePcm(APcmChunk: Integer);
var
  LStream, LActual: TBytes;
begin
  LStream := TMp3Samples.SilentStream(3);
  LActual := DecodeInChunks(NewDecoder, LStream, MaxInt, APcmChunk);

  Assert.AreEqual(3 * SAMPLE_MONO_PCM_BYTES, Length(LActual));
end;

procedure TTestMp3Engine.TestFeedWithNilDataFails;
var
  LDecoder: IMp3Decoder;
begin
  LDecoder := NewDecoder;
  Assert.AreEqual(MP3_ERROR_INVALID_ARGUMENT, LDecoder.Feed(nil, 10));
  Assert.AreEqual(MP3_OK, LDecoder.Feed(nil, 0));
end;

procedure TTestMp3Engine.TestDecodeWithInvalidBufferFails;
var
  LDecoder: IMp3Decoder;
  LBuffer: array[0..9] of Byte;
  LWritten: Cardinal;
begin
  LDecoder := NewDecoder;
  LWritten := 123;
  Assert.AreEqual(MP3_ERROR_INVALID_ARGUMENT, LDecoder.Decode(nil, 100, LWritten));
  Assert.AreEqual(0, Integer(LWritten));

  LWritten := 123;
  Assert.AreEqual(MP3_ERROR_INVALID_ARGUMENT, LDecoder.Decode(@LBuffer[0], 1, LWritten));
  Assert.AreEqual(0, Integer(LWritten));
end;

procedure TTestMp3Engine.TestFeedBeyondTheLimitFails;
var
  LDecoder: IMp3Decoder;
  LByte: Byte;
begin
  LDecoder := NewDecoder;
  LByte := 0;
  // The size is checked before the memory is touched
  Assert.AreEqual(MP3_ERROR_LIMIT,
    LDecoder.Feed(@LByte, Cardinal(MP3_MAX_BUFFERED_BYTES) + 1));
  Assert.AreEqual(0, Integer(LDecoder.GetPendingSize));
end;

procedure TTestMp3Engine.TestGarbageNeedsDataAndKeepsLittle;
var
  LDecoder: IMp3Decoder;
  LGarbage, LBuffer: TBytes;
  LWritten: Cardinal;
begin
  LDecoder := NewDecoder;
  SetLength(LGarbage, 5000);
  FillChar(LGarbage[0], Length(LGarbage), $55);
  SetLength(LBuffer, 4096);

  Assert.AreEqual(MP3_OK, LDecoder.Feed(@LGarbage[0], Cardinal(Length(LGarbage))));
  Assert.AreEqual(MP3_NEED_DATA,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(0, Integer(LWritten));
  Assert.AreEqual(0, Integer(LDecoder.GetFrequency));
  // Bytes that cannot start a frame header are dropped
  Assert.IsTrue(LDecoder.GetPendingSize <= 3);
end;

procedure TTestMp3Engine.TestInvalidHeaderIsSkipped(AByte0, AByte1, AByte2,
  AByte3: Integer);
var
  LDecoder: IMp3Decoder;
  LData, LBuffer: TBytes;
  LWritten: Cardinal;
begin
  LDecoder := NewDecoder;
  SetLength(LData, 600);
  FillChar(LData[0], Length(LData), 0);
  LData[0] := Byte(AByte0);
  LData[1] := Byte(AByte1);
  LData[2] := Byte(AByte2);
  LData[3] := Byte(AByte3);
  SetLength(LBuffer, 4096);

  Assert.AreEqual(MP3_OK, LDecoder.Feed(@LData[0], Cardinal(Length(LData))));
  Assert.AreEqual(MP3_NEED_DATA,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(0, Integer(LWritten));
  Assert.AreEqual(0, Integer(LDecoder.GetFrequency));
end;

procedure TTestMp3Engine.TestLayer2FrameIsUnsupported;
var
  LDecoder: IMp3Decoder;
  LFrame, LBuffer: TBytes;
  LWritten: Cardinal;
begin
  LDecoder := NewDecoder;
  LFrame := TMp3Samples.Layer2Frame;
  SetLength(LBuffer, 4096);

  Assert.AreEqual(MP3_OK, LDecoder.Feed(@LFrame[0], Cardinal(Length(LFrame))));
  Assert.AreEqual(MP3_ERROR_UNSUPPORTED,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(0, Integer(LWritten));
  Assert.AreEqual(SAMPLE_FREQUENCY, Integer(LDecoder.GetFrequency));

  // The frame was consumed: the decoder is ready for the next one
  Assert.AreEqual(MP3_NEED_DATA,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
end;

procedure TTestMp3Engine.TestId3TagIsSkipped(AFeedChunk: Integer);
var
  LDecoder: IMp3Decoder;
  LStream, LPcm: TBytes;
begin
  // The tag is 100 bytes long and starts with what looks like a frame header:
  // read as a frame it would swallow the beginning of the first real frame
  LStream := TMp3Samples.Join(TMp3Samples.Id3Tag(100),
    TMp3Samples.SilentStream(2));
  LDecoder := NewDecoder;
  LPcm := DecodeInChunks(LDecoder, LStream, AFeedChunk, 4096);

  Assert.AreEqual(2 * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
end;

procedure TTestMp3Engine.TestJunkBeforeTheFirstFrameIsSkipped;
var
  LDecoder: IMp3Decoder;
  LJunk, LStream, LPcm: TBytes;
begin
  SetLength(LJunk, 50);
  FillChar(LJunk[0], Length(LJunk), $12);
  LStream := TMp3Samples.Join(LJunk, TMp3Samples.SilentStream(2));
  LDecoder := NewDecoder;
  LPcm := DecodeInChunks(LDecoder, LStream, MaxInt, 4096);

  Assert.AreEqual(2 * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
end;

procedure TTestMp3Engine.TestIncompleteFrameWaitsForTheRest;
var
  LDecoder: IMp3Decoder;
  LStream, LBuffer: TBytes;
  LWritten: Cardinal;
  LCut: Integer;
begin
  LStream := TMp3Samples.SilentStream(2);
  LCut := Length(LStream) - 10;
  LDecoder := NewDecoder;
  SetLength(LBuffer, 8192);

  Assert.AreEqual(MP3_OK, LDecoder.Feed(@LStream[0], Cardinal(LCut)));
  Assert.AreEqual(MP3_NEED_DATA,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(SAMPLE_MONO_PCM_BYTES, Integer(LWritten));
  // The partial second frame is kept untouched
  Assert.AreEqual(SAMPLE_FRAME_SIZE - 10, Integer(LDecoder.GetPendingSize));

  Assert.AreEqual(MP3_OK, LDecoder.Feed(@LStream[LCut], 10));
  Assert.AreEqual(MP3_NEED_DATA,
    LDecoder.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(SAMPLE_MONO_PCM_BYTES, Integer(LWritten));
  Assert.AreEqual(0, Integer(LDecoder.GetPendingSize));
end;

procedure TTestMp3Engine.TestResetStartsANewStream;
var
  LDecoder: IMp3Decoder;
  LStream, LFirst, LSecond: TBytes;
begin
  LStream := TMp3Samples.SilentStream(3);
  LDecoder := NewDecoder;
  LFirst := DecodeInChunks(LDecoder, LStream, MaxInt, 4096);

  Assert.AreEqual(MP3_OK, LDecoder.Reset);
  Assert.AreEqual(0, Integer(LDecoder.GetFrequency));
  Assert.AreEqual(0, Integer(LDecoder.GetChannels));
  Assert.AreEqual(0, Integer(LDecoder.GetPendingSize));

  LSecond := DecodeInChunks(LDecoder, LStream, MaxInt, 4096);
  Assert.AreEqual(3 * SAMPLE_MONO_PCM_BYTES, Length(LFirst));
  Assert.AreEqual(Length(LFirst), Length(LSecond));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMp3Engine);

end.
