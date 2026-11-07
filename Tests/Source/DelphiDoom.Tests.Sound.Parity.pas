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
  System.SysUtils, System.Classes, System.StrUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf,
  DelphiDoom.Tests.Sound.WavFile, DelphiDoom.Tests.Sound.ContainerFiles,
  DelphiDoom.Tests.Sound.FlacFile, DelphiDoom.Tests.Sound.VorbisFile, DelphiDoom.Tests.Sound.PafFile, DelphiDoom.Tests.Sound.SdsFile, DelphiDoom.Tests.Sound.XiFile,
  DelphiDoom.Tests.Sound.Digest, DelphiDoom.Tests.Sound.Golden;


type
  /// <summary>
  ///   Opens test sounds with the Pascal engine and requires the same
  ///   description of the sound, the same samples (bit by bit) through every
  ///   Read method and the same results of Seek that libsndfile (C) gave: the
  ///   answers are kept as fingerprints in Tests\Data\sound_golden.txt
  /// </summary>
  [TestFixture]
  [Category('sound')]
  TTestSoundParity = class(TObject)
  private
    FCandidate: ISndfile;
    FGolden: TSoundGolden;
    procedure Match(const AKey: string; const AObserve: TFunc<ISndfile, UInt64>);
    function ObserveInfo(const AEngine: ISndfile; const ASource: TBytes): UInt64;
    function ObserveReads(const AEngine: ISndfile; const ASource: TBytes;
      AKind, AChunk: Integer): UInt64;
    function ObserveSeeks(const AEngine: ISndfile; const ASource: TBytes): UInt64;
    function ObserveStream(const AEngine: ISndfile; const ASource: TBytes;
      AKind: Integer): UInt64;
    function KeyOf(const AName: string; const ASource: TBytes): string;
    procedure CheckSame(const ASource: TBytes; const AName: string);
    procedure CheckSameFailure(const ASource: TBytes; const AName: string);
    procedure CheckSameStream(const ASource: TBytes; const AName: string);
    /// <summary>
    ///   For sounds whose last samples depend on how the reads are cut (DWVW):
    ///   the same description and the same samples read in big chunks
    /// </summary>
    procedure CheckSameBulk(const ASource: TBytes; const AName: string);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
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
    procedure TestAiffImaAdpcm;
    [Test]
    procedure TestAiffOtherChunks;
    [Test]
    procedure TestAiffCommVariants;
    [Test]
    procedure TestW64;
    [Test]
    procedure TestRf64;
    [Test]
    procedure TestCaf;
    [Test]
    procedure TestSvx;
    [Test]
    procedure TestIrcam;
    [Test]
    procedure TestMat4;
    [Test]
    procedure TestMat5;
    [Test]
    procedure TestWve;
    [Test]
    procedure TestMpc2k;
    [Test]
    procedure TestMsAdpcm;
    [Test]
    procedure TestImaAdpcm;
    [Test]
    procedure TestGsm610;
    [Test]
    procedure TestG72x;
    [Test]
    procedure TestDwvw;
    [Test]
    procedure TestFlac;
    [Test]
    procedure TestFlacDamaged;
    [Test]
    procedure TestId3Tag;
    [Test]
    procedure TestXi;
    [Test]
    procedure TestSds;
    [Test]
    procedure TestPaf;
    [Test]
    procedure TestVorbis;
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
  DelphiDoom.Sound.Factory;

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

procedure TTestSoundParity.SetupFixture;
begin
  FGolden := TSoundGolden.Create;
end;

procedure TTestSoundParity.TearDownFixture;
begin
  FreeAndNil(FGolden);
end;

procedure TTestSoundParity.Setup;
begin
  FCandidate := TSoundFactory.CreateEngine;
end;

procedure TTestSoundParity.TearDown;
begin
  FCandidate := nil;
end;

function TTestSoundParity.KeyOf(const AName: string; const ASource: TBytes): string;
var
  LDigest: TSoundDigest;
begin
  // Several tests give the same name to sounds that differ
  LDigest := TSoundDigest.Start;
  if Length(ASource) > 0 then
    LDigest.AddBuffer(@ASource[0], Length(ASource));
  Result := AName + '#' + IntToHex(LDigest.Value shr 32, 8);
end;

procedure TTestSoundParity.Match(const AKey: string;
  const AObserve: TFunc<ISndfile, UInt64>);
var
  LActual, LExpected: UInt64;
begin
  LActual := AObserve(FCandidate);
  LExpected := FGolden.Get(AKey);
  Assert.IsTrue(LExpected = LActual,
    Format('%s: the sound differs from the one libsndfile gives (%s, expected %s)',
      [AKey, IntToHex(LActual, 16), IntToHex(LExpected, 16)]));
end;

function TTestSoundParity.ObserveInfo(const AEngine: ISndfile;
  const ASource: TBytes): UInt64;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
  LDigest: TSoundDigest;
  LCode: Integer;
begin
  LDigest := TSoundDigest.Start;
  LCode := AEngine.OpenMemory(@ASource[0], Length(ASource), LSound);
  LDigest.AddInt64(LCode);
  if LCode = SNDFILE_OK then
  begin
    LSound.GetInfo(LInfo);
    LDigest.AddInt64(LInfo.Frames);
    LDigest.AddInt64(LInfo.SampleRate);
    LDigest.AddInt64(LInfo.Channels);
    LDigest.AddInt64(Integer(LInfo.Format));
    LDigest.AddInt64(LInfo.Sections);
    LDigest.AddInt64(LInfo.Seekable);
  end;
  Result := LDigest.Value;
end;

function TTestSoundParity.ObserveReads(const AEngine: ISndfile;
  const ASource: TBytes; AKind, AChunk: Integer): UInt64;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
  LBuffer: TBytes;
  LDigest: TSoundDigest;
  LRead: Int64;
  LCode, LRound: Integer;
begin
  LDigest := TSoundDigest.Start;
  LCode := AEngine.OpenMemory(@ASource[0], Length(ASource), LSound);
  LDigest.AddInt64(LCode);
  if LCode <> SNDFILE_OK then
    Exit(LDigest.Value);
  LSound.GetInfo(LInfo);
  SetLength(LBuffer, AChunk * LInfo.Channels * BytesPerItem(AKind));
  // Always one more read than needed, to see the end of the sound
  for LRound := 0 to Integer(LInfo.Frames div AChunk) + 1 do
  begin
    FillChar(LBuffer[0], Length(LBuffer), $5A);
    LCode := ReadKind(LSound, AKind, @LBuffer[0], AChunk, LRead);
    LDigest.AddInt64(LCode);
    LDigest.AddInt64(LRead);
    LDigest.AddBuffer(@LBuffer[0], Length(LBuffer));
  end;
  Result := LDigest.Value;
end;

function TTestSoundParity.ObserveSeeks(const AEngine: ISndfile;
  const ASource: TBytes): UInt64;
const
  CASES: array[0..9, 0..1] of Integer = (
    (0, SNDFILE_SEEK_SET), (3, SNDFILE_SEEK_SET), (1, SNDFILE_SEEK_CUR),
    (-1, SNDFILE_SEEK_CUR), (0, SNDFILE_SEEK_END), (-2, SNDFILE_SEEK_END),
    (1, SNDFILE_SEEK_END), (-1, SNDFILE_SEEK_SET), (1000000, SNDFILE_SEEK_SET),
    (0, 7));
var
  LSound: ISoundFile;
  LDigest: TSoundDigest;
  LIndex, LCode: Integer;
  LPosition, LRead: Int64;
  LShort: array[0..15] of SmallInt;
begin
  LDigest := TSoundDigest.Start;
  LCode := AEngine.OpenMemory(@ASource[0], Length(ASource), LSound);
  LDigest.AddInt64(LCode);
  if LCode <> SNDFILE_OK then
    Exit(LDigest.Value);
  for LIndex := 0 to High(CASES) do
  begin
    LCode := LSound.Seek(CASES[LIndex, 0], CASES[LIndex, 1], LPosition);
    LDigest.AddInt64(Ord(LCode = SNDFILE_OK));
    LDigest.AddInt64(LPosition);
    // And what is read afterwards (when the sound is mono or stereo)
    FillChar(LShort, SizeOf(LShort), 0);
    LSound.ReadShort(@LShort, 1, LRead);
    LDigest.AddInt64(LRead);
    LDigest.AddBuffer(@LShort, SizeOf(LShort));
  end;
  Result := LDigest.Value;
end;

function TTestSoundParity.ObserveStream(const AEngine: ISndfile;
  const ASource: TBytes; AKind: Integer): UInt64;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
  LDigest: TSoundDigest;
  LBuffer: array[0..2047] of Double;
  LRead: Int64;
  LCode, LRound: Integer;
begin
  LDigest := TSoundDigest.Start;
  LCode := AEngine.OpenMemory(@ASource[0], Length(ASource), LSound);
  LDigest.AddInt64(LCode);
  if LCode <> SNDFILE_OK then
    Exit(LDigest.Value);
  LSound.GetInfo(LInfo);
  LDigest.AddInt64(LInfo.Frames);
  LDigest.AddInt64(Integer(LInfo.Format));
  // A sound of unknown length: read it until it has nothing more, in chunks of 100 frames
  for LRound := 0 to 5000 do
  begin
    FillChar(LBuffer, SizeOf(LBuffer), $5A);
    ReadKind(LSound, AKind, @LBuffer, 100, LRead);
    LDigest.AddInt64(LRead);
    LDigest.AddBuffer(@LBuffer, SizeOf(LBuffer));
    if LRead = 0 then
      Break;
  end;
  Result := LDigest.Value;
end;

procedure TTestSoundParity.CheckSame(const ASource: TBytes; const AName: string);
var
  LKind, LChunk: Integer;
begin
  Match(KeyOf(AName, ASource) + '|info', function(AEngine: ISndfile): UInt64
    begin
      Result := ObserveInfo(AEngine, ASource);
    end);
  for LKind := KIND_SHORT to KIND_DOUBLE do
    for LChunk in [1, 7, 4096] do
      Match(Format('%s|reads %d %d', [KeyOf(AName, ASource), LKind, LChunk]), function(AEngine: ISndfile): UInt64
        begin
          Result := ObserveReads(AEngine, ASource, LKind, LChunk);
        end);
  Match(KeyOf(AName, ASource) + '|seeks', function(AEngine: ISndfile): UInt64
    begin
      Result := ObserveSeeks(AEngine, ASource);
    end);
end;

procedure TTestSoundParity.CheckSameBulk(const ASource: TBytes;
  const AName: string);
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
  LKind: Integer;
begin
  Match(KeyOf(AName, ASource) + '|info', function(AEngine: ISndfile): UInt64
    begin
      Result := ObserveInfo(AEngine, ASource);
    end);
  Assert.AreEqual(SNDFILE_OK, FCandidate.OpenMemory(@ASource[0], Length(ASource), LSound), AName + ': open');
  LSound.GetInfo(LInfo);
  LSound := nil;
  for LKind := KIND_SHORT to KIND_DOUBLE do
    // Exactly the sound: what a longer read leaves past it is whatever the C buffers held
    Match(Format('%s|bulk %d', [KeyOf(AName, ASource), LKind]), function(AEngine: ISndfile): UInt64
      begin
        Result := ObserveReads(AEngine, ASource, LKind, Integer(LInfo.Frames));
      end);
end;

procedure TTestSoundParity.CheckSameStream(const ASource: TBytes;
  const AName: string);
var
  LKind: Integer;
begin
  for LKind := KIND_SHORT to KIND_DOUBLE do
    Match(Format('%s|stream %d', [KeyOf(AName, ASource), LKind]), function(AEngine: ISndfile): UInt64
      begin
        Result := ObserveStream(AEngine, ASource, LKind);
      end);
end;

procedure TTestSoundParity.CheckSameFailure(const ASource: TBytes;
  const AName: string);
var
  LSound: ISoundFile;
begin
  LSound := nil;
  Assert.AreNotEqual(SNDFILE_OK, FCandidate.OpenMemory(@ASource[0], Length(ASource), LSound),
    AName + ': the Pascal engine should refuse the file');
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

procedure TTestSoundParity.TestAiffImaAdpcm;
var
  LOptions: TSoundTestAiffOptions;
  LChannels: Word;
begin
  // Blocks of 34 bytes per channel
  for LChannels := 1 to 2 do
  begin
    LOptions := TSoundTestAiffOptions.Compressed('ima4', LChannels, 16);
    CheckSame(TSoundTestContainerFile.BuildAiff(LOptions,
      TSoundTestWavFile.RandomBytes(34 * LChannels * 7, 30 + LChannels)),
      Format('aifc ima4 %d channels', [LChannels]));
  end;
  // A piece of a block at the end: libsndfile fills the rest of it with the
  // bytes left in its buffer by the block read before, which after a seek are
  // those of another block. The Pascal decoder reads the sound once, in order,
  // so only the reads from the start are the same
  LOptions := TSoundTestAiffOptions.Compressed('ima4', 1, 16);
  CheckSameBulk(TSoundTestContainerFile.BuildAiff(LOptions,
    TSoundTestWavFile.RandomBytes(34 * 7 + 20, 31)), 'aifc ima4 piece of a block');
  // An odd number of blocks in stereo, and a chunk after the data
  LOptions := TSoundTestAiffOptions.Compressed('ima4', 2, 16);
  LOptions.ChunkAfterData := True;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(34 * 5, 33)),
    'aifc ima4 odd blocks');
  LOptions := TSoundTestAiffOptions.Compressed('ima4', 3, 16);
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, TSoundTestWavFile.RandomBytes(34 * 6, 34)),
    'aifc ima4 3 channels');
end;

function TextBytes(const AText: AnsiString): TBytes;
begin
  SetLength(Result, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], Result[0], Length(AText));
end;

function BigEndianBytes(AValue: Cardinal; ACount: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(AValue shr (8 * (ACount - 1 - LIndex)));
end;

procedure TTestSoundParity.TestAiffOtherChunks;
var
  LPayload, LMark, LPeak: TBytes;
  LIndex: Integer;
  LOptions: TSoundTestAiffOptions;

  procedure Check(const AName: string; const ABefore, AAfter: TBytes; AChannels: Word = 1;
    ARefused: Boolean = False);
  var
    LChunkOptions: TSoundTestAiffOptions;
  begin
    LChunkOptions := TSoundTestAiffOptions.Plain(AChannels, 16);
    LChunkOptions.ChunksBeforeComm := ABefore;
    LChunkOptions.ChunksAfterComm := AAfter;
    if ARefused then
      CheckSameFailure(TSoundTestContainerFile.BuildAiff(LChunkOptions, LPayload), AName)
    else
      CheckSame(TSoundTestContainerFile.BuildAiff(LChunkOptions, LPayload), AName);
  end;

  procedure Refused(const AName: string; const AAfter: TBytes);
  begin
    Check(AName, nil, AAfter, 1, True);
  end;

begin
  LPayload := TSoundTestWavFile.RandomBytes(2 * 2 * 80, 40);

  // PEAK: after the COMM chunk, version and time, then value and position of
  // each channel. A good one is not here: the C engine the answers were taken
  // from raised an exception in its C runtime while writing the log of it
  LPeak := BigEndianBytes(1, 4) + BigEndianBytes(0, 4) +
    BigEndianBytes(0, 4) + BigEndianBytes(0, 4);
  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.ChunksAfterComm := TSoundTestContainerFile.Chunk('PEAK', Copy(LPeak, 0, 12));
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff peak wrong size');
  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.ChunksBeforeComm := TSoundTestContainerFile.Chunk('PEAK', LPeak);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff peak before comm');

  // Text chunks, short and too long for the buffer of libsndfile
  Check('aiff text chunks', nil,
    TSoundTestContainerFile.Chunk('(c) ', TextBytes('2026')) +
    TSoundTestContainerFile.Chunk('AUTH', TextBytes('someone')) +
    TSoundTestContainerFile.Chunk('NAME', TextBytes('x')) +
    TSoundTestContainerFile.Chunk('ANNO', nil));
  Refused('aiff long copyright', TSoundTestContainerFile.Chunk('(c) ', TSoundTestWavFile.RandomBytes(8192, 45)));
  Refused('aiff long auth', TSoundTestContainerFile.Chunk('AUTH', TSoundTestWavFile.RandomBytes(8191, 46)));
  Refused('aiff long name', TSoundTestContainerFile.Chunk('NAME', TSoundTestWavFile.RandomBytes(8190, 47)));

  // COMT: comments with a time, a marker and a text
  Check('aiff comments', nil, TSoundTestContainerFile.Chunk('COMT',
    BigEndianBytes(2, 2) +
    BigEndianBytes(1000, 4) + BigEndianBytes(1, 2) + BigEndianBytes(5, 2) + TextBytes('hello') +
    BigEndianBytes(2000, 4) + BigEndianBytes(2, 2) + BigEndianBytes(3, 2) + TextBytes('abc') + [0]));
  Check('aiff empty comments', nil, TSoundTestContainerFile.Chunk('COMT', nil));
  Refused('aiff comment too long', TSoundTestContainerFile.Chunk('COMT',
    BigEndianBytes(1, 2) + BigEndianBytes(0, 4) + BigEndianBytes(0, 2) + BigEndianBytes(9000, 2) +
    TSoundTestWavFile.RandomBytes(20, 48)));

  // APPL of every size libsndfile tells apart
  Check('aiff appl', nil,
    TSoundTestContainerFile.Chunk('APPL', TextBytes('stoc') + TextBytes('abcde')) +
    TSoundTestContainerFile.Chunk('APPL', TextBytes('ab')) +
    TSoundTestContainerFile.Chunk('APPL', nil));
  Refused('aiff long appl', TSoundTestContainerFile.Chunk('APPL', TSoundTestWavFile.RandomBytes(8191, 49)));

  // INST, basc, FVER, SFX!, CHAN: skipped
  Check('aiff inst', nil, TSoundTestContainerFile.Chunk('INST', TSoundTestWavFile.RandomBytes(20, 50)));
  Check('aiff short inst', nil, TSoundTestContainerFile.Chunk('INST', TSoundTestWavFile.RandomBytes(6, 50)));
  Check('aiff basc', nil, TSoundTestContainerFile.Chunk('basc', TSoundTestWavFile.RandomBytes(54, 51)));
  Check('aiff fver', nil, TSoundTestContainerFile.Chunk('FVER', BigEndianBytes($A2805140, 4)));
  Check('aiff sfx', nil, TSoundTestContainerFile.Chunk('SFX!', TSoundTestWavFile.RandomBytes(6, 52)));
  // CHAN: a layout libsndfile knows (mono) and a chunk too short
  // for one. With a layout it does not know libsndfile reads the rest of the
  // chunk as the next one, while the Pascal decoder skips it whole
  Check('aiff chan', nil, TSoundTestContainerFile.Chunk('CHAN',
    [0, $64, 0, $01] + TSoundTestWavFile.RandomBytes(20, 53)));
  Check('aiff short chan', nil, TSoundTestContainerFile.Chunk('CHAN', TSoundTestWavFile.RandomBytes(8, 53)));

  // MARK: names of odd and even length, a count that is too large
  LMark := BigEndianBytes(3, 2);
  for LIndex := 1 to 3 do
    LMark := LMark + BigEndianBytes(LIndex, 2) + BigEndianBytes(LIndex * 100, 4) +
      [Byte(LIndex)] + TSoundTestWavFile.RandomBytes(LIndex + Ord(not Odd(LIndex)), 54 + LIndex);
  Check('aiff markers', nil, TSoundTestContainerFile.Chunk('MARK', LMark));
  Check('aiff too many markers', nil, TSoundTestContainerFile.Chunk('MARK',
    BigEndianBytes(2000, 2) + TSoundTestWavFile.RandomBytes(10, 58)));
  Check('aiff markers cut', nil, TSoundTestContainerFile.Chunk('MARK',
    BigEndianBytes(5, 2) + BigEndianBytes(1, 2) + BigEndianBytes(7, 4) + [2] + TextBytes('ab') + [0]));

  // The NONE chunk of broken AIFC files, unknown chunks, garbage and huge sizes
  Check('aiff none chunk', nil, TSoundTestContainerFile.Chunk('NONE', nil, $07000000) +
    TSoundTestWavFile.RandomBytes(4, 59));
  Check('aiff unknown chunk', nil, TSoundTestContainerFile.Chunk('wxyz', TSoundTestWavFile.RandomBytes(10, 60)));
  Refused('aiff huge unknown chunk', TSoundTestContainerFile.Chunk('wxyz', nil, $FFFF0001));
  Refused('aiff garbage aligned', [1, 2, 3, 4, 0, 0, 0, 4, 9, 9, 9, 9]);
  Refused('aiff garbage unaligned', [1, 2, 3, 4, 0, 0, 0, 4, 9, 9, 9, 9, 7]);
  Refused('aiff two forms', TextBytes('FORM') + BigEndianBytes(4, 4) + TextBytes('AIFF'));
end;

procedure TTestSoundParity.TestAiffCommVariants;
const
  RATES: array[0..4, 0..9] of Byte = (
    ($C0, $0E, $AC, $44, 0, 0, 0, 0, 0, 0),
    ($3F, $FF, $80, 0, 0, 0, 0, 0, 0, 0),
    ($41, $0E, $AC, $44, 0, 0, 0, 0, 0, 0),
    ($40, $1D, $AC, $44, 0, 0, 0, 0, 0, 0),
    ($40, $0B, $FA, 0, 0, 0, 0, 0, 0, 0));
var
  LOptions: TSoundTestAiffOptions;
  LPayload: TBytes;
  LIndex: Integer;
begin
  LPayload := TSoundTestWavFile.RandomBytes(2 * 120, 61);

  // Rates that are negative, below 1, too large, and an ordinary one
  for LIndex := 0 to High(RATES) do
  begin
    LOptions := TSoundTestAiffOptions.Plain(1, 16);
    SetLength(LOptions.Rate, 10);
    Move(RATES[LIndex, 0], LOptions.Rate[0], 10);
    // libsndfile refuses a rate that is not positive
    if LIndex = 0 then
      CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), Format('aiff rate %d', [LIndex]))
    else
      CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), Format('aiff rate %d', [LIndex]));
  end;

  // AIFC with the encoding and no name
  LOptions := TSoundTestAiffOptions.Compressed('sowt', 1, 16);
  LOptions.CommWithoutName := True;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc comm without name');

  // Refused by libsndfile too: a COMM size written with the bytes swapped (the
  // size is turned back, but the chunk is then read as a longer one), a name
  // longer than its buffer, a size between the AIFF and the AIFC one, no SSND
  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.CommSize := $12000000;
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff swapped comm size');

  LOptions := TSoundTestAiffOptions.Compressed('twos', 1, 16);
  LOptions.CommSize := 9000;
  LOptions.ChunksAfterComm := TSoundTestWavFile.RandomBytes(9000 - 24, 62);
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc long comm');

  LOptions := TSoundTestAiffOptions.Compressed('twos', 1, 16);
  LOptions.CommSize := 20;
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc comm of 20 bytes');

  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.OmitSsnd := True;
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aiff without ssnd');

  // The data starts past the end of the file
  LOptions := TSoundTestAiffOptions.Plain(1, 16);
  LOptions.SsndOffset := 4;
  LOptions.SsndSize := 8;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, nil), 'aiff offset past the data');
end;

procedure TTestSoundParity.TestW64;
var
  LChannels, LBits: Word;
  LPayload: TBytes;
  LIndex: Integer;
begin
  for LBits in [8, 16, 24, 32] do
    for LChannels := 1 to 2 do
      CheckSame(TSoundTestContainerFile.BuildW64(1, LChannels, LBits, 22050, False, False,
        TSoundTestWavFile.RandomBytes(LChannels * (LBits div 8) * 101 + 1, LBits)),
        Format('w64 pcm %d bits %d channels', [LBits, LChannels]));
  CheckSame(TSoundTestContainerFile.BuildW64(3, 2, 32, 44100, True, False,
    TSoundTestWavFile.FloatPayload(150, 1, False, False)), 'w64 float with fact');
  CheckSame(TSoundTestContainerFile.BuildW64(3, 1, 64, 44100, True, True,
    TSoundTestWavFile.FloatPayload(100, 2, True, False)), 'w64 double with junk');

  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestContainerFile.BuildW64(7, 2, 8, 8000, False, False, LPayload), 'w64 mulaw');
  CheckSame(TSoundTestContainerFile.BuildW64(6, 1, 8, 8000, True, False, LPayload), 'w64 alaw');
  // Float with an odd width is still float
  CheckSame(TSoundTestContainerFile.BuildW64(3, 1, 32, 8000, False, True,
    TSoundTestWavFile.FloatPayload(50, 3, False, False)), 'w64 float with junk');
  CheckSameFailure(TSoundTestContainerFile.BuildW64(1, 0, 16, 8000, False, False, LPayload), 'w64 no channels');
  CheckSameFailure(TSoundTestContainerFile.BuildW64(1, 1, 40, 8000, False, False, LPayload), 'w64 40 bits');
  CheckSameFailure(TSoundTestContainerFile.BuildW64(1, 1, 16, 0, False, False, LPayload), 'w64 rate 0');
end;

procedure TTestSoundParity.TestRf64;
var
  LChannels, LBits: Word;
  LPayload: TBytes;
  LIndex: Integer;
begin
  for LBits in [8, 16, 24, 32] do
    for LChannels := 1 to 2 do
    begin
      CheckSame(TSoundTestContainerFile.BuildRf64(1, LChannels, LBits, 22050, True, -2,
        TSoundTestWavFile.RandomBytes(LChannels * (LBits div 8) * 101 + 1, LBits)),
        Format('rf64 pcm %d bits %d channels', [LBits, LChannels]));
    end;
  CheckSame(TSoundTestContainerFile.BuildRf64(3, 2, 32, 44100, True, -2,
    TSoundTestWavFile.FloatPayload(150, 1, False, False)), 'rf64 float');
  CheckSame(TSoundTestContainerFile.BuildRf64(3, 1, 64, 44100, True, -2,
    TSoundTestWavFile.FloatPayload(100, 2, True, False)), 'rf64 double');

  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestContainerFile.BuildRf64(7, 2, 8, 8000, True, -2, LPayload), 'rf64 mulaw');
  CheckSame(TSoundTestContainerFile.BuildRf64(6, 1, 8, 8000, True, -2, LPayload), 'rf64 alaw');
  // Sizes that do not agree with the file
  CheckSame(TSoundTestContainerFile.BuildRf64(1, 2, 16, 8000, True, 100, LPayload), 'rf64 short data');
  CheckSame(TSoundTestContainerFile.BuildRf64(1, 2, 16, 8000, True, 100000, LPayload), 'rf64 long data');
  // No ds64 chunk: the size of the data chunk is the real one
  CheckSame(TSoundTestContainerFile.BuildRf64(1, 2, 16, 8000, False, -2, LPayload), 'rf64 without ds64');
  CheckSameFailure(TSoundTestContainerFile.BuildRf64(1, 0, 16, 8000, True, -2, LPayload), 'rf64 no channels');
end;

procedure TTestSoundParity.TestCaf;
var
  LChannels, LBits, LFlags: Cardinal;
  LPayload: TBytes;
  LIndex: Integer;
begin
  for LFlags in [0, 2] do
    for LBits in [8, 16, 24, 32] do
      for LChannels := 1 to 2 do
        CheckSame(TSoundTestContainerFile.BuildCaf('lpcm', LFlags, LChannels * (LBits div 8),
          LChannels, LBits, 44100.0, LBits = 16, LBits = 24,
          TSoundTestWavFile.RandomBytes(Integer(LChannels * (LBits div 8)) * 101 + 1, LBits)),
          Format('caf pcm %d bits %d channels flags %d', [LBits, LChannels, LFlags]));
  CheckSame(TSoundTestContainerFile.BuildCaf('lpcm', 1, 8, 2, 32, 22050.0, False, False,
    TSoundTestWavFile.FloatPayload(150, 1, False, True)), 'caf float');
  CheckSame(TSoundTestContainerFile.BuildCaf('lpcm', 3, 8, 1, 64, 48000.0, True, True,
    TSoundTestWavFile.FloatPayload(100, 2, True, False)), 'caf double little endian');

  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestContainerFile.BuildCaf('ulaw', 0, 2, 2, 8, 8000.0, False, False, LPayload), 'caf ulaw');
  CheckSame(TSoundTestContainerFile.BuildCaf('alaw', 0, 1, 1, 8, 8000.0, False, False, LPayload), 'caf alaw');
  // A rate that is not an integer is rounded
  CheckSame(TSoundTestContainerFile.BuildCaf('lpcm', 0, 2, 1, 16, 11025.6, False, False, LPayload), 'caf rate');

  CheckSameFailure(TSoundTestContainerFile.BuildCaf('lpcm', 0, 2, 0, 16, 8000.0, False, False, LPayload), 'caf no channels');
  CheckSameFailure(TSoundTestContainerFile.BuildCaf('lpcm', 0, 3, 1, 16, 8000.0, False, False, LPayload), 'caf bad packet');
  CheckSameFailure(TSoundTestContainerFile.BuildCaf('zzzz', 0, 2, 1, 16, 8000.0, False, False, LPayload), 'caf unknown');
  CheckSameFailure(TSoundTestContainerFile.BuildCaf('lpcm', 0, 2, 1, 16, 0.0, False, False, LPayload), 'caf rate 0');
end;

procedure TTestSoundParity.TestSvx;
begin
  CheckSame(TSoundTestContainerFile.BuildSvx(False, 8000, 0, False, False,
    TSoundTestWavFile.RandomBytes(301, 1)), 'svx 8 bit');
  CheckSame(TSoundTestContainerFile.BuildSvx(True, 22050, 0, False, False,
    TSoundTestWavFile.RandomBytes(301, 2)), 'svx 16 bit');
  CheckSame(TSoundTestContainerFile.BuildSvx(True, 22050, 0, True, True,
    TSoundTestWavFile.RandomBytes(400, 3)), 'svx stereo with chunks');
  CheckSame(TSoundTestContainerFile.BuildSvx(False, 8000, 0, False, True,
    TSoundTestWavFile.RandomBytes(100, 4)), 'svx with name');
  CheckSameFailure(TSoundTestContainerFile.BuildSvx(False, 8000, 1, False, False,
    TSoundTestWavFile.RandomBytes(100, 5)), 'svx fibonacci');
  CheckSameFailure(TSoundTestContainerFile.BuildSvx(False, 0, 0, False, False,
    TSoundTestWavFile.RandomBytes(100, 5)), 'svx rate 0');
end;

procedure TTestSoundParity.TestIrcam;
const
  LE_MARKER: array[0..3] of Byte = ($00, $01, $A3, $64);
  LE_MARKER_4: array[0..3] of Byte = ($00, $04, $A3, $64);
  BE_MARKER: array[0..3] of Byte = ($64, $A3, $02, $00);
var
  LPayload: TBytes;
  LIndex: Integer;
begin
  CheckSame(TSoundTestContainerFile.BuildIrcam(LE_MARKER, False, 44100.0, 2, $2,
    TSoundTestWavFile.RandomBytes(4 * 101 + 1, 1)), 'ircam 16 bit');
  CheckSame(TSoundTestContainerFile.BuildIrcam(LE_MARKER_4, False, 22050.5, 1, $40004,
    TSoundTestWavFile.RandomBytes(4 * 101, 2)), 'ircam 32 bit');
  CheckSame(TSoundTestContainerFile.BuildIrcam(LE_MARKER, False, 8000.0, 2, $4,
    TSoundTestWavFile.FloatPayload(100, 3, False, False)), 'ircam float');
  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestContainerFile.BuildIrcam(LE_MARKER, False, 8000.0, 2, $10001, LPayload), 'ircam alaw');
  CheckSame(TSoundTestContainerFile.BuildIrcam(LE_MARKER, False, 8000.0, 1, $20001, LPayload), 'ircam ulaw');
  // Fields that are big endian: the channel count tells
  CheckSame(TSoundTestContainerFile.BuildIrcam(LE_MARKER, True, 44100.0, 2, $2,
    TSoundTestWavFile.RandomBytes(4 * 100, 4)), 'ircam big endian fields');

  CheckSameFailure(TSoundTestContainerFile.BuildIrcam(BE_MARKER, True, 44100.0, 2, $2, LPayload), 'ircam big endian marker');
  CheckSameFailure(TSoundTestContainerFile.BuildIrcam(LE_MARKER, False, 44100.0, 2, $99, LPayload), 'ircam unknown encoding');
  CheckSameFailure(TSoundTestContainerFile.BuildIrcam(LE_MARKER, False, 44100.0, 0, $2, LPayload), 'ircam no channels');
end;

procedure TTestSoundParity.TestMat4;
const
  // The type of the matrix as the file has it, for a big endian then a little endian file
  PCM16: array[Boolean, 0..3] of Byte = ((30, 0, 0, 0), (0, 0, 4, 6));
  PCM32: array[Boolean, 0..3] of Byte = ((20, 0, 0, 0), (0, 0, 3, $FC));
  FLOATS: array[Boolean, 0..3] of Byte = ((10, 0, 0, 0), (0, 0, 3, $F2));
  DOUBLES: array[Boolean, 0..3] of Byte = ((0, 0, 0, 0), (0, 0, 3, $E8));
  BAD: array[0..3] of Byte = (50, 0, 0, 0);
var
  LBig: Boolean;
  LChannels: Cardinal;
begin
  for LBig := False to True do
    for LChannels := 1 to 2 do
    begin
      CheckSame(TSoundTestContainerFile.BuildMat4(LBig, 44100.0, LChannels, 101, PCM16[LBig],
        TSoundTestWavFile.RandomBytes(Integer(LChannels) * 2 * 101 + 1, 1)), 'mat4 16 bit');
      CheckSame(TSoundTestContainerFile.BuildMat4(LBig, 22050.0, LChannels, 51, PCM32[LBig],
        TSoundTestWavFile.RandomBytes(Integer(LChannels) * 4 * 51, 2)), 'mat4 32 bit');
      CheckSame(TSoundTestContainerFile.BuildMat4(LBig, 8000.0, LChannels, 60, FLOATS[LBig],
        TSoundTestWavFile.FloatPayload(Integer(LChannels) * 60, 3, False, LBig)), 'mat4 float');
      CheckSame(TSoundTestContainerFile.BuildMat4(LBig, 11025.0, LChannels, 40, DOUBLES[LBig],
        TSoundTestWavFile.FloatPayload(Integer(LChannels) * 40, 4, True, LBig)), 'mat4 double');
    end;
  // Fewer frames in the matrix than in the file, and more
  CheckSame(TSoundTestContainerFile.BuildMat4(False, 8000.0, 1, 20, PCM16[False],
    TSoundTestWavFile.RandomBytes(200, 5)), 'mat4 data after the matrix');
  CheckSame(TSoundTestContainerFile.BuildMat4(True, 8000.0, 1, 500, PCM16[True],
    TSoundTestWavFile.RandomBytes(200, 6)), 'mat4 truncated');
  CheckSameFailure(TSoundTestContainerFile.BuildMat4(False, 8000.0, 0, 20, PCM16[False],
    TSoundTestWavFile.RandomBytes(200, 7)), 'mat4 no channels');
  CheckSameFailure(TSoundTestContainerFile.BuildMat4(False, 8000.0, 2000, 20, PCM16[False],
    TSoundTestWavFile.RandomBytes(200, 7)), 'mat4 too many channels');
  CheckSameFailure(TSoundTestContainerFile.BuildMat4(False, 8000.0, 1, 20, BAD,
    TSoundTestWavFile.RandomBytes(200, 7)), 'mat4 unsigned 8 bit');
end;

procedure TTestSoundParity.TestMat5;
var
  LBig, LSmall: Boolean;
  LChannels, LKind: Cardinal;
begin
  for LBig := False to True do
    for LChannels := 1 to 2 do
    begin
      CheckSame(TSoundTestContainerFile.BuildMat5(LBig, 0, 44100, LChannels, 101, 3, False, False,
        TSoundTestWavFile.RandomBytes(Integer(LChannels) * 2 * 101 + 1, 1)), 'mat5 16 bit');
      CheckSame(TSoundTestContainerFile.BuildMat5(LBig, 0, 22050, LChannels, 51, 5, False, False,
        TSoundTestWavFile.RandomBytes(Integer(LChannels) * 4 * 51, 2)), 'mat5 32 bit');
      CheckSame(TSoundTestContainerFile.BuildMat5(LBig, 0, 8000, LChannels, 60, 2, False, False,
        TSoundTestWavFile.RandomBytes(Integer(LChannels) * 60, 3)), 'mat5 8 bit');
      CheckSame(TSoundTestContainerFile.BuildMat5(LBig, 0, 8000, LChannels, 60, 7, False, False,
        TSoundTestWavFile.FloatPayload(Integer(LChannels) * 60, 3, False, LBig)), 'mat5 float');
      CheckSame(TSoundTestContainerFile.BuildMat5(LBig, 0, 11025, LChannels, 40, 9, False, False,
        TSoundTestWavFile.FloatPayload(Integer(LChannels) * 40, 4, True, LBig)), 'mat5 double');
    end;
  for LKind := 0 to 3 do
    for LSmall := False to True do
      CheckSame(TSoundTestContainerFile.BuildMat5(False, Integer(LKind), 32000, 2, 50, 3, LSmall, False,
        TSoundTestWavFile.RandomBytes(200, 8)), Format('mat5 sample rate kind %d small names %s', [LKind, BoolToStr(LSmall, True)]));
  CheckSameFailure(TSoundTestContainerFile.BuildMat5(False, 0, 44100, 0, 0, 3, False, False,
    TSoundTestWavFile.RandomBytes(100, 9)), 'mat5 empty');
  CheckSameFailure(TSoundTestContainerFile.BuildMat5(False, 0, 44100, 1, 50, 8, False, False,
    TSoundTestWavFile.RandomBytes(100, 9)), 'mat5 unknown type');
  CheckSameFailure(TSoundTestContainerFile.BuildMat5(False, 0, 44100, 1, 50, 3, False, True,
    TSoundTestWavFile.RandomBytes(100, 9)), 'mat5 text without end');
end;

procedure TTestSoundParity.TestWve;
var
  LPayload: TBytes;
  LIndex: Integer;
begin
  SetLength(LPayload, 256);
  for LIndex := 0 to 255 do
    LPayload[LIndex] := Byte(LIndex);
  CheckSame(TSoundTestContainerFile.BuildWve(-2, LPayload), 'wve');
  // A length in the header that is not the real one
  CheckSame(TSoundTestContainerFile.BuildWve(100, LPayload), 'wve wrong length');
  CheckSame(TSoundTestContainerFile.BuildWve(-2, Copy(LPayload, 0, 1)), 'wve one sample');
end;

procedure TTestSoundParity.TestMpc2k;
begin
  CheckSame(TSoundTestContainerFile.BuildMpc2k(False, 44100, TSoundTestWavFile.RandomBytes(2 * 101 + 1, 1)), 'mpc2k mono');
  CheckSame(TSoundTestContainerFile.BuildMpc2k(True, 22050, TSoundTestWavFile.RandomBytes(4 * 101 + 2, 2)), 'mpc2k stereo');
  CheckSameFailure(TSoundTestContainerFile.BuildMpc2k(False, 0, TSoundTestWavFile.RandomBytes(100, 3)), 'mpc2k rate 0');
end;

procedure TTestSoundParity.TestMsAdpcm;
var
  LChannels: Word;
  LBlock: Word;
begin
  for LChannels := 1 to 2 do
  begin
    for LBlock in [256, 512, 134] do
    begin
      // Whole blocks, and then a last one that is cut short
      CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
        TSoundTestContainerFile.AdpcmFormat(2, LChannels, 22050, LBlock,
          2 * (LBlock - 6 * LChannels) div LChannels),
        TSoundTestWavFile.RandomBytes(LBlock * 5, LBlock), False),
        Format('wav ms adpcm %d channels block %d', [LChannels, LBlock]));
    end;
    CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
      TSoundTestContainerFile.AdpcmFormat(2, LChannels, 11025, 256, 2 * (256 - 6 * LChannels) div LChannels),
      TSoundTestWavFile.RandomBytes(256 * 3 + 100, 3), True), 'wav ms adpcm short last block');
    CheckSame(TSoundTestContainerFile.BuildW64WithFormat(
      TSoundTestContainerFile.AdpcmFormat(2, LChannels, 22050, 256, 2 * (256 - 6 * LChannels) div LChannels),
      TSoundTestWavFile.RandomBytes(256 * 4, 4)), 'w64 ms adpcm');
  end;
  CheckSameFailure(TSoundTestContainerFile.BuildWavWithFormat(
    TSoundTestContainerFile.AdpcmFormat(2, 1, 22050, 256, 100), TSoundTestWavFile.RandomBytes(512, 5), False),
    'wav ms adpcm wrong samples per block');
end;

procedure TTestSoundParity.TestImaAdpcm;
var
  LChannels: Word;
  LBlock: Word;
begin
  for LChannels := 1 to 2 do
  begin
    for LBlock in [256, 512, 1024] do
      CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
        TSoundTestContainerFile.AdpcmFormat($11, LChannels, 22050, LBlock,
          2 * (LBlock - 4 * LChannels) div LChannels + 1),
        TSoundTestWavFile.RandomBytes(LBlock * 5, LBlock), False),
        Format('wav ima adpcm %d channels block %d', [LChannels, LBlock]));
    // With a chunk after the sound, the blocks are whole and the data goes on
    CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
      TSoundTestContainerFile.AdpcmFormat($11, LChannels, 11025, 256, 2 * (256 - 4 * LChannels) div LChannels + 1),
      TSoundTestWavFile.RandomBytes(256 * 3, 3), True), 'wav ima adpcm with a chunk after');
    CheckSame(TSoundTestContainerFile.BuildW64WithFormat(
      TSoundTestContainerFile.AdpcmFormat($11, LChannels, 22050, 256, 2 * (256 - 4 * LChannels) div LChannels + 1),
      TSoundTestWavFile.RandomBytes(256 * 4, 4)), 'w64 ima adpcm');
  end;
  CheckSameFailure(TSoundTestContainerFile.BuildWavWithFormat(
    TSoundTestContainerFile.AdpcmFormat($11, 1, 22050, 256, 100), TSoundTestWavFile.RandomBytes(512, 5), False),
    'wav ima adpcm wrong samples per block');
end;

procedure TTestSoundParity.TestGsm610;
var
  LPayload: TBytes;
  LIndex: Integer;
  LOptions: TSoundTestAiffOptions;
begin
  // WAV: blocks of 65 bytes
  CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
    TSoundTestContainerFile.GsmFormat, TSoundTestWavFile.RandomBytes(65 * 6, 1), False), 'wav gsm 610');
  CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
    TSoundTestContainerFile.GsmFormat, TSoundTestWavFile.RandomBytes(65 * 3 + 20, 2), False), 'wav gsm 610 cut block');
  CheckSame(TSoundTestContainerFile.BuildWavWithFormat(
    TSoundTestContainerFile.GsmFormat, TSoundTestWavFile.RandomBytes(65 * 3, 3), True), 'wav gsm 610 chunk after');
  CheckSame(TSoundTestContainerFile.BuildW64WithFormat(
    TSoundTestContainerFile.GsmFormat, TSoundTestWavFile.RandomBytes(65 * 4, 4)), 'w64 gsm 610');

  // AIFF-C: frames of 33 bytes that start with the magic number $D
  LPayload := TSoundTestWavFile.RandomBytes(33 * 7, 5);
  for LIndex := 0 to 6 do
    LPayload[LIndex * 33] := Byte($D0 or (LPayload[LIndex * 33] and $0F));
  LOptions := TSoundTestAiffOptions.Compressed('GSM ', 1, 16);
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc gsm 610');
  // A frame without the magic number repeats the one before
  LPayload[33 * 3] := $00;
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc gsm 610 bad frame');
  LOptions := TSoundTestAiffOptions.Compressed('GSM ', 2, 16);
  CheckSame(TSoundTestContainerFile.BuildAiff(LOptions, LPayload), 'aifc gsm 610 two channels');
end;

procedure TTestSoundParity.TestG72x;
var
  LOptions: TSoundTestAuOptions;
  LBits: Integer;
begin
  // 120 samples make 60, 45 or 75 bytes
  for LBits in [3, 4, 5] do
  begin
    LOptions := TSoundTestAuOptions.Plain(22 + LBits - 2 + Ord(LBits = 5) - Ord(LBits = 4) * 0, 1);
    case LBits of
      3: LOptions := TSoundTestAuOptions.Plain(25, 1);
      4: LOptions := TSoundTestAuOptions.Plain(23, 1);
    else
      LOptions := TSoundTestAuOptions.Plain(26, 1);
    end;
    LOptions.BigEndian := True;
    CheckSame(TSoundTestContainerFile.BuildAu(LOptions,
      TSoundTestWavFile.RandomBytes(LBits * 15 * 5, LBits)), Format('au g72x %d bits', [LBits]));
    CheckSame(TSoundTestContainerFile.BuildAu(LOptions,
      TSoundTestWavFile.RandomBytes(LBits * 15 * 3 + 7, LBits)), Format('au g72x %d bits cut block', [LBits]));
  end;
  CheckSame(TSoundTestContainerFile.BuildWavWithFormat(TSoundTestContainerFile.G721Format,
    TSoundTestWavFile.RandomBytes(60 * 6, 9), False), 'wav g721');
  LOptions := TSoundTestAuOptions.Plain(23, 2);
  CheckSameFailure(TSoundTestContainerFile.BuildAu(LOptions, TSoundTestWavFile.RandomBytes(120, 1)), 'au g721 stereo');
end;

procedure TTestSoundParity.TestDwvw;
var
  LBits: Word;
  LChannels: Word;
  LCode: AnsiString;
begin
  for LBits in [16, 24, 8, 12, 20] do
    for LChannels := 1 to 2 do
    begin
      case LBits of
        16, 24, 12: LCode := 'DWVW';
      else
        LCode := 'DWVW';
      end;
      // Any bytes are a stream for DWVW: the end of it is what shows
      CheckSameBulk(TSoundTestContainerFile.BuildAiff(
        TSoundTestAiffOptions.Compressed(LCode, LChannels, LBits),
        TSoundTestWavFile.RandomBytes(400 + LBits, LBits)), Format('aifc dwvw %d bits %d channels', [LBits, LChannels]));
    end;
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('DWVW', 1, 4), TSoundTestWavFile.RandomBytes(100, 1)), 'aifc dwvw 4 bits');
  CheckSameFailure(TSoundTestContainerFile.BuildAiff(
    TSoundTestAiffOptions.Compressed('DWVW', 1, 28), TSoundTestWavFile.RandomBytes(100, 1)), 'aifc dwvw 28 bits');
end;

function FlacSignals(AChannels, ACount, ABits, AWasted: Integer): TArray<TArray<Integer>>;
var
  LChannel, LIndex: Integer;
begin
  SetLength(Result, AChannels);
  for LChannel := 0 to AChannels - 1 do
  begin
    Result[LChannel] := TSoundTestFlacFile.Signal(ACount, ABits - AWasted, LChannel + 1);
    for LIndex := 0 to ACount - 1 do
      Result[LChannel][LIndex] := Result[LChannel][LIndex] * (1 shl AWasted);
  end;
end;

procedure TTestSoundParity.TestFlac;
var
  LReal: TBytes;
  LSound: ISoundFile;
  LCode: Integer;
  LInfo2: TSoundFileInfo;
  LText: string;
  LVariant: Integer;
  LOptions: TSoundTestFlacOptions;
  LBits, LChannels, LAssignment, LOrder: Integer;
  LSignals: TArray<TArray<Integer>>;
  LKind: TSoundTestFlacSubframe;
begin
  // Depths, channels and the ways to code two channels
  for LBits in [8, 16, 24] do
  begin
    for LChannels := 1 to 3 do
    begin
      LOptions := TSoundTestFlacOptions.Plain;
      LOptions.Channels := LChannels;
      LOptions.BitsPerSample := LBits;
      CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(LChannels, 3000, LBits, 0)),
        Format('flac %d bits %d channels', [LBits, LChannels]));
    end;
    for LAssignment := 1 to 3 do
    begin
      LOptions := TSoundTestFlacOptions.Plain;
      LOptions.Channels := 2;
      LOptions.BitsPerSample := LBits;
      LOptions.Assignment := LAssignment;
      CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 2500, LBits, 0)),
        Format('flac %d bits assignment %d', [LBits, LAssignment]));
    end;
  end;

  // Every kind of subframe
  for LOrder := 0 to 4 do
  begin
    LOptions := TSoundTestFlacOptions.Plain;
    LOptions.Order := LOrder;
    CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 2400, 16, 0)), Format('flac fixed %d', [LOrder]));
  end;
  for LOrder in [1, 2, 4, 8, 12, 32] do
  begin
    LOptions := TSoundTestFlacOptions.Plain;
    LOptions.Subframe := TSoundTestFlacSubframe.Lpc;
    LOptions.Order := LOrder;
    LOptions.BlockSize := 4096;
    CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 9000, 16, 0)), Format('flac lpc %d', [LOrder]));
  end;
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.Subframe := TSoundTestFlacSubframe.Verbatim;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 2000, 16, 0)), 'flac verbatim');
  LOptions.Subframe := TSoundTestFlacSubframe.Constant;
  LSignals := FlacSignals(2, 2000, 16, 0);
  for LChannels := 0 to 1 do
    for LOrder := 0 to 1999 do
      LSignals[LChannels][LOrder] := 1234 * (LChannels + 1);
  CheckSame(TSoundTestFlacFile.Build(LOptions, LSignals), 'flac constant');

  // Residual coding
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.Rice2 := True;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3000, 16, 0)), 'flac rice 2');
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.UseEscape := True;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3000, 16, 0)), 'flac escape');
  for LOrder in [0, 3, 5] do
  begin
    LOptions := TSoundTestFlacOptions.Plain;
    LOptions.PartitionOrder := LOrder;
    // A multiple of 32 samples: the partitions of an uneven block leave samples unwritten
    CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3072, 16, 0)), Format('flac partitions %d', [LOrder]));
  end;

  // Wasted bits, headers that defer to STREAMINFO, odd block sizes and rates
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.WastedBits := 3;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3000, 16, 3)), 'flac wasted bits');
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.HeaderFromStreamInfo := True;
  LOptions.BlockSize := 700;
  LOptions.SampleRate := 37800;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3001, 16, 0)), 'flac header from streaminfo');
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.BlockSize := 300;
  LOptions.SampleRate := 16000;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3001, 16, 0)), 'flac block size 300');
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.BlockSize := 4096;
  LOptions.SampleRate := 11025;
  LOptions.ExtraMetadata := True;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 9000, 16, 0)), 'flac more metadata');
end;

/// <summary>A tag of ID3v2.3 with ABodySize bytes after its header of ten</summary>
function Id3Tag(ABodySize: Integer): TBytes;
begin
  SetLength(Result, 10 + ABodySize);
  Result[0] := Ord('I');
  Result[1] := Ord('D');
  Result[2] := Ord('3');
  Result[3] := 3;
  Result[6] := (ABodySize shr 21) and $7F;
  Result[7] := (ABodySize shr 14) and $7F;
  Result[8] := (ABodySize shr 7) and $7F;
  Result[9] := ABodySize and $7F;
end;

function WithTag(const ATag, ASound: TBytes): TBytes;
begin
  SetLength(Result, Length(ATag) + Length(ASound));
  Move(ATag[0], Result[0], Length(ATag));
  Move(ASound[0], Result[Length(ATag)], Length(ASound));
end;

procedure TTestSoundParity.TestId3Tag;
var
  LWav, LFlac, LPaf: TBytes;
  LOptions: TSoundTestFlacOptions;
begin
  LWav := TSoundTestWavFile.Build(TSoundTestWavOptions.Plain(1, 2, 16),
    TSoundTestWavFile.RandomBytes(2 * 2 * 301, 5));
  LOptions := TSoundTestFlacOptions.Plain;
  LFlac := TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3000, 16, 0));
  LPaf := TSoundTestPafFile.Build(False, 0, 1, 22050, TSoundTestWavFile.RandomBytes(602, 1));

  CheckSame(WithTag(Id3Tag(0), LFlac), 'id3 flac, empty tag');
  CheckSame(WithTag(Id3Tag(20000), LFlac), 'id3 flac');
  // a tag after a tag is not understood
  CheckSameFailure(WithTag(Id3Tag(25), WithTag(Id3Tag(77), LFlac)), 'id3 twice');
  // the other containers do not open after a tag (in this build of libsndfile)
  CheckSameFailure(WithTag(Id3Tag(40), LWav), 'id3 wav');
  CheckSameFailure(WithTag(Id3Tag(300), LPaf), 'id3 paf');
  // and a tag that is all there is
  CheckSameFailure(Id3Tag(100), 'id3 alone');
end;

procedure TTestSoundParity.TestXi;
var
  LSixteen: Boolean;
  LData: TBytes;
  LSize: Integer;
begin
  for LSixteen := False to True do
  begin
    LSize := 600 + Ord(LSixteen) * 601;
    LData := TSoundTestWavFile.RandomBytes(LSize, 9 + Ord(LSixteen));
    CheckSame(TSoundTestXiFile.Build(LSixteen, 1, [LSize], LData), Format('xi sample, 16 bit %s', [BoolToStr(LSixteen)]));
    // other samples with nothing in them, and a size that is not the real one
    CheckSame(TSoundTestXiFile.Build(LSixteen, 3, [LSize, 0, 0], LData), Format('xi empty samples, 16 bit %s', [BoolToStr(LSixteen)]));
    CheckSame(TSoundTestXiFile.Build(LSixteen, 1, [1000000], LData), Format('xi truncated, 16 bit %s', [BoolToStr(LSixteen)]));
  end;
  CheckSame(TSoundTestXiFile.Build(False, 2, [600, 10], LData), 'xi two samples');
  CheckSameFailure(TSoundTestXiFile.Build(False, 3, [10, 10, 10], LData), 'xi three samples');
  CheckSameFailure(TSoundTestXiFile.Build(False, 17, [10], LData), 'xi too many samples');
  CheckSameFailure(TSoundTestXiFile.Build(False, 0, [], LData), 'xi no samples');
  CheckSameFailure(TSoundTestXiFile.Build(False, 1, [10], LData, Ord(';')), 'xi bad signature');
  CheckSameFailure(TSoundTestXiFile.Build(False, 1, [10], LData, Ord(':'), $1B), 'xi bad name end');
end;

procedure TTestSoundParity.TestSds;
var
  LWidth: Integer;
begin
  // 2, 3 and 4 bytes for each sample; the frames are of whole packets or not
  for LWidth in [8, 12, 14, 16, 20, 21, 24, 28] do
  begin
    CheckSameBulk(TSoundTestSdsFile.Build(LWidth, 22675, 240, 4, LWidth), Format('sds %d bits whole', [LWidth]));
    CheckSameBulk(TSoundTestSdsFile.Build(LWidth, 22675, 200, 4, LWidth), Format('sds %d bits partial', [LWidth]));
    CheckSameBulk(TSoundTestSdsFile.Build(LWidth, 0, 180, 5, LWidth), Format('sds %d bits period 0', [LWidth]));
  end;
  // a file that has less packets than it says, and a sound of a single packet
  CheckSameBulk(TSoundTestSdsFile.Build(16, 22675, 400, 3, 3), 'sds missing packets');
  CheckSameBulk(TSoundTestSdsFile.Build(16, 22675, 30, 1, 3), 'sds one packet');
  CheckSameFailure(TSoundTestSdsFile.Build(1, 22675, 240, 4, 1), 'sds 1 bit');
  CheckSameFailure(TSoundTestSdsFile.Build(5, 22675, 240, 4, 1), 'sds 5 bits');
  CheckSameFailure(TSoundTestSdsFile.Build(30, 22675, 240, 4, 1), 'sds 30 bits');
end;

procedure TTestSoundParity.TestPaf;
var
  LLittle: Boolean;
  LFormat, LChannels: Integer;
  LBytes: Integer;
begin
  for LLittle := False to True do
    for LFormat in [2, 0] do
      for LChannels := 1 to 3 do
      begin
        LBytes := 1 + Ord(LFormat = 0);
        CheckSame(TSoundTestPafFile.Build(LLittle, LFormat, LChannels, 22050,
          TSoundTestWavFile.RandomBytes(LChannels * LBytes * 301 + 1, LChannels + LFormat)),
          Format('paf format %d, %d channels, little %s', [LFormat, LChannels, BoolToStr(LLittle)]));
      end;

  // 24 bit: blocks of 32 bytes that hold 10 samples of a channel
  for LLittle := False to True do
    for LChannels := 1 to 3 do
    begin
      CheckSameBulk(TSoundTestPafFile.Build(LLittle, 1, LChannels, 44100,
        TSoundTestWavFile.RandomBytes(5 * 32 * LChannels, 40 + LChannels)),
        Format('paf 24 bit, %d channels, little %s', [LChannels, BoolToStr(LLittle)]));
      // a file that stops in the middle of a block
      CheckSameBulk(TSoundTestPafFile.Build(LLittle, 1, LChannels, 44100,
        TSoundTestWavFile.RandomBytes(4 * 32 * LChannels + 17, 50 + LChannels)),
        Format('paf 24 bit truncated, %d channels, little %s', [LChannels, BoolToStr(LLittle)]));
    end;

  // headers that are wrong
  CheckSameFailure(TSoundTestPafFile.Build(False, 0, 1, 22050, TSoundTestWavFile.RandomBytes(100, 1), 1), 'paf version');
  CheckSameFailure(TSoundTestPafFile.Build(False, 0, 0, 22050, TSoundTestWavFile.RandomBytes(100, 1)), 'paf no channels');
  CheckSameFailure(TSoundTestPafFile.Build(True, 7, 1, 22050, TSoundTestWavFile.RandomBytes(100, 1)), 'paf unknown format');
  CheckSameFailure(TSoundTestPafFile.Build(False, 0, 1, 0, TSoundTestWavFile.RandomBytes(100, 1)), 'paf rate 0');
  CheckSameFailure(Copy(TSoundTestPafFile.Build(False, 0, 1, 22050, TSoundTestWavFile.RandomBytes(100, 1)), 0, 1000), 'paf short header');
end;

procedure TTestSoundParity.TestVorbis;
var
  LOptions: TSoundTestVorbisOptions;
  LFirst, LSecond: TBytes;
  LChannels, LResidue: Integer;
begin
  for LChannels := 1 to 2 do
    for LResidue := 0 to 2 do
    begin
      LOptions := TSoundTestVorbisOptions.Plain;
      LOptions.Channels := LChannels;
      LOptions.ResidueType := LResidue;
      LOptions.Seed := 100 + LChannels * 10 + LResidue;
      CheckSame(TSoundTestVorbisFile.Build(LOptions), Format('vorbis %d channels residue %d', [LChannels, LResidue]));
    end;

  // the end of the last page cuts the last block
  LOptions := TSoundTestVorbisOptions.Plain;
  LOptions.TrimEnd := 300;
  CheckSame(TSoundTestVorbisFile.Build(LOptions), 'vorbis trimmed end');

  // two sounds one after the other: the length is of both, the audio of the first
  LFirst := TSoundTestVorbisFile.Build(LOptions);
  LOptions.Serial := 99;
  LOptions.Seed := 777;
  LOptions.Packets := 12;
  LSecond := TSoundTestVorbisFile.Build(LOptions);
  CheckSame(TSoundTestVorbisFile.Chain(LFirst, LSecond), 'vorbis chained');

  // a file cut in the middle of the audio: the length is of the last page that is whole
  LOptions := TSoundTestVorbisOptions.Plain;
  LFirst := TSoundTestVorbisFile.Build(LOptions);
  SetLength(LFirst, Length(LFirst) * 2 div 3);
  CheckSame(LFirst, 'vorbis cut');

  // a file without the setup header
  LFirst := TSoundTestVorbisFile.Build(LOptions);
  SetLength(LFirst, 120);
  CheckSameFailure(LFirst, 'vorbis without headers');
end;
procedure TTestSoundParity.TestFlacDamaged;
var
  LOptions: TSoundTestFlacOptions;
  LBytes: TBytes;
begin
  // A frame with the wrong CRC is silence, one with a bad header is lost
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.BadCrcFrame := 1;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 6000, 16, 0)), 'flac bad crc');
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.BadHeaderFrame := 2;
  // In chunks: a single read across the resync and the end of the sound is not emulated
  CheckSameStream(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 6000, 16, 0)), 'flac bad header');
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.Garbage := 7;
  CheckSameStream(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 6000, 16, 0)), 'flac garbage between frames');

  // The numbers in STREAMINFO do not agree with the frames
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.TotalSamples := 5000;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3000, 16, 0)), 'flac more samples promised');
  LOptions.TotalSamples := 2000;
  CheckSame(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 3000, 16, 0)), 'flac fewer samples promised');
  LOptions.TotalSamples := 0;
  CheckSameStream(TSoundTestFlacFile.Build(LOptions, FlacSignals(2, 3000, 16, 0)), 'flac unknown length');

  // A file that stops in the middle of a frame
  LOptions := TSoundTestFlacOptions.Plain;
  LBytes := TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 6000, 16, 0));
  SetLength(LBytes, Length(LBytes) - 300);
  CheckSameBulk(LBytes, 'flac cut');

  // A bit depth libsndfile does not read
  LOptions := TSoundTestFlacOptions.Plain;
  LOptions.BitsPerSample := 12;
  CheckSameFailure(TSoundTestFlacFile.Build(LOptions, FlacSignals(1, 2000, 12, 0)), 'flac 12 bits');
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
