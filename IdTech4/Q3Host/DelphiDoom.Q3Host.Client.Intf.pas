{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - what the client gives to the system     }
{  calls of cgame and ui (state of the client, keys, sound, cinematics, the     }
{  renderer, the server lists)                                                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c,      }
{  cl_ui.c, cl_keys.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is   }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Client.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Client.Types;

type
  /// <summary>
  ///   cl.gameState, cl.snapshots, clc.serverCommands and cl.cmds as the system calls of cgame read them
  ///   (CL_GetGameState, CL_GetCurrentSnapshotNumber, CL_GetSnapshot, CL_GetServerCommand, CL_GetUserCmd ...)
  /// </summary>
  IQ3HostClientState = interface
    ['{91E4A7C3-2D58-4B06-A3F9-6C0D8E15B742}']
    /// <summary>The gameState_t: 20100 bytes (the offsets of the strings, the data, the count)</summary>
    function GameState: TBytes;
    /// <summary>
    ///   GetConfigString of cl_ui.c: False for an index out of range and for a string that was never set (its
    ///   offset is 0)
    /// </summary>
    function TryGetConfigString(AIndex: Integer; out AValue: AnsiString): Boolean;
    /// <summary>CL_GetCurrentSnapshotNumber</summary>
    procedure CurrentSnapshotNumber(out ANumber, AServerTime: Integer);
    /// <summary>CL_GetSnapshot: False when the snapshot is gone or was not valid; an error for a number not yet received</summary>
    function TryGetSnapshot(ANumber: Integer; out ASnapshot: TQ3HostSnapshot): Boolean;
    /// <summary>
    ///   CL_GetServerCommand: the command is tokenized for CG_ARGC and CG_ARGV; False for the commands the client
    ///   keeps for itself (the big configstrings that are not complete yet, a changed configstring that did not
    ///   change). A reliable command that was cycled out or not received yet is an error
    /// </summary>
    function GetServerCommand(ANumber: Integer): Boolean;
    /// <summary>CL_GetCurrentCmdNumber</summary>
    function CurrentCommandNumber: Integer;
    /// <summary>CL_GetUserCmd: False when the command was overwritten in the circular buffer</summary>
    function TryGetUserCmd(ANumber: Integer; out ACommand: TQ3HostUserCmd): Boolean;
    /// <summary>CL_SetUserCmdValue</summary>
    procedure SetUserCmdValue(AValue: Integer; ASensitivity: Single);
    /// <summary>CL_AddReliableCommand (CG_SENDCLIENTCOMMAND)</summary>
    procedure AddReliableCommand(const AText: AnsiString);
  end;

  /// <summary>GetClientState of cl_ui.c (the connection of the client)</summary>
  IQ3HostUiConnection = interface
    ['{4A8D1F67-B3C2-4E90-8D15-F2A6C70E9B34}']
    function GetClientState: TQ3HostUiClientState;
  end;

  /// <summary>The small calls that need the machine around the modules: the hunk, the screen, the clipboard</summary>
  IQ3HostClientSystem = interface
    ['{C7B03E52-1A94-4D68-9F2E-0B5D6A83E417}']
    /// <summary>Hunk_MemoryRemaining</summary>
    function MemoryRemaining: Integer;
    /// <summary>SCR_UpdateScreen (CG_UPDATESCREEN, UI_UPDATESCREEN)</summary>
    procedure UpdateScreen;
    /// <summary>Sys_GetClipboardData: empty when there is nothing</summary>
    function ClipboardText: AnsiString;
  end;

  /// <summary>The keys and what is bound to them (cl_keys.c)</summary>
  IQ3HostKeys = interface
    ['{2F60A9D4-85E1-4C37-B0A2-D18E3C57F946}']
    /// <summary>Key_IsDown (-1 and numbers out of 0..255 are never down)</summary>
    function IsDown(AKey: Integer): Boolean;
    function GetCatcher: Integer;
    procedure SetCatcher(AValue: Integer);
    /// <summary>Key_GetKey: the first key bound to the text (ignoring case), -1 if there is none</summary>
    function GetKey(const ABinding: AnsiString): Integer;
    /// <summary>Key_KeynumToString</summary>
    function KeynumToString(AKey: Integer): AnsiString;
    /// <summary>Key_GetBinding: empty when the key has none</summary>
    function GetBinding(AKey: Integer): AnsiString;
    procedure SetBinding(AKey: Integer; const ABinding: AnsiString);
    function GetOverstrikeMode: Boolean;
    procedure SetOverstrikeMode(AValue: Boolean);
    /// <summary>Key_ClearStates</summary>
    procedure ClearStates;
  end;

  /// <summary>The sound calls of cgame and ui (snd_public.h); the origins point into the memory of the program</summary>
  IQ3HostSound = interface
    ['{B5D82E10-7C39-4A64-8E1B-3F0A92C6D578}']
    function RegisterSound(const AName: AnsiString; ACompressed: Boolean): Integer;
    /// <summary>AOrigin is nil for a sound that follows the entity</summary>
    procedure StartSound(AOrigin: PQ3HostVec3; AEntityNumber, AEntityChannel, ASfx: Integer);
    procedure StartLocalSound(ASfx, AChannelNumber: Integer);
    procedure ClearLoopingSounds(AKillAll: Boolean);
    procedure AddLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
    procedure AddRealLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
    procedure StopLoopingSound(AEntityNumber: Integer);
    procedure UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3HostVec3);
    procedure Respatialize(AEntityNumber: Integer; const AHead: TQ3HostVec3; const AAxis: TQ3HostAxis;
      AInWater: Integer);
    procedure StartBackgroundTrack(const AIntro, ALoop: AnsiString);
    procedure StopBackgroundTrack;
  end;

  /// <summary>The cinematic calls (CIN_*); the handles and statuses are the ones of cl_cin.c</summary>
  IQ3HostCinematics = interface
    ['{E1A47D38-9B02-4F5C-A6D3-80C7B2F5149E}']
    /// <summary>CIN_PlayCinematic: the handle, -1 when the file cannot be played</summary>
    function Play(const AName: AnsiString; AX, AY, AWidth, AHeight, ASystemBits: Integer): Integer;
    /// <summary>CIN_StopCinematic: e_status</summary>
    function Stop(AHandle: Integer): Integer;
    /// <summary>CIN_RunCinematic: e_status</summary>
    function Run(AHandle: Integer): Integer;
    procedure Draw(AHandle: Integer);
    procedure SetExtents(AHandle, AX, AY, AWidth, AHeight: Integer);
  end;

  /// <summary>
  ///   The renderer as cgame and ui use it (the re.* calls of cl_cgame.c and cl_ui.c). The structures stay in the
  ///   memory of the program: the renderer reads what it needs from AMemory at the address, as the C does through
  ///   a pointer
  /// </summary>
  IQ3HostRenderer = interface
    ['{6D3B8A15-F2C7-4E09-B1A4-5E70C9D32F86}']
    procedure LoadWorld(const AName: AnsiString);
    function RegisterModel(const AName: AnsiString): Integer;
    function RegisterSkin(const AName: AnsiString): Integer;
    function RegisterShader(const AName: AnsiString): Integer;
    function RegisterShaderNoMip(const AName: AnsiString): Integer;
    /// <summary>re.RegisterFont: fills the fontInfo_t at AFontAddress</summary>
    procedure RegisterFont(const AMemory: IQvmMemory; const AName: AnsiString; APointSize, AFontAddress: Integer);
    procedure ClearScene;
    /// <summary>re.AddRefEntityToScene: the refEntity_t at the address</summary>
    procedure AddRefEntityToScene(const AMemory: IQvmMemory; AAddress: Integer);
    /// <summary>re.AddPolyToScene: ANumVerts polyVert_t at the address, ANumPolys polygons</summary>
    procedure AddPolyToScene(const AMemory: IQvmMemory; AShader, ANumVerts, AVertsAddress, ANumPolys: Integer);
    procedure AddLightToScene(const AOrigin: TQ3HostVec3; AIntensity, ARed, AGreen, ABlue: Single;
      AAdditive: Boolean);
    /// <summary>re.RenderScene: the refdef_t at the address</summary>
    procedure RenderScene(const AMemory: IQvmMemory; AAddress: Integer);
    /// <summary>re.SetColor: four floats at the address, or NULL (address 0) for white</summary>
    procedure SetColor(const AMemory: IQvmMemory; AAddress: Integer);
    procedure DrawStretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single; AShader: Integer);
    /// <summary>re.ModelBounds: writes the two vectors</summary>
    procedure ModelBounds(const AMemory: IQvmMemory; AModel, AMinsAddress, AMaxsAddress: Integer);
    /// <summary>re.LerpTag: fills the orientation_t at ATagAddress; the result is qtrue when the tag exists</summary>
    function LerpTag(const AMemory: IQvmMemory; ATagAddress, AModel, AStartFrame, AEndFrame: Integer;
      AFraction: Single; const ATagName: AnsiString): Integer;
    function InPVS(const APoint1, APoint2: TQ3HostVec3): Integer;
    /// <summary>re.LightForPoint: fills the three vectors (the lights are the addresses); qfalse when there is no light grid</summary>
    function LightForPoint(const AMemory: IQvmMemory; const APoint: TQ3HostVec3;
      AAmbientAddress, ADirectedAddress, ALightDirAddress: Integer): Integer;
    procedure RemapShader(const AOldShader, ANewShader, ATimeOffset: AnsiString);
    /// <summary>re.MarkFragments: the number of fragments written (a renderer without decals writes none)</summary>
    function MarkFragments(const AMemory: IQvmMemory; ANumPoints, APointsAddress, AProjectionAddress,
      AMaxPoints, APointBufferAddress, AMaxFragments, AFragmentBufferAddress: Integer): Integer;
    /// <summary>The glconfig_t the client keeps (cls.glconfig): 11332 bytes</summary>
    function GlConfig: TBytes;
  end;

  /// <summary>The server lists and the pings the menus show (LAN_* of cl_ui.c and the ping queue of cl_main.c)</summary>
  IQ3HostLan = interface
    ['{0C9E5B71-4D83-4A26-96F0-A7B1D3E8C254}']
    procedure LoadCachedServers;
    procedure SaveCachedServers;
    /// <summary>LAN_AddServer: 1 added, 0 already there, -1 source unknown or list full</summary>
    function AddServer(ASource: Integer; const AName, AAddress: AnsiString): Integer;
    procedure RemoveServer(ASource: Integer; const AAddress: AnsiString);
    function GetServerCount(ASource: Integer): Integer;
    function GetServerAddressString(ASource, AIndex: Integer): AnsiString;
    /// <summary>LAN_GetServerInfo: the info string ("" for an index out of range)</summary>
    function GetServerInfo(ASource, AIndex: Integer): AnsiString;
    function GetServerPing(ASource, AIndex: Integer): Integer;
    procedure MarkServerVisible(ASource, AIndex: Integer; AVisible: Boolean);
    function ServerIsVisible(ASource, AIndex: Integer): Boolean;
    function UpdateVisiblePings(ASource: Integer): Boolean;
    procedure ResetPings(ASource: Integer);
    function CompareServers(ASource, ASortKey, ASortDirection, AServer1, AServer2: Integer): Integer;
    function GetPingQueueCount: Integer;
    procedure ClearPing(AIndex: Integer);
    /// <summary>CL_GetPing: the address and the ping time; an empty slot is "" and 0</summary>
    procedure GetPing(AIndex: Integer; out AAddress: AnsiString; out APingTime: Integer);
    function GetPingInfo(AIndex: Integer): AnsiString;
    /// <summary>CL_ServerStatus: qtrue when a status string arrived (it is then AStatus)</summary>
    function ServerStatus(const AAddress: AnsiString; out AStatus: AnsiString): Integer;
  end;

implementation

end.
