{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - the worker thread                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.WorkerThread;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.Threading.Intf, DelphiDoom.Threading.Types;

type
  /// <summary>
  ///   A thread made with CreateThread (like the old engine threads, so each job runs with the
  ///   floating point state Windows gives to a new thread) that sleeps on an event until it gets
  ///   a job. The thread never touches the interface reference counts: the object is alive
  ///   until Shutdown (or the destructor) has seen the thread leave.
  /// </summary>
  /// <remarks>
  ///   State (busy flag, pending failure, result) is guarded by one critical section; two events
  ///   carry the hand-over: FWake (auto reset) tells the thread that a job or the exit is
  ///   ready, FIdle (manual reset) is set while no job is running.
  /// </remarks>
  TWorkerThread = class(TInterfacedObject, IWorkerThread)
  strict private
    FLock: TCriticalSection;
    FWake: TEvent;
    FIdle: TEvent;
    FHandle: THandle;
    FProc: TWorkerProc;
    FParameter: Pointer;
    FBusy: Boolean;
    FTerminated: Boolean;
    FHasFailure: Boolean;
    FFailureClassName: string;
    FFailureMessage: string;
    FLastResult: Integer;
    /// <summary>Waits for the idle state and returns with FLock held and FBusy false</summary>
    procedure EnterWhenIdle;
    procedure RecordFailure(const AException: Exception);
    function TakeFailure(out AClassName, AMessage: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Submit(AProc: TWorkerProc; AParameter: Pointer);
    procedure Wait;
    function IsIdle: Boolean;
    function LastResult: Integer;
    procedure Shutdown;
    /// <summary>The body of the thread; only the thread procedure calls it</summary>
    procedure RunLoop;
  end;

implementation

uses
  Winapi.Windows;

const
  SNilJob = 'A worker job needs a procedure.';
  SWorkerClosed = 'The worker thread is closed.';
  SCannotStart = 'The worker thread could not be started.';

function WorkerThreadProc(AParameter: Pointer): DWORD; stdcall;
begin
  TWorkerThread(AParameter).RunLoop;
  Result := 0;
end;

{ TWorkerThread }

constructor TWorkerThread.Create;
var
  LThreadId: DWORD;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FWake := TEvent.Create(nil, False, False, '');
  FIdle := TEvent.Create(nil, True, True, '');
  // the memory manager must be thread safe from now on
  IsMultiThread := True;
  FHandle := CreateThread(nil, 0, @WorkerThreadProc, Self, 0, LThreadId);
  if FHandle = 0 then
    raise EThreadingException.Create(SCannotStart);
end;

destructor TWorkerThread.Destroy;
begin
  if Assigned(FLock) and Assigned(FIdle) and Assigned(FWake) then
    Shutdown;
  FIdle.Free;
  FWake.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TWorkerThread.EnterWhenIdle;
var
  LReady: Boolean;
begin
  repeat
    FIdle.WaitFor(INFINITE);
    FLock.Enter;
    LReady := not FBusy;
    if not LReady then
      FLock.Leave;
  until LReady;
end;

procedure TWorkerThread.RecordFailure(const AException: Exception);
begin
  FLock.Enter;
  try
    FHasFailure := True;
    FFailureClassName := AException.ClassName;
    FFailureMessage := AException.Message;
  finally
    FLock.Leave;
  end;
end;

function TWorkerThread.TakeFailure(out AClassName, AMessage: string): Boolean;
begin
  FLock.Enter;
  try
    Result := FHasFailure;
    if Result then
    begin
      AClassName := FFailureClassName;
      AMessage := FFailureMessage;
      FHasFailure := False;
      FFailureClassName := '';
      FFailureMessage := '';
    end
    else
    begin
      AClassName := '';
      AMessage := '';
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TWorkerThread.Submit(AProc: TWorkerProc; AParameter: Pointer);
var
  LClassName: string;
  LMessage: string;
begin
  if not Assigned(AProc) then
    raise EThreadingException.Create(SNilJob);
  EnterWhenIdle;
  try
    if FTerminated then
      raise EThreadingException.Create(SWorkerClosed);
    // the failure of the previous job goes to the next one who talks to the worker
    if TakeFailure(LClassName, LMessage) then
      raise EWorkerJobException.Create(LClassName, LMessage);
    FProc := AProc;
    FParameter := AParameter;
    FBusy := True;
    FIdle.ResetEvent;
    FWake.SetEvent;
  finally
    FLock.Leave;
  end;
end;

procedure TWorkerThread.Wait;
var
  LClassName: string;
  LMessage: string;
begin
  FIdle.WaitFor(INFINITE);
  if TakeFailure(LClassName, LMessage) then
    raise EWorkerJobException.Create(LClassName, LMessage);
end;

function TWorkerThread.IsIdle: Boolean;
begin
  FLock.Enter;
  try
    Result := not FBusy;
  finally
    FLock.Leave;
  end;
end;

function TWorkerThread.LastResult: Integer;
begin
  FLock.Enter;
  try
    Result := FLastResult;
  finally
    FLock.Leave;
  end;
end;

procedure TWorkerThread.Shutdown;
var
  LHandle: THandle;
begin
  // a running job is never abandoned: wait for it, then ask the thread to leave
  EnterWhenIdle;
  try
    FTerminated := True;
    LHandle := FHandle;
    FHandle := 0;
  finally
    FLock.Leave;
  end;
  if LHandle <> 0 then
  begin
    FWake.SetEvent;
    WaitForSingleObject(LHandle, INFINITE);
    CloseHandle(LHandle);
  end;
end;

procedure TWorkerThread.RunLoop;
var
  LProc: TWorkerProc;
  LParameter: Pointer;
  LResult: Integer;
  LLeave: Boolean;
begin
  LLeave := False;
  while not LLeave do
  begin
    FWake.WaitFor(INFINITE);
    FLock.Enter;
    try
      LLeave := FTerminated;
      LProc := FProc;
      LParameter := FParameter;
    finally
      FLock.Leave;
    end;
    if not LLeave then
    begin
      LResult := 0;
      try
        LResult := LProc(LParameter);
      except
        on E: Exception do
          RecordFailure(E);
      end;
      FLock.Enter;
      try
        FLastResult := LResult;
        FBusy := False;
        FIdle.SetEvent;
      finally
        FLock.Leave;
      end;
    end;
  end;
end;

end.
