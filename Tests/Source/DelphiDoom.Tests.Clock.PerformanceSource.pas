{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the clock library - the source on the system counters  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Clock.PerformanceSource;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Clock.Intf;

type
  /// <summary>Counters that answer what the test says</summary>
  TFakeClockCounters = class(TInterfacedObject, IClockCounters)
  public
    HasFrequency: Boolean;
    Frequency: Int64;
    CounterWorks: Boolean;
    Counter: Int64;
    Ticks: Cardinal;
    SleptFor: Integer;
    function QueryFrequency(out AFrequency: Int64): Boolean;
    function QueryCounter(out ACounter: Int64): Boolean;
    function TickCount: Cardinal;
    procedure Sleep(AMilliseconds: Integer);
  end;

  [TestFixture]
  [Category('clock')]
  TTestClockPerformanceSource = class(TObject)
  private
    FCounters: TFakeClockCounters;
    FCountersIntf: IClockCounters;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareContatoriMancanti;
    [Test]
    procedure DovrebbeLeggereIlContatoreAdAltaRisoluzione;
    [Test]
    procedure DovrebbeUsareIMillisecondiSenzaContatore;
    [Test]
    procedure DovrebbePassareAiMillisecondiSeIlContatoreFallisce;
    [Test]
    procedure DovrebbeUsareIMillisecondiSeLaFrequenzaEMille;
    [Test]
    procedure DovrebbeDormireConIContatori;
    [Test]
    procedure DovrebbeLeggereIContatoriDiWindows;
  end;

implementation

uses
  DelphiDoom.Clock.PerformanceSource, DelphiDoom.Clock.WindowsCounters;

{ TFakeClockCounters }

function TFakeClockCounters.QueryFrequency(out AFrequency: Int64): Boolean;
begin
  AFrequency := Frequency;
  Result := HasFrequency;
end;

function TFakeClockCounters.QueryCounter(out ACounter: Int64): Boolean;
begin
  ACounter := Counter;
  Result := CounterWorks;
end;

function TFakeClockCounters.TickCount: Cardinal;
begin
  Result := Ticks;
end;

procedure TFakeClockCounters.Sleep(AMilliseconds: Integer);
begin
  SleptFor := AMilliseconds;
end;

{ TTestClockPerformanceSource }

procedure TTestClockPerformanceSource.Setup;
begin
  FCounters := TFakeClockCounters.Create;
  FCountersIntf := FCounters;
  FCounters.HasFrequency := True;
  FCounters.Frequency := 3579545;
  FCounters.CounterWorks := True;
  FCounters.Counter := 123456789;
  FCounters.Ticks := 4242;
end;

procedure TTestClockPerformanceSource.TearDown;
begin
  FCountersIntf := nil;
  FCounters := nil;
end;

procedure TTestClockPerformanceSource.DovrebbeRifiutareContatoriMancanti;
begin
  Assert.WillRaise(
    procedure
    begin
      TPerformanceClockSource.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestClockPerformanceSource.DovrebbeLeggereIlContatoreAdAltaRisoluzione;
var
  LSource: IClockSource;
begin
  LSource := TPerformanceClockSource.Create(FCountersIntf);
  Assert.AreEqual(Int64(3579545), LSource.Frequency);
  Assert.AreEqual(Int64(123456789), LSource.Read);
end;

procedure TTestClockPerformanceSource.DovrebbeUsareIMillisecondiSenzaContatore;
var
  LSource: IClockSource;
begin
  FCounters.HasFrequency := False;
  LSource := TPerformanceClockSource.Create(FCountersIntf);
  Assert.AreEqual(Int64(1000), LSource.Frequency);
  Assert.AreEqual(Int64(4242), LSource.Read);
end;

procedure TTestClockPerformanceSource.DovrebbePassareAiMillisecondiSeIlContatoreFallisce;
var
  LSource: IClockSource;
begin
  LSource := TPerformanceClockSource.Create(FCountersIntf);
  Assert.AreEqual(Int64(123456789), LSource.Read);
  FCounters.CounterWorks := False;
  Assert.AreEqual(Int64(4242), LSource.Read);
  Assert.AreEqual(Int64(1000), LSource.Frequency);
  // Once it has given up the counter it does not go back to it
  FCounters.CounterWorks := True;
  FCounters.Ticks := 5000;
  Assert.AreEqual(Int64(5000), LSource.Read);
end;

procedure TTestClockPerformanceSource.DovrebbeUsareIMillisecondiSeLaFrequenzaEMille;
var
  LSource: IClockSource;
begin
  FCounters.Frequency := 1000;
  LSource := TPerformanceClockSource.Create(FCountersIntf);
  Assert.AreEqual(Int64(4242), LSource.Read);
end;

procedure TTestClockPerformanceSource.DovrebbeDormireConIContatori;
var
  LSource: IClockSource;
begin
  LSource := TPerformanceClockSource.Create(FCountersIntf);
  LSource.Sleep(17);
  Assert.AreEqual(17, FCounters.SleptFor);
end;

procedure TTestClockPerformanceSource.DovrebbeLeggereIContatoriDiWindows;
var
  LCounters: IClockCounters;
  LFrequency, LFirst, LSecond: Int64;
begin
  // The counter of Windows exists on every system since Windows XP
  LCounters := TWindowsClockCounters.Create;
  Assert.IsTrue(LCounters.QueryFrequency(LFrequency));
  Assert.IsTrue(LFrequency > 0);
  Assert.IsTrue(LCounters.QueryCounter(LFirst));
  Assert.IsTrue(LCounters.QueryCounter(LSecond));
  Assert.IsTrue(LSecond >= LFirst);
  Assert.IsTrue(LCounters.TickCount > 0);
  // Zero gives the rest of the time slice back and returns
  LCounters.Sleep(0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestClockPerformanceSource);

end.
