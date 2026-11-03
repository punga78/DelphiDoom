{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiClient                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Client;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Intf,
  DelphiDoom.Xmi.Client;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiClient = class(TObject)
  private
    FClient: TXmiClient;
    procedure AssertIsStandardMidi(const AMidi: TBytes);
    procedure AssertConvertRaises(const ASource: TBytes; ATrack: Cardinal;
      AExpectedCode: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutXmiRaises;
    [Test]
    procedure TestDetectFormat;
    [Test]
    procedure TestDetectFormatOfEmptyDataIsUnknown;
    [Test]
    procedure TestIsXmiMusic;
    [Test]
    procedure TestTrackCount;
    [Test]
    procedure TestConvertXmiToMidi;
    [Test]
    procedure TestConvertCmfToMidi;
    [Test]
    procedure TestConvertFromPointer;
    [Test]
    procedure TestConvertGarbageRaisesFormatError;
    [Test]
    procedure TestConvertEmptyDataRaisesArgumentError;
    [Test]
    procedure TestConvertMissingTrackRaisesTrackError;
    [Test]
    procedure TestConvertCorruptedXmiDoesNotCrash;
  end;

implementation

uses
  DelphiDoom.Xmi.Engine, DelphiDoom.Tests.Xmi.Samples;

{ TTestXmiClient }

procedure TTestXmiClient.Setup;
begin
  FClient := TXmiClient.Create(TXmiEngine.Create);
end;

procedure TTestXmiClient.TearDown;
begin
  FreeAndNil(FClient);
end;

procedure TTestXmiClient.AssertIsStandardMidi(const AMidi: TBytes);
begin
  Assert.IsTrue(Length(AMidi) > 22, 'MIDI file too short');
  Assert.AreEqual('MThd', TXmiSamples.TagAt(AMidi, 0));
  Assert.AreEqual('MTrk', TXmiSamples.TagAt(AMidi, 14));
end;

procedure TTestXmiClient.AssertConvertRaises(const ASource: TBytes;
  ATrack: Cardinal; AExpectedCode: Integer);
begin
  try
    FClient.ConvertToMidi(ASource, ATrack);
    Assert.Fail('EXmiException expected');
  except
    on E: EXmiException do
      Assert.AreEqual(AExpectedCode, E.Code);
  end;
end;

procedure TTestXmiClient.TestCreateWithoutXmiRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestXmiClient.TestDetectFormat;
begin
  Assert.IsTrue(FClient.DetectFormat(TXmiSamples.BuildXmi) = TXmiFormat.Xmi);
  Assert.IsTrue(FClient.DetectFormat(TXmiSamples.BuildCmf) = TXmiFormat.Cmf);
  Assert.IsTrue(FClient.DetectFormat(TXmiSamples.BuildSopHeader) = TXmiFormat.Sop);
  Assert.IsTrue(FClient.DetectFormat(TXmiSamples.BuildMidi) = TXmiFormat.Midi);
  Assert.IsTrue(FClient.DetectFormat(TXmiSamples.BuildGarbage(200)) =
    TXmiFormat.Unknown);
end;

procedure TTestXmiClient.TestDetectFormatOfEmptyDataIsUnknown;
var
  LEmpty: TBytes;
begin
  LEmpty := nil;
  Assert.IsTrue(FClient.DetectFormat(LEmpty) = TXmiFormat.Unknown);
end;

procedure TTestXmiClient.TestIsXmiMusic;
begin
  Assert.IsTrue(FClient.IsXmiMusic(TXmiSamples.BuildXmi), 'XMI');
  Assert.IsTrue(FClient.IsXmiMusic(TXmiSamples.BuildCmf), 'CMF');
  Assert.IsTrue(FClient.IsXmiMusic(TXmiSamples.BuildSopHeader), 'SOP');
  Assert.IsFalse(FClient.IsXmiMusic(TXmiSamples.BuildMidi), 'MIDI');
  Assert.IsFalse(FClient.IsXmiMusic(TXmiSamples.BuildGarbage(200)), 'garbage');
end;

procedure TTestXmiClient.TestTrackCount;
begin
  Assert.AreEqual(1, Integer(FClient.TrackCount(TXmiSamples.BuildXmi)));
  Assert.AreEqual(1, Integer(FClient.TrackCount(TXmiSamples.BuildCmf)));
end;

procedure TTestXmiClient.TestConvertXmiToMidi;
begin
  AssertIsStandardMidi(FClient.ConvertToMidi(TXmiSamples.BuildXmi));
end;

procedure TTestXmiClient.TestConvertCmfToMidi;
begin
  AssertIsStandardMidi(FClient.ConvertToMidi(TXmiSamples.BuildCmf));
end;

procedure TTestXmiClient.TestConvertFromPointer;
var
  LSample: TBytes;
begin
  LSample := TXmiSamples.BuildXmi;
  AssertIsStandardMidi(FClient.ConvertToMidi(Pointer(LSample), Length(LSample)));
end;

procedure TTestXmiClient.TestConvertGarbageRaisesFormatError;
begin
  AssertConvertRaises(TXmiSamples.BuildGarbage(200), 0, XMI_ERROR_FORMAT);
end;

procedure TTestXmiClient.TestConvertEmptyDataRaisesArgumentError;
var
  LEmpty: TBytes;
begin
  LEmpty := nil;
  AssertConvertRaises(LEmpty, 0, XMI_ERROR_ARGUMENT);
end;

procedure TTestXmiClient.TestConvertMissingTrackRaisesTrackError;
begin
  AssertConvertRaises(TXmiSamples.BuildXmi, 3, XMI_ERROR_TRACK);
end;

procedure TTestXmiClient.TestConvertCorruptedXmiDoesNotCrash;
var
  LSample: TBytes;
begin
  // The tail of the song is gone: whatever the library decides (a MIDI file
  // with the events that survive, or an error), it must say it with a result
  // or an EXmiException, never with another exception
  LSample := TXmiSamples.BuildXmi;
  SetLength(LSample, Length(LSample) - 6);
  try
    FClient.ConvertToMidi(LSample);
    Assert.Pass('converted');
  except
    on EXmiException do
      Assert.Pass('rejected');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiClient);

end.
