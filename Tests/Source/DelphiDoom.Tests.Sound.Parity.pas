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
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf,
  DelphiDoom.Tests.Sound.WavFile;

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
  Assert.AreEqual(SNDFILE_OK, AEngine.OpenMemory(@ASource[0], Length(ASource), Result));
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

initialization
  TDUnitX.RegisterTestFixture(TTestSoundParity);

end.
