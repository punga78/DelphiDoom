{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSndfileClient                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sndfile.Client;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf,
  DelphiDoom.Sndfile.Client;

type
  [TestFixture]
  [Category('sndfile')]
  TTestSndfileClient = class(TObject)
  private
    FClient: TSndfileClient;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutSndfileRaises;
    [Test]
    procedure TestVersion;
    [Test]
    procedure TestCheckOfOkDoesNotRaise;
    [Test]
    procedure TestCheckOfAnErrorRaisesWithTheCode;
    [Test]
    procedure TestOpenReturnsTheInfo;
    [Test]
    procedure TestOpenGarbageRaises;
    [Test]
    procedure TestOpenEmptyRaisesInvalidArgument;
    [Test]
    procedure TestDecode16OfMonoKeepsTheSamples;
    [Test]
    procedure TestDecode16OfStereoKeepsTheSamples;
    [Test]
    [TestCase('PocheFrame', '100')]
    [TestCase('UnBlocco', '4096')]
    [TestCase('PiuBlocchi', '10000')]
    procedure TestDecode16OfLongSound(AFrames: Integer);
    [Test]
    procedure TestDecode16NormalizedReachesTheFullRange;
    [Test]
    procedure TestDecode16NormalizedKeepsSilence;
    [Test]
    procedure TestDecode16OfGarbageRaises;
  end;

implementation

uses
  DelphiDoom.Sndfile.Engine, DelphiDoom.Tests.Sndfile.Wav;

{ TTestSndfileClient }

procedure TTestSndfileClient.Setup;
begin
  FClient := TSndfileClient.Create(TSndfileEngine.Create);
end;

procedure TTestSndfileClient.TearDown;
begin
  FreeAndNil(FClient);
end;

procedure TTestSndfileClient.TestCreateWithoutSndfileRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TSndfileClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestSndfileClient.TestVersion;
begin
  Assert.IsTrue(Length(FClient.Version) > 0);
end;

procedure TTestSndfileClient.TestCheckOfOkDoesNotRaise;
begin
  TSndfileClient.Check(SNDFILE_OK);
  Assert.Pass;
end;

procedure TTestSndfileClient.TestCheckOfAnErrorRaisesWithTheCode;
begin
  try
    TSndfileClient.Check(SNDFILE_ERR_MALFORMED_FILE);
    Assert.Fail('ESndfileException expected');
  except
    on E: ESndfileException do
      Assert.AreEqual(SNDFILE_ERR_MALFORMED_FILE, E.Code);
  end;
end;

procedure TTestSndfileClient.TestOpenReturnsTheInfo;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
begin
  LSound := FClient.Open(TSndfileTestWav.MakePcm16(2, 22050, [1, 2, 3, 4]));
  LInfo := FClient.InfoOf(LSound);

  Assert.AreEqual(2, LInfo.Channels);
  Assert.AreEqual(22050, LInfo.SampleRate);
  Assert.AreEqual(2, Integer(LInfo.Frames));
end;

procedure TTestSndfileClient.TestOpenGarbageRaises;
var
  LGarbage: TBytes;
begin
  LGarbage := TEncoding.ASCII.GetBytes('Not a sound at all, only some text to be rejected.');

  Assert.WillRaise(
    procedure
    begin
      FClient.Open(LGarbage);
    end, ESndfileException);
end;

procedure TTestSndfileClient.TestOpenEmptyRaisesInvalidArgument;
var
  LEmpty: TBytes;
begin
  LEmpty := nil;

  try
    FClient.Open(LEmpty);
    Assert.Fail('ESndfileException expected');
  except
    on E: ESndfileException do
      Assert.AreEqual(SNDFILE_ERR_INVALID_ARGUMENT, E.Code);
  end;
end;

procedure TTestSndfileClient.TestDecode16OfMonoKeepsTheSamples;
var
  LSamples: TArray<SmallInt>;
  LInfo: TSoundFileInfo;
begin
  LSamples := FClient.Decode16(
    TSndfileTestWav.MakePcm16(1, 11025, [0, 100, -100, 32767, -32768]),
    False, LInfo);

  Assert.AreEqual(1, LInfo.Channels);
  Assert.AreEqual(11025, LInfo.SampleRate);
  Assert.AreEqual(5, Length(LSamples));
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(100, Integer(LSamples[1]));
  Assert.AreEqual(-100, Integer(LSamples[2]));
  Assert.AreEqual(32767, Integer(LSamples[3]));
  Assert.AreEqual(-32768, Integer(LSamples[4]));
end;

procedure TTestSndfileClient.TestDecode16OfStereoKeepsTheSamples;
var
  LSamples: TArray<SmallInt>;
  LInfo: TSoundFileInfo;
  LIndex: Integer;
begin
  LSamples := FClient.Decode16(
    TSndfileTestWav.MakePcm16(2, 44100, [10, -10, 20, -20, 30, -30]),
    False, LInfo);

  Assert.AreEqual(2, LInfo.Channels);
  Assert.AreEqual(6, Length(LSamples));
  for LIndex := 0 to 2 do
  begin
    Assert.AreEqual((LIndex + 1) * 10, Integer(LSamples[LIndex * 2]));
    Assert.AreEqual(-(LIndex + 1) * 10, Integer(LSamples[LIndex * 2 + 1]));
  end;
end;

procedure TTestSndfileClient.TestDecode16OfLongSound(AFrames: Integer);
var
  LSamples: TArray<SmallInt>;
  LInfo: TSoundFileInfo;
  LIndex: Integer;
begin
  LSamples := FClient.Decode16(TSndfileTestWav.MakeSawtooth(AFrames, 11025),
    False, LInfo);

  Assert.AreEqual(AFrames, Length(LSamples));
  for LIndex := 0 to AFrames - 1 do
    if LSamples[LIndex] <> TSndfileTestWav.SawtoothAt(LIndex) then
      Assert.Fail(Format('Sample %d: expected %d, got %d',
        [LIndex, TSndfileTestWav.SawtoothAt(LIndex), LSamples[LIndex]]));
end;

procedure TTestSndfileClient.TestDecode16NormalizedReachesTheFullRange;
var
  LSamples: TArray<SmallInt>;
  LInfo: TSoundFileInfo;
begin
  // The loudest sample (-2000) becomes -32768, the others keep their ratio
  LSamples := FClient.Decode16(
    TSndfileTestWav.MakePcm16(1, 11025, [1000, -2000, 500, 0]), True, LInfo);

  Assert.AreEqual(4, Length(LSamples));
  Assert.IsTrue(Abs(LSamples[0] - 16384) <= 1);
  Assert.IsTrue(Abs(LSamples[1] + 32768) <= 1);
  Assert.IsTrue(Abs(LSamples[2] - 8192) <= 1);
  Assert.AreEqual(0, Integer(LSamples[3]));
end;

procedure TTestSndfileClient.TestDecode16NormalizedKeepsSilence;
var
  LSamples: TArray<SmallInt>;
  LInfo: TSoundFileInfo;
  LIndex: Integer;
begin
  LSamples := FClient.Decode16(
    TSndfileTestWav.MakePcm16(1, 11025, [0, 0, 0, 0, 0]), True, LInfo);

  Assert.AreEqual(5, Length(LSamples));
  for LIndex := 0 to High(LSamples) do
    Assert.AreEqual(0, Integer(LSamples[LIndex]));
end;

procedure TTestSndfileClient.TestDecode16OfGarbageRaises;
var
  LGarbage: TBytes;
begin
  LGarbage := TEncoding.ASCII.GetBytes('Not a sound at all, only some text to be rejected.');

  Assert.WillRaise(
    procedure
    var
      LInfo: TSoundFileInfo;
    begin
      FClient.Decode16(LGarbage, False, LInfo);
    end, ESndfileException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSndfileClient);

end.
