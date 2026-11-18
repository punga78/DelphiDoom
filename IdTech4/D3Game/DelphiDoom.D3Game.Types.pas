{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - constants and the game exception          }
{                                                                              }
{  Port of Doom 3 (id Software): game\Game_local.h, game\Entity.h              }
{  (the constants), game\gamesys\Class.h.                                      }
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
unit DelphiDoom.D3Game.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_CLIENTS: the first entity numbers are always the clients</summary>
  D3_MAX_CLIENTS = 32;
  /// <summary>GENTITYNUM_BITS</summary>
  D3_GENTITYNUM_BITS = 12;
  /// <summary>MAX_GENTITIES</summary>
  D3_MAX_GENTITIES = 1 shl D3_GENTITYNUM_BITS;
  /// <summary>ENTITYNUM_NONE: the number of an entity that is not registered</summary>
  D3_ENTITYNUM_NONE = D3_MAX_GENTITIES - 1;
  /// <summary>ENTITYNUM_WORLD: the number of the worldspawn</summary>
  D3_ENTITYNUM_WORLD = D3_MAX_GENTITIES - 2;
  /// <summary>ENTITYNUM_MAX_NORMAL: the first number that the table does not give to an entity by itself</summary>
  D3_ENTITYNUM_MAX_NORMAL = D3_MAX_GENTITIES - 2;
  /// <summary>idGameLocal::INITIAL_SPAWN_COUNT: the spawn id of the first entity of a map</summary>
  D3_INITIAL_SPAWN_COUNT = 1;

  /// <summary>The thinkFlags of idEntity (Entity.h): TH_ALL, run the think function each frame, run physics...</summary>
  D3_TH_ALL = -1;
  D3_TH_THINK = 1;
  D3_TH_PHYSICS = 2;
  D3_TH_ANIMATE = 4;
  D3_TH_UPDATEVISUALS = 8;
  D3_TH_UPDATEPARTICLES = 16;

  /// <summary>SIG_TRIGGER: the signal of an entity that is triggered</summary>
  D3_SIG_TRIGGER = 0;

  /// <summary>USERCMD_MSEC: the length of a physics frame (1000 / 60)</summary>
  D3_USERCMD_MSEC = 1000 div 60;

  /// <summary>
  ///   <c>sizeof( eventCallback_t )</c>: the size of a pointer to a member function on the compiler that gave the
  ///   golden files (bcc32c, 8 bytes; Visual C++ 4). Only the "bytes for event callbacks" line of
  ///   <c>idClass::Init</c> shows it.
  /// </summary>
  D3_EVENT_CALLBACK_SIZE = 8;

  /// <summary>The name that the superclass of <c>idClass</c> has in its declaration (<c>#nameofsuperclass</c> of NULL)</summary>
  D3_NO_SUPERCLASS = 'NULL';
  /// <summary>The name of the base class of every game object</summary>
  D3_CLASS_NAME = 'idClass';
  /// <summary>The name of the class of the entities (the test of <c>SpawnEntityType</c>)</summary>
  D3_ENTITY_CLASS_NAME = 'idEntity';
  /// <summary>The name of the class of the world entity (<c>idWorldspawn::Type</c> in <c>SpawnMapEntities</c>)</summary>
  D3_WORLDSPAWN_CLASS_NAME = 'idWorldspawn';

type
  /// <summary>
  ///   What <c>gameLocal.Error</c> does after it has printed the message: the original leaves the game by an
  ///   exception (<c>common->Error</c> with ERP_DROP). The text is the message as printed.
  /// </summary>
  ED3GameException = class(Exception);

implementation

end.
