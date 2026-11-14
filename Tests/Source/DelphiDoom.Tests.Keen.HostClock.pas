{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of Keen32 - TimeCount on the clock of the machine, and     }
{  the speed of the loops that wait for it                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.HostClock;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.HostClock,
  DelphiDoom.Clock.Intf, DelphiDoom.Clock.ManualClock;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenHostClock = class(TObject)
  strict private
    FManual: TManualClock;
    FClock: IClock;
    FHost: TKeenHostClock;
    FHostKeeper: IKeenClock;
    /// <summary>
    ///   What RF_Refresh does at its end: wait until 2 tics (MINTICS) went by since the last refresh, looking at
    ///   TimeCount and calling Idle in between. Returns the refreshes made in the given seconds of the clock.
    ///   A sleep of ASleepMilliseconds is what Idle costs: 1 with the fine timer, about 16 without it
    /// </summary>
    function RefreshesIn(ASeconds, ASleepMilliseconds: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeContareSettantaTicAlSecondo;
    [Test]
    procedure DovrebbeContareITicUnoAlla;
    [Test]
    procedure DovrebbePartireDaZero;
    [Test]
    procedure DovrebbeObbedireAllaScritturaDelTimeCount;
    [Test]
    procedure UnaScritturaDovrebbeLasciareIlPassoDelTempo;
    [Test]
    procedure IdleSenzaGestoreDovrebbeDormireUnMillisecondo;
    [Test]
    procedure IdleDovrebbeChiamareIlGestoreSeCeE;
    [Test]
    procedure DovrebbeRifiutareUnOrologioNil;
    [Test]
    procedure ConIlTimerFineIlRefreshDovrebbeFareTrentacinqAlSecondo;
    [Test]
    procedure ConIlTimerGrossolanoIlRefreshDovrebbeScendereSottoITrentacinque;
  end;

implementation

procedure TTestKeenHostClock.Setup;
begin
  FManual := TManualClock.Create;
  FClock := FManual;
  FHost := TKeenHostClock.Create(FClock);
  FHostKeeper := FHost;
end;

procedure TTestKeenHostClock.TearDown;
begin
  FHost := nil;
  FHostKeeper := nil;
  FClock := nil;
  FManual := nil;
end;

function TTestKeenHostClock.RefreshesIn(ASeconds, ASleepMilliseconds: Integer): Integer;
var
  LLast: Integer;
  LNow: Integer;
  LEnd: Double;
begin
  Result := 0;
  FHost.OnIdle :=
    procedure
    begin
      FClock.Sleep(ASleepMilliseconds);
    end;
  LLast := FHostKeeper.TimeCount;
  LEnd := FClock.Seconds + ASeconds;
  while FClock.Seconds < LEnd do
  begin
    repeat
      LNow := FHostKeeper.TimeCount;
      if LNow - LLast < KEEN_MINTICS then
        FHostKeeper.Idle;
    until LNow - LLast >= KEEN_MINTICS;
    LLast := LNow;
    Inc(Result);
  end;
end;

procedure TTestKeenHostClock.DovrebbeContareSettantaTicAlSecondo;
begin
  FManual.Advance(1000);
  Assert.AreEqual(70, FHostKeeper.TimeCount);
  FManual.Advance(9000);
  Assert.AreEqual(700, FHostKeeper.TimeCount);
end;

procedure TTestKeenHostClock.DovrebbeContareITicUnoAlla;
var
  LMillisecond: Integer;
  LPrevious: Integer;
  LCurrent: Integer;
begin
  // a tic every 14.28 ms: the count never goes back and never jumps by more than one
  LPrevious := FHostKeeper.TimeCount;
  for LMillisecond := 1 to 3000 do
  begin
    FManual.Advance(1);
    LCurrent := FHostKeeper.TimeCount;
    Assert.IsTrue((LCurrent = LPrevious) or (LCurrent = LPrevious + 1), 'at ' + IntToStr(LMillisecond));
    LPrevious := LCurrent;
  end;
  Assert.AreEqual(210, LPrevious);
end;

procedure TTestKeenHostClock.DovrebbePartireDaZero;
begin
  FManual.Advance(5000);
  FHost := TKeenHostClock.Create(FClock);
  FHostKeeper := FHost;
  Assert.AreEqual(0, FHostKeeper.TimeCount);
end;

procedure TTestKeenHostClock.DovrebbeObbedireAllaScritturaDelTimeCount;
begin
  FManual.Advance(1000);
  FHostKeeper.TimeCount := 0;
  Assert.AreEqual(0, FHostKeeper.TimeCount);
  FManual.Advance(1000);
  Assert.AreEqual(70, FHostKeeper.TimeCount);
  FHostKeeper.TimeCount := 500;
  Assert.AreEqual(500, FHostKeeper.TimeCount);
end;

procedure TTestKeenHostClock.UnaScritturaDovrebbeLasciareIlPassoDelTempo;
begin
  // the game takes tics back when a frame was too long: the clock keeps its pace
  FManual.Advance(1000);
  FHostKeeper.TimeCount := FHostKeeper.TimeCount - 4;
  Assert.AreEqual(66, FHostKeeper.TimeCount);
  FManual.Advance(1000);
  Assert.AreEqual(136, FHostKeeper.TimeCount);
end;

procedure TTestKeenHostClock.IdleSenzaGestoreDovrebbeDormireUnMillisecondo;
var
  LBefore: Double;
begin
  LBefore := FClock.Seconds;
  FHostKeeper.Idle;
  Assert.AreEqual<Int64>(1, Round((FClock.Seconds - LBefore) * 1000));
end;

procedure TTestKeenHostClock.IdleDovrebbeChiamareIlGestoreSeCeE;
var
  LCalls: Integer;
begin
  LCalls := 0;
  FHost.OnIdle :=
    procedure
    begin
      Inc(LCalls);
    end;
  FHostKeeper.Idle;
  FHostKeeper.Idle;
  Assert.AreEqual(2, LCalls);
  // the handler replaces the sleep: the clock did not move
  Assert.AreEqual(0, FHostKeeper.TimeCount);
end;

procedure TTestKeenHostClock.DovrebbeRifiutareUnOrologioNil;
var
  LNone: IClock;
begin
  LNone := nil;
  Assert.WillRaise(
    procedure
    begin
      TKeenHostClock.Create(LNone).Free;
    end, EArgumentNilException);
end;

procedure TTestKeenHostClock.ConIlTimerFineIlRefreshDovrebbeFareTrentacinqAlSecondo;
begin
  // 70 / MINTICS: the ceiling of the original
  Assert.AreEqual(350, RefreshesIn(10, 1));
end;

procedure TTestKeenHostClock.ConIlTimerGrossolanoIlRefreshDovrebbeScendereSottoITrentacinque;
var
  LRefreshes: Integer;
begin
  // Sleep(1) that lasts a tick of Windows (15.6 ms): a refresh of 2 tics waits 2 sleeps, 32 ms, 2.2 tics (the real program measured 30 a second)
  LRefreshes := RefreshesIn(10, 16);
  Assert.IsTrue(LRefreshes < 340, 'refreshes in 10 s: ' + IntToStr(LRefreshes));
  Assert.IsTrue(LRefreshes > 250, 'refreshes in 10 s: ' + IntToStr(LRefreshes));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenHostClock);

end.
