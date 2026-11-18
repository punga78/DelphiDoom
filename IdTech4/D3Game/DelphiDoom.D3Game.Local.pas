{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idGameLocal (the entity table and the     }
{  spawning of the entities of a map)                                          }
{                                                                              }
{  Port of Doom 3 (id Software): game\Game_local.h, Game_local.cpp             }
{  (RegisterEntity, UnregisterEntity, SpawnEntityType, SpawnEntityDef,         }
{  FindEntityDef, InhibitEntitySpawn, SpawnMapEntities, MapPopulate, the       }
{  names hash, the think loop of RunFrame). Clients, players, physics,         }
{  render and sound worlds, saving and the network are not ported yet.         }
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
unit DelphiDoom.D3Game.Local;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Containers.HashIndex,
  DelphiDoom.IdLib.Containers.LinkList, DelphiDoom.Scanner.IdDict, DelphiDoom.D3Game.Types,
  DelphiDoom.IdLib.Math.Random, DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.ClassSystem,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity;

type
  /// <summary>The services a game needs (every one is an interface; none is owned by the game)</summary>
  TD3GameServices = record
    Printer: ID3GamePrinter;
    EntityDefs: ID3EntityDefs;
    SpawnFunctions: ID3SpawnFunctions;
    ScriptNames: ID3ScriptNames;
    Settings: ID3GameSettings;
    MapSteps: ID3MapSteps;
    /// <summary>idEvent::CancelEvents for the destructors; may be nil</summary>
    EventCanceller: ID3EventCanceller;
    /// <summary>Told when an entity enters or leaves the table; may be nil</summary>
    EntityObserver: ID3EntityObserver;
    /// <summary>The event definitions of the entity classes (not owned); may be nil for a game with no such classes</summary>
    Events: TD3EntityEvents;
    /// <summary>Where the entities post events; may be nil</summary>
    EventQueue: ID3EventQueue;
    /// <summary>The script functions the triggers call; may be nil</summary>
    ScriptFunctions: ID3ScriptFunctions;
    /// <summary>The thread that runs an event handler (return values, <c>waitFor</c>); may be nil</summary>
    ScriptThreads: ID3ScriptThreads;
  end;

  /// <summary>
  ///   idGameLocal, the part that holds the entities: the table of the entities by number (the first
  ///   <c>D3_MAX_CLIENTS</c> numbers are for the clients), the spawn ids, the names hash, the list of all the spawned
  ///   entities and the list of the ones that think. It spawns entities from an entityDef (<c>SpawnEntityDef</c>: the
  ///   <c>spawnclass</c> or <c>spawnfunc</c> of the declaration) or from a class (<c>SpawnEntityType</c>), spawns the
  ///   entities of a map file (<c>SpawnMapEntities</c>, <c>MapPopulate</c>) and runs the think loop of a frame
  ///   (<c>RunFrameThink</c>: the loop of <c>RunFrame</c> that makes the active entities think and takes out the ones
  ///   that stopped).
  ///   <para>The game owns every object it makes (<c>SpawnEntityDef</c>, <c>SpawnEntityType</c>): the original leaves
  ///   them to its own deletion; here they are freed with the game (or by <c>RemoveEntity</c>). The game implements
  ///   <c>ID3EntityWorld</c> without reference counting: it is owned by whoever created it and the entities hold it
  ///   as an interface only to ask.</para>
  /// </summary>
  TD3GameLocal = class(TObject, ID3EntityWorld, ID3EventCanceller, ID3EntityGame)
  strict private
    FRandom: TIdRandom;
    FStartup: Boolean;
    FServices: TD3GameServices;
    FClasses: TD3ClassSystem;
    FMapSource: ID3MapSource;
    FEntities: array[0..D3_MAX_GENTITIES - 1] of TD3Entity;
    FSpawnIds: array[0..D3_MAX_GENTITIES - 1] of Integer;
    FNumEntities: Integer;
    FEntityHash: TIdHashIndex;
    FSpawnArgs: TIdDict;
    FSpawnedEntities: TIdLinkList<TD3Entity>;
    FActiveEntities: TIdLinkList<TD3Entity>;
    FNumEntitiesToDeactivate: Integer;
    FFirstFreeIndex: Integer;
    FSpawnCount: Integer;
    FMapSpawnCount: Integer;
    FInCinematic: Boolean;
    FTime: Integer;
    FPreviousTime: Integer;
    FMsec: Integer;
    FFrameNum: Integer;
    FObjects: TObjectList<TD3Class>;
    FDisposing: Boolean;
    function GetEntity(const ANumber: Integer): TD3Entity;
    function GetSpawnId(const ANumber: Integer): Integer;
    procedure Warning(const AText: AnsiString);
    procedure Printf(const AText: AnsiString);
  protected
    { ID3EntityWorld, without reference counting }
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(const AServices: TD3GameServices; const AClasses: TD3ClassSystem);
    destructor Destroy; override;
    /// <summary>
    ///   The entity part of <c>idGameLocal::InitFromNewMap</c>: an empty table with the first numbers left to the
    ///   clients, the spawn count back at its start, empty lists, time zero. The objects of the old map stay allocated
    ///   (as in the original, whose map shutdown deletes them first): free them with <c>RemoveEntity</c> before.
    /// </summary>
    procedure NewMap;
    /// <summary>
    ///   <c>type->CreateInstance()</c> of a game that owns what it makes: the object is freed with the game, or when
    ///   it is destroyed before (its destructor reports to <c>CancelEvents</c>, which lets it go). Nil for a class
    ///   whose factory gives none; an abstract class is an error.
    /// </summary>
    function CreateObject(const AType: TD3TypeInfo): TD3Class;
    /// <summary>
    ///   The hook that the objects of this game call from their destructor (<c>idClass::~idClass</c>): the game stops
    ///   owning the object, and the cancel of the events is passed to the service of the game
    /// </summary>
    procedure CancelEvents(const AObject: TObject);
    /// <summary>idGameLocal::RegisterEntity: gives the entity its number, spawn id and place in the spawned list</summary>
    procedure RegisterEntity(const AEntity: TD3Entity);
    /// <summary>idGameLocal::UnregisterEntity: leaves the table and the spawned list; the number is free again</summary>
    procedure UnregisterEntity(const AEntity: TD3Entity);
    /// <summary>
    ///   idGameLocal::SpawnEntityType: an object of the class (which must be an entity class) spawned with the
    ///   arguments (nil: none). Raises <c>ED3GameException</c> for a class that is not an entity class or abstract.
    ///   The spawn arguments are cleared at the end (and not if an error was raised, as in the original).
    /// </summary>
    function SpawnEntityType(const AClassDef: TD3TypeInfo; const AArgs: TIdDict = nil): TD3Entity;
    /// <summary>
    ///   idGameLocal::SpawnEntityDef: finds the entityDef of <c>classname</c>, adds its defaults to the arguments and
    ///   spawns what it says: the class of <c>spawnclass</c> or a thread on the script function of <c>spawnfunc</c>.
    ///   False (with a warning) if there is nothing to spawn; the entity comes back if the class is an entity class.
    /// </summary>
    function SpawnEntityDef(const AArgs: TIdDict; out AEntity: TD3Entity): Boolean;
    /// <summary>idGameLocal::FindEntityDef: the <c>_mp</c> variant first in multiplayer</summary>
    function FindEntityDef(const AName: AnsiString): ID3EntityDef;
    /// <summary>idGameLocal::FindEntityDefDict: the defaults of the entityDef, nil if there is none</summary>
    function FindEntityDefDict(const AName: AnsiString): TIdDict;
    /// <summary>
    ///   idGameLocal::InhibitEntitySpawn: whether the skill (or multiplayer) says that a map entity is not spawned
    ///   (<c>not_easy</c>, <c>not_medium</c>, <c>not_hard</c>, <c>not_multiplayer</c>, the medkits of the hardest skill,
    ///   the BFG and the soul cube of multiplayer)
    /// </summary>
    function InhibitEntitySpawn(const ASpawnArgs: TIdDict): Boolean;
    /// <summary>
    ///   idGameLocal::SpawnMapEntities: the worldspawn first (in the world entity number), then the other entities of
    ///   the map file that the skill lets in. Errors if there are no entities or the world cannot be spawned.
    /// </summary>
    procedure SpawnMapEntities;
    /// <summary>
    ///   idGameLocal::MapPopulate: spawns the map entities, spreads the locations, prepares the initial spawn spots,
    ///   notes how many entities the map has and serves the pending events (the main script of the map)
    /// </summary>
    procedure MapPopulate;
    /// <summary>idGameLocal::AddEntityToHash</summary>
    procedure AddEntityToHash(const AName: AnsiString; const AEntity: TD3Entity);
    /// <summary>idGameLocal::RemoveEntityFromHash</summary>
    function RemoveEntityFromHash(const AName: AnsiString; const AEntity: TD3Entity): Boolean;
    /// <summary>
    ///   idGameLocal::FindEntity: the entity of that name (the comparison ignores case, the hash does not: a name that
    ///   differs in case is only found if it falls in the same bucket); nil if none
    /// </summary>
    function FindEntity(const AName: AnsiString): TD3Entity;
    /// <summary>idGameLocal::FindEntityUsingDef: the next entity after the given one (nil: from the first) made from that entityDef</summary>
    function FindEntityUsingDef(const AFrom: TD3Entity; const AMatch: AnsiString): TD3Entity;
    /// <summary>
    ///   The loop of <c>idGameLocal::RunFrame</c> that makes the entities think: the time moves on by <c>Msec</c>, every
    ///   active entity thinks (in a cinematic only the ones that are in it; the others follow the time), then the
    ///   entities that stopped thinking leave the active list. The <c>g_timeentities</c> timing is not ported.
    /// </summary>
    procedure RunFrameThink;
    /// <summary>
    ///   The part of <c>idGameLocal::RunFrame</c> that this game has: <c>RunFrameThink</c> and then
    ///   <c>idEvent::ServiceEvents()</c> (the events due at the new time: a door's <c>&lt;returntopos1&gt;</c>, a timer)
    /// </summary>
    procedure RunFrame;
    /// <summary>
    ///   Deletes an entity of the table and frees the object (the <c>delete ent</c> of the original); false if the
    ///   number has no entity
    /// </summary>
    function RemoveEntity(const ANumber: Integer): Boolean;
    { ID3EntityGame }
    function GetTime: Integer;
    function GetPreviousTime: Integer;
    function GetEvents: TD3EntityEvents;
    function IsStartup: Boolean;
    function CRandomFloat: Single;
    function GetEntityByNumber(const ANumber: Integer): TD3Entity;
    function GetSpawnedEntities: TIdLinkList<TD3Entity>;
    function GetEventQueue: ID3EventQueue;
    function GetScriptFunctions: ID3ScriptFunctions;
    function GetSpawnFunctions: ID3SpawnFunctions;
    function GetScriptThreads: ID3ScriptThreads;
    /// <summary>gamestate = GAMESTATE_ACTIVE: entities spawned from now on find their targets at once</summary>
    procedure EndStartup;
    /// <summary>gamestate = GAMESTATE_STARTUP</summary>
    procedure BeginStartup;
    /// <summary>gameLocal.random.SetSeed (the game starts a map with seed 0)</summary>
    procedure SetRandomSeed(const ASeed: Integer);
    { ID3EntityWorld }
    function FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
    procedure SetScriptEntity(const AName: AnsiString; const AEntityNumber: Integer);
    procedure Error(const AText: AnsiString);
    function GetActiveEntities: TIdLinkList<TD3Entity>;
    function GetNumEntitiesToDeactivate: Integer;
    procedure SetNumEntitiesToDeactivate(const AValue: Integer);
    property Entities[const ANumber: Integer]: TD3Entity read GetEntity;
    /// <summary>gameLocal.spawnIds: the serial number of the entity of that number; -1 if none was ever spawned there</summary>
    property SpawnIds[const ANumber: Integer]: Integer read GetSpawnId;
    property NumEntities: Integer read FNumEntities;
    property FirstFreeIndex: Integer read FFirstFreeIndex;
    property SpawnCount: Integer read FSpawnCount write FSpawnCount;
    property MapSpawnCount: Integer read FMapSpawnCount;
    property SpawnedEntities: TIdLinkList<TD3Entity> read FSpawnedEntities;
    property ActiveEntities: TIdLinkList<TD3Entity> read FActiveEntities;
    property NumEntitiesToDeactivate: Integer read FNumEntitiesToDeactivate;
    property InCinematic: Boolean read FInCinematic write FInCinematic;
    property Time: Integer read FTime;
    property PreviousTime: Integer read FPreviousTime;
    /// <summary>gameLocal.msec: the length of a frame in milliseconds (16)</summary>
    property Msec: Integer read FMsec write FMsec;
    property FrameNum: Integer read FFrameNum;
    /// <summary>The map file that <c>SpawnMapEntities</c> reads; nil for none</summary>
    property MapSource: ID3MapSource read FMapSource write FMapSource;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

const
  SSpawnCountOverflow = 'idGameLocal::RegisterEntity: spawn count overflow';
  SNoFreeEntities = 'no free entities';
  SNonEntityClass = 'Attempted to spawn non-entity class ''%s''';
  SUnknownClassname = 'Unknown classname ''%s''%s.';
  SClassNotFound = 'Could not spawn ''%s''.  Class ''%s'' not found%s.';
  SNoInstance = 'Could not spawn ''%s''. Instance could not be created%s.';
  SFunctionNotFound = 'Could not spawn ''%s''.  Script function ''%s'' not found%s.';
  SNothingToSpawn = '%s doesn''t include a spawnfunc or spawnclass%s.';
  SSpawningEntities = 'Spawning entities'#10;
  SNoMapFile = 'No mapfile present'#10;
  SNoEntities = '...no entities';
  SWorldProblem = 'Problem spawning world entity';
  SEntitiesSpawned = '...%d entities spawned, %d inhibited'#10#10;
  SProcessingEvents = '==== Processing events ===='#10;
  SMultipleEntities = 'Multiple entities named ''%s''';
  SBadEntityNumber = 'idGameLocal::RegisterEntity: bad spawn_entnum %d';

constructor TD3GameLocal.Create(const AServices: TD3GameServices; const AClasses: TD3ClassSystem);
begin
  inherited Create;
  FServices := AServices;
  FClasses := AClasses;
  FEntityHash := TIdHashIndex.Create;
  FSpawnArgs := TIdDict.Create;
  FSpawnedEntities := TIdLinkList<TD3Entity>.Create;
  FActiveEntities := TIdLinkList<TD3Entity>.Create;
  FObjects := TObjectList<TD3Class>.Create(True);
  FMsec := 16;
  // idGameLocal::Clear
  FillChar(FSpawnIds, SizeOf(FSpawnIds), $FF);
  FEntityHash.Clear(1024, D3_MAX_GENTITIES);
  FSpawnCount := D3_INITIAL_SPAWN_COUNT;
end;

destructor TD3GameLocal.Destroy;
begin
  // the entities take themselves out of the table as they are freed: nobody is listening any more
  FDisposing := True;
  FObjects.Free;
  FActiveEntities.Free;
  FSpawnedEntities.Free;
  FSpawnArgs.Free;
  FEntityHash.Free;
  inherited Destroy;
end;

function TD3GameLocal.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TD3GameLocal._AddRef: Integer;
begin
  Result := -1;
end;

function TD3GameLocal._Release: Integer;
begin
  Result := -1;
end;

function TD3GameLocal.GetEntity(const ANumber: Integer): TD3Entity;
begin
  if (ANumber >= 0) and (ANumber < D3_MAX_GENTITIES) then
    Result := FEntities[ANumber]
  else
    Result := nil;
end;

function TD3GameLocal.GetSpawnId(const ANumber: Integer): Integer;
begin
  if (ANumber >= 0) and (ANumber < D3_MAX_GENTITIES) then
    Result := FSpawnIds[ANumber]
  else
    Result := -1;
end;

function TD3GameLocal.CreateObject(const AType: TD3TypeInfo): TD3Class;
begin
  Result := AType.CreateInstance;
  if Assigned(Result) then
    FObjects.Add(Result);
end;

procedure TD3GameLocal.CancelEvents(const AObject: TObject);
begin
  if not FDisposing then
    FObjects.Extract(TD3Class(AObject));
  if Assigned(FServices.EventCanceller) then
    FServices.EventCanceller.CancelEvents(AObject);
end;

procedure TD3GameLocal.Printf(const AText: AnsiString);
begin
  FServices.Printer.Printf(AText);
end;

procedure TD3GameLocal.Warning(const AText: AnsiString);
begin
  FServices.Printer.Warning(AText);
end;

procedure TD3GameLocal.Error(const AText: AnsiString);
begin
  FServices.Printer.Error(AText);
  raise ED3GameException.Create(string(AText));
end;

function TD3GameLocal.GetTime: Integer;
begin
  Result := FTime;
end;

function TD3GameLocal.GetPreviousTime: Integer;
begin
  Result := FPreviousTime;
end;

function TD3GameLocal.GetEvents: TD3EntityEvents;
begin
  Result := FServices.Events;
end;

function TD3GameLocal.IsStartup: Boolean;
begin
  Result := FStartup;
end;

function TD3GameLocal.CRandomFloat: Single;
begin
  Result := FRandom.CRandomFloat;
end;

procedure TD3GameLocal.BeginStartup;
begin
  FStartup := True;
end;

procedure TD3GameLocal.EndStartup;
begin
  FStartup := False;
end;

procedure TD3GameLocal.SetRandomSeed(const ASeed: Integer);
begin
  FRandom.SetSeed(ASeed);
end;

function TD3GameLocal.GetEntityByNumber(const ANumber: Integer): TD3Entity;
begin
  Result := GetEntity(ANumber);
end;

function TD3GameLocal.GetSpawnedEntities: TIdLinkList<TD3Entity>;
begin
  Result := FSpawnedEntities;
end;

function TD3GameLocal.GetEventQueue: ID3EventQueue;
begin
  Result := FServices.EventQueue;
end;

function TD3GameLocal.GetScriptFunctions: ID3ScriptFunctions;
begin
  Result := FServices.ScriptFunctions;
end;

function TD3GameLocal.GetSpawnFunctions: ID3SpawnFunctions;
begin
  Result := FServices.SpawnFunctions;
end;

function TD3GameLocal.GetScriptThreads: ID3ScriptThreads;
begin
  Result := FServices.ScriptThreads;
end;

procedure TD3GameLocal.NewMap;
begin
  FStartup := True;
  FRandom.SetSeed(0);
  FillChar(FEntities, SizeOf(FEntities), 0);
  FillChar(FSpawnIds, SizeOf(FSpawnIds), $FF);
  FSpawnCount := D3_INITIAL_SPAWN_COUNT;

  FSpawnedEntities.Clear;
  FActiveEntities.Clear;
  FNumEntitiesToDeactivate := 0;

  // always leave room for the max number of clients,
  // even if they aren't all used, so numbers inside that
  // range are NEVER anything but clients
  FNumEntities := D3_MAX_CLIENTS;
  FFirstFreeIndex := D3_MAX_CLIENTS;

  FPreviousTime := 0;
  FTime := 0;
  FFrameNum := 0;

  FSpawnArgs.Clear;
  FInCinematic := False;
  FEntityHash.Clear(1024, D3_MAX_GENTITIES);
end;

procedure TD3GameLocal.RegisterEntity(const AEntity: TD3Entity);
var
  LSpawnEntNum: Integer;
begin
  if FSpawnCount >= (1 shl (32 - D3_GENTITYNUM_BITS)) then
    Error(SSpawnCountOverflow);

  if not FSpawnArgs.GetInt('spawn_entnum', '0', LSpawnEntNum) then
  begin
    while Assigned(FEntities[FFirstFreeIndex]) and (FFirstFreeIndex < D3_ENTITYNUM_MAX_NORMAL) do
      Inc(FFirstFreeIndex);
    if FFirstFreeIndex >= D3_ENTITYNUM_MAX_NORMAL then
      Error(SNoFreeEntities);
    LSpawnEntNum := FFirstFreeIndex;
    Inc(FFirstFreeIndex);
  end;
  // the original writes outside its table for a number that is not one (a map is input)
  if (LSpawnEntNum < 0) or (LSpawnEntNum >= D3_MAX_GENTITIES) then
    Error(AnsiString(Format(SBadEntityNumber, [LSpawnEntNum])));

  FEntities[LSpawnEntNum] := AEntity;
  FSpawnIds[LSpawnEntNum] := FSpawnCount;
  Inc(FSpawnCount);
  AEntity.EntityNumber := LSpawnEntNum;
  AEntity.SpawnNode.AddToEnd(FSpawnedEntities);
  AEntity.SpawnArgs.TransferKeyValues(FSpawnArgs);

  if LSpawnEntNum >= FNumEntities then
    Inc(FNumEntities);

  if Assigned(FServices.EntityObserver) then
    FServices.EntityObserver.EntityRegistered(AEntity, LSpawnEntNum);
end;

procedure TD3GameLocal.UnregisterEntity(const AEntity: TD3Entity);
begin
  if FDisposing then
    Exit;
  if (AEntity.EntityNumber <> D3_ENTITYNUM_NONE) and (FEntities[AEntity.EntityNumber] = AEntity) then
  begin
    if Assigned(FServices.EntityObserver) then
      FServices.EntityObserver.EntityUnregistered(AEntity.EntityNumber);
    AEntity.SpawnNode.Remove;
    FEntities[AEntity.EntityNumber] := nil;
    FSpawnIds[AEntity.EntityNumber] := -1;
    if (AEntity.EntityNumber >= D3_MAX_CLIENTS) and (AEntity.EntityNumber < FFirstFreeIndex) then
      FFirstFreeIndex := AEntity.EntityNumber;
    AEntity.EntityNumber := D3_ENTITYNUM_NONE;
  end;
end;

function TD3GameLocal.SpawnEntityType(const AClassDef: TD3TypeInfo; const AArgs: TIdDict): TD3Entity;
var
  LObject: TD3Class;
  LEntityType: TD3TypeInfo;
begin
  LEntityType := FClasses.GetClass(D3_ENTITY_CLASS_NAME);
  if (not Assigned(LEntityType)) or (not AClassDef.IsType(LEntityType)) then
    Error(AnsiString(Format(SNonEntityClass, [string(AClassDef.Name)])));

  if Assigned(AArgs) then
    FSpawnArgs.Assign(AArgs)
  else
    FSpawnArgs.Clear;
  LObject := CreateObject(AClassDef);
  if Assigned(LObject) then
    LObject.CallSpawn;
  FSpawnArgs.Clear;

  Result := TD3Entity(LObject);
end;

function TD3GameLocal.SpawnEntityDef(const AArgs: TIdDict; out AEntity: TD3Entity): Boolean;
var
  LClassname: AnsiString;
  LSpawn: AnsiString;
  LName: AnsiString;
  LError: AnsiString;
  LDef: ID3EntityDef;
  LClass: TD3TypeInfo;
  LObject: TD3Class;
  LEntityType: TD3TypeInfo;
begin
  AEntity := nil;
  Result := False;

  FSpawnArgs.Assign(AArgs);

  LError := '';
  if FSpawnArgs.GetString('name', '', LName) then
    LError := AnsiString(Format(' on ''%s''', [string(LName)]));

  FSpawnArgs.GetString('classname', '', LClassname);

  LDef := FindEntityDef(LClassname);
  if not Assigned(LDef) then
  begin
    Warning(AnsiString(Format(SUnknownClassname, [string(LClassname), string(LError)])));
    Exit;
  end;

  FSpawnArgs.SetDefaults(LDef.GetDict);

  // check if we should spawn a class object
  if FSpawnArgs.GetString('spawnclass', '', LSpawn) then
  begin
    LClass := FClasses.GetClass(LSpawn);
    if not Assigned(LClass) then
    begin
      Warning(AnsiString(Format(SClassNotFound, [string(LClassname), string(LSpawn), string(LError)])));
      Exit;
    end;

    LObject := CreateObject(LClass);
    if not Assigned(LObject) then
    begin
      Warning(AnsiString(Format(SNoInstance, [string(LClassname), string(LError)])));
      Exit;
    end;

    LObject.CallSpawn;

    LEntityType := FClasses.GetClass(D3_ENTITY_CLASS_NAME);
    if Assigned(LEntityType) and LObject.IsType(LEntityType) then
      AEntity := TD3Entity(LObject);

    Exit(True);
  end;

  // check if we should call a script function to spawn
  if FSpawnArgs.GetString('spawnfunc', '', LSpawn) then
  begin
    if not FServices.SpawnFunctions.StartSpawnFunction(LSpawn) then
    begin
      Warning(AnsiString(Format(SFunctionNotFound, [string(LClassname), string(LSpawn), string(LError)])));
      Exit;
    end;
    Exit(True);
  end;

  Warning(AnsiString(Format(SNothingToSpawn, [string(LClassname), string(LError)])));
end;

function TD3GameLocal.FindEntityDef(const AName: AnsiString): ID3EntityDef;
begin
  Result := nil;
  if FServices.Settings.GetIsMultiplayer then
    Result := FServices.EntityDefs.FindEntityDef(AName + '_mp');
  if not Assigned(Result) then
    Result := FServices.EntityDefs.FindEntityDef(AName);
end;

function TD3GameLocal.FindEntityDefDict(const AName: AnsiString): TIdDict;
var
  LDef: ID3EntityDef;
begin
  LDef := FindEntityDef(AName);
  if Assigned(LDef) then
    Result := LDef.GetDict
  else
    Result := nil;
end;

function TD3GameLocal.InhibitEntitySpawn(const ASpawnArgs: TIdDict): Boolean;
var
  LName: AnsiString;
  LSkill: Integer;
begin
  Result := False;
  LSkill := FServices.Settings.GetSkill;

  if FServices.Settings.GetIsMultiplayer then
    ASpawnArgs.GetBool('not_multiplayer', '0', Result)
  else if LSkill = 0 then
    ASpawnArgs.GetBool('not_easy', '0', Result)
  else if LSkill = 1 then
    ASpawnArgs.GetBool('not_medium', '0', Result)
  else
    ASpawnArgs.GetBool('not_hard', '0', Result);

  if LSkill = 3 then
  begin
    LName := ASpawnArgs.GetString('classname');
    if (TIdStrings.Icmp(LName, 'item_medkit') = 0) or (TIdStrings.Icmp(LName, 'item_medkit_small') = 0) then
      Result := True;
  end;

  if FServices.Settings.GetIsMultiplayer then
  begin
    LName := ASpawnArgs.GetString('classname');
    if (TIdStrings.Icmp(LName, 'weapon_bfg') = 0) or (TIdStrings.Icmp(LName, 'weapon_soulcube') = 0) then
      Result := True;
  end;
end;

procedure TD3GameLocal.SpawnMapEntities;
var
  LIndex: Integer;
  LNum: Integer;
  LInhibit: Integer;
  LNumEntities: Integer;
  LArgs: TIdDict;
  LEntity: TD3Entity;
  LWorld: TD3Entity;
begin
  Printf(SSpawningEntities);

  if not Assigned(FMapSource) then
  begin
    Printf(SNoMapFile);
    Exit;
  end;

  FServices.MapSteps.SetSkill(FServices.Settings.GetSkill);

  LNumEntities := FMapSource.GetNumEntities;
  if LNumEntities = 0 then
    Error(SNoEntities);

  LArgs := TIdDict.Create;
  try
    // the worldspawn is a special that performs any global setup needed by a level
    LArgs.Assign(FMapSource.GetEntityEpairs(0));
    LArgs.SetInt('spawn_entnum', D3_ENTITYNUM_WORLD);
    LWorld := nil;
    if SpawnEntityDef(LArgs, LEntity) then
      LWorld := FEntities[D3_ENTITYNUM_WORLD];
    if (not Assigned(LWorld)) or (not LWorld.IsType(FClasses.GetClass(D3_WORLDSPAWN_CLASS_NAME))) then
      Error(SWorldProblem);

    LNum := 1;
    LInhibit := 0;
    for LIndex := 1 to LNumEntities - 1 do
    begin
      LArgs.Assign(FMapSource.GetEntityEpairs(LIndex));
      if not InhibitEntitySpawn(LArgs) then
      begin
        // precache any media specified in the map entity
        FServices.MapSteps.CacheDictionaryMedia(LArgs);
        SpawnEntityDef(LArgs, LEntity);
        Inc(LNum);
      end
      else
        Inc(LInhibit);
    end;
  finally
    LArgs.Free;
  end;

  Printf(AnsiString(Format(SEntitiesSpawned, [LNum, LInhibit])));
end;

procedure TD3GameLocal.MapPopulate;
begin
  if FServices.Settings.GetIsMultiplayer then
    FServices.MapSteps.SetSkipSpecular(False);
  // parse the key/value pairs and spawn entities
  SpawnMapEntities;

  // mark location entities in all connected areas
  FServices.MapSteps.SpreadLocations;

  // prepare the list of randomized initial spawn spots
  FServices.MapSteps.RandomizeInitialSpawns;

  // spawnCount - 1 is the number of entities spawned into the map, their indexes started at MAX_CLIENTS (included)
  // mapSpawnCount is used as the max index of map entities, it's the first index of non-map entities
  FMapSpawnCount := D3_MAX_CLIENTS + FSpawnCount - 1;

  // execute pending events before the very first game frame
  // this makes sure the map script main() function is called
  // before the physics are run so entities can bind correctly
  Printf(SProcessingEvents);
  FServices.MapSteps.ServiceEvents;
  // InitFromNewMap: the map is up, gamestate = GAMESTATE_ACTIVE
  FStartup := False;
end;

procedure TD3GameLocal.AddEntityToHash(const AName: AnsiString; const AEntity: TD3Entity);
begin
  if Assigned(FindEntity(AName)) then
    Error(AnsiString(Format(SMultipleEntities, [string(AName)])));
  FEntityHash.Add(FEntityHash.GenerateKey(AName, True), AEntity.EntityNumber);
end;

function TD3GameLocal.RemoveEntityFromHash(const AName: AnsiString; const AEntity: TD3Entity): Boolean;
var
  LHash: Integer;
  LIndex: Integer;
begin
  if FDisposing then
    Exit(False);
  LHash := FEntityHash.GenerateKey(AName, True);
  LIndex := FEntityHash.First(LHash);
  while LIndex <> -1 do
  begin
    if Assigned(FEntities[LIndex]) and (FEntities[LIndex] = AEntity) and
      (TIdStrings.Icmp(FEntities[LIndex].GetName, AName) = 0) then
    begin
      FEntityHash.Remove(LHash, LIndex);
      Exit(True);
    end;
    LIndex := FEntityHash.Next(LIndex);
  end;
  Result := False;
end;

function TD3GameLocal.FindEntity(const AName: AnsiString): TD3Entity;
var
  LHash: Integer;
  LIndex: Integer;
begin
  LHash := FEntityHash.GenerateKey(AName, True);
  LIndex := FEntityHash.First(LHash);
  while LIndex <> -1 do
  begin
    if Assigned(FEntities[LIndex]) and (TIdStrings.Icmp(FEntities[LIndex].GetName, AName) = 0) then
      Exit(FEntities[LIndex]);
    LIndex := FEntityHash.Next(LIndex);
  end;
  Result := nil;
end;

function TD3GameLocal.FindEntityUsingDef(const AFrom: TD3Entity; const AMatch: AnsiString): TD3Entity;
var
  LEntity: TD3Entity;
begin
  if not Assigned(AFrom) then
    LEntity := FSpawnedEntities.Next
  else
    LEntity := AFrom.SpawnNode.Next;

  while Assigned(LEntity) do
  begin
    if TIdStrings.Icmp(LEntity.GetEntityDefName, AMatch) = 0 then
      Exit(LEntity);
    LEntity := LEntity.SpawnNode.Next;
  end;
  Result := nil;
end;

procedure TD3GameLocal.RunFrameThink;
var
  LEntity: TD3Entity;
  LNext: TD3Entity;
begin
  // update the game time
  Inc(FFrameNum);
  FPreviousTime := FTime;
  Inc(FTime, FMsec);

  // let entities think
  if FInCinematic then
  begin
    LEntity := FActiveEntities.Next;
    while Assigned(LEntity) do
    begin
      if FServices.Settings.GetCinematicEnabled and not LEntity.Cinematic then
        LEntity.UpdatePhysicsTime(FTime)
      else
        LEntity.Think;
      LEntity := LEntity.ActiveNode.Next;
    end;
  end
  else
  begin
    LEntity := FActiveEntities.Next;
    while Assigned(LEntity) do
    begin
      LEntity.Think;
      LEntity := LEntity.ActiveNode.Next;
    end;
  end;

  // remove any entities that have stopped thinking
  if FNumEntitiesToDeactivate <> 0 then
  begin
    LEntity := FActiveEntities.Next;
    while Assigned(LEntity) do
    begin
      LNext := LEntity.ActiveNode.Next;
      if LEntity.ThinkFlags = 0 then
        LEntity.ActiveNode.Remove;
      LEntity := LNext;
    end;
    FNumEntitiesToDeactivate := 0;
  end;
end;

procedure TD3GameLocal.RunFrame;
begin
  RunFrameThink;
  FServices.MapSteps.ServiceEvents;
end;

function TD3GameLocal.RemoveEntity(const ANumber: Integer): Boolean;
var
  LEntity: TD3Entity;
begin
  LEntity := GetEntity(ANumber);
  Result := Assigned(LEntity);
  if Result then
    FObjects.Remove(LEntity);
end;

function TD3GameLocal.FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
begin
  Result := FServices.EntityDefs.FindEntityDefByIndex(AIndex);
end;

procedure TD3GameLocal.SetScriptEntity(const AName: AnsiString; const AEntityNumber: Integer);
begin
  FServices.ScriptNames.SetEntity(AName, AEntityNumber);
end;

function TD3GameLocal.GetActiveEntities: TIdLinkList<TD3Entity>;
begin
  Result := FActiveEntities;
end;

function TD3GameLocal.GetNumEntitiesToDeactivate: Integer;
begin
  Result := FNumEntitiesToDeactivate;
end;

procedure TD3GameLocal.SetNumEntitiesToDeactivate(const AValue: Integer);
begin
  FNumEntitiesToDeactivate := AValue;
end;

end.
