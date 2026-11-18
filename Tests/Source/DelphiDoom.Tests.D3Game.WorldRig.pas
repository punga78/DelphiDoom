{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - a game with the entity       }
{  classes (triggers, movers) on fakes: a time-sorted event queue, the script   }
{  threads, the fake world and the game                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.WorldRig;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Scanner.IdDict,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry,
  DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Local, DelphiDoom.Tests.D3Game.World;

type
  /// <summary>An event waiting in the fake queue</summary>
  TD3FakeQueuedEvent = record
    Target: TObject;
    Event: TDoomScriptEventDef;
    Time: Integer;
    Args: TDoomScriptEventArgs;
    Pointers: array[0..DS_EVENT_MAXARGS - 1] of TD3EntityPtr;
  end;

  /// <summary>
  ///   <c>idEvent</c> for the tests: events sorted by time (an event goes after the ones due at the same time),
  ///   delivered by <c>ServiceEvents</c> when the game time reaches them; entity arguments are kept as entity
  ///   pointers and delivered as no entity if the entity is gone. The same rules as the queue of the C++ harness
  ///   (<c>Tools\Verifica\255\harness_world.cpp</c>).
  /// </summary>
  TD3FakeEventQueue = class(TObject, IInterface, ID3EventQueue, ID3EventCanceller)
  strict private
    FItems: TList<TD3FakeQueuedEvent>;
    FGame: TD3GameLocal;
  protected
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Attach(const AGame: TD3GameLocal);
    procedure PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ATime: Integer;
      const AArgs: array of TDoomScriptEventArg);
    procedure PostEventSec(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ASeconds: Single;
      const AArgs: array of TDoomScriptEventArg);
    procedure CancelEvent(const AObject: TObject; const AEvent: TDoomScriptEventDef);
    procedure CancelEvents(const AObject: TObject);
    /// <summary>idEvent::ServiceEvents</summary>
    procedure ServiceEvents;
    function Count: Integer;
    /// <summary>"name@time" of every pending event, in order</summary>
    function Pending: string;
  end;

  /// <summary>The thread an event handler runs in: the values it returns and the moves that finished</summary>
  TD3FakeThreads = class(TObject, IInterface, ID3ScriptThreads)
  protected
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    Returned: TStringList;
    MoveDone: TStringList;
    Current: Integer;
    /// <summary>Every call is also written here in the format of the C++ harness (may be nil)</summary>
    Sink: TProc<string>;
    constructor Create;
    destructor Destroy; override;
    procedure ReturnFloat(const AValue: Single);
    procedure ReturnInteger(const AValue: Integer);
    procedure ReturnString(const AText: AnsiString);
    procedure ReturnEntity(const AEntityNumber: Integer);
    function CurrentThreadNum: Integer;
    procedure ObjectMoveDone(const AThreadNum, AEntityNumber: Integer);
  end;

  /// <summary>
  ///   An entity that writes down what happens to it: <c>ACTIVATE name by activator</c> for the <c>activate</c> event
  ///   and <c>DAMAGE name def</c> for a damage
  /// </summary>
  TD3RecorderEntity = class(TD3Entity)
  public
    Log: TStringList;
    Sink: TProc<string>;
    procedure Damage(const ADamageDefName: AnsiString; const AScale: Single); override;
  end;

  /// <summary>
  ///   A game with the entity classes of the library declared and every service on a fake: entityDefs and script
  ///   functions of the fake world, the fake event queue and threads. <c>Frame</c> runs a frame of the game (think and
  ///   events). Defs are added with <c>World.AddDef</c>, entities spawned with <c>Spawn</c>.
  /// </summary>
  TD3WorldRig = class
  strict private
    FWorld: TD3GameFakeWorld;
    FEvents: TDoomScriptEventRegistry;
    FEntityEvents: TD3EntityEvents;
    FQueue: TD3FakeEventQueue;
    FThreads: TD3FakeThreads;
    FClasses: TD3ClassSystem;
    FGame: TD3GameLocal;
    FLog: TStringList;
    procedure DeclareRecorder;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>What the entities of class idRecorder wrote down</summary>
    property Log: TStringList read FLog;
    /// <summary>Spawns an entity from key/value pairs (classname first); nil if nothing was made</summary>
    function Spawn(const AKeysAndValues: array of AnsiString): TD3Entity;
    /// <summary>A frame of the game: the time moves, the entities think, the events due are served</summary>
    procedure Frame(const ACount: Integer = 1);
    /// <summary>Frames until the game time is at least this one</summary>
    procedure RunUntil(const ATime: Integer);
    property World: TD3GameFakeWorld read FWorld;
    property Events: TDoomScriptEventRegistry read FEvents;
    property EntityEvents: TD3EntityEvents read FEntityEvents;
    property Queue: TD3FakeEventQueue read FQueue;
    property Threads: TD3FakeThreads read FThreads;
    property Classes: TD3ClassSystem read FClasses;
    property Game: TD3GameLocal read FGame;
  end;

implementation

uses
  DelphiDoom.D3Game.Types, DelphiDoom.D3Game.WorldClasses;

{ TD3FakeEventQueue }

constructor TD3FakeEventQueue.Create;
begin
  inherited Create;
  FItems := TList<TD3FakeQueuedEvent>.Create;
end;

destructor TD3FakeEventQueue.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TD3FakeEventQueue.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TD3FakeEventQueue._AddRef: Integer;
begin
  Result := -1;
end;

function TD3FakeEventQueue._Release: Integer;
begin
  Result := -1;
end;

procedure TD3FakeEventQueue.Attach(const AGame: TD3GameLocal);
begin
  FGame := AGame;
end;

procedure TD3FakeEventQueue.PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef;
  const ATime: Integer; const AArgs: array of TDoomScriptEventArg);
var
  LItem: TD3FakeQueuedEvent;
  LIndex: Integer;
begin
  if not TD3Class(AObject).RespondsTo(AEvent) then
    // we don't respond to this event, so ignore it
    Exit;
  LItem := Default(TD3FakeQueuedEvent);
  LItem.Target := AObject;
  LItem.Event := AEvent;
  LItem.Time := FGame.Time + ATime;
  for LIndex := 0 to High(AArgs) do
  begin
    LItem.Args[LIndex] := AArgs[LIndex];
    if AEvent.ArgFormat[LIndex + 1] = DS_EVENT_ENTITY then
      LItem.Pointers[LIndex] := TD3EntityPtr.Make(FGame, FGame.Entities[AArgs[LIndex].IntValue]);
  end;
  LIndex := 0;
  while (LIndex < FItems.Count) and (LItem.Time >= FItems[LIndex].Time) do
    Inc(LIndex);
  FItems.Insert(LIndex, LItem);
end;

procedure TD3FakeEventQueue.PostEventSec(const AObject: TObject; const AEvent: TDoomScriptEventDef;
  const ASeconds: Single; const AArgs: array of TDoomScriptEventArg);
begin
  PostEventMS(AObject, AEvent, TDoomScriptConvert.SecToMs(ASeconds), AArgs);
end;

procedure TD3FakeEventQueue.CancelEvent(const AObject: TObject; const AEvent: TDoomScriptEventDef);
var
  LIndex: Integer;
begin
  for LIndex := FItems.Count - 1 downto 0 do
    if (FItems[LIndex].Target = AObject) and (FItems[LIndex].Event = AEvent) then
      FItems.Delete(LIndex);
end;

procedure TD3FakeEventQueue.CancelEvents(const AObject: TObject);
var
  LIndex: Integer;
begin
  for LIndex := FItems.Count - 1 downto 0 do
    if FItems[LIndex].Target = AObject then
      FItems.Delete(LIndex);
end;

procedure TD3FakeEventQueue.ServiceEvents;
var
  LItem: TD3FakeQueuedEvent;
  LIndex: Integer;
  LEntity: TD3Entity;
begin
  while (FItems.Count > 0) and (FItems[0].Time <= FGame.Time) do
  begin
    LItem := FItems[0];
    FItems.Delete(0);
    // an entity that was removed after the event was posted is delivered as no entity
    for LIndex := 0 to LItem.Event.GetNumArgs - 1 do
      if LItem.Event.ArgFormat[LIndex + 1] = DS_EVENT_ENTITY then
      begin
        LEntity := LItem.Pointers[LIndex].GetEntity(FGame);
        if Assigned(LEntity) then
          LItem.Args[LIndex].IntValue := LEntity.EntityNumber
        else
          LItem.Args[LIndex].IntValue := -1;
      end;
    TD3Class(LItem.Target).ProcessEvent(LItem.Event, LItem.Args);
  end;
end;

function TD3FakeEventQueue.Count: Integer;
begin
  Result := FItems.Count;
end;

function TD3FakeEventQueue.Pending: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FItems.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + string(FItems[LIndex].Event.Name) + '@' + IntToStr(FItems[LIndex].Time);
  end;
end;

{ TD3FakeThreads }

constructor TD3FakeThreads.Create;
begin
  inherited Create;
  Returned := TStringList.Create;
  MoveDone := TStringList.Create;
end;

destructor TD3FakeThreads.Destroy;
begin
  MoveDone.Free;
  Returned.Free;
  inherited Destroy;
end;

function TD3FakeThreads.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TD3FakeThreads._AddRef: Integer;
begin
  Result := -1;
end;

function TD3FakeThreads._Release: Integer;
begin
  Result := -1;
end;

procedure TD3FakeThreads.ReturnFloat(const AValue: Single);
begin
  Returned.Add('f ' + FloatToStr(AValue, TFormatSettings.Invariant));
  if Assigned(Sink) then
    Sink('RETURN f ' + IntToHex(PCardinal(@AValue)^, 8));
end;

procedure TD3FakeThreads.ReturnInteger(const AValue: Integer);
begin
  Returned.Add('d ' + IntToStr(AValue));
  if Assigned(Sink) then
    Sink('RETURN d ' + IntToStr(AValue));
end;

procedure TD3FakeThreads.ReturnString(const AText: AnsiString);
begin
  Returned.Add('s ' + string(AText));
  if Assigned(Sink) then
    Sink('RETURN s ' + string(AText));
end;

procedure TD3FakeThreads.ReturnEntity(const AEntityNumber: Integer);
begin
  Returned.Add('e ' + IntToStr(AEntityNumber));
end;

function TD3FakeThreads.CurrentThreadNum: Integer;
begin
  Result := Current;
end;

procedure TD3FakeThreads.ObjectMoveDone(const AThreadNum, AEntityNumber: Integer);
begin
  MoveDone.Add(Format('%d %d', [AThreadNum, AEntityNumber]));
  if Assigned(Sink) then
    Sink(Format('CALL idThread.ObjectMoveDone %d %d', [AThreadNum, AEntityNumber]));
end;

{ TD3WorldRig }

constructor TD3WorldRig.Create;
var
  LServices: TD3GameServices;
begin
  inherited Create;
  LServices := Default(TD3GameServices);
  FWorld := TD3GameFakeWorld.Create;
  FWorld.Quiet := True;
  FEvents := TDoomScriptEventRegistry.Create;
  FEntityEvents := TD3EntityEvents.Create(FEvents);
  FQueue := TD3FakeEventQueue.Create;
  FThreads := TD3FakeThreads.Create;
  FClasses := TD3ClassSystem.Create(FWorld, FEvents, FWorld);
  LServices.Printer := FWorld;
  LServices.EntityDefs := FWorld;
  LServices.SpawnFunctions := FWorld;
  LServices.ScriptNames := FWorld;
  LServices.Settings := FWorld;
  LServices.MapSteps := FWorld;
  LServices.EventCanceller := FQueue;
  LServices.EntityObserver := nil;
  LServices.Events := FEntityEvents;
  LServices.EventQueue := FQueue;
  LServices.ScriptFunctions := FWorld;
  LServices.ScriptThreads := FThreads;
  FGame := TD3GameLocal.Create(LServices, FClasses);
  FQueue.Attach(FGame);
  FLog := TStringList.Create;
  TD3WorldClasses.Declare(FClasses, FEntityEvents, FGame);
  DeclareRecorder;
  FClasses.Init;
  FGame.NewMap;
  FWorld.Quiet := False;
  FWorld.Trace.Clear;
  // MapPopulate would end the startup of the map: the entities of a test are spawned into a running game
  FGame.EndStartup;
  FThreads.Sink :=
    procedure(AText: string)
    begin
      FWorld.Line(AText);
    end;
end;

destructor TD3WorldRig.Destroy;
begin
  FGame.Free;
  FLog.Free;
  FClasses.Free;
  FThreads.Free;
  FQueue.Free;
  FEntityEvents.Free;
  FEvents.Free;
  FWorld.Free;
  inherited Destroy;
end;

procedure TD3RecorderEntity.Damage(const ADamageDefName: AnsiString; const AScale: Single);
begin
  Log.Add('DAMAGE ' + string(GetName) + ' ' + string(ADamageDefName));
  if Assigned(Sink) then
    Sink(Log[Log.Count - 1]);
end;

procedure TD3WorldRig.DeclareRecorder;
var
  LGame: TD3GameLocal;
  LLog: TStringList;
  LWorld: TD3GameFakeWorld;
  LSink: TProc<string>;
  LType: TD3TypeInfo;
begin
  LGame := FGame;
  LLog := FLog;
  LWorld := FWorld;
  LSink :=
    procedure(AText: string)
    begin
      LWorld.Line(AText);
    end;
  LType := FClasses.Declare('idRecorder', 'idEntity',
    function: TD3Class
    begin
      Result := TD3RecorderEntity.Create(LGame, LGame);
      TD3RecorderEntity(Result).Log := LLog;
      TD3RecorderEntity(Result).Sink := LSink;
    end, TD3Entity.SpawnClass);
  LType.AddEvent(FEntityEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LActivator: TD3Entity;
      LName: string;
    begin
      LActivator := TD3Entity(ATarget).EntityFromArg(AArgs[0]);
      if Assigned(LActivator) then
        LName := string(LActivator.GetName)
      else
        LName := '(none)';
      LLog.Add('ACTIVATE ' + string(TD3Entity(ATarget).GetName) + ' by ' + LName + ' t=' + IntToStr(LGame.Time));
      LWorld.Line(LLog[LLog.Count - 1]);
    end);
end;

function TD3WorldRig.Spawn(const AKeysAndValues: array of AnsiString): TD3Entity;
var
  LArgs: TIdDict;
  LIndex: Integer;
begin
  LArgs := TIdDict.Create;
  try
    LIndex := 0;
    while LIndex + 1 <= High(AKeysAndValues) do
    begin
      LArgs.SetValue(AKeysAndValues[LIndex], AKeysAndValues[LIndex + 1]);
      Inc(LIndex, 2);
    end;
    if not FGame.SpawnEntityDef(LArgs, Result) then
      Result := nil;
  finally
    LArgs.Free;
  end;
end;

procedure TD3WorldRig.Frame(const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FGame.RunFrameThink;
    FQueue.ServiceEvents;
  end;
end;

procedure TD3WorldRig.RunUntil(const ATime: Integer);
begin
  while FGame.Time < ATime do
    Frame;
end;

end.
