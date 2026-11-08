{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the factories                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.Factory;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Threading.Fakes, DelphiDoom.Tests.Threading.Helpers;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingFactory = class(TObject)
  private
    FLog: TFakeWorkerLog;
    FCounter: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCreareUnaFabbricaDiThreadCheDaWorkerFunzionanti;
    [Test]
    procedure DovrebbeDareWorkerDiversiAOgniChiamata;
    [Test]
    procedure DovrebbeRifiutareUnaFabbricaDiPoolSenzaFabbricaDiThread;
    [Test]
    procedure DovrebbeCreareUnPoolConIlNumeroDiThreadRichiesto;
    [Test]
    procedure DovrebbeCreareUnPoolVuoto;
    [Test]
    procedure DovrebbeUsareLaFabbricaDiThreadDataAllaFabbricaDiPool;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.Intf, DelphiDoom.Threading.Factory;

procedure TTestThreadingFactory.Setup;
begin
  FCounter := 0;
  FLog := TFakeWorkerLog.Create;
end;

procedure TTestThreadingFactory.TearDown;
begin
  FreeAndNil(FLog);
end;

procedure TTestThreadingFactory.DovrebbeCreareUnaFabbricaDiThreadCheDaWorkerFunzionanti;
var
  LWorker: IWorkerThread;
begin
  LWorker := TThreadingFactory.CreateThreadFactory.CreateWorker;
  LWorker.Submit(CountJob, @FCounter);
  LWorker.Wait;
  Assert.AreEqual(1, FCounter);
end;

procedure TTestThreadingFactory.DovrebbeDareWorkerDiversiAOgniChiamata;
var
  LFactory: IWorkerThreadFactory;
  LFirst: IWorkerThread;
  LSecond: IWorkerThread;
begin
  LFactory := TThreadingFactory.CreateThreadFactory;
  LFirst := LFactory.CreateWorker;
  LSecond := LFactory.CreateWorker;
  Assert.IsFalse(LFirst = LSecond);
end;

procedure TTestThreadingFactory.DovrebbeRifiutareUnaFabbricaDiPoolSenzaFabbricaDiThread;
begin
  Assert.WillRaise(
    procedure
    begin
      TThreadingFactory.CreatePoolFactory(nil);
    end, EArgumentNilException);
end;

procedure TTestThreadingFactory.DovrebbeCreareUnPoolConIlNumeroDiThreadRichiesto;
var
  LBefore: Integer;
  LDuring: Integer;
  LPool: IWorkerPool;
begin
  LBefore := TThreadCounter.Count;
  LPool := TThreadingFactory.CreatePool(6);
  LDuring := TThreadCounter.Count;
  Assert.AreEqual(6, LPool.Count);
  Assert.IsTrue(LDuring >= LBefore + 6,
    Format('Threads of the process: %d before, %d with the pool', [LBefore, LDuring]));
  LPool := nil;
  TThreadCounter.AssertNotAbove(LBefore);
end;

procedure TTestThreadingFactory.DovrebbeCreareUnPoolVuoto;
var
  LPool: IWorkerPool;
begin
  LPool := TThreadingFactory.CreatePool(0);
  Assert.AreEqual(0, LPool.Count);
end;

procedure TTestThreadingFactory.DovrebbeUsareLaFabbricaDiThreadDataAllaFabbricaDiPool;
var
  LThreads: IWorkerThreadFactory;
  LPool: IWorkerPool;
begin
  LThreads := TFakeWorkerFactory.Create(FLog);
  LPool := TThreadingFactory.CreatePoolFactory(LThreads).CreatePool(3);
  Assert.AreEqual(3, LPool.Count);
  LPool := nil;
  Assert.AreEqual(3, FLog.Destroyed);
end;

end.
