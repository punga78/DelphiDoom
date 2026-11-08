{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the worker thread               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.WorkerThread;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Threading.Intf, DelphiDoom.Tests.Threading.Helpers;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingWorkerThread = class(TObject)
  private
    FFactory: IWorkerThreadFactory;
    FWorker: IWorkerThread;
    FCounter: Integer;
    procedure RunBusyShutdownCycle;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereInattivoSubitoDopoLaCreazione;
    [Test]
    procedure DovrebbeEseguireUnLavoro;
    [Test]
    procedure DovrebbeDareIlRisultatoDelLavoro;
    [Test]
    procedure DovrebbeRifiutareUnLavoroSenzaProcedura;
    [Test]
    procedure DovrebbeNonEssereInattivoMentreIlLavoroGira;
    [Test]
    procedure DovrebbeRiportareLEccezioneDelLavoroAllAttesa;
    [Test]
    procedure DovrebbeRiportareLEccezioneUnaSolaVolta;
    [Test]
    procedure DovrebbeFunzionareDopoUnaEccezione;
    [Test]
    procedure DovrebbeRiportareLEccezionePrecedenteAlProssimoLavoro;
    [Test]
    procedure DovrebbeAspettareIlLavoroPrecedenteQuandoNeArrivaUnAltro;
    [Test]
    procedure DovrebbeChiudersiPiuVolte;
    [Test]
    procedure DovrebbeRifiutareLavoriDopoLaChiusura;
    [Test]
    procedure DovrebbeAspettareIlLavoroInCorsoQuandoSiChiudeDaUnAltroThread;
    [Test]
    procedure DovrebbeLiberareIlThreadAllaDistruzione;
    [Test]
    procedure DovrebbeResistereAMigliaiaDiCreazioniEDistruzioni;
    [Test]
    procedure DovrebbeNonPerdereIlLavoroSeLoDistruggeSubito;
    [Test]
    procedure DovrebbeChiudersiConIlThreadOccupatoMigliaiaDiVolte;
    [Test]
    procedure DovrebbeEseguireMolteMigliaiaDiLavoriBrevi;
    [Test]
    procedure DovrebbeEseguireMolteMigliaiaDiLavoriSenzaAttenderliUnoAUno;
    [Test]
    procedure DovrebbeRiportareLEccezioneDiOgniLavoroInUnaSerie;
    [Test]
    procedure DovrebbeEseguireTuttiILavoriAssegnatiDaPiuThread;
  end;

implementation

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.Threading.Types, DelphiDoom.Threading.Factory;

procedure TTestThreadingWorkerThread.Setup;
begin
  FCounter := 0;
  FFactory := TThreadingFactory.CreateThreadFactory;
  FWorker := FFactory.CreateWorker;
end;

procedure TTestThreadingWorkerThread.TearDown;
begin
  FWorker := nil;
  FFactory := nil;
end;

procedure TTestThreadingWorkerThread.DovrebbeEssereInattivoSubitoDopoLaCreazione;
begin
  Assert.IsTrue(FWorker.IsIdle);
  FWorker.Wait;
  Assert.AreEqual(0, FWorker.LastResult);
end;

procedure TTestThreadingWorkerThread.DovrebbeEseguireUnLavoro;
begin
  FWorker.Submit(CountJob, @FCounter);
  FWorker.Wait;
  Assert.AreEqual(1, FCounter);
  Assert.IsTrue(FWorker.IsIdle);
end;

procedure TTestThreadingWorkerThread.DovrebbeDareIlRisultatoDelLavoro;
var
  LValue: Integer;
begin
  LValue := 42;
  FWorker.Submit(ResultJob, @LValue);
  FWorker.Wait;
  Assert.AreEqual(42, FWorker.LastResult);
end;

procedure TTestThreadingWorkerThread.DovrebbeRifiutareUnLavoroSenzaProcedura;
begin
  Assert.WillRaise(
    procedure
    begin
      FWorker.Submit(nil, nil);
    end, EThreadingException);
end;

procedure TTestThreadingWorkerThread.DovrebbeNonEssereInattivoMentreIlLavoroGira;
var
  LJob: TBlockingJob;
begin
  InitBlockingJob(LJob);
  try
    FWorker.Submit(BlockJob, @LJob);
    Assert.IsTrue(LJob.Started.WaitFor(TEST_TIMEOUT) = wrSignaled, 'the job did not start');
    Assert.IsFalse(FWorker.IsIdle);
    LJob.Release.SetEvent;
    FWorker.Wait;
    Assert.IsTrue(FWorker.IsIdle);
    Assert.AreEqual(1, LJob.Finished);
    Assert.AreEqual(7, FWorker.LastResult);
  finally
    LJob.Release.SetEvent;
    FWorker.Shutdown;
    DoneBlockingJob(LJob);
  end;
end;

procedure TTestThreadingWorkerThread.DovrebbeRiportareLEccezioneDelLavoroAllAttesa;
var
  LClassName: string;
  LMessage: string;
begin
  FWorker.Submit(RaiseJob, nil);
  try
    FWorker.Wait;
    Assert.Fail('Wait should have raised the exception of the job');
  except
    on E: EWorkerJobException do
    begin
      LClassName := E.OriginalClassName;
      LMessage := E.OriginalMessage;
    end;
  end;
  Assert.AreEqual('EInvalidOpException', LClassName);
  Assert.AreEqual('job failed on purpose', LMessage);
end;

procedure TTestThreadingWorkerThread.DovrebbeRiportareLEccezioneUnaSolaVolta;
begin
  FWorker.Submit(RaiseJob, nil);
  Assert.WillRaise(
    procedure
    begin
      FWorker.Wait;
    end, EWorkerJobException);
  // the failure was taken by the first wait
  FWorker.Wait;
  Assert.IsTrue(FWorker.IsIdle);
end;

procedure TTestThreadingWorkerThread.DovrebbeFunzionareDopoUnaEccezione;
begin
  FWorker.Submit(RaiseJob, nil);
  Assert.WillRaise(
    procedure
    begin
      FWorker.Wait;
    end, EWorkerJobException);
  FWorker.Submit(CountJob, @FCounter);
  FWorker.Wait;
  Assert.AreEqual(1, FCounter);
end;

procedure TTestThreadingWorkerThread.DovrebbeRiportareLEccezionePrecedenteAlProssimoLavoro;
begin
  FWorker.Submit(RaiseJob, nil);
  // nobody waited: the next Submit tells, and does not run its job
  Assert.WillRaise(
    procedure
    begin
      FWorker.Submit(CountJob, @FCounter);
    end, EWorkerJobException);
  FWorker.Wait;
  Assert.AreEqual(0, FCounter);
  FWorker.Submit(CountJob, @FCounter);
  FWorker.Wait;
  Assert.AreEqual(1, FCounter);
end;

procedure TTestThreadingWorkerThread.DovrebbeAspettareIlLavoroPrecedenteQuandoNeArrivaUnAltro;
var
  LJob: TBlockingJob;
  LChain: TChainJob;
  LHelper: IWorkerThread;
begin
  InitBlockingJob(LJob);
  LChain.Target := FWorker;
  LChain.Counter := @FCounter;
  LChain.Reached := TEvent.Create(nil, True, False, '');
  LHelper := FFactory.CreateWorker;
  try
    FWorker.Submit(BlockJob, @LJob);
    Assert.IsTrue(LJob.Started.WaitFor(TEST_TIMEOUT) = wrSignaled, 'the job did not start');
    // the helper gives a second job to FWorker, which is held by the first one
    LHelper.Submit(SubmitCountJob, @LChain);
    Assert.IsTrue(LChain.Reached.WaitFor(TEST_TIMEOUT) = wrSignaled, 'the helper did not start');
    Assert.AreEqual(0, FCounter);
    LJob.Release.SetEvent;
    LHelper.Wait;
    FWorker.Wait;
    Assert.AreEqual(1, FCounter);
    Assert.AreEqual(1, LJob.Finished);
  finally
    LJob.Release.SetEvent;
    LHelper.Shutdown;
    FWorker.Shutdown;
    DoneBlockingJob(LJob);
    LChain.Reached.Free;
  end;
end;

procedure TTestThreadingWorkerThread.DovrebbeChiudersiPiuVolte;
begin
  FWorker.Shutdown;
  FWorker.Shutdown;
  FWorker.Shutdown;
  Assert.IsTrue(FWorker.IsIdle);
  // waiting on a closed worker is harmless
  FWorker.Wait;
end;

procedure TTestThreadingWorkerThread.DovrebbeRifiutareLavoriDopoLaChiusura;
begin
  FWorker.Shutdown;
  Assert.WillRaise(
    procedure
    begin
      FWorker.Submit(CountJob, @FCounter);
    end, EThreadingException);
  Assert.AreEqual(0, FCounter);
end;

procedure TTestThreadingWorkerThread.DovrebbeAspettareIlLavoroInCorsoQuandoSiChiudeDaUnAltroThread;
var
  LJob: TBlockingJob;
  LChain: TChainJob;
  LHelper: IWorkerThread;
begin
  InitBlockingJob(LJob);
  LChain.Target := FWorker;
  LChain.Counter := nil;
  LChain.Reached := TEvent.Create(nil, True, False, '');
  LHelper := FFactory.CreateWorker;
  try
    FWorker.Submit(BlockJob, @LJob);
    Assert.IsTrue(LJob.Started.WaitFor(TEST_TIMEOUT) = wrSignaled, 'the job did not start');
    // the helper closes FWorker while its job is running: the close waits for the job
    LHelper.Submit(ShutdownJob, @LChain);
    Assert.IsTrue(LChain.Reached.WaitFor(TEST_TIMEOUT) = wrSignaled, 'the helper did not start');
    LJob.Release.SetEvent;
    LHelper.Wait;
    Assert.AreEqual(1, LJob.Finished);
    Assert.WillRaise(
      procedure
      begin
        FWorker.Submit(CountJob, @FCounter);
      end, EThreadingException);
  finally
    LJob.Release.SetEvent;
    LHelper.Shutdown;
    FWorker.Shutdown;
    DoneBlockingJob(LJob);
    LChain.Reached.Free;
  end;
end;

procedure TTestThreadingWorkerThread.DovrebbeLiberareIlThreadAllaDistruzione;
var
  LBefore: Integer;
  LWorkers: array[0..31] of IWorkerThread;
  LIndex: Integer;
  LDuring: Integer;
begin
  LBefore := TThreadCounter.Count;
  for LIndex := 0 to High(LWorkers) do
    LWorkers[LIndex] := FFactory.CreateWorker;
  LDuring := TThreadCounter.Count;
  Assert.IsTrue(LDuring >= LBefore + Length(LWorkers),
    Format('Threads of the process: %d before, %d with the workers', [LBefore, LDuring]));
  for LIndex := 0 to High(LWorkers) do
    LWorkers[LIndex] := nil;
  TThreadCounter.AssertNotAbove(LBefore);
end;

procedure TTestThreadingWorkerThread.DovrebbeResistereAMigliaiaDiCreazioniEDistruzioni;
var
  LBefore: Integer;
  LIndex: Integer;
  LWorker: IWorkerThread;
begin
  LBefore := TThreadCounter.Count;
  for LIndex := 1 to 2000 do
  begin
    LWorker := FFactory.CreateWorker;
    LWorker.Submit(CountJob, @FCounter);
    LWorker.Wait;
    LWorker := nil;
  end;
  Assert.AreEqual(2000, FCounter);
  TThreadCounter.AssertNotAbove(LBefore);
end;

procedure TTestThreadingWorkerThread.DovrebbeNonPerdereIlLavoroSeLoDistruggeSubito;
var
  LBefore: Integer;
  LIndex: Integer;
  LWorker: IWorkerThread;
begin
  LBefore := TThreadCounter.Count;
  for LIndex := 1 to 2000 do
  begin
    LWorker := FFactory.CreateWorker;
    // no Wait: the destruction has to let the job end before it frees the object
    LWorker.Submit(CountJob, @FCounter);
    LWorker := nil;
  end;
  Assert.AreEqual(2000, FCounter);
  TThreadCounter.AssertNotAbove(LBefore);
end;

procedure TTestThreadingWorkerThread.RunBusyShutdownCycle;
var
  LJob: TBlockingJob;
  LWorker: IWorkerThread;
  LSetter: TEventSetterThread;
begin
  InitBlockingJob(LJob);
  LWorker := FFactory.CreateWorker;
  LSetter := nil;
  try
    LWorker.Submit(BlockJob, @LJob);
    Assert.IsTrue(LJob.Started.WaitFor(TEST_TIMEOUT) = wrSignaled, 'the job did not start');
    // the release comes from another thread, before or after the close has started:
    // either way the close must wait for the job
    LSetter := TEventSetterThread.Create(LJob.Release);
    LSetter.Start;
    LWorker.Shutdown;
    Assert.AreEqual(1, LJob.Finished);
    LSetter.WaitFor;
  finally
    if Assigned(LSetter) then
    begin
      LSetter.WaitFor;
      LSetter.Free;
    end;
    LJob.Release.SetEvent;
    LWorker.Shutdown;
    DoneBlockingJob(LJob);
  end;
end;

procedure TTestThreadingWorkerThread.DovrebbeChiudersiConIlThreadOccupatoMigliaiaDiVolte;
var
  LBefore: Integer;
  LIndex: Integer;
begin
  LBefore := TThreadCounter.Count;
  for LIndex := 1 to 1000 do
    RunBusyShutdownCycle;
  TThreadCounter.AssertNotAbove(LBefore);
end;

procedure TTestThreadingWorkerThread.DovrebbeEseguireMolteMigliaiaDiLavoriBrevi;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 20000 do
  begin
    FWorker.Submit(CountJob, @FCounter);
    FWorker.Wait;
  end;
  Assert.AreEqual(20000, FCounter);
  Assert.AreEqual(20000, FWorker.LastResult);
end;

procedure TTestThreadingWorkerThread.DovrebbeEseguireMolteMigliaiaDiLavoriSenzaAttenderliUnoAUno;
var
  LIndex: Integer;
begin
  // each Submit waits for the previous job: none is lost or run twice
  for LIndex := 1 to 20000 do
    FWorker.Submit(CountJob, @FCounter);
  FWorker.Wait;
  Assert.AreEqual(20000, FCounter);
end;

procedure TTestThreadingWorkerThread.DovrebbeRiportareLEccezioneDiOgniLavoroInUnaSerie;
var
  LIndex: Integer;
  LRaised: Integer;
begin
  LRaised := 0;
  for LIndex := 1 to 500 do
  begin
    FWorker.Submit(RaiseJob, nil);
    try
      FWorker.Wait;
    except
      on EWorkerJobException do
        Inc(LRaised);
    end;
    FWorker.Submit(CountJob, @FCounter);
    FWorker.Wait;
  end;
  Assert.AreEqual(500, LRaised);
  Assert.AreEqual(500, FCounter);
end;

procedure TTestThreadingWorkerThread.DovrebbeEseguireTuttiILavoriAssegnatiDaPiuThread;
const
  SUBMITTERS = 8;
  ROUNDS = 500;
var
  LThreads: array[0..SUBMITTERS - 1] of TSubmitterThread;
  LIndex: Integer;
begin
  for LIndex := 0 to SUBMITTERS - 1 do
    LThreads[LIndex] := TSubmitterThread.Create(FWorker, @FCounter, ROUNDS);
  try
    for LIndex := 0 to SUBMITTERS - 1 do
      LThreads[LIndex].Start;
    for LIndex := 0 to SUBMITTERS - 1 do
      LThreads[LIndex].WaitFor;
    for LIndex := 0 to SUBMITTERS - 1 do
      Assert.AreEqual('', LThreads[LIndex].Error);
  finally
    for LIndex := 0 to SUBMITTERS - 1 do
      LThreads[LIndex].Free;
  end;
  FWorker.Wait;
  Assert.AreEqual(SUBMITTERS * ROUNDS, FCounter);
end;

end.
