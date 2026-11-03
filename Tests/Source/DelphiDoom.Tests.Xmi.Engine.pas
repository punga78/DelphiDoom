{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiEngine                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Intf;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiEngine = class(TObject)
  private
    FXmi: IXmi;
    function Detect(const ASource: TBytes): Integer;
    function ConvertWithTwoCalls(const ASource: TBytes; ATrack: Cardinal): TBytes;
    procedure AssertIsStandardMidi(const AMidi: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDetectXmi;
    [Test]
    procedure TestDetectCmf;
    [Test]
    procedure TestDetectSop;
    [Test]
    procedure TestDetectMidi;
    [Test]
    procedure TestDetectGarbageIsUnknown;
    [Test]
    procedure TestDetectNilIsUnknown;
    [Test]
    procedure TestTrackCountOfXmi;
    [Test]
    procedure TestTrackCountOfGarbageReturnsFormatError;
    [Test]
    procedure TestConvertXmiProducesStandardMidi;
    [Test]
    procedure TestConvertCmfProducesStandardMidi;
    [Test]
    procedure TestConvertTwiceGivesTheSameMidi;
    [Test]
    procedure TestConvertWithoutBufferReportsRequiredSize;
    [Test]
    procedure TestConvertIntoTooSmallBufferReportsRequiredSize;
    [Test]
    procedure TestConvertIntoLargerBufferReportsActualSize;
    [Test]
    procedure TestConvertGarbageReturnsFormatError;
    [Test]
    procedure TestConvertMidiReturnsFormatError;
    [Test]
    procedure TestConvertMissingTrackReturnsTrackError;
    [Test]
    procedure TestConvertNilReturnsArgumentError;
    [Test]
    procedure TestTwoEnginesConvertIndependently;
  end;

implementation

uses
  DelphiDoom.Xmi.Engine, DelphiDoom.Tests.Xmi.Samples;

{ TTestXmiEngine }

procedure TTestXmiEngine.Setup;
begin
  FXmi := TXmiEngine.Create;
end;

procedure TTestXmiEngine.TearDown;
begin
  FXmi := nil;
end;

function TTestXmiEngine.Detect(const ASource: TBytes): Integer;
begin
  Result := FXmi.DetectFormat(Pointer(ASource), Length(ASource));
end;

// The protocol of the interface: ask for the size, then give the buffer
function TTestXmiEngine.ConvertWithTwoCalls(const ASource: TBytes;
  ATrack: Cardinal): TBytes;
var
  LSize: Cardinal;
begin
  LSize := 0;
  Assert.AreEqual(XMI_ERROR_BUFFER, FXmi.ConvertToMidi(Pointer(ASource),
    Length(ASource), ATrack, nil, LSize));
  Assert.IsTrue(LSize > 0, 'size needed not reported');

  SetLength(Result, LSize);
  Assert.AreEqual(XMI_OK, FXmi.ConvertToMidi(Pointer(ASource), Length(ASource),
    ATrack, Pointer(Result), LSize));
  SetLength(Result, LSize);
end;

procedure TTestXmiEngine.AssertIsStandardMidi(const AMidi: TBytes);
begin
  Assert.IsTrue(Length(AMidi) > 22, 'MIDI file too short');
  Assert.AreEqual('MThd', TXmiSamples.TagAt(AMidi, 0));
  // Length of the header chunk: 6
  Assert.AreEqual(6, Integer(AMidi[7]));
  Assert.AreEqual('MTrk', TXmiSamples.TagAt(AMidi, 14));
end;

procedure TTestXmiEngine.TestDetectXmi;
begin
  Assert.AreEqual(Ord(TXmiFormat.Xmi), Detect(TXmiSamples.BuildXmi));
end;

procedure TTestXmiEngine.TestDetectCmf;
begin
  Assert.AreEqual(Ord(TXmiFormat.Cmf), Detect(TXmiSamples.BuildCmf));
end;

procedure TTestXmiEngine.TestDetectSop;
begin
  Assert.AreEqual(Ord(TXmiFormat.Sop), Detect(TXmiSamples.BuildSopHeader));
end;

procedure TTestXmiEngine.TestDetectMidi;
begin
  Assert.AreEqual(Ord(TXmiFormat.Midi), Detect(TXmiSamples.BuildMidi));
end;

procedure TTestXmiEngine.TestDetectGarbageIsUnknown;
begin
  Assert.AreEqual(Ord(TXmiFormat.Unknown), Detect(TXmiSamples.BuildGarbage(200)));
end;

procedure TTestXmiEngine.TestDetectNilIsUnknown;
begin
  Assert.AreEqual(Ord(TXmiFormat.Unknown), FXmi.DetectFormat(nil, 100));
  Assert.AreEqual(Ord(TXmiFormat.Unknown), FXmi.DetectFormat(Pointer(1), 0));
end;

procedure TTestXmiEngine.TestTrackCountOfXmi;
var
  LSample: TBytes;
  LCount: Cardinal;
begin
  LSample := TXmiSamples.BuildXmi;
  Assert.AreEqual(XMI_OK, FXmi.GetTrackCount(Pointer(LSample), Length(LSample),
    LCount));
  Assert.AreEqual(1, Integer(LCount));
end;

procedure TTestXmiEngine.TestTrackCountOfGarbageReturnsFormatError;
var
  LSample: TBytes;
  LCount: Cardinal;
begin
  LSample := TXmiSamples.BuildGarbage(200);
  Assert.AreEqual(XMI_ERROR_FORMAT, FXmi.GetTrackCount(Pointer(LSample),
    Length(LSample), LCount));
  Assert.AreEqual(0, Integer(LCount));
end;

procedure TTestXmiEngine.TestConvertXmiProducesStandardMidi;
begin
  AssertIsStandardMidi(ConvertWithTwoCalls(TXmiSamples.BuildXmi, 0));
end;

procedure TTestXmiEngine.TestConvertCmfProducesStandardMidi;
begin
  AssertIsStandardMidi(ConvertWithTwoCalls(TXmiSamples.BuildCmf, 0));
end;

procedure TTestXmiEngine.TestConvertTwiceGivesTheSameMidi;
var
  LSample, LFirst, LSecond: TBytes;
begin
  LSample := TXmiSamples.BuildXmi;
  LFirst := ConvertWithTwoCalls(LSample, 0);
  LSecond := ConvertWithTwoCalls(LSample, 0);
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  Assert.AreEqualMemory(Pointer(LFirst), Pointer(LSecond), Length(LFirst));
end;

procedure TTestXmiEngine.TestConvertWithoutBufferReportsRequiredSize;
var
  LSample: TBytes;
  LSize: Cardinal;
begin
  LSample := TXmiSamples.BuildXmi;
  LSize := 12345;
  Assert.AreEqual(XMI_ERROR_BUFFER, FXmi.ConvertToMidi(Pointer(LSample),
    Length(LSample), 0, nil, LSize));
  Assert.IsTrue(LSize <> 12345, 'size not updated');
  Assert.IsTrue(LSize > 14, 'size smaller than the MIDI header');
end;

procedure TTestXmiEngine.TestConvertIntoTooSmallBufferReportsRequiredSize;
var
  LSample, LSmall, LFull: TBytes;
  LSize, LNeeded: Cardinal;
begin
  LSample := TXmiSamples.BuildXmi;
  LFull := ConvertWithTwoCalls(LSample, 0);
  LNeeded := Length(LFull);

  SetLength(LSmall, 10);
  LSize := Length(LSmall);
  Assert.AreEqual(XMI_ERROR_BUFFER, FXmi.ConvertToMidi(Pointer(LSample),
    Length(LSample), 0, Pointer(LSmall), LSize));
  Assert.AreEqual(Integer(LNeeded), Integer(LSize));
end;

procedure TTestXmiEngine.TestConvertIntoLargerBufferReportsActualSize;
var
  LSample, LExact, LLarge: TBytes;
  LSize: Cardinal;
begin
  LSample := TXmiSamples.BuildXmi;
  LExact := ConvertWithTwoCalls(LSample, 0);

  SetLength(LLarge, Length(LExact) + 100);
  LSize := Length(LLarge);
  Assert.AreEqual(XMI_OK, FXmi.ConvertToMidi(Pointer(LSample), Length(LSample),
    0, Pointer(LLarge), LSize));
  Assert.AreEqual(Length(LExact), Integer(LSize));
  Assert.AreEqualMemory(Pointer(LExact), Pointer(LLarge), Length(LExact));
end;

procedure TTestXmiEngine.TestConvertGarbageReturnsFormatError;
var
  LSample, LDest: TBytes;
  LSize: Cardinal;
begin
  LSample := TXmiSamples.BuildGarbage(200);
  SetLength(LDest, 1000);
  LSize := Length(LDest);
  Assert.AreEqual(XMI_ERROR_FORMAT, FXmi.ConvertToMidi(Pointer(LSample),
    Length(LSample), 0, Pointer(LDest), LSize));
end;

procedure TTestXmiEngine.TestConvertMidiReturnsFormatError;
var
  LSample, LDest: TBytes;
  LSize: Cardinal;
begin
  LSample := TXmiSamples.BuildMidi;
  SetLength(LDest, 1000);
  LSize := Length(LDest);
  Assert.AreEqual(XMI_ERROR_FORMAT, FXmi.ConvertToMidi(Pointer(LSample),
    Length(LSample), 0, Pointer(LDest), LSize));
end;

procedure TTestXmiEngine.TestConvertMissingTrackReturnsTrackError;
var
  LSample, LDest: TBytes;
  LSize: Cardinal;
begin
  LSample := TXmiSamples.BuildXmi;
  SetLength(LDest, 1000);
  LSize := Length(LDest);
  Assert.AreEqual(XMI_ERROR_TRACK, FXmi.ConvertToMidi(Pointer(LSample),
    Length(LSample), 1, Pointer(LDest), LSize));
end;

procedure TTestXmiEngine.TestConvertNilReturnsArgumentError;
var
  LDest: TBytes;
  LSize: Cardinal;
begin
  SetLength(LDest, 1000);
  LSize := Length(LDest);
  Assert.AreEqual(XMI_ERROR_ARGUMENT, FXmi.ConvertToMidi(nil, 100, 0,
    Pointer(LDest), LSize));
end;

procedure TTestXmiEngine.TestTwoEnginesConvertIndependently;
var
  LOther: IXmi;
  LXmi, LCmf, LXmiMidi, LCmfMidi: TBytes;
  LXmiSize, LCmfSize: Cardinal;
begin
  LOther := TXmiEngine.Create;
  LXmi := TXmiSamples.BuildXmi;
  LCmf := TXmiSamples.BuildCmf;

  // Both engines report the size needed for their own song before either
  // of them receives the data: each one keeps its own converted MIDI
  LXmiSize := 0;
  Assert.AreEqual(XMI_ERROR_BUFFER, FXmi.ConvertToMidi(Pointer(LXmi),
    Length(LXmi), 0, nil, LXmiSize));
  LCmfSize := 0;
  Assert.AreEqual(XMI_ERROR_BUFFER, LOther.ConvertToMidi(Pointer(LCmf),
    Length(LCmf), 0, nil, LCmfSize));

  SetLength(LXmiMidi, LXmiSize);
  Assert.AreEqual(XMI_OK, FXmi.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0,
    Pointer(LXmiMidi), LXmiSize));
  SetLength(LCmfMidi, LCmfSize);
  Assert.AreEqual(XMI_OK, LOther.ConvertToMidi(Pointer(LCmf), Length(LCmf), 0,
    Pointer(LCmfMidi), LCmfSize));

  AssertIsStandardMidi(LXmiMidi);
  AssertIsStandardMidi(LCmfMidi);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiEngine);

end.
