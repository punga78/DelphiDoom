{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptEventQueue (idEvent)       }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\gamesys\Event.h,    }
{  Event.cpp and the PostEvent/CancelEvents part of Class.cpp. Copyright (C)   }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.EventQueue;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry,
  DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.ClassRegistry, DelphiDoom.DoomScript.EventTarget,
  DelphiDoom.DoomScript.Entities, DelphiDoom.DoomScript.SaveStream;

type
  /// <summary>An event waiting in the queue</summary>
  TDoomScriptQueuedEvent = class
  public
    Time: Integer;
    EventDef: TDoomScriptEventDef;
    Target: TDoomScriptEventTarget;
    /// <summary>The class of the target when the event was posted</summary>
    TargetClass: TDoomScriptClassInfo;
    Args: TDoomScriptEventArgs;
    // the targets of the entity arguments, to know at delivery if the entity is still the same
    EntityTargets: array[0..DS_EVENT_MAXARGS - 1] of TDoomScriptEventTarget;
  end;


  /// <summary>
  ///   idEvent: the queue of the events posted for a later time (<c>PostEventMS</c>), ordered by time and,
  ///   at the same time, by order of posting. <c>ServiceEvents</c> delivers those whose time has come;
  ///   the time is the one of the host. At most DS_MAX_EVENTS events can wait and at most
  ///   DS_MAX_EVENTSPERFRAME are delivered by one call, as in the original.
  /// </summary>
  TDoomScriptEventQueue = class
  strict private
    FHost: IDoomScriptHost;
    FEvents: TDoomScriptEventRegistry;
    FClasses: TDoomScriptClassRegistry;
    FEntities: TDoomScriptEntityTable;
    FQueue: TObjectList<TDoomScriptQueuedEvent>;
    function Alloc(const AEvent: TDoomScriptEventDef; const AArgs: array of TDoomScriptEventArg): TDoomScriptQueuedEvent;
  public
    constructor Create(const AHost: IDoomScriptHost; const AEvents: TDoomScriptEventRegistry;
      const AClasses: TDoomScriptClassRegistry; const AEntities: TDoomScriptEntityTable);
    destructor Destroy; override;
    /// <summary>
    ///   idClass::PostEventMS: queues an event for the target <c>ATime</c> milliseconds from now. False
    ///   (and nothing queued) if the target does not respond to the event. Raises EDoomScriptError for a
    ///   wrong number or type of arguments or a full queue.
    /// </summary>
    function PostEventMS(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef;
      const ATime: Integer; const AArgs: array of TDoomScriptEventArg): Boolean; overload;
    function PostEventMS(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef;
      const ATime: Integer): Boolean; overload;
    /// <summary>idClass::PostEventSec</summary>
    function PostEventSec(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef;
      const ATime: Single; const AArgs: array of TDoomScriptEventArg): Boolean;
    /// <summary>idEvent::CancelEvents: drops the events of a target, all of them or those of one definition</summary>
    procedure CancelEvents(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef = nil);
    /// <summary>idEvent::ClearEventList</summary>
    procedure Clear;
    /// <summary>idEvent::ServiceEvents; raises EDoomScriptError "Event overflow" past the limit of a frame</summary>
    procedure ServiceEvents;
    /// <summary>idEvent::Save. As in the original the string arguments are not written</summary>
    procedure Save(const AStream: TStream; const AWriteObject: TDoomScriptWriteObject);
    /// <summary>idEvent::Restore: appends the saved events to the queue</summary>
    procedure Restore(const AStream: TStream; const AReadObject: TDoomScriptReadObject);
    function Count: Integer;
    function GetEvent(const AIndex: Integer): TDoomScriptQueuedEvent;
  end;

implementation


const
  SNoFreeEvents = 'idEvent::Alloc : No more free events';
  SWrongArgCount = 'idEvent::Alloc : Wrong number of args for ''%s'' event.';
  SWrongArgType = 'idEvent::Alloc : Wrong type passed in for arg # %d on ''%s'' event.';
  SOverflow = 'Event overflow.  Possible infinite loop in script.';
  SRestoreNoFree = 'idEvent::Restore : No more free events';
  SRestoreUnknownEvent = 'idEvent::Restore: unknown event ''%s''';
  SRestoreUnknownClass = 'idEvent::Restore: unknown class ''%s'' on event ''%s''';
  SRestoreArgSize = 'idEvent::Restore: arg size (%d) doesn''t match saved arg size(%d) on event ''%s''';
  SBadIndex = 'idEvent: event %d out of range';

constructor TDoomScriptEventQueue.Create(const AHost: IDoomScriptHost; const AEvents: TDoomScriptEventRegistry;
  const AClasses: TDoomScriptClassRegistry; const AEntities: TDoomScriptEntityTable);
begin
  inherited Create;
  FHost := AHost;
  FEvents := AEvents;
  FClasses := AClasses;
  FEntities := AEntities;
  FQueue := TObjectList<TDoomScriptQueuedEvent>.Create(True);
end;

destructor TDoomScriptEventQueue.Destroy;
begin
  FQueue.Free;
  inherited;
end;

function TDoomScriptEventQueue.Count: Integer;
begin
  Result := FQueue.Count;
end;

function TDoomScriptEventQueue.GetEvent(const AIndex: Integer): TDoomScriptQueuedEvent;
begin
  if (AIndex < 0) or (AIndex >= FQueue.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SBadIndex, [AIndex]);
  Result := FQueue[AIndex];
end;

function TDoomScriptEventQueue.Alloc(const AEvent: TDoomScriptEventDef;
  const AArgs: array of TDoomScriptEventArg): TDoomScriptQueuedEvent;
var
  LIndex: Integer;
  LFormat: AnsiString;
  LKind: AnsiChar;
begin
  if FQueue.Count >= DS_MAX_EVENTS then
    raise EDoomScriptError.Create(SNoFreeEvents);
  if Length(AArgs) <> AEvent.GetNumArgs then
    raise EDoomScriptError.CreateFmt(SWrongArgCount, [string(AEvent.Name)]);
  LFormat := AEvent.ArgFormat;
  Result := TDoomScriptQueuedEvent.Create;
  try
    Result.EventDef := AEvent;
    for LIndex := 0 to Length(AArgs) - 1 do
    begin
      LKind := LFormat[LIndex + 1];
      if LKind <> AArgs[LIndex].Kind then
        // when NULL is passed in for an entity, it gets cast as an integer 0, so no error then
        if not ((LKind in [DS_EVENT_TRACE, DS_EVENT_ENTITY]) and (AArgs[LIndex].Kind = DS_EVENT_INTEGER) and
          (AArgs[LIndex].IntValue = 0)) then
          raise EDoomScriptError.CreateFmt(SWrongArgType, [LIndex, string(AEvent.Name)]);
      Result.Args[LIndex] := AArgs[LIndex];
      Result.Args[LIndex].Kind := LKind;
      if LKind in [DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL] then
      begin
        if AArgs[LIndex].Kind = DS_EVENT_INTEGER then
          Result.Args[LIndex].IntValue := -1;
        Result.EntityTargets[LIndex] := FEntities.TargetOf(Result.Args[LIndex].IntValue);
      end;
      if LKind = DS_EVENT_STRING then
        // idStr::Copynz into MAX_STRING_LEN bytes
        Result.Args[LIndex].StringValue := Copy(AArgs[LIndex].StringValue, 1, DS_MAX_STRING_LEN - 1);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TDoomScriptEventQueue.PostEventMS(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef;
  const ATime: Integer; const AArgs: array of TDoomScriptEventArg): Boolean;
var
  LEvent: TDoomScriptQueuedEvent;
  LIndex: Integer;
begin
  if not ATarget.RespondsTo(AEvent) then
    // we don't respond to this event, so ignore it
    Exit(False);
  LEvent := Alloc(AEvent, AArgs);
  // idEvent::Schedule
  LEvent.Target := ATarget;
  LEvent.TargetClass := ATarget.EventClass;
  LEvent.Time := FHost.GetTime + ATime;
  LIndex := 0;
  while (LIndex < FQueue.Count) and (LEvent.Time >= FQueue[LIndex].Time) do
    Inc(LIndex);
  FQueue.Insert(LIndex, LEvent);
  Result := True;
end;

function TDoomScriptEventQueue.PostEventMS(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef;
  const ATime: Integer): Boolean;
begin
  Result := PostEventMS(ATarget, AEvent, ATime, []);
end;

function TDoomScriptEventQueue.PostEventSec(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef;
  const ATime: Single; const AArgs: array of TDoomScriptEventArg): Boolean;
begin
  Result := PostEventMS(ATarget, AEvent, TDoomScriptConvert.SecToMs(ATime), AArgs);
end;

procedure TDoomScriptEventQueue.CancelEvents(const ATarget: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef);
var
  LIndex: Integer;
begin
  for LIndex := FQueue.Count - 1 downto 0 do
    if (FQueue[LIndex].Target = ATarget) and ((not Assigned(AEvent)) or (AEvent = FQueue[LIndex].EventDef)) then
      FQueue.Delete(LIndex);
end;

procedure TDoomScriptEventQueue.Clear;
begin
  FQueue.Clear;
end;

procedure TDoomScriptEventQueue.ServiceEvents;
var
  LEvent: TDoomScriptQueuedEvent;
  LCount: Integer;
  LIndex: Integer;
begin
  LCount := 0;
  while FQueue.Count > 0 do
  begin
    if FQueue[0].Time > FHost.GetTime then
      Break;
    // the event leaves the queue first, so that if the object is deleted the event isn't freed twice
    LEvent := FQueue.Extract(FQueue[0]);
    try
      // an entity that was removed after the event was posted is delivered as no entity
      for LIndex := 0 to LEvent.EventDef.GetNumArgs - 1 do
        if (LEvent.Args[LIndex].Kind in [DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL]) and
          ((not Assigned(LEvent.EntityTargets[LIndex])) or
          (FEntities.TargetOf(LEvent.Args[LIndex].IntValue) <> LEvent.EntityTargets[LIndex])) then
          LEvent.Args[LIndex].IntValue := -1;
      LEvent.Target.ProcessEvent(LEvent.EventDef, LEvent.Args);
    finally
      LEvent.Free;
    end;
    // an abnormally high number of events being processed is evidence of an infinite loop of events
    Inc(LCount);
    if LCount > DS_MAX_EVENTSPERFRAME then
      raise EDoomScriptError.Create(SOverflow);
  end;
end;

procedure TDoomScriptEventQueue.Save(const AStream: TStream; const AWriteObject: TDoomScriptWriteObject);
var
  LIndex: Integer;
  LArg: Integer;
  LEvent: TDoomScriptQueuedEvent;
begin
  TDoomScriptSaveStream.WriteInt(AStream, FQueue.Count);
  for LIndex := 0 to FQueue.Count - 1 do
  begin
    LEvent := FQueue[LIndex];
    TDoomScriptSaveStream.WriteInt(AStream, LEvent.Time);
    TDoomScriptSaveStream.WriteString(AStream, LEvent.EventDef.Name);
    TDoomScriptSaveStream.WriteString(AStream, LEvent.TargetClass.Name);
    AWriteObject(AStream, LEvent.Target);
    TDoomScriptSaveStream.WriteInt(AStream, LEvent.EventDef.ArgSize);
    for LArg := 0 to LEvent.EventDef.GetNumArgs - 1 do
      case LEvent.Args[LArg].Kind of
        DS_EVENT_FLOAT:
          TDoomScriptSaveStream.WriteFloat(AStream, LEvent.Args[LArg].FloatValue);
        DS_EVENT_INTEGER:
          TDoomScriptSaveStream.WriteInt(AStream, LEvent.Args[LArg].IntValue);
        DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
          // the entity handle plus one, zero for none
          TDoomScriptSaveStream.WriteInt(AStream, LEvent.Args[LArg].IntValue + 1);
        DS_EVENT_VECTOR:
          TDoomScriptSaveStream.WriteVec3(AStream, LEvent.Args[LArg].VectorValue);
        // a string is not written (a defect of the original); a trace cannot be posted here
      end;
  end;
end;

procedure TDoomScriptEventQueue.Restore(const AStream: TStream; const AReadObject: TDoomScriptReadObject);
var
  LCount: Integer;
  LIndex: Integer;
  LArg: Integer;
  LName: AnsiString;
  LEvent: TDoomScriptQueuedEvent;
  LObject: TObject;
  LArgSize: Integer;
  LFormat: AnsiString;
begin
  LCount := TDoomScriptSaveStream.ReadInt(AStream);
  for LIndex := 0 to LCount - 1 do
  begin
    if FQueue.Count >= DS_MAX_EVENTS then
      raise EDoomScriptError.Create(SRestoreNoFree);
    LEvent := TDoomScriptQueuedEvent.Create;
    try
      LEvent.Time := TDoomScriptSaveStream.ReadInt(AStream);
      // read the event name
      LName := TDoomScriptSaveStream.ReadString(AStream);
      LEvent.EventDef := FEvents.FindEvent(LName);
      if not Assigned(LEvent.EventDef) then
        raise EDoomScriptError.CreateFmt(SRestoreUnknownEvent, [string(LName)]);
      // read the classtype
      LName := TDoomScriptSaveStream.ReadString(AStream);
      LEvent.TargetClass := FClasses.GetClass(LName);
      if not Assigned(LEvent.TargetClass) then
        raise EDoomScriptError.CreateFmt(SRestoreUnknownClass, [string(LName), string(LEvent.EventDef.Name)]);
      LObject := AReadObject(AStream);
      if not (LObject is TDoomScriptEventTarget) then
        raise EDoomScriptError.CreateFmt(SRestoreUnknownClass, [string(LName), string(LEvent.EventDef.Name)]);
      LEvent.Target := TDoomScriptEventTarget(LObject);
      // read the args
      LArgSize := TDoomScriptSaveStream.ReadInt(AStream);
      if LArgSize <> LEvent.EventDef.ArgSize then
        raise EDoomScriptError.CreateFmt(SRestoreArgSize, [LEvent.EventDef.ArgSize, LArgSize,
          string(LEvent.EventDef.Name)]);
      LFormat := LEvent.EventDef.ArgFormat;
      for LArg := 0 to Length(LFormat) - 1 do
      begin
        LEvent.Args[LArg].Kind := LFormat[LArg + 1];
        case LFormat[LArg + 1] of
          DS_EVENT_FLOAT:
            LEvent.Args[LArg].FloatValue := TDoomScriptSaveStream.ReadFloat(AStream);
          DS_EVENT_INTEGER:
            LEvent.Args[LArg].IntValue := TDoomScriptSaveStream.ReadInt(AStream);
          DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
            begin
              LEvent.Args[LArg].IntValue := TDoomScriptSaveStream.ReadInt(AStream) - 1;
              LEvent.EntityTargets[LArg] := FEntities.TargetOf(LEvent.Args[LArg].IntValue);
            end;
          DS_EVENT_VECTOR:
            LEvent.Args[LArg].VectorValue := TDoomScriptSaveStream.ReadVec3(AStream);
        end;
      end;
    except
      LEvent.Free;
      raise;
    end;
    FQueue.Add(LEvent);
  end;
end;

end.
