{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the contracts of the bot library       }
{  bridge (the BOTLIB system calls of qagame)                                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_bot.c,       }
{  botlib.h, be_interface.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Facade.Intf,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Entity.Types;

type
  /// <summary>
  ///   What the bot library asks of the server and is not the world (sv_bot.c and sv_client.c): the commands of a
  ///   bot, the reliable commands the bot "receives", the entities of its last snapshot and its user command
  /// </summary>
  IQ3HostBotServer = interface
    ['{B2D84F31-6A07-4E95-8C13-5F0A7D9E2B46}']
    /// <summary>
    ///   BotClientCommand: SV_ExecuteClientCommand( client, command, qtrue ). The machine is the game that is
    ///   calling: the command ends in it (GAME_CLIENT_COMMAND, a nested call)
    /// </summary>
    procedure ClientCommand(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString);
    /// <summary>
    ///   SV_BotGetConsoleMessage: the next reliable server command of the client that it has not seen (False when
    ///   there is none)
    /// </summary>
    function ConsoleMessage(AClient: Integer; out AText: AnsiString): Boolean;
    /// <summary>SV_BotGetSnapshotEntity: the number of the sequence-th entity of the last snapshot, -1 past the end</summary>
    function SnapshotEntity(AClient, ASequence: Integer): Integer;
    /// <summary>
    ///   SV_ClientThink, the first part: the 24 bytes become the last user command of the client; True if the client
    ///   is active (the caller then makes the game think: GAME_CLIENT_THINK)
    /// </summary>
    function UserCommand(AClient: Integer; const ACommand: TBytes): Boolean;
  end;

  /// <summary>
  ///   What the engine gives to the bridge of the bot library. Without Files the group of system calls is not
  ///   registered. A nil Server answers as a server with no clients that ever received a command or a snapshot
  /// </summary>
  TQ3HostBotServices = record
    /// <summary>The botfiles of the game ("botfiles/syn.c", the characters, the weights, the .aas of the maps)</summary>
    Files: IBotFileSource;
    Server: IQ3HostBotServer;
    /// <summary>random() of the library; nil is the generator of the Microsoft C runtime, seed 1</summary>
    Random: IBotRandom;
  end;

  /// <summary>
  ///   The AAS half of the botlib export table (aas_export_t of botlib.h) with the guards of the C when no map is
  ///   loaded or the AAS is not initialized
  /// </summary>
  IQ3BotAas = interface
    ['{B2D84F31-6A07-4E95-8C13-5F0A7D9E2B47}']
    /// <summary>AAS_EntityInfo: zeroed (with a message) when the AAS is not initialized or the entity is out of range</summary>
    function EntityInfo(AEntity: Integer): TAasEntityInfo;
    function Initialized: Boolean;
    procedure PresenceTypeBoundingBox(APresenceType: Integer; out AMins, AMaxs: TVec3);
    function Time: Single;
    function PointAreaNum(const APoint: TVec3): Integer;
    /// <summary>AAS_PointReachabilityAreaIndex; a nil point is the total of the reachability areas of all the clusters</summary>
    function PointReachabilityAreaIndex(const APoint: PVec3): Integer;
    function TraceAreas(const AStart, AEnd: TVec3; AMaxAreas: Integer; out AAreas: TArray<Integer>;
      out APoints: TArray<TVec3>): Integer;
    function BBoxAreas(const AAbsMins, AAbsMaxs: TVec3; AMaxAreas: Integer): TArray<Integer>;
    /// <summary>AAS_AreaInfo: sizeof( aas_areainfo_t ) or 0 (and AInfo untouched)</summary>
    function AreaInfo(AAreaNum: Integer; out AInfo: TAasAreaInfo): Integer;
    function PointContents(const APoint: TVec3): Integer;
    function NextBspEntity(AEntity: Integer): Integer;
    function ValueForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: AnsiString;
      ASize: Integer): Boolean;
    function VectorForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: TVec3): Boolean;
    function FloatForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: Single): Boolean;
    function IntForBspEpairKey(AEntity: Integer; const AKey: AnsiString; out AValue: Integer): Boolean;
    function AreaReachability(AAreaNum: Integer): Integer;
    function AreaTravelTimeToGoalArea(AAreaNum: Integer; const AOrigin: PVec3; AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    function EnableRoutingArea(AAreaNum, AEnable: Integer): Integer;
    function PredictRoute(var ARoute: TAasPredictRoute; AAreaNum: Integer; const AOrigin: TVec3; AGoalAreaNum,
      ATravelFlags, AMaxAreas, AMaxTime, AStopEvent, AStopContents, AStopTravelFlags, AStopAreaNum: Integer): Boolean;
    function AlternativeRouteGoals(const AStart: TVec3; AStartAreaNum: Integer; const AGoal: TVec3; AGoalAreaNum,
      ATravelFlags: Integer; var AGoals: TArray<TAasAltRouteGoal>; AMaxGoals, AType: Integer): Integer;
    function Swimming(const AOrigin: TVec3): Boolean;
    function PredictClientMovement(out AMove: TAasClientMove; AEntityNum: Integer; const AOrigin: TVec3;
      APresenceType: Integer; AOnGround: Boolean; const AVelocity, ACmdMove: TVec3; ACmdFrames, AMaxFrames: Integer;
      AFrameTime: Single; AStopEvent, AStopAreaNum: Integer; AVisualize: Boolean): Boolean;
  end;

  /// <summary>
  ///   The bot library of the game (botlib_export_t: be_interface.c): Setup, Shutdown, library variables, the frame,
  ///   the map and the entities, and the systems that live between a Setup and a Shutdown. Ai and Aas are nil
  ///   until the library is set up; a call before Setup prints the message of the C and answers BLERR_LIBRARYNOTSETUP
  /// </summary>
  IQ3BotLibrary = interface
    ['{B2D84F31-6A07-4E95-8C13-5F0A7D9E2B48}']
    /// <summary>
    ///   The module that makes the call that is being answered: its memory holds the entities of the world the
    ///   library traces through, and it is the game that receives the commands of the bots
    /// </summary>
    procedure Attach(const AMachine: IQvmMachine);
    function IsSetup: Boolean;
    /// <summary>Export_BotLibSetup: the BLERR_ code of the first system that fails to set up</summary>
    function Setup: Integer;
    function Shutdown: Integer;
    function LibVarSet(const AName, AValue: AnsiString): Integer;
    function LibVarGet(const AName: AnsiString; ASize: Integer): AnsiString;
    function StartFrame(ATime: Single): Integer;
    function LoadMap(const AMapName: AnsiString): Integer;
    /// <summary>Export_BotLibUpdateEntity; a nil state unlinks the entity</summary>
    function UpdateEntity(AEntity: Integer; const AState: PBotEntityState): Integer;
    function Ai: IBotAi;
    function Aas: IQ3BotAas;
  end;

const
  /// <summary>BLERR_LIBRARYNOTSETUP, BLERR_INVALIDENTITYNUMBER of botlib.h</summary>
  Q3BOT_BLERR_LIBRARYNOTSETUP = 1;
  Q3BOT_BLERR_INVALIDENTITYNUMBER = 2;

implementation

end.
