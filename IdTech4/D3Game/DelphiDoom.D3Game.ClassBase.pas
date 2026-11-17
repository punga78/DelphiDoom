{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idClass and idTypeInfo                    }
{                                                                              }
{  Port of Doom 3 (id Software): game\gamesys\Class.h, Class.cpp              }
{  (idClass, idTypeInfo: the classes that Class.h declares together).          }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.ClassBase;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Containers.Hierarchy, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.Intf;

type
  TD3Class = class;
  TD3TypeInfo = class;

  /// <summary>
  ///   The <c>Spawn</c> member function of a class (<c>classSpawnFunc_t</c>). A class that has no spawn function of its
  ///   own gives the one of its superclass (a static <c>class procedure</c>, so that two classes can be told to share
  ///   it): <c>CallSpawn</c> does not call the same function twice in a row.
  /// </summary>
  TD3SpawnProc = procedure(const AInstance: TD3Class);

  /// <summary>The <c>CreateInstance</c> of a class: a new object (<c>new nameofclass</c>)</summary>
  TD3InstanceFactory = reference to function: TD3Class;

  /// <summary>
  ///   The code an object runs for an event (<c>eventCallback_t</c>): the object and the event with its arguments,
  ///   the same call that the script system makes
  /// </summary>
  TD3EventHandler = reference to procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef;
    const AArgs: TDoomScriptEventArgs);

  /// <summary>One <c>EVENT( ev, function )</c> line of a class declaration</summary>
  TD3EventBinding = record
    Event: TDoomScriptEventDef;
    Handler: TD3EventHandler;
  end;

  /// <summary>
  ///   The table of fast lookups of a class (<c>eventMap</c>): a handler for every event number, or none. A class
  ///   that adds no events shares the table of its superclass, so the table is not owned by every class that uses it.
  /// </summary>
  TD3EventMap = class
  strict private
    FHandlers: TArray<TD3EventHandler>;
  public
    constructor Create(const ACount: Integer);
    /// <summary>The handler of an event number; none (nil) for a number that the table does not have</summary>
    function Find(const AEventNum: Integer): TD3EventHandler;
    procedure SetHandler(const AEventNum: Integer; const AHandler: TD3EventHandler);
  end;

  /// <summary>
  ///   idTypeInfo: the description of a class of the game: its name, its superclass, its events, how to make an
  ///   object of it and its spawn function. The class system (<c>TD3ClassSystem</c>) owns the descriptions and
  ///   links them into the hierarchy.
  /// </summary>
  TD3TypeInfo = class
  strict private
    FClassName: AnsiString;
    FSuperclassName: AnsiString;
    FFactory: TD3InstanceFactory;
    FSpawn: TD3SpawnProc;
    FAbstract: Boolean;
    FPrinter: ID3GamePrinter;
    FEventCallbacks: TArray<TD3EventBinding>;
    FEventMap: TD3EventMap;
    FFreeEventMap: Boolean;
    FSuper: TD3TypeInfo;
    FTypeNum: Integer;
    FLastChild: Integer;
    FNode: TIdHierarchy<TD3TypeInfo>;
  public
    /// <param name="AFactory">nil for an abstract class (ABSTRACT_DECLARATION): <c>CreateInstance</c> is an error</param>
    constructor Create(const AClassName, ASuperclassName: AnsiString; const AFactory: TD3InstanceFactory;
      const ASpawn: TD3SpawnProc; const AAbstract: Boolean; const APrinter: ID3GamePrinter);
    destructor Destroy; override;
    /// <summary>One <c>EVENT( ev, function )</c> of the declaration; call it before the class system is initialized</summary>
    procedure AddEvent(const AEvent: TDoomScriptEventDef; const AHandler: TD3EventHandler);
    /// <summary>
    ///   idTypeInfo::Init: the event table of the class (the handlers of the superclasses, replaced by the ones of the
    ///   class), the place in the hierarchy and the count of the children of every ancestor. The superclass goes first.
    /// </summary>
    /// <param name="ARoot">the node that the classes without a superclass hang from (<c>classHierarchy</c>)</param>
    /// <param name="ANumEvents">idEventDef::NumEventCommands</param>
    /// <param name="AEventCallbackMemory">bytes of event tables, added to by every table that is made</param>
    procedure Init(const ARoot: TIdHierarchy<TD3TypeInfo>; const ANumEvents: Integer;
      var AEventCallbackMemory: Integer);
    /// <summary>
    ///   idTypeInfo::Shutdown: frees the event table the class made. The node and the freeEventMap flag stay as
    ///   they are (as in the original), so a second <c>Init</c> starts from the old tree.
    /// </summary>
    procedure Shutdown;
    /// <summary>idTypeInfo::IsType: the number of this class is in the range that the other class covers</summary>
    function IsType(const AOther: TD3TypeInfo): Boolean;
    /// <summary>idTypeInfo::RespondsTo</summary>
    function RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
    /// <summary>
    ///   The <c>CreateInstance</c> of the declaration: a new object of the class, which knows its type. An abstract
    ///   class is an error ("Cannot instanciate abstract class").
    /// </summary>
    function CreateInstance: TD3Class;
    /// <summary>The number of <c>EVENT</c> lines of the declaration (the class's own, not the inherited ones)</summary>
    function EventBindingCount: Integer;
    /// <summary>One <c>EVENT</c> line of the declaration</summary>
    function EventBindingAt(const AIndex: Integer): TD3EventBinding;
    /// <summary>Runs the spawn function of the class on an object</summary>
    procedure RunSpawn(const AInstance: TD3Class);
    /// <summary>The code address of the spawn function: two classes that share a function have the same one</summary>
    function SpawnAddress: NativeUInt;
    property Name: AnsiString read FClassName;
    property SuperclassName: AnsiString read FSuperclassName;
    property Super: TD3TypeInfo read FSuper write FSuper;
    property EventMap: TD3EventMap read FEventMap;
    property FreeEventMap: Boolean read FFreeEventMap;
    property TypeNum: Integer read FTypeNum write FTypeNum;
    property LastChild: Integer read FLastChild write FLastChild;
    property Node: TIdHierarchy<TD3TypeInfo> read FNode;
  end;

  /// <summary>
  ///   idClass: the base class of every object of the game. It knows its type, so it can say what it is
  ///   (<c>IsType</c>), what events it answers (<c>RespondsTo</c>) and run the spawn functions of its classes from
  ///   the first superclass to its own (<c>CallSpawn</c>). The destructor cancels the events posted for it.
  /// </summary>
  TD3Class = class
  strict private
    FType: TD3TypeInfo;
    FEventCanceller: ID3EventCanceller;
    function CallSpawnFunc(const AClass: TD3TypeInfo): TD3TypeInfo;
  public
    constructor Create(const AEventCanceller: ID3EventCanceller = nil);
    /// <summary>idClass::~idClass: <c>idEvent::CancelEvents( this )</c></summary>
    destructor Destroy; override;
    /// <summary>idClass::Spawn: nothing</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    /// <summary>Called by <c>TD3TypeInfo.CreateInstance</c>: what <c>GetType</c> of the declaration gives</summary>
    procedure AssignType(const AType: TD3TypeInfo);
    /// <summary>idClass::GetType: nil for an object that was not made by a class declaration</summary>
    function GetType: TD3TypeInfo;
    /// <summary>idClass::GetClassname</summary>
    function GetClassname: AnsiString;
    /// <summary>idClass::GetSuperclass</summary>
    function GetSuperclass: AnsiString;
    /// <summary>idClass::IsType</summary>
    function IsType(const AType: TD3TypeInfo): Boolean;
    /// <summary>idClass::RespondsTo</summary>
    function RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
    /// <summary>
    ///   idClass::CallSpawn: the spawn functions of the superclasses and then the one of the class, each one once
    ///   (a class that has none of its own does not call its superclass's again)
    /// </summary>
    procedure CallSpawn;
    /// <summary>
    ///   idClass::ProcessEventArgPtr without the checks of the arguments: runs the handler of the class now; false
    ///   if the class does not respond to the event. The handler may free the object.
    /// </summary>
    function ProcessEvent(const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs): Boolean; overload;
    /// <summary>idClass::ProcessEvent( ev ): an event with no arguments</summary>
    function ProcessEvent(const AEvent: TDoomScriptEventDef): Boolean; overload;
  end;

implementation

uses
  DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Errors;

const
  SAbstractClass = 'Cannot instanciate abstract class %s.';

{ TD3EventMap }

constructor TD3EventMap.Create(const ACount: Integer);
begin
  inherited Create;
  SetLength(FHandlers, ACount);
end;

function TD3EventMap.Find(const AEventNum: Integer): TD3EventHandler;
begin
  if (AEventNum >= 0) and (AEventNum < Length(FHandlers)) then
    Result := FHandlers[AEventNum]
  else
    Result := nil;
end;

procedure TD3EventMap.SetHandler(const AEventNum: Integer; const AHandler: TD3EventHandler);
begin
  FHandlers[AEventNum] := AHandler;
end;

{ TD3TypeInfo }

constructor TD3TypeInfo.Create(const AClassName, ASuperclassName: AnsiString; const AFactory: TD3InstanceFactory;
  const ASpawn: TD3SpawnProc; const AAbstract: Boolean; const APrinter: ID3GamePrinter);
begin
  inherited Create;
  FClassName := AClassName;
  FSuperclassName := ASuperclassName;
  FFactory := AFactory;
  FSpawn := ASpawn;
  FAbstract := AAbstract;
  FPrinter := APrinter;
  FNode := TIdHierarchy<TD3TypeInfo>.Create;
end;

destructor TD3TypeInfo.Destroy;
begin
  Shutdown;
  FNode.Free;
  inherited Destroy;
end;

procedure TD3TypeInfo.AddEvent(const AEvent: TDoomScriptEventDef; const AHandler: TD3EventHandler);
var
  LBinding: TD3EventBinding;
begin
  LBinding.Event := AEvent;
  LBinding.Handler := AHandler;
  FEventCallbacks := FEventCallbacks + [LBinding];
end;

procedure TD3TypeInfo.Init(const ARoot: TIdHierarchy<TD3TypeInfo>; const ANumEvents: Integer;
  var AEventCallbackMemory: Integer);
var
  LClass: TD3TypeInfo;
  LIndex: Integer;
  LEventNum: Integer;
  LSet: TArray<Boolean>;
begin
  if Assigned(FEventMap) then
    // we've already been initialized by a subclass
    Exit;

  // make sure our superclass is initialized first
  if Assigned(FSuper) and not Assigned(FSuper.FEventMap) then
    FSuper.Init(ARoot, ANumEvents, AEventCallbackMemory);

  // add to our node hierarchy
  if Assigned(FSuper) then
    FNode.ParentTo(FSuper.FNode)
  else
    FNode.ParentTo(ARoot);
  FNode.SetOwner(Self);

  // keep track of the number of children below each class
  LClass := FSuper;
  while Assigned(LClass) do
  begin
    Inc(LClass.FLastChild);
    LClass := LClass.FSuper;
  end;

  // if we're not adding any new event callbacks, we can just use our superclass's table
  if (Length(FEventCallbacks) = 0) and Assigned(FSuper) then
  begin
    FEventMap := FSuper.FEventMap;
    Exit;
  end;

  // set a flag so we know to free the event table
  FFreeEventMap := True;

  // a table with as many entries as there are events
  FEventMap := TD3EventMap.Create(ANumEvents);
  Inc(AEventCallbackMemory, D3_EVENT_CALLBACK_SIZE * ANumEvents);

  // go through the inheritance order and copy the event callback into a list indexed by the event number; the
  // flags make the callbacks of a subclass override the ones of its superclass
  SetLength(LSet, ANumEvents);
  LClass := Self;
  while Assigned(LClass) do
  begin
    for LIndex := 0 to Length(LClass.FEventCallbacks) - 1 do
    begin
      LEventNum := LClass.FEventCallbacks[LIndex].Event.EventNum;
      if LSet[LEventNum] then
        Continue;
      LSet[LEventNum] := True;
      FEventMap.SetHandler(LEventNum, LClass.FEventCallbacks[LIndex].Handler);
    end;
    LClass := LClass.FSuper;
  end;
end;

procedure TD3TypeInfo.Shutdown;
begin
  // free up the memory used for event lookups
  if Assigned(FEventMap) then
  begin
    if FFreeEventMap then
      FEventMap.Free;
    FEventMap := nil;
  end;
  FTypeNum := 0;
  FLastChild := 0;
end;

function TD3TypeInfo.IsType(const AOther: TD3TypeInfo): Boolean;
begin
  Result := (FTypeNum >= AOther.FTypeNum) and (FTypeNum <= AOther.FLastChild);
end;

function TD3TypeInfo.RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
begin
  // we don't respond to this event if there is no table or no entry
  Result := Assigned(FEventMap) and Assigned(FEventMap.Find(AEvent.EventNum));
end;

function TD3TypeInfo.EventBindingCount: Integer;
begin
  Result := Length(FEventCallbacks);
end;

function TD3TypeInfo.EventBindingAt(const AIndex: Integer): TD3EventBinding;
begin
  Result := FEventCallbacks[AIndex];
end;

procedure TD3TypeInfo.RunSpawn(const AInstance: TD3Class);
begin
  FSpawn(AInstance);
end;

function TD3TypeInfo.SpawnAddress: NativeUInt;
begin
  // @ on a procedural variable gives the address of the procedure it holds (@@ would be the variable)
  Result := NativeUInt(@FSpawn);
end;

function TD3TypeInfo.CreateInstance: TD3Class;
begin
  if FAbstract or not Assigned(FFactory) then
    TD3GameErrors.RaiseError(FPrinter, AnsiString(Format(SAbstractClass, [string(FClassName)])));
  Result := FFactory();
  if Assigned(Result) then
    Result.AssignType(Self);
end;

{ TD3Class }

constructor TD3Class.Create(const AEventCanceller: ID3EventCanceller);
begin
  inherited Create;
  FEventCanceller := AEventCanceller;
end;

destructor TD3Class.Destroy;
begin
  if Assigned(FEventCanceller) then
    FEventCanceller.CancelEvents(Self);
  inherited Destroy;
end;

class procedure TD3Class.SpawnClass(const AInstance: TD3Class);
begin
end;

procedure TD3Class.AssignType(const AType: TD3TypeInfo);
begin
  FType := AType;
end;

function TD3Class.GetType: TD3TypeInfo;
begin
  Result := FType;
end;

function TD3Class.GetClassname: AnsiString;
begin
  Result := FType.Name;
end;

function TD3Class.GetSuperclass: AnsiString;
begin
  Result := FType.SuperclassName;
end;

function TD3Class.IsType(const AType: TD3TypeInfo): Boolean;
begin
  Result := FType.IsType(AType);
end;

function TD3Class.RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
begin
  Result := FType.RespondsTo(AEvent);
end;

function TD3Class.CallSpawnFunc(const AClass: TD3TypeInfo): TD3TypeInfo;
begin
  if Assigned(AClass.Super) then
  begin
    Result := CallSpawnFunc(AClass.Super);
    // don't call the same function twice in a row;
    // this can happen when subclasses don't have their own spawn function
    if Result.SpawnAddress = AClass.SpawnAddress then
      Exit;
  end;
  AClass.RunSpawn(Self);
  Result := AClass;
end;

procedure TD3Class.CallSpawn;
begin
  CallSpawnFunc(FType);
end;

function TD3Class.ProcessEvent(const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs): Boolean;
var
  LHandler: TD3EventHandler;
begin
  LHandler := nil;
  if Assigned(FType.EventMap) then
    LHandler := FType.EventMap.Find(AEvent.EventNum);
  Result := Assigned(LHandler);
  if Result then
    LHandler(Self, AEvent, AArgs);
end;

function TD3Class.ProcessEvent(const AEvent: TDoomScriptEventDef): Boolean;
var
  LArgs: TDoomScriptEventArgs;
begin
  LArgs := Default(TDoomScriptEventArgs);
  Result := ProcessEvent(AEvent, LArgs);
end;

end.
