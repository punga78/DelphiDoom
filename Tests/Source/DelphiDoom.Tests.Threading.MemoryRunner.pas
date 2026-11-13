{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - memory on several threads      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.MemoryRunner;

interface

uses
  System.Classes, DUnitX.TestFramework, DelphiDoom.Threading.Intf, DelphiDoom.Threading.MemoryRunner;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingMemoryRunner = class(TObject)
  private
    FLog: TStringList;
    FOpsLog: TStringList;
    FOps: IWorkerMemoryOps;
    function NewRunner(AWorkers: Integer): TWorkerMemoryRunner;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnPoolNil;
    [Test]
    procedure DovrebbeRifiutareLePrimitiveNil;
    [Test]
    procedure DovrebbeUsareAlPiuSedicithread;
    [Test]
    procedure DovrebbeFareUnBloccoPiccoloSulChiamante;
    [Test]
    procedure DovrebbeFareTuttoSulChiamanteConUnSoloWorker;
    [Test]
    procedure DovrebbeTagliareUnBloccoGrandeInPartiUguali;
    [Test]
    procedure DovrebbeSpostareDiQuattroByteAPassoNelRiempimentoDiInteri;
    [Test]
    procedure DovrebbeLimitareIThreadRichiestiAiWorkerDelPool;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioCodiceSuScenariCasuali;
    [Test]
    procedure DovrebbeRiempireDavveroUnBloccoConThreadVeri;
    [Test]
    procedure DovrebbeCopiareDavveroUnBloccoConThreadVeri;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.Types, DelphiDoom.Threading.Factory,
  DelphiDoom.Tests.Threading.Legacy, DelphiDoom.Tests.Threading.Recording;

type
  /// <summary>Real primitives on real memory, for the tests with real threads</summary>
  TBufferOps = class(TInterfacedObject, IWorkerMemoryOps)
  public
    procedure Zero(ADest: Pointer; ACount: Integer);
    procedure Fill(ADest: Pointer; AValue, ACount: Integer);
    procedure FillInteger(ADest: Pointer; AValue, ACount: Integer);
    procedure Copy(ADest, ASource: Pointer; ACount: Integer);
  end;

procedure TBufferOps.Zero(ADest: Pointer; ACount: Integer);
begin
  FillChar(ADest^, ACount, 0);
end;

procedure TBufferOps.Fill(ADest: Pointer; AValue, ACount: Integer);
begin
  FillChar(ADest^, ACount, AValue);
end;

procedure TBufferOps.FillInteger(ADest: Pointer; AValue, ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
    PInteger(PByte(ADest) + LIndex * SizeOf(Integer))^ := AValue;
end;

procedure TBufferOps.Copy(ADest, ASource: Pointer; ACount: Integer);
begin
  Move(ASource^, ADest^, ACount);
end;

const
  BASE = $100000;

procedure TTestThreadingMemoryRunner.Setup;
begin
  FLog := TStringList.Create;
  FOpsLog := TStringList.Create;
  FOps := TRecordingMemoryOps.Create(FOpsLog, BASE);
end;

procedure TTestThreadingMemoryRunner.TearDown;
begin
  FOps := nil;
  FOpsLog.Free;
  FLog.Free;
end;

function TTestThreadingMemoryRunner.NewRunner(AWorkers: Integer): TWorkerMemoryRunner;
begin
  Result := TWorkerMemoryRunner.Create(CreateSyncPool(FLog, AWorkers), FOps);
end;

procedure TTestThreadingMemoryRunner.DovrebbeRifiutareUnPoolNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWorkerMemoryRunner.Create(nil, FOps).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThreadingMemoryRunner.DovrebbeRifiutareLePrimitiveNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWorkerMemoryRunner.Create(CreateSyncPool(FLog, 2), nil).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThreadingMemoryRunner.DovrebbeUsareAlPiuSedicithread;
var
  LRunner: TWorkerMemoryRunner;
begin
  LRunner := NewRunner(64);
  try
    Assert.AreEqual(16, LRunner.ThreadCount);
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeFareUnBloccoPiccoloSulChiamante;
var
  LRunner: TWorkerMemoryRunner;
begin
  LRunner := NewRunner(8);
  try
    LRunner.Fill(Pointer(BASE), 5, 1023);
    Assert.AreEqual('', JoinLog(FLog));
    Assert.AreEqual('F 0 5 1023', JoinLog(FOpsLog));
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeFareTuttoSulChiamanteConUnSoloWorker;
var
  LRunner: TWorkerMemoryRunner;
begin
  LRunner := NewRunner(1);
  try
    LRunner.ZeroMemory(Pointer(BASE), 100000);
    Assert.AreEqual('Z 0 100000', JoinLog(FOpsLog));
    Assert.AreEqual('', JoinLog(FLog));
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeTagliareUnBloccoGrandeInPartiUguali;
var
  LRunner: TWorkerMemoryRunner;
begin
  LRunner := NewRunner(8);
  try
    // 4100 bytes: 4 threads, 1025 and 8 off: (4100 div 4) and not 7 = 1024; the last takes the rest
    LRunner.Copy(Pointer(BASE), Pointer(BASE + 50000), 4100);
    Assert.AreEqual('C 0 50000 1024|C 1024 51024 1024|C 2048 52048 1024|C 3072 53072 1028', JoinLog(FOpsLog));
    Assert.AreEqual('S0|S1|S2|W0|W1|W2', JoinLog(FLog));
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeSpostareDiQuattroByteAPassoNelRiempimentoDiInteri;
var
  LRunner: TWorkerMemoryRunner;
begin
  LRunner := NewRunner(8);
  try
    LRunner.FillInteger(Pointer(BASE), 9, 2048, 2);
    Assert.AreEqual('I 0 9 1024|I 4096 9 1024', JoinLog(FOpsLog));
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeLimitareIThreadRichiestiAiWorkerDelPool;
var
  LRunner: TWorkerMemoryRunner;
begin
  LRunner := NewRunner(3);
  try
    LRunner.Fill(Pointer(BASE), 1, 8000, 10);
    Assert.AreEqual('F 0 1 2664|F 2664 1 2664|F 5328 1 2672', JoinLog(FOpsLog));
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeDareLoStessoRisultatoDelVecchioCodiceSuScenariCasuali;
var
  LScenario: Integer;
  LWorkers: Integer;
  LCount: Integer;
  LUse: Integer;
  LKind: Integer;
  LRunner: TWorkerMemoryRunner;
  LLegacy: TLegacyThreads;
  LNew: string;
  LOld: string;
  LPool: IWorkerPool;
  LLegacyOps: IWorkerMemoryOps;
begin
  RandSeed := 185;
  for LScenario := 1 to 600 do
  begin
    LWorkers := 1 + Random(16);
    case Random(4) of
      0: LCount := Random(1024);
      1: LCount := 1024 + Random(4096);
      else LCount := Random(300000);
    end;
    LUse := Random(20);
    LKind := Random(4);

    FLog.Clear;
    FOpsLog.Clear;
    LRunner := NewRunner(LWorkers);
    try
      case LKind of
        0: LRunner.ZeroMemory(Pointer(BASE), LCount, LUse);
        1: LRunner.Fill(Pointer(BASE), LScenario, LCount, LUse);
        2: LRunner.FillInteger(Pointer(BASE), LScenario, LCount, LUse);
        3: LRunner.Copy(Pointer(BASE), Pointer(BASE + 7), LCount, LUse);
      end;
    finally
      LRunner.Free;
    end;
    LNew := JoinLog(FLog) + '#' + JoinLog(FOpsLog);

    FLog.Clear;
    FOpsLog.Clear;
    LPool := CreateSyncPool(FLog, LWorkers);
    LLegacyOps := TRecordingMemoryOps.Create(FOpsLog, BASE);
    LLegacy := TLegacyThreads.Create(LPool, LPool, LPool, LLegacyOps, TRecordingMessages.Create(FLog), 4, True);
    try
      case LKind of
        0: LLegacy.MT_ZeroMemory(Pointer(BASE), LCount, LUse);
        1: LLegacy.MT_memset(Pointer(BASE), LScenario, LCount, LUse);
        2: LLegacy.MT_memseti(Pointer(BASE), LScenario, LCount, LUse);
        3: LLegacy.MT_memcpy(Pointer(BASE), Pointer(BASE + 7), LCount, LUse);
      end;
    finally
      LLegacy.Free;
    end;
    LOld := JoinLog(FLog) + '#' + JoinLog(FOpsLog);
    Assert.AreEqual(LOld, LNew,
      Format('scenario %d: workers %d, count %d, use %d, kind %d', [LScenario, LWorkers, LCount, LUse, LKind]));
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeRiempireDavveroUnBloccoConThreadVeri;
var
  LRunner: TWorkerMemoryRunner;
  LBuffer: TBytes;
  LIntegers: TArray<Integer>;
  LIndex: Integer;
begin
  LRunner := TThreadingFactory.CreateMemoryRunner(TThreadingFactory.CreatePool(6), TBufferOps.Create);
  try
    SetLength(LBuffer, 1000003);
    LRunner.Fill(@LBuffer[0], 77, Length(LBuffer));
    for LIndex := 0 to High(LBuffer) do
      if LBuffer[LIndex] <> 77 then
        Assert.Fail('byte ' + IntToStr(LIndex));
    LRunner.ZeroMemory(@LBuffer[0], Length(LBuffer));
    for LIndex := 0 to High(LBuffer) do
      if LBuffer[LIndex] <> 0 then
        Assert.Fail('zero byte ' + IntToStr(LIndex));
    SetLength(LIntegers, 250001);
    LRunner.FillInteger(@LIntegers[0], $01020304, Length(LIntegers));
    for LIndex := 0 to High(LIntegers) do
      if LIntegers[LIndex] <> $01020304 then
        Assert.Fail('integer ' + IntToStr(LIndex));
  finally
    LRunner.Free;
  end;
end;

procedure TTestThreadingMemoryRunner.DovrebbeCopiareDavveroUnBloccoConThreadVeri;
var
  LRunner: TWorkerMemoryRunner;
  LSource: TBytes;
  LDest: TBytes;
  LIndex: Integer;
begin
  LRunner := TThreadingFactory.CreateMemoryRunner(TThreadingFactory.CreatePool(4), TBufferOps.Create);
  try
    SetLength(LSource, 777777);
    SetLength(LDest, 777777);
    for LIndex := 0 to High(LSource) do
      LSource[LIndex] := Byte(LIndex * 31 + 7);
    LRunner.Copy(@LDest[0], @LSource[0], Length(LSource));
    Assert.IsTrue(CompareMem(@LDest[0], @LSource[0], Length(LSource)));
  finally
    LRunner.Free;
  end;
end;

end.
