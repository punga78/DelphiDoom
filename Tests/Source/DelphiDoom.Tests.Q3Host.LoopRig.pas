{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the client of a loop:     }
{  the state, the parser, the writer of packets and cgame with a renderer      }
{  that records, for the tests that put a server and a client together         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.LoopRig;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Net.LoopbackTransport,
  DelphiDoom.Q3Host.ServerNetwork, DelphiDoom.Q3Host.ClientNetwork, DelphiDoom.Q3Host.Server, DelphiDoom.Q3Host.Server.Intf, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec,
  DelphiDoom.Net.Q3.ServerMessageParser, DelphiDoom.Net.Q3.ServerMessage.Intf, DelphiDoom.Q3Host.Services.Intf,
  DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.ClipMap,
  DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientPacketWriter, DelphiDoom.Q3Host.ClientKeys,
  DelphiDoom.Q3Host.ClientCdKey, DelphiDoom.Q3Host.ClientRecordingRenderer, DelphiDoom.Q3Host.UiLanServers,
  DelphiDoom.Tests.Q3Host.Support;

type
  /// <summary>Sys_Milliseconds that moves by 17 at every question: the ids and the seeds of the server differ</summary>
  TQ3SteppingTime = class(TInterfacedObject, IQ3HostTime)
  strict private
    FValue: Integer;
  public
    constructor Create(AStart: Integer);
    function Milliseconds: Integer;
  end;

  /// <summary>
  ///   The client of the loops: what the engine would put together on its side of a connection, with the fakes of the
  ///   tests for the renderer, the sound and the input. cgame runs on the qvm of the game folder
  /// </summary>
  TQ3LoopClient = class
  strict private
    FFiles: IGameFileSystem;
    FConsole: TQ3Console;
    FClipMap: IQ3HostClipMap;
    FState: TQ3ClientState;
    FStateIntf: IQ3HostClientState;
    FSink: IInterface;
    FEntityCodec: TQ3EntityStateCodec;
    FPlayerCodec: TQ3PlayerStateCodec;
    FCoder: IQ3HuffmanCoder;
    FParser: TQ3ServerMessageParser;
    FWriter: TQ3ClientPacketWriter;
    FGlobals: TQ3GlobalDefines;
    FSources: TQ3SourceHandles;
    FRenderer: TQ3RecordingRenderer;
    FKeys: TQ3ClientKeys;
    FLan: TQ3LanServers;
    FCdKey: TQ3ClientCdKey;
    FCgame: IQvmMachine;
    FCgameFingerprint: TQ3FingerprintHost;
    FCgameHost: IQ3SyscallHost;
    FStage: string;
    FCgameKeeper: IQvmHost;
    FLimits: TQvmLimits;
    FHolders: TArray<IInterface>;
  public
    constructor Create(const AFiles: IGameFileSystem; const AConsole: TQ3Console; const ALimits: TQvmLimits);
    destructor Destroy; override;
    /// <summary>CG_INIT with what the gamestate message gave (its message number first)</summary>
    procedure InitCgame(AServerMessageNumber: Integer);
    /// <summary>CG_DRAW_ACTIVE_FRAME at the time of the snapshot that came last</summary>
    procedure DrawFrame;
    function CgameCalls: Integer;
    function Draws: Integer;
    function Scenes: Integer;
    property State: TQ3ClientState read FState;
    property Parser: TQ3ServerMessageParser read FParser;
    property Writer: TQ3ClientPacketWriter read FWriter;
    property Coder: IQ3HuffmanCoder read FCoder;
    /// <summary>The sources of the precompiler: botlib and the client use one table</summary>
    property Sources: TQ3SourceHandles read FSources;
    property Stage: string read FStage;
  end;

type
  /// <summary>
  ///   The server of the loops with the fakes of the tests around it (the log, the calendar, the time that moves, a
  ///   counter of the system calls of qagame)
  /// </summary>
  TQ3LoopServer = class
  strict private
    FServer: TQ3Server;
    FFingerprint: TQ3FingerprintHost;
    FPrinted: TStringList;
  public
    constructor Create(const AFiles: IGameFileSystem; const AConsole: TQ3Console; const ALimits: TQvmLimits;
      const ASources: TQ3SourceHandles; const AOutput: IQ3ServerOutput);
    destructor Destroy; override;
    /// <summary>The system calls that qagame made (of the last machine; a new level starts again)</summary>
    function GameCalls: Integer;
    property Server: TQ3Server read FServer;
    property Printed: TStringList read FPrinted;
  end;

type
  /// <summary>The messages of the server for the clients, kept for the client to take (the in memory output)</summary>
  TQ3MemoryOutput = class(TInterfacedObject, IQ3ServerOutput)
  strict private
    FMessages: TList<TBytes>;
    FSequences: TList<Integer>;
    FOutOfBand: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SendMessage(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
    procedure SendOutOfBand(const AAddress: TQ3NetAddress; const AText: AnsiString);
    function HasUnsentFragments(AClient: Integer): Boolean;
    procedure TransmitNextFragment(AClient: Integer);
    function Take(out AMessage: TBytes; out ASequence: Integer): Boolean;
    property OutOfBand: TStringList read FOutOfBand;
  end;

  /// <summary>
  ///   A server and a client in the same process, one qagame and one cgame on the files of OpenArena: the client
  ///   connects, gets the gamestate, enters the world and plays frames (a command and a packet, the game, the
  ///   snapshot, the parser, cgame). Network: the packets go through the netchan of both sides on a wire in memory
  ///   (nothing opens a socket); otherwise they are given to the server and to the parser as they are
  /// </summary>
  TQ3LoopSession = class
  strict private
    FNetwork: Boolean;
    FConsole: TQ3Console;
    FClient: TQ3LoopClient;
    FServerSide: TQ3LoopServer;
    FOutput: TQ3MemoryOutput;
    FOutputIntf: IQ3ServerOutput;
    FWire: TNetLoopbackPair;
    FServerNet: TQ3ServerNetwork;
    FServerNetIntf: IQ3ServerOutput;
    FClientNet: TQ3ClientNetwork;
    FSlot: Integer;
    FMessageNumber: Integer;
    FOutgoing: Integer;
    FFrame: Integer;
    FEntities: Integer;
    FCgameStarted: Boolean;
    FStage: string;
    procedure DrainMemory;
    procedure SendMemoryPacket;
    function ServerIdOfClient: Integer;
    function GetServer: TQ3Server;
    procedure AddWalkCommand;
  public
    constructor Create(const AFiles: IGameFileSystem; ANetwork: Boolean);
    destructor Destroy; override;
    /// <summary>The server loads the map, the client connects and gets the gamestate, cgame starts</summary>
    procedure Connect(const AMap: AnsiString);
    /// <summary>One frame of the client and of the server</summary>
    procedure Frame;
    /// <summary>The client sends a command for the server (a reliable client command, "say hello")</summary>
    procedure ClientCommand(const AText: AnsiString);
    /// <summary>True if the client has received a server command that starts with the text</summary>
    function ClientSawCommand(const APrefix: AnsiString): Boolean;
    /// <summary>
    ///   After a map change or a map_restart: the next packet of the client brings the new gamestate (the client
    ///   starts its cgame again when ARestartCgame)
    /// </summary>
    procedure Resync;
    property Client: TQ3LoopClient read FClient;
    property Server: TQ3Server read GetServer;
    property ServerSide: TQ3LoopServer read FServerSide;
    property Slot: Integer read FSlot;
    property Frames: Integer read FFrame;
    property Stage: string read FStage;
  end;

/// <summary>The OpenArena folder (DELPHIDOOM_OPENARENA or Reference\openarena); the test is ignored if it is not there</summary>
function OpenArenaFolder: string;
/// <summary>The file system of the game folder (baseoa, and the mod AGame on top of it)</summary>
function StartFileSystem(const AFolder, AGame: string): IGameFileSystem;
/// <summary>SV_BotInitCvars: the variables of the bots with the values the server gives them</summary>
procedure RegisterBotCvars(const AConsole: TQ3Console);

implementation

uses
  System.IOUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Net.Q3.ConsoleInfoWriter,
  DelphiDoom.Net.Q3.InfoString, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.ServerSnapshots,
  DelphiDoom.Q3Host.NetTransportAdapter, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Skip, DelphiDoom.Qvm.Factory, DelphiDoom.Net.Q3.Factory, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Factory,
  DelphiDoom.Q3Host.GameFiles, DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.ClientMessageSink,
  DelphiDoom.Q3Host.ClientScriptFiles, DelphiDoom.Q3Host.Client.Services, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Scanner.Q3.ScriptLoader, DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Q3Host.ClientSupport;

{ TQ3SteppingTime }

constructor TQ3SteppingTime.Create(AStart: Integer);
begin
  inherited Create;
  FValue := AStart;
end;

function TQ3SteppingTime.Milliseconds: Integer;
begin
  Inc(FValue, 17);
  Result := FValue;
end;

function OpenArenaFolder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TTestFiles.FindFolderUp('Reference\openarena\openarena-0.8.8');
  if (Result = '') or not TFile.Exists(TPath.Combine(Result, 'baseoa\pak0.pk3')) then
    TTestSkip.Ignore('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena)');
end;

function StartFileSystem(const AFolder, AGame: string): IGameFileSystem;
var
  LSettings: TGameFsSettings;
begin
  LSettings := Default(TGameFsSettings);
  LSettings.BasePath := AFolder;
  LSettings.SavePath := TPath.Combine(TPath.GetTempPath, 'ddq3localloop');
  LSettings.GameBase := 'baseoa';
  LSettings.Game := AGame;
  LSettings.PakExtension := '.pk3';
  Result := TGameFileSystemFactory.CreateOnDisk(LSettings);
  Result.Startup;
end;

procedure RegisterBotCvars(const AConsole: TQ3Console);
const
  NAMES: array[0..30] of string = ('bot_enable', 'bot_developer', 'bot_debug', 'bot_maxdebugpolys',
    'bot_groundonly', 'bot_reachability', 'bot_visualizejumppads', 'bot_forceclustering', 'bot_forcereachability',
    'bot_forcewrite', 'bot_aasoptimize', 'bot_saveroutingcache', 'bot_thinktime', 'bot_reloadcharacters',
    'bot_testichat', 'bot_testrchat', 'bot_testsolid', 'bot_testclusters', 'bot_fastchat', 'bot_nochat', 'bot_pause',
    'bot_report', 'bot_grapple', 'bot_rocketjump', 'bot_challenge', 'bot_minplayers', 'bot_interbreedchar',
    'bot_interbreedbots', 'bot_interbreedcycle', 'bot_interbreedwrite', 'bot_memorydump');
  VALUES: array[0..30] of string = ('1', '0', '0', '2', '1', '0', '0', '0', '0', '0', '0', '0', '100', '0', '0', '0',
    '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '', '10', '20', '', '0');
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(NAMES) do
    AConsole.CVars.Get(AnsiString(NAMES[LIndex]), AnsiString(VALUES[LIndex]), 0);
end;

{ TQ3MemoryOutput }

constructor TQ3MemoryOutput.Create;
begin
  inherited Create;
  FMessages := TList<TBytes>.Create;
  FSequences := TList<Integer>.Create;
  FOutOfBand := TStringList.Create;
end;

destructor TQ3MemoryOutput.Destroy;
begin
  FMessages.Free;
  FSequences.Free;
  FOutOfBand.Free;
  inherited Destroy;
end;

procedure TQ3MemoryOutput.SendMessage(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
begin
  FMessages.Add(Copy(AMessage));
  FSequences.Add(ASequence);
end;

procedure TQ3MemoryOutput.SendOutOfBand(const AAddress: TQ3NetAddress; const AText: AnsiString);
begin
  FOutOfBand.Add(string(AText));
end;

function TQ3MemoryOutput.HasUnsentFragments(AClient: Integer): Boolean;
begin
  Result := False;
end;

procedure TQ3MemoryOutput.TransmitNextFragment(AClient: Integer);
begin
end;

function TQ3MemoryOutput.Take(out AMessage: TBytes; out ASequence: Integer): Boolean;
begin
  Result := FMessages.Count > 0;
  if not Result then
    Exit;
  AMessage := FMessages[0];
  ASequence := FSequences[0];
  FMessages.Delete(0);
  FSequences.Delete(0);
end;

{ TQ3LoopSession }

constructor TQ3LoopSession.Create(const AFiles: IGameFileSystem; ANetwork: Boolean);
var
  LLimits: TQvmLimits;
begin
  inherited Create;
  FNetwork := ANetwork;
  FConsole := TQ3Console.Create(nil, nil, nil, TQ3ConsoleInfoWriter.Create);
  FConsole.Init;
  RegisterBotCvars(FConsole);
  // OpenArena runs on ioquake3: a bot's qagame copies a literal that does not start on a dword
  LLimits := TQvmLimits.Default;
  LLimits.UnalignedBlockCopy := True;
  FClient := TQ3LoopClient.Create(AFiles, FConsole, LLimits);
  FOutput := TQ3MemoryOutput.Create;
  FOutputIntf := FOutput;
  FServerSide := TQ3LoopServer.Create(AFiles, FConsole, LLimits, FClient.Sources, FOutputIntf);
  FSlot := -1;
  FOutgoing := 1;
  if FNetwork then
  begin
    FWire := TNetLoopbackPair.Create;
    FServerNet := TQ3ServerNetwork.Create(FServerSide.Server, FWire.Left, FConsole.Arguments, FClient.Coder, True);
    FServerNetIntf := FServerNet;
    FServerSide.Server.SetOutput(FServerNetIntf);
    FClientNet := TQ3ClientNetwork.Create(FWire.Right, 1, True, FClient.State, FClient.Parser, FClient.Writer,
      FConsole.Arguments, FClient.Coder);
  end;
end;

destructor TQ3LoopSession.Destroy;
begin
  // the server lets go of its output before the output goes
  FServerSide.Server.SetOutput(nil);
  FClientNet.Free;
  FServerNetIntf := nil;
  FServerNet := nil;
  FWire.Free;
  FServerSide.Free;
  FOutputIntf := nil;
  FClient.Free;
  FConsole.Free;
  inherited Destroy;
end;

function TQ3LoopSession.GetServer: TQ3Server;
begin
  Result := FServerSide.Server;
end;

function TQ3LoopSession.ServerIdOfClient: Integer;
begin
  Result := StrToIntDef(string(TQ3InfoString.ValueForKey(FClient.State.ConfigString(1), 'sv_serverid')), 0);
end;

procedure TQ3LoopSession.AddWalkCommand;
var
  LCommand: TQ3HostUserCmd;
begin
  LCommand := Default(TQ3HostUserCmd);
  PInteger(@LCommand[0])^ := Server.Time + 50;
  // forwardmove 100, as a player that walks
  LCommand[21] := 100;
  FClient.State.AddUserCommand(LCommand);
end;

// what the server wrote for the client, through the parser
procedure TQ3LoopSession.DrainMemory;
var
  LMessage: TBytes;
  LSequence: Integer;
  LNumber, LTime: Integer;
  LSnapshot: TQ3HostSnapshot;
begin
  while FOutput.Take(LMessage, LSequence) do
  begin
    FClient.Parser.OutgoingSequence := FOutgoing;
    FClient.Parser.ReliableSequence := FClient.State.ReliableSequence;
    FClient.Parser.RealTime := Server.Time;
    FClient.Parser.ParseMessage(LMessage, Length(LMessage), LSequence);
    FMessageNumber := LSequence;
  end;
  FClient.State.CurrentSnapshotNumber(LNumber, LTime);
  if FClient.State.TryGetSnapshot(LNumber, LSnapshot) then
    FEntities := LSnapshot.NumEntities;
end;

procedure TQ3LoopSession.SendMemoryPacket;
var
  LInput: TQ3ClientPacketInput;
  LPacket: TBytes;
  LServerTime: Integer;
begin
  LInput := Default(TQ3ClientPacketInput);
  LInput.ServerId := ServerIdOfClient;
  LInput.ServerMessageSequence := FMessageNumber;
  LInput.OutgoingSequence := FOutgoing;
  LInput.ChecksumFeed := FClient.State.ChecksumFeed;
  LInput.SnapshotValid := FClient.State.SnapshotValid;
  FClient.State.CurrentSnapshotNumber(LInput.SnapshotMessageNum, LServerTime);
  LInput.PacketDup := 1;
  LPacket := FClient.Writer.Write(LInput);
  Inc(FOutgoing);
  // the server reads what the netchan gives it: the message without the header, not encoded
  Server.ExecuteClientMessage(FSlot, LPacket, Length(LPacket));
end;

procedure TQ3LoopSession.Connect(const AMap: AnsiString);
const
  USERINFO = '\name\Tester\model\sarge\skill\3\rate\25000\cl_voip\0\cl_guid\0123456789ABCDEF0123456789ABCDEF\protocol\68\qport\1234\challenge\1';
var
  LAddress: TQ3NetAddress;
  LTry: Integer;
begin
  FConsole.CVars.Get('sv_maxclients', '8', 0);
  Server.SpawnServer(AMap, True);
  LAddress := TQ3NodeAddresses.FromNode(1, True);
  if FNetwork then
  begin
    FClientNet.Connect(USERINFO, 68, 1234);
    for LTry := 1 to 20 do
    begin
      FServerNet.Poll;
      FClientNet.Poll;
      if FClientNet.Connection = TQ3ClientConnection.Connected then
        Break;
    end;
    Assert.AreEqual(Ord(TQ3ClientConnection.Connected), Ord(FClientNet.Connection), 'connected');
    FSlot := 0;
    // the first packet of the client: its serverId is not the server's, so the gamestate comes back
    FClientNet.SendPacket;
    FServerNet.Poll;
    FClientNet.Poll;
    FMessageNumber := FClientNet.ServerMessageSequence;
  end
  else
  begin
    FSlot := Server.DirectConnect(LAddress, USERINFO);
    Assert.IsTrue(FSlot >= 0, 'connect: ' + StringReplace(Trim(FOutput.OutOfBand.Text), #10, '~', [rfReplaceAll]));
    SendMemoryPacket;
    DrainMemory;
  end;
  Assert.AreEqual(Ord(TQ3ServerClientPhase.Primed), Ord(Server.ClientPhase[FSlot]), 'primed');
  FClient.InitCgame(FMessageNumber);
  FCgameStarted := True;
end;

procedure TQ3LoopSession.Resync;
var
  LTry: Integer;
  LOld: Integer;
begin
  LOld := ServerIdOfClient;
  for LTry := 1 to 6 do
  begin
    if FNetwork then
    begin
      FStage := 'net packet';
      FClientNet.SendPacket;
      FServerNet.Poll;
      FClientNet.Poll;
      FMessageNumber := FClientNet.ServerMessageSequence;
    end
    else
    begin
      FStage := 'memory packet';
      SendMemoryPacket;
      FStage := 'drain';
      DrainMemory;
    end;
    if ServerIdOfClient <> LOld then
      Break;
    FStage := 'server frame';
    Server.Frame(50);
  end;
  FStage := 'init cgame';
  FClient.InitCgame(FMessageNumber);
end;

procedure TQ3LoopSession.ClientCommand(const AText: AnsiString);
begin
  FClient.State.AddReliableCommand(AText);
end;

function TQ3LoopSession.ClientSawCommand(const APrefix: AnsiString): Boolean;
var
  LSequence: Integer;
begin
  Result := False;
  for LSequence := Max(1, FClient.State.ServerCommandSequence - 63) to FClient.State.ServerCommandSequence do
    if Copy(FClient.State.ServerCommandText(LSequence), 1, Length(APrefix)) = APrefix then
      Exit(True);
end;

procedure TQ3LoopSession.Frame;
begin
  Inc(FFrame);
  AddWalkCommand;
  if FNetwork then
  begin
    FClientNet.SendPacket;
    FServerNet.Poll;
    Server.Frame(50);
    FClientNet.Poll;
    FMessageNumber := FClientNet.ServerMessageSequence;
    FOutgoing := FClientNet.Netchan.OutgoingSequence;
  end
  else
  begin
    SendMemoryPacket;
    Server.Frame(50);
    DrainMemory;
  end;
  FClient.DrawFrame;
end;

{ TQ3LoopServer }

constructor TQ3LoopServer.Create(const AFiles: IGameFileSystem; const AConsole: TQ3Console;
  const ALimits: TQvmLimits; const ASources: TQ3SourceHandles; const AOutput: IQ3ServerOutput);
var
  LSettings: TQ3ServerSettings;
begin
  inherited Create;
  FPrinted := TStringList.Create;
  LSettings := Default(TQ3ServerSettings);
  LSettings.Files := AFiles;
  LSettings.Console := AConsole;
  LSettings.Print := TQ3RecordingConsole.Create(FPrinted);
  LSettings.Calendar := TQ3FixedCalendar.Create;
  LSettings.Time := TQ3SteppingTime.Create(1000);
  LSettings.Output := AOutput;
  LSettings.Limits := ALimits;
  LSettings.Sources := ASources;
  LSettings.Protocol := 68;
  LSettings.ClientRunning := True;
  LSettings.WrapGameHost :=
    function(AHost: IQvmHost): IQvmHost
    begin
      FFingerprint := TQ3FingerprintHost.Create(AHost);
      Result := FFingerprint;
    end;
  FServer := TQ3Server.Create(LSettings);
end;

destructor TQ3LoopServer.Destroy;
begin
  FServer.Free;
  FPrinted.Free;
  inherited Destroy;
end;

function TQ3LoopServer.GameCalls: Integer;
begin
  Result := 0;
  if Assigned(FFingerprint) then
    Result := FFingerprint.Count;
end;

{ TQ3LoopClient }

constructor TQ3LoopClient.Create(const AFiles: IGameFileSystem; const AConsole: TQ3Console;
  const ALimits: TQvmLimits);
begin
  inherited Create;
  FFiles := AFiles;
  FConsole := AConsole;
  FLimits := ALimits;
  FClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(AFiles));
  FState := TQ3ClientState.Create(AConsole.Arguments);
  FStateIntf := FState;
  FSink := TQ3ClientMessageSink.Create(FState);
  FEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  FPlayerCodec := TQ3NetFactory.CreatePlayerStateCodec;
  FCoder := TQ3NetFactory.CreateMessageHuffman;
  FParser := TQ3NetFactory.CreateServerMessageParser(FCoder, FEntityCodec, FPlayerCodec,
    FSink as IQ3ServerMessageSink);
  FWriter := TQ3ClientPacketWriter.Create(FState, FCoder);
  FGlobals := TQ3GlobalDefines.Create;
  FSources := TQ3SourceHandles.Create(TQ3ScriptLoader.Create(TQ3HostScriptFiles.Create(AFiles), nil), nil, FGlobals);
  FRenderer := TQ3RecordingRenderer.Create;
  FKeys := TQ3ClientKeys.Create(AConsole.CVars);
  FLan := TQ3LanServers.Create;
  FCdKey := TQ3ClientCdKey.Create;
  // the services are objects with a reference count: one reference for the life of the client, so a cgame that
  // goes (a new map) does not free them
  SetLength(FHolders, 3);
  FHolders[0] := FRenderer;
  FHolders[1] := FKeys;
  FHolders[2] := FLan;
end;

destructor TQ3LoopClient.Destroy;
begin
  FCgame := nil;
  FCgameKeeper := nil;
  FCgameHost := nil;
  FHolders := nil;
  FCdKey.Free;
  FWriter.Free;
  FParser.Free;
  FEntityCodec.Free;
  FPlayerCodec.Free;
  FSink := nil;
  FSources.Free;
  FGlobals.Free;
  inherited Destroy;
end;

procedure TQ3LoopClient.InitCgame(AServerMessageNumber: Integer);
var
  LServices: TQ3HostServices;
  LClientServices: TQ3HostClientServices;
  LData: TBytes;
  LMapName: AnsiString;
begin
  // a new gamestate (a new map): the old cgame goes first
  FCgame := nil;
  FCgameKeeper := nil;
  FCgameFingerprint := nil;
  FCgameHost := nil;
  // CL_InitCGame: the map of the gamestate is loaded and the module started
  LMapName := FConsole.CVars.VariableString('mapname');
  FStage := 'clipmap';
  FClipMap.Load(AnsiString('maps/' + string(LMapName) + '.bsp'));
  FStage := 'clipmap done';
  FStage := 'services';
  LClientServices := Default(TQ3HostClientServices);
  LClientServices.State := FStateIntf;
  LClientServices.Connection := TQ3FakeConnection.Create;
  LClientServices.ClientSystem := TQ3FakeClientSystem.Create;
  LClientServices.Keys := FKeys;
  LClientServices.Sound := TQ3FakeSound.Create;
  LClientServices.Cinematics := TQ3FakeCinematics.Create;
  LClientServices.Renderer := FRenderer;
  LClientServices.Lan := FLan;
  LClientServices.CdKey := FCdKey;
  LClientServices.Sources := FSources;
  LClientServices.Math := True;
  LServices := Default(TQ3HostServices);
  LServices.CVars := FConsole.CVars;
  LServices.Arguments := FConsole.Arguments;
  LServices.Buffer := FConsole.Buffer;
  LServices.Commands := FConsole.Commands;
  LServices.Files := TQ3GameHostFiles.Create(FFiles, nil);
  LServices.ClipMap := FClipMap;
  LServices.Calendar := TQ3FixedCalendar.Create;
  LServices.Client := LClientServices;
  FStage := 'host';
  FCgameHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.CGame, TQ3RecordingConsole.Create(nil),
    TQ3FixedTime.Create(5000), LServices);
  FCgameFingerprint := TQ3FingerprintHost.Create(FCgameHost);
  FCgameKeeper := FCgameFingerprint;
  if not FFiles.ReadFile('vm/cgame.qvm', LData) then
    raise Exception.Create('vm/cgame.qvm is not there');
  FStage := 'machine';
  FCgame := TQvmFactory.CreateMachine('cgame', LData, FCgameKeeper, FLimits);
  FStage := 'CG_INIT';
  FCgame.Call(CG_INIT, [AServerMessageNumber, FState.LastExecutedServerCommand, FState.ConnectedClientNumber]);
end;

procedure TQ3LoopClient.DrawFrame;
var
  LNumber, LTime: Integer;
begin
  FState.CurrentSnapshotNumber(LNumber, LTime);
  FCgame.Call(CG_DRAW_ACTIVE_FRAME, [LTime, 0, 0]);
end;

function TQ3LoopClient.CgameCalls: Integer;
begin
  Result := FCgameFingerprint.Count;
end;

function TQ3LoopClient.Draws: Integer;
begin
  Result := FRenderer.CallCount('DrawStretchPic');
end;

function TQ3LoopClient.Scenes: Integer;
begin
  Result := FRenderer.CallCount('RenderScene');
end;

end.
