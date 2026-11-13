{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMp3Client                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Client;

// Not covered: the audio itself (see the note in DelphiDoom.Tests.Mp3.Engine).
// The streams are silent frames built in memory.

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mp3.Intf,
  DelphiDoom.Mp3.Client;

type
  [TestFixture]
  [Category('mp3')]
  TTestMp3Client = class(TObject)
  private
    FClient: TMp3Client;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutMp3Raises;
    [Test]
    procedure TestCreateWithInvalidVolumeRaises;
    [Test]
    procedure TestNewClientHasNoFormatYet;
    [Test]
    [TestCase('Uno', '1')]
    [TestCase('Cinque', '5')]
    [TestCase('Venti', '20')]
    procedure TestDecodeAll(AFrameCount: Integer);
    [Test]
    procedure TestFeedInBlocksAndDrain;
    [Test]
    procedure TestDecodeReturnsFalseWhenTheInputIsExhausted;
    [Test]
    procedure TestDecodeReturnsTrueWhenTheBufferIsFull;
    [Test]
    procedure TestLayer2RaisesUnsupported;
    [Test]
    procedure TestFeedBeyondTheLimitRaises;
    [Test]
    procedure TestResetAllowsDecodingAgain;
    [Test]
    procedure TestExceptionMessageAndCode;
    [Test]
    procedure TestCodeOfException;
  end;

implementation

uses
  DelphiDoom.Mp3.Engine, DelphiDoom.Tests.Mp3.Samples;

{ TTestMp3Client }

procedure TTestMp3Client.Setup;
begin
  FClient := TMp3Client.Create(TMp3Engine.Create);
end;

procedure TTestMp3Client.TearDown;
begin
  FreeAndNil(FClient);
end;

procedure TTestMp3Client.TestCreateWithoutMp3Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      TMp3Client.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestMp3Client.TestCreateWithInvalidVolumeRaises;
begin
  try
    TMp3Client.Create(TMp3Engine.Create, MP3_CHANNELS_BOTH, 500).Free;
    Assert.Fail('EMp3Exception expected');
  except
    on E: EMp3Exception do
      Assert.AreEqual(MP3_ERROR_INVALID_ARGUMENT, E.Code);
  end;
end;

procedure TTestMp3Client.TestNewClientHasNoFormatYet;
begin
  Assert.AreEqual(0, Integer(FClient.Frequency));
  Assert.AreEqual(0, Integer(FClient.Channels));
  Assert.AreEqual(0, Integer(FClient.PendingSize));
end;

procedure TTestMp3Client.TestDecodeAll(AFrameCount: Integer);
var
  LPcm: TBytes;
begin
  LPcm := FClient.DecodeAll(TMp3Samples.SilentStream(AFrameCount));

  Assert.AreEqual<Integer>(AFrameCount * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
  Assert.IsTrue(TMp3Samples.IsSilent(LPcm), 'silent frames must decode to zeros');
  Assert.AreEqual(SAMPLE_FREQUENCY, Integer(FClient.Frequency));
  Assert.AreEqual(1, Integer(FClient.Channels));
end;

procedure TTestMp3Client.TestFeedInBlocksAndDrain;
const
  BLOCK_SIZE = 300;
var
  LStream, LBlock, LPcm, LPart: TBytes;
  LOffset, LCount: Integer;
begin
  LStream := TMp3Samples.SilentStream(6);
  LPcm := nil;
  LOffset := 0;
  while LOffset < Length(LStream) do
  begin
    LCount := Length(LStream) - LOffset;
    if LCount > BLOCK_SIZE then
      LCount := BLOCK_SIZE;
    SetLength(LBlock, LCount);
    Move(LStream[LOffset], LBlock[0], LCount);
    Inc(LOffset, LCount);

    FClient.Feed(LBlock);
    LPart := FClient.Drain;
    LPcm := TMp3Samples.Join(LPcm, LPart);
  end;

  Assert.AreEqual<Integer>(6 * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
end;

procedure TTestMp3Client.TestDecodeReturnsFalseWhenTheInputIsExhausted;
var
  LBuffer: TBytes;
  LWritten: Cardinal;
begin
  SetLength(LBuffer, 8192);
  FClient.Feed(TMp3Samples.SilentStream(1));

  Assert.IsFalse(FClient.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(SAMPLE_MONO_PCM_BYTES, Integer(LWritten));
end;

procedure TTestMp3Client.TestDecodeReturnsTrueWhenTheBufferIsFull;
var
  LBuffer: TBytes;
  LWritten: Cardinal;
begin
  SetLength(LBuffer, 100);
  FClient.Feed(TMp3Samples.SilentStream(1));

  Assert.IsTrue(FClient.Decode(@LBuffer[0], Cardinal(Length(LBuffer)), LWritten));
  Assert.AreEqual(100, Integer(LWritten));
end;

procedure TTestMp3Client.TestLayer2RaisesUnsupported;
begin
  try
    FClient.DecodeAll(TMp3Samples.Layer2Frame);
    Assert.Fail('EMp3Exception expected');
  except
    on E: EMp3Exception do
      Assert.AreEqual(MP3_ERROR_UNSUPPORTED, E.Code);
  end;
end;

procedure TTestMp3Client.TestFeedBeyondTheLimitRaises;
var
  LByte: Byte;
begin
  LByte := 0;
  try
    // The size is checked before the memory is touched
    FClient.Feed(@LByte, Cardinal(MP3_MAX_BUFFERED_BYTES) + 1);
    Assert.Fail('EMp3Exception expected');
  except
    on E: EMp3Exception do
      Assert.AreEqual(MP3_ERROR_LIMIT, E.Code);
  end;
end;

procedure TTestMp3Client.TestResetAllowsDecodingAgain;
var
  LStream, LFirst, LSecond: TBytes;
begin
  LStream := TMp3Samples.SilentStream(4);
  LFirst := FClient.DecodeAll(LStream);
  FClient.Reset;
  Assert.AreEqual(0, Integer(FClient.Frequency));

  LSecond := FClient.DecodeAll(LStream);
  Assert.AreEqual<Integer>(4 * SAMPLE_MONO_PCM_BYTES, Length(LFirst));
  Assert.AreEqual(Length(LFirst), Length(LSecond));
end;

procedure TTestMp3Client.TestExceptionMessageAndCode;
var
  LException: EMp3Exception;
begin
  LException := EMp3Exception.CreateCode(MP3_ERROR_DATA);
  try
    Assert.AreEqual(MP3_ERROR_DATA, LException.Code);
    Assert.IsTrue(Pos('Invalid MP3 data', LException.Message) > 0);
  finally
    LException.Free;
  end;
  Assert.AreEqual('Unknown error', EMp3Exception.TextOf(-99));
end;

procedure TTestMp3Client.TestCodeOfException;
var
  LGeneric: Exception;
  LMemory: EOutOfMemory;
  LDecoder: EMp3Exception;
begin
  LGeneric := Exception.Create('x');
  LMemory := EOutOfMemory.Create('x');
  LDecoder := EMp3Exception.CreateCode(MP3_ERROR_LIMIT);
  try
    Assert.AreEqual(MP3_ERROR_INTERNAL, EMp3Exception.CodeOf(LGeneric));
    Assert.AreEqual(MP3_ERROR_MEMORY, EMp3Exception.CodeOf(LMemory));
    Assert.AreEqual(MP3_ERROR_LIMIT, EMp3Exception.CodeOf(LDecoder));
  finally
    LDecoder.Free;
    LMemory.Free;
    LGeneric.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMp3Client);

end.
