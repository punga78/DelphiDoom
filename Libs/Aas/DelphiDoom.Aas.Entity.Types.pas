{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the entities of the game as the bots see them      }
{                                                                              }
{  aas_entityinfo_t of be_aas.h and bot_entitystate_t of botlib.h. Based on the  }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id    }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Entity.Types;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

const
  /// <summary>BLERR_NOAASFILE of botlib.h</summary>
  AAS_BLERR_NOAASFILE = 3;
  /// <summary>The solid types of the entities (SOLID_BBOX, SOLID_BSP of be_aas_entity.c)</summary>
  AAS_SOLID_BBOX = 2;
  AAS_SOLID_BSP = 31;
  /// <summary>ENTITYNUM_WORLD (MAX_GENTITIES - 2): the world model is never linked</summary>
  AAS_ENTITYNUM_WORLD = 1022;
  /// <summary>The entity types that the botlib knows (ET_GENERAL .. ET_MOVER)</summary>
  AAS_ET_GENERAL = 0;
  AAS_ET_PLAYER = 1;
  AAS_ET_ITEM = 2;
  AAS_ET_MISSILE = 3;
  AAS_ET_MOVER = 4;
  /// <summary>The defaults of the library variables maxclients and maxentities</summary>
  AAS_DEFAULT_MAX_CLIENTS = 128;
  AAS_DEFAULT_MAX_ENTITIES = 1024;

type
  /// <summary>bot_entitystate_t: what the game tells about an entity each frame</summary>
  TBotEntityState = record
    EntityType: Integer;
    Flags: Integer;
    Origin: TVec3;
    Angles: TVec3;
    OldOrigin: TVec3;
    Mins: TVec3;
    Maxs: TVec3;
    GroundEnt: Integer;
    Solid: Integer;
    ModelIndex: Integer;
    ModelIndex2: Integer;
    Frame: Integer;
    Event: Integer;
    EventParm: Integer;
    Powerups: Integer;
    Weapon: Integer;
    LegsAnim: Integer;
    TorsoAnim: Integer;
  end;

  PBotEntityState = ^TBotEntityState;

  /// <summary>aas_entityinfo_t: what the bots know about an entity</summary>
  TAasEntityInfo = record
    Valid: Boolean;
    EntityType: Integer;
    Flags: Integer;
    LocalTime: Single;
    UpdateTime: Single;
    Number: Integer;
    Origin: TVec3;
    Angles: TVec3;
    OldOrigin: TVec3;
    LastVisOrigin: TVec3;
    Mins: TVec3;
    Maxs: TVec3;
    GroundEnt: Integer;
    Solid: Integer;
    ModelIndex: Integer;
    ModelIndex2: Integer;
    Frame: Integer;
    Event: Integer;
    EventParm: Integer;
    Powerups: Integer;
    Weapon: Integer;
    LegsAnim: Integer;
    TorsoAnim: Integer;
  end;

  /// <summary>An entity number outside the table where the original writes past its array</summary>
  EAasEntityException = class(Exception);

implementation

end.
