{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound engine                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sndfile.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf;

type
  [TestFixture]
  [Category('sndfile')]
  TTestSndfileEngine = class(TObject)
  private
    FSndfile: ISndfile;
    function OpenSound(const ASource: TBytes): ISoundFile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVersion;
    [Test]
    procedure TestOpenMonoWav;
    [Test]
    procedure TestOpenStereoWav;
    [Test]
    procedure TestReadShortReturnsTheSamples;
    [Test]
    procedure TestReadShortOfStereoKeepsTheChannelsInterleaved;
    [Test]
    procedure TestReadStopsAtTheEndOfTheSound;
    [Test]
    procedure TestReadIntScalesTo32Bit;
    [Test]
    procedure TestReadDoubleIsNormalized;
    [Test]
    procedure TestSeekThenRead;
    [Test]
    procedure TestSeekToTheEnd;
    [Test]
    procedure TestSeekPastTheEndFails;
    [Test]
    procedure TestSeekWithInvalidOriginFails;
    [Test]
    procedure TestReadIntoNilBufferFails;
    [Test]
    procedure TestSourceCanBeChangedAfterOpen;
    [Test]
    procedure TestOpenNilReturnsInvalidArgument;
    [Test]
    procedure TestOpenEmptyBufferReturnsInvalidArgument;
    [Test]
    procedure TestOpenTextReturnsError;
    [Test]
    procedure TestErrorTextIsAvailable;
  end;

implementation

uses
  DelphiDoom.Sound.Factory, DelphiDoom.Tests.Sndfile.Wav;

{ TTestSndfileEngine }

procedure TTestSndfileEngine.Setup;
begin
  FSndfile := TSoundFactory.CreateEngine;
end;

procedure TTestSndfileEngine.TearDown;
begin
  FSndfile := nil;
end;

function TTestSndfileEngine.OpenSound(const ASource: TBytes): ISoundFile;
begin
  Assert.AreEqual(SNDFILE_OK, FSndfile.OpenMemory(Pointer(ASource),
    Length(ASource), Result));
  Assert.IsTrue(Assigned(Result));
end;

procedure TTestSndfileEngine.TestVersion;
begin
  Assert.IsTrue(Length(string(AnsiString(FSndfile.GetVersion))) > 0);
end;

procedure TTestSndfileEngine.TestOpenMonoWav;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [0, 100, -100, 32767, -32768]));

  Assert.AreEqual(SNDFILE_OK, LSound.GetInfo(LInfo));
  Assert.AreEqual(1, LInfo.Channels);
  Assert.AreEqual(11025, LInfo.SampleRate);
  Assert.AreEqual(5, Integer(LInfo.Frames));
  Assert.AreEqual(SNDFILE_FORMAT_WAV, LInfo.Format and SNDFILE_FORMAT_TYPEMASK);
  Assert.AreEqual(SNDFILE_FORMAT_PCM_16, LInfo.Format and SNDFILE_FORMAT_SUBMASK);
end;

procedure TTestSndfileEngine.TestOpenStereoWav;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(2, 44100, [1, 2, 3, 4, 5, 6]));

  Assert.AreEqual(SNDFILE_OK, LSound.GetInfo(LInfo));
  Assert.AreEqual(2, LInfo.Channels);
  Assert.AreEqual(44100, LInfo.SampleRate);
  Assert.AreEqual(3, Integer(LInfo.Frames));
end;

procedure TTestSndfileEngine.TestReadShortReturnsTheSamples;
var
  LSound: ISoundFile;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [0, 100, -100, 32767, -32768]));
  SetLength(LBuffer, 5);

  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 5, LFramesRead));

  Assert.AreEqual(5, Integer(LFramesRead));
  Assert.AreEqual(0, Integer(LBuffer[0]));
  Assert.AreEqual(100, Integer(LBuffer[1]));
  Assert.AreEqual(-100, Integer(LBuffer[2]));
  Assert.AreEqual(32767, Integer(LBuffer[3]));
  Assert.AreEqual(-32768, Integer(LBuffer[4]));
end;

procedure TTestSndfileEngine.TestReadShortOfStereoKeepsTheChannelsInterleaved;
var
  LSound: ISoundFile;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
  LIndex: Integer;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(2, 22050, [10, -10, 20, -20, 30, -30]));
  SetLength(LBuffer, 6);

  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 3, LFramesRead));

  Assert.AreEqual(3, Integer(LFramesRead));
  for LIndex := 0 to 2 do
  begin
    Assert.AreEqual((LIndex + 1) * 10, Integer(LBuffer[LIndex * 2]));
    Assert.AreEqual(-(LIndex + 1) * 10, Integer(LBuffer[LIndex * 2 + 1]));
  end;
end;

procedure TTestSndfileEngine.TestReadStopsAtTheEndOfTheSound;
var
  LSound: ISoundFile;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 8000, [1, 2, 3]));
  SetLength(LBuffer, 10);

  // More frames than the sound has: not an error, just a short read
  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 10, LFramesRead));
  Assert.AreEqual(3, Integer(LFramesRead));

  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 10, LFramesRead));
  Assert.AreEqual(0, Integer(LFramesRead));
end;

procedure TTestSndfileEngine.TestReadIntScalesTo32Bit;
var
  LSound: ISoundFile;
  LBuffer: array of Integer;
  LFramesRead: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [0, 100, -100]));
  SetLength(LBuffer, 3);

  Assert.AreEqual(SNDFILE_OK, LSound.ReadInt(@LBuffer[0], 3, LFramesRead));

  Assert.AreEqual(3, Integer(LFramesRead));
  Assert.AreEqual(0, LBuffer[0]);
  Assert.AreEqual(100 * 65536, LBuffer[1]);
  Assert.AreEqual(-100 * 65536, LBuffer[2]);
end;

procedure TTestSndfileEngine.TestReadDoubleIsNormalized;
var
  LSound: ISoundFile;
  LBuffer: array of Double;
  LFramesRead: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [0, 16384, -16384, -32768]));
  SetLength(LBuffer, 4);

  Assert.AreEqual(SNDFILE_OK, LSound.ReadDouble(@LBuffer[0], 4, LFramesRead));

  Assert.AreEqual(4, Integer(LFramesRead));
  Assert.IsTrue(Abs(LBuffer[0]) < 0.0001);
  Assert.IsTrue(Abs(LBuffer[1] - 0.5) < 0.0001);
  Assert.IsTrue(Abs(LBuffer[2] + 0.5) < 0.0001);
  Assert.IsTrue(Abs(LBuffer[3] + 1.0) < 0.0001);
end;

procedure TTestSndfileEngine.TestSeekThenRead;
var
  LSound: ISoundFile;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
  LPosition: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [10, 20, 30, 40, 50]));
  SetLength(LBuffer, 1);

  Assert.AreEqual(SNDFILE_OK, LSound.Seek(2, SNDFILE_SEEK_SET, LPosition));
  Assert.AreEqual(2, Integer(LPosition));
  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 1, LFramesRead));
  Assert.AreEqual(30, Integer(LBuffer[0]));

  // Relative to the position after the read (frame 3)
  Assert.AreEqual(SNDFILE_OK, LSound.Seek(1, SNDFILE_SEEK_CUR, LPosition));
  Assert.AreEqual(4, Integer(LPosition));
  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 1, LFramesRead));
  Assert.AreEqual(50, Integer(LBuffer[0]));

  Assert.AreEqual(SNDFILE_OK, LSound.Seek(0, SNDFILE_SEEK_SET, LPosition));
  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 1, LFramesRead));
  Assert.AreEqual(10, Integer(LBuffer[0]));
end;

procedure TTestSndfileEngine.TestSeekToTheEnd;
var
  LSound: ISoundFile;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
  LPosition: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [10, 20, 30]));
  SetLength(LBuffer, 1);

  Assert.AreEqual(SNDFILE_OK, LSound.Seek(0, SNDFILE_SEEK_END, LPosition));
  Assert.AreEqual(3, Integer(LPosition));
  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 1, LFramesRead));
  Assert.AreEqual(0, Integer(LFramesRead));
end;

procedure TTestSndfileEngine.TestSeekPastTheEndFails;
var
  LSound: ISoundFile;
  LPosition: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [10, 20, 30]));

  Assert.IsTrue(LSound.Seek(100, SNDFILE_SEEK_SET, LPosition) <> SNDFILE_OK);
end;

procedure TTestSndfileEngine.TestSeekWithInvalidOriginFails;
var
  LSound: ISoundFile;
  LPosition: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [10, 20, 30]));

  Assert.AreEqual(SNDFILE_ERR_INVALID_ARGUMENT, LSound.Seek(0, 99, LPosition));
end;

procedure TTestSndfileEngine.TestReadIntoNilBufferFails;
var
  LSound: ISoundFile;
  LFramesRead: Int64;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [10, 20, 30]));

  Assert.AreEqual(SNDFILE_ERR_INVALID_ARGUMENT, LSound.ReadShort(nil, 3, LFramesRead));
  Assert.AreEqual(0, Integer(LFramesRead));
end;

procedure TTestSndfileEngine.TestSourceCanBeChangedAfterOpen;
var
  LSource: TBytes;
  LSound: ISoundFile;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
begin
  LSource := TSndfileTestWav.MakePcm16(1, 11025, [111, 222, 333]);
  LSound := OpenSound(LSource);
  // The DLL has its own copy of the data
  FillChar(LSource[0], Length(LSource), 0);
  SetLength(LBuffer, 3);

  Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 3, LFramesRead));

  Assert.AreEqual(3, Integer(LFramesRead));
  Assert.AreEqual(111, Integer(LBuffer[0]));
  Assert.AreEqual(222, Integer(LBuffer[1]));
  Assert.AreEqual(333, Integer(LBuffer[2]));
end;

procedure TTestSndfileEngine.TestOpenNilReturnsInvalidArgument;
var
  LSound: ISoundFile;
begin
  Assert.AreEqual(SNDFILE_ERR_INVALID_ARGUMENT, FSndfile.OpenMemory(nil, 100, LSound));
  Assert.IsTrue(LSound = nil);
end;

procedure TTestSndfileEngine.TestOpenEmptyBufferReturnsInvalidArgument;
var
  LSource: TBytes;
  LSound: ISoundFile;
begin
  SetLength(LSource, 16);

  Assert.AreEqual(SNDFILE_ERR_INVALID_ARGUMENT, FSndfile.OpenMemory(Pointer(LSource), 0, LSound));
  Assert.IsTrue(LSound = nil);
end;

procedure TTestSndfileEngine.TestOpenTextReturnsError;
var
  LSource: TBytes;
  LSound: ISoundFile;
begin
  LSource := TEncoding.ASCII.GetBytes('This is plain text, not a sound: nothing to decode here.');

  Assert.IsTrue(FSndfile.OpenMemory(Pointer(LSource), Length(LSource),
    LSound) <> SNDFILE_OK);
  Assert.IsTrue(LSound = nil);
end;

procedure TTestSndfileEngine.TestErrorTextIsAvailable;
var
  LSound: ISoundFile;
begin
  LSound := OpenSound(TSndfileTestWav.MakePcm16(1, 11025, [10, 20, 30]));

  Assert.IsTrue(Assigned(LSound.GetErrorText));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSndfileEngine);

end.
