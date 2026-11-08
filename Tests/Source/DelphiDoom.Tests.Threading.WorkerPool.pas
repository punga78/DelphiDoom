{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the pool of workers             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.WorkerPool;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Threading.Intf, DelphiDoom.Tests.Threading.Fakes,
  DelphiDoom.Tests.Threading.Helpers;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingWorkerPool = class(TObject)
  private
    FLog: TFakeWorkerLog;
    FFactory: TFakeWorkerFactory;
    FFactoryIntf: IWorkerThreadFactory;
    FPool: IWorkerPool;
    FCounter: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCreareIlNumeroDiWorkerRichiesto;
    [Test]
    procedure DovrebbeAccettareUnPoolVuoto;
    [Test]
    procedure DovrebbeRifiutareUnaFabbricaNil;
    [Test]
    procedure DovrebbeRifiutareUnNumeroNegativo;
    [Test]
    procedure DovrebbeDareIWorkerPerIndice;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriIntervallo;
    [Test]
    procedure DovrebbeAspettareTuttiIWorkerInOrdine;
    [Test]
    procedure DovrebbeAspettareTuttiPoiRiportareIlPrimoErrore;
    [Test]
    procedure DovrebbeChiudereTuttiIWorker;
    [Test]
    procedure DovrebbeChiudereEliberareIWorkerAllaDistruzione;
    [Test]
    procedure DovrebbeLiberareIWorkerGiaCreatiSeUnaCreazioneFallisce;
    [Test]
    procedure DovrebbeEseguireUnLavoroSuOgniWorkerVero;
    [Test]
    procedure DovrebbeRiportareLErroreDiUnLavoroConWaitAllEdEseguireGliAltri;
    [Test]
    procedure DovrebbeNonLasciareThreadViviDopoMigliaiaDiPool;
    [Test]
    procedure DovrebbeChiudereIlPoolConTuttiIWorkerOccupati;
  end;

implementation

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.Threading.Types, DelphiDoom.Threading.WorkerPool,
  DelphiDoom.Threading.Factory;

procedure TTestThreadingWorkerPool.Setup;
begin
  FCounter := 0;
  FLog := TFakeWorkerLog.Create;
  FFactory := TFakeWorkerFactory.Create(FLog);
  FFactoryIntf := FFactory;
end;

procedure TTestThreadingWorkerPool.TearDown;
begin
  // the workers refer to the log: they go first
  FPool := nil;
  FFactoryIntf := nil;
  FFactory := nil;
  FreeAndNil(FLog);
end;

procedure TTestThreadingWorkerPool.DovrebbeCreareIlNumeroDiWorkerRichiesto;
begin
  FPool := TWorkerPool.Create(5, FFactoryIntf);
  Assert.AreEqual(5, FPool.Count);
  Assert.AreEqual(5, FFactory.Created);
end;

procedure TTestThreadingWorkerPool.DovrebbeAccettareUnPoolVuoto;
begin
  FPool := TWorkerPool.Create(0, FFactoryIntf);
  Assert.AreEqual(0, FPool.Count);
  FPool.WaitAll;
  FPool.Shutdown;
  Assert.AreEqual(0, FLog.Shutdowns);
end;

procedure TTestThreadingWorkerPool.DovrebbeRifiutareUnaFabbricaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FPool := TWorkerPool.Create(3, nil);
    end, EArgumentNilException);
end;

procedure TTestThreadingWorkerPool.DovrebbeRifiutareUnNumeroNegativo;
begin
  Assert.WillRaise(
    procedure
    begin
      FPool := TWorkerPool.Create(-1, FFactoryIntf);
    end, EArgumentOutOfRangeException);
  Assert.AreEqual(0, FFactory.Created);
end;

procedure TTestThreadingWorkerPool.DovrebbeDareIWorkerPerIndice;
begin
  FPool := TWorkerPool.Create(3, FFactoryIntf);
  Assert.IsTrue(Assigned(FPool.Workers[0]));
  Assert.IsTrue(Assigned(FPool[2]));
  // each worker is a different one: the fake gives its own number as the last result
  Assert.AreEqual(0, FPool[0].LastResult);
  Assert.AreEqual(1, FPool[1].LastResult);
  Assert.AreEqual(2, FPool[2].LastResult);
end;

procedure TTestThreadingWorkerPool.DovrebbeRifiutareUnIndiceFuoriIntervallo;
begin
  FPool := TWorkerPool.Create(3, FFactoryIntf);
  Assert.WillRaise(
    procedure
    begin
      FPool.GetWorker(-1);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FPool.GetWorker(3);
    end, EArgumentOutOfRangeException);
end;

procedure TTestThreadingWorkerPool.DovrebbeAspettareTuttiIWorkerInOrdine;
begin
  FPool := TWorkerPool.Create(3, FFactoryIntf);
  FPool.WaitAll;
  Assert.AreEqual(3, FLog.Waits.Count);
  Assert.AreEqual(0, FLog.Waits[0]);
  Assert.AreEqual(1, FLog.Waits[1]);
  Assert.AreEqual(2, FLog.Waits[2]);
end;

procedure TTestThreadingWorkerPool.DovrebbeAspettareTuttiPoiRiportareIlPrimoErrore;
var
  LClassName: string;
begin
  FLog.FailingIndexes.Add(1);
  FLog.FailingIndexes.Add(3);
  FPool := TWorkerPool.Create(4, FFactoryIntf);
  LClassName := '';
  try
    FPool.WaitAll;
    Assert.Fail('WaitAll should have raised');
  except
    on E: EWorkerJobException do
      LClassName := E.OriginalClassName;
  end;
  Assert.AreEqual('FakeError1', LClassName);
  // every worker was waited for, even after the first failure
  Assert.AreEqual(4, FLog.Waits.Count);
end;

procedure TTestThreadingWorkerPool.DovrebbeChiudereTuttiIWorker;
begin
  FPool := TWorkerPool.Create(4, FFactoryIntf);
  FPool.Shutdown;
  Assert.AreEqual(4, FLog.Shutdowns);
end;

procedure TTestThreadingWorkerPool.DovrebbeChiudereEliberareIWorkerAllaDistruzione;
begin
  FPool := TWorkerPool.Create(4, FFactoryIntf);
  FPool := nil;
  Assert.AreEqual(4, FLog.Shutdowns);
  Assert.AreEqual(4, FLog.Destroyed);
end;

procedure TTestThreadingWorkerPool.DovrebbeLiberareIWorkerGiaCreatiSeUnaCreazioneFallisce;
var
  LFailing: IWorkerThreadFactory;
begin
  LFailing := TFakeWorkerFactory.Create(FLog, 2);
  Assert.WillRaise(
    procedure
    begin
      FPool := TWorkerPool.Create(5, LFailing);
    end, EThreadingException);
  Assert.IsFalse(Assigned(FPool));
  Assert.AreEqual(2, FLog.Destroyed);
end;

procedure TTestThreadingWorkerPool.DovrebbeEseguireUnLavoroSuOgniWorkerVero;
var
  LIndex: Integer;
begin
  FPool := TThreadingFactory.CreatePool(8);
  for LIndex := 0 to FPool.Count - 1 do
    FPool[LIndex].Submit(CountJob, @FCounter);
  FPool.WaitAll;
  Assert.AreEqual(8, FCounter);
end;

procedure TTestThreadingWorkerPool.DovrebbeRiportareLErroreDiUnLavoroConWaitAllEdEseguireGliAltri;
var
  LRaised: Boolean;
begin
  FPool := TThreadingFactory.CreatePool(4);
  FPool[0].Submit(CountJob, @FCounter);
  FPool[1].Submit(RaiseJob, nil);
  FPool[2].Submit(CountJob, @FCounter);
  LRaised := False;
  try
    FPool.WaitAll;
  except
    on EWorkerJobException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  Assert.AreEqual(2, FCounter);
end;

procedure TTestThreadingWorkerPool.DovrebbeNonLasciareThreadViviDopoMigliaiaDiPool;
var
  LBefore: Integer;
  LCycle: Integer;
  LIndex: Integer;
  LPool: IWorkerPool;
  LFactory: IWorkerPoolFactory;
begin
  LBefore := TThreadCounter.Count;
  LFactory := TThreadingFactory.CreatePoolFactory(TThreadingFactory.CreateThreadFactory);
  for LCycle := 1 to 300 do
  begin
    LPool := LFactory.CreatePool(8);
    for LIndex := 0 to LPool.Count - 1 do
      LPool[LIndex].Submit(CountJob, @FCounter);
    LPool.WaitAll;
    LPool := nil;
  end;
  Assert.AreEqual(2400, FCounter);
  TThreadCounter.AssertNotAbove(LBefore);
end;

procedure TTestThreadingWorkerPool.DovrebbeChiudereIlPoolConTuttiIWorkerOccupati;
const
  WORKERS = 8;
var
  LJobs: array[0..WORKERS - 1] of TBlockingJob;
  LSetters: array[0..WORKERS - 1] of TEventSetterThread;
  LIndex: Integer;
  LBefore: Integer;
begin
  LBefore := TThreadCounter.Count;
  for LIndex := 0 to WORKERS - 1 do
  begin
    InitBlockingJob(LJobs[LIndex]);
    LSetters[LIndex] := nil;
  end;
  FPool := TThreadingFactory.CreatePool(WORKERS);
  try
    for LIndex := 0 to WORKERS - 1 do
    begin
      FPool[LIndex].Submit(BlockJob, @LJobs[LIndex]);
      Assert.IsTrue(LJobs[LIndex].Started.WaitFor(TEST_TIMEOUT) = wrSignaled,
        'a job did not start');
    end;
    for LIndex := 0 to WORKERS - 1 do
    begin
      LSetters[LIndex] := TEventSetterThread.Create(LJobs[LIndex].Release);
      LSetters[LIndex].Start;
    end;
    // the pool is closed while every worker is busy (or just released): no job is lost
    FPool.Shutdown;
    for LIndex := 0 to WORKERS - 1 do
      Assert.AreEqual(1, LJobs[LIndex].Finished);
  finally
    for LIndex := 0 to WORKERS - 1 do
      if Assigned(LSetters[LIndex]) then
      begin
        LSetters[LIndex].WaitFor;
        LSetters[LIndex].Free;
      end;
    for LIndex := 0 to WORKERS - 1 do
      LJobs[LIndex].Release.SetEvent;
    FPool := nil;
    for LIndex := 0 to WORKERS - 1 do
      DoneBlockingJob(LJobs[LIndex]);
  end;
  TThreadCounter.AssertNotAbove(LBefore);
end;

end.
