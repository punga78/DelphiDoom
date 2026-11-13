{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the runner of jobs             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.JobRunner;

interface

uses
  System.Classes, DUnitX.TestFramework, DelphiDoom.Threading.Intf, DelphiDoom.Threading.JobRunner,
  DelphiDoom.Tests.Threading.Legacy;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingJobRunner = class(TObject)
  private
    FLog: TStringList;
    FNewLog: TStringList;
    FPool: IWorkerPool;
    FMessages: IWorkerMessages;
    FRunner: TWorkerJobRunner;
    FLegacy: TLegacyThreads;
    procedure CompareExecute(const ASeed: Integer; AJobCount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnPoolNil;
    [Test]
    procedure DovrebbeRifiutareIMessaggiNil;
    [Test]
    procedure DovrebbeEseguireIlPrimoLavoroSulChiamanteSenzaWorker;
    [Test]
    procedure DovrebbeDareLeAltreFunzioniAiWorkerInOrdine;
    [Test]
    procedure DovrebbeSaltareLeFunzioniNilSenzaBucareIWorker;
    [Test]
    procedure DovrebbeAvvisareSeIlPrimoLavoroENilEAspettareComunqueIWorker;
    [Test]
    procedure DovrebbeAvvisareSeNonCiSonoLavori;
    [Test]
    procedure DovrebbeSegnalareUnaChiamataRicorsivaDiExecute;
    [Test]
    procedure DovrebbeTogliereLOccupatoSeUnLavoroSollevaUnEccezione;
    [Test]
    procedure DovrebbeSegnalareUnIterateDentroUnExecute;
    [Test]
    procedure DovrebbeDareAOgniThreadDellIterazioneIlSuoIndice;
    [Test]
    procedure DovrebbeUsareIlNumeroDiCpuSeIThreadSonoZero;
    [Test]
    procedure DovrebbeLimitareIThreadDellIterazioneDaDueASessantacinque;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioExecuteConDueLavori;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioExecuteConQuattroLavoriENil;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioExecute4;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioExecute6SenzaLeAttesePerThreadFermi;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioIterate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.Types, DelphiDoom.Tests.Threading.Recording;

var
  GRunner: TWorkerJobRunner;

function ReenterExecuteJob(AParameter: Pointer): Integer; stdcall;
begin
  GRunner.Execute([TWorkerJob.Make(RecordJob, nil)]);
  Result := 0;
end;

function ReenterIterateJob(AParameter: Pointer): Integer; stdcall;
begin
  GRunner.Iterate(IterationJob, nil, 2);
  Result := 0;
end;

function RaisingJob(AParameter: Pointer): Integer; stdcall;
begin
  raise EThreadingException.Create('boom');
end;

procedure TTestThreadingJobRunner.Setup;
begin
  FLog := TStringList.Create;
  FNewLog := TStringList.Create;
  GJobLog := FLog;
  FPool := CreateSyncPool(FLog, LEGACY_NUMEXECTHREADS);
  FMessages := TRecordingMessages.Create(FLog);
  FRunner := TWorkerJobRunner.Create(FPool, FMessages, 4);
  GRunner := FRunner;
end;

procedure TTestThreadingJobRunner.TearDown;
begin
  GRunner := nil;
  GJobLog := nil;
  FLegacy.Free;
  FLegacy := nil;
  FRunner.Free;
  FMessages := nil;
  FPool := nil;
  FNewLog.Free;
  FLog.Free;
end;

procedure TTestThreadingJobRunner.DovrebbeRifiutareUnPoolNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWorkerJobRunner.Create(nil, FMessages, 4).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThreadingJobRunner.DovrebbeRifiutareIMessaggiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWorkerJobRunner.Create(FPool, nil, 4).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThreadingJobRunner.DovrebbeEseguireIlPrimoLavoroSulChiamanteSenzaWorker;
begin
  FRunner.Execute([TWorkerJob.Make(RecordJob, Pointer(1))]);
  Assert.AreEqual('J1', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeDareLeAltreFunzioniAiWorkerInOrdine;
begin
  FRunner.Execute([
    TWorkerJob.Make(RecordJob, Pointer(1)),
    TWorkerJob.Make(RecordJob, Pointer(2)),
    TWorkerJob.Make(RecordJob, Pointer(3))]);
  // the workers start first, then the caller runs its own job, then the waits
  Assert.AreEqual('S0|J2|S1|J3|J1|W0|W1', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeSaltareLeFunzioniNilSenzaBucareIWorker;
begin
  FRunner.Execute([
    TWorkerJob.Make(RecordJob, Pointer(1)),
    TWorkerJob.Make(nil, nil),
    TWorkerJob.Make(RecordJob, Pointer(3)),
    TWorkerJob.Make(nil, nil),
    TWorkerJob.Make(RecordJob, Pointer(5))]);
  Assert.AreEqual('S0|J3|S1|J5|J1|W0|W1', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeAvvisareSeIlPrimoLavoroENilEAspettareComunqueIWorker;
begin
  FRunner.Execute([
    TWorkerJob.Make(nil, nil),
    TWorkerJob.Make(RecordJob, Pointer(2))]);
  Assert.AreEqual('S0|J2|W:MT_Execute(): Called with null application thread function.|W0', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeAvvisareSeNonCiSonoLavori;
begin
  FRunner.Execute([]);
  Assert.AreEqual('W:MT_Execute(): Called with null application thread function.', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeSegnalareUnaChiamataRicorsivaDiExecute;
begin
  Assert.WillRaise(
    procedure
    begin
      FRunner.Execute([TWorkerJob.Make(ReenterExecuteJob, nil)]);
    end,
    EThreadingException);
  Assert.AreEqual('E:MT_Execute(): Invalid recoursive call.', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeTogliereLOccupatoSeUnLavoroSollevaUnEccezione;
begin
  // the old code left the flag set, so every later call said "recursive call"
  Assert.WillRaise(
    procedure
    begin
      FRunner.Execute([TWorkerJob.Make(RaisingJob, nil)]);
    end,
    EThreadingException);
  Assert.IsFalse(FRunner.Busy);
  FLog.Clear;
  FRunner.Execute([TWorkerJob.Make(RecordJob, Pointer(9))]);
  Assert.AreEqual('J9', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeSegnalareUnIterateDentroUnExecute;
begin
  Assert.WillRaise(
    procedure
    begin
      FRunner.Execute([TWorkerJob.Make(ReenterIterateJob, nil)]);
    end,
    EThreadingException);
  Assert.AreEqual('E:MT_Iterate(): Invalid recoursive call.', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeDareAOgniThreadDellIterazioneIlSuoIndice;
begin
  FRunner.Iterate(IterationJob, Pointer(77), 3);
  Assert.AreEqual('S0|I0/3/77|S1|I1/3/77|I2/3/77|W0|W1', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeUsareIlNumeroDiCpuSeIThreadSonoZero;
begin
  FRunner.Iterate(IterationJob, nil, 0);
  Assert.AreEqual('S0|I0/4/0|S1|I1/4/0|S2|I2/4/0|I3/4/0|W0|W1|W2', JoinLog(FLog));
end;

procedure TTestThreadingJobRunner.DovrebbeLimitareIThreadDellIterazioneDaDueASessantacinque;
begin
  FRunner.Iterate(IterationJob, nil, 1);
  Assert.AreEqual('S0|I0/2/0|I1/2/0|W0', JoinLog(FLog));
  FLog.Clear;
  FRunner.Iterate(IterationJob, nil, 500);
  Assert.IsTrue(FLog.IndexOf('I64/65/0') >= 0);
  Assert.IsTrue(FLog.IndexOf('I65/65/0') < 0);
  Assert.AreEqual('W63', FLog[FLog.Count - 1]);
end;

procedure TTestThreadingJobRunner.CompareExecute(const ASeed: Integer; AJobCount: Integer);
var
  LJobs: array[1..4] of TWorkerProc;
  LIndex: Integer;
  LMask: Integer;
  LNewLog: string;
begin
  RandSeed := ASeed;
  for LMask := 0 to 7 do
  begin
    for LIndex := 1 to 4 do
      if (LIndex = 1) or ((LMask shr (LIndex - 2)) and 1 = 1) then
        LJobs[LIndex] := RecordJob
      else
        LJobs[LIndex] := nil;
    FLog.Clear;
    case AJobCount of
      2:
        FRunner.Execute([
          TWorkerJob.Make(LJobs[1], Pointer(1)), TWorkerJob.Make(LJobs[2], Pointer(2))]);
      4:
        FRunner.Execute([
          TWorkerJob.Make(LJobs[1], Pointer(1)), TWorkerJob.Make(LJobs[2], Pointer(2)),
          TWorkerJob.Make(LJobs[3], Pointer(3)), TWorkerJob.Make(LJobs[4], Pointer(4))]);
    end;
    LNewLog := JoinLog(FLog);

    FLog.Clear;
    FLegacy := TLegacyThreads.Create(FPool, FPool, FPool, TRecordingMemoryOps.Create(FLog, 0),
      FMessages, 4, True);
    try
      case AJobCount of
        2:
          FLegacy.MT_Execute2(LJobs[1], Pointer(1), LJobs[2], Pointer(2));
        4:
          FLegacy.MT_Execute4(LJobs[1], Pointer(1), LJobs[2], Pointer(2), LJobs[3], Pointer(3),
            LJobs[4], Pointer(4));
      end;
    finally
      FreeAndNil(FLegacy);
    end;
    Assert.AreEqual(JoinLog(FLog), LNewLog, 'mask ' + IntToStr(LMask));
  end;
end;

procedure TTestThreadingJobRunner.DovrebbeDareLoStessoRisultatoDelVecchioExecuteConDueLavori;
begin
  CompareExecute(1, 2);
end;

procedure TTestThreadingJobRunner.DovrebbeDareLoStessoRisultatoDelVecchioExecuteConQuattroLavoriENil;
begin
  CompareExecute(2, 4);
end;

procedure TTestThreadingJobRunner.DovrebbeDareLoStessoRisultatoDelVecchioExecute4;
var
  LNew: string;
begin
  FRunner.Execute([
    TWorkerJob.Make(RecordJob, Pointer(1)), TWorkerJob.Make(RecordJob, Pointer(2)),
    TWorkerJob.Make(RecordJob, Pointer(3)), TWorkerJob.Make(RecordJob, Pointer(4))]);
  LNew := JoinLog(FLog);
  FLog.Clear;
  FLegacy := TLegacyThreads.Create(FPool, FPool, FPool, TRecordingMemoryOps.Create(FLog, 0),
    FMessages, 4, True);
  FLegacy.MT_Execute4Fixed(RecordJob, Pointer(1), RecordJob, Pointer(2), RecordJob, Pointer(3),
    RecordJob, Pointer(4));
  Assert.AreEqual(JoinLog(FLog), LNew);
end;

procedure TTestThreadingJobRunner.DovrebbeDareLoStessoRisultatoDelVecchioExecute6SenzaLeAttesePerThreadFermi;
var
  LNew: string;
begin
  FRunner.Execute([
    TWorkerJob.Make(RecordJob, Pointer(1)), TWorkerJob.Make(RecordJob, Pointer(2)),
    TWorkerJob.Make(RecordJob, Pointer(3)), TWorkerJob.Make(RecordJob, Pointer(4)),
    TWorkerJob.Make(RecordJob, Pointer(5)), TWorkerJob.Make(RecordJob, Pointer(6))]);
  LNew := JoinLog(FLog);
  FLog.Clear;
  FLegacy := TLegacyThreads.Create(FPool, FPool, FPool, TRecordingMemoryOps.Create(FLog, 0),
    FMessages, 4, True);
  FLegacy.MT_Execute6Fixed(RecordJob, Pointer(1), RecordJob, Pointer(2), RecordJob, Pointer(3),
    RecordJob, Pointer(4), RecordJob, Pointer(5), RecordJob, Pointer(6));
  // the old code also waited for the workers 5..14, which never had a job
  Assert.AreEqual(JoinLogWithoutIdleWaits(FLog, 5), LNew);
end;

procedure TTestThreadingJobRunner.DovrebbeDareLoStessoRisultatoDelVecchioIterate;
var
  LCounts: TArray<Integer>;
  LCount: Integer;
  LNew: string;
begin
  LCounts := [0, 1, 2, 3, 7, 64, 65, 66, 200, -5];
  for LCount in LCounts do
  begin
    FLog.Clear;
    FRunner.Iterate(IterationJob, Pointer(5), LCount);
    LNew := JoinLog(FLog);
    FLog.Clear;
    FLegacy := TLegacyThreads.Create(FPool, FPool, FPool, TRecordingMemoryOps.Create(FLog, 0),
      FMessages, 4, True);
    try
      FLegacy.MT_Iterate(IterationJob, Pointer(5), LCount);
    finally
      FreeAndNil(FLegacy);
    end;
    Assert.AreEqual(JoinLog(FLog), LNew, 'threads ' + IntToStr(LCount));
  end;
end;

end.
