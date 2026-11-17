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
  System.SysUtils, DelphiDoom.IdLib.Containers.LinkList, DelphiDoom.Scanner.IdDict, DelphiDoom.D3Game.Intf,
  DelphiDoom.D3Game.ClassBase;

type
  TD3Entity = class;

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
    procedure SpawnEntity;
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
  DelphiDoom.D3Game.Types;

const
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
end;

destructor TD3Entity.Destroy;
begin
  if FThinkFlags <> 0 then
    BecomeInactive(FThinkFlags);
  FActiveNode.Remove;
  FWorld.RemoveEntityFromHash(FName, Self);
  FWorld.UnregisterEntity(Self);
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

  FCinematic := FSpawnArgs.GetBool('cinematic', '0');

  // every object will have a unique name
  SetName(FSpawnArgs.GetString('name', AnsiString(Format('%s_%s_%d', [string(GetClassname),
    string(FSpawnArgs.GetString('classname')), FEntityNumber]))));

  FHealth := FSpawnArgs.GetInt('health');
end;

procedure TD3Entity.Think;
begin
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
