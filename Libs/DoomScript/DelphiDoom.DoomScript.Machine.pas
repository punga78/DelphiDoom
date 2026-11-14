{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptMachine                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): the uses of the script   }
{  system by the game (game\Game_local.cpp, game\Entity.cpp: script object     }
{  construction, save and restore of the threads and of the events).           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Machine;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.EventRegistry, DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.ClassRegistry,
  DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.EventQueue, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.ScriptObject, DelphiDoom.DoomScript.Entities,
  DelphiDoom.DoomScript.Compiler, DelphiDoom.DoomScript.Context, DelphiDoom.DoomScript.Thread,
  DelphiDoom.DoomScript.SysEvents;

const
  /// <summary>How a save refers to an entity: this flag plus the entity handle</summary>
  DS_SAVE_ENTITY_FLAG = $40000000;

type
  /// <summary>
  ///   A whole script system: the program, its compiler, the entities of the host, the threads and the
  ///   queue of the events. It owns every part (built by <c>TDoomScriptFactory</c>) and adds what the
  ///   game did around them in the original: the frame (<c>ServiceEvents</c>), the construction of the
  ///   script object of an entity and the save and restore of the whole state on a stream.
  /// </summary>
  TDoomScriptMachine = class
  strict private
    FContext: TDoomScriptContext;
    FEvents: TDoomScriptEventRegistry;
    FClasses: TDoomScriptClassRegistry;
    FProgram: TDoomScriptProgram;
    FEntities: TDoomScriptEntityTable;
    FQueue: TDoomScriptEventQueue;
    FCompiler: TDoomScriptCompiler;
    FSysEvents: TDoomScriptSysEvents;
  public
    /// <summary>Takes ownership of the parts</summary>
    constructor Create(const AContext: TDoomScriptContext; const ACompiler: TDoomScriptCompiler;
      const ASysEvents: TDoomScriptSysEvents);
    destructor Destroy; override;

    /// <summary>new idThread( func ): a thread that will run a function; start it or delay it</summary>
    function CreateThread(const AFunction: TDoomScriptFunction): TDoomScriptThread; overload;
    /// <summary>new idThread(): a thread without a function, for <c>CallFunction</c></summary>
    function CreateThread: TDoomScriptThread; overload;
    /// <summary>new idThread( self, func ): a thread that will run a method of the object of an entity</summary>
    function CreateObjectThread(const AEntityNumber: Integer; const AFunction: TDoomScriptFunction): TDoomScriptThread;
    function GetThread(const ANum: Integer): TDoomScriptThread;
    function NumThreads: Integer;
    function ThreadAt(const AIndex: Integer): TDoomScriptThread;
    procedure KillThread(const AName: AnsiString); overload;
    procedure KillThread(const ANum: Integer); overload;
    /// <summary>idThread::Restart: frees every thread</summary>
    procedure RestartThreads;
    /// <summary>idEvent::ServiceEvents: delivers the events due at the time of the host (once per frame)</summary>
    procedure ServiceEvents;

    /// <summary>
    ///   idEntity::ConstructScriptObject: gives the entity a script object of this type and runs its
    ///   <c>init</c> to the end on a thread of its own. False if the type cannot be used. Returns nil in
    ///   <c>AThread</c> when the type has no constructor; otherwise the thread (in manual control, owned
    ///   by the caller) that ran it.
    /// </summary>
    function ConstructScriptObject(const AEntityNumber: Integer; const ATypeName: AnsiString;
      out AThread: TDoomScriptThread): Boolean;
    /// <summary>idEntity::DeconstructScriptObject: runs <c>destroy</c> of the script object, if any</summary>
    procedure DeconstructScriptObject(const AEntityNumber: Integer);

    /// <summary>
    ///   idSaveGame::WriteObject for the objects the script system refers to: -1 for nil, the position in the list
    ///   of the threads plus one for a thread, DS_SAVE_ENTITY_FLAG or the handle for an entity. A host that saves
    ///   the parts of the machine one by one passes it to their <c>Save</c>.
    /// </summary>
    procedure WriteObject(const AStream: TStream; const AObject: TObject);
    /// <summary>idRestoreGame::ReadObject; raises EDoomScriptError for a thread index out of range</summary>
    function ReadObject(const AStream: TStream): TObject;
    /// <summary>
    ///   Writes the program state (idProgram::Save), every thread in the order of the list
    ///   (idThread::Save) and the queue of the events (idEvent::Save)
    /// </summary>
    procedure Save(const AStream: TStream);
    /// <summary>
    ///   Ends the threads and empties the queue, then reads what <c>Save</c> wrote. False if the
    ///   checksum of the program differs from the saved one (the state is restored all the same).
    ///   Damaged data raises EDoomScriptError and never reads or writes outside the machine.
    /// </summary>
    function Restore(const AStream: TStream): Boolean;

    property Context: TDoomScriptContext read FContext;
    property ScriptProgram: TDoomScriptProgram read FProgram;
    property Entities: TDoomScriptEntityTable read FEntities;
    property Events: TDoomScriptEventRegistry read FEvents;
    property Classes: TDoomScriptClassRegistry read FClasses;
    property Queue: TDoomScriptEventQueue read FQueue;
    property SysEvents: TDoomScriptSysEvents read FSysEvents;
  end;

implementation

uses
  DelphiDoom.DoomScript.SaveStream;

const
  SBadThreadCount = 'TDoomScriptMachine.Restore: invalid number of threads (%d)';
  SBadObject = 'TDoomScriptMachine.Restore: invalid object reference (%d)';
  SBadThreadIndex = 'TDoomScriptMachine: thread %d out of range';
  MAX_SAVED_THREADS = 65536;

constructor TDoomScriptMachine.Create(const AContext: TDoomScriptContext; const ACompiler: TDoomScriptCompiler;
  const ASysEvents: TDoomScriptSysEvents);
begin
  inherited Create;
  FContext := AContext;
  FCompiler := ACompiler;
  FSysEvents := ASysEvents;
  FEvents := AContext.Events;
  FClasses := AContext.Classes;
  FProgram := AContext.ScriptProgram;
  FEntities := AContext.Entities;
  FQueue := AContext.Queue;
end;

destructor TDoomScriptMachine.Destroy;
begin
  // threads first: their destructors use the queue and the list
  if Assigned(FContext) then
    TDoomScriptThread.Restart(FContext);
  if Assigned(FProgram) then
  begin
    FProgram.SetRestartThreads(nil);
    FProgram.SetReleaseObjects(nil);
    FProgram.SetCompiler(nil);
  end;
  FQueue.Free;
  FEntities.Free;
  FSysEvents.Free;
  FCompiler.Free;
  FProgram.Free;
  FClasses.Free;
  FEvents.Free;
  FContext.Free;
  inherited;
end;

function TDoomScriptMachine.CreateThread(const AFunction: TDoomScriptFunction): TDoomScriptThread;
begin
  Result := TDoomScriptThread.CreateForFunction(FContext, AFunction);
end;

function TDoomScriptMachine.CreateThread: TDoomScriptThread;
begin
  Result := TDoomScriptThread.Create(FContext);
end;

function TDoomScriptMachine.CreateObjectThread(const AEntityNumber: Integer;
  const AFunction: TDoomScriptFunction): TDoomScriptThread;
begin
  Result := TDoomScriptThread.CreateForObject(FContext, AEntityNumber, AFunction);
end;

function TDoomScriptMachine.GetThread(const ANum: Integer): TDoomScriptThread;
begin
  Result := TDoomScriptThread.GetThread(FContext, ANum);
end;

function TDoomScriptMachine.NumThreads: Integer;
begin
  Result := FContext.Threads.Count;
end;

function TDoomScriptMachine.ThreadAt(const AIndex: Integer): TDoomScriptThread;
begin
  if (AIndex < 0) or (AIndex >= FContext.Threads.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SBadThreadIndex, [AIndex]);
  Result := TDoomScriptThread(FContext.Threads[AIndex]);
end;

procedure TDoomScriptMachine.KillThread(const AName: AnsiString);
begin
  TDoomScriptThread.KillThread(FContext, AName);
end;

procedure TDoomScriptMachine.KillThread(const ANum: Integer);
begin
  TDoomScriptThread.KillThread(FContext, ANum);
end;

procedure TDoomScriptMachine.RestartThreads;
begin
  TDoomScriptThread.Restart(FContext);
end;

procedure TDoomScriptMachine.ServiceEvents;
begin
  FQueue.ServiceEvents;
end;

function TDoomScriptMachine.ConstructScriptObject(const AEntityNumber: Integer; const ATypeName: AnsiString;
  out AThread: TDoomScriptThread): Boolean;
var
  LObject: TDoomScriptObject;
  LConstructor: TDoomScriptFunction;
begin
  AThread := nil;
  LObject := FEntities.ObjectOf(AEntityNumber);
  if (not Assigned(LObject)) or not LObject.SetType(ATypeName) then
    Exit(False);
  Result := True;
  LConstructor := LObject.GetConstructor;
  if not Assigned(LConstructor) then
    Exit;
  // start a thread that will initialize after Spawn is done being called
  AThread := TDoomScriptThread.Create(FContext);
  AThread.ManualDelete;
  AThread.ManualControl;
  AThread.SetThreadName(FEntities.NameOf(AEntityNumber));
  AThread.CallFunction(AEntityNumber, LConstructor, True);
  AThread.Execute;
end;

procedure TDoomScriptMachine.DeconstructScriptObject(const AEntityNumber: Integer);
var
  LObject: TDoomScriptObject;
  LDestructor: TDoomScriptFunction;
  LThread: TDoomScriptThread;
begin
  LObject := FEntities.ObjectOf(AEntityNumber);
  if not Assigned(LObject) then
    Exit;
  LDestructor := LObject.GetDestructor;
  if not Assigned(LDestructor) then
    Exit;
  // start a thread that will run immediately and be destroyed
  LThread := TDoomScriptThread.Create(FContext);
  try
    LThread.ManualDelete;
    LThread.ManualControl;
    LThread.SetThreadName(FEntities.NameOf(AEntityNumber));
    LThread.CallFunction(AEntityNumber, LDestructor, True);
    LThread.Execute;
  finally
    LThread.Free;
  end;
end;

procedure TDoomScriptMachine.WriteObject(const AStream: TStream; const AObject: TObject);
var
  LNumber: Integer;
begin
  if not Assigned(AObject) then
    TDoomScriptSaveStream.WriteInt(AStream, -1)
  else if AObject is TDoomScriptThread then
    // the position in the list of the threads, from 1
    TDoomScriptSaveStream.WriteInt(AStream, FContext.Threads.IndexOf(TDoomScriptThread(AObject)) + 1)
  else
  begin
    LNumber := -1;
    if AObject is TDoomScriptEventTarget then
      LNumber := FEntities.NumberOf(TDoomScriptEventTarget(AObject));
    if LNumber < 0 then
      TDoomScriptSaveStream.WriteInt(AStream, -1)
    else
      TDoomScriptSaveStream.WriteInt(AStream, DS_SAVE_ENTITY_FLAG or LNumber);
  end;
end;

function TDoomScriptMachine.ReadObject(const AStream: TStream): TObject;
var
  LValue: Integer;
begin
  LValue := TDoomScriptSaveStream.ReadInt(AStream);
  if (LValue = -1) or (LValue = 0) then
    Exit(nil);
  if (LValue and DS_SAVE_ENTITY_FLAG) <> 0 then
    // an entity that no longer exists is no entity
    Exit(FEntities.TargetOf(LValue and not DS_SAVE_ENTITY_FLAG));
  if (LValue < 0) or (LValue > FContext.Threads.Count) then
    raise EDoomScriptError.CreateFmt(SBadObject, [LValue]);
  Result := FContext.Threads[LValue - 1];
end;

procedure TDoomScriptMachine.Save(const AStream: TStream);
var
  LIndex: Integer;
begin
  FProgram.Save(AStream);
  TDoomScriptSaveStream.WriteInt(AStream, FContext.Threads.Count);
  for LIndex := 0 to FContext.Threads.Count - 1 do
    TDoomScriptThread(FContext.Threads[LIndex]).Save(AStream, WriteObject);
  FQueue.Save(AStream, WriteObject);
end;

function TDoomScriptMachine.Restore(const AStream: TStream): Boolean;
var
  LIndex: Integer;
  LCount: Integer;
begin
  TDoomScriptThread.Restart(FContext);
  FQueue.Clear;
  Result := FProgram.Restore(AStream);
  LCount := TDoomScriptSaveStream.ReadInt(AStream);
  if (LCount < 0) or (LCount > MAX_SAVED_THREADS) then
    raise EDoomScriptError.CreateFmt(SBadThreadCount, [LCount]);
  // all the threads exist before any of them is restored: a thread may wait for a later one
  for LIndex := 0 to LCount - 1 do
    TDoomScriptThread.Create(FContext);
  for LIndex := 0 to LCount - 1 do
    TDoomScriptThread(FContext.Threads[LIndex]).Restore(AStream, ReadObject);
  FQueue.Restore(AStream, ReadObject);
end;

end.
