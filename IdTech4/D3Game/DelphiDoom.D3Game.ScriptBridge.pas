{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the game seen by the script machine       }
{                                                                              }
{  Written for this repository. In the original the script system and the      }
{  game share the globals (gameLocal.entities, gameLocal.program, idEvent):    }
{  here this class is the one place where the two libraries meet.              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.ScriptBridge;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.Machine,
  DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Local;

type
  /// <summary>
  ///   What connects the game to a script machine: the entities of the game are the entities the scripts name
  ///   (<c>$door1</c>, <c>sys.getEntity</c>), the events of their classes are the events a script sends them
  ///   (<c>$door1.open()</c>), the entityDefs' <c>spawnfunc</c> starts a script function, <c>MapPopulate</c> serves the
  ///   pending events and the events of an object that goes away are cancelled. It implements the interfaces that the
  ///   game takes (<c>ID3ScriptNames</c>, <c>ID3EntityObserver</c>, <c>ID3SpawnFunctions</c>, <c>ID3MapSteps</c>,
  ///   <c>ID3EventCanceller</c>, <c>ID3EventPoster</c>) without reference counting: the owner of the bridge keeps it
  ///   alive as long as the game and the machine are.
  ///   <para>Create it first, give its interfaces to the game's services, create the game, then <c>Attach</c> the game
  ///   and, once every class is declared, <c>BindClasses</c> (it declares the classes of the game in the machine
  ///   with the same names and superclasses and gives them the handlers of their <c>EVENT</c> lines).</para>
  /// </summary>
  TD3ScriptBridge = class(TObject, IInterface, ID3ScriptNames, ID3EntityObserver, ID3SpawnFunctions, ID3MapSteps,
    ID3EventCanceller, ID3EventPoster, ID3EventQueue, ID3ScriptFunctions, ID3ScriptThreads)
  strict private
    FMachine: TDoomScriptMachine;
    FGame: TD3GameLocal;
    FTargets: TObjectList<TDoomScriptEventTarget>;
    FObjectByTarget: TDictionary<TObject, TD3Class>;
    FTargetByObject: TDictionary<TObject, TDoomScriptEventTarget>;
    FTargetByNumber: TDictionary<Integer, TDoomScriptEventTarget>;
    function MakeHandler(const AHandler: TD3EventHandler): TDoomScriptEventHandler;
    function EnsureScriptClass(const AType: TD3TypeInfo): TDoomScriptClassInfo;
  protected
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(const AMachine: TDoomScriptMachine);
    destructor Destroy; override;
    /// <summary>The game whose entities the scripts see (<c>Game.SpawnIds</c> gives the spawn ids)</summary>
    procedure Attach(const AGame: TD3GameLocal);
    /// <summary>
    ///   Declares in the machine every class of the game that it does not know, superclass first, with the handlers of
    ///   the <c>EVENT</c> lines of the classes (a script event reaches the object of the game)
    /// </summary>
    procedure BindClasses(const AClasses: TD3ClassSystem);
    { ID3ScriptNames }
    procedure SetEntity(const AName: AnsiString; const AEntityNumber: Integer);
    { ID3EntityObserver }
    procedure EntityRegistered(const AEntity: TObject; const AEntityNumber: Integer);
    procedure EntityUnregistered(const AEntityNumber: Integer);
    { ID3SpawnFunctions }
    function StartSpawnFunction(const AName: AnsiString): Boolean;
    { ID3MapSteps: only the service of the events is done; the others are not ported }
    procedure SetSkill(const ASkill: Integer);
    procedure CacheDictionaryMedia(const ADict: TIdDict);
    procedure SpreadLocations;
    procedure RandomizeInitialSpawns;
    procedure SetSkipSpecular(const AValue: Boolean);
    procedure ServiceEvents;
    { ID3EventCanceller }
    procedure CancelEvents(const AObject: TObject);
    { ID3EventPoster }
    procedure PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ATime: Integer); overload;
    { ID3EventQueue }
    procedure PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ATime: Integer;
      const AArgs: array of TDoomScriptEventArg); overload;
    procedure PostEventSec(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ASeconds: Single;
      const AArgs: array of TDoomScriptEventArg);
    procedure CancelEvent(const AObject: TObject; const AEvent: TDoomScriptEventDef);
    { ID3ScriptFunctions }
    function HasFunction(const AName: AnsiString): Boolean;
    { ID3ScriptThreads }
    procedure ReturnFloat(const AValue: Single);
    procedure ReturnInteger(const AValue: Integer);
    procedure ReturnString(const AText: AnsiString);
    procedure ReturnEntity(const AEntityNumber: Integer);
    function CurrentThreadNum: Integer;
    procedure ObjectMoveDone(const AThreadNum, AEntityNumber: Integer);
  end;

implementation

uses
  DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.Thread, DelphiDoom.D3Game.Entity;

constructor TD3ScriptBridge.Create(const AMachine: TDoomScriptMachine);
begin
  inherited Create;
  FMachine := AMachine;
  FTargets := TObjectList<TDoomScriptEventTarget>.Create(True);
  FObjectByTarget := TDictionary<TObject, TD3Class>.Create;
  FTargetByObject := TDictionary<TObject, TDoomScriptEventTarget>.Create;
  FTargetByNumber := TDictionary<Integer, TDoomScriptEventTarget>.Create;
end;

destructor TD3ScriptBridge.Destroy;
begin
  FTargetByNumber.Free;
  FTargetByObject.Free;
  FObjectByTarget.Free;
  FTargets.Free;
  inherited Destroy;
end;

function TD3ScriptBridge.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TD3ScriptBridge._AddRef: Integer;
begin
  Result := -1;
end;

function TD3ScriptBridge._Release: Integer;
begin
  Result := -1;
end;

procedure TD3ScriptBridge.Attach(const AGame: TD3GameLocal);
begin
  FGame := AGame;
end;

function TD3ScriptBridge.MakeHandler(const AHandler: TD3EventHandler): TDoomScriptEventHandler;
begin
  Result :=
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LObject: TD3Class;
    begin
      if FObjectByTarget.TryGetValue(ATarget, LObject) then
        AHandler(LObject, AEvent, AArgs);
    end;
end;

function TD3ScriptBridge.EnsureScriptClass(const AType: TD3TypeInfo): TDoomScriptClassInfo;
var
  LIndex: Integer;
  LSuperName: AnsiString;
  LBinding: TD3EventBinding;
begin
  Result := FMachine.Classes.GetClass(AType.Name);
  if Assigned(Result) then
    Exit;
  LSuperName := '';
  if Assigned(AType.Super) then
  begin
    EnsureScriptClass(AType.Super);
    LSuperName := AType.Super.Name;
  end;
  Result := FMachine.Classes.Declare(AType.Name, LSuperName);
  for LIndex := 0 to AType.EventBindingCount - 1 do
  begin
    LBinding := AType.EventBindingAt(LIndex);
    Result.AddEvent(LBinding.Event, MakeHandler(LBinding.Handler));
  end;
end;

procedure TD3ScriptBridge.BindClasses(const AClasses: TD3ClassSystem);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AClasses.DeclaredCount - 1 do
    EnsureScriptClass(AClasses.DeclaredClass(LIndex));
end;

procedure TD3ScriptBridge.SetEntity(const AName: AnsiString; const AEntityNumber: Integer);
begin
  // gameLocal.program.SetEntity( name, ent ); the script table learns the name of the entity too
  FMachine.ScriptProgram.SetEntity(AName, AEntityNumber);
  if (AEntityNumber >= 0) and FMachine.Entities.Exists(AEntityNumber) then
    FMachine.Entities.Rename(AEntityNumber, AName);
end;

procedure TD3ScriptBridge.EntityRegistered(const AEntity: TObject; const AEntityNumber: Integer);
var
  LInfo: TDoomScriptClassInfo;
  LTarget: TDoomScriptEventTarget;
begin
  LInfo := FMachine.Classes.GetClass(TD3Entity(AEntity).GetType.Name);
  if not Assigned(LInfo) then
    Exit;
  LTarget := TDoomScriptEventTarget.Create(LInfo);
  FTargets.Add(LTarget);
  FObjectByTarget.Add(LTarget, TD3Entity(AEntity));
  FTargetByObject.Add(AEntity, LTarget);
  FTargetByNumber.AddOrSetValue(AEntityNumber, LTarget);
  // the script table numbers the spawns as the game does
  FMachine.Entities.SpawnCount := FGame.SpawnIds[AEntityNumber];
  FMachine.Entities.Add(AEntityNumber, LTarget, '');
end;

procedure TD3ScriptBridge.EntityUnregistered(const AEntityNumber: Integer);
var
  LTarget: TDoomScriptEventTarget;
begin
  if not FTargetByNumber.TryGetValue(AEntityNumber, LTarget) then
    Exit;
  // the events posted for the entity go with it (the destructor of idClass)
  FMachine.Queue.CancelEvents(LTarget);
  FMachine.Entities.Remove(AEntityNumber);
  FTargetByNumber.Remove(AEntityNumber);
  FTargetByObject.Remove(FObjectByTarget[LTarget]);
  FObjectByTarget.Remove(LTarget);
  FTargets.Remove(LTarget);
end;

function TD3ScriptBridge.StartSpawnFunction(const AName: AnsiString): Boolean;
var
  LFunction: TDoomScriptFunction;
begin
  LFunction := FMachine.ScriptProgram.FindFunction(AName);
  Result := Assigned(LFunction);
  if Result then
    // idThread *thread = new idThread( func ); thread->DelayedStart( 0 );
    FMachine.CreateThread(LFunction).DelayedStart(0);
end;

procedure TD3ScriptBridge.SetSkill(const ASkill: Integer);
begin
end;

procedure TD3ScriptBridge.CacheDictionaryMedia(const ADict: TIdDict);
begin
end;

procedure TD3ScriptBridge.SpreadLocations;
begin
end;

procedure TD3ScriptBridge.RandomizeInitialSpawns;
begin
end;

procedure TD3ScriptBridge.SetSkipSpecular(const AValue: Boolean);
begin
end;

procedure TD3ScriptBridge.ServiceEvents;
begin
  FMachine.ServiceEvents;
end;

procedure TD3ScriptBridge.CancelEvents(const AObject: TObject);
var
  LTarget: TDoomScriptEventTarget;
begin
  if FTargetByObject.TryGetValue(AObject, LTarget) then
    FMachine.Queue.CancelEvents(LTarget);
end;

procedure TD3ScriptBridge.PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef;
  const ATime: Integer);
var
  LTarget: TDoomScriptEventTarget;
begin
  if FTargetByObject.TryGetValue(AObject, LTarget) then
    FMachine.Queue.PostEventMS(LTarget, AEvent, ATime);
end;

procedure TD3ScriptBridge.PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef;
  const ATime: Integer; const AArgs: array of TDoomScriptEventArg);
var
  LTarget: TDoomScriptEventTarget;
begin
  if FTargetByObject.TryGetValue(AObject, LTarget) then
    FMachine.Queue.PostEventMS(LTarget, AEvent, ATime, AArgs);
end;

procedure TD3ScriptBridge.PostEventSec(const AObject: TObject; const AEvent: TDoomScriptEventDef;
  const ASeconds: Single; const AArgs: array of TDoomScriptEventArg);
var
  LTarget: TDoomScriptEventTarget;
begin
  if FTargetByObject.TryGetValue(AObject, LTarget) then
    FMachine.Queue.PostEventSec(LTarget, AEvent, ASeconds, AArgs);
end;

procedure TD3ScriptBridge.CancelEvent(const AObject: TObject; const AEvent: TDoomScriptEventDef);
var
  LTarget: TDoomScriptEventTarget;
begin
  if FTargetByObject.TryGetValue(AObject, LTarget) then
    FMachine.Queue.CancelEvents(LTarget, AEvent);
end;

function TD3ScriptBridge.HasFunction(const AName: AnsiString): Boolean;
begin
  Result := Assigned(FMachine.ScriptProgram.FindFunction(AName));
end;

procedure TD3ScriptBridge.ReturnFloat(const AValue: Single);
begin
  FMachine.ScriptProgram.ReturnFloat(AValue);
end;

procedure TD3ScriptBridge.ReturnInteger(const AValue: Integer);
begin
  // idThread::ReturnInt writes a float: the language has no integers
  FMachine.ScriptProgram.ReturnFloat(AValue);
end;

procedure TD3ScriptBridge.ReturnString(const AText: AnsiString);
begin
  FMachine.ScriptProgram.ReturnString(AText);
end;

procedure TD3ScriptBridge.ReturnEntity(const AEntityNumber: Integer);
begin
  FMachine.ScriptProgram.ReturnEntity(AEntityNumber);
end;

function TD3ScriptBridge.CurrentThreadNum: Integer;
begin
  Result := TDoomScriptThread.CurrentThreadNum(FMachine.Context);
end;

procedure TD3ScriptBridge.ObjectMoveDone(const AThreadNum, AEntityNumber: Integer);
begin
  TDoomScriptThread.ObjectMoveDone(FMachine.Context, AThreadNum, AEntityNumber);
end;

end.
