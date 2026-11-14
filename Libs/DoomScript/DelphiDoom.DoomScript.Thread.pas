{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptThread (idThread)          }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Thread.h, Script_Thread.cpp. Copyright (C) 1999-2011 id Software     }
{  LLC, a ZeniMax Media company.                                               }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Thread;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.Interpreter, DelphiDoom.DoomScript.Context, DelphiDoom.DoomScript.SaveStream;

type
  /// <summary>
  ///   idThread: a script thread - an interpreter, what it is waiting for and its name. A thread is in
  ///   the list of its context from creation to destruction; it runs when <c>Execute</c> is called, by
  ///   the event "&lt;execute&gt;" of the queue or by its owner (<c>ManualControl</c>). A thread that
  ///   ends posts its own removal ("&lt;immediateremove&gt;") unless <c>ManualDelete</c> was called: then
  ///   the owner frees it. The time is always the one of the host.
  /// </summary>
  TDoomScriptThread = class(TDoomScriptThreadBase)
  strict private
    FContext: TDoomScriptContext;
    FInterpreter: TDoomScriptInterpreter;
    FSpawnArgs: TIdDict;
    FThreadNum: Integer;
    FThreadName: AnsiString;
    FLastExecuteTime: Integer;
    FCreationTime: Integer;
    FManualControl: Boolean;
    FWaitingForThread: TDoomScriptThread;
    FWaitingFor: Integer;
    FWaitingUntil: Integer;
    procedure Init;
    procedure DebugCreate;
  public
    /// <summary>idThread(): a thread with no function, called "thread_N"</summary>
    constructor Create(const AContext: TDoomScriptContext);
    /// <summary>idThread( self, func ): enters a method of the script object of an entity</summary>
    constructor CreateForObject(const AContext: TDoomScriptContext; const AEntityNumber: Integer;
      const AFunction: TDoomScriptFunction);
    /// <summary>idThread( func ): enters a function</summary>
    constructor CreateForFunction(const AContext: TDoomScriptContext; const AFunction: TDoomScriptFunction);
    /// <summary>idThread( source, func, args ): <c>thread f( ... )</c> of a script</summary>
    constructor CreateCall(const AContext: TDoomScriptContext; const ASource: TDoomScriptInterpreter;
      const AFunction: TDoomScriptFunction; const AArgs: Integer);
    destructor Destroy; override;

    function GetThreadName: AnsiString; override;
    procedure SetThreadName(const AName: AnsiString); override;
    function StartThread(const ASource: TDoomScriptInterpreter; const AFunction: TDoomScriptFunction;
      const AArgs: Integer): Integer; override;

    /// <summary>Tells the thread not to remove itself when it ends</summary>
    procedure ManualDelete;
    procedure Save(const AStream: TStream; const AWriteObject: TDoomScriptWriteObject);
    procedure Restore(const AStream: TStream; const AReadObject: TDoomScriptReadObject);
    procedure EnableDebugInfo;
    procedure DisableDebugInfo;
    procedure Pause;
    procedure WaitMS(const ATime: Integer);
    procedure WaitSec(const ATime: Single);
    procedure WaitFrame;
    /// <summary>Waits until the entity calls <c>ObjectMoveDone</c></summary>
    procedure WaitForEntity(const AEntityNumber: Integer);
    procedure WaitForThread(const AThread: TDoomScriptThread);
    procedure CallFunction(const AFunction: TDoomScriptFunction; const AClearStack: Boolean); overload;
    procedure CallFunction(const AEntityNumber: Integer; const AFunction: TDoomScriptFunction;
      const AClearStack: Boolean); overload;
    procedure DisplayInfo;
    function IsDoneProcessing: Boolean;
    function IsDying: Boolean;
    /// <summary>Tells the thread to die: it exits on its own</summary>
    procedure EndThread;
    /// <summary>Runs the thread; true when it is done</summary>
    function Execute: Boolean;
    procedure ManualControl;
    procedure DoneProcessing;
    procedure ContinueProcessing;
    function IsWaiting: Boolean;
    procedure ClearWaitFor;
    function IsWaitingFor(const AEntityNumber: Integer): Boolean;
    procedure ObjectMoveDone(const AEntityNumber: Integer); overload;
    procedure ThreadCallback(const AThread: TDoomScriptThread);
    procedure DelayedStart(ADelay: Integer);
    function Start: Boolean;
    function WaitingOnThread: TDoomScriptThread;
    /// <summary>Raises the error of the interpreter, with file, line and thread name</summary>
    procedure Error(const AText: string);
    procedure Warning(const AText: string);

    /// <summary>idThread::GetThread: the thread with this number, nil if none</summary>
    class function GetThread(const AContext: TDoomScriptContext; const ANum: Integer): TDoomScriptThread; static;
    /// <summary>idThread::KillThread( name ): ends the threads whose name matches; a '*' ends the comparison</summary>
    class procedure KillThread(const AContext: TDoomScriptContext; const AName: AnsiString); overload; static;
    class procedure KillThread(const AContext: TDoomScriptContext; const ANum: Integer); overload; static;
    /// <summary>idThread::Restart: frees every thread and resets the numbering</summary>
    class procedure Restart(const AContext: TDoomScriptContext); static;
    /// <summary>idThread::ObjectMoveDone( threadnum, obj )</summary>
    class procedure ObjectMoveDone(const AContext: TDoomScriptContext; const AThreadNum,
      AEntityNumber: Integer); overload; static;
    /// <summary>idThread::ListThreads_f</summary>
    class procedure ListThreads(const AContext: TDoomScriptContext); static;
    /// <summary>idThread::CurrentThread</summary>
    class function CurrentThread(const AContext: TDoomScriptContext): TDoomScriptThread; static;
    class function CurrentThreadNum(const AContext: TDoomScriptContext): Integer; static;
    class function BeginMultiFrameEvent(const AContext: TDoomScriptContext; const AEntity: TDoomScriptEventTarget;
      const AEvent: TDoomScriptEventDef): Boolean; static;
    class procedure EndMultiFrameEvent(const AContext: TDoomScriptContext; const AEntity: TDoomScriptEventTarget;
      const AEvent: TDoomScriptEventDef); static;

    property Context: TDoomScriptContext read FContext;
    property Interpreter: TDoomScriptInterpreter read FInterpreter;
    property SpawnArgs: TIdDict read FSpawnArgs;
    property ThreadNum: Integer read FThreadNum write FThreadNum;
    property LastExecuteTime: Integer read FLastExecuteTime;
    property CreationTime: Integer read FCreationTime;
    property IsManualControl: Boolean read FManualControl;
    property WaitingFor: Integer read FWaitingFor;
    property WaitingUntil: Integer read FWaitingUntil;
  end;

implementation

const
  SNoCurrentThreadBegin = 'idThread::BeginMultiFrameEvent called without a current thread';
  SNoCurrentThreadEnd = 'idThread::EndMultiFrameEvent called without a current thread';
  SRestoreWaitingFor = 'idThread::Restore: invalid entity number %d';

{ TDoomScriptThread }

procedure TDoomScriptThread.Init;
begin
  FSpawnArgs := TIdDict.Create(FContext.Log);
  FInterpreter := TDoomScriptInterpreter.Create(FContext.ScriptProgram, FContext.Entities, FContext.Events,
    FContext.Host, FContext.Log, Self);
  // create a unique threadNum
  repeat
    Inc(FContext.ThreadIndex);
    if FContext.ThreadIndex = 0 then
      FContext.ThreadIndex := 1;
  until not Assigned(GetThread(FContext, FContext.ThreadIndex));
  FThreadNum := FContext.ThreadIndex;
  FContext.Threads.Add(Self);
  FCreationTime := FContext.Host.GetTime;
  FLastExecuteTime := 0;
  FManualControl := False;
  ClearWaitFor;
end;

procedure TDoomScriptThread.DebugCreate;
begin
  if FContext.Host.DebugScript then
    FContext.Print(Format('%d: create thread (%d) ''%s'''#10, [FContext.Host.GetTime, FThreadNum,
      string(FThreadName)]));
end;

constructor TDoomScriptThread.Create(const AContext: TDoomScriptContext);
begin
  inherited Create(AContext.ThreadClass);
  FContext := AContext;
  Init;
  SetThreadName(AnsiString(Format('thread_%d', [FContext.ThreadIndex])));
  DebugCreate;
end;

constructor TDoomScriptThread.CreateForObject(const AContext: TDoomScriptContext; const AEntityNumber: Integer;
  const AFunction: TDoomScriptFunction);
begin
  inherited Create(AContext.ThreadClass);
  FContext := AContext;
  Init;
  SetThreadName(FContext.Entities.NameOf(AEntityNumber));
  FInterpreter.EnterObjectFunction(AEntityNumber, AFunction, False);
  DebugCreate;
end;

constructor TDoomScriptThread.CreateForFunction(const AContext: TDoomScriptContext;
  const AFunction: TDoomScriptFunction);
begin
  inherited Create(AContext.ThreadClass);
  FContext := AContext;
  Init;
  if Assigned(AFunction) then
    SetThreadName(AFunction.Name);
  FInterpreter.EnterFunction(AFunction, False);
  DebugCreate;
end;

constructor TDoomScriptThread.CreateCall(const AContext: TDoomScriptContext; const ASource: TDoomScriptInterpreter;
  const AFunction: TDoomScriptFunction; const AArgs: Integer);
begin
  inherited Create(AContext.ThreadClass);
  FContext := AContext;
  Init;
  FInterpreter.ThreadCall(ASource, AFunction, AArgs);
  DebugCreate;
end;

destructor TDoomScriptThread.Destroy;
var
  LIndex: Integer;
  LCount: Integer;
  LThread: TDoomScriptThread;
begin
  // a constructor that failed before Init has no context parts to release
  if Assigned(FContext) and Assigned(FInterpreter) then
  begin
    if FContext.Host.DebugScript then
      FContext.Print(Format('%d: end thread (%d) ''%s'''#10, [FContext.Host.GetTime, FThreadNum,
        string(FThreadName)]));
    FContext.Threads.Remove(Self);
    LCount := FContext.Threads.Count;
    LIndex := 0;
    while (LIndex < LCount) and (LIndex < FContext.Threads.Count) do
    begin
      LThread := TDoomScriptThread(FContext.Threads[LIndex]);
      if LThread.WaitingOnThread = Self then
        LThread.ThreadCallback(Self);
      Inc(LIndex);
    end;
    if FContext.CurrentThread = Self then
      FContext.CurrentThread := nil;
    // idClass::~idClass
    FContext.Queue.CancelEvents(Self);
  end;
  FInterpreter.Free;
  FSpawnArgs.Free;
  inherited;
end;

function TDoomScriptThread.GetThreadName: AnsiString;
begin
  Result := FThreadName;
end;

procedure TDoomScriptThread.SetThreadName(const AName: AnsiString);
begin
  FThreadName := AName;
end;

function TDoomScriptThread.StartThread(const ASource: TDoomScriptInterpreter; const AFunction: TDoomScriptFunction;
  const AArgs: Integer): Integer;
var
  LThread: TDoomScriptThread;
begin
  LThread := TDoomScriptThread.CreateCall(FContext, ASource, AFunction, AArgs);
  Result := LThread.ThreadNum;
  LThread.Start;
end;

procedure TDoomScriptThread.ManualDelete;
begin
  FInterpreter.TerminateOnExit := False;
end;

procedure TDoomScriptThread.Save(const AStream: TStream; const AWriteObject: TDoomScriptWriteObject);
begin
  // threads are restored in the same order: the number is checked then
  TDoomScriptSaveStream.WriteInt(AStream, FThreadNum);
  AWriteObject(AStream, FWaitingForThread);
  TDoomScriptSaveStream.WriteInt(AStream, FWaitingFor);
  TDoomScriptSaveStream.WriteInt(AStream, FWaitingUntil);
  FInterpreter.Save(AStream, AWriteObject);
  TDoomScriptSaveStream.WriteDict(AStream, FSpawnArgs);
  TDoomScriptSaveStream.WriteString(AStream, FThreadName);
  TDoomScriptSaveStream.WriteInt(AStream, FLastExecuteTime);
  TDoomScriptSaveStream.WriteInt(AStream, FCreationTime);
  TDoomScriptSaveStream.WriteBool(AStream, FManualControl);
end;

procedure TDoomScriptThread.Restore(const AStream: TStream; const AReadObject: TDoomScriptReadObject);
var
  LObject: TObject;
  LWaitingFor: Integer;
begin
  FThreadNum := TDoomScriptSaveStream.ReadInt(AStream);
  LObject := AReadObject(AStream);
  if LObject is TDoomScriptThread then
    FWaitingForThread := TDoomScriptThread(LObject)
  else
    FWaitingForThread := nil;
  LWaitingFor := TDoomScriptSaveStream.ReadInt(AStream);
  if (LWaitingFor < 0) or (LWaitingFor >= DS_MAX_GENTITIES) then
    raise EDoomScriptMemoryError.CreateFmt(SRestoreWaitingFor, [LWaitingFor]);
  FWaitingFor := LWaitingFor;
  FWaitingUntil := TDoomScriptSaveStream.ReadInt(AStream);
  FInterpreter.Restore(AStream, AReadObject);
  TDoomScriptSaveStream.ReadDict(AStream, FSpawnArgs);
  FThreadName := TDoomScriptSaveStream.ReadString(AStream);
  FLastExecuteTime := TDoomScriptSaveStream.ReadInt(AStream);
  FCreationTime := TDoomScriptSaveStream.ReadInt(AStream);
  FManualControl := TDoomScriptSaveStream.ReadBool(AStream);
end;

procedure TDoomScriptThread.EnableDebugInfo;
begin
  FInterpreter.Debug := True;
end;

procedure TDoomScriptThread.DisableDebugInfo;
begin
  FInterpreter.Debug := False;
end;

class function TDoomScriptThread.GetThread(const AContext: TDoomScriptContext; const ANum: Integer): TDoomScriptThread;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AContext.Threads.Count - 1 do
    if TDoomScriptThread(AContext.Threads[LIndex]).FThreadNum = ANum then
      Exit(TDoomScriptThread(AContext.Threads[LIndex]));
  Result := nil;
end;

class function TDoomScriptThread.CurrentThread(const AContext: TDoomScriptContext): TDoomScriptThread;
begin
  Result := TDoomScriptThread(AContext.CurrentThread);
end;

class function TDoomScriptThread.CurrentThreadNum(const AContext: TDoomScriptContext): Integer;
begin
  if Assigned(AContext.CurrentThread) then
    Result := TDoomScriptThread(AContext.CurrentThread).FThreadNum
  else
    Result := 0;
end;

class function TDoomScriptThread.BeginMultiFrameEvent(const AContext: TDoomScriptContext;
  const AEntity: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef): Boolean;
begin
  if not Assigned(AContext.CurrentThread) then
    raise EDoomScriptError.Create(SNoCurrentThreadBegin);
  Result := TDoomScriptThread(AContext.CurrentThread).FInterpreter.BeginMultiFrameEvent(AEntity, AEvent);
end;

class procedure TDoomScriptThread.EndMultiFrameEvent(const AContext: TDoomScriptContext;
  const AEntity: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef);
begin
  if not Assigned(AContext.CurrentThread) then
    raise EDoomScriptError.Create(SNoCurrentThreadEnd);
  TDoomScriptThread(AContext.CurrentThread).FInterpreter.EndMultiFrameEvent(AEntity, AEvent);
end;

procedure TDoomScriptThread.DisplayInfo;
var
  LTime: Integer;
begin
  LTime := FContext.Host.GetTime;
  FContext.Print(Format('%12d: ''%s'''#10'        File: %s(%d)'#10'     Created: %d (%d ms ago)'#10'      Status: ',
    [FThreadNum, string(FThreadName), string(FInterpreter.CurrentFile), FInterpreter.CurrentLine, FCreationTime,
    LTime - FCreationTime]));
  if FInterpreter.ThreadDying then
    FContext.Print('Dying'#10)
  else if FInterpreter.DoneProcessing then
  begin
    FContext.Print(Format('Paused since %d (%d ms)'#10'      Reason: ', [FLastExecuteTime, LTime - FLastExecuteTime]));
    if Assigned(FWaitingForThread) then
      FContext.Print(Format('Waiting for thread #%3d ''%s'''#10, [FWaitingForThread.FThreadNum,
        string(FWaitingForThread.FThreadName)]))
    else if (FWaitingFor <> DS_ENTITYNUM_NONE) and FContext.Entities.Exists(FWaitingFor) then
      FContext.Print(Format('Waiting for entity #%3d ''%s'''#10, [FWaitingFor,
        string(FContext.Entities.NameOf(FWaitingFor))]))
    else if FWaitingUntil <> 0 then
      FContext.Print(Format('Waiting until %d (%d ms total wait time)'#10, [FWaitingUntil,
        FWaitingUntil - FLastExecuteTime]))
    else
      FContext.Print('None'#10);
  end
  else
    FContext.Print('Processing'#10);
  FInterpreter.DisplayInfo;
  FContext.Print(#10);
end;

class procedure TDoomScriptThread.ListThreads(const AContext: TDoomScriptContext);
var
  LIndex: Integer;
  LThread: TDoomScriptThread;
begin
  for LIndex := 0 to AContext.Threads.Count - 1 do
  begin
    LThread := TDoomScriptThread(AContext.Threads[LIndex]);
    AContext.Print(Format('%3d: %-20s : %s(%d)'#10, [LThread.FThreadNum, string(LThread.FThreadName),
      string(LThread.FInterpreter.CurrentFile), LThread.FInterpreter.CurrentLine]));
  end;
  AContext.Print(Format('%d active threads'#10#10, [AContext.Threads.Count]));
end;

class procedure TDoomScriptThread.Restart(const AContext: TDoomScriptContext);
var
  LIndex: Integer;
begin
  // reset the threadIndex
  AContext.ThreadIndex := 0;
  AContext.CurrentThread := nil;
  LIndex := AContext.Threads.Count - 1;
  while LIndex >= 0 do
  begin
    if LIndex < AContext.Threads.Count then
      AContext.Threads[LIndex].Free;
    Dec(LIndex);
  end;
  AContext.Threads.Clear;
end;

procedure TDoomScriptThread.DelayedStart(ADelay: Integer);
begin
  FContext.Queue.CancelEvents(Self, FContext.EvExecute);
  if FContext.Host.GetTime <= 0 then
    Inc(ADelay);
  FContext.Queue.PostEventMS(Self, FContext.EvExecute, ADelay);
end;

function TDoomScriptThread.Start: Boolean;
begin
  FContext.Queue.CancelEvents(Self, FContext.EvExecute);
  Result := Execute;
end;

class procedure TDoomScriptThread.ObjectMoveDone(const AContext: TDoomScriptContext; const AThreadNum,
  AEntityNumber: Integer);
var
  LThread: TDoomScriptThread;
begin
  if AThreadNum = 0 then
    Exit;
  LThread := GetThread(AContext, AThreadNum);
  if Assigned(LThread) then
    LThread.ObjectMoveDone(AEntityNumber);
end;

procedure TDoomScriptThread.EndThread;
begin
  // Tell thread to die.  It will exit on its own.
  Pause;
  FInterpreter.ThreadDying := True;
end;

class procedure TDoomScriptThread.KillThread(const AContext: TDoomScriptContext; const AName: AnsiString);
var
  LIndex: Integer;
  LLength: Integer;
  LThread: TDoomScriptThread;
begin
  // see if the name uses a wild card
  LLength := Pos(AnsiChar('*'), AName) - 1;
  if LLength < 0 then
    LLength := Length(AName);
  // kill only those threads whose name matches name
  for LIndex := 0 to AContext.Threads.Count - 1 do
  begin
    LThread := TDoomScriptThread(AContext.Threads[LIndex]);
    if Copy(LThread.FThreadName, 1, LLength) = Copy(AName, 1, LLength) then
      LThread.EndThread;
  end;
end;

class procedure TDoomScriptThread.KillThread(const AContext: TDoomScriptContext; const ANum: Integer);
var
  LThread: TDoomScriptThread;
begin
  LThread := GetThread(AContext, ANum);
  if Assigned(LThread) then
    // Tell thread to die.  It will delete itself on it's own.
    LThread.EndThread;
end;

function TDoomScriptThread.Execute: Boolean;
var
  LOldThread: TDoomScriptThreadBase;
  LTime: Integer;
begin
  LTime := FContext.Host.GetTime;
  if FManualControl and (FWaitingUntil > LTime) then
    Exit(False);
  LOldThread := FContext.CurrentThread;
  FContext.CurrentThread := Self;
  FLastExecuteTime := LTime;
  ClearWaitFor;
  Result := FInterpreter.Execute;
  if Result then
  begin
    EndThread;
    if FInterpreter.TerminateOnExit then
      FContext.Queue.PostEventMS(Self, FContext.EvRemove, 0);
  end
  else if not FManualControl then
  begin
    if FWaitingUntil > FLastExecuteTime then
      FContext.Queue.PostEventMS(Self, FContext.EvExecute, FWaitingUntil - FLastExecuteTime)
    else if FInterpreter.MultiFrameEventInProgress then
      FContext.Queue.PostEventMS(Self, FContext.EvExecute, FContext.Host.GetFrameMsec);
  end;
  // As in the original, an error leaves this thread as the current one (no try/finally). The thread that was
  // current before may have been removed meanwhile: the original would keep its dangling pointer.
  if Assigned(LOldThread) and (FContext.Threads.IndexOf(LOldThread) < 0) then
    LOldThread := nil;
  FContext.CurrentThread := LOldThread;
end;

procedure TDoomScriptThread.ManualControl;
begin
  FManualControl := True;
  FContext.Queue.CancelEvents(Self, FContext.EvExecute);
end;

procedure TDoomScriptThread.DoneProcessing;
begin
  FInterpreter.DoneProcessing := True;
end;

procedure TDoomScriptThread.ContinueProcessing;
begin
  FInterpreter.DoneProcessing := False;
end;

function TDoomScriptThread.IsDoneProcessing: Boolean;
begin
  Result := FInterpreter.DoneProcessing;
end;

function TDoomScriptThread.IsDying: Boolean;
begin
  Result := FInterpreter.ThreadDying;
end;

function TDoomScriptThread.IsWaiting: Boolean;
begin
  if Assigned(FWaitingForThread) or (FWaitingFor <> DS_ENTITYNUM_NONE) then
    Exit(True);
  Result := (FWaitingUntil <> 0) and (FWaitingUntil > FContext.Host.GetTime);
end;

procedure TDoomScriptThread.CallFunction(const AFunction: TDoomScriptFunction; const AClearStack: Boolean);
begin
  ClearWaitFor;
  FInterpreter.EnterFunction(AFunction, AClearStack);
end;

procedure TDoomScriptThread.CallFunction(const AEntityNumber: Integer; const AFunction: TDoomScriptFunction;
  const AClearStack: Boolean);
begin
  ClearWaitFor;
  FInterpreter.EnterObjectFunction(AEntityNumber, AFunction, AClearStack);
end;

procedure TDoomScriptThread.ClearWaitFor;
begin
  FWaitingFor := DS_ENTITYNUM_NONE;
  FWaitingForThread := nil;
  FWaitingUntil := 0;
end;

function TDoomScriptThread.IsWaitingFor(const AEntityNumber: Integer): Boolean;
begin
  Result := FWaitingFor = AEntityNumber;
end;

procedure TDoomScriptThread.ObjectMoveDone(const AEntityNumber: Integer);
begin
  if IsWaitingFor(AEntityNumber) then
  begin
    ClearWaitFor;
    DelayedStart(0);
  end;
end;

procedure TDoomScriptThread.ThreadCallback(const AThread: TDoomScriptThread);
begin
  if FInterpreter.ThreadDying then
    Exit;
  if AThread = FWaitingForThread then
  begin
    ClearWaitFor;
    DelayedStart(0);
  end;
end;

function TDoomScriptThread.WaitingOnThread: TDoomScriptThread;
begin
  Result := FWaitingForThread;
end;

procedure TDoomScriptThread.Error(const AText: string);
begin
  FInterpreter.Error(AText);
end;

procedure TDoomScriptThread.Warning(const AText: string);
begin
  FInterpreter.Warning(AText);
end;

procedure TDoomScriptThread.Pause;
begin
  ClearWaitFor;
  FInterpreter.DoneProcessing := True;
end;

procedure TDoomScriptThread.WaitMS(const ATime: Integer);
begin
  Pause;
  FWaitingUntil := FContext.Host.GetTime + ATime;
end;

procedure TDoomScriptThread.WaitSec(const ATime: Single);
begin
  WaitMS(TDoomScriptConvert.SecToMs(ATime));
end;

procedure TDoomScriptThread.WaitFrame;
begin
  Pause;
  // manual control threads don't set waitingUntil so that they can be run again that frame if necessary
  if not FManualControl then
    FWaitingUntil := FContext.Host.GetTime + FContext.Host.GetFrameMsec;
end;

procedure TDoomScriptThread.WaitForEntity(const AEntityNumber: Integer);
begin
  Pause;
  FWaitingFor := AEntityNumber;
end;

procedure TDoomScriptThread.WaitForThread(const AThread: TDoomScriptThread);
begin
  Pause;
  FWaitingForThread := AThread;
end;

end.
