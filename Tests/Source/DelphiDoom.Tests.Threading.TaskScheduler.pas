{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the scheduler of tasks         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.TaskScheduler;

interface

uses
  System.Classes, DUnitX.TestFramework, DelphiDoom.Threading.TaskScheduler;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingTaskScheduler = class(TObject)
  private
    FLog: TStringList;
    FScheduler: TWorkerTaskScheduler;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnPoolNil;
    [Test]
    procedure DovrebbeAvereUnoSlotPerWorker;
    [Test]
    procedure DovrebbeDareGliSlotInOrdine;
    [Test]
    procedure DovrebbeLiberareLoSlotQuandoIlTaskFinisce;
    [Test]
    procedure DovrebbeEseguireSubitoSulChiamanteSeNonCiSonoSlotLiberi;
    [Test]
    procedure DovrebbeIgnorareSlotLiberiOFuoriIntervallo;
    [Test]
    procedure DovrebbeAspettareSoloGliSlotOccupati;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioCodiceSuScenariCasuali;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.Intf, DelphiDoom.Threading.Types,
  DelphiDoom.Tests.Threading.Legacy, DelphiDoom.Tests.Threading.Recording;

procedure TTestThreadingTaskScheduler.Setup;
begin
  FLog := TStringList.Create;
  GJobLog := FLog;
  FScheduler := TWorkerTaskScheduler.Create(CreateSyncPool(FLog, LEGACY_NUMTASKTHREADS));
end;

procedure TTestThreadingTaskScheduler.TearDown;
begin
  FScheduler.Free;
  GJobLog := nil;
  FLog.Free;
end;

procedure TTestThreadingTaskScheduler.DovrebbeRifiutareUnPoolNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWorkerTaskScheduler.Create(nil).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThreadingTaskScheduler.DovrebbeAvereUnoSlotPerWorker;
begin
  Assert.AreEqual(8, FScheduler.SlotCount);
end;

procedure TTestThreadingTaskScheduler.DovrebbeDareGliSlotInOrdine;
begin
  Assert.AreEqual(0, FScheduler.Schedule(RecordTask));
  Assert.AreEqual(1, FScheduler.Schedule(RecordTask));
  Assert.AreEqual(2, FScheduler.Schedule(RecordTask));
  // scheduling does not start anything
  Assert.AreEqual('', JoinLog(FLog));
end;

procedure TTestThreadingTaskScheduler.DovrebbeLiberareLoSlotQuandoIlTaskFinisce;
begin
  Assert.AreEqual(0, FScheduler.Schedule(RecordTask));
  Assert.AreEqual(1, FScheduler.Schedule(RecordTask));
  FScheduler.ExecutePending(0);
  Assert.AreEqual('S0|T', JoinLog(FLog));
  Assert.AreEqual(0, FScheduler.Schedule(RecordTask));
end;

procedure TTestThreadingTaskScheduler.DovrebbeEseguireSubitoSulChiamanteSeNonCiSonoSlotLiberi;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    Assert.AreEqual(LIndex, FScheduler.Schedule(RecordTask));
  Assert.AreEqual(-1, FScheduler.Schedule(RecordTask));
  Assert.AreEqual('T', JoinLog(FLog));
end;

procedure TTestThreadingTaskScheduler.DovrebbeIgnorareSlotLiberiOFuoriIntervallo;
begin
  // the old code read tasks[id] with any id: out of range it was a memory error
  FScheduler.ExecutePending(3);
  FScheduler.ExecutePending(-1);
  FScheduler.ExecutePending(8);
  FScheduler.ExecutePending(1000);
  FScheduler.Wait(-1);
  FScheduler.Wait(8);
  FScheduler.Wait(2);
  Assert.AreEqual('', JoinLog(FLog));
end;

procedure TTestThreadingTaskScheduler.DovrebbeAspettareSoloGliSlotOccupati;
begin
  FScheduler.Schedule(RecordTask);
  FScheduler.Schedule(RecordTask);
  FScheduler.Schedule(RecordTask);
  FScheduler.Wait(1);
  FScheduler.WaitAll;
  Assert.AreEqual('W1|W0|W1|W2', JoinLog(FLog));
end;

procedure TTestThreadingTaskScheduler.DovrebbeDareLoStessoRisultatoDelVecchioCodiceSuScenariCasuali;
var
  LScenario: Integer;
  LStep: Integer;
  LNewLog: string;
  LOldLog: string;
  LNewScheduler: TWorkerTaskScheduler;
  LLegacy: TLegacyThreads;
  LPool: IWorkerPool;
  LOperations: TArray<Integer>;
  LOperation: Integer;
  LNewAnswers: string;
  LOldAnswers: string;
begin
  RandSeed := 1185;
  for LScenario := 1 to 200 do
  begin
    SetLength(LOperations, 60);
    for LStep := 0 to High(LOperations) do
      LOperations[LStep] := Random(40);

    FLog.Clear;
    LNewAnswers := '';
    LNewScheduler := TWorkerTaskScheduler.Create(CreateSyncPool(FLog, LEGACY_NUMTASKTHREADS));
    try
      for LOperation in LOperations do
        case LOperation mod 4 of
          0: LNewAnswers := LNewAnswers + IntToStr(LNewScheduler.Schedule(RecordTask)) + ',';
          1: LNewScheduler.ExecutePending(LOperation div 5);
          2: LNewScheduler.Wait(LOperation div 5 - 1);
          3: if LOperation > 30 then LNewScheduler.WaitAll;
        end;
    finally
      LNewScheduler.Free;
    end;
    LNewLog := JoinLog(FLog);

    FLog.Clear;
    LOldAnswers := '';
    LPool := CreateSyncPool(FLog, LEGACY_NUMTASKTHREADS);
    LLegacy := TLegacyThreads.Create(LPool, LPool, LPool, TRecordingMemoryOps.Create(FLog, 0),
      TRecordingMessages.Create(FLog), 4, True);
    try
      for LOperation in LOperations do
        case LOperation mod 4 of
          0: LOldAnswers := LOldAnswers + IntToStr(LLegacy.MT_ScheduleTask(RecordTask)) + ',';
          1: if LOperation div 5 < LEGACY_NUMTASKTHREADS then LLegacy.MT_ExecutePendingTask(LOperation div 5);
          2: LLegacy.MT_WaitTask(LOperation div 5 - 1);
          3: if LOperation > 30 then LLegacy.MT_WaitTasks;
        end;
    finally
      LLegacy.Free;
    end;
    LOldLog := JoinLog(FLog);
    Assert.AreEqual(LOldAnswers, LNewAnswers, 'answers of scenario ' + IntToStr(LScenario));
    Assert.AreEqual(LOldLog, LNewLog, 'events of scenario ' + IntToStr(LScenario));
  end;
end;

end.
