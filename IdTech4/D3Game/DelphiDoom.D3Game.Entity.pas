{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idEntity (the base of the entities)       }
{                                                                              }
{  Port of Doom 3 (id Software): game\Entity.h, Entity.cpp (the entity as the  }
{  game table sees it: number, name, spawn arguments, think flags, the lists   }
{  that it is in). Physics, rendering, sound, binding, scripts objects,        }
{  targets and the network are not ported yet.                                 }
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
unit DelphiDoom.D3Game.Entity;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Containers.LinkList, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.Intf,
  DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Physics.Intf;

type
  TD3Entity = class;

  /// <summary>
  ///   What the entity classes (triggers, movers) ask of the game beyond the table (<c>ID3EntityWorld</c>): the time,
  ///   the random numbers, the entities by name and number, the events and the scripts. The game implements it; an
  ///   entity whose world does not (the fake of the first tests) simply cannot post events or read the time.
  /// </summary>
  ID3EntityGame = interface
    ['{2D8A4F17-B3C6-4E09-9A51-7F0E6C28D3B4}']
    /// <summary>gameLocal.time</summary>
    function GetTime: Integer;
    /// <summary>gameLocal.previousTime</summary>
    function GetPreviousTime: Integer;
    function GetEvents: TD3EntityEvents;
    /// <summary>gameLocal.GameState() == GAMESTATE_STARTUP: the map's entities are being spawned</summary>
    function IsStartup: Boolean;
    /// <summary>gameLocal.random.CRandomFloat()</summary>
    function CRandomFloat: Single;
    function FindEntity(const AName: AnsiString): TD3Entity;
    function GetEntityByNumber(const ANumber: Integer): TD3Entity;
    /// <summary>gameLocal.spawnIds[ number ]</summary>
    function GetSpawnId(const ANumber: Integer): Integer;
    /// <summary>gameLocal.Warning</summary>
    procedure Warning(const AText: AnsiString);
    function GetSpawnedEntities: TIdLinkList<TD3Entity>;
    /// <summary>The services of the scripts; each may be nil (the game has no script machine)</summary>
    function GetEventQueue: ID3EventQueue;
    function GetScriptFunctions: ID3ScriptFunctions;
    function GetSpawnFunctions: ID3SpawnFunctions;
    function GetScriptThreads: ID3ScriptThreads;
  end;

  /// <summary>
  ///   idEntityPtr&lt;idEntity&gt;: a reference to an entity that goes null when the entity is deleted (its spawn id
  ///   says which entity of that number it was). The value is encoded as the original does
  ///   (<c>spawnId shl GENTITYNUM_BITS or number</c>), and 0 is no entity.
  /// </summary>
  TD3EntityPtr = record
  strict private
    FValue: Integer;
  public
    class function Make(const AGame: ID3EntityGame; const AEntity: TD3Entity): TD3EntityPtr; static;
    /// <summary>The entity, or nil if it is gone or was never set</summary>
    function GetEntity(const AGame: ID3EntityGame): TD3Entity;
    property Value: Integer read FValue;
  end;

  /// <summary>
  ///   What an entity asks of the game (the parts of <c>gameLocal</c> that <c>idEntity</c> reaches): the entity table,
  ///   the names hash, the entityDefs, the script names and the list of the entities that think
  /// </summary>
  ID3EntityWorld = interface
    ['{C6E21A47-5D93-4B08-A1F7-30B9D8E4C562}']
    /// <summary>idGameLocal::RegisterEntity</summary>
    procedure RegisterEntity(const AEntity: TD3Entity);
    /// <summary>idGameLocal::UnregisterEntity</summary>
    procedure UnregisterEntity(const AEntity: TD3Entity);
    /// <summary>idGameLocal::AddEntityToHash: an error if the name is taken</summary>
    procedure AddEntityToHash(const AName: AnsiString; const AEntity: TD3Entity);
    /// <summary>idGameLocal::RemoveEntityFromHash</summary>
    function RemoveEntityFromHash(const AName: AnsiString; const AEntity: TD3Entity): Boolean;
    /// <summary>idGameLocal::FindEntityDef( name, false )</summary>
    function FindEntityDef(const AName: AnsiString): ID3EntityDef;
    /// <summary>declManager->DeclByIndex( DECL_ENTITYDEF, index )</summary>
    function FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
    /// <summary>gameLocal.program.SetEntity( name, ent ): -1 takes the name away</summary>
    procedure SetScriptEntity(const AName: AnsiString; const AEntityNumber: Integer);
    /// <summary>idGameLocal::Error: prints and raises ED3GameException</summary>
    procedure Error(const AText: AnsiString);
    /// <summary>gameLocal.activeEntities: the head of the list of the entities that think</summary>
    function GetActiveEntities: TIdLinkList<TD3Entity>;
    function GetNumEntitiesToDeactivate: Integer;
    procedure SetNumEntitiesToDeactivate(const AValue: Integer);
  end;

  /// <summary>
  ///   idEntity: the base class of what is in a map. It has a number in the game table, a name that is unique in the
  ///   map, the arguments it was spawned with and the flags that say what it does each frame. An entity that thinks
  ///   (its flags are not zero) is in the list of the active entities; the game calls <c>Think</c> on each one every
  ///   frame. <c>Spawn</c> registers the entity and names it; the destructor takes it out of the table, the names and
  ///   the lists, in the order of the original.
  /// </summary>
  TD3Entity = class(TD3Class)
  strict private
    FWorld: ID3EntityWorld;
    FEntityNumber: Integer;
    FEntityDefNumber: Integer;
    FThinkFlags: Integer;
    FCinematic: Boolean;
    FHealth: Integer;
    FName: AnsiString;
    FSpawnArgs: TIdDict;
    FSpawnNode: TIdLinkList<TD3Entity>;
    FActiveNode: TIdLinkList<TD3Entity>;
    FGame: ID3EntityGame;
    FHidden: Boolean;
    FTargets: TList<TD3EntityPtr>;
    FPhysics: ID3Physics;
    procedure SpawnEntity;
    procedure InitDefaultPhysics(const AOrigin: TIdVec3);
  protected
    property World: ID3EntityWorld read FWorld;
    /// <summary>The game services of the entity classes; nil if the world is not a game</summary>
    property Game: ID3EntityGame read FGame;
  public
    constructor Create(const AWorld: ID3EntityWorld; const AEventCanceller: ID3EventCanceller = nil);
    /// <summary>
    ///   idEntity::~idEntity (the part ported): stops thinking, leaves the active list, the names hash and the entity
    ///   table
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///   idEntity::Spawn, reduced to what the table needs and in the order of the original: registers the entity,
    ///   finds its entityDef, reads <c>cinematic</c>, names it (<c>name</c> or classname_entityDef_number) and reads
    ///   its health. A class that has its own spawn function calls this one first (<c>CallSpawn</c> does).
    /// </summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    /// <summary>idEntity::Think: nothing here (the original runs the physics and presents the entity)</summary>
    procedure Think; virtual;
    /// <summary>
    ///   <c>GetPhysics()->UpdateTime( time )</c> of a frame in a cinematic: the entities that are not in it only follow
    ///   the time. Nothing here (no physics yet).
    /// </summary>
    procedure UpdatePhysicsTime(const ATime: Integer); virtual;
    /// <summary>idEntity::GetEntityDefName: "*unknown*" for an entity with no entityDef</summary>
    function GetEntityDefName: AnsiString;
    /// <summary>
    ///   idEntity::SetName: takes the old name out of the hash and the script, and puts the new one in; "NULL" and
    ///   "null_entity" are reserved. The name is set before the hash is asked, so a name that is taken stays on the
    ///   entity when the error is raised (as in the original).
    /// </summary>
    procedure SetName(const ANewName: AnsiString);
    /// <summary>idEntity::GetName</summary>
    function GetName: AnsiString;
    /// <summary>idEntity::IsActive: in the list of the entities that think</summary>
    function IsActive: Boolean;
    /// <summary>idEntity::BecomeActive: adds the flags; joins the active list if it was not in it</summary>
    procedure BecomeActive(const AFlags: Integer);
    /// <summary>
    ///   idEntity::BecomeInactive: takes the flags away; an entity with no flags left is counted to be taken out of
    ///   the list at the end of the frame. The physics team rules of the original are not ported (no teams yet).
    /// </summary>
    procedure BecomeInactive(const AFlags: Integer);
    /// <summary>
    ///   The events the base entity answers (idEntity's <c>EVENT</c> lines that this phase ports: <c>&lt;findTargets&gt;</c>,
    ///   <c>activateTargets</c>, <c>hide</c>, <c>show</c>, <c>getName</c>, <c>setName</c>, <c>numTargets</c>,
    ///   <c>getTarget</c>, <c>isHidden</c>): call it on the declaration of the class
    /// </summary>
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    /// <summary>An event argument for an entity (its number, -1 for none)</summary>
    class function EntityArg(const AEntity: TD3Entity): TDoomScriptEventArg; static;
    /// <summary>The entity of an event argument (nil for none or for an entity that is gone)</summary>
    function EntityFromArg(const AArg: TDoomScriptEventArg): TD3Entity;
    /// <summary>idClass::ProcessEvent( ev, entity ): an event with one entity argument</summary>
    function ProcessEntityEvent(const AEvent: TDoomScriptEventDef; const AEntity: TD3Entity): Boolean;
    /// <summary>idClass::PostEventMS</summary>
    procedure PostEventMS(const AEvent: TDoomScriptEventDef; const ATime: Integer); overload;
    procedure PostEventMS(const AEvent: TDoomScriptEventDef; const ATime: Integer;
      const AArgs: array of TDoomScriptEventArg); overload;
    /// <summary>idClass::PostEventSec</summary>
    procedure PostEventSec(const AEvent: TDoomScriptEventDef; const ASeconds: Single); overload;
    procedure PostEventSec(const AEvent: TDoomScriptEventDef; const ASeconds: Single;
      const AArgs: array of TDoomScriptEventArg); overload;
    /// <summary>idClass::CancelEvents( ev )</summary>
    procedure CancelEvent(const AEvent: TDoomScriptEventDef);
    /// <summary>idEntity::IsHidden</summary>
    function IsHidden: Boolean;
    /// <summary>idEntity::Hide: nothing to free or update without a renderer</summary>
    procedure Hide; virtual;
    /// <summary>idEntity::Show</summary>
    procedure Show; virtual;
    /// <summary>
    ///   idEntity::Damage with a damage def: nothing here (no health, no damage defs); a class that wants to see it
    ///   overrides it
    /// </summary>
    procedure Damage(const ADamageDefName: AnsiString; const AScale: Single); virtual;
    /// <summary>
    ///   idGameLocal::RequirementMet: an entity that requires an item is met by an activator that has it; there is no
    ///   player and no inventory here, so it is always met (the original dereferences a null activator)
    /// </summary>
    function RequirementMet(const AActivator: TD3Entity; const ARequires: AnsiString;
      const ARemoveItem: Integer): Boolean;
    /// <summary>idEntity::HasSignal: signals (<c>onSignal</c> of the scripts) are not ported: false</summary>
    function HasSignal(const ASignal: Integer): Boolean; virtual;
    /// <summary>idEntity::Signal: nothing (see <c>HasSignal</c>)</summary>
    procedure Signal(const ASignal: Integer); virtual;
    /// <summary>idEntity::FindTargets: the entities named by the <c>target</c> keys (an entity that targets itself is an error)</summary>
    procedure FindTargets;
    /// <summary>idEntity::RemoveNullTargets</summary>
    procedure RemoveNullTargets;
    /// <summary>idEntity::ActivateTargets: sends <c>activate</c> to the targets that answer it</summary>
    procedure ActivateTargets(const AActivator: TD3Entity);
    function NumTargets: Integer;
    /// <summary>The target of that place, nil for none or for an entity that is gone</summary>
    function GetTarget(const AIndex: Integer): TD3Entity;
    /// <summary>idEntity::RunPhysics, reduced: no team, no push; posts <c>&lt;reachedpos&gt;</c> at the end of a motion</summary>
    function RunPhysics: Boolean;
    function GetPhysics: ID3Physics;
    /// <summary>idEntity::SetPhysics</summary>
    procedure SetPhysics(const APhysics: ID3Physics);
    /// <summary>idEntity::SetOrigin</summary>
    procedure SetOrigin(const AOrigin: TIdVec3);
    property EntityNumber: Integer read FEntityNumber write FEntityNumber;
    property EntityDefNumber: Integer read FEntityDefNumber;
    property ThinkFlags: Integer read FThinkFlags;
    property Cinematic: Boolean read FCinematic;
    property Health: Integer read FHealth;
    property SpawnArgs: TIdDict read FSpawnArgs;
    /// <summary>The node of the list of all the spawned entities (<c>gameLocal.spawnedEntities</c>)</summary>
    property SpawnNode: TIdLinkList<TD3Entity> read FSpawnNode;
    /// <summary>The node of the list of the entities that think (<c>gameLocal.activeEntities</c>)</summary>
    property ActiveNode: TIdLinkList<TD3Entity> read FActiveNode;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.PhysicsStatic;

const
  SSelfTarget = 'Entity ''%s'' is targeting itself';
  SInvalidBounds = 'Invalid bounds ''%s''-''%s'' on entity ''%s''';
  SInvalidSize = 'Invalid size ''%s'' on entity ''%s''';
  SReservedName = 'Cannot name entity ''%s''.  ''%s'' is reserved for script.';
  SUnknownDef = '*unknown*';

constructor TD3Entity.Create(const AWorld: ID3EntityWorld; const AEventCanceller: ID3EventCanceller);
begin
  inherited Create(AEventCanceller);
  FWorld := AWorld;
  FEntityNumber := D3_ENTITYNUM_NONE;
  FEntityDefNumber := -1;
  FSpawnArgs := TIdDict.Create;
  FSpawnNode := TIdLinkList<TD3Entity>.Create;
  FSpawnNode.SetOwner(Self);
  FActiveNode := TIdLinkList<TD3Entity>.Create;
  FActiveNode.SetOwner(Self);
  FTargets := TList<TD3EntityPtr>.Create;
  if not Supports(AWorld, ID3EntityGame, FGame) then
    FGame := nil;
  FPhysics := TD3PhysicsStatic.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0));
end;

destructor TD3Entity.Destroy;
begin
  if FThinkFlags <> 0 then
    BecomeInactive(FThinkFlags);
  FActiveNode.Remove;
  FWorld.RemoveEntityFromHash(FName, Self);
  FWorld.UnregisterEntity(Self);
  FPhysics := nil;
  FTargets.Free;
  FActiveNode.Free;
  FSpawnNode.Free;
  FSpawnArgs.Free;
  inherited Destroy;
end;

class procedure TD3Entity.SpawnClass(const AInstance: TD3Class);
begin
  TD3Entity(AInstance).SpawnEntity;
end;

procedure TD3Entity.SpawnEntity;
var
  LClassname: AnsiString;
  LDef: ID3EntityDef;
begin
  FWorld.RegisterEntity(Self);

  FSpawnArgs.GetString('classname', '', LClassname);
  LDef := FWorld.FindEntityDef(LClassname);
  if Assigned(LDef) then
    FEntityDefNumber := LDef.GetIndex;

  FHidden := FSpawnArgs.GetBool('hide', '0');
  if FHidden and Assigned(FGame) and Assigned(FGame.GetEvents) then
    // make sure we're hidden, since a spawn function might not set it up right
    PostEventMS(FGame.GetEvents.Hide, 0);

  FCinematic := FSpawnArgs.GetBool('cinematic', '0');

  // every object will have a unique name
  SetName(FSpawnArgs.GetString('name', AnsiString(Format('%s_%s_%d', [string(GetClassname),
    string(FSpawnArgs.GetString('classname')), FEntityNumber]))));

  // if we have targets, wait until all entities are spawned to get them
  if Assigned(FGame) and Assigned(FGame.GetEvents) and
    ((FSpawnArgs.MatchPrefix('target') >= 0) or (FSpawnArgs.MatchPrefix('guiTarget') >= 0)) then
  begin
    if FGame.IsStartup then
      PostEventMS(FGame.GetEvents.FindTargets, 0)
    else
      // not during spawn, so it's ok to get the targets
      FindTargets;
  end;

  FHealth := FSpawnArgs.GetInt('health');

  InitDefaultPhysics(FSpawnArgs.GetVector('origin'));
end;

procedure TD3Entity.InitDefaultPhysics(const AOrigin: TIdVec3);
var
  LMins: TIdVec3;
  LMaxs: TIdVec3;
  LSize: TIdVec3;
begin
  LMins.Zero;
  LMaxs.Zero;
  if not FSpawnArgs.GetBool('noclipmodel', '0') then
  begin
    // check if mins/maxs or size key/value pairs are set
    if FSpawnArgs.GetVector('mins', '', LMins) and FSpawnArgs.GetVector('maxs', '', LMaxs) then
    begin
      if (LMins.X > LMaxs.X) or (LMins.Y > LMaxs.Y) or (LMins.Z > LMaxs.Z) then
        FWorld.Error(AnsiString(Format(SInvalidBounds, [string(LMins.ToString), string(LMaxs.ToString),
          string(FName)])));
    end
    else if FSpawnArgs.GetVector('size', '', LSize) then
    begin
      if (LSize.X < 0) or (LSize.Y < 0) or (LSize.Z < 0) then
        FWorld.Error(AnsiString(Format(SInvalidSize, [string(LSize.ToString), string(FName)])));
      LMins.SetValues(LSize.X * -0.5, LSize.Y * -0.5, 0);
      LMaxs.SetValues(LSize.X * 0.5, LSize.Y * 0.5, LSize.Z);
    end
    else
    begin
      LMins.Zero;
      LMaxs.Zero;
    end;
  end;
  FPhysics := TD3PhysicsStatic.Create(AOrigin, LMins, LMaxs);
end;

class function TD3EntityPtr.Make(const AGame: ID3EntityGame; const AEntity: TD3Entity): TD3EntityPtr;
begin
  if Assigned(AEntity) then
    Result.FValue := (AGame.GetSpawnId(AEntity.EntityNumber) shl D3_GENTITYNUM_BITS) or AEntity.EntityNumber
  else
    Result.FValue := 0;
end;

function TD3EntityPtr.GetEntity(const AGame: ID3EntityGame): TD3Entity;
var
  LNumber: Integer;
begin
  LNumber := FValue and (D3_MAX_GENTITIES - 1);
  if ((AGame.GetSpawnId(LNumber) shl D3_GENTITYNUM_BITS) or LNumber) = FValue then
    Result := AGame.GetEntityByNumber(LNumber)
  else
    Result := nil;
end;

procedure TD3Entity.Think;
begin
  RunPhysics;
end;

function TD3Entity.GetPhysics: ID3Physics;
begin
  Result := FPhysics;
end;

procedure TD3Entity.SetPhysics(const APhysics: ID3Physics);
begin
  FPhysics := APhysics;
end;

procedure TD3Entity.SetOrigin(const AOrigin: TIdVec3);
begin
  FPhysics.SetOrigin(AOrigin);
end;

function TD3Entity.RunPhysics: Boolean;
var
  LStartTime: Integer;
  LEndTime: Integer;
  LReachedTime: Integer;
begin
  // don't run physics if not enabled
  if ((FThinkFlags and D3_TH_PHYSICS) = 0) or (not Assigned(FGame)) then
    Exit(False);

  LStartTime := FGame.GetPreviousTime;
  LEndTime := FGame.GetTime;
  FPhysics.Evaluate(LEndTime - LStartTime, LEndTime);

  // post reached event if the current time is at or past the end point of the motion
  LReachedTime := FPhysics.GetLinearEndTime;
  if (LStartTime < LReachedTime) and (LEndTime >= LReachedTime) then
    ProcessEvent(FGame.GetEvents.ReachedPos);
  LReachedTime := FPhysics.GetAngularEndTime;
  if (LStartTime < LReachedTime) and (LEndTime >= LReachedTime) then
    ProcessEvent(FGame.GetEvents.ReachedAng);
  Result := True;
end;

class function TD3Entity.EntityArg(const AEntity: TD3Entity): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_ENTITY;
  if Assigned(AEntity) then
    Result.IntValue := AEntity.EntityNumber
  else
    Result.IntValue := -1;
end;

function TD3Entity.EntityFromArg(const AArg: TDoomScriptEventArg): TD3Entity;
begin
  if (AArg.IntValue < 0) or (not Assigned(FGame)) then
    Result := nil
  else
    Result := FGame.GetEntityByNumber(AArg.IntValue);
end;

function TD3Entity.ProcessEntityEvent(const AEvent: TDoomScriptEventDef; const AEntity: TD3Entity): Boolean;
var
  LArgs: TDoomScriptEventArgs;
begin
  LArgs := Default(TDoomScriptEventArgs);
  LArgs[0] := EntityArg(AEntity);
  Result := ProcessEvent(AEvent, LArgs);
end;

procedure TD3Entity.PostEventMS(const AEvent: TDoomScriptEventDef; const ATime: Integer);
begin
  PostEventMS(AEvent, ATime, []);
end;

procedure TD3Entity.PostEventMS(const AEvent: TDoomScriptEventDef; const ATime: Integer;
  const AArgs: array of TDoomScriptEventArg);
begin
  if Assigned(FGame) and Assigned(FGame.GetEventQueue) then
    FGame.GetEventQueue.PostEventMS(Self, AEvent, ATime, AArgs);
end;

procedure TD3Entity.PostEventSec(const AEvent: TDoomScriptEventDef; const ASeconds: Single);
begin
  PostEventSec(AEvent, ASeconds, []);
end;

procedure TD3Entity.PostEventSec(const AEvent: TDoomScriptEventDef; const ASeconds: Single;
  const AArgs: array of TDoomScriptEventArg);
begin
  if Assigned(FGame) and Assigned(FGame.GetEventQueue) then
    FGame.GetEventQueue.PostEventSec(Self, AEvent, ASeconds, AArgs);
end;

procedure TD3Entity.CancelEvent(const AEvent: TDoomScriptEventDef);
begin
  if Assigned(FGame) and Assigned(FGame.GetEventQueue) then
    FGame.GetEventQueue.CancelEvent(Self, AEvent);
end;

function TD3Entity.IsHidden: Boolean;
begin
  Result := FHidden;
end;

procedure TD3Entity.Hide;
begin
  if not IsHidden then
    FHidden := True;
end;

procedure TD3Entity.Show;
begin
  if IsHidden then
    FHidden := False;
end;

procedure TD3Entity.Damage(const ADamageDefName: AnsiString; const AScale: Single);
begin
end;

function TD3Entity.RequirementMet(const AActivator: TD3Entity; const ARequires: AnsiString;
  const ARemoveItem: Integer): Boolean;
begin
  Result := True;
end;

function TD3Entity.HasSignal(const ASignal: Integer): Boolean;
begin
  Result := False;
end;

procedure TD3Entity.Signal(const ASignal: Integer);
begin
end;

procedure TD3Entity.FindTargets;
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LEntity: TD3Entity;
begin
  // targets can be a list of multiple names (gameLocal.GetTargets)
  FTargets.Clear;
  LIndex := FSpawnArgs.MatchPrefix('target');
  while LIndex >= 0 do
  begin
    if FSpawnArgs.TryGetKeyVal(LIndex, LKeyValue) then
    begin
      LEntity := FGame.FindEntity(LKeyValue.Value);
      if Assigned(LEntity) then
        FTargets.Add(TD3EntityPtr.Make(FGame, LEntity));
    end;
    LIndex := FSpawnArgs.MatchPrefix('target', LIndex);
  end;

  // ensure that we don't target ourselves since that could cause an infinite loop when activating entities
  for LIndex := 0 to FTargets.Count - 1 do
    if FTargets[LIndex].GetEntity(FGame) = Self then
      FWorld.Error(AnsiString(Format(SSelfTarget, [string(FName)])));
end;

procedure TD3Entity.RemoveNullTargets;
var
  LIndex: Integer;
begin
  for LIndex := FTargets.Count - 1 downto 0 do
    if not Assigned(FTargets[LIndex].GetEntity(FGame)) then
      FTargets.Delete(LIndex);
end;

procedure TD3Entity.ActivateTargets(const AActivator: TD3Entity);
var
  LIndex: Integer;
  LEntity: TD3Entity;
begin
  for LIndex := 0 to FTargets.Count - 1 do
  begin
    LEntity := FTargets[LIndex].GetEntity(FGame);
    if not Assigned(LEntity) then
      Continue;
    if LEntity.RespondsTo(FGame.GetEvents.Activate) or LEntity.HasSignal(D3_SIG_TRIGGER) then
    begin
      LEntity.Signal(D3_SIG_TRIGGER);
      LEntity.ProcessEntityEvent(FGame.GetEvents.Activate, AActivator);
    end;
  end;
end;

function TD3Entity.NumTargets: Integer;
begin
  Result := FTargets.Count;
end;

function TD3Entity.GetTarget(const AIndex: Integer): TD3Entity;
begin
  if (AIndex < 0) or (AIndex >= FTargets.Count) then
    Result := nil
  else
    Result := FTargets[AIndex].GetEntity(FGame);
end;

class procedure TD3Entity.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.FindTargets,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).FindTargets;
    end);
  AType.AddEvent(AEvents.ActivateTargets,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).ActivateTargets(TD3Entity(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.Hide,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).Hide;
    end);
  AType.AddEvent(AEvents.Show,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).Show;
    end);
  AType.AddEvent(AEvents.SetName,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).SetName(AArgs[0].StringValue);
    end);
  AType.AddEvent(AEvents.GetName,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThreads: ID3ScriptThreads;
    begin
      LThreads := TD3Entity(ATarget).Game.GetScriptThreads;
      if Assigned(LThreads) then
        LThreads.ReturnString(TD3Entity(ATarget).GetName);
    end);
  AType.AddEvent(AEvents.IsHidden,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThreads: ID3ScriptThreads;
    begin
      LThreads := TD3Entity(ATarget).Game.GetScriptThreads;
      if Assigned(LThreads) then
        LThreads.ReturnInteger(Ord(TD3Entity(ATarget).IsHidden));
    end);
  AType.AddEvent(AEvents.NumTargets,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThreads: ID3ScriptThreads;
    begin
      LThreads := TD3Entity(ATarget).Game.GetScriptThreads;
      if Assigned(LThreads) then
        LThreads.ReturnFloat(TD3Entity(ATarget).NumTargets);
    end);
  AType.AddEvent(AEvents.GetTarget,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThreads: ID3ScriptThreads;
      LEntity: TD3Entity;
    begin
      LThreads := TD3Entity(ATarget).Game.GetScriptThreads;
      if not Assigned(LThreads) then
        Exit;
      LEntity := TD3Entity(ATarget).GetTarget(Trunc(AArgs[0].FloatValue));
      if Assigned(LEntity) then
        LThreads.ReturnEntity(LEntity.EntityNumber)
      else
        LThreads.ReturnEntity(-1);
    end);
end;

procedure TD3Entity.UpdatePhysicsTime(const ATime: Integer);
begin
end;

function TD3Entity.GetEntityDefName: AnsiString;
begin
  if FEntityDefNumber < 0 then
    Exit(SUnknownDef);
  Result := FWorld.FindEntityDefByIndex(FEntityDefNumber).GetName;
end;

procedure TD3Entity.SetName(const ANewName: AnsiString);
begin
  if Length(FName) > 0 then
  begin
    FWorld.RemoveEntityFromHash(FName, Self);
    FWorld.SetScriptEntity(FName, -1);
  end;

  FName := ANewName;
  if Length(FName) > 0 then
  begin
    if (FName = 'NULL') or (FName = 'null_entity') then
      FWorld.Error(AnsiString(Format(SReservedName, [string(FName), string(FName)])));
    FWorld.AddEntityToHash(FName, Self);
    FWorld.SetScriptEntity(FName, FEntityNumber);
  end;
end;

function TD3Entity.GetName: AnsiString;
begin
  Result := FName;
end;

function TD3Entity.IsActive: Boolean;
begin
  Result := FActiveNode.InList;
end;

procedure TD3Entity.BecomeActive(const AFlags: Integer);
var
  LOldFlags: Integer;
begin
  LOldFlags := FThinkFlags;
  FThinkFlags := FThinkFlags or AFlags;
  if FThinkFlags <> 0 then
  begin
    if not IsActive then
      FActiveNode.AddToEnd(FWorld.GetActiveEntities)
    else if LOldFlags = 0 then
      // we became inactive this frame, so we have to decrease the count of entities to deactivate
      FWorld.SetNumEntitiesToDeactivate(FWorld.GetNumEntitiesToDeactivate - 1);
  end;
end;

procedure TD3Entity.BecomeInactive(const AFlags: Integer);
begin
  if FThinkFlags <> 0 then
  begin
    FThinkFlags := FThinkFlags and not AFlags;
    if (FThinkFlags = 0) and IsActive then
      FWorld.SetNumEntitiesToDeactivate(FWorld.GetNumEntitiesToDeactivate + 1);
  end;
end;

end.
