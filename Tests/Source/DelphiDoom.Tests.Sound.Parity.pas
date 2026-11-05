{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - same answers as libsndfile (C)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.Parity;

interface

uses
  System.SysUtils, System.StrUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf,
  DelphiDoom.Tests.Sound.WavFile, DelphiDoom.Tests.Sound.ContainerFiles;

type
  /// <summary>
  ///   Opens the same bytes with the C engine and with the Pascal one and
  ///   requires the same description of the sound, the same samples (bit by
  ///   bit) through every Read method, and the same results of Seek
  /// </summary>
  [TestFixture]
  [Category('sound')]
  TTestSoundParity = class(TObject)
  private
    FReference: ISndfile;
    FCandidate: ISndfile;
    FCurrentName: string;
    procedure CheckSame(const ASource: TBytes; const AName: string);
    procedure CheckSameFailure(const ASource: TBytes; const AName: string);
    procedure CompareReads(const ASource: TBytes; AKind, AChunk: Integer;
      const AName: string);
    procedure CompareSeeks(const ASource: TBytes; const AName: string);
    function Open(const AEngine: ISndfile; const ASource: TBytes): ISoundFile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestPcm8;
    [Test]
    procedure TestPcm16;
    [Test]
    procedure TestPcm24;
    [Test]
    procedure TestPcm32;
    [Test]
    procedure TestFloat;
    [Test]
    procedure TestDouble;
    [Test]
    procedure TestMuLaw;
    [Test]
    procedure TestALaw;
    [Test]
    procedure TestBigEndian;
    [Test]
    procedure TestExtensible;
    [Test]
    procedure TestChunksAroundTheData;
    [Test]
    procedure TestDataLargerThanTheFile;
    [Test]
    procedure TestOddDataSize;
    [Test]
    procedure TestDamagedFiles;
    [Test]
    procedure TestNotASound;
    [Test]
    procedure TestAiffPcm;
    [Test]
    procedure TestAiffCompressedPcm;
    [Test]
    procedure TestAiffFloatAndCompanded;
    [Test]
    procedure TestAiffChunks;
    [Test]
    procedure TestAiffSizes;
    [Test]
    procedure TestAiffDamaged;
    [Test]
    procedure TestAvr;
    [Test]
    procedure TestHtk;
    [Test]
    procedure TestSimpleFormatsDamaged;
    [Test]
    procedure TestInvalidSampleRate;
    [Test]
    procedure TestAuPcm;
    [Test]
    procedure TestAuFloatAndCompanded;
    [Test]
    procedure TestAuSizes;
    [Test]
    procedure TestAuDamaged;
    [Test]
    procedure TestVocBlocks;
    [Test]
    procedure TestVocExtendedII;
    [Test]
    procedure TestVocDamaged;
  end;

implementation

uses
  DelphiDoom.Sndfile.Engine, DelphiDoom.Sound.Factory;

const
  KIND_SHORT = 0;
  KIND_INT = 1;
  KIND_DOUBLE = 2;

function BytesPerItem(AKind: Integer): Integer;
begin
  case AKind of
    KIND_SHORT: Result := 2;
    KIND_INT: Result := 4;
  else
    Result := 8;
  end;
end;

function ReadKind(const ASound: ISoundFile; AKind: Integer; ABuffer: Pointer;
  AFrames: Int64; out ARead: Int64): Integer;
begin
  case AKind of
    KIND_SHORT: Result := ASound.ReadShort(ABuffer, AFrames, ARead);
    KIND_INT: Result := ASound.ReadInt(ABuffer, AFrames, ARead);
  else
    Result := ASound.ReadDouble(ABuffer, AFrames, ARead);
  end;
end;

{ TTestSoundParity }

procedure TTestSoundParity.Setup;
begin
  FReference := TSndfileEngine.Create;
  FCandidate := TSoundFactory.CreateEngine;
end;

procedure TTestSoundParity.TearDown;
begin
  FCandidate := nil;
  FReference := nil;
end;

function TTestSoundParity.Open(const AEngine: ISndfile;
  const ASource: TBytes): ISoundFile;
begin
  Assert.AreEqual(SNDFILE_OK, AEngine.OpenMemory(@ASource[0], Length(ASource), Result),
    'open: ' + FCurrentName + IfThen(AEngine = FReference, ' (C engine)', ' (Pascal engine)'));
  Assert.IsNotNull(Result);
end;

procedure TTestSoundParity.CompareReads(const ASource: TBytes; AKind,
  AChunk: Integer; const AName: string);
var
  LExpected, LActual: ISoundFile;
  LInfo: TSoundFileInfo;
  LExpectedBuffer, LActualBuffer: TBytes;
  LExpectedRead, LActualRead: Int64;
  LExpectedCode, LActualCode: Integer;
  LItems: Integer;
  LRound: Integer;
begin
  LExpected := Open(FReference, ASource);
  LActual := Open(FCandidate, ASource);
  LExpected.GetInfo(LInfo);

  LItems := AChunk * LInfo.Channels;
  SetLength(LExpectedBuffer, LItems * BytesPerItem(AKind));
  SetLength(LActualBuffer, Length(LExpectedBuffer));

  // Always one more read than needed, to see the end of the sound
  for LRound := 0 to Integer(LInfo.Frames div AChunk) + 1 do
  begin
    FillChar(LExpectedBuffer[0], Length(LExpectedBuffer), $5A);
    FillChar(LActualBuffer[0], Length(LActualBuffer), $5A);
    LExpectedCode := ReadKind(LExpected, AKind, @LExpectedBuffer[0], AChunk, LExpectedRead);
    LActualCode := ReadKind(LActual, AKind, @LActualBuffer[0], AChunk, LActualRead);

    Assert.AreEqual(LExpectedCode, LActualCode,
      Format('%s: code of the read %d (kind %d)', [AName, LRound, AKind]));
    Assert.AreEqual(LExpectedRead, LActualRead,
      Format('%s: frames of the read %d (kind %d)', [AName, LRound, AKind]));
    Assert.IsTrue(CompareMem(@LExpectedBuffer[0], @LActualBuffer[0], Length(LExpectedBuffer)),
      Format('%s: samples of the read %d (kind %d)', [AName, LRound, AKind]));
  end;
end;

procedure TTestSoundParity.CompareSeeks(const ASource: TBytes;
  const AName: string);
const
  CASES: array[0..9, 0..1] of Integer = (
    (0, SNDFILE_SEEK_SET), (3, SNDFILE_SEEK_SET), (1, SNDFILE_SEEK_CUR),
    (-1, SNDFILE_SEEK_CUR), (0, SNDFILE_SEEK_END), (-2, SNDFILE_SEEK_END),
    (1, SNDFILE_SEEK_END), (-1, SNDFILE_SEEK_SET), (1000000, SNDFILE_SEEK_SET),
    (0, 7));
var
  LExpected, LActual: ISoundFile;
  LIndex: Integer;
  LExpectedPosition, LActualPosition: Int64;
  LExpectedCode, LActualCode: Integer;
  LShortExpected, LShortActual: array[0..15] of SmallInt;
  LExpectedRead, LActualRead: Int64;
begin
  LExpected := Open(FReference, ASource);
  LActual := Open(FCandidate, ASource);
  for LIndex := 0 to High(CASES) do
  begin
    LExpectedCode := LExpected.Seek(CASES[LIndex, 0], CASES[LIndex, 1], LExpectedPosition);
    LActualCode := LActual.Seek(CASES[LIndex, 0], CASES[LIndex, 1], LActualPosition);
    Assert.AreEqual(LExpectedCode = SNDFILE_OK, LActualCode = SNDFILE_OK,
      Format('%s: seek %d (%d, %d) success', [AName, LIndex, CASES[LIndex, 0], CASES[LIndex, 1]]));
    Assert.AreEqual(LExpectedPosition, LActualPosition,
      Format('%s: seek %d position', [AName, LIndex]));

    // And what is read afterwards (when the sound is mono or stereo)
    FillChar(LShortExpected, SizeOf(LShortExpected), 0);
    FillChar(LShortActual, SizeOf(LShortActual), 0);
    LExpected.ReadShort(@LShortExpected, 1, LExpectedRead);
    LActual.ReadShort(@LShortActual, 1, LActualRead);
    Assert.AreEqual(LExpectedRead, LActualRead, Format('%s: read after seek %d', [AName, LIndex]));
    Assert.IsTrue(CompareMem(@LShortExpected, @LShortActual, SizeOf(LShortExpected)),
      Format('%s: samples after seek %d', [AName, LIndex]));
  end;
end;

procedure TTestSoundParity.CheckSame(const ASource: TBytes; const AName: string);
var
  LExpected, LActual: ISoundFile;
  LExpectedInfo, LActualInfo: TSoundFileInfo;
  LKind: Integer;
begin
  FCurrentName := AName;
  LExpected := Open(FReference, ASource);
  LActual := Open(FCandidate, ASource);
  LExpected.GetInfo(LExpectedInfo);
  LActual.GetInfo(LActualInfo);

  Assert.AreEqual(LExpectedInfo.Frames, LActualInfo.Frames, AName + ': frames');
  Assert.AreEqual(LExpectedInfo.SampleRate, LActualInfo.SampleRate, AName + ': sample rate');
  Assert.AreEqual(LExpectedInfo.Channels, LActualInfo.Channels, AName + ': channels');
  Assert.AreEqual(Integer(LExpectedInfo.Format), Integer(LActualInfo.Format), AName + ': format');
  Assert.AreEqual(LExpectedInfo.Sections, LActualInfo.Sections, AName + ': sections');
  Assert.AreEqual(LExpectedInfo.Seekable, LActualInfo.Seekable, AName + ': seekable');

  LExpected := nil;
  LActual := nil;
  for LKind := KIND_SHORT to KIND_DOUBLE do
  begin
    CompareReads(ASource, LKind, 1, AName);
    CompareReads(ASource, LKind, 7, AName);
    CompareReads(ASource, LKind, 4096, AName);
  end;
  CompareSeeks(ASource, AName);
end;

procedure TTestSoundParity.CheckSameFailure(const ASource: TBytes;
  const AName: string);
var
  LSound: ISoundFile;
  LExpectedCode, LActualCode: Integer;
begin
  LExpectedCode := FReference.OpenMemory(@ASource[0], Length(ASource), LSound);
  Assert.AreNotEqual(SNDFILE_OK, LExpectedCode, AName + ': the C engine should refuse the file');
  LSound := nil;
  LActualCode := FCandidate.OpenMemory(@ASource[0], Length(ASource), LSound);
  Assert.AreNotEqual(SNDFILE_OK, LActualCode, AName + ': the Pascal engine should refuse the file');
  Assert.IsNull(LSound, AName + ': no sound for a refused file');
end;

procedure TTestSoundParity.TestPcm8;
var
  LChannels: Word;
begin
  for LChannels := 1 to 3 do
    CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(1, LChannels, 8),
      TSoundTestWavFile.RandomBytes(LChannels * 301, LChannels)), 'pcm8 ' + IntToStr(LChannels));
end;

procedure TTestSoundParity.TestPcm16;
var
  LChannels: Word;
begin
  for LChannels := 1 to 3 do
    CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(1, LChannels, 16),
      TSoundTestWavFile.RandomBytes(LChannels * 2 * 301, LChannels)), 'pcm16 ' + IntToStr(LChannels));
end;

procedure TTestSoundParity.TestPcm24;
var
  LChannels: Word;
begin
  for LChannels := 1 to 2 do
    CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(1, LChannels, 24),
      TSoundTestWavFile.RandomBytes(LChannels * 3 * 301, LChannels)), 'pcm24 ' + IntToStr(LChannels));
end;

procedure TTestSoundParity.TestPcm32;
var
  LChannels: Word;
begin
  for LChannels := 1 to 2 do
    CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(1, LChannels, 32),
      TSoundTestWavFile.RandomBytes(LChannels * 4 * 301, LChannels)), 'pcm32 ' + IntToStr(LChannels));
end;

procedure TTestSoundParity.TestFloat;
var
  LChannels: Word;
begin
  for LChannels := 1 to 2 do
    CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(3, LChannels, 32),
      TSoundTestWavFile.FloatPayload(LChannels * 301, LChannels, False, False)),
      'float ' + IntToStr(LChannels));
end;

procedure TTestSoundParity.TestDouble;
var
  LChannels: Word;
begin
  for LChannels := 1 to 2 do
    CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(3, LChannels, 64),
      TSoundTestWavFile.FloatPayload(LChannels * 301, LChannels, True, False)),
      'double ' + IntToStr(LChannels));
end;

procedure TTestSoundParity.TestMuLaw;
var
  LPayload: TBytes;
  LIndex: Integer;
begin
  SetLength(LPayload, 512);
  for LIndex := 0 to 511 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(7, 1, 8), LPayload), 'mulaw mono');
  CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(7, 2, 8), LPayload), 'mulaw stereo');
  SetLength(LPayload, 301);
  CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(7, 1, 8), LPayload), 'mulaw odd');
end;

procedure TTestSoundParity.TestALaw;
var
  LPayload: TBytes;
  LIndex: Integer;
begin
  SetLength(LPayload, 512);
  for LIndex := 0 to 511 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(6, 1, 8), LPayload), 'alaw mono');
  CheckSame(TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(6, 2, 8), LPayload), 'alaw stereo');
end;

procedure TTestSoundParity.TestBigEndian;
var
  LOptions: TSoundTestWavOptions;
begin
  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LOptions.BigEndian := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(4 * 301, 1)), 'rifx pcm16');

  LOptions := TSoundTestWavOptions.Plain(1, 1, 24);
  LOptions.BigEndian := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(3 * 301, 2)), 'rifx pcm24');

  LOptions := TSoundTestWavOptions.Plain(1, 1, 32);
  LOptions.BigEndian := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(4 * 301, 3)), 'rifx pcm32');

  LOptions := TSoundTestWavOptions.Plain(3, 2, 32);
  LOptions.BigEndian := True;
  CheckSame(TSoundTestWavFile.Build(LOptions,
    TSoundTestWavFile.FloatPayload(2 * 301, 4, False, True)), 'rifx float');

  LOptions := TSoundTestWavOptions.Plain(3, 1, 64);
  LOptions.BigEndian := True;
  CheckSame(TSoundTestWavFile.Build(LOptions,
    TSoundTestWavFile.FloatPayload(301, 5, True, True)), 'rifx double');
end;

procedure TTestSoundParity.TestExtensible;
var
  LOptions: TSoundTestWavOptions;
begin
  LOptions := TSoundTestWavOptions.Plain(1, 2, 24);
  LOptions.Extensible := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(6 * 301, 1)), 'wavex pcm24');

  LOptions := TSoundTestWavOptions.Plain(1, 1, 16);
  LOptions.Extensible := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(2 * 301, 2)), 'wavex pcm16');

  LOptions := TSoundTestWavOptions.Plain(3, 2, 32);
  LOptions.Extensible := True;
  CheckSame(TSoundTestWavFile.Build(LOptions,
    TSoundTestWavFile.FloatPayload(2 * 301, 3, False, False)), 'wavex float');

  LOptions := TSoundTestWavOptions.Plain(3, 1, 64);
  LOptions.Extensible := True;
  CheckSame(TSoundTestWavFile.Build(LOptions,
    TSoundTestWavFile.FloatPayload(301, 4, True, False)), 'wavex double');
end;

procedure TTestSoundParity.TestChunksAroundTheData;
var
  LOptions: TSoundTestWavOptions;
begin
  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LOptions.JunkBeforeFormat := True;
  LOptions.ChunkAfterData := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(4 * 100, 1)), 'junk and list');
end;

procedure TTestSoundParity.TestDataLargerThanTheFile;
var
  LOptions: TSoundTestWavOptions;
begin
  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LOptions.DataSize := 1000000;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(4 * 100, 1)), 'data too large');
end;

procedure TTestSoundParity.TestOddDataSize;
var
  LOptions: TSoundTestWavOptions;
begin
  LOptions := TSoundTestWavOptions.Plain(1, 1, 8);
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(101, 1)), 'odd 8 bit');
  LOptions := TSoundTestWavOptions.Plain(1, 1, 16);
  LOptions.ChunkAfterData := True;
  CheckSame(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(101, 2)), 'odd 16 bit');
end;

procedure TTestSoundParity.TestDamagedFiles;
var
  LOptions: TSoundTestWavOptions;
  LFile: TBytes;
begin
  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LOptions.OmitData := True;
  CheckSameFailure(TSoundTestWavFile.Build(LOptions, nil), 'no data chunk');

  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LOptions.OmitFormat := True;
  CheckSameFailure(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(40, 1)), 'no fmt chunk');

  LOptions := TSoundTestWavOptions.Plain(1, 0, 16);
  CheckSameFailure(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(40, 1)), 'zero channels');

  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LOptions.FormatSize := 14;
  CheckSameFailure(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(40, 1)), 'short fmt chunk');

  LOptions := TSoundTestWavOptions.Plain(1, 2, 16);
  LFile := TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(40, 1));
  SetLength(LFile, 30);
  CheckSameFailure(LFile, 'cut inside the fmt chunk');

  LOptions := TSoundTestWavOptions.Plain(1, 1, 0);
  CheckSameFailure(TSoundTestWavFile.Build(LOptions, TSoundTestWavFile.RandomBytes(40, 1)), 'zero bits');
end;

procedure TTestSoundParity.TestNotASound;
begin
  CheckSameFailure(TSoundTestWavFile.RandomBytes(500, 1), 'noise');
  CheckSameFailure(TBytes.Create(1, 2, 3), 'three bytes');
end;

procedure TTestSoundParity.TestAiffPcm;
var
  LChannels, LBits: Word;
begin
  for LBits := 1 to 4 do
    for LChannels := 1 to 2 do
      // Whole frames plus one byte
      CheckSame(TSoundTestContainerFile.BuildAiff(
        TSoundTestAiffOptions.Plain(LChannels, LBits * 8),
        TSoundTestWavFile.RandomBytes(LChannels * LBits * 150 + 1, LBits)),
        Format('aiff pcm %d bits %d channels', [LBits * 8, LChannels]));
  // A sample size between the usual ones is stored in the next width
  CheckSame(TSoundTestContainerFile.BuildAiff(TSoundTestAiffOptions.Plain(2, 12),
    TSoundTestWavFile.RandomBytes(2 * 2 * 60, 9)), 'aiff 12 bits');
end;

procedure TTestSoundParity.TestAiffCompressedPcm;
const
  ENCODINGS: array[0..6] of AnsiString = ('NONE', 'twos', 'sowt', 'in24', '42ni', 'in32', '23ni');
  BITS: array[0..6] of Word = (16, 16, 16, 24, 24, 32, 32);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ENCODINGS) do
    CheckSame(TSoundTestContainerFile.BuildAiff(
      TSoundTestAiffOptions.Compressed(ENCODINGS[LIndex], 2, BITS[LIndex]),
      TSoundTestWavFile.RandomBytes(2 * (BITS[LIndex] div 8) * 90 + 3, LIndex)),
      'aifc ' + string(ENCODINGS[LIndex]));
end;

procedure TTestSoundParity.TestAiffFloatAndCompanded;
var
  LOptions: TSoundTestAiffOptions;
  LPayload: TBytes;
  LIndex: Integer;
  LEncoding: AnsiString;
begin
  CheckSame(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('fl32', 2, 32),
    TSoundTestWavFile.FloatPayload(200, 1, False, True)), 'aifc fl32');
  // Files that say 16 bits for a float
  CheckSame(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('FL32', 1, 16),
    TSoundTestWavFile.FloatPayload(100, 2, False, True)), 'aifc FL32 wrong size');
  CheckSame(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('fl64', 1, 64),
    TSoundTestWavFile.FloatPayload(100, 3, True, True)), 'aifc fl64');
  CheckSame(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('FL64', 2, 8),
    TSoundTestWavFile.FloatPayload(100, 4, True, True)), 'aifc FL64 wrong size');

  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  for LEncoding in ['ulaw', 'ULAW', 'alaw', 'ALAW'] do
  begin
    LOptions := TSoundTestAiffOptions.Compressed(LEncoding, 2, 8);
    CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc ' + string(LEncoding));
  end;
  CheckSame(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('raw ', 1, 8), LPayload), 'aifc raw');
end;

procedure TTestSoundParity.TestAiffChunks;
var
  LOptions: TSoundTestAiffOptions;
  LPayload: TBytes;
begin
  LPayload := TSoundTestWavFile.RandomBytes(2 * 101, 1);

  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.ChunksBeforeData := True;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff chunks before the data');

  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.ChunkAfterData := True;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff chunk after the data');

  LOptions := TSoundTestAiffOptions.Plain(2, 16);
  LOptions.ChunksBeforeData := True;
  LOptions.ChunkAfterData := True;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(4 * 50, 2)),
    'aiff chunks around the data');

  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.SsndOffset := 6;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff ssnd offset');
end;

procedure TTestSoundParity.TestAiffSizes;
var
  LOptions: TSoundTestAiffOptions;
  LPayload: TBytes;
begin
  LPayload := TSoundTestWavFile.RandomBytes(2 * 101, 1);

  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.SsndSize := 8 + 100;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff short ssnd');

  LOptions.SsndSize := 100000;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff long ssnd');

  LOptions.SsndSize := 3;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff tiny ssnd');

  LOptions := TSoundTestAiffOptions.Plain(2, 24);
  LOptions.SsndSize := 8 + 6 * 20;
  LOptions.ChunkAfterData := True;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(6 * 40, 3)),
    'aiff short ssnd with a chunk after');
end;

procedure TTestSoundParity.TestAiffDamaged;
var
  LOptions: TSoundTestAiffOptions;
begin
  LOptions := TSoundTestAiffOptions.Plain(0, 16);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'aiff zero channels');
  LOptions := TSoundTestAiffOptions.Plain(5000, 16);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'aiff too many channels');
  LOptions := TSoundTestAiffOptions.Plain(1, 4);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'aiff 4 bits');
  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.OmitComm := True;
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'aiff without COMM');
  LOptions := TSoundTestAiffOptions.Compressed('xxxx', 1, 16);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'aifc unknown encoding');
  LOptions := TSoundTestAiffOptions.Compressed('raw ', 1, 16);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'aifc raw with 16 bits');
end;

procedure TTestSoundParity.TestAvr;
var
  LStereo: Word;
begin
  for LStereo := 0 to 1 do
  begin
    CheckSame(TSoundTestContainerFile.BuildAvr(LStereo * $FFFF, 8, 0, 11025,
      TSoundTestWavFile.RandomBytes(301, 1)), 'avr unsigned 8 bit');
    CheckSame(TSoundTestContainerFile.BuildAvr(LStereo * $FFFF, 8, $FFFF, 22050,
      TSoundTestWavFile.RandomBytes(301, 2)), 'avr signed 8 bit');
    CheckSame(TSoundTestContainerFile.BuildAvr(LStereo * $FFFF, 16, $FFFF, 44100,
      TSoundTestWavFile.RandomBytes(4 * 150 + 1, 3)), 'avr 16 bit');
  end;
end;

procedure TTestSoundParity.TestHtk;
begin
  CheckSame(TSoundTestContainerFile.BuildHtk(-1, 625, $20000, TSoundTestWavFile.RandomBytes(400, 1)),
    'htk 16 kHz');
  CheckSame(TSoundTestContainerFile.BuildHtk(-1, 0, $20000, TSoundTestWavFile.RandomBytes(400, 2)),
    'htk no period');
  CheckSame(TSoundTestContainerFile.BuildHtk(-1, 1250, $20000, TSoundTestWavFile.RandomBytes(2, 3)),
    'htk one sample');
end;

procedure TTestSoundParity.TestSimpleFormatsDamaged;
begin
  CheckSameFailure(TSoundTestContainerFile.BuildAvr(0, 12, 0, 8000,
    TSoundTestWavFile.RandomBytes(100, 1)), 'avr bad resolution');
  CheckSameFailure(TSoundTestContainerFile.BuildAvr(0, 16, 0, 8000,
    TSoundTestWavFile.RandomBytes(100, 1)), 'avr unsigned 16 bit');
  CheckSameFailure(TSoundTestContainerFile.BuildHtk(-1, 625, $20001,
    TSoundTestWavFile.RandomBytes(400, 1)), 'htk not a waveform');
  CheckSameFailure(TSoundTestContainerFile.BuildHtk(50, 625, $20000,
    TSoundTestWavFile.RandomBytes(400, 1)), 'htk wrong length');
end;

procedure TTestSoundParity.TestInvalidSampleRate;
begin
  // sf_open refuses a sound whose rate is not positive, whatever the format
  CheckSameFailure(TSoundTestContainerFile.BuildAvr(0, 8, 0, 0,
    TSoundTestWavFile.RandomBytes(100, 1)), 'avr rate 0');
end;

procedure TTestSoundParity.TestAuPcm;
var
  LBig: Boolean;
  LCode, LChannels: Cardinal;
  LOptions: TSoundTestAuOptions;
  LBytes: Integer;
begin
  for LBig := False to True do
    for LCode := 2 to 5 do
      for LChannels := 1 to 2 do
      begin
        LOptions := TSoundTestAuOptions.Plain(LCode, LChannels);
        LOptions.BigEndian := LBig;
        // 1, 2, 3 and 4 bytes per sample; one byte more than a whole number of frames
        if LCode = 2 then
          LBytes := 1
        else
          LBytes := Integer(LCode) - 1;
        CheckSame(TSoundTestContainerFile.BuildAu(LOptions,
          TSoundTestWavFile.RandomBytes(Integer(LChannels) * LBytes * 150 + 1, LCode)),
          Format('au pcm code %d channels %d big %s', [LCode, LChannels, BoolToStr(LBig, True)]));
      end;
end;

procedure TTestSoundParity.TestAuFloatAndCompanded;
var
  LBig: Boolean;
  LOptions: TSoundTestAuOptions;
  LPayload: TBytes;
  LIndex: Integer;
begin
  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  for LBig := False to True do
  begin
    LOptions := TSoundTestAuOptions.Plain(6, 2);
    LOptions.BigEndian := LBig;
    CheckSame(TSoundTestContainerFile.BuildAu(LOptions,
      TSoundTestWavFile.FloatPayload(200, 1, False, LBig)), 'au float');

    LOptions := TSoundTestAuOptions.Plain(7, 1);
    LOptions.BigEndian := LBig;
    CheckSame(TSoundTestContainerFile.BuildAu(LOptions,
      TSoundTestWavFile.FloatPayload(100, 2, True, LBig)), 'au double');

    LOptions := TSoundTestAuOptions.Plain(1, 1);
    LOptions.BigEndian := LBig;
    CheckSame(TSoundTestContainerFile.BuildAu(LOptions, LPayload), 'au mulaw');

    LOptions := TSoundTestAuOptions.Plain(27, 2);
    LOptions.BigEndian := LBig;
    CheckSame(TSoundTestContainerFile.BuildAu(LOptions, LPayload), 'au alaw');
  end;
end;

procedure TTestSoundParity.TestAuSizes;
var
  LOptions: TSoundTestAuOptions;
  LPayload: TBytes;
begin
  LPayload := TSoundTestWavFile.RandomBytes(2 * 101, 1);

  LOptions := TSoundTestAuOptions.Plain(3, 1);
  LOptions.BigEndian := True;
  LOptions.DataSize := -1;
  CheckSame(TSoundTestContainerFile.BuildAu(LOptions, LPayload), 'au unknown size');

  LOptions.DataSize := 100;
  CheckSame(TSoundTestContainerFile.BuildAu(LOptions, LPayload), 'au short size');

  LOptions.DataSize := 100000;
  CheckSame(TSoundTestContainerFile.BuildAu(LOptions, LPayload), 'au long size');

  LOptions.DataSize := -2;
  LOptions.Padding := 8;
  CheckSame(TSoundTestContainerFile.BuildAu(LOptions, LPayload), 'au annotation field');
end;

procedure TTestSoundParity.TestAuDamaged;
var
  LOptions: TSoundTestAuOptions;
begin
  LOptions := TSoundTestAuOptions.Plain(3, 0);
  CheckSameFailure(TSoundTestContainerFile.BuildAu(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'au zero channels');
  LOptions := TSoundTestAuOptions.Plain(99, 1);
  CheckSameFailure(TSoundTestContainerFile.BuildAu(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'au unknown encoding');
  LOptions := TSoundTestAuOptions.Plain(3, 5000);
  CheckSameFailure(TSoundTestContainerFile.BuildAu(LOptions, TSoundTestWavFile.RandomBytes(40, 1)),
    'au too many channels');
end;

procedure TTestSoundParity.TestVocBlocks;
var
  LOptions: TSoundTestVocOptions;
begin
  LOptions := TSoundTestVocOptions.Plain;
  CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(200, 1)), 'voc block 1');

  LOptions.TextBlockFirst := True;
  CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(201, 2)), 'voc text block');

  LOptions := TSoundTestVocOptions.Plain;
  LOptions.Version := $0114;
  CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(50, 3)), 'voc version 1.20');

  LOptions := TSoundTestVocOptions.Plain;
  LOptions.Extended := True;
  CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(100, 4)), 'voc extended mono');
  LOptions.Stereo := True;
  CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(100, 5)), 'voc extended stereo');
end;

procedure TTestSoundParity.TestVocExtendedII;
var
  LOptions: TSoundTestVocOptions;
  LChannels: Byte;
begin
  for LChannels := 1 to 2 do
  begin
    LOptions := TSoundTestVocOptions.Plain;
    LOptions.ExtendedII := True;
    LOptions.Channels := LChannels;

    LOptions.Encoding := 0;
    LOptions.BitsPerSample := 8;
    CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(120, 1)), 'voc ext2 u8');

    LOptions.Encoding := 4;
    LOptions.BitsPerSample := 16;
    CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(120, 2)), 'voc ext2 16 bit');

    // SoX writes encoding 0 for 16 bit
    LOptions.Encoding := 0;
    CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(120, 3)), 'voc ext2 sox 16 bit');

    LOptions.BitsPerSample := 8;
    LOptions.Encoding := 6;
    CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(120, 4)), 'voc ext2 alaw');
    LOptions.Encoding := 7;
    CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(120, 5)), 'voc ext2 mulaw');

    LOptions.OmitTerminator := True;
    CheckSame(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(120, 6)), 'voc ext2 no terminator');
  end;
end;

procedure TTestSoundParity.TestVocDamaged;
var
  LOptions: TSoundTestVocOptions;
  LFile, LMore: TBytes;
begin
  LOptions := TSoundTestVocOptions.Plain;
  LOptions.OmitTerminator := True;
  CheckSameFailure(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(100, 1)),
    'voc truncated');

  LOptions := TSoundTestVocOptions.Plain;
  LOptions.Version := $0100;
  CheckSameFailure(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(100, 1)),
    'voc version');

  LOptions := TSoundTestVocOptions.Plain;
  LFile := TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(100, 1));
  LMore := TSoundTestWavFile.RandomBytes(40, 9);
  SetLength(LFile, Length(LFile) + Length(LMore));
  Move(LMore[0], LFile[Length(LFile) - Length(LMore)], Length(LMore));
  CheckSameFailure(LFile, 'voc more blocks after the sound');

  LOptions := TSoundTestVocOptions.Plain;
  LOptions.ExtendedII := True;
  LOptions.Encoding := 3;
  CheckSameFailure(TSoundTestContainerFile.BuildVoc(LOptions, TSoundTestWavFile.RandomBytes(100, 1)),
    'voc unknown encoding');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSoundParity);

end.
