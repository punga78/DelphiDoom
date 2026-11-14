{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptThread       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Thread;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.Thread, DelphiDoom.Tests.DoomScript.Rig;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptThread = class
  strict private
    FRig: TDoomScriptTestRig;
    function NewThread(const AFunction: AnsiString): TDoomScriptThread;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareUnNumeroEUnNomeAOgniThread;
    [Test]
    procedure DovrebbeSaltareIlNumeroZeroEINumeriInUso;
    [Test]
    procedure DovrebbeAspettareUnTempo;
    [Test]
    procedure DovrebbeAspettareUnFotogramma;
    [Test]
    procedure DovrebbePartireUnMillisecondoDopoAlTempoZero;
    [Test]
    procedure DovrebbeNonEseguireUnThreadManualeCheAspetta;
    [Test]
    procedure DovrebbeRiprendereQuandoIlThreadAttesoFinisce;
    [Test]
    procedure DovrebbeRiprendereQuandoLEntitaAttesaHaFinito;
    [Test]
    procedure DovrebbeUccidereIThreadPerNomeConIlCarattereJolly;
    [Test]
    procedure DovrebbeLasciareNellaListaUnThreadUccisoInPausa;
    [Test]
    procedure DovrebbeRimuovereIlThreadFinitoAlServizioSuccessivo;
    [Test]
    procedure DovrebbeTenereIlThreadFinitoSeLaRimozioneEManuale;
    [Test]
    procedure DovrebbeElencareIThread;
    [Test]
    procedure DovrebbeMostrareLoStatoDiUnThread;
    [Test]
    procedure DovrebbeLasciareCorrenteIlThreadFallitoComeLOriginale;
    [Test]
    procedure DovrebbeRipartireDaZeroConRestart;
    [Test]
    procedure DovrebbeTracciareCreazioneEFineConIlDebugDegliScript;
    [Test]
    procedure DovrebbeSalvareERipristinareUnThreadCheAspetta;
  end;

implementation

uses
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.SaveStream,
  DelphiDoom.Tests.DoomScript.Support;

procedure TTestDoomScriptThread.Setup;
begin
  FRig := TDoomScriptTestRig.Create;
  FRig.Compile(
    'float counter;'#10 +
    'void quick() { counter = counter + 1; }'#10 +
    'void sleeper() { sys.wait( 0.1 ); counter = counter + 10; }'#10 +
    'void framer() { sys.waitFrame(); counter = counter + 100; }'#10 +
    'void pauser() { sys.pause(); counter = counter + 1000; }'#10 +
    'void failing() { sys.error( "stop here" ); }'#10);
end;

procedure TTestDoomScriptThread.TearDown;
begin
  FRig.Free;
end;

function TTestDoomScriptThread.NewThread(const AFunction: AnsiString): TDoomScriptThread;
begin
  Result := FRig.Machine.CreateThread(FRig.FindFunction(AFunction));
end;

procedure TTestDoomScriptThread.DovrebbeDareUnNumeroEUnNomeAOgniThread;
var
  LFirst: TDoomScriptThread;
  LSecond: TDoomScriptThread;
begin
  LFirst := FRig.Machine.CreateThread;
  LSecond := NewThread('quick');
  Assert.AreEqual(1, LFirst.ThreadNum);
  Assert.AreEqual('thread_1', string(LFirst.GetThreadName));
  Assert.AreEqual(2, LSecond.ThreadNum);
  Assert.AreEqual('quick', string(LSecond.GetThreadName));
  Assert.AreSame(LSecond, FRig.Machine.GetThread(2));
  Assert.IsNull(FRig.Machine.GetThread(3));
  Assert.IsNull(FRig.Machine.GetThread(0));
  Assert.AreEqual(2, FRig.Machine.NumThreads);
  Assert.AreSame(LFirst, FRig.Machine.ThreadAt(0));
  LSecond.SetThreadName('renamed');
  Assert.AreEqual('renamed', string(LSecond.GetThreadName));
  Assert.AreSame(FRig.Machine.Context, LFirst.Context);
  Assert.AreEqual(0, LFirst.SpawnArgs.GetNumKeyVals);
  Assert.AreEqual(0, LFirst.CreationTime);
  Assert.IsNull(TDoomScriptThread.CurrentThread(FRig.Machine.Context));
  Assert.AreEqual(0, TDoomScriptThread.CurrentThreadNum(FRig.Machine.Context));
end;

procedure TTestDoomScriptThread.DovrebbeSaltareIlNumeroZeroEINumeriInUso;
var
  LFirst: TDoomScriptThread;
  LNext: TDoomScriptThread;
begin
  LFirst := FRig.Machine.CreateThread;
  Assert.AreEqual(1, LFirst.ThreadNum);
  // the counter wraps: 0 is "no thread" and 1 is in use
  FRig.Machine.Context.ThreadIndex := -1;
  LNext := FRig.Machine.CreateThread;
  Assert.AreEqual(2, LNext.ThreadNum);
end;

procedure TTestDoomScriptThread.DovrebbeAspettareUnTempo;
var
  LThread: TDoomScriptThread;
begin
  LThread := NewThread('sleeper');
  LThread.ManualDelete;
  Assert.IsFalse(LThread.Start);
  Assert.AreEqual(100, LThread.WaitingUntil);
  Assert.IsTrue(LThread.IsWaiting);
  Assert.IsTrue(LThread.IsDoneProcessing);
  Assert.IsFalse(LThread.IsDying);
  Assert.AreEqual(1, FRig.Machine.Queue.Count, 'the event that wakes the thread');
  FRig.Frame(99);
  Assert.IsTrue(LThread.IsWaiting);
  FRig.Frame(1);
  Assert.IsTrue(LThread.IsDying);
  Assert.AreEqual(100, LThread.LastExecuteTime);
  Assert.IsFalse(LThread.IsWaiting);
  // WaitSec and WaitMS from the host
  LThread := NewThread('quick');
  LThread.WaitSec(0.25);
  Assert.AreEqual(350, LThread.WaitingUntil);
  LThread.WaitMS(7);
  Assert.AreEqual(107, LThread.WaitingUntil);
  LThread.ClearWaitFor;
  Assert.AreEqual(0, LThread.WaitingUntil);
  Assert.AreEqual(DS_ENTITYNUM_NONE, LThread.WaitingFor);
end;

procedure TTestDoomScriptThread.DovrebbeAspettareUnFotogramma;
var
  LThread: TDoomScriptThread;
begin
  LThread := NewThread('framer');
  Assert.IsFalse(LThread.Start);
  Assert.AreEqual(16, LThread.WaitingUntil);
  // a thread under manual control does not set the time: it can run again in the same frame
  LThread := NewThread('framer');
  LThread.ManualControl;
  Assert.IsTrue(LThread.IsManualControl);
  Assert.IsFalse(LThread.Execute);
  Assert.AreEqual(0, LThread.WaitingUntil);
  Assert.IsTrue(LThread.Execute);
end;

procedure TTestDoomScriptThread.DovrebbePartireUnMillisecondoDopoAlTempoZero;
var
  LThread: TDoomScriptThread;
begin
  LThread := NewThread('quick');
  LThread.DelayedStart(0);
  Assert.AreEqual(1, FRig.Machine.Queue.GetEvent(0).Time);
  // a second request replaces the first
  LThread.DelayedStart(5);
  Assert.AreEqual(1, FRig.Machine.Queue.Count);
  Assert.AreEqual(6, FRig.Machine.Queue.GetEvent(0).Time);
  FRig.Host.Time := 50;
  LThread.DelayedStart(0);
  Assert.AreEqual(50, FRig.Machine.Queue.GetEvent(0).Time);
  // Start runs now and cancels the request
  Assert.IsTrue(LThread.Start);
  Assert.AreEqual(1, FRig.Machine.Queue.Count, 'only the removal of the finished thread');
  Assert.AreSame(FRig.Machine.Context.EvRemove, FRig.Machine.Queue.GetEvent(0).EventDef);
end;

procedure TTestDoomScriptThread.DovrebbeNonEseguireUnThreadManualeCheAspetta;
var
  LThread: TDoomScriptThread;
begin
  LThread := NewThread('quick');
  LThread.ManualControl;
  LThread.WaitMS(10);
  Assert.IsFalse(LThread.Execute);
  Assert.AreEqual(10, LThread.WaitingUntil, 'the wait is still there');
  FRig.Host.Time := 10;
  Assert.IsTrue(LThread.Execute);
end;

procedure TTestDoomScriptThread.DovrebbeRiprendereQuandoIlThreadAttesoFinisce;
var
  LWaiter: TDoomScriptThread;
  LOther: TDoomScriptThread;
begin
  LOther := NewThread('pauser');
  LOther.Start;
  LWaiter := NewThread('quick');
  LWaiter.ManualDelete;
  LWaiter.WaitForThread(LOther);
  Assert.AreSame(LOther, LWaiter.WaitingOnThread);
  Assert.IsTrue(LWaiter.IsWaiting);
  // another thread ending does nothing
  LWaiter.ThreadCallback(LWaiter);
  Assert.AreSame(LOther, LWaiter.WaitingOnThread);
  LOther.Free;
  Assert.IsNull(LWaiter.WaitingOnThread);
  Assert.AreEqual(1, FRig.Machine.Queue.Count, 'the waiter is scheduled');
  FRig.Frame;
  Assert.IsTrue(LWaiter.IsDying);
  // a dying thread ignores the callback
  LWaiter.WaitForThread(LWaiter);
  LWaiter.EndThread;
  LWaiter.ThreadCallback(LWaiter);
  Assert.IsTrue(LWaiter.IsDoneProcessing);
end;

procedure TTestDoomScriptThread.DovrebbeRiprendereQuandoLEntitaAttesaHaFinito;
var
  LThread: TDoomScriptThread;
begin
  FRig.AddEntity(6, 'six');
  LThread := NewThread('quick');
  LThread.WaitForEntity(6);
  Assert.IsTrue(LThread.IsWaitingFor(6));
  Assert.IsTrue(LThread.IsWaiting);
  // another entity, another thread number, no thread: nothing
  TDoomScriptThread.ObjectMoveDone(FRig.Machine.Context, LThread.ThreadNum, 7);
  TDoomScriptThread.ObjectMoveDone(FRig.Machine.Context, 0, 6);
  TDoomScriptThread.ObjectMoveDone(FRig.Machine.Context, 99, 6);
  Assert.IsTrue(LThread.IsWaitingFor(6));
  Assert.AreEqual(0, FRig.Machine.Queue.Count);
  TDoomScriptThread.ObjectMoveDone(FRig.Machine.Context, LThread.ThreadNum, 6);
  Assert.IsFalse(LThread.IsWaitingFor(6));
  Assert.AreEqual(1, FRig.Machine.Queue.Count);
end;

procedure TTestDoomScriptThread.DovrebbeUccidereIThreadPerNomeConIlCarattereJolly;
var
  LOne: TDoomScriptThread;
  LTwo: TDoomScriptThread;
  LThree: TDoomScriptThread;
begin
  LOne := FRig.Machine.CreateThread;
  LOne.SetThreadName('door_open');
  LTwo := FRig.Machine.CreateThread;
  LTwo.SetThreadName('door_close');
  LThree := FRig.Machine.CreateThread;
  LThree.SetThreadName('light');
  FRig.Machine.KillThread('door_open');
  Assert.IsTrue(LOne.IsDying);
  Assert.IsFalse(LTwo.IsDying);
  FRig.Machine.KillThread('door*');
  Assert.IsTrue(LTwo.IsDying);
  Assert.IsFalse(LThree.IsDying);
  FRig.Machine.KillThread(LThree.ThreadNum);
  Assert.IsTrue(LThree.IsDying);
  FRig.Machine.KillThread(12345);
  // as in the original the name is compared up to the length of the pattern: "li" kills "light"
  LThree := FRig.Machine.CreateThread;
  LThree.SetThreadName('light');
  FRig.Machine.KillThread('li');
  Assert.IsTrue(LThree.IsDying);
end;

procedure TTestDoomScriptThread.DovrebbeLasciareNellaListaUnThreadUccisoInPausa;
var
  LThread: TDoomScriptThread;
begin
  // kept from the original: nothing removes a paused thread that is killed, it stays in the list dying
  LThread := NewThread('pauser');
  Assert.IsFalse(LThread.Start);
  FRig.Machine.KillThread(LThread.ThreadNum);
  FRig.Frame;
  FRig.Frame;
  Assert.AreEqual(1, FRig.Machine.NumThreads);
  Assert.IsTrue(LThread.IsDying);
end;

procedure TTestDoomScriptThread.DovrebbeRimuovereIlThreadFinitoAlServizioSuccessivo;
begin
  Assert.IsTrue(NewThread('quick').Start);
  Assert.AreEqual(1, FRig.Machine.NumThreads);
  FRig.Machine.ServiceEvents;
  Assert.AreEqual(0, FRig.Machine.NumThreads);
end;

procedure TTestDoomScriptThread.DovrebbeTenereIlThreadFinitoSeLaRimozioneEManuale;
var
  LThread: TDoomScriptThread;
begin
  LThread := NewThread('quick');
  LThread.ManualDelete;
  Assert.IsTrue(LThread.Start);
  FRig.Machine.ServiceEvents;
  Assert.AreEqual(1, FRig.Machine.NumThreads);
  LThread.Free;
  Assert.AreEqual(0, FRig.Machine.NumThreads);
end;

procedure TTestDoomScriptThread.DovrebbeElencareIThread;
begin
  NewThread('sleeper').Start;
  FRig.Machine.CreateThread;
  TDoomScriptThread.ListThreads(FRig.Machine.Context);
  Assert.Contains(FRig.Printed, '  1: sleeper              : test.script(3)'#10);
  Assert.Contains(FRig.Printed, '  2: thread_2             : (0)'#10);
  Assert.Contains(FRig.Printed, '2 active threads'#10#10);
end;

procedure TTestDoomScriptThread.DovrebbeMostrareLoStatoDiUnThread;
var
  LThread: TDoomScriptThread;
  LOther: TDoomScriptThread;
begin
  FRig.AddEntity(6, 'six');
  LThread := NewThread('sleeper');
  LThread.Start;
  FRig.Host.Time := 40;
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '           1: ''sleeper'''#10'        File: test.script(3)'#10 +
    '     Created: 0 (40 ms ago)'#10'      Status: Paused since 0 (40 ms)'#10 +
    '      Reason: Waiting until 100 (100 ms total wait time)'#10);
  Assert.Contains(FRig.Printed, '  Call depth: 1, 1 max'#10);
  LOther := NewThread('quick');
  LThread.WaitForThread(LOther);
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '      Reason: Waiting for thread #  2 ''quick'''#10);
  LThread.WaitForEntity(6);
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '      Reason: Waiting for entity #  6 ''six'''#10);
  LThread.Pause;
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '      Reason: None'#10);
  LThread.ContinueProcessing;
  Assert.IsFalse(LThread.IsDoneProcessing);
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '      Status: Processing'#10);
  LThread.DoneProcessing;
  Assert.IsTrue(LThread.IsDoneProcessing);
  LThread.EndThread;
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '      Status: Dying'#10);
end;

procedure TTestDoomScriptThread.DovrebbeLasciareCorrenteIlThreadFallitoComeLOriginale;
var
  LThread: TDoomScriptThread;
  LNext: TDoomScriptThread;
begin
  // kept from the original (and in the goldens): idThread::Execute does not put the previous thread back
  // when the script ends with an error
  LThread := NewThread('failing');
  TDoomScriptTestSupport.ExpectError(procedure begin LThread.Start; end, EDoomScriptError,
    'test.script(6): Thread ''failing'': stop here'#10);
  Assert.AreSame(LThread, TDoomScriptThread.CurrentThread(FRig.Machine.Context));
  Assert.AreEqual(LThread.ThreadNum, TDoomScriptThread.CurrentThreadNum(FRig.Machine.Context));
  // a thread that runs after it puts it back
  LNext := NewThread('quick');
  LNext.Start;
  Assert.AreSame(LThread, TDoomScriptThread.CurrentThread(FRig.Machine.Context));
  // the original would keep a pointer to a thread that was removed: here it is forgotten
  LThread.Free;
  Assert.IsNull(TDoomScriptThread.CurrentThread(FRig.Machine.Context));
end;

procedure TTestDoomScriptThread.DovrebbeRipartireDaZeroConRestart;
begin
  NewThread('sleeper').Start;
  NewThread('pauser').Start;
  FRig.Machine.RestartThreads;
  Assert.AreEqual(0, FRig.Machine.NumThreads);
  Assert.AreEqual(0, FRig.Machine.Queue.Count, 'the events of the threads are cancelled');
  Assert.AreEqual(1, FRig.Machine.CreateThread.ThreadNum);
end;

procedure TTestDoomScriptThread.DovrebbeTracciareCreazioneEFineConIlDebugDegliScript;
var
  LThread: TDoomScriptThread;
begin
  FRig.Host.DebugScriptOn := True;
  FRig.Host.Time := 5;
  LThread := NewThread('quick');
  Assert.Contains(FRig.Printed, '5: create thread (1) ''quick'''#10);
  LThread.Free;
  Assert.Contains(FRig.Printed, '5: end thread (1) ''quick'''#10);
  FRig.Machine.CreateThread.Free;
  Assert.Contains(FRig.Printed, '5: create thread (2) ''thread_2'''#10);
end;

procedure TTestDoomScriptThread.DovrebbeSalvareERipristinareUnThreadCheAspetta;
var
  LThread: TDoomScriptThread;
  LCopy: TDoomScriptThread;
  LStream: TBytesStream;
begin
  LThread := NewThread('sleeper');
  LThread.SpawnArgs.SetValue('key', 'value');
  LThread.Start;
  LStream := TBytesStream.Create;
  try
    LThread.Save(LStream, FRig.Machine.WriteObject);
    LCopy := FRig.Machine.CreateThread;
    LStream.Position := 0;
    LCopy.Restore(LStream, FRig.Machine.ReadObject);
    Assert.AreEqual(LStream.Size, LStream.Position);
  finally
    LStream.Free;
  end;
  Assert.AreEqual(LThread.ThreadNum, LCopy.ThreadNum);
  Assert.AreEqual('sleeper', string(LCopy.GetThreadName));
  Assert.AreEqual(100, LCopy.WaitingUntil);
  Assert.AreEqual('value', string(LCopy.SpawnArgs.GetString('key')));
  Assert.AreEqual(LThread.Interpreter.InstructionPointer, LCopy.Interpreter.InstructionPointer);
  Assert.AreSame(LThread.Interpreter.GetCurrentFunction, LCopy.Interpreter.GetCurrentFunction);
  Assert.AreEqual(LThread.Interpreter.LocalStackUsed, LCopy.Interpreter.LocalStackUsed);
  Assert.AreEqual(LThread.Interpreter.GetCallstackDepth, LCopy.Interpreter.GetCallstackDepth);
  // the copy goes on from where the original stopped
  FRig.Host.Time := 100;
  Assert.IsTrue(LCopy.Execute);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptThread);

end.
