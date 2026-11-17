{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - qagame and cgame of        }
{  OpenArena 0.8.8 together: a server in memory (qagame, the snapshots of       }
{  TQ3ServerSnapshots), the messages it writes, the parser of NetQ3 and the     }
{  state of the client that cgame reads. The golden                             }
{  (Tests\Data\Q3Host\reach-loop.golden.txt) has how far it goes. Ignored if    }
{  the OpenArena folder is not there                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.LocalLoop;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostLoop')]
  [Category('OpenArena')]
  TTestQ3LocalLoop = class
  public
    [Test]
    procedure QagameECgameInsiemeDovrebberoArrivareAlPuntoDelGolden;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Scanner.Q3.ScriptLoader,
  DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.EntityStateCodec,
  DelphiDoom.Net.Q3.PlayerStateCodec, DelphiDoom.Net.Q3.Factory, DelphiDoom.Net.Q3.ServerMessage.Intf,
  DelphiDoom.Net.Q3.ServerMessageParser, DelphiDoom.Net.Q3.ConsoleInfoWriter, DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.GameFiles,
  DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.ServerState, DelphiDoom.Q3Host.GameWorld,
  DelphiDoom.Q3Host.ServerSnapshots, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf,
  DelphiDoom.Q3Host.Client.Services, DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientMessageSink,
  DelphiDoom.Q3Host.ClientKeys, DelphiDoom.Q3Host.ClientCdKey, DelphiDoom.Q3Host.ClientRecordingRenderer,
  DelphiDoom.Q3Host.UiLanServers, DelphiDoom.Q3Host.ClientScriptFiles, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.IdLib.Hashing.Md4, DelphiDoom.Q3Host.Bot.Intf, DelphiDoom.Q3Host.Bot.Files, DelphiDoom.Q3Host.Bot.Server,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Q3Host.ClientSupport,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Shared.Skip,
  DelphiDoom.Tests.Qvm.Support;

const
  CG_FRAMES = 10;
  SERVER_FRAME_MSEC = 50;

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

// SV_BotInitCvars: the variables of the bots with the values the server gives them
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

// one run: the server game, the messages, the parser, the client state and cgame, on the same console and files
procedure RunLoop(const AFiles: IGameFileSystem; const AGame: string; const ALines: TStrings);
var
  LConsole: TQ3Console;
  LClipMap: IQ3HostClipMap;
  LWorld: TQ3GameWorld;
  LServerState: TQ3HostServerState;
  LStateIntf: IQ3HostServerState;
  LSnaps: TQ3ServerSnapshots;
  LSnapsIntf: IQ3HostServerCommands;
  LClient: TQ3ClientState;
  LClientIntf: IQ3HostClientState;
  LSink: IQ3ServerMessageSink;
  LEntityCodec: TQ3EntityStateCodec;
  LPlayerCodec: TQ3PlayerStateCodec;
  LParser: TQ3ServerMessageParser;
  LGlobals: TQ3GlobalDefines;
  LSources: TQ3SourceHandles;
  LRenderer: TQ3RecordingRenderer;
  LKeys: TQ3ClientKeys;
  LLan: TQ3LanServers;
  LCdKey: TQ3ClientCdKey;
  LBase, LServices: TQ3HostServices;
  LClientServices: TQ3HostClientServices;
  LGameHost, LCgameHost: IQ3SyscallHost;
  LGameFingerprint, LCgameFingerprint: TQ3FingerprintHost;
  LGameKeeper, LCgameKeeper: IQvmHost;
  LGame, LCgame: IQvmMachine;
  LLimits: TQvmLimits;
  LData, LMessage: TBytes;
  LPrinted: TQ3RecordingConsole;
  LPrintedIntf: IQ3HostConsole;
  LStage, LResult: string;
  LFrame, LNumber, LTime, LSnapshots, LEntities, LRead: Integer;
  LCommand: TQ3HostUserCmd;
  LCommandBytes: TBytes;
  LSnapshot: TQ3HostSnapshot;
  LSnapNumber, LSnapTime: Integer;
  LBotServer: TQ3HostBotServer;
  LMapBytes: TBytes;
  LBotServerIntf: IInterface;
begin
  LConsole := TQ3Console.Create(nil, nil, nil, TQ3ConsoleInfoWriter.Create);
  try
    LConsole.Init;
    LConsole.CVars.Get('sv_maxclients', '8', 0);
    LConsole.CVars.Get('mapname', 'oa_dm1', 0);
    RegisterBotCvars(LConsole);
    Assert.IsTrue(AFiles.ReadFile('maps/oa_dm1.bsp', LMapBytes), 'bsp');
    LConsole.CVars.Get('sv_mapChecksum', AnsiString(IntToStr(Integer(TIdMd4.BlockChecksum(LMapBytes[0],
      Length(LMapBytes))))), 0);
    LClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(AFiles));
    LClipMap.Load('maps/oa_dm1.bsp');
    LPrinted := TQ3RecordingConsole.Create(nil);
    LPrintedIntf := LPrinted;
    LWorld := TQ3GameWorld.Create(LClipMap, LPrintedIntf);
    LServerState := TQ3HostServerState.Create(LConsole.CVars);
    LStateIntf := LServerState;
    LSnaps := TQ3ServerSnapshots.Create(LWorld, LClipMap, LStateIntf);
    LSnapsIntf := LSnaps;
    LServerState.OnConfigstringChanged :=
      procedure(AIndex: Integer; const AValue: AnsiString)
      begin
        LSnaps.ConfigstringChanged(AIndex, AValue);
      end;
    LClient := TQ3ClientState.Create(LConsole.Arguments);
    LClientIntf := LClient;
    LSink := TQ3ClientMessageSink.Create(LClient);
    LEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
    LPlayerCodec := TQ3NetFactory.CreatePlayerStateCodec;
    LParser := TQ3NetFactory.CreateServerMessageParser(TQ3NetFactory.CreateMessageHuffman, LEntityCodec,
      LPlayerCodec, LSink);
    LGlobals := TQ3GlobalDefines.Create;
    LSources := TQ3SourceHandles.Create(TQ3ScriptLoader.Create(TQ3HostScriptFiles.Create(AFiles), nil), nil, LGlobals);
    LRenderer := TQ3RecordingRenderer.Create;
    LKeys := TQ3ClientKeys.Create(LConsole.CVars);
    LLan := TQ3LanServers.Create;
    LCdKey := TQ3ClientCdKey.Create;
    try
      // OpenArena runs on ioquake3: a bot's qagame copies a literal that does not start on a dword
      LLimits := TQvmLimits.Default;
      LLimits.UnalignedBlockCopy := True;

      LBase := Default(TQ3HostServices);
      LBase.CVars := LConsole.CVars;
      LBase.Arguments := LConsole.Arguments;
      LBase.Buffer := LConsole.Buffer;
      LBase.Commands := LConsole.Commands;
      LBase.Files := TQ3GameHostFiles.Create(AFiles, nil);
      LBase.ClipMap := LClipMap;
      LBase.State := LStateIntf;
      LBase.ServerCommands := LSnapsIntf;
      LBase.Calendar := TQ3FixedCalendar.Create;
      // the botlib of the server (bot_enable 0: the library is there and nothing is set up, as sv_bot.c with the cvar off)

      LBotServer := TQ3HostBotServer.Create(LServerState,
        procedure(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString)
        begin
          LConsole.Arguments.Tokenize(ACommand);
          AMachine.Call(GAME_CLIENT_COMMAND, [AClient]);
        end);
      LBotServerIntf := LBotServer;
      LBase.Bot.Files := TQ3BotFileSource.Create(AFiles);
      LBase.Bot.Server := LBotServer;

      LClientServices := Default(TQ3HostClientServices);
      LClientServices.State := LClientIntf;
      LClientServices.Connection := TQ3FakeConnection.Create;
      LClientServices.ClientSystem := TQ3FakeClientSystem.Create;
      LClientServices.Keys := LKeys;
      LClientServices.Sound := TQ3FakeSound.Create;
      LClientServices.Cinematics := TQ3FakeCinematics.Create;
      LClientServices.Renderer := LRenderer;
      LClientServices.Lan := LLan;
      LClientServices.CdKey := LCdKey;
      LClientServices.Sources := LSources;
      LClientServices.Math := True;

      // 1. the server: sv_init sets the info strings, then the game starts
      LStage := 'server init';
      LServerState.SetConfigstring(0, AnsiString('\sv_hostname\Test\mapname\oa_dm1\sv_maxclients\8\g_gametype\0'
        + '\timelimit\0\fraglimit\20\capturelimit\8\g_maxGameClients\0'));
      LServerState.SetConfigstring(1, '\sv_serverid\1234\sv_pure\0');
      LServices := LBase;
      LServices.World := LWorld;
      LGameHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, LPrintedIntf, TQ3FixedTime.Create(0),
        LServices);
      LGameFingerprint := TQ3FingerprintHost.Create(LGameHost);
      LGameKeeper := LGameFingerprint;
      Assert.IsTrue(AFiles.ReadFile('vm/qagame.qvm', LData), 'qagame');
      LGame := TQvmFactory.CreateMachine('qagame', LData, LGameKeeper, LLimits);
      LResult := 'finished';
      LSnapshots := 0;
      LEntities := 0;
      LNumber := 0;
      try
        LGame.Call(GAME_INIT, [1000, 12345, 0]);
        LGame.Call(BOTAI_START_FRAME, [1050]);
        LGame.Call(GAME_RUN_FRAME, [1050]);
        LSnaps.CreateBaselines(LGame.Memory);
        LSnaps.StartGame;
        LSnaps.SetTime(1000);

        // 2. the client connects: the gamestate message goes through the parser into the client state
        LStage := 'connect';
        LServerState.SetUserinfo(0, '\name\Tester\model\sarge\skill\3\rate\25000\cl_voip\0');
        LServerState.SetClientActive(0, True);
        LSnaps.ConnectClient(0);
        LGame.Call(GAME_CLIENT_CONNECT, [0, 1, 0]);
        LMessage := LSnaps.WriteGamestate(0, LNumber);
        LParser.ParseMessage(LMessage, Length(LMessage), LNumber);

        // 3. cgame loads with the state the message gave
        LStage := 'cgame init';
        LServices := LBase;
        LServices.Client := LClientServices;
        LCgameHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.CGame, TQ3RecordingConsole.Create(nil),
          TQ3FixedTime.Create(5000), LServices);
        LCgameFingerprint := TQ3FingerprintHost.Create(LCgameHost);
        LCgameKeeper := LCgameFingerprint;
        Assert.IsTrue(AFiles.ReadFile('vm/cgame.qvm', LData), 'cgame');
        LCgame := TQvmFactory.CreateMachine('cgame', LData, LCgameKeeper, LLimits);
        LCgame.Call(CG_INIT, [LNumber, LClient.LastExecutedServerCommand, LClient.ConnectedClientNumber]);

        // 4. the client begins and the frames run: the command, the game, the snapshot, the parser, cgame
        LStage := 'begin';
        LGame.Call(GAME_CLIENT_BEGIN, [0]);
        LSnaps.ClientBegin(0);
        LTime := 1000;
        for LFrame := 1 to CG_FRAMES do
        begin
          LStage := 'frame ' + IntToStr(LFrame);
          Inc(LTime, SERVER_FRAME_MSEC);
          LCommand := Default(TQ3HostUserCmd);
          PInteger(@LCommand[0])^ := LTime;
          // forwardmove 100, as a player that walks
          LCommand[21] := 100;
          LClient.AddUserCommand(LCommand);
          SetLength(LCommandBytes, SizeOf(LCommand));
          Move(LCommand[0], LCommandBytes[0], SizeOf(LCommand));
          LServerState.SetUsercmd(0, LCommandBytes);
          LGame.Call(GAME_CLIENT_THINK, [0]);
          LSnaps.SetTime(LTime);
          LGame.Call(BOTAI_START_FRAME, [LTime]);
          LGame.Call(GAME_RUN_FRAME, [LTime]);
          LMessage := LSnaps.WriteSnapshot(LGame.Memory, 0, LNumber);
          LParser.RealTime := LTime;
          LParser.OutgoingSequence := LNumber + 1;
          LParser.ParseMessage(LMessage, Length(LMessage), LNumber);
          // the next packet of the client: what it got, and whether it can take a delta
          LClient.CurrentSnapshotNumber(LSnapNumber, LSnapTime);
          LSnaps.Acknowledge(0, LNumber, LClient.ServerCommandSequence, LSnapNumber = LNumber);
          if LClient.TryGetSnapshot(LSnapNumber, LSnapshot) then
            LEntities := LSnapshot.NumEntities;
          LSnapshots := LParser.SnapshotCount;
          LCgame.Call(CG_DRAW_ACTIVE_FRAME, [LSnapTime, 0, 0]);
        end;
        LStage := 'done';
      except
        on E: EQ3UnhandledSyscallException do
          LResult := 'stop=' + E.Message;
        on E: EQ3ModuleErrorException do
          LResult := 'error=' + Trim(E.Message);
        on E: Exception do
          LResult := 'exception=' + E.ClassName + ': ' + Trim(E.Message);
      end;
      LRead := 0;
      if Assigned(LCgameFingerprint) then
        LRead := LCgameFingerprint.Count;
      ALines.Add(Format('%s/loop %s in %s | server_calls=%d cgame_calls=%d snapshots=%d entities=%d'
        + ' last_message=%d draws=%d scenes=%d', [AGame, LResult, LStage, LGameFingerprint.Count, LRead,
        LSnapshots, LEntities, LNumber, LRenderer.CallCount('DrawStretchPic'), LRenderer.CallCount('RenderScene')]));
    finally
      LCgame := nil;
      LGame := nil;
      LCgameKeeper := nil;
      LGameKeeper := nil;
      LParser.Free;
      LEntityCodec.Free;
      LPlayerCodec.Free;
      LSink := nil;
      LSources.Free;
      LGlobals.Free;
      LCdKey.Free;
    end;
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3LocalLoop.QagameECgameInsiemeDovrebberoArrivareAlPuntoDelGolden;
var
  LFolder, LGame, LOut: string;
  LFiles: IGameFileSystem;
  LActual, LGolden: TStringList;
begin
  LFolder := OpenArenaFolder;
  LActual := TStringList.Create;
  try
    for LGame in ['baseoa', 'missionpack'] do
    begin
      LFiles := StartFileSystem(LFolder, LGame);
      RunLoop(LFiles, LGame, LActual);
      LFiles.Shutdown;
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_REACH_LOOP_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    TQvmScenarioRunner.Report(StringReplace(Trim(LActual.Text), sLineBreak, ' | ', [rfReplaceAll]));
    if TFile.Exists(TTestFiles.DataFile('Q3Host', 'reach-loop.golden.txt')) then
    begin
      LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'reach-loop.golden.txt'));
      try
        TTestGolden.AssertSameLines(LGolden, LActual);
      finally
        LGolden.Free;
      end;
    end;
  finally
    LActual.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3LocalLoop);

end.
