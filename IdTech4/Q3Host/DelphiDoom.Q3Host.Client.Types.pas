{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the types of the client host            }
{  (cgame and ui)                                                               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c,      }
{  cl_ui.c, cl_keys.c, client.h, q_shared.h. Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Client.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>vec3_t</summary>
  TQ3HostVec3 = array[0..2] of Single;
  PQ3HostVec3 = ^TQ3HostVec3;
  /// <summary>vec3_t axis[3]</summary>
  TQ3HostAxis = array[0..2] of TQ3HostVec3;
  PQ3HostAxis = ^TQ3HostAxis;

  /// <summary>usercmd_t: 24 bytes as the module has them</summary>
  TQ3HostUserCmd = array[0..23] of Byte;

  /// <summary>
  ///   What CL_GetSnapshot copies into the snapshot_t of the module: the entities are numEntities entityState_t
  ///   (already cut to MAX_ENTITIES_IN_SNAPSHOT) one after the other
  /// </summary>
  TQ3HostSnapshot = record
    SnapFlags: Integer;
    ServerCommandSequence: Integer;
    Ping: Integer;
    ServerTime: Integer;
    AreaMask: array[0..31] of Byte;
    PlayerState: array[0..467] of Byte;
    NumEntities: Integer;
    Entities: TBytes;
  end;

  /// <summary>uiClientState_t (GetClientState of cl_ui.c)</summary>
  TQ3HostUiClientState = record
    ConnectPacketCount: Integer;
    ConnectionState: Integer;
    ClientNumber: Integer;
    ServerName: AnsiString;
    UpdateInfoString: AnsiString;
    MessageString: AnsiString;
  end;

  /// <summary>
  ///   One snapshot as the client keeps it (clSnapshot_t): the parser of the messages fills it; the entities are
  ///   in the circular buffer of the parsed entities
  /// </summary>
  TQ3ClientSnapshot = record
    Valid: Boolean;
    SnapFlags: Integer;
    ServerTime: Integer;
    MessageNum: Integer;
    ServerCommandNum: Integer;
    Ping: Integer;
    AreaMask: array[0..31] of Byte;
    PlayerState: array[0..467] of Byte;
    NumEntities: Integer;
    ParseEntitiesNum: Integer;
  end;

const
  Q3_MAX_CONFIGSTRINGS = 1024;
  Q3_MAX_GAMESTATE_CHARS = 16000;
  Q3_GAMESTATE_SIZE = 20100;
  Q3_GAMESTATE_DATA_OFFSET = 4096;
  Q3_GAMESTATE_COUNT_OFFSET = 20096;
  Q3_ENTITYSTATE_SIZE = 208;
  Q3_PLAYERSTATE_SIZE = 468;
  Q3_USERCMD_SIZE = 24;
  Q3_MAX_ENTITIES_IN_SNAPSHOT = 256;
  Q3_PACKET_BACKUP = 32;
  Q3_PACKET_MASK = 31;
  Q3_CMD_BACKUP = 64;
  Q3_CMD_MASK = 63;
  Q3_MAX_PARSE_ENTITIES = 2048;
  Q3_MAX_RELIABLE_COMMANDS = 64;
  Q3_BIG_INFO_STRING = 8192;
  Q3_MAX_STRING_CHARS = 1024;
  Q3_MAX_OSPATH = 260;
  Q3_MAX_NAME_LENGTH = 32;
  Q3_CS_SYSTEMINFO = 1;

  /// <summary>The offsets in snapshot_t, gameState_t, uiClientState_t, pc_token_t and glconfig_t (client-layout.golden.txt)</summary>
  Q3_SNAPSHOT_SIZE = 53772;
  Q3_SNAPSHOT_PING = 4;
  Q3_SNAPSHOT_SERVERTIME = 8;
  Q3_SNAPSHOT_AREAMASK = 12;
  Q3_SNAPSHOT_PS = 44;
  Q3_SNAPSHOT_NUMENTITIES = 512;
  Q3_SNAPSHOT_ENTITIES = 516;
  Q3_SNAPSHOT_SERVERCOMMANDSEQUENCE = 53768;
  Q3_UICLIENTSTATE_SIZE = 3084;
  Q3_UICLIENTSTATE_UPDATEINFO = 1036;
  Q3_UICLIENTSTATE_MESSAGE = 2060;
  Q3_UICLIENTSTATE_SERVERNAME = 12;
  Q3_PCTOKEN_SIZE = 1040;
  Q3_PCTOKEN_STRING = 16;
  Q3_PCTOKEN_STRING_SIZE = 1024;
  Q3_GLCONFIG_SIZE = 11332;

  /// <summary>The key catchers (KEYCATCH_*)</summary>
  Q3_KEYCATCH_CONSOLE = 1;
  Q3_KEYCATCH_UI = 2;
  Q3_KEYCATCH_MESSAGE = 4;
  Q3_KEYCATCH_CGAME = 8;

  /// <summary>The sources of the server lists (AS_*) and their sizes</summary>
  Q3_AS_LOCAL = 0;
  Q3_AS_MPLAYER = 1;
  Q3_AS_GLOBAL = 2;
  Q3_AS_FAVORITES = 3;
  Q3_MAX_GLOBAL_SERVERS = 4096;
  Q3_MAX_OTHER_SERVERS = 128;
  Q3_MAX_PINGREQUESTS = 32;

  /// <summary>The sort keys of LAN_CompareServers (SORT_*)</summary>
  Q3_SORT_HOST = 0;
  Q3_SORT_MAP = 1;
  Q3_SORT_CLIENTS = 2;
  Q3_SORT_GAME = 3;
  Q3_SORT_PING = 4;

  /// <summary>e_status of the cinematics</summary>
  Q3_FMV_IDLE = 0;
  Q3_FMV_PLAY = 1;
  Q3_FMV_EOF = 2;

  /// <summary>The Hunk_MemoryRemaining the fixed client answers (a 56 MB hunk, nothing used)</summary>
  Q3_HUNK_FREE = 56 * 1024 * 1024;

implementation

end.
