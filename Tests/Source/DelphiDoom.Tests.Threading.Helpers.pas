{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - jobs and helper threads         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.Helpers;

interface

uses
  System.Classes, System.SyncObjs, DelphiDoom.Threading.Intf;

const
  /// <summary>
  ///   Every wait of a test has this limit, so that a broken test fails instead of hanging the
  ///   whole run (it is a timeout, never a way to synchronise)
  /// </summary>
  TEST_TIMEOUT = 20000;

type
  /// <summary>A job that holds the worker until the test lets it go</summary>
  PBlockingJob = ^TBlockingJob;
  TBlockingJob = record
    Started: TEvent;
    Release: TEvent;
    Finished: Integer;
  end;

  /// <summary>A job that gives a job to another worker, or closes it</summary>
  PChainJob = ^TChainJob;
  TChainJob = record
    Target: IWorkerThread;
    Counter: PInteger;
    Reached: TEvent;
  end;

  /// <summary>Adds one to the integer the parameter points to (and returns the new value)</summary>
  function CountJob(AParameter: Pointer): Integer; stdcall;
  /// <summary>Returns the integer the parameter points to</summary>
  function ResultJob(AParameter: Pointer): Integer; stdcall;
  /// <summary>Raises an exception</summary>
  function RaiseJob(AParameter: Pointer): Integer; stdcall;
  /// <summary>Tells that it started, waits to be released, tells that it finished</summary>
  function BlockJob(AParameter: Pointer): Integer; stdcall;
  /// <summary>Submits CountJob to the target worker (it waits there if the target is busy)</summary>
  function SubmitCountJob(AParameter: Pointer): Integer; stdcall;
  /// <summary>Closes the target worker (it waits there if the target is busy)</summary>
  function ShutdownJob(AParameter: Pointer): Integer; stdcall;

type
  /// <summary>Submits and waits CountJob on a worker, many times, from its own thread</summary>
  TSubmitterThread = class(TThread)
  strict private
    FWorker: IWorkerThread;
    FCounter: PInteger;
    FRounds: Integer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AWorker: IWorkerThread; ACounter: PInteger; ARounds: Integer);
    /// <summary>Class and message of the exception that stopped the thread, or empty</summary>
    property Error: string read FError;
  end;

  /// <summary>Sets an event as soon as it runs</summary>
  TEventSetterThread = class(TThread)
  strict private
    FEvent: TEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: TEvent);
  end;

  /// <summary>How many threads the process has, from the toolhelp snapshot</summary>
  TThreadCounter = class
  public
    class function Count: Integer; static;
    /// <summary>
    ///   Fails if the process has more threads than ABefore plus a small margin (the system
    ///   may start a thread of its own); a leaked worker thread is far beyond it in the
    ///   tests that call this
    /// </summary>
    class procedure AssertNotAbove(ABefore: Integer); static;
  end;

/// <summary>Makes the two events of a blocking job (not signalled)</summary>
procedure InitBlockingJob(var AJob: TBlockingJob);
/// <summary>Lets the job go (if it still waits) and frees its events</summary>
procedure DoneBlockingJob(var AJob: TBlockingJob);

implementation

uses
  Winapi.Windows, Winapi.TlHelp32, System.SysUtils, DUnitX.TestFramework;

const
  THREAD_MARGIN = 2;

procedure InitBlockingJob(var AJob: TBlockingJob);
begin
  AJob.Started := TEvent.Create(nil, True, False, '');
  AJob.Release := TEvent.Create(nil, True, False, '');
  AJob.Finished := 0;
end;

procedure DoneBlockingJob(var AJob: TBlockingJob);
begin
  if Assigned(AJob.Release) then
    AJob.Release.SetEvent;
  FreeAndNil(AJob.Release);
  FreeAndNil(AJob.Started);
end;

function CountJob(AParameter: Pointer): Integer; stdcall;
begin
  Result := TInterlocked.Increment(PInteger(AParameter)^);
end;

function ResultJob(AParameter: Pointer): Integer; stdcall;
begin
  Result := PInteger(AParameter)^;
end;

function RaiseJob(AParameter: Pointer): Integer; stdcall;
begin
  Result := 0;
  raise EInvalidOpException.Create('job failed on purpose');
end;

function BlockJob(AParameter: Pointer): Integer; stdcall;
var
  LJob: PBlockingJob;
begin
  LJob := PBlockingJob(AParameter);
  LJob.Started.SetEvent;
  LJob.Release.WaitFor(TEST_TIMEOUT);
  TInterlocked.Increment(LJob.Finished);
  Result := 7;
end;

function SubmitCountJob(AParameter: Pointer): Integer; stdcall;
var
  LJob: PChainJob;
begin
  LJob := PChainJob(AParameter);
  LJob.Reached.SetEvent;
  LJob.Target.Submit(CountJob, LJob.Counter);
  Result := 0;
end;

function ShutdownJob(AParameter: Pointer): Integer; stdcall;
var
  LJob: PChainJob;
begin
  LJob := PChainJob(AParameter);
  LJob.Reached.SetEvent;
  LJob.Target.Shutdown;
  Result := 0;
end;

{ TSubmitterThread }

constructor TSubmitterThread.Create(const AWorker: IWorkerThread; ACounter: PInteger;
  ARounds: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorker := AWorker;
  FCounter := ACounter;
  FRounds := ARounds;
end;

procedure TSubmitterThread.Execute;
var
  LRound: Integer;
begin
  try
    for LRound := 1 to FRounds do
    begin
      FWorker.Submit(CountJob, FCounter);
      FWorker.Wait;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

{ TEventSetterThread }

constructor TEventSetterThread.Create(AEvent: TEvent);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
end;

procedure TEventSetterThread.Execute;
begin
  FEvent.SetEvent;
end;

{ TThreadCounter }

class function TThreadCounter.Count: Integer;
var
  LSnapshot: THandle;
  LEntry: TThreadEntry32;
  LProcessId: DWORD;
begin
  Result := 0;
  LProcessId := GetCurrentProcessId;
  LSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if LSnapshot = INVALID_HANDLE_VALUE then
    raise Exception.Create('The thread snapshot could not be taken');
  try
    LEntry.dwSize := SizeOf(LEntry);
    if Thread32First(LSnapshot, LEntry) then
      repeat
        if LEntry.th32OwnerProcessID = LProcessId then
          Inc(Result);
      until not Thread32Next(LSnapshot, LEntry);
  finally
    CloseHandle(LSnapshot);
  end;
end;

class procedure TThreadCounter.AssertNotAbove(ABefore: Integer);
var
  LNow: Integer;
begin
  LNow := Count;
  Assert.IsTrue(LNow <= ABefore + THREAD_MARGIN,
    Format('Threads of the process: %d before, %d now', [ABefore, LNow]));
end;

end.
