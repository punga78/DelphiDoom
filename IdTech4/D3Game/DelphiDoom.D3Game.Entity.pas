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
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.Intf,
  DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Physics.Intf,
  DelphiDoom.D3Game.Clip, DelphiDoom.Collision.Types;

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
    /// <summary>gameLocal.Printf (the text ends in a line feed where the original's does)</summary>
    procedure Printf(const AText: AnsiString);
    function GetSpawnedEntities: TIdLinkList<TD3Entity>;
    /// <summary>The services of the scripts; each may be nil (the game has no script machine)</summary>
    function GetEventQueue: ID3EventQueue;
    function GetScriptFunctions: ID3ScriptFunctions;
    function GetSpawnFunctions: ID3SpawnFunctions;
    function GetScriptThreads: ID3ScriptThreads;
    /// <summary>gameLocal.clip; nil for a game with no clipping (the entities then have no clip models)</summary>
    function GetClip: TD3Clip;
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
    /// <summary>gameLocal.sortTeamMasters: the active list needs the physics team masters at the front</summary>
    procedure SetSortTeamMasters(const AValue: Boolean);
    /// <summary>gameLocal.sortPushers: the active list needs the parametric bodies at the front</summary>
    procedure SetSortPushers(const AValue: Boolean);
    /// <summary>gameLocal.world: the world entity (nil until an idWorldspawn is spawned)</summary>
    function GetWorldEntity: TD3Entity;
    procedure SetWorldEntity(const AEntity: TD3Entity);
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
    FTakeDamage: Boolean;
    FName: AnsiString;
    FSpawnArgs: TIdDict;
    FSpawnNode: TIdLinkList<TD3Entity>;
    FActiveNode: TIdLinkList<TD3Entity>;
    FGame: ID3EntityGame;
    FHidden: Boolean;
    FTargets: TList<TD3EntityPtr>;
    FPhysics: ID3Physics;
    FDefaultPhysics: ID3Physics;
    FTouchTrace: TCollisionTrace;
    FBindMaster: TD3Entity;
    FBindBody: Integer;
    FBindOrientated: Boolean;
    FTeamMaster: TD3Entity;
    FTeamChain: TD3Entity;
    FSolidForTeam: Boolean;
    FForcePhysicsUpdate: Boolean;
    FRenderOrigin: TIdVec3;
    FRenderAxis: TIdMat3;
    procedure SpawnEntity;
    procedure InitDefaultPhysics(const AOrigin: TIdVec3; const AAxis: TIdMat3);
    function InitBind(const AMaster: TD3Entity): Boolean;
    procedure FinishBind;
    procedure EventSpawnBind;
  protected
    property World: ID3EntityWorld read FWorld;
    /// <summary>The game services of the entity classes; nil if the world is not a game</summary>
    property Game: ID3EntityGame read FGame;
    /// <summary>
    ///   What the physics objects of this entity ask of it: the time, the think flags and the position of the master
    ///   (<c>self->GetMasterPosition</c>)
    /// </summary>
    function CreatePhysicsHost: TD3PhysicsHost;
    /// <summary>idEntity::PreBind (empty): a class that keeps positions in the master's space converts them here</summary>
    procedure PreBind; virtual;
    /// <summary>idEntity::PostBind (empty)</summary>
    procedure PostBind; virtual;
    procedure PreUnbind; virtual;
    procedure PostUnbind; virtual;
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
    /// <summary>
    ///   idEntity::RunPhysics: the team master runs the physics of the whole team (the clip of the parts that are not
    ///   <c>solidForTeam</c> is off meanwhile), then posts <c>&lt;reachedpos&gt;</c> and <c>&lt;reachedang&gt;</c> at the
    ///   end of a motion. Nothing is ever pushed or blocked (idPush is not ported).
    /// </summary>
    function RunPhysics: Boolean;
    function GetPhysics: ID3Physics;
    /// <summary>idEntity::SetPhysics: nil gives the entity its default (static) physics back</summary>
    procedure SetPhysics(const APhysics: ID3Physics);
    /// <summary>idEntity::SetOrigin</summary>
    procedure SetOrigin(const AOrigin: TIdVec3);
    /// <summary>idEntity::SetAxis</summary>
    procedure SetAxis(const AAxis: TIdMat3);
    /// <summary>idEntity::SetAngles</summary>
    procedure SetAngles(const AAngles: TIdAngles);
    /// <summary>idEntity::IsAtRest</summary>
    function IsAtRest: Boolean;
    /// <summary>
    ///   idEntity::UpdateModelTransform: the position of the render entity is the one of the physics. The render entity
    ///   is the position a bound entity takes from its master (<c>GetMasterPosition</c>).
    /// </summary>
    procedure UpdateModelTransform;
    /// <summary>idEntity::UpdateFromPhysics (the TH_UPDATEVISUALS flag is not ported)</summary>
    procedure UpdateFromPhysics(const AMoveBack: Boolean);
    /// <summary>idEntity::GetMasterPosition: false for an entity that is not bound</summary>
    function GetMasterPosition(out AMasterOrigin: TIdVec3; out AMasterAxis: TIdMat3): Boolean;
    /// <summary>idEntity::GetLocalVector (a world vector in the master's space)</summary>
    function GetLocalVector(const AVector: TIdVec3): TIdVec3;
    /// <summary>idEntity::GetLocalCoordinates (a world position in the master's space)</summary>
    function GetLocalCoordinates(const AVector: TIdVec3): TIdVec3;
    /// <summary>idEntity::GetWorldVector</summary>
    function GetWorldVector(const AVector: TIdVec3): TIdVec3;
    /// <summary>idEntity::GetWorldCoordinates</summary>
    function GetWorldCoordinates(const AVector: TIdVec3): TIdVec3;
    /// <summary>
    ///   idEntity::Bind: the entity follows the master; the master's position is that of its render entity. A nil
    ///   master, the entity itself or the world (<c>gameLocal.world</c>) just unbinds; an error for binding the world or
    ///   the entity to itself.
    /// </summary>
    procedure Bind(const AMaster: TD3Entity; const AOrientated: Boolean);
    /// <summary>
    ///   idEntity::BindToJoint: no entity has a skeleton here: the original warns and does nothing (after unbinding)
    /// </summary>
    procedure BindToJoint(const AMaster: TD3Entity; const AJointName: AnsiString; const AOrientated: Boolean);
    /// <summary>idEntity::BindToBody: a body of the physics of the master (all have one here: the id is ignored)</summary>
    procedure BindToBody(const AMaster: TD3Entity; const ABodyId: Integer; const AOrientated: Boolean);
    /// <summary>idEntity::Unbind</summary>
    procedure Unbind;
    /// <summary>idEntity::RemoveBinds: unbinds and removes (<c>&lt;immediateremove&gt;</c> posted) every entity bound to this one</summary>
    procedure RemoveBinds;
    function IsBound: Boolean;
    function IsBoundTo(const AMaster: TD3Entity): Boolean;
    function GetBindMaster: TD3Entity;
    /// <summary>idEntity::JoinTeam: the entity joins the physics team of the other one</summary>
    procedure JoinTeam(const ATeamMember: TD3Entity);
    /// <summary>idEntity::QuitTeam</summary>
    procedure QuitTeam;
    function GetTeamMaster: TD3Entity;
    function GetNextTeamEntity: TD3Entity;
    property BindBody: Integer read FBindBody;
    property BindOrientated: Boolean read FBindOrientated;
    /// <summary>fl.solidForTeam</summary>
    property SolidForTeam: Boolean read FSolidForTeam;
    /// <summary>renderEntity.origin</summary>
    property RenderOrigin: TIdVec3 read FRenderOrigin;
    /// <summary>renderEntity.axis</summary>
    property RenderAxis: TIdMat3 read FRenderAxis;
    /// <summary>
    ///   idEntity::TouchTriggers: sends <c>&lt;touch&gt;</c> to every trigger (an entity whose clip model has the
    ///   contents <c>CONTENTS_TRIGGER</c>) that the clip model of this entity is in, at its current position. The
    ///   game calls it from the think function of the entities that walk (<c>idPlayer</c>, <c>idAI</c>): nothing in
    ///   the original calls it for a mover. True if some trigger was touched.
    /// </summary>
    function TouchTriggers: Boolean;
    /// <summary>
    ///   The trace the entity is being touched with: valid while a <c>&lt;touch&gt;</c> event is processed (the
    ///   second argument of <c>Event_Touch( idEntity *other, trace_t *trace )</c>)
    /// </summary>
    property TouchTrace: TCollisionTrace read FTouchTrace;
    property EntityNumber: Integer read FEntityNumber write FEntityNumber;
    property EntityDefNumber: Integer read FEntityDefNumber;
    property ThinkFlags: Integer read FThinkFlags;
    property Cinematic: Boolean read FCinematic;
    property Health: Integer read FHealth;
    /// <summary>fl.takedamage: an entity that does not take damage ignores <c>Damage</c> (false until a class sets it)</summary>
    property TakeDamage: Boolean read FTakeDamage write FTakeDamage;
    /// <summary>idEntity::Pain: the entity took damage and is alive; false (it has no pain animation)</summary>
    function Pain(const ADamage: Integer): Boolean; virtual;
    /// <summary>idEntity::Killed: the entity's health went to zero or below; nothing in the base</summary>
    procedure Killed(const ADamage: Integer); virtual;
    property SpawnArgs: TIdDict read FSpawnArgs;
    /// <summary>The node of the list of all the spawned entities (<c>gameLocal.spawnedEntities</c>)</summary>
    property SpawnNode: TIdLinkList<TD3Entity> read FSpawnNode;
    /// <summary>The node of the list of the entities that think (<c>gameLocal.activeEntities</c>)</summary>
    property ActiveNode: TIdLinkList<TD3Entity> read FActiveNode;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.MathCore.Float.Conversions, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.D3Game.Types, DelphiDoom.D3Game.PhysicsStatic, DelphiDoom.D3Game.ClipModel,
  DelphiDoom.D3Game.ClipConvert;

const
  SSelfTarget = 'Entity ''%s'' is targeting itself';
  SInvalidBounds = 'Invalid bounds ''%s''-''%s'' on entity ''%s''';
  SInvalidSize = 'Invalid size ''%s'' on entity ''%s''';
  SReservedName = 'Cannot name entity ''%s''.  ''%s'' is reserved for script.';
  SUnknownDef = '*unknown*';
  SUnknownDamageDef = 'Unknown damageDef ''%s''' + #10;

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
  FBindBody := -1;
  FRenderOrigin.Zero;
  FRenderAxis := TIdMat3.Identity;
  FDefaultPhysics := TD3PhysicsStatic.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0),
    nil, nil, CreatePhysicsHost.GetMasterPosition);
  FPhysics := FDefaultPhysics;
end;

destructor TD3Entity.Destroy;
begin
  if FThinkFlags <> 0 then
    BecomeInactive(FThinkFlags);
  FActiveNode.Remove;
  // we have to set back the default physics object before unbinding because the entity specific physics object might
  // be an entity variable and as such could already be destroyed
  SetPhysics(nil);
  // remove any entities that are bound to me
  RemoveBinds;
  // unbind from master
  Unbind;
  QuitTeam;
  if FWorld.GetWorldEntity = Self then
    FWorld.SetWorldEntity(nil);
  FWorld.RemoveEntityFromHash(FName, Self);
  FWorld.UnregisterEntity(Self);
  FPhysics := nil;
  FDefaultPhysics := nil;
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
  LOrigin: TIdVec3;
  LAxis: TIdMat3;
  LAngle: Single;
begin
  FWorld.RegisterEntity(Self);

  FSpawnArgs.GetString('classname', '', LClassname);
  LDef := FWorld.FindEntityDef(LClassname);
  if Assigned(LDef) then
    FEntityDefNumber := LDef.GetIndex;

  // idGameEdit::ParseSpawnArgsToRenderEntity: the origin and the axis ("rotation", or the "angle" of the yaw)
  FSpawnArgs.GetVector('origin', '0 0 0', LOrigin);
  if not FSpawnArgs.GetMatrix('rotation', '1 0 0 0 1 0 0 0 1', LAxis) then
  begin
    LAngle := FSpawnArgs.GetFloat('angle');
    if LAngle <> 0 then
      LAxis := TIdRotationConversions.AnglesToMat(TIdAngles.Create(0, LAngle, 0))
    else
      LAxis := TIdMat3.Identity;
  end;

  FSolidForTeam := FSpawnArgs.GetBool('solidForTeam', '0');

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

  InitDefaultPhysics(LOrigin, LAxis);

  SetOrigin(LOrigin);
  SetAxis(LAxis);

  if FSpawnArgs.GetString('bind', '', LClassname) and Assigned(FGame) and Assigned(FGame.GetEvents) then
    PostEventMS(FGame.GetEvents.SpawnBind, 0);
end;

procedure TD3Entity.InitDefaultPhysics(const AOrigin: TIdVec3; const AAxis: TIdMat3);
var
  LMins: TIdVec3;
  LMaxs: TIdVec3;
  LSize: TIdVec3;
  LHasBounds: Boolean;
  LClip: TD3Clip;
  LNumSides: Integer;
  LTraceModel: TTraceModel;
  LBounds: TGeoBounds;
begin
  LMins.Zero;
  LMaxs.Zero;
  LHasBounds := False;
  if not FSpawnArgs.GetBool('noclipmodel', '0') then
  begin
    // check if mins/maxs or size key/value pairs are set
    if FSpawnArgs.GetVector('mins', '', LMins) and FSpawnArgs.GetVector('maxs', '', LMaxs) then
    begin
      LHasBounds := True;
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
      LHasBounds := True;
    end
    else
    begin
      LMins.Zero;
      LMaxs.Zero;
    end;
  end;

  LClip := nil;
  if Assigned(FGame) then
    LClip := FGame.GetClip;
  FDefaultPhysics := TD3PhysicsStatic.Create(AOrigin, LMins, LMaxs, LClip, Self, CreatePhysicsHost.GetMasterPosition);
  FPhysics := FDefaultPhysics;
  FDefaultPhysics.SetOrigin(AOrigin);
  FDefaultPhysics.SetAxis(AAxis);

  // the clip model of the bounds (the clipmodel and model keys, which name a collision model, are not ported)
  if Assigned(LClip) and LHasBounds then
  begin
    LBounds := TGeoBounds.Make(TD3ClipConvert.ToGeo(LMins), TD3ClipConvert.ToGeo(LMaxs));
    LTraceModel := TTraceModel.Create;
    try
      LNumSides := FSpawnArgs.GetInt('cylinder', '0');
      if LNumSides > 0 then
      begin
        if LNumSides < 3 then
          LNumSides := 3;
        LTraceModel.SetupCylinder(LBounds, LNumSides);
      end
      else
      begin
        LNumSides := FSpawnArgs.GetInt('cone', '0');
        if LNumSides > 0 then
        begin
          if LNumSides < 3 then
            LNumSides := 3;
          LTraceModel.SetupCone(LBounds, LNumSides);
        end
        else
          LTraceModel.SetupBox(LBounds);
      end;
      FPhysics.SetClipModel(TD3ClipModel.Create(LClip.Manager, LTraceModel));
    finally
      LTraceModel.Free;
    end;
  end;
end;

function TD3Entity.TouchTriggers: Boolean;
var
  LClip: TD3Clip;
  LModels: TList<TD3ClipModel>;
  LModel: TD3ClipModel;
  LEntity: TD3Entity;
  LTrace: TCollisionTrace;
  LBounds: TGeoBounds;
  LIndex: Integer;
  LNumEntities: Integer;
begin
  Result := False;
  if not Assigned(FGame) then
    Exit;
  LClip := FGame.GetClip;
  if not Assigned(LClip) then
    Exit;

  LTrace := Default(TCollisionTrace);
  LTrace.EndPos := TD3ClipConvert.ToGeo(GetPhysics.GetOrigin);
  LTrace.EndAxis := TD3ClipConvert.ToGeo(GetPhysics.GetAxis);

  LBounds.Mins := TD3ClipConvert.ToGeo(GetPhysics.GetAbsBoundsMin);
  LBounds.Maxs := TD3ClipConvert.ToGeo(GetPhysics.GetAbsBoundsMax);

  LNumEntities := 0;
  LModels := TList<TD3ClipModel>.Create;
  try
    LClip.ClipModelsTouchingBounds(LBounds, CONTENTS_TRIGGER, LModels, D3_MAX_GENTITIES);
    for LIndex := 0 to LModels.Count - 1 do
    begin
      LModel := LModels[LIndex];

      // don't touch it if we're the owner
      if LModel.Owner = Self then
        Continue;

      LEntity := TD3Entity(LModel.Entity);

      if not (LEntity.RespondsTo(FGame.GetEvents.Touch) or LEntity.HasSignal(D3_SIG_TOUCH)) then
        Continue;

      if GetPhysics.ClipContents(LModel) = 0 then
        Continue;

      Inc(LNumEntities);

      LTrace.C.Contents := LModel.Contents;
      LTrace.C.EntityNum := LEntity.EntityNumber;
      LTrace.C.Id := LModel.Id;

      LEntity.Signal(D3_SIG_TOUCH);
      LEntity.FTouchTrace := LTrace;
      LEntity.ProcessEntityEvent(FGame.GetEvents.Touch, Self);

      if FGame.GetEntityByNumber(FEntityNumber) = nil then
      begin
        FGame.Printf('entity was removed while touching triggers' + #10);
        Result := True;
        Exit;
      end;
    end;
  finally
    LModels.Free;
  end;
  Result := LNumEntities <> 0;
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
  // set new physics object or set the default physics if nil
  if Assigned(APhysics) then
  begin
    FDefaultPhysics.SetClipModel(nil);
    FPhysics := APhysics;
    FPhysics.Activate;
  end
  else
    FPhysics := FDefaultPhysics;
  if Assigned(FGame) then
    FPhysics.UpdateTime(FGame.GetTime);
  FPhysics.SetMaster(Assigned(FBindMaster), FBindOrientated);
end;

procedure TD3Entity.SetOrigin(const AOrigin: TIdVec3);
begin
  FPhysics.SetOrigin(AOrigin);
  UpdateModelTransform;
end;

procedure TD3Entity.SetAxis(const AAxis: TIdMat3);
begin
  FPhysics.SetAxis(AAxis);
  UpdateModelTransform;
end;

procedure TD3Entity.SetAngles(const AAngles: TIdAngles);
begin
  SetAxis(TIdRotationConversions.AnglesToMat(AAngles));
end;

function TD3Entity.IsAtRest: Boolean;
begin
  Result := GetPhysics.IsAtRest;
end;

procedure TD3Entity.UpdateModelTransform;
begin
  FRenderAxis := GetPhysics.GetAxis;
  FRenderOrigin := GetPhysics.GetOrigin;
end;

procedure TD3Entity.UpdateFromPhysics(const AMoveBack: Boolean);
begin
  UpdateModelTransform;
end;

function TD3Entity.CreatePhysicsHost: TD3PhysicsHost;
begin
  Result.GetTime :=
    function: Integer
    begin
      Result := Game.GetTime;
    end;
  Result.BecomeActive :=
    procedure(AFlags: Integer)
    begin
      BecomeActive(AFlags);
    end;
  Result.BecomeInactive :=
    procedure(AFlags: Integer)
    begin
      BecomeInactive(AFlags);
    end;
  Result.GetMasterPosition :=
    function(out AOrigin: TIdVec3; out AAxis: TIdMat3): Boolean
    begin
      Result := GetMasterPosition(AOrigin, AAxis);
    end;
end;

function TD3Entity.RunPhysics: Boolean;
var
  LStartTime: Integer;
  LEndTime: Integer;
  LReachedTime: Integer;
  LPart: TD3Entity;
  LMoved: Boolean;
begin
  // don't run physics if not enabled
  if ((FThinkFlags and D3_TH_PHYSICS) = 0) or (not Assigned(FGame)) then
    Exit(False);

  // if this entity is a team slave don't do anything because the team master will handle everything
  if Assigned(FTeamMaster) and (FTeamMaster <> Self) then
    Exit(False);

  LStartTime := FGame.GetPreviousTime;
  LEndTime := FGame.GetTime;

  // disable the team for collision detection (the state is saved by the original to move the parts back when one is
  // blocked: nothing is ever blocked here)
  LPart := Self;
  while Assigned(LPart) do
  begin
    if not LPart.FSolidForTeam then
      LPart.FPhysics.DisableClip;
    LPart := LPart.FTeamChain;
  end;

  // move the whole team
  LPart := Self;
  while Assigned(LPart) do
  begin
    // run physics
    LMoved := LPart.FPhysics.Evaluate(LEndTime - LStartTime, LEndTime);
    // if moved or forced to update the visual position and orientation from the physics
    if LMoved or LPart.FForcePhysicsUpdate then
      LPart.UpdateFromPhysics(False);
    LPart := LPart.FTeamChain;
  end;

  // enable the whole team for collision detection
  LPart := Self;
  while Assigned(LPart) do
  begin
    if not LPart.FSolidForTeam then
      LPart.FPhysics.EnableClip;
    LPart := LPart.FTeamChain;
  end;

  // post reached event if the current time is at or past the end point of the motion
  LPart := Self;
  while Assigned(LPart) do
  begin
    LReachedTime := LPart.FPhysics.GetLinearEndTime;
    if (LStartTime < LReachedTime) and (LEndTime >= LReachedTime) then
      LPart.ProcessEvent(FGame.GetEvents.ReachedPos);
    LReachedTime := LPart.FPhysics.GetAngularEndTime;
    if (LStartTime < LReachedTime) and (LEndTime >= LReachedTime) then
      LPart.ProcessEvent(FGame.GetEvents.ReachedAng);
    LPart := LPart.FTeamChain;
  end;
  Result := True;
end;

procedure TD3Entity.PreBind;
begin
end;

procedure TD3Entity.PostBind;
begin
end;

procedure TD3Entity.PreUnbind;
begin
end;

procedure TD3Entity.PostUnbind;
begin
end;

function TD3Entity.IsBound: Boolean;
begin
  Result := Assigned(FBindMaster);
end;

function TD3Entity.IsBoundTo(const AMaster: TD3Entity): Boolean;
var
  LEntity: TD3Entity;
begin
  Result := False;
  if not Assigned(FBindMaster) then
    Exit;
  LEntity := FBindMaster;
  while Assigned(LEntity) do
  begin
    if LEntity = AMaster then
      Exit(True);
    LEntity := LEntity.FBindMaster;
  end;
end;

function TD3Entity.GetBindMaster: TD3Entity;
begin
  Result := FBindMaster;
end;

function TD3Entity.GetTeamMaster: TD3Entity;
begin
  Result := FTeamMaster;
end;

function TD3Entity.GetNextTeamEntity: TD3Entity;
begin
  Result := FTeamChain;
end;

function TD3Entity.GetMasterPosition(out AMasterOrigin: TIdVec3; out AMasterAxis: TIdMat3): Boolean;
begin
  if Assigned(FBindMaster) then
  begin
    // bound to a body or to the visual position of the master (no entity has a skeleton here: the joint is never set)
    if (FBindBody >= 0) and Assigned(FBindMaster.FPhysics) then
    begin
      AMasterOrigin := FBindMaster.GetPhysics.GetOrigin;
      AMasterAxis := FBindMaster.GetPhysics.GetAxis;
    end
    else
    begin
      AMasterOrigin := FBindMaster.FRenderOrigin;
      AMasterAxis := FBindMaster.FRenderAxis;
    end;
    Result := True;
  end
  else
  begin
    AMasterOrigin.Zero;
    AMasterAxis := TIdMat3.Identity;
    Result := False;
  end;
end;

function TD3Entity.GetLocalVector(const AVector: TIdVec3): TIdVec3;
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  if not Assigned(FBindMaster) then
    Exit(AVector);
  GetMasterPosition(LMasterOrigin, LMasterAxis);
  LMasterAxis.ProjectVector(AVector, Result);
end;

function TD3Entity.GetLocalCoordinates(const AVector: TIdVec3): TIdVec3;
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  if not Assigned(FBindMaster) then
    Exit(AVector);
  GetMasterPosition(LMasterOrigin, LMasterAxis);
  LMasterAxis.ProjectVector(AVector - LMasterOrigin, Result);
end;

function TD3Entity.GetWorldVector(const AVector: TIdVec3): TIdVec3;
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  if not Assigned(FBindMaster) then
    Exit(AVector);
  GetMasterPosition(LMasterOrigin, LMasterAxis);
  LMasterAxis.UnprojectVector(AVector, Result);
end;

function TD3Entity.GetWorldCoordinates(const AVector: TIdVec3): TIdVec3;
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  if not Assigned(FBindMaster) then
    Exit(AVector);
  GetMasterPosition(LMasterOrigin, LMasterAxis);
  LMasterAxis.UnprojectVector(AVector, Result);
  Result := Result + LMasterOrigin;
end;

function TD3Entity.InitBind(const AMaster: TD3Entity): Boolean;
begin
  if AMaster = Self then
  begin
    FWorld.Error('Tried to bind an object to itself.');
    Exit(False);
  end;
  if Self = FWorld.GetWorldEntity then
  begin
    FWorld.Error('Tried to bind world to another entity');
    Exit(False);
  end;

  // unbind myself from my master
  Unbind;

  // this can happen in scripts, so safely exit out
  Result := Assigned(AMaster) and (AMaster <> FWorld.GetWorldEntity);
end;

procedure TD3Entity.FinishBind;
begin
  // set the master on the physics object
  FPhysics.SetMaster(Assigned(FBindMaster), FBindOrientated);

  // we are now separated from our previous team and are either an individual, or have a team of our own: now we can
  // join the new bindMaster's team (the bindMaster must be set before, or we are placed in the wrong position)
  JoinTeam(FBindMaster);

  // if our bindMaster is enabled during a cinematic, we must be, too
  FCinematic := FBindMaster.FCinematic;

  // make sure the team master is active so that physics get run
  FTeamMaster.BecomeActive(D3_TH_PHYSICS);
end;

procedure TD3Entity.Bind(const AMaster: TD3Entity; const AOrientated: Boolean);
begin
  if not InitBind(AMaster) then
    Exit;
  PreBind;
  FBindBody := -1;
  FBindMaster := AMaster;
  FBindOrientated := AOrientated;
  FinishBind;
  PostBind;
end;

procedure TD3Entity.BindToJoint(const AMaster: TD3Entity; const AJointName: AnsiString; const AOrientated: Boolean);
begin
  if not InitBind(AMaster) then
    Exit;
  if Assigned(FGame) then
    FGame.Warning(AnsiString(Format('idEntity::BindToJoint: entity ''%s'' cannot support skeletal models.',
      [string(AMaster.GetName)])));
end;

procedure TD3Entity.BindToBody(const AMaster: TD3Entity; const ABodyId: Integer; const AOrientated: Boolean);
begin
  if not InitBind(AMaster) then
    Exit;
  if ABodyId < 0 then
    if Assigned(FGame) then
      FGame.Warning(AnsiString(Format('idEntity::BindToBody: body ''%d'' not found.', [ABodyId])));
  PreBind;
  FBindBody := ABodyId;
  FBindMaster := AMaster;
  FBindOrientated := AOrientated;
  FinishBind;
  PostBind;
end;

procedure TD3Entity.Unbind;
var
  LPrevious: TD3Entity;
  LNext: TD3Entity;
  LLast: TD3Entity;
  LEntity: TD3Entity;
begin
  if not Assigned(FBindMaster) then
    Exit;

  if not Assigned(FTeamMaster) then
  begin
    // teammaster already has been freed
    FBindMaster := nil;
    Exit;
  end;

  PreUnbind;

  if Assigned(FPhysics) then
    FPhysics.SetMaster(False, FBindOrientated);

  // we're still part of a team, so that means I have to extricate myself and any entities that are bound to me from
  // the old team: find the node previous to me in the team
  LPrevious := FTeamMaster;
  LEntity := FTeamMaster.FTeamChain;
  while Assigned(LEntity) and (LEntity <> Self) do
  begin
    LPrevious := LEntity;
    LEntity := LEntity.FTeamChain;
  end;

  // find the last node in my team that is bound to me, and the first node not bound to me, if one exists
  LLast := Self;
  LNext := FTeamChain;
  while Assigned(LNext) do
  begin
    if not LNext.IsBoundTo(Self) then
      Break;
    // tell them I'm now the teamMaster
    LNext.FTeamMaster := Self;
    LLast := LNext;
    LNext := LNext.FTeamChain;
  end;

  // disconnect the last member of our team from the old team
  LLast.FTeamChain := nil;

  // connect up the previous member of the old team to the node that follow the last node bound to me (if one exists)
  if FTeamMaster <> Self then
  begin
    LPrevious.FTeamChain := LNext;
    if (not Assigned(LNext)) and (FTeamMaster = LPrevious) then
      LPrevious.FTeamMaster := nil;
  end
  else if Assigned(LNext) then
  begin
    // if we were the teamMaster, then the nodes that were not bound to me are now a disconnected chain: make them
    // into their own team
    LEntity := LNext;
    while Assigned(LEntity.FTeamChain) do
    begin
      LEntity.FTeamMaster := LNext;
      LEntity := LEntity.FTeamChain;
    end;
    LNext.FTeamMaster := LNext;
  end;

  // if we don't have anyone on our team, then clear the team variables
  if Assigned(FTeamChain) then
    // make myself my own team
    FTeamMaster := Self
  else
    // no longer a team
    FTeamMaster := nil;

  FBindBody := -1;
  FBindMaster := nil;

  PostUnbind;
end;

procedure TD3Entity.RemoveBinds;
var
  LEntity: TD3Entity;
  LNext: TD3Entity;
begin
  LEntity := FTeamChain;
  while Assigned(LEntity) do
  begin
    LNext := LEntity.FTeamChain;
    if LEntity.FBindMaster = Self then
    begin
      LEntity.Unbind;
      if Assigned(FGame) and Assigned(FGame.GetEvents) then
        LEntity.PostEventMS(FGame.GetEvents.Remove, 0);
      LNext := FTeamChain;
    end;
    LEntity := LNext;
  end;
end;

procedure TD3Entity.JoinTeam(const ATeamMember: TD3Entity);
var
  LEntity: TD3Entity;
  LMaster: TD3Entity;
  LPrevious: TD3Entity;
  LNext: TD3Entity;
begin
  // if we're already on a team, quit it so we can join this one
  if Assigned(FTeamMaster) and (FTeamMaster <> Self) then
    QuitTeam;

  if ATeamMember = Self then
  begin
    FTeamMaster := Self;
    Exit;
  end;

  // check if our new team mate is already on a team
  LMaster := ATeamMember.FTeamMaster;
  if not Assigned(LMaster) then
  begin
    // he's not on a team, so he's the new teamMaster
    LMaster := ATeamMember;
    ATeamMember.FTeamMaster := ATeamMember;
    ATeamMember.FTeamChain := Self;

    // make anyone who's bound to me part of the new team
    LEntity := FTeamChain;
    while Assigned(LEntity) do
    begin
      LEntity.FTeamMaster := LMaster;
      LEntity := LEntity.FTeamChain;
    end;
  end
  else
  begin
    // skip past the chain members bound to the entity we're teaming up with
    LPrevious := ATeamMember;
    LNext := ATeamMember.FTeamChain;
    if Assigned(FBindMaster) then
    begin
      // if we have a bindMaster, join after any entities bound to the entity we're joining
      while Assigned(LNext) and LNext.IsBoundTo(ATeamMember) do
      begin
        LPrevious := LNext;
        LNext := LNext.FTeamChain;
      end;
    end
    else
    begin
      // if we're not bound to someone, then put us at the end of the team
      while Assigned(LNext) do
      begin
        LPrevious := LNext;
        LNext := LNext.FTeamChain;
      end;
    end;

    // make anyone who's bound to me part of the new team and also find the last member of my team
    LEntity := Self;
    while Assigned(LEntity.FTeamChain) do
    begin
      LEntity.FTeamChain.FTeamMaster := LMaster;
      LEntity := LEntity.FTeamChain;
    end;

    LPrevious.FTeamChain := Self;
    LEntity.FTeamChain := LNext;
  end;

  FTeamMaster := LMaster;

  // reorder the active entity list
  FWorld.SetSortTeamMasters(True);
end;

procedure TD3Entity.QuitTeam;
var
  LEntity: TD3Entity;
begin
  if not Assigned(FTeamMaster) then
    Exit;

  // check if I'm the teamMaster
  if FTeamMaster = Self then
  begin
    // do we have more than one teammate?
    if not Assigned(FTeamChain.FTeamChain) then
      // no, break up the team
      FTeamChain.FTeamMaster := nil
    else
    begin
      // yes, so make the first teammate the teamMaster
      LEntity := FTeamChain;
      while Assigned(LEntity) do
      begin
        LEntity.FTeamMaster := FTeamChain;
        LEntity := LEntity.FTeamChain;
      end;
    end;
  end
  else
  begin
    // find the previous member of the teamChain
    LEntity := FTeamMaster;
    while LEntity.FTeamChain <> Self do
      LEntity := LEntity.FTeamChain;

    // remove this from the teamChain
    LEntity.FTeamChain := FTeamChain;

    // if no one is left on the team, break it up
    if not Assigned(FTeamMaster.FTeamChain) then
      FTeamMaster.FTeamMaster := nil;
  end;

  FTeamMaster := nil;
  FTeamChain := nil;
end;

procedure TD3Entity.EventSpawnBind;
var
  LBind: AnsiString;
  LJoint: AnsiString;
  LParent: TD3Entity;
  LOrientated: Boolean;
  LBodyId: Integer;
begin
  if not FSpawnArgs.GetString('bind', '', LBind) then
    Exit;
  if TIdStrings.Icmp(LBind, 'worldspawn') = 0 then
    LParent := FWorld.GetWorldEntity
  else
    LParent := FGame.FindEntity(LBind);
  LOrientated := FSpawnArgs.GetBool('bindOrientated', '1');
  if not Assigned(LParent) then
    Exit;
  // bind to a joint of the skeletal model of the parent: none has a skeleton here
  if FSpawnArgs.GetString('bindToJoint', '', LJoint) and (Length(LJoint) > 0) then
    FWorld.Error(AnsiString(Format('Cannot bind to joint ''%s'' on ''%s''.  Entity does not support skeletal models.',
      [string(LJoint), string(FName)])))
  // bind to a body of the physics object of the parent
  else if FSpawnArgs.GetInt('bindToBody', '0', LBodyId) then
    BindToBody(LParent, LBodyId, LOrientated)
  // bind to the parent
  else
    Bind(LParent, LOrientated);
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
var
  LDef: ID3EntityDef;
  LDamage: Integer;
begin
  if not FTakeDamage then
    Exit;

  LDef := FWorld.FindEntityDef(ADamageDefName);
  if not Assigned(LDef) then
    FWorld.Error(AnsiString(Format(SUnknownDamageDef, [string(ADamageDefName)])));

  LDamage := LDef.GetDict.GetInt('damage');

  // the original informs the attacker (DamageFeedback, implemented in subclasses): there is no attacker here
  if LDamage <> 0 then
  begin
    // do the damage
    Dec(FHealth, LDamage);
    if FHealth <= 0 then
    begin
      if FHealth < -999 then
        FHealth := -999;
      Killed(LDamage);
    end
    else
      Pain(LDamage);
  end;
end;

function TD3Entity.Pain(const ADamage: Integer): Boolean;
begin
  Result := False;
end;

procedure TD3Entity.Killed(const ADamage: Integer);
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
  AType.AddEvent(AEvents.RemoveBinds,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).RemoveBinds;
    end);
  AType.AddEvent(AEvents.Bind,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).Bind(TD3Entity(ATarget).EntityFromArg(AArgs[0]), True);
    end);
  AType.AddEvent(AEvents.BindPosition,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).Bind(TD3Entity(ATarget).EntityFromArg(AArgs[0]), False);
    end);
  AType.AddEvent(AEvents.Unbind,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).Unbind;
    end);
  AType.AddEvent(AEvents.SpawnBind,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Entity(ATarget).EventSpawnBind;
    end);
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
  FPhysics.UpdateTime(ATime);
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
  if (AFlags and D3_TH_PHYSICS) <> 0 then
  begin
    // enable the team master if this entity is part of a physics team
    if Assigned(FTeamMaster) and (FTeamMaster <> Self) then
      FTeamMaster.BecomeActive(D3_TH_PHYSICS)
    else if (FThinkFlags and D3_TH_PHYSICS) = 0 then
      // if this is a pusher
      if FPhysics.IsParametric then
        FWorld.SetSortPushers(True);
  end;

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
var
  LFlags: Integer;
  LEntity: TD3Entity;
begin
  LFlags := AFlags;
  if (LFlags and D3_TH_PHYSICS) <> 0 then
    // may only disable physics on a team master if no team members are running physics (or are bound to a joint:
    // none is here)
    if FTeamMaster = Self then
    begin
      LEntity := FTeamMaster.FTeamChain;
      while Assigned(LEntity) do
      begin
        if (LEntity.FThinkFlags and D3_TH_PHYSICS) <> 0 then
        begin
          LFlags := LFlags and not D3_TH_PHYSICS;
          Break;
        end;
        LEntity := LEntity.FTeamChain;
      end;
    end;

  if FThinkFlags <> 0 then
  begin
    FThinkFlags := FThinkFlags and not LFlags;
    if (FThinkFlags = 0) and IsActive then
      FWorld.SetNumEntitiesToDeactivate(FWorld.GetNumEntitiesToDeactivate + 1);
  end;

  if (LFlags and D3_TH_PHYSICS) <> 0 then
    // if this entity has a team master
    if Assigned(FTeamMaster) and (FTeamMaster <> Self) then
      // if the team master is at rest
      if FTeamMaster.IsAtRest then
        FTeamMaster.BecomeInactive(D3_TH_PHYSICS);
end;

end.
