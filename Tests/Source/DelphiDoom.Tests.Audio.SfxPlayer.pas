{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the player of the sound effects     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.SfxPlayer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.Types, DelphiDoom.Audio.Intf,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder, DelphiDoom.Tests.Audio.Fakes;

type
  [TestFixture]
  [Category('audio')]
  TTestAudioSfxPlayer = class(TObject)
  private
    FDevice: TFakeDevice;
    FDeviceIntf: ISoundDevice;
    FSource: TFakeSource;
    FSourceIntf: ISfxSampleSource;
    FRecorder: TLogRecorder;
    FRecorderIntf: ILogSink;
    FPlayer: ISfxPlayer;
    function MakePlayer(AWithDevice: Boolean = True): ISfxPlayer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSeparationToPan;
    [Test]
    procedure TestVolumeToAttenuation;
    [Test]
    procedure TestWithoutDeviceOnlyHandles;
    [Test]
    procedure TestStartPlaysWithTheLevels;
    [Test]
    procedure TestHandlesOnlyGoUp;
    [Test]
    procedure TestSameSoundWhilePlayingUsesAnotherChannel;
    [Test]
    procedure TestSameSoundAfterItIsOverRestartsTheVoice;
    [Test]
    procedure TestForgetSoundsStopsTheRestart;
    [Test]
    procedure TestStopStopsTheVoice;
    [Test]
    procedure TestUpdateParamsOnlyOnThePlayingHandle;
    [Test]
    procedure TestZeroLengthIsAWarningAndNoVoice;
    [Test]
    procedure TestFreeChannelIsPreferredToReplacing;
    [Test]
    procedure TestWithAllChannelsUsedTheOldestIsReplaced;
    [Test]
    procedure TestRefusedFormatIsTriedWithTheAverageOfTheFormat;
    [Test]
    procedure TestExternalSoundThatFailsIsDiscardedAndLoadedAgain;
    [Test]
    procedure TestCreateFailingAlwaysRaisesAStartException;
    [Test]
    procedure TestLoadFailingRaisesAStartException;
    [Test]
    procedure TestShutdownStopsVoicesAndTheDevice;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.Audio.Factory,
  DelphiDoom.Audio.Levels, DelphiDoom.Audio.SfxPlayer;

{ TTestAudioSfxPlayer }

procedure TTestAudioSfxPlayer.Setup;
begin
  FDevice := TFakeDevice.Create;
  FDeviceIntf := FDevice;
  FSource := TFakeSource.Create;
  FSourceIntf := FSource;
  FRecorder := TLogRecorder.Create;
  FRecorderIntf := FRecorder;
  FPlayer := MakePlayer;
end;

function TTestAudioSfxPlayer.MakePlayer(AWithDevice: Boolean): ISfxPlayer;
var
  LDevice: ISoundDevice;
begin
  if AWithDevice then
    LDevice := FDeviceIntf
  else
    LDevice := nil;
  Result := TAudioFactory.CreateSfxPlayer(LDevice, FSourceIntf,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderIntf), nil));
end;

procedure TTestAudioSfxPlayer.TearDown;
begin
  FPlayer := nil;
  FRecorderIntf := nil;
  FRecorder := nil;
  FSourceIntf := nil;
  FSource := nil;
  FDeviceIntf := nil;
  FDevice := nil;
end;

procedure TTestAudioSfxPlayer.TestSeparationToPan;
begin
  Assert.AreEqual(0, TSfxLevels.SeparationToPan(128));
  Assert.AreEqual(-1250, TSfxLevels.SeparationToPan(0));
  Assert.AreEqual(3711, TSfxLevels.SeparationToPan(255));
end;

procedure TTestAudioSfxPlayer.TestVolumeToAttenuation;
begin
  Assert.AreEqual(-9961, TSfxLevels.VolumeToAttenuation(0));
  Assert.AreEqual(-6211, TSfxLevels.VolumeToAttenuation(1));
  Assert.AreEqual(-977, TSfxLevels.VolumeToAttenuation(8));
  Assert.AreEqual(0, TSfxLevels.VolumeToAttenuation(15));
end;

procedure TTestAudioSfxPlayer.TestWithoutDeviceOnlyHandles;
var
  LPlayer: ISfxPlayer;
begin
  LPlayer := MakePlayer(False);
  Assert.AreEqual(1, LPlayer.Start(5, 15, 128));
  Assert.AreEqual(2, LPlayer.Start(5, 15, 128));
  Assert.IsFalse(LPlayer.IsPlaying(1));
  LPlayer.Stop(1);
  LPlayer.UpdateParams(1, 1, 1);
  LPlayer.Shutdown;
  Assert.AreEqual(0, FDevice.Calls);
end;

procedure TTestAudioSfxPlayer.TestStartPlaysWithTheLevels;
var
  LHandle: Integer;
begin
  LHandle := FPlayer.Start(5, 15, 128);
  Assert.AreEqual(1, LHandle);
  Assert.AreEqual(1, FDevice.Voices.Count);
  Assert.IsTrue(FDevice.Voices[0].Loaded);
  Assert.AreEqual(1, FDevice.Voices[0].PlayCount);
  Assert.AreEqual(0, FDevice.Voices[0].Pan);
  Assert.AreEqual(0, FDevice.Voices[0].Volume);
  Assert.IsTrue(FPlayer.IsPlaying(LHandle));
end;

procedure TTestAudioSfxPlayer.TestHandlesOnlyGoUp;
begin
  Assert.AreEqual(1, FPlayer.Start(1, 15, 128));
  Assert.AreEqual(2, FPlayer.Start(2, 15, 128));
  Assert.AreEqual(3, FPlayer.Start(3, 15, 128));
end;

procedure TTestAudioSfxPlayer.TestSameSoundWhilePlayingUsesAnotherChannel;
begin
  FPlayer.Start(7, 15, 128);
  FPlayer.Start(7, 15, 128);
  Assert.AreEqual(2, FDevice.Voices.Count);
end;

procedure TTestAudioSfxPlayer.TestSameSoundAfterItIsOverRestartsTheVoice;
var
  LSecond: Integer;
begin
  FPlayer.Start(7, 15, 128);
  FDevice.Voices[0].Playing := False; // it is over
  LSecond := FPlayer.Start(7, 15, 128);
  Assert.AreEqual(1, FDevice.Voices.Count);
  Assert.AreEqual(2, FDevice.Voices[0].PlayCount);
  Assert.AreEqual(2, LSecond);
end;

procedure TTestAudioSfxPlayer.TestForgetSoundsStopsTheRestart;
begin
  FPlayer.Start(7, 15, 128);
  FDevice.Voices[0].Playing := False;
  FPlayer.ForgetSounds;
  FPlayer.Start(7, 15, 128);
  Assert.AreEqual(2, FDevice.Voices.Count);
end;

procedure TTestAudioSfxPlayer.TestStopStopsTheVoice;
var
  LHandle: Integer;
begin
  LHandle := FPlayer.Start(3, 15, 128);
  FPlayer.Stop(LHandle);
  Assert.IsFalse(FDevice.Voices[0].Playing);
  Assert.IsFalse(FPlayer.IsPlaying(LHandle));
end;

procedure TTestAudioSfxPlayer.TestUpdateParamsOnlyOnThePlayingHandle;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FPlayer.Start(1, 15, 128);
  LSecond := FPlayer.Start(2, 15, 128);
  FPlayer.UpdateParams(LSecond, 8, 0);
  Assert.AreEqual(0, FDevice.Voices[0].Volume);
  Assert.AreEqual(-977, FDevice.Voices[1].Volume);
  Assert.AreEqual(-1250, FDevice.Voices[1].Pan);
  FDevice.Voices[0].Playing := False;
  FPlayer.UpdateParams(LFirst, 1, 255);
  Assert.AreEqual(0, FDevice.Voices[0].Volume); // it is over: untouched
end;

procedure TTestAudioSfxPlayer.TestZeroLengthIsAWarningAndNoVoice;
begin
  FSource.Lengths.Add(9, 0);
  Assert.AreEqual(1, FPlayer.Start(9, 15, 128));
  Assert.AreEqual(0, FDevice.Voices.Count);
  Assert.IsTrue(Pos('has zero length', FRecorder.TextOf(TLogChannel.ErrorFile)) > 0);
  // the handle was not used
  Assert.AreEqual(1, FPlayer.Start(1, 15, 128));
end;

procedure TTestAudioSfxPlayer.TestFreeChannelIsPreferredToReplacing;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 4 do
    FPlayer.Start(LIndex, 15, 128);
  Assert.AreEqual(4, FDevice.Voices.Count);
end;

procedure TTestAudioSfxPlayer.TestWithAllChannelsUsedTheOldestIsReplaced;
var
  LIndex: Integer;
  LFirst: Integer;
begin
  LFirst := FPlayer.Start(1, 15, 128);
  for LIndex := 2 to TSfxPlayer.CHANNEL_COUNT do
    FPlayer.Start(LIndex, 15, 128);
  Assert.AreEqual(TSfxPlayer.CHANNEL_COUNT, FDevice.Voices.Count);
  FPlayer.Start(100, 15, 128);
  Assert.AreEqual(TSfxPlayer.CHANNEL_COUNT + 1, FDevice.Voices.Count);
  // the first sound lost its channel
  Assert.IsFalse(FPlayer.IsPlaying(LFirst));
  Assert.IsTrue(FPlayer.IsPlaying(TSfxPlayer.CHANNEL_COUNT));
end;

procedure TTestAudioSfxPlayer.TestRefusedFormatIsTriedWithTheAverageOfTheFormat;
begin
  FDevice.FailuresLeft := 1;
  Assert.AreEqual(1, FPlayer.Start(4, 15, 128));
  Assert.AreEqual(2, FDevice.Calls);
  Assert.AreEqual(Cardinal(99), FDevice.AverageBytesSeen[0]);
  Assert.AreEqual(Cardinal(11025), FDevice.AverageBytesSeen[1]);
  Assert.AreEqual(Cardinal(11025), FSource.StoredAverage);
end;

procedure TTestAudioSfxPlayer.TestExternalSoundThatFailsIsDiscardedAndLoadedAgain;
begin
  FSource.External := True;
  FDevice.FailuresLeft := 1;
  Assert.AreEqual(1, FPlayer.Start(4, 15, 128));
  Assert.AreEqual(1, FSource.DiscardCount);
  Assert.AreEqual(2, FSource.LoadCount);
  Assert.AreEqual(2, FDevice.Calls);
  Assert.IsTrue(Pos('will be discarded', FRecorder.TextOf(TLogChannel.ErrorFile)) > 0);
end;

procedure TTestAudioSfxPlayer.TestCreateFailingAlwaysRaisesAStartException;
var
  LMessage: string;
begin
  FDevice.FailuresLeft := 10;
  LMessage := '';
  try
    FPlayer.Start(4, 15, 128);
  except
    on E: ESfxStartException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(Pos('CreateSoundBuffer()', LMessage) > 0);
  Assert.IsTrue(Pos('DSPISTOL', LMessage) > 0);
  Assert.IsTrue(Pos('Sound id = 4', LMessage) > 0);
end;

procedure TTestAudioSfxPlayer.TestLoadFailingRaisesAStartException;
var
  LRaised: Boolean;
begin
  FDevice.NextLoadCode := 5;
  LRaised := False;
  try
    FPlayer.Start(4, 15, 128);
  except
    on E: ESfxStartException do
      LRaised := Pos('SoundBuffer.Lock()', E.Message) > 0;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestAudioSfxPlayer.TestShutdownStopsVoicesAndTheDevice;
begin
  FPlayer.Start(1, 15, 128);
  FPlayer.Start(2, 15, 128);
  FPlayer.Shutdown;
  Assert.IsFalse(FDevice.Voices[0].Playing);
  Assert.IsFalse(FDevice.Voices[1].Playing);
  Assert.AreEqual(1, FDevice.ShutdownCount);
end;

end.
