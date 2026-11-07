{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thread that plays the tracker                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.ThreadWorker;

// The work only waits for an event that the test sets: no time goes by and
// the order of the steps is fixed

interface

uses
  System.SysUtils,
  System.SyncObjs,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Output.Intf;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerThreadWorker = class(TObject)
  private
    FWorker: ITrackerWorker;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonFareNullaSenzaLavoro;
    [Test]
    procedure DovrebbeFareIlLavoroInUnAltroThread;
    [Test]
    procedure DovrebbeEssereInCorsoFinoAllaFineDelLavoro;
    [Test]
    procedure DovrebbeFareUnLavoroDopoLAltro;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Tracker.ThreadWorker;

const
  // Only a broken worker would make the test wait this long
  EVENT_TIMEOUT_MS = 10000;

{ TTestTrackerThreadWorker }

procedure TTestTrackerThreadWorker.Setup;
begin
  FWorker := TTrackerThreadWorker.Create;
end;

procedure TTestTrackerThreadWorker.TearDown;
begin
  FWorker := nil;
end;

procedure TTestTrackerThreadWorker.DovrebbeNonFareNullaSenzaLavoro;
begin
  Assert.IsFalse(FWorker.IsRunning);
  FWorker.WaitFor;
  Assert.IsFalse(FWorker.IsRunning);
end;

procedure TTestTrackerThreadWorker.DovrebbeFareIlLavoroInUnAltroThread;
var
  LThreadId: TThreadID;
begin
  LThreadId := TThread.CurrentThread.ThreadID;
  FWorker.Start(
    procedure
    begin
      LThreadId := TThread.CurrentThread.ThreadID;
    end);
  FWorker.WaitFor;

  Assert.AreNotEqual(Integer(MainThreadID), Integer(LThreadId));
  Assert.IsFalse(FWorker.IsRunning);
end;

procedure TTestTrackerThreadWorker.DovrebbeEssereInCorsoFinoAllaFineDelLavoro;
var
  LGo: TEvent;
begin
  LGo := TEvent.Create(nil, True, False, '');
  try
    FWorker.Start(
      procedure
      begin
        LGo.WaitFor(EVENT_TIMEOUT_MS);
      end);
    Assert.IsTrue(FWorker.IsRunning);
    LGo.SetEvent;
    FWorker.WaitFor;
    Assert.IsFalse(FWorker.IsRunning);
  finally
    LGo.Free;
  end;
end;

procedure TTestTrackerThreadWorker.DovrebbeFareUnLavoroDopoLAltro;
var
  LCount: Integer;
begin
  LCount := 0;
  FWorker.Start(
    procedure
    begin
      TInterlocked.Increment(LCount);
    end);
  // Start waits for the work before
  FWorker.Start(
    procedure
    begin
      TInterlocked.Increment(LCount);
    end);
  // The destructor waits for the last one
  FWorker := nil;

  Assert.AreEqual(2, LCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerThreadWorker);

end.
