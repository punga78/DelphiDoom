{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the server in one process              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_init.c       }
{  (SV_Init cvars, SV_SpawnServer), sv_ccmds.c (SV_Map_f, SV_MapRestart_f),    }
{  sv_client.c (SV_DirectConnect, SV_DropClient, SV_SendClientGameState,       }
{  SV_ClientEnterWorld, SV_ExecuteClientCommand, SV_ClientCommand,             }
{  SV_ClientThink, SV_UserMove, SV_UserinfoChanged, SV_ExecuteClientMessage),  }
{  sv_main.c (SV_Frame, SV_CheckTimeouts), sv_snapshot.c                       }
{  (SV_SendClientMessages, SV_SendClientSnapshot, SV_SendMessageToClient,      }
{  SV_RateMsec), sv_game.c (SV_InitGameVM, SV_RestartGameProgs,                }
{  SV_ShutdownGameProgs) and sv_bot.c (SV_BotFrame). Copyright (C) 1999-2005   }
{  Id Software, Inc. This unit is derived from the Quake III Arena source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Server;

// Overflow and range checks are off: times and counters are 32 bit ints of the C.

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Console.Q3.Types, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message, DelphiDoom.Scanner.Q3.SourceHandles,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.ClipMap,
  DelphiDoom.Q3Host.ServerState, DelphiDoom.Q3Host.GameWorld, DelphiDoom.Q3Host.EntityTokens, DelphiDoom.Q3Host.ServerSnapshots,
  DelphiDoom.Q3Host.Server.Intf, DelphiDoom.Q3Host.Bot.Server;

type
  /// <summary>
  ///   What the server is given. The console is the one of the process (the cvars of the server are created on it
  ///   when the server is); the others are the services of the host of qagame
  /// </summary>
  TQ3ServerSettings = record
    Files: IGameFileSystem;
    Console: TQ3Console;
    /// <summary>Com_Printf of the game and of the server</summary>
    Print: IQ3HostConsole;
    Calendar: IQ3HostCalendar;
    /// <summary>Sys_Milliseconds: com_frameTime (the server id) and the seed that GAME_INIT gets</summary>
    Time: IQ3HostTime;
    /// <summary>Where the messages go; nil: nobody receives them</summary>
    Output: IQ3ServerOutput;
    Limits: TQvmLimits;
    /// <summary>The sources of botlib (shared with the client), nil: the bots have no precompiler table</summary>
    Sources: TQ3SourceHandles;
    /// <summary>
    ///   Puts something around the host of qagame before the machine is made (the tests count the calls this way);
    ///   nil: the host itself
    /// </summary>
    WrapGameHost: TFunc<IQvmHost, IQvmHost>;
    /// <summary>PROTOCOL_VERSION: 68 (Quake III 1.32), 71 (OpenArena 0.8.8 clients)</summary>
    Protocol: Integer;
    /// <summary>com_cl_running: a client in the same process (the flood protection of the commands is off)</summary>
    ClientRunning: Boolean;
    /// <summary>
    ///   A dedicated server writes to its console the print commands that go to every client (the C: com_dedicated, "broadcast: ..."):
    ///   the messages of the game like "X entered the game"
    /// </summary>
    EchoBroadcast: Boolean;
  end;

  /// <summary>
  ///   The lado server of a game in memory: it starts a map (SV_SpawnServer), runs the frames of qagame, lets
  ///   clients connect, enter the world and play (the messages of the client come in through
  ///   ExecuteClientMessage), builds and sends the snapshots, and drops the clients. The messages leave through
  ///   IQ3ServerOutput, so the same server runs in a loop with a client in memory or behind a netchan.
  ///   Differences from the C: no master servers, heartbeats, rcon, downloads, pure servers (sv_pure stays 0, the
  ///   cp and vdr commands do nothing), no authorize server (every challenge is accepted), no ping calculation
  ///   (ps.ping stays 0), clients with no gamestate yet (CS_CONNECTED) get no snapshot, a client that is dropped
  ///   gets its disconnect command in a message with the commands only, and only loopback addresses are LAN
  ///   addresses for the rate
  /// </summary>
  TQ3Server = class
  strict private
    const
      MAX_CLIENTS = 64;
      CS_SERVERINFO = 0;
      CS_SYSTEMINFO = 1;
      CS_WARMUP = 5;
      GAME_FRAME_SETTLE = 3;
      HEADER_RATE_BYTES = 48;
    type
      TClientInfo = record
        Used: Boolean;
        IsBot: Boolean;
        Address: TQ3NetAddress;
        QPort: Integer;
        Challenge: Integer;
        Name: AnsiString;
        LastUsercmd: TQ3UserCmd;
        LastClientCommandString: AnsiString;
        MessageAcknowledge: Integer;
        ReliableAcknowledge: Integer;
        NextReliableTime: Integer;
        NextSnapshotTime: Integer;
        LastPacketTime: Integer;
        LastConnectTime: Integer;
        GamestateMessageNum: Integer;
        SnapshotMsec: Integer;
        Rate: Integer;
        TimeoutCount: Integer;
      end;
      TChallenge = record
        Address: TQ3NetAddress;
        Challenge: Integer;
        Time: Integer;
        Used: Boolean;
      end;
      /// <summary>What the game sees as the commands of the server: the object is the game's, not the server's</summary>
      TGameCommands = class(TInterfacedObject, IQ3HostServerCommands)
      strict private
        FServer: TQ3Server;
      public
        constructor Create(const AServer: TQ3Server);
        procedure Send(AClient: Integer; const AText: AnsiString);
        procedure Drop(AClient: Integer; const AReason: AnsiString);
      end;
    var
      FSettings: TQ3ServerSettings;
      FCoder: IQ3HuffmanCoder;
      FClipMap: IQ3HostClipMap;
      FWorld: TQ3GameWorld;
      FTokens: TQ3EntityTokens;
      FState: TQ3HostServerState;
      FStateIntf: IQ3HostServerState;
      FSnaps: TQ3ServerSnapshots;
      FSnapsIntf: IQ3HostServerCommands;
      FCommandsIntf: IQ3HostServerCommands;
      FBotServer: TQ3HostBotServer;
      FBotServerIntf: IInterface;
      FGameHost: IQ3SyscallHost;
      FGameKeeper: IQvmHost;
      FGame: IQvmMachine;
      FGameFile: TBytes;
      FClients: array[0..MAX_CLIENTS - 1] of TClientInfo;
      FChallenges: array[0..63] of TChallenge;
      FNextChallenge: Integer;
      FRunning: Boolean;
      FInGame: Boolean;
      FRestarting: Boolean;
      FTime: Integer;
      FTimeResidual: Integer;
      FRestartTime: Integer;
      FServerId: Integer;
      FRestartedServerId: Integer;
      FChecksumFeed: Integer;
      FMapName: AnsiString;
      FPrintIntf: IQ3HostConsole;
    function MaxClients: Integer;
    function IntegerCVar(const AName: AnsiString): Integer;
    procedure SetCVar(const AName, AValue: AnsiString);
    procedure InitCVars;
    procedure Print(const AText: AnsiString);
    procedure ShutdownGameProgs;
    procedure SendServerCommand(AClient: Integer; const AText: AnsiString);
    procedure InitGameVM(ARestart: Boolean);
    procedure BotFrame(ATime: Integer);
    procedure RunGameFrame;
    procedure CreateLevel(const AMapName: AnsiString);
    procedure CreateGame;
    function GameDeniedText(AResult: Integer): AnsiString;
    procedure SyncBots;
    procedure UserinfoChanged(AClient: Integer);
    procedure ExecuteClientCommand(AClient: Integer; const AText: AnsiString; AClientOK: Boolean);
    function ClientCommand(AClient: Integer; AMessage: TQ3Message): Boolean;
    procedure UserMove(AClient: Integer; AMessage: TQ3Message; ADelta: Boolean);
    procedure ClientThink(AClient: Integer; const ACommand: TQ3UserCmd);
    procedure SendMessageToClient(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
    function RateMsec(AClient, AMessageSize: Integer): Integer;
    procedure SendClientSnapshot(AClient: Integer);
    procedure SendClientMessages;
    procedure CheckTimeouts;
    class function UserCmdBytes(const ACommand: TQ3UserCmd): TBytes; static;
    class function SameBaseAddress(const AFirst, ASecond: TQ3NetAddress): Boolean; static;
    class function AddressText(const AAddress: TQ3NetAddress): AnsiString; static;
    function GetClientPhase(AClient: Integer): TQ3ServerClientPhase;
    function GetClientIsBot(AClient: Integer): Boolean;
  public
    constructor Create(const ASettings: TQ3ServerSettings);
    destructor Destroy; override;
    /// <summary>SV_SpawnServer: a new level; the clients that are connected get the new gamestate on their next packet</summary>
    procedure SpawnServer(const AMapName: AnsiString; AKillBots: Boolean);
    /// <summary>
    ///   SV_Map_f: False (and a message) if the level is not there; the bots are dropped
    /// </summary>
    function Map(const AMapName: AnsiString): Boolean;
    /// <summary>SV_MapRestart_f with its delay in seconds (the console default is 5, 0 restarts now)</summary>
    procedure MapRestart(ADelay: Integer);
    /// <summary>
    ///   SVC_GetChallenge: the challenge a client has to repeat in its connect (the answer "challengeResponse n" goes
    ///   to the output)
    /// </summary>
    procedure GetChallenge(const AFrom: TQ3NetAddress);
    /// <summary>
    ///   SV_DirectConnect: the slot of the client, or -1 when the connect was rejected (the reason went to the
    ///   output as a "print" packet). AUserinfo is the string of the connect command
    /// </summary>
    function DirectConnect(const AFrom: TQ3NetAddress; const AUserinfo: AnsiString): Integer;
    /// <summary>SV_DropClient: the client becomes a zombie, the game is told, everybody is told why</summary>
    procedure DropClient(AClient: Integer; const AReason: AnsiString);
    /// <summary>
    ///   SV_ExecuteClientMessage: a message of a client as the netchan gives it (the sequence is already taken
    ///   off). The packet counts for the timeout of the client
    /// </summary>
    procedure ExecuteClientMessage(AClient: Integer; const AData: TBytes; ALength: Integer);
    /// <summary>SV_SendClientGameState</summary>
    procedure SendClientGameState(AClient: Integer);
    /// <summary>SV_ClientEnterWorld</summary>
    procedure ClientEnterWorld(AClient: Integer; const ACommand: TQ3UserCmd);
    /// <summary>SV_Frame: AMsec of real time since the last call</summary>
    procedure Frame(AMsec: Integer);
    /// <summary>The slot that a connect from the address and qport uses, or -1</summary>
    function FindClient(const AAddress: TQ3NetAddress; AQPort: Integer): Integer;
    /// <summary>Where the messages go (the server and its output refer to each other, so it is set after Create)</summary>
    procedure SetOutput(const AOutput: IQ3ServerOutput);
    /// <summary>The slots that are CS_CONNECTED or more (not the zombies)</summary>
    function ConnectedCount: Integer;
    /// <summary>client->netchan.qport</summary>
    function ClientQPort(AClient: Integer): Integer;
    /// <summary>PROTOCOL_VERSION of the server</summary>
    function Protocol: Integer;
    /// <summary>client->challenge: the key of the xor of the messages</summary>
    function ClientChallenge(AClient: Integer): Integer;
    /// <summary>client->lastClientCommandString</summary>
    function ClientLastCommand(AClient: Integer): AnsiString;
    property IsRunning: Boolean read FRunning;
    /// <summary>svs.time</summary>
    property Time: Integer read FTime;
    property ServerId: Integer read FServerId;
    property ChecksumFeed: Integer read FChecksumFeed;
    property MapName: AnsiString read FMapName;
    property Game: IQvmMachine read FGame;
    property Snapshots: TQ3ServerSnapshots read FSnaps;
    property ServerState: TQ3HostServerState read FState;
    property ClientPhase[AClient: Integer]: TQ3ServerClientPhase read GetClientPhase;
    property ClientIsBot[AClient: Integer]: Boolean read GetClientIsBot;
  end;

implementation

uses
  System.Classes, System.Math, DelphiDoom.Console.Q3.CVar, DelphiDoom.Console.Q3.Intf, DelphiDoom.Net.Q3.Factory,
  DelphiDoom.Net.Q3.InfoString, DelphiDoom.Net.Q3.UserCmdCodec, DelphiDoom.Net.Q3.HashKey, DelphiDoom.IdLib.Hashing.Md4,
  DelphiDoom.Qvm.Factory, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.GameFiles,
  DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.Bot.Files;

resourcestring
  SNoGame = 'The server has no game';
  SServerFull = 'server is full on local connect';
  SBadClientNumber = 'SV: bad client number %d';

const
  // MAX_RELIABLE_COMMANDS
  RELIABLE_COMMANDS = 64;

function CAtoi(const AText: AnsiString): Integer;
var
  LIndex, LSign: Integer;
begin
  Result := 0;
  LIndex := 1;
  while (LIndex <= Length(AText)) and (AText[LIndex] in [' ', #9, #10, #13]) do
    Inc(LIndex);
  LSign := 1;
  if (LIndex <= Length(AText)) and (AText[LIndex] in ['-', '+']) then
  begin
    if AText[LIndex] = '-' then
      LSign := -1;
    Inc(LIndex);
  end;
  while (LIndex <= Length(AText)) and (AText[LIndex] in ['0'..'9']) do
  begin
    Result := Result * 10 + (Ord(AText[LIndex]) - Ord('0'));
    Inc(LIndex);
  end;
  Result := Result * LSign;
end;

{ TQ3Server.TGameCommands }

constructor TQ3Server.TGameCommands.Create(const AServer: TQ3Server);
begin
  inherited Create;
  FServer := AServer;
end;

procedure TQ3Server.TGameCommands.Send(AClient: Integer; const AText: AnsiString);
begin
  FServer.SendServerCommand(AClient, AText);
end;

procedure TQ3Server.TGameCommands.Drop(AClient: Integer; const AReason: AnsiString);
begin
  FServer.DropClient(AClient, AReason);
end;

{ TQ3Server }

constructor TQ3Server.Create(const ASettings: TQ3ServerSettings);
var
  LIndex: Integer;
begin
  inherited Create;
  FSettings := ASettings;
  if FSettings.Protocol = 0 then
    FSettings.Protocol := 68;
  FCoder := TQ3NetFactory.CreateMessageHuffman;
  FPrintIntf := FSettings.Print;
  InitCVars;
  FState := TQ3HostServerState.Create(FSettings.Console.CVars);
  FStateIntf := FState;
  FState.OnConfigstringChanged :=
    procedure(AIndex: Integer; const AValue: AnsiString)
    begin
      if Assigned(FSnaps) then
        FSnaps.ConfigstringChanged(AIndex, AValue);
    end;
  for LIndex := 0 to MAX_CLIENTS - 1 do
    FClients[LIndex].GamestateMessageNum := -1;
end;

destructor TQ3Server.Destroy;
begin
  FGame := nil;
  FGameKeeper := nil;
  FGameHost := nil;
  FSnapsIntf := nil;
  FSnaps := nil;
  FCommandsIntf := nil;
  FBotServerIntf := nil;
  FTokens.Free;
  FWorld.Free;
  inherited Destroy;
end;

function TQ3Server.MaxClients: Integer;
begin
  Result := Min(MAX_CLIENTS, FState.MaxClients);
end;

function TQ3Server.IntegerCVar(const AName: AnsiString): Integer;
begin
  Result := FSettings.Console.CVars.VariableIntegerValue(AName);
end;

procedure TQ3Server.SetCVar(const AName, AValue: AnsiString);
begin
  FSettings.Console.CVars.Set2(AName, AValue, True);
end;

// SV_Init: the variables of the server with the flags the C gives them
procedure TQ3Server.InitCVars;
var
  LCVars: IQ3CVarSystem;
begin
  LCVars := FSettings.Console.CVars;
  LCVars.Get('dmflags', '0', Q3_CVAR_SERVERINFO);
  LCVars.Get('fraglimit', '20', Q3_CVAR_SERVERINFO);
  LCVars.Get('timelimit', '0', Q3_CVAR_SERVERINFO);
  LCVars.Get('g_gametype', '0', Q3_CVAR_SERVERINFO or Q3_CVAR_LATCH);
  LCVars.Get('sv_keywords', '', Q3_CVAR_SERVERINFO);
  LCVars.Get('protocol', AnsiString(IntToStr(FSettings.Protocol)), Q3_CVAR_SERVERINFO or Q3_CVAR_ROM);
  LCVars.Get('mapname', 'nomap', Q3_CVAR_SERVERINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_privateClients', '0', Q3_CVAR_SERVERINFO);
  LCVars.Get('sv_hostname', 'noname', Q3_CVAR_SERVERINFO or Q3_CVAR_ARCHIVE);
  LCVars.Get('sv_maxclients', '8', Q3_CVAR_SERVERINFO or Q3_CVAR_LATCH);
  LCVars.Get('sv_maxRate', '0', Q3_CVAR_ARCHIVE or Q3_CVAR_SERVERINFO);
  LCVars.Get('sv_minPing', '0', Q3_CVAR_ARCHIVE or Q3_CVAR_SERVERINFO);
  LCVars.Get('sv_maxPing', '0', Q3_CVAR_ARCHIVE or Q3_CVAR_SERVERINFO);
  LCVars.Get('sv_floodProtect', '1', Q3_CVAR_ARCHIVE or Q3_CVAR_SERVERINFO);
  LCVars.Get('sv_cheats', '1', Q3_CVAR_SYSTEMINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_serverid', '0', Q3_CVAR_SYSTEMINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_pure', '0', Q3_CVAR_SYSTEMINFO or Q3_CVAR_INIT or Q3_CVAR_ROM);
  LCVars.Get('sv_paks', '', Q3_CVAR_SYSTEMINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_pakNames', '', Q3_CVAR_SYSTEMINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_referencedPaks', '', Q3_CVAR_SYSTEMINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_referencedPakNames', '', Q3_CVAR_SYSTEMINFO or Q3_CVAR_ROM);
  LCVars.Get('sv_privatePassword', '', Q3_CVAR_TEMP);
  LCVars.Get('sv_fps', '20', Q3_CVAR_TEMP);
  LCVars.Get('sv_timeout', '200', Q3_CVAR_TEMP);
  LCVars.Get('sv_zombietime', '2', Q3_CVAR_TEMP);
  LCVars.Get('nextmap', '', Q3_CVAR_TEMP);
  LCVars.Get('sv_allowDownload', '0', Q3_CVAR_SERVERINFO);
  LCVars.Get('sv_reconnectlimit', '3', 0);
  LCVars.Get('sv_mapChecksum', '', Q3_CVAR_ROM);
  LCVars.Get('sv_lanForceRate', '1', Q3_CVAR_ARCHIVE);
  LCVars.Get('cl_paused', '0', Q3_CVAR_ROM);
  LCVars.Get('g_doWarmup', '0', Q3_CVAR_SERVERINFO);
  LCVars.Get('bot_enable', '1', Q3_CVAR_LATCH);
end;

procedure TQ3Server.Print(const AText: AnsiString);
begin
  if Assigned(FPrintIntf) then
    FPrintIntf.Print(AText);
end;

class function TQ3Server.UserCmdBytes(const ACommand: TQ3UserCmd): TBytes;
begin
  SetLength(Result, SizeOf(TQ3UserCmd));
  Move(ACommand, Result[0], SizeOf(TQ3UserCmd));
end;

class function TQ3Server.SameBaseAddress(const AFirst, ASecond: TQ3NetAddress): Boolean;
begin
  // NET_CompareBaseAdr: the type and the address, not the port
  if AFirst.AddressType <> ASecond.AddressType then
    Exit(False);
  case TQ3NetAddressType(AFirst.AddressType) of
    natLoopback:
      Result := True;
    natIp:
      Result := CompareMem(@AFirst.Ip[0], @ASecond.Ip[0], 4);
    natIpx:
      Result := CompareMem(@AFirst.Ipx[0], @ASecond.Ipx[0], 10);
  else
    Result := False;
  end;
end;

class function TQ3Server.AddressText(const AAddress: TQ3NetAddress): AnsiString;
begin
  // NET_AdrToString
  case TQ3NetAddressType(AAddress.AddressType) of
    natLoopback:
      Result := 'loopback';
    natBot:
      Result := 'bot';
    natIp:
      Result := AnsiString(Format('%d.%d.%d.%d:%d', [AAddress.Ip[0], AAddress.Ip[1], AAddress.Ip[2],
        AAddress.Ip[3], Swap(AAddress.Port)]));
  else
    Result := 'unknown';
  end;
end;

function TQ3Server.GetClientPhase(AClient: Integer): TQ3ServerClientPhase;
begin
  if not Assigned(FSnaps) then
    Exit(TQ3ServerClientPhase.Free);
  Result := FSnaps.Phase(AClient);
end;

function TQ3Server.GetClientIsBot(AClient: Integer): Boolean;
begin
  Result := FClients[AClient].IsBot;
end;

function TQ3Server.FindClient(const AAddress: TQ3NetAddress; AQPort: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MaxClients - 1 do
    if FClients[LIndex].Used and (FSnaps.Phase(LIndex) <> TQ3ServerClientPhase.Free) and
      SameBaseAddress(AAddress, FClients[LIndex].Address) and
      ((FClients[LIndex].QPort = AQPort) or (AAddress.Port = FClients[LIndex].Address.Port)) then
      Exit(LIndex);
  Result := -1;
end;

procedure TQ3Server.SetOutput(const AOutput: IQ3ServerOutput);
begin
  FSettings.Output := AOutput;
end;

function TQ3Server.ConnectedCount: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  if not Assigned(FSnaps) then
    Exit;
  for LIndex := 0 to MaxClients - 1 do
    if FSnaps.Phase(LIndex) >= TQ3ServerClientPhase.Connected then
      Inc(Result);
end;

function TQ3Server.ClientQPort(AClient: Integer): Integer;
begin
  Result := FClients[AClient].QPort;
end;

function TQ3Server.Protocol: Integer;
begin
  Result := FSettings.Protocol;
end;

function TQ3Server.ClientChallenge(AClient: Integer): Integer;
begin
  Result := FClients[AClient].Challenge;
end;

function TQ3Server.ClientLastCommand(AClient: Integer): AnsiString;
begin
  Result := FClients[AClient].LastClientCommandString;
end;

// SV_SendServerCommand: a dedicated server echoes the print commands for everybody (SV_ExpandNewlines: a new line is written \n)
procedure TQ3Server.SendServerCommand(AClient: Integer; const AText: AnsiString);
begin
  FSnaps.Send(AClient, AText);
  if FSettings.EchoBroadcast and (AClient < 0) and (Copy(AText, 1, 5) = 'print') then
    Print('broadcast: ' + AnsiString(StringReplace(string(AText), #10, '\n', [rfReplaceAll])) + #10);
end;

// SV_ShutdownGameProgs
procedure TQ3Server.ShutdownGameProgs;
begin
  if not Assigned(FGame) then
    Exit;
  FGame.Call(GAME_SHUTDOWN, [0]);
  FGame := nil;
  FGameKeeper := nil;
  FGameHost := nil;
end;

// SV_InitGameVM
procedure TQ3Server.InitGameVM(ARestart: Boolean);
begin
  // start the entity parsing at the beginning
  FTokens.Rewind;
  FGame.Call(GAME_INIT, [FTime, FSettings.Time.Milliseconds, Ord(ARestart)]);
end;

// SV_BotFrame
procedure TQ3Server.BotFrame(ATime: Integer);
begin
  if (IntegerCVar('bot_enable') = 0) or not Assigned(FGame) then
    Exit;
  FGame.Call(BOTAI_START_FRAME, [ATime]);
end;

procedure TQ3Server.RunGameFrame;
begin
  FGame.Call(GAME_RUN_FRAME, [FTime]);
end;

function TQ3Server.GameDeniedText(AResult: Integer): AnsiString;
begin
  // VM_ExplicitArgPtr: a pointer into the memory of the game, 0 is no pointer
  if AResult = 0 then
    Exit('');
  Result := FGame.Memory.ReadString(AResult);
end;

// the map, the world and the game of a level (SV_ClearWorld, CM_LoadMap, SV_InitGameProgs)
procedure TQ3Server.CreateLevel(const AMapName: AnsiString);
var
  LMapBytes: TBytes;
  LCVars: IQ3CVarSystem;
begin
  LCVars := FSettings.Console.CVars;
  if not FSettings.Files.ReadFile('maps/' + string(AMapName) + '.bsp', LMapBytes) then
    raise EQ3HostException.CreateFmt('Could not find map maps/%s.bsp', [string(AMapName)]);
  FClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(FSettings.Files));
  FClipMap.Load(AnsiString('maps/' + string(AMapName) + '.bsp'));
  // set serverinfo visible name
  SetCVar('mapname', AMapName);
  SetCVar('sv_mapChecksum', AnsiString(IntToStr(Integer(TIdMd4.BlockChecksum(LMapBytes[0], Length(LMapBytes))))));
  // the world of the level: the old one goes after the game that used it
  FGame := nil;
  FGameKeeper := nil;
  FGameHost := nil;
  FreeAndNil(FWorld);
  FWorld := TQ3GameWorld.Create(FClipMap, FSettings.Print);
  if Assigned(FSnaps) then
    FSnaps.ChangeLevel(FWorld, FClipMap)
  else
  begin
    FSnaps := TQ3ServerSnapshots.Create(FWorld, FClipMap, FStateIntf);
    FSnapsIntf := FSnaps;
    FCommandsIntf := TGameCommands.Create(Self);
  end;
  FSnaps.ChecksumFeed := FChecksumFeed;
  FSnaps.SetTime(FTime);
  CreateGame;
end;

// the host of qagame and its machine (SV_InitGameProgs: VM_Create); a map_restart makes them again on the same world
procedure TQ3Server.CreateGame;
var
  LServices: TQ3HostServices;
  LCVars: IQ3CVarSystem;
  LBotCommand: TQ3BotClientCommand;
begin
  LCVars := FSettings.Console.CVars;
  FGame := nil;
  FGameKeeper := nil;
  FGameHost := nil;
  FreeAndNil(FTokens);
  FTokens := TQ3EntityTokens.Create(FClipMap);
  LBotCommand :=
    procedure(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString)
    begin
      // SV_ExecuteClientCommand( cl, s, qtrue ) for a bot
      FSettings.Console.Arguments.Tokenize(ACommand);
      AMachine.Call(GAME_CLIENT_COMMAND, [AClient]);
    end;
  FBotServerIntf := nil;
  FBotServer := TQ3HostBotServer.Create(FState, LBotCommand);
  FBotServerIntf := FBotServer;

  LServices := Default(TQ3HostServices);
  LServices.CVars := LCVars;
  LServices.Arguments := FSettings.Console.Arguments;
  LServices.Buffer := FSettings.Console.Buffer;
  LServices.Commands := FSettings.Console.Commands;
  LServices.Files := TQ3GameHostFiles.Create(FSettings.Files, nil);
  LServices.ClipMap := FClipMap;
  LServices.State := FStateIntf;
  LServices.ServerCommands := FCommandsIntf;
  LServices.Calendar := FSettings.Calendar;
  LServices.Bot.Files := TQ3BotFileSource.Create(FSettings.Files);
  LServices.Bot.Server := FBotServer;
  LServices.World := FWorld;
  LServices.Tokens := FTokens;
  LServices.Client.Sources := FSettings.Sources;
  FGameHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, FSettings.Print, FSettings.Time, LServices);
  if Assigned(FSettings.WrapGameHost) then
    FGameKeeper := FSettings.WrapGameHost(FGameHost)
  else
    FGameKeeper := FGameHost;
  if not FSettings.Files.ReadFile('vm/qagame.qvm', FGameFile) then
    raise EQ3HostException.Create(SNoGame);
  FGame := TQvmFactory.CreateMachine('qagame', FGameFile, FGameKeeper, FSettings.Limits);
end;

// SV_SpawnServer
procedure TQ3Server.SpawnServer(const AMapName: AnsiString; AKillBots: Boolean);
var
  LIndex: Integer;
  LDenied: AnsiString;
  LResult: Integer;
  LIsBot: Boolean;
  LCVar: TQ3CVar;
begin
  // shut down the existing game if it is running
  ShutdownGameProgs;
  Print('------ Server Initialization ------'#10);
  Print(AnsiString('Server: ' + string(AMapName) + #10));
  FRunning := True;
  FInGame := False;
  FRestarting := False;
  // the configstrings are wiped and set while the level loads: nothing goes to the clients (sv.state SS_LOADING)
  if Assigned(FSnaps) then
    FSnaps.SetBroadcast(False);
  SetCVar('nextmap', 'map_restart 0');
  SetCVar('cl_paused', '0');
  // wipe the entire per-level structure
  for LIndex := 0 to 1023 do
    FState.SetConfigstring(LIndex, '');
  // a new checksum feed
  FChecksumFeed := FSettings.Time.Milliseconds * 31 + 7;
  FServerId := FSettings.Time.Milliseconds;
  FRestartedServerId := FServerId;
  FTimeResidual := 0;
  FRestartTime := 0;
  FMapName := AMapName;
  // load and spawn all other entities
  CreateLevel(AMapName);
  SetCVar('sv_serverid', AnsiString(IntToStr(FServerId)));
  InitGameVM(False);
  // don't allow a map_restart if game is modified (and the latched maxclients is in force now)
  LCVar := FSettings.Console.CVars.Find('g_gametype');
  if Assigned(LCVar) then
    LCVar.Modified := False;
  LCVar := FSettings.Console.CVars.Find('sv_maxclients');
  if Assigned(LCVar) then
    LCVar.Modified := False;
  // run a few frames to allow everything to settle
  for LIndex := 0 to GAME_FRAME_SETTLE - 1 do
  begin
    RunGameFrame;
    BotFrame(FTime);
    Inc(FTime, 100);
    FSnaps.SetTime(FTime);
  end;
  // create a baseline for more efficient communications
  FSnaps.CreateBaselines(FGame.Memory);
  for LIndex := 0 to MaxClients - 1 do
  begin
    // send the new gamestate to all connected clients
    if FSnaps.Phase(LIndex) < TQ3ServerClientPhase.Connected then
      Continue;
    LIsBot := FClients[LIndex].IsBot;
    if LIsBot and AKillBots then
    begin
      DropClient(LIndex, '');
      Continue;
    end;
    // connect the client again
    LResult := FGame.Call(GAME_CLIENT_CONNECT, [LIndex, 0, Ord(LIsBot)]);
    LDenied := GameDeniedText(LResult);
    if LResult <> 0 then
      DropClient(LIndex, LDenied)
    else if not LIsBot then
      // when we get the next packet from a connected client, the new gamestate will be sent
      FClients[LIndex].GamestateMessageNum := -1
    else
    begin
      FSnaps.ClientBegin(LIndex);
      FClients[LIndex].NextSnapshotTime := FTime;
      FGame.Call(GAME_CLIENT_BEGIN, [LIndex]);
    end;
  end;
  // run another frame to allow things to look at all the players
  RunGameFrame;
  BotFrame(FTime);
  Inc(FTime, 100);
  FSnaps.SetTime(FTime);
  // pure servers are not supported: the paks the server sends are empty
  SetCVar('sv_paks', '');
  SetCVar('sv_pakNames', '');
  SetCVar('sv_referencedPaks', '');
  SetCVar('sv_referencedPakNames', '');
  // save systeminfo and serverinfo strings
  FState.SetConfigstring(CS_SYSTEMINFO, FSettings.Console.CVars.InfoStringBig(Q3_CVAR_SYSTEMINFO));
  FSettings.Console.CVars.ModifiedFlags := FSettings.Console.CVars.ModifiedFlags and not Q3_CVAR_SYSTEMINFO;
  FState.SetConfigstring(CS_SERVERINFO, FSettings.Console.CVars.InfoString(Q3_CVAR_SERVERINFO));
  FSettings.Console.CVars.ModifiedFlags := FSettings.Console.CVars.ModifiedFlags and not Q3_CVAR_SERVERINFO;
  // any configstring change now is sent to the clients
  FInGame := True;
  FSnaps.StartGame;
  Print('-----------------------------------'#10);
end;

// SV_Map_f
function TQ3Server.Map(const AMapName: AnsiString): Boolean;
var
  LBytes: TBytes;
begin
  // make sure the level exists before trying to change, so that a typo does not end the game
  if not FSettings.Files.ReadFile('maps/' + string(AMapName) + '.bsp', LBytes) then
  begin
    Print(AnsiString('Can''t find map maps/' + string(AMapName) + '.bsp'#10));
    Exit(False);
  end;
  SetCVar('sv_cheats', '0');
  SpawnServer(AMapName, True);
  Result := True;
end;

// SV_MapRestart_f
procedure TQ3Server.MapRestart(ADelay: Integer);
var
  LIndex: Integer;
  LResult: Integer;
  LCVar: TQ3CVar;
  LGametype, LMaxClients: TQ3CVar;
  LName: AnsiString;
  LIsBot: Boolean;
begin
  // make sure we aren't restarting twice in the same frame
  if FSettings.Time.Milliseconds = FServerId then
    Exit;
  if not FRunning then
  begin
    Print('Server is not running.'#10);
    Exit;
  end;
  if FRestartTime <> 0 then
    Exit;
  LCVar := FSettings.Console.CVars.Find('g_doWarmup');
  if (ADelay <> 0) and not (Assigned(LCVar) and (LCVar.Value <> 0)) then
  begin
    FRestartTime := FTime + ADelay * 1000;
    FState.SetConfigstring(CS_WARMUP, AnsiString(IntToStr(FRestartTime)));
    Exit;
  end;
  // check for changes in variables that can't just be restarted
  LGametype := FSettings.Console.CVars.Find('g_gametype');
  LMaxClients := FSettings.Console.CVars.Find('sv_maxclients');
  if (Assigned(LMaxClients) and LMaxClients.Modified) or (Assigned(LGametype) and LGametype.Modified) then
  begin
    Print('variable change -- restarting.'#10);
    LName := FSettings.Console.CVars.VariableString('mapname');
    SpawnServer(LName, False);
    Exit;
  end;
  // generate a new serverid
  FServerId := FSettings.Time.Milliseconds;
  SetCVar('sv_serverid', AnsiString(IntToStr(FServerId)));
  // reset all the vm data in place: configstrings that had been changed generate broadcast updates
  FInGame := False;
  FRestarting := True;
  FSnaps.SetBroadcast(True);
  FGame.Call(GAME_SHUTDOWN, [1]);
  // VM_Restart: the machine starts again from the same file (the botlib of the host stays set up, as in the C)
  FWorld.ClearWorld;
  FGame.Restart(FGameFile);
  InitGameVM(True);
  for LIndex := 0 to GAME_FRAME_SETTLE - 1 do
  begin
    RunGameFrame;
    Inc(FTime, 100);
    FSnaps.SetTime(FTime);
  end;
  FInGame := True;
  FRestarting := False;
  // connect and begin all the clients
  for LIndex := 0 to MaxClients - 1 do
  begin
    if FSnaps.Phase(LIndex) < TQ3ServerClientPhase.Connected then
      Continue;
    LIsBot := FClients[LIndex].IsBot;
    // add the map_restart command
    FSnaps.Send(LIndex, 'map_restart'#10);
    // connect the client again, without the firstTime flag
    LResult := FGame.Call(GAME_CLIENT_CONNECT, [LIndex, 0, Ord(LIsBot)]);
    if LResult <> 0 then
    begin
      DropClient(LIndex, GameDeniedText(LResult));
      Print(AnsiString(Format('SV_MapRestart_f(%d): dropped client %d - denied!'#10, [ADelay, LIndex])));
      Continue;
    end;
    ClientEnterWorld(LIndex, FClients[LIndex].LastUsercmd);
  end;
  // run another frame to allow things to look at all the players
  RunGameFrame;
  Inc(FTime, 100);
  FSnaps.SetTime(FTime);
end;

// SVC_GetChallenge without the authorize server: the challenge is accepted at once
procedure TQ3Server.GetChallenge(const AFrom: TQ3NetAddress);
var
  LIndex, LOldest, LOldestTime: Integer;
begin
  LOldest := 0;
  LOldestTime := MaxInt;
  // see if we already have a challenge for this ip
  for LIndex := 0 to High(FChallenges) do
  begin
    if FChallenges[LIndex].Used and SameBaseAddress(AFrom, FChallenges[LIndex].Address) and
      (AFrom.Port = FChallenges[LIndex].Address.Port) then
      Break;
    if FChallenges[LIndex].Time < LOldestTime then
    begin
      LOldestTime := FChallenges[LIndex].Time;
      LOldest := LIndex;
    end;
  end;
  if LIndex = Length(FChallenges) then
  begin
    // this is the first time this client has asked for a challenge
    LIndex := LOldest;
    Inc(FNextChallenge);
    FChallenges[LIndex].Challenge := (FNextChallenge * 1103515245 + 12345) and $7FFFFFFF;
    FChallenges[LIndex].Address := AFrom;
    FChallenges[LIndex].Used := True;
  end;
  FChallenges[LIndex].Time := FTime;
  if Assigned(FSettings.Output) then
    FSettings.Output.SendOutOfBand(AFrom, AnsiString('challengeResponse ' + IntToStr(FChallenges[LIndex].Challenge)));
end;

// SV_UserinfoChanged
procedure TQ3Server.UserinfoChanged(AClient: Integer);
var
  LInfo, LValue: AnsiString;
  LNumber: Integer;
begin
  LInfo := FState.GetUserinfo(AClient);
  // name for C code
  FClients[AClient].Name := TQ3InfoString.ValueForKey(LInfo, 'name');
  // rate command: a loopback client is on the LAN and is not choked
  if (FClients[AClient].Address.AddressType = Ord(natLoopback)) and (IntegerCVar('sv_lanForceRate') = 1) then
    FClients[AClient].Rate := 99999
  else
  begin
    LValue := TQ3InfoString.ValueForKey(LInfo, 'rate');
    if Length(LValue) > 0 then
      FClients[AClient].Rate := Min(90000, Max(1000, CAtoi(LValue)))
    else
      FClients[AClient].Rate := 3000;
  end;
  LValue := TQ3InfoString.ValueForKey(LInfo, 'handicap');
  if Length(LValue) > 0 then
  begin
    LNumber := CAtoi(LValue);
    if (LNumber <= 0) or (LNumber > 100) or (Length(LValue) > 4) then
      TQ3InfoString.SetValueForKey(LInfo, 'handicap', '100');
  end;
  // snaps command
  LValue := TQ3InfoString.ValueForKey(LInfo, 'snaps');
  if Length(LValue) > 0 then
  begin
    LNumber := Min(30, Max(1, CAtoi(LValue)));
    FClients[AClient].SnapshotMsec := 1000 div LNumber;
  end
  else
    FClients[AClient].SnapshotMsec := 50;
  // maintain the IP information
  LValue := TQ3InfoString.ValueForKey(LInfo, 'ip');
  if Length(LValue) = 0 then
  begin
    if FClients[AClient].Address.AddressType <> Ord(natLoopback) then
      TQ3InfoString.SetValueForKey(LInfo, 'ip', AddressText(FClients[AClient].Address))
    else
      TQ3InfoString.SetValueForKey(LInfo, 'ip', 'localhost');
  end;
  FState.SetUserinfo(AClient, LInfo);
end;

// SV_DirectConnect
function TQ3Server.DirectConnect(const AFrom: TQ3NetAddress; const AUserinfo: AnsiString): Integer;
var
  LUserinfo, LPassword: AnsiString;
  LIndex, LSlot, LChallenge, LQPort, LStart: Integer;
  LLocal, LFound: Boolean;
  LDenied: Integer;
  LText: AnsiString;
  LCount: Integer;

  procedure Reply(const AText: AnsiString);
  begin
    if Assigned(FSettings.Output) then
      FSettings.Output.SendOutOfBand(AFrom, AText);
  end;

begin
  LUserinfo := Copy(AUserinfo, 1, 1023);
  if CAtoi(TQ3InfoString.ValueForKey(LUserinfo, 'protocol')) <> FSettings.Protocol then
  begin
    Reply(AnsiString(Format('print'#10'Server uses protocol version %d.'#10, [FSettings.Protocol])));
    Exit(-1);
  end;
  LChallenge := CAtoi(TQ3InfoString.ValueForKey(LUserinfo, 'challenge'));
  LQPort := CAtoi(TQ3InfoString.ValueForKey(LUserinfo, 'qport'));
  // quick reject
  LSlot := FindClient(AFrom, LQPort);
  if (LSlot >= 0) and ((FTime - FClients[LSlot].LastConnectTime) < IntegerCVar('sv_reconnectlimit') * 1000) then
    Exit(-1);
  // see if the challenge is valid (LAN clients don't need to challenge)
  LLocal := AFrom.AddressType = Ord(natLoopback);
  if not LLocal then
  begin
    LFound := False;
    for LIndex := 0 to High(FChallenges) do
      if FChallenges[LIndex].Used and SameBaseAddress(AFrom, FChallenges[LIndex].Address) and
        (AFrom.Port = FChallenges[LIndex].Address.Port) and (FChallenges[LIndex].Challenge = LChallenge) then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
    begin
      Reply('print'#10'No or bad challenge for address.'#10);
      Exit(-1);
    end;
    // force the IP key/value pair so the game can filter based on ip
    TQ3InfoString.SetValueForKey(LUserinfo, 'ip', AddressText(AFrom));
  end
  else
    TQ3InfoString.SetValueForKey(LUserinfo, 'ip', 'localhost');
  // if there is already a slot for this ip, reuse it, else find a client slot
  if LSlot >= 0 then
    Print(AnsiString(string(AddressText(AFrom)) + ':reconnect'#10))
  else
  begin
    LPassword := TQ3InfoString.ValueForKey(LUserinfo, 'password');
    if LPassword = FSettings.Console.CVars.VariableString('sv_privatePassword') then
      LStart := 0
    else
      LStart := IntegerCVar('sv_privateClients');
    for LIndex := LStart to MaxClients - 1 do
      if (FSnaps.Phase(LIndex) = TQ3ServerClientPhase.Free) and not FState.IsClientActive(LIndex) then
      begin
        LSlot := LIndex;
        Break;
      end;
    if LSlot < 0 then
    begin
      if LLocal then
      begin
        LCount := 0;
        for LIndex := LStart to MaxClients - 1 do
          if FClients[LIndex].IsBot then
            Inc(LCount);
        // if they're all bots
        if LCount >= MaxClients - LStart then
        begin
          LSlot := MaxClients - 1;
          DropClient(LSlot, 'only bots on server');
          FSnaps.FreeZombie(LSlot);
          FState.SetClientActive(LSlot, False);
        end
        else
          raise EQ3HostException.Create(SServerFull);
      end
      else
      begin
        Reply('print'#10'Server is full.'#10);
        Exit(-1);
      end;
    end;
  end;
  // build a new connection: this is the only place a client is initialized
  FClients[LSlot] := Default(TClientInfo);
  FClients[LSlot].Address := AFrom;
  FClients[LSlot].QPort := LQPort;
  FClients[LSlot].Challenge := LChallenge;
  FClients[LSlot].GamestateMessageNum := -1;
  FClients[LSlot].Rate := 3000;
  FClients[LSlot].SnapshotMsec := 50;
  FState.SetUserinfo(LSlot, LUserinfo);
  // get the game a chance to reject this connection or modify the userinfo
  LDenied := FGame.Call(GAME_CLIENT_CONNECT, [LSlot, 1, 0]);
  if LDenied <> 0 then
  begin
    LText := GameDeniedText(LDenied);
    Reply(AnsiString('print'#10 + string(LText) + #10));
    Exit(-1);
  end;
  FClients[LSlot].Used := True;
  FSnaps.ConnectClient(LSlot);
  FState.SetClientActive(LSlot, True);
  UserinfoChanged(LSlot);
  // send the connect packet to the client
  Reply('connectResponse');
  FClients[LSlot].NextSnapshotTime := FTime;
  FClients[LSlot].LastPacketTime := FTime;
  FClients[LSlot].LastConnectTime := FTime;
  // when we receive the first packet from the client, we will notice that it is from a different serverid and that
  // the gamestate message was not just sent, forcing a retransmit
  FClients[LSlot].GamestateMessageNum := -1;
  Result := LSlot;
end;

// SV_DropClient
procedure TQ3Server.DropClient(AClient: Integer; const AReason: AnsiString);
begin
  if (AClient < 0) or (AClient >= MaxClients) then
    raise EQ3HostException.CreateFmt(SBadClientNumber, [AClient]);
  if FSnaps.Phase(AClient) = TQ3ServerClientPhase.Zombie then
    Exit;
  // tell everyone why they got dropped
  SendServerCommand(-1, AnsiString(Format('print "%s^7 %s'#10'"', [string(FClients[AClient].Name), string(AReason)])));
  FSnaps.Drop(AClient, AReason);
  // call the prog function for removing a client: this will remove the body, among other things
  if Assigned(FGame) then
    FGame.Call(GAME_CLIENT_DISCONNECT, [AClient]);
  // add the disconnect command
  FSnaps.Send(AClient, AnsiString(Format('disconnect "%s"', [string(AReason)])));
  if FClients[AClient].IsBot then
  begin
    FState.BotFreeClient(AClient);
    FClients[AClient].IsBot := False;
    FSnaps.FreeZombie(AClient);
  end;
  // nuke user info
  FState.SetUserinfo(AClient, '');
  FState.SetClientActive(AClient, False);
end;

// SV_SendClientGameState
procedure TQ3Server.SendClientGameState(AClient: Integer);
var
  LNumber: Integer;
  LBytes: TBytes;
begin
  FClients[AClient].GamestateMessageNum := FSnaps.OutgoingSequence(AClient);
  LBytes := FSnaps.WriteGamestate(AClient, LNumber);
  SendMessageToClient(AClient, LBytes, LNumber);
end;

// SV_ClientEnterWorld
procedure TQ3Server.ClientEnterWorld(AClient: Integer; const ACommand: TQ3UserCmd);
begin
  FSnaps.ClientBegin(AClient);
  FClients[AClient].NextSnapshotTime := FTime;
  FClients[AClient].LastUsercmd := ACommand;
  FState.SetUsercmd(AClient, UserCmdBytes(ACommand));
  // call the game begin function
  FGame.Call(GAME_CLIENT_BEGIN, [AClient]);
end;

// SV_ClientThink
procedure TQ3Server.ClientThink(AClient: Integer; const ACommand: TQ3UserCmd);
begin
  FClients[AClient].LastUsercmd := ACommand;
  FState.SetUsercmd(AClient, UserCmdBytes(ACommand));
  // may have been kicked during the last usercmd
  if FSnaps.Phase(AClient) <> TQ3ServerClientPhase.Active then
    Exit;
  FGame.Call(GAME_CLIENT_THINK, [AClient]);
end;

// SV_ExecuteClientCommand
procedure TQ3Server.ExecuteClientCommand(AClient: Integer; const AText: AnsiString; AClientOK: Boolean);
var
  LName: AnsiString;
  LProcessed: Boolean;
begin
  FSettings.Console.Arguments.Tokenize(AText);
  LName := FSettings.Console.Arguments.Argv(0);
  LProcessed := True;
  // see if it is a server level command
  if LName = 'userinfo' then
  begin
    // SV_UpdateUserinfo_f
    FState.SetUserinfo(AClient, Copy(FSettings.Console.Arguments.Argv(1), 1, 1023));
    UserinfoChanged(AClient);
    // call prog code to allow overrides
    FGame.Call(GAME_CLIENT_USERINFO_CHANGED, [AClient]);
  end
  else if LName = 'disconnect' then
    DropClient(AClient, 'disconnected')
  else if (LName = 'cp') or (LName = 'vdr') or (LName = 'download') or (LName = 'nextdl') or (LName = 'stopdl') or
    (LName = 'donedl') then
    // pure servers and downloads are not served
    Exit
  else
    LProcessed := False;
  if AClientOK then
  begin
    // pass unknown strings to the game
    if not LProcessed and FInGame then
    begin
      FSettings.Console.Arguments.Tokenize(AText);
      FGame.Call(GAME_CLIENT_COMMAND, [AClient]);
    end;
  end
  else if not LProcessed then
    Print(AnsiString('client text ignored for ' + string(FClients[AClient].Name) + ': ' + string(LName) + #10));
end;

// SV_ClientCommand
function TQ3Server.ClientCommand(AClient: Integer; AMessage: TQ3Message): Boolean;
var
  LMessage: TQ3Message;
  LSequence: Integer;
  LText: AnsiString;
  LClientOK: Boolean;
begin
  LMessage := AMessage;
  LClientOK := True;
  LSequence := LMessage.ReadLong;
  LText := LMessage.ReadString;
  // see if we have already executed it
  if FSnaps.LastClientCommand(AClient) >= LSequence then
    Exit(True);
  // drop the connection if we have somehow lost commands
  if LSequence > FSnaps.LastClientCommand(AClient) + 1 then
  begin
    Print(AnsiString(Format('Client %s lost %d clientCommands'#10, [string(FClients[AClient].Name),
      LSequence - FSnaps.LastClientCommand(AClient) + 1])));
    DropClient(AClient, 'Lost reliable commands');
    Exit(False);
  end;
  // malicious users may try using too many string commands to lag other players
  if not FSettings.ClientRunning and (FSnaps.Phase(AClient) >= TQ3ServerClientPhase.Active) and
    (IntegerCVar('sv_floodProtect') <> 0) and (FTime < FClients[AClient].NextReliableTime) then
    LClientOK := False;
  // don't allow another command for one second
  FClients[AClient].NextReliableTime := FTime + 1000;
  ExecuteClientCommand(AClient, LText, LClientOK);
  FSnaps.SetLastClientCommand(AClient, LSequence);
  FClients[AClient].LastClientCommandString := LText;
  Result := True;
end;

// SV_UserMove
procedure TQ3Server.UserMove(AClient: Integer; AMessage: TQ3Message; ADelta: Boolean);
var
  LMessage: TQ3Message;
  LCount, LIndex, LKey: Integer;
  LCommands: array[0..Q3_MAX_PACKET_USERCMDS - 1] of TQ3UserCmd;
  LNull, LOld: TQ3UserCmd;
begin
  LMessage := AMessage;
  FSnaps.Acknowledge(AClient, FClients[AClient].MessageAcknowledge, FClients[AClient].ReliableAcknowledge, ADelta);
  LCount := LMessage.ReadByte;
  if LCount < 1 then
  begin
    Print('cmdCount < 1'#10);
    Exit;
  end;
  if LCount > Q3_MAX_PACKET_USERCMDS then
  begin
    Print('cmdCount > MAX_PACKET_USERCMDS'#10);
    Exit;
  end;
  // use the checksum feed in the key, the message acknowledge and the last acknowledged server command
  LKey := FChecksumFeed xor FClients[AClient].MessageAcknowledge xor
    TQ3HashKey.Compute(FSnaps.ServerCommand(AClient, FClients[AClient].ReliableAcknowledge), 32);
  LNull := Default(TQ3UserCmd);
  LOld := LNull;
  for LIndex := 0 to LCount - 1 do
  begin
    TQ3UserCmdCodec.ReadDeltaKey(LMessage, LKey, LOld, LCommands[LIndex]);
    LOld := LCommands[LIndex];
  end;
  // if this is the first usercmd we have received this gamestate, put the client into the world
  if FSnaps.Phase(AClient) = TQ3ServerClientPhase.Primed then
    ClientEnterWorld(AClient, LCommands[0]);
  if FSnaps.Phase(AClient) <> TQ3ServerClientPhase.Active then
  begin
    FSnaps.Acknowledge(AClient, FClients[AClient].MessageAcknowledge, FClients[AClient].ReliableAcknowledge, False);
    Exit;
  end;
  // usually, the first couple commands will be duplicates of ones we have previously received, but the
  // servertimes in the commands will cause them to be immediately discarded
  for LIndex := 0 to LCount - 1 do
  begin
    // if this is a cmd from before a map_restart ignore it
    if LCommands[LIndex].ServerTime > LCommands[LCount - 1].ServerTime then
      Continue;
    // don't execute if this is an old cmd which is already executed
    if LCommands[LIndex].ServerTime <= FClients[AClient].LastUsercmd.ServerTime then
      Continue;
    ClientThink(AClient, LCommands[LIndex]);
  end;
end;

// SV_ExecuteClientMessage
procedure TQ3Server.ExecuteClientMessage(AClient: Integer; const AData: TBytes; ALength: Integer);
var
  LMessage: TQ3Message;
  LServerId, LCommand, LAcknowledge: Integer;
begin
  if (AClient < 0) or (AClient >= MaxClients) then
    raise EQ3HostException.CreateFmt(SBadClientNumber, [AClient]);
  if FSnaps.Phase(AClient) = TQ3ServerClientPhase.Zombie then
    Exit;
  FClients[AClient].LastPacketTime := FTime;
  LMessage := TQ3NetFactory.CreateMessage(FCoder);
  try
    LMessage.Init(AData, ALength);
    LMessage.CurSize := ALength;
    LMessage.Bitstream;
    LServerId := LMessage.ReadLong;
    FClients[AClient].MessageAcknowledge := LMessage.ReadLong;
    // usually only hackers create messages like this
    if FClients[AClient].MessageAcknowledge < 0 then
      Exit;
    LAcknowledge := LMessage.ReadLong;
    FClients[AClient].ReliableAcknowledge := LAcknowledge;
    if LAcknowledge < FSnaps.ReliableSequence(AClient) - RELIABLE_COMMANDS then
    begin
      FClients[AClient].ReliableAcknowledge := FSnaps.ReliableSequence(AClient);
      FSnaps.Acknowledge(AClient, FClients[AClient].MessageAcknowledge, FClients[AClient].ReliableAcknowledge,
        False);
      Exit;
    end;
    FSnaps.Acknowledge(AClient, FClients[AClient].MessageAcknowledge, LAcknowledge, False);
    // if this is a usercmd from a previous gamestate, ignore it or retransmit the current gamestate
    if (LServerId <> FServerId) and (Pos('nextdl', string(FClients[AClient].LastClientCommandString)) = 0) then
    begin
      // they just haven't caught the map_restart yet
      if (LServerId >= FRestartedServerId) and (LServerId < FServerId) then
        Exit;
      // if we can tell that the client has dropped the last gamestate we sent them, resend it
      if FClients[AClient].MessageAcknowledge > FClients[AClient].GamestateMessageNum then
        SendClientGameState(AClient);
      Exit;
    end;
    // read optional clientCommand strings
    while True do
    begin
      LCommand := LMessage.ReadByte;
      if LCommand = Q3_CLC_EOF then
        Break;
      if LCommand <> Q3_CLC_CLIENT_COMMAND then
        Break;
      // we couldn't execute it because of the flood protection
      if not ClientCommand(AClient, LMessage) then
        Exit;
      // disconnect command
      if FSnaps.Phase(AClient) = TQ3ServerClientPhase.Zombie then
        Exit;
    end;
    // read the usercmd_t
    if LCommand = Q3_CLC_MOVE then
      UserMove(AClient, LMessage, True)
    else if LCommand = Q3_CLC_MOVE_NODELTA then
      UserMove(AClient, LMessage, False)
    else if LCommand <> Q3_CLC_EOF then
      Print(AnsiString(Format('WARNING: bad command byte for client %d'#10, [AClient])));
  finally
    LMessage.Free;
  end;
end;

// SV_SendMessageToClient + SV_RateMsec
function TQ3Server.RateMsec(AClient, AMessageSize: Integer): Integer;
var
  LRate: Integer;
begin
  LRate := FClients[AClient].Rate;
  if (IntegerCVar('sv_maxRate') <> 0) and (IntegerCVar('sv_maxRate') < LRate) then
    LRate := IntegerCVar('sv_maxRate');
  // include the header overhead in the size
  Inc(AMessageSize, HEADER_RATE_BYTES);
  Result := (AMessageSize * 1000) div LRate;
end;

procedure TQ3Server.SendMessageToClient(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
var
  LRateMsec, LFps: Integer;
begin
  if Assigned(FSettings.Output) then
    FSettings.Output.SendMessage(AClient, AMessage, ASequence);
  // set nextSnapshotTime based on rate and requested number of updates: local clients get snapshots every frame
  LFps := Max(1, IntegerCVar('sv_fps'));
  if FClients[AClient].Address.AddressType = Ord(natLoopback) then
  begin
    FClients[AClient].NextSnapshotTime := FTime + 1000 div LFps;
    Exit;
  end;
  LRateMsec := RateMsec(AClient, Length(AMessage));
  if LRateMsec < FClients[AClient].SnapshotMsec then
    LRateMsec := FClients[AClient].SnapshotMsec;
  FClients[AClient].NextSnapshotTime := FTime + LRateMsec;
end;

// SV_SendClientSnapshot
procedure TQ3Server.SendClientSnapshot(AClient: Integer);
var
  LNumber: Integer;
  LBytes: TBytes;
begin
  // a client with no gamestate yet has nothing to be sent (and no entity the game filled in)
  if FSnaps.Phase(AClient) = TQ3ServerClientPhase.Connected then
    Exit;
  if FSnaps.Phase(AClient) = TQ3ServerClientPhase.Zombie then
  begin
    LBytes := FSnaps.WriteCommandsOnly(AClient, LNumber);
    SendMessageToClient(AClient, LBytes, LNumber);
    Exit;
  end;
  // bots need to have their snapshots build, but they query them directly without needing to be sent
  if FClients[AClient].IsBot then
  begin
    FSnaps.BuildClientSnapshot(FGame.Memory, AClient);
    FBotServer.SetSnapshot(AClient, FSnaps.FrameEntityNumbers(AClient));
    Exit;
  end;
  LBytes := FSnaps.WriteSnapshot(FGame.Memory, AClient, LNumber);
  SendMessageToClient(AClient, LBytes, LNumber);
end;

// SV_SendClientMessages
procedure TQ3Server.SendClientMessages;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MaxClients - 1 do
  begin
    if FSnaps.Phase(LIndex) = TQ3ServerClientPhase.Free then
      Continue;
    // not time yet
    if FTime < FClients[LIndex].NextSnapshotTime then
      Continue;
    // send additional message fragments if the last message was too large to send at once
    if Assigned(FSettings.Output) and FSettings.Output.HasUnsentFragments(LIndex) then
    begin
      FClients[LIndex].NextSnapshotTime := FTime + RateMsec(LIndex, Q3_FRAGMENT_SIZE);
      FSettings.Output.TransmitNextFragment(LIndex);
      Continue;
    end;
    SendClientSnapshot(LIndex);
  end;
end;

// SV_CheckTimeouts
procedure TQ3Server.CheckTimeouts;
var
  LIndex, LDropPoint, LZombiePoint: Integer;
begin
  LDropPoint := FTime - 1000 * IntegerCVar('sv_timeout');
  LZombiePoint := FTime - 1000 * IntegerCVar('sv_zombietime');
  for LIndex := 0 to MaxClients - 1 do
  begin
    // message times may be wrong across a changelevel
    if FClients[LIndex].LastPacketTime > FTime then
      FClients[LIndex].LastPacketTime := FTime;
    if (FSnaps.Phase(LIndex) = TQ3ServerClientPhase.Zombie) and (FClients[LIndex].LastPacketTime < LZombiePoint) then
    begin
      FSnaps.FreeZombie(LIndex);
      Continue;
    end;
    if (FSnaps.Phase(LIndex) >= TQ3ServerClientPhase.Connected) and (FClients[LIndex].LastPacketTime < LDropPoint) and
      not FClients[LIndex].IsBot then
    begin
      // wait several frames so a debugger session doesn't cause a timeout
      Inc(FClients[LIndex].TimeoutCount);
      if FClients[LIndex].TimeoutCount > 5 then
      begin
        DropClient(LIndex, 'timed out');
        // don't bother with zombie state
        FSnaps.FreeZombie(LIndex);
      end;
    end
    else
      FClients[LIndex].TimeoutCount := 0;
  end;
end;

// the slots that SV_BotAllocateClient and SV_BotFreeClient (the game's trap calls) made or released
procedure TQ3Server.SyncBots;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MaxClients - 1 do
  begin
    if FState.IsClientActive(LIndex) and not FClients[LIndex].Used then
    begin
      FClients[LIndex] := Default(TClientInfo);
      FClients[LIndex].Used := True;
      FClients[LIndex].IsBot := True;
      FClients[LIndex].Address.AddressType := Ord(natBot);
      FClients[LIndex].Rate := 16384;
      FClients[LIndex].SnapshotMsec := 50;
      FClients[LIndex].GamestateMessageNum := -1;
      FSnaps.ConnectClient(LIndex);
      FSnaps.ClientBegin(LIndex);
      FClients[LIndex].NextSnapshotTime := FTime;
    end
    else if FClients[LIndex].IsBot and not FState.IsClientActive(LIndex) then
    begin
      FClients[LIndex].IsBot := False;
      FClients[LIndex].Used := False;
      FSnaps.Drop(LIndex, '');
      FSnaps.FreeZombie(LIndex);
    end;
  end;
end;

// SV_Frame
procedure TQ3Server.Frame(AMsec: Integer);
var
  LFrameMsec: Integer;
begin
  if not FRunning or not Assigned(FGame) then
    Exit;
  LFrameMsec := 1000 div Max(1, IntegerCVar('sv_fps'));
  Inc(FTimeResidual, AMsec);
  BotFrame(FTime + FTimeResidual);
  if (FRestartTime <> 0) and (FTime >= FRestartTime) then
  begin
    FRestartTime := 0;
    MapRestart(0);
    Exit;
  end;
  // update infostrings if anything has been changed
  if (FSettings.Console.CVars.ModifiedFlags and Q3_CVAR_SERVERINFO) <> 0 then
  begin
    FState.SetConfigstring(CS_SERVERINFO, FSettings.Console.CVars.InfoString(Q3_CVAR_SERVERINFO));
    FSettings.Console.CVars.ModifiedFlags := FSettings.Console.CVars.ModifiedFlags and not Q3_CVAR_SERVERINFO;
  end;
  if (FSettings.Console.CVars.ModifiedFlags and Q3_CVAR_SYSTEMINFO) <> 0 then
  begin
    FState.SetConfigstring(CS_SYSTEMINFO, FSettings.Console.CVars.InfoStringBig(Q3_CVAR_SYSTEMINFO));
    FSettings.Console.CVars.ModifiedFlags := FSettings.Console.CVars.ModifiedFlags and not Q3_CVAR_SYSTEMINFO;
  end;
  SyncBots;
  // run the game simulation in chunks
  while FTimeResidual >= LFrameMsec do
  begin
    Dec(FTimeResidual, LFrameMsec);
    Inc(FTime, LFrameMsec);
    FSnaps.SetTime(FTime);
    RunGameFrame;
    SyncBots;
  end;
  CheckTimeouts;
  SendClientMessages;
end;

end.
