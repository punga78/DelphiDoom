{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - what the engine gives to the system    }
{  calls (files, the map, the state of the server, the clock and the commands  }
{  the server sends)                                                           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  sv_init.c, sv_bot.c, files.c. Copyright (C) 1999-2005 Id Software, Inc.     }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Services.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Intf;

type
  /// <summary>qtime_t: nine 32 bit integers (tm of the C library)</summary>
  TQ3HostRealTime = record
    Second, Minute, Hour, DayOfMonth, Month, Year, DayOfWeek, DayOfYear, IsDst: Integer;
  end;

  /// <summary>
  ///   The handle based file calls the virtual machines have (FS_FOpenFileByMode, FS_Read2, FS_Write,
  ///   FS_FCloseFile, FS_Seek, FS_ListFiles). Handle 0 is "no file"
  /// </summary>
  IQ3HostFileSystem = interface
    ['{C5E27A41-9B08-4F63-A1D4-3E7B60F8D295}']
    /// <summary>
    ///   FS_FOpenFileByMode: AMode is FS_READ 0, FS_WRITE 1, FS_APPEND 2, FS_APPEND_SYNC 3. The result is the
    ///   length of a file opened for reading, 0 for a file opened for writing, -1 when it cannot be opened (the
    ///   handle is then 0)
    /// </summary>
    function Open(const AName: AnsiString; AMode: Integer; out AHandle: Integer): Integer;
    /// <summary>FS_Read: the bytes read (less than ALength at the end of the file); handle 0 reads nothing</summary>
    function Read(AHandle: Integer; ABuffer: PByte; ALength: Integer): Integer;
    /// <summary>FS_Write: the bytes written; handle 0 writes nothing</summary>
    function Write(AHandle: Integer; ABuffer: PByte; ALength: Integer): Integer;
    /// <summary>FS_FCloseFile</summary>
    procedure Close(AHandle: Integer);
    /// <summary>FS_Seek (FS_SEEK_CUR 0, FS_SEEK_END 1, FS_SEEK_SET 2)</summary>
    function Seek(AHandle, AOffset, AOrigin: Integer): Integer;
    /// <summary>FS_ListFiles: the names in a folder with an extension ('/' = the folders), sorted, once each</summary>
    function ListFiles(const APath, AExtension: AnsiString): TArray<AnsiString>;
  end;

  /// <summary>CM_LoadMap by name: the bytes of 'maps/name.bsp' become a collision model; nil if the file is not there</summary>
  IQ3HostMapLoader = interface
    ['{18F3D6B7-4A92-4C05-8E71-D0B5A3926F4C}']
    function Load(const AName: AnsiString): IQ3CollisionModel;
  end;

  /// <summary>
  ///   The clipmap the server and the client game share (cm in the C is a global): CM_LoadMap with clientload
  ///   leaves a map that is already loaded as it is
  /// </summary>
  IQ3HostClipMap = interface
    ['{7B4C09E5-D1A8-4326-9F5E-A8C2E7013B6D}']
    function GetModel: IQ3CollisionModel;
    function GetName: AnsiString;
    /// <summary>The map as the server or the client loaded it; nil when none is loaded</summary>
    property Model: IQ3CollisionModel read GetModel;
    property Name: AnsiString read GetName;
    /// <summary>CM_LoadMap( name, qtrue ): the same name again does nothing; a map that is not there raises EQ3HostException</summary>
    procedure Load(const AName: AnsiString);
    /// <summary>The server sets the map it loaded (SV_SpawnServer)</summary>
    procedure SetModel(const AModel: IQ3CollisionModel; const AName: AnsiString);
  end;

  /// <summary>The configstrings, the user infos and the user commands the server keeps (sv and svs)</summary>
  IQ3HostServerState = interface
    ['{2E9A5C70-B3F4-48D1-A607-5C1D8E3F9B24}']
    /// <summary>sv_maxclients->integer</summary>
    function MaxClients: Integer;
    /// <summary>SV_SetConfigstring: a bad index is EQ3HostException; the same text does nothing</summary>
    procedure SetConfigstring(AIndex: Integer; const AValue: AnsiString);
    /// <summary>SV_GetConfigstring: empty for a string that was never set</summary>
    function GetConfigstring(AIndex: Integer): AnsiString;
    procedure SetUserinfo(AClient: Integer; const AValue: AnsiString);
    function GetUserinfo(AClient: Integer): AnsiString;
    /// <summary>SV_GetUsercmd: the 24 bytes of usercmd_t of the last command of the client</summary>
    function GetUsercmd(AClient: Integer): TBytes;
    /// <summary>SV_BotAllocateClient: the first free slot, which becomes active; -1 if there is none</summary>
    function BotAllocateClient: Integer;
    /// <summary>SV_BotFreeClient: the slot is free again; False if it had no game entity</summary>
    function BotFreeClient(AClient: Integer): Boolean;
  end;

  /// <summary>What the server does with the commands the game sends (SV_SendServerCommand, SV_DropClient)</summary>
  IQ3HostServerCommands = interface
    ['{A60D3B94-5E17-4F28-B9C3-71E4F8A2D056}']
    /// <summary>AClient -1: all the clients; any other number is a valid client</summary>
    procedure Send(AClient: Integer; const AText: AnsiString);
    procedure Drop(AClient: Integer; const AReason: AnsiString);
  end;

  /// <summary>Com_RealTime</summary>
  IQ3HostCalendar = interface
    ['{4D18E2A6-90C5-4B37-A8F1-E36B7C0D5192}']
    /// <summary>Fills the time and returns time( NULL ) (seconds from 1970)</summary>
    function RealTime(out ATime: TQ3HostRealTime): Integer;
  end;

implementation

end.
