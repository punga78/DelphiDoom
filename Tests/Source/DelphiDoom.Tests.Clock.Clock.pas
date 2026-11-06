{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the clock library - the clock                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Clock.Clock;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Clock.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Recorder;

type
  /// <summary>A source that moves only when the test says so</summary>
  TFakeClockSource = class(TInterfacedObject, IClockSource)
  public
    Counter: Int64;
    Frequency: Int64;
    SleepCalls: Integer;
    /// <summary>Every sleep moves the counter by this much (0 = never)</summary>
    StepOnSleep: Int64;
    function GetFrequency: Int64;
    function Read: Int64;
    procedure Sleep(AMilliseconds: Integer);
  end;

  [TestFixture]
  [Category('clock')]
  TTestClockClock = class(TObject)
  private
    FSource: TFakeClockSource;
    FSourceIntf: IClockSource;
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    function MakeClock: IClock;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTheFirstReadingIsZero;
    [Test]
    procedure TestSecondsAreCounterOverFrequency;
    [Test]
    procedure TestStepsAreTruncated;
    [Test]
    procedure TestScaledStepsKeepTheFixedPointPart;
    [Test]
    procedure TestBaseIsTheFirstReadingNotTheCreation;
    [Test]
    procedure TestSleepGoesToTheSource;
    [Test]
    procedure TestWaitSleepsUntilTheTimeHasPassed;
    [Test]
    procedure TestWaitZeroReturnsAtOnce;
    [Test]
    procedure TestNewFrequencyRestartsTimeAndWarns;
    [Test]
    procedure TestNoLogIsFine;
    [Test]
    procedure TestRealSourceNeverGoesBack;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory,
  DelphiDoom.Clock.Factory;

{ TFakeClockSource }

function TFakeClockSource.GetFrequency: Int64;
begin
  Result := Frequency;
end;

function TFakeClockSource.Read: Int64;
begin
  Result := Counter;
end;

procedure TFakeClockSource.Sleep(AMilliseconds: Integer);
begin
  Inc(SleepCalls);
  Inc(Counter, StepOnSleep);
end;

{ TTestClockClock }

procedure TTestClockClock.Setup;
begin
  FSource := TFakeClockSource.Create;
  FSource.Frequency := 1000;
  FSource.Counter := 5000;
  FSourceIntf := FSource;
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
end;

procedure TTestClockClock.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
  FSourceIntf := nil;
  FSource := nil;
end;

function TTestClockClock.MakeClock: IClock;
begin
  Result := TClockFactory.CreateClock(FSourceIntf,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
end;

procedure TTestClockClock.TestTheFirstReadingIsZero;
begin
  Assert.AreEqual(0.0, MakeClock.Seconds, 0.0000001);
end;

procedure TTestClockClock.TestSecondsAreCounterOverFrequency;
var
  LClock: IClock;
begin
  LClock := MakeClock;
  LClock.Seconds;
  FSource.Counter := 7500;
  Assert.AreEqual(2.5, LClock.Seconds, 0.0000001);
end;

procedure TTestClockClock.TestStepsAreTruncated;
var
  LClock: IClock;
begin
  LClock := MakeClock;
  LClock.Seconds;
  FSource.Counter := 5000 + 999;
  Assert.AreEqual(34, LClock.Steps(35));
  FSource.Counter := 5000 + 1000;
  Assert.AreEqual(35, LClock.Steps(35));
end;

procedure TTestClockClock.TestScaledStepsKeepTheFixedPointPart;
var
  LClock: IClock;
begin
  LClock := MakeClock;
  LClock.Seconds;
  FSource.Counter := 5000 + 500;
  Assert.AreEqual(35 * 65536 div 2, LClock.ScaledSteps(35, 65536));
end;

procedure TTestClockClock.TestBaseIsTheFirstReadingNotTheCreation;
var
  LClock: IClock;
begin
  LClock := MakeClock;
  FSource.Counter := 9000;
  Assert.AreEqual(0.0, LClock.Seconds, 0.0000001);
  FSource.Counter := 10000;
  Assert.AreEqual(1.0, LClock.Seconds, 0.0000001);
end;

procedure TTestClockClock.TestSleepGoesToTheSource;
begin
  MakeClock.Sleep(10);
  Assert.AreEqual(1, FSource.SleepCalls);
end;

procedure TTestClockClock.TestWaitSleepsUntilTheTimeHasPassed;
var
  LClock: IClock;
begin
  FSource.StepOnSleep := 10;
  LClock := MakeClock;
  LClock.Wait(100);
  Assert.IsTrue(FSource.SleepCalls >= 10);
  Assert.IsTrue(LClock.Seconds >= 0.1);
end;

procedure TTestClockClock.TestWaitZeroReturnsAtOnce;
begin
  FSource.StepOnSleep := 1;
  MakeClock.Wait(0);
  Assert.IsTrue(FSource.SleepCalls <= 1);
end;

procedure TTestClockClock.TestNewFrequencyRestartsTimeAndWarns;
var
  LClock: IClock;
begin
  LClock := MakeClock;
  LClock.Seconds;
  FSource.Counter := 9000;
  Assert.AreEqual(4.0, LClock.Seconds, 0.0000001);
  FSource.Frequency := 500;
  FSource.Counter := 20000;
  Assert.AreEqual(0.0, LClock.Seconds, 0.0000001);
  FSource.Counter := 21000;
  Assert.AreEqual(2.0, LClock.Seconds, 0.0000001);
  Assert.AreEqual(1, FRecorder.Count div 2);
  Assert.IsTrue(Pos('I_Warning: ', FRecorder.TextOf(TLogChannel.Output)) = 1);
end;

procedure TTestClockClock.TestNoLogIsFine;
var
  LClock: IClock;
begin
  LClock := TClockFactory.CreateClock(FSourceIntf, nil);
  LClock.Seconds;
  FSource.Frequency := 10;
  Assert.AreEqual(0.0, LClock.Seconds, 0.0000001);
end;

procedure TTestClockClock.TestRealSourceNeverGoesBack;
var
  LClock: IClock;
  LFirst: Double;
  LSecond: Double;
begin
  LClock := TClockFactory.CreateClock(nil);
  LFirst := LClock.Seconds;
  LSecond := LClock.Seconds;
  Assert.AreEqual(0.0, LFirst, 0.0000001);
  Assert.IsTrue(LSecond >= LFirst);
end;

end.
